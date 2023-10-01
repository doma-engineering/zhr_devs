defmodule ZhrDevs.Web.ProtectedRouter do
  @moduledoc """
  Router for protected resources
  """

  use Plug.Router

  require Logger

  alias ZhrDevs.IdentityManagement

  @session_secrets Application.compile_env!(:zhr_devs, :server)[:session]
  @session_options Keyword.merge(@session_secrets, store: :cookie)

  plug(Plug.Parsers,
    pass: ["application/json", "multipart/form-data"],
    parsers: [
      {:json, json_decoder: Jason},
      {:multipart, length: Application.compile_env!(:zhr_devs, :max_upload_size)}
    ]
  )

  plug(Plug.Session, @session_options)
  plug(:fetch_session)
  plug(:check_auth)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_file(conn, 200, "priv/static/index.html")
  end

  get("/tasks", to: ZhrDevs.Web.Plugs.Tasks)

  get("/submission/:task_uuid", to: ZhrDevs.Web.Plugs.Submission)

  get("/submission/nt/:name/:technology", to: ZhrDevs.Web.Plugs.Submission)

  post("/task/:task_uuid/submission", to: ZhrDevs.Web.Plugs.SubmissionUpload)

  post("/task/nt/:name/:technology/:task_uuid/submission", to: ZhrDevs.Web.Plugs.SubmissionUpload)

  get("/submission/:submission_uuid/download", to: ZhrDevs.Web.Plugs.DownloadSubmission)

  defp check_auth(conn, _opts) do
    conn
    |> check_session()
    |> lookup_identity()
    |> case do
      :ok ->
        conn

      :unauthenticated ->
        conn
        |> put_resp_content_type("text/html")
        |> send_file(401, "priv/pages/login.html")
        |> halt()
    end
  end

  match _ do
    Logger.warning("No route found for #{inspect(conn.method)} #{inspect(conn.request_path)}")

    case get_req_header(conn, "refferrer") do
      [path] ->
        ZhrDevs.Web.Shared.redirect_to(conn, path)

      _ ->
        ZhrDevs.Web.Shared.redirect_to(conn, "/my")
    end
  end

  defp check_session(conn), do: get_session(conn, :hashed_identity)

  defp lookup_identity(nil), do: :unauthenticated

  defp lookup_identity(binary_hashed_identity) do
    hashed_identity = Uptight.Base.mk_url!(binary_hashed_identity)

    case IdentityManagement.get_identity(hashed_identity) do
      {:ok, _pid} ->
        :ok

      {:error, :not_found} ->
        :unauthenticated
    end
  end
end
