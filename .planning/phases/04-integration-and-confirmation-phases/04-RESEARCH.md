# Phase 4: Integration and Confirmation Phases - Research

**Researched:** 2026-04-14
**Domain:** Integration analysis protocol, trust scoring, step-by-step confirmation, dry run tool stubbing
**Confidence:** HIGH

## Summary

This phase populates two reference files (`references/phase-3-integration.md` and `references/phase-4-confirmation.md`) that define the conversational protocols Claude follows during the AgentBloc Integration Analysis and Confirmation + Dry Run phases. The integration protocol must instruct Claude to perform live evidence-based multi-method search per service, build a decision matrix, compute trust scores, and cross-reference security patterns from Phase 2. The confirmation protocol must define per-agent sequential approval and a mandatory dry run with tool stubbing.

The critical research question was whether Claude Code hooks (PreToolUse) can deterministically block tool calls for dry run mode. The answer is **yes, with correct implementation** -- but the implementation details are non-obvious and many published examples get it wrong. The correct approach uses exit code 0 with a JSON `hookSpecificOutput` containing `permissionDecision: "deny"`, NOT exit code 2 as many tutorials suggest. Exit code 2 signals a hook crash, not a policy denial. Additionally, subagent `tools` field restrictions provide a complementary enforcement layer by preventing write/send tools from being available at all during dry run.

A secondary finding is that MCP ecosystem trust scoring has matured significantly. The MCP Scorecard project provides a structured 4-category scoring framework (provenance, maintenance, popularity, permissions) that aligns with AgentBloc's 3-tier trust system. Security scanning of MCP servers has revealed significant vulnerability rates (82% path traversal, 36.7% SSRF), making trust scoring during integration analysis essential, not optional.

**Primary recommendation:** Implement a dual-layer dry run enforcement strategy (prompt-level instruction as primary, PreToolUse hook `permissionDecision: "deny"` as deterministic enforcement layer) and use the MCP Scorecard signal taxonomy to inform AgentBloc's trust scoring criteria.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Multi-method integration search follows a strict priority order per action: official API (best) > MCP server (native) > Playwright browser automation (scraping) > email scraping (Gmail MCP) > webhook interception (event-driven) > manual notification (last resort). Claude searches each method in order and stops presenting alternatives after finding 3 viable options.
- **D-02:** Integration decision matrix per service: one table per service showing recommended method, alternative method, and fallback method. Each row includes: method name, pros, cons, setup complexity (low/medium/high), and trust score. The user sees a clear recommendation with "why" for each service.
- **D-03:** Integration search uses live web search (WebSearch, WebFetch) to verify current availability. No integration is presented without evidence. Claude searches for npm packages, GitHub repos, MCP server directories (PulseMCP), and official API documentation.
- **D-04:** Every integration claim includes: URL (source), package version (if applicable), last-commit date (for GitHub repos), and publisher info. If any of these is missing, the integration is marked [UNVERIFIED] and the user is warned. An [UNVERIFIED] integration can still be recommended if no better option exists, but the user must acknowledge the risk.
- **D-05:** Trust score per dependency uses a 3-tier system (HIGH/MEDIUM/LOW) based on: HIGH = Official vendor-maintained or >500 GitHub stars with active maintenance (commit within 90 days); MEDIUM = Community-maintained, 100-500 stars, commit within 180 days, clear documentation; LOW = <100 stars, >180 days since last commit, unclear maintainer, or no documentation.
- **D-06:** Trust scoring references the MCP Server Discovery Protocol from CLAUDE.md for consistency.
- **D-07:** Per-agent confirmation reuses the contract card format from the design phase but enhances it with integration findings: each agent card now includes a "Selected Integrations" section showing the chosen method per service, the trust score, and the credential requirement.
- **D-08:** Step-by-step confirmation is strictly sequential: one agent at a time, user confirms or requests changes, then next agent. No batch confirmation.
- **D-09:** After all agents are individually confirmed, a final integration summary table shows the complete team with all integrations, trust scores, and credential requirements. This is the Phase 4 gate artifact.
- **D-10:** Mandatory dry run executes all agents against N real records (user-specified count, default 5). All side-effect tools stubbed. Read operations execute normally against real data.
- **D-11:** Dry run tool stubbing is achieved through explicit instruction in the agent skill files. Research should investigate whether Claude Code hooks (PreToolUse) can block specific tool calls as an enforcement layer.
- **D-12:** Dry run report format: structured markdown document showing per-agent results.
- **D-13:** During integration analysis, credential requirements per service are evaluated using the decision tree from references/credentials.md.
- **D-14:** Prompt injection risk is assessed per integration during analysis: agents that ingest external content are flagged and assigned defense layers from references/prompt-injection.md.

### Claude's Discretion
- Exact format of the integration decision matrix table (as long as it includes method, pros, cons, setup complexity, and trust score per row)
- How to present low-trust integrations (warning banner, inline note, or separate section)
- Dry run record count default (suggested 5, but Claude can adjust based on complexity)
- Whether the dry run report includes sample data previews or just summaries

