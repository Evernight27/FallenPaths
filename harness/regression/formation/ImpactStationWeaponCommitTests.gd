class_name ImpactStationWeaponCommitTests
extends CombatRegressionHarnessCore
## IV-7b: low stamina dampens attack / close listing weights via canonical engage floor.
static func _run_iv7b_stamina_engage_floor_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv7b_stamina_engage_doc_sync_line()
    if not sync_line.contains("ratio<0.20"):
        _fail(failures, "iv7b_engage: sync line want floor 0.20 in %s" % sync_line)
    if not is_equal_approx(CombatConstants.ai_offense_stamina_weight_mult(0.25), 1.0):
        _fail(failures, "iv7b_engage: above floor want mult 1.0")
    if not is_equal_approx(
        CombatConstants.ai_offense_stamina_weight_mult(0.15), CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT
    ):
        _fail(failures, "iv7b_engage: below floor want mult %.2f" % CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    p["gauge"] = 100.0
    p["stamina"] = CombatConstants.STAMINA_MAX * 0.15
    var act: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var w_low: float = _AIPicker._get_action_weight(act, p_id, mgr, true)
    p["stamina"] = CombatConstants.STAMINA_MAX * 0.50
    var w_hi: float = _AIPicker._get_action_weight(act, p_id, mgr, true)
    _free_manager(mgr)
    if w_low <= 0.0 or w_hi <= 0.0:
        _fail(failures, "iv7b_engage: want positive attack weights low=%.4f hi=%.4f" % [w_low, w_hi])
        return
    var ratio: float = w_low / w_hi
    if absf(ratio - CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT) > 0.02:
        _fail(
            failures,
            (
                "iv7b_engage: attack weight ratio want %.2f got %.3f (low=%.4f hi=%.4f)"
                % [CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT, ratio, w_low, w_hi]
            )
        )


## Tier 0: hit during **`STATE_SWAP_RANK`** extends duration and delays resolve event (does not cancel).


## Tier 0: hit during **`STATE_SWAP_RANK`** extends duration and delays resolve event (does not cancel).
static func _run_formation_hit_reaction_extends_pair_move_duration(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2}, {"files": 2, "ranks": 2})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c):
            continue
        if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 0:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "form_hit_rx: need rank-0/1 same-file pair")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    var dur_before: float = float(p0.get("state_duration", -1.0))
    var resolve_before: float = -1.0
    for ev in mgr.event_queue:
        if typeof(ev) != TYPE_DICTIONARY:
            continue
        var evd: Dictionary = ev as Dictionary
        if (
            str(evd.get("type", "")) == CombatConstants.EVENT_SWAP_RANK_RESOLVE
            and int(evd.get("combatant_id", -1)) == id0
        ):
            resolve_before = float(evd.get("resolve_at", -1.0))
            break
    _FormationFlow.apply_hit_reaction_if_needed(mgr, id0, 0.35)
    var dur_after: float = float(p0.get("state_duration", -1.0))
    var resolve_after: float = resolve_before
    for ev in mgr.event_queue:
        if typeof(ev) != TYPE_DICTIONARY:
            continue
        var evd2: Dictionary = ev as Dictionary
        if (
            str(evd2.get("type", "")) == CombatConstants.EVENT_SWAP_RANK_RESOLVE
            and int(evd2.get("combatant_id", -1)) == id0
        ):
            resolve_after = float(evd2.get("resolve_at", -1.0))
            break
    _free_manager(mgr)
    if dur_after <= dur_before + 0.05:
        _fail(failures, "form_hit_rx: duration want increase before=%.3f after=%.3f" % [dur_before, dur_after])
    if resolve_before < 0.0 or resolve_after <= resolve_before + 0.05:
        _fail(failures, "form_hit_rx: resolve_at want bump before=%.3f after=%.3f" % [resolve_before, resolve_after])


## Tier 0: hard hit during pair formation move aborts to waiting and removes resolve event.


