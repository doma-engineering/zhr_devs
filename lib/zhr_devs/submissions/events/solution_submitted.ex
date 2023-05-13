defmodule ZhrDevs.Submissions.Events.SolutionSubmitted do
  @moduledoc """
  Represents an event that is emitted when a solution is submitted.
  """

  @derive Jason.Encoder
  import Algae

  defdata do
    uuid :: Uptight.Base.Urlsafe.t()
    hashed_identity :: Uptight.Base.Urlsafe.t()
    task_uuid :: Uptight.Base.Urlsafe.t()
    technology :: atom()
    solution_path :: list(Uptight.Base.Urlsafe.t())
  end
end