### Deferred Ideas (OUT OF SCOPE)
- Automated MCP server health checking (pinging endpoints to verify availability)
- Integration version pinning (locking to specific MCP server versions for reproducibility)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTG-01 | Multi-method integration search per action: official API -> MCP server -> Playwright -> email scraping -> webhook | Priority chain protocol documented in Architecture Patterns; PulseMCP MCP server enables programmatic search; Arco Rooms example demonstrates full fallback chain |
| INTG-02 | Integration decision matrix per service: recommended + alternative + fallback, each with pros/cons/setup | Decision matrix template in Architecture Patterns; trust scoring data from MCP Scorecard informs per-row scoring |
| INTG-03 | Evidence protocol: every integration claim includes URL + package version + last-commit date; missing = marked [UNVERIFIED] | Evidence verification protocol documented; PulseMCP returns GitHub stars and package data; GitHub API provides commit dates |
| INTG-04 | Trust score per dependency: GitHub stars, publisher verification, last commit recency, known CVEs | MCP Scorecard 4-category scoring verified; AgentSeal security scanning for CVE detection; 3-tier mapping documented |
| INTG-05 | User reviews and approves all integration findings before proceeding | Integration gate protocol documented in Architecture Patterns |
| CONF-01 | Step-by-step confirmation: each agent presented individually with actions, integrations, outputs, failure handling, permissions | Enhanced contract card template documented; sequential flow pattern in Architecture Patterns |
| CONF-02 | Each agent individually approved; feedback triggers adjustment before moving to next agent | Sequential approval loop documented; change propagation rules specified |
| CONF-03 | Mandatory dry run: agents execute against N real records with all side-effect tools stubbed | Dual-layer enforcement strategy verified: prompt-level + PreToolUse hooks; correct implementation documented |
| CONF-04 | Dry run report generated: what ran, what would have been sent/written, any errors | Report template in Code Examples; per-agent result format specified |
| CONF-05 | User reviews dry run results and approves before deployment | Final approval gate protocol documented |
</phase_requirements>

## Standard Stack

This phase produces markdown reference files (conversational protocols). No npm packages or runtime dependencies are introduced. The "stack" is the set of tools and data sources the integration protocol instructs Claude to use during live sessions.

### Core: Integration Discovery Tools
| Tool | Purpose | Why Standard | Confidence |
|------|---------|--------------|------------|
| PulseMCP MCP Server | Programmatic search of 12,500+ MCP servers | Largest hand-reviewed directory; provides stars, package data per server | HIGH [VERIFIED: pulsemcp.com, github.com/orliesaurus/pulsemcp-server] |
| WebSearch + WebFetch | Live verification of API docs, npm packages, GitHub repos | Built-in Claude Code tools; required for evidence-based claims | HIGH [VERIFIED: built-in tools] |
| GitHub API (via gh CLI) | Last commit date, stars, contributor count, open issues | Standard git metadata source for trust scoring | HIGH [VERIFIED: built-in gh CLI] |

### Core: Trust Scoring Data Sources
| Source | What It Provides | How to Query | Confidence |
|--------|-----------------|--------------|------------|
| MCP Scorecard (mcp-scorecard) | 4-category trust score (provenance, maintenance, popularity, permissions) per server | JSON index at github.com/gigabrainobserver/mcp-scorecard, updated daily via GitHub Actions | HIGH [VERIFIED: github.com/gigabrainobserver/mcp-scorecard] |
| AgentSeal/awesome-mcp-security | Security scores for 800+ MCP servers; 9 analyzers for prompt injection, toxic flows, attack surface | GitHub repo, updated daily | MEDIUM [VERIFIED: github.com/AgentSeal/awesome-mcp-security] |
| npm registry | Package version, publish date, weekly downloads | `npm view <package> version` or WebSearch | HIGH [VERIFIED: npm registry] |

### Core: Dry Run Enforcement
| Mechanism | Purpose | Confidence |
|-----------|---------|------------|
| Prompt-level instruction (primary) | Agent skill files include "DRY RUN MODE" directive treating write/send operations as log-only | HIGH [VERIFIED: established Claude Code pattern] |
| PreToolUse hook with `permissionDecision: "deny"` (enforcement) | Deterministic hook blocks MCP write tools; exit 0 + JSON hookSpecificOutput | HIGH [VERIFIED: code.claude.com/docs/en/hooks, github.com/anthropics/claude-code/issues/37210 resolution] |
| Subagent `tools` field restriction (belt-and-suspenders) | Subagent definition excludes write/send MCP tools entirely during dry run | HIGH [VERIFIED: code.claude.com/docs/en/sub-agents] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| PulseMCP MCP server | Manual WebSearch for each service | PulseMCP is programmatic and returns structured data; manual search is slower but catches newer servers not yet indexed |
| MCP Scorecard JSON | Manual GitHub star/commit checks | Scorecard provides batch data; manual checks are more current but slower per-service |
| PreToolUse "deny" hook | Exit code 2 only | Exit code 2 works but signals "hook crashed" not "policy denied"; the JSON deny approach gives Claude a reason message and is the documented correct path |

## Architecture Patterns

### Recommended Reference File Structure

Both files follow the established pattern from Phase 2/3 security reference files:

