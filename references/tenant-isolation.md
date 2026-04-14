# Tenant Isolation

> Security reference loaded by SKILL.md. Documents single-tenant design for v1.0 and planned multi-tenant patterns for v2.0.

## Purpose

Patterns for multi-client deployments: namespace separation, credential isolation per client, preventing cross-client data access, and audit trail per tenant. In v1.0, tenant isolation is achieved through deployment separation.

## v1.0: Single-Tenant by Design

Each AgentBloc deployment operates as a single-tenant instance. One `.agentbloc/` directory per client, one set of credentials, one `governance.yaml`, one audit log. There is no multi-tenant runtime in v1.0.

For consultants managing multiple clients: deploy a separate AgentBloc instance per client on separate machines or in separate directories. Do not share `.env` files, state directories, or audit logs between clients. Each client deployment is fully isolated at the filesystem and credential level.

This approach eliminates cross-tenant risk by design. No namespace enforcement is needed when there is only one tenant per deployment.

## v2.0 Patterns (Planned)

These patterns are documented for future implementation. v1.0 achieves tenant isolation through deployment separation.

- **Namespace separation:** `.agentbloc/{tenant_id}/` directory structure with per-tenant state, config, and logs
- **Credential isolation:** Separate `.env` per tenant, no shared secrets across tenant boundaries
- **Data access controls:** Agents scoped to their tenant's state directory via path validation in hooks
- **Audit trail per tenant:** Separate audit JSONL files per `tenant_id` with tenant-scoped correlation IDs
- **Cross-tenant prevention:** PreToolUse hooks enforce path boundaries, blocking any file access outside the active tenant's namespace

## When to Revisit

Revisit this file for v2.0 implementation when AgentBloc is deployed in a multi-client SaaS or managed-service context where a single machine hosts multiple client deployments.
