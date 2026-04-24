# Phase 12: Deploy Pipeline + Agent Memory System - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning
**Decision mode:** Autonomous (per `autonomous_mode` memo , Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + prior phases)
**Depends on:** Phase 8 (Business Graph), Phase 9 (agent-profiles.yaml), Phase 10 (integration-manifest.yaml), Phase 11 (DISCOVERY-REPORT.md browser-fallback entries)

<domain>
## Problem Statement

Materialize an approved `.agentbloc/team/agent-profiles.yaml` (Phase 9 output) plus its verified `.agentbloc/integrations/integration-manifest.yaml` (Phase 10) plus any `.agentbloc/discovery/<service>/DISCOVERY-REPORT.md` browser-fallback entries (Phase 11) into a running ClaudeClaw-compatible deployment: a skill per agent, ClaudeClaw job configs per trigger, `.mcp.json` merges, per-agent memory directories, a team registry, a deploy report, and a post-deploy verification pass. Re-runs are idempotent; differences present a diff for user approval before overwrite; failures halt cleanly with a named report. Phase 12 produces the artifacts that Phase 13 (Multi-Agent Runtime) wakes and Phase 14 (Monitor / Control Plane) observes.

Phase 12 closes the Design-to-Deploy loop that Phases 8-11 set up. Everything before this was specification; this is the first phase that emits concrete runtime artifacts a user can point ClaudeClaw at.

**In scope:**
- `.claude/skills/agentbloc/references/deploy-protocol.md` (new) , imperative 7-step deploy flow (load manifests, resolve idempotency fingerprint, generate SKILL.md per agent from template, merge `.mcp.json`, bootstrap memory directories, write registry, emit DEPLOY-REPORT.md, run post-deploy verification)
- `.claude/skills/agentbloc/references/deployed-agent-skill-schema.md` (new) , contract for the per-agent `SKILL.md` that Phase 12 generates (frontmatter shape, mandatory body sections, autonomy-language injection points, prose-checklist validator per D-13)
- `.claude/skills/agentbloc/references/agent-memory-schema.md` (new) , canonical shape for `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}` (per D-59b) including section-headed memory.md template, flat state.json schema with role-specific `working_state` namespace, and last-run.json log-entry shape. Prose-checklist validator.
- `.claude/skills/agentbloc/references/deploy-report-schema.md` (new) , contract for DEPLOY-REPORT.md (frontmatter with deployment_id + timestamp + idempotent_hash; body sections: created / updated / skipped / pending-actions / verification). Also defines DEPLOY-FAILED-REPORT.md for halt-and-name failures (inherits D-35 pattern).
- `.claude/skills/agentbloc/templates/deployed-agent-skill.md.tmpl` (new) , Jinja-lite template with fixed anchor points consumed by the deploy engine (role / goal / backstory / tools / autonomy language / escalation / memory refs). Template-based generation chosen over LLM-assembled per D-62.
- `.claude/agents/deploy-engine.md` (new) , Claude Code subagent that orchestrates the deploy flow (`context: fork`, scoped tools Read/Grep/Glob/Write + Edit for `.mcp.json` merges + Bash narrowly scoped to running `claude mcp list` / `claude agents list` for post-deploy verification only; NO WebFetch, NO other MCPs)
- `.claude/skills/agentbloc/examples/arco-rooms-deploy-report.md` (new) , canonical DEPLOY-REPORT.md fixture for the 3-agent Arco Rooms team
- `.claude/skills/agentbloc/examples/arco-rooms-registry.yaml` (new) , canonical registry.yaml fixture (MEM-05 / DEPLOY-05 surface for Phase 14 briefing-agent consumption)
- Surgical edits to `.claude/skills/agentbloc/references/phase-5-deployment.md` (v1.0) , promote ClaudeClaw path to Priority 1, delegate detailed flow to `deploy-protocol.md` via See-line; preserve v1.0 summary block for backward compatibility
- Surgical edits to `.claude/skills/agentbloc/SKILL.md` , Phase 5 entry adds unconditional-load See-lines (`deploy-protocol.md` + `deployed-agent-skill-schema.md` + `agent-memory-schema.md` + `deploy-report-schema.md`); Phase 5 Summary Gate wires the deploy-engine subagent; new sub-gate `deployment_artifacts_emitted` joins the State Transitions paragraph; Phase 6 Evolution precondition verifies DEPLOY-REPORT.md exists with `verification_status: PASSED`

**Out of scope (belongs to later phases):**
- Cron trigger wakes + actual `claude -p` invocation → Phase 13 (RUNTIME-01..07)
- n8n webhook route configuration (Phase 12 emits stub webhook URLs; Phase 13 wires n8n) → Phase 13 (RUNTIME-02, RUNTIME-03)
- `TeamCreate` / `SendMessage` inter-agent coordination runtime → Phase 13 (RUNTIME-04, RUNTIME-05)
- Correlation-ID plumbing through live agent activations → Phase 13 (RUNTIME-06)
- Kill-switch enforcement at agent wake → Phase 13 (RUNTIME-07, re-validates v1.0 SECR-05)
- JSONL log emission at runtime + briefing-agent daily summaries → Phase 14 (MONITOR-01..06)
- Telegram escalation UX / approval-queue threads → Phase 14 (AUTON-02, CTRL-01)
- Cost tracking + task locking + status badges → Phase 14 (CTRL-02..04)
- Anticipation-pass agents in deploy (Phase 15 extends Designer output; Phase 12 deploys whatever agent-profiles.yaml contains including anticipated agents once Phase 15 ships) → Phase 15 (ANTIC-01..05)
- Cross-run deploy history diff viewer (web dashboard) → v2.5+
- Auto-remediation when post-deploy verification fails → v4.0 Self-Healing Evolution

</domain>

<decisions>
## Implementation Decisions

### Inherited from Phases 8-11 and v1.0 (carry forward , do not re-decide)

