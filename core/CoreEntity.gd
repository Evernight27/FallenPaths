class_name CoreEntity
extends Node2D
## Stats boosted by training drill (merged into proficiency bonus after each contract). Per-stat.
"""Medical effectiveness from intelligence (100 INT = 1.0; 50 = 0.75, 150 = 1.25). Used for bandage, direct pressure."""
"""Max blood volume scaling from END (100 |' 1.0x; 150 |' 1.25x). Applied in BloodVolumeMl.init_entity_pool."""
"""Camp rest healing speed from END (100 |' 1.0x; 150 |' ~1.20x faster). Applied in EntityHealing tau calculations."""
"""Contract pay scaling from INT (100 |' 1.0x; 150 |' 1.075x max). Applied in CompanyState post-victory gold."""
"""Ensure consciousness/performance are current before UI reads. Only recalculates when dirty."""

signal died
signal creature_incapacitated
signal health_changed
@export var species: Resource = null
## Campaign / harness: player party lead (stamped on **`CombatManager.register`** for player side only).
var training_pending: Dictionary = {
    "strength": 0.0,
    "agility": 0.0,
    "intelligence": 0.0,
    "endurance": 0.0,
    "perception": 0.0,
}

## Day index of last combat participation (for calendar-day decay calculation).
var last_fought_day: int = 0

## Whether this merc participated in the most recent combat (tracks who fought vs who stayed at camp).
var last_fought_in_combat: bool = false
var is_party_leader: bool = false
## IV-11: enemy commander (stamped on **`CombatManager.register`** for enemy side only).
var is_enemy_leader: bool = false

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
# Attacking arm: which hand is dominant and offhand effectiveness (0.6—1.0).
var dominant_hand: String = BodyPartConstants.PART_RIGHT_ARM
var offhand_functionality: float = 0.8
# One armor piece per body part (e.g. chest -> Cuirass with plate + gambeson layers).
var armor_slots: Dictionary = {}  # body_part (String) -> ArmorPiece
# Optional equipped weapon (Weapon instance from template). Null = unarmed.
var weapon: Variant = null

# Wound tracking and bleeding (injury-based). Body parts: head, chest, right_arm, left_arm, right_leg, left_leg.
# wounds[part] = Array of injury dicts. Each wound has individual healing: created_at_game_time,
# healing_duration_seconds.
# Pain contribution = damage f -  severity_mult f -  (1 - healing_progress); wounds are removed when progress >=
# HealingConstants.WOUND_RESOLVED_THRESHOLD.
var wounds: Dictionary = {}  # part (String) -> Array of Dictionary
## M3: per-part soft-tissue layer integrity (`intact` | `damaged` | `ruptured`); reset on `apply_species`.
var tissue_layer_state: Dictionary = {}
## M6: internal tissue J (authoritative when `FEATURE_TISSUE_ENERGY_POOL`); display pools derived.
var tissue_energy_capacity_j: Dictionary = {}
var tissue_energy_remaining_j: Dictionary = {}
var blood_volume: float = 100.0  # 0—100; death below BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
## S6 literal pool when `FEATURE_LITERAL_BLOOD_ML` (-1 = percent-only mode).
var blood_volume_ml: float = -1.0
var blood_volume_ml_max: float = -1.0
# Tourniquet: limb parts only. part -> { "applied_at": float, "effectiveness": float }. Effectiveness 0—1 scales
# bleeding reduction.
var tourniquet_applied: Dictionary = {}  # part (String) -> Dictionary
## Tracks failed tourniquet attempts per part for escalating retry chance. part -> int (failure count).
var tourniquet_failures: Dictionary = {}  # part (String) -> int
# Bandaged parts: part -> true when bandage has been applied. Mutually exclusive with tourniquet per part (can't bandage
# a tourniqueted limb, can't tourniquet a bandaged limb).
var bandaged_parts: Dictionary = {}  # part (String) -> bool
# Packed parts: head/chest only; linen packed into wound cavity. Mutually exclusive with bandage/tourniquet per part.
var packed_parts: Dictionary = {}  # part (String) -> bool
## Party linen for cavity packing (Tier 6 / III-5). Consumed per **`apply_packing`** attempt.
var linen_strips_remaining: int = 0
# Direct pressure: part (String) the entity is currently holding pressure on; empty if not. Lasts until next action or
# bleeding on that part stops.
# When ally holds pressure on us: direct_pressure_part + direct_pressure_held_by. When we hold on ourselves:
# self_direct_pressure_part.
var direct_pressure_part: String = ""
# Part we are holding pressure on ourselves (e.g. second wound while ally treats our first). Allows simultaneous ally +
# self pressure.
var self_direct_pressure_part: String = ""
# When holding pressure on an ally: {node: Node, part: String}. Cleared when performer releases or target's bleeding
# stops.
var direct_pressure_on_ally: Dictionary = {}
# When pressure is held on us by an ally: the performer's medical entity. Used to clear performer when our bleeding
# stops.
var direct_pressure_held_by: Node = null
# Optional second ally pressing the same part during stabilizing treatment wind-up (helper holds, medic treats).
var direct_pressure_assist_held_by: Node = null
var campaign_afflictions: Array[Dictionary] = []
## Phase 2: persisted per-limb muscle fatigue pools (synced from combatant dict after fights).
var muscle_fatigue: Dictionary = {}
var consciousness: float = 100.0  # true consciousness (incapacitation when < 10)
var effective_consciousness: float = 100.0  # for combat (after pain shock)
# Optional bleed pacing overrides (default full ATLS drain; future explicit fluid resuscitation may raise recovery).
var _combat_blood_loss_mult: float = 1.0
var _combat_blood_recovery_per_s: float = 0.0
## Camp-2.4 permanent injuries; each entry `{ id, label, stamina_mult, pain_mult }`.
var _campaign_supply_factor: float = 1.0

