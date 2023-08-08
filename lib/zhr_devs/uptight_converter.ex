defmodule ZhrDevs.UptightConverter do
  @moduledoc """
  Converts raw data and Uptight structs.
  """

  defmodule Sixteen do
    @spec from(binary | %Uptight.Binary{} | %Uptight.Base.Sixteen{}) :: %Uptight.Base.Sixteen{}
    def from(<<x::binary>>) do
      %Uptight.Base.Sixteen{
        encoded: Base.encode16(x, case: :lower),
        raw: x
      }
    end

    def from(%Uptight.Base.Sixteen{} = x), do: x

    def from(%Uptight.Binary{} = x) do
      x
      |> Uptight.Binary.un()
      |> from()
    end

    @spec from_raw(binary) :: %Uptight.Base.Sixteen{}
    def from_raw(<<x::binary>>), do: from(<<x::binary>>)

    @spec from_binary(%Uptight.Binary{}) :: %Uptight.Base.Sixteen{}
    def from_binary(%Uptight.Binary{} = x), do: from(x)

    @spec to_binary(%Uptight.Base.Sixteen{}) :: %Uptight.Binary{}
    def to_binary(%Uptight.Base.Sixteen{} = x), do: %Uptight.Binary{binary: x.raw}

    @spec to_raw(%Uptight.Base.Sixteen{}) :: binary()
    def to_raw(%Uptight.Base.Sixteen{} = x), do: x.raw
  end
end
