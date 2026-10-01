class_name MeisterhauCounterIntentTests

extends RefCounted

## A2: Meisterhäue counter-intent scaling — decisive counter-strikes scale form_counter_mult by yomi confidence.
## Also tests meisterhau_readthrough feint defense mod on schielhau read-through threshold.
const HarnessCore := preload("res://harness/regression/core/CombatRegressionHarnessCore.gd")

const CombatConstants := preload("res://combat/CombatConstants.gd")

const CombatManager := preload("res://combat/CombatManager.gd")

const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")

const CombatWeaponForm := preload("res://combat/weapon_form/CombatWeaponForm.gd")

const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")

const WeaponConstants := preload("res://resources/weapons/WeaponConstants.gd")

const WeaponFormDefs := preload("res://combat/weapon_form/CombatWeaponFormDefsShared.gd")

const SwordFormDefs := preload("res://combat/weapon_form/CombatWeaponFormDefsSword.gd")

static var _mgr_ref: Node = null


static func run_meisterhau_family_mapping(failures: PackedStringArray) -> void:
    # Meisterhau IDs get "meisterhau" family; oberhau gets "high_cut".
    _assert(
        CombatWeaponForm._move_family_for_move_id("zornhau") == "meisterhau",
        failures,
        "meisterhau_family: zornhau -> meisterhau"
    )
    _assert(
        CombatWeaponForm._move_family_for_move_id("scheitelhau") == "meisterhau",
        failures,
        "meisterhau_family: scheitelhau -> meisterhau"
    )
    _assert(
        CombatWeaponForm._move_family_for_move_id("krumphau") == "meisterhau",
        failures,
        "meisterhau_family: krumphau -> meisterhau"
    )
    ## Schielhau is a feint — its family is "feint" (caught by is_feint_move before meisterhau list).
    _assert(
        CombatWeaponForm._move_family_for_move_id("schielhau") == "feint",
        failures,
        "meisterhau_family: schielhau -> feint (not meisterhau)"
    )
    _assert(
        CombatWeaponForm._move_family_for_move_id("oberhau") == "high_cut",
        failures,
        "meisterhau_family: oberhau should stay high_cut (not meisterhau)"
    )


static func run_meisterhau_scale_factor_is_sub_one(failures: PackedStringArray) -> void:
    # The A2 constant must be < 1.0 so that meisterhau counter bonuses are reduced
    # when yomi confidence is low (defender hasn't committed to reading attacker intent).
    var scale_factor: float = CombatConstants.A2_MEISTERHAU_CONFIDENCE_SCALE_FACTOR
    _assert(
        scale_factor < 1.0,
        failures,
        "meisterhau_scale: A2_MEISTERHAU_CONFIDENCE_SCALE_FACTOR must be < 1.0 got %.2f" % scale_factor
    )