## Per-stat proficiency bonus above species base (int). Grows through combat, decays through inactivity.
## Stored as SEPARATE dict from base stats so _apply_species() cannot wipe it.
var _proficiency_bonus: Dictionary = {
    "strength": 0.0,
    "agility": 0.0,
    "intelligence": 0.0,
    "endurance": 0.0,
    "perception": 0.0,
}
## Per-weapon / per-form fight familiarity (XCamp-4 targeting extension). Not decayed yet.
var _weapon_proficiency: Dictionary = {}
var _form_proficiency: Dictionary = {}
var _game_time_seconds: float = 0.0
var _pain_shock_until_time: float = -1.0  # Time.get_ticks_msec()/1000.0 when shock ends; -1 = not in shock
# Concussion timestamp (Issue 1): simulation time until which entity is concussed; 0 = not concussed
var _concussion_until_time: float = 0.0
# Total damage of last hit (for pain-shock duration scaling); set on weapon hit, consumed when shock is entered
var _last_hit_impact: float = 0.0
var _ambient_pain_shock_accum: float = 0.0  # Combat tick accumulator for sustained-pain shock rolls
# Timestamp of last ambient pain shock trigger (for cooldown enforcement)
var _last_ambient_pain_shock_time: float = -1.0
var _consciousness_dirty: bool = true

var _death_notified: bool = false


func _get_training_pending() -> Dictionary:
    return training_pending


func _set_training_pending_value(stat: String, value: float) -> void:
    training_pending[stat] = value


# BleedingConstants is class_name in core/BleedingConstants.gd; preload for linter/standalone parse


func _get_weapon_proficiency() -> Dictionary:
    return _weapon_proficiency


func _get_form_proficiency() -> Dictionary:
    return _form_proficiency


## Camp rest clears local limb exertion pools (FEATURE_MUSCLE_GROUP_FATIGUE campaign bridge).
func _restore_muscle_fatigue_at_camp() -> void:
    muscle_fatigue = {}


func _get_combat_blood_loss_mult() -> float:
    return clampf(_combat_blood_loss_mult, 0.0, 1.0)


func _get_combat_blood_recovery_per_s() -> float:
    return maxf(0.0, _combat_blood_recovery_per_s)


func _set_combat_blood_loss_mult(mult: float) -> void:
    _combat_blood_loss_mult = clampf(mult, 0.0, 1.0)


func _set_combat_blood_recovery_per_s(rate_per_s: float) -> void:
    _combat_blood_recovery_per_s = maxf(0.0, rate_per_s)


