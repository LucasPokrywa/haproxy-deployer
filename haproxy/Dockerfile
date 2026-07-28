FROM haproxy:3.2-alpine

USER root

RUN apk add --no-cache gettext

COPY haproxy/docker-entrypoint.sh /usr/local/bin/project-entrypoint
COPY templates/haproxy.cfg.template /etc/haproxy/haproxy.cfg.template

RUN chmod +x /usr/local/bin/project-entrypoint

ENTRYPOINT ["/usr/local/bin/project-entrypoint"]