class_name CombatRegressionHarnessSimulation
extends RefCounted

## Simulation realism track (S1–S10): `_run_sim_*` — docs/LIVE_PATHS.md#harness-prefixes.

const _Weapon := preload("res://weapon/Weapon.gd")
const _WeaponDamage := preload("res://weapon/WeaponDamageHelper.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _WeaponPosition := preload("res://combat/CombatWeaponPosition.gd")
const _HitSubRegion := preload("res://combat/CombatHitSubRegion.gd")
const _PathResolver := preload("res://combat/AttackPathResolver.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _Harness := preload("res://combat/CombatRegressionHarness.gd")
const _DamageMechanism := preload("res://core/CombatDamageMechanism.gd")
const _HumanSpecies := preload("res://species/human.tres")
const _GoblinSpecies := preload("res://species/goblin.tres")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _ArmorJouleBudget := preload("res://core/ArmorJouleBudget.gd")
const _EntityDamage := preload("res://core/EntityDamage.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _CombatLayerTissue := preload("res://core/CombatLayerTissue.gd")
const _ArmorPenetrationTrace := preload("res://armor/ArmorPenetrationTrace.gd")
const _EntityPainConsciousness := preload("res://core/EntityPainConsciousness.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _MaterialFailureCurves := preload("res://core/MaterialFailureCurves.gd")
const _CalibrationAudit := preload("res://combat/CombatCalibrationAudit.gd")
const _TissueEnergyCapacity := preload("res://core/TissueEnergyCapacity.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _ResearchAnchors := preload("res://core/CombatResearchAnchors.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")


static func run(failures: PackedStringArray) -> void:
	_run_sim_delivery_commit_scales_ke_and_cut(failures)
	_run_sim_calibration_audit_committed_ke_in_band(failures)
	_run_sim_subregion_deterministic_same_inputs(failures)
	_run_sim_subregion_high_line_arm(failures)
	_run_sim_pack_neck_requires_subregion(failures)
	_run_sim_mfb_cut_only_no_fracture(failures)
	_run_sim_mfb_mace_arm_fracture(failures)
	_run_sim_mfb_deep_cut_bone_optional(failures)
	_run_sim_severity_absolute_stable(failures)
	_run_sim_severity_ke_still_upgrades(failures)
	_run_sim_derived_production_species_flags(failures)
	_run_sim_derived_limb_capacity_human_arm_reference(failures)
	_run_sim_derived_limb_capacity_human_leg_reference(failures)
	_run_sim_derived_goblin_smaller_limb_than_human(failures)
	_run_sim_derived_goblin_limbs_match_hand_tuned(failures)
	_run_sim_derived_pain_reference_matches_entity_body_max(failures)
	_run_sim_joule_armor_ke_conserved(failures)
	_run_sim_joule_armor_cuirass_absorbs_more_than_gambeson(failures)
	_run_sim_joule_armor_authoritative_ke_frac(failures)
	_run_sim_joule_armor_not_below_ke_frac_floor(failures)
	_run_sim_blood_ml_pool_human_goblin_mass_scale(failures)
	_run_sim_blood_ml_ttd_matches_percent_mode(failures)
	_run_sim_blood_ml_sync_percent_from_ml(failures)
	_run_sim_notify_died_emits_once(failures)
	_run_sim_layer_tissue_shallow_pen_reduces_bone(failures)
	_run_sim_layer_tissue_deep_pen_reaches_bone(failures)
	_run_sim_pen_trace_cuirass_stops_shallow(failures)
	_run_sim_pen_trace_cuirass_deep_reaches_tissue(failures)
	_run_sim_pen_entity_damage_armor_reduces_bone(failures)
	_run_sim_atls_consciousness_class_boundaries(failures)
	_run_sim_atls_consciousness_monotonic(failures)
	_run_sim_depth_shallow_pen_lowers_severity(failures)
	_run_sim_depth_deep_pen_raises_severity(failures)
	_run_sim_blunt_tissue_ke_reduces_fracture(failures)
	_run_sim_depth_deep_pen_raises_arterial_chance(failures)
	_run_sim_layer_stack_two_sheets_absorb_pen(failures)
	_run_sim_layer_tissue_entity_path_reduces_bone(failures)
	_run_mat_curve_monotonic_pen_and_ke(failures)
	_run_mat_curve_matches_mfb_baseline_at_anchor(failures)
	_run_mat_curve_depth_mult_delegates_bleeding(failures)
	_run_mat_entity_curve_matches_hp_baseline_unarmored(failures)
	_run_mat_entity_flag_off_matches_mfb_path(failures)
	_run_mat_armored_pen_reduces_curve_damage(failures)
	_run_mat_layer_yield_stops_shallow_pen(failures)
	_run_mat_layer_rupture_deepens_wound_depth(failures)
	_run_mat_layer_entity_path_reduces_bone(failures)
	_run_mat_layer_flat_budget_unchanged_when_curves_off(failures)
	_run_mat_production_curves_flag_enabled(failures)
	_run_mat_production_layer_tissue_flag_enabled(failures)
	_run_mat_production_layer_curves_flag_enabled(failures)
	_run_mat_production_layer_entity_matches_forced(failures)
	_run_mat_production_layer_curves_entity_matches_forced(failures)
	_run_mat_production_energy_pool_flag_enabled(failures)
	_run_mat_production_energy_pools_seeded(failures)
	_run_mat_production_energy_damage_within_five_pct(failures)
	_run_mat_production_energy_severance_streams_independent(failures)
	_run_mat_production_joule_armor_flag_enabled(failures)
	_run_mat_production_joule_authoritative_matches_forced(failures)
	_run_mat_production_joule_disable_restores_scalar_armor(failures)
	_run_mat_production_literal_blood_ml_flag_enabled(failures)
	_run_mat_production_blood_ml_pools_seeded(failures)
	_run_mat_production_blood_ttd_matches_percent(failures)
	_run_mat_production_blood_sync_tick(failures)
	_run_mat_production_sim_flags_snapshot(failures)
	_run_mat_production_f5_headless_proxies(failures)
	_run_mat_production_deferred_flags_off(failures)
	_run_mat_production_calibration_anchors_locked(failures)
	_run_mat_production_ttd_and_oberhau_unchanged(failures)
	_run_mat_energy_arm_capacity_anchor(failures)
	_run_mat_energy_display_bridge(failures)
	_run_mat_energy_flag_off_no_entity_fields(failures)
	_run_mat_energy_entity_j_path_debits_internal(failures)
	_run_mat_energy_entity_flag_off_matches_display_pools(failures)
	_run_research_clinical_ttd_band(failures)
	_run_research_blood_ml_nominal_70_per_kg(failures)
	_run_research_species_reference_mass_anchors(failures)
	_run_research_reference_bleed_derivation(failures)
	_run_research_atls_class_boundaries(failures)
	_run_research_atls_death_threshold(failures)
	_run_research_blood_loss_multiplier_derived(failures)
	_run_research_arterial_chance_literature(failures)
	_run_research_blunt_anchor_ordering(failures)
	_run_research_committed_ke_hema_band(failures)
	_run_research_direct_pressure_ttd_halving(failures)
	_run_research_bleeding_ladder_monotonic(failures)
	_run_research_pen_depth_monotonic(failures)
	_run_research_clotting_half_life_order(failures)
	_run_research_ml_percent_ttd_parity(failures)
	_run_research_implied_ml_bridge(failures)
	_run_research_goblin_blood_ml_per_kg(failures)
	_run_research_scalp_vs_limb_bleed(failures)
	_run_research_absolute_severity_bands(failures)
	_run_research_pain_human_reference(failures)
	_run_research_pain_hits_to_nrs4(failures)
	_run_research_pain_nrs_thresholds_ordered(failures)
	_run_research_pain_goblin_below_human(failures)
	_run_research_forearm_arterial_epidemiology(failures)
	_run_research_human_chest_largest_segment(failures)
	_run_research_production_full_stack_gate(failures)
	_run_research_tissue_energy_arm_anchor(failures)
	_run_research_normalized_pain_method_b(failures)
	_run_research_derived_limb_species_flags(failures)
	_run_research_blunt_ke_budget_reduces_bone(failures)
	_run_research_atls_blood_consciousness_monotonic(failures)
	_run_research_pain_performance_nrs_bands(failures)
	_run_research_neck_arterial_epidemiology(failures)
	_run_research_medical_triage_thresholds(failures)
	_run_research_triage_danger_seconds_vs_ttd(failures)
	_run_research_joule_sqrt_transmission(failures)
	_run_research_material_curve_full_blend(failures)
	_run_research_gate_registry_count(failures)
	_run_f5_headless_forearm_graze(failures)
	_run_f5_headless_armored_chest(failures)
	_run_f5_headless_mace_elbow(failures)


static func _fail(failures: PackedStringArray, msg: String) -> void:
	_Harness._fail(failures, msg)


static func _oberhau_swing_instance(intensity: float, commit_frac: float) -> AttackInstance:
	var ai: AttackInstance = AttackInstance.new("oberhau", intensity)
	ai.archetype = {"kinematic_delivery": _WeaponConstants.KINEMATIC_DELIVERY_SWING}
	if commit_frac >= 0.0:
		ai.delivery_commit_fraction = commit_frac
	return ai


## S1: extension commit scales KE and pre_armor_cut; intensity ordering at fixed commit.
static func _run_sim_delivery_commit_scales_ke_and_cut(failures: PackedStringArray) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "sim_delivery: missing SWORD")
		return
	const strength: float = 100.0
	const arm_mod: float = 1.0
	const commit_lo: float = 0.45
	const commit_hi: float = 0.90
	var ai_lo: AttackInstance = _oberhau_swing_instance(1.0, commit_lo)
	var ai_hi: AttackInstance = _oberhau_swing_instance(1.0, commit_hi)
	var ke_lo: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_lo)
	var ke_hi: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_hi)
	if ke_hi <= ke_lo + 0.5:
		_fail(
			failures,
			"sim_delivery: commit %.2f KE %.1f should exceed commit %.2f KE %.1f"
			% [commit_hi, ke_hi, commit_lo, ke_lo]
		)
	var cut_lo: float = _WeaponDamage.compute_pre_armor_cut(sword, ai_lo, strength, arm_mod)
	var cut_hi: float = _WeaponDamage.compute_pre_armor_cut(sword, ai_hi, strength, arm_mod)
	if cut_hi <= cut_lo + 0.01:
		_fail(
			failures,
			"sim_delivery: cut commit_hi=%.2f %.2f should exceed commit_lo=%.2f %.2f"
			% [commit_hi, cut_hi, commit_lo, cut_lo]
		)
	const pin_commit: float = 0.78
	var ai_half: AttackInstance = _oberhau_swing_instance(0.5, pin_commit)
	var ai_full: AttackInstance = _oberhau_swing_instance(1.0, pin_commit)
	var ke_half: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_half)
	var ke_full: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_full)
	if ke_full <= ke_half + 0.5:
		_fail(
			failures,
			"sim_delivery: i=1.0 KE %.1f should exceed i=0.5 KE %.1f at commit %.2f"
			% [ke_full, ke_half, pin_commit]
		)
	var ai_no_commit: AttackInstance = _oberhau_swing_instance(1.0, -1.0)
	var ke_no: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_no_commit)
	if ke_no <= ke_full + 0.5:
		_fail(
			failures,
			"sim_delivery: no-commit KE %.1f should exceed committed i=1.0 KE %.1f"
			% [ke_no, ke_full]
		)


## S1: oberhau full wind-up with move commit lands nearer design arm KE than uncommitted i=1.0.
static func _run_sim_calibration_audit_committed_ke_in_band(failures: PackedStringArray) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "sim_audit_ke: missing SWORD")
		return
	var oberhau_commit: float = _WeaponPosition.commit_fraction_from_move_def(_WeaponConstants.get_move("oberhau"))
	var ai_bare: AttackInstance = _oberhau_swing_instance(1.0, -1.0)
	var ai_committed: AttackInstance = _oberhau_swing_instance(1.0, oberhau_commit)
	var ke_bare: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_bare)
	var ke_commit: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_committed)
	if not _DesignAnchors.committed_strike_ke_in_strict_band(ke_commit):
		_fail(
			failures,
			"sim_audit_ke: committed oberhau i=1.0 KE %.0fJ outside 70–140J (commit=%.2f bare=%.0f)"
			% [ke_commit, oberhau_commit, ke_bare]
		)
	var err_bare: float = absf(ke_bare - _DesignAnchors.DESIGN_KE_ARM_J)
	var err_commit: float = absf(ke_commit - _DesignAnchors.DESIGN_KE_ARM_J)
	if err_commit >= err_bare - 1.0:
		_fail(
			failures,
			"sim_audit_ke: committed |KE-%.0f|=%.1f should beat bare %.1f (commit=%.2f bare=%.0f commit=%.0f)"
			% [_DesignAnchors.DESIGN_KE_ARM_J, err_commit, err_bare, oberhau_commit, ke_bare, ke_commit]
		)


## S2: identical inputs yield the same sub_region (no randf on hot path).
static func _run_sim_subregion_deterministic_same_inputs(failures: PackedStringArray) -> void:
	var align: Dictionary = {"attack_angle_deg": 0.0, "guard_angle_deg": 0.0}
	var intercept_idx: int = _PathResolver.path_intercept_max_index("high", "high", 1.0, align)
	var a: String = _HitSubRegion.resolve_sub_region(
		"right_arm", "high", "high", align, "oberhau", intercept_idx
	)
	var b: String = _HitSubRegion.resolve_sub_region(
		"right_arm", "high", "high", align, "oberhau", intercept_idx
	)
	if a.is_empty() or a != b:
		_fail(failures, "sim_subregion_det: want stable non-empty got a=%s b=%s" % [a, b])


## S2: high attack vs high guard on arm path → proximal site (upper_arm).
static func _run_sim_subregion_high_line_arm(failures: PackedStringArray) -> void:
	var align: Dictionary = {"attack_angle_deg": 0.0, "guard_angle_deg": 0.0}
	var intercept_idx: int = _PathResolver.path_intercept_max_index("high", "high", 1.0, align)
	var sub: String = _HitSubRegion.resolve_sub_region(
		"right_arm", "high", "high", align, "oberhau", intercept_idx
	)
	if sub != "upper_arm":
		_fail(
			failures,
			"sim_subregion_high_arm: want upper_arm got %s (intercept=%d)"
			% [sub, intercept_idx]
		)


## S2: packing eligibility still works when neck sub_region is explicit (medical harness pattern).
static func _run_sim_pack_neck_requires_subregion(failures: PackedStringArray) -> void:
	var ent: Node = _Harness._new_entity("SWORD")
	_EntityWounds.add_wound(
		ent, "head", _Bleeding.INJURY_TYPE_CUT, 5.0, "neck", _Bleeding.SEVERITY_MODERATE
	)
	if ent.wounds.get("head", []).size() != 1:
		_fail(failures, "sim_pack_neck: expected one neck wound")
		return
	ent.wounds["head"][0]["is_arterial"] = true
	if not ent.can_apply_packing("head"):
		_fail(failures, "sim_pack_neck: moderate arterial neck should allow packing")


