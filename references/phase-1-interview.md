# Deep Interview Protocol

> Loaded unconditionally at Phase 1 entry. Guides Claude through a structured 9-category deep interview to fully understand the user's business workflow before designing an agent team.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Interview Opening Protocol](#interview-opening-protocol)
- [Progressive Data Classification Protocol](#progressive-data-classification-protocol)
- [Category 1: The Problem](#category-1-the-problem)
- [Category 2: The Current Workflow](#category-2-the-current-workflow)
- [Category 3: The Services and Tools](#category-3-the-services-and-tools)
- [Category 4: The Data](#category-4-the-data)
- [Category 5: Data Classification](#category-5-data-classification)
- [Category 6: The People](#category-6-the-people)
- [Category 7: Edge Cases and Failures](#category-7-edge-cases-and-failures)
- [Category 8: Reporting and Communication](#category-8-reporting-and-communication)
- [Category 9: Budget and Constraints](#category-9-budget-and-constraints)
- [Interview Completion Gate](#interview-completion-gate)
- [Summary of Understanding Template](#summary-of-understanding-template)
- [Quick Reference](#quick-reference)

## When This Applies

This file is loaded at Phase 1 entry, unconditionally alongside [references/data-classification.md](data-classification.md). Every AgentBloc session begins here. No questions are asked until both files are fully read.

## Interview Opening Protocol

### Soft Framing (D-04)

At the very start of the interview, after determining language and technical level, say:

> "I'll ask about 15 to 25 questions across 9 areas to fully understand your workflow. Let's start."

This is the only progress indication given. Do not provide running counts or category tracking during the interview. Let the conversation flow naturally.

### Technical Level Detection

Refer to the Technical Level Assessment section in SKILL.md. Determine the user's level from their first message. If ambiguous, ask the technical comfort question before proceeding.

### One Question Per Turn (D-03)

**Ask strictly ONE question per turn. No bundling. No exceptions.**

Ask one question, wait for the answer, then decide the next question based on what was revealed.

## Progressive Data Classification Protocol (D-08)

Throughout every category below, apply the auto-detection rules from [references/data-classification.md](data-classification.md) to every user answer. When any data signal is detected (a name = PII, a payment = financial, a diagnosis = PHI), immediately classify it and add to a running security tally.

**This tally is internal. Do not announce each classification to the user.**

### Running Tally Format

Maintain an internal markdown table (never shown) that accumulates throughout the interview:

| Data Class | Signal Detected | Category Where Detected |
|------------|----------------|------------------------|
| PII | "guest names and emails" | The Data |
| Financial | "credit card for deposits" | The Services and Tools |

This tally feeds the Security Profile in the Summary of Understanding.

### Cross-Reference

Consult [references/data-classification.md](data-classification.md) for keyword lists, confidence thresholds, and activation logic. When a regime activates (GDPR, HIPAA, PCI), note it in the tally but continue the interview without interruption.

## Category 1: The Problem

### Seed Questions

1. "What's the business problem you want to solve? Describe the pain point in your own words."
2. "What happens today when this problem isn't handled? What's the cost of the current situation?"
3. "How will you know the solution is working? What does success look like?"

### Must-Know Checklist

- [ ] Core pain point identified
- [ ] Current cost or impact quantified (time, money, errors, or missed opportunities)
- [ ] Desired outcome articulated
- [ ] Success criteria defined (measurable if possible)

### Adaptive Branching

- If user mentions lost revenue or missed deadlines, probe for frequency and magnitude: "How often does this happen, and what's the typical cost each time?"
- If user describes multiple problems, prioritize: "Which of these causes the most pain right now? Let's start there."
- If user jumps to a solution ("I need a bot that..."), redirect to the problem: "Before we design the solution, help me understand the problem. What triggers this need?"

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 2: The Current Workflow

### Seed Questions

1. "Walk me through the current process step by step. What triggers it, and what's the end result?"
2. "Which steps are manual and repetitive? Where do you spend the most time?"
3. "How often does this workflow run? Daily, weekly, on-demand?"

### Must-Know Checklist

- [ ] End-to-end process mapped with trigger and output
- [ ] Manual and repetitive steps identified
- [ ] Frequency and volume known (how often, how many items per run)
- [ ] Time spent per cycle estimated

### Adaptive Branching

- If the workflow has more than 5 steps, ask for a breakdown of each: "Let's go through each step one at a time. What's the first thing that happens?"
- If user mentions handoffs between people, probe for delays: "When you hand this off to [person], how long does it typically take them to act on it?"
- If user mentions exceptions or "sometimes" scenarios, flag for Category 7: "We'll come back to those exceptions later. For now, describe the normal happy path."

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 3: The Services and Tools

### Seed Questions

1. "What software, platforms, or tools are involved in this workflow?"
2. "For each tool, do you have admin access or API access, or do you just use the web interface?"

### Must-Know Checklist

- [ ] All software and platforms listed
- [ ] Access level known per tool (admin, API, web-only)
- [ ] Integration capability assessed (API available, MCP server exists, browser automation needed)

### Adaptive Branching

- If user mentions a tool you don't recognize, ask: "Can you share the URL or full name of that tool? I'll research its integration options."
- If user only has web interface access, note Playwright as the likely integration path and probe: "Is there a paid plan that includes API access, or is the web interface the only option?"
- If user mentions spreadsheets as a central tool, probe for structure: "Is there a single master spreadsheet, or multiple files? Who else edits it?"

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 4: The Data

### Seed Questions

1. "What data flows through this process? Where does it come from and where does it end up?"
2. "What format is the data in? Spreadsheets, emails, database records, PDFs?"

### Must-Know Checklist

- [ ] Data types and formats identified
- [ ] Data sources and destinations mapped
- [ ] Volume and frequency known (records per day/week, file sizes)

### Adaptive Branching

- If data comes from email, probe for structure: "Are these structured emails (like order confirmations) or freeform messages you have to interpret?"
- If user mentions multiple data formats, probe for transformation needs: "Do you currently convert between formats manually? For example, copying from email into a spreadsheet?"
- If volumes seem high (hundreds or thousands of records), note for state management design: "At that volume, we'll need checkpoint tracking so the agents never process the same record twice."

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 5: Data Classification

### Seed Questions

1. "Does your workflow handle personal information like names, emails, phone numbers, or ID numbers?"
2. "Are there any payments, invoices, or financial records involved?"

### Must-Know Checklist

- [ ] PII presence confirmed or ruled out
- [ ] Financial data presence confirmed or ruled out
- [ ] PHI presence confirmed or ruled out
- [ ] Data residency and jurisdiction noted (EU, US, other)

### Adaptive Branching

- If user confirms PII, probe for scope: "How many individuals' data does this workflow process? Tens, hundreds, thousands?"
- If user mentions health or medical context, probe explicitly: "Does this workflow touch patient records, diagnoses, or any health-related data?"
- If user operates in the EU or mentions European customers, note GDPR activation as mandatory (do not ask, just activate per the rules in data-classification.md).

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 6: The People

### Seed Questions

1. "Who else is involved in this workflow? Who provides input, who approves things, who receives the output?"
2. "Who should be notified when something goes wrong or needs manual attention?"

### Must-Know Checklist

- [ ] All roles identified (input providers, approvers, recipients)
- [ ] Approval chains mapped (who signs off on what)
- [ ] Notification preferences captured (channel, urgency level)

### Adaptive Branching

- If user mentions an approval step, probe for SLA: "When someone needs to approve, what's the typical turnaround time? What happens if they don't respond?"
- If multiple people share a role, probe for routing: "How do you decide which team member handles a given item? Round-robin, expertise, availability?"
- If user is a solo operator, confirm: "So you're the only person involved? No one else needs to approve or review anything?"

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 7: Edge Cases and Failures

### Seed Questions

1. "What goes wrong most often? What are the common exceptions or edge cases?"
2. "When something fails, what do you do today? Is there a fallback process?"

### Must-Know Checklist

- [ ] Top 3 failure modes identified
- [ ] Current fallback process documented
- [ ] Acceptable failure rate discussed (zero tolerance vs. occasional misses ok)

### Adaptive Branching

- If user says "nothing goes wrong," push back gently: "Every workflow has edge cases. What happens when data is missing, a tool is down, or someone doesn't respond on time?"
- If user describes catastrophic failures, probe for prevention: "Has this happened before? What was the impact, and what would have prevented it?"
- If failure modes involve data corruption or loss, flag for Design phase blast-radius scoring.

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 8: Reporting and Communication

### Seed Questions

1. "What reports or summaries does this workflow need to produce? For whom?"
2. "How do you prefer to receive updates: email, messaging app, spreadsheet, dashboard?"

### Must-Know Checklist

- [ ] Report types and recipients defined
- [ ] Delivery channel chosen (Telegram, Slack, email, spreadsheet)
- [ ] Frequency determined (real-time, daily digest, weekly summary)

### Adaptive Branching

- If user wants real-time notifications, probe for noise tolerance: "Do you want to know about every item processed, or only exceptions and errors?"
- If user mentions multiple stakeholders with different needs, note separate report streams: "It sounds like [person A] needs a summary and [person B] needs the raw data. We'll design separate notification streams."
- If user has no preference, suggest Telegram as the default: "Most of our deployments use Telegram for notifications because it's mobile-first and supports threading. Would that work for you?"

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Category 9: Budget and Constraints

### Seed Questions

1. "Are there budget constraints for the tools and services involved?"
2. "Are there any technical constraints, compliance requirements, or deadlines I should know about?"

### Must-Know Checklist

- [ ] Budget range noted (or "no constraint" confirmed)
- [ ] Timeline requirements captured (go-live date, phased rollout preference)
- [ ] Technical constraints logged (hosting limitations, network restrictions, existing infrastructure)
- [ ] Compliance constraints logged (industry regulations, internal policies)

### Adaptive Branching

- If user mentions a tight deadline, probe for MVP scope: "Given the timeline, which parts of the workflow are highest priority to automate first?"
- If budget is limited, note free-tier options: "Several integrations have free tiers that cover small volumes. I'll prioritize those in the design."
- If user mentions existing compliance requirements (SOC 2, ISO 27001), note for governance.yaml generation.

**Data Classification Scan:** Apply auto-detection rules from references/data-classification.md to every answer in this category.

## Interview Completion Gate (INTV-03)

Before generating the Summary of Understanding, verify ALL must-know items across all 9 categories:

### Master Completion Checklist

**The Problem:** core pain point, current cost, desired outcome, success criteria
**The Current Workflow:** end-to-end map, manual steps, frequency, time per cycle
**The Services and Tools:** all platforms listed, access levels, integration capability
**The Data:** data types/formats, sources/destinations, volume
**Data Classification:** PII status, financial status, PHI status, jurisdiction
**The People:** roles, approval chains, notification preferences
**Edge Cases and Failures:** top 3 failures, fallback process, acceptable failure rate
**Reporting and Communication:** report types, delivery channel, frequency
**Budget and Constraints:** budget, timeline, technical constraints, compliance constraints

**If any must-know item has a gap, ask targeted follow-up questions before proceeding.** Do not generate the summary until every checkbox above can be checked.

## Summary of Understanding Template (INTV-04, D-10)

After the completion gate is satisfied, present this structured summary for user confirmation:
### Your Business
[One paragraph: business context, industry, and scale.]

### The Problem
[Core pain point, its cost, and what success looks like.]

### Current Workflow
[Step-by-step from trigger to output. Highlight manual and repetitive steps.]

### Services and Integrations
| Service | Access Level | Integration Path |
|---------|-------------|-----------------|
| [Tool name] | [admin/API/web-only] | [API/MCP/Playwright/email] |

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

### Security Profile (D-10)
| Data Class | Signals Found | Confidence |
|------------|--------------|------------|
| [PII/PHI/Financial/Public] | [specific signals] | [HIGH/MEDIUM] |

**Compliance regimes activated:** [GDPR, HIPAA, PCI, or None]

**Implications for design:** [How compliance affects agent permissions, data handling, audit logging, retention, and which patterns will be applied in the Design phase]

**Does this accurately capture your workflow? I need your confirmation before proceeding to the design phase.**

## Quick Reference

| Category | Seed Questions | Must-Know Items |
|----------|---------------|----------------|
| 1. The Problem | 3 | 4 |
| 2. The Current Workflow | 3 | 4 |
| 3. The Services and Tools | 2 | 3 |
| 4. The Data | 2 | 3 |
| 5. Data Classification | 2 | 4 |
| 6. The People | 2 | 3 |
| 7. Edge Cases and Failures | 2 | 3 |
| 8. Reporting and Communication | 2 | 3 |
| 9. Budget and Constraints | 2 | 4 |
| **Total** | **20** | **31** |

With adaptive branching, expect 15 to 25 total questions depending on workflow complexity.