static func run_meisterhau_counter_mult_no_crash_with_inferred_form(failures: PackedStringArray) -> void:
    var mgr = _make_1v1_sword()
    var def = mgr.combatants[0]
    var atk = mgr.combatants[1]
    # Wall counters wrath with [parry, feint] families. Zornhau is "meisterhau" family — not in families → returns 1.0.
    _set_form(mgr, def, "wall")
    _set_form(mgr, atk, "wrath")
    var cache: Dictionary = {}
    cache[str(CombatantEntityAccess.id_int(atk))] = "wrath"
    def[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = cache
    # Should not crash and should return 1.0 (no family match).
    var mh_mult: float = CombatWeaponForm.form_counter_mult("wall", "wrath", "zornhau")
    _assert(
        mh_mult == 1.0,
        failures,
        "meisterhau_counter: wall vs wrath zornhau should return 1.0 (no family match) got %.4f" % mh_mult
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


static func run_oberhau_vs_meisterhau_family_distinction(failures: PackedStringArray) -> void:
    # Verify oberhau stays "high_cut" family while zornhau is "meisterhau".
    var oh_family = CombatWeaponForm._move_family_for_move_id("oberhau")
    var zh_family = CombatWeaponForm._move_family_for_move_id("zornhau")
    _assert(
        oh_family != zh_family,
        failures,
        "meisterhau_distinct: oberhau (%s) should differ from zornhau (%s)" % [oh_family, zh_family]
    )
    # Plow counters wrath with [thrust, high_cut] families. Oberhau (high_cut) matches → counter bonus.
    # Zornhau (meisterhau) does NOT match → no bonus.
    var mgr = _make_1v1_sword()
    var def_c: Dictionary = {}
    var opp_c: Dictionary = {}
    for c in mgr.combatants:
        if c is Dictionary:
            if def_c.is_empty():
                def_c = c as Dictionary
            else:
                opp_c = c as Dictionary
    CombatWeaponForm.assign_form(mgr, def_c, "plow", "harness_baseline")
    CombatWeaponForm.assign_form(mgr, opp_c, "wrath", "harness_baseline")
    var plow_vs_wrath_oberhau: float = CombatWeaponForm.form_counter_mult("plow", "wrath", "oberhau")
    var plow_vs_wrath_zornhau: float = CombatWeaponForm.form_counter_mult("plow", "wrath", "zornhau")
    _assert(
        plow_vs_wrath_oberhau >= 1.0,
        failures,
        "meisterhau_distinct: plow vs wrath oberhau should get counter bonus got %.4f" % plow_vs_wrath_oberhau
    )
    _assert(
        plow_vs_wrath_zornhau == 1.0,
        failures,
        (
            (
                "meisterhau_distinct: plow vs wrath zornhau should NOT get counter bonus (meisterhau != "
                + "thrust/high_cut) "
                + "got %.4f"
            )
            % plow_vs_wrath_zornhau
        )
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


static func run_meisterhau_move_definitions_exist(failures: PackedStringArray) -> void:
    for mid in ["zornhau", "scheitelhau", "krumphau", "schielhau"]:
        var md = WeaponConstants.get_move(mid)
        _assert(not md.is_empty(), failures, "meisterhau_defs: %s should exist in move definitions" % mid)
    # zornhau is overhead archetype (not feint).
    var zorn = WeaponConstants.get_move("zornhau")
    _assert(not zorn.get("is_feint", false), failures, "meisterhau_defs: zornhau should NOT be a feint")
    # schielhau IS a feint (peeking cut).
    var schiel = WeaponConstants.get_move("schielhau")
    _assert(schiel.get("is_feint", false), failures, "meisterhau_defs: schielhau should be a feint")


static func run_meisterhau_readthrough_in_neutral_mod(failures: PackedStringArray) -> void:
    var neutral = WeaponFormDefs._neutral_mod()
    _assert("meisterhau_readthrough" in neutral, failures, "meisterhau_readthrough should be in _neutral_mod()")
    _assert(neutral["meisterhau_readthrough"] == 1.0, failures, "meisterhau_readthrough default should be 1.0")


static func run_meisterhau_readthrough_wall_has_bonus(failures: PackedStringArray) -> void:
    var sword_forms = SwordFormDefs._sword_forms()
    var wall_mods = sword_forms["wall"].get("mod", {})
    _assert(
        wall_mods.get("meisterhau_readthrough", 1.0) > 1.0,
        failures,
        (
            "meisterhau_rt: wall should have > 1.0 meisterhau_readthrough bonus got %.2f"
            % wall_mods.get("meisterhau_readthrough", 1.0)
        )
    )


static func _assert(cond: bool, failures: PackedStringArray, msg: String) -> void:
    if not cond:
        failures.append(msg)


# -- Helpers ---------------------------------------------------------------


static func _make_1v1_sword() -> Node:
    var mgr := CombatManager.new()
    var e1 = HarnessFixtures._new_entity("SWORD")
    var e2 = HarnessFixtures._new_entity("SWORD")
    mgr.register(e1, "player")
    mgr.register(e2, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    HarnessFixtures._harness_reset_combatants_form_balanced(mgr)
    _mgr_ref = mgr
    return mgr


static func _set_form(mgr: Node, c: Dictionary, form: String) -> void:
    CombatWeaponForm.assign_form(mgr, c, form, "harness_baseline")
