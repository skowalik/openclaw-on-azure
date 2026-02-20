# ─── Build stage ───
FROM node:22-bookworm-slim AS build

RUN corepack enable
WORKDIR /app

RUN npm install -g openclaw@latest

# ─── Runtime stage ───
FROM node:22-bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tini \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib/node_modules/openclaw /usr/local/lib/node_modules/openclaw
COPY --from=build /usr/local/bin/openclaw /usr/local/bin/openclaw

# Non-root user (security-first)
RUN mkdir -p /home/node/.openclaw /home/node/.openclaw/workspace \
    && chown -R node:node /home/node

USER node
WORKDIR /home/node

ENV NODE_ENV=production
ENV OPENCLAW_GATEWAY_BIND=0.0.0.0
ENV OPENCLAW_GATEWAY_PORT=18789

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["tini", "--"]
CMD ["openclaw", "gateway", "--port", "18789", "--allow-unconfigured"]
