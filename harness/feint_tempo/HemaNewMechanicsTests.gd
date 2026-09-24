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
const CombatTiming := preload("res://combat/flow/CombatTiming.gd")


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


## Open-line window length scales with the commitment of the opening event: heavier strikes (higher
## intensity) hold the defender off-line longer, and a circumscription (verwunden) that goes AROUND
## the committed blade adds a further extension, capped at OPEN_LINE_DURATION_MAX_S. Pins the new
## commitment-scaling behaviour (XCamp-4) so a future flat-TTL regression is caught.
static func run_open_line_duration_scales_with_commitment(failures: PackedStringArray) -> void:
	var base: float = CombatConstants.FEINT_OPEN_LINE_DURATION_S
	# Zero intensity, no circumscription = the flat base window.
	_assert(
		is_equal_approx(CombatGuardLines.open_line_duration_s(0.0, false), base),
		failures,
		"open_line_dur: intensity 0.0 / no-circ should equal base (%.2f) got %.2f"
		% [base, CombatGuardLines.open_line_duration_s(0.0, false)]
	)
	# Full intensity adds the intensity scale.
	var full: float = CombatGuardLines.open_line_duration_s(1.0, false)
	_assert(
		is_equal_approx(full, base + CombatGuardLines.OPEN_LINE_DURATION_INTENSITY_SCALE_S),
		failures,
		"open_line_dur: intensity 1.0 / no-circ should be base+scale (%.2f) got %.2f"
		% [base + CombatGuardLines.OPEN_LINE_DURATION_INTENSITY_SCALE_S, full]
	)
	# Monotonic: a heavier strike holds the line open at least as long as a lighter one.
	_assert(
		CombatGuardLines.open_line_duration_s(0.0, false) < CombatGuardLines.open_line_duration_s(0.5, false)
		and CombatGuardLines.open_line_duration_s(0.5, false) < CombatGuardLines.open_line_duration_s(1.0, false),
		failures,
		"open_line_dur: duration should increase monotonically with intensity"
	)
	# A circumscription extends the window beyond the same-commitment non-circumscripting opener.
	_assert(
		CombatGuardLines.open_line_duration_s(0.5, true) > CombatGuardLines.open_line_duration_s(0.5, false),
		failures,
		"open_line_dur: circumscription should extend the window beyond the same-intensity non-circ case"
	)
	# The cap is respected even at the most committed circumscription.
	_assert(
		CombatGuardLines.open_line_duration_s(1.0, true) <= CombatGuardLines.OPEN_LINE_DURATION_MAX_S,
		failures,
		"open_line_dur: intensity 1.0 / circ should not exceed the cap (%.2f) got %.2f"
		% [CombatGuardLines.OPEN_LINE_DURATION_MAX_S, CombatGuardLines.open_line_duration_s(1.0, true)]
	)


## open_line_openness decays over the stamped window with an ease-out recovery curve
## (openness = (1 - t)^EASE): no live window -> 0.0, an expired window -> 0.0, a freshly opened
## window -> near 1.0, and the decay is faster early than late (the defender re-covers the acute
## off-line quickly, leaving only the fine blade re-coverage to linger). Pins the time-decay model
## (monotonic, no guard-position dependence) and the eased shape specifically.
static func run_open_line_openness_time_decay(failures: PackedStringArray) -> void:
	var now: float = CombatTiming.now_seconds()
	var dur: float = CombatConstants.FEINT_OPEN_LINE_DURATION_S

	# No open-line state at all -> not open.
	_assert_eq(
		str(CombatGuardLines.open_line_openness({})),
		"0.0",
		failures,
		"open_line_decay: no state should read 0.0 got %s" % str(CombatGuardLines.open_line_openness({}))
	)

	# An expired window (until in the past) -> not open.
	var expired: Dictionary = {
		DataKeys.PA_FEINT_OPEN_LINE: "high",
		DataKeys.PA_FEINT_OPEN_LINE_UNTIL: now - 1.0,
		DataKeys.PA_FEINT_OPEN_LINE_DURATION_S: dur,
	}
	_assert(
		CombatGuardLines.open_line_openness(expired) <= 0.0,
		failures,
		"open_line_decay: expired window should read 0.0 got %s" % str(CombatGuardLines.open_line_openness(expired))
	)

	# A freshly opened window (until = now + dur) -> near fully open (tiny wall-clock drift allowed).
	var fresh: Dictionary = {
		DataKeys.PA_FEINT_OPEN_LINE: "high",
		DataKeys.PA_FEINT_OPEN_LINE_UNTIL: now + dur,
		DataKeys.PA_FEINT_OPEN_LINE_DURATION_S: dur,
	}
	var fresh_openness: float = CombatGuardLines.open_line_openness(fresh)
	_assert(
		fresh_openness > 0.95,
		failures,
		"open_line_decay: freshly opened window should read near 1.0 got %s" % str(fresh_openness)
	)

	# A mid-window state (until = now + dur/2) -> under an ease-out the defender is already mostly
	# re-covered: (1 - 0.5)^2 = 0.25, well below the 0.5 a linear decay would give.
	var mid: Dictionary = {
		DataKeys.PA_FEINT_OPEN_LINE: "high",
		DataKeys.PA_FEINT_OPEN_LINE_UNTIL: now + dur * 0.5,
		DataKeys.PA_FEINT_OPEN_LINE_DURATION_S: dur,
	}
	var mid_openness: float = CombatGuardLines.open_line_openness(mid)
	_assert(
		mid_openness > 0.15 and mid_openness < 0.40,
		failures,
		"open_line_decay: ease-out mid-window should read ~0.25 got %s" % str(mid_openness)
	)

	# The eased curve is steeper early than late: an early-quarter sample (0.5625) is far above a
	# late-quarter sample (0.0625). This pinpoints the non-linear ease-out shape (vs a flat/linear
	# decay, which would read ~0.75 and ~0.25 symmetric about 0.5).
	var early: Dictionary = {
		DataKeys.PA_FEINT_OPEN_LINE: "high",
		DataKeys.PA_FEINT_OPEN_LINE_UNTIL: now + dur * 0.75,
		DataKeys.PA_FEINT_OPEN_LINE_DURATION_S: dur,
	}
	var early_openness: float = CombatGuardLines.open_line_openness(early)
	var late: Dictionary = {
		DataKeys.PA_FEINT_OPEN_LINE: "high",
		DataKeys.PA_FEINT_OPEN_LINE_UNTIL: now + dur * 0.25,
		DataKeys.PA_FEINT_OPEN_LINE_DURATION_S: dur,
	}
	var late_openness: float = CombatGuardLines.open_line_openness(late)
	_assert(
		early_openness > late_openness * 2.0,
		failures,
		"open_line_decay: early-quarter (%.3f) should exceed twice the late-quarter (%.3f) under ease-out"
		% [early_openness, late_openness]
	)


