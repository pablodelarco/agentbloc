# Pitfalls Research

**Domain:** Claude Code skill for AI agent team design and deployment
**Researched:** 2026-04-13
**Confidence:** HIGH (multi-source: Anthropic official docs, published failure data, production incident reports, peer-reviewed research)

**Scope note:** The enterprise-readiness audit already covers security governance, enforcement mechanisms, and product completeness gaps. This document focuses on pitfalls BEYOND those -- failure modes inherent to the medium (Claude Code skills), the domain (multi-agent deployment), the audience (non-technical users), and the business model (open-source portfolio for consulting).

---

## Critical Pitfalls

### Pitfall 1: Context Rot Kills Skill Compliance

**What goes wrong:**
AgentBloc's SKILL.md is 539 lines. Research from Chroma (2025, 18 frontier models tested) proves every LLM degrades as context grows -- some dropping from 95% to 60% accuracy. Separately, community testing shows Claude Code begins ignoring CLAUDE.md instructions at around 150 lines, and SKILL.md instructions compete for the same context window as conversation history, system prompt, and other skills. The longer a Phase 1 interview runs (potentially 15+ exchanges), the more AgentBloc's own instructions get pushed into Claude's blind spot. By the time a user reaches Phase 4 or 5, the hard gates and quality checklist from SKILL.md may be functionally invisible.

**Why it happens:**
Claude's context window is a shared resource. SKILL.md content is loaded as user-message-level text, not system-level instructions. As conversation grows, the model weights instructions proportionally less. The "lost-in-the-middle" effect means rules in the middle of a long skill file are the first to be ignored. AgentBloc compounds this because it is a multi-phase conversational flow -- by design, conversations get long.

