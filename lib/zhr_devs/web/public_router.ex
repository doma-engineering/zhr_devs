defmodule ZhrDevs.Web.PublicRouter do
  @moduledoc """
  Public router for ZhrDevs
  """

  use Plug.Router
  use Plug.ErrorHandler

  alias ZhrDevs.Web

  alias ZhrDevs.Web.AuthCallback

  plug(Plug.Logger)

  plug Plug.Static,
    at: "/",
    from: :zhr_devs

  @session_secrets Application.compile_env!(:zhr_devs, :server)[:session]
  @session_options Keyword.merge(@session_secrets, store: :cookie)

  plug(Plug.Session, @session_options)
  plug(:fetch_session)
  plug(:fetch_query_params)
  plug(:match)
  plug(Ueberauth)
  plug(:dispatch)

  get "/" do
    conn = put_resp_content_type(conn, "text/html")
    send_file(conn, 200, "priv/static/index.html")
  end

  get("/auth/:provider/callback",
    to: DomaOAuth,
    init_opts: %{callback: &AuthCallback.call/2}
  )

  forward("/my", to: Web.ProtectedRouter)

  if Mix.env() == :dev do
    get "/sign-in-dev" do
      mock_auth = %DomaOAuth.Authentication.Success{
        identity: "john.doe@gmail.com",
        hashed_identity: DomaOAuth.hash("john.doe@gmail.com")
      }

      :ok = AuthCallback.dispatch_login_command(mock_auth)

      conn
      |> AuthCallback.assign_hashed_identity_to_session(mock_auth.hashed_identity)
      |> Web.Shared.redirect_to("/my/tasks")
    end
  end

  match _ do
    conn
    |> send_resp(404, "Not found")
    |> halt()
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _, reason: _, stack: _}) do
    # Maybe render 500.html
    send_resp(conn, conn.status, "Something went wrong")
  end
end