## stamp_open_line centralizes the four-key open-line write and encodes the re-open rule: a lighter
## follow-up on a line that is already open must NOT shorten the live window (only a different line
## or a strictly longer window re-stamps). Pins the helper so the three stamp sites stay consistent.
static func run_stamp_open_line_reopen_rules(failures: PackedStringArray) -> void:
	var c: Dictionary = {"id": 0}

	# Empty combatant is a no-op.
	var empty_c: Dictionary = {}
	CombatGuardLines.stamp_open_line(empty_c, "high", 3.0, 0.8)
	_assert(
		not empty_c.has(DataKeys.PA_FEINT_OPEN_LINE),
		failures,
		"stamp_open_line: empty combatant should be a no-op"
	)

	# Empty line is a no-op.
	CombatGuardLines.stamp_open_line(c, "", 3.0, 0.8)
	_assert(
		not c.has(DataKeys.PA_FEINT_OPEN_LINE),
		failures,
		"stamp_open_line: empty line should be a no-op"
	)

	# Fresh stamp writes all four keys with the given duration/mult.
	CombatGuardLines.stamp_open_line(c, "high", 4.0, 0.8)
	_assert_eq(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")),
		"high",
		failures,
		"stamp_open_line: fresh stamp should store line 'high'"
	)
	_assert(
		c.has(DataKeys.PA_FEINT_OPEN_LINE_UNTIL)
		and c.has(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
		and c.has(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT),
		failures,
		"stamp_open_line: fresh stamp should write until/duration/parry_mult"
	)
	_assert(
		is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 4.0),
		failures,
		"stamp_open_line: stored duration should be 4.0 got %.2f" % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
	)
	_assert(
		is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0)), 0.8),
		failures,
		"stamp_open_line: stored parry mult should be 0.8 got %.2f" % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0))
	)
	var until_first: float = float(c.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, 0.0))
	# until should be roughly now+4.0 (wall-clock drift over a few ms is negligible).
	_assert(
		until_first >= CombatTiming.now_seconds() + 3.9 and until_first <= CombatTiming.now_seconds() + 4.1,
		failures,
		"stamp_open_line: until should be now+4s, got %.3f" % (until_first - CombatTiming.now_seconds())
	)

	# Re-opening the SAME line with a SHORTER window must preserve the longer live window.
	CombatGuardLines.stamp_open_line(c, "high", 2.0, 0.8)
	var until_after_short: float = float(c.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, 0.0))
	_assert(
		until_after_short >= until_first - 0.05,
		failures,
		"stamp_open_line: shorter re-open on same line must not shorten the window (%.3f vs %.3f)"
		% [until_after_short, until_first]
	)
	_assert(
		is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 4.0),
		failures,
		"stamp_open_line: stored duration must stay 4.0 after shorter re-open got %.2f"
		% float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
	)

	# Opening a DIFFERENT line replaces the open line and stamps a fresh window.
	CombatGuardLines.stamp_open_line(c, "low", 3.0, 0.7)
	_assert_eq(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")),
		"low",
		failures,
		"stamp_open_line: different line should replace the open line"
	)
	_assert(
		is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 3.0),
		failures,
		"stamp_open_line: replaced window should have duration 3.0 got %.2f"
		% float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
	)
	_assert(
		is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0)), 0.7),
		failures,
		"stamp_open_line: replaced window should carry the new parry mult got %.2f"
		% float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0))
	)

	# A LONGER re-open on the same line re-stamps fresh with the longer window.
	CombatGuardLines.stamp_open_line(c, "low", 5.0, 0.6)
	_assert(
		is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 5.0),
		failures,
		"stamp_open_line: longer re-open on same line should extend the window to 5.0 got %.2f"
		% float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
	)


