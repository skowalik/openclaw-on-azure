# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do NOT** open a public GitHub issue for security vulnerabilities.
2. Email your findings to the repository maintainers.
3. Include a detailed description of the vulnerability and steps to reproduce.
4. Allow reasonable time for a fix before public disclosure.

## Security Design

This project follows security-first principles:

- **Managed Identity** — No API keys stored in config; Azure Managed Identity authenticates Container Apps to Key Vault and AI Foundry.
- **Key Vault** — All secrets (gateway tokens, channel tokens) stored in Azure Key Vault with RBAC access control.
- **Non-root container** — The OpenClaw container runs as the `node` user (uid 1000), not root.
- **HTTPS-only** — Azure Container Apps enforces HTTPS with auto-provisioned TLS certificates.
- **DM pairing** — OpenClaw's default `dmPolicy="pairing"` requires sender verification before processing messages.
- **Network isolation** — Container Apps ingress can be restricted to internal-only if needed.

## Dependencies

This project uses Azure Bicep templates for infrastructure. Keep the `openclaw` npm package updated to get the latest security patches:

```bash
npm update -g openclaw@latest
```
