import Config

config :zhr_devs, :event_store,
  adapter: Commanded.EventStore.Adapters.InMemory,
  event_store: ZhrDevs.EventStore

config :logger, level: :info

config :stream_data, max_runs: 250
