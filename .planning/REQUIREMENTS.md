# Requirements: AgentBloc v2.0 Discovery Agent

**Defined:** 2026-04-18
**Core Value:** A non-technical business owner can describe their problem and end up with a deployed, secure agent team without writing code and without improvised security scaffolding. v2.0 extends this by automatically reverse-engineering services that have no MCP or public API — without the user touching browser tooling or legal boilerplate.

---

## Milestone Scope (Locked 2026-04-18)

- **Architecture:** Discovery is a Claude Code subagent (`.claude/agents/discovery-agent.md` with `context: fork`) invoked from Phase 3 Integration Analysis as Priority 5.5, between webhook (5) and manual fallback (6). No new user-facing phases — v1.0's 6-phase brand stays intact.
- **MVP contract:** 12 P0 table-stakes obligatory, 5 P1 differentiators "ship 3+ of 5 is success", 4 P2 differentiators deferred to v2.5 (design hooks preserved in v2.0 state schema).
- **Policy triad (hardcoded):** Detect-and-degrade never bypass · Per-service opt-in + `DISCOVERY-LICENSE-NOTICE.md` · Three-tier API classification per endpoint.
- **Governance UX:** `governance.yaml` ships a `discovery:` block template with safe defaults (`enabled: false`), plus an optional interactive wizard triggered when Phase 3 recommends Discovery and `discovery.enabled` is false.
- **Open decisions deferred to Phase 8 discuss-phase:** (a) `DISCOVERY-REPORT.md` split threshold at >30 endpoints — v2.0 single-file default; (b) `OPT_IN_LEDGER.json` scope — per-project default.

---

## v1 Requirements

### Legal & Licensing

- [ ] **LEGAL-01**: System refuses to launch browser for any service until user has signed an explicit per-service opt-in; opt-in is logged with timestamp, version hash, and user attestation
- [ ] **LEGAL-02**: System generates `DISCOVERY-LICENSE-NOTICE.md` per service containing ToS URL, keyword-flagged excerpt, tier classification (TOS-GREEN / TOS-AMBER / TOS-RED), and user attestation wording
- [ ] **LEGAL-03**: Every endpoint in a DISCOVERY-REPORT.md carries a three-tier API classification: DOCUMENTED (public API key grant exists) / INTERNAL (UI-backing JSON, no anti-automation intent) / INTERNAL-HARDENED (CORS + CSRF + anti-automation intent observed)
- [ ] **LEGAL-04**: Skill includes a new reference file `references/legal-posture.md` documenting jurisdictional variance (CFAA US, CMA UK, StGB DE, GDPR EU, LGPD BR) so users understand regional constraints
- [ ] **LEGAL-05**: User can review an append-only `OPT_IN_LEDGER.json` per project listing every opt-in ever granted (service, date, tier, user attestation hash, Discovery run ID)
- [ ] **LEGAL-06**: `DISCOVERY-LICENSE-NOTICE.md` is committed to the user's repository by default (supports GDPR Article 30 record-of-processing); user can opt out via `governance.yaml` flag for privacy-sensitive deployments
- [ ] **LEGAL-07**: Project CI lints the codebase against a deny-list of stealth / evasion libraries (`playwright-extra`, `puppeteer-extra-plugin-stealth`, any CAPTCHA solver service, fingerprint-spoofing libraries); violations fail CI

### Discovery Core

