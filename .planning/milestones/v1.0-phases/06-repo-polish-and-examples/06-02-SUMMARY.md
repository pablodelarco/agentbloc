---
phase: 06-repo-polish-and-examples
plan: 02
subsystem: examples
tags: [examples, walkthroughs, documentation]
dependency_graph:
  requires: []
  provides: [example-walkthroughs, arco-rooms-walkthrough, ecommerce-walkthrough, freelance-walkthrough]
  affects: [README.md]
tech_stack:
  added: []
  patterns: [D-05-walkthrough-structure, pipeline-topology, hierarchy-topology, 9-category-interview, blast-radius-scoring]
key_files:
  created:
    - examples/ecommerce-support.md
    - examples/freelance-pipeline.md
  modified:
    - examples/arco-rooms.md
decisions:
  - "Three examples cover two topology types (pipeline, hierarchy) and three technical levels (non-technical, technical-basics, developer)"
  - "Examples use short YAML excerpts (team.yaml only) per D-06 constraint"
  - "All integration references use real MCP server names with trust scores from phase-3-integration.md"
metrics:
  duration: 239s
  completed: "2026-04-14T15:13:54Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 6 Plan 02: Example Walkthroughs Summary

Three complete 6-phase example walkthroughs demonstrating AgentBloc across property management (pipeline, non-technical), e-commerce support (hierarchy, technical-basics), and freelance pipeline management (pipeline, developer) with realistic business scenarios, accurate protocol references, and consistent D-05 structure.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Expand arco-rooms.md and create ecommerce-support.md | e5cefb8 | examples/arco-rooms.md, examples/ecommerce-support.md |
| 2 | Create freelance-pipeline.md | b69cc57 | examples/freelance-pipeline.md |

## What Was Built

### examples/arco-rooms.md (200 lines)

Full rewrite from a 50-line pattern reference to a complete 6-phase walkthrough. Pipeline topology with 3 agents (Invoice Collector, Payment Matcher, Report Sender). Demonstrates multi-provider integration (Playwright, Gmail scraping, APIs), PSD2 banking via bank-mcp, and Telegram reporting. Non-technical persona. GDPR activated for EU tenant data.

### examples/ecommerce-support.md (227 lines)

New walkthrough demonstrating hierarchy topology. A Shopify-based e-commerce store with 4 agents: Support Coordinator (L1 read-only router), Order Tracker (L2), Refund Processor (L3 with approval gate), Escalation Handler (L4). Integrates Shopify MCP, Stripe MCP, Slack MCP Plugin, Google Workspace MCP. Technical-basics persona. Shows event-driven trigger model (polled every 5 minutes) versus cron.

### examples/freelance-pipeline.md (222 lines)

New walkthrough demonstrating a business lifecycle pipeline (distinct from operational pipeline). Solo developer freelancer with 4 agents: Lead Capture, Proposal Generator (Opus for scope reasoning), Invoice Manager (L3 Xero writes with approval), Follow-Up Agent (L4 client emails with approval). Integrates Xero MCP (official), Google Workspace MCP, Telegram MCP. Developer persona with technical language throughout.

## Verification Results

- All 3 files exist and are within 150-250 line range (200, 227, 222)
- All 3 follow D-05 7-section structure (Business Context, Interview Summary, Agent Team Design, Integration Findings, Confirmed Agent Cards, Deployment Artifacts, Evolution Notes)
- Arco Rooms: pipeline topology, 3 agents, non-technical
- E-Commerce: hierarchy topology, 4 agents, technical-basics
- Freelance: pipeline topology, 4 agents, developer
- Interview summaries cover all 9 categories from phase-1-interview.md
- Blast-radius scores use 1-4 scale from blast-radius.md
- Trust scores use HIGH/MEDIUM/LOW system from phase-3-integration.md
- No full YAML dumps (short team.yaml excerpts only, per D-06)
- No real credentials or API keys (placeholder descriptions only)
- Threat T-06-04 mitigated: all YAML excerpts use descriptive values, no real credentials
- Threat T-06-05 accepted: examples reference real MCP server names illustratively

## Deviations from Plan

None. Plan executed exactly as written.

## Decisions Made

1. **Arco Rooms full rewrite over incremental expansion.** The existing 50-line file was a pattern reference, not a walkthrough. A full rewrite was cleaner than attempting to restructure the existing content. The 11 patterns are now demonstrated implicitly through the walkthrough narrative rather than listed explicitly.

2. **E-commerce uses event-driven polling, not cron.** The hierarchy topology with a coordinator routing tickets naturally fits an event-driven model (poll every 5 minutes) rather than a daily cron batch. This shows AgentBloc supports both scheduling models.

3. **Freelance example uses Opus for Proposal Generator.** Proposal customization involves reasoning about project scope, template selection, and pricing, making it the natural Opus assignment. This contrasts with Arco Rooms (Opus for Payment Matcher) and E-Commerce (Opus for Refund Processor), showing Opus goes to the reasoning-heavy agent in each team.

## Self-Check: PASSED

- All 4 files exist (3 examples + SUMMARY)
- Both commits found (e5cefb8, b69cc57)
