ARG N8N_VERSION
FROM docker.io/n8nio/n8n:${N8N_VERSION}
ARG N8N_VERSION
USER root
RUN rm -f /usr/bin/ssh /usr/bin/scp /usr/bin/sftp
USER node
LABEL org.opencontainers.image.title="DO14 n8n webhook" org.opencontainers.image.version="${N8N_VERSION}"
COPY --chown=node:node tools/check-health.mjs /opt/do14/check-health.mjs
CMD ["webhook"]
