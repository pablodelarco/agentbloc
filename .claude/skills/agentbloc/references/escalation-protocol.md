# Escalation Protocol (Phase 14)

> Phase 14 reference. Routes agent failures + critical errors through a dedicated `escalations` Telegram thread (distinct from `approvals` per CTRL-01 and `briefing` per MONITOR-04). Persistent-halt semantics until /resume reply. 4-part message template per AUTON-05.

## Table of Contents

- [When This Applies](#when-this-applies)
- [6-Step Flow](#6-step-flow)
- [4-Part Template](#4-part-template)
- [Persistent-Halt Semantics](#persistent-halt-semantics)
- [/resume + /halt Slash-Commands](#resume--halt-slash-commands)
- [3 Worked Examples](#3-worked-examples)
- [Cross-References](#cross-references)

## When This Applies

An agent escalates when: (1) an uncaught exception during wake; (2) a critical-action tool returning `result: failure` (where critical = the action was the agent's primary purpose for this wake); (3) explicit `escalate(...)` call from agent prose.

## 6-Step Flow

1. JSONL log entry: `{action: "escalation", priority: "critical", details: {what_tried, why_failed, options, recommended_next_action}}` per `references/jsonl-log-schema.md`.
2. `last-run.json` mutation: `status: error` per `references/agent-memory-schema.md` MEM-04.
3. `bash .agentbloc/runtime/escalation-router.sh telegram-escalate "$AGENT_ID" "$CORRELATION_ID" "$WHAT_TRIED" "$WHY_FAILED" "$OPTIONS_JSON" "$RECOMMENDED"`.
4. Telegram POST to `escalations_thread_id` with the 4-part template below.
5. Wake exits with `wake_outcome: escalated`.
6. Subsequent wakes (cron / webhook / inter) check `last-run.json status` first (after kill-switch); if `error`, short-circuit with `wake_outcome: skipped-prior-error` UNTIL `/resume` reply lands.

## 4-Part Template

```
🚨 ESCALATION , {{agent_id}}
Correlation: {{correlation_id}}

What I tried: {{what_tried}}

Why it failed: {{why_failed}}

Options:
1. {{option_1}}
2. {{option_2}}
3. {{option_3}}

Recommended: {{recommended_next_action}}

Reply: /resume {{correlation_id}} [free-text instructions] | /halt {{correlation_id}}
```

Per AUTON-05: NOT just an error stack. Each part MUST be filled by the agent's prose before invoking `escalation-router.sh`.

## Persistent-Halt Semantics

`status: error` halts subsequent wakes. Wake-job templates section 1 (after kill-switch check) detects + short-circuits with `wake_outcome: skipped-prior-error`. Rationale: avoid repeated cost spend on a known-broken state. v2.0 ships persistent halt; v2.5 adds opt-in retry budget per agent.

The kill-switch check ALWAYS precedes the persistent-halt check; an agent halted by kill-switch does NOT escalate (the halt IS the alarm). Escalations bypass kill-switch ONLY when the escalation IS the kill-switch firing event itself.

## /resume + /halt Slash-Commands

`/resume <correlation_id> [free-text instructions]` , updates `last-run.json status: idle` + appends instructions to `memory.md` Open Items section (per Phase 12 D-64 location). Next cron/webhook fires resumes work.

`/halt <correlation_id>` , confirms persistent halt + escalates one tier higher (optional v2.5 hook; v2.0 ships as documentation of the affordance, no action).

Inbound n8n route at `.agentbloc/runtime/n8n-routes/agentbloc-resume.json` (emitted by Phase 13 runtime-engine) handles `/resume` replies + dispatches the state mutation.

## 3 Worked Examples

**Example A: Gestor Documental + gmail rate-limit**
```
🚨 ESCALATION , gestor-documental
Correlation: webhook-gmail-20260501T091523Z-b8c41e

What I tried: Pulled 47 new invoice emails from gmail filter "Invoice 2026"; rate-limited at message 31.
Why it failed: Gmail API returned 429 quota exceeded; per-user-per-second limit; daily quota at 78%.
Options:
1. Wait 60s + retry remaining 16 messages
2. Skip remaining messages today; resume tomorrow at 08:00
3. Request quota increase via Google Cloud Console

Recommended: Option 2 (skip + resume tomorrow); quota likely fully restored at 00:00 UTC.

Reply: /resume webhook-gmail-20260501T091523Z-b8c41e skip remaining today | /halt webhook-gmail-20260501T091523Z-b8c41e
```

**Example B: Gestor Cobros + plaid auth-revoked**
```
🚨 ESCALATION , gestor-cobros
Correlation: cron-20260501T080000Z-a3f21b

What I tried: Listed transactions for account es76-1234; received 401 ITEM_LOGIN_REQUIRED.
Why it failed: User revoked Plaid Item access (manual disconnect or expired refresh-token).
Options:
1. Re-authorize via Plaid Link (requires user browser session)
2. Switch to BBVA direct API (already configured per registry.yaml)
3. Skip this account this month; resume next cron

Recommended: Option 1 (re-authorize); BBVA fallback may not have full transaction history.

Reply: /resume cron-20260501T080000Z-a3f21b reauthorized | /halt cron-20260501T080000Z-a3f21b
```

**Example C: Recepcionista + BBVA 2FA-expired**
```
🚨 ESCALATION , recepcionista
Correlation: webhook-telegram-20260501T143022Z-c7d92a

What I tried: Authorized payment via BBVA API for tenant request; 2FA challenge expired.
Why it failed: BBVA SCA token expires after 5 min; agent reasoning took 7 min.
Options:
1. Re-trigger 2FA + retry payment with shorter reasoning window
2. Defer payment to next cron after explicit approval
3. Switch payment to manual SEPA transfer (no SCA on small amounts)

Recommended: Option 2 (defer to next cron); avoids same expiry on retry.

Reply: /resume webhook-telegram-20260501T143022Z-c7d92a defer to monthly cron | /halt webhook-telegram-20260501T143022Z-c7d92a
```

## Cross-References

- [incident-response.md](incident-response.md) , Runtime Kill-Switch Semantics sibling pattern; kill-switch precedence
- [approval-router.md](approval-router.md) , shared Telegram-routing infrastructure (escalation-router.sh + approval-router.sh follow same shell + long-poll grammar)
- [agent-memory-schema.md](agent-memory-schema.md) , `last-run.json status: error` field
- [jsonl-log-schema.md](jsonl-log-schema.md) , escalations.jsonl line schema
