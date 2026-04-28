# Runtime Coordination Contract

> Phase 13 runtime reference. Defines how deployed agents coordinate with each other when workflows.agents.length > 1. Primitive contract: ClaudeClaw TeamCreate + SendMessage for interactive leads; writeStateHandoff file-based fallback for non-interactive wakes and runtime-agnostic deployments. Single-agent workflows bypass TeamCreate entirely at template-selection time per RUNTIME-05. Crontab mutations use the stdin install form exclusively; crontab -e is explicitly disallowed because it launches an interactive editor that hangs forked subagents.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Single-Agent Bypass (RUNTIME-05)](#single-agent-bypass-runtime-05)
- [Multi-Agent Workflow Invocation (D-76)](#multi-agent-workflow-invocation-d-76)
- [Topology-to-Primitive Mapping (D-23 + D-24)](#topology-to-primitive-mapping-d-23--d-24)
- [writeStateHandoff Fallback (PRIMARY for non-interactive wakes)](#writestatehandoff-fallback-primary-for-non-interactive-wakes)
- [Team Dissolution Semantics (D-77)](#team-dissolution-semantics-d-77)
- [Kill-Switch Integration (D-77)](#kill-switch-integration-d-77)
- [Crontab Stdin Install Discipline (D-80)](#crontab-stdin-install-discipline-d-80)
- [Coordination Preference in Registry (D-78)](#coordination-preference-in-registry-d-78)
- [Cross-References](#cross-references)

## When This Applies

Phase 13 runtime-engine subagent (`.claude/agents/runtime-engine.md`) loads this file in its forked context on invocation. The contract runs every time an agent's workflow classification in registry.yaml workflows[<workflow-id>] declares agents.length > 1 (multi-agent workflow) OR the agent detects a dependency at runtime. Single-agent workflows (agents.length === 1) skip this contract entirely; the wake template invokes the agent's SKILL.md directly. Loaded UNCONDITIONALLY at Phase 5 entry per D-58 context-budget discipline.

## Single-Agent Bypass (RUNTIME-05)

Per RUNTIME-05, single-agent tasks run without TeamCreate overhead. Enforcement is at the wake-template selection level (runtime-engine picks `wake-job-cron.md.tmpl` or `wake-job-webhook.md.tmpl` for workflows with agents.length === 1; picks `wake-job-inter.md.tmpl` or embeds a TeamCreate call in the cron/webhook template for agents.length > 1). The check is deterministic: runtime-engine reads `registry.runtime.workflows[<workflow-id>].agents` and dispatches the template accordingly. No runtime conditional branching.

```
workflow = registry.runtime.workflows[workflow_id]
if workflow.agents.length == 1:
  # Bypass: direct wake, no TeamCreate
  template = wake-job-<trigger-type>.md.tmpl
  materialize(template, agent=workflow.agents[0])
else:  # length > 1
  if workflow.spawn_rule == "declared":
    # First agent wakes, immediately TeamCreate
    lead = workflow.agents[0]
    template = wake-job-<trigger-type>.md.tmpl (with TeamCreate section embedded)
    materialize(template, agent=lead, roster=workflow.agents)
  elif workflow.spawn_rule == "dynamic":
    # Any agent may detect need and call TeamCreate
    template = wake-job-inter.md.tmpl (for re-entry on SendMessage)
    materialize(template, agent=each, dependencies=agent.dependencies)
```

## Multi-Agent Workflow Invocation (D-76)

Per PDF page 5 ("primer agente que detecta spawna el equipo"), AgentBloc honors two cases:

- **Declared roster (`spawn_rule: declared`):** The first agent in `workflow.agents[]` (the lead per D-23 topology selection) wakes via cron or webhook, immediately issues `TeamCreate(agents=workflow.agents, correlation_id=<ID>)`, and coordinates via `SendMessage` from then on. The correlation_id is propagated verbatim into TeamCreate metadata and every subsequent SendMessage call.
- **Dynamic detection (`spawn_rule: dynamic`):** Any agent during execution may detect a dependency via its SKILL.md `dependencies` block + the incoming payload shape. When detected, the agent calls `TeamCreate([self, detected-agent, ...transitive-deps])` with a new sub-correlation-ID (parent ID + `-sub-<NNN>` per audit-logging.md).

Primitive call signatures (ClaudeClaw docs, subject to verification in Plan 13-02 if signature drifts):

```
TeamCreate(agents: string[], correlation_id: string, metadata: {...}) -> team_id
SendMessage(to: agent-id, body: object, metadata: { correlation_id: string }) -> message_id
```

## Topology-to-Primitive Mapping (D-23 + D-24)

| Topology | Orchestration Pattern (ADK) | Primitive Invocation |
|----------|-----------------------------|----------------------|
| pipeline | Sequential | Staggered cron (scheduling.md pipeline-spacing 30-min gaps); NO TeamCreate |
| mesh (default per D-23) | Parallel or Conversational | TeamCreate + SendMessage fan-out |
| hierarchy | Event-driven | Lead spawns TeamCreate; children SendMessage to lead only |
| swarm | Conversational | TeamCreate + peer SendMessage (any agent talks to any agent) |

Cross-reference `orchestration-patterns.md` for the 5-pattern Sequential / Parallel / Loop / Event-driven / Conversational table and the topology decision heuristics.

## writeStateHandoff Fallback (PRIMARY for non-interactive wakes)

Per Phase 13 RESEARCH refinement, writeStateHandoff is the PRIMARY coordination mechanism for non-interactive wakes (cron-triggered agents that need to coordinate; webhook-triggered agents without interactive lead context). TeamCreate is PRIMARY only for interactive leads (an agent handling a Telegram conversation that dynamically detects a dependency; the human is in the loop). This refinement applies because ClaudeClaw's TeamCreate primitive is session-scoped; cron wakes have no session to attach to, so a file-based handoff is both simpler and more debuggable.

File flow (writeStateHandoff):
```
Agent A (non-interactive wake, e.g., cron)
  -> Writes handoff payload to .agentbloc/agents/<agent-b>/inbox/<correlation-id>.json
  -> Invokes: claude -p --payload-file <path> .agentbloc/agents/<agent-b>/wake-inter.md
     as foreground subprocess (synchronous, blocks until Agent B exits)
Agent B (wake-inter.md)
  -> Reads inbox/<correlation-id>.json
  -> Processes per SKILL.md
  -> Writes response to .agentbloc/agents/<agent-a>/inbox/<correlation-id>-reply.json
  -> Exits
Agent A resumes
  -> Reads reply
  -> Continues execution
```

Trade-offs:
- writeStateHandoff: debuggable (files on disk; manually inspectable), runtime-agnostic (works on plain Claude Code), no concurrency (sequential only).
- TeamCreate: concurrent (parallel agent execution), ClaudeClaw-only (primitive is not available in plain Claude Code).

## Team Dissolution Semantics (D-77)

`team_dissolution_reason` enum (bounded per D-18 discriminated-union discipline, one of 4 values):

- `all-members-returned` , happy path; every member agent has returned a non-continuation output via final state.json write
- `kill-switch` , D-77 three-point enforcement fires; see `references/incident-response.md` Runtime Kill-Switch Semantics
- `timeout` , correlation-ID-scoped timeout exceeds `registry.runtime.team_timeout_minutes` (default 15 minutes)
- `error` , unrecoverable error in any member; team-wide halt; failure logged with correlation_id and bubbled to lead for v1.0 SECR escalation

Dissolution events are logged to `.agentbloc/runtime/TEAM_SESSIONS.jsonl` per D-46 append-only ledger discipline (one JSON per line, UTC-Z timestamps, GDPR Article 30 record-of-processing).

## Kill-Switch Integration (D-77)

Per D-77, the kill-switch is checked at 3 points per agent wake: (1) top of wake.md before any reads, (2) before every side-effect tool call via PreToolUse hook (Phase 12 artifact), (3) at every state transition within a TeamCreate session. Inside a multi-agent workflow, the team-transition check (#3) is the load-bearing semantic: every agent checks `.agentbloc/KILL_SWITCH` before SendMessage send AND before SendMessage consume. If active, the agent returns `{status: halted-kill-switch}` and the team lead dissolves the team via explicit TeamCreate teardown. Worst-case latency is one SendMessage round-trip (typically under 5 seconds). See `references/incident-response.md` Runtime Kill-Switch Semantics for the full protocol.

## Crontab Stdin Install Discipline (D-80)

Phase 13 runtime-engine subagent installs crontab entries via the stdin form EXCLUSIVELY. `crontab -e` is EXPLICITLY DISALLOWED because it launches an interactive editor (`$EDITOR`) that hangs a forked subagent waiting for user input. Scripted install uses the stdin form verbatim:

```bash
(crontab -l 2>/dev/null; cat .agentbloc/runtime/crontab.applied) | crontab -
```

Bash allow-list for runtime-engine (preview; full spec in D-80 and Plan 13-02):
- `crontab -` (stdin install; the `-` suffix reads from stdin)
- `crontab -l` (list current crontab; for diff presentation)
- `shasum -a 256` (fingerprint computation for crontab.applied manifest)
- `claude agents list` (verification: every deployed agent registered)
- `claude mcp list` (verification: every MCP server declared)

Disallowed (explicit NEVER): `crontab -e` (interactive editor hangs forked subagent), `bash -c` (arbitrary shell), `sh` (arbitrary shell), `curl` (network egress), `rm -rf` (destructive wildcards).

## Coordination Preference in Registry (D-78)

Registry.yaml extends with a `runtime.coordination_preference` block:

```yaml
runtime:
  coordination_preference:
    prefer: "claudeclaw"  # or "writeStateHandoff"
    fallback: "writeStateHandoff"
```

Rules:
- When `prefer: claudeclaw`, runtime-engine emits TeamCreate calls in the wake-job-inter.md.tmpl output; writeStateHandoff is the fallback if TeamCreate throws.
- When `prefer: writeStateHandoff`, runtime-engine skips TeamCreate entirely and materializes writeStateHandoff semantics in the wake-job-inter.md.tmpl output.
- When both are absent, runtime-engine defaults to `prefer: writeStateHandoff` per RESEARCH refinement (TeamCreate is session-scoped; cron wakes have no session to attach to).

## Worked Example: Arco Rooms Tenant Query (Dynamic Spawn)

Scenario: Telegram tenant sends "Cuando vence mi contrato?" to Recepcionista. Recepcionista's SKILL.md declares `dependencies: [gestor-cobros]` for payment-status context. Workflow `atencion_inquilinos` in registry.runtime.workflows is declared with `agents: [recepcionista, gestor-cobros]` and `spawn_rule: dynamic` (Recepcionista does NOT always need Gestor Cobros; only when the question touches payment status).

Flow:
```
1. n8n Telegram webhook -> envelope { correlation_id: "webhook-telegram-<UTC>-c7d92a", agent_id: "recepcionista", ... }
2. Recepcionista wake-webhook-telegram-tenant-message.md fires
3. Recepcionista reads memory.md + state.json (section 3 of wake template)
4. Recepcionista parses payload (section 4); detects question is about contract expiry
5. Recepcionista's SKILL.md dispatches: "need contract-end-date from gestor-cobros memory"
6. Recepcionista calls TeamCreate([recepcionista, gestor-cobros], correlation_id=<parent>)
7. TeamCreate returns team_id; Recepcionista issues SendMessage(to=gestor-cobros, body={query: "contract-end-date", tenant_id: "..."}, metadata={correlation_id: "<parent>-sub-001"})
8. Gestor Cobros wake-inter.md fires (payload arrives via SendMessage)
9. Gestor Cobros reads its memory.md, extracts contract-end-date, SendMessage reply
10. Recepcionista formats reply to tenant, Telegram send
11. All team members return non-continuation output; team dissolves with team_dissolution_reason: all-members-returned
```

Every log line across both agents carries the same parent correlation_id; grep recovers the full chain per `references/correlation-id.md` recipes.

## Diagnostics + Common Failure Modes

- **Empty team shell (TeamCreate succeeded, no teammates responded):** `TEAM_SESSIONS.jsonl` entry with team_dissolution_reason: timeout and zero SendMessage events. Root cause per RESEARCH focus area 1: TeamCreate is session-scoped; cron-wake had no interactive lead context. Remediation: set `coordination_preference.prefer: writeStateHandoff` in registry.yaml so runtime-engine emits wake templates with file-based handoff instead of TeamCreate.
- **SendMessage round-trip exceeds team_timeout_minutes:** child agent's wake.md is slow (typically stuck in a long tool call or waiting for external API). Check correlation-ID-scoped entries in `.agentbloc/logs/audit.jsonl` for the child agent's last tool_call event. Increase `team_timeout_minutes` in registry.runtime only after confirming the child is making forward progress.
- **Kill-switch mid-team dissolution takes >10 seconds:** lead agent may be blocked in a long SendMessage send with no state-transition check opportunities. Remediation: SKILL.md authors should break long operations into explicit state-transition points per D-77. The three-point enforcement (wake / per-tool / team-transition) covers most realistic windows, but a tight inner loop with no tool calls can still delay halt.
- **Crontab install fails with "no job" or empty crontab:** stdin install form requires the existing crontab to flow through `crontab -l`. If the user has never had a crontab, `crontab -l` returns non-zero on some systems; use `(crontab -l 2>/dev/null || true; cat .agentbloc/runtime/crontab.applied) | crontab -` to handle empty baseline.

## Cross-References

- `references/n8n-integration.md` , event-bus contract for webhook-triggered multi-agent workflows (envelope carries correlation_id as top-level field)
- `references/correlation-id.md` , D-75 format spec + propagation through TeamCreate metadata + SendMessage metadata
- `references/incident-response.md` , Runtime Kill-Switch Semantics section (D-77 three-point enforcement prose)
- `references/orchestration-patterns.md` , 5-pattern table (Sequential / Parallel / Loop / Event-driven / Conversational) with topology decision heuristics
- `references/scheduling.md` , pipeline-spacing rules for Sequential-topology staggered cron
- `references/agent-profile-schema.md` , topology enum + dependencies[] array consumed by dynamic spawn_rule
- `references/audit-logging.md` , correlation_id pattern + sub-ID child convention inherited by TeamCreate metadata

## Notes

- Phase 13 treats TeamCreate and SendMessage as external primitives; AgentBloc does not reimplement them. If Claude Code releases a documented non-interactive TeamCreate path in a future release, runtime-coordination.md can invert the coordination_preference default without touching any other CONTEXT decision.
