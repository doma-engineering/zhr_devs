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

  def attempts(hashed_identity, %ZhrDevs.Task{} = task) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        Submission.attempts(hashed_identity, task)

      _ ->
        0
    end
  end

  # TODO: What is this function even. Why don't we just say `task: task`? I made this change, I think it makes sense.
  def details(hashed_identity, %ZhrDevs.Task{} = task) do
    %{
      technology: task.technology,
      counter: attempts(hashed_identity, task),
      # task: %{
      # id: "#{task.technology}-0-dev",
      # description: "This task does not currently exist."
      # },
      task: task,
      invitations: %{
        invited: [],
        interested: ["Company X"]
      }
    }
  end

  defdelegate increment_attempts(hashed_identity, task), to: Submission

  defp lookup_submissions_registry(hashed_identity) do
    Registry.lookup(ZhrDevs.Registry, {:submissions, hashed_identity})
  end
end
