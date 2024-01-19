defmodule ZhrDevs.Otp.SubmissionsSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all of the event handlers
  """

  @dialyzer {:no_return, {:init, 1}}

  use Supervisor

  alias ZhrDevs.Submissions
  alias ZhrDevs.Submissions.ReadModels.CandidateSubmissions

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      ZhrDevs.Submissions.ProcessManagers.CheckSolution,
      Submissions.EventHandler,
      CandidateSubmissions
    ]

    Supervisor.init(children, strategy: :one_for_all, name: __MODULE__)
  end
end
