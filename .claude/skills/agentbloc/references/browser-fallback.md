# Browser Fallback Protocol

> Loaded by SKILL.md at Phase 3 entry alongside [phase-3-integration.md](phase-3-integration.md), [mcp-integration-protocol.md](mcp-integration-protocol.md), [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md), [inventory-schema.md](inventory-schema.md), and [browser-stack.md](browser-stack.md). Defines Step 4 of the 4-step MCP search: when Steps 1-3 (existing `.mcp.json`, ecosystem registry, wrapper generation) exhaust without resolution, Phase 3 spawns the `browser-discovery` subagent to reverse-engineer the target service via Playwright MCP and emit a schema-locked, SHA256-signed DISCOVERY-REPORT.md. Detect-and-degrade posture only (no fingerprint evasion, no CAPTCHA solving). Posture C (hardened anti-bot) halts cleanly via DISCOVERY-BLOCKED-REPORT.md.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Flow Diagram](#flow-diagram)
- [Step 1: Per-Service Legal Opt-In Gate](#step-1-per-service-legal-opt-in-gate)
- [Step 2: Subagent Invocation](#step-2-subagent-invocation)
- [Step 3: HAR Capture with Checkpoint State](#step-3-har-capture-with-checkpoint-state)
- [Step 4: Endpoint Classification](#step-4-endpoint-classification)
- [Step 5: Output Firewall Pass](#step-5-output-firewall-pass)
- [Step 6: DISCOVERY-REPORT.md Emission](#step-6-discovery-reportmd-emission)
- [Posture Classification](#posture-classification)
- [Ralph Retry Protocol](#ralph-retry-protocol)
- [Halt Protocol for Browser Discovery](#halt-protocol-for-browser-discovery)
- [Quick Reference](#quick-reference)

## When This Applies

Claude loads this file at Phase 3 entry (see SKILL.md Phase 3). The `browser-discovery` subagent is spawned ONLY after Steps 1-3 of [mcp-integration-protocol.md](mcp-integration-protocol.md) exhaust for a given tool (no existing `.mcp.json` entry, no ecosystem registry match, no viable wrapper generation). Output is written to `.agentbloc/discovery/<service-slug>/DISCOVERY-REPORT.md` per the schema defined in [discovery-report-schema.md](discovery-report-schema.md); the corresponding manifest entry carries `resolution_method: browser-fallback` (bounded enum value from [inventory-schema.md](inventory-schema.md)).

Three resume states apply per D-50:

- **Fresh run:** no prior `.agentbloc/discovery/<service-slug>/state.json`; walk Steps 1 through 6 in order.
- **Resume within 4 hours:** state.json exists AND `now() < expires_at`; skip phases already recorded as complete, resume at the current `phase` value.
- **Resume after 4 hours:** state.json exists AND `now() >= expires_at`; the 4-hour staleness ceiling per D-50 triggered; re-require Step 1 opt-in re-attestation before any browser work.

This file is imperative (step-by-step flow Claude walks); [browser-stack.md](browser-stack.md) is declarative (pinned versions plus anti-bot deny-list Claude consults); [discovery-report-schema.md](discovery-report-schema.md) is the output contract (YAML frontmatter plus markdown body plus validation checklist); [output-firewall.md](output-firewall.md) is the runtime firewall loaded inside the subagent's forked context; [legal-posture.md](legal-posture.md) is the jurisdictional reference. Together these five files cover Phase 3 Step 4 top to bottom.

## Flow Diagram

```
                     tool entry from agent-profiles.yaml
                 (Steps 1-3 of mcp-integration-protocol exhausted)
                                     │
                                     ▼
        ┌────────────────────────────────────────────────────┐
        │  Step 1: Legal Opt-In Gate (per service)           │
        │    ToS fetch ─► classify GREEN/AMBER/RED           │
        │    user signs DISCOVERY-LICENSE-NOTICE.md          │
        │    append OPT_IN_LEDGER.jsonl ────► proceed        │
        │    user declines ─► abort, no browser launch       │
        └────────────────────────────────────────────────────┘
                                     │
                                     ▼
        ┌────────────────────────────────────────────────────┐
        │  Step 2: Subagent Invocation                       │
        │    Task() context:fork ─► browser-discovery        │
        │    TARGET.md + budget + resume state.json          │
        └────────────────────────────────────────────────────┘
                                     │
                                     ▼
        ┌────────────────────────────────────────────────────┐
        │  Step 3: HAR Capture + Checkpoint State            │
        │    Playwright session ─► har/session-N.har         │
        │    state.json expires_at = now + 4h                │
        │    Posture A ─► stock Playwright                   │
        │    Posture B ─► Patchright (CDP-leak patch)        │
        │    Posture C ─► HALT + DISCOVERY-BLOCKED-REPORT.md │
        └────────────────────────────────────────────────────┘
                                     │
                                     ▼
        ┌────────────────────────────────────────────────────┐
        │  Step 4: Endpoint Classification                   │
        │    DOCUMENTED / INTERNAL / INTERNAL-HARDENED       │
        │    replay via curlconverter ─► VERIFIED/UNVERIFIED │
        └────────────────────────────────────────────────────┘
                                     │
                                     ▼
        ┌────────────────────────────────────────────────────┐
        │  Step 5: Output Firewall Pass                      │
        │    injection detector ─► FAIL ─► Halt Protocol     │
        │    PII redaction ──────► FAIL ─► Halt Protocol     │
        │    fresh-context Task() ► YES ─► Halt Protocol     │
        └────────────────────────────────────────────────────┘
                                     │
                                     ▼
        ┌────────────────────────────────────────────────────┐
        │  Step 6: DISCOVERY-REPORT.md Emission              │
        │    Validation Checklist (8 checks)                 │
        │    SHA256 over body ─► frontmatter                 │
        │    silent write + rendered summary review          │
        └────────────────────────────────────────────────────┘
                                     │
                                     ▼
             .agentbloc/discovery/<service-slug>/DISCOVERY-REPORT.md
                                     │
                                     ▼
        manifest entry: resolution_method: browser-fallback
```

Note on emission: use ASCII box characters (`┌ ┐ └ ┘ │ ─ ► ▼`) not Unicode em-dashes. The diagram must render in any plain-text viewer.

## Step 1: Per-Service Legal Opt-In Gate

**Action:** Fetch the target service's Terms of Service in-session via the subagent's Playwright browser (never rely on training data for legal content). SHA256-hash the fetched excerpt. Classify `tos_tier` via keyword grep on the fetched content for the triggers `bot`, `automated`, `scrape`, `reverse engineer`, `API`, `circumvent`: zero matches => `TOS-GREEN`; silent or ambiguous phrasing => `TOS-AMBER`; explicit prohibition => `TOS-RED`. Write `.agentbloc/discovery/<service-slug>/DISCOVERY-LICENSE-NOTICE.md` with the ToS URL, the fetched-in-session excerpt, the SHA256 hash (so tampering is detectable), the jurisdictional-risk banner (per [legal-posture.md](legal-posture.md)), the user attestation text, and the tool-provider disclaimer. Render the notice to the user for explicit attestation.

**Input:** target service URL + calling agent context from `.agentbloc/team/agent-profiles.yaml` (agent-id, tools[] entry that triggered Step 4).

**If accepted:** Append a JSON line to `.agentbloc/discovery/OPT_IN_LEDGER.jsonl` with exactly this shape (per D-46): `{"service_slug": "<slug>", "opted_in_at": "<ISO-8601>", "ip": "<ip>", "jurisdiction": "<ISO-3166>", "tos_tier": "<tier>", "tos_url": "<url>", "tos_excerpt_sha256": "<64-hex>", "attestation": "I am the authorized account holder..."}`. Populate `state.json` `user_attestation` with timestamp, ip, jurisdiction. Proceed to Step 2.

**If declined:** Abort the run. No browser launch. `state.json` status stays `opt-in-pending`. Surface the specific gap to the user in one sentence so they know which attestation line they declined.

**Arco Rooms example:** `mapfre-insurance-portal` ToS is silent on automation (no `bot` or `automated` keyword match) and therefore classifies as `TOS-AMBER`. User attests. Ledger line appended. Browser proceeds to Step 2.

**Rationale (D-37 + D-46):** This is approval-gated execution: Claude NEVER launches the browser before DISCOVERY-LICENSE-NOTICE.md is signed AND OPT_IN_LEDGER.jsonl receives a fresh entry AND `user_attestation_timestamp` populates state.json. The ledger provides the GDPR Article 30 record-of-processing trail. Per-project (not per-machine) scope so the record survives session boundaries and commits to the user's repository for audit.

## Step 2: Subagent Invocation

**Action:** Spawn the `browser-discovery` subagent via `Task()` with `context: fork`. Pass `.agentbloc/discovery/<service-slug>/TARGET.md` (scoped target, browser budget, retry allowance, 5-10 representative user flows pulled from `agent-profiles.yaml` outputs.schema hints). The subagent's tool scope is fixed at definition time (D-43): Read, Grep, Glob, Write (restricted by its `<write_constraint>` block to `.agentbloc/discovery/<service-slug>/*` plus `.agentbloc/discovery/OPT_IN_LEDGER.jsonl`), plus the Playwright MCP tool set (browser_navigate, browser_snapshot, browser_evaluate, browser_network_requests, browser_take_screenshot, browser_click, browser_type, browser_wait_for, browser_handle_dialog, browser_file_upload, browser_press_key, browser_select_option, browser_tabs). NO Bash, NO WebFetch, NO other MCPs.

**Input:** TARGET.md + latest `OPT_IN_LEDGER.jsonl` entry for the service + `state.json` if resuming.

**If fresh:** Create `.agentbloc/discovery/<service-slug>/` directory. Initialize `state.json` with `status: har-capturing`, `started_at: now()`, `expires_at: now() + 4h`.

**If resuming within 4 hours:** Read `state.json`; skip phases already recorded as complete; resume at the phase named in `state.json.phase`.

**If resuming after 4 hours:** `state.json.expires_at` is stale per D-50; halt the subagent invocation; re-run Step 1 so the user re-attests (SMS/2FA latency defensible ceiling).

**Rationale (D-21 + D-43):** Forked context isolates captured content from the main session, preventing injection payloads in captured bodies from leaking back into the main agent's context. The no-Bash posture means the subagent CANNOT execute arbitrary shell commands: the browser is the only side-effect surface, so every HTTP call is guaranteed to be captured in the HAR. Scoped writes prevent filesystem escape. No WebFetch eliminates the possibility of bypassing the HAR capture layer.

## Step 3: HAR Capture with Checkpoint State

**Action:** The subagent walks the portal via `mcp__playwright__browser_navigate` plus `browser_snapshot` plus `browser_network_requests` for the 5-10 representative flows named in TARGET.md (typically: login, landing dashboard, one or two data list views, one detail view, one search, and a logout). HAR written to `.agentbloc/discovery/<service-slug>/har/session-N.har` (numbered sequentially; a single run may capture multiple HAR files if the session splits across retries). After each phase transition the subagent updates `state.json`.

**Input:** TARGET.md flow list + credentials resolved from `.env` (per D-38, the subagent auto-appends any missing credential placeholders to `.env.example` before halting for user action).

**state.json shape (reference D-50; full Status bounded enum in [discovery-report-schema.md](discovery-report-schema.md) § Status Bounded Enum):** the `phase` field walks the lifecycle `opt-in-pending -> har-capturing -> endpoint-classifying -> replay-validating -> pii-redacting -> injection-checking -> report-writing -> complete` with terminal states `blocked` (posture C, injection detector, ToS-RED) and `failed` (PII residual match, retry budget exhaustion, credential gap).

**4-hour expires_at:** resume logic reads `state.json`; `now() < expires_at` => skip completed phases, resume at current phase; `now() >= expires_at` => require Step 1 re-attestation.

**Posture detection during HAR capture:** See the Posture Classification section below. The detection points are: Cloudflare UAM challenge page on initial navigation => posture B plus Patchright invocation for the CDP-leak patch; DataDome / PerimeterX / Kasada / Akamai Bot Manager / recaptcha_v3 / hcaptcha / behavioral fingerprinting signals => posture C plus immediate HALT. Posture is recorded in `state.json.posture`.

## Step 4: Endpoint Classification

**Action:** The subagent iterates every unique request observed in the HAR and classifies each into one of three tiers per D-53: DOCUMENTED, INTERNAL, or INTERNAL-HARDENED. The canonical enum definition (criteria plus required sub-fields per tier) lives in [discovery-report-schema.md](discovery-report-schema.md) § API Classification Bounded Enum; do NOT duplicate the enum here.

**Classification summary:**

- **DOCUMENTED:** path matches a fetched `/docs`, `/developers`, OpenAPI spec, or Postman collection URL; `documented_at` field populated with the exact doc URL.
- **INTERNAL:** no doc match; backs a first-party UI; auth via session cookie or CSRF header; `observed_in_har` populated.
- **INTERNAL-HARDENED:** INTERNAL plus hardening signal (`x-requested-with: XMLHttpRequest`, custom `x-csrf-token`, non-browser origin check, or `x-internal: true` header); requires second user attestation in the DISCOVERY-LICENSE-NOTICE.md addendum.

**Replay validation:** use `curlconverter` to convert each HAR entry to a curl invocation; replay the curl with the captured session cookie/bearer; stamp `replay_status: VERIFIED` on 2xx response with matching shape, `replay_status: UNVERIFIED` on 2xx response with shape drift, or `replay_status: FAILED` on any 4xx/5xx that the original HAR did not encounter.

State.json transitions: `endpoint-classifying` then `replay-validating` then `pii-redacting`.

**Arco Rooms example:** mapfre-insurance-portal yields 5 endpoints: 2 DOCUMENTED (public OAuth-backed `/api/v1/policies` and `/api/v1/claims`) + 2 INTERNAL (session-cookie-backed `/internal/dashboard/*`) + 1 INTERNAL-HARDENED (CSRF-header-plus-XHR `/internal/api/secure/submit`). The INTERNAL-HARDENED endpoint triggers the second-attestation requirement.

## Step 5: Output Firewall Pass

**Action:** Delegate the full pipeline to [output-firewall.md](output-firewall.md). The firewall applies three gates to every captured HAR body (request and response), every `browser_snapshot` result, and any captured text destined for DISCOVERY-REPORT.md body:

- **Injection detector (three-layer regex):** imperative-string + base64-blob + invisible-Unicode. See [output-firewall.md](output-firewall.md) § Three-Layer Injection Detector.
- **Fresh-context Task() verification:** spawned on ANY layer flag; returns YES/NO. YES => HALT. See [output-firewall.md](output-firewall.md) § Fresh-Context Verification Pass.
- **PII redaction pipeline:** 5 patterns ordered more-specific-first (IBAN, SSN, Luhn CC, E.164 phone, email) + post-redaction verification scan. See [output-firewall.md](output-firewall.md) § PII Redaction Pipeline.

Firewall results populate `injection_scan_report` and `pii_redaction_report` in the DISCOVERY-REPORT.md YAML frontmatter. Any failure (layer flag with YES from fresh-context; or any residual regex match on redacted output) triggers the Halt Protocol below.

state.json transitions: `injection-checking` then `report-writing`.

## Step 6: DISCOVERY-REPORT.md Emission

**Action:** Delegate to [discovery-report-schema.md](discovery-report-schema.md) § Emission Protocol. Summary:

1. Walk the 8-check Validation Checklist from the schema file in order.
2. Compute SHA256 over the body (excluding the `sha256:` frontmatter line itself).
3. Insert the computed SHA256 into the frontmatter.
4. Render a posture + tos_tier + endpoint-count-by-classification summary to the user per D-14 (user sees the rendered summary; the raw YAML plus markdown body is NEVER shown).
5. After user confirmation, write silently to `.agentbloc/discovery/<service-slug>/DISCOVERY-REPORT.md`.
6. Update the calling manifest entry to `resolution_method: browser-fallback`, `status: verified` when every REQUIRED check passed.
7. Set `state.json.status: complete`.

The rendered summary is a 5-column table (`| # | method | path | api_classification | replay_status |`) plus a two-line header showing `posture: <X>`, `tos_tier: <Y>`, `endpoints: <N> DOCUMENTED, <M> INTERNAL, <K> INTERNAL-HARDENED`. This is what the user confirms before silent write per D-14.

## Posture Classification

Posture is detected during HAR capture (Step 3) and recorded in `state.json.posture` + the DISCOVERY-REPORT.md `posture` frontmatter field. Three values apply per D-49:

| Posture | Signal | Action |
|---|---|---|
| **A - Friendly** | OAuth login, public API docs, no WAF challenge page, ToS-GREEN | Proceed with stock Playwright + MCP. Patchright NOT invoked. |
| **B - Detected-but-navigable** | Cloudflare UAM (simple JS challenge), rate-limit cooldowns, session cookies required, ToS-AMBER | Switch to Patchright for the CDP-leak patch. Rate-limit with exponential backoff. NO fingerprint adjustment. |
| **C - Hardened** | DataDome / PerimeterX / Kasada / Akamai Bot Manager / CAPTCHA challenge / behavioral fingerprinting / TOS-RED | **HALT immediately.** Emit `.agentbloc/discovery/<service-slug>/DISCOVERY-BLOCKED-REPORT.md` naming the detected anti-bot vendor + the trigger URL. Do NOT switch tools. Do NOT retry. Update manifest entry to `status: failed`, `failure_reason: "Posture C hardened anti-bot detected: <vendor>"`. |

Posture C is TERMINAL: no fallback path, no tool-switch, no retry. The v2.0 scope does not support manual session-cookie handoff past Posture C (deferred to v2.5+). See [browser-stack.md](browser-stack.md) for the stock-Playwright vs Patchright-only decision matrix per posture. Cross-reference: the posture bounded enum is canonically defined in [discovery-report-schema.md](discovery-report-schema.md) § Posture Bounded Enum.

## Ralph Retry Protocol

Per D-55, retries are strictly timing-adjustments, never fingerprint-adjustments.

- **Budget:** from `governance.yaml` `browser_discovery.retry_budget` (default 3). Hard cap of 5 attempts regardless of the governance.yaml value (prevents runaway loops).
- **Backoff:** exponential 1s, 4s, 16s (and beyond if the budget is raised). Purely temporal; no header, User-Agent, TLS-fingerprint, or cookie-jar tweaks between attempts.
- **State record:** each retry appends an entry to `state.json.retries[]` with this shape: `{"attempt_number": <N>, "attempted_at": "<ISO-8601>", "failure_mode": "<string>", "backoff_ms_before_next": <integer>}`.
- **Covered failure modes:** transient network errors, 429 rate limits, 5xx upstream errors, timing-sensitive UI loads that missed a selector on first pass.
- **NOT covered (terminal, no retry):** posture C halt, injection detector YES from fresh-context verification, PII residual match on post-redaction scan, user-declined opt-in. These route directly to the Halt Protocol.

The "timing-only" constraint is load-bearing. Any retry that changes the browser's fingerprint, headers, or identity crosses into detect-and-bypass territory, which the project's deny-and-degrade policy (see [browser-stack.md](browser-stack.md) Anti-Bot Deny-List) forbids.

## Halt Protocol for Browser Discovery

When any halt-trigger fires, Claude executes the following in one turn:

1. Write `.agentbloc/discovery/<service-slug>/DISCOVERY-BLOCKED-REPORT.md` naming the specific trigger:
   - Posture C: detected vendor + trigger URL + screenshot path (if captured).
   - Injection detector YES: flagged layer (1 / 2 / 3) + the suspicious body quoted inside ` ```untrusted-data ... ``` ` code fences + the fresh-context Task() response verbatim.
   - PII residual match: the specific regex pattern that matched + the 20-char context window (no full PII leak).
   - Retry budget exhausted: final `failure_mode` + retries[] summary.
2. Update `state.json.status` to `blocked` (posture C / injection) or `failed` (PII residual / retry exhausted / user-declined opt-in). Populate `state.json.last_error` with the one-line reason.
3. Update the manifest entry: `resolution_method: browser-fallback`, `status: failed`, `failure_reason: "<specific trigger>"`.
4. Surface a targeted conversation to the user. Template:

> "Discovery for `<service-slug>` halted at `<phase>`: `<specific-failure>`. See `.agentbloc/discovery/<service-slug>/DISCOVERY-BLOCKED-REPORT.md` for the quoted trigger. To resolve: <path-1>, or <path-2>. Which do you prefer?"

No silent degradation (inherited from D-35 in [mcp-integration-protocol.md](mcp-integration-protocol.md)). The DISCOVERY-BLOCKED-REPORT.md gives the user a paper trail; the targeted conversation names the specific gap so the user knows what decision they face.

## Quick Reference

- **Step 1:** per-service legal opt-in, D-37 approval-gated. Never launch the browser without a fresh OPT_IN_LEDGER.jsonl entry.
- **Step 2:** subagent invocation with `context: fork`, no Bash, Playwright MCP only (BROWSER-01 + D-43).
- **Step 3:** HAR capture with 4-hour `expires_at` checkpoint per D-50. Posture detection happens here.
- **Step 4:** endpoint classification into DOCUMENTED / INTERNAL / INTERNAL-HARDENED per D-53 (full enum in [discovery-report-schema.md](discovery-report-schema.md)).
- **Step 5:** output firewall with injection detector + fresh-context verify + PII redaction per D-51 / D-52 (full pipeline in [output-firewall.md](output-firewall.md)).
- **Step 6:** emission with SHA256 over body + silent write + rendered summary per D-14.
- **Posture A:** stock Playwright. **Posture B:** Patchright for CDP-leak patch only. **Posture C:** HARD HALT (D-49).
- **Ralph retry:** default 3 attempts, hard cap 5, exponential backoff 1s / 4s / 16s, timing-only (D-55).
- **Halt triggers:** posture C + injection detector YES + PII residual match + retry budget exhausted + user-declined opt-in.
- **On halt:** DISCOVERY-BLOCKED-REPORT.md + state.json status: blocked|failed + manifest failure_reason + targeted user conversation.
- **Cross-reference:** this file is imperative; [browser-stack.md](browser-stack.md) is declarative; [discovery-report-schema.md](discovery-report-schema.md) is the output contract; [output-firewall.md](output-firewall.md) is the runtime firewall; [legal-posture.md](legal-posture.md) is the jurisdictional reference; [.claude/agents/browser-discovery.md](../../../.claude/agents/browser-discovery.md) is the subagent definition.