## close_open_line_on_recover encodes the demonstrated re-coverage rule: a successful parry onto
## the defender's own open line clears the open-line window immediately (the "you're open here"
## state no longer holds). Pins the no-op cases (no live line, wrong line, expired) and the
## positive clear case so the parry/parry-partial call sites stay consistent.
static func run_close_open_line_on_recover_rules(failures: PackedStringArray) -> void:
	var c: Dictionary = {"id": 0}

	# No live open line -> no-op (nothing to clear).
	CombatGuardLines.close_open_line_on_recover(c, "high")
	_assert(
		not c.has(DataKeys.PA_FEINT_OPEN_LINE),
		failures,
		"close_open_line: should be a no-op when no line is open"
	)

	# Empty defended line -> no-op.
	CombatGuardLines.stamp_open_line(c, "high", 3.0, 0.8)
	CombatGuardLines.close_open_line_on_recover(c, "")
	_assert(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high",
		failures,
		"close_open_line: empty defended line should be a no-op"
	)

	# Different defended line -> no-op (defending elsewhere says nothing about this line).
	CombatGuardLines.close_open_line_on_recover(c, "low")
	_assert(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high",
		failures,
		"close_open_line: defending a different line should not clear the open line"
	)

	# Same live line -> clears all four keys.
	CombatGuardLines.close_open_line_on_recover(c, "high")
	_assert(
		not c.has(DataKeys.PA_FEINT_OPEN_LINE)
		and not c.has(DataKeys.PA_FEINT_OPEN_LINE_UNTIL)
		and not c.has(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
		and not c.has(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT),
		failures,
		"close_open_line: re-covering the open line should clear all four keys"
	)
	_assert(
		is_equal_approx(CombatGuardLines.open_line_openness(c), 0.0),
		failures,
		"close_open_line: openness should be 0.0 after re-covering the line"
	)
	# Expired window -> no-op (the line is already closed; stale keys have no effect).
	CombatGuardLines.stamp_open_line(c, "high", 3.0, 0.8)
	c[DataKeys.PA_FEINT_OPEN_LINE_UNTIL] = CombatTiming.now_seconds() - 1.0
	CombatGuardLines.close_open_line_on_recover(c, "high")
	_assert(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high",
		failures,
		"close_open_line: an expired window should be a no-op"
	)


## has_live_open_line reports whether a live open-line window exists on a given line. It is the gate
## for the dodge "deepen" path: only a dodge that actually lands on the defender's open line should
## re-stamp (extend) it.
static func run_has_live_open_line_rules(failures: PackedStringArray) -> void:
	var empty_c: Dictionary = {}
	_assert(
		CombatGuardLines.has_live_open_line(empty_c, "high") == false,
		failures,
		"has_live_open_line: empty combatant should be false"
	)

	var c: Dictionary = {"id": 0}
	_assert(
		CombatGuardLines.has_live_open_line(c, "high") == false,
		failures,
		"has_live_open_line: no live window should be false"
	)

	CombatGuardLines.stamp_open_line(c, "high", 3.0, 0.8)
	_assert(
		CombatGuardLines.has_live_open_line(c, "high") == true,
		failures,
		"has_live_open_line: live window on the stamped line should be true"
	)
	_assert(
		CombatGuardLines.has_live_open_line(c, "low") == false,
		failures,
		"has_live_open_line: a different line should be false"
	)
	_assert(
		CombatGuardLines.has_live_open_line(c, "") == false,
		failures,
		"has_live_open_line: empty query line should be false"
	)

	c[DataKeys.PA_FEINT_OPEN_LINE_UNTIL] = CombatTiming.now_seconds() - 1.0
	_assert(
		CombatGuardLines.has_live_open_line(c, "high") == false,
		failures,
		"has_live_open_line: an expired window should be false"
	)


## shrink_open_line_on_partial_recover encodes the partial re-coverage rule: a partial parry onto the
## defender's own open line shrinks the live window to a fraction of its remaining time (instead of
## clearing it as a full parry does). Pins the no-op cases and the shrink (until moves earlier,
## openness drops but stays positive, all keys preserved).
static func run_shrink_open_line_partial_recover_rules(failures: PackedStringArray) -> void:
	var c: Dictionary = {"id": 0}

	# No live open line -> no-op.
	CombatGuardLines.shrink_open_line_on_partial_recover(c, "high")
	_assert(
		not c.has(DataKeys.PA_FEINT_OPEN_LINE),
		failures,
		"shrink_open_line: should be a no-op when no line is open"
	)

	# Empty defended line -> no-op.
	CombatGuardLines.stamp_open_line(c, "high", 3.0, 0.8)
	CombatGuardLines.shrink_open_line_on_partial_recover(c, "")
	_assert(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high",
		failures,
		"shrink_open_line: empty defended line should be a no-op"
	)

	# Different defended line -> no-op (until unchanged).
	CombatGuardLines.shrink_open_line_on_partial_recover(c, "low")
	_assert(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high",
		failures,
		"shrink_open_line: defending a different line should not shrink the open line"
	)

	# Same live line -> until shrinks, all four keys preserved, openness drops but stays in (0,1).
	CombatGuardLines.stamp_open_line(c, "high", 4.0, 0.8)
	var until_before: float = float(c.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, 0.0))
	var open_before: float = CombatGuardLines.open_line_openness(c)
	CombatGuardLines.shrink_open_line_on_partial_recover(c, "high")
	var until_after: float = float(c.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, 0.0))
	var open_after: float = CombatGuardLines.open_line_openness(c)
	var now: float = CombatTiming.now_seconds()
	_assert(
		str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high"
		and c.has(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
		and c.has(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT),
		failures,
		"shrink_open_line: all four keys should be preserved after a partial re-coverage"
	)
	_assert(
		until_after < until_before and until_after > now,
		failures,
		"shrink_open_line: until should move earlier but stay live (%.3f -> %.3f, now=%.3f)"
		% [until_before, until_after, now]
	)
	_assert(
		open_after < open_before and open_after > 0.0,
		failures,
		"shrink_open_line: openness should drop but stay positive (%.3f -> %.3f)"
		% [open_before, open_after]
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
	# Orientation axis: a rear-arc grapple unroots the target more than face-on — the target resists
	# a forward pull against their own base of support. Same shared map; face-on is D001-neutral.
	var front_mult: float = CombatConstants.hit_orientation_stagger_mult("front")
	var rear_mult: float = CombatConstants.hit_orientation_stagger_mult("rear")
	var flank_mult: float = CombatConstants.hit_orientation_stagger_mult("flank")
	_assert(
		is_equal_approx(front_mult, 1.0)
		and rear_mult > flank_mult and flank_mult > front_mult,
		failures,
		"bind_wrestle_orient: rear grapple should unroot more than flank, flank more than face-on "
		+ "(rear=%.3f flank=%.3f front=%.3f)"
		% [rear_mult, flank_mult, front_mult]
	)
	# Bounded: even a rear-arc full-strength wrestle stays under the cumulative cap.
	_assert(
		CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S * rear_mult < CombatConstants.OFF_BALANCE_MAX_WINDOW_S,
		failures,
		"bind_wrestle_orient: rear-arc window should stay under the cumulative cap "
		+ "(got %.3f vs cap %.1f)"
		% [CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S * rear_mult, CombatConstants.OFF_BALANCE_MAX_WINDOW_S]
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
		"ob_fade: fresh penalty should be ~full (%.3f) got %f"
		% [full, PassiveParryContext.off_balance_penalty_mult(fresh, full)]
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
		"ob_fade: legacy (no total) penalty should be ~full (%.3f) got %f"
		% [full, PassiveParryContext.off_balance_penalty_mult(legacy, full)]
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
	_assert(
		PassiveParryContext.is_off_balance(c0),
		failures,
		"regain_footing: fixture should be off-balance"
	)
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
		depth_after < 1.0,
		failures,
		"regain_footing: depth should drop below 1.0 after re-root got %.3f" % depth_after
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
	_assert(PassiveParryContext.off_balance_depth(c) > 0.9, failures, "cumulative: depth should be ~full after re-stagger got %.3f" % PassiveParryContext.off_balance_depth(c))
	# A large fresh event while already off-balance is clamped to the cap.
	var t3: float = PassiveParryContext.apply_off_balance_window(c, 99.0)
	_assert(
		is_equal_approx(t3, CombatConstants.OFF_BALANCE_MAX_WINDOW_S),
		failures,
		"cumulative: stacked window should clamp to the cap (%.1f) got %.3f"
		% [CombatConstants.OFF_BALANCE_MAX_WINDOW_S, t3]
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
	var remaining_after_root: float = maxf(0.0, c0.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0) - CombatTiming.now_seconds())
	_assert(
		remaining_after_root > 0.0 and remaining_after_root <= 1.0 + 0.05,
		failures,
		"life: re-root should halve the 2.0s window to ~1.0s got %.3f" % remaining_after_root
	)
	# Re-strike (strike path) while still staggered: extends the halved window and re-ignites depth.
	var t: float = PassiveParryContext.apply_off_balance_window(c0, 0.8)
	var remaining_after_strike: float = maxf(0.0, c0.get(DataKeys.PA_OFF_BALANCE_UNTIL, -1.0) - CombatTiming.now_seconds())
	_assert(
		remaining_after_strike > remaining_after_root,
		failures,
		"life: re-strike should extend the post-root window (%.3f > %.3f)"
		% [remaining_after_strike, remaining_after_root]
	)
	_assert(
		t > remaining_after_root,
		failures,
		"life: new window total should exceed the halved remaining (%.3f > %.3f)"
		% [t, remaining_after_root]
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
		"life: invariant total>=remaining / depth<=1 violated (total=%.3f remaining=%.3f depth=%.3f)"
		% [total_now, remaining_after_strike, PassiveParryContext.off_balance_depth(c0)]
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## Glancing/negligible strike separation: a graze must not stagger the defender as hard as a clean
## hit, and a negligible chip must not stagger at all. Verifies the outcome multiplier mapping, the
## fail-safe for unknown outcomes, and that the glancing window composes under the part multipliers.
static func run_off_balance_glancing_strike(failures: PackedStringArray) -> void:
	# Constant is a true reduction in (0, 1).
	_assert(
		CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT > 0.0
		and CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT < 1.0,
		failures,
		"glancing_ob: HIT_GLANCING_OFF_BALANCE_MULT (%.2f) should be in (0, 1)"
		% CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT
	)
	# Outcome mapping: clean = full, glancing = the constant, negligible = none.
	_assert(
		is_equal_approx(CombatConstants.hit_off_balance_outcome_mult("hit"), 1.0),
		failures, "glancing_ob: clean hit should map to 1.0"
	)
	_assert(
		is_equal_approx(
			CombatConstants.hit_off_balance_outcome_mult("glancing"),
			CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT
		),
		failures,
		"glancing_ob: glancing hit should map to the constant (%.2f)"
		% CombatConstants.HIT_GLANCING_OFF_BALANCE_MULT
	)
	_assert(
		is_equal_approx(CombatConstants.hit_off_balance_outcome_mult("negligible"), 0.0),
		failures, "glancing_ob: negligible chip should map to 0.0 (no stagger)"
	)
	# Fail-safe: a missing/unknown outcome must never zero out a legitimate stagger.
	_assert(
		is_equal_approx(CombatConstants.hit_off_balance_outcome_mult(""), 1.0)
		and is_equal_approx(CombatConstants.hit_off_balance_outcome_mult("unknown_outcome"), 1.0),
		failures, "glancing_ob: unknown/empty outcome should default to 1.0 (clean-hit assumption)"
	)
	# Ordering: clean > glancing > negligible, and a glancing hit still leaves some stagger.
	_assert(
		CombatConstants.hit_off_balance_outcome_mult("hit")
		> CombatConstants.hit_off_balance_outcome_mult("glancing")
		and CombatConstants.hit_off_balance_outcome_mult("glancing")
		> CombatConstants.hit_off_balance_outcome_mult("negligible"),
		failures, "glancing_ob: expected clean > glancing > negligible ordering"
	)
	# Composition: a glancing head hit (mult x 1.30 part) must stay weaker than a clean chest hit (1.0 x 1.0).
	var glancing_head: float = CombatConstants.hit_off_balance_outcome_mult("glancing") * CombatConstants.hit_part_off_balance_mult("head")
	var clean_chest: float = CombatConstants.hit_off_balance_outcome_mult("hit") * CombatConstants.hit_part_off_balance_mult("chest")
	_assert(
		glancing_head < clean_chest,
		failures,
		"glancing_ob: glancing head hit (%.3f) should stagger less than a clean chest hit (%.3f)"
		% [glancing_head, clean_chest]
	)


## The hit-stagger window composition (base x part x outcome x recovery) as one named helper:
## PassiveParryContext.hit_off_balance_window. Catches wrong-ordering/combination bugs that
## per-factor tests would miss, and pins that a D001-neutral combatant gets ~base x part x outcome.
static func run_off_balance_hit_window_composition(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	var c: Dictionary = mgr.combatants[0]
	# D001-neutral defender: no injuries, default stats, no exhaustion -> recovery ~1.0.
	var rec: float = PassiveParryContext.off_balance_recovery_mult(c)
	_assert(
		rec > 0.9 and rec < 1.1,
		failures,
		"ob_compose: neutral recovery should be ~1.0 got %.3f" % rec
	)
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
		"cont_outcome: expected 0 < glancing (%.3f) < full (%.3f) and negligible == 0 (got %.3f)"
		% [glancing_win, full_win, neg_win]
	)
	# Clean: full window stamped.
	CounterTempo.grant_hit_continuation(mgr, c, tid, full_win)
	var clean_until: float = c.get(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL, -1.0)
	_assert(
		is_equal_approx(clean_until - clock, full_win),
		failures,
		"cont_outcome: clean hit should grant the full window (until-clock=%.3f want %.3f)"
		% [clean_until - clock, full_win]
	)
	c.erase(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL)
	c.erase(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_TARGET_ID)
	# Glancing: shorter window than clean.
	CounterTempo.grant_hit_continuation(mgr, c, tid, glancing_win)
	var glancing_until: float = c.get(CombatConstants.COMBATANT_KEY_HIT_CONTINUATION_UNTIL, -1.0)
	_assert(
		is_equal_approx(glancing_until - clock, glancing_win),
		failures,
		"cont_outcome: glancing hit should grant the scaled window (until-clock=%.3f want %.3f)"
		% [glancing_until - clock, glancing_win]
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
		"cont_outcome: default call should still grant the full window (until-clock=%.3f)"
		% (default_until - clock)
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## Parry-deflect off-balance alignment scale: the applier multiplies the *attacker's* post-deflect
## off-balance window by parry_recoil_alignment_mult(alignment), the same factor the blade-recoil
## path uses. A glancing catch (low alignment) must disorient less than a square-on catch at equal
## strike intensity; neutral alignment stays ~1.0.
static func run_parry_deflect_alignment_off_balance(failures: PackedStringArray) -> void:
	var base: float = CombatConstants.off_balance_deflect_duration(0.8)
	var glancing_total: float = base * CombatConstants.parry_recoil_alignment_mult(0.1)
	var square_total: float = base * CombatConstants.parry_recoil_alignment_mult(1.0)
	var neutral_total: float = base * CombatConstants.parry_recoil_alignment_mult(0.5)
	_assert(
		glancing_total < base and square_total > base,
		failures,
		"pdeflect_align: glancing (%.3f) should be < base (%.3f) < square (%.3f)"
		% [glancing_total, base, square_total]
	)
	_assert(
		absf(neutral_total - base) < 0.02 * base,
		failures,
		"pdeflect_align: neutral alignment should be ~unchanged (got %.3f vs %.3f)"
		% [neutral_total, base]
	)
	# Bounded: the scale never drops off-balance to zero or blows past 2x.
	_assert(
		CombatConstants.parry_recoil_alignment_mult(0.0) >= 0.5
		and CombatConstants.parry_recoil_alignment_mult(1.0) <= 2.0,
		failures,
		"pdeflect_align: alignment scale out of sane bounds"
	)
	# Impulse axis (this pass): a parried heavy swing over-extends the attacker more than a parried
	# light probe, at the same alignment. Shares the hit/miss impulse map, neutral at the mid band.
	var heavy_deflect: float = base * CombatConstants.hit_impulse_stagger_mult(95.0)
	var light_deflect: float = base * CombatConstants.hit_impulse_stagger_mult(35.0)
	var mid_deflect: float = base * CombatConstants.hit_impulse_stagger_mult(65.0)
	_assert(
		heavy_deflect > base and light_deflect < base,
		failures,
		"pdeflect_impulse: heavy parried swing should over-extend more (%.3f > %.3f) and light less (%.3f < %.3f)"
		% [heavy_deflect, base, light_deflect, base]
	)
	_assert(
		absf(mid_deflect - base) < 0.001 * base,
		failures,
		"pdeflect_impulse: mid-band KE should be D001-neutral (got %.4f vs base %.4f)"
		% [mid_deflect, base]
	)
	_assert(
		is_equal_approx(base * CombatConstants.hit_impulse_stagger_mult(-1.0), base),
		failures, "pdeflect_impulse: missing KE in the clash context should stay neutral"
	)
	# Armor-inertia axis (this pass): a parried heavy-armor swing recovers slower than an unarmed
	# one, mirroring the whiff / dodge-attacker self-penalties. Neutral (1.0) with no armor (D001).
	_assert(
		is_equal_approx(CombatConstants.whiff_armor_inertia_mult(0.0), 1.0),
		failures, "pdeflect_armor: no armor should be neutral 1.0"
	)
	_assert(
		CombatConstants.whiff_armor_inertia_mult(1.0) > 1.0,
		failures,
		"pdeflect_armor: full-armor parried swing should over-extend more (got %.3f)"
		% CombatConstants.whiff_armor_inertia_mult(1.0)
	)


## Impulse-driven stagger + head-impact startle floor: the off-balance window now scales with the
## strike's kinetic energy (neutral at the mid-band so D001 pacing holds), and a clean head hit above
## the KE threshold carries a hard floor that agility/recovery cannot undercut.
static func run_off_balance_impulse_and_startle(failures: PackedStringArray) -> void:
	# Impulse mapping: 35 J -> 0.8, 95 J -> 1.2, 65 J (mid band) -> 1.0, no KE -> neutral.
	_assert(
		is_equal_approx(CombatConstants.hit_impulse_stagger_mult(35.0), 0.8),
		failures,
		"impulse_ob: 35 J should map to the min mult 0.8 got %.3f"
		% CombatConstants.hit_impulse_stagger_mult(35.0)
	)
	_assert(
		is_equal_approx(CombatConstants.hit_impulse_stagger_mult(95.0), 1.2),
		failures,
		"impulse_ob: 95 J should map to the max mult 1.2 got %.3f"
		% CombatConstants.hit_impulse_stagger_mult(95.0)
	)
	_assert(
		absf(CombatConstants.hit_impulse_stagger_mult(65.0) - 1.0) < 0.001,
		failures,
		"impulse_ob: mid-band 65 J should be D001-neutral 1.0 got %.3f"
		% CombatConstants.hit_impulse_stagger_mult(65.0)
	)
	_assert(
		is_equal_approx(CombatConstants.hit_impulse_stagger_mult(0.0), 1.0)
		and is_equal_approx(CombatConstants.hit_impulse_stagger_mult(-1.0), 1.0),
		failures, "impulse_ob: missing KE should stay neutral 1.0"
	)
	_assert(
		is_equal_approx(CombatConstants.hit_impulse_stagger_mult(500.0), 1.2),
		failures, "impulse_ob: KE above the band should clamp to the max mult"
	)
	# Startle floor: applies only to a clean head hit above the KE threshold.
	_assert(
		is_equal_approx(CombatConstants.hit_startle_min_s("head", "hit", 65.0), CombatConstants.STARTLE_HEAD_IMPACT_MIN_S),
		failures,
		"impulse_ob: clean head hit at 65 J should carry the startle floor (%.2f)"
		% CombatConstants.STARTLE_HEAD_IMPACT_MIN_S
	)
	_assert(
		CombatConstants.hit_startle_min_s("chest", "hit", 65.0) == 0.0
		and CombatConstants.hit_startle_min_s("head", "hit", 30.0) == 0.0
		and CombatConstants.hit_startle_min_s("head", "negligible", 65.0) == 0.0
		and CombatConstants.hit_startle_min_s("head", "glancing", 65.0) == 0.0,
		failures, "impulse_ob: startle floor should apply only to clean head hits above the KE threshold"
	)
	# Composition: heavy KE stuns more than light KE on the same clean torso hit.
	var c: Dictionary = {}
	var heavy: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", c, 95.0)
	var light: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", c, 35.0)
	_assert(
		heavy > light,
		failures,
		"impulse_ob: heavy KE (%.3f) should stagger more than light (%.3f)"
		% [heavy, light]
	)
	# The floor binds: the lightest clean head hit (i=0, 40 J) would be ~0.54s; the startle floor
	# holds it at 0.55s. The same blow to the torso stays below the floor (no startle on the torso).
	var light_head: float = PassiveParryContext.hit_off_balance_window(0.0, "head", "hit", {}, 40.0)
	var light_chest: float = PassiveParryContext.hit_off_balance_window(0.0, "chest", "hit", {}, 40.0)
	_assert(
		light_head >= CombatConstants.STARTLE_HEAD_IMPACT_MIN_S - 0.001,
		failures,
		"impulse_ob: lightest head hit should hold the startle floor (got %.3f, floor %.2f)"
		% [light_head, CombatConstants.STARTLE_HEAD_IMPACT_MIN_S]
	)
	_assert(
		light_chest < CombatConstants.STARTLE_HEAD_IMPACT_MIN_S,
		failures,
		"impulse_ob: torso hit should not reach the head startle floor (got %.3f)"
		% light_chest
	)


## Whiff impulse: a whiffed swing leaves the attacker over-extended in proportion to the swing's
## kinetic energy (the follow-through that had to be decelerated), distinct from commitment
## (intensity). Same shared impulse map as the hit path: neutral at the mid band so D001 holds.
static func run_off_balance_whiff_impulse(failures: PackedStringArray) -> void:
	var base: float = CombatConstants.miss_off_balance_duration(0.5)
	_assert(
		base > 0.0,
		failures,
		"whiff_ob: miss base off-balance should be positive (got %.3f)"
		% base
	)
	var heavy: float = base * CombatConstants.hit_impulse_stagger_mult(95.0)
	var light: float = base * CombatConstants.hit_impulse_stagger_mult(35.0)
	var mid: float = base * CombatConstants.hit_impulse_stagger_mult(65.0)
	_assert(
		heavy > base and light < base,
		failures,
		"whiff_ob: heavy whiff should over-extend more (%.3f > %.3f) and light whiff less (%.3f < %.3f)"
		% [heavy, base, light, base]
	)
	# Mid-band is D001-neutral: the whiff window is unchanged from the intensity-only base.
	_assert(
		absf(mid - base) < 0.001 * base,
		failures,
		"whiff_ob: mid-band KE should be neutral (got %.4f vs base %.4f)"
		% [mid, base]
	)
	# Missing KE data must not fabricate a discount or extension.
	_assert(
		is_equal_approx(base * CombatConstants.hit_impulse_stagger_mult(-1.0), base),
		failures, "whiff_ob: missing KE should stay neutral"
	)
	# Move-type commit extras still stack on top of the impulse-scaled base.
	var feint_mid: float = mid + CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S
	var thrust_mid: float = mid + CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S
	_assert(
		feint_mid > mid and thrust_mid > mid,
		failures,
		"whiff_ob: feint/thrust commit extras should still stack over the impulse base (feint=%.3f thrust=%.3f base=%.3f)"
		% [feint_mid, thrust_mid, mid]
	)


## Engagement-orientation stagger: a hit that meets the defender's flank or rear disrupts balance
## more than a frontal hit (the impact crosses / bypasses the base of support). Front is the neutral
## 1.0 baseline so D001 1v1 duels (always face-on) are unaffected; unknown angles degrade to 1.0.
static func run_off_balance_orientation_stagger(failures: PackedStringArray) -> void:
	_assert(
		is_equal_approx(CombatConstants.hit_orientation_stagger_mult("front"), 1.0),
		failures, "orient_ob: front should be the neutral 1.0 baseline"
	)
	_assert(
		CombatConstants.hit_orientation_stagger_mult("flank") > 1.0
		and CombatConstants.hit_orientation_stagger_mult("flank") < CombatConstants.hit_orientation_stagger_mult("rear"),
		failures,
		"orient_ob: expected front < flank < rear (flank=%.2f rear=%.2f)"
		% [
			CombatConstants.hit_orientation_stagger_mult("flank"),
			CombatConstants.hit_orientation_stagger_mult("rear"),
		]
	)
	_assert(
		CombatConstants.hit_orientation_stagger_mult("") == 1.0
		and CombatConstants.hit_orientation_stagger_mult("unknown") == 1.0,
		failures, "orient_ob: unknown/empty angle should degrade to 1.0"
	)
	# Composition: same clean torso hit, rear-facing defender stags longer than front-facing.
	var front_c: Dictionary = {}
	front_c[DataKeys.PA_ENGAGEMENT_ANGLE] = "front"
	var rear_c: Dictionary = {}
	rear_c[DataKeys.PA_ENGAGEMENT_ANGLE] = "rear"
	var front_window: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", front_c)
	var rear_window: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", rear_c)
	_assert(
		rear_window > front_window,
		failures,
		"orient_ob: rear-facing defender should stagger longer (%.3f > %.3f)"
		% [rear_window, front_window]
	)
	# Default (no stamped angle) equals the explicit front baseline.
	var default_c: Dictionary = {}
	var default_window: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", default_c)
	_assert(
		is_equal_approx(default_window, front_window),
		failures,
		"orient_ob: missing angle should default to front baseline (%.3f vs %.3f)"
		% [default_window, front_window]
	)


## Armor-mass inertia: heavy armor braces a defender against impact-stagger (less off-balance on a
## hit) but adds swing mass to an attacker (longer over-extension on a whiff). Both are 1.0 neutral
## with no armor (D001 default) and bounded so armor never dominates the window.
static func run_off_balance_armor_inertia(failures: PackedStringArray) -> void:
	# No armor: both sides neutral.
	_assert(
		is_equal_approx(CombatConstants.hit_armor_inertia_mult(0.0), 1.0)
		and is_equal_approx(CombatConstants.whiff_armor_inertia_mult(0.0), 1.0),
		failures, "armor_ob: no armor should be neutral 1.0 on both sides"
	)
	# Full armor: defender staggers less, attacker over-extends more; both bounded.
	var hit_full: float = CombatConstants.hit_armor_inertia_mult(1.0)
	var whiff_full: float = CombatConstants.whiff_armor_inertia_mult(1.0)
	_assert(
		hit_full < 1.0 and hit_full > 0.5,
		failures,
		"armor_ob: full-armor defender should stagger less, bounded (got %.3f)" % hit_full
	)
	_assert(
		whiff_full > 1.0 and whiff_full < 2.0,
		failures,
		"armor_ob: full-armor attacker should over-extend more, bounded (got %.3f)" % whiff_full
	)
	# Exact constant values at full armor.
	_assert(
		is_equal_approx(hit_full, 1.0 - CombatConstants.HIT_ARMOR_INERTIA_REDUCTION)
		and is_equal_approx(whiff_full, 1.0 + CombatConstants.WHIFF_ARMOR_INERTIA_EXTENSION),
		failures, "armor_ob: full-armor values should equal 1 -/+ the reduction/extension constants"
	)
	# Monotonic in armor ratio: hit reduction deepens, whiff extension grows.
	_assert(
		CombatConstants.hit_armor_inertia_mult(0.5) > hit_full
		and CombatConstants.hit_armor_inertia_mult(0.5) < 1.0,
		failures, "armor_ob: hit armor mult should decrease monotonically with armor"
	)
	_assert(
		CombatConstants.whiff_armor_inertia_mult(0.5) < whiff_full
		and CombatConstants.whiff_armor_inertia_mult(0.5) > 1.0,
		failures, "armor_ob: whiff armor mult should increase monotonically with armor"
	)
	# Out-of-range ratios clamp to [0,1] before lerping (no extrapolation).
	_assert(
		is_equal_approx(CombatConstants.hit_armor_inertia_mult(5.0), hit_full)
		and is_equal_approx(CombatConstants.whiff_armor_inertia_mult(-5.0), 1.0),
		failures, "armor_ob: armor ratio should clamp to [0,1] before lerping"
	)


## Dodge->footing: a full dodge is a movement off the base of support, so the dodger is briefly
## off-balance until they re-stabilize. The window grows with the incoming strike's intensity, sits
## below the whiff base (a braced reactive dodge re-centers faster than a committed over-extension),
## and routes through off_balance_recovery_mult so agility gates re-stabilization like it does after
## a hit. This closes the footing<->dodge loop: off-balance already reduces dodge chance
## (OFF_BALANCE_DODGE_CHANCE_MULT); now dodging itself costs footing.
static func run_off_balance_dodge_stagger(failures: PackedStringArray) -> void:
	var base: float = CombatConstants.dodge_off_balance_duration(0.0)
	var heavy: float = CombatConstants.dodge_off_balance_duration(1.0)
	_assert(
		absf(base - CombatConstants.DODGE_OFF_BALANCE_BASE_S) < 0.001,
		failures,
		"dodge_ob: zero intensity should equal the base constant (got %.3f, base %.3f)"
		% [base, CombatConstants.DODGE_OFF_BALANCE_BASE_S]
	)
	_assert(
		heavy > base,
		failures,
		"dodge_ob: a harder incoming strike should demand a bigger evasive move (%.3f > %.3f)"
		% [heavy, base]
	)
	# A braced, reactive dodge re-centers faster than a forward-committed whiff.
	_assert(
		base < CombatConstants.OFF_BALANCE_DURATION_S,
		failures,
		"dodge_ob: dodge base should sit below the whiff base (%.2f < %.2f)"
		% [base, CombatConstants.OFF_BALANCE_DURATION_S]
	)
	# Bounded: full-intensity window stays well under the cumulative cap.
	_assert(
		heavy < CombatConstants.OFF_BALANCE_MAX_WINDOW_S,
		failures,
		"dodge_ob: full-intensity window should stay far under the cumulative cap (got %.3f)"
		% heavy
	)
	# Integration: the dodger's re-stabilization is gated by the same recovery system as hit
	# re-stabilization — a low-agility dodger lingers off-balance longer than a high-agility one.
	var slow_c: Dictionary = {}
	slow_c[DataKeys.COMBATANT_STATS] = {DataKeys.ENTITY_AGILITY: 10.0}
	var quick_c: Dictionary = {}
	quick_c[DataKeys.COMBATANT_STATS] = {DataKeys.ENTITY_AGILITY: 90.0}
	var slow_total: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* PassiveParryContext.off_balance_recovery_mult(slow_c)
	var quick_total: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* PassiveParryContext.off_balance_recovery_mult(quick_c)
	_assert(
		slow_total > quick_total,
		failures,
		"dodge_ob: low-agility dodger should linger off-balance longer (slow=%.3f quick=%.3f)"
		% [slow_total, quick_total]
	)
	# Impulse axis (this pass): a heavy incoming swing forces a bigger evasive motion, so the
	# dodger is off-balance longer. Neutral at the mid band; heavy > light. Same shared impulse map.
	var dodge_neutral: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* CombatConstants.hit_impulse_stagger_mult(65.0)
	_assert(
		absf(dodge_neutral - CombatConstants.dodge_off_balance_duration(0.5)) < 0.001 * base,
		failures,
		"dodge_ob: mid-band incoming KE should be D001-neutral for the dodger (got %.4f vs %.4f)"
		% [dodge_neutral, CombatConstants.dodge_off_balance_duration(0.5)]
	)
	var dodge_heavy: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* CombatConstants.hit_impulse_stagger_mult(95.0)
	var dodge_light: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* CombatConstants.hit_impulse_stagger_mult(35.0)
	_assert(
		dodge_heavy > dodge_neutral and dodge_light < dodge_neutral,
		failures,
		"dodge_ob: heavy incoming swing should stagger the dodger more than a light one "
		+ "(heavy=%.3f neutral=%.3f light=%.3f)"
		% [dodge_heavy, dodge_neutral, dodge_light]
	)
	# Armor-inertia axis (this pass): a heavily-armored dodger re-centers the evasive step slower —
	# the same carried-mass axis as the whiff / dodge-attacker / parry self-penalties. Neutral at 0.
	var dodge_bare: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* CombatConstants.hit_impulse_stagger_mult(65.0) \
		* CombatConstants.whiff_armor_inertia_mult(0.0)
	var dodge_armored: float = CombatConstants.dodge_off_balance_duration(0.5) \
		* CombatConstants.hit_impulse_stagger_mult(65.0) \
		* CombatConstants.whiff_armor_inertia_mult(1.0)
	_assert(
		is_equal_approx(dodge_bare, CombatConstants.dodge_off_balance_duration(0.5))
		and dodge_armored > dodge_bare,
		failures,
		"dodge_ob: armored dodger should linger off-balance longer than bare (armored=%.3f bare=%.3f)"
		% [dodge_armored, dodge_bare]
	)
	# Orientation axis (this pass): dodging a rear-arc attack is harder than face-on — the dodger
	# pivots against their own center. Same shared orientation map as the hit path; face-on is 1.0.
	_assert(
		is_equal_approx(CombatConstants.hit_orientation_stagger_mult("front"), 1.0),
		failures, "dodge_ob_orient: face-on dodge should be D001-neutral 1.0"
	)
	_assert(
		CombatConstants.hit_orientation_stagger_mult("rear") > CombatConstants.hit_orientation_stagger_mult("flank")
		and CombatConstants.hit_orientation_stagger_mult("flank") > 1.0,
		failures,
		"dodge_ob_orient: rear dodge should stagger more than flank, flank more than face-on "
		+ "(rear=%.3f flank=%.3f)"
		% [CombatConstants.hit_orientation_stagger_mult("rear"), CombatConstants.hit_orientation_stagger_mult("flank")]
	)


## Attacker self-penalty on a dodged swing: a swing the defender dodges over-extends the attacker
## exactly like a whiff (the miss-path formula: commitment + impulse + move-type extras, gated by
## recovery). Locks the swing-KE helper (null weapon -> -1 neutral; real weapon positive and
## monotonic in intensity) and that a mid-band dodged swing is D001-neutral vs the miss base.
static func run_off_balance_dodge_attacker_self_penalty(failures: PackedStringArray) -> void:
	# Swing KE helper: null weapon -> -1.0 so the impulse term stays neutral (never fabricates).
	_assert(
		AttackResolver._swing_kinetic_energy_j(null, 0.5, {}, "oberhau") == -1.0,
		failures, "dodge_atk_ob: null weapon should return -1.0 (neutral impulse)"
	)
	var sword = HarnessFixtures.get_cached_weapon("SWORD")
	if sword == null:
		_assert(false, failures, "dodge_atk_ob: missing SWORD fixture")
		return
	var ke_lo: float = AttackResolver._swing_kinetic_energy_j(sword, 0.2, {}, "oberhau")
	var ke_hi: float = AttackResolver._swing_kinetic_energy_j(sword, 0.9, {}, "oberhau")
	_assert(
		ke_lo > 0.0 and ke_hi > ke_lo,
		failures,
		"dodge_atk_ob: swing KE should be positive and grow with intensity (lo=%.1f hi=%.1f)"
		% [ke_lo, ke_hi]
	)
	# The dodged-swing self-penalty reuses the miss formula; at the mid-band KE it must be
	# D001-neutral (the impulse factor is 1.0), equal to the intensity-only miss base.
	var intensity: float = 0.5
	var mid_ke: float = 65.0
	var dodge_self: float = CombatConstants.miss_off_balance_duration(intensity) \
		* CombatConstants.hit_impulse_stagger_mult(mid_ke)
	_assert(
		is_equal_approx(dodge_self, CombatConstants.miss_off_balance_duration(intensity)),
		failures,
		"dodge_atk_ob: mid-band dodged swing should equal the intensity-only miss base "
		+ "(got %.4f vs %.4f)" % [dodge_self, CombatConstants.miss_off_balance_duration(intensity)]
	)
	# A heavy (high-KE) dodged swing over-extends the attacker more than a light (low-KE) one.
	var heavy_self: float = CombatConstants.miss_off_balance_duration(intensity) \
		* CombatConstants.hit_impulse_stagger_mult(95.0)
	var light_self: float = CombatConstants.miss_off_balance_duration(intensity) \
		* CombatConstants.hit_impulse_stagger_mult(35.0)
	_assert(
		heavy_self > light_self,
		failures,
		"dodge_atk_ob: heavy dodged swing should over-extend more than light (heavy=%.3f light=%.3f)"
		% [heavy_self, light_self]
	)


## Bind-contest off-balance penalty: the constant is a bounded discount, and the penalty fades with
## depth (1.0 when settled, < 1.0 while off-balance, reaching the constant near full depth).
static func run_off_balance_bind_contest_penalty(failures: PackedStringArray) -> void:
	_assert(
		CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT > 0.0 and CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT < 1.0,
		failures,
		"bind_penalty: OFF_BALANCE_BIND_CONTEST_MULT must be in (0, 1) got %.3f"
		% CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT
	)
	# Settled: no penalty.
	var settled: Dictionary = {}
	_assert(
		PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT) == 1.0,
		failures,
		"bind_penalty: settled fighter should get no penalty"
	)
	# Off-balance: a discount between the constant and 1.0.
	var ob: Dictionary = {}
	PassiveParryContext.apply_off_balance_window(ob, 1.0)
	var p: float = PassiveParryContext.off_balance_penalty_mult(ob, CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT)
	# Discount is a lerp from 1.0 (settled) to the constant (full depth), so the off-balance value is
	# bounded in [constant, 1.0). It equals the constant at full depth (same-ms read), so use >=.
	_assert(
		p >= CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT and p < 1.0,
		failures,
		"bind_penalty: off-balance contest power should be discounted to [mult, 1.0) (got %.3f)"
		% p
	)


## Execute fumble + close-attempt off-balance constants: both must be bounded, and the execute fumble
## chance must scale with depth (0 when settled, == MAX at full depth).
static func run_off_balance_execute_and_close_constants(failures: PackedStringArray) -> void:
	_assert(
		CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX > 0.0
		and CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX < 1.0,
		failures,
		"exec_close: execute fumble chance must be in (0, 1) got %.3f"
		% CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX
	)
	_assert(
		CombatConstants.OFF_BALANCE_CLOSE_PRESSURE_MULT > 0.0 and CombatConstants.OFF_BALANCE_CLOSE_PRESSURE_MULT < 1.0,
		failures,
		"exec_close: close pressure mult must be in (0, 1) got %.3f"
		% CombatConstants.OFF_BALANCE_CLOSE_PRESSURE_MULT
	)
	# Fumble chance scales with depth: 0 settled, == MAX at full depth.
	var settled: Dictionary = {}
	var full: Dictionary = {}
	PassiveParryContext.apply_off_balance_window(full, 1.0)
	_assert(
		is_equal_approx(PassiveParryContext.off_balance_depth(settled) * CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX, 0.0),
		failures,
		"exec_close: settled attacker fumble chance should be 0"
	)
	# Full depth is clamped to 1.0, so the chance equals the constant.
	_assert(
		PassiveParryContext.off_balance_depth(full) * CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX
		> CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX * 0.9,
		failures,
		"exec_close: full-depth fumble chance should be ~MAX got %.3f"
		% (PassiveParryContext.off_balance_depth(full) * CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX)
	)
	# Off-balance hit-chance mult: a reduction in (0,1); settled -> 1.0 (no penalty), full depth -> the mult.
	_assert(
		CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT > 0.0 and CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT < 1.0,
		failures,
		"exec_close: OFF_BALANCE_HIT_CHANCE_MULT must be in (0, 1) got %.3f"
		% CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT
	)
	_assert(
		is_equal_approx(PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT), 1.0),
		failures,
		"exec_close: settled attacker should take no hit-chance penalty"
	)
	_assert(
		is_equal_approx(
			PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT),
			CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT
		),
		failures,
		"exec_close: full-depth attacker should take the full hit-chance penalty got %.3f"
		% PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT)
	)
	# Target mirror: a wobbly target is easier to hit — the boost is > 1.0, neutral when the target is
	# settled (D001), and equals the constant at full depth.
	_assert(
		CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT > 1.0,
		failures,
		"exec_close: OFF_BALANCE_TARGET_HIT_CHANCE_MULT should be a boost > 1.0 got %.3f"
		% CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT
	)
	_assert(
		is_equal_approx(
			PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT),
			1.0
		),
		failures,
		"exec_close: settled target should give the attacker no hit-chance boost"
	)
	_assert(
		is_equal_approx(
			PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT),
			CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT
		),
		failures,
		"exec_close: full-depth target should give the attacker the full hit-chance boost got %.3f"
		% PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT)
	)


