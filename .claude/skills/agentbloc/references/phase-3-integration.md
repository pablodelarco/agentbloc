# Deep Integration Analysis Protocol

> Loaded by SKILL.md at Phase 3 entry. Instructs Claude to research the best integration method for every service each agent needs, verify claims with live evidence, compute trust scores, build decision matrices, cross-reference security patterns, and present findings for user approval.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Integration Opening](#integration-opening)
- [Step 1: Service Inventory from Design](#step-1-service-inventory-from-design)
- [Step 2: Multi-Method Search Protocol](#step-2-multi-method-search-protocol)
- [Step 3: Evidence Verification](#step-3-evidence-verification)
- [Step 4: Trust Scoring](#step-4-trust-scoring)
- [Step 5: Decision Matrix Construction](#step-5-decision-matrix-construction)
- [Step 6: Security Cross-Reference](#step-6-security-cross-reference)
- [Step 7: Integration Presentation and Approval](#step-7-integration-presentation-and-approval)
- [Integration Gate](#integration-gate)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file when the user confirms the agent team design (Phase 2 gate approved) and Phase 3 begins. The design phase produced two artifacts that serve as input here:

1. **Agent summary table** listing all agents with their roles, blast-radius levels, and triggers
2. **Per-agent contract cards** listing each agent's tools, inputs, outputs, and dependencies

At Phase 3 entry, also load:
- [references/credentials.md](credentials.md) for the credential decision tree (used in Step 6)
- [references/prompt-injection.md](prompt-injection.md) for the defense layer pipeline (used in Step 6)

## Integration Opening

Present a brief explanation of what this phase does. Adapt to the user's technical level from the state bar.

**Non-technical:** "Now I'm going to research the best way to connect each of your agents to the services they need. I check real sources -- official documentation, package registries, developer communities -- so every recommendation is backed by evidence, not guesses. I'll show you the options and you'll pick the ones you prefer."

**Technical-basics:** "I'll research integration methods for each service in your agent team. For every service I'll search for official APIs, MCP servers, and browser automation paths, then present a decision matrix with trust scores so you can make informed choices."

**Developer:** "Integration analysis phase. For each service identified in the contract cards, I'll execute a multi-method search (API > MCP > Playwright > email > webhook > manual), verify each option with live evidence (URL, version, last commit, publisher), compute a 3-tier trust score, and build a decision matrix. You'll review and approve before confirmation."

## Step 1: Service Inventory from Design

Extract all unique services from the confirmed agent contract cards. Pull from the **Tools** and **Inputs** fields of each card.

### Process

1. Read each agent's contract card from the design phase output
2. List every external service, API, MCP server, or data source mentioned
3. Group services by agent to show which agent depends on which services
4. Deduplicate: if two agents use the same service, analyze it once and reference from both cards

### Service Inventory Template

Present this table to the user before starting analysis:

```markdown
| # | Service | Used By | Current Method (from design) | Analysis Status |
|---|---------|---------|------------------------------|-----------------|
| 1 | [service] | [agent name(s)] | [what design assumed] | Pending |
| 2 | [service] | [agent name(s)] | [what design assumed] | Pending |
```

Confirm with the user: "These are the services I'll research. Should I add any services I might have missed, or remove any that are no longer needed?"

## Step 2: Multi-Method Search Protocol

For each service in the inventory, search integration methods in this strict priority order. This follows decision D-01: official API (best) > MCP server (native) > Playwright browser automation > email scraping > webhook interception > manual notification (last resort).

### Priority 1: Official API

WebSearch for `{service_name} API documentation`. If found, record:
- API endpoint base URL
- Authentication method (OAuth, API key, basic auth)
- Rate limits and quotas
- SDK availability (npm, Python, etc.)

### Priority 2: MCP Server

Search for existing MCP servers. Use PulseMCP (`list_servers` tool if available) or WebSearch for `{service_name} MCP server site:pulsemcp.com OR site:github.com`. If found, record:
- Package name (npm or GitHub)
- GitHub stars count
- Last commit date
- Publisher (individual or organization)
- Available tools/capabilities

### Priority 3: Playwright Browser Automation

If no API or MCP server exists, WebSearch for `{service_name} login portal` or `{service_name} web dashboard`. Note:
- Whether the portal uses standard web forms (automatable)
- Whether 2FA/CAPTCHA is required (complicates automation)
- Playwright MCP (microsoft/playwright-mcp) is the automation tool -- HIGH trust, Microsoft-maintained

### Priority 4: Email Scraping

Check if the service sends notification emails (invoices, confirmations, reports) that can be parsed:
- Google Workspace MCP (taylorwilsdon/google_workspace_mcp) provides Gmail access
- Structured data in emails (HTML tables, PDF attachments) can be extracted
- Only viable if the service reliably sends the data the agent needs via email

### Priority 5: Webhook Interception

WebSearch for `{service_name} webhook API` or `{service_name} event notifications`. Note:
- Available event types
- Payload format
- Authentication for webhook endpoints
- Whether the service supports outbound webhooks to custom URLs

### Priority 6: Manual Notification (Last Resort)

If no automated method exists, the fallback is a Telegram notification asking the user to perform the action manually and confirm completion. This is acceptable for low-frequency actions but not for daily automated workflows.

### Search Rules

- **Stop after finding 3 viable options per service** (D-01). Do not exhaustively search all 6 methods if you already have 3 good options.
- **Always verify with live search.** Never recommend an integration from memory alone. WebSearch and WebFetch confirm current availability.
- **Record everything.** Each search result feeds into Steps 3-5. If a search returns nothing, document that too ("No MCP server found for {service}").

The Arco Rooms reference implementation ([examples/arco-rooms.md](../examples/arco-rooms.md)) demonstrates this full fallback chain pattern across 6 utility providers with different integration methods per provider.

## Step 3: Evidence Verification

Every integration claim from Step 2 must include verifiable evidence. This is not optional -- unverified claims erode trust and lead to broken deployments.

### Required Evidence Fields

| Field | Required | Source |
|-------|----------|--------|
| URL | Yes | WebSearch result or official docs link |
| Package version | If applicable | `npm view {package} version` or GitHub release page |
| Last commit date | For GitHub repos | GitHub repo page or `gh` CLI |
| Publisher | Yes | npm publisher, GitHub org, or company name |
| Trust score | Yes | Computed in Step 4 from evidence data |

### Evidence Verification Table

For each service, compile an evidence table before building the decision matrix:

```markdown
| Method | Package | Version | Last Commit | Publisher | Trust | Status |
|--------|---------|---------|-------------|-----------|-------|--------|
| Official API | N/A | v2.1 | N/A | {vendor} | HIGH | Verified |
| MCP Server | {package-name} | 0.3.x | 2026-03-15 | {org} | MEDIUM | Verified |
| Playwright | @playwright/mcp | latest | 2026-04-01 | Microsoft | HIGH | Verified |
| Gmail scraping | google_workspace_mcp | 1.2.0 | 2026-02-20 | taylorwilsdon | MEDIUM | Verified |
| Custom script | N/A | N/A | N/A | N/A | N/A | [UNVERIFIED] |
```

### UNVERIFIED Marking

If any required field cannot be found through live search, mark the integration as `[UNVERIFIED]` in the Status column. Present this warning to the user:

"This integration is marked [UNVERIFIED] because I could not confirm {missing field}. An [UNVERIFIED] integration can still be recommended if no better option exists, but you should acknowledge the risk before we proceed."

Never silently omit missing evidence. The absence of verification is itself a data point the user needs.

## Step 4: Trust Scoring

Apply the 3-tier trust scoring system to every integration option. This aligns with the MCP Server Discovery Protocol from CLAUDE.md and decision D-05.

### Trust Tier Definitions

**HIGH:** Official vendor-maintained (Anthropic, Microsoft, Google, Slack, Xero, Stripe, etc.), OR community project with >500 GitHub stars AND active maintenance (commit within 90 days).

**MEDIUM:** Community-maintained project with 100-500 GitHub stars, commit within 180 days, clear documentation (README with examples).

**LOW:** Project with <100 GitHub stars, OR >180 days since last commit, OR unclear/anonymous maintainer, OR no documentation. Low-trust dependencies get a warning and highlighted alternatives.

### Evaluation Criteria Table

| Criterion | HIGH (auto-pass) | MEDIUM | LOW (flag) |
|-----------|-------------------|--------|------------|
| Publisher | Official vendor (Anthropic, Microsoft, Google, Slack, Xero) | Known community contributor | Unknown or anonymous |
| GitHub stars | >500 | 100-500 | <100 |
| Last commit | Within 90 days | 91-180 days | >180 days |
| Documentation | Comprehensive README + usage examples | README present | Minimal or absent |
| Known CVEs | None | Historical (patched) | Active unpatched |
| Package registry | Published to npm/PyPI with versioning | GitHub release only | Source code only |

### Scoring Rule

**Trust level equals the minimum across all criteria.** If any single criterion evaluates as LOW, the overall trust is LOW regardless of other scores. A server with 1,000 stars but an active unpatched CVE is LOW trust.

### Security Check for Sensitive Data

For MCP servers that will handle PII, PHI, or financial data (as determined by the data classification from the interview phase), add a mandatory security check:

- WebSearch for `{package_name} CVE` or `{package_name} security vulnerability`
- Check AgentSeal scores if available (agentseal/awesome-mcp-security)
- Note whether the server has a SECURITY.md or security policy
- Flag servers without security documentation that handle sensitive data

Low-trust dependencies handling sensitive data receive an explicit warning: "This server handles {data_type} data but has a LOW trust score. Consider using an alternative or implementing additional safeguards."

## Step 5: Decision Matrix Construction

Build one decision matrix per service. Each matrix shows the recommended method, an alternative, and a fallback. This is the primary deliverable of the integration analysis.

### Decision Matrix Template

```markdown
### {Service Name} Integration Options

| # | Method | Package/Tool | Trust | Setup | Pros | Cons |
|---|--------|-------------|-------|-------|------|------|
| 1 | **{Recommended}** | `{package}` v{ver} | {HIGH/MEDIUM/LOW} | {Low/Medium/High} | {advantages} | {limitations} |
| 2 | {Alternative} | `{package}` ({stars} stars) | {tier} | {complexity} | {advantages} | {limitations} |
| 3 | {Fallback} | {tool} | {tier} | {complexity} | {advantages} | {limitations} |

**Evidence:**
- {Method 1}: [{url}] (verified {date})
- {Method 2}: [{github_url}] (last commit: {date}, {stars} stars)
- {Method 3}: [{url}] (verified {date})

**Recommendation:** Option 1 ({method}) provides {rationale}.
Fallback to Option 2 if {condition}. Option 3 reserved as last resort.

**Credential requirement:** {credential_type} with `{scope}` scope (per [references/credentials.md](credentials.md))
**Prompt injection risk:** {layer_assignment} (per [references/prompt-injection.md](prompt-injection.md))
```

### Matrix Construction Rules

1. **The recommended method** is the one with the highest trust score AND lowest setup complexity. When trust scores tie, prefer lower setup complexity. When both tie, prefer the method higher in the priority order (API > MCP > Playwright > email > webhook > manual).
2. **Every row** must include all 6 columns (Method, Package/Tool, Trust, Setup, Pros, Cons). No empty cells.
3. **Evidence links** below the table point to the verified sources from Step 3. Each link should be clickable.
4. **Credential requirement** cross-references [references/credentials.md](credentials.md) -- record the credential type per the decision tree (Step 6 details).
5. **Prompt injection risk** cross-references [references/prompt-injection.md](prompt-injection.md) -- record the layer assignment per the agent's blast radius (Step 6 details).

### Behavior by Technical Level

**Non-technical:** Before presenting each decision matrix, add a plain-language summary: "For {service}, the best way to connect is through {method}. This is {trust_explanation}. Setup is {complexity_explanation}." Then show the table for reference.

**Technical-basics:** Present the table with a one-sentence recommendation below it.

**Developer:** Present the table, evidence links, and credential/injection details. Include package install commands if applicable.

## Step 6: Security Cross-Reference

Two security dimensions must be evaluated for every integration: credential requirements and prompt injection risk.

### 6A: Credential Evaluation (D-13)

For each integration's recommended method, run through the credential decision tree from [references/credentials.md](credentials.md):

**Step 1:** Does the service offer OAuth 2.0? Use OAuth with minimum scopes.
**Step 2:** Does the service offer scoped API keys? Use the most restrictive scope.
**Step 3:** Service only offers admin/full-access tokens? Flag as high risk, set `requires_approval: true`.

Record per integration:

| Field | Value |
|-------|-------|
| Credential type | OAuth 2.0 / Scoped API key / Admin token |
| Required scope | {minimum scope needed} |
| Rotation policy | {days, from credentials.md rotation table} |
| Env variable name | `AGENTBLOC_{SERVICE}_{TYPE}` |

The rotation policy depends on both the credential type and the data classification from the interview phase. Refer to the rotation frequency table in [references/credentials.md](credentials.md).

### 6B: Prompt Injection Assessment (D-14)

For each agent, determine if it ingests external content through its integrations. External content includes: emails, web pages (via Playwright), API responses containing user-generated text, and documents from shared drives.

Apply the decision tree from [references/prompt-injection.md](prompt-injection.md):

1. **Does this agent ingest content from outside the AgentBloc deployment?**
   - NO: No injection defense needed. Skip.
   - YES: Continue to step 2.

2. **What is the agent's blast-radius level?** (from the design phase contract card)
   - **Level 1-2 (read-only, write-scoped):** Assign Layers 1, 2, 3
   - **Level 3-4 (write-unrestricted, send-external):** Assign all 4 layers + separate validation LLM call

3. Update the **Prompt Injection Defense** line in each agent's contract card with the specific layer assignment and the data sources that trigger it.

Example: "Layers 1, 2, 3 (ingests emails via Gmail MCP and web pages via Playwright)"

### Security Summary Table

After evaluating all integrations, present a consolidated security view:

```markdown
| Agent | Service | Credential Type | Scope | Injection Risk | Defense Layers |
|-------|---------|----------------|-------|----------------|----------------|
| [name] | [service] | [type] | [scope] | [Yes/No] | [layers or "None"] |
```

## Step 7: Integration Presentation and Approval

Present all findings to the user in a structured format. This is the final step before the Integration Gate.

### Presentation Order

1. **Service-by-service decision matrices** (from Step 5), one per service
2. **Security summary table** (from Step 6)
3. **Integration-enhanced agent summary table** showing how the design has been enriched

### Integration-Enhanced Agent Summary Table

```markdown
| # | Agent | Services | Recommended Methods | Trust Profile | Injection Defense |
|---|-------|----------|--------------------|--------------|--------------------|
| 1 | [name] | [service list] | [method per service] | [HIGH/MEDIUM/LOW per service] | [layers or "None"] |
```

### Approval Request

After presenting all materials, ask:

"Review the integration analysis above. For each service, I've recommended the best option based on live research and trust scoring. You can:
- **Approve all** to proceed to the confirmation phase
- **Change any selection** -- tell me which service and I'll adjust
- **Request more research** on a specific service if the options aren't satisfactory

Which would you prefer?"

Wait for explicit approval. The user must confirm before the Integration Gate is marked as approved. Any modification request loops back to the relevant service analysis. Do not batch-approve without the user's explicit confirmation.

## Integration Gate

The Phase 3 gate artifact is the set of **integration-enhanced agent contract cards**. Each contract card from the design phase now includes:

1. **Selected Integrations section** -- chosen method, trust score, and setup complexity per service
2. **Credential Summary** -- credential type, scope, rotation policy, and env variable per service
3. **Updated Prompt Injection Defense** -- refined layer assignment based on actual integration paths

The agent summary table is also updated with integration data (recommended methods and trust profiles).

### Gate Format

Update the state bar to:

**Phase 3: Deep Integration Analysis | Gate: approved | Level: {level}**

Only after the user explicitly confirms the integration findings. Store the complete integration-enhanced contract cards as the gate artifact for Phase 4 consumption.

### Transition to Phase 4

When transitioning to Phase 4 (Step-by-Step Confirmation + Dry Run), the confirmation protocol receives:
- The integration-enhanced agent summary table
- The integration-enhanced per-agent contract cards (with Selected Integrations, Credential Summary, and Prompt Injection Defense)
- All decision matrices for reference during per-agent confirmation

## Quick Reference

### Protocol Steps

| Step | What It Produces | Key Decision | Cross-References |
|------|-----------------|--------------|------------------|
| Service Inventory | Deduplicated service list grouped by agent | -- | Design phase contract cards |
| Multi-Method Search | Up to 3 options per service (API > MCP > Playwright > email > webhook > manual) | D-01 | [examples/arco-rooms.md](../examples/arco-rooms.md) |
| Evidence Verification | Verified URL, version, commit date, publisher per option | D-03, D-04 | WebSearch, WebFetch, npm, GitHub |
| Trust Scoring | HIGH/MEDIUM/LOW per option | D-05, D-06 | MCP Server Discovery Protocol (CLAUDE.md) |
| Decision Matrix | Recommended + alternative + fallback per service | D-02 | [references/credentials.md](credentials.md), [references/prompt-injection.md](prompt-injection.md) |
| Security Cross-Ref | Credential type + injection defense per agent | D-13, D-14 | [references/credentials.md](credentials.md), [references/prompt-injection.md](prompt-injection.md) |
| Presentation + Approval | User-confirmed integration selections | INTG-05 | -- |

### Trust Scoring Quick Reference

| Tier | Criteria | Action |
|------|----------|--------|
| HIGH | Official vendor OR >500 stars + commit <90 days | Recommend confidently |
| MEDIUM | Community, 100-500 stars, commit <180 days, documented | Recommend with note |
| LOW | <100 stars OR >180 days stale OR no docs OR unpatched CVE | Warn, highlight alternatives |

**Scoring rule:** Trust = minimum across all criteria. Any single LOW criterion makes overall trust LOW.

### Search Priority Order

```
1. Official API    -- Direct, reliable, documented
2. MCP Server      -- Native Claude Code integration
3. Playwright      -- Browser automation for portals without APIs
4. Email scraping  -- Gmail MCP for services that send email notifications
5. Webhook         -- Event-driven for services with outbound hooks
6. Manual          -- Telegram notification as last resort
```

### Evidence Requirements

Every integration claim must include: URL, package version (if applicable), last commit date (for repos), publisher. Missing any required field triggers `[UNVERIFIED]` status.

### Credential Priority (from references/credentials.md)

```
OAuth 2.0 (preferred) > Scoped API key > Admin token (last resort, flag as high risk)
```

Env variable naming: `AGENTBLOC_{SERVICE}_{CREDENTIAL_TYPE}`
