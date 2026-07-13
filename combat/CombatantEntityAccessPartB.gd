class_name CombatantEntityAccessPartB
extends CombatantEntityAccessPartA


## True while combat clock is before `until`. Values below `inactive_below` are treated as off.
static func timestamp_cooldown_active(manager: Node, until: float, inactive_below: float = 0.0) -> bool:
    if manager == null:
        return false
    if until < inactive_below:
        return false
    return combat_clock_float(manager) < until


## True while combat clock is before the combatant's `cooldown_key` timestamp.
## Timestamps below `inactive_below` are treated as off (e.g. `-1` for formation CDs, `0` for unset).


## True while combat clock is before the combatant's `cooldown_key` timestamp.
## Timestamps below `inactive_below` are treated as off (e.g. `-1` for formation CDs, `0` for unset).
static func combatant_cooldown_active(
    manager: Node, combatant: Dictionary, cooldown_key: String, inactive_below: float = 0.0
) -> bool:
    if combatant.is_empty():
        return false
    return timestamp_cooldown_active(manager, float(combatant.get(cooldown_key, inactive_below)), inactive_below)


## Seconds until `until`; `0` when inactive or elapsed (for UI status lines).


## Seconds until `until`; `0` when inactive or elapsed (for UI status lines).
static func cooldown_remaining_s(manager: Node, until: float, inactive_below: float = 0.0) -> float:
    if not timestamp_cooldown_active(manager, until, inactive_below):
        return 0.0
    return until - combat_clock_float(manager)


## Opponent band from actor `distance_to` (default **LONG** when unset).


## Opponent band from actor `distance_to` (default **LONG** when unset).
static func distance_to_opponent_band(
    actor: Dictionary, opponent_id: int, default_band: String = CombatConstants.DISTANCE_LONG
) -> String:
    return str(nested_dictionary_read(actor, "distance_to").get(opponent_id, default_band))


## Combatant `id`; uses `default_id` when missing (common default: -1).


## Combatant `id`; uses `default_id` when missing (common default: -1).
static func id_int(combatant: Dictionary, default_id: int = -1) -> int:
    return int(combatant.get("id", default_id))


## `alive` flag; uses `default_alive` when missing (`false` for combat rules; `true` when absent should count as
## living).


## `alive` flag; uses `default_alive` when missing (`false` for combat rules; `true` when absent should count as
## living).
static func alive_bool(combatant: Dictionary, default_alive: bool = false) -> bool:
    var v = combatant.get("alive", default_alive)
    return v == true


## `state` string; uses `default_state` when missing.


## `state` string; uses `default_state` when missing.
static func state_str(combatant: Dictionary, default_state: String = "") -> String:
    return str(combatant.get("state", default_state))


## `tactical_penetration_depth` (0 if unset).


## `tactical_penetration_depth` (0 if unset).
static func tactical_penetration_depth_int(combatant: Dictionary) -> int:
    return combatant.get("tactical_penetration_depth", 0)


## `stats` sub-dictionary (strength, agility, ...). Empty if missing or wrong type.
## May alias `combatant["stats"]`  -  do not replace the combatant's stats reference from call sites.


## `stats` sub-dictionary (strength, agility, ...). Empty if missing or wrong type.
## May alias `combatant["stats"]`  -  do not replace the combatant's stats reference from call sites.
static func stats_dict(combatant: Dictionary) -> Dictionary:
    var s: Variant = combatant.get("stats", null)
    if s is Dictionary:
        return s
    return {}


## Turn / action gauge (readiness), typically 0 - 100.


## Turn / action gauge (readiness), typically 0 - 100.
static func gauge_float(combatant: Dictionary, default_gauge: float = 0.0) -> float:
    return float(combatant.get("gauge", default_gauge))


## Stamina (0 - `STAMINA_MAX` when key missing uses `default_if_missing`; use `0.0` when "missing = zero" for cost
## checks).


## Stamina (0 - `STAMINA_MAX` when key missing uses `default_if_missing`; use `0.0` when "missing = zero" for cost
## checks).
static func stamina_float(combatant: Dictionary, default_if_missing: float = CombatConstants.STAMINA_MAX) -> float:
    return float(combatant.get("stamina", default_if_missing))


## Breath (alternate/alias burst pool; canonical in new code per anti-patterns).


## Breath (alternate/alias burst pool; canonical in new code per anti-patterns).
static func breath_float(combatant: Dictionary, default_if_missing: float = CombatConstants.STAMINA_MAX) -> float:
    if combatant.has("breath"):
        return float(combatant["breath"])
    return stamina_float(combatant, default_if_missing)