## Strike-location off-balance: head/leg hits disrupt balance more than torso (neutral 1.0),
## arm hits least. Unknown/empty parts degrade gracefully to 1.0.
static func run_off_balance_strike_location(failures: PackedStringArray) -> void:
	_assert(
		CombatConstants.hit_part_off_balance_mult("head") == CombatConstants.HIT_OFF_BALANCE_PART_HEAD_MULT,
		failures,
		"strike_loc: head should map to head mult"
	)
	_assert(
		CombatConstants.hit_part_off_balance_mult("left_leg")
		== CombatConstants.hit_part_off_balance_mult("right_leg"),
		failures,
		"strike_loc: both legs should share the same mult"
	)
	_assert(
		CombatConstants.hit_part_off_balance_mult("head")
		> CombatConstants.hit_part_off_balance_mult("chest"),
		failures,
		"strike_loc: head should disrupt balance more than torso"
	)
	_assert(
		CombatConstants.hit_part_off_balance_mult("left_arm")
		< CombatConstants.hit_part_off_balance_mult("chest"),
		failures,
		"strike_loc: arm should disrupt balance less than torso"
	)
	_assert(
		is_equal_approx(CombatConstants.hit_part_off_balance_mult(""), 1.0),
		failures,
		"strike_loc: unknown part should default to 1.0"
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


## Regain Footing AI wiring: a staggered fighter must surface Regain Footing in its menu and the real
## picker weight must be positive + depth-scaled, so the AI re-roots instead of grinding a compromised
## strike. Settled: not listed, weight 0. Closes the "built but never picked" gap.
static func run_off_balance_regain_footing_ai_selection(failures: PackedStringArray) -> void:
	var mgr: Node = _make_1v1_sword()
	var c: Dictionary = mgr.combatants[0]
	var cid: int = CombatantEntityAccess.id_int(c)
	var rf_action: Dictionary = {"target_id": cid, "move_id": CombatConstants.MOVE_ID_REGAIN_FOOTING}
	# build() only produces a full menu for a WAITING combatant at full gauge (mirrors the live turn).
	c[DataKeys.COMBATANT_STATE] = CombatConstants.STATE_WAITING
	c[DataKeys.COMBATANT_GAUGE] = 100.0
	# Settled: not listed, weight 0.
	var settled_menu: Array = AvailableActionsBuilder.build(mgr, cid)
	_assert(
		_actions_have_move(settled_menu, CombatConstants.MOVE_ID_REGAIN_FOOTING) == false,
		failures,
		"rf_ai: settled fighter should NOT list Regain Footing"
	)
	var settled_weight: float = CombatAIActionPicker._get_action_weight(rf_action, cid, mgr, false)
	_assert(
		is_equal_approx(settled_weight, 0.0),
		failures,
		"rf_ai: settled Regain Footing weight should be 0 got %.3f" % settled_weight
	)
	# Off-balance full depth: listed + positive, ~AI_WEIGHT at depth 1.
	PassiveParryContext.apply_off_balance_window(c, 5.0)
	var ob_menu: Array = AvailableActionsBuilder.build(mgr, cid)
	_assert(
		_actions_have_move(ob_menu, CombatConstants.MOVE_ID_REGAIN_FOOTING),
		failures,
		"rf_ai: off-balance fighter should list Regain Footing"
	)
	var rf_weight: float = CombatAIActionPicker._get_action_weight(rf_action, cid, mgr, false)
	_assert(
		rf_weight > 0.0,
		failures,
		"rf_ai: off-balance Regain Footing weight should be > 0 got %.3f" % rf_weight
	)
	_assert(
		rf_weight > CombatConstants.REGAIN_FOOTING_AI_WEIGHT * 0.9,
		failures,
		"rf_ai: full-depth Regain Footing weight should be ~AI_WEIGHT (%.1f) got %.3f"
		% [CombatConstants.REGAIN_FOOTING_AI_WEIGHT, rf_weight]
	)
	HarnessCore._free_manager_restore_global_rng(mgr)


## Calibration guard: off-balance is a *stagger*, not a nullifier. At full depth the attacker's combined
## damage x accuracy and the defender's combined dodge x parry both stay above a floor, so a wobbly
## fighter is hurt but never auto-dead / auto-miss. Guards against a death-spiral calibration stack.
static func run_off_balance_stack_bounded(failures: PackedStringArray) -> void:
	var settled: Dictionary = {}
	var full: Dictionary = {}
	PassiveParryContext.apply_off_balance_window(full, 5.0)
	var atk_comb: float = (
		PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT)
		* PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT)
	)
	_assert(
		atk_comb > 0.30,
		failures,
		"stack_bounded: full-depth attacker dmg x hit-chance (%.3f) should stay > 0.30 (stagger, not nullifier)"
		% atk_comb
	)
	var def_comb: float = (
		PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT)
		* PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT)
	)
	_assert(
		def_comb > 0.30,
		failures,
		"stack_bounded: full-depth defender dodge x parry (%.3f) should stay > 0.30 (hurt, not auto-killed)"
		% def_comb
	)
	# Penalty must fade with depth: settled is stronger / better-armed than full depth on the same axis.
	_assert(
		PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT)
		> PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT),
		failures,
		"stack_bounded: settled attacker should be stronger than full-depth attacker"
	)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static var _mgr_ref: Node = null


