class_name CoreEntity
extends Node2D
## Entity sim facade: holds tissue / wound / gear state; logic lives in Entity* modules
## (Wounds, Medical, Healing, Damage, Equipment, PainConsciousness, Proficiency, StatsUtil).
## Combat reads via CombatantEntityAccess / health entity — see docs/ARCHITECTURE.md.
## Stats boosted by training drill (merged into proficiency bonus after each contract). Per-stat.
## Medical effectiveness from intelligence (100 INT = 1.0; 50 = 0.75, 150 = 1.25). Used for bandage, direct pressure.
## Max blood volume scaling from END (100 |' 1.0x; 150 |' 1.25x). Applied in BloodVolumeMl.init_entity_pool.
## Camp rest healing speed from END (100 |' 1.0x; 150 |' ~1.20x faster). Applied in EntityHealing tau calculations.
## Contract pay scaling from INT (100 |' 1.0x; 150 |' 1.075x max). Applied in CompanyState post-victory gold.
## Ensure consciousness/performance are current before UI reads. Only recalculates when dirty.

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

## XCamp-6: queued camp drills for fighting form / weapon proficiency (mirrors training_pending,
## but keyed by form id / weapon id). Merged into _form_proficiency / _weapon_proficiency at the
## next camp rest via EntityProficiency.merge_form/weapon_training_pending.
var _form_training_pending: Dictionary = {}
var _weapon_training_pending: Dictionary = {}

## Day index of last combat participation (for calendar-day decay calculation).
var last_fought_day: int = 0

## XCamp-4: highest campaign day up to which proficiency decay has already been charged for the
## current absence. Lets EntityProficiency.apply_decay() apply only the not-yet-decayed tail so
## consecutive calls (e.g. each camp rest) do not re-count the same rusting days.
var last_decay_day: int = 0

## XCamp-4b: gladiator display name. Per-individual identity set at setup/hire and
## persisted so a surviving fighter keeps their name across save/load (and it does not
## get re-rolled for a new hire into the same slot). Empty = fall back to slot-derived name.
var fighter_name: String = ""

## Medical-staff role tag. Empty = combatant. "surgeon" = hired medical staff who never enter a
## lineup (excluded from fightable party nodes) but ride into campaign fights and unlock full TCCC
## in the post-victory medical phase (see `CombatManager.register_surgeon`). Persisted like fighter_name.
var fighter_role: String = ""

## XCamp-5f: per-fighter fame. A personal brand distinct from company renown: accrues on each
## victory scaled by how hard that fighter made it (opponent difficulty) plus kill bonuses.
## Drives the sponsor payout and career-tier label on the gladiator. Persisted like fighter_name.
var fame: int = 0

## Whether this merc participated in the most recent combat (tracks who fought vs who stayed at camp).
var last_fought_in_combat: bool = false
## Nutrition level 0.0 (starving) - 1.0 (well-fed); set on the daily provisions tick. Malnutrition slows healing.
var nutrition_level: float = 1.0
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
# Attacking arm: which hand is dominant and offhand effectiveness (0.6--"1.0).
var dominant_hand: String = BodyPartConstants.PART_RIGHT_ARM
var offhand_functionality: float = 0.8
# Lead leg: the leg that steps into a strike (drive/extension), as opposed to the trail leg
# that pushes off. Drives per-leg wind-up; the trail leg is not modeled separately in v1.
var lead_leg: String = BodyPartConstants.PART_RIGHT_LEG
# One armor piece per body part (e.g. chest -> Cuirass with plate + gambeson layers).
var armor_slots: Dictionary = {}  # body_part (String) -> ArmorPiece
# Optional equipped weapon (Weapon instance from template). Null = unarmed.
var weapon = null

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
var blood_volume: float = 100.0  # 0--"100; death below BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
## S6 literal pool when `FEATURE_LITERAL_BLOOD_ML` (-1 = percent-only mode).
var blood_volume_ml: float = -1.0
var blood_volume_ml_max: float = -1.0
# Tourniquet: limb parts only. part -> { "applied_at": float, "effectiveness": float }. Effectiveness 0--"1 scales
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
## CAMP-SCAR-1: resolved-wound descriptors stashed during a healing advance (core); the world layer mints
## scars from this and clears it. Entry: { part, severity, injury_type, is_compound_fracture,
## was_infected, had_ischemia, is_osteomyelitis }. Campaign-only (day-advance), never mid-battle.
var resolved_wounds_this_advance: Array[Dictionary] = []
## Campaign → combat muscle fatigue carry-over (part -> 0..1). Synced from combatant dict after fights.
var muscle_fatigue: Dictionary = {}
## Campaign weariness: 0..1 fatigue accumulated from fighting + daily operations; recovered by camp rest.
## A fatigued member has a lower stamina cap (see _get_campaign_stamina_mult). Accumulates per battle + per day.
const CAMPAIGN_FATIGUE_STAMINA_FLOOR: float = 0.7  # stamina cap multiplier at full fatigue
const CAMPAIGN_FATIGUE_PER_BATTLE: float = 0.2  # fatigue added per battle fought
const CAMPAIGN_FATIGUE_PER_DAY: float = 0.1  # fatigue added per day of campaign operations
var campaign_fatigue: float = 0.0
## Rest-quality floor: even a poorly-provisioned (starving) camp lets a member recover at least this
## fraction of accumulated weariness in one night. A well-fed camp (quality 1.0) fully clears it.
const REST_QUALITY_FLOOR: float = 0.3
## Weapon edge wear: 0..1 dullness accumulated from fighting; restored by sharpening at camp rest.
## A worn edge cuts less effectively (lower weapon sharpness => wider contact + duller wedge angle).
## Applied to the equipped weapon at battle start (see apply_weapon_edge_wear_to_weapon).
const WEAPON_EDGE_WEAR_DULL_SHARPNESS: float = 0.4  # weapon sharpness at full wear (1 = razor-sharp, 0 = dull)
const WEAPON_EDGE_WEAR_PER_BATTLE: float = 0.15  # edge wear added per battle fought
var weapon_edge_wear: float = 0.0
var consciousness: float = 100.0  # true consciousness (incapacitation when < 10)
var effective_consciousness: float = 100.0  # for combat (after pain shock)
# Optional bleed pacing overrides (default full ATLS drain; future explicit fluid resuscitation may raise recovery).
var _combat_blood_loss_mult: float = 1.0
var _combat_blood_recovery_per_s: float = 0.0
## Active combat exertion flag: movement prevents clotting, adrenaline increases heart rate,
## wounds reopen with exertion. Set by CombatProcessTick from combatant state; read by EntityWounds
## for ~50% faster bleeding and ~40% reduced clotting during active combat.
var exertion_active: bool = false
## Camp-2.4 permanent injuries; each entry `{ id, label, stamina_mult, pain_mult }`.
var _campaign_supply_factor: float = 1.0

