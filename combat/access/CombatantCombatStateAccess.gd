class_name CombatantCombatStateAccess
extends CombatantIdentityAccess

## Combat state: stamina, gauge, alive, vitals, incapacitation.


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


static func state_str(combatant: Dictionary, default_state: String = "") -> String:
    return str(combatant.get(DataKeys.COMBATANT_STATE, default_state))


## `tactical_penetration_depth` (0 if unset).


## `tactical_penetration_depth` (0 if unset).
static func gauge_float(combatant: Dictionary, default_gauge: float = 0.0) -> float:
    return float(combatant.get(DataKeys.COMBATANT_GAUGE, default_gauge))


## Stamina (0 - `STAMINA_MAX` when key missing uses `default_if_missing`; use `0.0` when "missing = zero" for cost
## checks).


## Stamina (0 - `STAMINA_MAX` when key missing uses `default_if_missing`; use `0.0` when "missing = zero" for cost
## checks).
static func stamina_float(
    combatant: Dictionary, default_if_missing: float = CombatConstantsStamina.STAMINA_MAX
) -> float:
    return float(combatant.get(DataKeys.COMBATANT_STAMINA, default_if_missing))


## Breath (alternate/alias burst pool; canonical in new code per anti-patterns).


## Breath (alternate/alias burst pool; canonical in new code per anti-patterns).
static func breath_float(
    combatant: Dictionary, default_if_missing: float = CombatConstantsStamina.STAMINA_MAX
) -> float:
    if combatant.has(DataKeys.COMBATANT_BREATH):
        return float(combatant[DataKeys.COMBATANT_BREATH])
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
    return float(combatant.get(CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION, default_if_missing))


static func set_exhaustion_float(combatant: Dictionary, value: float) -> void:
    if combatant.is_empty():
        return
    combatant[CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION] = clampf(
        value, 0.0, CombatConstantsStamina.EXHAUSTION_MAX
    )


## Combat `stance` string (harness compatibility alias)  -  **`form_str`** fallback only; production bias uses
## **`form_str`** + **`CombatWeaponForm.mod`**.


## Combat `stance` string (harness compatibility alias)  -  **`form_str`** fallback only; production bias uses
## **`form_str`** + **`CombatWeaponForm.mod`**.
static func stance_str(
    combatant: Dictionary, default_stance: String = CombatConstantsFormationMove.STANCE_BALANCED
) -> String:
    return str(combatant.get(DataKeys.COMBATANT_STANCE, default_stance))


## Active weapon form id (Expand WF). Normalization at use sites via **`CombatWeaponForm`**.
## Footing: read for picker **`mod`**, UI **`Form`** suffix  -  **not** PA offset or parry step (those use
## **`guard_line`**). LIVE_PATHS **`#wf-assign-form-contract`**.


## Active weapon form id (Expand WF). Normalization at use sites via **`CombatWeaponForm`**.
## Footing: read for picker **`mod`**, UI **`Form`** suffix  -  **not** PA offset or parry step (those use
## **`guard_line`**). LIVE_PATHS **`#wf-assign-form-contract`**.
static func form_str(combatant: Dictionary) -> String:
    if combatant.is_empty():
        return CombatConstantsFormationMove.STANCE_BALANCED
    var raw: String = str(combatant.get(CombatConstantsMentalStack.COMBATANT_KEY_WEAPON_FORM, "")).strip_edges()
    if not raw.is_empty():
        return raw.to_lower()
    return stance_str(combatant).strip_edges().to_lower()


## Returns display name for logging/debug: node.name if available, else "id:{id}". Pass fallback_id when combatant may
## be null.


## Returns display name for logging/debug: node.name if available, else "id:{id}". Pass fallback_id when combatant may
## be null.
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
    var base_mod: float = 1.0
    if node.has_method("_get_hit_chance_performance_modifier"):
        base_mod = node._get_hit_chance_performance_modifier()
    elif node.has_method("get_performance_modifier"):
        base_mod = node.get_performance_modifier()
    return (
        base_mod
        * CombatConstantsStamina.exhaustion_performance_mult(
            combatant.get(CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION, 0.0)
        )
    )


## Action-bar / gauge fill performance. Falls back to get_performance_modifier when unavailable.


## Action-bar / gauge fill performance. Falls back to get_performance_modifier when unavailable.
static func get_action_bar_performance_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null:
        return 1.0
    var base_mod: float = 1.0
    if node.has_method("_get_action_bar_performance_modifier"):
        base_mod = node._get_action_bar_performance_modifier()
    elif node.has_method("get_performance_modifier"):
        base_mod = node.get_performance_modifier()
    return (
        base_mod
        * CombatConstantsStamina.exhaustion_performance_mult(
            combatant.get(CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION, 0.0)
        )
    )


## True when the scene node reports dead (bleed-out, fatal wound, etc.).


## True when the scene node reports dead (bleed-out, fatal wound, etc.).
static func is_dead(combatant: Dictionary) -> bool:
    var node = node_variant(combatant)
    if node == null or not node.has_method("is_dead"):
        return false
    return node.is_dead()


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


## Parry capacity modifier: pain in arms + concussion balance impairment + limb crippling.
static func get_parry_capacity_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_parry_capacity_modifier"):
        return 1.0
    return node.get_parry_capacity_modifier()


