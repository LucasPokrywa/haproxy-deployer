FROM williamyeh/wrk:4.0.2

COPY files/example.lua /scripts/example.lua
COPY docker-entrypoint.sh /usr/local/bin/benchmark-entrypoint

RUN chmod +x /usr/local/bin/benchmark-entrypoint

ENTRYPOINT ["/usr/local/bin/benchmark-entrypoint"]