- **Inherited D-1 (v1.0 + Phase 8 D-11):** File-based state, JSON for machine-written, YAML for human-authored, Markdown for agent memory. Phase 12 writes `state.json` and `last-run.json` as machine-written JSON; `memory.md` as Markdown; `registry.yaml` as YAML. No database.
- **Inherited D-11 (Phase 8):** Artifact emission lives in a gate, not a separate subagent flow. Deploy emission is the Phase 5 Summary gate output , same pattern as Business Graph / agent-profiles / integration-manifest / DISCOVERY-REPORT.md.
- **Inherited D-13 (Phase 8):** Validators are prose-checklists inside the schema reference file. `deployed-agent-skill-schema.md`, `agent-memory-schema.md`, and `deploy-report-schema.md` all use prose checklists. No `ajv`, no `yamllint`, no external linter as a hard dep.
- **Inherited D-14 (Phase 8):** User confirms a rendered table (deploy summary); the DEPLOY-REPORT.md is written silently at `.agentbloc/deploy/DEPLOY-REPORT.md`. SKILL.md files per agent are written silently; the user reviews the rendered team deployment table, not individual SKILL.md files.
- **Inherited D-15 (Phase 8 + PDF):** Deployment artifacts live under `.agentbloc/` for customer-mutable state. Deploy reports at `.agentbloc/deploy/`. Stable agent contracts (SKILL.md) ship at project root `skills/<agent-id>/SKILL.md` per D-59a (DEPLOY-01 literal honored); mutable per-agent runtime files (memory.md, state.json, last-run.json, registry.yaml) ship at `.agentbloc/agents/<agent-id>/` per D-59b and D-59c (MEM-01 and DEPLOY-05 literals overridden for namespace hygiene; full rationale below).
- **Inherited D-18 (Phase 8):** Bounded enums for discriminated unions. `deploy.status` ∈ `{created, updated, skipped, failed}`; `idempotency_action` ∈ `{create, update-approved, skip-identical, halt-conflict-unapproved}`; `verification_status` ∈ `{PASSED, PARTIAL, FAILED}`; `mcp_merge_action` ∈ `{add-new, keep-existing-conflict-warn, replace-approved}`.
- **Inherited D-21 (Phase 9):** Subagent with `context: fork`, scoped tools, NO Bash by default. Phase 12 narrows this: the deploy-engine subagent needs Bash for the Read-only post-deploy verification probes (`claude mcp list`, `claude agents list`, `crontab -l`) per DEPLOY-08, but NO Bash for writes. See D-68 for the exact Bash allow-list.
- **Inherited D-22 (Phase 9):** Three-tier field obligation (REQUIRED / RECOMMENDED / OPTIONAL) with `schema_version: 1` integer. Applied to all three Phase 12 schemas.
- **Inherited D-29 (Phase 9):** SKILL.md extensions are surgical, budget ≤250 lines total. Phase 12 adds 4 See-lines + 1 new sub-gate bullet + 1 Phase 5 Summary Gate paragraph + 1 Phase 6 precondition paragraph. Target SKILL.md line count after Phase 12: ~200 lines (still 50 lines of headroom under the 250 cap).
- **Inherited D-31 (Phase 10):** Split references per concern: imperative flow vs declarative schema vs output contract. Phase 12 ships four references: protocol (deploy-protocol.md, imperative) + three schemas (deployed-agent-skill-schema.md, agent-memory-schema.md, deploy-report-schema.md).
- **Inherited D-34 (Phase 10):** Three-check verification protocol as prose checklist. Applied as post-deploy verification: (1) every generated SKILL.md loads cleanly via `claude agents list`; (2) every MCP server in `.mcp.json` responds to `tools/list` with ≥1 tool declared via `claude mcp list`; (3) every cron job is registered with ClaudeClaw via `crontab -l` + ClaudeClaw scheduled-tasks list. See D-70.
- **Inherited D-35 (Phase 10):** Halt-and-name with named report on failure. Phase 12 extends: deploy failure → `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` (twin of DISCOVERY-BLOCKED-REPORT.md from Phase 11) with frontmatter citing which step failed + specific error + recommended fix. See D-71.
- **Inherited D-37 (Phase 10):** Approval-gated execution for anything with blast radius. Phase 12 applies this to D-66 diff presentation before overwrite: user must approve the unified diff before deploy-engine mutates existing files. Also applies to D-67 `.mcp.json` conflict-on-key: user approves keep-existing vs replace before the merge lands.
- **Inherited D-39 (Phase 10):** Evidence record + `[UNVERIFIED]` flag carry-forward. DEPLOY-REPORT.md preserves each integration's resolution_method + trust_tier from the integration-manifest; `[DISCOVERED]`-tier entries (Phase 11 browser-fallback) carry their `expires_at` field into the deploy record so downstream re-verification (v1.0 Phase 6 EVOL-02, v4.0 Self-Healing) has the signal.
- **Inherited D-40 (Phase 10):** Surgical edits to existing references. `phase-5-deployment.md` gets a Priority 1 promotion for the ClaudeClaw path + See-line delegation; v1.0 Summary block preserved verbatim.
- **Inherited D-42 (Phase 10 / integration-manifest-schema.md):** Idempotency fingerprint pattern. Phase 12 uses SHA256 over the body excluding timestamp fields , same discipline as the DISCOVERY-REPORT.md `sha256` field (Phase 11 D-45).
- **Inherited D-46 (Phase 11):** Append-only ledger format. Phase 12 uses `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` as the cross-run deploy ledger (one JSON per deploy attempt, append-only, supports GDPR Article 30 record-of-processing for agent-lifecycle events). See D-72.
- **Inherited D-58 (Phase 11):** Context-budget discipline for Phase-entry loads. Phase 5 currently loads 1 reference (`phase-5-deployment.md`). Phase 12 adds 4 more for an estimated 1,100-line Phase 5 unconditional load. Since this is the first time Phase 5 takes on significant load (was the lightest phase pre-12), there is no context-budget conflict. The deploy-engine subagent loads the template + agent-memory schema in its forked context so the main session doesn't double-load them.
- **Inherited v1.0 SECR-05:** Kill-switch pattern. Phase 12 does NOT implement the runtime kill-switch check (Phase 13 RUNTIME-07 does), but every generated SKILL.md MUST include the kill-switch pre-check prose as a Mandatory Initial Read step. See D-65.
- **Inherited v1.0 Phase 4 Dry Run:** DEPLOY-08 post-deploy verification inherits the v1.0 dry-run posture , every artifact must load cleanly before the deployment is marked `verification_status: PASSED`. See D-70.
- **Inherited v1.0 Phase 6 Evolution EVOL-02:** Weekly capability + vulnerability scan applies to every deployed team. Phase 12 does not extend the cadence; it records the `deployed_at` timestamp in the registry so Phase 6 Evolution knows the team's age.

### New decisions (autonomous, per PDF + REQUIREMENTS + prior phases)

#### Output directory convention (resolves DEPLOY-01 literal, MEM-01 namespace collision, DEPLOY-05 co-location)

**Architectural summary.** REQUIREMENTS.md has an internal inconsistency that cannot be honored verbatim without structural cost: DEPLOY-01 writes `skills/{agent-id}/SKILL.md` (project root), MEM-01 writes `.claude/agents/{agent-id}/{memory.md, state.json, last-run.json}`, DEPLOY-05 writes `.claude/agents/registry.yaml`. Three independent tensions: (a) `skills/` at root vs `.claude/agents/` would create two directories per deployed agent; (b) putting customer-deployed-agent files inside `.claude/agents/` collides with Claude Code's RESERVED namespace for native subagent definitions (designer-agent.md, browser-discovery.md, deploy-engine.md); (c) the separation of stable contracts (SKILL.md, versioned, audited) from mutable state (state.json rewritten on every wake) is a core AI-agent-system invariant that a mono-directory structure violates. Phase 12 commits to a split path design with one literal honored and two literal overrides, each justified on architectural grounds.

- **D-59a (SKILL.md at `skills/<agent-id>/SKILL.md`, DEPLOY-01 literal HONORED):** Deployed agent skill files ship at project root `skills/<agent-id>/SKILL.md` verbatim. This is the ClaudeClaw runtime-discovery path (REQUIREMENTS.md mentions ClaudeClaw six times; DEPLOY-08 pings what ClaudeClaw finds). Matching the literal text preserves ClaudeClaw compatibility and keeps the stable contract separate from mutable state.

- **D-59b (Per-agent memory files at `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}`, MEM-01 literal OVERRIDDEN):** Customer-deployed-agent runtime state is moved out of `.claude/agents/` into the project's existing `.agentbloc/` customer-state namespace. `.claude/agents/` is reserved by Claude Code for native subagent definitions (AgentBloc developer-authored subagents); mixing customer runtime with developer tooling is a namespace-hygiene violation. `.agentbloc/discovery/` was established in Phase 11 as the customer-state convention; `.agentbloc/agents/` extends the same pattern. The deploy flow now writes mutable files (state.json rewritten on every wake, memory.md accretes over time, last-run.json rotates per tick) into a directory whose entire purpose is customer mutable state, keeping `.claude/` git history immutable for developer contracts.

- **D-59c (Registry at `.agentbloc/agents/registry.yaml`, DEPLOY-05 literal OVERRIDDEN):** Follows D-59b namespace hygiene. The registry is co-located with the per-agent memory directories it indexes, which makes the `.agentbloc/agents/` directory the single source of truth for "what deployed agents exist + what is their runtime state". DEPLOY-05 said `.claude/agents/registry.yaml`; the override applies the same namespace argument as D-59b.

**Stable-vs-mutable split (the core architectural reason for the double override):**
- `skills/<agent-id>/SKILL.md` holds the immutable-per-deploy contract: prompts, tool lists, autonomy rules, escalation protocol. Version-controlled, code-reviewed, audited. Git history stays clean because content changes only on explicit re-deploy.
- `.agentbloc/agents/<agent-id>/*` holds mutable runtime state: memory.md accretes over time (agent-editable markdown), state.json changes on every wake (machine-written), last-run.json is rewritten per tick (JSON log). Co-locating these with the stable contract would contaminate git history with state churn and block the "is anything different in the deploy?" diff from being meaningful.
- `.claude/` stays UNTOUCHED as Claude Code meta-tooling namespace: AgentBloc skill + three native subagents (designer-agent, browser-discovery, deploy-engine). Phase 16 audit readers see a clean three-namespace separation: developer tooling (`.claude/`), stable deployed contracts (`skills/`), customer mutable state (`.agentbloc/`).

**Alternatives considered:**

| Option | Paths | Verdict |
|---|---|---|
| A. REQUIREMENTS literal both | `skills/<id>/SKILL.md` + `.claude/agents/<id>/{memory,state,last-run}` | Rejected. Two directories per agent; MEM-01 collides with native-subagent namespace; mixing developer tooling with customer runtime. |
| B. Original D-59 override (DEPLOY-01 only) | `.claude/agents/<id>/{SKILL,memory,state,last-run}` | Rejected post-review. Co-locating customer runtime in Claude Code reserved namespace; conflates AgentBloc-native-subagents with customer-deployed-agents into the same directory. Breaks the stable-vs-mutable invariant (SKILL.md gets contaminated by state churn). |
| C. Double override with namespace hygiene | `skills/<id>/SKILL.md` + `.agentbloc/agents/<id>/{memory,state,last-run,registry}` | **Selected (D-59a + D-59b + D-59c).** Honors ClaudeClaw runtime expectation verbatim; respects Claude Code reserved namespace; consistent with Phase 11 `.agentbloc/` precedent; separates stable contract from mutable state; scales to multi-tenant. |
| D. Symlink hybrid | `.claude/agents/<id>/SKILL.md` + `skills/<id>/SKILL.md` symlink | Rejected. Complexity premium not justified; git symlink handling is uneven across platforms; VPS/Docker deploys without git would break. |

