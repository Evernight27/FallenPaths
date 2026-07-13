class_name CombatRegressionHarnessPartM
extends CombatRegressionHarnessPartL

## Tier 0.2: formation move gauge shows vulnerable suffix while swapping / falling back.


static func _run_formation_hit_cancel_ui_gauge_vulnerable_suffix(failures: PackedStringArray) -> void:
    var c: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_SWAP_RANK,
        "state_timer": 0.0,
        "state_duration": 2.0,
        "gauge": 50.0,
    }
    var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c)
    if "vulnerable" not in label:
        _fail(failures, "form_hit_ui: swap gauge want vulnerable suffix got %s" % label)
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c)
    var found: bool = false
    for line in tips:
        if "Formation move" in str(line) and "cancel" in str(line):
            found = true
            break
    if not found:
        _fail(failures, "form_hit_ui: gauge tooltip should mention hit cancel risk")


## Camp-3.2: party menu triage line uses ATLS band + danger ETA from bleed physics.


## Camp-3.2: party menu triage line uses ATLS band + danger ETA from bleed physics.
static func _run_party_row_triage_formatter(failures: PackedStringArray) -> void:
    var blood: float = 70.0
    var bleed: float = 0.35
    var line: String = _PartyRowFormatter.format_triage_line(blood, bleed)
    if "ATLS" not in line:
        _fail(failures, "party_triage: want ATLS band label in %s" % line)
    var cls: int = _Bleeding.atls_hemorrhage_class_from_remaining_pct(blood)
    var class_token: String = "Class %d" % cls
    var roman: String = ["", "I", "II", "III", "IV"][cls] if cls >= 1 and cls <= 4 else ""
    if class_token not in line and (roman.is_empty() or ("Class %s" % roman) not in line):
        _fail(failures, "party_triage: want ATLS class for blood=%.0f got %s" % [blood, line])
    var eta_s: float = _PartyRowFormatter.seconds_to_danger_band(blood, bleed)
    if eta_s <= 0.0 or eta_s == INF:
        _fail(failures, "party_triage: want finite ETA to danger got %.2f" % eta_s)
    if "danger" not in line:
        _fail(failures, "party_triage: want danger ETA text in %s" % line)
    var at_danger: String = _PartyRowFormatter.format_triage_line(
        _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING - 1.0, bleed
    )
    if "at danger" not in at_danger:
        _fail(failures, "party_triage: below danger threshold should read at danger got %s" % at_danger)
    var calm: String = _PartyRowFormatter.format_triage_line(95.0, 0.0)
    if "ATLS" not in calm or "Bleeding" in calm:
        _fail(failures, "party_triage: zero bleed should omit bleed/ETA got %s" % calm)


## Campaign bridge: untreated wound detection on **`CoreEntity`**.


## Campaign bridge: untreated wound detection on **`CoreEntity`**.
static func _run_campaign_bridge_entity_untreated_wounds(failures: PackedStringArray) -> void:
    var ent: CoreEntity = _new_entity("SWORD")
    ent.take_damage_split(8.0, 2.0, "left_arm", 0.5, 0.5)
    if not _CampaignBridge.entity_has_untreated_wounds(ent):
        _fail(failures, "campaign_bridge: fresh wound should count as untreated")
    ent.apply_direct_pressure("left_arm")
    if ent._can_apply_bandage("left_arm") and ent._apply_bandage("left_arm"):
        if _CampaignBridge.entity_has_untreated_wounds(ent):
            _fail(failures, "campaign_bridge: bandaged wound should not be untreated")
    var packed: CoreEntity = _new_entity("SWORD")
    packed.take_damage_split(6.0, 1.0, "head", 0.5, 0.5)
    packed.packed_parts["head"] = true
    if _CampaignBridge.entity_has_untreated_wounds(packed):
        _fail(failures, "campaign_bridge: packed part should not count as untreated")
    var tq: CoreEntity = _new_entity("SWORD")
    tq.take_damage_split(6.0, 1.0, "left_leg", 0.5, 0.5)
    tq.tourniquet_applied["left_leg"] = {"effectiveness": 1.0}
    if _CampaignBridge.entity_has_untreated_wounds(tq):
        _fail(failures, "campaign_bridge: tourniqueted part should not count as untreated")
    _free_harness_node(ent)
    _free_harness_node(packed)
    _free_harness_node(tq)


## Campaign bridge: encounter node exports -> world meta.


