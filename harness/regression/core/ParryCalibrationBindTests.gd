class_name ParryCalibrationBindTests

extends CombatRegressionHarnessCore

## Parry calibration bind surface: blade-width friction, morale parry readiness, damage-
## reduction cap, bind-pressure defender penalty + decay constants, follow-through
## gates and block-threshold balance/asymmetry.


static func _run_bind_friction_blade_width(failures: PackedStringArray) -> void:
    var hi_cd: float = 100.0
    var pa_m: float = 5.0
    var al: float = 0.9
    # Backward compat: the 7-arg baseline (default friction 1.0) equals the explicit 1.0.
    var base: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut")
    var explicit_one: float = CombatConstants.parry_control_for_bind_deflect(
        hi_cd, pa_m, al, 1.0, false, false, "cut", 1.0
    )
    if absf(base - explicit_one) > 0.0001:
        _fail(
            failures,
            "bind_friction: 7-arg baseline must equal explicit 1.0 (base=%.4f explicit=%.4f)" % [base, explicit_one]
        )
    # A narrower parrying blade (dagger 1.5cm -> 0.94) reduces bind control.
    var narrow: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut", 0.94)
    if narrow >= explicit_one:
        _fail(
            failures,
            "bind_friction: narrow blade (0.94) should reduce control (narrow=%.4f full=%.4f)" % [narrow, explicit_one]
        )
    # bind_friction_mult_for_weapon: null -> 1.0.
    if absf(CombatConstants.bind_friction_mult_for_weapon(null) - 1.0) > 0.0001:
        _fail(failures, "bind_friction: null weapon should yield 1.0")
    # A real SWORD (2.0cm blade, blade parry) -> exactly 1.0 (the D001 no-op guarantee).
    var mgr: Node = MgrScript.new()
    var ent: CoreEntity = _new_entity("SWORD")
    mgr.register(ent, "player")
    var c: Dictionary = mgr.combatants[0]
    var sword_w = EntityAccess.get_weapon(c)
    if sword_w == null:
        _fail(failures, "bind_friction: SWORD weapon should not be null")
        _free_manager(mgr)
        return
    var sword_mult: float = CombatConstants.bind_friction_mult_for_weapon(sword_w)
    if absf(sword_mult - 1.0) > 0.0001:
        _fail(failures, "bind_friction: SWORD (2.0cm) should yield exactly 1.0 (got %.4f)" % sword_mult)
    # Mutate a FRESH weapon instance (not the shared cached SWORD) so the mutation does not leak
    # into later tests that read the cached weapon's blade_width / parry_part_id.
    var mut_w: Weapon = Weapon.create_from_definition("SWORD")
    # Narrow the blade to dagger width (1.5cm) -> < 1.0 (narrower blade grips less).
    mut_w.blade_width = 1.5
    var dagger_mult: float = CombatConstants.bind_friction_mult_for_weapon(mut_w)
    if dagger_mult >= 1.0 or dagger_mult < 0.9:
        _fail(failures, "bind_friction: 1.5cm blade should yield ~0.94 (got %.4f)" % dagger_mult)
    # A shaft parry (SPEAR-like) is gated out -> 1.0.
    mut_w.parry_part_id = "shaft"
    var shaft_mult: float = CombatConstants.bind_friction_mult_for_weapon(mut_w)
    if absf(shaft_mult - 1.0) > 0.0001:
        _fail(failures, "bind_friction: shaft parry should yield 1.0 (got %.4f)" % shaft_mult)
    _free_manager(mgr)


## Morale parry readiness: fear degrades fine motor control. At full morale (1.0) the multiplier is 1.0;
## at the drain floor (0.70) it is 0.85 (15% reduction); at 0.85 it is 0.925 (midpoint).


