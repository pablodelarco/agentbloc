---
phase: 11-integration-discovery-browser-fallback
plan: 02
status: complete
completed_at: 2026-04-24
requirements_closed:
  - BROWSER-05
  - BROWSER-06
  - BROWSER-07
  - BROWSER-09
  - BROWSER-12
decisions_applied:
  - D-46
  - D-47
  - D-48
  - D-49
  - D-54
  - D-55
  - D-56
  - D-58
files_created:
  - .claude/skills/agentbloc/references/browser-stack.md
  - .claude/skills/agentbloc/references/legal-posture.md
  - scripts/anti-bot-lint.sh
files_modified:
  - .github/workflows/ci.yml
commits:
  - 2a2cd71  # Task 1: browser-stack.md
  - a8b13a7  # Task 2: legal-posture.md
  - 82f81f3  # Task 3: anti-bot-lint.sh + ci.yml extension
---

# Phase 11 Plan 02: Stack Pinning, Legal Posture, and CI Anti-Bot Lint

One-liner: Emitted the pinned browser-automation stack with a nine-package anti-bot deny-list, the five-jurisdiction legal posture reference with a SHA256-pinned attestation protocol, and the CI-enforceable deny-list lint script plus workflow job that blocks a poisoned manifest before any dependency install runs.

## Artifacts

### Files Created

| Path | Lines | Purpose |
| --- | --- | --- |
| `.claude/skills/agentbloc/references/browser-stack.md` | 152 | Declarative stack reference loaded unconditionally at Phase 3 entry. Six-row Pinned Stack table (playwright, patchright, @playwright/mcp, curlconverter, @har-sdk/validator, fetch-har) with version + release-date + purpose + rationale columns. Nine-package Anti-Bot Deny-List with category, prohibition rationale, and alternative. Patchright Usage Rules scoping Patchright to Posture B CDP-leak patches only. Ralph Retry Protocol with budget (3 default, hard cap 5), exponential backoff (1s/4s/16s), and forbidden-vs-allowed adjustments list. Posture A/B/C Stack Variant Guidance with Posture C halt behavior. Quick Reference six-bullet summary. |
| `.claude/skills/agentbloc/references/legal-posture.md` | 180 | Legal posture reference loaded by the browser-discovery subagent in its forked context on every invocation. Five-jurisdiction Variance Matrix (US CFAA + DMCA section 1201 / UK Computer Misuse Act 1990 + CPS 2020 / EU GDPR Art 5(1)(a) + Art 6 / DE BDSG section 202a Ausspaehen von Daten / BR LGPD) with post-matrix Van Buren + hiQ Labs context. ToS Tier Classification Protocol (5-step decision grammar with 12 trigger keywords, SHA256-pinned in-session ToS fetch, GREEN/AMBER/RED enum, data-subject scope check, jurisdictional exposure check). DISCOVERY-LICENSE-NOTICE.md template with user attestation + tool-provider disclaimer blocks. OPT_IN_LEDGER.jsonl append-only format with corrects_entry correction protocol and auditor walk-through. User Attestation Protocol with required fields. Tool-Provider Disclaimer locked boilerplate. Jurisdictional Red Flags (TOS-RED auto-halt, regulated verticals, non-US user + US TOS-AMBER/RED, AI-ban keywords, missing-jurisdiction halt, IP-country-mismatch warning). |
| `scripts/anti-bot-lint.sh` | 54 (exec) | POSIX bash script with `set -euo pipefail`, nine-package `DENY` array, five-file `SCAN_FILES` array (`package.json`, `.mcp.json`, `pyproject.toml`, `requirements.txt`, `Gemfile`), grep pattern `"\"$pkg\"\|'$pkg'\|$pkg=="` covering double-quoted JSON keys, single-quoted JSON keys, and pip-style pins. Exits 1 on first match with `DENY-LIST VIOLATION: <pkg> found in <file>`. Exits 0 with `anti-bot deny-list lint: clean`. No dependencies beyond bash + grep. Executable bit committed. |

