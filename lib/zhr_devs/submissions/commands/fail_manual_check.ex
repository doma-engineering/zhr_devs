defmodule ZhrDevs.Submissions.Commands.FailManualCheck do
  @moduledoc """
  This command will be issued by the queue process
  whenever the manual check fails.
  """

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:task_uuid) => Uptight.Text.t(),
          required(:uuid) => Uptight.Text.t(),
          required(:triggered_by) => Uptight.Base.Urlsafe.t(),
          required(:system_error) => ZhrDevs.BakeryIntegration.Commands.Command.system_error(),
          optional(:submissions) => list(Uptight.Text.t())
        }

  @fields [:task_uuid, :uuid, :triggered_by, :system_error, :submissions]
  @enforce_keys @fields
  defstruct @fields

  def dispatch(opts) do
    cmd = %__MODULE__{
      task_uuid: Keyword.fetch!(opts, :task_uuid),
      uuid: Keyword.fetch!(opts, :uuid),
      triggered_by: Keyword.fetch!(opts, :triggered_by),
      system_error: Keyword.fetch!(opts, :error),
      submissions: Keyword.get(opts, :submissions, [])
    }

    ZhrDevs.App.dispatch(cmd)
  end
end
