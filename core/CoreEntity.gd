extends Node2D

class_name CoreEntity

# BleedingConstants is class_name in core/_Bleeding.gd; preload for linter/standalone parse
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _Healing := preload("res://core/HealingConstants.gd")

@export var species: Resource = null

# Sharp (cutting) and blunt health per body part (tissue). Bone is separate; severance when tissue 0 and bone 0.
var body_cutting: Dictionary = {}
var body_blunt: Dictionary = {}
var body_max: Dictionary = {}
var bone_health: Dictionary = {}
var bone_max: Dictionary = {}
var strength: int = 0
var speed: int = 0
# Attacking arm: which hand is dominant and offhand effectiveness (0.6–1.0).
var dominant_hand: String = "right_arm"
var offhand_functionality: float = 0.8
# One armor piece per body part (e.g. chest -> Cuirass with plate + gambeson layers).
var armor_slots: Dictionary = {}  # body_part (String) -> ArmorPiece
# Optional equipped weapon (Weapon instance from template). Null = unarmed.
var weapon = null

# Wound tracking and bleeding (injury-based). Body parts: head, chest, right_arm, left_arm, right_leg, left_leg.
# wounds[part] = Array of injury dicts: { injury_type, severity, damage, sub_region, base_bleeding_rate, current_bleeding_rate, is_stabilized }
var wounds: Dictionary = {}  # part (String) -> Array of Dictionary
var blood_volume: float = 100.0  # 0–100; death below _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD

signal died

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

func _get_body_part_list() -> Array:
	if species != null and "BODY_PARTS" in species:
		return species.BODY_PARTS.duplicate()
	return ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]

func _get_vital_parts() -> Array:
	if species != null and "VITAL_PARTS" in species:
		return species.VITAL_PARTS.duplicate()
	return ["head", "chest"]

# Part is targetable until severed (cutting 0 and bone 0) or crushed (blunt 0 and bone 0).
func get_targetable_parts() -> Array:
	var out: Array = []
	for part in _get_body_part_list():
		if _is_part_destroyed(part):
			continue
		if body_cutting.get(part, 0) > 0 or body_blunt.get(part, 0) > 0:
			out.append(part)
	return out

func _is_part_severed(part: String) -> bool:
	return body_cutting.get(part, 0) <= 0 and bone_health.get(part, 0) <= 0

func _is_part_crushed(part: String) -> bool:
	return body_blunt.get(part, 0) <= 0 and bone_health.get(part, 0) <= 0

func _is_part_destroyed(part: String) -> bool:
	return _is_part_severed(part) or _is_part_crushed(part)

# Broken = bone_health <= 0 (complete fracture). Fractured = bone damaged but > 0 (partial/hairline).
func is_bone_fractured(part: String) -> bool:
	return bone_health.get(part, 0) <= 0

func is_bone_broken(part: String) -> bool:
	return bone_health.get(part, 0) <= 0

# Bone functionality factor 0.0–1.0 from research: broken=0%; severe fracture (~0–25% bone left)~15%;
# fracture (25–50%)~40%; mild (50–75%)~70%; near full (75–100%)~95%. Hip/lower-limb studies: <50% regain
# pre-fracture mobility; arm/wrist: substantial strength loss. Tiers chosen to match that.
func get_bone_functionality_factor(part: String) -> float:
	var cur: int = bone_health.get(part, 0)
	var mx: int = bone_max.get(part, 1)
	if mx <= 0:
		return 0.0
	if cur <= 0:
		return 0.0
	var ratio: float = float(cur) / float(mx)
	if ratio <= 0.25:
		return 0.15
	if ratio <= 0.5:
		return 0.40
	if ratio <= 0.75:
		return 0.70
	if ratio < 1.0:
		return 0.92
	return 1.0

func is_part_severed(part: String) -> bool:
	return _is_part_severed(part)

func _get_offhand() -> String:
	return "left_arm" if dominant_hand == "right_arm" else "right_arm"

func is_arm_destroyed(part: String) -> bool:
	if part != "right_arm" and part != "left_arm":
		return true
	if _is_part_destroyed(part):
		return true
	return body_cutting.get(part, 0) <= 0 or body_blunt.get(part, 0) <= 0