## Burst pool ratio vs **`CombatExhaustion.effective_stamina_max`** (exhaustion + blood).


## Burst pool ratio vs **`CombatExhaustion.effective_stamina_max`** (exhaustion + blood).
static func stamina_ratio(combatant: Dictionary) -> float:
    return _load_exhaustion().stamina_ratio(combatant)


## Current burst ceiling (see **`CombatExhaustion.effective_stamina_max`**).


## Current burst ceiling (see **`CombatExhaustion.effective_stamina_max`**).
static func stamina_effective_max(combatant: Dictionary) -> float:
    return _load_exhaustion().effective_stamina_max(combatant)


## MXm: cumulative fight exhaustion index (0 - `EXHAUSTION_MAX`).


## MXm: cumulative fight exhaustion index (0 - `EXHAUSTION_MAX`).
static func exhaustion_float(combatant: Dictionary, default_if_missing: float = 0.0) -> float:
    return float(combatant.get(CombatConstants.COMBATANT_KEY_EXHAUSTION, default_if_missing))


static func set_exhaustion_float(combatant: Dictionary, value: float) -> void:
    if combatant.is_empty():
        return
    combatant[CombatConstants.COMBATANT_KEY_EXHAUSTION] = clampf(value, 0.0, CombatConstants.EXHAUSTION_MAX)


## Combat `stance` string (harness compatibility alias)  -  **`form_str`** fallback only; production bias uses
## **`form_str`** + **`CombatWeaponForm.mod`**.


## Combat `stance` string (harness compatibility alias)  -  **`form_str`** fallback only; production bias uses
## **`form_str`** + **`CombatWeaponForm.mod`**.
static func stance_str(combatant: Dictionary, default_stance: String = CombatConstants.STANCE_BALANCED) -> String:
    return str(combatant.get("stance", default_stance))


## Active weapon form id (Expand WF). Normalization at use sites via **`CombatWeaponForm`**.
## Footing: read for picker **`mod`**, UI **`Form`** suffix  -  **not** PA offset or parry step (those use
## **`guard_line`**). LIVE_PATHS **`#wf-assign-form-contract`**.


## Active weapon form id (Expand WF). Normalization at use sites via **`CombatWeaponForm`**.
## Footing: read for picker **`mod`**, UI **`Form`** suffix  -  **not** PA offset or parry step (those use
## **`guard_line`**). LIVE_PATHS **`#wf-assign-form-contract`**.
static func form_str(combatant: Dictionary) -> String:
    if combatant.is_empty():
        return CombatConstants.STANCE_BALANCED
    var raw: String = str(combatant.get(CombatConstants.COMBATANT_KEY_WEAPON_FORM, "")).strip_edges()
    if not raw.is_empty():
        return raw.to_lower()
    return stance_str(combatant).strip_edges().to_lower()


## Returns display name for logging/debug: node.name if available, else "id:{id}". Pass fallback_id when combatant may
## be null.


## Returns display name for logging/debug: node.name if available, else "id:{id}". Pass fallback_id when combatant may
## be null.
static func get_display_name(combatant: Variant, fallback_id: int = -1) -> String:
    if combatant == null or not (combatant is Dictionary):
        return "id:%d" % fallback_id
    var node = node_variant(combatant)
    if node != null:
        return str(node.name)
    return "id:%d" % id_int(combatant, fallback_id)


## Returns true if combatant's node has a weapon.


## Returns true if combatant's node has a weapon.
static func has_weapon(combatant: Dictionary) -> bool:
    return get_weapon(combatant) != null


## Returns weapon from node directly. Use when caller has node (not combatant dict).


## Returns weapon from node directly. Use when caller has node (not combatant dict).
static func get_weapon_from_node(node: Node) -> Variant:
    if node == null or not node.has_method("get_weapon"):
        return null
    return node.get_weapon()


## Returns armor slots from node. Use when caller has node (not combatant dict).


## Returns armor slots from node. Use when caller has node (not combatant dict).
static func get_armor_slots_from_node(node: Node) -> Dictionary:
    if node == null or not node.has_method("_get_armor_slots"):
        return {}
    return node._get_armor_slots()


## Returns weapon display name for UI. Empty if no weapon or node unavailable.


