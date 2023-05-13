defmodule ZhrDevs.Submissions do
  @moduledoc """
  This module is responsible for managing user submissions projections.
  """

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.ReadModels.Submissions

  def spawn_submission(%SolutionSubmitted{} = submitted_solution_event) do
    DynamicSupervisor.start_child(
      ZhrDevs.DynamicSupervisor,
      {Submissions, submitted_solution_event}
    )
  end

  def get_submission(hashed_identity) do
    case Registry.lookup(ZhrDevs.Registry, {:submissions, hashed_identity}) do
      [{pid, _}] when is_pid(pid) ->
        {:ok, pid}

      _ ->
        {:error, :not_found}
    end
  end

  defdelegate increment_attempts(hashed_identity, technology), to: Submissions

  defdelegate attempts(hashed_identity), to: Submissions
end
