defmodule ZhrDevs.BakeryIntegration.CommandRunnerTest do
  use ExUnit.Case, async: false
  use Witchcraft.Functor

  alias ZhrDevs.BakeryIntegration.CommandRunner

  alias Uptight.Text, as: T

  @moduletag :capture_log

  @long_running_script_path [".", "test", "support", "long_running.sh"]
                            |> map(&T.new!/1)
                            |> Ubuntu.Path.new!()

  describe "exit status message received from port" do
    test "it sends :execution_stopped error to the callback" do
      {:ok, pid} = run_command(cmd: long_running_command())

      Process.monitor(pid)

      %{port: port} = :sys.get_state(pid)
      send(pid, {port, {:exit_status, 11}})

      assert_receive {:DOWN, _, _, _, {:shutdown, %{error: :execution_stopped, exit_status: 11}}},
                     200
    end
  end

  describe "data from port" do
    test "it saves the latest data received from port" do
      {:ok, pid} = run_command(cmd: long_running_command())

      %{port: port} = :sys.get_state(pid)
      send(pid, {port, {:data, "data from port\n"}})
      send(pid, {port, {:data, "\n\n\ndata from port 2"}})

      assert %{latest_output: "data from port 2"} = :sys.get_state(pid)
    end

    test "with Logger configuration - creates a logger backend with the provided metadata" do
      {:ok, pid} =
        run_command(
          cmd: long_running_command(),
          logger_metadata: [backend: :runner_id, path: "/tmp/runner_id.log"]
        )

      %{port: port} = :sys.get_state(pid)

      send(pid, {port, {:data, "data from port\n"}})

      assert File.exists?("/tmp/runner_id.log")
      assert File.read!("/tmp/runner_id.log") =~ "data from port"

      clean_up_tmp()
    end
  end

  defp run_command(opts) do
    start_supervised({CommandRunner, opts})
  end

  defp long_running_command do
    Ubuntu.Command.new!(@long_running_script_path, [])
  end

  def clean_up_tmp do
    File.rm("/tmp/runner_id.log")

    :ok
  end
end
