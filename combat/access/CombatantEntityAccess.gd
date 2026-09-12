class_name CombatantEntityAccess
extends RefCounted


# ── Lazy-loaded child accessors (break circular dependency) ──────────────

static var _manager_bridge_cache: GDScript = null
static var _identity_cache: GDScript = null
static var _combat_state_cache: GDScript = null
static var _weapon_cache: GDScript = null
static var _medical_cache: GDScript = null


static func _get_manager_bridge() -> GDScript:
	if _manager_bridge_cache == null:
		_manager_bridge_cache = load("res://combat/access/CombatantManagerBridge.gd")
	return _manager_bridge_cache


static func _get_identity() -> GDScript:
	if _identity_cache == null:
		_identity_cache = load("res://combat/access/CombatantIdentityAccess.gd")
	return _identity_cache


static func _get_combat_state() -> GDScript:
	if _combat_state_cache == null:
		_combat_state_cache = load("res://combat/access/CombatantCombatStateAccess.gd")
	return _combat_state_cache


static func _get_weapon() -> GDScript:
	if _weapon_cache == null:
		_weapon_cache = load("res://combat/access/CombatantWeaponAccess.gd")
	return _weapon_cache


static func _get_medical() -> GDScript:
	if _medical_cache == null:
		_medical_cache = load("res://combat/access/CombatantMedicalEntityAccess.gd")
	return _medical_cache


# ═══════════════════════════════════════════════════════════════════════
# CombatantManagerBridge  (base) — alive, node, dict, clock, manager
# ═══════════════════════════════════════════════════════════════════════

static func alive_bool(combatant: Dictionary, default_alive: bool = false) -> bool:
	return _get_manager_bridge().alive_bool(combatant, default_alive)


static func is_alive_in_combat(combatant: Dictionary) -> bool:
	return _get_manager_bridge().is_alive_in_combat(combatant)


static func is_unconscious(combatant: Dictionary) -> bool:
	return _get_manager_bridge().is_unconscious(combatant)


static func has_left_battlefield(combatant: Dictionary) -> bool:
	return _get_manager_bridge().has_left_battlefield(combatant)


static func is_incapacitated(combatant: Dictionary) -> bool:
	return _get_manager_bridge().is_incapacitated(combatant)


static func node_variant(combatant: Dictionary) -> Variant:
	return _get_manager_bridge().node_variant(combatant)


static func scene_node(combatant: Dictionary) -> Node:
	return _get_manager_bridge().scene_node(combatant)


static func combatant_dict_or_empty(v: Variant) -> Dictionary:
	return _get_manager_bridge().combatant_dict_or_empty(v)


static func manager_get_combatant(manager: Node, combatant_id: int) -> Dictionary:
	return _get_manager_bridge().manager_get_combatant(manager, combatant_id)


static func manager_get_combatant_optional(manager: Node, combatant_id: int) -> Dictionary:
	return _get_manager_bridge().manager_get_combatant_optional(manager, combatant_id)


static func manager_notify_turn_ready(manager: Node, combatant_id: int) -> void:
	_get_manager_bridge().manager_notify_turn_ready(manager, combatant_id)


static func manager_notify_formation_changed(manager: Node, fid: String) -> void:
	_get_manager_bridge().manager_notify_formation_changed(manager, fid)


static func manager_notify_engagement_state_changed(
	manager: Node, fid: String, cohesion: float, posture: String
) -> void:
	_get_manager_bridge().manager_notify_engagement_state_changed(manager, fid, cohesion, posture)


static func stats_dict_for_mutation(combatant: Dictionary) -> Dictionary:
	return _get_manager_bridge().stats_dict_for_mutation(combatant)


static func nested_dictionary_for_mutation(combatant: Dictionary, key: String) -> Dictionary:
	return _get_manager_bridge().nested_dictionary_for_mutation(combatant, key)


static func nested_dictionary_read(combatant: Dictionary, key: String) -> Dictionary:
	return _get_manager_bridge().nested_dictionary_read(combatant, key)


