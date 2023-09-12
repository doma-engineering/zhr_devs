defmodule UpToCounter do
  @moduledoc """
  Represents counter that can be incremented up to some maximum value.

  m - maximum counter value
  i - current counter value

  The `including?` boolean configuration is used to control wether counter
  value can be equal to maximum value or not.
  """

  import Algae

  defdata do
    m :: non_neg_integer()
    i :: non_neg_integer()
    including? :: boolean()
  end

  @spec increment(t()) :: t()
  def increment(%__MODULE__{m: max, i: i, including?: false} = counter) when i + 1 < max do
    %__MODULE__{counter | i: i + 1}
  end

  def increment(%__MODULE__{m: max, i: i, including?: true} = counter) when i + 1 <= max do
    %__MODULE__{counter | i: i + 1}
  end

  def increment(%__MODULE__{} = counter), do: counter
end
