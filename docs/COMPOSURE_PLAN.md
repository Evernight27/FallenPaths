# Composure — shipped

Design history: [`archive/COMPOSURE_PLAN.md`](archive/COMPOSURE_PLAN.md).

**Live APIs:** [`AGENTS_API`](AGENTS_API.md#canonical-apis) composure rows · fill/cost in `CombatConstants` / `AttackWindUpStarter._resolve_composure_cost` · campaign sync `world/CampaignComposureSync.gd`.

**LIVE_PATHS:** [`#composure-rework`](LIVE_PATHS.md#composure-rework).

<a id="3c--cost-deduction-at-wind-up-start"></a>

## Cost deduction (canonical)

Cost table and wind-up deduction live in production: `AttackWindUpStarter._resolve_composure_cost(move_id)`. Historical step write-up: [`archive/COMPOSURE_PLAN.md#3c--cost-deduction-at-wind-up-start`](archive/COMPOSURE_PLAN.md#3c--cost-deduction-at-wind-up-start).
