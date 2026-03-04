# Parry System: Speed and Other Improvement Options

This document investigates ways to improve **parry speed** (defender’s effective parry capacity) and other **parry system** improvements. Current behavior is summarized first, then options with touchpoints and tradeoffs.

---

## Current Parry Summary

- **Capacity:** `c_d = m_d * v_parry * (strength/100) * perf * arm_mod * capacity_mult * readiness * [off_balance]`.  
  `v_parry` is a **global constant** (`VELOCITY_MAX_M_S * 0.5` ≈ 12 m/s); defender weapon only contributes **mass** `m_d`.
- **Attacker momentum:** `p_a = m_a * v_intent` (full intent velocity; no velocity curve at intercept time).
- **Choice:** Parry is chosen when `can_parry_in_time` and expected-damage comparison (PARRY_DODGE_STRENGTH_RATIO 2.2 for block viable).
- **Resolve:** Full deflect if `c_d >= p_a * PARRY_DEFLECT_THRESHOLD` (1.08); else partial (reduced velocity, then damage).
- **Unused constants:** `PARRY_BLADE_MOVEMENT_S`, `PARRY_MOVEMENT_MASS_STRENGTH_MIN/MAX` are defined but not used (design intent: blade movement time scaled by mass/strength).

---

## 1. Parry Speed Improvements

### 1.1 Per-weapon parry speed factor (recommended)

**Idea:** Defender weapon can scale parry speed. E.g. dagger = quicker blade movement (1.2×), mace = slower defensive positioning (0.85×). Then `v_parry = BASE_PARRY_SPEED * weapon_parry_factor(def_weapon)`.

**Touchpoints:**

- `weapon/WeaponConstants.gd`: in weapon definitions, add optional `parry_speed_factor: float` (default 1.0). E.g. DAGGER 1.2, MACE 0.9, SWORD/SPEAR 1.0.
- `weapon/Weapon.gd`: add property and read from definition in `create_from_definition`.
- `ui/CombatManager.gd`: change `_get_parry_speed_m_s()` to accept optional `def_weapon`; if present and has `parry_speed_factor`, return `WeaponConstants.VELOCITY_MAX_M_S * PARRY_V_FRACTION_OF_MAX_STRIKE * def_weapon.parry_speed_factor`. Call site already has `def_weapon` when computing `c_d_full`.

**Pros:** Light weapons feel quicker to parry with; heavy/clunky weapons slightly worse. No change to stats.  
**Cons:** One new optional field per weapon; need to tune factors.

---

### 1.2 Agility scaling parry speed

**Idea:** Faster defenders get a higher effective parry speed (blade movement). `v_parry_effective = v_parry_base * clamp(agility/100, 0.7, 1.3)` (or similar).

**Touchpoints:**

- `ui/CombatManager.gd`: when computing `c_d_full`, multiply by an agility factor from defender: e.g. `var agi: float = float(tgt.stats.get("agility", 100)); c_d_full *= clampf(agi / 100.0, 0.7, 1.3)`.

**Pros:** One stat (agility) improves both recovery and parry capacity; no new data.  
**Cons:** Agility already affects dodge and recovery; may make high-agi defenders very strong defensively.

---

### 1.3 Use blade movement time (implement existing design)

**Idea:** The comment and constants say parry has “reaction + blade movement (scaled by mass/strength)”. Currently only `time_to_react = effective_wind_up - reaction_time` is used for `capacity_mult`. Subtract the time needed to move the blade into position: `blade_time = PARRY_BLADE_MOVEMENT_S * clamp(m_d / (s_d/100), PARRY_MOVEMENT_MASS_STRENGTH_MIN, PARRY_MOVEMENT_MASS_STRENGTH_MAX)`. Then `effective_time_to_parry = time_to_react - blade_time`, and use that (clamped ≥ 0) in `capacity_mult` instead of `time_to_react`.

**Touchpoints:**

