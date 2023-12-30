defmodule ZhrDevs.BakeryIntegration.Queue do
  @moduledoc """
  This module is responsible for queueing the submission check runs.
  It using a Queue.RunningCheck struct to keep track of running checks.

  It will hold a :queue with all checks.
    - When a new check is enqueued, it will be added to the queue and
      the CommandRunner process will be started after 30 seconds;
      Once the CommandRunner process is spawned, it will return the pid,
      which will be used to monitor the process and restart it if it fails.

  It will also keep track of running checks, to be able to:
    - Restart them in case of failure with more granular control;
      By default, if a check fails, it will be restarted 3 times before giving up.
      An email alert will be sent after the third failure.

  It should be mentioned, that this process won't be receiving "replayed" events,
  because the event handler that it controled by (ZhrDevs.Submissions.AutomaticCheckRunner)
  is not configured to do so.

  If not listening to events is not ok, this process is already implements
  the way to 'dequeue' checks. (We should decide how to handle this case)

  Therefore, we might want to have a 'button' that will re-enqueue all checks (TODO)
  Also, as discussed with Jons, we want to have a way to run only subest of submissions (TODO)
  """

  use GenServer

  require Logger

  @empty_queue :queue.new()
  @queue_delay_ms :timer.seconds(30)

  alias ZhrDevs.BakeryIntegration.Queue.RunningCheck

  alias ZhrDevs.{Email, Mailer}

  alias ZhrDevs.BakeryIntegration.Commands.Command

  defmodule State do
    @moduledoc """
    State of the queue process
    """
    defstruct queue: :queue.new(), running: [], delayed_check_ref: nil
  end

  @spec start_link(RunningCheck.restart_opts()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec enqueue_check(RunningCheck.restart_opts(), atom()) :: :ok
  def enqueue_check(options, name \\ __MODULE__) do
    GenServer.call(name, {:enqueue_check, options})
  end

  @spec prioritize_check(RunningCheck.restart_opts(), atom()) :: :ok
  def prioritize_check(options, name \\ __MODULE__) do
    GenServer.call(name, {:prioritize_check, options})
  end

  @spec dequeue_check(Uptight.Text.t(), atom()) :: :ok
  def dequeue_check(check_uuid, name \\ __MODULE__) do
    GenServer.cast(name, {:dequeue_check, check_uuid})
  end

  @spec send_email_alert(RunningCheck.t(), Command.system_error()) ::
          DynamicSupervisor.on_start_child()
  def send_email_alert(running_check, system_error) do
    Task.Supervisor.start_child(
      ZhrDevs.EmailsSendingSupervisor,
      fn ->
        Email.automatic_check_failed(running_check: running_check, system_error: system_error)
        |> Mailer.deliver_now!()
      end,
      restart: :transient
    )
  end

  def init(opts) do
    queue = Keyword.get(opts, :queue, :queue.new())
    running = Keyword.get(opts, :running, [])

    delayed_check_ref =
      unless :queue.is_empty(queue),
        do: Process.send_after(self(), :run_next_check, @queue_delay_ms)

    {:ok, %State{queue: queue, running: running, delayed_check_ref: delayed_check_ref}}
  end

  def handle_call({:enqueue_check, options}, _from, %State{queue: queue} = state) do
    Logger.info("#{__MODULE__} Enqueuing check: #{inspect(options)}")

    ref = schedule_next_check(state.delayed_check_ref)

    {:reply, :ok, %State{state | queue: :queue.in(options, queue), delayed_check_ref: ref}}
  end

  def handle_call({:prioritize_check, options}, _from, %State{queue: queue} = state) do
    Logger.info("#{__MODULE__} Prioritizing check: #{inspect(options)}")

    reshaped_queue = [options | :queue.to_list(queue)] |> :queue.from_list()
    ref = schedule_next_check(state.delayed_check_ref)

    {:reply, :ok, %State{state | queue: reshaped_queue, delayed_check_ref: ref}}
  end

  def handle_cast({:dequeue_check, check_uuid}, %State{queue: queue, running: running} = state) do
    Logger.info("#{__MODULE__} Dequeuing check: #{check_uuid}")

    updated_queue =
      :queue.delete_with(
        fn element ->
          element[:check_uuid] === check_uuid
        end,
        queue
      )

    running_checks =
      case Enum.find(running, &(&1.check_uuid == check_uuid)) do
        nil ->
          running

        %RunningCheck{pid: pid, ref: ref} ->
          Logger.debug("#{__MODULE__} Killing check: #{check_uuid}")

          Process.demonitor(ref, [:flush])
          Process.exit(pid, :shutdown)
          Enum.filter(running, &(&1.check_uuid != check_uuid))
      end

    {:noreply, %State{state | queue: updated_queue, running: running_checks}}
  end

  def handle_info(:run_next_check, %{queue: @empty_queue} = state) do
    Logger.info("#{__MODULE__} No checks to run.")

    {:noreply, state}
  end

  def handle_info(:run_next_check, %{queue: queue, running: []} = state) do
    {{:value, options}, rest_of_queue} = :queue.out(queue)

    command_module = Keyword.fetch!(options, :command_module)
    command = Keyword.fetch!(options, :cmd)

    {:ok, pid} = command_module.run(command)

    running_check = %RunningCheck{
      retries: 0,
      check_uuid: Keyword.fetch!(options, :check_uuid),
      ref: Process.monitor(pid),
      pid: pid,
      restart_opts: options,
      task_technology: Keyword.fetch!(options, :task)
    }

    {:noreply, %State{state | queue: rest_of_queue, running: [running_check]}}
  end

  def handle_info(:run_next_check, %{running: running} = state) do
    Logger.info("#{__MODULE__} Already running a check: #{inspect(running)}")

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _, _, :normal}, %State{running: checks} = state) do
    terminated_check = Enum.find(checks, &(&1.ref == ref))

    case Keyword.fetch!(terminated_check.restart_opts, :on_success) |> emit_success_event() do
      :ok ->
        updated_checks = Enum.filter(checks, &(&1.ref != ref))

        delayed_check_ref = schedule_next_check(state.delayed_check_ref)

        {:noreply, %State{state | running: updated_checks, delayed_check_ref: delayed_check_ref}}

      {:error, reason} ->
        {:noreply, maybe_retry_check(ref, reason, state)}
    end
  end

  def handle_info({:DOWN, ref, _, _, reason}, state) when is_atom(reason) do
    Logger.error("Check failed with not :normal reason: #{inspect(reason)}")

    {:norely, maybe_retry_check(ref, %{error: reason}, state)}
  end

  def handle_info({:DOWN, ref, _, _, {:shutdown, reason}}, state) do
    {:norely, maybe_retry_check(ref, reason, state)}
  end

  def handle_info(
        {:retry_check, %RunningCheck{ref: ref} = running_check},
        %State{running: checks} = state
      ) do
    command_module = Keyword.fetch!(running_check.restart_opts, :command_module)
    command = Keyword.fetch!(running_check.restart_opts, :cmd)

    {:ok, pid} = command_module.run(command)

    updated_running_check = %RunningCheck{
      running_check
      | ref: Process.monitor(pid),
        retries: running_check.retries + 1,
        pid: pid
    }

    running_checks =
      Enum.map(checks, fn
        %RunningCheck{ref: ^ref} -> updated_running_check
        other -> other
      end)

    {:noreply, %State{state | running: running_checks}}
  end

  @spec schedule_next_check(reference() | nil) :: reference()
  defp schedule_next_check(ref) do
    :ok = maybe_reset_check_timer(ref)

    Process.send_after(self(), :run_next_check, @queue_delay_ms)
  end

  defp maybe_reset_check_timer(nil), do: :ok

  defp maybe_reset_check_timer(ref) do
    Process.cancel_timer(ref)
    :ok
  end

  @spec check_retry_interval(integer()) :: integer()
  defp check_retry_interval(retries) do
    # This is a simple exponential backoff based on the number of retries.
    (retries + 1) * :timer.seconds(10)
  end

  defp emit_failure_event({m, f, a}, reason) do
    Kernel.apply(m, f, [reason | a])
  end

  defp emit_success_event({m, f, a}) do
    Kernel.apply(m, f, a)
  end

  defp maybe_retry_check(ref, reason, %State{running: checks} = state) do
    checks
    |> Enum.find(&(&1.ref == ref))
    |> case do
      %RunningCheck{retries: 3} = running_check ->
        Logger.error(
          "Check failed 3 times: #{inspect(running_check)}. Reason: #{inspect(reason)}"
        )

        :ok =
          running_check.restart_opts
          |> Keyword.fetch!(:on_failure)
          |> emit_failure_event(reason)

        {:ok, _pid} = send_email_alert(running_check, reason)

        updated_refs = Enum.filter(checks, &(&1.ref != ref))
        delayed_check_ref = schedule_next_check(state.delayed_check_ref)

        %State{state | running: updated_refs, delayed_check_ref: delayed_check_ref}

      running_check ->
        retry_interval = check_retry_interval(running_check.retries)

        Logger.info("""
        Retrying the check. Current state: #{inspect(running_check)}.\nWill be restarted in #{retry_interval} ms
        """)

        Process.send_after(self(), {:retry_check, running_check}, retry_interval)

        state
    end
  end
end
