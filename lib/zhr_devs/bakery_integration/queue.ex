defmodule ZhrDevs.BakeryIntegration.Queue do
  @moduledoc """
  This module is responsible for queueing the submission check runs.

  It will hold a :queue with all checks.
  It will also keep track of running checks, to be able to:
    - Restart them in case of failure with more granular control
    - Stop the check in case we already processed the solution before;
      That usually happens on system restart, when we are replaying the events.
      In such a case the queue will receive the request to start the check first,
      but then the event will be replayed and the check will be removed from queue.
      If check is already running, we will kill the process that is running the check.
  """

  use GenServer

  require Logger

  @empty_queue :queue.new()
  @queue_delay_ms :timer.seconds(30)

  alias ZhrDevs.BakeryIntegration.Queue.RunningCheck

  defmodule State do
    @moduledoc """
    State of the queue process
    """
    defstruct queue: :queue.new(), running: [], delayed_check_ref: nil
  end

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def enqueue_check(options, name \\ __MODULE__) do
    GenServer.call(name, {:enqueue_check, options})
  end

  def dequeue_check(solution_uuid, name \\ __MODULE__) do
    GenServer.cast(name, {:dequeue_check, solution_uuid})
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

    {:ok, pid} = ZhrDevs.BakeryIntegration.Commands.GenMultiplayer.run(options)

    running_check = %RunningCheck{
      solution_uuid: Keyword.fetch!(options, :solution_uuid),
      ref: Process.monitor(pid),
      pid: pid,
      restart_opts: options
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

        updated_refs = Enum.filter(checks, &(&1.ref != ref))
        delayed_check_ref = schedule_next_check(state.delayed_check_ref)

        {:noreply, %State{state | running: updated_refs, delayed_check_ref: delayed_check_ref}}

      running_check ->
        Logger.info("Retrying the check. Current state: #{inspect(running_check)}")

        {:ok, pid} =
          ZhrDevs.BakeryIntegration.Commands.GenMultiplayer.run(running_check.restart_opts)

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
end
