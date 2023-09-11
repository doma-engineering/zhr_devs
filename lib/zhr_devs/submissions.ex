defmodule ZhrDevs.Submissions do
  @moduledoc """
  This module is responsible for managing user submissions projections.
  """

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.ReadModels.Submission

  def spawn_submission(%SolutionSubmitted{} = submitted_solution_event) do
    DynamicSupervisor.start_child(
      ZhrDevs.DynamicSupervisor,
      {Submission, submitted_solution_event}
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

  def attempts(hashed_identity) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        Submission.attempts(hashed_identity)

      _ ->
        Submission.default_counter()
    end
  end

  def attempts(hashed_identity, name, technology) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        Submission.attempts(hashed_identity, name, technology)

      _ ->
        0
    end
  end

  def details(hashed_identity, name, technology) do
    %{
      technology: technology,
      counter: attempts(hashed_identity, name, technology),
      task: %{
        id: "#{technology}-0-dev",
        description: "This task does not currently exist."
      },
      invitations: %{
        invited: [],
        interested: ["Company X"]
      }
    }
  end

  defdelegate increment_attempts(hashed_identity, task_uuid), to: Submission

  defp lookup_submissions_registry(hashed_identity) do
    Registry.lookup(ZhrDevs.Registry, {:submissions, hashed_identity})
  end
end
