class_name DefenseParryMath
extends RefCounted

## Parry / dodge / feint computation subdomain, extracted from **`DefenseChoiceResolver`**.
## Pure computation over the combatant dicts + manager; no instance state. `choose_defense`
## keeps its decision logic in `DefenseChoiceResolver`; this module holds the shared parry
## capacity / timing / geometry / feint / spacing math that `choose_defense`, the AI, and the
## harnesses call (referenced via class_name; no circular preload).


static func _get_effective_redirect(tgt: Dictionary) -> float:
    var pcfg: Dictionary = PassiveParryContext.get_parry_config()
    var redirect_attempt: float = pcfg.get(DataKeys.PCFG_REDIRECT_ATTEMPT_RATIO, 2.5)
    var agi_scale: float = pcfg.get(DataKeys.PCFG_REDIRECT_ATTEMPT_AGILITY_SCALE, 0.5)
    var agi_d_attempt: float = float(
        CombatantEntityAccess.stats_dict(tgt).get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
    )
    return redirect_attempt * (0.75 + agi_scale * clampf(agi_d_attempt / 100.0, 0.0, 1.5))


## Doc-10 Issue 2: a localized arm wound degrades blade delivery (attack) more than blade-on-blade parry contact.
## plan_balance_tuning.md line 91 anchors "-15% attack / -10% parry" -> parry penalty = grip penalty * 10/15, so
## parry capacity stays gentler than attack at the same wound while scaling with the severity-scaled grip mult.
## Feature-gated.
static func arm_wound_parry_capacity_mult(arm_mod: float) -> float:
    if not CombatConstants.is_feature_arm_wound_degradation_enabled() or arm_mod >= 1.0:
        return arm_mod
    var grip_penalty: float = 1.0 - arm_mod
    return maxf(0.1, 1.0 - grip_penalty * CombatConstants.ARM_WOUND_GRIP_PARRY_PENALTY_RATIO)


static func _compute_parry_c_d(def_weapon, tgt: Dictionary, contact_type: String = "") -> float:
    var m_parry_part: float = CombatantEntityAccess.weapon_parry_part_mass_kg(def_weapon)
    var m_total: float = CombatantEntityAccess.weapon_mass_kg(def_weapon)
    # Full weapon mass matters: inertia and geometry. Blend parry-part (contact) with total (leverage).
    var m_d: float = (
        lerpf(m_parry_part, m_total, CombatConstants.PARRY_INERTIA_BLEND)
        if CombatantEntityAccess.weapon_has_parts(def_weapon)
        else m_total
    )
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var s_d: float = float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var c_d_full: float = (
        m_d * PassiveParryContext.get_parry_speed_m_s(def_weapon) * (s_d / CombatConstants.PARRY_STRENGTH_NORM)
    )
    var agi_d: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    c_d_full *= clampf(agi_d / 100.0, CombatConstants.RECOVERY_AGILITY_MIN, CombatConstants.RECOVERY_AGILITY_MAX)
    # Full parry capacity modifier: includes pain, consciousness, blood, concussion, and limb crippling
    # (get_parry_capacity_modifier already incorporates get_performance_modifier internally).
    var def_entity: Node = CombatantEntityAccess.combat_body(tgt) if not tgt.is_empty() else null
    var def_parry_mod: float = (
        (EntityPainConsciousness.get_parry_capacity_modifier(def_entity))
        if def_entity != null and def_entity.has_method("_get_vital_parts")
        else 1.0
    )
    c_d_full *= maxf(CombatConstants.PERF_MOD_MIN, def_parry_mod)
    c_d_full *= arm_wound_parry_capacity_mult(maxf(0.1, CombatantEntityAccess.get_attack_damage_modifier(tgt)))
    if CombatantEntityAccess.weapon_has_parts(def_weapon):
        var pct: String = CombatantEntityAccess.weapon_parry_contact_type(def_weapon)
        c_d_full *= CombatConstants.PARRY_CONTACT_MODIFIERS.get(pct, 1.0)
    var contact_key: String = contact_type.to_lower().strip_edges()
    if not contact_key.is_empty():
        var def_type: String = str(def_weapon.get("weapon_type")).to_upper()
        var mod_dict: Variant = CombatConstants.PARRY_DEF_VS_ATK_MOD.get(def_type, {})
        if mod_dict is Dictionary:
            var mult: float = mod_dict.get(contact_key, 1.0)
            c_d_full *= mult
    # HEMA: a two-handed grip braces the weapon into the torso/core, holding parry structure better
    # against a strong blow (longer lever + both arms). One-handed (SWORD/DAGGER/MACE/AXE) is neutral
    # 1.0 — D001 SWORD soak unaffected. Applied to base capacity so it feeds both on-time and late.
    c_d_full *= CombatConstants.parry_two_handed_capacity_mult(WeaponConstants.weapon_is_two_handed(def_weapon))
    return c_d_full


