# Agent Prompt: Leg Fatigue Degradation System (Phase 2)

**Stream:** Enhance / Combat  
**Gate:** `PHASE0: PASS`  
**Priority:** High — closes a documented realism gap in the combat simulation  

---

## Context & Previous Work

### What's already done
- **Muscle fatigue system exists** (`CombatMuscleFatigue`, `CombatConstantsMuscleFatigue`) with per-limb pools (R arm, L arm, R leg, L leg) that accumulate from exertion and recover during wait/recovering states.
- **Dodge chance wiring completed:** `CombatMuscleFatigue.dodge_chance_mult(tgt)` is now called in `DefenseChoiceResolver.choose_defense()` at line 127. This applies a multiplicative reduction to dodge chance based on leg fatigue, with a 40% floor at max fatigue (`MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR = 0.4`).
- **Formation movement damp exists:** `CombatMuscleFatigue.formation_movement_weight_mult()` uses `MUSCLE_FATIGUE_FORMATION_DAMP_FLOOR = 0.45` for reposition moves (rotate_file, swap_rank).

### What's missing (the gap)
The research doc (`docs/LEG_FATIGUE_RESEARCH.md`) documents a **multi-stage degradation curve** that the current system doesn't implement:

| Fatigue Level | Primary Effect | Current System | Missing? |
|---------------|---------------|----------------|----------|
| 0-25% | Step frequency drops | Nothing (dodge=1.0, formation damp=1.0) | YES |
| 25-50% | Step speed degrades | Nothing | YES |
| 50-75% | Balance/stability degrades | Dodge floor starts at 40%, but no curve | PARTIAL |
| 75-90%+ | Recovery from off-balance fails | Nothing | YES |

The current system jumps from "no effect" to a flat 40% floor. Real combat has **gradual degradation** — fighters notice sluggish advance at ~30% leg fatigue, not just collapse at 100%.

### Research doc: `docs/LEG_FATIGUE_RESEARCH.md`
Key proposed effects (Section 6):
- **A. Step Speed Multiplier** — applies to all footwork advancement speed
- **B. Balance Stability Floor** — replaces flat dodge floor with dynamic curve  
- **C. Retreat Penalty** — asymmetry: retreat harder than advance when fatigued
- **D. Binding/Positional Control** — affects ground holding, bind pressure
- **E. Strike Follow-Through Balance Penalty** — recovery from attacks takes longer
- **F. Step Precision / Footwork Accuracy** — tactical positioning degrades

### Existing constants (to extend or replace)
```gdscript
# CombatConstantsMuscleFatigue.gd
const MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR: float = 0.4       # flat floor → needs curve
const MUSCLE_FATIGUE_FORMATION_DAMP_FLOOR: float = 0.45     # flat floor → needs curve
```

### Key files to own (≤3)
1. **`combat/constants/CombatConstantsMuscleFatigue.gd`** — add new constants for degradation curves
2. **`combat/flow/CombatMuscleFatigue.gd`** — implement step_speed_mult, balance_stability_mult, retreat_mult functions; update dodge_chance_mult to use curve instead of flat floor
3. Possibly **`combat/strike/DefenseChoiceResolver.gd`** if dodge formula changes (research: `effective_dodge = base * stability_floor * lateral_mult * retreat_mult`)

---

## Task: Implement Multi-Stage Leg Fatigue Degradation

### Goal
Replace the flat "40% dodge floor" and "45% formation damp floor" with **graded degradation curves** that match the research doc's empirically-grounded values. The system should show measurable effects at 25%, 50%, 75%, and 90% leg fatigue levels — not just a binary "fine or collapsed."

### Design Decisions (to implement)

#### 1. Step Speed Multiplier (all forward/retreat/lateral movement)
Formula from research: `step_speed = lerp(1.0, 0.10, pow(leg_fatigue/100, 1.3))`

Values:
| Fatigue | Step Speed |
|---------|-----------|
| 0% | 1.00 |
| 25% | ~0.82 |
| 50% | ~0.60 |
| 75% | ~0.38 |
| 90% | ~0.22 |
| 100% | 0.10 |

Apply to: formation movement duration (already uses `formation_movement_weight_mult`), and any step-speed-based combatant movement in the overworld/campaign pathing.

#### 2. Dodge Degradation Curve (replaces flat floor)
Research proposes replacing the single dodge floor with multiplicative factors:
```
effective_dodge = base_dodge * balance_stability_floor(leg_fatigue) * lateral_mult(leg_fatigue)
```

At 75% fatigue: `base * 0.45 * 0.38 * 0.32 ≈ base * 0.055` (near-zero dodge, not just "floor at 40%")

New constants to add:
- `MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR` — replaces dodge floor (curves from 1.0 → 0.25)
- Keep `MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR = 0.4` only as an **absolute survival floor** at extreme fatigue/collapse (e.g., only applies when leg_fatigue > 90%)

Update `dodge_chance_mult()` to use: `lerp(1.0, stability_floor, pow(fatigue, 1.3))` with optional additional lateral penalty for non-forward dodge directions.