```
references/
  phase-3-integration.md     # ~300-400 lines
  phase-4-confirmation.md    # ~250-350 lines
```

### Pattern 1: Integration Analysis Protocol Structure

```markdown
# Deep Integration Analysis Protocol

## Table of Contents
## When This Applies
## Integration Opening
## Step 1: Service Inventory (from Design)
## Step 2: Multi-Method Search Protocol (INTG-01)
## Step 3: Evidence Verification (INTG-03)
## Step 4: Trust Scoring (INTG-04)
## Step 5: Decision Matrix Construction (INTG-02)
## Step 6: Security Cross-Reference (D-13, D-14)
## Step 7: Integration Presentation and Approval (INTG-05)
## Integration Gate
## Quick Reference
```

**Key design principle:** The protocol is a SCRIPT that Claude follows step-by-step for each service identified in the design phase. It must be prescriptive ("do this, then this") not descriptive ("consider doing this").

### Pattern 2: Multi-Method Search Protocol

For each service/action identified in the design phase:

1. **Check official API:** WebSearch for `{service_name} API documentation`. If found, record URL, authentication method, rate limits
2. **Check MCP servers:** Search PulseMCP for `{service_name}`. If found, record package name, GitHub stars, last commit, publisher
3. **Check Playwright path:** If no API/MCP, WebSearch for `{service_name} login portal`. Note if browser automation via Playwright is viable
4. **Check email integration:** If the service sends notification emails, Gmail MCP can scrape structured data
5. **Check webhook support:** WebSearch for `{service_name} webhook API`. Note if event-driven integration is possible
6. **Last resort:** Manual notification via Telegram asking the user to handle the action

Stop after finding 3 viable options (D-01). Present as decision matrix (D-02).

### Pattern 3: Evidence Verification Format

Every integration claim in the decision matrix must include:

```markdown
| Field | Required | Source |
|-------|----------|--------|
| URL | Yes | WebSearch result or official docs link |
| Package version | If applicable | npm view or GitHub release page |
| Last commit date | For GitHub repos | GitHub repo page or gh CLI |
| Publisher | Yes | npm publisher, GitHub org, or company name |
| Trust score | Yes | Computed from D-05 criteria |
```

If any required field cannot be found, mark as `[UNVERIFIED]`:

```markdown
| Method | Package | Version | Last Commit | Trust | Status |
|--------|---------|---------|-------------|-------|--------|
| Xero MCP | xero-mcp@beta | 0.3.x | 2026-03-15 | HIGH | Verified |
| Custom Playwright | N/A | N/A | N/A | N/A | [UNVERIFIED] -- no existing package; would be custom |
```

### Pattern 4: Trust Score Computation

Map the D-05 3-tier system to concrete evaluation criteria. This aligns with MCP Scorecard categories:

| Criterion | HIGH (auto-pass) | MEDIUM | LOW (flag) |
|-----------|-------------------|--------|------------|
| Publisher | Official vendor (Anthropic, Microsoft, Google, Slack, Xero, etc.) | Known community contributor | Unknown / anonymous |
| GitHub stars | >500 | 100-500 | <100 |
| Last commit | Within 90 days | 91-180 days | >180 days |
| Documentation | Comprehensive README + examples | README present | Minimal or absent |
| Known CVEs | None | Historical (patched) | Active unpatched |
| Package registry | Published to npm/PyPI | GitHub release only | Source code only |

**Scoring rule:** Trust level = minimum across all criteria. If any single criterion is LOW, overall trust is LOW regardless of other scores. [ASSUMED]

### Pattern 5: Confirmation Protocol Structure

```markdown
# Step-by-Step Confirmation and Dry Run Protocol

## Table of Contents
## When This Applies
## Confirmation Opening
## Step 1: Enhanced Contract Card Format (CONF-01)
## Step 2: Sequential Agent Approval (CONF-02)
## Step 3: Integration Summary Gate (D-09)
## Step 4: Dry Run Configuration (CONF-03)
## Step 5: Dry Run Execution
## Step 6: Dry Run Report (CONF-04)
## Step 7: Final Approval Gate (CONF-05)
## Quick Reference
```

### Pattern 6: Enhanced Contract Card (Confirmation Phase)

The design phase contract card (from references/phase-2-design.md) is enhanced with integration data:

```markdown
### Agent: [Agent Name]

| Field | Value |
|-------|-------|
| **Role** | [from design phase] |
| **Responsibility** | [from design phase] |
| **Inputs** | [from design phase] |
| **Outputs** | [from design phase] |
| **Dependencies** | [from design phase] |
| **Tools** | [from design phase] |
| **Trigger** | [from design phase] |
| **Blast Radius** | [from design phase] |
| **Approval Required** | [from design phase] |
| **Model** | [from design phase] |
| **Failure Handling** | [from design phase] |

**Selected Integrations:**

| Service | Method | Trust | Credential | Setup |
|---------|--------|-------|------------|-------|
| [service] | [recommended method from matrix] | [HIGH/MEDIUM/LOW] | [OAuth/API key/admin per credentials.md] | [low/medium/high] |

**Prompt Injection Defense:** [updated from integration analysis per D-14]

**Credential Summary:**
| Service | Credential Type | Scope | Rotation | Env Variable |
|---------|----------------|-------|----------|--------------|
| [service] | [OAuth/scoped API key/admin] | [scope] | [days] | AGENTBLOC_{SERVICE}_{TYPE} |
```

