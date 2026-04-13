# Feature Research

**Domain:** AI agent team design and deployment (conversational skill, not SaaS platform)
**Researched:** 2026-04-13
**Confidence:** HIGH (multiple competitor products analyzed, enterprise audit cross-referenced, production failure patterns verified)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = the skill feels broken or dangerous. Ordered by criticality.

| # | Feature | Why Expected | Complexity | Notes |
|---|---------|--------------|------------|-------|
| T1 | **Structured interview / requirements gathering** | Every competitor (CrewAI Studio, n8n, Relevance AI) starts with "describe what you want." AgentBloc must go deeper than a blank prompt -- users expect guided discovery of their manual process | MEDIUM | Already in SKILL.md as Phase 1. Needs enforcement (sizing, categories, completion criteria). Current version is strong but lacks hard-gate enforcement |
| T2 | **Multi-agent team design with clear contracts** | CrewAI, LangGraph, AutoGen all produce multi-agent topologies. Users expect separate agents per responsibility, not a monolith. Input/output contracts are standard | MEDIUM | Already in SKILL.md as Phase 2. Missing: blast-radius scoring, model routing rationale, cost estimation per agent |
| T3 | **Integration discovery and verification** | n8n has 400+ integrations, Relevance AI has 9,000+. Users expect the skill to know what integrations exist and whether they actually work. Hallucinated integrations are the #1 trust destroyer | HIGH | Phase 3 exists but lacks evidence protocol. Every integration claim must cite URL + package version + last-commit date. Unverified claims must be flagged [UNVERIFIED] |
| T4 | **Deployable artifact generation** | Dify, Flowise, n8n all produce runnable output. Users expect to go from design to "something I can run" -- not just documentation. AgentBloc generates .agentbloc/ directory with YAML configs, skill files, cron jobs | HIGH | Phase 5 exists. 4 of 6 templates incomplete (per-agent skill .md, governance.yaml, telegram.yaml, state schemas). Must complete all templates |
| T5 | **Human-in-the-loop gates** | LangGraph's standout feature is checkpointing + human approval. CrewAI has hierarchical delegation with manager approval. Every enterprise guide requires human gates for sensitive actions | LOW | Phase gates exist in SKILL.md. Need to also generate approval gates within deployed agents -- not just during design, but in production runtime |
| T6 | **Credential and secrets guidance** | 2026 best practice: runtime injection, never static credentials, unique agent identities, least privilege. 1Password, HashiCorp Vault, AWS Secrets Manager are standard. Users expect the skill to tell them WHERE secrets go | MEDIUM | Currently zero guidance (enterprise audit finding #1). Must add credential decision tree: env vars for simple setups, secrets manager for production, never in Git |
| T7 | **Data classification (PII/PHI/financial)** | GDPR enforcement broadening in 2026, NIST AI Agent Standards Initiative launched Jan 2026. Any workflow touching customer data must classify it. Users handling EU data EXPECT compliance patterns | MEDIUM | Currently missing. Must be added to interview phase: "Is this data PII, PHI, financial, or public?" Answer triggers compliance patterns downstream |
| T8 | **Failure handling and fallback chains** | n8n, CrewAI, LangGraph all document error handling. 85% per-step accuracy across 5 steps = only 44% end-to-end success. Users expect every agent to have retry logic, fallbacks, and escalation paths | MEDIUM | Partially in SKILL.md (Phase 4 confirmation includes failure handling). Needs to be systematic: every agent gets primary/fallback/escalate chain |
| T9 | **Step-by-step user confirmation** | Relevance AI, CrewAI Studio, and all visual builders show previews before execution. Users expect to approve every agent individually before anything runs | LOW | Phase 4 already covers this well. Just needs the structural enforcement (PHASE/GATE ritual) to prevent skipping |
| T10 | **Notification and reporting setup** | All competitors handle output delivery. Users expect to configure WHERE results go (Telegram, email, Slack) and WHEN (always, errors only, daily summary) | LOW | Telegram-centric approach is a reasonable default. telegram.yaml template needs completion. Should also document Slack/email alternatives for users who don't use Telegram |

### Differentiators (Competitive Advantage)

Features that set AgentBloc apart from CrewAI Studio, n8n, Relevance AI, Flowise, Dify, etc. These are where the consulting thesis lives.

| # | Feature | Value Proposition | Complexity | Notes |
|---|---------|-------------------|------------|-------|
| D1 | **Conversational guide (not visual builder)** | Every competitor is a visual drag-and-drop builder or web form. AgentBloc is the only product that works as a senior AI consultant inside Claude Code, asking probing questions, pushing back on bad ideas, and adapting language to user's technical level. This is the core differentiator | LOW (it's the product itself) | The skill's identity section already nails this. Must NOT drift toward building a visual builder -- that's the anti-feature trap |
| D2 | **Security-first design with blast-radius scoring** | No competitor in the skill/framework space does mandatory security analysis during design. CrewAI AMP offers enterprise security but as an afterthought add-on. AgentBloc bakes security INTO the design process: every agent gets a blast-radius score (read-only / write-scoped / write-unrestricted / send-external), automatic kill switches, and rate limits | HIGH | Enterprise audit findings 1.1-1.7. This is the hardest differentiator to build but the most defensible. Consulting clients will pay premium for security-audited agent designs |
| D3 | **Mandatory dry run before production** | No skill-level competitor requires a test run. LangGraph has checkpointing but it's developer-operated. AgentBloc mandates: agents execute against real data with side-effect tools stubbed, user reviews output, only then deploy. This prevents the #1 failure mode (untested agents in production) | MEDIUM | Insert as Phase 4.5. Need tool-stubbing patterns, dry-run report format, pass/fail criteria |
| D4 | **Integration evidence protocol** | CrewAI, n8n, Dify trust that integrations exist. AgentBloc requires proof: URL + package version + last-commit-date for every integration claim. Unverified claims flagged [UNVERIFIED]. This prevents the #1 trust-destroying hallucination: "just use the X API" when no such API exists | LOW | Simple protocol to enforce. High impact on trust. Biggest bang-for-buck differentiator |
| D5 | **Adaptive technical level detection** | Relevance AI and Lindy target non-technical users. CrewAI and LangGraph target developers. Nobody adapts mid-conversation. AgentBloc detects technical level (non-technical / basics / developer) and adjusts language, depth, and glossary usage accordingly | MEDIUM | First interview question: "Describe your technical level." Branch conversation style. Create glossaries (EN/ES) for non-technical terms (MCP, OAuth, cron, webhook, idempotency) |
| D6 | **Bilingual support (English/Spanish)** | No competitor offers native bilingual agent design. European market (GDPR compliance) + Latin American market = differentiated positioning for consulting | LOW | Already in SKILL.md conceptually. Needs glossary files and explicit language-detection protocol |
| D7 | **Phase 6 Evolution: post-deploy self-improvement** | No competitor has a structured self-improvement loop after deployment. AgentBloc proposes: weekly scan of agent ecosystem (GitHub, npm, papers), classify findings, propose improvements, human approval gate. This turns a one-time design into an ongoing consulting relationship | HIGH | This is the consulting upsell engine. Most complex to build but directly drives revenue. Defer detailed implementation to v1.1 but include the framework now |
| D8 | **Framework pattern library** | CrewAI, LangGraph, AutoGen, n8n each have strengths. AgentBloc references all of them: "if your workflow needs persistent state machines, use LangGraph's StateGraph pattern. If needs role-based collaboration, use CrewAI's Crew+Task pattern." No other tool offers cross-framework design guidance | MEDIUM | Create references/frameworks.md. Position AgentBloc as framework-agnostic architect, not locked to one framework |
| D9 | **Incident response runbook generation** | Enterprise deployments need documented incident procedures. AgentBloc generates INCIDENT_RESPONSE.md per deployment: who gets paged, rollback steps, escalation path. No competing skill does this | LOW | Template-based. Low effort, high enterprise value |
| D10 | **Zero-dependency deployment (Claude Code + cron + MCP)** | CrewAI requires Python runtime. LangGraph requires LangServe. n8n requires n8n server. Dify requires Docker. AgentBloc generates artifacts that run on any machine with Claude Code -- no custom runtime, no Docker, no server. Just cron + MCP + Telegram | LOW (it's already the architecture) | This is a massive advantage for non-technical users. Must be preserved. The "no new dependencies" constraint is a feature, not a limitation |

### Anti-Features (Deliberately NOT Building)

Features that seem good but would destroy AgentBloc's positioning, add unbounded complexity, or duplicate what competitors do better.

| # | Feature | Why Requested | Why Problematic | Alternative |
|---|---------|---------------|-----------------|-------------|
| A1 | **Visual workflow builder / drag-and-drop UI** | "I want to SEE my agent pipeline." Every competitor has one (n8n, Flowise, Dify, Relevance AI) | Would require a web app, frontend framework, hosting. Completely changes the product from skill to SaaS. The market is saturated with visual builders -- AgentBloc wins by NOT being one | Generate ASCII diagrams during design (already in Phase 2). The conversational approach IS the differentiator. If users want visual, recommend n8n |
| A2 | **Custom TypeScript/Python runtime** | "Agents should run in a real runtime, not just Claude Code + cron" | Adds massive infrastructure complexity. Requires hosting, monitoring, deployment pipeline. v1.0 must validate the consulting thesis with zero infrastructure | Claude Code IS the runtime. Cron IS the scheduler. MCP IS the tool layer. This is proven in production (ClaudeClaw pattern). v2.0 can add a custom runtime only after v1.0 validates demand |
| A3 | **Real-time streaming / WebSocket agent communication** | "Agents should talk to each other in real-time" | Requires persistent server process, WebSocket infrastructure, state synchronization. Overkill for batch workflows that run on cron schedules | Agents communicate via state files (JSON/YAML). Sequential pipeline execution handles 90% of use cases. Real-time is a v2+ consideration |
| A4 | **Multi-tenant SaaS hosting** | "I want to host agent teams for my clients on a shared platform" | Requires tenant isolation infrastructure, billing, multi-cloud deployment, SOC 2 certification. Premature for v1.0 | Document tenant isolation PATTERNS (separate namespaces, credentials, state). Let users self-host. Consulting engagement handles multi-tenant for enterprise clients |
| A5 | **Agent marketplace / template store** | "Let me browse pre-built agent teams for my industry" | Requires curation, quality control, versioning, review process. Community management overhead. Premature without user base | Ship 3-5 example walkthroughs (ecommerce, real estate, freelance pipeline). Let organic demand drive marketplace if/when needed |
| A6 | **Mobile app or native client** | "I want to design agents from my phone" | Claude Code is a terminal tool. Mobile adds entire platform layer. No competing Claude Code skill has a mobile companion | Telegram serves as the mobile interface for deployed agents. Design happens on desktop in Claude Code. This is fine |
| A7 | **Paid features / license gating** | "Monetize the skill directly" | Fragments the open-source community. Reduces portfolio/consulting value. Claude Code skills ecosystem is open | Revenue comes from consulting engagements, not software licensing. The skill IS the lead generator |
| A8 | **RAG / knowledge base ingestion** | "Let agents search my documents" | Adds vector database dependency, embedding pipeline, chunking strategy. Scope explosion | If a user needs RAG, recommend Dify or integrate via MCP servers that provide search capabilities. Don't build RAG into the skill itself |
| A9 | **LLM fine-tuning or training** | "Can AgentBloc train a custom model for my agents?" | Completely outside scope. Requires ML infrastructure, GPU access, training data pipelines | AgentBloc designs agent teams that use existing models (Opus/Sonnet/Haiku). Model routing per agent role is sufficient. Fine-tuning is a separate concern |

## Feature Dependencies

```
[T1: Interview]
    |-- feeds into --> [T2: Team Design]
    |                      |-- feeds into --> [T3: Integration Discovery]
    |                      |                      |-- feeds into --> [T9: Step-by-Step Confirmation]
    |                      |                                              |-- feeds into --> [D3: Dry Run]
    |                      |                                                                    |-- feeds into --> [T4: Artifact Generation]
    |                      |                                                                                          |-- feeds into --> [D7: Evolution]
    |                      |
    |                      |-- requires --> [D2: Security/Blast-Radius] (during design phase)
    |                      |-- enhanced by --> [D8: Framework Pattern Library]
    |
    |-- triggers --> [T7: Data Classification] (during interview)
    |                    |-- activates --> [T6: Credential Guidance] (if sensitive data found)
    |                    |-- activates --> GDPR/HIPAA/PCI patterns (if regulated data found)

[T4: Artifact Generation]
    |-- includes --> [T5: Human-in-the-Loop Gates] (in deployed agent configs)
    |-- includes --> [T8: Failure Handling] (in agent YAML fallbacks)
    |-- includes --> [T10: Notification Setup] (telegram.yaml)
    |-- includes --> [D9: Incident Response Runbook]
    |-- includes --> [T6: Credential Guidance] (in integration setup docs)

[D4: Evidence Protocol] -- enhances --> [T3: Integration Discovery]
[D5: Technical Level Detection] -- enhances --> [T1: Interview]
[D6: Bilingual Support] -- enhances --> ALL phases
[D1: Conversational Guide] -- IS --> the entire product
[D10: Zero-Dependency Deploy] -- constrains --> [T4: Artifact Generation]
```

### Dependency Notes

- **T1 (Interview) is the foundation:** Everything downstream depends on interview quality. If the interview misses edge cases, design will be flawed, integrations will be wrong, and deployment will fail. Invest disproportionate effort here.
- **T7 (Data Classification) triggers security features:** Must happen during interview. If data is PII/PHI/financial, it activates credential guidance (T6), compliance patterns, and elevated blast-radius scrutiny (D2). Late detection means redesign.
- **D2 (Security) must be embedded in design, not bolted on:** The enterprise audit found that "agent systems that reach the demo stage without governance controls almost never get them added later." Security must be in Phase 2 design, not Phase 5 deployment.
- **D3 (Dry Run) blocks artifact generation:** Agents must not go to production without a test run. This is a hard dependency -- Phase 4.5 must pass before Phase 5 begins.
- **D4 (Evidence Protocol) is trivially cheap and trust-critical:** Simplest differentiator to implement. Prevents the most common trust failure (hallucinated APIs). Should be in the first build phase.
- **D7 (Evolution) depends on everything else:** Cannot self-improve agents that weren't properly designed and deployed. This is the final phase, built on top of a solid foundation.

## MVP Definition

### Launch With (v1.0)

Minimum viable product -- what's needed to validate the consulting thesis: "A non-technical business owner can describe their problem and end up with a deployed, secure agent team."

- [x] **T1: Structured interview with 8 categories** -- already exists, needs enforcement polish
- [ ] **T2: Multi-agent team design with contracts and topology** -- exists, add blast-radius scoring (D2 lite)
- [ ] **T3: Integration discovery with evidence protocol (D4)** -- exists, add verification requirement
- [ ] **T9: Step-by-step confirmation with phase gates** -- exists, add structural enforcement
- [ ] **D3: Mandatory dry run** -- NEW, critical safety feature
- [ ] **T4: Complete artifact generation (all 6 templates)** -- exists, complete missing templates
- [ ] **T5: Human-in-the-loop gates in deployed agents** -- partial, formalize
- [ ] **T6: Credential management guidance** -- NEW, minimum security
- [ ] **T7: Data classification in interview** -- NEW, triggers compliance
- [ ] **T8: Failure handling per agent** -- partial, systematize
- [ ] **T10: Notification setup (Telegram)** -- partial, complete template
- [ ] **D1: Conversational guide identity** -- exists, polish
- [ ] **D4: Integration evidence protocol** -- NEW, cheap and critical
- [ ] **D5: Technical level detection** -- NEW, required for non-technical users
- [ ] **D6: Bilingual support** -- partial, add glossaries
- [ ] **D9: Incident response runbook** -- NEW, template-based
- [ ] **D10: Zero-dependency deployment** -- already the architecture

### Add After Validation (v1.x)

Features to add once the core flow is proven with real users.

- [ ] **D2 full: Comprehensive blast-radius scoring** -- Add formal scoring matrix (read-only / write-scoped / write-unrestricted / send-external) with automatic permission-minimization pass. Trigger: first enterprise client engagement
- [ ] **D8: Framework pattern library** -- Cross-reference CrewAI, LangGraph, AutoGen, n8n patterns during design. Trigger: users asking "why not use CrewAI directly?"
- [ ] **Audit logging specification** -- Correlation IDs, PII redaction, log retention policies in governance.yaml. Trigger: first regulated-industry client
- [ ] **Test scenario harness** -- Replayable user-turn scenarios (JSONL) for regression testing. Trigger: skill changes breaking existing flows
- [ ] **Prompt injection defense guidance** -- Patterns for agents ingesting external content (emails, web pages). Trigger: any agent that reads untrusted input

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **D7: Phase 6 Evolution / self-improvement loop** -- Weekly ecosystem scanning, auto-propose improvements, human approval gate. Why defer: needs stable base to improve upon, highest complexity
- [ ] **Custom TypeScript runtime** -- Only if v1.0 proves demand for programmatic agent orchestration beyond Claude Code + cron
- [ ] **Advanced observability (OpenTelemetry integration)** -- Distributed tracing for multi-agent workflows. Only needed at scale
- [ ] **Multi-tenant isolation patterns** -- Documented but not enforced in v1.0. Build tooling when consulting practice scales
- [ ] **Agent-to-agent communication protocols** -- Beyond sequential pipeline (mesh, swarm topologies). Only if user demand surfaces
- [ ] **Example walkthrough library** -- Full end-to-end walkthroughs for 5+ industries. Ship 1-2 in v1.0, expand based on consulting engagements

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase |
|---------|------------|---------------------|----------|-------|
| D4: Evidence protocol | HIGH | LOW | **P1** | 1 |
| D5: Technical level detection | HIGH | LOW | **P1** | 1 |
| T6: Credential guidance | HIGH | MEDIUM | **P1** | 1 |
| T7: Data classification | HIGH | MEDIUM | **P1** | 1 |
| D3: Mandatory dry run | HIGH | MEDIUM | **P1** | 1 |
| T4: Complete artifact templates | HIGH | MEDIUM | **P1** | 1 |
| D9: Incident response runbook | MEDIUM | LOW | **P1** | 1 |
| D6: Bilingual glossaries | MEDIUM | LOW | **P1** | 1 |
| D2: Blast-radius scoring (lite) | HIGH | MEDIUM | **P1** | 1 |
| Phase gate enforcement (ritual) | HIGH | LOW | **P1** | 1 |
| T8: Systematic failure handling | MEDIUM | MEDIUM | **P2** | 1.x |
| D8: Framework pattern library | MEDIUM | MEDIUM | **P2** | 1.x |
| Audit logging spec | MEDIUM | MEDIUM | **P2** | 1.x |
| Prompt injection defense | HIGH | LOW | **P2** | 1.x |
| Test scenario harness | MEDIUM | HIGH | **P2** | 1.x |
| D7: Evolution loop | HIGH | HIGH | **P3** | 2+ |
| Advanced observability | MEDIUM | HIGH | **P3** | 2+ |
| Multi-tenant tooling | LOW | HIGH | **P3** | 2+ |

**Priority key:**
- P1: Must have for v1.0 launch -- validates consulting thesis
- P2: Should have, add when core is proven
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | CrewAI | LangGraph | n8n | Relevance AI | Flowise | Dify | **AgentBloc** |
|---------|--------|-----------|-----|-------------|---------|------|---------------|
| **Approach** | Code-first Python | Code-first Python | Visual builder | No-code web | Visual builder | Visual builder | **Conversational skill** |
| **Target user** | Developers | Developers | Ops/low-code | Non-technical | Low-code | Low-code/dev | **Non-technical to developer** |
| **Multi-agent design** | Yes (Crew + Task) | Yes (StateGraph) | Yes (sub-workflows) | Yes (multi-agent teams) | Yes (AgentFlow V2) | Yes (workflow nodes) | **Yes (interview-driven)** |
| **Integration count** | LangChain ecosystem | LangChain ecosystem | 400+ nodes | 9,000+ | 100+ LLMs | 50+ built-in tools | **Discovery-based (any API/MCP)** |
| **Security built-in** | Enterprise add-on (AMP) | None (DIY) | Basic auth | Enterprise tier | Basic | Enterprise tier | **First-class, mandatory** |
| **Dry run / testing** | None at skill level | Checkpointing (dev) | Test mode | None visible | None visible | Logs/annotations | **Mandatory pre-production** |
| **Human-in-the-loop** | Manager agent | Built-in checkpoints | Manual approvals | Workflow triggers | Human feedback nodes | Manual steps | **Phase gates + runtime gates** |
| **Credential guidance** | None | None | Environment vars | Platform-managed | Environment vars | Platform-managed | **Decision tree + best practices** |
| **Deployment target** | Python runtime | LangServe / Cloud | n8n server | Cloud platform | Docker/Cloud | Docker/Cloud | **Claude Code + cron (zero infra)** |
| **Cost to start** | Free (OSS) + hosting | Free (OSS) + hosting | Free (self-host) | Free tier (200 actions) | Free (OSS) + hosting | Free (OSS) + hosting | **Free (Claude Code sub only)** |
| **Consulting value** | Low (commodity) | Low (commodity) | Medium (custom flows) | Low (template-driven) | Low (commodity) | Medium (custom apps) | **HIGH (designed for it)** |

### Key Competitive Insight

The market is saturated with visual builders and code-first frameworks. AgentBloc's competitive advantage is NOT in features -- it's in the **delivery mechanism** (conversational, adaptive, security-first) and the **deployment model** (zero infrastructure, immediate artifacts). The consulting thesis works because:

1. **Non-technical users cannot use CrewAI/LangGraph** -- they need a guide, not a framework
2. **Visual builders produce generic output** -- AgentBloc produces custom, security-audited designs
3. **Nobody does mandatory security during design** -- this is the enterprise unlock
4. **Nobody requires evidence for integrations** -- this prevents the #1 hallucination failure

## Sources

### Competitor Products (Direct Analysis)
- [CrewAI](https://crewai.com/) -- Role-based agent orchestration framework
- [LangGraph](https://www.langchain.com/langgraph) -- Graph-based agent orchestration (v1.1.6 as of April 2026)
- [AutoGen (Microsoft)](https://github.com/microsoft/autogen) -- Multi-agent framework (now in maintenance mode, superseded by Microsoft Agent Framework)
- [n8n](https://n8n.io/ai-agents/) -- Visual AI workflow automation
- [Relevance AI](https://relevanceai.com/agents) -- No-code multi-agent platform (9,000+ integrations)
- [Flowise](https://flowiseai.com/) -- Open-source visual AI agent builder (AgentFlow V2)
- [Dify](https://dify.ai/) -- Open-source LLM app platform ($30M funding, 1.4M+ machines)

### Enterprise Security and Governance
- [AI Agent Secrets Management Best Practices](https://fast.io/resources/ai-agent-secrets-management/) -- Fastio 2026
- [AI Agent Security Enterprise Guide](https://www.mintmcp.com/blog/ai-agent-security) -- MintMCP 2026
- [NIST AI Agent Standards Initiative](https://www.federalregister.gov/documents/2026/01/08/2026-00206/request-for-information-regarding-security-considerations-for-artificial-intelligence-agents) -- Federal Register Jan 2026
- [AI Agent Governance Checklist for CISOs](https://zenity.io/blog/security/ai-agent-governance) -- Zenity 2026

### Production Failure Patterns
- [Why 88% of AI Agents Fail in Production](https://bonjoy.com/articles/why-ai-agents-fail-production/) -- Bonjoy Enterprise Guide
- [Three Disciplines Separating Demos from Deployment](https://venturebeat.com/orchestration/the-three-disciplines-separating-ai-agent-demos-from-real-world-deployment) -- VentureBeat
- [Why AI Agents Keep Failing in Production](https://medium.com/data-science-collective/why-ai-agents-keep-failing-in-production-cdd335b22219) -- Data Science Collective

### Testing and Deployment
- [Agent Harness Engineering Guide](https://qubittool.com/blog/agent-harness-evaluation-guide) -- QubitTool 2026
- [15 Best Practices for Deploying AI Agents](https://blog.n8n.io/best-practices-for-deploying-ai-agents-in-production/) -- n8n Blog
- [How to Test an AI Agent Before Production](https://theagentlabs.com/blog-how-to-test-ai-agent) -- The Agent Labs

### Claude Code Ecosystem
- [Claude Code Skills vs MCP Servers](https://dev.to/williamwangai/claude-code-skills-vs-mcp-servers-what-to-use-how-to-install-and-the-best-ones-in-2026-548k) -- DEV Community 2026
- [Claude Code for Production: MCP, Subagents, CLAUDE.md](https://dev.to/lizechengnet/how-to-structure-claude-code-for-production-mcp-servers-subagents-and-claudemd-2026-guide-4gjn) -- DEV Community 2026

### AI Agent Observability
- [AI Agent Observability in 2026](https://dev.to/chunxiaoxx/ai-agent-observability-in-2026-openai-agents-sdk-langsmith-and-opentelemetry-3ale) -- DEV Community
- [AI Agent Observability: Enterprise Standard](https://www.n-ix.com/ai-agent-observability/) -- N-iX 2026

---
*Feature research for: AI agent team design and deployment (Claude Code skill)*
*Researched: 2026-04-13*
