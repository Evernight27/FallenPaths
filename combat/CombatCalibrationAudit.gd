class_name CombatCalibrationAudit
extends RefCounted

## Compare shipped combat numbers to documented physics / medical anchors.
## Writes **`.calibration_audit.txt`**; optional gate via **`run_all_combat_checks.gd`**.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _CombatLayerTissue := preload("res://core/CombatLayerTissue.gd")
const _ArmorPenetrationTrace := preload("res://armor/ArmorPenetrationTrace.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _Pain := preload("res://core/PainConsciousnessConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _HumanSpecies := preload("res://species/human.tres")
const _GoblinSpecies := preload("res://species/goblin.tres")
const _SpeciesResource := preload("res://species/SpeciesResource.gd")
const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _WeaponDamage := preload("res://weapon/WeaponDamageHelper.gd")
const _AttackInstance := preload("res://weapon/AttackInstance.gd")
const _MaterialFailureCurves := preload("res://core/MaterialFailureCurves.gd")
const _DamageMechanism := preload("res://core/CombatDamageMechanism.gd")
const _TissueEnergyCapacity := preload("res://core/TissueEnergyCapacity.gd")
const _ResearchAnchors := preload("res://core/CombatResearchAnchors.gd")
const _CoreEntity := preload("res://core/CoreEntity.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
const REPORT_FILENAME := ".calibration_audit.txt"
const BIND_THRESHOLD := _CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
const DEFLECT_THRESHOLD := _CombatConstants.PARRY_DEFLECT_THRESHOLD
## Soak lines tag `parry_deflect` for full-stop outcomes; `parry_bind` only when `parry_was_bind`  -  allow ctrl at threshold on deflect rows.
const BIND_CTRL_AUDIT_EPS := 0.001

# de Leva (1996) whole-body segment mass % (adult male reference; game uses abstract 6-part lumping).
const DE_LEVA_REFERENCE_PCT: Dictionary = {
	"head": 6.9,
	"chest_proxy_trunk": 43.5,
	"upper_arm_each": 2.7,
	"forearm_hand_lump": 5.0,
	"thigh_each": 14.2,
	"shank_foot_lump": 5.5,
}


static func run_and_write_report(soak_log_path: String = "") -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("--- FP_CALIBRATION_AUDIT ---")
	lines.append("purpose=physics_and_medical_anchor_comparison")
	_append_bleeding_section(lines, failures)
	_append_species_pain_section(lines, failures)
	_append_impact_ke_section(lines, failures)
	_append_derived_limb_capacity_section(lines)
	_append_parry_formula_section(lines, failures)
	_append_soak_parry_section(lines, failures, _resolve_soak_log_path(soak_log_path))
	_append_material_failure_production_section(lines, failures)
	_append_production_sim_flags_inventory(lines)
	_append_research_benchmarks_section(lines)
	_append_formation_diagram_vitals_section(lines)
	_append_f5_scenario_headless_section(lines, failures)
	lines.append("failures=%d" % failures.size())
	for msg in failures:
		lines.append("FAIL: %s" % msg)
	lines.append("ok=%s" % str(failures.is_empty()).to_lower())
	lines.append("--- END FP_CALIBRATION_AUDIT ---")
	var body: String = "\n".join(lines) + "\n"
	_write_report(body)
	return {"ok": failures.is_empty(), "failures": failures, "lines": lines}


static func _resolve_soak_log_path(explicit: String) -> String:
	if not explicit.is_empty() and FileAccess.file_exists(explicit):
		return explicit
	var root: String = ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
	var default_path: String = "%s/.f5_soak_in.txt" % root
	if FileAccess.file_exists(default_path):
		return default_path
	return ""


static func _write_report(body: String) -> void:
	var path: String = ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
	path = "%s/%s" % [path, REPORT_FILENAME]
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(body)
		f.close()
	print("FP_HARNESS_SUMMARY: wrote %s" % path)


static func _append_bleeding_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
	lines.append("")
	lines.append("[bleeding_vs_ATLS]")
	var ttd: float = _Bleeding.seconds_to_exsanguination(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, _Bleeding.MAX_BLOOD_VOLUME, 1.0
	)
	var loss_per_s: float = _Bleeding.blood_volume_loss_per_second(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, 1.0
	)
	lines.append(
		"reference_uncontrolled_rate=%.2f HP/s loss_per_s=%.3f %%/s TTD_s=%.1f"
		% [_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, loss_per_s, ttd]
	)
	lines.append(
		"ATLS_death_threshold_remaining=%.0f%% (~%.0f%% lost; Class IV begins >40%% lost at <60%% remaining)"
		% [_Bleeding.BLOOD_LOSS_DEATH_THRESHOLD, 100.0 - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD]
	)
	lines.append(
		"reference_bleed_formula=critical_cut(%.2f)*head(%.2f)*arterial(%.2f)=%.2f_HP_per_s"
		% [
			float(_Bleeding.BLEEDING_RATES[_Bleeding.INJURY_TYPE_CUT][_Bleeding.SEVERITY_CRITICAL]),
			float(_Bleeding.BODY_PART_BLEEDING_MULTIPLIERS["head"]),
			_Bleeding.ARTERIAL_BLEEDING_MULTIPLIER,
			_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE,
		]
	)
	lines.append("clinical_TTD_band_untreated_arterial=30-120s (order-of-minutes)")
	var derived_mult: float = _ResearchAnchors.derived_blood_loss_multiplier_for_ttd(
		_ResearchAnchors.LITERATURE_TTD_TARGET_S
	)
	lines.append(
		"blood_loss_multiplier_shipped=%.3f derived_for_48s=%.4f matches=%s"
		% [
			_Bleeding.BLOOD_LOSS_RATE_MULTIPLIER,
			derived_mult,
			str(_ResearchAnchors.blood_loss_multiplier_matches_derived()).to_lower(),
		]
	)
	var ttd_ok: bool = ttd >= 30.0 and ttd <= 120.0
	lines.append("audit_TTD_in_clinical_band=%s" % str(ttd_ok).to_lower())
	if not ttd_ok:
		failures.append("bleeding: reference TTD %.1fs outside 30-120s" % ttd)
	var pressure_ttd: float = ttd * 2.0
	lines.append("estimated_TTD_with_sustained_pressure_halve=%.0fs" % pressure_ttd)
	_append_literal_blood_ml_section(lines)
	lines.append("triage_danger_remaining=%.0f%% peril=%.0f%%" % [
		_Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING,
		_Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING,
	])
	lines.append(
		"triage_ATLS_class_IV_window=%s class_III_min=%.0f%% death=%.0f%%"
		% [
			str(_ResearchAnchors.medical_triage_blood_bands_in_class_iv_window()).to_lower(),
			_Bleeding.ATLS_CLASS_III_MIN_REMAINING,
			_Bleeding.BLOOD_LOSS_DEATH_THRESHOLD,
		]
	)


static func _append_literal_blood_ml_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[literal_blood_ml_pilot]")
	lines.append(
		"FEATURE_LITERAL_BLOOD_ML=%s"
		% str(_Bleeding.FEATURE_LITERAL_BLOOD_ML).to_lower()
	)
	var ref_h: float = _HumanSpecies.resolved_reference_mass_kg()
	var ref_g: float = _GoblinSpecies.resolved_reference_mass_kg()
	var hum_ml: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_h)
	var gob_ml: float = _BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_g)
	lines.append(
		"human_blood_ml_max=%.0f ref_kg=%.1f goblin_blood_ml_max=%.0f ref_kg=%.1f"
		% [hum_ml, ref_h, gob_ml, ref_g]
	)
	var rate: float = _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE
	var ttd_s: float = _Bleeding.seconds_to_exsanguination(rate)
	lines.append(
		"reference_uncontrolled_bleed_rate=%.2f TTD_to_death_threshold_s=%.1f (percent and mL bridge match)"
		% [rate, ttd_s]
	)
	var implied_ml_s: float = _ResearchAnchors.reference_uncontrolled_implied_ml_per_second(ref_h, 1.0)
	var implied_ml_min: float = implied_ml_s * 60.0
	lines.append(
		"reference_implied_ml_per_s=%.2f implied_ml_per_min=%.1f"
		% [implied_ml_s, implied_ml_min]
	)
	lines.append(
		"note=HP_per_s_is_abstract_game_unit; implied_mL_is_percent_bridge_only; clinical_TTD_band=30-120s"
	)
	lines.append(
		"bridge=loss_ml_per_s = (rate * BLOOD_LOSS_RATE_MULTIPLIER) * ml_max / MAX_BLOOD_VOLUME"
	)
	var bleed_deriv: Dictionary = _ResearchAnchors.reference_bleed_rate_derivation()
	lines.append(
		"reference_bleed_product=%.2f cut_crit=%.1f head_mult=%.1f arterial_mult=%.1f matches_const=%s"
		% [
			float(bleed_deriv.get("product_hp_per_s", 0.0)),
			float(bleed_deriv.get("critical_cut_hp_per_s", 0.0)),
			float(bleed_deriv.get("head_part_mult", 0.0)),
			float(bleed_deriv.get("arterial_mult", 0.0)),
			str(bool(bleed_deriv.get("matches_reference_const", false))).to_lower(),
		]
	)
	lines.append(
		"blood_loss_multiplier_shipped=%.3f derived=%.4f matches=%s clinical_ttd_s=%.1f ml_parity=%s"
		% [
			float(bleed_deriv.get("shipped_blood_loss_multiplier", 0.0)),
			float(bleed_deriv.get("derived_blood_loss_multiplier", 0.0)),
			str(bool(bleed_deriv.get("multiplier_matches_derived", false))).to_lower(),
			float(bleed_deriv.get("clinical_ttd_s", 0.0)),
			str(bool(bleed_deriv.get("ml_ttd_parity_ok", false))).to_lower(),
		]
	)
	_append_layer_tissue_section(lines)
	_append_penetration_pipeline_section(lines)
	_append_wound_depth_section(lines)
	_append_material_failure_curves_section(lines)
	_append_layer_tissue_curves_section(lines)


