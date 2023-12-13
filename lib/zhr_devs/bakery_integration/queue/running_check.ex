defmodule ZhrDevs.BakeryIntegration.Queue.RunningCheck do
  @moduledoc """
  Represents a running solution check
  """

  alias ZhrDevs.BakeryIntegration.Commands.Command

  @type t() :: %__MODULE__{
          solution_uuid: Uptight.Text.t(),
          ref: reference(),
          pid: pid(),
          retries: non_neg_integer(),
          restart_opts: [Command.options()]
        }

  defstruct solution_uuid: nil, ref: nil, retries: 0, restart_opts: [], pid: nil
end