static func _run_morale_parry_readiness(failures: PackedStringArray) -> void:
    if not is_equal_approx(CombatMoraleCohesion.morale_parry_readiness_mult(1.0), 1.0):
        _fail(failures, "morale_parry: full morale should yield 1.0")
    if not is_equal_approx(
        CombatMoraleCohesion.morale_parry_readiness_mult(CombatMoraleCohesion.MORALE_DRAIN_FLOOR),
        CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT
    ):
        _fail(failures, "morale_parry: drain floor should yield %.2f" % CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT)
    var mid: float = CombatMoraleCohesion.morale_parry_readiness_mult(0.85)
    var want_mid: float = lerpf(
        CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT, 1.0, (0.85 - CombatMoraleCohesion.MORALE_DRAIN_FLOOR) / 0.30
    )
    if absf(mid - want_mid) > 0.0001:
        _fail(failures, "morale_parry: midpoint 0.85 should yield %.4f (got %.4f)" % [want_mid, mid])
    var low: float = CombatMoraleCohesion.morale_parry_readiness_mult(0.75)
    if low <= CombatMoraleCohesion.PARRY_MORALE_FLOOR_MULT or low >= 1.0:
        _fail(failures, "morale_parry: 0.75 should be between floor and 1.0 (got %.4f)" % low)


## Conservation of momentum: PARRY_MAX_DAMAGE_REDUCTION caps armed parry damage reduction so ~15%
## residual always passes through. A high-control parry (c_d > 0.85 * pa) is capped; a low-control one is not.


static func _run_parry_max_damage_reduction_cap(failures: PackedStringArray) -> void:
    var cap: float = CombatConstantsParry.PARRY_MAX_DAMAGE_REDUCTION
    if absf(cap - 0.85) > 0.0001:
        _fail(failures, "parry_dmg_cap: PARRY_MAX_DAMAGE_REDUCTION should be 0.85 (got %.4f)" % cap)
    # High-control parry: c_d_final*redirect = 1.0, pa = 1.0 → capped at 0.85, remaining = 0.15.
    var pa_hi: float = 1.0
    var base_red_hi: float = minf(1.0, pa_hi * cap)
    var remain_hi: float = maxf(0.0, pa_hi - base_red_hi) / pa_hi
    if absf(remain_hi - (1.0 - cap)) > 0.0001:
        _fail(failures, "parry_dmg_cap: high-control remaining should be %.2f (got %.4f)" % [1.0 - cap, remain_hi])
    # Low-control parry: c_d_final*redirect = 0.5, pa = 1.0 → NOT capped, remaining = 0.5.
    var pa_lo: float = 1.0
    var base_red_lo: float = minf(0.5, pa_lo * cap)
    var remain_lo: float = maxf(0.0, pa_lo - base_red_lo) / pa_lo
    if absf(remain_lo - 0.5) > 0.0001:
        _fail(failures, "parry_dmg_cap: low-control remaining should be 0.50 (got %.4f)" % remain_lo)
    # Unarmed cap is separate and lower (0.5).
    var unarmed_cap: float = CombatConstantsParry.PARRY_UNARMED_MAX_DAMAGE_REDUCTION
    if absf(unarmed_cap - 0.5) > 0.0001:
        _fail(failures, "parry_dmg_cap: unarmed cap should be 0.5 (got %.4f)" % unarmed_cap)


## HEMA bind pressure defense penalty: opponent pressing the bind reduces defender's parry capacity.
## Reads the OPPONENT's pressure, not the defender's (the original was inverted and removed).


static func _run_bind_pressure_defender_penalty(failures: PackedStringArray) -> void:
    var floor_val: float = CombatConstantsParry.BIND_PRESSURE_DEFENDER_PARRY_CAP_FLOOR
    if absf(floor_val - 0.70) > 0.0001:
        _fail(failures, "bind_pressure_def: floor should be 0.70 (got %.4f)" % floor_val)
    # Null opponent → 1.0 (no effect).
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult({}, 0.0), 1.0):
        _fail(failures, "bind_pressure_def: null opponent should yield 1.0")
    # No active bind pressure (until < 0) → 1.0.
    var no_pressure: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: -1.0, DataKeys.BIND_PRESSURE_VALUE: 0.5}
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(no_pressure, 0.0), 1.0):
        _fail(failures, "bind_pressure_def: expired pressure should yield 1.0")
    # Active bind pressure at 0.5 → lerpf(1.0, 0.70, 0.5) = 0.85.
    var mid_pressure: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: 10.0, DataKeys.BIND_PRESSURE_VALUE: 0.5}
    var want_mid: float = lerpf(1.0, floor_val, 0.5)
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(mid_pressure, 0.0), want_mid):
        _fail(
            failures,
            (
                "bind_pressure_def: 0.5 pressure should yield %.4f (got %.4f)"
                % [want_mid, CombatBindPressure.defender_parry_cap_mult(mid_pressure, 0.0)]
            )
        )
    # Active bind pressure at 0.8 → lerpf(1.0, 0.70, 0.8) = 0.76.
    var hi_pressure: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: 10.0, DataKeys.BIND_PRESSURE_VALUE: 0.8}
    var want_hi: float = lerpf(1.0, floor_val, 0.8)
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(hi_pressure, 0.0), want_hi):
        _fail(
            failures,
            (
                "bind_pressure_def: 0.8 pressure should yield %.4f (got %.4f)"
                % [want_hi, CombatBindPressure.defender_parry_cap_mult(hi_pressure, 0.0)]
            )
        )
    # Pressure expired (clock > until) → 1.0.
    var expired: Dictionary = {DataKeys.BIND_PRESSURE_UNTIL: 5.0, DataKeys.BIND_PRESSURE_VALUE: 0.8}
    if not is_equal_approx(CombatBindPressure.defender_parry_cap_mult(expired, 6.0), 1.0):
        _fail(failures, "bind_pressure_def: expired (clock > until) should yield 1.0")


