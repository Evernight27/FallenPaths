# Per-limb muscle fatigue (Phase 2)

Local exertion pools per fighting limb — **not** composure (mental readiness), **not** whole-body breath burst, **not** tissue injury J pools.

**Status:** **Shipped** — `FEATURE_MUSCLE_GROUP_FATIGUE` default **on** (Expand MXf, 2026-07).

**Parent:** [`COMPOSURE_PLAN.md`](COMPOSURE_PLAN.md) (archive; composure shipped) · stub [`../COMPOSURE_PLAN.md`](../COMPOSURE_PLAN.md) · [`LIVE_PATHS#muscle-fatigue-phase-2`](../LIVE_PATHS.md#muscle-fatigue-phase-2) · [`SHIP_PLAN` §9c](../SHIP_PLAN.md#combat-expand-registry).

---

## When to implement

| Gate | Requirement |
|------|-------------|
| **Composure rework** | ✅ Shipped — do not block on muscle fatigue |
| **Breath + fight exhaustion (MXm / MS-L7)** | ✅ Shipped — muscle fatigue **layers on top**, does not replace |
| EA / Phase 0 | Muscle fatigue **shipped** (Expand MXf, flag default on) |
| **Expand PR** | One row per PR: flag + harness `_run_muscle_fatigue_*` + LIVE_PATHS line ([`PLANNING#harness-and-flags`](../PLANNING.md#harness-and-flags)) |
| **Suggested timing** | Post–Camp-5 Expand, **after** composure/breath soak stable · optional tie-in with tier-4.4 footwork feel pass — not before |

**Do not implement** during maintain-only composure PRs. Pick explicitly from Expand stream when local limb degradation is the next combat-feel priority.

---

## Four-layer exertion model (do not conflate)

| Layer | Key / field | Range | Refill | Owns |
|-------|-------------|-------|--------|------|
| **Composure** | `gauge` (combat dict) · `campaign_composure` (entity) | 0–100 | WAITING 25/s · RECOVERING 8/s · camp rest | Mental readiness, wind-up quality, parry scaling |
| **Breath** | `breath` / `stamina` (combat dict) | 0 → `effective_stamina_max` | PCr refill in WAITING (`CombatExhaustion`) | Burst exertion bar (`Brth` UI) |
| **Fight exhaustion** | `exhaustion` (combat dict) | 0–1 | Slow decay in WAITING | Whole-fight performance mult, MS-L7 tunnel |
| **Muscle fatigue (Phase 2)** | `muscle_fatigue` dict on combatant (+ optional entity persist) | 0–1 per limb | Limb-specific recovery (TBD) | Strike power/speed on **that limb**; footwork on legs |

**Separate from injury:** `CombatLayerTissue` / `tissue_energy_*_j` track **damage capacity**, not reversible fight fatigue.

---

## Scope (Phase 2 MVP)

### Limb keys (align with `BodyPartConstants`)

Initial pools — one float per part, not sub-muscle anatomy:

- `right_arm`, `left_arm` — strike / parry / bind load from `dominant_hand` + move profile
- `right_leg`, `left_leg` — footwork, formation lane steps, dodge weight transfer

Chest/head: **out of scope** for MVP unless a Expand row explicitly adds posture/core fatigue.

### Production touchpoints (implement in order)

1. **Flag + stub** — `CombatMuscleFatigue.gd` · `FEATURE_MUSCLE_GROUP_FATIGUE` (default **on**) ✅
2. **Combatant dict** — `muscle_fatigue: { part: float }` seeded at `CombatManager.register` / `start()` ✅
3. **Spend on exertion** — breath spend (attack/parry) + formation proxy via `CombatFormationFlow` ✅
4. **Read modifiers** — `apply_attacker_wind_up_mult` in `AttackWindUpStarter` ✅
5. **Entity persist** — `CoreEntity.muscle_fatigue` · save/load · camp clear ✅
6. **Harness** — `CombatRegressionHarnessMuscleFatigueTail` ✅

### Explicit non-goals (Phase 2 MVP)

- Replacing or merging into `gauge` / composure
- Replacing `exhaustion` or `breath` whole-body tracks
- Sub-muscle groups (biceps vs triceps) — use limb keys only
- Campaign afflictions for muscle fatigue until persist design is playtested

---

## Module ownership

| Module | Role |
|--------|------|
| `combat/CombatMuscleFatigue.gd` | Feature gate, seed, spend, read mults (Phase 2 logic lives here) |
| `combat/CombatExhaustion.gd` | Whole-body breath + exhaustion only — call muscle hook after breath spend when flag on |
| `combat/AttackWindUpStarter.gd` | Wind-up / composure — **no** muscle cost here; optional read mult for quality when flag on |
| `weapon/WeaponConstants.gd` | Dominant/off hand, two-handed → which limb keys receive spend |
| `core/CoreEntity.gd` | Optional `muscle_fatigue` persist (Phase 2b) |
| `harness/CombatHarnessComposureSeeds.gd` | Composure harness seeds only — muscle fatigue uses separate harness constants |

---

## Expand registry row

Add to [`SHIP_PLAN §9c`](../SHIP_PLAN.md#combat-expand-registry) **Phase 4 / cognition feel** bucket:

**MXf — per-limb muscle fatigue:** `FEATURE_MUSCLE_GROUP_FATIGUE` · `CombatMuscleFatigue` · harness `_run_muscle_fatigue_*` · LIVE_PATHS [#muscle-fatigue-phase-2](../LIVE_PATHS.md#muscle-fatigue-phase-2).

---

## Acceptance (when implemented)

- Flag on (production default): behavior per rows above; harness `_run_muscle_fatigue_flag_off_*` verifies override-off is inert
- Phase 0 regression green with flag default on (2026-07 soak)
- AGENTS four-layer table updated; no new inline `muscle_fatigue` reads outside `CombatMuscleFatigue`

---

## Balance soak (headless proxy)

**Harness:** `_run_muscle_fatigue_balance_exchange_proxy` — 8× medium breath spend → dominant-limb fatigue in **[0.15, 0.95]**; 4s WAITING recovery must drop fatigue measurably. Tune `MUSCLE_FATIGUE_EXERTION_PER_BREATH_POINT` / `MUSCLE_FATIGUE_RECOVERY_RATE` in `CombatConstantsStamina.gd` if proxy fails after flag-on soak.

**F5 playtest:** optional **`mxf_*`** tracks in `CombatD001TrackSpecs` (gated on ` · Msc ` in paste). D-001 sanity fixtures `fixture_mxf_good` / `fixture_mxf_bad`. Not required for Camp close-out (WF-M3 + `camp_*` only).
