# Phase 4: Integration and Confirmation Phases - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 04-integration-and-confirmation-phases
**Mode:** --auto (all decisions auto-selected)
**Areas discussed:** Integration search protocol, Evidence and trust scoring, Confirmation flow, Dry run protocol, Security integration points

---

## Integration Search Protocol

| Option | Description | Selected |
|--------|-------------|----------|
| API > MCP > Playwright > email > webhook > manual | Strict priority order, stop after 3 viable options | Yes |
| Search all methods equally, present all | No priority, user picks | |
| Only search API and MCP, skip browser automation | Simpler but less comprehensive | |

**User's choice:** [auto] API > MCP > Playwright > email > webhook > manual (recommended default from INTG-01 and CLAUDE.md)
**Notes:** Priority order matches the existing fallback chain pattern in Arco Rooms example.

---

## Evidence and Trust Scoring

| Option | Description | Selected |
|--------|-------------|----------|
| URL + version + last-commit + publisher, 3-tier trust | Full evidence with HIGH/MEDIUM/LOW scoring | Yes |
| URL only, binary verified/unverified | Simpler but less informative | |
| URL + stars count only | Middle ground | |

**User's choice:** [auto] Full evidence with 3-tier trust scoring (locked by INTG-03 and INTG-04)
**Notes:** Aligns with MCP Server Discovery Protocol already defined in CLAUDE.md.

---

## Confirmation Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Sequential per-agent with enhanced contract cards | One agent at a time, reuses design card format | Yes |
| Batch confirmation (all agents in one table) | Faster but less thorough | |
| Sequential per-agent with new format | Custom confirmation format | |

**User's choice:** [auto] Sequential per-agent with enhanced contract cards (recommended, reuses D-05 from Phase 3)
**Notes:** Consistent with SKILL.md philosophy: "cost of a bad design is 10x the cost of one more question."

---

## Dry Run Protocol

| Option | Description | Selected |
|--------|-------------|----------|
| Prompt-level stubbing + optional hook enforcement | Instruct agents to simulate, research hook enforcement | Yes |
| Code-level stubbing (mock MCP responses) | More reliable but requires custom code | |
| No stubbing, use sandbox/test accounts | Requires separate test infrastructure | |

**User's choice:** [auto] Prompt-level stubbing with hook enforcement research (recommended default)
**Notes:** Research should investigate PreToolUse hook blocking as enforcement layer. Flagged in STATE.md blockers.

---

## Security Integration Points

| Option | Description | Selected |
|--------|-------------|----------|
| Cross-reference credentials.md and prompt-injection.md during integration analysis | Full security integration | Yes |
| Security review only during confirmation, not integration | Deferred security | |

**User's choice:** [auto] Full security integration during analysis phase (recommended, aligns with Phase 2 security-first architecture)

---

## Claude's Discretion

- Integration decision matrix table format (as long as core fields present)
- Low-trust integration presentation style
- Dry run record count default
- Dry run report detail level
