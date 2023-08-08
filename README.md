# ZhrDevs

**Development env setup**

- Get the OAuth secrets from passveil: `veil show accounts.google.com/oauth/zerohr-staging-localhost`

- Insert the secrets into `config/dev.secret.exs` in the following format:

```
import Config

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  client_secret: "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
```

- If you don't run a global postgresql on default port, but would rather have it local, run:

```bash
make dev
mix test && echo ok || echo ko
```

- If you want to drop the database: `make danger_zone_i_am_sure_i_want_to_clean_dev_state`

- Initialize the event_store (the configuration for database is in config files) for development, run:

```bash
mix event_store.create
mix event_store.init
```

- If you plan to work on the front-end part only, currently there is no solution to connect it with the running backend, so mock API calls in the templates.

- To run application:

```bash
cd assets && yarn build && cd .. && iex -S mix
```
