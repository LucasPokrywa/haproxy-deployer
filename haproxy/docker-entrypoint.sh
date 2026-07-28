#!/bin/sh
set -eu

HAPROXY_TEMPLATE="${HAPROXY_TEMPLATE:-/etc/haproxy/haproxy.http.cfg.template}"

envsubst \
    < "$HAPROXY_TEMPLATE" \
    > /usr/local/etc/haproxy/haproxy.cfg

haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

exec haproxy \
    -W \
    -db \
    -f /usr/local/etc/haproxy/haproxy.cfg