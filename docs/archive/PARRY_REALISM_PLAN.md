# Parry Realism Improvements Plan

**Status:** Research complete, planning phase. Parent: [`COMPOSURE_PLAN.md`](COMPOSURE_PLAN.md) · Expand registry [`SHIP_PLAN §9c`](SHIP_PLAN.md#combat-expand-registry).

**Core files involved:** `DefenseResolutionHandler.gd`, `AttackResultApplier.gd`, `CombatConstantsParry.gd`, `CombatMuscleFatigue.gd`, `CombatFootwork.gd`, `DefenseChoiceResolver.gd`.

---

## Current System Summary

The parry system already has significant depth:
- **Momentum clash:** `parry_p_a` (attacker mass × velocity × composure) vs `parry_c_d` (defender capacity from weapon, timing, readiness, alignment, fatigue)
- **Three outcomes:** `parry_deflect` (full stop), `parry_edge_deflect` (alignment + margin), `parry_partial` (remaining energy passes through)
- **Bind detection:** Hard threshold at `PARRY_BIND_CONTROL_THRESHOLD = 0.65` on computed `parry_control` value
- **8-line guard system** with angle-based alignment (`CombatFootwork.guard_angle_deg`, Tier 4.4 PA offsets)
- **Timing model:** Early vs late parry via `parry_time_to_react`, capacity mult from blade movement time
- **Muscle fatigue:** Per-limb pools track exertion, dampen parry capacity and strike quality
- **Off-balance:** Fixed `OFF_BALANCE_DURATION_S = 0.4s` on deflect

---

## Identified Gaps (ranked by priority)

### Gap 1: Off-balance duration too short and uniform
**Current:** `OFF_BALANCE_DURATION_S = 0.4s`, scaled only by attack intensity in `AttackResultApplier` at line 500, 501:
```gdscript
atk["off_balance_until"] = CombatTiming.now_seconds() + OFF_BALANCE_DURATION_S * lerpf(0.5, 1.5, deflect_intensity)
tgt["off_balance_until"] = CombatTiming.now_seconds() + OFF_BALANCE_DURATION_S * 0.5
```

**Problem:** A heavy hammer blow and a light dagger tap produce the same off-balance duration if intensity is similar. Impact energy (momentum transfer `parry_p_a`, kinetic energy) doesn't factor in. The defender gets only 0.2s regardless of absorbing 50 N·kg/s vs 500 N·kg/s.

**Fix:** Scale off-balance by impact severity derived from `parry_clash_context`:
- Use `strike_kinetic_energy_j` or `parry_p_a` to compute a shock magnitude
- Higher energy → longer off-balance (up to ~1.5s for heavy impacts)
- Low margin_ratio (barely deflecting) → longer shake despite lower energy

### Gap 2: No forte/foible contact point on defender's blade
**Current:** Defender weapon has `weapon_parry_contact_type` ("blade", "shaft", "haft") and `weapon_parry_strong_fraction`, but no modeling of *where along the defender's blade* the attack contacts.

**Problem:** In real fencing, parrying with your forte (strong part near handle) against attacker's foible (weak tip) gives massive leverage advantage. Timing determines contact point: early parry = contact near defender's forte; late parry = attacker's blade has already moved past, contact shifts toward defender's foible.

**Fix:** Compute defender's blade contact ratio from `parry_time_to_react`:
- Early parry (high `parry_time_to_react`): contact at 0.2-0.4 of blade length from handle (forte)
- Late parry: contact at 0.7-1.0 of blade length (foible/weak)
- Apply leverage multiplier to `parry_c_d`: forte contact gives up to 1.3x advantage, foible gives 0.7x

### Gap 3: Cumulative arm shock fatigue separate from exertion
**Current:** `CombatMuscleFatigue` tracks per-limb exertion fatigue based on breath spent during attacks/parries. Recovery is passive over time.

**Problem:** Absorbing a hard parry impact transmits shock through the wrist, forearm, and elbow — this is distinct from muscle exertion. A fighter can be fresh (low exertion fatigue) but have a numb/shaking arm from blocking three heavy blows. This affects subsequent parry quality and grip strength.

**Fix:** Add `parry_shock` sub-pool to the existing limb fatigue dict:
- Triggered by `parry_deflect` / `parry_partial` outcomes proportional to absorbed energy
- Separate decay rate (faster recovery than exertion, ~2x)
- Affects `parry_c_d` multiplicatively (`parry_shock_capacity_mult`) with floor at 0.6 when fully shocked
- Resets at camp rest

### Gap 4: Bind quality is binary threshold
**Current:** `PARRY_BIND_CONTROL_THRESHOLD = 0.65` — if `parry_control >= 0.65`, it's a bind (grants riposte + flurry pair). Below that, no bind state.

**Problem:** In reality, binds exist on a spectrum:
- **Strong bind** (high control, well-aligned): Full grip, attacker cannot disengage easily
- **Marginal bind** (near threshold, partial alignment): Weak grip, may slip
- **Near-bind** (below threshold but >0.5): Blade contact maintained but no mechanical advantage

**Fix:** Tiered bind quality stored in `parry_clash_context`:
- `bind_quality: float` (0.0-1.0) always computed from `parry_control`
- `bind_tier: String` ("strong", "marginal", "none")
- Strong bind: current behavior (riposte, flurry pair)
- Marginal bind (0.5-0.65): Partial riposte bonus (smaller gauge bonus), no flurry pair
- Near-bind: No mechanical advantage but prevents passive parry reset

### Gap 5: Wrist rotation/torsion model for misaligned parries
**Current:** Alignment is computed as a single scalar (0.0-1.0) based on guard line vs attack line angular difference. Poor alignment reduces `parry_c_d` multiplicatively.

**Problem:** When blades meet at an angle, the defender's wrist must rotate to keep the blade oriented correctly. A large angle mismatch means more wrist torsion needed, which:
- Reduces effective strength (wrist is weaker in rotation than flexion)
- Can cause the parry to deflect outward (blade runs off)
- Costs more energy from the wrist/forearm

**Fix:** Model wrist torsion as a function of angular mismatch at contact:
- `angle_mismatch_deg = abs(attack_angle_deg - guard_angle_deg)` at parry moment
- Torsion penalty scales quadratically with angle gap (>30° starts mattering)
- Adds to `parry_shock` (Gap 3) — high-torsion parries are harder on the arm
- Already partially addressed by alignment, but torsion is a separate physical cost

---

## Implementation Plan (ordered for dependency)

### Phase 1: Off-balance scaling (standalone, no deps)
**Files:** `CombatConstantsParry.gd`, `AttackResultApplier.gd`

1. Add `OFF_BALANCE_ENERGY_SCALE_FACTOR` — converts kinetic energy to duration seconds
2. In `parry_deflect` branch of `apply_result()`, compute:
   ```gdscript
   var impact_energy = clash.get("strike_kinetic_energy_j", 0.0)
   var margin_ratio = clash.get("margin_ratio", 1.0)
   var base_duration = OFF_BALANCE_DURATION_S
   var energy_mult = clampf(lerpf(0.5, 2.5, impact_energy / 100.0), 0.3, 3.0)
   var margin_mult = clampf(margin_ratio, 0.5, 1.5)  # barely deflecting = longer shake
   tgt["off_balance_until"] = CombatTiming.now_seconds() + base_duration * energy_mult * margin_mult
   ```
3. Same for attacker recovery off-balance (line 500)

**Harness:** `_run_parry_off_balance_energy_scale_*` — verify heavy attack deflect causes longer lockout than light tap.

### Phase 2: Forte/foible contact point
**Files:** `CombatConstantsParry.gd`, `DefenseResolutionHandler.gd`, `DefenseChoiceResolver.gd`

1. Add constants:
   - `PARRY_FORTE_FOIBLE_CONTACT_MIN = 0.15` (closest to handle)
   - `PARRY_FORTE_FOIBLE_CONTACT_MAX = 1.0` (tip)
   - `PARRY_FORTE_LEVERAGE_BONUS = 0.3` (up to 30% advantage)
   - `PARRY_FOIBLE_LEVERAGE_PENALTY = 0.3` (up to 30% penalty)

2. In `DefenseResolutionHandler._resolve_parry()`, compute contact ratio:
   ```gdscript
   var contact_ratio = clampf(1.0 - parry_time_to_react / effective_wind_up, 0.0, 1.0)
   # Early parry (high time_to_react) → low contact_ratio → forte
   # Late parry → high contact_ratio → foible
   var leverage_mult = lerpf(1.0 + FORTE_LEVERAGE_BONUS, 1.0 - FOIBLE_LEVERAGE_PENALTY, contact_ratio)
   c_d_final *= leverage_mult
   ```

3. Store `contact_ratio` and `leverage_mult` in `parry_clash_context`.

**Harness:** `_run_parry_forte_foible_*` — early parry with same weapon has higher `parry_c_d` than late parry beyond just the timing capacity mult.

### Phase 3: Parry shock fatigue
**Files:** `CombatMuscleFatigue.gd`, `AttackResultApplier.gd`, `DefenseChoiceResolver.gd`

1. Extend combatant dict to support `muscle_fatigue.parry_shock` per limb (or separate key `parry_shock`)
2. In `AttackResultApplier` on `parry_deflect` / `parry_partial`:
   ```gdscript
   var shock_gain = clampf(impact_energy / 200.0, 0.0, 0.4)  # 0-40% per hit
   _MuscleFatigue.apply_parry_shock(manager, tgt, shock_gain, dominant_limb)
   ```
3. In `CombatMuscleFatigue`:
   - New `apply_parry_shock()` method
   - Recovery rate 2x faster than exertion (`MUSCLE_FATIGUE_SHOCK_RECOVERY_RATE`)
   - Camp clear flag
4. In `DefenseChoiceResolver.choose_defense()`:
   ```gdscript
   parry_c_d *= _MuscleFatigue.parry_shock_capacity_mult(tgt, manager)
   ```

**Harness:** `_run_parry_shock_fatigue_*` — 5 heavy deflects should accumulate measurable shock that reduces subsequent parry capacity.

### Phase 4: Bind quality spectrum
**Files:** `CombatConstantsParry.gd`, `DefenseResolutionHandler.gd`, `AttackResultApplier.gd`, `CombatFlurryBind.gd`

1. Add constants:
   - `PARRY_BIND_STRONG_THRESHOLD = 0.65` (current)
   - `PARRY_BIND_MARGINAL_THRESHOLD = 0.50`
   - `PARRY_BIND_NONE_THRESHOLD = 0.35`

2. In `DefenseResolutionHandler._build_parry_clash_context()`, add:
   ```gdscript
   var bind_tier = "none"
   if parry_control >= PARRY_BIND_STRONG_THRESHOLD:
       bind_tier = "strong"
   elif parry_control >= PARRY_BIND_MARGINAL_THRESHOLD:
       bind_tier = "marginal"
   ctx["bind_tier"] = bind_tier
   ```

3. In `AttackResultApplier` on `parry_deflect` / `parry_partial`:
   - Strong: Current behavior (full riposte, flurry pair)
   - Marginal: `tgt["parry_was_bind"] = true`, smaller gauge bonus (`PARRY_BIND_RIPOSTE_GAUGE_BONUS * 0.5`), no flurry pair open
   - None: `tgt["parry_was_bind"] = false`, current behavior

4. Update `CombatFlurryBind` to check bind tier before opening pair.

**Harness:** `_run_parry_bind_quality_*` — verify marginal binds grant partial advantage without full flurry commitment.

### Phase 5: Wrist torsion cost
**Files:** `CombatConstantsParry.gd`, `DefenseResolutionHandler.gd`, `AttackResultApplier.gd`

1. Add constants:
   - `PARRY_TORSION_ANGLE_THRESHOLD_DEG = 30.0` (below this, no penalty)
   - `PARRY_TORSION_SHOCK_SCALE = 0.002` (shock per degree of mismatch beyond threshold)

2. In `_resolve_parry()`, compute angular mismatch:
   ```gdscript
   var angle_gap = absf(attack_angle_deg - guard_angle_deg)
   # Normalize to 0-180 range
   if angle_gap > 180.0:
       angle_gap = 360.0 - angle_gap
   var torsion_penalty = 1.0
   if angle_gap > TORSION_ANGLE_THRESHOLD_DEG:
       var excess = angle_gap - TORSION_ANGLE_THRESHOLD_DEG
       torsion_penalty = 1.0 - (excess / 90.0) * 0.25  # up to 25% reduction at 90° mismatch
   c_d_final *= torsion_penalty
   
   var torsion_shock = clampf((angle_gap - TORSION_ANGLE_THRESHOLD_DEG) * TORSION_SHOCK_SCALE, 0.0, 0.15)
   ```

3. Store `torsion_penalty` and `torsion_shock` in `parry_clash_context`. Apply shock to defender's arm in `AttackResultApplier`.

**Harness:** `_run_parry_wrist_torsion_*` — parrying at 90° angle mismatch costs more and generates more shock than aligned parry.

---

## Non-goals

- Weapon structural stress / blade damage (requires new weapon durability system)
- Sound/visual feedback changes (UI scope, not simulation)
- New `FEATURE_*` flags initially — implement as always-on improvements to existing behavior
- Modifying the 8-line guard system itself (already working well)

---

## Balance soak strategy

After each phase:
1. Run `_run_parry_*_balance_exchange_proxy` harness row — verify parry capacity stays within expected range
2. F5 paste with `wf_m3_*` tracks to monitor off-balance lockout frequency and duration
3. Verify Phase 0 regression green with changes applied

---

## Expand registry row (when implemented)

Add to [`SHIP_PLAN §9c`](SHIP_PLAN.md#combat-expand-registry):

**Pr — parry realism improvements:** `DefenseResolutionHandler` forte/foible, `AttackResultApplier` off-balance energy scale, `CombatMuscleFatigue` parry shock, bind quality spectrum, wrist torsion cost. Harness `_run_parry_realism_*`.

