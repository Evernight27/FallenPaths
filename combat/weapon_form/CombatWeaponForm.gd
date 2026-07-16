class_name CombatWeaponForm
extends RefCounted
const FORM_OX := "ox"
const FORM_PLOW := "plow"
const FORM_WRATH := "wrath"
const FORM_FOOL := "fool"
const FORM_WALL := "wall"
const FORM_TEMPEST := "tempest"
const FORM_BALANCED := "balanced"

const FORM_AXE_DEMI := "demi_hache"
const FORM_AXE_BEC := "bec_point"
const FORM_AXE_QUEUE := "queue_bind"
const FORM_MACE_CROWN := "crown_guard"
const FORM_MACE_FLANK := "flank_guard"
const FORM_DAGGER_HIGH := "high_hut"
const FORM_DAGGER_LOW := "low_bind"
const FORM_DAGGER_REVERSE := "reverse_seize"
const FORM_SPEAR_IRON := "iron_gate"
const FORM_SPEAR_CROSS := "true_cross"
const FORM_SPEAR_PORT := "high_port"

## Per-fighter weapon form defs: temperament mods, move-family weights, pressure class, home guard, auto-switch.
## Read order: FORM_DEFS ÃƒÂ¢Ã¢Â€Â ' normalize ÃƒÂ¢Ã¢Â€Â ' seed ÃƒÂ¢Ã¢Â€Â ' mod/action_weight_mult ÃƒÂ¢Ã¢Â€Â ' pressure
## ÃƒÂ¢Ã¢Â€Â ' evaluate_automatic_form.
## Canonical: CombatantEntityAccess.form_str Â· mod Â· action_weight_mult Â· home_guard_line Â· evaluate_automatic_form.
## Footing: assign_form ÃƒÂ¢Ã¢Â€Â ' home guard_line only (LIVE_PATHS **`#wf-assign-form-contract`**); picker uses form
## weights only â€”" **`#wf-pick-vs-strike`**. Tier 4.4 PA: **`CombatFootwork`** â€”" hub **`#wf-tier-44-pa`**.
## **`#wf-footing-guards-stances`** Â· **`#wf-form-guard-pa-matrix`**.
## Manager requires: combatants, encounter, combat_clock (auto-switch cooldown only).

# Runtime preload — circular dependency (CombatAttention preloads CombatWeaponForm).
static var _attention_cache: Variant = null
static var _tactical_combat_cache: Variant = null

static var _form_defs_by_weapon: Dictionary = {}


static func _get_attention() -> GDScript:
    if _attention_cache == null:
        _attention_cache = load("res://combat/ai/CombatAttention.gd")
    return _attention_cache


# Runtime preload — circular dependency (CombatConstants → CombatConstantsStance → CombatWeaponForm → TacticalCombat).


static func _get_tactical_combat() -> GDScript:
    if CombatWeaponForm._tactical_combat_cache == null:
        CombatWeaponForm._tactical_combat_cache = load("res://combat/TacticalCombat.gd")
    return CombatWeaponForm._tactical_combat_cache


static func _ensure_defs() -> void:
    if not _form_defs_by_weapon.is_empty():
        return
    _form_defs_by_weapon = CombatWeaponFormDefs.build_all()


static func _weapon_key(weapon: Variant) -> String:
    if weapon is String:
        var sid: String = str(weapon).strip_edges().to_upper()
        if not sid.is_empty():
            return sid
    var wid: String = WeaponConstants.weapon_type_id(weapon)
    if wid.is_empty():
        return "SWORD"
    return wid


static func _neutral_mod() -> Dictionary:
    return {
        "parry": 1.0,
        "evasion": 1.0,
        "damage": 1.0,
        "close_attempt": 1.0,
        "ai_melee_focus": 1.0,
        "feint_readthrough": 1.0,
        "ai_feint_listing": 1.0,
    }


static func _def(form: String, weapon: Variant = null) -> Dictionary:
    _ensure_defs()
    var fid: String = _normalize_form_id(raw_form(form, weapon), weapon)
    var wid: String = _weapon_key(weapon) if weapon != null else ""
    if wid.is_empty():
        for wkey in _form_defs_by_weapon.keys():
            var bucket: Variant = _form_defs_by_weapon[wkey]
            if bucket is Dictionary and (bucket as Dictionary).has(fid):
                return (bucket as Dictionary)[fid] as Dictionary
        wid = "SWORD"
    var bucket2: Variant = _form_defs_by_weapon.get(wid, null)
    if bucket2 is not Dictionary:
        return (_form_defs_by_weapon.get("SWORD", {}) as Dictionary).get(FORM_BALANCED, {}) as Dictionary
    var defs: Dictionary = bucket2 as Dictionary
    if defs.has(fid):
        return defs[fid] as Dictionary
    return defs.get(FORM_BALANCED, {}) as Dictionary