## Campaign bridge: encounter node exports -> world meta.
static func _run_campaign_bridge_encounter_meta_from_node(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var enc: Node = _EncounterNode.new()
    enc.encounter_config = {
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM: "  wrath  ",
    }
    enc.enemy_count = 2
    _CampaignBridge.prepare_combat_from_encounter(world, enc)
    var got: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    if (
        str(got.get(CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
        != CombatConstants.DOCTRINE_PINCH_CENTER
    ):
        _fail(failures, "campaign_bridge: encounter_config not copied to world meta")
    if str(got.get(CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM, "")) != "wrath":
        _fail(failures, "campaign_bridge: enemy_default_weapon_form not copied/stripped to world meta")
    var ef: Dictionary = world.get_meta("enemy_formation", {})
    if int(ef.get("files", 0)) < 1:
        _fail(failures, "campaign_bridge: enemy_formation meta missing files")
    enc.free()
    world.free()


## Tier 1.10: **`CombatFormationEngagement.recompute_all`** runs automatic doctrine evaluation.


## Tier 1.10: **`CombatFormationEngagement.recompute_all`** runs automatic doctrine evaluation.
static func _run_automatic_doctrine_pinch_via_formation_recompute(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        _fail(failures, "auto_doc_recompute: FEATURE_AUTOMATIC_DOCTRINE should be enabled")
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
    var en_by_file: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_enemy_side(c):
            continue
        en_by_file[_EntityAccess.file_int(c)] = c
    (en_by_file[1] as Dictionary)["alive"] = false
    _FormationEngagement.recompute_all(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(failures, "auto_doc_recompute: want pinch_center got %s" % mgr.get_formation_doctrine("player"))
    _free_manager(mgr)


## p4c: **`numeric_superiority_for_pinch`** sets **`pinch_center`** on wide outnumber (7v3) without hollow enemy front.


## p4c: **`numeric_superiority_for_pinch`** sets **`pinch_center`** on wide outnumber (7v3) without hollow enemy front.
static func _run_p4c_numeric_superiority_auto_pinch(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        _fail(failures, "p4c_numeric: FEATURE_AUTOMATIC_DOCTRINE should be enabled")
        return
    var mgr: Node = _MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1}, {"files": 3, "ranks": 1})
    if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
        _fail(failures, "p4c_numeric: full enemy front should not read hollow_center")
    if not _CombatDoctrine.numeric_superiority_for_pinch(mgr, "player"):
        _fail(failures, "p4c_numeric: 7v3 rank-0 fronts should trigger numeric_superiority")
    _CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(failures, "p4c_numeric: want pinch_center got %s" % mgr.get_formation_doctrine("player"))
    if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
        _fail(failures, "p4c_numeric: missing telemetry after evaluate_automatic_doctrine")
        _free_manager(mgr)
        return
    var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
    var lap: Variant = tel.get("last_automatic_doctrine_pinch", {})
    if typeof(lap) != TYPE_DICTIONARY:
        _fail(failures, "p4c_numeric: last_automatic_doctrine_pinch should be a dict")
        _free_manager(mgr)
        return
    if str((lap as Dictionary).get("reason", "")) != "numeric_superiority":
        _fail(
            failures, "p4c_numeric: want reason numeric_superiority got %s" % str((lap as Dictionary).get("reason", ""))
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    _CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(failures, "p4c_numeric: must not override player hold_lane got %s" % mgr.get_formation_doctrine("player"))
    _FormationEngagement.recompute_all(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures, "p4c_numeric: recompute must not override hold_lane got %s" % mgr.get_formation_doctrine("player")
        )
    _free_manager(mgr)


## Tier 7: bind **`parry_deflect`** grants defender gauge bonus; sub-threshold control does not.


## Tier 7: bind **`parry_deflect`** grants defender gauge bonus; sub-threshold control does not.
static func _run_tier7_parry_bind_riposte_gauge_bonus_on_deflect(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = _EntityAccess.id_int(defender)
    var e_id: int = _EntityAccess.id_int(attacker)
    attacker["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.8}
    defender["gauge"] = 40.0
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.72, "kinematic_delivery": "thrust"},
            }
        )
    )
    var want_bind: float = 40.0 + CombatConstants.PARRY_BIND_RIPOSTE_GAUGE_BONUS
    if not is_equal_approx(float(defender.get("gauge", -1.0)), want_bind):
        _fail(
            failures,
            "tier7_bind_gauge: bind deflect want %.1f got %.1f" % [want_bind, float(defender.get("gauge", -1.0))]
        )
    defender["gauge"] = 40.0
    attacker["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.8}
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.41, "kinematic_delivery": "thrust"},
            }
        )
    )
    if not is_equal_approx(float(defender.get("gauge", -1.0)), 40.0):
        _fail(
            failures,
            "tier7_bind_gauge: deflect-only should not bump gauge got %.1f" % float(defender.get("gauge", -1.0))
        )
    _free_manager(mgr)


