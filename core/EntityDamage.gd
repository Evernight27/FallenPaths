class_name EntityDamage
extends RefCounted

## Severance ease and full damage-split application. Entity must have: body_*, bone_*, wounds, endurance,
## _get_armor_for_part(part), _round_tissue(v), _get_vital_parts(), _is_part_severed(part),
## _get_pain_contribution_for_wound(...),
## _last_hit_impact, _try_enter_pain_shock_from_hit(pain), _update_consciousness(), EntityWounds.emit_death_once.

# Damage resistance and severance (CoreEntity-aligned).
## Damage resistance per END point: 0.2% per point (150 END = 30% reduction, capped at 25%).
## Clinical basis: muscle mass and tissue density provide meaningful blunt trauma dissipation;
## previous value (0.01%/point) was biomechanically negligible — a 150-END character got only 0.75% mitigation.
const ENDURANCE_DAMAGE_RESISTANCE_PER_POINT: float = 0.002
const ENDURANCE_DAMAGE_RESISTANCE_MAX: float = 0.25
## Base minimum damage required for any severance attempt — raised from 10 to 28 based on clinical data:
## Traumatic blade amputation is biomechanically impossible; real dismemberment requires bone fracture + massive force.
const MIN_DAMAGE_TO_SEVER: int = 28
const DEFLECTION_BRUISE_THRESHOLD: int = 3
const SEVERANCE_EARLY_THRESHOLD: float = 0.25
const SEVERANCE_EARLY_MAX_CHANCE: float = 0.10
const SEVERANCE_EARLY_LIMBS_ONLY: bool = true
## Per-body-part minimum severance thresholds — models that different body regions require vastly different force.
## Head is most fragile (thin bone, vital structures); extremities are nearly impossible to amputate with blades alone.
## Clinical basis: traumatic dismemberment requires >200J cutting energy + sustained force; real battlefield amputations
## are almost always from blast/impaction trauma, not blade wounds. Values tuned for gameplay pacing while maintaining realism.
## Reference values scale against human tissue budgets (head=10, chest=30, arms=12, legs=16).
const SEVERANCE_MIN_DAMAGE_BY_PART: Dictionary = {
	"head": 25,                 # Thin skull + vital structures — most fragile region
	"chest": 30,                # Rib cage + thoracic musculature — very difficult to sever through armor/bone
	"abdomen": 30,              # Soft tissue but deep organ protection — requires massive force
	"neck": 25,                 # Thin structures but trachea/spine provide resistance; clinically fatal before severance
	"right_arm": 35,            # Humerus + biceps/triceps — traumatic amputation biomechanically impossible with blades
	"left_arm": 35,             # Same as right arm (non-dominant)
	"right_leg": 40,            # Femur is strongest bone in body; quadriceps/hamstrings provide massive tissue resistance
	"left_leg": 40,             # Same as right leg
}
const SEVERANCE_REFERENCE_TISSUE_BY_PART: Dictionary = {
	"head": 10.0,
	"chest": 30.0,
	"abdomen": 30.0,
	"neck": 10.0,
	"right_arm": 12.0,
	"left_arm": 12.0,
	"right_leg": 16.0,
	"left_leg": 16.0,
}

# Severance ease: full-health limb resists dismemberment; already wounded/bone-damaged parts give way more easily.
## Overall ease range: 1.0 (healthy) to 1.8 (max). Each wound adds SEVERANCE_EASE_PER_WOUND=3% to the base factor.
## Severity bonus scales by clinical trauma tier — tuned for gameplay feel rather than direct clinical mapping:
## minor (superficial): no bonus, moderate (fat/muscle only): +5%, severe (deep fascia/tendon): +12%, critical (bone/joint): +20%.
const SEVERANCE_EASE_MAX: float = 1.8
const SEVERANCE_EASE_TISSUE_FACTOR: float = 0.4
const SEVERANCE_EASE_BONE_FACTOR: float = 0.3
const SEVERANCE_EASE_PER_WOUND: float = 0.03
const SEVERANCE_EASE_WOUND_CAP: float = 0.12
const SEVERANCE_EASE_SEVERITY_BONUS: Dictionary = {"minor": 0.0, "moderate": 0.05, "severe": 0.12, "critical": 0.20}

# Per-channel amplification dampening to prevent multi-channel zeroing from ease factor alone.
# When base allocation already zeroes a channel (to_X >= cur_X), ease=1.0 for that channel — no bonus amplification.
# Otherwise, local ease = 1.0 + (severance_ease - 1.0) * CHANNEL_DAMP, capping the wound amplifier so
# at most one channel can be zeroed by amplified damage per hit when base allocations alone wouldn't do it.
const SEVERANCE_EASE_CHANNEL_DAMP: float = 0.75

# --- Cumulative tissue trauma (P2 #3 from biomechanics pass) ---
## Repeated strikes to the same body region cause microstructural damage that degrades tissue beyond
## what a single hit would predict — models fatigue cracking in bone, cumulative fiber tearing in muscle,
## and progressive fascial disruption. Clinical basis: repeated sub-fracture impacts cause stress fractures;
## sustained blunt trauma causes progressive contusion expansion (ATLS Ch.3 soft-tissue injury).
const CUMULATIVE_TRAUMA_WINDOW_S: float = 15.0       # rolling window for counting prior hits to same part
const CUMULATIVE_TRAUMA_DAMAGE_MULT_PER_HIT: float = 0.06  # each prior hit adds 6% damage (tissue fatigue)
const CUMULATIVE_TRAUMA_MAX_BONUS: float = 0.35       # caps at +35% total bonus (diminishing returns on tissue failure)

## --- Armor energy accounting (design options, not implemented) ---
## Option A  -  Layer joule budget: each layer absorbs KE from a running total; sharp vs blunt uses split
## absorption curves. Pros: matches armor literature, one conserved quantity. Cons: needs per-material
## data, larger refactor, tuning all weapons again.
## Option B  -  Impedance chain: sequential reflection coefficients per interface. Pros: fast, stable.
## Cons: still many tuned coefficients, less intuitive than joules for designers.
## Option C  -  Hybrid: keep current scalar streams but report "estimated absorbed joules" for logs/AI
## only. Pros: incremental. Cons: not physically authoritative, can disagree with gameplay damage.
## Option D  -  Monte Carlo micro-deflect: sample yarn/ring deflections. Pros: rich variance. Cons: CPU,
## hard to balance, opaque to players.


static func _layer_state_rows_for_part(entity: Node, part: String) -> Array:
	if not ("tissue_layer_state" in entity):
		return CombatLayerTissue.seed_layer_state_for_part(part)
	var by_part: Variant = entity.tissue_layer_state
	if by_part is Dictionary:
		if not by_part.has(part):
			by_part[part] = CombatLayerTissue.seed_layer_state_for_part(part)
		var rows: Variant = by_part[part]
		if rows is Array:
			return rows
	return CombatLayerTissue.seed_layer_state_for_part(part)


