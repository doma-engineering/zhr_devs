defmodule ZhrDevs.Tasks.Events.TaskSupported do
  @moduledoc """
  Represents an event that is emitted when user is allowed to download a task before the first submission.
  """
  alias Uptight.Base.Urlsafe
  alias Uptight.Text

  @fields [
    technology: nil,
    task_uuid: Text.new(),
    name: Urlsafe.new()
  ]
  @derive Jason.Encoder
  defstruct @fields

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:name) => Urlsafe.t(),
          required(:task_uuid) => Text.t(),
          required(:technology) => atom()
        }

  def fields, do: @fields
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Tasks.Events.TaskSupported do
  alias ZhrDevs.Tasks.Events.TaskSupported

  def decode(%TaskSupported{name: name, task_uuid: task_uuid, technology: technology}) do
    %TaskSupported{
      name: String.to_existing_atom(name),
      task_uuid: Uptight.Text.new!(task_uuid),
      technology: String.to_existing_atom(technology)
    }
  end
end
