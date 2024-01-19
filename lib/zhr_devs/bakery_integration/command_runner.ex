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
    defstruct [:port, :latest_output, :exit_status, :timeout_ref, :logger_meta]
  end

  @spec start_link(Command.options()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    %Ubuntu.Command{} = cmd = Keyword.fetch!(opts, :cmd)
    logger_metadata = Keyword.get(opts, :logger_metadata, [])

    GenServer.start_link(__MODULE__, {cmd, logger_metadata})
  end

  def init({cmd, logger_metadata}) do
    Process.flag(:trap_exit, true)

    logger_meta = configure_logger(logger_metadata)

    port =
      Port.open(
        {:spawn_executable, cmd.path |> Ubuntu.Path.render() |> T.un()},
        [:binary, args: cmd.args |> map(&T.un/1)]
      )

    Port.monitor(port)

    {:ok, %State{port: port, logger_meta: logger_meta}}
  end

  # This callback handles data incoming from the command's STDOUT
  def handle_info({port, {:data, text_line}}, %{port: port} = state) do
    Logger.info(text_line, runner_id: state.logger_meta)

    {:noreply,
     %State{
       state
       | latest_output: String.trim(text_line),
         timeout_ref: maybe_reset_timer(state.timeout_ref)
     }}
  end

  # This callback tells us when the process exits
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("Port exit: :exit_status: #{status}", runner_id: state.logger_meta)

    formatted_error = %{
      error: :execution_stopped,
      context: state.latest_output,
      exit_status: status
    }

    {:stop, {:shutdown, formatted_error}, state}
  end

  def handle_info({:DOWN, _ref, :port, port, :normal}, state) do
    Logger.info("Handled :DOWN message from port with :normal reason #{inspect(port)}",
      runner_id: state.logger_meta
    )

    {:stop, :normal, state}
  end

  def handle_info(:timeout, %{port: port} = state) do
    Logger.error("No output from Port for 2 minutes. Terminating.\nPort info: #{Port.info(port)}",
      runner_id: state.logger_meta
    )

    formatted_error = %{
      error: :timeout_reached,
      context: state.latest_output
    }

    {:stop, {:shutdown, formatted_error}, state}
  end

  def handle_info({:EXIT, _, _}, state) do
    {:noreply, state}
  end

  def handle_info(msg, state) do
    # Ideally we want to be notified about all messages that we don't handle
    Logger.warning("Unhandled message: #{inspect(msg)}", runner_id: state.logger_meta)

    {:noreply, state}
  end

  def terminate(_reason, state) do
    if not is_nil(state.logger_meta),
      do: Logger.remove_backend({LoggerFileBackend, state.logger_meta})
  end

  defp maybe_reset_timer(nil) do
    Process.send_after(self(), :timeout, :timer.minutes(2))
  end

  defp maybe_reset_timer(timeout_ref) when is_reference(timeout_ref) do
    _ = Process.cancel_timer(timeout_ref)

    maybe_reset_timer(nil)
  end

  defp configure_logger([]) do
    nil
  end

  defp configure_logger(backend: runner_id, path: path) do
    Logger.add_backend({LoggerFileBackend, runner_id}, flush: true)

    :ok =
      Logger.configure_backend({LoggerFileBackend, runner_id},
        path: path,
        level: :info,
        metadata_filter: [runner_id: runner_id]
      )

    runner_id
  end
end
