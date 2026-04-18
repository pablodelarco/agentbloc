# Research Summary — AgentBloc v2.0 Discovery Agent

**Synthesized:** 2026-04-18
**Source files:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md (committed `8a587f4`)
**Confidence:** HIGH overall. Legal + stack verified against primary sources; output-poisoning tooling MEDIUM (emerging 2026 literature).

---

## Executive Summary

v2.0 adds a Discovery Agent that fires when v1.0 Phase 3 Integration Analysis exhausts all five integration paths (API → MCP → Playwright → email scraping → webhook) and finds nothing. The Discovery Agent is a **Claude Code subagent with `context: fork`, NOT a new user-facing phase**. It slots into Phase 3 as Priority 5.5 between webhook and manual-notification fallback, preserving v1.0's 6-phase brand.

Prior art `kalil0321/reverse-api-engineer` validates the HAR-capture core. v2.0 must differ on six dimensions: replay validation, checkpointed multi-turn (up to 4h pause/resume), per-service legal gate, secret redaction before persist, frozen `DISCOVERY-REPORT.md` schema, and signed-hash output-poisoning defense.

**The dominant risks are legal and build-time injection, not technical.**

---

## The Hard Architectural Decision (all 4 research files agree)

Discovery is a Phase 3 subagent, not a new Phase 7.

- Subagent lives at `.claude/agents/discovery-agent.md` with `context: fork`
- State at `.agentbloc/discovery/<service-slug>/` (user-owned artifact directory, not `.planning/`)
- Main session polls via file existence (`DISCOVERY-REPORT.md` present → subagent done)
- SKILL.md state vocabulary extends with two new gate values: `discovery-running`, `discovery-complete`
- Five v1.0 security references need extensions; one new reference added (`legal-posture.md`)
- One new user-facing phase (Phase 3) stays. Any roadmap numbering "Phase 8 / Phase 9 / ..." refers to v2.0 **internal development phases**, not new skill phases.

---

## Policy Triad (legal + anti-bot + output-poisoning)

1. **Legal:** Per-service opt-in required before any browser launches. Each service gets a `DISCOVERY-LICENSE-NOTICE.md` (ToS URL + keyword-flagged excerpt + tier TOS-GREEN / TOS-AMBER / TOS-RED). Every endpoint classified `DOCUMENTED` / `INTERNAL` / `INTERNAL-HARDENED`. Per-service, not per-install.

2. **Anti-bot:** **Detect-and-degrade, never detect-and-bypass.** Stock Playwright profile + `AgentBloc-Discovery/2.0` User-Agent. CI lint rejects `playwright-extra`, `puppeteer-extra-plugin-stealth`, CAPTCHA solvers. Patchright only for legitimate CDP-leak patches, governed by opt-in gate and logged in `humanGates`.

3. **Output-poisoning:** Every captured response body framed with `untrusted-data` code fences. Injection detector scans for imperative strings, Base64 blobs, invisible unicode. **Fresh-context Claude session performs verification pass** before report release to Builder. SHA256 signed report; v3.0 Builder verifies hash before consuming. This is the single most important security contract of the v2.0 → v3.0 arc.

---

## Critical-Path Stack Pins (top 5)

| Package | Pin | Why |
|---------|-----|-----|
| `playwright` | `^1.59.1` | Lock to 1.59.x for Patchright compatibility |
| `patchright` | `^1.59.4` | Version-locked 1:1 with playwright; 2-maintainer bus-factor — fallback to bare `playwright` or `rebrowser-playwright@^1.52.0` documented |
| `curlconverter` | `^4.12.0` | HAR → curl; 8K stars; replay proof |
| `@har-sdk/validator` | `^2.6.1` | Replaces dead `har-validator` (unpublished from npm 2023) |
| `fetch-har` | `^12.0.1` | In-process replay smoke-test; April 2026 release |

**Do NOT add:** `playwright-extra` (abandoned 2023), `mitmproxy` (3 CVEs 2025-2026), LangGraph runtime (Python-bound; use the *schema shape* only), SQLite / Redis (v1.0 file-based state decision holds), `har-validator`, CAPTCHA solver services, fingerprint-spoofing libraries.

Full stack detail: `STACK.md`.

---

## Prior Art Gap Analysis (`kalil0321/reverse-api-engineer`)

| Gap in prior art | v2.0 must ship |
|---|---|
| One-shot, no pause/resume | Checkpointed multi-turn (file-based JSON, LangGraph-shaped schema) |
| No replay validation | Mandatory `curl` replay; VERIFIED / UNVERIFIED flag per endpoint |
| No legal gate | Per-service opt-in + `DISCOVERY-LICENSE-NOTICE.md` |
| No secret redaction | Redaction before persist; verification scan before emit |
| No structured output | Frozen `DISCOVERY-REPORT.md` with YAML front-matter + markdown body |
| No output-poisoning defense | Injection detector + fresh-context verification + signed hash |

---

## Requirement Category Prefixes (for step 9)

