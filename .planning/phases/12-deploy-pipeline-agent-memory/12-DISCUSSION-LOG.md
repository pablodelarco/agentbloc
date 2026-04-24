# Phase 12: Deploy Pipeline + Agent Memory System - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in [12-CONTEXT.md](12-CONTEXT.md) , this log preserves the alternatives considered and the reasoning for each autonomous pick.

**Date:** 2026-04-24
**Phase:** 12-deploy-pipeline-agent-memory
**Decision mode:** Autonomous (per `autonomous_mode` memo , Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + prior phases D-1..D-58). No interactive AskUserQuestion calls; each area shows options considered and rationale.
**Areas discussed:** 13 gray areas + threat-model sweep , output directory convention · idempotency fingerprint · diff presentation · SKILL.md generation approach · registry format · memory.md structure · state.json schema · .mcp.json merge semantics · deploy-engine subagent tool scope · DEPLOY-REPORT.md format · post-deploy verification · halt-and-name for failures · cron config approach + n8n stubs
**New decisions:** D-59 through D-73 (15 new decisions locked)
**Auto-decisions-count:** 15

---

## Output Directory Convention (→ D-59)

| Option | Description | Selected |
|--------|-------------|----------|
| Project-root `skills/<agent-id>/SKILL.md` | Literal REQUIREMENTS.md phrasing, matches ClaudeClaw convention | |
| `.claude/skills/<agent-id>/SKILL.md` | Collides with AgentBloc + mcp-builder skill hub dirs | |
| `.agentbloc/deploy/skills/<agent-id>/SKILL.md` | Artifacts under `.agentbloc/` hierarchy but divorced from the memory dir | |
| `.claude/agents/<agent-id>/SKILL.md` (co-located with memory dir) | MEM-01 already writes to `.claude/agents/<agent-id>/`; co-locate the 4 per-agent files | ✓ |

**Auto-selected:** `.claude/agents/<agent-id>/SKILL.md`, co-located with `memory.md + state.json + last-run.json`.

**Notes:** REQUIREMENTS.md DEPLOY-01 literal says `skills/{agent-id}/SKILL.md`. D-59 is a documented literal-reading override: co-locating all 4 per-agent files (SKILL + memory + state + last-run) in a single subdirectory is a strictly-better shape because (a) it's atomic ("everything about agent X lives in `.claude/agents/x/`"), (b) it doesn't create a third top-level directory colliding with the existing `.claude/skills/` and `.claude/agents/`, (c) it matches MEM-01's explicit path `.claude/agents/{agent-id}/` , which is the same literal in REQUIREMENTS.md, so DEPLOY-01's `skills/` literal is effectively an outdated or inconsistent reference. Plan-phase header MUST explicitly justify this override so reviewers see the REQUIREMENTS tension. Root-level `.claude/agents/<id>.md` (file-not-directory) is reserved for developer-authored Claude Code subagents like designer-agent.md and browser-discovery.md (Phases 9 + 11); deployed AgentBloc agents use subdirectories.

**Files consulted:** REQUIREMENTS.md DEPLOY-01, MEM-01, existing `.claude/agents/designer-agent.md` and `browser-discovery.md` shape.

**Prior decisions applied:** Phase 8 D-15 (artifacts under `.agentbloc/` for deploy state but not source-code artifacts which live under `.claude/`).

---

## Idempotency Fingerprint Mechanism (→ D-60)

| Option | Description | Selected |
|--------|-------------|----------|
| mtime comparison | Fast but lies across clone/checkout/rsync | |
| git blob hash | Requires git; AgentBloc deploys to non-git VPS + Docker images | |
| Full-file SHA256 | Timestamp drift makes every re-run look like a change | |
| SHA256 over body with timestamp fields masked | Content-aware, deterministic across re-runs, matches Phase 11 DISCOVERY-REPORT.md pattern | ✓ |

**Auto-selected:** SHA256 over body with timestamp fields masked to `<TIMESTAMP>` before hashing.