static func get_severance_ease_factor(entity: Node, part: String) -> float:
	var max_tissue: int = entity.body_max.get(part, 1)
	var max_bone: int = entity.bone_max.get(part, 1)
	if max_tissue <= 0 or max_bone <= 0:
		return 1.0
	var cur_cut: float = entity.body_cutting.get(part, 0.0)
	var cur_blunt: float = entity.body_blunt.get(part, 0.0)
	var cur_bone: float = entity.bone_health.get(part, 0.0)
	var tissue_ratio: float = (cur_cut + cur_blunt) / float(maxi(1, max_tissue * 2))
	var bone_ratio: float = cur_bone / float(max_bone)
	var wound_count: int = entity.wounds.get(part, []).size()
	var wound_factor: float = minf(float(wound_count) * SEVERANCE_EASE_PER_WOUND, SEVERANCE_EASE_WOUND_CAP)
	var worst_sev: String = BleedingConstants.SEVERITY_MINOR
	for injury in entity.wounds.get(part, []):
		var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MINOR)
		var order: Array = [
			BleedingConstants.SEVERITY_MINOR,
			BleedingConstants.SEVERITY_MODERATE,
			BleedingConstants.SEVERITY_SEVERE,
			BleedingConstants.SEVERITY_CRITICAL
		]
		if order.find(sev) > order.find(worst_sev):
			worst_sev = sev
	var severity_bonus: float = SEVERANCE_EASE_SEVERITY_BONUS.get(worst_sev, 0.0)
	# A part carrying a wound-derived scar severs more easily — scar tissue shears at ~70-80% of
	# normal tensile strength (same anchor as SCAR_REINJURY_MULT). One small bonus, capped at
	# SEVERANCE_EASE_MAX in the sum below. (A severed part returns early in apply_damage_split and
	# never reaches this, so its amputated_limb scar never feeds here.)
	var scar_ease: float = 0.0
	if "campaign_afflictions" in entity:
		for raw in entity.campaign_afflictions:
			if raw is Dictionary and str(raw.get("part", "")) == part and part != "":
				scar_ease = BleedingConstants.SCAR_SEVERANCE_EASE_BONUS
				break
	var severance_ease: float = (
		1.0
		+ (1.0 - tissue_ratio) * SEVERANCE_EASE_TISSUE_FACTOR
		+ (1.0 - bone_ratio) * SEVERANCE_EASE_BONE_FACTOR
		+ wound_factor
		+ severity_bonus
		+ scar_ease
	)
	return clampf(severance_ease, 1.0, SEVERANCE_EASE_MAX)


static func _get_cumulative_trauma_multiplier(entity: Node, part: String) -> float:
	if not entity.has_meta("_cumulative_trauma_timestamps"):
		entity.set_meta("_cumulative_trauma_timestamps", {})
	var timestamps: Array = []
	if entity.get_meta("_cumulative_trauma_timestamps").has(part):
		timestamps = entity.get_meta("_cumulative_trauma_timestamps")[part]
	var game_time: float = entity._get_game_time_seconds()
	# Purge old entries outside the rolling window.
	var valid: Array = []
	for ts in timestamps:
		if game_time - ts < CUMULATIVE_TRAUMA_WINDOW_S:
			valid.append(ts)
	entity.get_meta("_cumulative_trauma_timestamps")[part] = valid
	# Count prior hits within window — each adds trauma degradation.
	var hit_count: int = valid.size()
	if hit_count <= 0:
		return 1.0
	var trauma_bonus: float = minf(hit_count * CUMULATIVE_TRAUMA_DAMAGE_MULT_PER_HIT, CUMULATIVE_TRAUMA_MAX_BONUS)
	return 1.0 + trauma_bonus


static func _record_cumulative_trauma_hit(entity: Node, part: String) -> void:
	if not entity.has_meta("_cumulative_trauma_timestamps"):
		entity.set_meta("_cumulative_trauma_timestamps", {})
	var timestamps: Dictionary = entity.get_meta("_cumulative_trauma_timestamps")
	if not timestamps.has(part):
		timestamps[part] = []
	timestamps[part].append(entity._get_game_time_seconds())


static func _effective_endurance_for_damage(entity: Node) -> float:
	return EntityStatsUtil.get_effective_stat(entity, "endurance")


