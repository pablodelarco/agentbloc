# Phase 10: Integration Discovery — MCP Path - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Decision mode:** Autonomous (per `autonomous_mode` memo — Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + prior phases)

<domain>
## Phase Boundary

For every tool declared in `agent-profiles.yaml` (Phase 9 output), resolve it to a concrete, verified MCP server through a deterministic 4-step search: **existing `.mcp.json` entry → curated ecosystem registry → wrapper-generated MCP from public API → browser-fallback (Phase 11 scope, stubbed here)**. Emit a verification manifest that the Deploy Pipeline (Phase 12) can consume; halt cleanly on credential / scope / shape failure with a specific gap named in the conversation. Introduce the `mcp-builder` skill that generates minimal wrapper MCP servers on demand. Extend the existing v1.0 `phase-3-integration.md` to promote MCP from Priority 2 to the mandatory first path (the "MCP-first" v2.0 constraint from PROJECT.md), delegating the detailed 4-step flow to a new `mcp-integration-protocol.md` reference.

Scope note: Phase 10 ships steps 1–3 of the search (MCP path) plus the verification + evidence protocol. Step 4 (browser fallback via Patchright + HAR capture) is Phase 11's scope and only gets a stub invocation point here.

**In scope:**
- `.claude/skills/agentbloc/references/mcp-integration-protocol.md` — new reference documenting the 4-step search + verification loop + evidence protocol (structural twin of `phase-3-integration.md`, but scoped to the MCP path only)
- `.claude/skills/agentbloc/references/mcp-ecosystem-registry.md` — new reference with a curated registry of known MCP servers (seeded from CLAUDE.md "MCP Server Ecosystem: Verified Available" tables); each entry carries package, trust tier, last-commit, publisher, required scopes, tools declared
- `.claude/skills/agentbloc/references/integration-manifest-schema.md` — new reference defining the `.agentbloc/integrations/integration-manifest.yaml` schema + prose-checklist validator (twin of `business-graph-schema.md` and `agent-profile-schema.md`)
- `.claude/skills/mcp-builder/SKILL.md` — new top-level skill (NOT inside agentbloc) that generates a minimal TypeScript MCP server from a public-API spec into `.mcp/generated/<tool-id>/`
- `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` — canonical fixture showing 3 tools resolving via the 3 different methods (existing / ecosystem / wrapper); browser-fallback case is Phase 11's fixture
- Surgical edits to `references/phase-3-integration.md` — promote MCP to Priority 1, link to `mcp-integration-protocol.md` for the full protocol, preserve the other priority tiers for Phase 11 browser-fallback
- `SKILL.md` Phase 3 extensions — add `mcp_integrations_verified` gate value, extend Phase 3 unconditional-load list, add Phase 4 precondition on the integration manifest

**Out of scope (belongs to later phases):**
- Browser-fallback step 4 (Playwright + Patchright + HAR + injection detector + PII redaction) → Phase 11 (BROWSER-01..12)
- Actually executing `npx -y @mcp/xxx` installs (Claude only updates `.mcp.json` declaratively; the user runs install commands in their own shell) → matches v1.0 security posture, no shell execution by Claude
- Runtime verification of MCP responses in a deployed system → Phase 13 (RUNTIME) monitoring
- Telegram-delivered credential prompts for missing scopes → Phase 14 (AUTON-02, escalation UX)
- Generating production-grade MCP wrappers with tests + CI + npm publishing → v3.0 Builder Agent (explicitly deferred in REQUIREMENTS.md § Deferred to v3.0+)
- Cross-run diff of integration manifests for drift detection → v2.5+ (REQUIREMENTS.md § Deferred to v2.5+)

</domain>

<decisions>
## Implementation Decisions

### Inherited from Phase 8 / Phase 9 / v1.0 (carry forward — do not re-decide)

