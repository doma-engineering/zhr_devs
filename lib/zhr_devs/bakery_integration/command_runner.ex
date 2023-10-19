defmodule ZhrDevs.BakeryIntegration.CommandRunner do
  @moduledoc """
  Generic process that will run the given command
  """
  use GenServer

  alias Uptight.Text, as: T

  import Witchcraft.Functor

  require Logger

  defmodule State do
    defstruct [:port, :latest_output, :exit_status]
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    cmd = Keyword.fetch!(opts, :cmd)

    port =
      Port.open(
        {:spawn_executable, cmd.path |> Ubuntu.Path.render() |> T.un()},
        [:binary, args: cmd.args |> map(&T.un/1)]
      )

    Port.monitor(port)

    {:ok, %State{port: port}}
  end

  # This callback handles data incoming from the command's STDOUT
  def handle_info({port, {:data, text_line}}, %{port: port} = state) do
    Logger.info("Data: #{inspect(text_line)}")
    {:noreply, %State{state | latest_output: String.trim(text_line)}}
  end

  # This callback tells us when the process exits
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("Port exit: :exit_status: #{status}")

    new_state = %State{state | exit_status: status}

    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :port, port, :normal}, state) do
    Logger.info("Handled :DOWN message from port: #{inspect(port)}")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
