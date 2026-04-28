# Arco Rooms Runtime Correlation Flow

> Canonical narrative fixture for Phase 13 runtime behavior. Walks through 3 scenarios demonstrating correlation-ID propagation, TeamCreate coordination, and kill-switch team-wide halt. This is the Phase 16 golden-file reference for the end-to-end runtime validation. Companion structural fixture: arco-rooms-runtime-artifacts.md (literal wake.md + crontab + n8n route .json + registry.yaml shapes).

## Context

Arco Rooms is a 3-agent rental property team designed in Phase 12 from the user's PDF brief. Three agents are requested in v1.0; two more anticipated in Phase 15. The trigger matrix per PDF page 3:

- **Gestor Cobros (Payment Reconciliation Engine):** monthly cron (1st 09:00 Europe/Madrid = 08:00 UTC Z) + Plaid `payment-received` webhook + inter-agent receiver (handles SendMessage from Recepcionista on tenant-inquiry workflows)
- **Recepcionista (Daily Operations Reporter):** Telegram `tenant-message` webhook + inter-agent receiver (team lead on dynamic spawn workflows)
- **Gestor Documental (Invoice Collection Specialist):** weekly cron (Monday 08:00 Europe/Madrid = 07:00 UTC Z) + Gmail `new-invoice-email` webhook

This fixture demonstrates how a single user-visible event walks through the full runtime: kill-switch gate, correlation-ID ingest, memory load, input parse, execution, and audit log emission. Every grep in the verification blocks below is reproducible against `.agentbloc/logs/audit.jsonl` and `.agentbloc/runtime/TEAM_SESSIONS.jsonl`.

Read order for the three scenarios is intentional: Scenario A establishes the simplest path (single-agent bypass with one log line); Scenario B introduces multi-agent coordination via TeamCreate + SendMessage with parent/child correlation IDs; Scenario C overlays the kill-switch on Scenario B's mid-execution state to demonstrate halt-and-dissolve semantics. A reader who only has time for one scenario should pick B, since it exercises the most contracts (envelope validation + idempotency + team spawn + child-ID propagation + clean dissolution).

### Scenario A: Cron wake of Gestor Cobros (single-agent bypass)

Setup: 1st of May 2026, 09:00 Europe/Madrid (= 08:00 UTC Z for CEST). System cron fires the crontab entry for Gestor Cobros. `registry.runtime.workflows.monthly-collections.agents` = `[gestor-cobros]` (length 1, single-agent bypass per D-76; no TeamCreate is issued).

Flow:

1. Cron entry triggers `AGENTBLOC_CORRELATION_ID=$(agentbloc-gen-correlation cron) claude -p .agentbloc/agents/gestor-cobros/wake-cron.md`
2. Correlation ID generated: `cron-20260501T080000Z-a3f21b`
3. wake-cron.md section 1: checks `.agentbloc/KILL_SWITCH`. Not present. Continues.
4. Section 2: ingests `AGENTBLOC_CORRELATION_ID=cron-20260501T080000Z-a3f21b` from env var.
5. Section 3: reads `memory.md` (tenant contracts, autonomy=semi conventions) + `state.json` (last month processed = `2026-04`, no pending retries).
6. Section 4: derives input from `state.working_state.month_to_process = "2026-05"`.
7. Section 5: loads `.claude/skills/gestor-cobros/SKILL.md`; executes per autonomy = semi; calls BBVA MCP to list transactions for 2026-05; reconciles against contract roster from memory.
8. Section 6: writes updated `state.json` (advances `month_to_process` to `2026-06`) + `last-run.json`; appends one log line:
   ```
   {"correlation_id":"cron-20260501T080000Z-a3f21b","agent_id":"gestor-cobros","event":"wake-completed","wake_outcome":"completed","timing_ms":4821,"trigger":"cron"}
   ```
9. Sends Telegram message to tenant thread with correlation ID in header for human grep:
   ```
   [id: cron-20260501T080000Z-a3f21b]
   Estimado inquilino, recordatorio de cuota de mayo.
   ```

Key observation: single-agent workflow takes the bypass path; no TeamCreate call; one log line, one correlation ID, end-to-end grep-traceable.

Grep verification:
```bash
grep '"correlation_id":"cron-20260501T080000Z-a3f21b"' .agentbloc/logs/audit.jsonl | wc -l
# 1   (one wake, one log entry; no team session, no inter-agent fan-out)
```

