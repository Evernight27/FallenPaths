class_name TuningLogFormatter
extends RefCounted

## HEMA-oriented strike / cycle logging for the combat tuning scene.
## Anchors: `CombatDesignAnchors.COMMITTED_STRIKE_KE_J_*`, `CombatResearchAnchors`, ATLS via `BleedingConstants`.

const _ConfigData := preload("res://tools/combat_tuning/TuningConfigData.gd")
const _CombatLogFormatter := preload("res://ui/battle/CombatLogFormatter.gd")
const _DesignAnchors := preload("res://core/CombatDesignAnchors.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _WeaponDamageHelper := preload("res://resources/weapons/WeaponDamageHelper.gd")

const _SWING_MOVE_IDS: Array[String] = [
    "oberhau",
    "diagonal_chop",
    "slash",
    "side_strike",
    "overhead_chop",
    "overhead_strike",
    "pole_swing",
    "poll_strike",
]

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
        var hp_ratio: float = (cut + blunt) / max_hp if max_hp > 0.0 else 0.0
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


static func strike_ke_from_result(result: Dictionary) -> float:
    return _strike_ke_j(_resolved_payload(result))


static func ke_sample_from_result(result: Dictionary) -> Dictionary:
    var rd: Dictionary = _resolved_payload(result)
    var sample: Dictionary = {
        "ke_j": _strike_ke_j(rd),
        "move_id": _move_id_from_result(result),
        "weapon_id": str(result.get("weapon_id", rd.get("weapon_id", ""))),
        "kinematic_delivery": str(result.get("kinematic_delivery", rd.get("kinematic_delivery", ""))),
    }
    if result.has("parry_control"):
        sample["parry_control"] = float(result["parry_control"])
    elif rd.has("parry_control"):
        sample["parry_control"] = float(rd["parry_control"])
    var delivery: String = str(sample.get("kinematic_delivery", ""))
    if delivery.is_empty():
        var move_id: String = str(sample.get("move_id", ""))
        if not move_id.is_empty():
            sample["kinematic_delivery"] = _WeaponDamageHelper.kinematic_delivery({}, move_id)
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
    return "KE=%.0fJ [%s, ref %.0f-%.0fJ]" % [ke_j, band_label, band.x, band.y]


static func format_hema_ke_tag(ke_j: float) -> String:
    return format_ke_tag_for_sample({"ke_j": ke_j, "weapon_id": "SWORD"})


static func atls_class_label(remaining_blood_pct: float) -> String:
    var cls: int = _Bleeding.atls_hemorrhage_class_from_remaining_pct(remaining_blood_pct)
    return "ATLS-%s" % ["0", "I", "II", "III", "IV"][clampi(cls, 0, 4)]


static func format_vitals_suffix(entity: Node) -> String:
    if entity == null or not is_instance_valid(entity):
        return ""
    entity.ensure_consciousness_current()
    var blood: float = float(entity.blood_volume)
    var atls: String = atls_class_label(blood)
    return "blood=%.0f%% %s con=%.0f" % [blood, atls, float(entity.consciousness)]


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
        "fled", "yielded", "focus_line", "skip":
            var short := "[HEMA] %s%s %s | outcome=%s" % [idx_bit, atk_name, move_id, outcome]
            if tgt_entity != null or atk_entity != null:
                var ent: Node = atk_entity if outcome in ["fled", "yielded"] else tgt_entity
                short += " | actor[%s]" % format_vitals_suffix(ent)
            return short
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
    var gauge_atk_pre: float = float(result.get("gauge_atk_pre", _resolved_payload(result).get("gauge_atk_pre", -1.0)))
    var gauge_def_pre: float = float(result.get("gauge_def_pre", _resolved_payload(result).get("gauge_def_pre", -1.0)))
    if gauge_atk_pre >= 0.0 or gauge_def_pre >= 0.0:
        bits.append("gauge_pre_atk=%.3f gauge_pre_def=%.3f" % [maxf(gauge_atk_pre, 0.0), maxf(gauge_def_pre, 0.0)])
    var parent_idx: int = int(
        result.get("parent_exchange_index", _resolved_payload(result).get("parent_exchange_index", -1))
    )
    if parent_idx > 0:
        bits.append("ft_parent=#%d" % parent_idx)

    var ke_j: float = _strike_ke_j(rd)
    if ke_j > 0.0:
        (
            bits
            . append(
                format_ke_tag_for_sample(
                    {
                        "ke_j": ke_j,
                        "weapon_id": str(result.get("weapon_id", rd.get("weapon_id", ""))),
                        "kinematic_delivery": str(result.get("kinematic_delivery", rd.get("kinematic_delivery", ""))),
                        "move_id": _move_id_from_result(result),
                    }
                )
            )
        )
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
        var pre_armor: float = float(rd.get("pre_armor", -1.0))
        var mech: float = float(rd.get("mechanical_post_armor", -1.0))
        bits.append("pre_armor=%.1f mech=%.1f" % [maxf(pre_armor, 0.0), maxf(mech, 0.0)])
        var hb: float = float(rd.get("health_before", 0.0))
        var ha: float = float(rd.get("health_after", 0.0))
        if hb > 0.0 or ha > 0.0:
            bits.append("part_hp=%.0f->%.0f delta=%.0f" % [hb, ha, ha - hb])

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


## Optional second line with part tissue delta (verbose tuning panel).
static func format_strike_detail(result: Dictionary, atk_gauge: float, def_gauge: float) -> String:
    var rd: Dictionary = _resolved_payload(result)
    var hb: float = float(rd.get("health_before", 0.0))
    var ha: float = float(rd.get("health_after", 0.0))
    if hb <= 0.0 and ha <= 0.0 and atk_gauge < 0.0:
        return ""
    var lines := PackedStringArray()
    if hb > 0.0 or ha > 0.0:
        lines.push_back("  part_hp: %.0f -> %.0f (delta=%.0f)" % [hb, ha, ha - hb])
    if atk_gauge >= 0.0:
        lines.push_back("  gauge: atk=%.3f def=%.3f" % [atk_gauge, def_gauge])
    return "\n".join(lines)


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


static func format_fight_end(
    winner_side: String, end_cause: String, atk_name: String, def_name: String, atk_entity: Node, def_entity: Node
) -> String:
    var winner_name: String = atk_name if winner_side == "player" else def_name
    var lines := PackedStringArray()
    lines.push_back("[Fight end] winner=%s (%s) cause=%s" % [winner_name, winner_side, end_cause])
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
    strikes: int,
    outcome_counts: Dictionary,
    ke_samples: Array,
    atk_dmg: float,
    def_dmg: float,
    aggregate_line: String,
    scenario_key: String = "",
    atk_cfg: Variant = null,
    def_cfg: Variant = null
) -> String:
    var total_exchanges: int = 0
    for k in outcome_counts:
        total_exchanges += int(outcome_counts[k])
    var lines := PackedStringArray()
    lines.push_back(
        "--- Cycle %d: %s (%s) | exchanges=%d strikes_logged=%d —"
        % [cycle_index, winner_name, end_cause, total_exchanges, strikes]
    )
    if not scenario_key.is_empty():
        lines.push_back("  scenario: %s" % scenario_key)
    if atk_cfg != null and def_cfg != null:
        lines.push_back("  " + format_matchup_compact(atk_cfg, def_cfg))
    lines.push_back("  outcomes: %s" % _format_outcome_counts(outcome_counts))
    if total_exchanges > 0:
        var hit_n: int = int(outcome_counts.get("hit", 0)) + int(outcome_counts.get("glancing", 0))
        var deflect_n: int = int(outcome_counts.get("parry_deflect", 0))
        var bind_n: int = int(outcome_counts.get("parry_bind", 0))
        var partial_n: int = int(outcome_counts.get("parry_partial", 0))
        var parry_n: int = deflect_n + bind_n + partial_n
        (
            lines
            . push_back(
                (
                    "  rates: hit=%.1f%% parry=%.1f%% dodge=%.1f%% miss=%.1f%%"
                    % [
                        float(hit_n) / float(total_exchanges) * 100.0,
                        float(parry_n) / float(total_exchanges) * 100.0,
                        float(outcome_counts.get("dodge", 0)) / float(total_exchanges) * 100.0,
                        float(outcome_counts.get("miss", 0)) / float(total_exchanges) * 100.0,
                    ]
                )
            )
        )
        if parry_n > 0:
            (
                lines
                . push_back(
                    (
                        "  parry_rates: deflect=%.1f%% bind=%.1f%% partial=%.1f%%"
                        % [
                            float(deflect_n) / float(parry_n) * 100.0,
                            float(bind_n) / float(parry_n) * 100.0,
                            float(partial_n) / float(parry_n) * 100.0,
                        ]
                    )
                )
            )
    lines.push_back("  " + _format_parry_taxonomy(outcome_counts, ke_samples))
    lines.push_back("  damage: atk=%.1f def=%.1f" % [atk_dmg, def_dmg])
    lines.push_back("  " + _format_ke_aggregate(ke_samples))
    lines.push_back("  " + _format_ke_bucket_lines(ke_samples))
    lines.push_back("  " + aggregate_line)
    return "\n".join(lines)


