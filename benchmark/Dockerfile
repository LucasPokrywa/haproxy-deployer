FROM williamyeh/wrk

COPY files/example.lua /scripts/example.lua
COPY docker-entrypoint.sh /usr/local/bin/benchmark-entrypoint

RUN chmod +x /usr/local/bin/benchmark-entrypoint

ENTRYPOINT ["/usr/local/bin/benchmark-entrypoint"]