State diff before vs after the wake:
```diff
--- .agentbloc/agents/gestor-cobros/state.json (pre)
+++ .agentbloc/agents/gestor-cobros/state.json (post)
-  "month_to_process": "2026-05",
-  "last_run_at": "2026-04-01T08:00:00Z",
+  "month_to_process": "2026-06",
+  "last_run_at": "2026-05-01T08:00:04Z",
   "processed_ids": [..., "txn-2026-04-091"],
+  "processed_ids": [..., "txn-2026-04-091", "txn-2026-05-001", ..., "txn-2026-05-047"]
```

The state cursor advance (month_to_process → 2026-06) is the single side effect that prevents replay on the next monthly cron tick. Idempotency for cron is cursor-based (advance after success); idempotency for webhooks is processed_ids-based (Scenario B section 4 shows the natural-key check).

### Scenario B: Telegram tenant message wakes Recepcionista, TeamCreate with Gestor Cobros (multi-agent dynamic spawn)

Setup: tenant sends Telegram message "Cuando vence mi contrato?" at 14:32:12 UTC on 2026-05-04. n8n Telegram route fires the webhook. `registry.runtime.workflows.tenant-inquiry.agents` = `[recepcionista, gestor-cobros]` with `spawn_rule: dynamic`. Coordination preference = `claudeclaw` with `writeStateHandoff` fallback.

Flow:

1. n8n Telegram route seeds the D-74 envelope with `correlation_id: webhook-telegram-20260504T143212Z-c7d92a`, `agent_id: recepcionista`, `trigger.source: telegram`, `trigger.event_name: tenant-message`, payload carries `chat_id` + `sender` + `text`.
2. ClaudeClaw job endpoint reads envelope, invokes `claude -p --payload-file <path> .agentbloc/agents/recepcionista/wake-webhook-telegram-tenant-message.md`.
3. wake-webhook.md section 1: KILL_SWITCH not present. Continues.
4. Section 2: ingests `webhook-telegram-20260504T143212Z-c7d92a` from envelope top-level field.
5. Section 3: reads Recepcionista memory (tenant roster, contract expiry table) + state.json.
6. Section 4: validates envelope (schema_version=1, agent_id=recepcionista, source=telegram); parses payload; idempotency check on `message_id` passes (not in processed_ids[]).
7. Section 5: loads SKILL.md; the natural-language classifier detects "cuando vence mi contrato" needs contract expiry (own memory) + payment-status (dependency on gestor-cobros per `dependencies[]` in agent-profiles.yaml).
8. Recepcionista calls `TeamCreate([recepcionista, gestor-cobros], correlation_id=webhook-telegram-20260504T143212Z-c7d92a)`. Team ID assigned. TEAM_SESSIONS.jsonl entry: `{event: team-created, team_id: "T-9f82", agents: [recepcionista, gestor-cobros]}`.
9. Recepcionista sends `SendMessage(to: gestor-cobros, body: {type: payment-status-check, tenant_id: "T-042"}, metadata: { correlation_id: "webhook-telegram-20260504T143212Z-c7d92a-sub-001" })`.
10. Gestor Cobros wakes via wake-inter.md. Section 1: KILL_SWITCH not present. Section 2: ingests sub-001 child ID from metadata. Section 3: reads state. Section 4: dispatches on `message.type=payment-status-check`; validates `calling_agent_id=recepcionista` is in team roster.
11. Section 5: queries BBVA MCP for tenant T-042 payment history; detects no overdue balances; status=current.
12. Gestor Cobros sends `SendMessage(to: recepcionista, body: {type: payment-status-reply, status: "current", last_paid: "2026-05-01"}, metadata: { correlation_id: "webhook-telegram-20260504T143212Z-c7d92a-sub-001" })`.
13. Gestor Cobros log line:
    ```
    {"correlation_id":"webhook-telegram-20260504T143212Z-c7d92a-sub-001","agent_id":"gestor-cobros","event":"wake-completed","wake_outcome":"completed","timing_ms":1203,"trigger":"inter","calling_agent_id":"recepcionista"}
    ```
14. Recepcionista receives reply; drafts Telegram response combining contract expiry (from its own memory) + payment status (from reply). Sends Telegram message with correlation ID header.
15. Recepcionista log line; team dissolves with `team_dissolution_reason: all-members-returned`; TEAM_SESSIONS.jsonl entry appended.

Key observation: ONE user event maps to TWO agent wakes; SAME parent correlation ID `webhook-telegram-20260504T143212Z-c7d92a` grep-traces both; child ID `sub-001` distinguishes the Gestor Cobros sub-invocation.