static func _has_fracture_wound(ent: Node, part: String) -> bool:
	for w: Variant in ent.wounds.get(part, []):
		if w is Dictionary and str(w.get("injury_type", "")) == _Bleeding.INJURY_TYPE_FRACTURE:
			return true
	return false


## S3: cut-dominant, low penetration → no fracture (old pool would often chip bone).
static func _run_sim_mfb_cut_only_no_fracture(failures: PackedStringArray) -> void:
	var ent: Node = _Harness._new_entity("SWORD")
	var res: Dictionary = ent.take_damage_split(
		16.0,
		0.0,
		"right_arm",
		0.4,
		-1.0,
		-1.0,
		{"hit_sub_region": "forearm"}
	)
	if _has_fracture_wound(ent, "right_arm") or float(res.get("final_bone", 0.0)) > 0.01:
		_fail(failures, "sim_mfb_cut_low_pen: sharp-dominant low pen should not chip bone")


## S3: blunt-dominant arm hit with KE above sub-region anchor → fracture.
static func _run_sim_mfb_mace_arm_fracture(failures: PackedStringArray) -> void:
	var ent: Node = _Harness._new_entity("MACE")
	var j_anchor: float = _DamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
	var strike_ke: float = j_anchor + 24.0
	var res: Dictionary = ent.take_damage_split(
		0.0,
		8.0,
		"right_arm",
		-1.0,
		-1.0,
		-1.0,
		{"hit_sub_region": "elbow", "strike_ke_j": strike_ke}
	)
	if not _has_fracture_wound(ent, "right_arm") and float(res.get("final_bone", 0.0)) < 0.5:
		_fail(
			failures,
			"sim_mfb_mace_arm: want fracture or final_bone at KE %.1f (anchor %.1f)"
			% [strike_ke, j_anchor]
		)


## S3: deep cut (pen gate) allows bone; shallow pen at same cut damage does not.
static func _run_sim_mfb_deep_cut_bone_optional(failures: PackedStringArray) -> void:
	var shallow: Node = _Harness._new_entity("SWORD")
	var extras_mfb: Dictionary = {
		"hit_sub_region": "forearm",
		"disable_layer_tissue": true,
	}
	var res_sh: Dictionary = shallow.take_damage_split(
		11.0,
		0.0,
		"right_arm",
		0.5,
		-1.0,
		-1.0,
		extras_mfb
	)
	if _has_fracture_wound(shallow, "right_arm") or float(res_sh.get("final_bone", 0.0)) > 0.01:
		_fail(failures, "sim_mfb_deep_cut: shallow pen should not chip bone")
	var deep: Node = _Harness._new_entity("SWORD")
	var res_dp: Dictionary = deep.take_damage_split(
		11.0,
		0.0,
		"right_arm",
		_DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5,
		-1.0,
		-1.0,
		extras_mfb
	)
	if float(res_dp.get("final_bone", 0.0)) < 0.5 and not _has_fracture_wound(deep, "right_arm"):
		_fail(
			failures,
			"sim_mfb_deep_cut: pen >= %.2f mm should allow cut bone chip"
			% _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM
		)


static func _entity_for_species(sp: SpeciesResource) -> CoreEntity:
	var ent: CoreEntity = CoreEntity.new()
	ent.species = sp
	ent.apply_species()
	return ent


