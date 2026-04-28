# Arco Rooms Runtime Artifacts

> Companion structural fixture to arco-rooms-correlation-flow.md. Shows the literal file contents runtime-engine materializes for the Arco Rooms team: wake.md per trigger path, crontab.applied manifest, n8n route .json stubs, and the extended registry.yaml runtime block per D-78. Textual (not executable); for audit + Phase 16 golden-file comparison.

## Context

Arco Rooms team with 3 agents. Trigger matrix per PDF page 3:

- **Gestor Cobros:** 1 cron (monthly 1st 09:00 Europe/Madrid = 08:00 UTC) + 1 webhook (Plaid `payment-received`) + 1 inter (receives SendMessage from Recepcionista) -> 3 wake.md files
- **Recepcionista:** 1 webhook (Telegram `tenant-message`) + 1 inter (team lead on dynamic spawn workflows) -> 2 wake.md files
- **Gestor Documental:** 1 cron (weekly Monday 08:00 Europe/Madrid = 07:00 UTC) + 1 webhook (Gmail `new-invoice-email`) -> 2 wake.md files

Total: 7 wake.md files. Phase 13 runtime-engine materializes each deterministically from agent-profiles.yaml triggers[] + the 3 templates per D-73 Option D. For brevity this fixture shows 3 representative artifacts (one per template variant). The remaining 4 follow the same shape with anchor-point substitutions per their triggers.

## Wake.md Artifact 1 - Gestor Cobros cron wake

Path: `.agentbloc/agents/gestor-cobros/wake-cron.md`. Materialized post-substitution from wake-job-cron.md.tmpl with `{{agent.id}}=gestor-cobros`, `{{cron.schedule}}=0 8 1 * *`, `{{agent.skill_path}}=.claude/skills/gestor-cobros/SKILL.md`, `{{agent.memory_dir}}=.agentbloc/agents/gestor-cobros/`, `{{agent.autonomy}}=semi`.

```
# Wake Job: gestor-cobros (cron)
You are waking to execute Payment Reconciliation Engine per the cron schedule `0 8 1 * *`.
## 1. Kill-switch pre-check
Check `.agentbloc/KILL_SWITCH`. If YES: append halted-kill-switch entry with trigger=cron; EXIT IMMEDIATELY.
## 2. Correlation-ID ingest
Read AGENTBLOC_CORRELATION_ID env var. If missing, generate `cron-<UTC-Z-compact>-<nonce6>` via helpers.sh.
## 3. Memory + state read
Load `.agentbloc/agents/gestor-cobros/memory.md` + `state.json`.
## 4. Input parse
Derive from state.working_state: month_to_process, last_processed_id, pending_retries[].
## 5. Execute
Load `.claude/skills/gestor-cobros/SKILL.md`. Autonomy: semi. Reconcile BBVA transactions for month_to_process.
## 6. State + log write
Update state.json (advance month_to_process), last-run.json, append wake-completed entry with trigger=cron.
```

## Wake.md Artifact 2 - Recepcionista webhook-telegram wake

Path: `.agentbloc/agents/recepcionista/wake-webhook-telegram-tenant-message.md`. Materialized post-substitution from wake-job-webhook.md.tmpl with `{{trigger.source}}=telegram`, `{{trigger.event_name}}=tenant-message`, `{{payload.schema}}={chat_id, sender, text}`.

```
# Wake Job: recepcionista (webhook: telegram/tenant-message)
You are waking to execute Daily Operations Reporter per the n8n webhook for `telegram` event `tenant-message`.
## 1. Kill-switch pre-check
Check `.agentbloc/KILL_SWITCH`. If active, append halted-kill-switch with trigger=webhook-telegram; EXIT.
## 2. Correlation-ID ingest
Read `correlation_id` from D-74 envelope top-level. Format: `webhook-telegram-<UTC-Z-compact>-<nonce6>`.
## 3. Memory + state read
Load `.agentbloc/agents/recepcionista/memory.md` + `state.json`.
## 4. Input parse (D-74 envelope payload)
Validate envelope (schema_version=1, agent_id=recepcionista, source=telegram). Parse payload `{chat_id, sender, text}`. Idempotency check on message_id natural-key.
## 5. Execute
Load `.claude/skills/recepcionista/SKILL.md`. Autonomy: semi. If tenant query needs payment-status, TeamCreate([recepcionista, gestor-cobros], correlation_id) + SendMessage with sub-001 child ID.
## 6. State + log write
Commit message_id to processed_ids[]. Append wake-completed with trigger=webhook-telegram, event_name=tenant-message.
```

## Wake.md Artifact 3 - Recepcionista inter wake (team handler)

Path: `.agentbloc/agents/recepcionista/wake-inter.md`. Materialized post-substitution from wake-job-inter.md.tmpl. The team-transition kill-switch check at section 5 is the D-77 enforcement point #3.

