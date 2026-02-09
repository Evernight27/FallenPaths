extends Node2D

class_name CoreEntity

# BleedingConstants is class_name in core/_Bleeding.gd; preload for linter/standalone parse
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _Healing := preload("res://core/HealingConstants.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")

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
# wounds[part] = Array of injury dicts. Each wound has individual healing: created_at_game_time, healing_duration_seconds.
# Pain contribution = damage × severity_mult × (1 - healing_progress); wounds are removed when progress >= WOUND_RESOLVED_THRESHOLD.
var wounds: Dictionary = {}  # part (String) -> Array of Dictionary
var blood_volume: float = 100.0  # 0–100; death below _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
# Tourniquet: limb parts only. part -> game_time when applied (for optional expiry). When set, that part's wounds do not contribute to blood loss.
var tourniquet_applied: Dictionary = {}  # part (String) -> float (game_time_seconds when applied)
# Direct pressure: part (String) the entity is currently holding pressure on; empty if not. Lasts until next action or bleeding on that part stops.
var direct_pressure_part: String = ""

# Game time (seconds) for per-wound healing and pain decay. Advanced in process_healing(seconds).
var _game_time_seconds: float = 0.0
const WOUND_RESOLVED_THRESHOLD: float = 0.95  # wound removed when healing progress >= this (~95% healed)

# Severance ease: full-health limb is hard to chop through; mangled/bone-damaged limbs give way more easily (research: MESS, limb salvage).
const SEVERANCE_EASE_MAX: float = 1.8       # max multiplier (80% more effective damage when part is critically damaged)
const SEVERANCE_EASE_TISSUE_FACTOR: float = 0.4   # (1 - tissue_ratio) contributes up to this
const SEVERANCE_EASE_BONE_FACTOR: float = 0.3    # (1 - bone_ratio) contributes up to this
const SEVERANCE_EASE_PER_WOUND: float = 0.04     # per wound on part, up to cap
const SEVERANCE_EASE_WOUND_CAP: float = 0.25    # max contribution from wound count
const SEVERANCE_EASE_SEVERITY_BONUS: Dictionary = { "minor": 0.0, "moderate": 0.05, "severe": 0.12, "critical": 0.20 }  # worst wound on part

# Early severance: when part is critically damaged but not yet at 0, one blow can finish it (complete amputation from single blow is realistic).
# Only consider when combined remaining (cut + bone) is below this fraction of max; probability scales with how low health is.
const SEVERANCE_EARLY_THRESHOLD: float = 0.18   # below 18% combined (cut + bone) remaining vs max
const SEVERANCE_EARLY_MAX_CHANCE: float = 0.65  # max roll chance when at 0% (cap)
const SEVERANCE_EARLY_LIMBS_ONLY: bool = true  # if true, only arms/legs can early-sever; head/chest still require exact 0 (death)

# Minimum total damage this hit must do to allow severance (cut through limb). Prevents dagger slices / spear stabs from severing;
# tissue can go to 0 (mangled, unusable) but limb only detaches when a blow has "force to cut through" (e.g. sword chop).
const MIN_DAMAGE_TO_SEVER: int = 4  # hits below this can reduce tissue/bone but cannot sever; leave bone at 1 if would sever

# Pain and consciousness (Combat Extended–style). Action bar and hit chance use get_performance_modifier().
var consciousness: float = 100.0       # true consciousness (incapacitation when < 10)
var effective_consciousness: float = 100.0  # for combat (after pain shock)
var _pain_shock_until_time: float = -1.0    # Time.get_ticks_msec()/1000.0 when shock ends; -1 = not in shock

signal died
signal creature_incapacitated

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
# Tissue can go to 0 without severing (bone > 0) = mangled, unusable, not targetable; only hits with MIN_DAMAGE_TO_SEVER can sever.
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
	var created: float = injury.get("created_at_game_time", -1.0)
	var duration: float = injury.get("healing_duration_seconds", 0.0)
	if created < 0.0 or duration <= 0.0:
		return 0.0
	var age: float = _game_time_seconds - created
	if age <= 0.0:
		return 0.0
	var tau: float = duration / _Healing.EXPONENTIAL_HEAL_TAU_DIVISOR
	return 1.0 - exp(-age / tau)