### Pattern 7: Dry Run Enforcement (Dual-Layer)

**Layer 1: Prompt-level instruction (primary)**

In the agent skill .md file, when dry run is active:

```markdown
## DRY RUN MODE ACTIVE

You are executing in DRY RUN mode. The following rules override all other instructions:

1. READ operations proceed normally against real data
2. WRITE operations (file writes, state updates): Log what WOULD be written, return simulated success
3. SEND operations (Telegram, email, API POST/PUT/DELETE): Log what WOULD be sent, return simulated success
4. Log format for each stubbed operation:
   [DRY RUN] Tool: {tool_name} | Target: {target} | Would have: {action description}
5. Never execute a write or send operation in dry run mode
```

**Layer 2: PreToolUse hook enforcement (deterministic)**

```bash
#!/bin/bash
# .agentbloc/hooks/dry-run-enforcer.sh
# Blocks write/send MCP tools during dry run mode

# Check if dry run is active
if [ ! -f ".agentbloc/DRY_RUN_ACTIVE" ]; then
  exit 0  # Not in dry run mode, allow everything
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Define write/send tool patterns to block
BLOCKED_PATTERNS=(
  "mcp__telegram__send"
  "mcp__gmail__send"
  "mcp__shopify__create"
  "mcp__shopify__update"
  "mcp__xero__create"
  "mcp__xero__update"
  "mcp__stripe__create"
)

for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$TOOL_NAME" == *"$PATTERN"* ]]; then
    # CORRECT: Exit 0 with deny JSON, NOT exit 2
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"DRY RUN: $TOOL_NAME blocked. Side-effect tools are stubbed during dry run.\"}}"
    exit 0
  fi
done

# Also block Write/Edit to external paths during dry run
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
  # Allow writes to dry run report and log files
  if [[ "$FILE_PATH" != *".agentbloc/dry-run-report"* && "$FILE_PATH" != *".agentbloc/logs"* ]]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"DRY RUN: Write to $FILE_PATH blocked. Only dry run reports and logs are writable.\"}}"
    exit 0
  fi
fi

exit 0
```

