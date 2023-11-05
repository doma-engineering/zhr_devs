defmodule ZhrDevs.BakeryIntegration.Queue.RunningCheck do
  @moduledoc """
  Represents a running solution check
  """
  defstruct solution_uuid: nil, ref: nil, retries: 0, restart_opts: [], pid: nil
end