**Notes:** Matches the DISCOVERY-REPORT.md SHA256 discipline (Phase 11 D-45) and `integration-manifest.yaml healthcheck_at` idempotency pattern (Phase 10 D-42). One shape project-wide. Every generated artifact carries an HTML-comment fingerprint at bottom: `<!-- agentbloc:fingerprint sha256=<hex> generated_at=<ISO> -->`. Deploy-engine reads existing file, masks `generated_at` token AND its own fingerprint comment, hashes, compares. Same hash = skip (`idempotency_action: skip-identical`). Different hash = present diff + approve (`idempotency_action: update-approved` or halt if declined). Reject git-blob-hash because users deploy to Docker / VPS / bare Linux without git. Reject mtime because clone / rsync / tar extraction reset it arbitrarily.

**Files consulted:** REQUIREMENTS.md DEPLOY-06, Phase 11 discovery-report-schema.md (SHA256 pattern), Phase 10 integration-manifest-schema.md (healthcheck_at pattern).

**Prior decisions applied:** Phase 10 D-42 (idempotency fingerprint), Phase 11 D-45 (SHA256 over body excluding signature field).

---

## Diff Presentation Format (→ D-61)

| Option | Description | Selected |
|--------|-------------|----------|
| Side-by-side two-column diff | Terminal-hostile; wide output; awkward in markdown | |
| Affected-keys-only summary | Loses line-level precision; "foo.bar changed" hides the content | |
| Silent overwrite, no approval | Violates D-37 approval-gated execution | |
| Unified diff + 5-line context hunks, in DEPLOY-REPORT.md + stdout + separate .diff file | Standard format, reviewable, auditable | ✓ |

**Auto-selected:** Unified diff (`diff -u` style) with 5-line context; embedded in DEPLOY-REPORT.md under collapsible `<details>` blocks; printed to stdout; saved to `.agentbloc/deploy/pending-diffs/<artifact>.diff` for post-approval audit.

**Notes:** Unified diff is the standard developer-audit format every Git-using engineer recognizes. 5-line context matches `git diff` defaults , enough to understand the change in isolation. Triple emission (report + stdout + saved file) gives redundancy: DEPLOY-REPORT.md for the audit trail, stdout for live user review, `.diff` file for paste-into-PR. `<details>` collapsible wrapper keeps DEPLOY-REPORT.md scannable when many files changed. Reject side-by-side because markdown renders awkwardly in wide-column display and terminals wrap. Reject affected-keys-only because it loses "what exactly changed" precision required for approval.

**Files consulted:** REQUIREMENTS.md DEPLOY-06, Phase 10 D-37 (approval-gated execution).

**Prior decisions applied:** Phase 10 D-37 (approval-gated execution for anything with blast radius).

---

## SKILL.md Generation Approach (→ D-62)

| Option | Description | Selected |
|--------|-------------|----------|
| LLM-assembled per agent | Creative but non-deterministic; cost-per-deploy; fails Phase 16 determinism | |
| Pure Python / TypeScript template engine | Adds runtime dep; fights markdown-only constraint | |
| Jinja-lite in markdown, Claude substitutes in-context | Deterministic, no dep, testable | ✓ |
| Hybrid (LLM for backstory prose, template for structure) | Two code paths; fragile; inherits LLM non-determinism | |

**Auto-selected:** Template-based generation with fixed Jinja-lite anchor points (`{{agent.field}}`). Template lives at `.claude/skills/agentbloc/templates/deployed-agent-skill.md.tmpl`. Substitution performed by Claude in-context (reading template + YAML, producing output via string-level replacement). No runtime engine; pure markdown-compatible.

**Notes:** Phase 9 locked the agent's prompt structure into YAML (role / goal / backstory / tools / autonomy / outputs / escalation / dependencies / blast_radius / model). Those fields ARE the prompt content , no synthesis needed. Template substitution makes the generation (a) deterministic (same inputs → same output byte-for-byte), (b) cheap (zero LLM cost in the inner loop), (c) testable (Phase 16 golden-file tests trivially validate). LLM assembly is rejected because Phase 16 success criterion 2 ("re-running does not duplicate or corrupt") requires determinism and LLMs introduce token-level variance even at temperature=0. Hybrid rejected because two code paths is fragile; whichever path changes will drift from the other. Anchor-point allow-list frozen in `deployed-agent-skill-schema.md` so new fields don't accidentally leak credentials.

