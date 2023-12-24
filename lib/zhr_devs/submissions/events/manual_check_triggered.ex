defmodule ZhrDevs.Submissions.Events.ManualCheckTriggered do
  @moduledoc """
  This event is emmited when manual check is about to start.
  """

  @fields [
    uuid: nil,
    task_uuid: nil,
    submissions: [],
    triggered_by: nil,
    submissions_folder: nil,
    triggered_at: nil
  ]
  @enforce_keys Keyword.keys(@fields)
  @derive Jason.Encoder
  defstruct @fields
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Submissions.Events.ManualCheckTriggered do
  alias ZhrDevs.Submissions.Events.ManualCheckTriggered

  def decode(%ManualCheckTriggered{} = event) do
    {:ok, triggered_at, _} = DateTime.from_iso8601(event.triggered_at)

    %ManualCheckTriggered{
      uuid: Uptight.Text.new!(event.uuid),
      submissions_folder: Uptight.Text.new!(event.submissions_folder),
      submissions: Enum.map(event.submissions, &Uptight.Text.new!/1),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      triggered_by: Uptight.Base.mk_url!(event.triggered_by),
      triggered_at: triggered_at
    }
  end
end
