defmodule ZhrDevs.Tasks.Commands.ChangeTaskMode do
  @moduledoc """
  This command is for changing the task mode (manual or automatic)

  Tasks are created in manual mode by default (if no flags applied to SupportTask command).
  """
  alias ZhrDevs.App

  alias Uptight.Result

  alias ZhrDevs.Tasks.TaskIdentity

  @enforce_keys [:name, :technology, :trigger_automatic_check, :task_identity]
  defstruct @enforce_keys

  @spec dispatch(Keyword.t()) :: :ok | {:error, Result.Err.t()}
  def dispatch(opts \\ []) do
    case parse(opts) do
      %Result.Ok{ok: ok} ->
        App.dispatch(ok)

      error ->
        {:error, error}
    end
  end

  defp parse(opts) do
    Result.new(fn ->
      name = Keyword.fetch!(opts, :name)
      technology = Keyword.fetch!(opts, :technology)
      trigger_automatic_check = Keyword.fetch!(opts, :trigger_automatic_check)

      build_command(name, technology, trigger_automatic_check)
    end)
  end

  defp build_command(name, technology, trigger_automatic_check) do
    %__MODULE__{
      name: name,
      technology: technology,
      trigger_automatic_check: trigger_automatic_check,
      task_identity: TaskIdentity.new(name: name, technology: technology)
    }
  end
end
