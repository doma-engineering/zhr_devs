defmodule ZhrDevs.Submissions.ReadModels.SubmissionsTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.ReadModels.Submissions

  import ZhrDevs.Fixtures

  describe "increment_attemps/2" do
    setup do
      trigger_event = %SolutionSubmitted{
        hashed_identity: generate_hashed_identity(),
        technology: "elixir"
      }

      %{event: trigger_event}
    end

    test "with spawned identity - allows to increment without constraints", %{event: event} do
      start_supervised!({Submissions, event})

      assert Submissions.increment_attempts(event.hashed_identity, "elixir") == :ok
      assert Submissions.increment_attempts(event.hashed_identity, "elixir") == :ok

      assert Submissions.attempts(event.hashed_identity) == %{"elixir" => 3}
    end
  end

  describe "start_link/1" do
    setup do
      trigger_event = %SolutionSubmitted{
        hashed_identity: generate_hashed_identity(),
        technology: "elixir"
      }

      %{event: trigger_event}
    end

    test "doesn't allow to spawn more than one process per hashed_identity", %{event: event} do
      pid = start_supervised!({Submissions, event})

      assert {:error, {:already_started, ^pid}} = Submissions.start_link(event)
    end
  end
end
