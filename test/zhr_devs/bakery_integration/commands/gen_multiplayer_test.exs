defmodule ZhrDevs.BakeryIntegration.Commands.GenMultiplayerTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias ZhrDevs.BakeryIntegration.Commands.GenMultiplayer

  alias Uptight.Text, as: T

  use Witchcraft.Comonad

  import ExUnit.CaptureLog

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
        submissions_folder: T.new!("submissions_folder"),
        server_code: T.new!("server_code"),
        task: :on_the_map_goo
      ]

      assert [
               {:cmd, %Ubuntu.Command{}},
               {:output_json_path, output_json_path}
             ] = opts |> GenMultiplayer.build() |> Uptight.Result.from_ok()

      assert output_json_path =~ "tournament/on_the_map_goo/output.json"
    end

    test "generates valid Ubuntu command" do
      opts = [
        submissions_folder: T.new!("submissions_folder"),
        server_code: T.new!("server_code"),
        task: :on_the_map_goo
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
        submissions_folder: T.new!("submissions_folder"),
        task: T.new!("task"),
        server_code: T.new!("server_code")
      ]

      for key <- Keyword.keys(opts) do
        invalid_opts = Keyword.delete(opts, key)

        assert %{exception: %KeyError{key: ^key}} =
                 invalid_opts |> GenMultiplayer.build() |> extract()
      end
    end
  end

  describe "on_success/1" do
    test "with existing output file - returns :ok" do
      output_json_path = GenMultiplayer.output_json_path(:task)
      :ok = File.mkdir_p!([Path.dirname(output_json_path)])
      File.write!(output_json_path, "{}")

      on_exit(:cleanup, fn -> File.rm!(output_json_path) end)

      assert capture_log([level: :info], fn ->
               assert :ok = GenMultiplayer.on_success(output_json_path)
             end) =~ "Successfully generated tournament output"
    end

    test "with non existing output.json file - returns error tuple" do
      output_json_path = GenMultiplayer.output_json_path(:non_existing)

      assert {:error, _} = GenMultiplayer.on_success(output_json_path)
    end

    test "with non existing output.json file - logs an error" do
      output_json_path = GenMultiplayer.output_json_path(:non_existing)

      assert capture_log([level: :error], fn ->
               assert {:error, _} = GenMultiplayer.on_success(output_json_path)
             end) =~ "Failed to generate multiplayer"
    end
  end

  describe "on_failure/1" do
    test "log proper message when success_criteria aren't met" do
      assert capture_log([level: :error], fn ->
               assert :ok =
                        GenMultiplayer.on_failure(%{
                          error: :on_success_not_met,
                          context: "whatever"
                        })
             end) =~
               "Multiplayer generation process is completed successfully, but output.json doesn't get generated.\nLatest output: whatever"
    end

    test "log proper message when execution is stopped" do
      assert capture_log([level: :error], fn ->
               assert :ok =
                        GenMultiplayer.on_failure(%{
                          error: :execution_stopped,
                          context: "whatever",
                          exit_code: 1
                        })
             end) =~
               "Multiplayer generation process is stopped with exit code: 1.\nLatest output: whatever"
    end
  end
end