static func raw_form(raw: String, weapon: Variant = null) -> String:
    var s: String = str(raw).strip_edges().to_lower()
    if s.is_empty():
        return FORM_BALANCED
    if weapon != null:
        s = WeaponConstants.resolve_form_legacy_alias(weapon, s)
    match s:
        "defensive":
            return FORM_WALL
        "aggressive":
            if weapon != null:
                return WeaponConstants.resolve_form_legacy_alias(weapon, "wrath")
            return FORM_WRATH
        "controlling":
            if weapon != null:
                return WeaponConstants.resolve_form_legacy_alias(weapon, "fool")
            return FORM_FOOL
        _:
            return s


static func _normalize_form_id(s: String, weapon: Variant = null) -> String:
    if s.is_empty():
        return FORM_BALANCED
    if weapon != null:
        var allowed: Array = WeaponConstants.allowed_forms_for_weapon(weapon)
        if not allowed.is_empty() and s not in allowed:
            return raw_form(WeaponConstants.default_form_for_weapon(weapon), weapon)
    return s


static func normalize_form(raw: String, weapon: Variant = null) -> String:
    return _normalize_form_id(raw_form(raw, weapon), weapon)


static func form_allowed_for_weapon(form: String, weapon: Variant) -> bool:
    var fid: String = raw_form(form, weapon)
    var allowed: Array = WeaponConstants.allowed_forms_for_weapon(weapon)
    return allowed.is_empty() or fid in allowed


static func default_form_for_weapon(weapon: Variant) -> String:
    return normalize_form(WeaponConstants.default_form_for_weapon(weapon), weapon)


static func home_guard_line(form: String, weapon: Variant = null) -> String:
    var d: Dictionary = _def(form, weapon)
    return str(d.get("home_guard", CombatConstants.GUARD_DEFAULT))


static func preferred_guards(form: String, weapon: Variant = null) -> PackedStringArray:
    var d: Dictionary = _def(form, weapon)
    var raw: Variant = d.get("preferred_guards", PackedStringArray())
    if raw is PackedStringArray:
        return raw
    return PackedStringArray()


## Stance limb bias for AI target pick (multiplies per-part weights; 1.0 = neutral).
static func target_part_weight_mult(
    form: String, part: String, form_prof_tier: float = -1.0, weapon: Variant = null
) -> float:
    var bias: Variant = _def(form, weapon).get("target_part_bias", {})
    var base: float = 1.0
    if bias is Dictionary:
        base = float((bias as Dictionary).get(part, 1.0))
    if base == 1.0:
        return 1.0
    if form_prof_tier < 0.0:
        return base
    return lerpf(1.0, base, 0.5 + clampf(form_prof_tier, 0.0, 1.0) * 0.5)


## Move-family limb bias (links Layer A occurrence posture to Layer B aim).
static func move_family_part_weight_mult(form: String, move_id: String, part: String, weapon: Variant = null) -> float:
    var family: String = _move_family_for_move_id(move_id)
    if family.is_empty():
        return 1.0
    var fam_bias: Variant = _def(form, weapon).get("move_family_part_bias", {})
    if fam_bias is not Dictionary:
        return 1.0
    var row: Variant = (fam_bias as Dictionary).get(family, null)
    if row is Dictionary:
        return float((row as Dictionary).get(part, 1.0))
    return 1.0


static func _form_ids_for_weapon(weapon: Variant) -> Array:
    _ensure_defs()
    var bucket: Variant = _form_defs_by_weapon.get(_weapon_key(weapon), null)
    if bucket is Dictionary:
        return (bucket as Dictionary).keys()
    return []


static func _defensive_form_for_weapon(weapon: Variant) -> String:
    if form_allowed_for_weapon(FORM_WALL, weapon):
        return FORM_WALL
    for fid in _form_ids_for_weapon(weapon):
        if pressure_class_is(str(fid), "defensive", weapon):
            return normalize_form(str(fid), weapon)
    return ""


static func _duel_offense_form_ids(weapon: Variant) -> PackedStringArray:
    _ensure_defs()
    var seen: Dictionary = {}
    var out: PackedStringArray = PackedStringArray()
    for fid in _form_ids_for_weapon(weapon):
        var row: Variant = _def(str(fid), weapon).get("duel_offense_forms", PackedStringArray())
        if row is PackedStringArray:
            for d in row:
                var s: String = str(d)
                if s.is_empty() or seen.has(s):
                    continue
                seen[s] = true
                out.append(s)
    return out


