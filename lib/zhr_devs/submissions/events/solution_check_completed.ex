defmodule ZhrDevs.Submissions.Events.SolutionCheckCompleted do
  @moduledoc """
  Solution checked event is emmited once we successfully checked the solution.
  """
  alias Uptight.Base.Urlsafe
  alias Uptight.Text, as: T

  @fields [
    solution_uuid: Urlsafe.new(),
    task_id: T.new(),
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
