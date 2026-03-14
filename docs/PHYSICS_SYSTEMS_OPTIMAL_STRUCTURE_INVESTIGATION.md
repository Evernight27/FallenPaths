# Physics Systems: Implementation & Optimal Structure Investigation

## Purpose

Investigate how Fatigue/Readiness/Off-Balance, Attack Arc, Mass/Guard Wobble, Binding/Tempo, Continuous Angle System, and Footwork/Positioning are implemented, and propose better structural approaches for optimal physics-based realism.

---

## 1. Fatigue, Readiness, and Off-Balance on Angle Variance

### 1.1 Current Implementation

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

### 1.2 Gaps

- **Readiness not in variance_context:** Attacker in recovery has lower readiness but attack variance is not scaled. Only defender readiness affects parry (capacity, wobble).
- **Fatigue/readiness conflated:** Stamina is a global fatigue pool; readiness is recovery-state (early/late). A fatigued combatant in WAITING might still have high readiness but high variance (fatigue).
- **Off-balance is binary:** Fixed duration; no severity. Realistically, severity depends on intensity, deflect vs miss, etc.

### 1.3 Optimal Structure

| Improvement | Description |
|-------------|-------------|
| **Unified variance factor** | `effective_variance_mult = 1.0 × stamina_factor × off_balance_factor × readiness_factor × mass_factor`. Each factor from its own curve. |
| **Readiness in attacker variance** | When attacker is RECOVERING and resolves attack (re-entry from parry_partial?), pass `attacker_readiness` into variance_context. Early recovery = worse control = higher variance. |
| **Off-balance severity** | `off_balance_severity` 0–1 from recovery_cause (miss=0.6, deflect=0.8) × intensity. Duration and variance mult scale with severity. |
| **Stamina curve** | **Implemented.** `CombatConstants.stamina_factor(ratio)` uses power 0.6; applied to variance, parry, damage. See STAMINA_CURVE_HEMA_COMBAT_PACING_INVESTIGATION.md. |

---

## 2. Attack Arc Tracking and Use

### 2.1 Current Implementation

| Data | Where Set | Where Used |
|------|-----------|------------|
| `arc_start_deg` | AttackWindUpStarter (attacker guard at wind-up) | AttackResolver: base for arc_span |
| `arc_end_deg` | AttackResolver ( = attack_angle_deg after variance) | - |
| `arc_span_deg` | AttackResolver: `angle_diff_deg(arc_start, arc_end)` | DefenseChoiceResolver (late parry only) |

**Flow:**
- Wind-up: `pa["arc_start_deg"] = CombatConstants.get_guard_angle_deg(atk)` (attacker’s blade at start)
- Resolve: `arc_end_deg = attack_angle_deg`, `arc_span_deg = angle_diff_deg(arc_start, arc_end)`
- Late parry: if `arc_span > 50°` → parry_c_d scaled down by up to 25%

### 2.2 Gaps

- **Arc only affects late parry:** On-time parries do not use arc_span.
- **No arc-based intercept depth:** Path intercept uses alignment only, not “how far the blade traveled.” A short arc vs long arc could affect where the blade is when contact happens.
- **Arc_start from guard:** Reasonable, but diagonal moves might start from a blended guard; arc_start could be refined.
- **No move-defined arc width:** Moves don’t define arc_center/arc_width (trajectory-as-range per ENHANCED_BLADE_TRAJECTORY.md Approach D).

### 2.3 Optimal Structure

| Improvement | Description |
|-------------|-------------|
| **Arc for all parries** | Scale parry capacity or alignment by arc_span: large arc = blade moving fast through space; harder to predict and catch. `parry_align_factor = 1.0 - k * clamp(arc_span / 90, 0, 1)` for small k. |
| **Move-defined arc width** | Add `arc_width_deg` per move (e.g. oberhau 60°, thrust 15°). Arc_span = variance within that width + geometry. Enables “sweeping cut vs precise thrust” feel. |
| **Intercept from arc position** | Model “blade at X% of arc” at contact. Late parry = blade further along arc. Feed into path intercept or hit distribution. |
| **Arc → deflection magnitude** | Large arc = more momentum; deflect magnitude could scale with arc_span (harder redirect when blade has traveled far). |

