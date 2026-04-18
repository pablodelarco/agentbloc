# Roadmap: AgentBloc

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-7 (shipped 2026-04-18) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 Discovery Agent** — Phases 8-15 (In Progress)

## Phases

<details>
<summary>✅ v1.0 Initial Release (Phases 1-7) — SHIPPED 2026-04-18</summary>

- [x] Phase 1: Skill Foundation (2/2 plans) — completed 2026
- [x] Phase 2: Security Cross-Cutting References (3/3 plans) — completed 2026
- [x] Phase 3: Interview and Design Phases (3/3 plans) — completed 2026
- [x] Phase 4: Integration and Confirmation Phases (2/2 plans) — completed 2026
- [x] Phase 5: Deployment Artifacts and Evolution (3/3 plans) — completed 2026
- [x] Phase 6: Repo Polish and Examples (3/3 plans) — completed 2026
- [x] Phase 7: Testing and CI (2/2 plans) — completed 2026-04-18

For full v1.0 details see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md).

</details>

### 🚧 v2.0 Discovery Agent (In Progress)

- [ ] **Phase 8: Legal Foundation and Output Schema** — Freeze `DISCOVERY-LICENSE-NOTICE.md`, three-tier API classification, `DISCOVERY-REPORT.md` YAML front-matter with SHA256 + `expires_at`, CI deny-list lint for stealth libraries.
- [ ] **Phase 9: Security Extensions** — Extend v1.0 security references (credentials, blast-radius Level 2.5, audit logging +8 events, prompt-injection Layer 5, tenant-isolation, PII redaction pipeline).
- [ ] **Phase 10: Discovery Toolchain** — Playwright + CDP HAR capture, curl replay, checkpoint schema, Ralph retry loop, KILL_SWITCH check, `agentbloc-discovery-runner.sh` wrapper for cron resume.
- [ ] **Phase 11: Discovery Orchestration** — `.claude/agents/discovery-agent.md` subagent, seven-state lifecycle, auth classification, selector fingerprinting, rate-limit detection, error classification, Socratic pre-flight.
- [ ] **Phase 12: v1.0 Integration** — Wire Phase 3 Priority 5.5 handoff via `TARGET.md`, Telegram progress thread, `governance.yaml` `discovery:` block, interactive enablement wizard, `telegram.yaml` `discovery-approvals` thread.
- [ ] **Phase 13: Output Sanitization and Report Finalization** — Injection detector, fresh-context verification pass, Telegram `/stop` kill-switch wiring, schema inference, anti-bot posture classifier, cost observability, license-notice automation.
- [ ] **Phase 14: Evolution Forward Compatibility** — `REDISCOVER-REQUEST` proposal type, four self-healing trigger events, `expires_at` staleness contract, Builder-handoff healthcheck recipe for v4.0.
- [ ] **Phase 15: Validation and Release** — End-to-end walkthrough against a non-critical service, TAP test additions, README + CHANGELOG updates, v2.0.0 git tag.

## Phase Details

### Phase 8: Legal Foundation and Output Schema
**Goal**: The skill can refuse to launch a browser until the user has signed a per-service opt-in, and every DISCOVERY-REPORT.md produced by v2.0 conforms to a frozen, hash-signed, staleness-aware schema.
**Depends on**: Nothing (first v2.0 phase — schema must freeze before any producer is built)
**Requirements**: LEGAL-01, LEGAL-02, LEGAL-03, LEGAL-04, LEGAL-05, LEGAL-06, LEGAL-07, DISC-13, DISC-14, DISC-19, RDSV-03
**Success Criteria** (what must be TRUE):
  1. User who tries to run Discovery against a service with no logged opt-in is refused, and the refusal cites the missing `DISCOVERY-LICENSE-NOTICE.md` by path
  2. A sample `DISCOVERY-REPORT.md` validates against the locked YAML front-matter schema and carries a verifiable SHA256 hash plus an `expires_at` field
  3. A reader can open `references/legal-posture.md` and identify the legal exposure for their jurisdiction (CFAA / CMA / StGB / GDPR / LGPD) before opting in
  4. `OPT_IN_LEDGER.json` is append-only — attempting to rewrite a past opt-in either fails a lint or produces a visible tampering signal
  5. CI fails on any PR that adds `playwright-extra`, `puppeteer-extra-plugin-stealth`, a CAPTCHA solver, or a fingerprint-spoofing library to the dependency tree
