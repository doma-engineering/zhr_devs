#!/usr/bin/env bash

_db_suffix=""
if [ ! -z "$1" ]; then
  _db_suffix="_$1"
fi
psql -U phoenix -h 127.0.0.1 -p 5666 -d "on_the_map${_db_suffix}"
