defmodule ZhrDevs.Submissions.Events.SolutionCheckFailed do
  @moduledoc """
  This event is emitted when solution is failed to terminate successfully.

  This means, that we should mark the solution as 'explosive' and move it away
  from the other solutions.
  """

  alias Uptight.Text

  @fields [
    solution_uuid: Text.new(),
    task_uuid: Text.new(),
    system_error: %{}
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
  for: ZhrDevs.Submissions.Events.SolutionCheckFailed do
  alias ZhrDevs.Submissions.Events.SolutionCheckFailed

  def decode(%SolutionCheckFailed{} = event) do
    %SolutionCheckFailed{
      solution_uuid: Uptight.Text.new!(event.solution_uuid),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      system_error: event.system_error
    }
  end
end