## Per-stat proficiency bonus above species base (int). Grows through combat, decays through inactivity.
## Stored as SEPARATE dict from base stats so _apply_species() cannot wipe it.
## Read dynamically by EntityProficiency / EntityStatsUtil, hence the ignore.
@warning_ignore("unused_private_class_variable")
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
## Proficiency-tracked fighter (campaign party onboarding). Enables the combat skill curve
## (melee_skill from weapon/form experience, below-baseline reads as "untrained").
## Read dynamically by EntityProficiency, hence the ignore.
@warning_ignore("unused_private_class_variable")
var _combat_skill_trained: bool = false
var _game_time_seconds: float = 0.0
var _pain_shock_until_time: float = -1.0  # Time.get_ticks_msec()/1000.0 when shock ends; -1 = not in shock
# Total damage of last hit (for pain-shock duration scaling); set on weapon hit, consumed when shock is entered
var _last_hit_impact: float = 0.0
var _ambient_pain_shock_accum: float = 0.0  # Combat tick accumulator for sustained-pain shock rolls
# Timestamp of last ambient pain shock trigger (for cooldown enforcement)
var _last_ambient_pain_shock_time: float = -1.0
## Adrenaline dump cycle — surge→plateau→crash model per exercise physiology (McArdle Katch & Katch Ch.12).
## Onset triggered by pain shock or severe blood loss; surge boosts performance 10-30s, plateau holds then crashes.
var _adrenaline_dump_until_time: float = -1.0  # game time when adrenaline dump ends; -1 = inactive
var _adrenaline_phase: String = ""  # "surge", "plateau", "crash" during active dump
var _adrenaline_cooldown_until: float = -1.0  # game time when next adrenaline dump is allowed
var _consciousness_dirty: bool = true

