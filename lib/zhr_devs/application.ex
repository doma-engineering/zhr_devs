defmodule ZhrDevs.Application do
  @moduledoc false
  use Application

  alias ZhrDevs.Otp.EventHandlersSupervisor
  alias ZhrDevs.Otp.ProcessManagersSupervisor
  alias ZhrDevs.Otp.ProjectionsSupervisor
  alias ZhrDevs.Otp.SubmissionSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ZhrDevs.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ZhrDevs.DynamicSupervisor},
      {Task.Supervisor, name: ZhrDevs.EmailsSendingSupervisor},
      ProjectionsSupervisor,
      ProcessManagersSupervisor,
      SubmissionSupervisor,
      EventHandlersSupervisor,
      cowboy_child_spec()
    ]

    opts = [strategy: :one_for_one, name: ZhrDevs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cowboy_child_spec do
    {
      Plug.Cowboy,
      scheme: Application.fetch_env!(:zhr_devs, :server)[:scheme],
      options: Application.fetch_env!(:zhr_devs, :server)[:cowboy_opts],
      plug: ZhrDevs.Web.PublicRouter
    }
  end
end
