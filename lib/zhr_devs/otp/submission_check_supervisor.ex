defmodule ZhrDevs.Otp.SubmissionSupervisor do
  @moduledoc """
  This is a high-level supervisor that will supervise all the submission checks.
  """

  use Supervisor

  @dialyzer {:no_return, {:init, 1}}

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      {DynamicSupervisor, check_supervisor_opts()},
      ZhrDevs.BakeryIntegration.Queue,
      ZhrDevs.Submissions.AutomaticCheckRunner
    ]

    Supervisor.init(children, strategy: :one_for_all, name: __MODULE__)
  end

  defp check_supervisor_opts do
    [
      strategy: :one_for_one,
      max_children: max_children(Mix.env()),
      max_seconds: 60,
      max_restarts: 3,
      name: ZhrDevs.Submissions.CheckSupervisor
    ]
  end

  defp max_children(:test), do: 100
  defp max_children(_), do: 1
end
