#!/bin/sh
set -e

OPENCLAW_DIR="/home/node/.openclaw"
WA_CREDS_DIR="$OPENCLAW_DIR/credentials/whatsapp/default"
OC="node /app/openclaw.mjs"

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

# Fetch Managed Identity token for Azure AI Foundry (used by models.providers config)
export AZURE_OPENAI_ENDPOINT="$AZURE_AI_ENDPOINT"
export AZURE_OPENAI_API_KEY=$(curl -sf \
  "http://localhost:12356/msi/token?resource=https%3A%2F%2Fcognitiveservices.azure.com&api-version=2019-08-01" \
  -H "X-IDENTITY-HEADER: $IDENTITY_HEADER" \
  | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).access_token))")

# Configure browser to use Playwright Chromium (if installed)
if [ -d "/home/node/.cache/ms-playwright" ]; then
  $OC config set browser.enabled true 2>/dev/null || true
fi

# Install custom skills from /opt/openclaw-skills/ into agent dir
SKILL_SRC="/opt/openclaw-skills"
SKILL_DST="$OPENCLAW_DIR/agents/main/agent/skills"
if [ -d "$SKILL_SRC" ]; then
  mkdir -p "$SKILL_DST"
  cp -rn "$SKILL_SRC"/* "$SKILL_DST"/ 2>/dev/null || true
fi

# Set default model
$OC models set azure-openai-responses/gpt-5-2-chat 2>/dev/null || true

# Start gateway in background, then auto-approve browser devices in a loop
$OC gateway --allow-unconfigured --bind lan --port 18789 &
GATEWAY_PID=$!

# Poll every 30s and approve any pending browser device
(
  sleep 8
  while kill -0 $GATEWAY_PID 2>/dev/null; do
    $OC devices approve --latest \
      --url ws://localhost:18789 \
      --token "$OPENCLAW_GATEWAY_TOKEN" 2>/dev/null || true
    sleep 30
  done
) &

# Forward signals to gateway process
wait $GATEWAY_PID
