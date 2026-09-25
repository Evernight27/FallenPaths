class_name Tier1EncounterGapTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_encounter_formation_doctrine_on_start(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  probing  "
    mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY] = "hold"
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        _fail(
            failures,
            (
                "encounter_doctrine_start: player want %s got %s"
                % [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
            )
        )
    if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures,
            (
                "encounter_doctrine_start: enemy want %s got %s"
                % [CombatConstants.DOCTRINE_HOLD_LANE, mgr.get_formation_doctrine("enemy")]
            )
        )
    HarnessFixtures._free_manager(mgr)
    var mgr2: Node = CombatManager.new()
    mgr2.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  \t  "
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if mgr2.get_formation_doctrine("player") != CombatConstants.DOCTRINE_DEFAULT:
        _fail(
            failures,
            (
                "encounter_doctrine_start: whitespace-only encounter value should keep default got %s"
                % mgr2.get_formation_doctrine("player")
            )
        )
    HarnessFixtures._free_manager(mgr2)
    var mgr3: Node = CombatManager.new()
    mgr3.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
    var pdoc: Dictionary = {"files": 1, "ranks": 1, CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "hold_lane"}
    mgr3.register(_new_entity("SWORD"), "player")
    mgr3.register(_new_entity("SWORD"), "enemy")
    mgr3.start(pdoc, {"files": 1, "ranks": 1})
    if mgr3.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures,
            (
                "preset_doctrine_start: player preset should override encounter probing got %s"
                % mgr3.get_formation_doctrine("player")
            )
        )
    HarnessFixtures._free_manager(mgr3)
    var mgr4: Node = CombatManager.new()
    mgr4.register(_new_entity("SWORD"), "player")
    mgr4.register(_new_entity("SWORD"), "enemy")
    var edoc: Dictionary = {"files": 1, "ranks": 1, CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "pinch"}
    mgr4.start({"files": 1, "ranks": 1}, edoc)
    if mgr4.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(
            failures,
            (
                "preset_doctrine_start: enemy preset pinch alias want pinch_center got %s"
                % mgr4.get_formation_doctrine("enemy")
            )
        )
    HarnessFixtures._free_manager(mgr4)
    var mgr5: Node = CombatManager.new()
    mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "probing"
    mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT] = "hold"
    mgr5.register(_new_entity("SWORD"), "player")
    mgr5.register(_new_entity("SWORD"), "enemy")
    mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if mgr5.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        _fail(
            failures,
            "encounter_doctrine_alt: player doctrine_player want probing got %s" % mgr5.get_formation_doctrine("player")
        )
    if mgr5.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures,
            "encounter_doctrine_alt: enemy doctrine_enemy want hold_lane got %s" % mgr5.get_formation_doctrine("enemy")
        )
    HarnessFixtures._free_manager(mgr5)
    var mgr6: Node = CombatManager.new()
    mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
    mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "hold_lane"
    mgr6.register(_new_entity("SWORD"), "player")
    mgr6.register(_new_entity("SWORD"), "enemy")
    mgr6.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if mgr6.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        _fail(
            failures,
            (
                "encounter_doctrine_alt: canonical formation_doctrine_player should win over doctrine_player got %s"
                % mgr6.get_formation_doctrine("player")
            )
        )
    HarnessFixtures._free_manager(mgr6)
    var mgr7: Node = CombatManager.new()
    mgr7.register(_new_entity("SWORD"), "player")
    mgr7.register(_new_entity("SWORD"), "enemy")
    var p7: Dictionary = {
        "files": 1,
        "ranks": 1,
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold",
    }
    mgr7.start(p7, {"files": 1, "ranks": 1})
    if mgr7.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures,
            (
                "preset_doctrine_alt: player preset `doctrine` only want hold_lane got %s"
                % mgr7.get_formation_doctrine("player")
            )
        )
    HarnessFixtures._free_manager(mgr7)
    var mgr8: Node = CombatManager.new()
    mgr8.register(_new_entity("SWORD"), "player")
    mgr8.register(_new_entity("SWORD"), "enemy")
    var p8: Dictionary = {
        "files": 1,
        "ranks": 1,
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
    }
    mgr8.start(p8, {"files": 1, "ranks": 1})
    if mgr8.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        _fail(
            failures,
            (
                "preset_doctrine_alt: canonical formation_doctrine on preset should win over doctrine got %s"
                % mgr8.get_formation_doctrine("player")
            )
        )
    HarnessFixtures._free_manager(mgr8)


