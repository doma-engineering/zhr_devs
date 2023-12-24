defmodule ZhrDevs.Submissions.Commands.CompleteManualCheck do
  @moduledoc """
  This command will be available only for the admins,
  it will allow to trigger all (or the subset of) the submissions.
  """

  @fields [task_uuid: nil, uuid: nil, submissions: [], score: %{}]
  @enforce_keys Keyword.keys(@fields)
  defstruct @fields
end
