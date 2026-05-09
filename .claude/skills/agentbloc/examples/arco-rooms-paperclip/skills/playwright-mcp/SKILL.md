---
name: playwright-mcp
description: Browser automation via accessibility snapshots; used for Endesa, Aguas de Almeria, Naturgy, Movistar, and Urbaser portal scraping
allowed-tools:
  - browser_navigate
  - browser_snapshot
  - browser_click
  - browser_type
  - browser_wait_for
  - browser_press_key
metadata:
  sources:
    - kind: github-repo
      repo: microsoft/playwright-mcp
      url: https://github.com/microsoft/playwright-mcp
      commit: cited 2026-04-28; pin to current main HEAD or pinned release at install time
      attribution: Microsoft
      license: Apache-2.0
      usage: referenced
  agentbloc:
    tier: EXISTS-MCP
    trust_tier: HIGH
    publisher: microsoft
    last_commit: "2026-04-02"
    cited_at: "2026-04-28T14:00:00Z"
    estimated_effort_cc_hours: 2
    used_by:
      - gestor-documental
    mcp_server:
      package: "@playwright/mcp"
      version: "0.0.28"
      installed_via: ".mcp.json existing"
      tools_declared:
        - browser_navigate
        - browser_snapshot
        - browser_click
        - browser_type
      required_scopes: []
      healthcheck_at: "2026-04-28T14:00:00Z"
    status: verified
---

# playwright-mcp

Browser automation via accessibility snapshots. Used by gestor-documental to log into 5 utility provider portals (Endesa, Aguas de Almería, Naturgy, Movistar, Urbaser) and download invoice PDFs.

## Why this MCP

The 5 utility provider portals don't expose APIs. Three options:

1. **Reverse-engineer their internal APIs** (browser-discovery skill): high effort, fragile to portal changes, legally gray
2. **Email scraping only**: misses providers that don't email invoices
3. **Browser automation**: works on every portal, accessibility snapshots are reliable, vendor-maintained MCP exists

Option 3 wins for cost and stability. Microsoft maintains the official MCP; accessibility snapshots are 4x more token-efficient than vision-based screenshot approaches.

## Install

This skill assumes the MCP is registered in your `.mcp.json`. If not:

```json
{
  "mcpServers": {
    "playwright-mcp": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

No environment variables required. The MCP launches Chromium in headless mode by default; for the 5 utility portals the team uses head-on mode for the first run (interactive login + cookie persistence) then headless for subsequent runs.

## Cookie persistence

Each provider login uses 2FA / OTP for the first session. The MCP stores cookies under `~/.cache/playwright-mcp/`. After the first interactive login (Pablo runs once with `PLAYWRIGHT_HEADLESS=false`), subsequent cron runs reuse the cookies until the provider invalidates them (varies by provider; Endesa rotates monthly).

When cookies expire, the agent's portal sweep returns 401-equivalent failures; gestor-documental's escalation logic catches this and sends a Telegram alert to Pablo: "Endesa cookies expired, please re-authenticate."

## Provenance

Cited at `2026-04-28T14:00:00Z` against last commit `2026-04-02`. Trust tier `HIGH` per AgentBloc's MCP ecosystem registry: official Microsoft maintenance, weekly releases, large user base. Re-pin to a specific commit via `metadata.sources[0].commit` at install time for forensic auditability.

## Cross-references

- Used by: [`../../agents/gestor-documental/AGENTS.md`](../../agents/gestor-documental/AGENTS.md)
- Upstream: https://github.com/microsoft/playwright-mcp
- AgentBloc tier classification: EXISTS-MCP (`metadata.agentbloc.tier`)
