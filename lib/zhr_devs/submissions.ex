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

  def attempts(hashed_identity, tech) do
    case lookup_submissions_registry(hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        Submission.attempts(hashed_identity, tech)

      _ ->
        0
    end
  end

  @doc """
  Should return all the information that we need on the individual task page.
  """
  def details(hashed_identity, technology) do
    %{
      technology: technology,
      counter: attempts(hashed_identity, technology),
      task: %{
        id: "MjzJjpWMFMtmfA3FEfu3h0-l3MJvk_RiHabe6pku6Tg=",
        description: "This task is not exists currently"
      },
      invitations: %{
        invited: [],
        interested: ["Company X"]
      }
    }
  end

  defdelegate increment_attempts(hashed_identity, technology), to: Submission

  defp lookup_submissions_registry(hashed_identity) do
    Registry.lookup(ZhrDevs.Registry, {:submissions, hashed_identity})
  end
end
