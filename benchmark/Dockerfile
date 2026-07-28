FROM williamyeh/wrk

COPY files/example.lua /example.lua

ENTRYPOINT ["wrk", "-t16", "-c1000", "-d30s", "-s", "/example.lua"]