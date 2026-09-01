class_name CombatArmorDoctrine
extends RefCounted

## D3: Full armor doctrine system.
## Estimates opponent armor tier from equipped pieces, recommends specialized forms (half_sword/mordhau),
## and adapts target part selection toward armor gaps based on the attacker's doctrine state.


# Armor tier thresholds (total RHA sharp resistance across all body parts).
const ARMOR_TIER_NONE_THRESHOLD := 2.0
const ARMOR_TIER_LIGHT_THRESHOLD := 8.0
const ARMOR_TIER_MEDIUM_THRESHOLD := 16.0
const ARMOR_TIER_HEAVY_THRESHOLD := 30.0
# Armor degradation: protection falls 1.0 -> 0.3 as absorbed damage reaches the part's resistance threshold, then
# continues to complete failure (0.0) at this multiple of the threshold. Heavily battered armor no longer protects.
const ARMOR_COMPLETE_FAILURE_ABSORBED_MULT := 2.0

# Armor tier labels for UI/log.
const TIER_NONE := "none"
const TIER_LIGHT := "light"
const TIER_MEDIUM := "medium"
const TIER_HEAVY := "heavy"

# Doctrine state keys on combatant dict.
const COMBATANT_KEY_DOCTRINE_ARMOR_TIER: String = "armor_doctrine_tier"
const COMBATANT_KEY_DOCTRINE_ACTIVATED_FORM: String = "armor_doctrine_form"
const COMBATANT_KEY_DOCTRINE_GAP_TARGETS: String = "armor_doctrine_gap_targets"
const COMBATANT_KEY_DOCTRINE_DEGRADATION_TRACKING: String = "armor_degradation"

# Recommended forms for each armor tier.
const _TIER_TO_FORM: Dictionary = {
	TIER_NONE: "",           # no doctrine needed
	TIER_LIGHT: "ox",        # standard form still viable
	TIER_MEDIUM: "half_sword",  # specialized anti-plate
	TIER_HEAVY: "mordhau",   # grappling/close-quarters anti-armor
}

# Form tier mapping — which forms are armor-doctrine forms.
const _DOCTRINE_FORMS := ["half_sword", "mordhau"]


## Estimate total sharp resistance from a combatant's armor slots.
static func estimate_armor_rha(combatant: Dictionary) -> float:
	if combatant.is_empty():
		return 0.0
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_slots"):
		return 0.0
	var slots: Dictionary = node._get_armor_slots()
	var total_rha: float = 0.0
	for part_key in slots.keys():
		var piece = slots[part_key]
		if piece is ArmorPiece:
			total_rha += piece.get_outer_layer_sharp_resistance_rha_mm()
		elif piece is Dictionary:
			# Fallback for raw dict-style armor data.
			total_rha += float(piece.get("sharp_resistance_rha_mm", 0.0))
	return total_rha


## Get the highest single-part RHA resistance (for determining which parts to aim around).
static func get_max_part_rha(combatant: Dictionary) -> float:
	if combatant.is_empty():
		return 0.0
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_slots"):
		return 0.0
	var slots: Dictionary = node._get_armor_slots()
	var max_rha: float = 0.0
	for part_key in slots.keys():
		var piece = slots[part_key]
		if piece is ArmorPiece:
			max_rha = maxf(max_rha, piece.get_outer_layer_sharp_resistance_rha_mm())
		elif piece is Dictionary:
			max_rha = maxf(max_rha, float(piece.get("sharp_resistance_rha_mm", 0.0)))
	return max_rha


## Classify armor tier (none/light/medium/heavy) from a combatant's equipment.
static func classify_tier(combatant: Dictionary) -> String:
	if combatant.is_empty():
		return TIER_NONE
	var rha: float = estimate_armor_rha(combatant)
	if rha < ARMOR_TIER_NONE_THRESHOLD:
		return TIER_NONE
	if rha < ARMOR_TIER_LIGHT_THRESHOLD:
		return TIER_LIGHT
	if rha < ARMOR_TIER_MEDIUM_THRESHOLD:
		return TIER_MEDIUM
	return TIER_HEAVY