**Plans**: TBD

### Phase 9: Security Extensions
**Goal**: Every v1.0 security reference has an explicit v2.0 extension so Discovery Agent inherits the existing framework rather than improvising a parallel one, and a PII redaction pipeline is provably active before any HAR or response body is persisted.
**Depends on**: Phase 8 (Level 2.5 blast-radius tier references the TOS classification schema; audit events reference the report schema)
**Requirements**: SECR-EXT-01, SECR-EXT-02, SECR-EXT-03, SECR-EXT-04, SECR-EXT-05, SECR-EXT-06, GOV-03
**Success Criteria** (what must be TRUE):
  1. A developer reading `blast-radius.md` can classify a Discovery run as Level 2.5 "discovery-probe" and see the approval requirements distinct from read-only (2) and write-scoped (3)
  2. All eight new discovery-specific audit event types (`session.started` through `session.completed`) appear in `audit-logging.md` with correlation-ID examples matching v1.0's pattern
  3. `credentials.md` shows a session-handoff pattern where Discovery never captures MFA seeds or passkey secrets — only the resulting session cookie, auto-purged on run completion
  4. The PII redaction pipeline catches EU IBAN, US SSN, Luhn-valid credit cards, E.164 phones, and email addresses in a synthetic HAR; a residual-match verification scan fails the test run when any pattern survives
  5. Cross-service directory reads under `.agentbloc/discovery/<service-slug>/` require explicit opt-in — a Discovery run for service A cannot read service B's state without an additional gate
**Plans**: TBD

