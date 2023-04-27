defmodule ZhrDevs.Web.AuthCallback do
  @moduledoc """
  This module is responsible for handling the callback from the OAuth provider.
  """

  @behaviour Plug

  require Logger

  alias DomaOAuth.Authentication.{Failure, Success}

  alias ZhrDevs.IdentityManagement

  def init(opts), do: opts

  def call(%{assigns: %{oauth: %Success{} = success}} = conn, _opts) do
    Logger.info("Successful authentication attempt for #{success.hashed_identity}")

    case IdentityManagement.get_identity(success.hashed_identity) do
      {:ok, _pid} ->
        :ok = IdentityManagement.renew_login(success.hashed_identity)

      {:error, :not_found} ->
        {:ok, _pid} = IdentityManagement.spawn_identity(success)

        Logger.info("New identity spawned for #{success.hashed_identity}")
    end

    conn
    |> assign_hashed_identity_to_session(success.hashed_identity)
    |> redirect_to("/protected")
  end

  def call(%{assigns: %{oauth: %Failure{errors: errors}}} = conn, _opts) do
    Logger.info("Failed authentication attempt: #{errors}")

    redirect_to(conn, "/")
  end

  defp assign_hashed_identity_to_session(conn, hashed_identity) do
    Plug.Conn.put_session(conn, :hashed_identity, hashed_identity)
  end

  defp redirect_to(conn, route) do
    conn
    |> Plug.Conn.put_status(302)
    |> Plug.Conn.put_resp_header("location", route)
  end
end
