# Deployed Agent SKILL.md Schema

> The frozen template anchor-point contract for the Jinja-lite templates at .claude/skills/agentbloc/templates/deployed-agent-skill-<autonomy>.md.tmpl. Phase 12 Step 4 substitutes these anchors verbatim; no new anchors may be added without a schema_version bump.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Schema Definition](#schema-definition)
- [Field Obligation Matrix](#field-obligation-matrix)
- [Bounded Enum: autonomy_level](#bounded-enum-autonomy_level)
- [Bounded Enum: model](#bounded-enum-model)
- [Bounded Enum: blast_radius](#bounded-enum-blast_radius)
- [Credential-Bearing Fields Exclusion (Threat Model)](#credential-bearing-fields-exclusion-threat-model)
- [Validation Checklist](#validation-checklist)
- [Emission Protocol](#emission-protocol)
- [Re-run Behavior and Schema Versioning](#re-run-behavior-and-schema-versioning)

## When This Applies

The deploy-engine subagent (`.claude/agents/deploy-engine.md`, Plan 12-02) loads this file in its forked context on invocation, NOT at Phase 5 entry (per D-58 context-budget discipline). This file defines the frozen allow-list of substitution variables that the three per-autonomy-level templates (`deployed-agent-skill-full.md.tmpl`, `deployed-agent-skill-semi.md.tmpl`, `deployed-agent-skill-supervised.md.tmpl`) may reference. Template authors may NOT introduce new `{{...}}` anchors without bumping `schema_version`. Downstream consumer: [deploy-protocol.md](deploy-protocol.md) Step 4 template render; Phase 13 Runtime reads the generated SKILL.md files; Phase 14 Monitor parses the `autonomy` marker comment; Phase 16 End-to-End Validation replays against the Arco Rooms fixture.

**Plan 12-01 triple literal override notice (PHASE 12 TRIPLE LITERAL OVERRIDE):** Deployed SKILL.md files ship at `.claude/skills/<agent-id>/SKILL.md` per D-59a (Claude Code native skill discovery path), which overrides the REQUIREMENTS.md DEPLOY-01 literal `skills/<agent-id>/SKILL.md`. Per-agent memory files ship at `.agentbloc/agents/<agent-id>/` per D-59b (MEM-01 override). Registry at `.agentbloc/agents/registry.yaml` per D-59c (DEPLOY-05 override). The unifying architectural principle is the stable-vs-mutable split: SKILL.md contracts (this schema's output) are versioned, reviewed, audited; memory files are machine-written on every wake.

This file is declarative (anchor-point allow-list + bounded enums consulted in Step 4); [deploy-protocol.md](deploy-protocol.md) is imperative (step-by-step flow the subagent walks); the three templates are the substrate over which substitution runs.

## Schema Definition

The 13 anchor points below are the ONLY `{{...}}` variables the templates may reference. Any other `{{...}}` pattern in a template file is a schema violation caught by Validation Checklist Check 3.

```
{{agent.id}}                  # slug, matches .claude/skills/<agent-id>/ directory
{{agent.role}}                # human-readable role title
{{agent.goal}}                # 1-2 sentence goal statement
{{agent.backstory}}           # 3-5 sentence context
{{agent.tools}}               # PRE-COMPUTED bullet list (deploy-engine renders from integration-manifest.yaml BEFORE substitution)
{{agent.autonomy_language}}   # pre-computed autonomy-variant prose (one of three per autonomy_level)
{{agent.escalation}}          # escalation protocol prose
{{agent.dependencies}}        # dependency-on-other-agents prose (from agent-profiles.yaml)
{{agent.blast_radius}}        # integer 1-4 + semantic label
{{agent.model}}               # opus | sonnet | haiku
{{agent.memory_refs}}         # literal block pointing at .agentbloc/agents/<agent-id>/{memory,state,last-run} + v1.0 SECR-05 kill-switch pre-check prose
{{team.name}}                 # team slug from agent-profiles.yaml
{{team.briefing_agent_id}}    # agent-id of briefing-agent (null if Phase 15 anticipation not yet run)
```

Pre-computation rules for the two composite anchors:

- **`{{agent.tools}}`** is rendered by the deploy-engine BEFORE substitution. The engine reads `integration-manifest.yaml`, filters by the agent's `tools[]` list, and emits one bullet line per tool in the format `- mcp__<server>__<method>` (matching Claude Code MCP tool-naming convention). The template sees an already-rendered string; it does NOT contain a `{% for tool in agent.tools %}` loop.
- **`{{agent.autonomy_language}}`** is rendered by the deploy-engine from a fixed 3-way lookup: `full` => "full autonomy, no prompt required"; `semi` => "semi-autonomous, confirm before side-effects"; `supervised` => "supervised, propose and wait for approval". The template sees the already-selected prose string; it does NOT contain a `{% if autonomy == "full" %}` conditional.

Path literals used by `{{agent.memory_refs}}`: the rendered block cites `.agentbloc/agents/<agent-id>/memory.md`, `.agentbloc/agents/<agent-id>/state.json`, `.agentbloc/agents/<agent-id>/last-run.json` (D-59b), plus a 3-line kill-switch pre-check prose citing `.agentbloc/KILL_SWITCH` per v1.0 SECR-05.

## Field Obligation Matrix

| Tier | Fields | Behavior if missing |
|---|---|---|
| REQUIRED | `agent.id`, `agent.role`, `agent.goal`, `agent.tools`, `agent.autonomy_language`, `agent.memory_refs` | Deploy-engine refuses to render. Halt with `halt_reason: yaml-parse-error` naming the missing field. |
| RECOMMENDED | `agent.backstory`, `agent.escalation`, `agent.dependencies`, `agent.blast_radius`, `agent.model`, `team.name` | Render with warnings. Phase 12 DEPLOY-REPORT.md surfaces each gap in `## Pending User Actions`. |
| OPTIONAL | `team.briefing_agent_id` | Render with literal `null`. Phase 15 Anticipation fills in the briefing-agent id during its own wave; Phase 12 does not block. |

Downstream consumers (Phase 13 Runtime, Phase 14 Monitor, Phase 16 Validation) refuse to proceed on an unknown major `schema_version`, matching the rule in [agent-profile-schema.md](agent-profile-schema.md) and [integration-manifest-schema.md](integration-manifest-schema.md).

## Bounded Enum: autonomy_level

The `autonomy_level` field on each agent in `agent-profiles.yaml` selects which of the three template files the deploy-engine loads in Step 4. Exactly one of three values: `full | semi | supervised`.

| Enum Value | Template File | Pre-Computed `autonomy_language` Prose |
|---|---|---|
| `full` | `.claude/skills/agentbloc/templates/deployed-agent-skill-full.md.tmpl` | "Full autonomy: this agent acts without prompting. Side-effects are logged to the audit trail but no approval gate blocks them." |
| `semi` | `.claude/skills/agentbloc/templates/deployed-agent-skill-semi.md.tmpl` | "Semi-autonomous: this agent confirms before any external side-effect. Internal state updates proceed without prompting." |
| `supervised` | `.claude/skills/agentbloc/templates/deployed-agent-skill-supervised.md.tmpl` | "Supervised: this agent proposes every action and waits for explicit human approval before any side-effect, internal or external." |

Any `autonomy_level` value outside this enum forces a Step 1 validation halt before template selection.

**Why three separate templates instead of one template with conditionals:** 12-RESEARCH.md topic 3 documented that single-template-with-Jinja-conditional approaches are the exact failure mode for Claude-in-context substitution: escaping rules vary, conditional branches introduce rendering variance, and loop rendering breaks determinism even at temperature=0. The three-template split (D-62) eliminates conditional blocks entirely; the template file is pure `{{var}}` substitution. Phase 16 golden-file tests can assert determinism per autonomy level because the same inputs plus the same template always produce the same output bytes.

## Bounded Enum: model

The `model` field selects the Claude model the deployed agent targets. Exactly one of three values: `opus | sonnet | haiku`. Matches the PROJECT.md STACK guidance (Opus for complex reasoning, Sonnet for standard, Haiku for checks).

| Enum Value | Use Case | Matches PROJECT.md STACK Guidance |
|---|---|---|
| `opus` | Complex reasoning, multi-step planning, conversational editing | Opus for complex reasoning |
| `sonnet` | Standard-throughput tasks, routine automation, most deployed agents | Sonnet for standard |
| `haiku` | Fast checks, validation probes, watchdog agents | Haiku for checks |

OPTIONAL field: if absent, the rendered SKILL.md omits the `model` field in the frontmatter and the Phase 13 runtime uses the project default.

## Bounded Enum: blast_radius

The `blast_radius` field is an integer in the inclusive range `1 | 2 | 3 | 4`. Matches the Phase 8 blast-radius taxonomy at [blast-radius.md](blast-radius.md).

| Enum Value | Semantic Label | Definition | Autonomy Compatibility |
|---|---|---|---|
| `1` | read-only | Agent only reads data; no writes to any namespace | `full` acceptable |
| `2` | write-scoped | Agent writes only to its own `.agentbloc/agents/<id>/` namespace | `full` or `semi` acceptable |
| `3` | write-unrestricted | Agent writes to other files or databases in the project | `semi` or `supervised` recommended |
| `4` | send-external | Agent sends data outside the project (Telegram, email, HTTP) | `supervised` recommended; `semi` acceptable with escalation |

Any value outside `{1, 2, 3, 4}` forces a Step 1 validation halt.

## Credential-Bearing Fields Exclusion (Threat Model)

**No anchor point may resolve to an env-var value or raw credential.** This is a threat-model rule, not a preference. Env-var references live in `.mcp.json` and are loaded at runtime by the MCP server process; the SKILL.md file must only reference them by name.

**Prohibited anchor points (never add to the allow-list):**

- `{{agent.api_key}}`
- `{{agent.secret}}`
- `{{agent.password}}`
- `{{agent.token}}`
- `{{agent.oauth_token}}`
- `{{agent.client_secret}}`
- Any anchor whose name or value-at-render matches the regex `(api_key|secret|password|token|credential|bearer)`

**Correct pattern:** the rendered SKILL.md may reference credentials BY NAME only, e.g., "this agent uses the `TELEGRAM_BOT_TOKEN` env var as documented in `.env.example`" or "authentication via the `GOOGLE_OAUTH_TOKEN` scope defined in the google-workspace-mcp MCP entry in `.mcp.json`". The actual secret value never reaches the rendered output.

**Rationale:** SKILL.md files are committed to git in the target project (they are the stable contract per D-59a). Any credential value baked into SKILL.md at render time would be exfiltrated on push. The `.env` file is gitignored; `.env.example` documents the required variable names without values. MCP servers resolve the names at runtime in their own process, never inside Claude's context.

Validation Checklist Check 3 enforces this exclusion. Any template that references a prohibited anchor or that resolves to a string matching the forbidden regex is rejected before write.

## Validation Checklist

The deploy-engine walks this ordered list after rendering each agent's SKILL.md in Step 4 and BEFORE writing to disk in Step 5. Any FAIL blocks the write; halt with the specific check number named in DEPLOY-FAILED-REPORT.md.

1. All REQUIRED fields populated (matrix above). FAIL: halt with the specific agent-id + field name.
2. `autonomy_level` on the source `agent-profiles.yaml` record matches one of `full | semi | supervised`. FAIL: halt with `halt_reason: yaml-parse-error` naming the invalid value.
3. No anchor point references env-var values or raw credentials. Grep the rendered output for `api_key`, `secret`, `password`, `token=`, `bearer `, `client_secret` (case-insensitive); matches must be zero. FAIL: halt with `halt_reason: yaml-parse-error` citing the offending line.
4. `blast_radius` value is in `{1, 2, 3, 4}`. FAIL: halt with the invalid value named.
5. `model` value is in `{opus, sonnet, haiku}` OR is absent. FAIL: halt with the invalid value named.
6. `agent.id` matches the parent directory slug at `.claude/skills/<agent-id>/`. FAIL: halt; the registry Step 6 would otherwise write a stale pointer.
7. `agent.memory_refs` literal block cites all three files (memory.md + state.json + last-run.json) AND cites the `.agentbloc/KILL_SWITCH` kill-switch pre-check per v1.0 SECR-05. FAIL: halt; the deployed agent would otherwise skip the kill-switch check on wake.
8. `agent.tools` bullet list was pre-computed. Grep the rendered output for Jinja loop syntax (`{% for `, `{% endfor %}`, `{% if `, `{% else %}`, `{% endif %}`); matches must be zero. FAIL: halt; conditional / loop syntax leaked past pre-computation.
9. The `<!-- agentbloc:template autonomy=<level> schema_version=1 -->` marker comment is present and the `<level>` matches the agent's `autonomy_level`. FAIL: halt; a wrong template file was loaded in Step 4.

## Emission Protocol

Emission happens during Step 4 of [deploy-protocol.md](deploy-protocol.md). The deploy-engine walks:

1. Read the agent record from `agent-profiles.yaml`.
2. Pick the template file based on `agent.autonomy_level` (router-picks-by-autonomy-field per D-62).
3. Pre-compute `{{agent.tools}}` by reading `integration-manifest.yaml` and filtering by the agent's `tools[]` list.
4. Pre-compute `{{agent.autonomy_language}}` from the 3-way lookup in the `autonomy_level` enum table above.
5. Substitute all 13 anchor points into the template.
6. Walk the Validation Checklist above.
7. On all PASS: append the fingerprint HTML comment `<!-- agentbloc:fingerprint sha256=<64-hex> generated_at=<ISO-8601> -->` per D-60 (timestamp masked to `<TIMESTAMP>` before hashing).
8. Write atomically to `.claude/skills/<agent-id>/SKILL.md` per D-59a.

Per D-61, if a prior SKILL.md exists for this agent and the fingerprint differs, the deploy-engine pauses for user approval of the unified diff (via Step 3 of [deploy-protocol.md](deploy-protocol.md)) before overwriting.

## Re-run Behavior and Schema Versioning

The `schema_version` field on `agent-profiles.yaml` currently equals `1`. Any breaking change to this anchor-point allow-list requires a coordinated update across all three autonomy-level template files plus a bump of `schema_version`.

**Breaking changes (bump `schema_version`):**

- Removing or renaming an anchor point (e.g., removing `{{agent.backstory}}`).
- Removing a value from a bounded enum (e.g., dropping `haiku` from `model`).
- Tightening a RECOMMENDED field to REQUIRED.

**Additive changes (do NOT bump):**

- Adding a new OPTIONAL anchor point (e.g., `{{agent.custom_prompt_suffix}}`).
- Adding a new value to a bounded enum (e.g., a future `opus-plus` model hint).
- Loosening a REQUIRED field to RECOMMENDED.

**Re-run compare:** On re-deploy, the deploy-engine reads the existing `.claude/skills/<agent-id>/SKILL.md`, strips the fingerprint block, canonicalizes (timestamp masking per D-60; RFC 8785 not applicable to markdown), and computes SHA256. Matching hash = skip (no re-write). Differing hash = present unified diff via Step 3 of [deploy-protocol.md](deploy-protocol.md) and wait for user approval before overwriting.

Downstream consumers (Phase 13 Runtime, Phase 14 Monitor, Phase 15 Anticipation, Phase 16 Validation) read `schema_version` from the frontmatter marker and refuse to proceed on an unknown major version. This matches the rule in [agent-profile-schema.md](agent-profile-schema.md), [integration-manifest-schema.md](integration-manifest-schema.md), and [discovery-report-schema.md](discovery-report-schema.md).

**Coordinated update discipline:** When `schema_version` bumps from 1 to 2, the deploy-engine refuses to proceed until all three template files and this schema file have been updated together and committed in the same changeset. A single-file bump that drifts the templates out of sync with the allow-list is a schema violation caught by Validation Checklist Check 8 (loop / conditional syntax detection) or Check 9 (autonomy marker mismatch). Phase 16 golden-file tests catch drift at CI time by regenerating the Arco Rooms fixture and diffing against the checked-in version.

**Fingerprint emission contract:** The HTML-comment fingerprint line appended at Step 7 of the Emission Protocol follows this exact format: `<!-- agentbloc:fingerprint sha256=<64-hex> generated_at=<ISO-8601> -->`. Deploy-engine strips this line before re-hashing on re-deploy to avoid the recursive-hash trap (the previous fingerprint would otherwise become part of the content being hashed). The `generated_at` value is purely informational and is masked to the literal placeholder `<TIMESTAMP>` during canonicalization per D-60.

**Interaction with kill-switch pre-check (v1.0 SECR-05 inheritance):** Every rendered SKILL.md carries the kill-switch pre-check prose inside the `{{agent.memory_refs}}` block. The pre-check cites `.agentbloc/KILL_SWITCH` (a sentinel file the operator creates to halt all deployed agents) and instructs the deployed agent to skip execution on wake if the file exists. Phase 12 does NOT implement runtime kill-switch reading (Phase 13 RUNTIME-07 does), but every generated SKILL.md MUST include the pre-check prose as a Mandatory Initial Read step. Validation Checklist Check 7 enforces this.

## Cross-References

- [deploy-protocol.md](deploy-protocol.md) , Step 4 caller that walks this schema end-to-end
- [agent-memory-schema.md](agent-memory-schema.md) , sibling contract for the three per-agent runtime files (memory.md + state.json + last-run.json) that `{{agent.memory_refs}}` points at
- [deploy-report-schema.md](deploy-report-schema.md) , emission contract for DEPLOY-REPORT.md + DEPLOY-FAILED-REPORT.md (the latter is the halt target when any of the 9 validation checks fail)
- [agent-profile-schema.md](agent-profile-schema.md) , upstream Phase 9 contract whose field set is the source for the 13 anchor points in this allow-list
- [integration-manifest-schema.md](integration-manifest-schema.md) , upstream Phase 10 contract consumed by the `{{agent.tools}}` pre-computation step
- [prompt-injection.md](prompt-injection.md) , v1.0 cross-cutting defense cited by every rendered SKILL.md in the autonomy-language block
- [blast-radius.md](blast-radius.md) , v1.0 taxonomy that the `blast_radius` bounded enum inherits
