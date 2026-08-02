class_name AttentionFootworkAttentionLoadTests
extends CombatRegressionHarnessCore
const Bp := preload("res://core/BodyPartConstants.gd")

## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _t44_harness_ensure_flurry_bind() -> bool:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    return saved


static func _t44_harness_restore_flurry_bind(saved: bool) -> void:
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


static func _harness_immediate_peril_bleeding_chest(ent: Node, blood_volume: float) -> void:
    if ent == null:
        return
    ent.blood_volume = blood_volume
    EntityWounds.add_wound(
        ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
    )


static func _run_attention_being_wind_up_targeted_when_telegraph_set(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
    if not CombatAttention.is_being_wind_up_targeted(mgr, def_id):
        CombatRegressionHarness._fail(failures, "attention_wind_up_targeted: expected true when telegraph set")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: counter salience tracks **`CounterTempo.can_act`**.


## Tier 4.3: counter salience tracks **`CounterTempo.can_act`**.
static func _run_attention_counter_tempo_salience_matches_can_act(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 55.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    var can: bool = CounterTempo.can_act(mgr, def)
    var sal: bool = CombatAttention.has_actionable_counter_tempo(mgr, def)
    if sal != can:
        CombatRegressionHarness._fail(failures, "attention_counter_salience: want %s got %s" % [str(can), str(sal)])
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: peril + incoming telegraph stack **`attention_load`**.


## Tier 4.3: peril + incoming telegraph stack **`attention_load`**.
static func _run_attention_load_stacks_peril_and_incoming(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var atk: Dictionary = mgr.combatants[2]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent != null:
        ally_ent.blood_volume = 46.0
    AttackWindUpStarter.start(mgr, atk_id, medic_id, "oberhau")
    CombatAttention.refresh_salience(mgr, medic_id)
    var load: float = CombatAttention.get_attention_load(medic)
    var want_min: float = (
        (CombatConstants.ATTENTION_LOAD_TELEGRAPH_WEIGHT + CombatConstants.ATTENTION_LOAD_PERIL_WEIGHT) * 0.99
    )
    if load < want_min:
        CombatRegressionHarness._fail(failures, "attention_load_stack: want load >= %.4f got %.4f" % [want_min, load])
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: wrong-line focus dampens feint read-through line mult vs correct-line focus.


## Tier 4.3: wrong-line focus dampens feint read-through line mult vs correct-line focus.
static func _run_focus_intensity_scales_feint_readthrough_and_guard_zone(failures: PackedStringArray) -> void:
    var def: Dictionary = {
        "guard_zone": "head",
        "guard": 0.95,
        "stance": CombatConstants.STANCE_BALANCED,
        "state": CombatConstants.STATE_WAITING,
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
        CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
        CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
    }
    var pa: Dictionary = {"feint_part": "head", "target_part": "chest", "attack_type": "oberhau_feint"}
    var wrong_m: float = CombatAttention.focus_line_mult_for_feint(def, pa)
    CombatAttention.set_focus(def, "chest")
    var right_m: float = CombatAttention.focus_line_mult_for_feint(def, pa)
    if wrong_m >= right_m:
        CombatRegressionHarness._fail(
            failures, "focus_line_mult: wrong %.4f should be < correct %.4f" % [wrong_m, right_m]
        )
    if absf(wrong_m - CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT) > 0.0001:
        CombatRegressionHarness._fail(
            failures,
            "focus_line_mult wrong: want %.4f got %.4f" % [CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT, wrong_m]
        )


## Tier 4.3: high **`attention_load`** reduces **`focus_effective`**.


## Tier 4.3: high **`attention_load`** reduces **`focus_effective`**.
static func _run_attention_load_dampens_focus_effective_readiness(failures: PackedStringArray) -> void:
    var c: Dictionary = {CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0}
    c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 0.0
    var fe_clear: float = CombatAttention.focus_effective(c)
    c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 1.0
    var fe_load: float = CombatAttention.focus_effective(c)
    var want_load: float = 1.0 - CombatConstants.ATTENTION_LOAD_FOCUS_PENALTY
    if absf(fe_clear - 1.0) > 0.0001:
        CombatRegressionHarness._fail(failures, "focus_effective clear: want 1.0 got %.4f" % fe_clear)
    if absf(fe_load - want_load) > 0.0001:
        CombatRegressionHarness._fail(failures, "focus_effective load: want %.4f got %.4f" % [want_load, fe_load])


## Enemy win still ends combat immediately (no medical phase).


## Enemy win still ends combat immediately (no medical phase).
static func _run_mental_stack_medical_overrides_attack(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    AttentionFootworkAttentionLoadTests._harness_immediate_peril_bleeding_chest(ally_ent, 46.0)
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"

    var actions: Array = [
        {"move_id": "oberhau", "target_id": enemy_id},
        {
            "move_id": "apply_direct_pressure",
            "target_id": ally_id,
            "target_part": "chest",
        },
    ]

    # --- Robust diagnostics: each step fails with full context on mismatch ---
    var ctx: String = ""
    ctx += "medic_id=%d ally_id=%d enemy_id=%d med_phase=%s |" % [medic_id, ally_id, enemy_id, str(mgr.medical_phase)]

    # 1. Verify entity setup
    var ally_bv: float = -1.0
    if ally_ent != null:
        ally_bv = float(ally_ent.get("blood_volume"))
    ctx += " bv=%.1f|" % ally_bv
    if ally_bv > BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING:
        CombatRegressionHarness._fail(
            failures,
            "mental_stack_medical diag: ally blood_volume=%.1f > %s threshold  -  peril won't trigger" % [ally_bv, BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING]
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 2. Verify is_in_immediate_peril on ally (direct, via combatant dict)
    var ally_peril: bool = CombatantEntityAccess.is_in_immediate_peril(mgr, ally)
    ctx += " peril=%s|" % str(ally_peril)
    if not ally_peril:
        CombatRegressionHarness._fail(
            failures, "mental_stack_medical diag: is_in_immediate_peril(ally)=false  -  expected true"
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 3. Verify L0: medic NOT in peril
    var medic_peril: bool = CombatantEntityAccess.is_in_immediate_peril(mgr, medic)
    ctx += " medic_peril=%s|" % str(medic_peril)
    if medic_peril:
        CombatRegressionHarness._fail(
            failures, "mental_stack_medical diag: is_in_immediate_peril(medic)=true  -  should be false"
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 4. Verify L1 trigger: ally_in_immediate_peril from attention perspective
    var l1_ally_peril: bool = CombatAttention.ally_in_immediate_peril(mgr, medic_id)
    ctx += " l1_peril=%s|" % str(l1_ally_peril)
    if not l1_ally_peril:
        CombatRegressionHarness._fail(
            failures, "mental_stack_medical diag: ally_in_immediate_peril(medic)=false  -  expected true"
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 5. Verify coordinated medical filter includes the pressure action
    var coordinated: Array = MentalStackDecider._filter_coordinated_medical_actions(actions, medic_id, mgr)
    var coord_has_pressure: bool = false
    for _ca in coordinated:
        if _ca is Dictionary:
            var dca: Dictionary = _ca as Dictionary
            if str(dca.get("move_id", "")) == "apply_direct_pressure":
                coord_has_pressure = true
                break
    ctx += " coord_count=%d|" % coordinated.size()
    if not coord_has_pressure:
        var fallback_list: Array = MentalStackDecider._filter_ally_medical_actions_fallback(actions, medic_id, mgr)
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_medical diag: coordinated filter empty (count=%d), fallback count=%d  -  medical_acti"
                + "on_allowed likely failed" % [coordinated.size(), fallback_list.size()]
            )
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 6. Verify coordination blocked reason is empty for the pressure action
    var blocked_reason: String = CombatMedicalCoordination.medical_action_coordination_blocked(
        mgr, medic_id, ally_id, "chest", "apply_direct_pressure"
    )
    if not blocked_reason.is_empty():
        ctx += " blocked='%s'|" % blocked_reason
        CombatRegressionHarness._fail(failures, "mental_stack_medical diag: coordination_blocked='%s'" % blocked_reason)
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 7. Verify can_stack_assist_pressure is FALSE (no compression yet)
    var can_stack: bool = CombatMedicalCoordination.can_stack_assist_pressure(mgr, medic_id, ally_id, "chest")
    ctx += " can_stack=%s|" % str(can_stack)
    if can_stack:
        CombatRegressionHarness._fail(
            failures,
            "mental_stack_medical diag: can_stack_assist_pressure=true  -  expected false (no compression yet)"
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # 8. Verify entity bleeding rate for chest > 0
    var ally_dict: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, ally_id)
    var bleed_rate: float = 0.0
    if not ally_dict.is_empty():
        bleed_rate = CombatantEntityAccess.entity_bleeding_rate_for_part(mgr, ally_dict, "chest")
    ctx += " bleed_rate=%.2f|" % bleed_rate
    if bleed_rate <= 0.0:
        CombatRegressionHarness._fail(
            failures,
            "mental_stack_medical diag: entity_bleeding_rate_for_part(chest)=%.2f  -  expected > 0" % bleed_rate
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    # --- Run try_pick and verify result ---
    var picked: Dictionary = MentalStackDecider.try_pick(actions, medic_id, mgr)
    ctx += " pick=%s|" % str(picked)

    if picked.is_empty():
        CombatRegressionHarness._fail(
            failures, "mental_stack_medical: expected stack pick (all layers returned empty). ctx=" + ctx
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    var picked_move: String = str(picked.get("move_id", ""))
    var post_c: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, medic_id)
    var picked_layer: String = str(post_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "NONE"))
    ctx += " move=%s layer=%s" % [picked_move, picked_layer]

    if not mgr._is_medical_move(picked_move):
        CombatRegressionHarness._fail(
            failures, "mental_stack_medical: want medical move got '%s' (ctx=%s)" % [picked_move, ctx]
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    if picked_layer != CombatConstants.MENTAL_STACK_LAYER_MEDICAL:
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_medical: expected layer=%s got layer=%s move=%s (ctx=%s)"
                % [CombatConstants.MENTAL_STACK_LAYER_MEDICAL, picked_layer, picked_move, ctx]
            )
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return

    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: incoming wind-up restricts picks to counter or melee vs attacker.


## Tier 4.3: incoming wind-up restricts picks to counter or melee vs attacker.
static func _run_mental_stack_incoming_windup_prefers_defense(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var def_id: int = CombatantEntityAccess.id_int(def)
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    var actions: Array = [
        {"move_id": "oberhau", "target_id": atk_id},
        {"move_id": "wait"},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(actions, def_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_incoming: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var tid: int = int(picked.get("target_id", -1))
    if bool(picked.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
        pass
    elif tid != atk_id:
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_incoming: pick should target incoming attacker %d got target %d move %s"
                % [atk_id, tid, str(picked.get("move_id", ""))]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: counter window open -> stack prefers counter-tempo listing.


## Tier 4.3: counter window open -> stack prefers counter-tempo listing.
static func _run_mental_stack_counter_over_plain_attack_when_window_open(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var def_id: int = CombatantEntityAccess.id_int(def)
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    def["gauge"] = 55.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    (
        mgr
        . _schedule_event(
            {
                "type": CombatConstants.EVENT_MELEE_ATTACK,
                "combatant_id": atk_id,
                "resolve_at": mgr.combat_clock + float(atk.get(DataKeys.PA_STATE_DURATION, 0.0)),
                "data": {},
            }
        )
    )
    var actions: Array = AvailableActionsBuilder.build(mgr, def_id)
    var saw_counter: bool = false
    for raw in actions:
        if (
            typeof(raw) == TYPE_DICTIONARY
            and bool((raw as Dictionary).get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false))
        ):
            saw_counter = true
            break
    if not saw_counter:
        CombatRegressionHarness._fail(failures, "mental_stack_counter: expected counter_tempo in action list")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked: Dictionary = MentalStackDecider.try_pick(actions, def_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_counter: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if not bool(picked.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
        CombatRegressionHarness._fail(
            failures, "mental_stack_counter: want counter_tempo action got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: no salience -> **`try_pick`** empty; attack weights unchanged with stack off.


## Tier 4.3: no salience -> **`try_pick`** empty; attack weights unchanged with stack off.
static func _run_mental_stack_attack_layer_matches_stance_alias_weights(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var a: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var actions: Array = [a]
    var stacked: Dictionary = MentalStackDecider.try_pick(actions, p_id, mgr)
    if not stacked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack: try_pick should be empty without salience")
    var w: float = CombatAIActionPicker._get_action_weight(a, p_id, mgr, true)
    CombatConstants.set_feature_mental_stack_ai_load(false)
    var stacked_off: Dictionary = MentalStackDecider.try_pick(actions, p_id, mgr)
    var w_off: float = CombatAIActionPicker._get_action_weight(a, p_id, mgr, true)
    CombatConstants.set_feature_mental_stack_ai_load(true)
    if not stacked_off.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack: try_pick off should stay empty")
    if absf(w - w_off) > 0.0001 * maxf(1.0, absf(w)):
        CombatRegressionHarness._fail(failures, "mental_stack: weight changed %.6f vs %.6f" % [w, w_off])
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: repeated high-line attacks raise yomi feint mult on that line.


## Tier 4.3: repeated high-line attacks raise yomi feint mult on that line.
static func _run_yomi_guard_tendency_boosts_feint_after_repeated_high(failures: PackedStringArray) -> void:
    var def: Dictionary = {}
    var atk_id: int = 7
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    var m0: float = CombatAttention.yomi_feint_listing_mult(def, atk_id, "head")
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    var m1: float = CombatAttention.yomi_feint_listing_mult(def, atk_id, "head")
    if m1 <= m0 or m0 <= 1.0:
        CombatRegressionHarness._fail(failures, "yomi_feint: mult should rise above 1.0 got m0=%.4f m1=%.4f" % [m0, m1])


## Tier 4.3 UI: **`format_attention_ui_hint`** includes telegraph + focus when incoming.


## Tier 4.3 UI: **`format_attention_ui_hint`** includes telegraph + focus when incoming.
static func _run_yomi_updates_on_parry_deflect_clears_on_hit(failures: PackedStringArray) -> void:
    var def: Dictionary = {}
    var atk_id: int = 3
    CombatAttention.record_parry_deflect_on_attacker_memory(def, atk_id)
    var root: Dictionary = def.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, {}) as Dictionary
    var entry: Dictionary = root.get(str(atk_id), {}) as Dictionary
    if int(entry.get("parry_deflect", 0)) != 1:
        CombatRegressionHarness._fail(failures, "yomi_parry: want parry_deflect count 1")
    CombatAttention.clear_yomi_for_attacker(def, atk_id)
    if def.has(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER):
        CombatRegressionHarness._fail(failures, "yomi_clear: yomi root should be empty after clear")


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", probing)`** multiplies feint listing by
## **`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**; then **`hold_lane`** applies
## **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no probing mult).


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", probing)`** multiplies feint listing by
## **`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**; then **`hold_lane`** applies
## **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no probing mult).
static func _run_attention_ui_hint_formats_when_telegraph_set(failures: PackedStringArray) -> void:
    var def: Dictionary = {
        "guard_zone": "head",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
        CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
        CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
        CombatConstants.COMBATANT_KEY_ATTENTION_LOAD: 0.2,
    }
    var hint: String = CombatAttention.format_attention_ui_hint(def)
    if not hint.contains("Tel head"):
        CombatRegressionHarness._fail(failures, "attention_ui_hint: want Tel head in '%s'" % hint)
    if not hint.contains("Focus head"):
        CombatRegressionHarness._fail(failures, "attention_ui_hint: want Focus head in '%s'" % hint)
    if not hint.contains("Load"):
        CombatRegressionHarness._fail(failures, "attention_ui_hint: want Load segment in '%s'" % hint)


## Tier 4.3 UI: **`refresh_for_waiting_tick`** stamps **`COMBATANT_KEY_ATTENTION_UI_HINT`**.


## Tier 4.3 UI: **`refresh_for_waiting_tick`** stamps **`COMBATANT_KEY_ATTENTION_UI_HINT`**.
static func _run_attention_refresh_waiting_tick_stamps_ui_hint(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    AttackWindUpStarter.start(
        mgr,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(def),
        "oberhau_feint",
        {"target_part": "chest", "feint_part": "head"}
    )
    CombatStateHandlers.process_waiting(mgr, def, 0.05)
    var hint: String = str(def.get(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, ""))
    if hint.is_empty():
        CombatRegressionHarness._fail(failures, "attention_ui_refresh: expected non-empty attention_ui_hint")
    AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(
        mgr, CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
    )
    if def.has(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT):
        CombatRegressionHarness._fail(failures, "attention_ui_refresh: hint should clear when telegraph cleared")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: yomi habit line sets AI **`focus_part`** on drift.


## Tier 4.3: yomi habit line sets AI **`focus_part`** on drift.
static func _run_yomi_focus_drift_sets_habitual_part_on_ai(failures: PackedStringArray) -> void:
    var def: Dictionary = {"side": "enemy", "is_party_leader": false}
    var atk_id: int = 11
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    CombatAttention.apply_yomi_focus_drift(null, def, atk_id)
    if CombatAttention.get_focus_part(def) != "head":
        CombatRegressionHarness._fail(
            failures, "yomi_focus_drift: want focus head got %s" % CombatAttention.get_focus_part(def)
        )


## Tier 4.3: mismatched feint telegraph line keeps habitual focus (not bait part).


## Tier 4.3: mismatched feint telegraph line keeps habitual focus (not bait part).
static func _run_yomi_focus_drift_keeps_habit_when_telegraph_line_mismatches(failures: PackedStringArray) -> void:
    var def: Dictionary = {
        "side": "enemy",
        "is_party_leader": false,
        CombatConstants.COMBATANT_KEY_FOCUS_PART: "chest",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "left_arm",
    }
    var atk_id: int = 12
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    CombatAttention.record_attack_toward_defender(null, atk_id, def, "head")
    CombatAttention.apply_yomi_focus_drift(null, def, atk_id)
    if CombatAttention.get_focus_part(def) != "head":
        CombatRegressionHarness._fail(
            failures, "yomi_focus_drift_mismatch: want habit head got %s" % CombatAttention.get_focus_part(def)
        )


## Tier 4.3: explicit guard move updates **`focus_part`** with **`guard_zone`**.


## Tier 4.3: explicit guard move updates **`focus_part`** with **`guard_zone`**.
static func _run_guard_from_move_syncs_focus_part_with_guard_line(failures: PackedStringArray) -> void:
    var c: Dictionary = {
        "guard_line": CombatConstants.GUARD_DEFAULT,
        "guard_zone": "head",
        CombatConstants.COMBATANT_KEY_FOCUS_PART: "chest",
    }
    GuardLineUpdater.set_guard_from_line(c, "low")
    if str(c.get("guard_zone", "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures, "guard_focus_sync: want guard_zone left_leg got %s" % str(c.get("guard_zone"))
        )
    if CombatAttention.get_focus_part(c) != "left_leg":
        CombatRegressionHarness._fail(
            failures, "guard_focus_sync: want focus left_leg got %s" % CombatAttention.get_focus_part(c)
        )


## Tier 4.3: mental stack stamps **`COMBATANT_KEY_MENTAL_STACK_LAYER`** on layer pick.


## Tier 4.3: mental stack stamps **`COMBATANT_KEY_MENTAL_STACK_LAYER`** on layer pick.
static func _run_mental_stack_stamps_layer_on_medical_pick(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    AttentionFootworkAttentionLoadTests._harness_immediate_peril_bleeding_chest(ally_ent, 46.0)
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var actions: Array = [
        {"move_id": "oberhau", "target_id": CombatantEntityAccess.id_int(mgr.combatants[2])},
        {"move_id": "apply_direct_pressure", "target_id": ally_id, "target_part": "chest"},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(actions, medic_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_layer: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_MEDICAL
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_layer: want medical got %s"
                % str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: self immediate peril picks coordinated self-aid before ally medical.


## Tier 4.3: self immediate peril picks coordinated self-aid before ally medical.
static func _run_mental_stack_self_peril_before_ally_medical(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    var medic_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, medic)
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    AttentionFootworkAttentionLoadTests._harness_immediate_peril_bleeding_chest(medic_ent, 46.0)
    AttentionFootworkAttentionLoadTests._harness_immediate_peril_bleeding_chest(ally_ent, 46.0)
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var actions: Array = [
        {"move_id": "oberhau", "target_id": CombatantEntityAccess.id_int(mgr.combatants[2])},
        {"move_id": "apply_direct_pressure", "target_id": medic_id, "target_part": "chest"},
        {"move_id": "apply_direct_pressure", "target_id": ally_id, "target_part": "chest"},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(actions, medic_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_self: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_SELF_MEDICAL
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_self: want self_medical layer got %s"
                % str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if int(picked.get("target_id", -1)) != medic_id:
        CombatRegressionHarness._fail(
            failures, "mental_stack_self: want self target %d got %d" % [medic_id, int(picked.get("target_id", -1))]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: hold-line-only menu -> **`wait`** unless incoming telegraph needs another guard line.


## Tier 4.3: hold-line-only menu -> **`wait`** unless incoming telegraph needs another guard line.
static func _run_mental_stack_hold_line_only_picks_focus_or_wait(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var back: Dictionary = mgr.combatants[0]
    var back_id: int = CombatantEntityAccess.id_int(back)
    back["guard_line"] = "low"
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": back_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": back_id},
    ]
    var picked: Dictionary = MentalStackDecider.try_pick(actions, back_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_hold: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(back.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_hold: want hold_line got %s"
                % str(back.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_WAIT:
        CombatRegressionHarness._fail(
            failures, "mental_stack_hold: no telegraph want wait got %s" % str(picked.get("move_id", ""))
        )
    back[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    # Simulate wind-up targeting without full manager telegraph wiring  -  layer only checks key + targeted.
    if not CombatAttention.is_being_wind_up_targeted(mgr, back_id):
        CombatRegressionHarness._fail(failures, "mental_stack_hold: setup want wind_up targeted")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var picked_tele: Dictionary = MentalStackDecider.try_pick(actions, back_id, mgr)
    if str(picked_tele.get("move_id", "")) != CombatConstants.MOVE_ID_FOCUS_HIGH:
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_hold: telegraph head vs guard low want focus_high got %s"
                % str(picked_tele.get("move_id", ""))
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 Track A PR7: L4 reserve posture wing with LONG close listed -> **`attempt_close`** (not **`wait`**).


## III-4 Track A PR7: L4 reserve posture wing with LONG close listed -> **`attempt_close`** (not **`wait`**).
static func _run_mental_stack_hold_line_attempt_close_wing(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 1)
    if wing.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_close_wing: missing wing/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    # Nearest-wing maps rank-0 wings to outer enemies; use depth-only hostiles so L4 close path still applies.
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy" and CombatantEntityAccess.rank_int(c) == 0:
            c["rank"] = 1
    var wing_id: int = CombatantEntityAccess.id_int(wing)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    if not EngagementOpposition.wing_lacks_mapped_opposition(mgr, wing):
        CombatRegressionHarness._fail(failures, "mental_stack_close_wing: setup want wing_lacks_mapped_opposition")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(wing, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_LONG
    wing["gauge"] = 100.0
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": wing_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": wing_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    if not CombatListedActions.action_list_is_reserve_posture_only(actions):
        CombatRegressionHarness._fail(failures, "mental_stack_close_wing: setup want reserve_posture_only menu")
    var picked: Dictionary = MentalStackDecider.try_pick(actions, wing_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_close_wing: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(wing.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_close_wing: want hold_line got %s"
                % str(wing.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_close_wing: want attempt_close got %s" % str(picked.get("move_id", ""))
        )
    var hint: String = CombatPlayerTurnHints.hold_line_focus_only_hint(mgr, wing, actions)
    if hint.is_empty() or not hint.contains("close"):
        CombatRegressionHarness._fail(failures, "mental_stack_close_wing: want wing close hint got '%s'" % hint)
    # Mapped-opposed center (rank-0 vs rank-0) still defaults to wait when reserve-only without close need.
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 2)
    var e_front: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy" and CombatantEntityAccess.file_int(c) == 1:
            c["rank"] = 0
            e_front = c
            break
    if center.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_close_wing: missing center fixture")
    else:
        var center_id: int = CombatantEntityAccess.id_int(center)
        if EngagementOpposition.wing_lacks_mapped_opposition(mgr, center):
            CombatRegressionHarness._fail(failures, "mental_stack_close_wing: center should have mapped opposition")
        var center_actions: Array = [
            {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
            {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
        ]
        dist = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
        dist[enemy_id] = CombatConstants.DISTANCE_LONG
        var center_pick: Dictionary = MentalStackDecider.try_pick(center_actions, center_id, mgr)
        if str(center_pick.get("move_id", "")) != CombatConstants.MOVE_ID_WAIT:
            CombatRegressionHarness._fail(
                failures,
                "mental_stack_close_wing: mapped center want wait got %s" % str(center_pick.get("move_id", ""))
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mapped center during mop-up still L4-picks **`attempt_close`** (not wing_lacks-only).


## III-4 **3e**: mapped center during mop-up still L4-picks **`attempt_close`** (not wing_lacks-only).
static func _run_mental_stack_hold_line_attempt_close_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: setup want envelop_mop_up_active")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: missing center/enemy fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if EngagementOpposition.wing_lacks_mapped_opposition(mgr, center):
        CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: center should have mapped opposition")
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_LONG
    center["gauge"] = 100.0
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    if not CombatDoctrine.hold_line_close_pick_eligible(mgr, center):
        CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: want hold_line_close_pick_eligible")
    var picked: Dictionary = MentalStackDecider.try_pick(actions, center_id, mgr)
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_close_mop_up: want attempt_close got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: L4 picks **`attempt_close`** at MID band during mop-up (band/reach gap).


## III-4 **3e**: L4 picks **`attempt_close`** at MID band during mop-up (band/reach gap).
static func _run_mental_stack_hold_line_attempt_close_mop_up_mid(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if center.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up_mid: missing fixtures")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center_id: int = CombatantEntityAccess.id_int(center)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var dist: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(center, "distance_to")
    dist[enemy_id] = CombatConstants.DISTANCE_MID
    center["gauge"] = 100.0
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    if not CombatMeleeListing.attempt_close_listed_for_pair(mgr, center, enemy_id, CombatConstants.DISTANCE_MID):
        CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up_mid: setup want close listed at MID")
    var picked: Dictionary = MentalStackDecider.try_pick(actions, center_id, mgr)
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_close_mop_up_mid: want attempt_close got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)

## III-4 **3e**: mop-up close beats focus retarget even under incoming telegraph (no focus_* tail loop).
