# Feature Research — AgentBloc v2.0 Discovery Agent

**Domain:** Autonomous reverse-engineering agent (web portals + undocumented APIs) invoked as a subroutine from AgentBloc v1.0 Phase 3 (Integration Analysis) when no MCP or official API exists
**Researched:** 2026-04-18
**Confidence:** HIGH — prior-art implementation exists (`kalil0321/reverse-api-engineer`) that directly validates the core pattern; Playwright MCP, mitmproxy HAR support, OpenAPI DevTools, LangGraph checkpointing, Ralph loop are all current, battle-tested primitives
**Scope boundary:** Features the Discovery Agent itself needs. v1.0 interview/design/integration-analysis capabilities are OUT of scope for this document — see `milestones/v1.0-research/FEATURES.md` for baseline.

---

## Feature Landscape

### Table Stakes (Users Expect These — v2.0 must-have)

Non-negotiable for v2.0 MVP. Missing any of these = the Discovery Agent is either broken, dangerous, or produces output that cannot feed the v3.0 Builder Agent. Ordered by criticality (T1 is load-bearing for everything else).

| # | Feature | Why Expected / Why Required | Complexity | Notes |
|---|---------|------------------------------|------------|-------|
| **T1** | **Scoped-target contract from Phase 3 (handoff schema)** | Discovery Agent must be invoked with a clearly-bounded target (service + required actions + success criteria), not a blank "go discover stuff" prompt. Phase 3 already produces a list of per-action integration failures ("no MCP for ClickUp.add_comment"). The Discovery Agent must consume that list verbatim as its input. Without a contract, scope explodes and results are unusable for v3.0 Builder Agent | LOW | New file: `.agentbloc/discovery/TARGET.md` emitted by Phase 3 handoff. Schema: `{service, base_url, required_actions[], auth_hint, data_classification, user_opt_in_signed_at}`. v1.0 Phase 3 already collects this info — just needs explicit write-out. **Blocks everything downstream** |
| **T2** | **Legal opt-in gate per service (ToS disclaimer)** | Reverse-engineering private APIs can violate ToS (OpenAI, Google explicitly prohibit it in their terms). v1.0 product posture is "potential product, built with legal/compliance in mind from day 1" — shipping a discovery agent that scrapes without consent is an existential risk. User must explicitly confirm per service, and the opt-in must be recorded in the target contract | LOW (implementation) / HIGH (wording) | Hard gate before any browser launches. Pattern: read TARGET.md → display disclaimer → require literal confirmation phrase from user → record timestamp + service in `.agentbloc/discovery/OPT_IN_LEDGER.json`. Disclaimer wording should be reviewed (MVP can use a strong default from EFF reverse-engineering FAQ) |
| **T3** | **HAR capture via Playwright MCP** | Industry standard. `kalil0321/reverse-api-engineer` (prior art) is literally a fork of Playwright MCP that adds native HAR. mitmproxy also exports HAR natively. HAR is the lingua franca of browser traffic — v3.0 Builder Agent will parse HAR to generate MCP code | LOW | Playwright MCP supports network interception and request capture today (2026). `recordHar` option on context. Save per-run to `.agentbloc/discovery/<service>/captures/run-<id>.har`. **Every discovery run starts with HAR enabled** |
| **T4** | **Request replay with curl validation** | Captured requests must be REPLAYABLE. If the agent can't re-run a request outside the browser with curl and get a valid response, the "discovery" is a hallucination. Same pattern v1.0 uses for integration evidence (URL + version + commit-date): endpoint claims are tagged `[UNVERIFIED]` until a curl call succeeds | LOW | For each captured request, generate a curl command (existing tools: `har-to-curl`, `hargo`, `curlconverter`). Execute. Store response. Compare response shape to original browser capture. Mark endpoint VERIFIED only if replay succeeds. Extends v1.0 evidence protocol |
| **T5** | **Auth flow extraction (cookies / JWT / OAuth / session)** | Every non-trivial service has auth. Discovery is useless without documenting HOW auth works. Must detect and classify: session cookies (extract `Set-Cookie` headers, note `HttpOnly`/`SameSite`), JWT bearer tokens (decode header/payload, note expiry), OAuth redirect flows (capture auth URL, token endpoint, scopes), CSRF tokens (identify header name + refresh behavior). Without this, v3.0 Builder Agent cannot generate a working MCP | MEDIUM | Auth classifier runs post-HAR. Heuristics: `Authorization: Bearer <jwt>` → JWT flow, `Set-Cookie: session=...; HttpOnly` → session flow, redirect to `accounts.google.com/o/oauth2` → OAuth2. Output to `DISCOVERY-REPORT.md` auth section. Redact token values in report (security) |
| **T6** | **Multi-turn workflow discovery (pausable)** | Real workflows span minutes to hours: login → wait for 2FA email → verify → navigate → trigger target action. The agent must be able to pause, yield control to the human (for 2FA codes, CAPTCHAs, email clicks), and resume without losing state. v1.0 Phase 6 Evolution already assumes cron-triggered batch; Discovery is the first AgentBloc capability that requires true session persistence. LangGraph-style checkpoint is the canonical pattern | MEDIUM | Checkpoint after every major action (login-started, login-complete, navigated-to-target, captured-request). State file: `.agentbloc/discovery/<service>/state.json`. On resume: read state → reattach to browser context → continue from last checkpoint. Human-approval gates injected at known friction points (2FA, CAPTCHA). Timeout after 4 hours of human inactivity → dump state + Telegram alert |
| **T7** | **Ralph-style retry loop for brittle selectors + anti-bot** | Selectors break (DOM changes, A/B tests, anti-bot injects noise). Anti-bot responds with 403/429/CAPTCHA. A single-shot discovery is guaranteed to fail intermittently. Ralph pattern (fixed prompt + persistence + retry ledger + bounded max-iterations) is the proven Claude Code primitive for this. OMC `/ralph` is a named, battle-tested implementation | MEDIUM | Per captured-request-attempt, retry up to N times (configurable, default 3) with adjusted heuristics each iteration: (1) try `get_by_role` → (2) try `data-testid` → (3) try text content → (4) try visual position via screenshot. Retry ledger: `.agentbloc/discovery/<service>/retries.jsonl` with one row per attempt (what failed, why, what was tried next). Max total iterations per session = 20 (hard cap to prevent runaway LLM cost) |
| **T8** | **Rate-limit detection + backoff** | 429 responses with `Retry-After` headers are the standard signal. Custom rate-limit headers (`X-RateLimit-Remaining`, `X-RateLimit-Reset`) are common. Without detection, the agent keeps hammering and gets the user's IP banned. 2026 anti-bot systems escalate from IP rate-limit → IP ban → network-wide fingerprint flag. Must respect servers, period | LOW | Parse every response. On 429: read `Retry-After` (seconds or HTTP-date), sleep, retry once, then abort if still 429. Record per-endpoint: `rate_limit_detected`, `retry_after_observed`, `custom_headers`. Adaptive pacing: if `X-RateLimit-Remaining` < 5, pre-emptively slow to 1 request per 2 seconds |
| **T9** | **Error classification (success / retry / abort / human-needed)** | Not every error is retriable. 401 = auth expired (get new session), 403 = forbidden (abort, log, alert), 429 = rate-limited (backoff), 5xx = server error (retry with exponential backoff), CAPTCHA = human-needed (pause for human). Without classification, agent retries 403s and gets banned | LOW | Decision table per HTTP status + content pattern. CAPTCHA detection via known page-marker heuristics (Cloudflare, reCAPTCHA, hCaptcha) — exits the loop and pauses. All classifications logged to retry ledger |
| **T10** | **DISCOVERY-REPORT.md as structured, consumable output** | The REPORT is the handoff artifact to (a) the human reviewer and (b) the v3.0 Builder Agent. Must be parseable (Builder Agent reads it as input to generate TypeScript MCP). Must be human-reviewable (user approves before v3.0 Builder runs). Schema must be stable — changing it is a breaking change downstream | MEDIUM | See "DISCOVERY-REPORT.md schema" section below. YAML front-matter for machine-read, markdown body for humans. Per-endpoint subsections. Per-auth-flow subsection. Per-known-limitation subsection. **Design this schema BEFORE implementing capture logic** — otherwise capture shape drifts from output shape |
| **T11** | **Redaction of secrets in the report** | HAR files contain tokens, session cookies, API keys, sometimes PII in response bodies. The report must redact these before it's written to disk / committed to git / shared with a consultant. v1.0 already mandates audit-log redaction patterns — extend to discovery output | LOW | Redaction patterns applied before writing DISCOVERY-REPORT.md: `Authorization: Bearer <REDACTED>`, `Cookie: session=<REDACTED>`, JWT payloads stripped of `sub`/`email`, JSON response bodies have email/phone/name-pattern strings replaced with `<REDACTED_PII>`. Original HAR kept in `.agentbloc/discovery/<service>/captures/` (gitignored by default) |
| **T12** | **Kill switch + observable progress** | Long-running agent with browser control needs a stop button. v1.0 kill-switch file pattern (`.agentbloc/KILL_SWITCH`) extends naturally. Also must emit periodic status to Telegram (same thread-per-service pattern as v1.0) so user knows agent is alive and what it's doing | LOW | Before each major action: check `KILL_SWITCH` file → exit cleanly if present (save state, close browser). Every N minutes or major-checkpoint: Telegram message to discovery thread: "Discovered endpoint 3/7, now extracting auth flow". Human can reply `/stop` → writes KILL_SWITCH file |

