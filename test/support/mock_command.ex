defmodule ZhrDevs.Support.MockCommand do
  @moduledoc false

  alias Uptight.Result

  alias ZhrDevs.BakeryIntegration.Commands.Command

  require Logger

  @behaviour Command

  import ZhrDevs.Fixtures, only: [long_running_command: 0]

  @impl Command
  def run(%Ubuntu.Command{} = cmd) do
    ZhrDevs.BakeryIntegration.run_command(cmd)
  end

  @impl Command
  def build(_) do
    Result.new(fn ->
      [
        cmd: long_running_command(),
        on_success: {__MODULE__, :on_success, [[some: :opts]]},
        on_failure: {__MODULE__, :on_failure, [[some: :opts]]},
        command_module: __MODULE__
      ]
    end)
  end

  @impl Command
  def on_success(opts) do
    Logger.info("MockCommand.on_success/1 called with opts: #{inspect(opts)}")

    :ok
  end

  @impl Command
  def on_failure(system_error, opts) do
    Logger.info(
      "MockCommand.on_failure/2 called with system_error: #{inspect(system_error)}. opts: #{inspect(opts)};"
    )

    :ok
  end
end
