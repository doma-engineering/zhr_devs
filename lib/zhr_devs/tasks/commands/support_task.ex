defmodule ZhrDevs.Tasks.Commands.SupportTask do
  @moduledoc """
  This command is used to add a new task into the system.
  """
  alias ZhrDevs.App

  alias Uptight.Result

  defstruct [:task_uuid, :technology, :name]

  @spec dispatch(Keyword.t()) :: :ok | {:error, Result.err()}
  def dispatch(opts) do
    uuid = Keyword.fetch!(opts, :uuid)
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
      name: task.name
    }
  end
end