Grep verification:
```bash
grep 'correlation_id":"webhook-telegram-20260504T143212Z-c7d92a' .agentbloc/logs/audit.jsonl
# Returns both agent log lines (Recepcionista parent + Gestor Cobros with sub-001 suffix)

# Reconstruct full timeline ordered by timing:
grep 'correlation_id":"webhook-telegram-20260504T143212Z-c7d92a' .agentbloc/logs/audit.jsonl | \
  jq -s 'sort_by(.timing_ms) | .[] | "\(.agent_id) \(.event) (\(.trigger))"'
# "recepcionista wake-completed (webhook-telegram)"
# "gestor-cobros  wake-completed (inter)"

# Cross-reference with team session events:
grep '"correlation_id":"webhook-telegram-20260504T143212Z-c7d92a"' .agentbloc/runtime/TEAM_SESSIONS.jsonl
# {team-created} ... {team-member-returned: gestor-cobros} ... {team-member-returned: recepcionista} ... {team-dissolved: all-members-returned}
```

The four-event TEAM_SESSIONS sequence (created -> member-returned x2 -> dissolved) is the canonical happy-path team trace. A clean dissolution requires every member to have logged a `team-member-returned` entry; absence of one indicates a hung agent that the team timeout (`registry.runtime.team_timeout_minutes`) will eventually evict.

### Scenario C: KILL_SWITCH fires mid-team, team dissolves cleanly

Setup: Scenario B is in progress at step 11 (Gestor Cobros about to query BBVA MCP). Operator notices unusual activity in the Telegram ops thread at 14:32:15 UTC and types `/stop`.

Flow:

1. n8n agentbloc-stop route fires on `/stop` message in the operator ops thread; runs `touch .agentbloc/KILL_SWITCH` via shell node.
2. Gestor Cobros at step 11 is executing the BBVA MCP call. The Phase 12 PreToolUse hook checks KILL_SWITCH before each tool call.
3. Phase 12 PreToolUse hook `.claude/hooks/kill-switch-check.sh` detects KILL_SWITCH; returns `permissionDecision: deny` for the BBVA MCP call. Gestor Cobros logs:
   ```
   {"correlation_id":"webhook-telegram-20260504T143212Z-c7d92a-sub-001","agent_id":"gestor-cobros","event":"tool-call-denied-kill-switch","wake_outcome":"halted-kill-switch","trigger":"inter"}
   ```
4. Gestor Cobros returns `{status: halted-kill-switch}` to Recepcionista via SendMessage. This SendMessage itself passes the D-77 enforcement point #3 team-transition check because the check gates OUTGOING new work, not error returns.
5. Recepcionista wake-inter.md section 5: re-checks KILL_SWITCH before issuing any outgoing SendMessage. KILL_SWITCH present. Emits `{status: halted-kill-switch}` back toward the team.
6. Team lead (Recepcionista per D-23 mesh/default for dynamic-spawn workflows) dissolves the team via TeamCreate teardown. TEAM_SESSIONS.jsonl entry:
   ```
   {"correlation_id":"webhook-telegram-20260504T143212Z-c7d92a","team_id":"T-9f82","event":"team-dissolved","team_dissolution_reason":"kill-switch","dissolved_at":"2026-05-04T14:32:16Z"}
   ```
7. No Telegram reply is sent to the tenant (KILL_SWITCH gates all outbound side effects). The conversation resumes when operator runs `/resume` (clears KILL_SWITCH via the sibling n8n route).

Key observation: KILL_SWITCH activation mid-team halts within one SendMessage round-trip (typically under 5 seconds). `team_dissolution_reason: kill-switch` is logged with the shared correlation ID, so forensics can reconstruct the exact chain end-to-end. The D-77 three-point enforcement (wake + tool + team-transition) covers all three latency windows.

Grep verification:
```bash
grep '"correlation_id":"webhook-telegram-20260504T143212Z-c7d92a"' .agentbloc/runtime/TEAM_SESSIONS.jsonl | jq '.team_dissolution_reason'
# "kill-switch"
```

Operator recovery walkthrough:

1. Operator confirms in the ops thread that the alert was a false positive (or that the underlying issue is resolved). They type `/resume` in the same Telegram ops thread.
2. n8n agentbloc-resume route fires; runs `rm -f .agentbloc/KILL_SWITCH` via shell node.
3. The next scheduled cron tick or webhook will find KILL_SWITCH absent and proceed normally. There is no auto-replay of halted teams; the tenant in Scenario B will need to re-send their Telegram message (or an operator can manually invoke recepcionista with the original payload).
4. Forensic post-mortem: an operator searches by correlation ID across both log streams, reconstructing the full event chain end-to-end (wake start, halted-kill-switch event, dissolution reason, recovery time). The grep recipe `grep -r '<correlation-id>' .agentbloc/logs/ .agentbloc/runtime/` returns every artifact touched by the halted run.

