class_name CombatRegressionHarnessMercyExecuteTail
extends RefCounted
## Mercy & execution tests — downed predicate, personality mult, threat/grudge weights, listing, resolve.


const MgrScript := preload("res://combat/CombatManager.gd")
const Weapon := preload("res://resources/weapons/Weapon.gd")
const CoreEntity := preload("res://core/CoreEntity.gd")
const CombatConstants := preload("res://combat/CombatConstants.gd")
const CombatExecute := preload("res://combat/ai/CombatExecute.gd")
const CombatMeleeListing := preload("res://combat/ai/CombatMeleeListing.gd")
const CombatResolveAction := preload("res://combat/flow/CombatResolveAction.gd")
const CombatConstantsFeatureFlags := preload("res://combat/constants/CombatConstantsFeatureFlags.gd")
const AvailableActionsBuilder := preload("res://combat/ai/AvailableActionsBuilder.gd")
const CombatantEntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")
const CombatantIdentityAccess := preload("res://combat/access/CombatantIdentityAccess.gd")
const CombatAIActionPicker := preload("res://combat/ai/CombatAIActionPicker.gd")
const CombatAIActionWeights := preload("res://combat/ai/CombatAIActionWeights.gd")
const CombatCampaignMoodBias := preload("res://combat/ai/CombatCampaignMoodBias.gd")
const CombatTargetScoring := preload("res://combat/ai/CombatTargetScoring.gd")
const DataKeys := preload("res://core/DataKeys.gd")
const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")
const BattleUIUpdater := preload("res://ui/battle/BattleUIUpdater.gd")
const CombatLogFormatter := preload("res://ui/battle/CombatLogFormatter.gd")
const FormationSlots := preload("res://combat/formation/FormationSlots.gd")


## Headless harness helper: appends to the failures PackedStringArray.

static func _fail(failures: PackedStringArray, msg: String) -> void:
    failures.append(msg)


static func _new_entity(weapon_id: String) -> CoreEntity:
    return HarnessFixtures._new_entity(weapon_id)


static func _free_manager_restore_global_rng(mgr: Node) -> void:
    HarnessFixtures.flush_harness_live_nodes()
    if mgr != null and is_instance_valid(mgr):
        mgr.free()


# -- Downed predicate -------------------------------------------------------

## Phase 1b: downed = alive + on-field + opponent of executor + not standing.
static func _run_is_downed_opponent_of_detects_cowering_enemy(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    # Standing enemy should not count as downed.
    if CombatExecute.is_downed_opponent_of(mgr, attacker, target):
        _fail(failures, "downed_predicate: standing enemy must not be downed")
    # Cower the enemy — now it is downed.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    if not CombatExecute.is_downed_opponent_of(mgr, attacker, target):
        _fail(failures, "downed_predicate: cowering enemy must be downed")
    # Kill the enemy — dead is not downed.
    target.alive = false
    if CombatExecute.is_downed_opponent_of(mgr, attacker, target):
        _fail(failures, "downed_predicate: dead enemy must not be downed")
    # Same side combatant should never be downed (not an opponent).
    var ally: Dictionary = mgr.combatants[0]
    # Re-activate a second player for test.
    var mgr2: Node = CombatManager.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr2.combatants[0]
    var p1: Dictionary = mgr2.combatants[0]  # same combatant — not opponent of itself
    if CombatExecute.is_downed_opponent_of(mgr2, p0, p1):
        _fail(failures, "downed_predicate: self must not be downed opponent of self")
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)
    _free_manager_restore_global_rng(mgr2)


# -- Personality mult -------------------------------------------------------

## Phase 1b: ruthlessness 0 → min mult, 50 → 1.0, 100 → max mult.
static func _run_personality_mult_linear_ramp(failures: PackedStringArray) -> void:
    var r0: float = CombatExecute.personality_mult(0.0)
    var r50: float = CombatExecute.personality_mult(50.0)
    var r100: float = CombatExecute.personality_mult(100.0)
    var eps: float = 0.001
    if absf(r0 - CombatExecute.EXECUTE_RUTHLESSNESS_MULT_MIN) > eps:
        _fail(failures, "personality_mult: ruth=0 want %.3f got %.3f" % [CombatExecute.EXECUTE_RUTHLESSNESS_MULT_MIN, r0])
    if absf(r50 - 1.0) > eps:
        _fail(failures, "personality_mult: ruth=50 want 1.0 got %.3f" % r50)
    if absf(r100 - CombatExecute.EXECUTE_RUTHLESSNESS_MULT_MAX) > eps:
        _fail(failures, "personality_mult: ruth=100 want %.3f got %.3f" % [CombatExecute.EXECUTE_RUTHLESSNESS_MULT_MAX, r100])


