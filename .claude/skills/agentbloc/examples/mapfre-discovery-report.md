---
schema_version: 1
service_slug: "mapfre-insurance-portal"
generated_at: "2026-04-22T14:30:00Z"
expires_at: "2026-07-21T14:30:00Z"
sha256: "a1b2c3d4e5f60718293041526374859607182930415263748596071829304152"
posture: B
tos_tier: TOS-AMBER
user_attestation_timestamp: "2026-04-22T14:25:00Z"
used_by:
  - gestor-documental
endpoints:
  - method: GET
    path: "/api/v1/policies/{policy_id}"
    api_classification: DOCUMENTED
    auth_type: oauth2
    observed_in_har: "har/session-1.har#entry-12"
    replay_status: VERIFIED
    sample_call: "curl -H 'Authorization: Bearer $MAPFRE_OAUTH_TOKEN' https://api.mapfre.es/v1/policies/ABC123"
    documented_at: "https://developers.mapfre.es/api/v1/policies"
    rate_limit: "120/min"
  - method: POST
    path: "/api/v1/claims"
    api_classification: DOCUMENTED
    auth_type: oauth2
    observed_in_har: "har/session-1.har#entry-18"
    replay_status: VERIFIED
    sample_call: "curl -X POST -H 'Authorization: Bearer $MAPFRE_OAUTH_TOKEN' -H 'Content-Type: application/json' -d '{...}' https://api.mapfre.es/v1/claims"
    documented_at: "https://developers.mapfre.es/api/v1/claims"
    rate_limit: "60/min"
  - method: GET
    path: "/internal/dashboard/claim-summary"
    api_classification: INTERNAL
    auth_type: session_cookie
    observed_in_har: "har/session-1.har#entry-47"
    replay_status: VERIFIED
    sample_call: "curl -H 'Cookie: mapfre_session=$SESSION_ID' https://www.mapfre.es/internal/dashboard/claim-summary"
  - method: GET
    path: "/internal/api/documents/pending"
    api_classification: INTERNAL
    auth_type: session_cookie
    observed_in_har: "har/session-1.har#entry-52"
    replay_status: VERIFIED
    sample_call: "curl -H 'Cookie: mapfre_session=$SESSION_ID' https://www.mapfre.es/internal/api/documents/pending"
  - method: POST
    path: "/internal/api/secure/submit"
    api_classification: INTERNAL-HARDENED
    auth_type: csrf_header
    observed_in_har: "har/session-1.har#entry-63"
    replay_status: UNVERIFIED
    sample_call: "curl -X POST -H 'Cookie: mapfre_session=$SESSION_ID' -H 'X-CSRF-Token: $CSRF_TOKEN' -H 'X-Requested-With: XMLHttpRequest' https://www.mapfre.es/internal/api/secure/submit"
    hardening_signal: "x-csrf-token custom header + x-requested-with: XMLHttpRequest + origin check on Referer"
auth_flow:
  login_url: "https://www.mapfre.es/login"
  session_cookie_name: "mapfre_session"
  mfa_required: false
  token_refresh_mechanism: "session cookie refresh via GET /internal/api/session/refresh every 15 minutes"
ui_selectors:
  login_form: "form#login-form"
  username_input: "input[name='username']"
  password_input: "input[name='password']"
  submit_button: "button[type='submit'].btn-login"
anti_bot_observations:
  detected: cloudflare-uam
  trigger: "initial navigation to /login returned Cloudflare JS challenge page"
  action_taken: degrade
pii_redaction_report:
  patterns_applied:
    - email
    - e164_phone
  matches_redacted: 7
  residual_match_scan: PASS
injection_scan_report:
  imperative_strings_flagged: 0
  base64_blobs_flagged: 2
  invisible_unicode_flagged: 0
  fresh_context_verification: PASS
---

# DISCOVERY-REPORT: Mapfre Insurance Portal

> Tool-provider disclaimer: AgentBloc is a general-purpose research tool. The user is solely responsible for lawful use. AgentBloc takes no position on whether any specific Discovery run is lawful in the user's jurisdiction.

## Endpoints

| # | method | path | api_classification | auth_type | replay_status |
|---|--------|------|---------------------|-----------|---------------|
| 1 | GET | /api/v1/policies/{policy_id} | DOCUMENTED | oauth2 | VERIFIED |
| 2 | POST | /api/v1/claims | DOCUMENTED | oauth2 | VERIFIED |
| 3 | GET | /internal/dashboard/claim-summary | INTERNAL | session_cookie | VERIFIED |
| 4 | GET | /internal/api/documents/pending | INTERNAL | session_cookie | VERIFIED |
| 5 | POST | /internal/api/secure/submit | INTERNAL-HARDENED | csrf_header | UNVERIFIED |

