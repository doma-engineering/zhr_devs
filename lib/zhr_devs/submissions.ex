defmodule ZhrDevs.Submissions do
  @moduledoc """
  This module is responsible for managing user submissions projections.
  """

  alias ZhrDevs.Submissions.ReadModels.CandidateAttempts
  alias ZhrDevs.Submissions.ReadModels.TournamentRuns

  @typep formatted_attemts :: [%{name: atom(), technology: atom(), counter: integer()}]

  def spawn_candidate_attempts(%Uptight.Base.Urlsafe{} = hashed_identity) do
    DynamicSupervisor.start_child(
      ZhrDevs.DynamicSupervisor,
      {CandidateAttempts, hashed_identity}
    )
  end

  def spawn_tournament_tracker(%Uptight.Text{} = task_uuid) do
    DynamicSupervisor.start_child(
      ZhrDevs.DynamicSupervisor,
      {TournamentRuns, [task_uuid: task_uuid]}
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
  def attempts(%Uptight.Base.Urlsafe{} = hashed_identity) do
    CandidateAttempts.attempts(hashed_identity)
  end

  @spec attempts(Uptight.Base.Urlsafe.t(), ZhrDevs.Task.t()) :: integer()
  def attempts(hashed_identity, %ZhrDevs.Task{} = task) do
    CandidateAttempts.attempts(hashed_identity, task)
  end

  def details(hashed_identity, %ZhrDevs.Task{} = task, results \\ []) do
    %{
      technology: task.technology,
      counter: attempts(hashed_identity, task),
      task: task,
      results: results,
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