## Tier 1.9: **`CombatConstants.encounter_formation_doctrine_string`** / **`formation_doctrine_string_from_dict`** match
## **`CombatManager.start()`** read order.


## Tier 1.9: **`CombatConstants.encounter_formation_doctrine_string`** / **`formation_doctrine_string_from_dict`** match
## **`CombatManager.start()`** read order.
static func _run_encounter_formation_doctrine_string_helper(failures: PackedStringArray) -> void:
    var enc_alt: Dictionary = {
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "",
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "  hold  ",
    }
    var got_alt: String = CombatConstants.encounter_formation_doctrine_string(
        enc_alt,
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
    )
    if got_alt != "hold":
        _fail(
            failures, "encounter_doctrine_string: empty canonical should use alt got %s" % got_alt
        )
    var enc_canon: Dictionary = {
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "probing",
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "hold_lane",
    }
    var got_canon: String = CombatConstants.encounter_formation_doctrine_string(
        enc_canon,
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
    )
    if got_canon != "probing":
        _fail(
            failures, "encounter_doctrine_string: canonical should win over alt got %s" % got_canon
        )
    var enc_ws: Dictionary = {CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "  \t  "}
    var got_ws: String = CombatConstants.encounter_formation_doctrine_string(
        enc_ws,
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
    )
    if not got_ws.is_empty():
        _fail(
            failures,
            "encounter_doctrine_string: whitespace-only canonical should fall through to empty got %s" % got_ws
        )
    var preset_alt_only: Dictionary = {
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "  hold  ",
    }
    var got_preset_alt: String = CombatConstants.formation_doctrine_string_from_dict(
        preset_alt_only,
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
    )
    if got_preset_alt != "hold":
        _fail(
            failures, "formation_doctrine_string_from_dict: preset alt-only want hold got %s" % got_preset_alt
        )
    var preset_both: Dictionary = {
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
        CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
    }
    var got_preset_canon: String = CombatConstants.formation_doctrine_string_from_dict(
        preset_both, CombatConstants.FORMATION_PRESET_KEY_DOCTRINE, CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
    )
    if got_preset_canon != "probing":
        _fail(
            failures, "formation_doctrine_string_from_dict: preset canonical should win got %s" % got_preset_canon
        )


## Pair moves cancel any queued `swap_rank_resolve` touching either combatant before scheduling a fresh resolve.


static func _run_gap1_axe_overhead_chop_head_weight_clamp(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("AXE"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var atk: Dictionary = mgr.combatants[0]
    var enm: Dictionary = mgr.combatants[1]
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    for c in mgr.combatants:
        if c is Dictionary:
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_BALANCED, "harness_gap1")
    var move_def: Dictionary = WeaponConstants.get_move("overhead_chop")
    var attack_line: String = move_def.get("attack_line", "high")
    var guard_line: String = enm.get("guard_line", CombatConstants.GUARD_DEFAULT)
    var targetable: Array = CombatantEntityAccess.get_targetable_parts(enm)
    if targetable.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var segment: Array = AttackPathResolver.path_segment_for_strike(attack_line, guard_line, targetable, 0.9, {})
    if segment.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var weights: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment, attack_line, move_def, atk, enm, CombatantEntityAccess.id_int(atk), "overhead_chop", true
    )
    var head_w: float = weights.get("head", 1.0)
    var anatomy_head: float = BodyPartConstants.BODY_PART_TARGET_WEIGHTS.get("head", 1.2)
    var max_allowed: float = anatomy_head * AttackPathResolver.MAX_PRE_INT_WEIGHT_MULT * 1.5
    if head_w > max_allowed + 0.01:
        _fail(
            failures,
            (
                "gap1_axe_overhead_chop_head: weight %.4f exceeds cap %.4f (anatomy %.2f × 1.5 × preferred 1.5)"
                % [head_w, max_allowed, anatomy_head]
            )
        )
    HarnessFixtures._free_manager(mgr)


