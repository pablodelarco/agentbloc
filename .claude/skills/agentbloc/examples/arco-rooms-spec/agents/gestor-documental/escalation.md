# Escalation — gestor-documental

> Failure handling and escalation protocol for the Invoice Collection
> Specialist.

## Escalation triggers

The agent escalates when ANY of:

1. **Uncaught exception during wake** — runtime error, network failure,
   unparseable input from any provider
2. **Critical-action tool returns failure** — when 2+ providers fail
   in a single wake (single-provider failure is degrade-and-continue)
3. **Approval timeout** — N/A (this agent is `full` autonomy, no
   approval requests)
4. **Explicit `escalate(...)` call** — agent prose decides the
   situation needs human judgment (e.g., 3 of 6 providers returning
   "no invoices" when historical baseline is daily)

## Escalation message format (4-part template)

```
🚨 ESCALATION — gestor-documental
Correlation: <correlation-id>

What I tried: Pulled new invoices from 6 utility providers; 4 of 6
succeeded; <providers-failed> failed.

Why it failed: <root-cause-per-provider>. Examples:
- Endesa portal returned 503 "service temporarily unavailable"
- Naturgy Gmail filter matched 0 emails (expected ≥1 daily)

Options:
1. Retry failed providers in 30 minutes (next short cron) — risk: same outage
2. Skip failed providers today; resume tomorrow at 22:00 — risk: missed late fees
3. Investigate provider portal manually; manual upload to invoices.json

Recommended: Option 2 (skip + retry tomorrow); 503s typically clear within hours.

Reply: /resume <correlation-id> [free-text instructions] | /halt <correlation-id>
```

## Approval-timeout escalation

N/A — agent is `full` autonomy and never sends approval requests, so
there is nothing to time out on.

## Persistent halt

After an escalation fires, `last-run.json status` is set to `error`.
Subsequent wakes (next 22:00 cron) short-circuit with
`wake_outcome: skipped-prior-error` until `/resume <correlation-id>`
lands.

Rationale: avoid repeated cost spend on a known-broken state. If 4 of
6 providers fail two nights in a row, persistent halt prevents
chronic failure churn.

## /resume + /halt grammar

| Reply | Effect |
|---|---|
| `/resume <correlation-id>` | Set `last-run.json status: idle`. Next 22:00 wake resumes work. |
| `/resume <correlation-id> skip endesa` | Same + appends "skip endesa" to memory.md Open Items section |
| `/halt <correlation-id>` | Confirm persistent halt. (v1: documentation only; v2 may auto-escalate to org-level reporting) |

## Escalation target

| Channel | Who receives |
|---|---|
| `escalations_thread_id` (env) | Pablo (operator) |
| Fallback to `TELEGRAM_CHAT_ID` | Same person; used if escalations thread is misconfigured |

## Cross-references

- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
- Kill-switch: [`../../governance/kill-switch.md`](../../governance/kill-switch.md)
- Reference impl escalation router:
  [`../../runtime/reference-impl/escalation-router.sh`](../../runtime/reference-impl/escalation-router.sh)
