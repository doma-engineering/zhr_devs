defmodule ZhrDevs.Application do
  @moduledoc false
  use Application

  alias ZhrDevs.{IdentityManagement, Submissions, Tasks}

  alias ZhrDevs.Otp.ProcessManagersSupervisor
  alias ZhrDevs.Otp.ProjectionsSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      ZhrDevs.App,
      ProjectionsSupervisor,
      ProcessManagersSupervisor,
      IdentityManagement.EventHandler,
      Submissions.EventHandler,
      Tasks.EventHandler,
      {Plug.Cowboy,
       scheme: :http,
       plug: ZhrDevs.Web.PublicRouter,
       options: [
         otp_app: :zhr_devs,
         port: Application.get_env(:zhr_devs, :server)[:port]
       ]}
    ]

    opts = [strategy: :one_for_one, name: ZhrDevs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
