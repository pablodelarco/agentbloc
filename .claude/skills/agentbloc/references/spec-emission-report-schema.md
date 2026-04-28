# Deploy Report Schema

> Dual-artifact contract for Phase 12 Step 8 emission. DEPLOY-REPORT.md is the happy-path summary; DEPLOY-FAILED-REPORT.md is the halt-and-name twin (per D-70) emitted instead of DEPLOY-REPORT.md on any hard-fail. Both live at .agentbloc/deploy/.

## Table of Contents

- [When This Applies](#when-this-applies)
- [DEPLOY-REPORT.md Frontmatter Schema](#deploy-reportmd-frontmatter-schema)
- [DEPLOY-REPORT.md Body Sections](#deploy-reportmd-body-sections)
- [Created](#created)
- [Updated](#updated)
- [Skipped](#skipped)
- [Pending User Actions](#pending-user-actions)
- [Post-Deploy Verification](#post-deploy-verification)
- [Bounded Enum: verification_status](#bounded-enum-verification_status)
- [DEPLOY-FAILED-REPORT.md Schema](#deploy-failed-reportmd-schema)
- [Bounded Enum: halt_reason](#bounded-enum-halt_reason)
- [Fingerprint Protocol (D-60)](#fingerprint-protocol-d-60)
- [Validation Checklist](#validation-checklist)
- [Emission Protocol](#emission-protocol)
- [Re-run Behavior](#re-run-behavior)
- [Cross-References](#cross-references)

## When This Applies

The deploy-engine subagent (`.claude/agents/deploy-engine.md`, Plan 12-02) loads this file in its forked context on invocation, NOT at Phase 5 entry (per D-58 context-budget discipline). This file defines the dual emission contract for Phase 12 Step 8: exactly ONE of DEPLOY-REPORT.md (happy path) or DEPLOY-FAILED-REPORT.md (halt) is written per deploy run. Both live at `.agentbloc/deploy/`. Downstream consumers: [deploy-protocol.md](deploy-protocol.md) Step 8 (emission trigger); Phase 14 Monitor (reads verification_status for team-health rollups); Phase 16 End-to-End Validation (replays the Arco Rooms fixture at `examples/arco-rooms-deploy-report.md`); operator humans (read the report after every deploy to understand what landed, what failed, what needs manual action).

**Plan 12-01 triple literal override notice (PHASE 12 TRIPLE LITERAL OVERRIDE):** The DEPLOY-REPORT.md `## Created` and `## Updated` body sections reference artifact paths per the D-59a / D-59b / D-59c split: SKILL.md artifacts at `.claude/skills/<agent-id>/SKILL.md` (D-59a), memory artifacts at `.agentbloc/agents/<agent-id>/` (D-59b), registry at `.agentbloc/agents/registry.yaml` (D-59c). The override rationale is the stable-vs-mutable architectural split documented in [deploy-protocol.md](deploy-protocol.md) Section 1.

This file is declarative (YAML schemas + bounded enums + validation checklist); [deploy-protocol.md](deploy-protocol.md) is imperative (step-by-step flow the subagent walks). The emission contract is the terminal artifact of every Phase 12 deploy run.

## DEPLOY-REPORT.md Frontmatter Schema

```yaml
---
schema_version: 1
deployment_id: <uuid-v4>
deployed_at: <ISO-8601 UTC with Z suffix>
team_name: <from agent-profiles.yaml>
agent_count: <integer>
integration_count: <integer>
verification_status: PASSED | PARTIAL | FAILED
idempotent_hash: <64-hex over all emitted artifacts together>
sha256: <64-hex>
---
```

Field semantics:

- `schema_version`: integer. Currently `1`. Downstream consumers refuse to proceed on an unknown major version.
- `deployment_id`: fresh UUID-v4 per deploy run. Never reused across runs; ties the report to the `DEPLOY_HISTORY.jsonl` ledger line.
- `deployed_at`: ISO-8601 UTC with Z suffix. Masked to `<TIMESTAMP>` during the D-60 fingerprint computation.
- `team_name`: copied from `agent-profiles.yaml` `team.name`. Must match the registry.yaml entry.
- `agent_count`: integer count of agents in the `## Created` + `## Updated` + `## Skipped` sections combined.
- `integration_count`: integer count of MCP entries processed in Step 7 `.mcp.json` merge.
- `verification_status`: one of the 3-value bounded enum below. Rolled up from D-69 three-check verification.
- `idempotent_hash`: 64-hex SHA256 computed over the concatenation of all emitted artifacts' individual fingerprints, sorted by artifact path. Stable across equivalent re-runs.
- `sha256`: 64-hex SHA256 of the DEPLOY-REPORT.md body (excluding the `sha256` frontmatter line itself) per D-60.

## DEPLOY-REPORT.md Body Sections

Five H2 sections in fixed order after the frontmatter. Every deploy run writes all five, even when a section is empty (empty sections emit a one-line "(none)" placeholder). The five sections are enumerated as `## Created`, `## Updated`, `## Skipped`, `## Pending User Actions`, `## Post-Deploy Verification` below.

## Created

Table with one row per newly emitted artifact:

| filepath | sha256 | generation_source |
|---|---|---|
| `.claude/skills/<agent-id>/SKILL.md` | `<64-hex>` | `agent-profiles.yaml + deployed-agent-skill-<autonomy>.md.tmpl` |
| `.agentbloc/agents/<agent-id>/memory.md` | `<64-hex>` | `agent-memory-schema.md Section 2 template` |
| `.agentbloc/agents/<agent-id>/state.json` | `<64-hex>` | `agent-memory-schema.md Section 3 initialization` |
| `.agentbloc/agents/<agent-id>/last-run.json` | `<64-hex>` | `agent-memory-schema.md Section 4 initialization` |
| `.agentbloc/agents/registry.yaml` | `<64-hex>` | `D-63 schema + agent-profiles.yaml denormalization` |

## Updated

Table with one row per fingerprint-differed artifact (overwritten after user approval in Step 3):

| filepath | old_sha256 | new_sha256 | diff_link |
|---|---|---|---|
| `.claude/skills/recepcionista/SKILL.md` | `<64-hex>` | `<64-hex>` | `.agentbloc/deploy/pending-diffs/recepcionista-SKILL.diff` |

## Skipped

Table with one row per fingerprint-matched artifact:

| filepath | sha256 | reason |
|---|---|---|
| `.claude/skills/gestor-documental/SKILL.md` | `<64-hex>` | idempotent-match |

## Pending User Actions

Bullet list. Each entry names the exact file / env var / decision-point and the recommended resolution. Canonical categories:

- Credentials missing per integration (e.g., "Set `TELEGRAM_BOT_TOKEN` in `.env` as documented in `.env.example`")
- ToS opt-in needed for `[DISCOVERED]`-tier entries (Phase 11 browser-fallback integrations)
- `.mcp.json` conflicts awaiting decision (from Step 7 `mcp_merge_action: keep-existing-conflict-warn`)
- n8n webhook routes to configure (from D-73 placeholder stubs)
- System cron install (e.g., "Run `crontab .agentbloc/deploy/crontab.proposed` in your shell to register the Phase 13 cron entries")

## Post-Deploy Verification

Table with one row per D-69 check + overall rollup:

| check | status | note |
|---|---|---|
| SKILL.md loads cleanly (`claude agents list`) | PASS | 3 of 3 agent-ids present |
| MCP servers respond (`tools/list`) | PASS | 8 of 8 servers responded within timeout |
| Cron registered (`crontab -l`) | SKIP | Phase 13 not yet executed; cron verification skipped |

## Bounded Enum: verification_status

The `verification_status` field on DEPLOY-REPORT.md is drawn from a fixed 3-value set. Exactly one of: `PASSED | PARTIAL | FAILED`. Rollup rules per D-69:

| Enum Value | Condition | Gate Behavior |
|---|---|---|
| `PASSED` | All three checks PASS; zero FAIL rows | Phase 5 gate advances; deploy considered healthy |
| `PARTIAL` | Check 1 (SKILL.md) PASS; Check 2 or Check 3 has soft-fail but no hard-fail on required integration | Phase 5 gate advances with warning banner; user sees which soft-fails to address |
| `FAILED` | Check 1 (SKILL.md) FAILS, OR Check 2 has hard-fail on a required integration, OR any other hard-fail during Steps 1-7 | DEPLOY-REPORT.md NOT emitted; DEPLOY-FAILED-REPORT.md emitted instead per D-70; Phase 5 gate blocks |

Any value outside `{PASSED, PARTIAL, FAILED}` blocks emission (schema violation caught by Validation Checklist Check 2).

## DEPLOY-FAILED-REPORT.md Schema

The halt-and-name twin emitted INSTEAD of DEPLOY-REPORT.md on any hard-fail during Steps 1-8 of [deploy-protocol.md](deploy-protocol.md). Never co-exists with a DEPLOY-REPORT.md for the same `deployment_id`.

```yaml
---
schema_version: 1
deployment_id: <uuid-v4>
halted_at: <ISO-8601 UTC with Z suffix>
halt_reason: template-load-failure | yaml-parse-error | disk-full | permission-denied | verification-failed | user-rejected-diff
halt_step: <step number 1-8>
team_name: <from agent-profiles.yaml>
error_excerpt: <first 200 chars of the specific error message, redacted for PII>
---
```

Body (three H2 sections in fixed order):

- **`## Failure Details`** , concrete evidence: which file, which field, which step, what went wrong. Quote the exact error message inside a ` ```error ... ``` ` code fence. If the failure came from a tool invocation (`claude agents list`, `tools/list`, etc.) quote the tool's stderr output.
- **`## Partial State`** , list of files that WERE written before halt (may need manual rollback). One bullet per file with its full path. If no files were written (e.g., halt at Step 1 before any atomic write), emit `(none, halt occurred before any write)`.
- **`## Resumption Advice`** , what the user should fix before re-running. One paragraph per fix option. Name the exact file / env var / decision-point.

**Twin behavior (per D-70):** this schema mirrors DISCOVERY-BLOCKED-REPORT.md from Phase 11 (halt-and-name pattern carry-forward). Single-emit discipline: exactly one of DEPLOY-REPORT.md or DEPLOY-FAILED-REPORT.md is written per deploy run. No retry, no partial-write commits.

## Bounded Enum: halt_reason

Six values. Exactly one is written per DEPLOY-FAILED-REPORT.md. Any value outside this enum blocks emission.

| Enum Value | Trigger | Originating Step |
|---|---|---|
| `template-load-failure` | Template file missing, unreadable, or substitution failed | Step 4 of [deploy-protocol.md](deploy-protocol.md) |
| `yaml-parse-error` | agent-profiles.yaml or integration-manifest.yaml invalid, or a validation checklist field error | Step 1 of [deploy-protocol.md](deploy-protocol.md) |
| `disk-full` | Write operation failed due to storage exhaustion | Step 5, 6, or 7 of [deploy-protocol.md](deploy-protocol.md) |
| `permission-denied` | Write operation failed due to filesystem permissions | Step 5, 6, or 7 of [deploy-protocol.md](deploy-protocol.md) |
| `verification-failed` | D-69 three-check rollup returned FAILED | Step 8 of [deploy-protocol.md](deploy-protocol.md) |
| `user-rejected-diff` | User declined to approve a proposed change in Step 3 | Step 3 of [deploy-protocol.md](deploy-protocol.md) |

## Fingerprint Protocol (D-60)

Both artifacts carry the HTML-comment fingerprint `<!-- agentbloc:fingerprint sha256=<64-hex> generated_at=<ISO-8601 UTC with Z suffix> -->` at the end of the body, after all H2 sections. The fingerprint is the LAST line of the file.

**Hashing rules (D-60):**

1. **Strip the fingerprint line** before re-hashing on re-deploy to avoid the recursive-hash trap.
2. **Mask all ISO-8601 timestamps** in both the frontmatter (`deployed_at`, `halted_at`, `generated_at`) and the body (any timestamp in Pending User Actions prose, any timestamp in Post-Deploy Verification notes) to the literal placeholder `<TIMESTAMP>`. This applies to both markdown frontmatter and any embedded JSON.
3. **RFC 8785 JSON Canonicalization Scheme (JCS) for any JSON sub-sections:** the Post-Deploy Verification table if it embeds raw JSON (tool response bodies), or any JSON blob inside the `## Failure Details` error fence, are re-serialized per RFC 8785 (sorted keys, UTF-8 no BOM, shortest-number, no insignificant whitespace) before hashing. Pure-markdown content does not need this step.
4. **Compute SHA256** over the canonicalized byte sequence of the body. Write the 64-hex digest into the fingerprint line.

The `sha256` field in the frontmatter and the `sha256` in the HTML-comment fingerprint line carry the SAME value. The frontmatter copy is for machine-query convenience; the comment copy is for paper-trail grepping.

## Validation Checklist

The deploy-engine walks this ordered list after rendering the report and BEFORE writing to disk. Any FAIL blocks emission; the deploy-engine falls back to emitting DEPLOY-FAILED-REPORT.md with `halt_reason: yaml-parse-error` citing the specific check.

1. `schema_version` equals `1` on both DEPLOY-REPORT.md and DEPLOY-FAILED-REPORT.md frontmatters. FAIL: halt; the deploy-engine wrote a wrong scaffold.
2. `verification_status` on DEPLOY-REPORT.md is one of `{PASSED, PARTIAL, FAILED}`. If `FAILED`, DEPLOY-REPORT.md must NOT be emitted; DEPLOY-FAILED-REPORT.md emits instead. FAIL: halt citing the enum mismatch.
3. Every filepath referenced in `## Created`, `## Updated`, and `## Skipped` exists on disk (verify via filesystem stat after Step 5 + Step 6 writes). FAIL: halt; some atomic write was silently dropped.
4. Every diff file referenced in `## Updated` exists at `.agentbloc/deploy/pending-diffs/<name>.diff`. FAIL: halt; Step 3 diff emission was skipped.
5. Every Pending User Action bullet names a concrete resolution (not a vague "fix this"). Grep the bullets for imperative verbs (`Set`, `Run`, `Configure`, `Add`, `Approve`) at the start of each; zero matches = vague prose. FAIL: halt with the offending bullet quoted.
6. `halt_reason` on DEPLOY-FAILED-REPORT.md is one of the 6-value enum. FAIL: halt citing the invalid value.
7. NO DEPLOY-REPORT.md AND DEPLOY-FAILED-REPORT.md co-exist for the same `deployment_id`. Scan `.agentbloc/deploy/` for both files with matching frontmatter UUIDs; if both present, halt citing "single-emit violation".
8. `idempotent_hash` on DEPLOY-REPORT.md matches the recomputed hash over the concatenation of all emitted artifacts' fingerprints. FAIL: halt; the fingerprint accumulation in Step 2 drifted.
9. Every ISO-8601 timestamp in both reports carries the `Z` UTC suffix. FAIL: halt citing the offending field.

## Emission Protocol

Emission happens at the END of every deploy run per Step 8 of [deploy-protocol.md](deploy-protocol.md). The deploy-engine walks:

1. Rollup `verification_status` from the D-69 three-check results.
2. If `verification_status == FAILED` OR any hard-fail occurred during Steps 1-7: render DEPLOY-FAILED-REPORT.md with the specific `halt_reason` from the 6-value enum. Skip to step 5.
3. Otherwise (PASSED or PARTIAL): render DEPLOY-REPORT.md with all 5 body sections populated.
4. Walk the Validation Checklist above.
5. Compute the D-60 fingerprint over the canonicalized body. Insert into the frontmatter `sha256` field AND the HTML-comment fingerprint line.
6. Write the report atomically to `.agentbloc/deploy/DEPLOY-REPORT.md` OR `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` (exactly one).
7. Append exactly one JSON line to `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` per D-71:

```json
{"deployment_id": "<uuid-v4>", "attempted_at": "<ISO-8601 UTC with Z suffix>", "completed_at": "<ISO-8601 UTC with Z suffix | null>", "verification_status": "PASSED | PARTIAL | FAILED", "agent_count": <integer>, "integration_count": <integer>, "idempotent_hash": "<64-hex>", "report_path": ".agentbloc/deploy/DEPLOY-REPORT.md | .agentbloc/deploy/DEPLOY-FAILED-REPORT.md", "halt_reason": "<enum-value | null>"}
```

The `DEPLOY_HISTORY.jsonl` ledger is append-only. Each line is RFC 8785 canonicalized before hashing per D-60 for downstream audit. Matches the OPT_IN_LEDGER.jsonl pattern from Phase 11 (D-46).

8. Surface to the user: "Deploy `<deployment_id>` complete: verification_status `<PASSED|PARTIAL|FAILED>`. See `.agentbloc/deploy/DEPLOY-REPORT.md` (or DEPLOY-FAILED-REPORT.md)." Include a one-line pointer to any Pending User Actions that block the next wake.

## Re-run Behavior

A new `deployment_id` UUID-v4 is generated per run. Prior reports are preserved on disk (append-only discipline); the latest DEPLOY-REPORT.md at the canonical path is always the most recent successful deploy.

**Re-run sequencing:**

- On successful re-deploy: the previous DEPLOY-REPORT.md is overwritten at the canonical path (`.agentbloc/deploy/DEPLOY-REPORT.md`). The previous version's data is preserved in the append-only `DEPLOY_HISTORY.jsonl` via the prior line. Users who need the full prior report body can grep `DEPLOY_HISTORY.jsonl` for the prior `deployment_id` and fetch from git history.
- On failed re-deploy: DEPLOY-FAILED-REPORT.md is emitted. The prior DEPLOY-REPORT.md is NOT overwritten (the file stays as the most recent successful deploy snapshot). A separate DEPLOY-FAILED-REPORT.md file at the same directory coexists until the next successful deploy.
- Phase 14 Monitor diffs across runs by reading `DEPLOY_HISTORY.jsonl` chronologically; it does not require reading prior DEPLOY-REPORT.md bodies.

**Fingerprint preservation:** the `idempotent_hash` frontmatter field is the stable identity of the deploy content. Two runs with identical inputs produce identical `idempotent_hash` values even if `deployment_id` differs; this is the signal Phase 14 Monitor uses to detect "no-op re-deploy" cadence.

## Cross-References

- [deploy-protocol.md](deploy-protocol.md) , Step 8 caller that emits these artifacts (the Halt Protocol section names DEPLOY-FAILED-REPORT.md as the terminal artifact per D-70)
- [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) , defines the SKILL.md artifacts listed in the `## Created` and `## Updated` sections
- [agent-memory-schema.md](agent-memory-schema.md) , defines the memory.md + state.json + last-run.json artifacts listed in the same sections
- [discovery-report-schema.md](discovery-report-schema.md) , Phase 11 structural twin; DEPLOY-REPORT.md inherits the frontmatter + body-sections pattern
- [browser-fallback.md](browser-fallback.md) Halt Protocol , DEPLOY-FAILED-REPORT.md is the Phase 12 twin of DISCOVERY-BLOCKED-REPORT.md
- `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` , append-only ledger per D-71; one line per deploy attempt