### Files Modified

| Path | Change | Purpose |
| --- | --- | --- |
| `.github/workflows/ci.yml` | +8 lines (56 to 63 lines total body; 64 with trailing newline) | Appended `anti-bot-lint` job after the existing `check-links` job. Job runs on `ubuntu-latest`, uses `actions/checkout@v4`, then runs the single step `Anti-bot deny-list lint` invoking `bash scripts/anti-bot-lint.sh`. No `npm install` / `pip install` precedes the lint step; a poisoned manifest is caught before `node_modules/` or `.venv/` pollution. The four existing jobs (`lint-markdown`, `validate-yaml`, `test-scenarios`, `check-links`) were not modified. |

## Requirements Closed

- **BROWSER-05** (CI anti-bot deny-list lint rejects deny-listed packages on push + pull_request): `scripts/anti-bot-lint.sh` + `.github/workflows/ci.yml` `anti-bot-lint` job. Verified with synthetic negative test (poisoned `/tmp/package.json` containing `"playwright-extra": "^1.0.0"` exits 1 with the expected `DENY-LIST VIOLATION: playwright-extra found in package.json` message).
- **BROWSER-06** (Patchright pin policy documented): `browser-stack.md` Pinned Stack row + Patchright Usage Rules section; `patchright@^1.59.4` pin + explicit prohibition on fingerprint / User-Agent / navigator / TLS / header spoofing.
- **BROWSER-07** (stack pins captured): `browser-stack.md` Pinned Stack table with six rows (playwright@^1.59.1, patchright@^1.59.4, @playwright/mcp@^0.0.70, curlconverter@^4.12.0, @har-sdk/validator@^2.6.1, fetch-har@^12.0.1); release dates per STACK.md (2026-04-18 for playwright, 2026-Q1 for the rest).
- **BROWSER-09** (Ralph retry belt-and-suspenders coverage): `browser-stack.md` Ralph Retry Protocol section with budget (3 default per governance.yaml, hard cap 5), exponential backoff ladder (1s, 4s, 16s between attempts), state persistence to `.agentbloc/discovery/<service-slug>/state.json` under `retries[]`, forbidden adjustments (User-Agent, TLS, headers, proxy rotation, plugin injection) vs allowed adjustments (timing jitter, wait-for-selector extension, 5xx / 429 Retry-After, fresh browser context).
- **BROWSER-12** (jurisdictional variance documented): `legal-posture.md` five-row Variance Matrix covering US / UK / EU / DE / BR with relevant law, broadest-interpretation, safe-harbor, and highest-risk-failure-mode columns; DISCOVERY-LICENSE-NOTICE.md template; OPT_IN_LEDGER.jsonl schema with append-only corrects_entry correction protocol; tool-provider disclaimer boilerplate.

## Decisions Applied

- **D-46** (OPT_IN_LEDGER.jsonl per-project append-only): locked in `legal-posture.md` OPT_IN_LEDGER.jsonl Format section with schema + field contracts + correction protocol + auditor walk-through.
- **D-47** (DISCOVERY-LICENSE-NOTICE.md committed per service): template locked in `legal-posture.md` DISCOVERY-LICENSE-NOTICE.md Template section; committed-to-repo rationale called out.
- **D-48** (ALLOWED + DENY-LIST): Pinned Stack + Anti-Bot Deny-List tables in `browser-stack.md`; mirrored verbatim in `scripts/anti-bot-lint.sh` DENY array.
- **D-49** (three-posture A/B/C with hard halt at C): Stack Variant Guidance table in `browser-stack.md` plus posture-halt language threading through Patchright Usage Rules, Ralph Retry Cross-Reference, Jurisdictional Red Flags.
- **D-54** (five-jurisdiction matrix + tool-provider disclaimer): Variance Matrix + locked disclaimer text in `legal-posture.md`.
- **D-55** (Ralph retry with caps): Ralph Retry Protocol section in `browser-stack.md` with exact budget, backoff, forbidden/allowed adjustments, and state-file location.
- **D-56** (bash lint script + ci.yml extension): verbatim script body and CI step wired.
- **D-58** (context-budget load-points): `browser-stack.md` is the unconditional Phase 3 load; `legal-posture.md` is the subagent-only (fork context) load. Only two refs added to Phase 3 unconditional load from this plan.

