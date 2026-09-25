ARG N8N_VERSION=2.40.6
FROM docker.n8n.io/n8nio/n8n:${N8N_VERSION}

LABEL org.opencontainers.image.title="DO14 n8n"
LABEL org.opencontainers.image.description="Pinned n8n with a dependency-free diagnostics command"

COPY --chown=node:node tools/check-health.mjs /opt/do14/check-health.mjs

# The same image runs main, webhook and worker; Kubernetes defines role-specific probes.