## Pre-parry guard line matching: a trained defender shifts their blade toward the attack trajectory before parrying.
## When can_parry_in_time is true and alignment is at least glancing (>= floor), look up which guard lines produce
## better alignment against the incoming attack. Use the best-matching guard line's alignment for capacity calculation,
## simulating a competent fencer adjusting their posture to meet the attack on-line. This prevents stale guard positions
## from degrading c_d when the defender hasn't yet committed to a new stance (that happens at apply_defender_step).
static func _apply_guard_line_matching(
    alignment: float, attack_line: String, tgt, can_parry_in_time: bool, proactive_boost: float
) -> float:
    if not can_parry_in_time or alignment < CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR:
        return minf(1.0, alignment + proactive_boost)
    var guard_line_cur: String = str(tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT))
    if attack_line.is_empty() or guard_line_cur.is_empty():
        return minf(1.0, alignment + proactive_boost)
    var best_align: float = alignment
    var candidate_lines: Array[String] = [attack_line]
    if attack_line in CombatGuardLines.LINE_ADJACENTS:
        for adj in CombatGuardLines.LINE_ADJACENTS[attack_line]:
            candidate_lines.append(adj)
    for cand in candidate_lines:
        var test_align: float = CombatGuardLines.alignment_from_lines(attack_line, cand, 0.0)
        if test_align > best_align:
            best_align = test_align
    return minf(1.0, maxf(best_align, alignment + proactive_boost))


## Unified contact geometry: alignment × leverage. Blade gets alignment only (leverage=1); shaft/haft get alignment ×
## leverage factor.
## Merges angular (attack vs guard) and linear (where along shaft contact happens) into one multiplier.
## A 0.35 geometry floor (deliberate gameplay choice) keeps parrying forgiving: even a poorly-aligned guard
## retains ~35% parry capacity before the guard-zone penalty is applied, so a blade in motion can still
## intercept at poor angles. (An earlier micro-floor of 0.001 was replaced by this higher floor.)
static func _get_contact_geometry(alignment: float, def_weapon) -> float:
    var is_blade: bool = (
        not CombatantEntityAccess.weapon_has_parts(def_weapon)
        or CombatantEntityAccess.weapon_parry_contact_type(def_weapon) == "blade"
    )
    var effective_align: float = alignment
    if is_blade:
        effective_align = (
            pow(clampf(alignment, 0.0, 1.0), 0.75) + (alignment - pow(clampf(alignment, 0.0, 1.0), 0.75)) * 0.25
        )
    var leverage: float = _get_leverage_factor(def_weapon, effective_align)
    return maxf(0.35, effective_align) * leverage


## Leverage factor: where along shaft/haft the blow lands. Good alignment = defender controlled contact = strong (near
## hands).
## Poor alignment = contact could be weak (far from hands). Blade/handle: 1.0 (uniform).
static func _get_leverage_factor(def_weapon, alignment: float) -> float:
    if not CombatantEntityAccess.weapon_has_parts(def_weapon):
        return 1.0
    var pct: String = CombatantEntityAccess.weapon_parry_contact_type(def_weapon)
    if pct != "shaft" and pct != "haft":
        return 1.0
    var len_cm: float = CombatantEntityAccess.weapon_parry_part_length_cm(def_weapon)
    if len_cm < CombatConstants.PARRY_LEVERAGE_LONG_PART_CM:
        return 1.0
    return lerpf(CombatConstants.PARRY_LEVERAGE_FLOOR, 1.0, alignment)


