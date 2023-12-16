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
      (TODO: Send an email when we failed to run a check 3 times)

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

  @type check_options() :: [
          task: String.t(),
          submissions_folder: Uptight.Text.t(),
          server_code: Uptight.Text.t(),
          solution_uuid: Uptight.Text.t(),
          task_uuid: Uptight.Text.t()
        ]

  defmodule State do
    @moduledoc """
    State of the queue process
    """
    defstruct queue: :queue.new(), running: [], delayed_check_ref: nil
  end

  @spec start_link(check_options()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec enqueue_check(check_options(), atom()) :: :ok
  def enqueue_check(options, name \\ __MODULE__) do
    GenServer.call(name, {:enqueue_check, options})
  end

  @spec dequeue_check(Uptight.Text.t(), atom()) :: :ok
  def dequeue_check(solution_uuid, name \\ __MODULE__) do
    GenServer.cast(name, {:dequeue_check, solution_uuid})
  end

  @spec send_email_alert(RunningCheck.t(), Command.system_error()) :: DynamicSupervisor.on_start_child()
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

    delayed_check_ref =
      unless :queue.is_empty(queue),
        do: Process.send_after(self(), :run_next_check, @queue_delay_ms)

    {:ok, %State{queue: queue, running: [], delayed_check_ref: delayed_check_ref}}
  end

  def handle_call({:enqueue_check, options}, _from, %State{queue: queue} = state) do
    Logger.info("#{__MODULE__} Enqueuing check: #{inspect(options)}")

    ref = schedule_next_check(state.delayed_check_ref)

    {:reply, :ok, %State{state | queue: :queue.in(options, queue), delayed_check_ref: ref}}
  end

  def handle_cast({:dequeue_check, solution_uuid}, %State{queue: queue, running: running} = state) do
    Logger.info("#{__MODULE__} Dequeuing check: #{solution_uuid}")

    updated_queue =
      :queue.delete_with(
        fn element ->
          element[:solution_uuid] === solution_uuid
        end,
        queue
      )

    running_checks =
      case Enum.find(running, &(&1.solution_uuid == solution_uuid)) do
        nil ->
          running

        %RunningCheck{pid: pid, ref: ref} ->
          Logger.debug("#{__MODULE__} Killing check: #{solution_uuid}")

          Process.demonitor(ref, [:flush])
          Process.exit(pid, :shutdown)
          Enum.filter(running, &(&1.solution_uuid != solution_uuid))
      end

    {:noreply, %State{state | queue: updated_queue, running: running_checks}}
  end

  def handle_info(:run_next_check, %{queue: @empty_queue} = state) do
    Logger.info("#{__MODULE__} No checks to run.")

    {:noreply, state}
  end

  def handle_info(:run_next_check, %{queue: queue, running: []} = state) do
    {{:value, options}, rest_of_queue} = :queue.out(queue)

    {:ok, pid} = ZhrDevs.BakeryIntegration.gen_multiplayer(options)

    running_check = %RunningCheck{
      retries: 0,
      solution_uuid: Keyword.fetch!(options, :solution_uuid),
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
    updated_checks = Enum.filter(checks, &(&1.ref != ref))

    delayed_check_ref = schedule_next_check(state.delayed_check_ref)

    {:noreply, %State{state | running: updated_checks, delayed_check_ref: delayed_check_ref}}
  end

  def handle_info({:DOWN, ref, _, _, reason}, %State{running: checks} = state) do
    checks
    |> Enum.find(&(&1.ref == ref))
    |> case do
      %RunningCheck{retries: 3} = running_check ->
        Logger.error(
          "Check failed 3 times: #{inspect(running_check)}. Reason: #{inspect(reason)}"
        )

        {:ok, _pid} = send_email_alert(running_check, reason)

        updated_refs = Enum.filter(checks, &(&1.ref != ref))
        delayed_check_ref = schedule_next_check(state.delayed_check_ref)

        {:noreply, %State{state | running: updated_refs, delayed_check_ref: delayed_check_ref}}

      running_check ->
        retry_interval = check_retry_interval(running_check.retries)

        Logger.info("""
        Retrying the check. Current state: #{inspect(running_check)}.\nWill be restarted in #{retry_interval} ms
        """)

        Process.send_after(self(), {:retry_check, running_check}, retry_interval)

        {:noreply, state}
    end
  end

  def handle_info(
        {:retry_check, %RunningCheck{ref: ref} = running_check},
        %State{running: checks} = state
      ) do
    {:ok, pid} = ZhrDevs.BakeryIntegration.gen_multiplayer(running_check.restart_opts)

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
end
