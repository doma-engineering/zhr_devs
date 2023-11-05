defmodule ZhrDevs.Submissions.AutomaticCheckRunner do
  @moduledoc """
  This process is similar to other Event.Handlers, except it's a part
  of a separate supervision tree (ZhrDevs.Otp.SubmissionSupervisor).
  """

  require Logger

  use Commanded.Event.Handler,
    application: ZhrDevs.App,
    name: __MODULE__,
    start_from: :origin

  alias Uptight.Text, as: T

  alias ZhrDevs.Submissions.Events.SolutionCheckCompleted
  alias ZhrDevs.Submissions.Events.SolutionCheckStarted

  def handle(%SolutionCheckStarted{solution_path: solution_path} = event, _meta) do
    %ZhrDevs.Task{} =
      task = ZhrDevs.Tasks.ReadModels.AvailableTasks.get_task_by_uuid(event.task_uuid)

    server_code =
      T.new!(
        Application.fetch_env!(:zhr_devs, :server_code_folders)[{task.name, task.technology}]
      )

    opts = [
      submissions_folder: solution_path |> T.un() |> Path.dirname() |> T.new!(),
      server_code: server_code,
      task: "#{task.name}_#{task.technology}",
      solution_uuid: event.solution_uuid,
      task_uuid: event.task_uuid
    ]

    :ok = ZhrDevs.BakeryIntegration.Queue.enqueue_check(opts)
  end

  def handle(%SolutionCheckCompleted{solution_uuid: solution_uuid}, _meta) do
    # Notice that we are not using the init() callback to delete already processed events.
    # That's because we don't want to reply already processed events on system restart.
    :ok = ZhrDevs.BakeryIntegration.Queue.dequeue_check(solution_uuid)
  end
end
