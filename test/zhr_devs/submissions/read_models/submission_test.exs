defmodule ZhrDevs.Submissions.ReadModels.SubmissionTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.ReadModels.Submission

  alias ZhrDevs.Submissions

  import ZhrDevs.Fixtures

  describe "increment_attemps/2" do
    setup do
      successful_auth = generate_successful_auth(:github)

      trigger_event = %SolutionSubmitted{
        hashed_identity: successful_auth.hashed_identity,
        technology: "elixir",
        uuid: Commanded.UUID.uuid4(),
        task_uuid: Commanded.UUID.uuid4(),
        solution_path: "test/support/testfile.txt"
      }

      %{event: trigger_event}
    end

    test "with spawned identity - allows to increment without constraints", %{event: event} do
      start_supervised!({Submission, event})

      assert Submissions.increment_attempts(event.hashed_identity, "elixir") == :ok

      assert Submissions.increment_attempts(event.hashed_identity, "elixir") ==
               {:error, :max_attempts_reached}

      assert %{technology: :elixir, counter: 2} =
               event.hashed_identity
               |> Submissions.attempts()
               |> Enum.find(&(&1.technology == :elixir))
    end

    test "with spawned identity without any submissions yet - returns default", %{event: event} do
      assert event.hashed_identity |> Submissions.attempts() |> Enum.all?(&(&1.counter == 0))
    end
  end

  describe "start_link/1" do
    setup do
      trigger_event = %SolutionSubmitted{
        hashed_identity: generate_hashed_identity(),
        technology: "elixir",
        uuid: Commanded.UUID.uuid4(),
        task_uuid: Commanded.UUID.uuid4(),
        solution_path: "test/support/testfile.txt"
      }

      %{event: trigger_event}
    end

    test "doesn't allow to spawn more than one process per hashed_identity", %{event: event} do
      pid = start_supervised!({Submission, event})

      assert {:error, {:already_started, ^pid}} = Submission.start_link(event)
    end
  end
end
