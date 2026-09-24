# Footing & Balance Realism Plan

**Date:** 2026-09-14
**Last Updated:** 2026-09-15 — Tier 3.1 (persistent facing / turn-to posture) shipped.
**Status:** DONE — Tiers 1.1, 1.2, 2.1, 3.1 (formation-settle, cower re-plant, lead/trail foot asymmetry, persistent facing) all shipped, regression-clean.
**Scope:** the four realism systems deferred across the leg/off-balance tuning passes. See
`LIVE_PATHS.md#wf-footing-improvement-backlog` for what already shipped (leg parry brace, torso parry
brace, leg off-balance susceptibility, staggered guard-transition cost, concussed balance → dodge,
arm-wound wind-up slowdown, formation-move settling).

## Read this first

The combat model has **no persistent per-combatant facing vector**. `engagement_angle`
(`front`/`flank`/`rear`) is a **resolve-time stamp** recomputed from formation zone-control + `(rank,
file)` each time a strike resolves (`combat/strike/AttackResolver.gd:795-800`, source of truth
`combat/formation/ZoneOfControl.gd:417-477`). It is overwritten, never cleared, and lives only
per-exchange.

What **does** persist between turns: `guard_line` (blade posture), weapon `form`, the guard-readiness
gauge, `stance_preference`, and the timed/decaying `off_balance_until`/`off_balance_total` window.
Cower is a **physical posture** (limb destruction / unconsciousness) that persists while the condition
holds — it is not a timer.

**Design rule carried from the prior passes:** every new term must be (a) D001-neutral at healthy
values, (b) bounded to a researched band, and (c) a distinct axis from the existing multipliers (no
double-counting of pain / performance / consciousness that are already in the base formula).

---

## Tier 1 — clean wins (single insertion point, reuse the off-balance window)

These reuse the existing `PassiveParryContext.apply_off_balance_window` system, so no new state is
introduced. Highest value per line of code.

### 1.1 Formation-move settling window

**Motivation (HEMA):** a fighter who just stepped, swapped rank, or fell back is mid-replant — weight
is shifting, the base is not yet braced. Historically a man who has just moved in a line is easier to
hit for a beat, even without a dedicated "recovering" state. Today a formation move goes
`move-state → WAITING` with **no** recovery window: `_set_combatant_waiting` (`combat/formation/
CombatFormationFlow.gd:38-39`) calls `CombatFootwork.return_to_waiting` and the mover is immediately
fully ready. The only carryover is leg *fatigue* via `CombatMuscleFatigue.apply_formation_exertion`,
which slows the *next* movement but does not model the moment of replant.

**Current state:** the move-completion handlers call `_set_combatant_waiting` then
`CombatEventScheduler.schedule_action_ready_for_combatant` (e.g. `CombatFormationFlow.gd:594-595`,
`722-723`, `844-845`). Aborts (`abort_pair`, `abort_solo_formation_move`, `_formation_resolve_medical_
phase_skip`) call the same `_set_combatant_waiting` — so the insertion must be at the **successful
resolve** sites, not the generic setter.

**Design:**
- New constant `FORMATION_SETTLE_OFF_BALANCE_BASE_S := 0.35` in `CombatConstantsParry.gd` (a short
  replant window, shorter than a whiff's `OFF_BALANCE_DURATION_S` 0.4s+ because the fighter moved
  deliberately, not into a committed blow).
- New pure function `formation_settle_off_balance_duration(move_kind: String) -> float` — scales by
  move kind (fall-back/rotate > swap > plug-forward; plug is short and forward).
- New helper `apply_formation_settle(manager, c, move_kind)` that calls
  `PassiveParryContext.apply_off_balance_window(c, dur * off_balance_recovery_mult(c))` and logs via
  `CombatDebug.flow_log`.
- Insert at the **successful resolve** sites only (swap-rank resolve, fall-back resolve, rotate-file
  resolve, plug-forward resolve) — not the abort/medical-skip paths.

**D001-neutral:** a settled healthy fighter pays only the short 0.35s window on the *next* exchange —
D001 is a static SWORD-vs-SWORD soak with no formation movement, so the soak is unaffected (flag the
soak assumption explicitly in the test).

**Regression test:** `harness/regression/` — assert `apply_formation_settle` produces a positive
`off_balance_depth` immediately after and that it fades to 0 over the window; assert no window is
applied on the abort path.

**Open question:** should settling be skipped for `MOVE_ID_PLUG_FORWARD` (a deliberate, fast advance
that *gains* tempo)? Tentative: yes, plug sets 0.0.

### 1.2 Cower re-plant window

**Motivation (HEMA):** cower is entered on limb destruction (no functional arm / leg-collapsed /
unconscious) — `core/CoreEntity.gd:437-446`. When the condition clears, `process_incapacitation`
(`combat/flow/CombatStateHandlers.gd:107-117`) drops the fighter straight to `WAITING` with gauge 0.
A man getting back to his feet after that is not instantly braced; he needs a beat to plant and
re-establish the guard.

