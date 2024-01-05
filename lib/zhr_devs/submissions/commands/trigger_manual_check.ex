defmodule ZhrDevs.Submissions.Commands.TriggerManualCheck do
  @moduledoc """
  This command will be available only for the admins,
  it will allow to trigger all (or the subset of) the submissions.
  """

  alias ZhrDevs.App

  alias Uptight.Result
  alias Uptight.Text, as: T

  @fields [
    task_uuid: nil,
    submissions: [],
    submissions_folder: nil,
    triggered_by: nil,
    uuid: nil,
    triggered_at: nil
  ]
  @enforce_keys Keyword.keys(@fields)
  defstruct @fields

  @doc """
  To dispatch this command, the user must be an admin.
  We validate the submissions list or the task_uuid provided.
  Then we need to create a separate directory with subset of submissions (for the subset case).

  *If no submissions provided, we will use all submissions for the task.*
  """
  def dispatch(opts) do
    case parse(opts) do
      %Uptight.Result.Ok{ok: result} ->
        App.dispatch(result)

      error ->
        {:error, error}
    end
  end

  defp parse(opts) do
    Result.new(fn ->
      task_uuid =
        opts
        |> Keyword.fetch!(:task_uuid)
        |> T.new!()

      triggered_by =
        opts
        |> Keyword.fetch!(:triggered_by)
        |> Uptight.Base.mk_url!()

      uuid = Keyword.get(opts, :uuid, Commanded.UUID.uuid4()) |> T.new!()

      %ZhrDevs.Task{} = task = ZhrDevs.Tasks.ReadModels.AvailableTasks.get_task_by_uuid(task_uuid)

      case opts |> Keyword.fetch!(:submissions) |> lookup_submission_files(task) do
        {:ok, :all_submissions} ->
          %__MODULE__{
            uuid: uuid,
            task_uuid: task_uuid,
            submissions: [],
            submissions_folder: standard_submissions_folder(task),
            triggered_by: triggered_by,
            triggered_at: DateTime.utc_now()
          }

        {:ok, submission_paths} ->
          %__MODULE__{
            uuid: uuid,
            task_uuid: task_uuid,
            submissions: submission_paths,
            submissions_folder: T.new!("/tmp/#{task.name}_#{task.technology}"),
            triggered_by: triggered_by,
            triggered_at: DateTime.utc_now()
          }

        error ->
          error
      end
    end)
  end

  def standard_submissions_folder(%ZhrDevs.Task{name: task_name, technology: technology}) do
    ZhrDevs.submission_upload_folder(task_name, technology) |> Path.dirname() |> T.new!()
  end

  def lookup_submission_files([], _task), do: {:ok, :all_submissions}

  def lookup_submission_files(submissions, %ZhrDevs.Task{name: task_name, technology: technology}) do
    submissions
    |> Enum.map(fn submission_uuid ->
      submission_path = ZhrDevs.submission_upload_path(task_name, technology, submission_uuid)

      if File.exists?(submission_path) do
        {:ok, submission_path}
      else
        {:error, submission_uuid}
      end
    end)
    |> Enum.split_with(fn {result, _} -> result == :ok end)
    |> case do
      {ok, []} ->
        {:ok, Enum.map(ok, fn {:ok, path} -> path end)}

      {_, errors} ->
        {:error, :submission_not_exists, Enum.map(errors, fn {:error, uuid} -> uuid end)}
    end
  end
end
