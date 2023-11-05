defmodule ZhrDevs.Submissions.Events.SolutionCheckCompleted do
  @moduledoc """
  Solution checked event is emmited once we successfully checked the solution.
  """
  alias Uptight.Text
  # alias Uptight.Base.Urlsafe

  @fields [
    solution_uuid: Text.new(),
    task_uuid: Text.new(),
    score: %{}
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

defimpl Commanded.Serialization.JsonDecoder,
  for: ZhrDevs.Submissions.Events.SolutionCheckCompleted do
  alias ZhrDevs.Submissions.Events.SolutionCheckCompleted

  def decode(%SolutionCheckCompleted{} = event) do
    %SolutionCheckCompleted{
      solution_uuid: Uptight.Text.new!(event.solution_uuid),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      score: event.score
    }
  end
end
