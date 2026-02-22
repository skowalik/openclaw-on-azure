# ─── Based on official OpenClaw image, adding Chromium for browser automation ───
FROM ghcr.io/openclaw/openclaw:latest

USER root

# Install Playwright Chromium + deps (same method as official image's OPENCLAW_INSTALL_BROWSER)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
    mkdir -p /home/node/.cache/ms-playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
    chown -R node:node /home/node/.cache/ms-playwright && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Custom skills (baked into image, copied to agent dir at startup)
COPY skills/ /opt/openclaw-skills/

# Entrypoint script (config restore, MI token fetch, browser setup)
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER node

CMD ["sh", "/usr/local/bin/entrypoint.sh"]