**Current state:** the cower-exit block sets `return_to_waiting`, `gauge = 0.0`,
`COMBATANT_GUARD = GUARD_AFTER_ATTACK`, then `schedule_action_ready_for_combatant(manager, c, 0.05)`.
The 0.05s is effectively instant.

**Design:**
- Reuse the settling idiom: at the cower-exit, apply a short off-balance window sized to the cower
  reason (legs > arms; a leg-collapsed re-plant is slower). New constant
  `COWER_REPLANT_OFF_BALANCE_BASE_S := 0.6` (arms-only) and `* 1.4` when the reason involved legs.
- Read `get_cowering_reason()` (`CoreEntity.gd:451-459`) — but note it is only meaningful *while*
  cowering; capture the reason before the `return_to_waiting` transition, or key off leg functionality
  (`CombatantEntityAccess.get_leg_functionality` < `LEG_COWER_THRESHOLD`).

**D001-neutral:** D001 never enters cower (no limb destruction in the SWORD soak), so unaffected.

**Regression test:** enter cower via arm-destruction fixture, clear the condition, assert a positive
settling window; assert the reason-dependent scaling.

**Open question:** does re-plant double-count the existing `GUARD_AFTER_ATTACK` (0.4) guard dip?
Guard dip is *readiness* (how fast the blade rises); off-balance is *timing/balance*. They are
distinct axes and both apply — no double count, but confirm the combined feel in a soak before
freezing the 0.6 constant.

---

## Tier 2 — new fields, medium effort

### 2.1 Lead/trail foot asymmetry

**Motivation (HEMA):** the lead leg steps *into* the strike (drive/extension) while the trail leg
pushes off (the propulsive reaction). A compromised lead leg can't advance into the blow; a
compromised trail leg can't generate push-off power. Today both legs are collapsed to one symmetric
scalar — `BodyPartQuery.get_leg_functionality` (`core/BodyPartQuery.gd:261-286`) is the geometric mean
of both legs' bone factors. The raw per-leg data (`body_cutting`/`bone_health` keyed on
`left_leg`/`right_leg`) **already exists and is asymmetric**; only the blend throws the distinction
away.

**What exists to reuse:**
- Per-leg part queries already operate on a single part: `get_bone_functionality_factor`,
  `is_part_physically_operable`, `get_part_operability` (`BodyPartQuery.gd:93-144`).
- A per-combatant `dominant_hand` field already exists (`core/CoreEntity.gd:59`) — `lead_leg` mirrors
  it.
- Consumers of the symmetric `get_leg_functionality`: wind-up speed (`AttackWindUpStarter.gd:166`),
  off-balance recovery (`PassiveParryContext.gd:174`), parry bracing (`DefenseChoiceResolver.gd:268,409`
  + torso pass), formation move duration (`CombatFormationMoveDuration.gd:77,82`), close-advance
  fatigue (`CombatEngagementResolver.gd:96`).

**Design (staged):**
1. **Data:** add `lead_leg: String` (default `PART_RIGHT_LEG` or `PART_LEFT_LEG`) to `CoreEntity.gd`
   alongside `dominant_hand`; randomize/default on spawn (mirror `CoreEntity.gd:1043-1053`). Optional
   species default in `resources/species/SpeciesResource.gd` + both `.tres` (defer — combatant-level
   is enough for v1).
2. **Query:** add `get_leg_functionality_for(entity, part: String) -> float` (per-leg, reusing the
   bone-factor + operability logic of the existing function). Keep the existing symmetric
   `get_leg_functionality(entity)` **unchanged** for the bulk consumers.
3. **Access:** plumb through `CoreEntity` → `CombatantCombatStateAccess` → `CombatantEntityAccess`
   (5-file facade pattern, same as `get_striking_arm_grip_mult`).
4. **Consumer hook (v1, minimal):** in the strike wind-up/advance, substitute the **lead leg** value
   for the drive term and keep the symmetric value elsewhere. Do *not* rewire off-balance or parry
   bracing yet — those read "overall stability", not "which leg steps".

**D001-neutral:** a healthy fighter's lead-leg value == symmetric value == 1.0 → no change.

**Regression test:** `harness/regression/core/` — mirror `ArmWoundDegradationTests.gd`: healthy
lead = 1.0; damaged lead leg (bone depleted on lead part) < symmetric blend when only the lead is hit;
feature-off path returns the symmetric value.

**Open questions:**
- ~~Which consumers flip to per-leg in v1 vs v2?~~ Wind-up drive shipped in v1; close-advance
  pressure shipped in v2 (`close_advance_lead_leg_mult` in `CombatEngagementResolver`). Formation-move
  duration remains on the symmetric blend (deferred).
- Does lead-leg swap on weapon form (aggressive vs defensive stance)? Out of scope — treat
  `lead_leg` as static per combatant for v1.