Distribution: 2 DOCUMENTED, 2 INTERNAL, 1 INTERNAL-HARDENED.

## Auth Flow

Login URL: `https://www.mapfre.es/login`. The portal uses a session-cookie auth scheme (`mapfre_session`) with a 15-minute idle timeout and automatic refresh via `GET /internal/api/session/refresh`. MFA is NOT required for the standard broker account tier (verified during HAR capture). OAuth2 is available for the `/api/v1/*` documented surface via `https://auth.mapfre.es/oauth/authorize`; bearer tokens refresh on the 1-hour mark.

## Sample Calls (curl)

Documented endpoints (from developers.mapfre.es/v1 docs):

```
curl -H 'Authorization: Bearer $MAPFRE_OAUTH_TOKEN' \
  https://api.mapfre.es/v1/policies/ABC123
```

```
curl -X POST \
  -H 'Authorization: Bearer $MAPFRE_OAUTH_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"policy_id":"ABC123","claim_type":"property_damage"}' \
  https://api.mapfre.es/v1/claims
```

Internal endpoints (session-cookie auth from captured HAR):

```
curl -H 'Cookie: mapfre_session=$SESSION_ID' \
  https://www.mapfre.es/internal/dashboard/claim-summary
```

INTERNAL-HARDENED endpoint (requires second attestation per D-53; UNVERIFIED because replay triggered a fresh CSRF token challenge not captured in HAR):

```
curl -X POST \
  -H 'Cookie: mapfre_session=$SESSION_ID' \
  -H 'X-CSRF-Token: $CSRF_TOKEN' \
  -H 'X-Requested-With: XMLHttpRequest' \
  https://www.mapfre.es/internal/api/secure/submit
```

## UI Selectors

Login form: `form#login-form`. Username: `input[name='username']`. Password: `input[name='password']`. Submit: `button[type='submit'].btn-login`.

## Rate Limit Observations

Documented endpoints: `/api/v1/policies/*` is 120/min (documented at developers.mapfre.es/rate-limits); `/api/v1/claims` is 60/min. Internal endpoints: no public documentation; observed 429 with `Retry-After: 30` after approximately 40 requests/minute burst on `/internal/api/documents/pending`. Subsequent Ralph retry backed off to 1 req/sec without adjustment.

## Anti-Bot Observations

Cloudflare UAM (Under Attack Mode) detected on initial navigation to `/login`. Challenge page served JavaScript that required 5-second delay before submitting. Switched to Patchright (CDP-leak patch) per browser-stack.md posture B handling. No further challenges on subsequent navigation. No CAPTCHA, no DataDome, no behavioral fingerprinting detected. Posture locked at B (Detected-but-navigable); Patchright was sufficient.

## Evidence and Signature

User attestation: 2026-04-22T14:25:00Z (resolves to OPT_IN_LEDGER.jsonl line for service_slug `mapfre-insurance-portal`; ledger line SHA256 matches). Jurisdiction: ES. ToS tier classified TOS-AMBER (silent on automation, no explicit prohibition). Anti-bot posture: B.

SHA256 of body (excluding the sha256 frontmatter field): `a1b2c3d4e5f60718293041526374859607182930415263748596071829304152`.

This report is classified `[DISCOVERED]`, subordinate to v1.0 `[VERIFIED]` tier. Phase 12 Deploy Pipeline will surface this tier distinction in DEPLOY-REPORT.md per D-39 inheritance.

PII redaction summary: 7 matches redacted (email and e164_phone patterns). Residual match scan: PASS. Injection scan: 2 base64 blobs flagged (both were session token fingerprints, not injection payloads; fresh-context verification confirmed NO). See [references/output-firewall.md](../references/output-firewall.md) for the full pipeline.

Fixture notes: this file is the canonical happy-path fixture for Phase 16 end-to-end TAP validation. All PII in this fixture is synthetic (emails at `example.invalid`; phones in the `+1-555-0100` documentation range; no real IBANs/SSNs/CCs). Fixture family linkage: `used_by: [gestor-documental]` matches the agent ID declared in `examples/arco-rooms-agent-profiles.yaml` and consumed in `examples/arco-rooms-integration-manifest.yaml`.
