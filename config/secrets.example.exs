import Config

config :zhr_devs, :server,
  session: [
    key: "_zhr_devs_session",
    encryption_salt: "encryption salt",
    signing_salt: "salt",
    secret_key_base: "oEmi0qbPX1iNGLuG9sSZB+WxbxR99eXznc8nhUf+d8tBv/VxkTYKkFPpMIDLvltG",
    log: :debug
  ]