## Gap 3: spear depth gating must protect legs during diagonal attacks (diagonal variance path should not re-introduce
## legs excluded by depth).


## Gap 3: spear depth gating must protect legs during diagonal attacks (diagonal variance path should not re-introduce
## legs excluded by depth).
static func _run_gap3_spear_diagonal_depth_gate(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var atk: Dictionary = mgr.combatants[1]
    var enm: Dictionary = mgr.combatants[2]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, atk):
        _fail(failures, "gap3_spear_diagonal_depth: expected depth lane open")
        HarnessFixtures._free_manager(mgr)
        return
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    for c in mgr.combatants:
        if c is Dictionary:
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_BALANCED, "harness_gap3")
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    if CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, atk):
        _fail(
            failures, "gap3_spear_diagonal_depth: expected strict+tight+no wedge to block low targets"
        )
        HarnessFixtures._free_manager(mgr)
        return
    var targetable: Array = CombatantEntityAccess.get_targetable_parts(enm)
    if targetable.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var filtered: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, atk, targetable)
    if filtered.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var has_legs: bool = false
    for p in filtered:
        if p == BodyPartConstants.PART_LEFT_LEG or p == BodyPartConstants.PART_RIGHT_LEG:
            has_legs = true
            break
    if has_legs:
        _fail(
            failures,
            (
                "gap3_spear_diagonal_depth: depth_polearm_targetable_parts_filter should exclude legs when depth bl"
                + "ocks low (got %s)" % str(filtered)
            )
        )
        HarnessFixtures._free_manager(mgr)
        return
    # Production flow: pre-filtered targetable (no legs) + diagonal oberhau -> no leg weights
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var attack_line: String = move_def.get("attack_line", "high")
    var guard_line: String = enm.get("guard_line", CombatConstants.GUARD_DEFAULT)
    var segment: Array = AttackPathResolver.path_segment_for_strike(attack_line, guard_line, filtered, 0.9, {})
    if segment.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var weights: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment,
        attack_line,
        move_def,
        atk,
        enm,
        CombatantEntityAccess.id_int(atk),
        "oberhau",
        false,
        filtered,
        guard_line,
        0.9,
        {}
    )
    for p in weights.keys():
        if p == BodyPartConstants.PART_LEFT_LEG or p == BodyPartConstants.PART_RIGHT_LEG:
            _fail(
                failures,
                (
                    "gap3_spear_diagonal_depth: diagonal oberhau should not distribute weight to legs with pre-filt"
                    + "ered targetable (got %s)" % str(weights.keys())
                )
            )
            break
    HarnessFixtures._free_manager(mgr)


static func _run_gap6_diagonal_variance_distribution(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var atk: Dictionary = mgr.combatants[0]
    var enm: Dictionary = mgr.combatants[1]
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    for c in mgr.combatants:
        if c is Dictionary:
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_BALANCED, "harness_gap6")
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var attack_line: String = move_def.get("attack_line", "high")
    enm["guard_line"] = "high"
    var targetable: Array = CombatantEntityAccess.get_targetable_parts(enm)
    if targetable.is_empty():
        targetable = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
    var segment: Array = AttackPathResolver.path_segment_for_strike(attack_line, "high", targetable, 0.9, {})
    if segment.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var weights: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment,
        attack_line,
        move_def,
        atk,
        enm,
        CombatantEntityAccess.id_int(atk),
        "oberhau",
        true,
        targetable,
        "high",
        0.9,
        {}
    )
    var has_nonhigh: bool = false
    for p in weights.keys():
        if not p.begins_with("right_arm") and not p.begins_with("left_arm") and p != "head" and p != "chest":
            has_nonhigh = true
            break
    if not has_nonhigh:
        _fail(
            failures,
            (
                "gap6_oberhau_high_guard: diagonal variance should distribute weight beyond declared line parts (go"
                + "t %s)" % str(weights.keys())
            )
        )
    HarnessFixtures._free_manager(mgr)


