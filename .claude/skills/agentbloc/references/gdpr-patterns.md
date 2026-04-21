# GDPR Compliance Patterns

> Security reference loaded by SKILL.md when data classification identifies EU personal data, health data, or financial data. Includes HIPAA and PCI ready patterns activated by data classification.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Art. 17 Right to Erasure](#art-17-right-to-erasure)
- [Art. 15 Data Subject Access Request](#art-15-data-subject-access-request)
- [Art. 33 Breach Notification](#art-33-breach-notification)
- [Art. 6 Consent and Legal Basis Logging](#art-6-consent-and-legal-basis-logging)
- [DPO Designation Guidance](#dpo-designation-guidance)
- [DPA Template](#dpa-template)
- [HIPAA Ready Patterns](#hipaa-ready-patterns)
- [PCI Ready Patterns](#pci-ready-patterns)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file when data classification (references/data-classification.md) identifies EU personal data, health data, or financial data during the Interview phase. GDPR patterns activate by default for EU operations -- the skill detects and activates automatically without asking the user. HIPAA and PCI sections activate only when data classification identifies PHI or financial card data respectively.

This file provides operational guidance for generating compliance artifacts. AgentBloc generates templates and workflows; the client reviews with legal counsel before implementation.

## Art. 17 Right to Erasure

This pattern implements the GDPR right to erasure workflow. Generated as part of `governance.yaml` when GDPR is activated.

### Erasure Workflow Steps

1. **Receive erasure request:** Log the request as a DSAR with a correlation_id in the audit trail. Record the timestamp and requester identity
2. **Verify requester identity:** Match the requester against known data subjects in `.agentbloc/state/` files. If identity cannot be verified, request additional verification before proceeding
3. **Enumerate data stores:** List all `.agentbloc/state/` files containing the subject's data. Include any MCP-accessible external stores where data was written
4. **Delete data:** Remove subject records from state files. In audit logs, retain hash-only references (do not delete audit entries -- replace PII with `hash:{8-char-sha256}` values)
5. **Confirm deletion:** Send confirmation via Telegram to the requester's thread
6. **Notify downstream:** If data was shared with external services via MCP, send deletion notification to each service
7. **Log completion:** Record the erasure completion in the audit trail with correlation_id

### Deadlines and Exceptions

- **Response deadline:** 30 days from request (extendable to 90 days with justification, but the requester must be notified of the extension within 30 days)
- **Exceptions:** Legal obligation retention, defense of legal claims, public health, archiving in public interest, freedom of expression

### governance.yaml Erasure Block

```yaml
gdpr:
  erasure_workflow:
    steps:
      - receive_request: "Log DSAR with correlation_id, verify requester identity"
      - enumerate_stores: "List all .agentbloc/state/ files containing subject data"
      - delete_data: "Remove subject records from state files, audit logs retain hash only"
      - confirm_deletion: "Send confirmation via Telegram to requester thread"
      - notify_downstream: "If data was shared with external services, notify them"
    response_deadline_days: 30
    exceptions:
      - legal_obligation
      - defense_of_claims
```

## Art. 15 Data Subject Access Request

This pattern implements the GDPR right of access. When a data subject requests their data, the agent team compiles and exports all held information.

### DSAR Workflow Steps

1. **Receive DSAR:** Log the request with a correlation_id in the audit trail
2. **Verify identity:** Confirm the requester is the data subject or an authorized representative
3. **Enumerate data:** Scan all `.agentbloc/state/` files for records associated with the subject
4. **Compile export:** Generate a JSON file containing all data points with their processing purposes, categories, retention periods, and any third parties the data was shared with
5. **Deliver export:** Send the JSON export via a secure channel (Telegram DM or email attachment)
6. **Log completion:** Record the DSAR fulfillment in the audit trail

### Response Rules

- **Deadline:** 30 days from verified request
- **Format:** JSON file containing all data held about the subject, structured by processing purpose
- **Cost:** Free of charge for the first request; a reasonable fee may be charged for manifestly unfounded or excessive repetitive requests
- **Scope:** All data held in `.agentbloc/state/`, processed IDs, mappings, and any cached references

## Art. 33 Breach Notification

This pattern implements the 72-hour breach notification requirement. AgentBloc generates a breach notification template as part of the incident response artifacts.

### Breach Notification Template

The following fields are populated when a breach is detected:

| Field | Content |
|-------|---------|
| **Nature of breach** | What happened, how many records affected, what data types exposed |
| **Likely consequences** | Identity theft risk, financial exposure, reputational harm assessment |
| **Measures taken** | Kill switch activated, credentials rotated, affected users notified, MCP connections severed |
| **DPO contact** | Name, email, phone from governance.yaml gdpr.dpo block |

### Notification Timeline

1. **Discovery:** Breach detected (via audit log anomaly, agent error, or external report)
2. **Assessment (immediate):** Determine scope, affected data categories, number of subjects
3. **Supervisory authority notification (within 72 hours):** Submit notification to the relevant Data Protection Authority using the template above
4. **Affected individuals (without undue delay if high risk):** Notify data subjects directly if the breach poses a high risk to their rights and freedoms
5. **Telegram alert:** Immediate P1 alert to the operations thread with breach summary and correlation_id linking to the relevant audit trail entries

### governance.yaml Breach Block

```yaml
gdpr:
  breach_notification:
    deadline_hours: 72
    notify:
      - supervisory_authority
      - affected_subjects_if_high_risk
    telegram_alert: true
    alert_priority: P1
```

## Art. 6 Consent and Legal Basis Logging

Every data processing activity performed by the agent team is logged with its legal basis. This implements GDPR Article 6 and Article 30 (records of processing activities).

### Processing Activity Record

Each processing activity includes:

- **Purpose:** What the data is processed for (e.g., "invoice collection for client billing")
- **Legal basis:** One of: `consent`, `contract`, `legal_obligation`, `vital_interest`, `public_task`, `legitimate_interest`
- **Data categories:** Specific fields processed (e.g., supplier_name, invoice_amount, due_date)
- **Retention period:** How long the data is kept before deletion

### governance.yaml Processing Activities Block

```yaml
gdpr:
  processing_activities:
    - purpose: "Invoice collection"
      legal_basis: "contract"
      data_categories: ["supplier_name", "invoice_amount", "due_date"]
      retention_days: 365
    - purpose: "Customer communication"
      legal_basis: "legitimate_interest"
      data_categories: ["customer_name", "email"]
      retention_days: 730
```

This block is generated during Deployment (Phase 5) based on the data flows identified in the Interview and Design phases. Each agent's data access is mapped to a processing purpose and legal basis.

## DPO Designation Guidance

AgentBloc generates a Data Protection Officer designation template when the GDPR regime is activated. The client determines whether a DPO is required and fills in the details.

### Decision Tree

1. Is the data controller a public authority or body?
   - **YES:** DPO designation is required under Art. 37
   - **NO:** Continue to question 2

2. Does the core activity involve large-scale, regular, systematic monitoring of individuals?
   - **YES:** DPO designation is required under Art. 37
   - **NO:** Continue to question 3

3. Does the core activity involve large-scale processing of special categories of data (Art. 9) or criminal conviction data?
   - **YES:** DPO designation is required under Art. 37
   - **ALL NO:** DPO designation is recommended but not mandatory

### governance.yaml DPO Block

```yaml
gdpr:
  dpo:
    required: true
    name: "[Client's DPO or external DPO service]"
    email: "[dpo@client.example.com]"
    registered_with: "[Supervisory authority name]"
```

AgentBloc generates this template. The client fills in their DPO details and validates with legal counsel.

## DPA Template

For B2B consulting engagements, a Data Processing Agreement outline is generated when AgentBloc is deployed on behalf of a client. This covers the relationship where the consulting entity operates the agent team (processor) on behalf of the client (controller).

### DPA Outline Sections

1. **Parties:** Controller (client) and Processor (consulting entity operating AgentBloc)
2. **Subject matter and duration:** Description of the processing, duration of the engagement
3. **Nature and purpose:** Automated data processing via AI agent team for [specific business process]
4. **Types of personal data:** Categories identified during data classification (PII, PHI, financial)
5. **Categories of data subjects:** Employees, customers, suppliers, or other subjects identified in interview
6. **Controller obligations:** Provide lawful instructions, ensure legal basis for processing
7. **Processor obligations:**
   - Process data only on documented controller instructions
   - Ensure confidentiality of personnel with access
   - Implement security measures (encryption, access controls, audit logging)
   - Obtain prior written authorization for sub-processors
   - Assist controller with DSAR fulfillment and breach notification
   - Provide audit access to processing activities
8. **Data return/deletion:** On contract termination, return all data to controller and delete processor copies within 30 days

AgentBloc generates this outline during Deployment. Both parties review with legal counsel before signing.

## HIPAA Ready Patterns

These patterns activate only when data classification identifies Protected Health Information (PHI). They are not enabled by default.

### PHI Safeguards

- **Encryption at rest:** All `.agentbloc/state/` files containing PHI are encrypted at the file level. The encryption key is stored as an environment variable, never in the repository
- **Encryption in transit:** All MCP connections use TLS. Agents processing PHI verify TLS certificates before transmitting data
- **Minimum necessary standard:** Each agent accesses only the PHI fields required for its specific task. Agent permissions in `agent.yaml` specify exactly which data fields the agent can read and write

### Business Associate Agreement (BAA)

If a third-party MCP server processes PHI, a Business Associate Agreement is required between the client and the MCP server operator. AgentBloc flags this requirement during Integration Analysis (Phase 3) when:

- The MCP server receives, stores, or transmits PHI
- The service is not covered by an existing BAA

The deployment artifacts include a BAA checklist for each MCP server that handles PHI.

### Audit Requirements

- All PHI access is logged with correlation IDs (see references/audit-logging.md)
- PHI audit logs are retained for a minimum of 6 years per HIPAA requirements
- Override `audit.retention_days` to `2190` (6 years) when HIPAA is activated

### 2025 Security Rule

The HIPAA Security Rule updates (proposed January 2025) remove the distinction between "required" and "addressable" safeguards. All safeguards are now mandatory:

- Encryption of electronic PHI (ePHI) is required, not optional
- Multi-factor authentication for systems accessing ePHI
- Annual security risk assessments including AI system components

## PCI Ready Patterns

These patterns activate only when data classification identifies payment card data (PAN, CVV, cardholder information). They are not enabled by default.

### Tokenization

This pattern implements PCI DSS 4.0 Requirement 3 (Protect Stored Account Data):

- **Never store raw PAN** (Primary Account Number) in `.agentbloc/state/` files or audit logs
- **Use payment provider tokenization:** Stripe tokens, payment gateway tokens, or other provider-issued surrogate values replace raw card numbers
- **If an agent must reference card data:** Use only tokenized references. Raw card numbers never enter the AgentBloc state directory
- **Truncation for display:** Show only last 4 digits when card references appear in Telegram reports

### Agent Restrictions

Any agent processing financial card data is automatically assigned:

- **Blast radius:** Level 3 or higher (write-unrestricted or send-external)
- **Approval gate:** `requires_approval: true` in agent.yaml
- **Scope limitation:** Agent can read tokenized references only; raw PAN access is blocked at the MCP server configuration level

### PCI DSS 4.0 Key Requirements for AI Agents

| Requirement | Implementation |
|-------------|---------------|
| Req. 3: Protect stored data | Tokenization; never store raw PAN |
| Req. 7: Restrict access | Per-agent permissions in agent.yaml; minimum necessary |
| Req. 10: Log and monitor | JSONL audit logging with correlation IDs (see audit-logging.md) |
| Req. 12: Security policies | governance.yaml documents security policies; DPA covers third parties |

## Quick Reference

| Article/Standard | Pattern | governance.yaml Block | Activation Trigger |
|-----------------|---------|----------------------|-------------------|
| Art. 17 (Erasure) | 7-step deletion workflow | `gdpr.erasure_workflow` | DSAR received |
| Art. 15 (DSAR) | Data export as JSON | `gdpr.dsar_workflow` | Access request received |
| Art. 33 (Breach) | 72h notification template | `gdpr.breach_notification` | Breach detected |
| Art. 6 (Legal Basis) | Processing activity records | `gdpr.processing_activities` | All GDPR deployments |
| Art. 37 (DPO) | 3-question decision tree | `gdpr.dpo` | All GDPR deployments |
| DPA | B2B processing agreement outline | N/A (standalone document) | B2B consulting engagements |
| HIPAA | PHI safeguards, BAA flagging, 6-year retention | `audit.retention_days: 2190` | PHI detected in data classification |
| PCI DSS 4.0 | Tokenization, PAN prohibition, agent restrictions | Agent blast radius Level 3+ | Financial card data detected |
