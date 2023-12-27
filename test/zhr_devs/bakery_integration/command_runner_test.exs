defmodule ZhrDevs.BakeryIntegration.CommandRunnerTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.BakeryIntegration.CommandRunner

  import ExUnit.CaptureLog
  import ZhrDevs.Fixtures, only: [long_running_command: 0]

  @moduletag :capture_log

  @logger_meta %{
    backend: :runner_id,
    path: "/tmp/runner_id.log"
  }

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

    @tag fs: true
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

  describe "handling of :timeout message" do
    test "it output logs correctly and stops the process" do
      {output, log} =
        with_log([level: :error], fn ->
          CommandRunner.handle_info(:timeout, %{
            port: :port,
            latest_output: "latest output",
            logger_meta: @logger_meta
          })
        end)

      assert log =~ "No output from Port for 2 minutes. Terminating."

      assert {:stop, {:shutdown, %{error: :timeout_reached}}, _} = output
    end
  end

  describe "unhandled messages" do
    test "it output warning logs correctly and do not stops the process" do
      {output, log} =
        with_log([level: :warning], fn ->
          CommandRunner.handle_info(:nonexisted, %{
            port: :port,
            latest_output: "latest output",
            logger_meta: @logger_meta
          })
        end)

      assert log =~ "Unhandled message"

      assert {:noreply, _} = output
    end
  end

  defp run_command(opts) do
    start_supervised({CommandRunner, opts})
  end

  def clean_up_tmp do
    File.rm("/tmp/runner_id.log")

    :ok
  end
end