static func _append_layer_tissue_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[layer_tissue_pilot]")
	lines.append("FEATURE_LAYER_TISSUE=%s" % str(_Bleeding.FEATURE_LAYER_TISSUE).to_lower())
	var arm_stack: Array = _CombatLayerTissue.soft_tissue_layer_stack_mm("right_arm")
	var arm_pen: Dictionary = _CombatLayerTissue.penetration_after_soft_tissue("right_arm", 6.0, true)
	lines.append(
		"right_arm soft_tissue_stack_mm=%s budget=%.1f pen=6 absorbed=%.1f to_bone=%.1f"
		% [
			str(arm_stack),
			_CombatLayerTissue.soft_tissue_budget_mm("right_arm"),
			float(arm_pen.get("layer_absorbed_mm", 0.0)),
			float(arm_pen.get("penetration_to_bone_mm", 0.0)),
		]
	)
	lines.append(
		"pen_depth_arterial_mult shallow=%.2f deep=%.2f"
		% [
			_Bleeding.penetration_depth_arterial_mult(0.8),
			_Bleeding.penetration_depth_arterial_mult(6.0),
		]
	)
	lines.append("note=2-sheet stack (subcut+muscle); flat budget when curves off; full FEM deferred")


static func _append_penetration_pipeline_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[penetration_pipeline_s7]")
	lines.append(
		"FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS=%s"
		% str(_Bleeding.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS).to_lower()
	)
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass != null:
		var shallow: Dictionary = _ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 3.0)
		var deep: Dictionary = _ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 6.0)
		lines.append(
			"cuirass_pen3_tissue_mm=%.2f stopped=%s pen6_tissue_mm=%.2f"
			% [
				float(shallow.get("penetration_to_tissue_mm", 0.0)),
				str(shallow.get("stopped_by_armor", false)).to_lower(),
				float(deep.get("penetration_to_tissue_mm", 0.0)),
			]
		)
	lines.append(
		"order=armor RHA depth budget -> soft tissue (FEATURE_LAYER_TISSUE) -> MFB bone pen"
	)
	lines.append(
		"atls_class_85=%d mod=%.2f atls_class_50=%d mod=%.2f"
		% [
			_Bleeding.atls_hemorrhage_class_from_remaining_pct(85.0),
			_Bleeding.blood_consciousness_modifier_from_remaining(
				85.0,
				_Pain.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
				_Pain.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
				_Pain.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
			),
			_Bleeding.atls_hemorrhage_class_from_remaining_pct(50.0),
			_Bleeding.blood_consciousness_modifier_from_remaining(
				50.0,
				_Pain.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
				_Pain.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
				_Pain.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
			),
		]
	)


static func _append_wound_depth_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[wound_depth_s8]")
	lines.append(
		"FEATURE_PENETRATION_DEPTH_SEVERITY=%s FEATURE_BLUNT_TISSUE_KE_GATE=%s"
		% [
			str(_Bleeding.FEATURE_PENETRATION_DEPTH_SEVERITY).to_lower(),
			str(_Bleeding.FEATURE_BLUNT_TISSUE_KE_GATE).to_lower(),
		]
	)
	lines.append(
		"pen_depth_mult pen=0.8mm=%.2f pen=6mm=%.2f arterial_mult_deep=%.2f arm_blunt_ke_budget_J=%.0f"
		% [
			_Bleeding.penetration_depth_severity_mult(0.8),
			_Bleeding.penetration_depth_severity_mult(6.0),
			_Bleeding.penetration_depth_arterial_mult(6.0),
			float(_CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0)),
		]
	)


