defmodule ZhrDevs.BakeryIntegration.Commands.GenMultiplayer do
  @moduledoc """
  Generates an OTMG
  """

  use Witchcraft.Functor

  alias Uptight.Text, as: T
  alias Uptight.Result

  @gen_multiplayer [".", "priv", "bakery", "gen_multiplayer"] |> map(&T.new!/1) |> Ubuntu.Path.new!()

  def gen_multiplayer, do: @gen_multiplayer

  def call() do

  end

  def build(opts \\ []) do
    Result.new(fn ->
      %T{} = submissions_folder = Keyword.fetch!(opts, :submissions_folder)
      %T{} = server_code = Keyword.fetch!(opts, :server_code)

      cmd = Ubuntu.Command.new(@gen_multiplayer, [submissions_folder, server_code])

      Ubuntu.new!(cmd)
    end)
  end
end
