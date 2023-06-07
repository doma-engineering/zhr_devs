defmodule ZhrDevs.Web.ProtectedRouter do
  @moduledoc """
  Router for protected resources
  """

  use Plug.Router

  alias ZhrDevs.IdentityManagement

  import ZhrDevs.Web.Shared, only: [redirect_to: 2]

  @session_secrets Application.compile_env!(:zhr_devs, :server)[:session]
  @session_options Keyword.merge(@session_secrets, store: :cookie)

  plug(Plug.Session, @session_options)
  plug(:fetch_session)
  plug(:check_auth)
  plug(:match)
  plug(:dispatch)

  plug(Plug.Parsers,
    pass: ["application/json", "application/zip", "multipart/form-data"],
    parsers: [
      {:json, json_decoder: Jason},
      {:multipart, length: Application.compile_env!(:zhr_devs, :max_upload_size)}
    ]
  )

  get "/" do
    conn = put_resp_content_type(conn, "text/html")
    send_file(conn, 200, "priv/static/index.html")
  end

  post("/task/:technology/:task_uuid/submission", to: ZhrDevs.Web.Plugs.SubmissionUpload)

  defp check_auth(conn, _opts) do
    conn
    |> check_session()
    |> lookup_identity()
    |> case do
      :ok ->
        conn

      :unauthenticated ->
        redirect_to(conn, "/login")
    end
  end

  defp check_session(conn), do: get_session(conn, :hashed_identity)

  defp lookup_identity(nil), do: :unauthenticated

  defp lookup_identity(hashed_identity) do
    case IdentityManagement.get_identity(hashed_identity) do
      {:ok, _pid} ->
        :ok

      {:error, :not_found} ->
        :unauthenticated
    end
  end
end
