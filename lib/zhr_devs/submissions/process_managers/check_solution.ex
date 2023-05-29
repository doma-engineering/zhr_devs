defmodule ZhrDevs.Submissions.ProcessManagers.CheckSolution do
  @moduledoc """
  Process manager for checking solution.

  This process will be listening for particular set of events
  mentioned in the `interested?/1` function.

  Once event is observed, the process manager will dispatch appropriate command

  Process manager also maintains it's own tiny state, that will allow us
  to not dispatch the same command twice.

  Unlike the aggregate, we can omit the handle/2 and apply/2 functions
  which we are not interesting in, in this case nothing will happens and state
  will be preserved.

  For more information about process managers, please refer to the Commanded documentation:
  https://github.com/commanded/commanded/blob/master/guides/Process%20Managers.md
  """

  use Commanded.ProcessManagers.ProcessManager,
    application: ZhrDevs.App,
    name: "CheckSolutionProcessManager",
    start_from: :origin

  alias ZhrDevs.Submissions.Commands
  alias ZhrDevs.Submissions.Events

  @derive Jason.Encoder
  defstruct status: :new

  def interested?(%Events.SolutionSubmitted{uuid: solution_uuid}), do: {:start, solution_uuid}

  def interested?(%Events.SolutionCheckStarted{solution_uuid: solution_uuid}),
    do: {:continue, solution_uuid}

  def interested?(%Events.SolutionCheckCompleted{solution_uuid: solution_uuid}),
    do: {:stop, solution_uuid}

  def interested?(_event), do: false

  def handle(%__MODULE__{status: :new}, %Events.SolutionSubmitted{} = event) do
    %Commands.StartCheckSolution{
      solution_uuid: event.uuid,
      task_uuid: event.task_uuid,
      solution_path: event.solution_path
    }
  end

  ### State mutators ###

  def apply(%__MODULE__{status: :new} = state, %Events.SolutionCheckStarted{}) do
    %__MODULE__{state | status: :running}
  end

  ### Error handling ###

  require Logger

  @retry_delay_milliseconds 10_000
  @failures_limit 3

  # Stop process manager after three failures
  def error({:error, _failure}, _failed_message, %{context: %{failures: failures}})
      when failures >= @failures_limit do
    {:stop, :too_many_failures}
  end

  # Retry command, record failure count in context map
  def error({:error, _failure}, _failed_message, %{context: context}) do
    Logger.error(
      "[#{__MODULE__}] Failed to dispatch command, retrying in #{@retry_delay_milliseconds} ms"
    )

    context = Map.update(context, :failures, 1, fn failures -> failures + 1 end)

    {:retry, @retry_delay_milliseconds, context}
  end
end
