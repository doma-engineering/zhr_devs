defmodule ZhrDevs.Web.Plugs.SubmissionUpload do
  @moduledoc """
  This plug is responsible for handling submission uploads.

  As per Plug.Upload documentation we can't trust the content_type from the client
  so we check it, but it could be not enough: https://hexdocs.pm/plug/Plug.Upload.html#module-security
  """

  @behaviour Plug

  import Plug.Conn

  alias ZhrDevs.Submissions.Commands.SubmitSolution

  import ZhrDevs.Web.Presentation.Helper, only: [json_error: 1]

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

  def init([]), do: []

  def call(
        %{
          body_params: %{"submission" => %Plug.Upload{path: submission_tmp_path} = upload},
          params: %{"task_uuid" => task_uuid}
        } = conn,
        _opts
      ) do
    uuid4 = Commanded.UUID.uuid4()
    hashed_identity = get_session(conn, :hashed_identity)
    %ZhrDevs.Task{} = task = task_uuid |> Uptight.Text.new!() |> AvailableTasks.get_task_by_uuid()
    upload_path = upload_path(task, uuid4)

    with :ok <- check_mime_type(upload),
         :ok <- File.mkdir_p(Path.dirname(upload_path)),
         :ok <- File.cp!(submission_tmp_path, upload_path),
         :ok <- submit_solution(uuid4, hashed_identity, conn.params, upload_path) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{uuid4: uuid4}))
      |> halt()
    else
      {:error, error} when is_binary(error) ->
        cleanup(upload_path)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, json_error(error))
        |> halt()

      {:error, error} ->
        cleanup(upload_path)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, json_error(%{error: error}))
        |> halt()
    end
  end

  defp upload_path(%ZhrDevs.Task{name: task, technology: technology}, uuid) do
    ZhrDevs.submission_upload_path(task, technology, "#{uuid}.zip")
  end

  defp submit_solution(uuid, hashed_identity, params, path) do
    opts = [
      uuid: uuid,
      hashed_identity: hashed_identity,
      technology: Map.get(params, "technology"),
      task_uuid: Map.get(params, "task_uuid"),
      solution_path: path
    ]

    SubmitSolution.dispatch(opts)
  end

  defp check_mime_type(%Plug.Upload{content_type: content_type, path: _path}) do
    if do_check_mime_type(content_type) do
      :ok
    else
      {:error, "only .zip files are allowed"}
    end
  end

  defp do_check_mime_type(content_type) do
    content_type
    |> MIME.extensions()
    |> Enum.any?(fn ext -> ext in ["zip", "x-zip", "x-zip-compressed"] end)
  end

  defp cleanup(upload_path) do
    if File.exists?(upload_path), do: File.rm!(upload_path)
  end
end
