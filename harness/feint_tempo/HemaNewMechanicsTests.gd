class_name HemaNewMechanicsTests

extends HemaTestBase

## HEMA line mechanics: Nach (riposte line-aim), Gegenschlag (counterblow trade),
## Verwunden (circumscription open-line penalty) and open-line stamping/lifetime.


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
    _assert_eq(
        line_cleared,
        "",
        failures,
        "nach_clear: riposte_target_line should be empty after clear got '%s'" % line_cleared
    )

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
        line, "", failures, "nach_no_chain: riposte_target_line should be empty when no chain active got '%s'" % line
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
        prob == 0.0, failures, "gegenschlag_no_pending: should return 0.0 when no pending melee attack got %.4f" % prob
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
    (
        CombatEventScheduler
        . schedule_event(
            mgr,
            {
                "type": CombatConstants.EVENT_MELEE_ATTACK,
                "combatant_id": atk_id,
                "resolve_at": clock + 2.0,
                "data": {},
            }
        )
    )
    var prob_fav: float = CounterTempo.gegenschlag_trade_probability(mgr, def_id, atk_id)
    _assert(prob_fav > 0.5, failures, "gegenschlag_fav: favorable timing should give prob > 0.5 got %.4f" % prob_fav)
    _assert(prob_fav <= 0.95, failures, "gegenschlag_fav_clamp: prob should be <= 0.95 got %.4f" % prob_fav)

    # Scenario B: their attack resolves in 0.1s (very soon) → unfavorable for us.
    CombatEventScheduler.set_pending_melee_attack_resolve_at(mgr, atk_id, clock + 0.1)
    var prob_unfav: float = CounterTempo.gegenschlag_trade_probability(mgr, def_id, atk_id)
    _assert(
        prob_unfav < prob_fav,
        failures,
        (
            "gegenschlag_unfav: unfavorable timing should give lower prob than favorable (unfav=%.4f fav=%.4f)"
            % [prob_unfav, prob_fav]
        )
    )
    _assert(prob_unfav >= 0.05, failures, "gegenschlag_unfav_clamp: prob should be >= 0.05 got %.4f" % prob_unfav)
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
    _assert(not md.is_empty(), failures, "verwunden_def: move definition should exist")
    _assert(md.get("is_feint", false), failures, "verwunden_def: should have is_feint=true")
    _assert(md.get("circumscription", false), failures, "verwunden_def: should have circumscription=true")
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
        (
            "verwunden_mult: CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT (%.2f) should be < FEINT_OPEN_LINE_PARRY_MULT (%.2f)"
            % [
                CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT,
                CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
            ]
        )
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
    _assert_eq(opp_high, "low", failures, "verwunden_opp: opposite_line('high') should be 'low' got '%s'" % opp_high)
    # low → high
    var opp_low: String = CombatGuardLines.opposite_line("low")
    _assert_eq(opp_low, "high", failures, "verwunden_opp: opposite_line('low') should be 'high' got '%s'" % opp_low)
    # right → left
    var opp_right: String = CombatGuardLines.opposite_line("right")
    _assert_eq(
        opp_right, "left", failures, "verwunden_opp: opposite_line('right') should be 'left' got '%s'" % opp_right
    )
    # left → right
    var opp_left: String = CombatGuardLines.opposite_line("left")
    _assert_eq(
        opp_left, "right", failures, "verwunden_opp: opposite_line('left') should be 'right' got '%s'" % opp_left
    )


## Deflect open-line: a parried attacker is stamped open on their committed line with the
## deflect-specific parry mult (distinct from feint open-line, stronger than plain feint).


static func run_deflect_open_line_constant_and_keys(failures: PackedStringArray) -> void:
    # The deflect open-line penalty is stronger than a plain feint (committed parry opens more than a reaction).
    _assert(
        CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT < CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
        failures,
        (
            "deflect_open: DEFLECT_OPEN_LINE_PARRY_MULT (%.2f) should be < FEINT_OPEN_LINE_PARRY_MULT (%.2f)"
            % [
                CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT,
                CombatConstants.FEINT_OPEN_LINE_PARRY_MULT,
            ]
        )
    )
    # And milder than a deliberate circumscription (going around the blade is more exposing than being parried).
    _assert(
        CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT > CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT,
        failures,
        (
            "deflect_open: DEFLECT_OPEN_LINE_PARRY_MULT (%.2f) should be > CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT (%.2f)"
            % [
                CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT,
                CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT,
            ]
        )
    )
    # The open-line payoff keys are shared with the feint mechanic (same "you are open on this line" semantic).
    _assert(
        DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT == "feint_open_line_parry_mult",
        failures,
        (
            "deflect_open: PA_FEINT_OPEN_LINE_PARRY_MULT key should be stable got '%s'"
            % DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT
        )
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
        (
            "open_line_dur: intensity 0.0 / no-circ should equal base (%.2f) got %.2f"
            % [base, CombatGuardLines.open_line_duration_s(0.0, false)]
        )
    )
    # Full intensity adds the intensity scale.
    var full: float = CombatGuardLines.open_line_duration_s(1.0, false)
    _assert(
        is_equal_approx(full, base + CombatGuardLines.OPEN_LINE_DURATION_INTENSITY_SCALE_S),
        failures,
        (
            "open_line_dur: intensity 1.0 / no-circ should be base+scale (%.2f) got %.2f"
            % [base + CombatGuardLines.OPEN_LINE_DURATION_INTENSITY_SCALE_S, full]
        )
    )
    # Monotonic: a heavier strike holds the line open at least as long as a lighter one.
    _assert(
        (
            CombatGuardLines.open_line_duration_s(0.0, false) < CombatGuardLines.open_line_duration_s(0.5, false)
            and CombatGuardLines.open_line_duration_s(0.5, false) < CombatGuardLines.open_line_duration_s(1.0, false)
        ),
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
        (
            "open_line_dur: intensity 1.0 / circ should not exceed the cap (%.2f) got %.2f"
            % [CombatGuardLines.OPEN_LINE_DURATION_MAX_S, CombatGuardLines.open_line_duration_s(1.0, true)]
        )
    )