## Gap 7: wounded-vitals exploit (`FEATURE_WOUNDED_VITALS_EXPLOIT`) presses a defender's already-damaged head/chest in
## both the AI part-pick weights and the hit-resolution weights.

static func _run_gap7_wounded_vitals_exploit(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_WOUNDED_VITALS_EXPLOIT:
        return
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("AXE"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var atk: Dictionary = mgr.combatants[0]
    var enm: Dictionary = mgr.combatants[1]
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    for c in mgr.combatants:
        if c is Dictionary:
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_BALANCED, "harness_gap7")
    var def_ent: CoreEntity = CombatantEntityAccess.scene_entity(enm)
    if def_ent == null:
        HarnessFixtures._free_manager(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("overhead_chop")
    var attack_line: String = move_def.get("attack_line", "high")
    enm["guard_line"] = "high"
    var targetable: Array = CombatantEntityAccess.get_targetable_parts(enm)
    if targetable.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var segment: Array = AttackPathResolver.path_segment_for_strike(attack_line, "high", targetable, 0.9, {})
    if not segment.has(BodyPartConstants.PART_HEAD):
        HarnessFixtures._free_manager(mgr)
        return
    var weights_base: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment, attack_line, move_def, atk, enm, CombatantEntityAccess.id_int(atk), "overhead_chop", true
    )
    var head_base: float = weights_base.get(BodyPartConstants.PART_HEAD, 0.0)
    var chest_base: float = weights_base.get(BodyPartConstants.PART_CHEST, 0.0)
    var mult_pristine: float = AttackPathResolver._wounded_vitals_part_mult(enm, BodyPartConstants.PART_HEAD)
    if absf(mult_pristine - 1.0) > 0.001:
        _fail(
            failures, "gap7_wounded_vitals: pristine head mult want 1.0 got %.3f" % mult_pristine
        )
    # Pristine resolution distribution (seeded; each resolve draws one randf).
    var seeds: Array = [101, 202, 303, 404, 505, 606, 707, 808, 909, 1011, 1112, 1213, 1314, 1415, 1516, 1617, 1718, 1819, 1920, 2021]
    var pristine_head: int = 0
    for s in seeds:
        seed(int(s))
        if (
            AttackPathResolver.resolve_hit_part(
                attack_line, "high", targetable, {}, "", enm, {}, atk, move_def, true
            )
            == BodyPartConstants.PART_HEAD
        ):
            pristine_head += 1
    # Damage the defender's head to ~50% tissue remaining (destroyed 0.5 > ramp 0.35 -> top mult).
    var head_max: int = def_ent.body_max.get(BodyPartConstants.PART_HEAD, 1)
    def_ent.body_cutting[BodyPartConstants.PART_HEAD] = float(head_max) * 0.5
    def_ent.body_blunt[BodyPartConstants.PART_HEAD] = float(head_max) * 0.5
    var mult_wounded: float = AttackPathResolver._wounded_vitals_part_mult(enm, BodyPartConstants.PART_HEAD)
    if absf(mult_wounded - AttackPathResolver.WOUNDED_VITAL_TOP_MULT) > 0.001:
        _fail(
            failures,
            "gap7_wounded_vitals: wounded head mult want %.2f got %.3f"
            % [AttackPathResolver.WOUNDED_VITAL_TOP_MULT, mult_wounded]
        )
    var mult_arm: float = AttackPathResolver._wounded_vitals_part_mult(enm, BodyPartConstants.PART_LEFT_ARM)
    if mult_arm != 1.0:
        _fail(
            failures, "gap7_wounded_vitals: non-vital part mult must stay 1.0 got %.3f" % mult_arm
        )
    var weights_wounded: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment, attack_line, move_def, atk, enm, CombatantEntityAccess.id_int(atk), "overhead_chop", true
    )
    var head_wounded: float = weights_wounded.get(BodyPartConstants.PART_HEAD, 0.0)
    if head_wounded <= head_base * 1.7:
        _fail(
            failures,
            "gap7_wounded_vitals: AI pick head weight should jump ~%.2fx on wounded head (base %.4f got %.4f)"
            % [AttackPathResolver.WOUNDED_VITAL_TOP_MULT, head_base, head_wounded]
        )
    if segment.has(BodyPartConstants.PART_CHEST) and chest_base > 0.0:
        var chest_wounded: float = weights_wounded.get(BodyPartConstants.PART_CHEST, 0.0)
        if absf(chest_wounded - chest_base) > 0.001:
            _fail(
                failures,
                "gap7_wounded_vitals: pristine chest weight must be unchanged (base %.4f got %.4f)"
                % [chest_base, chest_wounded]
            )
    var wounded_head: int = 0
    for s in seeds:
        seed(int(s))
        if (
            AttackPathResolver.resolve_hit_part(
                attack_line, "high", targetable, {}, "", enm, {}, atk, move_def, true
            )
            == BodyPartConstants.PART_HEAD
        ):
            wounded_head += 1
    if wounded_head <= pristine_head:
        _fail(
            failures,
            "gap7_wounded_vitals: wounded head picks %d should exceed pristine %d" % [wounded_head, pristine_head]
        )
    HarnessFixtures._free_manager(mgr)


