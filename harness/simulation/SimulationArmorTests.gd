class_name SimulationArmorTests

extends SimulationCombatBase

## S1 Joule armour realism: KE conservation, cuirass vs gambeson absorption,
## authoritative KE fraction, floor clamp, complete-failure threshold,
## robustness edge cases, and cross-check against hand-tuned realism.


static func _run_sim_joule_armor_ke_conserved(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if cuirass == null:
        SimulationCombatTests._fail(failures, "sim_joule_ke: missing CUIRASS")
        return
    var strike_ke: float = 120.0
    var pen: float = 2.0
    var r: Dictionary = ArmorJouleBudget.account_ke_through_armor(cuirass, strike_ke, pen, true)
    var absorbed: float = float(r.get("armor_ke_absorbed_j", 0.0))
    var remaining: float = float(r.get("armor_ke_remaining_j", 0.0))
    if not is_equal_approx(absorbed + remaining, strike_ke):
        SimulationCombatTests._fail(
            failures, "sim_joule_ke: absorbed %.1f + remaining %.1f != strike %.1f" % [absorbed, remaining, strike_ke]
        )


## S6: plate kit bleeds less KE through than gambeson at same pen (sharp deflect path).


static func _run_sim_joule_armor_cuirass_absorbs_more_than_gambeson(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    var gambeson: ArmorPiece = HarnessFixtures.get_cached_armor("GAMBESON")
    if cuirass == null or gambeson == null:
        SimulationCombatTests._fail(failures, "sim_joule_armor: missing CUIRASS or GAMBESON")
        return
    var strike_ke: float = 100.0
    var pen: float = 2.0
    var heavy: Dictionary = ArmorJouleBudget.account_ke_through_armor(cuirass, strike_ke, pen, true)
    var light: Dictionary = ArmorJouleBudget.account_ke_through_armor(gambeson, strike_ke, pen, true)
    var rem_heavy: float = float(heavy.get("armor_ke_remaining_j", strike_ke))
    var rem_light: float = float(light.get("armor_ke_remaining_j", strike_ke))
    if rem_heavy >= rem_light - 0.5:
        SimulationCombatTests._fail(
            failures, "sim_joule_armor: cuirass remaining KE %.1f should be < gambeson %.1f" % [rem_heavy, rem_light]
        )


## S10: joule-authoritative path matches ke_frac ×  pre (no second scalar ArmorPiece pass).


static func _run_sim_joule_armor_authoritative_ke_frac(failures: PackedStringArray) -> void:
    var ent: CoreEntity = SimulationCombatBase._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    ent.endurance = 0
    var armor: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if armor == null:
        SimulationCombatTests._fail(failures, "sim_joule_authoritative: missing CUIRASS")
        return
    ent.equip_armor("chest", armor)
    var strike_ke: float = 90.0
    var cut_pre: float = 14.0
    var extras: Dictionary = {"strike_ke_j": strike_ke, "force_joule_armor_budget": true, "hit_sub_region": "thoracic"}
    var res: Dictionary = EntityDamage.apply_damage_split(ent, cut_pre, 0.0, "chest", 2.0, -1.0, -1.0, extras)
    var frac: float = float(res.get("transmitted_ke_fraction", -1.0))
    var mech: float = float(res.get("mechanical_post_armor", 0.0))
    var want_mech: float = cut_pre * frac
    if frac < 0.0:
        SimulationCombatTests._fail(failures, "sim_joule_authoritative: missing transmitted_ke_fraction on result")
    if want_mech > 0.01 and absf(mech - want_mech) > want_mech * 0.15:
        SimulationCombatTests._fail(
            failures, "sim_joule_authoritative: mech %.2f want cut*frac=%.2f (frac=%.3f)" % [mech, want_mech, frac]
        )
    if float(res.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
        SimulationCombatTests._fail(failures, "sim_joule_authoritative: want armor_ke_absorbed_j > 1 when forced")


## S10: joule path must not double-absorb below ke_frac floor (regression guard).


static func _run_sim_joule_armor_not_below_ke_frac_floor(failures: PackedStringArray) -> void:
    var armor: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if armor == null:
        SimulationCombatTests._fail(failures, "sim_joule_floor: missing CUIRASS")
        return
    var strike_ke: float = 90.0
    var cut_pre: float = 14.0
    var joule_ke: Dictionary = ArmorJouleBudget.account_ke_through_armor(armor, strike_ke, 2.0, true)
    var frac: float = float(joule_ke.get("transmitted_ke_fraction", 1.0))
    var ent: CoreEntity = SimulationCombatBase._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    ent.equip_armor("chest", armor)
    var res: Dictionary = EntityDamage.apply_damage_split(
        ent, cut_pre, 0.0, "chest", 2.0, -1.0, -1.0, {"strike_ke_j": strike_ke, "force_joule_armor_budget": true}
    )
    var mech: float = float(res.get("mechanical_post_armor", 0.0))
    var floor_mech: float = cut_pre * frac * 0.80
    if mech < floor_mech - 0.05:
        SimulationCombatTests._fail(
            failures,
            "sim_joule_floor: mech %.2f below ke_frac floor %.2f (double-absorb regression)" % [mech, floor_mech]
        )


## S10: armor complete failure — the blunt/thrust RHA read (get_effective_rha_with_degradation) is
## wear-aware: it delegates to the outer surviving layer's material-accurate value (the same source
## the sharp damage math uses). Pin: a fresh CUIRASS reports the plate outer layer's RHA, and once the
## outer plate layer is destroyed the reported value falls to the inner cloth layer's RHA.


static func _run_sim_armor_complete_failure_at_high_absorbed(failures: PackedStringArray) -> void:
    var armor: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if armor == null:
        SimulationCombatTests._fail(failures, "sim_armor_fail: missing CUIRASS")
        return
    var ent: CoreEntity = SimulationCombatBase._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    ent.equip_armor("chest", armor)
    var combatant: Dictionary = {DataKeys.COMBATANT_NODE: ent}
    var fresh_rha: float = CombatArmorDoctrine.get_effective_rha_with_degradation(combatant, "chest")
    var plate_rha: float = float(ArmorConstants.LAYER_PLATE[ArmorConstants.ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM])
    if absf(fresh_rha - plate_rha) > 0.01:
        SimulationCombatTests._fail(
            failures, "sim_armor_fail: fresh CUIRASS effective RHA want %.1f (plate) got %.2f" % [plate_rha, fresh_rha]
        )
    # Destroy the outer plate layer -> the effective RHA should fall through to the inner cloth layer.
    armor.layers[0][ArmorConstants.ARMOR_LAYER_KEY_DURABILITY] = 0.0
    var worn_rha: float = CombatArmorDoctrine.get_effective_rha_with_degradation(combatant, "chest")
    var cloth_rha: float = float(ArmorConstants.LAYER_CLOTH[ArmorConstants.ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM])
    if absf(worn_rha - cloth_rha) > 0.01:
        SimulationCombatTests._fail(
            failures, "sim_armor_fail: worn CUIRASS effective RHA want %.1f (cloth) got %.2f" % [cloth_rha, worn_rha]
        )


## S11: armor robustness edge cases + doctrine bounds. Pins the invariants that keep the
## wear-aware RHA read and the AI tier/gap doctrine from misbehaving on boundary inputs:
## all-destroyed pieces report 0 RHA and 0% condition; a worn-but-alive outer layer reports a
## strictly lower effective RHA than fresh; the mace bonus is monotonic non-decreasing and capped
## at its documented heavy-plate ceiling; and a bare fighter (no armor slots) classifies as "none".


static func _run_sim_armor_robustness_edge_cases(failures: PackedStringArray) -> void:
    # -- All layers destroyed -> 0 effective RHA and 0% condition --
    var dead_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if dead_piece == null:
        SimulationCombatTests._fail(failures, "sim_armor_rob: missing CUIRASS")
        return
    for layer in dead_piece.layers:
        layer[ArmorConstants.ARMOR_LAYER_KEY_DURABILITY] = 0.0
    if dead_piece.get_outer_layer_effective_rha_mm() > 0.01:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_armor_rob: destroyed piece should report ~0 effective RHA, got %.3f"
                % dead_piece.get_outer_layer_effective_rha_mm()
            )
        )
    if dead_piece.get_condition_pct() > 0.01:
        SimulationCombatTests._fail(
            failures, "sim_armor_rob: destroyed piece condition want 0 got %.2f" % dead_piece.get_condition_pct()
        )

    # -- Worn outer layer strictly lowers effective RHA vs fresh --
    var fresh: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    var worn: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    worn.layers[0][ArmorConstants.ARMOR_LAYER_KEY_DURABILITY] = 50.0
    var fresh_rha: float = fresh.get_outer_layer_effective_rha_mm()
    var worn_rha: float = worn.get_outer_layer_effective_rha_mm()
    if not (worn_rha < fresh_rha and worn_rha > 0.0):
        SimulationCombatTests._fail(
            failures, "sim_armor_rob: worn outer RHA (%.3f) must be < fresh (%.3f) and > 0" % [worn_rha, fresh_rha]
        )

    # -- Mace bonus is monotonic non-decreasing in target RHA and capped --
    var prev: float = -1.0
    var capped: bool = false
    for rha in [0.0, 2.0, 5.0, 8.0, 12.0, 16.0, 20.0, 40.0]:
        var m: float = CombatArmorDoctrine.mace_armor_interaction_multiplier(float(rha))
        if m < prev:
            SimulationCombatTests._fail(
                failures,
                "sim_armor_rob: mace multiplier not monotonic at rha=%s (%.3f after %.3f)" % [str(rha), m, prev]
            )
        if m > 1.78 + 0.001:
            SimulationCombatTests._fail(
                failures, "sim_armor_rob: mace multiplier %.3f exceeds heavy-plate cap 1.78" % m
            )
        if rha >= 16.0 and absf(m - 1.78) < 0.001:
            capped = true
        prev = m
    if not capped:
        SimulationCombatTests._fail(failures, "sim_armor_rob: mace multiplier should reach 1.78 cap at rha >= 16")

    # -- Bare fighter (no armor slots) classifies as "none" --
    var bare: CoreEntity = SimulationCombatBase._sim_entity()
    bare.species = HumanSpecies
    bare.apply_species()
    var bare_combatant: Dictionary = {DataKeys.COMBATANT_NODE: bare}
    if CombatArmorDoctrine.classify_tier(bare_combatant) != CombatArmorDoctrine.TIER_NONE:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_armor_rob: bare fighter should classify TIER_NONE, got %s"
                % CombatArmorDoctrine.classify_tier(bare_combatant)
            )
        )


