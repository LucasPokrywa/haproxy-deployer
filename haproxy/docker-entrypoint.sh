#!/bin/sh
set -eu

envsubst \
    < /etc/haproxy/haproxy.cfg.template \
    > /usr/local/etc/haproxy/haproxy.cfg

haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

exec haproxy \
    -W \
    -db \
    -f /usr/local/etc/haproxy/haproxy.cfg