# Escalation — recepcionista

## Escalation triggers

1. **Uncaught exception** during wake (network, parsing)
2. **Critical-action failure**: Telegram delivery returns persistent
   non-2xx (3 retries exhausted) for ANY owner thread
3. **Approval timeout**: Pablo doesn't reply `/approve <correlation-id>`
   within 600s. Tier ladder per `governance/approval-protocol.md`:
   - Tier 1 ping after 600s: re-send approval message tagged `[ESC1]`
     with derived child correlation-id `<orig>-esc1`
   - Tier 2 ping after another 600s: tagged `[ESC2]`,
     correlation-id `<orig>-esc2`
   - Tier 3 final at 1800s: escalate to escalations_thread_id;
     halt remaining sends for the wake; set last-run.json status=error
4. **Explicit `escalate(...)`**: agent decides a message contains
   information critical enough to bypass the approval queue (e.g.,
   "tenant fraud detected" — currently no such trigger in v1)

## Escalation message format

```
🚨 ESCALATION — recepcionista
Correlation: <correlation-id>

What I tried: Sent <N> per-owner Telegram summaries; <N-K>
delivered; <K> stuck in approval queue past 1800s OR Telegram
delivery failed.

Why it failed: <root cause:>
- Pablo unresponsive in approvals_thread_id past Tier 3 timeout
- Telegram Bot API returned 429 (rate limit) consistently after
  3 retries
- Owner thread <thread-id> returned 403 (bot kicked from thread —
  owner left the team or revoked bot)

Options:
1. Retry stuck sends in next 23:00 cron (24h delay) — risk: stale data
2. Promote stuck sends to escalations thread for Pablo's eyes-only
   review — risk: PII in escalations thread (owner data)
3. Skip stuck owners today; flag in registry for manual handling

Recommended: Option 1 if Pablo unresponsive; Option 3 if specific
owner thread is broken (clean failure mode, no data loss).

Reply: /resume <correlation-id> [free-text] | /halt <correlation-id>
```

## Approval-timeout escalation

Tier 1/2/3 ladder above. Each tier uses a derived child correlation-id
to bypass Telegram dedup in `telegram-send.sh`.

Special case: if Tier 3 fires AND the original send was for an
unmatched-payment-alert (real-time, not nightly), the alert is
promoted to escalations_thread_id with priority=critical so Pablo
sees it eventually even if he missed the approvals thread.

## Persistent halt

`last-run.json status=error` halts next 23:00 cron until `/resume
<correlation-id>` lands. If the halt persists 2+ days, the team is
effectively offline (no owner reporting); the situation warrants
manual operator intervention.

## /resume + /halt grammar

Standard per `governance/approval-protocol.md`.

`/resume <correlation-id> sent manually for <owner-name>` is a
common pattern: Pablo manually messages the owner, then resumes the
agent so it doesn't try to re-send tomorrow.

## Escalation target

`escalations_thread_id` (env). NOT the approvals thread (which is
already overloaded if approvals are timing out).

## Cross-references

- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
- Kill-switch: [`../../governance/kill-switch.md`](../../governance/kill-switch.md)
- Reference impl escalation router:
  [`../../runtime/reference-impl/escalation-router.sh`](../../runtime/reference-impl/escalation-router.sh)