## Returns weapon display name for UI. Empty if no weapon or node unavailable.
static func get_weapon_display_name_from_node(node: Node) -> String:
    var w = get_weapon_from_node(node)
    if w == null:
        return ""
    if "display_name" in w and w.display_name:
        return str(w.display_name)
    if "weapon_type" in w:
        return str(w.weapon_type)
    return "?"


## Returns armor piece display names for UI (e.g. ["Cuirass", "Gambeson"]).


## Returns armor piece display names for UI (e.g. ["Cuirass", "Gambeson"]).
static func get_armor_summary_from_node(node: Node) -> Array:
    var slots: Dictionary = get_armor_slots_from_node(node)
    var names: Array = []
    for part in slots.keys():
        var piece = slots[part]
        if piece != null and "display_name" in piece and piece.display_name:
            names.append(piece.display_name)
    return names


## Sum of equipped ArmorPiece.get_total_mass_kg()  -  formation moves, encumbrance tuning.


## Sum of equipped ArmorPiece.get_total_mass_kg()  -  formation moves, encumbrance tuning.
static func get_total_armor_mass_kg_from_node(node: Node) -> float:
    if node == null or not node.has_method("_get_armor_slots"):
        return 0.0
    var slots: Dictionary = node._get_armor_slots()
    var total: float = 0.0
    for part in slots.keys():
        var piece = slots[part]
        if piece != null and piece.has_method("get_total_mass_kg"):
            total += piece.get_total_mass_kg()
    return total


## Returns performance modifier (pain/consciousness) from combatant's node. Default 1.0 if unavailable.


## Returns performance modifier (pain/consciousness) from combatant's node. Default 1.0 if unavailable.
static func get_performance_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_performance_modifier"):
        return 1.0
    return node.get_performance_modifier()


## Returns hit-chance-specific performance modifier. Falls back to get_performance_modifier if unavailable.


## Returns hit-chance-specific performance modifier. Falls back to get_performance_modifier if unavailable.
static func get_hit_chance_performance_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null:
        return 1.0
    if node.has_method("_get_hit_chance_performance_modifier"):
        return node._get_hit_chance_performance_modifier()
    if node.has_method("get_performance_modifier"):
        return node.get_performance_modifier()
    return 1.0


## Action-bar / gauge fill performance. Falls back to get_performance_modifier when unavailable.


## Action-bar / gauge fill performance. Falls back to get_performance_modifier when unavailable.
static func get_action_bar_performance_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null:
        return 1.0
    if node.has_method("_get_action_bar_performance_modifier"):
        return node._get_action_bar_performance_modifier()
    if node.has_method("get_performance_modifier"):
        return node.get_performance_modifier()
    return 1.0


## True when the scene node reports dead (bleed-out, fatal wound, etc.).