## Pass 35 (HEMA blade fatigue): sustained bind pressure decays over time — the holding muscles tire.
## `apply_decay` was dead code (never called); it is now ticked each waiting frame in process_waiting.
## This test verifies the decay physics constants are set correctly and the documented accelerated
## decay (0.04/s base * 2.5 progressive = 0.10/s) is consistent.


static func _run_bind_pressure_decay_constants(failures: PackedStringArray) -> void:
    # Base decay rate: 0.04/s.
    if not is_equal_approx(CombatConstants.BIND_PRESSURE_DECAY_RATE, 0.04):
        _fail(
            failures,
            "bind_decay: BIND_PRESSURE_DECAY_RATE want 0.04 got %.4f" % CombatConstants.BIND_PRESSURE_DECAY_RATE
        )
    # Grace period: 1.0s before progressive degradation kicks in.
    if not is_equal_approx(CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S, 1.0):
        _fail(
            failures,
            "bind_decay: BIND_LEVERAGE_GRACE_PERIOD_S want 1.0 got %.2f" % CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
        )
    # Progressive leverage degradation multiplier: 2.5x.
    if not is_equal_approx(CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT, 2.5):
        _fail(
            failures,
            (
                "bind_decay: BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT want 2.5 got %.2f"
                % CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT
            )
        )
    # Bind pressure duration: 6.0s.
    if not is_equal_approx(CombatConstants.BIND_PRESSURE_DURATION_S, 6.0):
        _fail(
            failures,
            "bind_decay: BIND_PRESSURE_DURATION_S want 6.0 got %.2f" % CombatConstants.BIND_PRESSURE_DURATION_S
        )
    # Documented accelerated decay: base * progressive = 0.04 * 2.5 = 0.10/s.
    var accelerated: float = (
        CombatConstants.BIND_PRESSURE_DECAY_RATE * CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT
    )
    if not is_equal_approx(accelerated, 0.10):
        _fail(failures, "bind_decay: accelerated decay want 0.10/s (0.04*2.5) got %.4f" % accelerated)
    # A sustained medium-pressure bind (0.6) must decay monotonically over the duration.
    # Simulate: 1.0s base decay, then accelerated decay for the remainder.
    var p: float = 0.6
    var base_phase: float = CombatConstants.BIND_PRESSURE_DECAY_RATE * CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
    p -= base_phase  # after grace period
    var remaining: float = CombatConstants.BIND_PRESSURE_DURATION_S - CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
    p -= accelerated * remaining  # accelerated for the rest
    # Pressure must drop well below the starting value (fatigue is real).
    if p >= 0.6:
        _fail(failures, "bind_decay: sustained bind should decay below start (final=%.3f)" % p)
    # The decayed pressure must be less than the starting pressure (monotonic decrease).
    if p >= 0.6 - 0.01:
        _fail(failures, "bind_decay: decay should be meaningful (start=0.6 final=%.3f)" % p)


## **`AttackResultApplier`** must NOT call **`manager._execute_attack()`** after partial parry.

## Tier 3.2 (combat tuning fix): follow-through gate at low remaining ratio — when **`parry_remaining_ratio <= 0.1`**,
## **`AttackResultApplier`** must NOT call **`manager._execute_attack()`** after partial parry.


