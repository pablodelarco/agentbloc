# Webhook Receiver Spec

> Loaded by SKILL.md during Phase 3 when a tool is assigned tier
> `NEEDS-WEBHOOK`. Defines what the spec folder must contain so a
> build session can implement the webhook receiver.

## Table of Contents

- [When This Applies](#when-this-applies)
- [What the Spec Folder Must Contain](#what-the-spec-folder-must-contain)
- [Receiver Design Considerations](#receiver-design-considerations)
- [Per-Receiver Spec Template](#per-receiver-spec-template)
- [Cross-References](#cross-references)

## When This Applies

A tool received tier `NEEDS-WEBHOOK` from
[inventory-protocol.md](inventory-protocol.md):
- Vendor exposes a webhook subscription mechanism (Stripe, Shopify,
  GitHub, Slack Events API, etc.)
- The agent reacts to vendor-pushed events rather than polling
- The receiver must be built and exposed at a stable URL

## What the Spec Folder Must Contain

For each `NEEDS-WEBHOOK` tool, `spec-engine` writes a single file:

```
integrations/needs-webhook/<tool>-receiver.md
```

This file is the receiver's design spec — the build session implements
the actual HTTP endpoint based on it.

## Receiver Design Considerations

The receiver must address all of:

| Concern | Spec section |
|---|---|
| **Subscription** | What events to subscribe to + how to register the URL with the vendor |
| **Authentication** | Signing secret + signature verification (HMAC-SHA256 typical) |
| **Idempotency** | Vendor may retry; receiver dedups via event_id |
| **Acknowledgment** | Vendor expects 2xx within seconds; do work async |
| **Inbox handoff** | Convert event payload into agent's inbox envelope |
| **Replay** | Some vendors push replays after outage; handle gracefully |
| **Rate limiting** | Vendor may burst; receiver shouldn't crash |

The receiver is typically a tiny HTTP service: bash + nc on a free
port for the demo, or n8n's Webhook node, or a Python/Node app on a
public URL (ngrok / Cloudflare Tunnel for local, or a small VPS
endpoint for production).

## Per-Receiver Spec Template

```markdown
# Webhook Receiver — <tool>

This spec describes a webhook endpoint the build session implements
to receive events from <tool>. The receiver feeds events into the
agent's inbox.

## Subscribed events

| Event name | Used by agent | Action on receipt |
|---|---|---|
| `customer.subscription.created` | <agent-id> | atomic_write_inbox to <agent-id> with subscription details |
| `customer.subscription.updated` | <agent-id> | atomic_write_inbox; agent re-evaluates state |

(Excluded events list — least-privilege: which events are NOT
subscribed and why)

## Endpoint

| Property | Value |
|---|---|
| Method | POST |
| Path suggestion | `/webhooks/<tool>` |
| Authentication | <signing-secret-header-name>, HMAC-SHA256 of body |
| Expected ack | 200 OK within 5 seconds; 4xx/5xx triggers vendor retry |

## Signature verification

```python
# pseudocode — adapt to runtime
sig = request.headers.get('<signing-secret-header-name>')
expected = hmac.new(WEBHOOK_SECRET, request.body, sha256).hexdigest()
if not hmac.compare_digest(sig, expected):
    return 401
```

The build session implements this in whatever language the runtime
uses. The reference impl bash path uses `openssl dgst -sha256 -hmac`.

## Idempotency

Vendor's `<event-id-field>` is the dedup key. Receiver SHOULD:

1. Check if `event_id` is in `.agentbloc/state/<tool>-webhook-seen.jsonl`
2. If seen → 200 OK immediately, no work
3. If new → append to seen.jsonl, atomic_write_inbox, then 200 OK

## Inbox handoff

For every accepted event:

```bash
# pseudocode using reference-impl primitives
cid="$(gen_correlation_id "webhook-<tool>")"
echo "$EVENT_PAYLOAD" > /tmp/payload.$$.json
atomic_write_inbox "<agent-id>" "webhook-<tool>" "$cid" /tmp/payload.$$.json
```

The agent's next wake reads the inbox and processes the event.

## Subscription registration

Run once at install time (build session does this):

1. Generate a stable URL (production: VPS endpoint; demo: ngrok tunnel)
2. Use vendor's API or admin UI to register URL + selected events
3. Store the signing secret in `.env` as `<TOOL>_WEBHOOK_SECRET`
4. Verify with vendor's test-event mechanism (Stripe CLI, Shopify
   webhook tester, etc.)

## Failure modes

- **Signature failure:** log to `.agentbloc/state/<tool>-webhook-rejected.jsonl`
  with reason; respond 401. Don't process — could be a forgery.
- **Missing event_id:** log + respond 400. Vendor SDK should always
  include one; absence is a signal something's wrong.
- **Inbox write fails:** log + respond 500 (vendor will retry).
- **Replay storm after vendor outage:** idempotency on event_id makes
  this safe; receiver may emit a metric on burst.

## Effort estimate

<from inventory.yaml: estimated_effort_cc_hours>

## Reference implementations

- Stripe: https://stripe.com/docs/webhooks/signatures
- Shopify: https://shopify.dev/docs/apps/webhooks/configuration/https
- GitHub: https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
- Slack Events API: https://api.slack.com/apis/events-api
```

## Cross-References

- [inventory-protocol.md](inventory-protocol.md) — Q4 path
- [phase-3-integration.md](phase-3-integration.md) — orchestration
- [n8n-flow-design.md](n8n-flow-design.md) — Tier 3 alternative if the
  webhook fits a flow better
- [mcp-synthesis.md](mcp-synthesis.md) — Tier 2 alternative for
  poll-based pulls
- `runtime/reference-impl/helpers.sh` — `atomic_write_inbox` primitive
  the receiver calls