static func nested_array_for_mutation(combatant: Dictionary, key: String) -> Array:
	return _get_manager_bridge().nested_array_for_mutation(combatant, key)


static func combat_clock_float(manager: Node) -> float:
	return _get_manager_bridge().combat_clock_float(manager)


static func combat_clock_plus(manager: Node, offset_s: float) -> float:
	return _get_manager_bridge().combat_clock_plus(manager, offset_s)


static func manager_schedule_event(manager: Node, ev: Dictionary) -> void:
	_get_manager_bridge().manager_schedule_event(manager, ev)


static func manager_skip_turn(manager: Node, combatant_id: int, reason: String, detail: String = "") -> void:
	_get_manager_bridge().manager_skip_turn(manager, combatant_id, reason, detail)


static func manager_apply_formation_hit_reaction_if_needed(
	manager: Node, combatant_id: int, intensity: float = 0.5
) -> void:
	_get_manager_bridge().manager_apply_formation_hit_reaction_if_needed(manager, combatant_id, intensity)


# ═══════════════════════════════════════════════════════════════════════
# CombatantIdentityAccess — side, rank, file, formation, identity
# ═══════════════════════════════════════════════════════════════════════

static func is_living_same_side(actor: Dictionary, other: Dictionary) -> bool:
	return _get_identity().is_living_same_side(actor, other)


static func is_available_formation_partner(actor: Dictionary, other: Dictionary) -> bool:
	return _get_identity().is_available_formation_partner(actor, other)


static func is_available_medical_ally(actor: Dictionary, other: Dictionary) -> bool:
	return _get_identity().is_available_medical_ally(actor, other)


static func is_alive_opponent_of(actor: Dictionary, other: Dictionary) -> bool:
	return _get_identity().is_alive_opponent_of(actor, other)


static func is_living_hostile_to(actor: Dictionary, other: Dictionary) -> bool:
	return _get_identity().is_living_hostile_to(actor, other)


static func is_alive_on_side(combatant: Dictionary, side: String) -> bool:
	return _get_identity().is_alive_on_side(combatant, side)


static func is_living_on_side(combatant: Dictionary, side: String) -> bool:
	return _get_identity().is_living_on_side(combatant, side)


static func are_alive_opponents(a: Dictionary, b: Dictionary) -> bool:
	return _get_identity().are_alive_opponents(a, b)


static func are_living_hostiles(a: Dictionary, b: Dictionary) -> bool:
	return _get_identity().are_living_hostiles(a, b)


static func are_both_alive(a: Dictionary, b: Dictionary) -> bool:
	return _get_identity().are_both_alive(a, b)


static func is_standing_combatant(combatant: Dictionary) -> bool:
	return _get_identity().is_standing_combatant(combatant)


static func is_on_side(combatant: Dictionary, side: String) -> bool:
	return _get_identity().is_on_side(combatant, side)


static func is_player_side(combatant: Dictionary) -> bool:
	return _get_identity().is_player_side(combatant)


static func is_enemy_side(combatant: Dictionary) -> bool:
	return _get_identity().is_enemy_side(combatant)


static func is_living_opponent_of_by_side(combatant: Dictionary, my_side: String) -> bool:
	return _get_identity().is_living_opponent_of_by_side(combatant, my_side)

static func leader_register_flags_from_node(node: Node, side: String) -> Dictionary:
	return _get_identity().leader_register_flags_from_node(node, side)


static func is_formation_command_issuer(combatant: Dictionary) -> bool:
	return _get_identity().is_formation_command_issuer(combatant)


static func is_formation_telegraph_leader(combatant: Dictionary) -> bool:
	return _get_identity().is_formation_telegraph_leader(combatant)


static func opponent_side_for(actor: Dictionary) -> String:
	return _get_identity().opponent_side_for(actor)


static func opponent_side_label(side: String) -> String:
	return _get_identity().opponent_side_label(side)


