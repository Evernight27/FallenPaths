class_name TuningLogFormatter
extends RefCounted

## HEMA-oriented strike / cycle logging for the combat tuning scene.
## Anchors: `CombatDesignAnchors.COMMITTED_STRIKE_KE_J_*`, `CombatResearchAnchors`, ATLS via `BleedingConstants`.

const _ConfigData := preload("res://tools/combat_tuning/TuningConfigData.gd")
const _CombatLogFormatter := preload("res://ui/battle/CombatLogFormatter.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _WeaponDamageHelper := preload("res://resources/weapons/WeaponDamageHelper.gd")
const _WeaponConstants := preload("res://resources/weapons/WeaponConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")

## Note stamped by **`AttackResultApplier._tuning_follow_through_extras`** on a strike that lands as the
## follow-through of a parried blow (real hit, but low KE is the parried-blow residual, not a committed strike).
const FOLLOW_THROUGH_NOTE: String = "follow_through_from_parry"

static var _bbcode_strip_re: RegEx


static func strip_bbcode(text: String) -> String:
	if text.is_empty():
		return ""
	if _bbcode_strip_re == null:
		_bbcode_strip_re = RegEx.new()
		_bbcode_strip_re.compile("\\[/?[^\\]]+\\]")
	return _bbcode_strip_re.sub(text, "", true)


static func format_calibration_preamble() -> String:
	return (
		(
            "[Tuning] anchors ke_commit=%.0f-%.0fJ ref_oberhau_ke=%.0fJ "
			+ "adult_mass=%.0fkg blood_ref=%.0fml mode=1v1_skip_medical "
			+ "grep_tags=[Tuning],[Matchup],[HEMA],[Fight end],--- Cycle"
		)
		% [
			_DesignAnchors.COMMITTED_STRIKE_KE_J_MIN,
			_DesignAnchors.COMMITTED_STRIKE_KE_J_MAX,
			_DesignAnchors.REFERENCE_COMMITTED_OBERHAU_KE_J,
			_DesignAnchors.REFERENCE_ADULT_MASS_KG,
			_DesignAnchors.REFERENCE_BLOOD_VOLUME_ML_ADULT,
		]
	)


static func format_entity_tissue_oneline(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return "tissue=(no entity)"
	entity.ensure_consciousness_current()
	var tissue_bits := PackedStringArray()
	var bone_bits := PackedStringArray()
	for part in _ConfigData.BODY_PARTS:
		var cut: float = float(entity.body_cutting.get(part, 0.0))
		var blunt: float = float(entity.body_blunt.get(part, 0.0))
		var max_hp: float = float(entity.body_max.get(part, 1.0))
		var bone: float = float(entity.bone_health.get(part, 0.0))
		var bone_max_val: float = float(entity.bone_max.get(part, 1.0))
		# body_cutting/body_blunt are REMAINING pools (each init to body_max, damage subtracts).
		# Total pool is 2x max (cut + blunt); remaining fraction must be clamped to 100%.
		var hp_ratio: float = (cut + blunt) / (max_hp * 2.0) if max_hp > 0.0 else 0.0
		hp_ratio = clampf(hp_ratio, 0.0, 1.0)
		var bone_ratio: float = bone / bone_max_val if bone_max_val > 0.0 else 0.0
		tissue_bits.append("%s=%.0f%%" % [part, hp_ratio * 100.0])
		bone_bits.append("%s=%.0f%%" % [part, bone_ratio * 100.0])
	return (
        "tissue {%s} | bone {%s} | %s"
		% [
			", ".join(tissue_bits),
			", ".join(bone_bits),
			format_vitals_suffix(entity),
		]
	)


static func _resolved_payload(result: Dictionary) -> Dictionary:
	var nested: Variant = result.get("result_dict", null)
	if nested is Dictionary and not (nested as Dictionary).is_empty():
		return nested as Dictionary
	return result


static func exchange_outcome(result: Dictionary) -> String:
	return _resolved_outcome(result)


static func ke_sample_from_result(result: Dictionary) -> Dictionary:
	var sample: Dictionary = _ke_sample_meta(result)
	var rd: Dictionary = _resolved_payload(result)
	if result.has("parry_control"):
		sample["parry_control"] = float(result["parry_control"])
	elif rd.has("parry_control"):
		sample["parry_control"] = float(rd["parry_control"])
	return sample


static func _ke_sample_meta(result: Dictionary) -> Dictionary:
	var rd: Dictionary = _resolved_payload(result)
	var sample: Dictionary = {
		"ke_j": _strike_ke_j(rd),
		"move_id": _move_id_from_result(result),
		"weapon_id": str(result.get("weapon_id", rd.get("weapon_id", ""))),
		"kinematic_delivery": str(result.get("kinematic_delivery", rd.get("kinematic_delivery", ""))),
		# Intended aim vs actual landed part — lets the cycle summary report aim-drift
		# (fraction of intentional hits that land on a different part than aimed).
		"aim_part": str(result.get("target_part", rd.get("target_part", ""))).strip_edges(),
		"hit_part": str(rd.get("part", "")).strip_edges(),
		# True when the aimed part was inside the intercept segment at resolve time.
		# False/absent means the guard/first-contact parts interposed before it — a physical
		# block rather than a targeting error. Stamped by AttackResolver when target_part set.
		"aim_reachable": bool(result.get("aim_reachable", rd.get("aim_reachable", false))),
		# Alignment (0..1) at resolve time; lets format_aim_drift bucket aim-error by
		# aligned/glancing/off using the same thresholds the defense resolver uses.
		"hit_alignment": float(result.get("hit_alignment", rd.get("hit_alignment", -1.0))),
	}
	var sample_move_id: String = str(sample.get("move_id", ""))
	if not sample_move_id.is_empty():
		var move_def: Dictionary = WeaponConstants.get_move(sample_move_id)
		sample["archetype_id"] = str(move_def.get("archetype_id", ""))
	var delivery: String = str(sample.get("kinematic_delivery", ""))
	if delivery.is_empty():
		var move_id: String = str(sample.get("move_id", ""))
		var weapon_id: String = str(sample.get("weapon_id", ""))
		if not move_id.is_empty() and not weapon_id.is_empty():
			var arch_for_infer: Dictionary = _build_archetype_for_inference(weapon_id, move_id)
			sample["kinematic_delivery"] = _WeaponDamageHelper.kinematic_delivery(arch_for_infer, move_id)
		elif not move_id.is_empty():
			sample["kinematic_delivery"] = _WeaponDamageHelper.kinematic_delivery({}, move_id)
	# A parry follow-through is a real landed hit, but its low KE is the residual of a parried blow —
	# not a committed strike. Tag it so the committed-swing/thrust/light band buckets can exclude it
	# (otherwise a 1J follow-through forces in_band=0% and hides the true committed-strike distribution).
	var note: String = str(result.get("note", rd.get("note", ""))).strip_edges()
	var parent_idx: int = int(result.get("parent_exchange_index", rd.get("parent_exchange_index", -1)))
	sample["is_follow_through"] = note == FOLLOW_THROUGH_NOTE or parent_idx >= 0
	return sample


static func _resolved_outcome(result: Dictionary) -> String:
	var payload: Dictionary = _resolved_payload(result)
	var outcome: String = str(payload.get("outcome", "")).strip_edges()
	if not outcome.is_empty():
		return outcome
	if result.has("action"):
		return str(result.get("action", "?"))
	return "?"


static func _move_id_from_result(result: Dictionary) -> String:
	var mid: String = str(result.get("move_id", "")).strip_edges()
	if not mid.is_empty():
		return mid
	return str(_resolved_payload(result).get("move_id", "")).strip_edges()


static func _strike_ke_j(rd: Dictionary) -> float:
	var ke: float = float(rd.get("strike_ke_j_applied", rd.get("ke", 0.0)))
	return ke


static func ke_band_tag_for_weapon(ke_j: float, weapon_id: String, kinematic_delivery: String = "") -> String:
	if ke_j <= 0.0:
		return ""
	var band: Vector2 = _DesignAnchors.ke_band_min_max_for_weapon(weapon_id, kinematic_delivery)
	if ke_j < band.x:
		return "low"
	if ke_j > band.y:
		return "high"
	return "in_band"


static func hema_ke_band_tag(ke_j: float) -> String:
	return ke_band_tag_for_weapon(ke_j, "SWORD")


static func ke_band_tag_for_sample(sample: Variant) -> String:
	if sample is not Dictionary:
		return hema_ke_band_tag(float(sample))
	var d: Dictionary = sample as Dictionary
	return ke_band_tag_for_weapon(
		float(d.get("ke_j", 0.0)), str(d.get("weapon_id", "SWORD")), str(d.get("kinematic_delivery", ""))
	)


static func format_ke_tag_for_sample(sample: Variant) -> String:
	var ke_j: float = _ke_sample_ke_j(sample) if sample is Dictionary else float(sample)
	if ke_j <= 0.0:
		return ""
	var weapon_id: String = _ke_sample_weapon_id(sample) if sample is Dictionary else "SWORD"
	var delivery: String = ""
	if sample is Dictionary:
		delivery = str((sample as Dictionary).get("kinematic_delivery", ""))
	var band: Vector2 = _DesignAnchors.ke_band_min_max_for_weapon(weapon_id, delivery)
	var band_label: String = ke_band_tag_for_weapon(ke_j, weapon_id, delivery)
	band_label = "in_band" if band_label == "in_band" else band_label.to_upper()
	# Dual-band: weapon-specific reference + combat-realistic reference band.
	var combat_min: float = _DesignAnchors.COMBAT_REALISTIC_KE_J_MIN
	var combat_max: float = _DesignAnchors.COMBAT_REALISTIC_KE_J_MAX
	return "KE=%.0fJ [%s, weapon %.0f-%.0fJ, combat %.0f-%.0fJ]" % [ke_j, band_label, band.x, band.y, combat_min, combat_max]


## Space-separated, CSV-safe attribution of a strike's KE multipliers so weak
## strikes from injured/exhausted combatants are explainable at a glance.
static func format_attack_perf(rd: Dictionary) -> String:
	var perf: Variant = rd.get("attack_perf", {})
	if perf is not Dictionary or (perf as Dictionary).is_empty():
		return ""
	var d: Dictionary = perf as Dictionary
	var items := PackedStringArray()
	if d.has("str"):
		items.append("str=%.0f" % float(d["str"]))
	for key in ["arm", "fat", "pow", "wuf", "close"]:
		if d.has(key):
			items.append("%s=%.2f" % [key, float(d[key])])
	if d.has("intensity"):
		items.append("i=%.2f" % float(d["intensity"]))
	return "perf=[%s]" % " ".join(items)


## Compact list of which KE multipliers dragged the strike below band.
static func _format_ke_low_cause(rd: Dictionary) -> String:
	var perf: Variant = rd.get("attack_perf", {})
	if perf is not Dictionary:
		return ""
	var d: Dictionary = perf as Dictionary
	# A parry follow-through lands with a velocity override (the parried blow's residual), so its low KE is
	# the parry's, not a performance factor's. Attribute it to the follow-through rather than listing
	# fat/pow/wuf (which sit near 1.0 here and would mislead the reader).
	var parent_idx: int = int(rd.get("parent_exchange_index", -1))
	if parent_idx >= 0:
		return "follow_through"
	var culprits := PackedStringArray()
	# KE is set by the velocity chain (fatigue, power, wind-up, closing speed). `arm` is a DAMAGE factor
	# (pre_cut/pre_blunt only) and never touches the KE velocity — listing it here misattributes the low
	# energy, so it is excluded from the KE-low cause (it still shows in the perf= breakdown).
	for key in ["fat", "pow", "wuf"]:
		if d.has(key):
			var val: float = float(d[key])
			if val > 0.0 and val < 0.98:
				culprits.append("%s:%.2f" % [key, val])
	if d.has("close"):
		var close: float = float(d["close"])
		if close < 0.98:
			culprits.append("close:%.2f" % close)
	return " ".join(culprits)


static func atls_class_label(remaining_blood_pct: float) -> String:
	var cls: int = _Bleeding.atls_hemorrhage_class_from_remaining_pct(remaining_blood_pct)
	return "ATLS-%s" % ["0", "I", "II", "III", "IV"][clampi(cls, 0, 4)]


static func format_vitals_suffix(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return ""
	entity.ensure_consciousness_current()
	var blood: float = float(entity.blood_volume)
	var atls: String = atls_class_label(blood)
	return "blood=%.0f%% %s consc=%.0f" % [blood, atls, float(entity.consciousness)]


## Tags each side's vitals string with [WIN]/[LOSS] so the collapsed fighter and the winner are
## unambiguous even though vitals are always ordered Attacker-first. Returns e.g.
## `[LOSS] Attacker blood=37% ATLS-IV consc=5 | [WIN] Defender blood=69% ATLS-III consc=95`.
## Empty tags (plain join) for mutual/draw where no single side won.
static func tagged_vitals_pair(atk_vitals: String, def_vitals: String, winner_name: String) -> String:
	var atk_tag: String = ""
	var def_tag: String = ""
	if winner_name != "mutual" and winner_name != "draw":
		if atk_vitals.begins_with(winner_name + " "):
			atk_tag = "[WIN] "
			def_tag = "[LOSS] "
		else:
			atk_tag = "[LOSS] "
			def_tag = "[WIN] "
	var bit := PackedStringArray()
	if not atk_vitals.is_empty():
		bit.append(atk_tag + atk_vitals)
	if not def_vitals.is_empty():
		bit.append(def_tag + def_vitals)
	if bit.is_empty():
		return ""
	return " | ".join(bit)


## Blood-loss + structural invariant audit. Blood volume only decreases via active wound
## bleeding (so lost>3% with wounds=0 is a bleed-accounting bug), and tissue % should track with
## wound count/severity. Returns a compact per-side line, e.g.
## `recon atk blood 100→37% lost=63 wounds=4 bleed=1.5%/s tissue=82% | def ...`
## Flags: `? unaccounted blood loss` (lost>3% + no wounds + no bleed);
## `? death-state inconsistent` (is_dead() but blood>threshold and tissue>30%).
static func format_realism_recon(atk_entity: Node, def_entity: Node) -> String:
	var atk_bit: String = _recon_side_bit(atk_entity)
	var def_bit: String = _recon_side_bit(def_entity)
	if atk_bit.is_empty() and def_bit.is_empty():
		return ""
	return "recon " + atk_bit + " | " + def_bit


## Extracts the flagged invariant warnings from a recon string (everything after the first `?`).
## Used by _run_batch to accumulate anomaly counts without re-computing entity state.
static func _format_recon_flags(recon: String) -> String:
	var q_pos: int = recon.find("?")
	if q_pos < 0:
		return ""
	return recon.substr(q_pos).strip_edges()


static func _recon_side_bit(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return ""
	entity.ensure_consciousness_current()
	var blood: float = float(entity.blood_volume)
	var lost: float = _Bleeding.MAX_BLOOD_VOLUME - blood
	var rate: float = 0.0
	var wound_count: int = 0
	if ("wounds" in entity) and (entity.wounds is Dictionary):
		# Display the ACTUAL blood-volume drain, not the raw (uncapped) wound sum: process_blood_loss
		# clamps the drain to MAX_TOTAL_BLOOD_LOSS_RATE in both the % and mL paths, so the uncapped
		# total (e.g. 15.4%/s) misrepresents the ~3.5%/s the sim really applies and understates TTD.
		rate = minf(
			EntityWounds.get_total_bleeding_rate(entity) * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER,
			_Bleeding.MAX_TOTAL_BLOOD_LOSS_RATE
		)
		var wounds: Dictionary = entity.wounds as Dictionary
		for p in wounds.keys():
			var arr: Array = wounds[p]
			if arr is Array:
				wound_count += arr.size()
	var tissue_pct: float = 100.0
	if "body_cutting" in entity and "body_max" in entity:
		var total_tissue: float = 0.0
		var max_tissue: float = 0.0
		var body_max: Dictionary = entity.body_max as Dictionary
		for p in body_max.keys():
			total_tissue += float(entity.body_cutting.get(p, 0.0)) + float(entity.body_blunt.get(p, 0.0))
			max_tissue += float(body_max[p]) * 2.0
		if max_tissue > 0.0:
			tissue_pct = total_tissue / max_tissue * 100.0
	var flags: PackedStringArray = []
	if lost > 3.0 and wound_count == 0 and rate < 0.05:
		flags.append("? unaccounted blood loss")
	if "is_dead" in entity and entity.is_dead():
		var blood_above_thresh: bool = blood > _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
		var tissue_above_crit: bool = true
		if "is_vital_part_critically_damaged" in entity:
			tissue_above_crit = not entity.is_vital_part_critically_damaged()
		if blood_above_thresh and tissue_above_crit:
			flags.append("? death-state inconsistent")
	var flag_str: String = ""
	if not flags.is_empty():
		flag_str = " " + " ".join(flags)
	var ttd_above: float = blood - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	var ttd_str: String = "ttd=inf"
	if rate > 0.0 and ttd_above > 0.0:
		ttd_str = "ttd=~%ds" % int(round(ttd_above / rate))
	elif ttd_above <= 0.0:
		ttd_str = "ttd=0"
	return (
		"blood %d%%→%d%% lost=%d wounds=%d bleed=%.1f%%/s tissue=%d%% %s%s"
		% [
			int(round(_Bleeding.MAX_BLOOD_VOLUME)),
			int(round(blood)),
			int(round(lost)),
			wound_count,
			rate,
			int(round(tissue_pct)),
			ttd_str,
			flag_str,
		]
	)


## Compact bleed-cause tag for a contact line so "why is this fighter's blood dropping" is answerable
## without cross-referencing the fight-end wound table. Returns e.g. `bleed=12.3%/s (forearm arterial, severe)` —
## the target part's total bleed rate, its worst sub-region when that wound is arterial, and the highest
## injury severity present (so a single hit's catastrophic blood loss is judgeable at a glance). Empty when
## the entity has no active bleeding (so clean hits add no noise).
static func format_bleed_cause(entity: Node, part: String) -> String:
	if entity == null or not is_instance_valid(entity):
		return ""
	if not ("wounds" in entity) or not (entity.wounds is Dictionary):
		return ""
	var wounds: Dictionary = entity.wounds as Dictionary
	var rate: float = EntityWounds.get_bleeding_rate_for_part(entity, part) if part != "" else EntityWounds.get_total_bleeding_rate(entity)
	if rate <= 0.001:
		return ""
	# `rate` is the raw abstract wound rate (HP/s game units). The REAL blood-volume loss rate is
	# rate × BLOOD_LOSS_RATE_MULTIPLIER (see BleedingConstants.blood_volume_loss_per_second /
	# BloodVolumeMl.blood_ml_loss_per_second). Display the real %/s so a 144.8 raw rate reads as the
	# ~10.4%/s blood-volume loss it actually is (not an impossible 144.8%/s).
	var blood_pct_per_s: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	var worst_sub: String = ""
	var worst_arterial_rate: float = -1.0
	var worst_sev_rank: int = -1
	var scope_parts: Array = [part] if not part.is_empty() else wounds.keys()
	for p in scope_parts:
		if not wounds.has(p):
			continue
		for injury in wounds[p]:
			if not (injury is Dictionary):
				continue
			var r: float = float(injury.get("current_bleeding_rate", 0.0))
			var arterial: bool = bool(injury.get("is_arterial", false))
			var sub: String = str(injury.get("sub_region", ""))
			# Surface the highest-rate arterial wound's sub-region (the realistic "which vessel" signal).
			if arterial and not sub.is_empty() and r > worst_arterial_rate:
				worst_arterial_rate = r
				worst_sub = sub
			var sev_rank: int = _severity_rank(str(injury.get("severity", "")))
			if sev_rank > worst_sev_rank:
				worst_sev_rank = sev_rank
	var tag := PackedStringArray()
	tag.append("bleed=%.1f%%/s" % blood_pct_per_s)
	# Detail is optional: a wound can bleed without an arterial sub-region or a recognized severity
	# string (e.g. compound-fracture / stabilized), so only emit parens when there is something to say.
	var detail := PackedStringArray()
	if not worst_sub.is_empty():
		detail.append("%s arterial" % worst_sub)
	if worst_sev_rank >= 0:
		# Index 0 ("minor") is intentionally blank in the label table; only append when it adds text.
		var sev_label: String = ["", "minor", "moderate", "severe", "critical"][clampi(worst_sev_rank, 0, 4)]
		if not sev_label.is_empty():
			detail.append(sev_label)
	if not detail.is_empty():
		tag.append("(%s)" % ", ".join(detail))
	return " ".join(tag)


## Maps a BleedingConstants severity string to a comparable rank (higher = worse). -1 when unrecognized.
static func _severity_rank(severity: String) -> int:
	match severity:
		"minor":
			return 0
		"moderate":
			return 1
		"severe":
			return 2
		"critical":
			return 3
	return -1


## Arm-modifier breakdown for a KE-dragging strike (`ke_low_by=arm`), so an agent can tell "injured at spawn"
## from "mid-fight pain/grip loss". Returns e.g. `arm=0.35 (pain 0.42 grip 0.83)` or "" when the arm factor
## is healthy or the entity is unavailable.
static func format_arm_breakdown(entity: Node, arm_value: float) -> String:
	if entity == null or not is_instance_valid(entity):
		return ""
	if arm_value <= 0.0 or arm_value >= 0.98:
		return ""
	var factors: Dictionary = EntityEquipment.attack_damage_modifier_factors(entity)
	var bits := PackedStringArray()
	for key in ["base", "func", "pain", "grip"]:
		if factors.has(key):
			bits.append("%s %.2f" % [key, float(factors[key])])
	if bits.is_empty():
		return ""
	return "arm=%.2f (%s)" % [float(factors.get("total", arm_value)), " ".join(bits)]


## One grep-friendly line per exchange (replaces production combat log in tuning).
static func format_exchange_line(
	atk_name: String,
	tgt_name: String,
	result: Dictionary,
	atk_entity: Node = null,
	tgt_entity: Node = null,
	exchange_index: int = -1,
	gauge_atk: float = -1.0,
	gauge_def: float = -1.0
) -> String:
	var rd: Dictionary = _resolved_payload(result)
	var outcome: String = _resolved_outcome(result)
	var move_id: String = _move_id_from_result(result)
	if move_id.is_empty():
		move_id = "?"
	var part: String = str(rd.get("part", "")).strip_edges()
	var aim_part: String = str(result.get("target_part", rd.get("target_part", ""))).strip_edges()
	var part_bit: String = (" %s" % part) if not part.is_empty() else ""
	var idx_bit: String = ("#%d " % exchange_index) if exchange_index > 0 else ""

	match outcome:
		"fled", "yielded":
			var short := "[HEMA] %s%s %s | outcome=%s" % [idx_bit, atk_name, move_id, outcome]
			if atk_entity != null:
				short += " | actor[%s]" % format_vitals_suffix(atk_entity)
			return short
		"bled_out":
			# Bleed-out is a non-strike event on the victim itself (target id is -1), so the
			# vitals shown must be the victim's (atk_entity), not a stale/healthy "target".
			var short := "[HEMA] %s%s %s | outcome=%s" % [idx_bit, atk_name, move_id, outcome]
			if atk_entity != null:
				short += " | actor[%s]" % format_vitals_suffix(atk_entity)
			return short
		"parry_deflection_shock":
			# Recoil blunt the parrier takes from a hard deflection — a self-event (emitted with
			# attacker_id = the parrier, target_id = -1), so there is no real "target". Show the
			# parrier's name + part + their vitals instead of the confusing "?->id:-1".
			var short := "[HEMA] %s%s %s%s | outcome=%s" % [idx_bit, atk_name, move_id if move_id != "?" else "parry_shock", part_bit, outcome]
			if atk_entity != null:
				short += " | actor[%s]" % format_vitals_suffix(atk_entity)
			return short
		"focus_line":
			var short := "[HEMA] %s%s %s->%s | outcome=%s" % [idx_bit, atk_name, move_id if move_id != "?" else "focus_line", tgt_name, outcome]
			if tgt_entity != null:
				short += " | actor[%s]" % format_vitals_suffix(tgt_entity)
			return short
		"skip":
			return ""
		_:
			pass

	var bits := PackedStringArray()
	bits.append("[HEMA] %s%s %s->%s%s" % [idx_bit, atk_name, move_id, tgt_name, part_bit])
	bits.append("outcome=%s" % outcome)
	if not aim_part.is_empty() and aim_part != part:
		bits.append("aim=%s" % aim_part)
	var aim_prof: float = float(result.get("aim_prof_tier", rd.get("aim_prof_tier", -1.0)))
	if aim_prof >= 0.0:
		bits.append("aim_prof=%.2f" % aim_prof)
	var occ_mult: float = float(result.get("occ_mult", rd.get("occ_mult", -1.0)))
	if occ_mult > 0.0 and absf(occ_mult - 1.0) > 0.01:
		bits.append("occ_mult=%.2f" % occ_mult)

	var i: float = float(result.get("intensity", rd.get("intensity", -1.0)))
	var power: float = float(result.get("power", rd.get("power", -1.0)))
	var ft: float = float(result.get("follow_through", rd.get("follow_through", -1.0)))
	if i >= 0.0:
		bits.append("i=%.2f" % i)
	if power >= 0.0:
		bits.append("p=%.2f" % power)
	if ft >= 0.0:
		bits.append("ft=%.2f" % ft)
	var wind_up: float = float(result.get("wind_up_s", rd.get("wind_up_s", -1.0)))
	if wind_up > 0.0:
		bits.append("wind_up=%.2fs" % wind_up)

	var atk_line: String = str(result.get("attack_line", rd.get("attack_line", ""))).strip_edges()
	var atk_guard: String = str(result.get("atk_guard", "")).strip_edges()
	var def_guard: String = str(result.get("def_guard", "")).strip_edges()
	(
		bits
		. append(
			(
				"line=%s atk_grd=%s def_grd=%s"
				% [
					atk_line if not atk_line.is_empty() else "-",
					atk_guard if not atk_guard.is_empty() else "-",
					def_guard if not def_guard.is_empty() else "-",
				]
			)
		)
	)

	if gauge_atk >= 0.0 or gauge_def >= 0.0:
		bits.append("gauge_atk=%.3f gauge_def=%.3f" % [maxf(gauge_atk, 0.0), maxf(gauge_def, 0.0)])
	# Pre-gauge is only informative when it differs from the post value (a gauge spent during the exchange).
	# Skip the otherwise-identical repeat to keep grep density high.
	var gauge_atk_pre: float = float(result.get("gauge_atk_pre", rd.get("gauge_atk_pre", -1.0)))
	var gauge_def_pre: float = float(result.get("gauge_def_pre", rd.get("gauge_def_pre", -1.0)))
	var pre_changed: bool = (gauge_atk_pre >= 0.0 and absf(gauge_atk_pre - maxf(gauge_atk, 0.0)) > 0.05) or (gauge_def_pre >= 0.0 and absf(gauge_def_pre - maxf(gauge_def, 0.0)) > 0.05)
	if pre_changed:
		bits.append("gauge_pre_atk=%.3f gauge_pre_def=%.3f" % [maxf(gauge_atk_pre, 0.0), maxf(gauge_def_pre, 0.0)])
	var parent_idx: int = int(
		result.get("parent_exchange_index", _resolved_payload(result).get("parent_exchange_index", -1))
	)
	if parent_idx > 0:
		bits.append("ft_parent=#%d" % parent_idx)

	var ke_j: float = _strike_ke_j(rd)
	if ke_j > 0.0:
		bits.append(format_ke_tag_for_sample(_ke_sample_meta(result)))
		var perf_bit: String = format_attack_perf(rd)
		if not perf_bit.is_empty():
			bits.append(perf_bit)
		if ke_band_tag_for_sample(_ke_sample_meta(result)) == "low":
			var low_cause: String = _format_ke_low_cause(rd)
			if not low_cause.is_empty():
				bits.append("ke_low_by=%s" % low_cause)
			# Surface the arm's damage-modifier breakdown (pain/grip/function) when the attacking arm is
			# degraded, so an agent can distinguish spawn-injury from mid-fight degradation. Note the arm
			# factor scales DAMAGE (pre_cut/pre_blunt), not KE — it is context here, not a `ke_low_by` cause.
			var perf: Variant = rd.get("attack_perf", {})
			if perf is Dictionary and (perf as Dictionary).has("arm"):
				var arm_val: float = float((perf as Dictionary)["arm"])
				var arm_bit: String = format_arm_breakdown(atk_entity, arm_val)
				if not arm_bit.is_empty():
					bits.append(arm_bit)
	else:
		bits.append("KE=n/a")

	var pen_sharp: float = float(rd.get("penetration_sharp_applied", rd.get("penetration", 0.0)))
	bits.append("pen=%.2fmm" % pen_sharp)

	if outcome in ["hit", "glancing", "negligible", "deflected"]:
		var dmg: int = int(rd.get("dmg", 0))
		var phys: float = float(rd.get("total_physical", float(dmg)))
		var cut: float = float(rd.get("final_cut", 0.0))
		var blunt: float = float(rd.get("final_blunt", 0.0))
		var bone: float = float(rd.get("final_bone", 0.0))
		bits.append("dmg=%d phys=%.3f cut=%.2f blunt=%.2f bone=%.2f" % [dmg, phys, cut, blunt, bone])
		# Zero-energy follow-through contact (KE=n/a + PHYSICAL_DAMAGE_MIN_FLOOR dmg): tag it so a
		# bare "hit" that dealt only the 1.0 floor is distinguishable from a real-energy hit in the
		# log (otherwise these read as full hits and inflate the per-cycle hit-rate).
		if ke_j <= 0.0 and dmg <= 1:
			bits.append("contact_floor")
		var pre_armor: float = float(rd.get("pre_armor", -1.0))
		var mech: float = float(rd.get("mechanical_post_armor", -1.0))
		var mech_bit: String = "pre_armor=%.1f mech=%.1f" % [maxf(pre_armor, 0.0), maxf(mech, 0.0)]
		if mech > pre_armor + 0.5:
			var amplif := PackedStringArray()
			if rd.has("mech_trauma_mult") and absf(float(rd["mech_trauma_mult"]) - 1.0) > 0.01:
				amplif.append("trauma x%.2f" % float(rd["mech_trauma_mult"]))
			if rd.has("mech_subregion_mult") and absf(float(rd["mech_subregion_mult"]) - 1.0) > 0.01:
				amplif.append("subregion x%.2f" % float(rd["mech_subregion_mult"]))
			if not amplif.is_empty():
				mech_bit += " (mech>pre: %s)" % " ".join(amplif)
		bits.append(mech_bit)
		var hb: float = float(rd.get("health_before", 0.0))
		var ha: float = float(rd.get("health_after", 0.0))
		if hb > 0.0 or ha > 0.0:
			bits.append("part_hp=%.0f->%.0f delta=%.0f" % [hb, ha, ha - hb])
		var bleed_bit: String = format_bleed_cause(tgt_entity, part)
		if not bleed_bit.is_empty():
			bits.append(bleed_bit)

	if outcome in ["parry_deflect", "parry_partial"]:
		var bind: bool = bool(result.get("parry_bind", false))
		var ctrl: float = float(result.get("parry_control", -1.0))
		var rem: float = float(result.get("follow_through_rem", -1.0))
		var parry_bits := PackedStringArray()
		if bind:
			parry_bits.append("bind")
		elif outcome == "parry_deflect":
			parry_bits.append("deflect")
		else:
			parry_bits.append("partial")
		if ctrl >= 0.0:
			parry_bits.append("ctrl=%.2f" % ctrl)
		if rem >= 0.0:
			parry_bits.append("rem=%.2f" % rem)
		bits.append("parry=%s" % " ".join(parry_bits))

	var rec_s: float = float(result.get("recovery_s", rd.get("recovery_s", -1.0)))
	if rec_s >= 0.0:
		bits.append("recover=%.2fs" % rec_s)

	var reason: String = str(rd.get("damage_resolve_note", "")).strip_edges()
	if reason.is_empty():
		reason = str(result.get("note", "")).strip_edges()
	if reason.is_empty():
		reason = _CombatLogFormatter.damage_resolve_note(rd)
	if not reason.is_empty() and outcome not in ["parry_deflect"]:
		bits.append("note=%s" % reason)

	if tgt_entity != null:
		bits.append("tgt[%s]" % format_vitals_suffix(tgt_entity))

	return " | ".join(bits)


## Append pain_shock and adrenaline annotations to an exchange line when either combatant has active states.
static func annotate_with_performance_states(line: String, atk_entity: Node = null, tgt_entity: Node = null) -> String:
	var tags := PackedStringArray()
	if atk_entity != null and is_instance_valid(atk_entity):
		tags.append_array(_performance_tags_for("atk", atk_entity))
	if tgt_entity != null and is_instance_valid(tgt_entity):
		tags.append_array(_performance_tags_for("tgt", tgt_entity))
	if tags.is_empty():
		return line
	return line + " | perf=" + " ".join(tags)


static func _performance_tags_for(role: String, entity: Node) -> PackedStringArray:
	var bits := PackedStringArray()
	if not entity.has_method("get_effective_consciousness"):
		return bits
	entity.ensure_consciousness_current()
	var mod: float = 1.0
	if entity.has_method("get_performance_modifier"):
		mod = entity.get_performance_modifier()
	var _cons: float = entity.effective_consciousness if "effective_consciousness" in entity else 100.0
	var pain_val: float = 0.0
	if entity.has_method("_get_effective_pain_for_thresholds"):
		pain_val = entity._get_effective_pain_for_thresholds()
	elif entity.has_method("get_total_pain"):
		pain_val = entity.get_total_pain()
	bits.append("%s_mod=%.2f" % [role, mod])
	if pain_val > 0.5:
		bits.append("%s_pain=%.1f" % [role, pain_val])
	var shock_until: float = -1.0
	if entity.has_method("_get_pain_shock_until_time"):
		shock_until = float(entity._get_pain_shock_until_time())
	elif "_pain_shock_until_time" in entity:
		shock_until = float(entity._pain_shock_until_time)
	if shock_until >= 0.0:
		var remaining: float = maxf(shock_until - CombatTiming.now_seconds(), 0.0)
		bits.append("%s_shock=%.1fs" % [role, remaining])
	var adrenaline_phase: String = ""
	if entity.has_method("_get_adrenaline_phase"):
		adrenaline_phase = entity._get_adrenaline_phase()
	elif "_adrenaline_phase" in entity:
		adrenaline_phase = str(entity._adrenaline_phase)
	if not adrenaline_phase.is_empty() and adrenaline_phase != "none":
		bits.append("%s_adr=%s" % [role, adrenaline_phase])
	return bits


static func format_matchup_banner(atk_cfg: Variant, def_cfg: Variant) -> String:
	var atk_species: String = "human" if str(atk_cfg.species_tres_path).contains("human") else "goblin"
	var def_species: String = "human" if str(def_cfg.species_tres_path).contains("human") else "goblin"
	var atk_armor: String = str(atk_cfg.armor_overrides.keys()) if not atk_cfg.armor_overrides.is_empty() else "none"
	var def_armor: String = str(def_cfg.armor_overrides.keys()) if not def_cfg.armor_overrides.is_empty() else "none"
	var ke_band: Vector2 = _DesignAnchors.ke_band_min_max_for_weapon(str(atk_cfg.weapon_id))
	return (
		"[Matchup] %s (%s %s %s/%s/%s/%s/%s grd=%s) vs %s (%s %s %s/%s/%s/%s/%s grd=%s) | armor: %s / %s | HEMA KE ref %.0f-%.0fJ"
		% [
			atk_cfg.display_name,
			atk_species,
			atk_cfg.weapon_id,
			atk_cfg.form,
			atk_cfg.strength,
			atk_cfg.agility,
			atk_cfg.endurance,
			atk_cfg.perception,
			atk_cfg.guard_line,
			def_cfg.display_name,
			def_species,
			def_cfg.weapon_id,
			def_cfg.form,
			def_cfg.strength,
			def_cfg.agility,
			def_cfg.endurance,
			def_cfg.perception,
			def_cfg.guard_line,
			atk_armor,
			def_armor,
			ke_band.x,
			ke_band.y,
		]
	)


## Stable machine-readable token for a free-text fight-end cause (see CombatTuningMain._infer_end_cause) so agents
## can aggregate outcomes across batches without parsing prose. Falls back to OTHER when unrecognized.
static func _cause_code(cause: String) -> String:
	var c: String = cause.to_lower().strip_edges()
	if c.is_empty():
		return "OTHER"
	if c == "bled_out":
		return "EXSANGUINATION"
	if c == "vital_destroyed":
		return "VITAL_DESTROYED"
	if c == "kill":
		return "KILL"
	if c.begins_with("head"):
		return "HEAD_TRAUMA"
	# Hemorrhagic syncope = unconscious (alive) from Class III/IV blood loss. Distinct from
	# EXSANGUINATION (dead, blood below the death threshold) so the logs no longer conflate
	# "unconscious from bleeding" with "bled out (dead)". Legacy "blood loss" prose maps here.
	if c.begins_with("hemorrhagic syncope") or c.begins_with("blood loss"):
		return "HEMORRHAGIC_SYNCOPE"
	if c.begins_with("unconscious"):
		return "UNCONSCIOUS"
	if c.begins_with("leg") or c.begins_with("arm destruction"):
		return "INCAPACITATED_LIMB"
	if c.begins_with("incapacitated"):
		return "INCAPACITATED"
	if c == "yield":
		return "YIELD"
	if c == "flee":
		return "FLEE"
	if c == "stalemate":
		return "STALEMATE"
	if c == "draw" or c == "standing":
		return "DRAW"
	return "OTHER"


## Compact stable token for a verbose death reason (see CoreEntity._get_death_reason) so the always-on DEATH line
## carries a machine-readable code instead of duplicating the numeric prose already summarized by cause_code.
## The verbose numbers remain available behind COMBAT_DEBUG_CALIBRATION.
static func _death_token(reason: String) -> String:
	var r: String = reason.to_lower().strip_edges()
	if r.is_empty():
		return "UNKNOWN"
	if r.begins_with("blood_loss"):
		return "BLEED_OUT"
	if r.begins_with("vital_part_destroyed") or r.begins_with("vital_part_zero"):
		return "VITAL_DESTROYED"
	return "OTHER"


static func format_fight_end(
	winner_side: String, end_cause: String, atk_name: String, def_name: String, atk_entity: Node, def_entity: Node
) -> String:
	var winner_name: String = atk_name if winner_side == "player" else def_name
	var lines := PackedStringArray()
	lines.push_back("[Fight end] winner=%s (%s) cause=%s cause_code=%s" % [winner_name, winner_side, end_cause, _cause_code(end_cause)])
	if atk_entity != null:
		lines.push_back("  %s vitals: %s" % [atk_name, format_vitals_suffix(atk_entity)])
		lines.push_back("  %s %s" % [atk_name, format_entity_tissue_oneline(atk_entity)])
	if def_entity != null:
		lines.push_back("  %s vitals: %s" % [def_name, format_vitals_suffix(def_entity)])
		lines.push_back("  %s %s" % [def_name, format_entity_tissue_oneline(def_entity)])
	return "\n".join(lines)


static func format_matchup_compact(atk_cfg: Variant, def_cfg: Variant) -> String:
	var atk_sp: String = "human" if str(atk_cfg.species_tres_path).contains("human") else "goblin"
	var def_sp: String = "human" if str(def_cfg.species_tres_path).contains("human") else "goblin"
	return (
		"atk=%s/%s/%s arm=%d def=%s/%s/%s arm=%d"
		% [
			atk_sp,
			atk_cfg.weapon_id,
			atk_cfg.form,
			atk_cfg.armor_overrides.size(),
			def_sp,
			def_cfg.weapon_id,
			def_cfg.form,
			def_cfg.armor_overrides.size(),
		]
	)


static func format_cycle_hema_summary(
	cycle_index: int,
	winner_name: String,
	end_cause: String,
	contact_strikes: int,
	total_strikes: int = -1,
	outcome_counts: Dictionary = {},
	ke_samples: Array = [],
	atk_dmg: float = 0.0,
	def_dmg: float = 0.0,
	aggregate_line: String = "",
	scenario_key: String = "",
	atk_cfg: Variant = null,
	def_cfg: Variant = null,
	atk_vitals: String = "",
	def_vitals: String = ""
) -> String:
	var total_exchanges: int = 0
	for k in outcome_counts:
		if k != "reject" and k != "parry_bind":
			total_exchanges += int(outcome_counts[k])
	var lines := PackedStringArray()
	# Backward compat: if only one strike arg was passed, use it for both.
	var effective_contacts: int = contact_strikes
	var effective_total: int = total_strikes
	if effective_total < 0:
		effective_total = contact_strikes
	lines.push_back(
		"--- Cycle %d: %s wins (%s) | exchanges=%d strikes=%d contacts=%d cause_code=%s —"
		% [cycle_index, winner_name, end_cause, total_exchanges, effective_total, effective_contacts, _cause_code(end_cause)]
	)
	if not scenario_key.is_empty():
		lines.push_back("  scenario: %s" % scenario_key)
	if atk_cfg != null and def_cfg != null:
		lines.push_back("  " + format_matchup_compact(atk_cfg, def_cfg))
	lines.push_back("  outcomes: %s" % _format_outcome_counts(outcome_counts))
	if total_exchanges > 0:
		var hit_n: int = int(outcome_counts.get("hit", 0)) + int(outcome_counts.get("glancing", 0)) + int(outcome_counts.get("negligible", 0))
		var deflect_n: int = int(outcome_counts.get("parry_deflect", 0))
		var bind_n: int = int(outcome_counts.get("parry_bind", 0))
		var partial_n: int = int(outcome_counts.get("parry_partial", 0))
		# parry_bind is a subset of parry_deflect/parry_partial — do NOT double-count in totals.
		var total_parry_count: int = deflect_n + partial_n
		var dodge_n: int = int(outcome_counts.get("dodge", 0))
		var miss_n: int = int(outcome_counts.get("miss", 0))
		# Residual exchange events counted in `exchanges` but not a strike outcome (e.g.
		# parry_deflection_shock, the parrier's recoil self-event). Surfacing them keeps the
		# rates line summing to 100% instead of silently dropping below it.
		var other_n: int = total_exchanges - hit_n - total_parry_count - dodge_n - miss_n
		var rates_line: String = "  rates: hit=%.1f%% parry=%.1f%% dodge=%.1f%% miss=%.1f%%" % [
			float(hit_n) / float(total_exchanges) * 100.0,
			float(total_parry_count) / float(total_exchanges) * 100.0,
			float(dodge_n) / float(total_exchanges) * 100.0,
			float(miss_n) / float(total_exchanges) * 100.0,
		]
		if other_n > 0:
			rates_line += " other=%.1f%%" % (float(other_n) / float(total_exchanges) * 100.0)
		lines.push_back(rates_line)
		var aim_drift_line: String = format_aim_drift(ke_samples)
		if not aim_drift_line.is_empty():
			lines.push_back("  " + aim_drift_line)
		if total_parry_count > 0:
			(
				lines
				. push_back(
					(
						"  parry_rates: deflect=%.1f%% partial=%.1f%% (bind=%.1f%% of parries)"
						% [
							float(deflect_n) / float(total_parry_count) * 100.0,
							float(partial_n) / float(total_parry_count) * 100.0,
							float(bind_n) / float(total_parry_count) * 100.0,
						]
					)
				)
			)
	lines.push_back("  " + _format_parry_taxonomy(outcome_counts, ke_samples))
	lines.push_back("  damage: atk=%.1f def=%.1f" % [atk_dmg, def_dmg])
	lines.push_back("  " + _format_ke_aggregate(ke_samples))
	lines.push_back("  " + _format_ke_bucket_lines(ke_samples))
	var vitals_line: String = tagged_vitals_pair(atk_vitals, def_vitals, winner_name)
	if not vitals_line.is_empty():
		lines.push_back("  " + vitals_line)
	lines.push_back("  " + aggregate_line)
	return "\n".join(lines)


## One-line stdout form of the cycle summary (the full block above stays in the log file).
static func format_cycle_hema_summary_oneline(
	winner_name: String,
	end_cause: String,
	contact_strikes: int,
	total_strikes: int = -1,
	outcome_counts: Dictionary = {},
	ke_samples: Array = [],
	atk_dmg: float = 0.0,
	def_dmg: float = 0.0,
	atk_vitals: String = "",
	def_vitals: String = ""
) -> String:
	var total_exchanges: int = 0
	for k in outcome_counts:
		if k != "reject" and k != "parry_bind":
			total_exchanges += int(outcome_counts[k])
	var effective_contacts: int = contact_strikes
	var effective_total: int = total_strikes
	if effective_total < 0:
		effective_total = contact_strikes
	var parts := PackedStringArray()
	parts.append("exch=%d" % total_exchanges)
	parts.append("strk=%d" % effective_total)
	parts.append("cont=%d" % effective_contacts)
	parts.append("code=%s" % _cause_code(end_cause))
	var hit_n: int = int(outcome_counts.get("hit", 0)) + int(outcome_counts.get("glancing", 0)) + int(outcome_counts.get("negligible", 0))
	if total_exchanges > 0:
		parts.append("hit=%.0f%%" % (float(hit_n) / float(total_exchanges) * 100.0))
	var ke_line: String = _format_ke_aggregate(ke_samples)
	if not ke_line.is_empty():
		parts.append(ke_line.trim_prefix("KE_all: "))
	parts.append("dmg=atk%d/def%d" % [int(atk_dmg), int(def_dmg)])
	var vitals_bit: String = tagged_vitals_pair(atk_vitals, def_vitals, winner_name)
	if not vitals_bit.is_empty():
		parts.append(vitals_bit)
	return "--- Cycle: %s wins (%s) — %s" % [winner_name, end_cause, " ".join(parts)]


static func _format_outcome_counts(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts := PackedStringArray()
	for k in keys:
		# parry_bind is a subset annotation on parry_deflect/parry_partial (not a distinct strike
		# outcome); listing it here inflates the sum so it no longer reconciles with `strikes`.
		# It is already shown in the `parry:` taxonomy line.
		if str(k) == "parry_bind":
			continue
		parts.append("%s=%d" % [str(k), int(counts[k])])
	return ", ".join(parts)


static func _ke_sample_ke_j(sample: Variant) -> float:
	if sample is Dictionary:
		return float((sample as Dictionary).get("ke_j", 0.0))
	return float(sample)


static func _ke_sample_move_id(sample: Variant) -> String:
	if sample is Dictionary:
		return str((sample as Dictionary).get("move_id", ""))
	return ""


static func _ke_sample_weapon_id(sample: Variant) -> String:
	if sample is Dictionary:
		return str((sample as Dictionary).get("weapon_id", ""))
	return ""


static func _ke_sample_delivery(sample: Variant) -> String:
	if sample is Dictionary:
		return str((sample as Dictionary).get("kinematic_delivery", "")).strip_edges().to_lower()
	return ""


static func _is_thrust_sample(sample: Variant) -> bool:
	var delivery: String = _ke_sample_delivery(sample)
	if delivery == "thrust":
		return true
	if delivery == "swing":
		return false
	var move_id: String = _ke_sample_move_id(sample)
	return move_id.contains("thrust") or move_id.contains("stab")


static func _ke_sample_is_follow_through(sample: Variant) -> bool:
	if sample is Dictionary:
		return bool((sample as Dictionary).get("is_follow_through", false))
	return false


## Light/probing swings (quick_slash, pommel_strike archetypes) are calibrated below the
## committed-swing KE band by design (velocity_factor 0.7-0.75 vs 1.0). Identifying them lets the
## committed_swing bucket report true committed swings instead of light strikes dragging in_band down.
static func _ke_sample_is_light_swing(sample: Variant) -> bool:
	if sample is not Dictionary:
		return false
	var arch: String = str((sample as Dictionary).get("archetype_id", ""))
	return arch == WeaponConstants.ARCHETYPE_QUICK_SLASH or arch == WeaponConstants.ARCHETYPE_POMMEL


## Aim-drift: fraction of intentional CONTACTS (aim_part set, KE>0) that land on a different
## part than aimed. Denominator is contacts, NOT strikes — so it is independent of the hit-rate
## line (which is over all strikes). A fight can be hit=100% (every strike connected) AND
## aim_drift=100% (every connection off the aimed part). Returns e.g. `aim_drift=37.8% (28/74
## contacts)` or "" when no intentional contacts were sampled.
##
## When drift > 0 the line appends `[blocked=N aim-error=M]`:
##   blocked   - aimed part was outside the intercept segment (guard/first-contact in the way)
##   aim-error—aimed part was in-segment but the weighted pick chose a different part
##
## aim-error is further bucketed by alignment tier (same thresholds as
## DefenseChoiceResolver: aligned >= PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD,
## glancing >= PARRY_GLANCING_ALIGNMENT_FLOOR, else off) so the log separates
## drift on committed, well-aligned strikes (a tuning signal) from drift on
## glancing, poorly-aligned swings (expected).
static func format_aim_drift(ke_samples: Array) -> String:
	var intentional: int = 0
	var drifted: int = 0
	var guard_blocked: int = 0
	var err_aligned: int = 0
	var err_glancing: int = 0
	var err_off: int = 0
	for raw in ke_samples:
		if not (raw is Dictionary):
			continue
		var s: Dictionary = raw as Dictionary
		var aim: String = str(s.get("aim_part", "")).strip_edges()
		if aim.is_empty():
			continue
		intentional += 1
		var hit: String = str(s.get("hit_part", "")).strip_edges()
		if not hit.is_empty() and aim != hit:
			drifted += 1
			if not bool(s.get("aim_reachable", false)):
				guard_blocked += 1
			else:
				var al: float = float(s.get("hit_alignment", -1.0))
				if al >= _CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD:
					err_aligned += 1
				elif al >= _CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR:
					err_glancing += 1
				else:
					err_off += 1
	if intentional == 0:
		return ""
	var aim_error: int = drifted - guard_blocked
	var breakdown: String = " [blocked=%d aim-error=%d]" % [guard_blocked, aim_error] if drifted > 0 else ""
	if aim_error > 0:
		breakdown += " err(align=%d gl=%d off=%d)" % [err_aligned, err_glancing, err_off]
	return "aim_drift=%.1f%% (%d/%d contacts)%s" % [float(drifted) / float(intentional) * 100.0, drifted, intentional, breakdown]


static func _format_ke_bucket_line(
	label: String, samples: Array, use_weapon_band: bool, band_weapon_id: String = "SWORD", band_delivery: String = ""
) -> String:
	if samples.is_empty():
		return "KE_%s: (no samples)" % label
	var sum_ke: float = 0.0
	var in_band: int = 0
	for raw in samples:
		var ke: float = _ke_sample_ke_j(raw)
		sum_ke += ke
		if not use_weapon_band or ke_band_tag_for_sample(raw) == "in_band":
			in_band += 1
	var n: int = samples.size()
	if use_weapon_band:
		var band: Vector2 = _DesignAnchors.ke_band_min_max_for_weapon(band_weapon_id, band_delivery)
		return (
			"KE_%s: n=%d mean=%.0fJ in_band=%.0f%% (ref %.0f-%.0fJ %s)"
			% [
				label,
				n,
				sum_ke / float(n),
				float(in_band) / float(n) * 100.0,
				band.x,
				band.y,
				band_weapon_id if band_delivery.is_empty() else "%s/%s" % [band_weapon_id, band_delivery],
			]
		)
	return "KE_%s: n=%d mean=%.0fJ" % [label, n, sum_ke / float(n)]


static func _dominant_weapon_in_samples(samples: Array, fallback: String = "SWORD") -> String:
	if samples.is_empty():
		return fallback
	var counts: Dictionary = {}
	for raw in samples:
		var wid: String = _ke_sample_weapon_id(raw)
		if wid.is_empty():
			wid = fallback
		counts[wid] = int(counts.get(wid, 0)) + 1
	var best: String = fallback
	var best_n: int = -1
	for k in counts:
		var n: int = int(counts[k])
		if n > best_n:
			best_n = n
			best = str(k)
	return best


static func _format_ke_bucket_lines(ke_samples: Array) -> String:
	var all_samples: Array = []
	var swing_samples: Array = []
	var thrust_samples: Array = []
	var light_samples: Array = []
	var light_swing_samples: Array = []
	var follow_through_samples: Array = []
	for raw in ke_samples:
		all_samples.append(raw)
		# Parry follow-throughs are real hits but not committed strikes — keep them out of the
		# committed-swing/thrust/light band buckets (their ~1J residual would drag in_band to 0%)
		# and report them in their own bucket so the committed-strike band stays meaningful.
		if _ke_sample_is_follow_through(raw):
			follow_through_samples.append(raw)
			continue
		var weapon_id: String = _ke_sample_weapon_id(raw)
		if weapon_id == "DAGGER":
			# Dagger hits live in the light bucket only (they would otherwise double-count
			# as swings via pommel/grab moves, and their thrusts as a second thrust bucket).
			light_samples.append(raw)
		elif _is_thrust_sample(raw):
			thrust_samples.append(raw)
		elif _ke_sample_is_light_swing(raw):
			# Light/probing swings are below the committed-swing band by design — give them their own
			# band-checked bucket so committed_swing in_band% reflects true committed swings.
			light_swing_samples.append(raw)
		else:
			swing_samples.append(raw)
	var parts := PackedStringArray()
	var swing_weapon: String = _dominant_weapon_in_samples(swing_samples)
	parts.append(_format_ke_bucket_line("committed_swing", swing_samples, true, swing_weapon, "swing"))
	if not thrust_samples.is_empty():
		var thrust_weapon: String = _dominant_weapon_in_samples(thrust_samples)
		parts.append(_format_ke_bucket_line("thrust", thrust_samples, true, thrust_weapon, "thrust"))
	if not light_samples.is_empty():
		# Dagger samples are routed to the light bucket (see _format_ke_bucket_lines); label the ref
		# "light" to match the bucket instead of the misleading "thrust" delivery tag.
		parts.append(_format_ke_bucket_line("light", light_samples, true, "DAGGER", "light"))
	if not light_swing_samples.is_empty():
		var light_swing_weapon: String = _dominant_weapon_in_samples(light_swing_samples)
		parts.append(_format_ke_bucket_line("light_swing", light_swing_samples, true, light_swing_weapon, "swing"))
	if not follow_through_samples.is_empty():
		parts.append(_format_ke_bucket_line("follow_through", follow_through_samples, false))
	parts.append(_format_ke_bucket_line("all", all_samples, false))
	return " | ".join(parts)


static func _format_parry_taxonomy(outcome_counts: Dictionary, ke_samples: Array) -> String:
	var deflect_n: int = int(outcome_counts.get("parry_deflect", 0))
	var bind_n: int = int(outcome_counts.get("parry_bind", 0))
	var partial_n: int = int(outcome_counts.get("parry_partial", 0))
	var ctrl_sum: float = 0.0
	var ctrl_n: int = 0
	for raw in ke_samples:
		if raw is not Dictionary:
			continue
		var ctrl: float = float((raw as Dictionary).get("parry_control", -1.0))
		if ctrl >= 0.0:
			ctrl_sum += ctrl
			ctrl_n += 1
	var ctrl_mean: float = ctrl_sum / float(ctrl_n) if ctrl_n > 0 else -1.0
	if ctrl_mean >= 0.0:
		return "parry: deflect=%d bind=%d partial=%d | ctrl_mean=%.2f" % [deflect_n, bind_n, partial_n, ctrl_mean]
	return "parry: deflect=%d bind=%d partial=%d" % [deflect_n, bind_n, partial_n]


static func _format_ke_aggregate(ke_samples: Array) -> String:
	if ke_samples.is_empty():
		return "KE_all: (no contact hits with kinematics)"
	var sum_ke: float = 0.0
	for raw in ke_samples:
		sum_ke += _ke_sample_ke_j(raw)
	var n: int = ke_samples.size()
	return "KE_all: n=%d mean=%.0fJ" % [n, sum_ke / float(n)]


static func csv_header() -> String:
	return (
		"strike_index,outcome,move_id,part,intensity,power,follow_through,wind_up_s,"
		+ "attack_line,atk_guard,def_guard,strike_ke_j,hema_ke_band,pen_mm,"
		+ "dmg,phys,cut,blunt,bone,pre_armor,mech_post_armor,recovery_s,"
		+ "gauge_atk,gauge_def,health_before,health_after,note,perf"
	)


static func csv_row(
	strike_index: int, _move_id: String, result: Dictionary, gauge_atk: float, gauge_def: float
) -> String:
	var rd: Dictionary = _resolved_payload(result)
	var ke_j: float = _strike_ke_j(rd)
	var note: String = str(rd.get("damage_resolve_note", _CombatLogFormatter.damage_resolve_note(rd)))
	var parts := PackedStringArray()
	parts.push_back(str(strike_index))
	parts.push_back(_resolved_outcome(result))
	parts.push_back(_move_id_from_result(result))
	parts.push_back(str(rd.get("part", "")))
	parts.push_back("%.3f" % float(result.get("intensity", rd.get("intensity", 0.0))))
	parts.push_back("%.3f" % float(result.get("power", rd.get("power", 0.0))))
	parts.push_back("%.3f" % float(result.get("follow_through", rd.get("follow_through", 0.0))))
	parts.push_back("%.3f" % float(result.get("wind_up_s", rd.get("wind_up_s", 0.0))))
	parts.push_back(str(result.get("attack_line", rd.get("attack_line", ""))))
	parts.push_back(str(result.get("atk_guard", "")))
	parts.push_back(str(result.get("def_guard", "")))
	parts.push_back("%.2f" % ke_j)
	parts.push_back(ke_band_tag_for_sample(_ke_sample_meta(result)))
	parts.push_back("%.3f" % float(rd.get("penetration_sharp_applied", rd.get("penetration", 0.0))))
	parts.push_back(str(int(rd.get("dmg", 0))))
	parts.push_back("%.4f" % float(rd.get("total_physical", rd.get("dmg", 0.0))))
	parts.push_back("%.2f" % float(rd.get("final_cut", 0.0)))
	parts.push_back("%.2f" % float(rd.get("final_blunt", 0.0)))
	parts.push_back("%.2f" % float(rd.get("final_bone", 0.0)))
	parts.push_back("%.2f" % float(rd.get("pre_armor", 0.0)))
	parts.push_back("%.2f" % float(rd.get("mechanical_post_armor", 0.0)))
	parts.push_back("%.3f" % float(result.get("recovery_s", rd.get("recovery_s", 0.0))))
	parts.push_back("%.3f" % gauge_atk)
	parts.push_back("%.3f" % gauge_def)
	parts.push_back("%.0f" % float(rd.get("health_before", 0.0)))
	parts.push_back("%.0f" % float(rd.get("health_after", 0.0)))
	parts.push_back(note.replace(",", ";"))
	var perf_bit: String = format_attack_perf(rd)
	parts.push_back(perf_bit.replace(",", " ") if not perf_bit.is_empty() else "")
	return ",".join(parts)


static func _build_archetype_for_inference(_weapon_id: String, move_id: String) -> Dictionary:
	# Reconstruct a minimal archetype dict from weapon+move definitions so that
	# WeaponDamageHelper.kinematic_delivery() can consult explicit archetype fields
	# instead of falling back to contact_type inference (which misclassifies moves
	# like "shaft_thrust" as swing when the archetype context is missing).
	var move_def: Dictionary = WeaponConstants.get_move(move_id)
	if not move_def.is_empty():
		var arch_id: String = str(move_def.get("archetype_id", ""))
		if not arch_id.is_empty():
			return WeaponConstants.get_archetype(arch_id)
	return {}
