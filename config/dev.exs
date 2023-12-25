import Config

config :logger,
  backends: [:console, {LoggerFileBackend, :info}],
  format: "[$level] $message\n"

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :info,
  path: "/tmp/info.log",
  level: :info
