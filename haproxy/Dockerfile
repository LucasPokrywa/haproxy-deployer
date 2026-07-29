FROM haproxy:3.2.21-alpine

USER root

RUN apk add --no-cache gettext

COPY haproxy/docker-entrypoint.sh /usr/local/bin/project-entrypoint
COPY templates/haproxy.http.cfg.template /etc/haproxy/haproxy.http.cfg.template
COPY templates/haproxy.https.cfg.template /etc/haproxy/haproxy.https.cfg.template

RUN chmod +x /usr/local/bin/project-entrypoint

ENTRYPOINT ["/usr/local/bin/project-entrypoint"]