# Game time (seconds) for per-wound healing and pain decay. Advanced in _process_healing(seconds).


# Tissue health precision: round to 2 decimal places for finer damage representation.
func _round_tissue(v: float) -> float:
    return roundf(v * 100.0) / 100.0


# Pain and consciousness. Consciousness = head f -  blood only (pain does not affect it). Pain strongly affects
# performance.


func _get_last_ambient_pain_shock_time() -> float:
    return _last_ambient_pain_shock_time


func _set_last_ambient_pain_shock_time(value: float) -> void:
    _last_ambient_pain_shock_time = value


# Dirty flag: only recalc consciousness when something changed (damage, blood loss, healing).


## Called by EntityDamage and EntityWounds when entity dies (vital part destroyed or blood loss). Centralizes emission.
func _notify_died() -> void:
    if _death_notified:
        return
    _death_notified = true
    died.emit()


## Called by EntityPainConsciousness when consciousness drops below incapacitation threshold.
## CombatManager connects this so UI refreshes; Phase 5 formation logic can react (fall back, plug gap).
func _notify_creature_incapacitated() -> void:
    creature_incapacitated.emit()


## Called by EntityPainConsciousness when consciousness/pain changes. UI refreshes via CombatManager.
func _notify_health_changed() -> void:
    health_changed.emit()


func _get_body_part_list() -> Array:
    return BodyPartQuery.get_body_part_list(self)


func _get_vital_parts() -> Array:
    return BodyPartQuery.get_vital_parts(self)


func _get_targetable_parts() -> Array:
    return BodyPartQuery.get_targetable_parts(self)


func _is_part_severed(part: String) -> bool:
    return BodyPartQuery.is_part_severed(self, part)


func _is_part_crushed(part: String) -> bool:
    return BodyPartQuery.is_part_crushed(self, part)


func _is_part_destroyed(part: String) -> bool:
    return BodyPartQuery.is_part_destroyed(self, part)


func _is_bone_fractured(part: String) -> bool:
    return bone_health.get(part, 0.0) <= 0.0


func _is_bone_broken(part: String) -> bool:
    return bone_health.get(part, 0.0) <= 0.0


func _get_bone_functionality_factor(part: String) -> float:
    return BodyPartQuery.get_bone_functionality_factor(self, part)


func _get_offhand() -> String:
    return (
        BodyPartConstants.PART_LEFT_ARM
        if dominant_hand == BodyPartConstants.PART_RIGHT_ARM
        else BodyPartConstants.PART_RIGHT_ARM
    )


func _is_arm_destroyed(part: String) -> bool:
    return BodyPartQuery.is_arm_destroyed(self, part)


func _get_arm_functionality(part: String) -> float:
    return BodyPartQuery.get_arm_functionality(self, part)


func _get_leg_functionality() -> float:
    return BodyPartQuery.get_leg_functionality(self)


func _get_part_dodge_modifier(part: String) -> float:
    return BodyPartQuery.get_part_dodge_modifier(self, part)


# Effective speed for gauge fill / mobility: base agility f -  leg functionality (research: leg fracture |' major
# mobility loss).
func _get_effective_speed() -> int:
    var leg: float = _get_leg_functionality()
    return maxi(1, int(roundf(float(agility) * leg)))


# Which arm is used to hold and attack with the weapon. Effectively swaps to the offhand when the
# dominant arm is injured or destroyed and the offhand would be more effective (by effective damage).
func get_attacking_arm() -> String:
    return EntityEquipment.get_attacking_arm(self)


func _get_attack_damage_modifier() -> float:
    return EntityEquipment.get_attack_damage_modifier(self)


func _get_armor_for_part(part: String) -> Variant:
    return EntityEquipment._get_armor_for_part(self, part)


# Sharp resistance (mm RHA) of armor on this part. For energy-based thrust contact estimation.
func _get_armor_sharp_resistance_for_part(part: String) -> float:
    return EntityEquipment._get_armor_sharp_resistance_for_part(self, part)


func _get_armor_slots() -> Dictionary:
    return EntityEquipment.get_armor_slots(self)


