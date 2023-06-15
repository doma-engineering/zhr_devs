#!/usr/bin/env bash

set -euo pipefail

# Check that the project compiles.
# This incidentally checks that we're in the project root directory.
echo "Compiling the project for phx.gen.secret to just print the secret without compilation details."
mix deps.get
mix compile

echo "Setting up variables and generating passwords and secrets with phx.gen.secret..."
_pgsql_dev_port=5666
_pw_phoenix=$(mix phx.gen.secret)
_pw_root=$(mix phx.gen.secret)
_sk_seed=$(mix phx.gen.secret)
_user=$(whoami)

echo "Setting up project name based on ./mix.exs..."
if [ ! -f "mix.exs" ]; then
  echo "Error: mix.exs not found in current directory. Are you in the project root directory?"
  exit 1
fi
# Grep for `defmodule PROJECTNAME.MixProject` and extract PROJECTNAME.
_project_name=$(grep -E 'defmodule [A-Z][a-zA-Z0-9_]*\.MixProject' mix.exs | cut -d ' ' -f 2 | cut -d '.' -f 1)
echo here
# Grep for the first occurrence of `app: APPLICATION_NAME,` and extract APPLICATION_NAME.
_application_name=$(grep -E 'app: :[a-z][a-zA-Z0-9_]*,' mix.exs | head -n1 | cut -d ':' -f 3 | cut -d ',' -f 1)
_application_name=":$_application_name"

echo "Checking existing ~/.pgpass for existing passwords for user phoenix and ${_user}..."
# To find it we grep for 127.0.0.1:${_pgsql_dev_port}:*:phoenix:.* and 127.0.0.1:${_pgsql_dev_port}:*:${_user}:.*
# Then we store those in corresponding variables if we find them.
if grep -q "127.0.0.1:${_pgsql_dev_port}:\*:phoenix:" "${HOME}/.pgpass"; then
  _pw_phoenix=$(grep "127.0.0.1:${_pgsql_dev_port}:\*:phoenix:" "${HOME}/.pgpass" | cut -d ':' -f 5)
else
    echo "127.0.0.1:${_pgsql_dev_port}:*:phoenix:${_pw_phoenix}" >> "${HOME}/.pgpass"
    chmod 0600 "${HOME}/.pgpass"
fi
if grep -q "127.0.0.1:${_pgsql_dev_port}:\*:${_user}:" "${HOME}/.pgpass"; then
  _pw_root=$(grep "127.0.0.1:${_pgsql_dev_port}:\*:${_user}:" "${HOME}/.pgpass" | cut -d ':' -f 5)
else
  echo "127.0.0.1:${_pgsql_dev_port}:*:${_user}:${_pw_root}" >> "${HOME}/.pgpass"
  chmod 0600 "${HOME}/.pgpass"
fi

echo "Creating bootstrap SQL with role 'phoenix' and role ${_user}..."
cat >/tmp/run.sql <<EOF
create role phoenix with password '${_pw_phoenix}';
alter role phoenix with login;
alter role phoenix createdb;
alter role ${_user} with password '${_pw_root}';
alter role ${_user} with login;
EOF

echo "Running bootstrap SQL script..."
psql -h localhost -p "$_pgsql_dev_port" -d postgres -f /tmp/run.sql
rm /tmp/run.sql

cat <<EOF

* * *

Created role 'phoenix' with password ${_pw_phoenix}
Save this password to your configuration!
For demonstration purposes, restricted local logins to password-based logins.
New password for user ${_user} is ${_pw_root}.

EOF

# ...

cat <<EOF

* * *
Now saving phoenix password into ./config/dev.secret.exs
EOF

# ...

cat >> "config/dev.secret.exs" <<EOF
import Config

config ${_application_name}, ${_project_name}.Repo, username: "phoenix", password: "${_pw_phoenix}"
config ${_application_name}, ${_project_name}.Crypto, sk_seed: "${_sk_seed}"

EOF

chmod 0600 "config/dev.secret.exs"

# ...

cat <<EOF

* * *
Now saving phoenix password into ./config/test.secret.exs
EOF

# ...

cat >> "config/test.secret.exs" <<EOF

import Config

config ${_application_name}, ${_project_name}.Repo, username: "phoenix", password: "${_pw_phoenix}"

EOF

# ...

chmod 0600 config/test.secret.exs

echo "Done!"