## Dodge speed modifier: leg pain + concussion balance impairment.
static func get_dodge_speed_modifier(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_dodge_speed_modifier"):
        return 1.0
    return node.get_dodge_speed_modifier()


## Cumulative pain degradation across all body parts (0-1, higher = more degraded).
static func get_cumulative_pain_degradation(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_vital_parts"):
        return 0.0
    var entity: Node = CombatantEntityAccess.combat_body(combatant)
    return EntityPainConsciousness.get_cumulative_pain_degradation(entity if entity != null else node)


## Limb crippling modifier for a specific part (1.0 = functional, <1.0 = impaired).
static func get_limb_crippling_modifier(combatant: Dictionary, limb_part: String) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_vital_parts"):
        return 1.0
    var entity: Node = CombatantEntityAccess.combat_body(combatant)
    return EntityPainConsciousness.get_limb_crippling_modifier(entity if entity != null else node, limb_part)


## Cumulative penalty from all damaged limbs (0-1).
static func get_cumulative_limb_penalty(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_vital_parts"):
        return 0.0
    var entity: Node = CombatantEntityAccess.combat_body(combatant)
    return EntityPainConsciousness.get_cumulative_limb_penalty(entity if entity != null else node)


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


static func finalize_dead_combatant_if_node_dead(manager: Node, c: Dictionary) -> bool:
    if c.is_empty() or not alive_bool(c):
        return false
    if not is_dead(c):
        return false
    c[DataKeys.COMBATANT_ALIVE] = false
    _get_footwork().clear_on_death(c)
    c[DataKeys.COMBATANT_STATE] = CombatConstantsState.STATE_DEAD
    _get_state_handlers().cancel_events_for_dead_combatant(manager, c)
    return true


## Returns attacking arm (e.g. "right_arm") or "" if none. Empty = no functional arm.


## Returns attacking arm (e.g. "right_arm") or "" if none. Empty = no functional arm.
static func get_attacking_arm(combatant: Dictionary) -> String:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_attacking_arm"):
        return ""
    return node.get_attacking_arm()


## Arm-wound grip factor for the attacking arm (1.0 healthy, down to ARM_WOUND_GRIP_FLOOR at a full
## localized wound). Feature-gated via BodyPartQuery.get_arm_wound_function_mult. Returns 1.0 when the
## attacking arm is empty or the node is unavailable. Used to slow wind-up for a wounded striking arm.
static func get_striking_arm_grip_mult(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null:
        return 1.0
    var arm: String = get_attacking_arm(combatant)
    if arm.is_empty():
        return 1.0
    return BodyPartQuery.get_arm_wound_function_mult(node, arm)


## Entity has any wound part not comprehensively dressed (bandage/pack/TQ). Direct pressure alone does not count.


## Entity has any wound part not comprehensively dressed (bandage/pack/TQ). Direct pressure alone does not count.
static func retreat_formation_body_damage_warranted(c: Dictionary, manager: Node) -> bool:
    if c.is_empty():
        return false
    if get_attacking_arm(c).is_empty():
        return true
    var node: Variant = node_variant(c)
    if node == null:
        return false
    if get_blood_volume_from_node(node as Node) < CombatConstantsFormation.FORMATION_RETREAT_BLOOD_VOLUME_MAX:
        return true
    if manager != null and _get_medical_phase().is_in_immediate_peril(manager, c):
        return true
    return false


## True when **`flee`** (leave the field / rout) is justified  -  see **`CombatFormationRout.abandonment_warranted`**.


## True when **`flee`** (leave the field / rout) is justified  -  see **`CombatFormationRout.abandonment_warranted`**.
static func flee_abandonment_warranted(c: Dictionary, manager: Node) -> bool:
    return _get_rout().abandonment_warranted(manager, c)


## Side formation `morale_cohesion_factor` (Tier 1.5 input to `line_cohesion`); 1.0 when unknown.


## Side formation `morale_cohesion_factor` (Tier 1.5 input to `line_cohesion`); 1.0 when unknown.
static func get_leg_functionality(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_leg_functionality"):
        return 1.0
    return node._get_leg_functionality()


## Lead-leg drive functionality (1.0 healthy, lower when the lead leg is wounded/destroyed).
## Used by wind-up drive so a compromised lead leg slows the step-in. D001-neutral at healthy values.
static func get_lead_leg_functionality(combatant: Dictionary) -> float:
    var node = node_variant(combatant)
    if node == null:
        return 1.0
    var part: String = node.lead_leg if "lead_leg" in node else BodyPartConstants.PART_RIGHT_LEG
    return BodyPartQuery.get_leg_functionality_for(node, part)


## Returns targetable body parts array. Empty if unavailable.


## Returns targetable body parts array. Empty if unavailable.
static func get_targetable_parts(combatant: Dictionary) -> Array:
    return get_targetable_parts_from_node(scene_node(combatant))


static func get_targetable_parts_from_node(node: Node) -> Array:
    if node == null or not node.has_method("_get_targetable_parts"):
        return []
    return node._get_targetable_parts()


## Returns true if combatant's node is incapacitated (consciousness/cowering) or has yielded.


static func is_yielded(combatant: Dictionary) -> bool:
    return state_str(combatant) == CombatConstantsState.STATE_YIELDED


## True when consciousness is below incapacitation floor (unconscious; cannot act or move).


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


## Returns dodge chance 0 - 1 with attacker windup override for realistic dodge model. Default 0.0 if unavailable.
static func get_dodge_chance_with_windup(combatant: Dictionary, attacker_windup_override: float = -1.0) -> float:
    var node = node_variant(combatant)
    if node == null or not node.has_method("_get_dodge_chance"):
        return 0.0
    var entity: Node = CombatantEntityAccess.combat_body(combatant)
    return EntityParryDodge.get_dodge_chance_with_windup(entity if entity != null else node, attacker_windup_override)


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
static func get_permanent_bleeding_rate_from_node(node: Node, fallback: float = 0.0) -> float:
    if node == null:
        return fallback
    if node.has_method("_get_permanent_bleeding_rate"):
        return node._get_permanent_bleeding_rate()
    return fallback
