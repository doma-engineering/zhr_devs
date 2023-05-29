#!/usr/bin/env bash

if [[ ! -f "./node_modules/.bin/wdio" ]]; then
  npm i -D '@wdio/cli@latest' \
           '@wdio/local-runner@latest' \
           '@wdio/mocha-framework@latest' \
           '@wdio/spec-reporter@latest' \
           'chromedriver@latest' \
           'tsm@latest' \
           'wdio-chromedriver-service@latest'
fi

docker compose up || docker-compose up

_wdio_result="$(cat ./_wdio_result)"
rm "./_wdio_result"

if [[ $_wdio_result == "OK" ]]; then
  exit 0
else
  exit 1
fi
