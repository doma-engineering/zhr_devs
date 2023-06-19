defmodule ZhrDevs.Web.Plugs.DownloadTask do
  @moduledoc """
  Sends user requested 'task' in form of a file

  For now finding a task by id is skipped, as we don't have tasks implemented.
  """

  @behaviour Plug

  import Plug.Conn

  alias ZhrDevs.Submissions.Commands.DownloadTask, as: DownloadTaskCommand

  import ZhrDevs.Web.Presentation.Helper, only: [json_error: 1]

  def init([]), do: []

  def call(%{params: %{"task_uuid" => task_uuid}} = conn, _opts) do
    download_command_opts = [
      hashed_identity: get_session(conn, :hashed_identity),
      technology: "elixir",
      task_uuid: task_uuid
    ]

    case DownloadTaskCommand.dispatch(download_command_opts) do
      :ok ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_file(200, "priv/static/robots.txt")

      {:error, error} ->
        send_resp(conn, 422, json_error(error))
    end
  end
end
