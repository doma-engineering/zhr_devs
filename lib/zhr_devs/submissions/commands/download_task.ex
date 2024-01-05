defmodule ZhrDevs.Submissions.Commands.DownloadTask do
  @moduledoc """
  This command will be dispatched upon download task request from user

  For the first submission the event will be TaskDownloaded
  After the first submission we will attach the extended task version with tests,
  so fields will remain the same, but event will be called TestCasesDownloaded
  """

  alias ZhrDevs.Submissions.Events.TaskDownloaded

  alias ZhrDevs.Submissions.SubmissionIdentity

  alias ZhrDevs.App

  alias Uptight.Base.Urlsafe
  alias Uptight.Result
  alias Uptight.Text

  @fields TaskDownloaded.fields() ++ [submission_identity: nil, additional_inputs: false]
  @enforce_keys Keyword.keys(@fields)
  defstruct @fields

  @type t :: %{
          :__struct__ => __MODULE__,
          required(:technology) => atom(),
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_uuid) => Text.t(),
          required(:submission_identity) => SubmissionIdentity.t(),
          required(:additional_inputs) => boolean()
        }

  @typep error() :: String.t() | struct()

  @spec dispatch(Keyword.t()) :: :ok | {:error, error()}
  def dispatch(opts) do
    case parse(opts) do
      %Uptight.Result.Ok{} = ok_result ->
        ok_result
        |> Result.from_ok()
        |> App.dispatch()

      error ->
        {:error, error}
    end
  end

  defp parse(opts) do
    Result.new(fn ->
      hashed_identity =
        opts
        |> Keyword.fetch!(:hashed_identity)
        |> Uptight.Base.mk_url!()

      technology = Keyword.fetch!(opts, :technology)
      additional_inputs = Keyword.get(opts, :additional_inputs, false)
      task_uuid = Keyword.fetch!(opts, :task_uuid)

      %__MODULE__{
        additional_inputs: additional_inputs,
        technology: technology,
        hashed_identity: hashed_identity,
        task_uuid: task_uuid,
        submission_identity:
          SubmissionIdentity.new(hashed_identity: hashed_identity, task_uuid: task_uuid)
      }
    end)
  end
end
