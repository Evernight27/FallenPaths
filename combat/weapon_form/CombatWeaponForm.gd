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
const FORM_DAGGER_HIGH := "high_hut"

## Per-fighter weapon form defs: temperament mods, move-family weights, pressure class, home guard, auto-switch.
## Read order: FORM_DEFS → normalize → seed → mod/action_weight_mult → pressure → evaluate_automatic_form.
## → evaluate_automatic_form.
## Canonical: CombatantEntityAccess.form_str · mod · action_weight_mult · home_guard_line · evaluate_automatic_form.
## Footing: assign_form → home guard_line only (LIVE_PATHS **`#wf-assign-form-contract`**); picker uses form
## weights only —" **`#wf-pick-vs-strike`**. Tier 4.4 PA: **`CombatFootwork`** —" hub **`#wf-tier-44-pa`**.
## **`#wf-footing-guards-stances`** · **`#wf-form-guard-pa-matrix`**.
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


## Live pressure tag for UI —" suppress **`controlling`** when the stamina gate is down.
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
## **`#wf-footing-improvement-backlog`** —" pairs with **`STANCE_MOD_OPPONENT_DISENGAGE`**.
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
    if move_id in ["zornhau", "scheitelhau", "krumphau", "schielhau"]:
        return "meisterhau"
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


static func stamina_cost_mult(form: String, weapon: Variant = null) -> float:
    var d: Dictionary = _def(form, weapon)
    return float(d.get("stamina_cost_mult", 1.0))


static func cooldown_modifiers(form: String, _move_id: String, weapon: Variant = null) -> Dictionary:
    var d: Dictionary = _def(form, weapon)
    var raw: Variant = d.get("cooldown_modifiers", {})
    if raw is Dictionary:
        return raw as Dictionary
    return {}


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


## Phase 2: count distinct signal types (line, move_id, contact_type, feint) that contribute
## to the score for a given form. Used by MIN_SIGNAL_AGREEMENT gate.
static func _signal_vote_count(form: String, entry: Dictionary, weapon: Variant = null) -> int:
    var sig: Dictionary = _def(form, weapon).get("signature", {}) as Dictionary
    if sig.is_empty() or entry.is_empty():
        return 0
    var votes: int = 0
    var move_sig: Dictionary = sig.get("move_ids", {}) as Dictionary
    var move_counts: Dictionary = entry.get("move_id_counts", {}) as Dictionary
    for mid in move_counts.keys():
        if move_sig.get(mid, 0.0) > 0.0 and int(move_counts[mid]) > 0:
            votes += 1
            break
    var ct_sig: Dictionary = sig.get("contact_types", {}) as Dictionary
    var ct_counts: Dictionary = entry.get("contact_type_counts", {}) as Dictionary
    for ct in ct_counts.keys():
        if ct_sig.get(ct, 0.0) > 0.0 and int(ct_counts[ct]) > 0:
            votes += 1
            break
    var line_sig: Dictionary = sig.get("lines", {}) as Dictionary
    var line_counts: Dictionary = entry.get("line_counts", {}) as Dictionary
    for ln in line_counts.keys():
        if line_sig.get(ln, 0.0) > 0.0 and int(line_counts[ln]) > 0:
            votes += 1
            break
    var feint_bias: float = sig.get("feint_bias", 0.0)
    var feint_n: int = entry.get("feint_resolved", 0)
    if feint_bias > 0.0 and feint_n > 0:
        votes += 1
    return votes


static func infer_opponent_form(manager: Node, observer: Dictionary, opponent_id: int) -> String:
    if observer == null or observer.is_empty() or opponent_id < 0:
        return ""
    if not _get_attention().enabled():
        return ""
    var entry: Dictionary = _get_attention().yomi_entry_for_attacker(observer, opponent_id)
    var total_obs: int = _get_attention().yomi_observation_total(entry)
    if total_obs < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_OBS:
        return ""
    var observer_form: String = CombatantEntityAccess.form_str(observer)
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
    if _signal_vote_count(best_form, entry, opp_weapon) < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_SIGNAL_AGREEMENT:
        return ""
    if _same_pressure_suppresses_inference(observer_form, best_form):
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


## Stance → pressure_class alias (harness compatibility). Production uses **`form_str`** +
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


## L2 → L3 home write site: sets **`weapon_form`**, stance alias (harness compatibility), home
## **`guard_line`** —" does **not** stamp/clear PA. Contract: LIVE_PATHS **`#wf-assign-form-contract`**.
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
                        "form_switch id=%d %s %s→%s reason=%s"
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


## Spawn path entry: resolve form from overlay → encounter → **`stance_preference`** →
## weapon default → **`assign_form(..., "spawn")`**. LIVE_PATHS **`#spawn→reset-path-wf-1a`**.
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