---

## 3. Mass and Guard Wobble

### 3.1 Current Implementation

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

### 3.2 Gaps

- **Defender mass not in wobble:** Heavier defender weapon = more inertia = potentially more wobble when reacting. Current wobble is readiness-only.
- **Attacker mass only in variance:** Mass doesn’t affect deflection outcome, bind chance, or damage (except via variance → alignment).
- **Wobble is isotropic:** Same ± degrees in any direction. Realistically, wobble might favor certain directions (e.g. along weak axis of blade).

### 3.3 Optimal Structure

| Improvement | Description |
|-------------|-------------|
| **Defender mass in wobble** | `wobble_mult = 1.0 + (defender_mass_kg - 1.0) * 0.08`. Heavier blade = slower to stabilize = more wobble when reacting. |
| **Mass in bind/deflect** | P(bind) or deflect magnitude could factor mass ratio: heavier attacker blade = harder to control in bind; lighter defender = easier to deflect. |
| **Readiness × mass interaction** | `wobble = base_wobble * (1 - readiness) * (1 + mass_factor)`. Low readiness + heavy blade = worst. |
| **Anisotropic wobble (advanced)** | Wobble component along blade axis vs perpendicular; perpendicular (edge alignment) matters more for parry quality. |

---

## 4. Binding and Tempo

### 4.1 Current Implementation

**Bind:**
- `parry_control >= PARRY_BIND_CONTROL_THRESHOLD` (0.65) → bind
- parry_control = f(margin_ratio, alignment, readiness, timing, attack_type)
- On bind: attacker guard_line = attack_line (blade stays); defender guard from move
- GuardLineUpdater: `if parry_control >= threshold: line = atk_line, blend = 0`

**Tempo:**
- `off_balance_until` after parry_deflect or miss → gauge fill × `OFF_BALANCE_GAUGE_FILL_MULT` (0.5)
- `parry_bonus_until` after parry_deflect → parry capacity × 1.1 for defender
- No explicit Vor/Nach state; tempo is emergent from gauge fill rate

### 4.2 Gaps

- **Bind angle is discrete:** Both blades end at attack_line. No compromise angle (lerp of attack + defender guard).
- **No bind duration:** Once bind, next action is normal. No “wind from bind” or restricted options.
- **Tempo is implicit:** Only off_balance and parry_bonus. No “last to act fills slower” or “indes window.”
- **Riposte from bind:** Parry_counter moves use attack_line; minimal transition is implicit but not a formal bonus.

### 4.3 Optimal Structure (from BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md)

| Improvement | Description |
|-------------|-------------|
| **Bind angle blend** | `guard_angle = lerp(attack_angle, defender_guard_angle, 0.4 + 0.3 * parry_control)`. Both blades at compromise. Store continuous angle; guard_line = angle_to_nearest_line for legacy. |
| **Indes parry-counter** | When parry_deflect + parry_thrust/cut chosen, wind-up × 0.85 (faster counter from good position). |
| **Tempo state (optional)** | `tempo_state`: "vor" | "nach" | "neutral". Last to successfully attack = Vor; parried attacker = Nach. Vor: gauge bonus; Nach: parry/riposte bonus. |
| **Bind duration (advanced)** | `bind_until` timestamp. While bound: wind action or restricted guard change. Enables wind-from-bind gameplay. |

---

## 5. Continuous Angle System (No 4-Line Quantization)

### 5.1 Current Implementation

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

### 5.2 Gaps