**Directory shape per deployed agent (canonical):**
```
skills/                                  # ClaudeClaw-discovered stable contracts (D-59a)
└── <agent-id>/
    └── SKILL.md                         # DEPLOY-01 literal: prompt + role + goal + autonomy + tools + escalation

.agentbloc/                              # customer-state namespace (Phase 11 convention extended)
├── agents/                              # D-59b + D-59c
│   ├── registry.yaml                    # DEPLOY-05 override: team shape + agent roster + reporting hierarchy
│   └── <agent-id>/
│       ├── memory.md                    # MEM-01 override: domain knowledge, agent-editable markdown
│       ├── state.json                   # MEM-03: machine-written working state with schema_version
│       └── last-run.json                # MEM-04: last execution entry with status
├── deploy/
│   ├── DEPLOY_HISTORY.jsonl             # D-64 append-only ledger (cross-run audit)
│   └── DEPLOY-REPORT.md                 # DEPLOY-07 per-run artifact
└── discovery/                           # Phase 11 artifacts (unchanged)

.claude/                                 # UNTOUCHED: Claude Code meta-tooling namespace
├── agents/
│   ├── designer-agent.md                # Phase 9 native subagent (flat .md file, Claude Code convention)
│   ├── browser-discovery.md             # Phase 11 native subagent
│   └── deploy-engine.md                 # Phase 12 native subagent (new)
└── skills/agentbloc/                    # AgentBloc skill itself (unchanged)
```

**Plan-phase responsibility:** Plan 12-01 (contracts) header MUST document both overrides explicitly, citing the stable-vs-mutable split as the architectural principle. Plan 12-02 (deploy-engine) MUST use these paths verbatim in its `<write_constraint>` XML block. Phase 16 audit readers will see "REQUIREMENTS literal says X, code does Y" for MEM-01 and DEPLOY-05 , the D-59b/c justification must be surfaced in both the plan and the eventual DEPLOY-REPORT.md template.

#### Idempotency fingerprint mechanism (resolves REQUIREMENTS.md DEPLOY-06)

- **D-60 (SHA256 over body excluding timestamp fields, matching Phase 11 D-45 pattern):** For every generated artifact (SKILL.md / memory.md / state.json / last-run.json / registry.yaml / `.mcp.json` delta / DEPLOY-REPORT.md), compute SHA256 over the file content with timestamp fields masked to a fixed placeholder `<TIMESTAMP>` before hashing. Alternatives:

  | Option | Description | Selected |
  |---|---|---|
  | mtime compare | Fast but lies across checkout / clone | |
  | git blob hash | Requires git; not all deployments track generated files | |
  | Full file SHA256 | Timestamp noise makes every re-run look like a change | |
  | SHA256 with timestamp masking | Content-aware; re-running with same input does not flag diff | ✓ |

  **Fingerprint schema:** Each generated artifact carries an HTML comment at the bottom `<!-- agentbloc:fingerprint sha256=<64-hex> generated_at=<ISO-8601> -->`. The deploy-engine reads the existing file, masks its `generated_at` token and its own fingerprint comment, hashes, and compares. Same hash = skip. Different hash = present diff + ask for approval.

  **Rationale:** Matches the DISCOVERY-REPORT.md SHA256 discipline (Phase 11 D-45) , same pattern, one shape across the project. Timestamp masking avoids the "every re-run is a diff" trap that plain SHA256 would create. Git-blob-hash is rejected because users deploy without git (VPS, Docker image). Mtime is rejected because clone / rsync / image-bake resets it arbitrarily.

#### Diff presentation (resolves REQUIREMENTS.md DEPLOY-06 second half)

- **D-61 (Unified diff with 5-line context hunks, emitted to DEPLOY-REPORT.md and stdout):** When D-60 detects a change, deploy-engine produces a unified diff (`diff -u` style) with 5 lines of context before / after each hunk. The diff is:
  1. Embedded in DEPLOY-REPORT.md under a collapsed `<details>` block per affected file (standard Markdown collapsible)
  2. Printed to stdout in the conversation so the user can review before approving
  3. Saved separately to `.agentbloc/deploy/pending-diffs/<agent-id>-<artifact>.diff` for audit trail

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | Side-by-side two-column diff | Terminal-hostile; wide output | |
  | Affected-keys-only summary | Loses line-level precision | |
  | Silent overwrite with no approval | Violates D-37 | |
  | Unified diff + 5-line context + DEPLOY-REPORT + stdout + saved .diff file | Precise, reviewable, auditable | ✓ |

  **Rationale:** Unified diff is the standard developer-audit format; 5-line context matches `git diff` defaults for scannable hunks. Saving diffs separately to `.agentbloc/deploy/pending-diffs/` gives the user a pre-commit-hook-style review artifact they can paste into a PR or share with a teammate before approving. Consistent with D-37 approval-gated execution.

#### SKILL.md generation approach (resolves REQUIREMENTS.md DEPLOY-01)

- **D-62 (Template-based generation with fixed anchor points, NOT LLM-assembled):** The deploy-engine reads `agent-profiles.yaml` + the Jinja-lite template at `.claude/skills/agentbloc/templates/deployed-agent-skill.md.tmpl`, substitutes the agent's structured fields into fixed anchor points (`{{agent.role}}`, `{{agent.goal}}`, `{{agent.backstory}}`, etc.), and writes the result. NO LLM step in the inner loop. Alternatives:

  | Option | Description | Selected |
  |---|---|---|
  | LLM-assembled per agent | Creative but non-deterministic; blows cost budget; fails Phase 16 deterministic tests | |
  | Pure Python / TypeScript template engine | Adds dep; fights markdown-only constraint | |
  | Jinja-lite in markdown (Claude reads template + does substitution in-context) | Deterministic, no new dep, Claude can do substitution in-context | ✓ |
  | Hybrid (LLM for backstory prose, template for structure) | Two code paths; fragile | |

  **Rationale:** Phase 9 locked the agent's prompt structure into YAML (role/goal/backstory/tools/autonomy/outputs/escalation/dependencies/blast_radius/model). Those fields ARE the prompt content , no synthesis needed. The template is pure substitution. Claude Code can execute Jinja-lite substitution without a Python runtime: the deploy-engine reads the template and the YAML, then produces the output in-context using string-level replacement. This is deterministic (same inputs → same output), cheap (no LLM-per-agent cost), and testable (Phase 16 golden-file tests trivially validate). LLM assembly is rejected because Phase 16's success criterion 2 ("re-running with same profiles does not duplicate or corrupt artifacts") requires determinism and LLMs introduce token-level variance even at temperature=0.

  **Template anchor points (frozen in `deployed-agent-skill-schema.md`):**
  - `{{agent.id}}`, `{{agent.role}}`, `{{agent.goal}}`, `{{agent.backstory}}`
  - `{{agent.tools}}` (rendered as bullet list with MCP references per integration-manifest.yaml)
  - `{{agent.autonomy_language}}` (conditional block: full = "no prompt required"; semi = "confirm before side-effects"; supervised = "propose and wait")
  - `{{agent.escalation}}`, `{{agent.dependencies}}`, `{{agent.blast_radius}}`, `{{agent.model}}`
  - `{{agent.memory_refs}}` (literal block pointing at `memory.md` + `state.json` + `last-run.json` + v1.0 SECR-05 kill-switch pre-check prose)
  - `{{team.name}}`, `{{team.briefing_agent_id}}` (registry reference)

#### Registry format (resolves REQUIREMENTS.md DEPLOY-05)

