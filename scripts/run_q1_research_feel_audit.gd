extends SceneTree

## Track Q1 headless proxy: emit research_feel-shaped lines + boundary checks (no F5 editor).
## Writes **.q1_research_feel_audit.txt** at repo root.

const _Audit := preload("res://combat/CombatCalibrationAudit.gd")
const _F5 := preload("res://combat/CombatF5SoakTrace.gd")
const _Research := preload("res://core/CombatResearchAnchors.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _Log := preload("res://core/OperationalLog.gd")
const OUT_PATH := "res://.q1_research_feel_audit.txt"


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(false)
	CombatConstants.set_combat_dev_verbose_override(true)
	_Log.begin_play_session("res://main.tscn", "ii2b")
	_F5.prepare_fight_end_log()

	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== Q1 research_feel audit (headless proxies) ===")
	lines.append("")

	var graze: Dictionary = _Audit.f5_forearm_graze_metrics()
	var chest: Dictionary = _Audit.f5_armored_chest_metrics()
	var mace: Dictionary = _Audit.f5_mace_elbow_metrics()

	_log_scenario(lines, "forearm_graze", graze, "right_arm", "forearm")
	_log_scenario(lines, "armored_chest_bare", _bare_row_from_chest(chest), "chest", "thoracic")
	_log_scenario(lines, "armored_chest_plate", _armored_row_from_chest(chest), "chest", "thoracic")
	_log_scenario(lines, "mace_elbow", mace, "right_arm", "elbow")

	_append_global_benchmarks(lines)
	_check_boundaries(lines, graze, chest, mace)

	_F5.log_fight_end_summary("audit", false)
	_Log.end_play_session()

	var text: String = "\n".join(lines) + "\n"
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f:
		f.store_string(text)
		print(text)
		quit(0 if not text.contains("BOUNDARY_FAIL") else 1)
	else:
		print("FP_HARNESS_FAIL: Q1Audit could not write %s" % OUT_PATH)
		quit(1)


static func _bare_row_from_chest(m: Dictionary) -> Dictionary:
	return {
		"final_cut": float(m.get("bare_damage_sum", 0.0)),
		"final_blunt": 0.0,
		"final_bone": 0.0,
		"penetration_to_tissue_mm": float(m.get("bare_tissue_pen_mm", 0.0)),
		"transmitted_ke_fraction": 1.0,
	}


static func _armored_row_from_chest(m: Dictionary) -> Dictionary:
	return {
		"final_cut": float(m.get("armored_damage_sum", 0.0)),
		"final_blunt": 0.0,
		"final_bone": 0.0,
		"penetration_to_tissue_mm": float(m.get("armored_tissue_pen_mm", 0.0)),
		"transmitted_ke_fraction": float(m.get("transmitted_ke_fraction", 1.0)),
	}


static func _log_scenario(
	lines: PackedStringArray, label: String, res: Dictionary, part: String, sub: String
) -> void:
	lines.append("[%s]" % label)
	lines.append(
		"  research_feel part=%s sub=%s cut=%.1f blunt=%.1f bone=%.1f pen_mm=%.2f ke_frac=%.2f"
		% [
			part,
			sub,
			float(res.get("final_cut", 0.0)),
			float(res.get("final_blunt", 0.0)),
			float(res.get("final_bone", 0.0)),
			float(res.get("penetration_to_tissue_mm", -1.0)),
			float(res.get("transmitted_ke_fraction", 1.0)),
		]
	)


static func _append_global_benchmarks(lines: PackedStringArray) -> void:
	lines.append("")
	lines.append("[global_research_benchmarks]")
	var ttd: float = _Research.clinical_ttd_seconds(1.0)
	var ttd_ok: bool = ttd >= _Research.LITERATURE_TTD_UNTREATED_S_MIN and ttd <= _Research.LITERATURE_TTD_UNTREATED_S_MAX
	lines.append(
		"  TTD_uncontrolled_s=%.1f band=%.0f-%.0f verdict=%s"
		% [
			ttd,
			_Research.LITERATURE_TTD_UNTREATED_S_MIN,
			_Research.LITERATURE_TTD_UNTREATED_S_MAX,
			"pass" if ttd_ok else "FAIL",
		]
	)
	var ke: float = _Research.committed_oberhau_ke_j()
	var ke_ok: bool = (
		ke >= _Research.LITERATURE_HEMA_COMMITTED_KE_J_MIN
		and ke <= _Research.LITERATURE_HEMA_COMMITTED_KE_J_MAX
	)
	lines.append(
		"  committed_oberhau_ke_J=%.0f band=%.0f-%.0f verdict=%s"
		% [
			ke,
			_Research.LITERATURE_HEMA_COMMITTED_KE_J_MIN,
			_Research.LITERATURE_HEMA_COMMITTED_KE_J_MAX,
			"pass" if ke_ok else "FAIL",
		]
	)
	var ml_max: float = _BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT
	var per_kg: float = _Research.blood_ml_per_kg_at_reference_mass(_DesignAnchors.REFERENCE_ADULT_MASS_KG)
	var ml_ok: bool = absf(per_kg - _Research.LITERATURE_BLOOD_ML_PER_KG_NOMINAL) <= _Research.LITERATURE_BLOOD_ML_PER_KG_TOLERANCE
	lines.append(
		"  blood_ml_max=%.0f ml_per_kg=%.1f want~%.0f verdict=%s"
		% [ml_max, per_kg, _Research.LITERATURE_BLOOD_ML_PER_KG_NOMINAL, "pass" if ml_ok else "FAIL"]
	)


static func _check_boundaries(
	lines: PackedStringArray, graze: Dictionary, chest: Dictionary, mace: Dictionary
) -> void:
	lines.append("")
	lines.append("[boundary_checks]")
	_check(
		lines,
		"graze_no_bone",
		float(graze.get("final_bone", 0.0)) < 0.01,
		"bone=%.2f" % float(graze.get("final_bone", 0.0)),
	)
	_check(
		lines,
		"graze_shallow_pen",
		float(graze.get("penetration_to_tissue_mm", 99.0)) <= 1.5,
		"pen_mm=%.2f" % float(graze.get("penetration_to_tissue_mm", 0.0)),
	)
	_check(
		lines,
		"graze_has_cut",
		float(graze.get("final_cut", 0.0)) > 0.0,
		"cut=%.2f" % float(graze.get("final_cut", 0.0)),
	)
	_check(
		lines,
		"cuirass_lowers_pen",
		float(chest.get("armored_tissue_pen_mm", 0.0)) < float(chest.get("bare_tissue_pen_mm", 0.0)) - 0.01,
		"bare=%.2f armored=%.2f"
		% [float(chest.get("bare_tissue_pen_mm", 0.0)), float(chest.get("armored_tissue_pen_mm", 0.0))],
	)
	_check(
		lines,
		"cuirass_ke_frac",
		float(chest.get("transmitted_ke_fraction", 0.0)) > 0.5
		and float(chest.get("transmitted_ke_fraction", 0.0)) < 1.0,
		"ke_frac=%.3f" % float(chest.get("transmitted_ke_fraction", 1.0)),
	)
	_check(
		lines,
		"cuirass_lowers_damage",
		float(chest.get("armored_damage_sum", 0.0)) < float(chest.get("bare_damage_sum", 0.0)) - 0.5,
		"bare_dmg=%.1f armored_dmg=%.1f"
		% [float(chest.get("bare_damage_sum", 0.0)), float(chest.get("armored_damage_sum", 0.0))],
	)
	_check(
		lines,
		"mace_bone_chip",
		float(mace.get("final_bone", 0.0)) >= 0.5,
		"bone=%.2f KE=%.0f anchor=%.0f"
		% [float(mace.get("final_bone", 0.0)), float(mace.get("strike_ke_j", 0.0)), float(mace.get("j_anchor", 0.0))],
	)
	lines.append("")
	lines.append(
		"note=matches .calibration_audit.txt [f5_scenario_headless]; F5 editor adds live duel parry/bind lines"
	)


static func _check(
	lines: PackedStringArray, id: String, ok: bool, detail: String
) -> void:
	var tag: String = "pass" if ok else "BOUNDARY_FAIL"
	lines.append("  %s %s (%s)" % [id, tag, detail])
