defmodule ZhrDevs.Submissions.Commands.DownloadTaskTest do
  use ExUnit.Case, async: true

  import Commanded.Assertions.EventAssertions

  import ZhrDevs.Fixtures

  import Hammox

  alias ZhrDevs.App

  alias ZhrDevs.Submissions.Commands.DownloadTask
  alias ZhrDevs.Submissions.Commands.SubmitSolution

  alias ZhrDevs.Submissions.Events.SolutionSubmitted
  alias ZhrDevs.Submissions.Events.TaskDownloaded
  alias ZhrDevs.Submissions.Events.TestCasesDownloaded

  alias ZhrDevs.Submissions.ReadModels.TaskDownloads

  @task_uuid Commanded.UUID.uuid4() |> Uptight.Base.mk_url!()

  describe "DownloadTask command" do
    setup :verify_on_exit!

    setup do
      %{hid: generate_hashed_identity()}
    end

    test "with submission attempts count of 0 emit TestTaskDownloaded event", %{
      hid: hashed_identity
    } do
      :ok =
        DownloadTask.dispatch(
          task_uuid: @task_uuid.encoded,
          hashed_identity: hashed_identity.encoded,
          technology: "elixir"
        )

      assert_receive_event(
        App,
        TaskDownloaded,
        fn event -> event.hashed_identity === hashed_identity end
      )
    end

    test "with already submitted solution emit TestCasesDownloaded event", %{hid: hashed_identity} do
      expect(ZhrDevs.MockDocker, :zip_test, fn _solution_path -> true end)

      :ok =
        SubmitSolution.dispatch(
          hashed_identity: hashed_identity.encoded,
          task_uuid: @task_uuid.encoded,
          technology: "elixir",
          solution_path: "test/support/testfile.txt"
        )

      wait_for_event(App, SolutionSubmitted, fn event ->
        event.task_uuid.encoded === @task_uuid.encoded
      end)

      :ok =
        DownloadTask.dispatch(
          task_uuid: @task_uuid.encoded,
          hashed_identity: hashed_identity.encoded,
          technology: "elixir"
        )

      assert_receive_event(
        App,
        TestCasesDownloaded,
        fn event -> event.hashed_identity === hashed_identity end
      )
    end

    @tag :skip
    test "download of task increments global tasks read model", %{hid: hashed_identity} do
      independent_task_uuid = Commanded.UUID.uuid4()

      :ok =
        DownloadTask.dispatch(
          task_uuid: independent_task_uuid,
          hashed_identity: hashed_identity.encoded,
          technology: "elixir"
        )

      wait_for_event(App, TaskDownloaded, fn event ->
        event.hashed_identity === hashed_identity
      end)

      # Testing of global shared resources aren't easy

      :timer.sleep(50)

      downloads = TaskDownloads.get_downloads()

      assert %{task: 1, test_cases: 0} == Map.fetch!(downloads, independent_task_uuid)
    end
  end
end
