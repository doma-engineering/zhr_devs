defmodule ZhrDevs.Submissions.EventHandler do
  @moduledoc """
  Event handlers allow you to execute code that reacts to domain events:
   - to build read model projections;
   - dispatch commands to other aggregates;
   - and to interact with third-party systems such as sending emails.

  Commanded guarantees only one instance of an event handler will run, regardless of how many nodes are running (even when not using distributed Erlang).
  This is enforced by the event store subscription (PostgreSQL advisory locks in Elixir Event Store).

  In our case we want to react to the `LoggedIn` event and spawn new identity / update it's login time:
    - If it's a new user that was logged in for the first time, we spawn a new identity in the response to the event.
    - If it's a user that was already logged in previously, the spawn_identity/1 function will return {:error, :already_started} tuple
      becase the process already spawned for this identity. But also the event will be handled in the handle_info/2 callback of the identity process.
      Read more about this design decision in ZhrDevs.IdentityManagement.ReadModels.Identity module.
    - TODO: implement proper handling of an unexpected errors, such as :max_children_reached and others.
  """

  require Logger

  use Commanded.Event.Handler,
    application: ZhrDevs.App,
    name: __MODULE__,
    start_from: :origin,
    consistency: :strong

  alias ZhrDevs.Submissions.Events.SolutionCheckCompleted
  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.Events.ManualCheckCompleted

  alias ZhrDevs.Submissions.Events.TaskDownloaded
  alias ZhrDevs.Submissions.Events.TestCasesDownloaded

  alias ZhrDevs.Submissions.ReadModels.TaskDownloads
  alias ZhrDevs.Submissions.ReadModels.CandidateSubmissions

  def init do
    :ok = ZhrDevs.Queries.delete_handler_subscriptions(__MODULE__)
  end

  def handle(%SolutionSubmitted{} = solution_submitted, _meta) do
    %ZhrDevs.Task{} =
      task =
      ZhrDevs.Tasks.ReadModels.AvailableTasks.get_task_by_uuid(solution_submitted.task_uuid)

    ZhrDevs.Submissions.increment_attempts(
      solution_submitted.hashed_identity,
      task
    )

    CandidateSubmissions.register_submission(
      task: task,
      hashed_identity: solution_submitted.hashed_identity,
      submission_uuid: solution_submitted.uuid
    )
  end

  def handle(%SolutionCheckCompleted{task_uuid: task_uuid, score: result}, _meta) do
    Logger.debug("SolutionCheckCompleted: #{inspect(task_uuid)}")

    ZhrDevs.Submissions.ReadModels.TournamentRuns.add_tournament_result(task_uuid, result)
  end

  def handle(%ManualCheckCompleted{task_uuid: task_uuid, score: result}, _meta) do
    Logger.debug("ManualCheckCompleted for task: #{inspect(task_uuid)}")

    ZhrDevs.Submissions.ReadModels.TournamentRuns.add_tournament_result(task_uuid, result)
  end

  def handle(%TaskDownloaded{task_uuid: task_uuid}, _meta) do
    :ok = TaskDownloads.increment_downloads(task_uuid, :task)
  end

  def handle(%TestCasesDownloaded{task_uuid: task_uuid}, _meta) do
    :ok = TaskDownloads.increment_downloads(task_uuid, :test_cases)
  end

  def error(_, _, %Commanded.Event.FailureContext{context: context}) do
    {:retry, 2_000, context}
  end
end
