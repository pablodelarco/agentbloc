# Technology Stack: AgentBloc v2.0 Discovery Agent

**Project:** AgentBloc v2.0 — Discovery Agent milestone
**Researched:** 2026-04-18
**Scope:** INCREMENTAL — only additions/changes needed for the Discovery Agent. v1.0 stack (Claude Code skill, Telegram/Slack/Google MCP servers, file-based JSON state, system cron, Playwright MCP as deployment-time browser fallback) remains authoritative and is NOT re-researched here.
**Confidence:** HIGH for versioned npm/PyPI picks; MEDIUM for anti-bot layer (ecosystem is adversarial and shifts every ~6 months).

---

## Executive Summary

The Discovery Agent does NOT need a new runtime framework. It runs inside Claude Code like every other AgentBloc component. The additions are a small set of browser-automation, HAR-capture, request-replay, and checkpointing primitives that the skill shells out to via `Bash`, `mcp__playwright__*` (already installed in v1.0), and file I/O.

Seven new additions to the stack, each with an explicit integration touchpoint against v1.0:

1. **Browser engine** — keep v1.0's `@playwright/mcp` as the default; add `patchright@1.59.4` as the stealth drop-in when the target site uses Cloudflare/DataDome/Akamai. `playwright-extra` + `puppeteer-extra-plugin-stealth` are obsolete (2023 last release).
2. **CDP network interception** — use Playwright's native `CDPSession` (`context.newCDPSession(page)`). Do NOT add `chrome-remote-interface` or `puppeteer-core` — they duplicate what Playwright already exposes and bring a second browser-binary dependency.
3. **HAR capture** — use Playwright's built-in `recordHar` option. No need for `chrome-har` (abandoned 2022–2024, now only maintenance releases) or `har-validator` (unpublished from npm 2023).
4. **HAR analysis / replay** — `curlconverter@4.12.0` to turn captured requests into curl commands. `@har-sdk/core@1.5.0` + `@har-sdk/validator@2.6.1` from NeuralLegion for HAR schema validation when we need stricter checking. `jq` (already v1.0 dependency) does the bulk of the analysis.
5. **Checkpointing** — keep AgentBloc's existing JSON-file pattern (`.agentbloc/state/*.json`). Do NOT add LangGraph. Add a `discovery-checkpoint.json` schema that mirrors LangGraph's StateGraph-checkpoint *shape* without importing the Python runtime.
6. **Request replay / validation** — `curl` + `jq` (v1.0 tools) remain primary. Add `xh@0.24.0` as an optional human-readable alternative (single Rust static binary, no deps). `httpie` is slower and Python-dependent — skip for MVP.
7. **Scheduling for long-running discovery** — reuse v1.0's system cron + `claude -p` pattern. Discovery runs that span multiple sessions are handled by the checkpoint file, NOT by a new job queue. Introduce a wrapper script (`agentbloc-discovery-runner.sh`) that reads the checkpoint, invokes `claude -p` with the resume prompt, and writes the next checkpoint.

**The hard constraint:** every addition below must work inside a Claude Code session shelling out to a CLI or MCP server. No long-lived daemons, no new language runtimes beyond Node 22 LTS and Python 3.12 (already needed for some v1.0 MCP servers). This keeps the "Claude Code + cron + MCP + shell" deployment promise intact.

---

## Recommended Stack

### 1. Browser Automation Layer

| Technology | Version | Released | Purpose | Why |
|------------|---------|----------|---------|-----|
| **`@playwright/mcp`** (already in v1.0) | `0.0.70` | 2026-04-18 | Default browser controller via MCP tools. AI-first, accessibility-snapshot based. | Already referenced by AgentBloc. Primary entry point for "politely crawl a well-behaved site." Does NOT need stealth for most B2B SaaS dashboards. |
| **`playwright`** (Node library) | `1.59.1` | 2026-04-18 | Low-level Playwright for Discovery Agent's own scripts (HAR capture, CDP interception). | Needed when the agent writes ad-hoc Node scripts that MCP tool-surface cannot express (full CDP, low-level interception, custom wait conditions). Install via `npm i playwright@^1.59`. |
| **`patchright`** (Node) | `1.59.4` | 2026-04-09 | Stealth drop-in for Chromium-only targets with Cloudflare/DataDome/Akamai bot-check. Patches `Runtime.enable`, `Console.enable`, and `--disable-blink-features=AutomationControlled` at the CDP-leak level. | 2935 GitHub stars, actively maintained by Vinyzu/Kaliiiiiiiiii, version-pinned 1:1 with Playwright. This is the 2026-current path. `playwright-extra` + stealth plugin haven't shipped since 2023. |