func equip_armor(part: String, piece: Variant) -> void:
    EntityEquipment.equip_armor(self, part, piece)


func get_weapon():
    return EntityEquipment.get_weapon(self)


func equip_weapon(w) -> void:
    EntityEquipment.equip_weapon(self, w)


func _get_blood_loss_death_threshold() -> float:
    if (
        species != null
        and species.get("blood_loss_death_threshold") != null
        and species.blood_loss_death_threshold >= 0.0
    ):
        return species.blood_loss_death_threshold
    return BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD


func _get_blood_loss_critical_threshold() -> float:
    if (
        species != null
        and species.get("blood_loss_critical_threshold") != null
        and species.blood_loss_critical_threshold >= 0.0
    ):
        return species.blood_loss_critical_threshold
    return BleedingConstants.BLOOD_LOSS_CRITICAL_THRESHOLD


func _is_blood_critical() -> bool:
    """True when remaining blood is at or below this entity's critical threshold (for UI/effects)."""
    return blood_volume <= _get_blood_loss_critical_threshold()


# --- Pain and consciousness (Combat Extended—style) ---
# Per-wound healing progress 0..1 (exponential: after healing_duration seconds ~95% healed). Backwards compat: missing
# fields => progress 0.
func _get_wound_healing_progress(injury: Dictionary) -> float:
    return EntityWounds._get_wound_healing_progress(self, injury)


func _get_pain_contribution_for_wound(
    part: String, damage: float, severity: String, injury_type: String, sub_region: String, is_stump: bool = false
) -> float:
    return EntityPainConsciousness.get_pain_contribution_for_wound(
        self, part, damage, severity, injury_type, sub_region, is_stump
    )


func _get_total_pain() -> float:
    return EntityPainConsciousness.get_total_pain(self)


func _get_effective_pain_for_thresholds() -> float:
    return EntityPainConsciousness.get_effective_pain_for_thresholds(self)


func _get_effective_pain_for_region(region: String) -> float:
    return EntityPainConsciousness._get_effective_pain_for_region(self, region)


func _mark_consciousness_dirty() -> void:
    EntityPainConsciousness.mark_consciousness_dirty(self)


func _try_enter_pain_shock_from_hit(pain_from_this_hit_raw: float) -> void:
    EntityPainConsciousness.try_enter_pain_shock_from_hit(self, pain_from_this_hit_raw)


func _try_ambient_pain_shock_tick(delta: float) -> void:
    if EntityPainConsciousness.try_ambient_pain_shock_tick(self, delta):
        _update_consciousness()


func _update_consciousness() -> void:
    EntityPainConsciousness.update_consciousness(self)


func is_cowering() -> bool:
    return get_attacking_arm().is_empty()


## True when blood/head trauma has dropped true consciousness below the incapacitation floor (cannot act or move).
func is_unconscious() -> bool:
    ensure_consciousness_current()
    return consciousness < PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD


## Formation retreat (flee / fall_back): not unconscious and legs functional enough to walk. Cowering (no arms) may
## still retreat when mobile.
func can_flee_or_fall_back() -> bool:
    if is_unconscious():
        return false
    return _get_leg_functionality() >= PainConsciousnessConstants.MOBILITY_FLEE_THRESHOLD


func is_incapacitated() -> bool:
    if is_unconscious():
        return true
    return is_cowering()


func is_concussed() -> bool:
    return EntityPainConsciousness.is_concussed(self)


func _get_effective_consciousness() -> float:
    return EntityPainConsciousness.get_effective_consciousness(self)


func get_performance_modifier() -> float:
    return EntityPainConsciousness.get_performance_modifier(self)


func _get_action_bar_performance_modifier() -> float:
    return EntityPainConsciousness.get_action_bar_performance_modifier(self)


func _get_hit_chance_performance_modifier() -> float:
    return EntityPainConsciousness.get_hit_chance_performance_modifier(self)


func _get_passive_parry_reaction_time() -> float:
    return EntityPainConsciousness.get_passive_parry_reaction_time(self)


func _get_dodge_chance() -> float:
    return EntityPainConsciousness.get_dodge_chance(self)