### Cross-Scenario Summary

| Scenario | Trigger | Wakes | Correlation ID(s) | TeamCreate? | Outcome | Log Lines |
|----------|---------|-------|-------------------|-------------|---------|-----------|
| A | cron (monthly) | 1 (gestor-cobros) | cron-...-a3f21b | no (single-agent bypass) | completed | 1 |
| B | webhook (telegram) | 2 (recepcionista, gestor-cobros) | webhook-telegram-...-c7d92a + sub-001 | yes (dynamic spawn) | completed | 2 + 4 team session events |
| C | webhook + kill-switch | 2 (halted) | webhook-telegram-...-c7d92a + sub-001 | yes, then dissolved | halted-kill-switch | 2 wake-related + tool-call-denied + team-dissolved |

The three scenarios collectively exercise: every wake template (cron + webhook + inter), the single-agent bypass + multi-agent fan-out paths, parent + child correlation IDs, and all four `wake_outcome` enum values that appear under nominal operation (`completed`, `halted-kill-switch`; `failed` and `halted-upstream-failure` are exercised in Phase 16 fault-injection tests).

### Note on Gestor Documental

Gestor Documental does not appear in the active flows above; its two trigger paths follow shapes already covered:

- **Weekly cron (Monday 08:00 Europe/Madrid = 07:00 UTC):** structurally identical to Scenario A (single-agent bypass, cron correlation ID `cron-<UTC-Z-compact>-<nonce>`, no TeamCreate). State cursor advances by week instead of month: `state.working_state.week_to_process = "2026-W18"`.
- **Gmail `new-invoice-email` webhook:** structurally identical to the webhook path inside Scenario B (envelope validation + idempotency on `message_id` natural key) but `registry.runtime.workflows.gmail-invoice-received.agents = [gestor-documental]` is length-1, so the single-agent bypass applies (no TeamCreate, no inter-wake).

The structural companion fixture (`arco-rooms-runtime-artifacts.md`) contains the literal `wake-cron.md`, `wake-webhook-gmail-new-invoice-email.md`, and crontab entry for completeness.

### Common Failure Modes

The three nominal scenarios above are the happy paths. The table below catalogs the most common deviations encountered during Phase 13 dogfooding and during early Phase 16 fault-injection runs. Each row maps a user-visible symptom to its probable cause and the remediation step a Phase 14 dashboard agent (or a human operator) would take.

| Symptom | Likely Cause | Remediation |
|---------|--------------|-------------|
| Two log lines with `correlation_id_source: self-generated` for the same wake | n8n route did not seed the envelope correlation_id (route file outdated or schema_version mismatch) | Re-publish the n8n route file from `.agentbloc/runtime/n8n-routes/` |
| `team-dissolved` event missing for an active correlation_id | Team timed out (`registry.runtime.team_timeout_minutes` exceeded) before all members returned | Inspect `team_dissolution_reason: timeout`; check the slowest member's last log line for hung tool call |
| `inter-message-unknown-type` log entry | Calling agent sent a message type the receiver does not handle (SKILL.md handler table mismatch with sender) | Update receiver's SKILL.md to declare the type, or update sender to use a known type |
| Webhook fires but no wake.md log appears | KILL_SWITCH active, OR webhook envelope failed schema validation (event: `malformed-envelope`) | grep audit.jsonl for `event: halted-kill-switch` or `event: malformed-envelope` with the trigger correlation_id |

### Cross-References

- `.claude/skills/agentbloc/references/correlation-id.md` (format spec + grep recipes)
- `.claude/skills/agentbloc/references/n8n-integration.md` (envelope schema + Telegram worked example)
- `.claude/skills/agentbloc/references/runtime-coordination.md` (TeamCreate/SendMessage contract + dissolution semantics)
- `.claude/skills/agentbloc/references/incident-response.md` (KILL_SWITCH + three-point enforcement)
- `.claude/skills/agentbloc/examples/arco-rooms-runtime-artifacts.md` (companion structural fixture: literal wake.md + crontab + n8n route .json + registry.yaml shapes)
- `.planning/phases/13-multi-agent-runtime/13-CONTEXT.md` (decisions D-73 through D-79 documented in full)

### Phase 16 Golden-File Discipline

This fixture is byte-stable. Phase 16 validation diffs the live audit.jsonl + TEAM_SESSIONS.jsonl produced by a real agent run against the literal blocks above. Any drift in correlation-ID format, log key set, wake_outcome enum, or scenario step ordering is a regression. Updates to this fixture require a coordinated change to wake-job templates + runtime-engine + the Phase 16 diff harness.
