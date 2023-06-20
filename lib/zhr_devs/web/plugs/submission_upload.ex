defmodule ZhrDevs.Web.Plugs.SubmissionUpload do
  @moduledoc """
  This plug is responsible for handling submission uploads.

  As per Plug.Upload documentation we can't trust the content_type from the client
  so we check it, but it could be not enough: https://hexdocs.pm/plug/Plug.Upload.html#module-security
  """

  @behaviour Plug

  import Plug.Conn

  @upload_dir Application.compile_env!(:zhr_devs, :uploads_path)

  alias ZhrDevs.Submissions.Commands.SubmitSolution

  alias ZhrDevs.Web.Decoder.FromUrlEncoded

  alias ZhrDevs.Submissions

  import ZhrDevs.Web.Presentation.Helper, only: [json_error: 1]
  import Uptight.Assertions

  def init([]), do: []

  def call(
        %{params: %{"submission" => %Plug.Upload{path: submission_tmp_path} = upload}} = conn,
        _opts
      ) do
    uuid4 = Commanded.UUID.uuid4()
    hashed_identity = get_session(conn, :hashed_identity)
    upload_path = upload_path(uuid4)

    assert %Submissions.Task{} = task_id = FromUrlEncoded.call(conn.params["task_id"], :task),
           "Invalid task_id"

    with :ok <- check_mime_type(upload),
         :ok <- File.cp!(submission_tmp_path, upload_path(uuid4)),
         :ok <- submit_solution(uuid4, hashed_identity, task_id) do
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

      {:error, _error} ->
        cleanup(upload_path)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, json_error(%{error: "Unexpected error"}))
        |> halt()
    end
  end

  defp upload_path(uuid) do
    Path.join(@upload_dir, "#{uuid}.zip")
  end

  defp submit_solution(uuid, hashed_identity, %ZhrDevs.Submissions.Task{} = task_id) do
    opts = [
      uuid: uuid,
      hashed_identity: hashed_identity,
      technology: task_id.programming_language.language.text,
      task_id: task_id,
      solution_path: upload_path(uuid)
    ]

    SubmitSolution.dispatch(opts)
  end

  @spec check_mime_type(Plug.Upload.t()) :: :ok | {:error, String.t()}
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
