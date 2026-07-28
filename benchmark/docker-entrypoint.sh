#!/bin/sh
set -eu

exec wrk \
    "-t${BENCHMARK_THREADS:-16}" \
    "-c${BENCHMARK_CONNECTIONS:-1000}" \
    "-d${BENCHMARK_DURATION:-30s}" \
    -s /scripts/example.lua \
    "${BENCHMARK_URL:-http://haproxy/}"