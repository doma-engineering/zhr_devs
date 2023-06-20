import Config

config :zhr_devs, :server,
  port: 4002,
  host: "localhost"

config :zhr_devs, :event_store,
  adapter: Commanded.EventStore.Adapters.InMemory,
  event_store: ZhrDevs.EventStore

config :logger, level: :info

config :stream_data, max_runs: 250

config :zhr_devs,
  # 1 MB
  max_upload_size: 1_000_000
