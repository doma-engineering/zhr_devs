defmodule ZhrDevs.Submissions.Events.ManualCheckFailed do
  @moduledoc """
  This event is emmited when manual check is failed to run for 3 times.
  """

  @fields [
    uuid: nil,
    task_uuid: nil,
    submissions: [],
    system_error: %{},
    triggered_by: nil
  ]
  @enforce_keys Keyword.keys(@fields)
  @derive Jason.Encoder
  defstruct @fields
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Submissions.Events.ManualCheckFailed do
  alias ZhrDevs.Submissions.Events.ManualCheckFailed

  def decode(%ManualCheckFailed{} = event) do
    %ManualCheckFailed{
      uuid: Uptight.Text.new!(event.uuid),
      submissions: Enum.map(event.submissions, &Uptight.Text.new!/1),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      system_error: event.system_error,
      triggered_by: Uptight.Base.mk_url!(event.triggered_by)
    }
  end
end
