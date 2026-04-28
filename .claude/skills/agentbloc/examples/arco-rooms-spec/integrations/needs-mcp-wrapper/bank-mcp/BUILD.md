# Build Instructions — bank-mcp Wrapper

> Synthesizes a PSD2-compliant MCP wrapper for 4 Spanish banks (BBVA,
> Santander, CaixaBank, Unicaja) covering read-only transaction +
> balance endpoints.

## Prerequisites

- `mcp-builder` skill installed (Claude Code) OR equivalent generator
- Bun ≥ 1.1 OR Node ≥ 20
- Per-bank PSD2 developer accounts (free; register at each bank's
  developer portal)

## Steps

### 1. Register PSD2 apps (4 banks, ~30 min each)

For each bank, register a TPP (Third-Party Provider) account:

| Bank | Developer portal |
|---|---|
| BBVA | https://www.bbva.com/api_market/ |
| Santander | https://developer.santander.com/ |
| CaixaBank | https://www.caixabankdevelopers.com/ |
| Unicaja | https://api.unicajabanco.es/ |

Each gives you a `CLIENT_ID` and `CLIENT_SECRET`. Store in `.env`:

```
BBVA_PSD2_CLIENT_ID=...
BBVA_PSD2_CLIENT_SECRET=...
SANTANDER_PSD2_CLIENT_ID=...
SANTANDER_PSD2_CLIENT_SECRET=...
CAIXABANK_PSD2_CLIENT_ID=...
CAIXABANK_PSD2_CLIENT_SECRET=...
UNICAJA_PSD2_CLIENT_ID=...
UNICAJA_PSD2_CLIENT_SECRET=...
```

### 2. Initial SCA consent flow (~15 min per bank)

PSD2 mandates Strong Customer Authentication for AIS (Account
Information Service) consent. Each bank's portal has a sandbox flow;
you complete it once per bank to get a 90-day consent token. Store as
`<BANK>_PSD2_CONSENT_TOKEN`.

### 3. Invoke mcp-builder

From a Claude Code session in the spec folder root:

```
/mcp-build
```

Pass:
- Tool ID: `bank-mcp`
- Source: PSD2 Berlin Group NextGenPSD2 spec (no inline OpenAPI;
  `mcp-builder` synthesizes from the spec doc URL or hand-curated
  endpoints.json)
- Endpoint subset: see `ENDPOINTS.md` Included section (only
  `GET /v1/accounts/{accountId}/transactions` and
  `GET /v1/accounts/{accountId}/balances`)
- Output: `.mcp/generated/bank-mcp/`

The skill produces `index.ts` + `package.json` + `README.md` under
`.mcp/generated/bank-mcp/`. The wrapper handles per-bank URL routing
based on `bank_id` parameter.

### 4. Smoke test (per bank)

```bash
bun run .mcp/generated/bank-mcp/index.ts
```

Send a `tools/list` request via MCP harness. Expected: server declares
`list_transactions` + `get_balance` tools.

For each bank, exercise `list_transactions` with a 24-hour window.
Verify response shape matches `governance/audit-trail.md` expectations
for downstream consumption by gestor-cobros.

### 5. Register with Claude Code

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "bank-mcp": {
      "command": "bun",
      "args": ["run", ".mcp/generated/bank-mcp/index.ts"],
      "env": {
        "BBVA_PSD2_CLIENT_ID": "${env:BBVA_PSD2_CLIENT_ID}",
        "BBVA_PSD2_CLIENT_SECRET": "${env:BBVA_PSD2_CLIENT_SECRET}",
        "BBVA_PSD2_CONSENT_TOKEN": "${env:BBVA_PSD2_CONSENT_TOKEN}",
        "SANTANDER_PSD2_CLIENT_ID": "${env:SANTANDER_PSD2_CLIENT_ID}",
        "SANTANDER_PSD2_CLIENT_SECRET": "${env:SANTANDER_PSD2_CLIENT_SECRET}",
        "SANTANDER_PSD2_CONSENT_TOKEN": "${env:SANTANDER_PSD2_CONSENT_TOKEN}",
        "CAIXABANK_PSD2_CLIENT_ID": "${env:CAIXABANK_PSD2_CLIENT_ID}",
        "CAIXABANK_PSD2_CLIENT_SECRET": "${env:CAIXABANK_PSD2_CLIENT_SECRET}",
        "CAIXABANK_PSD2_CONSENT_TOKEN": "${env:CAIXABANK_PSD2_CONSENT_TOKEN}",
        "UNICAJA_PSD2_CLIENT_ID": "${env:UNICAJA_PSD2_CLIENT_ID}",
        "UNICAJA_PSD2_CLIENT_SECRET": "${env:UNICAJA_PSD2_CLIENT_SECRET}",
        "UNICAJA_PSD2_CONSENT_TOKEN": "${env:UNICAJA_PSD2_CONSENT_TOKEN}"
      }
    }
  }
}
```

Restart Claude Code so the MCP picks up.

### 6. Verify from agent's wake.md

Reference the MCP tools by their generated names in
`agents/gestor-cobros/tools.md`. Tool names follow the convention
`mcp__bank-mcp__list_transactions` and `mcp__bank-mcp__get_balance`.

### 7. Add to INVENTORY.md evidence

Once smoke tests pass, edit `integrations/INVENTORY.md` to record the
build outcome: install path, generated tools count, smoke-test date.

## Failure modes

| Mode | Likely cause | Fix |
|---|---|---|
| `mcp-builder` rejects spec | PSD2 endpoints differ per bank | Use Berlin Group standard; per-bank shim layer in wrapper |
| Auth failure (401) | Consent token expired (90-day rotation) | Re-run SCA consent flow at the bank's portal |
| Per-bank SCA differences | Some banks require redirect-flow, others embedded | Document per-bank in BUILD.md; wrapper handles dispatch |
| Rate limit (429) | PSD2 has per-TPP limits (typically 4 calls/account/day for free tier) | Cache aggressively in wrapper; respect Retry-After |

## Effort estimate

6 CC-hours: 4h to synthesize + smoke test, 2h for SCA consent
ceremony across 4 banks. Per `integrations/INVENTORY.md`.

## Cross-references

- `README.md` — tier rationale
- `ENDPOINTS.md` — endpoint subset
- `references/mcp-synthesis.md` — synthesis protocol
- `governance/blast-radius.md` — write-endpoint approval gating
- `governance/audit-trail.md` — PSD2 GDPR Article 30 logging
