# Phase 11: Integration Discovery — Browser Fallback - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in [11-CONTEXT.md](11-CONTEXT.md) — this log preserves the alternatives considered and the reasoning for each autonomous pick.

**Date:** 2026-04-21
**Phase:** 11-integration-discovery-browser-fallback
**Decision mode:** Autonomous (per `autonomous_mode` memo — Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + 2,603 lines of pre-pivot research + prior phases). No interactive AskUserQuestion calls; each area shows options considered and rationale.
**Areas discussed:** 14 gray areas — subagent structure · reference file count + split · DISCOVERY-REPORT.md schema · opt-in ledger scope · license notice commit policy · anti-bot policy enforcement · posture classification · checkpoint state + expiry · injection detector rules · PII redaction + verification · three-tier API classification · jurisdictional variance · CI lint implementation · phase-3-integration.md + SKILL.md wiring

---

## Subagent Structure and Tool Scope (→ D-43)

| Option | Description | Selected |
|--------|-------------|----------|
| Full Bash + WebFetch + Playwright MCP | Maximum flexibility | |
| Playwright MCP only + Read/Grep/Glob/Write | Matches BROWSER-01 explicit scope | ✓ |
| Subagent with no tools (pure reasoning) | Cannot accomplish the goal | |

**Auto-selected:** Playwright MCP + Read/Grep/Glob/Write + NO Bash + NO WebFetch.

