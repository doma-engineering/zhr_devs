defmodule ZhrDevs.IdentityManagement.Identity do
  @moduledoc """
  Represents an identity of user received from a trusted OAuth provider.
  """

  use GenServer

  import Algae

  alias Uptight.Result
  alias Uptight.Text, as: T

  import Uptight.Assertions

  defdata do
    identity :: Uptight.Text.t()
    hashed_identity :: Uptight.Base.Urlsafe.t()
    login_at :: UtcDateTime.t()
  end

  alias DomaOAuth.Authentication.Success

  # Public API

  def start_link(%Success{hashed_identity: hashed_identity} = success_struct) do
    GenServer.start_link(__MODULE__, success_struct, name: via_tuple(hashed_identity))
  end

  @spec renew_login(binary()) :: :ok | no_return()
  def renew_login(hashed_identity) when is_binary(hashed_identity) do
    GenServer.call(via_tuple(hashed_identity), :renew_login)
  end

  # Callbacks

  @impl GenServer
  def init(success) do
    parsed_success = success_to_identity(success)
    assert Result.is_ok?(parsed_success), "Parsing success struct is failed"

    {:ok, Result.from_ok(parsed_success)}
  end

  @impl GenServer
  def handle_call(:renew_login, _from, state) do
    {:reply, :ok, %__MODULE__{state | login_at: UtcDateTime.new()}}
  end

  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, hashed_identity}}
  end

  defp success_to_identity(success) do
    Result.new(fn ->
      identity = T.new(success.identity)
      hashed_identity = Uptight.Base.mk_url(success.hashed_identity)

      new(Result.from_ok(identity), Result.from_ok(hashed_identity), UtcDateTime.new())
    end)
  end
end
