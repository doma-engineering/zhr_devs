defmodule ZhrDevs.Submissions.Events.SolutionCheckStarted do
  @moduledoc """
  Solution checked event is emmited once we successfully checked the solution.
  """
  alias Uptight.Base.Urlsafe

  @fields [
    solution_uuid: Urlsafe.new(),
    task_uuid: Urlsafe.new(),
    solution_path: Urlsafe.new()
  ]
  @enforce_keys Keyword.keys(@fields)
  defstruct @fields

  def fields do
    @fields
  end

  @spec fields_keys() :: [atom()]
  def fields_keys do
    Keyword.keys(@fields)
  end
end
