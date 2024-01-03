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

# If you don't run a global postgresql on default port, but would rather have it local, run:

```bash
make dev
mix test && echo ok || echo ko
```

To run whole test suite:

```bash
mix test.all
```

- If you want to drop the database: `make danger_zone_i_am_sure_i_want_to_clean_dev_state`

- To run application:

```bash
make iex
```

- To run just the PGSQL server after a reboot (when the PGSQL server isn't running):

```bsah
make start
```

# If you run a global PGSQL on a default port

## You shouldn't

### But still

Everything will work out of the box, just don't forget to initialize the event_store (the configuration for database is in config files) for development, run:

```bash
mix event_store.create
mix event_store.init
```

And also you won't get to use `make` commands, you'll have to compile yarn stuff yourself:

```bash
cd assets && yarn install && yarn build && cd ..
```

Afterwards, you'll be able to just `iex -S mix` to get the freshest build.

In principle, just running this chain of yarn commands in a separate terminal or running `make priv/static` should hot-load new compiled JS files but I normally recompile everything.
