#!/bin/sh
set -e

OPENCLAW_DIR="/home/node/.openclaw"
WA_CREDS_DIR="$OPENCLAW_DIR/credentials/whatsapp/default"

# Restore openclaw.json from Key Vault secret (via env var)
if [ -n "$OPENCLAW_CONFIG" ]; then
  mkdir -p "$OPENCLAW_DIR"
  printf '%s' "$OPENCLAW_CONFIG" > "$OPENCLAW_DIR/openclaw.json"
fi

# Restore WhatsApp credentials from Key Vault secret (base64-encoded tar.gz)
if [ -n "$OPENCLAW_WA_AUTH" ]; then
  mkdir -p "$WA_CREDS_DIR"
  printf '%s' "$OPENCLAW_WA_AUTH" | base64 -d | tar xzf - -C "$WA_CREDS_DIR"
fi

# Start gateway in background, then auto-approve first browser device
node openclaw.mjs gateway --allow-unconfigured --bind lan --port 18789 &
GATEWAY_PID=$!

# Wait for gateway to be ready, then approve pending browser devices
(
  sleep 8
  node openclaw.mjs devices approve --latest \
    --url ws://localhost:18789 \
    --token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true
) &

# Forward signals to gateway process
wait $GATEWAY_PID