## S4: same raw tissue damage → same severity on human vs goblin arm (absolute bands on).
static func _run_sim_severity_absolute_stable(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_ABSOLUTE_SEVERITY_BANDS:
		_fail(failures, "sim_severity_abs: FEATURE_ABSOLUTE_SEVERITY_BANDS must be on")
		return
	const dmg: float = 5.5
	const part: String = "right_arm"
	var human: CoreEntity = _entity_for_species(_HumanSpecies)
	var goblin: CoreEntity = _entity_for_species(_GoblinSpecies)
	var sev_h: String = _EntityWounds.severity_from_damage(human, part, dmg, "forearm", -1.0)
	var sev_g: String = _EntityWounds.severity_from_damage(goblin, part, dmg, "forearm", -1.0)
	if sev_h != sev_g:
		_fail(
			failures,
			"sim_severity_abs: human=%s goblin=%s want same at dmg=%.1f (max hp %d vs %d)"
			% [sev_h, sev_g, dmg, int(human.body_max.get(part, 0)), int(goblin.body_max.get(part, 0))]
		)
	if sev_h != _Bleeding.SEVERITY_SEVERE:
		_fail(failures, "sim_severity_abs: pinned dmg %.1f want severe got %s" % [dmg, sev_h])
	var bone_h: String = _EntityWounds.severity_from_bone_damage(human, part, 3.2)
	var bone_g: String = _EntityWounds.severity_from_bone_damage(goblin, part, 3.2)
	if bone_h != bone_g or bone_h != _Bleeding.SEVERITY_SEVERE:
		_fail(
			failures,
			"sim_severity_abs: bone 3.2 want severe both got human=%s goblin=%s"
			% [bone_h, bone_g]
		)


## S4: high impact_ke_j still raises severity band vs low-KE same damage.
static func _run_sim_severity_ke_still_upgrades(failures: PackedStringArray) -> void:
	var ent: CoreEntity = _entity_for_species(_HumanSpecies)
	const part: String = "chest"
	const dmg: float = 1.8
	var sev_low: String = _EntityWounds.severity_from_damage(ent, part, dmg, "thoracic", -1.0)
	var sev_hi: String = _EntityWounds.severity_from_damage(ent, part, dmg, "thoracic", 140.0)
	var order: Array = [
		_Bleeding.SEVERITY_MINOR,
		_Bleeding.SEVERITY_MODERATE,
		_Bleeding.SEVERITY_SEVERE,
		_Bleeding.SEVERITY_CRITICAL,
	]
	if order.find(sev_hi) <= order.find(sev_low):
		_fail(
			failures,
			"sim_severity_ke: high KE should raise band (low=%s hi=%s dmg=%.1f)"
			% [sev_low, sev_hi, dmg]
		)


static func _species_with_derived_flag(sp: SpeciesResource) -> SpeciesResource:
	var dup: SpeciesResource = sp.duplicate() as SpeciesResource
	dup.feature_derived_limb_capacity = true
	return dup


static func _within_pct(actual: int, expected: int, tolerance_pct: float) -> bool:
	if expected <= 0:
		return actual == expected
	var slack: int = maxi(1, int(round(float(expected) * tolerance_pct)))
	return absi(actual - expected) <= slack


## S5: human + goblin production flags on; profiled derived matches hand exports.
static func _run_sim_derived_production_species_flags(failures: PackedStringArray) -> void:
	if not _HumanSpecies.feature_derived_limb_capacity:
		_fail(failures, "sim_derived_flag: human.tres feature_derived_limb_capacity must be true (S5 pilot)")
	if not _GoblinSpecies.feature_derived_limb_capacity:
		_fail(failures, "sim_derived_flag: goblin.tres feature_derived_limb_capacity must be true (S5 pilot)")
	for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
		var hand_t: int = _hand_tuned_limb_tissue(_HumanSpecies, part)
		var hand_b: int = _hand_tuned_limb_bone(_HumanSpecies, part)
		if _HumanSpecies.get_body_part_max(part) != hand_t or _HumanSpecies.get_bone_max(part) != hand_b:
			_fail(
				failures,
				"sim_derived_flag: human production %s tissue/bone %d/%d != hand %d/%d"
				% [
					part,
					_HumanSpecies.get_body_part_max(part),
					_HumanSpecies.get_bone_max(part),
					hand_t,
					hand_b,
				]
			)
	for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
		var hand_t_g: int = _hand_tuned_limb_tissue(_GoblinSpecies, part)
		var hand_b_g: int = _hand_tuned_limb_bone(_GoblinSpecies, part)
		if _GoblinSpecies.get_body_part_max(part) != hand_t_g or _GoblinSpecies.get_bone_max(part) != hand_b_g:
			_fail(
				failures,
				"sim_derived_flag: goblin production %s tissue/bone %d/%d != hand %d/%d"
				% [
					part,
					_GoblinSpecies.get_body_part_max(part),
					_GoblinSpecies.get_bone_max(part),
					hand_t_g,
					hand_b_g,
				]
			)


static func _hand_tuned_limb_tissue(sp: SpeciesResource, part: String) -> int:
	match part:
		"right_arm": return sp.right_arm
		"left_arm": return sp.left_arm
		"left_leg": return sp.left_leg
		"right_leg": return sp.right_leg
	return 0


static func _hand_tuned_limb_bone(sp: SpeciesResource, part: String) -> int:
	match part:
		"right_arm": return sp.right_arm_bone
		"left_arm": return sp.left_arm_bone
		"left_leg": return sp.left_leg_bone
		"right_leg": return sp.right_leg_bone
	return 1


## S5: derived human arm tissue/bone within ±15% of hand-tuned 12/8 when pilot flag on.
static func _run_sim_derived_limb_capacity_human_arm_reference(failures: PackedStringArray) -> void:
	var sp: SpeciesResource = _species_with_derived_flag(_HumanSpecies)
	const part: String = "right_arm"
	var tissue: int = sp.get_body_part_max(part)
	var bone: int = sp.get_bone_max(part)
	if not _within_pct(tissue, 12, 0.15):
		_fail(
			failures,
			"sim_derived_human_arm: tissue=%d want ~12 within 15%% (derived formula)"
			% tissue
		)
	if not _within_pct(bone, 8, 0.15):
		_fail(
			failures,
			"sim_derived_human_arm: bone=%d want ~8 within 15%% (derived formula)"
			% bone
		)
	var ent: CoreEntity = _entity_for_species(sp)
	if int(ent.body_max.get(part, 0)) != tissue or int(ent.bone_max.get(part, 0)) != bone:
		_fail(
			failures,
			"sim_derived_human_arm: CoreEntity caps tissue=%d bone=%d != getters %d/%d"
			% [int(ent.body_max.get(part, 0)), int(ent.bone_max.get(part, 0)), tissue, bone]
		)


## S5: derived human leg tissue/bone within ±15% of hand-tuned 16/12 when pilot flag on.
static func _run_sim_derived_limb_capacity_human_leg_reference(failures: PackedStringArray) -> void:
	var sp: SpeciesResource = _species_with_derived_flag(_HumanSpecies)
	const part: String = "left_leg"
	var tissue: int = sp.get_body_part_max(part)
	var bone: int = sp.get_bone_max(part)
	if not _within_pct(tissue, 16, 0.15):
		_fail(
			failures,
			"sim_derived_human_leg: tissue=%d want ~16 within 15%% (derived formula)"
			% tissue
		)
	if not _within_pct(bone, 12, 0.15):
		_fail(
			failures,
			"sim_derived_human_leg: bone=%d want ~12 within 15%% (derived formula)"
			% bone
		)


## S5: lighter species gets smaller derived limb budgets than human (mass-scaled pilot).
static func _run_sim_derived_goblin_smaller_limb_than_human(failures: PackedStringArray) -> void:
	var human: SpeciesResource = _species_with_derived_flag(_HumanSpecies)
	var goblin: SpeciesResource = _species_with_derived_flag(_GoblinSpecies)
	for part in ["right_arm", "left_leg"]:
		var h_t: int = human.get_body_part_max(part)
		var g_t: int = goblin.get_body_part_max(part)
		if g_t >= h_t:
			_fail(
				failures,
				"sim_derived_goblin: %s goblin tissue=%d should be < human %d"
				% [part, g_t, h_t]
			)
		var h_b: int = human.get_bone_max(part)
		var g_b: int = goblin.get_bone_max(part)
		if g_b >= h_b:
			_fail(
				failures,
				"sim_derived_goblin: %s goblin bone=%d should be < human %d"
				% [part, g_b, h_b]
			)


## S5: profiled derived goblin limbs equal hand-tuned exports (mini mass, hand cap).
static func _run_sim_derived_goblin_limbs_match_hand_tuned(failures: PackedStringArray) -> void:
	var sp: SpeciesResource = _species_with_derived_flag(_GoblinSpecies)
	for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
		var hand_t: int = _hand_tuned_limb_tissue(_GoblinSpecies, part)
		var hand_b: int = _hand_tuned_limb_bone(_GoblinSpecies, part)
		if sp.get_body_part_max(part) != hand_t:
			_fail(
				failures,
				"sim_derived_goblin_hand: %s tissue=%d want hand-tuned %d"
				% [part, sp.get_body_part_max(part), hand_t]
			)
		if sp.get_bone_max(part) != hand_b:
			_fail(
				failures,
				"sim_derived_goblin_hand: %s bone=%d want hand-tuned %d"
				% [part, sp.get_bone_max(part), hand_b]
			)


## S5: pain reference uses applied entity body_max (getters), not bypassing derived caps.
static func _run_sim_derived_pain_reference_matches_entity_body_max(failures: PackedStringArray) -> void:
	var sp: SpeciesResource = _species_with_derived_flag(_HumanSpecies)
	var ent: CoreEntity = _entity_for_species(sp)
	var from_entity: float = sp.get_pain_reference(ent.body_max)
	var from_getters: float = sp.live_pain_reference()
	if not is_equal_approx(from_entity, from_getters):
		_fail(
			failures,
			"sim_derived_pain_ref: entity body_max sum pain ref %.3f != getter dict %.3f"
			% [from_entity, from_getters]
		)


## S6: layer KE walk conserves strike_ke_j = absorbed + remaining.
static func _run_sim_joule_armor_ke_conserved(failures: PackedStringArray) -> void:
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass == null:
		_fail(failures, "sim_joule_ke: missing CUIRASS")
		return
	const strike_ke: float = 120.0
	const pen: float = 2.0
	var r: Dictionary = _ArmorJouleBudget.account_ke_through_armor(cuirass, strike_ke, pen, true)
	var absorbed: float = float(r.get("armor_ke_absorbed_j", 0.0))
	var remaining: float = float(r.get("armor_ke_remaining_j", 0.0))
	if not is_equal_approx(absorbed + remaining, strike_ke):
		_fail(
			failures,
			"sim_joule_ke: absorbed %.1f + remaining %.1f != strike %.1f"
			% [absorbed, remaining, strike_ke]
		)


## S6: plate kit bleeds less KE through than gambeson at same pen (sharp deflect path).
static func _run_sim_joule_armor_cuirass_absorbs_more_than_gambeson(failures: PackedStringArray) -> void:
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	var gambeson: ArmorPiece = _ArmorPiece.create_from_definition("GAMBESON")
	if cuirass == null or gambeson == null:
		_fail(failures, "sim_joule_armor: missing CUIRASS or GAMBESON")
		return
	const strike_ke: float = 100.0
	const pen: float = 2.0
	var heavy: Dictionary = _ArmorJouleBudget.account_ke_through_armor(cuirass, strike_ke, pen, true)
	var light: Dictionary = _ArmorJouleBudget.account_ke_through_armor(gambeson, strike_ke, pen, true)
	var rem_heavy: float = float(heavy.get("armor_ke_remaining_j", strike_ke))
	var rem_light: float = float(light.get("armor_ke_remaining_j", strike_ke))
	if rem_heavy >= rem_light - 0.5:
		_fail(
			failures,
			"sim_joule_armor: cuirass remaining KE %.1f should be < gambeson %.1f"
			% [rem_heavy, rem_light]
		)


## S10: joule-authoritative path matches ke_frac × pre (no second scalar ArmorPiece pass).
static func _run_sim_joule_armor_authoritative_ke_frac(failures: PackedStringArray) -> void:
	var ent: CoreEntity = CoreEntity.new()
	ent.species = _HumanSpecies
	ent.apply_species()
	var armor: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if armor == null:
		_fail(failures, "sim_joule_authoritative: missing CUIRASS")
		return
	ent.equip_armor("chest", armor)
	const strike_ke: float = 90.0
	const cut_pre: float = 14.0
	var extras: Dictionary = {"strike_ke_j": strike_ke, "force_joule_armor_budget": true}
	var res: Dictionary = _EntityDamage.apply_damage_split(
		ent, cut_pre, 0.0, "chest", 2.0, -1.0, -1.0, extras
	)
	var frac: float = float(res.get("transmitted_ke_fraction", -1.0))
	var mech: float = float(res.get("mechanical_post_armor", 0.0))
	var want_mech: float = cut_pre * frac
	if frac < 0.0:
		_fail(failures, "sim_joule_authoritative: missing transmitted_ke_fraction on result")
	if want_mech > 0.01 and absf(mech - want_mech) > want_mech * 0.15:
		_fail(
			failures,
			"sim_joule_authoritative: mech %.2f want cut*frac=%.2f (frac=%.3f)"
			% [mech, want_mech, frac]
		)
	if float(res.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
		_fail(failures, "sim_joule_authoritative: want armor_ke_absorbed_j > 1 when forced")


## S10: joule path must not double-absorb below ke_frac floor (regression guard).
static func _run_sim_joule_armor_not_below_ke_frac_floor(failures: PackedStringArray) -> void:
	var armor: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if armor == null:
		_fail(failures, "sim_joule_floor: missing CUIRASS")
		return
	const strike_ke: float = 90.0
	const cut_pre: float = 14.0
	var joule_ke: Dictionary = _ArmorJouleBudget.account_ke_through_armor(armor, strike_ke, 2.0, true)
	var frac: float = float(joule_ke.get("transmitted_ke_fraction", 1.0))
	var ent: CoreEntity = CoreEntity.new()
	ent.species = _HumanSpecies
	ent.apply_species()
	ent.equip_armor("chest", armor)
	var res: Dictionary = _EntityDamage.apply_damage_split(
		ent,
		cut_pre,
		0.0,
		"chest",
		2.0,
		-1.0,
		-1.0,
		{"strike_ke_j": strike_ke, "force_joule_armor_budget": true}
	)
	var mech: float = float(res.get("mechanical_post_armor", 0.0))
	var floor_mech: float = cut_pre * frac * 0.92
	if mech < floor_mech - 0.05:
		_fail(
			failures,
			"sim_joule_floor: mech %.2f below ke_frac floor %.2f (double-absorb regression)"
			% [mech, floor_mech]
		)


static func _harness_entity_with_ml_pool(sp: SpeciesResource) -> CoreEntity:
	_BloodVolumeMl._harness_force_literal_blood_ml = true
	var ent: CoreEntity = CoreEntity.new()
	ent.species = sp
	ent.apply_species()
	return ent


## S6 literal blood: mL max scales with species reference mass (human 75 kg → 5250 mL via `CombatDesignAnchors`).
static func _run_sim_blood_ml_pool_human_goblin_mass_scale(failures: PackedStringArray) -> void:
	_BloodVolumeMl._harness_force_literal_blood_ml = true
	var human: CoreEntity = _harness_entity_with_ml_pool(_HumanSpecies)
	var goblin: CoreEntity = _harness_entity_with_ml_pool(_GoblinSpecies)
	var hum_max: float = human.blood_volume_ml_max
	var gob_max: float = goblin.blood_volume_ml_max
	if not is_equal_approx(hum_max, _BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT):
		_fail(failures, "sim_blood_ml: human max want %.0f got %.0f" % [_BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT, hum_max])
	if gob_max >= hum_max - 1.0:
		_fail(failures, "sim_blood_ml: goblin max %.0f should be < human %.0f" % [gob_max, hum_max])
	var want_gob: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(38.0)
	if not is_equal_approx(gob_max, want_gob):
		_fail(failures, "sim_blood_ml: goblin max want %.0f got %.0f" % [want_gob, gob_max])
	_BloodVolumeMl._harness_force_literal_blood_ml = false


## S6: same bleed rate → same seconds-to-death in % mode vs mL mode (ATLS bridge).
static func _run_sim_blood_ml_ttd_matches_percent_mode(failures: PackedStringArray) -> void:
	const rate: float = _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE
	var ttd_pct: float = _Bleeding.seconds_to_exsanguination(rate, _Bleeding.MAX_BLOOD_VOLUME, 1.0)
	_BloodVolumeMl._harness_force_literal_blood_ml = true
	var ent_ml: CoreEntity = _harness_entity_with_ml_pool(_HumanSpecies)
	var max_ml: float = ent_ml.blood_volume_ml_max
	var buffer_ml: float = max_ml * (
		(_Bleeding.MAX_BLOOD_VOLUME - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / _Bleeding.MAX_BLOOD_VOLUME
	)
	var loss_ml_s: float = _BloodVolumeMl.blood_ml_loss_per_second(rate, max_ml, 1.0)
	var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
	_BloodVolumeMl._harness_force_literal_blood_ml = false
	if not is_equal_approx(ttd_pct, ttd_ml):
		_fail(
			failures,
			"sim_blood_ml_ttd: percent %.1fs vs ml %.1fs (rate=%.2f)"
			% [ttd_pct, ttd_ml, rate]
		)


## S6: one process_blood_loss tick keeps blood_volume % in sync with mL pool.
static func _run_sim_blood_ml_sync_percent_from_ml(failures: PackedStringArray) -> void:
	_BloodVolumeMl._harness_force_literal_blood_ml = true
	var ent: CoreEntity = _harness_entity_with_ml_pool(_HumanSpecies)
	ent.take_damage_split(8.0, 2.0, "right_arm")
	ent.blood_volume_ml = ent.blood_volume_ml_max * 0.6
	_BloodVolumeMl.sync_percent_from_ml(ent)
	if not is_equal_approx(ent.blood_volume, 60.0):
		_fail(
			failures,
			"sim_blood_ml_sync: 60%% pool want blood_volume=60 got %.2f"
			% ent.blood_volume
		)
	var rate: float = _EntityWounds.get_total_bleeding_rate(ent)
	if rate <= 0.0:
		_fail(failures, "sim_blood_ml_sync: need bleed rate")
		return
	var ml_before: float = ent.blood_volume_ml
	var pct_before: float = ent.blood_volume
	ent.set_combat_blood_loss_mult(1.0)
	_EntityWounds.process_blood_loss(ent, 1.0)
	var want_loss_pct: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	var want_loss_ml: float = _BloodVolumeMl.blood_ml_loss_per_second(rate, ent.blood_volume_ml_max, 1.0)
	if not is_equal_approx(pct_before - ent.blood_volume, want_loss_pct):
		_fail(
			failures,
			"sim_blood_ml_sync: pct loss %.3f want %.3f"
			% [pct_before - ent.blood_volume, want_loss_pct]
		)
	if not is_equal_approx(ml_before - ent.blood_volume_ml, want_loss_ml):
		_fail(
			failures,
			"sim_blood_ml_sync: ml loss %.1f want %.1f"
			% [ml_before - ent.blood_volume_ml, want_loss_ml]
		)


## Death signal fires once per entity (map bleed / repeated process_blood_loss ticks).
static func _run_sim_notify_died_emits_once(failures: PackedStringArray) -> void:
	var ent: CoreEntity = CoreEntity.new()
	var fired_box: Array = [0]
	ent.died.connect(func() -> void: fired_box[0] = int(fired_box[0]) + 1)
	ent.notify_died()
	ent.notify_died()
	if int(fired_box[0]) != 1:
		_fail(failures, "notify_died: want 1 died signal got %d" % int(fired_box[0]))
	var bleed_ent: CoreEntity = _Harness._new_entity("SWORD")
	bleed_ent.take_damage_split(6.0, 2.0, "chest")
	if _EntityWounds.get_total_bleeding_rate(bleed_ent) <= 0.0:
		_fail(failures, "notify_died: need bleed rate on wounded entity")
		return
	bleed_ent.blood_volume = 36.0
	bleed_ent.set_combat_blood_loss_mult(1.0)
	bleed_ent.set_combat_blood_recovery_per_s(0.0)
	var bleed_fired: Array = [0]
	bleed_ent.died.connect(func() -> void: bleed_fired[0] = int(bleed_fired[0]) + 1)
	for _i in range(24):
		_EntityWounds.process_blood_loss(bleed_ent, 1.0)
	if int(bleed_fired[0]) != 1:
		_fail(
			failures,
			"notify_died: blood_loss ticks want 1 died signal got %d" % int(bleed_fired[0])
		)
	bleed_ent.apply_species()
	var refire_box: Array = [0]
	bleed_ent.died.connect(func() -> void: refire_box[0] = int(refire_box[0]) + 1)
	bleed_ent.notify_died()
	if int(refire_box[0]) != 1:
		_fail(
			failures,
			"notify_died: apply_species should allow one new died signal got %d" % int(refire_box[0])
		)


## S6 layer tissue: shallow penetration absorbed by soft-tissue budget → less bone via MFB pen gate.
static func _run_sim_layer_tissue_shallow_pen_reduces_bone(failures: PackedStringArray) -> void:
	_CombatLayerTissue._harness_force_layer_tissue = true
	const part: String = "right_arm"
	const sub: String = "forearm"
	const cut: float = 14.0
	const pen_mid: float = 6.0
	var off: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		cut, 0.0, cut, part, sub, pen_mid, -1.0
	)
	var layer: Dictionary = _CombatLayerTissue.penetration_after_soft_tissue(part, pen_mid, true)
	var on: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		cut,
		0.0,
		cut,
		part,
		sub,
		float(layer.get("penetration_to_bone_mm", pen_mid)),
		-1.0,
	)
	_CombatLayerTissue._harness_force_layer_tissue = false
	if float(layer.get("penetration_to_bone_mm", -1.0)) >= _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
		_fail(
			failures,
			"sim_layer_tissue_shallow: pen %.1f absorbed should leave to_bone < %.2f got %.2f"
			% [
				pen_mid,
				_DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM,
				float(layer.get("penetration_to_bone_mm", 0.0)),
			]
		)
	if float(off.get("to_bone", 0.0)) <= 0.0:
		_fail(failures, "sim_layer_tissue_shallow: need baseline bone from pen for comparison")
	if float(on.get("to_bone", 0.0)) >= float(off.get("to_bone", 0.0)):
		_fail(
			failures,
			"sim_layer_tissue_shallow: layer on bone %.2f should be < off %.2f"
			% [float(on.get("to_bone", 0.0)), float(off.get("to_bone", 0.0))]
		)


## S6 layer tissue: penetration beyond budget reaches bone MFB pen threshold.
static func _run_sim_layer_tissue_deep_pen_reaches_bone(failures: PackedStringArray) -> void:
	_CombatLayerTissue._harness_force_layer_tissue = true
	const part: String = "right_arm"
	const sub: String = "forearm"
	const cut: float = 14.0
	const pen_deep: float = 8.0
	var layer: Dictionary = _CombatLayerTissue.penetration_after_soft_tissue(part, pen_deep, true)
	var pen_bone: float = float(layer.get("penetration_to_bone_mm", 0.0))
	if pen_bone < _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
		_fail(
			failures,
			"sim_layer_tissue_deep: pen_to_bone %.2f want >= %.2f"
			% [pen_bone, _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM]
		)
	var alloc: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		cut, 0.0, cut, part, sub, pen_bone, -1.0
	)
	_CombatLayerTissue._harness_force_layer_tissue = false
	if float(alloc.get("to_bone", 0.0)) < 0.5:
		_fail(
			failures,
			"sim_layer_tissue_deep: want bone chip at pen %.1f (to_bone=%.2f)"
			% [pen_deep, float(alloc.get("to_bone", 0.0))]
		)


## S7: armor layer stack consumes RHA depth — shallow pen stopped before tissue.
static func _run_sim_pen_trace_cuirass_stops_shallow(failures: PackedStringArray) -> void:
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass == null:
		_fail(failures, "sim_pen_trace: missing CUIRASS")
		return
	var trace: Dictionary = _ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 3.0)
	if not bool(trace.get("stopped_by_armor", false)):
		_fail(failures, "sim_pen_trace: pen 3 mm should stop on cuirass plate")
	if float(trace.get("penetration_to_tissue_mm", -1.0)) > 0.01:
		_fail(
			failures,
			"sim_pen_trace: shallow pen tissue mm want 0 got %.2f"
			% float(trace.get("penetration_to_tissue_mm", 0.0))
		)


## S7: pen beyond cloth+plate stack reaches tissue with remainder.
static func _run_sim_pen_trace_cuirass_deep_reaches_tissue(failures: PackedStringArray) -> void:
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass == null:
		_fail(failures, "sim_pen_trace_deep: missing CUIRASS")
		return
	const pen_deep: float = 6.0
	var trace: Dictionary = _ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, pen_deep)
	var to_tissue: float = float(trace.get("penetration_to_tissue_mm", 0.0))
	var want_remainder: float = pen_deep - 0.9 - 3.5
	if not is_equal_approx(to_tissue, want_remainder):
		_fail(
			failures,
			"sim_pen_trace_deep: tissue pen %.2f want ~%.2f (cloth+plate consumed)"
			% [to_tissue, want_remainder]
		)


