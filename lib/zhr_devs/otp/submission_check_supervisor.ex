defmodule ZhrDevs.Otp.SubmissionCheckSupervisor do
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
      ZhrDevs.BakeryIntegration.Queue,
      {DynamicSupervisor, check_supervisor_opts()},
      ZhrDevs.Submissions.AutomaticCheckRunner
    ]

    Supervisor.init(children, strategy: :rest_for_one, name: __MODULE__)
  end

  defp check_supervisor_opts do
    [
      strategy: :one_for_one,
      max_children: max_children(),
      max_seconds: 60,
      max_restarts: 3,
      name: ZhrDevs.Submissions.CheckSupervisor
    ]
  end

  defp max_children do
    if System.get_env("MIX_ENV") == "test", do: 100, else: 1
  end
end
