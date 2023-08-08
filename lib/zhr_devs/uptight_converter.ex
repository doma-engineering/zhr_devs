defmodule ZhrDevs.UptightConverter do
  @moduledoc """
  Converts raw data and Uptight structs.
  """

  defmodule Sixteen do
    @moduledoc """
    Convenience functions for base 16.
    """

    @spec from(binary() | Uptight.Binary.t() | Uptight.Base.Sixteen.t()) ::
            Uptight.Base.Sixteen.t()
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

    @spec from_raw(binary) :: Uptight.Base.Sixteen.t()
    def from_raw(<<x::binary>>), do: from(<<x::binary>>)

    @spec from_binary(Uptight.Binary.t()) :: Uptight.Base.Sixteen.t()
    def from_binary(%Uptight.Binary{} = x), do: from(x)

    @spec to_binary(Uptight.Base.Sixteen.t()) :: Uptight.Binary.t()
    def to_binary(%Uptight.Base.Sixteen{} = x), do: %Uptight.Binary{binary: x.raw}

    @spec to_raw(Uptight.Base.Sixteen.t()) :: binary()
    def to_raw(%Uptight.Base.Sixteen{} = x), do: x.raw
  end
end
