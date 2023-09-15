defmodule ZhrDevs.Tasks.ReadModels.AvailableTasks do
  @moduledoc false

  @callback get_task_by_uuid(Uptight.Text.t()) :: ZhrDevs.Task.t() | nil
  @callback get_task_by_name_technology(atom(), atom()) :: ZhrDevs.Task.t() | nil
  @callback get_available_tasks() :: [ZhrDevs.Task.t()]
  @callback add_task(ZhrDevs.Task.t()) :: :ok

  def get_task_by_uuid(uuid), do: impl().get_task_by_uuid(uuid)

  def get_task_by_name_technology(name, technology),
    do: impl().get_task_by_name_technology(name, technology)

  def get_available_tasks, do: impl().get_available_tasks()
  def add_task(task), do: impl().add_task(task)

  defp impl,
    do:
      Application.get_env(
        :zhr_devs,
        :available_tasks_module,
        ZhrDevs.Tasks.ReadModels.AvailableTasksAgent
      )
end