- [ ] **DISC-01**: When Phase 3 Integration Analysis exhausts Priorities 1-5 (API → MCP → Playwright → email → webhook) and no path exists, it emits a `TARGET.md` describing the service + target workflow + budget cap
- [ ] **DISC-02**: A Discovery subagent defined at `.claude/agents/discovery-agent.md` with `context: fork` consumes the TARGET.md, scoped to Playwright MCP tools only
- [ ] **DISC-03**: Discovery runs through a seven-state lifecycle (pre-login → login → walk → capture → analyze → validate → report), persisting state after every transition
- [ ] **DISC-04**: Discovery captures network traffic via Playwright's native `recordHar` with in-memory handling; HAR files never persist to disk before PII redaction runs
- [ ] **DISC-05**: Discovery replays every discovered endpoint via `curl` to verify reachability; each endpoint flagged VERIFIED or UNVERIFIED in the report
- [ ] **DISC-06**: Discovery classifies the observed auth flow into a bounded set (cookie / OAuth 2.x / JWT / session / magic link / passkey) and documents the classification in the report
- [ ] **DISC-07**: Discovery fingerprints UI selectors with preference order: `data-testid` > accessibility role > stable CSS class > XPath; brittle selectors are flagged
- [ ] **DISC-08**: Discovery detects rate limits from 429 + `Retry-After` headers and from 503 patterns; infers hidden quotas and documents a recommended request budget in the report
- [ ] **DISC-09**: Discovery classifies each failure response into a bounded set (auth-expired / forbidden / rate-limited / server-error / schema-changed / anti-bot-triggered) with per-class retry strategy
- [ ] **DISC-10**: Discovery state is serialised to `.agentbloc/discovery/<service-slug>/state.json` so a run can pause for up to 4 hours (real-world latency: 2FA email, SMS verification) and resume from last checkpoint
- [ ] **DISC-11**: Discovery wraps brittle interactions in a Ralph-style retry loop with a capped iteration budget (`max_retry_iterations` from governance), logged reasoning, and exponential backoff — NO fingerprint evasion or stealth adjustment
- [ ] **DISC-12**: Discovery checks `.agentbloc/KILL_SWITCH` file existence before every major state transition; any existence halts the run immediately and writes a partial report
- [ ] **DISC-13**: Discovery emits a `DISCOVERY-REPORT.md` at `.agentbloc/discovery/<service-slug>/DISCOVERY-REPORT.md` with YAML front-matter (schema-locked) + structured markdown body (endpoints, auth, rate limits, anti-bot observations, limitations, Builder handoff notes)
- [ ] **DISC-14**: The DISCOVERY-REPORT.md carries a SHA256 hash in its front-matter; v3.0 Builder Agent verifies the hash before consuming the report
- [ ] **DISC-15**: Before the report is finalised, an injection detector scans every captured response body for imperative strings, Base64 blobs, and invisible Unicode; findings are isolated inside `untrusted-data` code fences
- [ ] **DISC-16**: A fresh-context Claude session performs a verification pass on the sanitised report before it is released to downstream consumers; the fresh session has no access to the original HAR files
- [ ] **DISC-17**: User can halt a running Discovery via the existing Telegram `/stop` command; kill signal propagates to the subagent within one state-transition window
- [ ] **DISC-18**: Long-running discovery reports progress to a dedicated Telegram thread-per-service (matches v1.0 thread-per-domain pattern)
- [ ] **DISC-19**: System ships an `agentbloc-discovery-runner.sh` wrapper so discovery runs can be scheduled via system cron + `claude -p` alongside v1.0 deployed agents

### Governance & Controls

- [ ] **GOV-01**: `governance.yaml` deployment template carries a `discovery:` block with safe defaults: `enabled: false`, `max_runtime_minutes: 240`, `max_retry_iterations: 3`, `max_budget_usd: 50`, `allowed_services: []`, `require_license_notice: true`, `posture_classifier: true`
- [ ] **GOV-02**: When Phase 3 recommends Discovery and `discovery.enabled` is false, the skill offers an optional interactive wizard that walks the user through enabling Discovery, granting per-service opt-in, and signing the license notice
- [ ] **GOV-03**: Blast-radius scoring (extended from v1.0) introduces a new Level 2.5 "discovery-probe" that sits between read-only (2) and write-scoped (3); requires opt-in but is bounded by the governance budget
- [ ] **GOV-04**: Discovery honours three hard budget caps from governance: wall-clock minutes, retry iterations, and USD cost estimate; exceeding any cap halts the run and emits a partial report
- [ ] **GOV-05**: `telegram.yaml` template gains a `discovery-approvals` thread pattern so human-in-the-loop approvals (posture-C escalation, license-notice review) surface on mobile without leaving AgentBloc's thread-based UX

### Security Extensions (to v1.0 references)

- [ ] **SECR-EXT-01**: `credentials.md` extended with a session-handoff pattern — Discovery never captures MFA seeds or passkey secrets; user logs in on their own device, Discovery captures only the resulting session cookie, stored in the OS keychain, auto-purged on run completion
- [ ] **SECR-EXT-02**: `blast-radius.md` documents the new Level 2.5 discovery-probe tier with examples and approval requirements
- [ ] **SECR-EXT-03**: `audit-logging.md` extended with eight discovery-specific event types (`session.started`, `endpoint.discovered`, `tier.classified`, `anti_bot.detected`, `posture.classified`, `report.signed`, `kill.triggered`, `session.completed`); all events carry the correlation ID pattern from v1.0
- [ ] **SECR-EXT-04**: `prompt-injection.md` extended with Layer 5 "HTML / response-body isolation" — every captured body is framed as untrusted data and cannot be interpreted as instructions by the main session
- [ ] **SECR-EXT-05**: `tenant-isolation.md` extended with per-service directory segregation under `.agentbloc/discovery/<service-slug>/`; cross-service reads require explicit opt-in
- [ ] **SECR-EXT-06**: PII redaction pipeline runs on every captured HAR and every response body, with patterns for EU IBAN, US SSN, credit-card Luhn, E.164 phone, and common email formats; a verification scan re-runs on the report before emit and fails the run on any residual match

### Rediscovery / Self-Healing Forward Compatibility (for v4.0)