static func formation_id_str(combatant: Dictionary) -> String:
	return _get_identity().formation_id_str(combatant)


static func side_str(combatant: Dictionary) -> String:
	return _get_identity().side_str(combatant)


static func rank_int(combatant: Dictionary, default_rank: int = 0) -> int:
	return _get_identity().rank_int(combatant, default_rank)


static func file_int(combatant: Dictionary, default_file: int = 0) -> int:
	return _get_identity().file_int(combatant, default_file)


static func lane_offset_float(combatant: Dictionary) -> float:
	return _get_identity().lane_offset_float(combatant)


static func distance_to_opponent_band(
	actor: Dictionary, opponent_id: int, default_band: String = CombatConstantsDistance.DISTANCE_LONG
) -> String:
	return _get_identity().distance_to_opponent_band(actor, opponent_id, default_band)


static func id_int(combatant: Dictionary, default_id: int = -1) -> int:
	return _get_identity().id_int(combatant, default_id)


static func tactical_penetration_depth_int(combatant: Dictionary) -> int:
	return _get_identity().tactical_penetration_depth_int(combatant)


static func stats_dict(combatant: Dictionary) -> Dictionary:
	return _get_identity().stats_dict(combatant)


static func get_display_name(combatant: Variant, fallback_id: int = -1) -> String:
	return _get_identity().get_display_name(combatant, fallback_id)


static func sync_close_distance_pair(atk: Dictionary, tgt: Dictionary, attacker_id: int, target_id: int) -> void:
	_get_identity().sync_close_distance_pair(atk, tgt, attacker_id, target_id)


static func formation_morale_cohesion_factor(manager: Node, c: Dictionary) -> float:
	return _get_identity().formation_morale_cohesion_factor(manager, c)


# ═══════════════════════════════════════════════════════════════════════
# CombatantCombatStateAccess — stamina, gauge, stance/form, death, etc.
# ═══════════════════════════════════════════════════════════════════════

static func timestamp_cooldown_active(manager: Node, until: float, inactive_below: float = 0.0) -> bool:
	return _get_combat_state().timestamp_cooldown_active(manager, until, inactive_below)


static func combatant_cooldown_active(
	manager: Node, combatant: Dictionary, cooldown_key: String, inactive_below: float = 0.0
) -> bool:
	return _get_combat_state().combatant_cooldown_active(manager, combatant, cooldown_key, inactive_below)


static func cooldown_remaining_s(manager: Node, until: float, inactive_below: float = 0.0) -> float:
	return _get_combat_state().cooldown_remaining_s(manager, until, inactive_below)


static func state_str(combatant: Dictionary, default_state: String = "") -> String:
	return _get_combat_state().state_str(combatant, default_state)


static func gauge_float(combatant: Dictionary, default_gauge: float = 0.0) -> float:
	return _get_combat_state().gauge_float(combatant, default_gauge)


static func stamina_float(
	combatant: Dictionary, default_if_missing: float = CombatConstantsStamina.STAMINA_MAX
) -> float:
	return _get_combat_state().stamina_float(combatant, default_if_missing)


static func breath_float(
	combatant: Dictionary, default_if_missing: float = CombatConstantsStamina.STAMINA_MAX
) -> float:
	return _get_combat_state().breath_float(combatant, default_if_missing)


static func stamina_ratio(combatant: Dictionary) -> float:
	return _get_combat_state().stamina_ratio(combatant)


static func stamina_effective_max(combatant: Dictionary) -> float:
	return _get_combat_state().stamina_effective_max(combatant)


static func exhaustion_float(combatant: Dictionary, default_if_missing: float = 0.0) -> float:
	return _get_combat_state().exhaustion_float(combatant, default_if_missing)


static func set_exhaustion_float(combatant: Dictionary, value: float) -> void:
	_get_combat_state().set_exhaustion_float(combatant, value)


static func stance_str(
	combatant: Dictionary, default_stance: String = CombatConstantsFormationMove.STANCE_BALANCED
) -> String:
	return _get_combat_state().stance_str(combatant, default_stance)


