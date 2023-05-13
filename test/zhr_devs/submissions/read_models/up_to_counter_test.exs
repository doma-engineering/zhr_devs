defmodule ZhrDevs.Submissions.ReadModels.UpToCounterTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.ReadModels.UpToCounter

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
      start_supervised!({UpToCounter, event})

      assert UpToCounter.increment_attempts(event.hashed_identity, "elixir") == :ok

      assert UpToCounter.increment_attempts(event.hashed_identity, "elixir") ==
               {:error, :max_attempts_reached}

      assert %{elixir: 2} = UpToCounter.attempts(event.hashed_identity)
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
      pid = start_supervised!({UpToCounter, event})

      assert {:error, {:already_started, ^pid}} = UpToCounter.start_link(event)
    end
  end
end
