defmodule ZhrDevs.Tasks.Events.TaskSupported do
  @moduledoc """
  Represents an event that is emitted when user is allowed to download a task before the first submission.
  """
  alias Uptight.Text

  @fields [
    technology: nil,
    name: nil,
    task_uuid: Text.new()
  ]
  @derive Jason.Encoder
  defstruct @fields

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:name) => binary() | atom(),
          required(:task_uuid) => binary() | Text.t(),
          required(:technology) => binary() | atom()
        }

  def fields, do: @fields
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Tasks.Events.TaskSupported do
  alias ZhrDevs.Tasks.Events.TaskSupported

  def decode(%TaskSupported{
        name: name = <<_::binary>>,
        task_uuid: task_uuid = <<_::binary>>,
        technology: technology = <<_::binary>>
      }) do
    %TaskSupported{
      name: String.to_existing_atom(name),
      task_uuid: Uptight.Text.new!(task_uuid),
      technology: String.to_existing_atom(technology)
    }
  end
end
