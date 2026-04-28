# playwright-mcp — EXISTS-MCP

| Property | Value |
|---|---|
| Tool ID | `playwright-mcp` |
| Vendor | Microsoft |
| Used by | gestor-documental |
| Tier | **EXISTS-MCP** |
| Effort | 2 CC-hours |

## MCP server

| Property | Value |
|---|---|
| Repo | https://github.com/microsoft/playwright-mcp |
| Publisher | microsoft (vendor-maintained) |
| Last commit | 2026-04-02 |
| Trust tier | HIGH |
| Install | `npx -y @playwright/mcp@0.0.28` |

## Why this MCP

Microsoft-maintained, vendor-grade. Accessibility-snapshot-based (not
vision-based), so token-efficient. Used for the 5 utility provider
portals (Endesa, Aguas de Almeria, Naturgy fallback, Movistar fallback,
Urbaser).

## Install

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "playwright-mcp": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.0.28"]
    }
  }
}
```

No env vars required for the MCP itself; provider credentials live in
the agent's prompts (loaded from `.env` `ENDESA_USER`, `ENDESA_PASS`,
etc.).

Smoke test: from a Claude Code session, invoke
`mcp__playwright-mcp__browser_navigate` with `https://example.com` and
verify response.

## Tools the agents use

| MCP tool | Used by | Operation | Blast |
|---|---|---|---|
| `browser_navigate` | gestor-documental | Go to provider login URL | L1 |
| `browser_type` | gestor-documental | Credential input | L2 |
| `browser_click` | gestor-documental | Submit + nav to invoices | L2 |
| `browser_snapshot` | gestor-documental | Accessibility tree extract | L1 |

## Authentication

N/A for the MCP. Provider credentials are managed by the agent prose.

## Rate limits

N/A (Playwright is local). Provider portals have their own per-IP
limits — agent runs at 22:00 nightly, well within typical limits.

## Known issues

None. Microsoft-maintained, accessibility-tree based, no vision model
required, no fingerprinting concerns when used for legitimate
account-holder access.

## Cross-references

- Inventory: [`../INVENTORY.md`](../INVENTORY.md)
- Phase 3 protocol: `references/mcp-integration-protocol.md`
- Trust tiers: `references/mcp-ecosystem-registry.md`
