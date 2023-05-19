defmodule ZhrDevs.Otp.ProcessManagersSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all the process managers
  """

  @dialyzer {:no_return, {:init, 1}}

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      ZhrDevs.Submissions.ProcessManagers.CheckSolution
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
