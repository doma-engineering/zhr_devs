defmodule ZhrDevs.Submissions do
  @moduledoc """
  This module is responsible for managing user submissions projections.
  """

  alias ZhrDevs.Submissions.ReadModels.CandidateAttempts

  @typep formatted_attemts :: [%{name: atom(), technology: atom(), counter: integer()}]

  def spawn_candidate_attempts(%Uptight.Base.Urlsafe{} = hashed_identity) do
    DynamicSupervisor.start_child(
      ZhrDevs.DynamicSupervisor,
      {CandidateAttempts, hashed_identity}
    )
  end

  def get_submission(hashed_identity) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        {:ok, pid}

      _ ->
        {:error, :not_found}
    end
  end

  @spec attempts(Uptight.Base.Urlsafe.t()) :: formatted_attemts()
  def attempts(hashed_identity) do
    CandidateAttempts.attempts(hashed_identity)
  end

  @spec attempts(Uptight.Base.Urlsafe.t(), ZhrDevs.Task.t()) :: integer()
  def attempts(hashed_identity, %ZhrDevs.Task{} = task) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        CandidateAttempts.attempts(hashed_identity, task)

      _ ->
        0
    end
  end

  def details(hashed_identity, %ZhrDevs.Task{} = task) do
    %{
      technology: task.technology,
      counter: attempts(hashed_identity, task),
      task: task,
      invitations: %{
        invited: [],
        interested: ["Company X"]
      }
    }
  end

  defdelegate increment_attempts(hashed_identity, task), to: CandidateAttempts

  defp lookup_submissions_registry(hashed_identity) do
    Registry.lookup(ZhrDevs.Registry, {:candidate_attempts, hashed_identity})
  end
end
