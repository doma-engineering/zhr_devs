defmodule ZhrDevs.Submissions.Aggregates.ManualCheck do
  @moduledoc """
  Note: because our :identity is the same as with Identity aggregate, we have to provide an ignore clauses...
  """

  defstruct last_check_status: :new, last_check_uuid: nil, triggered_by: nil, triggered_at: nil

  alias ZhrDevs.Submissions.{Commands, Events}

  @three_minutes_in_seconds 5 * 60

  @type t() ::
          %{
            :__struct__ => __MODULE__,
            required(:last_check_status) => :new | :running | :completed | :failed,
            required(:last_check_uuid) => Uptight.Text.t(),
            required(:triggered_by) => Uptight.Base.Urlsafe.t()
          }

  def execute(
        %__MODULE__{last_check_status: :running, triggered_at: triggered_at},
        %Commands.TriggerManualCheck{} = command
      ) do
    time_diff = DateTime.diff(DateTime.utc_now(), triggered_at, :second)

    if time_diff < @three_minutes_in_seconds do
      {:error, "Please try again in #{@three_minutes_in_seconds - time_diff} seconds"}
    else
      %Events.ManualCheckTriggered{
        uuid: command.uuid,
        task_uuid: command.task_uuid,
        submissions: command.submissions,
        triggered_by: command.triggered_by,
        triggered_at: command.triggered_at,
        submissions_folder: command.submissions_folder
      }
    end
  end

  def execute(%__MODULE__{}, %Commands.TriggerManualCheck{} = command) do
    %Events.ManualCheckTriggered{
      uuid: command.uuid,
      task_uuid: command.task_uuid,
      submissions: command.submissions,
      triggered_by: command.triggered_by,
      triggered_at: command.triggered_at,
      submissions_folder: command.submissions_folder
    }
  end

  def execute(%__MODULE__{}, %Commands.CompleteManualCheck{} = cmd) do
    %Events.ManualCheckCompleted{
      uuid: cmd.uuid,
      task_uuid: cmd.task_uuid,
      submissions: cmd.submissions,
      score: cmd.score
    }
  end

  def execute(%__MODULE__{}, _unhandled_command) do
    []
  end

  def apply(%__MODULE__{} = state, %Events.ManualCheckTriggered{
        uuid: uuid,
        triggered_by: triggered_by,
        triggered_at: triggered_at
      }) do
    %__MODULE__{
      state
      | last_check_status: :running,
        last_check_uuid: uuid,
        triggered_by: triggered_by,
        triggered_at: triggered_at
    }
  end

  def apply(%__MODULE__{} = state, %Events.ManualCheckCompleted{}) do
    %__MODULE__{
      state
      | last_check_status: :completed
    }
  end

  def apply(state, _unhandled_event) do
    state
  end
end