- `ui/CombatManager.gd`: where `parry_time_to_react` and `parry_capacity_mult` are set, compute `blade_movement_s = PARRY_BLADE_MOVEMENT_S * clampf((m_d * PARRY_STRENGTH_NORM / maxf(1.0, s_d)), PARRY_MOVEMENT_MASS_STRENGTH_MIN, PARRY_MOVEMENT_MASS_STRENGTH_MAX)` (heavy weapon / weak user = larger mult = more time). Then `effective_parry_time = maxf(0.0, parry_time_to_react - blade_movement_s)` and `parry_capacity_mult = clampf(effective_parry_time / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0.0, 1.0)`.

**Pros:** Matches existing design; light weapon + strong user parries “into position” faster.  
**Cons:** Slightly more complex; heavy weapons / weak defenders get noticeably less capacity.

---

### 1.4 Species parry speed multiplier

**Idea:** SpeciesResource gets optional `parry_speed_mult` (default 1.0). Small/fast species (e.g. Goblin) get 1.1 so their capacity scales up without touching strength.

**Touchpoints:**

- `species/SpeciesResource.gd`: `@export var parry_speed_mult: float = 1.0`.
- `core/CoreEntity.gd`: add helper e.g. `get_parry_speed_multiplier() -> float` returning `species.parry_speed_mult` if set else 1.0.
- `ui/CombatManager.gd`: when computing `c_d_full`, if defender node has `get_parry_speed_multiplier`, multiply `c_d_full` by it (or pass into parry speed so it’s one place).

**Pros:** Per-species tuning; can help weak-but-quick species parry a bit more.  
**Cons:** New field; overlaps with “raise perception/strength” for similar outcomes.

---

## 2. Other Parry System Improvements

### 2.1 Time-of-intercept momentum (early parry meets less p_a)

**Idea:** The design comment says “early parry meets less momentum” (velocity curve). Currently `p_a = m_a * v_intent` uses full intent velocity. At the moment the defender’s parry “contacts” the attack, the blade is still accelerating; use a progress-based velocity so `p_a = m_a * v_intent * _velocity_curve_factor(progress)`. Progress could be derived from “when” the defender gets their blade there: e.g. `progress = 1.0 - (parry_time_to_react / effective_wind_up)` (early in wind-up → low progress → low p_a).

**Touchpoints:**

- `ui/CombatManager.gd`: when setting `parry_p_a`, compute `parry_progress = clampf(1.0 - (parry_time_to_react / maxf(0.001, effective_wind_up)), 0.0, 1.0)` then `parry_p_a = m_a * v_intent * _velocity_curve_factor(parry_progress)`. Use the same `parry_p_a` for choose_parry and for _resolve_parry_with_momentum.

**Pros:** Early, reactive parries face lighter momentum; rewards fast reaction.  
**Cons:** Need to keep p_a consistent for both choice and resolve; slightly more logic.

---

### 2.2 Softer partial parry (residual velocity scales with how close c_d was to p_a)

**Idea:** Currently partial parry: `v_reduced = (p_a - c_d) / m_a`, then clamped to `v_min = v_intent * PARRY_V_MIN_FRACTION`. So a “near deflect” (c_d just below p_a) still leaves 20% of intent velocity. Option: scale the residual so that when c_d is close to p_a, the leftover velocity is smaller: e.g. `remaining_ratio = (p_a - c_d) / p_a` and `v_reduced = v_intent * lerp(0.1, PARRY_V_MIN_FRACTION, remaining_ratio)` or similar.

**Touchpoints:**

- `ui/CombatManager.gd` in `_resolve_parry_with_momentum`: when computing `v_reduced` and `v_min`, optionally blend v_min down when (p_a - c_d) is small so “almost deflected” hits do less damage.

**Pros:** Partial parries feel more graduated; almost-deflects are less punishing.  
**Cons:** Requires tuning; current flat v_min is simple and predictable.

---

### 2.3 Relax or scale PARRY_DODGE_STRENGTH_RATIO

**Idea:** So weak defenders (e.g. Goblins) sometimes *attempt* parry (and get partial) instead of always choosing dodge. Options: (a) raise ratio globally (e.g. 1.4 → 1.8) so they try parry more often; (b) per-species or per-situation “grit” that raises effective c_d for the *choice* only (so they attempt parry more, but resolve still uses real c_d).

**Touchpoints:**