## Full damage-split application: armor, bone/tissue split, wounds, early severance, stump, vital death, pain shock.
## extras: strike_ke_j, hit_sub_region, hit_sub_region_seed, force_layer_tissue, force_layer_tissue_curves,
## force_material_curves, material_curve_blend_weight, force_joule_armor_budget, force_tissue_energy_pool,
## disable_layer_tissue, disable_layer_tissue_curves, disable_tissue_energy_pool, disable_joule_armor_budget (harness
## baselines).
## Returns final_* , was_deflected, mechanical_post_armor (cut+blunt sum immediately after armor, game units).
static func apply_damage_split(
	entity: Node,
	cut_pre: float,
	blunt_pre: float,
	part: String,
	penetration_sharp: float = -1.0,
	penetration_blunt_momentum_per_area: float = -1.0,
	blunt_contact_cm: float = -1.0,
	extras: Dictionary = {}
) -> Dictionary:
	var impact_ke: float = extras.get("strike_ke_j", -1.0)
	var weapon_type: String = extras.get("weapon_type", "")
	if part not in entity.body_cutting or part not in entity.body_blunt or part not in entity.bone_health:
		return {
			"final_cut": 0.0,
			"final_blunt": 0.0,
			"final_bone": 0.0,
			"was_deflected": false,
			"mechanical_post_armor": 0.0
		}
	if entity._is_part_severed(part):
		# Detached part should no longer take weapon damage. Keep/seed one stump wound and exit.
		EntityWounds.ensure_stump_wound(entity, part)
		return {
			"final_cut": 0.0,
			"final_blunt": 0.0,
			"final_bone": 0.0,
			"was_deflected": false,
			"mechanical_post_armor": 0.0
		}
	var cut_pre_val: float = maxf(0.0, cut_pre)
	var blunt_pre_val: float = maxf(0.0, blunt_pre)
	var end_resist: float = clampf(
		_effective_endurance_for_damage(entity) * ENDURANCE_DAMAGE_RESISTANCE_PER_POINT,
		0.0,
		ENDURANCE_DAMAGE_RESISTANCE_MAX
	)
	cut_pre_val *= (1.0 - end_resist)
	blunt_pre_val *= (1.0 - end_resist)
	var armor_var: Variant = entity._get_armor_for_part(part)
	var pen_s: float = penetration_sharp if penetration_sharp >= 0.0 else ArmorConstants.DEFAULT_PENETRATION_SHARP
	# The weapon's TRUE (uncapped) contact face, for the rigid-plate area-coupling term. Rides in
	# extras from AttackResolver; -1.0 (absent) makes the coupling fall back to the capped contact.
	var blunt_coupling_contact_cm: float = extras.get("blunt_coupling_contact_cm", -1.0)
	var joule_ke: Dictionary = {}
	var force_joule: bool = extras.get("force_joule_armor_budget", false)
	var joule_authoritative: bool = false
	if (
		ArmorJouleBudget.is_active(force_joule)
		and not extras.get("disable_joule_armor_budget", false)
		and impact_ke > 0.0
		and armor_var != null
		and armor_var.get_script() == ArmorPiece
	):
		joule_ke = ArmorJouleBudget.account_ke_through_armor(
			armor_var, impact_ke, pen_s, cut_pre_val > 0.0, penetration_blunt_momentum_per_area,
			blunt_contact_cm, blunt_coupling_contact_cm
		)
		var ke_frac: float = joule_ke.get("transmitted_ke_fraction", 1.0)
		cut_pre_val *= ke_frac
		blunt_pre_val *= ke_frac
		joule_authoritative = true
	var final_cut: float = 0.0
	var final_blunt: float = 0.0
	var blunt_from_deflection: float = 0.0
	var blunt_from_direct: float = 0.0
	# XCamp-4n: capture which armor layers are destroyed BEFORE this hit so a
	# layer that crosses to 0 during this hit can be traced as a failure event.
	var armor_fail_before: Array = []
	if armor_var != null and armor_var.get_script() == ArmorPiece:
		armor_fail_before = armor_var.destroyed_layer_indices()
	if armor_var != null and armor_var.get_script() == ArmorPiece:
		if joule_authoritative:
			final_cut = cut_pre_val
			final_blunt = blunt_pre_val
			blunt_from_direct = blunt_pre_val
			if CombatConstants.combat_debug_active():
				(
					CombatDebug
					. log(
						(
							(
                                "[Armor] %s %s: joule-authoritative cut=%.1f blunt=%.1f ke_frac=%.3f "
								+ "(scalar ArmorPiece skipped)"
							)
							% [
								entity.name,
								part,
								final_cut,
								final_blunt,
								joule_ke.get("transmitted_ke_fraction", 1.0),
							]
						)
					)
				)
		else:
			var deflected_raw: float = 0.0
			if cut_pre_val > 0.0:
				## Pass the weapon's blunt-transmission params so that, when the edge is deflected by a
				## rigid layer (plate/mail), the deflected shock continues through the inner padding layers
				## with the correct weapon-specific cushion / area-coupling math (not the -1.0 defaults).
				## apply_wear stays true: the inner layers wear ONCE here, during this single pass.
				var result_cut: Dictionary = armor_var.apply_damage(
					cut_pre_val,
					CombatConstants.DAMAGE_TYPE_SHARP,
					pen_s,
					penetration_blunt_momentum_per_area,
					blunt_contact_cm,
					0,
					blunt_coupling_contact_cm,
					true
				)
				var d: float = maxf(0.0, result_cut.get("damage", 0.0))
				var dtype: String = result_cut.get("damage_type", CombatConstants.DAMAGE_TYPE_SHARP)
				if dtype == CombatConstants.DAMAGE_TYPE_SHARP:
					final_cut += d
				else:
					## `transmitted_blunt_amount` is the deflected shock AFTER it has been carried through
					## every inner layer (apply_damage continues the loop once a sharp is deflected), so it
					## is already the final post-armor blunt value — no retransmission is needed.
					deflected_raw = result_cut.get(
						"transmitted_blunt_amount", result_cut.get("deflected_blunt_amount", d)
					)
					blunt_from_deflection = deflected_raw
			blunt_from_direct = blunt_pre_val
			if deflected_raw > 0.0 and blunt_pre_val > 0.0:
				## Both the sharp edge was deflected AND there is a direct blunt component. The deflected
				## blunt (deflected_raw) is already post-armor — the sharp pass above carried the deflected
				## shock through every inner layer — so it is used as-is. The direct blunt is a separate
				## blow that must travel through the whole stack itself.
				var result_direct: Dictionary = armor_var.apply_damage(
					blunt_pre_val,
					CombatConstants.DAMAGE_TYPE_BLUNT,
					0.0,
					penetration_blunt_momentum_per_area,
					blunt_contact_cm,
					0,
					blunt_coupling_contact_cm
				)
				var blunt_after_direct: float = maxf(0.0, result_direct.get("damage", 0.0))
				## Cap combined blunt so it cannot exceed the sum of pre-armor inputs (physics constraint).
				var max_allowed_blunt: float = deflected_raw + blunt_pre_val
				final_blunt = minf(deflected_raw + blunt_after_direct, max_allowed_blunt)
			elif deflected_raw > 0.0:
				## Deflected-only: deflected_raw is already the final post-armor value (the sharp pass
				## carried the deflected shock through every inner layer), so no retransmission is needed.
				final_blunt = deflected_raw
			elif blunt_pre_val > 0.0:
				var result_blunt: Dictionary = armor_var.apply_damage(
					blunt_pre_val,
					CombatConstants.DAMAGE_TYPE_BLUNT,
					0.0,
					penetration_blunt_momentum_per_area,
					blunt_contact_cm,
					0,
					blunt_coupling_contact_cm
				)
				final_blunt = maxf(0.0, result_blunt.get("damage", 0.0))
				if CombatConstants.combat_debug_active():
					(
						CombatDebug
						. log(
							(
								(
	                                "[Armor] %s %s: pre cut=%.1f blunt=%.1f | transmitted_raw=%.1f direct_blunt=%.1f | "
									+ "pen_sharp=%.2f mm RHA | blunt: => post-armor cut=%.1f blunt=%.1f"
								)
								% [
									entity.name,
									part,
									cut_pre_val,
									blunt_pre_val,
									deflected_raw,
									blunt_pre_val,
									pen_s,
									final_cut,
									final_blunt,
								]
							)
						)
					)
	else:
		final_cut = cut_pre_val
		final_blunt = blunt_pre_val
		blunt_from_direct = blunt_pre_val
		if CombatConstants.combat_debug_active() and (cut_pre_val > 0.0 or blunt_pre_val > 0.0):
			CombatDebug.log(
				"[Armor] %s %s: no armor => post cut=%.1f blunt=%.1f" % [entity.name, part, final_cut, final_blunt]
			)
	# XCamp-4n: trace any armor layer that crossed to destroyed during this hit.
	if armor_var != null and armor_var.get_script() == ArmorPiece:
		var armor_fail_after: Array = armor_var.destroyed_layer_indices()
		for idx in armor_fail_after:
			if not armor_fail_before.has(idx):
				CombatDebug.combat_session(
					"ARMOR_LAYER_FAIL %s %s piece=%s layer=%d"
					% [entity.name, part, str(armor_var.display_name), int(idx)]
				)
	# Weapon-type-specific armor interaction (e.g., mace scales UP against armored targets).
	# armor_var is always ArmorPiece-or-null (EntityEquipment._get_armor_for_part filters to it),
	# so no Dictionary fallback is needed.
	if weapon_type == "MACE" and armor_var is ArmorPiece:
		var target_rha: float = armor_var.get_outer_layer_effective_rha_mm()
		if target_rha > CombatArmorDoctrine.ARMOR_TIER_NONE_THRESHOLD:
			var interaction_mult: float = CombatArmorDoctrine.mace_armor_interaction_multiplier(target_rha)
			final_blunt *= interaction_mult
	var total_final: float = final_cut + final_blunt
	# Cumulative tissue trauma — repeated strikes to the same body region degrade tissue beyond single-hit damage.
	## Each prior hit within CUMULATIVE_TRAUMA_WINDOW_S adds ~6% damage (tissue fatigue / microstructural breakdown).
	## Caps at +35% total bonus — models progressive failure where damaged tissue offers less resistance to subsequent hits.
	var trauma_mult: float = _get_cumulative_trauma_multiplier(entity, part)
	total_final *= trauma_mult
	var mechanical_post_armor: float = total_final
	if total_final <= 0.0:
		return {
			"final_cut": 0.0,
			"final_blunt": 0.0,
			"final_bone": 0.0,
			"was_deflected": false,
			"mechanical_post_armor": 0.0
		}
	var sub_region: String = extras.get("hit_sub_region", "").strip_edges()
	if sub_region.is_empty():
		var seed_key: int = int(extras.get("hit_sub_region_seed", entity.get_instance_id()))
		sub_region = CombatHitSubRegion.fallback_sub_region(part, seed_key)
	var combat_mult: float = CombatHitSubRegion.combat_damage_mult(part, sub_region)
	if combat_mult != 1.0:
		final_cut *= combat_mult
		final_blunt *= combat_mult
		total_final = final_cut + final_blunt
		mechanical_post_armor = total_final
	var vital_mult: float = 1.0
	# IV-10: vital_mult is a sub-region-dependent mechanical multiplier; gate behind the same flag
	# as combat_mult so that flag-OFF means sub-regions cannot affect mechanical damage.
	# Also skip on joule-authoritative path — the KE fraction is the sole determinant of mech damage.
	if not joule_authoritative and CombatConstants.is_feature_subregion_combat_mult_enabled():
		vital_mult = BleedingConstants.get_vital_damage_multiplier(part, sub_region, extras.get("attack_line", ""))
	if vital_mult != 1.0:
		final_cut *= vital_mult
		final_blunt *= vital_mult
		total_final = final_cut + final_blunt
		mechanical_post_armor = total_final
	# NOTE: skull cut-absorption is applied to the ALLOCATED cut tissue (to_cut) after the mechanism is
	# determined (see below), NOT here on final_cut. Reducing final_cut pre-allocation would lower cut_share
	# and flip the mechanism sharp->mixed/blunt, corrupting bone allocation (a sword cut would then dump most
	# of its energy into the skull bone). The mechanism must reflect how the weapon struck, not the skull.
	var pen_to_tissue: float = 0.0
	if final_cut > 0.0:
		pen_to_tissue = pen_s
		if armor_var != null and armor_var.get_script() == ArmorPiece:
			var pen_trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(armor_var, pen_s)
			pen_to_tissue = pen_trace.get("penetration_to_tissue_mm", 0.0)
			if joule_authoritative and "transmitted_ke_fraction" in joule_ke:
				var ke_frac: float = maxf(joule_ke["transmitted_ke_fraction"], 0.01)
				pen_to_tissue *= ke_frac
	var pen_for_mfb: float = pen_to_tissue
	var layer_meta: Dictionary = {}
	var force_layer: bool = extras.get("force_layer_tissue", false)
	var force_layer_curves: bool = extras.get("force_layer_tissue_curves", false)
	if (
		final_cut > 0.0
		and not extras.get("disable_layer_tissue", false)
		and CombatLayerTissue.is_layer_penetration_active(force_layer, force_layer_curves)
	):
		if (
			CombatLayerTissue.is_curves_active(force_layer_curves)
			and not extras.get("disable_layer_tissue_curves", false)
		):
			var state_rows: Array = _layer_state_rows_for_part(entity, part)
			layer_meta = CombatLayerTissue.penetration_through_layers(part, pen_to_tissue, state_rows, true)
			if layer_meta.has("layer_state") and "tissue_layer_state" in entity:
				entity.tissue_layer_state[part] = layer_meta["layer_state"]
		else:
			layer_meta = CombatLayerTissue.penetration_after_soft_tissue(part, pen_to_tissue, true)
		pen_for_mfb = float(layer_meta.get("penetration_to_bone_mm", pen_to_tissue))
	# KE that physically reaches the body after armor absorption. The bone-fracture gates (sharp J-anchor
	# + blunt tissue-budget) must be driven by this, not the weapon's pre-armor KE: otherwise a cuirass caps
	# fracture magnitude (via the final_blunt share + ke_frac) yet the full pre-armor energy still clears the
	# fracture threshold — armor limits HOW MUCH bone breaks, not WHETHER the mechanism fires. On the
	# joule-authoritative path the running budget remainder is the transmitted KE; on every other path
	# (no armor, or the legacy scalar path) the weapon KE is the best available estimate.
	var body_ke_j: float = impact_ke
	if joule_authoritative:
		body_ke_j = maxf(0.0, float(joule_ke.get("armor_ke_remaining_j", impact_ke)))
	var ke_blunt_bone: float = CombatLayerTissue.blunt_ke_reaching_bone(part, body_ke_j)
	var mfb_alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(
		final_cut, final_blunt, total_final, part, sub_region, pen_for_mfb, body_ke_j, ke_blunt_bone, entity.bone_max.get(part, 0)
	)
	var alloc: Dictionary = mfb_alloc
	var force_curves: bool = extras.get("force_material_curves", false)
	var curve_alloc: Dictionary = {}
	if MaterialFailureCurves.is_active(force_curves):
		curve_alloc = MaterialFailureCurves.allocate_bone_and_tissue(
			final_cut, final_blunt, total_final, part, sub_region, pen_to_tissue, pen_for_mfb, body_ke_j, ke_blunt_bone
		)
		var blend_w: float = float(
			extras.get("material_curve_blend_weight", BleedingConstants.MATERIAL_CURVE_BLEND_WEIGHT)
		)
		alloc = MaterialFailureCurves.blend_allocations(mfb_alloc, curve_alloc, blend_w)
	var wound_pen_mm: float = -1.0
	if final_cut > 0.0:
		wound_pen_mm = pen_to_tissue
	var to_tissue_total: float = float(alloc.get("to_tissue_total", total_final))
	var to_bone: float = alloc.get("to_bone", 0.0)
	var to_cut: float = alloc.get("to_cut", 0.0)
	var to_blunt: float = alloc.get("to_blunt", 0.0)
	# CAMP-SCAR-1: a scarred part takes more incoming damage (scarred tissue re-injures / is less elastic).
	# Applied to the allocated cut+blunt tissue, before the severance-ease cap. Bone untouched.
	if entity.has_method("_get_scar_damage_mult"):
		var scar_dm: float = entity._get_scar_damage_mult(part)
		to_cut *= scar_dm
		to_blunt *= scar_dm
	# Skull vault gating for head cuts: the dense ~7mm vault must be breached before a cut can damage the
	# neurologic/brain TISSUE pool. Breach means the blade reached the vault this hit (sharp tissue
	# penetration >= HEAD_SKULL_BREACH_PEN_MM or bone damage) or the skull is already broken. Until then
	# a head cut is a scalp laceration — it bleeds (wound recorded at full magnitude below) but cannot
	# exhaust the brain pool, so repeated soft scalping can no longer "destroy head tissue" (issue: DAGGER
	# "head destruction" at 17-29J). A breached cut transmits HEAD_SKULL_CUT_TRANSMISSION of its damage
	# into the brain pool. Mechanism (sharp/blunt) and skull bone allocation are unaffected.
	# The gate runs only when the strike is a BLADE deliverer — mechanism sharp or mixed (to_cut > 0 and the
	# allocation did not classify blunt-dominant). A non-breaching blade must not drain the HEAD-POOL through
	# its cut channel NOR its accompanying blunt share: a stopped edge rattles the skull (modeled by the
	# rotational concussion channel / pain-shock, not the brain tissue pool), so both to_cut AND to_blunt are
	# zeroed. Blunt-dominant strikes (mace/pommel) allocate ONLY a vestigial cut under the 85% blunt share
	# (e.g. cut=0.08 alongside blunt=10.00) — checking to_cut alone would misfire on them and park their
	# legitimate crush. Mechanism "blunt" therefore skips the gate and still crushes the head pool without
	# needing to breach — mace head trauma is preserved.
	var head_strike_mechanism: String = str(alloc.get("mechanism", "mixed"))
	var head_cut_wound_value: float = to_cut
	if part == BodyPartConstants.PART_HEAD and to_cut > 0.0 and head_strike_mechanism != "blunt":
		var skull_breached_this_hit: bool = (
			to_bone > 0.0 or pen_to_tissue >= BleedingConstants.HEAD_SKULL_BREACH_PEN_MM
		)
		if skull_breached_this_hit or entity.bone_health.get(part, 0.0) <= 0.0:
			to_cut *= BleedingConstants.HEAD_SKULL_CUT_TRANSMISSION
		else:
			to_cut = 0.0
			to_blunt = 0.0
	var mechanism_raw: String = str(alloc.get("mechanism", "mixed"))
	var mfb_mechanism: String = str(mfb_alloc.get("mechanism", mechanism_raw))
	var applied_mechanism: String = mechanism_raw
	var bone_threshold: int = BodyPartConstants.get_bone_damage_threshold(part, sub_region)
	var bone_fraction: float = BodyPartConstants.get_bone_damage_fraction(part, sub_region)
	var severance_ease: float = get_severance_ease_factor(entity, part)
	var cur_cut: float = entity.body_cutting.get(part, 0.0)
	var cur_blunt: float = entity.body_blunt.get(part, 0.0)
	var cur_bone: float = entity.bone_health.get(part, 0.0)
	var allocated_bone: float = to_bone
	# J-pool authority. The tissue display pools (body_cutting/body_blunt) are a 50/50 DERIVED
	# VIEW of one shared J reservoir per part (TissueEnergyCapacity). Capping each channel
	# against its own drained display stops a blunt-dominant weapon (mace) dead after one full
	# crush while the reservoir still holds ~50% — the 51-80-strike grind. Cap the tissue SUM
	# against the reservoir's remaining display instead; a drained channel releases its credit
	# to the sibling channel in the debit below.
	var energy_pool_force: bool = extras.get("force_tissue_energy_pool", false)
	var use_energy_pool: bool = (
		TissueEnergyCapacity.is_active(energy_pool_force)
		and not extras.get("disable_tissue_energy_pool", false)
	)
	# Per-channel ease cap prevents amplification from zeroing multiple channels.
	# When base allocation already zeros a channel (to_X >= cur_X), use ease=1.0 for that
	# channel — the hit is lethal regardless of wound factor. Otherwise, dampen the global
	# severance_ease so moderate hits can't zero two+ channels through amplification alone:
	# local_ease = 1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP.
	var cut_ease: float = 1.0 if to_cut >= cur_cut else clampf(1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP, 1.0, severance_ease)
	var blunt_ease: float = 1.0 if to_blunt >= cur_blunt else clampf(1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP, 1.0, severance_ease)
	var bone_ease: float = 1.0 if to_bone >= cur_bone else clampf(1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP, 1.0, severance_ease)
	if use_energy_pool:
		# The J reservoir (translated back to display points) is the real remaining tissue.
		# A single shared reservoir authority replaces the per-channel display caps: a mace
		# (blunt-dominant) can now keep crushing a part instead of parking at the 50% line
		# once its blunt display half is spent. Channel ease still applies so amplification
		# doesn't over-spend the reservoir; each channel clamps against the reservoir total.
		var reservoir_display: float = TissueEnergyCapacity.display_total_from_remaining_j(
			int(entity.body_max.get(part, 1)),
			entity.tissue_energy_remaining_j.get(part, 0.0),
			entity.tissue_energy_capacity_j.get(part, 0.0),
		)
		to_cut = entity._round_tissue(to_cut * cut_ease)
		to_blunt = entity._round_tissue(to_blunt * blunt_ease)
		var tissue_spend: float = to_cut + to_blunt
		if tissue_spend > reservoir_display:
			var spend_scale: float = maxf(0.0, reservoir_display / tissue_spend)
			to_cut = entity._round_tissue(to_cut * spend_scale)
			to_blunt = entity._round_tissue(to_blunt * spend_scale)
	else:
		to_cut = minf(entity._round_tissue(to_cut * cut_ease), cur_cut)
		to_blunt = minf(entity._round_tissue(to_blunt * blunt_ease), cur_blunt)
	to_bone = minf(entity._round_tissue(to_bone * bone_ease), cur_bone)
	# Channel debit targets. Non-pool path caps each channel against its own display.
	# Pool path spills overflow into the sibling channel: one shared J reservoir per part,
	# so a blunt-dominant weapon (mace) that has already spent the blunt display half keeps
	# crushing the cutting display instead of parking at 50%. Wounds were recorded above
	# from the raw to_cut/to_blunt, so only the display debit is re-routed.
	var debit_cut: float = to_cut
	var debit_blunt: float = to_blunt
	if use_energy_pool:
		if debit_blunt > cur_blunt:
			var blunt_overflow: float = debit_blunt - cur_blunt
			debit_blunt = cur_blunt
			debit_cut += blunt_overflow
		elif debit_cut > cur_cut:
			var cut_overflow: float = debit_cut - cur_cut
			debit_cut = cur_cut
			debit_blunt += cut_overflow
	var total_damage_this_hit: float = to_cut + to_blunt + to_bone
	var channel_cut_drain: float = debit_cut
	var channel_bone_drain: float = to_bone
	if (
		total_damage_this_hit < _get_severance_threshold_for_part_entity_aware(entity, part)
		and (cur_cut - channel_cut_drain) <= 0.0
		and (cur_bone - channel_bone_drain) <= 0.0
		and cur_bone > 0.0
	):
		var bone_floor: float = maxf(0.1, float(entity.bone_max.get(part, 6)) * 0.15)
		to_bone = maxf(0.0, cur_bone - entity._round_tissue(bone_floor))
	if use_energy_pool:
		TissueEnergyCapacity.apply_tissue_damage_to_entity(entity, part, debit_cut, debit_blunt)
		entity.bone_health[part] = entity._round_tissue(maxf(0.0, entity.bone_health.get(part, 0.0) - to_bone))
	else:
		entity.body_cutting[part] = entity._round_tissue(maxf(0.0, entity.body_cutting.get(part, 0.0) - to_cut))
		entity.body_blunt[part] = entity._round_tissue(maxf(0.0, entity.body_blunt.get(part, 0.0) - to_blunt))
		entity.bone_health[part] = entity._round_tissue(maxf(0.0, entity.bone_health.get(part, 0.0) - to_bone))
	var cut_after: float = entity.body_cutting.get(part, 0.0)
	var blunt_after: float = entity.body_blunt.get(part, 0.0)
	var bone_after: float = entity.bone_health.get(part, 0.0)
	if CombatConstants.combat_debug_active():
		(
			CombatDebug
			. log(
				(
					(
                        "[Bone/tissue] %s %s (%s): mechanism=%s%s total_post_armor=%.1f | "
						+ "threshold=%d fraction=%.2f => allocated bone=%.2f tissue=%.2f | "
						+ "severance_ease=%.2f => applied cut=%.2f blunt=%.2f bone=%.2f | "
						+ "part state: cut %.2f->%.2f blunt %.2f->%.2f bone %.2f->%.2f"
					)
					% [
						entity.name,
						part,
						sub_region,
						mfb_mechanism,
						" curve=%s" % applied_mechanism if force_curves else "",
						total_final,
						bone_threshold,
						bone_fraction,
						allocated_bone,
						to_tissue_total,
						severance_ease,
						to_cut,
						to_blunt,
						to_bone,
						cur_cut,
						cut_after,
						cur_blunt,
						blunt_after,
						cur_bone,
						bone_after,
					]
				)
			)
		)
	# Stab wounds use INJURY_TYPE_STAB (narrow deep channel; forensic: stab:cut external bleed ratio ~1:2-3).
	var contact_type: String = extras.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)
	var wound_extras: Dictionary = {}
	if weapon_type == "DAGGER":
		wound_extras["dagger_wound"] = true
	if to_cut > 0.0 or head_cut_wound_value > 0.0:
		# Head cuts bleed at full scalp magnitude regardless of the skull-vault gating: the vault absorbs
		# deep-cavity transmission into the brain pool, not the external scalp laceration that hemorrhages.
		var wound_cut_value: float = head_cut_wound_value if part == BodyPartConstants.PART_HEAD else to_cut
		var injury_type_for_wound: String = (
			BleedingConstants.INJURY_TYPE_STAB if contact_type == WeaponConstants.ATTACK_TYPE_STAB else BleedingConstants.INJURY_TYPE_CUT
		)
		EntityWounds.add_wound(entity, part, injury_type_for_wound, wound_cut_value, sub_region, "", body_ke_j, wound_pen_mm, wound_extras)
		# Torso thrusts can open a slow internal-organ bleed (forensic: stabs penetrate deeper and reach
		# organs surface cuts miss). A separate unclottable wound so it doesn't merge with the external stab.
		# Chance scales with penetration depth (a shallow thrust can't reach the organ plane). Dedicated RNG
		# (seeded from entity+part+game-time) so the roll is deterministic per run and varies per thrust
		# WITHOUT consuming the global RNG sequence (which would shift seeded soak-test outcomes).
		if contact_type == WeaponConstants.ATTACK_TYPE_STAB and part == BodyPartConstants.PART_CHEST:
			var ib_chance: float = BleedingConstants.internal_bleed_chance_torso_thrust(wound_pen_mm)
			if ib_chance > 0.0:
				var ib_seed: int = hash(
					"%s:%s:%d" % [entity.name, part, int(float(entity._game_time_seconds) * 1000.0)]
				)
				var ib_rng := RandomNumberGenerator.new()
				ib_rng.seed = ib_seed
				if ib_rng.randf() < ib_chance:
					EntityWounds.add_wound(
						entity, part, BleedingConstants.INJURY_TYPE_INTERNAL_BLEED, 1.0, sub_region,
						BleedingConstants.internal_bleed_severity_for_penetration(wound_pen_mm), body_ke_j, wound_pen_mm, {}
					)
	if to_blunt > 0.0:
		var total_blunt_source: float = blunt_from_deflection + blunt_from_direct
		var to_blunt_deflected: float = 0.0
		var to_blunt_direct: float = to_blunt
		if total_blunt_source > 0.0 and blunt_from_deflection > 0.0:
			to_blunt_deflected = to_blunt * blunt_from_deflection / total_blunt_source
			to_blunt_direct = to_blunt - to_blunt_deflected
		if to_blunt_deflected > 0.0:
			var sev: String = EntityWounds.severity_from_damage(entity, part, to_blunt_deflected, sub_region, body_ke_j)
			if to_blunt_deflected <= float(DEFLECTION_BRUISE_THRESHOLD) or sev == BleedingConstants.SEVERITY_MINOR:
				EntityWounds.add_wound(
					entity, part, BleedingConstants.INJURY_TYPE_BRUISE, to_blunt_deflected, sub_region, "", body_ke_j
				)
			else:
				EntityWounds.add_wound(
					entity, part, BleedingConstants.INJURY_TYPE_CRUSH, to_blunt_deflected, sub_region, "", body_ke_j
				)
		if to_blunt_direct > 0.0:
			EntityWounds.add_wound(
				entity, part, BleedingConstants.INJURY_TYPE_CRUSH, to_blunt_direct, sub_region, "", body_ke_j
			)
	# Blunt internal organ trauma (visceral injury without penetration): high-KE BLUNT strikes to
	# thoracic/abdominal regions can rupture organs even when no sharp penetration path exists. This
	# is a BLUNT-mechanism injury (crush/contusion), so it only applies to non-sharp-dominant strikes
	# (blunt/mixed): a sharp-dominant cut lacerates rather than contuses, and its organ damage flows
	# through the sharp channel. Plate armor TRANSMITS blunt force, so organ injury is driven by the
	# KE that reaches the body (body_ke_j), not the weapon's pre-armor KE: a cuirass reduces the risk
	# but a hard mace blow through plate still risks liver/rib/organ trauma. A fully absorbed glancing
	# blow passes ~0 J and correctly produces none.
	var organ_trauma: Dictionary = {}
	if mechanism_raw != "sharp":
		organ_trauma = CombatDamageMechanism.check_blunt_internal_organ_trauma(
			part, sub_region, body_ke_j, pen_to_tissue
		)
	if not organ_trauma.get("trauma_type", "").is_empty() and organ_trauma.get("organ_blunt_dmg", 0.0) > 0.0:
		var extra_blunt: float = organ_trauma["organ_blunt_dmg"]
		entity.body_blunt[part] = entity._round_tissue(maxf(0.0, entity.body_blunt.get(part, 0.0) - extra_blunt))
		to_blunt += extra_blunt
		total_damage_this_hit += extra_blunt
		# Create an unclottable internal-bleed wound so ruptured organs sustain continuous
		# blood loss independent of the crush-wound path.
		var ib_severity: String
		match organ_trauma["trauma_type"]:
			"aortic_trauma":
				ib_severity = BleedingConstants.SEVERITY_CRITICAL
			"liver_spleen_tear":
				ib_severity = BleedingConstants.SEVERITY_SEVERE
			_:
				ib_severity = BleedingConstants.SEVERITY_MODERATE
		EntityWounds.add_wound(
			entity, part, BleedingConstants.INJURY_TYPE_INTERNAL_BLEED, 1.0, sub_region,
			ib_severity, body_ke_j, 0.0, {}
		)
		if CombatConstants.combat_debug_active():
			CombatDebug.log(
				"[OrganTrauma] %s %s (%s): %s KE=%.1fJ => +%.1f blunt, internal_bleed=%s (visceral injury)"
					% [entity.name, part, sub_region, organ_trauma["trauma_type"], body_ke_j, extra_blunt, ib_severity]
			)
	if to_bone > 0.0:
		var fracture_severity: String = EntityWounds.severity_from_bone_damage(entity, part, to_bone)
		EntityWounds.add_wound(
			entity, part, BleedingConstants.INJURY_TYPE_FRACTURE, to_bone, sub_region, fracture_severity, body_ke_j
		)
	# Intracranial hemorrhage: a head wound that breaches the skull (fracture or deep sharp penetration)
	# opens an internal, unclottable bleed distinct from external scalp laceration. Field pressure
	# cannot stop it; it progresses over time and is only treatable via evacuation/surgery.
	var head_skull_breached: bool = part == BodyPartConstants.PART_HEAD and (
		to_bone > 0.0 or (to_cut > 0.0 and pen_to_tissue >= BleedingConstants.HEAD_SKULL_BREACH_PEN_MM)
	)
	if head_skull_breached:
		var ic_chance: float = BleedingConstants.internal_bleed_chance_head_skull_damage(to_bone)
		if ic_chance <= 0.0 and to_cut > 0.0 and pen_to_tissue >= BleedingConstants.HEAD_SKULL_BREACH_PEN_MM:
			ic_chance = BleedingConstants.HEAD_INTRACRANIAL_BLEED_MAX_CHANCE * 0.5
		if ic_chance > 0.0:
			var ic_seed: int = hash("%s:%s:%d" % [entity.name, "ic_bleed", int(float(entity._game_time_seconds) * 1000.0)])
			var ic_rng := RandomNumberGenerator.new()
			ic_rng.seed = ic_seed
			if ic_rng.randf() < ic_chance:
				var ic_severity: String = BleedingConstants.internal_bleed_severity_head_skull_damage(to_bone, pen_to_tissue)
				EntityWounds.add_wound(
					entity, part, BleedingConstants.INJURY_TYPE_INTERNAL_BLEED, 1.0, sub_region,
					ic_severity, body_ke_j, pen_to_tissue, {"intracranial": true}
				)
				if CombatConstants.combat_debug_active():
					CombatDebug.log(
						"[IntracranialBleed] %s %s: skull breached (to_bone=%.1f pen=%.1fmm) severity=%s chance=%.2f"
						% [entity.name, part, to_bone, pen_to_tissue, ic_severity, ic_chance]
					)
	# Concussion from head impact (Issue 1 + rotational channel). Two physical mTBI mechanisms, both
	# anchored to the calibrated fracture-energy reference (CombatDamageMechanism.blunt_fracture_j_anchor):
	#  - LINEAR (bone impulse): KE that reaches the skull bone cracks it / imparts linear acceleration.
	#    A concussion is caused by the impact impulse on the brain at energies well below those that
	#    fracture the skull, so it gates on ke_blunt_bone > 0, NOT to_bone > 0 (the sqrt(J) bone formula +
	#    45% blunt-share cap caps head bone at ~1-1.5 units, so allocated_bone/8 never reached the 1.2
	#    threshold and the to_bone>0 gate was dead code). Fires on committed blows that reach the skull.
	#  - ROTATIONAL (head spin): total KE transmitted to the head spins it. Rowson/Duma: rotational
	#    acceleration, not linear, is the dominant TBI/diffuse-axonal-injury predictor, so this catches
	#    glancing or scalp-absorbed blows that spin the head without reaching the bone (sub-fracture
	#    rotational mTBI the linear bone gate misses). Driven by transmitted head KE; I_head/dt/share
	#    cancel out of the fracture-anchored gate, so the trigger is transmitted-head-KE in the 0.75-1.5x
	#    fracture-energy band, mirroring the linear channel.
	if part == BodyPartConstants.PART_HEAD and body_ke_j > 0.0:
		var fracture_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor(part, sub_region)
		if fracture_anchor > 0.0:
			# A single impact is ONE mTBI event. Fire the LINEAR (bone-impulse) channel when it clears the
			# onset ratio; otherwise fall back to the ROTATIONAL channel to catch sub-fracture glancing blows
			# that spin the head below the bone-impulse onset. Firing both on the same hit would double-count
			# the cumulative counter and accelerate Second-Impact escalation beyond a single impact.
			var transmitted_ratio: float = ke_blunt_bone / fracture_anchor if ke_blunt_bone > 0.0 else 0.0
			if transmitted_ratio >= EntityPainConsciousness.CONCUSSION_BONE_THRESHOLD_MIN:
				EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(entity, transmitted_ratio)
			else:
				# Rotational: alpha from the KE that actually reaches the head — body_ke_j, the same
				# post-armor transmitted energy the bone/organ gates use (armor absorbs the rest). This
				# includes the scalp/tissue KE the bone channel's `ke_blunt_bone` subtracts away. Gated
				# against fracture-energy-anchored thresholds. No-armor: body_ke_j == impact_ke.
				var transmitted_head_ke: float = body_ke_j
				if transmitted_head_ke > 0.0:
					var alpha_head: float = EntityPainConsciousness.head_rotational_accel_rad_s2(transmitted_head_ke)
					var alpha_thr: Array = EntityPainConsciousness.rotational_alpha_thresholds_for_fracture_anchor(fracture_anchor)
					EntityPainConsciousness.try_enter_concussion_from_rotation(entity, alpha_head, alpha_thr[0], alpha_thr[1])
	# Record the mechanism+physics profile of head strikes (replaces the single blunt-KE scalar) so
	# downstream tuning classification can tell a penetrating sharp wound from blunt TBI and gradual crush.
	# body_ke_j is the KE reaching the head (a helmet/plate reduces it); bone/penetration flags the breach.
	if part == BodyPartConstants.PART_HEAD and body_ke_j > 0.0 and (to_cut > 0.0 or to_blunt > 0.0):
		_record_head_strike_profile(entity, body_ke_j, mfb_mechanism, pen_to_tissue, to_bone)
	var early_severed: bool = false
	var part_sever_threshold: float = _get_severance_threshold_for_part_entity_aware(entity, part)
	if not entity._is_part_severed(part) and total_damage_this_hit >= part_sever_threshold:
		if not SEVERANCE_EARLY_LIMBS_ONLY or part not in entity._get_vital_parts():
			var max_cut: int = entity.body_max.get(part, 1)
			var max_bone: int = entity.bone_max.get(part, 1)
			var rem_cut: float = entity.body_cutting.get(part, 0.0)
			var rem_bone: float = entity.bone_health.get(part, 0.0)
			var combined_max: float = float(max_cut + max_bone)
			if combined_max > 0.0:
				var remaining_ratio: float = (rem_cut + rem_bone) / combined_max
				if remaining_ratio < SEVERANCE_EARLY_THRESHOLD and remaining_ratio > 0.0:
					var chance: float = (
						(SEVERANCE_EARLY_THRESHOLD - remaining_ratio)
						/ SEVERANCE_EARLY_THRESHOLD
						* SEVERANCE_EARLY_MAX_CHANCE
					)
					chance = clampf(chance, 0.0, 1.0)
					if randf() < chance:
						# Fold the destroyed remainder into the applied allocation so the
						# reported final_cut/final_blunt/final_bone match what was actually
						# lost from the part (previously the remainder vanished from logs).
						to_cut += entity.body_cutting.get(part, 0.0)
						to_blunt += entity.body_blunt.get(part, 0.0)
						to_bone += entity.bone_health.get(part, 0.0)
						entity.body_cutting[part] = 0.0
						entity.body_blunt[part] = 0.0
						entity.bone_health[part] = 0.0
						early_severed = true
						total_damage_this_hit = to_cut + to_blunt + to_bone
						# Keep the head-strike profile current even when early severance zeroes the part.
						if part == BodyPartConstants.PART_HEAD and body_ke_j > 0.0:
							_record_head_strike_profile(entity, body_ke_j, mfb_mechanism, pen_to_tissue, to_bone)
						# Sync J reservoir after early severance zeroing (prevents stale J after display reset).
						if "tissue_energy_capacity_j" in entity and "tissue_energy_remaining_j" in entity:
							var body_max_t: int = clampi(int(entity.body_max.get(part, 10)), 1, 999)
							var cap_j: float = float(entity.tissue_energy_capacity_j.get(part, 0.0))
							if cap_j > 0.01:
								entity.tissue_energy_remaining_j[part] = TissueEnergyCapacity.remaining_j_from_display_pools(
									body_max_t,
									entity.body_cutting.get(part, 0.0),
									entity.body_blunt.get(part, 0.0),
									cap_j,
								)
						CombatDebug.log(
							(
								(
                                    "[Severance] %s %s: early severance triggered "
									+ "(remaining ratio < threshold) => part destroyed "
									+ "(applied cut=%.1f blunt=%.1f bone=%.1f)"
								)
								% [entity.name, part, to_cut, to_blunt, to_bone]
							)
						)
	if entity._is_part_severed(part):
		EntityWounds.ensure_stump_wound(entity, part, sub_region)
	# Vital destruction: death is deferred to the is_dead() grace countdown. Initialize the
	# countdown here (the moment the vital tissue/bone is destroyed) so is_dead() returns
	# false during the grace; the per-tick death check registers the kill once it elapses.
	# The entity is incapacitated (consciousness capped) immediately via
	# is_vital_part_destroyed() in update_consciousness.
	# Use the same "vital destroyed" predicate that drives is_dead() and the consciousness cap
	# (entity._is_vital_part_destroyed) so the grace trigger, death path, and incapacitation can
	# never drift apart. Initialize the countdown the moment a vital is destroyed; do not extend
	# it on subsequent hits (the grace started at the first destruction).
	if entity._is_vital_part_destroyed(part):
		if entity._vital_grace_remaining < 0.0:
			var grace_s: float = CoreEntity.vital_grace_period_for_part(part)
			entity._vital_grace_remaining = grace_s
			CombatDebug.combat_session("VITAL_GRACE %s %s destroyed grace=%.1fs" % [entity.name, part, grace_s])
	var pain_from_this_hit_raw: float = 0.0
	if entity._is_part_severed(part):
		var stump_damage: float = entity.body_max.get(part, 10)
		pain_from_this_hit_raw = entity._get_pain_contribution_for_wound(
			part, stump_damage, BleedingConstants.SEVERITY_CRITICAL, BleedingConstants.INJURY_TYPE_CUT, sub_region,
			true, wound_pen_mm
		)
	else:
		if to_cut > 0.0:
			var sev_cut: String = EntityWounds.severity_from_damage(entity, part, to_cut, sub_region, body_ke_j)
			pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
				part, to_cut, sev_cut, BleedingConstants.INJURY_TYPE_CUT, sub_region, false, wound_pen_mm
			)
		if to_blunt > 0.0:
			var total_blunt_source: float = blunt_from_deflection + blunt_from_direct
			var to_blunt_deflected: float = 0.0
			var to_blunt_direct: float = to_blunt
			if total_blunt_source > 0.0 and blunt_from_deflection > 0.0:
				to_blunt_deflected = to_blunt * blunt_from_deflection / total_blunt_source
				to_blunt_direct = to_blunt - to_blunt_deflected
			if to_blunt_deflected > 0.0:
				var sev_def: String = EntityWounds.severity_from_damage(
					entity, part, to_blunt_deflected, sub_region, body_ke_j
				)
				var itype_def: String = (
					BleedingConstants.INJURY_TYPE_BRUISE
					if (
						to_blunt_deflected <= float(DEFLECTION_BRUISE_THRESHOLD)
						or sev_def == BleedingConstants.SEVERITY_MINOR
					)
					else BleedingConstants.INJURY_TYPE_CRUSH
				)
				pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
					part, to_blunt_deflected, sev_def, itype_def, sub_region, false
				)
			if to_blunt_direct > 0.0:
				var sev_dir: String = EntityWounds.severity_from_damage(
					entity, part, to_blunt_direct, sub_region, body_ke_j
				)
				pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
					part, to_blunt_direct, sev_dir, BleedingConstants.INJURY_TYPE_CRUSH, sub_region, false
				)
		if to_bone > 0.0:
			var sev_bone: String = EntityWounds.severity_from_bone_damage(entity, part, to_bone)
			pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
				part, to_bone, sev_bone, BleedingConstants.INJURY_TYPE_FRACTURE, sub_region, false
			)
	# Add pain for blunt organ trauma (visceral nociceptors produce disproportionately severe pain).
	if organ_trauma.has("organ_pain_mult") and organ_trauma["organ_pain_mult"] > 1.0:
		var organ_sev: String = EntityWounds.severity_from_damage(entity, part, organ_trauma.get("organ_blunt_dmg", 0.0), sub_region, body_ke_j)
		pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
			part, organ_trauma["organ_blunt_dmg"], organ_sev, BleedingConstants.INJURY_TYPE_CRUSH, sub_region, false
		)
	entity._last_hit_impact = float(total_damage_this_hit)
	entity._try_enter_pain_shock_from_hit(pain_from_this_hit_raw)
	entity._update_consciousness()
	# was_deflected: scalar path flags it when the edge was stopped by a rigid layer
	# (blunt_from_deflection > 0). The joule path (live) tracks the same sharp->blunt
	# conversion internally and surfaces it as "was_deflected" in the KE result.
	var hit_was_deflected: bool = (blunt_from_deflection > 0.0) or bool(joule_ke.get("was_deflected", false))
	var result: Dictionary = {
		"final_cut": to_cut,
		"final_blunt": to_blunt,
		"final_bone": to_bone,
		"was_deflected": hit_was_deflected,
		"mechanical_post_armor": mechanical_post_armor,
		"mech_trauma_mult": trauma_mult,
		"mech_subregion_mult": combat_mult,
		"early_severed": early_severed,
	}
	if not joule_ke.is_empty():
		result["armor_ke_absorbed_j"] = joule_ke.get("armor_ke_absorbed_j", 0.0)
		result["armor_ke_remaining_j"] = joule_ke.get("armor_ke_remaining_j", 0.0)
		result["transmitted_ke_fraction"] = joule_ke.get("transmitted_ke_fraction", 1.0)
	if final_cut > 0.0:
		result["penetration_to_tissue_mm"] = pen_to_tissue
	if not layer_meta.is_empty():
		result["layer_absorbed_mm"] = layer_meta.get("layer_absorbed_mm", 0.0)
		result["penetration_to_bone_mm"] = float(layer_meta.get("penetration_to_bone_mm", pen_for_mfb))
		if layer_meta.has("layer_states"):
			result["layer_states"] = layer_meta["layer_states"]
	if use_energy_pool and entity.tissue_energy_remaining_j.has(part):
		result["tissue_energy_remaining_j"] = entity.tissue_energy_remaining_j.get(part, 0.0)
		result["tissue_energy_capacity_j"] = entity.tissue_energy_capacity_j.get(part, 0.0)
	if force_curves and not curve_alloc.is_empty():
		result["mfb_cut"] = mfb_alloc.get("to_cut", 0.0)
		result["mfb_blunt"] = mfb_alloc.get("to_blunt", 0.0)
		result["mfb_bone"] = mfb_alloc.get("to_bone", 0.0)
		result["curve_cut"] = curve_alloc.get("to_cut", 0.0)
		result["curve_blunt"] = curve_alloc.get("to_blunt", 0.0)
		result["curve_bone"] = curve_alloc.get("to_bone", 0.0)
	CombatF5SoakTrace.note_research_damage_outcome(part, result, extras)
	# Record this hit for cumulative trauma tracking on the same body region.
	if total_damage_this_hit > 0.0:
		_record_cumulative_trauma_hit(entity, part)
	return result


