# ZhrDevs

**Development env setup**

- Initialize the event_store (the configuration for database is in config files) for development, run:
```bash
mix event_store.create
mix event_store.init
```

- If you plan to work on the front-end part only, currently there is no solution to connect is with the running backend, so mock API calls in the templates.

- To run application:
```bash
cd assets && yarn build && cd .. && iex -S mix
```
