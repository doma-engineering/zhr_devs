defmodule ZhrDevs.Otp.TasksSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all of the event handlers
  """

  @dialyzer {:no_return, {:init, 1}}

  use Supervisor

  alias ZhrDevs.Tasks

  alias ZhrDevs.Submissions.ReadModels.TaskDownloads
  alias ZhrDevs.Tasks.ReadModels.AvailableTasksAgent

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      TaskDownloads,
      AvailableTasksAgent,
      Tasks.EventHandler
    ]

    Supervisor.init(children, strategy: :one_for_all, name: __MODULE__)
  end
end
