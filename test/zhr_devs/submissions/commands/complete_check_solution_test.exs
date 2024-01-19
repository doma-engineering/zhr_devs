defmodule ZhrDevs.Submissions.Commands.CompleteSolutionCheckTest do
  use ExUnit.Case, async: false

  @moduletag :capture_log

  import Commanded.Assertions.EventAssertions

  alias Commanded.Aggregates.Aggregate

  alias ZhrDevs.App
  alias ZhrDevs.Submissions.Aggregates.Check
  alias ZhrDevs.Submissions.Commands.CompleteSolutionCheck
  alias ZhrDevs.Submissions.Commands.StartSolutionCheck
  alias ZhrDevs.Submissions.Events.SolutionCheckStarted

  @task %ZhrDevs.Task{
    uuid: Commanded.UUID.uuid4() |> Uptight.Text.new!(),
    name: :on_the_map,
    technology: :goo
  }

  import Mox

  setup [:set_mox_from_context]

  describe "StartSolutionCheck command" do
    test "do not allow to dispatch command twice with the same solution_uuid" do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _uuid -> @task end)
      allow(ZhrDevs.MockAvailableTasks, self(), ZhrDevs.Submissions.EventHandler)

      solution_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()

      :ok = simulate_check_started(solution_uuid)

      command = %CompleteSolutionCheck{
        solution_uuid: solution_uuid,
        task_uuid: "doesn't matter",
        score: %{
          "points" => 1
        }
      }

      assert :ok = App.dispatch(command)

      assert {:error, :illegal_attempt} = App.dispatch(command)
    end

    test "Check aggregate state is predictable even after issuing the command more then once" do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _uuid -> @task end)
      allow(ZhrDevs.MockAvailableTasks, self(), ZhrDevs.Submissions.EventHandler)

      solution_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()

      :ok = simulate_check_started(solution_uuid)

      command = %CompleteSolutionCheck{
        solution_uuid: solution_uuid,
        task_uuid: "doesn't matter",
        score: %{
          "points" => 100
        }
      }

      for _ <- 1..3, do: App.dispatch(command)

      assert %Check{
               solution_uuid: ^solution_uuid,
               status: :completed
             } = Aggregate.aggregate_state(App, Check, solution_uuid.encoded)
    end

    def simulate_check_started(solution_uuid) do
      command = %StartSolutionCheck{
        solution_uuid: solution_uuid,
        task_uuid: "doesn't matter",
        solution_path: "doesn't matter"
      }

      App.dispatch(command)

      wait_for_event(App, SolutionCheckStarted, fn event ->
        event.solution_uuid == solution_uuid
      end)

      assert %Check{
               solution_uuid: ^solution_uuid,
               status: :started
             } = Aggregate.aggregate_state(App, Check, solution_uuid.encoded)

      :ok
    end
  end
end