static func _format_outcome_counts(counts: Dictionary) -> String:
    var keys: Array = counts.keys()
    keys.sort()
    var parts := PackedStringArray()
    for k in keys:
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


static func _is_committed_swing_sample(sample: Variant) -> bool:
    var move_id: String = _ke_sample_move_id(sample)
    if move_id in _SWING_MOVE_IDS:
        return true
    if sample is Dictionary:
        var delivery: String = str((sample as Dictionary).get("kinematic_delivery", ""))
        return delivery == "swing"
    return false


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
    for raw in ke_samples:
        all_samples.append(raw)
        var move_id: String = _ke_sample_move_id(raw)
        var weapon_id: String = _ke_sample_weapon_id(raw)
        if _is_committed_swing_sample(raw):
            swing_samples.append(raw)
        if (
            move_id.contains("thrust")
            or move_id in ["spike_thrust", "quick_thrust", "committed_thrust", "spear_thrust"]
        ):
            thrust_samples.append(raw)
        if weapon_id == "DAGGER":
            light_samples.append(raw)
    var parts := PackedStringArray()
    var swing_weapon: String = _dominant_weapon_in_samples(swing_samples)
    parts.append(_format_ke_bucket_line("committed_swing", swing_samples, true, swing_weapon, "swing"))
    if not thrust_samples.is_empty():
        parts.append(_format_ke_bucket_line("thrust", thrust_samples, true, "SPEAR", "thrust"))
    if not light_samples.is_empty():
        parts.append(_format_ke_bucket_line("light", light_samples, true, "DAGGER", "thrust"))
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


