# Physics Damage And Flow

**Plan / code:** **Status** → plan [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary) only. **Live paths:** [Kinematic audit](#tier-51-kinematic-audit) · [Pipeline checklist](#tier-51-angles-pipeline-remaining) · grep **`_run_kinematic_delivery_`** in registry.

---

<a id="tier-51-kinematic-audit"></a>

## Tier 5.1 — Kinematic audit (regression)

**Purpose:** What Tier **5.1** harnesses lock — see table below. **Sources:** plan [§5.1 exit](IMPLEMENTATION_ORDER.md#tier-51-angles-damage-flow-audits) · registry Tier **5.1** paragraph.

**Locked behaviors (`_run_kinematic_delivery_*`):**

| Topic | Intent |
|--------|--------|
| **`kinematic_delivery`** | Thrust / swing / **`mixed`** routing; explicit archetype overrides move inference; mixed **0.5** uses blended **`v`** for KE (**`lerp`** of thrust vs swing KE at that **`v`**, not **`lerp`** of pure-mode KEs). |
| **Intensity bridge** | **`velocity_m_s_from_intensity`** matches **`get_effective_velocity_m_s`** when **`velocity_m_s` < 0**; intensity **0.05 → 0.95** increases derived speed where expected (**SWORD** / **AXE** / **DAGGER** swing, **SPEAR** thrust, **MACE** blunt→swing, mixed). |
| **Pre-armor vs speed** | **`compute_pre_armor_cut`** ∝ **`sqrt(KE)`** at pinned **`v`** (swing fixtures); **`compute_pre_armor_blunt`** rises with pinned **`v`** on **MACE** **`direct_blow`**. |
| **Penetration vs speed** | **SHARP** **`penetration_sharp`** ∝ **`KE^PENETRATION_EXPONENT`** at pinned **`v`**; **BLUNT** **`penetration_blunt_momentum_per_area`** rises with pinned **`v`** on **MACE**. |
| **`strike_energy_mult`** | Scales **`compute_kinetic_energy_j`** linearly at pinned **`v`**; **`compute_pre_armor_cut`** tracks **`sqrt(mult)`**; same pattern on **`mixed`** **0.5** with derived **`v`**. |
| **`strike_momentum_mult`** | Scales **`compute_pre_armor_blunt`** and **BLUNT** **`penetration_blunt_momentum_per_area`** linearly at pinned **`v`** (cut swings + **MACE** blunt). |
| **Cross-coupling** | **`strike_momentum_mult`** does not feed **KE**, **SHARP** penetration, **`compute_pre_armor_cut`**, or effective **`v`** where the harness says so; **`strike_energy_mult`** does not feed blunt pre-armor, **BLUNT** **`mpa`**, or effective **`v`** where the harness says so — including pinned **`v`** on **SWORD** / **AXE** / **DAGGER** cuts (**`get_effective_velocity_m_s`** ⊥ both mults on those fixtures). |
| **Oblique penetration (damage path)** | **`AttackResolver.penetration_oblique_angle_factor`** — parry fraction vs misaligned-guard alignment (**`PARRY_PENETRATION_*`**); **`velocity_override` < 0** ⇒ no oblique penetration scaling (intensity-derived path). **`strike_mods`** **`sharp_penetration_mult`** / **`blunt_momentum_pa_mult`** on applied pens after oblique; **`cut_damage_mult`** / **`blunt_damage_mult`** scale pre-armor tissue only — do not change applied pens (**`compute_and_apply_damage`**). Harnesses **`_run_kinematic_delivery_penetration_oblique_angle_factor_attack_resolver`**, **`_run_kinematic_delivery_compute_damage_oblique_penetration_integration`**, **`_run_kinematic_delivery_compute_damage_strike_mods_penetration_integration`** (incl. partial parry + damage mults; shared **`_kin_dmg_pen_sample`**); manager meta **`_harness_expose_penetration_applied`**. |
| **Line alignment + deflect blend** | **`CombatConstants.get_line_alignment_with_deflect`**: both **`attack_angle_deg`** + **`guard_angle_deg`** ⇒ **`get_alignment_from_angles`** with **`PARRY_ALIGNMENT_FLOOR`**; attack-angle-only uses **`get_guard_angle_deg`**; no angles + blend **0** ⇒ discrete **`get_line_alignment`**; **`guard_deflect_blend`** lerps between **`get_line_alignment(attack, from_line)`** and **`get_line_alignment(attack, guard_line)`**. Harness **`_run_kinematic_delivery_line_alignment_with_deflect_branches`**. |
| **Bilateral deflection + line quadrants** | **`get_deflected_angle_bilateral`**: cw vs ccw by larger shortest angular distance from **`guard_angle_deg`** (feeds **`get_deflected_line_from_angles`** magnitude path). **`angle_to_nearest_line`** / **`line_to_angle`** cardinal round-trips. Harness **`_run_kinematic_delivery_deflected_angle_bilateral_and_line_angle_helpers`** (deterministic; complements seeded **`_run_parry_opposite_deflect_thresholds`**). |
| **Deflected line — same-line bind** | **`get_deflected_line_from_angles`**: when attack and guard angles map to the same **`angle_to_nearest_line`**, returns that line immediately (no **`get_deflection_magnitude_deg`** / RNG). Harness **`_run_kinematic_delivery_deflected_line_from_angles_same_line_bind`**. |
| **Angle diff + cos alignment** | **`angle_diff_deg`** shortest arc **0–180°** (wrap-safe); **`get_alignment_from_angles`** = **`maxf(PARRY_ALIGNMENT_FLOOR, cos(θ))`**. Harnesses **`_run_kinematic_delivery_angle_diff_and_alignment_from_angles_helpers`**, **`_run_kinematic_delivery_angle_diff_symmetry_and_zero`** (tail). |
| **Paths + wobble** | **`get_attack_path`** / fallbacks; **`attack_angle_deg`** variance; guard wobble vs readiness/mass. Harnesses in main harness + tail (**`_run_kinematic_delivery_get_attack_path_*`**, **`_run_kinematic_delivery_attack_angle_*`**, **`_run_kinematic_delivery_guard_wobble_*`**). |
| **`compute_and_apply_damage` integration** | Assembled **`v`** → pre-armor / pens / **`strike_ke_j`**; partial parry cut→blunt; oblique + strike_mods compose; meta **`_harness_expose_penetration_applied`** / **`_harness_expose_damage_kinematics`**. Shared **`_kin_dmg_integration_sample`**; grep **`_run_kinematic_delivery_compute_damage_*`**, **`_run_kinematic_delivery_partial_parry_*`**, **`_run_kinematic_delivery_misaligned_*`**. |
| **Closing speed (`StrikePhysics`)** | **`closing_speed_multiplier`**: **`engagement_angle`**, **`strike_physics_ctx`** depth-polearm open-lane stab (not **`over_shoulder`** / cut **`attack_type`**), **`depth_polearm_allows_low_targets` false** blocks non-open lane boost, **`tactical_ambush_mult` > 1** only (≤ 1 unchanged). Rank-1 **`stamp_attack_pair_geometry_on_dict`** → same ctx as **`AttackResolver`**. Harnesses **`_run_kinematic_delivery_closing_speed_engagement_angle_scales_strike_ke`**, **`_run_kinematic_delivery_depth_polearm_thrust_ctx_scales_strike_ke`**, **`_run_kinematic_delivery_depth_polearm_allows_low_false_no_closing_boost`**, **`_run_kinematic_delivery_pa_stamp_open_lane_strike_ke_matches_manual_ctx`**, **`_run_kinematic_delivery_tactical_ambush_mult_scales_strike_ke`**, **`_run_kinematic_delivery_tactical_ambush_mult_unity_no_boost`** (tail). |
| **Entity / armor sample** | **`take_damage_split`** contract; chest **GAMBESON** / **CUIRASS** / **HAUBERK** below bare tissue at pinned **`vo`** with **`mechanical_post_armor` > 0** (piece ordering not asserted on **oberhau**). Harnesses **`_run_kinematic_delivery_compute_damage_velocity_and_entity_split`**, **`_run_kinematic_delivery_entity_split_final_fields_on_hit`**, **`_run_kinematic_delivery_armored_chest_reduces_tissue_and_reports_mech_post_armor`**, **`_run_kinematic_delivery_gambeson_and_cuirass_chest_both_below_bare`** (tail). |
| **Unarmed damage** | No weapon: **`unarmed_base_pre_armor`** × closing × stamina × stance; partial parry **`lerp(0.5,1,r)`**. Tail **`_run_kinematic_delivery_unarmed_pre_blunt_matches_helper`**, **`_run_kinematic_delivery_unarmed_partial_parry_scales_pre_blunt`**. |

**Harness layout:** Exit-gated tests in **`CombatRegressionHarness.gd`**; optional long-tail in **`CombatRegressionHarnessKinematicTail.gd`** (**`CombatRegressionHarness._KinematicTail.run`**). Registry → **`REGRESSION_HARNESS_MAP_TIER19.md`** Tier **5.1** paragraph.

**Out of scope here:** Full parry calibration, exhaustive armor layering per part, editor soaks, and every **`LINE_ANGLE_DEG`** consumer beyond harnessed helpers — see investigations below.

---

## Contents (investigations)

1. [PHYSICS_REALISM_DECISIONS_INVESTIGATION.md](#physics-realism-decisions-investigation)
2. [ANGLE_SYSTEM_INTEGRATION_STATUS.md](#angle-system-integration-status)
3. [PHYSICS_SYSTEMS_OPTIMAL_STRUCTURE_INVESTIGATION.md](#physics-systems-optimal-structure-investigation)
4. [COMBAT_ATTACK_PARRY_DODGE_FLOW.md](#combat-attack-parry-dodge-flow)
5. [SYSTEM_INTEGRATION_STATUS.md](#system-integration-status)
6. [COMBAT_ENTITY_INTERFACE.md](#combat-entity-interface)
7. [SHARP_PENETRATION_BLUNT_TRANSMISSION_PLAN.md](#sharp-penetration-blunt-transmission-plan)
8. [CONTACT_TYPE_MULTIPLIERS_INTEGRATION_INVESTIGATION.md](#contact-type-multipliers-integration-investigation)
9. [SUBREGION_MULTIPLIER_AUDIT.md](#subregion-multiplier-audit)
10. [RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md](#researched-numbers-health-system-coherence)
11. [COMBAT_NUMBERS_REALISM_AUDIT.md](#combat-numbers-realism-audit)
12. [GOBLIN_STATS_REALISM.md](#goblin-stats-realism)
13. [Tier 5.1 — Angles / pipeline (narrative checklist)](#tier-51-angles-pipeline-remaining)

---

<a id="tier-51-angles-pipeline-remaining"></a>

## Tier 5.1 — Angles and damage pipeline (narrative checklist)

**Purpose:** Working checklist for Tier **5.1** narrative damage-flow work in [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md#tier-51-angles-damage-flow-audits) (beyond [Kinematic audit](#tier-51-kinematic-audit)). **Plan:** The checklist + read-through anchors here are **checked** in the plan (see **Tier 5.1 narrative damage-flow checklist** exit row); optional long-tail items use the following **unchecked** row there.

| Track | Where in this file | Suggested audit |
|--------|-------------------|-----------------|
| Continuous angles vs discrete lines | [Angle system integration status](#angle-system-integration-status) | Reconcile live path with: **`get_line_alignment_with_deflect`**, **`angle_to_nearest_line`** / **`ATTACK_PATHS_BY_GUARD`**, **`alignment_context`** / **`variance_context`** fallbacks — see **Angles vs discrete lines** anchors below. |
| Attack → parry → damage flow | [Combat attack, parry, dodge flow](#combat-attack-parry-dodge-flow) | Trace **`v`** end-to-end: parry **`v_intent`** uses **`WeaponDamageHelper.get_effective_velocity_m_s`** in **`DefenseChoiceResolver`**; hit damage builds **`AttackInstance.velocity_m_s`** in **`AttackResolver.compute_and_apply_damage`** then **`WeaponDamageHelper`** pre-armor / penetration / KE (each calls **`get_effective_velocity_m_s`** internally). See also [PARRY_DEFLECT_AND_CALIBRATION.md](PARRY_DEFLECT_AND_CALIBRATION.md) damage pipeline table. |
| Sharp / blunt penetration | [Sharp penetration / blunt transmission plan](#sharp-penetration-blunt-transmission-plan) | Match **`WeaponDamageHelper.compute_penetration`** return keys (**`penetration_sharp`**, **`penetration_blunt_momentum_per_area`**, **`blunt_contact_cm`**) to **`AttackResolver.compute_and_apply_damage`** post-processing (angle/oblique **`angle_factor`**, strike mods) — see **Penetration → armor** anchors below. |
| Entity / armor interface | [Combat entity interface](#combat-entity-interface) | Confirm split path: **`AttackResolver`** → **`CoreEntity.take_damage_split`** → **`EntityDamage.apply_damage_split`** — see **Entity split damage** anchors below. |

**Code read-through:** Summarized in [Kinematic audit](#tier-51-kinematic-audit) (alignment branches, oblique penetration, entity split). Narrative flow tables → [Combat attack, parry, dodge flow](#combat-attack-parry-dodge-flow). Tier **3** live paths → [3.2](PARRY_BIND_AND_WEAPON_GEOMETRY.md#tier-32-parry-bind-live-path), [3.3](GUARDS_LINES_AFTERBLOW.md#tier-33-guard-line-afterblow-live-path).

---

<a id="physics-realism-decisions-investigation"></a>

## Source: `PHYSICS_REALISM_DECISIONS_INVESTIGATION.md`

# Physics Realism: Systems Requiring Decisions — Investigation

After implementing the 4-line guard system (Liechtenauer: high, low, left, right), this doc identifies **other systems that need design decisions** to prioritize physics-based realism. Ordered by impact and dependencies.

---

## 1. What Is Implemented (4-Line System)

> **Historical snapshot** — current contract is Tier **3.2–3.3** + [Kinematic audit](#tier-51-kinematic-audit). Do not treat this table as milestone **Status**.

| Component | Status | Location |
|-----------|--------|----------|
| LINE_ANGLE_DEG table | Done | CombatConstants.gd |
| get_line_alignment(attack_line, guard_line) | Done | CombatConstants.gd |
| attack_line per move | Done | WeaponConstants.gd (_move_definitions_build) |
| guard_line per combatant | Done | CombatManager.gd (_register_combatant); default "high" |
| BP2: parry_c_d *= alignment | Done | DefenseChoiceResolver.gd |
| BP3: variance ∝ 1/alignment | Done | AttackResolver.gd |
| BP5: geometric leak | Done | AttackResolver.gd |
| Constants: PARRY_ALIGNMENT_FLOOR, GEOMETRIC_LEAK_MAX | Done | CombatConstants.gd |

---

## 2. Guard Line Dynamics (Priority: Medium)

**Current:** Combatants have `guard_line` defaulting to "high." It never changes.

**Question:** Should `guard_line` evolve based on combat state?

| Option | Description | Physics Basis |
|--------|-------------|---------------|
| **A: Static default** | Always "high" (current). | Simplest; neutral guard is high (Vom Tag). |
| **B: After attack** | Last attack's line becomes new guard. E.g. oberhau → guard_line = "high." | Liechtenauer: cut ends in a guard; next defense starts from that position. |
| **C: Explicit choice** | Player/AI chooses guard_line each turn or when idle. | Historical: fighter chooses where to hold blade. |
| **D: Blend** | Default "high"; after attack, set guard_line = attack_line of that move. No explicit choice. | B without UI; automatic continuity. |

**Recommendation:** **Option D** — set `tgt["guard_line"] = attack_line` when defender finishes an attack (or when attacker recovers from their attack, if defender was last to act). Gives weapon-position continuity without new UI. Defer explicit guard choice (C) until/if you add active defense.

**Data:** `attack_line` from move; defender's last move_id must be stored (e.g. `last_move_id` on combatant) or inferred from state. If defender didn't attack, keep current guard_line.

---

## 3. Physically Realistic Afterblow (Priority: High)

**Current:** No afterblow. When A hits B, B's `pending_attack` (if any) is not resolved.

**Physics:** A creature hit mid-swing can complete a *previously planned* attack **iff** the blow wasn't intense enough to hinder the action (part hit, damage, intensity, outcome).

**Decisions:**

| Item | Options | Recommendation |
|------|---------|---------------|
| **Hindrance model** | Score (0–1), hard thresholds, per-part damage, KE threshold | Hybrid: immediate disqualifiers + hindrance score (LINE_GUARD doc §3.5) |
| **Hook point** | After `compute_and_apply_damage` returns, before recovery/state transition | In `CombatManager` after `resolve_attack` returns "hit"; check `tgt.pending_attack` |
| **Flow** | A hits B → apply damage → check B.pending_attack targets A → hindrance → if allowed, resolve B→A | See LINE_GUARD doc §3.6 |
| **Data** | hit_part, final_cut/blunt/bone, outcome, intensity, B.pending_attack, get_attacking_arm | All available in take_result and combatant state |

**IMPLEMENTED:** `AfterblowHandler.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)` called from CombatManager when action=="hit". Hybrid hindrance; stance from dominant_hand; damage *= (1-hindrance); full resolution for B→A and B→C. See combat/AfterblowHandler.gd.

---

## 4. Arm interpose (BP6) — **not in current code**

The separate interpose roll and `CombatConstants.INTERPOSE_*` tables were **removed**; limb-before-head ordering is handled via **`ATTACK_PATHS_BY_GUARD`** and related path logic in `CombatConstants.gd` / `AttackResolver.gd` (guard-dependent intercept order), not a dedicated `p_interpose` constant.

---

## 5. Diagonal Cut Line Roll (BP1) — Optional

**Current:** Diagonal moves (oberhau, diagonal_chop) have single primary `attack_line`.

**Physics:** Zornhau crosses high and left. Which line the guard "meets" first varies by trajectory.

| Option | Description |
|--------|-------------|
| **Keep primary** | oberhau = "high", diagonal_chop = "left." Simple. |
| **Weighted roll** | At resolve, roll: 65% high, 35% left for descending diagonal. Adds variance. |

**Recommendation:** **Keep primary** for now. Weighted roll (Option P5) can be added later if diagonal parries feel too binary.

---

## 6. Variance Constant (PARRY_GEOMETRY_VARIANCE_BASE)

**Current:** Geometry variance is multiplicative with technique variance: `variance_eff *= clamp(1/alignment, 1, 2.5)`. PARRY_GEOMETRY_VARIANCE_BASE exists but is not used (we scale technique variance instead).

**Doc suggested:** Separate geometry variance `= PARRY_GEOMETRY_VARIANCE_BASE × clamp(1/alignment, 1, 2.5)` instead of scaling technique.

**Decision:** Keep current approach (technique × geometry scale) vs replace with pure geometry variance. Current is simpler and preserves agility's effect on technique variance. **Recommendation:** Keep as-is; tune if parry outcomes feel off.

---

## 7. Measure / Distance — Defer

**Current:** No distance. All attacks "in range" when chosen.

**Physics:** At bind (close), thrust from bind; at long measure, cuts may fall short.

**Recommendation:** **Defer.** Would require `steps_to_opponent` or abstract measure bands. Significant scope increase.

---

## 8. Weapon Position Continuity (last_guard)

**Current:** No `last_guard`. Each parry uses current `guard_line` only.

**Physics:** After a cut, weapon is in a guard (e.g. Plough). Next parry from that position is faster.

**Recommendation:** **Defer** until guard_line dynamics (§2) are decided. If guard_line evolves after attack (Option D), that partly captures continuity. Explicit wind-up cost from guard transition (`windup_mult × transition_factor`) is a later enhancement.

---

## 9. Thrust Line

**Current:** All thrusts use `attack_line = "high"` (point threatens center/high).

**Alternative:** Add "center" as fifth line for thrusts. Would require extending LINE_ANGLE_DEG to 5×5.

**Recommendation:** **Keep "high"** for thrusts. Four lines suffice; "center" adds complexity with limited benefit.

---

## 10. Calibration and Validation

| Metric | Target (HEMA) | How to Validate |
|--------|---------------|-----------------|
| Blade-blade share of contacts | 57–80% (longsword) | Log parry_deflect + parry_partial vs hit; tune alignment floor, leak, variance |
| Wrong guard = partial, not total fail | — | alignment floor 0.15 ensures some parry effect even at 90° |
| Outcome variance when wrong | — | Playtest; adjust GEOMETRIC_LEAK_MAX, variance scale |

**Recommendation:** Add optional debug logging (alignment, parry_c_d before/after, variance_eff, geometric_leak, remaining_ratio) behind a flag for calibration runs. Tune PARRY_ALIGNMENT_FLOOR (0.15), GEOMETRIC_LEAK_MAX (0.35) to hit 57–80% parry share in longsword vs longsword.

---

## 11. Decision Summary (Recommended Order)

| Order | System | Decision | Effort |
|-------|--------|----------|--------|
| 1 | **Afterblow** | Implement hybrid hindrance model; hook after damage | Medium |
| 2 | **Guard line dynamics** | Option D: set guard_line = attack_line after attacker's recovery | Low |
| 3 | **Calibration** | Add debug logging; tune to 57–80% parry | Low |
| 4 | Arm interpose | Defer | — |
| 5 | Diagonal line roll | Defer | — |
| 6 | Measure, last_guard, thrust center | Defer | — |

---

## References

- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md (Parts 3, 4, 4B)
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- COMBAT_PARRY_MISS_RESEARCH.md
- CombatManager.gd, AttackResolver.gd, DefenseChoiceResolver.gd
- CombatConstants.gd (LINE_ANGLE_DEG, get_line_alignment)

---

<a id="angle-system-integration-status"></a>

## Source: `ANGLE_SYSTEM_INTEGRATION_STATUS.md`

## Angle-Based System Integration Status

### Overview

The combat system now uses continuous angles for trajectory, deflection, alignment, and damage. This document lists what was updated and what uses the new system.

---

### Components Updated for Angle System

#### Core combat (already implemented)

| Component | Angle integration |
|-----------|-------------------|
| **CombatConstants** | Continuous angles; fatigue/readiness/off-balance/mass variance; guard wobble; arc late-parry penalty |
| **AttackResolver** | `variance_context` (stamina, off_balance, mass) for attack angle; `arc_start/end/span`; guard wobble on hit |
| **AttackWindUpStarter** | `arc_start_deg` stored in pending_attack |
| **DefenseChoiceResolver** | Guard wobble via parry_readiness; arc_span penalty for late parry |
| **DefenseResolutionHandler** | Guard wobble in parry alignment |
| **AttackPathResolver** | Path from angle_to_nearest_line; alignment from continuous angles |
| **AttackResultApplier** | Guard wobble for parry_partial guard update |

---

### Debug Logging (updated)

| Log location | Change |
|--------------|--------|
| **AttackPathResolver** | When angle-based: `(atk=47° guard=90°)` appended to path log |
| **GuardLineUpdater** | When deflect with angles: `[atk=47° guard=90°]` appended |
| **DefenseResolutionHandler** (calibration) | `atk_deg=47 guard_deg=90` appended when available |
| **DefenseChoiceResolver** (calibration) | `atk_deg=47 guard_deg=90` appended when `align_ctx` has angles |
| **AttackWindUpStarter** | `[atk=0° guard=45°]` always shown (wind-up uses angle context) |

**Flags:** Set `CombatConstants.COMBAT_DEBUG := true` and/or `COMBAT_DEBUG_CALIBRATION := true` to enable.

---

### Combat UI (updated)

| Component | Status |
|-----------|--------|
| **CombatManager.get_combatants()** | When `COMBAT_DEBUG`: includes `guard_line` and `guard_angle_deg` in output |
| **BattleUIUpdater** | When `COMBAT_DEBUG`: gauge label shows guard angle (e.g. `Ready! 45°`) for waiting combatants |
| **CombatLogFormatter** | No change — uses result dict (dmg, part, outcome); angle system feeds resolution, not formatting |
| **BattleScene** | No change — passes result to formatter; resolution already uses angles |

The combat log displays outcomes (hit, miss, parry, glancing) from the result dict. Damage and parts are computed using angles; the UI only shows the final outcome.

---

### Continuous angle system

`get_line_alignment_with_deflect` uses continuous `get_alignment_from_angles` (cos θ) when `attack_angle_deg` and `guard_angle_deg` are present. No 4-line quantization for alignment — angles drive alignment directly. Path lookup still uses `angle_to_nearest_line` for ATTACK_PATHS_BY_GUARD table keys. Deflection uses bilateral angle-based `get_deflected_angle_bilateral`. Fatigue, readiness, off-balance, weapon mass, and guard wobble all modify angle variance/placement.

### Backward compatibility

- **guard_line** and **effective_attack_line** are still used. Angles are computed alongside them.
- If `alignment_context` is empty or lacks angles, behavior falls back to line-based alignment.
- Path lookup uses `angle_to_nearest_line()` for 4-line quantization; ATTACK_PATHS_BY_GUARD remains unchanged.

---

### Enabling debug output

In `combat/CombatConstants.gd`:

```gdscript
const COMBAT_DEBUG := true           # General combat logs (path, guard, wind-up)
const COMBAT_DEBUG_CALIBRATION := true  # Parry calibration (alignment, c_d, angles)
```

When both are true, you will see:
- Path resolution with angles
- Guard deflection with atk/guard angles
- Wind-up with angle-based alignment
- Parry capacity with angles
- Gauge label with guard angle (e.g. `Ready! 90°`)

---

<a id="physics-systems-optimal-structure-investigation"></a>

## Source: `PHYSICS_SYSTEMS_OPTIMAL_STRUCTURE_INVESTIGATION.md`

## Physics Systems: Implementation & Optimal Structure Investigation

### Purpose

Investigate how Fatigue/Readiness/Off-Balance, Attack Arc, Mass/Guard Wobble, Binding/Tempo, Continuous Angle System, and Footwork/Positioning are implemented, and propose better structural approaches for optimal physics-based realism.

---

### 1. Fatigue, Readiness, and Off-Balance on Angle Variance

#### 1.1 Current Implementation

| Factor | Where | How |
|--------|-------|-----|
| **Fatigue (Stamina)** | AttackResolver → variance_context | `stamina_ratio` (0–1) passed to `get_attack_angle_deg()`. **Non-linear:** `stamina_factor(ratio) = ratio^0.6`; variance mult = 1 + 0.5×(1 − stamina_factor). Ramps sharply below ~25% stamina. |
| **Readiness** | PassiveParryContext → DefenseChoiceResolver | Readiness affects **defender** parry capacity and guard wobble, not attacker variance. Attacker variance_context does **not** include readiness. |
| **Off-Balance** | AttackResolver, AttackResultApplier | Set `off_balance_until` after miss or parry_deflect. `_PassiveParry.is_off_balance(atk)` → `variance_context["off_balance"]` → variance × `ANGLE_VARIANCE_OFF_BALANCE_MULT` (1.35). Also: parry capacity × 0.7, gauge fill × 0.5 during window. |

**Flow (AttackResolver.gd 269–276):**
```gdscript
var_ctx["stamina_ratio"] = clampf(s / STAMINA_MAX, 0, 1)
var_ctx["off_balance"] = _PassiveParry.is_off_balance(atk)
var_ctx["weapon_mass_kg"] = ...
pa["attack_angle_deg"] = CombatConstants.get_attack_angle_deg(atk_line_base, true, move_def_pre, var_ctx)
```

**Constants (CombatConstants.gd 250–253):**
- `ANGLE_VARIANCE_DEG`: 8° base
- `ANGLE_VARIANCE_STAMINA_AT_ZERO_MULT`: 1.5
- `ANGLE_VARIANCE_OFF_BALANCE_MULT`: 1.35

#### 1.2 Gaps

- **Readiness not in variance_context:** Attacker in recovery has lower readiness but attack variance is not scaled. Only defender readiness affects parry (capacity, wobble).
- **Fatigue/readiness conflated:** Stamina is a global fatigue pool; readiness is recovery-state (early/late). A fatigued combatant in WAITING might still have high readiness but high variance (fatigue).
- **Off-balance is binary:** Fixed duration; no severity. Realistically, severity depends on intensity, deflect vs miss, etc.

#### 1.3 Optimal Structure

| Improvement | Description |
|-------------|-------------|
| **Unified variance factor** | `effective_variance_mult = 1.0 × stamina_factor × off_balance_factor × readiness_factor × mass_factor`. Each factor from its own curve. |
| **Readiness in attacker variance** | When attacker is RECOVERING and resolves attack (re-entry from parry_partial?), pass `attacker_readiness` into variance_context. Early recovery = worse control = higher variance. |
| **Off-balance severity** | `off_balance_severity` 0–1 from recovery_cause (miss=0.6, deflect=0.8) × intensity. Duration and variance mult scale with severity. |
| **Stamina curve** | **Implemented.** `CombatConstants.stamina_factor(ratio)` uses power 0.6; applied to variance, parry, damage. See STAMINA_CURVE_HEMA_COMBAT_PACING_INVESTIGATION.md. |

---

### 2. Attack Arc Tracking and Use

#### 2.1 Current Implementation

| Data | Where Set | Where Used |
|------|-----------|------------|
| `arc_start_deg` | AttackWindUpStarter (attacker guard at wind-up) | AttackResolver: base for arc_span |
| `arc_end_deg` | AttackResolver ( = attack_angle_deg after variance) | - |
| `arc_span_deg` | AttackResolver: `angle_diff_deg(arc_start, arc_end)` | DefenseChoiceResolver (late parry only) |

**Flow:**
- Wind-up: `pa["arc_start_deg"] = CombatConstants.get_guard_angle_deg(atk)` (attacker’s blade at start)
- Resolve: `arc_end_deg = attack_angle_deg`, `arc_span_deg = angle_diff_deg(arc_start, arc_end)`
- Late parry: if `arc_span > 50°` → parry_c_d scaled down by up to 25%

#### 2.2 Gaps

- **Arc only affects late parry:** On-time parries do not use arc_span.
- **No arc-based intercept depth:** Path intercept uses alignment only, not “how far the blade traveled.” A short arc vs long arc could affect where the blade is when contact happens.
- **Arc_start from guard:** Reasonable, but diagonal moves might start from a blended guard; arc_start could be refined.
- **No move-defined arc width:** Moves don’t define arc_center/arc_width (trajectory-as-range per ENHANCED_BLADE_TRAJECTORY.md Approach D).

#### 2.3 Optimal Structure

| Improvement | Description |
|-------------|-------------|
| **Arc for all parries** | Scale parry capacity or alignment by arc_span: large arc = blade moving fast through space; harder to predict and catch. `parry_align_factor = 1.0 - k * clamp(arc_span / 90, 0, 1)` for small k. |
| **Move-defined arc width** | Add `arc_width_deg` per move (e.g. oberhau 60°, thrust 15°). Arc_span = variance within that width + geometry. Enables “sweeping cut vs precise thrust” feel. |
| **Intercept from arc position** | Model “blade at X% of arc” at contact. Late parry = blade further along arc. Feed into path intercept or hit distribution. |
| **Arc → deflection magnitude** | Large arc = more momentum; deflect magnitude could scale with arc_span (harder redirect when blade has traveled far). |

---

### 3. Mass and Guard Wobble

#### 3.1 Current Implementation

**Mass (attacker variance):**
- `variance_context["weapon_mass_kg"]` from attacker weapon
- `mass_mult = 1.0 + (mass_kg - 1.0) * 0.1`; variance × mass_mult
- Heavier weapon → harder to control → more variance

**Guard Wobble (defender):**
- `GUARD_WOBBLE_MAX_DEG`: 12°
- `wobble = GUARD_WOBBLE_MAX_DEG * (1.0 - readiness * GUARD_WOBBLE_READINESS_SCALE)` 
- Low readiness (e.g. early recovery) → blade not perfectly on line → ±wobble added to guard_angle
- Used in `get_guard_angle_deg(tgt, wobble_context)` when `parry_readiness < 1`

**Flow:** DefenseChoiceResolver passes `parry_readiness` → `align_ctx` includes wobble-affected guard_angle → alignment uses it. DefenseResolutionHandler, AttackPathResolver, AttackResultApplier use the same pattern.

#### 3.2 Gaps

- **Defender mass not in wobble:** Heavier defender weapon = more inertia = potentially more wobble when reacting. Current wobble is readiness-only.
- **Attacker mass only in variance:** Mass doesn’t affect deflection outcome, bind chance, or damage (except via variance → alignment).
- **Wobble is isotropic:** Same ± degrees in any direction. Realistically, wobble might favor certain directions (e.g. along weak axis of blade).

#### 3.3 Optimal Structure

| Improvement | Description |
|-------------|-------------|
| **Defender mass in wobble** | `wobble_mult = 1.0 + (defender_mass_kg - 1.0) * 0.08`. Heavier blade = slower to stabilize = more wobble when reacting. |
| **Mass in bind/deflect** | P(bind) or deflect magnitude could factor mass ratio: heavier attacker blade = harder to control in bind; lighter defender = easier to deflect. |
| **Readiness × mass interaction** | `wobble = base_wobble * (1 - readiness) * (1 + mass_factor)`. Low readiness + heavy blade = worst. |
| **Anisotropic wobble (advanced)** | Wobble component along blade axis vs perpendicular; perpendicular (edge alignment) matters more for parry quality. |

---

### 4. Binding and Tempo

#### 4.1 Current Implementation

**Bind:**
- `parry_control >= PARRY_BIND_CONTROL_THRESHOLD` (0.65) → bind
- parry_control = f(margin_ratio, alignment, readiness, timing, attack_type)
- On bind: attacker guard_line = attack_line (blade stays); defender guard from move
- GuardLineUpdater: `if parry_control >= threshold: line = atk_line, blend = 0`

**Tempo:**
- `off_balance_until` after parry_deflect or miss → gauge fill × `OFF_BALANCE_GAUGE_FILL_MULT` (0.5)
- `parry_bonus_until` after parry_deflect → parry capacity × 1.1 for defender
- No explicit Vor/Nach state; tempo is emergent from gauge fill rate

#### 4.2 Gaps

- **Bind angle is discrete:** Both blades end at attack_line. No compromise angle (lerp of attack + defender guard).
- **No bind duration:** Once bind, next action is normal. No “wind from bind” or restricted options.
- **Tempo is implicit:** Only off_balance and parry_bonus. No “last to act fills slower” or “indes window.”
- **Riposte from bind:** Parry_counter moves use attack_line; minimal transition is implicit but not a formal bonus.

#### 4.3 Optimal Structure (from BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md)

| Improvement | Description |
|-------------|-------------|
| **Bind angle blend** | `guard_angle = lerp(attack_angle, defender_guard_angle, 0.4 + 0.3 * parry_control)`. Both blades at compromise. Store continuous angle; guard_line = angle_to_nearest_line for legacy. |
| **Indes parry-counter** | When parry_deflect + parry_thrust/cut chosen, wind-up × 0.85 (faster counter from good position). |
| **Tempo state (optional)** | `tempo_state`: "vor" | "nach" | "neutral". Last to successfully attack = Vor; parried attacker = Nach. Vor: gauge bonus; Nach: parry/riposte bonus. |
| **Bind duration (advanced)** | `bind_until` timestamp. While bound: wind action or restricted guard change. Enables wind-from-bind gameplay. |

---

### 5. Continuous Angle System (No 4-Line Quantization)

#### 5.1 Current Implementation

| Layer | Continuous? | Quantization |
|-------|-------------|--------------|
| Attack angle | Yes | `get_attack_angle_deg()` returns 0–360 float. Variance applied. |
| Guard angle | Yes | `get_guard_angle_deg()` returns float; uses guard_line + deflect_blend + wobble. |
| Alignment | Yes | `get_alignment_from_angles(atk, guard)` = cos(θ). No line lookup. |
| Deflection | Yes | `get_deflected_angle_bilateral()` returns deflected angle; then `angle_to_nearest_line()` for storage. |
| Path lookup | No | `angle_to_nearest_line()` → discrete line → `get_attack_path(attack_line, guard_line)`. |
| Hit part | Partial | Path intercept uses alignment; when align_ctx has angles, path uses angle_to_nearest_line for lookup. |

**Quantization points:**
- `angle_to_nearest_line()`: boundaries at 45°, 135°, 225°, 315°
- ATTACK_PATHS_BY_GUARD: keyed by discrete (attack_line, guard_line)
- Guard storage: combatant.guard_line is string; guard_deflect_blend for lerp

#### 5.2 Gaps

- **Path table is 4×4:** Angles 23° and 67° both map to same quadrant. No interpolation between paths.
- **Deflection output quantized:** Deflected angle becomes line for storage; downstream loses precision.
- **Part sectors not angle-driven:** Hit part from path (ordered list) + intercept. No direct angle→part weights.

#### 5.3 Optimal Structure (from ENHANCED_BLADE_TRAJECTORY, ANGLE_VS_DISCRETE)

| Improvement | Description |
|-------------|-------------|
| **Store guard_angle_deg** | Keep `guard_angle_deg` alongside guard_line. Use angle for alignment, deflection, path; guard_line for legacy/display. |
| **Path interpolation** | When angle falls between two lines, blend path weights: `path_A * (1-t) + path_B * t` where t = angular distance to nearest. |
| **8 directions (medium effort)** | Add diagonals; 8×8 path table. 2× angular resolution without full float propagation. |
| **Angle-driven part sectors (Approach F)** | Define PART_SECTORS_DEG; weight(part) = sector_overlap(part, attack_angle) × guard_block_factor. Eliminates path tables for hit distribution. |
| **Deflection stays continuous** | Store deflected_angle_deg; only quantize when writing to guard_line for UI. |

---

### 6. Footwork and Positioning

#### 6.1 Current Implementation

**None.** No distance_band, stance, position_angle, or step-on-attack.

Relevant constants:
- `GUARD_TRANSITION_COST_SCALE`: wind-up scales by 1 - alignment (guard→attack)
- `melee_range` per weapon exists but not used for positioning
- Footwork/positioning doc (FOOTWORK_POSITIONING_INVESTIGATION.md) outlines options but none implemented

#### 6.2 Gaps

- No spatial representation: all combatants effectively “in range”
- No stance-derived variance (e.g. committed vs balanced)
- No distance modifiers for parry/damage

#### 6.3 Optimal Structure (from FOOTWORK_POSITIONING_INVESTIGATION)

| Phase | Content | Effect |
|-------|---------|--------|
| **1** | Distance band (close/medium/far) | Attack→close, dodge→far. Parry/damage modifiers per band. |
| **2** | Stance from last action | balanced/committed/retreating → variance mult. |
| **3** | Position angle offset | Step-on-attack adds offset; effective_attack_angle += offset. |
| **4** | Reach vs distance | At far: reduce parry alignment; at close: increase. |

---

### 7. Cross-Cutting Recommendations

#### 7.1 Data Flow Consistency

- **VarianceContext:** Extend to `{stamina_ratio, off_balance, off_balance_severity?, readiness?, weapon_mass_kg}`. Single struct passed everywhere attack angle is computed.
- **WobbleContext:** `{parry_readiness, defender_mass_kg?}`. Single struct for guard angle.
- **ClashContext:** Already exists for parry; extend for bind_angle, bind_duration.

#### 7.2 Constants Organization

Group by system:
```gdscript
# Angle variance
ANGLE_VARIANCE_*
# Wobble
GUARD_WOBBLE_*
# Arc
ARC_SPAN_*
# Bind / Tempo
PARRY_BIND_*
OFF_BALANCE_*
```

#### 7.3 Physics-First Order of Application

1. Base geometry (angles, alignment)
2. Variance (stamina, off_balance, readiness, mass) → attack_angle, guard_angle
3. Arc (span, width) → parry difficulty, intercept
4. Wobble → effective guard_angle
5. Bind/deflect → post-contact state
6. Tempo → gauge, recovery

#### 7.4 Suggested Implementation Priority

| Priority | Change | Effort | Impact |
|----------|--------|--------|--------|
| 1 | Readiness in attacker variance_context | Low | Medium |
| 2 | Off-balance severity (from recovery_cause × intensity) | Low | Medium |
| 3 | Arc for on-time parry (small penalty) | Low | Low–Medium |
| 4 | Bind angle blend | Low | Medium |
| 5 | Indes parry-counter wind-up reduction | Low | Medium |
| 6 | Defender mass in wobble | Low | Low |
| 7 | Store guard_angle_deg, path interpolation | Medium | High |
| 8 | Distance band | Medium | Medium |
| 9 | 8 directions or part sectors | Medium–High | High |

---

### References

- CombatConstants.gd (ANGLE_VARIANCE_*, GUARD_WOBBLE_*, ARC_SPAN_*, PARRY_BIND_*)
- AttackResolver.gd, DefenseChoiceResolver.gd, DefenseResolutionHandler.gd
- AttackWindUpStarter.gd, GuardLineUpdater.gd, PassiveParryContext.gd
- AttackPathResolver.gd, AttackResultApplier.gd
- CombatStateHandlers.gd (gauge fill, off_balance)
- BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md
- ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md
- FOOTWORK_POSITIONING_INVESTIGATION.md
- ANGLE_VS_DISCRETE_AND_BILATERAL_INTERSECTION_INVESTIGATION.md

---

<a id="combat-attack-parry-dodge-flow"></a>

## Source: `COMBAT_ATTACK_PARRY_DODGE_FLOW.md`

## Combat: Attack, Parry, and Dodge Data Flow Trace

This document traces how attack, parry, and dodge data flow through the combat system to verify connections are correct.

---

### 1. Attack flow

#### 1.1 Commitment (_begin_attack_with_target)

| Data | Source | Stored / used |
|------|--------|----------------|
| target_id | resolve_action(attacker_id, target_id) | → pending_attack.target_id |
| power, follow_through | randf_range(POWER_MIN/MAX, FOLLOW_THROUGH_MIN/MAX) | → pending_attack |
| intensity | (0.5+0.5*power)*(0.5+0.5*follow_through), clamped INTENSITY_MIN..1 | → pending_attack.intensity |
| weapon | atk.node.get_weapon() | Used to pick attack_type, archetype |
| attack_type | weapon.get_available_attack_types() (non-parry) or move_id | → pending_attack.attack_type |
| archetype | WeaponConstants.get_archetype(weapon.get_archetype_id(attack_type)) | → pending_attack.archetype |
| wind_up_s | _wind_up_duration(intensity, windup_mult) / leg / perf_mod | → pending_attack.wind_up_duration |
| leg | atk.node.get_leg_functionality() (CombatManager uses atk.node) | Affects wind_up_duration only |
| atk_perf_mod | atk.node.get_performance_modifier() | Affects wind_up_duration |

**Combatant state:** atk.state = STATE_WIND_UP, atk.pending_attack = { target_id, intensity, power, follow_through, attack_type, archetype, wind_up_duration }.

**Connection check:** Attacker leg health and performance only affect wind-up duration, not damage. Damage uses intensity and attacker stats later in _execute_attack. OK.

#### 1.2 Execution (_execute_attack) — read from pending_attack

| Data | From | Used for |
|------|------|----------|
| target_id | pa.target_id | Resolve target, targetable parts |
| intensity | pa.intensity | Recovery duration, parry p_a (via attack_instance), damage (attack_instance) |
| attack_type | pa.attack_type | Parry attack_instance, damage attack_instance |
| archetype | pa.archetype | Parry attack_instance, damage (pre_armor, recovery_mult) |
| velocity_override | pa.get("velocity_m_s", -1.0) | **-1 on first hit; set on partial parry re-entry** → parry v_intent (first time) and damage v_m_s |

**Connection check:** All attack parameters flow from the single pending_attack payload. On partial parry re-entry, velocity_m_s is the only extra key; intensity/attack_type/archetype are unchanged and still read from pa (before we clear pending_attack). OK.

#### 1.3 Damage block (after defense / no defense)

| Data | Source | Used for |
|------|--------|----------|
| weapon | atk.node.get_weapon() | All damage math |
| attack_instance | New(attack_type, intensity, archetype, velocity_m_s) | get_effective_velocity_m_s, compute_kinetic_energy_j, pre_armor cut/blunt, penetration |
| velocity_m_s on instance | velocity_override if >= 0 else velocity_m_s_from_intensity(intensity, archetype) | **First hit: from intensity. Partial parry re-entry: from pa.velocity_m_s (reduced).** |
| arm_mod (attacker) | atk.node.get_attack_damage_modifier() | pre_cut_raw, pre_blunt_raw (attacker arm health) |
| atk.stats.strength | Combatant cache (refreshed in _process via _refresh_combatant_stats) | compute_pre_armor_cut/blunt, str_mod in log |

**Connection check:** Partial parry writes attacker.pending_attack["velocity_m_s"] = maxf(v_reduced, v_min). On re-entry, velocity_override is that value, so damage uses reduced velocity. Attack intensity and archetype are still the same locals from the start of _execute_attack. OK.

---

### 2. Parry flow

#### 2.1 Can-parry and capacity (defense choice, _execute_attack)

| Data | Source | Used for |
|------|--------|----------|
| wind_up_duration | pa.get("wind_up_duration", 0.5) | effective_wind_up = wind_up_duration * (1 - COMMITMENT_FRACTION) |
| effective_wind_up | As above | Compare to reaction_time |
| reaction_time | tgt.node.get_passive_parry_reaction_time() | **CoreEntity: perception, consciousness, head pain.** Character → _combat_body. |
| can_parry_in_time | reaction_time < effective_wind_up && def_weapon && atk_weapon | Whether parry is an option |
| atk_weapon | atk.node.get_weapon() | m_a, v_intent → p_a |
| v_intent | WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance) | p_a = m_a * v_intent; **v_intent** is thrust vs swing vs mixed per archetype (**Tier 3.0** in `IMPLEMENTATION_ORDER.md`; `WeaponDamageHelper.kinematic_delivery`) |
| attack_instance (parry) | New(attack_type, intensity, archetype, velocity_override or -1) | **First hit: velocity_override = -1 → full-speed intent for p_a.** Correct. |
| p_a | m_a * v_intent | Attacker momentum; compared to c_d and written on partial parry (reduced v) |
| def_weapon | tgt.node.get_weapon() | m_d for c_d |
| m_d, s_d | def_weapon.mass, tgt.stats.get("strength", 100) | c_d_full = m_d * parry_speed * (s_d / PARRY_STRENGTH_NORM) |
| def_perf | tgt.node.get_performance_modifier() | c_d_full *= perf (pain/consciousness) |
| arm_mod (defender) | tgt.node.get_attack_damage_modifier() | **CoreEntity: get_attacking_arm(), get_arm_functionality(arm), arm pain.** c_d_full *= arm_mod → parry tied to arm health. |
| time_to_react | effective_wind_up - reaction_time | capacity_mult = clamp(time_to_react / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S) |
| parry_readiness | _get_passive_parry_readiness(tgt) | STATE_WAITING=1, RECOVERING=lerp(early, late) |
| parry_off_balance | _is_off_balance(tgt) | c_d *= OFF_BALANCE_PARRY_CAPACITY_MULT if true |
| choose_parry | Expected-damage comparison: parry when E_parry ≤ E_dodge and viable; dodge when E_dodge < E_parry or full_dodge_prob ≥ PARRY_PREFER_DODGE_FULL_THRESHOLD (0.12). PARRY_DODGE_STRENGTH_RATIO (2.2) for block viable. | See AttackResolver |

**Connection check:** Parry uses defender’s **live** arm (get_attack_damage_modifier), **live** performance and reaction time (node methods). Defender strength is from **cached** tgt.stats (refreshed each frame in _process). So parry is correctly tied to arm health, reaction, and strength. OK.

**KE / cut damage:** After parry follow-through, damage uses the same **`v`** pipeline; **`compute_kinetic_energy_j`** matches **`kinematic_delivery`** (thrust point-mass vs swing rotational vs mixed) — see `PARRY_DEFLECT_AND_CALIBRATION.md` §1.2 table, not a single `½ m v²` for all strikes.

#### 2.2 Resolve parry (_resolve_parry_with_momentum)

| Data | Source | Used for |
|------|--------|----------|
| p_a, c_d | Arguments (from _execute_attack) | deflected = (c_d >= p_a * PARRY_DEFLECT_THRESHOLD)  # 1.08 |
| pa | attacker.pending_attack | intensity, attack_type, archetype for attack_instance; **not** velocity_m_s (v_intent = full) |
| v_intent | WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance) | Full intent for v_min = v_intent * PARRY_V_MIN_FRACTION |
| remaining_momentum | p_a - c_d | v_reduced = remaining_momentum / m_a |
| velocity_m_s (partial) | maxf(v_reduced, v_min) | **Written to attacker.pending_attack["velocity_m_s"]** → used on re-entry as velocity_override in damage. |
| _execute_attack(attacker_id) | Called on partial | Re-entry with same pa (plus velocity_m_s, passive_parry_attempted). |

**Connection check:** Partial parry writes the only modified field (velocity_m_s) into pending_attack; re-entry uses it for damage velocity and skips a second defense (already_used_defense). Full deflect clears pending_attack and puts attacker in recovery. OK.

---

### 3. Dodge flow

#### 3.1 Defense choice

| Data | Source | Used for |
|------|--------|----------|
| defense_choice | "parry" if choose_parry else "dodge" | If "dodge", only dodge is attempted; no parry. |
| already_used_defense | pa.get("passive_parry_attempted", false) | If true (partial parry follow-through), skip both dodge and parry → go to damage. |

**Connection check:** One defense per attack; no mixing. OK.

#### 3.2 Dodge roll (when defense_choice == "dodge")

| Data | Source | Used for |
|------|--------|----------|
| dodge_chance | tgt.node.get_dodge_chance() | **CoreEntity: get_leg_functionality(), get_performance_modifier(), leg pain, agility, perception.** Character → _combat_body.get_dodge_chance(). |
| dodge_roll | randf() | Tiers: roll < eff_dodge × DODGE_FULL_THRESHOLD (0.4) → full dodge; roll < eff_dodge → partial (parry_remaining_ratio); else → hit. |

**CoreEntity.get_dodge_chance():**
- leg = get_leg_functionality() (both legs, bone factor)
- perf = get_performance_modifier() (pain/consciousness)
- leg_pain_mod = pain modifier for region "legs"
- dodge_stat_factor = (agility + perception) / 200, clamped 0.5..1.5
- return DODGE_CHANCE_AT_FULL_SPEED (0.10) * dodge_stat_factor * leg * perf * leg_pain_mod

**Connection check:** Dodge is driven by leg health, leg pain, agility, perception, and general performance. All from the defender node (CoreEntity or Character→CombatBody). OK.

---

### 4. Cross-checks

#### 4.1 Partial parry → damage (no second defense)

- _resolve_parry_with_momentum (partial) sets `attacker.pending_attack["velocity_m_s"]` and calls _execute_attack(attacker_id).
- Before that, in _execute_attack we set `pa["passive_parry_attempted"] = true` when choosing parry.
- On re-entry: pa has passive_parry_attempted == true → already_used_defense == true → we skip dodge and parry, log "Partial parry follow-through", then clear pending_attack and run damage.
- Damage uses local velocity_override (read at top of _execute_attack from pa), which is the reduced value. **Connected.**

#### 4.2 Attacker/defender stats

- **Attacker:** atk.stats (strength, etc.) and atk.node (weapon, arm modifier, performance) are used. Stats are refreshed in _process via _refresh_combatant_stats from entity (CoreEntity); node methods are live.
- **Defender:** tgt.stats used for parry strength (cached); tgt.node used for reaction time, weapon, arm modifier, performance, dodge chance (all live). **Consistent.**

#### 4.3 Character vs CoreEntity

- **Character:** Combat-related methods (get_weapon, get_attacking_arm, get_attack_damage_modifier, get_dodge_chance, get_passive_parry_reaction_time, get_leg_functionality, get_performance_modifier, etc.) delegate to _combat_body (CoreEntity). So for party members the data flow is Character → CoreEntity. **Connected.**

---

### 5. Summary

| Flow | Data path | Status |
|------|-----------|--------|
| Attack commit | resolve_action → _begin_attack_with_target → pending_attack (intensity, wind_up_duration, etc.) | OK |
| Attack execute | pending_attack → _execute_attack locals → miss → defense → damage; velocity_override from pa on re-entry | OK |
| Attack damage | weapon, attack_instance (intensity, velocity_override), atk.stats.strength, atk.node.get_attack_damage_modifier() | OK |
| Parry decision | wind_up_duration from pa; reaction_time, def_weapon, atk_weapon from nodes; p_a, c_d with defender arm_mod and strength | OK |
| Parry resolve | p_a, c_d → full or partial; partial writes velocity_m_s, re-calls _execute_attack | OK |
| Parry → damage | Re-entry with already_used_defense, no second defense, velocity_override = reduced | OK |
| Dodge | defense_choice == "dodge" only; get_dodge_chance() from defender node (leg, agility, perception, perf) | OK |
| No mixing | already_used_defense skips defense on partial follow-through; one of dodge or parry per attack | OK |

**Conclusion:** Attack, parry, and dodge data flows are consistent and correctly connected. Partial parry reduces velocity and that velocity is used for damage on re-entry with no second defense roll.

---

<a id="system-integration-status"></a>

## Source: `SYSTEM_INTEGRATION_STATUS.md`

## System Integration Status

Verification that aggressive realism and pain systems are properly integrated. Last updated after integration audit.

---

### Active Systems (Integrated)

| System | Source | Status |
|--------|--------|--------|
| **Damage (cut)** | WeaponConstants.DAMAGE_KE_SCALE 2.0, WeaponDamageHelper | ✓ Used by CombatManager |
| **Damage (blunt)** | WeaponConstants.DAMAGE_MOMENTUM_SCALE 0.42 | ✓ Used by CombatManager |
| **Severance** | CoreEntity.MIN_DAMAGE_TO_SEVER 10 | ✓ Used in take_damage_split |
| **Body parts** | SpeciesResource (human.tres, goblin.tres) | ✓ apply_species() populates body_max, bone_max |
| **Pain reference** | SpeciesResource.get_pain_reference (divisor 32) | ✓ CoreEntity.get_effective_pain_for_thresholds |
| **Combat flow** | BattleScene → CombatManager | ✓ Main battle uses take_damage_split, body parts |

---

### Data Flow

1. **Battle start:** main.gd → BattleScene.start(players, enemies)
2. **Entities:** Character has CombatBody (CoreEntity); Enemy is CoreEntity. Both get species (human.tres / goblin.tres) and call apply_species().
3. **Damage:** `AttackResolver` / `WeaponDamageHelper` compute pre_cut, pre_blunt; the target’s node receives **`take_damage_split(pre_cut, pre_blunt, part, ...)`** only (no single-stream **`take_damage`** on **`CoreEntity`**).
4. **Pain:** CoreEntity.get_total_pain() sums wounds; get_effective_pain_for_thresholds() divides by species.get_pain_reference(body_max).

### Combat Phases

1. **Combat phase:** Fight to the death—attacks only, no medical actions. Bleeding and blood loss tick during combat.
2. **Medical phase (player wins):** When all enemies eliminated, CombatManager emits `enemies_eliminated`; battle continues. Winning side performs medical actions (bandage, direct pressure, tourniquet). Bleeding continues until wounded are stabilized. "End battle" appears when `can_end_medical_phase()` (no one in medical danger).
3. **Enemy wins:** Combat ends immediately; "End battle" shown right away.

---

### Legacy / Unused

| Item | Notes |
|------|-------|
| `CoreEntity.take_damage` / single-stream damage | Removed; use **`take_damage_split`** only. |
| `ui/CombatManager.gd` | Removed; orchestration is **`combat/CombatManager.gd`** + **`ui/BattleScene.gd`**. |

---

### Fallbacks

| Fallback | Value | When used |
|----------|-------|-----------|
| CoreEntity (no species) | body_max 12, bone_max 8 per part | Entity has species = null |
| body_max.get(part, 10) | 10 | Missing part key (edge case) |
| get_pain_reference fallback | 6.0 | body_max sum <= 0 |

---

### Species Files

| File | Tissue (head/chest/arm/leg) | Bone | Sum |
|------|----------------------------|------|-----|
| human.tres | 10/30/12/16 | 8/22/8/12 | 96 |
| goblin.tres | 8/14/5/8 | 5/10/3/4 | 48 |

---

<a id="combat-entity-interface"></a>

## Source: `COMBAT_ENTITY_INTERFACE.md`

## Combat Entity Interface

Nodes that participate in combat (Character, CoreEntity, CombatBody) must implement this interface. Combat systems use `CombatantEntityAccess` to safely call these methods.

### Required Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `get_weapon()` | Weapon or null | Weapon for attack type, damage, parry |
| `get_attacking_arm()` | String | "right_arm", "left_arm", or "" (cowering) |
| `get_attack_damage_modifier()` | float | Arm health × pain modifier for damage |
| `get_performance_modifier()` | float | Pain/consciousness modifier for gauge, hit chance |
| `get_targetable_parts()` | Array | Body parts that can be hit |
| `is_incapacitated()` | bool | Consciousness < threshold or cowering |
| `is_dead()` | bool | Blood loss or vital part destroyed |

### Optional (with defaults)

| Method | Returns | Default | Purpose |
|--------|---------|---------|---------|
| `get_hit_chance_performance_modifier()` | float | get_performance_modifier() | Hit chance specifically |
| `get_action_bar_performance_modifier()` | float | get_performance_modifier() | Gauge fill rate |
| `get_leg_functionality()` | float | 1.0 | Wind-up, dodge, mobility |
| `get_dodge_chance()` | float | 0.0 | Dodge probability |
| `get_part_dodge_modifier(part)` | float | 1.0 | Part-specific dodge |
| `get_passive_parry_reaction_time()` | float | — | Parry timing (needs weapon) |
| `get_armor_for_part(part)` | Variant | null | Armor for damage calc |
| `get_armor_sharp_resistance_for_part(part)` | float | 0.0 | Penetration |
| `get_armor_slots()` | Dictionary | {} | Equipment display |

### Medical

| Method | Purpose |
|--------|---------|
| `get_medical_entity()` | Returns health-holding node (Character → CombatBody); battle code resolves via **`CombatManager.get_health_entity`** / **`CombatantEntityAccess`** |
| `get_blood_volume()` | Blood level |
| `get_total_bleeding_rate()` | Bleeding rate |
| `get_wounded_parts()` | Parts with wounds |
| `can_apply_direct_pressure(part)` | Can hold pressure |
| `apply_direct_pressure(part)` | Apply pressure |
| `clear_direct_pressure()` | Release pressure |
| `is_applying_direct_pressure()` | Currently holding |
| `get_direct_pressure_part()` | Part being held |

### Damage

| Method | Purpose |
|--------|---------|
| `take_damage_split(cut, blunt, part, ...)` | Apply damage (sole entry on **`CoreEntity`** / combat bodies) |
| `process_bleeding(delta)` | Advance bleeding |
| `process_blood_loss(delta)` | Advance blood loss |

### Implementation Notes

- **Character**: Delegates to `_combat_body` (CombatBody/CoreEntity child).
- **CoreEntity**: Implements directly; delegates equipment to EntityEquipment, medical to EntityMedical, etc.
- **CombatantEntityAccess**: Centralized safe access; returns defaults when methods missing.

---

<a id="sharp-penetration-blunt-transmission-plan"></a>

## Source: `SHARP_PENETRATION_BLUNT_TRANSMISSION_PLAN.md`

## Implementation Plan: Sharp = Penetration, Blunt = Transmission

### Overview

Switch the armor system so that:
- **Sharp (cutting):** Penetration model — armor either stops the edge (deflection) or it cuts through (penetration).
- **Blunt:** Transmission-only model — armor never "penetrates" blunt; force always transmits proportionally to the strike.

---

### Phase 1: Audit All Implementation Points

#### 1.1 Damage Flow Entry Points

| Location | Method | Damage Type | Penetration Used |
|----------|--------|-------------|------------------|
| `combat/AttackResolver.gd` | `compute_and_apply_damage` | Split (cut + blunt) | pen_sharp, pen_blunt, pen_blunt_momentum_per_area → **`take_damage_split`** on target node |
| `core/CoreEntity.gd` | `take_damage_split` | Split | Passes to armor / **`EntityDamage`** |
| `character.gd` | Passthrough | — | Forwards **`take_damage_split`** to **`_combat_body`** |
| *(removed)* | Combat.gd was legacy; BattleScene/CombatManager is sole combat system | — | — |
| `tests/TestBattle.gd` | Scripted tests | Split | pen_sharp, pen_blunt (500, 3000, 2500) |

#### 1.2 Armor Processing

| Location | Logic |
|----------|-------|
| `armor/ArmorPiece.gd` | `apply_damage` → `_process_layer` |
| `_process_layer` | SHARP: pen vs sharp_res → penetrate or deflect. BLUNT: pen vs blunt_res → penetrate or deflect. |

#### 1.3 Penetration Computation

| Location | Output |
|----------|--------|
| `weapon/WeaponDamageHelper.gd` | `compute_penetration(DAMAGE_TYPE_SHARP)` → pen_sharp, pen_blunt (deflect) |
| `weapon/WeaponDamageHelper.gd` | `compute_penetration(DAMAGE_TYPE_BLUNT)` → pen_blunt, momentum_per_area (explodes for stabs) |

#### 1.4 Constants

| File | Relevant Constants |
|------|-------------------|
| `armor/ArmorConstants.gd` | `SHARP_DEFLECT_TRANSMISSION_DEFAULT`, `BLUNT_TRANSMISSION_DEFAULT`, `BLUNT_CUSHION_MOMENTUM_THRESHOLD`; layer JSON may still use legacy keys `blunt_bat_transmission` / `deflection_transmission` (see `ArmorPiece.gd` fallbacks) |
| `weapon/WeaponConstants.gd` | `MIN_BLUNT_AREA_M2`, blunt coupling / move defs (obsolete rigid blunt penetration constants removed from code) |

---

### Phase 2: ArmorPiece Changes (Core Logic)

#### 2.1 Add Blunt-Transmission-Only Mode

**File:** `armor/ArmorPiece.gd`

**Current behavior for BLUNT in `_process_layer`:**
- If `pen_mpa < blunt_res` → deflect (transmission)
- Else → penetrate (damage reduction factor)

**New behavior for BLUNT:**
- Always use transmission. Never use penetration branch.
- Remove the `current_pen >= layer_res` penetration path for BLUNT.
- For BLUNT: `after_transmission = damage * transmission`, where transmission = f(layer, momentum_per_area).

**Implementation:**
```gdscript
# In _process_layer, when damage_type == BLUNT:
# ALWAYS deflect (transmission) — never penetrate
if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
    var base_tx: float = layer.get("blunt_transmission", layer.get("blunt_bat_transmission", ArmorConstants.BLUNT_TRANSMISSION_DEFAULT))
    var cushion: float = layer.get("blunt_cushion", 0.0)
    if blunt_momentum_per_area < 0.0 or cushion <= 0.0:
        transmission = base_tx * (1.0 - cushion)
    else:
        var thresh: float = ArmorConstants.BLUNT_CUSHION_MOMENTUM_THRESHOLD
        var momentum_factor: float = clampf(1.0 - blunt_momentum_per_area / thresh, 0.0, 1.0)
        transmission = base_tx * (1.0 - cushion * momentum_factor)
    var after_transmission: float = damage * transmission
    _apply_durability_loss(layer, damage - after_transmission)
    return {"damage": after_transmission, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}
```

**Multi-layer blunt:** Each layer applies transmission. Current loop already processes layer-by-layer; for blunt we never "break" from penetration — we always apply transmission and continue to next layer with reduced damage.

**Critical:** The current loop structure: when blunt "deflects", it continues to inner layers with `damage_remaining` as blunt. We keep that. We just never take the penetration branch for blunt.

#### 2.2 Update `apply_damage` Signature (Optional)

We can keep `penetration_blunt` in the signature for backward compatibility but ignore it for the rigid check. Or remove it from the blunt path. **Recommendation:** Keep signature; document that `penetration_blunt` is ignored for blunt (only `penetration_blunt_momentum_per_area` matters for cushion).

---

### Phase 3: Momentum/Area for Blunt Transmission

#### 3.1 Problem: Explosion for Stabs

`compute_penetration(DAMAGE_TYPE_BLUNT)` returns `momentum_per_area` which can be 300,000+ for stabs. The cushion formula uses it:
`momentum_factor = 1 - momentum_per_area / 3000` → clamps to 0, so cushion fully overwhelmed.

**Options:**
- **A) Cap momentum_per_area** before passing to armor: `min(momentum_per_area, 2 * BLUNT_CUSHION_MOMENTUM_THRESHOLD)` so cushion can still matter for extreme cases.
- **B) Leave as-is** — heavy thrusts overwhelm padding (realistic). No change needed.
- **C) Scale momentum_per_area** for sharp-dominant attacks so it stays in a sensible range.

**Recommendation:** **B** — leave momentum_per_area uncapped. A spear thrust should overwhelm padding. The explosion in pen_blunt is fixed by not using it; momentum_per_area is only for cushion, and 300k overwhelming 3k threshold is correct.

#### 3.2 Ensure momentum_per_area Is Always Provided

For blunt transmission, we need `penetration_blunt_momentum_per_area` for cushion. Currently CombatManager gets it from `compute_penetration(DAMAGE_TYPE_BLUNT)`. We still need that call — but we can simplify it to only return `momentum_per_area` (and optionally remove pen_blunt computation).

---

### Phase 4: WeaponDamageHelper Simplification

#### 4.1 Remove or Simplify Blunt Penetration Computation

**File:** `weapon/WeaponDamageHelper.gd`

**Current:** `compute_penetration(DAMAGE_TYPE_BLUNT)` returns `penetration_blunt` (explodes) and `penetration_blunt_momentum_per_area`.

**New:** 
- Keep `compute_penetration(DAMAGE_TYPE_BLUNT)` but only compute and return `penetration_blunt_momentum_per_area`.
- Return `penetration_blunt: 0.0` or a sentinel — it will be ignored by armor.
- **Alternative:** Add `compute_blunt_momentum_per_area(weapon, attack_instance)` and use that. CombatManager would call it instead of full compute_penetration for blunt.

**Recommendation:** Keep `compute_penetration(DAMAGE_TYPE_BLUNT)` for API consistency. Return `penetration_blunt: 0.0` (or -1.0 to indicate "not used"). The momentum_per_area is the only value used.

---

### Phase 5: CoreEntity.take_damage_split Changes

#### 5.1 Blunt Processing

**File:** `core/CoreEntity.gd`

**Current:** Calls `armor.apply_damage(blunt_pre_val, DAMAGE_TYPE_BLUNT, 0.0, pen_b, penetration_blunt_momentum_per_area, 0)`.

**New:** Same call. Armor will ignore pen_b for the rigid check and always use transmission. No change needed in CoreEntity — the change is entirely in ArmorPiece.

#### 5.2 Deflected Sharp → Blunt

When sharp deflects, we get `deflected_raw`. That is processed as BLUNT with `apply_damage(deflected_raw, DAMAGE_TYPE_BLUNT, 0.0, pen_b, ...)`. The deflected sharp becomes blunt trauma. With blunt=transmission-only, that will use transmission. **No change** — already correct.

---

### Phase 6: CombatManager Changes

#### 6.1 Penetration Computation

**Current:**
```gdscript
var pen_sharp_dict = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_SHARP)
var pen_blunt_dict = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_BLUNT)
pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
pen_blunt = pen_blunt_dict.get("penetration_blunt", -1.0)
pen_blunt_momentum_per_area = pen_blunt_dict.get("penetration_blunt_momentum_per_area", -1.0)
```

**New:** Keep the same. pen_blunt will be 0 or unused; pen_blunt_momentum_per_area is still needed. Optionally stop passing pen_blunt to take_damage_split if we want to clean up — but keeping it avoids signature changes. Armor will ignore it.

#### 6.2 Debug Print

Update the print to not imply pen_blunt matters for blunt: e.g. "pen_sharp=%.2f mm RHA | blunt: transmission only (momentum/A=%.0f)"

---

### Phase 7: ~~CoreEntity.take_damage (Single Stream)~~ **Removed**

**Current code:** `CoreEntity.take_damage` was removed; all combat damage goes through **`take_damage_split`**. Blunt-only strikes use **`take_damage_split(0.0, blunt_pre, part, ...)`** (or cut+blunt as computed). If `penetration_blunt_momentum_per_area` is -1 (not provided), cushion uses base only. **`combat/AttackResolver.gd`** is the combat entry that calls **`take_damage_split`** on the target node.

---

### Phase 8: Physics-Accurate Numbers

#### 8.1 Transmission Values (ArmorConstants)

Current layer values (from code):

| Layer | blunt_bat_transmission | blunt_cushion | deflection_transmission |
|-------|------------------------|---------------|-------------------------|
| Cloth | 0.50 | 0.80 | 0.16 |
| Leather | 0.58 | 0.50 | 0.24 |
| Mail | 0.70 | 0.20 | 0.36 |
| Plate | 0.80 | 0.00 | 0.46 |

**Physics rationale:**
- **Plate:** Rigid, transmits most force (0.80). No cushion (0). Sharp deflection 0.46 — plate stops the cut but transmits ~46% as blunt.
- **Mail:** Transmits trauma (0.70). Little cushion (0.2).
- **Cloth:** Absorbs impact (0.50 blunt, 0.16 sharp deflection). High cushion (0.8).
- **Leather:** Between cloth and mail.

**Verification:** These are already in a sensible order. Plate > mail > leather > cloth for transmission. No changes needed unless tuning.

#### 8.2 BLUNT_CUSHION_MOMENTUM_THRESHOLD

Current: 3000 (kg·m/s)/m².

**Reference:** Mace 1.7 kg, 12 m/s, 8 cm head → p/A ≈ 4080. Above 3000, so cushion overwhelmed. Realistic.

**Recommendation:** Keep 3000. Document that thrusts (high p/A) will overwhelm cushion.

#### 8.3 Sharp Penetration (Unchanged)

Sharp still uses: pen_sharp vs sharp_resistance_rha_mm. PENETRATION_DAMAGE_REDUCTION_MAX = 0.5. J_PER_MM_RHA = 80. All remain as-is.

---

### Phase 9: Test Updates

#### 9.1 TestBattle.gd

**Current calls:**
- `take_damage_split(2.0, 2.0, part, 2.0, 500.0)` — pen_sharp 2, pen_blunt 500
- `take_damage_split(6.0, 6.0, part, 3.0, 3000.0)`
- `take_damage_split(5.0, 3.0, "chest", 2.5, 2500.0)`

**New:** pen_blunt is ignored. Tests should still pass. For blunt transmission, we need momentum_per_area. Currently tests don't pass it — `take_damage_split` has no 4th/5th/6th param for momentum. Checking signature: `take_damage_split(cut_pre, blunt_pre, part, penetration_sharp, penetration_blunt, penetration_blunt_momentum_per_area)`. So 6 params. Tests use 5: `(2.0, 2.0, part, 2.0, 500.0)` — that's cut, blunt, part, pen_sharp, pen_blunt. No momentum. Default -1. So cushion uses base. **Tests will behave differently** — blunt will always use transmission. With pen_blunt 500, currently that might have penetrated some layers. Now it won't. So test outcomes may change. **Update tests** to expect transmission-only blunt. The mangled limb test, severed limb test, chest wounds — verify they still produce expected outcomes. If not, adjust test expectations or add new assertions.

---

### Phase 10: Documentation and Comments

#### 10.1 ArmorPiece

Add header comment:
```
# SHARP: Penetration model. pen_sharp vs sharp_resistance → penetrate or deflect.
# BLUNT: Transmission-only model. Force always transmits; no penetration check.
#       Uses blunt_bat_transmission and cushion (momentum_per_area) for absorption.
```

#### 10.2 ArmorConstants

Update comments to state blunt is transmission-only. blunt_resistance_mpa is no longer used for penetration check; could be repurposed later for durability or kept for reference.

#### 10.3 DAMAGE_PHYSICS_EXPLOSION_FIX_OPTIONS.md

Add note that the chosen fix is "Blunt = Transmission Only" — removes need for pen_blunt entirely.

---

### Implementation Order

1. **ArmorPiece._process_layer** — Implement blunt transmission-only (never penetrate).
2. **WeaponDamageHelper** — Simplify compute_penetration(DAMAGE_TYPE_BLUNT) to only return momentum_per_area; set pen_blunt = 0 or document as unused.
3. **CombatManager** — Update debug print.
4. **Tests** — Run TestBattle; adjust expectations if needed.
5. **Documentation** — Update ArmorPiece, ArmorConstants, plan doc.

---

### Verification Checklist

- [x] Sharp damage: still penetrates or deflects based on pen_sharp vs sharp_res.
- [x] Sharp deflection: converts to blunt, uses transmission through layers.
- [x] Blunt damage: always uses transmission; never penetration branch.
- [x] Blunt cushion: momentum_per_area still affects transmission when cushion > 0.
- [x] Multi-layer armor: blunt applies transmission per layer, damage reduces through stack.
- [x] No pen_blunt explosion: pen_blunt no longer used for rigid check.
- [x] ~~take_damage (single stream)~~ removed; blunt-only uses **`take_damage_split`** with momentum -1 where applicable.
- [x] `take_damage_split`: deflected + direct blunt both use transmission.
- [ ] TestBattle: scripted tests pass or expectations updated (run in Godot editor).
- [x] Unarmed / weaponless paths resolve through **`AttackResolver`** + **`take_damage_split`** (no separate single-stream API).

---

### Rollback

If issues arise: revert ArmorPiece._process_layer to restore blunt penetration branch (pen vs blunt_res). Keep WeaponDamageHelper changes (or revert) as desired. The system is backward-compatible at the API level; only behavior changes.

---

<a id="contact-type-multipliers-integration-investigation"></a>

## Source: `CONTACT_TYPE_MULTIPLIERS_INTEGRATION_INVESTIGATION.md`

## Contact Type Multipliers: Current System & Bind Riposte Integration

### Purpose

Inspect the current contact-type multiplier system, evaluate its physical accuracy, and determine the most physically grounded way to integrate bind riposte wind-up multipliers.

---

### 1. Current Contact-Type Multiplier System

#### 1.1 PARRY_CONTACT_MODIFIERS (CombatConstants)

**What it does:** Modifies parry capacity based on *what the defender parries with* (their parry part).

```gdscript
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.88, "haft": 0.92}
```

| Parry Part | Multiplier | Physics |
|------------|------------|---------|
| blade | 1.0 | Baseline. Blade-on-blade best — flat catches edge, forte controls foible. |
| shaft | 0.88 | Wood shaft vs blade — edge can bite, less control. Spear/mace. |
| haft | 0.92 | Wood haft vs blade — slightly better than shaft (shorter, stiffer?). Axe. |

**Applied in:** `DefenseChoiceResolver._compute_parry_c_d()` — multiplies `c_d_full` after base capacity.

**Physical accuracy:** ✓ Good. Blade is optimal parrying surface; wood is worse. Haft vs shaft difference (0.92 vs 0.88) is plausible — haft often shorter, more rigid.

---

#### 1.2 PARRY_DEF_VS_ATK_MOD (CombatConstants)

**What it does:** Modifies parry capacity based on *defender weapon type vs attacker contact type* (sparse overrides).

```gdscript
const PARRY_DEF_VS_ATK_MOD: Dictionary = {"DAGGER": {"stab": 0.9}, "MACE": {"blunt": 1.05}, "SPEAR": {"cut": 0.95}}
```

| Defender | vs Attacker | Mult | Physics |
|----------|-------------|------|---------|
| DAGGER | stab | 0.9 | Small blade vs thrust — point can slip past, harder to control. |
| MACE | blunt | 1.05 | Shaft absorbs blunt impact; percussion-on-percussion. |
| SPEAR | cut | 0.95 | Long shaft vs cut — blade can slide along or bite into wood. |

**Applied in:** `DefenseChoiceResolver._compute_parry_c_d()` — looks up `def_weapon.weapon_type` + `contact_type`. Missing entries default to 1.0.

**Physical accuracy:** ✓ The three entries are sensible. **Gap:** Sparse — SWORD, AXE have no overrides. Many def×atk combinations use 1.0 (implicit neutral).

---

#### 1.3 Related: redirect_thrust_bonus, redirect_blunt_penalty (DefenseResolutionHandler)

**What they do:** Modify *redirect effectiveness* (partial parry) when shedding momentum.

- Thrust: +22% redirect (point deflects easily)
- Blunt: −12% redirect (momentum harder to shed)

**Scope:** Partial parry path only; does not affect full-stop parry capacity.

---

### 2. Bind Riposte System (Proposed)

**What it does:** Reduces wind-up when defender ripostes from a *bind* (blades in contact, defender in control).

**Proposed constants (from BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION):**
```gdscript
# Wind-up multiplier when riposting from bind. Lower = faster.
const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55   # Extend — minimal wind-up
const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78    # Wind along blade — moderate
const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90   # Swing head — significant wind-up
```

**Phase:** Post-parry, when defender chooses their next attack. Different from parry capacity (pre-parry).

---

### 3. Relationship Between Systems

| System | Phase | Keyed By | Purpose |
|--------|-------|----------|---------|
| PARRY_CONTACT_MODIFIERS | Parry capacity | Defender parry part | How well defender's *weapon* catches attacks |
| PARRY_DEF_VS_ATK_MOD | Parry capacity | def_weapon_type × atk_contact_type | Matchup-specific parry difficulty |
| redirect_thrust/blunt | Partial parry | Attack contact_type | How well momentum sheds |
| PARRY_BIND_RIPOSTE_MULT_* | Riposte wind-up | Defender's *riposte move* contact_type | How fast defender can follow up from bind |

**Key insight:** Parry capacity and bind riposte use contact_type for *different things*:
- **Parry capacity:** Attacker's contact_type (what's coming at defender)
- **Bind riposte:** Defender's chosen move's contact_type (what defender does next)

No overlap — they don't conflict. Integration is additive: add bind riposte constants and logic.

---

### 4. Physical Accuracy: Completing PARRY_DEF_VS_ATK_MOD

**Current:** 3 entries. **Default:** 1.0 for everything else.

**Should we add more?** For physical consistency, consider:

| Defender | vs Stab | vs Cut | vs Blunt | Rationale |
|----------|---------|--------|----------|-----------|
| SWORD | 1.0 | 1.0 | 0.95? | Blade vs blade neutral. Blade vs blunt — edge can chip, less ideal. |
| AXE | 0.92? | 0.92? | 1.0 | Haft vs thrust — point can slip. Haft vs cut — edge bites wood. Haft vs blunt — absorb. |
| MACE | 0.9 | 0.92? | 1.05 ✓ | Shaft vs thrust — slips. vs cut — bites. vs blunt — current. |
| DAGGER | 0.9 ✓ | 1.0 | 0.85? | Small vs thrust — current. vs cut — ok. vs blunt — overwhelmed. |
| SPEAR | 0.95? | 0.95 ✓ | 1.0 | Long vs thrust — point can slip past. vs cut — current. vs blunt — shaft absorbs. |

**Recommendation:** Keep sparse. The three existing entries address the most salient cases. Expanding to 15 entries (5×3) adds maintenance burden; default 1.0 is a reasonable neutral. Add overrides only when balance or realism clearly demands it.

---

### 5. Integration: Bind Riposte into Existing System

#### Option A: Separate Constants (Recommended)

Add bind riposte constants alongside existing parry constants. No changes to PARRY_CONTACT_MODIFIERS or PARRY_DEF_VS_ATK_MOD.

```gdscript
# Bind riposte wind-up (separate from parry capacity). See BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION.
const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55
const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78
const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90
```

**Pros:** Clear separation of concerns. Parry capacity vs riposte speed are different phases. No risk of double-counting.  
**Cons:** None.

---

#### Option B: Unified Contact-Type Table

Create one table for all contact-type–based modifiers:

```gdscript
# Parry/redirect/bind by contact_type. Keys: modifier purpose.
const CONTACT_TYPE_PARAMS: Dictionary = {
    "parry_def_vs_atk": {...},       # def_weapon × atk contact (sparse)
    "redirect_mult": {"stab": 1.22, "cut": 1.0, "blunt": 0.88},
    "bind_riposte_windup": {"stab": 0.55, "cut": 0.78, "blunt": 0.90}
}
```

**Pros:** Single place for contact-type logic.  
**Cons:** Restructure. redirect is currently thrust_bonus + blunt_penalty (additive), not per-type. Would need refactor. Overkill for bind riposte.

---

#### Option C: Extend PARRY_DEF_VS_ATK_MOD for Bind

Reuse PARRY_DEF_VS_ATK_MOD for bind riposte: when defender has parry_was_bind, look up `def_weapon_type` × `riposte_move_contact_type` for wind-up mult.

**Problem:** PARRY_DEF_VS_ATK_MOD keys defender vs *attacker* contact. Bind riposte keys defender's *chosen* move contact. Semantically different. Also, PARRY_DEF_VS_ATK_MOD is parry capacity (× c_d), not wind-up (× time). Would conflate two uses of the same table.

**Verdict:** Don't reuse. Keep bind riposte as its own constants.

---

#### Option D: Parry-Part–Aware Bind Mult (Max Physics)

Combine defender parry part with riposte contact type:

```gdscript
# bind_riposte_mult = f(parry_part, riposte_contact_type)
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
    "blade": {"stab": 0.52, "cut": 0.75},
    "shaft": {"stab": 0.54, "cut": 0.80, "blunt": 0.90},
    "haft": {"stab": 0.53, "cut": 0.78}
}
```

**Pros:** Most physically detailed. Blade thrust from blade bind vs shaft thrust from shaft bind could differ slightly.  
**Cons:** Sparse matrix (blade/haft have no blunt riposte). More constants. Marginal gain over contact-type-only (stab 0.55, cut 0.78, blunt 0.90) for 5 weapons.

**Verdict:** Option A (contact-type only) is sufficient. Add Option D only if tuning shows parry-part matters.

---

### 6. Recommended Integration (Most Physically Accurate)

#### 6.1 Keep Current Systems As-Is

- **PARRY_CONTACT_MODIFIERS:** No change. Blade/shaft/haft already reflect parry-part physics.
- **PARRY_DEF_VS_ATK_MOD:** No change. Sparse overrides for salient cases; 1.0 default is fine.
- **redirect_thrust/blunt:** No change. Handles partial parry correctly.

#### 6.2 Add Bind Riposte (Option A)

1. **CombatConstants.gd:**
   ```gdscript
   # Bind riposte wind-up. Defender's riposte move contact_type — extend=fast, swing=slow.
   const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55
   const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78
   const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90
   # Or as dict for lookup: PARRY_BIND_RIPOSTE_MULT_BY_CONTACT
   ```

2. **Eligibility:** Only when move's contact_type is in weapon's bind-riposte-eligible set (from parry moves). Axe: add `bind_riposte_contact_types: ["cut", "stab"]` for spike.

3. **AttackWindUpStarter:** After `wind_up_s *= trans_mult`, if bind conditions + eligibility: `wind_up_s *= get_bind_riposte_mult(contact_type)`.

#### 6.3 Optional: Weapon Overrides for Edge Cases

If tuning shows need:
```gdscript
const PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE: Dictionary = {
    "MACE": 0.92,   # Shaft bind + blunt = heaviest follow-up
    "DAGGER": 0.50  # Lightest; thrust dominant
}
```
Use override when present; else contact-type mult.

---

### 7. Summary

| System | Action | Rationale |
|--------|--------|-----------|
| PARRY_CONTACT_MODIFIERS | Keep | Already physically sound |
| PARRY_DEF_VS_ATK_MOD | Keep sparse | Default 1.0 is fine; add only when needed |
| Bind riposte | Add new constants | Separate phase; contact-type mults (0.55/0.78/0.90) match extend vs wind vs swing |
| Parry-part × contact matrix | Skip for now | Marginal benefit; contact-type-only is enough |

**Most physically accurate integration:** Add `PARRY_BIND_RIPOSTE_MULT_*` (or `PARRY_BIND_RIPOSTE_MULT_BY_CONTACT` dict) as a separate concern. Use defender's riposte move's `contact_type` for lookup. Do not merge with PARRY_DEF_VS_ATK_MOD or PARRY_CONTACT_MODIFIERS.

---

<a id="subregion-multiplier-audit"></a>

## Source: `SUBREGION_MULTIPLIER_AUDIT.md`

## Sub-Region × Part Multiplier Audit

Computed combined values when part and sub-region multipliers are multiplied together. Verifies consistency and flags any issues.

---

### 1. Pain (PainConsciousnessConstants)

**Formula:** `part_mult × sub_mult` (both applied multiplicatively)

| Part | Sub-region | Part | Sub | **Combined** | Notes |
|------|------------|------|-----|--------------|-------|
| head | scalp | 1.4 | 1.3 | **1.82** | Scalp: many nerves |
| head | face | 1.4 | 1.4 | **1.96** | Face: highest pain (trigeminal) |
| head | neck | 1.4 | 1.35 | **1.89** | Neck: vascular, less sensory |
| chest | thoracic | 1.25 | 1.2 | **1.50** | Ribs: more painful |
| chest | abdominal | 1.25 | 1.15 | **1.44** | Soft tissue |
| arm | upper_arm | 1.0 | 0.95 | **0.95** | |
| arm | elbow | 1.0 | 1.1 | **1.10** | Joint |
| arm | forearm | 1.0 | 1.05 | **1.05** | |
| arm | hand | 1.0 | 1.35 | **1.35** | High nerve density |
| leg | thigh | 0.95 | 0.95 | **0.90** | |
| leg | knee | 0.95 | 1.1 | **1.05** | Joint |
| leg | calf | 0.95 | 1.0 | **0.95** | |
| leg | foot | 0.95 | 0.9 | **0.86** | Lowest pain |

**Verdict:** ✓ Ordering is medically plausible. Face > neck > scalp for pain. Hand highest on limbs. Foot lowest.

---

### 2. Bleeding (BleedingConstants)

**Formula:** `part_mult × sub_mult` (BODY_PART_BLEEDING × SUB_REGION_BLEEDING)

| Part | Sub-region | Part | Sub | **Combined** | Notes |
|------|------------|------|-----|--------------|-------|
| head | scalp | 1.5 | 1.8 | **2.70** | Scalp very vascular |
| head | face | 1.5 | 1.4 | **2.10** | |
| head | neck | 1.5 | 1.6 | **2.40** | Carotid/jugular |
| chest | thoracic | 1.2 | 1.15 | **1.38** | |
| chest | abdominal | 1.2 | 1.25 | **1.50** | More vessels |
| arm | upper_arm | 1.0 | 0.9 | **0.90** | |
| arm | elbow | 1.0 | 1.0 | **1.00** | |
| arm | forearm | 1.0 | 1.15 | **1.15** | UE vessels |
| arm | hand | 1.0 | 1.05 | **1.05** | |
| leg | thigh | 1.0 | 1.1 | **1.10** | |
| leg | knee | 1.0 | 1.2 | **1.20** | Popliteal |
| leg | calf | 1.0 | 1.05 | **1.05** | |
| leg | foot | 1.0 | 0.95 | **0.95** | |

**Verdict:** ✓ Scalp (2.70) > neck (2.40) > face (2.10). Scalp bleeds profusely. Consistent.

---

### 3. Arterial Chance (BleedingConstants)

**Formula:** `ARTERIAL_BODY_PART_MULTIPLIERS × SUB_REGION_ARTERIAL_MULTIPLIERS`

| Part | Sub-region | Part | Sub | **Combined** | Notes |
|------|------------|------|-----|--------------|-------|
| head | scalp | 1.4 | 1.2 | **1.68** | |
| head | face | 1.4 | 1.1 | **1.54** | |
| head | neck | 1.4 | 1.5 | **2.10** | Highest - carotid |
| chest | thoracic | 1.2 | 1.15 | **1.38** | |
| chest | abdominal | 1.2 | 1.2 | **1.44** | |
| arm | upper_arm | 1.0 | 0.95 | **0.95** | |
| arm | forearm | 1.0 | 1.2 | **1.20** | UE vascular |
| arm | hand | 1.0 | 0.9 | **0.90** | |
| leg | thigh | 1.0 | 1.15 | **1.15** | SFA |
| leg | knee | 1.0 | 1.15 | **1.15** | Popliteal |

**Verdict:** ✓ Neck (2.10) highest for arterial. Medically correct.

---

### 4. Stump Bleeding (BleedingConstants)

**Formula:** `part × sub × stump_level` (third multiplier for amputation level)

Example: right_arm upper_arm stump = 1.0 × 0.9 × 1.22 = **1.10**
Leg thigh stump = 1.0 × 1.1 × 1.2 = **1.32**

Proximal (upper_arm, thigh) > distal (hand, foot). ✓

---

### 5. Severity (BleedingConstants)

**Sub-region only** (no part-level). Used as: `effective_damage = damage × severity_mod`

| Part | Sub-region | Severity mod | Notes |
|------|------------|--------------|-------|
| head | scalp | 1.25 | Thin over bone |
| arm | elbow | 1.15 | Less tissue |
| arm | hand | 1.1 | Smaller cross-section |
| leg | knee | 1.1 | Less tissue |
| leg | foot | 1.1 | Smaller |

**Verdict:** ✓ Thin tissue = higher effective damage = severity reached sooner.

---

### 6. Potential Issues Found

#### Issue A: BleedingConstants empty sub_region fallback

When `sub_region` is provided but not found in the dict, `get(sub_region, 0.0)` returns 0.0. The condition `> 0.0` causes the sub-region multiply to be **skipped** (part_mult only). This is correct fallback behavior. ✓

#### Issue B: Pain head face = 1.4 × 1.4

Face sub-region (1.4) equals head part (1.4). Combined = 1.96. This is intentional: face is the most painful part of the most painful region. ✓

#### Issue C: Leg part 0.95 creates asymmetry

Leg thigh = 0.95 × 0.95 = 0.90. Arm upper_arm = 1.0 × 0.95 = 0.95. So leg thigh is slightly less painful than arm upper_arm. Plausible (thigh has more muscle mass, less nerve density than hand). ✓

---

### 7. Cross-System Consistency

| Region | Pain rank | Bleeding rank | Arterial rank |
|--------|-----------|---------------|---------------|
| head/face | 1 (1.96) | 2 (2.10) | 2 (1.54) |
| head/scalp | 3 (1.82) | 1 (2.70) | 3 (1.68) |
| head/neck | 2 (1.89) | 3 (2.40) | 1 (2.10) |

Scalp bleeds most, face hurts most, neck most arterial. ✓ Medically consistent.

---

### 8. Summary

All part × sub-region multiplications are applied correctly. No bugs found. Ordering is medically plausible. No changes required.

---

<a id="researched-numbers-health-system-coherence"></a>

## Source: `RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md`

## Researched Numbers vs. Health System Coherence

This document audits whether the aggressive realism constants (DAMAGE_KE_SCALE 2.0, MIN_DAMAGE_TO_SEVER 10, limb totals) are appropriate for each health system in the project.

---

### 1. Tissue / Bone / Blunt Pools (CoreEntity)

| System | Constants | Coherence |
|--------|-----------|-----------|
| body_cutting, body_blunt | body_max from SpeciesResource | ✓ Arm 12, leg 16 tissue; bone 8/12. Correctly initialized. |
| bone_health | bone_max from SpeciesResource | ✓ Matches bone thresholds in BodyPartConstants. |
| Severance | MIN_DAMAGE_TO_SEVER 10 | ✓ Blocks weak hits; 10 damage ≈ 25 J floor. |
| Early severance | combined_max = body_max + bone_max | ✓ Arm 20, leg 28. remaining_ratio uses rem_cut + rem_bone. Correct. |
| Severance ease | tissue_ratio = (cur_cut + cur_blunt) / (max_tissue * 2) | ✓ Both pools start at max_tissue; combined max = 2×. Correct. |

**Verdict:** Tissue, blunt, and bone pools are coherent with researched limb totals.

---

### 2. Bone Damage (BodyPartConstants)

| Part | Threshold | Fraction | With damage scale 2.0 |
|------|-----------|----------|------------------------|
| head | 3 | 0.55 | First bone at 3 damage (~2.25 J); full break ~18 total |
| arm | 5 | 0.38 | First bone at 5 (~6.25 J); full break ~26 total (~169 J) |
| leg | 6 | 0.42 | First bone at 6 (~9 J); full break ~35 total (~306 J) |
| chest | 8 | 0.30 | First bone at 8 (~16 J) |

**Research:** Arm bones 12–45 J fracture; leg 25–35 J. Thresholds (3–8) represent "first involvement"; full break requires higher total. Sub-region thresholds (elbow 3, hand 4) add granularity.

**Verdict:** Bone thresholds are in abstract damage units; they scale with DAMAGE_KE_SCALE. No change needed.

---

### 3. Severity & Bleeding (BleedingConstants)

| Constant | Value | With new part maxes |
|----------|-------|---------------------|
| SEVERITY_PERCENTAGE_MODERATE | 0.25 | Arm 12: 3 damage = moderate |
| SEVERITY_PERCENTAGE_SEVERE | 0.5 | Arm 12: 6 damage = severe |
| SEVERITY_PERCENTAGE_CRITICAL | 0.75 | Arm 12: 9 damage = critical |
| SEVERITY_ABSOLUTE_MINOR | 2 | Overrides % for tiny hits on large parts |
| SEVERITY_ABSOLUTE_SEVERE | 5 | 5+ damage = at least severe |
| SEVERITY_ABSOLUTE_CRITICAL | 10 | 10+ damage = at least critical |

**Interaction:** Severity = max(percentage-based, absolute). For chest (max 30): 10 damage = 33% (moderate) vs absolute 10 (critical) → critical. A 10-damage hit (~25 J) on chest can be a deep wound; critical is plausible.

**Verdict:** Severity thresholds are appropriate. Absolute 2/5/10 scale with damage; typical sword ~31, so 10 is a solid hit.

---

### 4. Pain & Consciousness (PainConsciousnessConstants, SpeciesResource)

| System | Before (body_max sum 112) | After (body_max sum 96) | Issue |
|--------|---------------------------|-------------------------|-------|
| pain_reference | 112/18.7 ≈ 6.0 | 96/32 ≈ 3.0 | ~2 moderate hits to first effect (research-aligned) |
| NRS first effect | 4 | 4 | ~4 moderate hits to reach |
| Intended behavior | 1 moderate hit ≈ 1 effective pain | 1 moderate hit ≈ 1.2 effective | Pain effects trigger ~20% sooner |

**Research-aligned fix:** Divisor **32** (PAIN_MEDICAL_RESEARCH_SYNTHESIS.md). Human ref = 96/32 = 3. ~2 moderate hits to NRS 4 (first effect). Krebs: NRS 4-6 = 2.67× functional impairment; acute trauma 57% present NRS 5-10.

**Goblin:** 48/32 = 1.5. Smaller species = lower ref = pain effects trigger sooner (realistic).

---

### 5. Pain Shock (PainConsciousnessConstants)

| Constant | Value | With scale 2.0 |
|----------|-------|----------------|
| PAIN_SHOCK_DURATION_IMPACT_REFERENCE | 10.0 | 10 damage = 1.0× duration |
| Typical sword hit | ~31 damage | 31/10 = 3.1×, capped at 2.0× |
| IMPACT_MAX_MULTIPLIER | 2.0 | Heavy hits double shock duration |

**Verdict:** Impact reference 10 is appropriate. Typical hits (15–35 damage) scale shock duration correctly.

---

### 6. Healing (HealingConstants)

Healing durations are severity-based (minor/moderate/severe/critical), not damage-scale. Same severity → same duration. No change needed.

---

### 7. Blood Volume (BleedingConstants)

Death at BLOOD_LOSS_DEATH_THRESHOLD (35%); critical at 30%. These are percentage-based. Bleeding rates scale with severity. No change needed.

---

### Summary of Required Adjustments

| Adjustment | File | Change |
|------------|------|--------|
| Pain reference divisor | SpeciesResource.gd | 32 (human ref=3; ~2 moderate hits to first effect; research-aligned) |

All other systems are coherent with the researched numbers.

---

<a id="combat-numbers-realism-audit"></a>

## Source: `COMBAT_NUMBERS_REALISM_AUDIT.md`

## Combat Numbers: Realism Audit (Post-Parry Changes)

This document checks that current constants and formulas still align with real-world combat research after the parry/dodge tweaks and parry improvements. References: existing docs (RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md, COMBAT_PARRY_MISS_RESEARCH.md, BodyPartConstants, ArmorConstants), and typical research ranges for reaction time and strike velocity.

---

### 1. Strike and parry velocity (m/s)

| Constant / value | In-game | Research / reality | Verdict |
|------------------|--------|---------------------|--------|
| VELOCITY_MIN_M_S / VELOCITY_MAX_M_S | 6–24 m/s | Rod-like / longsword strikes often cited **17–24 m/s** at impact; slower for telegraphed or weak blows. | **OK.** Min 6 gives weak attacks; max 24 matches upper end of typical strike speeds. |
| Parry base speed | 24 × 0.5 = **12 m/s** | Defensive move is positioning, not full strike; **~40–60% of strike** is common in design notes. | **OK.** 50% of 24 = 12 m/s is within band. |
| Per-weapon parry factor | Dagger 1.2, Mace 0.9, Sword/Axe/Spear 1.0/0.95/1.0 | Lighter blade = quicker defensive move; heavy mace = slower to reposition. | **OK.** Directionally correct; factors are modest (0.9–1.2). |
| PARRY_V_MIN_FRACTION (partial) | 0.2 (20% residual) | Partial parry often leaves a glancing hit; 20% of intent velocity is a reasonable floor. | **OK.** |
| PARRY_V_MIN_NEAR_DEFLECT | 0.1 (10% when c_d ≈ p_a) | “Almost deflected” should leave less energy; 10% floor is more realistic than 20% for near-miss parries. | **OK.** |

---

### 2. Reaction and parry timing (seconds)

| Constant / value | In-game | Research / reality | Verdict |
|------------------|--------|---------------------|--------|
| PASSIVE_PARRY_BASE_REACTION_S (EntityPainConsciousness) | **0.24 s** (240 ms) | Simple visual reaction time **~180–250 ms** typical. Base 0.24 s places “notice attack” in the research band. | **OK.** Matches typical visual RT range. |
| PARRY_BLADE_MOVEMENT_S | **0.13 s** | Explosive cut duration in research **250–350 ms**; defensive blade move is a shorter repositioning. 130 ms is plausible for “blade into line.” | **OK.** |
| PASSIVE_PARRY_MIN_TIME_FOR_FULL_S | 0.25 s | Time *after* reaction to achieve full parry capacity. 0.25 s to get full capacity is reasonable. | **OK.** |
| Blade movement mult (mass/strength) | 0.5–2.0× base | Heavy weapon / weak user = slower into position; light / strong = faster. | **OK.** Directionally correct. |

---

### 3. Impulse and parry physics (p_a, c_d)

| Formula / constant | In-game | Research / reality | Verdict |
|--------------------|--------|---------------------|--------|
| p_a = m × v (momentum) | kg·m/s | Standard: impulse = mass × velocity. | **OK.** |
| c_d = m_d × v_parry × (strength/100) | Capacity scales with defender mass, parry speed, strength. | Parry “capacity” as impulse-like (force × time or momentum) is a reasonable abstraction for blade meeting blade. | **OK.** |
| PARRY_DEFLECT_THRESHOLD = 1.08 | Full deflect when c_d ≥ p_a × this. | “Match” impulse for full stop is a simple, plausible rule. | **OK.** |
| Time-of-intercept p_a (velocity curve) | p_a = m_a × v_intent × progress² (early parry → lower progress → lower p_a). | Blade accelerates into impact; early contact meets less momentum. | **OK.** Aligns with real kinematics. |
| Agility scaling c_d | c_d × clamp(agi/100, 0.7, 1.3). | Faster defenders get blade into position more effectively; no direct citation but consistent with “quicker = better parry.” | **OK.** Modest range. |

---

### 4. Wind-up, recovery, and commitment

| Constant | In-game | Research / reality | Verdict |
|----------|--------|---------------------|--------|
| WIND_UP_BASE_S + scale | ~0.25 + 0.6×intensity → ~0.37–0.85 s | “Standard” cut **600+ ms**; “explosive” **250–350 ms**. Our wind-ups span that range. | **OK.** |
| COMMITMENT_FRACTION | 0.2 | First 20% of wind-up = telegraph before attack “counts” for defender reaction. | **OK.** |
| OFF_BALANCE_DURATION_S | 0.4 s | Short window after miss/deflect; plausible. | **OK.** |
| PARRY_BONUS_AFTER_DEFLECT_S | 2.0 s | Short “ready” bonus after successful deflect; no direct research; gameplay tuning. | **OK.** |

---

### 5. Miss, dodge, and hit chance

| Constant | In-game | Research (COMBAT_PARRY_MISS_RESEARCH.md) | Verdict |
|----------|--------|-------------------------------------------|--------|
| MISS_CHANCE_BASE | 0.06 (6%) | No direct melee “miss %”; HEMA suggests most exchanges end in *some* contact. Low miss is plausible. | **OK.** |
| DODGE_CHANCE_AT_FULL_SPEED | 0.10 | “Modest” dodge; research doesn’t give a number. | **OK.** (HEMA §8) |
| Dodge floor (if added) | Optional 1–2% | Small floor for “flinch” avoids 0% when badly injured; realism trade-off. | **Design choice.** |

---

### 6. Damage, penetration, and armor

| Constant / system | In-game | Research / reality | Verdict |
|-------------------|--------|---------------------|--------|
| J_PER_MM_BASE (55) | Williams-style: ~55 J per 1 mm mild steel equivalent. | Williams (Knight & Blast Furnace) and similar penetration models use this order of magnitude for armor steel. | **OK.** (Citation in WeaponConstants/ArmorConstants.) |
| PENETRATION_EXPONENT | 0.6 (≈ 1/1.67) | Thicker armor needs disproportionately more energy. | **OK.** |
| DAMAGE_KE_SCALE | 2.0 | Tuned so ~100 J arm, ~200 J leg for severance (RESEARCHED_NUMBERS, SpeciesResource). | **OK.** |
| MIN_DAMAGE_TO_SEVER | 10 | Blocks trivial severance; ~25 J floor. | **OK.** |
| Body part weights (targeting) | BodyPartConstants | Based on surface area / exposure (e.g. NCBI). | **OK.** |
| Bone thresholds | BodyPartConstants | Skull/femoral/tibial fracture energy ranges cited in comments. | **OK.** |
| BLUNT_CUSHION_MOMENTUM_THRESHOLD | 3000 (kg·m/s)/m² | Example: mace 1.7 kg, 12 m/s, 8 cm → p/A ≈ 4080; above threshold. | **OK.** |

---

### 7. Technique variance and post-deflect bonus

| Change | In-game | Realism note | Verdict |
|--------|--------|--------------|--------|
| PARRY_TECHNIQUE_VARIANCE | ±10% on c_d | Timing/placement vary; ±10% is modest. | **OK.** |
| Agility reduces variance | High agility → lower variance (down to ±5%). | Skilled fighters more consistent; plausible. | **OK.** |
| Post-deflect +10% capacity, 2 s | Defender “ready” after full deflect. | Readiness after successful parry is attested in fencing; 2 s and 10% are tuning. | **OK.** |

---

### 8. Summary: values still align with real-life combat

- **Velocity:** 6–24 m/s and parry at ~50% of max (with per-weapon 0.9–1.2) match typical strike/parry speed ranges and “defensive move slower than strike” idea.
- **Reaction:** 0.24 s (240 ms) “notice attack” is in the typical visual RT band (180–250 ms). Blade movement 0.13 s and mass/strength scaling are plausible.
- **Impulse/parry:** p_a and c_d use standard momentum; time-of-intercept (progress²) and full-deflect threshold 1.08 are consistent with real kinematics and HEMA-style blade-blade outcomes.
- **Damage/armor:** Existing research-backed numbers (55 J/mm, bone thresholds, KE scale, severance) are unchanged and still coherent.
- **Miss/dodge:** Low base miss (6%) and modest dodge (10%) remain in line with COMBAT_PARRY_MISS_RESEARCH.md and HEMA “most contacts are defended or blade-blade” (57–80% defended for longsword).

No constant changes are **required** for realism. Optional tuning only:

- If you want parry to sit more in the **57–80% defended** band (HEMA), the main levers are how often defenders **choose** parry and **succeed** (e.g. reaction window, PARRY_DODGE_STRENGTH_RATIO, or species perception/strength), not the raw velocity/reaction numbers above.
- If you add a **dodge floor** (e.g. 1%), it slightly diverges from “pure” realism for badly injured defenders but improves feel; document as a design choice.

---

### 9. References in codebase

- RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md — tissue/bone/severance/pain coherence.
- COMBAT_PARRY_MISS_RESEARCH.md — HEMA blade-blade %, miss/dodge plausibility.
- BodyPartConstants.gd — bone thresholds (skull 4–23 J, femoral ~35 J, etc.).
- WeaponConstants.gd — “Research: rod-like strikes 17.2–24.2 m/s”; Williams 55 J/mm.
- ArmorConstants.gd — Williams 50 J for 16 layers linen; blunt cushion threshold.
- EntityPainConsciousness.gd — PASSIVE_PARRY_BASE_REACTION_S 0.24; DODGE_CHANCE_AT_FULL_SPEED (see §8 of COMBAT_PARRY_MISS_RESEARCH for dodge realism).

---

<a id="goblin-stats-realism"></a>

## Source: `GOBLIN_STATS_REALISM.md`

## Goblin Stats: Realism Rationale

Baseline: **Human** = 100 all stats (species average). **Goblin** = small humanoid; fantasy norms (D&D, Pathfinder) and the in-game description ("Small, sneaky, and quick") drive the targets below.

---

### Reference (fantasy norms)

- **Size:** Small humanoid (~3–4 ft). Smaller than human → less mass, shorter levers.
- **Strength:** Low. D&D 5e Goblin Str 8 (−1). Raw strength scales with size/mass.
- **Agility / Dexterity:** High. D&D Dex 14 (+2). Nimble, evasive, quick to act.
- **Perception / awareness:** Often high for scouts and ambush; “sneaky” implies good situational awareness.
- **Intelligence:** Often below average; crafty but not scholarly.
- **Endurance:** Smaller body → less stamina reserve; often below average.

---

### Stat targets (50–150 scale, 100 = human average)

| Stat        | Before | After | Rationale |
|------------|--------|--------|-----------|
| **Strength** | 65   | **60** | Small = weak. 60% of human keeps them clearly weaker; D&D Str 8 is very low. |
| **Agility**  | 125  | **115** | Nimble and quick, but 125 was 25% above human (cartoonishly fast). 115 = clearly faster (gauge fill, dodge, recovery) without being superhuman. |
| **Intelligence** | 70 | **70** | Crafty, opportunistic; not scholars. Unchanged. |
| **Endurance**   | 70 | **70** | Less stamina and pain reserve than human. Unchanged. |
| **Perception**  | 80 | **90** | “Sneaky” and alert; 90 puts reaction time in parry range (0.24/0.9 ≈ 0.27 s) and fits scouts/ambush. |

---

### Body proportions (unchanged)

- **Top-heavy, spindly limbs:** head 8, chest 14, arms 5 each, legs 8 each (total 48 vs human 96).
- Head share ~17% vs human ~10%; arm share ~21% vs human ~25%. Matches “large head/chest share, thin arms/legs.”
- Smaller total tissue → higher pain per hit (pain_reference scale), faster death to limb focus. **Realistic.**

---

### In-game impact

- **Strength 60:** Slightly lower damage and parry capacity; still can use weapons and parry when in time.
- **Agility 115:** Still faster than human (gauge fill, dodge, recovery); no longer 125.
- **Perception 90:** Reaction ~0.24 s; can parry in time vs typical wind-ups; better dodge factor and attacker hit chance when they attack.

---