**Hook configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__*|Write|Edit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .agentbloc/hooks/dry-run-enforcer.sh"
          }
        ]
      }
    ]
  }
}
```

**Layer 3: Subagent tool restriction (belt-and-suspenders)**

During dry run, agent subagent definitions use the `tools` field to exclude write/send MCP tools entirely:

```yaml
---
name: invoice-collector-dryrun
description: Dry run version of invoice-collector with read-only tools
tools: Read, Grep, Glob, WebSearch, WebFetch, mcp__playwright__navigate, mcp__playwright__snapshot
# Note: NO mcp__telegram, NO mcp__shopify__create, etc.
---
```

### Anti-Patterns to Avoid

- **Exit code 2 for PreToolUse deny:** Exit code 2 means "hook crashed," not "policy denied." Claude Code may ignore it and proceed. Use exit 0 + JSON with `permissionDecision: "deny"`. [VERIFIED: github.com/anthropics/claude-code/issues/37210]
- **Exit code 1 for PreToolUse deny:** Exit code 1 is treated as a non-blocking error. The tool proceeds anyway. [VERIFIED: code.claude.com/docs/en/hooks]
- **Flat JSON deny without hookSpecificOutput wrapper:** The deny JSON MUST be wrapped in `{"hookSpecificOutput": {...}}`. Flat JSON is not parsed correctly. [VERIFIED: github.com/anthropics/claude-code/issues/37210]
- **Trusting a single integration source:** Never present an integration based solely on PulseMCP listing. Cross-verify with the actual GitHub repo, npm registry, or official docs.
- **Batch agent confirmation:** D-08 explicitly requires sequential, one-at-a-time confirmation. Never present all agents at once for bulk approval.
- **Prompt-only dry run without enforcement:** Prompt-level instructions are the primary mechanism but are not deterministic. The hook layer provides a safety net for the cases where the LLM doesn't follow the instruction perfectly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MCP server discovery | Manual WebSearch per service | PulseMCP MCP Server (`list_servers` tool) | 12,500+ servers indexed with structured metadata; manual search misses options |
| Trust scoring data | Scrape GitHub manually for each dependency | MCP Scorecard JSON index + AgentSeal security scores | Pre-computed daily, covers 2,300+ servers with 4-category scoring |
| Integration evidence format | Ad-hoc URL collection | Standardized evidence template (URL, version, commit date, publisher, trust) | Consistency across all integrations; [UNVERIFIED] marking prevents false confidence |
| Dry run enforcement | Prompt-only instruction | Dual-layer: prompt + PreToolUse hook + subagent tool restriction | Prompt is not deterministic; hook provides safety net; tool restriction prevents tool availability |
| Contract card enhancement | Redesign the card format | Extend the existing Phase 2 design template with integration fields | Consistency with prior phase; user already understands the format |

## Common Pitfalls

### Pitfall 1: PreToolUse Hook Implementation Errors
**What goes wrong:** Developers use exit code 2 or exit code 1 to deny tool execution. Claude Code treats both as hook errors, not policy denials, and may proceed with the tool call.
**Why it happens:** Most tutorials and blog posts show exit code 2 for blocking. The official documentation describes the JSON `permissionDecision: "deny"` approach but it is not prominently featured.
**How to avoid:** ALWAYS use exit 0 + JSON with `hookSpecificOutput.permissionDecision: "deny"`. Never rely on non-zero exit codes for policy enforcement.
**Warning signs:** Audit logs showing tool calls that should have been blocked; dry run producing real side effects.

### Pitfall 2: Stale Integration Data
**What goes wrong:** Integration analysis presents outdated package versions, deprecated MCP servers, or dead GitHub repos as viable options.
**Why it happens:** MCP ecosystem evolves rapidly. Servers get archived. npm packages get deprecated. Training data is months stale.
**How to avoid:** The protocol must mandate live verification (WebSearch + WebFetch) for every integration claim. Never recommend from memory alone. Check last commit date explicitly.
**Warning signs:** [UNVERIFIED] markers appearing on multiple integrations; GitHub repos showing "archived" status.

### Pitfall 3: Trust Score Inflation
**What goes wrong:** An MCP server appears well-maintained (recent commits, decent stars) but has unpatched security vulnerabilities or processes data unsafely.
**Why it happens:** Stars and commit recency don't measure code quality. 82% of MCP servers surveyed have path traversal vulnerabilities. [VERIFIED: AgentSeal scan results]
**How to avoid:** Trust score is a starting point, not a guarantee. For MCP servers handling PII/PHI/financial data, add a security dimension: check AgentSeal scores, note known CVEs, and flag servers that lack SECURITY.md.
**Warning signs:** HIGH trust score on a server with known CVEs; server processing sensitive data without security documentation.

### Pitfall 4: Confirmation Fatigue
**What goes wrong:** User rubber-stamps agent approvals without reading the details because the cards are too long or too technical.
**Why it happens:** Sequential per-agent approval (D-08) can feel tedious for teams with 5+ agents. Non-technical users may not understand all fields.
**How to avoid:** The protocol should adapt card detail level to the user's tech level (from SKILL.md). Non-technical users see a plain-language summary before the full card. Key changes from the design phase are highlighted.
**Warning signs:** User approving agents in <5 seconds; user saying "just approve them all."

### Pitfall 5: Dry Run Scope Mismatch
**What goes wrong:** Dry run executes against too few records (1-2) to surface real edge cases, or too many records (100+) consuming excessive tokens.
**Why it happens:** Default of 5 records was chosen arbitrarily. Different workflows have different edge case densities.
**How to avoid:** Let the user specify record count (D-10 default 5). Claude should suggest a count based on workflow complexity: simple workflows need fewer, multi-provider workflows need more. Always include at least one edge case record if possible.
**Warning signs:** Dry run report showing 100% success on trivially simple records; dry run consuming >50K tokens per agent.

### Pitfall 6: MCP Security Vulnerabilities in Dependencies
**What goes wrong:** An integration dependency has known vulnerabilities (path traversal, SSRF, command injection) that go undetected during analysis.
**Why it happens:** Between January-February 2026, 30+ CVEs were filed against MCP servers. 82% of surveyed implementations have path traversal vulnerabilities.
**How to avoid:** During trust scoring, explicitly check AgentSeal security scores and search for known CVEs. For any MCP server handling PII/PHI/financial data, a security check is mandatory, not optional.
**Warning signs:** MCP server not in AgentSeal database; server with HIGH star count but no SECURITY.md; recent CVE advisories on GitHub.

## Code Examples

### Integration Decision Matrix Template

```markdown
### [Service Name] Integration Options

| # | Method | Package/Tool | Trust | Setup | Pros | Cons |
|---|--------|-------------|-------|-------|------|------|
| 1 | **Official API** | `{package}` v{ver} | HIGH | Medium | Direct, reliable, documented | Requires OAuth setup |
| 2 | MCP Server | `{mcp-server}` ({stars} stars) | MEDIUM | Low | Native Claude Code, easy setup | Community-maintained |
| 3 | Playwright | @playwright/mcp | HIGH | High | Works for any web portal | Brittle, token-intensive |

**Evidence:**
- API docs: [{url}] (verified {date})
- MCP server: [{github_url}] (last commit: {date}, {stars} stars)
- Package: [{npm_url}] (v{version}, published {date})

**Recommendation:** Option 1 (Official API) provides the most reliable path.
Fallback to Option 2 (MCP Server) if OAuth setup is prohibitive.
Option 3 (Playwright) reserved as last resort.

**Credential requirement:** OAuth 2.0 with `{scope}` scope (per references/credentials.md)
**Prompt injection risk:** [Layers 1,2,3 / None] (per references/prompt-injection.md)
```

### Enhanced Contract Card (Confirmation Phase)

```markdown
### Agent: Invoice Collector

