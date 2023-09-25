defmodule ZhrDevs.Tasks.Events.TaskSupported do
  @moduledoc """
  Represents an event that is emitted when user is allowed to download a task before the first submission.
  """
  alias Uptight.Text

  @fields [
    technology: nil,
    name: nil,
    trigger_automatic_check: false,
    task_uuid: Text.new()
  ]
  @enforce_keys [:technology, :name, :trigger_automatic_check, :task_uuid]
  @derive Jason.Encoder
  defstruct @fields

  @typedoc """
  Left side of the `|` (binary()) represent raw values coming from the external world,
  right side of the `|` (atom() & Text.t()) represent values that are used internally.
  """
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
        technology: technology = <<_::binary>>,
        trigger_automatic_check: trigger_automatic_check
      }) do
    %TaskSupported{
      name: String.to_existing_atom(name),
      task_uuid: Uptight.Text.new!(task_uuid),
      technology: String.to_existing_atom(technology),
      trigger_automatic_check: trigger_automatic_check
    }
  end

  def decode(%TaskSupported{} = event), do: event
end
