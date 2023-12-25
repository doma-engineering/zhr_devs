defmodule ZhrDevs.BakeryIntegration.Commands.GenMultiplayer do
  @moduledoc """
  Generates an OTMG
  """

  use Witchcraft.Functor

  alias ZhrDevs.BakeryIntegration.Commands.Command

  @behaviour Command

  require Logger

  alias Uptight.Result
  alias Uptight.Text, as: T

  alias ZhrDevs.Submissions.Commands.CompleteCheckSolution
  alias ZhrDevs.Submissions.Commands.CompleteManualCheck

  @type options() :: [
          submission_folder: Uptight.Text.t(),
          server_code: Uptight.Text.t(),
          task: ZhrDevs.Task.t(),
          check_uuid: Uptight.Text.t(),
          task_uuid: Uptight.Text.t(),
          type: :automatic | :manual
        ]

  @gen_multiplayer [".", "priv", "bakery", "gen_multiplayer"]
                   |> map(&T.new!/1)
                   |> Ubuntu.Path.new!()

  @output_json_backup_folder Application.compile_env!(:zhr_devs, :output_json_backup_folder)

  def gen_multiplayer, do: @gen_multiplayer

  @impl Command
  def run(opts) do
    opts
    |> build()
    |> Result.from_ok()
    |> ZhrDevs.Submissions.start_automatic_check()
  end

  @impl Command
  def build(opts \\ []) do
    Result.new(fn ->
      case Keyword.fetch!(opts, :type) do
        :manual ->
          build_manual(opts)

        :automatic ->
          build_automatic(opts)
      end
    end)
  end

  def build_automatic(opts \\ []) do
    %T{} = submissions_folder = Keyword.fetch!(opts, :submissions_folder)
    %T{} = server_code = Keyword.fetch!(opts, :server_code)
    task = Keyword.fetch!(opts, :task)

    on_success_opts = [
      output_json_path: output_json_path(task),
      task_uuid: Keyword.fetch!(opts, :task_uuid),
      solution_uuid: Keyword.fetch!(opts, :check_uuid)
    ]

    [
      cmd: Ubuntu.Command.new(@gen_multiplayer, [submissions_folder, server_code]),
      on_success: fn -> __MODULE__.on_success(on_success_opts) end,
      on_failure: fn error -> __MODULE__.on_failure(error) end
    ]
  end

  def build_manual(opts \\ []) do
    %T{} = submissions_folder = Keyword.fetch!(opts, :submissions_folder)
    %T{} = server_code = Keyword.fetch!(opts, :server_code)
    task = Keyword.fetch!(opts, :task)

    on_success_opts = [
      output_json_path: output_json_path(task),
      task_uuid: Keyword.fetch!(opts, :task_uuid),
      uuid: Keyword.fetch!(opts, :check_uuid),
      submissions: Keyword.get(opts, :submissions, [])
    ]

    [
      cmd: Ubuntu.Command.new(@gen_multiplayer, [submissions_folder, server_code]),
      on_success: fn -> __MODULE__.manual_on_success(on_success_opts) end,
      on_failure: fn error -> __MODULE__.on_failure(error) end
    ]
  end

  @impl Command
  def on_success(opts) do
    output_file_path = Keyword.fetch!(opts, :output_json_path)
    task_uuid = Keyword.fetch!(opts, :task_uuid)
    solution_uuid = Keyword.fetch!(opts, :solution_uuid)

    if File.exists?(output_file_path) do
      Logger.info("Successfully generated tournament output: #{inspect(output_file_path)}")

      complete_check_solution = %CompleteCheckSolution{
        solution_uuid: solution_uuid,
        task_uuid: task_uuid,
        score: extract_score!(output_file_path)
      }

      :ok = persist_output(output_file_path, task_uuid, solution_uuid)

      # We now want to safely delete the original output.json (maybe with the whole tournament dir?)
      # Because it will mislead the whole `on_success` function another time it will be called
      :ok = File.rm!(output_file_path)

      ZhrDevs.App.dispatch(complete_check_solution)
    else
      Logger.error("Failed to generate multiplayer: #{inspect(output_file_path)}")

      {:error, "#{output_file_path} file doesn't exist"}
    end
  end

  @impl Command
  def on_failure(%{error: :on_success_not_met, context: context}) do
    Logger.error(
      "Multiplayer generation process is completed successfully, but output.json doesn't get generated.\nLatest output: #{context}"
    )

    :ok
  end

  def on_failure(%{error: :execution_stopped, context: context, exit_code: code}) do
    Logger.error(
      "Multiplayer generation process is stopped with exit code: #{code}.\nLatest output: #{context}"
    )

    :ok
  end

  def manual_on_success(opts) do
    output_file_path = Keyword.fetch!(opts, :output_json_path)
    task_uuid = Keyword.fetch!(opts, :task_uuid)
    submissions = Keyword.get(opts, :submissions, [])
    uuid = Keyword.fetch!(opts, :uuid)
    triggered_by = Keyword.fetch!(opts, :triggered_by)

    if File.exists?(output_file_path) do
      Logger.info(
        "Manually generated tournament terminated successfully: #{inspect(output_file_path)}"
      )

      complete_manual_check = %CompleteManualCheck{
        task_uuid: task_uuid,
        score: extract_score!(output_file_path),
        submissions: submissions,
        uuid: uuid,
        triggered_by: triggered_by
      }

      :ok = persist_output(output_file_path, task_uuid, uuid, :manual)

      # We now want to safely delete the original output.json (maybe with the whole tournament dir?)
      # Because it will mislead the whole `on_success` function another time it will be called
      :ok = File.rm!(output_file_path)

      ZhrDevs.App.dispatch(complete_manual_check)
    else
      Logger.error("Manual tournament generation failed")

      {:error, "#{output_file_path} file doesn't exist"}
    end
  end

  def output_json_path(task) when is_atom(task) do
    task
    |> Atom.to_string()
    |> output_json_path()
  end

  def output_json_path(task) when is_binary(task) do
    Path.join([File.cwd!(), "tournament", task, "output.json"])
  end

  defp extract_score!(path) do
    path |> File.read!() |> Jason.decode!() |> Map.fetch!("gen_multiplayer_score")
  end

  defp persist_output(output_json_file_path, task_uuid, solution_uuid, type \\ :auto)

  defp persist_output(output_json_file_path, task_uuid, uuid, :maual) do
    backup_path =
      Path.join([@output_json_backup_folder, T.un(task_uuid), "manual", "#{T.un(uuid)}.json"])

    :ok = File.mkdir_p!(Path.dirname(backup_path))
    :ok = File.cp!(output_json_file_path, backup_path)
  end

  defp persist_output(output_json_file_path, task_uuid, solution_uuid, _) do
    backup_path =
      Path.join([@output_json_backup_folder, T.un(task_uuid), "#{T.un(solution_uuid)}.json"])

    :ok = File.mkdir_p!(Path.dirname(backup_path))
    :ok = File.cp!(output_json_file_path, backup_path)
  end
end
