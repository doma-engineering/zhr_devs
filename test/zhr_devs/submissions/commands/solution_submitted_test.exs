defmodule ZhrDevs.Submissions.Commands.SolutionSubmittedTest do
  use ExUnit.Case, async: true

  import Commanded.Assertions.EventAssertions

  import ZhrDevs.Fixtures

  alias Commanded.Aggregates.Aggregate

  alias ZhrDevs.App

  alias ZhrDevs.Submissions.{Aggregates, Commands, Events}

  alias ZhrDevs.Submissions.SubmissionIdentity

  describe "SolutionSubmitted command" do
    setup do
      valid_opts = fn identity ->
        [
          hashed_identity: DomaOAuth.hash(identity),
          task_uuid: "Jaju6yAv1oZ23NcjJk-1JkOrxCemsH_K-9iRRw0sYRg=",
          technology: "elixir",
          solution_path: "test/support/testfile.txt"
        ]
      end

      %{valid_opts: valid_opts}
    end

    test "return error if invalid options passed" do
      assert {:error, %KeyError{key: :hashed_identity}} = Commands.SubmitSolution.dispatch([])
    end

    test "return error if invalid hashed_identity passed" do
      assert {:error, %ArgumentError{message: "incorrect padding"}} =
               Commands.SubmitSolution.dispatch(hashed_identity: "invalid")
    end

    test "return an error when file can't be located (File.exists? is returning false)", %{
      valid_opts: valid_opts
    } do
      opts =
        identity_generator() |> valid_opts.() |> Keyword.put(:solution_path, "/nonesense/path")

      assert {:error, %ArgumentError{message: "Solution path is invalid: /nonesense/path"}} =
               Commands.SubmitSolution.dispatch(opts)
    end

    test "return an error when technology we do not support passed", %{valid_opts: valid_opts} do
      opts = identity_generator() |> valid_opts.() |> Keyword.put(:technology, "javascript")

      assert {:error, %Uptight.AssertionError{message: message}} =
               Commands.SubmitSolution.dispatch(opts)

      assert message =~ "javascript is not supported"
    end

    test "with valid arguments emits an a valid event", %{valid_opts: valid_opts} do
      identity = identity_generator()
      opts = valid_opts.(identity)

      assert :ok = Commands.SubmitSolution.dispatch(opts)
      hashed_identity = opts[:hashed_identity]

      assert_receive_event(
        App,
        Events.SolutionSubmitted,
        fn event -> event.hashed_identity.encoded == hashed_identity end,
        fn event ->
          assert %{
                   solution_path: %Uptight.Text{text: "test/support/testfile.txt"},
                   task_uuid: %Uptight.Base.Urlsafe{},
                   uuid: %Uptight.Base.Urlsafe{},
                   technology: :elixir
                 } = event
        end
      )
    end

    test "with valid arguments aggregate state is predictable", %{valid_opts: valid_opts} do
      identity = identity_generator()
      opts = valid_opts.(identity)
      hashed_identity = opts[:hashed_identity]

      assert :ok = Commands.SubmitSolution.dispatch(opts)

      wait_for_event(App, Events.SolutionSubmitted, fn event ->
        event.hashed_identity.encoded == hashed_identity
      end)

      assert %Aggregates.Submission{
               attempts: 1,
               technology: :elixir,
               hashed_identity: %Uptight.Base.Urlsafe{encoded: ^hashed_identity}
             } = Aggregate.aggregate_state(App, Aggregates.Submission, submission_identity(opts))
    end

    test "we allow to submit solution only twice", %{valid_opts: valid_opts} do
      identity = identity_generator()
      opts = valid_opts.(identity)
      hashed_identity = opts[:hashed_identity]

      for _ <- 1..2 do
        assert :ok = Commands.SubmitSolution.dispatch(opts)

        wait_for_event(App, Events.SolutionSubmitted, fn event ->
          event.hashed_identity.encoded == hashed_identity
        end)
      end

      assert {:error, "Maximum number of attempts reached"} =
               Commands.SubmitSolution.dispatch(opts)

      assert %Aggregates.Submission{
               attempts: 2,
               technology: :elixir,
               hashed_identity: %Uptight.Base.Urlsafe{encoded: ^hashed_identity}
             } = Aggregate.aggregate_state(App, Aggregates.Submission, submission_identity(opts))
    end

    defp submission_identity(opts) do
      opts
      |> Keyword.take([:hashed_identity, :technology])
      |> SubmissionIdentity.new()
      |> to_string()
    end
  end
end
