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
    name: "CheckSolutionProcessManager"

  alias ZhrDevs.Submissions.Commands
  alias ZhrDevs.Submissions.Events

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
end
