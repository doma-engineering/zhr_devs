import Config

# You probably should use an env-dependent secrets file such as:
# dev.secret.exs
# prod.secret.exs
# test.secret.exs

config :zhr_devs, :server,
  session: [
    key: "_zhr_devs_session",
    encryption_salt: "encryption salt",
    signing_salt: "salt",
    secret_key_base: "oEmi0qbPX1iNGLuG9sSZB+WxbxR99eXznc8nhUf+d8tBv/VxkTYKkFPpMIDLvltG",
    log: :debug
  ]

### !!! Please consult this message for an example of a working configuration !!!
### https://zulip.memorici.de/#narrow/stream/63-doma-infra/topic/do-auth.20bamboo/near/66912
config :zhr_devs, ZhrDevs.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.domain",
  hostname: "your.domain",
  port: 1025,
  # or {:system, "SMTP_USERNAME"}
  username: "your.name@your.domain",
  # or {:system, "SMTP_PASSWORD"}
  password: "pa55word",
  # can be `:always` or `:never`
  tls: :if_available,
  # or {:system, "ALLOWED_TLS_VERSIONS"} w/ comma separated values (e.g. "tlsv1.1,tlsv1.2")
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  tls_log_level: :error,
  # optional, can be `:verify_peer` or `:verify_none`
  tls_verify: :verify_peer,
  # optional, path to the ca truststore
  tls_cacertfile: "/somewhere/on/disk",
  # optional, DER-encoded trusted certificates
  tls_cacerts: "…",
  # optional, tls certificate chain depth
  tls_depth: 3,
  # optional, tls verification function
  tls_verify_fun: {&:ssl_verify_hostname.verify_fun/3, check_hostname: "example.com"},
  # can be `true`
  ssl: false,
  retries: 1,
  # can be `true`
  no_mx_lookups: false,
  # can be `:always`. If your smtp relay requires authentication set it to `:always`.
  auth: :if_available
