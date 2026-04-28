# Minimum-Viable Endpoints — bank-mcp

> Wrapper exposes ONLY these endpoints across the 4 Spanish banks.
> Read-only PSD2 access; no write/payment-initiation.

## Included

| Endpoint | Method | Used by | Purpose | Blast |
|---|---|---|---|---|
| `/v1/accounts/{accountId}/transactions` | GET | gestor-cobros | List transactions for date range; covers all 4 banks via dispatch | L2 (read external; cached locally) |
| `/v1/accounts/{accountId}/balances` | GET | gestor-cobros | Get current balance; rarely used (sanity check) | L1 |

Tool names exposed: `list_transactions(bank_id, account_id, date_from, date_to)`
and `get_balance(bank_id, account_id)`.

## Excluded (least-privilege)

These PSD2 endpoints exist in Berlin Group spec but are NOT in this wrapper:

| Endpoint | Method | Reason for exclusion |
|---|---|---|
| `/v1/payments` | POST | PIS (Payment Initiation Service) — out of agent envelope; agent never authorizes payments |
| `/v1/accounts/{accountId}/transactions/{transactionId}` | DELETE | No delete operation in PSD2 spec; placeholder for clarity |
| `/v1/consents` | POST | Consent management — done manually at install time, not at runtime |
| `/v1/funds-confirmations` | POST | PIIS (Payment Instrument Issuer Service) — out of envelope |

If future requirements add payment initiation (e.g., automated rent
disbursement to owners), AgentBloc Phase 6 revisits this subset and
the agent's blast-radius envelope.

## Authentication

| Property | Value |
|---|---|
| Pattern | OAuth 2.0 + PSD2 SCA (Strong Customer Authentication) |
| Header | `Authorization: Bearer <consent_token>` per bank |
| Required scope | `accounts.read`, `transactions.read` (Berlin Group naming) |
| Refresh policy | 90-day consent cycle; build session re-runs SCA flow at expiry |

**OAuth dance** — build session completes once per bank at install:

1. Visit bank's developer portal sandbox; complete TPP registration
2. Receive `CLIENT_ID` + `CLIENT_SECRET`
3. Initiate consent: `POST /v1/consents` with desired account list
4. Complete SCA challenge (typically redirect to bank's consent UI;
   user approves with mobile app or SMS)
5. Receive `CONSENT_TOKEN` valid 90 days; store in `.env` as
   `<BANK>_PSD2_CONSENT_TOKEN`

Repeat for all 4 banks. Each bank's SCA UI is slightly different;
document any per-bank quirks in this folder.

## Rate limits

| Limit | Value (Berlin Group default) | Wrapper response |
|---|---|---|
| Per-account | 4 reads/day (frequent reads beyond this trigger SCA challenge) | Cache aggressively; one daily read is well within |
| Per-TPP per bank | varies; typically generous | Honor `Retry-After` |
| Burst | varies | Queue + drain |

The team's nightly read pattern (1 list_transactions per account per
day) is well within the free-tier limits. Document each bank's
specific limits in this folder if they're stricter than 4/day.

## Pagination

| Property | Value |
|---|---|
| Pattern | Offset-based (`offset` + `limit` query params) |
| Default page size | 50 transactions |
| Max page size | 200 |

Wrapper paginates internally; agent receives a flat array.

## Webhook hand-off

Not applicable — PSD2 transaction reads are pull-based, not webhook-
driven. (PSD2 does support webhook notifications via "balance below
threshold" but it's not required for daily payment matching.)

## Cross-references

- `README.md` — tier rationale
- `BUILD.md` — build steps
- `references/mcp-synthesis.md` — synthesis protocol
- `governance/blast-radius.md` — read-only L2 envelope
- `governance/audit-trail.md` — PSD2 GDPR Article 30 logging
