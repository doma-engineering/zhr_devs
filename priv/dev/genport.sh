#!/usr/bin/env bash

function port_as_name_hash() {
    # Make sure we got both arguments.
    if [ $# -ne 2 ]; then
        echo "Usage: $0 <application-name> <project-name>. For example: $0 myapp MyApp"
        exit 1
    fi
    # Hash the port number to get a name for the database.
    # This is to avoid collisions when running multiple services on the same machine.
    # Code follows:
    _preimage="$1-$2"
    _hash=$(echo -n "$_preimage" | sha256sum | cut -d ' ' -f 1)
    # Turn _hash into a number between 5665 and 65535.
    _hash=$(echo "$_hash" | tr -d '[:alpha:]' | cut -c 1-5)
    # __debug_val=$(( 100 * _hash / 100000  ))
    # echo "DEBUG::: _hash: $_hash and 100 * _hash/100000: $__debug_val"
    _hash=$(( 5665 + ( 65535 - 5665 ) * _hash / 100000 ))
    echo "$_hash"
}

# Grep for `defmodule PROJECTNAME.MixProject` and extract PROJECTNAME.
_project_name=$(grep -E 'defmodule [A-Z][a-zA-Z0-9_]*\.MixProject' mix.exs | cut -d ' ' -f 2 | cut -d '.' -f 1)
# Grep for the first occurrence of `app: APPLICATION_NAME,` and extract APPLICATION_NAME.
# TODO: Split application_name_atom and application_name_atom_atom.
_application_name=$(grep -E 'app: :[a-z][a-zA-Z0-9_]*,' mix.exs | head -n1 | cut -d ':' -f 3 | cut -d ',' -f 1)

# Generate a port number between 5665 and 65535.
port_as_name_hash "$_application_name" "$_project_name"