func get_total_pain() -> float:
	var total: float = 0.0
	for part in wounds:
		if _is_part_severed(part):
			continue  # severed part: stump wound does not add pain (part gone); bleeding still from stump in get_total_bleeding_rate.
		for injury in wounds[part]:
			var d: float = injury.get("damage", 0.0)
			var sev: String = injury.get("severity", "moderate")
			var mult: float = _PainConscious.SEVERITY_PAIN_MULTIPLIERS.get(sev, 1.0)
			var progress: float = _get_wound_healing_progress(injury)
			total += d * mult * (1.0 - progress)
	return total

func _get_blood_consciousness_modifier() -> float:
	if blood_volume >= _PainConscious.BLOOD_CONSCIOUSNESS_THRESHOLD:
		return 1.0
	var reduction: float = (_PainConscious.BLOOD_CONSCIOUSNESS_THRESHOLD - blood_volume) / _PainConscious.BLOOD_CONSCIOUSNESS_THRESHOLD
	return maxf(0.0, 1.0 - reduction * _PainConscious.BLOOD_CONSCIOUSNESS_REDUCTION_MAX)

func _update_consciousness() -> void:
	# 1) Base from head (proxy for brain)
	var head_cut: int = body_cutting.get("head", 0)
	var head_blunt: int = body_blunt.get("head", 0)
	var head_max: int = body_max.get("head", 1)
	var head_total: float = float(head_cut + head_blunt)
	var head_max_total: float = float(head_max * 2)
	var base_consciousness: float = 100.0
	if head_max_total > 0.0:
		base_consciousness = 100.0 * (head_total / head_max_total)
	# 2) Blood modifier
	base_consciousness *= _get_blood_consciousness_modifier()
	# 3) Pain reduction (subtractive)
	var total_pain: float = get_total_pain()
	var pain_reduction: float = _PainConscious.get_pain_consciousness_reduction(total_pain)
	var true_consciousness: float = maxf(0.0, base_consciousness - pain_reduction)
	consciousness = true_consciousness
	# 4) Pain shock (temporary; only affects effective for combat)
	var now: float = Time.get_ticks_msec() / 1000.0
	if _pain_shock_until_time >= 0.0 and now < _pain_shock_until_time:
		effective_consciousness = true_consciousness * (1.0 - _PainConscious.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0)
	else:
		_pain_shock_until_time = -1.0
		effective_consciousness = true_consciousness
		# Roll for shock when pain above threshold
		if total_pain > _PainConscious.PAIN_SHOCK_THRESHOLD:
			var risk: float = minf(1.0, (total_pain - _PainConscious.PAIN_SHOCK_THRESHOLD) * _PainConscious.PAIN_SHOCK_RISK_PER_POINT)
			if randf() < risk:
				var duration: float = _PainConscious.PAIN_SHOCK_DURATION_BASE * (total_pain / _PainConscious.PAIN_SHOCK_THRESHOLD)
				_pain_shock_until_time = now + duration
				effective_consciousness = true_consciousness * (1.0 - _PainConscious.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0)
	if true_consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
		emit_signal("creature_incapacitated")

func is_incapacitated() -> bool:
	"""True when consciousness is below threshold (unconscious; cannot act, counts as defeated)."""
	return consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD

func get_effective_consciousness() -> float:
	"""Consciousness used for combat (includes pain shock)."""
	return effective_consciousness

func get_performance_modifier() -> float:
	"""Combined pain × consciousness modifier for action bar fill and hit chance (min 0.35)."""
	return _PainConscious.get_combined_performance_modifier(get_total_pain(), get_effective_consciousness())

func is_dead() -> bool:
	if blood_volume <= _get_blood_loss_death_threshold():
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


