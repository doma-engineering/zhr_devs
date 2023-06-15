.PHONY: db dev test danger_zone_i_am_sure_i_want_to_clean_dev_state pg_ctl migrate start

# Create pgdata directory.
pgdata:
	initdb -D pgdata

# Copy config files to pgdata.
pgdata/sockets pgdata/postgresql.conf:
	mkdir -p pgdata/sockets
	cp priv/dev/postgresql.conf ./pgdata/

pgdata/pg_hba.conf: pgdata/sockets pgdata/postgresql.conf
	cp priv/dev/pg_hba.conf ./pgdata/

# Start database if it's not running.
pg_ctl:
	pg_ctl status -D ./pgdata/ || pg_ctl -D ./pgdata -l logfile start

start: pg_ctl

# Create database and run migrations.
# To run the recipe for `pgdata/pg_hba.conf`, we use $(MAKE) command followed by the name of the target.
# It is necessary, because we need to create roles in an insecure trust setting, before applying more secure settings.
# The $(MAKE) command is a built-in variable in make that allows you to run make recursively.
# See: https://www.gnu.org/software/make/manual/html_node/MAKE-Variable.html
db: pgdata pgdata/sockets pgdata/postgresql.conf
	$(MAKE) pg_ctl
	priv/dev/create-role-phoenix.sh
	$(MAKE) pgdata/pg_hba.conf
	pg_ctl -D ./pgdata -l logfile restart
	mix ecto.create || true
	mix ecto.migrate || true
	mix event_store.create || true
	mix event_store.init || true
	mix event_store.migrate || true

# Copy pre-commit hook to .git/hooks/.
.git/hooks/pre-commit:
	cp -v priv/dev/pre-commit .git/hooks/

HAS_DIRENV := $(shell command -v direnv 2> /dev/null)

# Set up dev environment.
dev: db .git/hooks/pre-commit
ifndef HAS_DIRENV
	echo "Running without direnv. You can install direnv and nix with flakes to get reproducible dev environment."
endif
ifdef HAS_DIRENV
	direnv allow
endif

# Test stuff.
# First make sure that test database is created.
# Then make sure taht it is running.
test: start
	mix test

migrate:
	$(MAKE) pg_ctl
	mix ecto.create
	mix ecto.migrate

danger_zone_i_am_sure_i_want_to_clean_dev_state:
	pg_ctl -D ./pgdata -l logfile stop
	rm -rf ./logfile ./pgdata
