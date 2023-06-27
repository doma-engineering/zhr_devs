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

  @task_id ZhrDevs.Submissions.Task.from_uri(
             "%7B%22task_name%22%3A%22onTheMap%22%2C%22programming_language%22%3A%22elixir%22%2C%22integrations%22%3A%5B%5D%2C%22library_stack%22%3A%5B%22ecto%22%2C%22postgresql%22%5D%7D"
           )

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
          task_id: @task_id,
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
          task_id: @task_id,
          technology: "elixir",
          solution_path: "test/support/testfile.txt"
        )

      wait_for_event(App, SolutionSubmitted, fn event ->
        event.task_id === @task_id |> ZhrDevs.Submissions.Task.to_uri()
      end)

      :ok =
        DownloadTask.dispatch(
          task_id: @task_id,
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
      independent_task_id = Commanded.UUID.uuid4()

      :ok =
        DownloadTask.dispatch(
          task_id: independent_task_id,
          hashed_identity: hashed_identity.encoded,
          technology: "elixir"
        )

      wait_for_event(App, TaskDownloaded, fn event ->
        event.hashed_identity === hashed_identity
      end)

      # Testing of global shared resources aren't easy

      :timer.sleep(50)

      downloads = TaskDownloads.get_downloads()

      assert %{task: 1, test_cases: 0} == Map.fetch!(downloads, independent_task_id)
    end
  end
end
