#!/usr/bin/env bash

_db_suffix=""
if [ ! -z "$1" ]; then
  _db_suffix="_$1"
fi
# Grep for the first occurrence of `app: APPLICATION_NAME,` and extract APPLICATION_NAME.
_application_name=$(grep -E 'app: :[a-z][a-zA-Z0-9_]*,' mix.exs | head -n1 | cut -d ':' -f 3 | cut -d ',' -f 1)
psql -U phoenix -h 127.0.0.1 -p 5666 -d "${_application_name}${_db_suffix}"