static func _get_parry_capacity_mult(def_weapon, tgt: Dictionary, parry_time_to_react: float) -> float:
    # Weapon objects use direct properties; Object.get() takes 1 arg (no default like Dictionary).
    var m_d: float = CombatantEntityAccess.weapon_mass_kg(def_weapon)
    var s_d: float = float(
        CombatantEntityAccess.stats_dict(tgt).get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)
    )
    var speed_f: float = clampf(
        float(def_weapon.parry_speed_factor), CombatConstants.STAT_EFFECT_MULT_MIN, CombatConstants.STAT_EFFECT_MULT_MAX
    )
    var blade_movement_s: float = (
        (
            CombatConstants.PARRY_BLADE_MOVEMENT_S
            * clampf(
                m_d * CombatConstants.PARRY_STRENGTH_NORM / maxf(s_d, 1.0),
                CombatConstants.PARRY_MOVEMENT_MASS_STRENGTH_MIN,
                CombatConstants.PARRY_MOVEMENT_MASS_STRENGTH_MAX
            )
        )
        / speed_f
    )
    var effective_parry_time: float = maxf(0.0, parry_time_to_react - blade_movement_s)
    return clampf(effective_parry_time / CombatConstants.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0.0, 1.0)


static func _parry_bonus_if_active(tgt: Dictionary) -> float:
    var now_s: float = CombatTiming.now_seconds()
    if tgt.get(DataKeys.PA_PARRY_BONUS_UNTIL, -1.0) > now_s:
        return float(tgt.get(DataKeys.PA_PARRY_BONUS_MULT, 1.1))
    return 1.0


static func _get_line_alignment(
    attack_type: String,
    tgt: Dictionary,
    effective_attack_line_override: String = "",
    alignment_context: Dictionary = {},
    base_alignment: float = -1.0
) -> float:
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var attack_line: String = (
        effective_attack_line_override
        if not effective_attack_line_override.is_empty()
        else move_def.get(DataKeys.PA_ATTACK_LINE, "high")
    )
    # G2: share the guard alignment stamped at resolve (same source DefenseChoiceResolver parry uses) for the
    # line-based path; the angle context (blade at parry contact) is the fine-grained refinement.
    if alignment_context.is_empty() and base_alignment >= 0.0:
        return base_alignment
    return CombatConstants.get_line_alignment_with_deflect(attack_line, tgt, alignment_context)


## IV-5 BP6: boost parry alignment when attack-side arm is on the intercept path despite misaligned guard.
static func _alignment_with_arm_interpose(
    attack_type: String,
    tgt: Dictionary,
    effective_attack_line: String,
    alignment: float,
    targetable: Array,
    result: Dictionary
) -> float:
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var atk_line: String = (
        effective_attack_line
        if not effective_attack_line.is_empty()
        else str(move_def.get(DataKeys.PA_ATTACK_LINE, "high"))
    )
    var guard_line: String = str(tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT))
    var interpose: Dictionary = CombatGuardLines.arm_interpose_eval(atk_line, guard_line, alignment, targetable)
    if not interpose.get("active", false):
        return alignment
    var boost: float = interpose.get("align_boost", 0.0)
    result[DataKeys.RESULT_ARM_INTERPOSE_ARM] = interpose.get(CombatConstants.INTERPOSE_KEY_ARM, "")
    result[DataKeys.RESULT_ARM_INTERPOSE_BOOST] = boost
    return minf(1.0, alignment + boost)


static func _defender_spacing_band_to_attacker(tgt: Dictionary, atk: Dictionary) -> String:
    return CombatConstants.defender_distance_band_to_attacker_id(tgt, CombatantEntityAccess.id_int(atk))


static func _spacing_band_parry_capacity_mult(tgt: Dictionary, atk: Dictionary) -> float:
    match _defender_spacing_band_to_attacker(tgt, atk):
        CombatConstants.DISTANCE_CLOSE:
            return CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE
        CombatConstants.DISTANCE_LONG:
            return CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG
        _:
            return 1.0


