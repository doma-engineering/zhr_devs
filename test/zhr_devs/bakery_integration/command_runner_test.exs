defmodule ZhrDevs.BakeryIntegration.CommandRunnerTest do
  use ExUnit.Case, async: false
  use Witchcraft.Functor

  alias ZhrDevs.BakeryIntegration.CommandRunner

  alias Uptight.Text, as: T

  @moduletag :capture_log

  @long_running_script_path [".", "test", "support", "long_running.sh"]
                            |> map(&T.new!/1)
                            |> Ubuntu.Path.new!()

  describe ":DOWN message handling" do
    test "trigger success callback only on successful run" do
      {:ok, pid} = run_command(cmd: long_running_command())

      assert_receive :success, 200

      refute_receive {:error, _}, 200

      refute Process.alive?(pid)
    end

    test "trigger success callback AND error callback if on_success returns error" do
      on_success = fn ->
        {:error, "on_success error"}
      end

      {:ok, pid} = run_command(cmd: long_running_command(), on_success: on_success)

      assert_receive {:error, %{error: :on_success_not_met, context: nil}}, 100

      refute Process.alive?(pid)
    end
  end

  describe "exit status message received from port" do
    test "it sends :execution_stopped error to the callback" do
      {:ok, pid} = run_command(cmd: long_running_command())

      %{port: port} = :sys.get_state(pid)
      send(pid, {port, {:exit_status, 11}})

      assert_receive {:error, %{error: :execution_stopped, context: nil, exit_status: 11}}, 200
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
  end

  defp run_command(opts) do
    me = self()

    on_success =
      Keyword.get(opts, :on_success, fn ->
        send(me, :success)

        :ok
      end)

    on_failure =
      Keyword.get(opts, :on_failure, fn error ->
        send(me, {:error, error})

        :ok
      end)

    cmd = Keyword.fetch!(opts, :cmd)

    opts = [
      cmd: cmd,
      on_success: on_success,
      on_failure: on_failure
    ]

    start_supervised({CommandRunner, opts})
  end

  defp long_running_command do
    Ubuntu.Command.new!(@long_running_script_path, [])
  end
end
