# PII Redaction — Arco Rooms

> What counts as PII for this team + Spain-specific patterns.
> Mandatory before any log/state/Telegram emission (with one
> documented exemption: per-owner Telegram bodies).

## Data classification

Phase 1 of AgentBloc surfaced this team's data classes:

| Class | Examples | Regulatory implication |
|---|---|---|
| Tenant PII | Names, addresses, DNI/NIE, phone numbers, emails | GDPR mandatory |
| Owner PII | Names, IBAN, contact info | GDPR mandatory |
| Financial | Invoice amounts, payment status, bank accounts | GDPR + financial confidentiality |
| Authentication | API keys, OAuth tokens, PSD2 consent tokens, Telegram bot token | Never logged |

Compliance posture:

- **GDPR**: yes (Spain — EU member)
- **HIPAA**: no
- **PCI-DSS**: no (no card numbers — bank transfers only)
- **LOPDGDD** (Spain implementation): yes (covered by GDPR + Spain-specific DNI/NIE patterns below)

## Redaction patterns (all mandatory unless exempted)

### Email addresses

Pattern: `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`
Replace with: `<email-redacted>`

### Phone numbers

Pattern (E.164 + Spain national):
`\+?(34|0034)?[\s-]?[6789]\d{2}[\s-]?\d{3}[\s-]?\d{3}|\+?[0-9]{1,3}[-. ]?\(?[0-9]{1,4}\)?[-. ]?[0-9]{1,4}[-. ]?[0-9]{1,9}`
Replace with: `<phone-redacted>`

### IBAN / SEPA

Pattern: `[A-Z]{2}[0-9]{2}[A-Z0-9]{10,30}`
Replace with: `<iban-redacted>` (or last-4 visible on owner messages
per exemption rules below)

### Spain DNI

Pattern: `[0-9]{8}[A-HJ-NP-TV-Z]` (8 digits + checksum letter)
Replace with: `<dni-redacted>`

### Spain NIE (foreign residents)

Pattern: `[XYZ][0-9]{7}[A-HJ-NP-TV-Z]`
Replace with: `<nie-redacted>`

### Authentication tokens

Pattern: long alphanumeric strings (32+ chars, no spaces) typical of
API keys, OAuth tokens, JWTs.
Replace with: `<token-redacted>`

### Long free text

Truncate any single field > 200 chars to first 100 + `[truncated]`.

## Order of operations

The redactor runs patterns in this order:

1. Tokens (longest non-whitespace first)
2. IBANs
3. Spain DNI / NIE (region-specific)
4. Phone numbers
5. Email addresses
6. Long free text (truncate)

Earlier patterns shouldn't eat later ones; sequential apply with no
overlap by design.

## Special rule: per-owner Telegram bodies

Per [`recepcionista/blast-radius.md`](../agents/recepcionista/blast-radius.md):
the OWNER MESSAGE BODY (not the audit log line about that body) is
EXEMPT from base GDPR redaction because the owner is the lawful
recipient of their tenants' data per the property management
contract.

Exemption applies ONLY to:
- The `text` parameter of `mcp__telegram-mcp__send_message` when
  `thread_id` matches a known per-owner thread in registry.yaml

Exemption does NOT apply to:
- The audit log line about that send (PII-redacted in `args_summary`)
- The approval-router prompt to Pablo (PII-redacted in payload preview)
- Any other log/state/inter-agent file

DNI/NIE always redacted EVEN in exempt owner messages (extra
guardrail).

IBAN truncated to last 4 in owner messages (e.g., `ES**...**1234`).

## What is NOT redacted

These fields appear unredacted, deliberately:

- `correlation_id` — synthetic; safe by design
- `agent_id` — public identifier (3 known values)
- `tool` name — vendor + operation, no PII
- `result` enum — finite vocabulary
- `timestamp` — required for forensics

## Testing the redactor

Build session writes tests asserting:

1. Each pattern redacts known fixtures (Spain-specific: DNI
   `12345678Z`, NIE `X1234567L`, IBAN `ES7621000418401234567890`)
2. Combined inputs (multiple patterns in one string) all redact
3. Edge cases: empty string, null, integer, nested object
4. Performance: redactor handles a typical args_summary in < 5ms
5. Exemption rule: per-owner Telegram body preserves names, redacts
   DNI/NIE, truncates IBAN to last 4

Reference impl tests live in
`runtime/reference-impl/tests/redact_test.sh`.

## Right to erasure (GDPR Article 17)

If a tenant requests erasure, the build session implements:

1. Identify all log lines, state files, and inboxes referencing the
   subject (by hashed identifier or correlation_id chain)
2. Tombstone entries (replace content with `<erased>` rather than
   deleting; preserves log integrity)
3. Document the action in audit log per Article 30
4. Notify the property owner (their tenant has exercised this right)

Manual runbook only — agents do NOT invoke erasure themselves.

## Cross-references

- Audit trail: [`audit-trail.md`](audit-trail.md)
- Approval protocol: [`approval-protocol.md`](approval-protocol.md)
- AgentBloc references: `references/data-classification.md`,
  `references/gdpr-patterns.md`, `references/output-firewall.md`
