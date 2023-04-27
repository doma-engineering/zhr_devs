defmodule ZhrDevs.Factory do
  @moduledoc "Helper functions to generate test data."

  alias DomaOAuth.Authentication.Success

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

  defp username_generator do
    generated = StreamData.string(:alphanumeric) |> Enum.take(5) |> Enum.join()
    generated <> "@" <> "github.com"
  end
end