**Notes:** BROWSER-01 explicitly says "Playwright MCP only." Research reinforces: subagent writes state + HAR + report files, Playwright MCP does the browser work. No Bash eliminates shell-escape risk (critical — this subagent interacts with adversarial third-party sites). No WebFetch prevents bypass of HAR capture (every HTTP call the subagent cares about must go through the browser session so it's captured + redacted + firewalled).

---

## Reference File Count and Split (→ D-44)

| Option | Description | Selected |
|--------|-------------|----------|
| Single mega-reference | One `browser-fallback.md` inline everything | |
| 2 refs: protocol + schema | Minimal but conflates stack/legal/firewall | |
| 5 refs by domain concern | protocol + stack + schema + firewall + legal | ✓ |
| 7 refs finer-grained | Splits firewall into injection.md + pii.md + verify.md | |

**Auto-selected:** 5 reference files — `browser-fallback.md` (imperative) + `browser-stack.md` (stack/pins/deny-list) + `discovery-report-schema.md` (output contract) + `output-firewall.md` (runtime firewall) + `legal-posture.md` (legal reference).

**Notes:** Each serves a distinct audience. `browser-fallback.md` = Claude at Phase 3 entry. `browser-stack.md` = CI lint + Claude. `discovery-report-schema.md` = subagent + v3.0 Builder Agent. `output-firewall.md` = subagent runtime + security reviewers. `legal-posture.md` = legal review + user audit. Collapsing any two conflates an audience's needs. 7-ref split is too granular — `output-firewall.md` is cohesive because injection + PII + fresh-context run as a pipeline on the same captured body.

---

## DISCOVERY-REPORT.md Schema Shape (→ D-45)

| Option | Description | Selected |
|--------|-------------|----------|
| Pure markdown body, no frontmatter | Simple but no machine-consumability | |
| JSON file alongside markdown | Two-file contract is brittle | |
| YAML frontmatter + markdown body + SHA256 | Machine + human readable, tamper-evident | ✓ |
| Full YAML (no markdown body) | Hostile to user audit | |

**Auto-selected:** YAML frontmatter (SHA256-signed) + structured markdown body.

**Notes:** BROWSER-02 mandates "YAML front-matter (schema-locked, SHA256 signed, expires_at field) + structured body." The SHA256 covers the body excluding the signature field itself — standard tamper-evidence pattern. `expires_at` defaults to `generated_at + 90 days` — aligned with trust-tier drift cadence (v1.0 INTG-04 uses 90-day commit freshness for HIGH tier; same window).

---

## Opt-In Ledger Scope (→ D-46)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-installation (user global) | Single ledger for all projects | |
| Per-project | Each project has own `.agentbloc/discovery/OPT_IN_LEDGER.jsonl` | ✓ |
| Per-service | One file per service | |
| Central registry (cloud) | Shared across users | |

**Auto-selected:** Per-project, append-only JSONL at `.agentbloc/discovery/OPT_IN_LEDGER.jsonl`.

**Notes:** Resolves research Open Decision #6. Per-project because (a) opt-in attestation is contextual to the project's data-subject scope, (b) per-installation would leak opt-ins across unrelated projects, (c) cloud-central violates the v2.0 file-based + no-new-services constraint. Append-only to support GDPR Article 30 record-of-processing. JSONL over JSON because appending is atomic.

---

## DISCOVERY-LICENSE-NOTICE.md Commit Policy (→ D-47)

| Option | Description | Selected |
|--------|-------------|----------|
| Committed to user's repo | Supports GDPR Article 30 trail | ✓ |
| Local-only (gitignored) | Reduces repo noise | |
| Ephemeral (deleted after session) | Fastest but no audit trail | |

**Auto-selected:** Committed to user's repo at `.agentbloc/discovery/<service-slug>/DISCOVERY-LICENSE-NOTICE.md`.

**Notes:** Resolves research Open Decision #7. Commit is the liability firewall for both parties — user can show consent, AgentBloc maintainers can show the gate was enforced. Research PITFALLS.md Pitfall 1 (ToS-Violation Shift) explicitly names "timestamped attestation log" as a mitigation; committed file satisfies that.

---

## Anti-Bot Policy Enforcement (→ D-48)

| Option | Description | Selected |
|--------|-------------|----------|
| Policy documented only (no enforcement) | Trusts convention | |
| Prose policy + CI deny-list lint | Document + enforce via CI | ✓ |
| Pre-commit hook + CI | Double enforcement | |
| Runtime enforcement (subagent refuses) | Inside the subagent's prose | also apply — |

**Auto-selected:** Prose policy in `browser-stack.md` + CI deny-list lint (`scripts/anti-bot-lint.sh`) + subagent prose refusal. Three-layer enforcement.

**Notes:** BROWSER-05 explicitly requires "CI deny-list lint rejects playwright-extra, puppeteer-extra-plugin-stealth, CAPTCHA solvers, fingerprint-spoofing libraries." Pre-commit is over-engineering for Phase 11 — CI enforcement catches the violation before it lands on main. Subagent-level refusal is the belt-and-suspenders layer for the case where a user runs the subagent locally without CI having caught a deny-listed dep.

---

## Posture Classification (→ D-49)

| Option | Description | Selected |
|--------|-------------|----------|
| Two tiers: friendly vs hardened | Too coarse — Cloudflare UAM needs different handling than DataDome | |
| Three tiers: A/B/C | Friendly / detected-but-navigable / hardened | ✓ |
| Five tiers: color-coded | Over-engineered — users can't calibrate 5 tiers | |

**Auto-selected:** Three tiers (A/B/C) with hard halt at C.

**Notes:** Research validates three-tier classification. Posture A = proceed with stock Playwright, Patchright NOT invoked. Posture B = switch to Patchright for CDP-leak patches only (documented in `browser-stack.md`). Posture C = HALT + `DISCOVERY-BLOCKED-REPORT.md` naming the detected vendor. Resolves research Open Decision #5 — Posture C is always halt; no v2.0 fallback.

---

## Checkpoint State Schema + Expiry (→ D-50)

| Option | Description | Selected |
|--------|-------------|----------|
| No checkpoint (single-shot only) | Violates BROWSER-08 | |
| 1-hour expiry | Too short for 2FA/SMS flow | |
| 4-hour expiry | Defensible upper bound per research | ✓ |
| 24-hour expiry | Too long — stale session cookies; user context fades | |
| Indefinite (no expiry) | Unsafe — user may not remember attesting | |

**Auto-selected:** 4-hour `expires_at` with 7-state lifecycle phase enum + resume-on-reinvocation logic.

**Notes:** BROWSER-08 mandates "4-hour pauses" as the defensible ceiling. Research ARCHITECTURE.md documents the 7-state lifecycle (opt-in-pending → har-capturing → endpoint-classifying → replay-validating → pii-redacting → injection-checking → report-writing). State.json stores current phase + per-phase artifacts; resume skips completed phases only if `now() < expires_at`.

---

## Injection Detector Rules (→ D-51)

| Option | Description | Selected |
|--------|-------------|----------|
| Regex-only detector | Fast but brittle | |
| LLM-only detector | Expensive, non-deterministic | |
| Regex pre-filter + fresh-context LLM verification | Best of both | ✓ |

**Auto-selected:** Three-layer regex (imperative strings + base64 blobs + invisible Unicode) + fresh-context Claude verification via `Task()` with `context: fork`.

**Notes:** Regex catches obvious attacks cheaply. Fresh-context verification catches sophisticated attacks the regex misses (e.g., natural-language injection without banned keywords). Critical: verification Claude sees ONLY the suspicious body, nothing else — prevents the injection from latching onto main-session context. Research PITFALLS.md (output-poisoning pitfalls 8-11) explicitly names this two-layer pattern.

---

## PII Redaction + Verification (→ D-52)

| Option | Description | Selected |
|--------|-------------|----------|
| Redact once, trust output | Fast but no integrity check | |
| Redact + verification scan on redacted output | Defense in depth | ✓ |
| Redact + LLM PII check | Expensive, non-deterministic | |
| No redaction (assume HAR is clean) | Unsafe | |

**Auto-selected:** Redact with regex set (IBAN / SSN / Luhn / E.164 / email) + verification scan applies the SAME regexes to the redacted output + block emit on any residual match.

**Notes:** BROWSER-11 mandates "PII redaction pipeline... with verification scan before emit". Two-pass redact-then-verify catches regex mutations from adjacent content (e.g., a redaction that leaves a visible SSN prefix due to regex off-by-one). Block-on-residual-match is the right severity — a leaked IBAN in a production DISCOVERY-REPORT.md is a liability event.

---

## Three-Tier API Classification (→ D-53)

| Option | Description | Selected |
|--------|-------------|----------|
| Binary: public vs private | Too coarse — misses INTERNAL-HARDENED | |
| Three tiers: DOCUMENTED / INTERNAL / INTERNAL-HARDENED | Matches research Pitfall 2 | ✓ |
| Four tiers: add UNKNOWN | INTERNAL already absorbs UNKNOWN w/ note | |
| Five tiers: color-coded + deprecation state | Out of scope | |

**Auto-selected:** DOCUMENTED / INTERNAL / INTERNAL-HARDENED — exact vocabulary from BROWSER-04.

**Notes:** Research PITFALLS.md Pitfall 2 (private-vs-public API confusion) explicitly calls out the three distinctions. INTERNAL-HARDENED endpoints (vendor-expressed intent that only their UI talks to it via anti-CSRF / custom headers) require a second user attestation addendum — vendor has raised a technical barrier that legal reasoning treats differently post-Van Buren.

---

## Jurisdictional Variance Matrix (→ D-54)

| Option | Description | Selected |
|--------|-------------|----------|
| Single "US + EU" section | Too coarse | |
| Five rows: US/UK/EU/DE/BR | Matches BROWSER-12 | ✓ |
| Ten+ rows (full EU member states) | Overkill for v2.0 | |

**Auto-selected:** 5 jurisdictions (US / UK / EU / DE / BR) × 4 columns (Law / Broadest interpretation / Safe-harbor / Highest-risk failure mode).

**Notes:** BROWSER-12 explicitly names "CFAA US, CMA UK, StGB DE, GDPR EU, LGPD BR." DE is called out separately from EU because BDSG §202a is broader than GDPR. BR treated separately because LGPD is GDPR-like but distinct. Other EU member states not itemized because BDSG §202a is the strictest — if a run is safe under DE law, it's safe under lighter EU member implementations.

---

## CI Anti-Bot Lint Implementation (→ D-56)

| Option | Description | Selected |
|--------|-------------|----------|
| No enforcement (prose only) | Violates BROWSER-05 | |
| Bash script in CI | Simple, zero deps | ✓ |
| TypeScript linter plugin | Over-engineered | |
| AST-based analyzer | Over-engineered | |
| npm audit custom rule | Limited to npm packages | |

**Auto-selected:** `scripts/anti-bot-lint.sh` bash script invoked from extended `.github/workflows/ci.yml`.

**Notes:** First executable code shipped in AgentBloc (v1.0 was markdown-only). Justified by BROWSER-05 mandating CI enforcement — can't be done in pure markdown. ~40 lines of bash, POSIX-compatible, greps `package.json` / `.mcp.json` / `pyproject.toml` / `requirements.txt` / `Gemfile` for 9 deny-listed package names. Zero runtime cost. Future v2.5+ may need an AST analyzer if the deny-list grows; bash is right-sized for Phase 11's 9-package list.

---

## Wiring: phase-3-integration.md + SKILL.md (→ D-57, D-58)

| Option | Description | Selected |
|--------|-------------|----------|
| Add all 5 refs to SKILL.md Phase 3 load-list | Phase 3 load balloons past 1,500 lines | |
| Add 2 refs (browser-fallback.md + browser-stack.md) | Budget-conscious; subagent loads the rest | ✓ |
| Add no refs; subagent loads everything | Main session can't scan the protocol | |

**Auto-selected:** 2 new See-lines in SKILL.md Phase 3 (browser-fallback + browser-stack). The other 3 refs (discovery-report-schema, output-firewall, legal-posture) load inside the `browser-discovery` subagent's forked context on invocation.

**Notes:** Applies Phase 10 plan-eng-review P-1 observation (Phase 3 load trending up). Main session needs the imperative protocol + declarative stack at Phase 3 entry to decide when to invoke the subagent. The schema + firewall + legal-posture are subagent-specific concerns; fork context gets them only when running. Net Phase 3 load after Phase 11: ~1,230 lines (was 966 after Phase 10, budget ceiling ~1,500).

Also adds NO new sub-gate — browser fallback is a sub-path of the existing `mcp_integrations_verified` sub-gate. Manifest entries with `resolution_method: browser-fallback` become `status: verified` when the DISCOVERY-REPORT.md exists + validates + SHA256 matches.

---

## Claude's Discretion

These gray areas left to Claude's implementation-time judgment — they don't materially change phase boundary:

- Exact prose wording of the jurisdictional variance matrix (D-54 rows are locked; prose is flexible)
- Mermaid diagram in `browser-fallback.md` (optional, ≤40 lines if included)
- Example TARGET.md template for user opt-in (ship a default, iterate)
- Regex tuning for Base64 detector (40-char minimum is default; may need adjustment)
- Retry budget default in governance.yaml (3 by default per D-55; raise to 5 if dogfood shows 3 insufficient)
- Fresh-context verification prompt wording (ship default, iterate)
- Whether DISCOVERY-LICENSE-NOTICE.md is surfaced to user via rendered summary (lean: yes, matches D-14)
- Exact bash script flavor (POSIX vs bash-specific features) — lean POSIX for maximum portability

## Deferred Ideas

Surfaced during analysis, belong to later phases or milestones (detail in [11-CONTEXT.md](11-CONTEXT.md) `<deferred>` section):

- Production TypeScript MCP generation from DISCOVERY-REPORT.md → v3.0 Builder Agent
- Cross-run DISCOVERY-REPORT.md drift detection → v2.5+
- Self-healing re-discovery on schema_mismatch → v4.0
- Multi-account tier-shape detection → v2.5+
- Contract-test export (Pact/OpenAPI) → v2.5+
- DISCOVERY-REPORT.md split at >30 endpoints → v2.5 optimization
- Manual session-cookie handoff (escape past Posture C) → v2.5+
- Mobile app reverse engineering (Frida, iOS SSL pinning bypass) → v3.5+
- Browser extension reverse engineering → deferred indefinitely

### Anti-features (explicitly rejected per REQUIREMENTS.md)

- Fingerprint evasion libraries — permanent reject (ToS + legal exposure)
- CAPTCHA solver services — permanent reject
- TLS fingerprint (JA3/JA4) spoofing — permanent reject
- Writing to third-party services during discovery (read-only) — permanent reject
- MFA seed / passkey extraction — permanent reject (registers persistent backdoor)

---

*Log preserved: 2026-04-21. Decision audit trail for Phase 11 Integration Discovery (Browser Fallback). See [11-CONTEXT.md](11-CONTEXT.md) for the canonical decisions that downstream agents consume.*
