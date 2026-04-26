# Plan 14-02 Summary: Briefing Agent Template + Monitor Schema Extensions

Plan 14-02 emits 1 new template (briefing-agent.md.tmpl, 69 lines) and surgically extends 2 existing references (agent-memory-schema.md + audit-logging.md) per Phase 14 D-88 + D-97 + D-98.

## Artifacts

| # | File | Edit | Lines | Commit | Closes |
|---|------|------|-------|--------|--------|
| 1 | `templates/briefing-agent.md.tmpl` | NEW | 69 | `edd433a` | MONITOR-03 + MONITOR-04 + MONITOR-06 + CTRL-04 D-88 default briefing agent |
| 2 | `references/agent-memory-schema.md` | surgical extend | 217 | `95139f6` | CTRL-02 D-98 last-run.json schema_version=2 with cost_usd + token_count fields |
| 3 | `references/audit-logging.md` | surgical align | (minor) | `82161e8` | D-97 correlation-ID format alignment with Phase 13 D-75 |

## briefing-agent.md.tmpl structure

7 body sections + frontmatter + last-line tag:
1. Role + Goal + Autonomy (autonomy=full per D-88)
2. Mandatory Initial Read (memory.md, state.json, last-run.json, registry.yaml)
3. Wake Protocol (6-step: kill-switch -> correlation ID -> memory read -> log glob -> execute -> state write)
4. Side-effect Approval Routing (autonomy=full bypasses approval; PostToolUse audits)
5. Memory Protocol (run-history high-water marks for last 30 days)
6. Pluggable Renderer (telegram v2.0 + html v2.5 stub + json v3.0 stub per MONITOR-06)
7. Kill-Switch Discipline (v1.0 SECR-05 + Phase 13 D-77)

Pure `{{var}}` substitution; zero Jinja blocks (verified at commit time).

## Schema extension impact

agent-memory-schema.md last-run.json bumps to schema_version=2 with two new optional fields:
- `cost_usd: number` — Today's USD cost rolling total (claude-wrap.sh increments per wake)
- `token_count: {input, output, cached_input}` — Today's token totals

Backward-compatible: v1 deployments continue to work (consumers parse new fields as null when absent); consumers refuse on schema_version > 2 only.

## audit-logging.md alignment

Surgically aligned the v1.0 `sess-{agent_name}-{NNN}` correlation-ID format with Phase 13 D-75 `<source>-<UTC-Z-compact>-<nonce6>` format per D-97. Legacy v1.0 examples preserved as historical lineage; main reference now points at correlation-id.md (Phase 13 D-75) as the v2.0+ canonical format.

## D-XX decision coverage

D-88 (briefing-agent template + pluggable renderer), D-97 (audit-logging alignment with D-75), D-98 (last-run.json schema_version=2) — all applied with surgical insertion-only discipline.

## Plan 14-03 handoff

Plan 14-03 surgical edits wire briefing-agent.md.tmpl into deploy-engine.md emission_targets (per-team rendering); claude-wrap.sh into runtime-engine.md emission; SKILL.md Phase 5 See-lines + monitor_wired sub-gate. No content from Plan 14-02 is rewritten.

## Verification status

All per-task verifies passed:
- briefing-agent.md.tmpl: 69 lines (within 60-90), em-dashes = 0, zero Jinja blocks, last-line tag `<!-- agentbloc:template autonomy=full role=briefing schema_version=1 -->`
- agent-memory-schema.md: schema_version: 2 + cost_usd + token_count + billing-rates.md cross-reference all present; D-65 schema versioning prose preserved
- audit-logging.md: correlation-id.md cross-reference + D-97 + D-75 all present; legacy `sess-` examples preserved

Plan 14-03 can begin immediately.