static func _reach_disparity_parry_penalty(atk: Dictionary, tgt: Dictionary) -> float:
    var atk_weapon = CombatantEntityAccess.get_weapon(atk)
    if atk_weapon == null:
        return 1.0
    var atk_range = 1.5
    if atk_weapon is Dictionary:
        atk_range = float(atk_weapon.get("melee_range", 1.5))
    else:
        atk_range = float(atk_weapon.melee_range)
    var def_weapon = CombatantEntityAccess.get_weapon(tgt)
    if def_weapon == null:
        return 1.0
    var def_range = 1.5
    if def_weapon is Dictionary:
        def_range = float(def_weapon.get("melee_range", 1.5))
    else:
        def_range = float(def_weapon.melee_range)
    var disparity = atk_range - def_range
    if disparity <= CombatConstants.REACH_DISPARITY_THRESHOLD_M:
        return 1.0
    # Slope 0.3 (was 0.5): reach delta is already partly priced by _reach_parry_readiness_bonus, so a
    # steeper slope double-counted the same advantage (sword 0.65 / dagger 0.30 -> 0.79 / 0.58).
    var penalty = clampf(
        1.0 - (disparity - CombatConstants.REACH_DISPARITY_THRESHOLD_M) * CombatConstants.REACH_DISPARITY_PENALTY_SLOPE,
        CombatConstants.REACH_DISPARITY_PENALTY_FLOOR,
        1.0
    )
    return penalty


static func _spacing_band_dodge_chance_mult(tgt: Dictionary, atk: Dictionary) -> float:
    match _defender_spacing_band_to_attacker(tgt, atk):
        CombatConstants.DISTANCE_CLOSE:
            return CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE
        CombatConstants.DISTANCE_LONG:
            return CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG
        _:
            return 1.0


static func _feint_telegraph_dodge_spacing_mult(tgt: Dictionary, atk: Dictionary) -> float:
    match _defender_spacing_band_to_attacker(tgt, atk):
        CombatConstants.DISTANCE_CLOSE:
            return CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE
        CombatConstants.DISTANCE_LONG:
            return CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG
        _:
            return 1.0


## Tier 4.2 telegraph delay (Feint “C”): until attacker wind-up progress ≥
## **`feint_target_reveal_at_progress`**, damp readiness used for feint read-through / dodge telegraph / guard-zone bait
## resolution (**`1.0`** = disabled). If **`pa`** has **`feint_target_reveal_at_progress`** and it is **≤ 0**,
## delay is off; if the key is absent, read the fraction from **`WeaponConstants.get_move(attack_type)`**.
static func _feint_readiness_reveal_mult(pa: Dictionary, atk: Dictionary) -> float:
    var fp: String = pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges()
    if fp.is_empty():
        return 1.0
    var reveal_at: float = 0.0
    if pa.has(DataKeys.PA_FEINT_TARGET_REVEAL_AT_PROGRESS):
        reveal_at = clampf(float(pa[DataKeys.PA_FEINT_TARGET_REVEAL_AT_PROGRESS]), 0.0, 1.0)
        if reveal_at <= 0.0:
            return 1.0
    else:
        var mid: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
        if not mid.is_empty():
            reveal_at = clampf(
                WeaponConstants.get_move(mid).get(DataKeys.WEAPON_FEINT_TARGET_REVEAL_AT_PROGRESS, 0.0), 0.0, 1.0
            )
        if reveal_at <= 0.0:
            return 1.0
    if CombatantEntityAccess.state_str(atk) != CombatConstants.STATE_WIND_UP:
        return 1.0
    var dur: float = atk.get(DataKeys.PA_STATE_DURATION, 0.0)
    var t: float = atk.get(DataKeys.PA_STATE_TIMER, 0.0)
    var denom: float = maxf(0.001, dur)
    var p: float = clampf(t / denom, 0.0, 1.0)
    if p >= reveal_at:
        return 1.0
    return lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, p / maxf(0.001, reveal_at))


