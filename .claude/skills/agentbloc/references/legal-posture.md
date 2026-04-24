# Legal Posture for Browser Discovery

> Loaded by the `browser-discovery` subagent in its forked context on every invocation (per Phase 11 D-58 context-budget discipline, NOT unconditionally at Phase 3 entry). Also available for the user to audit at any time. Defines the five-jurisdiction variance matrix, the DISCOVERY-LICENSE-NOTICE.md template, the OPT_IN_LEDGER.jsonl append-only format, the user attestation protocol, the tool-provider disclaimer AgentBloc surfaces in every DISCOVERY-REPORT.md header, and the jurisdictional red-flag halt conditions.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Jurisdictional Variance Matrix](#jurisdictional-variance-matrix)
- [ToS Tier Classification Protocol](#tos-tier-classification-protocol)
- [DISCOVERY-LICENSE-NOTICE.md Template](#discovery-license-noticemd-template)
- [OPT_IN_LEDGER.jsonl Format](#opt_in_ledgerjsonl-format)
- [User Attestation Protocol](#user-attestation-protocol)
- [Tool-Provider Disclaimer](#tool-provider-disclaimer)
- [Jurisdictional Red Flags](#jurisdictional-red-flags)
- [Quick Reference](#quick-reference)

## When This Applies

This file is loaded by the `browser-discovery` subagent (context: fork per Phase 9 D-21 + Phase 11 D-43) at the top of every discovery invocation, before the subagent launches a browser session. The user may also grep this file directly when auditing whether a particular service was discovered lawfully; the OPT_IN_LEDGER.jsonl entries below cross-reference back to this file via the `attestation` text block.

Cross-reference: [credentials.md](credentials.md) governs credential posture (OAuth vs scoped API key vs admin token) once opt-in passes; this file governs the opt-in gate itself. Credential decisions happen after a DISCOVERY-LICENSE-NOTICE.md is signed and an OPT_IN_LEDGER.jsonl line is appended; never before.

## Jurisdictional Variance Matrix

The five rows below cover the jurisdictions AgentBloc expects a v2.0 user base to declare. Each row names the broadest reading of the relevant law (the worst-case prosecutorial stance), the safe-harbor condition under which that reading is unlikely to apply, and the highest-risk failure mode the user should avoid. Jurisdiction column uses ISO-3166 alpha-2 codes where feasible plus "EU" for the Union-level framework.

| Jurisdiction | Relevant Law | Broadest Interpretation | Safe-Harbor Condition | Highest-Risk Failure Mode |
| --- | --- | --- | --- | --- |
| US | CFAA + DMCA section 1201 | Post-Van Buren narrow "gates-up-or-down" reading applies to CFAA; DMCA section 1201 separately criminalizes circumvention of technical access-control measures regardless of user authorization. | Logged-in user automating their own account with a documented API path and least-privilege OAuth scope. | INTERNAL-HARDENED endpoint (vendor-signaled "external automation not welcome") combined with TOS-RED classification. |
| UK | Computer Misuse Act 1990 + CPS 2020 Code for Prosecutors guidance | Bypassing any access-control mechanism, including rate limits or bot-detection challenges, can support a section 1 offence. | Well-behaved target interaction, documented API usage, no rate-limit circumvention, no Cloudflare challenge bypass. | Cloudflare or equivalent WAF challenge bypass via any means, including "just slow it down enough to look human." |
| EU | GDPR Art 5(1)(a) + Art 6 + national implementations | Processing third parties' personal data visible inside the user's admin view without a lawful basis is itself a violation, separate from any access-layer question. | User is the data controller for the captured data with a documented lawful purpose (Art 6(1)(b) contract / 6(1)(f) legitimate interest with balancing test). | Scraping admin panels containing third-party PII without redaction, or retaining captured PII beyond the discovery run. |
| DE | BDSG section 202a (Ausspaehen von Daten) | German federal data-protection law carries a broad "spying on data" interpretation that can attach criminal liability even where civil GDPR exposure is marginal. | Same conditions as EU row plus an explicit jurisdictional banner in DISCOVERY-LICENSE-NOTICE.md acknowledging BDSG applies. | German WAF encountered (multiple native-language CAPTCHA pages, DSGVO-specific interstitials), combined with captured third-party PII. |
| BR | LGPD (Lei Geral de Protecao de Dados, similar to GDPR) | Processing personal data requires a legal basis and grants data-subject rights; violations carry administrative sanctions plus civil exposure. | Same conditions as EU row with the user identified as the controller for LGPD purposes. | Brazilian jurisdiction declared at attestation combined with a TOS-RED service; the LGPD + ToS-breach combination is a compounding exposure. |

Post-matrix context (2 paragraphs):

**Van Buren v. United States (2021 US Supreme Court)** narrowed CFAA's "exceeds authorized access" to a "gates-up-or-down" reading: a user with authorized access to a system cannot be prosecuted under the CFAA merely for accessing information in that system in a way the terms of service disallow. However, this reading is NOT a blanket safe harbor. INTERNAL-HARDENED endpoints (per D-53 in `discovery-report-schema.md`) still carry civil exposure under DMCA section 1201 if a technical access-control measure is circumvented; Van Buren does not touch DMCA. hiQ Labs v. LinkedIn (2022 9th Cir.) further established that publicly-accessible data scraping is not automatically CFAA-violating, but that decision does NOT extend to logged-in INTERNAL endpoints and does NOT address ToS breach (which remains a state-law contract claim).

**EU, DE, and BR rows tilt heavier on data-protection law than on access law.** If captured content contains third-party PII without a lawful basis, the violation lives in the processing, not in the access. This matters for AgentBloc because a subagent logged into its own admin account might still trip GDPR / BDSG / LGPD on captured content that belongs to the account holder's customers or employees. The `output-firewall.md` PII redaction pipeline is the primary control for this risk; the ToS Tier Classification Protocol below is the secondary control (an AMBER / RED classification surfaces the question to the user before the browser launches).

## ToS Tier Classification Protocol

Decision-tree step grammar mirroring the credentials.md shape. Every browser-fallback discovery runs through these five steps before the subagent navigates past the landing page.

**Step 1: Fetch the ToS in-session, not from training memory.**
- Use Playwright `browser_navigate` to the target's Terms-of-Service URL, then `browser_snapshot` to capture the rendered DOM.
- Extract the visible ToS text into a single string; SHA256 the string (64-hex digest) and store the hash + the URL + the first 2000 characters of the excerpt in DISCOVERY-LICENSE-NOTICE.md.
- Tampering with the stored excerpt is detectable by recomputing the SHA256 and comparing.

**Step 2: Grep the fetched excerpt for trigger keywords.**
- Case-insensitive match against: `bot`, `automated`, `automation`, `scrape`, `scraping`, `reverse engineer`, `circumvent`, `bypass`, `unauthorized access`, `artificial intelligence`, `machine`, `crawler`.
- Each hit records the keyword plus a 40-character context window around the match for the classifier input.

**Step 3: Classify into a tier.**
- **TOS-GREEN**: No trigger keywords hit AND an explicit API / developer terms section exists inside the ToS or at a linked `/developers` / `/api` URL. Lowest-risk path.
- **TOS-AMBER**: Silent ToS (no trigger keywords hit AND no API / developer terms section exists) OR trigger keywords appear only in a neutral context (e.g., "bots may be used for accessibility features"). Proceed with heightened attestation.
- **TOS-RED**: Any trigger keyword appears in a prohibitive context (e.g., "You may not use automated means to access...", "You will not scrape, crawl, or reverse engineer..."). Auto-triggers a Posture-C-style halt per D-49 in `browser-stack.md`; emit `DISCOVERY-BLOCKED-REPORT.md` and do not launch a session.

**Step 4: Data-subject scope check.**
- Does the target account contain third-party PII (customer emails, employee records, supplier contacts, patient data)? The user answers yes or no at attestation.
- If YES, GDPR / LGPD lawful-basis determination is required BEFORE opt-in attestation; the subagent surfaces the question and waits for a user-supplied lawful basis (contract, legitimate interest with balancing test, consent).

**Step 5: Jurisdictional exposure check.**
- Ask the user their jurisdiction (ISO-3166 alpha-2) and cross-reference the row in the Variance Matrix above.
- Surface the matching "Highest-Risk Failure Mode" to the user in the opt-in prompt so the user can weigh it before signing.
- Combine Step 4 answer with Step 5 jurisdiction to decide whether the user's jurisdiction + data-subject scope triggers a Jurisdictional Red Flag below.

## DISCOVERY-LICENSE-NOTICE.md Template

Per D-47. Lives at `.agentbloc/discovery/<service-slug>/DISCOVERY-LICENSE-NOTICE.md`, committed to the user's repo (not gitignored). Provides the GDPR Article 30 record-of-processing trail.

```
# Discovery License Notice: <service-slug>

**Generated:** <ISO-8601>
**ToS URL:** <fetched-in-session URL>
**ToS Excerpt (first 2000 chars):**
<verbatim excerpt captured via Playwright browser_snapshot>
**ToS Excerpt SHA256:** <64-hex>
**ToS Tier:** TOS-GREEN | TOS-AMBER | TOS-RED
**Jurisdictional Banner:** <user jurisdiction ISO-3166 alpha-2> + <highest-risk failure mode row from Variance Matrix>

## User Attestation

I, the authorized account holder for the service at <service URL>, declare:
1. I am the account holder or have explicit written authorization from the account holder.
2. I am using AgentBloc to automate my own account activity, not a third party's.
3. I have read the ToS excerpt above and the classification.
4. My jurisdiction is <ISO-3166 alpha-2>.
5. I accept the highest-risk failure mode noted above.

**Attestation timestamp:** <ISO-8601>
**Client IP at attestation:** <IP>

## Tool-Provider Disclaimer

AgentBloc is a general-purpose research tool. The user is solely responsible for lawful use. AgentBloc takes no position on whether any specific Discovery run is lawful in the user's jurisdiction. This tool enforces opt-in gates (per D-37), anti-bot deny-list (per D-48), PII redaction (per D-52), and posture-C halt (per D-49), but legal determination rests with the user.
```

Rationale: the file is committed to the user's repo so that a subsequent audit (user-initiated or third-party) can reconstruct what the user consented to at the moment the browser launched. The SHA256 of the ToS excerpt pins the ToS language the user read; a later ToS change does not retroactively alter the attestation record. INTERNAL-HARDENED endpoint classification (see `discovery-report-schema.md`) requires an addendum to this notice re-attesting the heightened risk.

## OPT_IN_LEDGER.jsonl Format

Per D-46. Lives at `.agentbloc/discovery/OPT_IN_LEDGER.jsonl` (project-level; one file for all services in the project). Append-only. One JSON object per line. Resolves research Open Decision #6 (per-project, not per-user-global).

Schema:

```
{"service_slug":"mapfre-insurance-portal","opted_in_at":"2026-04-21T18:30:00Z","ip":"203.0.113.42","jurisdiction":"ES","tos_tier":"TOS-AMBER","tos_url":"https://mapfre.es/legal/tos","tos_excerpt_sha256":"<64-hex>","attestation":"I am the authorized account holder..."}
```

Field contracts:
- `service_slug`: kebab-case; matches the per-service directory under `.agentbloc/discovery/`.
- `opted_in_at`: ISO-8601 UTC; must be <= current time at subagent launch.
- `ip`: the client's public IP at attestation time (user may supply via `.env` `AGENTBLOC_USER_IP` or allow the subagent to capture it from the outbound request).
- `jurisdiction`: ISO-3166 alpha-2 (e.g., `ES`, `US`, `DE`, `GB`, `BR`).
- `tos_tier`: one of `TOS-GREEN`, `TOS-AMBER`, `TOS-RED`. A `TOS-RED` line is a signal that the subagent then halted before launching, not permission to launch.
- `tos_url`: the URL fetched in Step 1 of the ToS Tier Classification Protocol.
- `tos_excerpt_sha256`: 64-hex digest matching the value in DISCOVERY-LICENSE-NOTICE.md for the same service.
- `attestation`: the full attestation text the user signed, copy-pasted from the DISCOVERY-LICENSE-NOTICE.md User Attestation section.

Correction protocol: corrections require a SECOND ledger entry with a `corrects_entry: <sha256 of prior line>` field naming the SHA256 of the prior line's full JSON text. The original line is NEVER edited or deleted. Append-only discipline is the GDPR Article 30 requirement for an immutable record-of-processing audit trail; a mutable ledger would forfeit the compliance value.

Correction example (append AFTER the original line, never replace):

```
{"service_slug":"mapfre-insurance-portal","corrects_entry":"<sha256 of the prior line>","opted_in_at":"2026-04-21T19:05:00Z","ip":"203.0.113.42","jurisdiction":"ES","tos_tier":"TOS-AMBER","tos_url":"https://mapfre.es/legal/tos","tos_excerpt_sha256":"<64-hex>","attestation":"Correction: updated jurisdiction value. Original attestation otherwise stands."}
```

Auditors walk the ledger top-to-bottom. When they encounter a line with `corrects_entry`, they match the referenced SHA256 against the prior line in the file. Any line that is NOT later corrected is the authoritative record for its `service_slug`.

Rationale: per-project scope (not per-user-global) means the ledger travels with the repo, survives session boundaries, and is version-controlled alongside the rest of the project state. A user who shares a repo with a collaborator shares the ledger; a user who archives a repo archives the ledger. Every audit question ("did the user consent before this run?") is answered by grepping a single file. Global-user scope would split the record across machines and make audit-reconstruction brittle.

## User Attestation Protocol

Required fields for every attestation event, captured at the moment the user signs DISCOVERY-LICENSE-NOTICE.md:

- **Timestamp** (ISO-8601 UTC): records when the user signed, not when the subagent was spawned.
- **Client IP**: captured from the user's environment. The user may set `AGENTBLOC_USER_IP` in `.env` for a stable value; otherwise the subagent captures the IP of the outbound request at attestation time.
- **Jurisdiction** (ISO-3166 alpha-2): the user states this explicitly in the opt-in prompt. The subagent does not infer jurisdiction from the IP; IP-based inference is unreliable and surfaces no warning when wrong.
- **Scope**: `service_slug` + ToS URL + ToS excerpt SHA256. These three fields bind the attestation to the exact ToS text the user read.

Attestation text template (copy-paste from DISCOVERY-LICENSE-NOTICE.md User Attestation section into the `attestation` field of the OPT_IN_LEDGER.jsonl line). The ledger line IS the record of attestation; Claude NEVER launches the browser session before the attestation line has been appended to the ledger (D-37 approval gate). If the append fails (filesystem error, permission denied), the subagent halts and returns the error to the main session rather than launching without the record.

## Tool-Provider Disclaimer

Copy-paste-ready boilerplate block. This exact text is reused in every DISCOVERY-REPORT.md header (the `discovery-report-schema.md` reference pins this obligation).

`AgentBloc is a general-purpose research tool. The user is solely responsible for lawful use. AgentBloc takes no position on whether any specific Discovery run is lawful in the user's jurisdiction.`

This disclaimer is NOT a waiver of the user's obligations; it is a statement of AgentBloc's posture as a tool-provider. The user's attestation inside DISCOVERY-LICENSE-NOTICE.md is the legal primary document. The disclaimer is defensive: it makes clear that the tool enforces the gates documented in this file and the deny-list documented in `browser-stack.md`, but does not and cannot make a legal determination on the user's behalf.

Downstream use: the Phase 12 Deploy Pipeline reads DISCOVERY-REPORT.md files and propagates the tool-provider disclaimer into the DEPLOY-REPORT.md header that documents the resulting agent team. The disclaimer travels with every artifact that was produced by a browser-fallback discovery run; deleting the disclaimer from a report is a policy violation, not a cosmetic edit.

Boundary with product marketing copy: nothing in AgentBloc's README, SKILL.md, or example walkthroughs should contradict the disclaimer by implying that AgentBloc performs any legal determination. Tool-surface prose calls this out consistently: AgentBloc enforces gates; the user owns the determination.

## Jurisdictional Red Flags

Auto-halt conditions. When any one of these triggers, the subagent emits DISCOVERY-BLOCKED-REPORT.md and does NOT launch a browser session, regardless of whether a prior attestation was signed.

- **TOS-RED classification**: the ToS explicitly prohibits automated access in a prohibitive context. Auto-triggers a Posture-C-style halt per D-49 in `browser-stack.md`.
- **Regulated verticals WITHOUT documented API access**: healthcare (HIPAA in the US), banking (BSA / AML in the US, PSD2 in the EU), insurance (state-by-state licensing in the US, IDD in the EU), education (FERPA in the US). Halt and surface a targeted question to the user: "This service is in a regulated vertical; did the user verify a documented API path for this integration, or does the user have explicit counsel sign-off to proceed via browser fallback?"
- **Non-US user declaration + US service with TOS-AMBER or TOS-RED**: EU / DE / BR / UK users scraping US services are NOT protected by the Van Buren narrow reading of CFAA (which applies in US courts). Surface an additional warning before opt-in: "Your declared jurisdiction is outside the US; the US court narrow-reading of CFAA does not protect you from US-jurisdiction civil exposure."
- **ToS explicitly prohibits "artificial intelligence" or "machine" access**: auto-classify TOS-RED regardless of other signals; many 2026-era ToS updates add these terms specifically to bar AI-agent automation, and the prohibitive intent is unambiguous.
- **User declines jurisdiction declaration**: if the user refuses to state a jurisdiction at attestation, the subagent cannot surface the matching row in the Variance Matrix. Halt and emit DISCOVERY-BLOCKED-REPORT.md citing missing jurisdiction declaration; do not fall back to an IP-inferred value.
- **Mismatch between declared jurisdiction and attestation client IP country**: surface a warning (not an auto-halt) before launch. The user may legitimately be in one jurisdiction while the client IP geolocates elsewhere (VPN, traveling, employer network); the warning gives the user a chance to re-declare.

**Red-flag notes:**

- Every auto-halt writes a DISCOVERY-BLOCKED-REPORT.md that names which red flag triggered. The main session surfaces the reason to the user; the user may re-scope the discovery target (different service, different account) and attempt again with a fresh attestation.
- Red flags compound: a non-US user declaring US jurisdiction for a TOS-RED US service hits both the TOS-RED auto-halt AND the non-US-user warning. The blocked report cites every triggered flag so the user sees the full picture.

## Quick Reference

- **Five jurisdictions documented**: US (CFAA + DMCA), UK (CMA + CPS), EU (GDPR), DE (BDSG section 202a), BR (LGPD). Each row names relevant law, broadest interpretation, safe-harbor, and highest-risk failure mode.
- **Attestation required before browser launch**: DISCOVERY-LICENSE-NOTICE.md signed plus OPT_IN_LEDGER.jsonl line appended. Claude never launches a session without both records in place.
- **Ledger is append-only**: corrections require a second entry with `corrects_entry` field; the original line is never edited or deleted (GDPR Article 30 immutable audit trail).
- **DISCOVERY-LICENSE-NOTICE.md committed per service**: lives at `.agentbloc/discovery/<service-slug>/`, tracked in git, carries the SHA256-pinned ToS excerpt.
- **Tool-provider disclaimer in every DISCOVERY-REPORT.md header**: AgentBloc takes no position on lawfulness; the user attests and the user owns the legal determination.
- **Auto-halt on TOS-RED**: any prohibitive keyword in the fetched ToS excerpt maps to DISCOVERY-BLOCKED-REPORT.md; no session launch, no retry, no circumvention. Jurisdictional Red Flags (regulated verticals, non-US user + US TOS-AMBER/RED, explicit AI-ban keywords) trigger the same halt.
