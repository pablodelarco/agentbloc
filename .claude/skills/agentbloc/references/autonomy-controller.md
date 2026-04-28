# Autonomy Controller

> Two-layer pattern that ships INSIDE the emitted spec folder (as agent
> prose in `agents/<id>/blast-radius.md` and as the optional
> `runtime/reference-impl/hooks/autonomy-gate.sh` primitive). AgentBloc
> emits the spec; the build session implements the runtime gating.
>
> Loaded at Phase 5 entry to inform the prose `spec-engine` writes
> into the emitted spec folder's agent + governance files.

Two-layer enforcement of per-agent autonomy: agent prose informs reasoning; PreToolUse hook (`autonomy-gate.sh`) provides deterministic enforcement. Defense-in-depth pattern.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Two-Layer Architecture](#two-layer-architecture)
- [Tool Classification Table](#tool-classification-table)
- [Per-Autonomy Behavior Matrix](#per-autonomy-behavior-matrix)
- [$TOOL_REASONING Contract](#tool_reasoning-contract)
- [autonomy-gate.sh Shell Contract](#autonomy-gatesh-shell-contract)
- [Cross-References](#cross-references)

## When This Applies

Loaded UNCONDITIONALLY at Phase 5 entry per D-58. Informs PreToolUse hook installation by deploy-engine + the per-template approval-routing prose insertion in deployed-agent-skill templates per D-94.

## Two-Layer Architecture

**Layer 1 (prose):** Phase 12 deployed-agent-skill templates (`-full`, `-semi`, `-supervised`) encode autonomy-appropriate prose. Phase 14 surgically extends each with a "Side-effect Approval Routing" paragraph per D-94 instructing the agent on its responsibilities.

**Layer 2 (runtime hook):** `.claude/hooks/autonomy-gate.sh` is a PreToolUse hook installed by deploy-engine. Sequences AFTER `kill-switch-check.sh` (alphabetical hook order; kill-switch always blocks first). Reads the running agent's `autonomy` field from `registry.yaml`; dispatches to `approval-router.sh` for `semi`/`supervised`; permits all for `full`.

The two layers compose: prose-only relies on model compliance and provides no audit guarantee; hook-only is deterministic but lacks the contextual reasoning that prose teaches the agent to surface in `$TOOL_REASONING`. Both together = defense in depth.

## Tool Classification Table

| Category | Pattern | Examples | Hook Behavior |
|----------|---------|----------|---------------|
| External side-effect | MCP tool name starts with `send_`, `post_`, `create_`, `update_`, `delete_`, `transfer_`, `pay_` OR Bash that writes outside `.agentbloc/agents/<self>/` | `mcp__telegram__send_message`, `mcp__plaid__transfer_funds`, `Bash(rm /tmp/...)` | Triggers approval on semi + supervised |
| Internal side-effect | Writes to `.agentbloc/agents/<self>/` (own memory), state.json mutations | `Write .agentbloc/agents/gestor-cobros/memory.md` | Permits on full + semi; triggers approval on supervised (when target is OTHER agent's dir) |
| Read-only | Read, Grep, Glob, fetch-* MCP tools, list-* MCP tools | `Read`, `mcp__gmail__search_messages`, `mcp__plaid__list_transactions` | NEVER triggers approval, regardless of autonomy |

## Per-Autonomy Behavior Matrix

| Tool Category | full | semi | supervised |
|---------------|------|------|-----------|
| External side-effect | proceed | approval required | approval required |
| Internal side-effect (own dir) | proceed | proceed | proceed |
| Internal side-effect (other agent's dir) | proceed | proceed | approval required |
| Read-only | proceed | proceed | proceed |

PostToolUse audit hook always logs the call regardless of autonomy or category.

## $TOOL_REASONING Contract

Before invoking any external-side-effect tool, `semi` + `supervised` agents MUST export `$TOOL_REASONING` (1-2 sentence rationale). The hook reads this env var and includes it in the approval request payload sent to Telegram per `references/approval-router.md`. Agents that fail to set the env var have their tool invocation BLOCKED with `result: blocked, reason: missing-tool-reasoning` logged.

Example: `TOOL_REASONING="Sending the May invoice to tenant Pablo because rent payment is overdue 5 days; reversible via subsequent corrective email" mcp__gmail__send_email --to ... --subject ...`

## autonomy-gate.sh Shell Contract

**Input:** PreToolUse hook spec (env vars: `$TOOL_NAME`, `$TOOL_ARGS`, `$TOOL_REASONING`, `$AGENT_ID`, `$CORRELATION_ID`)
**Behavior tree:**
1. Read `autonomy` for `$AGENT_ID` from `.agentbloc/agents/registry.yaml`.
2. Classify `$TOOL_NAME` per the table above.
3. If category=read-only -> exit 0 (proceed).
4. If autonomy=full + category!=read-only -> exit 0.
5. If autonomy=semi + category=internal-self -> exit 0.
6. If autonomy=supervised + category=internal-self -> exit 0.
7. Else -> dispatch approval via `bash .agentbloc/runtime/approval-router.sh telegram-request "$AGENT_ID" "$TOOL_NAME" "$TOOL_ARGS" "$TOOL_REASONING" "$CORRELATION_ID"`. Exit code propagated (0 = approved/proceed, 1 = denied/blocked/timeout).

**Forbidden patterns (do NOT add these to autonomy-gate.sh):** WebFetch, Task, generic Bash beyond the dispatch line, `bash -c`, `sh ...`. The script is a thin classifier + dispatcher; the heavy lifting is in approval-router.sh.

## Cross-References

- [approval-router.md](approval-router.md) , dispatch target for semi/supervised
- [blast-radius.md](blast-radius.md) , v1.0 + DSGN-04 blast-radius scoring; defaults autonomy per blast-radius score
- [deployed-agent-skill-schema.md](deployed-agent-skill-schema.md) , Phase 12 template baseline; Phase 14 surgical extensions per D-94
- [incident-response.md](incident-response.md) , kill-switch-check.sh sequencing precedence