# Tissue-based functionality (0–1): remaining cutting+blunt vs max. Arms only.
func _get_arm_tissue_factor(part: String) -> float:
	if part != "right_arm" and part != "left_arm":
		return 0.0
	var max_per_type: int = body_max.get(part, 0)
	if max_per_type <= 0:
		return 0.0
	var combined_max: float = float(max_per_type * 2)
	var remaining: float = float(body_cutting.get(part, 0) + body_blunt.get(part, 0))
	return clampf(remaining / combined_max, 0.0, 1.0)

# Arm functionality = tissue factor × bone factor. Broken bone = 0%; fractured = severely reduced (research-based).
func get_arm_functionality(part: String) -> float:
	if part != "right_arm" and part != "left_arm":
		return 0.0
	if _is_part_destroyed(part):
		return 0.0
	var tissue: float = _get_arm_tissue_factor(part)
	var bone_factor: float = get_bone_functionality_factor(part)
	return clampf(tissue * bone_factor, 0.0, 1.0)

# Leg functionality for mobility/speed: min of both legs (both needed for gait). Bone factor only (tissue damage
# already limits part; we use bone for "can this leg bear weight / move?"). Research: <50% hip-fracture patients
# regain pre-fracture mobility; broken leg → near 0% effective mobility.
func get_leg_functionality() -> float:
	var left: float = get_bone_functionality_factor("left_leg")
	var right: float = get_bone_functionality_factor("right_leg")
	# If either leg is broken, mobility is severely limited (e.g. hopping/crutch).
	if left <= 0.0 or right <= 0.0:
		return 0.08
	# Both legs damaged: use geometric mean so two bad legs = very low; one good one bad = moderate.
	return sqrt(left * right)

# Effective speed for gauge fill / mobility: base speed × leg functionality (research: leg fracture → major mobility loss).
func get_effective_speed() -> int:
	var leg: float = get_leg_functionality()
	return maxi(1, int(roundf(float(speed) * leg)))

# Which arm is used to hold and attack with the weapon. Effectively swaps to the offhand when the
# dominant arm is injured or destroyed and the offhand would be more effective (by effective damage).
func get_attacking_arm() -> String:
	var offhand: String = _get_offhand()
	var dom_ok: bool = not is_arm_destroyed(dominant_hand)
	var off_ok: bool = not is_arm_destroyed(offhand)
	if not dom_ok and not off_ok:
		return ""
	if dom_ok and not off_ok:
		return dominant_hand
	if off_ok and not dom_ok:
		return offhand
	# Both usable: use whichever arm gives higher effective damage (swap to offhand if it's better).
	var dom_eff: float = get_arm_functionality(dominant_hand) * 1.0
	var off_eff: float = get_arm_functionality(offhand) * offhand_functionality
	return dominant_hand if dom_eff >= off_eff else offhand

func get_attack_damage_modifier() -> float:
	var arm := get_attacking_arm()
	if arm.is_empty():
		return 0.0
	var base: float = 1.0 if arm == dominant_hand else offhand_functionality
	return base * get_arm_functionality(arm)

func get_armor_for_part(part: String) -> Variant:
	return armor_slots.get(part, null)

func get_armor_slots() -> Dictionary:
	return armor_slots.duplicate()

func equip_armor(part: String, piece: Variant) -> void:
	if part.is_empty():
		return
	if piece == null:
		armor_slots.erase(part)
		return
	if not (piece is ArmorPiece):
		return
	if piece.body_part != part:
		return
	armor_slots[part] = piece

func get_weapon():
	return weapon

func equip_weapon(w) -> void:
	weapon = w

func is_dead() -> bool:
	if blood_volume <= _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD:
		return true
	for part in _get_vital_parts():
		if _is_part_destroyed(part):
			return true
		if body_cutting.get(part, 0) <= 0 or body_blunt.get(part, 0) <= 0:
			return true
	return false

# Returns a short string describing why this entity is dead (for combat/debug logging). Call only when is_dead() is true.
func get_death_reason() -> String:
	if blood_volume <= _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD:
		return "blood_loss (volume=%.1f <= threshold %.1f)" % [blood_volume, _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD]
	for part in _get_vital_parts():
		if _is_part_destroyed(part):
			return "vital_part_destroyed (%s severed/crushed)" % part
		var cut: int = body_cutting.get(part, 0)
		var blunt: int = body_blunt.get(part, 0)
		if cut <= 0 or blunt <= 0:
			return "vital_part_zero (%s cut=%d blunt=%d)" % [part, cut, blunt]
	return "unknown"

