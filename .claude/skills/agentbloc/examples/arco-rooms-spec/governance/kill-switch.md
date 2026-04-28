# Kill Switch — Arco Rooms

> Three independent triggers. Any halts the entire team within one
> cron tick. Recovery requires explicit human action.

## Three triggers

### 1. File flag

```
.agentbloc/KILL_SWITCH
```

If exists, all agents halt at next wake. Create with `touch
.agentbloc/KILL_SWITCH`; remove with `rm .agentbloc/KILL_SWITCH`.

### 2. Environment variable

```
AGENTBLOC_KILL=1
```

If set to `1` in `.env`, team halts. Use when shell access is
impractical.

### 3. Telegram slash-command

```
/halt-all <reason>
```

In the team's escalations Telegram thread, this command from an
authorized user (per `.env` `TELEGRAM_AUTHORIZED_USERS`, currently
just Pablo) creates the file flag. Reverse with `/resume-all`.

## How agents check

Every agent's wake (or `runtime/reference-impl/wake.sh` preamble)
executes this contract before any work:

```bash
if [ -f ".agentbloc/KILL_SWITCH" ] || [ "$AGENTBLOC_KILL" = "1" ]; then
  audit_log "kill_switch_fire" "agent=$AGENT_ID reason=flag-set"
  exit 0
fi
```

Hook order: kill-switch ALWAYS precedes any other PreToolUse hook.
Reference impl ensures this with alphabetical naming
(`00-kill-switch-check.sh` runs before `autonomy-gate.sh`).

## Why "silent exit"

When kill switch fires, the team is broken or under attack. Sending
hundreds of Telegram alarms compounds the problem. The kill switch
itself IS the alarm — Pablo (who set it) knows.

Exception: if kill switch fires due to detection logic (not in v1 —
this team has no auto-kill detectors), the detector sends ONE
Telegram alarm before silencing.

## Recovery

To resume:

1. Investigate why the kill switch fired (read recent
   audit.jsonl, approvals.jsonl, escalations.jsonl)
2. Fix underlying issue
3. Remove flag: `rm .agentbloc/KILL_SWITCH` OR unset env var OR
   `/resume-all` in Telegram
4. Manually trigger one wake to verify health:
   `AGENTBLOC_NO_CRON=1 ./runtime/reference-impl/wake.sh gestor-documental manual-test`
5. Verify audit log shows successful tool calls
6. Let cron resume normal operation

Team does NOT self-recover. Operator-driven recovery is the point.

## Detection-driven kills (NOT enabled in v1)

The architecture supports automated kill triggers:

| Trigger | Detector | Why |
|---|---|---|
| Cost spike | Cost > €5/day | Runaway agent burning $ |
| Audit-log anomaly | Same correlation_id > 10 times | Loop detected |
| External error rate | Tool failures > 50% in 1h window | Vendor outage cascade |
| Approval timeout cascade | > 5 pending approvals | Pablo unresponsive |

v1 of this team does NOT enable these. If desired, build session adds
optional cron jobs that touch `.agentbloc/KILL_SWITCH` on detection.

## Tests

Build session writes tests asserting:

1. With file flag set, every agent's wake exits 0 immediately
2. With env var set, same
3. Removing flag + waking succeeds
4. Kill-switch hook runs BEFORE other PreToolUse hooks
5. Kill fire emits exactly one audit log line, no Telegram

## What NOT to do

- Don't auto-resume after timeout — defeats the purpose
- Don't skip the check to "save a cycle" — it's cheap (single file
  stat + env var test)
- Don't tie kill to a single trigger — defense-in-depth requires three

## Cross-references

- Audit trail: [`audit-trail.md`](audit-trail.md)
- Per-agent escalations: `../agents/<id>/escalation.md`
- Reference impl: `../runtime/reference-impl/hooks/00-kill-switch.sh`
- AgentBloc reference: `references/incident-response.md`