# Severance ease: full-health limb resists dismemberment; already wounded/bone-damaged parts give way more easily (MESS/limb salvage research).
func _get_severance_ease_factor(part: String) -> float:
	var max_tissue: int = body_max.get(part, 1)
	var max_bone: int = bone_max.get(part, 1)
	if max_tissue <= 0 or max_bone <= 0:
		return 1.0
	var cur_cut: int = body_cutting.get(part, 0)
	var cur_blunt: int = body_blunt.get(part, 0)
	var cur_bone: int = bone_health.get(part, 0)
	var tissue_ratio: float = float(cur_cut + cur_blunt) / float(maxi(1, max_tissue * 2))
	var bone_ratio: float = float(cur_bone) / float(max_bone)
	var wound_count: int = wounds.get(part, []).size()
	var wound_factor: float = minf(float(wound_count) * SEVERANCE_EASE_PER_WOUND, SEVERANCE_EASE_WOUND_CAP)
	var worst_sev: String = _Bleeding.SEVERITY_MINOR
	for injury in wounds.get(part, []):
		var sev: String = injury.get("severity", _Bleeding.SEVERITY_MINOR)
		var order: Array = [_Bleeding.SEVERITY_MINOR, _Bleeding.SEVERITY_MODERATE, _Bleeding.SEVERITY_SEVERE, _Bleeding.SEVERITY_CRITICAL]
		if order.find(sev) > order.find(worst_sev):
			worst_sev = sev
	var severity_bonus: float = SEVERANCE_EASE_SEVERITY_BONUS.get(worst_sev, 0.0)
	var severance_ease: float = 1.0 + (1.0 - tissue_ratio) * SEVERANCE_EASE_TISSUE_FACTOR + (1.0 - bone_ratio) * SEVERANCE_EASE_BONE_FACTOR + wound_factor + severity_bonus
	return clampf(severance_ease, 1.0, SEVERANCE_EASE_MAX)

