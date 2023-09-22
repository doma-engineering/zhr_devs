defmodule ZhrDevs.Tasks.ReadModels.AvailableTasksAgent do
  @moduledoc """
  Read model that holds a list with available tasks.

  This read model is listen to events in ZhrDevs.Tasks.EventHandler
  And reacts accordingly to the events:
  - When TaskSupported event is fired, it adds the task to the list of available tasks.
  """

  use Agent

  def start_link(available_tasks \\ []) do
    Agent.start_link(fn -> available_tasks end, name: __MODULE__)
  end

  @spec get_task_by_uuid(Uptight.Text.t()) :: ZhrDevs.Task.t() | nil
  def get_task_by_uuid(%Uptight.Text{} = uuid) do
    Agent.get(__MODULE__, fn available_tasks ->
      Enum.find(available_tasks, fn task -> task.uuid == uuid end)
    end)
  end

  @spec get_task_by_name_technology(atom(), atom()) :: ZhrDevs.Task.t() | nil
  def get_task_by_name_technology(name, technology) do
    Agent.get(__MODULE__, fn available_tasks ->
      Enum.find(available_tasks, fn task ->
        task.name == name and task.technology == technology
      end)
    end)
  end

  @spec get_available_tasks() :: [ZhrDevs.Task.t()]
  def get_available_tasks do
    Agent.get(__MODULE__, fn available_tasks -> available_tasks end)
  end

  @spec add_task(ZhrDevs.Task.t()) :: :ok
  def add_task(%ZhrDevs.Task{} = task) do
    Agent.update(__MODULE__, fn available_tasks -> [task | available_tasks] end)
  end

  @spec change_task_mode(atom(), atom(), boolean()) :: :ok
  def change_task_mode(name, technology, new_mode) do
    Agent.update(__MODULE__, fn available_tasks ->
      Enum.map(available_tasks, &do_change_mode(&1, name, technology, new_mode))
    end)
  end

  defp do_change_mode(%ZhrDevs.Task{name: name, technology: tech} = task, name, tech, mode) do
    %ZhrDevs.Task{task | trigger_automatic_check: mode}
  end

  defp do_change_mode(%ZhrDevs.Task{} = task, _, _, _), do: task
end
