defmodule ZhrDevs.BakeryIntegration.Queue.RunningCheck do
  @moduledoc """
  Represents a running solution check
  """
  @type restart_opts() :: [
          {:submission_folder, Uptight.Text.t()},
          {:server_code, Uptight.Text.t()},
          {:task, String.t()},
          {:check_uuid, Uptight.Text.t()},
          {:task_uuid, Uptight.Text.t()},
          {:type, :automatic | :manual},
          {:cmd, Ubuntu.Command.t()},
          {:on_success, mfa()},
          {:on_failure, mfa()}
        ]

  @type t() :: %__MODULE__{
          check_uuid: Uptight.Text.t(),
          ref: reference(),
          pid: pid(),
          retries: non_neg_integer(),
          restart_opts: restart_opts(),
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
