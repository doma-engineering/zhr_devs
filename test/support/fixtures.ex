defmodule ZhrDevs.Fixtures do
  @moduledoc "Helper functions to generate test data."

  alias DomaOAuth.Authentication.Success

  alias Uptight.Result
  alias Uptight.Text, as: T

  def generate_successful_auth(:github) do
    username = username_generator()

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

  defp username_generator do
    generated = StreamData.string(:alphanumeric) |> Enum.take(5) |> Enum.join()
    generated <> "@" <> "github.com"
  end
end
