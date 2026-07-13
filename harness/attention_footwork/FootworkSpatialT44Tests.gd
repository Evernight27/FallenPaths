class_name AttentionFootworkSpatialT44Tests
extends CombatRegressionHarnessCore
## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _run_t44_spatial_band_pa_defender_close_gt_long(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_t44: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        return
    var def_close: Dictionary = {
        "guard_line": "left",
        "distance_to": {1: CombatConstants.DISTANCE_CLOSE},
    }
    CombatFootwork.apply_defender_step_on_parry(def_close, "left", 1)
    var close_off: float = float(def_close.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var def_long: Dictionary = {
        "guard_line": "left",
        "distance_to": {1: CombatConstants.DISTANCE_LONG},
    }
    CombatFootwork.apply_defender_step_on_parry(def_long, "left", 1)
    var long_off: float = float(def_long.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want_close: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
    var want_long: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_LONG
    if absf(close_off - want_close) > 0.01 or absf(long_off - want_long) > 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "t44_spatial_band_pa_defender: close=%.2f long=%.2f want %.2f/%.2f"
                % [close_off, long_off, want_close, want_long]
            )
        )
    if absf(close_off) <= absf(long_off) + 0.001:
        CombatRegressionHarness._fail(failures, "t44_spatial_band_pa_defender: |close| should exceed |long|")
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


static func _run_t44_spatial_band_pa_flag_off_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_t44: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(false)
    var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    var atk: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_CLOSE}}
    CombatFootwork.apply_attack_step_on_windup(atk, "left", 2)
    var off_close: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    atk["distance_to"] = {2: CombatConstants.DISTANCE_LONG}
    CombatFootwork.apply_attack_step_on_windup(atk, "left", 2)
    var off_long: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(off_close - base) > 0.01 or absf(off_long - base) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_spatial_band_pa_flag_off: want base %.2f close=%.2f long=%.2f" % [base, off_close, off_long]
        )
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)

    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


## Tier 4.4 spatial slice 2: wing file dodge step > interior file (parry unchanged).


## Tier 4.4 spatial slice 2: wing file dodge step > interior file (parry unchanged).
static func _run_t44_spatial_file_dodge_wing_gt_interior(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
    var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var wing: Dictionary = {}
    var center: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, "player"):
            continue
        var fi: int = CombatantEntityAccess.file_int(c)
        if fi == 0:
            wing = c
        elif fi == 1:
            center = c
    if wing.is_empty() or center.is_empty():
        CombatRegressionHarness._fail(failures, "t44_file_dodge: missing wing/center fixtures")
        CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        CombatRegressionHarness._free_manager(mgr)
        return
    CombatFootwork.apply_defender_step_on_dodge(wing, "left_arm", -1, mgr)
    var wing_off: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatFootwork.apply_defender_step_on_dodge(center, "left_arm", -1, mgr)
    var center_off: float = float(center.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want_wing: float = base * CombatConstants.T44_SPATIAL_FILE_DODGE_WING_MULT
    if absf(wing_off - want_wing) > 0.01:
        CombatRegressionHarness._fail(failures, "t44_file_dodge: wing want %.2f got %.2f" % [want_wing, wing_off])
    if absf(center_off - base) > 0.01:
        CombatRegressionHarness._fail(failures, "t44_file_dodge: center want %.2f got %.2f" % [base, center_off])
    if absf(wing_off) <= absf(center_off) + 0.001:
        CombatRegressionHarness._fail(failures, "t44_file_dodge: |wing| should exceed |center|")
    var right_wing: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, "player"):
            continue
        if CombatantEntityAccess.file_int(c) == 2:
            right_wing = c
            break
    if right_wing.is_empty():
        CombatRegressionHarness._fail(failures, "t44_file_dodge: missing right-wing fixture")
    else:
        CombatFootwork.apply_defender_step_on_dodge(right_wing, "left_arm", -1, mgr)
        var rw_off: float = float(right_wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
        if absf(rw_off - want_wing) > 0.01:
            CombatRegressionHarness._fail(
                failures, "t44_file_dodge: right wing want %.2f got %.2f" % [want_wing, rw_off]
            )
    CombatFootwork.apply_defender_step_on_parry(wing, "left", -1)
    var wing_parry: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatFootwork.apply_defender_step_on_parry(center, "left", -1)
    var center_parry: float = float(center.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(wing_parry - center_parry) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_file_dodge: parry must not differ wing=%.2f center=%.2f" % [wing_parry, center_parry]
        )
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 2: **`dodge_eval_step_deg_for_defender`** matches dodge stamp on wing file.


## Tier 4.4 spatial slice 2: **`dodge_eval_step_deg_for_defender`** matches dodge stamp on wing file.
static func _run_t44_spatial_file_dodge_eval_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var wing: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "player") and CombatantEntityAccess.file_int(c) == 0:
            wing = c
            break
    if wing.is_empty():
        CombatRegressionHarness._fail(failures, "t44_file_dodge_eval: missing wing fixture")
    else:
        var eval_deg: float = CombatFootwork.dodge_eval_step_deg_for_defender(wing, "left_arm", -1, mgr)
        CombatFootwork.apply_defender_step_on_dodge(wing, "left_arm", -1, mgr)
        var stamp_deg: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
        if absf(eval_deg - stamp_deg) > 0.01:
            CombatRegressionHarness._fail(
                failures, "t44_file_dodge_eval: want parity eval=%.2f stamp=%.2f" % [eval_deg, stamp_deg]
            )
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_file_dodge_flag_off_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(false)
    var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var wing: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "player") and CombatantEntityAccess.file_int(c) == 0:
            wing = c
            break
    CombatFootwork.apply_defender_step_on_dodge(wing, "left_arm", -1, mgr)
    var off: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    CombatRegressionHarness._free_manager(mgr)
    if absf(off - base) > 0.01:
        CombatRegressionHarness._fail(failures, "t44_file_dodge_off: flag off want base %.2f got %.2f" % [base, off])


