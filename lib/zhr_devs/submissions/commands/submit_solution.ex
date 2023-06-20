defmodule ZhrDevs.Submissions.Commands.SubmitSolution do
  @moduledoc """
  A command must contain a field to uniquely identify the aggregate instance (e.g. account_number).
  Use @enforce_keys to force the identity field to be specified when creating the command struct.
  """
  alias ZhrDevs.App

  alias ZhrDevs.Submissions.SubmissionIdentity

  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  alias Uptight.Base.Urlsafe
  alias Uptight.Result
  alias Uptight.Text, as: T
  alias Uptight.Text.Urlencoded, as: TU

  import ZhrDevs.Submissions.Commands.Parsing.Shared

  @fields [:uuid, :submission_identity] ++ SolutionSubmitted.fields()
  defstruct @fields

  @type t :: %{
          :__struct__ => __MODULE__,
          required(:technology) => atom(),
          required(:uuid) => Urlsafe.t(),
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_id) => TU.t(),
          required(:solution_path) => list(Urlsafe.t()),
          required(:submission_identity) => SubmissionIdentity.t()
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

  #### Private functions ####

  defp parse(opts) do
    Result.new(fn ->
      hashed_identity =
        opts
        |> Keyword.fetch!(:hashed_identity)
        |> Uptight.Base.mk_url!()

      technology = unpack_technology(opts)

      task_id =
        opts
        |> Keyword.fetch!(:task_id)
        |> Jason.encode!()
        |> T.new!()
        |> TU.new!()

      uuid =
        opts
        |> Keyword.get(:uuid, Commanded.UUID.uuid4())
        |> Uptight.Base.mk_url!()

      solution_path = check_solution_path(opts)

      %__MODULE__{
        uuid: uuid,
        hashed_identity: hashed_identity,
        technology: technology,
        task_id: task_id,
        solution_path: solution_path,
        submission_identity:
          SubmissionIdentity.new(hashed_identity: hashed_identity, technology: technology)
      }
    end)
  end

  defp check_solution_path(opts) do
    solution_path = Keyword.fetch!(opts, :solution_path)

    unless File.exists?(solution_path) do
      raise ArgumentError, "Solution path is invalid: #{solution_path}"
    end

    unless valid_zip_file?(solution_path) do
      raise ArgumentError, "Not a zip file!"
    end

    T.new!(solution_path)
  end

  defp valid_zip_file?(solution_absolute_path) do
    solution_absolute_path
    |> Path.relative_to_cwd()
    |> ZhrDevs.Docker.zip_test()
  end
end
