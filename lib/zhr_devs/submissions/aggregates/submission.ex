defmodule ZhrDevs.Submissions.Aggregates.Submission do
  @moduledoc """
  Represents a submission of the certain task by the certain user.
  Validates, that user can submit the solution only twice.

  An aggregate is comprised of its state, public command functions, and state mutators.

  In a CQRS application all state must be derived from the published domain events.
  This prevents tight coupling between aggregate instances, such as querying for their state, and ensures their state isn't exposed.

  Command functions (execute/2):
    A command function receives the aggregate's state and the command to execute. It must return the resultant domain events, which may be one event or multiple events.

    You can return a single event or a list of events: %Event{}, [%Event{}], {:ok, %Event{}}, or {:ok, [%Event{}]}.
    To respond without returning an event you can return :ok, nil or an empty list as either [] or {:ok, []}.
    For business rule violations and errors you may return an {:error, error} tagged tuple or raise an exception.

    Name your public command functions execute/2 to dispatch commands directly to the aggregate without requiring an intermediate command handler.

  State mutators (apply/2):
    The state of an aggregate can only be mutated by applying a domain event to its state.
    This is achieved by an apply/2 function that receives the state and the domain event. It returns the modified state.
    Pattern matching is used to invoke the respective apply/2 function for an event.
    These functions must never fail as they are used when rebuilding the aggregate state from its history of domain events. You cannot reject the event once it has occurred.

  Read more: https://github.com/commanded/commanded/blob/master/guides/Aggregates.md
  """
  alias Uptight.Base.Urlsafe
  alias Uptight.Text

  alias ZhrDevs.Submissions.Commands.DownloadTask
  alias ZhrDevs.Submissions.Commands.SubmitSolution

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.Events.TaskDownloaded
  alias ZhrDevs.Submissions.Events.TestCasesDownloaded

  @type t() ::
          %{
            :__struct__ => __MODULE__,
            required(:attempts) => non_neg_integer(),
            required(:first_attempt_at) => UtcDateTime.t(),
            required(:hashed_identity) => Urlsafe.t(),
            required(:last_attempt_at) => UtcDateTime.t(),
            # Would be cute to refactor all the Text.t() to Uptight.UUID.t().
            # However, we'll need to implement it first in Uptight.
            required(:task_uuid) => Text.t(),
            required(:technology) => atom(),
            required(:uuid) => Text.t()
          }

  @fields SolutionSubmitted.aggregate_fields() ++
            [last_attempt_at: nil, first_attempt_at: nil, attempts: 0, uuid: Urlsafe.new()]
  @enforce_keys Keyword.keys(SolutionSubmitted.aggregate_fields()) ++ [:attempts, :uuid]
  defstruct @fields

  # Not a huge fan of this hack, if something can be empty, it should be `Option.st(t())`.
  # # (`st` stands for `specific type`).
  #
  # Speaking of which, we should have a Maybe / Option implemented in Uptight.
  # Better yet, it can be improved in Algae (or wherever it is defined).
  # The idea is that we should be able to use a type similar to `Uptight.Result.sum(e_t, a_t)` and `Uptight.Result.possibly(a_t)`.
  # This way we will preserve a lot more information about the type than just `Maybe.t()`.
  #
  # P.S.
  # But without these facilities, this hack is pretty neat, good job on coming up with it!
  @new Urlsafe.new()

  def execute(%__MODULE__{attempts: 2}, _command) do
    {:error, "Maximum number of attempts reached"}
  end

  def execute(%__MODULE__{}, %SubmitSolution{} = command) do
    %SolutionSubmitted{
      uuid: command.uuid,
      hashed_identity: command.hashed_identity,
      technology: command.technology,
      task_uuid: command.task_uuid,
      solution_path: command.solution_path
    }
  end

  def execute(%__MODULE__{attempts: 0}, %DownloadTask{} = command) do
    %TaskDownloaded{
      hashed_identity: command.hashed_identity,
      task_uuid: command.task_uuid,
      technology: command.technology
    }
  end

  def execute(%__MODULE__{attempts: 1}, %DownloadTask{} = command) do
    %TestCasesDownloaded{
      hashed_identity: command.hashed_identity,
      task_uuid: command.task_uuid,
      technology: command.technology
    }
  end

  def apply(%__MODULE__{uuid: @new}, %SolutionSubmitted{} = event) do
    %__MODULE__{
      uuid: event.uuid,
      attempts: 1,
      hashed_identity: event.hashed_identity,
      task_uuid: event.task_uuid,
      technology: event.technology,
      first_attempt_at: UtcDateTime.new()
    }
  end

  def apply(%__MODULE__{attempts: attempts} = submission, %SolutionSubmitted{}) do
    %__MODULE__{
      submission
      | attempts: attempts + 1,
        last_attempt_at: UtcDateTime.new()
    }
  end

  def apply(%__MODULE__{} = state, %TaskDownloaded{}), do: state
  def apply(%__MODULE__{} = state, %TestCasesDownloaded{}), do: state
end
