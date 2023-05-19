defmodule ZhrDevs.Web.Presentation.Helper do
  @moduledoc false

  use Witchcraft.Comonad

  alias Uptight.Result.Err
  alias Uptight.Trace

  def extract_error(%Err{} = exception), do: exception |> extract() |> extract_error()

  def extract_error(%Trace{exception: %MatchError{term: %Err{} = exception}}),
    do: exception |> extract() |> extract_error()

  def extract_error(%Trace{exception: exception}), do: exception
  def extract_error(exception), do: exception
end
