defmodule ZhrDevs.Submissions do
  @moduledoc """
  This module is responsible for managing user submissions projections.
  """

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.ReadModels.CandidateAttempts

  def spawn_submission(%SolutionSubmitted{} = submitted_solution_event) do
    DynamicSupervisor.start_child(
      ZhrDevs.DynamicSupervisor,
      {CandidateAttempts, submitted_solution_event}
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

  @spec attempts(Uptight.Text.t()) :: CandidateAttempts.t()
  def attempts(hashed_identity) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        CandidateAttempts.attempts(hashed_identity)

      _ ->
        CandidateAttempts.default_attempts()
    end
  end

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
    Registry.lookup(ZhrDevs.Registry, {:submissions, hashed_identity})
  end
end