## Get the recommended doctrine form for the given armor tier.
static func recommended_form_for_tier(tier: String) -> String:
	return _TIER_TO_FORM.get(tier, "")


## Check if a form is an armor-doctrine form (half_sword/mordhau).
static func is_doctrine_form(form: String) -> bool:
	return form in _DOCTRINE_FORMS


## Check if the combatant has doctrine activated (they are using half_sword or mordhau).
static func is_doctrine_activated(combatant: Dictionary) -> bool:
	if combatant.is_empty():
		return false
	var form: String = CombatantEntityAccess.form_str(combatant)
	return is_doctrine_form(form)


## Identify armor gaps on the opponent — parts with RHA below a threshold (unprotected/exposed).
static func find_armor_gaps(combatant: Dictionary, max_rha: float = 1.5) -> Array:
	if combatant.is_empty():
		return []
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_slots"):
		return []
	var slots: Dictionary = node._get_armor_slots()
	var gaps: Array = []
	for part_key in slots.keys():
		var piece = slots[part_key]
		var rha: float = 0.0
		if piece is ArmorPiece:
			rha = piece.get_outer_layer_sharp_resistance_rha_mm()
		elif piece is Dictionary:
			rha = float(piece.get("sharp_resistance_rha_mm", 0.0))
		if rha <= max_rha:
			gaps.append(part_key)
	return gaps


## Find the best target part on a heavily armored opponent for a given contact type.
## Returns "" if no good gap is found.
static func pick_gap_target(
	combatant: Dictionary,
	_contact_type: String = "",
	max_rha: float = 1.5,
	targetable_parts: Array = []
) -> String:
	var gaps: Array = find_armor_gaps(combatant, max_rha)
	if targetable_parts.is_empty():
		targetable_parts = BodyPartConstants.BODY_PARTS.duplicate()
	# Filter to only targetable gaps.
	var viable: Array = []
	for g in gaps:
		if g in targetable_parts:
			viable.append(g)
	if viable.is_empty():
		return ""
	# Prioritize limbs over torso (historically, half-sword/mordhau aim for weapon-arm joints).
	for part in [BodyPartConstants.PART_LEFT_ARM, BodyPartConstants.PART_RIGHT_ARM]:
		if part in viable:
			return part
	# Then legs.
	for part in [BodyPartConstants.PART_LEFT_LEG, BodyPartConstants.PART_RIGHT_LEG]:
		if part in viable:
			return part
	# Finally head (vulnerable but small).
	if BodyPartConstants.PART_HEAD in viable:
		return BodyPartConstants.PART_HEAD
	return ""


## Apply armor-aware target part bias to AI weights. Modifies `weights` dict in place,
## boosting gap parts when attacking armored opponent. Doctrine forms get full bonuses;
## non-doctrine forms still get partial awareness (instinctive targeting of gaps).
static func apply_armor_bias_to_weights(
	attacker: Dictionary,
	defender: Dictionary,
	weights: Dictionary,
	contact_type: String = ""
) -> void:
	if weights.is_empty():
		return
	var atk_form: String = CombatantEntityAccess.form_str(attacker)
	var is_doctrine: bool = is_doctrine_form(atk_form)
	var def_tier: String = classify_tier(defender)
	if def_tier in [TIER_NONE, TIER_LIGHT]:
		return
	var max_rha: float = 1.5
	if def_tier == TIER_MEDIUM:
		max_rha = 2.0
	elif def_tier == TIER_HEAVY:
		max_rha = 3.0
	var gaps: Array = find_armor_gaps(defender, max_rha)
	if gaps.is_empty():
		return
	for gap in gaps:
		if weights.has(gap):
			var base_bonus: float = 1.4 if is_doctrine else 1.2
			var bonus: float = base_bonus
			if contact_type == "stab" and gap in [BodyPartConstants.PART_HEAD]:
				bonus = 2.0 if is_doctrine else 1.6  # half-sword thrust to visor/joints vs heavy plate
			elif contact_type == "cut":
				bonus = 1.3 if is_doctrine else 1.15  # cuts less effective at gaps, but still useful
			weights[gap] = weights.get(gap, 1.0) * bonus


