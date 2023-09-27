import Config

port = String.to_integer(System.get_env("PORT", "4001"))

config :zhr_devs, :server,
  host: System.get_env("ZHR_DEVS_HOST", "devs.zhr.staging.doma.dev"),
  scheme: :http,
  port: port,
  cowboy_opts: [
    port: port,
    otp_app: :zhr_devs,
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    keyfile: System.get_env("SSL_KEYFILE"),
    certfile: System.get_env("SSL_CERTFILE")
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