#### 3. Formation Movement Degradation
Replace flat `MUSCLE_FATIGUE_FORMATION_DAMP_FLOOR = 0.45` with:
```
formation_damp = step_speed_mult(leg_fatigue) * step_precision_mult(leg_fatigue)
```

At 50% fatigue: `0.60 * 0.82 ≈ 0.49` (matches current ~45% figure but with proper curve)

Update `formation_movement_weight_mult()` to use this curve instead of `lerp(1.0, 0.45, leg_f)`.

#### 4. Recovery Time Multiplier
At high fatigue, combatants recover from off-balance/recovering states more slowly:
```
recovery_time_mult(leg_fatigue):
  25%: x1.15
  50%: x1.40
  75%: x1.90
  90%: x2.60
```

Apply in `CombatStateHandlers` or wherever recovering state duration is computed. This makes fatigued fighters stay longer in vulnerable states after committing attacks.

---

## Implementation Plan (one PR, one FEATURE)

### Step 1: Add constants to `CombatConstantsMuscleFatigue.gd`
```gdscript
// New constants for degradation curves:
const MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER: float = 1.3    // exponent for non-linear curve
const MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX: float = 0.25  // at 100% fatigue
const MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX: float = 0.30
const MUSCLE_FATIGUE_RETREAT_PENALTY_MULT_AT_MAX: float = 0.06  // retreat is hardest when fatigued
const MUSCLE_FATIGUE_RECOVERY_TIME_BONUS_AT_MAX: float = 3.50   // recovery takes up to 3.5x longer

// Keep old constants for backward compatibility / absolute floors:
const MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR: float = 0.4          // survival floor only (applies at >90%)
const MUSCLE_FATIGUE_FORMATION_DAMP_FLOOR: float = 0.45        // legacy reference
```

### Step 2: Add helper methods to `CombatMuscleFatigue.gd`
```gdscript
// Step speed multiplier for all footwork (advance/retreat/lateral)
static func step_speed_mult(c: Dictionary, direction: String = "forward") -> float:
    var leg_f = maxf(damage.limb_fatigue(c, R_LEG), limb_fatigue(c, L_LEG))
    var base := lerpf(1.0, 0.10, pow(clampf(leg_f, 0.0, 1.0), MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
    // Directional asymmetry: retreat is harder than forward at high fatigue
    if direction == "retreat":
        return base * lerpf(1.0, 0.65, leg_f)  // up to 35% additional penalty for retreat
    elif direction == "lateral" or direction == "diagonal":
        return base * lerpf(1.0, 0.82, leg_f)   // up to 18% additional penalty for lateral
    return base

// Balance/stability multiplier for dodge success
static func balance_stability_mult(c: Dictionary) -> float:
    var leg_f = maxf(limb_fatigue(c, R_LEG), limb_fatigue(c, L_LEG))
    return lerpf(1.0, MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(clampf(leg_f, 0.0, 1.0), 1.3))

// Step precision for formation movement accuracy
static func step_precision_mult(c: Dictionary) -> float:
    var leg_f = maxf(limb_fatigue(c, R_LEG), limb_fatigue(c, L_LEG))
    return lerpf(1.0, MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX, pow(clampf(leg_f, 0.0, 1.0), 1.2))

// Recovery time bonus (multiplier on recovery duration)
static func recovery_time_mult(c: Dictionary) -> float:
    var leg_f = maxf(limb_fatigue(c, R_LEG), limb_fatigue(c, L_LEG))
    return lerpf(1.0, MUSCLE_FATIGUE_RECOVERY_TIME_BONUS_AT_MAX, pow(clampf(leg_f, 0.0, 1.0), 1.3))
```

### Step 3: Update `dodge_chance_mult()` to use curve + survival floor
Current (flat): `lerp(1.0, 0.4, leg_fatigue)`  
New (curved with absolute floor):
```gdscript
static func dodge_chance_mult(c: Dictionary, manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var leg_f := maxf(limb_fatigue(c, R_LEG), limb_fatigue(c, L_LEG))
    
    // Curved degradation for normal fatigue range (0-90%)
    var stability := balance_stability_mult(c)
    
    // Absolute survival floor only kicks in at extreme fatigue (>90%)
    if leg_f > 0.9:
        return maxf(MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR, stability)
    
    return stability
```

Wait — reconsider. The research says dodge should be multiplicative AND can go below 40% at moderate fatigue. The 40% floor is only a "collapse" survival mechanism. Let me re-read the research...

Research Section 7 says: `effective_dodge = base_dodge * stability_floor(lf) * lateral_mult(lf)`. At 75% fatigue that's ~5.5% of base — meaning dodge becomes essentially useless, not just "40% chance." The flat 40% floor was too generous.

New approach:
```gdscript
static func dodge_chance_mult(c: Dictionary, _manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var leg_f := maxf(limb_fatigue(c, BodyPartConstants.PART_RIGHT_LEG), limb_fatigue(c, BodyPartConstants.PART_LEFT_LEG))
    
    // Curved degradation — dodge degrades smoothly from 1.0 → ~0.05
    var stability := lerpf(1.0, MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(clampf(leg_f, 0.0, 1.0), 1.3))
    
    // Absolute floor only at collapse (prevents total immobility animation bug)
    if leg_f >= 1.0:
        return maxf(stability, 0.05)  // 5% minimum — character can still flinch
    
    return stability
```

