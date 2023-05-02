import Config

config :zhr_devs, :event_store,
  adapter: Commanded.EventStore.Adapters.InMemory,
  event_store: ZhrDevs.EventStore

config :logger, level: :info
