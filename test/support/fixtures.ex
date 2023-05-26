defmodule ZhrDevs.Fixtures do
  @moduledoc "Helper functions to generate test data."

  alias DomaOAuth.Authentication.Success

  alias ZhrDevs.IdentityManagement.ReadModels.Identity

  alias Uptight.Text, as: T

  def generate_successful_auth(:github) do
    username = identity_generator()

    %Success{
      identity: username,
      hashed_identity: DomaOAuth.hash(username)
    }
  end

  def generate_failed_auth(_) do
    %DomaOAuth.Authentication.Failure{errors: ["Something really bad happens"]}
  end

  def generate_successful_login_event(%Success{hashed_identity: hi, identity: i}) do
    identity = T.new!(i)
    hashed_identity = Uptight.Base.mk_url!(hi)

    %ZhrDevs.IdentityManagement.Events.LoggedIn{
      identity: identity,
      hashed_identity: hashed_identity,
      login_at: UtcDateTime.new()
    }
  end

  def generate_successful_login_event(provider) do
    %Success{
      identity: i,
      hashed_identity: hi
    } = generate_successful_auth(provider)

    %ZhrDevs.IdentityManagement.Events.LoggedIn{
      identity: T.new!(i),
      hashed_identity: Uptight.Base.mk_url!(hi),
      login_at: UtcDateTime.new()
    }
  end

  def identity_generator(num_of_chars \\ 5) do
    generated = StreamData.string(:alphanumeric) |> Enum.take(num_of_chars) |> Enum.join()
    generated <> "@" <> "github.com"
  end

  def generate_hashed_identity(num_of_chars \\ 5) do
    num_of_chars
    |> identity_generator()
    |> DomaOAuth.hash()
    |> Uptight.Base.mk_url!()
  end

  def login(%Plug.Conn{} = conn) do
    successful_auth = generate_successful_auth(:github)
    login_event = generate_successful_login_event(successful_auth)

    ExUnit.Callbacks.start_supervised!({Identity, login_event})

    Plug.Test.init_test_session(conn, %{hashed_identity: login_event.hashed_identity.encoded})
  end
end
