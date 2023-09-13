defmodule ZhrDevs.Tasks.ReadModels.AvailableTasks do
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

  @spec get_task_by_name_technology(Uptight.Text.t(), Uptight.Text.t()) :: ZhrDevs.Task.t() | nil
  def get_task_by_name_technology(%Uptight.Text{} = name, %Uptight.Text{} = technology) do
    Agent.get(__MODULE__, fn available_tasks ->
      Enum.find(available_tasks, fn task ->
        task.name == name and task.technology == technology
      end)
    end)
  end

  def get_available_tasks() do
    Agent.get(__MODULE__, fn available_tasks -> available_tasks end)
  end

  def add_task(%ZhrDevs.Task{} = task) do
    Agent.update(__MODULE__, fn available_tasks -> [task | available_tasks] end)
  end
end
