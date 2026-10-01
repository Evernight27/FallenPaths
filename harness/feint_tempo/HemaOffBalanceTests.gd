class_name HemaOffBalanceTests

extends HemaTestBase

## HEMA off-balance commit/measure surface: attack damage, feint + thrust + bind commit,
## angular advantage, measure gates, regain-footing and cumulative off-balance windows.


static func run_off_balance_attack_dmg_constant(failures: PackedStringArray) -> void:
    # Must be a reduction (less than 1.0).
    _assert(
        CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT < 1.0,
        failures,
        "ob_atk: OFF_BALANCE_ATTACK_DMG_MULT (%.2f) should be < 1.0" % CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT
    )
    # Must be > 0 (an off-balance strike still lands, just weaker).
    _assert(
        CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT > 0.0,
        failures,
        "ob_atk: OFF_BALANCE_ATTACK_DMG_MULT (%.2f) should be > 0.0" % CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT
    )
    # Symmetric with the defensive penalty — same magnitude in both directions.
    _assert_eq(
        str(CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT),
        str(CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT),
        failures,
        (
            "ob_atk: OFF_BALANCE_ATTACK_DMG_MULT should equal OFF_BALANCE_PARRY_CAPACITY_MULT (%.2f vs %.2f)"
            % [
                CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT,
                CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT,
            ]
        )
    )


## Feint commit off-balance: a failed feint leaves the attacker more committed than a failed
## direct strike. The extra off-balance window is a positive, bounded constant exposed through
## the CombatConstants facade.


static func run_feint_commit_off_balance_constant(failures: PackedStringArray) -> void:
    # The extra window must be positive (a feint commit is always more exposing than a miss).
    _assert(
        CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S > 0.0,
        failures,
        (
            "feint_commit: FEINT_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be > 0"
            % CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S
        )
    )
    # Bounded so it cannot exceed the base miss off-balance floor (a commit penalty, not a stun).
    _assert(
        CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S < CombatConstants.OFF_BALANCE_DURATION_S,
        failures,
        (
            "feint_commit: FEINT_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be < OFF_BALANCE_DURATION_S (%.2f)"
            % [
                CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S,
                CombatConstants.OFF_BALANCE_DURATION_S,
            ]
        )
    )
    # Facade method returns the same value.
    _assert_eq(
        str(CombatConstants.feint_commit_off_balance_extra_s()),
        str(CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S),
        failures,
        (
            "feint_commit: feint_commit_off_balance_extra_s() should return the constant got '%s'"
            % str(CombatConstants.feint_commit_off_balance_extra_s())
        )
    )


## Angular advantage: voiding outside an opponent's strong side grants a bounded positional damage
## bonus against that specific target only. The constant is > 1.0 and the reader gates on both
## the clock window and the target id.


