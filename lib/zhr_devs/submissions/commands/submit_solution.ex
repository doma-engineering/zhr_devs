defmodule ZhrDevs.Submissions.Commands.SubmitSolution do
  @moduledoc """
  A command must contain a field to uniquely identify the aggregate instance (e.g. account_number).
  Use @enforce_keys to force the identity field to be specified when creating the command struct.
  """
  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias Uptight.Base.Urlsafe

  @fields [:uuid, :submission_identity] ++ SolutionSubmitted.command_fields()
  defstruct @fields

  @type t :: %{
          :__struct__ => __MODULE__,
          required(:technology) => atom(),
          required(:uuid) => Urlsafe.t(),
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_uuid) => Urlsafe.t(),
          required(:solution_path) => list(Urlsafe.t()),
          required(:submission_identity) => ZhrDevs.Submissions.SubmissionIdentity.t()
        }

  alias Uptight.Result
  alias Uptight.Text, as: T

  alias ZhrDevs.App

  alias ZhrDevs.Submissions.SubmissionIdentity

  import Uptight.Assertions

  @supported_technologies Enum.map(
                            Application.compile_env(:zhr_devs, :supported_technologies),
                            &Atom.to_string/1
                          )

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

      task_uuid =
        opts
        |> Keyword.fetch!(:task_uuid)
        |> Uptight.Base.mk_url!()

      uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()

      solution_path = check_solution_path(opts)

      %__MODULE__{
        uuid: uuid,
        hashed_identity: hashed_identity,
        technology: technology,
        task_uuid: task_uuid,
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

    T.new!(solution_path)
  end

  defp unpack_technology(opts) do
    passed_technology_downcase =
      opts
      |> Keyword.fetch!(:technology)
      |> String.downcase()

    assert passed_technology_downcase in @supported_technologies,
           "Technology #{passed_technology_downcase} is not supported"

    String.to_existing_atom(passed_technology_downcase)
  end
end