func is_dead() -> bool:
    if blood_volume <= _get_blood_loss_death_threshold():
        return true
    for part in _get_vital_parts():
        if _is_part_destroyed(part):
            return true
        if body_cutting.get(part, 0.0) <= 0.0 or body_blunt.get(part, 0.0) <= 0.0:
            return true
    return false


# Returns a short string describing why this entity is dead (for combat/debug logging). Call only when is_dead() is
# true.
func _get_death_reason() -> String:
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
    return EntityDamage.get_severance_ease_factor(self, part)


# Split damage: apply cut (SHARP) and blunt (BLUNT) streams; armor, bone/tissue split, wounds, pain shock in
# EntityDamage.
func take_damage_split(
    cut_pre: float,
    blunt_pre: float,
    part: String,
    penetration_sharp: float = -1.0,
    penetration_blunt_momentum_per_area: float = -1.0,
    blunt_contact_cm: float = -1.0,
    extras: Dictionary = {}
) -> Dictionary:
    return EntityDamage.apply_damage_split(
        self, cut_pre, blunt_pre, part, penetration_sharp, penetration_blunt_momentum_per_area, blunt_contact_cm, extras
    )


# --- Wounds and bleeding: delegated to EntityWounds (core/EntityWounds.gd) ---


func _get_total_bleeding_rate() -> float:
    return EntityWounds.get_total_bleeding_rate(self)


func _get_permanent_bleeding_rate() -> float:
    return EntityWounds.get_permanent_bleeding_rate(self)


func get_bleeding_rate_for_part(part: String) -> float:
    return EntityWounds.get_bleeding_rate_for_part(self, part)


func get_wounded_parts() -> Array:
    return EntityWounds.get_wounded_parts(self)


func _get_wounds_snapshot() -> Dictionary:
    return EntityWounds.get_wounds(self)


func _get_game_time_seconds() -> float:
    return _game_time_seconds


func process_bleeding(delta: float) -> void:
    EntityWounds.process_bleeding(self, delta)


func process_blood_loss(delta: float) -> void:
    EntityWounds.process_blood_loss(self, delta)


# --- Medical: delegated to EntityMedical (core/EntityMedical.gd) ---


func _get_bandage_application_time_seconds() -> float:
    return EntityMedical._get_bandage_application_time_seconds()


func _get_bandage_application_time_seconds_for_part(part: String) -> float:
    return EntityMedical._get_bandage_application_time_seconds_for_part(self, part)


func _get_medical_effectiveness() -> float:
    var effective_int: float = float(intelligence)
    if CompanyState.read_stub_proficiency_enabled() and "_proficiency_bonus" in self:
        effective_int += float(_proficiency_bonus.get("intelligence", 0) or 0)
    var base: float = clampf(effective_int / 100.0, 0.5, 1.5)
    return base * clampf(_campaign_supply_factor, 0.25, 1.5)


func _set_campaign_supply_factor(factor: float) -> void:
    _campaign_supply_factor = clampf(factor, 0.25, 1.5)


func _get_campaign_supply_factor() -> float:
    return _campaign_supply_factor


func _get_endurance_blood_volume_mult() -> float:
    var effective_end: float = float(endurance)
    if CompanyState.read_stub_proficiency_enabled() and "_proficiency_bonus" in self:
        effective_end += float(_proficiency_bonus.get("endurance", 0) or 0)
    return 1.0 + (effective_end - 100) / 400.0


func _get_endurance_healing_speed_mult() -> float:
    var effective_end: float = float(endurance)
    if CompanyState.read_stub_proficiency_enabled() and "_proficiency_bonus" in self:
        effective_end += float(_proficiency_bonus.get("endurance", 0) or 0)
    return 1.0 - clampf((effective_end - 100) / 500.0, 0.0, 0.25)


func _get_intelligence_contract_bonus_mult() -> float:
    var effective_int: float = float(intelligence)
    if CompanyState.read_stub_proficiency_enabled() and "_proficiency_bonus" in self:
        effective_int += float(_proficiency_bonus.get("intelligence", 0) or 0)
    return 1.0 + clampf((effective_int - 100) / 500.0, 0.0, 0.15)