- [ ] **RDSV-01**: `references/phase-6-evolution.md` declares a `REDISCOVER-REQUEST` proposal type with a locked schema (service, observed symptom, trigger event, requested scope); v2.0 emits but does not consume — v4.0 will implement the consumer
- [ ] **RDSV-02**: `references/phase-6-evolution.md` defines four self-healing trigger event types (`discovery.schema_mismatch`, `discovery.selector_drift`, `discovery.auth_change`, `discovery.rate_limit_tightened`) with examples and producer contracts
- [ ] **RDSV-03**: Every DISCOVERY-REPORT.md front-matter carries an `expires_at` field (conservative 90-day default); downstream consumers (v3.0 Builder, v4.0 Self-Healing) honour this as a staleness signal
- [ ] **RDSV-04**: Discovery embeds a healthcheck recipe in the report's "Builder handoff" section so v3.0 Builder-generated MCPs can include a lightweight `/__discovery_healthcheck` operation for v4.0 drift detection

### P1 Differentiators (Ship 3+ of 5 is success)

- [ ] **NICE-01** (Schema inference): Discovery infers JSON response shapes (types, required vs optional fields, enum values when observed ≥3 times) and documents them in the report
- [ ] **NICE-02** (Anti-bot posture classifier): Discovery classifies the observed anti-bot posture as A (none), B (basic: User-Agent / rate limit / Cloudflare-lite), or C (hardened: DataDome / PerimeterX / CAPTCHA); Posture C halts the run and emits a `DISCOVERY-BLOCKED-REPORT.md`
- [ ] **NICE-03** (Socratic scoping): Discovery pre-flight runs a short Socratic skill (borrowed pattern from GStack `/office-hours`) to scope the target workflow, required endpoints, and budget before any browser launches
- [ ] **NICE-04** (Cost observability): Discovery tallies token usage, wall-clock minutes, and browser-minutes per run and writes them to the report's "Run stats" section
- [ ] **NICE-05** (DISCOVERY-LICENSE-NOTICE automation): Discovery fetches the service's ToS URL, extracts keyword-flagged excerpts, and drafts the TOS-tier classification — user reviews and edits rather than authoring from scratch

## v2.5+ Requirements (Deferred)

Design hooks preserved in v2.0 state schema so these do not require a schema migration:

- **DIFF-01**: Cross-run DISCOVERY-REPORT diff (semantic, not textual) surfacing endpoint additions/removals/changes between runs (v2.5)
- **LEARN-01**: Learner system that auto-extracts reusable selector / auth patterns into `.omc/skills/`-style reusable skill files from Discovery debug sessions (v2.5)
- **TIER-01**: Multi-account tier-shape detection — run Discovery twice with different account tiers to detect endpoint shape differences (Free vs Pro) (v2.5)
- **CONTRACT-01**: Contract-test export format for downstream CI (Pact / OpenAPI examples / bespoke) (v2.5)

## Out of Scope (v2.0 and beyond unless noted)

| Feature | Reason |
|---------|--------|
| Fingerprint evasion / stealth plugins (`playwright-extra`, `puppeteer-extra-plugin-stealth`) | Violates target-vendor ToS and creates CFAA exposure; destroys AgentBloc's compliance-first brand |
| CAPTCHA solving services | ToS violation for solver vendor + target vendor; explicit anti-feature |
| TLS fingerprint (JA3 / JA4) spoofing | Same legal reasoning as fingerprint evasion |
| Brute-force credential discovery | Out of scope at the charter level |
| Writing to third-party services during Discovery | Discovery is read-only; any endpoint observed to be a write is documented but never called |
| MFA seed / passkey extraction | Permanent anti-feature — registering a persistent backdoor against a third party is not something AgentBloc ever does |
| Mobile app reverse engineering (Frida, iOS SSL pinning bypass) | Defer to v3.5+; out of scope for v2.0 |
| Browser extension reverse engineering | Defer; v2.0 targets web portals only |
| Residential / mobile proxy orchestration | Not in v2.0; documented env var hook `AGENTBLOC_DISCOVERY_PROXY` for future extension |
| Real-time streaming discovery reports (WebSocket) | Discovery emits static files; streaming would duplicate Telegram progress thread |

## Traceability (filled by roadmapper)

_To be populated by `gsd-roadmapper` in step 10._

**Coverage targets:**
- v1 requirements: 40 total (7 LEGAL + 21 DISC + 5 GOV + 6 SECR-EXT + 4 RDSV — P0 baseline) + 5 NICE (P1 optional)
- Mapped to phases: pending (8 internal dev phases proposed in `research/SUMMARY.md`)
- Unmapped: 0 (must verify after roadmap)

---

*Requirements defined 2026-04-18 after 4-agent research + synthesis (see `research/SUMMARY.md`).*