- **Inherited D-11 (Phase 8):** Artifact emission lives in a gate, not a separate subagent flow. The integration manifest is the Phase 3 Summary gate output — same pattern as Business Graph and agent-profiles.
- **Inherited D-13 (Phase 8):** Validators are prose-checklists inside the schema reference file. No `ajv`, no `jsonschema`, no external YAML linter as a hard dep. `integration-manifest-schema.md` uses the same prose-checklist structure.
- **Inherited D-14 (Phase 8):** User confirms a **rendered table** of integrations; the manifest YAML is written silently.
- **Inherited D-15 (Phase 8 + PDF):** File location for deployment artifacts is `.agentbloc/` — integration manifest lives at `.agentbloc/integrations/integration-manifest.yaml`; generated wrappers live at `.mcp/generated/<tool-id>/` (per PDF § "Descubrimiento de Integraciones — 4 pasos").
- **Inherited D-18 (Phase 8):** Bounded enums are the preferred shape for discriminated unions. `resolution_method` uses the same bounded-enum pattern.
- **Inherited D-21 (Phase 9):** Claude Code subagents / skills with scoped tools and no Bash are the default. `mcp-builder` follows this posture (Read, Grep, Glob, Write scoped to `.mcp/generated/*`, plus `WebFetch` for API docs; no Bash).
- **Inherited D-22 (Phase 9):** Three-tier field obligation (REQUIRED / RECOMMENDED / OPTIONAL) with `schema_version: 1` integer.
- **Inherited D-29 (Phase 9):** SKILL.md extensions are surgical — one gate-value addition + one precondition addition + two load-list extensions per phase. Budget: SKILL.md stays under 250 lines.
- **Inherited v1.0 INTG-01..08 protocol:** Search priority chain, trust scoring (HIGH/MEDIUM/LOW), evidence verification (URL + version + last-commit + publisher), `[UNVERIFIED]` status marker, decision matrix presentation, credential cross-reference, prompt-injection layer assignment. Phase 10 extends — does not replace — this protocol.

### New decisions (autonomous, per PDF + REQUIREMENTS + prior phases)

#### Four-step search protocol contract

- **D-31 (Split into two reference files: protocol + registry):** Mirror the Phase 8/9 pattern of `business-graph-schema.md` / `agent-profile-schema.md` (contract shape) and `orchestration-patterns.md` (decision tables). Phase 10 ships three reference files:
  - `mcp-integration-protocol.md` — the 4-step search flow, verification loop, credential gap handling, decision matrix extension
  - `mcp-ecosystem-registry.md` — curated registry seeded from the `CLAUDE.md` "MCP Server Ecosystem" tables (Telegram, Slack, Google Workspace, Xero, Bank, Playwright, etc.)
  - `integration-manifest-schema.md` — the output artifact contract (twin of the Business Graph / agent-profiles schemas)

  **Rationale:** Separation of concerns. Protocol reference = imperative flow Claude follows. Registry reference = declarative lookup table Claude consults. Schema reference = contract the output must satisfy. Matches the "single source of truth per shape" principle established in Phase 8/9.

#### mcp-builder skill architecture

- **D-32 (Top-level skill at `.claude/skills/mcp-builder/`, not nested under agentbloc):** `mcp-builder` is a **composable utility** — AgentBloc invokes it during Phase 3, but nothing in the skill is AgentBloc-specific. A future ClaudeClaw deployment, a different skill suite, or a standalone user could reuse it. Nesting it under `.claude/skills/agentbloc/` would couple the two and violate Claude Code skill composability norms.

  **Rationale:** Follows the official skill authoring principle from CLAUDE.md ("progressive disclosure via references/ directory") applied at the skill-hub level — each skill is self-contained, skills can compose. Also signals that the generator is stable enough for other projects to depend on.

- **D-33 (Wrapper MCP stack: TypeScript + `@modelcontextprotocol/sdk` + Bun executor):** Generated wrappers are single-file TypeScript servers using the official Anthropic MCP TypeScript SDK, executed by Bun. Output shape per generated tool:

  ```
  .mcp/generated/<tool-id>/
  ├── package.json          # name, version, deps (@modelcontextprotocol/sdk only)
  ├── index.ts              # MCP server implementation with 1-N tool handlers
  └── README.md             # what API it wraps, required env vars, tool surface
  ```

  **Rationale:** (a) Matches ClaudeClaw runtime (TypeScript + Bun per PROJECT.md constraint), (b) `@modelcontextprotocol/sdk` is the official reference SDK, (c) single-file keeps the generator template small (under 200 lines of Claude-generated code per tool), (d) Bun avoids the npm-install-every-time friction that a Node-based wrapper would have. No Python path because ClaudeClaw is TS-native.