## True when the scene node reports dead (bleed-out, fatal wound, etc.).
static func is_dead(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_dead"):
        return false
    return node.is_dead()


static func has_left_battlefield(combatant: Dictionary) -> bool:
    return combatant.get("combat_absent", false) or state_str(combatant) == CombatConstants.STATE_FLED


## `alive` combatant flag, on the field, and not `is_dead` on the scene node.


## `alive` combatant flag, on the field, and not `is_dead` on the scene node.
static func is_alive_in_combat(combatant: Dictionary) -> bool:
    if has_left_battlefield(combatant):
        return false
    return alive_bool(combatant) and not is_dead(combatant)


static func is_on_battlefield(combatant: Dictionary) -> bool:
    return is_alive_in_combat(combatant)


## Death log string from node; empty when unavailable.


## Death log string from node; empty when unavailable.
static func get_death_reason(combatant: Dictionary) -> String:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_death_reason"):
        return ""
    return str(node._get_death_reason())


## Arm functionality / injury damage scale for strikes and parry capacity. Default 1.0.


## Arm functionality / injury damage scale for strikes and parry capacity. Default 1.0.
static func get_attack_damage_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_attack_damage_modifier"):
        return 1.0
    return node._get_attack_damage_modifier()


static func has_passive_parry_reaction_time(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    return node != null and node.has_method("_get_passive_parry_reaction_time")


## Passive parry reaction window (seconds). Default 0.0 when node lacks the method.


## Passive parry reaction window (seconds). Default 0.0 when node lacks the method.
static func get_passive_parry_reaction_time(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_passive_parry_reaction_time"):
        return 0.0
    return node._get_passive_parry_reaction_time()


## Sets `blunt_opts["armor_resistance_rha_mm"]` when the defender node exposes armor RHA for `part`.


## Sets `blunt_opts["armor_resistance_rha_mm"]` when the defender node exposes armor RHA for `part`.
static func apply_armor_sharp_resistance_to_blunt_opts(
    blunt_opts: Dictionary, defender: Dictionary, part: String
) -> void:
    var node: Node = scene_node(defender)
    if node != null and node.has_method("_get_armor_sharp_resistance_for_part"):
        blunt_opts["armor_resistance_rha_mm"] = node._get_armor_sharp_resistance_for_part(part)


static func sync_close_distance_pair(atk: Dictionary, tgt: Dictionary, attacker_id: int, target_id: int) -> void:
    nested_dictionary_for_mutation(atk, "distance_to")[target_id] = CombatConstants.DISTANCE_CLOSE
    nested_dictionary_for_mutation(tgt, "distance_to")[attacker_id] = CombatConstants.DISTANCE_CLOSE


static func finalize_dead_combatant_if_node_dead(manager: Node, c: Dictionary) -> bool:
    if c.is_empty() or not alive_bool(c):
        return false
    if not is_dead(c):
        return false
    c["alive"] = false
    _get_footwork().clear_on_death(c)
    c["state"] = CombatConstants.STATE_DEAD
    _get_state_handlers().cancel_events_for_dead_combatant(manager, c)
    return true


## Returns attacking arm (e.g. "right_arm") or "" if none. Empty = no functional arm.


## Returns attacking arm (e.g. "right_arm") or "" if none. Empty = no functional arm.
static func get_attacking_arm(combatant: Dictionary) -> String:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_attacking_arm"):
        return ""
    return node.get_attacking_arm()


## Entity has any wound part not comprehensively dressed (bandage/pack/TQ). Direct pressure alone does not count.


## Entity has any wound part not comprehensively dressed (bandage/pack/TQ). Direct pressure alone does not count.
static func entity_has_untreated_wounds(entity: Node) -> bool:
    return _get_entity_wounds().entity_has_untreated_wounds(entity)


## Medical danger / peril  -  delegates to **`MedicalPhaseController`** (AGENTS canonical names).


## Medical danger / peril  -  delegates to **`MedicalPhaseController`** (AGENTS canonical names).
static func is_in_medical_danger(manager: Node, c: Dictionary) -> bool:
    return _get_medical_phase().is_in_medical_danger(manager, c)


static func is_in_immediate_peril(manager: Node, c: Dictionary) -> bool:
    return _get_medical_phase().is_in_immediate_peril(manager, c)


static func has_left_immediate_peril_permanently(manager: Node, c: Dictionary) -> bool:
    return _get_medical_phase().has_left_immediate_peril_permanently(manager, c)


## True when formation **retreat** (disengage swap, drag/fall_back pair, solo fall_back) is justified by injury or peril
## -  not fatigue-only composite fitness.


## True when formation **retreat** (disengage swap, drag/fall_back pair, solo fall_back) is justified by injury or peril
## -  not fatigue-only composite fitness.
static func retreat_formation_body_damage_warranted(c: Dictionary, manager: Node) -> bool:
    if c.is_empty():
        return false
    if get_attacking_arm(c).is_empty():
        return true
    var node: Variant = node_variant(c)
    if node == null:
        return false
    if get_blood_volume_from_node(node as Node) < CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX:
        return true
    if manager != null and is_in_immediate_peril(manager, c):
        return true
    return false


## True when **`flee`** (leave the field / rout) is justified  -  see **`CombatFormationRout.abandonment_warranted`**.


## True when **`flee`** (leave the field / rout) is justified  -  see **`CombatFormationRout.abandonment_warranted`**.
static func flee_abandonment_warranted(c: Dictionary, manager: Node) -> bool:
    return _get_rout().abandonment_warranted(manager, c)


## Side formation `morale_cohesion_factor` (Tier 1.5 input to `line_cohesion`); 1.0 when unknown.


## Side formation `morale_cohesion_factor` (Tier 1.5 input to `line_cohesion`); 1.0 when unknown.
static func formation_morale_cohesion_factor(manager: Node, c: Dictionary) -> float:
    if manager == null or not manager.get("formations"):
        return 1.0
    var fid: String = formation_id_str(c)
    if fid.is_empty():
        return 1.0
    var form: Dictionary = _get_formation_slots().formation_record_for_manager(manager, fid)
    return clampf(form.get("morale_cohesion_factor", 1.0), CombatConstants.MORALE_COHESION_FACTOR_MIN, 1.0)


## Returns leg functionality 0 - 1. Default 1.0 if unavailable.


## Returns leg functionality 0 - 1. Default 1.0 if unavailable.
static func get_leg_functionality(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_leg_functionality"):
        return 1.0
    return node._get_leg_functionality()


## Returns targetable body parts array. Empty if unavailable.


## Returns targetable body parts array. Empty if unavailable.
static func get_targetable_parts(combatant: Dictionary) -> Array:
    return get_targetable_parts_from_node(scene_node(combatant))


static func get_targetable_parts_from_node(node: Node) -> Array:
    if node == null or not node.has_method("_get_targetable_parts"):
        return []
    return node._get_targetable_parts()


## Returns true if combatant's node is incapacitated (consciousness/cowering) or has yielded.


## Returns true if combatant's node is incapacitated (consciousness/cowering) or has yielded.
static func is_incapacitated(combatant: Dictionary) -> bool:
    if is_yielded(combatant):
        return true
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_incapacitated"):
        return false
    return node.is_incapacitated()


## Voluntary surrender: non-standing but remains on the field.


## Voluntary surrender: non-standing but remains on the field.
static func is_yielded(combatant: Dictionary) -> bool:
    return state_str(combatant) == CombatConstants.STATE_YIELDED


## True when consciousness is below incapacitation floor (unconscious; cannot act or move).


## True when consciousness is below incapacitation floor (unconscious; cannot act or move).
static func is_unconscious(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_unconscious"):
        return false
    return node.is_unconscious()


## Tier 6.1: arm loss during combat  -  sync cowering, cancel stale turns, abort wind-up (see
## **`CombatMobilityRetreat`**).


## Tier 6.1: arm loss during combat  -  sync cowering, cancel stale turns, abort wind-up (see
## **`CombatMobilityRetreat`**).
static func react_attacking_arm_lost_if_needed(manager: Node, combatant: Dictionary) -> void:
    _get_mobility_retreat().react_attacking_arm_lost_if_needed(manager, combatant)


## True when unit has no functional attacking arm (cowering posture on entity).


## True when unit has no functional attacking arm (cowering posture on entity).
static func is_cowering(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_cowering"):
        return false
    return node.is_cowering()


## True when unit can disengage via formation retreat (leg mobility + not unconscious). Cowering may qualify.


## True when unit can disengage via formation retreat (leg mobility + not unconscious). Cowering may qualify.
static func can_flee_or_fall_back(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("can_flee_or_fall_back"):
        return false
    return node.can_flee_or_fall_back()


## Returns part-specific dodge modifier. Default 1.0 if unavailable.


## Returns part-specific dodge modifier. Default 1.0 if unavailable.
static func _get_part_dodge_modifier(combatant: Dictionary, part: String) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_part_dodge_modifier"):
        return 1.0
    return node._get_part_dodge_modifier(part)


## Returns dodge chance 0 - 1. Default 0.0 if unavailable.


## Returns dodge chance 0 - 1. Default 0.0 if unavailable.
static func get_dodge_chance(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_dodge_chance"):
        return 0.0
    return node._get_dodge_chance()


## Returns blood volume 0 - 100 from node. Default 100.0 if unavailable.


## Returns blood volume 0 - 100 from node. Default 100.0 if unavailable.
static func get_blood_volume_from_node(node: Node) -> float:
    if node == null:
        return 100.0
    if node.has_method("_get_blood_volume"):
        return node._get_blood_volume()
    if "blood_volume" in node:
        return float(node.blood_volume)
    return 100.0


## Returns total bleeding rate from node. Default 0.0 if unavailable.


## Returns total bleeding rate from node. Default 0.0 if unavailable.
static func get_total_bleeding_rate_from_node(node: Node) -> float:
    if node == null:
        return 0.0
    if node.has_method("_get_total_bleeding_rate"):
        return node._get_total_bleeding_rate()
    return 0.0


## Returns medical effectiveness 0 - 1.5 from node. Default 1.0 if unavailable.
## Wind-up speed: self-care uses medic shock; ally-care uses training + small patient thrash penalty.


## Returns medical effectiveness 0 - 1.5 from node. Default 1.0 if unavailable.
## Wind-up speed: self-care uses medic shock; ally-care uses training + small patient thrash penalty.
static func get_medical_windup_speed_modifier(manager: Node, performer: Dictionary, target: Dictionary) -> float:
    var perf_entity: Node = get_entity_from_manager(manager, performer)
    var med_eff: float = get_medical_effectiveness_from_node(perf_entity)
    med_eff = maxf(0.5, med_eff)
    if id_int(performer) == id_int(target):
        var perf: float = get_performance_modifier(performer)
        return maxf(CombatConstants.PERF_MOD_MIN, perf) * med_eff
    var patient_perf: float = get_performance_modifier(target)
    var thrash: float = (
        clampf(1.0 - patient_perf, 0.0, 1.0) * CombatConstants.MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY
    )
    return med_eff * (1.0 - thrash)


## Effective medical wind-up speed: reads INT from combatant stats dict (includes proficiency bonuses via
## _copy_core_stats()).
## Use this when proficiency system is enabled instead of get_medical_windup_speed_modifier().


## Effective medical wind-up speed: reads INT from combatant stats dict (includes proficiency bonuses via
## _copy_core_stats()).
## Use this when proficiency system is enabled instead of get_medical_windup_speed_modifier().
static func get_effective_medical_windup_speed_modifier(
    _manager: Node, performer: Dictionary, target: Variant
) -> float:
    var perf_node = node_variant(performer)
    var eff_int: float = 100.0
    if perf_node != null and "_proficiency_bonus" in perf_node:
        eff_int = float(perf_node.intelligence or 0) + float(perf_node._proficiency_bonus.get("intelligence", 0) or 0)
    else:
        eff_int = float(performer.get("intelligence", CombatConstants.DEFAULT_STAT_VALUE))
    var med_eff: float = clampf(
        eff_int / 100.0, CombatConstants.STAT_EFFECT_MULT_MIN, CombatConstants.STAT_EFFECT_MULT_MAX
    )
    med_eff = maxf(0.5, med_eff)
    if id_int(performer) == id_int(target):
        var perf: float = get_performance_modifier(performer)
        return maxf(CombatConstants.PERF_MOD_MIN, perf) * med_eff
    var patient_perf: float = get_performance_modifier(target)
    var thrash: float = (
        clampf(1.0 - patient_perf, 0.0, 1.0) * CombatConstants.MEDICAL_ALLY_TASK_PATIENT_THRASH_MAX_PENALTY
    )
    return med_eff * (1.0 - thrash)


## Divisor for dressing wind-up when compression is held (primary holder / stacked assist).


## Divisor for dressing wind-up when compression is held (primary holder / stacked assist).
static func get_medical_windup_assist_duration_divisor(manager: Node, target: Dictionary, part: String) -> float:
    var divisor: float = 1.0
    var tgt_entity: Node = get_entity_from_manager(manager, target)
    if tgt_entity == null or part.is_empty():
        return divisor
    if part_has_active_direct_pressure_on_entity(tgt_entity, part):
        divisor += CombatConstants.MEDICAL_WINDUP_PRIMARY_HOLDER_DURATION_BONUS
    if tgt_entity.get("direct_pressure_assist_held_by") != null and tgt_entity.direct_pressure_assist_held_by != null:
        divisor += CombatConstants.MEDICAL_WINDUP_STACK_ASSIST_DURATION_BONUS
    return divisor


static func part_has_active_direct_pressure_on_entity(entity: Node, part: String) -> bool:
    if entity == null or part.is_empty():
        return false
    if entity.has_method("has_direct_pressure_on_part"):
        return entity.has_direct_pressure_on_part(part)
    return false


static func get_medical_effectiveness_from_node(node: Node) -> float:
    if node == null:
        return 1.0
    if node.has_method("_get_medical_effectiveness"):
        return node._get_medical_effectiveness()
    return 1.0


static func manager_schedule_event(manager: Node, ev: Dictionary) -> void:
    if manager != null and manager.has_method("_schedule_event"):
        manager._schedule_event(ev)


static func manager_skip_turn(manager: Node, combatant_id: int, reason: String, detail: String = "") -> void:
    if manager != null and manager.has_method("skip_turn"):
        manager.skip_turn(combatant_id, reason, detail)


static func manager_apply_formation_hit_reaction_if_needed(
    manager: Node, combatant_id: int, intensity: float = 0.5
) -> void:
    if manager != null and manager.has_method("_apply_formation_hit_reaction_if_needed"):
        manager._apply_formation_hit_reaction_if_needed(combatant_id, intensity)


## Returns permanent bleeding rate from node. Default fallback if unavailable.


## Returns permanent bleeding rate from node. Default fallback if unavailable.
static func get_permanent_bleeding_rate_from_node(node: Node, fallback: float = 0.0) -> float:
    if node == null:
        return fallback
    if node.has_method("_get_permanent_bleeding_rate"):
        return node._get_permanent_bleeding_rate()
    return fallback