## Compute armor degradation tracker for a combatant (called during attack resolution).
## Returns {part: damage_absorbed} dictionary tracking cumulative damage to armor layers.
static func get_degradation_tracker(combatant: Dictionary) -> Dictionary:
	if combatant.is_empty():
		return {}
	var tracker: Variant = combatant.get(COMBATANT_KEY_DOCTRINE_DEGRADATION_TRACKING, null)
	if tracker is Dictionary:
		return tracker
	return {}


## Record armor degradation on a body part (called after damage resolves against armored target).
static func record_armor_damage(combatant: Dictionary, part: String, absorbed_damage: float) -> void:
	if combatant.is_empty() or part.is_empty():
		return
	var tracker: Dictionary = get_degradation_tracker(combatant)
	if not tracker.has(part):
		tracker[part] = 0.0
	tracker[part] += absorbed_damage
	combatant[COMBATANT_KEY_DOCTRINE_DEGRADATION_TRACKING] = tracker


## Check if armor on a part is degraded (absorbed damage exceeded ~40% of max layer resistance).
static func is_armor_degraded(combatant: Dictionary, part: String) -> bool:
	var tracker: Dictionary = get_degradation_tracker(combatant)
	if not tracker.has(part):
		return false
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_for_part"):
		return false
	var piece = node._get_armor_for_part(part)
	if piece is ArmorPiece:
		var max_resistance: float = 0.0
		# Sum all layer resistances for degradation threshold.
		# Approximate: outer_layer * layer_count equivalent.
		max_resistance = piece.get_outer_layer_sharp_resistance_rha_mm() * 2.0
		return tracker[part] > (max_resistance * 0.4)
	elif piece is Dictionary:
		var dur: float = piece.get("durability", ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
		return tracker[part] > (dur * 0.4)
	return false


## Degradation factor from absorbed damage vs the part's resistance threshold. Protection falls 1.0 -> 0.3 as
## absorbed reaches the threshold, then continues to complete failure (0.0) at ARMOR_COMPLETE_FAILURE_ABSORBED_MULT
## times the threshold — heavily battered armor no longer protects.
static func _armor_degradation_factor_from_absorbed(absorbed: float, threshold: float) -> float:
	if threshold <= 0.0:
		return 1.0
	var ratio: float = clampf(absorbed / threshold, 0.0, float(ARMOR_COMPLETE_FAILURE_ABSORBED_MULT))
	if ratio <= 1.0:
		return lerpf(1.0, 0.3, ratio)
	return lerpf(0.3, 0.0, ratio - 1.0)


## Get armor degradation factor — how much RHA protection remains based on cumulative absorbed damage.
## Returns a ratio between 0.0 (failed) and 1.0 (intact), scaled with absorbed damage.
static func get_armor_degradation_factor(combatant: Dictionary, part: String) -> float:
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_for_part"):
		return 1.0
	var piece = node._get_armor_for_part(part)
	if piece is ArmorPiece:
		var max_resistance: float = piece.get_outer_layer_sharp_resistance_rha_mm() * 2.0
		var tracker: Dictionary = get_degradation_tracker(combatant)
		if not tracker.has(part):
			return 1.0
		return _armor_degradation_factor_from_absorbed(tracker[part], max_resistance)
	elif piece is Dictionary:
		var dur: float = piece.get("durability", ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
		var tracker: Dictionary = get_degradation_tracker(combatant)
		if not tracker.has(part):
			return 1.0
		return _armor_degradation_factor_from_absorbed(tracker[part], maxf(dur, 0.01))
	return 1.0


## Get armor degradation UI hint for a body part.
static func get_degradation_hint(combatant: Dictionary, part: String) -> String:
	if is_armor_degraded(combatant, part):
		return "armor_degraded" if part == BodyPartConstants.PART_CHEST else "armor_weakening"
	return ""


## Clear doctrine state when combat ends.
static func clear_doctrine_state(c: Dictionary) -> void:
	if c.is_empty():
		return
	c.erase(COMBATANT_KEY_DOCTRINE_ARMOR_TIER)
	c.erase(COMBATANT_KEY_DOCTRINE_ACTIVATED_FORM)
	c.erase(COMBATANT_KEY_DOCTRINE_GAP_TARGETS)
	c.erase(COMBATANT_KEY_DOCTRINE_DEGRADATION_TRACKING)


## Estimate armor tier and store it on the combatant dict for later lookups.
static func update_doctrine_assessment(manager: Node, defender_id: int) -> void:
	if manager == null or defender_id < 0:
		return
	var defender: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
	if defender.is_empty():
		return
	var tier: String = classify_tier(defender)
	defender[COMBATANT_KEY_DOCTRINE_ARMOR_TIER] = tier
	if tier in [TIER_MEDIUM, TIER_HEAVY]:
		# Pre-compute gap targets for AI use.
		var gaps: Array = find_armor_gaps(defender)
		defender[COMBATANT_KEY_DOCTRINE_GAP_TARGETS] = gaps


## Check if attacker should consider doctrine form against a specific defender.
static func should_consider_doctrine(_attacker: Dictionary, defender: Dictionary) -> bool:
	if defender.is_empty():
		return false
	var def_tier: String = classify_tier(defender)
	return def_tier in [TIER_MEDIUM, TIER_HEAVY]


## Get the effective RHA reduction due to armor degradation on a specific part.
static func get_effective_rha_with_degradation(combatant: Dictionary, part: String) -> float:
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_for_part"):
		return 0.0
	var piece = node._get_armor_for_part(part)
	if piece is ArmorPiece:
		var base_rha: float = piece.get_outer_layer_sharp_resistance_rha_mm()
		return base_rha * get_armor_degradation_factor(combatant, part)
	elif piece is Dictionary:
		var rha: float = float(piece.get("sharp_resistance_rha_mm", 0.0))
		return rha * get_armor_degradation_factor(combatant, part)
	return 0.0


## Get recommended gap target for AI targeting when using doctrine form.
static func get_ai_gap_target_recommendation(attacker: Dictionary, defender: Dictionary) -> String:
	var atk_form: String = CombatantEntityAccess.form_str(attacker)
	if not is_doctrine_form(atk_form):
		return ""
	var def_tier: String = classify_tier(defender)
	if def_tier in [TIER_NONE, TIER_LIGHT]:
		return ""
	defender.get(COMBATANT_KEY_DOCTRINE_GAP_TARGETS, [])
	return pick_gap_target(defender, "", 2.0 if def_tier == TIER_MEDIUM else 3.0)


## Compute form switch cost reduction when switching to doctrine form (body movement already in position).
static func form_switch_cost_modifier(attacker: Dictionary, defender: Dictionary) -> float:
	var atk_form: String = CombatantEntityAccess.form_str(attacker)
	if is_doctrine_form(atk_form):
		# Already in doctrine form — switching to another doctrine form is cheaper.
		return 0.7
	var def_tier: String = classify_tier(defender)
	if def_tier == TIER_HEAVY:
		# Heavy armor detected — AI may proactively switch to mordhau with reduced cost.
		return 0.85
	return 1.0


## Determine if a contact type is effective against the given armor tier.
static func contact_type_effective(contact_type: String, armor_tier: String) -> float:
	if armor_tier == TIER_NONE or armor_tier == TIER_LIGHT:
		return 1.0  # all types work similarly
	if armor_tier == TIER_MEDIUM:
		if contact_type == "stab":
			return 1.3  # thrusts penetrate gaps in mail/plate joints
		elif contact_type == "cut":
			return 0.85  # cuts deflect off plate
		else:  # blunt
			return 1.1  # blunt transmits through plate
	if armor_tier == TIER_HEAVY:
		if contact_type == "stab":
			return 1.5  # half-sword thrust to visor/joints is devastating
		elif contact_type == "cut":
			return 0.7  # cuts largely useless vs full plate
		else:  # blunt
			return 1.2  # mace/pommel still effective via blunt transmission
	return 1.0


## Check if the combatant's armor includes a specific body part.
static func has_armor_on_part(combatant: Dictionary, part: String) -> bool:
	if combatant.is_empty() or part.is_empty():
		return false
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_for_part"):
		return false
	var piece = node._get_armor_for_part(part)
	return piece != null and (piece is ArmorPiece or piece is Dictionary)


## Count number of body parts with armor above threshold.
static func count_armored_parts(combatant: Dictionary, min_rha: float = 1.0) -> int:
	var node = _combatant_node(combatant)
	if node == null or not node.has_method("_get_armor_slots"):
		return 0
	var slots: Dictionary = node._get_armor_slots()
	var count: int = 0
	for part_key in slots.keys():
		var piece = slots[part_key]
		var rha: float = 0.0
		if piece is ArmorPiece:
			rha = piece.get_outer_layer_sharp_resistance_rha_mm()
		elif piece is Dictionary:
			rha = float(piece.get("sharp_resistance_rha_mm", 0.0))
		if rha >= min_rha:
			count += 1
	return count


## Get a summary string of the combatant's armor for UI/log display.
static func armor_summary(combatant: Dictionary) -> String:
	var tier: String = classify_tier(combatant)
	var rha: float = estimate_armor_rha(combatant)
	var armored_count: int = count_armored_parts(combatant, 1.0)
	return "Armor: %s (%.1f RHA, %d parts)" % [tier, rha, armored_count]


## Resolve the combatant's scene node from its dict representation.
static func _combatant_node(combatant: Dictionary) -> Variant:
	if combatant.is_empty():
		return null
	var ent: CoreEntity = CombatantEntityAccess.scene_entity(combatant)
	if ent != null and ent is CoreEntity:
		return ent
	return null


## Weapon-type-specific armor interaction multiplier for mace.
## Returns a factor >= 1.0 that scales mace damage UP against armored targets, representing
## blunt force trauma transmitted through plate/mail that edged weapons cannot deliver.
## target_rha_mm: sharp resistance of the target's armor on the hit part in mm RHA.
static func mace_armor_interaction_multiplier(target_rha_mm: float) -> float:
	if target_rha_mm <= ARMOR_TIER_NONE_THRESHOLD:
		return 1.0  # cloth/gambeson — no bonus vs soft targets
	elif target_rha_mm <= ARMOR_TIER_LIGHT_THRESHOLD:
		# Mail armor — mace crushes beneath links, transmitting shock to body
		var ratio = (target_rha_mm - ARMOR_TIER_NONE_THRESHOLD) / (ARMOR_TIER_LIGHT_THRESHOLD - ARMOR_TIER_NONE_THRESHOLD)
		return 1.2 + ratio * 0.3  # 1.2x at none → 1.5x at light mail
	elif target_rha_mm <= ARMOR_TIER_MEDIUM_THRESHOLD:
		# Medium plate — flanged head dents plates, concentrates force on small contact areas
		var ratio = (target_rha_mm - ARMOR_TIER_LIGHT_THRESHOLD) / (ARMOR_TIER_MEDIUM_THRESHOLD - ARMOR_TIER_LIGHT_THRESHOLD)
		return 1.5 + ratio * 0.28  # 1.5x at light → 1.78x at medium
	else:
		return 1.78  # cap vs heavy plate
