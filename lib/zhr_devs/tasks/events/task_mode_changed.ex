defmodule ZhrDevs.Tasks.Events.TaskModeChanged do
  @moduledoc """
  Represents an event that is emitted when user is changed the task processing mode (manual or automatic).
  """
  @fields [:technology, :name, :trigger_automatic_check]
  @enforce_keys [:technology, :name, :trigger_automatic_check]
  @derive Jason.Encoder
  defstruct @fields

  @typedoc """
  Left side of the `|` (binary()) represent raw values coming from the external world,
  right side of the `|` (atom() & Text.t()) represent values that are used internally.
  """
  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:name) => binary() | atom(),
          required(:trigger_automatic_check) => boolean() | boolean(),
          required(:technology) => binary() | atom()
        }

  def fields, do: @fields
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Tasks.Events.TaskModeChanged do
  alias ZhrDevs.Tasks.Events.TaskModeChanged

  def decode(%TaskModeChanged{
        name: name = <<_::binary>>,
        technology: technology = <<_::binary>>,
        trigger_automatic_check: trigger_automatic_check
      })
      when is_boolean(trigger_automatic_check) do
    %TaskModeChanged{
      name: String.to_existing_atom(name),
      technology: String.to_existing_atom(technology),
      trigger_automatic_check: trigger_automatic_check
    }
  end
end
