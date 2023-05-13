defmodule ZhrDevs.IdentityManagement.ReadModels.Identity do
  @moduledoc """
  Represents an identity of user received from a trusted OAuth provider.

  To keep the state of the read model up-to date even in case of an errors,
  we rely on the ZhrDevs.IdentityManagement.EventHandler process to spawn new identity process
  as well send appropriate updates.
  """

  use GenServer

  import Algae

  defdata do
    identity :: Uptight.Text.t()
    hashed_identity :: Uptight.Base.Urlsafe.t()
    login_at :: UtcDateTime.t()
  end

  alias ZhrDevs.IdentityManagement.Events.LoggedIn

  # Public API

  def start_link(%LoggedIn{hashed_identity: hashed_identity} = event) do
    GenServer.start_link(__MODULE__, event, name: via_tuple(hashed_identity))
  end

  def update_login_at(hashed_identity, new_login_at) do
    GenServer.call(via_tuple(hashed_identity), {:update_login_at, new_login_at})
  end

  # Callbacks

  @impl GenServer
  def init(event) do
    {:ok, new(event.identity, event.hashed_identity, event.login_at)}
  end

  @impl GenServer
  def handle_call({:update_login_at, new_login_at}, _from, state) do
    {:reply, :ok, %__MODULE__{state | login_at: new_login_at}}
  end

  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, {:identity, to_string(hashed_identity)}}}
  end
end
