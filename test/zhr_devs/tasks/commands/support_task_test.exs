defmodule ZhrDevs.Tasks.Commands.SupportTaskTest do
  use ExUnit.Case, async: false

  import Mox

  import Commanded.Assertions.EventAssertions

  alias Commanded.Aggregates.Aggregate

  alias ZhrDevs.App
  alias ZhrDevs.Tasks.Aggregates
  alias ZhrDevs.Tasks.Commands.SupportTask
  alias ZhrDevs.Tasks.Events.TaskSupported

  setup [:set_mox_from_context]

  setup _ do
    expect(ZhrDevs.MockAvailableTasks, :add_task, fn _ ->
      :ok
    end)

    :ok
  end

  test "do not allow to dispatch command twice with same name and technology" do
    opts = [name: "on_the_map", technology: "goo"]

    assert :ok = SupportTask.dispatch(opts)

    wait_for_event(App, TaskSupported, fn
      %{technology: :goo} = event ->
        task_identity =
          ZhrDevs.Tasks.TaskIdentity.new(name: event.name, technology: event.technology)

        assert %Aggregates.Task{
                 name: :on_the_map,
                 technology: :goo,
                 uuid: event.task_uuid,
                 show: true
               } == Aggregate.aggregate_state(App, Aggregates.Task, to_string(task_identity))

      _ ->
        nil
    end)

    assert {:error, :already_supported} = SupportTask.dispatch(opts)
  end

  test "ignores uuid passed by user" do
    opts = [name: "on_the_map", technology: "rust", uuid: "some_uuid"]

    assert :ok = SupportTask.dispatch(opts)

    wait_for_event(App, TaskSupported, fn
      %{technology: :rust} = event ->
        event.task_uuid != "some_uuid"

      _ ->
        nil
    end)
  end
end