# Optional penetration (mm RHA sharp, MPa blunt). If < 0, defaults are used when armor is present.
# Damage above BONE_DAMAGE_THRESHOLD splits: fraction to bone (fracture/break); rest to tissue. Severance when tissue 0 and bone 0.
# Returns { "final_type": SHARP/BLUNT, "final_amount": int } so caller can report the correct pool (e.g. when armor deflects sharp->blunt).
func take_damage(amount: int, part: String, damage_type: String = DAMAGE_TYPE_BLUNT, penetration_sharp: float = -1.0, penetration_blunt: float = -1.0) -> Dictionary:
	if part not in body_cutting or part not in body_blunt or part not in bone_health:
		return { "final_type": damage_type, "final_amount": 0 }
	var final_amount: int = amount
	var final_type: String = damage_type
	var armor: Variant = get_armor_for_part(part)
	if armor != null and armor is ArmorPiece:
		var pen_s: float = penetration_sharp if penetration_sharp >= 0.0 else ArmorConstants.DEFAULT_PENETRATION_SHARP
		var pen_b: float = penetration_blunt if penetration_blunt >= 0.0 else ArmorConstants.DEFAULT_PENETRATION_BLUNT
		var result: Dictionary = armor.apply_damage(float(amount), damage_type, pen_s, pen_b)
		final_amount = int(roundf(result.get("damage", float(amount))))
		final_type = result.get("damage_type", damage_type)
	var to_tissue: int = final_amount
	var to_bone: int = 0
	var bone_threshold: int = BodyPartConstants.get_bone_damage_threshold(part)
	var bone_fraction: float = BodyPartConstants.get_bone_damage_fraction(part)
	var bone_min: int = BodyPartConstants.get_bone_damage_min(part)
	if final_amount >= bone_threshold:
		# Fraction applies to damage above threshold (SUB_REGIONS_MEDICAL_SOURCES §8).
		var excess: int = final_amount - bone_threshold
		to_bone = maxi(bone_min, int(roundf(float(excess) * bone_fraction)))
		to_tissue = final_amount - to_bone
	if final_type == DAMAGE_TYPE_SHARP:
		body_cutting[part] = max(0, body_cutting[part] - to_tissue)
	else:
		body_blunt[part] = max(0, body_blunt[part] - to_tissue)
	bone_health[part] = max(0, bone_health[part] - to_bone)
	var vital := _get_vital_parts()
	if part in vital and (body_cutting.get(part, 0) <= 0 or body_blunt.get(part, 0) <= 0):
		emit_signal("died")
	return { "final_type": final_type, "final_amount": final_amount }