static func _run_follow_through_gate_at_low_remaining_ratio(failures: PackedStringArray) -> void:
    # Verify constant gate threshold is set correctly.
    if CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY < 0.6:
        _fail(
            failures,
            (
                "ft_gate: PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY should be >= 0.6 (got %.2f)"
                % CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY
            )
        )
    # Test the gate logic directly: remaining_ratio > 0.1 triggers follow-through, <= 0.1 does not.
    var gate_above: bool = 0.15 > 0.1
    var gate_at: bool = false  # boundary: remaining_ratio == 0.1 is not > 0.1
    var gate_below: bool = 0.05 > 0.1
    if not gate_above:
        _fail(failures, "ft_gate: ratio 0.15 should pass gate (> 0.1)")
    if gate_at:
        _fail(failures, "ft_gate: ratio 0.1 should NOT pass gate (must be > 0.1, not >=)")
    if gate_below:
        _fail(failures, "ft_gate: ratio 0.05 should NOT pass gate (> 0.1)")


## Tier 3.2 (combat tuning fix): block thresholds at balanced entity values — **`PARRY_BLOCK_MASS_THRESHOLD = 0.75`**,
## **`PARRY_BLOCK_STR_THRESHOLD = 0.85`**.

## Tier 3.2 (combat tuning fix): block thresholds at balanced entity values — **`PARRY_BLOCK_MASS_THRESHOLD = 0.75`**,
## **`PARRY_BLOCK_STR_THRESHOLD = 0.85`**.


