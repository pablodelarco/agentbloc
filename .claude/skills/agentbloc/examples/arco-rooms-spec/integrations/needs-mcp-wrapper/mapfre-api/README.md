# mapfre-api — NEEDS-MCP-WRAPPER

| Property | Value |
|---|---|
| Tool ID | `mapfre-api` |
| Vendor | Mapfre (Spanish insurance company) |
| Used by | gestor-documental |
| Tier | **NEEDS-MCP-WRAPPER** |
| Effort | 5 CC-hours |

## API source

| Property | Value |
|---|---|
| Vendor docs | https://www.mapfre.es/empresas/oficina-directa/api/ |
| OpenAPI spec | None published; structured docs available at vendor portal |
| Auth pattern | api-key (Bearer header) |
| Public MCP search | No public MCP found as of 2026-04-28 |

## Why a wrapper

Mapfre publishes a documented REST API for property insurance
policies + claims. No public MCP exists. Wrapper synthesis via
`mcp-builder` is the right path: ~5 CC-hours buys us a stable,
least-privilege surface that gestor-documental can use to fetch
monthly insurance invoices without portal-scraping.

(This is one of the few cases where a vendor API is more reliable
than browser automation — Mapfre's portal has aggressive bot
detection on Spanish IP ranges.)

## Wrapper scope (least-privilege)

Read-only:
- `get_policy(policy_id)` — fetch policy details + monthly invoice URL
- `list_claims()` — list current claims (rarely used; informational)

NO write endpoints. Full subset in [`ENDPOINTS.md`](ENDPOINTS.md).

## Build steps

See [`BUILD.md`](BUILD.md).

## Files in this folder

| File | Purpose |
|---|---|
| `README.md` | This file |
| `BUILD.md` | Build instructions |
| `ENDPOINTS.md` | Endpoint subset + auth |

## Cross-references

- Inventory: [`../../INVENTORY.md`](../../INVENTORY.md)
- Phase 3 synthesis protocol: `references/mcp-synthesis.md`
