# Build Instructions — mapfre-api Wrapper

## Prerequisites

- `mcp-builder` skill installed
- Bun ≥ 1.1 OR Node ≥ 20
- Mapfre API key (request at https://www.mapfre.es/empresas/oficina-directa/api/)

## Steps

### 1. Register for API access

Visit Mapfre's empresas portal, register a business account, and
request API access for your policies. They issue an API key valid
1 year (renewable). Store as `MAPFRE_API_KEY` in `.env`.

### 2. Invoke mcp-builder

```
/mcp-build
```

Pass:
- Tool ID: `mapfre-api`
- Source: hand-curated `endpoints.json` derived from vendor docs
  (no published OpenAPI; build session creates the JSON from docs)
- Endpoint subset: see `ENDPOINTS.md` Included
- Output: `.mcp/generated/mapfre-api/`

### 3. Smoke test

```bash
bun run .mcp/generated/mapfre-api/index.ts
```

Send `tools/list`. Expected: `get_policy` + `list_claims` declared.

Then call `get_policy` with a known policy_id from your account. Verify
response contains `monthly_invoice_url`.

### 4. Register with Claude Code

```json
{
  "mcpServers": {
    "mapfre-api": {
      "command": "bun",
      "args": ["run", ".mcp/generated/mapfre-api/index.ts"],
      "env": {
        "MAPFRE_API_KEY": "${env:MAPFRE_API_KEY}",
        "MAPFRE_API_BASE": "https://api.mapfre.es/v1"
      }
    }
  }
}
```

### 5. Wire to agent

Reference `mcp__mapfre-api__get_policy` in
`agents/gestor-documental/tools.md` and prompts.

## Failure modes

| Mode | Cause | Fix |
|---|---|---|
| Auth failure | API key expired (annual rotation) | Renew via Mapfre portal; update `.env` |
| Rate limit (429) | Per-account daily cap | Cache invoice URL; only fetch when policy ID changes |
| Policy not found (404) | Policy ID drift | Update tenant registry mapping |

## Effort

5 CC-hours: 3h synthesis + smoke test, 2h vendor portal admin (API
key request + docs synthesis to endpoints.json).
