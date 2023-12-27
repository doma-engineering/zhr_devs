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

  alias ZhrDevs.Submissions.Commands.CompleteSolutionCheck
  alias ZhrDevs.Submissions.Commands.FailSolutionCheck

  alias ZhrDevs.Submissions.Commands.CompleteManualCheck
  alias ZhrDevs.Submissions.Commands.FailManualCheck

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
    ZhrDevs.Submissions.start_automatic_check(opts)
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
    %T{} =
      submissions_folder =
      opts |> Keyword.fetch!(:solution_path) |> T.un() |> Path.dirname() |> T.new!()

    %T{} = server_code = Keyword.fetch!(opts, :server_code)
    task = Keyword.fetch!(opts, :task)

    callback_opts = [
      output_json_path: output_json_path(task),
      task_uuid: Keyword.fetch!(opts, :task_uuid),
      solution_uuid: Keyword.fetch!(opts, :check_uuid)
    ]

    [
      cmd: Ubuntu.Command.new(@gen_multiplayer, [submissions_folder, server_code]),
      on_success: {__MODULE__, :on_success, [callback_opts]},
      on_failure: {__MODULE__, :on_failure, [callback_opts]}
    ]
  end

  def build_manual(opts \\ []) do
    %T{} = submissions_folder = Keyword.fetch!(opts, :submissions_folder)
    %T{} = server_code = Keyword.fetch!(opts, :server_code)
    task = Keyword.fetch!(opts, :task)

    callback_opts = [
      output_json_path: output_json_path(task),
      task_uuid: Keyword.fetch!(opts, :task_uuid),
      uuid: Keyword.fetch!(opts, :check_uuid),
      submissions: Keyword.get(opts, :submissions, []),
      triggered_by: Keyword.fetch!(opts, :triggered_by)
    ]

    [
      cmd: Ubuntu.Command.new(@gen_multiplayer, [submissions_folder, server_code]),
      on_success: {__MODULE__, :manual_on_success, [callback_opts]},
      on_failure: {__MODULE__, :manual_on_failure, [callback_opts]}
    ]
  end

  @impl Command
  def on_success(opts) do
    output_file_path = Keyword.fetch!(opts, :output_json_path)
    %T{} = task_uuid = Keyword.fetch!(opts, :task_uuid)
    %T{} = solution_uuid = Keyword.fetch!(opts, :solution_uuid)

    if File.exists?(output_file_path) do
      Logger.info("Successfully generated tournament output: #{inspect(output_file_path)}")

      complete_check_solution = %CompleteSolutionCheck{
        solution_uuid: solution_uuid,
        task_uuid: task_uuid,
        score: extract_score!(output_file_path)
      }

      :ok = persist_output(output_file_path, task_uuid, solution_uuid, :automatic)

      # We now want to safely delete the original output.json (maybe with the whole tournament dir?)
      # Because it will mislead the whole `on_success` function another time it will be called
      :ok = File.rm!(output_file_path)

      ZhrDevs.App.dispatch(complete_check_solution)
    else
      Logger.error("Port terminated with :normal reason, but output.json doesn't get generated.")

      {:error, %{error: :on_success_not_met, context: "output.json doesn't get generated"}}
    end
  end

  @impl Command
  def on_failure(%{error: :on_success_not_met, context: context} = system_error, callback_opts) do
    Logger.error(
      "Port terminated with :normal reason, but output.json doesn't get generated.\nLatest output: #{context}"
    )

    FailSolutionCheck.dispatch(Keyword.merge(callback_opts, error: system_error))
  end

  def on_failure(
        %{error: :execution_stopped, context: context, exit_code: code} = system_error,
        callback_opts
      ) do
    Logger.error(
      "Multiplayer generation process is stopped with exit code: #{code}.\nLatest output: #{context}"
    )

    FailSolutionCheck.dispatch(Keyword.merge(callback_opts, error: system_error))
  end

  def on_failure(system_error, callback_opts) do
    FailSolutionCheck.dispatch(Keyword.merge(callback_opts, error: system_error))
  end

  def manual_on_failure(system_error, callback_opts) when is_map(system_error) do
    FailManualCheck.dispatch(Keyword.merge(callback_opts, error: system_error))
  end

  def manual_on_success(opts) do
    output_file_path = Keyword.fetch!(opts, :output_json_path)
    %T{} = task_uuid = Keyword.fetch!(opts, :task_uuid)
    submissions = Keyword.get(opts, :submissions, [])
    %T{} = uuid = Keyword.fetch!(opts, :uuid)
    %Uptight.Base.Urlsafe{} = triggered_by = Keyword.fetch!(opts, :triggered_by)

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
      Logger.error("output.json doesn't get generated. Manual check uuid: #{uuid}")

      {:error, %{error: :on_success_not_met, context: "output.json doesn't get generated"}}
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

  def extract_score!(path) do
    path |> File.read!() |> Jason.decode!() |> Map.fetch!("gen_multiplayer_score")
  end

  @spec persist_output(String.t(), T.t(), T.t(), :automatic | :manual) :: :ok
  def persist_output(output_json_file_path, %T{} = task_uuid, %T{} = uuid, :manual) do
    backup_path =
      Path.join([@output_json_backup_folder, T.un(task_uuid), "manual", "#{T.un(uuid)}.json"])

    :ok = File.mkdir_p!(Path.dirname(backup_path))
    :ok = File.cp!(output_json_file_path, backup_path)
  end

  def persist_output(output_json_file_path, %T{} = task_uuid, %T{} = solution_uuid, _) do
    backup_path =
      Path.join([@output_json_backup_folder, T.un(task_uuid), "#{T.un(solution_uuid)}.json"])

    :ok = File.mkdir_p!(Path.dirname(backup_path))
    :ok = File.cp!(output_json_file_path, backup_path)
  end
end