static func _append_material_failure_curves_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[material_failure_curves_pilot]")
	lines.append(
		"FEATURE_MATERIAL_FAILURE_CURVES=%s"
		% str(_Bleeding.FEATURE_MATERIAL_FAILURE_CURVES).to_lower()
	)
	var part: String = "right_arm"
	var sub: String = "forearm"
	var pen_shallow: float = 0.8
	var pen_deep: float = 6.0
	var ke_ref: float = _MaterialFailureCurves.reference_committed_arm_ke_j()
	lines.append(
		"cut_tissue_pen0.8=%.2f pen6=%.2f depth_mult_0.8=%.2f depth_mult_6=%.2f"
		% [
			_MaterialFailureCurves.cut_tissue_damage_from_pen(pen_shallow, part),
			_MaterialFailureCurves.cut_tissue_damage_from_pen(pen_deep, part),
			_MaterialFailureCurves.penetration_depth_mult(pen_shallow),
			_MaterialFailureCurves.penetration_depth_mult(pen_deep),
		]
	)
	var bone_ke: float = _MaterialFailureCurves.blunt_bone_damage_from_ke(ke_ref, part, sub)
	var anchor_j: float = _DamageMechanism.blunt_fracture_j_anchor(part, sub)
	lines.append(
		"blunt_bone_ke137_J=%.2f anchor_J=%.0f excess_J=%.1f"
		% [bone_ke, anchor_j, maxf(0.0, ke_ref - anchor_j)]
	)
	lines.append(
		"law=cut piecewise yield=%.1f ultimate=%.1f mm; blunt bone = MFB j_excess; depth mult delegates BleedingConstants"
		% [_MaterialFailureCurves.CUT_TISSUE_YIELD_PEN_MM, _MaterialFailureCurves.cut_tissue_ultimate_pen_mm()]
	)


static func _append_layer_tissue_curves_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[layer_tissue_curves_m3]")
	lines.append(
		"FEATURE_LAYER_TISSUE_CURVES=%s FEATURE_LAYER_TISSUE=%s"
		% [
			str(_Bleeding.FEATURE_LAYER_TISSUE_CURVES).to_lower(),
			str(_Bleeding.FEATURE_LAYER_TISSUE).to_lower(),
		]
	)
	var state: Array = _CombatLayerTissue.seed_layer_state_for_part("right_arm")
	var shallow: Dictionary = _CombatLayerTissue.penetration_through_layers("right_arm", 0.5, state, true)
	var deep_state: Array = _CombatLayerTissue.seed_layer_state_for_part("right_arm")
	var deep: Dictionary = _CombatLayerTissue.penetration_through_layers("right_arm", 2.5, deep_state, true)
	var sh_states: Array = shallow.get("layer_states", [])
	var dp_states: Array = deep.get("layer_states", [])
	var sh_sub: String = str(sh_states[0].get("state", "?")) if not sh_states.is_empty() else "?"
	var dp_sub: String = str(dp_states[0].get("state", "?")) if not dp_states.is_empty() else "?"
	lines.append(
		"arm_pen0.5_to_bone=%.2f subcut_state=%s pen2.5_subcut=%s to_bone=%.2f"
		% [
			float(shallow.get("penetration_to_bone_mm", 0.0)),
			sh_sub,
			dp_sub,
			float(deep.get("penetration_to_bone_mm", 0.0)),
		]
	)
	lines.append("note=tissue_layer_state reset on apply_species; ruptured subcut bleed mult=%.2f" % _Bleeding.LAYER_RUPTURE_SUBCUT_BLEED_MULT)


static func _append_material_failure_production_section(
	lines: PackedStringArray, failures: PackedStringArray
) -> void:
	lines.append("")
	lines.append("[material_failure_production]")
	lines.append("M4_damage_D=cancelled (M3 layer curves sufficient; see Decision log)")
	lines.append(
		"production_flags curves=%s layer_curves=%s layer_tissue=%s damage_D=%s energy_pool=%s joule_armor=%s literal_blood_ml=%s"
		% [
			str(_Bleeding.FEATURE_MATERIAL_FAILURE_CURVES).to_lower(),
			str(_Bleeding.FEATURE_LAYER_TISSUE_CURVES).to_lower(),
			str(_Bleeding.FEATURE_LAYER_TISSUE).to_lower(),
			str(_Bleeding.FEATURE_TISSUE_DAMAGE_D).to_lower(),
			str(_Bleeding.FEATURE_TISSUE_ENERGY_POOL).to_lower(),
			str(_CombatConstants.FEATURE_JOULE_ARMOR_BUDGET).to_lower(),
			str(_Bleeding.FEATURE_LITERAL_BLOOD_ML).to_lower(),
		]
	)
	lines.append(
		"enablement_order=1 curves 2 layer_tissue 3 layer_curves 4 damage_D(cancelled) 5 energy_pool 6 joule_armor 7 literal_blood_ml"
	)
	if not _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
		failures.append("material_production: FEATURE_JOULE_ARMOR_BUDGET must be true (S11-A)")
	if not _Bleeding.FEATURE_LITERAL_BLOOD_ML:
		failures.append("material_production: FEATURE_LITERAL_BLOOD_ML must be true (S11-B)")
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES and not _Bleeding.FEATURE_LAYER_TISSUE:
		failures.append(
			"material_production: FEATURE_LAYER_TISSUE_CURVES requires FEATURE_LAYER_TISSUE true"
		)
	var ttd_s: float = _Bleeding.seconds_to_exsanguination(
		_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE, _Bleeding.MAX_BLOOD_VOLUME, 1.0
	)
	var ttd_ok: bool = ttd_s >= 30.0 and ttd_s <= 120.0
	lines.append("audit_TTD_s=%.1f in_band_30-120=%s" % [ttd_s, str(ttd_ok).to_lower()])
	if not ttd_ok:
		failures.append("material_production: TTD %.1fs outside 30-120s" % ttd_s)
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword != null:
		var ai: AttackInstance = _AttackInstance.new("oberhau", 1.0)
		ai.archetype = {"kinematic_delivery": _WeaponConstants.KINEMATIC_DELIVERY_SWING}
		ai.delivery_commit_fraction = 0.78
		var ke_j: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai)
		var ke_ok: bool = _DesignAnchors.committed_strike_ke_in_strict_band(ke_j)
		lines.append("committed_oberhau_ke_J=%.0f strict_70-140=%s" % [ke_j, str(ke_ok).to_lower()])
		if not ke_ok:
			failures.append("material_production: committed oberhau KE %.0f outside 70-140 J" % ke_j)
	var arm_pen6: Dictionary = _material_failure_reference_arm_pen6()
	lines.append(
		"reference_arm_pen6_to_bone=%.2f curve_cut_pen6=%.2f"
		% [
			float(arm_pen6.get("penetration_to_bone_mm", 0.0)),
			_MaterialFailureCurves.cut_tissue_damage_from_pen(6.0, "right_arm"),
		]
	)
	lines.append(material_failure_headless_gate_line())
	_append_tissue_energy_pool_section(lines, failures)