## WF-3 auto-switch hook — decision logic moved to **`CombatWeaponFormAutoSwitch`** (WF-3 module).
## Thin delegate so existing callers + the `CombatWeaponFormConst` preload keep working. Caller:
## **`CombatAIActionPicker.pick`** after mental-stack miss. LIVE_PATHS **`#wf-pick-vs-strike`** ·
## **`#wf-assign-form-contract`**.
static func evaluate_automatic_form(manager: Node, c: Dictionary) -> bool:
    return CombatWeaponFormAutoSwitch.evaluate_automatic_form(manager, c)


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
    for entry in history as Array:
        if entry is Dictionary and not entry.get("success", true):
            wrong += 1
    return wrong


## Phase 2: record the outcome of a counter-read. Appends to history and clears commitment on success.
static func record_counter_read_outcome(atk: Dictionary, target_id: int, success: bool, inferred_form: String) -> void:
    var history: Array = atk.get(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY, []) as Array
    (
        history
        . append(
            {
                "target_id": target_id,
                "success": success,
                "inferred_form": inferred_form,
            }
        )
    )
    if history.size() > CombatConstantsEncounter.COUNTER_READ_HISTORY_MAX_ENTRIES:
        history = history.slice(history.size() - CombatConstantsEncounter.COUNTER_READ_HISTORY_MAX_ENTRIES)
    atk[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY] = history
    if success:
        atk.erase(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL)


## WF-2b: form-inference confidence (0..1) based on observed attack count toward observer from target.
## Tiered model: 0 obs → 0; < LOW → LOW_CONF; < MED → MED_CONF; ≥ MED → HIGH_CONF.
static func get_form_inference_confidence(observer: Dictionary, target_id: int) -> float:
    var entry: Dictionary = CombatAttention._yomi_entry(observer, target_id)
    var counts: Dictionary = entry.get(DataKeys.ATTENTION_LINE_COUNTS, {}) as Dictionary
    var total: int = 0
    for line in counts:
        total += int(counts[line])
    if total == 0:
        return 0.0
    if total >= CombatConstantsEncounter.WF_YOMI_OBS_MED_THRESHOLD:
        return CombatConstantsEncounter.WF_YOMI_OBS_HIGH_CONFIDENCE
    if total >= CombatConstantsEncounter.WF_YOMI_OBS_LOW_THRESHOLD:
        return CombatConstantsEncounter.WF_YOMI_OBS_MED_CONFIDENCE
    return CombatConstantsEncounter.WF_YOMI_OBS_LOW_CONFIDENCE


## Phase 2: minimum inference confidence required to justify a counter-read form switch
## from one pressure class to another. Unknown or same-class transitions fall back to
## COUNTER_READ_MIN_CONFIDENCE_NO_OBSERVATIONS (the lowest bar).
static func _counter_read_min_confidence(from_pressure: String, to_pressure: String) -> float:
    var key: String = from_pressure.to_lower() + "_to_" + to_pressure.to_lower()
    var table: Dictionary = {
        "neutral_to_aggressive": CombatConstantsEncounter.COUNTER_READ_NEUTRAL_TO_AGGRESSIVE_MIN_CONFIDENCE,
        "aggressive_to_defensive": CombatConstantsEncounter.COUNTER_READ_AGGRESSIVE_TO_DEFENSIVE_MIN_CONFIDENCE,
        "neutral_to_controlling": CombatConstantsEncounter.COUNTER_READ_NEUTRAL_TO_CONTROLLING_MIN_CONFIDENCE,
        "neutral_to_defensive": CombatConstantsEncounter.COUNTER_READ_NEUTRAL_TO_DEFENSIVE_MIN_CONFIDENCE,
        "aggressive_to_controlling": CombatConstantsEncounter.COUNTER_READ_AGGRESSIVE_TO_CONTROLLING_MIN_CONFIDENCE,
        "controlling_to_aggressive": CombatConstantsEncounter.COUNTER_READ_CONTROLLING_TO_AGGRESSIVE_MIN_CONFIDENCE,
        "controlling_to_defensive": CombatConstantsEncounter.COUNTER_READ_CONTROLLING_TO_DEFENSIVE_MIN_CONFIDENCE,
        "controlling_to_neutral": CombatConstantsEncounter.COUNTER_READ_CONTROLLING_TO_NEUTRAL_MIN_CONFIDENCE,
        "aggressive_to_neutral": CombatConstantsEncounter.COUNTER_READ_AGGRESSIVE_TO_NEUTRAL_MIN_CONFIDENCE,
        "defensive_to_aggressive": CombatConstantsEncounter.COUNTER_READ_DEFENSIVE_TO_AGGRESSIVE_MIN_CONFIDENCE,
        "defensive_to_controlling": CombatConstantsEncounter.COUNTER_READ_DEFENSIVE_TO_CONTROLLING_MIN_CONFIDENCE,
        "defensive_to_neutral": CombatConstantsEncounter.COUNTER_READ_DEFENSIVE_TO_NEUTRAL_MIN_CONFIDENCE,
    }
    if table.has(key):
        return float(table[key])
    return CombatConstantsEncounter.COUNTER_READ_MIN_CONFIDENCE_NO_OBSERVATIONS


