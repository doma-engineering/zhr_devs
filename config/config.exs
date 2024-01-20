import Config

config :logger,
  backends: [:console],
  format: "[$level] $message\n"

config :zhr_devs, :server,
  host: "localhost",
  scheme: :http,
  port: 4001

config :zhr_devs, :server,
  cowboy_opts: [
    otp_app: :zhr_devs,
    port: 4001
  ]

config :zhr_devs,
  task_support: [
    goo: [:on_the_map],
    rust: [:hanooy_maps],
    unity: [:cuake]
  ]

config :zhr_devs,
  server_code_folders: %{
    {:on_the_map, :goo} => "/tmp/on_the_map_goo"
  }

config :zhr_devs,
  submission_uploads_folder: "/tmp/submissions",
  output_json_backup_folder: "/tmp/output_backup",
  harvested_tasks_structure: ["priv", "tasks", "harvested"],
  command_logs_folder: "/tmp/command_logs"

config :zhr_devs,
  uploads_path: Path.expand("./priv/uploads/#{Mix.env()}"),
  # 30 MB
  max_upload_size: 30_000_000

# Event store configuration
config :zhr_devs, event_stores: [ZhrDevs.EventStore]

config :zhr_devs, :server,
  session: [
    key: "_to_be_overridden",
    encryption_salt: "_to_be_overridden",
    signing_salt: "_to_be_overridden",
    secret_key_base: "oEmi0qbPX1iNGLuG9sSZB+WxbxR99eXznc8nhUf+d8tBv/VxkTYKkFPpMIDLvltG",
    log: :debug
  ]

config :zhr_devs, :event_store,
  adapter: Commanded.EventStore.Adapters.EventStore,
  event_store: ZhrDevs.EventStore

# OAuth configuration

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email"]},
    # https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email"]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

# Default pgsql connection values for people who aren't using auto-generated configuration

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

config :zhr_devs,
  submissions_operator_email: ["jm@memorici.de"]

config :zhr_devs, ZhrDevs.Mailer, adapter: Bamboo.LocalAdapter

# Overrides!

import_config "#{Mix.env()}.exs"

# Import global secrets (not sure it's a good design).
if File.exists?("config/secrets.exs") do
  import_config "secrets.exs"
end

# Also import per-environment secret configuration.
if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end

# Also import auto-generated secret configuration (for example, from running `make dev`).
if File.exists?("config/#{Mix.env()}.secret.auto.exs") do
  import_config "#{Mix.env()}.secret.auto.exs"
end

import_config "deployment.exs"
