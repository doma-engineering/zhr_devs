defmodule ZhrDevs.Web.AuthCallback do
  @moduledoc """
  This module is responsible for handling the callback from the OAuth provider.
  """

  @behaviour Plug

  require Logger

  import ZhrDevs.Web.Shared

  alias DomaOAuth.Authentication.{Failure, Success}

  alias ZhrDevs.IdentityManagement.Commands.Login

  def init(opts), do: opts

  def call(%{assigns: %{oauth: %Success{} = success}} = conn, _opts) do
    :ok = dispatch_login_command(success)
    Logger.info("Successful authentication attempt for #{success.hashed_identity}")

    conn
    |> assign_hashed_identity_to_session(success.hashed_identity)
    |> redirect_to("/protected")
  end

  def call(%{assigns: %{oauth: %Failure{errors: errors}}} = conn, _opts) do
    Logger.info("Failed authentication attempt: #{errors}")

    redirect_to(conn, "/")
  end

  def assign_hashed_identity_to_session(conn, hashed_identity) do
    Plug.Conn.put_session(conn, :hashed_identity, hashed_identity)
  end

  def dispatch_login_command(%Success{} = success) do
    success
    |> Map.take([:identity, :hashed_identity])
    |> Keyword.new()
    |> Login.dispatch()
  end
end
