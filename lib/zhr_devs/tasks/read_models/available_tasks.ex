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

  def get_available_tasks() do
    Agent.get(__MODULE__, fn available_tasks -> available_tasks end)
  end

  def add_task(%ZhrDevs.Task{} = task) do
    Agent.update(__MODULE__, fn available_tasks -> [task | available_tasks] end)
  end
end