static func mod(form: String, effect: String, weapon: Variant = null) -> float:
    var d: Dictionary = _def(form, weapon)
    var m: Dictionary = d.get("mod", {}) as Dictionary
    return m.get(effect, 1.0)


static func display_name(form: String, weapon: Variant = null) -> String:
    return str(_def(form, weapon).get("display_name", "Balanced"))


static func form_ai_targeting_mult(actor: Dictionary) -> float:
    if actor.is_empty():
        return 1.0
    return mod(CombatantEntityAccess.form_str(actor), "ai_melee_focus", CombatantEntityAccess.get_weapon(actor))


static func pressure_class(form: String, weapon: Variant = null) -> String:
    return str(_def(form, weapon).get("pressure_class", "neutral"))


static func pressure_class_is(form: String, class_id: String, weapon: Variant = null) -> bool:
    return pressure_class(form, weapon) == str(class_id).strip_edges().to_lower()


static func controlling_pressure_active(c: Dictionary) -> bool:
    if c.is_empty():
        return false
    var weapon = CombatantEntityAccess.get_weapon(c)
    var form: String = CombatantEntityAccess.form_str(c)
    if not pressure_class_is(form, "controlling", weapon):
        return false
    return CombatantEntityAccess.stamina_ratio(c) >= CombatConstants.STANCE_MIN_STAMINA_CONTROLLING_RATIO


## Live pressure tag for UI â€”" suppress **`controlling`** when the stamina gate is down.
static func pressure_class_label_for_ui(c: Dictionary) -> String:
    if c.is_empty():
        return ""
    var pressure: String = pressure_class(CombatantEntityAccess.form_str(c), CombatantEntityAccess.get_weapon(c))
    if pressure.is_empty() or pressure == "neutral":
        return ""
    if pressure == "controlling" and not controlling_pressure_active(c):
        return ""
    return pressure


static func opponent_close_evasion_divisor(form: String) -> float:
    if pressure_class_is(form, "controlling"):
        return CombatConstants.STANCE_MOD_OPPONENT_CLOSE
    return 1.0


## Controlling pressure slows opponent formation disengage (fall_back / swap duration). LIVE_PATHS
## **`#wf-footing-improvement-backlog`** â€”" pairs with **`STANCE_MOD_OPPONENT_DISENGAGE`**.
static func opponent_disengage_pressure_mult(form: String) -> float:
    if pressure_class_is(form, "controlling"):
        return 1.0 / CombatConstants.STANCE_MOD_OPPONENT_DISENGAGE
    return 1.0


## AI **`attempt_close`** listing dampening vs controlling defender (mirrors resolve evasion divisor).
static func opponent_close_listing_weight_mult(form: String) -> float:
    if pressure_class_is(form, "controlling"):
        return CombatConstants.STANCE_MOD_OPPONENT_CLOSE
    return 1.0


static func opponent_close_listing_weight_mult_for_defender(c: Dictionary) -> float:
    if not controlling_pressure_active(c):
        return 1.0
    return opponent_close_listing_weight_mult(CombatantEntityAccess.form_str(c))


static func min_stamina_ratio_for_form(form: String, weapon: Variant = null) -> float:
    return _def(form, weapon).get("min_stamina_ratio", 0.22)


static func wait_action_weight_mult(form: String, weapon: Variant = null) -> float:
    return _def(form, weapon).get("wait_weight_mult", 1.0)


static func _move_family_for_move_id(move_id: String) -> String:
    if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        return "close"
    if WeaponConstants.is_feint_move(move_id):
        return "feint"
    if WeaponConstants.is_parry_move(move_id):
        return "parry"
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    if ct == WeaponConstants.ATTACK_TYPE_STAB:
        return "thrust"
    var md: Dictionary = WeaponConstants.get_move(move_id)
    var arch: String = md.get("archetype_id", "")
    var line: String = md.get("attack_line", "")
    if arch == WeaponConstants.ARCHETYPE_QUICK_SLASH or move_id == "slash" or move_id == "quick_slash":
        return "slash"
    if line.begins_with("low") or move_id == "unterhau":
        return "low_cut"
    if ct == WeaponConstants.ATTACK_TYPE_CUT or ct == WeaponConstants.ATTACK_TYPE_BLUNT:
        return "high_cut"
    return ""


static func action_weight_mult(form: String, move_id: String, weapon: Variant = null) -> float:
    var family: String = _move_family_for_move_id(move_id)
    if family.is_empty():
        return 1.0
    var d: Dictionary = _def(form, weapon)
    var fam: Dictionary = d.get("move_family_mult", {}) as Dictionary
    var base: float = fam.get(family, 1.0)
    var move_row: Variant = d.get("move_id_mult", {})
    if move_row is Dictionary:
        base *= float((move_row as Dictionary).get(move_id, 1.0))
    return base