# Split damage: apply cut (SHARP) and blunt (BLUNT) streams; sharp deflected -> blunt. Bone split from total (Option B).
# Returns { "final_cut": int, "final_blunt": int } = tissue amounts applied to each pool.
func take_damage_split(cut_pre: float, blunt_pre: float, part: String, penetration_sharp: float = -1.0, penetration_blunt: float = -1.0) -> Dictionary:
	if part not in body_cutting or part not in body_blunt or part not in bone_health:
		return { "final_cut": 0, "final_blunt": 0 }
	var cut_pre_val: float = maxf(0.0, cut_pre)
	var blunt_pre_val: float = maxf(0.0, blunt_pre)
	var armor_var: Variant = get_armor_for_part(part)
	var pen_s: float = penetration_sharp if penetration_sharp >= 0.0 else ArmorConstants.DEFAULT_PENETRATION_SHARP
	var pen_b: float = penetration_blunt if penetration_blunt >= 0.0 else ArmorConstants.DEFAULT_PENETRATION_BLUNT

	var final_cut: float = 0.0
	var final_blunt: float = 0.0
	if armor_var != null and armor_var is ArmorPiece:
		if cut_pre_val > 0.0:
			var result_cut: Dictionary = armor_var.apply_damage(cut_pre_val, DAMAGE_TYPE_SHARP, pen_s, pen_b)
			var d: float = maxf(0.0, result_cut.get("damage", 0.0))
			var dtype: String = result_cut.get("damage_type", DAMAGE_TYPE_SHARP)
			if dtype == DAMAGE_TYPE_SHARP:
				final_cut += d
			else:
				final_blunt += d
		if blunt_pre_val > 0.0:
			var result_blunt: Dictionary = armor_var.apply_damage(blunt_pre_val, DAMAGE_TYPE_BLUNT, 0.0, pen_b)
			final_blunt += maxf(0.0, result_blunt.get("damage", 0.0))
		print("[Damage apply] %s %s: armor on | pre cut=%.1f blunt=%.1f pen_s=%.2f pen_b=%.2f => post cut=%.1f blunt=%.1f" % [name, part, cut_pre_val, blunt_pre_val, pen_s, pen_b, final_cut, final_blunt])
	else:
		final_cut = cut_pre_val
		final_blunt = blunt_pre_val
		if cut_pre_val > 0.0 or blunt_pre_val > 0.0:
			print("[Damage apply] %s %s: no armor | pre cut=%.1f blunt=%.1f => tissue cut=%.1f blunt=%.1f" % [name, part, cut_pre_val, blunt_pre_val, final_cut, final_blunt])

	var total_final: float = final_cut + final_blunt
	if total_final <= 0.0:
		return { "final_cut": 0, "final_blunt": 0 }

	# 2) Sub-region is chosen relative to the body part already hit: weighted random over this part's sub-regions only (SUB_REGION_WEIGHTS[part]).
	var sub_region: String = _Bleeding.get_random_sub_region(part)

	var to_tissue_total: int = int(roundf(total_final))
	var to_bone: int = 0
	var bone_threshold: int = BodyPartConstants.get_bone_damage_threshold(part, sub_region)
	var bone_fraction: float = BodyPartConstants.get_bone_damage_fraction(part, sub_region)
	var bone_min: int = BodyPartConstants.get_bone_damage_min(part)
	if to_tissue_total >= bone_threshold:
		# Fraction applies to damage above threshold (SUB_REGIONS_MEDICAL_SOURCES §8).
		var excess: int = to_tissue_total - bone_threshold
		to_bone = maxi(bone_min, int(roundf(float(excess) * bone_fraction)))
		to_tissue_total = maxi(0, int(roundf(total_final)) - to_bone)
	var total_tissue: float = float(to_tissue_total)
	var to_cut: int = 0
	var to_blunt: int = 0
	if total_final > 0.0:
		to_cut = int(roundf(total_tissue * (final_cut / total_final)))
		to_blunt = maxi(0, to_tissue_total - to_cut)
	print("[Damage apply] %s %s (%s): bone threshold=%d fraction=%.2f => to_bone=%d to_tissue=%d (cut=%d blunt=%d)" % [name, part, sub_region, bone_threshold, bone_fraction, to_bone, to_tissue_total, to_cut, to_blunt])
	body_cutting[part] = max(0, body_cutting[part] - to_cut)
	body_blunt[part] = max(0, body_blunt[part] - to_blunt)
	bone_health[part] = max(0, bone_health[part] - to_bone)
	# Wound tracking: add injuries for bleeding (cut and crush); same sub_region for this hit
	if to_cut > 0:
		_add_wound(part, _Bleeding.INJURY_TYPE_CUT, to_cut, sub_region)
	if to_blunt > 0:
		_add_wound(part, _Bleeding.INJURY_TYPE_CRUSH, to_blunt, sub_region)
	var vital := _get_vital_parts()
	if part in vital and (body_cutting.get(part, 0) <= 0 or body_blunt.get(part, 0) <= 0):
		emit_signal("died")
	return { "final_cut": to_cut, "final_blunt": to_blunt }


# --- Wound and bleeding (injury-based) ---

func _severity_from_damage(part: String, damage: float, sub_region: String = "") -> String:
	var max_hp: float = float(body_max.get(part, 10))
	if max_hp <= 0.0:
		return _Bleeding.SEVERITY_MODERATE
	var effective_damage: float = damage * _Bleeding.get_severity_modifier(part, sub_region)
	var pct: float = effective_damage / max_hp
	var sev_pct: String = _Bleeding.SEVERITY_MINOR
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_CRITICAL:
		sev_pct = _Bleeding.SEVERITY_CRITICAL
	elif pct >= _Bleeding.SEVERITY_PERCENTAGE_SEVERE:
		sev_pct = _Bleeding.SEVERITY_SEVERE
	elif pct >= _Bleeding.SEVERITY_PERCENTAGE_MODERATE:
		sev_pct = _Bleeding.SEVERITY_MODERATE
	var sev_abs: String = _Bleeding.SEVERITY_MINOR
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_CRITICAL:
		sev_abs = _Bleeding.SEVERITY_CRITICAL
	elif effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_SEVERE:
		sev_abs = _Bleeding.SEVERITY_SEVERE
	elif effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_MINOR:
		sev_abs = _Bleeding.SEVERITY_MODERATE
	var order: Array = [_Bleeding.SEVERITY_MINOR, _Bleeding.SEVERITY_MODERATE, _Bleeding.SEVERITY_SEVERE, _Bleeding.SEVERITY_CRITICAL]
	var i_pct: int = order.find(sev_pct)
	var i_abs: int = order.find(sev_abs)
	return order[maxi(i_pct, i_abs)]