# Split damage: apply cut (SHARP) and blunt (BLUNT) streams; sharp deflected -> blunt. Bone split from total (Option B).
# Severance ease applied: same hit does more effective damage to already-mangled parts (easier to dismember).
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
		print("[Armor] %s %s: pre cut=%.1f blunt=%.1f | pen_sharp=%.2f mm RHA pen_blunt=%.1f MPa => post-armor cut=%.1f blunt=%.1f" % [name, part, cut_pre_val, blunt_pre_val, pen_s, pen_b, final_cut, final_blunt])
	else:
		final_cut = cut_pre_val
		final_blunt = blunt_pre_val
		if cut_pre_val > 0.0 or blunt_pre_val > 0.0:
			print("[Armor] %s %s: no armor => post cut=%.1f blunt=%.1f" % [name, part, final_cut, final_blunt])

	var total_final: float = final_cut + final_blunt
	if total_final <= 0.0:
		return { "final_cut": 0, "final_blunt": 0 }

	# 2) Sub-region is chosen relative to the body part already hit: weighted random over this part's sub-regions only (SUB_REGION_WEIGHTS[part]).
	var sub_region: String = _Bleeding.get_random_sub_region(part)

	# 3) Bone and tissue split: total impact (cut + blunt) can damage bone (cut through limb / chop into bone or blunt fracture). Damage above threshold splits: fraction to bone, rest to tissue (split by cut/blunt ratio).
	var to_tissue_total: int = int(roundf(total_final))
	var to_bone: int = 0
	var bone_threshold: int = BodyPartConstants.get_bone_damage_threshold(part, sub_region)
	var bone_fraction: float = BodyPartConstants.get_bone_damage_fraction(part, sub_region)
	var bone_min: int = BodyPartConstants.get_bone_damage_min(part)
	if to_tissue_total >= bone_threshold:
		var excess: int = to_tissue_total - bone_threshold
		to_bone = maxi(bone_min, int(roundf(float(excess) * bone_fraction)))
		to_tissue_total = maxi(0, int(roundf(total_final)) - to_bone)
	var total_tissue: float = float(to_tissue_total)
	var to_cut: int = 0
	var to_blunt: int = 0
	if total_final > 0.0:
		to_cut = int(roundf(total_tissue * (final_cut / total_final)))
		to_blunt = maxi(0, to_tissue_total - to_cut)
	# Severance ease: already wounded / bone-damaged parts take more effective damage (easier to dismember).
	var severance_ease: float = _get_severance_ease_factor(part)
	var cur_cut: int = body_cutting.get(part, 0)
	var cur_blunt: int = body_blunt.get(part, 0)
	var cur_bone: int = bone_health.get(part, 0)
	var allocated_bone: int = to_bone  # before cap by current bone
	to_cut = mini(int(roundf(float(to_cut) * severance_ease)), cur_cut)
	to_blunt = mini(int(roundf(float(to_blunt) * severance_ease)), cur_blunt)
	to_bone = mini(int(roundf(float(to_bone) * severance_ease)), cur_bone)
	# Small hits cannot sever: if this hit would make cutting 0 and bone 0 but total damage < MIN_DAMAGE_TO_SEVER, leave bone at 1 (mangled, not severed).
	var total_damage_this_hit: int = to_cut + to_blunt + to_bone
	if total_damage_this_hit < MIN_DAMAGE_TO_SEVER and (cur_cut - to_cut) <= 0 and (cur_bone - to_bone) <= 0 and cur_bone > 0:
		to_bone = maxi(0, cur_bone - 1)  # leave bone at 1 so part is mangled (tissue 0) but not severed
	body_cutting[part] = max(0, body_cutting[part] - to_cut)
	body_blunt[part] = max(0, body_blunt[part] - to_blunt)
	bone_health[part] = max(0, bone_health[part] - to_bone)
	var cut_after: int = body_cutting.get(part, 0)
	var blunt_after: int = body_blunt.get(part, 0)
	var bone_after: int = bone_health.get(part, 0)
	print("[Bone/tissue] %s %s (%s): total_post_armor=%.1f | threshold=%d fraction=%.2f => allocated bone=%d tissue=%d | severance_ease=%.2f => applied cut=%d blunt=%d bone=%d | part state: cut %d->%d blunt %d->%d bone %d->%d" % [name, part, sub_region, total_final, bone_threshold, bone_fraction, allocated_bone, to_tissue_total, severance_ease, to_cut, to_blunt, to_bone, cur_cut, cut_after, cur_blunt, blunt_after, cur_bone, bone_after])
	# Wound tracking: tissue (cut/crush/bruise) and bone (fracture); same sub_region for this hit
	if to_cut > 0:
		_add_wound(part, _Bleeding.INJURY_TYPE_CUT, float(to_cut), sub_region)
	if to_blunt > 0:
		_add_wound(part, _Bleeding.INJURY_TYPE_CRUSH, float(to_blunt), sub_region)
	if to_bone > 0:
		var fracture_severity: String = _severity_from_bone_damage(part, to_bone)
		_add_wound(part, _Bleeding.INJURY_TYPE_FRACTURE, float(to_bone), sub_region, fracture_severity)

	# Early severance: when part is critically damaged (low combined cut+bone), one blow with enough force can complete amputation.
	if not _is_part_severed(part) and total_damage_this_hit >= MIN_DAMAGE_TO_SEVER:
		if not SEVERANCE_EARLY_LIMBS_ONLY or part not in _get_vital_parts():
			var max_cut: int = body_max.get(part, 1)
			var max_bone: int = bone_max.get(part, 1)
			var rem_cut: int = body_cutting.get(part, 0)
			var rem_bone: int = bone_health.get(part, 0)
			var combined_max: float = float(max_cut + max_bone)
			if combined_max > 0.0:
				var remaining_ratio: float = float(rem_cut + rem_bone) / combined_max
				if remaining_ratio < SEVERANCE_EARLY_THRESHOLD and remaining_ratio > 0.0:
					var chance: float = (SEVERANCE_EARLY_THRESHOLD - remaining_ratio) / SEVERANCE_EARLY_THRESHOLD * SEVERANCE_EARLY_MAX_CHANCE
					chance = clampf(chance, 0.0, 1.0)
					if randf() < chance:
						body_cutting[part] = 0
						body_blunt[part] = 0
						bone_health[part] = 0
						print("[Severance] %s %s: early severance triggered (remaining ratio < threshold) => part destroyed" % [name, part])

	# Severed parts: replace with single stump wound (amputation site bleeds by part + level; can clot/bandage/heal).
	if _is_part_severed(part):
		wounds[part] = _create_stump_wound(part, sub_region)

	var vital := _get_vital_parts()
	if part in vital and (body_cutting.get(part, 0) <= 0 or body_blunt.get(part, 0) <= 0):
		emit_signal("died")
	_update_consciousness()
	return { "final_cut": to_cut, "final_blunt": to_blunt, "final_bone": to_bone }


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

