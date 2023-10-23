defmodule ZhrDevs.BakeryIntegration.CommandRunner do
  @moduledoc """
  Generic process that will run the given command

  To run successfully the command must implement the ZhrDevs.BakeryIntegration.Commands.Command behaviour

  on_success is zero arity function that will be called when the command finishes successfully.
  on_failure is one arity function that will be called when the command fails.

  If at any point in time process terminates abnormally it would be restarted, because it's transient.
  """
  use GenServer, restart: :transient

  alias Uptight.Text, as: T

  import Witchcraft.Functor

  require Logger

  defmodule State do
    @moduledoc """
    State of the individual process
    """
    defstruct [:port, :latest_output, :exit_status, :on_success, :on_failure]
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    cmd = Keyword.fetch!(opts, :cmd)
    on_success = Keyword.fetch!(opts, :on_success)
    on_failure = Keyword.fetch!(opts, :on_failure)

    port =
      Port.open(
        {:spawn_executable, cmd.path |> Ubuntu.Path.render() |> T.un()},
        [:binary, args: cmd.args |> map(&T.un/1)]
      )

    Port.monitor(port)

    {:ok, %State{port: port, on_success: on_success, on_failure: on_failure}}
  end

  # This callback handles data incoming from the command's STDOUT
  def handle_info({port, {:data, text_line}}, %{port: port} = state) do
    {:noreply, %State{state | latest_output: String.trim(text_line)}}
  end

  # This callback tells us when the process exits
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.info("Port exit: :exit_status: #{status}")

    error = %{error: :execution_stopped, context: state.latest_output, exit_status: status}
    :ok = state.on_failure.(error)

    {:stop, :shutdown, state}
  end

  def handle_info({:DOWN, _ref, :port, port, :normal}, state) do
    Logger.info("Handled :DOWN message from port: #{inspect(port)}")

    case state.on_success.() do
      :ok ->
        {:stop, :normal, state}

      {:error, error} ->
        formatted_error = %{error: :on_success_not_met, context: state.latest_output}

        :ok = state.on_failure.(formatted_error)

        {:stop, {:shutdown, {error, state.latest_output}}, state}
    end
  end

  def handle_info(msg, state) do
    # Ideally we want to be notified about all messages that we don't handle
    Logger.warning("Unhandled message: #{inspect(msg)}")

    {:noreply, state}
  end
end