## Tier 4.2: defender passive readiness for feint listing weight (shared by **`CombatAIActionPicker`** and harness).
static func defender_feint_listing_pr_def(
    defender: Dictionary,
    attacker_id: int,
    move_id: String,
    attacker: Dictionary = {},
    pa_live: Dictionary = {},
    apply_stamina_and_exhaustion: bool = true,
    apply_spacing_mult: bool = true
) -> float:
    var pr_def: float = clampf(PassiveParryContext.get_passive_parry_readiness(defender), 0.0, 1.0)
    var ct_mv: String = str(
        WeaponConstants.get_move(move_id).get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT)
    )
    pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct_mv), 0.0, 1.0)
    if apply_stamina_and_exhaustion:
        pr_def = clampf(
            (
                pr_def
                * CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
                    CombatantEntityAccess.stamina_ratio(defender)
                )
                * CombatConstants.defender_passive_readiness_exhaustion_mult(defender)
            ),
            0.0,
            1.0
        )
    if apply_spacing_mult:
        pr_def = clampf(
            pr_def * CombatConstants.ai_feint_listing_defender_readiness_spacing_mult(defender, attacker_id), 0.0, 1.0
        )
    if not attacker.is_empty() and not pa_live.is_empty():
        if pa_live.get(DataKeys.ACTION_TARGET_ID, -1) == CombatantEntityAccess.id_int(defender):
            var pa_mid: String = pa_live.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
            if pa_mid.is_empty() or pa_mid == move_id:
                pr_def = clampf(pr_def * _feint_readiness_reveal_mult(pa_live, attacker), 0.0, 1.0)
    return pr_def


## Tier 4.2 footwork / tempo: same curve as post-alignment **`parry_c_d`** stamina (**`STAMINA_AT_ZERO_PARRY_MULT`** +
## **`stamina_factor`**) applied to **readiness** (feint read-through, guard-zone, dodge telegraph). Not multiplied into
## **`pr_base`** in **`parry_c_d *= parry_capacity_mult * pr_base`** — avoids double-applying stamina to passive parry
## capacity.
static func _defender_passive_readiness_stamina_mult(tgt: Dictionary) -> float:
    return CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(CombatantEntityAccess.stamina_ratio(tgt))


## MXm-2: fight-duration exhaustion on readiness reporting (not folded into **`pr_base`** in **`parry_c_d`**).
static func _defender_passive_readiness_exhaustion_mult(tgt: Dictionary) -> float:
    return CombatConstants.defender_passive_readiness_exhaustion_mult(tgt)


static func _feint_guard_reads_real_line(tgt: Dictionary, parry_readiness: float, attacker_id: int = -1) -> bool:
    var sm: float = CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(tgt), "feint_readthrough", CombatantEntityAccess.get_weapon(tgt)
    )
    # A2: meisterhau_readthrough — extra bonus for defending against Liechtenauer decisive counter-strikes.
    var mh_rt: float = CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(tgt), "meisterhau_readthrough", CombatantEntityAccess.get_weapon(tgt)
    )
    if mh_rt > 1.0:
        sm *= lerpf(1.0, mh_rt, 0.4)
    if attacker_id >= 0:
        var cache_raw: Variant = tgt.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
        if cache_raw is Dictionary:
            var inferred: String = (cache_raw as Dictionary).get(str(attacker_id), "").strip_edges()
            sm += CombatWeaponForm.counter_readiness_nudge(
                CombatantEntityAccess.form_str(tgt), inferred, CombatantEntityAccess.get_weapon(tgt)
            )
    return parry_readiness * sm >= CombatConstants.FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD


## When **`pa.feint_part`** is set and defender does not read through the feint, **`dodge_eval_part`** may follow the
## telegraph (dodge --Abites--  on bait). **`pa[CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS]`** (**0..1**)
## overrides **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS`** for regression only; then **`distance_to[attacker]`** scales bias
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**). Read-through uses the same
## **`feint_guard_zone_readiness_spacing_mult`** as **`_guard_zone_modifier`** vs
## **`CombatantEntityAccess.id_int(atk)`** ( **`attacker_id` < 0** → MID / **1.0** ). **`attack_type_for_contact`**:
## incoming move id for stab/cut/blunt readiness scaling; if empty, uses **`pa["attack_type"]`**.
static func _apply_feint_telegraph_bias_to_dodge_eval_part(
    pa: Dictionary,
    tgt: Dictionary,
    atk: Dictionary,
    targetable: Array,
    result: Dictionary,
    attack_type_for_contact: String = ""
) -> void:
    if targetable.is_empty():
        return
    var fp: String = pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges()
    if fp.is_empty() or not targetable.has(fp):
        return
    var pr: float = PassiveParryContext.get_passive_parry_readiness(tgt)
    var atk_type_for_ct: String = attack_type_for_contact.strip_edges()
    if atk_type_for_ct.is_empty():
        atk_type_for_ct = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
    var ct_for_pr: String = ""
    if not atk_type_for_ct.is_empty():
        ct_for_pr = str(
            WeaponConstants.get_move(atk_type_for_ct).get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT)
        )
    pr *= CombatConstants.passive_parry_readiness_incoming_contact_mult(ct_for_pr)
    pr *= _defender_passive_readiness_stamina_mult(tgt)
    pr *= _defender_passive_readiness_exhaustion_mult(tgt)
    pr *= CombatAttention.focus_effective(tgt)
    pr *= CombatAttention.yomi_defense_readiness_mult(tgt, CombatantEntityAccess.id_int(atk))
    pr *= _feint_readiness_reveal_mult(pa, atk)
    pr *= CombatAttention.focus_line_mult_for_feint(tgt, pa)
    pr = clampf(pr, 0.0, 1.0)
    var pr_rt: float = clampf(
        pr * CombatConstants.feint_guard_zone_readiness_spacing_mult(tgt, CombatantEntityAccess.id_int(atk)), 0.0, 1.0
    )
    if _feint_guard_reads_real_line(tgt, pr_rt, CombatantEntityAccess.id_int(atk)):
        return
    var bias: float = CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS
    var ho: Variant = pa.get(CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS, -1.0)
    if ho is float or ho is int:
        var ob: float = float(ho)
        if ob >= 0.0:
            bias = clampf(ob, 0.0, 1.0)
    bias = clampf(bias * _feint_telegraph_dodge_spacing_mult(tgt, atk), 0.0, 1.0)
    if bias > 0.0 and randf() < bias:
        result.dodge_eval_part = fp


## Guard zone modifier: bonus when defender guards the hit part, penalty when unguarded (feint D).
## **`parry_readiness_for_feint`**: pass passive parry readiness from **`choose_defense`**; **`< 0`** skips feint
## read-through (harness compatibility / static calls). **`atk_id_for_feint_spacing`**: defender
## **`distance_to[atk_id]`** scales readiness only for read-through (**`-1`** = omit footwork, default).
static func _guard_zone_modifier(
    pa: Dictionary,
    tgt: Dictionary,
    targetable: Array,
    attack_type: String,
    parry_readiness_for_feint: float = -1.0,
    atk_id_for_feint_spacing: int = -1
) -> float:
    var gz: String = str(tgt.get(DataKeys.DEFENDER_GUARD_ZONE, "head"))
    if gz.is_empty():
        return 1.0
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var attack_line: String = move_def.get(DataKeys.PA_ATTACK_LINE, "high")
    var guard_line: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
    var intended: String = pa.get(DataKeys.ACTION_TARGET_PART, "")
    var expected_part: String = AttackPathResolver.resolve_hit_part(
        attack_line, guard_line, targetable, {}, intended, tgt
    )
    if expected_part.is_empty():
        return 1.0
    var feint_part: String = pa.get(DataKeys.ACTION_FEINT_PART, "")
    var gz_eval: String = gz
    var pr_fe_rt: float = parry_readiness_for_feint
    if atk_id_for_feint_spacing >= 0 and pr_fe_rt >= 0.0:
        pr_fe_rt = clampf(
            (
                parry_readiness_for_feint
                * CombatConstants.feint_guard_zone_readiness_spacing_mult(tgt, atk_id_for_feint_spacing)
            ),
            0.0,
            1.0
        )
    if (
        not feint_part.is_empty()
        and parry_readiness_for_feint >= 0.0
        and _feint_guard_reads_real_line(tgt, pr_fe_rt, atk_id_for_feint_spacing)
    ):
        gz_eval = expected_part
    if not feint_part.is_empty():
        var tele: String = str(tgt.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, feint_part))
        if tele.is_empty():
            tele = feint_part
        # Still aligned with wind-up telegraph while real line lands elsewhere → baited / wrong focus.
        if gz_eval == tele and expected_part != tele:
            return CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
    if expected_part == gz_eval:
        return CombatConstants.GUARD_ZONE_BONUS
    return CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY


