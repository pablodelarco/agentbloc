# Deep Interview Protocol (Strawman-First)

> Loaded unconditionally at Phase 1 entry. Phase 1 produces a confirmed Business Graph through a strawman-first pattern: state intent up front, pull a small set of must-haves, sketch a strawman agent team early, then iterate by user reaction.
>
> Updated 2026-05-09 from the original 9-category interrogation pattern. The 9 categories survive as a coverage checklist (and as a targeted-follow-up reference), not as a sequential question script.

## Table of Contents

- [When This Applies](#when-this-applies)
- [The Strawman-First Pattern](#the-strawman-first-pattern)
- [Step 1: Frame the Conversation](#step-1-frame-the-conversation)
- [Step 2: Pull the Minimum Must-Haves](#step-2-pull-the-minimum-must-haves)
- [Step 3: Sketch the Strawman](#step-3-sketch-the-strawman)
- [Step 4: Iterate by Reaction](#step-4-iterate-by-reaction)
- [Step 5: Coverage Check and Summary of Understanding](#step-5-coverage-check-and-summary-of-understanding)
- [Coverage Checklist](#coverage-checklist)
- [Progressive Data Classification](#progressive-data-classification)
- [Targeted Follow-up Reference](#targeted-follow-up-reference)
- [Summary of Understanding Template](#summary-of-understanding-template)
- [Business Graph Emission](#business-graph-emission)
- [Quick Reference](#quick-reference)

## When This Applies

Phase 1 begins when a user invokes AgentBloc. Every session opens here. This file is loaded unconditionally alongside [references/data-classification.md](data-classification.md) and [references/business-graph-schema.md](business-graph-schema.md) before any conversation begins.

The output of Phase 1 is a validated Business Graph at `.agentbloc/graph/business-graph.json` plus user-confirmed Summary of Understanding tables. The path to that output is the 5-step Strawman-First Pattern below.

## The Strawman-First Pattern

Senior consultants do not run 25 cold questions. They show a sketch and refine by reaction. Phase 1 mirrors that:

1. **Frame**: state intent up front (what AgentBloc is going to do)
2. **Pull**: ask only the minimum-viable must-haves (3-5 questions)
3. **Sketch**: render a strawman agent team early
4. **Iterate**: refine by user reaction (push back, add, drop, change)
5. **Cover**: run the Coverage Checklist; ask targeted follow-ups for gaps; render the Summary of Understanding; emit the Business Graph

Do NOT walk users through 9 categories of cold questions in order. That pattern is deprecated. The 9 must-know categories now serve as a coverage checklist, not a script.

## Step 1: Frame the Conversation

After determining language and technical level (per SKILL.md Technical Level Assessment), open with an intent statement, not a soft count of questions.

EN: "I'll learn what you do, sketch the agent team I'd build for you, and refine it together. A few quick questions to get started, then I'll show you a draft team."

ES: "Voy a entender lo que haces, esbozar el equipo de agentes que diseñaría para ti, y lo refinamos juntos. Unas preguntas rápidas para empezar, y luego te muestro un equipo borrador."

This sets expectations: we are CO-DESIGNING, not surveying.

## Step 2: Pull the Minimum Must-Haves

Three questions, one at a time, in this order:

1. **The workflow**: "What workflow do you want to automate? Describe what you do by hand today."
2. **The cadence and scale**: "How often does this run, and how much volume per cycle?"
3. **The distinguishing constraint**: "What's the one thing that makes this hard? Your style, the data sensitivity, the volume, integrations no one else has, regulatory constraints?"

Adapt: if the user volunteers all three in their first message, skip ahead. If a critical concrete detail surfaces during step 2 that demands clarification, pull it inline rather than deferring.

After these three answers, you have enough context to sketch a strawman.

## Step 3: Sketch the Strawman

Render a 3-7 agent team table. Each row carries:

- Agent name (kebab-case id + human-readable role)
- Trigger (cron expression / event / inter-agent)
- One-sentence "what it does"
- Autonomy (full / semi / supervised)
- Blast radius (L1 read-only / L2 write-internal / L3 write-external / L4 send-external)

Pair the table with:

- A cadence diagram or one-line schedule (e.g., "Sun scout → Mon-Wed pick + research + draft → Thu images → Fri publish")
- The user's expected weekly time budget (e.g., "~30-60 min across 3 touches")
- The runtime hand-off note ("This emits a portable spec; Paperclip is the canonical runtime example; any AI coding agent can build it")

End with: "What's wrong with this picture? Push back, add agents, change cadence, anything."

The strawman is intentionally provisional. Its job is to surface what the cold-question script was trying to extract.

## Step 4: Iterate by Reaction

Reactions reveal information the cold script tried to chase. As the user pushes back, log signals into the running Business Graph draft:

- New tools they mention → `tools_available`
- Edge cases they describe → `decision_patterns`
- People they name → People Involved
- Data sensitivity they reveal → run Progressive Data Classification (see below)
- Compliance regime triggers → activate the corresponding patterns silently
- Budget or timeline mentions → Budget and Constraints
- Failure modes they cite → Edge Cases

Apply Progressive Data Classification on EVERY user response throughout Phase 1.

Stop iterating when the user has stopped pushing back substantively (one full turn with "yes" / "good to go" / "looks right" or equivalent).

## Step 5: Coverage Check and Summary of Understanding

When the strawman is stable, walk the Coverage Checklist below. For each unsatisfied must-know, ask ONE targeted follow-up question (use the Targeted Follow-up Reference if you need a seed). Do not march through the checklist mechanically; only ask what's actually missing.

Once all REQUIRED must-knows are satisfied, render the Summary of Understanding. The user confirms the tables, then emit the Business Graph silently.

## Coverage Checklist

These are the must-knows the strawman + iteration must collectively satisfy before Phase 2 entry. They are NOT a question script.

| # | Category | Must-Know |
|---|---|---|
| 1 | The Problem | Core pain, current cost, desired outcome, success criteria |
| 2 | Current Workflow | End-to-end map, manual steps, frequency, time per cycle |
| 3 | Services and Tools | Software listed, access levels, integration capability |
| 4 | The Data | Types/formats, sources/destinations, volume |
| 5 | Data Classification | PII / PHI / Financial status, jurisdiction |
| 6 | The People | Roles, approval chains, notification preferences |
| 7 | Edge Cases and Failures | Top 3 failures, fallback, decision rules |
| 8 | Reporting and Communication | Report types, recipients, channel, frequency |
| 9 | Budget and Constraints | Budget, timeline, technical + compliance constraints |

REQUIRED tier (per [references/business-graph-schema.md](business-graph-schema.md) Field Obligation Matrix):

- `business.type`, every `process.name + steps + pain`, every `process.trigger.type` with sub-field, length >= 1 process

RECOMMENDED tier: every other field above. Emit Business Graph with warnings on RECOMMENDED gaps; the rendered Summary of Understanding flags them so the user can fill in or accept.

## Progressive Data Classification

Throughout every step above, apply the auto-detection rules from [references/data-classification.md](data-classification.md) to every user response. When any data signal is detected (a name = PII, a payment = financial, a diagnosis = PHI), immediately classify it and add to a running internal tally.

**This tally is internal. Do not announce each classification to the user.**

Running tally format (never shown):

| Data Class | Signal Detected | Surfaced In |
|------------|-----------------|-------------|
| PII | "guest names and emails" | strawman iteration |
| Financial | "credit card for deposits" | follow-up on tools |

When a regime activates (GDPR, HIPAA, PCI), note it in the tally and continue. The Security Profile in the Summary of Understanding renders the result. See data-classification.md for keyword lists, confidence thresholds, and activation logic.

## Targeted Follow-up Reference

When a coverage gap surfaces, use these per-category seed questions and adaptive branches as a reference for the targeted follow-up. They are NOT a question script. Pull only the seed that addresses the actual gap.

### Category 1: The Problem

Seeds: "What's the cost of the current situation?" / "What does success look like?"

Branches: if user mentions lost revenue, probe frequency and magnitude. If user describes multiple problems, prioritize. If user jumps to a solution, redirect to the underlying problem.

### Category 2: Current Workflow

Seeds: "Walk me through the current process step by step." / "Which steps are manual and repetitive?" / "How often does this run?"

Branches: more than 5 steps, ask for per-step breakdown. Handoffs between people, probe delays. "Sometimes" exceptions, defer to Category 7.

### Category 3: Services and Tools

Seeds: "What software, platforms, or tools are involved?" / "For each tool, do you have admin access, API access, or just web interface?"

Branches: unfamiliar tool, ask for URL. Web-only access, note Playwright path. Spreadsheets central, probe structure.

### Category 4: The Data

Seeds: "What data flows through this process?" / "What format is the data in?"

Branches: email source, probe structure. Multiple formats, probe transformation needs. High volume, note checkpoint design.

### Category 5: Data Classification

Seeds: "Does your workflow handle personal information?" / "Are there payments, invoices, or financial records?"

Branches: PII confirmed, probe scope. Health context, probe explicitly. EU operation, GDPR activates without asking (per data-classification.md).

### Category 6: The People

Seeds: "Who else is involved? Who approves, who receives output?" / "Who should be notified when something goes wrong?"

Branches: approval step, probe SLA. Multiple people sharing a role, probe routing. Solo operator, confirm.

### Category 7: Edge Cases and Failures

Seeds: "What goes wrong most often?" / "When something fails, what do you do today?" / "What rules do you apply when deciding how to handle edge cases?"

Branches: "nothing goes wrong", push back gently. Catastrophic failures, probe prevention. Rule or threshold mentioned, capture verbatim for `decision_patterns`.

### Category 8: Reporting and Communication

Seeds: "What reports does this workflow need to produce, for whom?" / "How do you prefer to receive updates?"

Branches: real-time notifications, probe noise tolerance. Multiple stakeholders with different needs, design separate streams. No preference, suggest Telegram default.

### Category 9: Budget and Constraints

Seeds: "Are there budget constraints?" / "Any technical constraints, compliance requirements, or deadlines?"

Branches: tight deadline, probe MVP scope. Limited budget, prioritize free-tier integrations. Compliance mentioned, log for governance generation.

## Summary of Understanding Template

After the Coverage Check passes, present this structured summary for user confirmation. The JSON is NEVER shown; the rendered tables ARE the user-facing review.

### Your Business

[One paragraph: business context, industry, scale.]

### The Problem

[Core pain point, its cost, what success looks like.]

### Current Workflow

[Step-by-step from trigger to output. Highlight manual and repetitive steps.]

### Services and Integrations

| Service | Access Level | Integration Path |
|---------|-------------|-----------------|
| [Tool name] | [admin/API/web-only] | [API/MCP/Playwright/email] |

### Tools Available (Business Graph `tools_available`)

| Tool | Already in Use | Purpose |
|------|----------------|---------|
| [Tool name] | [yes / evaluating] | [what the user uses it for today] |

If no specific tools were named during iteration, ask one clarifying question before emitting: "Anything come to mind that you already use: a CRM, spreadsheet, calendar, accounting software?"

### Channels (Business Graph `channels`)

| Channel | Used For |
|---------|----------|
| [telegram / email / web / slack / sms / other] | [notifications / approvals / reports / other] |

### Decision Patterns (Business Graph `decision_patterns`)

| Rule | Source |
|------|--------|
| [Verbatim rule the user described, e.g., "If an invoice is overdue by more than 7 days, send a formal notice."] | [Where it surfaced during iteration] |

These feed the `decision_patterns` array in the Business Graph. Capture verbatim. Phase 9 Designer Agent uses natural-language understanding to classify them; do not pre-structure.

### Data Model

| Data Type | Format | Source | Destination | Volume |
|-----------|--------|--------|-------------|--------|
| [type] | [format] | [where from] | [where to] | [per cycle] |

### People Involved

| Role | Person/Team | Responsibility | Notification Channel |
|------|------------|---------------|---------------------|
| [role] | [who] | [what they do] | [how to reach them] |

### Edge Cases

| Failure Mode | Current Handling | Acceptable Rate |
|-------------|-----------------|----------------|
| [what goes wrong] | [what happens today] | [tolerance] |

### Reporting Requirements

| Report | Recipient | Channel | Frequency |
|--------|-----------|---------|-----------|
| [type] | [who] | [Telegram/Slack/email] | [when] |

### Budget and Constraints

- **Budget:** [range or "no constraint"]
- **Timeline:** [deadline or "flexible"]
- **Technical constraints:** [any limitations]
- **Compliance constraints:** [any requirements]

### Security Profile

| Data Class | Signals Found | Confidence |
|------------|--------------|------------|
| [PII / PHI / Financial / Public] | [specific signals] | [HIGH / MEDIUM] |

**Compliance regimes activated:** [GDPR, HIPAA, PCI, or None]

**Implications for design:** [How compliance affects agent permissions, data handling, audit logging, retention, and which patterns will be applied in the Design phase]

### Confirmation Question

**Does this accurately capture your workflow? I need your confirmation before proceeding to the design phase.**

## Business Graph Emission

Once the user confirms the rendered tables:

1. Apply the Validation Checklist from [references/business-graph-schema.md](business-graph-schema.md) in order (Check 1 through Check 6).
2. For any failed REQUIRED check (Checks 1-5), ask the targeted conversational follow-up specified in that check and wait for the user's answer before resuming.
3. Once all REQUIRED checks pass, write the validated JSON silently to `.agentbloc/graph/business-graph.json`. Create the `.agentbloc/graph/` directory if it does not exist.
4. Confirm emission in one sentence: "Business Graph saved. Ready to move to the design phase."
5. Set the Phase 1 `business_graph_validated` sub-gate to `approved` (see SKILL.md State Transitions).

If `.agentbloc/graph/business-graph.json` already exists, follow the Re-run Behavior in [references/business-graph-schema.md](business-graph-schema.md): ask keep / overwrite / merge (default merge).

## Quick Reference

| Step | What you do | Output |
|---|---|---|
| 1. Frame | State intent + soft framing of co-design | User knows the shape of Phase 1 |
| 2. Pull | 3 must-have questions (workflow / cadence / constraint) | Enough signal to draft strawman |
| 3. Sketch | Strawman agent team table + cadence + time budget + handoff note | User has something to react to |
| 4. Iterate | User pushes back; you log every signal into the running Business Graph | Strawman stabilizes; coverage gaps surface |
| 5. Cover | Coverage Checklist gap-fill via targeted follow-ups; Summary of Understanding; Business Graph emission | Phase 1 sub-gate approved |

Expected total questions: 5 to 12, not 25. The strawman does the work of 15 cold questions by giving the user something concrete to react to.
