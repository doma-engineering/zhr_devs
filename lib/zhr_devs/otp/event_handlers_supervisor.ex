defmodule ZhrDevs.Otp.EventHandlersSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all of the event handlers
  """

  @dialyzer {:no_return, {:init, 1}}

  use Supervisor

  alias ZhrDevs.{IdentityManagement, Submissions, Tasks}

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      IdentityManagement.EventHandler,
      Tasks.EventHandler,
      Submissions.EventHandler,
      Submissions.TransactionalEmailsSender,
      Submissions.DelayedEmailsSender
    ]

    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end
end
