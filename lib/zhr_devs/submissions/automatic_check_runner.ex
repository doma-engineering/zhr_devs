defmodule ZhrDevs.Submissions.AutomaticCheckRunner do
  @moduledoc """
  This process is similar to other Event.Handlers, except it's a part
  of a separate supervision tree (ZhrDevs.Otp.SubmissionSupervisor).

  When we enqueue check we have two options:
  - Enqueue using normal procedure, which will insert the check at the end of queue (used for automatic checks)
  - Prioritize the check, which will insert the check at the beginning of queue (used for manual checks)

  Note, that opts, that we are building here will be passed by queue to the
  ZhrDevs.BakeryIntegration.Commands.GenMultiplayer.run/1 function, which will
  build the command with respect to the :type option provided (we have slightly different flow for manual and automatic checks)

  This is important, because we want Queue and CommandRunner processes to be decoupled from this logic.

  Why we should execute the IO side effects separately from the pure logic? This article explains it well:
  https://github.com/commanded/commanded/wiki/Functional-core%2C-imperative-shell
  """

  require Logger

  use Commanded.Event.Handler,
    application: ZhrDevs.App,
    name: __MODULE__,
    start_from: :origin

  alias Uptight.Text, as: T

  alias ZhrDevs.Submissions.Events.SolutionCheckCompleted
  alias ZhrDevs.Submissions.Events.SolutionCheckFailed
  alias ZhrDevs.Submissions.Events.SolutionCheckStarted

  alias ZhrDevs.Submissions.Events.ManualCheckCompleted
  alias ZhrDevs.Submissions.Events.ManualCheckFailed
  alias ZhrDevs.Submissions.Events.ManualCheckTriggered

  def init do
    :ok = ZhrDevs.Queries.delete_handler_subscriptions(__MODULE__)
  end

  def handle(%SolutionCheckStarted{} = event, _meta) do
    %ZhrDevs.Task{} =
      task = ZhrDevs.Tasks.ReadModels.AvailableTasks.get_task_by_uuid(event.task_uuid)

    if task.trigger_automatic_check do
      enqueue_check(event, task)
    else
      :ok
    end
  end

  def handle(%SolutionCheckCompleted{solution_uuid: solution_uuid}, _meta) do
    :ok = ZhrDevs.BakeryIntegration.Queue.dequeue_check(solution_uuid)
  end

  def handle(%SolutionCheckFailed{solution_uuid: solution_uuid}, _meta) do
    :ok = ZhrDevs.BakeryIntegration.Queue.dequeue_check(solution_uuid)
  end

  def handle(%ManualCheckFailed{uuid: check_uuid}, _meta) do
    :ok = ZhrDevs.BakeryIntegration.Queue.dequeue_check(check_uuid)
  end

  def handle(%ManualCheckCompleted{uuid: check_uuid}, _meta) do
    :ok = ZhrDevs.BakeryIntegration.Queue.dequeue_check(check_uuid)
  end

  def handle(%ManualCheckTriggered{} = event, _meta) do
    %ZhrDevs.Task{} =
      task = ZhrDevs.Tasks.ReadModels.AvailableTasks.get_task_by_uuid(event.task_uuid)

    enqueue_check(event, task)
  end

  defp enqueue_check(
         %SolutionCheckStarted{solution_path: solution_path} = event,
         %ZhrDevs.Task{} = task
       ) do
    command_module = ZhrDevs.BakeryIntegration.command_module(task)

    opts = [
      solution_path: solution_path,
      server_code: server_code(task),
      task: "#{task.name}_#{task.technology}",
      check_uuid: event.solution_uuid,
      task_uuid: event.task_uuid,
      type: :automatic,
      command_module: command_module
    ]

    command_specific_options = opts |> command_module.build() |> Uptight.Result.from_ok()
    check_options = Keyword.merge(opts, command_specific_options)

    :ok = ZhrDevs.BakeryIntegration.Queue.enqueue_check(check_options)
  end

  defp enqueue_check(
         %ManualCheckTriggered{submissions_folder: submissions_folder} = event,
         %ZhrDevs.Task{} = task
       ) do
    command_module = ZhrDevs.BakeryIntegration.command_module(task)

    opts = [
      submissions_folder: submissions_folder,
      server_code: server_code(task),
      task: "#{task.name}_#{task.technology}",
      task_uuid: event.task_uuid,
      check_uuid: event.uuid,
      type: :manual,
      triggered_by: event.triggered_by,
      command_module: ZhrDevs.BakeryIntegration.command_module(task)
    ]

    command_specific_options = opts |> command_module.build() |> Uptight.Result.from_ok()
    check_options = Keyword.merge(opts, command_specific_options)

    :ok = ZhrDevs.BakeryIntegration.Queue.prioritize_check(check_options)
  end

  defp server_code(%ZhrDevs.Task{} = task) do
    T.new!(Application.fetch_env!(:zhr_devs, :server_code_folders)[{task.name, task.technology}])
  end
end