- **Path table is 4×4:** Angles 23° and 67° both map to same quadrant. No interpolation between paths.
- **Deflection output quantized:** Deflected angle becomes line for storage; downstream loses precision.
- **Part sectors not angle-driven:** Hit part from path (ordered list) + intercept. No direct angle→part weights.

### 5.3 Optimal Structure (from ENHANCED_BLADE_TRAJECTORY, ANGLE_VS_DISCRETE)

| Improvement | Description |
|-------------|-------------|
| **Store guard_angle_deg** | Keep `guard_angle_deg` alongside guard_line. Use angle for alignment, deflection, path; guard_line for legacy/display. |
| **Path interpolation** | When angle falls between two lines, blend path weights: `path_A * (1-t) + path_B * t` where t = angular distance to nearest. |
| **8 directions (medium effort)** | Add diagonals; 8×8 path table. 2× angular resolution without full float propagation. |
| **Angle-driven part sectors (Approach F)** | Define PART_SECTORS_DEG; weight(part) = sector_overlap(part, attack_angle) × guard_block_factor. Eliminates path tables for hit distribution. |
| **Deflection stays continuous** | Store deflected_angle_deg; only quantize when writing to guard_line for UI. |

---

## 6. Footwork and Positioning

### 6.1 Current Implementation

**None.** No distance_band, stance, position_angle, or step-on-attack.

Relevant constants:
- `GUARD_TRANSITION_COST_SCALE`: wind-up scales by 1 - alignment (guard→attack)
- `melee_range` per weapon exists but not used for positioning
- Footwork/positioning doc (FOOTWORK_POSITIONING_INVESTIGATION.md) outlines options but none implemented

### 6.2 Gaps

- No spatial representation: all combatants effectively “in range”
- No stance-derived variance (e.g. committed vs balanced)
- No distance modifiers for parry/damage

### 6.3 Optimal Structure (from FOOTWORK_POSITIONING_INVESTIGATION)

| Phase | Content | Effect |
|-------|---------|--------|
| **1** | Distance band (close/medium/far) | Attack→close, dodge→far. Parry/damage modifiers per band. |
| **2** | Stance from last action | balanced/committed/retreating → variance mult. |
| **3** | Position angle offset | Step-on-attack adds offset; effective_attack_angle += offset. |
| **4** | Reach vs distance | At far: reduce parry alignment; at close: increase. |

---

## 7. Cross-Cutting Recommendations

### 7.1 Data Flow Consistency

- **VarianceContext:** Extend to `{stamina_ratio, off_balance, off_balance_severity?, readiness?, weapon_mass_kg}`. Single struct passed everywhere attack angle is computed.
- **WobbleContext:** `{parry_readiness, defender_mass_kg?}`. Single struct for guard angle.
- **ClashContext:** Already exists for parry; extend for bind_angle, bind_duration.

### 7.2 Constants Organization

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

### 7.3 Physics-First Order of Application

1. Base geometry (angles, alignment)
2. Variance (stamina, off_balance, readiness, mass) → attack_angle, guard_angle
3. Arc (span, width) → parry difficulty, intercept
4. Wobble → effective guard_angle
5. Bind/deflect → post-contact state
6. Tempo → gauge, recovery

### 7.4 Suggested Implementation Priority

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

## References

- CombatConstants.gd (ANGLE_VARIANCE_*, GUARD_WOBBLE_*, ARC_SPAN_*, PARRY_BIND_*)
- AttackResolver.gd, DefenseChoiceResolver.gd, DefenseResolutionHandler.gd
- AttackWindUpStarter.gd, GuardLineUpdater.gd, PassiveParryContext.gd
- AttackPathResolver.gd, AttackResultApplier.gd
- CombatStateHandlers.gd (gauge fill, off_balance)
- BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md
- ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md
- FOOTWORK_POSITIONING_INVESTIGATION.md
- ANGLE_VS_DISCRETE_AND_BILATERAL_INTERSECTION_INVESTIGATION.md