**DO NOT ADD:**
- `playwright-extra@4.3.6` (last release 2023-03-01, 3 years stale) — superseded by Patchright
- `puppeteer-extra-plugin-stealth@2.11.2` (last release 2023-04-11) — superseded by Patchright
- `puppeteer-core@24.41.0` — adds a second browser-binary download and a second automation API surface. If we need Puppeteer's CDP behavior, Playwright's `CDPSession` already exposes it
- `playwright-stealth` on PyPI (`0.4.11`, last update Jan 2025) — the Python stealth fork is less maintained than Patchright

**Variant guidance for v2.0:**
- **Well-behaved target** (internal SaaS, banking portal with OAuth, public docs) → `@playwright/mcp` only. Patchright is over-rotation.
- **Hostile target** (public e-commerce, scraping-detection on, Cloudflare challenge page appears) → `patchright` + residential-proxy guidance in the Discovery skill. Flag to user via disclaimer gate.
- **Hardcore hostile** (FingerprintJS + CreepJS + behavioral) → out of scope for v2.0. Skill emits `DISCOVERY-BLOCKED-REPORT.md` and asks user for cookies/session handoff.

---

### 2. Chrome DevTools Protocol (CDP) Access

**Decision: use Playwright's native `CDPSession`. Add NO new CDP library.**

| Approach | Verdict | Rationale |
|----------|---------|-----------|
| **Playwright `context.newCDPSession(page)`** | USE | Zero new dependency. Full CDP surface. Works with both `playwright` and `patchright`. Example: `session.send('Network.enable'); session.on('Network.requestWillBeSent', ...)`. |
| `chrome-remote-interface@0.34.0` (cyrus-and) | SKIP | 4519 stars, maintained (last push 2026-02-09), but requires connecting to a manually-launched Chrome with `--remote-debugging-port`. Adds a second process-management burden. Only useful if we need to attach to an already-running Chrome (out of scope for Discovery Agent). |
| `puppeteer-core@24.41.0` as CDP bridge | SKIP | Adds a second browser library to maintain. Playwright already handles everything Puppeteer does. |

**Integration touchpoint with v1.0:**
- CDP sessions are ephemeral (they die with the browser context). Persistent discovery state goes into `.agentbloc/state/discovery/<service>/checkpoint.json`, NOT into any CDP-specific store.
- When the skill captures network traffic, it writes to `.agentbloc/state/discovery/<service>/har/<timestamp>.har` using Playwright's built-in `recordHar`.

**Example pattern the skill will document:**
```typescript
// .agentbloc/discovery/<service>/capture.ts — generated by Discovery Agent
import { chromium } from 'patchright';  // or 'playwright' for well-behaved targets

const browser = await chromium.launch({ headless: false });
const context = await browser.newContext({
  recordHar: { path: '.agentbloc/state/discovery/acme-invoices/har/session-1.har' },
});
const page = await context.newPage();
const cdp = await context.newCDPSession(page);

await cdp.send('Network.enable');
cdp.on('Network.requestWillBeSent', (event) => {
  if (event.request.url.includes('/api/')) {
    // append to .agentbloc/state/discovery/acme-invoices/endpoints.jsonl
  }
});
```

---

### 3. HAR Capture, Validation, Replay

| Tool | Version | Released | Purpose | Why This One |
|------|---------|----------|---------|--------------|
| **Playwright `recordHar`** (built-in) | bundled with `playwright@1.59.1` | — | Capture every request/response during a browser session into a HAR 1.2 file | Zero new dependency. Content-inclusion controls (`recordHarContent: 'embed'/'omit'`) mean we can strip response bodies from HAR to shrink files and avoid accidentally persisting PII. |
| **`curlconverter`** (Node or standalone binary) | `4.12.0` | 2025-02-07 | Turn HAR entries or raw copy-as-cURL strings into runnable curl commands, also supports 40+ target languages (Python, Rust, Go) for future Builder Agent code-gen | 8116 GitHub stars. Maintained. This is *the* standard tool for request replay. Powers Firefox/Chrome devtools' "Copy as cURL" import. |
| **`@har-sdk/core`** (NeuralLegion) | `1.5.0` | 2025-03-25 | Typed TypeScript HAR 1.2 types + parser | Still maintained by NeuralLegion (Bright Security). Use when we need strict type-checking in generated Discovery scripts. |
| **`@har-sdk/validator`** (NeuralLegion) | `2.6.1` | 2025-03-25 | Validate HAR files against the 1.2 schema | Same maintainer. Drop-in validator. Replaces the abandoned `har-validator`. |
| **`fetch-har`** (Node) | `12.0.1` | 2026-04-07 | Replay a HAR entry as a `fetch()` call. Useful for the "smoke test" step of DISCOVERY-REPORT | Actively maintained (April 2026). Good for quickly proving a discovered request still works. |
| **`jq`** (CLI, v1.0 dependency) | `1.7.1` (local) | — | Query and filter HAR JSON on the shell | Already required by AgentBloc v1.0 hooks. Do HAR analysis with `jq '.log.entries[] \| select(.request.url \| contains("/api/"))'` in 3 lines. |

