# bank-mcp — NEEDS-MCP-WRAPPER

| Property | Value |
|---|---|
| Tool ID | `bank-mcp` |
| Vendor | 4 Spanish banks via PSD2 (BBVA, Santander, CaixaBank, Unicaja) |
| Used by | gestor-cobros |
| Tier | **NEEDS-MCP-WRAPPER** |
| Effort | 6 CC-hours |

## API source

| Property | Value |
|---|---|
| Vendor docs | https://www.bbva.es/clientes/particulares/banca-electronica/api-de-datos.html (BBVA exemplar; other banks expose equivalent PSD2 endpoints under EU directive 2015/2366) |
| OpenAPI spec | None published; PSD2 endpoints follow Berlin Group NextGenPSD2 standard |
| Auth pattern | OAuth (PSD2 SCA + 90-day consent) |
| Public MCP search | No public MCP found as of 2026-04-28; community implementations exist (e.g., elcukro/bank-mcp via Plaid/Enable Banking) but none cover the exact 4 Spanish banks needed; a custom wrapper is more reliable |

## Why a wrapper

PSD2 is a regulated standard. The 4 Spanish banks expose conforming
endpoints, but each bank has small differences in OAuth flows, scope
strings, and transaction payload shapes. A purpose-built wrapper
covering only the read endpoints (list_transactions, get_balance) is
~6 CC-hours and gives the team a stable, least-privilege surface.

Alternative: use Plaid (US-focused, EU coverage limited) or Enable
Banking (EU PSD2 aggregator, paid API). The custom wrapper is cheaper
for one team's scale and gives full control.

## Wrapper scope (least-privilege)

The wrapper exposes ONLY:
- `list_transactions(bank_id, account_id, date_from, date_to)`
- `get_balance(bank_id, account_id)`

NO write endpoints (initiate_payment, transfer, modify). Read-only
PSD2 access aligns with gestor-cobros' L2 envelope.

Full endpoint subset documented in [`ENDPOINTS.md`](ENDPOINTS.md).

## Build steps

See [`BUILD.md`](BUILD.md) for the step-by-step `/mcp-build` invocation,
env vars, smoke test per bank, and `.mcp.json` registration.

## Files in this folder

| File | Purpose |
|---|---|
| `README.md` | This file — orientation + tier rationale |
| `BUILD.md` | Step-by-step build instructions |
| `ENDPOINTS.md` | Minimum-viable endpoint subset + excluded surface |

(No `openapi.yaml` because no published OpenAPI spec — the build
session synthesizes from PSD2 Berlin Group docs.)

## Cross-references

- Inventory: [`../../INVENTORY.md`](../../INVENTORY.md)
- Phase 3 synthesis protocol: `references/mcp-synthesis.md`
- `mcp-builder` skill: separate Claude Code skill (read its SKILL.md)
- Credentials: `governance/audit-trail.md` + `.env.example`
