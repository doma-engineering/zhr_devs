defmodule ZhrDevs.BakeryIntegration.QueueTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.BakeryIntegration.Queue

  alias Uptight.Text, as: T

  import ExUnit.CaptureLog

  @moduletag :capture_log

  describe "State" do
    test "it provides sane defaults" do
      state = %Queue.State{}

      assert state.queue == :queue.new()
      assert state.running == []
      assert state.delayed_check_ref == nil
    end
  end

  describe "RunningCheck" do
    setup do
      attributes = %{
        check_uuid: T.new!("check_uuid"),
        restart_opts: [],
        task_technology: T.new!("task_technology")
      }

      %{attributes: attributes}
    end

    test "it require to provide :check_uuid, :restart_opts, :task_technology", %{
      attributes: attributes
    } do
      for key <- Map.keys(attributes) do
        invalid_opts = Map.delete(attributes, key)

        assert_raise ArgumentError, fn ->
          struct!(Queue.RunningCheck, invalid_opts)
        end
      end
    end

    test "it allows to build RunningCheck struct with required attributes", %{
      attributes: attributes
    } do
      assert %Queue.RunningCheck{retries: 0, pid: nil, ref: nil} =
               struct!(Queue.RunningCheck, attributes)
    end
  end

  describe "enqueue_check/1" do
    setup :start_clean_queue_process

    test "with empty queue - add check to the queue", ctx do
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid")], ctx.name)
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid_2")], ctx.name)

      %Queue.State{queue: queue, delayed_check_ref: ref, running: []} = :sys.get_state(ctx.pid)

      assert queue |> :queue.to_list() |> Enum.count() === 2
      assert is_reference(ref)
    end
  end

  describe "prioritize_check/1" do
    setup :start_clean_queue_process

    test "inserts 'proiritized' check at the beginning of the queue", ctx do
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid")], ctx.name)
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid_2")], ctx.name)
      assert :ok = Queue.prioritize_check([check_uuid: T.new!("check_uuid_3")], ctx.name)

      %Queue.State{queue: queue, running: []} = :sys.get_state(ctx.pid)

      assert queue |> :queue.to_list() |> Enum.count() === 3

      check_3_id = T.new!("check_uuid_3")

      assert {{:value, [check_uuid: ^check_3_id]}, _} = :queue.out(queue)
    end
  end

  describe "dequeue_check/1" do
    setup :start_clean_queue_process

    test "removes check from the queue", ctx do
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid")], ctx.name)
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid_2")], ctx.name)
      assert :ok = Queue.enqueue_check([check_uuid: T.new!("check_uuid_3")], ctx.name)

      assert :ok = Queue.dequeue_check(T.new!("check_uuid_2"), ctx.name)

      %Queue.State{queue: queue, running: []} = :sys.get_state(ctx.pid)

      assert queue |> :queue.to_list() |> Enum.map(fn kw -> T.un(kw[:check_uuid]) end) === [
               "check_uuid",
               "check_uuid_3"
             ]
    end
  end

  describe "handle_info :run_next_check" do
    test "with empty queue - logs info" do
      assert capture_log([level: :info], fn ->
               assert {:noreply, _} = Queue.handle_info(:run_next_check, %Queue.State{})
             end) =~ "No checks to run."
    end

    test "with already running check in state - logs message and does nothing" do
      state = %Queue.State{
        queue: :queue.from_list(check_uuid: T.new!("check_uuid")),
        running: [
          %Queue.RunningCheck{
            check_uuid: T.new!("check_uuid"),
            restart_opts: [],
            task_technology: "task_technology"
          }
        ]
      }

      assert capture_log([level: :info], fn ->
               assert {:noreply, _} = Queue.handle_info(:run_next_check, state)
             end) =~ "Already running a check"
    end

    test "with non empty queue - starts the check" do
      check =
        Keyword.merge(mock_cmd_opts(),
          check_uuid: T.new!("check_uuid"),
          task: "mock_task",
          logger_metadata: [backend: :mock, path: "/tmp/mock.log"]
        )

      queue = :queue.from_list([check])

      {pid, _} = start_queue!(queue: queue)

      send(pid, :run_next_check)

      assert %Queue.State{running: [running_check]} = :sys.get_state(pid)

      assert running_check.check_uuid === T.new!("check_uuid")
      assert running_check.retries === 0
    end
  end

  describe ":DOWN messages handling" do
    setup do
      check =
        Keyword.merge(mock_cmd_opts(),
          check_uuid: T.new!("check_uuid"),
          task: "mock_task",
          logger_metadata: [backend: :mock, path: "/tmp/mock.log"]
        )

      queue = :queue.from_list([check])

      %{queue: queue}
    end

    @tag :flaky
    test "with :normal reason - runs on_success/1 callback provided by the Command module", %{
      queue: queue
    } do
      assert capture_log(fn ->
               {pid, _} = start_queue!(queue: queue)

               send(pid, :run_next_check)
               :erlang.trace(pid, true, [:receive])

               assert %Queue.State{running: [%Queue.RunningCheck{ref: check_ref}]} =
                        :sys.get_state(pid)

               assert_receive {:trace, ^pid, :receive, {:DOWN, ^check_ref, _, _, _}}, 1_000

               assert %Queue.State{running: []} = :sys.get_state(pid)
             end) =~ "MockCommand.on_success/1 called"
    end
  end

  defp mock_cmd_opts do
    ZhrDevs.Support.MockCommand.build([]) |> Uptight.Result.from_ok()
  end

  defp start_clean_queue_process(ctx) do
    name = Commanded.UUID.uuid4() |> String.to_atom()
    {pid, _} = start_queue!(name: name)

    Map.merge(ctx, %{name: name, pid: pid})
  end

  defp start_queue!(opts) do
    name = Keyword.get(opts, :name, Commanded.UUID.uuid4() |> String.to_atom())
    queue = Keyword.get(opts, :queue, :queue.new())
    running = Keyword.get(opts, :running, [])

    pid = start_supervised!({Queue, [name: name, queue: queue, running: running]})

    {pid, name}
  end
end