static func _material_failure_reference_arm_pen6() -> Dictionary:
	var part: String = "right_arm"
	var pen: float = 6.0
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		var arm_state: Array = _CombatLayerTissue.seed_layer_state_for_part(part)
		return _CombatLayerTissue.penetration_through_layers(part, pen, arm_state, true)
	if _Bleeding.FEATURE_LAYER_TISSUE:
		return _CombatLayerTissue.penetration_after_soft_tissue(part, pen, true)
	return {"penetration_to_bone_mm": pen}


static func material_failure_headless_gate_line() -> String:
	if _Bleeding.FEATURE_TISSUE_DAMAGE_D:
		return "headless_M5_gate=partial_enablement_review_flags"
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES and not _Bleeding.FEATURE_LAYER_TISSUE:
		return "headless_M5_gate=partial_enablement_review_flags"
	if not _Bleeding.FEATURE_MATERIAL_FAILURE_CURVES:
		return "headless_M5_gate=all_pilot_flags_off_and_anchors_locked"
	if (
		_Bleeding.FEATURE_LITERAL_BLOOD_ML
		and _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
		and _Bleeding.FEATURE_TISSUE_ENERGY_POOL
		and _Bleeding.FEATURE_LAYER_TISSUE_CURVES
	):
		return "headless_M5_gate=p3b_full_including_energy_pool_joule_armor_and_literal_blood_ml"
	if (
		_CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
		and _Bleeding.FEATURE_TISSUE_ENERGY_POOL
		and _Bleeding.FEATURE_LAYER_TISSUE_CURVES
	):
		return "headless_M5_gate=p3b_full_including_energy_pool_and_joule_armor"
	if _Bleeding.FEATURE_TISSUE_ENERGY_POOL and _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		return "headless_M5_gate=p3b_full_including_energy_pool"
	if _Bleeding.FEATURE_LAYER_TISSUE_CURVES:
		return "headless_M5_gate=curves_layer_tissue_and_curves_on"
	if _Bleeding.FEATURE_LAYER_TISSUE:
		return "headless_M5_gate=curves_and_layer_tissue_on"
	return "headless_M5_gate=curves_on_layer_pilots_off_anchors_locked"


static func _append_tissue_energy_pool_section(
	lines: PackedStringArray, failures: PackedStringArray
) -> void:
	lines.append("")
	lines.append("[tissue_energy_pool_m6]")
	lines.append("FEATURE_TISSUE_ENERGY_POOL=%s" % str(_Bleeding.FEATURE_TISSUE_ENERGY_POOL).to_lower())
	var part: String = "right_arm"
	var body_max: int = _DesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
	var cap_j: float = _TissueEnergyCapacity.capacity_j_for_part(part, body_max)
	var display_half: float = _TissueEnergyCapacity.display_tissue_from_remaining_j(
		body_max, cap_j * 0.5, cap_j
	)
	lines.append(
		"human_arm_anchor body_max=%d capacity_J=%.0f display_at_50pct_J=%.0f (target ~6)"
		% [body_max, cap_j, display_half]
	)
	var parity: Dictionary = tissue_energy_hp_vs_j_parity_metrics()
	var tissue_j: float = float(parity.get("tissue_applied_j", 0.0))
	var tissue_hp: float = float(parity.get("tissue_applied_hp", 0.0))
	var parity_ok: bool = _damage_within_pct_tolerance(tissue_hp, tissue_j, 0.05)
	lines.append(
		"production_hit_tissue_applied_J=%.2f HP_path=%.2f within_5pct=%s"
		% [tissue_j, tissue_hp, str(parity_ok).to_lower()]
	)
	lines.append(
		"note=J synced from cut+blunt displays (dual-stream severance); extras.disable_tissue_energy_pool for HP baseline"
	)
	if _Bleeding.FEATURE_TISSUE_ENERGY_POOL and not parity_ok:
		failures.append(
			"tissue_energy: J path tissue %.2f vs HP path %.2f outside 5%%"
			% [tissue_j, tissue_hp]
		)


static func _damage_within_pct_tolerance(baseline: float, actual: float, pct: float) -> bool:
	if baseline <= 0.01:
		return actual <= 0.01
	return absf(actual - baseline) <= baseline * pct


## Compare production J debit vs classic HP pools on same hit (harness/audit).
static func tissue_energy_hp_vs_j_parity_metrics() -> Dictionary:
	var part: String = "right_arm"
	var extras: Dictionary = {
		"hit_sub_region": "forearm",
		"strike_ke_j": 12.0,
		"disable_layer_tissue": true,
	}
	var ent_j: CoreEntity = _audit_new_entity("SWORD")
	var res_j: Dictionary = ent_j.take_damage_split(8.0, 1.0, part, 4.0, -1.0, -1.0, extras)
	var extras_hp: Dictionary = extras.duplicate()
	extras_hp["disable_tissue_energy_pool"] = true
	var ent_hp: CoreEntity = _audit_new_entity("SWORD")
	var res_hp: Dictionary = ent_hp.take_damage_split(8.0, 1.0, part, 4.0, -1.0, -1.0, extras_hp)
	var tissue_j: float = (
		float(res_j.get("final_cut", 0.0))
		+ float(res_j.get("final_blunt", 0.0))
		+ float(res_j.get("final_bone", 0.0))
	)
	var tissue_hp: float = (
		float(res_hp.get("final_cut", 0.0))
		+ float(res_hp.get("final_blunt", 0.0))
		+ float(res_hp.get("final_bone", 0.0))
	)
	CombatRegressionHarness._free_harness_node(ent_j)
	CombatRegressionHarness._free_harness_node(ent_hp)
	return {"tissue_applied_j": tissue_j, "tissue_applied_hp": tissue_hp}


