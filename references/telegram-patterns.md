# Telegram Reporting Patterns

> Loaded during Phase 5 (telegram.yaml generation in deployment artifacts) and Phase 2 (reporting preferences in Design step 5). Provides thread-per-domain convention, notification tiers, approval-by-reply patterns, voice message support, and bot setup requirements.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Thread-Per-Domain Convention](#thread-per-domain-convention)
- [Notification Tiers](#notification-tiers)
- [Approval-by-Reply](#approval-by-reply)
- [Voice Message Support](#voice-message-support)
- [Bot Setup Requirements](#bot-setup-requirements)
- [Quick Reference](#quick-reference)

## When This Applies

Referenced during Phase 5 (telegram.yaml generation) and Phase 2 (reporting design in governance specification). This is a supporting pattern library, not a standalone conversational phase. The deployment protocol cross-references this file when generating telegram.yaml and configuring notification routing.

## Thread-Per-Domain Convention

Each logical domain gets its own Telegram forum topic (thread) within the team's supergroup. Messages are routed by domain, not by agent. This keeps related notifications grouped regardless of which agent produced them.

**How it works:** Telegram supergroups with "Topics" (forum mode) enabled support separate conversation threads. Each thread has a unique `message_thread_id` used in the Bot API `sendMessage` call to target the correct topic.

**Domain mapping example (Arco Rooms):**

| Domain | Thread Purpose | Typical Senders |
|--------|---------------|-----------------|
| invoices | Invoice collection results and errors | Invoice Collector |
| payments | Payment matching results, low-confidence flags | Payment Matcher |
| operations | Pipeline status, system errors, kill switch alerts | Any agent |
| approvals | Level 3-4 agent approval requests and responses | Report Sender, any Level 3+ agent |

**Why thread-per-domain, not thread-per-agent:** A single domain (e.g., "operations") may receive messages from multiple agents. Grouping by domain keeps the user's view organized by topic. If an invoice error and a payment error both land in "operations," the user sees all system issues in one place.

**telegram.yaml thread mapping:**

```yaml
threads:
  invoices:
    message_thread_id: 2
    description: "Invoice collection results and errors"
  payments:
    message_thread_id: 3
    description: "Payment matching results, low-confidence flags"
  operations:
    message_thread_id: 4
    description: "Pipeline status, errors, kill switch alerts"
  approvals:
    message_thread_id: 5
    description: "Level 3-4 agent approval requests"
```

Thread IDs are obtained after creating forum topics in the supergroup. They are populated during deployment setup, not hardcoded in advance.

## Notification Tiers

Three tiers with distinct formatting. **Silence-by-default:** agents only send notifications for notable events. No "everything is fine" messages. If nothing noteworthy happened, the agent sends nothing.

### Tier 1: `info`

Plain text, routine updates. Used for successful completions with notable results.

```
3 new invoices collected from Xero
Payment matching complete: 12 of 14 matched automatically
```

### Tier 2: `action_required`

Bold header prefix. Requires user attention or response.

```
**ACTION REQUIRED:** 1 low-confidence match needs review
**ACTION REQUIRED:** Xero OAuth token expires in 3 days
```

### Tier 3: `error`

Alert emoji prefix. Immediate attention needed. Indicates a failure that may affect data integrity or agent operation.

```
ALERT: Invoice Collector failed to reach Endesa portal after 3 retries
ALERT: Kill switch activated by operator - all agents halted
```

**Tier selection rule:** Use the lowest tier that accurately represents the situation. A successful run with zero notable results produces no notification at all (silence-by-default). A successful run with results uses `info`. An issue requiring human judgment uses `action_required`. A failure uses `error`.

## Approval-by-Reply

For agents at blast-radius Level 3 (write-unrestricted) or Level 4 (send-external), human approval is required before executing side effects. The approval flow uses Telegram's reply mechanism in the "approvals" thread.

**Approval request format:**

```
**APPROVAL REQUEST**

Agent: Report Sender
Action: Send daily summary to 3 tenant Telegram groups
Preview:
  - Arco Rooms Monthly Summary (April 2026)
  - 14 invoices processed, 12 matched, 2 pending
  - Total: EUR 3,247.80

Reply APPROVE to proceed or REJECT (with optional reason) to cancel.
Timeout: 60 minutes (configurable in governance.yaml)
```

**Response handling:**

| User Reply | Agent Behavior |
|-----------|---------------|
| APPROVE (or "si", "yes", "ok") | Proceed with the action |
| REJECT (or "no", "reject") | Skip the action, log rejection reason if provided |
| No reply within timeout | Do nothing (safe default). Log timeout. Send `action_required` notification |

**Timeout behavior:** On timeout, the agent does NOT auto-approve. It does nothing and logs the timeout. This is the safe default. The timeout duration is configurable in `governance.yaml` under `approvals.default_timeout_minutes` (default: 60).

## Voice Message Support

Telegram natively supports voice messages. Users can reply to approval requests or provide feedback using voice instead of text. This is not a custom AgentBloc feature; it leverages Telegram's built-in voice-to-text transcription.

When a user sends a voice message in reply to an approval request, Telegram provides a text transcription that the agent processes using the same reply-parsing logic as text responses. No additional configuration is required.

This is particularly useful for non-technical users who prefer speaking over typing, especially on mobile devices.

## Bot Setup Requirements

The Telegram bot must be configured before deployment:

1. **Create a bot** via @BotFather. Save the token.
2. **Store the token** in `.env` as `AGENTBLOC_TELEGRAM_BOT_TOKEN`. Never store the token in telegram.yaml or any version-controlled file.
3. **Create a supergroup** with "Topics" (forum mode) enabled.
4. **Add the bot** to the supergroup as an admin with "Manage Topics" permission.
5. **Create forum topics** for each domain (invoices, payments, operations, approvals).
6. **Record thread IDs** in telegram.yaml. Thread IDs can be obtained by sending a test message to each topic and inspecting the API response.
7. **Record the chat ID** (supergroup ID, a negative number) in telegram.yaml.

**Security:** The supergroup should be private. Only team members who should receive notifications and approve actions should be members. Supergroup admin controls membership, which controls who can reply to approval requests.

**telegram.yaml bot configuration:**

```yaml
bot:
  token_env: AGENTBLOC_TELEGRAM_BOT_TOKEN  # References .env variable, never the actual token
  chat_id: -1001234567890                    # Supergroup ID (negative number)
```

## Quick Reference

| Tier | Format | When to Use | Silence OK? |
|------|--------|-------------|-------------|
| `info` | Plain text | Successful run with notable results | Yes, if nothing notable |
| `action_required` | **Bold header** prefix | Needs human attention or decision | Never silent if triggered |
| `error` | ALERT emoji prefix | Failure or integrity risk | Never silent if triggered |

| Pattern | Rule |
|---------|------|
| Thread routing | By domain (invoices, payments, operations, approvals), not by agent |
| Silence-by-default | No notification unless something notable happened |
| Approval timeout | Do nothing (safe default), never auto-approve |
| Bot token | In .env only, referenced by env var name in telegram.yaml |
| Supergroup access | Private group, admin-controlled membership |
| Voice replies | Supported natively via Telegram transcription |
