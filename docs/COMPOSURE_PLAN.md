# Composure — shipped

**Live APIs:** [`AGENTS_API`](AGENTS_API.md#canonical-apis) composure rows · gauge 0–100 (`DataKeys.COMBATANT_GAUGE`) · campaign sync `world/CampaignComposureSync.gd`.

**LIVE_PATHS:** [`#composure-rework`](LIVE_PATHS.md#composure-rework).

<a id="3c--cost-deduction-at-wind-up-start"></a>

## Gauge model (shipped)

`gauge` is **event-driven** — no continuous fill, no wind-up cost, no quality/parry scaling:

- **100** on `EVENT_ACTION_READY` (`CombatEventDispatch.handle_action_ready`).
- **0** at wind-up start (`CombatStateHandlers.process_wind_up` / `AttackWindUpStarter`), medical wind-up, recovery, form switch, flee/yield, attack resolve, counter-tempo spend.
- **Cowering idle** fills at **0.5/s** (`CombatStateHandlers.process_cowering_idle`).
- **Thresholds:** counter-tempo ready ≥ `COUNTER_TEMPO_GAUGE_THRESHOLD` (50) · AI/action-list gate `< GAUGE_FULL_THRESHOLD` (99).
- **Campaign sync:** `CampaignComposureSync` persists gauge onto party `CoreEntity` between fights.