## Velocity-based parry difficulty: faster attacks reduce effective parry capacity.
## Models the reality that high-speed strikes are harder to time/read, not just harder to stop.
## Low-intensity attacks (below threshold) are excluded to avoid penalizing deliberate/slow techniques.
static func _parry_velocity_difficulty_mult(attack_velocity_m_s: float, pa: Dictionary = {}) -> float:
    var intensity: float = float(pa.get(CombatConstants.PA_KEY_INTENSITY, 1.0))
    if intensity < CombatConstants.PARRY_VELOCITY_INTENSITY_MIN_THRESHOLD:
        return 1.0
    var ref: float = CombatConstants.PARRY_VELOCITY_DIFFICULTY_REF_M_S
    if attack_velocity_m_s <= ref:
        return 1.0
    var ratio: float = (attack_velocity_m_s - ref) / maxf(ref, 1.0)
    var penalty: float = clampf(
        ratio * CombatConstants.PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY / 2.0,
        0.0,
        CombatConstants.PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY
    )
    return 1.0 - penalty


## P4: Reach-based parry readiness bonus — longer weapons extend blade into attack trajectory earlier,
## effectively increasing the reactive window. Spear/polearm defenders gain ~8-15% more readiness than
## short weapons (dagger/short sword), reflecting HEMA "Langen-ort" distance control.
static func _reach_parry_readiness_bonus(def_weapon: Variant, atk_weapon: Variant) -> float:
    var def_len: float = 1.5
    if def_weapon != null and "melee_range" in def_weapon:
        def_len = maxf(0.0, float(def_weapon.melee_range))
    var atk_len: float = 1.5
    if atk_weapon != null and "melee_range" in atk_weapon:
        atk_len = maxf(0.0, float(atk_weapon.melee_range))
    ## Net reach advantage (defender length - attacker length). Positive = defender reaches further.
    ## Scale factor: 6% readiness bonus per meter of net reach advantage, capped at +0.15 (2.5m advantage).
    ## Baseline ~1.0m weapons (short sword) vs ~2.0m spear → +0.06 bonus; vs dagger ~0.4m → -0.036 penalty.
    var net_reach: float = def_len - atk_len
    return clampf(
        net_reach * CombatConstants.REACH_READINESS_SCALE_PER_M,
        -CombatConstants.REACH_READINESS_CAP,
        CombatConstants.REACH_READINESS_CAP
    )


## Positional feint: returns the open-line parry penalty when the defender's guard is still
## displaced on the given line from a feint that just landed, else 1.0. A circumscription (verwunden)
## carries a stronger stored mult (far side of the committed blade is more exposed than a same-line
## follow-up); plain feints fall back to the default FEINT_OPEN_LINE_PARRY_MULT.
## The penalty scales with the live open-line openness (eased time decay over the window) so the
## defender's parry capacity on that line recovers gradually instead of snapping back instantly.
static func _feint_open_line_parry_mult(tgt: Dictionary, incoming_line: String) -> float:
    if incoming_line.is_empty():
        return 1.0
    var open_line: String = str(tgt.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if open_line.is_empty():
        return 1.0
    if CombatGuardLines.normalize_line(open_line) != CombatGuardLines.normalize_line(incoming_line):
        return 1.0
    var openness: float = CombatGuardLines.open_line_openness(tgt)
    if openness <= 0.0:
        return 1.0
    var stored_mult: Variant = tgt.get(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT, null)
    if stored_mult != null:
        return lerpf(1.0, float(stored_mult), openness)
    return lerpf(1.0, CombatConstants.FEINT_OPEN_LINE_PARRY_MULT, openness)
