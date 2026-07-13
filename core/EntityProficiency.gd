class_name EntityProficiency
extends RefCounted

## XCamp-4: use-based stat proficiency system.
## Static methods for stat gain rates, decay calculation, and training application.
## All public mutation methods check CompanyState.read_stub_proficiency_enabled() at entry.
##
## Gain tiers (diminishing returns): 0-5 = 1.0x, 6-10 = 0.7x, 11-20 = 0.4x, 21-30 = 0.2x, 31+ = 0.1x.
## Decay tiers (per-stat calibrated): 11-15 = -0.03/day, 16-20 = -0.05/day, 21-25 = -0.08/day, 26+ = -0.12/day.
## Gain and decay use separate thresholds  -  gain follows a "proficiency level" model (novice|'elite),
## decay follows a "bonus magnitude" model calibrated for how quickly different magnitudes erode.
## Decay only applies to bonuses > 10.0  -  characters below +11 don't lose ground on basic training.

# Runtime preload ' circular dependency (CompanyState preloads CompanyCamp/Roster which preload EntityProficiency).
static var _CompanyState: Variant = null

static func _get_company_state() -> GDScript:
	if EntityProficiency._CompanyState == null:
		EntityProficiency._CompanyState = load("res://world/CompanyState.gd")
	return EntityProficiency._CompanyState

const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")

# --- Gain rate multipliers (diminishing returns by proficiency level) ---
const PROFICIENCY_NOVICE_MAX: int = 5
const PROFICIENCY_PROFICIENT_MAX: int = 10
const PROFICIENCY_VETERAN_MAX: int = 20
const PROFICIENCY_ELITE_MAX: int = 30

# --- Decay rates (per inactive day, before per-stat multiplier) ---
const DECAY_RATE_NOVICE_PLUS: float = -0.03   # +11 to +15
const DECAY_RATE_PROFICIENT_PLUS: float = -0.05  # +16 to +20
const DECAY_RATE_VETERAN_PLUS: float = -0.08   # +21 to +25
const DECAY_RATE_ELITE_PLUS: float = -0.12     # +26+

# --- Decay threshold boundaries (bonus magnitude tiers) ---
const DECAY_THRESHOLD_NOVICE_MAX: float = 15.0
const DECAY_THRESHOLD_PROFICIENT_MAX: float = 20.0
const DECAY_THRESHOLD_VETERAN_MAX: float = 25.0

# --- Per-stat decay multipliers (research-calibrated) ---
const DECAY_MULT_END: float = 1.5
const DECAY_MULT_AGI: float = 1.3
const DECAY_MULT_PER: float = 0.8
const DECAY_MULT_STR: float = 0.5
const DECAY_MULT_INT: float = 0.4

# --- Stance/form gain modifiers  -  derived from CombatWeaponForm._FORM_DEFS ---
## Maps form pressure class to stat training bonus profile.
## Aggressive forms |' strength bonus (overwhelming force).
## Defensive forms |' endurance bonus (durability under pressure).
## Controlling forms |' intelligence bonus (reading the fight).
## Neutral Ox |' agility + perception (thrust precision).
## Neutral Plow |' mixed endurance/agility (methodical spacing).
## Tempest is aggressive but gets unique STR/AGI treatment  -  checked before pressure match.
static func stance_mods_for_form(form: String) -> Dictionary:
	if form.is_empty():
		return {}
	var normalized: String = _WeaponForm.normalize_form(form)
	if normalized == _WeaponForm.FORM_TEMPEST:
		return {"strength": 1.18, "endurance": 1.0, "agility": 1.10}
	if normalized == _WeaponForm.FORM_OX:
		return {"strength": 1.10, "endurance": 1.0, "agility": 1.10, "perception": 1.10}
	if normalized == _WeaponForm.FORM_PLOW:
		return {"strength": 1.0, "endurance": 1.20, "agility": 1.05}
	if _WeaponForm.pressure_class_is(form, "aggressive"):
		return {"strength": 1.25, "endurance": 1.0}
	if _WeaponForm.pressure_class_is(form, "defensive"):
		return {"strength": 1.0, "endurance": 1.25}
	if _WeaponForm.pressure_class_is(form, "controlling"):
		return {"strength": 1.05, "endurance": 1.05, "intelligence": 1.15}
	return {"strength": 1.0, "endurance": 1.0}

