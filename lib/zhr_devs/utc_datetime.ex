defmodule UtcDateTime do
  @moduledoc """
  Wrapper for DateTime.t() with UTC timezone.
  """

  defstruct [:dt]

  @type t :: %__MODULE__{dt: DateTime.t()}

  def new do
    %__MODULE__{dt: DateTime.utc_now()}
  end

  defimpl Jason.Encoder, for: UtcDateTime do
    def encode(value, _opts) do
      [?", DateTime.to_iso8601(value.dt), ?"]
    end
  end
end
