defmodule ZhrDevs.Submissions.Commands.StartCheckSolution do
  @moduledoc """
  This command will be dispatched by the process manager once SolutionSubmitted event will occur.

  There is no need to parse the command with Uptight here, because it will be dispatched by the system.
  """

  @fields [:task_uuid, :solution_uuid, :solution_path]
  @enforce_keys @fields
  defstruct @fields
end
