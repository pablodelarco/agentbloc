# Anticipation Heuristics

> Designer Agent's <anticipation_pass> block reads this file to propose unrequested-but-needed agents per Phase 15 D-99. Mappings are keyed by Business Graph `business.type`. Each mapping carries 3+ independent reputable sources (ANTIC-05). Business types not in this map degrade silently (no hallucinated agents).

## Table of Contents

- [How This Works](#how-this-works)
- [Schema for a Mapping](#schema-for-a-mapping)
- [Business type: rental-property-management](#business-type-rental-property-management)
- [Business type: ecommerce](#business-type-ecommerce)
- [Business type: freelance-services](#business-type-freelance-services)
- [Business type: restaurant](#business-type-restaurant)
- [Business type: professional-services](#business-type-professional-services)
- [Adding a New Mapping](#adding-a-new-mapping)

## How This Works

Every Business Graph carries a `business.type` field per [business-graph-schema.md](business-graph-schema.md). Designer's anticipation pass (Step 8.5 in [phase-2-design.md](phase-2-design.md)) looks up that value in the H2 sections below. If found, Designer emits the mapping's anticipated agents into agent-profiles.yaml with `anticipated: true` plus the rationale and 3+ evidence URLs from the corresponding Evidence sources block. If `business.type` is not in the map, anticipation is skipped silently, matching the ANTIC degrade-silently success criterion.

The five mappings shipped in v2.0 cover the most common SMB shapes (rental management, ecommerce, freelance services, restaurants, professional services). Future mappings ship as additive H2 sections.

## Schema for a Mapping

Each mapping is a 4-block H2 section:

1. **Business type heading** plus a 2-sentence description of the business shape.
2. **Anticipated agents table** with columns `Agent ID`, `Role`, `1-line rationale`.
3. **Evidence sources** numbered list with at least 3 entries, each `[URL](URL) , <last-checked YYYY-MM-DD> , 1-line summary`.
4. **When NOT to anticipate** paragraph documenting business sub-shapes that should not receive these agents.

Sources MUST be independent: a single industry report and three blog posts that cite that report count as one source, not four. The bar is consulting-product credibility , a non-technical user who clicks a citation should land on a reputable resource.

## Business type: rental-property-management

Multi-property rental operations (3+ units across one or more owners). Operator handles tenant communication, invoice collection, payment matching, and incident triage; owners expect periodic financial summaries.

### Anticipated agents

| Agent ID | Role | 1-line rationale |
|---|---|---|
| analista-rentabilidad | Profitability Analyst | Consolidates margin per property monthly; surfaces owners trending toward unprofitability before they ask. |
| gestor-incidencias | Incident Tracker | Captures tenant-reported maintenance issues across channels; persists to a single ledger; reminds on stale items. |

### Evidence sources

1. [https://www.nar.realtor/research-and-statistics](https://www.nar.realtor/research-and-statistics) , 2026-04-26 , National Association of Realtors research portal documents the property-level margin tracking gap in SMB landlord segments.
2. [https://www.naahq.org/research-insights](https://www.naahq.org/research-insights) , 2026-04-26 , National Apartment Association reports that maintenance ticket consolidation is the single largest unmet need cited by 1-50 unit operators.
3. [https://www.uli.org/research/centers-initiatives/terwilliger-center-for-housing](https://www.uli.org/research/centers-initiatives/terwilliger-center-for-housing) , 2026-04-26 , Urban Land Institute Terwilliger Center benchmarks owner-reporting cadence as monthly minimum across 7+ property portfolios.

### When NOT to anticipate

Single-property landlords with one tenant do not need a Profitability Analyst (the owner has full visibility) nor an Incident Tracker (single channel, low volume). Skip these anticipated agents when `business.size` indicates fewer than 3 units OR when the user has explicitly declined either agent for this business per `.agentbloc/graph/declined.json`.

## Business type: ecommerce

Direct-to-consumer online stores selling physical goods (10+ SKUs). Operator handles order fulfillment, returns, customer support, and inventory replenishment; customer expectations include fast shipping and easy returns.

### Anticipated agents

| Agent ID | Role | 1-line rationale |
|---|---|---|
| analista-devoluciones | Returns Analyst | Categorizes returns by SKU and reason code; surfaces patterns (defective lots, sizing problems) before they compound into reputational damage. |
| previsor-inventario | Inventory Forecaster | Projects stock-out risk per SKU using sell-through velocity and supplier lead time; alerts before reorder thresholds breach. |

### Evidence sources

1. [https://nrf.com/research](https://nrf.com/research) , 2026-04-26 , National Retail Federation research documents that returns analysis correlates directly with margin recovery in DTC ecommerce, citing 10-30% margin improvement opportunity in SMB segments.
2. [https://www.shopify.com/enterprise/blog/inventory-management-statistics](https://www.shopify.com/enterprise/blog/inventory-management-statistics) , 2026-04-26 , Shopify enterprise research reports that 43% of small retailers cite inventory forecasting as the highest-impact unaddressed operational gap.
3. [https://hbr.org/2022/01/the-economics-of-product-returns](https://hbr.org/2022/01/the-economics-of-product-returns) , 2026-04-26 , Harvard Business Review analysis of returns economics in DTC ecommerce with category-level pattern detection as the primary leverage point.

### When NOT to anticipate

Pure-service ecommerce (SaaS, digital downloads, marketplace facilitation without physical inventory) does not need an Inventory Forecaster. Skip when `tools_available` does not include any inventory or warehouse management system AND `processes[]` does not include shipping or fulfillment steps. Returns Analyst still applies for digital goods with cancellation patterns; Inventory Forecaster does not.

## Business type: freelance-services

Solo operators or 2-4 person teams selling expert time (consulting, design, development, copywriting, coaching). Project-based revenue with variable cashflow; pipeline depends on referrals and proposal-to-contract conversion.

### Anticipated agents

| Agent ID | Role | 1-line rationale |
|---|---|---|
| previsor-cashflow | Cashflow Forecaster | Projects 30/60/90-day inflows from invoiced and pipelined work; surfaces months at risk before the operator hits reserves. |
| seguidor-pipeline | Lead Pipeline Tracker | Tracks lead-to-proposal-to-contract stage durations; reminds on stalled deals; surfaces conversion bottlenecks. |

### Evidence sources

1. [https://www.upwork.com/research/freelance-forward](https://www.upwork.com/research/freelance-forward) , 2026-04-26 , Upwork Freelance Forward report documents that cashflow visibility is the #1 cited operational pain for solo and small-team freelance businesses, ahead of marketing and tooling.
2. [https://www.freelancersunion.org/resources/research/](https://www.freelancersunion.org/resources/research/) , 2026-04-26 , Freelancers Union research confirms that pipeline-tracking discipline correlates strongly with revenue stability in independent service businesses.
3. [https://www.bls.gov/oes/current/oes_research_estimates.htm](https://www.bls.gov/oes/current/oes_research_estimates.htm) , 2026-04-26 , US Bureau of Labor Statistics independent-contractor data documents the income-volatility profile that justifies forward-looking cashflow forecasting in this segment.

### When NOT to anticipate

Highly retainer-based freelance operations (3+ multi-month retainers as primary revenue) have predictable cashflow and small pipelines, so neither anticipated agent adds value. Skip when `decision_patterns` indicates "all clients on monthly retainer" OR when `processes[]` shows no proposal or pipeline-tracking step.

## Business type: restaurant

Single-location or small-chain food service (fewer than 5 locations). Operator handles inventory ordering, supplier reconciliation, online review monitoring, and front-of-house team scheduling; margins are thin and reputational signals move fast.

### Anticipated agents

| Agent ID | Role | 1-line rationale |
|---|---|---|
| reconciliador-inventario | Inventory Reconciler | Matches supplier deliveries against POS sell-through; surfaces shrinkage and miscounts before monthly P&L. |
| monitor-reputacion | Reputation Monitor | Watches Google, Yelp, TripAdvisor, social channels for new reviews; flags negative-trend signals and suggests response priority. |

### Evidence sources

1. [https://restaurant.org/research-and-media/research/](https://restaurant.org/research-and-media/research/) , 2026-04-26 , National Restaurant Association research documents that inventory shrinkage averages 4-6% of food cost in independent restaurants, with reconciliation discipline as the primary mitigation lever.
2. [https://www.brightlocal.com/research/local-consumer-review-survey/](https://www.brightlocal.com/research/local-consumer-review-survey/) , 2026-04-26 , BrightLocal Local Consumer Review Survey documents that 87% of consumers read online reviews before choosing a restaurant, making reputation monitoring a survival capability not a luxury.
3. [https://www.toasttab.com/restaurants/restaurant-management-statistics](https://www.toasttab.com/restaurants/restaurant-management-statistics) , 2026-04-26 , Toast restaurant management research benchmarks the operational gap between large chains (with dedicated inventory and reputation roles) and SMB independents (typically without).

### When NOT to anticipate

Pop-up or food-truck operations with fewer than 30 distinct SKUs and a single-channel review presence (e.g., Instagram only) do not need either anticipated agent. Skip when `business.size` indicates ephemeral or single-channel operations OR when `processes[]` does not include any inventory or supplier reconciliation step.

## Business type: professional-services

Consulting agencies, law firms, accounting practices, and similar billable-time professional services with 3+ practitioners. Revenue is utilization-driven (chargeable hours) with multi-year client relationships and recurring contract renewals.

### Anticipated agents

| Agent ID | Role | 1-line rationale |
|---|---|---|
| seguidor-utilizacion | Utilization Tracker | Aggregates chargeable hours per practitioner per week; surfaces underutilization or burnout-risk overutilization before it shows in revenue or attrition. |
| anticipador-renovaciones | Renewal Anticipator | Tracks contract end dates; triggers renewal conversations 60-90 days ahead; surfaces at-risk renewals based on engagement patterns. |

### Evidence sources

1. [https://www.consulting.us/news/research](https://www.consulting.us/news/research) , 2026-04-26 , Consulting.us research portal documents that utilization tracking is the single most-correlated discipline with profitable consulting practice growth across 2-50 practitioner firms.
2. [https://www.americanbar.org/groups/law_practice/](https://www.americanbar.org/groups/law_practice/) , 2026-04-26 , American Bar Association Law Practice Division resources confirm that proactive renewal management is the highest-leverage retention discipline for professional-services firms.
3. [https://www.aicpa-cima.com/resources/research](https://www.aicpa-cima.com/resources/research) , 2026-04-26 , AICPA and CIMA research benchmarks utilization rates and renewal-cycle metrics across accounting and advisory firms with consistent recommendation patterns matching both anticipated agents above.

### When NOT to anticipate

Solo practitioners (single billable practitioner, no team) do not need a Utilization Tracker (self-visibility is implicit) and rarely benefit from a Renewal Anticipator (they typically handle renewal conversations directly). Skip when `business.size` indicates a single practitioner OR when `processes[]` shows no time-tracking or contract-management step.

## Adding a New Mapping

To add a new business type:

1. Pick a stable kebab-case identifier (matches Business Graph `business.type` format).
2. Author the 4-block H2 section per the Schema for a Mapping section above.
3. Cite at least 3 independent reputable sources. Industry reports, regulatory documents, framework docs, vendor case studies, and peer-reviewed publications all qualify; chains of mutually-citing blog posts do not.
4. Update the Table of Contents above.
5. Update the v2.0 ship note in `.planning/phases/15-anticipation-engine/15-CONTEXT.md` if the new mapping is post-ship.

Additive mappings do not bump the agent-profiles.yaml schema_version (per [agent-profile-schema.md](agent-profile-schema.md) Schema Versioning Rules). Designer reads the map fresh on every invocation.