# --- Weapon type learning curve modifiers (keys match Weapon.weapon_type) ---
const WEAPON_CURVES: Dictionary = {
	"SWORD": {"strength": 0.8, "agility": 0.9},
	"AXE": {"strength": 1.2, "agility": 0.95},
	"MACE": {"strength": 1.25, "agility": 0.85},
	"DAGGER": {"strength": 0.7, "agility": 1.2},
	"SPEAR": {"strength": 1.3, "agility": 1.0},
}

const GAIN_OFF_FOCUS_HIT_PER_BASE: float = 0.12
const GAIN_PREFERRED_PART_INT_BASE: float = 0.10
const GAIN_WEAPON_PROF_HIT_BASE: float = 0.25
const GAIN_FORM_PROF_HIT_BASE: float = 0.20

const WEAPON_PROF_VETERAN_MAX: float = 20.0
const FORM_PROF_VETERAN_MAX: float = 20.0
const PROF_OCCURRENCE_MULT_MAX: float = 1.35
const PROF_AIM_MULT_MAX: float = 1.15
const PROF_INTENDED_PART_BOOST_MIN: float = 2.0
const PROF_INTENDED_PART_BOOST_MAX: float = 3.0

# --- Base gain amounts per combat event (raw proficiency points) ---
const GAIN_MELEE_HIT_BASE: float = 0.3
const GAIN_MELEE_HIT_MAX_DMG_CONTRIB: float = 2.0
const GAIN_SEVERE_WOUND_BASE: float = 0.5
const GAIN_STRIKE_ATTEMPTED_BASE: float = 0.15
const GAIN_DODGE_EVaded_BASE: float = 0.4
const GAIN_DODGE_OUTNUMBERED_BONUS: float = 0.2
const GAIN_WINDUP_COMPLETED_AGI_BASE: float = 0.1
const GAIN_MEDICAL_ACTION_BASE: float = 0.5
const GAIN_MEDIC_INT_FLOOR: float = 0.5
const GAIN_DAMAGE_ABSORBED_BASE: float = 0.2
const GAIN_DAMAGE_ABSORBED_MAX_CONTRIB: float = 1.5
const GAIN_HIT_STR_DAMAGE_DIVIDER: float = 10.0
const GAIN_END_DMG_TAKEN_DIVIDER: float = 15.0
const GAIN_BLOOD_PERIL_BASE: float = 0.8

# --- Parry outcome multipliers (fraction of base gains) ---
const GAIN_PARRY_DEFLECT_STR_MULT: float = 0.5
const GAIN_PARRY_DEFLECT_END_MULT: float = 0.5
const GAIN_PARRY_PARTIAL_STR_MULT: float = 0.3

# --- Medical patient END gain fraction (fraction of blood peril base) ---
const GAIN_MEDICAL_PATIENT_END_MULT: float = 0.5
const GAIN_DIRECT_PRESSURE_PATIENT_END_MULT: float = 0.25

# --- Direct pressure INT gain fraction (fraction of medical action base) ---
const GAIN_DIRECT_PRESSURE_INT_MULT: float = 0.8

# --- Severity multipliers for severe wound STR gain ---
const SEVERITY_MULT: Dictionary = {
	"minor": 0.5,
	"moderate": 1.0,
	"severe": 1.5,
	"critical": 2.0,
}

# --- Item type multipliers for medical INT gain ---
const MEDICAL_ITEM_MULT: Dictionary = {
	"bandage": 0.8,
	"pack": 1.2,
	"tourniquet": 1.5,
}