static func form_str(combatant: Dictionary) -> String:
	return _get_combat_state().form_str(combatant)


static func get_performance_modifier(combatant: Dictionary) -> float:
	return _get_combat_state().get_performance_modifier(combatant)


static func get_hit_chance_performance_modifier(combatant: Dictionary) -> float:
	return _get_combat_state().get_hit_chance_performance_modifier(combatant)


static func get_action_bar_performance_modifier(combatant: Dictionary) -> float:
	return _get_combat_state().get_action_bar_performance_modifier(combatant)


static func is_dead(combatant: Dictionary) -> bool:
	return _get_combat_state().is_dead(combatant)


static func is_on_battlefield(combatant: Dictionary) -> bool:
	return _get_combat_state().is_on_battlefield(combatant)


static func get_death_reason(combatant: Dictionary) -> String:
	return _get_combat_state().get_death_reason(combatant)


static func get_attack_damage_modifier(combatant: Dictionary) -> float:
	return _get_combat_state().get_attack_damage_modifier(combatant)


static func has_passive_parry_reaction_time(combatant: Dictionary) -> bool:
	return _get_combat_state().has_passive_parry_reaction_time(combatant)


static func get_passive_parry_reaction_time(combatant: Dictionary) -> float:
	return _get_combat_state().get_passive_parry_reaction_time(combatant)


static func apply_armor_sharp_resistance_to_blunt_opts(
	blunt_opts: Dictionary, defender: Dictionary, part: String
) -> void:
	_get_combat_state().apply_armor_sharp_resistance_to_blunt_opts(blunt_opts, defender, part)


static func finalize_dead_combatant_if_node_dead(manager: Node, c: Dictionary) -> bool:
	return _get_combat_state().finalize_dead_combatant_if_node_dead(manager, c)


static func get_attacking_arm(combatant: Dictionary) -> String:
	return _get_combat_state().get_attacking_arm(combatant)


static func retreat_formation_body_damage_warranted(c: Dictionary, manager: Node) -> bool:
	return _get_combat_state().retreat_formation_body_damage_warranted(c, manager)


static func flee_abandonment_warranted(c: Dictionary, manager: Node) -> bool:
	return _get_combat_state().flee_abandonment_warranted(c, manager)


static func get_leg_functionality(combatant: Dictionary) -> float:
	return _get_combat_state().get_leg_functionality(combatant)


static func get_targetable_parts(combatant: Dictionary) -> Array:
	return _get_combat_state().get_targetable_parts(combatant)


static func get_targetable_parts_from_node(node: Node) -> Array:
	return _get_combat_state().get_targetable_parts_from_node(node)


static func is_yielded(combatant: Dictionary) -> bool:
	return _get_combat_state().is_yielded(combatant)


static func react_attacking_arm_lost_if_needed(manager: Node, combatant: Dictionary) -> void:
	_get_combat_state().react_attacking_arm_lost_if_needed(manager, combatant)


static func is_cowering(combatant: Dictionary) -> bool:
	return _get_combat_state().is_cowering(combatant)


static func can_flee_or_fall_back(combatant: Dictionary) -> bool:
	return _get_combat_state().can_flee_or_fall_back(combatant)


static func _get_part_dodge_modifier(combatant: Dictionary, part: String) -> float:
	return _get_combat_state()._get_part_dodge_modifier(combatant, part)


static func get_dodge_chance(combatant: Dictionary, attacker_windup_override: float = -1.0) -> float:
	return _get_combat_state().get_dodge_chance_with_windup(combatant, attacker_windup_override)


## Parry capacity modifier: pain in arms + concussion balance impairment + limb crippling.
static func get_parry_capacity_modifier(combatant: Dictionary) -> float:
	return _get_combat_state().get_parry_capacity_modifier(combatant)


## Dodge speed modifier: leg pain + concussion balance impairment.
static func get_dodge_speed_modifier(combatant: Dictionary) -> float:
	return _get_combat_state().get_dodge_speed_modifier(combatant)