func _add_wound(part: String, injury_type: String, damage: float, sub_region: String = "") -> void:
	if part.is_empty() or damage <= 0.0:
		return
	var severity: String = _severity_from_damage(part, damage, sub_region)
	var base_rate: float = _Bleeding.get_bleeding_rate(injury_type, severity, part, sub_region)
	if base_rate <= 0.0:
		return
	var is_arterial: bool = randf() < _Bleeding.get_arterial_chance(severity, injury_type, part, sub_region)
	if is_arterial:
		base_rate *= _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	if wounds.get(part) == null:
		wounds[part] = []
	var injury: Dictionary = {
		"injury_type": injury_type,
		"severity": severity,
		"damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": base_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial
	}
	wounds[part].append(injury)

func get_total_bleeding_rate() -> float:
	var total: float = 0.0
	for part in wounds:
		var list: Array = wounds[part]
		for injury in list:
			total += injury.get("current_bleeding_rate", 0.0)
	return total

func get_wounds() -> Dictionary:
	return wounds.duplicate(true)

func process_bleeding(delta: float) -> void:
	for part in wounds.keys():
		var list: Array = wounds[part]
		var i: int = list.size() - 1
		while i >= 0:
			var injury: Dictionary = list[i]
			var rate: float = injury.get("current_bleeding_rate", 0.0)
			var clotting: float
			if injury.get("is_stabilized", false):
				clotting = _Bleeding.CLOTTING_RATE_STABILIZED
			else:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
				clotting = _Bleeding.get_clotting_rate(sev)
				# Arterial wounds: pressure inhibits clotting; clot very slowly.
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
			# Exponential decay of bleeding rate (rate ∝ current rate); first-order kinetics. See RESEARCH_BASED_APPROXIMATIONS.md.
			rate = rate * exp(-clotting * delta)
			rate = maxf(0.0, rate)
			injury["current_bleeding_rate"] = rate
			if rate <= 0.0:
				list.remove_at(i)
			i -= 1
		if list.is_empty():
			wounds.erase(part)

func process_blood_loss(delta: float) -> void:
	var total: float = get_total_bleeding_rate()
	if total <= 0.0:
		return
	var loss: float = total * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER * delta
	blood_volume = maxf(0.0, blood_volume - loss)
	if blood_volume <= _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD:
		emit_signal("died")

func apply_bandage(part: String, effectiveness: float = 1.0) -> void:
	if part.is_empty() or not wounds.has(part):
		return
	effectiveness = clampf(effectiveness, 0.0, 1.0)
	for injury in wounds[part]:
		var eff: float = effectiveness
		if injury.get("is_arterial", false):
			eff *= _Bleeding.BANDAGE_ARTERIAL_EFFECTIVENESS_MULT
		var reduction: float = _Bleeding.BANDAGE_IMMEDIATE_REDUCTION * eff
		var rate: float = injury.get("current_bleeding_rate", 0.0)
		injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - reduction))
		injury["is_stabilized"] = true
		if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
			injury["stabilized_remaining_seconds"] = _Bleeding.BANDAGE_STABILIZATION_DURATION

