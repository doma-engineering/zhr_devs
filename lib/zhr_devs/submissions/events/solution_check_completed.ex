defmodule ZhrDevs.Submissions.Events.SolutionCheckCompleted do
  @moduledoc """
  Solution checked event is emmited once we successfully checked the solution.
  """
  alias Uptight.Base.Urlsafe

  @fields [
    solution_uuid: Urlsafe.new(),
    task_uuid: Urlsafe.new(),
    points: 0
  ]
  @enforce_keys Keyword.keys(@fields)
  @derive Jason.Encoder
  defstruct @fields

  def fields do
    @fields
  end

  @spec fields_keys() :: [atom()]
  def fields_keys do
    Keyword.keys(@fields)
  end
end
