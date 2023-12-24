defmodule ZhrDevs.BakeryIntegration.Queue.RunningCheck do
  @moduledoc """
  Represents a running solution check
  """

  alias ZhrDevs.BakeryIntegration.Commands.Command

  @type t() :: %__MODULE__{
          check_uuid: Uptight.Text.t(),
          ref: reference(),
          pid: pid(),
          retries: non_neg_integer(),
          restart_opts: [Command.options()],
          task_technology: String.t()
        }

  @enforce_keys [:check_uuid, :restart_opts, :task_technology]
  defstruct check_uuid: nil,
            ref: nil,
            retries: 0,
            restart_opts: [],
            pid: nil,
            task_technology: nil
end