### Step 4: Update `formation_movement_weight_mult()` to use step_speed × precision
Current (flat): `lerp(1.0, 0.45, leg_f)` → at 50% fatigue = 0.725 (only 27.5% damp)  
New (curved): `step_speed * precision` → at 50% = 0.60 × 0.82 = 0.49 (~51% damp, matches research)

```gdscript
static func formation_movement_weight_mult(c: Dictionary, move_id: String, _manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    if not CombatConstants.is_formation_reposition_move(move_id):
        return 1.0
    var leg_f := maxf(limb_fatigue(c, BodyPartConstants.PART_RIGHT_LEG), limb_fatigue(c, BodyPartConstants.PART_LEFT_LEG))
    // Step speed × precision curve (research Section 8)
    var step_spd := lerpf(1.0, 0.10, pow(clampf(leg_f, 0.0, 1.0), 1.3))
    var step_prec := lerpf(1.0, MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX, pow(clampf(leg_f, 0.0, 1.0), 1.2))
    return step_spd * step_prec
```

### Step 5: Add recovery time bonus hook (if feasible within budget)
If there's room after steps 1-4, add `recovery_time_mult()` and hook it into wherever recovering state duration is computed. This could be in `CombatStateHandlers` or via a constant that scales the `COMPOSURE_FILL_RECOVERING` rate inversely:

```gdscript
// In CombatConstants.gd (or existing recovery constants file):
const MUSCLE_FATIGUE_RECOVERY_TIME_BONUS_AT_MAX := 3.50

// Existing recovering dodge mult reads this:
static func defense_footwork_recovering_dodge_mult_for_cause(cause: String) -> float:
    // ... existing logic ...
    // Could optionally factor in fatigue via CombatMuscleFatigue.recovery_time_mult()
```

**Budget constraint:** If step 5 won't fit within ≤3 files + ≤1 doc section, defer it to a follow-up PR. Steps 1-4 are the core improvement and should be done first.

---

## Harness Requirements

### Update existing test: `_run_muscle_fatigue_dodge_chance_tired_legs`
Current test expects `lerp(1.0, floor, 0.8)` — needs updating for the new curve:
```gdscript
static func _run_muscle_fatigue_dodge_chance_tired_legs(failures: PackedStringArray) -> void:
    _with_flag(true, func() -> void:
        var c: Dictionary = {}
        CombatMuscleFatigue.seed_combatant_if_enabled(c)
        c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.8
        var mult: float = CombatMuscleFatigue.dodge_chance_mult(c)
        // New curve at 80% fatigue: lerp(1.0, 0.25, pow(0.8, 1.3)) ≈ 0.29
        var expected := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(0.8, 1.3))
        if absf(mult - expected) > 0.02:
            CombatRegressionHarness._fail(failures, "muscle_fatigue_dodge: want ~%.3f got %.3f" % [expected, mult])
    )
```

### Add new test: `_run_muscle_fatigue_step_speed_curve`
Verify step speed degrades non-linearly at expected fatigue levels (0%, 25%, 50%, 75%, 100%).

### Add new test: `_run_muscle_fatigue_formation_damp_curve`
Replace/update existing `_run_muscle_fatigue_formation_damp_tired_legs` to verify the product of step_speed × precision, not a flat lerp.

---

## Anti-Patterns & Constraints

- **Do NOT** add new `FEATURE_*` flags — muscle fatigue is already enabled (`FEATURE_MUSCLE_GROUP_FATIGUE := true`).
- **Do NOT** modify `world/*` files (campaign bridge). Step speed for overworld movement is out of scope unless trivially accessible via existing constants.
- **Do NOT** change the exertion accumulation formulas — only the *effects* of accumulated fatigue.
- **Preserve** existing behavior when leg_fatigue = 0 (all multipliers must return 1.0).
- **Preserve** `MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR = 0.4` as a named constant for legacy reference / UI display, even if the functional dodge mult uses the new curve.
- **Follow** the session contract: ≤1 doc section + ≤3 `.gd` files before first edit.

---

## Research Anchor
All values derived from `docs/LEG_FATIGUE_RESEARCH.md` (Section 6 "Recommended New Effects for Game Implementation" and Section 7 "Integration with Existing Dodge System"). Key studies cited: Amadio et al. 2017, Barton et al. 2017, Gummeling et al. 2020.

---

## Success Criteria
- All degradation curves produce values matching the research doc tables (within ±5%)
- Dodge at 75% fatigue: ~45% of base (not flat 40% floor)
- Formation movement at 50% fatigue: ~49-51% damp (matches current ~45% but with proper curve)
- `dodge_chance_mult(0.0)` returns exactly 1.0 (fresh fighter = no penalty)
- Harness tests updated and passing
- Phase 0 gate green after changes

---

## PR Prefix
`combat:` or `enhance:leg-fatigue-curve`