```
# Wake Job: recepcionista (inter-agent)
You are waking to execute Daily Operations Reporter in response to a SendMessage from another agent in your team.
## 1. Kill-switch pre-check
Check `.agentbloc/KILL_SWITCH`. If active, emit `{status: halted-kill-switch}` to caller and EXIT.
## 2. Correlation-ID ingest
Read from `message.metadata.correlation_id` (ClaudeClaw) OR inbox file (writeStateHandoff fallback). Inherited child IDs (`<parent>-sub-<NNN>`) are used verbatim.
## 3. Memory + state read
Load `.agentbloc/agents/recepcionista/memory.md` + `state.json`.
## 4. Input parse (SendMessage body + team dispatch)
Parse `{type, calling_agent_id, body}`. Validate calling_agent_id is in registry.runtime.workflows[<id>].agents roster. Dispatch on message.type. Unknown types return `{status: rejected, reason: unknown-message-type}`.
## 5. Execute
Load `.claude/skills/recepcionista/SKILL.md`. **Team-transition kill-switch check (D-77 #3):** RE-CHECK `.agentbloc/KILL_SWITCH` before any outgoing SendMessage. If active, emit halted-kill-switch and do NOT fan out.
## 6. State + log write
Update state.json + last-run.json. Append wake-completed with trigger=inter, calling_agent_id. If in active TeamCreate session, also append team-member-returned to TEAM_SESSIONS.jsonl.
```

## Crontab manifest

Path: `.agentbloc/runtime/crontab.applied`

```
# agentbloc:fingerprint sha256=<64-hex> generated_at=2026-04-24T18:00:00Z

# Gestor Cobros - monthly rent collection (1st of month, 09:00 Europe/Madrid = 08:00 UTC)
0 8 1 * * AGENTBLOC_CORRELATION_ID=$(/home/user/.agentbloc/runtime/helpers.sh agentbloc-gen-correlation cron) claude -p /home/user/.agentbloc/agents/gestor-cobros/wake-cron.md

# Gestor Documental - weekly document review (Monday 08:00 Europe/Madrid = 07:00 UTC)
0 7 * * 1 AGENTBLOC_CORRELATION_ID=$(/home/user/.agentbloc/runtime/helpers.sh agentbloc-gen-correlation cron) claude -p /home/user/.agentbloc/agents/gestor-documental/wake-cron.md

# Recepcionista has NO cron; webhook-only (Telegram + inter paths)
```

Installation discipline (per D-80): runtime-engine installs via stdin form, NEVER via `crontab -e`:

```bash
(crontab -l 2>/dev/null; cat .agentbloc/runtime/crontab.applied) | crontab -
```

## n8n Route 1 - Recepcionista Telegram

Path: `.agentbloc/runtime/n8n-routes/recepcionista-telegram-tenant-message.json`

```json
{
  "schema_version": 1,
  "agent_id": "recepcionista",
  "trigger": {
    "source": "telegram",
    "event_name": "tenant-message"
  },
  "n8n_config": {
    "webhook_path": "/webhook/recepcionista-tenant-message",
    "http_method": "POST",
    "filter": "chat.type == 'private' AND message.text IS NOT NULL"
  },
  "payload_schema": {
    "chat_id": "integer",
    "sender": "{ id: integer, username: string }",
    "text": "string"
  },
  "evidence": {
    "verified_at": null
  }
}
```

## n8n Route 2 - Gestor Documental Gmail

Path: `.agentbloc/runtime/n8n-routes/gestor-documental-gmail-new-invoice-email.json`

```json
{
  "schema_version": 1,
  "agent_id": "gestor-documental",
  "trigger": {
    "source": "gmail",
    "event_name": "new-invoice-email"
  },
  "n8n_config": {
    "webhook_path": "/webhook/gestor-documental-new-invoice-email",
    "http_method": "POST",
    "filter": "label == 'Inbox' AND from MATCHES '.*@(invoices|billing).*'"
  },
  "payload_schema": {
    "message_id": "string",
    "from": "string",
    "subject": "string",
    "attachment_ids": "string[]"
  },
  "evidence": {
    "verified_at": null
  }
}
```

## n8n Route 3 - Gestor Cobros Plaid

Path: `.agentbloc/runtime/n8n-routes/gestor-cobros-plaid-payment-received.json`

```json
{
  "schema_version": 1,
  "agent_id": "gestor-cobros",
  "trigger": {
    "source": "plaid",
    "event_name": "payment-received"
  },
  "n8n_config": {
    "webhook_path": "/webhook/gestor-cobros-plaid-payment-received",
    "http_method": "POST",
    "filter": "transaction.amount > 0 AND transaction.category == 'rent'"
  },
  "payload_schema": {
    "account_id": "string",
    "amount": "number",
    "transaction_id": "string"
  },
  "evidence": {
    "verified_at": null
  }
}
```

