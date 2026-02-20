# 🦞 OpenClaw on Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fskowalik%2Fopenclaw-on-azure%2Fmaster%2Finfra%2Fazuredeploy.json)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/skowalik/openclaw-on-azure?quickstart=1)

> Deploy [OpenClaw](https://github.com/openclaw/openclaw) — your personal AI assistant — on Azure in under 5 minutes.

OpenClaw on Azure gives you a private, always-on AI assistant running on Azure Container Apps with Azure AI Foundry (Claude Sonnet), Managed Identity (zero API keys), and persistent storage. No infrastructure to manage — just deploy and go.

---

## ⚡ Quickstart (Pick One)

### Option 1: One-Click Deploy (Fastest)

Click the button — fill in a resource group — done:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fskowalik%2Fopenclaw-on-azure%2Fmaster%2Finfra%2Fazuredeploy.json)

### Option 2: Azure Cloud Shell (No Install Needed)

Open [shell.azure.com](https://shell.azure.com) and paste:

```bash
curl -sL https://raw.githubusercontent.com/skowalik/openclaw-on-azure/master/scripts/quickstart.sh | bash
```

### Option 3: Azure Developer CLI (`azd`)

```bash
azd init -t skowalik/openclaw-on-azure
azd up
```

That's it. `azd` handles resource group creation, Bicep deployment, and container provisioning.

### Option 4: Azure CLI

```bash
git clone https://github.com/skowalik/openclaw-on-azure.git && cd openclaw-on-azure
az login
az group create --name openclaw-rg --location eastus
az deployment group create \
  --resource-group openclaw-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

All options deploy the same infrastructure (~5 minutes). After deployment, open your Container App URL in the Azure Portal and paste the gateway token from Key Vault.

---

## What is OpenClaw?

[OpenClaw](https://openclaw.ai) is a personal AI assistant you run on your own infrastructure. It connects to the messaging channels you already use — WhatsApp, Telegram, Slack, Discord, Microsoft Teams, Signal, and more — through a single gateway control plane.

## What Gets Deployed

| Component  | Azure Service              | Purpose                                                |
|------------|----------------------------|--------------------------------------------------------|
| **Compute**    | Container Apps         | Runs OpenClaw gateway (serverless, scales to zero)     |
| **AI Model**   | AI Foundry + Claude Sonnet | Latest Sonnet model, billed through your Azure subscription |
| **Auth**       | Managed Identity       | Zero API keys — Container Apps authenticates to Foundry & Key Vault automatically |
| **Secrets**    | Key Vault              | Gateway token and channel tokens (RBAC-protected)      |
| **Storage**    | Azure Files            | Persists `~/.openclaw/` config across container restarts |
| **Monitoring** | Log Analytics          | Container logs, metrics, and diagnostics               |

### Deployment Parameters

| Parameter        | Default              | Description                              |
|------------------|----------------------|------------------------------------------|
| `baseName`       | `openclaw`           | Base name for all resources              |
| `location`       | Resource group region | Azure region                            |
| `containerImage` | `ghcr.io/openclaw/openclaw:latest` | Container image to deploy  |
| `containerCpu`   | `0.5`                | CPU cores for the container              |
| `containerMemory`| `1Gi`                | Memory allocation                        |

---

## 🔒 Security

This deployment follows security-first principles:

- **Managed Identity** — No API keys in config. Container Apps authenticates to Key Vault and AI Foundry via Azure Managed Identity.
- **Key Vault** — All secrets stored in Azure Key Vault with RBAC access control. Only the Container App's identity can read secrets.
- **Non-root container** — OpenClaw runs as the `node` user (uid 1000), not root.
- **HTTPS-only** — Azure Container Apps enforces HTTPS with auto-provisioned TLS certificates.
- **DM pairing** — OpenClaw's default `dmPolicy="pairing"` requires sender verification before processing messages from unknown contacts.
- **No public blob access** — Storage account blocks all public blob access.
- **TLS 1.2 minimum** — All Azure resources enforce TLS 1.2+.

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

---

## 💡 Use Cases

### Personal AI Assistant
Deploy your own always-on AI assistant that connects to your messaging apps. Ask questions, get summaries, draft emails — all from WhatsApp, Telegram, or Slack.

### Team Knowledge Hub
Set up OpenClaw for your team with shared workspaces. Connect it to Slack or Microsoft Teams so everyone can interact with the AI assistant in channels they already use.

### Secure Enterprise Assistant
For organizations that need AI capabilities but can't send data to third-party services. Everything runs in your Azure subscription with Managed Identity — no API keys leave your tenant.

### Multi-Channel Customer Support Prototype
Use OpenClaw as a prototype for AI-assisted customer support across WhatsApp, Telegram, and webchat. The gateway handles routing and session management.

### Developer Productivity Tool
Connect OpenClaw to Discord or Slack in your dev team. Use it for code reviews, documentation lookups, debugging help, and automated notifications via cron jobs and webhooks.

### Research & Analysis Assistant
Deploy with high-context models (Claude Sonnet via AI Foundry) for research tasks — summarizing papers, analyzing data, drafting reports — accessible from any messaging channel.

---

## 🖥️ Local Development

### Recommended: GitHub Codespaces (Zero Install)

Click the badge to open a pre-configured dev environment with Azure CLI, Bicep, `azd`, Node.js 22, and Docker — ready to deploy in seconds:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/skowalik/openclaw-on-azure?quickstart=1)

Inside the Codespace, just run:

```bash
azd up
```

### Local: OrbStack (Recommended)

We recommend [OrbStack](https://orbstack.dev/) as your local container runtime. It's faster and lighter than Docker Desktop, with native support for Docker Compose and Kubernetes.

**Install OrbStack:**
- macOS: `brew install orbstack` or download from [orbstack.dev](https://orbstack.dev/)
- Linux: See [OrbStack Linux docs](https://docs.orbstack.dev/install)
- Windows: Use WSL2 with OrbStack inside the Linux VM

> Docker Desktop, Podman, and any OCI-compatible runtime also work — the Dockerfile is standard.

### Build and Run Locally

```bash
# Clone the repo
git clone https://github.com/skowalik/openclaw-on-azure.git
cd openclaw-on-azure

# Build and start
docker compose up --build

# Access the gateway
open http://localhost:18789
```

### Run OpenClaw CLI

```bash
# Run onboarding wizard
docker compose run --rm --profile cli openclaw-cli onboard

# Add a channel
docker compose run --rm --profile cli openclaw-cli channels add --channel telegram --token "YOUR_TOKEN"

# Check health
docker compose run --rm --profile cli openclaw-cli gateway health
```

### Without Docker

If you prefer running OpenClaw directly:

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
openclaw gateway --port 18789 --verbose
```

Requires Node.js ≥22.

---

## 📁 Repository Structure

```
openclaw-on-azure/
├── Dockerfile                    # Multi-stage container image
├── docker-compose.yml            # Local dev with OrbStack/Docker
├── azure.yaml                    # Azure Developer CLI (azd) config
├── .devcontainer/                # GitHub Codespaces / devcontainer
│   └── devcontainer.json
├── .env.example                  # Environment variable template
├── infra/
│   ├── main.bicep                # Main Bicep orchestrator
│   ├── main.parameters.json      # Default deployment parameters
│   ├── azuredeploy.json          # Compiled ARM template (Deploy button)
│   └── modules/
│       ├── container-apps.bicep  # Container Apps + Environment
│       ├── keyvault.bicep        # Key Vault + secrets
│       ├── keyvault-access.bicep # Key Vault RBAC for Managed Identity
│       ├── ai-foundry.bicep      # Azure AI Services + Claude Sonnet
│       ├── ai-access.bicep       # AI Services RBAC for Managed Identity
│       ├── storage.bicep         # Azure Files for persistent config
│       └── monitoring.bicep      # Log Analytics workspace
├── scripts/
│   ├── quickstart.sh             # Cloud Shell one-liner deploy
│   ├── deploy.sh                 # Full deploy script (bash)
│   └── deploy.ps1                # Full deploy script (PowerShell)
├── docs/                         # Additional documentation
├── CONTRIBUTING.md               # Contribution guide
├── SECURITY.md                   # Security policy
└── LICENSE                       # MIT License
```

---

## 🔧 Post-Deployment Setup

After deploying, configure OpenClaw through the Control UI or CLI:

### 1. Access the Control UI
Navigate to your Container App URL and paste the gateway token from Key Vault.

### 2. Configure AI Model
The deployment includes Azure AI Foundry with Claude Sonnet. OpenClaw will auto-detect the model endpoint via the `AZURE_AI_ENDPOINT` environment variable.

### 3. Add Messaging Channels

**Telegram:**
1. Create a bot with [@BotFather](https://t.me/BotFather)
2. Add the token via the Control UI or CLI

**Slack:**
1. Create a Slack App at [api.slack.com](https://api.slack.com/apps)
2. Configure OAuth scopes and event subscriptions
3. Add the bot token via the Control UI

**Discord:**
1. Create a Discord Application at [discord.com/developers](https://discord.com/developers/applications)
2. Add the bot token via the Control UI

**Microsoft Teams:**
1. Register a Teams app in Azure AD
2. Configure the bot channel registration

See the [OpenClaw channel docs](https://docs.openclaw.ai/channels) for detailed setup guides.

### 4. Pair Your Device
OpenClaw uses DM pairing by default. When you message the bot for the first time, it sends a pairing code. Approve it:

```bash
openclaw pairing approve <channel> <code>
```

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Azure Cloud                        │
│                                                      │
│  ┌──────────────┐     ┌─────────────────────────┐   │
│  │  Key Vault   │◄────│   Managed Identity      │   │
│  │  (secrets)   │     │   (zero API keys)       │   │
│  └──────────────┘     └────────────┬────────────┘   │
│                                    │                 │
│  ┌──────────────┐     ┌────────────▼────────────┐   │
│  │ Azure Files  │◄────│   Container Apps         │   │
│  │ (persistent  │     │   ┌──────────────────┐  │   │
│  │  config)     │     │   │  OpenClaw Gateway │  │   │
│  └──────────────┘     │   │  (Node.js ≥22)   │  │   │
│                       │   └──────────────────┘  │   │
│  ┌──────────────┐     └────────────┬────────────┘   │
│  │ Log Analytics│◄─────────────────┘                 │
│  └──────────────┘                                    │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Azure AI Foundry                             │   │
│  │  └─ Claude Sonnet (serverless)                │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
          │
          │ HTTPS (TLS 1.2+)
          ▼
┌─────────────────────────────────────┐
│  Messaging Channels                  │
│  WhatsApp · Telegram · Slack         │
│  Discord · Teams · Signal · WebChat  │
└─────────────────────────────────────┘
```

---

## FAQ

**Q: How much does this cost?**
A: Azure Container Apps scales to zero when idle, so you only pay when the gateway is active. Key Vault, Storage, and Log Analytics have minimal costs. The main cost is AI Foundry usage (pay-per-token for Claude Sonnet). Expect ~$5-20/month for light personal use.

**Q: Can I use a different AI model?**
A: Yes. Modify the `ai-foundry.bicep` module to deploy a different model, or configure OpenClaw to use any supported provider (OpenAI, Anthropic direct, etc.) via the Control UI.

**Q: Is my data private?**
A: Yes. Everything runs in your Azure subscription. No data leaves your tenant. Managed Identity means no API keys are stored in config files.

**Q: Can I run this on-premises?**
A: Yes. Use the `docker-compose.yml` for local/on-prem deployment. You'll need to configure your own AI model provider (API key based).

**Q: How do I update OpenClaw?**
A: Update the `containerImage` parameter to the latest tag and redeploy, or pull the latest image and restart the Container App.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](LICENSE)