## Called during combat  -  adds to proficiency bonus with diminishing returns and weapon-form modifiers.
static func award_stat_gain(entity: CoreEntity, stat: String, raw_amount: float, weapon_id: String = "", form_str: String = "") -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null or not "_proficiency_bonus" in entity:
		return
	if not _is_valid_stat(stat):
		return

	# Use Variant access to avoid GDScript 4 typed-dictionary member issues.
	var ce := entity as CoreEntity
	var prof_dict: Dictionary = ce._proficiency_bonus
	var current_bonus: float = 0.0
	if stat in prof_dict:
		current_bonus = maxf(0.0, float(prof_dict[stat]))
	else:
		current_bonus = 0.0
	var gain_mult: float = _get_gain_multiplier_for_float(current_bonus)
	var modified_amount: float = raw_amount * gain_mult

	# Apply stance/form modifier (derived from form pressure class)
	if not form_str.is_empty():
		var stance_mods := stance_mods_for_form(form_str)
		if stance_mods.has(stat):
			modified_amount *= float(stance_mods[stat])

	var wid: String = normalize_weapon_id(weapon_id)
	if not wid.is_empty() and WEAPON_CURVES.has(wid):
		var weapon_mods: Dictionary = WEAPON_CURVES[wid]
		if weapon_mods.has(stat):
			modified_amount *= float(weapon_mods[stat])

	var new_bonus: float = current_bonus + modified_amount
	prof_dict[stat] = new_bonus


## Like award_stat_gain but without stance_mods lookup — for cognitive stats where form-dependent modifiers don't apply.
static func award_stat_gain_raw(entity: CoreEntity, stat: String, raw_amount: float) -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null or not "_proficiency_bonus" in entity:
		return
	if not _is_valid_stat(stat):
		return
	var prof_dict: Dictionary = entity._proficiency_bonus
	var current_bonus: float = 0.0
	if stat in prof_dict:
		current_bonus = maxf(0.0, float(prof_dict[stat]))
	else:
		current_bonus = 0.0
	var gain_mult: float = _get_gain_multiplier_for_float(current_bonus)
	entity._proficiency_bonus[stat] = current_bonus + raw_amount * gain_mult


static func normalize_weapon_id(weapon_id: String) -> String:
	return str(weapon_id).to_upper().strip_edges()


static func normalize_form_id(form: String) -> String:
	return _WeaponForm.normalize_form(form)


static func weapon_proficiency_value(entity: CoreEntity, weapon_id: String) -> float:
	if entity == null or not "_weapon_proficiency" in entity:
		return 0.0
	var wp_dict: Dictionary = entity._weapon_proficiency
	var wp_key: String = normalize_weapon_id(weapon_id)
	if wp_key in wp_dict:
		return float(wp_dict[wp_key])
	return 0.0


static func form_proficiency_value(entity: CoreEntity, form: String) -> float:
	if entity == null or not "_form_proficiency" in entity:
		return 0.0
	var fp_dict: Dictionary = entity._form_proficiency
	var fp_key: String = normalize_form_id(form)
	if fp_key in fp_dict:
		return float(fp_dict[fp_key])
	return 0.0


static func weapon_proficiency_tier(entity: CoreEntity, weapon_id: String) -> float:
	return clampf(weapon_proficiency_value(entity, weapon_id) / WEAPON_PROF_VETERAN_MAX, 0.0, 1.0)


static func form_proficiency_tier(entity: CoreEntity, form: String) -> float:
	return clampf(form_proficiency_value(entity, form) / FORM_PROF_VETERAN_MAX, 0.0, 1.0)


static func combined_aim_prof_tier(entity: CoreEntity, weapon_id: String, form: String) -> float:
	return clampf((weapon_proficiency_tier(entity, weapon_id) + form_proficiency_tier(entity, form)) * 0.5, 0.0, 1.0)


