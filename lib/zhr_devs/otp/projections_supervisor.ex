defmodule ZhrDevs.Otp.ProjectionsSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all the projections,
  since we want them to be in-memory.
  """

  alias ZhrDevs.Submissions.ReadModels.TaskDownloads

  @dialyzer {:no_return, {:init, 1}}

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      {Registry, keys: :unique, name: ZhrDevs.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ZhrDevs.DynamicSupervisor},
      TaskDownloads
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
