defmodule ZhrDevs.Submissions.Commands.SolutionSubmittedTest do
  use ExUnit.Case, async: true

  import Commanded.Assertions.EventAssertions

  import ZhrDevs.Fixtures

  import ZhrDevs.Web.Presentation.Helper, only: [extract_error: 1]

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
      assert {:error, exception} = Commands.SubmitSolution.dispatch([])

      assert %KeyError{key: :hashed_identity} = extract_error(exception)
    end

    test "return error if invalid hashed_identity passed" do
      assert {:error, exception} = Commands.SubmitSolution.dispatch(hashed_identity: "invalid")

      assert %ArgumentError{message: "incorrect padding"} = extract_error(exception)
    end

    test "return an error when file can't be located (File.exists? is returning false)", %{
      valid_opts: valid_opts
    } do
      opts =
        identity_generator() |> valid_opts.() |> Keyword.put(:solution_path, "/nonesense/path")

      assert {:error, exception} = Commands.SubmitSolution.dispatch(opts)

      assert %ArgumentError{message: "Solution path is invalid: /nonesense/path"} =
               extract_error(exception)
    end

    test "return an error when technology we do not support passed", %{valid_opts: valid_opts} do
      opts = identity_generator() |> valid_opts.() |> Keyword.put(:technology, "javascript")

      assert {:error, exception} = Commands.SubmitSolution.dispatch(opts)

      assert %Uptight.AssertionError{message: message} = extract_error(exception)
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

    test "correlated with SolutionCheckStarted event", %{valid_opts: valid_opts} do
      identity = identity_generator()
      opts = valid_opts.(identity)
      uuid = Commanded.UUID.uuid4()

      opts = Keyword.put(opts, :uuid, uuid)

      assert :ok = Commands.SubmitSolution.dispatch(opts)

      encoded_uuid = Uptight.Base.mk_url!(uuid)

      assert_correlated(
        App,
        Events.SolutionSubmitted,
        fn solution_submitted -> solution_submitted.uuid == encoded_uuid end,
        Events.SolutionCheckStarted,
        fn check_started -> check_started.solution_uuid == encoded_uuid end
      )
    end

    defp submission_identity(opts) do
      opts
      |> Keyword.take([:hashed_identity, :technology])
      |> SubmissionIdentity.new()
      |> to_string()
    end
  end
end
