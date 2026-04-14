# Data Classification

> Security reference loaded by SKILL.md during Interview Phase (category 5: Data Classification).

## Table of Contents

- [When This Applies](#when-this-applies)
- [Classification Categories](#classification-categories)
- [Auto-Detection Rules](#auto-detection-rules)
- [Activation Logic](#activation-logic)
- [Retention Schedule](#retention-schedule)
- [Deletion Workflow](#deletion-workflow)
- [Regime Conflict Resolution](#regime-conflict-resolution)
- [Compliance Activation Matrix](#compliance-activation-matrix)

## When This Applies

Claude reads this file during the Interview Phase (category 5: Data Classification) to determine what data the user's workflow handles. The classification result activates the corresponding compliance regime and shapes every subsequent phase: Design (blast-radius scoring), Integration (credential scoping), and Deployment (governance.yaml generation).

## Classification Categories

| Category | Definition | Examples | Regime Triggered |
|----------|-----------|----------|-----------------|
| PII (Personal) | Data identifying a natural person (GDPR Art. 4) | Names, emails, phone numbers, addresses, DNI/NIE, date of birth | GDPR (if EU) |
| PHI (Health) | Health data linked to an individual | Patient records, diagnoses, prescriptions, medical history, health insurance IDs | GDPR + HIPAA |
| Financial | Payment or banking data | Credit card numbers, IBAN, bank accounts, CVV, invoices with payment details | GDPR + PCI |
| Public | Non-identifying business data | Product SKUs, public pricing, schedules, stock levels, published content | None |

A single workflow can handle multiple categories (PII, PHI, financial, public). The highest-sensitivity category determines the baseline compliance regime.

## Auto-Detection Rules

During the interview, Claude scans the user's workflow description for data signals. Detection is bilingual (English/Spanish):

**PII Signals (High Confidence):**

| Signal Pattern | Language |
|---------------|----------|
| nombre, name, apellido, surname | ES / EN |
| email, correo, e-mail | ES / EN |
| telefono, phone, mobile | ES / EN |
| direccion, address, domicilio | ES / EN |
| DNI, NIE, passport, pasaporte | ES / EN |
| fecha de nacimiento, date of birth, DOB | ES / EN |

**PII Signals (Medium Confidence):**

| Signal Pattern | Language |
|---------------|----------|
| IP, cookie, device ID | Universal |
| location, ubicacion, GPS | ES / EN |
| foto, photo, image of person | ES / EN |

**PHI Signals:**

| Signal Pattern | Language |
|---------------|----------|
| paciente, patient | ES / EN |
| diagnostico, diagnosis | ES / EN |
| prescripcion, prescription | ES / EN |
| historia clinica, medical record, health record | ES / EN |
| seguro medico, health insurance | ES / EN |

**Financial Signals:**

| Signal Pattern | Language |
|---------------|----------|
| tarjeta, card number, PAN, credit card | ES / EN |
| IBAN, cuenta bancaria, bank account | ES / EN |
| CVV, CVC, security code | ES / EN |
| factura con pago, invoice with payment | ES / EN |

## Activation Logic

**Primary engine (auto-detection):** If ANY keyword signal is detected during the interview, the corresponding regime activates automatically. Low threshold: a false positive is better than a missed classification.

**Region default (baseline):** If the client operates in the EU (detected from conversation language, business region, or explicit statement), GDPR is the non-negotiable floor. Do not ask "do you need GDPR?" That delegates a legal decision the user cannot make. The skill does the work.

**Override (escape hatch only):** The user can deactivate a detection only by providing an explanation (e.g., "this is synthetic test data, not real personal data"). The override can only deactivate a regime, never activate one. If there is a signal, Claude activates automatically.

**Claude's behavior:** "Your workflow handles personal data (emails, names). This activates GDPR compliance patterns for the deployment." Matter-of-fact, not asking permission.

## Retention Schedule

Default retention periods by data class, with regime-specific overrides:

| Data Class | Default Retention | GDPR Override | HIPAA Override | PCI Override |
|------------|-------------------|---------------|----------------|--------------|
| PII | 1 year after last processing | Art. 5(1)(e): no longer than necessary | N/A | N/A |
| PHI | 1 year after last processing | Art. 5(1)(e) | 6 years minimum | N/A |
| Financial | 1 year after last processing | Art. 5(1)(e) | N/A | 1 year after processing |
| Public | No restriction | N/A | N/A | N/A |
| Audit logs | 90 days (configurable) | Keep until retention period expires | 6 years | 1 year |

Retention periods are configured in governance.yaml and enforced by a scheduled cleanup agent.

## Deletion Workflow

When a data subject exercises their right to erasure (GDPR Art. 17), follow these steps:

1. **Receive request:** Log a DSAR (Data Subject Access Request) with a unique correlation_id. Record the request timestamp.
2. **Verify identity:** Confirm the requester is the data subject or their authorized representative.
3. **Enumerate stores:** List all `.agentbloc/state/` files containing the subject's data. Search by known identifiers (email hash, account ID hash).
4. **Delete data:** Remove the subject's records from state files. In audit logs, retain only hash references (no raw PII). Delete any cached or temporary copies.
5. **Confirm deletion:** Send confirmation to the requester via Telegram, referencing the correlation_id.
6. **Notify downstream:** If the subject's data was shared with external services (via MCP integrations), notify those services of the erasure request.

**Response deadline:** 30 days from receipt of verified request.

**Exceptions:** Erasure can be refused when data retention is required by legal obligation or for defense of legal claims. Log the exception with the reason in the audit trail.

## Regime Conflict Resolution

When multiple compliance regimes apply simultaneously (e.g., GDPR + HIPAA for health data of EU patients):

**Retention conflicts:** The most restrictive retention period wins. If GDPR says "delete when no longer necessary" and HIPAA says "retain for 6 years," retain for 6 years but revoke all access immediately upon erasure request (soft delete).

**Erasure conflicts:** When an erasure request conflicts with a retention obligation:
- Revoke all access to the data immediately (soft delete)
- Complete physical deletion when the retention period expires
- Log the conflict, the resolution, and the expected physical deletion date in the audit trail

**General rule:** When in doubt, apply the more restrictive requirement. Document the conflict resolution in governance.yaml under the `compliance` section.

## Compliance Activation Matrix

Summary of which signals trigger which regimes:

| Signal Detected | Data Class | Regime Activated | Confidence |
|----------------|------------|-----------------|------------|
| Names, emails, addresses, phone numbers | PII | GDPR (if EU) | HIGH |
| Patient records, diagnoses, prescriptions | PHI | GDPR + HIPAA | HIGH |
| Credit card numbers, IBAN, bank accounts | Financial | GDPR + PCI | HIGH |
| Product SKUs, public pricing, schedules | Public | None | HIGH |
| IP addresses, device IDs, cookies | PII (technical) | GDPR (if EU) | MEDIUM |
| Photos of people, biometric data | PII (special category) | GDPR (if EU) | MEDIUM |

When a regime activates, Claude loads the corresponding reference file (references/gdpr-patterns.md) for detailed compliance patterns during Design and Deployment phases.