**DO NOT ADD:**
- `chrome-har@1.1.1` (last release 2025-10-17, 166 stars, 44 open issues) — Playwright already records HAR natively. `chrome-har` was for converting Chrome DevTools Network-log events to HAR format manually. We don't need that when Playwright does it.
- `har-validator@5.1.5` — **unpublished from npm 2023-03-15**. Dead. Use `@har-sdk/validator`.
- `har-format` — unpublished from npm 2023. Dead.
- `har-to-k6@0.14.13` (last release 2026-02-12) — generates k6 load-test scripts from HAR. Out of scope for Discovery Agent. Maybe relevant for v3.0 Builder Agent integration-testing.

**Integration touchpoint with v1.0:**
- HAR files live at `.agentbloc/state/discovery/<service>/har/*.har` alongside the existing `.agentbloc/state/*.json` state files.
- `.agentbloc/state/discovery/<service>/endpoints.jsonl` — append-only log of discovered endpoints, in the same JSONL format v1.0 uses for `audit.jsonl`.
- The Discovery skill enforces HAR content redaction (Playwright `recordHarContent: 'omit'` unless user explicitly opts in). This is the same data-classification discipline v1.0's security references/ already mandate.

---

### 4. Checkpointing for Long-Running Discovery

**Decision: extend v1.0's JSON-file state pattern. Do NOT add LangGraph as a runtime.**

| Option | Verdict | Rationale |
|--------|---------|-----------|
| **Custom JSON checkpoint file** (`.agentbloc/state/discovery/<service>/checkpoint.json`) | USE | Fits v1.0's file-based state decision perfectly. Debuggable (open in editor). No new runtime. Schema mirrors LangGraph's checkpoint *shape* (state, step, timestamp, nextAction) so if we ever move to LangGraph in v3.0, migration is mechanical. |
| `langgraph@1.1.8` + `langgraph-checkpoint-sqlite@3.0.3` | SKIP for v2.0 | 29590 GitHub stars, released 2026-04-17 (very active). But importing LangGraph means a Python runtime with langchain-core, pydantic, etc. — breaks AgentBloc's "Claude Code + shell + MCP only" promise. Reference its design in the skill; don't import it. |
| `langgraph-checkpoint@4.0.2` (base interface only) | SKIP for v2.0 | Still Python, still a runtime dependency. |
| SQLite file | SKIP for v2.0 | Solves a problem we don't have. File-based JSON handles <10K discovery records easily. Revisit in v3.0 if Discovery needs relational queries. |
| Redis / Postgres | HARD NO | Breaks the "runs on any laptop or VPS" deployment promise. Not needed at SMB scale. |

