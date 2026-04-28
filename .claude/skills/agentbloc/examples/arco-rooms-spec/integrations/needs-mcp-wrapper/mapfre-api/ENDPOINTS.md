# Minimum-Viable Endpoints — mapfre-api

## Included

| Endpoint | Method | Used by | Purpose | Blast |
|---|---|---|---|---|
| `/v1/policies/{id}` | GET | gestor-documental | Fetch policy details + current month invoice URL | L2 (read external; cached locally) |
| `/v1/claims` | GET | gestor-documental | List active claims (rarely used; informational only) | L1 |

Tool names: `get_policy(policy_id)` and `list_claims()`.

## Excluded (least-privilege)

| Endpoint | Method | Reason |
|---|---|---|
| `/v1/policies` | POST | Create policy — Pablo does manually |
| `/v1/policies/{id}` | PUT/DELETE | Modify/cancel — sensitive; manual only |
| `/v1/claims/{id}` | POST/PUT | File/update claim — Pablo does manually |
| `/v1/payments` | * | Payment endpoints out of scope |

## Authentication

| Property | Value |
|---|---|
| Pattern | api-key |
| Header | `Authorization: Bearer ${MAPFRE_API_KEY}` |
| Required scope | `policies:read`, `claims:read` (per Mapfre's scope strings) |
| Refresh policy | Annual rotation; build session re-requests at portal |

## Rate limits

| Limit | Value | Wrapper response |
|---|---|---|
| Per-account | 1000 reads/day | Cache invoice URL aggressively |
| Burst | 10/sec | Sleep on burst |

Team's nightly read pattern (~30 policies × 1 read = 30 reads/day) is
well under the cap.

## Pagination

`list_claims` paginates with `page` + `per_page` query params (default
20, max 100). Wrapper paginates internally.

## Cross-references

- `README.md`, `BUILD.md`
- `governance/blast-radius.md`
- `governance/audit-trail.md`
