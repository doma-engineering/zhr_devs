defmodule UtcDateTime do
  @moduledoc """
  Wrapper for DateTime.t() with UTC timezone.
  """

  defstruct [:dt]

  @type t :: %__MODULE__{dt: DateTime.t()}

  def new do
    %__MODULE__{dt: DateTime.utc_now()}
  end
end