### Phase 10: Discovery Toolchain
**Goal**: The concrete tooling Discovery needs (HAR capture, curl replay, checkpoint persistence, Ralph retry loop, kill-switch check, cron resume wrapper) exists and is independently exercisable before orchestration wires them together.
**Depends on**: Phase 8 (checkpoint schema references the report schema's `expires_at` and SHA256 contract)
**Requirements**: DISC-04, DISC-05, DISC-10, DISC-11, DISC-12, DISC-19
**Success Criteria** (what must be TRUE):
  1. A Playwright `recordHar` session captures network traffic in memory and only writes HAR to disk after the PII redaction pipeline from Phase 9 has run — unredacted HAR never touches persistent storage
  2. Every endpoint captured from a synthetic target replays successfully via `curl` and is flagged VERIFIED, or is flagged UNVERIFIED with the failure class logged
  3. A Discovery run can be interrupted mid-flight, resumed from `.agentbloc/discovery/<service-slug>/state.json` up to 4 hours later, and complete without re-capturing previously completed state
  4. Touching `.agentbloc/KILL_SWITCH` during a run causes the run to halt at the next state transition and emit a partial report with the reason recorded
  5. `agentbloc-discovery-runner.sh` invoked from system cron picks up a paused checkpoint, invokes `claude -p` with the resume prompt, and advances the run — all without human intervention
  6. The Ralph retry loop hits its `max_retry_iterations` cap from governance and surfaces the ledger (retry count, last failure class, exponential-backoff timing) in the checkpoint without attempting fingerprint evasion
**Plans**: TBD

### Phase 11: Discovery Orchestration
**Goal**: A Claude Code subagent can drive a complete discovery run end-to-end through the seven-state lifecycle, classifying auth and errors, fingerprinting selectors, and detecting rate limits — all scoped to Playwright MCP tools and gated by the security extensions from Phase 9.
**Depends on**: Phase 9 (subagent inherits extended security references), Phase 10 (orchestrator calls toolchain primitives)
**Requirements**: DISC-02, DISC-03, DISC-06, DISC-07, DISC-08, DISC-09, NICE-03
**Success Criteria** (what must be TRUE):
  1. `.claude/agents/discovery-agent.md` exists with `context: fork`, scoped to Playwright MCP tools only, and is invoked cleanly by the main session with a `TARGET.md` payload
  2. A discovery run against a synthetic target advances through all seven states (pre-login → login → walk → capture → analyze → validate → report), persisting checkpoint state after every transition
  3. Auth flows are classified into the bounded set (cookie / OAuth 2.x / JWT / session / magic link / passkey) in the resulting report with observable evidence for the classification
  4. UI selectors are fingerprinted in preference order (`data-testid` > accessibility role > stable CSS class > XPath) and brittle selectors carry a visible flag in the report
  5. When the synthetic target returns 429 with `Retry-After` or a 503 pattern, the report includes a recommended request budget derived from the observed limit, and each failure is tagged with one of the six error classes (auth-expired / forbidden / rate-limited / server-error / schema-changed / anti-bot-triggered)
  6. Before any browser launches, the Socratic pre-flight produces a scoped target workflow with an explicit endpoint list and budget — and refuses to proceed if the user's answers are ambiguous
**Plans**: TBD

### Phase 12: v1.0 Integration
**Goal**: The Discovery Agent is reachable from v1.0's Phase 3 Integration Analysis as Priority 5.5, governed by `discovery:` config defaults, surfaced through Telegram threads, and optionally enabled via an interactive wizard — without breaking v1.0's 6-phase user-facing brand.
**Depends on**: Phase 11 (subagent must exist before Phase 3 can hand off to it)
**Requirements**: DISC-01, DISC-18, GOV-01, GOV-02, GOV-04, GOV-05
**Success Criteria** (what must be TRUE):
  1. When Phase 3 exhausts Priorities 1-5 and no path exists, the skill emits a `TARGET.md` containing the service, target workflow, and budget cap — and hands it off to the Discovery subagent as Priority 5.5
  2. A fresh deployment's `governance.yaml` template carries the `discovery:` block with safe defaults (`enabled: false`, `max_runtime_minutes: 240`, `max_retry_iterations: 3`, `max_budget_usd: 50`, `allowed_services: []`, `require_license_notice: true`, `posture_classifier: true`)
  3. When `discovery.enabled` is false and Phase 3 recommends Discovery, the optional wizard walks the user through enabling it, granting per-service opt-in, and signing the license notice — no hand-edited YAML required
  4. A running Discovery run streams progress to a per-service Telegram thread that matches v1.0's thread-per-domain pattern, and the `telegram.yaml` template carries the `discovery-approvals` thread pattern for human gates
  5. Exceeding any of the three hard caps (wall-clock minutes, retry iterations, USD estimate) halts the run and emits a partial report citing which cap was exceeded
**Plans**: TBD

### Phase 13: Output Sanitization and Report Finalization
**Goal**: Before any DISCOVERY-REPORT.md is released to downstream consumers, every captured response body has been framed as untrusted data, scanned for prompt injection, and verified in a fresh-context session — and the P1 differentiator features (schema inference, anti-bot posture classifier, cost observability, license-notice automation) layer onto that sanitized output.
**Depends on**: Phase 12 (Telegram wiring must exist for `/stop` kill signal and posture-C escalation; report producer must be fully wired to v1.0 Phase 3 before finalization gates run)
**Requirements**: DISC-15, DISC-16, DISC-17, NICE-01, NICE-02, NICE-04, NICE-05
**Success Criteria** (what must be TRUE):
  1. A captured response body containing an imperative string, a Base64 blob, or invisible Unicode is isolated inside an `untrusted-data` code fence in the report, and the injection detector logs the finding with position and pattern class
  2. A fresh-context Claude session with no access to the original HAR files signs off on the sanitized report before it is released; a deliberately poisoned fixture fails this verification pass
  3. Sending `/stop` via Telegram halts a running Discovery within one state-transition window, as observed in the checkpoint's last `kill.triggered` audit event
  4. A run against a synthetic JSON API produces a report with inferred response shapes (field types, required vs optional, enum values observed ≥3 times), a posture classification (A / B / C), a "Run stats" section with token usage + wall-clock + browser-minutes, and a draft `DISCOVERY-LICENSE-NOTICE.md` with ToS excerpt + tier — the user reviews rather than authors from scratch
  5. A Posture C ("hardened: DataDome / PerimeterX / CAPTCHA") detection halts the run and emits a `DISCOVERY-BLOCKED-REPORT.md` instead of a normal report
**Plans**: TBD

### Phase 14: Evolution Forward Compatibility
**Goal**: Every v2.0 DISCOVERY-REPORT.md carries the producer-side contract that v4.0 Self-Healing Evolution will consume — trigger event types, rediscovery proposal schema, staleness signal, and a Builder-generated healthcheck recipe — so v2.0 output is not obsoleted when v4.0 ships.
**Depends on**: Phase 12 (Phase 6 Evolution reference file is part of v1.0 wiring — the rediscover proposal type extends it, not replaces it)
**Requirements**: RDSV-01, RDSV-02, RDSV-04
**Success Criteria** (what must be TRUE):
  1. `references/phase-6-evolution.md` defines the `REDISCOVER-REQUEST` proposal type with a locked schema (service, observed symptom, trigger event, requested scope) that a future v4.0 consumer can parse without negotiation
  2. All four self-healing trigger event types (`discovery.schema_mismatch`, `discovery.selector_drift`, `discovery.auth_change`, `discovery.rate_limit_tightened`) are documented with worked examples and producer contracts
  3. Every generated DISCOVERY-REPORT.md's "Builder handoff" section contains a healthcheck recipe specific enough that v3.0 Builder can wire a `/__discovery_healthcheck` operation into the generated MCP without reinterpreting the discovery evidence
  4. A v2.0 report emits but does not attempt to consume a `REDISCOVER-REQUEST` — the producer/consumer split is clean, and the test suite asserts the absence of consumer code paths
**Plans**: TBD

### Phase 15: Validation and Release
**Goal**: v2.0 is provably safe to ship against a real-world non-critical service, every new requirement has test coverage, and the repo carries the documentation + tag a user needs to install v2.0 with confidence.
**Depends on**: Phase 14 (the forward-compat contract is part of what v2.0 ships — release cannot cut before that contract is frozen)
**Requirements**: RDSV-04 (verification that Builder-handoff section passes downstream consumption shape test)
**Success Criteria** (what must be TRUE):
  1. An end-to-end Discovery run against a non-critical real-world service (user-selected, low-blast-radius) produces a validated DISCOVERY-REPORT.md, a DISCOVERY-LICENSE-NOTICE.md, and an updated OPT_IN_LEDGER.json — all passing the Phase 13 sanitization pass
  2. The TAP test suite adds coverage for every new requirement category (LEGAL, DISC, GOV, SECR-EXT, RDSV) and the full suite passes in CI on a clean checkout
  3. The README carries a v2.0 section explaining Discovery Agent, when it activates, and the legal posture — and the CHANGELOG records every added requirement by ID
  4. The `v2.0.0` git tag is pushed to the public repo, CI is green, and the "Looks Done But Isn't" 17-item checklist is completed with no open items
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Skill Foundation | v1.0 | 2/2 | Complete | 2026 |
| 2. Security Cross-Cutting References | v1.0 | 3/3 | Complete | 2026 |
| 3. Interview and Design Phases | v1.0 | 3/3 | Complete | 2026 |
| 4. Integration and Confirmation Phases | v1.0 | 2/2 | Complete | 2026 |
| 5. Deployment Artifacts and Evolution | v1.0 | 3/3 | Complete | 2026 |
| 6. Repo Polish and Examples | v1.0 | 3/3 | Complete | 2026 |
| 7. Testing and CI | v1.0 | 2/2 | Complete | 2026-04-18 |
| 8. Legal Foundation and Output Schema | v2.0 | 0/3 | Not started | - |
| 9. Security Extensions | v2.0 | 0/2 | Not started | - |
| 10. Discovery Toolchain | v2.0 | 0/3 | Not started | - |
| 11. Discovery Orchestration | v2.0 | 0/3 | Not started | - |
| 12. v1.0 Integration | v2.0 | 0/2 | Not started | - |
| 13. Output Sanitization and Report Finalization | v2.0 | 0/3 | Not started | - |
| 14. Evolution Forward Compatibility | v2.0 | 0/2 | Not started | - |
| 15. Validation and Release | v2.0 | 0/2 | Not started | - |
