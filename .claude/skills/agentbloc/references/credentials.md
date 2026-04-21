# Credential Management

> Security reference loaded by SKILL.md during Integration Analysis (Phase 3) and Deployment (Phase 5).

## Table of Contents

- [When This Applies](#when-this-applies)
- [Credential Decision Tree](#credential-decision-tree)
- [Rotation Policy](#rotation-policy)
- [Log Redaction Rules](#log-redaction-rules)
- [Secret Storage Pattern](#secret-storage-pattern)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file during Integration Analysis (Phase 3) when evaluating service credentials for each integration, and during Deployment (Phase 5) when generating governance.yaml and .env.example. Every external service an agent connects to goes through the decision tree below.

## Credential Decision Tree

For each service integration, follow these steps in order:

**Step 1: Does the service offer OAuth 2.0?**
- YES: Use OAuth with minimum scopes. Request only the permissions the agent needs (e.g., `read:orders` not `admin`). Prefer short-lived access tokens with refresh token rotation.
- NO: Continue to Step 2.

**Step 2: Does the service offer scoped API keys (read-only, write-limited)?**
- YES: Use the most restrictive scope that covers the agent's needs. A collector agent reading invoices uses a read-only key, not a read-write key.
- NO: Continue to Step 3.

**Step 3: Service only offers admin/full-access tokens.**
- Document the risk in the agent's blast-radius scoring (see blast-radius.md).
- Set `requires_approval: true` for this agent in agent.yaml.
- Add token revocation as the first action in the incident response runbook.
- Add a note in governance.yaml: `credential_risk: admin_token_only`.

**Decision summary:** OAuth > scoped API key > admin token. Always prefer the option that gives the agent the least privilege needed to do its job.

## Rotation Policy

Rotation frequency depends on credential type and the data classification of what the agent processes:

| Credential Type | Public Data | PII | PHI / Financial |
|-----------------|-------------|-----|-----------------|
| OAuth tokens | Auto-refresh (standard) | Auto-refresh (standard) | Auto-refresh + session limit 1h |
| Scoped API keys | Rotate every 90 days | Rotate every 30 days | Rotate every 14 days |
| Admin tokens | Rotate every 30 days | Rotate every 14 days | Rotate every 7 days + 2FA |
| Webhook secrets | Rotate every 90 days | Rotate every 30 days | Rotate every 14 days |

Rotation is documented in governance.yaml and surfaced as a scheduled reminder via Telegram.

## Log Redaction Rules

Audit logs record agent actions but must not become a secondary store of sensitive credentials. Apply these rules to every log entry:

**ALWAYS redact (replace with marker):**
- API keys, OAuth tokens, refresh tokens
- Passwords, webhook secrets, session tokens
- Any string matching known credential patterns

Replacement pattern: `[REDACTED:api_key]`, `[REDACTED:oauth_token]`, `[REDACTED:password]`

**HASH instead of logging raw values:**
- User emails: `hash:a1b2c3d4` (SHA-256, first 8 characters)
- Account IDs: `hash:e5f6g7h8` (SHA-256, first 8 characters)
- Any PII reference that appears in log context

**KEEP as-is (safe to log):**
- Service names (e.g., "shopify", "xero")
- Endpoint URLs without query parameters
- HTTP status codes
- Timestamps and correlation IDs
- Agent names and action types

## Secret Storage Pattern

**Primary:** Environment variables loaded from a `.env` file (gitignored).

**Template:** A `.env.example` file is committed to the repository showing required variables without values:

```
# .env.example -- copy to .env and fill in values
AGENTBLOC_SHOPIFY_API_KEY=
AGENTBLOC_XERO_CLIENT_ID=
AGENTBLOC_XERO_CLIENT_SECRET=
AGENTBLOC_TELEGRAM_BOT_TOKEN=
AGENTBLOC_GOOGLE_OAUTH_CLIENT_ID=
AGENTBLOC_GOOGLE_OAUTH_CLIENT_SECRET=
```

**Naming convention:** `AGENTBLOC_{SERVICE}_{CREDENTIAL_TYPE}`

Examples:
- `AGENTBLOC_SHOPIFY_API_KEY`
- `AGENTBLOC_STRIPE_SECRET_KEY`
- `AGENTBLOC_XERO_CLIENT_ID`

**agent.yaml reference:**

```yaml
credentials:
  source: env
  key: AGENTBLOC_SHOPIFY_API_KEY
  type: scoped_api_key
  scope: read_orders
  rotation_days: 30
```

Secrets are injected at runtime via environment variables. They never appear in agent prompts, YAML config values, or state files.

## Quick Reference

| Credential Type | Preferred Approach | Blast-Radius Impact | Approval Required |
|-----------------|--------------------|---------------------|-------------------|
| OAuth 2.0 | Always use when available | Lowest (scoped, auto-expiring) | No |
| Scoped API key | Use when OAuth unavailable | Low-Medium (scope-limited) | No |
| Admin token | Last resort only | High (full access) | Yes |
| Webhook secret | Rotate per schedule | Low (inbound validation only) | No |
