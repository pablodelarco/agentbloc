# Claude Code Project Context — Arco Rooms

> Claude-Code-specific entry point. For other AI coding tools, see
> `AGENTS.md` (universal). This file uses Claude Code vocabulary
> (skills, subagents, hooks) and references the bash reference impl
> directly.

## Project

Arco Rooms — 3-agent Property Management team that collects utility
invoices, matches PSD2 bank payments across 4 Spanish banks, and sends
per-owner Telegram summaries.

This project is the implementation of an AgentBloc-emitted spec folder.
You are the build session. AgentBloc was the architect. The spec
folder you're in tells you everything to build; you decide HOW to
implement it.

## Build approach

Read in order:
1. `ROADMAP.md` — phased build plan
2. `workflows/<id>.md` — what each workflow does
3. `agents/<id>/` — CrewAI-shaped agent designs
4. `integrations/INVENTORY.md` — tier-ranked tools
5. `governance/` — safety contracts
6. `runtime/BUILD.md` — runtime substrate build plan

## Conventions

### Subagents

Each agent in `agents/<id>/` may be implemented as a Claude Code
subagent in `.claude/agents/<id>.md`. The reference impl uses
`claude -p` invocations from `wake.sh` for per-cron firing — that's
the recommended path for `semi`/`supervised` agents that need approval
gating.

For `gestor-documental` (autonomy: full), a long-lived subagent or a
per-cron `claude -p` both work. For `gestor-cobros` (semi) and
`recepcionista` (semi, L4 send-external), use the per-cron pattern so
the autonomy-gate hook can intercept tool calls.

### Skills

For the 2 NEEDS-MCP-WRAPPER tools (bank-mcp + mapfre-api), invoke the
`mcp-builder` skill once per wrapper from a Claude Code session:

```
/mcp-build
```

Pass `integrations/needs-mcp-wrapper/<tool>/BUILD.md` as input. The
skill emits a single-file TypeScript MCP at `.mcp/generated/<tool>/`.

### Hooks

The reference impl ships `runtime/reference-impl/hooks/autonomy-gate.sh`
(PreToolUse blast-radius blocker). Register via
`.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "$REPO_ROOT/runtime/reference-impl/hooks/autonomy-gate.sh"}]}
    ]
  }
}
```

This hook blocks side-effect tools (L3+) when the agent's autonomy is
`semi`/`supervised` and there's no matching `/approve` record in
`.agentbloc/state/approvals.jsonl`.

### MCP servers

`integrations/existing/<tool>.md` lists the 6 already-deployed MCPs.
Install each + add to `.mcp.json`:

```json
{
  "mcpServers": {
    "playwright-mcp": { "command": "npx", "args": ["-y", "@playwright/mcp"] },
    "google-workspace-mcp": { "command": "...", "args": [...] }
  }
}
```

For the 2 wrapper tools, run `/mcp-build` per
`integrations/needs-mcp-wrapper/<tool>/BUILD.md`.

## Runtime — bash + cron + Telegram (default)

If you use the reference impl in `runtime/reference-impl/`:

1. `cp runtime/reference-impl/.env.example .env` and fill in:
   - `TELEGRAM_BOT_TOKEN` (create bot via @BotFather)
   - `TELEGRAM_APPROVAL_THREAD_ID`, `TELEGRAM_BRIEFING_THREAD_ID`,
     `TELEGRAM_ESCALATIONS_THREAD_ID`
   - `ANTHROPIC_API_KEY`
   - `BBVA_PSD2_CLIENT_ID`, `BBVA_PSD2_CLIENT_SECRET` (per
     integrations/needs-mcp-wrapper/bank-mcp/)
   - `MAPFRE_API_KEY`
   - Google Workspace OAuth refresh token
2. `./runtime/reference-impl/cron-generator.sh apply` to install
   crontab (or set `AGENTBLOC_NO_CRON=1` and use
   `./runtime/reference-impl/loop.sh` for foreground operation)
3. The cron lines fire `wake.sh <agent-id>` per agent's schedule;
   `claude-wrap.sh` invokes `claude -p` with the agent's `wake.md`

Cron schedule for this team:
- `0 22 * * *` → wake `gestor-documental`
- `30 22 * * *` → wake `gestor-cobros`
- `0 23 * * *` → wake `recepcionista`

If you pick a different runtime (n8n, Temporal, Pipedream, Inngest,
custom Python), see `runtime/alternatives.md` for tradeoffs and adapt
the contract from the bash impl.

## Testing

Each workflow in `workflows/<id>.md` ships falsifiable success
criteria. Implement them as integration tests against your runtime of
choice.

`governance/audit-trail.md` defines the 12-field JSONL schema your
audit implementation must match — assert on shape in tests.

## Provenance

Spec emitted by AgentBloc v1.0.0 on 2026-04-28. Input SHA256s in
`SPEC-EMISSION-REPORT.md`.

If you need to evolve this spec (requirements changed, tool
deprecated, new agent role), rerun AgentBloc on this folder. It reads
existing spec as ground truth and emits a diff in
`SPEC-EMISSION-REPORT.md` Revision History.