## Tier 3.2: bind riposte speed depends on parry contact part plus the riposte contact type.


## Tier 3.2: bind riposte speed depends on parry contact part plus the riposte contact type.
static func _run_bind_riposte_contact_multipliers(failures: PackedStringArray) -> void:
    var spear_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", false)
    var spear_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", true)
    var spear_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["stab"])
    if spear_normal <= 0.0 or absf((spear_bind / spear_normal) - spear_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: spear stab ratio %.3f want %.3f"
                % [(spear_bind / spear_normal) if spear_normal > 0.0 else -1.0, spear_want]
            )
        )
    var mace_normal: float = _windup_duration_for_bind_test("MACE", "direct_blow", false)
    var mace_bind: float = _windup_duration_for_bind_test("MACE", "direct_blow", true)
    var mace_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["blunt"])
    if mace_normal <= 0.0 or absf((mace_bind / mace_normal) - mace_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: mace blunt ratio %.3f want %.3f"
                % [(mace_bind / mace_normal) if mace_normal > 0.0 else -1.0, mace_want]
            )
        )
    var axe_normal: float = _windup_duration_for_bind_test("AXE", "spike_thrust", false)
    var axe_bind: float = _windup_duration_for_bind_test("AXE", "spike_thrust", true)
    var axe_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["haft"] as Dictionary)["stab"])
    if axe_normal <= 0.0 or absf((axe_bind / axe_normal) - axe_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: axe spike ratio %.3f want %.3f"
                % [(axe_bind / axe_normal) if axe_normal > 0.0 else -1.0, axe_want]
            )
        )
    var spear_slash_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", false)
    var spear_slash_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", true)
    if spear_slash_normal <= 0.0 or absf((spear_slash_bind / spear_slash_normal) - 1.0) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: spear slash should not be eligible by default ratio %.3f"
                % [(spear_slash_bind / spear_slash_normal) if spear_slash_normal > 0.0 else -1.0]
            )
        )
    var sword_normal: float = _windup_duration_for_bind_test("SWORD", "oberhau", false)
    var sword_bind: float = _windup_duration_for_bind_test("SWORD", "oberhau", true)
    var sword_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary)["cut"])
    if sword_normal <= 0.0 or absf((sword_bind / sword_normal) - sword_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: sword cut ratio %.3f want %.3f"
                % [(sword_bind / sword_normal) if sword_normal > 0.0 else -1.0, sword_want]
            )
        )
    var dagger_normal: float = _windup_duration_for_bind_test("DAGGER", "quick_thrust", false)
    var dagger_bind: float = _windup_duration_for_bind_test("DAGGER", "quick_thrust", true)
    var dagger_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary)["stab"])
    if dagger_normal <= 0.0 or absf((dagger_bind / dagger_normal) - dagger_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: dagger stab ratio %.3f want %.3f"
                % [(dagger_bind / dagger_normal) if dagger_normal > 0.0 else -1.0, dagger_want]
            )
        )


## Tier 3.2 / P4h: bind riposte wind-up ordering  -  extend (stab) faster than swing (blunt) on bind follow-up.


## Tier 3.2 / P4h: bind riposte wind-up ordering  -  extend (stab) faster than swing (blunt) on bind follow-up.
static func _run_bind_riposte_archetype_ordering_spear_faster_than_mace(failures: PackedStringArray) -> void:
    var spear_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", false)
    var spear_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", true)
    var mace_normal: float = _windup_duration_for_bind_test("MACE", "direct_blow", false)
    var mace_bind: float = _windup_duration_for_bind_test("MACE", "direct_blow", true)
    if spear_normal <= 0.0 or mace_normal <= 0.0:
        _fail(
            failures,
            "bind_riposte_order: invalid baseline wind-up (spear=%.4f mace=%.4f)" % [spear_normal, mace_normal]
        )
        return
    var spear_ratio: float = spear_bind / spear_normal
    var mace_ratio: float = mace_bind / mace_normal
    if spear_ratio >= mace_ratio - 0.001:
        _fail(
            failures,
            "bind_riposte_order: spear stab ratio %.3f should be < mace blunt %.3f" % [spear_ratio, mace_ratio]
        )
    if spear_bind >= mace_bind:
        _fail(
            failures,
            "bind_riposte_order: spear bind duration %.4f should be < mace bind %.4f" % [spear_bind, mace_bind]
        )
    var sword_normal: float = _windup_duration_for_bind_test("SWORD", "oberhau", false)
    var sword_bind: float = _windup_duration_for_bind_test("SWORD", "oberhau", true)
    if sword_normal > 0.0:
        var sword_ratio: float = sword_bind / sword_normal
        if spear_ratio >= sword_ratio - 0.001 or sword_ratio >= mace_ratio - 0.001:
            _fail(
                failures,
                (
                    "bind_riposte_order: want stab < cut < blunt ratios got spear=%.3f sword=%.3f mace=%.3f"
                    % [spear_ratio, sword_ratio, mace_ratio]
                )
            )