## Verification Results

| Check | Result |
| --- | --- |
| `browser-stack.md` exists, 152 lines in band [150, 280] | PASS |
| `browser-stack.md` contains all nine deny-listed package names | PASS |
| `browser-stack.md` contains `playwright@^1.59.1` and `patchright@^1.59.4` pin strings | PASS |
| `browser-stack.md` contains `Ralph` keyword for retry protocol | PASS |
| `browser-stack.md` zero em-dash characters | PASS |
| `legal-posture.md` exists, 180 lines in band [180, 320] | PASS |
| `legal-posture.md` contains CFAA, Computer Misuse Act, GDPR, BDSG, LGPD | PASS |
| `legal-posture.md` contains OPT_IN_LEDGER, DISCOVERY-LICENSE-NOTICE, corrects_entry | PASS |
| `legal-posture.md` contains TOS-GREEN, TOS-AMBER, TOS-RED | PASS |
| `legal-posture.md` contains See-line cross-reference to `credentials.md` | PASS |
| `legal-posture.md` zero em-dashes, zero section signs, zero German umlauts | PASS |
| `scripts/anti-bot-lint.sh` exists with +x bit (100755) | PASS |
| `scripts/anti-bot-lint.sh` 54 lines in band [40, 80] | PASS |
| `scripts/anti-bot-lint.sh` `set -euo pipefail` + SCAN_FILES present | PASS |
| `scripts/anti-bot-lint.sh` contains all nine deny-listed package names | PASS |
| `bash scripts/anti-bot-lint.sh` on clean repo exits 0 with `anti-bot deny-list lint: clean` | PASS |
| Synthetic negative test: poisoned `/tmp/package.json` with playwright-extra exits 1 | PASS |
| Synthetic negative test message: `DENY-LIST VIOLATION: playwright-extra found in package.json` | PASS |
| `.github/workflows/ci.yml` contains `Anti-bot deny-list lint` step name | PASS |
| `.github/workflows/ci.yml` contains `bash scripts/anti-bot-lint.sh` | PASS |
| `.github/workflows/ci.yml` contains `anti-bot-lint:` job key | PASS |
| All files zero em-dash characters | PASS |

## CI Lint Behavior Summary

- Clean repo: exits 0 with `anti-bot deny-list lint: clean`. No manifest file yet exists at the repo root that would trip the lint; the script tolerates missing files (`[ -f "$file" ] || continue`).
- Poisoned manifest: exits 1 with `DENY-LIST VIOLATION: <pkg> found in <file>` on first match. PR status check fails immediately, blocking merge.
- No dependency install step precedes the lint in the CI job; `actions/checkout@v4` is the only preparation. A poisoned manifest is caught before `node_modules/` or `.venv/` pollution.
- Separate job (not folded into `lint-markdown`) so a violation surfaces in GitHub PR status checks as `Anti-bot Deny-list Lint: failed` rather than hidden inside another job's output.

## Next Downstream Plans

- **Plan 11-03** (browser-discovery subagent definition): `.claude/agents/browser-discovery.md` with scoped Playwright MCP tools (no Bash, no WebFetch), `context: fork`, Mandatory Initial Read list that includes `browser-stack.md` and `legal-posture.md` from this plan, `<write_constraint>` + `<output_contract>` XML blocks.
- **Plan 11-04** (wiring): unmark `[Phase 11 scope]` marker + concrete See-line replacement in `phase-3-integration.md` Priority 3; extend `SKILL.md` Phase 3 See-line load-list with `browser-fallback.md` + `browser-stack.md` (the two unconditional Phase 3 loads per D-58).