static func wind_up_transition_mult(
    form: String, _move_id: String, guard_line: String, attack_line: String, weapon: Variant = null
) -> float:
    var home: String = home_guard_line(form, weapon)
    if home.is_empty() or attack_line.is_empty():
        return 1.0
    if guard_line == home and attack_line == home:
        return 0.88
    for pg in preferred_guards(form, weapon):
        if pg == attack_line and (guard_line == pg or guard_line == home):
            return 0.92
    return 1.0


static func _counter_spec_for_inferred(my_form: String, inferred_opp: String, weapon: Variant = null) -> Dictionary:
    var mine: String = normalize_form(my_form, weapon)
    var opp: String = str(inferred_opp).strip_edges().to_lower()
    if opp.is_empty():
        return {"mult": 1.0, "families": PackedStringArray()}
    var raw: Variant = (_def(mine, weapon).get("counters", {}) as Dictionary).get(opp, null)
    if raw is float or raw is int:
        return {"mult": float(raw), "families": PackedStringArray()}
    if raw is Dictionary:
        return {
            "mult": (raw as Dictionary).get("mult", 1.0),
            "families": _coerce_string_array((raw as Dictionary).get("families", [])),
        }
    return {"mult": 1.0, "families": PackedStringArray()}


static func _coerce_string_array(raw: Variant) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    if raw is PackedStringArray:
        return raw as PackedStringArray
    if raw is Array:
        for item in raw:
            var s: String = str(item).strip_edges()
            if not s.is_empty():
                out.append(s)
    return out


## WF-2b: picker boost when **`my_form`** counters inferred opponent habit for this **`move_id`** family.
static func form_counter_mult(
    my_form: String, inferred_opp_form: String, move_id: String, weapon: Variant = null
) -> float:
    if inferred_opp_form.is_empty() or move_id.is_empty():
        return 1.0
    var spec: Dictionary = _counter_spec_for_inferred(my_form, inferred_opp_form, weapon)
    var mult: float = spec.get("mult", 1.0)
    if mult <= 1.0:
        return 1.0
    var families: PackedStringArray = _coerce_string_array(spec.get("families", []))
    if not families.is_empty():
        var family: String = _move_family_for_move_id(move_id)
        if family.is_empty() or family not in families:
            return 1.0
    return minf(mult, CombatConstants.WF_FORM_COUNTER_MULT_CAP)


## WF-2b: optional defense bump when defender form counters inferred attacker form.
static func counter_readiness_nudge(my_form: String, inferred_opp_form: String, weapon: Variant = null) -> float:
    if inferred_opp_form.is_empty():
        return 0.0
    var mult: float = _counter_spec_for_inferred(my_form, inferred_opp_form, weapon).get("mult", 1.0)
    if mult <= 1.0:
        return 0.0
    var t: float = clampf((mult - 1.0) / maxf(0.001, CombatConstants.WF_FORM_COUNTER_MULT_CAP - 1.0), 0.0, 1.0)
    return lerpf(CombatConstants.WF_COUNTER_READINESS_NUDGE_MIN, CombatConstants.WF_COUNTER_READINESS_NUDGE_MAX, t)


static func _signature_score_for_entry(form: String, entry: Dictionary, weapon: Variant = null) -> float:
    var sig: Dictionary = _def(form, weapon).get("signature", {}) as Dictionary
    if sig.is_empty() or entry.is_empty():
        return 0.0
    var score: float = 0.0
    var move_sig: Dictionary = sig.get("move_ids", {}) as Dictionary
    var move_counts: Dictionary = entry.get("move_id_counts", {}) as Dictionary
    for mid in move_counts.keys():
        var w: float = move_sig.get(mid, 0.0)
        if w > 0.0:
            score += float(move_counts[mid]) * w
    var ct_sig: Dictionary = sig.get("contact_types", {}) as Dictionary
    var ct_counts: Dictionary = entry.get("contact_type_counts", {}) as Dictionary
    for ct in ct_counts.keys():
        var cw: float = ct_sig.get(ct, 0.0)
        if cw > 0.0:
            score += float(ct_counts[ct]) * cw
    var line_sig: Dictionary = sig.get("lines", {}) as Dictionary
    var line_counts: Dictionary = entry.get("line_counts", {}) as Dictionary
    for ln in line_counts.keys():
        var lw: float = line_sig.get(ln, 0.0)
        if lw > 0.0:
            score += float(line_counts[ln]) * lw
    var feint_bias: float = sig.get("feint_bias", 0.0)
    var feint_n: int = entry.get("feint_resolved", 0)
    if feint_bias > 0.0 and feint_n > 0:
        score += float(feint_n) * feint_bias
    return score