func _get_campaign_stamina_mult() -> float:
    var m: float = 1.0
    for raw in campaign_afflictions:
        if raw is Dictionary:
            m *= clampf(raw.get("stamina_mult", 1.0), 0.5, 1.0)
    return m


func _get_campaign_pain_mult() -> float:
    var m: float = 1.0
    for raw in campaign_afflictions:
        if raw is Dictionary:
            m *= clampf(raw.get("pain_mult", 1.0), 0.5, 1.5)
    return m


func _add_campaign_affliction(def: Dictionary) -> bool:
    if def.is_empty():
        return false
    var id: String = def.get("id", "")
    if id.is_empty():
        return false
    for raw in campaign_afflictions:
        if raw is Dictionary and raw.get("id", "") == id:
            return false
    campaign_afflictions.append(def.duplicate(true))
    return true


func _get_campaign_affliction_labels() -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    for raw in campaign_afflictions:
        if raw is Dictionary:
            out.append(raw.get("label", raw.get("id", "")))
    return out


func _get_tourniquet_application_time_seconds() -> float:
    return EntityMedical._get_tourniquet_application_time_seconds()


func _can_apply_bandage(part: String) -> bool:
    return EntityMedical._can_apply_bandage(self, part)


func _apply_bandage(part: String, effectiveness: float = 1.0) -> bool:
    return EntityMedical._apply_bandage(self, part, effectiveness)


func _can_apply_stabilize(part: String) -> bool:
    return EntityMedical._can_apply_stabilize(self, part)


func _apply_stabilize(part: String, effectiveness: float = 1.0) -> bool:
    return EntityMedical._apply_stabilize(self, part, effectiveness)


func _get_stabilize_application_time_seconds_for_part(part: String) -> float:
    return EntityMedical._get_stabilize_application_time_seconds_for_part(self, part)


func can_apply_packing(part: String) -> bool:
    return EntityMedical.can_apply_packing(self, part)


func _apply_packing(part: String, effectiveness: float = 1.0) -> bool:
    return EntityMedical._apply_packing(self, part, effectiveness)


func _get_packing_application_time_seconds_for_part(part: String) -> float:
    return EntityMedical._get_packing_application_time_seconds_for_part(self, part)


func _get_medical_entity() -> Node:
    return self


func ensure_consciousness_current() -> void:
    if _consciousness_dirty:
        _update_consciousness()


func _can_apply_direct_pressure(target_part: String) -> bool:
    return EntityMedical._can_apply_direct_pressure(self, target_part)


func _can_apply_direct_pressure_from_ally(part: String, performer_entity: Node = null) -> bool:
    return EntityMedical._can_apply_direct_pressure_from_ally(self, part, performer_entity)


func _apply_direct_pressure_from_ally(part: String, performer_entity: Node = null) -> bool:
    return EntityMedical._apply_direct_pressure_from_ally(self, part, performer_entity)


func _stack_assist_pressure_eligible(part: String, assist_entity: Node = null) -> bool:
    return EntityMedical._stack_assist_pressure_eligible(self, part, assist_entity)


func _stack_assist_pressure_during_ally_treatment(part: String, assist_entity: Node = null) -> bool:
    return EntityMedical._stack_assist_pressure_during_ally_treatment(self, part, assist_entity)


func apply_direct_pressure(part: String, effectiveness: float = -1.0) -> bool:
    return EntityMedical.apply_direct_pressure(self, part, effectiveness)


func _is_applying_direct_pressure() -> bool:
    return EntityMedical.is_applying_direct_pressure(self)


func has_direct_pressure_on_part(part: String) -> bool:
    return EntityMedical.has_direct_pressure_on_part(self, part)


func _get_direct_pressure_part() -> String:
    return EntityMedical.get_direct_pressure_part(self)


func _clear_direct_pressure() -> void:
    EntityMedical.clear_direct_pressure(self)


func _prepare_for_medical_windup(target: Node, part: String) -> void:
    EntityMedical._prepare_for_medical_windup(self, target, part)


func _is_tourniquet_indicated_for_part(part: String) -> bool:
    return EntityMedical._is_tourniquet_indicated_for_part(self, part)


func _can_apply_tourniquet(part: String) -> bool:
    return EntityMedical._can_apply_tourniquet(self, part)


