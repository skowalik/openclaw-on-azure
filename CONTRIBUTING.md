# Contributing to OpenClaw on Azure

Thanks for your interest in contributing! This project makes it easy to deploy [OpenClaw](https://github.com/openclaw/openclaw) on Azure with one click.

## Development Setup

### Prerequisites

- [OrbStack](https://orbstack.dev/) (recommended) or Docker Desktop
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (bundled with Azure CLI)
- Node.js ≥22 (for local OpenClaw testing)

### Local Development

1. **Clone the repo:**
   ```bash
   git clone https://github.com/skowalik/openclaw-on-azure.git
   cd openclaw-on-azure
   ```

2. **Build and run locally with OrbStack/Docker:**
   ```bash
   docker compose up --build
   ```

3. **Access the gateway:**
   Open `http://localhost:18789` in your browser.

4. **Run CLI commands:**
   ```bash
   docker compose run --rm --profile cli openclaw-cli onboard
   ```

### Modifying Infrastructure

Bicep templates are in `infra/`. To validate changes:

```bash
az bicep build --file infra/main.bicep
```

To deploy to a test resource group:

```bash
az group create --name openclaw-test --location eastus
az deployment group create \
  --resource-group openclaw-test \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Regenerating ARM Template

After modifying Bicep files, regenerate the ARM JSON for the Deploy button:

```bash
az bicep build --file infra/main.bicep --outfile infra/azuredeploy.json
```

## Code of Conduct

Be respectful, inclusive, and constructive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/).

## Submitting Changes

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-change`)
3. Commit your changes with clear messages
4. Push and open a Pull Request
5. Ensure Bicep validates: `az bicep build --file infra/main.bicep`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