static func infer_opponent_form(manager: Node, observer: Dictionary, opponent_id: int) -> String:
    if observer == null or observer.is_empty() or opponent_id < 0:
        return ""
    if not _get_attention().enabled():
        return ""
    var entry: Dictionary = _get_attention().yomi_entry_for_attacker(observer, opponent_id)
    var total_obs: int = _get_attention().yomi_observation_total(entry)
    if total_obs < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_OBS:
        return ""
    var opp_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, opponent_id)
    var opp_weapon: Variant = CombatantEntityAccess.get_weapon(opp_c) if not opp_c.is_empty() else null
    _ensure_defs()
    var best_form: String = ""
    var best_score: float = -1.0
    var second_score: float = -1.0
    for entry_raw_form in _form_ids_for_weapon(opp_weapon):
        var fid: String = str(entry_raw_form)
        var s: float = _signature_score_for_entry(fid, entry, opp_weapon)
        if s > best_score:
            second_score = best_score
            best_score = s
            best_form = fid
        elif s > second_score:
            second_score = s
    if best_form.is_empty() or best_score <= 0.0:
        return ""
    if second_score < 0.0:
        second_score = 0.0
    if (best_score - second_score) < CombatConstants.WF_YOMI_FORM_INFERENCE_MARGIN:
        return ""
    return normalize_form(best_form, opp_weapon)


