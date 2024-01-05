defmodule ZhrDevs.BakeryIntegration.Commands.GenMultiplayerTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias ZhrDevs.BakeryIntegration.Commands.GenMultiplayer

  alias Uptight.Text, as: T

  use Witchcraft.Comonad

  import ExUnit.CaptureLog
  import Commanded.Assertions.EventAssertions

  describe "output_json_path/1" do
    test "with atom task - returns expected path" do
      assert GenMultiplayer.output_json_path(:task) =~ "tournament/task/output.json"
    end

    test "with string task - returns expected path" do
      assert GenMultiplayer.output_json_path("on_the_map_goo") =~
               "tournament/on_the_map_goo/output.json"
    end
  end

  describe "build/1" do
    test "with valid opts - returns expected result" do
      opts = [
        solution_path: T.new!("/tmp/submissions_folder"),
        server_code: T.new!("server_code"),
        task: :on_the_map_goo,
        server_code: T.new!("server_code"),
        task_uuid: T.new!("task-uuid"),
        check_uuid: T.new!("solution-uuid"),
        type: :automatic
      ]

      assert [
               {:cmd, %Ubuntu.Command{}},
               {:on_success, {GenMultiplayer, :on_success, _}},
               {:on_failure, {GenMultiplayer, :on_failure, _}}
             ] = opts |> GenMultiplayer.build() |> Uptight.Result.from_ok()
    end

    test "with manual type - returns expected result" do
      opts = [
        submissions_folder: T.new!("/tmp/submissions_folder"),
        server_code: T.new!("server_code"),
        task: :on_the_map_goo,
        server_code: T.new!("server_code"),
        task_uuid: T.new!("task-uuid"),
        check_uuid: T.new!("solution-uuid"),
        type: :manual,
        triggered_by: Uptight.Base.mk_url!("triggered_by")
      ]

      assert [
               {:cmd, %Ubuntu.Command{}},
               {:on_success, {GenMultiplayer, :manual_on_success, _}},
               {:on_failure, {GenMultiplayer, :manual_on_failure, _}}
             ] = opts |> GenMultiplayer.build() |> Uptight.Result.from_ok()
    end

    test "generates valid Ubuntu command" do
      opts = [
        solution_path: T.new!("/tmp/submissions_folder"),
        server_code: T.new!("server_code"),
        task: :on_the_map_goo,
        task_uuid: T.new!("task-uuid"),
        check_uuid: T.new!("solution-uuid"),
        type: :automatic
      ]

      cmd = opts |> GenMultiplayer.build() |> extract() |> Keyword.fetch!(:cmd)

      assert [
               %Uptight.Text{text: "."},
               %Uptight.Text{text: "priv"},
               %Uptight.Text{text: "bakery"},
               %Uptight.Text{text: "gen_multiplayer"}
             ] = cmd.path.path
    end

    test "with missing option raises KeyError" do
      opts = [
        solution_path: T.new!("/tmp/submissions_folder"),
        task: "on_the_map_goo",
        server_code: T.new!("server_code"),
        task_uuid: T.new!("task-uuid"),
        check_uuid: T.new!("solution-uuid"),
        type: :automatic
      ]

      for key <- Keyword.keys(opts) do
        invalid_opts = Keyword.delete(opts, key)

        assert %{exception: %KeyError{key: ^key}} =
                 invalid_opts |> GenMultiplayer.build() |> extract()
      end
    end
  end

  describe "on_success/1" do
    defp init_aggregate_state(task_uuid, solution_uuid) do
      :ok =
        ZhrDevs.App.dispatch(%ZhrDevs.Submissions.Commands.StartSolutionCheck{
          task_uuid: task_uuid,
          solution_uuid: solution_uuid,
          solution_path: "/some/path"
        })

      wait_for_event(
        ZhrDevs.App,
        ZhrDevs.Submissions.Events.SolutionCheckStarted,
        fn event ->
          event.solution_uuid == solution_uuid
        end
      )
    end

    setup do
      task_uuid = Commanded.UUID.uuid4() |> T.new!()
      solution_uuid = Commanded.UUID.uuid4() |> T.new!()

      init_aggregate_state(task_uuid, solution_uuid)

      %{opts: [task_uuid: task_uuid, solution_uuid: solution_uuid]}
    end

    @tag fs: true
    test "with existing output file - returns :ok", %{opts: default_opts} do
      output_json_path = GenMultiplayer.output_json_path(:task)
      opts = Keyword.put(default_opts, :output_json_path, output_json_path)

      :ok = File.mkdir_p!([Path.dirname(output_json_path)])
      File.write!(output_json_path, Jason.encode!(%{gen_multiplayer_score: []}))

      on_exit(:cleanup, fn ->
        File.rm_rf!(
          Path.join([Application.fetch_env!(:zhr_devs, :output_json_backup_folder), "task_uuid"])
        )
      end)

      assert capture_log([level: :info], fn ->
               assert :ok = GenMultiplayer.on_success(opts)
             end) =~ "Successfully generated tournament output"
    end

    test "with non existing output.json file - returns error tuple", %{opts: default_opts} do
      output_json_path = GenMultiplayer.output_json_path(:non_existing)
      opts = Keyword.put(default_opts, :output_json_path, output_json_path)

      assert {:error, %{error: :on_success_not_met}} = GenMultiplayer.on_success(opts)
    end

    test "with non existing output.json file - logs an error", %{opts: default_opts} do
      output_json_path = GenMultiplayer.output_json_path(:non_existing)
      opts = Keyword.put(default_opts, :output_json_path, output_json_path)

      assert capture_log([level: :error], fn ->
               assert {:error,
                       %{error: :on_success_not_met, context: "output.json doesn't get generated"}} =
                        GenMultiplayer.on_success(opts)
             end) =~ "Port terminated with :normal"
    end
  end

  describe "manual_on_success/1" do
    test "with missing opts - raise KeyError" do
      opts = [
        output_json_path: T.new!("output_json_path"),
        task_uuid: T.new!("task_uuid"),
        uuid: T.new!("uuid"),
        triggered_by: T.new!("triggered_by")
      ]

      for key <- Keyword.keys(opts) do
        invalid_opts = Keyword.delete(opts, key)

        assert_raise KeyError, fn ->
          GenMultiplayer.manual_on_success(invalid_opts)
        end
      end
    end

    test "with non existing output.json file - returns an error" do
      output_json_path = GenMultiplayer.output_json_path(:non_existing)

      opts = [
        output_json_path: output_json_path,
        task_uuid: T.new!("task_uuid"),
        uuid: T.new!("uuid"),
        triggered_by: Uptight.Base.mk_url!("triggered_by")
      ]

      assert capture_log([level: :error], fn ->
               assert {:error, _} = GenMultiplayer.manual_on_success(opts)
             end) =~ "output.json doesn't get generated"
    end
  end

  describe "on_failure/1" do
    test "log proper message when success_criteria aren't met" do
      assert capture_log([level: :error], fn ->
               assert :ok =
                        GenMultiplayer.on_failure(
                          %{
                            error: :on_success_not_met,
                            context: "whatever"
                          },
                          task_uuid: T.new!("task_uuid"),
                          solution_uuid: T.new!("solution_uuid")
                        )
             end) =~
               "Port terminated with :normal reason, but output.json doesn't get generated.\nLatest output: whatever"
    end

    test "log proper message when execution is stopped" do
      assert capture_log([level: :error], fn ->
               assert :ok =
                        GenMultiplayer.on_failure(
                          %{
                            error: :execution_stopped,
                            context: "whatever",
                            exit_code: 1
                          },
                          task_uuid: T.new!("task_uuid"),
                          solution_uuid: T.new!("solution_uuid")
                        )
             end) =~
               "Multiplayer generation process is stopped with exit code: 1.\nLatest output: whatever"
    end

    test "dispatch FailSolutionCheck command" do
      solution_uuid = Commanded.UUID.uuid4() |> T.new!()

      assert :ok =
               GenMultiplayer.on_failure(
                 %{error: :on_success_not_met, context: "whatever"},
                 task_uuid: T.new!("task_uuid"),
                 solution_uuid: solution_uuid
               )

      wait_for_event(
        ZhrDevs.App,
        ZhrDevs.Submissions.Events.SolutionCheckFailed,
        fn event ->
          event.solution_uuid == solution_uuid
        end
      )
    end
  end

  describe "manual_on_failure/2" do
    test "emits a ManualCheckFailed event" do
      callback_opts = [
        task_uuid: T.new!("task_uuid"),
        uuid: T.new!("uuid"),
        triggered_by: Uptight.Base.mk_url!(DomaOAuth.hash("triggered_by"))
      ]

      :ok = GenMultiplayer.manual_on_failure(%{error: :whatever}, callback_opts)

      wait_for_event(
        ZhrDevs.App,
        ZhrDevs.Submissions.Events.ManualCheckFailed,
        fn event ->
          event.uuid == callback_opts[:uuid]
        end
      )
    end
  end

  describe "persist_output/4" do
    @tag fs: true
    test "with :manual option - persists output to 'manual' folder" do
      output_json_path = GenMultiplayer.output_json_path(:task)

      File.write!(output_json_path, Jason.encode!(%{gen_multiplayer_score: []}))

      assert File.exists?(output_json_path)

      task_uuid = Commanded.UUID.uuid4() |> T.new!()
      uuid = Commanded.UUID.uuid4() |> T.new!()

      assert :ok = GenMultiplayer.persist_output(output_json_path, task_uuid, uuid, :manual)

      output_backup_folder = Application.fetch_env!(:zhr_devs, :output_json_backup_folder)

      assert File.exists?(
               Path.join([output_backup_folder, T.un(task_uuid), "manual", "#{T.un(uuid)}.json"])
             )

      assert :ok = GenMultiplayer.persist_output(output_json_path, task_uuid, uuid, :auto)

      assert File.exists?(
               Path.join([output_backup_folder, T.un(task_uuid), "#{T.un(uuid)}.json"])
             )

      on_exit(:cleanup, fn ->
        File.rm_rf!(Path.join([output_backup_folder, "task_uuid"]))
      end)
    end
  end
end