## Tier 0: hard hit during pair formation move aborts to waiting and removes resolve event.
static func _run_formation_hit_cancel_aborts_pair_move(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2}, {"files": 2, "ranks": 2})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c):
            continue
        if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 0:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "form_hit_cancel: need rank-0/1 same-file pair")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    _FormationFlow.apply_hit_reaction_if_needed(mgr, id0, 0.9)
    var st0: String = _EntityAccess.state_str(p0)
    var st1: String = _EntityAccess.state_str(p1)
    var resolve_left: bool = false
    for ev in mgr.event_queue:
        if typeof(ev) != TYPE_DICTIONARY:
            continue
        var evd: Dictionary = ev as Dictionary
        if str(evd.get("type", "")) != CombatConstants.EVENT_SWAP_RANK_RESOLVE:
            continue
        var cid: int = int(evd.get("combatant_id", -1))
        var dr: Variant = evd.get("data", null)
        var pid: int = -1
        if dr is Dictionary:
            pid = int((dr as Dictionary).get("partner_id", -1))
        if cid == id0 or cid == id1 or pid == id0 or pid == id1:
            resolve_left = true
            break
    _free_manager(mgr)
    if st0 != CombatConstants.STATE_WAITING or st1 != CombatConstants.STATE_WAITING:
        _fail(failures, "form_hit_cancel: want both waiting got init=%s partner=%s" % [st0, st1])
    if resolve_left:
        _fail(failures, "form_hit_cancel: swap_rank_resolve should be removed")


## Tier 0 pilot: overlapping wind-ups  -  parry commitment follows highest threat only.


## Tier 0 pilot: overlapping wind-ups  -  parry commitment follows highest threat only.
static func _run_incoming_parry_choice_blocks_non_chosen_attacker(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        _fail(failures, "incoming_parry: FEATURE_INCOMING_PARRY_CHOICE should be enabled")
        return
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    p["gauge"] = 100.0
    e0["gauge"] = 100.0
    e1["gauge"] = 100.0
    _WindUpStarter.start(mgr, e0_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e0, "pending_attack")["intensity"] = 1.0
    _WindUpStarter.start(mgr, e1_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e1, "pending_attack")["intensity"] = 0.95
    var resolve_at: float = _EntityAccess.combat_clock_plus(mgr, float(e0.get("state_duration", 0.5)))
    for aid in [e0_id, e1_id]:
        (
            _EntityAccess
            . manager_schedule_event(
                mgr,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": aid,
                    "resolve_at": resolve_at,
                    "data": {},
                }
            )
        )
    var incoming: Array = _IncomingParryChoice.incoming_attacker_ids_on_defender(mgr, p_id, resolve_at)
    if incoming.size() < 2:
        _fail(failures, "incoming_parry: want 2 incoming attackers got %s" % str(incoming))
        _free_manager_restore_global_rng(mgr)
        return
    var s0: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e0_id)
    var s1: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e1_id)
    if s0 <= s1:
        _fail(
            failures,
            (
                "incoming_parry: threat e0=%.3f e1=%.3f i0=%.2f i1=%.2f"
                % [
                    s0,
                    s1,
                    float(_EntityAccess.nested_dictionary_read(e0, "pending_attack").get("intensity", -1.0)),
                    float(_EntityAccess.nested_dictionary_read(e1, "pending_attack").get("intensity", -1.0)),
                ]
            )
        )
    if _IncomingParryChoice.can_parry_all(mgr, p_id, resolve_at):
        _fail(failures, "incoming_parry: dual heavy pair should fail can_parry_all")
    var chosen: int = _IncomingParryChoice.choose_parry_target_attacker_id(mgr, p_id, resolve_at)
    if chosen != e0_id:
        _fail(
            failures,
            (
                "incoming_parry: want higher-intensity e0 chosen got %d (i0=%.2f i1=%.2f)"
                % [
                    chosen,
                    float(_EntityAccess.nested_dictionary_read(e0, "pending_attack").get("intensity", -1.0)),
                    float(_EntityAccess.nested_dictionary_read(e1, "pending_attack").get("intensity", -1.0)),
                ]
            )
        )
    if _IncomingParryChoice.parry_choice_blocked_for_resolve(mgr, p_id, e1_id, resolve_at):
        pass
    else:
        _fail(
            failures,
            (
                "incoming_parry: low-threat resolve should block parry choice (incoming=%s)"
                % str(_IncomingParryChoice.incoming_attacker_ids_on_defender(mgr, p_id, resolve_at))
            )
        )
    if _IncomingParryChoice.parry_choice_blocked_for_resolve(mgr, p_id, e0_id, resolve_at):
        _fail(failures, "incoming_parry: high-threat resolve should not block parry choice")
    _free_manager_restore_global_rng(mgr)


## Tier 0: two weak simultaneous wind-ups  -  **`can_parry_all`** true, no **`parry_choice_blocked`**.