## WF-2a: cache inferred opponent forms on observer (waiting-tick refresh).
static func refresh_inferred_forms_for_observer(manager: Node, observer: Dictionary) -> void:
    if observer == null or observer.is_empty() or manager == null:
        return
    if not _get_attention().enabled():
        observer.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
        return
    var self_side: String = CombatantEntityAccess.side_str(observer)
    var cache: Dictionary = {}
    for other in manager.combatants:
        if other == null or other is not Dictionary:
            continue
        var oc: Dictionary = other
        if not CombatantEntityAccess.is_alive_in_combat(oc):
            continue
        if CombatantEntityAccess.side_str(oc) == self_side:
            continue
        var oid: int = CombatantEntityAccess.id_int(oc)
        if oid < 0:
            continue
        var inferred: String = infer_opponent_form(manager, observer, oid)
        if not inferred.is_empty():
            cache[str(oid)] = inferred
    if cache.is_empty():
        observer.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
    else:
        observer[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = cache


## Stance ÃƒÂ¢Ã¢Â€Â ' pressure_class alias (harness compatibility). Production uses **`form_str`** +
## **`CombatWeaponForm.mod`**.
static func _stance_alias_from_pressure(form: String, weapon: Variant = null) -> String:
    match pressure_class(form, weapon):
        "defensive":
            return CombatConstants.STANCE_DEFENSIVE
        "aggressive":
            return CombatConstants.STANCE_AGGRESSIVE
        "controlling":
            return CombatConstants.STANCE_CONTROLLING
        _:
            return CombatConstants.STANCE_BALANCED


static func _side_encounter_default_form(manager: Node, c: Dictionary) -> String:
    if manager == null or not ("encounter" in manager):
        return ""
    var enc: Dictionary = manager.encounter if manager.encounter is Dictionary else {}
    var side: String = CombatantEntityAccess.side_str(c)
    var key: String = (
        CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM
        if side == CombatConstants.SIDE_PLAYER
        else CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM
    )
    return str(enc.get(key, "")).strip_edges()


## L2 ÃƒÂ¢Ã¢Â€Â ' L3 home write site: sets **`weapon_form`**, stance alias (harness compatibility), home
## **`guard_line`** â€”" does **not** stamp/clear PA. Contract: LIVE_PATHS **`#wf-assign-form-contract`**.
static func assign_form(manager: Node, c: Dictionary, form: String, reason: String = "") -> void:
    var weapon = CombatantEntityAccess.get_weapon(c)
    var resolved: String = normalize_form(form, weapon)
    if not form_allowed_for_weapon(resolved, weapon):
        resolved = default_form_for_weapon(weapon)
    var old_form: String = CombatantEntityAccess.form_str(c)
    c[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = resolved
    c["stance"] = _stance_alias_from_pressure(resolved, weapon)
    if old_form != resolved and reason not in ["spawn", "harness_baseline"]:
        c[CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON] = reason
    GuardLineUpdater.set_guard_from_line(c, home_guard_line(resolved, weapon))
    if manager != null and not reason.is_empty() and CombatConstants.combat_event_debug_active():
        CombatDebug.flow_log(
            "form_switch id=%d form=%s reason=%s" % [CombatantEntityAccess.id_int(c), resolved, reason]
        )
    if (
        old_form != resolved
        and reason not in ["spawn", "harness_baseline"]
        and CombatConstants.WF_FORM_SWITCH_STAMINA_COST > 0.0
    ):
        c["stamina"] = maxf(0.0, CombatantEntityAccess.stamina_float(c) - CombatConstants.WF_FORM_SWITCH_STAMINA_COST)
    if manager != null and old_form != resolved and reason not in ["spawn", "harness_baseline"]:
        if OperationalLog.is_play_session_active():
            (
                OperationalLog
                . play_combat(
                    (
                        "form_switch id=%d %s %sÃƒÂ¢Ã¢Â€Â '%s reason=%s"
                        % [
                            CombatantEntityAccess.id_int(c),
                            CombatantEntityAccess.get_display_name(c, CombatantEntityAccess.id_int(c)),
                            old_form,
                            resolved,
                            reason,
                        ]
                    )
                )
            )


## Spawn path entry: resolve form from overlay ÃƒÂ¢Ã¢Â€Â ' encounter ÃƒÂ¢Ã¢Â€Â ' **`stance_preference`** ÃƒÂ¢Ã¢Â€Â '
## weapon default ÃƒÂ¢Ã¢Â€Â ' **`assign_form(..., "spawn")`**. LIVE_PATHS **`#spawn--reset-path-wf-1a`**.
static func seed_combatant_form(manager: Node, c: Dictionary, spawn_overlay: Dictionary = {}) -> void:
    var weapon = CombatantEntityAccess.get_weapon(c)
    var raw: String = spawn_overlay.get("weapon_form", "").strip_edges()
    if raw.is_empty():
        raw = _side_encounter_default_form(manager, c)
    if raw.is_empty():
        raw = c.get("stance_preference", "").strip_edges()
    var form: String
    if raw.is_empty():
        form = default_form_for_weapon(weapon)
    else:
        form = normalize_form(raw, weapon)
        if not form_allowed_for_weapon(form, weapon):
            form = default_form_for_weapon(weapon)
    assign_form(manager, c, form, "spawn")


static func _stamp_form_switch_cooldown(c: Dictionary, clk: float) -> void:
    c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL] = (clk + CombatConstants.WF_FORM_SWITCH_COOLDOWN_S)


static func _inferred_opponent_form(manager: Node, observer: Dictionary, opponent_id: int) -> String:
    if opponent_id < 0:
        return ""
    var cache_raw: Variant = observer.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
    if cache_raw is Dictionary:
        var cached: String = (cache_raw as Dictionary).get(str(opponent_id), "").strip_edges()
        if not cached.is_empty():
            return cached
    return infer_opponent_form(manager, observer, opponent_id)


static func _primary_melee_threat_id(manager: Node, c: Dictionary) -> int:
    if manager == null or c.is_empty():
        return -1
    var engaged: int = c.get("engaged_with_id", -1)
    if engaged >= 0:
        var engaged_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, engaged)
        if not engaged_c.is_empty() and CombatantEntityAccess.is_living_hostile_to(c, engaged_c):
            return engaged
    var sole_id: int = -1
    var count: int = 0
    for other in manager.combatants:
        if other == null or other is not Dictionary:
            continue
        var oc: Dictionary = other
        if not CombatantEntityAccess.is_living_hostile_to(c, oc):
            continue
        var pair_geom: Dictionary = CombatPairGeometry.effective_pair_geometry(manager, oc, c)
        if not CombatMeleeListing.can_melee_threaten(manager, oc, c, pair_geom):
            continue
        count += 1
        sole_id = CombatantEntityAccess.id_int(oc)
    if count == 1:
        return sole_id
    return -1


