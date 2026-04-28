# Blast Radius — gestor-cobros

## Assignment

| Property | Value |
|---|---|
| Blast radius | **L2** |
| Autonomy | **semi** |

## What L2 means

**L2 — write-scoped.** Writes only to designated paths
(`.agentbloc/state/matches.json`, own state directory,
`.agentbloc/agents/recepcionista/inbox/` for inter-agent handoff).
No external sends, no third-party API writes (bank-mcp is read-only
in this team's scope).

## Why this level (and `semi` autonomy, not `full`)

Payment matching reads from external APIs (banks, sheets) but writes
only locally. L2 is the right envelope.

`semi` autonomy is chosen even though the agent's tools are all L2
because:
1. The decision rule "overdue 7 days → formal notice" has downstream
   L4 implications (recepcionista will eventually send a stern
   tenant message). Forcing the upstream agent to be `semi` adds an
   audit trail before the L4 send fires.
2. Future spec evolution may add an L3 tool (e.g., direct CSV export
   to accountant); `semi` autonomy makes that change safer by default.
3. Bank PSD2 reads carry compliance weight (GDPR Article 30 record of
   processing) — having an explicit autonomy gate ready, even if
   currently dormant, is good defensive design.

## Cooperative enforcement

System prompt instructs L2 boundaries + the dormant approval gate for
hypothetical L3+ tool calls.

## Deterministic enforcement

`runtime/reference-impl/hooks/autonomy-gate.sh` PreToolUse:
1. Reads `CLAUDE_AGENT_ID=gestor-cobros`, `autonomy=semi`
2. Classifies tool blast level
3. L1+L2 → exit 0 (proceed)
4. L3+ → look up `.agentbloc/state/approvals.jsonl` for matching
   correlation_id with `decision=approve`; if absent, post approval
   request via `approval-router.sh` and block until response
5. L4 → same as L3

## Permission boundaries

| Permitted | Forbidden |
|---|---|
| Bank PSD2 reads (list_transactions, get_balance) across 4 banks | Bank initiate_payment / transfer / write |
| Google Sheets read tenant registry | Google Sheets write to tenant registry (only own log sheet permitted) |
| Write `.agentbloc/state/matches.json` and own inbox/handoff | Write to other agents' memory.md or last-run.json |
| Inter-agent envelope to recepcionista | Direct Telegram send |

## Escalation

Per [`escalation.md`](escalation.md). Bank PSD2 401s + persistent
matching-quality degradation are the canonical failure modes.

## Cross-references

- Tools: [`tools.md`](tools.md)
- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
- Audit trail: [`../../governance/audit-trail.md`](../../governance/audit-trail.md)