var _death_notified: bool = false
## Sepsis (CAMP-INF-1): entity-level systemic infection state. Set when any wound reaches
## infection_stage == 2; persists until recovered (sepsis_resolve_progress >= 1) or death.
var is_septic: bool = false
## 0..1 accrual toward sepsis recovery; only advances while the septic focus is source-controlled.
var sepsis_resolve_progress: float = 0.0
## Death flag set by the sepsis day-advance death roll; folded into is_dead() + _get_death_reason().
var _sepsis_dead: bool = false
## Latched true on first sepsis recovery (CAMP-SCAR-1): used to mint the whole-body
## post_sepsis_weakness scar once (plan §2.3: "was is_septic and is now recovered").
var sepsis_recovered: bool = false
## Tetanus (Phase A+, plan §10.2): entity-level spore-load + systemic-rigidity state.
## Incubation is entity-level (spores germinate in the body) so it survives the seeding wound
## resolving — the wound can fully heal before the member manifests 3-21 days later.
## -1.0 = no spore load present; > 0.0 = days remaining until the onset roll.
var tetanus_incubation_days: float = -1.0
## Systemic tetanus rigidity active; persists for the TETANUS_SYMPTOMATIC_DAYS window (death roll + perception tell).
var is_tetanus: bool = false
## 0..1 accrual across the tetanus symptomatic window; at 1.0 the member survives (is_tetanus cleared).
var tetanus_resolve_progress: float = 0.0
## Death flag set by the tetanus per-day death roll; folded into is_dead() + _get_death_reason().
var _tetanus_dead: bool = false
## Latched at spore-load arming: true when the contaminated part had definitive hemostasis (clean
## / debrided / dressed) at the moment spores were seeded. A well-dressed wound halves the onset
## probability (debridement removes spores before germination — plan §10.2 counter-play).
var tetanus_cleaned_at_arm: bool = false
## Grace period after vital destruction before death is registered (seconds of combat time).
## Models the real-world delay between organ destruction and circulatory collapse. Fallback for
## parts not listed in VITAL_DESTRUCTION_GRACE_PERIODS.
const VITAL_DESTRUCTION_GRACE_PERIOD_S: float = 2.5
## Per-part grace periods after vital destruction (combat seconds). Head (brain/brainstem)
## destruction collapses consciousness and autonomic control almost immediately (~1.5s); chest
## (heart/great-vessel) destruction causes tamponade + hemorrhagic shock over a slightly longer
## window (~3.0s) — long enough that in multi-fighter fights a coup de gràce can land on the
## downed fighter before death registers, matching the historical execution flow.
const VITAL_DESTRUCTION_GRACE_PERIODS: Dictionary = {
	BodyPartConstants.PART_HEAD: 1.5,
	BodyPartConstants.PART_CHEST: 3.0,
}
## Remaining grace time after a vital part is destroyed; decremented each combat tick in
## process_blood_loss. Negative means "no active grace". Once it reaches 0, is_dead() returns true.
var _vital_grace_remaining: float = -1.0


## Grace period (combat seconds) to apply when `part` is destroyed as a vital. Uses the per-part
## table; falls back to VITAL_DESTRUCTION_GRACE_PERIOD_S for unlisted parts.
static func vital_grace_period_for_part(part: String) -> float:
	return float(VITAL_DESTRUCTION_GRACE_PERIODS.get(part, VITAL_DESTRUCTION_GRACE_PERIOD_S))


func _get_training_pending() -> Dictionary:
	return training_pending


func _set_training_pending_value(stat: String, value: float) -> void:
	training_pending[stat] = value


func _get_form_training_pending() -> Dictionary:
	return _form_training_pending


func _set_form_training_pending_value(form: String, value: float) -> void:
	_form_training_pending[form] = value


func _get_weapon_training_pending() -> Dictionary:
	return _weapon_training_pending


func _set_weapon_training_pending_value(weapon_id: String, value: float) -> void:
	_weapon_training_pending[weapon_id] = value


# BleedingConstants is class_name in core/BleedingConstants.gd; preload for linter/standalone parse


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
	emit_signal("died")


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


func _is_part_destroyed(part: String) -> bool:
	return BodyPartQuery.is_part_destroyed(self, part)


func _get_bone_functionality_factor(part: String) -> float:
	return BodyPartQuery.get_bone_functionality_factor(self, part)


func _get_offhand() -> String:
	return (
		BodyPartConstants.PART_LEFT_ARM
		if dominant_hand == BodyPartConstants.PART_RIGHT_ARM
		else BodyPartConstants.PART_RIGHT_ARM
	)


func _get_leg_functionality() -> float:
	var base: float = BodyPartQuery.get_leg_functionality(self)
	# CAMP-SCAR-1 §9.5: a scarred/malunited/infected-bone leg drives slower. Latches onto the
	# whole-locomotion value, so it also raises movement stamina cost and the cowering threshold.
	var lp: float = _get_scar_part_penalty(BodyPartConstants.PART_LEFT_LEG).get("move_speed", 1.0)
	var rp: float = _get_scar_part_penalty(BodyPartConstants.PART_RIGHT_LEG).get("move_speed", 1.0)
	return clampf(base * lp * rp, 0.0, 1.0)


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


# --- Pain and consciousness (Combat Extended—style) ---
# Per-wound healing progress 0..1 (exponential: after healing_duration seconds ~95% healed). Backwards compat: missing
# fields => progress 0.
func _get_wound_healing_progress(injury: Dictionary) -> float:
	return EntityWounds._get_wound_healing_progress(self, injury)


