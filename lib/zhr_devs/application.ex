defmodule ZhrDevs.Application do
  @moduledoc false
  use Application

  alias ZhrDevs.Otp.SubmissionCheckSupervisor
  alias ZhrDevs.Otp.SubmissionsSupervisor
  alias ZhrDevs.Otp.TasksSupervisor
  alias ZhrDevs.Otp.TransactionalEventsHandler

  alias ZhrDevs.IdentityManagement

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ZhrDevs.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ZhrDevs.DynamicSupervisor},
      {Task.Supervisor, name: ZhrDevs.EmailsSendingSupervisor},
      ZhrDevs.App,
      IdentityManagement.EventHandler,
      TasksSupervisor,
      SubmissionsSupervisor,
      SubmissionCheckSupervisor,
      TransactionalEventsHandler,
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