| Field | Value |
|-------|-------|
| **Role** | Invoice Collection Specialist |
| **Responsibility** | Fetch new invoices from utility providers |
| **Inputs** | Provider credentials (env vars), state/processed-invoices.json |
| **Outputs** | state/invoices.json (new invoices appended) |
| **Dependencies** | None (first in pipeline) |
| **Tools** | Read, Write, Glob, mcp__xero__*, mcp__playwright__* |
| **Trigger** | Daily at 22:00 (`0 22 * * *`) |
| **Blast Radius** | Level 2 (write-scoped) |
| **Approval Required** | No |
| **Model** | Sonnet |
| **Failure Handling** | Retry 3x per provider, skip on persistent failure, alert via Telegram |

**Selected Integrations:**

| Service | Method | Trust | Credential | Setup |
|---------|--------|-------|------------|-------|
| Xero | Official MCP (xero-mcp@beta) | HIGH | OAuth 2.0 (read:invoices) | Medium |
| Endesa | Playwright browser automation | HIGH (Microsoft) | Web login (env vars) | High |
| Gmail (invoice emails) | Google Workspace MCP | HIGH | OAuth 2.0 (gmail.readonly) | Medium |

**Prompt Injection Defense:** Layers 1, 2, 3 (ingests emails and web pages)

**Credential Summary:**
| Service | Type | Scope | Rotation | Env Variable |
|---------|------|-------|----------|--------------|
| Xero | OAuth 2.0 | read:invoices | Auto-refresh | AGENTBLOC_XERO_CLIENT_ID, AGENTBLOC_XERO_CLIENT_SECRET |
| Endesa | Web login | Portal access | 90 days | AGENTBLOC_ENDESA_USER, AGENTBLOC_ENDESA_PASS |
| Gmail | OAuth 2.0 | gmail.readonly | Auto-refresh | AGENTBLOC_GOOGLE_OAUTH_CLIENT_ID, AGENTBLOC_GOOGLE_OAUTH_CLIENT_SECRET |
```

### Dry Run Report Template

```markdown
# Dry Run Report

**Team:** {team_name}
**Date:** {date}
**Records processed:** {N} per agent
**Mode:** DRY RUN (all side-effect tools stubbed)

## Per-Agent Results

### Agent: Invoice Collector
**Status:** PASS

| # | Operation | Type | Target | Result |
|---|-----------|------|--------|--------|
| 1 | Read invoices from Xero | READ (real) | Xero API | 3 invoices retrieved |
| 2 | Read emails from Gmail | READ (real) | Gmail MCP | 2 invoice emails found |
| 3 | Navigate Endesa portal | READ (real) | Playwright | Portal loaded, 1 invoice found |
| 4 | Write to state/invoices.json | WRITE (stubbed) | .agentbloc/state/invoices.json | [DRY RUN] Would append 6 invoice records |
| 5 | Send notification | SEND (stubbed) | Telegram operations thread | [DRY RUN] Would send: "6 new invoices collected" |

**Errors:** None
**Verdict:** PASS

### Agent: Payment Matcher
**Status:** PASS (with warnings)

| # | Operation | Type | Target | Result |
|---|-----------|------|--------|--------|
| 1 | Read bank transactions | READ (real) | Bank MCP | 12 transactions retrieved |
| 2 | Read invoices state | READ (real) | .agentbloc/state/invoices.json | 6 invoices loaded |
| 3 | Match transactions | PROCESS | In-memory | 4 high-confidence, 1 low-confidence, 1 unmatched |
| 4 | Write matches | WRITE (stubbed) | .agentbloc/state/matches.json | [DRY RUN] Would write 5 match records |
| 5 | Flag for review | SEND (stubbed) | Telegram | [DRY RUN] Would send: "1 low-confidence match needs review" |

**Warnings:** 1 transaction could not be matched (new tenant not in mapping)
**Verdict:** PASS (unmapped entity expected for new tenants)

## Summary

| Agent | Read Ops | Write Ops (stubbed) | Send Ops (stubbed) | Errors | Verdict |
|-------|----------|--------------------|--------------------|--------|---------|
| Invoice Collector | 3 | 1 | 1 | 0 | PASS |
| Payment Matcher | 2 | 1 | 1 | 0 | PASS |
| Report Sender | 1 | 0 | 3 | 0 | PASS |

**Overall:** All agents passed dry run. Proceed to deployment?

Review these results and confirm to proceed, or request changes.
```

### PreToolUse Hook Correct Implementation

Source: [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks), [github.com/anthropics/claude-code/issues/37210](https://github.com/anthropics/claude-code/issues/37210) (resolution comment)

```bash
#!/bin/bash
# CORRECT: Exit 0 with JSON deny
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ "$TOOL_NAME" == mcp__telegram__send* ]]; then
  # Correct approach: exit 0 with hookSpecificOutput
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"DRY RUN: Telegram send blocked"}}'
  exit 0
fi

# WRONG (common mistake): exit 2 -- this signals "hook crashed"
# echo "Blocked" >&2
# exit 2