**Files consulted:** REQUIREMENTS.md DEPLOY-01, ROADMAP.md Phase 12 success criterion 2, Phase 9 D-22 (three-tier field obligation in agent-profiles.yaml).

**Prior decisions applied:** Phase 8 D-13 (prose-checklist validator; template is the natural extension for emission), Phase 9 D-22 (the structured YAML schema Phase 12 reads).

---

## Registry Format (→ D-63)

| Option | Description | Selected |
|--------|-------------|----------|
| YAML at `.claude/agents/registry.yaml` | Consistent with team.yaml / agent-profiles.yaml / integration-manifest.yaml | ✓ |
| JSON at `.claude/agents/registry.json` | Faster machine-write; harder for humans to audit | |
| Mixed: registry.yaml for team block + registry.json for agents array | Over-engineered for this scale | |

**Auto-selected:** YAML at `.claude/agents/registry.yaml` per prior convention. Schema defined in D-63.

**Notes:** D-1 (v1.0 + PROJECT.md) dictates YAML for human-authored/human-audited config, JSON for machine-written state. Registry is read by Phase 14 briefing-agent for daily summaries, potentially edited by users to rename a team or adjust reporting_hierarchy. YAML wins. JSON rejected because deploys that re-emit the file will be harder to audit in PR reviews; YAML diffs are more readable. REQUIREMENTS.md DEPLOY-05 is format-neutral ("Generate `.claude/agents/registry.yaml`") so no conflict. Mixed format rejected because it's over-engineered for a file that will have ~10-50 entries at the v2.0 target scale.

**Files consulted:** REQUIREMENTS.md DEPLOY-05, Phase 8 D-1 (YAML vs JSON rules).

**Prior decisions applied:** Phase 8 D-1 (file-based state; YAML for human config, JSON for machine state).

---

## Memory.md Structure (→ D-64)

| Option | Description | Selected |
|--------|-------------|----------|
| Freeform markdown, no template | Flexible but agent wastes tokens hunting for sections | |
| Single-blob per agent | Shortest but no internal structure | |
| 2-section template (Knowledge + Open Items) | Too coarse; mixes decision-history and integration-quirks in one bucket | |
| 4-section template (Domain Knowledge + Decisions + Integration Quirks + Open Items) | Matches the file-based-state blog post cited in PROJECT.md sources | ✓ |
| 6+ section template (+ Escalation History + Glossary) | Over-structured; can be added by user as OPTIONAL | |

**Auto-selected:** 4-section template with fixed H2 navigation: `## Domain Knowledge` / `## Decisions` / `## Integration Quirks` / `## Open Items`.

**Notes:** Freeform markdown would force the agent to scan the whole file on every wake, burning context. A section-headed template lets the agent jump to `## Domain Knowledge` on wake without scanning. The 4 sections cover the real-world categories observed in 24/7 file-based agent systems (see `earezki.com` cited in PROJECT.md , static knowledge / history / quirks / pending). Sections are RECOMMENDED per D-22 three-tier obligation (schema warns on missing H2 but still emits). Phase 12 ships the template as the initial memory.md stub with empty sections and one-line guidance under each H2 , user fills in over time or delegates to the agent. Agent can append additional H2s beyond the 4 (schema does not forbid additive H2s) per OPTIONAL tier.

**Files consulted:** REQUIREMENTS.md MEM-02, PROJECT.md "Sources" section citing `earezki.com` 2026-03-09 file-based-state pattern.

**Prior decisions applied:** Phase 9 D-22 (three-tier field obligation).

---

## state.json Schema Shape (→ D-65)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-role schemas (finance.json, reporter.json) | Flexible but explodes schema count + validator complexity | |
| One flat common schema, role-opaque `working_state` namespace | One shape project-wide; agent owns its role-specific namespace | ✓ |
| Free-form JSON, no schema | No idempotency discipline; regressions likely | |
| Schema with union types on agent-role | Too clever; markdown-only prose-checklist validator can't express unions well | |

**Auto-selected:** One flat common schema; role-specific fields namespaced inside a free-form `working_state` object.

