defmodule ZhrDevs.Web.Plugs.DownloadTask do
  @moduledoc """
  This plug is responsible for downloading task
  and incrementing a counter of downloads.
  """
  use Plug.Builder

  require Logger

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

  alias ZhrDevs.Submissions.Commands.DownloadTask

  import ZhrDevs.Web.Presentation.Helper, only: [json_error: 1]

  plug(Plug.Logger)
  plug(:fetch_task)
  plug(:parse_download_type)
  plug(:send_code)

  def fetch_task(%{params: params} = conn, _) do
    case Map.get(params, "task_uuid") do
      nil ->
        Logger.warning("Unable to fetch task, no UUID is provided.")

        ZhrDevs.Web.Shared.redirect_to(conn, "/tasks")

      uuid ->
        task = uuid |> Uptight.Text.new!() |> AvailableTasks.get_task_by_uuid()

        assign(conn, :task, task)
    end
  end

  def parse_download_type(conn, _opts) do
    additional_inputs = Map.get(conn.params, "type") == "additionalInputs"

    assign(conn, :additional_inputs, additional_inputs)
  end

  def send_code(conn, _opts) do
    with {:ok, download_path} <- get_download_path(conn),
         :ok <- dispatch_command(conn) do
      send_file(conn, 200, download_path)
    else
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, json_error(reason))
        |> halt()
    end
  end

  defp dispatch_command(%{assigns: %{task: task, additional_inputs: additional_inputs}} = conn) do
    opts = [
      technology: task.technology,
      task_uuid: task.uuid,
      additional_inputs: additional_inputs,
      hashed_identity: get_session(conn, :hashed_identity)
    ]

    DownloadTask.dispatch(opts)
  end

  defp get_download_path(%{assigns: %{additional_inputs: true, task: task}}) do
    ZhrDevs.additional_inputs_download_path(task)
  end

  defp get_download_path(%{assigns: %{additional_inputs: false, task: task}}) do
    ZhrDevs.task_download_path(task)
  end
end
