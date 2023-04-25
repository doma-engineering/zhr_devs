defmodule ZhrDevs.PublicRouter do
  @moduledoc """
  Public router for ZhrDevs
  """

  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger)

  @session_secrets Application.compile_env!(:zhr_devs, :server)[:session]
  @session_options Keyword.merge(@session_secrets, store: :cookie)

  plug(Plug.Session, @session_options)

  plug(:fetch_query_params)

  plug(:match)
  plug(Ueberauth)
  plug(:dispatch)

  plug(:fetch_session)

  get("/auth/:provider/callback",
    to: DomaOAuth,
    init_opts: %{callback: &ZhrDevs.AuthCallback.call/2}
  )

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
