class_name CompanyChecksArmorWearTests

extends CompanyChecksCore

## XCamp-4n-4u/surgeon armor wear-detail checks: layer-fail trace, damage-type
## and joule wear, breakthrough crush, worn deflect, wear-curve shape, rate
## cliff, wear-aware RHA and surgeon hire + medical phase.


static func _run_xcamp_4m_armor_wear_fatigue(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.new()
    piece.body_part = "chest"
    var absorbed: float = 10.0
    var rate: float = float(ArmorConstants.LAYER_CLOTH["durability_loss_rate"])

    # Neutral rigidity (0.5) on both layers so the XCamp-4o damage-type wear modifier is
    # exactly 1.0 and the only variable is the fatigue multiplier.
    # Fresh layer (100%): fatigue multiplier is exactly 1.0 -> loss == absorbed * rate.
    var fresh_layer: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    fresh_layer["rigidity"] = 0.5
    fresh_layer["durability"] = 100.0
    fresh_layer["max_durability"] = 100.0
    piece._apply_durability_loss(fresh_layer, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var fresh_loss: float = 100.0 - float(fresh_layer["durability"])
    var expected_fresh: float = absorbed * rate
    if absf(fresh_loss - expected_fresh) > 0.001:
        _fail(failures, "fatigue4m: fresh loss want %.4f (no fatigue) got %s" % [expected_fresh, str(fresh_loss)])
    else:
        _pass()

    # Worn layer (50%): multiplier = 1 + ARMOR_WEAR_FATIGUE_MAX * 0.5 = 1.25 -> loss * 1.25.
    var worn_layer: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    worn_layer["rigidity"] = 0.5
    worn_layer["durability"] = 50.0
    worn_layer["max_durability"] = 100.0
    piece._apply_durability_loss(worn_layer, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var worn_loss: float = 50.0 - float(worn_layer["durability"])
    var expected_worn: float = absorbed * rate * 1.25
    if absf(worn_loss - expected_worn) > 0.001:
        _fail(failures, "fatigue4m: worn loss want %.4f (1.25x) got %s" % [expected_worn, str(worn_loss)])
    else:
        _pass()

    # Behavioral: at the same absorbed damage, the worn layer loses more durability.
    if not worn_loss > fresh_loss:
        _fail(failures, "fatigue4m: worn layer should wear faster, got %s <= %s" % [str(worn_loss), str(fresh_loss)])
    else:
        _pass()


## XCamp-4n: destroyed_layer_indices() drives the ARMOR_LAYER_FAIL combat trace.
## Pins the transition-detection logic: empty when fresh, exact index on partial
## failure, all indices when fully destroyed.


static func _run_xcamp_4n_armor_layer_fail_trace(failures: PackedStringArray) -> void:
    # CUIRASS = [plate (0), cloth (1)]
    var piece := ArmorPiece.create_from_definition("CUIRASS")
    if piece == null:
        _fail(failures, "layerfail4n: could not build CUIRASS")
        return

    # Fresh piece: no destroyed layers.
    var fresh_idx: Array = piece.destroyed_layer_indices()
    if fresh_idx.size() != 0:
        _fail(failures, "layerfail4n: fresh piece should have 0 destroyed layers, got %d" % fresh_idx.size())
    else:
        _pass()

    # Destroy only the outer (plate) layer -> exactly index 0.
    (piece.layers[0] as Dictionary)["durability"] = 0.0
    var partial_idx: Array = piece.destroyed_layer_indices()
    if partial_idx.size() != 1 or int(partial_idx[0]) != 0:
        _fail(failures, "layerfail4n: partial failure want [0], got %s" % str(partial_idx))
    else:
        _pass()

    # Destroy all layers -> indices == [0, 1].
    (piece.layers[1] as Dictionary)["durability"] = 0.0
    var all_idx: Array = piece.destroyed_layer_indices()
    if all_idx.size() != piece.layers.size():
        _fail(failures, "layerfail4n: all destroyed want %d, got %d" % [piece.layers.size(), all_idx.size()])
    else:
        _pass()


## XCamp-4o: damage-type-accurate wear. Two otherwise-identical synthetic layers differing only in
## rigidity: a flexible layer (rigidity 0.0) wears faster from cuts and slower from blunts; a
## rigid layer (rigidity 1.0) is the opposite. A neutral layer (rigidity 0.5) is unaffected.


static func _run_xcamp_4o_armor_damage_type_wear(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.new()
    piece.body_part = "chest"
    var absorbed: float = 10.0

    # Sharp: flexible (rigidity 0.0) should wear MORE than rigid (rigidity 1.0).
    var flex_cut: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    flex_cut["rigidity"] = 0.0
    flex_cut["durability_loss_rate"] = 0.1
    flex_cut["durability"] = 100.0
    flex_cut["max_durability"] = 100.0
    var rigid_cut: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    rigid_cut["rigidity"] = 1.0
    rigid_cut["durability_loss_rate"] = 0.1
    rigid_cut["durability"] = 100.0
    rigid_cut["max_durability"] = 100.0
    piece._apply_durability_loss(flex_cut, absorbed, ArmorConstants.DAMAGE_TYPE_SHARP)
    piece._apply_durability_loss(rigid_cut, absorbed, ArmorConstants.DAMAGE_TYPE_SHARP)
    var flex_cut_loss: float = 100.0 - float(flex_cut["durability"])
    var rigid_cut_loss: float = 100.0 - float(rigid_cut["durability"])
    if not flex_cut_loss > rigid_cut_loss:
        _fail(
            failures,
            (
                "damagetype4o: flexible should wear more from cuts, got flex=%s rigid=%s"
                % [str(flex_cut_loss), str(rigid_cut_loss)]
            )
        )
    else:
        _pass()

    # Blunt: rigid (rigidity 1.0) should wear MORE than flexible (rigidity 0.0).
    var flex_blunt: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    flex_blunt["rigidity"] = 0.0
    flex_blunt["durability_loss_rate"] = 0.1
    flex_blunt["durability"] = 100.0
    flex_blunt["max_durability"] = 100.0
    var rigid_blunt: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    rigid_blunt["rigidity"] = 1.0
    rigid_blunt["durability_loss_rate"] = 0.1
    rigid_blunt["durability"] = 100.0
    rigid_blunt["max_durability"] = 100.0
    piece._apply_durability_loss(flex_blunt, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    piece._apply_durability_loss(rigid_blunt, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var flex_blunt_loss: float = 100.0 - float(flex_blunt["durability"])
    var rigid_blunt_loss: float = 100.0 - float(rigid_blunt["durability"])
    if not rigid_blunt_loss > flex_blunt_loss:
        _fail(
            failures,
            (
                "damagetype4o: rigid should wear more from blunts, got flex=%s rigid=%s"
                % [str(flex_blunt_loss), str(rigid_blunt_loss)]
            )
        )
    else:
        _pass()

    # Neutral rigidity (0.5): modifier is exactly 1.0, so loss == absorbed * rate (bit-identical).
    var neutral: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    neutral["rigidity"] = 0.5
    neutral["durability_loss_rate"] = 0.1
    neutral["durability"] = 100.0
    neutral["max_durability"] = 100.0
    piece._apply_durability_loss(neutral, absorbed, ArmorConstants.DAMAGE_TYPE_SHARP)
    var neutral_loss: float = 100.0 - float(neutral["durability"])
    var expected_neutral: float = absorbed * 0.1
    if absf(neutral_loss - expected_neutral) > 0.001:
        _fail(failures, "damagetype4o: neutral rigidity loss want %.4f got %s" % [expected_neutral, str(neutral_loss)])
    else:
        _pass()


## XCamp-4p: the authoritative joule wear path (apply_joule_durability_loss) now applies the same
## damage-type modifier as the scalar path (4o). Pins: flexible sharp > flexible blunt (the type
## split is live in the joule path), and neutral rigidity (0.5) is bit-identical to the pre-4p
## joule rate (absorbed * rate * JOULE_KE_DURABILITY_SCALE) — so the invariant holds.


static func _run_xcamp_4p_armor_joule_wear_consistency(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.new()
    piece.body_part = "chest"
    var absorbed_j: float = 10.0
    var rate: float = 0.1
    var scale: float = ArmorConstants.JOULE_KE_DURABILITY_SCALE
    var baseline: float = absorbed_j * rate * scale  # 0.5

    # Flexible layer (rigidity 0.0), SHARP: type_mult 1.15 -> loss = baseline * 1.15.
    var flex_sharp: Dictionary = {
        "rigidity": 0.0,
        "durability_loss_rate": rate,
        "durability": 100.0,
        "max_durability": 100.0,
    }
    piece.apply_joule_durability_loss(flex_sharp, absorbed_j, ArmorConstants.DAMAGE_TYPE_SHARP)
    var flex_sharp_loss: float = 100.0 - float(flex_sharp["durability"])
    if absf(flex_sharp_loss - baseline * 1.15) > 0.001:
        _fail(failures, "joulewear4p: flex sharp want %.4f got %s" % [baseline * 1.15, str(flex_sharp_loss)])
    else:
        _pass()

    # Flexible layer, BLUNT: type_mult 0.85 -> less wear than the sharp case.
    var flex_blunt: Dictionary = {
        "rigidity": 0.0,
        "durability_loss_rate": rate,
        "durability": 100.0,
        "max_durability": 100.0,
    }
    piece.apply_joule_durability_loss(flex_blunt, absorbed_j, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var flex_blunt_loss: float = 100.0 - float(flex_blunt["durability"])
    if not flex_sharp_loss > flex_blunt_loss:
        _fail(
            failures,
            (
                "joulewear4p: flex sharp should wear more than flex blunt, got %s vs %s"
                % [str(flex_sharp_loss), str(flex_blunt_loss)]
            )
        )
    else:
        _pass()

    # Neutral rigidity (0.5): bit-identical to the pre-4p joule rate (no type modifier).
    var neutral: Dictionary = {
        "rigidity": 0.5,
        "durability_loss_rate": rate,
        "durability": 100.0,
        "max_durability": 100.0,
    }
    piece.apply_joule_durability_loss(neutral, absorbed_j, ArmorConstants.DAMAGE_TYPE_SHARP)
    var neutral_loss: float = 100.0 - float(neutral["durability"])
    if absf(neutral_loss - baseline) > 0.001:
        _fail(failures, "joulewear4p: neutral want %.4f (pre-4p bit-identical) got %s" % [baseline, str(neutral_loss)])
    else:
        _pass()


## XCamp-4q: breakthrough crush — when a layer is destroyed, the next surviving inner layer
## takes a one-time extra durability hit. Pins the three invariants: it wears the inner layer,
## zero absorbed energy is a no-op, and no surviving inner layer is a safe no-op.


static func _run_xcamp_4q_armor_breakthrough_crush(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.create_from_definition("CUIRASS")
    if piece == null or piece.layers.size() < 2:
        _fail(failures, "crush4q: need a 2-layer CUIRASS")
        return
    var inner: Dictionary = piece.layers[1]
    var inner_before: float = float(inner.get("durability", 100.0))

    # A broken outer layer should shock the inner layer (its durability drops).
    piece.apply_breakthrough_crush(0, 10.0, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var inner_after: float = float(inner.get("durability", 100.0))
    if not inner_after < inner_before:
        _fail(
            failures,
            (
                "crush4q: inner layer should wear on breakthrough, before=%s after=%s"
                % [str(inner_before), str(inner_after)]
            )
        )
    else:
        _pass()

    # No-op: zero absorbed energy leaves the inner layer unchanged.
    var before_noop: float = float(inner.get("durability", 100.0))
    piece.apply_breakthrough_crush(0, 0.0, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var after_noop: float = float(inner.get("durability", 100.0))
    if absf(after_noop - before_noop) > 0.0001:
        _fail(
            failures,
            "crush4q: zero absorbed should be a no-op, before=%s after=%s" % [str(before_noop), str(after_noop)]
        )
    else:
        _pass()

    # No surviving inner layer: all layers destroyed -> safe no-op, inner stays 0.
    var piece2 := ArmorPiece.create_from_definition("CUIRASS")
    (piece2.layers[0] as Dictionary)["durability"] = 0.0
    (piece2.layers[1] as Dictionary)["durability"] = 0.0
    piece2.apply_breakthrough_crush(0, 10.0, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var inner2: float = float((piece2.layers[1] as Dictionary).get("durability", 0.0))
    if inner2 != 0.0:
        _fail(failures, "crush4q: no surviving inner layer should stay 0, got %s" % str(inner2))
    else:
        _pass()


## XCamp-4r: worn deflection. A worn layer's deflected transmission rises with wear (a dented
## surface no longer presents a clean bevel), so a stopped cut channels more through as shock.
## White-box: drives sharp_penetration_math with pen_rha = 0 so the deflection branch is
## isolated (proximity = 0 -> transmission equals the base value exactly).


static func _run_xcamp_4r_armor_worn_deflect(failures: PackedStringArray) -> void:
    var base_tx: float = float(ArmorConstants.LAYER_PLATE["sharp_deflect_transmission"])

    # Fresh plate: deflected transmission == base (bit-identical to pre-4r).
    var fresh: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    fresh["durability"] = 100.0
    fresh["max_durability"] = 100.0
    var fresh_res: Dictionary = ArmorPiece.sharp_penetration_math(0.0, fresh, 10.0)
    var fresh_tx: float = float(fresh_res["damage"]) / 10.0
    if absf(fresh_tx - base_tx) > 0.001:
        _fail(failures, "deflect4r: fresh transmission want %.4f got %s" % [base_tx, str(fresh_tx)])
    else:
        _pass()

    # Worn plate (50%): prot=0.5; 4s convex wear_frac = 1—pow(0.5, exp). Transmission rises
    # above fresh (a dented bevel leaks more) but the convex curve keeps it below the old linear value.
    var worn: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    worn["durability"] = 50.0
    worn["max_durability"] = 100.0
    var worn_res: Dictionary = ArmorPiece.sharp_penetration_math(0.0, worn, 10.0)
    var worn_tx: float = float(worn_res["damage"]) / 10.0
    var penalty: float = ArmorConstants.ARMOR_WEAR_DEFLECT_PENALTY
    var curve_exp: float = ArmorConstants.ARMOR_WEAR_CURVE_EXPONENT
    var wear_frac: float = 1.0 - pow(0.5, curve_exp)
    var expected_worn: float = base_tx * (1.0 + penalty * wear_frac)
    if absf(worn_tx - expected_worn) > 0.001:
        _fail(failures, "deflect4r: worn transmission want %.4f got %s" % [expected_worn, str(worn_tx)])
    else:
        _pass()
    if not worn_tx > fresh_tx:
        _fail(failures, "deflect4r: worn transmission %s should exceed fresh %s" % [str(worn_tx), str(fresh_tx)])
    else:
        _pass()


## XCamp-4s: non-linear (cliff-edge) deflection wear. The 4r wear_frac is shaped convexly
## (1—pow(prot, exp), exp < 1), so a worn bevel stays clean through most of a layer's life
## and the deflected transmission degrades sharply only near failure. Pins, white-box via
## pen_rha = 0 (proximity 0 -> deflected transmission equals the base value exactly):
##   (1) fresh = base exactly (bit-identical, no penalty);
##   (2) destroyed = full transmission 1.0 (a 0% layer drops to sharp_res 0, so even a
##       glancing cut penetrates — the 4i full-penetration invariant, a separate path from
##       the 4r deflection penalty);
##   (3) monotonic: more wear -> more transmitted;
##   (4) convex: the increment accelerates as the layer nears failure
##       (the 75->50 jump < the 50->25 jump), which a linear curve would not show.


static func _run_xcamp_4s_wear_curve_shape(failures: PackedStringArray) -> void:
    var base_tx: float = float(ArmorConstants.LAYER_PLATE["sharp_deflect_transmission"])
    var penalty: float = ArmorConstants.ARMOR_WEAR_DEFLECT_PENALTY

    var l100: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l100["durability"] = 100.0
    l100["max_durability"] = 100.0
    var l75: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l75["durability"] = 75.0
    l75["max_durability"] = 100.0
    var l50: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l50["durability"] = 50.0
    l50["max_durability"] = 100.0
    var l25: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l25["durability"] = 25.0
    l25["max_durability"] = 100.0
    var l0: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l0["durability"] = 0.0
    l0["max_durability"] = 100.0

    var tx_fresh: float = float(ArmorPiece.sharp_penetration_math(0.0, l100, 10.0)["damage"]) / 10.0
    var tx_75: float = float(ArmorPiece.sharp_penetration_math(0.0, l75, 10.0)["damage"]) / 10.0
    var tx_50: float = float(ArmorPiece.sharp_penetration_math(0.0, l50, 10.0)["damage"]) / 10.0
    var tx_25: float = float(ArmorPiece.sharp_penetration_math(0.0, l25, 10.0)["damage"]) / 10.0
    var tx_dead: float = float(ArmorPiece.sharp_penetration_math(0.0, l0, 10.0)["damage"]) / 10.0

    # (1) Fresh: no penalty -> transmission == base exactly.
    if absf(tx_fresh - base_tx) > 0.001:
        _fail(failures, "curve4s: fresh transmission want %.4f got %s" % [base_tx, str(tx_fresh)])
    else:
        _pass()

    # (2) Destroyed: a 0% layer drops to sharp_res 0, so even pen=0 fully penetrates.
    if absf(tx_dead - 1.0) > 0.001:
        _fail(failures, "curve4s: destroyed transmission want 1.0 got %s" % str(tx_dead))
    else:
        _pass()

    # (3) Monotonic: more wear -> more transmitted.
    if not (tx_fresh < tx_75 and tx_75 < tx_50 and tx_50 < tx_25 and tx_25 < tx_dead):
        _fail(
            failures,
            (
                "curve4s: want monotonic fresh<75<50<25<dead, got %s/%s/%s/%s/%s"
                % [str(tx_fresh), str(tx_75), str(tx_50), str(tx_25), str(tx_dead)]
            )
        )
    else:
        _pass()

    # (4) Convex: the increment accelerates as the layer nears failure. A linear curve
    # would give equal 75->50 and 50->25 jumps; the convex curve makes the lower jump larger.
    var jump_hi: float = tx_50 - tx_75
    var jump_lo: float = tx_25 - tx_50
    if not jump_lo > jump_hi:
        _fail(
            failures, "curve4s: want accelerating degradation (jump_lo %s > jump_hi %s)" % [str(jump_lo), str(jump_hi)]
        )
    else:
        _pass()


## XCamp-4t: fatigue cliff — wear rate accelerates in the final 25% of a layer's life.
## Pins: (1) below threshold the cliff factor is exactly 1.0 (4m unchanged),
## (2) at full wear the cliff reaches 1 + CLIFF_MAX,
## (3) the cliff is monotonic (higher wear -> higher multiplier),
## (4) the 4m pin at 50% is preserved (total fatigue still 1.25 with default constants).


static func _run_xcamp_4t_wear_rate_cliff(failures: PackedStringArray) -> void:
    var threshold: float = ArmorConstants.ARMOR_WEAR_FATIGUE_CLIFF_THRESHOLD
    var cliff_max: float = ArmorConstants.ARMOR_WEAR_FATIGUE_CLIFF_MAX

    # (1) Below threshold: cliff is exactly 1.0 (no effect on 4m behaviour).
    var below: float = ArmorPiece._wear_fatigue_cliff(50.0, 100.0)  # wear_frac = 0.5
    if absf(below - 1.0) > 0.0001:
        _fail(failures, "cliff4t: below threshold want 1.0 got %s" % str(below))
    else:
        _pass()

    var at_threshold: float = ArmorPiece._wear_fatigue_cliff(25.0, 100.0)  # wear_frac = 0.75
    if absf(at_threshold - 1.0) > 0.0001:
        _fail(failures, "cliff4t: at threshold want 1.0 got %s" % str(at_threshold))
    else:
        _pass()

    # (2) At full wear (wear_frac = 1.0): cliff = 1.0 + CLIFF_MAX.
    var full_wear: float = ArmorPiece._wear_fatigue_cliff(0.0, 100.0)
    var expected_full: float = 1.0 + cliff_max
    if absf(full_wear - expected_full) > 0.0001:
        _fail(failures, "cliff4t: full wear want %.4f got %s" % [expected_full, str(full_wear)])
    else:
        _pass()

    # (3) Monotonic: cliff at 10% durability > cliff at 24% durability > cliff at 25% durability.
    var c_10: float = ArmorPiece._wear_fatigue_cliff(10.0, 100.0)  # wear_frac 0.90
    var c_24: float = ArmorPiece._wear_fatigue_cliff(24.0, 100.0)  # wear_frac 0.76
    var c_25: float = ArmorPiece._wear_fatigue_cliff(25.0, 100.0)  # wear_frac 0.75 (at threshold)
    if not (c_10 > c_24 and c_24 > c_25):
        _fail(failures, "cliff4t: want monotonic 10%%>24%%>25%%, got %s/%s/%s" % [str(c_10), str(c_24), str(c_25)])
    else:
        _pass()

    # (4) 4m pin preserved: at 50% durability the total fatigue multiplier is still 1.25
    #     (base fatigue 1.25 * cliff 1.0 = 1.25, since 0.5 <= threshold).
    var base_fatigue: float = ArmorPiece._wear_fatigue_multiplier(50.0, 100.0)
    var cliff_at_50: float = ArmorPiece._wear_fatigue_cliff(50.0, 100.0)
    var total: float = base_fatigue * cliff_at_50
    if absf(total - 1.25) > 0.001:
        _fail(failures, "cliff4t: 4m pin broken, total fatigue at 50%% want 1.25 got %s" % str(total))
    else:
        _pass()


## XCamp-4u: out-of-math consumers (AI doctrine tier, gap-finding, mace bonus) now see the same
## wear-scaled RHA the damage path uses, not the base design value. Pins, white-box on the
## CUIRASS piece (outer = plate 3.5mm / rigidity 1.0, inner = cloth 0.9mm):
##   (1) fresh armor effective == base (bit-identical, no wear);
##   (2) a worn outer layer's effective RHA drops below base and matches the 4k formula
##       (base * pow(prot, 1—rigidity*shield), prot=0.5 -> base * pow(0.5, 0.4));
##   (3) a destroyed outer layer falls through to the next surviving layer's effective RHA;
##   (4) monotonic: more wear -> lower effective RHA (fresh > 75 > 50 > 25).


static func _run_xcamp_4u_wear_aware_rha(failures: PackedStringArray) -> void:
    var base_plate: float = float(ArmorConstants.LAYER_PLATE["sharp_resistance_rha_mm"])  # 3.5
    var base_cloth: float = float(ArmorConstants.LAYER_CLOTH["sharp_resistance_rha_mm"])  # 0.9
    var shield: float = ArmorConstants.ARMOR_WEAR_RIGIDITY_SHIELD

    # (1) Fresh cuirass (outer = plate): effective == base, bit-identical.
    var fresh_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if fresh_piece == null:
        _fail(failures, "wearrha4u: could not build CUIRASS")
        return
    var fresh_eff: float = fresh_piece.get_outer_layer_effective_rha_mm()
    if absf(fresh_eff - base_plate) > 0.001:
        _fail(failures, "wearrha4u: fresh effective want %.3f got %s" % [base_plate, str(fresh_eff)])
    else:
        _pass()

    # (2) Worn outer plate (50% durability): effective < base and matches the 4k formula.
    var worn_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (worn_piece.layers[0] as Dictionary)["durability"] = 50.0
    var worn_eff: float = worn_piece.get_outer_layer_effective_rha_mm()
    var exp: float = clampf(1.0 - 1.0 * shield, 0.1, 1.0)  # plate rigidity 1.0 -> 0.4
    var expected_worn: float = base_plate * pow(0.5, exp)
    if absf(worn_eff - expected_worn) > 0.001:
        _fail(failures, "wearrha4u: worn 50%% effective want %.4f got %s" % [expected_worn, str(worn_eff)])
    else:
        _pass()
    if not worn_eff < fresh_eff:
        _fail(failures, "wearrha4u: worn %s should be < fresh %s" % [str(worn_eff), str(fresh_eff)])
    else:
        _pass()

    # (3) Destroyed outer plate: fall through to inner cloth layer's effective RHA.
    var dead_outer: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (dead_outer.layers[0] as Dictionary)["durability"] = 0.0
    var cloth_eff: float = dead_outer.get_outer_layer_effective_rha_mm()
    if absf(cloth_eff - base_cloth) > 0.001:
        _fail(failures, "wearrha4u: destroyed outer want inner cloth %.3f got %s" % [base_cloth, str(cloth_eff)])
    else:
        _pass()

    # (4) Monotonic: effective RHA strictly decreases as durability falls.
    var m75: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (m75.layers[0] as Dictionary)["durability"] = 75.0
    var m25: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (m25.layers[0] as Dictionary)["durability"] = 25.0
    var eff_75: float = m75.get_outer_layer_effective_rha_mm()
    var eff_25: float = m25.get_outer_layer_effective_rha_mm()
    if not (fresh_eff > eff_75 and eff_75 > worn_eff and worn_eff > eff_25):
        _fail(
            failures,
            "wearrha4u: want monotonic %s>%s>%s>%s" % [str(fresh_eff), str(eff_75), str(worn_eff), str(eff_25)]
        )
    else:
        _pass()


## XSurgeon: medical-staff hire end-to-end — flat cost, "surgeon" role tag + pool name, one-surgeon
## rule, exclusion from fightable party nodes, P2 persistence roundtrip of the role tag, and the
## CombatManager medical-phase registration that unlocks full TCCC.


static func _run_xsurgeon_hire_and_medical_phase(failures: PackedStringArray) -> void:
    # --- Hire: cost, role, pool name, one-surgeon rule ---
    var world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world)
    CompanyState.set_renown(world, 0)
    var cost: int = CompanyState.surgeon_hire_cost()
    if cost <= 0:
        _fail(failures, "XSurgeon: surgeon_hire_cost must be positive, got " + str(cost))
    else:
        _pass()
    CompanyState.set_gold(world, 300)
    var rng := RandomNumberGenerator.new()
    rng.seed = 11
    var hired: bool = CompanyState.try_hire_surgeon(world, rng, true)
    if not hired:
        _fail(failures, "XSurgeon: hire surgeon on a renown-0 leader party should succeed")
    else:
        _pass()
    if CompanyState.get_gold(world) != 300 - cost:
        _fail(failures, "XSurgeon: gold after hire want %d got %d" % [300 - cost, CompanyState.get_gold(world)])
    else:
        _pass()
    var surgeon: Node = CompanyState.find_living_surgeon(world)
    if surgeon == null:
        _fail(failures, "XSurgeon: find_living_surgeon should resolve the hired surgeon")
    else:
        _pass()
    var surgeon_ent: Node = CampaignEncounterBridge.health_entity_from_character(surgeon)
    if surgeon_ent == null or str(surgeon_ent.get("fighter_role")) != PlayerCompanionSetup.SURGEON_ROLE:
        _fail(failures, "XSurgeon: hired surgeon entity should carry fighter_role='surgeon'")
    else:
        _pass()
    var sname: String = PlayerCompanionSetup.resolve_fighter_display_name(surgeon)
    if sname.is_empty() or not PlayerCompanionSetup.SURGEON_NAMES.has(sname):
        _fail(failures, "XSurgeon: surgeon display name '%s' should come from the surgeon pool" % sname)
    else:
        _pass()
    if not CompanyState.has_surgeon(world):
        _fail(failures, "XSurgeon: has_surgeon should be true after hiring")
    else:
        _pass()
    CompanyState.set_gold(world, 900)
    if CompanyState.try_hire_surgeon(world, rng, true):
        _fail(failures, "XSurgeon: a second surgeon hire must be refused (one-surgeon rule)")
    else:
        _pass()
    # --- Lineup exclusion: surgeon never enters fightable party nodes ---
    var fighters: Array = CampaignEncounterBridge.get_fightable_party_nodes(world)
    var surgeon_leaked: bool = false
    for f in fighters:
        if f == surgeon:
            surgeon_leaked = true
            break
    if surgeon_leaked:
        _fail(failures, "XSurgeon: surgeon must be excluded from fightable party nodes")
    else:
        _pass()
    if fighters.is_empty():
        _fail(failures, "XSurgeon: the leader should still be fightable alongside the surgeon")
    else:
        _pass()
    # --- CombatManager medical-phase registration (surgeon becomes a player-side combatant) ---
    var mgr: CombatManager = CombatManager.new()
    mgr.register_surgeon(surgeon)
    mgr.call("_register_surgeon_for_medical_phase")
    if not mgr.is_surgeon_present:
        _fail(failures, "XSurgeon: medical-phase registration should set is_surgeon_present")
    else:
        _pass()
    if not mgr.is_surgeon_combatant(int(mgr._surgeon_combatant_id)):
        _fail(failures, "XSurgeon: the designated surgeon cid should be is_surgeon_combatant")
    else:
        _pass()
    if mgr.is_surgeon_combatant(9999):
        _fail(failures, "XSurgeon: an unrelated cid must not be the surgeon")
    else:
        _pass()
    mgr.free()
    _release_harness_world(world)

    # --- P2 roundtrip: fighter_role survives save/load/apply ---
    CampaignPersistence.clear_slot()
    var round_world: Node2D = _instantiate_main_hire_world(true)
    var round_comp: Node = round_world.get_node_or_null("Character/Companion")
    var round_ent: Node = CampaignEncounterBridge.health_entity_from_character(round_comp)
    if round_ent == null:
        _fail(failures, "XSurgeon P2: could not resolve companion entity")
        CampaignPersistence.clear_slot()
        _release_harness_world(round_world)
        return
    round_ent.fighter_role = PlayerCompanionSetup.SURGEON_ROLE
    round_ent.fighter_name = "Galen"
    if not CampaignPersistence.save_slot(round_world):
        _fail(failures, "XSurgeon P2: save_slot failed")
        CampaignPersistence.clear_slot()
        _release_harness_world(round_world)
        return
    _pass()
    var loaded: Dictionary = CampaignPersistence.load_save()
    if not CampaignPersistence.is_valid_save(loaded):
        _fail(failures, "XSurgeon P2: loaded save should be valid")
        CampaignPersistence.clear_slot()
        _release_harness_world(round_world)
        return
    _pass()
    var fresh: Node2D = _instantiate_main_hire_world(true)
    var rng2 := RandomNumberGenerator.new()
    rng2.seed = 99
    CampaignPersistence.apply_save(fresh, loaded, rng2, null)
    var f_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        fresh.get_node_or_null("Character/Companion")
    )
    if f_ent == null or str(f_ent.get("fighter_role")) != PlayerCompanionSetup.SURGEON_ROLE:
        _fail(failures, "XSurgeon P2: fighter_role should survive roundtrip")
    else:
        _pass()
    if str(f_ent.get("fighter_name")) != "Galen":
        _fail(failures, "XSurgeon P2: surgeon fighter_name should survive roundtrip")
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _release_harness_world(round_world)
    _release_harness_world(fresh)

    # --- P3: separate slot -- a full fighter roster can still hire a surgeon; it does not
    # consume a companion slot, does not raise the living-roster count (wages/food/cap),
    # and lives on the dedicated Character/Surgeon node ---
    var full_world: Node2D = _instantiate_main_hire_world(true)
    var full_count: int = CompanyState.count_living_roster(full_world)
    if full_count != CompanyState.ROSTER_MAX_LIVING:
        _fail(
            failures,
            (
                "XSurgeon P3: fresh roster should be at fighter capacity %d, got %d"
                % [CompanyState.ROSTER_MAX_LIVING, full_count]
            )
        )
    else:
        _pass()
    if CompanyState.roster_has_hire_room(full_world):
        _fail(failures, "XSurgeon P3: a full fighter roster should have no fighter hire room")
    else:
        _pass()
    CompanyState.set_gold(full_world, 300)
    var full_rng := RandomNumberGenerator.new()
    full_rng.seed = 3
    if not CompanyState.try_hire_surgeon(full_world, full_rng, true):
        _fail(failures, "XSurgeon P3: surgeon hire must succeed on a full fighter roster (separate slot)")
    else:
        _pass()
    var full_surgeon: Node = CompanyState.find_living_surgeon(full_world)
    if full_surgeon == null:
        _fail(failures, "XSurgeon P3: find_living_surgeon should resolve on a full roster")
    elif str(full_surgeon.name) != "Surgeon":
        _fail(
            failures,
            "XSurgeon P3: surgeon should live on the dedicated 'Surgeon' node, got '%s'" % str(full_surgeon.name)
        )
    else:
        _pass()
    var count_after: int = CompanyState.count_living_roster(full_world)
    if count_after != full_count:
        _fail(
            failures,
            "XSurgeon P3: surgeon must not raise the living-roster count (want %d got %d)" % [full_count, count_after]
        )
    else:
        _pass()
    if CompanyState.roster_has_hire_room(full_world):
        _fail(failures, "XSurgeon P3: hiring a surgeon must not free a fighter slot (roster still full)")
    else:
        _pass()
    _release_harness_world(full_world)

    # --- P4: dedicated-slot save/load roundtrip ---
    CampaignPersistence.clear_slot()
    var r_world: Node2D = _instantiate_main_hire_world(true)
    CompanyState.set_gold(r_world, 300)
    var r_rng := RandomNumberGenerator.new()
    r_rng.seed = 77
    if not CompanyState.try_hire_surgeon(r_world, r_rng, true):
        _fail(failures, "XSurgeon P4: hire surgeon should succeed")
        CampaignPersistence.clear_slot()
        _release_harness_world(r_world)
        return
    _pass()
    var r_node: Node = CompanyState.find_living_surgeon(r_world)
    var r_ent: Node = CampaignEncounterBridge.health_entity_from_character(r_node)
    var r_name: String = str(r_ent.get("fighter_name")) if r_ent != null else ""
    if r_ent == null or str(r_ent.get("fighter_role")) != PlayerCompanionSetup.SURGEON_ROLE:
        _fail(failures, "XSurgeon P4: hired surgeon should carry the role tag before save")
        CampaignPersistence.clear_slot()
        _release_harness_world(r_world)
        return
    _pass()
    if not CampaignPersistence.save_slot(r_world):
        _fail(failures, "XSurgeon P4: save_slot failed")
        CampaignPersistence.clear_slot()
        _release_harness_world(r_world)
        return
    _pass()
    var r_loaded: Dictionary = CampaignPersistence.load_save()
    var r_fresh: Node2D = _instantiate_main_hire_world(true)
    var r_rng2 := RandomNumberGenerator.new()
    r_rng2.seed = 55
    CampaignPersistence.apply_save(r_fresh, r_loaded, r_rng2, null)
    var r_restored: Node = CompanyState.find_living_surgeon(r_fresh)
    if r_restored == null:
        _fail(failures, "XSurgeon P4: find_living_surgeon should resolve after save/load (dedicated slot restore)")
    else:
        _pass()
    var r_r_ent: Node = CampaignEncounterBridge.health_entity_from_character(r_restored) if r_restored != null else null
    if r_r_ent == null or str(r_r_ent.get("fighter_role")) != PlayerCompanionSetup.SURGEON_ROLE:
        _fail(failures, "XSurgeon P4: fighter_role should survive the roundtrip on the dedicated slot")
    elif str(r_r_ent.get("fighter_name")) != r_name:
        _fail(
            failures,
            (
                "XSurgeon P4: fighter_name should survive the roundtrip (want '%s' got '%s')"
                % [r_name, str(r_r_ent.get("fighter_name"))]
            )
        )
    else:
        _pass()
    if r_restored != null and str(r_restored.name) != "Surgeon":
        _fail(
            failures,
            "XSurgeon P4: restored surgeon should live on the dedicated 'Surgeon' node, got '%s'" % str(r_restored.name)
        )
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _release_harness_world(r_world)
    _release_harness_world(r_fresh)