## Cumulative pain degradation across all body parts (0-1, higher = more degraded).
static func get_cumulative_pain_degradation(combatant: Dictionary) -> float:
	return _get_combat_state().get_cumulative_pain_degradation(combatant)


## Limb crippling modifier for a specific part (1.0 = functional, <1.0 = impaired).
static func get_limb_crippling_modifier(combatant: Dictionary, limb_part: String) -> float:
	return _get_combat_state().get_limb_crippling_modifier(combatant, limb_part)


## Cumulative penalty from all damaged limbs (0-1).
static func get_cumulative_limb_penalty(combatant: Dictionary) -> float:
	return _get_combat_state().get_cumulative_limb_penalty(combatant)


static func get_blood_volume_from_node(node: Node) -> float:
	return _get_combat_state().get_blood_volume_from_node(node)


static func get_total_bleeding_rate_from_node(node: Node) -> float:
	return _get_combat_state().get_total_bleeding_rate_from_node(node)


static func get_permanent_bleeding_rate_from_node(node: Node, fallback: float = 0.0) -> float:
	return _get_combat_state().get_permanent_bleeding_rate_from_node(node, fallback)


# ═══════════════════════════════════════════════════════════════════════
# CombatantWeaponAccess — weapon, armor, parry, striking mass
# ═══════════════════════════════════════════════════════════════════════

static func weapon_attack_types(weapon: Variant) -> Array:
	return _get_weapon().weapon_attack_types(weapon)


static func weapon_has_attack_types(weapon: Variant) -> bool:
	return _get_weapon().weapon_has_attack_types(weapon)


static func weapon_contact_type(weapon: Variant, move_id: String, default_contact: String = "cut") -> String:
	return _get_weapon().weapon_contact_type(weapon, move_id, default_contact)


static func weapon_mass_kg(weapon: Variant) -> float:
	return _get_weapon().weapon_mass_kg(weapon)


static func parry_wobble_context(defender_weapon: Variant, parry_readiness: float) -> Dictionary:
	return _get_weapon().parry_wobble_context(defender_weapon, parry_readiness)


static func parry_wobble_context_for_combatant(combatant: Dictionary, parry_readiness: float) -> Dictionary:
	return _get_weapon().parry_wobble_context_for_combatant(combatant, parry_readiness)


static func weapon_archetype_id(weapon: Variant, move_id: String, default_id: String = "slash") -> String:
	return _get_weapon().weapon_archetype_id(weapon, move_id, default_id)


static func weapon_archetype_for_move(
	weapon: Variant, move_id: String, default_archetype_id: String = WeaponConstants.ARCHETYPE_SLASH
) -> Dictionary:
	return _get_weapon().weapon_archetype_for_move(weapon, move_id, default_archetype_id)


static func weapon_has_parts(weapon: Variant) -> bool:
	return _get_weapon().weapon_has_parts(weapon)


static func weapon_parry_strong_fraction(weapon: Variant, default_frac: float = 0.25) -> float:
	return _get_weapon().weapon_parry_strong_fraction(weapon, default_frac)


static func weapon_parry_part_length_cm(weapon: Variant, default_len: float = 0.0) -> float:
	return _get_weapon().weapon_parry_part_length_cm(weapon, default_len)


static func weapon_striking_mass_kg(weapon: Variant, contact_type: String = "") -> float:
	return _get_weapon().weapon_striking_mass_kg(weapon, contact_type)


static func weapon_parry_part_mass_kg(weapon: Variant) -> float:
	return _get_weapon().weapon_parry_part_mass_kg(weapon)


static func weapon_parry_contact_type(weapon: Variant, default_pct: String = "blade") -> String:
	return _get_weapon().weapon_parry_contact_type(weapon, default_pct)


static func weapon_parry_ref_contact_type(weapon: Variant) -> String:
	return _get_weapon().weapon_parry_ref_contact_type(weapon)


