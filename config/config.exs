import Config

config :zhr_devs, :server,
  port: 4001,
  host: "localhost"

config :zhr_devs,
       :supported_technologies,
       ~w[elixir haskell lean typescript python rust kotlin java]a

# Event store configuration
config :zhr_devs, event_stores: [ZhrDevs.EventStore]

config :zhr_devs, ZhrDevs.EventStore,
  column_data_type: "jsonb",
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "zhr_devs_eventstore",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :zhr_devs, :event_store,
  adapter: Commanded.EventStore.Adapters.EventStore,
  event_store: ZhrDevs.EventStore

# OAuth configuration

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, []},
    github: {Ueberauth.Strategy.Github, []}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

import_config "#{Mix.env()}.exs"
import_config "secrets.exs"