- ~~Does `lead_leg` vary per fighter?~~ Shipped: `_apply_common_seed_defaults` correlates `lead_leg`
  with the already-seeded `dominant_hand` (right-hander → right lead leg, left-hander → left), so the
  lead/trail asymmetry responds to both legs across the population. No extra RNG call (reads
  `dominant_hand`), so the deterministic harness stream is unaffected; the D001/harness path pins
  `lead_leg` via `apply_species_harness_deterministic`. Regression: `LeadLegFunctionalityTests._run_lead_leg_correlates_with_dominant_hand`.

---

## Tier 3 — architectural, largest

### 3.1 Persistent facing / turn-to posture

**Status:** Shipped (v1 + pile-on + recovery scaling). `facing_turn_until`/`facing_turn_total` stamp on flank/rear resolve
(`AttackResolver`), decay over `facing_turn_window_s` (flank 1.2 s / rear 1.5 s); repeated flank/rear
hits pile on (extend) the window, capped by `FACING_TURN_MAX_WINDOW_S` (2.5 s) via
`PassiveParryContext.apply_facing_turn`, which scales the window by `off_balance_recovery_mult` so a
compromised fighter (wounded legs / low agility / exhausted / concussed) re-centers more slowly.
`PassiveParryContext.facing_turn_parry_capacity_mult` consumes it as a bounded parry-capacity dip (min 0.90) on both
the on-time and late/reflexive parry paths in `DefenseChoiceResolver`. Gated by `FEATURE_PERSISTENT_FACING`. D001-neutral.

**Motivation (HEMA):** once a fighter turns to answer a flank or rear attack, they stay turned for a
beat — they don't snap back to front-on between every exchange. Today `engagement_angle` is
recomputed fresh each resolve from zone geometry, so a fighter who parried a rear attack is scored
as "front" on the very next exchange. A decaying **facing state** would let the orientation advantage
persist and decay.

**Why it's large:**
- It introduces a *new persistent per-combatant scalar* (turn-orientation) alongside the
  resolve-time stamp — the first true "facing" datum in the model.
- It must reconcile with `ZoneOfControl`'s zone-based orientation (the authoritative front/flank/rear
  for *damage*). Two sources of orientation must not fight: the zone stamp sets the *threat* angle;
  the persistent facing would modulate *recovery cost* of re-orienting.
- It interacts with `guard_line` drift (`GuardLineUpdater`) and the parry-alignment path
  (`CombatConstants.line_to_angle` / `get_line_alignment`) — turning changes which guard lines are
  "open".

**Design (lightweight v1 — a decaying orientation, not a full facing vector):**
- Add `facing_turn_until` + `facing_turn_total` (mirror the off-balance pair) on the combatant dict.
- On a strike that resolves with `engagement_angle` == flank/rear, *stamp* the defender's facing to
  that orientation with a decaying window (~1.0–1.5s).
- Consume it in one or two places first: a small off-balance/penalty *carryover* while the facing is
  still turned (a turned fighter is briefly exposed on that flank), read alongside the existing
  `hit_orientation_stagger_mult`.
- Feature-gated (`FEATURE_PERSISTENT_FACING`), D001-neutral (D001 always resolves front-on → no stamp).

**Regression test:** force a flank-stamp, assert the facing window is active and decays; assert D001
(front-only) never stamps.

**Open questions:**
- Decay rate and how it composes with the off-balance window (both are timed decays — must not stack
  into a double stagger).
- Does turning raise parry readiness on the *new* exposure line but lower it on the *old* line?
  (This is where it meets `guard_line` — likely a follow-up.)
- **Recommendation:** do Tier 1 + 2 first, soak, then tackle this. It is the only item that changes
  the model's shape (new persistent datum) rather than adding a bounded multiplier.

---

## Suggested order

1. **1.1 Formation-move settling** — smallest, reuses off-balance, immediately visible in line play.
2. **1.2 Cower re-plant** — same idiom, small.
3. **2.1 Lead/trail v1** (data + query + wind-up drive only) — medium, isolated.
4. **Soak** (D001 + F5 regression) between 2 and 3 to confirm no tempo drift.
5. **2.1 v2** (formation-move + close-advance consumers) once the split is proven.
6. **3.1 Persistent facing v1** — only after the above are stable; it's the one that changes the model.

## Cross-cutting invariants (every tier)

- D001 SWORD soak must remain byte-stable (healthy values → 1.0 / no-op).
- New constants live in `CombatConstantsParry.gd` (or `CombatConstantsFormationMove.gd` for
  formation-only terms) with a delegation in `CombatConstantsMethods.gd`.
- Pure functions in constants; entity reads only in the access layer / consumer.
- No `print("[Combat]")` — use `CombatDebug.flow_log` / `combat_session`.
- Every new axis gets a `harness/regression/` test mirroring `ArmWoundDegradationTests.gd`.
- Run `tools/ci/run_all_combat_checks.ps1 -HarnessMode regression` (`ok=true`) after each tier.