static func proficiency_occurrence_mult(
	entity: CoreEntity, weapon_id: String, form: String, move_id: String
) -> float:
	if entity == null:
		return 1.0
	var wt: float = weapon_proficiency_tier(entity, weapon_id)
	var ft: float = form_proficiency_tier(entity, form)
	var sig: float = _WeaponForm.action_weight_mult(normalize_form_id(form), move_id, weapon_id)
	var boost: float = 1.0 + wt * 0.12 + ft * 0.08
	if sig > 1.05:
		boost += (sig - 1.0) * ft * 0.35
	return clampf(boost, 1.0, PROF_OCCURRENCE_MULT_MAX)


static func proficiency_aim_part_mult(entity: CoreEntity, weapon_id: String, form: String) -> float:
	if entity == null:
		return 1.0
	var tier: float = combined_aim_prof_tier(entity, weapon_id, form)
	return lerpf(1.0, PROF_AIM_MULT_MAX, tier)


static func intended_part_boost_mult(entity: CoreEntity, weapon_id: String, form: String) -> float:
	if entity == null:
		return PROF_INTENDED_PART_BOOST_MIN
	return lerpf(PROF_INTENDED_PART_BOOST_MIN, PROF_INTENDED_PART_BOOST_MAX, combined_aim_prof_tier(entity, weapon_id, form))


static func award_weapon_proficiency(entity: CoreEntity, weapon_id: String, raw_amount: float) -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null or not "_weapon_proficiency" in entity:
		return
	var wid: String = normalize_weapon_id(weapon_id)
	if wid.is_empty():
		return
	var current: float = weapon_proficiency_value(entity, wid)
	var gain_mult: float = _get_gain_multiplier_for_float(current)
	entity._weapon_proficiency[wid] = current + raw_amount * gain_mult


static func award_form_proficiency(entity: CoreEntity, form: String, raw_amount: float) -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null or not "_form_proficiency" in entity:
		return
	var fid: String = normalize_form_id(form)
	if fid.is_empty():
		return
	var current: float = form_proficiency_value(entity, fid)
	var gain_mult: float = _get_gain_multiplier_for_float(current)
	entity._form_proficiency[fid] = current + raw_amount * gain_mult


## Strike-time targeting proficiency: PER on off-focus, INT on preferred part, weapon/form track.
static func notify_targeting_gains_from_hit(
	entity: CoreEntity,
	weapon_id: String,
	form_str: String,
	move_def: Dictionary,
	hit_part: String,
	intended_part: String,
	defender_focus_part: String
) -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null:
		return
	award_weapon_proficiency(entity, weapon_id, GAIN_WEAPON_PROF_HIT_BASE)
	if not form_str.is_empty():
		award_form_proficiency(entity, form_str, GAIN_FORM_PROF_HIT_BASE)
	var preferred: Array = []
	if "preferred_parts" in move_def and move_def["preferred_parts"] is Array:
		preferred = move_def["preferred_parts"] as Array
	if not intended_part.is_empty() and hit_part == intended_part:
		if not preferred.is_empty() and preferred.has(hit_part):
			award_stat_gain_raw(entity, "intelligence", GAIN_PREFERRED_PART_INT_BASE)
	if (
		not defender_focus_part.is_empty()
		and not intended_part.is_empty()
		and intended_part != defender_focus_part
		and hit_part == intended_part
	):
		award_stat_gain_raw(entity, "perception", GAIN_OFF_FOCUS_HIT_PER_BASE)


## Called between contracts  -  applies decay for inactive mercenaries using calendar days.
static func apply_decay(entity: CoreEntity, current_day_index: int) -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null or not "_proficiency_bonus" in entity:
		return

	var last_fought: int = 0
	if "last_fought_day" in entity:
		last_fought = int(entity.last_fought_day)
	elif "_last_fought_day" in entity:
		last_fought = int(entity.get("_last_fought_day"))
	if last_fought == 0:
		return  # Never fought  -  no combat bonuses to decay yet
	var inactive_days: int = current_day_index - last_fought
	if inactive_days <= 0:
		return

	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		var prof_dict: Dictionary = entity._proficiency_bonus
		var bonus: float = 0.0
		if stat in prof_dict:
			bonus = float(prof_dict[stat])
		if bonus <= 10.0:
			continue  # Only decay above proficient baseline

		var decay_mult: float = get_decay_multiplier(stat)
		var rate: float = _get_decay_rate_for_bonus(bonus)
		var daily_decay: float = rate * decay_mult

		# Wounded mercenary protection: decay x0.5 if below 40% blood volume.
		var bv: float = 100.0
		if "blood_volume" in entity:
			bv = float(entity.blood_volume)
		elif entity.has_method("get_blood_volume"):
			bv = float(entity.get_blood_volume())
		if bv < 40.0:
			daily_decay *= 0.5

		var new_bonus: float = maxf(0.0, bonus + daily_decay * inactive_days)
		entity._proficiency_bonus[stat] = new_bonus