## S7: post-armor tissue pen gates sharp-dominant MFB bone (cuirass vs bare pen).
static func _run_sim_pen_entity_damage_armor_reduces_bone(failures: PackedStringArray) -> void:
	var armor: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if armor == null:
		_fail(failures, "sim_pen_damage: missing CUIRASS")
		return
	const pen: float = 5.0
	const cut: float = 14.0
	const part: String = "chest"
	const sub: String = "thoracic"
	var trace: Dictionary = _ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(armor, pen)
	var pen_tissue: float = float(trace.get("penetration_to_tissue_mm", 0.0))
	var bare_alloc: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		cut, 0.0, cut, part, sub, pen, -1.0
	)
	var arm_alloc: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		cut, 0.0, cut, part, sub, pen_tissue, -1.0
	)
	if float(bare_alloc.get("to_bone", 0.0)) <= 0.0:
		_fail(failures, "sim_pen_damage: bare MFB want bone at pen %.1f" % pen)
	if float(arm_alloc.get("to_bone", 0.0)) >= float(bare_alloc.get("to_bone", 0.0)) - 0.01:
		_fail(
			failures,
			"sim_pen_damage: armored sharp bone %.2f should be < bare %.2f (tissue pen %.2f)"
			% [float(arm_alloc.get("to_bone", 0.0)), float(bare_alloc.get("to_bone", 0.0)), pen_tissue]
		)


## S7: ATLS hemorrhage class boundaries (remaining blood %).
static func _run_sim_atls_consciousness_class_boundaries(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS:
		_fail(failures, "sim_atls: FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS must be on")
		return
	if _Bleeding.atls_hemorrhage_class_from_remaining_pct(90.0) != 1:
		_fail(failures, "sim_atls: 90%% remaining want class I")
	if _Bleeding.atls_hemorrhage_class_from_remaining_pct(75.0) != 2:
		_fail(failures, "sim_atls: 75%% remaining want class II")
	if _Bleeding.atls_hemorrhage_class_from_remaining_pct(65.0) != 3:
		_fail(failures, "sim_atls: 65%% remaining want class III")
	if _Bleeding.atls_hemorrhage_class_from_remaining_pct(50.0) != 4:
		_fail(failures, "sim_atls: 50%% remaining want class IV")
	var mod_85: float = _Bleeding.blood_consciousness_modifier_from_remaining(
		85.0,
		_PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
		_PainConscious.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
		_PainConscious.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
	)
	var mod_35: float = _Bleeding.blood_consciousness_modifier_from_remaining(
		35.0,
		_PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
		_PainConscious.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
		_PainConscious.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
	)
	if not is_equal_approx(mod_85, 1.0):
		_fail(failures, "sim_atls: mod at 85%% want 1.0 got %.3f" % mod_85)
	if not is_equal_approx(mod_35, 0.5):
		_fail(failures, "sim_atls: mod at 35%% want 0.5 got %.3f" % mod_35)


## S7: blood-loss consciousness modifier decreases monotonically with volume loss.
static func _run_sim_atls_consciousness_monotonic(failures: PackedStringArray) -> void:
	var ent: CoreEntity = _entity_for_species(_HumanSpecies)
	var prev: float = 1.0
	for pct in [100.0, 85.0, 80.0, 70.0, 65.0, 55.0, 40.0, 35.0]:
		ent.blood_volume = pct
		var mod: float = _EntityPainConsciousness.get_blood_consciousness_modifier(ent)
		if mod > prev + 0.001:
			_fail(
				failures,
				"sim_atls_mono: mod %.3f at %.0f%% > prev %.3f (non-monotonic)"
				% [mod, pct, prev]
			)
		prev = mod


## S8: shallow post-armor penetration → lower cut severity than deep track at same damage.
static func _run_sim_depth_shallow_pen_lowers_severity(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_PENETRATION_DEPTH_SEVERITY:
		_fail(failures, "sim_depth_severity: FEATURE_PENETRATION_DEPTH_SEVERITY must be on")
		return
	var ent: CoreEntity = _entity_for_species(_HumanSpecies)
	const part: String = "right_arm"
	const sub: String = "forearm"
	const dmg: float = 5.5
	var sev_shallow: String = _EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 0.8)
	var sev_deep: String = _EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 6.0)
	var order: Array = _EntityWounds._severity_order()
	if order.find(sev_deep) < order.find(sev_shallow):
		_fail(
			failures,
			"sim_depth_severity: deep=%s should be >= shallow=%s at same damage"
			% [sev_deep, sev_shallow]
		)


## S8: deep penetration reaches severe+ band where shallow stays moderate at tuned damage.
static func _run_sim_depth_deep_pen_raises_severity(failures: PackedStringArray) -> void:
	var ent: CoreEntity = _entity_for_species(_HumanSpecies)
	const part: String = "right_arm"
	const sub: String = "forearm"
	const dmg: float = 5.5
	var sev_shallow: String = _EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 0.5)
	var sev_deep: String = _EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 6.0)
	if sev_shallow == _Bleeding.SEVERITY_SEVERE or sev_shallow == _Bleeding.SEVERITY_CRITICAL:
		_fail(failures, "sim_depth_deep: shallow pen should not already be severe+ (got %s)" % sev_shallow)
	if sev_deep != _Bleeding.SEVERITY_SEVERE and sev_deep != _Bleeding.SEVERITY_CRITICAL:
		_fail(
			failures,
			"sim_depth_deep: deep pen want severe+ got %s (shallow=%s)"
			% [sev_deep, sev_shallow]
		)


## S8: blunt KE budget in soft tissue suppresses low-energy arm fracture.
static func _run_sim_blunt_tissue_ke_reduces_fracture(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_BLUNT_TISSUE_KE_GATE:
		_fail(failures, "sim_blunt_tissue_ke: FEATURE_BLUNT_TISSUE_KE_GATE must be on")
		return
	const part: String = "right_arm"
	const sub: String = "elbow"
	var j_anchor: float = _DamageMechanism.blunt_fracture_j_anchor(part, sub)
	var budget: float = float(_CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get(part, 22.0))
	var ke_hi: float = j_anchor + budget + 18.0
	var ke_lo: float = j_anchor + budget - 4.0
	const blunt_stream: float = 2.0
	var hi: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		0.0, blunt_stream, blunt_stream, part, sub, -1.0, ke_hi, _CombatLayerTissue.blunt_ke_reaching_bone(part, ke_hi)
	)
	var lo: Dictionary = _DamageMechanism.allocate_bone_and_tissue(
		0.0, blunt_stream, blunt_stream, part, sub, -1.0, ke_lo, _CombatLayerTissue.blunt_ke_reaching_bone(part, ke_lo)
	)
	if float(hi.get("to_bone", 0.0)) < 0.5:
		_fail(failures, "sim_blunt_tissue_ke: high KE %.1f want bone (anchor %.1f)" % [ke_hi, j_anchor])
	if float(lo.get("to_bone", 0.0)) > 0.01:
		_fail(
			failures,
			"sim_blunt_tissue_ke: low KE %.1f should not fracture (to_bone=%.2f)"
			% [ke_lo, float(lo.get("to_bone", 0.0))]
		)


## S9: deep tissue penetration raises arterial chance vs shallow slash (same severity/part).
static func _run_sim_depth_deep_pen_raises_arterial_chance(failures: PackedStringArray) -> void:
	const sev: String = _Bleeding.SEVERITY_SEVERE
	var ch_shallow: float = _Bleeding.get_arterial_chance(
		sev, _Bleeding.INJURY_TYPE_CUT, "right_arm", "forearm", 0.8
	)
	var ch_deep: float = _Bleeding.get_arterial_chance(
		sev, _Bleeding.INJURY_TYPE_CUT, "right_arm", "forearm", 6.0
	)
	if ch_deep <= ch_shallow + 0.001:
		_fail(
			failures,
			"sim_depth_arterial: deep chance %.4f should exceed shallow %.4f"
			% [ch_deep, ch_shallow]
		)


## S9: subcutaneous + muscle stack (2 mm + 3 mm arm) absorbs before bone.
static func _run_sim_layer_stack_two_sheets_absorb_pen(failures: PackedStringArray) -> void:
	_CombatLayerTissue._harness_force_layer_tissue = true
	const part: String = "right_arm"
	var mid: Dictionary = _CombatLayerTissue.penetration_after_soft_tissue(part, 4.0, true)
	var deep: Dictionary = _CombatLayerTissue.penetration_after_soft_tissue(part, 6.5, true)
	_CombatLayerTissue._harness_force_layer_tissue = false
	var layers_mid: Array = mid.get("layers_absorbed_mm", [])
	if layers_mid.size() < 2:
		_fail(failures, "sim_layer_stack: want 2 soft-tissue sheets in layers_absorbed_mm")
	if float(mid.get("penetration_to_bone_mm", -1.0)) > 0.01:
		_fail(
			failures,
			"sim_layer_stack: pen 4 mm should not reach bone (to_bone=%.2f)"
			% float(mid.get("penetration_to_bone_mm", 0.0))
		)
	var to_bone: float = float(deep.get("penetration_to_bone_mm", 0.0))
	if not is_equal_approx(to_bone, 1.5):
		_fail(
			failures,
			"sim_layer_stack: pen 6.5 mm want 1.5 to bone (2+3 consumed) got %.2f"
			% to_bone
		)


## S10: full EntityDamage path — layer tissue reduces bone vs same hit without layer stack.
static func _run_sim_layer_tissue_entity_path_reduces_bone(failures: PackedStringArray) -> void:
	var off_ent: Node = _Harness._new_entity("SWORD")
	var on_ent: Node = _Harness._new_entity("SWORD")
	const pen: float = _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 2.0
	# Below forearm J anchor so bone comes from penetration gate, not KE excess alone.
	const extras: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
	var extras_off: Dictionary = extras.duplicate()
	if _Bleeding.FEATURE_LAYER_TISSUE:
		extras_off["disable_layer_tissue"] = true
	var res_off: Dictionary = off_ent.take_damage_split(
		12.0, 0.0, "right_arm", pen, -1.0, -1.0, extras_off
	)
	var extras_on: Dictionary = extras.duplicate()
	if not _Bleeding.FEATURE_LAYER_TISSUE:
		extras_on["force_layer_tissue"] = true
	var res_on: Dictionary = on_ent.take_damage_split(
		12.0, 0.0, "right_arm", pen, -1.0, -1.0, extras_on
	)
	var bone_off: float = float(res_off.get("final_bone", 0.0))
	var bone_on: float = float(res_on.get("final_bone", 0.0))
	if bone_off <= 0.0:
		_fail(failures, "sim_layer_entity: off-path want bone chip at pen %.1f" % pen)
	if bone_on >= bone_off - 0.01:
		_fail(
			failures,
			"sim_layer_entity: layer on bone %.2f should be < off %.2f"
			% [bone_on, bone_off]
		)
	if float(res_on.get("penetration_to_bone_mm", 99.0)) >= pen - 0.5:
		_fail(failures, "sim_layer_entity: want reduced penetration_to_bone_mm in result")