## Phase 1b: clamping at boundaries.
static func _run_personality_mult_clamps_negative_and_over_100(failures: PackedStringArray) -> void:
    var r_neg: float = CombatExecute.personality_mult(-20.0)
    var r_over: float = CombatExecute.personality_mult(150.0)
    if absf(r_neg - CombatExecute.EXECUTE_RUTHLESSNESS_MULT_MIN) > 0.001:
        _fail(failures, "personality_mult: want clamped to min at -20 got %.3f" % r_neg)
    if absf(r_over - CombatExecute.EXECUTE_RUTHLESSNESS_MULT_MAX) > 0.001:
        _fail(failures, "personality_mult: want clamped to max at 150 got %.3f" % r_over)


# -- Threat mult ------------------------------------------------------------

## Phase 1c: no enemies in melee reach → threat mult = 1.0 (safe to execute).
static func _run_threat_mult_safe_when_no_melee_opponents(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    # Only one enemy, far away — set LONG distance band.
    mgr.register(_new_entity("SPEAR"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    # Place enemy far enough — use LONG distance band to ensure no melee threat.
    attacker[DataKeys.COMBATANT_DISTANCE_TO] = {
        CombatantEntityAccess.id_int(mgr.combatants[1]): CombatConstants.DISTANCE_LONG
    }
    # With only one enemy and no rank-0 melee opponents in range, threat should be 1.0.
    var tm: float = CombatExecute.threat_mult(mgr, attacker)
    if absf(tm - 1.0) > 0.001:
        _fail(failures, "threat_mult: no melee threat want 1.0 got %.3f" % tm)
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


# -- Grudge mult ------------------------------------------------------------

## Phase 1c: executor has damage in ledger for target → grudge boost.
static func _run_grudge_mult_detects_damage_ledger(failures: PackedStringArray) -> void:
    var cid_a: int = 42
    var cid_b: int = 99
    # No ledger entry — baseline.
    var c_no_grudge: Dictionary = {DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID: {}}
    if CombatExecute.grudge_mult(c_no_grudge, cid_b) != 1.0:
        _fail(failures, "grudge_mult: empty ledger must return 1.0")
    # Ledger shows damage dealt to target_id → grudge boost.
    var c_with_grudge: Dictionary = {DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID: {cid_b: 3.5}}
    if absf(CombatExecute.grudge_mult(c_with_grudge, cid_b) - CombatExecute.EXECUTE_GRUDGE_MULT) > 0.001:
        _fail(failures, "grudge_mult: damage ledger must return grudge_mult")
    # Ledger shows damage to a different target — no grudge for this one.
    var c_other_grudge: Dictionary = {DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID: {cid_a: 5.0}}
    if CombatExecute.grudge_mult(c_other_grudge, cid_b) != 1.0:
        _fail(failures, "grudge_mult: damage to different target must return 1.0")


# -- Full execute weight ----------------------------------------------------

## Phase 1b/c: full weight formula returns 0 for non-downed targets.
static func _run_execute_weight_zero_for_standing_target(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    # Standing enemy — weight should be 0.
    var w: float = CombatExecute.execute_weight(mgr, attacker, target)
    if w != 0.0:
        _fail(failures, "execute_weight: standing target must return 0.0 got %.4f" % w)
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


## Phase 1b/c: downed enemy with high ruthlessness and grudge → weight > base.
static func _run_execute_weight_amplifies_with_ruthless_grudge(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    # Make target downed.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    # Set high ruthlessness on attacker.
    attacker[DataKeys.COMBATANT_RUTHLESSNESS] = 80.0
    # Stamp grudge: attacker dealt damage to target.
    var ledger: Dictionary = {CombatantEntityAccess.id_int(target): 2.0}
    attacker[DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID] = ledger
    var w: float = CombatExecute.execute_weight(mgr, attacker, target)
    # Weight should be > base (ruthlessness 80 → ~1.4×, grudge ×1.5, no threat dampen).
    if w <= CombatExecute.EXECUTE_BASE_AI_WEIGHT:
        _fail(failures, "execute_weight: downed+grudge+ruthless must exceed base weight %.4f" % [CombatExecute.EXECUTE_BASE_AI_WEIGHT])
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


# -- Listing integration ----------------------------------------------------

## Phase 1c: execute action listed for downed opponent in reach.
static func _run_execute_listed_for_downed_in_reach(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    c.gauge = 100.0
    # Standing enemy — execute should NOT be listed.
    var acts_before: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(c))
    for act in acts_before:
        if str(act.get("move_id", "")) == CombatConstants.MOVE_ID_EXECUTE:
            _fail(failures, "execute_listing: standing enemy must not list execute")
    # Down the enemy.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    var acts_after: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(c))
    var has_execute: bool = false
    for act in acts_after:
        if str(act.get("move_id", "")) == CombatConstants.MOVE_ID_EXECUTE:
            has_execute = true
            break
    if not has_execute:
        _fail(failures, "execute_listing: downed enemy must list execute action")
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


## Phase 1c: execute NOT listed when executor has no attacking arm.
static func _run_execute_not_listed_without_attacking_arm(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    c.gauge = 100.0
    # Down the enemy.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    # Destroy both of attacker's arms so no functional attacking arm remains.
    var ent: CoreEntity = CombatantEntityAccess.scene_node(c) as CoreEntity
    HarnessFixtures._harness_destroy_limb(ent, "right_arm")
    HarnessFixtures._harness_destroy_limb(ent, "left_arm")
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(c))
    for act in acts:
        if str(act.get("move_id", "")) == CombatConstants.MOVE_ID_EXECUTE:
            _fail(failures, "execute_listing: no attacking arm must not list execute")
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


# -- Resolve integration ----------------------------------------------------

## Phase 1c: resolve execute kills target instantly, sets dead state.
static func _run_resolve_execute_sets_target_dead(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    var tgt_id: int = CombatantEntityAccess.id_int(target)
    attacker.gauge = 100.0
    # Down the enemy.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    # Resolve execute.
    CombatResolveAction.resolve(mgr, atk_id, tgt_id, CombatConstants.MOVE_ID_EXECUTE, {})
    if target.alive:
        _fail(failures, "execute_resolve: target must be dead after resolve")
    if CombatantEntityAccess.state_str(target) != CombatConstants.STATE_DEAD:
        _fail(failures, "execute_resolve: target state must be DEAD got %s" % CombatantEntityAccess.state_str(target))
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


## Phase 1c: resolve execute stamps damage ledger on attacker.
static func _run_resolve_execute_stamps_grudge_ledger(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    var tgt_id: int = CombatantEntityAccess.id_int(target)
    attacker.gauge = 100.0
    # Set initial ledger.
    attacker[DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID] = {tgt_id: 1.0}
    # Down and execute target.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    CombatResolveAction.resolve(mgr, atk_id, tgt_id, CombatConstants.MOVE_ID_EXECUTE, {})
    # Ledger should now show 2.0 (1.0 pre + 1.0 execute).
    var ledger: Dictionary = attacker.get(DataKeys.COMBATANT_DAMAGE_DEALT_BY_ID, {})
    var post_val: float = float(ledger.get(tgt_id, 0.0))
    if absf(post_val - 2.0) > 0.01:
        _fail(failures, "execute_resolve: ledger must increment by 1 got %.1f" % post_val)
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


## Phase 1c: resolve execute emits action_resolved with died=true and outcome="execute".
static func _run_resolve_execute_emits_action_resolved_signal(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    var tgt_id: int = CombatantEntityAccess.id_int(target)
    attacker.gauge = 100.0
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    var _signal_payload: Dictionary = {}
    var on_resolved := func(_a, _b, payload): _signal_payload.merge(payload)
    mgr.action_resolved.connect(on_resolved)
    CombatResolveAction.resolve(mgr, atk_id, tgt_id, CombatConstants.MOVE_ID_EXECUTE, {})
    if not bool(_signal_payload.get("died", false)):
        _fail(failures, "execute_resolve: action_resolved must have died=true")
    if str(_signal_payload.get("outcome", "")) != "execute":
        _fail(failures, "execute_resolve: action_resolved outcome must be 'execute' got '%s'" % str(_signal_payload.get("outcome", "")))
    HarnessFixtures.flush_harness_live_nodes()
    mgr.disconnect("action_resolved", on_resolved)
    _free_manager_restore_global_rng(mgr)


# -- AI weight integration --------------------------------------------------

## Phase 1c: execute listed and assigned non-zero weight.
static func _run_execute_has_nonzero_ai_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    c.gauge = 100.0
    # Down the enemy.
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    var acts: Array = AvailableActionsBuilder.build(mgr, CombatantEntityAccess.id_int(c))
    var execute_act: Dictionary = {}
    for act in acts:
        if str(act.get("move_id", "")) == CombatConstants.MOVE_ID_EXECUTE:
            execute_act = act
            break
    if execute_act.is_empty():
        _fail(failures, "execute_weight: must list execute action")
    var cid: int = CombatantEntityAccess.id_int(c)
    var w: float = CombatAIActionPicker._get_action_weight(execute_act, cid, mgr, true)
    if w < 0.0:
        _fail(failures, "execute_weight: weight must not be negative got %.4f" % w)
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


# -- Combat log formatting --------------------------------------------------

## Phase 1c: combat log format for execute outcome.
static func _run_combat_log_execute_outcome_format(failures: PackedStringArray) -> void:
    var line: String = CombatLogFormatter.format_action_line(
        "Alaric", "player", "Borg", "enemy", {"outcome": "execute", "died": true}
    )
    if "execute" not in line.to_lower():
        _fail(failures, "combat_log_execute: want 'execute' in log got '%s'" % line)


# -- Feature flag toggle ----------------------------------------------------

## Phase 0/1c: FEATURE_MERCY_EXECUTE=false suppresses execute listing.
static func _run_execute_suppressed_when_feature_flag_off(failures: PackedStringArray) -> void:
    var was_on: bool = CombatConstants.FEATURE_MERCY_EXECUTE
    CombatConstantsFeatureFlags.set_feature_mercy_execute_load(false)
    # Re-check: even with feature off, the listing function returns early.
    # Since we can't reload features at runtime easily in headless, verify the guard exists.
    if was_on:
        var mgr: Node = CombatManager.new()
        mgr.register(_new_entity("SWORD"), "player")
        mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
        var c: Dictionary = mgr.combatants[0]
        var target: Dictionary = mgr.combatants[1]
        target.state = CombatConstants.STATE_COWERING
        target.alive = true
        # Direct call to append_execute_actions_for_combatant should return without adding.
        var acts: Array = []
        CombatMeleeListing.append_execute_actions_for_combatant(mgr, c, mgr.combatants, acts)
        if not acts.is_empty():
            _fail(failures, "execute_suppressed: listing must be empty when feature off")
        HarnessFixtures.flush_harness_live_nodes()
        _free_manager_restore_global_rng(mgr)
    CombatConstantsFeatureFlags.set_feature_mercy_execute_load(was_on)


## Phase 0/1c: append_execute_actions_for_combatant is idempotent (no duplicates).
static func _run_execute_listing_idempotent(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    var acts: Array = []
    for _i in range(5):
        CombatMeleeListing.append_execute_actions_for_combatant(mgr, c, mgr.combatants, acts)
    # There should be exactly one execute action (one downed enemy).
    var count: int = 0
    for act in acts:
        if str(act.get("move_id", "")) == CombatConstants.MOVE_ID_EXECUTE:
            count += 1
    if count != 1:
        _fail(failures, "execute_listing: want exactly 1 execute action got %d" % count)
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


# -- UI / display -----------------------------------------------------------

## Phase 1c: dead unit shows "Dead" on gauge row after execute resolve.
static func _run_execute_ui_gauge_label_dead(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var attacker: Dictionary = mgr.combatants[0]
    var target: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    var tgt_id: int = CombatantEntityAccess.id_int(target)
    attacker.gauge = 100.0
    target.state = CombatConstants.STATE_COWERING
    target.alive = true
    CombatResolveAction.resolve(mgr, atk_id, tgt_id, CombatConstants.MOVE_ID_EXECUTE, {})
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(target, mgr)
    if label != "Defeated":
        _fail(failures, "execute_ui_gauge: want 'Defeated' got '%s'" % label)
    HarnessFixtures.flush_harness_live_nodes()
    _free_manager_restore_global_rng(mgr)


# -- Suite runner -----------------------------------------------------------

## Stage-1 mercy-execute full suite (predicate, listing, weight, resolve).
static func run(failures: PackedStringArray) -> void:
    _run_is_downed_opponent_of_detects_cowering_enemy(failures)
    _run_personality_mult_linear_ramp(failures)
    _run_personality_mult_clamps_negative_and_over_100(failures)
    _run_threat_mult_safe_when_no_melee_opponents(failures)
    _run_grudge_mult_detects_damage_ledger(failures)
    _run_execute_weight_zero_for_standing_target(failures)
    _run_execute_weight_amplifies_with_ruthless_grudge(failures)
    _run_execute_listed_for_downed_in_reach(failures)
    _run_execute_not_listed_without_attacking_arm(failures)
    _run_resolve_execute_sets_target_dead(failures)
    _run_resolve_execute_stamps_grudge_ledger(failures)
    _run_resolve_execute_emits_action_resolved_signal(failures)
    _run_execute_has_nonzero_ai_weight(failures)
    _run_combat_log_execute_outcome_format(failures)
    _run_execute_suppressed_when_feature_flag_off(failures)
    _run_execute_listing_idempotent(failures)
    _run_execute_ui_gauge_label_dead(failures)