# Healing: exponential deficit decay (tissue, bone, blood). Duration = time to ~95% healed. Call on time advance.
# Also decays bandage stabilization timer; when it hits 0, is_stabilized reverts to false.
func process_healing(seconds: float) -> void:
	if seconds <= 0.0:
		return
	# Bandage stabilization expiry: subtract time from stabilized_remaining_seconds; clear is_stabilized when expired.
	if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
		for part in wounds.keys():
			for injury in wounds[part]:
				if injury.get("stabilized_remaining_seconds", 0.0) > 0.0:
					var rem: float = injury["stabilized_remaining_seconds"] - seconds
					injury["stabilized_remaining_seconds"] = maxf(0.0, rem)
					if rem <= 0.0:
						injury["is_stabilized"] = false
						injury.erase("stabilized_remaining_seconds")
	for part in _get_body_part_list():
		if part not in body_max or part not in bone_max:
			continue
		var max_tissue: int = body_max.get(part, 0)
		var max_bone: int = bone_max.get(part, 0)
		if max_tissue <= 0:
			continue
		# Worst wound severity on this part sets tissue heal duration (medical realism)
		var severity: String = _Bleeding.SEVERITY_MINOR
		if wounds.has(part) and wounds[part].size() > 0:
			var order: Array = [_Bleeding.SEVERITY_MINOR, _Bleeding.SEVERITY_MODERATE, _Bleeding.SEVERITY_SEVERE, _Bleeding.SEVERITY_CRITICAL]
			for injury in wounds[part]:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MINOR)
				if order.find(sev) > order.find(severity):
					severity = sev
		var tissue_duration: float = _Healing.get_tissue_heal_duration_seconds(part, severity)
		if tissue_duration <= 0.0:
			tissue_duration = _Healing.SECONDS_PER_DAY * 4.0
		# Tissue: exponential healing (deficit *= exp(-t/τ)); rate ∝ current deficit. See RESEARCH_BASED_APPROXIMATIONS.md.
		var cur_cut: int = body_cutting.get(part, 0)
		var cur_blunt: int = body_blunt.get(part, 0)
		var remain_cut: float = float(max_tissue - cur_cut)
		var remain_blunt: float = float(max_tissue - cur_blunt)
		var tau_tissue: float = tissue_duration / _Healing.EXPONENTIAL_HEAL_TAU_DIVISOR
		var add_cut: float = remain_cut * (1.0 - exp(-seconds / tau_tissue))
		var add_blunt: float = remain_blunt * (1.0 - exp(-seconds / tau_tissue))
		body_cutting[part] = mini(max_tissue, cur_cut + int(roundf(add_cut)))
		body_blunt[part] = mini(max_tissue, cur_blunt + int(roundf(add_blunt)))
		# Bone: exponential healing toward max (6 weeks duration)
		var bone_duration: float = _Healing.get_bone_heal_duration_seconds(part)
		if bone_duration <= 0.0:
			bone_duration = _Healing.BONE_HEAL_DURATION_SECONDS
		var cur_bone: int = bone_health.get(part, 0)
		var remain_bone: float = float(max_bone - cur_bone)
		var tau_bone: float = bone_duration / _Healing.EXPONENTIAL_HEAL_TAU_DIVISOR
		var bone_heal: float = remain_bone * (1.0 - exp(-seconds / tau_bone))
		bone_health[part] = mini(max_bone, cur_bone + int(roundf(bone_heal)))
	# Blood volume recovery when not bleeding: exponential (deficit ∝ current deficit). Body replenishes over ~24 h.
	if get_total_bleeding_rate() <= 0.0:
		var remain_blood: float = _Bleeding.MAX_BLOOD_VOLUME - blood_volume
		if remain_blood > 0.0:
			var tau_blood: float = _Healing.BLOOD_VOLUME_RECOVERY_DURATION_SECONDS / _Healing.EXPONENTIAL_HEAL_TAU_DIVISOR
			var add_blood: float = remain_blood * (1.0 - exp(-seconds / tau_blood))
			blood_volume = minf(_Bleeding.MAX_BLOOD_VOLUME, blood_volume + add_blood)

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
	blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	if species != null:
		for p in _get_body_part_list():
			var m = species.get_body_part_max(p) if species.has_method("get_body_part_max") else 10
			var b = species.get_bone_max(p) if species.has_method("get_bone_max") else maxi(1, m / 2)
			body_max[p] = m
			body_cutting[p] = m
			body_blunt[p] = m
			bone_max[p] = b
			bone_health[p] = b
		strength = species.strength
		speed = species.speed
		dominant_hand = ["right_arm", "left_arm"][randi() % 2]
		offhand_functionality = randf_range(0.6, 1.0)
		if typeof(species.name) == TYPE_STRING and species.name != "":
			self.name = species.name
	else:
		for p in _get_body_part_list():
			body_max[p] = 10
			body_cutting[p] = 10
			body_blunt[p] = 10
			bone_max[p] = 5
			bone_health[p] = 5
		strength = 1
		speed = 100
		dominant_hand = ["right_arm", "left_arm"][randi() % 2]
		offhand_functionality = randf_range(0.6, 1.0)