## p4h: bind riposte balance  -  canonical table (stab < cut < blunt), fallback parity, ii2b riposte band.


## p4h: bind riposte balance  -  canonical table (stab < cut < blunt), fallback parity, ii2b riposte band.
static func _run_p4h_bind_riposte_balance_suite(failures: PackedStringArray) -> void:
    var blade: Dictionary = CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary
    var shaft: Dictionary = CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary
    var stab_m: float = float(blade["stab"])
    var cut_m: float = float(blade["cut"])
    var blunt_m: float = float(shaft["blunt"])
    if not is_equal_approx(stab_m, 0.55):
        _fail(failures, "p4h_riposte: blade stab want 0.55 got %.3f" % stab_m)
    if not is_equal_approx(cut_m, 0.78):
        _fail(failures, "p4h_riposte: blade cut want 0.78 got %.3f" % cut_m)
    if not is_equal_approx(blunt_m, 0.90):
        _fail(failures, "p4h_riposte: shaft blunt want 0.90 got %.3f" % blunt_m)
    if stab_m >= cut_m - 0.001 or cut_m >= blunt_m - 0.001:
        _fail(failures, "p4h_riposte: want stab < cut < blunt got %.3f %.3f %.3f" % [stab_m, cut_m, blunt_m])
    if not is_equal_approx(CombatConstants.PARRY_BIND_RIPOSTE_MULT_FALLBACK, cut_m):
        _fail(
            failures,
            (
                "p4h_riposte: fallback want cut mult %.3f got %.3f"
                % [cut_m, CombatConstants.PARRY_BIND_RIPOSTE_MULT_FALLBACK]
            )
        )
    var ii2b_band: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 2,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    var band_fail: PackedStringArray = CombatD001TrackSpecs.ii2b_plausibility_failures(ii2b_band)
    if not band_fail.is_empty():
        _fail(failures, "p4h_riposte: ii2b good band should pass: %s" % ", ".join(band_fail))


## P4d: doc <-> code sync  -  canonical bind/deflect/riposte lines in ii2b worksheet + calibration audit source.


## P4d: doc <-> code sync  -  canonical bind/deflect/riposte lines in ii2b worksheet + calibration audit source.
static func _run_p4d_parry_bind_doc_code_parity_suite(failures: PackedStringArray) -> void:
    var CalibrationAudit := preload("res://harness/CombatCalibrationAudit.gd")
    var sync_line: String = CombatConstants.p4d_parry_bind_doc_sync_line()
    if not sync_line.contains("blade stab=0.55"):
        _fail(failures, "p4d_sync: want blade stab=0.55 in %s" % sync_line)
    if not sync_line.contains("cut=0.78"):
        _fail(failures, "p4d_sync: want cut=0.78 in %s" % sync_line)
    if not sync_line.contains("shaft blunt=0.90"):
        _fail(failures, "p4d_sync: want shaft blunt=0.90 in %s" % sync_line)
    if not sync_line.contains("gauge_bonus=28"):
        _fail(failures, "p4d_sync: want gauge_bonus=28 in %s" % sync_line)
    var good_stats: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 2,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    var prefill: String = CombatD001TrackSpecs.ii2b_worksheet_prefill_text(good_stats, true)
    if CombatConstants.iii3_baseline_constants_line() not in prefill:
        _fail(failures, "p4d_sync: signed ii2b worksheet must include III-3 baseline line")
    if sync_line not in prefill:
        _fail(failures, "p4d_sync: signed ii2b worksheet must include P4d bind sync line")
    var audit_lines: PackedStringArray = PackedStringArray()
    var audit_fail: PackedStringArray = PackedStringArray()
    CalibrationAudit._append_parry_formula_section(audit_lines, audit_fail)
    var audit_text: String = "\n".join(audit_lines)
    if sync_line not in audit_text:
        _fail(failures, "p4d_sync: calibration audit parry section must include P4d bind sync line")
    if (
        (
            "PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f"
            % [CombatConstants.PARRY_DEFLECT_THRESHOLD, CombatConstants.PARRY_BIND_CONTROL_THRESHOLD]
        )
        not in audit_text
    ):
        _fail(failures, "p4d_sync: calibration audit must echo III-3 threshold pair")


