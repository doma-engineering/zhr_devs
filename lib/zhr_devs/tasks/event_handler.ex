defmodule ZhrDevs.Tasks.EventHandler do
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

  alias ZhrDevs.Tasks.Events.{TaskModeChanged, TaskSupported}

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

  def init do
    :ok = ZhrDevs.Queries.delete_handler_subscriptions(__MODULE__)
  end

  def handle(%TaskSupported{} = task_supported, _meta) do
    task =
      ZhrDevs.Task.new!(
        task_supported.task_uuid,
        task_supported.name,
        task_supported.technology,
        task_supported.trigger_automatic_check
      )

    :ok =
      Commanded.PubSub.broadcast(
        ZhrDevs.App,
        "task_availability",
        {:task_supported, task}
      )

    ZhrDevs.Submissions.spawn_tournament_tracker(task.uuid)

    AvailableTasks.add_task(task)
  end

  def handle(%TaskModeChanged{} = event, _meta) do
    :ok =
      AvailableTasks.change_task_mode(event.name, event.technology, event.trigger_automatic_check)
  end

  def error(_, _, %Commanded.Event.FailureContext{context: context}) do
    {:retry, 2_000, context}
  end
end