static func run_angular_advantage_constant_and_reader(failures: PackedStringArray) -> void:
    # The bonus must be > 1.0 (a positional advantage, not a penalty).
    _assert(
        CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT > 1.0,
        failures,
        "ang_adv: ANGULAR_ADVANTAGE_DMG_MULT (%.2f) should be > 1.0" % CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT
    )
    # Bounded so it cannot exceed a doubling of damage.
    _assert(
        CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT <= 1.5,
        failures,
        "ang_adv: ANGULAR_ADVANTAGE_DMG_MULT (%.2f) should be <= 1.5" % CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT
    )

    var mgr: Node = _make_1v1_sword()
    var c0: Dictionary = mgr.combatants[0]
    var c1: Dictionary = mgr.combatants[1]
    var id0: int = CombatantEntityAccess.id_int(c0)
    var id1: int = CombatantEntityAccess.id_int(c1)
    var clock: float = CombatantEntityAccess.combat_clock_float(mgr)

    # No advantage set: reader returns false for both targets.
    _assert(
        not CombatBindPressure.has_angular_advantage_over(c0, id1, clock),
        failures,
        "ang_adv: reader should be false when no advantage is set"
    )

    # Grant an advantage from c0 against c1; valid for c1, not for c0 (self) or a third id.
    c0[DataKeys.BIND_ANGULAR_ADVANTAGE_UNTIL] = clock + 4.0
    c0[DataKeys.BIND_ANGULAR_ADVANTAGE_TARGET_ID] = id1
    _assert(
        CombatBindPressure.has_angular_advantage_over(c0, id1, clock),
        failures,
        "ang_adv: reader should be true for the voided target"
    )
    _assert(
        not CombatBindPressure.has_angular_advantage_over(c0, id0, clock),
        failures,
        "ang_adv: reader should be false for the self id"
    )

    # Expired window returns false.
    c0[DataKeys.BIND_ANGULAR_ADVANTAGE_UNTIL] = clock - 0.1
    _assert(
        not CombatBindPressure.has_angular_advantage_over(c0, id1, clock),
        failures,
        "ang_adv: reader should be false once the window has expired"
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## Bind-wrestle transition: the off-balance window granted to the target on a successful wrestle
## is a positive, bounded value. The has_wrestling_available gate returns false when no flag is set,
## true when the flag is present.


static func run_bind_wrestle_constant_and_gate(failures: PackedStringArray) -> void:
    # The off-balance window must be positive.
    _assert(
        CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S > 0.0,
        failures,
        (
            "bind_wrestle: BIND_WRESTLE_TARGET_OFF_BALANCE_S (%.2f) should be > 0"
            % CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S
        )
    )
    # Bounded so it cannot exceed 3s (a single wrestle shouldn't stun).
    _assert(
        CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S <= 3.0,
        failures,
        (
            "bind_wrestle: BIND_WRESTLE_TARGET_OFF_BALANCE_S (%.2f) should be <= 3.0"
            % CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S
        )
    )
    # Orientation axis: a rear-arc grapple unroots the target more than face-on — the target resists
    # a forward pull against their own base of support. Same shared map; face-on is D001-neutral.
    var front_mult: float = CombatConstants.hit_orientation_stagger_mult("front")
    var rear_mult: float = CombatConstants.hit_orientation_stagger_mult("rear")
    var flank_mult: float = CombatConstants.hit_orientation_stagger_mult("flank")
    _assert(
        is_equal_approx(front_mult, 1.0) and rear_mult > flank_mult and flank_mult > front_mult,
        failures,
        (
            "bind_wrestle_orient: rear grapple should unroot more than flank, flank more than face-on "
            + "(rear=%.3f flank=%.3f front=%.3f)" % [rear_mult, flank_mult, front_mult]
        )
    )
    # Bounded: even a rear-arc full-strength wrestle stays under the cumulative cap.
    _assert(
        CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S * rear_mult < CombatConstants.OFF_BALANCE_MAX_WINDOW_S,
        failures,
        (
            "bind_wrestle_orient: rear-arc window should stay under the cumulative cap "
            + (
                "(got %.3f vs cap %.1f)"
                % [
                    CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S * rear_mult,
                    CombatConstants.OFF_BALANCE_MAX_WINDOW_S
                ]
            )
        )
    )

    var mgr: Node = _make_1v1_sword()
    var c0: Dictionary = mgr.combatants[0]
    var c1: Dictionary = mgr.combatants[1]

    # No flag set: gate returns false.
    _assert(
        not CombatBindPressure.has_wrestling_available(c0),
        failures,
        "bind_wrestle: has_wrestling_available should be false when no flag is set"
    )

    # Set the flag: gate returns true.
    c0[DataKeys.BIND_WRESTLING_AVAILABLE] = true
    _assert(
        CombatBindPressure.has_wrestling_available(c0),
        failures,
        "bind_wrestle: has_wrestling_available should be true when flag is set"
    )
    # Flag is erased, gate returns false again.
    c0.erase(DataKeys.BIND_WRESTLING_AVAILABLE)
    _assert(
        not CombatBindPressure.has_wrestling_available(c0),
        failures,
        "bind_wrestle: has_wrestling_available should be false after flag erased"
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## Off-balance dodge chance: an off-balance defender's evasive step is impaired — a compromised
## center of gravity makes stepping away from an incoming strike less effective. The multiplier
## is in (0, 1) and symmetric with the parry-capacity penalty (both reduce defender capability).


static func run_off_balance_dodge_chance_constant(failures: PackedStringArray) -> void:
    # Must be a reduction (less than 1.0).
    _assert(
        CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT < 1.0,
        failures,
        "ob_dodge: OFF_BALANCE_DODGE_CHANCE_MULT (%.2f) should be < 1.0" % CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT
    )
    # Must be > 0 (an off-balance defender can still attempt to dodge, just less effectively).
    _assert(
        CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT > 0.0,
        failures,
        "ob_dodge: OFF_BALANCE_DODGE_CHANCE_MULT (%.2f) should be > 0.0" % CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT
    )
    # Mild: off-balance reduces stepping but doesn't make evasion impossible (more lenient than parry,
    # which is more dependent on center-of-gravity stability).
    _assert(
        CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT > CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT,
        failures,
        (
            "ob_dodge: OFF_BALANCE_DODGE_CHANCE_MULT (%.2f) should be > OFF_BALANCE_PARRY_CAPACITY_MULT (%.2f)"
            % [
                CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT,
                CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT,
            ]
        )
    )


## Proportional off-balance penalty: the penalty fades from full strength (just lost footing) to none
## (fully settled) across the off-balance window, instead of staying flat at full strength. Locks in
## the off_balance_depth / off_balance_penalty_mult math so it cannot silently regress to binary.


static func run_off_balance_proportional_penalty(failures: PackedStringArray) -> void:
    var full: float = CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
    var now: float = CombatTiming.now_seconds()
    # Settled (no off-balance): depth ~0, penalty neutral 1.0.
    var settled: Dictionary = {}
    _assert(
        absf(PassiveParryContext.off_balance_depth(settled)) < 0.001,
        failures,
        "ob_fade: settled depth should be ~0 got %f" % PassiveParryContext.off_balance_depth(settled)
    )
    _assert(
        absf(PassiveParryContext.off_balance_penalty_mult(settled, full) - 1.0) < 0.001,
        failures,
        "ob_fade: settled penalty should be ~1.0 got %f" % PassiveParryContext.off_balance_penalty_mult(settled, full)
    )
    # Just lost footing (full window remaining): depth ~1, penalty at full strength.
    var fresh: Dictionary = {}
    fresh[DataKeys.PA_OFF_BALANCE_UNTIL] = now + 10.0
    fresh[DataKeys.PA_OFF_BALANCE_TOTAL] = 10.0
    _assert(
        absf(PassiveParryContext.off_balance_depth(fresh) - 1.0) < 0.05,
        failures,
        "ob_fade: fresh depth should be ~1 got %f" % PassiveParryContext.off_balance_depth(fresh)
    )
    _assert(
        absf(PassiveParryContext.off_balance_penalty_mult(fresh, full) - full) < 0.05,
        failures,
        (
            "ob_fade: fresh penalty should be ~full (%.3f) got %f"
            % [full, PassiveParryContext.off_balance_penalty_mult(fresh, full)]
        )
    )
    # Halfway through recovery: penalty strictly between settled (1.0) and full.
    var half: Dictionary = {}
    half[DataKeys.PA_OFF_BALANCE_UNTIL] = now + 5.0
    half[DataKeys.PA_OFF_BALANCE_TOTAL] = 10.0
    var half_penalty: float = PassiveParryContext.off_balance_penalty_mult(half, full)
    _assert(
        half_penalty > minf(full, 1.0) + 0.01 and half_penalty < maxf(full, 1.0) - 0.01,
        failures,
        "ob_fade: mid-window penalty %.3f should be strictly between %.3f and %.3f" % [half_penalty, full, 1.0]
    )
    # Legacy combatant (only until set, total unknown): full penalty preserved (backward compatible).
    var legacy: Dictionary = {}
    legacy[DataKeys.PA_OFF_BALANCE_UNTIL] = now + 10.0
    _assert(
        absf(PassiveParryContext.off_balance_penalty_mult(legacy, full) - full) < 0.05,
        failures,
        (
            "ob_fade: legacy (no total) penalty should be ~full (%.3f) got %f"
            % [full, PassiveParryContext.off_balance_penalty_mult(legacy, full)]
        )
    )


## Bind follow-through: while actively holding a bind on the target, the striker gets a modest
## damage bonus. The constant is a bounded >1.0 value, and the gate only fires when the bind
## partner is the strike target (a third combatant is not affected).


static func run_bind_follow_through_constant_and_gate(failures: PackedStringArray) -> void:
    # Bounded bonus: > 1.0 (it's a bonus) but capped so it cannot exceed +50%.
    _assert(
        CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT > 1.0,
        failures,
        "bind_ft: BIND_FOLLOW_THROUGH_DMG_MULT (%.2f) should be > 1.0" % CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT
    )
    _assert(
        CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT <= 1.5,
        failures,
        "bind_ft: BIND_FOLLOW_THROUGH_DMG_MULT (%.2f) should be <= 1.5" % CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT
    )

    var mgr: Node = _make_1v1_sword()
    var c0: Dictionary = mgr.combatants[0]
    var c1: Dictionary = mgr.combatants[1]
    var id0: int = CombatantEntityAccess.id_int(c0)
    var id1: int = CombatantEntityAccess.id_int(c1)
    var clock: float = CombatantEntityAccess.combat_clock_float(mgr)

    # No bind: is_in_bind is false.
    _assert(
        not CombatBindPressure.is_in_bind(c0, clock), failures, "bind_ft: is_in_bind should be false with no bind set"
    )

    # Grant c0 a live bind on c1: gate is true for partner c1, false for self/other.
    c0[DataKeys.BIND_PRESSURE_UNTIL] = clock + 4.0
    c0[DataKeys.BIND_PARTNER_ID] = id1
    _assert(
        CombatBindPressure.is_in_bind(c0, clock),
        failures,
        "bind_ft: is_in_bind should be true when a live bind partner is set"
    )
    _assert(
        CombatBindPressure.get_bind_partner_id(c0) == id1,
        failures,
        "bind_ft: get_bind_partner_id should return the bound partner id"
    )

    # Graduated bonus: follow_through_dmg_mult scales with live pressure level (consumes the
    # previously-dead get_pressure_level). light < medium < hard, each > 1.0, hard == the constant.
    var ft_light: float = _follow_through_at(c0, 0.3, clock)
    var ft_medium: float = _follow_through_at(c0, 0.6, clock)
    var ft_hard: float = _follow_through_at(c0, 0.9, clock)
    _assert(ft_light > 1.0, failures, "bind_ft: light follow-through (%.3f) should be > 1.0" % ft_light)
    _assert(ft_medium > ft_light, failures, "bind_ft: medium (%.3f) should exceed light (%.3f)" % [ft_medium, ft_light])
    _assert(ft_hard > ft_medium, failures, "bind_ft: hard (%.3f) should exceed medium (%.3f)" % [ft_hard, ft_medium])
    _assert(
        is_equal_approx(ft_hard, CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT),
        failures,
        (
            "bind_ft: hard follow-through (%.3f) should equal BIND_FOLLOW_THROUGH_DMG_MULT (%.3f)"
            % [ft_hard, CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT]
        )
    )
    # No bind -> no bonus.
    var ft_none: float = _follow_through_at(c0, -1.0, -1.0)
    _assert(ft_none == 1.0, failures, "bind_ft: no-bind follow-through should be 1.0 got %.3f" % ft_none)
    HarnessCore._free_manager_restore_global_rng(mgr)


## HEMA: a fighter mid-guard-change has a blade in transit — a strike into the transition lands on an
## unguarded line. The attack-side payoff is a modest, bounded damage multiplier (symmetric with the
## defensive parry/dodge penalties already applied during the transition).


static func run_form_switch_vulnerability_constant_and_gate(failures: PackedStringArray) -> void:
    # Bounded bonus: > 1.0 but capped so it cannot exceed +50%.
    _assert(
        CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT > 1.0,
        failures,
        (
            "fsw_vuln: FORM_SWITCH_VULNERABILITY_DMG_MULT (%.2f) should be > 1.0"
            % CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT
        )
    )
    _assert(
        CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT <= 1.5,
        failures,
        (
            "fsw_vuln: FORM_SWITCH_VULNERABILITY_DMG_MULT (%.2f) should be <= 1.5"
            % CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT
        )
    )

    # The attack resolver keys off STATE_FORM_SWITCH; confirm that constant is the expected string.
    _assert(
        CombatConstants.STATE_FORM_SWITCH == "form_switch",
        failures,
        "fsw_vuln: STATE_FORM_SWITCH (%s) should be 'form_switch'" % CombatConstants.STATE_FORM_SWITCH
    )

    # Gate logic: a combatant in the form-switch state is detected by the same reader the resolver uses;
    # a combatant in a normal state is not.
    var mgr: Node = _make_1v1_sword()
    var c0: Dictionary = mgr.combatants[0]
    c0[DataKeys.COMBATANT_STATE] = CombatConstants.STATE_FORM_SWITCH
    _assert(
        CombatantEntityAccess.state_str(c0) == CombatConstants.STATE_FORM_SWITCH,
        failures,
        "fsw_vuln: combatant set to STATE_FORM_SWITCH should read back as form_switch"
    )
    c0[DataKeys.COMBATANT_STATE] = ""
    _assert(
        CombatantEntityAccess.state_str(c0) != CombatConstants.STATE_FORM_SWITCH,
        failures,
        "fsw_vuln: combatant cleared of state should not read as form_switch"
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## HEMA nach/Vorschlag: after a landed strike the attacker gets a short fast re-commit window against
## the off-balance victim. The constant is a bounded speed-up (< 1.0) and is deliberately SLOWER than
## the blade-catch riposte chain (a completed strike is controlled commitment, not a parry reposition).


static func run_hit_continuation_constant_and_gate(failures: PackedStringArray) -> void:
    _assert(
        CombatConstants.HIT_CONTINUATION_WINDUP_MULT < 1.0,
        failures,
        "hit_cont: HIT_CONTINUATION_WINDUP_MULT (%.2f) should be < 1.0" % CombatConstants.HIT_CONTINUATION_WINDUP_MULT
    )
    _assert(
        CombatConstants.HIT_CONTINUATION_WINDUP_MULT > 0.0,
        failures,
        "hit_cont: HIT_CONTINUATION_WINDUP_MULT (%.2f) should be > 0.0" % CombatConstants.HIT_CONTINUATION_WINDUP_MULT
    )
    # HEMA ordering: a blade-catch riposte is the fastest counter; a landed-strike follow-up is slower.
    _assert(
        CombatConstants.HIT_CONTINUATION_WINDUP_MULT > CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT,
        failures,
        (
            "hit_cont: HIT_CONTINUATION_WINDUP_MULT (%.2f) should be slower (>) than RIPOSTE_CHAIN_WINDUP_MULT (%.2f)"
            % [CombatConstants.HIT_CONTINUATION_WINDUP_MULT, CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT]
        )
    )
    _assert(
        CombatConstants.HIT_CONTINUATION_WINDOW_S > 0.0,
        failures,
        "hit_cont: HIT_CONTINUATION_WINDOW_S (%.2f) should be > 0" % CombatConstants.HIT_CONTINUATION_WINDOW_S
    )
    _assert(
        CombatConstants.is_feature_hit_continuation_window_enabled(),
        failures,
        "hit_cont: hit-continuation window feature should be enabled"
    )

    # Gate logic: no grant -> neutral; after grant -> the mult, and only against the just-hit target.
    var mgr: Node = _make_1v1_sword()
    var atk: Dictionary = mgr.combatants[0]
    var tgt: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var tgt_id: int = CombatantEntityAccess.id_int(tgt)
    _assert(
        CounterTempo.hit_continuation_windup_mult(mgr, atk, tgt_id) == 1.0,
        failures,
        "hit_cont: wind-up mult should be 1.0 before a continuation is granted"
    )
    CounterTempo.grant_hit_continuation(mgr, atk, tgt_id)
    _assert(
        CounterTempo.hit_continuation_windup_mult(mgr, atk, tgt_id) == CombatConstants.HIT_CONTINUATION_WINDUP_MULT,
        failures,
        (
            "hit_cont: wind-up mult (%.2f) should equal the constant after grant"
            % CounterTempo.hit_continuation_windup_mult(mgr, atk, tgt_id)
        )
    )
    # Scoped to the just-hit target: attacking the attacker itself is not a continuation.
    _assert(
        CounterTempo.hit_continuation_windup_mult(mgr, atk, atk_id) == 1.0,
        failures,
        "hit_cont: continuation should be target-scoped (self attack not affected)"
    )
    CounterTempo.clear_hit_continuation(atk)
    _assert(
        CounterTempo.hit_continuation_windup_mult(mgr, atk, tgt_id) == 1.0,
        failures,
        "hit_cont: wind-up mult should return to 1.0 after clear"
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## HEMA: a whiffed thrust/lunge leaves the attacker more committed than a cut.
## The extra off-balance should be positive, bounded, and distinct from the feint extra.


static func run_thrust_commit_off_balance_constant(failures: PackedStringArray) -> void:
    _assert(
        CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S > 0.0,
        failures,
        (
            "thrust_commit: THRUST_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be > 0"
            % CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S
        )
    )
    _assert(
        CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S < CombatConstants.OFF_BALANCE_DURATION_S,
        failures,
        (
            "thrust_commit: THRUST_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be < OFF_BALANCE_DURATION_S (%.2f)"
            % [
                CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S,
                CombatConstants.OFF_BALANCE_DURATION_S,
            ]
        )
    )
    # Facade method returns the same value.
    _assert_eq(
        str(CombatConstants.thrust_commit_off_balance_extra_s()),
        str(CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S),
        failures,
        (
            "thrust_commit: thrust_commit_off_balance_extra_s() should return the constant got '%s'"
            % str(CombatConstants.thrust_commit_off_balance_extra_s())
        )
    )
    # Verify the contact_type resolver returns "stab" for a known thrust move.
    _assert(
        WeaponConstants.contact_type_for_move_id("spear_thrust") == WeaponConstants.ATTACK_TYPE_STAB,
        failures,
        "thrust_commit: contact_type_for_move_id('spear_thrust') should return 'stab'"
    )


## HEMA: a strike out of measure deals reduced damage (complements the hit-chance penalty).
## Constants should be in (0, 1) and the feature flag should be enabled by default.


static func run_measure_damage_commit_constant_and_gate(failures: PackedStringArray) -> void:
    _assert(
        CombatConstants.is_feature_measure_damage_commit_enabled(),
        failures,
        "measure_dmg: feature flag should be enabled by default"
    )
    _assert(
        CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR > 0.0 and CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR < 1.0,
        failures,
        (
            "measure_dmg: MEASURE_DMG_OVER_REACH_FLOOR (%.2f) should be in (0, 1)"
            % CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR
        )
    )
    _assert(
        CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR > 0.0 and CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR < 1.0,
        failures,
        (
            "measure_dmg: MEASURE_DMG_UNDER_REACH_FLOOR (%.2f) should be in (0, 1)"
            % CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR
        )
    )
    # Damage floor should not be stricter (lower) than the corresponding hit-chance floor:
    # even a badly out-of-measure strike still lands with meaningful force.
    _assert(
        CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR >= CombatConstants.MEASURE_HIT_CHANCE_FLOOR,
        failures,
        (
            "measure_dmg: over-reach dmg floor (%.2f) should be >= hit-chance floor (%.2f)"
            % [CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR, CombatConstants.MEASURE_HIT_CHANCE_FLOOR]
        )
    )
    _assert(
        CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR >= CombatConstants.MEASURE_UNDER_REACH_HIT_CHANCE_FLOOR,
        failures,
        (
            "measure_dmg: under-reach dmg floor (%.2f) should be >= hit-chance floor (%.2f)"
            % [CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR, CombatConstants.MEASURE_UNDER_REACH_HIT_CHANCE_FLOOR]
        )
    )


## HEMA reach priority: a defender with the longer weapon reaches past the attacker, who is inside the
## defender's natural measure. The damage floor should be milder (higher) than the self-measure floors
## because it is a relational positional penalty, not the attacker's own flawed commit.


static func run_measure_defender_reach_constant(failures: PackedStringArray) -> void:
    _assert(
        (
            CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR > 0.0
            and CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR < 1.0
        ),
        failures,
        (
            "measure_def_reach: MEASURE_DMG_DEFENDER_REACH_FLOOR (%.2f) should be in (0, 1)"
            % CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR
        )
    )
    # Milder (higher) than the self-measure over-reach floor: positional threat < personal commit error.
    _assert(
        CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR > CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR,
        failures,
        (
            "measure_def_reach: defender-reach floor (%.2f) should be > over-reach floor (%.2f)"
            % [
                CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR,
                CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR,
            ]
        )
    )


## Regain Footing: an off-balance fighter may spend their turn to re-root and halve the remaining
## off-balance window (instead of riding it out). Costs the turn like WAIT (gauge resets to 0 via
## skip_turn). Verify the resolve effect, the post-action gauge reset, and rejection when settled.


static func run_regain_footing_move(failures: PackedStringArray) -> void:
    var mgr: Node = _make_1v1_sword()
    var c0: Dictionary = mgr.combatants[0]
    var id0: int = CombatantEntityAccess.id_int(c0)
    # Put c0 off-balance with a known 2.0s window; state must be WAITING for skip_turn's guard.
    var now: float = CombatTiming.now_seconds()
    c0[DataKeys.PA_OFF_BALANCE_UNTIL] = now + 2.0
    c0[DataKeys.PA_OFF_BALANCE_TOTAL] = 2.0
    c0[DataKeys.COMBATANT_STATE] = CombatConstants.STATE_WAITING
    c0[DataKeys.COMBATANT_GAUGE] = 100.0
    _assert(PassiveParryContext.is_off_balance(c0), failures, "regain_footing: fixture should be off-balance")
    var ok: bool = mgr.resolve_action(id0, id0, CombatConstants.MOVE_ID_REGAIN_FOOTING, {})
    _assert(ok, failures, "regain_footing: resolve_action should succeed for off-balance self-target")
    var until_after: float = c0.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0)
    _assert(
        until_after > now and until_after <= now + 1.0 + 0.05,
        failures,
        "regain_footing: off-balance window should be ~halved (until=%.3f now=%.3f)" % [until_after, now]
    )
    # total is untouched, so depth drops: the remaining window is now shorter than the recorded total.
    var depth_after: float = PassiveParryContext.off_balance_depth(c0)
    _assert(
        depth_after < 1.0, failures, "regain_footing: depth should drop below 1.0 after re-root got %.3f" % depth_after
    )
    # Costs the turn like WAIT: skip_turn resets gauge to 0 on resolve.
    var gauge_after: float = CombatantEntityAccess.gauge_float(c0)
    _assert(
        is_equal_approx(gauge_after, 0.0),
        failures,
        "regain_footing: gauge should reset to 0 after the turn (got %.2f)" % gauge_after
    )
    # Settled fighter: the move is rejected and has no re-root effect (no off-balance window is created).
    c0.erase(DataKeys.PA_OFF_BALANCE_UNTIL)
    c0.erase(DataKeys.PA_OFF_BALANCE_TOTAL)
    c0[DataKeys.COMBATANT_GAUGE] = 100.0
    var ok_settled: bool = mgr.resolve_action(id0, id0, CombatConstants.MOVE_ID_REGAIN_FOOTING, {})
    _assert(not ok_settled, failures, "regain_footing: should reject when not off-balance")
    _assert(
        not PassiveParryContext.is_off_balance(c0),
        failures,
        "regain_footing: rejected move should not create an off-balance window"
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## Cumulative off-balance: repeated events pile on the remaining window (bounded by the cap) rather
## than resetting it. Verifies extension, the cap, and that a fresh re-stagger reads full depth.


static func run_off_balance_cumulative_window(failures: PackedStringArray) -> void:
    var c: Dictionary = {}
    # Fresh event: window equals the fresh duration.
    var t1: float = PassiveParryContext.apply_off_balance_window(c, 0.8)
    _assert(is_equal_approx(t1, 0.8), failures, "cumulative: fresh window should equal 0.8 got %.3f" % t1)
    _assert(PassiveParryContext.is_off_balance(c), failures, "cumulative: should be off-balance after first event")
    # Second event immediately: remaining ~0.8 + 0.8 extends past the single-event duration.
    var t2: float = PassiveParryContext.apply_off_balance_window(c, 0.8)
    _assert(
        t2 > 0.8 and t2 <= 1.6 + 0.05,
        failures,
        "cumulative: second event should extend the window (0.8, 1.6] got %.3f" % t2
    )
    # Depth is high right after a re-stagger (just got hit again).
    _assert(
        PassiveParryContext.off_balance_depth(c) > 0.9,
        failures,
        "cumulative: depth should be ~full after re-stagger got %.3f" % PassiveParryContext.off_balance_depth(c)
    )
    # A large fresh event while already off-balance is clamped to the cap.
    var t3: float = PassiveParryContext.apply_off_balance_window(c, 99.0)
    _assert(
        is_equal_approx(t3, CombatConstants.OFF_BALANCE_MAX_WINDOW_S),
        failures,
        (
            "cumulative: stacked window should clamp to the cap (%.1f) got %.3f"
            % [CombatConstants.OFF_BALANCE_MAX_WINDOW_S, t3]
        )
    )


## Lifecycle invariant across Regain Footing -> re-strike: the one path where the stale (larger-than-
## remaining) TOTAL feeds apply_off_balance_window's `old_remaining + fresh`. After re-rooting (halves
## remaining, leaves total), a re-strike must re-ignite to full depth, extend the window beyond the
## halved remaining, and keep total >= remaining so depth never clamps stuck. Locks the bookkeeping.


static func run_off_balance_regain_then_restrike_lifecycle(failures: PackedStringArray) -> void:
    var mgr: Node = _make_1v1_sword()
    var c0: Dictionary = mgr.combatants[0]
    var id0: int = CombatantEntityAccess.id_int(c0)
    var now: float = CombatTiming.now_seconds()
    c0[DataKeys.PA_OFF_BALANCE_UNTIL] = now + 2.0
    c0[DataKeys.PA_OFF_BALANCE_TOTAL] = 2.0
    c0[DataKeys.COMBATANT_STATE] = CombatConstants.STATE_WAITING
    c0[DataKeys.COMBATANT_GAUGE] = 100.0
    _assert(
        is_equal_approx(PassiveParryContext.off_balance_depth(c0), 1.0),
        failures,
        "life: fresh 2.0s window should read full depth got %.3f" % PassiveParryContext.off_balance_depth(c0)
    )
    # Real re-root resolve: halves remaining, leaves total untouched, costs the turn.
    var ok: bool = mgr.resolve_action(id0, id0, CombatConstants.MOVE_ID_REGAIN_FOOTING, {})
    _assert(ok, failures, "life: Regain Footing resolve should succeed")
    var remaining_after_root: float = maxf(
        0.0, c0.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0) - CombatTiming.now_seconds()
    )
    _assert(
        remaining_after_root > 0.0 and remaining_after_root <= 1.0 + 0.05,
        failures,
        "life: re-root should halve the 2.0s window to ~1.0s got %.3f" % remaining_after_root
    )
    # Re-strike (strike path) while still staggered: extends the halved window and re-ignites depth.
    var t: float = PassiveParryContext.apply_off_balance_window(c0, 0.8)
    var remaining_after_strike: float = maxf(
        0.0, c0.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0) - CombatTiming.now_seconds()
    )
    _assert(
        remaining_after_strike > remaining_after_root,
        failures,
        (
            "life: re-strike should extend the post-root window (%.3f > %.3f)"
            % [remaining_after_strike, remaining_after_root]
        )
    )
    _assert(
        t > remaining_after_root,
        failures,
        "life: new window total should exceed the halved remaining (%.3f > %.3f)" % [t, remaining_after_root]
    )
    _assert(
        PassiveParryContext.off_balance_depth(c0) > 0.9,
        failures,
        "life: re-strike should re-ignite to ~full depth got %.3f" % PassiveParryContext.off_balance_depth(c0)
    )
    # Invariant: total >= remaining and depth <= 1.0 at all times (never clamps stuck / goes negative).
    var total_now: float = c0.get(DataKeys.PA_OFF_BALANCE_TOTAL, 0.0)
    _assert(
        total_now >= remaining_after_strike - 0.001 and PassiveParryContext.off_balance_depth(c0) <= 1.0,
        failures,
        (
            "life: invariant total>=remaining / depth<=1 violated (total=%.3f remaining=%.3f depth=%.3f)"
            % [total_now, remaining_after_strike, PassiveParryContext.off_balance_depth(c0)]
        )
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## Glancing/negligible strike separation: a graze must not stagger the defender as hard as a clean
## hit, and a negligible chip must not stagger at all. Verifies the outcome multiplier mapping, the
## fail-safe for unknown outcomes, and that the glancing window composes under the part multipliers.


static func run_off_balance_glancing_strike(failures: PackedStringArray) -> void:
    # Constant is a true reduction in (0, 1).
    _assert(
        CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT > 0.0 and CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT < 1.0,
        failures,
        (
            "glancing_ob: HIT_GLANCING_OFF_BALANCE_MULT (%.2f) should be in (0, 1)"
            % CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT
        )
    )
    # Outcome mapping: clean = full, glancing = the constant, negligible = none.
    _assert(
        is_equal_approx(CombatConstants.hit_off_balance_outcome_mult("hit"), 1.0),
        failures,
        "glancing_ob: clean hit should map to 1.0"
    )
    _assert(
        is_equal_approx(
            CombatConstants.hit_off_balance_outcome_mult("glancing"), CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT
        ),
        failures,
        "glancing_ob: glancing hit should map to the constant (%.2f)" % CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT
    )
    _assert(
        is_equal_approx(CombatConstants.hit_off_balance_outcome_mult("negligible"), 0.0),
        failures,
        "glancing_ob: negligible chip should map to 0.0 (no stagger)"
    )
    # Fail-safe: a missing/unknown outcome must never zero out a legitimate stagger.
    _assert(
        (
            is_equal_approx(CombatConstants.hit_off_balance_outcome_mult(""), 1.0)
            and is_equal_approx(CombatConstants.hit_off_balance_outcome_mult("unknown_outcome"), 1.0)
        ),
        failures,
        "glancing_ob: unknown/empty outcome should default to 1.0 (clean-hit assumption)"
    )
    # Ordering: clean > glancing > negligible, and a glancing hit still leaves some stagger.
    _assert(
        (
            (
                CombatConstants.hit_off_balance_outcome_mult("hit")
                > CombatConstants.hit_off_balance_outcome_mult("glancing")
            )
            and (
                CombatConstants.hit_off_balance_outcome_mult("glancing")
                > CombatConstants.hit_off_balance_outcome_mult("negligible")
            )
        ),
        failures,
        "glancing_ob: expected clean > glancing > negligible ordering"
    )
    # Composition: a glancing head hit (mult x 1.30 part) must stay weaker than a clean chest hit (1.0 x 1.0).
    var glancing_head: float = (
        CombatConstants.hit_off_balance_outcome_mult("glancing") * CombatConstants.hit_part_off_balance_mult("head")
    )
    var clean_chest: float = (
        CombatConstants.hit_off_balance_outcome_mult("hit") * CombatConstants.hit_part_off_balance_mult("chest")
    )
    _assert(
        glancing_head < clean_chest,
        failures,
        (
            "glancing_ob: glancing head hit (%.3f) should stagger less than a clean chest hit (%.3f)"
            % [glancing_head, clean_chest]
        )
    )


## The hit-stagger window composition (base x part x outcome x recovery) as one named helper:
## PassiveParryContext.hit_off_balance_window. Catches wrong-ordering/combination bugs that
## per-factor tests would miss, and pins that a D001-neutral combatant gets ~base x part x outcome.


static func run_off_balance_hit_window_composition(failures: PackedStringArray) -> void:
    var mgr: Node = _make_1v1_sword()
    var c: Dictionary = mgr.combatants[0]
    # D001-neutral defender: no injuries, default stats, no exhaustion -> recovery ~1.0.
    var rec: float = PassiveParryContext.off_balance_recovery_mult(c)
    _assert(rec > 0.9 and rec < 1.1, failures, "ob_compose: neutral recovery should be ~1.0 got %.3f" % rec)
    var intensity: float = 0.5
    var base: float = CombatConstants.hit_defender_off_balance_duration(intensity)
    # Composition equals the product of the four factors (catches a divide-vs-multiply slip).
    for part in ["chest", "head", "left_leg"]:
        for outcome in ["hit", "glancing"]:
            var expected: float = (
                base
                * CombatConstants.hit_part_off_balance_mult(part)
                * CombatConstants.hit_off_balance_outcome_mult(outcome)
                * rec
            )
            var got: float = PassiveParryContext.hit_off_balance_window(intensity, part, outcome, c)
            _assert(
                absf(got - expected) < 0.001,
                failures,
                "ob_compose: %s %s got %.3f want %.3f" % [part, outcome, got, expected]
            )
    # Monotonic ordering at the same intensity: negligible < glancing < clean.
    var clean: float = PassiveParryContext.hit_off_balance_window(intensity, "chest", "hit", c)
    var glancing: float = PassiveParryContext.hit_off_balance_window(intensity, "chest", "glancing", c)
    var neg: float = PassiveParryContext.hit_off_balance_window(intensity, "chest", "negligible", c)
    _assert(
        is_equal_approx(neg, 0.0) and glancing > 0.0 and clean > glancing,
        failures,
        "ob_compose: expected 0 < glancing (%.3f) < clean (%.3f)" % [glancing, clean]
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## Hit-continuation (attacker initiative) scales with how cleanly the hit landed: a clean blow grants
## the full re-commit window, a glancing graze grants a shorter one, a negligible chip grants none.
## Mirrors the defender off-balance separation on the attacker side (nach/Vorschlag follow-up).


static func run_hit_continuation_outcome_scale(failures: PackedStringArray) -> void:
    var mgr: Node = _make_1v1_sword()
    var c: Dictionary = mgr.combatants[0]
    var tid: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var clock: float = CombatantEntityAccess.combat_clock_float(mgr)
    var full_win: float = CombatConstants.HIT_CONTINUATION_WINDOW_S
    var glancing_win: float = full_win * CombatConstants.hit_off_balance_outcome_mult("glancing")
    var neg_win: float = full_win * CombatConstants.hit_off_balance_outcome_mult("negligible")
    # Composition sanity: glancing window is a proper fraction of the full window; negligible is zero.
    _assert(
        glancing_win > 0.0 and glancing_win < full_win and is_equal_approx(neg_win, 0.0),
        failures,
        (
            "cont_outcome: expected 0 < glancing (%.3f) < full (%.3f) and negligible == 0 (got %.3f)"
            % [glancing_win, full_win, neg_win]
        )
    )
    # Clean: full window stamped.
    CounterTempo.grant_hit_continuation(mgr, c, tid, full_win)
    var clean_until: float = c.get(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL, -1.0)
    _assert(
        is_equal_approx(clean_until - clock, full_win),
        failures,
        (
            "cont_outcome: clean hit should grant the full window (until-clock=%.3f want %.3f)"
            % [clean_until - clock, full_win]
        )
    )
    c.erase(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL)
    c.erase(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_TARGET_ID)
    # Glancing: shorter window than clean.
    CounterTempo.grant_hit_continuation(mgr, c, tid, glancing_win)
    var glancing_until: float = c.get(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL, -1.0)
    _assert(
        is_equal_approx(glancing_until - clock, glancing_win),
        failures,
        (
            "cont_outcome: glancing hit should grant the scaled window (until-clock=%.3f want %.3f)"
            % [glancing_until - clock, glancing_win]
        )
    )
    c.erase(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL)
    c.erase(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_TARGET_ID)
    # Negligible: zero window -> nothing granted.
    CounterTempo.grant_hit_continuation(mgr, c, tid, neg_win)
    _assert(
        not c.has(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL),
        failures,
        "cont_outcome: negligible chip should grant no hit-continuation window"
    )
    # Backward-compat: the no-arg call still grants the full default window.
    CounterTempo.grant_hit_continuation(mgr, c, tid)
    var default_until: float = c.get(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL, -1.0)
    _assert(
        is_equal_approx(default_until - clock, full_win),
        failures,
        "cont_outcome: default call should still grant the full window (until-clock=%.3f)" % (default_until - clock)
    )
    HarnessCore._free_manager_restore_global_rng(mgr)

## Parry-deflect off-balance alignment scale: the applier multiplies the *attacker's* post-deflect
## off-balance window by parry_recoil_alignment_mult(alignment), the same factor the blade-recoil
## path uses. A glancing catch (low alignment) must disorient less than a square-on catch at equal
## strike intensity; neutral alignment stays ~1.0.