## Tier 0: two weak simultaneous wind-ups  -  **`can_parry_all`** true, no **`parry_choice_blocked`**.
static func _run_incoming_parry_can_parry_all_weak_pair(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        _fail(failures, "incoming_parry_all: FEATURE_INCOMING_PARRY_CHOICE should be enabled")
        return
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    _harness_reset_combatants_form_balanced(mgr)
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    p["gauge"] = 100.0
    p["guard_line"] = "high_right"
    e0["gauge"] = 100.0
    e1["gauge"] = 100.0
    _WindUpStarter.start(mgr, e0_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e0, "pending_attack")["intensity"] = 0.40
    _WindUpStarter.start(mgr, e1_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e1, "pending_attack")["intensity"] = 0.40
    var resolve_at: float = _EntityAccess.combat_clock_plus(mgr, float(e0.get("state_duration", 0.5)))
    for aid in [e0_id, e1_id]:
        (
            _EntityAccess
            . manager_schedule_event(
                mgr,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": aid,
                    "resolve_at": resolve_at,
                    "data": {},
                }
            )
        )
    var incoming: Array = _IncomingParryChoice.incoming_attacker_ids_on_defender(mgr, p_id, resolve_at)
    if incoming.size() < 2:
        _fail(failures, "incoming_parry_all: want 2 incoming got %s" % str(incoming))
        _free_manager_restore_global_rng(mgr)
        return
    if not _IncomingParryChoice.can_parry_all(mgr, p_id, resolve_at):
        _fail(failures, "incoming_parry_all: weak pair should pass can_parry_all")
    for aid in [e0_id, e1_id]:
        if _IncomingParryChoice.parry_choice_blocked_for_resolve(mgr, p_id, aid, resolve_at):
            _fail(failures, "incoming_parry_all: aid=%d should not be parry_choice_blocked" % aid)
        var pa: Dictionary = _EntityAccess.nested_dictionary_read(
            _EntityAccess.manager_get_combatant(mgr, aid), "pending_attack"
        )
        _IncomingParryChoice.stamp_parry_choice_on_pa(mgr, pa, p_id, aid, resolve_at)
        if bool(pa.get("parry_choice_blocked", false)):
            _fail(failures, "incoming_parry_all: stamp should not block aid=%d" % aid)
        if not bool(pa.get("parry_all_incoming_batch", false)):
            _fail(failures, "incoming_parry_all: want parry_all_incoming_batch on aid=%d" % aid)
    _free_manager_restore_global_rng(mgr)


## III-1: equal perceived telegraph -> sector flank weight breaks parry-target tie (not outright telegraph wins).


## III-1: equal perceived telegraph -> sector flank weight breaks parry-target tie (not outright telegraph wins).
static func _run_iii1_incoming_parry_sector_tiebreak(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        _fail(failures, "iii1_parry_tie: FEATURE_INCOMING_PARRY_CHOICE should be enabled")
        return
    if not CombatConstants.is_feature_sector_surround_load():
        _fail(failures, "iii1_parry_tie: sector surround load should be enabled")
        return
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    p["file"] = 2
    e0["file"] = 0
    e1["file"] = 3
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var w0: float = _TacticalCombat.sector_weight_for_attacker_on_defender(mgr, p_id, e0_id)
    var w1: float = _TacticalCombat.sector_weight_for_attacker_on_defender(mgr, p_id, e1_id)
    if absf(w0 - w1) < 0.02:
        _fail(failures, "iii1_parry_tie: want distinct sector weights got w0=%.3f w1=%.3f" % [w0, w1])
        _free_manager_restore_global_rng(mgr)
        return
    var want_id: int = e0_id if w0 > w1 else e1_id
    _WindUpStarter.start(mgr, e0_id, p_id, "oberhau")
    _WindUpStarter.start(mgr, e1_id, p_id, "oberhau")
    var pa0: Dictionary = _EntityAccess.nested_dictionary_for_mutation(e0, "pending_attack")
    pa0["intensity"] = 0.85
    pa0["power"] = 0.55
    pa0["follow_through"] = 0.55
    pa0.erase("feint_part")
    pa0.erase("parry_telegraph_apparent")
    e1["pending_attack"] = pa0.duplicate(true)
    e1["state_timer"] = e0["state_timer"]
    e1["state_duration"] = e0["state_duration"]
    var tie_strength := 100.0
    for atk in [e0, e1]:
        _EntityAccess.stats_dict_for_mutation(atk)["strength"] = tie_strength
    var resolve_at: float = _EntityAccess.combat_clock_plus(mgr, float(e0.get("state_duration", 0.5)))
    for aid in [e0_id, e1_id]:
        (
            _EntityAccess
            . manager_schedule_event(
                mgr,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": aid,
                    "resolve_at": resolve_at,
                    "data": {},
                }
            )
        )
    var s0: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e0_id, p_id, resolve_at)
    var s1: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e1_id, p_id, resolve_at)
    if absf(s0 - s1) > 0.001:
        _fail(failures, "iii1_parry_tie: want tied threat scores s0=%.4f s1=%.4f" % [s0, s1])
        _free_manager_restore_global_rng(mgr)
        return
    var chosen: int = _IncomingParryChoice.choose_parry_target_attacker_id(mgr, p_id, resolve_at)
    if chosen != want_id:
        _fail(failures, "iii1_parry_tie: want sector-heavy aid=%d got %d (w0=%.3f w1=%.3f)" % [want_id, chosen, w0, w1])
    _free_manager_restore_global_rng(mgr)