static func _actions_have_move(actions: Array, move_id: String) -> bool:
	for a in actions:
		if a.get(DataKeys.ACTION_MOVE_ID, "") == move_id:
			return true
	return false


## Formation-move settling: plug=0 (no-op), rotate=base*1.2, fall_back=base*1.1.
## apply_formation_settle should create an off-balance window for non-zero durations.
static func run_formation_settle_off_balance(failures: PackedStringArray) -> void:
	var base: float = CombatConstants.FORMATION_SETTLE_OFF_BALANCE_BASE_S
	_assert(base > 0.0, failures, "form_settle: base must be > 0 got %f" % base)
	# plug -> 0.0
	_assert(
		is_equal_approx(CombatConstants.formation_settle_off_balance_duration("plug_forward"), 0.0),
		failures,
		"form_settle: plug should be 0.0 got %f" % CombatConstants.formation_settle_off_balance_duration("plug_forward")
	)
	# rotate -> base * 1.2
	var expected_rotate: float = base * CombatConstants.FORMATION_SETTLE_ROTATE_SCALE
	_assert(
		absf(CombatConstants.formation_settle_off_balance_duration("rotate_file") - expected_rotate) < 0.001,
		failures,
		"form_settle: rotate should be %.3f got %f" % [expected_rotate, CombatConstants.formation_settle_off_balance_duration("rotate_file")]
	)
	# fall_back -> base * 1.1
	var expected_fb: float = base * CombatConstants.FORMATION_SETTLE_FALL_BACK_SCALE
	_assert(
		absf(CombatConstants.formation_settle_off_balance_duration(CombatConstants.MOVE_ID_FALL_BACK) - expected_fb) < 0.001,
		failures,
		"form_settle: fall_back should be %.3f got %f"
		% [expected_fb, CombatConstants.formation_settle_off_balance_duration(CombatConstants.MOVE_ID_FALL_BACK)]
	)
	# apply_formation_settle with plug: no off-balance window created
	var c_plug: Dictionary = {}
	PassiveParryContext.apply_formation_settle(c_plug, "plug_forward")
	_assert(
		not PassiveParryContext.is_off_balance(c_plug),
		failures,
		"form_settle: plug should not create off-balance window"
	)
	# apply_formation_settle with rotate: creates off-balance window
	var c_rot: Dictionary = {}
	PassiveParryContext.apply_formation_settle(c_rot, "rotate_file")
	_assert(
		PassiveParryContext.is_off_balance(c_rot),
		failures,
		"form_settle: rotate should create off-balance window"
	)


