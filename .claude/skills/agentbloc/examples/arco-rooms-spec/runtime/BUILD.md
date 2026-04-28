# Build Plan — Runtime Substrate for Arco Rooms

> Tool-agnostic build plan. Default: bash + cron + Telegram per
> `reference-impl/`. Alternatives: see `alternatives.md`.

## What the runtime does

1. Wakes each agent on its trigger (cron / inter-agent inbox)
2. Loads agent state, env, prompt
3. Invokes the agent's reasoning loop (`claude -p` with wake prompt)
4. Enforces governance gates (kill switch, blast-radius approvals)
5. Logs all activity to the audit trail
6. Persists agent state across wakes

These are CONTRACTS, not implementations. Any runtime that honors the
contracts works.

## Default: bash + cron + Telegram (reference-impl/)

The `reference-impl/` folder ships a complete bash implementation
adapted from the v2.5-runtime branch. Use it as-is for fastest path
to working, or reference it while building a different runtime.

### Build steps

1. **Copy `.env.example` to `.env`** and populate per `CLAUDE.md`:

   - `TELEGRAM_BOT_TOKEN` (create bot via @BotFather)
   - `TELEGRAM_APPROVAL_THREAD_ID`, `TELEGRAM_BRIEFING_THREAD_ID`,
     `TELEGRAM_ESCALATIONS_THREAD_ID`, `TELEGRAM_AUTHORIZED_USERS`
   - `ANTHROPIC_API_KEY`
   - Per-bank PSD2 credentials (see
     `../integrations/needs-mcp-wrapper/bank-mcp/BUILD.md`)
   - `MAPFRE_API_KEY` (see
     `../integrations/needs-mcp-wrapper/mapfre-api/BUILD.md`)
   - `GOOGLE_REFRESH_TOKEN`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
   - Per-utility-provider credentials: `ENDESA_USER`, `ENDESA_PASS`,
     `AGUAS_USER`, `AGUAS_PASS`, `NATURGY_USER`, `NATURGY_PASS`,
     `MOVISTAR_USER`, `MOVISTAR_PASS`, `URBASER_USER`, `URBASER_PASS`

2. **Install MCP servers** per
   `../integrations/existing/<tool>.md` files (6 EXISTS-MCP).

3. **Build wrappers** per
   `../integrations/needs-mcp-wrapper/<tool>/BUILD.md` files:
   - `/mcp-build` for `bank-mcp` (~6 CC-hours, covers 4 banks)
   - `/mcp-build` for `mapfre-api` (~5 CC-hours)

4. **Initialize agent state directories**:

   ```bash
   for agent in gestor-documental gestor-cobros recepcionista; do
     mkdir -p ".agentbloc/agents/$agent/inbox"
   done
   mkdir -p ".agentbloc/state" ".agentbloc/logs"
   ```

5. **Smoke test each agent** by manual wake:

   ```bash
   AGENTBLOC_NO_CRON=1 ./reference-impl/wake.sh gestor-documental manual-test
   ```

   Verify audit log entries appear in `.agentbloc/logs/<today>/audit.jsonl`.

6. **Install crontab**:

   ```bash
   ./reference-impl/cron-generator.sh apply
   ```

   Installs three cron lines:
   - `0 22 * * *` → wake gestor-documental
   - `30 22 * * *` → wake gestor-cobros
   - `0 23 * * *` → wake recepcionista

7. **Verify** by waiting one cron interval and inspecting logs.

8. **Wire kill switch** per `../governance/kill-switch.md`:
   - Touch test: `touch .agentbloc/KILL_SWITCH`; trigger any wake;
     confirm silent exit
   - Recovery test: `rm .agentbloc/KILL_SWITCH`; manual wake; confirm
     normal operation
   - Telegram test: send `/halt-all kill-test` from authorized user;
     verify file flag created; send `/resume-all`; verify cleared

## Effort estimate

| Component | Effort |
|---|---|
| Env + secrets setup | 1 CC-hour |
| 6 EXISTS-MCP installs | 12 CC-hours (2h × 6) |
| 2 NEEDS-MCP-WRAPPER builds | 11 CC-hours (6h bank-mcp + 5h mapfre-api) |
| Cron + smoke tests | 1.5 CC-hours |
| Governance wiring | 1.5 CC-hours |
| **Total** | **~27 CC-hours** |

(The ~21h estimate in `../ROADMAP.md` excludes Phase 1.1 OAuth dance
overhead and assumes parallel execution of independent steps.)

## When to deviate from reference-impl

See `alternatives.md` for the 8 documented runtime profiles. Pick
based on:

- Self-hosted VPS + cost-conscious → reference-impl (default)
- Visual flow ergonomics for non-technical operator → n8n self-hosted
- Event-driven heavy + serverless → Pipedream
- Long-running workflows + retry-heavy → Temporal or Inngest
- Python-native team → custom Python (APScheduler + FastAPI)

The CONTRACTS in `../governance/` stay constant regardless of runtime.

## Verification checklist

The team is "built" when ALL pass:

- [ ] Every agent wakes on trigger, exits cleanly
- [ ] L4 send-external (recepcionista) triggers Telegram approval
- [ ] `/approve` unblocks; `/deny` blocks
- [ ] Approval timeout escalates per tier ladder
- [ ] Kill switch (file + env + Telegram) all halt within 1 cron tick
- [ ] Audit logs append-only, redacted per `pii-redaction.md`,
      schema-conformant per `audit-trail.md`
- [ ] PII redaction passes test fixtures (Spain DNI/NIE)
- [ ] Each workflow's success criteria met by end-to-end run

## Cross-references

- Reference impl files: `reference-impl/`
- Other runtime options: `alternatives.md`
- Per-agent designs: `../agents/`
- Tool inventory: `../integrations/INVENTORY.md`
- Governance contracts: `../governance/`