func _is_tourniquet_applied(part: String) -> bool:
    return EntityMedical._is_tourniquet_applied(self, part)


func _apply_tourniquet(part: String, effectiveness: float = 1.0) -> bool:
    return EntityMedical._apply_tourniquet(self, part, effectiveness)


func _remove_tourniquet(part: String) -> void:
    EntityMedical._remove_tourniquet(self, part)


## Tracks failed tourniquet attempts per limb for escalating retry chance.
func _get_tourniquet_failures(part: String, default: int = 0) -> int:
    return int(tourniquet_failures.get(part, default))


func _set_tourniquet_failures(part: String, count: int) -> void:
    tourniquet_failures[part] = count


# Healing: exponential deficit decay (tissue, bone, blood). Per-wound: pain decays by healing progress; resolved wounds
# removed.
# Call on time advance. Game time advances here for per-wound healing and pain.
func _process_healing(seconds: float) -> void:
    EntityHealing._process_healing(self, seconds)


func _ready():
    if species != null:
        _apply_species()


func apply_species():
    _apply_species()


func _apply_species():
    _death_notified = false
    if has_meta("_fp_death_notified"):
        remove_meta("_fp_death_notified")
    body_cutting.clear()
    body_blunt.clear()
    body_max.clear()
    bone_health.clear()
    bone_max.clear()
    wounds.clear()
    tissue_layer_state.clear()
    tissue_energy_capacity_j.clear()
    tissue_energy_remaining_j.clear()
    tourniquet_applied.clear()
    tourniquet_failures.clear()
    bandaged_parts.clear()
    packed_parts.clear()
    linen_strips_remaining = BleedingConstants.PACKING_LINEN_PARTY_START
    direct_pressure_part = ""
    self_direct_pressure_part = ""
    direct_pressure_assist_held_by = null
    _game_time_seconds = 0.0
    if BloodVolumeMl.is_active() and species != null:
        var ref_kg: float = CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
        if species.has_method("resolved_reference_mass_kg"):
            ref_kg = species.resolved_reference_mass_kg()
        BloodVolumeMl.init_entity_pool(self, ref_kg)
    else:
        BloodVolumeMl.clear_entity_pool(self)
        blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    consciousness = 100.0
    effective_consciousness = 100.0
    _consciousness_dirty = false
    _pain_shock_until_time = -1.0
    _concussion_until_time = 0.0
    _last_hit_impact = 0.0
    _ambient_pain_shock_accum = 0.0
    if species != null and species.name != "":
        self.name = species.name
    if species != null:
        _seed_body_parts_from_species(species)
        strength = species.strength
        agility = species.agility
        intelligence = species.intelligence
        endurance = species.endurance
        perception = species.perception
    else:
        # Fallback when no species: use generic values consistent with aggressive realism scale
        _seed_body_parts_generic()
        strength = 100
        agility = 100
        intelligence = 100
        endurance = 100
        perception = 100
    _apply_common_seed_defaults()


## Common seed defaults shared by species and fallback branches.
func _apply_common_seed_defaults():
    dominant_hand = [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM][randi() % 2]
    offhand_functionality = randf_range(0.6, 1.0)
    CombatLayerTissue.seed_all_layer_states(self)
    TissueEnergyCapacity.seed_entity_energy_pools(self, true)


func _seed_body_parts_from_species(species_resource: Resource) -> void:
    for p in _get_body_part_list():
        var m = species_resource.get_body_part_max(p) if species_resource.has_method("get_body_part_max") else 10
        var b = species_resource.get_bone_max(p) if species_resource.has_method("get_bone_max") else maxi(1, m / 2)
        body_max[p] = m
        body_cutting[p] = _round_tissue(float(m))
        body_blunt[p] = _round_tissue(float(m))
        bone_max[p] = b
        bone_health[p] = _round_tissue(float(b))


func _seed_body_parts_generic() -> void:
    for p in _get_body_part_list():
        body_max[p] = CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
        body_cutting[p] = _round_tissue(12.0)
        body_blunt[p] = _round_tissue(12.0)
        bone_max[p] = 8
        bone_health[p] = _round_tissue(8.0)