static func _get_severance_threshold_for_part(part: String) -> float:
	"""Returns minimum damage to attempt severance for a specific body part.
	Traumatic blade amputation is biomechanically impossible — real dismemberment requires bone fracture + massive force
	from blast/impaction trauma, not cutting weapons. Extremities (arms/legs) have highest thresholds."""
	if SEVERANCE_MIN_DAMAGE_BY_PART.has(part):
		return float(SEVERANCE_MIN_DAMAGE_BY_PART[part])
	return float(MIN_DAMAGE_TO_SEVER)


static func _get_severance_threshold_for_part_entity_aware(entity: Node, part: String) -> float:
	"""Returns minimum damage to attempt severance for a specific body part, scaled by species tissue budget.
	Scales thresholds proportionally so smaller species don't require human-scale damage to trigger severance."""
	var base_threshold: float = _get_severance_threshold_for_part(part)
	if entity == null or not ("body_max" in entity):
		return base_threshold
	var ref_tissue: float = SEVERANCE_REFERENCE_TISSUE_BY_PART.get(part, 10.0)
	var cur_tissue: float = float(entity.body_max.get(part, int(ref_tissue)))
	if ref_tissue <= 0.0:
		return base_threshold
	var scale: float = cur_tissue / ref_tissue
	return base_threshold * scale