**Checkpoint schema (lives in the Discovery skill's reference file):**
```json
{
  "schemaVersion": "1.0",
  "service": "acme-invoices",
  "discoveryId": "disc-2026-04-18-a3f2",
  "createdAt": "2026-04-18T19:12:04Z",
  "updatedAt": "2026-04-18T19:47:18Z",
  "status": "in_progress | paused | complete | blocked",
  "currentStep": "auth-flow-mapping",
  "completedSteps": ["login-capture", "homepage-crawl"],
  "nextSteps": ["endpoint-enumeration", "rate-limit-probe"],
  "evidence": {
    "harFiles": ["har/session-1.har"],
    "endpointsFound": 7,
    "authFlow": "oauth2_pkce"
  },
  "ralphLedger": {
    "retryCount": 2,
    "lastFailure": "selector_mismatch",
    "contextResetAt": "2026-04-18T19:30:00Z"
  },
  "humanGates": [
    { "at": "2026-04-18T19:15:00Z", "decision": "opt_in_disclaimer_accepted" }
  ]
}
```

**Why this shape:**
- `currentStep` + `completedSteps` + `nextSteps` mirror LangGraph's StateGraph node semantics. If we port to LangGraph in v3.0, each becomes a node name.
- `ralphLedger` captures the Ralph-retry-loop state (oh-my-claudecode pattern). Agent reads this on resume to decide whether to retry the failing step or escalate.
- `humanGates` is the audit trail for the legal-disclaimer opt-in required by the v2.0 legal posture.

**Integration touchpoint with v1.0:**
- Sits next to existing `.agentbloc/state/*.json` files — no new directory conventions
- Read/written by the Discovery Agent subagent, not by deployed production agents
- `.agentbloc/KILL_SWITCH` (v1.0) still honored — Discovery Agent checks it on resume

---

### 5. Stealth / Anti-Bot Layer

**Decision: `patchright` is the current best-of-breed for Chromium-based stealth in 2026. Defer Firefox/Camoufox unless a target demands it.**

| Tool | Version | Released | Stars | Use When |
|------|---------|----------|-------|----------|
| **`patchright`** (Node & PyPI) | Node `1.59.4` / PyPI `1.58.2` | 2026-04-09 / 2026-03-07 | 2935 | Chromium target + bot detection on. Default stealth pick for v2.0. Keeps Playwright API surface. |
| `camoufox` (Python) | `0.4.11` | 2025-01-29 | 4052 | Target specifically Firefox-fingerprintable OR detection bypass is critical AND target is Chromium-stealth-hardened. Camoufox modifies Firefox at C++ level — strongest stealth, different API. Defer to v2.5 unless target demands it. |
| `nodriver` (Python, successor to undetected-chromedriver) | `0.48.1` | 2025-11-09 | 7742 | When target specifically detects Playwright/Puppeteer signatures. Python-only, async, no WebDriver. Defer to v2.5; patchright covers 80% of stealth needs. |
| `curl_cffi` (Python) | `0.15.0` | 2026-04-03 | 5432 | TLS fingerprint impersonation (JA3/JA4). When the target blocks at the TLS layer, not at JS level. Orthogonal to browser stealth — can be combined. Defer to v2.5. |
| `playwright-extra@4.3.6` + `puppeteer-extra-plugin-stealth@2.11.2` | OBSOLETE | 2023-03/04 | — | **DO NOT USE.** Last release 3 years ago. Patchright is the successor. |
| `rebrowser-playwright@1.52.0` | BACKUP | 2025-05-09 | 50 | Alternative stealth patchset. Smaller community (50 stars). Use only if Patchright breaks on a specific target. |

**Known CVEs / maintenance concerns:**
- `patchright`: no CVEs disclosed as of 2026-04-18. 2935-star repo, active releases (9 days between 1.59.4 and research date). Risk: maintainer bus factor of 2 (Vinyzu + Kaliiiiiiiiii). Mitigate by pinning to a known-good version and monitoring release notes.
- `playwright` / `playwright-mcp`: no active CVEs. Microsoft-maintained.
- `mitmproxy` (NOT recommended for v2.0 but discussed below): **3 disclosed CVEs in 2025–2026** including GHSA-wg33-5h85-7q5p (high — auth bypass, Feb 2025) and GHSA-527g-3w9m-29hv (medium — LDAP injection, April 2026). Any integration requires running mitmproxy 12.2.2+ and reviewing its hardening guidance. Skip for v2.0.

**Integration touchpoint with v1.0:**
- Stealth is OPTIONAL per discovery target. The Discovery skill asks in Phase 3.5 (new): "Does this target block automated browsers?" Answer drives which dependency to install.
- Governance policy: stealth tooling must be paired with the v2.0 legal-posture opt-in gate. User acknowledges: "Using stealth tooling against a target may violate its ToS. Proceed?" — logged into `humanGates` in the checkpoint.

---

### 6. Request Replay / Validation (curl Replacements)

**Decision: `curl` + `jq` (v1.0 tools) are primary. `xh` is the one approved secondary tool.**

| Tool | Version | Released | Stars | Verdict |
|------|---------|----------|-------|---------|
| **`curl`** | `8.7.1` (macOS 25.3 stock) | — | — | PRIMARY. Already required. Universal. |
| **`jq`** | `1.7.1` | — | — | PRIMARY. Already required. |
| **`xh`** (Rust) | `0.24.0` | 2026-04 | 7427 | SECONDARY. Single static binary, zero runtime deps, httpie-compatible syntax, ~10x startup vs httpie. Good for reports where we show the user a readable request. Install via `brew install xh` or `cargo install xh`. |
| `httpie` (Python) | `3.2.4` | 2024-12-17 | 37949 | SKIP. Requires Python runtime. Slow startup. Last major release Dec 2024. No advantage over `xh`. |
| `curlie` | `1.8.2` | 2026-03 | 4357 | SKIP. Thin curl wrapper. Doesn't add enough over raw curl. |

**Integration touchpoint with v1.0:**
- `DISCOVERY-REPORT.md` generation uses `curlconverter` to produce both a raw-curl block and a Python/Node equivalent. Shown in the report verbatim — user (or future Builder Agent in v3.0) copy-pastes.
- Smoke-test step: Discovery Agent executes each discovered request via `fetch-har` (in-process) AND `curl` (shelled out). Both must succeed before the endpoint is listed as `validated: true` in DISCOVERY-REPORT.md.

---

### 7. Scheduling for Long-Running Discovery

**Decision: reuse v1.0's system cron + `claude -p` pattern. Add a resumable wrapper script.**

| Option | Verdict | Rationale |
|--------|---------|-----------|
| **System cron + `claude -p "resume discovery <id>"`** (v1.0 pattern) | USE | Proven in production. Checkpoint file carries all state. Zero new infra. |
| **Wrapper: `agentbloc-discovery-runner.sh`** | NEW | Reads `.agentbloc/state/discovery/<service>/checkpoint.json`, if status is `paused` or `in_progress` invokes `claude -p` with the resume prompt. Logs to `.agentbloc/state/discovery/<service>/runs.jsonl`. Cron triggers this every 30 minutes (configurable). |
| **Claude Code Scheduled Tasks** | SKIP | v1.0 already ruled these out for production — 7-day expiry, Desktop-only. Discovery runs can legitimately span >7 days while waiting for human approvals. |
| `pm2` / `supervisord` | SKIP | Adds a long-lived daemon. Breaks "no custom runtime" constraint. |
| GNU `parallel` | SKIP | Solves a problem we don't have. Discovery is step-sequential, not embarrassingly parallel. |
| Async job queue (BullMQ, Celery, Temporal) | HARD NO | New runtime, new infra, new failure modes. Massive over-engineering for 1–10 discovery runs per user. |

**Integration touchpoint with v1.0:**
- Wrapper script installed into `.agentbloc/bin/agentbloc-discovery-runner.sh` — same convention as v1.0's deployed-agent runner pattern.
- Cron entry template added to v1.0's `scheduling.md` reference: `*/30 * * * * /path/to/.agentbloc/bin/agentbloc-discovery-runner.sh >> /path/to/.agentbloc/logs/discovery.log 2>&1`
- Kill switch check at top of script — respects existing `.agentbloc/KILL_SWITCH`.
- Discovery runs are governed by the same `governance.yaml` patterns v1.0 uses for deployed agents (rate limit, human gates, audit logging).

---

## Installation Manifest

```bash
# Node deps (add to Discovery skill's reference installation steps)
npm install --save-dev \
  playwright@1.59.1 \
  patchright@1.59.4 \
  curlconverter@4.12.0 \
  fetch-har@12.0.1 \
  @har-sdk/core@1.5.0 \
  @har-sdk/validator@2.6.1

# Install browser binaries
npx playwright install chromium
npx patchright install chrome

# Optional CLI for human-readable request reports
brew install xh   # macOS
cargo install xh  # cross-platform fallback

# No Python additions. No new daemons. No new runtimes.
```

**Baseline versions pinned for v2.0 dependency declaration in Phase planning:**

| Package | Version | Notes |
|---------|---------|-------|
| `playwright` | `^1.59.1` | Stay within 1.59.x for compatibility with `patchright@1.59.4` |
| `patchright` | `^1.59.4` | Version-locked to `playwright@1.59.x` |
| `@playwright/mcp` | `^0.0.70` | v1.0 baseline, no change required |
| `curlconverter` | `^4.12.0` | — |
| `fetch-har` | `^12.0.1` | — |
| `@har-sdk/core` | `^1.5.0` | NeuralLegion |
| `@har-sdk/validator` | `^2.6.1` | NeuralLegion |
| `xh` | `>=0.24.0` | Optional |
| `jq` | `>=1.7` | v1.0 baseline, no change |
| Node.js | `>=22 LTS` | v1.0 baseline, no change |

---

## Alternatives Considered

| Recommended | Alternative | Why Not the Alternative |
|-------------|-------------|-------------------------|
| Playwright + Patchright | Puppeteer + puppeteer-extra-stealth | Stealth plugin unmaintained since 2023. Playwright has better CDP surface. |
| Playwright CDPSession | `chrome-remote-interface` | Adds a dependency + requires launching Chrome separately with `--remote-debugging-port`. Playwright already exposes CDP. |
| Playwright `recordHar` | `chrome-har` | Playwright records HAR natively in 1.59. `chrome-har` has 44 open issues and was built for a different workflow (post-hoc HAR from devtools logs). |
| `@har-sdk/validator` | `har-validator` | `har-validator` was unpublished from npm in 2023. |
| JSON checkpoint file | LangGraph runtime | LangGraph is Python, adds a runtime dependency, conflicts with AgentBloc's "skill + shell + MCP only" constraint. Borrow its schema shape, not its runtime. |
| `curl` + `xh` | `httpie` | Python runtime required. `xh` is a drop-in replacement with no deps and faster startup. |
| System cron + `claude -p` + checkpoint | Temporal / BullMQ / Celery | Adds workers, queue infra, persistence layers. Massive over-engineering for a skill used by SMB consultants. |
| `patchright` | `camoufox`, `nodriver` | Patchright stays on the Playwright API surface we already use. Camoufox/nodriver are separate APIs. Revisit for v2.5 if Chromium-stealth-hardened targets appear. |
| `@playwright/mcp` for well-behaved targets | `stagehand` (Browserbase) | Browserbase is a commercial hosted service. Our deployment target is self-hosted. `@playwright/mcp` is the open-source path. |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **`playwright-extra@4.3.6`** | Last release 2023-03-01. Three years unmaintained. Stealth plugin 2023-04-11. | `patchright@1.59.4` — current, maintained, pinned to Playwright 1.59. |
| **`har-validator@5.1.5`** | Unpublished from npm 2023-03-15. Does not install. | `@har-sdk/validator@2.6.1`. |
| **`chrome-har@1.1.1`** | Playwright's built-in HAR recording removes the need. Library has 44 open issues, slow release cadence. | Playwright `recordHar` context option. |
| **`puppeteer-core@24.41.0`** as a secondary automation library | Duplicates Playwright. Adds a second browser-binary management burden. | Playwright's `CDPSession` for any CDP need. |
| **`langgraph@1.1.8` + `langgraph-checkpoint-sqlite@3.0.3`** as runtime | Requires Python runtime, pydantic, langchain-core. Breaks AgentBloc's "no new runtime" constraint. 29K stars and well-designed — worth referencing the schema shape. | Custom JSON checkpoint (`.agentbloc/state/discovery/<service>/checkpoint.json`) with LangGraph-shaped fields. |
| **Redis / SQLite for discovery state** | Adds infra. File-based JSON scales to the 1–10 discovery runs a single SMB consultant will perform. | JSON files in `.agentbloc/state/discovery/`. |
| **`mitmproxy@12.2.2` for network interception** | 3 CVEs in 2025–2026. Man-in-the-middle proxy requires CA cert install on the target machine and root/admin. Overshoots what Playwright CDP already provides. | Playwright `context.newCDPSession()` + `Network.enable` event listener. No MITM, no certs. |
| **`httpie@3.2.4`** as primary request-replay CLI | Python dep. 10x slower startup than `xh`. | `curl` + optional `xh`. |
| **`curlie`, `curlconverter`** for user-facing replay commands in the DISCOVERY-REPORT | `curlconverter` is a converter, not a runner. `curlie` adds nothing over curl. Report uses `curl`. | `curlconverter` internally to generate curl blocks in the report; `curl` is what the user runs. |
| **GNU parallel** for Discovery runs | Discovery is step-sequential and gated by human approvals. No parallelism opportunity. | Sequential checkpoint-based resume. |
| **Claude Code Scheduled Tasks for production discovery** | 7-day expiry; Desktop-only. Discovery runs can exceed 7 days waiting for human opt-in. | v1.0's system cron + `claude -p` + wrapper script. |
| **`playwright_stealth` (PyPI `0.4.11`)** | Python fork with slower release cadence (last Jan 2025) than Patchright. | Patchright (Node or Python flavor). |
| **Long-lived Node.js daemon process for Discovery** | Violates "Claude Code is the runtime" constraint. Adds process-supervision burden. | Each discovery "tick" is a fresh `claude -p` session reading the checkpoint. |

---

## Integration Map Against v1.0

| v1.0 Component | v2.0 Extension for Discovery Agent |
|----------------|------------------------------------|
| `.agentbloc/state/*.json` (machine-written) | Add `.agentbloc/state/discovery/<service>/checkpoint.json`, `endpoints.jsonl`, `har/*.har` — same machine-write discipline, new directory |
| `.agentbloc/` YAML config (human-written) | Add `.agentbloc/discovery/<service>/config.yaml` — opt-in disclaimer acceptance, stealth on/off, rate limit, human-gate policy |
| `.agentbloc/audit.jsonl` | Discovery events also append here with `category: "discovery"`. Reuse v1.0 PostToolUse hook verbatim. |
| `.agentbloc/KILL_SWITCH` | Discovery runner checks it BEFORE calling `claude -p`. Same behavior as deployed agents. |
| `references/security/` | Add `references/security/discovery-legal.md` documenting the ToS risk and per-service opt-in requirement |
| `references/scheduling.md` | Add cron template for `agentbloc-discovery-runner.sh` |
| `references/frameworks.md` | Add "LangGraph checkpoint pattern (reference only, not imported)" section documenting the schema-shape rationale |
| `references/phase-3-integration.md` | Branch: "If no MCP found → invoke Discovery Agent instead of falling back to generic Playwright" |
| `governance.yaml` schema | Add `discovery:` block — rate limit, max_discovery_hours, human_gates, stealth_opt_in |
| `.env` / `.env.example` | Add optional `AGENTBLOC_DISCOVERY_PROXY` for residential-proxy URL when stealth is on |
| Telegram reporting | Discovery milestone events (opt-in requested, discovery blocked, discovery complete) go to a new Telegram thread `discovery-<service>` — reuses v1.0 thread pattern |
| Playwright MCP (already listed) | Promoted from "deployment-time browser fallback" to "Discovery Agent's primary browser controller." Add Patchright as secondary for hostile targets. |

---

## Version Compatibility Matrix

| Component | Minimum | Current (2026-04-18) | Notes |
|-----------|---------|----------------------|-------|
| Claude Code | 2.1.32+ (v1.0 baseline) | 2.2.x | No change. Hooks, Subagents, Scheduled Tasks already working. |
| Node.js | 22 LTS | 22.x | No change. Required for Playwright 1.59. |
| Python | 3.12+ (v1.0 baseline for some MCPs) | 3.12.x | No new Python code in v2.0. Python only for pre-existing MCP servers. |
| Playwright | 1.59.1 | 1.59.1 | NEW. Pin to 1.59.x for Patchright compatibility. |
| Patchright | 1.59.4 | 1.59.4 | NEW. Must match Playwright major-minor. |
| `@playwright/mcp` | 0.0.70 | 0.0.70 | No change from v1.0. |
| curl | 8.0+ | 8.7.1 | No change. |
| jq | 1.6+ | 1.7.1 | No change. |
| System cron | any | — | No change. |

---

## Known CVEs and Maintenance Concerns

| Package | Status | Concern |
|---------|--------|---------|
| `playwright` | Clean | Microsoft-maintained, 86K stars, weekly releases. Low risk. |
| `patchright` | Clean as of 2026-04-18 | 2935 stars, 2 primary maintainers. Bus factor risk. **Mitigation: pin to a known-good version, monitor GitHub releases, have a fallback plan to switch to `rebrowser-playwright` or bare `playwright` if Patchright becomes unmaintained.** |
| `curlconverter` | Clean | 8K stars, active. Low risk. |
| `@har-sdk/*` | Clean | NeuralLegion (Bright Security) maintained. Low risk. Last release March 2025 — watch for staleness. |
| `fetch-har` | Clean | Actively maintained (April 2026 release). Low risk. |
| `mitmproxy` | **3 CVEs 2025–2026** | Not recommended — but if a future milestone adopts it, use 12.2.2+ and review hardening doc. |
| `langgraph` | — (not imported) | Only the schema-shape is referenced. |

---

## Discovery Agent Stack by Target Posture

**Posture A — well-behaved internal SaaS (e.g., Xero dashboard, Shopify admin):**
```
@playwright/mcp (MCP tool calls only) + jq + curl
→ No Patchright needed. No CDP interception needed.
→ Use MCP accessibility snapshots for navigation, read network tab via Network.enable when login flow needs capturing.
```

**Posture B — public e-commerce with basic bot detection (Cloudflare challenge sometimes):**
```
playwright (Node scripts) + patchright (for login + protected pages) + CDP via CDPSession + curlconverter + jq
→ Browser cookies persisted in .agentbloc/state/discovery/<service>/cookies.json (encrypted via age or explicit .env key)
→ Residential proxy recommended but optional
```

**Posture C — hardcore bot protection (FingerprintJS + behavioral):**
```
→ Out of scope for v2.0 Discovery Agent.
→ Skill generates DISCOVERY-BLOCKED-REPORT.md and asks user to provide session cookies manually.
→ Revisit in v2.5: consider camoufox or nodriver for Chromium-hostile targets.
```

---

## Sources

### Package Registries (verified 2026-04-18)
- `playwright@1.59.1` — npm, released 2026-04-18. https://www.npmjs.com/package/playwright
- `@playwright/mcp@0.0.70` — npm, 2026-04-18. https://www.npmjs.com/package/@playwright/mcp
- `patchright@1.59.4` — npm, 2026-04-09. https://www.npmjs.com/package/patchright
- `curlconverter@4.12.0` — npm, 2025-02-07. https://www.npmjs.com/package/curlconverter
- `fetch-har@12.0.1` — npm, 2026-04-07. https://www.npmjs.com/package/fetch-har
- `@har-sdk/core@1.5.0` — npm, 2025-03-25. https://www.npmjs.com/package/@har-sdk/core
- `@har-sdk/validator@2.6.1` — npm, 2025-03-25. https://www.npmjs.com/package/@har-sdk/validator
- `chrome-har@1.1.1` — npm, 2025-10-17. https://www.npmjs.com/package/chrome-har (not recommended; listed for completeness)
- `har-validator` — unpublished 2023-03-15 (deprecated)
- `playwright-extra@4.3.6` — npm, 2023-03-01 (abandoned)
- `langgraph@1.1.8` — PyPI, 2026-04-17. https://pypi.org/project/langgraph/
- `mitmproxy@12.2.2` — PyPI, 2026-04-12. https://pypi.org/project/mitmproxy/

### GitHub Activity (verified 2026-04-18)
- [microsoft/playwright](https://github.com/microsoft/playwright) — 86,771 stars, push 2026-04-18
- [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) — 31,062 stars, push 2026-04-17
- [Kaliiiiiiiiii-Vinyzu/patchright](https://github.com/Kaliiiiiiiiii-Vinyzu/patchright) — 2,935 stars, push 2026-04-12
- [rebrowser/rebrowser-patches](https://github.com/rebrowser/rebrowser-patches) — 7,298 stars (last push July 2024)
- [ultrafunkamsterdam/nodriver](https://github.com/ultrafunkamsterdam/nodriver) — 7,742 stars
- [daijro/camoufox](https://github.com/daijro/camoufox) — 4,052 stars
- [lexiforest/curl_cffi](https://github.com/lexiforest/curl_cffi) — 5,432 stars
- [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) — 29,590 stars
- [curlconverter/curlconverter](https://github.com/curlconverter/curlconverter) — 8,116 stars
- [ducaale/xh](https://github.com/ducaale/xh) — 7,427 stars
- [mitmproxy/mitmproxy](https://github.com/mitmproxy/mitmproxy) — 43,165 stars
- [sitespeedio/chrome-har](https://github.com/sitespeedio/chrome-har) — 166 stars, 44 open issues (not recommended)

### Security Advisories
- mitmproxy [GHSA-wg33-5h85-7q5p](https://github.com/mitmproxy/mitmproxy/security/advisories/GHSA-wg33-5h85-7q5p) — Mitmweb API auth bypass (high, Feb 2025)
- mitmproxy [GHSA-527g-3w9m-29hv](https://github.com/mitmproxy/mitmproxy/security/advisories/GHSA-527g-3w9m-29hv) — LDAP injection (medium, April 2026)
- mitmproxy [GHSA-63cx-g855-hvv4](https://github.com/mitmproxy/mitmproxy/security/advisories/GHSA-63cx-g855-hvv4) — h2 dependency (medium, Aug 2025)
- `patchright`, `playwright`, `curlconverter`, `fetch-har`, `@har-sdk/*`: no disclosed advisories as of 2026-04-18

### Research Articles (MEDIUM confidence, ecosystem context)
- [AI Browser Automation in 2026: Camoufox, Nodriver & Stealth MCP](https://www.proxies.sx/blog/ai-browser-automation-camoufox-nodriver-2026)
- [The 6 best Patchright alternatives in 2026](https://roundproxies.com/blog/best-patchright-alternatives/)
- [From Puppeteer stealth to Nodriver: how anti-detect frameworks evolved](https://blog.castle.io/from-puppeteer-stealth-to-nodriver-how-anti-detect-frameworks-evolved-to-evade-bot-detection/)
- [Playwright Stealth Mode in 2026: The 7 Patches That Actually Matter](https://dev.to/vhub_systems_ed5641f65d59/playwright-stealth-mode-in-2026-the-7-patches-that-actually-matter-46bp)
- [Browsers-benchmark (stealth success rates)](https://github.com/techinz/browsers-benchmark)

---

*Stack research for: AgentBloc v2.0 Discovery Agent milestone*
*Researched: 2026-04-18*
*Next downstream: Requirements definition (step 9) + Roadmapper (step 10). All package versions above are ready to pin in Phase plans.*
