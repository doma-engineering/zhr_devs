defmodule ZhrDevs.Otp.ProjectionsSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all the projections,
  since we want them to be in-memory.

  TODO: In-memory for what? Just for testing? We sometimes write them to JSONB in database, don't we?
  """

  alias ZhrDevs.Submissions.ReadModels.TaskDownloads
  alias ZhrDevs.Tasks.ReadModels.AvailableTasksAgent

  alias ZhrDevs.Submissions.DelayedEmailsSender

  @dialyzer {:no_return, {:init, 1}}

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      AvailableTasksAgent,
      TaskDownloads,
      DelayedEmailsSender
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
