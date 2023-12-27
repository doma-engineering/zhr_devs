defmodule ZhrDevs.Submissions.Commands.CompleteSolutionCheck do
  @moduledoc """
  A command must contain a field to uniquely identify the aggregate instance (e.g. account_number).
  Use @enforce_keys to force the identity field to be specified when creating the command struct.

  This command will be issued by the check worker once the solution will be checked successfully.
  """

  alias ZhrDevs.Submissions.Events.SolutionCheckCompleted

  @fields SolutionCheckCompleted.fields()
  defstruct @fields
end