## III-3: deflect/bind calibration loop  -  canonical thresholds, helper gates, ii2b plausibility band.


## III-3: deflect/bind calibration loop  -  canonical thresholds, helper gates, ii2b plausibility band.
static func _run_iii3_deflect_bind_calibration_suite(failures: PackedStringArray) -> void:
    var TrackSpecs := preload("res://harness/d001/CombatD001TrackSpecs.gd")
    if not is_equal_approx(CombatConstants.PARRY_DEFLECT_THRESHOLD, 1.03):
        _fail(
            failures,
            "iii3_calibration: PARRY_DEFLECT_THRESHOLD want 1.03 got %.3f" % CombatConstants.PARRY_DEFLECT_THRESHOLD
        )
    if not is_equal_approx(CombatConstants.PARRY_BIND_CONTROL_THRESHOLD, 0.65):
        _fail(
            failures,
            (
                "iii3_calibration: PARRY_BIND_CONTROL_THRESHOLD want 0.65 got %.3f"
                % CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
            )
        )
    var pa: float = 10.0
    var stop_at: float = pa * CombatConstants.PARRY_DEFLECT_THRESHOLD
    if CombatConstants.parry_full_stop_reached(stop_at - 0.001, pa, true):
        _fail(failures, "iii3_calibration: full_stop should be false below threshold")
    if not CombatConstants.parry_full_stop_reached(stop_at, pa, true):
        _fail(failures, "iii3_calibration: full_stop should be true at threshold")
    if CombatConstants.parry_full_stop_reached(stop_at, pa, false):
        _fail(failures, "iii3_calibration: full_stop should require block parry")
    var edge_cd: float = pa * CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.05
    if not CombatConstants.parry_edge_deflect_reached(edge_cd, pa, 0.85, false):
        _fail(failures, "iii3_calibration: edge deflect should reach at aligned non-block margin")
    if CombatConstants.parry_edge_deflect_reached(edge_cd, pa, 0.85, true):
        _fail(failures, "iii3_calibration: edge deflect must not apply when block parry")
    if CombatConstants.parry_full_stop_reached(edge_cd, pa, false):
        _fail(failures, "iii3_calibration: edge deflect must not use full_stop without block")
    if CombatConstants.parry_bind_control_reached(0.649):
        _fail(failures, "iii3_calibration: bind control should be false below 0.65")
    if not CombatConstants.parry_bind_control_reached(0.65):
        _fail(failures, "iii3_calibration: bind control should be true at 0.65")
    var ctrl_nom: float = CombatConstants.parry_control_for_bind_deflect(12.0, 8.0, 0.85, 1.0, false, false, "cut")
    if not CombatConstants.parry_bind_control_reached(ctrl_nom):
        _fail(
            failures,
            (
                "iii3_calibration: nominal sword bind want control>=%.2f got %.3f"
                % [CombatConstants.PARRY_BIND_CONTROL_THRESHOLD, ctrl_nom]
            )
        )
    var pa_m: float = 10.0
    var cd_m: float = pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.05
    var ctrl_m: float = CombatConstants.parry_control_for_bind_deflect(cd_m, pa_m, 0.75, 1.0, false, false, "cut")
    if ctrl_nom < ctrl_m:
        _fail(failures, "iii3_calibration: decisive bind control %.3f should exceed marginal %.3f" % [ctrl_nom, ctrl_m])
    var good_stats: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 2,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if not TrackSpecs.ii2b_plausibility_failures(good_stats).is_empty():
        _fail(
            failures,
            (
                "iii3_calibration: balanced ii2b stats should pass plausibility got %s"
                % ", ".join(TrackSpecs.ii2b_plausibility_failures(good_stats))
            )
        )
    var bind_heavy: Dictionary = good_stats.duplicate()
    bind_heavy["parry_bind"] = 9
    bind_heavy["parry_deflect"] = 1
    if TrackSpecs.ii2b_plausibility_failures(bind_heavy).is_empty():
        _fail(failures, "iii3_calibration: bind-heavy ii2b stats should fail plausibility")
    var signed_prefill: String = TrackSpecs.ii2b_worksheet_prefill_text(good_stats, true)
    if CombatConstants.iii3_baseline_constants_line() not in signed_prefill:
        _fail(failures, "iii3_calibration: signed worksheet must include baseline constants line")