- **D-63 (Registry at `.agentbloc/agents/registry.yaml` per D-59c, YAML per prior convention):** team.yaml + agent-profiles.yaml + integration-manifest.yaml are all YAML. REQUIREMENTS.md DEPLOY-05 literal path (`.claude/agents/registry.yaml`) is overridden by D-59c for namespace hygiene; the registry now sits with the per-agent runtime state it indexes. Format stays YAML per prior convention. Schema:

  ```yaml
  schema_version: 1
  team:
    name: "<team-name>"
    lead: "<agent-id>"                  # first agent in a pipeline or the coordinator in a hierarchy
    topology: "<pipeline | mesh | hierarchy | swarm>"
    briefing_agent_id: "<agent-id | null>"  # populated in Phase 15 anticipation if briefing-agent generated
    deployed_at: "<ISO-8601>"
    last_deploy_id: "<uuid-v4>"
  agents:
    - id: "<agent-id>"
      role: "<role>"
      skill_path: "skills/<agent-id>/SKILL.md"
      memory_dir: ".agentbloc/agents/<agent-id>/"
      autonomy: "full | semi | supervised"
      blast_radius: <integer 1-4>
      triggers: [...]                   # denormalized from agent-profiles.yaml for quick registry scan
      dependencies: [...]               # denormalized for topology visualization
  reporting_hierarchy:                  # parent -> children map for Phase 14 MONITOR-05
    "<parent-id>": ["<child-id-1>", "<child-id-2>"]
  dashboard_agent: "<agent-id | null>"  # populated in v2.5 when web dashboard lands
  ```

  **Rationale:** Human-readable (Phase 14 briefing-agent consumes this for daily summaries; user may manually edit to rename a team or add a dashboard-agent), version-controllable, consistent with team.yaml / agent-profiles.yaml / integration-manifest.yaml. JSON would be faster to machine-write but harder to audit; D-1 applies (YAML for human-authored config, JSON for machine-written state).

#### Memory.md structure (resolves REQUIREMENTS.md MEM-02)

- **D-64 (Section-headed markdown template with fixed H2 navigation):** Each deployed agent's `memory.md` is NOT freeform markdown. It follows a fixed 4-section template so the agent can navigate deterministically on every wake:

  ```markdown
  # <agent-id> Memory

  ## Domain Knowledge
  <user-editable facts about the agent's domain: tenants, contracts, account numbers, SOPs, business rules>

  ## Decisions
  <append-only log of significant decisions the agent made: date, context, outcome>

  ## Integration Quirks
  <known weirdnesses: portal A rate-limits to 60/min, provider B rejects requests without User-Agent header, endpoint C returns HTML on error>

  ## Open Items
  <things the agent is tracking but has not resolved: pending invoice X, tenant Y payment delayed, MCP server Z last responded 2 days ago>
  ```

  Phase 12 ships this template as the initial memory.md stub for every agent (empty sections with one-line guidance under each H2). The agent adds to sections at wake; the user edits manually when domain knowledge shifts.

  **Rationale:** Freeform markdown is hostile to agents , they spend tokens hunting for the right section. Section-headed templates let the agent jump to `## Domain Knowledge` on wake without scanning. The 4 sections cover the real-world categories (static knowledge / history / quirks / pending) per the file-based-state pattern documented in `earezki.com` "5-agent system 24/7" post cited in PROJECT.md sources. RECOMMENDED vs REQUIRED: sections are RECOMMENDED (schema warns if missing but still emits). OPTIONAL: an agent can add sections beyond the 4 (e.g., `## Glossary`, `## Escalation History`) , the schema does not forbid additive H2s.

#### state.json schema (resolves REQUIREMENTS.md MEM-03)

- **D-65 (Flat common schema + role-specific fields under `working_state`):** One shape for all agents regardless of role. Role-specific data nests under `working_state` (opaque to the deploy-engine, readable by the agent that owns it). Schema:

  ```json
  {
    "schema_version": 1,
    "agent_id": "<agent-id>",
    "team": "<team-name>",
    "last_wake_at": "<ISO-8601 | null>",
    "last_completion_at": "<ISO-8601 | null>",
    "working_state": {},
    "processed_ids": [],
    "locks": [],
    "retries": [],
    "kill_switch_last_checked": "<ISO-8601 | null>"
  }
  ```

  - `working_state`: free-form object namespaced to the agent's role (Gestor Cobros puts `current_month_payments[]`; Recepcionista puts `last_owner_notifications{}`)
  - `processed_ids`: idempotency set for processed invoices / transactions / messages to prevent double-processing
  - `locks`: task lock entries per CTRL-03 (Phase 14 populates; Phase 12 bootstraps as empty array)
  - `retries`: exponential-backoff state for failed external calls
  - `kill_switch_last_checked`: Phase 13 RUNTIME-07 writes this on every wake; Phase 12 bootstraps as null

  On first deploy, state.json is the shape above with all optional fields null / empty. Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | Per-role schemas (finance-agent.json, reporter-agent.json) | Flexible but explodes type count | |
  | One flat common schema with role-opaque `working_state` | One shape project-wide; agent owns its namespace | ✓ |
  | Free-form JSON, no schema | No idempotency discipline | |

  **Rationale:** One flat schema = one Validation Checklist in `agent-memory-schema.md`. Role diversity lives inside `working_state` where the agent is the authority. `processed_ids[]` lifts the idempotency pattern from v1.0 to a first-class field every agent has , prevents the "double-processed invoice" regression. `locks[]` anticipates Phase 14 CTRL-03 without coupling Phase 12 to it (empty array on first deploy; Phase 14 populates at runtime).

#### .mcp.json merge semantics (resolves REQUIREMENTS.md DEPLOY-03)

- **D-66 (merge-keep-existing-with-conflict-warning; approval-gated overwrite per D-37):** When Phase 12 needs to merge MCP entries from `integration-manifest.yaml` into `.mcp.json`:

  1. If `.mcp.json` does not exist: create it with only the merged entries. No prompt.
  2. If an entry's `tool_id` key is NOT in `.mcp.json`: add it. Log as `mcp_merge_action: add-new`. No prompt.
  3. If an entry's `tool_id` key IS in `.mcp.json` AND the config is byte-identical (SHA256 match per D-60): skip. Log as `mcp_merge_action: skip-identical`.
  4. If an entry's `tool_id` key IS in `.mcp.json` AND the config differs: DO NOT overwrite. Log as `mcp_merge_action: keep-existing-conflict-warn`, emit a warning in DEPLOY-REPORT.md with the diff, and surface to the user: "The `gmail-mcp` entry in `.mcp.json` differs from the integration manifest. Keep existing (safe default) or replace with manifest entry?"
  5. On user `replace` approval: write the new config. Log as `mcp_merge_action: replace-approved`.

  **Rationale:** Non-destructive by default , re-deploying never silently clobbers MCP config the user customized. Conflict warning preserves the audit trail (user sees the diff, makes a choice, the choice is logged). Alternatives:

  | Option | Description | Selected |
  |---|---|---|
  | Always overwrite | Destructive; loses user customizations (e.g., custom env vars on an existing MCP) | |
  | Always skip if key exists | Deploys silently broken configs if manifest updated | |
  | Merge-keep-existing with conflict warning + approval | Safe default + explicit approval for overwrites | ✓ |
  | Three-way merge (manifest + existing + template) | Too clever; Markdown-only constraint rejects | |

#### Deploy-engine subagent tool scope

