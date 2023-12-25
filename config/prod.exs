import Config

port = String.to_integer(System.get_env("PORT", "4001"))

config :zhr_devs, :server,
  host: System.get_env("ZHR_DEVS_HOST", "devs.zhr.staging.doma.dev"),
  scheme: :http,
  port: port,
  cowboy_opts: [
    port: port,
    otp_app: :zhr_devs
  ]

config :zhr_devs, ZhrDevs.EventStore,
  column_data_type: "jsonb",
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.fetch_env!("PG_USER"),
  password: System.fetch_env!("PG_PASSWORD"),
  hostname: System.fetch_env!("PG_HOST"),
  database: System.get_env("EVENT_STORE_DB", "zhr_devs_eventstore"),
  pool_size: String.to_integer(System.get_env("PG_POOL_SIZE", "10")),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :logger,
  backends: [:console, {LoggerFileBackend, :info}],
  format: "[$level] $message\n"

  # configuration for the {LoggerFileBackend, :error_log} backend
  config :logger, :info,
    path: "/var/log/zhr_devs/info.log",
    level: :info
