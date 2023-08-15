defmodule ZhrDevs.Submissions.Events.SolutionCheckStarted do
  @moduledoc """
  Solution checked event is emmited once we successfully checked the solution.
  """
  alias Uptight.Text
  # alias Uptight.Base.Urlsafe

  @fields [
    solution_uuid: Text.new!(""),
    task_uuid: Text.new!(""),
    solution_path: Text.new!("")
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
