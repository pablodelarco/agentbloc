# Arco Rooms Monitor Fixtures (Phase 14)

> Phase 16 golden-file fixtures for Phase 14 monitor flow validation. Reuses correlation IDs from `arco-rooms-correlation-flow.md` Scenario A/B/C for continuity. All JSONL lines RFC 8785 JCS-canonicalized.

## Table of Contents

- [Sample 1: Per-Agent JSONL Log Lines](#sample-1-per-agent-jsonl-log-lines)
- [Sample 2: 1 Day's activity-feed.jsonl](#sample-2-1-days-activity-feedjsonl)
- [Sample 3: Briefing Telegram Message](#sample-3-briefing-telegram-message)
- [Sample 4: Escalation Telegram Message](#sample-4-escalation-telegram-message)
- [Sample 5: Lock File](#sample-5-lock-file)
- [Sample 6: Approval Thread Exchange](#sample-6-approval-thread-exchange)
- [Cross-References](#cross-references)

## Sample 1: Per-Agent JSONL Log Lines

5 entries from `gestor-cobros.jsonl` on 2026-05-01 covering action ENUM coverage:

```jsonl
{"action":"tool_call","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","cost_usd":0.0231,"details":{"account_id":"es76-1234","transaction_count":14},"duration_ms":2340,"locked_by":"bank-bbva-es76-1234","priority":"info","requires_human":false,"result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:00:00.123Z","token_count":{"cached_input":0,"input":1245,"output":312},"tool":"mcp__plaid__list_transactions"}
{"action":"decision","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","details":{"chosen":"send-reminder","decision":"tenant-payment-overdue-action","options_considered":["send-reminder","auto-debit","escalate-to-human"],"rationale":"5 days overdue but tenant has clean payment history; reminder is least-intrusive option."},"priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:00:03.500Z"}
{"action":"approval_request","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","details":{"args_summary":"to:tenant@example.com subject:May rent reminder","reasoning":"Sending May invoice reminder to tenant; rent overdue 5 days; reversible via corrective email","reversibility":"reversible","tool":"mcp__gmail__send_email"},"priority":"info","requires_human":true,"result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:00:05.000Z"}
{"action":"approval_response","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","details":{"decider_telegram_user_id":"123456789","outcome":"approved","reasoning_supplied":"yes, this is the May invoice run"},"priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:01:42.000Z"}
{"action":"tool_call","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","cost_usd":0.0089,"details":{"recipient":"tenant@example.com"},"duration_ms":1240,"priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:01:43.500Z","token_count":{"cached_input":0,"input":420,"output":180},"tool":"mcp__gmail__send_email"}
```

## Sample 2: 1 Day's activity-feed.jsonl

Chronological merge of 3 Arco Rooms agents' logs on 2026-05-01:

```jsonl
{"action":"tool_call","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:00:00.123Z","tool":"mcp__plaid__list_transactions"}
{"action":"decision","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:00:03.500Z"}
{"action":"approval_request","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","priority":"info","requires_human":true,"result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:00:05.000Z"}
{"action":"tool_call","agent_id":"gestor-documental","correlation_id":"cron-20260501T080500Z-d4e91c","cost_usd":0.0156,"priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:05:00.000Z","tool":"mcp__gmail__search_messages"}
{"action":"approval_response","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:01:42.000Z"}
{"action":"tool_call","agent_id":"recepcionista","correlation_id":"webhook-telegram-20260501T143022Z-c7d92a","cost_usd":0.0042,"priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T14:30:22.500Z","tool":"mcp__telegram__send_message"}
{"action":"escalation","agent_id":"gestor-documental","correlation_id":"cron-20260501T080500Z-d4e91c","details":{"options":["wait 60s + retry","skip + resume tomorrow","request quota increase"],"recommended_next_action":"skip + resume tomorrow","what_tried":"Pulled 47 invoice emails","why_failed":"Gmail API 429 quota exceeded"},"priority":"critical","result":"failure","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T09:15:23.000Z"}
```

## Sample 3: Briefing Telegram Message

Daily briefing dispatched to `briefing_thread_id` at 08:00 Europe/Madrid on 2026-05-02 (covering 2026-05-01):

```
📊 Arco Rooms , 2026-05-01 daily briefing

Status: 🟢 2 active · 🟡 0 idle · 🔴 1 error
─────────────────────────────────
· gestor-cobros 🟢 active , 14 transactions processed, 1 reminder sent, $0.32 spend
· recepcionista 🟢 active , 3 tenant messages handled, 1 calendar slot booked, $0.08 spend
· gestor-documental 🔴 error , 31 of 47 invoices processed; escalation pending: gmail rate-limited (see escalations thread)

─────────────────────────────────
Approvals: 1 pending → 0 (all resolved)
Escalations: 1 active (gestor-documental gmail rate-limit)
Total cost today: $0.40 (notional; included in Claude Max subscription)
Total tokens: 4,221 input / 1,108 output / 0 cached

Activity feed: .claude/agents/logs/2026-05-01/activity-feed.jsonl (15 lines)
Reply /resume <correlation_id> in #escalations to unblock gestor-documental.
```

## Sample 4: Escalation Telegram Message

Dispatched to `escalations_thread_id` on 2026-05-01 at 09:15:

```
🚨 ESCALATION , gestor-documental
Correlation: cron-20260501T080500Z-d4e91c

What I tried: Pulled 47 new invoice emails from gmail filter "Invoice 2026"; rate-limited at message 31.

Why it failed: Gmail API returned 429 quota exceeded; per-user-per-second limit; daily quota at 78%.

Options:
1. Wait 60s + retry remaining 16 messages
2. Skip remaining messages today; resume tomorrow at 08:00
3. Request quota increase via Google Cloud Console

Recommended: Option 2 (skip + resume tomorrow); quota likely fully restored at 00:00 UTC.

Reply: /resume cron-20260501T080500Z-d4e91c skip remaining today | /halt cron-20260501T080500Z-d4e91c
```

## Sample 5: Lock File

`.agentbloc/locks/bank-bbva-es76-1234.lock` content during gestor-cobros wake on 2026-05-01:

```json
{"acquired_at":"2026-05-01T08:00:01.234Z","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","expires_at":"2026-05-01T08:30:01.234Z"}
```

After release at 08:01:45:

```json
null
```

## Sample 6: Approval Thread Exchange

Telegram approvals thread on 2026-05-01:

**08:00:05 (bot)**:
```
[APPROVE/DENY] gestor-cobros
Correlation: cron-20260501T080000Z-a3f21b
Action: mcp__gmail__send_email(to:tenant@example.com subject:May rent reminder)
Reversibility: reversible
Reasoning: Sending May invoice reminder to tenant; rent overdue 5 days; reversible via corrective email
Reply: /approve cron-20260501T080000Z-a3f21b | /deny cron-20260501T080000Z-a3f21b
```

**08:01:42 (human reply)**: `/approve cron-20260501T080000Z-a3f21b yes, this is the May invoice run`

**08:01:43 (bot ack)**:
```
✓ Approved , gestor-cobros proceeding with mcp__gmail__send_email.
```

Resulting `approvals.jsonl` entry (the response line):

```jsonl
{"action":"approval_response","agent_id":"gestor-cobros","correlation_id":"cron-20260501T080000Z-a3f21b","details":{"decider_telegram_user_id":"123456789","outcome":"approved","reasoning_supplied":"yes, this is the May invoice run"},"priority":"info","result":"success","schema_version":1,"team":"arco-rooms","timestamp":"2026-05-01T08:01:42.000Z"}
```

## Cross-References

- [jsonl-log-schema.md](../references/jsonl-log-schema.md) , 12-field line schema
- [correlation-id.md](../references/correlation-id.md) , D-75 ID format
- [arco-rooms-correlation-flow.md](arco-rooms-correlation-flow.md) , parent fixture; correlation IDs reused for Phase 16 continuity
