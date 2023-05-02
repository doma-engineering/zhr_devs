defmodule ZhrDevs.EventStore do
  @moduledoc """
  Represents the event store to be used by the application.

  There is also several adapters available:
  - Commanded.EventStore.Adapters.InMemory - doesn't persist events in any kind of storage, keeping them in memory (good for development and testing)
  - Commanded.EventStore.Adapters.EventStore - uses the EventStore Postgres database to persist events

  Read more: https://github.com/commanded/commanded/blob/master/guides/Choosing%20an%20Event%20Store.md

  Typically, you want to configure the store adapter per Commanded.Application, for example ZhrDevs.IdentityManagement.App
  """

  use EventStore, otp_app: :zhr_devs
end