**Notes:** Common fields across every agent: `schema_version`, `agent_id`, `team`, `last_wake_at`, `last_completion_at`, `processed_ids[]`, `locks[]`, `retries[]`, `kill_switch_last_checked`. Role diversity (Gestor Cobros' current-month-payments, Recepcionista's per-owner notification log, Gestor Documental's invoice queue) lives inside `working_state`. One flat schema = one Validation Checklist in `agent-memory-schema.md`. Per-role schemas would 3x the validator surface for the Arco Rooms team and Nx for larger teams. `processed_ids[]` lifts the idempotency pattern from v1.0 to a first-class field every agent has , prevents the "double-processed invoice" regression common in 24/7 agents. `locks[]` anticipates Phase 14 CTRL-03 without coupling Phase 12 to it (empty array on first deploy; Phase 14 populates at runtime). `kill_switch_last_checked` is Phase 13's write target; Phase 12 bootstraps null.

**Files consulted:** REQUIREMENTS.md MEM-03, REQUIREMENTS.md CTRL-03 (locks forward reference), REQUIREMENTS.md RUNTIME-07 (kill switch forward reference), Phase 11 state.json shape (browser-discovery's state schema , structural parallel).

**Prior decisions applied:** Phase 9 D-22 (three-tier obligation), Phase 11 D-50 (state.json schema with phase enum lifecycle , Phase 12 adapts this pattern for per-agent state).

---

## .mcp.json Merge Semantics (→ D-66)

| Option | Description | Selected |
|--------|-------------|----------|
| Always overwrite | Destructive; loses user customizations | |
| Always skip if key exists | Deploys silently broken configs when manifest updated | |
| Merge-keep-existing with conflict warning + user approval | Safe default + explicit approval for overwrites | ✓ |
| Three-way merge (manifest + existing + template) | Too clever; markdown-only constraint rejects; no way to express "intent" | |

**Auto-selected:** Non-destructive merge. Add new keys freely. On conflict: keep existing, warn in DEPLOY-REPORT.md with diff, prompt user for replace-approval.

**Notes:** 5-step protocol:
1. If `.mcp.json` missing → create with merged entries
2. Key not in `.mcp.json` → add (mcp_merge_action: add-new)
3. Key present, byte-identical (SHA256 match per D-60) → skip (mcp_merge_action: skip-identical)
4. Key present, config differs → KEEP EXISTING + warn + present diff (mcp_merge_action: keep-existing-conflict-warn)
5. On user 'replace' approval → write new (mcp_merge_action: replace-approved)

Always-overwrite rejected because it silently clobbers user customizations (custom env vars, custom command args). Always-skip rejected because it deploys stale/broken configs when the manifest has genuine updates. Three-way merge rejected because it requires expressing "what was the template" / "what is user-intended" / "what is new" , no clean expression in markdown. The chosen path matches D-37 approval-gated execution: non-destructive default, user approval required for overwrites.

**Files consulted:** REQUIREMENTS.md DEPLOY-03, ROADMAP.md Phase 12 success criterion 2.

**Prior decisions applied:** Phase 10 D-37 (approval-gated execution), D-60 (SHA256 fingerprint for byte-identical detection).

---

## Deploy-Engine Subagent Tool Scope (→ D-67)

| Option | Description | Selected |
|--------|-------------|----------|
| Full Bash + WebFetch + all MCPs | Maximum power but zero accountability | |
| Read/Grep/Glob/Write + Edit, NO Bash (Phase 9/11 pattern) | Can't probe `claude mcp list` / `claude agents list` for verification | |
| Read/Grep/Glob/Write + Edit + narrow Bash allow-list (4 commands) | Write for new files, Edit for .mcp.json merges, Bash for CLI probes only | ✓ |
| Separate verification subagent with Bash | Two subagents for one flow; overkill | |

**Auto-selected:** Read, Grep, Glob, Write, Edit + Bash narrowed to 4-command allow-list: `claude mcp list`, `claude agents list`, `crontab -l`, `shasum -a 256 <file>`. NO WebFetch, NO other MCPs.

**Notes:** This is the first AgentBloc subagent that needs Bash. Designer had no Bash (Phase 9 D-21); browser-discovery had no Bash (Phase 11 D-43 explicitly disallowed). Deploy-engine NEEDS Bash for the post-deploy verification probes (DEPLOY-08) , they're inherently shell-based because ClaudeClaw exposes `claude mcp list` / `claude agents list` as CLI commands. The narrow allow-list is the precedent-setter: (a) named commands only, (b) read-only verification operations, (c) no user-supplied argument interpolation (paths come from Phase 12-generated registry, not user input), (d) Phase 14 CI check can assert deploy-engine's Bash calls match the allow-list. Edit is needed alongside Write because `.mcp.json` surgical merges (D-66) must preserve the user's other MCP entries byte-for-byte. Write is needed for the many new artifacts per agent. NO WebFetch / NO other MCPs: deploy is pure file-system work.

**Files consulted:** REQUIREMENTS.md DEPLOY-08, Phase 9 D-21 (scoped tools + no Bash precedent), Phase 11 D-43 (browser-discovery tool scope).

**Prior decisions applied:** Phase 9 D-21, Phase 11 D-43 (both precedents set the posture; Phase 12 narrows Bash to named allow-list instead of blanket NO-Bash).

---

## DEPLOY-REPORT.md Format (→ D-68)

| Option | Description | Selected |
|--------|-------------|----------|
| Pure markdown, no frontmatter | No machine-queryable identity | |
| JSON file, no markdown | User-hostile for audit | |
| YAML frontmatter + 5 markdown sections (Created / Updated / Skipped / Pending / Verification) | Machine + human readable | ✓ |
| Three separate files (deploy-report.json, deploy-diff.md, deploy-pending.md) | Three-file contract is fragile | |

**Auto-selected:** YAML frontmatter (deployment_id + generated_at + idempotent_hash + verification_status + sha256) + 5-section markdown body (Created / Updated / Skipped / Pending User Actions / Post-Deploy Verification).

**Notes:** Mirrors DISCOVERY-REPORT.md shape (Phase 11 D-45) , same contract across project. Frontmatter gives the file a machine-queryable deployment identity (Phase 14 monitor agent can grep deployment_id across history); body gives user a scannable audit trail. 5 sections cover the four REQUIREMENTS.md DEPLOY-07 categories ("what was created, what was updated, what was skipped, and any pending user actions") plus a fifth for the post-deploy verification roll-up from DEPLOY-08. Uses collapsible `<details>` wrappers for embedded diffs so the report stays scannable when many files changed.

**Files consulted:** REQUIREMENTS.md DEPLOY-07, Phase 11 D-45 (DISCOVERY-REPORT.md schema), ROADMAP.md Phase 12 success criterion 3.

**Prior decisions applied:** Phase 11 D-45 (schema-locked frontmatter + SHA256 + structured body pattern).

---

## Post-Deploy Verification (→ D-69)

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest validation only (no actual CLI probe) | Fast but catches zero real integration failures | |
| Actual MCP handshake via `claude mcp list`, 10-second per-server timeout | Catches real failures; soft-fail for optional MCPs | ✓ |
| Actual MCP handshake, NO timeout | Flaky networks → hangs | |
| Full dry-run invocation per agent (wake each, run a probe task) | Expensive + introduces side effects | |

**Auto-selected:** Three-check verification via narrow Bash allow-list: (1) SKILL.md loads cleanly via `claude agents list`, (2) MCP servers respond via `claude mcp list` with 10-second per-server timeout, (3) Cron jobs registered via `crontab -l`. Optional integrations soft-fail (logged as PARTIAL, not FAILED). Overall verification_status rolls up to PASSED / PARTIAL / FAILED.

**Notes:** Manifest-only validation would catch zero real integration failures (a manifest says "verified" but the MCP server could have died since). Full dry-run-per-agent would be expensive (each wake is an LLM invocation) and introduce side effects (some agents do real work on wake). The three-check shell probe is the right middle ground: cheap (seconds per deploy), catches the three failure modes that a deployed team could hit at first wake. 10-second timeout is defensible (longer degrades feedback loop; shorter triggers false FAILs on flaky networks). Soft-fail for optional MCPs prevents a "Mapfre is down today" from blocking an otherwise-healthy deploy. Check 3 (cron) soft-fails in Phase 12-only execution because Phase 13 writes the actual crontab , becomes hard-check after Phase 13 lands.

**Files consulted:** REQUIREMENTS.md DEPLOY-08, INTEG-04 (verification protocol), Phase 10 D-34 (three-check verification pattern).

**Prior decisions applied:** Phase 10 D-34 (three-check verification), Phase 10 D-35 (halt-and-name on hard-fail).

---

## Halt-and-Name for Deploy Failures (→ D-70)

| Option | Description | Selected |
|--------|-------------|----------|
| Partial DEPLOY-REPORT.md with errors inline | Mixes success and failure signals, confuses re-deploy | |
| DEPLOY-FAILED-REPORT.md separately emitted, no DEPLOY-REPORT.md | All-or-nothing; clear signal | ✓ |
| Silent rollback to previous deploy state | Complex rollback logic; markdown-only constraint rejects | |
| Retry loop with exponential backoff, then give up | Treats transient failures same as permanent; muddles reporting | |

**Auto-selected:** On any hard-fail, write `.agentbloc/deploy/DEPLOY-FAILED-REPORT.md` (twin of DISCOVERY-BLOCKED-REPORT.md). DO NOT write a partial DEPLOY-REPORT.md. Halt Phase 5 gate (state bar → blocked). User sees specific failed_step + error + recommended fix + "say `retry deploy` after fix."

**Notes:** All-or-nothing discipline matches Phase 11 D-35 halt-and-name pattern. Mixing success and failure in a partial DEPLOY-REPORT.md creates ambiguity: "was the deploy ready or not?" Separate FAILED report is unambiguous. failed_step enum (`load-profiles`, `load-manifests`, `fingerprint-compare`, `generate-skill-md`, `merge-mcp-json`, `bootstrap-memory`, `write-registry`, `post-deploy-verification`, `other`) gives the user a specific failure location + recommended-fix prose. Registry updates `last_deploy_id` / `deployed_at` so Phase 6 Evolution sees the attempt but not a green status. Retry loop rejected because transient (network) vs permanent (YAML parse error) need different UX , user can re-say `retry deploy` for transient, must fix source for permanent. Silent rollback rejected because it requires a snapshot mechanism and markdown-only constraint rules out sophisticated state management.

**Files consulted:** REQUIREMENTS.md DEPLOY-06 + DEPLOY-07 + DEPLOY-08, Phase 11 D-35 (halt-and-name), ROADMAP.md Phase 12 success criterion 2.

**Prior decisions applied:** Phase 10 D-35 (halt-and-name), Phase 11 DISCOVERY-BLOCKED-REPORT.md pattern.

---

## Cross-Run Deploy History Ledger (→ D-71)

| Option | Description | Selected |
|--------|-------------|----------|
| No cross-run history, each deploy overwrites | No audit trail for re-deploys | |
| Single `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` append-only ledger | GDPR Article 30 support, minimal-overhead | ✓ |
| Per-deploy DEPLOY-REPORT-<id>.md files retained forever | Explodes file count; no query surface | |
| SQLite DB in `.agentbloc/deploy/history.db` | Over-engineered; contradicts v2.0 no-database | |

**Auto-selected:** `.agentbloc/deploy/DEPLOY_HISTORY.jsonl`, append-only, one JSON per deploy attempt (PASSED / PARTIAL / FAILED).

**Notes:** Matches OPT_IN_LEDGER.jsonl pattern from Phase 11 D-46 , append-only audit trail, GDPR Article 30 support for agent-lifecycle records. Enables Phase 6 Evolution weekly scan to compute deploy-frequency / failure-rate / time-between-deploys without crawling individual DEPLOY-REPORT.md files. Per-deploy report files are RETAINED under `.agentbloc/deploy/reports/<deployment_id>/DEPLOY-REPORT.md` (this emerges from D-68 implicitly; refined in plan-phase) so a specific historical deploy can be inspected, but the JSONL ledger is the query surface. SQLite rejected because v2.0 explicitly defers databases to v2.5+ web dashboard.

**Files consulted:** REQUIREMENTS.md DEPLOY-07, PROJECT.md "Out of Scope (v2.0)" database exclusion, Phase 11 D-46 (append-only ledger pattern).

**Prior decisions applied:** Phase 11 D-46 (OPT_IN_LEDGER.jsonl append-only pattern).

---

## Cron Configuration Approach (→ D-72)

| Option | Description | Selected |
|--------|-------------|----------|
| System cron via `claude -p` wrapper, user runs `crontab <file>` manually | Matches PROJECT.md + v1.0 security posture (Claude doesn't mutate system) | ✓ |
| Claude Code Scheduled Tasks | Desktop-only, expires after 7 days per PROJECT.md | |
| ClaudeClaw scheduled-tasks primitive (direct) | Phase 13 concern; Phase 12 can still emit the config | |
| Phase 12 writes directly to user's crontab | Violates v1.0 security posture (Claude does not mutate system state) | |

**Auto-selected:** System cron + `claude -p` per PROJECT.md Stack table. Phase 12 writes `.agentbloc/deploy/crontab.proposed` with the proposed entries; user runs `crontab .agentbloc/deploy/crontab.proposed` (or merges into existing) in their own shell. Approval-gated install pattern from Phase 10 D-37.

**Notes:** System cron is the only reliable option per PROJECT.md Stack (Claude Code Scheduled Tasks are Desktop-only and 7-day-expiring; AgentBloc primarily targets VPS / Linux). Phase 12 staying out of direct crontab-write respects v1.0 security posture matching Phase 10 D-37 approval-gated install discipline (declarative writes to user-approved files, user runs the effecting command). Entry format preserves the deployment_id in a comment for future audit. Phase 13 can refine the activation pattern (e.g., add a sentinel file to detect "was crontab installed") without Phase 12 pre-committing.

**Files consulted:** PROJECT.md § Constraints, PROJECT.md § Technology Stack ("Scheduling"), REQUIREMENTS.md DEPLOY-02, REQUIREMENTS.md RUNTIME-01.

**Prior decisions applied:** Phase 10 D-37 (approval-gated install, declarative writes).

---

## n8n Webhook Integration for Event Triggers (→ D-73)

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcode Pablo's n8n base URL in generated artifacts | Couples AgentBloc to one deployment; ships exposed secrets | |
| Skip n8n entirely; let user wire post-deploy | Drops the PROJECT.md-mandated event bus | |
| Emit webhook URL placeholder stubs + document `{{N8N_BASE_URL}}` env var | Deferred coupling; user populates post-deploy | ✓ |
| Generate an n8n workflow JSON + import instructions | Scope creep; Phase 13's concern | |

**Auto-selected:** Placeholder URL stubs (`{{N8N_BASE_URL}}/webhook/<team-name>/<agent-id>`) emitted into generated SKILL.md + registry.yaml. `.env.example` auto-append records `N8N_BASE_URL`. DEPLOY-REPORT.md "Pending User Actions" lists per-agent routes to configure in n8n.

**Notes:** PROJECT.md says n8n is already deployed on Pablo's infra , but AgentBloc ships to users who may have their own n8n or none. Hardcoding couples the tool to one deployment + leaks infra info. Per-deployment env var keeps flexibility. Phase 13 wires the actual n8n routes (RUNTIME-03); Phase 12 emits the contract surface. The `.env.example` auto-append pattern is inherited from Phase 10 D-38.

**Files consulted:** REQUIREMENTS.md DEPLOY-02, REQUIREMENTS.md RUNTIME-02, REQUIREMENTS.md RUNTIME-03, PROJECT.md § Constraints (n8n + ClaudeClaw platform).

**Prior decisions applied:** Phase 10 D-38 (.env.example auto-append for credential gaps), Phase 10 D-37 (declarative writes, user runs effecting commands).

---

## Threat Model Sweep (additive, recorded in 12-CONTEXT.md § Threat Model Notes)

Not a gray-area decision but a cross-cutting sweep during discuss-phase:

1. Credentials leaking into generated SKILL.md , mitigated by locked template anchor-point allow-list (D-62)
2. Memory.md exfiltration via agent prompt , mitigated by v1.0 prompt-injection defense reference inclusion + PII warning header in generated memory.md
3. Registry poisoning (malicious skill_path redirect) , mitigated by DEPLOY-REPORT.md idempotent_hash covering registry.yaml (D-60 detects tamper)
4. `.mcp.json` merge used to inject malicious entries via approval prompt , mitigated by full diff shown before approval (D-61) + rate-limit approval prompts per run
5. crontab.proposed tampering between emission and install , mitigated by file-level idempotent_hash (D-60) + user review at install time

**Notes:** Phase 14 CSO review MUST explicitly audit these. Documented in 12-CONTEXT.md `<threat_model_notes>` section for forward handoff.

---

## Claude's Discretion

These gray areas left to Claude's implementation-time judgment , they don't materially change phase boundary:

- Exact Jinja-lite substitution syntax (`{{agent.field}}` vs alternatives) , lean `{{agent.field}}` because it's the most-widely-recognized template syntax
- Whether DEPLOY-REPORT.md "Created" section uses a table or bulleted list , lean table (matches Phase 11 endpoints-table pattern)
- Exact autonomy-language block wording in the template (full vs semi vs supervised prose) , ship default, iterate from dogfood
- Whether to mirror `team-topology.md` Mermaid from Phase 9 into `.agentbloc/deploy/` , lean yes if present; skip if absent
- 10-second per-MCP timeout in D-69 check 2 , adjustable based on real-world latency observations; ship 10s as default
- Git-tag deploys as `git tag agentbloc-deploy-<id>` , nice-to-have, defer to post-dogfood
- Exact kill-switch pre-check prose injected into generated SKILL.md , ship 3-line block citing `.agentbloc/KILL_SWITCH` per v1.0 SECR-05; Phase 13 may refine

## Unresolved

No items flagged for user follow-up. Autonomous mode per `autonomous_mode` memo resolved all 13 gray areas using REQUIREMENTS.md + PROJECT.md + ROADMAP.md + prior-phase decisions D-1..D-58 as ground truth. One item worth surfacing at plan-phase as a "proceed unless veto":

- **D-59 (output directory override):** REQUIREMENTS.md DEPLOY-01 literal path is `skills/{agent-id}/SKILL.md`; Phase 12 ships `.claude/agents/<agent-id>/SKILL.md` instead. Rationale documented in 12-CONTEXT.md (co-location with memory dir). Plan-phase header must re-state the override so Pablo can veto before implementation. This is the highest-risk "autonomous decision against literal REQUIREMENTS.md phrasing" in the Phase 12 set.

## Deferred Ideas

Surfaced during analysis, belong to later phases or milestones (detail in [12-CONTEXT.md](12-CONTEXT.md) `<deferred>` section):

- Actual crontab registration → Phase 13 (Phase 12 emits crontab.proposed)
- n8n webhook route configuration → Phase 13
- `TeamCreate` / `SendMessage` runtime → Phase 13
- Correlation-ID propagation → Phase 13
- Kill-switch enforcement at agent wake → Phase 13
- JSONL log emission at runtime → Phase 14
- Briefing-agent daily summaries → Phase 14 (Phase 12 ships registry contract)
- Telegram approval-queue + escalation → Phase 14
- Cost tracking + task locking + status badges → Phase 14
- Anticipation-pass agents → Phase 15
- Cross-run deploy-history diff viewer → v2.5+
- SQLite migration from JSONL + per-file state → v2.5 web dashboard
- Signed artifact manifest (cryptographic provenance) → v3.0+
- Self-Healing Evolution auto-remediation → v4.0+

### Anti-features (explicitly not doing)

- Direct `crontab` write by Claude , violates v1.0 security posture (D-72 defers to user-run command)
- Overwriting `.mcp.json` without approval , violates D-37 (D-66 warns + approves)
- LLM-assembled SKILL.md content , violates Phase 16 determinism (D-62 template-based)
- Emitting partial artifacts on failure , violates halt-and-name (D-70 all-or-nothing)

---

*Log preserved: 2026-04-24. Decision audit trail for Phase 12 Deploy Pipeline + Agent Memory System. See [12-CONTEXT.md](12-CONTEXT.md) for the canonical decisions (D-59..D-73) that downstream agents consume.*
