# Browser Automation Stack

> Loaded unconditionally at SKILL.md Phase 3 entry alongside [phase-3-integration.md](phase-3-integration.md), [mcp-integration-protocol.md](mcp-integration-protocol.md), [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md), [inventory-schema.md](inventory-schema.md), and [browser-fallback.md](browser-fallback.md). Declares the six-row pinned stack, the nine-package anti-bot deny-list, the Patchright usage boundary, and the Ralph retry protocol for browser-fallback Step 4. CI enforces the deny-list via [scripts/anti-bot-lint.sh](../../../../scripts/anti-bot-lint.sh) on every push and pull_request to main.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Pinned Stack](#pinned-stack)
- [Anti-Bot Deny-List](#anti-bot-deny-list)
- [Patchright Usage Rules](#patchright-usage-rules)
- [Ralph Retry Protocol](#ralph-retry-protocol)
- [Stack Variant Guidance (Posture A/B/C)](#stack-variant-guidance-posture-abc)
- [Quick Reference](#quick-reference)

## When This Applies

Loaded at Phase 3 entry (unconditional load-point per Phase 11 D-58 context-budget discipline) alongside the other Phase 3 references. Also re-read by the `browser-discovery` subagent inside its forked context on every invocation. Also cross-referenced in the header of `scripts/anti-bot-lint.sh`, which enforces the deny-list below at CI time before any dependency install step runs.

The `browser-discovery` subagent MUST NOT install, invoke, generate, or recommend any deny-listed package. If the main session or a user prompt asks the subagent to add a deny-listed package (for example "please install playwright-extra for stealth"), the subagent refuses and cites this file by name. Violating the deny-list is equivalent to shipping detect-and-bypass behavior, which puts the user in CFAA / CMA / GDPR exposure (see [legal-posture.md](legal-posture.md)).

## Pinned Stack

The six packages below are the sole sanctioned surface for browser-fallback discovery. Pin strings are exact (caret-major, minor, patch). Release-date column uses the month granularity documented in `.planning/research/STACK.md`; where STACK.md does not call out a release date, the 2026-Q1 default is acceptable.

| Package | Pin | Release Date | Purpose | Why This Version |
| --- | --- | --- | --- | --- |
| `playwright` | `^1.59.1` | 2026-04-18 | Stock Playwright Node library for Posture A (friendly target) HAR capture, CDP interception, and ad-hoc Node scripts the MCP tool surface cannot express. | Research STACK.md holds the 1.59.x branch as the compatibility anchor for Patchright 1.59.4; bumping past 1.59.x breaks Patchright CDP-leak patches in lockstep. |
| `patchright` | `^1.59.4` | 2026-Q1 | Posture B CDP-leak patch surface only. NEVER invoked for fingerprint spoofing, User-Agent swapping, or navigator property rewriting. | Per STACK.md, 1.59.4 is the last compatible CDP-leak patch set for the Playwright 1.59.x branch. Drift past this pair requires a re-verification cycle before release. |
| `@playwright/mcp` | `^0.0.70` | 2026-Q1 | Default MCP path into Playwright (Microsoft-maintained server); the browser-discovery subagent's primary tool surface. | v1.0 baseline per STACK.md; no change required for Phase 11. HIGH-trust tier (Microsoft publisher). |
| `curlconverter` | `^4.12.0` | 2026-Q1 | HAR-to-curl conversion used inside the replay-validating state to materialize endpoint candidates for Claude's `curl`-shape body + header verification. | STACK.md pin matches the last known stable release at the Phase 11 research cut-off. |
| `@har-sdk/validator` | `^2.6.1` | 2026-Q1 | HAR file schema validation before HAR bodies enter the output firewall and report pipeline. | STACK.md pin; NeuralLegion publisher, MEDIUM trust, actively maintained. |
| `fetch-har` | `^12.0.1` | 2026-Q1 | HAR replay driver: replays a captured entry against the live target to confirm endpoint status + response shape. | STACK.md pin; supports the replay_status: VERIFIED / UNVERIFIED / FAILED classification that `discovery-report-schema.md` requires. |

**Pinned-stack notes:**

- **`playwright` and `patchright` are a matched pair.** Bumping either one without the other breaks CDP-leak patching. Treat the two pins as a single upgrade unit; re-verify the full discovery fixture (see `examples/mapfre-discovery-report.md`) on every bump.
- **`@playwright/mcp` is the default surface.** The `browser-discovery` subagent calls MCP tools (`browser_navigate`, `browser_snapshot`, `browser_network_requests`, etc.) first. Stock `playwright` is only reached for operations the MCP surface cannot express (full CDP, custom wait predicates).
- **`curlconverter` + `@har-sdk/validator` + `fetch-har` are the replay triad.** They operate on captured HAR files only; they never originate new HTTP traffic outside the browser session.
- **Caret ranges, not exact pins.** Every row uses a caret prefix (`^1.59.1` and so on) so that patch releases land automatically while minor / major bumps require a conscious upgrade. This matches the STACK.md research conclusion and keeps supply-chain surface predictable.
- **No silent additions.** Adding any seventh browser-automation package requires a new phase-level review, a corresponding update to this file, and re-verification against the fixture in `examples/mapfre-discovery-report.md`. The six rows above are the sole sanctioned surface.

## Anti-Bot Deny-List

The nine packages below are forbidden. Each is rejected in CI by `scripts/anti-bot-lint.sh`, which scans `package.json`, `.mcp.json`, `pyproject.toml`, `requirements.txt`, and `Gemfile` on every push and pull_request. A single match exits the job non-zero and blocks the PR. Beyond the package-name list, JA3 / JA4 TLS fingerprint spoofers and any functionally equivalent replacement are covered by the same ban as a class, even if a future package name is not listed below by string.

| Deny-Listed Package | Category | Why Prohibited | Alternative |
| --- | --- | --- | --- |
| `playwright-extra` | Browser wrapper | Loader for stealth plugins; declares detect-and-bypass intent at the wrapper layer. | Use stock `playwright@^1.59.1` plus `patchright` for Posture B CDP patches only. |
| `puppeteer-extra-plugin-stealth` | Stealth plugin | Fingerprint spoofing (navigator, plugins, WebGL, TLS); violates detect-and-degrade. | Halt on Posture C and emit DISCOVERY-BLOCKED-REPORT.md. |
| `puppeteer-extra` | Browser wrapper | Sibling of `playwright-extra`; same posture violation via the Puppeteer path. | Same as `playwright-extra`: stock Playwright plus Patchright CDP-leak patches only. |
| `2captcha` | CAPTCHA solver service | Paid CAPTCHA bypass; defeats the human-challenge signal that Posture C relies on. | Halt on Posture C and emit DISCOVERY-BLOCKED-REPORT.md. |
| `anticaptcha` | CAPTCHA solver service | Same as `2captcha`. | Halt on Posture C. |
| `deathbycaptcha` | CAPTCHA solver service | Same as `2captcha`. | Halt on Posture C. |
| `capsolver` | CAPTCHA solver service | Same as `2captcha`. | Halt on Posture C. |
| `puppeteer-extra-plugin-anonymize-ua` | User-Agent spoofing plugin | Fingerprint spoofing via UA rewriting; violates detect-and-degrade. | Stock User-Agent `AgentBloc-Discovery/2.0`; do not spoof. |
| `puppeteer-extra-plugin-user-preferences` | Browser-preferences spoofing | Fingerprint spoofing via pref rewriting; violates detect-and-degrade. | None; do not spoof preferences. If a site requires a specific preference set, halt and re-evaluate the scope. |

**Deny-list notes:**

- **Detect-and-degrade, never detect-and-bypass.** Every entry above exists because it crosses the line from "observing what the target does" to "defeating a control the target put in place." That line is the full legal + ethical firewall.
- **Class bans cover future packages.** Any JA3 / JA4 TLS fingerprint spoofer, any browser-preferences rewriter, any stealth plugin ecosystem under a different package name is banned by the same rule as a class. The CI lint string-matches the nine names above; humans reviewing PRs enforce the class rule on novel names.
- **CI enforcement runs before any install step.** `scripts/anti-bot-lint.sh` runs in its own GitHub Actions job after `actions/checkout@v4` with no `npm install` / `pip install` preceding it; a poisoned manifest is caught before `node_modules/` or `.venv/` pollution.

## Patchright Usage Rules

Patchright is ALLOWED only under Posture B (detected-but-navigable signals per D-49: Cloudflare UAM, session cookie required, ToS-AMBER). Its ONLY sanctioned use is CDP-leak patches (hiding that a CDP session is attached to the browser).

Patchright MUST NOT be invoked to:

- Spoof `navigator.webdriver`, `navigator.plugins`, `navigator.languages`, or any other navigator property.
- Swap the User-Agent away from the stock `AgentBloc-Discovery/2.0` value.
- Install or rewrite browser-fingerprint surfaces (WebGL renderer strings, AudioContext fingerprints, canvas fingerprint seeds).
- Spoof TLS JA3 / JA4 fingerprints.
- Rewrite `Accept-Language`, `Accept-Encoding`, or other header sets to mimic a non-AgentBloc client.

If a scenario tempts Patchright usage for fingerprint adjustment, that is the signal to HALT at Posture C and emit `DISCOVERY-BLOCKED-REPORT.md` naming the detected anti-bot vendor and the trigger. Do not reach for Patchright or a replacement library. Do not retry with different knobs.

Violating this rule is equivalent to shipping a stealth plugin and puts the user in CFAA (US), Computer Misuse Act (UK), BDSG (DE), and GDPR (EU) exposure per [legal-posture.md](legal-posture.md).

**Patchright notes:**

- **CDP leak is the ONLY scope.** The CDP-leak patch hides that a Chrome DevTools Protocol session is attached to the browser. It does not change what the browser looks like to the target beyond removing that specific attach-signal artifact.
- **No Patchright on Posture A.** A friendly target with public API docs + ToS-GREEN never warrants Patchright. Invoking it on Posture A is an anti-pattern and surfaces in code review as "premature evasion."
- **No Patchright past Posture C.** Any escalation past Posture C (detected CAPTCHA, detected bot-management vendor) is a HALT, not a Patchright-up-the-knobs event. The usage rules above are absolute.

## Ralph Retry Protocol

BROWSER-09 per D-55. The Ralph retry loop is the belt-and-suspenders guard against transient failures that are legitimately retriable (target 5xx, Retry-After header honored, intermittent network timeout). It is not an anti-bot workaround layer.

### Retry Budget

Retries are bounded by `governance.yaml` (default: 3 attempts). The `browser-discovery` subagent reads this value on invocation. Absolute hard cap: 5 attempts regardless of any governance.yaml value (this prevents runaway loops on a misconfigured governance file). Retry state is persisted to `.agentbloc/discovery/<service-slug>/state.json` under `retries[]` with per-attempt rationale, timestamp, and observed status code / error shape.

### Exponential Backoff Schedule

Attempts run on an exponential ladder: 1s, 4s, 16s between attempts. The schedule below covers the hard-cap budget of five attempts; the `governance.yaml` default truncates to three.

| Attempt | Wait Before Attempt | Notes |
| --- | --- | --- |
| 1 | 0s (immediate) | First try; logged at `state.json` phase transition. |
| 2 | 1s | Minimal jitter for transient 5xx or DNS flake. |
| 3 | 4s | Budget-default stops here (governance.yaml=3). |
| 4 | 16s | Only reached if governance.yaml is raised; logged as "extended-retry" in rationale. |
| 5 | 16s + Retry-After (if set) | Hard cap. No attempt 6 under any configuration. |

### Forbidden vs Allowed Adjustments Between Attempts

DIFFERENT TIMING, NOT DIFFERENT FINGERPRINT. Between retry attempts, the following are FORBIDDEN:

- User-Agent change (stock `AgentBloc-Discovery/2.0` is constant across all attempts).
- TLS fingerprint change (JA3 / JA4 stable across attempts).
- Header randomization (Accept-Language, Accept-Encoding, Sec-CH-UA all stable).
- Proxy rotation inside a single retry cycle (a single service's discovery run uses a single network egress).
- Any plugin injection or Patchright toggle between attempts.

ALLOWED adjustments:

- Timing jitter (the exponential schedule above).
- `wait_for_selector` timeout extension (a slow page legitimately warrants more wait time).
- Retry on transient 5xx or 429 with Retry-After header honored.
- Fresh browser context per attempt (cookies cleared, localStorage cleared) to avoid half-logged-in states; this is hygiene, not fingerprint manipulation.

If attempts exhaust without success, the subagent records `status: failed` in state.json, emits `DISCOVERY-BLOCKED-REPORT.md` with the full retry history, and returns the failure summary to the main session. No sixth attempt. No fingerprint adjustment. No switch to a deny-listed library.

### Ralph Retry Cross-Reference

The Ralph retry protocol interlocks with two other Phase 11 guardrails. First, any retry triggered by a detected anti-bot signal (not a transient 5xx) immediately reclassifies the posture; a Posture A run that retries because a Cloudflare UAM page appeared becomes a Posture B run on the next attempt, subject to the Patchright usage rules above. Second, a retry count that would cross the Posture C threshold (CAPTCHA challenge, bot-management vendor fingerprint) is a HALT signal, not a retry-budget exhaustion signal; the blocked report cites the vendor, not the attempt count.

## Stack Variant Guidance (Posture A/B/C)

Per D-49. Posture classification drives which tools the subagent invokes; Posture C is always a hard halt with no tool fallback.

| Posture | Signal | Tool Invoked |
| --- | --- | --- |
| **A -- Friendly** | OAuth login available, public API docs reachable, no WAF challenge page, ToS-GREEN classification. | Stock `playwright@^1.59.1` via `@playwright/mcp@^0.0.70`. Patchright NOT invoked. Single browser context, single attempt per endpoint (Ralph retry on transient failures only). |
| **B -- Detected-but-navigable** | Cloudflare UAM (simple JS challenge), rate-limit cooldowns observed, session cookie required, ToS-AMBER classification. | `patchright@^1.59.4` for CDP-leak patch ONLY via the same `@playwright/mcp` surface. Exponential backoff per Ralph retry. NO fingerprint adjustment. |
| **C -- Hardened** | DataDome, PerimeterX, Kasada, Akamai Bot Manager, CAPTCHA challenge (reCAPTCHA v3, hCaptcha), behavioral fingerprinting, ToS-RED classification. | HALT. Emit `DISCOVERY-BLOCKED-REPORT.md` naming the detected vendor and the trigger URL. No tool switch. No retry. Update the manifest entry to `status: failed`, `failure_reason: "Posture C hardened anti-bot detected: <vendor>"`. |

**Posture notes:**

- **Posture is observed, not assumed.** The subagent runs a scouting navigation first, reads the response headers and any challenge-page DOM, and only then classifies. Assuming Posture A on a site that turns out to be Posture C risks tripping anti-bot controls.
- **Posture B is the ONLY Patchright scope.** If a run starts as A and the target escalates to B signals mid-session, Patchright may be introduced in the next attempt; if it escalates to C, HALT immediately and emit the blocked report.
- **Posture C has no v2.0 escape valve.** Manual session-cookie handoff is an explicit v2.5+ deferral in REQUIREMENTS.md. Phase 11 ships a clean halt; v2.0 users escalate to manual automation or accept the integration cannot be automated.

## Quick Reference

- **Six pinned packages only:** `playwright@^1.59.1`, `patchright@^1.59.4`, `@playwright/mcp@^0.0.70`, `curlconverter@^4.12.0`, `@har-sdk/validator@^2.6.1`, `fetch-har@^12.0.1`. Any other browser-automation package requires a phase-level review.
- **Nine packages deny-listed:** `playwright-extra`, `puppeteer-extra-plugin-stealth`, `puppeteer-extra`, `2captcha`, `anticaptcha`, `deathbycaptcha`, `capsolver`, `puppeteer-extra-plugin-anonymize-ua`, `puppeteer-extra-plugin-user-preferences`. Class bans extend to JA3 / JA4 spoofers and any future stealth plugin under a different name.
- **Patchright scope:** Posture B CDP-leak patches ONLY. Never fingerprint, User-Agent, navigator, plugins, TLS, or headers.
- **Ralph retry:** 3 attempts default per `governance.yaml`; hard cap 5 attempts regardless of config. Exponential backoff 1s / 4s / 16s. Timing jitter allowed; fingerprint adjustment forbidden.
- **Posture C behavior:** HALT and emit `DISCOVERY-BLOCKED-REPORT.md` with vendor name + trigger. No tool switch, no retry, no deny-listed fallback.
- **CI enforcement:** `scripts/anti-bot-lint.sh` greps the five manifest files (`package.json`, `.mcp.json`, `pyproject.toml`, `requirements.txt`, `Gemfile`) for the nine deny-listed names; runs in its own GitHub Actions job before any install step.