static func _is_isolated_duel(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var scan: Dictionary = CombatWeaponForm._get_tactical_combat().surround_threat_scan_for_defender(manager, c)
    if scan.get("count", 0) != 1:
        return false
    var wsum: float = scan.get("weight_sum", 0.0)
    if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD:
        return false
    if scan.get("arc_occupancy_blocked", 0) > 0:
        return false
    return _primary_melee_threat_id(manager, c) >= 0


static func _surround_pressure_high(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var scan: Dictionary = CombatWeaponForm._get_tactical_combat().surround_threat_scan_for_defender(manager, c)
    if scan.get("count", 0) >= 2:
        return true
    var wsum: float = scan.get("weight_sum", 0.0)
    return wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD


static func _surround_form_for_weapon(weapon: Variant) -> String:
    var wall: String = _defensive_form_for_weapon(weapon)
    if not wall.is_empty():
        return wall
    if form_allowed_for_weapon(FORM_TEMPEST, weapon):
        return FORM_TEMPEST
    for fid in _form_ids_for_weapon(weapon):
        if pressure_class_is(str(fid), "controlling", weapon):
            return normalize_form(str(fid), weapon)
    return ""


static func _preferred_aggressive_duel_form(weapon: Variant) -> String:
    for fid in _duel_offense_form_ids(weapon):
        if pressure_class_is(fid, "aggressive", weapon):
            return normalize_form(fid, weapon)
    var ids: PackedStringArray = _duel_offense_form_ids(weapon)
    if ids.size() > 0:
        return normalize_form(ids[0], weapon)
    return ""


static func _duel_demote_form(weapon: Variant, cur: String) -> String:
    for fid in _duel_offense_form_ids(weapon):
        if fid == cur:
            continue
        if not pressure_class_is(fid, "aggressive", weapon):
            return normalize_form(fid, weapon)
    return ""


static func _duel_form_from_yomi_and_stamina(
    cur: String, inferred: String, stamina_ratio: float, min_stamina: float, weapon: Variant = null
) -> String:
    var def_form: String = _defensive_form_for_weapon(weapon)
    var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
    var promote_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD
    var demote_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD
    if not def_form.is_empty() and cur == def_form and stamina_ratio < min_stamina + offense_pad:
        return ""
    if not inferred.is_empty():
        var counter: String = _duel_counter_form_vs_inferred(weapon, inferred)
        if not counter.is_empty() and counter != cur:
            return counter
    var agg: String = _preferred_aggressive_duel_form(weapon)
    if (
        not agg.is_empty()
        and stamina_ratio >= min_stamina + promote_pad
        and cur != agg
        and not pressure_class_is(cur, "aggressive", weapon)
    ):
        return agg
    if pressure_class_is(cur, "aggressive", weapon) and stamina_ratio < min_stamina + demote_pad:
        var demote: String = _duel_demote_form(weapon, cur)
        if not demote.is_empty() and demote != cur:
            return demote
    return ""


static func _counter_form_vs_inferred(weapon: Variant, inferred_opp: String) -> String:
    if inferred_opp.is_empty():
        return ""
    _ensure_defs()
    var best_form: String = ""
    var best_mult: float = 1.0
    for entry_raw_form in _form_ids_for_weapon(weapon):
        var fid: String = normalize_form(str(entry_raw_form), weapon)
        if not form_allowed_for_weapon(fid, weapon):
            continue
        var mult: float = _counter_spec_for_inferred(fid, inferred_opp, weapon).get("mult", 1.0)
        if mult > best_mult:
            best_mult = mult
            best_form = fid
    if best_mult <= 1.0 or best_form.is_empty():
        return ""
    return best_form


## Isolated duel: counter-read only among offensive duel forms (not wall/tempest).
static func _duel_counter_form_vs_inferred(weapon: Variant, inferred_opp: String) -> String:
    if inferred_opp.is_empty():
        return ""
    var best_form: String = ""
    var best_mult: float = 1.0
    for fid_raw in _duel_offense_form_ids(weapon):
        var fid: String = normalize_form(fid_raw, weapon)
        if not form_allowed_for_weapon(fid, weapon):
            continue
        var mult: float = _counter_spec_for_inferred(fid, inferred_opp, weapon).get("mult", 1.0)
        if mult > best_mult:
            best_mult = mult
            best_form = fid
    if best_mult <= 1.0 or best_form.is_empty():
        return ""
    return best_form


static func _try_assign_auto_switch(
    manager: Node, c: Dictionary, next_form: String, reason: String, clk: float
) -> bool:
    var next: String = next_form.strip_edges()
    if next.is_empty() or next == CombatantEntityAccess.form_str(c):
        return false
    var weapon = CombatantEntityAccess.get_weapon(c)
    if not form_allowed_for_weapon(next, weapon):
        return false
    assign_form(manager, c, next, reason)
    _stamp_form_switch_cooldown(c, clk)
    if reason == "counter_read":
        c[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL] = (
            clk + float(CombatConstantsEncounter.COUNTER_READ_COMMITMENT_DURATION_TICKS)
        )
    return true


## WF-3 auto-switch hook â€”" calls **`assign_form`** only; does **not** stamp/clear PA. Caller:
## **`CombatAIActionPicker.pick`** after mental-stack miss. LIVE_PATHS **`#wf-pick-vs-strike`** Â·
## **`#wf-assign-form-contract`**.
static func evaluate_automatic_form(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var clk: float = CombatantEntityAccess.combat_clock_float(manager)
    var until: float = float(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL, 0.0))
    if until > clk:
        return false
    var cur: String = CombatantEntityAccess.form_str(c)
    var ratio: float = CombatantEntityAccess.stamina_ratio(c)
    var weapon = CombatantEntityAccess.get_weapon(c)
    var min_r: float = min_stamina_ratio_for_form(cur, weapon)
    var def_form: String = _defensive_form_for_weapon(weapon)
    var envelop: bool = CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c))
    if ratio < min_r and not def_form.is_empty() and cur != def_form and not envelop:
        return _try_assign_auto_switch(manager, c, def_form, "low_stamina", clk)
    if not envelop:
        if _surround_pressure_high(manager, c):
            var sur_form: String = _surround_form_for_weapon(weapon)
            if _try_assign_auto_switch(manager, c, sur_form, "surround_pressure", clk):
                return true
    if CombatMobilityRetreat.cannot_commit_melee(c):
        return false
    if _is_isolated_duel(manager, c):
        var duel_id: int = _primary_melee_threat_id(manager, c)
        if duel_id >= 0:
            var inferred: String = _inferred_opponent_form(manager, c, duel_id)
            var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
            var can_offense: bool = not (not def_form.is_empty() and cur == def_form and ratio < min_r + offense_pad)
            if can_offense:
                var counter: String = _duel_counter_form_vs_inferred(weapon, inferred)
                if _try_assign_auto_switch(manager, c, counter, "counter_read", clk):
                    return true
            var duel_next: String = _duel_form_from_yomi_and_stamina(cur, inferred, ratio, min_r, weapon)
            if _try_assign_auto_switch(manager, c, duel_next, "duel_read", clk):
                return true
    var threat_id: int = _primary_melee_threat_id(manager, c)
    if threat_id >= 0:
        var offense_pad_fb: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
        if not (not def_form.is_empty() and cur == def_form and ratio < min_r + offense_pad_fb):
            var inferred_opp: String = _inferred_opponent_form(manager, c, threat_id)
            var counter: String = _counter_form_vs_inferred(weapon, inferred_opp)
            if _try_assign_auto_switch(manager, c, counter, "counter_read", clk):
                return true
    return false