func _get_pain_contribution_for_wound(
	part: String,
	damage: float,
	severity: String,
	injury_type: String,
	sub_region: String,
	is_stump: bool = false,
	penetration_to_tissue_mm: float = -1.0
) -> float:
	return EntityPainConsciousness.get_pain_contribution_for_wound(
		self, part, damage, severity, injury_type, sub_region, is_stump, penetration_to_tissue_mm
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


func _get_adrenaline_dump_until_time() -> float:
	return _adrenaline_dump_until_time


func _set_adrenaline_dump_until_time(value: float) -> void:
	_adrenaline_dump_until_time = value


func _get_adrenaline_phase() -> String:
	return _adrenaline_phase


func _set_adrenaline_phase(value: String) -> void:
	_adrenaline_phase = value


func _get_adrenaline_cooldown_until() -> float:
	return _adrenaline_cooldown_until


func _set_adrenaline_cooldown_until(value: float) -> void:
	_adrenaline_cooldown_until = value


func _tick_adrenaline_dump() -> void:
	EntityPainConsciousness.tick_adrenaline_dump(self)


func _update_consciousness() -> void:
	EntityPainConsciousness.update_consciousness(self)


func is_cowering() -> bool:
	if get_attacking_arm().is_empty():
		return true
	var leg_func: float = _get_leg_functionality()
	if leg_func <= PainConsciousnessConstants.LEG_COWER_THRESHOLD:
		return true
	var blood_pct: float = blood_volume
	if blood_pct < 40.0 and is_unconscious():
		return true
	return false


## Returns a string describing the cowering cause: "arms", "legs", or "".
## Used by AttackResultApplier to show accurate incapacitation reason.
func get_cowering_reason() -> String:
	if not is_cowering():
		return ""
	if get_attacking_arm().is_empty():
		return "arms"
	var leg_func: float = _get_leg_functionality()
	if leg_func <= PainConsciousnessConstants.LEG_COWER_THRESHOLD:
		return "legs"
	return ""


## True when blood/head trauma has dropped true consciousness below the incapacitation floor (cannot act or move).
func is_unconscious() -> bool:
	ensure_consciousness_current()
	return consciousness <= PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD


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


func get_parry_capacity_modifier() -> float:
	return EntityPainConsciousness.get_parry_capacity_modifier(self)


func get_dodge_speed_modifier() -> float:
	return EntityPainConsciousness.get_dodge_speed_modifier(self)


func is_dead() -> bool:
	# Sepsis death (CAMP-INF-1): the day-advance sepsis death roll sets _sepsis_dead; the campaign
	# polls is_dead() to reconcile the roster, so the flag must fold in here.
	if _sepsis_dead:
		return true
	# Tetanus death (Phase A+, plan §10.2): same day-advance death-roll pattern as sepsis.
	if _tetanus_dead:
		return true
	if blood_volume <= _get_blood_loss_death_threshold():
		return true
	# Grace period: vital destruction is not instantly fatal. The countdown is initialized in
	# EntityDamage when a vital part is destroyed and decremented each combat tick in
	# process_blood_loss. Death is registered only once the grace elapses (models the real-world
	# delay between organ destruction and circulatory collapse). During the grace the entity is
	# incapacitated (consciousness capped) but not yet dead.
	if is_vital_part_destroyed():
		return _vital_grace_remaining <= 0.0
	return false


## True when a vital part (head/chest) has lost most of its tissue — total (cut + blunt) pools
## below 30% of max. A mostly-destroyed vital part caps consciousness at 4 (below the
## incapacitation floor) so the fighter is unconscious, not a "zombie" winner.
##
## Head special case: a head blow KOs only when the skull is actually fractured (brain trauma).
## A scalp laceration with a >=50%-intact skull degrades consciousness smoothly via the
## head-fraction term in update_consciousness instead of one-shot KO — matching mTBI data where
## loss of consciousness occurs in only ~10% of concussions and is brief. Without this gate a
## sub-fracture head hit (e.g. a 56J clip below the ~80J skull-fracture anchor) emptied the small
## head tissue pool and KO'd the fighter via the tissue cap alone. Chest has no skull equivalent,
## so its tissue-destruction cap is unchanged.
func is_vital_part_critically_damaged() -> bool:
	const CRITICAL_TISSUE_FRACTION: float = 0.30
	for part in _get_vital_parts():
		var max_val: float = float(body_max.get(part, 0.0))
		if max_val <= 0.0:
			continue
		if part == BodyPartConstants.PART_HEAD:
			var skull_max: float = float(bone_max.get(part, 0.0))
			var skull_remaining: float = float(bone_health.get(part, 0.0))
			if skull_max > 0.0 and skull_remaining >= skull_max * 0.5:
				continue
		var total: float = float(body_cutting.get(part, 0.0) + body_blunt.get(part, 0.0))
		if total < max_val * 2.0 * CRITICAL_TISSUE_FRACTION:
			return true
	return false


## Single source of truth for "is this vital part destroyed" — a vital is destroyed when it is
## severed/crushed (a tissue pool AND bone at zero) OR both tissue pools are at zero. Any two of
## the three pools (cutting, blunt, bone) at zero counts. Used by is_dead() (grace countdown),
## is_vital_part_destroyed() (consciousness cap), and the EntityDamage grace initializer so the
## death path, incapacitation cap, and grace trigger can never drift apart.
func _is_vital_part_destroyed(part: String) -> bool:
	if part not in _get_vital_parts():
		return false
	if part == BodyPartConstants.PART_HEAD:
		var skull_max: float = float(bone_max.get(part, 0.0))
		var skull_remaining: float = float(bone_health.get(part, 0.0))
		if skull_max > 0.0 and skull_remaining >= skull_max * 0.5:
			return false
	return _is_part_destroyed(part) or (body_cutting.get(part, 0.0) <= 0.0 and body_blunt.get(part, 0.0) <= 0.0)


## True when a vital part is destroyed AND the grace countdown has run down to exactly 0.0.
## Unlike the `<= 0.0` test used by is_dead() (which is also true when no grace is armed, i.e.
## -1.0, e.g. test-manipulated vital destruction), this is only true when a grace period actually
## elapsed. Consumed by the per-tick death handler for the VITAL_GRACE_EXPIRED trace line.
func vital_grace_has_elapsed() -> bool:
	return is_vital_part_destroyed() and _vital_grace_remaining == 0.0


## True when any vital part (head/chest) is destroyed. Distinct from
## is_vital_part_critically_damaged() which triggers at <30% tissue.
func is_vital_part_destroyed() -> bool:
	for part in _get_vital_parts():
		if _is_vital_part_destroyed(part):
			return true
	return false


# Returns a short string describing why this entity is dead (for combat/debug logging). Call only when is_dead() is
# true.
func _get_death_reason() -> String:
	# Check vital-part destruction FIRST: a destroyed head/chest is the definitive cause of death.
	# emit_death_once clamps blood_volume to the death threshold when a vital part is destroyed, so a
	# blood check first (with <=) would mislabel a head/chest kill as "blood_loss" (BLEED_OUT) instead
	# of "vital_part_destroyed" (VITAL_DESTROYED). Blood loss is the cause only when no vital part failed.
	for part in _get_vital_parts():
		if _is_part_destroyed(part):
			var sever_cut: float = body_cutting.get(part, 0.0)
			var sev_blunt: float = body_blunt.get(part, 0.0)
			var bone: float = bone_health.get(part, 0.0)
			return "vital_part_destroyed (%s severed/crushed cut=%.1f blunt=%.1f bone=%.1f)" % [part, sever_cut, sev_blunt, bone]
		var zero_cut: float = body_cutting.get(part, 0.0)
		var zero_blunt: float = body_blunt.get(part, 0.0)
		if zero_cut <= 0.0 and zero_blunt <= 0.0:
			return "vital_part_zero (%s cut=%.2f blunt=%.2f)" % [part, zero_cut, zero_blunt]
	# Sepsis (CAMP-INF-1): after a definitive vital-part cause, before blood_loss. A sepsis death
	# clamps blood_volume via emit_death_once, so a blood check first would mislabel it.
	if _sepsis_dead:
		return "sepsis (systemic infection)"
	# Tetanus (plan §10.2): after sepsis, before blood_loss — a tetanus death clamps blood_volume
	# via emit_death_once, so a blood check first would mislabel it.
	if _tetanus_dead:
		return "tetanus (tetanospasmin)"
	var death_thresh: float = _get_blood_loss_death_threshold()
	if blood_volume <= death_thresh:
		return "blood_loss (remaining=%.1f at/below fatal floor %.1f)" % [blood_volume, death_thresh]
	return "unknown"


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
	# Advance the vital-destruction grace countdown each combat tick. This runs in both
	# real-time and batch/fast-forward mode (both call process_blood_loss with the tick
	# delta), so the grace elapses on combat time rather than wall-clock. Once it reaches
	# 0, is_dead() flips to true and the per-tick death check registers the kill.
	if _vital_grace_remaining > 0.0:
		_vital_grace_remaining = maxf(0.0, _vital_grace_remaining - delta)
	EntityWounds.process_blood_loss(self, delta)


# --- Medical: delegated to EntityMedical (core/EntityMedical.gd) ---


func _get_bandage_application_time_seconds() -> float:
	return EntityMedical._get_bandage_application_time_seconds()


func _get_bandage_application_time_seconds_for_part(part: String) -> float:
	return EntityMedical._get_bandage_application_time_seconds_for_part(self, part)


func _get_medical_effectiveness() -> float:
	var effective_int: float = EntityStatsUtil.get_effective_stat(self, "intelligence")
	var base: float = clampf(effective_int / 100.0, 0.5, 1.5)
	return base * clampf(_campaign_supply_factor, 0.25, 1.5)


func _set_campaign_supply_factor(factor: float) -> void:
	_campaign_supply_factor = clampf(factor, 0.25, 1.5)


func _get_campaign_supply_factor() -> float:
	return _campaign_supply_factor


func _get_endurance_blood_volume_mult() -> float:
	var effective_end: float = EntityStatsUtil.get_effective_stat(self, "endurance")
	return 1.0 + (effective_end - 100) / 400.0


func _get_endurance_healing_speed_mult() -> float:
	var effective_end: float = EntityStatsUtil.get_effective_stat(self, "endurance")
	# Higher END heals FASTER (fit veterans recover quicker): 100 -> 1.0x, 150 -> 1.20x, caps at 1.25x.
	# (The old `1.0 - ...` form inverted this, making fit characters heal slower.)
	return 1.0 + clampf((effective_end - 100) / 250.0, 0.0, 0.25)


func set_nutrition_level(value: float) -> void:
	nutrition_level = clampf(value, 0.0, 1.0)


func _get_nutrition_healing_speed_mult() -> float:
	# Malnutrition impairs wound healing (clinical: protein/energy deficiency slows tissue repair).
	# Well-fed (1.0) -> 1.0x; starving (0.0) -> NUTRITION_HEAL_STARVATION_MULT (0.6x).
	return lerpf(HealingConstants.NUTRITION_HEAL_STARVATION_MULT, 1.0, clampf(nutrition_level, 0.0, 1.0))


func _get_intelligence_contract_bonus_mult() -> float:
	var effective_int: float = EntityStatsUtil.get_effective_stat(self, "intelligence")
	return 1.0 + clampf((effective_int - 100) / 500.0, 0.0, 0.15)


func _get_campaign_stamina_mult() -> float:
	var m: float = 1.0
	for raw in campaign_afflictions:
		if raw is Dictionary:
			m *= clampf(raw.get("stamina_mult", 1.0), 0.5, 1.0)
	m *= _get_campaign_fatigue_mult()
	m *= _get_sepsis_stamina_mult()
	# Chest scar (CAMP-SCAR-1 §9.5): scarred thorax reduces sustained stamina output.
	m *= _get_scar_part_penalty(BodyPartConstants.PART_CHEST).get("stamina_pool", 1.0)
	return m


## Stamina cap multiplier from active systemic sepsis (CAMP-INF-1): 1.0 healthy,
## SEPSIS_STAMINA_MULT while is_septic (systemic catabolism + CIP/CIM weakness).
func _get_sepsis_stamina_mult() -> float:
	return BleedingConstants.SEPSIS_STAMINA_MULT if is_septic else 1.0


## Stamina cap multiplier from campaign weariness: 1.0 (fresh) -> CAMPAIGN_FATIGUE_STAMINA_FLOOR (fully fatigued).
func _get_campaign_fatigue_mult() -> float:
	return lerpf(1.0, CAMPAIGN_FATIGUE_STAMINA_FLOOR, clampf(campaign_fatigue, 0.0, 1.0))


## Add fatigue from a battle fought (clamped to 0..1). Called at battle end (world/CombatFlow).
func add_campaign_fatigue_battle() -> void:
	campaign_fatigue = clampf(campaign_fatigue + CAMPAIGN_FATIGUE_PER_BATTLE, 0.0, 1.0)


## Add fatigue from a day of campaign operations (marching/operating; clamped to 0..1). Called on day tick.
func add_campaign_fatigue_day() -> void:
	campaign_fatigue = clampf(campaign_fatigue + CAMPAIGN_FATIGUE_PER_DAY, 0.0, 1.0)


## Clear campaign weariness (a proper rest at camp). Called on camp rest.
func clear_campaign_fatigue() -> void:
	campaign_fatigue = 0.0


## Apply a night's rest of the given quality (0..1) to campaign weariness. Quality 1.0 fully clears
## fatigue (a well-provisioned, safe camp); lower quality recovers only that fraction, leaving
## residual weariness. A starving or exposed company cannot fully shake off the campaign's toll in
## one night — the rest is partial and the member carries some fatigue into the next battle.
func apply_rest_quality(quality: float) -> void:
	var q: float = clampf(quality, 0.0, 1.0)
	campaign_fatigue = clampf(campaign_fatigue * (1.0 - q), 0.0, 1.0)


## Add edge wear from a battle fought (clamped to 0..1). Called at battle end (world/CombatFlow).
func add_weapon_edge_wear_battle() -> void:
	weapon_edge_wear = clampf(weapon_edge_wear + WEAPON_EDGE_WEAR_PER_BATTLE, 0.0, 1.0)


## Sharpen the weapon (a proper rest at camp restores the edge). Called on camp rest.
func sharpen_weapon() -> void:
	weapon_edge_wear = 0.0


## Apply the current edge wear to the equipped weapon's sharpness (1.0 fresh -> DULL at full wear).
## Called at battle start so the damage pipeline (which reads weapon.sharpness) sees the worn edge.
## Always reflects the current wear: wear 0 -> fresh (1.0), full wear -> WEAPON_EDGE_WEAR_DULL_SHARPNESS.
## No-op when there is no weapon. All weapons default to sharpness 1.0 (no template overrides it).
func apply_weapon_edge_wear_to_weapon() -> void:
	var w: Variant = get_weapon()
	if w == null or not ("sharpness" in w):
		return
	w.sharpness = lerpf(1.0, WEAPON_EDGE_WEAR_DULL_SHARPNESS, clampf(weapon_edge_wear, 0.0, 1.0))


func _get_campaign_pain_mult() -> float:
	var m: float = 1.0
	for raw in campaign_afflictions:
		if raw is Dictionary:
			m *= clampf(raw.get("pain_mult", 1.0), 0.5, 1.5)
	return m


## CAMP-SCAR-1: per-part incoming-damage multiplier from wound-derived scars (product of matching
## damage_mult). Whole-body scars (part "") never match a part, so they add nothing here.
func _get_scar_damage_mult(part: String) -> float:
	var m: float = 1.0
	for raw in campaign_afflictions:
		if raw is Dictionary and str(raw.get("part", "")) == part:
			m *= clampf(float(raw.get("damage_mult", 1.0)), 0.5, 2.0)
	return m


## CAMP-SCAR-1: per-part bleeding-rate multiplier (product of matching bleed_mult).
func _get_scar_bleed_mult(part: String) -> float:
	var m: float = 1.0
	for raw in campaign_afflictions:
		if raw is Dictionary and str(raw.get("part", "")) == part:
			m *= clampf(float(raw.get("bleed_mult", 1.0)), 0.5, 2.0)
	return m


## CAMP-SCAR-1: per-part heal multiplier (product of matching heal_mult; < 1.0 = heals slower).
func _get_scar_heal_mult(part: String) -> float:
	var m: float = 1.0
	for raw in campaign_afflictions:
		if raw is Dictionary and str(raw.get("part", "")) == part:
			m *= clampf(float(raw.get("heal_mult", 1.0)), 0.1, 1.0)
	return m


## CAMP-SCAR-1 §9.5: part-specific scar penalties (move_speed, grip, perception, stamina_pool).
## Returns a Dictionary of multiplier factors; each is the product of matching scars on that part.
## All values default to 1.0 (no penalty) when no scars match.
func _get_scar_part_penalty(part: String) -> Dictionary:
	var out: Dictionary = {"move_speed": 1.0, "grip": 1.0, "perception": 1.0, "stamina_pool": 1.0}
	if part.is_empty():
		return out
	for raw in campaign_afflictions:
		if not raw is Dictionary or str(raw.get("part", "")) != part:
			continue
		for k in out.keys():
			var v: float = float(raw.get(k, 1.0))
			if v != 1.0:
				out[k] *= clampf(v, 0.3, 1.0)
	return out


## CAMP-SCAR-1 §9.3: re-injury vulnerability. A part already carrying a scar re-injures more readily
## (lost rete pegs, reduced elasticity — mechanical stress stimulates scarring), so a new wound on it
## lands one band worse. Binary per-part (scarred vs clean), not scaled by scar count. Read in
## EntityWounds.severity_from_damage. 1.0 when the part has no scars.
func _get_scar_reinjury_mult(part: String) -> float:
	if part.is_empty():
		return 1.0
	for raw in campaign_afflictions:
		if raw is Dictionary and str(raw.get("part", "")) == part:
			return BleedingConstants.SCAR_REINJURY_MULT
	return 1.0


## Stash a resolved-wound descriptor (called by core EntityHealing at the resolution seam).
func _stash_resolved_wound(desc: Dictionary) -> void:
	resolved_wounds_this_advance.append(desc)


## World layer calls this after minting scars from resolved_wounds_this_advance.
func clear_resolved_wounds() -> void:
	resolved_wounds_this_advance.clear()


func _add_campaign_affliction(def: Dictionary) -> bool:
	if def.is_empty():
		return false
	var id: String = def.get("id", "")
	if id.is_empty():
		return false
	var part: String = str(def.get("part", ""))
	# CAMP-SCAR-1: wound-derived scars carry a part. On an id+part match, deepen the existing scar
	# (a second severe wound on a scarred part worsens it) instead of no-op-ing. Whole-body scars
	# (part "") keep the plain id-dedup behaviour. Deepen is SCAR-ONLY (plan §9.6): the post-victory
	# tier-RNG afflictions also carry a part (bone picks) but must keep plain id+part dedup — they are
	# tagged `is_wound_scar=false`, so a repeated "Limping left_leg" roll can never silently stack
	# damage_mult the way a wound-derived scar deepens.
	if part != "" and bool(def.get("is_wound_scar", false)):
		for i in range(campaign_afflictions.size()):
			var raw: Dictionary = campaign_afflictions[i]
			if raw is Dictionary and raw.get("id", "") == id and str(raw.get("part", "")) == part \
					and bool(raw.get("is_wound_scar", false)):
				raw["damage_mult"] = clampf(
					float(raw.get("damage_mult", 1.0)) * BleedingConstants.SCAR_DEEPEN_MULT, 1.0, 2.0
				)
				# A deepened scar also heals WORSE (hypovascular, reduced tensile strength / extensibility —
				# same anchor as SCAR_REINJURY_MULT), so the heal side deepens inverse to damage_mult
				# (× 1/1.05 ≈ 0.95) and clamps like the _get_scar_heal_mult read floor so repeated deepens
				# can never push below 0.1.
				raw["heal_mult"] = clampf(
					float(raw.get("heal_mult", 1.0)) * (1.0 / BleedingConstants.SCAR_DEEPEN_MULT), 0.1, 1.0
				)
				# bleed_mult is deliberately NOT deepened: the wound on a re-injured scar and the residual
				# friability were set at first mint (e.g. scarred_tissue 1.05); repeated scarring only makes
				# the tissue MORE hypovascular, so its hemorrhage does not grow multiplicatively with depth.
				return false
	for raw in campaign_afflictions:
		if raw is Dictionary and raw.get("id", "") == id and str(raw.get("part", "")) == part:
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


func _apply_fluid_resuscitation(effectiveness: float = 1.0) -> bool:
	return EntityMedical._apply_fluid_resuscitation(self, effectiveness)


## Surgical amputation (sepsis source control): sever the limb and replace its wounds with the
## stump. Delegates to EntityMedical.amputate_part (plan §10.5).
func amputate_part(part: String, sub_region: String = "") -> bool:
	return EntityMedical.amputate_part(self, part, sub_region)


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
	_vital_grace_remaining = -1.0
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
	campaign_afflictions.clear()
	_weapon_proficiency.clear()
	_form_proficiency.clear()
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
		strength = species.strength
		agility = species.agility
		intelligence = species.intelligence
		endurance = species.endurance
		perception = species.perception
	if species != null and typeof(species.name) == TYPE_STRING and species.name != "":
		self.name = species.name
	else:
		# Fallback when no species: use generic values consistent with aggressive realism scale
		for p in _get_body_part_list():
			body_max[p] = CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
			body_cutting[p] = _round_tissue(float(CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY))
			body_blunt[p] = _round_tissue(float(CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY))
			bone_max[p] = maxf(1, int(CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY / 2.0))
			bone_health[p] = _round_tissue(float(bone_max[p]))
		strength = 100
		agility = 100
		intelligence = 100
		endurance = 100
		perception = 100
	# Clear concussion metas between combat sessions (Issue 7a).
	if has_meta("_concussion_until_time"):
		remove_meta("_concussion_until_time")
	if has_meta("_concussion_onset_time"):
		remove_meta("_concussion_onset_time")
	if has_meta("_cumulative_concussion_count"):
		remove_meta("_cumulative_concussion_count")
	if has_meta("_last_concussion_time"):
		remove_meta("_last_concussion_time")
	# Persistent concussion fatigue (EntityPainConsciousness) is per-session brain impairment; it must
	# reset with the other concussion metas or it ratchets across campaigns into a permanent penalty.
	if has_meta("_concussion_persistent_fatigue"):
		remove_meta("_concussion_persistent_fatigue")
	if has_meta("_tuning_pain_shock_locked"):
		remove_meta("_tuning_pain_shock_locked")
	if has_meta("_tuning_pain_shock_locked_value"):
		remove_meta("_tuning_pain_shock_locked_value")
	if has_meta("_cumulative_trauma_timestamps"):
		remove_meta("_cumulative_trauma_timestamps")
	_apply_common_seed_defaults()


## Common seed defaults shared by species and fallback branches.
func _apply_common_seed_defaults():
	dominant_hand = [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM][randi() % 2]
	# Correlate lead leg with the dominant side so the lead/trail asymmetry (Tier 2.1) varies per
	# fighter: a right-hander leads with the right leg, a left-hander with the left. Reads the
	# already-seeded dominant_hand (no extra RNG call) so the deterministic harness stream is
	# unaffected; the D001/harness path pins lead_leg explicitly via apply_species_harness_deterministic.
	lead_leg = BodyPartConstants.PART_LEFT_LEG if dominant_hand == BodyPartConstants.PART_LEFT_ARM else BodyPartConstants.PART_RIGHT_LEG
	offhand_functionality = randf_range(0.6, 1.0)
	CombatLayerTissue.seed_all_layer_states(self)
	TissueEnergyCapacity.seed_entity_energy_pools(self, true)


## Deterministic species application for harness tests that overwrite RNG-driven fields anyway.
func apply_species_harness_deterministic():
	_apply_species()
	dominant_hand = BodyPartConstants.PART_RIGHT_ARM
	lead_leg = BodyPartConstants.PART_RIGHT_LEG
	offhand_functionality = 1.0


## Camp rest: clear muscle fatigue so it doesn't persist across campaigns.