## Tier 4.5: open bind-exchange window -> wind-up vs partner - -  **`FLURRY_BIND_WIND_UP_MULT`** (feature on).


## Tier 4.5: open bind-exchange window -> wind-up vs partner - -  **`FLURRY_BIND_WIND_UP_MULT`** (feature on).
static func _run_flurry_bind_exchange_wind_up_reduced_vs_plain(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr_p: Node = _MgrScript.new()
    mgr_p.register(_new_entity("SWORD"), "player")
    mgr_p.register(_new_entity("SWORD"), "enemy")
    mgr_p.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = _EntityAccess.id_int(mgr_p.combatants[0])
    var e_id: int = _EntityAccess.id_int(mgr_p.combatants[1])
    seed(90331)
    _WindUpStarter.start(mgr_p, p_id, e_id, "oberhau")
    var dur_plain: float = float(mgr_p.combatants[0].get("state_duration", 0.0))
    var mgr_f: Node = _MgrScript.new()
    mgr_f.register(_new_entity("SWORD"), "player")
    mgr_f.register(_new_entity("SWORD"), "enemy")
    mgr_f.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    _FlurryBind.open_window(mgr_f, p_id, e_id)
    seed(90331)
    _WindUpStarter.start(mgr_f, p_id, e_id, "oberhau")
    var dur_flurry: float = float(mgr_f.combatants[0].get("state_duration", 0.0))
    var want: float = dur_plain * CombatConstants.FLURRY_BIND_WIND_UP_MULT
    if absf(dur_flurry - want) > 0.0002:
        _fail(failures, "flurry_bind: duration want %.4f got %.4f plain=%.4f" % [want, dur_flurry, dur_plain])
    _free_manager(mgr_p)
    _free_manager(mgr_f)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: each wind-up start decrements **`flurry_exchanges_left`**.


## Tier 4.5: each wind-up start decrements **`flurry_exchanges_left`**.
static func _run_flurry_bind_exchange_consumes_on_wind_up(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _FlurryBind.open_window(mgr, p_id, e_id)
    if int(p.get("flurry_exchanges_left", 0)) != CombatConstants.FLURRY_BIND_MAX_EXCHANGES:
        _fail(
            failures,
            (
                "flurry_bind: want %d exchanges after open got %s"
                % [CombatConstants.FLURRY_BIND_MAX_EXCHANGES, str(p.get("flurry_exchanges_left", "<absent>"))]
            )
        )
    seed(90332)
    _WindUpStarter.start(mgr, p_id, e_id, "oberhau")
    if int(p.get("flurry_exchanges_left", -99)) != CombatConstants.FLURRY_BIND_MAX_EXCHANGES - 1:
        _fail(
            failures,
            (
                "flurry_bind: want %d exchanges after first wind-up got %s"
                % [CombatConstants.FLURRY_BIND_MAX_EXCHANGES - 1, str(p.get("flurry_exchanges_left", "<absent>"))]
            )
        )
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: **`hit`** clears bind-exchange keys on both partners.


## Tier 4.5: **`hit`** clears bind-exchange keys on both partners.
static func _run_flurry_bind_window_closes_on_hit(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _FlurryBind.open_pair_after_bind(mgr, p_id, e_id)
    _FlurryBind.clear_pair(mgr, p_id, e_id)
    for label in ["player", "enemy"]:
        var c: Dictionary = mgr.combatants[0] if label == "player" else mgr.combatants[1]
        if c.has("flurry_until") or c.has("flurry_against_id") or c.has("flurry_exchanges_left"):
            _fail(failures, "flurry_bind: %s should have flurry keys cleared after hit clear" % label)
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: melee listing only offers strikes vs **`flurry_against_id`** while window active.


## Tier 4.5: melee listing only offers strikes vs **`flurry_against_id`** while window active.
static func _run_flurry_bind_listing_restricts_to_bind_partner(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(mgr.combatants[1])
    var e1_id: int = _EntityAccess.id_int(mgr.combatants[2])
    _FlurryBind.open_window(mgr, p_id, e0_id)
    var actions: Array = _ActionsBuilder.build(mgr, p_id)
    var bad_flurry: Dictionary = _ListedActions.first_action_where(
        actions,
        func(a: Dictionary) -> bool:
            var mid: String = _ListedActions.entry_move_id(a)
            if mid.is_empty() or mid in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
                return false
            if WeaponConstants.is_parry_move(mid):
                return false
            return _ListedActions.entry_target_id(a) != e0_id
    )
    if not bad_flurry.is_empty():
        _fail(
            failures,
            (
                "flurry_bind listing: melee target want %d got %d move=%s"
                % [
                    e0_id,
                    _ListedActions.entry_target_id(bad_flurry),
                    _ListedActions.entry_move_id(bad_flurry),
                ]
            )
        )
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: hard bind **`parry_deflect`** opens mutual flurry windows on both partners.


## Tier 4.5: hard bind **`parry_deflect`** opens mutual flurry windows on both partners.
static func _run_flurry_bind_opens_on_bind_deflect(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = _EntityAccess.id_int(defender)
    var e_id: int = _EntityAccess.id_int(attacker)
    attacker["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.8}
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.72, "kinematic_delivery": "thrust"},
            }
        )
    )
    var clk: float = _EntityAccess.combat_clock_float(mgr)
    if not _FlurryBind.is_active_vs(defender, e_id, clk):
        _fail(failures, "flurry_bind: defender window should open on bind deflect")
    if not _FlurryBind.is_active_vs(attacker, p_id, clk):
        _fail(failures, "flurry_bind: attacker window should open on bind deflect")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: **`process_waiting`** clears flurry keys after **`FLURRY_BIND_WINDOW_S`**.


## Tier 4.5: **`process_waiting`** clears flurry keys after **`FLURRY_BIND_WINDOW_S`**.
static func _run_flurry_bind_expires_after_window(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    mgr.combat_clock = 0.0
    _FlurryBind.open_window(mgr, p_id, e_id)
    mgr.combat_clock = CombatConstants.FLURRY_BIND_WINDOW_S + 0.05
    _FlurryBind.process_waiting(mgr, p)
    if _FlurryBind.is_active(p, mgr.combat_clock):
        _fail(failures, "flurry_bind: window should expire after FLURRY_BIND_WINDOW_S")
    if p.has("flurry_until") or p.has("flurry_against_id") or p.has("flurry_exchanges_left"):
        _fail(failures, "flurry_bind: expired window should erase flurry keys")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: gauge label shows bind-exchange suffix while flurry window is open (feature on).


## Tier 4.5: gauge label shows bind-exchange suffix while flurry window is open (feature on).
static func _run_flurry_bind_ui_gauge_label_when_window_open(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    p["state"] = CombatConstants.STATE_WAITING
    p["gauge"] = 100.0
    _FlurryBind.open_window(mgr, p_id, e_id)
    var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(p, mgr)
    if "Bind exchange" not in label:
        _fail(failures, "flurry_bind_ui: gauge want Bind exchange suffix got %s" % label)
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(p, mgr)
    var found_tip: bool = false
    for line in tips:
        if str(line).begins_with("Bind exchange"):
            found_tip = true
            break
    if not found_tip:
        _fail(failures, "flurry_bind_ui: gauge tooltip should mention bind exchange")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: runtime toggle disables opening bind-exchange windows (production default **on**).


## Tier 4.5: runtime toggle disables opening bind-exchange windows (production default **on**).
static func _run_flurry_bind_feature_flag_respects_runtime_toggle(failures: PackedStringArray) -> void:
    var prev: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    p["state"] = CombatConstants.STATE_WAITING
    CombatConstants.set_feature_flurry_bind_exchange_load(false)
    _FlurryBind.open_window(mgr, p_id, e_id)
    if p.has("flurry_until") or p.has("flurry_against_id") or p.has("flurry_exchanges_left"):
        CombatConstants.set_feature_flurry_bind_exchange_load(prev)
        _free_manager(mgr)
        _fail(failures, "flurry_flag: open_window should no-op when feature off")
        return
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    _FlurryBind.open_window(mgr, p_id, e_id)
    var clk: float = _EntityAccess.combat_clock_float(mgr)
    if not _FlurryBind.is_active_vs(p, e_id, clk):
        CombatConstants.set_feature_flurry_bind_exchange_load(prev)
        _free_manager(mgr)
        _fail(failures, "flurry_flag: open_window should stamp keys when feature on")
        return
    CombatConstants.set_feature_flurry_bind_exchange_load(prev)
    _free_manager(mgr)


## p4g: bind-exchange depth  -  canonical tuning constants, partner-only stamina discount, exchanges exhaust before
## window expiry.


## p4g: bind-exchange depth  -  canonical tuning constants, partner-only stamina discount, exchanges exhaust before
## window expiry.
static func _run_p4g_flurry_bind_depth_suite(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_FLURRY_BIND_EXCHANGE:
        _fail(failures, "p4g_flurry: FEATURE_FLURRY_BIND_EXCHANGE should be enabled")
        return
    if not is_equal_approx(CombatConstants.FLURRY_BIND_WINDOW_S, 1.25):
        _fail(failures, "p4g_flurry: FLURRY_BIND_WINDOW_S want 1.25 got %.3f" % CombatConstants.FLURRY_BIND_WINDOW_S)
    if CombatConstants.FLURRY_BIND_MAX_EXCHANGES != 2:
        _fail(
            failures, "p4g_flurry: FLURRY_BIND_MAX_EXCHANGES want 2 got %d" % CombatConstants.FLURRY_BIND_MAX_EXCHANGES
        )
    if not is_equal_approx(CombatConstants.FLURRY_BIND_WIND_UP_MULT, 0.82):
        _fail(
            failures,
            "p4g_flurry: FLURRY_BIND_WIND_UP_MULT want 0.82 got %.3f" % CombatConstants.FLURRY_BIND_WIND_UP_MULT
        )
    if not is_equal_approx(CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT, 0.88):
        _fail(
            failures,
            (
                "p4g_flurry: FLURRY_BIND_STAMINA_ATTACK_COST_MULT want 0.88 got %.3f"
                % CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT
            )
        )
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(mgr.combatants[1])
    var e1_id: int = _EntityAccess.id_int(mgr.combatants[2])
    mgr.combat_clock = 0.0
    _FlurryBind.open_window(mgr, p_id, e0_id)
    var clk: float = _EntityAccess.combat_clock_float(mgr)
    var stam_partner: float = _FlurryBind.stamina_attack_cost_mult(p, e0_id, clk)
    var stam_other: float = _FlurryBind.stamina_attack_cost_mult(p, e1_id, clk)
    if not is_equal_approx(stam_partner, CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT):
        _fail(
            failures,
            (
                "p4g_flurry: partner stamina mult want %.3f got %.3f"
                % [CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT, stam_partner]
            )
        )
    if stam_other != 1.0:
        _fail(failures, "p4g_flurry: non-partner stamina mult want 1.0 got %.3f" % stam_other)
    for _i in CombatConstants.FLURRY_BIND_MAX_EXCHANGES:
        _FlurryBind.consume_exchange_on_wind_up_start(p)
    if _FlurryBind.is_active(p, clk):
        _fail(failures, "p4g_flurry: zero exchanges should deactivate inside window")
    if _FlurryBind.wind_up_mult(p, e0_id, clk) != 1.0:
        _fail(failures, "p4g_flurry: wind_up_mult should be 1.0 when exchanges exhausted")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 3.2: opposite-line parry magnitude uses contact-type severity thresholds.


## Tier 3.2: opposite-line parry magnitude uses contact-type severity thresholds.
static func _run_parry_opposite_deflect_thresholds(failures: PackedStringArray) -> void:
    var align: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
    var cut_low: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.01, WeaponConstants.ATTACK_TYPE_CUT, align
    )
    if cut_low not in _harness_adjacent_lines_for("high"):
        _fail(failures, "parry_deflect_threshold: weak cut should partial-deflect high to adjacent, got %s" % cut_low)
    var cut_full: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT + 0.01, WeaponConstants.ATTACK_TYPE_CUT, align
    )
    if cut_full != _harness_opposite_cardinal("high"):
        _fail(failures, "parry_deflect_threshold: strong cut should deflect high to opposite, got %s" % cut_full)
    var stab_mid: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, 0.55, WeaponConstants.ATTACK_TYPE_STAB, align
    )
    if stab_mid != _harness_opposite_cardinal("high"):
        _fail(failures, "parry_deflect_threshold: thrust should reach full opposite at 0.55, got %s" % stab_mid)
    var blunt_mid: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, 0.55, WeaponConstants.ATTACK_TYPE_BLUNT, align
    )
    if blunt_mid not in _harness_adjacent_lines_for("high"):
        _fail(failures, "parry_deflect_threshold: blunt at 0.55 should partial-deflect to adjacent, got %s" % blunt_mid)
    seed(1205)
    var atk_adj: float = CombatConstants.line_to_angle(_harness_cardinal_attack_line("high_right"))
    var guard_adj: float = CombatConstants.line_to_angle("right")
    var adj_align: float = CombatConstants.get_alignment_from_angles(atk_adj, guard_adj)
    var adjacent_guard: String = CombatConstants.get_deflected_line_from_angles(
        atk_adj, guard_adj, 1.0, WeaponConstants.ATTACK_TYPE_CUT, adj_align
    )
    if adjacent_guard not in _harness_adjacent_lines_for("high_right"):
        _fail(failures, "parry_deflect_threshold: adjacent guard should stay adjacent, got %s" % adjacent_guard)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 3.2: defender weapon type - -  attack contact modifiers apply through Weapon object fields.


## Tier 3.2: defender weapon type - -  attack contact modifiers apply through Weapon object fields.
static func _run_parry_defender_vs_attack_modifiers(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("DAGGER"), "player")
    mgr.register(_new_entity("MACE"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var dagger_defender: Dictionary = mgr.combatants[0]
    var mace_defender: Dictionary = mgr.combatants[1]
    var spear_defender: Dictionary = mgr.combatants[2]
    var dagger: Weapon = _EntityAccess.get_weapon(dagger_defender)
    var mace: Weapon = _EntityAccess.get_weapon(mace_defender)
    var spear: Weapon = _EntityAccess.get_weapon(spear_defender)
    if dagger == null:
        _fail(failures, "parry_def_vs_atk: missing dagger weapon")
        _free_manager(mgr)
        return
    if mace == null:
        _fail(failures, "parry_def_vs_atk: missing mace weapon")
        _free_manager(mgr)
        return
    if spear == null:
        _fail(failures, "parry_def_vs_atk: missing spear weapon")
        _free_manager(mgr)
        return
    var dagger_stab_cd: float = _DefenseChoice._compute_parry_c_d(
        dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_STAB.to_upper()
    )
    var dagger_cut_cd: float = _DefenseChoice._compute_parry_c_d(
        dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_CUT
    )
    var dagger_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["DAGGER"] as Dictionary)["stab"])
    var dagger_ratio: float = dagger_stab_cd / dagger_cut_cd if dagger_cut_cd > 0.0 else -1.0
    if dagger_cut_cd <= 0.0 or absf(dagger_ratio - dagger_expected) > 0.001:
        _fail(failures, "parry_def_vs_atk: dagger stab/cut ratio %.3f want %.3f" % [dagger_ratio, dagger_expected])
    var mace_blunt_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_BLUNT)
    var mace_cut_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_CUT)
    var mace_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["MACE"] as Dictionary)["blunt"])
    var mace_ratio: float = mace_blunt_cd / mace_cut_cd if mace_cut_cd > 0.0 else -1.0
    if mace_cut_cd <= 0.0 or absf(mace_ratio - mace_expected) > 0.001:
        _fail(failures, "parry_def_vs_atk: mace blunt/cut ratio %.3f want %.3f" % [mace_ratio, mace_expected])
    var spear_cut_cd: float = _DefenseChoice._compute_parry_c_d(spear, spear_defender, WeaponConstants.ATTACK_TYPE_CUT)
    var spear_stab_cd: float = _DefenseChoice._compute_parry_c_d(
        spear, spear_defender, WeaponConstants.ATTACK_TYPE_STAB
    )
    var spear_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["SPEAR"] as Dictionary)["cut"])
    var spear_ratio: float = spear_cut_cd / spear_stab_cd if spear_stab_cd > 0.0 else -1.0
    if spear_stab_cd <= 0.0 or absf(spear_ratio - spear_expected) > 0.001:
        _fail(failures, "parry_def_vs_atk: spear cut/stab ratio %.3f want %.3f" % [spear_ratio, spear_expected])
    _free_manager(mgr)

## Tier 3.2 + 3.0: parry clash context preserves bind/deflect calibration + strike kinematics; asserts geometry + move
## ids vs **`DefenseResolutionHandler._resolve_parry`** and **`WeaponDamageHelper`** / **`StrikeRealismProfile`**; Tier
## **3.1** **`strike_measure_ratio`** vs **`pa`** after **`stamp_attack_pair_geometry_on_dict`** +
## **`strike_measure_ratio_for_attack_pair`** (full-stop key set **`PARRY_CLASH_CONTEXT_KEYS_FULL_STOP`**); stamped path
## sets **`impact_blade_station`** before **`resolve`** so post-resolve kinematics recompute matches
## **`velocity_intent_mult_from_pa`** (no extra **`randf()`** vs resolver); unstamped **`pa`** -> clash
## **`strike_measure_ratio`** **-1**, then **`seed(3312)`** before stamped path for stable RNG.
