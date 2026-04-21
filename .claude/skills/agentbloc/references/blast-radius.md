# Blast-Radius Scoring

> Security reference loaded by SKILL.md during Design Phase when assigning risk scores to each agent.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Scoring Levels](#scoring-levels)
- [Scoring Decision Tree](#scoring-decision-tree)
- [Approval Matrix](#approval-matrix)
- [Permission Minimization Checklist](#permission-minimization-checklist)
- [Artifact Template](#artifact-template)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file during the Design Phase when assigning blast-radius scores to each agent in the team. The score determines approval requirements and permission constraints in governance.yaml and agent.yaml. The framework follows the principle of least privilege, aligned with OWASP LLM06:2025 (Excessive Agency).

## Scoring Levels

Each agent receives one of four blast-radius levels based on what it can do:

| Level | Name | Tool Access | Data Access | External Comms | Approval |
|-------|------|-------------|-------------|----------------|----------|
| 1 | read-only | Read, Grep, Glob, WebFetch | Read-only access to state files | None | Not required |
| 2 | write-scoped | Read + Write to specific paths | Read/write to designated state files | None | Not required |
| 3 | write-unrestricted | Read + Write + Bash (restricted) | Read/write to any state file | None | Required |
| 4 | send-external | All tools + MCP servers with external side effects | Full data access | Sends emails, messages, API calls | Required |

Level is assigned based on the agent's maximum capability, not its typical behavior. If an agent can send external messages, it is Level 4 even if it only does so occasionally.

## Scoring Decision Tree

For each agent in the team design, follow these steps:

**Step 1: Does the agent send data externally?**
- Sends emails, Telegram messages, API POST/PUT/DELETE to third-party services, or webhook calls?
- YES: **Level 4 (send-external)**
- NO: Continue to Step 2.

**Step 2: Does the agent write to files or databases without path restrictions?**
- Can write to arbitrary paths, run unrestricted Bash commands, or modify any state file?
- YES: **Level 3 (write-unrestricted)**
- NO: Continue to Step 3.

**Step 3: Does the agent write to specific, pre-defined state files only?**
- Writes are limited to designated paths (e.g., `.agentbloc/state/invoices.json`)?
- YES: **Level 2 (write-scoped)**
- NO: Continue to Step 4.

**Step 4: Agent only reads data.**
- No write operations, no external communication, read-only access.
- **Level 1 (read-only)**

## Approval Matrix

Blast-radius level determines whether an agent runs autonomously or requires human approval before side effects:

| Level | requires_approval | Behavior |
|-------|-------------------|----------|
| 1 (read-only) | `false` | Agent runs autonomously on schedule |
| 2 (write-scoped) | `false` | Agent runs autonomously, writes to designated paths only |
| 3 (write-unrestricted) | `true` | Agent pauses before write operations, sends approval request via Telegram, waits for human confirmation |
| 4 (send-external) | `true` | Agent pauses before any external send, sends approval request via Telegram with preview of outbound data, waits for human confirmation |

**Dry run override:** During the mandatory dry run phase (Phase 4), ALL agents regardless of blast-radius level have their side-effect tools stubbed. No actual writes or external sends occur during dry run.

## Permission Minimization Checklist

During Design, Claude runs through these questions for each agent to push its blast-radius as low as possible:

- [ ] **Can this agent do its job with read-only access?** If yes, assign Level 1. A collector that reads invoices from a portal does not need write access.
- [ ] **Can write access be scoped to specific files or paths?** If yes, assign Level 2 instead of Level 3. Define the exact paths in `restricted_paths.write`.
- [ ] **Can external sends be consolidated into a single reporting agent?** If yes, move all outbound communication to one Level 4 reporter agent and keep other agents at Level 1-2. This concentrates blast radius in one controlled agent.
- [ ] **Can the agent use a scoped API key instead of an admin token?** If yes, reduce credential-based blast radius (see credentials.md decision tree).
- [ ] **Does the agent need Bash access?** If not, exclude Bash from `allowed_tools`. Bash is the highest-risk tool for unintended side effects.

The goal is to have most agents at Level 1-2, with only one or two agents at Level 3-4 (typically the reporter and the deployer).

## Artifact Template

The blast-radius configuration block in agent.yaml:

```yaml
blast_radius:
  level: 2
  classification: write-scoped
  requires_approval: false
  allowed_tools:
    - Read
    - Write
    - Glob
    - mcp__google_sheets__update
  restricted_paths:
    write: [".agentbloc/state/invoices.json"]
    read: ["*"]
```

**Level 4 example (reporter agent):**

```yaml
blast_radius:
  level: 4
  classification: send-external
  requires_approval: true
  allowed_tools:
    - Read
    - Glob
    - mcp__telegram__send_message
    - mcp__telegram__send_document
  restricted_paths:
    write: [".agentbloc/state/report-log.json"]
    read: ["*"]
  approval_channel: telegram
  approval_timeout_minutes: 60
```

The `blast_radius` block is consumed by governance.yaml during deployment to enforce tool restrictions and approval gates.

## Quick Reference

| Level | Classification | Autonomous | Typical Role |
|-------|---------------|------------|--------------|
| 1 | read-only | Yes | Data collector, monitor, checker |
| 2 | write-scoped | Yes | Processor, state updater, reconciler |
| 3 | write-unrestricted | No -- needs approval | System admin, config modifier |
| 4 | send-external | No -- needs approval | Reporter, notifier, API caller |

**Design target:** Most agent teams should have 60-80% of agents at Level 1-2. If more than half the team is Level 3-4, revisit the permission minimization checklist.