static func weapon_impact_velocity_band_max(weapon: Variant, contact_type: String) -> float:
	return _get_weapon().weapon_impact_velocity_band_max(weapon, contact_type)


static func get_weapon(combatant: Dictionary) -> Variant:
	return _get_weapon().get_weapon(combatant)


static func weapon_type_id(combatant: Dictionary) -> String:
	return _get_weapon().weapon_type_id(combatant)


static func weapon_melee_reach(combatant: Dictionary, default_reach: float = 1.5) -> float:
	return _get_weapon().weapon_melee_reach(combatant, default_reach)


static func has_weapon(combatant: Dictionary) -> bool:
	return _get_weapon().has_weapon(combatant)


static func get_weapon_from_node(node: Node) -> Variant:
	return _get_weapon().get_weapon_from_node(node)


static func get_armor_slots_from_node(node: Node) -> Dictionary:
	return _get_weapon().get_armor_slots_from_node(node)


static func get_weapon_display_name_from_node(node: Node) -> String:
	return _get_weapon().get_weapon_display_name_from_node(node)


static func get_armor_summary_from_node(node: Node) -> Array:
	return _get_weapon().get_armor_summary_from_node(node)


static func get_total_armor_mass_kg_from_node(node: Node) -> float:
	return _get_weapon().get_total_armor_mass_kg_from_node(node)


# ═══════════════════════════════════════════════════════════════════════
# CombatantMedicalEntityAccess — wounds, bleeding, medical actions
# ═══════════════════════════════════════════════════════════════════════

static func get_wounded_parts(combatant: Dictionary, manager: Node = null) -> Array:
	return _get_medical().get_wounded_parts(combatant, manager)


static func scene_has_wounded_parts_listing(combatant: Dictionary) -> bool:
	return _get_medical().scene_has_wounded_parts_listing(combatant)


static func scene_supports_medical_pressure_listing(combatant: Dictionary) -> bool:
	return _get_medical().scene_supports_medical_pressure_listing(combatant)


static func scene_can_apply_direct_pressure_api(combatant: Dictionary) -> bool:
	return _get_medical().scene_can_apply_direct_pressure_api(combatant)