## Meta key for the mechanism-aware head-strike profile (see _record_head_strike_profile). Read by
## tools/combat_tuning/CombatTuningMain._infer_end_cause to classify head deaths by physics + mechanism.
const HEAD_STRIKE_PROFILE_META: String = "_head_strike_prof"


## Records the highest-KE head-strike profile for death-cause classification. Replaces the old single
## blunt-KE scalar (_last_hit_blunt_ke_j) which could not distinguish a penetrating sharp wound from a
## blunt TBI or gradual crush. Profile fields: max_ke_j / mechanism / pen_mm / to_bone of the worst-KE
## strike, skull_breached (true if ANY head strike breached the vault), and sharp_penetrated (true if a
## sharp/mixed strike breached the vault — a focal-pressure P=F/A kill possible at any KE). body_ke_j is
## the post-armor KE reaching the head, so helmet/plate armor correctly reduces the classified trauma.
static func _record_head_strike_profile(
	entity: Node, body_ke_j: float, mfb_mechanism: String, pen_to_tissue: float, to_bone: float
) -> void:
	if entity == null:
		return
	var prof: Dictionary = entity.get_meta(HEAD_STRIKE_PROFILE_META, {})
	var skull_breached_this_hit: bool = to_bone > 0.0 or pen_to_tissue >= BleedingConstants.HEAD_SKULL_BREACH_PEN_MM
	if skull_breached_this_hit:
		prof["skull_breached"] = true
		if mfb_mechanism == "sharp" or mfb_mechanism == "mixed":
			prof["sharp_penetrated"] = true
	if float(prof.get("max_ke_j", 0.0)) < body_ke_j:
		prof["max_ke_j"] = body_ke_j
		prof["mechanism"] = mfb_mechanism
		prof["pen_mm"] = pen_to_tissue
		prof["to_bone"] = to_bone
	entity.set_meta(HEAD_STRIKE_PROFILE_META, prof)