static func _run_t44_spatial_file_dodge_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.t44_spatial_file_dodge_doc_sync_line()
    if sync_line.is_empty() or "slice2=wing_file_dodge_step_bias" not in sync_line:
        CombatRegressionHarness._fail(failures, "t44_file_dodge: bad doc_sync_line %s" % sync_line)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_file_dodge_wing_gt_interior(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_file_dodge_eval_parity(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_file_dodge_flag_off_parity(failures)


## Tier 4.4 spatial slice 3: active bind flurry vs partner boosts PA wind-up step.


## Tier 4.4 spatial slice 3: active bind flurry vs partner boosts PA wind-up step.
static func _run_t44_spatial_flurry_pa_bind_boost(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    mgr.combat_clock = 0.0
    CombatFlurryBind.open_window(mgr, atk_id, def_id)
    CombatFootwork.apply_attack_step_on_windup(atk, "left", def_id, mgr)
    var got: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want: float = base * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
    if absf(got - want) > 0.02:
        CombatRegressionHarness._fail(failures, "t44_flurry_pa: bind boost want %.2f got %.2f" % [want, got])
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 3: flurry window open but flag off -> base PA only.


## Tier 4.4 spatial slice 3: flurry window open but flag off -> base PA only.
static func _run_t44_spatial_flurry_pa_flag_off_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(false)
    var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(atk), def_id)
    CombatFootwork.apply_attack_step_on_windup(atk, "left", def_id, mgr)
    var got: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)
    if absf(got - base) > 0.02:
        CombatRegressionHarness._fail(failures, "t44_flurry_pa_off: want base %.2f got %.2f" % [base, got])


static func _run_t44_spatial_flurry_pa_parry_eval_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    def["guard_line"] = "left"
    CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(def), atk_id)
    var eval_deg: float = CombatFootwork.parry_eval_step_deg_for_defender(def, atk_id, mgr)
    CombatFootwork.apply_defender_step_on_parry(def, "left", atk_id, mgr)
    var stamp_deg: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(eval_deg - stamp_deg) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_flurry_pa: parry_eval want stamp parity eval=%.2f stamp=%.2f" % [eval_deg, stamp_deg]
        )
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 3: flurry bind  -  **`dodge_eval_step_deg_for_defender`** matches dodge stamp.


