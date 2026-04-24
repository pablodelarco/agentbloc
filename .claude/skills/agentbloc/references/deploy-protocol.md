# Deploy Pipeline Protocol

> When an agent-profiles.yaml (Phase 9) + integration-manifest.yaml (Phase 10) are approved, Phase 5 Step 4 invokes the deploy-engine subagent to materialize the team into a running ClaudeClaw-compatible deployment. This protocol is the imperative contract the subagent follows.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Flow Diagram](#flow-diagram)
- [Step 1: Input Validation](#step-1-input-validation)
- [Step 2: Fingerprint Compare](#step-2-fingerprint-compare)
- [Step 3: Diff Presentation](#step-3-diff-presentation)
- [Step 4: Template Render](#step-4-template-render)
- [Step 5: Atomic Write](#step-5-atomic-write)
- [Step 6: Registry Update](#step-6-registry-update)
- [Step 7: .mcp.json Merge](#step-7-mcpjson-merge)
- [Step 8: Post-Deploy Verification](#step-8-post-deploy-verification)
- [Halt Protocol](#halt-protocol)
- [Quick Reference](#quick-reference)
- [Cross-References](#cross-references)

## When This Applies

The deploy-engine subagent (`.claude/agents/deploy-engine.md`, Plan 12-02) loads this file in its forked context on invocation. The protocol runs during Phase 5 Step 4 of the AgentBloc flow, after user has approved agent-profiles.yaml (Phase 9) and the integration manifest (Phase 10). Downstream consumers: Phase 13 Multi-Agent Runtime (wakes deployed agents); Phase 14 Monitor (reads registry.yaml); Phase 16 End-to-End Validation (replays the Arco Rooms fixture). Loaded UNCONDITIONALLY at Phase 5 entry per D-58 context-budget discipline; three delegate schemas ([deployed-agent-skill-schema.md](deployed-agent-skill-schema.md), [agent-memory-schema.md](agent-memory-schema.md), [deploy-report-schema.md](deploy-report-schema.md)) are NOT loaded at Phase 5 entry (subagent-only).

**Plan 12-01 triple literal override notice (PHASE 12 TRIPLE LITERAL OVERRIDE, user-approved 2026-04-24):** REQUIREMENTS.md is internally inconsistent for the Deploy Pipeline output paths. All three literals are OVERRIDDEN on architectural grounds:

- **D-59a overrides DEPLOY-01:** SKILL.md ships at `.claude/skills/<agent-id>/SKILL.md` (Claude Code native skill discovery path; deployed agents become peer skills to agentbloc and mcp-builder; runtime-agnostic; OpenClaw / ClaudeClaw compatible per native convention).
- **D-59b overrides MEM-01:** memory files ship at `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}` (namespace hygiene; `.claude/agents/` reserved for Claude Code native subagent definitions only).
- **D-59c overrides DEPLOY-05:** registry at `.agentbloc/agents/registry.yaml` (co-location with the state it indexes).

The unifying architectural principle is the stable-vs-mutable split: SKILL.md contracts are versioned, reviewed, audited (belong in `.claude/skills/`); memory + state files are machine-written on every wake (belong in `.agentbloc/`, customer-mutable namespace per Phase 11 precedent). Phase 16 audit readers must see this justification.

Three resume states apply:

- **Fresh run:** no prior `.agentbloc/deploy/DEPLOY-REPORT.md` for this team; walk Steps 1 through 8 in order.
- **Re-deploy with no profile change:** existing DEPLOY-REPORT.md present and Step 2 fingerprint matches across all artifacts; deploy-engine emits an idempotent-skip DEPLOY-REPORT.md listing every artifact under `## Skipped` and advances the gate.
- **Re-deploy with drift:** Step 2 detects one or more differing fingerprints; deploy-engine pauses at Step 3 for user approval of every proposed diff before proceeding to Steps 4 through 8.

This file is imperative (step-by-step flow the subagent walks); [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) is declarative (anchor-point allow-list consulted in Step 4); [agent-memory-schema.md](agent-memory-schema.md) is the output contract for Step 5; [deploy-report-schema.md](deploy-report-schema.md) is the output contract for Step 8. The four files together cover Phase 5 Step 4 top to bottom.

## Flow Diagram

```
┌─────────────────────────────────────────┐
│ INPUT: .agentbloc/team/agent-profiles   │
│        .agentbloc/integrations/manifest │
└──────────────────┬──────────────────────┘
                   ▼
       ┌──────────────────────┐
       │ Step 1: Validate     │ ──fail──► DEPLOY-FAILED-REPORT.md
       │  (profiles+manifest) │
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 2: Fingerprint  │
       │  (SHA256 + RFC 8785) │
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 3: Diff Present │ ──user rejects──► DEPLOY-FAILED-REPORT.md
       │  (unified, 5-line)   │
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 4: Template     │ ──load failure──► DEPLOY-FAILED-REPORT.md
       │  Render (3 variants) │
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 5: Atomic Write │ ──disk full──► DEPLOY-FAILED-REPORT.md
       │  (SKILL + memory)    │
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 6: Registry     │
       │  Update (yaml)       │
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 7: .mcp.json    │ ──conflict unapproved──► DEPLOY-FAILED-REPORT.md
       │  Merge (non-destruct)│
       └──────────┬───────────┘
                  ▼
       ┌──────────────────────┐
       │ Step 8: Verify       │ ──hard fail──► DEPLOY-FAILED-REPORT.md
       │  (agents+mcp+cron)   │
       └──────────┬───────────┘
                  ▼
     .agentbloc/deploy/DEPLOY-REPORT.md
                  │
                  ▼
   registry.yaml + append to DEPLOY_HISTORY.jsonl
```

Note on emission: use ASCII box-drawing characters only (`┌ ┐ └ ┘ │ ─ ► ▼`). The diagram must render in any plain-text viewer.

## Step 1: Input Validation

**Action:** Read `.agentbloc/team/agent-profiles.yaml` and `.agentbloc/integrations/integration-manifest.yaml`. For every agent in `agent-profiles.yaml`, verify that every REQUIRED field in the [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) anchor-point allow-list is populated and that `autonomy` is one of `full | semi | supervised`. For every tool referenced in `agents[].tools[]`, verify an entry exists in `integration-manifest.yaml` with `status: verified`. Optional `DISCOVERY-REPORT.md` references (if an agent consumes a `[DISCOVERED]`-tier integration per Phase 11) are loaded for traceability only; they are not validated here.

**Input:** `.agentbloc/team/agent-profiles.yaml` + `.agentbloc/integrations/integration-manifest.yaml` + zero or more `.agentbloc/discovery/<slug>/DISCOVERY-REPORT.md` files.

**If validation passes:** Proceed to Step 2.

**If validation fails:** Halt with `halt_reason: yaml-parse-error` (for YAML syntax errors) or a specific per-field error (for missing REQUIRED fields) naming the offending file + agent-id + field. Emit DEPLOY-FAILED-REPORT.md per [deploy-report-schema.md](deploy-report-schema.md) and stop.

**Arco Rooms example:** Reads `arco-rooms-agent-profiles.yaml` (3 agents: gestor-documental, recepcionista, gestor-cobros) and `arco-rooms-integration-manifest.yaml` (8 verified tools). All REQUIRED fields present, all autonomy values valid, all tool references resolve. Step 1 PASS.

**Rationale:** Fail-fast before any write. A partially-validated team that gets halfway through Step 4 template render leaves the filesystem in a dirty state; Step 1 guarantees the run is either fully safe-to-proceed or cleanly halted.

## Step 2: Fingerprint Compare

**Action:** For each artifact the deploy will emit (per-agent SKILL.md, per-agent memory.md + state.json + last-run.json, registry.yaml, `.mcp.json` delta), compute SHA256 over canonicalized body per D-60. Canonicalization has two rules:

1. **Timestamp masking (all artifacts):** ISO-8601 timestamps are replaced with the fixed placeholder `<TIMESTAMP>` before hashing.
2. **RFC 8785 JSON Canonicalization Scheme (JCS) for JSON artifacts only:** `state.json`, `last-run.json`, and every line of `DEPLOY_HISTORY.jsonl` are re-serialized per RFC 8785 (sorted keys, UTF-8 no BOM, shortest-number representation, no insignificant whitespace) before hashing. The `_agentbloc_fingerprint` top-level field is stripped before hashing.

Compare each computed hash to the fingerprint block in the existing file (if present). Same hash = `skip`. Different hash = proceed to Step 3 diff presentation. Missing existing file = `create`.

**Input:** List of artifacts planned for this deploy + any existing versions on disk.

**If all hashes match existing (full idempotent skip):** Emit a fast-path DEPLOY-REPORT.md with every artifact under `## Skipped`. Gate advances.

**If some or all hashes differ:** Build a per-artifact diff queue for Step 3.

**Arco Rooms example:** First deploy has no existing artifacts; all 3 SKILL.md + 9 memory files + 1 registry.yaml + 1 `.mcp.json` delta are in `create` status. Re-deploy after a `recepcionista.goal` edit flips one SKILL.md to `update` while the other 12 stay `skip`.

**Rationale (D-60):** Matches the DISCOVERY-REPORT.md SHA256 discipline (Phase 11 D-45) and extends it with RFC 8785 canonicalization per 2026 JSON-hashing best practice. Timestamp masking avoids the "every re-run is a diff" trap. RFC 8785 avoids the equally bad "editor reordered keys so every re-run is a diff" trap specific to machine-written JSON in AI-agent systems. Git-blob-hash rejected because users deploy without git (VPS, Docker image). Mtime rejected because clone / rsync / image-bake resets it arbitrarily.

## Step 3: Diff Presentation

**Action:** For every artifact whose Step 2 fingerprint differed, produce a unified diff (`diff -u` style) with 5 lines of context before and after each hunk. The diff is:

1. Embedded in DEPLOY-REPORT.md under a collapsed `<details>` block per affected file (standard Markdown collapsible).
2. Printed to stdout in the conversation so the user can review before approving.
3. Saved separately to `.agentbloc/deploy/pending-diffs/<agent-id>-<artifact>.diff` for audit trail.

Ask the user for explicit per-artifact approval. Default is ask-for-approval; no silent overwrite.

**Input:** Per-artifact diff queue from Step 2 + the existing body + the newly rendered body.

**If all diffs approved:** Proceed to Step 4.

**If any diff rejected:** Halt with `halt_reason: user-rejected-diff` naming the specific artifact the user declined. Emit DEPLOY-FAILED-REPORT.md and stop.

**Arco Rooms example:** Re-deploy after editing `recepcionista.goal`. Step 3 emits one unified diff showing the 2-line goal change; user approves; deploy proceeds. On first deploy the queue is empty (everything is `create`, which does not need a diff).

**Rationale (D-61 + D-37):** Unified diff is the standard developer-audit format; 5-line context matches `git diff` defaults for scannable hunks. Saving diffs separately to `.agentbloc/deploy/pending-diffs/` gives the user a pre-commit-hook-style review artifact they can paste into a PR or share with a teammate before approving. Consistent with D-37 approval-gated execution: Claude never silently clobbers user-customized content.

## Step 4: Template Render

**Action:** For each agent, read `agent.autonomy_level` from `agent-profiles.yaml` and select one of three templates at `.claude/skills/agentbloc/templates/deployed-agent-skill-<autonomy>.md.tmpl` where `<autonomy>` is `full`, `semi`, or `supervised`. Pre-compute the two composite anchors before substitution:

- `{{agent.tools}}` is pre-computed by reading `integration-manifest.yaml`, filtering by the agent's `tools[]` list, and rendering each tool as a bullet `- mcp__<server>__<method>` line.
- `{{agent.autonomy_language}}` is pre-computed from a fixed 3-way lookup (full = "full autonomy, no prompt required"; semi = "semi-autonomous, confirm before side-effects"; supervised = "supervised, propose and wait for approval").

Substitute all 13 anchor points per [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md). NO in-template branching, NO conditional blocks, NO loops; the template is pure `{{var}}` substitution.

**Input:** Agent record from Step 1 validation + one of three template files + pre-computed `agent.tools` bullet string + pre-computed `agent.autonomy_language` prose string.

**If template loads and substitution succeeds:** Hand the rendered body to Step 5.

**If template load fails (missing file, unreadable):** Halt with `halt_reason: template-load-failure`. Emit DEPLOY-FAILED-REPORT.md and stop.

**Arco Rooms example:** 3 agents with autonomy values supervised / semi / full. Deploy-engine loads 3 different template files and renders 3 distinct SKILL.md bodies with the same skeleton but each carrying its own `<!-- agentbloc:template autonomy=<level> schema_version=1 -->` marker.

**Rationale (D-62):** Phase 9 locked the agent's prompt structure into YAML. Those fields ARE the prompt content; no synthesis is needed. 12-RESEARCH.md topic 3 showed that a SINGLE-template approach with `{% if %}` / `{% for %}` blocks is the failure mode for Claude-in-context substitution (escaping, conditional branches, loop rendering all introduce token-level variance even with the same inputs). Splitting the autonomy-variant prose into three separate template files and using `agent.autonomy_level` to select which file to load gives one-line routing and zero branching inside the template. Deterministic (same inputs, same output), cheap (no LLM-per-agent cost), testable (Phase 16 golden-file tests per autonomy level).

## Step 5: Atomic Write

**Action:** Write each rendered artifact to its canonical path. Use these paths verbatim (D-59a + D-59b):

- `SKILL.md` per agent => `.claude/skills/<agent-id>/SKILL.md` (D-59a)
- `memory.md` per agent => `.agentbloc/agents/<agent-id>/memory.md` (D-59b; template in [agent-memory-schema.md](agent-memory-schema.md) Section 2)
- `state.json` per agent => `.agentbloc/agents/<agent-id>/state.json` (D-59b; schema in [agent-memory-schema.md](agent-memory-schema.md) Section 3; RFC 8785 canonicalized per D-60)
- `last-run.json` per agent => `.agentbloc/agents/<agent-id>/last-run.json` (D-59b; schema in [agent-memory-schema.md](agent-memory-schema.md) Section 4; RFC 8785 canonicalized per D-60)

Write order is atomic-per-artifact: SKILL.md first, then memory.md, then state.json, then last-run.json. The `.agentbloc/agents/<agent-id>/` directory is created if it does not exist. Append the HTML-comment fingerprint `<!-- agentbloc:fingerprint sha256=<64-hex> generated_at=<ISO-8601> -->` to markdown artifacts; inline `_agentbloc_fingerprint` top-level field on JSON artifacts.

**Input:** Rendered bodies from Step 4 + the three memory-schema scaffolds.

**If all writes succeed:** Proceed to Step 6.

**If any write fails (disk full, permission denied):** Halt with `halt_reason: disk-full` or `halt_reason: permission-denied`. Emit DEPLOY-FAILED-REPORT.md listing which artifact was last written (partial-write disclosure) so the user can manually rollback.

**Arco Rooms example:** 12 files land: `.claude/skills/gestor-documental/SKILL.md`, `.agentbloc/agents/gestor-documental/{memory.md, state.json, last-run.json}`, and the same 4-file pattern for recepcionista and gestor-cobros.

**Rationale (D-59a + D-59b):** The stable-vs-mutable split. SKILL.md is the immutable-per-deploy contract (lives in Claude Code native skill discovery path). Memory files are mutable runtime state (live in the `.agentbloc/` customer-state namespace). Git history stays clean on SKILL.md because content changes only on explicit re-deploy; memory files change on every wake without polluting the stable contract.

## Step 6: Registry Update

**Action:** Write `.agentbloc/agents/registry.yaml` per [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) cross-reference and D-63 schema (team shape + agent roster + reporting hierarchy). Schema includes `schema_version: 1`, `team.name`, `team.lead`, `team.topology`, `team.briefing_agent_id`, `team.deployed_at`, `team.last_deploy_id`, and a denormalized `agents[]` array with per-agent `id`, `role`, `skill_path` (pointing at `.claude/skills/<agent-id>/SKILL.md`), `memory_dir` (pointing at `.agentbloc/agents/<agent-id>/`), `autonomy`, `blast_radius`, `triggers[]`, and `dependencies[]`. `reporting_hierarchy` is a parent-to-children map for Phase 14 MONITOR-05. `dashboard_agent` starts `null`.

**Input:** Validated `agent-profiles.yaml` from Step 1 + fresh `deployment_id` UUID + current ISO-8601 timestamp.

**If write succeeds:** Proceed to Step 7.

**If write fails (disk full, permission denied):** Halt as in Step 5.

**Arco Rooms example:** Registry written with `team.name: arco-rooms`, `team.lead: gestor-cobros`, `team.topology: hierarchy`, three `agents[]` entries, `reporting_hierarchy: {gestor-cobros: [recepcionista, gestor-documental]}`, `dashboard_agent: null`.

**Rationale (D-59c + D-63):** Co-located with the per-agent memory directories that the registry indexes; single source of truth for "what deployed agents exist + what is their runtime state". Human-readable (Phase 14 briefing-agent consumes this for daily summaries; user may manually edit to rename a team or add a dashboard-agent). Denormalized `triggers` + `dependencies` enable quick registry scans without crawling every `memory_dir`.

## Step 7: .mcp.json Merge

**Action:** Merge `integration-manifest.yaml` MCP server entries into project `.mcp.json` per D-66 semantics. Use the `Edit` tool (not `Write`) to preserve unrelated entries byte-for-byte. Apply the five rules:

1. If `.mcp.json` does not exist: create it with only the merged entries. No prompt.
2. If an entry's `tool_id` key is NOT in `.mcp.json`: add it. Log `mcp_merge_action: add-new`. No prompt.
3. If the key IS present AND the config is byte-identical (SHA256 match per D-60): skip. Log `mcp_merge_action: skip-identical`.
4. If the key IS present AND the config differs: DO NOT overwrite. Log `mcp_merge_action: keep-existing-conflict-warn`, embed the diff in DEPLOY-REPORT.md, and ask the user: "The `<tool-id>` entry in `.mcp.json` differs from the integration manifest. Keep existing (safe default) or replace with manifest entry?"
5. On user `replace` approval: write the new config. Log `mcp_merge_action: replace-approved`.

**Input:** `integration-manifest.yaml` from Step 1 + existing `.mcp.json` content.

**If all merges resolve:** Proceed to Step 8.

**If user declines a conflict replace:** Keep existing; log the decision; proceed. This is not a hard halt.

**If the merge operation fails (file corruption, permission denied):** Halt per Step 5 semantics.

**Arco Rooms example:** First deploy creates `.mcp.json` with 8 MCP entries (playwright-mcp, google-workspace-mcp, telegram-mcp, gmail-mcp, google-sheets-mcp, notion-mcp, bank-mcp, mapfre-api). Re-deploy after a gmail-mcp version bump lands `mcp_merge_action: keep-existing-conflict-warn` because the user had customized the env-var list; user approves replace.

**Rationale (D-66):** Non-destructive by default; re-deploying never silently clobbers MCP config the user customized. Conflict warning preserves the audit trail (user sees the diff, makes a choice, the choice is logged). Consistent with D-37 approval-gated execution.

## Step 8: Post-Deploy Verification

**Action:** Run the 3-check verification loop per D-69. Checks use the deploy-engine's narrow Bash allow-list (`claude agents list`, `claude mcp list`, `crontab -l`, `shasum -a 256`).

- **Check 1 (SKILL.md loads cleanly):** Invoke `claude agents list`. Parse the output. Every generated agent-id from Step 5 must appear. Missing = FAIL. Warm operation (Claude Code already running); no timeout extension.
- **Check 2 (MCP servers respond):** Invoke `claude mcp list` for discovery. For each MCP server in `integration-manifest.yaml` with `status: verified`, issue a `tools/list` JSON-RPC request (the canonical MCP health-check method per the 2026 MCP spec). Timeout policy: 5 seconds for warm servers, 10 seconds for cold-start servers, with retry=3 and exponential backoff (1s, 2s, 4s) on timeout. A server that does not respond to `tools/list` within the retry budget fails this check. Optional integrations (those with `used_by: []` or `optional: true`) soft-fail: FAIL is logged, overall verification may still pass as PARTIAL.
- **Check 3 (cron registered):** Invoke `crontab -l`. Every Phase 13-bound cron entry that Phase 12 proposed in `.agentbloc/deploy/crontab.proposed` must be present. In Phase 12-only execution before Phase 13 lands, Check 3 soft-fails with note "Phase 13 not yet executed; cron verification skipped."

Roll up `verification_status` per D-69:

- PASSED: all three checks pass; zero FAIL rows
- PARTIAL: Check 1 passes; Check 2 or Check 3 has soft-fail but no hard-fail
- FAILED: Check 1 fails, OR Check 2 hard-fails on a required integration

**Input:** Results of `claude agents list` + `claude mcp list` + per-MCP `tools/list` responses + `crontab -l`.

**If PASSED or PARTIAL:** Emit DEPLOY-REPORT.md per [deploy-report-schema.md](deploy-report-schema.md) with all 5 body sections populated (Created / Updated / Skipped / Pending User Actions / Post-Deploy Verification). Append one line to `.agentbloc/deploy/DEPLOY_HISTORY.jsonl`.

**If FAILED:** Halt with `halt_reason: verification-failed`. Emit DEPLOY-FAILED-REPORT.md naming the failing check.

**Arco Rooms example:** Check 1 PASS (3 agent-ids present). Check 2 PASS for 8 MCPs (all respond within 5-10s). Check 3 SKIP with Phase-13-not-shipped note. `verification_status: PARTIAL`. DEPLOY-REPORT.md emitted.

**Rationale (D-69):** `tools/list` is the canonical MCP liveness probe per the 2026 MCP spec; `ping` / `resources/list` / generic-hit were rejected in 12-RESEARCH.md topic 5. Soft-fail for optional MCPs prevents a transient "Mapfre is down today" event from failing an otherwise-healthy deploy. 10-second timeout is defensible (longer and the user's feedback loop degrades; shorter and flaky networks trigger false FAILs).

## Halt Protocol

Any hard-fail during Steps 1 through 8 emits `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` per [deploy-report-schema.md](deploy-report-schema.md) Section 6 and stops. No retry, no partial-write commits, no DEPLOY-REPORT.md.

Halt triggers and matching `halt_reason` enum values:

- `template-load-failure` (Step 4: template file missing, unreadable, or substitution fails)
- `yaml-parse-error` (Step 1: agent-profiles.yaml or integration-manifest.yaml invalid)
- `disk-full` (Step 5 or 6: write operation fails due to storage exhaustion)
- `permission-denied` (Step 5 or 6: write operation fails due to filesystem permissions)
- `verification-failed` (Step 8: `verification_status: FAILED` rollup)
- `user-rejected-diff` (Step 3: user declines to approve a proposed change)

DEPLOY-FAILED-REPORT.md carries frontmatter with `schema_version`, `deployment_id`, `halted_at`, `halt_reason`, `halt_step`, `team_name`, and a body with `## Failure Details` (concrete evidence: which file, which field, which step, what went wrong), `## Partial State` (list of files that WERE written before halt; may need manual rollback), and `## Resumption Advice` (what user should fix before re-running). Update `registry.yaml` `last_deploy_id` + `deployed_at` to reference the failed deployment (so Phase 6 Evolution sees the timestamp but not a green status). Halt the Phase 5 gate.

Surface to the user: "Deploy halted at step `<halt_step>`: `<halt_reason>`. See `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` for details. Fix: `<recommended fix>`. Say `retry deploy` to re-attempt after the fix."

**Rationale (D-70):** Pattern carry-forward from Phase 11 DISCOVERY-BLOCKED-REPORT.md. Halt-and-name with a specific artifact gives the user a paper trail they can share; atomic all-or-nothing prevents the "half-deployed team that confuses Phase 13" foot-gun.

## Quick Reference

- **Step 1 (input validation):** trigger = profiles + manifest loaded; halt = `yaml-parse-error`; delegate = [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) anchor allow-list.
- **Step 2 (fingerprint compare):** trigger = every planned artifact; halt = never (fingerprint is read-only); delegate = D-60 (SHA256 + timestamp masking + RFC 8785 for JSON).
- **Step 3 (diff presentation):** trigger = one or more hashes differ; halt = `user-rejected-diff`; delegate = D-61 unified-diff format.
- **Step 4 (template render):** trigger = every validated agent; halt = `template-load-failure`; delegate = [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) + three autonomy templates.
- **Step 5 (atomic write):** trigger = rendered bodies from Step 4; halt = `disk-full` or `permission-denied`; delegate = [agent-memory-schema.md](agent-memory-schema.md) for memory scaffolds.
- **Step 6 (registry update):** trigger = all writes succeeded; halt = `disk-full` or `permission-denied`; delegate = D-63 registry schema.
- **Step 7 (.mcp.json merge):** trigger = validated manifest; halt = never (conflict keeps existing by default); delegate = D-66 merge rules.
- **Step 8 (post-deploy verification):** trigger = all artifacts landed; halt = `verification-failed`; delegate = [deploy-report-schema.md](deploy-report-schema.md) + D-69 canonical `tools/list`.
- **Halt terminal artifact:** `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` per D-70.
- **Success terminal artifact:** `.agentbloc/deploy/DEPLOY-REPORT.md` per D-68 + appended line in `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` per D-71.

## Cross-References

- [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) , Step 4 anchor-point contract: frozen allow-list of 13 substitution variables; bounded enums for `autonomy_level`, `model`, `blast_radius`; credential-bearing-fields exclusion; validation checklist.
- [agent-memory-schema.md](agent-memory-schema.md) , Step 5 three-file contract for `.agentbloc/agents/<agent-id>/`: `memory.md` template + `state.json` schema + `last-run.json` schema; RFC 8785 canonicalization rules; runtime read / write semantics for Phase 13.
- [deploy-report-schema.md](deploy-report-schema.md) , Step 8 dual-artifact contract: DEPLOY-REPORT.md frontmatter + 5 body sections for the happy path; DEPLOY-FAILED-REPORT.md schema for halt-and-name per D-70; fingerprint protocol citing D-60.
- [prompt-injection.md](prompt-injection.md) , v1.0 cross-cutting defense reference cited by every generated SKILL.md so deployed agents ingest the prompt-injection posture.
- [browser-stack.md](browser-stack.md) , consulted if Phase 11 Posture B Patchright was used during discovery and produced `[DISCOVERED]`-tier entries feeding into this deploy.
- [integration-manifest-schema.md](integration-manifest-schema.md) , Phase 10 input contract consumed by Step 1 validation and Step 7 `.mcp.json` merge.
- [agent-profile-schema.md](agent-profile-schema.md) , Phase 9 input contract consumed by Step 1 validation and Step 4 template render.
