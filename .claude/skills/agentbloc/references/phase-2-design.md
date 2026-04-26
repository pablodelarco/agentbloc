# General Design Protocol

> Loaded by SKILL.md at Phase 2 entry. Translates the confirmed interview summary into a complete agent team design with topology, contracts, governance, and security scoring.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Design Opening](#design-opening)
- [Step 1: Agent Identification (DESG-01)](#step-1-agent-identification-desg-01)
- [Step 2: Topology Selection (DESG-02)](#step-2-topology-selection-desg-02)
- [Step 3: Per-Agent Contracts (DESG-03)](#step-3-per-agent-contracts-desg-03)
- [Step 4: Schedule and Trigger Definitions (DESG-04)](#step-4-schedule-and-trigger-definitions-desg-04)
- [Step 5: Governance Specification (DESG-05)](#step-5-governance-specification-desg-05)
- [Step 6: Blast-Radius Scoring (DESG-06)](#step-6-blast-radius-scoring-desg-06)
- [Step 7: Visual Presentation (DESG-08)](#step-7-visual-presentation-desg-08)
- [Design Gate](#design-gate)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file when the user confirms the interview summary (Phase 1 gate approved) and Phase 2 begins. The interview summary provides the raw material: business context, workflow steps, services, data classification, people, edge cases, reporting preferences, and constraints. This protocol transforms that material into a deployable agent team design.

## Design Opening

You have the confirmed Business Graph. Before starting design, also load [references/blast-radius.md](blast-radius.md), [references/frameworks.md](frameworks.md), [references/orchestration-patterns.md](orchestration-patterns.md), and [references/agent-profile-schema.md](agent-profile-schema.md). The Security Profile from the Business Graph tells you which compliance regimes are active.

The running data classification tally from the interview informs blast-radius scoring and governance constraints throughout design. If the interview identified PII, PHI, or financial data, those classifications carry forward into every agent contract and governance decision in this phase.

## Step 1: Agent Identification (DESG-01)

Each agent does exactly one job. If you find yourself writing "and also" in an agent's description, split it into two agents. This follows the CrewAI role-based decomposition pattern (see [references/frameworks.md](frameworks.md) for the full role, backstory, goal structure).

### Identification Process

1. **List all actions** from the confirmed interview summary. Every verb the workflow performs becomes a candidate action (collect, match, send, validate, report).
2. **Group related actions** that share the same data context. Actions reading from the same source and writing to the same destination belong together.
3. **Each group becomes one agent.** If a group has actions that require different permission levels (reading vs. sending externally), split further.
4. **Name by function.** Use descriptive role-based names: "Invoice Collector", "Payment Matcher", "Report Sender". Never use generic names like "Agent 1" or "Main Agent".
5. **Verify no overlap.** Each action maps to exactly one agent. If two agents could claim the same action, assign it to whichever has the lower blast-radius level.

### Naming Conventions

- Format: `{Action} {Domain}` or `{Domain} {Action}` (e.g., "Invoice Collector", "Payment Matcher")
- Lowercase with hyphens for technical identifiers: `invoice-collector`, `payment-matcher`
- Display names use title case for user-facing presentation

### Example: Arco Rooms

The Arco Rooms property management system (see [examples/arco-rooms.md](../examples/arco-rooms.md)) decomposes into three agents:

| Agent | Responsibility | Blast Radius |
|-------|---------------|--------------|
| Invoice Collector | Fetches invoices from 6 utility providers via API, email, or browser | Level 2 (write-scoped) |
| Payment Matcher | Matches bank transactions to invoices and tenants | Level 2 (write-scoped) |
| Report Sender | Sends daily summary and alerts via Telegram | Level 4 (send-external) |

## Step 2: Topology Selection (DESG-02)

### Decision Tree

Follow these steps in order:

1. **Count the agents** identified in Step 1.
2. **1 to 3 agents with sequential flow** (each agent's output feeds the next): select **Pipeline**.
3. **3 to 5 agents with a clear coordinator** directing work and collecting results: select **Hierarchy**.
4. **3 to 8 agents iterating on shared artifacts** where each agent refines the previous output: select **Mesh**.
5. **Agents exploring independently** with unknown or branching paths, results merged later: select **Swarm**.
6. **When in doubt:** default to **Pipeline**. It is the simplest, most debuggable, and covers 80% of SMB workflows.

### Topology Reference

| Topology | Pattern | When to Use | Agent Count | Complexity |
|----------|---------|-------------|-------------|------------|
| Pipeline | A -> B -> C | Sequential stages, clear input/output chain | 1-3 | Low |
| Hierarchy | Coordinator + workers | Centralized coordination, fan-out/fan-in | 3-5+ | Medium |
| Mesh | Peer-to-peer, shared artifacts | Iterative refinement, multi-perspective analysis | 3-8 | High |
| Swarm | Autonomous exploration | Unknown paths, parallel collection, research tasks | 5+ | Highest |

### Recommendation Protocol

Present ONE recommended topology with a clear rationale tied to the user's workflow. Example: "Your workflow has three sequential stages (collect, match, report), so I recommend a Pipeline topology. Each agent passes its output to the next."

For non-technical users, reference the n8n mental model: "Think of it like a conveyor belt: each station does one job and passes the work forward." This analogy works for Pipeline and Hierarchy. For Mesh and Swarm, use "a team huddle where everyone contributes and refines."

### User Override

If the user prefers a different topology, accept it. Document the original recommendation and the user's choice with their reasoning. There is no wrong answer here as long as the topology can support the agent count and data flow.

## Step 3: Per-Agent Contracts (DESG-03)

Every agent gets a contract card. This is the single source of truth for what the agent does, what it needs, and what it produces. Present each card to the user for review.

### Contract Card Template

```markdown
### Agent: [Agent Name]

| Field | Value |
|-------|-------|
| **Role** | [One-sentence description of what this agent does] |
| **Responsibility** | [Specific scope boundaries: what it handles and what it does NOT handle] |
| **Inputs** | [Data sources, state files, credentials needed] |
| **Outputs** | [Files written, messages sent, state updated] |
| **Dependencies** | [Other agents that must run first, or "None"] |
| **Tools** | [MCP servers, Read/Write/Bash, external APIs] |
| **Trigger** | [Cron schedule, event, on-demand] |
| **Blast Radius** | [Level 1-4 with classification name from blast-radius.md] |
| **Approval Required** | [Yes/No, derived from blast-radius level] |
| **Model** | [Opus/Sonnet/Haiku with reasoning] |
| **Failure Handling** | [retry N times / skip and continue / alert via Telegram / halt all agents] |

**Prompt Injection Defense:** [Layer assignment from references/prompt-injection.md]
```

### Model Recommendation Rules

Assign the most cost-effective model that can handle the agent's task:

| Model | Use When | Example Tasks |
|-------|----------|---------------|
| Opus | Complex reasoning, multi-step analysis, ambiguous data | Matching invoices to payments with fuzzy logic, resolving conflicts |
| Sonnet | Standard processing, extraction, structured transformations | Collecting invoices, parsing API responses, updating state files |
| Haiku | Simple checks, validations, formatting, boolean decisions | Verifying file existence, format checks, threshold comparisons |

Default to Sonnet unless the task clearly requires Opus-level reasoning or is simple enough for Haiku.

### Prompt Injection Defense Assignment

For each agent, determine defense layers using the decision tree in [references/prompt-injection.md](prompt-injection.md):

- **Ingests external content (emails, web, APIs) AND blast radius Level 3-4:** All 4 layers + separate validation LLM call
- **Ingests external content AND blast radius Level 1-2:** Layers 1, 2, 3
- **No external input:** No injection defense needed

## Step 4: Schedule and Trigger Definitions (DESG-04)

### Trigger Types

| Type | Format | Example | When to Use |
|------|--------|---------|-------------|
| Cron | Standard cron expression | `0 22 * * *` (daily at 22:00) | Recurring scheduled runs, most common |
| Event | File watch or webhook | State file change triggers next agent | Pipeline handoffs, real-time workflows |
| On-demand | Manual invocation | User sends `/run invoice-collector` via Telegram | Ad-hoc runs, testing, one-off tasks |

### Scheduling Considerations

- **Pipeline sequencing:** Space cron times to allow each agent to complete before the next starts. Example: collector at 22:00, matcher at 22:30, reporter at 23:00. Adjust based on expected run durations.
- **Timezone awareness:** All cron expressions use the deployment server's local timezone. Document the timezone in governance.yaml. For the Arco Rooms reference (Spain): `Europe/Madrid`.
- **Rate limit alignment:** Schedule agents outside provider API rate limit windows. If a provider resets rate limits at midnight UTC, schedule collection after the reset.
- **Business hours consideration:** Schedule agents with external sends (Level 4) during business hours so approval requests reach the operator when they are available.

## Step 5: Governance Specification (DESG-05)

Governance defines the operational boundaries for the agent team. Seven areas must be specified:

### 1. Budget

Set a token budget per agent based on model tier:

| Model | Approximate Cost per 1M Tokens | Suggested Session Limit |
|-------|--------------------------------|------------------------|
| Opus | Higher tier | 50K tokens/session |
| Sonnet | Standard tier | 100K tokens/session |
| Haiku | Lower tier | 200K tokens/session |

Set a global daily cost cap in governance.yaml. See [references/audit-logging.md](audit-logging.md) for rate limiting enforcement and denial-of-wallet protection.

### 2. Permissions

Per-agent tool restrictions derived from blast-radius scoring (see [references/blast-radius.md](blast-radius.md)). Each agent's `allowed_tools` list contains only the tools it needs. Bash access is excluded unless explicitly justified.

### 3. Approval Requirements

Agents at blast-radius Level 3 or Level 4 require human approval before executing side effects. The approval flow uses Telegram: agent sends a preview of the intended action, waits for confirmation, proceeds or aborts based on the response. Approval timeout defaults to 60 minutes. See the approval matrix in [references/blast-radius.md](blast-radius.md).

### 4. Credential Scoping

Each agent gets the least-privilege credential for the services it accesses. Follow the credential decision tree in [references/credentials.md](credentials.md): OAuth > scoped API key > admin token. Document each credential in the agent contract with its scope and rotation schedule.

### 5. Audit Logging

JSONL format with correlation IDs and PII redaction. Every side-effect tool call produces a log entry. See [references/audit-logging.md](audit-logging.md) for the complete field schema, correlation ID pattern, and retention configuration.

### 6. Kill Switch

File-based halt mechanism at `.agentbloc/KILL_SWITCH` with a Telegram `/stop` remote trigger. See [references/incident-response.md](incident-response.md) for the dual-path specification and PreToolUse hook template.

### 7. Rate Limiting

Per-agent call limits and daily cost caps. Enforcement uses session-start checks and per-call guards. Denial-of-wallet alerts at 80% budget, halt at 100%. See [references/audit-logging.md](audit-logging.md) for the governance.yaml rate_limits template.

### Governance Summary Table

Present this table to the user as a compact overview:

| Agent | Budget | Blast Radius | Approval | Credential Type | Rate Limit |
|-------|--------|-------------|----------|-----------------|------------|
| [name] | [tokens/session] | [Level N: classification] | [Yes/No] | [OAuth/API key/admin] | [calls/hour] |

### Compliance Overlay

If the interview data classification activated GDPR, HIPAA, or PCI regimes, add compliance-specific governance rows. Load [references/gdpr-patterns.md](gdpr-patterns.md) for:

- **GDPR active:** Add processing activity records (Art. 6), erasure workflow (Art. 17), breach notification (Art. 33), DPO designation check (Art. 37)
- **HIPAA active:** Override audit retention to 6 years (2190 days), enforce PHI encryption at rest, flag BAA requirements for external MCP servers
- **PCI active:** Enforce tokenization for card data, assign Level 3+ blast radius to any agent handling financial card data, prohibit raw PAN storage

## Step 6: Blast-Radius Scoring (DESG-06)

### Auto-Scoring Protocol

For each agent identified in Step 1, apply the 4-step decision tree from [references/blast-radius.md](blast-radius.md):

1. Does the agent send data externally? YES: Level 4 (send-external)
2. Does the agent write without path restrictions? YES: Level 3 (write-unrestricted)
3. Does the agent write to specific pre-defined paths only? YES: Level 2 (write-scoped)
4. Agent only reads data: Level 1 (read-only)

Assign the level based on maximum capability, not typical behavior.

### Permission Minimization Pass

After initial scoring, run the 5-item checklist from [references/blast-radius.md](blast-radius.md) to push each agent's level as low as possible:

- [ ] Can this agent do its job with read-only access?
- [ ] Can write access be scoped to specific files or paths?
- [ ] Can external sends be consolidated into a single reporting agent?
- [ ] Can the agent use a scoped API key instead of an admin token?
- [ ] Does the agent need Bash access?

Target: 60-80% of agents at Level 1-2. If more than half the team is Level 3-4, revisit the decomposition.

### User Override Mechanism

Present the auto-scored levels to the user. They may override any score:

- **Override that increases the level** (e.g., Level 2 to Level 3): accepted without question. The user knows their risk tolerance.
- **Override that decreases the level** (e.g., Level 4 to Level 2): display a warning explaining what protections are removed. Example: "Lowering Report Sender from Level 4 to Level 2 removes the approval gate for external messages. The agent would send Telegram messages without human review. Are you sure?" Accept if the user confirms after the warning.

## Step 7: Visual Presentation (DESG-08)

Present the complete design in this order. Each format serves a different audience and purpose.

### 1. Agent Summary Table

Quick overview for initial review:

| # | Agent | Role | Blast Radius | Model | Trigger |
|---|-------|------|-------------|-------|---------|
| 1 | [name] | [one-line role] | L[N]: [classification] | [model] | [cron/event/on-demand] |

### 2. ASCII Topology Diagram

Inline text diagram for conversation display. Templates by topology:

**Pipeline:**
```
[Invoice Collector] --> [Payment Matcher] --> [Report Sender]
     L2:write             L2:write             L4:send
     Sonnet               Opus                 Sonnet
```

**Hierarchy:**
```
                [Coordinator]
                  L3:write
               /      |      \
     [Worker A]  [Worker B]  [Worker C]
      L1:read     L2:write    L4:send
```

### 3. Mermaid Topology Diagram

For deployment artifacts and documentation. Color code by blast-radius level:

```mermaid
graph LR
    A[Invoice Collector] --> B[Payment Matcher]
    B --> C[Report Sender]

    style A fill:#2d6a4f,color:#fff
    style B fill:#2d6a4f,color:#fff
    style C fill:#d62828,color:#fff
```

Color key:
- Green (`#2d6a4f`): Level 1-2 (autonomous, low risk)
- Orange (`#e76f51`): Level 3 (approval required, medium risk)
- Red (`#d62828`): Level 4 (external sends, approval required, high risk)

### 4. Per-Agent Contract Cards

Full detail using the template from Step 3. Present each card sequentially. For non-technical users, precede each card with a plain-language summary: "This agent collects your utility invoices every night at 10 PM. It reads from provider portals and saves what it finds. It cannot send messages or modify anything outside its designated files."

## Step 8: Designer Subagent Invocation (DSGN-01..06, ORCH-01..04)

Once Steps 1-7 above are complete and the draft team is in your working memory, spawn the Designer Agent subagent to materialize the structured artifact.

### Invocation

Spawn the subagent defined at `.claude/agents/designer-agent.md` (`context: fork`). The subagent inherits no main-session conversation noise; its world is the Business Graph plus the schema references. Pass the following as the subagent's initial prompt context:

1. Path to Business Graph: `.agentbloc/graph/business-graph.json`
2. Required reading: [references/agent-profile-schema.md](agent-profile-schema.md), [references/orchestration-patterns.md](orchestration-patterns.md), [references/blast-radius.md](blast-radius.md), [references/frameworks.md](frameworks.md)
3. Output target: `.agentbloc/team/agent-profiles.yaml` (create `.agentbloc/team/` if missing)
4. Optional companion: `.agentbloc/team/team-topology.md` (Mermaid diagram per v1.0 Design Phase Step 7.3)
5. Scope note: Designer emits REQUESTED agents in Step 8, then runs the Anticipation Pass (Step 8.5 below) to add ANTICIPATED-tagged agents per the heuristics map. The user reviews both classes in a single rendered TABLE.

### Output Contract

Designer returns to the main session:

- Confirmation string: "agent-profiles.yaml saved at .agentbloc/team/agent-profiles.yaml"
- A rendered markdown TABLE of the team plus per-agent Contract Cards (same templates as Step 3 and Step 7.1)
- An ASCII topology diagram (see Step 7.2 templates)

The YAML is NEVER shown to the user. The rendered table + cards + diagram ARE the user-facing review.

### Gate Check

After Designer returns, verify:

1. `.agentbloc/team/agent-profiles.yaml` exists on disk.
2. Every REQUIRED check (Checks 1-7) in [references/agent-profile-schema.md](agent-profile-schema.md) Validation Checklist passed during Designer's emission.
3. The rendered table + cards + ASCII diagram are presented to the user for confirmation.

Only after the user confirms the rendered team do you transition the Phase 2 `agent_profiles_validated` sub-gate (see SKILL.md State Transitions) to `approved`.

## Step 8.5: Anticipation Pass (ANTIC-01..05)

After Designer's Step 8 invocation completes the requested-agent emission, Designer's `<anticipation_pass>` block runs in the same forked context per Phase 15 D-99. Designer reads `.agentbloc/graph/declined.json` (or treats it as empty if absent), looks up `business.type` in [references/anticipation-heuristics.md](anticipation-heuristics.md), and emits any unrequested-but-needed agents tagged `ANTICIPATED` into the same agent-profiles.yaml.

Anticipated agents appear in the rendered TABLE prefixed with `[ANTICIPATED]`. Per-agent Contract Cards for those rows include `Rationale:` (1-2 sentence narrative) plus `Evidence:` (3+ URLs) sourced from the heuristics map.

If `business.type` is not in the heuristics map, Designer skips the anticipation pass entirely and the cards include a 1-line "No anticipation candidates" note. No hallucinated agents (the ANTIC degrade-silently rule).

The user accepts each anticipated agent by default (no action needed) or declines by saying "drop the <agent>" / "skip the <agent>" / "no thanks on the <agent>". Declines append to `.agentbloc/graph/declined.json` per [references/declined-agents-schema.md](declined-agents-schema.md) (business-level state per D-102) and re-running Designer never re-proposes them. The user can also defer ("not now, maybe later") which behaves identically to decline for v2.0; the user can manually edit declined.json to un-decline.

For the canonical Arco Rooms test case (`business.type: rental-property-management`), the anticipated agents are `analista-rentabilidad` (Profitability Analyst) and `gestor-incidencias` (Incident Tracker). The full expected team is 5 agents (3 requested + 2 anticipated). See [examples/arco-rooms-anticipated-profiles.yaml](../examples/arco-rooms-anticipated-profiles.yaml) for the canonical fixture.

**Closes:** ANTIC-01 (anticipation pass), ANTIC-03 (ANTICIPATED tag in proposal), ANTIC-04 (declined.json memory).

**See also:** [anticipation-heuristics.md](anticipation-heuristics.md), [declined-agents-schema.md](declined-agents-schema.md), [agent-profile-schema.md](agent-profile-schema.md) Anticipation Fields section.

## Design Gate

After presenting all seven steps, ask the user:

"Does this agent team design look right? Should I adjust any agents, change the topology, or modify any blast-radius scores?"

The user must confirm before Phase 3 begins. Acceptable confirmations: "yes", "approved", "looks good", "adelante", "ok". Any modification request loops back to the relevant step. Once confirmed, update the state bar to `Phase 2: General Design | Gate: approved` and prepare to transition to Phase 3.

## Conversational Editing Flow (DSGN-07)

After the user reviews the rendered team, they may request edits:

- "Rename gestor-cobros to Maria's agent."
- "Drop the recepcionista for now."
- "Give gestor-documental bash access."
- "Change topology from mesh to pipeline."

### Surgical Patch Protocol

For each user edit:

1. Parse the intent into a structured patch: `{rename, delete, add-tool, remove-tool, change-autonomy, change-topology, change-blast-radius}`.
2. Re-invoke Designer Agent with the patch payload AND the existing `.agentbloc/team/agent-profiles.yaml` as input. Designer NEVER regenerates from the Business Graph; regeneration would re-insert rejected or renamed agents, fighting user intent.
3. Designer applies the patch in-place, bumps `team.modified_at` to the current ISO-8601 timestamp, and re-runs the Validation Checklist from [references/agent-profile-schema.md](agent-profile-schema.md).
4. Designer returns ONLY the new rendered TABLE (not the full YAML, not all cards) for the user's next confirmation turn.
5. User confirms the new table.

### Never Regenerate

If the user says "redo the whole team from scratch", prompt once for clarification: "Starting from scratch will discard your edits (renames, drops, tool changes). Keep edits or reset?" Default to keep.

### Gate Re-entry

After every edit round, the Phase 2 `agent_profiles_validated` sub-gate returns to `pending` until the user confirms the re-rendered table. Multiple edit rounds are fine; each completes its own confirmation turn before the gate flips back to `approved`.

## Quick Reference

| Step | ID | What It Produces | Cross-References |
|------|----|-----------------|------------------|
| Agent Identification | DESG-01 | Agent list with roles | [frameworks.md](frameworks.md), [examples/arco-rooms.md](../examples/arco-rooms.md) |
| Topology Selection | DESG-02 | Topology type + rationale | [frameworks.md](frameworks.md) |
| Per-Agent Contracts | DESG-03 | Contract cards for each agent | [blast-radius.md](blast-radius.md), [prompt-injection.md](prompt-injection.md) |
| Schedule and Triggers | DESG-04 | Cron expressions, event triggers | [audit-logging.md](audit-logging.md) |
| Governance | DESG-05 | 7-area governance specification | [blast-radius.md](blast-radius.md), [credentials.md](credentials.md), [audit-logging.md](audit-logging.md), [incident-response.md](incident-response.md), [gdpr-patterns.md](gdpr-patterns.md) |
| Blast-Radius Scoring | DESG-06 | Level per agent + minimization | [blast-radius.md](blast-radius.md) |
| Visual Presentation | DESG-08 | Summary table, ASCII diagram, Mermaid diagram, contract cards | [blast-radius.md](blast-radius.md) |
| Designer Subagent Invocation | DSGN-01..06, ORCH-01..04 | .agentbloc/team/agent-profiles.yaml + rendered team table + ASCII diagram | [agent-profile-schema.md](agent-profile-schema.md), [orchestration-patterns.md](orchestration-patterns.md), .claude/agents/designer-agent.md |
| Conversational Editing Flow | DSGN-07 | Surgical-patched YAML + re-rendered table | [agent-profile-schema.md](agent-profile-schema.md), .claude/agents/designer-agent.md |
| Anticipation Pass | ANTIC-01..05 | agent-profiles.yaml with ANTICIPATED-tagged agents + .agentbloc/graph/declined.json | [anticipation-heuristics.md](anticipation-heuristics.md), [declined-agents-schema.md](declined-agents-schema.md), [agent-profile-schema.md](agent-profile-schema.md) Anticipation Fields, .claude/agents/designer-agent.md `<anticipation_pass>` block |