static func format_strike_one_line(move_id: String, result: Dictionary) -> String:
    return format_exchange_line("?", "?", result).replace("[HEMA] ? ", "[HEMA] %s " % move_id)


static func format_entity_health(entity: Node) -> String:
    if entity == null or not is_instance_valid(entity):
        return "(no entity)"
    entity.ensure_consciousness_current()
    var parts := _ConfigData.BODY_PARTS
    var lines := PackedStringArray()
    for part in parts:
        var cut: float = entity.body_cutting.get(part, 0.0)
        var blunt: float = entity.body_blunt.get(part, 0.0)
        var max_hp: float = entity.body_max.get(part, 1.0)
        var bone: float = entity.bone_health.get(part, 0.0)
        var bone_max_val: float = entity.bone_max.get(part, 1.0)
        var hp_ratio: float = (cut + blunt) / max_hp if max_hp > 0.0 else 0.0
        var bone_ratio: float = bone / bone_max_val if bone_max_val > 0.0 else 0.0
        lines.push_back("  %s: tissue=%.0f%% bone=%.0f%%" % [part, hp_ratio * 100.0, bone_ratio * 100.0])
    lines.push_back("  %s" % format_vitals_suffix(entity))
    return "\n".join(lines)


static func format_combatant_state(c: Dictionary) -> String:
    if c.is_empty():
        return "(no combatant)"
    return (
        "state=%s stamina=%.0f%% gauge=%.0f%% guard=%s form=%s"
        % [
            c.get("state", "?"),
            float(c.get("stamina", 0.0)) / maxf(float(c.get("stamina_max", 100.0)), 1.0) * 100.0,
            float(c.get("gauge", 0.0)),
            c.get("guard_line", "?"),
            str(c.get("weapon_form", c.get("_form_str", "?"))),
        ]
    )


static func csv_header() -> String:
    return (
        "strike_index,outcome,move_id,part,intensity,power,follow_through,wind_up_s,"
        + "attack_line,atk_guard,def_guard,strike_ke_j,hema_ke_band,pen_mm,"
        + "dmg,phys,cut,blunt,bone,pre_armor,mech_post_armor,recovery_s,"
        + "gauge_atk,gauge_def,health_before,health_after,note"
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
    (
        parts
        . push_back(
            ke_band_tag_for_sample(
                {
                    "ke_j": ke_j,
                    "weapon_id": str(result.get("weapon_id", rd.get("weapon_id", ""))),
                    "kinematic_delivery": str(result.get("kinematic_delivery", rd.get("kinematic_delivery", ""))),
                    "move_id": _move_id_from_result(result),
                }
            )
        )
    )
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
    return ",".join(parts)
