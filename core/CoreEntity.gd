extends Node2D

class_name CoreEntity

# BleedingConstants is class_name in core/_Bleeding.gd; preload for linter/standalone parse
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _Healing := preload("res://core/HealingConstants.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _EntityPainConsciousness := preload("res://core/EntityPainConsciousness.gd")
const _EntityHealing := preload("res://core/EntityHealing.gd")
const _BodyPartQuery := preload("res://core/BodyPartQuery.gd")
const _EntityDamage := preload("res://core/EntityDamage.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _EntityEquipment := preload("res://core/EntityEquipment.gd")

@export var species: Resource = null

# Sharp (cutting) and blunt health per body part (tissue). Bone is separate; severance when tissue 0 and bone 0.
var body_cutting: Dictionary = {}
var body_blunt: Dictionary = {}
var body_max: Dictionary = {}
var bone_health: Dictionary = {}
var bone_max: Dictionary = {}
var strength: int = 100
var agility: int = 100
var intelligence: int = 100
var endurance: int = 100
var perception: int = 100
# Attacking arm: which hand is dominant and offhand effectiveness (0.6–1.0).
var dominant_hand: String = "right_arm"
var offhand_functionality: float = 0.8
# One armor piece per body part (e.g. chest -> Cuirass with plate + gambeson layers).
var armor_slots: Dictionary = {}  # body_part (String) -> ArmorPiece
# Optional equipped weapon (Weapon instance from template). Null = unarmed.
var weapon = null

# Wound tracking and bleeding (injury-based). Body parts: head, chest, right_arm, left_arm, right_leg, left_leg.
# wounds[part] = Array of injury dicts. Each wound has individual healing: created_at_game_time, healing_duration_seconds.
# Pain contribution = damage × severity_mult × (1 - healing_progress); wounds are removed when progress >= _Healing.WOUND_RESOLVED_THRESHOLD.
var wounds: Dictionary = {}  # part (String) -> Array of Dictionary
var blood_volume: float = 100.0  # 0–100; death below _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
# Tourniquet: limb parts only. part -> { "applied_at": float, "effectiveness": float }. Effectiveness 0–1 scales bleeding reduction.
var tourniquet_applied: Dictionary = {}  # part (String) -> Dictionary
# Bandaged parts: part -> true when bandage has been applied. Mutually exclusive with tourniquet per part (can't bandage a tourniqueted limb, can't tourniquet a bandaged limb).
var bandaged_parts: Dictionary = {}  # part (String) -> bool
# Packed parts: head/chest only; linen packed into wound cavity. Mutually exclusive with bandage/tourniquet per part.
var packed_parts: Dictionary = {}  # part (String) -> bool
# Direct pressure: part (String) the entity is currently holding pressure on; empty if not. Lasts until next action or bleeding on that part stops.
# When ally holds pressure on us: direct_pressure_part + direct_pressure_held_by. When we hold on ourselves: self_direct_pressure_part.
var direct_pressure_part: String = ""
# Part we are holding pressure on ourselves (e.g. second wound while ally treats our first). Allows simultaneous ally + self pressure.
var self_direct_pressure_part: String = ""
# When holding pressure on an ally: {node: Node, part: String}. Cleared when performer releases or target's bleeding stops.
var direct_pressure_on_ally: Dictionary = {}
# When pressure is held on us by an ally: the performer's medical entity. Used to clear performer when our bleeding stops.
var direct_pressure_held_by: Node = null
# Optional second ally pressing the same part during stabilizing treatment wind-up (helper holds, medic treats).
var direct_pressure_assist_held_by: Node = null
# Optional bleed pacing overrides (default full ATLS drain; future explicit fluid resuscitation may raise recovery).
var _combat_blood_loss_mult: float = 1.0
var _combat_blood_recovery_per_s: float = 0.0


func get_combat_blood_loss_mult() -> float:
	return clampf(_combat_blood_loss_mult, 0.0, 1.0)


func get_combat_blood_recovery_per_s() -> float:
	return maxf(0.0, _combat_blood_recovery_per_s)


func set_combat_blood_loss_mult(mult: float) -> void:
	_combat_blood_loss_mult = clampf(mult, 0.0, 1.0)


func set_combat_blood_recovery_per_s(rate_per_s: float) -> void:
	_combat_blood_recovery_per_s = maxf(0.0, rate_per_s)

# Game time (seconds) for per-wound healing and pain decay. Advanced in process_healing(seconds).
var _game_time_seconds: float = 0.0

# Tissue health precision: round to 2 decimal places for finer damage representation.
func _round_tissue(v: float) -> float:
	return roundf(v * 100.0) / 100.0

# Pain and consciousness. Consciousness = head × blood only (pain does not affect it). Pain strongly affects performance.
var consciousness: float = 100.0       # true consciousness (incapacitation when < 10)
var effective_consciousness: float = 100.0  # for combat (after pain shock)
var _pain_shock_until_time: float = -1.0    # Time.get_ticks_msec()/1000.0 when shock ends; -1 = not in shock
var _last_hit_impact: float = 0.0            # Total damage of last hit (for pain-shock duration scaling); set on weapon hit, consumed when shock is entered
var _ambient_pain_shock_accum: float = 0.0  # Combat tick accumulator for sustained-pain shock rolls

# Dirty flag: only recalc consciousness when something changed (damage, blood loss, healing).
var _consciousness_dirty: bool = true

signal died
signal creature_incapacitated
signal health_changed

## Called by EntityDamage and EntityWounds when entity dies (vital part destroyed or blood loss). Centralizes emission.
func notify_died() -> void:
	emit_signal("died")

## Called by EntityPainConsciousness when consciousness drops below incapacitation threshold.
## CombatManager connects this so UI refreshes; Phase 5 formation logic can react (fall back, plug gap).
func notify_creature_incapacitated() -> void:
	creature_incapacitated.emit()

## Called by EntityPainConsciousness when consciousness/pain changes. UI refreshes via CombatManager.
func notify_health_changed() -> void:
	health_changed.emit()

func _get_body_part_list() -> Array:
	return _BodyPartQuery.get_body_part_list(self)

func _get_vital_parts() -> Array:
	return _BodyPartQuery.get_vital_parts(self)

func get_targetable_parts() -> Array:
	return _BodyPartQuery.get_targetable_parts(self)

func _is_part_severed(part: String) -> bool:
	return _BodyPartQuery.is_part_severed(self, part)

func _is_part_crushed(part: String) -> bool:
	return _BodyPartQuery.is_part_crushed(self, part)

func _is_part_destroyed(part: String) -> bool:
	return _BodyPartQuery.is_part_destroyed(self, part)

func is_bone_fractured(part: String) -> bool:
	return bone_health.get(part, 0.0) <= 0.0

func is_bone_broken(part: String) -> bool:
	return bone_health.get(part, 0.0) <= 0.0

func get_bone_functionality_factor(part: String) -> float:
	return _BodyPartQuery.get_bone_functionality_factor(self, part)

func is_part_severed(part: String) -> bool:
	return _BodyPartQuery.is_part_severed(self, part)

func _get_offhand() -> String:
	return "left_arm" if dominant_hand == "right_arm" else "right_arm"

func is_arm_destroyed(part: String) -> bool:
	return _BodyPartQuery.is_arm_destroyed(self, part)

func get_arm_functionality(part: String) -> float:
	return _BodyPartQuery.get_arm_functionality(self, part)

func get_leg_functionality() -> float:
	return _BodyPartQuery.get_leg_functionality(self)

func get_part_dodge_modifier(part: String) -> float:
	return _BodyPartQuery.get_part_dodge_modifier(self, part)

# Effective speed for gauge fill / mobility: base agility × leg functionality (research: leg fracture → major mobility loss).
func get_effective_speed() -> int:
	var leg: float = get_leg_functionality()
	return maxi(1, int(roundf(float(agility) * leg)))

# Which arm is used to hold and attack with the weapon. Effectively swaps to the offhand when the
# dominant arm is injured or destroyed and the offhand would be more effective (by effective damage).
func get_attacking_arm() -> String:
	return _EntityEquipment.get_attacking_arm(self)

func get_attack_damage_modifier() -> float:
	return _EntityEquipment.get_attack_damage_modifier(self)

func get_armor_for_part(part: String) -> Variant:
	return _EntityEquipment.get_armor_for_part(self, part)

# Sharp resistance (mm RHA) of armor on this part. For energy-based thrust contact estimation.
func get_armor_sharp_resistance_for_part(part: String) -> float:
	return _EntityEquipment.get_armor_sharp_resistance_for_part(self, part)

func get_armor_slots() -> Dictionary:
	return _EntityEquipment.get_armor_slots(self)

func equip_armor(part: String, piece: Variant) -> void:
	_EntityEquipment.equip_armor(self, part, piece)

func get_weapon():
	return _EntityEquipment.get_weapon(self)

func equip_weapon(w) -> void:
	_EntityEquipment.equip_weapon(self, w)

func _get_blood_loss_death_threshold() -> float:
	if species != null and species.get("blood_loss_death_threshold") != null and species.blood_loss_death_threshold >= 0.0:
		return species.blood_loss_death_threshold
	return _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD

func _get_blood_loss_critical_threshold() -> float:
	if species != null and species.get("blood_loss_critical_threshold") != null and species.blood_loss_critical_threshold >= 0.0:
		return species.blood_loss_critical_threshold
	return _Bleeding.BLOOD_LOSS_CRITICAL_THRESHOLD

func is_blood_critical() -> bool:
	"""True when remaining blood is at or below this entity's critical threshold (for UI/effects)."""
	return blood_volume <= _get_blood_loss_critical_threshold()

# --- Pain and consciousness (Combat Extended–style) ---
# Per-wound healing progress 0..1 (exponential: after healing_duration seconds ~95% healed). Backwards compat: missing fields => progress 0.
func _get_wound_healing_progress(injury: Dictionary) -> float:
	return _EntityWounds.get_wound_healing_progress(self, injury)

func _get_pain_contribution_for_wound(part: String, damage: float, severity: String, injury_type: String, sub_region: String, is_stump: bool = false) -> float:
	return _EntityPainConsciousness.get_pain_contribution_for_wound(self, part, damage, severity, injury_type, sub_region, is_stump)

func get_total_pain() -> float:
	return _EntityPainConsciousness.get_total_pain(self)

func get_effective_pain_for_thresholds() -> float:
	return _EntityPainConsciousness.get_effective_pain_for_thresholds(self)

func get_effective_pain_for_region(region: String) -> float:
	return _EntityPainConsciousness.get_effective_pain_for_region(self, region)

func _mark_consciousness_dirty() -> void:
	_EntityPainConsciousness.mark_consciousness_dirty(self)

func _try_enter_pain_shock_from_hit(pain_from_this_hit_raw: float) -> void:
	_EntityPainConsciousness.try_enter_pain_shock_from_hit(self, pain_from_this_hit_raw)


func _try_ambient_pain_shock_tick(delta: float) -> void:
	if _EntityPainConsciousness.try_ambient_pain_shock_tick(self, delta):
		_update_consciousness()


func _update_consciousness() -> void:
	_EntityPainConsciousness.update_consciousness(self)

func is_cowering() -> bool:
	return get_attacking_arm().is_empty()

## True when blood/head trauma has dropped true consciousness below the incapacitation floor (cannot act or move).
func is_unconscious() -> bool:
	ensure_consciousness_current()
	return consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD

## Formation retreat (flee / fall_back): not unconscious and legs functional enough to walk. Cowering (no arms) may still retreat when mobile.
func can_flee_or_fall_back() -> bool:
	if is_unconscious():
		return false
	return get_leg_functionality() >= _PainConscious.MOBILITY_FLEE_THRESHOLD

func is_incapacitated() -> bool:
	if is_unconscious():
		return true
	return is_cowering()

func get_effective_consciousness() -> float:
	return _EntityPainConsciousness.get_effective_consciousness(self)

func get_performance_modifier() -> float:
	return _EntityPainConsciousness.get_performance_modifier(self)

func get_action_bar_performance_modifier() -> float:
	return _EntityPainConsciousness.get_action_bar_performance_modifier(self)

func get_hit_chance_performance_modifier() -> float:
	return _EntityPainConsciousness.get_hit_chance_performance_modifier(self)

func get_passive_parry_reaction_time() -> float:
	return _EntityPainConsciousness.get_passive_parry_reaction_time(self)

func get_dodge_chance() -> float:
	return _EntityPainConsciousness.get_dodge_chance(self)

func is_dead() -> bool:
	if blood_volume <= _get_blood_loss_death_threshold():
		return true
	for part in _get_vital_parts():
		if _is_part_destroyed(part):
			return true
		if body_cutting.get(part, 0.0) <= 0.0 or body_blunt.get(part, 0.0) <= 0.0:
			return true
	return false

# Returns a short string describing why this entity is dead (for combat/debug logging). Call only when is_dead() is true.
func get_death_reason() -> String:
	var death_thresh: float = _get_blood_loss_death_threshold()
	if blood_volume <= death_thresh:
		return "blood_loss (volume=%.1f <= threshold %.1f)" % [blood_volume, death_thresh]
	for part in _get_vital_parts():
		if _is_part_destroyed(part):
			return "vital_part_destroyed (%s severed/crushed)" % part
		var cut: float = body_cutting.get(part, 0.0)
		var blunt: float = body_blunt.get(part, 0.0)
		if cut <= 0.0 or blunt <= 0.0:
			return "vital_part_zero (%s cut=%.2f blunt=%.2f)" % [part, cut, blunt]
	return "unknown"

func _get_severance_ease_factor(part: String) -> float:
	return _EntityDamage.get_severance_ease_factor(self, part)

# Split damage: apply cut (SHARP) and blunt (BLUNT) streams; armor, bone/tissue split, wounds, pain shock in EntityDamage.
func take_damage_split(cut_pre: float, blunt_pre: float, part: String, penetration_sharp: float = -1.0, penetration_blunt_momentum_per_area: float = -1.0, blunt_contact_cm: float = -1.0, extras: Dictionary = {}) -> Dictionary:
	return _EntityDamage.apply_damage_split(self, cut_pre, blunt_pre, part, penetration_sharp, penetration_blunt_momentum_per_area, blunt_contact_cm, extras)


# --- Wounds and bleeding: delegated to EntityWounds (core/EntityWounds.gd) ---

func get_total_bleeding_rate() -> float:
	return _EntityWounds.get_total_bleeding_rate(self)

func get_permanent_bleeding_rate() -> float:
	return _EntityWounds.get_permanent_bleeding_rate(self)

func get_bleeding_rate_for_part(part: String) -> float:
	return _EntityWounds.get_bleeding_rate_for_part(self, part)

func get_wounded_parts() -> Array:
	return _EntityWounds.get_wounded_parts(self)

func get_wounds() -> Dictionary:
	return _EntityWounds.get_wounds(self)

func get_wound_healing_progress(injury: Dictionary) -> float:
	return _EntityWounds.get_wound_healing_progress(self, injury)

func get_game_time_seconds() -> float:
	return _game_time_seconds

func process_bleeding(delta: float) -> void:
	_EntityWounds.process_bleeding(self, delta)

func process_blood_loss(delta: float) -> void:
	_EntityWounds.process_blood_loss(self, delta)

# --- Medical: delegated to EntityMedical (core/EntityMedical.gd) ---

func get_bandage_application_time_seconds() -> float:
	return _EntityMedical.get_bandage_application_time_seconds()

func get_bandage_application_time_seconds_for_part(part: String) -> float:
	return _EntityMedical.get_bandage_application_time_seconds_for_part(self, part)

"""Medical effectiveness from intelligence (100 INT = 1.0; 50 = 0.75, 150 = 1.25). Used for bandage, direct pressure."""
func get_medical_effectiveness() -> float:
	return clampf(0.5 + float(intelligence) / 200.0, 0.5, 1.5)

func get_tourniquet_application_time_seconds() -> float:
	return _EntityMedical.get_tourniquet_application_time_seconds()

func can_apply_bandage(part: String) -> bool:
	return _EntityMedical.can_apply_bandage(self, part)

func apply_bandage(part: String, effectiveness: float = 1.0) -> bool:
	return _EntityMedical.apply_bandage(self, part, effectiveness)

func can_apply_packing(part: String) -> bool:
	return _EntityMedical.can_apply_packing(self, part)

func apply_packing(part: String, effectiveness: float = 1.0) -> bool:
	return _EntityMedical.apply_packing(self, part, effectiveness)

func get_packing_application_time_seconds_for_part(part: String) -> float:
	return _EntityMedical.get_packing_application_time_seconds_for_part(self, part)

func get_medical_entity() -> Node:
	return self

"""Ensure consciousness/performance are current before UI reads. Only recalculates when dirty (damage, blood loss, healing)."""
func ensure_consciousness_current() -> void:
	if _consciousness_dirty:
		_update_consciousness()

func can_apply_direct_pressure(target_part: String) -> bool:
	return _EntityMedical.can_apply_direct_pressure(self, target_part)

func apply_direct_pressure_from_ally(part: String, performer_entity: Node = null) -> bool:
	return _EntityMedical.apply_direct_pressure_from_ally(self, part, performer_entity)

func stack_assist_pressure_eligible(part: String, assist_entity: Node = null) -> bool:
	return _EntityMedical.stack_assist_pressure_eligible(self, part, assist_entity)


func stack_assist_pressure_during_ally_treatment(part: String, assist_entity: Node = null) -> bool:
	return _EntityMedical.stack_assist_pressure_during_ally_treatment(self, part, assist_entity)

func apply_direct_pressure(part: String, effectiveness: float = -1.0) -> bool:
	return _EntityMedical.apply_direct_pressure(self, part, effectiveness)

func is_applying_direct_pressure() -> bool:
	return _EntityMedical.is_applying_direct_pressure(self)

func has_direct_pressure_on_part(part: String) -> bool:
	return _EntityMedical.has_direct_pressure_on_part(self, part)

func get_direct_pressure_part() -> String:
	return _EntityMedical.get_direct_pressure_part(self)

func clear_direct_pressure() -> void:
	_EntityMedical.clear_direct_pressure(self)

func prepare_for_medical_windup(target: Node, part: String) -> void:
	_EntityMedical.prepare_for_medical_windup(self, target, part)

func is_tourniquet_indicated_for_part(part: String) -> bool:
	return _EntityMedical.is_tourniquet_indicated_for_part(self, part)

func can_apply_tourniquet(part: String) -> bool:
	return _EntityMedical.can_apply_tourniquet(self, part)

func is_tourniquet_applied(part: String) -> bool:
	return _EntityMedical.is_tourniquet_applied(self, part)

func apply_tourniquet(part: String, effectiveness: float = 1.0) -> bool:
	return _EntityMedical.apply_tourniquet(self, part, effectiveness)

func remove_tourniquet(part: String) -> void:
	_EntityMedical.remove_tourniquet(self, part)

# Healing: exponential deficit decay (tissue, bone, blood). Per-wound: pain decays by healing progress; resolved wounds removed.
# Call on time advance. Game time advances here for per-wound healing and pain.
func process_healing(seconds: float) -> void:
	_EntityHealing.process_healing(self, seconds)

func _ready():
	if species != null:
		_apply_species()

func apply_species():
	_apply_species()

func _apply_species():
	body_cutting.clear()
	body_blunt.clear()
	body_max.clear()
	bone_health.clear()
	bone_max.clear()
	wounds.clear()
	tourniquet_applied.clear()
	bandaged_parts.clear()
	packed_parts.clear()
	direct_pressure_part = ""
	self_direct_pressure_part = ""
	direct_pressure_assist_held_by = null
	_game_time_seconds = 0.0
	blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	consciousness = 100.0
	effective_consciousness = 100.0
	_consciousness_dirty = false
	_pain_shock_until_time = -1.0
	_last_hit_impact = 0.0
	_ambient_pain_shock_accum = 0.0
	if species != null:
		for p in _get_body_part_list():
			var m = species.get_body_part_max(p) if species.has_method("get_body_part_max") else 10
			var b = species.get_bone_max(p) if species.has_method("get_bone_max") else maxi(1, m / 2)
			body_max[p] = m
			body_cutting[p] = _round_tissue(float(m))
			body_blunt[p] = _round_tissue(float(m))
			bone_max[p] = b
			bone_health[p] = _round_tissue(float(b))
		strength = species.get("strength") if "strength" in species else 100
		agility = species.get("agility") if "agility" in species else (species.get("speed") if "speed" in species else 100)
		intelligence = species.get("intelligence") if "intelligence" in species else 100
		endurance = species.get("endurance") if "endurance" in species else 100
		perception = species.get("perception") if "perception" in species else 100
		dominant_hand = ["right_arm", "left_arm"][randi() % 2]
		offhand_functionality = randf_range(0.6, 1.0)
		if typeof(species.name) == TYPE_STRING and species.name != "":
			self.name = species.name
	else:
		# Fallback when no species: use generic values consistent with aggressive realism scale
		for p in _get_body_part_list():
			body_max[p] = 12
			body_cutting[p] = _round_tissue(12.0)
			body_blunt[p] = _round_tissue(12.0)
			bone_max[p] = 8
			bone_health[p] = _round_tissue(8.0)
		strength = 100
		agility = 100
		intelligence = 100
		endurance = 100
		perception = 100
		dominant_hand = ["right_arm", "left_arm"][randi() % 2]
		offhand_functionality = randf_range(0.6, 1.0)