## XCamp-6 (gladiator): school-fighter tendency hook — aggression/parry multipliers + target-part boost.
static func _run_xcamp6_school_tendency_hook(failures: PackedStringArray) -> void:
    # Aggression multiplier: absent -> 1.0, 0.0 -> 0.75, 0.5 -> 1.0, 1.0 -> 1.25
    if absf(CombatConstantsAIWeights.school_tendency_aggression_mult({}) - 1.0) > 0.001:
        _fail(failures, "xcamp6_tendency: no-tendency aggression mult should be 1.0")
    if absf(CombatConstantsAIWeights.school_tendency_aggression_mult({"school_tendency": {"aggression": 1.0}}) - 1.25) > 0.001:
        _fail(failures, "xcamp6_tendency: aggression=1.0 should give 1.25x, got %f" % CombatConstantsAIWeights.school_tendency_aggression_mult({"school_tendency": {"aggression": 1.0}}))
    if absf(CombatConstantsAIWeights.school_tendency_aggression_mult({"school_tendency": {"aggression": 0.0}}) - 0.75) > 0.001:
        _fail(failures, "xcamp6_tendency: aggression=0.0 should give 0.75x, got %f" % CombatConstantsAIWeights.school_tendency_aggression_mult({"school_tendency": {"aggression": 0.0}}))
    if absf(CombatConstantsAIWeights.school_tendency_aggression_mult({"school_tendency": {"aggression": 0.5}}) - 1.0) > 0.001:
        _fail(failures, "xcamp6_tendency: aggression=0.5 should give 1.0x (midpoint)")
    # Parry multiplier: absent -> 1.0, 0.0 -> 0.80, 1.0 -> 1.30
    if absf(CombatConstantsAIWeights.school_tendency_parry_mult({}) - 1.0) > 0.001:
        _fail(failures, "xcamp6_tendency: no-tendency parry mult should be 1.0")
    if absf(CombatConstantsAIWeights.school_tendency_parry_mult({"school_tendency": {"parry_bias": 1.0}}) - 1.30) > 0.001:
        _fail(failures, "xcamp6_tendency: parry_bias=1.0 should give 1.30x, got %f" % CombatConstantsAIWeights.school_tendency_parry_mult({"school_tendency": {"parry_bias": 1.0}}))
    if absf(CombatConstantsAIWeights.school_tendency_parry_mult({"school_tendency": {"parry_bias": 0.0}}) - 0.80) > 0.001:
        _fail(failures, "xcamp6_tendency: parry_bias=0.0 should give 0.80x, got %f" % CombatConstantsAIWeights.school_tendency_parry_mult({"school_tendency": {"parry_bias": 0.0}}))
    # Plumbing: node meta -> combatant dict copy in register() (the seam
    # CompanyMatch.stamp_bout_enemy depends on), and the key survives start()'s
    # clear loop. A non-school node (no meta) must NOT gain the key.
    var mgr_plumb: Node = CombatManager.new()
    var ent_school: Node = _new_entity("SWORD")
    ent_school.set_meta("school_tendency", {"aggression": 1.0, "parry_bias": 0.0})
    mgr_plumb.register(_new_entity("SWORD"), "player")
    var id_school: int = mgr_plumb.register(ent_school, "enemy")
    mgr_plumb.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c_school: Dictionary = mgr_plumb.combatants[id_school]
    var c_plain: Dictionary = mgr_plumb.combatants[0]
    if not c_school.has("school_tendency"):
        _fail(failures, "xcamp6_tendency: register should copy the school_tendency node meta onto the combatant dict")
    elif absf(float(c_school["school_tendency"].get("aggression", -1.0)) - 1.0) > 0.001:
        _fail(failures, "xcamp6_tendency: copied tendency should keep its values (aggression 1.0)")
    elif absf(CombatConstantsAIWeights.school_tendency_aggression_mult(c_school) - 1.25) > 0.001:
        _fail(failures, "xcamp6_tendency: aggression mult should read 1.25 from the combatant dict")
    elif absf(CombatConstantsAIWeights.school_tendency_parry_mult(c_school) - 0.80) > 0.001:
        _fail(failures, "xcamp6_tendency: parry mult should read 0.80 from the combatant dict")
    if c_plain.has("school_tendency"):
        _fail(failures, "xcamp6_tendency: a node without the meta must not gain school_tendency on its combatant dict")
    elif CombatConstantsAIWeights.school_tendency_aggression_mult(c_plain) != 1.0:
        _fail(failures, "xcamp6_tendency: meta-less combatant should read a neutral 1.0 aggression mult")
    HarnessFixtures._free_manager(mgr_plumb)
    # Target-part boost: the favored part should get a >= 1.4x weight boost (1.5x before any blending).
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var enm: Dictionary = mgr.combatants[1]
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    for c in mgr.combatants:
        if c is Dictionary:
            CombatWeaponForm.assign_form(mgr, c as Dictionary, CombatWeaponForm.FORM_BALANCED, "xcamp6_tend")
    var move_def: Dictionary = WeaponConstants.get_move("overhead_chop")
    var atk_line: String = move_def.get("attack_line", "high")
    var guard_line: String = enm.get("guard_line", CombatConstants.GUARD_DEFAULT)
    var targetable: Array = CombatantEntityAccess.get_targetable_parts(enm)
    var segment: Array = AttackPathResolver.path_segment_for_strike(atk_line, guard_line, targetable, 0.9, {})
    if segment.is_empty():
        HarnessFixtures._free_manager(mgr)
        return
    var head_part: String = BodyPartConstants.PART_HEAD
    if not segment.has(head_part):
        HarnessFixtures._free_manager(mgr)
        return
    var weights_base: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment, atk_line, move_def, atk, enm, CombatantEntityAccess.id_int(atk), "overhead_chop", true
    )
    var head_base: float = weights_base.get(head_part, 0.0)
    if head_base <= 0.0:
        HarnessFixtures._free_manager(mgr)
        return
    atk["school_tendency"] = {"target_part": head_part}
    var weights_tend: Dictionary = AttackPathResolver.part_weights_for_ai_pick(
        segment, atk_line, move_def, atk, enm, CombatantEntityAccess.id_int(atk), "overhead_chop", true
    )
    var head_tend: float = weights_tend.get(head_part, 0.0)
    if head_tend < head_base * 1.4:
        _fail(
            failures,
            "xcamp6_tendency: target_part boost expected >=1.4x head weight (base=%.4f got=%.4f)"
            % [head_base, head_tend]
        )
    HarnessFixtures._free_manager(mgr)
