# Tools — gestor-cobros

## Tool table

| Tool | Tier | Blast | Operations | Integration link |
|---|---|---|---|---|
| `bank-mcp` | NEEDS-MCP-WRAPPER | L2 (read) | list_transactions, get_balance | `../../integrations/needs-mcp-wrapper/bank-mcp/` |
| `google-sheets-mcp` | EXISTS-MCP | L1 (read) / L2 (write) | read_range, write_range, append_row | `../../integrations/existing/google-sheets-mcp.md` |

## Per-tool invocation pattern

### bank-mcp

PSD2 wrapper synthesized via `mcp-builder` skill. Covers BBVA,
Santander, CaixaBank, Unicaja with one shared OAuth flow per bank.

Operations:
- `list_transactions(bank_id, account_id, date_from, date_to)` — L2
  (read external; cached locally for matching)
- `get_balance(bank_id, account_id)` — L1 (read-only, no caching)

Approval gating (semi autonomy, L2 only): NONE. The gate fires only
on L3+ tools, which this agent doesn't use.

### google-sheets-mcp

Tenant registry lookup. Optional write of matching summary to a
"daily log" sheet for human review (separate from matches.json).

Operations:
- `read_range(sheet_id, range)` — L1
- `append_row(sheet_id, row)` — L2 (own log sheet only)
- `write_range(sheet_id, range)` — NOT used (would be L3 — out of envelope)

Approval gating: NONE for L1+L2 invocations within the agent's own log
sheet. Writing to the master tenant registry would require Pablo's
manual approval — explicitly out of scope for this agent.

## Excluded tools (least-privilege boundary)

- `playwright-mcp` — gestor-documental owns browser automation
- `telegram-mcp` — recepcionista owns send-external; gestor-cobros
  signals via inter-agent inbox instead
- `gmail-mcp` / `google-workspace-mcp` — not in this agent's scope
- `mapfre-api` — gestor-documental's tool

If a future requirement adds CSV export of matches.json (e.g., for
accountant), AgentBloc Phase 6 revisits this list and either widens
the agent's tools or adds a new agent.

## Cross-references

- Inventory: [`../../integrations/INVENTORY.md`](../../integrations/INVENTORY.md)
- Blast-radius: [`blast-radius.md`](blast-radius.md)
- Wrapper synthesis: [`../../integrations/needs-mcp-wrapper/bank-mcp/BUILD.md`](../../integrations/needs-mcp-wrapper/bank-mcp/BUILD.md)
