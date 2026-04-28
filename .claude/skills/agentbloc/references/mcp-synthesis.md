# MCP Synthesis — Designing Wrappers from Raw APIs

> Loaded by SKILL.md and the `browser-discovery` subagent during Phase 3
> when a tool is assigned tier `NEEDS-MCP-WRAPPER`. Defines what the
> spec folder must contain so a build session can run `mcp-builder` to
> produce the wrapper.

## Table of Contents

- [When This Applies](#when-this-applies)
- [What the Spec Folder Must Contain](#what-the-spec-folder-must-contain)
- [The Minimum-Viable Endpoints Rule](#the-minimum-viable-endpoints-rule)
- [`BUILD.md` Template](#buildmd-template)
- [`ENDPOINTS.md` Template](#endpointsmd-template)
- [Authentication Strategy](#authentication-strategy)
- [Cross-References](#cross-references)

## When This Applies

A tool received tier `NEEDS-MCP-WRAPPER` from
[inventory-protocol.md](inventory-protocol.md):
- Vendor publishes a documented public API
- No public MCP server exists (or the existing one is stale / unmaintained)
- Wrapper is buildable via the `mcp-builder` skill (which reads OpenAPI
  specs and generates a single-file TypeScript MCP server using the
  Anthropic SDK + Bun)

## What the Spec Folder Must Contain

For each `NEEDS-MCP-WRAPPER` tool, `spec-engine` writes:

```
integrations/needs-mcp-wrapper/<tool>/
├── README.md              # Why this tier; what the wrapper will do
├── BUILD.md               # Step-by-step instructions for the build session
├── ENDPOINTS.md           # Minimum-viable endpoint subset with rationale
└── openapi.yaml           # OpenAPI source (if available) — input to mcp-builder
```

If the vendor doesn't publish an OpenAPI spec but does publish API docs,
include a hand-summarized `endpoints.json` (subset) instead of `openapi.yaml`,
and document in `BUILD.md` that the build session may need to expand it.

## The Minimum-Viable Endpoints Rule

The wrapper exposes ONLY the endpoints the team's agents actually need.
This is least-privilege: an agent that reads pages should not be wired
to an MCP that can also delete pages.

Phase 3 derives the endpoint subset from `agent-profiles.yaml`:

1. For each agent, list the operations it performs against the tool
2. Map operations to the tool's API endpoints
3. Group endpoints by HTTP verb + scope (read / write / admin)
4. Drop endpoints not in the agent's scope
5. Document the dropped surface in `ENDPOINTS.md` "Excluded" section

Typical wrapper exposes 3-8 endpoints. More than that → consider
splitting the agent or revisiting whether NEEDS-MCP-WRAPPER is the
right tier.

## `BUILD.md` Template

`spec-engine` writes this file from a template; the build session
follows it step by step.

```markdown
# Build Instructions — <tool> MCP Wrapper

This wrapper was specified by AgentBloc Phase 3. The build session
(Claude Code, Codex, Gemini, Cursor, OpenClaw) executes these steps to
produce a runnable MCP server.

## Prerequisites

- `mcp-builder` skill installed (Claude Code) OR equivalent generator
  in your AI coding tool
- Bun ≥ 1.1 OR Node ≥ 20
- An API key / OAuth token for <tool> (the user provides this; never
  commit it to git)

## Steps

1. **Invoke mcp-builder.** From a Claude Code session:
   ```
   /mcp-build
   ```
   Pass:
   - Tool ID: `<tool>`
   - Source: `./openapi.yaml` (in this folder)
   - Endpoint subset: see `ENDPOINTS.md`
   - Output: `.mcp/generated/<tool>/`

2. **Set environment variables.** The wrapper reads:
   - `<TOOL>_API_KEY` — primary credential
   - `<TOOL>_API_BASE` — optional override (default vendor URL)

3. **Smoke test.** Run the MCP locally and verify the endpoint subset
   responds:
   ```
   bun run .mcp/generated/<tool>/index.ts
   ```

4. **Register with Claude Code (or your AI tool).** Add to
   `.mcp.json`:
   ```json
   {
     "<tool>": {
       "command": "bun",
       "args": ["run", ".mcp/generated/<tool>/index.ts"],
       "env": { "<TOOL>_API_KEY": "${env:<TOOL>_API_KEY}" }
     }
   }
   ```

5. **Verify from your agent's wake.md.** Reference the MCP tools by
   their generated names in the agent's `tools.md`.

## Failure modes

- **OpenAPI parse error:** mcp-builder rejected the spec. Check the
  spec validates with `swagger-cli validate openapi.yaml`. If invalid,
  fix and re-run.
- **Auth failure:** vendor's API rejected the token. Check token scope
  vs. the endpoint subset.
- **Rate limit:** vendor capped requests. Document in
  `governance/audit-trail.md` so future agents respect the limit.

## Effort estimate

<from inventory.yaml: estimated_effort_cc_hours>
```

## `ENDPOINTS.md` Template

```markdown
# Minimum-Viable Endpoints — <tool>

This subset is the only API surface the wrapper exposes. Agents that
need additional endpoints must amend this file and re-run mcp-builder.

## Included

| Endpoint | Method | Used by | Purpose |
|---|---|---|---|
| `/v1/foo` | GET | <agent-id> | List foo items |
| `/v1/foo/{id}` | GET | <agent-id> | Read one foo |
| `/v1/foo` | POST | <agent-id> | Create foo (subject to approval gate per blast-radius L3+) |

## Excluded (least-privilege)

The following endpoints exist in the vendor's API but are NOT in this
wrapper:

| Endpoint | Method | Reason for exclusion |
|---|---|---|
| `/v1/foo/{id}` | DELETE | No agent needs delete; high blast radius |
| `/v1/admin/*` | * | No agent needs admin; concentrating risk |

If a future agent needs an excluded endpoint, the team revisits
inventory-protocol.md Phase 3 and either expands this subset or
declines the agent's blast-radius escalation.

## Authentication

<one of: api-key | oauth | service-account>
<details: header name, scope requirements, refresh policy>

## Rate limits

<from vendor docs: per-second / per-day caps>
<governance/audit-trail.md should reflect this so the build session
implements appropriate retry-after handling>
```

## Authentication Strategy

The wrapper handles authentication via environment variables. Three
common patterns:

| Pattern | Wrapper holds | Build session step |
|---|---|---|
| API key | `<TOOL>_API_KEY` | Document where to obtain the key + scope to grant |
| OAuth | refresh token + client credentials | Document the OAuth dance + browser opt-in step |
| Service account | JSON credentials file path | Document service account creation + role assignment |

`BUILD.md` always includes the env-var names so the build session can
populate them. Never write tokens to git.

## Cross-References

- [inventory-protocol.md](inventory-protocol.md) — Q3 path that lands here
- [phase-3-integration.md](phase-3-integration.md) — orchestration
- `mcp-builder` skill — the actual generator (separate Claude Code skill)
- [credentials.md](credentials.md) — env var conventions
- [blast-radius.md](blast-radius.md) — endpoint inclusion gate
- [browser-fallback.md](browser-fallback.md) — when no API docs exist at all
