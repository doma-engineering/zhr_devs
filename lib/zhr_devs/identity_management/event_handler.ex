defmodule ZhrDevs.IdentityManagement.EventHandler do
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

  alias ZhrDevs.IdentityManagement.Aggregates.Identity
  alias ZhrDevs.IdentityManagement.Events.LoggedIn
  alias ZhrDevs.IdentityManagement.ReadModels.Identity

  def init do
    :ok = ZhrDevs.Queries.delete_handler_subscriptions(__MODULE__)
  end

  def handle(%LoggedIn{} = logged_in, _meta) do
    case ZhrDevs.IdentityManagement.spawn_identity(logged_in) do
      {:ok, _pid} ->
        Logger.debug(
          "Spawned new identity projection after successful login for #{inspect(logged_in.hashed_identity)}"
        )

        {:ok, _pid} = ZhrDevs.Submissions.spawn_candidate_attempts(logged_in.hashed_identity)

      {:error, {:already_started, _}} ->
        :ok = Identity.update_login_at(logged_in.hashed_identity, logged_in.login_at)

      other_error ->
        Logger.error(
          "Failed to spawn identity for #{inspect(logged_in)}: #{inspect(other_error)}"
        )

        :ok
    end
  end
end