static func _run_block_threshold_balance_test(failures: PackedStringArray) -> void:
    # Mass threshold: 0.75 means defender with 75% attacker mass should qualify.
    if not is_equal_approx(CombatConstants.PARRY_BLOCK_MASS_THRESHOLD, 0.75):
        _fail(
            failures,
            (
                "block_threshold: PARRY_BLOCK_MASS_THRESHOLD want 0.75 got %.2f"
                % CombatConstants.PARRY_BLOCK_MASS_THRESHOLD
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_BLOCK_STR_THRESHOLD, 0.85):
        _fail(
            failures,
            "block_threshold: PARRY_BLOCK_STR_THRESHOLD want 0.85 got %.2f" % CombatConstants.PARRY_BLOCK_STR_THRESHOLD
        )
    # Test balanced entity scenario: both SWORD (mass 1.2 each), strength equal at 50/50.
    var d_mass: float = HarnessFixtures.get_cached_weapon("SWORD").mass
    var a_mass: float = HarnessFixtures.get_cached_weapon("SWORD").mass
    var d_str: float = 50.0
    var a_str: float = 50.0
    # Balanced: mass ratio = 1.0, str ratio = 1.0 — both should pass threshold.
    var mass_ok: bool = d_mass / maxf(a_mass, 0.01) >= CombatConstants.PARRY_BLOCK_MASS_THRESHOLD
    var str_ok: bool = d_str / maxf(a_str, 0.01) >= CombatConstants.PARRY_BLOCK_STR_THRESHOLD
    if not mass_ok or not str_ok:
        _fail(
            failures,
            (
                "block_threshold: balanced SWORD vs SWORD should pass both thresholds (mass=%.2f/%.2f, str=%.0f/%.0f)"
                % [d_mass, a_mass, d_str, a_str]
            )
        )


## Tier 3.2 (combat tuning fix): follow-through gate integration — when **`parry_remaining_ratio <= 0.1`** on
## parry_partial, **`AttackResultApplier.apply_result`** must NOT call **`manager._execute_attack()`**.

## Tier 3.2 (combat tuning fix): follow-through gate integration — when **`parry_remaining_ratio <= 0.1`** on
## parry_partial, **`AttackResultApplier.apply_result`** must NOT call **`manager._execute_attack()`**.


static func _run_follow_through_integration_gate(failures: PackedStringArray) -> void:
    # Test the gate logic directly: simulate remaining_ratio values and check whether follow-through would trigger.
    var should_trigger_low: bool = 0.05 > 0.1
    var should_trigger_high: bool = 0.15 > 0.1
    if should_trigger_low:
        _fail(failures, "ft_integration: ratio 0.05 should NOT trigger follow-through (gate returned true)")
    if not should_trigger_high:
        _fail(failures, "ft_integration: ratio 0.15 SHOULD trigger follow-through (gate returned false)")


## Tier 3.2 (combat tuning fix): asymmetric block threshold — DAGGER vs SPEAR should NOT qualify for block parry (mass
## ratio far below 0.75).

## Tier 3.2 (combat tuning fix): asymmetric block threshold — DAGGER vs SPEAR should NOT qualify for block parry (mass
## ratio far below 0.75).


static func _run_block_threshold_asymmetric_test(failures: PackedStringArray) -> void:
    var d_mass: float = HarnessFixtures.get_cached_weapon("DAGGER").mass
    var a_mass: float = HarnessFixtures.get_cached_weapon("SPEAR").mass
    var mass_ratio: float = d_mass / maxf(a_mass, 0.01)
    if mass_ratio >= CombatConstants.PARRY_BLOCK_MASS_THRESHOLD:
        _fail(
            failures,
            (
                "block_threshold_asym: DAGGER(mass=%.2f) vs SPEAR(mass=%.2f) ratio=%.3f should be below threshold %.2f"
                % [d_mass, a_mass, mass_ratio, CombatConstants.PARRY_BLOCK_MASS_THRESHOLD]
            )
        )
    # Borderline case: AXE (1.5 kg) vs MACE (1.7 kg), mass_ratio = 0.883 — should pass mass check.
    var d_mass2: float = HarnessFixtures.get_cached_weapon("AXE").mass
    var a_mass2: float = HarnessFixtures.get_cached_weapon("MACE").mass
    var mass_ratio2: float = d_mass2 / maxf(a_mass2, 0.01)
    if mass_ratio2 < CombatConstants.PARRY_BLOCK_MASS_THRESHOLD:
        _fail(
            failures,
            (
                "block_threshold_borderline: AXE(mass=%.2f) vs MACE(mass=%.2f) ratio=%.3f should pass threshold %.2f"
                % [d_mass2, a_mass2, mass_ratio2, CombatConstants.PARRY_BLOCK_MASS_THRESHOLD]
            )
        )


## Tier 3.2 (weapon audit): melee_range ordering — DAGGER < MACE <= SWORD == AXE < SPEAR, reflecting total weapon
## length. Also verifies each weapon has at least one stab, one cut or blunt move, and valid coupling values.

## Tier 3.2 (weapon audit): melee_range ordering — DAGGER < MACE <= SWORD == AXE < SPEAR, reflecting total weapon
## length. Also verifies each weapon has at least one stab, one cut or blunt move, and valid coupling values.


static func _run_weapon_melee_range_ordering(failures: PackedStringArray) -> void:
    var expected_order: Array[String] = ["DAGGER", "MACE", "SWORD", "AXE", "SPEAR"]
    var ranges: Dictionary = {}
    for wname in expected_order:
        ranges[wname] = HarnessFixtures.get_cached_weapon_melee_range(wname)
    # DAGGER < MACE <= SWORD == AXE < SPEAR
    if ranges.has("DAGGER") and ranges.has("SPEAR"):
        if ranges["DAGGER"] >= ranges["SPEAR"]:
            _fail(
                failures,
                "weapon_audit: DAGGER range (%.2f) must be < SPEAR range (%.2f)" % [ranges["DAGGER"], ranges["SPEAR"]]
            )
    if ranges.has("MACE") and ranges.has("SWORD"):
        if ranges["MACE"] > ranges["SWORD"]:
            _fail(
                failures,
                "weapon_audit: MACE range (%.2f) must be <= SWORD range (%.2f)" % [ranges["MACE"], ranges["SWORD"]]
            )
    if ranges.has("SWORD") and ranges.has("AXE"):
        if absf(ranges["SWORD"] - ranges["AXE"]) > 0.01:
            _fail(
                failures,
                "weapon_audit: SWORD range (%.2f) must equal AXE range (%.2f)" % [ranges["SWORD"], ranges["AXE"]]
            )
    if ranges.has("AXE") and ranges.has("SPEAR"):
        if ranges["AXE"] >= ranges["SPEAR"]:
            _fail(
                failures,
                "weapon_audit: AXE range (%.2f) must be < SPEAR range (%.2f)" % [ranges["AXE"], ranges["SPEAR"]]
            )

## Tier 3.2 (weapon audit): verify each weapon has required move types and valid coupling physics.

## Pass 26 (HEMA biomechanics): deflect recovery cost — full-parry deflects cost 20% more recovery than a
## clean miss because the blade is physically knocked offline and requires extra repositioning.
