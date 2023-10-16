defmodule ZhrDevs.Application do
  @moduledoc false
  use Application

  alias ZhrDevs.{IdentityManagement, Submissions, Tasks}

  alias ZhrDevs.Otp.ProcessManagersSupervisor
  alias ZhrDevs.Otp.ProjectionsSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ZhrDevs.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ZhrDevs.DynamicSupervisor},
      ZhrDevs.App,
      ProjectionsSupervisor,
      ProcessManagersSupervisor,
      IdentityManagement.EventHandler,
      Submissions.EventHandler,
      Tasks.EventHandler,
      ZhrDevs.Submissions.TransactionalEmailsSender,
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
