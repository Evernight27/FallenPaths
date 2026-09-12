class_name HemaNewMechanicsTests
extends RefCounted
## Post-session HEMA mechanic tests: Nach (riposte line-aim), Gegenschlag (counterblow trade),
## Verwunden (circumscription open-line penalty).

const HarnessCore := preload("res://harness/regression/core/CombatRegressionHarnessCore.gd")
const CombatManager := preload("res://combat/CombatManager.gd")
const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")
const CounterTempo := preload("res://combat/strike/CounterTempo.gd")
const CombatConstants := preload("res://combat/CombatConstants.gd")
const CombatConstantsEncounter := preload("res://combat/constants/CombatConstantsEncounter.gd")
const CombatEventScheduler := preload("res://combat/flow/CombatEventScheduler.gd")
const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")
const DataKeys := preload("res://core/DataKeys.gd")
const WeaponConstants := preload("res://resources/weapons/WeaponConstants.gd")
const CombatGuardLines := preload("res://combat/weapon_form/CombatGuardLines.gd")
const CombatBindPressure := preload("res://combat/strike/CombatBindPressure.gd")


# ---------------------------------------------------------------------------
# Nach: riposte aims at the open line
# ---------------------------------------------------------------------------

## grant_riposte_chain with a target_line stores COMBATANT_KEY_RIPOSTE_TARGET_LINE;
## riposte_target_line returns it; clear_riposte_chain clears it.
static func run_nach_grant_stores_target_line(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = CombatantEntityAccess.id_int(def)
	var atk_id: int = CombatantEntityAccess.id_int(atk)

	# Grant riposte chain with a target line.
	CounterTempo.grant_riposte_chain(mgr, def, atk_id, "low")

	var line: String = CounterTempo.riposte_target_line(mgr, def, atk_id)
	_assert_eq(line, "low", failures, "nach_grant: riposte_target_line should be 'low' got '%s'" % line)

	# After clear, line is empty.
	CounterTempo.clear_riposte_chain(def)
	var line_cleared: String = CounterTempo.riposte_target_line(mgr, def, atk_id)
	_assert_eq(line_cleared, "", failures, "nach_clear: riposte_target_line should be empty after clear got '%s'" % line_cleared)

	# Also verify the key itself is erased from the dict.
	_assert(
		not def.has(CombatConstants.COMBATANT_KEY_RIPOSTE_TARGET_LINE),
		failures,
		"nach_clear: COMBATANT_KEY_RIPOSTE_TARGET_LINE should be erased from dict"
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## riposte_target_line returns "" when no chain is active against the target.
static func run_nach_no_chain_returns_empty(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = CombatantEntityAccess.id_int(def)
	var atk_id: int = CombatantEntityAccess.id_int(atk)

	# No riposte chain granted — should return empty.
	var line: String = CounterTempo.riposte_target_line(mgr, def, atk_id)
	_assert_eq(
		line,
		"",
		failures,
		"nach_no_chain: riposte_target_line should be empty when no chain active got '%s'" % line
	)

	# Grant against a different target — should not return line for the wrong target.
	CounterTempo.grant_riposte_chain(mgr, def, atk_id, "high")
	var wrong_line: String = CounterTempo.riposte_target_line(mgr, def, -1)
	_assert_eq(
		wrong_line,
		"",
		failures,
		"nach_wrong_target: riposte_target_line for wrong target should be empty got '%s'" % wrong_line
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


# ---------------------------------------------------------------------------
# Gegenschlag: counterblow trade probability
# ---------------------------------------------------------------------------

## Invalid args return 0.0.
static func run_gegenschlag_invalid_args_return_zero(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	_assert(
		CounterTempo.gegenschlag_trade_probability(mgr, -1, 0) == 0.0,
		failures,
		"gegenschlag_invalid: counter_id < 0 should return 0.0"
	)
	_assert(
		CounterTempo.gegenschlag_trade_probability(mgr, 0, -1) == 0.0,
		failures,
		"gegenschlag_invalid: incoming_attacker_id < 0 should return 0.0"
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## No pending melee attack → 0.0.
static func run_gegenschlag_no_pending_attack_returns_zero(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = CombatantEntityAccess.id_int(def)
	var atk_id: int = CombatantEntityAccess.id_int(atk)
	# No attack scheduled — their_at < 0.0 → prob = 0.0.
	var prob: float = CounterTempo.gegenschlag_trade_probability(mgr, def_id, atk_id)
	_assert(
		prob == 0.0,
		failures,
		"gegenschlag_no_pending: should return 0.0 when no pending melee attack got %.4f" % prob
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## Favorable timing (our counter ends well before their attack resolves) → high probability.
## Unfavorable timing (our counter ends well after their attack) → low probability.
## Both bounded in [0.05, 0.95].
static func run_gegenschlag_timing_scales_probability(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = CombatantEntityAccess.id_int(def)
	var atk_id: int = CombatantEntityAccess.id_int(atk)
	var clock: float = CombatantEntityAccess.combat_clock_float(mgr)

	# Put the counter (def) into wind-up with a short state duration (ends soon).
	def[DataKeys.PA_STATE_DURATION] = 0.3

	# Scenario A: their attack resolves 2.0s in the future → favorable for us.
	CombatEventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": clock + 2.0,
		"data": {},
	})
	var prob_fav: float = CounterTempo.gegenschlag_trade_probability(mgr, def_id, atk_id)
	_assert(
		prob_fav > 0.5,
		failures,
		"gegenschlag_fav: favorable timing should give prob > 0.5 got %.4f" % prob_fav
	)
	_assert(
		prob_fav <= 0.95,
		failures,
		"gegenschlag_fav_clamp: prob should be <= 0.95 got %.4f" % prob_fav
	)

	# Scenario B: their attack resolves in 0.1s (very soon) → unfavorable for us.
	CombatEventScheduler.set_pending_melee_attack_resolve_at(mgr, atk_id, clock + 0.1)
	var prob_unfav: float = CounterTempo.gegenschlag_trade_probability(mgr, def_id, atk_id)
	_assert(
		prob_unfav < prob_fav,
		failures,
		"gegenschlag_unfav: unfavorable timing should give lower prob than favorable (unfav=%.4f fav=%.4f)"
		% [prob_unfav, prob_fav]
	)
	_assert(
		prob_unfav >= 0.05,
		failures,
		"gegenschlag_unfav_clamp: prob should be >= 0.05 got %.4f" % prob_unfav
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## should_gegenschlag_trade returns false for invalid args.
static func run_gegenschlag_should_trade_false_for_invalid(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	_assert(
		not CounterTempo.should_gegenschlag_trade(mgr, -1, 0),
		failures,
		"gegenschlag_roll_invalid: should_gegenschlag_trade(-1, 0) should be false"
	)
	_assert(
		not CounterTempo.should_gegenschlag_trade(mgr, 0, -1),
		failures,
		"gegenschlag_roll_invalid: should_gegenschlag_trade(0, -1) should be false"
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


# ---------------------------------------------------------------------------
# Verwunden: circumscription
# ---------------------------------------------------------------------------

## Move definition exists and has correct flags.
static func run_verwunden_move_definition_exists(failures: PackedStringArray) -> void:
	var md: Dictionary = WeaponConstants.get_move("verwunden")
	_assert(
		not md.is_empty(),
		failures,
		"verwunden_def: move definition should exist"
	)
	_assert(
		md.get("is_feint", false),
		failures,
		"verwunden_def: should have is_feint=true"
	)
	_assert(
		md.get("circumscription", false),
		failures,
		"verwunden_def: should have circumscription=true"
	)
	_assert(
		WeaponConstants.is_circumscription_move("verwunden"),
		failures,
		"verwunden_def: is_circumscription_move('verwunden') should be true"
	)
	_assert(
		not WeaponConstants.is_circumscription_move("oberhau_feint"),
		failures,
		"verwunden_def: is_circumscription_move('oberhau_feint') should be false (plain feint)"
	)


## CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT is stronger (lower) than plain feint penalty.
static func run_verwunden_constant_stronger_than_feint(failures: PackedStringArray) -> void:
	_assert(
		CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT < CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
		failures,
		"verwunden_mult: CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT (%.2f) should be < FEINT_OPEN_LINE_PARRY_MULT (%.2f)"
		% [
			CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT,
			CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
		]
	)
	_assert(
		CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT > 0.0,
		failures,
		"verwunden_mult: CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT should be > 0.0"
	)


## opposite_line is used to compute the open line for circumscription.
static func run_verwunden_opposite_line_logic(failures: PackedStringArray) -> void:
	# high → low
	var opp_high: String = CombatGuardLines.opposite_line("high")
	_assert_eq(
		opp_high,
		"low",
		failures,
		"verwunden_opp: opposite_line('high') should be 'low' got '%s'" % opp_high
	)
	# low → high
	var opp_low: String = CombatGuardLines.opposite_line("low")
	_assert_eq(
		opp_low,
		"high",
		failures,
		"verwunden_opp: opposite_line('low') should be 'high' got '%s'" % opp_low
	)
	# right → left
	var opp_right: String = CombatGuardLines.opposite_line("right")
	_assert_eq(
		opp_right,
		"left",
		failures,
		"verwunden_opp: opposite_line('right') should be 'left' got '%s'" % opp_right
	)
	# left → right
	var opp_left: String = CombatGuardLines.opposite_line("left")
	_assert_eq(
		opp_left,
		"right",
		failures,
		"verwunden_opp: opposite_line('left') should be 'right' got '%s'" % opp_left
	)


## Deflect open-line: a parried attacker is stamped open on their committed line with the
## deflect-specific parry mult (distinct from feint open-line, stronger than plain feint).
static func run_deflect_open_line_constant_and_keys(failures: PackedStringArray) -> void:
	# The deflect open-line penalty is stronger than a plain feint (committed parry opens more than a reaction).
	_assert(
		CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT < CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
		failures,
		"deflect_open: DEFLECT_OPEN_LINE_PARRY_MULT (%.2f) should be < FEINT_OPEN_LINE_PARRY_MULT (%.2f)"
		% [
			CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT,
			CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
		]
	)
	# And milder than a deliberate circumscription (going around the blade is more exposing than being parried).
	_assert(
		CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT > CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT,
		failures,
		"deflect_open: DEFLECT_OPEN_LINE_PARRY_MULT (%.2f) should be > CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT (%.2f)"
		% [
			CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT,
			CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT,
		]
	)
	# The open-line payoff keys are shared with the feint mechanic (same "you are open on this line" semantic).
	_assert(
		DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT == "feint_open_line_parry_mult",
		failures,
		"deflect_open: PA_FEINT_OPEN_LINE_PARRY_MULT key should be stable got '%s'" % DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT
	)


## Off-balance attack damage: a fighter who is off-balance at the moment of impact deals reduced
## damage — compromised center of gravity weakens weight transfer. The multiplier is < 1.0 and
## symmetric with the defensive parry-capacity penalty (same value, same mechanic).
static func run_off_balance_attack_dmg_constant(failures: PackedStringArray) -> void:
	# Must be a reduction (less than 1.0).
	_assert(
		CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT < 1.0,
		failures,
		"ob_atk: OFF_BALANCE_ATTACK_DMG_MULT (%.2f) should be < 1.0"
		% CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT
	)
	# Must be > 0 (an off-balance strike still lands, just weaker).
	_assert(
		CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT > 0.0,
		failures,
		"ob_atk: OFF_BALANCE_ATTACK_DMG_MULT (%.2f) should be > 0.0"
		% CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT
	)
	# Symmetric with the defensive penalty — same magnitude in both directions.
	_assert_eq(
		str(CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT),
		str(CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT),
		failures,
		"ob_atk: OFF_BALANCE_ATTACK_DMG_MULT should equal OFF_BALANCE_PARRY_CAPACITY_MULT (%.2f vs %.2f)"
		% [
			CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT,
			CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT,
		]
	)


## Feint commit off-balance: a failed feint leaves the attacker more committed than a failed
## direct strike. The extra off-balance window is a positive, bounded constant exposed through
## the CombatConstants facade.
static func run_feint_commit_off_balance_constant(failures: PackedStringArray) -> void:
	# The extra window must be positive (a feint commit is always more exposing than a miss).
	_assert(
		CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S > 0.0,
		failures,
		"feint_commit: FEINT_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be > 0"
		% CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S
	)
	# Bounded so it cannot exceed the base miss off-balance floor (a commit penalty, not a stun).
	_assert(
		CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S < CombatConstants.OFF_BALANCE_DURATION_S,
		failures,
		"feint_commit: FEINT_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be < OFF_BALANCE_DURATION_S (%.2f)"
		% [
			CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S,
			CombatConstants.OFF_BALANCE_DURATION_S,
		]
	)
	# Facade method returns the same value.
	_assert_eq(
		str(CombatConstants.feint_commit_off_balance_extra_s()),
		str(CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S),
		failures,
		"feint_commit: feint_commit_off_balance_extra_s() should return the constant got '%s'"
		% str(CombatConstants.feint_commit_off_balance_extra_s())
	)


## Angular advantage: voiding outside an opponent's strong side grants a bounded positional damage
## bonus against that specific target only. The constant is > 1.0 and the reader gates on both
## the clock window and the target id.
static func run_angular_advantage_constant_and_reader(failures: PackedStringArray) -> void:
	# The bonus must be > 1.0 (a positional advantage, not a penalty).
	_assert(
		CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT > 1.0,
		failures,
		"ang_adv: ANGULAR_ADVANTAGE_DMG_MULT (%.2f) should be > 1.0"
		% CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT
	)
	# Bounded so it cannot exceed a doubling of damage.
	_assert(
		CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT <= 1.5,
		failures,
		"ang_adv: ANGULAR_ADVANTAGE_DMG_MULT (%.2f) should be <= 1.5"
		% CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT
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
		"bind_wrestle: BIND_WRESTLE_TARGET_OFF_BALANCE_S (%.2f) should be > 0"
		% CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S
	)
	# Bounded so it cannot exceed 3s (a single wrestle shouldn't stun).
	_assert(
		CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S <= 3.0,
		failures,
		"bind_wrestle: BIND_WRESTLE_TARGET_OFF_BALANCE_S (%.2f) should be <= 3.0"
		% CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S
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
		"ob_dodge: OFF_BALANCE_DODGE_CHANCE_MULT (%.2f) should be < 1.0"
		% CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT
	)
	# Must be > 0 (an off-balance defender can still attempt to dodge, just less effectively).
	_assert(
		CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT > 0.0,
		failures,
		"ob_dodge: OFF_BALANCE_DODGE_CHANCE_MULT (%.2f) should be > 0.0"
		% CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT
	)
	# Mild: off-balance reduces stepping but doesn't make evasion impossible (more lenient than parry,
	# which is more dependent on center-of-gravity stability).
	_assert(
		CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT > CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT,
		failures,
		"ob_dodge: OFF_BALANCE_DODGE_CHANCE_MULT (%.2f) should be > OFF_BALANCE_PARRY_CAPACITY_MULT (%.2f)"
		% [
			CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT,
			CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT,
		]
	)


## Bind follow-through: while actively holding a bind on the target, the striker gets a modest
## damage bonus. The constant is a bounded >1.0 value, and the gate only fires when the bind
## partner is the strike target (a third combatant is not affected).
static func run_bind_follow_through_constant_and_gate(failures: PackedStringArray) -> void:
	# Bounded bonus: > 1.0 (it's a bonus) but capped so it cannot exceed +50%.
	_assert(
		CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT > 1.0,
		failures,
		"bind_ft: BIND_FOLLOW_THROUGH_DMG_MULT (%.2f) should be > 1.0"
		% CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT
	)
	_assert(
		CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT <= 1.5,
		failures,
		"bind_ft: BIND_FOLLOW_THROUGH_DMG_MULT (%.2f) should be <= 1.5"
		% CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT
	)

	var mgr: Node = _make_1v1_sword()
	var c0: Dictionary = mgr.combatants[0]
	var c1: Dictionary = mgr.combatants[1]
	var id0: int = CombatantEntityAccess.id_int(c0)
	var id1: int = CombatantEntityAccess.id_int(c1)
	var clock: float = CombatantEntityAccess.combat_clock_float(mgr)

	# No bind: is_in_bind is false.
	_assert(
		not CombatBindPressure.is_in_bind(c0, clock),
		failures,
		"bind_ft: is_in_bind should be false with no bind set"
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
		"bind_ft: hard follow-through (%.3f) should equal BIND_FOLLOW_THROUGH_DMG_MULT (%.3f)"
		% [ft_hard, CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT]
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
		"fsw_vuln: FORM_SWITCH_VULNERABILITY_DMG_MULT (%.2f) should be > 1.0"
		% CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT
	)
	_assert(
		CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT <= 1.5,
		failures,
		"fsw_vuln: FORM_SWITCH_VULNERABILITY_DMG_MULT (%.2f) should be <= 1.5"
		% CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT
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
		"hit_cont: HIT_CONTINUATION_WINDUP_MULT (%.2f) should be < 1.0"
		% CombatConstants.HIT_CONTINUATION_WINDUP_MULT
	)
	_assert(
		CombatConstants.HIT_CONTINUATION_WINDUP_MULT > 0.0,
		failures,
		"hit_cont: HIT_CONTINUATION_WINDUP_MULT (%.2f) should be > 0.0"
		% CombatConstants.HIT_CONTINUATION_WINDUP_MULT
	)
	# HEMA ordering: a blade-catch riposte is the fastest counter; a landed-strike follow-up is slower.
	_assert(
		CombatConstants.HIT_CONTINUATION_WINDUP_MULT > CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT,
		failures,
		"hit_cont: HIT_CONTINUATION_WINDUP_MULT (%.2f) should be slower (>) than RIPOSTE_CHAIN_WINDUP_MULT (%.2f)"
		% [CombatConstants.HIT_CONTINUATION_WINDUP_MULT, CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT]
	)
	_assert(
		CombatConstants.HIT_CONTINUATION_WINDOW_S > 0.0,
		failures,
		"hit_cont: HIT_CONTINUATION_WINDOW_S (%.2f) should be > 0"
		% CombatConstants.HIT_CONTINUATION_WINDOW_S
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
		"hit_cont: wind-up mult (%.2f) should equal the constant after grant"
		% CounterTempo.hit_continuation_windup_mult(mgr, atk, tgt_id)
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
		"thrust_commit: THRUST_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be > 0"
		% CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S
	)
	_assert(
		CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S < CombatConstants.OFF_BALANCE_DURATION_S,
		failures,
		"thrust_commit: THRUST_COMMIT_OFF_BALANCE_EXTRA_S (%.2f) should be < OFF_BALANCE_DURATION_S (%.2f)"
		% [
			CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S,
			CombatConstants.OFF_BALANCE_DURATION_S,
		]
	)
	# Facade method returns the same value.
	_assert_eq(
		str(CombatConstants.thrust_commit_off_balance_extra_s()),
		str(CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S),
		failures,
		"thrust_commit: thrust_commit_off_balance_extra_s() should return the constant got '%s'"
		% str(CombatConstants.thrust_commit_off_balance_extra_s())
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
		"measure_dmg: MEASURE_DMG_OVER_REACH_FLOOR (%.2f) should be in (0, 1)"
		% CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR
	)
	_assert(
		CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR > 0.0 and CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR < 1.0,
		failures,
		"measure_dmg: MEASURE_DMG_UNDER_REACH_FLOOR (%.2f) should be in (0, 1)"
		% CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR
	)
	# Damage floor should not be stricter (lower) than the corresponding hit-chance floor:
	# even a badly out-of-measure strike still lands with meaningful force.
	_assert(
		CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR >= CombatConstants.MEASURE_HIT_CHANCE_FLOOR,
		failures,
		"measure_dmg: over-reach dmg floor (%.2f) should be >= hit-chance floor (%.2f)"
		% [CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR, CombatConstants.MEASURE_HIT_CHANCE_FLOOR]
	)
	_assert(
		CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR >= CombatConstants.MEASURE_UNDER_REACH_HIT_CHANCE_FLOOR,
		failures,
		"measure_dmg: under-reach dmg floor (%.2f) should be >= hit-chance floor (%.2f)"
		% [CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR, CombatConstants.MEASURE_UNDER_REACH_HIT_CHANCE_FLOOR]
	)


## HEMA reach priority: a defender with the longer weapon reaches past the attacker, who is inside the
## defender's natural measure. The damage floor should be milder (higher) than the self-measure floors
## because it is a relational positional penalty, not the attacker's own flawed commit.
static func run_measure_defender_reach_constant(failures: PackedStringArray) -> void:
	_assert(
		CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR > 0.0 and CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR < 1.0,
		failures,
		"measure_def_reach: MEASURE_DMG_DEFENDER_REACH_FLOOR (%.2f) should be in (0, 1)"
		% CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR
	)
	# Milder (higher) than the self-measure over-reach floor: positional threat < personal commit error.
	_assert(
		CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR > CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR,
		failures,
		"measure_def_reach: defender-reach floor (%.2f) should be > over-reach floor (%.2f)"
		% [
			CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR,
			CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR,
		]
	)


## HEMA: the damage-side commitment-quality floor stops a fully-compromised strike (off-balance +
## out of measure + over-extended cut + inside a longer-armed defender) from collapsing to a
## trivial chip. It mirrors HIT_CHANCE_MIN_CAP, which already floors compounded accuracy penalties.
static func run_attack_commit_quality_floor(failures: PackedStringArray) -> void:
	var floor: float = CombatConstants.ATTACK_COMMIT_QUALITY_FLOOR
	# Floor is a valid multiplicative bound in (0, 1).
	_assert(
		floor > 0.0 and floor < 1.0,
		failures,
		"commit_quality: ATTACK_COMMIT_QUALITY_FLOOR (%.2f) should be in (0, 1)" % floor
	)
	# Consistent with the accuracy-side cap: both floor compounded penalties at the same level.
	_assert(
		absf(floor - CombatConstants.HIT_CHANCE_MIN_CAP) < 0.001,
		failures,
		"commit_quality: floor (%.2f) should match HIT_CHANCE_MIN_CAP (%.2f)"
		% [floor, CombatConstants.HIT_CHANCE_MIN_CAP]
	)
	# The stack of sub-1.0 commitment penalties (off-balance x over-extended cut) can dip below
	# the floor, so the floor is load-bearing — without it the strike would collapse below the cap.
	var worst: float = (
		CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT
		* CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR
		* CombatConstants.MEASURE_DMG_CUT_OVER_REACH_FLOOR
	)
	_assert(
		worst < floor,
		failures,
		"commit_quality: worst-case stack (%.3f) should be < floor (%.2f) so the floor engages"
		% [worst, floor]
	)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static var _mgr_ref: Node = null


static func _make_1v1_sword() -> Node:
	var mgr: Node = CombatManager.new()
	var e1: Node = HarnessFixtures._new_entity("SWORD")
	var e2: Node = HarnessFixtures._new_entity("SWORD")
	mgr.register(e1, "player")
	mgr.register(e2, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	HarnessFixtures._harness_reset_combatants_form_balanced(mgr)
	_mgr_ref = mgr
	return mgr


## Set a live bind at the given pressure value on `c` (until = clock+4) and return the follow-through mult.
## A value < 0.25 yields pressure level "none" -> no bonus (used to simulate no active pressure).
static func _follow_through_at(c: Dictionary, value: float, clock: float) -> float:
	c[DataKeys.BIND_PRESSURE_VALUE] = value
	c[DataKeys.BIND_PRESSURE_UNTIL] = clock + 4.0
	return CombatBindPressure.follow_through_dmg_mult(c, clock)


static func _assert(cond: bool, failures: PackedStringArray, msg: String) -> void:
	if not cond:
		failures.append(msg)


static func _assert_eq(got: String, want: String, failures: PackedStringArray, msg: String) -> void:
	if got != want:
		failures.append(msg)