## Tier 4.4 spatial slice 3: flurry bind  -  **`dodge_eval_step_deg_for_defender`** matches dodge stamp.
static func _run_t44_spatial_flurry_pa_dodge_eval_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(def), atk_id)
    var eval_deg: float = CombatFootwork.dodge_eval_step_deg_for_defender(def, "left_arm", atk_id, mgr)
    CombatFootwork.apply_defender_step_on_dodge(def, "left_arm", atk_id, mgr)
    var stamp_deg: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(eval_deg - stamp_deg) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_flurry_pa: dodge_eval want stamp parity eval=%.2f stamp=%.2f" % [eval_deg, stamp_deg]
        )
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 3: flurry bind  -  **`attack_eval_step_deg_for_attacker`** matches wind-up stamp.


## Tier 4.4 spatial slice 3: flurry bind  -  **`attack_eval_step_deg_for_attacker`** matches wind-up stamp.
static func _run_t44_spatial_flurry_pa_attack_eval_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(atk), def_id)
    var eval_deg: float = CombatFootwork.attack_eval_step_deg_for_attacker(atk, "left", def_id, mgr)
    CombatFootwork.apply_attack_step_on_windup(atk, "left", def_id, mgr)
    var stamp_deg: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want: float = base * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
    if absf(eval_deg - stamp_deg) > 0.01 or absf(stamp_deg - want) > 0.02:
        CombatRegressionHarness._fail(
            failures,
            "t44_flurry_pa: attack_eval want parity eval=%.2f stamp=%.2f want=%.2f" % [eval_deg, stamp_deg, want]
        )
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_flurry_pa_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.t44_spatial_flurry_pa_doc_sync_line()
    if sync_line.is_empty() or "slice3=flurry_bind_pa_boost" not in sync_line:
        CombatRegressionHarness._fail(failures, "t44_flurry_pa: bad doc_sync_line %s" % sync_line)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_flurry_pa_bind_boost(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_flurry_pa_attack_eval_parity(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_flurry_pa_parry_eval_parity(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_flurry_pa_dodge_eval_parity(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_flurry_pa_flag_off_parity(failures)


static func _run_t44_spatial_band_pa_parry_eval_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    var def: Dictionary = {
        "guard_line": "left",
        "distance_to": {2: CombatConstants.DISTANCE_CLOSE},
    }
    var eval_deg: float = CombatFootwork.parry_eval_step_deg_for_defender(def, 2)
    CombatFootwork.apply_defender_step_on_parry(def, "left", 2)
    var stamp_deg: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    if absf(eval_deg - stamp_deg) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_band_pa: parry_eval want stamp parity eval=%.2f stamp=%.2f" % [eval_deg, stamp_deg]
        )


static func _run_t44_spatial_stacked_band_file_dodge(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
    var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
        CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var wing: Dictionary = {}
    var atk_id: int = CombatantEntityAccess.id_int(mgr.combatants[3])
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "player") and CombatantEntityAccess.file_int(c) == 0:
            wing = c
            break
    if wing.is_empty():
        CombatRegressionHarness._fail(failures, "t44_stacked: missing wing fixture")
    else:
        wing["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
        CombatFootwork.apply_defender_step_on_dodge(wing, "left_arm", atk_id, mgr)
        var got: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
        var want: float = (
            base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE * CombatConstants.T44_SPATIAL_FILE_DODGE_WING_MULT
        )
        if absf(got - want) > 0.02:
            CombatRegressionHarness._fail(failures, "t44_stacked: want %.2f got %.2f (close+wing)" % [want, got])
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_band_pa_attacker_eval_parity(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        return
    var atk: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_CLOSE}}
    var eval_deg: float = CombatFootwork.attack_eval_step_deg_for_attacker(atk, "left", 2)
    CombatFootwork.apply_attack_step_on_windup(atk, "left", 2)
    var stamp_deg: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
    if absf(eval_deg - stamp_deg) > 0.01 or absf(stamp_deg - want) > 0.02:
        CombatRegressionHarness._fail(
            failures,
            "t44_band_pa: attacker_eval want parity eval=%.2f stamp=%.2f want=%.2f" % [eval_deg, stamp_deg, want]
        )
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


static func _run_t44_spatial_stacked_band_flurry_dodge(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
        CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    def["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
    CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(def), atk_id)
    CombatFootwork.apply_defender_step_on_dodge(def, "left_arm", atk_id, mgr)
    var got: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
    if absf(got - want) > 0.02:
        CombatRegressionHarness._fail(
            failures, "t44_stacked_flurry: want %.2f got %.2f (close+flurry dodge)" % [want, got]
        )
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial: band + wing file + flurry stack on dodge stamp.


## Tier 4.4 spatial: band + wing file + flurry stack on dodge stamp.
static func _run_t44_spatial_stacked_band_file_flurry_dodge(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
        CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
        CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var wing: Dictionary = {}
    var atk_id: int = CombatantEntityAccess.id_int(mgr.combatants[3])
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "player") and CombatantEntityAccess.file_int(c) == 0:
            wing = c
            break
    if wing.is_empty():
        CombatRegressionHarness._fail(failures, "t44_stacked_all: missing wing fixture")
    else:
        wing["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
        CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(wing), atk_id)
        CombatFootwork.apply_defender_step_on_dodge(wing, "left_arm", atk_id, mgr)
        var got: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
        var want: float = (
            base
            * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
            * CombatConstants.T44_SPATIAL_FILE_DODGE_WING_MULT
            * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
        )
        if absf(got - want) > 0.03:
            CombatRegressionHarness._fail(
                failures, "t44_stacked_all: want %.2f got %.2f (close+wing+flurry)" % [want, got]
            )
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_band_pa_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.t44_spatial_band_pa_doc_sync_line()
    if sync_line.is_empty():
        CombatRegressionHarness._fail(failures, "t44_spatial_band_pa: empty doc_sync_line")
    AttentionFootworkFocusLineFootworkPickerTests._run_t44_spatial_band_pa_attacker_close_gt_long(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_band_pa_attacker_eval_parity(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_band_pa_defender_close_gt_long(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_band_pa_parry_eval_parity(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_stacked_band_file_dodge(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_stacked_band_flurry_dodge(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_stacked_band_file_flurry_dodge(failures)
    AttentionFootworkSpatialT44Tests._run_t44_spatial_band_pa_flag_off_parity(failures)


## WF-T1 suite: octant raw table + defender scales  -  single entry for Phase 0 maintain.


## WF-T1 suite: octant raw table + defender scales  -  single entry for Phase 0 maintain.
static func _run_footwork_wf_t1_octant_suite(failures: PackedStringArray) -> void:
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_defender_scales_wf_t1_locked(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_octant_lookup_delegates_to_guard_lines(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_eight_line_home_guard_parry_step(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_octant_windup_step_diagonals(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_defender_dodge_step_stamps_octant_low_left(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_defender_dodge_step_stamps_octant_right_leg(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_parry_eval_step_octant_home(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_dodge_eval_step_octant_arm(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_defender_parry_step_lt_dodge_on_octant(failures)
    AttentionFootworkFocusLineFootworkPickerTests._run_footwork_guard_angle_deg_octant_parry_step(failures)
    AttentionFootworkSpatialT44Tests._run_footwork_attack_angle_includes_octant_windup(failures)


## WF-T1: attacker contact angle includes octant wind-up step (**`high_right`** / ox home).


## WF-T1: attacker contact angle includes octant wind-up step (**`high_right`** / ox home).
static func _run_footwork_attack_angle_includes_octant_windup(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var line: String = _GuardLines.LINE_HIGH_RIGHT
    var atk: Dictionary = {
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG:
        CombatConstants.position_angle_offset_deg_for_attack_line(line),
    }
    var base_deg: float = _GuardLines.line_to_angle(line)
    var shifted: float = CombatFootwork.apply_offset_to_angle_deg(base_deg, atk)
    var step: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
    var want: float = fmod(base_deg + step + 360.0, 360.0)
    if absf(shifted - want) > 0.05:
        CombatRegressionHarness._fail(
            failures,
            (
                "footwork_attack_angle_octant: high_right want %.2f got %.2f (base=%.2f step=%.2f)"
                % [want, shifted, base_deg, step]
            )
        )


static func _run_footwork_defender_parry_step_stamps_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var def: Dictionary = {}
    CombatFootwork.apply_defender_step_on_parry(def, "left")
    var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    if absf(off - want) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_def_parry: want %.2f got %.2f" % [want, off])


## Tier 4.4.2: defender offset rotates effective guard angle for alignment.


## Tier 4.4.2: defender offset rotates effective guard angle for alignment.
static func _run_footwork_defender_offset_shifts_guard_angle_deg(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var def: Dictionary = {
        "guard_line": "left",
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG:
        CombatConstants.position_angle_defender_offset_deg_for_line(
            "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
        ),
    }
    var base_deg: float = CombatConstants.get_guard_angle_deg(def, {})
    var shifted: float = CombatFootwork.guard_angle_deg(def, {})
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var want: float = fmod(
        (
            base_deg
            + CombatConstants.position_angle_defender_offset_deg_for_line(
                "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
            )
            + 360.0
        ),
        360.0
    )
    if absf(shifted - want) > 0.05:
        CombatRegressionHarness._fail(failures, "footwork_def_guard: want %.2f got %.2f" % [want, shifted])


## Tier 4.4.2: dodge stamps larger scaled offset from eval part line.


## Tier 4.4.2: dodge stamps larger scaled offset from eval part line.
static func _run_footwork_defender_dodge_step_stamps_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var def: Dictionary = {}
    CombatFootwork.apply_defender_step_on_dodge(def, "left_arm")
    var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(off - want) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_def_dodge: want %.2f got %.2f" % [want, off])


## Tier 4.4.2: exchange end clears defender offset (dodge applier path).


## Tier 4.4.2: exchange end clears defender offset (dodge applier path).
static func _run_footwork_defender_offset_scrubbed_after_exchange(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    def[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 9.0
    (
        AttackResultApplier
        . apply_result(
            mgr,
            CombatantEntityAccess.id_int(atk),
            {"action": "dodge", "target_id": CombatantEntityAccess.id_int(def), "recovery_duration": 0.2},
        )
    )
    if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_def_scrub: defender offset should clear after dodge")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.4.3: footwork UI hint shows step label without degree clutter.


## Tier 4.4.3: footwork UI hint shows step label without degree clutter.
static func _run_footwork_ui_hint_formats_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var atk: Dictionary = {}
    CombatFootwork.apply_attack_step_on_windup(atk, "left")
    var hint: String = CombatFootwork.format_position_angle_ui_hint(atk)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if hint != "Step":
        CombatRegressionHarness._fail(failures, "footwork_ui_hint: want 'Step' got '%s'" % hint)


## Tier 4.4.3: formation diagram has no footwork degree suffix.


## Tier 4.4.3: formation diagram has no footwork degree suffix.
static func _run_footwork_ui_hint_clears_on_clear_position_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {}
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    CombatFootwork.clear_position_offset(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
        CombatRegressionHarness._fail(failures, "footwork_ui_hint_clear: hint key should be erased")
    if CombatFootwork.format_position_angle_ui_hint(c) != "":
        CombatRegressionHarness._fail(failures, "footwork_ui_hint_clear: format should be empty")
    if CombatFootwork.get_ui_hint(c) != "":
        CombatRegressionHarness._fail(failures, "footwork_ui_hint_clear: get_ui_hint should be empty")


## Tier 4.4: aborted wind-up clears attacker step offset (reserve / back rank stuck UI).


## Tier 4.4: aborted wind-up clears attacker step offset (reserve / back rank stuck UI).
static func _run_footwork_abort_attacker_wind_up_clears_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    _WindUpStarter.start(mgr, atk_id, CombatantEntityAccess.id_int(def), "slash")
    if absf(CombatFootwork.get_attacker_offset_deg(atk)) < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_abort: wind-up should stamp offset before abort")
    CounterTempo.abort_attacker_wind_up(mgr, atk_id)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_abort: offset key should be erased after abort")
    if CombatFootwork.get_ui_hint(atk) != "":
        CombatRegressionHarness._fail(failures, "footwork_abort: get_ui_hint should be empty after abort")
    if CombatantEntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
        CombatRegressionHarness._fail(
            failures, "footwork_abort: want short recovery after abort got '%s'" % CombatantEntityAccess.state_str(atk)
        )


## Tier 4.4 UI: idle waiting hides stale offset on gauge/diagram even if dict key leaked.


## Tier 4.4 UI: idle waiting hides stale offset on gauge/diagram even if dict key leaked.
static func _run_footwork_waiting_hides_stale_step_ui(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    if CombatFootwork.get_ui_hint(c) != "":
        CombatRegressionHarness._fail(failures, "footwork_waiting_ui: get_ui_hint should be empty while waiting")
    if CombatFootwork.get_diagram_label_suffix(c) != "":
        CombatRegressionHarness._fail(failures, "footwork_waiting_ui: diagram suffix should be empty while waiting")
    CombatConstants.set_feature_position_angle_footwork_load(true)


## Tier 4.4 UI: snapshot rows omit PA export while idle waiting even if offset key leaked.


## Tier 4.4 UI: snapshot rows omit PA export while idle waiting even if offset key leaked.
static func _run_footwork_snapshot_omits_pa_while_waiting(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    atk["state"] = CombatConstants.STATE_WAITING
    CombatFootwork.apply_attack_step_on_windup(atk, "left")
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_snapshot_waiting: expected rows")
        return
    var row: Dictionary = rows[0]
    if row.has("position_angle_offset_deg"):
        CombatRegressionHarness._fail(failures, "footwork_snapshot_waiting: offset should not export while waiting")
    if row.has("position_angle_ui_hint"):
        CombatRegressionHarness._fail(failures, "footwork_snapshot_waiting: ui hint should not export while waiting")


## Tier 4.4: **`process_waiting`** scrubs leaked PA keys on idle reserve (wf_m3 idle step leak guard).


## Tier 4.4: **`process_waiting`** scrubs leaked PA keys on idle reserve (wf_m3 idle step leak guard).
static func _run_footwork_process_waiting_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "guard": 1.0, "stamina": 80.0}
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    _StateHandlers.process_waiting(null, c, 0.05)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_waiting_scrub: offset key should be erased")
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
        CombatRegressionHarness._fail(failures, "footwork_waiting_scrub: ui hint key should be erased")


## Tier 4.4 + III-8: **`complete_recovery`** accepts compatibility **`parry_deflect`** cause (deflect guard path + PA
## scrub).


## Tier 4.4 + III-8: **`complete_recovery`** accepts compatibility **`parry_deflect`** cause (deflect guard path + PA
## scrub).
static func _run_footwork_complete_recovery_parry_deflect_alias(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    c["state"] = CombatConstants.STATE_RECOVERING
    c["recovery_cause"] = "parry_deflect"
    c["last_move_id"] = "oberhau"
    c["effective_attack_line"] = "high"
    c["defender_guard_line_at_parry"] = "high"
    c["parry_clash_context"] = {"severity": 0.4}
    CombatFootwork.apply_attack_step_on_windup(c, "left")
    _StateHandlers.complete_recovery(mgr, c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_recovery_alias: offset should be cleared")
    if c.has("defender_guard_line_at_parry"):
        CombatRegressionHarness._fail(
            failures, "footwork_recovery_alias: deflect guard path should erase defender_guard_line_at_parry"
        )
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        CombatRegressionHarness._fail(
            failures,
            "footwork_recovery_alias: want waiting after recovery got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: cowering tick scrubs leaked PA (**`process_incapacitation`**  -  no **`process_waiting`** on cowering).


## Tier 4.4: cowering tick scrubs leaked PA (**`process_incapacitation`**  -  no **`process_waiting`** on cowering).
static func _run_footwork_cowering_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    c["state"] = CombatConstants.STATE_COWERING
    CombatFootwork.apply_attack_step_on_windup(c, "left")
    _StateHandlers.process_incapacitation(mgr, c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_cowering_scrub: offset key should be erased")
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
        CombatRegressionHarness._fail(failures, "footwork_cowering_scrub: ui hint key should be erased")


## Tier 4.4: formation-move timer tick scrubs leaked PA (**`process_formation_move_timer`**).


## Tier 4.4: formation-move timer tick scrubs leaked PA (**`process_formation_move_timer`**).
static func _run_footwork_formation_move_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {
        "state": CombatConstants.STATE_SWAP_RANK,
        "state_timer": 0.0,
        "state_duration": 0.5,
    }
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    _StateHandlers.process_formation_move_timer(c, 0.05)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_formation_scrub: offset key should be erased")
    if absf(float(c.get("state_timer", 0.0)) - 0.05) > 0.001:
        CombatRegressionHarness._fail(
            failures, "footwork_formation_scrub: timer should advance got %.4f" % float(c.get("state_timer", 0.0))
        )

## Tier 4.4: medical wind-up tick scrubs leaked PA (**`process_medical_wind_up`**).
