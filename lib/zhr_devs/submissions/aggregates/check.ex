defmodule ZhrDevs.Submissions.Aggregates.Check do
  @moduledoc """
  Represents a check process of the submitted solution.

  The business process is following:
  - User submits the solution
  - Check process is started in the background
  - Once check process is finished successfully, the solution is marked as checked and points assigned
  - If check process fails, the solution is marked as failed and user is notified

  This particular module is ensuring, that only one check process is running for the certain solution.
  Because solution checking is an expensive operation, we don't want to run arbitrary amount of times.

  Read more about aggregates in Commanded context:
  https://github.com/commanded/commanded/blob/master/guides/Aggregates.md
  """
  defstruct [:solution_uuid, status: :new]

  alias Uptight.Base.Urlsafe

  @type t() ::
          %{
            :__struct__ => __MODULE__,
            required(:solution_uuid) => Urlsafe.t(),
            required(:status) => :new | :started | :completed,
            required(:execution_errors) => [String.t()] | []
          }

  alias ZhrDevs.Submissions.{Commands, Events}

  def execute(%__MODULE__{status: status}, %Commands.StartCheckSolution{}) when status != :new do
    {:error, :check_is_already_started}
  end

  def execute(
        %__MODULE__{solution_uuid: nil, status: :new},
        %Commands.StartCheckSolution{} = command
      ) do
    %Events.SolutionCheckStarted{
      solution_uuid: command.solution_uuid,
      task_uuid: command.task_uuid,
      solution_path: command.solution_path
    }
  end

  def execute(%__MODULE__{status: status}, %Commands.CompleteCheckSolution{})
      when status != :started do
    {:error, :illegal_attempt}
  end

  def execute(%__MODULE__{status: :started}, %Commands.CompleteCheckSolution{} = cmd) do
    %Events.SolutionCheckCompleted{
      solution_uuid: cmd.solution_uuid,
      task_uuid: cmd.task_uuid,
      points: cmd.points
    }
  end

  ### State mutators ###

  def apply(%__MODULE__{} = state, %Events.SolutionCheckStarted{} = event) do
    %__MODULE__{
      state
      | solution_uuid: event.solution_uuid,
        status: :started
    }
  end

  def apply(%__MODULE__{} = state, %Events.SolutionCheckCompleted{}) do
    %__MODULE__{
      state
      | status: :completed
    }
  end
end
