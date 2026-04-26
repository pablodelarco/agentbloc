# Approval Router (Phase 14)

> Phase 14 reference. Routes side-effect tool approvals through a dedicated Telegram thread (CTRL-01). Single shell script `.agentbloc/runtime/approval-router.sh` emitted by runtime-engine + invoked by `autonomy-gate.sh` PreToolUse hook.

## Table of Contents

- [When This Applies](#when-this-applies)
- [6-Step Flow](#6-step-flow)
- [Telegram Message Format](#telegram-message-format)
- [Slash-Command Syntax](#slash-command-syntax)
- [Long-Poll Implementation](#long-poll-implementation)
- [approvals.jsonl Append Discipline](#approvalsjsonl-append-discipline)
- [Thread Separation per CTRL-01](#thread-separation-per-ctrl-01)
- [approval-router.sh Shell Contract](#approval-routersh-shell-contract)
- [Cross-References](#cross-references)

## When This Applies

PreToolUse `autonomy-gate.sh` hook calls `approval-router.sh` on side-effect tools for `semi` + `supervised` agents per `references/autonomy-controller.md` Per-Autonomy Behavior Matrix.

## 6-Step Flow

1. Hook invocation: `bash .agentbloc/runtime/approval-router.sh telegram-request "$AGENT_ID" "$TOOL_NAME" "$TOOL_ARGS_SUMMARY" "$TOOL_REASONING" "$CORRELATION_ID"`
2. Read `registry.yaml monitor.approval_thread_id` + per-agent `approval_timeout_seconds` (default 600).
3. POST structured Telegram message via Telegram MCP `sendMessage` to `approval_thread_id`.
4. Long-poll Telegram via `getUpdates` with `offset` to avoid duplicate consumption; match reply against `^/approve <correlation_id>` or `^/deny <correlation_id>`.
5. Append to `.claude/agents/logs/<YYYY-MM-DD>/approvals.jsonl` per AUTON-03 schema.
6. Exit 0 (approved) or 1 (denied/timeout); hook propagates.

## Telegram Message Format

```
[APPROVE/DENY] {{agent_id}}
Correlation: {{correlation_id}}
Action: {{tool_name}}({{args_summary}})
Reversibility: {{reversibility_tag}}
Reasoning: {{tool_reasoning}}
Reply: /approve {{correlation_id}} | /deny {{correlation_id}}
```

`reversibility_tag` is one of `reversible | hard-to-reverse | irreversible` derived by deploy-engine from `references/blast-radius.md` per the tool's classification.

## Slash-Command Syntax

`/approve <correlation_id> [optional reasoning]` , approve the request; reasoning captured in `approvals.jsonl details.reasoning_supplied`.
`/deny <correlation_id> [optional reasoning]` , deny the request.

The `correlation_id` arg is the disambiguator for concurrent pending approvals. Multiple agents can have pending approvals simultaneously; the human picks the correct one by ID.

## Long-Poll Implementation

Telegram Bot API `getUpdates` with `offset` + `timeout=30` (long-poll); router calls in a loop until match found OR `approval_timeout_seconds` elapsed:

```bash
DEADLINE=$(($(date +%s) + ${APPROVAL_TIMEOUT:-600}))
OFFSET=$(cat .agentbloc/runtime/.tg-offset 2>/dev/null || echo 0)
while [ $(date +%s) -lt $DEADLINE ]; do
  RESP=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=30")
  # parse message text for /approve <CID> or /deny <CID>
  # update OFFSET to last update_id+1; persist to .tg-offset
  # match -> exit with append to approvals.jsonl
done
echo "timeout" >&2; exit 1
```

The offset persistence at `.agentbloc/runtime/.tg-offset` ensures concurrent pending approvals do not consume each others' updates.

## approvals.jsonl Append Discipline

Per-day file at `.claude/agents/logs/<YYYY-MM-DD>/approvals.jsonl`. Schema = `references/jsonl-log-schema.md` 12-field with `action: approval_request | approval_response`. Two lines per round-trip (one for the dispatch, one for the human reply).

Required fields per AUTON-03: `correlation_id`, `agent_id`, `tool` (or in details for response), `details: {tool, args_summary, reversibility, reasoning}`, `timestamp` (proposal vs decision distinguished by action ENUM), `details.outcome` ENUM `approved | denied | timeout`, `details.decider_telegram_user_id` (for response only). Append-only; RFC 8785 JCS-canonicalized per line.

## Thread Separation per CTRL-01

Three Telegram threads per team, distinct IDs in `registry.yaml monitor`:
- `approval_thread_id` , this router's target
- `briefing_thread_id` , daily briefing target (MONITOR-04)
- `escalations_thread_id` , crisis target (AUTON-04 / `escalation-protocol.md`)

Rationale: approvals are time-sensitive decisions that must not be buried in noisier briefing or escalation noise. Deploy-engine creates the 3 threads at deploy-time once per team + persists the IDs.

## approval-router.sh Shell Contract

**Args:** `telegram-request <agent_id> <tool> <args_summary> <reasoning> <correlation_id>`
**Env:** `$TELEGRAM_BOT_TOKEN` (required), `$APPROVAL_TIMEOUT` (default 600), `$REGISTRY_PATH` (default `.agentbloc/agents/registry.yaml`)
**Exit codes:** 0 = approved (proceed), 1 = denied/timeout (block)
**Side effects:** appends to `approvals.jsonl`; updates `.tg-offset`. NO state.json mutations; NO memory.md writes; NO other Telegram API calls beyond `sendMessage` + `getUpdates`.

## Cross-References

- [autonomy-controller.md](autonomy-controller.md) , caller (PreToolUse hook)
- [telegram-patterns.md](telegram-patterns.md) , thread-per-domain pattern + Telegram MCP usage
- [correlation-id.md](correlation-id.md) , D-75 format for slash-command arg
- [jsonl-log-schema.md](jsonl-log-schema.md) , approvals.jsonl entry schema
- [blast-radius.md](blast-radius.md) , reversibility-tag derivation
