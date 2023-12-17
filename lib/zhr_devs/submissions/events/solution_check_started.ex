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

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Submissions.Events.SolutionCheckStarted do
  alias ZhrDevs.Submissions.Events.SolutionCheckStarted

  def decode(%SolutionCheckStarted{} = event) do
    %SolutionCheckStarted{
      solution_uuid: Uptight.Text.new!(event.solution_uuid),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      solution_path: Uptight.Text.new!(event.solution_path)
    }
  end
end
