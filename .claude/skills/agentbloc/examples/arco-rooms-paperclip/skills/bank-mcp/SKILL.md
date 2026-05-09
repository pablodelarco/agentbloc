---
name: bank-mcp
description: Read-only PSD2 access across BBVA, Santander, CaixaBank, and Unicaja for daily transaction reconciliation; wrapper not yet built
allowed-tools:
  - list_transactions
  - get_balance
metadata:
  agentbloc:
    tier: NEEDS-MCP-WRAPPER
    estimated_effort_cc_hours: 6
    used_by:
      - gestor-cobros
    wrapper:
      openapi_url: null
      vendor_docs_url: "https://www.bbva.es/clientes/particulares/banca-electronica/api-de-datos.html"
      auth_pattern: oauth
      endpoint_subset:
        - "GET /v1/transactions"
        - "GET /v1/balance"
      output_path: ".mcp/generated/bank-mcp/"
    cited_at: "2026-04-28T14:00:00Z"
    status: pending-build
    rationale: |
      PSD2 is a regulated standard. The 4 Spanish banks expose conforming endpoints, but each
      bank has small differences in OAuth flows, scope strings, and transaction payload shapes.
      A purpose-built wrapper covering only the read endpoints (list_transactions, get_balance)
      is ~6 CC-hours and gives the team a stable, least-privilege surface. No public MCP exists
      that covers the exact 4 Spanish banks needed; community alternatives (elcukro/bank-mcp via
      Plaid/Enable Banking) don't cover the specific Spanish PSD2 implementations.
---

# bank-mcp (NEEDS-MCP-WRAPPER, not yet built)

Read-only PSD2 transaction access across 4 Spanish banks: BBVA, Santander, CaixaBank, Unicaja. Used by gestor-cobros for daily transaction reconciliation against the day's invoices.

> **This skill is a build specification, not a runnable MCP.** The wrapper code does not exist yet. Before this skill can be invoked, a build session must run the `mcp-builder` skill against this specification. See "How to build this skill" below.

## Why a custom wrapper

Three options, in order of preference:

1. **Public MCP** (preferred): No public MCP covers the exact 4 Spanish banks at the verification date (2026-04-28). Community alternatives like elcukro/bank-mcp wrap Plaid / Enable Banking / Tink, but none expose direct BBVA / Santander / CaixaBank / Unicaja PSD2 endpoints.
2. **Aggregator service** (Plaid, Enable Banking, Tink): Adds cost (~€100/month for Enable Banking PSD2 coverage), latency (intermediate hop), and a vendor dependency. Plaid's Spanish coverage is partial; Enable Banking is the strongest aggregator for EU PSD2 but adds a paid layer.
3. **Custom wrapper** (this approach): ~6 CC-hours via the `mcp-builder` skill. Covers only what gestor-cobros needs. Least-privilege; no payment-initiation, no credential modification, no account deletion endpoints. Stable surface area regardless of which aggregator the team might switch to later.

The custom wrapper is the cheapest path for one team's scale and gives full control of the surface.

## How to build this skill

From a Claude Code session in the destination repo:

```
/mcp-build
```

When prompted, pass this path as the build spec:

```
skills/bank-mcp/SKILL.md
```

The `mcp-builder` skill will read the `metadata.agentbloc.wrapper` block above, plus the BBVA PSD2 vendor docs at `https://www.bbva.es/clientes/particulares/banca-electronica/api-de-datos.html` (other banks expose equivalent endpoints under EU directive 2015/2366), and synthesize:

- A single-file TypeScript MCP at `.mcp/generated/bank-mcp/index.ts`
- A `package.json` with the `@modelcontextprotocol/sdk` dependency
- A `README.md` documenting the OAuth flow per bank
- A `.env.example` listing the 8 required PSD2 secrets (`BBVA_PSD2_CLIENT_ID` + `_SECRET` per bank)

After the build session completes:

1. Register the wrapper in `.mcp.json`:

   ```json
   {
     "mcpServers": {
       "bank-mcp": {
         "command": "bun",
         "args": ["run", ".mcp/generated/bank-mcp/index.ts"]
       }
     }
   }
   ```

2. Run a smoke test per bank: `tools/list` should return the 2 endpoints (`list_transactions`, `get_balance`); a sample `list_transactions` call against a known date range should return non-empty results for at least one bank with valid credentials.

3. Update `metadata.agentbloc.status` in this SKILL.md from `pending-build` to `verified` once the smoke test passes.

## Endpoint surface (least-privilege)

The wrapper exposes ONLY these endpoints. The build session must reject any extension that adds write capability without an explicit governance review.

| Tool | Method | Purpose |
|---|---|---|
| `list_transactions(bank_id, account_id, date_from, date_to)` | GET /v1/transactions | Read transaction history for a date range |
| `get_balance(bank_id, account_id)` | GET /v1/balance | Read current balance for an account |

Explicitly **forbidden** in this wrapper:
- `initiate_payment` (PSD2 PISP scope; not granted to consent)
- `transfer` (write operation; not in scope)
- `modify_account` (account configuration; not in scope)
- Any endpoint requiring SCA strong-authentication beyond the 90-day consent renewal

This aligns with gestor-cobros' L2-write-internal blast radius: read external APIs, write only to local state.

## Auth pattern

OAuth (PSD2 SCA) per bank, with 90-day consent renewal. The wrapper handles:

- Initial consent flow (interactive; Pablo runs once per bank to grant 90 days of read access)
- Refresh token management (stored in `~/.cache/bank-mcp/<bank-id>.json`, gitignored)
- Consent expiry detection (401 from any endpoint triggers a re-auth alert via gestor-cobros' escalation path)

## Provenance

Tier classified `NEEDS-MCP-WRAPPER` at AgentBloc Phase 3 (cited `2026-04-28T14:00:00Z`). Build effort estimated at 6 CC-hours per the inventory protocol's per-tier band. Status `pending-build` until the `mcp-builder` skill produces a verified wrapper.

## Cross-references

- Used by: [`../../agents/gestor-cobros/AGENTS.md`](../../agents/gestor-cobros/AGENTS.md)
- Vendor docs: https://www.bbva.es/clientes/particulares/banca-electronica/api-de-datos.html (BBVA exemplar; Santander, CaixaBank, Unicaja expose equivalent endpoints)
- AgentBloc `mcp-builder` skill: invoked via `/mcp-build`
