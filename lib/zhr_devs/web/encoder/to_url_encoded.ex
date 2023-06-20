defmodule ZhrDevs.Web.Encoder.ToUrlEncoded do
  @moduledoc false

  alias Uptight.Text, as: T
  alias Uptight.Text.Urlencoded, as: TU

  def call(struct) do
    struct
    |> Jason.encode!()
    |> T.new!()
    |> TU.new!()
  end
end