- `LEGAL-xx` — opt-in gate, license notice, three-tier API classification, jurisdiction variance
- `DISC-xx` — discovery mechanics (HAR capture, replay, auth classification, selector fingerprinting, rate-limit detection, error classification, report generation)
- `SECR-EXT-xx` — extensions to v1.0 security references (credentials, blast-radius, audit logging, prompt injection, tenant isolation)
- `RDSV-xx` — rediscovery / self-healing forward-compat interface for v4.0
- `TOS-xx` — per-service ToS classification tooling (may merge into LEGAL-)

---

## Reconciled Internal Phase Structure (v2.0 = 8 development phases, single user-facing change)

Numbering continues from v1.0 (which ended at Phase 7). All 8 are internal milestone phases, not new skill phases.

| # | Phase | Needs research-phase? |
|---|---|---|
| 8 | **Legal Foundation + Output Schema** — freeze `DISCOVERY-LICENSE-NOTICE.md`, three-tier API classification, `DISCOVERY-REPORT.md` schema, YAML front-matter, SHA256 sign format | YES — jurisdictional variance matrix |
| 9 | **Security Extensions to v1.0** — extend `credentials.md`, `blast-radius.md` (+Level 2.5 discovery-probe), `audit-logging.md` (+8 events), `prompt-injection.md` (+Layer 5 HTML isolation), `tenant-isolation.md`; add `legal-posture.md` | No (standard patterns) |
| 10 | **Discovery Toolchain** — Playwright MCP + CDP recipes, curl replay, 7-state lifecycle, checkpoint JSON schema, `agentbloc-discovery-runner.sh` wrapper | YES — Playwright CDP + Patchright syntax verification |
| 11 | **Discovery Orchestration** — Socratic scoping skill, `discovery-gate` hard gate, `.claude/agents/discovery-agent.md` subagent definition, Ralph retry ledger | No |
| 12 | **v1.0 Integration** — wire Phase 3 Step 2.5 ("Priority 5.5"), bump SKILL.md to 2.0.0, extend `governance.yaml` + `telegram.yaml` templates with `discovery:` blocks | No |
| 13 | **Output Sanitization + Report Finalization** — PII redaction pipeline, injection detector, fresh-context verification pass, signed hash, schema inference (D1), cost observability (D9), staleness + tier-shape handling | YES — PII pattern library (IBAN / E.164 / Luhn for EU/US/LATAM) |
| 14 | **Evolution Forward Compatibility** — `REDISCOVER-REQUEST` proposal type, self-healing trigger events interface (`discovery.schema_mismatch`, `discovery.selector_drift`), contract-only (v4.0 will implement consumer) | No |
| 15 | **Validation + Release** — end-to-end walkthrough against a non-critical service, TAP tests, README update, CHANGELOG, v2.0.0 tag, "Looks Done But Isn't" 17-item checklist | No |

**Phase ordering is load-bearing (do NOT reorder):**
- Schema before producer: 8 → 11
- Security before subagent: 9 → 11
- Toolchain before orchestration: 10 → 11
- Subagent before Phase 3 modification: 11 → 12
- Phase 3 wiring before Evolution contract: 12 → 14

---

## Open Decisions Needed During Requirements (step 9)

**Blocks REQUIREMENTS.md — must answer before requirements freeze:**
1. Does `governance.yaml discovery:` block require a new installation wizard, or just a config template with defaults?
2. Exact YAML syntax for path-restricted `Write(path:...)` in subagent frontmatter — needs live smoke-test
3. Does `DISCOVERY-REPORT.md` split into `summary.md` + per-endpoint files at >30 endpoints, or is this a v2.5 optimization?

**Defer to Phase 8 discuss-phase:**
4. Are `[DISCOVERED]`-tier integrations "documentation-only" in v2.0 (no Phase 4 dry-run artifacts generated) until v3.0 Builder ships?
5. Is "Posture C" (hardcore bot protection detected) always `DISCOVERY-BLOCKED-REPORT.md` + stop, or is there a fallback path in v2.0?
6. Is `OPT_IN_LEDGER.json` per-installation or per-project?
7. Should `DISCOVERY-LICENSE-NOTICE.md` be committed to the user's repo (supports GDPR Article 30 record-of-processing) or kept local-only?

---

## Confidence by Area

| Area | Confidence | Notes |
|---|---|---|
| Stack | HIGH | All packages verified on npm/PyPI 2026-04-18 |
| Features | HIGH | Prior art directly examined; P0/P1/P2 matrix complete |
| Architecture | HIGH | Live v1.0 files read; Phase 3 insertion point unambiguous; build order has explicit dependency graph |
| Pitfalls — legal / anti-bot | HIGH | Van Buren, hiQ, UK CPS, GDPR cited; Cloudflare docs verified |
| Pitfalls — output-poisoning | MEDIUM | Anchored to Anthropic Git MCP exploit (Jan 2026), Palo Alto Unit 42 taxonomy, Microsoft MCP security guidance |
| Checkpoint resume semantics | MEDIUM | LangGraph-shaped schema; no live v1.0 precedent — expect iteration after first real Discovery run |

---

## Ready for Requirements

All 4 research files + this synthesis are committed. Orchestrator proceeds to step 9 (Define Requirements).
