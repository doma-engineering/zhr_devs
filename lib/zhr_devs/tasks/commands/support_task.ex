defmodule ZhrDevs.Tasks.Commands.SupportTask do
  @moduledoc """
  This command is used to add a new task into the system.
  """
  alias ZhrDevs.App

  alias Uptight.Result

  alias ZhrDevs.Tasks.TaskIdentity

  @enforce_keys [:task_uuid, :technology, :name, :task_identity]
  defstruct @enforce_keys

  @spec dispatch(Keyword.t()) :: :ok | {:error, Result.Err.t()}
  def dispatch(opts) do
    uuid = Commanded.UUID.uuid4()
    name = Keyword.fetch!(opts, :name)
    technology = Keyword.fetch!(opts, :technology)

    case ZhrDevs.Task.parse(uuid, name, technology) do
      %Result.Ok{} = ok_result ->
        ok_result
        |> Result.from_ok()
        |> to_command()
        |> App.dispatch()

      error ->
        {:error, error}
    end
  end

  defp to_command(%ZhrDevs.Task{} = task) do
    %ZhrDevs.Tasks.Commands.SupportTask{
      task_uuid: task.uuid,
      technology: task.technology,
      name: task.name,
      task_identity: TaskIdentity.new(name: task.name, technology: task.technology)
    }
  end
end
