defmodule ZhrDevs.BakeryIntegration.Commands.GenMultiplayer do
  @moduledoc """
  Generates an OTMG
  """

  use Witchcraft.Functor

  @behaviour ZhrDevs.BakeryIntegration.Commands.Command

  require Logger

  alias Uptight.Text, as: T
  alias Uptight.Result

  @gen_multiplayer [".", "priv", "bakery", "gen_multiplayer"]
                   |> map(&T.new!/1)
                   |> Ubuntu.Path.new!()

  def gen_multiplayer, do: @gen_multiplayer

  def run(opts) do
    case build(opts) do
      %Result.Ok{ok: fields} ->
        cmd = Keyword.fetch!(fields, :cmd)
        output_json_path = Keyword.fetch!(fields, :output_json_path)

        ZhrDevs.BakeryIntegration.CommandRunner.start_link(
          cmd: cmd,
          on_success: fn -> __MODULE__.on_success(output_json_path) end,
          on_failure: fn error -> __MODULE__.on_failure(error) end
        )

      error ->
        error
    end
  end

  def build(opts \\ []) do
    Result.new(fn ->
      %T{} = submissions_folder = Keyword.fetch!(opts, :submissions_folder)
      %T{} = server_code = Keyword.fetch!(opts, :server_code)
      task = Keyword.fetch!(opts, :task)

      [
        cmd: Ubuntu.Command.new(@gen_multiplayer, [submissions_folder, server_code]),
        output_json_path: output_json_path(task)
      ]
    end)
  end

  def on_success(output_file_path) do
    if File.exists?(output_file_path) do
      Logger.info("Successfully generated tournament output: #{inspect(output_file_path)}")

      # We want to issue a command here for sure.
      :ok
    else
      Logger.error("Failed to generate multiplayer: #{inspect(output_file_path)}")

      {:error, "#{output_file_path} file doesn't exist"}
    end
  end

  def on_failure(%{error: :on_success_not_met, context: context}) do
    Logger.error(
      "Multiplayer generation process is completed successfully, but output.json doesn't get generated.\nLatest output: #{context}"
    )

    :ok
  end

  def on_failure(%{error: :execution_stopped, context: context, exit_code: code}) do
    Logger.error(
      "Multiplayer generation process is stopped with exit code: #{code}.\nLatest output: #{context}"
    )

    :ok
  end

  def output_json_path(task) do
    Path.join([File.cwd!(), "tournament", task, "output.json"])
  end
end