static func entity_can_apply_direct_pressure(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_can_apply_direct_pressure(manager, combatant, part)


static func entity_has_direct_pressure_on_part(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_has_direct_pressure_on_part(manager, combatant, part)


static func entity_has_wound_part(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_has_wound_part(manager, combatant, part)


static func entity_get_wounded_parts(manager: Node, combatant: Dictionary) -> Array:
	return _get_medical().entity_get_wounded_parts(manager, combatant)


static func entity_bleeding_rate_for_part(manager: Node, combatant: Dictionary, part: String) -> float:
	return _get_medical().entity_bleeding_rate_for_part(manager, combatant, part)


static func entity_can_apply_bandage(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_can_apply_bandage(manager, combatant, part)


static func entity_can_apply_stabilize(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_can_apply_stabilize(manager, combatant, part)


static func entity_can_apply_packing(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_can_apply_packing(manager, combatant, part)


static func entity_can_apply_tourniquet(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_can_apply_tourniquet(manager, combatant, part)


static func entity_is_tourniquet_indicated_for_part(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_is_tourniquet_indicated_for_part(manager, combatant, part)


static func entity_blood_loss_death_threshold(entity: Node) -> float:
	return _get_medical().entity_blood_loss_death_threshold(entity)


static func scene_can_apply_direct_pressure(combatant: Dictionary, part: String) -> bool:
	return _get_medical().scene_can_apply_direct_pressure(combatant, part)


static func entity_invoke_medical_method(
	entity: Node, method: String, part: String, effectiveness: float = 1.0
) -> Variant:
	return _get_medical().entity_invoke_medical_method(entity, method, part, effectiveness)


static func entity_apply_direct_pressure(manager: Node, combatant: Dictionary, part: String) -> bool:
	return _get_medical().entity_apply_direct_pressure(manager, combatant, part)


static func entity_apply_direct_pressure_from_ally(
	manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
	return _get_medical().entity_apply_direct_pressure_from_ally(manager, target, performer, part)


static func entity_stack_assist_pressure_eligible(
	manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
	return _get_medical().entity_stack_assist_pressure_eligible(manager, target, performer, part)


static func entity_stack_assist_pressure_during_ally_treatment(
	manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
	return _get_medical().entity_stack_assist_pressure_during_ally_treatment(manager, target, performer, part)


static func scene_apply_direct_pressure(combatant: Dictionary, part: String) -> bool:
	return _get_medical().scene_apply_direct_pressure(combatant, part)


static func link_performer_direct_pressure_on_ally(
	manager: Node, performer: Dictionary, tgt_entity: Node, part: String
) -> void:
	_get_medical().link_performer_direct_pressure_on_ally(manager, performer, tgt_entity, part)


static func is_applying_direct_pressure_scene(combatant: Dictionary) -> bool:
	return _get_medical().is_applying_direct_pressure_scene(combatant)


static func get_direct_pressure_part_scene(combatant: Dictionary) -> String:
	return _get_medical().get_direct_pressure_part_scene(combatant)


static func clear_direct_pressure_scene(combatant: Dictionary) -> void:
	_get_medical().clear_direct_pressure_scene(combatant)


static func prepare_for_medical_windup_scene(
	manager: Node, performer: Dictionary, target: Dictionary, part: String
) -> void:
	_get_medical().prepare_for_medical_windup_scene(manager, performer, target, part)


static func scene_entity(combatant: Dictionary) -> CoreEntity:
	return _get_medical().scene_entity(combatant)


## Derived combat skill for hit chance / bind contests. Untracked fighters (enemies, test entities)
## return MELEE_SKILL_BASELINE (100); proficiency-tracked party fighters span untrained → veteran.
static func melee_skill_value(combatant: Dictionary) -> float:
	var ent: CoreEntity = scene_entity(combatant)
	if ent == null:
		return float(CombatConstants.DEFAULT_STAT_VALUE)
	return EntityProficiency.melee_skill_for(ent, weapon_type_id(combatant), form_str(combatant))


static func get_health_entity_from_node(manager: Node, node: Node) -> Node:
	return _get_medical().get_health_entity_from_node(manager, node)


static func get_entity_from_manager(manager: Node, combatant: Dictionary) -> Node:
	return _get_medical().get_entity_from_manager(manager, combatant)


static func entity_has_untreated_wounds(entity: Node) -> bool:
	return _get_medical().entity_has_untreated_wounds(entity)


static func is_in_medical_danger(manager: Node, c: Dictionary) -> bool:
	return _get_medical().is_in_medical_danger(manager, c)


static func is_in_immediate_peril(manager: Node, c: Dictionary) -> bool:
	return _get_medical().is_in_immediate_peril(manager, c)


static func has_left_immediate_peril_permanently(manager: Node, c: Dictionary) -> bool:
	return _get_medical().has_left_immediate_peril_permanently(manager, c)


static func get_medical_windup_speed_modifier(manager: Node, performer: Dictionary, target: Dictionary) -> float:
	return _get_medical().get_medical_windup_speed_modifier(manager, performer, target)


static func get_effective_medical_windup_speed_modifier(
	_manager: Node, performer: Dictionary, target: Variant
) -> float:
	return _get_medical().get_effective_medical_windup_speed_modifier(_manager, performer, target)


static func get_medical_windup_assist_duration_divisor(manager: Node, target: Dictionary, part: String) -> float:
	return _get_medical().get_medical_windup_assist_duration_divisor(manager, target, part)


static func part_has_active_direct_pressure_on_entity(entity: Node, part: String) -> bool:
	return _get_medical().part_has_active_direct_pressure_on_entity(entity, part)


static func get_medical_effectiveness_from_node(node: Node) -> float:
	return _get_medical().get_medical_effectiveness_from_node(node)