## Phase 2: gate for counter-read form switches. Returns true when inference confidence
## is sufficient to justify committing to the target form based on the opponent's read.
## Guards against thrashing on low-observation inferences, stale reads, and bait setups.
static func _counter_read_confidence_ok(
    manager: Node, c: Dictionary, target_id: int, target_form: String, weapon: Variant
) -> bool:
    if target_form.is_empty() or target_form == CombatantEntityAccess.form_str(c):
        return false
    if _is_form_stale_for_opponent(manager, c, target_id):
        return false
    var yomi_entry: Dictionary = CombatAttention._yomi_entry(c, target_id)
    if _is_entry_mixed_stale(yomi_entry, manager):
        return false
    if _should_bait_counter_read(manager, c, target_id):
        return false
    var conf: float = get_form_inference_confidence(c, target_id)
    var from_pressure: String = pressure_class(CombatantEntityAccess.form_str(c), weapon)
    var to_pressure: String = pressure_class(target_form, weapon)
    if from_pressure == to_pressure:
        conf *= CombatConstantsEncounter.COUNTER_READ_SAME_PRESSURE_BONUS
    var min_conf: float = _counter_read_min_confidence(from_pressure, to_pressure)
    return conf >= min_conf


## Phase 5: return true when the opponent's deception state suggests they are baiting a counter-read.
## When true, the fighter should resist auto-switching forms — the opponent is trying to draw them into
## a trap (Exploit phase with low resistance). Called from evaluate_automatic_form before counter-read
## auto-switch decisions. Returns false when opponent has no deception state or is not in Exploit phase.
static func _should_bait_counter_read(manager: Node, _c: Dictionary, opponent_id: int) -> bool:
    if manager == null or opponent_id < 0:
        return false
    var threat_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, opponent_id)
    if threat_c.is_empty():
        return false
    var attention := _get_attention()
    if not attention.has_method("should_respect_bait"):
        return false
    return attention.should_respect_bait(threat_c)


## Phase 2: true when inferred form for opponent is stale (recent line counts all zero).
static func _is_form_stale_for_opponent(_manager: Node, c: Dictionary, opponent_id: int) -> bool:
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


static func _is_entry_mixed_stale(entry: Dictionary, manager: Node) -> bool:
    if entry.is_empty() or manager == null:
        return false
    var current_tick: int = -1
    if manager.has_method("get_combat_tick_index"):
        current_tick = manager.get_combat_tick_index()
    elif "combat_tick_index" in manager:
        current_tick = int(manager.combat_tick_index)
    else:
        return false
    var stale_count: int = 0
    var fresh_count: int = 0
    var window: int = CombatConstants.WF_YOMI_STALENESS_RECENT_WINDOW
    var att := _get_attention()
    var line_ticks: Dictionary = entry.get(DataKeys.ATTENTION_LINE_OBS_TICKS, {}) as Dictionary
    for line_key in line_ticks:
        var lt: int = att.yomi_last_observed_line(entry, line_key)
        if lt < 0:
            continue
        if current_tick - lt >= window:
            stale_count += 1
        else:
            fresh_count += 1
    var move_ticks: Dictionary = entry.get(DataKeys.ATTENTION_MOVE_OBS_TICKS, {}) as Dictionary
    for move_key in move_ticks:
        var lt: int = att.yomi_last_observed_move(entry, move_key)
        if lt < 0:
            continue
        if current_tick - lt >= window:
            stale_count += 1
        else:
            fresh_count += 1
    var total_obs_for_entry: int = att.yomi_observation_total(entry)
    return stale_count > 0 and fresh_count > 0 and fresh_count * 2 < total_obs_for_entry


static func _same_pressure_suppresses_inference(observer_form: String, best_form: String) -> bool:
    if observer_form.is_empty() or best_form.is_empty():
        return false
    if observer_form == best_form:
        return true
    var obs_class: String = pressure_class(observer_form)
    var best_class: String = pressure_class(best_form)
    if obs_class == "aggressive" and best_class == "aggressive":
        return true
    if obs_class == "controlling" and best_class == "controlling":
        return true
    return false
