defmodule ZhrDevs.Submissions.Commands.FailSolutionCheck do
  @moduledoc """
  This command will be dispatched by the process manager once SolutionSubmitted event will occur.

  There is no need to parse the command with Uptight here, because it will be dispatched by the system.
  """

  @type t :: %{
          task_uuid: Uptight.Text.t(),
          solution_uuid: Uptight.Text.t(),
          system_error: ZhrDevs.BakeryIntegration.Commands.Command.system_error()
        }

  @fields [:task_uuid, :solution_uuid, :system_error]
  @enforce_keys @fields
  defstruct @fields

  def dispatch(opts) do
    cmd = %__MODULE__{
      task_uuid: Keyword.fetch!(opts, :task_uuid),
      solution_uuid: Keyword.fetch!(opts, :solution_uuid),
      system_error: Keyword.fetch!(opts, :error)
    }

    ZhrDevs.App.dispatch(cmd)
  end
end