- **D-67 (Deploy-engine subagent at `.claude/agents/deploy-engine.md`, `context: fork`, narrowed Bash allow-list):** Deploy-engine is the orchestrator. Tool scope:

  - `Read` (agent-profiles.yaml + integration-manifest.yaml + DISCOVERY-REPORT.md + templates + existing skill/memory/state files for fingerprint compare)
  - `Grep` / `Glob` (scan existing `.claude/agents/` for agents not in the current profiles , flag orphans)
  - `Write` (create new SKILL.md / memory.md / state.json / last-run.json / registry.yaml / DEPLOY-REPORT.md / DEPLOY-FAILED-REPORT.md)
  - `Edit` (surgical `.mcp.json` merges per D-66 , Edit used instead of Write to preserve user's other MCP entries byte-for-byte)
  - `Bash` , NARROWED to a 4-command allow-list for post-deploy verification ONLY:
    - `claude mcp list` (DEPLOY-08 check 2: every MCP responds)
    - `claude agents list` (DEPLOY-08 check 1: every SKILL.md loads cleanly)
    - `crontab -l` (DEPLOY-08 check 3: cron jobs registered)
    - `shasum -a 256 <file>` (D-60 fingerprint computation)
  - NO `WebFetch`, NO other MCPs (browser-discovery's tool surface is irrelevant here; deploy is offline), NO unrestricted Bash

  **Rationale:** Deploy-engine is the first AgentBloc subagent that needs Bash , the post-deploy verification is inherently shell-based (ClaudeClaw exposes `claude mcp list` / `claude agents list` as CLI commands). The Bash allow-list is narrow and enforceable (Phase 14 may add CI to assert deploy-engine's Bash calls match the allow-list). Write + Edit are BOTH needed: Write for new artifacts (skill files, memory dirs, registry); Edit for `.mcp.json` surgical merges. Fork context isolates the deploy work from the main interview context. NO other MCPs: deploy-engine doesn't need Playwright / Google Workspace / Telegram , it's pure file-system work.

#### DEPLOY-REPORT.md format

- **D-68 (Frontmatter + 5 body sections, mirror of DISCOVERY-REPORT.md shape):** DEPLOY-REPORT.md at `.agentbloc/deploy/DEPLOY-REPORT.md`. Schema:

  ```yaml
  schema_version: 1
  deployment_id: "<uuid-v4>"
  generated_at: "<ISO-8601>"
  idempotent_hash: "<64-hex over all emitted artifacts together>"
  team: "<team-name>"
  agent_count: <integer>
  integration_count: <integer>
  verification_status: "PASSED | PARTIAL | FAILED"
  sha256: "<64-hex>"
  ```

  Body sections:

  1. **Created** , artifacts newly emitted this run (filepath + sha256 + generation-source-ref)
  2. **Updated** , artifacts whose fingerprint differed and were overwritten with user approval (filepath + old-sha256 + new-sha256 + diff-snippet link to `.agentbloc/deploy/pending-diffs/<name>.diff`)
  3. **Skipped** , artifacts whose fingerprint matched existing (filepath + sha256 + reason: `idempotent-match`)
  4. **Pending User Actions** , credentials missing, ToS opt-in needed for DISCOVERED-tier entries, `.mcp.json` conflicts awaiting user decision, etc. Each entry names the exact file / env var / decision point and the recommended resolution
  5. **Post-Deploy Verification** , table with one row per check (SKILL.md loads / MCP responds / cron registered) + status per row + overall verification_status

  **Rationale:** Frontmatter gives the file a machine-queryable deployment identity; body gives the user a scannable audit trail. Matches DISCOVERY-REPORT.md shape (Phase 11 D-45) so users / downstream agents see the same contract across the project.

#### Post-deploy verification

- **D-69 (3-check verification via narrow Bash allow-list, soft-fail for optional integrations):** Post-deploy verification runs at the end of every deploy. Three checks:

  1. **SKILL.md loads cleanly:** `claude agents list` is invoked; deploy-engine parses the output; every generated agent-id must appear. Missing = FAIL. Each present entry logs `verification_status: PASS` in the report row.
  2. **MCP servers respond:** `claude mcp list` is invoked with a 10-second per-server timeout. Every `integration-manifest.yaml` entry with `status: verified` must appear and respond. Optional integrations (those with `used_by: []` or marked `optional: true` in the manifest) soft-fail: FAIL is logged, overall verification may still pass as PARTIAL.
  3. **Cron jobs registered:** `crontab -l` is invoked; every Phase 13-bound cron entry the deploy-engine wrote to the user's crontab must be present. Missing = FAIL. (Phase 13 actually emits the crontab entries; Phase 12 verifies they're there after Phase 13 runs. In Phase 12-only execution before Phase 13 lands, cron check is soft-failed with note "Phase 13 not yet executed; cron verification skipped.")

  **`verification_status` rollup:**

  | Rollup | Condition |
  |---|---|
  | PASSED | All three checks pass; zero FAIL rows |
  | PARTIAL | Check 1 (SKILL.md) passes; Check 2 or Check 3 has soft-fail but no hard-fail |
  | FAILED | Check 1 (SKILL.md) fails, OR Check 2 has hard-fail on a required integration |

  On FAILED: emit DEPLOY-FAILED-REPORT.md per D-71. On PARTIAL: proceed with DEPLOY-REPORT.md but surface a warning table. On PASSED: gate advances.

  **Rationale:** INTEG-04 / INTEG-05 / DEPLOY-08 all insist on "verify before live." The three checks cover the three failure modes a deployed team could hit at first wake (missing agent def, missing integration, missing trigger). Soft-fail for optional MCPs prevents a "Mapfre is down today" event from failing an otherwise-healthy deploy. 10-second timeout is defensible (longer and the user's feedback loop degrades; shorter and flaky networks trigger false FAILs).

#### Halt-and-name for deploy failures

- **D-70 (DEPLOY-FAILED-REPORT.md, twin of DISCOVERY-BLOCKED-REPORT.md):** On any hard-fail (D-69 verification_status: FAILED, or a non-verification step like template load failure / YAML parse error / disk full / permission denied):

  1. Write `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` with:
     - Frontmatter: `deployment_id` + `generated_at` + `failed_step` ∈ `{load-profiles, load-manifests, fingerprint-compare, generate-skill-md, merge-mcp-json, bootstrap-memory, write-registry, post-deploy-verification, other}` + `error_excerpt`
     - Body: what step failed, exact error quoted, recommended fix, related file paths
  2. DO NOT write a partial DEPLOY-REPORT.md (all-or-nothing: either a PASSED / PARTIAL DEPLOY-REPORT.md or a FAILED DEPLOY-FAILED-REPORT.md)
  3. Update registry.yaml `last_deploy_id` and `deployed_at` to reference this failed deployment (so Phase 6 Evolution sees the timestamp but not a green status)
  4. Halt the Phase 5 gate (state bar moves to `blocked`)
  5. Surface to the user: "Deploy halted at step `<failed_step>`. See `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` for details. Fix: `<recommended fix>`. Say `retry deploy` to re-attempt after the fix."

  **Rationale:** Pattern carry-forward from Phase 11 DISCOVERY-BLOCKED-REPORT.md (D-35 / Phase 11 extension). Halt-and-name with a specific artifact gives the user a paper trail they can share; atomic all-or-nothing prevents the "half-deployed team that confuses Phase 13" foot-gun.

#### Cross-run deploy history

- **D-71 (`.agentbloc/deploy/DEPLOY_HISTORY.jsonl`, append-only):** Every deploy attempt (PASSED / PARTIAL / FAILED) appends one JSON line:

  ```json
  {
    "deployment_id": "<uuid-v4>",
    "attempted_at": "<ISO-8601>",
    "completed_at": "<ISO-8601 | null>",
    "verification_status": "PASSED | PARTIAL | FAILED",
    "agent_count": <integer>,
    "integration_count": <integer>,
    "idempotent_hash": "<64-hex>",
    "report_path": ".agentbloc/deploy/DEPLOY-REPORT.md | .agentbloc/deploy/DEPLOY-FAILED-REPORT.md",
    "failed_step": "<enum | null>"
  }
  ```

  **Rationale:** Matches OPT_IN_LEDGER.jsonl pattern (Phase 11 D-46) , append-only audit trail. Supports GDPR Article 30 record-of-processing for agent-lifecycle events (required for regulated deployments). Enables Phase 6 Evolution (v1.0 EVOL-02 weekly scan) to look at deploy frequency / failure rate / time-between-deploys without crawling the `DEPLOY-REPORT.md` files individually.

#### Cron config

- **D-72 (System cron + `claude -p` invocation, per PROJECT.md constraint and v1.0 D-42 inheritance):** Phase 12 emits cron entries TARGETING system cron (not Claude Code Scheduled Tasks which are Desktop-only and 7-day-expiring per PROJECT.md). Phase 12 does NOT actually write to `crontab` , that's Phase 13's work. Phase 12 writes a FILE at `.agentbloc/deploy/crontab.proposed` with the proposed entries and the user runs `crontab .agentbloc/deploy/crontab.proposed` (or merges into their existing crontab) in their own shell. Matches D-37 approval-gated install pattern from Phase 10.

  Proposed crontab entry format:
  ```
  # agentbloc:<team-name>:<agent-id>:<trigger-index> (deployment_id=<uuid>)
  0 22 * * * cd /path/to/project && claude -p --agent gestor-documental
  ```

  **Rationale:** System cron is the only reliable option per PROJECT.md (Claude Code Scheduled Tasks expire in 7 days on Desktop; AgentBloc targets VPS / Linux primarily). Phase 12 staying out of the actual crontab write respects the v1.0 security posture (Claude does not mutate the user's system state), matches Phase 10 D-37 (declarative writes to user-approved files, user runs the effecting command). The `.agentbloc/deploy/crontab.proposed` file is additive to `DEPLOY-REPORT.md`'s "Pending User Actions" section (user sees "Run `crontab .agentbloc/deploy/crontab.proposed`" as an action item).

#### n8n webhook integration (deferred to Phase 13; Phase 12 emits stubs)

- **D-73 (Emit n8n webhook URL placeholder stubs, don't couple AgentBloc to a specific n8n instance):** For every `trigger: event` in agent-profiles.yaml, Phase 12 emits a webhook-subscription stub in the agent's generated SKILL.md and in the registry:

  ```
  trigger:
    type: event
    source: n8n
    webhook_url: "{{N8N_BASE_URL}}/webhook/<team-name>/<agent-id>"
  ```

  The `{{N8N_BASE_URL}}` env var is recorded in `.env.example` auto-append per inherited D-38 (Phase 10). DEPLOY-REPORT.md "Pending User Actions" section lists "Set N8N_BASE_URL in .env and configure n8n routes for: `<team>/<agent-id-1>`, `<team>/<agent-id-2>`, ..." with one row per event-triggered agent.

  **Rationale:** PROJECT.md says n8n is already deployed on Pablo's infra , but AgentBloc ships to users who may have their own n8n (or none). Hardcoding a base URL couples AgentBloc to one deployment. Placeholder env var + per-deployment config keeps flexibility. Phase 13 wires the actual n8n routes (RUNTIME-03); Phase 12 emits the contract surface.

### Claude's Discretion

- Exact Jinja-lite substitution syntax in the template (`{{agent.field}}` vs `{$agent.field$}` vs `<agent-field/>`) , lean `{{agent.field}}` because it's the most-widely-recognized template syntax and Phase 16 tests can assert it unambiguously
- Whether DEPLOY-REPORT.md's "Created" section uses a table or a bulleted list (lean: table for scanability, matches Phase 11 DISCOVERY-REPORT.md endpoints table)
- Exact wording of the autonomy-language block in the template (`full` agents get different prose than `supervised` , ship a default, iterate from dogfood)
- Whether to emit a `team-topology.md` Mermaid diagram alongside registry.yaml (Phase 9's Designer can emit one; Phase 12 could mirror it into the deploy output , lean: yes if `team-topology.md` exists in `.agentbloc/team/`, copy to `.agentbloc/deploy/` for deployment-time reference; skip if absent)
- The exact 10-second per-MCP timeout in D-69 check 2 , adjustable based on real-world latency observations; ship 10s as default
- Whether to version-tag the registry (`git tag agentbloc-deploy-<deployment_id>`) as a deploy sentinel , nice-to-have, defer to post-dogfood observation
- Exact format for the "kill-switch pre-check prose" injected into every generated SKILL.md , ship a 3-line block that cites `.agentbloc/KILL_SWITCH` per v1.0 SECR-05; Phase 13 may refine

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope Authority
- `.planning/v2.0-PROMPT.pdf` , v2.0 ground truth; Phase 12 materializes the PDF's Deploy Pipeline flow from page 3-4 (`skills/<agent-id>/SKILL.md` + ClaudeClaw job configs + `.mcp.json` merge + per-agent memory dir)
- `.planning/REQUIREMENTS.md` § Deploy Pipeline (DEPLOY-01..08) + § Agent Memory System (MEM-01..06) , 14 requirements this phase satisfies
- `.planning/ROADMAP.md` § Phase 12 (lines 126-143) , 5 success criteria drive planning acceptance
- `.planning/PROJECT.md` § Constraints + Technology Stack , ClaudeClaw as runtime, system cron + `claude -p` as scheduler, file-based state, no custom runtime

### v2.0 Artifacts This Phase Consumes (from Phases 8, 9, 10, 11)
- `.claude/skills/agentbloc/references/business-graph-schema.md` , indirect; deploy-engine does NOT read the Business Graph but cites its path in DEPLOY-REPORT.md for traceability
- `.claude/skills/agentbloc/references/agent-profile-schema.md` (Phase 9) , input contract for template substitution (D-62 anchor points derive from this schema's field set)
- `.claude/skills/agentbloc/references/integration-manifest-schema.md` (Phase 10) , input contract for `.mcp.json` merge (D-66) + DEPLOY-REPORT.md integration rows
- `.claude/skills/agentbloc/references/discovery-report-schema.md` (Phase 11) , input contract for `[DISCOVERED]`-tier integration entries (expires_at propagated to DEPLOY-REPORT.md)
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (Phase 9 fixture) , canonical input for the arco-rooms-deploy-report fixture
- `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` (Phase 10 fixture) , canonical integration input
- `.claude/skills/agentbloc/examples/mapfre-discovery-report.md` (Phase 11 fixture) , shows how a DISCOVERED-tier entry surfaces in the deploy report

### v1.0 Artifacts Being Extended
- `.claude/skills/agentbloc/references/phase-5-deployment.md` (v1.0) , promote ClaudeClaw + system cron path to Priority 1 via surgical edit (D-40 pattern); preserve v1.0 Summary block
- `.claude/skills/agentbloc/references/credentials.md` (v1.0) , referenced by D-73 `.env.example` auto-append for `N8N_BASE_URL`
- `.claude/skills/agentbloc/references/prompt-injection.md` (v1.0) , generated SKILL.md files cite this reference so deployed agents ingest this defense posture
- `.claude/skills/agentbloc/SKILL.md` (post-Phase-11, 180 lines) , Phase 5 entry + State Transitions paragraph + Phase 6 precondition get D-29-style surgical edits
- v1.0 Phase 4 Dry Run protocol , re-validated by DEPLOY-08 post-deploy verification (D-69)

### Prior Phase Context (carry-forward decisions)
- `.planning/phases/08-business-graph-foundation/08-CONTEXT.md` , D-1, D-11, D-13, D-14, D-15, D-18 apply structurally
- `.planning/phases/09-designer-agent/09-CONTEXT.md` , D-21 (subagent scoped tools), D-22 (three-tier obligation), D-29 (surgical SKILL.md edits)
- `.planning/phases/10-integration-discovery-mcp-path/10-CONTEXT.md` , D-31 (reference split), D-34 (verification), D-35 (halt-and-name), D-37 (approval-gated), D-39 (evidence + UNVERIFIED), D-40 (surgical edits), D-42 (idempotency fingerprint)
- `.planning/phases/11-integration-discovery-browser-fallback/11-CONTEXT.md` , D-43 (subagent frontmatter), D-45 (schema-locked + SHA256), D-46 (append-only ledger), D-50 (state.json schema), D-58 (context-budget discipline)
- `.planning/milestones/v1.0-phases/05-deployment-artifacts-and-evolution/05-CONTEXT.md` (if present) , v1.0 Phase 5 original decisions

### New Files To Be Created (plan-phase will materialize)
- `.claude/skills/agentbloc/references/deploy-protocol.md` , imperative 7-step flow
- `.claude/skills/agentbloc/references/deployed-agent-skill-schema.md` , per-agent SKILL.md contract
- `.claude/skills/agentbloc/references/agent-memory-schema.md` , memory.md + state.json + last-run.json contract
- `.claude/skills/agentbloc/references/deploy-report-schema.md` , DEPLOY-REPORT.md + DEPLOY-FAILED-REPORT.md contract
- `.claude/skills/agentbloc/templates/deployed-agent-skill.md.tmpl` , Jinja-lite substitution template
- `.claude/agents/deploy-engine.md` , orchestrator subagent with narrowed Bash allow-list
- `.claude/skills/agentbloc/examples/arco-rooms-deploy-report.md` , 3-agent fixture
- `.claude/skills/agentbloc/examples/arco-rooms-registry.yaml` , fixture registry

### External Documentation Pointers (for research loops if needed)
- ClaudeClaw docs for `Agent` + `TeamCreate` + `SendMessage` primitives (Phase 13 RUNTIME consumes; Phase 12 references for the template's autonomy-language block)
- Claude Code Subagents official docs (`code.claude.com/docs/en/sub-agents`) , subagent definition format for deploy-engine
- Claude Code Scheduled Tasks docs (`code.claude.com/docs/en/scheduled-tasks`) , confirms Phase 12 targets system cron not Scheduled Tasks per D-72
- `.claude/skills/agentbloc/references/frameworks.md` (v1.0) , CrewAI/LangGraph pattern references cited in template prose

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/agents/designer-agent.md` (145 lines, Phase 9) , structural twin for `deploy-engine.md` (frontmatter + XML blocks: `<role>`, `<write_constraint>`, `<output_contract>`, `<validation_and_emission>`, `<scope_exclusion>`)
- `.claude/agents/browser-discovery.md` (171 lines, Phase 11) , structural twin for `deploy-engine.md` with narrowed Bash allow-list pattern (new for Phase 12)
- `references/mcp-integration-protocol.md` (231 lines, Phase 10) , structural twin for `deploy-protocol.md` (imperative 7-step grammar, ASCII flow diagram, Verification Loop section)
- `references/integration-manifest-schema.md` (168 lines, Phase 10) , structural twin for `deploy-report-schema.md` (schema + field obligation matrix + bounded enums + validation checklist)
- `references/agent-profile-schema.md` (178 lines, Phase 9) , structural twin for `deployed-agent-skill-schema.md` (substitution-anchor field matrix + validation checklist)
- `references/discovery-report-schema.md` (~216 lines, Phase 11) , structural twin for `deploy-report-schema.md` frontmatter shape (schema_version + generated_at + sha256 + status enum)
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` (Phase 9 fixture) + `arco-rooms-integration-manifest.yaml` (Phase 10 fixture) + `mapfre-discovery-report.md` (Phase 11 fixture) , inputs to the arco-rooms-deploy-report fixture
- `SKILL.md` (180 lines post-Phase-11) , has 3 existing sub-gate bullets (`business_graph_validated`, `agent_profiles_validated`, `mcp_integrations_verified`) + Phase-5 entry is sparse (only loads `phase-5-deployment.md`) + Phase 6 precondition not yet wired , all prime extension points for D-29 surgical edits
- `references/phase-5-deployment.md` (v1.0, size TBD) , Priority 1 promotion target per D-40; v1.0 Summary block preservation pattern carries from D-40 and Phase 11 D-57

### Established Patterns
- **Subagent with `context: fork`, scoped tools (Phase 9 D-21 + Phase 11 D-43):** applied to `deploy-engine.md` with narrowed Bash allow-list extension
- **`<write_constraint>` + `<output_contract>` XML blocks (Phase 9 + Phase 11):** applied to `deploy-engine.md`
- **Three-tier field obligation (Phase 9 D-22):** applied to all three Phase 12 schemas (deployed-agent-skill + agent-memory + deploy-report)
- **Prose-checklist validator (Phase 8 D-13):** applied to all three Phase 12 schemas + the deploy-protocol.md Validation Loop
- **Bounded enum for discriminated unions (Phase 8 D-18):** applied to deploy-report `status`, `idempotency_action`, `verification_status`, `mcp_merge_action`, DEPLOY-FAILED-REPORT `failed_step`
- **Halt-and-name with named artifact (Phase 10 D-35 + Phase 11 extension):** `DEPLOY-FAILED-REPORT.md` as twin of `DISCOVERY-BLOCKED-REPORT.md`
- **Approval-gated execution (Phase 10 D-37):** applied to D-61 diff-before-overwrite + D-66 .mcp.json conflict-on-key + D-72 crontab install (user runs crontab command; Claude only writes the proposed file)
- **Silent artifact + rendered table review (Phase 8 D-14):** user confirms rendered deploy summary (team table + per-agent deployment status); DEPLOY-REPORT.md + SKILL.md + memory.md + state.json all written silently
- **Surgical edits to existing references (Phase 9 D-29 + Phase 10 D-40 + Phase 11 D-57):** applied to `phase-5-deployment.md` (Priority 1 promotion for ClaudeClaw path) + SKILL.md (Phase 5 load-list + State Transitions bullet + Phase 6 precondition)
- **Context-budget discipline (Phase 11 D-58):** Phase 5 unconditional load currently 1 ref; Phase 12 adds 4 for ~1,100-line total load (no conflict; Phase 5 had headroom pre-12)
- **Append-only ledger format (Phase 11 D-46):** applied to `.agentbloc/deploy/DEPLOY_HISTORY.jsonl`
- **Idempotency fingerprint (Phase 10 D-42 + Phase 11 D-45):** applied to D-60 SHA256-over-body-with-timestamp-masking

### Integration Points
- `SKILL.md` Phase 5 entry: extend See-line load-list with 4 new references (D-29 pattern, same shape as Phase 10 D-41 and Phase 11 D-58)
- `SKILL.md` State Transitions paragraph: add "Phase 5 specific" bullet naming the `deployment_artifacts_emitted` sub-gate
- `SKILL.md` Phase 6 entry: add precondition "verify `.agentbloc/deploy/DEPLOY-REPORT.md` exists AND `verification_status: PASSED | PARTIAL`" (PARTIAL allowed because optional MCP soft-fails shouldn't block Evolution phase)
- `phase-5-deployment.md`: Priority 1 promotion for ClaudeClaw + delegate detail to `deploy-protocol.md` via See-line; preserve v1.0 Summary block
- `.agentbloc/deploy/` directory: new, created on first Phase 12 run
- `skills/<agent-id>/SKILL.md`: new project-root files, one per deployed agent (stable contract per D-59a, DEPLOY-01 literal honored)
- `.agentbloc/agents/<agent-id>/` directories: new per deployed agent, co-locate memory.md + state.json + last-run.json (mutable runtime state per D-59b, MEM-01 literal overridden)
- `.agentbloc/agents/registry.yaml`: new, co-located with the per-agent state subdirs (per D-59c, DEPLOY-05 literal overridden)

### Tech Stack Additions (none)
No new deps. Template substitution + YAML parsing + JSON writing + markdown rendering + Bash allow-list are all Claude-in-context operations. The template file is pure markdown with Jinja-lite placeholders (no runtime engine). Phase 12 stays within the "markdown-only skill" constraint; the only executable code is the inherited `scripts/anti-bot-lint.sh` from Phase 11 (unchanged).

</code_context>

<specifics>
## Specific Ideas

- **Phase 12 closes the Design-to-Deploy contract.** Everything Phase 8-11 designed becomes runnable. The deploy-engine subagent is the atomic unit , one invocation, one deployment, one report. No long-running state; every re-run is deterministic given inputs (D-60 fingerprint + D-62 template-based generation enforce this).
- **The template at `.claude/skills/agentbloc/templates/deployed-agent-skill.md.tmpl` is the single most load-bearing file in Phase 12.** Every deployed agent's SKILL.md inherits from this template. Its prose sets the baseline autonomy / escalation / memory / kill-switch posture for the entire v2.0 runtime. Phase 14 AUTON / MONITOR / CTRL all consume agents whose behavior is shaped by this template.
- **D-59 splits into 59a/59b/59c with one literal honored and two literal overrides; document all three explicitly.** D-59a HONORS DEPLOY-01 (`skills/<agent-id>/SKILL.md` at project root, ClaudeClaw runtime expectation). D-59b OVERRIDES MEM-01 (per-agent state moves from `.claude/agents/<agent-id>/` to `.agentbloc/agents/<agent-id>/` for namespace hygiene and stable-vs-mutable split). D-59c OVERRIDES DEPLOY-05 (registry.yaml moves from `.claude/agents/` to `.agentbloc/agents/` for co-location with the data it indexes). Plan 12-01 header MUST document the two overrides with rationale so Phase 16 audit readers see the REQUIREMENTS-literal tension AND the architectural principle (separating stable contracts from mutable runtime state, respecting Claude Code's reserved `.claude/agents/` namespace for native subagent definitions only). The argument: namespace hygiene and stable-vs-mutable split are worth the double literal-text departure because the structure teaches AI-agent-system architecture patterns to readers of this open-source skill.
- **Idempotency is the entire ballgame for DEPLOY-06 success.** Phase 16 success criterion 2 ("re-running with same profiles does not duplicate or corrupt") is pass / fail on D-60 fingerprint correctness. Every phase-12 artifact MUST be deterministic given inputs. Template-based generation (D-62) is the only defensible path; LLM-assembled would fail this bar.
- **Post-deploy verification is the bridge to Phase 13.** D-69 check 3 (cron registered) soft-fails in Phase 12-only execution because Phase 13 writes the actual crontab entries. When Phase 13 ships, this check becomes hard-enforcing. Phase 12's DEPLOY-REPORT.md should clearly mark "Phase 13 not yet executed; cron verification skipped" so a reader doesn't mistake the PARTIAL status for a real problem.
- **DEPLOY_HISTORY.jsonl supports regulated-deployment audit trails.** The append-only deploy ledger is the GDPR Article 30 record-of-processing for agent-lifecycle events. A deployed team's history from first deploy to Nth re-deploy is one file, grep-able. Per-entry fields (deployment_id, verification_status, agent_count) enable Phase 6 Evolution weekly scans to compute trend metrics without crawling individual reports.
- **Phase 12 is the first phase that writes to `.mcp.json`.** Phase 10 wrote `integration-manifest.yaml`; Phase 11 wrote DISCOVERY-REPORT.md under `.agentbloc/discovery/`. Neither touched `.mcp.json`. Phase 12's D-66 merge is the first mutation of the user's Claude Code MCP config , surgical via Edit tool, conflict-warning non-destructive, user-approval-gated for overwrites. Get this wrong and users lose custom MCP configs. Get this right and re-deploy is safe.
- **Phase 13 depends on Phase 12's crontab.proposed file existing.** Phase 13 wakes agents via cron + claude -p invocation. Phase 13 READS `.agentbloc/deploy/crontab.proposed` and either (a) advises the user to run `crontab <file>` (declarative, Phase 12 discipline carries) or (b) writes to the user's crontab directly (Phase 13's own decision). Phase 12 ships the file; Phase 13 picks the activation pattern.
- **The `deploy-engine` subagent is the first AgentBloc subagent with Bash.** Designer had no Bash (Phase 9 D-21); browser-discovery had no Bash (Phase 11 D-43 explicitly disallowed). deploy-engine NEEDS Bash for ClaudeClaw CLI probes (`claude mcp list`, `claude agents list`). The narrow allow-list (D-67) is the precedent-setter , future subagents that need Bash inherit this pattern of declaring an explicit allow-list in the subagent frontmatter.

</specifics>

<deferred>
## Deferred Ideas

### Deferred to Phase 13 (Multi-Agent Runtime)
- Actual crontab registration (Phase 12 ships `.agentbloc/deploy/crontab.proposed`; Phase 13 activates)
- n8n webhook route configuration (Phase 12 ships placeholder URLs; Phase 13 wires)
- `TeamCreate` / `SendMessage` inter-agent coordination (Phase 12 emits dependency graph; Phase 13 wakes it)
- Correlation-ID propagation through live agent activations
- Kill-switch enforcement at agent wake (Phase 12 ships the prose; Phase 13 enforces)

### Deferred to Phase 14 (Autonomy + Monitor + Control Plane)
- JSONL log emission at runtime (Phase 12 ships the registry contract; Phase 14 writes logs)
- Briefing-agent daily summaries (Phase 12 ships `briefing_agent_id` in registry; Phase 14 generates the briefing-agent when the team requests one , crosswalk with Phase 15 anticipation that also produces a briefing-agent by default)
- Telegram approval-queue threads + escalation UX
- Per-agent cost tracking (token_count + cost_usd rollups)
- Task locking for shared resources (Phase 12 bootstraps `locks: []` empty; Phase 14 populates at runtime)
- Status badges + activity feed

### Deferred to Phase 15 (Anticipation Engine)
- Anticipation pass adding unrequested-but-needed agents (Phase 12 deploys whatever agent-profiles.yaml contains; anticipated agents added by Phase 15 automatically deploy in the next deploy run)
- `briefing-agent` as a default anticipated agent per MONITOR-04

### Deferred to v2.5+
- Cross-run deploy-history diff viewer (web dashboard; Phase 12 has the JSONL; v2.5 has the UI)
- SQLite migration from JSONL + per-file state (v2.5 web dashboard lands with DB)
- Version-tagging deploys as git tags (`git tag agentbloc-deploy-<deployment_id>`)
- Rollback protocol (v2.5 adds `agentbloc deploy --rollback <deployment_id>` against the DEPLOY_HISTORY.jsonl trail)

### Deferred to v3.0+
- Multi-tenant deploys (one skill directory tree per client)
- Signed artifact manifest (cryptographic provenance chain)

### Deferred to v4.0+
- Self-Healing Evolution , auto-remediation when post-deploy verification hard-fails (v4.0 re-invokes discovery + re-deploys with human-approved patches)

### Explicitly not doing (anti-features)
- Direct `crontab` write by Claude , violates v1.0 security posture (D-72 defers to user-run command)
- Overwriting `.mcp.json` without user approval , violates D-37 (D-66 warns + approves)
- LLM-assembled SKILL.md content , violates Phase 16 determinism requirement (D-62 template-based)
- Emitting partial deploy artifacts on failure , violates halt-and-name discipline (D-70 all-or-nothing)

### Plan-eng-review observations (forward-looking, not blockers)
- Phase 12's `deploy-engine` introduces narrow-Bash-allow-list as a pattern. Phase 14 may need similar for agents that invoke monitoring commands (`claude logs tail`). The pattern carries cleanly; document it once in `deploy-protocol.md` so Phase 14 planner can cite it.
- `agent-memory-schema.md` may end up the most-referenced schema in v2.0+ because Phase 13 (state machine) and Phase 14 (monitoring) both read `state.json` + `last-run.json`. Consider sizing it generously (aim 200-250 lines vs 168 for integration-manifest-schema) so downstream phases don't have to extend it surgically.
- Template file (`deployed-agent-skill.md.tmpl`) becomes a versioned contract. Every v2.0 re-deploy uses the template as-of the commit that generated it. v2.5+ may need template-versioning (two deploy runs on different template versions should produce different skill files) , defer, but note the shape.

</deferred>

## Plan Structure Projection (3 plans)

This is the planner's decision, but autonomous rationale points strongly toward 3 plans matching the Phase 10 contract-first / Phase 11 contract-first rhythm:

- **Plan 12-01 (core contracts + template + fixtures):** Create 4 references (`deploy-protocol.md` imperative + `deployed-agent-skill-schema.md` + `agent-memory-schema.md` + `deploy-report-schema.md`) + Jinja-lite template + 2 Arco Rooms fixtures (`arco-rooms-deploy-report.md` + `arco-rooms-registry.yaml`). Pure contracts + fixtures, no SKILL.md edits, no wiring, no subagent. Covers DEPLOY-01 / DEPLOY-05 / DEPLOY-06 / DEPLOY-07 / MEM-01..06 contract surfaces.
- **Plan 12-02 (deploy-engine subagent):** Create `.claude/agents/deploy-engine.md` with frontmatter (scoped tools + narrow Bash allow-list per D-67) + XML blocks (`<role>`, `<write_constraint>`, `<output_contract>`, `<idempotency_protocol>`, `<mcp_merge_protocol>`, `<post_deploy_verification>`, `<halt_and_name>`). Mirrors designer-agent.md + browser-discovery.md structure. Covers the orchestration logic that the Plan 12-01 contracts specify. Smoke-test: point deploy-engine at the Arco Rooms fixtures and verify it can produce the expected 3-agent deploy deterministically.
- **Plan 12-03 (wiring):** Surgical edits to `phase-5-deployment.md` (Priority 1 promotion for ClaudeClaw path + See-line delegation) + `SKILL.md` (Phase 5 load-list with 4 See-lines + State Transitions `deployment_artifacts_emitted` sub-gate + Phase 6 precondition). Covers DEPLOY-02 (job-config emission wired into Phase 5 narrative) + DEPLOY-03 (`.mcp.json` merge wired into Phase 5) + DEPLOY-08 (post-deploy verification as Phase 5 Summary Gate prerequisite).

Matches Phase 10 / Phase 11 "contract-first, wiring-second" rhythm. Planner should confirm 3 plans in gsd-plan-phase. Phase 11 shipped 4 plans because its subagent was particularly complex (Phase 11 Plan 11-03 was 1 task because the subagent body had 7 XML blocks + posture classifier + fresh-context verification primitive). Phase 12's subagent is complex too (D-67 Bash allow-list is a new pattern) but the deploy flow itself is simpler than browser reverse-engineering , 3 plans should suffice; planner escalates to 4 if Plan 12-02 exceeds a reasonable single-plan scope.

## Threat Model Notes

Phase 12 introduces new attack surfaces that future phases (Phase 14 MONITOR + CSO review) will audit. Surfaces:

1. **Credentials leaking into generated SKILL.md:** The template substitution reads agent-profiles.yaml fields. If a future extension adds a `{{agent.api_key}}` anchor, credentials could leak into `skills/<agent-id>/SKILL.md` which gets committed. Mitigation: the D-62 anchor-point allow-list is explicit and locked in `deployed-agent-skill-schema.md`. No credential-bearing fields in the allow-list; env-var references only.
2. **Memory.md exfiltration via agent prompt:** memory.md is read by the agent every wake. If it contains PII the agent has no reason to process (e.g., tenant SSN accidentally pasted by a user), a prompt-injection attack could read and forward it. Mitigation: v1.0 prompt-injection defense (`prompt-injection.md` cited in every generated SKILL.md per template); Phase 12 warns in the generated memory.md header "Domain knowledge only; DO NOT paste PII unless the agent needs it."
3. **Registry poisoning:** A malicious user could edit `.claude/agents/registry.yaml` to point a skill_path at an attacker-controlled SKILL.md. Phase 13 reads registry.yaml to route agent wakes; Phase 12 is the emission point. Mitigation: DEPLOY-REPORT.md idempotent_hash covers registry.yaml; re-deploy detects the tamper. Phase 14 CSO review should audit this explicitly.
4. **`.mcp.json` merge conflicts used to inject malicious entries:** If an attacker social-engineers a user into approving a "replace" decision in D-66's conflict prompt, a malicious MCP entry could land. Mitigation: approval prompts show the full diff per D-61; user sees the malicious entry before approving. Rate-limit to one approval-prompt per .mcp.json run to prevent prompt fatigue.
5. **Crontab.proposed tampering:** Phase 12 writes `.agentbloc/deploy/crontab.proposed` which the user runs. An attacker editing this file between Phase 12 emission and user install could inject commands. Mitigation: the file is committed + idempotent_hash covers it; reviewer notices the diff. Defense-in-depth: `claude -p` is sandboxed (inherits Claude Code security posture).

</threat_model_notes>

---

*Phase: 12-deploy-pipeline-agent-memory*
*Context gathered: 2026-04-24*
*Decision mode: autonomous (Pablo-authorized). All decisions above are mine to defend; Pablo retains veto on any he disagrees with , raise before Phase 13 discuss begins.*
