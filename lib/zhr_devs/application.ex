defmodule ZhrDevs.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ZhrDevs.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ZhrDevs.DynamicSupervisor},
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
