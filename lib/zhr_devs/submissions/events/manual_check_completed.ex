defmodule ZhrDevs.Submissions.Events.ManualCheckCompleted do
  @moduledoc """
  This event is emmited when manual check is completed successfully.
  """

  @fields [
    uuid: nil,
    task_uuid: nil,
    submissions: [],
    score: %{},
    triggered_by: nil
  ]
  @enforce_keys Keyword.keys(@fields)
  @derive Jason.Encoder
  defstruct @fields
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Submissions.Events.ManualCheckCompleted do
  alias ZhrDevs.Submissions.Events.ManualCheckCompleted

  def decode(%ManualCheckCompleted{} = event) do
    %ManualCheckCompleted{
      uuid: Uptight.Text.new!(event.uuid),
      submissions: Enum.map(event.submissions, &Uptight.Text.new!/1),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      triggered_by: Uptight.Base.mk_url!(event.triggered_by),
      score: event.score
    }
  end
end
