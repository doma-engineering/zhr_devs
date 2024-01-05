defmodule ZhrDevs.BakeryIntegration.CommandRunner do
  @moduledoc """
  Generic process that will run the given command

  To run successfully the command must implement the ZhrDevs.BakeryIntegration.Commands.Command behaviour

  If at any point in time process terminates abnormally it would be restarted, because it's transient.

  If there is no output from the port for 2 minutes, the process will be terminated.
  """
  use GenServer, restart: :transient

  alias ZhrDevs.BakeryIntegration.Commands.Command

  alias Uptight.Text, as: T

  import Witchcraft.Functor

  require Logger

  defmodule State do
    @moduledoc """
    State of the individual process
    """
    defstruct [:port, :latest_output, :exit_status, :timeout_ref]
  end

  @spec start_link(Command.cmd()) :: {:ok, pid()} | {:error, term()}
  def start_link(%Ubuntu.Command{} = cmd) do
    GenServer.start_link(__MODULE__, cmd)
  end

  def init(cmd) do
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
    {:noreply,
     %State{
       state
       | latest_output: String.trim(text_line),
         timeout_ref: maybe_reset_timer(state.timeout_ref)
     }}
  end

  # This callback tells us when the process exits
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("Port exit: :exit_status: #{status}")

    formatted_error = %{
      error: :execution_stopped,
      context: state.latest_output,
      exit_status: status
    }

    {:stop, {:shutdown, formatted_error}, state}
  end

  def handle_info({:DOWN, _ref, :port, port, :normal}, state) do
    Logger.info("Handled :DOWN message from port with :normal reason #{inspect(port)}")

    {:stop, :normal, state}
  end

  def handle_info(:timeout, %{port: port} = state) do
    Logger.error("No output from Port for 2 minutes. Terminating.\nPort info: #{Port.info(port)}")

    formatted_error = %{
      error: :timeout_reached,
      context: state.latest_output
    }

    {:stop, {:shutdown, formatted_error}, state}
  end

  def handle_info(msg, state) do
    # Ideally we want to be notified about all messages that we don't handle
    Logger.warning("Unhandled message: #{inspect(msg)}")

    {:noreply, state}
  end

  defp maybe_reset_timer(nil) do
    Process.send_after(self(), :timeout, :timer.minutes(2))
  end

  defp maybe_reset_timer(timeout_ref) when is_reference(timeout_ref) do
    _ = Process.cancel_timer(timeout_ref)

    maybe_reset_timer(nil)
  end
end
