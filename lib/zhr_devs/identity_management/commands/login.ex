defmodule ZhrDevs.IdentityManagement.Commands.Login do
  @moduledoc """
  A command must contain a field to uniquely identify the aggregate instance (e.g. account_number).
  Use @enforce_keys to force the identity field to be specified when creating the command struct.
  """

  defstruct [:identity, :hashed_identity]

  use Witchcraft.Comonad

  alias ZhrDevs.IdentityManagement.App

  alias Uptight.Result
  alias Uptight.Text, as: T

  @parse_err "Parsing OAuth success struct failed"

  @typep error() :: String.t() | struct()

  @spec dispatch(Keyword.t()) :: :ok | {:error, error()}
  def dispatch(opts) do
    case parse(opts) do
      %Uptight.Result.Ok{} = ok_result ->
        ok_result
        |> Result.from_ok()
        |> App.dispatch()
      error ->
        {:error, error |> extract() |> build_error}
    end
  end

  #### Private functions ####

  defp parse(opts) do
    Result.new(fn ->
      identity = opts |> Keyword.fetch!(:identity) |> T.new() |> Result.from_ok()

      hashed_identity =
        opts |> Keyword.fetch!(:hashed_identity) |> Uptight.Base.mk_url() |> Result.from_ok()

      %__MODULE__{
        identity: identity,
        hashed_identity: hashed_identity
      }
    end)
  end

  defp build_error(%Uptight.Trace{exception: %KeyError{} = key_error}) do
    key_error
  end

  defp build_error(_), do: @parse_err
end
