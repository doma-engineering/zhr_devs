defmodule ZhrDevs.BakeryIntegration.CommandRunnerTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.BakeryIntegration.CommandRunner

  import ExUnit.CaptureLog
  import ZhrDevs.Fixtures, only: [long_running_command: 0]

  @moduletag :capture_log

  describe "exit status message received from port" do
    test "it sends :execution_stopped error to the callback" do
      {:ok, pid} = run_command(long_running_command())

      Process.monitor(pid)

      %{port: port} = :sys.get_state(pid)
      send(pid, {port, {:exit_status, 11}})

      assert_receive {:DOWN, _, _, _, {:shutdown, %{error: :execution_stopped, exit_status: 11}}},
                     200
    end
  end

  describe "data from port" do
    test "it saves the latest data received from port" do
      {:ok, pid} = run_command(long_running_command())

      %{port: port} = :sys.get_state(pid)
      send(pid, {port, {:data, "data from port\n"}})
      send(pid, {port, {:data, "\n\n\ndata from port 2"}})

      assert %{latest_output: "data from port 2"} = :sys.get_state(pid)
    end
  end

  describe "handling of :timeout message" do
    test "it output logs correctly and stops the process" do
      {output, log} =
        with_log([level: :error], fn ->
          CommandRunner.handle_info(:timeout, %{port: :port, latest_output: "latest output"})
        end)

      assert log =~ "No output from Port for 2 minutes. Terminating."

      assert {:stop, {:shutdown, %{error: :timeout_reached}}, _} = output
    end
  end

  describe "unhandled messages" do
    test "it output warning logs correctly and do not stops the process" do
      {output, log} =
        with_log([level: :warning], fn ->
          CommandRunner.handle_info(:nonexisted, %{port: :port, latest_output: "latest output"})
        end)

      assert log =~ "Unhandled message"

      assert {:noreply, _} = output
    end
  end

  defp run_command(opts) do
    start_supervised({CommandRunner, opts})
  end
end