func _severity_from_bone_damage(part: String, bone_damage: int) -> String:
	"""Severity for bone/fracture wounds: from damage vs bone_max (hairline = minor, full break = critical)."""
	var max_bone: float = float(bone_max.get(part, 1))
	if max_bone <= 0.0:
		return _Bleeding.SEVERITY_MODERATE
	var pct: float = float(bone_damage) / max_bone
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_CRITICAL:
		return _Bleeding.SEVERITY_CRITICAL
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_SEVERE:
		return _Bleeding.SEVERITY_SEVERE
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_MODERATE:
		return _Bleeding.SEVERITY_MODERATE
	return _Bleeding.SEVERITY_MINOR

func _add_wound(part: String, injury_type: String, damage: float, sub_region: String = "", severity_override: String = "") -> void:
	if part.is_empty() or damage <= 0.0:
		return
	var severity: String = severity_override if not severity_override.is_empty() else _severity_from_damage(part, damage, sub_region)
	# Minor blunt => bruise (contusion): pain without significant bleeding; severity-based resolution (HealingConstants).
	if injury_type == _Bleeding.INJURY_TYPE_CRUSH and severity == _Bleeding.SEVERITY_MINOR:
		injury_type = _Bleeding.INJURY_TYPE_BRUISE
	var base_rate: float = _Bleeding.get_bleeding_rate(injury_type, severity, part, sub_region)
	# Allow wounds with 0 bleeding rate so they still contribute to pain (blunt/non-bleeding trauma).
	if base_rate < 0.0:
		base_rate = 0.0
	# Variance: hit in more/less vascular spot (BLEEDING_MEDICAL_ACCURACY §10).
	if base_rate > 0.0:
		base_rate *= randf_range(_Bleeding.BLEEDING_RATE_VARIANCE_MIN, _Bleeding.BLEEDING_RATE_VARIANCE_MAX)
	var is_arterial: bool = randf() < _Bleeding.get_arterial_chance(severity, injury_type, part, sub_region) if base_rate > 0.0 else false
	if base_rate > 0.0 and is_arterial:
		base_rate *= _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	if wounds.get(part) == null:
		wounds[part] = []
	var current_rate: float = base_rate
	var healing_duration: float = _Healing.get_wound_healing_duration_seconds(part, severity, injury_type)
	var injury: Dictionary = {
		"injury_type": injury_type,
		"severity": severity,
		"damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": current_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial,
		"created_at_game_time": _game_time_seconds,
		"healing_duration_seconds": healing_duration
	}
	wounds[part].append(injury)

"""Creates a single stump wound for a severed part. Bleeding is part- and level-accurate (sub_region = where cut occurred); slight random variation."""
func _create_stump_wound(part: String, sub_region: String) -> Array:
	if sub_region.is_empty():
		sub_region = _Bleeding.get_random_sub_region(part)
	var base_rate: float = _Bleeding.get_stump_bleeding_rate(part, sub_region)
	var variation: float = 0.92 + randf() * 0.16  # 0.92–1.08
	base_rate *= variation
	var arterial_chance: float = _Bleeding.get_arterial_chance(_Bleeding.SEVERITY_CRITICAL, _Bleeding.INJURY_TYPE_CUT, part, sub_region) * _Bleeding.STUMP_ARTERIAL_CHANCE_MULTIPLIER
	arterial_chance = clampf(arterial_chance, 0.0, 1.0)
	var is_arterial: bool = randf() < arterial_chance
	if is_arterial:
		base_rate *= _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	var damage: float = float(body_max.get(part, 10))
	var healing_duration: float = _Healing.get_wound_healing_duration_seconds(part, _Bleeding.SEVERITY_CRITICAL, _Bleeding.INJURY_TYPE_CUT)
	var injury: Dictionary = {
		"injury_type": _Bleeding.INJURY_TYPE_CUT,
		"severity": _Bleeding.SEVERITY_CRITICAL,
		"damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": base_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial,
		"created_at_game_time": _game_time_seconds,
		"healing_duration_seconds": healing_duration,
		"is_stump": true
	}
	return [injury]

func get_total_bleeding_rate() -> float:
	var total: float = 0.0
	for part in wounds:
		total += get_bleeding_rate_for_part(part)
	return total

