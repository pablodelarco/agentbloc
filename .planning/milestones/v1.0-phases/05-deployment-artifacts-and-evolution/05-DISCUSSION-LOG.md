# Phase 5: Deployment Artifacts and Evolution - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 05-deployment-artifacts-and-evolution
**Mode:** --auto (all decisions auto-selected)
**Areas discussed:** Artifact structure, Template detail, Scheduling, Telegram, Evolution, Deployment guide

---

## Artifact Directory Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Flat with subdirectories | team.yaml at root, agents/, state/, jobs/ subdirs | Yes |
| Completely flat | All files at .agentbloc/ root | |
| Deep nesting | .agentbloc/config/agents/team-name/agent-name/ | |

**User's choice:** [auto] Flat with subdirectories (aligned with CLAUDE.md deployment infrastructure)

---

## Template Detail Level

| Option | Description | Selected |
|--------|-------------|----------|
| Arco Rooms grounded | Real field values from reference implementation | Yes |
| Generic placeholders | Abstract {agent-name} style templates | |
| Multiple examples | One per topology type | |

**User's choice:** [auto] Arco Rooms grounded (consistent with Phases 3-4 approach)

---

## Scheduling Patterns

| Option | Description | Selected |
|--------|-------------|----------|
| Standard cron + DST-safe + no holidays | 5-field cron, local timezone, avoid 01-03 DST window | Yes |
| Advanced with holiday support | Cron + holiday calendar integration | |
| Event-driven only | No cron, all webhook/event triggers | |

**User's choice:** [auto] Standard cron + DST-safe (per CLAUDE.md: system cron + claude -p)

---

## Telegram Patterns

| Option | Description | Selected |
|--------|-------------|----------|
| Thread-per-domain + 3 tiers + approval-by-reply | Full Telegram integration with structured reporting | Yes |
| Simple flat messages | No threading, no tiers | |
| Slack-first | Telegram as secondary | |

**User's choice:** [auto] Full Telegram integration (per CLAUDE.md and Arco Rooms pattern 7)

---

## Evolution Protocol

| Option | Description | Selected |
|--------|-------------|----------|
| Weekly scan + human approval | Configurable frequency, mandatory approval gate | Yes |
| Continuous monitoring | Real-time scanning (higher cost) | |
| Manual only | User triggers evolution checks | |

**User's choice:** [auto] Weekly scan + human approval (per EVOL-01 through EVOL-05)

---

## Deployment Guide Format

| Option | Description | Selected |
|--------|-------------|----------|
| SUMMARY.md with full sections | Prerequisites through troubleshooting | Yes |
| Minimal README | Just installation steps | |
| Interactive setup wizard | Claude walks through setup | |

**User's choice:** [auto] Full SUMMARY.md (per DEPL-09)

---

## Claude's Discretion

- YAML field ordering within templates
- Telegram message formatting details
- Evolution scan implementation specifics
- Incident response runbook structure