## Called during camp drill  -  merges pending training into proficiency bonus.
static func merge_training_pending(entity: CoreEntity) -> void:
	if not _get_company_state().read_stub_proficiency_enabled():
		return
	if entity == null or not entity.has_method("get_training_pending"):
		return

	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		var tp_dict: Dictionary = entity.get_training_pending()
		var pending: float = 0.0
		if stat in tp_dict:
			pending = float(tp_dict[stat])
		if pending > 0.0:
			var prof_dict: Dictionary = entity._proficiency_bonus
			var current: float = 0.0
			if stat in prof_dict:
				current = float(prof_dict[stat])
			entity._proficiency_bonus[stat] = current + pending
			entity.set_training_pending_value(stat, 0.0)



## Returns the gain rate multiplier for current proficiency level (float version  -  no truncation).
static func _get_gain_multiplier_for_float(proficiency_bonus: float) -> float:
	if proficiency_bonus <= float(PROFICIENCY_NOVICE_MAX):
		return 1.0
	if proficiency_bonus <= float(PROFICIENCY_PROFICIENT_MAX):
		return 0.7
	if proficiency_bonus <= float(PROFICIENCY_VETERAN_MAX):
		return 0.4
	if proficiency_bonus <= float(PROFICIENCY_ELITE_MAX):
		return 0.2
	return 0.1


## Returns the per-stat decay multiplier based on real-world research.
static func get_decay_multiplier(stat: String) -> float:
	match stat:
		"endurance":
			return DECAY_MULT_END
		"agility":
			return DECAY_MULT_AGI
		"perception":
			return DECAY_MULT_PER
		"strength":
			return DECAY_MULT_STR
		"intelligence":
			return DECAY_MULT_INT
	return 1.0




## Returns the medical item type multiplier for INT gain.
static func get_medical_item_mult(item_type: String) -> float:
	if item_type in MEDICAL_ITEM_MULT:
		return float(MEDICAL_ITEM_MULT[item_type])
	return 1.0


## Returns the severity multiplier for wound-based STR gain.
static func get_severity_mult(severity: String) -> float:
	if severity in SEVERITY_MULT:
		return float(SEVERITY_MULT[severity])
	return 1.0


# --- Internal helpers ---

## Safe dictionary-get helper — avoids GDScript `or` bug (GDScript `a or b` returns bool, not first truthy value).
## Usage instead of: `float(dict.get(key, 0) or 0)` → `get_float_or_zero(dict, key)`
static func get_float_or_zero(d: Dictionary, key: Variant) -> float:
	var v = d.get(key, null)
	if v != null:
		return float(v)
	return 0.0

static func _is_valid_stat(stat: String) -> bool:
	return stat in ["strength", "agility", "intelligence", "endurance", "perception"]


static func _get_decay_rate_for_bonus(bonus: float) -> float:
	if bonus <= DECAY_THRESHOLD_NOVICE_MAX:
		return DECAY_RATE_NOVICE_PLUS
	if bonus <= DECAY_THRESHOLD_PROFICIENT_MAX:
		return DECAY_RATE_PROFICIENT_PLUS
	if bonus <= DECAY_THRESHOLD_VETERAN_MAX:
		return DECAY_RATE_VETERAN_PLUS
	return DECAY_RATE_ELITE_PLUS