"""Bleeding rate from a single part (0 if tourniquet on that part). Used to check when direct pressure can stop."""
func get_bleeding_rate_for_part(part: String) -> float:
	if tourniquet_applied.has(part):
		return 0.0
	if not wounds.has(part):
		return 0.0
	var total: float = 0.0
	for injury in wounds[part]:
		total += injury.get("current_bleeding_rate", 0.0)
	return total

"""Parts that currently have at least one wound (for medical action UI)."""
func get_wounded_parts() -> Array:
	var out: Array = []
	for part in wounds.keys():
		out.append(part)
	return out

func get_wounds() -> Dictionary:
	return wounds.duplicate(true)

"""Returns 0.0 (fresh) to 1.0 (resolved) for UI or save. Uses wound's created_at_game_time and healing_duration_seconds."""
func get_wound_healing_progress(injury: Dictionary) -> float:
	return _get_wound_healing_progress(injury)

"""Current game time (seconds) for per-wound healing. Advance with process_healing(seconds)."""
func get_game_time_seconds() -> float:
	return _game_time_seconds

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
				# Arterial even when bandaged: pressure helps but arterial pressure still inhibits clot formation.
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
			else:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
				clotting = _Bleeding.get_clotting_rate(sev) * _Bleeding.get_clotting_multiplier(sev)
				# Arterial wounds: pressure inhibits clotting; clot very slowly.
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
			# Exponential decay of bleeding rate (rate ∝ current rate); first-order kinetics. See RESEARCH_BASED_APPROXIMATIONS.md.
			rate = rate * exp(-clotting * delta)
			rate = maxf(0.0, rate)
			# Once clotted (rate <= epsilon), set to 0 so wound no longer contributes to blood loss. Do NOT remove: wound still needs to heal and remains painful until removed in process_healing() when healing progress >= WOUND_RESOLVED_THRESHOLD.
			if rate <= _Bleeding.BLEEDING_RATE_EPSILON:
				rate = 0.0
			injury["current_bleeding_rate"] = rate
			i -= 1
		if list.is_empty():
			wounds.erase(part)
	# Direct pressure ends when bleeding on that part stops
	if not direct_pressure_part.is_empty() and get_bleeding_rate_for_part(direct_pressure_part) <= _Bleeding.BLEEDING_RATE_EPSILON:
		print("[Medical] %s direct_pressure auto-cleared: bleeding on %s stopped (rate <= epsilon)" % [name, direct_pressure_part])
		direct_pressure_part = ""

func process_blood_loss(delta: float) -> void:
	var total: float = get_total_bleeding_rate()
	if total <= 0.0:
		return
	var loss: float = total * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER * delta
	blood_volume = maxf(0.0, blood_volume - loss)
	_update_consciousness()
	if blood_volume <= _get_blood_loss_death_threshold():
		emit_signal("died")

"""Seconds the action system should delay before applying bandage effect (wrapping, securing)."""
func get_bandage_application_time_seconds() -> float:
	return _Bleeding.BANDAGE_APPLICATION_TIME_SECONDS

"""Seconds the action system should delay before applying tourniquet effect (positioning, tightening)."""
func get_tourniquet_application_time_seconds() -> float:
	return _Bleeding.TOURNIQUET_APPLICATION_TIME_SECONDS

func apply_bandage(part: String, effectiveness: float = 1.0) -> void:
	if part.is_empty() or not wounds.has(part):
		return
	clear_direct_pressure()  # bandage is a new action; stop holding pressure
	effectiveness = clampf(effectiveness, 0.0, 1.0)
	var wound_count: int = wounds[part].size()
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
	print("[Medical] %s apply_bandage(%s) => %d wound(s) stabilized" % [name, part, wound_count])

"""Direct pressure: use a functional arm to apply pressure to the wound site. Stronger than bandage (80% reduction); requires at least one usable arm. Returns false if no functional arm or no wounds on part."""
func can_apply_direct_pressure(_target_part: String) -> bool:
	return not get_attacking_arm().is_empty()