### Differentiators (Competitive Advantage — v2.0 nice-to-have or v2.5)

Features that raise Discovery Agent quality above the prior-art baseline (`reverse-api-engineer` captures traffic and generates a Python client — that's it). These are where AgentBloc's edge lives. Each labeled **v2.0 nice-to-have** (ship if there's time) or **v2.5 defer** (ship in next milestone).

| # | Feature | Value Proposition | Complexity | v2.0 / v2.5 | Notes |
|---|---------|-------------------|------------|-------------|-------|
| **D1** | **JSON schema inference from response bodies** | Every endpoint returns JSON with some shape. Inferring the schema (field names, types, nullability, array vs scalar) is what makes the DISCOVERY-REPORT actually useful — v3.0 Builder Agent generates TypeScript types from it. OpenAPI DevTools already does this for a browser extension. Prior art: `json-re`, Hackolade, FastTool. Best practice: infer from 3+ sample responses, not 1 | MEDIUM | **v2.0 nice-to-have** | Collect 3+ sample responses per endpoint (across different query params / data states). Run a schema-inference algorithm (merge field unions, detect optional fields, tag enum-candidates). Output OpenAPI 3.1 fragment per endpoint. This is THE differentiator that makes the report Builder-Agent-ready |
| **D2** | **Semantic endpoint clustering** | A discovery session often captures 50-200 requests. Many are noise (telemetry, analytics, tracking). Many are variations of the same endpoint (`/api/items/1`, `/api/items/2`, `/api/items/42`). Clustering by path pattern + response-shape similarity produces 5-15 canonical endpoints from the raw capture. OpenAPI Initiative's Moonwalk SIG (2026) explicitly calls out "agent-ready grouping" as an open problem | MEDIUM | **v2.5 defer** | Normalize paths (`/api/items/1` → `/api/items/{id}`), group by normalized-path + method, collapse into canonical entries. Filter likely-noise (telemetry domains, known-ad-tech patterns). Prior tool to borrow from: `mitmproxy2swagger`. **Defer to v2.5:** v2.0 can ship with "one row per unique URL" and let the human cluster during review |
| **D3** | **Anti-bot detection with defense playbook** | Detection of Cloudflare, PerimeterX, DataDome, hCaptcha by page markers / response headers. When detected: emit a structured finding ("service is protected by Cloudflare Managed Challenge — discovery here requires manual session transfer or anti-detect browser, out of v2.0 scope"), NOT a workaround. This is the honest differentiator: we detect, report, and degrade gracefully — we don't ship fingerprint evasion | LOW | **v2.0 nice-to-have** | Known-marker detection is cheap. Playbook is a reference file in `references/anti-bot-playbook.md`: "Cloudflare → user can manually transfer session cookies", "hCaptcha → requires human interaction mode", "DataDome → service is hardened, recommend contacting vendor for API access". This is an **anti-feature-adjacent** but legitimate: "we report the wall, we don't scale it" |
| **D4** | **Learner pattern emission (skill-ization)** | OMC's learner system auto-extracts reusable skills into `.omc/skills/` from debug sessions. Same pattern applied to discovery: when a novel auth flow or pagination pattern is discovered, emit a reusable skill template to `.agentbloc/skills/`. Next time a similar pattern is hit, the Discovery Agent uses the cached skill first. Foundation for v4.0 Self-Healing (broken MCP → re-discover → emit fresh skill) | MEDIUM | **v2.5 defer** | Out of v2.0 scope. But: **design the discovery state schema now so this is possible in v2.5 without rewrite.** Add `patterns_observed[]` field to state.json. v2.5 consumes patterns_observed to emit skills |
| **D5** | **Diff-based change detection across runs** | Run discovery against same service twice (a week apart). Did the endpoints change? New field added to response? Auth-token format changed? This is the foundation of v4.0 Self-Healing ("MCP started failing → auto-run discovery → diff → propose patch"). v2.0 just needs to store each run atomically so diff is possible later | LOW (storage) / MEDIUM (diff algorithm) | **v2.0 nice-to-have (storage only) / v2.5 (diff algo)** | v2.0: ensure each run is stored immutably at `.agentbloc/discovery/<service>/runs/<timestamp>/`. v2.5: diff algorithm compares two runs, emits `CHANGE-REPORT.md` |
| **D6** | **Socratic target-scoping interview** | Before launching browser, have a Socratic dialogue with the user: "Which exact action? What's the minimum data you need? What's the happy-path workflow you do manually today?" Borrowed from Superpowers spec-extraction methodology + GStack `/office-hours` + OMC `/deep-interview`. Prevents over-scoped discovery (capturing 200 irrelevant endpoints when the user only needs 3). In v1.0 the interview happens in Phase 1; Discovery needs its own mini-interview | LOW | **v2.0 nice-to-have** | Three-question pre-flight: (1) "Show me the exact button/link you click to do this manually", (2) "What's the minimum output you need? (JSON field list)", (3) "How often would you do this?" (informs rate-limit planning). Implement as `discovery-interview.md` reference skill |
| **D7** | **Evidence protocol extension (URL + capture + replay timestamp)** | v1.0's integration evidence protocol (URL + version + last-commit-date) is table stakes for OFFICIAL MCPs. Discovery Agent produces a different kind of evidence: capture-timestamp + replay-success + response-hash. Extending the same [UNVERIFIED] convention into DISCOVERY-REPORT.md keeps one mental model for the user | LOW | **v2.0 nice-to-have (trivially cheap)** | Per endpoint in report: `evidence: {captured_at, replay_verified_at, response_hash, sample_count}`. Endpoints without successful replay tagged `[UNVERIFIED]` same as v1.0. Consistency is the win |
| **D8** | **Pagination & dependency graph detection** | Endpoints often depend on each other: `/api/collections` returns IDs → `/api/collections/{id}/items` returns items → `/api/items/{id}/detail`. Pagination patterns (`?page=N`, cursor-based, offset-based) are a subclass of this. Detecting the graph lets v3.0 Builder generate a coherent SDK, not a flat list of unrelated endpoints | MEDIUM | **v2.5 defer** | Analyze response bodies for ID-shaped fields, cross-reference with URLs of subsequent requests. This is genuinely useful but moderately complex — v2.0 ships flat, v2.5 adds the graph |
| **D9** | **Cost observability per discovery run** | Discovery is LLM-heavy (analysis of each captured request, each retry, each schema inference). A single run can cost $5-50 in Claude calls. Exposing cost to the user before and during the run is a trust feature (and differentiator — no prior-art tool does this). v1.0 doesn't estimate LLM cost anywhere today | LOW | **v2.0 nice-to-have** | Token counter + estimated cost emitted to Telegram at each checkpoint. Hard budget cap: `.agentbloc/discovery/<service>/budget.yaml` with `max_usd`. Abort if exceeded. Foundation for v3.0+ cost model |

### Anti-Features (Deliberately NOT Building — Legal, Ethical, or Scope)

Features that either (a) would cross a legal/ethical line AgentBloc must not cross, (b) duplicate what already exists in an ethical tool the user should use instead, or (c) balloon v2.0 scope into a v3.0+ product. Each with explicit reasoning.

| # | Feature | Why Requested | Why We Refuse | What to Do Instead |
|---|---------|---------------|---------------|--------------------|
| **A1** | **Fingerprint evasion / anti-detect browser integration** (Camoufox, Gologin, Nstbrowser) | "The target service blocks Playwright. Work around it." | **LEGAL + ETHICAL red line.** Bypassing fingerprint detection is the exact behavior targeted by CFAA "exceeds authorized access" cases. 2026 anti-bot systems apply temporal rules — one bad actor gets "your whole operation flagged" (Fingerprint, 2026). AgentBloc's brand is security + compliance; shipping fingerprint-rotation tooling destroys consulting credibility | Detect the wall (**D3**). Report it honestly in DISCOVERY-REPORT.md. Recommend user contact the vendor for API access, or use an anti-detect browser themselves outside AgentBloc if they accept the legal risk |
| **A2** | **Brute-force credential discovery** | "User forgot creds, let the agent try common passwords" | **ILLEGAL.** Unauthorized access under CFAA, Computer Misuse Act (UK), equivalent statutes globally. Not even worth discussing | Discovery requires the user to be logged in OR to paste valid credentials into the agent. No credential guessing. Ever |
| **A3** | **ToS-violating mass scraping** (crawl entire site, extract all data) | "Just grab everything, we'll figure out what we need later" | **ToS violation + robots.txt violation + server-overload liability.** France CNIL (2026) explicitly considers robots.txt non-compliance as a strong negative signal. EU AI Act penalties reach €35M or 7% of global revenue for data-provenance failures. Mass scraping is NOT what Discovery Agent is for | Discovery Agent is scoped to N specific actions (from TARGET.md handoff). N is typically 3-10. Each action produces 1-5 endpoints. Never crawl outside scope. `robots.txt` is checked and respected before browser launches |
| **A4** | **CAPTCHA-solving services** (2Captcha, Anti-Captcha, reCAPTCHA bypass libraries) | "reCAPTCHA blocks the flow, let's solve it automatically" | **ToS violation (all CAPTCHA services prohibit automated solving of their CAPTCHAs).** Also legally fraught — solving CAPTCHA to access a service you're not authorized to access escalates CFAA exposure | CAPTCHA detected → pause → notify human via Telegram → human solves in browser → agent resumes. Human-in-the-loop (table stakes T6) handles this |
| **A5** | **Mobile app reverse engineering (APK/IPA + Frida)** in v2.0 | "Many services only have mobile apps — add Frida support" | **SCOPE EXPLOSION.** Mobile reverse engineering is a separate discipline: SSL pinning bypass, runtime instrumentation, root/jailbreak detection, app-store ToS, Apple's anti-hooking protections. Each is a 3-6 month research project. v1.0 handoff explicitly flagged this as "open question for next session" and the answer is: **web-only in v2.0.** Revisit for v3.5 or later | Web portals only. If a service is mobile-only, DISCOVERY-REPORT.md records "mobile-only service — out of v2.0 scope" and suggests the user request an official API from the vendor |
| **A6** | **Headless + stealth combo for production discovery runs** | "Run headless so it's faster and invisible" | **Escalates anti-bot detection.** Headless-Chromium has known fingerprints (missing Chrome runtime APIs, `navigator.webdriver === true`). Detection triggers the exact fingerprint-flag cascade we're trying to stay clear of (A1). Also "invisible" is a posture opposite to what a compliance-first product does | Run headed by default (visible browser window). User can watch the agent work. If performance matters, that's a v3.0+ runtime optimization (sandboxed containers, multiple workers) — not a v2.0 feature |
| **A7** | **Automatic login with user's personal credentials** | "Let the agent log in for me, I'll paste my password" | **SECURITY red flag.** Credentials pasted to the agent flow through LLM context, get logged, persist in conversation history, risk exfiltration. Violates v1.0 credential-hierarchy principle (OAuth > scoped API key > admin token, never personal passwords) | **User logs in manually** in the visible browser window the Discovery Agent launches. Agent attaches to the logged-in session. No credentials ever flow through the LLM. OMC's live-browser-attach pattern is the reference |
| **A8** | **Auto-publish discovered endpoints as a public MCP** | "Save time, make discovery output directly usable" | **Wrong milestone.** Generating a working MCP is the v3.0 Builder Agent's entire job. Shipping an MCP-generator inside v2.0 means v2.0 and v3.0 are the same milestone, which defeats the purpose of iterative scoping. v2.0 produces a **report**; v3.0 produces **code** | DISCOVERY-REPORT.md is the clean handoff to v3.0 Builder Agent. Keep boundaries sharp |
| **A9** | **Visual DAG / workflow editor for discovery runs** | "I want to see the discovery flow visually before running" | **Not conversational.** Same anti-feature reasoning as v1.0 A1 (no visual workflow builder). Conversation IS the interface | ASCII summary in Telegram ("Step 1: login → Step 2: navigate → Step 3: capture"). If user wants to drag nodes, recommend n8n + Playwright for that workflow |
| **A10** | **Running Discovery Agent against a service the user does not have an account on** | "Let's discover the API for a competitor we don't pay for" | **Unauthorized access.** Even reading a service's public endpoints while not logged in can cross ToS lines. And discovering a private API of a service you don't have legitimate access to is squarely CFAA territory | Pre-flight check: user must confirm they have a valid active account/subscription for the target service. Recorded in OPT_IN_LEDGER.json |

---

## DISCOVERY-REPORT.md Schema

**Why this schema matters:** The report is the v2.0 → v3.0 contract. Builder Agent will parse it to generate TypeScript MCP. Human reviewer will approve it before Builder runs. Changing this schema post-v2.0 is a breaking change.

**Canonical structure:**

```markdown
---
service: clickup
service_url: https://app.clickup.com
discovered_at: 2026-04-18T14:23:00Z
discovery_runtime_minutes: 47
user_opt_in_recorded_at: 2026-04-18T14:22:11Z
target_actions:
  - list_projects
  - add_comment_to_task
  - fetch_task_detail
endpoints_discovered: 7
endpoints_verified: 5
endpoints_unverified: 2
auth_flow_type: session_cookie_with_csrf
rate_limit_observed: "60 req/min per IP, X-RateLimit-Remaining header present"
anti_bot_detected: none
known_limitations:
  - "Pagination uses cursor, not observed across full dataset"
confidence: HIGH
---

# Discovery Report: ClickUp

## Executive Summary
[3-5 sentence human-readable summary]

## Authentication Flow
**Type:** Session cookie + CSRF header
**Login URL:** https://app.clickup.com/login
**Session cookie name:** cu_session (HttpOnly, Secure, SameSite=Lax)
**CSRF header:** X-Requested-With: XMLHttpRequest
**Token refresh:** Session is refreshed on each authenticated request; no explicit refresh endpoint observed
**Expiry:** 30 days (from Set-Cookie Max-Age)

## Endpoints

### 1. list_projects — VERIFIED
**Method:** GET
**URL pattern:** /api/v2/team/{team_id}/space
**Auth required:** Yes (session cookie)
**Captured_at:** 2026-04-18T14:26:17Z
**Replay_verified_at:** 2026-04-18T14:26:23Z
**Response_hash:** sha256:a1b2...
**Sample_count:** 3

**Request headers (relevant):**
- Cookie: cu_session=<REDACTED>
- X-Requested-With: XMLHttpRequest

**Query params:** none

**Response shape (inferred from 3 samples):**
\`\`\`json
{
  "spaces": [
    {"id": "string", "name": "string", "private": "boolean", "archived": "boolean"}
  ]
}
\`\`\`

**Notes:** Empty `spaces` array when user has no projects. 200 status for both populated and empty.

---

### 2. add_comment_to_task — VERIFIED
[...]

### 3. fetch_task_detail — UNVERIFIED
**Reason unverified:** Replay returned 403 despite cookie being valid in browser. Suspect additional fingerprint header required (under investigation).
**Next steps:** Manual investigation of request signing.

## Rate Limits
**Observed:** 60 requests/min per IP
**Headers present:** X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
**429 encountered:** Yes, 1 time during run. Retry-After: 23 seconds. Honored successfully.

## Pagination
**Pattern:** Cursor-based via `?next_cursor=...` query param
**Sample:** See endpoint 1
**Limitation:** Full pagination cycle not exercised (would require test data at scale)

## Anti-Bot / Security
**Detected:** None (no Cloudflare challenge, no reCAPTCHA, no DataDome markers)
**Login requires:** Email + password + optional 2FA
**Session stability:** Stable across tabs; survived network interruption during test

## Known Limitations & Risks
- fetch_task_detail endpoint returned 403 in replay — not production-ready
- Pagination cursor behavior at scale not tested
- 2FA flow was bypassed during this run (user already had active session) — 2FA flow itself not documented

## Evidence Files (gitignored)
- HAR capture: `.agentbloc/discovery/clickup/captures/run-20260418-1423.har`
- Retry ledger: `.agentbloc/discovery/clickup/retries.jsonl`
- State snapshots: `.agentbloc/discovery/clickup/state.json`

## Handoff Notes for v3.0 Builder Agent
- Generate TypeScript MCP with 2 tools: `list_projects`, `add_comment_to_task`
- Skip `fetch_task_detail` until UNVERIFIED status is resolved
- Auth layer: session-cookie-with-CSRF pattern (see reference implementation in `references/auth-patterns.md`)
- Rate limit: respect X-RateLimit-Remaining, slow to 1 req/2s below 5 remaining
```

**How humans use the report:**
1. Read executive summary (is this what I asked for?)
2. Review each endpoint (does this match my intended action?)
3. Check UNVERIFIED section (what's broken and why?)
4. Approve or send back for re-discovery

**How v3.0 Builder Agent consumes the report:**
1. Parse YAML front-matter for machine-readable metadata
2. Iterate endpoints → generate one TypeScript MCP tool per VERIFIED endpoint
3. Use auth flow section → generate auth middleware
4. Use rate-limit section → generate rate-limit respect logic
5. Skip UNVERIFIED endpoints (or flag them in generated code)

---

## Feature Dependencies

```
[T1: Target Contract]
    └── blocks everything. Without TARGET.md from Phase 3, nothing runs.

[T2: Legal Opt-In Gate]
    └── blocks T3+. Without signed opt-in, browser never launches.

[T3: HAR Capture]
    ├── feeds [T4: Replay]
    ├── feeds [T5: Auth Extraction]
    ├── feeds [T8: Rate-Limit Detection]
    ├── feeds [D1: Schema Inference] (if enabled)
    └── feeds [T10: DISCOVERY-REPORT.md]

[T6: Multi-turn Workflow] (checkpointing)
    ├── enables pauses for 2FA / CAPTCHA
    ├── enables resume-after-crash
    └── is foundation for [D5: Diff across runs]

[T7: Ralph Retry Loop]
    ├── consumes [T9: Error Classification]
    ├── writes to retry ledger
    └── bounded by max-iterations + [D9: Cost Budget]

[T11: Redaction]
    └── wraps [T10: Report Output]. Runs BEFORE report is written to disk.

[T12: Kill Switch]
    └── observed by all long-running loops. Check before each major action.

[D1: Schema Inference] ─enhances─> [T10: Report] — makes report Builder-ready
[D3: Anti-Bot Detection] ─enhances─> [T9: Error Classification] — adds CAPTCHA/Cloudflare branches
[D4: Learner Pattern] ─requires─> [T6 state schema] — must be designed into v2.0 even if implemented in v2.5
[D5: Diff across runs] ─requires─> immutable run storage in v2.0
[D6: Socratic Interview] ─enhances─> [T1: Target Contract] — sharpens scope pre-flight
[D7: Evidence Protocol] ─enhances─> [T10: Report] — consistent with v1.0 integration-evidence convention
```

### Dependency Notes

- **T1 (Target Contract) and T2 (Opt-In) are hard gates.** No code executes before both are satisfied. Without T1, scope is unbounded. Without T2, legal liability.
- **T3-T5 are one tightly-coupled capture-and-extract pipeline.** Can't ship any one without the other two — a HAR with no replay validation is hallucination territory; auth extraction without HAR has nothing to extract from.
- **T6 (Checkpointing) is the single largest complexity driver.** The difference between a "captures a login" toy and a "resumes after a 3-hour 2FA wait" production tool is checkpointing. LangGraph pattern (not runtime) is the reference.
- **T7 (Ralph Loop) + T8 (Rate Limit) + T9 (Error Classification) interlock.** All three write to the same retry ledger. All three respect the same cost budget.
- **T10 (Report) is the load-bearing artifact.** Schema stability matters more than feature completeness — if schema changes post-v2.0, every v3.0 Builder change breaks. **Design schema in phase 1 of v2.0, freeze it, then build backward from the schema.**
- **T11 (Redaction) is a BLOCKING safety feature.** Cannot ship v2.0 without redaction — first user to accidentally commit a HAR with their bearer token to GitHub is a reputational disaster.
- **D4 (Learner), D5 (Diff), D8 (Dependency Graph) are explicitly deferred to v2.5.** But T6's state schema must accommodate them — design now, implement later.

---

## MVP Definition

### Launch With (v2.0 Discovery Agent MVP)

Minimum to validate the thesis: "AgentBloc v1.0 hit 'no MCP found' for a service. The Discovery Agent produces a report the user trusts enough to hand off to v3.0 Builder."

- [ ] **T1: Target contract handoff from Phase 3** — new file schema
- [ ] **T2: Legal opt-in gate + OPT_IN_LEDGER.json** — hard gate before browser launch
- [ ] **T3: Playwright MCP HAR capture** — per-run HAR file
- [ ] **T4: curl replay validation per endpoint** — verified vs unverified flag
- [ ] **T5: Auth flow extraction (cookie / JWT / OAuth classifier)** — one auth section per report
- [ ] **T6: Checkpointed multi-turn workflow** — pausable up to 4 hours, resume from state.json
- [ ] **T7: Ralph-style retry loop with retry ledger** — max 20 iterations, retry budget per endpoint
- [ ] **T8: Rate-limit detection (429 + Retry-After + custom headers)** — backoff enforced
- [ ] **T9: Error classification decision table** — 401 / 403 / 429 / 5xx / CAPTCHA branches
- [ ] **T10: DISCOVERY-REPORT.md with frozen schema** — YAML front-matter + markdown body
- [ ] **T11: Redaction of secrets before report write** — mandatory
- [ ] **T12: Kill switch + Telegram status updates** — observability

### Add In v2.0 Nice-to-Have (ship if time permits)

- [ ] **D1: JSON schema inference from 3+ samples** — makes report Builder-ready, biggest quality leap
- [ ] **D3: Anti-bot detection with honest "we hit a wall" output** — protects legal posture
- [ ] **D6: Socratic target-scoping interview** — sharpens TARGET.md
- [ ] **D7: Extended evidence protocol consistency with v1.0** — trivially cheap
- [ ] **D9: Cost observability per run + budget cap** — trust feature

### Defer to v2.5 (explicitly NOT v2.0)

- [ ] **D2: Semantic endpoint clustering** — v2.0 ships "one row per unique URL"
- [ ] **D4: Learner pattern emission (skill-ization)** — design state schema to accommodate, implement in v2.5
- [ ] **D5: Diff-based change detection across runs** — v2.0 ships immutable run storage only, diff algo in v2.5
- [ ] **D8: Pagination + dependency graph detection** — v2.0 ships flat endpoint list

### Future Consideration (v3.0+)

- [ ] **Builder Agent** (consumes DISCOVERY-REPORT.md, generates TypeScript MCP) — v3.0 milestone
- [ ] **Self-Healing Evolution** (broken MCP → auto-rediscover → propose patch) — v4.0 milestone
- [ ] **Mobile (APK/IPA + Frida)** — v3.5 or later, if SMB demand surfaces
- [ ] **Multi-service discovery in parallel** — scale concern, only if v2.0 validates single-service thesis

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Milestone |
|---------|------------|---------------------|----------|-----------|
| T1: Target contract handoff | HIGH | LOW | **P0** | v2.0 |
| T2: Legal opt-in gate | HIGH (compliance-critical) | LOW | **P0** | v2.0 |
| T3: HAR capture via Playwright MCP | HIGH | LOW | **P0** | v2.0 |
| T4: curl replay validation | HIGH (trust) | LOW | **P0** | v2.0 |
| T5: Auth flow extraction | HIGH | MEDIUM | **P0** | v2.0 |
| T6: Checkpointed multi-turn workflow | HIGH | MEDIUM | **P0** | v2.0 |
| T7: Ralph retry loop | HIGH | MEDIUM | **P0** | v2.0 |
| T8: Rate-limit detection | HIGH (safety) | LOW | **P0** | v2.0 |
| T9: Error classification | HIGH | LOW | **P0** | v2.0 |
| T10: DISCOVERY-REPORT.md schema | HIGH (load-bearing) | MEDIUM | **P0** | v2.0 |
| T11: Redaction | HIGH (safety) | LOW | **P0** | v2.0 |
| T12: Kill switch + status | MEDIUM | LOW | **P0** | v2.0 |
| D1: JSON schema inference | HIGH (Builder-readiness) | MEDIUM | **P1** | v2.0 nice-to-have |
| D3: Anti-bot detection | MEDIUM (legal posture) | LOW | **P1** | v2.0 nice-to-have |
| D6: Socratic interview | MEDIUM | LOW | **P1** | v2.0 nice-to-have |
| D7: Evidence protocol extension | MEDIUM | LOW | **P1** | v2.0 nice-to-have |
| D9: Cost observability | MEDIUM (trust) | LOW | **P1** | v2.0 nice-to-have |
| D2: Endpoint clustering | MEDIUM | MEDIUM | **P2** | v2.5 |
| D4: Learner pattern emission | HIGH (future leverage) | MEDIUM | **P2** | v2.5 (design in v2.0) |
| D5: Diff across runs | HIGH (foundation for v4.0) | MEDIUM | **P2** | v2.5 (storage in v2.0) |
| D8: Dependency graph | MEDIUM | MEDIUM | **P2** | v2.5 |

**Priority key:**
- P0: Non-negotiable for v2.0 MVP (table stakes)
- P1: v2.0 nice-to-have (ship if time permits, not a blocker)
- P2: Deferred to v2.5 (but design foundations in v2.0 where cheap)

---

## Competitor / Prior-Art Feature Analysis

| Feature | reverse-api-engineer | OpenAPI DevTools | mitmproxy + mitmproxy2swagger | Apify | Playwright MCP (alone) | **AgentBloc v2.0 Discovery Agent** |
|---------|---------------------|-------------------|-------------------------------|-------|-------------------------|-------------------------------------|
| **Form factor** | Claude skill | Browser extension | CLI + addons | SaaS + actors | MCP server | **Claude skill invoked from v1.0 Phase 3** |
| **Autonomy** | Agent mode (one-shot) | Manual browsing | Manual replay + scripts | Programmatic actors | Manual driving | **Fully autonomous with checkpointed pause/resume** |
| **HAR capture** | Yes (forked Playwright MCP) | Yes (live traffic) | Yes (native) | No (uses own format) | Partial (via CDP) | **Yes (via Playwright MCP native HAR)** |
| **Replay validation** | Implicit (generates client, assumes success) | No | Yes (mitmdump -r) | No | No | **Mandatory curl replay, VERIFIED/UNVERIFIED flags** |
| **Auth flow extraction** | Basic (docs mention "authentication handling") | No (just captures) | No (generic traffic) | Per-actor | No | **Classifier: cookie / JWT / OAuth / CSRF / session** |
| **Schema inference** | Implicit (in generated client) | **Yes (OpenAPI 3.1)** | Via mitmproxy2swagger | Per-actor | No | **Yes (from 3+ samples), inspired by OpenAPI DevTools** |
| **Multi-turn / pausable** | No (one-shot) | No | No | Yes (actors can run long) | No | **Yes (checkpointed up to 4 hours)** |
| **Retry / self-healing** | No | No | No | Limited | No | **Yes (Ralph loop pattern + retry ledger)** |
| **Rate-limit respect** | No | No | Via scripts | Yes (platform-level) | No | **Yes (429 + Retry-After + custom headers)** |
| **Anti-bot honesty** | Not mentioned | N/A | N/A | Varies | N/A | **Detect + report + degrade (no bypass)** |
| **Legal opt-in gate** | No | N/A | N/A | Platform ToS | No | **Per-service signed opt-in** |
| **Secret redaction** | Not mentioned | Client-side only | Manual | Varies | No | **Mandatory before report write** |
| **Output for downstream builder** | Python/JS/TS client | OpenAPI 3.1 | OpenAPI 3.0 | Actor output | N/A | **DISCOVERY-REPORT.md (human + Builder-Agent consumable)** |
| **Cost observability** | No | N/A | N/A | Yes (platform billing) | No | **Yes (per-run LLM cost estimate + budget cap)** |

### Key Competitive Insight

Prior-art tools each solve a slice. `reverse-api-engineer` is the closest to what v2.0 wants to be, but it's one-shot (no pause/resume), doesn't validate replay, doesn't extract auth flows in a structured way, and has no legal gate. OpenAPI DevTools has the best schema inference but requires manual browsing. mitmproxy has the best replay but no agent layer. Apify is SaaS and not integrated into Claude Code.

**AgentBloc's v2.0 edge is:**
1. **Invoked from v1.0 Phase 3 as a subroutine, not a standalone tool.** Context-aware handoff from TARGET.md — no other tool knows why the discovery is happening.
2. **Legal-first posture.** Per-service opt-in, ToS awareness, robots.txt compliance, anti-bot DETECTION (not bypass). No other tool in this space treats legal posture as a primary concern.
3. **Checkpointed multi-turn workflow.** LangGraph-pattern pause/resume for real-world flows that span hours (2FA, email verification, human approval).
4. **DISCOVERY-REPORT.md as the v2.0 → v3.0 → v4.0 contract.** Frozen schema that Builder Agent parses. Self-Healing re-runs and diffs. This report is the product's connective tissue across milestones.
5. **Ralph retry loop + evidence protocol + redaction, baked in.** Safety patterns are first-class, not bolted on.

---

## Handoff Contract: Phase 3 → Discovery Agent

**Critical dependency.** v1.0 Phase 3 (Integration Analysis) already determines "no MCP exists for action X on service Y" — that determination is the trigger for v2.0 Discovery Agent invocation.

### Trigger condition (in v1.0 Phase 3)

Current Phase 3 behavior: iterates through each required action, searches for (a) official API → (b) community MCP → (c) Playwright → (d) email scraping → (e) webhook. Each action gets a decision + trust score + URL evidence.

**New in v2.0:** when all 5 search paths fail for a given action, instead of marking [UNVERIFIED] and moving on, Phase 3 offers the user:

> "No MCP or API found for `add_comment_to_clickup_task`. I can launch the v2.0 Discovery Agent to reverse-engineer ClickUp's web portal and produce a DISCOVERY-REPORT.md. This requires your explicit opt-in and may take 30-60 minutes. Proceed?"

### Handoff file: `.agentbloc/discovery/<service>/TARGET.md`

Emitted by Phase 3 when user accepts. Example:

```markdown
---
service: clickup
service_url: https://app.clickup.com
service_url_verified_at: 2026-04-18T14:20:00Z
required_actions:
  - id: add_comment
    description: "Add a text comment to an existing task by task ID"
    expected_inputs: [task_id, comment_text]
    expected_outputs: [comment_id, created_at]
  - id: list_projects
    description: "Return the list of spaces the user has access to"
    expected_inputs: []
    expected_outputs: [space_id[], space_name[]]
auth_hint: "User has an active ClickUp subscription (paid plan)"
data_classification: business_sensitive  # from v1.0 Phase 1 interview
user_opt_in_signed_at: 2026-04-18T14:22:11Z
user_opt_in_phrase: "I own/have authorization for this account and accept ToS responsibility"
budget:
  max_usd: 25.00
  max_runtime_minutes: 90
  max_retry_iterations: 20
---

# Context from Phase 3

Phase 3 searched: official ClickUp API (requires paid Business plan the user doesn't have),
community MCPs (none found), Playwright MCP (generic tool, no ClickUp knowledge),
webhook patterns (not applicable for these actions). All paths exhausted.

User accepted Discovery Agent invocation.
```

### Handoff file: `.agentbloc/discovery/OPT_IN_LEDGER.json` (append-only)

```json
[
  {
    "timestamp": "2026-04-18T14:22:11Z",
    "service": "clickup",
    "service_url": "https://app.clickup.com",
    "phrase_confirmed": "I own/have authorization for this account and accept ToS responsibility",
    "invoked_from": "v1.0 Phase 3 Integration Analysis",
    "session_id": "<hash>"
  }
]
```

### Discovery Agent outputs back to Phase 3

When Discovery completes, it writes:
- `.agentbloc/discovery/<service>/DISCOVERY-REPORT.md` — the report
- Updates state: `.planning/STATE.md` phase 3 block for this service: `discovery_complete: true, endpoints_verified: 5, report_path: ...`

Phase 3 resumes, re-evaluates action coverage with discovery results factored in.

---

## Sources

### Prior-Art Tools (HIGH confidence — directly examined)
- [kalil0321/reverse-api-engineer](https://github.com/kalil0321/reverse-api-engineer) — Claude skill forking Playwright MCP for native HAR + API client generation. Closest prior art. v2.0 improves on: replay validation, auth extraction, checkpointing, legal gate, redaction
- [reverse-engineering-api skill (Playbooks.com)](https://playbooks.com/skills/kalil0321/reverse-api-engineer/reverse-engineering-api) — skill listing with feature summary
- [Reverse-engineering undocumented APIs with Claude (DEV Community)](https://dev.to/kalil0321/reverse-engineering-undocumented-apis-with-claude-1l33) — author's deep-dive
- [AndrewWalsh/openapi-devtools](https://github.com/AndrewWalsh/openapi-devtools) — Chrome extension, best-in-class schema inference from live traffic
- [Reverse-Engineering APIs in Real Time (Starlog)](https://starlog.is/articles/automation/andrewwalsh-openapi-devtools/) — OpenAPI DevTools architecture analysis

### Browser Automation & Capture (HIGH confidence)
- [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) — official Microsoft Playwright MCP
- [Playwright AI Ecosystem 2026 (TestDino)](https://testdino.com/blog/playwright-ai-ecosystem/) — MCP + agents + self-healing tests state of the art
- [State of Playwright AI Ecosystem 2026 (Currents)](https://currents.dev/posts/state-of-playwright-ai-ecosystem-in-2026)
- [Playwright MCP Changes Build vs Buy (Bug0)](https://bug0.com/blog/playwright-mcp-changes-ai-testing-2026)
- [mcp-playwright-cdp](https://github.com/lars-hagen/mcp-playwright-cdp) — CDP-enhanced MCP variant
- [mitmproxy](https://www.mitmproxy.org/) and [mitmproxy 10.1 HAR support](https://www.mitmproxy.org/posts/har-support/) — HAR import/export
- [Replay Requests (mitmproxy docs)](https://docs.mitmproxy.org/stable/mitmproxytutorial-replayrequests/) — replay semantics

### HAR & curl Tooling (HIGH confidence)
- [har-to-curl](https://github.com/mattcg/har-to-curl) — JS library
- [hargo](https://github.com/mrichman/hargo) — Go CLI
- [curlconverter HAR](https://curlconverter.com/har/) — web converter
- [UnblockDevs HAR-to-cURL](https://unblockdevs.com/har-to-curl) — with header masking / secret redaction

### Schema Inference (HIGH confidence)
- [json-re](https://github.com/iShafayet/json-re) — reverse-engineer JSON to Schema/POJOs/SQL/MongoDB
- [Hackolade reverse-engineering](https://hackolade.com/help/Reverseengineeranexistinginstanc.html)
- [JSONDiscoverer](https://modeling-languages.com/json-schema-discoverer/) — infer shared schema across docs
- [FastTool JSON Schema Generator](https://fasttool.app/tools/json-schema-generator) — local browser inference

### Agent Retry / Self-Healing Patterns (MEDIUM confidence — WebSearch verified)
- [Ralph Wiggum Loop (Agent Factory)](https://agentfactory.panaversity.org/docs/General-Agents-Foundations/general-agents/ralph-wiggum-loop)
- [Wiggum CLI: What Is the Ralph Loop](https://wiggum.app/blog/what-is-the-ralph-loop/)
- [vercel-labs/ralph-loop-agent](https://github.com/vercel-labs/ralph-loop-agent)
- [frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code)
- [The Good Programmer: Ralph Wiggum pattern](https://thegoodprogrammer.medium.com/the-ralph-wiggum-pattern-automation-and-persistence-for-coding-agents-4e8fa6f81dff)
- [snarktank/ralph](https://github.com/snarktank/ralph) — PRD-driven iteration loop

### Checkpointing / Long-Running Agents (HIGH confidence — official docs)
- [LangGraph Persistence (docs)](https://docs.langchain.com/oss/python/langgraph/persistence) — official
- [LangGraph TypeScript Checkpointing Guide](https://langgraphjs.guide/persistence/)
- [Build durable AI agents with LangGraph (AWS)](https://aws.amazon.com/blogs/database/build-durable-ai-agents-with-langgraph-and-amazon-dynamodb/) — pause/resume for hours
- [LangGraph Stateful Multi-Agent (Mager)](https://www.mager.co/blog/2026-03-12-langgraph-deep-dive/)

### Anti-Bot / Fingerprinting (MEDIUM confidence — relevant for anti-feature boundaries)
- [Browser-use: Browser agent bot detection is about to change](https://browser-use.com/posts/bot-detection) — 2026 anti-bot landscape
- [Fingerprint.com: Bot Detection](https://fingerprint.com/products/bot-detection/) — how detection works
- [Browserless: Device Fingerprinting Guide](https://www.browserless.io/blog/device-fingerprinting) — TLS, WebGL, canvas fingerprints
- [Camoufox](https://camoufox.com/) — example anti-detect browser (listed as reference for anti-feature A1, not adoption)

### Rate Limiting (HIGH confidence)
- [MDN: HTTP 429 Too Many Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/429) — official spec
- [Scrapfly: HTTP 429 guide](https://scrapfly.io/blog/posts/what-is-http-error-429-too-many-requests)
- [Postman: HTTP Error 429](https://blog.postman.com/http-error-429/)
- [RoundProxies: HTTP Error 429 2026](https://roundproxies.com/blog/http-error-429/)

### Self-Healing Selectors (MEDIUM confidence)
- [Zero-Cost Self-Healing via DOM Accessibility Tree (arXiv 2603.20358)](https://arxiv.org/abs/2603.20358) — 10-tier priority locator hierarchy
- [Datadog: Resilient synthetic tests with locators](https://www.datadoghq.com/blog/css-xpath-selectors-synthetic-testing/)
- [When the Scraper Breaks Itself (DEV Community)](https://dev.to/viniciuspuerto/when-the-scraper-breaks-itself-building-a-self-healing-css-selector-repair-system-312d) — self-healing CSS selectors
- [Katalon: Self-healing Test Automation](https://katalon.com/resources-center/blog/self-healing-test-automation)
- [Momentic: Self-Healing Test Automation Guide](https://momentic.ai/blog/self-healing-test-automation-guide)

### Legal / Ethical / Compliance (MEDIUM confidence — multi-source verified)
- [EFF Coders' Rights: Reverse Engineering FAQ](https://www.eff.org/issues/coders/reverse-engineering-faq) — authoritative on US legal landscape
- [OpenAI Terms of Use](https://openai.com/policies/row-terms-of-use/) — explicit no-reverse-engineering clause (reference example)
- [Google APIs Terms of Service](https://developers.google.com/terms) — similar restrictions
- [ScoreDetect: Reverse Engineering Laws](https://www.scoredetect.com/blog/posts/reverse-engineering-laws-restrictions-legality-ip)
- [Apriorit: Best Practices of Reverse Engineering an API](https://www.apriorit.com/dev-blog/reverse-engineering-an-api-guide)
- [Web Scraping Laws And Ethics 2026 (DataDwip)](https://www.datadwip.com/blog/web-scraping-laws-and-ethics/)
- [PromptCloud: Is Web Scraping Legal in 2026](https://www.promptcloud.com/blog/is-web-scraping-legal/)
- [DEV: New AI web standards and scraping trends 2026](https://dev.to/astro-official/new-ai-web-standards-and-scraping-trends-in-2026-rethinking-robotstxt-3730) — EU AI Act + robots.txt evolution
- [Scrapers selectively respect robots.txt (arXiv 2505.21733)](https://arxiv.org/html/2505.21733v1) — empirical study
- [Illusory.io: Web Scraping Compliance 2026](https://www.illusory.io/blog/web-scraping-compliance-2026-legal-ethical-proxy)

### OpenAPI & Endpoint Organization (MEDIUM confidence)
- [OpenAPI Initiative Newsletter Feb 2026](https://www.openapis.org/blog/2026/02/10/openapi-initiative-newsletter-february-2026) — Moonwalk SIG on LLM-agent-ready grouping
- [StackHawk: AI-Powered OpenAPI Spec Generation](https://www.stackhawk.com/blog/openapi-spec-generation/) — deep structural analysis
- [StackHawk: Best API Discovery Tools 2026](https://www.stackhawk.com/blog/best-api-discovery-tools/)

### Framework Integration Context (HIGH confidence — from v2.0 handoff)
- [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — Ralph mode + learner system + `/deep-interview` (already verified by v2.0 handoff)
- [obra/superpowers](https://github.com/obra/superpowers) — Socratic spec extraction methodology
- [openclaw/openclaw](https://github.com/openclaw/openclaw) — ACP runtime substrate (v3.0+ consideration)

---

*Feature research for: AgentBloc v2.0 Discovery Agent (autonomous reverse-engineering subroutine invoked from v1.0 Phase 3 Integration Analysis)*
*Researched: 2026-04-18*
*Downstream: Requirements definition (DISC-xx + CHCK-xx categories), Roadmapper (phase decomposition)*