## M1: pen and KE curves monotonic; no EntityDamage mutation.
static func _run_mat_curve_monotonic_pen_and_ke(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	const sub: String = "forearm"
	var cut_sh: float = _MaterialFailureCurves.cut_tissue_damage_from_pen(0.8, part)
	var cut_mid: float = _MaterialFailureCurves.cut_tissue_damage_from_pen(3.0, part)
	var cut_deep: float = _MaterialFailureCurves.cut_tissue_damage_from_pen(6.0, part)
	if cut_mid <= cut_sh + 0.01 or cut_deep <= cut_mid + 0.01:
		_fail(
			failures,
			"mat_curve_monotonic: cut pen 0.8=%.2f 3=%.2f 6=%.2f want strict increase"
			% [cut_sh, cut_mid, cut_deep]
		)
	var j_anchor: float = _DamageMechanism.blunt_fracture_j_anchor(part, sub)
	var bone_lo: float = _MaterialFailureCurves.blunt_bone_damage_from_ke(j_anchor + 8.0, part, sub)
	var bone_hi: float = _MaterialFailureCurves.blunt_bone_damage_from_ke(j_anchor + 40.0, part, sub)
	if bone_hi <= bone_lo + 0.01:
		_fail(
			failures,
			"mat_curve_monotonic: blunt bone KE+8=%.2f KE+40=%.2f want increase"
			% [bone_lo, bone_hi]
		)
	if _MaterialFailureCurves.blunt_bone_damage_from_ke(j_anchor - 1.0, part, sub) > 0.01:
		_fail(failures, "mat_curve_monotonic: blunt bone below anchor should be 0")


## M1: blunt bone curve matches MFB `j_excess_to_bone_damage` at harness anchor.
static func _run_mat_curve_matches_mfb_baseline_at_anchor(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	const sub: String = "forearm"
	const excess_j: float = 24.0
	var j_anchor: float = _DamageMechanism.blunt_fracture_j_anchor(part, sub)
	var ke_hit: float = j_anchor + excess_j
	var curve_bone: float = _MaterialFailureCurves.blunt_bone_damage_from_ke(ke_hit, part, sub)
	var mfb_bone: float = _DamageMechanism.j_excess_to_bone_damage(excess_j)
	if absf(curve_bone - mfb_bone) > 0.02:
		_fail(
			failures,
			"mat_curve_mfb_anchor: blunt curve %.2f vs MFB %.2f (excess_J=%.0f)"
			% [curve_bone, mfb_bone, excess_j]
		)
	var ke_ref: float = _MaterialFailureCurves.reference_committed_arm_ke_j()
	var ref_bone: float = _MaterialFailureCurves.blunt_bone_damage_from_ke(ke_ref, part, sub)
	var expected_ref: float = _DamageMechanism.j_excess_to_bone_damage(
		maxf(0.0, ke_ref - j_anchor)
	)
	if absf(ref_bone - expected_ref) > 0.02:
		_fail(
			failures,
			"mat_curve_mfb_anchor: KE %.0f bone %.2f vs expected %.2f"
			% [ke_ref, ref_bone, expected_ref]
		)
	if _MaterialFailureCurves.cut_bone_damage_from_pen(1.0, part, sub) > 0.01:
		_fail(failures, "mat_curve_mfb_anchor: cut bone below MFB pen floor should be 0")
	var cut_deep: float = _MaterialFailureCurves.cut_tissue_damage_from_pen(6.0, part)
	var cut_shallow: float = _MaterialFailureCurves.cut_tissue_damage_from_pen(0.8, part)
	if cut_deep <= cut_shallow * 1.5:
		_fail(
			failures,
			"mat_curve_mfb_anchor: cut deep %.2f should exceed shallow %.2f"
			% [cut_deep, cut_shallow]
		)


## M1: depth mult is BleedingConstants delegate (no fork).
static func _run_mat_curve_depth_mult_delegates_bleeding(failures: PackedStringArray) -> void:
	for pen in [0.8, 3.0, 6.0]:
		var curve_mult: float = _MaterialFailureCurves.penetration_depth_mult(pen)
		var bleed_mult: float = _Bleeding.penetration_depth_severity_mult(pen)
		if absf(curve_mult - bleed_mult) > 0.0001:
			_fail(
				failures,
				"mat_curve_depth: pen=%.1f curve=%.3f bleeding=%.3f" % [pen, curve_mult, bleed_mult]
			)

static func _mat_within_pct_tolerance(baseline: float, actual: float, pct: float) -> bool:
	if baseline <= 0.01:
		return actual <= 0.01
	return absf(actual - baseline) <= baseline * pct


## M2: unarmored forearm — curve path within ±15% of MFB entity path (blend weight 1.0).
static func _run_mat_entity_curve_matches_hp_baseline_unarmored(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	const sub: String = "forearm"
	const pen: float = _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5
	const cut: float = 12.0
	const strike_ke: float = 12.0
	var extras_base: Dictionary = {
		"hit_sub_region": sub,
		"strike_ke_j": strike_ke,
		"material_curve_blend_weight": 0.0,
	}
	var ent_mfb: Node = _Harness._new_entity("SWORD")
	var res_mfb: Dictionary = ent_mfb.take_damage_split(
		cut, 0.0, part, pen, -1.0, -1.0, extras_base
	)
	var extras_curve: Dictionary = extras_base.duplicate()
	extras_curve["force_material_curves"] = true
	extras_curve["material_curve_blend_weight"] = 1.0
	var ent_curve: Node = _Harness._new_entity("SWORD")
	var res_curve: Dictionary = ent_curve.take_damage_split(
		cut, 0.0, part, pen, -1.0, -1.0, extras_curve
	)
	const tol: float = 0.15
	for key: String in ["final_cut", "final_blunt", "final_bone"]:
		var base_v: float = float(res_mfb.get(key, 0.0))
		var curve_v: float = float(res_curve.get(key, 0.0))
		if not _mat_within_pct_tolerance(base_v, curve_v, tol):
			_fail(
				failures,
				"mat_entity_baseline: %s MFB %.2f vs curve %.2f (>%.0f%%)"
				% [key, base_v, curve_v, tol * 100.0]
			)


## M2: production off → MFB path; production on → matches explicit `force_material_curves`.
static func _run_mat_entity_flag_off_matches_mfb_path(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	const pen: float = _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5
	const cut: float = 12.0
	const strike_ke: float = 12.0
	var extras: Dictionary = {
		"hit_sub_region": "forearm",
		"strike_ke_j": strike_ke,
		"material_curve_blend_weight": 0.0,
	}
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		var ent_a: Node = _Harness._new_entity("SWORD")
		var ent_b: Node = _Harness._new_entity("SWORD")
		var res_a: Dictionary = ent_a.take_damage_split(
			10.0, 2.0, part, 3.5, -1.0, -1.0, extras
		)
		var res_b: Dictionary = ent_b.take_damage_split(
			10.0, 2.0, part, 3.5, -1.0, -1.0, extras.duplicate()
		)
		for key: String in ["final_cut", "final_blunt", "final_bone"]:
			if absf(float(res_a.get(key, 0.0)) - float(res_b.get(key, 0.0))) > 0.01:
				_fail(
					failures,
					"mat_entity_flag_off: %s diverged %.2f vs %.2f"
					% [key, float(res_a.get(key, 0.0)), float(res_b.get(key, 0.0))]
				)
		if ent_a.body_cutting.get(part, 99.0) != ent_b.body_cutting.get(part, 99.0):
			_fail(failures, "mat_entity_flag_off: body_cutting pool mismatch")
		return
	var ent_prod: Node = _Harness._new_entity("SWORD")
	var res_prod: Dictionary = ent_prod.take_damage_split(
		cut, 0.0, part, pen, -1.0, -1.0, extras
	)
	var extras_force: Dictionary = extras.duplicate()
	extras_force["force_material_curves"] = true
	extras_force["material_curve_blend_weight"] = 1.0
	var ent_force: Node = _Harness._new_entity("SWORD")
	var res_force: Dictionary = ent_force.take_damage_split(
		cut, 0.0, part, pen, -1.0, -1.0, extras_force
	)
	const tol: float = 0.15
	for key: String in ["final_cut", "final_blunt", "final_bone"]:
		var prod_v: float = float(res_prod.get(key, 0.0))
		var force_v: float = float(res_force.get(key, 0.0))
		if not _mat_within_pct_tolerance(prod_v, force_v, tol):
			_fail(
				failures,
				"mat_entity_prod_curves: %s prod %.2f vs force %.2f (>%.0f%%)"
				% [key, prod_v, force_v, tol * 100.0]
			)


## M2: cuirass reduces post-armor pen → curve damage ≤ bare at pen 5.
static func _run_mat_armored_pen_reduces_curve_damage(failures: PackedStringArray) -> void:
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass == null:
		_fail(failures, "mat_armored_pen: missing CUIRASS")
		return
	const part: String = "chest"
	const sub: String = "thoracic"
	const pen: float = 5.0
	const cut: float = 14.0
	var extras: Dictionary = {
		"hit_sub_region": sub,
		"force_material_curves": true,
		"material_curve_blend_weight": 1.0,
	}
	var bare: Node = _Harness._new_entity("SWORD")
	var res_bare: Dictionary = bare.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
	var armored: Node = _Harness._new_entity("SWORD")
	armored.equip_armor(part, cuirass)
	var res_arm: Dictionary = armored.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
	var bare_sum: float = (
		float(res_bare.get("final_cut", 0.0))
		+ float(res_bare.get("final_blunt", 0.0))
		+ float(res_bare.get("final_bone", 0.0))
	)
	var arm_sum: float = (
		float(res_arm.get("final_cut", 0.0))
		+ float(res_arm.get("final_blunt", 0.0))
		+ float(res_arm.get("final_bone", 0.0))
	)
	if bare_sum <= 0.5:
		_fail(failures, "mat_armored_pen: bare path want damage at pen %.1f" % pen)
	if arm_sum > bare_sum + 0.01:
		_fail(
			failures,
			"mat_armored_pen: armored total %.2f should be <= bare %.2f"
			% [arm_sum, bare_sum]
		)
	if float(res_arm.get("final_bone", 0.0)) > float(res_bare.get("final_bone", 0.0)) + 0.01:
		_fail(
			failures,
			"mat_armored_pen: armored bone %.2f should be <= bare %.2f"
			% [float(res_arm.get("final_bone", 0.0)), float(res_bare.get("final_bone", 0.0))]
		)


## M3: shallow pen — yield stack leaves no bone penetration.
static func _run_mat_layer_yield_stops_shallow_pen(failures: PackedStringArray) -> void:
	_CombatLayerTissue._harness_force_layer_tissue_curves = true
	const part: String = "right_arm"
	var state: Array = _CombatLayerTissue.seed_layer_state_for_part(part)
	var layer: Dictionary = _CombatLayerTissue.penetration_through_layers(part, 0.5, state, true)
	_CombatLayerTissue._harness_force_layer_tissue_curves = false
	if float(layer.get("penetration_to_bone_mm", 99.0)) > 0.01:
		_fail(
			failures,
			"mat_layer_yield: pen 0.5 want to_bone=0 got %.2f"
			% float(layer.get("penetration_to_bone_mm", 0.0))
		)
	var states: Array = layer.get("layer_states", [])
	if states.is_empty() or str(states[0].get("state", "")) != "intact":
		_fail(failures, "mat_layer_yield: subcut should stay intact at 0.5 mm")


## M3: deep pen ruptures subcut; wound depth uses full tissue pen.
static func _run_mat_layer_rupture_deepens_wound_depth(failures: PackedStringArray) -> void:
	_CombatLayerTissue._harness_force_layer_tissue_curves = true
	const part: String = "right_arm"
	var state: Array = _CombatLayerTissue.seed_layer_state_for_part(part)
	var layer: Dictionary = _CombatLayerTissue.penetration_through_layers(part, 2.5, state, true)
	_CombatLayerTissue._harness_force_layer_tissue_curves = false
	var states: Array = layer.get("layer_states", [])
	if states.is_empty() or str(states[0].get("state", "")) != "ruptured":
		_fail(failures, "mat_layer_rupture: subcut should rupture at 2.5 mm pen")
	if float(layer.get("penetration_to_bone_mm", 0.0)) > 0.5:
		_fail(
			failures,
			"mat_layer_rupture: shallow rupture should not reach bone (to_bone=%.2f)"
			% float(layer.get("penetration_to_bone_mm", 0.0))
		)


## M3: entity path — curves + layer tissue reduces bone vs flat MFB at same pen.
static func _run_mat_layer_entity_path_reduces_bone(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	# Through 5 mm arm stack + bone gate (2.5 mm); 6 mm only reaches 1 mm to bone when flat layer on.
	var pen: float = 8.0 if _Bleeding.FEATURE_LAYER_TISSUE else 6.0
	const cut: float = 12.0
	const extras: Dictionary = {
		"hit_sub_region": "forearm",
		"strike_ke_j": 12.0,
		"force_material_curves": true,
		"force_layer_tissue_curves": true,
	}
	var extras_flat: Dictionary = extras.duplicate()
	extras_flat.erase("force_layer_tissue_curves")
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		extras_flat["disable_layer_tissue_curves"] = true
	var flat: Node = _Harness._new_entity("SWORD")
	var res_flat: Dictionary = flat.take_damage_split(
		cut, 0.0, part, pen, -1.0, -1.0, extras_flat
	)
	var curve: Node = _Harness._new_entity("SWORD")
	var res_curve: Dictionary = curve.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
	var bone_flat: float = float(res_flat.get("final_bone", 0.0))
	var bone_curve: float = float(res_curve.get("final_bone", 0.0))
	if bone_flat <= 0.0 and bone_curve <= 0.0:
		_fail(failures, "mat_layer_entity: need bone chip at pen %.1f for comparison" % pen)
	if bone_curve > bone_flat + 0.01:
		_fail(
			failures,
			"mat_layer_entity: curve+layer bone %.2f should be <= flat path %.2f"
			% [bone_curve, bone_flat]
		)
	var pen_tissue: float = float(res_curve.get("penetration_to_tissue_mm", -1.0))
	if pen_tissue < pen - 0.5:
		_fail(failures, "mat_layer_entity: want wound depth ~= strike pen %.1f got %.2f" % [pen, pen_tissue])


## M3: flat layer budget (5 mm arm stack) when yield/rupture curves inactive.
static func _run_mat_layer_flat_budget_unchanged_when_curves_off(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	const pen: float = 6.0
	var flat: Dictionary
	if _Bleeding.FEATURE_LAYER_TISSUE and not _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		flat = _CombatLayerTissue.penetration_after_soft_tissue(part, pen, true)
	else:
		_CombatLayerTissue._harness_force_layer_tissue = true
		_CombatLayerTissue._harness_force_layer_tissue_curves = false
		flat = _CombatLayerTissue.penetration_after_soft_tissue(part, pen, true)
		_CombatLayerTissue._harness_force_layer_tissue = false
	if absf(float(flat.get("penetration_to_bone_mm", -1.0)) - 1.0) > 0.05:
		_fail(
			failures,
			"mat_layer_flat: pen 6 want to_bone 1.0 got %.2f"
			% float(flat.get("penetration_to_bone_mm", 0.0))
		)


## M5 enablement PR #1: material curves production on.
static func _run_mat_production_curves_flag_enabled(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		_fail(failures, "mat_production: FEATURE_MATERIAL_FAILURE_CURVES must be true (enablement PR #1)")


## M5 enablement PR #2: flat layer tissue production on.
static func _run_mat_production_layer_tissue_flag_enabled(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LAYER_TISSUE:
		_fail(failures, "mat_production: FEATURE_LAYER_TISSUE must be true (enablement PR #2)")


## M5 enablement PR #3: layer yield/rupture production on.
static func _run_mat_production_layer_curves_flag_enabled(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		_fail(failures, "mat_production: FEATURE_LAYER_TISSUE_CURVES must be true (enablement PR #3)")
	if not _Bleeding.FEATURE_LAYER_TISSUE:
		_fail(failures, "mat_production: FEATURE_LAYER_TISSUE required before layer curves")


## PR #3: production yield/rupture path matches explicit `force_layer_tissue_curves`.
static func _run_mat_production_layer_curves_entity_matches_forced(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		return
	const part: String = "right_arm"
	var pen: float = 8.0 if _Bleeding.FEATURE_LAYER_TISSUE else 6.0
	var extras_prod: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
	var extras_force: Dictionary = extras_prod.duplicate()
	extras_force["force_layer_tissue_curves"] = true
	var ent_prod: Node = _Harness._new_entity("SWORD")
	var ent_force: Node = _Harness._new_entity("SWORD")
	var res_prod: Dictionary = ent_prod.take_damage_split(
		12.0, 0.0, part, pen, -1.0, -1.0, extras_prod
	)
	var res_force: Dictionary = ent_force.take_damage_split(
		12.0, 0.0, part, pen, -1.0, -1.0, extras_force
	)
	for key: String in ["final_cut", "final_blunt", "final_bone", "penetration_to_bone_mm"]:
		if absf(float(res_prod.get(key, 0.0)) - float(res_force.get(key, 0.0))) > 0.02:
			_fail(
				failures,
				"mat_layer_curves_prod: %s prod %.2f vs force %.2f"
				% [key, float(res_prod.get(key, 0.0)), float(res_force.get(key, 0.0))]
			)


## PR #2: production flat layer path matches `force_layer_tissue` (disable yield stack when curves on).
static func _run_mat_production_layer_entity_matches_forced(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LAYER_TISSUE:
		return
	const part: String = "right_arm"
	const pen: float = _DamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 2.0
	var extras_prod: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		extras_prod["disable_layer_tissue_curves"] = true
	var extras_force: Dictionary = extras_prod.duplicate()
	extras_force["force_layer_tissue"] = true
	var ent_prod: Node = _Harness._new_entity("SWORD")
	var ent_force: Node = _Harness._new_entity("SWORD")
	var res_prod: Dictionary = ent_prod.take_damage_split(
		12.0, 0.0, part, pen, -1.0, -1.0, extras_prod
	)
	var res_force: Dictionary = ent_force.take_damage_split(
		12.0, 0.0, part, pen, -1.0, -1.0, extras_force
	)
	for key: String in ["final_cut", "final_blunt", "final_bone", "penetration_to_bone_mm"]:
		if absf(float(res_prod.get(key, 0.0)) - float(res_force.get(key, 0.0))) > 0.02:
			_fail(
				failures,
				"mat_layer_prod: %s prod %.2f vs force %.2f"
				% [key, float(res_prod.get(key, 0.0)), float(res_force.get(key, 0.0))]
			)


## S11-A: joule armor production flag on (`CombatConstants`).
static func _run_mat_production_joule_armor_flag_enabled(failures: PackedStringArray) -> void:
	if not _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		_fail(failures, "mat_production: FEATURE_JOULE_ARMOR_BUDGET must be true (S11-A enablement)")


## S11-A: production joule path matches explicit `force_joule_armor_budget` on armored chest hit.
static func _run_mat_production_joule_authoritative_matches_forced(failures: PackedStringArray) -> void:
	if not _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		return
	var armor: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if armor == null:
		_fail(failures, "mat_joule_prod: missing CUIRASS")
		return
	const strike_ke: float = 90.0
	const cut_pre: float = 14.0
	const part: String = "chest"
	var extras_prod: Dictionary = {"strike_ke_j": strike_ke}
	var extras_force: Dictionary = extras_prod.duplicate()
	extras_force["force_joule_armor_budget"] = true
	var ent_prod: CoreEntity = CoreEntity.new()
	ent_prod.species = _HumanSpecies
	ent_prod.apply_species()
	ent_prod.equip_armor(part, armor)
	var ent_force: CoreEntity = CoreEntity.new()
	ent_force.species = _HumanSpecies
	ent_force.apply_species()
	ent_force.equip_armor(part, armor)
	var res_prod: Dictionary = _EntityDamage.apply_damage_split(
		ent_prod, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_prod
	)
	var res_force: Dictionary = _EntityDamage.apply_damage_split(
		ent_force, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_force
	)
	for key: String in [
		"mechanical_post_armor",
		"transmitted_ke_fraction",
		"armor_ke_absorbed_j",
		"final_cut",
		"final_blunt",
	]:
		if absf(float(res_prod.get(key, 0.0)) - float(res_force.get(key, 0.0))) > 0.02:
			_fail(
				failures,
				"mat_joule_prod: %s prod %.3f vs force %.3f"
				% [key, float(res_prod.get(key, 0.0)), float(res_force.get(key, 0.0))]
			)


## S11-A: `disable_joule_armor_budget` restores scalar ArmorPiece path when production flag on.
static func _run_mat_production_joule_disable_restores_scalar_armor(failures: PackedStringArray) -> void:
	if not _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		return
	var armor: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if armor == null:
		_fail(failures, "mat_joule_disable: missing CUIRASS")
		return
	const strike_ke: float = 90.0
	const cut_pre: float = 14.0
	const part: String = "chest"
	var extras_joule: Dictionary = {"strike_ke_j": strike_ke}
	var extras_scalar: Dictionary = extras_joule.duplicate()
	extras_scalar["disable_joule_armor_budget"] = true
	var ent_j: CoreEntity = CoreEntity.new()
	ent_j.species = _HumanSpecies
	ent_j.apply_species()
	ent_j.equip_armor(part, armor)
	var ent_s: CoreEntity = CoreEntity.new()
	ent_s.species = _HumanSpecies
	ent_s.apply_species()
	ent_s.equip_armor(part, armor)
	var res_j: Dictionary = _EntityDamage.apply_damage_split(
		ent_j, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_joule
	)
	var res_s: Dictionary = _EntityDamage.apply_damage_split(
		ent_s, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_scalar
	)
	var mech_j: float = float(res_j.get("mechanical_post_armor", 0.0))
	var mech_s: float = float(res_s.get("mechanical_post_armor", 0.0))
	if absf(mech_j - mech_s) < 0.25:
		_fail(
			failures,
			"mat_joule_disable: joule mech %.2f should differ from scalar %.2f on cuirass"
			% [mech_j, mech_s]
		)
	if float(res_j.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
		_fail(failures, "mat_joule_disable: joule path should report armor_ke_absorbed_j > 1")
	if float(res_s.get("armor_ke_absorbed_j", 0.0)) > 0.01:
		_fail(failures, "mat_joule_disable: scalar path should not populate armor_ke_absorbed_j")


## S11-B: literal blood mL production flag on.
static func _run_mat_production_literal_blood_ml_flag_enabled(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		_fail(failures, "mat_production: FEATURE_LITERAL_BLOOD_ML must be true (S11-B enablement)")


## S11-B: apply_species seeds mL pool when production flag on (no harness force).
static func _run_mat_production_blood_ml_pools_seeded(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		return
	_BloodVolumeMl._harness_force_literal_blood_ml = false
	var human: CoreEntity = CoreEntity.new()
	human.species = _HumanSpecies
	human.apply_species()
	var goblin: CoreEntity = CoreEntity.new()
	goblin.species = _GoblinSpecies
	goblin.apply_species()
	if not _BloodVolumeMl.entity_uses_ml(human):
		_fail(failures, "mat_blood_prod: human should use mL pool when flag on")
	if not is_equal_approx(human.blood_volume_ml_max, _BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT):
		_fail(
			failures,
			"mat_blood_prod: human max want %.0f got %.0f"
			% [_BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT, human.blood_volume_ml_max]
		)
	if not is_equal_approx(human.blood_volume_ml, human.blood_volume_ml_max):
		_fail(failures, "mat_blood_prod: human should spawn at full mL pool")
	if goblin.blood_volume_ml_max >= human.blood_volume_ml_max - 1.0:
		_fail(
			failures,
			"mat_blood_prod: goblin max %.0f should be < human %.0f"
			% [goblin.blood_volume_ml_max, human.blood_volume_ml_max]
		)


## S11-B: mL TTD matches percent-mode anchor (production bridge, no harness force).
static func _run_mat_production_blood_ttd_matches_percent(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		return
	const rate: float = _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE
	var ttd_pct: float = _Bleeding.seconds_to_exsanguination(rate, _Bleeding.MAX_BLOOD_VOLUME, 1.0)
	_BloodVolumeMl._harness_force_literal_blood_ml = false
	var ent: CoreEntity = CoreEntity.new()
	ent.species = _HumanSpecies
	ent.apply_species()
	var max_ml: float = ent.blood_volume_ml_max
	if max_ml < 1.0:
		_fail(failures, "mat_blood_ttd: missing blood_volume_ml_max on production entity")
		return
	var buffer_ml: float = max_ml * (
		(_Bleeding.MAX_BLOOD_VOLUME - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / _Bleeding.MAX_BLOOD_VOLUME
	)
	var loss_ml_s: float = _BloodVolumeMl.blood_ml_loss_per_second(rate, max_ml, 1.0)
	var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
	if not is_equal_approx(ttd_pct, ttd_ml):
		_fail(
			failures,
			"mat_blood_ttd: percent %.1fs vs ml %.1fs (rate=%.2f)"
			% [ttd_pct, ttd_ml, rate]
		)


## S11-B: one blood-loss tick keeps blood_volume % in sync with mL pool (production path).
static func _run_mat_production_blood_sync_tick(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		return
	_BloodVolumeMl._harness_force_literal_blood_ml = false
	var ent: CoreEntity = CoreEntity.new()
	ent.species = _HumanSpecies
	ent.apply_species()
	ent.take_damage_split(8.0, 2.0, "right_arm")
	ent.blood_volume_ml = ent.blood_volume_ml_max * 0.6
	_BloodVolumeMl.sync_percent_from_ml(ent)
	if not is_equal_approx(ent.blood_volume, 60.0):
		_fail(
			failures,
			"mat_blood_sync: 60%% pool want blood_volume=60 got %.2f"
			% ent.blood_volume
		)
	var rate: float = _EntityWounds.get_total_bleeding_rate(ent)
	if rate <= 0.0:
		_fail(failures, "mat_blood_sync: need bleed rate")
		return
	var ml_before: float = ent.blood_volume_ml
	var pct_before: float = ent.blood_volume
	ent.set_combat_blood_loss_mult(1.0)
	_EntityWounds.process_blood_loss(ent, 1.0)
	var want_loss_pct: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	var want_loss_ml: float = _BloodVolumeMl.blood_ml_loss_per_second(rate, ent.blood_volume_ml_max, 1.0)
	if not is_equal_approx(pct_before - ent.blood_volume, want_loss_pct):
		_fail(
			failures,
			"mat_blood_sync: pct loss %.3f want %.3f"
			% [pct_before - ent.blood_volume, want_loss_pct]
		)
	if not is_equal_approx(ml_before - ent.blood_volume_ml, want_loss_ml):
		_fail(
			failures,
			"mat_blood_sync: ml loss %.1f want %.1f"
			% [ml_before - ent.blood_volume_ml, want_loss_ml]
		)
	if not is_equal_approx(ent.blood_volume, 100.0 * ent.blood_volume_ml / ent.blood_volume_ml_max):
		_fail(
			failures,
			"mat_blood_sync: blood_volume %.2f != 100*ml/max %.2f"
			% [ent.blood_volume, 100.0 * ent.blood_volume_ml / ent.blood_volume_ml_max]
		)


## M5: production simulation + material flags snapshot (P3b + S11).
static func _run_mat_production_sim_flags_snapshot(failures: PackedStringArray) -> void:
	var checks: Array = [
		["FEATURE_MATERIAL_FAILURE_CURVES", _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES],
		["FEATURE_LAYER_TISSUE", _Bleeding.FEATURE_LAYER_TISSUE],
		["FEATURE_LAYER_TISSUE_CURVES", _Bleeding.FEATURE_LAYER_TISSUE_CURVES],
		["FEATURE_TISSUE_ENERGY_POOL", _Bleeding.FEATURE_TISSUE_ENERGY_POOL],
		["FEATURE_JOULE_ARMOR_BUDGET", _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET],
		["FEATURE_LITERAL_BLOOD_ML", _Bleeding.FEATURE_LITERAL_BLOOD_ML],
		["FEATURE_PENETRATION_DEPTH_SEVERITY", _Bleeding.FEATURE_PENETRATION_DEPTH_SEVERITY],
		["FEATURE_BLUNT_TISSUE_KE_GATE", _Bleeding.FEATURE_BLUNT_TISSUE_KE_GATE],
		["FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS", _Bleeding.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS],
		["FEATURE_ABSOLUTE_SEVERITY_BANDS", _Bleeding.FEATURE_ABSOLUTE_SEVERITY_BANDS],
	]
	for row: Array in checks:
		if not bool(row[1]):
			_fail(failures, "mat_flags_snapshot: %s must be true in production" % String(row[0]))
	if _Bleeding.FEATURE_TISSUE_DAMAGE_D:
		_fail(failures, "mat_flags_snapshot: FEATURE_TISSUE_DAMAGE_D must stay false (M4 cancelled)")


## M5: F5 playtest proxies green on full production stack (audit helpers).
static func _run_mat_production_f5_headless_proxies(failures: PackedStringArray) -> void:
	var graze: Dictionary = _CalibrationAudit.f5_forearm_graze_metrics()
	if float(graze.get("final_bone", 0.0)) >= 0.01:
		_fail(failures, "mat_f5: forearm graze want no bone chip")
	var chest: Dictionary = _CalibrationAudit.f5_armored_chest_metrics()
	var chest_ok: bool = (
		float(chest.get("armored_tissue_pen_mm", 99.0))
		< float(chest.get("bare_tissue_pen_mm", 0.0)) - 0.01
		or bool(chest.get("armor_stopped", false))
	) and float(chest.get("armored_damage_sum", 99.0)) < float(chest.get("bare_damage_sum", 0.0)) - 0.5
	if not chest_ok:
		_fail(
			failures,
			"mat_f5: cuirass pen/damage armored=%.2f/%.1f bare=%.2f/%.1f"
			% [
				float(chest.get("armored_tissue_pen_mm", 0.0)),
				float(chest.get("armored_damage_sum", 0.0)),
				float(chest.get("bare_tissue_pen_mm", 0.0)),
				float(chest.get("bare_damage_sum", 0.0)),
			]
		)
	if _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		if float(chest.get("transmitted_ke_fraction", -1.0)) < 0.0:
			_fail(failures, "mat_f5: armored chest missing joule transmitted_ke_fraction")
		if float(chest.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
			_fail(failures, "mat_f5: armored chest want armor_ke_absorbed_j > 1 with joule on")
	var mace: Dictionary = _CalibrationAudit.f5_mace_elbow_metrics()
	if float(mace.get("final_bone", 0.0)) < 0.5:
		_fail(
			failures,
			"mat_f5: mace elbow bone %.2f want >=0.5 at KE %.0f"
			% [float(mace.get("final_bone", 0.0)), float(mace.get("strike_ke_j", 0.0))]
		)


## M6 enablement PR #5: tissue energy pool production on.
static func _run_mat_production_energy_pool_flag_enabled(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		_fail(failures, "mat_production: FEATURE_TISSUE_ENERGY_POOL must be true (enablement PR #5)")


## M6: apply_species seeds J pools when production flag on.
static func _run_mat_production_energy_pools_seeded(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		return
	const part: String = "right_arm"
	var ent: Node = _Harness._new_entity("SWORD")
	var cap_j: float = float(ent.tissue_energy_capacity_j.get(part, 0.0))
	var rem_j: float = float(ent.tissue_energy_remaining_j.get(part, 0.0))
	if cap_j < 95.0 or cap_j > 105.0:
		_fail(failures, "mat_energy_prod: capacity_J %.0f want ~100" % cap_j)
	if rem_j < cap_j - 0.5:
		_fail(failures, "mat_energy_prod: remaining_J %.0f should equal capacity %.0f at spawn" % [rem_j, cap_j])


## M6: cut-only hit depletes cutting pool more than blunt (independent streams).
static func _run_mat_production_energy_severance_streams_independent(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		return
	const part: String = "right_arm"
	var extras: Dictionary = {
		"hit_sub_region": "forearm",
		"strike_ke_j": 12.0,
		"disable_layer_tissue": true,
	}
	var ent: Node = _Harness._new_entity("SWORD")
	var cut_before: float = float(ent.body_cutting.get(part, 0.0))
	var blunt_before: float = float(ent.body_blunt.get(part, 0.0))
	ent.take_damage_split(7.0, 0.5, part, 3.0, -1.0, -1.0, extras)
	var cut_drop: float = cut_before - float(ent.body_cutting.get(part, 0.0))
	var blunt_drop: float = blunt_before - float(ent.body_blunt.get(part, 0.0))
	if cut_drop <= blunt_drop + 0.5:
		_fail(
			failures,
			"mat_energy_streams: cut drop %.1f should exceed blunt drop %.1f on cut-heavy hit"
			% [cut_drop, blunt_drop]
		)


## M6: production J path tissue+bone applied within 5% of HP pool path (same hit).
static func _run_mat_production_energy_damage_within_five_pct(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		return
	var m: Dictionary = _CalibrationAudit.tissue_energy_hp_vs_j_parity_metrics()
	var tissue_hp: float = float(m.get("tissue_applied_hp", 0.0))
	var tissue_j: float = float(m.get("tissue_applied_j", 0.0))
	if not _mat_within_pct_tolerance(tissue_hp, tissue_j, 0.05):
		_fail(
			failures,
			"mat_energy_parity: J %.2f vs HP %.2f (>5%%)"
			% [tissue_j, tissue_hp]
		)


## M5: only M4 damage_D remains off (cancelled).
static func _run_mat_production_deferred_flags_off(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		_fail(failures, "mat_production: FEATURE_MATERIAL_FAILURE_CURVES must be true")
	if not _Bleeding.FEATURE_LAYER_TISSUE or not _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		_fail(failures, "mat_production: layer tissue + layer curves must be true")
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		_fail(failures, "mat_production: FEATURE_TISSUE_ENERGY_POOL must be true after PR #5")
	if _Bleeding.FEATURE_TISSUE_DAMAGE_D:
		_fail(failures, "mat_production: FEATURE_TISSUE_DAMAGE_D must be false (M4 cancelled)")
	if not _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		_fail(failures, "mat_production: FEATURE_JOULE_ARMOR_BUDGET must be true after S11-A")
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		_fail(failures, "mat_production: FEATURE_LITERAL_BLOOD_ML must be true after S11-B")


## M5: calibration audit material sections + anchor gate (runs audit inline, not stale file).
static func _run_mat_production_calibration_anchors_locked(failures: PackedStringArray) -> void:
	var result: Dictionary = _CalibrationAudit.run_and_write_report()
	if not bool(result.get("ok", false)):
		for msg: String in result.get("failures", PackedStringArray()):
			_fail(failures, "mat_production audit: %s" % msg)
	var body: String = "\n".join(result.get("lines", PackedStringArray()))
	for section: String in [
		"[material_failure_curves_pilot]",
		"[layer_tissue_curves_m3]",
		"[material_failure_production]",
		"[tissue_energy_pool_m6]",
		"[production_sim_flags]",
		"[research_benchmarks]",
		"[f5_scenario_headless]",
	]:
		if section not in body:
			_fail(failures, "mat_production: audit missing section %s" % section)
	var gate_line: String = _CalibrationAudit.material_failure_headless_gate_line()
	if gate_line not in body:
		_fail(failures, "mat_production: audit missing gate line %s" % gate_line)


## M5: TTD band and committed oberhau KE unchanged (delivery anchors).
static func _run_mat_production_ttd_and_oberhau_unchanged(failures: PackedStringArray) -> void:
	var ttd_s: float = _Bleeding.seconds_to_exsanguination(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, _Bleeding.MAX_BLOOD_VOLUME, 1.0
	)
	if ttd_s < 30.0 or ttd_s > 120.0:
		_fail(failures, "mat_production: TTD %.1fs outside 30-120s" % ttd_s)
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "mat_production: missing SWORD for KE anchor")
		return
	var ai: AttackInstance = AttackInstance.new("oberhau", 1.0)
	ai.archetype = {"kinematic_delivery": _WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai.delivery_commit_fraction = 0.78
	var ke_j: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai)
	if not _DesignAnchors.committed_strike_ke_in_strict_band(ke_j):
		_fail(failures, "mat_production: committed oberhau KE %.0f outside 70-140 J" % ke_j)


## M6: human arm 12 display ↔ ~100 J capacity anchor.
static func _run_mat_energy_arm_capacity_anchor(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	const body_max: int = _DesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
	var cap_j: float = _TissueEnergyCapacity.capacity_j_for_part(part, body_max)
	if cap_j < 95.0 or cap_j > 105.0:
		_fail(failures, "mat_energy: arm capacity_J %.0f want ~100" % cap_j)


## M6: display bridge 50% J → ~50% display tissue.
static func _run_mat_energy_display_bridge(failures: PackedStringArray) -> void:
	const body_max: int = _DesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
	var cap_j: float = _TissueEnergyCapacity.capacity_j_for_part("right_arm", body_max)
	var display: float = _TissueEnergyCapacity.display_tissue_from_remaining_j(
		body_max, cap_j * 0.5, cap_j
	)
	if display < 5.0 or display > 7.0:
		_fail(failures, "mat_energy: 50%% J display %.0f want ~6 (body_max %d)" % [display, body_max])
	var rem_j: float = _TissueEnergyCapacity.remaining_j_from_display_pools(
		body_max, 6.0, 6.0, cap_j
	)
	if rem_j < cap_j * 0.45 or rem_j > cap_j * 0.55:
		_fail(
			failures,
			"mat_energy: round-trip J %.0f want ~%.0f from 6+6 display"
			% [rem_j, cap_j * 0.5]
		)


## M6: when production flag off, J dicts stay empty after apply_species.
static func _run_mat_energy_flag_off_no_entity_fields(failures: PackedStringArray) -> void:
	if _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		return
	var ent: Node = _Harness._new_entity("SWORD")
	if not ent.tissue_energy_capacity_j.is_empty() or not ent.tissue_energy_remaining_j.is_empty():
		_fail(failures, "mat_energy: J pools should be empty when production flag off")


## M6: J path debits internal reservoir and syncs display pools (production or force).
static func _run_mat_energy_entity_j_path_debits_internal(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		return
	const part: String = "right_arm"
	var ent: Node = _Harness._new_entity("SWORD")
	var cap_before: float = float(ent.tissue_energy_capacity_j.get(part, 0.0))
	if cap_before < 1.0:
		cap_before = _TissueEnergyCapacity.capacity_j_for_part(
			part, int(ent.body_max.get(part, _DesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY))
		)
	var extras: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
	var cut_before: float = float(ent.body_cutting.get(part, 0.0))
	var res: Dictionary = ent.take_damage_split(6.0, 2.0, part, 4.0, -1.0, -1.0, extras)
	if float(res.get("tissue_energy_remaining_j", -1.0)) < 0.0:
		_fail(failures, "mat_energy_j_path: want tissue_energy_remaining_j on result")
	var rem_after: float = float(ent.tissue_energy_remaining_j.get(part, 0.0))
	if rem_after >= cap_before - 0.5:
		_fail(
			failures,
			"mat_energy_j_path: remaining_J %.1f should drop from %.1f after hit"
			% [rem_after, cap_before]
		)
	var cut_after: float = float(ent.body_cutting.get(part, 0.0))
	if cut_after >= cut_before - 0.01:
		_fail(
			failures,
			"mat_energy_j_path: display cut %.1f should drop from %.1f"
			% [cut_after, cut_before]
		)


## M6: HP pool path (disable J) matches itself; production J path reproducible.
static func _run_mat_energy_entity_flag_off_matches_display_pools(failures: PackedStringArray) -> void:
	const part: String = "right_arm"
	var extras: Dictionary = {
		"hit_sub_region": "forearm",
		"strike_ke_j": 12.0,
		"disable_layer_tissue": true,
	}
	var fail_tag: String = "mat_energy_flag_off"
	if _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		extras["disable_tissue_energy_pool"] = true
		fail_tag = "mat_energy_hp_path"
	var ent_a: Node = _Harness._new_entity("SWORD")
	var ent_b: Node = _Harness._new_entity("SWORD")
	var res_a: Dictionary = ent_a.take_damage_split(5.0, 1.0, part, 3.0, -1.0, -1.0, extras)
	var res_b: Dictionary = ent_b.take_damage_split(5.0, 1.0, part, 3.0, -1.0, -1.0, extras.duplicate())
	for key: String in ["final_cut", "final_blunt", "final_bone"]:
		if absf(float(res_a.get(key, 0.0)) - float(res_b.get(key, 0.0))) > 0.02:
			_fail(failures, "%s: %s diverged" % [fail_tag, key])


## Research gate: untreated arterial TTD in clinical 30–120 s band.
static func _run_research_clinical_ttd_band(failures: PackedStringArray) -> void:
	var ttd_s: float = _Bleeding.seconds_to_exsanguination(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, _Bleeding.MAX_BLOOD_VOLUME, 1.0
	)
	if ttd_s < 30.0 or ttd_s > 120.0:
		_fail(failures, "research_ttd: %.1fs outside clinical 30-120s band" % ttd_s)


## Research gate: species `.tres` masses and human tissue sum match design anchors.
static func _run_research_species_reference_mass_anchors(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.species_reference_mass_anchors_match():
		_fail(
			failures,
			(
				"research_species_mass: human=%.1f@%.0f goblin=%.1f@%.0f "
				+ "human_tissue=%d@%d goblin_tissue=%d@[%d-%d] goblin_below_human=%s"
			)
			% [
				_HumanSpecies.resolved_reference_mass_kg(),
				_DesignAnchors.REFERENCE_ADULT_MASS_KG,
				_GoblinSpecies.resolved_reference_mass_kg(),
				_ResearchAnchors.GOBLIN_REFERENCE_MASS_KG,
				_HumanSpecies.live_tissue_sum(),
				_DesignAnchors.REFERENCE_HUMAN_TISSUE_SUM,
				_GoblinSpecies.live_tissue_sum(),
				_ResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MIN,
				_ResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MAX,
				str(_ResearchAnchors.goblin_mass_below_human()).to_lower(),
			]
		)


## Research gate: 75 kg male anchor = 70 mL/kg (5250 mL).
static func _run_research_blood_ml_nominal_70_per_kg(failures: PackedStringArray) -> void:
	var ref_kg: float = _HumanSpecies.resolved_reference_mass_kg()
	var per_kg: float = _ResearchAnchors.blood_ml_per_kg_at_reference_mass(ref_kg)
	var tol: float = _ResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_TOLERANCE
	if absf(per_kg - _ResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_NOMINAL) > tol:
		_fail(
			failures,
			"research_blood_ml: %.2f mL/kg want %.0f ± %.1f"
			% [per_kg, _ResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_NOMINAL, tol]
		)
	if not is_equal_approx(
		_BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg),
		_BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT
	):
		_fail(failures, "research_blood_ml: pool max != REFERENCE_BLOOD_VOLUME_ML_ADULT")


## Research gate: ATLS 10th ed. class boundaries from remaining %.
static func _run_research_atls_class_boundaries(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.atls_class_boundaries_match_atls10():
		_fail(failures, "research_atls: remaining%% → class mapping does not match ATLS 10 loss bands")


## Research gate: BLOOD_LOSS_RATE_MULTIPLIER matches closed-form derivation for 48 s TTD.
static func _run_research_blood_loss_multiplier_derived(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.blood_loss_multiplier_matches_derived():
		var derived: float = _ResearchAnchors.derived_blood_loss_multiplier_for_ttd(
			_ResearchAnchors.LITERATURE_TTD_TARGET_S
		)
		_fail(
			failures,
			"research_mult: shipped %.4f vs derived %.4f for %.0fs TTD"
			% [_Bleeding.BLOOD_LOSS_RATE_MULTIPLIER, derived, _ResearchAnchors.LITERATURE_TTD_TARGET_S]
		)


## Research gate: REFERENCE_UNCONTROLLED_BLEED_RATE equals documented product (not a magic constant).
static func _run_research_reference_bleed_derivation(failures: PackedStringArray) -> void:
	var deriv: Dictionary = _ResearchAnchors.reference_bleed_rate_derivation()
	if not bool(deriv.get("matches_reference_const", false)):
		_fail(
			failures,
			"research_bleed_deriv: product %.2f != REFERENCE %.2f"
			% [float(deriv.get("product_hp_per_s", 0.0)), _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE]
		)
	if not bool(deriv.get("multiplier_matches_derived", false)):
		_fail(failures, "research_bleed_deriv: shipped multiplier diverges from 48s TTD derivation")
	var ttd_s: float = float(deriv.get("clinical_ttd_s", 0.0))
	if ttd_s < 30.0 or ttd_s > 120.0:
		_fail(failures, "research_bleed_deriv: calibrated TTD %.1fs outside 30-120s" % ttd_s)
	if not bool(deriv.get("ml_ttd_parity_ok", false)):
		_fail(failures, "research_bleed_deriv: percent and mL TTD paths diverge at reference bleed")


## Research gate: death threshold at or beyond ATLS Class IV (>40% loss).
static func _run_research_atls_death_threshold(failures: PackedStringArray) -> void:
	var loss_pct: float = _ResearchAnchors.loss_pct_to_death_threshold()
	if loss_pct < _ResearchAnchors.LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN:
		_fail(
			failures,
			"research_atls_death: loss to death %.0f%% below literature %.0f%%"
			% [loss_pct, _ResearchAnchors.LITERATURE_ATLS_CLASS_IV_LOSS_PCT_MIN]
		)
	if not _ResearchAnchors.death_threshold_deep_in_class_iv():
		_fail(failures, "research_atls_death: death threshold should be below 60%% remaining (Class IV entry)")


## Research gate: critical cut arterial chance near penetrating vascular soft-sign literature (~25%).
static func _run_research_arterial_chance_literature(failures: PackedStringArray) -> void:
	var game: float = float(_Bleeding.ARTERIAL_CHANCE_BY_SEVERITY[_Bleeding.SEVERITY_CRITICAL])
	if absf(game - _ResearchAnchors.LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS) > _ResearchAnchors.LITERATURE_ARTERIAL_CRITICAL_TOLERANCE:
		_fail(
			failures,
			"research_arterial: critical chance %.2f want ~%.2f (2+ soft signs teaching)"
			% [game, _ResearchAnchors.LITERATURE_PENETRATING_VASCULAR_SOFT_SIGN_2PLUS]
		)


## Research gate: distal blunt tolerance < proximal (biomechanics ordering).
static func _run_research_blunt_anchor_ordering(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.blunt_anchor_ordering_ok():
		_fail(failures, "research_blunt_order: want elbow < forearm < thigh J anchors")


## Research gate: committed oberhau KE in HEMA calibration band.
static func _run_research_committed_ke_hema_band(failures: PackedStringArray) -> void:
	var ke_j: float = _ResearchAnchors.committed_oberhau_ke_j()
	if ke_j < _ResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MIN or ke_j > _ResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MAX:
		_fail(
			failures,
			"research_hema_ke: %.0f J outside %.0f-%.0f"
			% [ke_j, _ResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MIN, _ResearchAnchors.LITERATURE_HEMA_COMMITTED_KE_J_MAX]
		)


## Research gate: loss_mult 0.5 ≈ doubles TTD (direct pressure heuristic).
static func _run_research_direct_pressure_ttd_halving(failures: PackedStringArray) -> void:
	var ratio: float = _ResearchAnchors.pressure_halved_ttd_ratio()
	if absf(ratio - _ResearchAnchors.LITERATURE_PRESSURE_TTD_RATIO_TARGET) > _ResearchAnchors.LITERATURE_PRESSURE_TTD_RATIO_TOLERANCE:
		_fail(
			failures,
			"research_pressure_ttd: halved-loss TTD ratio %.2f want ~%.1f"
			% [ratio, _ResearchAnchors.LITERATURE_PRESSURE_TTD_RATIO_TARGET]
		)


## Research gate: cut bleed rates exceed crush at every severity; ladders monotonic.
static func _run_research_bleeding_ladder_monotonic(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.cut_bleeding_exceeds_crush_at_all_severities():
		_fail(failures, "research_bleed_ladder: cut rates must exceed crush at all severities")
	if not _ResearchAnchors.bleeding_severity_ladder_monotonic():
		_fail(failures, "research_bleed_ladder: minor<moderate<severe<critical within cut and crush")


## Research gate: shallow penetration < deep for severity and arterial mults.
static func _run_research_pen_depth_monotonic(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_PENETRATION_DEPTH_SEVERITY:
		_fail(failures, "research_pen_depth: FEATURE_PENETRATION_DEPTH_SEVERITY must be on")
	if not _ResearchAnchors.penetration_depth_mult_monotonic():
		_fail(failures, "research_pen_depth: severity mult must rise shallow→deep")
	if not _ResearchAnchors.penetration_arterial_mult_monotonic():
		_fail(failures, "research_pen_depth: arterial mult must rise shallow→deep")


## Research gate: clotting half-life increases with wound severity; bandage in 60–300 s band.
static func _run_research_clotting_half_life_order(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.clotting_half_life_ordering_ok():
		_fail(failures, "research_clot: half-life must increase minor→critical")
	var bandage_hl: float = _ResearchAnchors.bandage_clot_half_life_s()
	if (
		bandage_hl < _ResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN
		or bandage_hl > _ResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX
	):
		_fail(
			failures,
			"research_clot: bandage half-life %.0fs outside %.0f-%.0fs"
			% [
				bandage_hl,
				_ResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN,
				_ResearchAnchors.LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MAX,
			]
		)


## Research gate: literal mL TTD matches percent-scale TTD at 75 kg (FEATURE_LITERAL_BLOOD_ML).
static func _run_research_ml_percent_ttd_parity(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		_fail(failures, "research_ml_ttd: FEATURE_LITERAL_BLOOD_ML must be on for parity gate")
	if not _ResearchAnchors.ml_percent_ttd_parity_ok():
		_fail(failures, "research_ml_ttd: percent and mL exsanguination paths diverge at reference mass")


## Research gate: implied mL bridge helper matches BloodVolumeMl and stays positive at reference mass.
static func _run_research_implied_ml_bridge(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		return
	var ref_kg: float = _DesignAnchors.REFERENCE_ADULT_MASS_KG
	var max_ml: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_kg)
	var want: float = _BloodVolumeMl.blood_ml_loss_per_second(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, max_ml, 1.0
	)
	var got: float = _ResearchAnchors.reference_uncontrolled_implied_ml_per_second(ref_kg, 1.0)
	if want <= 0.01 or got <= 0.01:
		_fail(failures, "research_implied_ml_bridge: implied loss must be positive at reference bleed")
	elif not is_equal_approx(want, got):
		_fail(
			failures,
			"research_implied_ml_bridge: helper %.3f != BloodVolumeMl %.3f"
			% [got, want]
		)


## Research gate: goblin mass-scaled pool preserves 70 mL/kg anchor.
static func _run_research_goblin_blood_ml_per_kg(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.goblin_blood_ml_per_kg_matches_human_anchor():
		_fail(
			failures,
			"research_goblin_blood: mL/kg must match %.0f ± %.1f at %.0f kg"
			% [
				_ResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_NOMINAL,
				_ResearchAnchors.LITERATURE_BLOOD_ML_PER_KG_TOLERANCE,
				_ResearchAnchors.GOBLIN_REFERENCE_MASS_KG,
			]
		)


## Research gate: scalp bleed mult exceeds limb baseline (vascular scalp literature).
static func _run_research_scalp_vs_limb_bleed(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.scalp_bleed_mult_exceeds_limb():
		_fail(failures, "research_scalp: scalp multiplier must exceed forearm and be >= 1.4")


## Research gate: absolute tissue/bone severity thresholds ordered.
static func _run_research_absolute_severity_bands(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.absolute_severity_bands_ordered():
		_fail(failures, "research_abs_severity: tissue and bone absolute bands must be strictly ordered")


## Research gate: human auto pain_reference ≈ 3.0 (tissue_sum/32).
static func _run_research_pain_human_reference(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.human_pain_reference_matches_literature():
		_fail(
			failures,
			"research_pain_ref: human %.3f want %.1f ± %.2f"
			% [
				_ResearchAnchors.pain_reference_for_species(_HumanSpecies),
				_ResearchAnchors.LITERATURE_HUMAN_PAIN_REFERENCE,
				_ResearchAnchors.LITERATURE_HUMAN_PAIN_REFERENCE_TOLERANCE,
			]
		)


## Research gate: ~2 moderate hits to reach NRS 4 (first functional impairment).
static func _run_research_pain_hits_to_nrs4(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.human_hits_to_nrs4_in_band():
		_fail(
			failures,
			"research_pain_nrs4: human hits_to_NRS4=%.2f want %.1f-%.1f"
			% [
				_ResearchAnchors.hits_to_nrs_first_effect(_HumanSpecies),
				_ResearchAnchors.LITERATURE_HITS_TO_NRS4_MIN,
				_ResearchAnchors.LITERATURE_HITS_TO_NRS4_MAX,
			]
		)


## Research gate: NRS thresholds strictly ordered (4 < 6 < 7 < 8 < 10).
static func _run_research_pain_nrs_thresholds_ordered(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.nrs_thresholds_ordered():
		_fail(failures, "research_pain_nrs: NRS thresholds must be strictly ordered")


## Research gate: smaller goblin tissue sum → lower pain_reference (more pain per hit).
static func _run_research_pain_goblin_below_human(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.goblin_pain_reference_below_human():
		_fail(
			failures,
			"research_pain_goblin: goblin ref %.3f must be below human %.3f"
			% [
				_ResearchAnchors.pain_reference_for_species(_GoblinSpecies),
				_ResearchAnchors.pain_reference_for_species(_HumanSpecies),
			]
		)


## Research gate: forearm arterial mult > upper_arm (UE penetrating vascular epidemiology).
static func _run_research_forearm_arterial_epidemiology(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.forearm_arterial_mult_exceeds_upper_arm():
		_fail(failures, "research_forearm_arterial: forearm mult must exceed upper_arm and be >= 1.1")


## Research gate: human chest largest tissue segment (gameplay mass proportions).
static func _run_research_human_chest_largest_segment(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.human_chest_largest_tissue_segment():
		_fail(failures, "research_anatomy: human chest must be largest tissue segment")


## Research gate: post-S11 full production headless gate id.
static func _run_research_production_full_stack_gate(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.production_sim_flags_full_stack_ok():
		_fail(
			failures,
			"research_production_gate: got %s want %s"
			% [_ResearchAnchors.production_headless_gate_id(), _ResearchAnchors.LITERATURE_HEADLESS_GATE_FULL]
		)


## Research gate: M6 arm tissue J capacity ~100 @ body_max 12; display half ~6 at 50%% J.
static func _run_research_tissue_energy_arm_anchor(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_TISSUE_ENERGY_POOL:
		_fail(failures, "research_tissue_energy: FEATURE_TISSUE_ENERGY_POOL must be on")
	if not _ResearchAnchors.tissue_energy_arm_capacity_matches_design():
		_fail(
			failures,
			"research_tissue_energy: arm capacity %.0f J want %.0f ± %.0f"
			% [
				_ResearchAnchors.tissue_energy_arm_capacity_j(),
				_ResearchAnchors.LITERATURE_ARM_TISSUE_CAPACITY_J,
				_ResearchAnchors.LITERATURE_ARM_CAPACITY_J_TOLERANCE,
			]
		)
	if not _ResearchAnchors.tissue_energy_arm_display_half_matches_anchor():
		_fail(
			failures,
			"research_tissue_energy: display half at 50%% J=%.0f want %.0f ± %.0f"
			% [
				_ResearchAnchors.tissue_energy_arm_display_half_at_50pct(),
				_ResearchAnchors.LITERATURE_ARM_DISPLAY_HALF_J,
				_ResearchAnchors.LITERATURE_ARM_DISPLAY_HALF_TOLERANCE,
			]
		)


## Research gate: Method B normalized pain is canonical.
static func _run_research_normalized_pain_method_b(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.normalized_pain_method_b_enabled():
		_fail(failures, "research_pain: USE_NORMALIZED_PAIN must be true")


## Research gate: S5 derived limb pilot on human and goblin species resources.
static func _run_research_derived_limb_species_flags(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.derived_limb_capacity_on_both_species():
		_fail(failures, "research_derived_limb: human and goblin feature_derived_limb_capacity must be true")


## Research gate: blunt flesh KE budget reduces KE reaching bone at committed oberhau.
static func _run_research_blunt_ke_budget_reduces_bone(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_BLUNT_TISSUE_KE_GATE:
		_fail(failures, "research_blunt_ke: FEATURE_BLUNT_TISSUE_KE_GATE must be on")
	if not _ResearchAnchors.blunt_ke_budget_reduces_bone_load():
		_fail(
			failures,
			"research_blunt_ke: ke_to_bone %.0f should be < committed %.0f minus budget"
			% [
				_ResearchAnchors.blunt_ke_after_arm_budget_at_committed_oberhau(),
				_ResearchAnchors.committed_oberhau_ke_j(),
			]
		)


## Research gate: ATLS stepped blood consciousness modifier decreases with volume loss.
static func _run_research_atls_blood_consciousness_monotonic(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS:
		_fail(failures, "research_atls_consciousness: FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS must be on")
	if not _ResearchAnchors.atls_blood_consciousness_monotonic():
		_fail(failures, "research_atls_consciousness: modifier must decrease 100%%→35%% remaining")


## Research gate: pain performance decreases at NRS 4/6/8; -8% at first effect.
static func _run_research_pain_performance_nrs_bands(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.pain_performance_monotonic_with_nrs():
		_fail(
			failures,
			"research_pain_perf: modifier at NRS4=%.3f want ~%.2f and monotonic bands"
			% [
				_PainConscious.get_pain_performance_modifier(_PainConscious.NRS_FIRST_EFFECT),
				_ResearchAnchors.LITERATURE_PAIN_PERF_AT_NRS4,
			]
		)


## Research gate: neck arterial mult > forearm (penetrating neck vascular risk).
static func _run_research_neck_arterial_epidemiology(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.neck_arterial_mult_exceeds_forearm():
		_fail(failures, "research_neck_arterial: neck mult must exceed forearm")


## Research gate: triage danger > peril > death threshold; danger time > peril time.
static func _run_research_medical_triage_thresholds(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.medical_triage_thresholds_ordered():
		_fail(
			failures,
			"research_triage: danger>peril>death; class_IV_window; peril_s=%.0f < reference_TTD=%.1fs"
			% [_Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS, _ResearchAnchors.clinical_ttd_seconds(1.0)]
		)


## Research gate: joule armor KE conserved; transmitted fraction = sqrt(remaining/strike).
static func _run_research_joule_sqrt_transmission(failures: PackedStringArray) -> void:
	if not _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		_fail(failures, "research_joule: FEATURE_JOULE_ARMOR_BUDGET must be on")
	if not _ResearchAnchors.joule_transmission_bounded_and_conserved():
		_fail(
			failures,
			"research_joule: cuirass frac %.3f must match sqrt law and lie in 0.15-0.85"
			% _ResearchAnchors.joule_cuirass_transmitted_ke_fraction()
		)


## Research gate: material curves on → full blend weight 1.0 (M2 production).
static func _run_research_material_curve_full_blend(failures: PackedStringArray) -> void:
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		_fail(failures, "research_mat_curve: FEATURE_MATERIAL_FAILURE_CURVES must be on")
	if not _ResearchAnchors.material_curves_full_blend_when_on():
		_fail(
			failures,
			"research_mat_curve: MATERIAL_CURVE_BLEND_WEIGHT %.2f want 1.0 when curves on"
			% _Bleeding.MATERIAL_CURVE_BLEND_WEIGHT
		)


## Research gate: registry count matches documented RESEARCH_HARNESS_GATE_IDS (drift guard).
static func _run_research_gate_registry_count(failures: PackedStringArray) -> void:
	var want: int = _ResearchAnchors.research_harness_gate_count()
	if want < 1:
		_fail(failures, "research_registry: RESEARCH_HARNESS_GATE_IDS is empty")
	# Meta-gate: when adding `_run_research_*`, append id to RESEARCH_HARNESS_GATE_IDS + checklist table.
	const EXPECTED_RESEARCH_GATES: int = 37
	if want != EXPECTED_RESEARCH_GATES:
		_fail(
			failures,
			"research_registry: RESEARCH_HARNESS_GATE_IDS count %d != expected %d"
			% [want, EXPECTED_RESEARCH_GATES]
		)


## Research gate: triage danger window (90 s) exceeds reference exsanguination TTD (~48 s).
static func _run_research_triage_danger_seconds_vs_ttd(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.medical_triage_danger_seconds_exceeds_reference_ttd():
		_fail(
			failures,
			"research_triage: DANGER_SECONDS %.0f should exceed reference TTD %.1fs"
			% [_Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS, _ResearchAnchors.clinical_ttd_seconds(1.0)]
		)


## F5 headless proxy: shallow forearm graze — no bone, tissue pen shallow.
static func _run_f5_headless_forearm_graze(failures: PackedStringArray) -> void:
	var m: Dictionary = _CalibrationAudit.f5_forearm_graze_metrics()
	if float(m.get("final_bone", 0.0)) >= 0.01:
		_fail(failures, "f5_graze: final_bone %.2f should be 0" % float(m.get("final_bone", 0.0)))
	if float(m.get("final_cut", 0.0)) <= 0.0:
		_fail(failures, "f5_graze: want tissue cut damage on graze")
	if float(m.get("penetration_to_tissue_mm", 99.0)) > 1.5:
		_fail(
			failures,
			"f5_graze: tissue pen %.2f too deep for graze"
			% float(m.get("penetration_to_tissue_mm", 0.0))
		)


## F5 headless proxy: cuirass reduces chest penetration or total damage.
static func _run_f5_headless_armored_chest(failures: PackedStringArray) -> void:
	var m: Dictionary = _CalibrationAudit.f5_armored_chest_metrics()
	var bare_pen: float = float(m.get("bare_tissue_pen_mm", 0.0))
	var arm_pen: float = float(m.get("armored_tissue_pen_mm", 0.0))
	var bare_dmg: float = float(m.get("bare_damage_sum", 0.0))
	var arm_dmg: float = float(m.get("armored_damage_sum", 0.0))
	if arm_pen >= bare_pen - 0.01 and not bool(m.get("armor_stopped", false)):
		_fail(
			failures,
			"f5_armored: armored pen %.2f should be < bare %.2f"
			% [arm_pen, bare_pen]
		)
	if arm_dmg >= bare_dmg - 0.5:
		_fail(
			failures,
			"f5_armored: armored damage %.1f should be < bare %.1f"
			% [arm_dmg, bare_dmg]
		)


## F5 headless proxy: mace elbow blunt fracture at KE above anchor.
static func _run_f5_headless_mace_elbow(failures: PackedStringArray) -> void:
	var m: Dictionary = _CalibrationAudit.f5_mace_elbow_metrics()
	if float(m.get("final_bone", 0.0)) < 0.5:
		_fail(
			failures,
			"f5_mace_elbow: final_bone %.2f want >=0.5 at KE %.0f"
			% [float(m.get("final_bone", 0.0)), float(m.get("strike_ke_j", 0.0))]
		)
