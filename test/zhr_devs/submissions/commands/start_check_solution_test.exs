defmodule ZhrDevs.Submissions.Commands.StartCheckSolutionTest do
  use ExUnit.Case, async: true

  import Commanded.Assertions.EventAssertions

  alias Commanded.Aggregates.Aggregate

  alias ZhrDevs.App
  alias ZhrDevs.Submissions.Aggregates.Check
  alias ZhrDevs.Submissions.Commands.StartCheckSolution
  alias ZhrDevs.Submissions.Events.SolutionCheckStarted

  alias Uptight.Text, as: T

  describe "StartCheckSolution command" do
    test "command generates a valid event" do
      solution_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()
      task_id = T.new!("onthemap-elixir-algae-witchcraft-uptight")
      solution_path = "doesn't matter"

      assert :ok =
               App.dispatch(%StartCheckSolution{
                 solution_uuid: solution_uuid,
                 task_id: task_id,
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

      command = %StartCheckSolution{
        solution_uuid: solution_uuid,
        task_id: "onthemap-elixir-algae-witchcraft-uptight",
        solution_path: "doesn't matter"
      }

      assert :ok = App.dispatch(command)

      assert {:error, :check_is_already_started} = App.dispatch(command)
    end

    test "Check aggregate state is predictable even after issuing the command more then once" do
      solution_uuid = Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()

      command = %StartCheckSolution{
        solution_uuid: solution_uuid,
        task_id: "onthemap-elixir-algae-witchcraft-uptight",
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
