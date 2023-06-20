defmodule ZhrDevs.Submissions.Events.SolutionCheckStarted do
  @moduledoc """
  Solution checked event is emmited once we successfully checked the solution.
  """
  alias Uptight.Base.Urlsafe
  alias Uptight.Text, as: T

  @fields [
    task_id: T.new(),
    solution_uuid: Urlsafe.new(),
    solution_path: Urlsafe.new()
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