## S12: armor realism cross-check. Pins the historically-plausible combat outcomes the layer
## values + wear model are meant to produce (see docs/ARMOR_VALUES_PHYSICS_RESEARCH.md):
##   - a committed sword cut and a committed spear thrust penetrate a fresh CUIRASS plate (a
##     real sharp edge gets through; this is the fresh-sharp-edge case, not a glancing blow),
##     and the cut depth stays within a realistic band (not absurdly deep);
##   - a full plate kit (chest/head/2 arms/2 legs) sits in the realistic 10-30 kg mass band;
##   - a committed cutting weapon eventually tears a CUIRASS fully — BOTH the plate and the
##     cloth layers fail in a finite number of hits, so a multi-layer piece can never fully
##     fail in the scalar path (regression guard for the penetrated-cut durability floor);
##   - a mace (the anti-plate weapon) transmits through a fresh plate layer at the 30-60%
##     HMIT band level (its area-coupling uses the true uncapped face, not the pressure cap),
##     and its doctrine multiplier reaches the documented heavy-plate cap.


static func _run_sim_armor_realism_cross_check(failures: PackedStringArray) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    var spear: Weapon = HarnessFixtures.get_cached_weapon("SPEAR")
    var mace: Weapon = HarnessFixtures.get_cached_weapon("MACE")
    var cuir: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if sword == null or spear == null or mace == null or cuir == null:
        SimulationCombatTests._fail(failures, "sim_armor_real: missing SWORD/SPEAR/MACE/CUIRASS")
        return
    var plate_layer: Dictionary = cuir.layers[0]
    var plate_rha: float = float(plate_layer.get(ArmorConstants.ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM, 0.0))

    # -- Penetration verdicts: committed sharp blows get through fresh plate --
    var cut_ai: AttackInstance = SimulationCombatBase._sim_attack("oberhau", 1.0, 0.9)
    var cut_pen: float = float(
        WeaponDamageHelper.compute_penetration(sword, cut_ai, WeaponConstants.DAMAGE_TYPE_SHARP).get(
            "penetration_sharp", 0.0
        )
    )
    var cut_res: Dictionary = ArmorPiece.sharp_penetration_math(cut_pen, plate_layer, 20.0)
    if plate_rha <= 0.0:
        SimulationCombatTests._fail(failures, "sim_armor_real: CUIRASS plate RHA should be > 0, got %.3f" % plate_rha)
    if cut_pen <= plate_rha:
        SimulationCombatTests._fail(
            failures,
            "sim_armor_real: committed sword cut (pen %.2f) must exceed plate RHA (%.2f)" % [cut_pen, plate_rha]
        )
    if cut_res.deflected:
        SimulationCombatTests._fail(
            failures,
            "sim_armor_real: committed sword cut (pen %.2f) must penetrate fresh plate, was deflected" % cut_pen
        )
    if cut_pen >= 9.0:
        SimulationCombatTests._fail(
            failures, "sim_armor_real: committed sword cut pen %.2f unrealistically deep (>= 9.0)" % cut_pen
        )
    var thrust_ai: AttackInstance = SimulationCombatBase._sim_attack("thrust", 1.0, 0.9)
    var spear_thrust_pen: float = float(
        WeaponDamageHelper.compute_penetration(spear, thrust_ai, WeaponConstants.DAMAGE_TYPE_SHARP).get(
            "penetration_sharp", 0.0
        )
    )
    var spear_thrust_res: Dictionary = ArmorPiece.sharp_penetration_math(spear_thrust_pen, plate_layer, 20.0)
    if not (spear_thrust_pen > plate_rha and not spear_thrust_res.deflected):
        SimulationCombatTests._fail(
            failures, "sim_armor_real: committed spear thrust (pen %.2f) must penetrate fresh plate" % spear_thrust_pen
        )

    # -- Full plate kit mass within a realistic band --
    var kit_ids: Array = [
        "CUIRASS", "KETTLE_HELM", "VAMBRACES_RIGHT", "VAMBRACES_LEFT", "GREAVES_RIGHT", "GREAVES_LEFT"
    ]
    var kit_mass: float = 0.0
    for pid in kit_ids:
        var piece: ArmorPiece = ArmorPiece.create_from_definition(String(pid))
        if piece == null:
            SimulationCombatTests._fail(failures, "sim_armor_real: missing armor piece %s" % str(pid))
            return
        kit_mass += piece.get_total_mass_kg()
    if not (kit_mass > 10.0 and kit_mass < 30.0):
        SimulationCombatTests._fail(
            failures, "sim_armor_real: full plate kit mass %.2f kg outside realistic (10-30)" % kit_mass
        )

    # -- Finite full failure: a committed cut tears BOTH layers (guards the penetrated-cut floor) --
    var target: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    var failed_at: int = -1
    for h in range(1, 601):
        target.apply_damage(20.0, WeaponConstants.DAMAGE_TYPE_SHARP, cut_pen)
        var dead: Array = target.destroyed_layer_indices()
        if 0 in dead and 1 in dead:
            failed_at = h
            break
    if failed_at < 0:
        SimulationCombatTests._fail(
            failures,
            "sim_armor_real: committed cut failed to destroy both CUIRASS layers in 600 hits (asymptote regression)"
        )

    # -- Mace (the anti-plate weapon) transmits through fresh plate at a historically-realistic level.
    #    The rigid-plate area-coupling term must use the weapon's TRUE (uncapped) contact face so a
    #    mace's broad head couples at full face size (docs/ARMOR_VALUES_PHYSICS_RESEARCH.md §8.2):
    #    HMIT drop-hammer data puts flat-plate mace/hammer transmission at 30-60% of impact energy.
    #    Pre-fix the pressure-channel face cap (BLUNT_HEAD_MAX_CONTACT_CM) leaked into the coupling,
    #    coupling the mace at only cap/reference and transmitting ~14% (too weak for the anti-plate role).
    var mace_ai: AttackInstance = SimulationCombatBase._sim_attack("direct_blow", 1.0, 0.9)
    var mace_pen: Dictionary = WeaponDamageHelper.compute_penetration(mace, mace_ai, WeaponConstants.DAMAGE_TYPE_BLUNT)
    var mace_mom: float = float(mace_pen.get("penetration_blunt_momentum_per_area", -1.0))
    var mace_contact: float = float(mace_pen.get("blunt_contact_cm", -1.0))
    var mace_coupling_contact: float = float(mace_pen.get("blunt_coupling_contact_cm", -1.0))
    if mace_mom <= 0.0 or mace_coupling_contact < mace_contact:
        SimulationCombatTests._fail(
            failures,
            (
                (
                    "sim_armor_real: mace must carry positive momentum/area (got %.0f) and an uncapped coupling face "
                    + "(coupling %.2f >= pressure contact %.2f)"
                )
                % [mace_mom, mace_coupling_contact, mace_contact]
            )
        )
    var mace_plate: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    var mace_plate_pre: float = ArmorPiece.blunt_transmission_math(100.0, mace_plate, mace_mom, mace_contact)
    var mace_plate_post: float = ArmorPiece.blunt_transmission_math(
        100.0, mace_plate, mace_mom, mace_contact, mace_coupling_contact
    )
    if mace_plate_post < mace_plate_pre:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_armor_real: uncapped coupling face must not reduce mace-plate transmission (post %.3f < pre %.3f)"
                % [mace_plate_post, mace_plate_pre]
            )
        )
    if mace_plate_post < 30.0:
        SimulationCombatTests._fail(
            failures,
            (
                (
                    "sim_armor_real: committed mace through fresh plate transmits %.1f%% (of 100), below the 30%% "
                    + "HMIT band floor — the mace is the anti-plate weapon and the area-coupling must use the true face"
                )
                % mace_plate_post
            )
        )
    if absf(CombatArmorDoctrine.mace_armor_interaction_multiplier(16.0) - 1.78) > 0.001:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_armor_real: mace doctrine multiplier at heavy plate (16) should be 1.78 cap, got %.3f"
                % CombatArmorDoctrine.mace_armor_interaction_multiplier(16.0)
            )
        )
