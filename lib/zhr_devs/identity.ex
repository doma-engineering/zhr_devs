defmodule ZhrDevs.Identity do
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
    login_at :: UtcDatetime
  end

  alias DomaOAuth.Authentication.Success

  # Public API

  def start_link(%Success{hashed_identity: hashed_identity} = success_struct) do
    GenServer.start_link(__MODULE__, success_struct, name: via_tuple(hashed_identity))
  end

  # Callbacks

  @impl GenServer
  def init(success) do
    parsed_success = success_to_identity(success)
    assert Result.is_ok?(parsed_success), "Parsing success struct is failed"

    {:ok, Result.from_ok(parsed_success)}
  end

  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, hashed_identity}}
  end

  defp success_to_identity(success) do
    Result.new(fn ->
      identity = T.new(success.identity)
      assert Result.is_ok?(identity), "Identity is not valid"

      hashed_identity = Uptight.Base.mk_url(success.hashed_identity)
      assert Result.is_ok?(hashed_identity), "Hashed identity is not valid"

      new(Result.from_ok(identity), Result.from_ok(hashed_identity), UtcDatetime.new())
    end)
  end
end

defmodule UtcDatetime do
  @moduledoc "Just a hack module to allow to use DateTime as a type in Algae."

  def new, do: DateTime.utc_now()
end