func apply_direct_pressure(part: String) -> bool:
	if part.is_empty() or not wounds.has(part):
		return false
	if get_attacking_arm().is_empty():
		return false  # no functional arm to apply pressure
	var effectiveness: float = 1.0
	for injury in wounds[part]:
		var eff: float = effectiveness
		if injury.get("is_arterial", false):
			eff *= _Bleeding.DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT
		var reduction: float = _Bleeding.DIRECT_PRESSURE_IMMEDIATE_REDUCTION * eff
		var rate: float = injury.get("current_bleeding_rate", 0.0)
		injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - reduction))
		injury["is_stabilized"] = true
		if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
			injury["stabilized_remaining_seconds"] = _Bleeding.BANDAGE_STABILIZATION_DURATION
	direct_pressure_part = part  # holding pressure until next action or bleeding stops
	print("[Medical] %s applying direct_pressure on %s => holding until next action or bleeding stops" % [name, part])
	return true

"""True if entity is currently holding direct pressure on a part (busy until cleared or bleeding stops)."""
func is_applying_direct_pressure() -> bool:
	return not direct_pressure_part.is_empty()

"""Part currently under direct pressure; empty string if none. Call clear_direct_pressure() when they take another action."""
func get_direct_pressure_part() -> String:
	return direct_pressure_part

"""Call when the entity takes any other action (attack, bandage, tourniquet, move, etc.). Also cleared automatically when bleeding on the pressure part stops."""
func clear_direct_pressure() -> void:
	if not direct_pressure_part.is_empty():
		print("[Medical] %s clear_direct_pressure (was holding %s)" % [name, direct_pressure_part])
	direct_pressure_part = ""

"""Tourniquet: limb-only. Stops bleeding from that limb (wounds on part no longer contribute to blood loss). When removed or expired, bleeding can resume. CoTCCC/TCCC."""
func can_apply_tourniquet(part: String) -> bool:
	return part in _Bleeding.LIMB_PARTS

func is_tourniquet_applied(part: String) -> bool:
	return tourniquet_applied.has(part)

func apply_tourniquet(part: String) -> bool:
	if not can_apply_tourniquet(part):
		return false
	clear_direct_pressure()  # tourniquet is a new action; stop holding pressure
	tourniquet_applied[part] = _game_time_seconds
	print("[Medical] %s apply_tourniquet(%s) => limb bleeding excluded from blood loss" % [name, part])
	return true

func remove_tourniquet(part: String) -> void:
	tourniquet_applied.erase(part)

# Healing: exponential deficit decay (tissue, bone, blood). Per-wound: pain decays by healing progress; resolved wounds removed.
# Call on time advance. Game time advances here for per-wound healing and pain.
func process_healing(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_game_time_seconds += seconds

	# Backfill legacy wounds: give them created_at and healing_duration so they participate in per-wound healing
	for part in wounds.keys():
		for injury in wounds[part]:
			if injury.get("created_at_game_time", -1.0) < 0.0:
				injury["created_at_game_time"] = _game_time_seconds
			if injury.get("healing_duration_seconds", 0.0) <= 0.0:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
				var itype: String = injury.get("injury_type", _Bleeding.INJURY_TYPE_CRUSH)
				injury["healing_duration_seconds"] = _Healing.get_wound_healing_duration_seconds(part, sev, itype)

	# Remove resolved wounds (healing progress >= threshold); pain has effectively resolved
	for part in wounds.keys():
		var list: Array = wounds[part]
		var i: int = list.size() - 1
		while i >= 0:
			if _get_wound_healing_progress(list[i]) >= WOUND_RESOLVED_THRESHOLD:
				list.remove_at(i)
			i -= 1
		if list.is_empty():
			wounds.erase(part)

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
	# Tourniquet expiry: if max duration > 0, release TQ after duration (limb ischemia risk). Bleeding can resume.
	if _Bleeding.TOURNIQUET_MAX_DURATION_SECONDS > 0.0:
		for part in tourniquet_applied.keys():
			var applied_at: float = tourniquet_applied[part]
			if _game_time_seconds - applied_at >= _Bleeding.TOURNIQUET_MAX_DURATION_SECONDS:
				tourniquet_applied.erase(part)
	for part in _get_body_part_list():
		if part not in body_max or part not in bone_max:
			continue
		if _is_part_severed(part):
			continue  # severed part is gone; no healing. Crushed/mangled (still attached) can heal (limb salvage).
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
	tourniquet_applied.clear()
	direct_pressure_part = ""
	_game_time_seconds = 0.0
	blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	consciousness = 100.0
	effective_consciousness = 100.0
	_pain_shock_until_time = -1.0
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
