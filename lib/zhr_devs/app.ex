defmodule ZhrDevs.App do
  @moduledoc """
  Commanded allows you to define, supervise, and start your own application module. To use Commanded you must create at least one application.
  You can create multiple Commanded applications which will run independently, each using its own separately configured event store.

  The application expects at least an :otp_app option to be specified. It should point to an OTP application containing the application's configuration.

  A Commanded application is also a composite router. This provides the router macro allowing you to include one or more router modules for command dispatch.
  Read more: https://github.com/commanded/commanded/blob/master/guides/Application.md

  Configs for actual persistence inside the Postgres (just for reference):
  ```
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: ZhrDevs.EventStore
    ]
  ```
  """

  use Commanded.Application,
    otp_app: :zhr_devs,
    event_store: Application.compile_env(:zhr_devs, :event_store)

  router(ZhrDevs.IdentityManagement.EventsRouter)
  router(ZhrDevs.Submissions.EventsRouter)
end