- **D-33b (Wrapper MCP tool surface = minimum viable for the agent's contract):** The generator reads the calling agent's `outputs.schema` and `tools[]` entry from `agent-profiles.yaml` and generates ONLY the endpoints that agent needs. A "Gmail wrapper" for an agent that only reads unread messages exposes exactly one tool: `list_unread(since_iso)`. Not a full Gmail API surface.

  **Rationale:** Keeps wrapper surface small (less attack surface, less to verify), respects the v1.0 "least privilege" credential posture, and lets Phase 10 verification actually test the generated wrapper end-to-end (you can probe one tool; you cannot probe every Gmail endpoint).

#### Verification protocol

- **D-34 (Three-check prose-checklist verification, Markdown-only):** Every tool entry in the manifest must pass all three checks before `verified_at` is stamped:

  1. **Ping** — MCP server responds to `tools/list` and declares at least one tool. Failed ping = "server does not start" → manifest entry gets `resolution_method: failed` and specific error.
  2. **Scope match** — the declared tool names intersect the agent's `tools[]` array AND every declared tool's required credential scope is present in `.env` (or `.env.example` has a stub). Missing credential = pipeline halt with the specific env var name quoted.
  3. **Shape probe** — call the tool with a dry-run argument set and verify the response shape matches `outputs.schema` in the agent profile. Mismatch = surface both shapes side-by-side to the user.

  All three checks are prose steps Claude executes; no new runtime dependency. The protocol reference file embeds the exact checklist. TAP tests in Phase 16 harden this against canned manifests.

  **Rationale:** Matches the "prose-checklist validator" pattern from D-13 (Phase 8). Three checks cover (a) liveness, (b) authorization, (c) correctness — which is exactly what INTEG-04 asks for ("responds + has scopes + returns expected shape"). Markdown-only preserves the AgentBloc skill constraint.

- **D-35 (Halt-and-name protocol for verification failures, per INTEG-05):** When any of the three checks fails, Claude does the following in one turn:
  1. Write `.agentbloc/integrations/<tool-id>/VERIFICATION-FAILED.md` with the failing check + quoted failure + recommended fix
  2. Update manifest entry to `status: failed` + `failure_reason: <specific-check>`
  3. Block the Phase 3 gate (state bar moves to `blocked`)
  4. Surface a targeted conversation: "The `gmail-mcp` server is installed but the `GOOGLE_OAUTH_TOKEN` scope is missing `gmail.modify`. Add that scope to your Google OAuth consent screen, or I can reduce the agent's scope to read-only — which do you prefer?"

  The pipeline does NOT silently degrade or proceed with a partially-verified integration.

  **Rationale:** INTEG-05 explicitly forbids silent failures. Specific-gap messaging is the v1.0 "specific failure, not generic" principle applied. Writing a `VERIFICATION-FAILED.md` gives the user a paper trail they can share when asking Pablo / support / an LLM for help.

#### Integration manifest artifact

- **D-36 (New artifact at `.agentbloc/integrations/integration-manifest.yaml`, NOT an extension of `agent-profiles.yaml`):** Separate file. Keeps Designer's output (Phase 9) stable across re-verification runs — if a wrapped MCP server starts failing a month from now and we need to re-verify, we rotate the manifest without touching the Designer-emitted profiles.

  Schema (full shape in `integration-manifest-schema.md`):
  ```yaml
  schema_version: 1
  generated_at: "ISO-8601"
  modified_at: "ISO-8601"                       # bumped on every re-verification
  tools:
    - tool_id: "gmail"
      resolution_method: "existing | ecosystem | wrapper | browser-fallback | failed"
      mcp_server:
        package: "@smithery-ai/gmail-mcp"      # or path for wrapper
        version: "0.3.1"                        # package version or wrapper commit
        installed_via: "npx -y @smithery-ai/gmail-mcp"  # or "wrapper" or ".mcp.json existing"
      evidence:
        url: "https://github.com/smithery-ai/gmail-mcp"
        last_commit: "2026-03-20"
        publisher: "smithery-ai"
        trust_tier: "MEDIUM"                    # HIGH | MEDIUM | LOW per v1.0 INTG-04
        tools_declared: ["list_unread", "send_message"]
        required_scopes: ["gmail.readonly"]
        healthcheck_at: "2026-04-21T17:42:00Z" # ISO timestamp of successful verification
      used_by: ["recepcionista"]
      status: "verified | failed | pending"
      failure_reason: null                      # populated when status=failed
  ```

  **Rationale:** (a) Idempotent — re-running Phase 3 does not mutate Designer's output, it mutates verification state. (b) Deploy Pipeline (Phase 12) has one place to look for "is this integration ready." (c) Survives agent profile edits (DSGN-07) — if the user renames an agent, the manifest's `used_by` gets updated, not regenerated.

#### Install-flow discipline

- **D-37 (Approval-gated install, declarative `.mcp.json` writes only; Claude never runs install commands):** For ecosystem path (INTEG-02), Claude:
  1. Presents the `npx -y @mcp/xxx` command + trust tier + evidence in the conversation
  2. Waits for explicit user approval
  3. On approval, writes the MCP entry into `.mcp.json` via the Edit tool — Claude does NOT execute `npx` itself
  4. Tells the user: "Run this command in your shell: `npx -y @mcp/xxx`, then say `installed` when done"
  5. Verification (D-34 checks) runs after the user confirms install

  **Rationale:** Matches v1.0 security posture — Claude does not execute arbitrary shell commands that mutate the user's environment, especially package installs. `npx` download + execute is a real supply-chain attack surface (the package could run arbitrary install scripts). Keeping the install as a user action preserves the auditable boundary. `.mcp.json` is declarative config — safe for Claude to edit.

#### Credential gap UX

- **D-38 (Halt + `.env.example` auto-append; Telegram prompts are Phase 14 work):** When a required scope is missing, Claude:
  1. Writes the missing env var name to `.env.example` with a comment `# required by <agent-id> for <mcp-server> scope <scope-name>`
  2. Halts the Phase 3 gate (blocked state)
  3. Surfaces the conversation: "Add `AGENTBLOC_GMAIL_OAUTH_TOKEN` to your `.env` file (see `.env.example` for the schema), then say `credentials added`"
  4. On user confirmation, re-runs D-34 verification on that tool

  Phase 10 stays in the interactive conversation. Telegram-delivered credential prompts are a Phase 14 AUTON concern (escalation UX).

  **Rationale:** (a) Minimizes new UX surface in Phase 10 — the interactive conversation is already the UX. (b) `.env.example` auto-append gives the user a checklist that survives session boundaries. (c) Phase 14's Telegram escalation will eventually subsume this for deployed agents, but Phase 10 is about design-time verification, not runtime.

#### Evidence protocol (extends v1.0 INTG-03)

- **D-39 (Evidence record extended with MCP-specific fields; v1.0 evidence carries forward):** The v1.0 evidence protocol (URL + package version + last-commit date + publisher) stays. v2.0 adds four MCP-specific fields for every entry:
  - `tools_declared[]` — result of the verification `tools/list` call
  - `required_scopes[]` — credential scopes declared by the MCP server (or inferred from its README)
  - `healthcheck_at` — ISO timestamp when all three D-34 checks last passed
  - `trust_tier` — HIGH / MEDIUM / LOW per v1.0 INTG-04 trust scoring, re-evaluated at each verification

  Missing any field = `[UNVERIFIED]` per v1.0 INTG-06 (inherited). `[UNVERIFIED]` entries can still be accepted by the user (override), but the manifest carries the flag forward for audit.

  **Rationale:** INTEG-06 explicitly asks the v1.0 evidence protocol to carry forward. The four new fields are MCP-specific verification state that didn't exist in v1.0's API-first framing. Together they give Phase 12 Deploy Pipeline everything it needs to decide "is this tool production-ready."

#### Relationship to v1.0 `phase-3-integration.md`

- **D-40 (Surgical extension, not replacement; MCP promoted from Priority 2 to Priority 1):** The v1.0 Phase 3 integration reference (388 lines) stays. Phase 10 ships three surgical edits:
  1. **Priority ladder reorder** — MCP Server moves from Priority 2 to Priority 1. Official API moves from Priority 1 to Priority 2 (fallback when no MCP exists or can be generated). Justified by PROJECT.md constraint: "every external integration goes through an MCP server."
  2. **MCP section refactor** — the existing "Priority 2: MCP Server" section becomes the new "Priority 1: MCP Server (Four-Step Search)" section. Delegates full detail to `mcp-integration-protocol.md` via a See-line; preserves the summary in place so users scanning `phase-3-integration.md` understand the contract without jumping files.
  3. **Browser-fallback stub** — the existing "Priority 3: Playwright Browser Automation" section gets a `[Phase 11 scope]` marker + See-line pointing forward to the Browser-fallback work. Phase 11 can then refine it without Phase 10 pre-committing to the browser protocol.

  Other v1.0 content — evidence verification, trust scoring, decision matrix construction, credential cross-reference, prompt-injection assessment, integration presentation — stays verbatim. Phase 10 does NOT re-litigate those decisions.

  **Rationale:** Preserves 388 lines of v1.0 prose that's still correct. Surgical edits keep the diff reviewable and respect the Phase 9 D-29 budget discipline ("small additive edits to existing references").

#### SKILL.md Phase 3 extensions

- **D-41 (Mirror of D-29 Phase 9 pattern — three surgical edits to SKILL.md):**
  1. **State Transitions paragraph:** add "Phase 3 specific" bullet naming the `mcp_integrations_verified` sub-gate (sibling of `business_graph_validated` and `agent_profiles_validated`). Requires all REQUIRED checks from `integration-manifest-schema.md` + every tool entry has `status: verified` + `healthcheck_at` timestamp.
  2. **Phase 3 entry:** extend unconditional-load list with `mcp-integration-protocol.md` + `mcp-ecosystem-registry.md` + `integration-manifest-schema.md`. Add Summary gate note: after the 4-step search completes, write `.agentbloc/integrations/integration-manifest.yaml` silently; render the integrations table for user confirmation per D-14.
  3. **Phase 4 entry:** add precondition — verify `.agentbloc/integrations/integration-manifest.yaml` exists AND every entry has `status: verified`. If any entry is `status: failed` or missing, return state bar to Phase 3 `pending`.

  **Rationale:** Exact mirror of the Phase 8/9 pattern. SKILL.md stays under 250 lines (currently 170; +~12 lines for this extension puts it at ~182, still 68 lines of headroom).

#### Canonical fixture

- **D-42 (Fixture at `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml`, shows all three MCP resolution methods):** The Arco Rooms 3-agent team (Gestor Cobros, Recepcionista, Gestor Documental, from Phase 9 D-30) needs a total of ~8 tools across the agents (bbva, gmail, google-calendar, google-drive, telegram, xero, notion, google-sheets). Fixture shows:
  - ~3 tools resolving via **existing `.mcp.json`** (e.g., playwright-mcp already present because of gstack)
  - ~3 tools resolving via **ecosystem registry** (e.g., `@smithery-ai/gmail-mcp`, `@google-workspace-mcp/calendar`)
  - ~2 tools resolving via **wrapper generation** (e.g., BBVA — no ecosystem MCP exists, PSD2 API wrapper generated; Arco Rooms' custom reservation API)

  Browser-fallback case is NOT in this fixture — Phase 11 ships its own fixture for that.

  **Rationale:** Covers the three happy paths in one fixture. Makes Phase 10 verification deterministic (same input profile → same manifest output modulo timestamps). Phase 16 end-to-end TAP test replays this exact fixture.

### Plan shape projection (3 plans)

This is the planner's decision, but autonomous rationale points strongly toward:

- **Plan 10-01 (contracts):** Create the 3 new references (`mcp-integration-protocol.md`, `mcp-ecosystem-registry.md`, `integration-manifest-schema.md`) + Arco Rooms integration manifest fixture. No SKILL.md edits. No wiring. Pure contracts + fixture.
- **Plan 10-02 (mcp-builder skill):** Create `.claude/skills/mcp-builder/SKILL.md` with the wrapper-generation protocol + a smoke-test example (generates one trivial wrapper from an OpenAPI spec to prove the skill works). No AgentBloc wiring yet.
- **Plan 10-03 (wiring):** Surgical edits to `phase-3-integration.md` (D-40) + surgical edits to `SKILL.md` Phase 3/4 (D-41). Wires the new references + skill + manifest into the user-facing flow.

Matches the Phase 8/9 "contract-first, wiring-second" rhythm precisely. Planner should confirm 3 plans in gsd-plan-phase.

### Claude's Discretion

- Exact wording of the 4-step search protocol prose in `mcp-integration-protocol.md` — ship a default, adjust from dogfooding
- Registry curation depth in `mcp-ecosystem-registry.md` — seed from CLAUDE.md ecosystem table (~20 entries is enough to start); additions land via PRs / user feedback, not a v2.0 concern
- Wrapper template style in `mcp-builder/SKILL.md` — single-file TS with inline comments vs split into handlers.ts + server.ts; lean: single-file for simplicity, split later if any wrapper grows past 300 lines
- Exact trust-tier bumps between v1.0 and v2.0 — keep v1.0 thresholds (>500 stars + commit <90 days = HIGH); re-evaluate during Phase 16 verification if the thresholds feel wrong against real ecosystem data
- Whether `mcp-builder` emits `package.json` with a `@mcp/<tool-id>` scoped name or a bare name — lean: bare name (e.g., `agentbloc-wrapper-bbva`) to avoid polluting the `@mcp/` npm scope with user-generated code
- Mermaid diagram of the 4-step search flow in `mcp-integration-protocol.md` — nice-to-have; include if it fits under 30 lines

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope Authority
- `.planning/v2.0-PROMPT.pdf` — v2.0 ground truth; **page 1 describes the 4-step integration discovery flow**, the MCP-first constraint, and the `.agentbloc/integrations/` convention
- `.planning/REQUIREMENTS.md` § Integration Discovery (INTEG-01..06) — the 6 requirements this phase satisfies
- `.planning/PROJECT.md` § Constraints — "MCP-first: every external integration goes through an MCP server" (the load-bearing positioning decision)
- `/Users/pablodelarco/agentbloc/CLAUDE.md` § "MCP Server Ecosystem: Verified Available" — the seed data for `mcp-ecosystem-registry.md` (Telegram / Slack / Google Workspace / Xero / Bank / Playwright / etc.)

### v2.0 Artifacts This Phase Consumes (from Phase 9)
- `.claude/skills/agentbloc/references/agent-profile-schema.md` — defines `tools[]` and `outputs.schema` per agent; Phase 10 reads these fields to know what to verify
- `.claude/skills/agentbloc/examples/arco-rooms-agent-profiles.yaml` — canonical input fixture; Phase 10 fixture is the verification manifest for these exact agents

### v1.0 Artifacts Being Extended
- `.claude/skills/agentbloc/references/phase-3-integration.md` (388 lines) — target of the surgical edits in D-40; MCP promoted to Priority 1, browser-fallback stubbed for Phase 11
- `.claude/skills/agentbloc/references/credentials.md` (117 lines) — referenced by D-34 scope-match check + D-38 credential gap UX
- `.claude/skills/agentbloc/references/prompt-injection.md` (178 lines) — referenced by the verification protocol (injection-defense layer assignment per MCP ingestion pattern)
- `.claude/skills/agentbloc/SKILL.md` (170 lines) — Phase 3 + Phase 4 entries + State Transitions paragraph get the D-41 surgical edits

### Prior Phase Context (carry-forward decisions)
- `.planning/phases/08-business-graph-foundation/08-CONTEXT.md` — D-11, D-13, D-14, D-15, D-18 apply structurally
- `.planning/phases/09-designer-agent/09-CONTEXT.md` — D-21, D-22, D-29, D-30 apply; agent-profiles.yaml shape is the input contract
- `.planning/milestones/v1.0-phases/04-integration-and-confirmation-phases/04-CONTEXT.md` — v1.0 INTG-01..08 decisions (search priority, evidence protocol, trust scoring) inherited wholesale

### New Files To Be Created (plan-phase will materialize)
- `.claude/skills/agentbloc/references/mcp-integration-protocol.md` — 4-step search + verification protocol
- `.claude/skills/agentbloc/references/mcp-ecosystem-registry.md` — curated MCP registry, trust-scored
- `.claude/skills/agentbloc/references/integration-manifest-schema.md` — manifest schema + prose-checklist validator
- `.claude/skills/mcp-builder/SKILL.md` — top-level wrapper-generator skill
- `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` — canonical 8-tool fixture showing existing / ecosystem / wrapper resolution paths

### Reference Examples (for shape testing)
- `.planning/v2.0-PROMPT.pdf` page 1 § "Descubrimiento de Integraciones — 4 pasos" — the canonical flow description
- `.planning/research/STACK.md` / `.planning/research/ARCHITECTURE.md` — 2026-04-18 Discovery Agent research; informs the browser-fallback STUB (not the full implementation, that's Phase 11)

### External Documentation Pointers
- `@modelcontextprotocol/sdk` — the official Anthropic MCP TypeScript SDK, used by `mcp-builder` wrappers (fetch latest usage via Context7 during Plan 10-02 research)
- Model Context Protocol specification (`modelcontextprotocol.io`) — transport + tool declaration shape; needed only if a generated wrapper uncovers an edge case the SDK hides

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `references/phase-3-integration.md` (388 lines) — v1.0 integration protocol with 6-method priority chain, evidence verification, trust scoring (HIGH/MEDIUM/LOW), decision matrix template, Step 6 security cross-reference to credentials.md + prompt-injection.md. **Phase 10 keeps everything and surgically reorders Priority 1/2 per D-40.**
- `references/business-graph-schema.md` (137 lines, Phase 8) + `references/agent-profile-schema.md` (178 lines, Phase 9) — structural twins for `integration-manifest-schema.md`. Same H1 + blockquote + TOC + "When This Applies" + schema definition + field obligation matrix + bounded enums + validation checklist + Quick Reference.
- `references/orchestration-patterns.md` (121 lines, Phase 9) — structural twin for `mcp-integration-protocol.md` (imperative flow reference; table-driven; "When This Applies" + "Quick Reference").
- `references/frameworks.md` (126 lines, v1.0) — structural twin for `mcp-ecosystem-registry.md` (curated table of named tools with evidence columns).
- `references/credentials.md` (117 lines, v1.0) — D-34 scope-match check delegates to this credential decision tree; D-38 credential gap UX references this for env var naming + rotation policy.
- `SKILL.md` (170 lines) — has the `business_graph_validated` + `agent_profiles_validated` gate-value pattern, Phase entry unconditional-load pattern, Phase precondition pattern. All reusable for Phase 10 (`mcp_integrations_verified`).
- `examples/arco-rooms-agent-profiles.yaml` (Phase 9 fixture) — the input to Phase 10 verification; agents + tools list + output schemas drive the manifest entries.
- `.claude/agents/designer-agent.md` (Phase 9, 145 lines) — NOT reused directly but demonstrates the "new Claude Code subagent" shape (YAML frontmatter + tool scoping + backstory) that `mcp-builder` will mirror if it ends up needing to be a subagent vs a skill.

### Established Patterns
- **Prose-checklist validator (Phase 8 D-13):** Validator lives inline in the schema reference file as an ordered prose checklist. No external tooling. Applied to the integration manifest schema.
- **Silent artifact + rendered table review (Phase 8 D-14):** User confirms the integrations table; the manifest YAML is written silently.
- **Artifact in `.agentbloc/` hierarchy (Phase 8 D-15 + PDF):** `.agentbloc/integrations/integration-manifest.yaml` (machine-written) + `.agentbloc/integrations/<tool-id>/VERIFICATION-FAILED.md` (diagnostic).
- **Bounded enum for method discrimination (Phase 8 D-18):** `resolution_method` ∈ `{existing, ecosystem, wrapper, browser-fallback, failed}` — same enum-driven control flow as `trigger.type`.
- **Three-tier field obligation (Phase 9 D-22):** REQUIRED / RECOMMENDED / OPTIONAL applies to manifest entries.
- **Subagent / skill with scoped tools, no Bash (Phase 9 D-21):** `mcp-builder` gets Read + Grep + Glob + Write (scoped to `.mcp/generated/*`) + WebFetch (for API docs). No Bash.
- **Surgical edits to existing references (Phase 9 D-29):** Phase 3 wiring = small additive paragraphs + See-lines, not rewrites. SKILL.md diff stays under 15 lines.

### Integration Points
- `SKILL.md` State Transitions paragraph: add "Phase 3 specific" bullet (mirror of Phase 1/2 bullets) naming `mcp_integrations_verified` sub-gate
- `SKILL.md` Phase 3 entry: extend unconditional-load list with 3 new references; add Summary gate note about manifest emission
- `SKILL.md` Phase 4 entry: add precondition verifying integration manifest exists + all entries verified
- `phase-3-integration.md` Step 2 "Multi-Method Search Protocol" section: surgical reorder of the priority ladder per D-40
- `phase-3-integration.md` Priority 2 MCP section: become Priority 1, delegate to `mcp-integration-protocol.md`
- `phase-3-integration.md` Priority 3 Playwright section: mark `[Phase 11 scope]`, keep summary
- `.agentbloc/integrations/` directory: new; created on first Phase 3 run
- `.mcp/generated/` directory: new; created by `mcp-builder` on first wrapper generation

</code_context>

<specifics>
## Specific Ideas

- **The manifest is a contract with Phase 12 (Deploy Pipeline).** Phase 12's quality ceiling is determined by how complete this manifest is. Every field Phase 12 needs to generate a valid `.mcp.json` merge + valid ClaudeClaw job config must be present or derivable. D-36's schema enumerates what Phase 12 cannot degrade on (package + version + resolution_method + status + healthcheck_at).
- **The 4-step search is deterministic per input.** Same agent-profiles.yaml + same `.mcp.json` state + same ecosystem registry should produce the same manifest modulo timestamps. Phase 16 TAP verification depends on this — if the search picks up non-determinism (e.g., calling `npm view` mid-search), Phase 16 testing becomes flaky.
- **`mcp-builder` is the first AgentBloc skill that generates executable code.** Until Phase 10, every AgentBloc output was Markdown/YAML/JSON. A generated TypeScript MCP server changes the trust surface — the user must be able to review the generated code easily. D-33's single-file constraint helps; so does the `README.md` that ships alongside each wrapper explaining what API surface was exposed.
- **Trust tier drift is real.** An MCP that was HIGH at verification time might drop to MEDIUM 6 months later if the publisher goes dark. `healthcheck_at` + `trust_tier` in the manifest give Phase 6 Evolution (v1.0, carry-forward) a signal to re-verify on a cadence (weekly scan per v1.0 EVOL-02). Phase 10 does NOT implement the re-verification loop — that lives in Phase 6 Evolution or the v2.5 drift detector — but the manifest schema supports it.
- **MCP-first is a positioning constraint, not a technical one.** There are workflows where a direct REST call or a webhook is objectively better than wrapping them in an MCP. The PROJECT.md constraint says "go through MCP" because it keeps the agent's tool surface uniform (same `tools/list` shape regardless of backend) and makes audit logging single-source. Phase 10's 4-step search honors this by making even custom wrappers an MCP. Where an MCP truly doesn't fit (e.g., trigger on SMS), the fallback is browser-automation MCP (Playwright MCP wraps the UI). Phase 10 never breaks the MCP envelope.
- **The `[UNVERIFIED]` flag survives manifest emission.** If the user overrides and accepts a tool with missing evidence (e.g., a new MCP with 20 GitHub stars), the manifest carries `trust_tier: LOW` + a note. Phase 12 Deploy Pipeline surfaces this in `DEPLOY-REPORT.md` so the audit trail preserves the decision.

</specifics>

<deferred>
## Deferred Ideas

- **Production-grade wrapper MCP (tests + CI + npm publishing):** deferred to v3.0 Builder Agent (explicit in REQUIREMENTS.md § Deferred to v3.0+). Phase 10 ships single-file-for-one-tool wrappers — good enough for Phase 16 validation, not good enough for npm.
- **Cross-run manifest diff (drift detection):** deferred to v2.5+. Phase 10 writes the manifest; Phase 6 Evolution (v1.0 EVOL-02) is the current re-verification cadence layer. A proper diff viewer with "what broke since last week" belongs to the web dashboard.
- **Self-healing re-discovery when MCP fails:** deferred to v4.0 (explicit in REQUIREMENTS.md § Deferred to v4.0+). Current Phase 10 halt-and-name is the manual path; v4.0 auto-triggers rediscovery.
- **Auto-install via `npx`:** explicitly rejected (D-37). Shell execution by Claude violates the v1.0 security posture. Always user-driven.
- **Telegram-delivered credential prompts:** explicitly deferred to Phase 14 AUTON (D-38). Phase 10 uses the interactive conversation.
- **Browser-fallback (INTEG-step-4):** deferred to Phase 11 BROWSER-01..12. Phase 10 stubs a `browser-fallback` enum value + a See-line but does not implement the flow.
- **Per-tool rate-limit enforcement:** interesting but belongs to Phase 14 CTRL (cost tracking + rate limiting live together). Phase 10 captures rate-limit info in `mcp-ecosystem-registry.md` descriptions but doesn't enforce.
- **MCP server sandboxing / OS-level isolation:** deferred to OpenClaw substrate evaluation (explicit in REQUIREMENTS.md § Deferred to v3.0+).
- **Localized registry (ES-speaking MCP servers):** the registry is English-only (tool names + descriptions). Bilingual role / goal in agent profiles is Phase 9 work; registry descriptions stay English for now. Reconsider at v3.0.
- **Lazy-load pattern for Phase 3 companion refs (plan-eng-review P-1, forward-looking):** Phase 3 unconditional load after Phase 10 ships is ~966 lines (phase-3-integration.md 406 + mcp-integration-protocol.md 180 + mcp-ecosystem-registry.md 180 + integration-manifest-schema.md 200). This is a 58% growth over Phase 2's ~612-line unconditional load and consistent with the Phase 8/9 pattern. `mcp-ecosystem-registry.md` is a lookup table Claude consults only at Step 2, and `integration-manifest-schema.md` is read primarily at the Summary Gate. Either could be lazy-loaded on demand instead of at Phase 3 entry. Phase 10 preserves unconditional-load for consistency with prior phases; Phase 11 planning should revisit this if Phase 3's total context load exceeds a budget threshold (suggested: 1,200 lines). Not a blocker; recorded for pattern evolution.

</deferred>

---

*Phase: 10-integration-discovery-mcp-path*
*Context gathered: 2026-04-21*
*Decision mode: autonomous (Pablo-authorized). All decisions above are mine to defend; Pablo retains veto on any he disagrees with — raise early if so.*
