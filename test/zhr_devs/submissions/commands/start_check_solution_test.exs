defmodule ZhrDevs.Submissions.Commands.StartSolutionCheckTest do
  use ExUnit.Case, async: false

  import Commanded.Assertions.EventAssertions

  alias Commanded.Aggregates.Aggregate

  alias ZhrDevs.App
  alias ZhrDevs.Submissions.Aggregates.Check
  alias ZhrDevs.Submissions.Commands.StartSolutionCheck
  alias ZhrDevs.Submissions.Events.SolutionCheckStarted

  describe "StartSolutionCheck command" do
    test "command generates a valid event" do
      solution_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()
      task_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()
      solution_path = "doesn't matter"

      assert :ok =
               App.dispatch(%StartSolutionCheck{
                 solution_uuid: solution_uuid,
                 task_uuid: task_uuid,
                 solution_path: solution_path
               })

      assert_receive_event(
        App,
        SolutionCheckStarted,
        fn event -> event.solution_uuid === solution_uuid end
      )
    end

    test "do not allow to dispatch command twice with the same solution_uuid" do
      solution_uuid = Commanded.UUID.uuid4()

      command = %StartSolutionCheck{
        solution_uuid: solution_uuid,
        task_uuid: "doesn't matter",
        solution_path: "doesn't matter"
      }

      assert :ok = App.dispatch(command)

      assert {:error, :check_is_already_started} = App.dispatch(command)
    end

    test "Check aggregate state is predictable even after issuing the command more then once" do
      # expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _ -> @task end)

      solution_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()

      command = %StartSolutionCheck{
        solution_uuid: solution_uuid,
        task_uuid: "doesn't matter",
        solution_path: "doesn't matter"
      }

      for _ <- 1..3, do: App.dispatch(command)

      assert %Check{
               solution_uuid: ^solution_uuid,
               status: :started
             } = Aggregate.aggregate_state(App, Check, solution_uuid.encoded)
    end
  end
end
