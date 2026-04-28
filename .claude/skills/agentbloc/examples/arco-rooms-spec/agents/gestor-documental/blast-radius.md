# Blast Radius — gestor-documental

> Per-agent risk envelope + autonomy posture.

## Assignment

| Property | Value |
|---|---|
| Blast radius | **L2** |
| Autonomy | **full** |

## What L2 means

**L2 — write-scoped.** Writes only to designated paths
(`.agentbloc/agents/gestor-documental/` for own state,
`.agentbloc/agents/gestor-cobros/inbox/` for inter-agent handoff,
`.agentbloc/state/invoices.json` for shared pipeline state). No
external sends. No approval gate.

## Why this level

Invoice collection is fundamentally a read-from-external,
write-to-local operation. The agent never sends emails, never makes
payments, never modifies data on the provider side. Writes are
limited to local JSON state and the next agent's inbox. L2 is the
correct envelope; L1 would block legitimate state writes; L3 would
unnecessarily risk arbitrary path writes.

Combined with `full` autonomy, the agent runs unattended every night
without operator interaction. This is appropriate because:
1. All L2 writes are reversible (local files, version-controllable)
2. Provider side is read-only (no risk of accidental external action)
3. Failure modes degrade gracefully (skip provider, log, continue)
4. PostToolUse audit captures every action for forensic review

## Cooperative enforcement (agent prose)

The agent's `prompts.md` system prompt instructs L2 boundaries
explicitly. Compliance relies on the model following instructions.

## Deterministic enforcement (hook)

If the build session uses the bash + cron reference impl,
`runtime/reference-impl/hooks/autonomy-gate.sh` PreToolUse will:

1. Read `CLAUDE_AGENT_ID=gestor-documental` from env (set by `wake.sh`)
2. Look up `autonomy=full` from registry
3. Classify the tool's blast level (L1/L2/L3/L4 per
   `governance/blast-radius.md` patterns)
4. For L1+L2: exit 0 (proceed) — full autonomy, no approval needed
5. For L3+L4: would block with `result: blocked, reason: outside-envelope`

L3+L4 tools should never be invoked by this agent — its `tools.md`
explicitly excludes them. The hook is a defense-in-depth backstop in
case a future spec change accidentally widens scope.

## Permission boundaries

| Permitted | Forbidden |
|---|---|
| Browser navigation + form interaction (Playwright on provider portals) | Telegram sends, email sends, third-party API writes |
| Gmail read + Drive download (Google Workspace MCP) | Gmail send, Drive delete |
| Mapfre API read | Any L3+ Bash, any external write outside designated dirs |
| Write to `.agentbloc/state/invoices.json` and own inbox/inbox/handoff | Modify other agents' memory.md or last-run.json |

Forbidden actions trigger hook-side BLOCK (exit 2) AND prose-side
self-decline.

## Escalation

Failures and unrecoverable errors route per
[`escalation.md`](escalation.md).

## Cross-references

- Tools: [`tools.md`](tools.md)
- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
- Audit trail: [`../../governance/audit-trail.md`](../../governance/audit-trail.md)
- Kill-switch: [`../../governance/kill-switch.md`](../../governance/kill-switch.md)