**How to avoid:**
1. Cut SKILL.md to under 250 lines (already planned). The official Anthropic best-practice ceiling is 500 lines, but given AgentBloc's long-conversation nature, target 200-250.
2. Use progressive disclosure aggressively: each phase loads its own reference file on demand, then the context from earlier phases can be released.
3. Put the most critical rules (hard gates, phase ritual) at the TOP of SKILL.md. Claude attends best to the beginning and end of context.
4. Consider a "context refresh" pattern: at each phase gate, the skill instructs Claude to re-read the relevant reference file, reinforcing instructions that may have decayed.
5. Never nest references more than one level deep from SKILL.md (Anthropic's official recommendation).

**Warning signs:**
- Claude skips a hard gate without acknowledging it
- Phase 4/5 outputs lack security fields that were defined in Phase 2 design
- Claude stops using the `[PHASE: N | GATE: X]` ritual mid-conversation
- Quality checklist items are silently omitted from deployment artifacts

**Phase to address:**
Phase 1 (Skill Restructuring). This must be solved FIRST because every subsequent phase depends on Claude actually following instructions throughout a long conversation.

---

### Pitfall 2: Skill Activation Failure -- AgentBloc Never Gets Invoked

**What goes wrong:**
Real-world testing across 200+ prompts shows Claude Code skills with poor metadata activate as low as 20% of the time. Even optimized skills plateau around 72-90%. AgentBloc's current frontmatter has a description that is first-person ("Design and deploy AI agent teams for businesses") and uses triggers that may not match how a non-technical user actually phrases their request. If the skill does not activate, the user gets generic Claude behavior instead of the structured 6-phase flow, and may not even realize they missed the skill entirely.

**Why it happens:**
Claude uses only the `name` and `description` fields from YAML frontmatter to decide whether to activate a skill. If the description does not match the user's phrasing, Claude defaults to its own reasoning. Additionally, the current name "agentbloc" contains no semantic signal about what it does. Published research identifies two distinct failure modes: (a) activation failure (skill never invoked) and (b) execution failure (skill loaded but procedural steps skipped because they "delay the output").

**How to avoid:**
1. Rewrite the frontmatter description in third person (Anthropic's explicit requirement): "Guides users through a structured 6-phase process to design and deploy autonomous AI agent teams for business process automation. Activates when users ask about automating business workflows, creating AI agents, designing agent teams, or deploying autonomous processes. Also activates on /agentbloc, 'automatizar mi negocio', 'crear agentes'."
2. Keep the description under 1024 characters (the hard limit) but make it keyword-rich for both English and Spanish trigger phrases.
3. Test activation with at least 20 diverse prompts across Haiku, Sonnet, and Opus. Document the activation rate. Target >90%.
4. Consider a UserPromptSubmit hook as a fallback activation mechanism for critical trigger phrases.

**Warning signs:**
- Users report "Claude just answered normally, it didn't do the interview"
- Activation rate below 80% in testing
- Non-English prompts fail to trigger the skill
- Indirect prompts ("I want to automate my invoicing") miss activation

**Phase to address:**
Phase 1 (Skill Restructuring) for the metadata rewrite. Phase 4 (Testing) for systematic activation testing.

---

### Pitfall 3: Execution Drift -- Claude Loads the Skill But Skips Steps

**What goes wrong:**
Even when a skill activates, Claude selectively follows instructions. It prioritizes steps that produce visible output quickly and skips "procedural overhead" steps like the phase gate ritual, the quality checklist, blast-radius scoring, and integration evidence verification. This is not a bug -- it is how language models handle competing priorities (helpfulness vs. compliance). The result: AgentBloc appears to work (it produces agent designs) but silently drops the safety mechanisms that make those designs enterprise-ready.

**Why it happens:**
Claude is trained to be helpful. When it faces a choice between (a) following a procedural step that adds friction and (b) skipping to the answer the user seems to want, it often chooses (b). This is amplified when instructions are in the "middle" of a long context. The problem is worst for steps that have no visible output -- you cannot tell the blast-radius score was skipped because there is no error, just absence.

**How to avoid:**
1. Make every critical step produce VISIBLE output. The `[PHASE: N | GATE: X]` ritual works because it is a visible prefix. Apply the same pattern: force Claude to print the blast-radius score, print the evidence URL, print the data classification before proceeding.
2. Use checklists with checkbox syntax that Claude must copy into its response and check off (Anthropic recommends this pattern for complex workflows).
3. Design reference files with "low freedom" instructions (Anthropic's term) for critical safety steps -- exact scripts, not suggestions.
4. Implement feedback loops: after generating artifacts, a validation step reads them back and checks for required fields.
5. Acceptance criteria for each phase should be machine-verifiable where possible (e.g., a script that checks governance.yaml has all required fields).

**Warning signs:**
- Deployment artifacts missing security fields (kill_switch, audit, rate_limit)
- Integration claims without `Verified: <URL>` lines
- Phase transitions without explicit gate approval logged
- Quality checklist never appears in conversation output

**Phase to address:**
Phase 2 (Core Skill Development) for checklist patterns. Phase 3 (Security & Governance) for enforcement of security-specific steps.

---

### Pitfall 4: Generated Artifacts That Don't Actually Work

**What goes wrong:**
AgentBloc generates YAML configurations, skill markdown files, cron job definitions, and governance specs. These artifacts look correct to a non-technical user but fail silently when deployed. Common failures: invalid YAML syntax, references to MCP servers that don't exist or have different tool names, cron expressions with timezone bugs, state file schemas that don't match what the agent actually produces, and ClaudeClaw job definitions with instructions that Claude Code cannot actually execute.

**Why it happens:**
Vibe-coded projects share a universal pattern: "each failure had a test that would have caught it. None of those tests were run." (Autonoma, 2025-2026 incident analysis). LLMs generate plausible-looking configurations that pass human review but fail machine validation. YAML is particularly dangerous because a single indentation error can silently change semantics. AgentBloc compounds this because: (a) the artifact templates are only 33% complete (2 of 6 defined), (b) there is no validation step, and (c) the target audience cannot diagnose YAML errors.

**How to avoid:**
1. Complete all 6 artifact templates with exact schemas, not prose descriptions. Include JSON Schema or YAML Schema definitions for every artifact type.
2. Build a validation script (Python or bash) that checks every generated artifact against its schema before presenting to the user. This is the "plan-validate-execute" pattern Anthropic recommends.
3. Include a "smoke test" in the dry-run phase that attempts to parse every generated file and reports errors in plain language.
4. Pin MCP server tool names with fully qualified names (`ServerName:tool_name` format per Anthropic docs) in generated skill files.
5. For cron expressions, include a "next 5 runs" preview so the user can verify scheduling makes sense.

**Warning signs:**
- Generated YAML fails `yamllint` or `js-yaml` parsing
- MCP server names in artifacts don't match any published MCP server
- Cron expressions produce unexpected schedules across timezones
- ClaudeClaw job markdown references tools or commands that don't exist
- State schema in agent.yaml doesn't match the structure the agent actually writes

**Phase to address:**
Phase 2 (Core Skill Development) for template completion. Phase 4 (Testing) for validation scripts and end-to-end testing.

---

### Pitfall 5: The Integration Hallucination Problem

**What goes wrong:**
During Phase 3 (Integration Analysis), Claude confidently recommends MCP servers, npm packages, or APIs that either don't exist, have been deprecated, have different interfaces than described, or require capabilities the user doesn't have. The user trusts these recommendations because Claude presents them with authority and specific-sounding package names. At deployment time, nothing works. This is the single most common complaint about AI-assisted development tools.

**Why it happens:**
Claude's training data includes package names, API documentation, and integration patterns from 6-18 months ago. Packages get deprecated, APIs change, MCP servers get renamed or abandoned. Claude cannot distinguish between a package it "remembers" from training and one that currently exists. The current SKILL.md says "NEVER claim an integration exists without verifying it" but provides no mechanism for verification -- it's a prose gate that Claude can (and does) skip.

**How to avoid:**
1. The integration evidence protocol is already in the enterprise-readiness audit. Implement it strictly: every integration claim must include `Verified: <URL> | Package: <name>@<version> | Last commit: <date>` or be marked `[UNVERIFIED]`.
2. Add a "verification workflow" to Phase 3 reference file: Claude must use WebSearch or tool calls to check that packages exist before recommending them. Include a fallback chain: search npm registry -> search GitHub -> search PyPI -> mark unverified.
3. For MCP servers specifically, maintain a curated list of known-good MCP servers in a reference file that gets updated periodically, rather than relying on Claude's training data.
4. Teach the skill to present unverified integrations honestly: "I believe this exists but could not verify it. You should check before depending on it."
5. The dry-run phase should include an "integration smoke test" that attempts to resolve each claimed package/server.

**Warning signs:**
- Integration recommendations lack URLs or version numbers
- Claude recommends an MCP server with a name that follows a pattern (`mcp-server-[service]`) but doesn't actually exist
- Package names sound plausible but return 404 on npm/PyPI
- API endpoints described don't match the service's current documentation

**Phase to address:**
Phase 2 (Core Skill Development) for the evidence protocol. Phase 3 (Security & Governance) for the trust-score mechanism. Phase 4 (Testing) for integration smoke tests.

---

### Pitfall 6: Multi-Agent Coordination Failures in Generated Designs

**What goes wrong:**
AgentBloc designs multi-agent teams with pipeline, mesh, hierarchy, or swarm topologies. Research shows 40% of multi-agent pilots fail within six months, with 79% of failures from specification and coordination problems (not infrastructure). Specific failure modes: (a) infinite loops where agents with conflicting instructions bounce tasks endlessly, (b) hallucinated consensus where multiple agents converge on fabricated data, (c) resource deadlock from circular dependencies, and (d) the "17x error trap" where adding agents without proper coordination topology amplifies errors by 17x.

**Why it happens:**
AgentBloc's current design phase gives Claude freedom to choose topologies and define contracts, but provides no guardrails against coordination anti-patterns. There is no iteration limit for agent-to-agent handoffs, no deadlock detection mechanism, no circuit breaker pattern. The designs look clean on paper but fail under real conditions because LLM-based agents are non-deterministic -- they don't always produce the same output format, and "gate conditions" expressed in natural language are interpreted differently across runs.

**How to avoid:**
1. Add a "coordination safety" section to Phase 2 reference file with mandatory patterns: iteration limits on all agent handoffs (default: 3 retries then escalate), timeout thresholds per agent, explicit conflict resolution hierarchy.
2. Require every agent contract to define not just inputs/outputs but also failure modes and escalation paths.
3. For pipeline topologies (the default), require that each gate condition be machine-verifiable, not just prose. "Invoices found" is too vague; "state/invoices.json exists AND contains > 0 entries" is testable.
4. Include a "topology risk assessment" in the design phase: mesh and swarm topologies get flagged as HIGH coordination risk with mandatory additional safeguards.
5. Add circuit-breaker patterns to the agent.yaml template: max_iterations, timeout_seconds, circuit_breaker_threshold.

**Warning signs:**
- Agent designs with mesh or swarm topology but no coordination safeguards
- Gate conditions expressed as natural language without machine-verifiable criteria
- No iteration limits or timeout definitions in agent contracts
- Agents with overlapping responsibilities and no conflict resolution protocol
- No fallback defined for when an agent produces unexpected output format

**Phase to address:**
Phase 2 (Core Skill Development) for coordination safety patterns. Phase 4 (Testing) for simulation of multi-agent failure scenarios.

---

### Pitfall 7: Non-Technical Users Abandoned During Deployment

**What goes wrong:**
AgentBloc's primary audience is "SMB owners and ops teams (non-technical)." The skill guides them through interview and design (conversational, accessible) but then drops them into deployment (YAML files, cron expressions, MCP server setup, credential management, state schemas). This is the "cliff of technical complexity" -- the user was fine when talking, but cannot execute the deployment steps. They either give up, make dangerous configuration errors, or require the very consulting engagement that was supposed to be the upsell (but they haven't paid for it yet).

**Why it happens:**
The skill was designed by a developer for a developer workflow (ClaudeClaw pattern). The deployment artifacts assume technical competence: editing YAML, understanding cron syntax, managing environment variables, troubleshooting MCP server connections. The non-technical adaptation is "vestigial" (enterprise audit's word) -- one line of guidance with no mechanism. The glossary files don't exist. The step-by-step deployment guide (SUMMARY.md) is a template that has never been tested with a real non-technical user.

**How to avoid:**
1. Detect technical level in Phase 1 (first question) and branch the entire flow, not just language. For non-technical users, the deployment phase should be a guided setup wizard, not artifact generation.
2. For non-technical users, AgentBloc should generate a DEPLOYMENT_GUIDE.md that reads like a tutorial: numbered steps, screenshots/descriptions of what to expect, explicit "copy this and paste it here" instructions, and "if you see this error, do this" troubleshooting.
3. Provide a "deployment difficulty score" at the design phase gate. If the agent team requires 5+ integrations, OAuth flows, or browser automation, explicitly warn the user: "This deployment requires technical skills. Consider hiring a developer or using our consulting service."
4. Build glossary files (en/es) and reference them inline whenever technical terms appear.
5. The consulting upsell should be naturally positioned at this cliff point, not as a paywall but as an honest assessment: "Based on the complexity of your setup, you may want professional help with deployment."

**Warning signs:**
- Non-technical users asking "what do I do with these YAML files?"
- Deployment guides that assume terminal/CLI familiarity
- Users copy-pasting credentials into YAML files instead of environment variables
- Integration setup instructions referencing tools the user has never heard of
- Zero non-technical users successfully completing deployment end-to-end in testing

**Phase to address:**
Phase 2 (Core Skill Development) for technical-level branching. Phase 5 (Polish & Differentiation) for guided deployment wizard and glossaries.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Single monolithic SKILL.md | Faster to write, everything in one place | Context rot, instruction decay, unmaintainable at scale | Never for AgentBloc's complexity |
| Prose-only hard gates | Quick to add, no infrastructure needed | Claude ignores them under context pressure; false safety | Only during initial prototyping, must be replaced by structural rituals before any real user testing |
| Incomplete artifact templates | Ship faster, let Claude improvise | Inconsistent deployments, missing security fields, user confusion | Only for v0.1 prototype; must be complete before any external user |
| Skip the dry-run phase | Faster path to "deployed" | First production failure destroys user trust permanently | Never -- this is the enterprise-readiness audit's #2 critical item |
| Trust Claude's integration claims | Faster Phase 3, less friction | Hallucinated capabilities discovered at deployment time, user blames AgentBloc | Never -- the evidence protocol must be enforced |
| Test only with developer personas | Faster test cycles, testers understand the tool | Non-technical users hit the complexity cliff on first real use | Only for Phase 1-3 internal testing; non-technical testing required before any release |
| Hardcode English in artifact templates | Simpler templates, less work | Spanish-speaking users (a stated target market) cannot understand their own deployment | Acceptable for v0.1 if bilingual is in v0.2 scope |

---

## Integration Gotchas

Common mistakes when connecting to external services in the AgentBloc context.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| MCP Servers | Recommend `mcp-server-[service]` by pattern without verifying it exists | Use fully qualified names (`ServerName:tool_name`), verify on npm/GitHub, include trust score |
| Playwright/Browser Automation | Assume browser automation is simple and reliable | WAF/bot detection breaks Playwright regularly; require fallback chain and explicit warning about fragility |
| Gmail scraping | Treat email parsing as deterministic | Email formats change without notice; build schema-tolerant parsers with fuzzy matching |
| Google Sheets API | Use as a database replacement | Sheets has 10M cell limit, rate limits at 60 req/min for reads; flag when data volume exceeds these |
| Cron scheduling | Generate cron expressions without timezone awareness | Always specify timezone in cron config; include DST transition handling; show "next 5 runs" preview |
| OAuth flows | Assume user can complete OAuth setup independently | Non-technical users struggle with redirect URIs, client IDs, scopes; provide visual guides or flag for consulting |
| Banking APIs (PSD2/OpenBanking) | Assume a single aggregator covers all banks | Coverage varies by country/bank; require explicit bank-by-bank verification during Phase 3 |
| Telegram Bot API | Hardcode thread IDs that change | Use topic-based threading with dynamic lookup; store thread mapping in state file |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| JSON state files as database | Works for 10 tenants | File locking issues, corruption on concurrent writes, slow reads | >50 tenants or >1000 state entries per file |
| Single cron job for all agents | Simple to manage | Long-running jobs timeout, one failure blocks all downstream agents | >5 agents or >30 minutes total execution time |
| No idempotency tokens | Simpler code, fewer files | Retry after timeout causes duplicate actions (double payments, double emails) | First network timeout during a write operation |
| Unbounded context in agent prompts | Agents "know everything" | Token costs explode, context rot degrades quality, API rate limits hit | >50 records per agent run or >100K tokens per session |
| Polling instead of events | Works when you check infrequently | Wastes API quota, misses time-sensitive events, increases cost linearly with frequency | >10 integrations or <5 minute freshness requirement |

---

## Security Mistakes

Domain-specific security issues beyond what the enterprise-readiness audit covers.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Prompt injection via ingested content | Agent processes a crafted email/webpage that hijacks its instructions | System prompts must treat all ingested content as untrusted data; input sanitization before LLM context (already in audit, but the implementation pattern needs to be in the reference file, not just mentioned) |
| Credential leakage in LLM conversation logs | API keys or tokens appear in Claude Code conversation history, which syncs to Anthropic servers | Never pass raw credentials through Claude's context; use env var references (`$BANK_API_KEY`) that the execution layer resolves |
| Over-scoped API credentials | User provides admin token because it's the only one they have | Phase 3 must include a "minimum viable permission" analysis per integration; warn when credentials exceed required scope |
| State file tampering | Attacker modifies state JSON to re-trigger processed transactions or skip validation | State files should include checksums; critical state (financial) should use append-only logs, not mutable JSON |
| Unverified MCP server supply chain | User installs an MCP server recommended by AgentBloc that contains malicious code | Include trust-score assessment (GitHub stars, publisher, last commit, known CVEs) per Anthropic recommendation; warn on unverified publishers |
| Telegram bot token exposure | Bot token in config file grants full control of the bot (read messages, send as bot) | Telegram tokens must be in env vars, never in YAML; document the blast radius of a compromised bot token |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Dumping 5 interview questions at once | User overwhelmed, gives shallow answers, important details missed | Ask one question at a time; each answer shapes the next question (already in SKILL.md, but enforce it as a "low freedom" instruction) |
| Technical jargon without explanation | Non-technical user feels stupid, loses confidence, abandons the flow | Detect technical level early; branch language; inline glossary references |
| No progress indicator across phases | User doesn't know how much is left, feels like the interview will never end | Show "Phase 1 of 6 - Interview (approximately 10-15 questions remaining)" at each step |
| Design diagrams using ASCII art only | Non-technical users cannot parse ASCII topology diagrams | Supplement with plain-language description: "Agent A collects invoices, then passes them to Agent B which matches payments" |
| Presenting all integration options equally | User paralyzed by choice (API vs MCP vs Playwright vs Gmail scraping) | Present one RECOMMENDED option with rationale, then "alternatives" collapsed/secondary |
| Silent deployment with no "it's working" confirmation | User doesn't know if deployment succeeded | After deployment, run a verification check and report "Your agent team is configured and will first run at [next cron time]. Here is how to check if it worked: [specific instructions]" |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **SKILL.md restructured:** Often missing -- reference files exist but SKILL.md still contains the full content instead of pointers. Verify SKILL.md is under 250 lines AND reference files are correctly linked.
- [ ] **Hard gates enforced:** Often missing -- `[PHASE: N | GATE: X]` prefix added but Claude stops using it after Phase 2. Verify gate ritual appears in EVERY Claude response throughout a full 6-phase test conversation.
- [ ] **Artifact templates complete:** Often missing -- team.yaml and agent.yaml defined but governance.yaml, telegram.yaml, state schemas, and per-agent skill markdown are still placeholder descriptions. Verify all 6 artifact types have YAML/JSON Schema definitions.
- [ ] **Integration evidence protocol working:** Often missing -- the instruction exists but Claude still outputs integration recommendations without URLs or version numbers. Verify by checking 5+ integration claims in a test run for evidence lines.
- [ ] **Dry run actually stubs side effects:** Often missing -- dry run phase described but the generated artifacts don't include a test mode. Verify generated ClaudeClaw jobs have a `--dry-run` flag or equivalent that stubs external calls.
- [ ] **Non-technical flow tested with a non-technical person:** Often missing -- developers test with developer prompts and declare success. Verify by having an actual non-technical user complete the full flow and documenting where they get stuck.
- [ ] **Bilingual support works end-to-end:** Often missing -- conversation in Spanish works but artifact field names, deployment guide, error messages, and glossary are all English. Verify the ENTIRE experience works in Spanish, not just the chat.
- [ ] **Consulting upsell positioning natural:** Often missing -- consulting mentioned in README but never surfaces during the actual skill flow when the user hits a complexity cliff. Verify the skill naturally suggests professional help when deployment complexity exceeds user capability.

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Context rot causes skipped safety steps | MEDIUM | Re-run deployment phase with explicit instruction to re-read all reference files; add a "safety audit" post-generation step that checks artifacts for required fields |
| Skill fails to activate | LOW | User can manually invoke with `/agentbloc`; add more trigger phrases to frontmatter; implement hook-based fallback |
| Generated artifacts have invalid YAML | LOW | Run `yamllint` on all generated files; fix and regenerate; add validation to the deployment phase |
| Hallucinated integration recommendation | HIGH | Must re-run Phase 3 with strict evidence protocol; user may have designed around a non-existent capability; could cascade to Phase 2 redesign |
| Multi-agent coordination failure in production | HIGH | Requires analysis of which agents are conflicting; add iteration limits and circuit breakers; may need topology change (mesh -> pipeline) |
| Non-technical user stuck at deployment | MEDIUM | Provide step-by-step video/written walkthrough; offer consulting session; simplify deployment to fewer manual steps |
| Credential leak in conversation logs | HIGH | Rotate ALL exposed credentials immediately; audit what data was accessible; update skill to use env var references exclusively |
| Prompt injection via ingested content | HIGH | Quarantine affected agent; review all actions taken under injection; add input sanitization layer; update system prompt defense |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Context rot kills skill compliance | Phase 1: Skill Restructuring | SKILL.md under 250 lines; full 6-phase test conversation with gate ritual verified in every response |
| Skill activation failure | Phase 1: Skill Restructuring + Phase 4: Testing | 20+ diverse prompt activation test; >90% activation rate across Haiku/Sonnet/Opus |
| Execution drift (steps skipped) | Phase 2: Core Skill Development | Checklist pattern in every phase; visible output required for every safety step; post-generation audit script |
| Generated artifacts don't work | Phase 2: Templates + Phase 4: Testing | All 6 artifact schemas defined; validation script passes on generated output; end-to-end deployment test |
| Integration hallucination | Phase 2: Evidence Protocol + Phase 4: Testing | 100% of integration claims in test runs include evidence line or [UNVERIFIED] tag |
| Multi-agent coordination failure | Phase 2: Design Patterns + Phase 4: Testing | Iteration limits, timeouts, circuit breakers present in every generated agent.yaml; simulated failure scenario test |
| Non-technical user abandonment | Phase 2: Tech-Level Branching + Phase 5: Polish | At least 2 non-technical users complete full flow in user testing; deployment difficulty score shown at design gate |
| Credential leakage | Phase 3: Security & Governance | Audit script checks no raw credentials appear in any generated artifact; env var references only |
| Prompt injection | Phase 3: Security & Governance | Reference file includes sanitization patterns; test with crafted malicious input in Phase 4 |
| Consulting upsell mispositioned | Phase 5: Polish & Differentiation | Skill naturally surfaces consulting suggestion at complexity cliff; verified in non-technical user test |

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Skill restructuring | Over-splitting into too many reference files, creating a maze Claude cannot navigate | Keep to one level of depth; max 8-10 reference files; clear table of contents in SKILL.md |
| Skill restructuring | Cutting SKILL.md too aggressively, losing critical context | Keep identity, hard gates, phase summaries, and reference links in SKILL.md; only move detailed procedures to reference files |
| Core skill development | Spending weeks perfecting one phase while others remain skeletal | Build ALL phases to minimum viable depth first, then iterate; a complete but rough flow beats a perfect Phase 1 with nothing else |
| Security & governance | "Security theater" -- adding security YAML fields that look impressive but are never enforced at runtime | Every security field must map to an actual enforcement mechanism (env var lookup, rate limit check, audit log write) |
| Testing | Testing only the happy path with the developer's own use case (Arco Rooms) | Require 3+ diverse scenarios (ecommerce, freelance, healthcare) with different data sensitivity levels and integration patterns |
| Testing | Declaring success after one successful test run | Test at least 3 full conversations per scenario; LLM non-determinism means one success does not guarantee reliability |
| Polish & launch | README that over-promises and under-delivers | Align README claims with actual tested capabilities; include honest "limitations" section; show real output, not hypothetical |
| Polish & launch | Launching without a single non-technical user having completed the flow | Block launch until at least one non-technical user test is documented with friction points addressed |

---

## Sources

- [Anthropic Official: Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) - Official ceiling of 500 lines, progressive disclosure patterns, checklist workflows, naming conventions
- [Chroma Research: Context Rot](https://research.trychroma.com/context-rot) - 18 frontier models tested, all degrade as context grows, some 95% to 60%
- [Claude Code CLAUDE.md Ignored (Multiple Sources)](https://medium.com/rigel-computer-com/claude-code-ignores-the-claude-md-how-is-that-possible-f54dece13204) - 150-line effective ceiling, delivery mechanism limitations
- [Claude Code Instructions Ignored (GitHub Issue #7777)](https://github.com/anthropics/claude-code/issues/7777) - Community reports of systematic instruction non-compliance
- [Composio: Why AI Agent Pilots Fail in Production](https://composio.dev/blog/why-ai-agent-pilots-fail-2026-integration-roadmap) - 88% of AI agents never reach production; integration issues are the leading cause
- [Towards Data Science: The 17x Error Trap](https://towardsdatascience.com/why-your-multi-agent-system-is-failing-escaping-the-17x-error-trap-of-the-bag-of-agents/) - Error amplification in uncoordinated multi-agent systems
- [Cogent: Multi-Agent Orchestration Failure Playbook](https://cogentinfo.com/resources/when-ai-agents-collide-multi-agent-orchestration-failure-playbook-for-2026) - Infinite loops, hallucinated consensus, resource deadlock patterns
- [Getmaxim: Multi-Agent System Reliability](https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/) - 40% of multi-agent pilots fail within 6 months; 79% from specification/coordination
- [Autonoma: Vibe Coding Failures](https://www.getautonoma.com/blog/vibe-coding-failures) - 7 documented production failures in 2025-2026; all had tests that would have caught them
- [DEV.to: Your AI Agent Configs Are Probably Broken](https://dev.to/avifenesh/your-ai-agent-configs-are-probably-broken-and-you-dont-know-it-16n1) - 0% activation on misconfigured skills; silent YAML failures; agnix linter
- [DEV.to: Claude Code Skills Activation Fixes](https://dev.to/oluwawunmiadesewa/claude-code-skills-not-triggering-2-fixes-for-100-activation-3b57) - Activation failure workarounds, hook-based fallback
- [MindStudio: Claude Code Skills Common Mistakes](https://www.mindstudio.ai/blog/claude-code-skills-common-mistakes-guide) - Over-specified instructions, kitchen-sink sessions, trust-then-verify gap

---
*Pitfalls research for: AgentBloc -- Claude Code skill for AI agent team design and deployment*
*Researched: 2026-04-13*