## open_line_openness decays over the stamped window with an ease-out recovery curve
## (openness = (1—t)^EASE): no live window -> 0.0, an expired window -> 0.0, a freshly opened
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
        (
            "open_line_decay: early-quarter (%.3f) should exceed twice the late-quarter (%.3f) under ease-out"
            % [early_openness, late_openness]
        )
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
        not empty_c.has(DataKeys.PA_FEINT_OPEN_LINE), failures, "stamp_open_line: empty combatant should be a no-op"
    )

    # Empty line is a no-op.
    CombatGuardLines.stamp_open_line(c, "", 3.0, 0.8)
    _assert(not c.has(DataKeys.PA_FEINT_OPEN_LINE), failures, "stamp_open_line: empty line should be a no-op")

    # Fresh stamp writes all four keys with the given duration/mult.
    CombatGuardLines.stamp_open_line(c, "high", 4.0, 0.8)
    _assert_eq(
        str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")),
        "high",
        failures,
        "stamp_open_line: fresh stamp should store line 'high'"
    )
    _assert(
        (
            c.has(DataKeys.PA_FEINT_OPEN_LINE_UNTIL)
            and c.has(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
            and c.has(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT)
        ),
        failures,
        "stamp_open_line: fresh stamp should write until/duration/parry_mult"
    )
    _assert(
        is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 4.0),
        failures,
        (
            "stamp_open_line: stored duration should be 4.0 got %.2f"
            % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
        )
    )
    _assert(
        is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0)), 0.8),
        failures,
        (
            "stamp_open_line: stored parry mult should be 0.8 got %.2f"
            % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0))
        )
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
        (
            "stamp_open_line: shorter re-open on same line must not shorten the window (%.3f vs %.3f)"
            % [until_after_short, until_first]
        )
    )
    _assert(
        is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 4.0),
        failures,
        (
            "stamp_open_line: stored duration must stay 4.0 after shorter re-open got %.2f"
            % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
        )
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
        (
            "stamp_open_line: replaced window should have duration 3.0 got %.2f"
            % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
        )
    )
    _assert(
        is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0)), 0.7),
        failures,
        (
            "stamp_open_line: replaced window should carry the new parry mult got %.2f"
            % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, 0.0))
        )
    )

    # A LONGER re-open on the same line re-stamps fresh with the longer window.
    CombatGuardLines.stamp_open_line(c, "low", 5.0, 0.6)
    _assert(
        is_equal_approx(float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0)), 5.0),
        failures,
        (
            "stamp_open_line: longer re-open on same line should extend the window to 5.0 got %.2f"
            % float(c.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, 0.0))
        )
    )


## close_open_line_on_recover encodes the demonstrated re-coverage rule: a successful parry onto
## the defender's own open line clears the open-line window immediately (the "you're open here"
## state no longer holds). Pins the no-op cases (no live line, wrong line, expired) and the
## positive clear case so the parry/parry-partial call sites stay consistent.


static func run_close_open_line_on_recover_rules(failures: PackedStringArray) -> void:
    var c: Dictionary = {"id": 0}

    # No live open line -> no-op (nothing to clear).
    CombatGuardLines.close_open_line_on_recover(c, "high")
    _assert(not c.has(DataKeys.PA_FEINT_OPEN_LINE), failures, "close_open_line: should be a no-op when no line is open")

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
        (
            not c.has(DataKeys.PA_FEINT_OPEN_LINE)
            and not c.has(DataKeys.PA_FEINT_OPEN_LINE_UNTIL)
            and not c.has(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
            and not c.has(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT)
        ),
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
        not c.has(DataKeys.PA_FEINT_OPEN_LINE), failures, "shrink_open_line: should be a no-op when no line is open"
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
        (
            str(c.get(DataKeys.PA_FEINT_OPEN_LINE, "")) == "high"
            and c.has(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
            and c.has(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT)
        ),
        failures,
        "shrink_open_line: all four keys should be preserved after a partial re-coverage"
    )
    _assert(
        until_after < until_before and until_after > now,
        failures,
        (
            "shrink_open_line: until should move earlier but stay live (%.3f -> %.3f, now=%.3f)"
            % [until_before, until_after, now]
        )
    )
    _assert(
        open_after < open_before and open_after > 0.0,
        failures,
        "shrink_open_line: openness should drop but stay positive (%.3f -> %.3f)" % [open_before, open_after]
    )

## Off-balance attack damage: a fighter who is off-balance at the moment of impact deals reduced
## damage — compromised center of gravity weakens weight transfer. The multiplier is < 1.0 and
## symmetric with the defensive parry-capacity penalty (same value, same mechanic).