## Tier 0 / FF4: extended weapon (recovering from own attack) dampens defender **`parry_c_d`**.


## Tier 0 / FF4: extended weapon (recovering from own attack) dampens defender **`parry_c_d`**.
static func _run_weapon_extended_parry_dampens_defender_recovering_from_attack(failures: PackedStringArray) -> void:
    if not _WeaponPosition.is_weapon_near_body({"state": CombatConstants.STATE_WAITING}):
        _fail(failures, "weapon_pos: waiting should be near body")
    if (
        _WeaponPosition
        . is_weapon_near_body(
            {
                "state": CombatConstants.STATE_RECOVERING,
                "recovery_cause": "attack_hit",
                "last_move_id": "oberhau",
            }
        )
    ):
        _fail(failures, "weapon_pos: recovering from own attack should be extended")
    if not _WeaponPosition.is_weapon_near_body(
        {"state": CombatConstants.STATE_RECOVERING, "recovery_cause": "parry_deflect"}
    ):
        _fail(failures, "weapon_pos: recovering from parry should stay near body")
    if not _WeaponPosition.is_weapon_near_body(
        {"state": CombatConstants.STATE_RECOVERING, "recovery_cause": "parry_partial"}
    ):
        _fail(failures, "weapon_pos: parry_partial recovery should stay near body")
    if not (
        _WeaponPosition
        . is_weapon_near_body(
            {
                "state": CombatConstants.STATE_RECOVERING,
                "recovery_cause": "parry_partial",
                "last_move_id": "oberhau",
            }
        )
    ):
        _fail(failures, "weapon_pos: parry_partial recovery should stay near body with last_move_id")
    if not (
        _WeaponPosition
        . is_weapon_near_body(
            {
                "state": CombatConstants.STATE_RECOVERING,
                "recovery_cause": "parry_deflect",
                "last_move_id": "oberhau",
            }
        )
    ):
        _fail(failures, "weapon_pos: parry_deflect recovery should stay near body with last_move_id")
    if not _WeaponPosition.is_weapon_near_body(
        {"state": CombatConstants.STATE_RECOVERING, "recovery_cause": "attack_deflect"}
    ):
        _fail(failures, "weapon_pos: attack_deflect recovery should stay near body")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["stamina"] = CombatConstants.STAMINA_MAX
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = _EntityAccess.scene_node(defender)
    var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "weapon_pos: targetable parts empty")
        _free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    attacker["state"] = CombatConstants.STATE_WIND_UP
    attacker["state_duration"] = 1.0
    attacker["state_timer"] = 0.0
    seed(92011)
    var dc_wait: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_wait: float = float(dc_wait.get("parry_c_d", 0.0))
    if cd_wait <= 1e-6:
        _fail(failures, "weapon_pos: want positive parry_c_d while waiting got %.6f" % cd_wait)
        _free_manager_restore_global_rng(mgr)
        return
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["recovery_cause"] = "attack_hit"
    defender["last_move_id"] = "oberhau"
    seed(92011)
    var dc_ext: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_ext: float = float(dc_ext.get("parry_c_d", 0.0))
    var want_ext: float = cd_wait * CombatConstants.WEAPON_EXTENDED_PARRY_MULT
    if absf(cd_ext - want_ext) > cd_wait * 0.02:
        _fail(
            failures,
            "weapon_pos: extended recover want c_d>=>=%.4f got %.4f (waiting=%.4f)" % [want_ext, cd_ext, cd_wait]
        )
    defender["recovery_cause"] = "parry_deflect"
    defender.erase("last_move_id")
    seed(92011)
    var dc_parry: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    if absf(float(dc_parry.get("parry_c_d", 0.0)) - cd_wait) > cd_wait * 0.02:
        _fail(
            failures,
            (
                "weapon_pos: parry recovery want c_d>=>=waiting got %.4f vs %.4f"
                % [float(dc_parry.get("parry_c_d", 0.0)), cd_wait]
            )
        )
    defender["recovery_cause"] = "parry_partial"
    seed(92011)
    var dc_partial: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    if absf(float(dc_partial.get("parry_c_d", 0.0)) - cd_wait) > cd_wait * 0.02:
        _fail(
            failures,
            (
                "weapon_pos: parry_partial recovery want c_d>=>=waiting got %.4f vs %.4f"
                % [float(dc_partial.get("parry_c_d", 0.0)), cd_wait]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 0 / FF4: attacker wind-up past commit (extended) dampens defender **`parry_c_d`**.


## Tier 0 / FF4: attacker wind-up past commit (extended) dampens defender **`parry_c_d`**.
static func _run_weapon_committed_attack_dampens_defender_parry_c_d(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["stamina"] = CombatConstants.STAMINA_MAX
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = _EntityAccess.scene_node(defender)
    var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "weapon_pos_commit: targetable parts empty")
        _free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "intensity": 0.55,
        "wind_up_duration": 1.0,
        "tactical_ambush_mult": 1.0,
    }
    attacker["state"] = CombatConstants.STATE_WIND_UP
    attacker["state_duration"] = 1.0
    attacker["state_timer"] = 0.0
    attacker["pending_attack"] = pa.duplicate()
    if not _WeaponPosition.is_weapon_near_body(attacker):
        _fail(failures, "weapon_pos_commit: early wind-up should be near body")
    seed(92012)
    var dc_coil: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_coil: float = float(dc_coil.get("parry_c_d", 0.0))
    if cd_coil <= 1e-6:
        _fail(failures, "weapon_pos_commit: want positive parry_c_d early wind-up")
        _free_manager_restore_global_rng(mgr)
        return
    var commit_frac: float = _WeaponPosition.commit_fraction_from_move_def(move_def)
    attacker["state_timer"] = commit_frac * 1.0 + 0.05
    if _WeaponPosition.is_weapon_near_body(attacker):
        _fail(
            failures,
            (
                "weapon_pos_commit: past commit wind-up should be extended (frac=%.2f timer=%.2f)"
                % [commit_frac, float(attacker.get("state_timer", 0.0))]
            )
        )
    seed(92012)
    var dc_commit: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_commit: float = float(dc_commit.get("parry_c_d", 0.0))
    var want_commit: float = cd_coil * CombatConstants.WEAPON_COMMITTED_ATTACK_PARRY_C_D_MULT
    if absf(cd_commit - want_commit) > cd_coil * 0.02:
        _fail(
            failures,
            (
                "weapon_pos_commit: committed attack want c_d>=>=%.4f got %.4f (coil=%.4f)"
                % [want_commit, cd_commit, cd_coil]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 0 / FF4: thrust moves commit earlier than heavy cuts (**`weapon_extension_commit_fraction`** on move def).


## Tier 0 / FF4: thrust moves commit earlier than heavy cuts (**`weapon_extension_commit_fraction`** on move def).
static func _run_weapon_commit_fraction_stab_before_overhead_cut(failures: PackedStringArray) -> void:
    var stab_frac: float = float(WeaponConstants.get_move("spear_thrust").get("weapon_extension_commit_fraction", 1.0))
    var cut_frac: float = float(WeaponConstants.get_move("oberhau").get("weapon_extension_commit_fraction", 0.0))
    if stab_frac >= cut_frac:
        _fail(failures, "weapon_commit_frac: stab %.2f should be < cut %.2f" % [stab_frac, cut_frac])
    var probe_timer: float = 0.65
    var atk_stab: Dictionary = {
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": probe_timer,
        "state_duration": 1.0,
        "pending_attack":
        {
            "wind_up_duration": 1.0,
            "attack_type": "spear_thrust",
            "weapon_extension_commit_fraction": stab_frac,
        },
    }
    if _WeaponPosition.is_weapon_near_body(atk_stab):
        _fail(failures, "weapon_commit_frac: spear at 65%% wind-up should be extended")
    var atk_cut: Dictionary = {
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": probe_timer,
        "state_duration": 1.0,
        "pending_attack":
        {
            "wind_up_duration": 1.0,
            "attack_type": "oberhau",
            "weapon_extension_commit_fraction": cut_frac,
        },
    }
    if not _WeaponPosition.is_weapon_near_body(atk_cut):
        _fail(failures, "weapon_commit_frac: oberhau at 65%% wind-up should still be coiled")


## Tier 0 / FF4: wind-up stamps per-move commit fraction on **`pending_attack`**.


## Tier 0 / FF4: wind-up stamps per-move commit fraction on **`pending_attack`**.
static func _run_weapon_windup_stamps_commit_fraction_on_pa(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var atk_id: int = _EntityAccess.id_int(atk)
    var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _WindUpStarter.start(mgr, atk_id, def_id, "spear_thrust")
    var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
    var want: float = _WeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move("spear_thrust"))
    if absf(float(pa.get("weapon_extension_commit_fraction", -1.0)) - want) > 0.001:
        _fail(
            failures,
            (
                "weapon_commit_frac: pa stamp want %.2f got %s"
                % [want, str(pa.get("weapon_extension_commit_fraction", "<absent>"))]
            )
        )
    _free_manager(mgr)


## Tier 0 / FF4: moves without explicit commit tag infer stab contact (**`parry_thrust`**).


## Tier 0 / FF4: moves without explicit commit tag infer stab contact (**`parry_thrust`**).
static func _run_weapon_commit_fraction_inferred_for_untagged_thrust_move(failures: PackedStringArray) -> void:
    var move_def: Dictionary = WeaponConstants.get_move("parry_thrust")
    if move_def.has("weapon_extension_commit_fraction"):
        _fail(failures, "weapon_commit_infer: parry_thrust should rely on contact inference")
    var want: float = _WeaponPosition.commit_fraction_from_move_def(move_def)
    if absf(want - CombatConstants.WEAPON_COMMIT_FRACTION_STAB) > 0.001:
        _fail(
            failures,
            (
                "weapon_commit_infer: parry_thrust want stab %.2f got %.2f"
                % [CombatConstants.WEAPON_COMMIT_FRACTION_STAB, want]
            )
        )


## Tier 7.5 pilot: **`impact_station_spread` 0** -> roll equals move **`impact_station_mean`** (+ intensity focus only).


## Tier 7.5 pilot: **`impact_station_spread` 0** -> roll equals move **`impact_station_mean`** (+ intensity focus only).
static func _run_impact_station_mean_zero_spread_equals_move_mean(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "impact_station: could not create SPEAR")
        return
    var intensity: float = 0.35
    var focus: float = clampf((intensity - 0.35) * 0.08, -0.04, 0.04)
    var want_mean: float = float(WeaponConstants.get_move("spear_thrust").get("impact_station_mean", -1.0))
    seed(7701)
    var got: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    if absf(got - clampf(want_mean + focus, 0.06, 0.99)) > 0.001:
        _fail(
            failures,
            (
                "impact_station: spear_thrust want %.3f got %.3f (mean %.2f focus %.3f)"
                % [want_mean + focus, got, want_mean, focus]
            )
        )


## Tier 7.5 pilot: per-move mean overrides weapon **`strike_physics.station_mean`**.


## Tier 7.5 pilot: per-move mean overrides weapon **`strike_physics.station_mean`**.
static func _run_impact_station_mean_move_overrides_weapon_default(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "impact_station_override: could not create SPEAR")
        return
    var intensity: float = 0.5
    seed(7702)
    var tagged: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    seed(7702)
    var untagged: float = _StrikeRealism.roll_blade_station(spear, "off_line_thrust", intensity)
    if tagged <= untagged:
        _fail(
            failures,
            "impact_station_override: spear_thrust %.3f should exceed off_line_thrust %.3f" % [tagged, untagged]
        )


## Tier 7.5 pilot: tip thrust stations above mace head-weighted direct blow.


## Tier 7.5 pilot: tip thrust stations above mace head-weighted direct blow.
static func _run_impact_station_mean_ordering_spear_thrust_above_mace_direct_blow(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    var mace: RefCounted = Weapon.create_from_definition("MACE")
    if spear == null or mace == null:
        _fail(failures, "impact_station_order: could not create weapons")
        return
    var intensity: float = 0.35
    seed(7703)
    var spear_station: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    seed(7703)
    var mace_station: float = _StrikeRealism.roll_blade_station(mace, "direct_blow", intensity)
    if spear_station <= mace_station:
        _fail(
            failures,
            (
                "impact_station_order: spear_thrust %.3f should exceed mace direct_blow %.3f"
                % [spear_station, mace_station]
            )
        )


## Tier 7.5 pilot: wind-up stamps tip-biased **`impact_blade_station`** (move mean, not weapon default).


## Tier 7.5 pilot: wind-up stamps tip-biased **`impact_blade_station`** (move mean, not weapon default).
static func _run_impact_station_mean_windup_stamps_move_override(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var atk_id: int = _EntityAccess.id_int(atk)
    var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _WindUpStarter.start(mgr, atk_id, def_id, "spear_thrust")
    var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
    var station: float = float(pa.get("impact_blade_station", -1.0))
    if station < 0.0:
        _fail(failures, "impact_station_windup: missing impact_blade_station on pa")
        return
    var move_mean: float = float(WeaponConstants.get_move("spear_thrust").get("impact_station_mean", -1.0))
    var lo: float = clampf(move_mean - 0.04, 0.06, 0.99)
    var hi: float = clampf(move_mean + 0.04, 0.06, 0.99)
    if station < lo or station > hi:
        _fail(failures, "impact_station_windup: spear_thrust station %.3f outside [%.3f, %.3f]" % [station, lo, hi])
    var weapon_default: float = float(Weapon.create_from_definition("SPEAR").strike_physics.get("station_mean", 0.0))
    if station <= weapon_default + 0.12:
        _fail(
            failures,
            "impact_station_windup: station %.3f should exceed weapon default %.2f" % [station, weapon_default]
        )
    _free_manager(mgr)


## Tier 7.5: every entry in **`WeaponConstants._move_definitions_build`** carries **`impact_station_mean`**.


## Tier 7.5: every entry in **`WeaponConstants._move_definitions_build`** carries **`impact_station_mean`**.
static func _run_impact_station_mean_every_move_def_tagged(failures: PackedStringArray) -> void:
    for move_id in WeaponConstants.get_all_move_ids():
        var md: Dictionary = WeaponConstants.get_move(move_id)
        if not md.has("impact_station_mean"):
            _fail(failures, "impact_station_catalog: %s missing impact_station_mean" % move_id)
            continue
        var mean: float = float(md.impact_station_mean)
        if mean < 0.06 or mean > 0.99:
            _fail(failures, "impact_station_catalog: %s mean %.3f outside [0.06, 0.99]" % [move_id, mean])


## Tier 7.5: feint wind-up station biased coiled vs honest cut at same intensity.


## Tier 7.5: feint wind-up station biased coiled vs honest cut at same intensity.
static func _run_impact_station_mean_feint_coiled_below_honest_cut(failures: PackedStringArray) -> void:
    var sword: RefCounted = Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "impact_station_feint: could not create SWORD")
        return
    var intensity: float = 0.35
    seed(7705)
    var feint_station: float = _StrikeRealism.roll_blade_station(sword, "oberhau_feint", intensity)
    seed(7705)
    var honest_station: float = _StrikeRealism.roll_blade_station(sword, "oberhau", intensity)
    if feint_station >= honest_station:
        _fail(
            failures,
            "impact_station_feint: oberhau_feint %.3f should be < oberhau %.3f" % [feint_station, honest_station]
        )


## Tier 7.5: spear shaft swing sits mid-blade vs tip thrust.


## Tier 7.5: spear shaft swing sits mid-blade vs tip thrust.
static func _run_impact_station_mean_pole_swing_below_spear_thrust(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "impact_station_pole: could not create SPEAR")
        return
    var intensity: float = 0.35
    seed(7706)
    var swing_station: float = _StrikeRealism.roll_blade_station(spear, "pole_swing", intensity)
    seed(7706)
    var thrust_station: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    if swing_station >= thrust_station:
        _fail(
            failures,
            "impact_station_pole: pole_swing %.3f should be < spear_thrust %.3f" % [swing_station, thrust_station]
        )

## Tier 0.2: formation move gauge shows vulnerable suffix while swapping / falling back.