exit 0
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Exit code 2 for PreToolUse blocking | Exit 0 + JSON `permissionDecision: "deny"` | Clarified March 2026 (issue #37210) | Previous approach unreliable; JSON approach is the documented correct path |
| Manual GitHub checks for MCP trust | MCP Scorecard automated scoring | 2026 Q1 | 4-category scoring across 2,300+ servers; daily updates |
| Trust by star count alone | Multi-factor trust + CVE scanning | 2026 Q1 (30+ CVEs filed Jan-Feb 2026) | Stars don't measure security; 82% of MCP servers have path traversal vulnerabilities |
| PulseMCP web browsing | PulseMCP MCP Server (programmatic) | Available since 2025 | Structured search via `list_servers` tool; returns metadata per server |
| Subagent inherited all tools | `tools` and `disallowedTools` fields | Claude Code v2.1+ | Subagents can be restricted to read-only tools for dry run |

**Deprecated/outdated:**
- `preventContinuation: true` in hook responses: deprecated/not implemented; use `permissionDecision: "deny"` instead [VERIFIED: github.com/anthropics/claude-code/issues/3514 closed as NOT_PLANNED]
- `{"continue": false}` hook response format: not supported; use `hookSpecificOutput` wrapper [VERIFIED: same issue]
- modelcontextprotocol/gdrive (archived): replaced by taylorwilsdon/google_workspace_mcp [VERIFIED: CLAUDE.md stack documentation]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Trust score minimum rule: overall trust = minimum across all criteria (if any criterion is LOW, overall is LOW) | Architecture Patterns, Pattern 4 | Low risk. This is the most conservative approach. Could be relaxed to weighted average if users find it too strict. |
| A2 | Dry run report should include actual data previews (redacted) for READ operations, not just summaries | Code Examples | Low risk. Claude's discretion per CONTEXT.md allows either approach. |
| A3 | PreToolUse deny with exit 0 + JSON approach works reliably in Claude Code v2.2+ | Architecture Patterns, Pattern 7 | HIGH risk if wrong. The dual-layer strategy mitigates this: prompt instruction + subagent tool restriction still work even if hooks fail. |

## Open Questions

1. **PulseMCP MCP Server availability during AgentBloc sessions**
   - What we know: PulseMCP MCP server exists (github.com/orliesaurus/pulsemcp-server) and provides `list_servers` and `list_integrations` tools
   - What's unclear: Whether the protocol should instruct Claude to configure PulseMCP MCP server on-the-fly or assume it is pre-configured. Also unclear if PulseMCP returns enough metadata (last commit date specifically) or if GitHub API calls are still needed
   - Recommendation: The protocol should instruct Claude to use WebSearch for PulseMCP.com as the primary discovery path (does not require MCP server setup) and note the MCP server as an optional accelerator. GitHub API calls via `gh` CLI for commit dates remain necessary either way.

2. **Blocked MCP tools list for dry run**
   - What we know: The hook needs a list of tool name patterns to block. Write/send patterns are service-specific (e.g., `mcp__telegram__send_message`, `mcp__xero__create_invoice`)
   - What's unclear: The exact tool names vary per MCP server and cannot be known in advance during protocol authoring
   - Recommendation: The protocol should generate the blocked-tools list dynamically from the integration analysis results. During confirmation, the list of "side-effect tools" per agent is captured. During dry run setup, this list is converted into hook matcher patterns.

3. **Dry run interaction model**
   - What we know: The dry run must execute agents against real data with side effects stubbed
   - What's unclear: Whether Claude runs the dry run within the same conversation session (interpreting what each agent would do) or whether it spawns actual Claude Code subagents with restricted tools
   - Recommendation: For v1.0, the dry run is a conversational simulation within the AgentBloc session. Claude walks through what each agent would do step-by-step, executing real reads and logging simulated writes. This avoids the complexity of spawning and configuring actual subagents during the design conversation. The deployment phase (Phase 5) can generate actual subagent definitions with dry-run hooks for post-deployment testing.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual scenario testing (markdown-based) |
| Config file | None (Phase 7 scope, TEST-01 through TEST-03) |
| Quick run command | Manual review of reference file against requirements checklist |
| Full suite command | Full 6-phase scenario replay (Phase 7 scope) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTG-01 | Multi-method search produces at least 3 methods per service | manual-only | Review phase-3-integration.md search protocol section | N/A |
| INTG-02 | Decision matrix per service has recommended + alternative + fallback | manual-only | Review decision matrix template completeness | N/A |
| INTG-03 | Every claim has URL + version + commit date or [UNVERIFIED] marker | manual-only | Review evidence template and [UNVERIFIED] protocol | N/A |
| INTG-04 | Trust score evaluates stars, publisher, commit recency, CVEs | manual-only | Review trust scoring criteria table | N/A |
| INTG-05 | User approval gate exists at end of integration phase | manual-only | Review integration gate section | N/A |
| CONF-01 | Enhanced contract card has all required fields | manual-only | Review enhanced card template against D-07 spec | N/A |
| CONF-02 | Sequential approval with change loop documented | manual-only | Review approval flow section | N/A |
| CONF-03 | Dry run protocol covers tool stubbing, record count, execution model | manual-only | Review dry run sections for completeness | N/A |
| CONF-04 | Dry run report template has per-agent results, summary, verdict | manual-only | Review report template against D-12 spec | N/A |
| CONF-05 | Final approval gate exists after dry run | manual-only | Review final gate section | N/A |

### Sampling Rate
- **Per task commit:** Manual review against requirement checklist
- **Per wave merge:** Cross-reference against all 10 requirement IDs
- **Phase gate:** All 10 requirements verified as addressed

### Wave 0 Gaps
None. This phase produces markdown reference files, not code. Validation is structural review against requirements, not automated testing. Full scenario testing is Phase 7 scope (TEST-01 through TEST-03).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes (credential evaluation) | Credential decision tree from references/credentials.md |
| V3 Session Management | No (no sessions in reference files) | N/A |
| V4 Access Control | Yes (blast-radius, tool restrictions) | references/blast-radius.md scoring + subagent tool restrictions |
| V5 Input Validation | Yes (prompt injection defense) | references/prompt-injection.md 4-layer pipeline |
| V6 Cryptography | No (no crypto in reference files) | N/A |

### Known Threat Patterns for Integration Analysis

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Recommending MCP server with known CVE | Tampering / Information Disclosure | Trust scoring with CVE check via AgentSeal; [UNVERIFIED] marking for unchecked servers |
| Stale integration data leading to broken deployments | Denial of Service | Live verification mandate; last-commit-date check |
| Prompt injection via ingested content during dry run | Tampering | 4-layer defense pipeline; content separation delimiters; dry run hooks block external sends |
| Dry run side effects leaking to production | Tampering | Dual-layer enforcement: prompt instruction + PreToolUse deny hook + subagent tool restriction |
| Over-permissioned credentials in integration | Elevation of Privilege | Credential decision tree enforcing least privilege (OAuth > scoped key > admin token) |

## Project Constraints (from CLAUDE.md)

Directives extracted from CLAUDE.md that apply to this phase:

- **Stack**: Pure Claude Code skill (markdown files only). The output is markdown reference files, not code.
- **SKILL.md size**: Capped at ~250 lines. Reference files handle the detail.
- **Progressive disclosure**: Reference files one level deep. No nested references.
- **Security**: GDPR patterns mandatory. HIPAA/PCI activated by data classification.
- **Compliance**: Integration analysis must cross-reference credentials.md, blast-radius.md, prompt-injection.md, gdpr-patterns.md when applicable.
- **Arco Rooms reference**: examples/arco-rooms.md demonstrates the full fallback chain pattern that the integration protocol should reference.
- **MCP Discovery Protocol**: Trust scoring aligns with HIGH/MEDIUM/LOW confidence ratings in CLAUDE.md stack documentation.
- **No TypeScript runtime**: All enforcement mechanisms (hooks, tool restrictions) must work within Claude Code's native capabilities.
- **Git commits**: No AI attribution in commit messages.

## Sources

### Primary (HIGH confidence)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- PreToolUse specification, exit codes, permissionDecision, hookSpecificOutput format
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents) -- tools/disallowedTools field, subagent YAML format, permission modes
- [GitHub Issue #37210 Resolution](https://github.com/anthropics/claude-code/issues/37210) -- Confirmed correct PreToolUse deny implementation (exit 0 + JSON, not exit 2)
- [MCP Scorecard](https://github.com/gigabrainobserver/mcp-scorecard) -- 4-category trust scoring framework for MCP servers
- [PulseMCP MCP Server](https://github.com/orliesaurus/pulsemcp-server) -- Programmatic MCP server discovery with structured metadata

### Secondary (MEDIUM confidence)
- [AgentSeal/awesome-mcp-security](https://github.com/AgentSeal/awesome-mcp-security) -- Security scores for 800+ MCP servers; vulnerability scanning
- [MCP Security 2026: 30 CVEs in 60 Days](https://www.heyuan110.com/posts/ai/2026-03-10-mcp-security-2026/) -- Context on MCP ecosystem vulnerability landscape
- [PulseMCP Directory](https://www.pulsemcp.com/servers) -- 12,500+ MCP servers indexed, hand-reviewed daily
- [GitHub Issue #3514](https://github.com/anthropics/claude-code/issues/3514) -- Historical context on PreToolUse blocking issues (closed NOT_PLANNED)

### Tertiary (LOW confidence)
- [GitHub Issue #21988](https://github.com/anthropics/claude-code/issues/21988) -- Exit code ignored bug report (used exit 1, not the correct approach)
- [MCP Server Vulnerability Scans](https://dev.to/manja316/we-scanned-5618-mcp-servers-for-security-vulnerabilities-heres-what-we-found-30k) -- 82% path traversal stat; community research, not peer-reviewed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All tools and data sources verified via official docs and GitHub
- Architecture: HIGH -- Patterns derived from established reference file structure + verified hook mechanism
- Pitfalls: HIGH -- Multiple primary sources confirm PreToolUse implementation issues; MCP security landscape well-documented
- Dry run enforcement: HIGH (with caveat A3) -- Correct implementation verified via issue #37210 resolution; dual-layer strategy mitigates any remaining hook reliability concerns

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (30 days -- MCP ecosystem moves fast but reference file patterns are stable)