## Extended registry.yaml with runtime block (D-78)

Path: `.agentbloc/agents/registry.yaml`

The Phase 12 base registry (see arco-rooms-registry.yaml for the unextended form) is augmented with the new top-level `runtime` block per D-78. The agent block, reporting_hierarchy, and dashboard_agent fields are unchanged from Phase 12. Only the `runtime` block is shown below for brevity:

```yaml
runtime:
  schema_version: 1
  correlation_prefix: "arco-rooms"
  team_timeout_minutes: 15
  coordination_preference:
    prefer: "claudeclaw"
    fallback: "writeStateHandoff"
  cron_registered_at: "2026-04-24T18:05:00Z"
  crontab_manifest: ".agentbloc/runtime/crontab.applied"
  workflows:
    monthly-collections:
      agents: [gestor-cobros]
      spawn_rule: "declared"
      trigger:
        type: "cron"
        schedule: "0 8 1 * *"
    weekly-document-review:
      agents: [gestor-documental]
      spawn_rule: "declared"
      trigger:
        type: "cron"
        schedule: "0 7 * * 1"
    tenant-inquiry:
      agents: [recepcionista, gestor-cobros]
      spawn_rule: "dynamic"
      trigger:
        type: "webhook"
        webhook_route: ".agentbloc/runtime/n8n-routes/recepcionista-telegram-tenant-message.json"
    plaid-payment-received:
      agents: [gestor-cobros]
      spawn_rule: "declared"
      trigger:
        type: "webhook"
        webhook_route: ".agentbloc/runtime/n8n-routes/gestor-cobros-plaid-payment-received.json"
    gmail-invoice-received:
      agents: [gestor-documental]
      spawn_rule: "declared"
      trigger:
        type: "webhook"
        webhook_route: ".agentbloc/runtime/n8n-routes/gestor-documental-gmail-new-invoice-email.json"
  webhook_endpoints:
    - agent_id: recepcionista
      source: telegram
      event_name: tenant-message
      route_file: ".agentbloc/runtime/n8n-routes/recepcionista-telegram-tenant-message.json"
      evidence:
        verified_at: null
    - agent_id: gestor-documental
      source: gmail
      event_name: new-invoice-email
      route_file: ".agentbloc/runtime/n8n-routes/gestor-documental-gmail-new-invoice-email.json"
      evidence:
        verified_at: null
    - agent_id: gestor-cobros
      source: plaid
      event_name: payment-received
      route_file: ".agentbloc/runtime/n8n-routes/gestor-cobros-plaid-payment-received.json"
      evidence:
        verified_at: null
```

## Evidence table

| Agent | Trigger Paths | wake.md Files | Evidence verified_at |
|-------|---------------|---------------|----------------------|
| gestor-cobros | cron (monthly 1st 08:00 UTC) + webhook (plaid) + inter (receives from recepcionista) | wake-cron.md + wake-webhook-plaid-payment-received.md + wake-inter.md | null (user confirms live n8n route) |
| recepcionista | webhook (telegram) + inter (team lead on dynamic spawn) | wake-webhook-telegram-tenant-message.md + wake-inter.md | null |
| gestor-documental | cron (weekly Mon 07:00 UTC) + webhook (gmail) | wake-cron.md + wake-webhook-gmail-new-invoice-email.md | null |

Per D-39 evidence protocol + D-78 registry.runtime.webhook_endpoints.evidence.verified_at convention: `verified_at` stays `null` until the user confirms each route is live in their n8n instance. Phase 13 does not auto-ping; verification is a user action documented in the deploy report.

## Cross-References

- `.claude/skills/agentbloc/examples/arco-rooms-correlation-flow.md` (companion narrative fixture; 3 scenarios + grep recipes)
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (input to Phase 13 runtime-engine; trigger matrix source)
- `.claude/skills/agentbloc/examples/arco-rooms-registry.yaml` (Phase 12 base registry; extended with runtime block above)
- `.claude/skills/agentbloc/references/n8n-integration.md` (D-74 envelope schema + .json route file format)
- `.claude/skills/agentbloc/references/runtime-coordination.md` (TeamCreate + crontab stdin install discipline per D-80)
- `.claude/skills/agentbloc/references/correlation-id.md` (D-75 format + helpers.sh generator contract)
- `.claude/skills/agentbloc/templates/wake-job-cron.md.tmpl` (template that materialized Artifact 1)
- `.claude/skills/agentbloc/templates/wake-job-webhook.md.tmpl` (template that materialized Artifact 2)
- `.claude/skills/agentbloc/templates/wake-job-inter.md.tmpl` (template that materialized Artifact 3)