static func _append_production_sim_flags_inventory(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[production_sim_flags]")
	lines.append(
		"material_curves=%s layer_tissue=%s layer_curves=%s tissue_energy_pool=%s tissue_damage_D=%s"
		% [
			str(_Bleeding.FEATURE_MATERIAL_FAILURE_CURVES).to_lower(),
			str(_Bleeding.FEATURE_LAYER_TISSUE).to_lower(),
			str(_Bleeding.FEATURE_LAYER_TISSUE_CURVES).to_lower(),
			str(_Bleeding.FEATURE_TISSUE_ENERGY_POOL).to_lower(),
			str(_Bleeding.FEATURE_TISSUE_DAMAGE_D).to_lower(),
		]
	)
	lines.append(
		"pen_depth=%s blunt_tissue_ke=%s atls_stepped=%s absolute_severity=%s joule_armor=%s literal_blood_ml=%s"
		% [
			str(_Bleeding.FEATURE_PENETRATION_DEPTH_SEVERITY).to_lower(),
			str(_Bleeding.FEATURE_BLUNT_TISSUE_KE_GATE).to_lower(),
			str(_Bleeding.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS).to_lower(),
			str(_Bleeding.FEATURE_ABSOLUTE_SEVERITY_BANDS).to_lower(),
			str(_CombatConstants.FEATURE_JOULE_ARMOR_BUDGET).to_lower(),
			str(_Bleeding.FEATURE_LITERAL_BLOOD_ML).to_lower(),
		]
	)
	lines.append(
		"species_derived_limb human=%s goblin=%s"
		% [
			str(_HumanSpecies.feature_derived_limb_capacity).to_lower(),
			str(_GoblinSpecies.feature_derived_limb_capacity).to_lower(),
		]
	)
	lines.append("doc=docs/LIVE_PATHS.md#tier-5-simulation-flags-2026-05")


static func _append_research_benchmarks_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[research_benchmarks]")
	lines.append(
		"purpose=compare_shipped_constants_to_ATLS_biomechanics_anatomy_literature; harness _run_research_* gates drift"
	)
	_ResearchAnchors.append_research_benchmark_lines(lines)
	var human_total: int = _HumanSpecies.live_tissue_sum()
	var pct_head: float = 100.0 * float(_HumanSpecies.head) / float(human_total)
	lines.append(
		"de_leva_head_pct=%.1f game_head_lump_pct=%.1f chest_proxy_trunk=%.1f verdict=%s"
		% [
			DE_LEVA_REFERENCE_PCT["head"],
			pct_head,
			DE_LEVA_REFERENCE_PCT["chest_proxy_trunk"],
			"note" if absf(pct_head - DE_LEVA_REFERENCE_PCT["head"]) > 4.0 else "pass",
		]
	)
	lines.append("doc=docs/LIVE_PATHS.md#research-audit · core/CombatResearchAnchors.gd")


static func _audit_new_entity(weapon_id: String) -> CoreEntity:
	var ent: CoreEntity = _CoreEntity.new()
	ent.apply_species()
	ent.dominant_hand = "right_arm"
	ent.offhand_functionality = 1.0
	var w: Weapon = _Weapon.create_from_definition(weapon_id)
	if w != null:
		ent.equip_weapon(w)
	CombatRegressionHarness._track_harness_node(ent)
	return ent


## M5 F5 proxy: forearm graze  -  shallow pen, no bone chip (production stack).
static func f5_forearm_graze_metrics() -> Dictionary:
	var ent: CoreEntity = _audit_new_entity("SWORD")
	var extras: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
	var res: Dictionary = ent.take_damage_split(8.0, 0.0, "right_arm", 0.5, -1.0, -1.0, extras)
	var out: Dictionary = {
		"final_bone": float(res.get("final_bone", 0.0)),
		"final_cut": float(res.get("final_cut", 0.0)),
		"penetration_to_tissue_mm": float(res.get("penetration_to_tissue_mm", -1.0)),
		"penetration_to_bone_mm": float(res.get("penetration_to_bone_mm", -1.0)),
	}
	CombatRegressionHarness._free_harness_node(ent)
	return out


## M5 F5 proxy: cuirass chest hit  -  armor reduces tissue pen vs bare (committed-scale cut).
static func f5_armored_chest_metrics() -> Dictionary:
	var part: String = "chest"
	var sub: String = "thoracic"
	var pen: float = 6.0
	var cut: float = 18.0
	var extras: Dictionary = {"hit_sub_region": sub, "strike_ke_j": 120.0}
	var bare: CoreEntity = _audit_new_entity("SWORD")
	var res_bare: Dictionary = bare.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
	var armored: CoreEntity = _audit_new_entity("SWORD")
	var cuirass: ArmorPiece = _ArmorPiece.create_from_definition("CUIRASS")
	if cuirass != null:
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
	var out: Dictionary = {
		"bare_tissue_pen_mm": float(res_bare.get("penetration_to_tissue_mm", 0.0)),
		"armored_tissue_pen_mm": float(res_arm.get("penetration_to_tissue_mm", 0.0)),
		"bare_damage_sum": bare_sum,
		"armored_damage_sum": arm_sum,
		"armor_stopped": float(res_arm.get("penetration_to_tissue_mm", 0.0)) < 0.01,
		"transmitted_ke_fraction": float(res_arm.get("transmitted_ke_fraction", -1.0)),
		"armor_ke_absorbed_j": float(res_arm.get("armor_ke_absorbed_j", 0.0)),
	}
	CombatRegressionHarness._free_harness_node(bare)
	CombatRegressionHarness._free_harness_node(armored)
	return out


## M5 F5 proxy: mace elbow  -  blunt KE above anchor fractures (production MFB).
static func f5_mace_elbow_metrics() -> Dictionary:
	var ent: CoreEntity = _audit_new_entity("MACE")
	var j_anchor: float = _DamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
	var strike_ke: float = j_anchor + 24.0
	var res: Dictionary = ent.take_damage_split(
		0.0, 8.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow", "strike_ke_j": strike_ke}
	)
	var out: Dictionary = {
		"strike_ke_j": strike_ke,
		"j_anchor": j_anchor,
		"final_bone": float(res.get("final_bone", 0.0)),
		"final_blunt": float(res.get("final_blunt", 0.0)),
	}
	CombatRegressionHarness._free_harness_node(ent)
	return out


static func _append_formation_diagram_vitals_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[formation_diagram_vitals]")
	lines.append(
		"bar_width=PartyRowFormatter.total_body_health_ratio tissue+bone remaining 0-1"
	)
	lines.append(
		"bar_fill=PartyRowFormatter.body_functionality_ratio green_to_red via formation_health_bar_fill_color"
	)
	lines.append(
		"refresh=BattleScene._tactical_diagram_signature hp fn rank file + tactical hints"
	)
	lines.append(
		"harness=form_health_bar body damage + form_health_tint arm function loss"
	)
	lines.append("FORMATION_HEALTH_BAR_HEIGHT=%d px" % BattleUIConstants.FORMATION_HEALTH_BAR_HEIGHT)


static func _append_f5_scenario_headless_section(
	lines: PackedStringArray, failures: PackedStringArray
) -> void:
	lines.append("")
	lines.append("[f5_scenario_headless]")
	lines.append("purpose=M5_playtest_proxies_full_entity_path; F5_feel_still_optional")
	var graze: Dictionary = f5_forearm_graze_metrics()
	var graze_ok: bool = (
		float(graze.get("final_bone", 0.0)) < 0.01
		and float(graze.get("final_cut", 0.0)) > 0.0
		and float(graze.get("penetration_to_tissue_mm", 0.0)) <= 1.0
	)
	lines.append(
		"forearm_graze pen=0.5 final_bone=%.2f final_cut=%.2f tissue_pen=%.2f verdict=%s"
		% [
			float(graze.get("final_bone", 0.0)),
			float(graze.get("final_cut", 0.0)),
			float(graze.get("penetration_to_tissue_mm", 0.0)),
			"pass" if graze_ok else "warn",
		]
	)
	if not graze_ok:
		failures.append("f5_headless: forearm graze want no bone and shallow tissue pen")
	var chest: Dictionary = f5_armored_chest_metrics()
	var chest_ok: bool = (
		float(chest.get("armored_tissue_pen_mm", 99.0))
		< float(chest.get("bare_tissue_pen_mm", 0.0)) - 0.01
		or bool(chest.get("armor_stopped", false))
	) and float(chest.get("armored_damage_sum", 99.0)) < float(chest.get("bare_damage_sum", 0.0)) - 0.5
	lines.append(
		"armored_chest bare_pen=%.2f armored_pen=%.2f bare_dmg=%.1f armored_dmg=%.1f ke_frac=%.3f ke_absorbed_J=%.0f verdict=%s"
		% [
			float(chest.get("bare_tissue_pen_mm", 0.0)),
			float(chest.get("armored_tissue_pen_mm", 0.0)),
			float(chest.get("bare_damage_sum", 0.0)),
			float(chest.get("armored_damage_sum", 0.0)),
			float(chest.get("transmitted_ke_fraction", -1.0)),
			float(chest.get("armor_ke_absorbed_j", 0.0)),
			"pass" if chest_ok else "warn",
		]
	)
	if _CombatConstants.FEATURE_JOULE_ARMOR_BUDGET and float(chest.get("transmitted_ke_fraction", -1.0)) < 0.0:
		failures.append("f5_headless: armored chest missing transmitted_ke_fraction with joule armor on")
	if not chest_ok:
		failures.append("f5_headless: cuirass should reduce chest pen or total damage")
	var mace: Dictionary = f5_mace_elbow_metrics()
	var mace_ok: bool = float(mace.get("final_bone", 0.0)) >= 0.5
	lines.append(
		"mace_elbow KE=%.0f anchor=%.0f final_bone=%.2f verdict=%s"
		% [
			float(mace.get("strike_ke_j", 0.0)),
			float(mace.get("j_anchor", 0.0)),
			float(mace.get("final_bone", 0.0)),
			"pass" if mace_ok else "warn",
		]
	)
	if not mace_ok:
		failures.append("f5_headless: mace elbow want bone chip at KE above anchor")
	lines.append(
		"F5_editor_feel=optional; headless_proxies=%s"
		% ("pass" if graze_ok and chest_ok and mace_ok else "review")
	)


static func _append_species_pain_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
	lines.append("")
	lines.append("[species_human_goblin]")
	lines.append("source_human=res://species/human.tres source_goblin=res://species/goblin.tres")
	var human: SpeciesResource = _HumanSpecies
	var human_total: int = human.live_tissue_sum()
	var pct_head: float = 100.0 * float(human.get_body_part_max("head")) / float(human_total)
	var pct_chest: float = 100.0 * float(human.get_body_part_max("chest")) / float(human_total)
	var pct_arm: float = 100.0 * float(human.get_body_part_max("left_arm")) / float(human_total)
	var pct_leg: float = 100.0 * float(human.get_body_part_max("left_leg")) / float(human_total)
	lines.append(
		"human_tissue_pct head=%.1f chest=%.1f arm_each=%.1f leg_each=%.1f sum=%d"
		% [pct_head, pct_chest, pct_arm, pct_leg, human_total]
	)
	lines.append(
		"de_leva_whole_body_pct head=%.1f trunk~%.1f (game chest=%.1f is trunk subset)"
		% [DE_LEVA_REFERENCE_PCT["head"], DE_LEVA_REFERENCE_PCT["chest_proxy_trunk"], pct_chest]
	)
	var ordering_ok: bool = (
		human.get_body_part_max("chest") > human.get_body_part_max("head")
		and human.get_body_part_max("chest") > human.get_body_part_max("left_leg")
	)
	lines.append("human_chest_largest_segment=%s" % str(ordering_ok).to_lower())
	if not ordering_ok:
		failures.append("species: human chest should be largest tissue segment")
	if human.pain_reference_scale > 0.0:
		failures.append("species: human pain_reference_scale should be -1 (auto)")
	lines.append("human_pain_reference_scale=%.1f" % human.pain_reference_scale)
	var human_pain_ref: float = human.live_pain_reference()
	lines.append("human_pain_reference_auto=%.2f (divisor 32)" % human_pain_ref)
	lines.append("NRS_first_effect_threshold=%.1f (PainConsciousnessConstants)" % _Pain.NRS_FIRST_EFFECT)
	var moderate_damage: float = 6.0
	var effective_one_hit: float = moderate_damage / maxf(human_pain_ref, 0.01)
	lines.append(
		"human_one_moderate_hit_effective_pain=%.2f (~%.1f hits to NRS 4)"
		% [effective_one_hit, _Pain.NRS_FIRST_EFFECT / maxf(effective_one_hit, 0.01)]
	)
	if not _ResearchAnchors.human_live_tissue_sum_matches_design_anchor():
		failures.append("species: human tissue sum want 96 got %d" % human_total)
	if not is_equal_approx(human_pain_ref, 3.0):
		failures.append("species: human pain_reference want 3.0 got %.3f" % human_pain_ref)
	var goblin: SpeciesResource = _GoblinSpecies
	var goblin_total: int = goblin.live_tissue_sum()
	if goblin.pain_reference_scale > 0.0:
		failures.append("species: goblin pain_reference_scale should be -1 (auto)")
	lines.append("goblin_pain_reference_scale=%.1f" % goblin.pain_reference_scale)
	var goblin_pain_ref: float = goblin.live_pain_reference()
	lines.append(
		"goblin_tissue_sum=%d goblin_pain_reference_auto=%.2f"
		% [goblin_total, goblin_pain_ref]
	)
	if not _ResearchAnchors.goblin_live_tissue_sum_in_band():
		failures.append(
			"species: goblin tissue sum out of band got %d want [%d-%d]"
			% [
				goblin_total,
				_ResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MIN,
				_ResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MAX,
			]
		)
	var want_goblin_ref: float = float(goblin_total) / 32.0
	if not is_equal_approx(goblin_pain_ref, want_goblin_ref):
		failures.append(
			"species: goblin pain_reference want %.3f got %.3f" % [want_goblin_ref, goblin_pain_ref]
		)
	var below_human: bool = goblin_pain_ref < human_pain_ref - 0.05
	lines.append("goblin_pain_below_human=%s" % str(below_human).to_lower())
	if not below_human:
		failures.append(
			"species: goblin pain_reference %.3f should be below human %.3f"
			% [goblin_pain_ref, human_pain_ref]
		)
	var human_mass: float = _WeaponDamage.reference_body_mass_kg_from_species(human)
	var goblin_mass: float = _WeaponDamage.reference_body_mass_kg_from_species(goblin)
	lines.append("human_reference_body_mass_kg=%.1f" % human_mass)
	lines.append("goblin_reference_body_mass_kg=%.1f" % goblin_mass)
	if not _ResearchAnchors.human_reference_mass_matches_design_anchor():
		failures.append(
			"species: human body mass want %.1f got %.1f"
			% [_DesignAnchors.REFERENCE_ADULT_MASS_KG, human_mass]
		)
	if not _ResearchAnchors.goblin_reference_mass_matches_anchor():
		failures.append(
			"species: goblin body mass want %.1f got %.1f"
			% [_ResearchAnchors.GOBLIN_REFERENCE_MASS_KG, goblin_mass]
		)
	if not _ResearchAnchors.goblin_mass_below_human():
		failures.append(
			"species: goblin body mass %.1f should be below human %.1f" % [goblin_mass, human_mass]
		)
	var human_blunt_chest: float = human_mass * 0.28
	var goblin_blunt_chest: float = goblin_mass * 0.28
	lines.append(
		"human_blunt_chest_kg_est=%.2f goblin_blunt_chest_kg_est=%.2f (chest fraction 0.28)"
		% [human_blunt_chest, goblin_blunt_chest]
	)


static func _append_parry_formula_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
	lines.append("")
	lines.append("[parry_physics_nominal_sword]")
	lines.append(
		"PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f"
		% [_CombatConstants.PARRY_DEFLECT_THRESHOLD, _CombatConstants.PARRY_BIND_CONTROL_THRESHOLD]
	)
	var pa_nom: float = 8.0
	var cd_nom: float = 12.0
	var margin: float = _CombatConstants.parry_deflect_margin_ratio(cd_nom, pa_nom)
	var ctrl: float = _CombatConstants.parry_control_for_bind_deflect(
		cd_nom, pa_nom, 0.85, 1.0, false, false, "cut"
	)
	lines.append("nominal_pa=%.1f cd=%.1f margin_ratio=%.2f control=%.2f -> %s" % [
		pa_nom,
		cd_nom,
		margin,
		ctrl,
		"bind" if ctrl >= BIND_THRESHOLD else "deflect",
	])
	var pa_marginal: float = 10.0
	var cd_marginal: float = pa_marginal * _CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.05
	var ctrl_m: float = _CombatConstants.parry_control_for_bind_deflect(
		cd_marginal, pa_marginal, 0.75, 1.0, false, false, "cut"
	)
	lines.append(
		"marginal_stop pa=%.1f cd=%.1f margin=%.2f control=%.2f"
		% [pa_marginal, cd_marginal, _CombatConstants.parry_deflect_margin_ratio(cd_marginal, pa_marginal), ctrl_m]
	)
	lines.append(_CombatConstants.p4d_parry_bind_doc_sync_line())
	if ctrl >= BIND_THRESHOLD and ctrl_m < BIND_THRESHOLD:
		lines.append("formula_ordering=OK (decisive bind > marginal deflect at align 0.75)")
	elif ctrl < BIND_THRESHOLD and ctrl_m >= BIND_THRESHOLD:
		failures.append("parry_formula: nominal vs marginal control ordering inverted")
	else:
		lines.append(
			"formula_note=marginal_stop can still bind when alignment high (%.2f>=%.2f); brawl partials use leak path"
			% [ctrl_m, BIND_THRESHOLD]
		)


static func _append_soak_parry_section(
	lines: PackedStringArray,
	failures: PackedStringArray,
	log_path: String
) -> void:
	lines.append("")
	lines.append("[soak_log_parry_ctrl_vs_BIND_THRESHOLD=%.2f]" % BIND_THRESHOLD)
	if log_path.is_empty():
		lines.append("soak_log=missing (run CombatD001SoakRunner first)")
		return
	var text: String = FileAccess.get_file_as_string(log_path)
	var deflect_n: int = 0
	var bind_n: int = 0
	var partial_n: int = 0
	var bind_ctrl_ok: int = 0
	var deflect_ctrl_ok: int = 0
	var ctrl_mismatch: int = 0
	for raw in text.split("\n"):
		var line: String = str(raw)
		if "parry_deflect" in line and "ctrl=" in line:
			deflect_n += 1
			var ctrl: float = _parse_ctrl(line)
			if ctrl >= 0.0:
				if ctrl < DEFLECT_THRESHOLD + BIND_CTRL_AUDIT_EPS:
					deflect_ctrl_ok += 1
				else:
					ctrl_mismatch += 1
		elif "parry_bind" in line and "flurry_bind" not in line and "ctrl=" in line:
			bind_n += 1
			var ctrl_b: float = _parse_ctrl(line)
			if ctrl_b >= 0.0:
				if ctrl_b >= BIND_THRESHOLD - BIND_CTRL_AUDIT_EPS:
					bind_ctrl_ok += 1
				else:
					ctrl_mismatch += 1
		elif "parry_partial" in line:
			partial_n += 1
	var ii2b_slice: PackedStringArray = _TrackSpecs.slice_lines_for_soak_preset(
		_packed_lines(text), "ii2b"
	)
	var ii2b_stats: Dictionary = _TrackSpecs.parry_outcome_stats(ii2b_slice)
	lines.append("aggregate_log deflect=%d bind=%d partial=%d" % [deflect_n, bind_n, partial_n])
	lines.append("ctrl_consistent_with_threshold=%d mismatch=%d" % [
		deflect_ctrl_ok + bind_ctrl_ok,
		ctrl_mismatch,
	])
	lines.append(_TrackSpecs.parry_stats_summary_line(ii2b_stats))
	lines.append(
		"HEMA_plausibility_headless=%s"
		% ("pass" if _TrackSpecs.ii2b_plausibility_failures(ii2b_stats).is_empty() else "fail")
	)
	var clean: int = deflect_n + bind_n
	var total_parry: int = clean + partial_n
	if total_parry > 0:
		var partial_pct: float = 100.0 * float(partial_n) / float(total_parry)
		var bind_pct: float = 100.0 * float(bind_n) / float(max(clean, 1))
		lines.append(
			"brawl_parry_mix partial=%.0f%% of %d events (bind %.0f%% of clean)"
			% [partial_pct, total_parry, bind_pct]
		)
		lines.append(
			"clinical_read=high partial pct expected in multi-threat (misaligned guard); duel sample too small for pct stats"
		)
	if ctrl_mismatch > 0:
		failures.append("soak_log: %d parry ctrl lines disagree with bind threshold %.2f" % [ctrl_mismatch, BIND_THRESHOLD])


static func _append_impact_ke_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
	lines.append("")
	lines.append("[impact_KE_vs_limb_severance]")
	var sp: SpeciesResource = _HumanSpecies
	var arm_slot: int = sp.left_arm + sp.left_arm_bone
	var leg_slot: int = sp.left_leg + sp.left_leg_bone
	lines.append(
		"DAMAGE_KE_SCALE=%.1f human_arm_slot=%d leg_slot=%d design_KE_arm~%.0fJ leg~%.0fJ"
		% [
			_WeaponConstants.DAMAGE_KE_SCALE,
			arm_slot,
			leg_slot,
			_DesignAnchors.DESIGN_KE_ARM_J,
			_DesignAnchors.DESIGN_KE_LEG_J,
		]
	)
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		failures.append("impact_ke: could not create SWORD")
		return
	var ke_hi: float = -1.0
	for intensity in [0.5, 0.8, 1.0]:
		var ai: AttackInstance = _AttackInstance.new("oberhau", intensity)
		ai.archetype = {"kinematic_delivery": _WeaponConstants.KINEMATIC_DELIVERY_SWING}
		var ke_j: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai)
		var pre_cut: float = _WeaponDamage.compute_pre_armor_cut(sword, ai, 100.0, 1.0)
		var est_damage: float = _WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, ke_j))
		lines.append(
			"oberhau_swing i=%.1f KE_J=%.0f pre_armor_cut=%.1f sqrt_KE_scale_damage=%.1f"
			% [intensity, ke_j, pre_cut, est_damage]
		)
		if is_equal_approx(intensity, 1.0):
			ke_hi = ke_j
	var oberhau_move: Dictionary = _WeaponConstants.get_move("oberhau")
	var oberhau_commit: float = float(oberhau_move.get("weapon_extension_commit_fraction", 0.78))
	var ai_commit: AttackInstance = _AttackInstance.new("oberhau", 1.0)
	ai_commit.archetype = {"kinematic_delivery": _WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_commit.delivery_commit_fraction = oberhau_commit
	var ke_commit: float = _WeaponDamage.compute_kinetic_energy_j(sword, ai_commit)
	var pre_cut_commit: float = _WeaponDamage.compute_pre_armor_cut(sword, ai_commit, 100.0, 1.0)
	var commit_ke_ratio: float = ke_commit / ke_hi if ke_hi > 0.01 else 0.0
	lines.append(
		"delivery_commit_formula=effective_intensity=intensity*commit_frac (floor %.2f); KE from v(eff_i); blunt slip uses full intensity"
		% [_WeaponDamage.DELIVERY_INTENSITY_FLOOR]
	)
	lines.append(
		"oberhau_i=1.0_commit=%.2f KE_J=%.0f pre_armor_cut=%.1f ke_ratio_vs_no_commit=%.3f"
		% [oberhau_commit, ke_commit, pre_cut_commit, commit_ke_ratio]
	)
	var arm_strict_commit: bool = _DesignAnchors.committed_strike_ke_in_strict_band(ke_commit)
	lines.append("audit_KE_at_i1.0_committed_J=%.0f strict_70-140J=%s" % [ke_commit, str(arm_strict_commit).to_lower()])
	var arm_strict: bool = _DesignAnchors.committed_strike_ke_in_strict_band(ke_hi)
	var arm_loose: bool = ke_hi >= 40.0 and ke_hi <= 250.0
	var vs_design: float = ke_hi / _DesignAnchors.DESIGN_KE_ARM_J if ke_hi >= 0.0 else 0.0
	lines.append(
		"audit_KE_at_i1.0_J=%.0f vs_design_arm=%.2fx (nominal %.0fJ)"
		% [ke_hi, vs_design, _DesignAnchors.DESIGN_KE_ARM_J]
	)
	lines.append("audit_KE_arm_strict_70-140J=%s (full commit may exceed nominal)" % str(arm_strict).to_lower())
	lines.append("audit_KE_arm_loose_40-250J=%s" % str(arm_loose).to_lower())
	if ke_hi < 0.0:
		failures.append("impact_ke: no intensity 1.0 sample")
	elif not arm_loose:
		failures.append("impact_ke: sword oberhau i=1.0 KE %.0fJ outside 40-250J loose band" % ke_hi)
	lines.append("spear_thrust_vs_mace=see harness impact_station_order (tip > head-weighted blunt)")


static func _append_derived_limb_capacity_section(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[derived_limb_capacity_pilot]")
	lines.append(
		"FEATURE_DERIVED_LIMB_CAPACITY production_default=%s (limbs only; head/chest hand-tuned)"
		% str(_HumanSpecies.feature_derived_limb_capacity).to_lower()
	)
	var ref_h: float = _HumanSpecies.resolved_reference_mass_kg()
	var ref_g: float = _GoblinSpecies.resolved_reference_mass_kg()
	for part in ["left_arm", "left_leg"]:
		var hand_t: int = _HumanSpecies.get("left_arm" if part == "left_arm" else "left_leg")
		var hand_b: int = _HumanSpecies.get("left_arm_bone" if part == "left_arm" else "left_leg_bone")
		var hand_t_h: int = hand_t
		var hand_b_h: int = hand_b
		var derived_t: int = _SpeciesResource.derived_limb_body_max_profiled(part, ref_h, hand_t_h)
		var derived_b: int = _SpeciesResource.derived_limb_bone_max_profiled(part, derived_t, hand_b_h)
		lines.append(
			"human_%s hand_tissue=%d hand_bone=%d derived_tissue=%d derived_bone=%d ref_kg=%.1f"
			% [part, hand_t, hand_b, derived_t, derived_b, ref_h]
		)
	var gob_arm_t: int = _SpeciesResource.derived_limb_body_max_profiled(
		"right_arm", ref_g, _GoblinSpecies.right_arm
	)
	var hum_arm_t: int = _SpeciesResource.derived_limb_body_max_profiled(
		"right_arm", ref_h, _HumanSpecies.right_arm
	)
	lines.append(
		"goblin_right_arm derived_tissue=%d human_right_arm derived_tissue=%d (mass %.1f vs %.1f kg)"
		% [gob_arm_t, hum_arm_t, ref_g, ref_h]
	)
	for part in ["right_arm", "left_leg"]:
		var hand_t_g: int = _GoblinSpecies.right_arm if part == "right_arm" else _GoblinSpecies.left_leg
		var hand_b_g: int = _GoblinSpecies.right_arm_bone if part == "right_arm" else _GoblinSpecies.left_leg_bone
		var derived_t_g: int = _SpeciesResource.derived_limb_body_max_profiled(part, ref_g, hand_t_g)
		var derived_b_g: int = _SpeciesResource.derived_limb_bone_max_profiled(part, derived_t_g, hand_b_g)
		lines.append(
			"goblin_%s hand_tissue=%d hand_bone=%d profiled_derived_tissue=%d profiled_derived_bone=%d"
			% [part, hand_t_g, hand_b_g, derived_t_g, derived_b_g]
		)
	lines.append(
		"profile_formula=mini(mass_derived,hand_export) tissue; bone mini(ratio_bone,hand_bone)"
	)
	lines.append(
		"pilot_note=human+goblin feature_derived_limb_capacity on; live caps = hand exports via profiled mini()"
	)


static func _parse_ctrl(line: String) -> float:
	var idx: int = line.find("ctrl=")
	if idx < 0:
		return -1.0
	var tail: String = line.substr(idx + 5).strip_edges()
	var space: int = tail.find(" ")
	if space >= 0:
		tail = tail.substr(0, space)
	return float(tail) if tail.is_valid_float() else -1.0


static func _packed_lines(text: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for raw in text.split("\n"):
		var s: String = str(raw).strip_edges()
		if not s.is_empty():
			out.append(s)
	return out
  