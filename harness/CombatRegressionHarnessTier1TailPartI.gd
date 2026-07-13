class_name CombatRegressionHarnessTier1TailPartI
extends RefCounted

## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_stamp_attack_pair_geometry_depth_lane_flags_consistent(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "stamp_depth_geom: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var fd: Dictionary = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    var live_tight: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
    var pa: Dictionary = {}
    CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa)
    if bool(pa.get("depth_polearm_attack", false)) != true:
        CombatRegressionHarness._fail(failures, "stamp_depth_geom: expected depth_polearm_attack true")
    var stamped_allow: bool = bool(pa.get("depth_polearm_allows_low_targets", true))
    if stamped_allow != live_tight:
        CombatRegressionHarness._fail(
            failures,
            "stamp_depth_geom: allows_low stamped=%s live=%s (strict tight)" % [str(stamped_allow), str(live_tight)]
        )
    var lt: String = str(pa.get("depth_polearm_lane_type", ""))
    var expect_lt: String = (
        CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
        if live_tight
        else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
    )
    if lt != expect_lt:
        CombatRegressionHarness._fail(
            failures, "stamp_depth_geom: lane_type=%s expected %s (strict tight)" % [lt, expect_lt]
        )
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
    fd = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    var live_open: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
    var pa2: Dictionary = {}
    CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa2)
    if bool(pa2.get("depth_polearm_allows_low_targets", false)) != live_open:
        CombatRegressionHarness._fail(
            failures,
            (
                "stamp_depth_geom: allows_low stamped=%s live=%s (profile open)"
                % [str(pa2.get("depth_polearm_allows_low_targets")), str(live_open)]
            )
        )
    var lt2: String = str(pa2.get("depth_polearm_lane_type", ""))
    var expect_lt2: String = (
        CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
        if live_open
        else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
    )
    if lt2 != expect_lt2:
        CombatRegressionHarness._fail(
            failures, "stamp_depth_geom: lane_type=%s expected %s (profile open)" % [lt2, expect_lt2]
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** leaves **`depth_polearm_*`** at non-depth defaults when
## attacker is rank **0** or rank **>0** with **`depth_polearm_lane_open`** **false**.


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** leaves **`depth_polearm_*`** at non-depth defaults when
## attacker is rank **0** or rank **>0** with **`depth_polearm_lane_open`** **false**.
static func _run_stamp_attack_pair_geometry_depth_defaults_non_depth_attack(failures: PackedStringArray) -> void:
    var m0: Node = CombatManager.new()
    m0.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    m0.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var atk0: Dictionary = m0.combatants[0]
    var en0: Dictionary = m0.combatants[1]
    if CombatantEntityAccess.rank_int(atk0) != 0:
        CombatRegressionHarness._fail(failures, "stamp_depth_def: expected rank-0 spear")
        CombatRegressionHarness._free_manager(m0)
        return
    var pa0: Dictionary = {}
    CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(m0, atk0, en0, pa0)
    CombatRegressionHarness._assert_stamp_depth_pa_defaults(pa0, failures, "stamp_depth_def:rank0")
    CombatRegressionHarness._free_manager(m0)

    var m1: Node = CombatManager.new()
    m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m1.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p1: Dictionary = {"files": 1, "ranks": 2, "density": "normal"}
    var e1: Dictionary = {"files": 1, "ranks": 1, "density": "normal"}
    m1.start(p1, e1)
    var atk1: Dictionary = m1.combatants[1]
    var en1: Dictionary = m1.combatants[2]
    if CombatantEntityAccess.rank_int(atk1) <= 0:
        CombatRegressionHarness._fail(failures, "stamp_depth_def: expected rank-1 sword")
        CombatRegressionHarness._free_manager(m1)
        return
    if CombatDepthPolearm.depth_polearm_lane_open(m1, atk1):
        CombatRegressionHarness._fail(failures, "stamp_depth_def: rank-1 sword should not open depth lane")
        CombatRegressionHarness._free_manager(m1)
        return
    var pa1: Dictionary = {}
    CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(m1, atk1, en1, pa1)
    CombatRegressionHarness._assert_stamp_depth_pa_defaults(pa1, failures, "stamp_depth_def:rank1_no_lane")
    CombatRegressionHarness._free_manager(m1)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** drops legs iff **`depth_polearm_lane_allows_low_targets`**
## (**`assume_depth_lane_open` true**) is **false** (same strict/tight vs **`spear_lane_profile` open** flip as other
## depth harnesses).


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** drops legs iff **`depth_polearm_lane_allows_low_targets`**
## (**`assume_depth_lane_open` true**) is **false** (same strict/tight vs **`spear_lane_profile` open** flip as other
## depth harnesses).
static func _run_depth_polearm_parts_filter_tracks_allows_low(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_parts_al: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var fd: Dictionary = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    if CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
        CombatRegressionHarness._fail(
            failures, "depth_parts_al: strict+tight should not allow low targets before filter assert"
        )
    var filt_tight: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_parts_al: filter should drop legs when allows_low false (got %s)" % str(filt_tight)
        )
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
    fd = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    if not CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
        CombatRegressionHarness._fail(
            failures, "depth_parts_al: open profile should allow low targets before filter assert"
        )
    var filt_open: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not filt_open.has("left_leg") or not filt_open.has("right_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_parts_al: filter should keep legs when allows_low true (got %s)" % str(filt_open)
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`lane_stress_by_file`** at depth file opens lows under **strict**/**tight** (no **`spear_lane_profile`
## open**)  -  **`depth_polearm_lane_allows_low_targets`** + **`depth_polearm_targetable_parts_filter`**.


## Tier 1.9: **`lane_stress_by_file`** at depth file opens lows under **strict**/**tight** (no **`spear_lane_profile`
## open**)  -  **`depth_polearm_lane_allows_low_targets`** + **`depth_polearm_targetable_parts_filter`**.
static func _run_depth_polearm_parts_filter_wedge_opens_legs_strict_tight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_parts_wedge: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    var df: int = CombatantEntityAccess.file_int(depth, 0)
    mgr.formations["player"]["lane_stress_by_file"] = {df: 0.85}
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var fd: Dictionary = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    if not CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
        CombatRegressionHarness._fail(
            failures, "depth_parts_wedge: lane stress should open low targets under strict+tight"
        )
    var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
    var filt: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not filt.has("left_leg") or not filt.has("right_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_parts_wedge: filter should keep legs when wedge opens lane (got %s)" % str(filt)
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`spear_lane_profile` restricted**  -  **`depth_polearm_lane_allows_low_targets`** is **false** without
## lane stress, **true** when **`lane_stress_by_file`** exceeds threshold ( **`depth_polearm_targetable_parts_filter`**
## follows).


## Tier 1.9: **`spear_lane_profile` restricted**  -  **`depth_polearm_lane_allows_low_targets`** is **false** without
## lane stress, **true** when **`lane_stress_by_file`** exceeds threshold ( **`depth_polearm_targetable_parts_filter`**
## follows).
static func _run_depth_polearm_restricted_profile_requires_lane_stress_for_allows_low(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_prof_rest: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["density"] = "loose"
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = (
        CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
    )
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var fd: Dictionary = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    if CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
        CombatRegressionHarness._fail(
            failures, "depth_prof_rest: restricted + loose should not allow lows without wedge"
        )
    var parts_in: Array = ["head", "left_leg", "right_leg"]
    var filt_no_w: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if filt_no_w.has("left_leg") or filt_no_w.has("right_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_prof_rest: filter should drop legs without wedge (got %s)" % str(filt_no_w)
        )
    var df: int = CombatantEntityAccess.file_int(depth, 0)
    mgr.formations["player"]["lane_stress_by_file"] = {df: 0.85}
    fd = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    if not CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
        CombatRegressionHarness._fail(
            failures, "depth_prof_rest: lane stress should allow lows under restricted profile"
        )
    var filt_w: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not filt_w.has("left_leg") or not filt_w.has("right_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_prof_rest: filter should keep legs after wedge (got %s)" % str(filt_w)
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** with explicit **`formation_dict_cache`** (deep copy of live
## dict) matches **`null`** cache (same **`fid`**, **`assume_depth_lane_open` true**).


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** with explicit **`formation_dict_cache`** (deep copy of live
## dict) matches **`null`** cache (same **`fid`**, **`assume_depth_lane_open` true**).
static func _run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_al_fd_cache: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var fd: Dictionary = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    var fd_dup: Dictionary = fd.duplicate(true)
    var a_tight: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
    var b_tight: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
    if a_tight != b_tight:
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_al_fd_cache: null vs dict cache mismatch strict+tight (null=%s cache=%s)"
                % [str(a_tight), str(b_tight)]
            )
        )
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
    fd = ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
    fd_dup = fd.duplicate(true)
    var a_open: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
    var b_open: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
    if a_open != b_open:
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_al_fd_cache: null vs dict cache mismatch profile open (null=%s cache=%s)"
                % [str(a_open), str(b_open)]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** is a **pass-through** when **`depth_polearm_lane_open`** is
## **false** (rank-1 non-polearm) or attacker **`rank` <= 0** (no depth lane use).


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** is a **pass-through** when **`depth_polearm_lane_open`** is
## **false** (rank-1 non-polearm) or attacker **`rank` <= 0** (no depth lane use).
static func _run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures: PackedStringArray) -> void:
    var m0: Node = CombatManager.new()
    m0.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    m0.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var atk0: Dictionary = m0.combatants[0]
    if CombatantEntityAccess.rank_int(atk0) != 0:
        CombatRegressionHarness._fail(failures, "depth_parts_pass: expected rank-0 attacker")
        CombatRegressionHarness._free_manager(m0)
        return
    var parts0: Array = ["head", "left_leg", "right_leg"]
    var out0: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(m0, atk0, parts0)
    if out0 != parts0:
        CombatRegressionHarness._fail(failures, "depth_parts_pass: rank-0 should not filter parts (got %s)" % str(out0))
    CombatRegressionHarness._free_manager(m0)

    var m1: Node = CombatManager.new()
    m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    m1.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var atk1: Dictionary = m1.combatants[1]
    if CombatantEntityAccess.rank_int(atk1) <= 0:
        CombatRegressionHarness._fail(failures, "depth_parts_pass: expected rank-1 sword")
        CombatRegressionHarness._free_manager(m1)
        return
    if CombatDepthPolearm.depth_polearm_lane_open(m1, atk1):
        CombatRegressionHarness._fail(failures, "depth_parts_pass: rank-1 sword should not open depth lane")
        CombatRegressionHarness._free_manager(m1)
        return
    var parts1: Array = ["head", "left_leg"]
    var out1: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(m1, atk1, parts1)
    if out1 != parts1:
        CombatRegressionHarness._fail(
            failures, "depth_parts_pass: lane closed should not filter parts (got %s)" % str(out1)
        )
    CombatRegressionHarness._free_manager(m1)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`**  -  **`assume_depth_lane_open` false** returns **true** when
## **`depth_polearm_lane_open`** is **false** (depth lane N/A); **`assume_depth_lane_open` true** skips that guard and
## runs wedge / **`spear_lane_profile`** / discipline (strict+tight -> **false** without open profile).


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`**  -  **`assume_depth_lane_open` false** returns **true** when
## **`depth_polearm_lane_open`** is **false** (depth lane N/A); **`assume_depth_lane_open` true** skips that guard and
## runs wedge / **`spear_lane_profile`** / discipline (strict+tight -> **false** without open profile).
static func _run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth: Dictionary = mgr.combatants[1]
    if CombatantEntityAccess.rank_int(depth) <= 0:
        CombatRegressionHarness._fail(failures, "depth_al_assume: expected rank-1 depth combatant")
        CombatRegressionHarness._free_manager(mgr)
        return
    if CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_al_assume: rank-1 sword must not open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var without_assume: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
    var with_assume: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
    if not without_assume:
        CombatRegressionHarness._fail(
            failures, "depth_al_assume: lane closed + assume false should return true (depth lane N/A)"
        )
    if with_assume:
        CombatRegressionHarness._fail(
            failures,
            "depth_al_assume: strict+tight + assume true should evaluate lane rules -> false (no open profile)"
        )
    if without_assume == with_assume:
        CombatRegressionHarness._fail(
            failures, "depth_al_assume: assume flag must change result when lane closed vs strict+tight body"
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_lane_allows_low_targets`** returns the
## same value whether **`assume_depth_lane_open`** is **false** or **true** (closed-lane early exit skipped in both
## cases once the lane is open).


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_lane_allows_low_targets`** returns the
## same value whether **`assume_depth_lane_open`** is **false** or **true** (closed-lane early exit skipped in both
## cases once the lane is open).
static func _run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_al_agree: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, depth)
    var tight_no_assume: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
    var tight_with_assume: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
    if tight_no_assume != tight_with_assume:
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_al_agree: strict+tight assume false vs true mismatch (%s vs %s)"
                % [str(tight_no_assume), str(tight_with_assume)]
            )
        )
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
    var open_no_assume: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
    var open_with_assume: bool = CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
    if open_no_assume != open_with_assume:
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_al_agree: profile open assume false vs true mismatch (%s vs %s)"
                % [str(open_no_assume), str(open_with_assume)]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets(manager, c, "", ...)`** matches **`...(manager, c, fid, ...)`**
## when **`fid == zone_geometry_fid_str(manager, c)`**  -  same **`zone_geometry_fid`** contract as
## **`depth_polearm_lane_open`** / **`formation_for_combatant_cached`**. Covers **`assume_depth_lane_open` false +
## true** on **home** line.


## Tier 1.9: **`depth_polearm_lane_allows_low_targets(manager, c, "", ...)`** matches **`...(manager, c, fid, ...)`**
## when **`fid == zone_geometry_fid_str(manager, c)`**  -  same **`zone_geometry_fid`** contract as
## **`depth_polearm_lane_open`** / **`formation_for_combatant_cached`**. Covers **`assume_depth_lane_open` false +
## true** on **home** line.
static func _run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    CombatRegressionHarness._assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, "depth_al_fid_rt:home")
    CombatRegressionHarness._free_manager(mgr)


static func _run_depth_polearm_auto_lane_discipline_posture(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "tight"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    var f_strict: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if f_strict.has("left_leg") or f_strict.has("right_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_auto_lane: strict discipline + tight should filter legs (got %s)" % str(f_strict)
        )
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
    var f_loose_disc: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not f_loose_disc.has("left_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_auto_lane: loose discipline + tight should allow legs (got %s)" % str(f_loose_disc)
        )
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
    mgr.formations["player"]["density"] = "loose"
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    var f_loose_dens_strict: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if f_loose_dens_strict.has("left_leg") or f_loose_dens_strict.has("right_leg"):
        CombatRegressionHarness._fail(
            failures,
            "depth_auto_lane: strict should override loose density for legs (got %s)" % str(f_loose_dens_strict)
        )
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
    mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
    var f_open_post: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not f_open_post.has("left_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_auto_lane: OPEN posture + tight should allow legs (got %s)" % str(f_open_post)
        )
    mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_DUEL
    var f_duel_post: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not f_duel_post.has("left_leg"):
        CombatRegressionHarness._fail(
            failures, "depth_auto_lane: DUEL posture + tight should allow legs (got %s)" % str(f_duel_post)
        )
    # LINE posture + normal discipline + tight: auto profile stays over-shoulder (stamped `pa` agrees).
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
    mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
    var f_line_norm: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if f_line_norm.has("left_leg") or f_line_norm.has("right_leg"):
        CombatRegressionHarness._fail(
            failures,
            "depth_auto_lane: LINE posture + normal discipline + tight should filter legs (got %s)" % str(f_line_norm)
        )
    var pa_ln: Dictionary = {}
    var en0: Dictionary = mgr.combatants[2]
    CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, en0, pa_ln)
    if bool(pa_ln.get("depth_polearm_allows_low_targets", true)):
        CombatRegressionHarness._fail(
            failures, "depth_auto_lane: stamped allows_low false for LINE+normal+tight depth attack"
        )
    if str(pa_ln.get("depth_polearm_lane_type", "")) != CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER:
        CombatRegressionHarness._fail(
            failures,
            "depth_auto_lane: stamped lane_type over_shoulder got %s" % str(pa_ln.get("depth_polearm_lane_type"))
        )
    # Empty formation field falls back to encounter discipline (same as posture / fall-back policy).
    mgr.formations["player"]["line_discipline"] = ""
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
    mgr.encounter[CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE] = CombatConstants.LINE_DISCIPLINE_STRICT
    var f_enc_strict: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if f_enc_strict.has("left_leg") or f_enc_strict.has("right_leg"):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_auto_lane: encounter strict with empty formation discipline should filter legs (got %s)"
                % str(f_enc_strict)
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: pinch `wing_lacks_file_opposed` uses same-file rank-0 partner when depth spear lane is open.


## Tier 1.6: pinch `wing_lacks_file_opposed` uses same-file rank-0 partner when depth spear lane is open.
static func _run_wing_lacks_depth_polearm(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    var depth_spear: Dictionary = {}
    var front_f1: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        var w: Variant = CombatantEntityAccess.get_weapon(c)
        if (
            w != null
            and w is Weapon
            and CombatantEntityAccess.rank_int(c) == 1
            and CombatantEntityAccess.file_int(c) == 1
        ):
            if (w as Weapon).depth_melee_eligible:
                depth_spear = c
        if CombatantEntityAccess.rank_int(c) == 0 and CombatantEntityAccess.file_int(c) == 1:
            front_f1 = c
    var front_f0: Dictionary = {}
    for c in mgr.combatants:
        if (
            CombatantEntityAccess.is_player_side(c)
            and CombatantEntityAccess.rank_int(c) == 0
            and CombatantEntityAccess.file_int(c) == 0
        ):
            front_f0 = c
            break
    if depth_spear.is_empty() or front_f1.is_empty() or front_f0.is_empty():
        CombatRegressionHarness._fail(failures, "wing_depth: expected 2- - 2 player grid with spear at rank1 file1")
        return
    if CombatTargetScoring.wing_lacks_file_opposed(mgr, front_f1):
        CombatRegressionHarness._fail(failures, "wing_depth: rank0 file1 should map to sole enemy file0 (nearest wing)")
    if CombatTargetScoring.wing_lacks_file_opposed(mgr, front_f0):
        CombatRegressionHarness._fail(failures, "wing_depth: rank0 file0 should have file-opposed enemy")
    if CombatTargetScoring.wing_lacks_file_opposed(mgr, depth_spear):
        CombatRegressionHarness._fail(failures, "wing_depth: depth spear should inherit front file1 mapped opposition")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: depth rank spear listing weights vs formation doctrine
## (`CombatAIActionPicker._depth_polearm_action_weight_mult`).


## Tier 1.9: depth rank spear listing weights vs formation doctrine
## (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
static func _run_depth_polearm_doctrine_action_weights(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_doc_weights: expected open depth polearm lane")
        CombatRegressionHarness._free_manager(mgr)
        return
    var w_base_stab: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
    var w_base_slash: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var w_pinch_stab: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
    var w_pinch_slash: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    var w_hold_stab: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
    var w_hold_slash: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
    var w_probe_stab: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
    var w_probe_slash: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
    if w_pinch_stab <= w_base_stab + 0.001:
        CombatRegressionHarness._fail(failures, "depth_doc_weights: pinch should raise stab vs default")
    if w_hold_stab >= w_base_stab - 0.001:
        CombatRegressionHarness._fail(failures, "depth_doc_weights: hold should lower stab vs default")
    if w_pinch_slash >= w_base_slash - 0.001:
        CombatRegressionHarness._fail(failures, "depth_doc_weights: pinch should lower non-stab vs default")
    if w_hold_slash <= w_base_slash + 0.001:
        CombatRegressionHarness._fail(failures, "depth_doc_weights: hold should raise non-stab vs default")
    if w_probe_stab <= w_hold_stab + 1e-5 or w_probe_stab >= w_pinch_stab - 1e-5:
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_doc_weights: probing stab should sit strictly between hold and pinch hold=%.6f probe=%.6f pi"
                + "nch=%.6f" % [w_hold_stab, w_probe_stab, w_pinch_stab]
            )
        )
    if w_probe_slash <= w_pinch_slash + 1e-5 or w_probe_slash >= w_hold_slash - 1e-5:
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_doc_weights: probing non-stab should sit strictly between pinch and hold pinch=%.6f probe=%."
                + "6f hold=%.6f" % [w_pinch_slash, w_probe_slash, w_hold_slash]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: optional encounter + preset **`depth_polearm_ai_doctrine_mults`** merged at **`CombatManager.start`**
## (preset wins; clamp **`DEPTH_POLEARM_AI_MULT_OVERRIDE_*`**).


## Tier 1.9: optional encounter + preset **`depth_polearm_ai_doctrine_mults`** merged at **`CombatManager.start`**
## (preset wins; clamp **`DEPTH_POLEARM_AI_MULT_OVERRIDE_*`**).
static func _run_depth_polearm_ai_doctrine_mults_encounter_preset(failures: PackedStringArray) -> void:
    var pinch_k: String = CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB
    var pinch_def: float = CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT
    var merged_clamp: Dictionary = CombatConstants.merge_depth_polearm_ai_doctrine_mults(
        CombatConstants.default_depth_polearm_ai_doctrine_mults_dict(), {pinch_k: 9.0}
    )
    if not is_equal_approx(float(merged_clamp[pinch_k]), CombatConstants.DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_ai_mults: clamp max want %.4f got %.4f"
                % [CombatConstants.DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX, float(merged_clamp[pinch_k])]
            )
        )
    var mgr0: Node = CombatManager.new()
    mgr0.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr0.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr0.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr0.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth0: Dictionary = mgr0.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr0, depth0):
        CombatRegressionHarness._fail(failures, "depth_ai_mults: expected open depth polearm lane (baseline)")
        CombatRegressionHarness._free_manager(mgr0)
        return
    mgr0.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var w0: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr0, depth0, "spear_thrust")
    if not is_equal_approx(w0, CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * pinch_def):
        CombatRegressionHarness._fail(failures, "depth_ai_mults: baseline pinch stab mult mismatch got %.6f" % w0)
    var mgr1: Node = CombatManager.new()
    mgr1.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER] = {pinch_k: 1.26}
    mgr1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr1.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr1.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth1: Dictionary = mgr1.combatants[1]
    mgr1.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var w1: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr1, depth1, "spear_thrust")
    var expect_enc: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * 1.26
    if not is_equal_approx(w1, expect_enc):
        CombatRegressionHarness._fail(
            failures, "depth_ai_mults: encounter pinch override want %.6f got %.6f" % [expect_enc, w1]
        )
    if not is_equal_approx(w1 / w0, 1.26 / pinch_def):
        CombatRegressionHarness._fail(failures, "depth_ai_mults: encounter ratio vs default pinch")
    var p_preset: Dictionary = {
        "files": 1,
        "ranks": 2,
        "density": "normal",
        CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS: {pinch_k: 1.44},
    }
    var mgr2: Node = CombatManager.new()
    mgr2.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER] = {pinch_k: 1.2}
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr2.start(p_preset, {"files": 1, "ranks": 1, "density": "normal"})
    var depth2: Dictionary = mgr2.combatants[1]
    mgr2.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var w2: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr2, depth2, "spear_thrust")
    var expect_preset: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * 1.44
    if not is_equal_approx(w2, expect_preset):
        CombatRegressionHarness._fail(
            failures, "depth_ai_mults: preset should win over encounter want %.6f got %.6f" % [expect_preset, w2]
        )
    var mgr3: Node = CombatManager.new()
    mgr3.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY] = {pinch_k: 1.11}
    mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr3.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    if not is_equal_approx(mgr3.get_depth_polearm_ai_doctrine_mult("enemy", pinch_k), 1.11):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_ai_mults: enemy encounter mult got %s"
                % str(mgr3.get_depth_polearm_ai_doctrine_mult("enemy", pinch_k))
            )
        )
    if not is_equal_approx(mgr3.get_depth_polearm_ai_doctrine_mult("player", pinch_k), pinch_def):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_ai_mults: player pinch should stay default got %s"
                % str(mgr3.get_depth_polearm_ai_doctrine_mult("player", pinch_k))
            )
        )
    CombatRegressionHarness._free_manager(mgr0)
    CombatRegressionHarness._free_manager(mgr1)
    CombatRegressionHarness._free_manager(mgr2)
    CombatRegressionHarness._free_manager(mgr3)


## Tier 1.9: **`CombatAIActionPicker._depth_polearm_action_weight_mult`** stays neutral (**1.0**) when no
## **`depth_polearm_valid_line_threat`** to any hostile rank 0 (lane may still be open); boosts stab when **3-wide**
## yields >=1 valid line.


## Tier 1.9: **`CombatAIActionPicker._depth_polearm_action_weight_mult`** stays neutral (**1.0**) when no
## **`depth_polearm_valid_line_threat`** to any hostile rank 0 (lane may still be open); boosts stab when **3-wide**
## yields >=1 valid line.
static func _run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures: PackedStringArray) -> void:
    var mgr_far: Node = CombatManager.new()
    mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_far.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    for _i in 3:
        mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr_far.recompute_zoc_and_distance()
    var depth_far: Dictionary = mgr_far.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr_far, depth_far):
        CombatRegressionHarness._fail(failures, "ai_vlt_any: expected open lane")
        CombatRegressionHarness._free_manager(mgr_far)
        return
    for i in range(2, 5):
        (mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
    mgr_far.recompute_zoc_and_distance()
    if CombatDepthPolearm.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(
        mgr_far, depth_far, mgr_far.combatants
    ):
        CombatRegressionHarness._fail(failures, "ai_vlt_any: expected no valid-line rank-0 hostile after pushing files")
        CombatRegressionHarness._free_manager(mgr_far)
        return
    var w_neutral_stab: float = CombatAIActionPicker._depth_polearm_action_weight_mult(
        mgr_far, depth_far, "spear_thrust"
    )
    var w_neutral_close: float = CombatAIActionPicker._depth_polearm_action_weight_mult(
        mgr_far, depth_far, CombatConstants.MOVE_ID_ATTEMPT_CLOSE
    )
    if absf(w_neutral_stab - 1.0) > 0.001 or absf(w_neutral_close - 1.0) > 0.001:
        CombatRegressionHarness._fail(
            failures,
            "ai_vlt_any: far-line AI mult should be 1.0 stab=%s close=%s" % [str(w_neutral_stab), str(w_neutral_close)]
        )
    CombatRegressionHarness._free_manager(mgr_far)
    var mgr3: Node = CombatManager.new()
    mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr3.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    for _j in 3:
        mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr3.recompute_zoc_and_distance()
    var depth3: Dictionary = mgr3.combatants[1]
    if not CombatDepthPolearm.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr3, depth3, mgr3.combatants):
        CombatRegressionHarness._fail(failures, "ai_vlt_any: standard 3-wide should have >=1 valid-line rank-0 target")
        CombatRegressionHarness._free_manager(mgr3)
        return
    var w_boost: float = CombatAIActionPicker._depth_polearm_action_weight_mult(mgr3, depth3, "spear_thrust")
    if w_boost <= 1.001:
        CombatRegressionHarness._fail(
            failures, "ai_vlt_any: standard layout should boost stab mult got %s" % str(w_boost)
        )
    CombatRegressionHarness._free_manager(mgr3)


## Option 4: `CombatDoctrine.enemy_line_hollow_center_for_pinch` (automatic pinch trigger when
## `FEATURE_AUTOMATIC_DOCTRINE` is enabled).


## Option 4: `CombatDoctrine.enemy_line_hollow_center_for_pinch` (automatic pinch trigger when
## `FEATURE_AUTOMATIC_DOCTRINE` is enabled).
static func _run_doctrine_hollow_center_pinch_heuristic(failures: PackedStringArray) -> void:
    CombatDoctrine.evaluate_automatic_doctrine(null)
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
    var en_by_file: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_enemy_side(c):
            continue
        en_by_file[CombatantEntityAccess.file_int(c)] = c
    if en_by_file.size() < 3:
        CombatRegressionHarness._fail(failures, "doctrine_hollow: expected 3 enemies")
        CombatRegressionHarness._free_manager(mgr)
        return
    (en_by_file[1] as Dictionary)["alive"] = false
    if not CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
        CombatRegressionHarness._fail(
            failures, "doctrine_hollow: 3-file line with dead center should read as hollow for pinch"
        )
    (en_by_file[1] as Dictionary)["alive"] = true
    if CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
        CombatRegressionHarness._fail(failures, "doctrine_hollow: full enemy front should not be hollow")
    (en_by_file[1] as Dictionary)["alive"] = false
    (en_by_file[2] as Dictionary)["alive"] = false
    if CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
        CombatRegressionHarness._fail(failures, "doctrine_hollow: single-wing line should not qualify as hollow center")
    CombatRegressionHarness._free_manager(mgr)

    var mgr4: Node = CombatManager.new()
    mgr4.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _k in 4:
        mgr4.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr4.start({"files": 1, "ranks": 1}, {"files": 4, "ranks": 1})
    var en4: Dictionary = {}
    for c in mgr4.combatants:
        if CombatantEntityAccess.is_enemy_side(c):
            en4[CombatantEntityAccess.file_int(c)] = c
    for kill_i in [1, 2]:
        (en4[kill_i] as Dictionary)["alive"] = false
    if not CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr4, "player"):
        CombatRegressionHarness._fail(
            failures, "doctrine_hollow: 4-file empty middle pair + living wings should be hollow"
        )
    CombatRegressionHarness._free_manager(mgr4)


static func _run_doctrine_normalize_and_manager_roundtrip(failures: PackedStringArray) -> void:
    if CombatDoctrine.normalize("") != CombatConstants.DOCTRINE_DEFAULT:
        CombatRegressionHarness._fail(failures, "doctrine_norm: empty string should be default")
    if CombatDoctrine.normalize("  \t ") != CombatConstants.DOCTRINE_DEFAULT:
        CombatRegressionHarness._fail(failures, "doctrine_norm: whitespace-only should be default")
    if CombatDoctrine.normalize("pinch") != CombatConstants.DOCTRINE_PINCH_CENTER:
        CombatRegressionHarness._fail(failures, "doctrine_norm: pinch alias")
    if CombatDoctrine.normalize("PINCH_CENTER") != CombatConstants.DOCTRINE_PINCH_CENTER:
        CombatRegressionHarness._fail(failures, "doctrine_norm: canonical pinch_center")
    if CombatDoctrine.normalize("pincer") != CombatConstants.DOCTRINE_PINCH_CENTER:
        CombatRegressionHarness._fail(failures, "doctrine_norm: pincer alias")
    if CombatDoctrine.normalize("hold") != CombatConstants.DOCTRINE_HOLD_LANE:
        CombatRegressionHarness._fail(failures, "doctrine_norm: hold alias")
    if CombatDoctrine.normalize("probing") != CombatConstants.DOCTRINE_PROBING:
        CombatRegressionHarness._fail(failures, "doctrine_norm: probing alias")
    if CombatDoctrine.normalize(CombatConstants.DOCTRINE_PROBING) != CombatConstants.DOCTRINE_PROBING:
        CombatRegressionHarness._fail(failures, "doctrine_norm: probing canonical")
    if CombatDoctrine.normalize("not_a_real_doctrine_string") != CombatConstants.DOCTRINE_DEFAULT:
        CombatRegressionHarness._fail(failures, "doctrine_norm: unknown -> default")
    if CombatDoctrine.doctrine_for_fid(null, "player") != CombatConstants.DOCTRINE_DEFAULT:
        CombatRegressionHarness._fail(failures, "doctrine_for_fid: null manager -> default")
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.set_formation_doctrine("player", "  pincer  ")
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        CombatRegressionHarness._fail(
            failures, "doctrine_roundtrip: player got %s want pinch_center" % mgr.get_formation_doctrine("player")
        )
    mgr.set_formation_doctrine("player", "  probing  ")
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        CombatRegressionHarness._fail(
            failures,
            (
                "doctrine_rt: set probing expected %s got %s"
                % [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
            )
        )
    mgr.set_formation_doctrine("enemy", "bogus_doctrine_value")
    if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_DEFAULT:
        CombatRegressionHarness._fail(
            failures,
            "doctrine_roundtrip: enemy unknown should store default got %s" % mgr.get_formation_doctrine("enemy")
        )
    CombatRegressionHarness._free_manager(mgr)

## Tier 1.9: **`encounter`** + optional **`start()`** preset dicts seed **`formation_doctrine`**
## (`ENCOUNTER_KEY_FORMATION_DOCTRINE_*`, else encounter alt keys, then preset **`FORMATION_PRESET_KEY_DOCTRINE`** or
## **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, via **`CombatConstants.formation_doctrine_string_from_dict`** for presets).
