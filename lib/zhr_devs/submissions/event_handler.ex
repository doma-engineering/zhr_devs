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
    start_from: :origin

  alias ZhrDevs.Submissions.Events.SolutionCheckStarted
  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.Events.TaskDownloaded
  alias ZhrDevs.Submissions.Events.TestCasesDownloaded

  alias ZhrDevs.Submissions.ReadModels.TaskDownloads

  alias ZhrDevs.{Email, Mailer}

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

    maybe_notify_operator(solution_submitted, task)
  end

  def handle(%SolutionCheckStarted{} = event, _meta) do
    Logger.info("Solution check started: #{inspect(event)}")

    :ok
  end

  def handle(%TaskDownloaded{task_uuid: task_uuid}, _meta) do
    :ok = TaskDownloads.increment_downloads(task_uuid, :task)
  end

  def handle(%TestCasesDownloaded{task_uuid: task_uuid}, _meta) do
    :ok = TaskDownloads.increment_downloads(task_uuid, :test_cases)
  end

  defp maybe_notify_operator(%SolutionSubmitted{trigger_automatic_check: false} = event, task) do
    opts = [
      task_name: task.name,
      technology: task.technology,
      submission_url: submission_url(event.uuid),
      hashed_identity: event.hashed_identity
    ]

    opts
    |> Email.solution_submitted()
    |> Mailer.deliver_now!()

    :ok
  end

  defp maybe_notify_operator(_solution_submitted, _task) do
    # Skip notifying operator if automatic check is enabled

    :ok
  end

  defp submission_url(uuid) do
    %URI{
      scheme: to_string(Application.fetch_env!(:zhr_devs, :server)[:scheme]),
      host: Application.fetch_env!(:zhr_devs, :server)[:host],
      port: Application.fetch_env!(:zhr_devs, :server)[:port],
      path: "/my/submission/#{uuid}/download"
    }
    |> URI.to_string()
  end
end