- (a) `ui/CombatManager.gd`: `const PARRY_DODGE_STRENGTH_RATIO := 1.8`.
- (b) CombatManager: when evaluating `choose_parry`, use a modified `parry_c_d_choice = parry_c_d * species_grit_mult` (e.g. Goblins 1.3) so they choose parry more; pass real `parry_c_d` into _resolve_parry_with_momentum.

**Pros:** More parry attempts from weak defenders; more partial parries and variety.  
**Cons:** (a) buffs all defenders; (b) needs a clear definition of “grit” and when it applies.

---

### 2.4 Parry bonus after successful deflect (readiness / confidence)

**Idea:** After a full deflect, give the defender a short-lived parry capacity bonus on the next defense (e.g. “ready” stance). Documented in STATE_MACHINE_PARRY_REALISM.md.

**Touchpoints:**

- Combatant state or defender node: e.g. `parry_bonus_until_time`, set on full deflect in `_resolve_parry_with_momentum`.
- When computing `parry_c_d`, if `Time.get_ticks_msec()/1000.0 < parry_bonus_until_time`, multiply by 1.1 or add a small capacity bonus.

**Pros:** Rewards successful defense; feels responsive.  
**Cons:** Extra state and tuning; can stack with other bonuses.

---

### 2.5 Reduce technique variance for high agility/skill

**Idea:** `PARRY_TECHNIQUE_VARIANCE` (0.1) applies ±10% to c_d. Option: scale variance down for high-agility defenders so their parries are more consistent.

**Touchpoints:**

- `ui/CombatManager.gd`: where `c_d_final *= randf_range(1.0 - PARRY_TECHNIQUE_VARIANCE, 1.0 + PARRY_TECHNIQUE_VARIANCE)`, use `var variance = PARRY_TECHNIQUE_VARIANCE * (1.0 - 0.5 * (float(tgt.stats.get("agility", 100)) - 100) / 100.0)` clamped so high agility reduces variance.

**Pros:** Skilled defenders have more consistent parries.  
**Cons:** Agility already does a lot; may be redundant.

---

## 3. Summary Table

| Area | Option | Where | Effort | Notes |
|------|--------|--------|--------|--------|
| Parry speed | 1.1 Per-weapon factor | WeaponConstants + Weapon + CombatManager | Low | Best for “dagger parries quicker than mace”. |
| Parry speed | 1.2 Agility scaling | CombatManager c_d_full | Trivial | One-line stat scaling. |
| Parry speed | 1.3 Blade movement time | CombatManager capacity_mult | Low | Implements existing comment; heavy weapon penalized. |
| Parry speed | 1.4 Species mult | SpeciesResource + CoreEntity + CombatManager | Low | Per-species parry capacity. |
| Other | 2.1 Time-of-intercept p_a | CombatManager parry_p_a | Low | Early parry meets less momentum. |
| Other | 2.2 Softer partial | CombatManager _resolve_parry | Medium | Near-deflects do less damage. |
| Other | 2.3 Relax ratio / grit | CombatManager choose_parry | Trivial / Low | Weak defenders attempt parry more. |
| Other | 2.4 Post-deflect bonus | CombatManager + state | Low | Capacity bonus after full deflect. |
| Other | 2.5 Agility vs variance | CombatManager c_d_final | Trivial | More consistent parries for high agi. |

---

## 4. Recommended Order

1. **Parry speed:** Implement **1.1** (per-weapon parry speed factor) so defender weapon type matters beyond mass. Optionally **1.2** (agility) if you want stats to improve parry without new data.
2. **Consistency with design:** Implement **1.3** (blade movement time) so the existing constants are used and heavy/weak defenders are slightly penalized.
3. **Feel:** **2.1** (time-of-intercept momentum) makes early parries face less p_a and rewards fast reaction.
4. **Balance:** **2.3** (relax ratio or species grit) if you want weak defenders to attempt parry more (and get partials) instead of always dodging.
5. **Polish:** **2.2** (softer partial), **2.4** (post-deflect bonus), **2.5** (variance vs agility) as tuning passes.

Implementing **1.1** + **1.3** + **2.1** gives clearer weapon differentiation, consistent use of blade movement time, and more realistic “early parry” momentum without changing core balance constants.