## Phase 2: counter-read commitment — true while the attacker's auto-switch stamp has not expired.
static func is_counter_read_committed(atk: Dictionary, clock: float) -> bool:
    var until: float = float(atk.get(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL, -1.0))
    return until > clock


## Phase 2: count wrong readings in recent counter-read history.
static func count_recent_wrong_readings(atk: Dictionary) -> int:
    var history: Variant = atk.get(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY, null)
    if history is not Array:
        return 0
    var wrong: int = 0
    for entry in (history as Array):
        if entry is Dictionary and not entry.get("success", true):
            wrong += 1
    return wrong


## Phase 2: record the outcome of a counter-read. Appends to history and clears commitment on success.
static func record_counter_read_outcome(atk: Dictionary, target_id: int, success: bool, inferred_form: String) -> void:
    var history: Array = atk.get(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY, []) as Array
    history.append({
        "target_id": target_id,
        "success": success,
        "inferred_form": inferred_form,
    })
    if history.size() > CombatConstantsEncounter.COUNTER_READ_HISTORY_MAX_ENTRIES:
        history = history.slice(history.size() - CombatConstantsEncounter.COUNTER_READ_HISTORY_MAX_ENTRIES)
    atk[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY] = history
    if success:
        atk.erase(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL)


## WF-2b: form-inference confidence (0..1) based on observed attack count toward observer from target.
static func get_form_inference_confidence(observer: Dictionary, target_id: int) -> float:
    var entry: Dictionary = CombatAttention._yomi_entry(observer, target_id)
    var counts: Dictionary = entry.get(DataKeys.ATTENTION_LINE_COUNTS, {}) as Dictionary
    var total: int = 0
    for line in counts:
        total += int(counts[line])
    return clampf(float(total) / 10.0, 0.0, 1.0)


## Phase 2: true when inferred form for opponent is stale (recent line counts all zero).
static func _is_form_stale_for_opponent(manager: Node, c: Dictionary, opponent_id: int) -> bool:
    var entry: Dictionary = CombatAttention._yomi_entry(c, opponent_id)
    if entry.is_empty():
        return false
    var recent: Dictionary = entry.get(DataKeys.ATTENTION_RECENT_LINE_COUNTS, {}) as Dictionary
    if recent.is_empty():
        return false
    for line in recent:
        if int(recent[line]) > 0:
            return false
    return true