## Cower re-plant: healthy legs get base window; compromised legs (<0.9) get a longer window.
static func run_cower_replant_off_balance(failures: PackedStringArray) -> void:
	var base: float = CombatConstants.COWER_REPLANT_OFF_BALANCE_BASE_S
	_assert(base > 0.0, failures, "cower_replant: base must be > 0 got %f" % base)
	# Healthy legs (functionality >= 0.9): base duration
	_assert(
		is_equal_approx(
			CombatConstants.cower_replant_off_balance_duration(1.0), base
		),
		failures,
		"cower_replant: healthy legs should get base (%.2f) got %f"
		% [base, CombatConstants.cower_replant_off_balance_duration(1.0)]
	)
	# Compromised legs (functionality < 0.9): base * 1.4
	var expected: float = base * CombatConstants.COWER_REPLANT_LEGS_SCALE
	_assert(
		absf(
			CombatConstants.cower_replant_off_balance_duration(0.5) - expected
		) < 0.001,
		failures,
		"cower_replant: compromised legs should get %.3f got %f"
		% [expected, CombatConstants.cower_replant_off_balance_duration(0.5)]
	)
	# Boundary: exactly at threshold should use base (not legs scale)
	_assert(
		is_equal_approx(
			CombatConstants.cower_replant_off_balance_duration(0.9), base
		),
		failures,
		"cower_replant: at threshold 0.9 should get base (%.2f) got %f"
		% [base, CombatConstants.cower_replant_off_balance_duration(0.9)]
	)


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
