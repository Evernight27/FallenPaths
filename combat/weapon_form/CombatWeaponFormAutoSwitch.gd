class_name CombatWeaponFormAutoSwitch
extends RefCounted

## WF-3 auto form switch, extracted from **`CombatWeaponForm`**: picks a defensive / surround /
## duel / counter-read form from stamina, surround pressure, and opponent form inference. Pure
## decision logic over the combatant dict + manager — no instance state. Shared form defs,
## normalize, pressure class, `assign_form`, cooldown stamp, inference, and counter-read confidence
## live in **`CombatWeaponForm`** (referenced via class_name; no circular preload).
## Entry: **`evaluate_automatic_form`** (LIVE_PATHS **`#wf-pick-vs-strike`** ·
## **`#wf-assign-form-contract`**). Caller: **`CombatAIActionPicker.pick`** after mental-stack miss.


## Primary melee threat id for `c` (engaged target, or the sole living hostile that can melee it).
## -1 when no single threat is identifiable.
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
    var count: int = scan.get("count", 0)
    if count >= 2:
        return true
    # Distance-weighted threat scoring — front-line threats (close range) count more than distant ones.
    var weighted_sum: float = _compute_weighted_threat_sum(manager, c, scan)
    return weighted_sum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD


static func _compute_weighted_threat_sum(manager: Node, defender: Dictionary, scan: Dictionary) -> float:
    if manager == null or defender.is_empty():
        return scan.get("weight_sum", 0.0)
    var weighted_sum: float = 0.0
    # Re-scan to get per-threat distance data (scan itself doesn't store distance bands).
    for other in manager.combatants:
        if other == null or not other is Dictionary:
            continue
        if not CombatantEntityAccess.is_living_hostile_to(defender, other):
            continue
        var pair_geom: Dictionary = CombatPairGeometry.effective_pair_geometry(manager, other, defender)
        if not CombatMeleeListing.can_melee_threaten(manager, other, defender, pair_geom):
            continue
        var eff_f: float = pair_geom.get(DataKeys.PAIR_FILE_SPACING_EQUIV, 0.0)
        var w: float = clampf(
            eff_f / maxf(0.001, CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN),
            CombatConstants.SURROUND_SECTOR_WEIGHT_MIN,
            1.0
        )
        # Distance-weighting — close-range threats create more urgent pressure.
        var dist_band: String = CombatantEntityAccess.distance_to_opponent_band(
            other, CombatantEntityAccess.id_int(defender)
        )
        if dist_band == "close":
            w *= 2.0
        elif dist_band == "mid":
            w *= 1.3
        else:
            w *= 0.6
        weighted_sum += w
    return weighted_sum


static func _surround_form_for_weapon(weapon: Variant) -> String:
    var wall: String = CombatWeaponForm._defensive_form_for_weapon(weapon)
    if not wall.is_empty():
        return wall
    if CombatWeaponForm.form_allowed_for_weapon(CombatWeaponForm.FORM_TEMPEST, weapon):
        return CombatWeaponForm.FORM_TEMPEST
    for fid in CombatWeaponForm._form_ids_for_weapon(weapon):
        if CombatWeaponForm.pressure_class_is(str(fid), "controlling", weapon):
            return CombatWeaponForm.normalize_form(str(fid), weapon)
    return ""


static func _preferred_aggressive_duel_form(weapon: Variant) -> String:
    for fid in CombatWeaponForm._duel_offense_form_ids(weapon):
        if CombatWeaponForm.pressure_class_is(fid, "aggressive", weapon):
            return CombatWeaponForm.normalize_form(fid, weapon)
    var ids: PackedStringArray = CombatWeaponForm._duel_offense_form_ids(weapon)
    if ids.size() > 0:
        return CombatWeaponForm.normalize_form(ids[0], weapon)
    return ""


static func _duel_demote_form(weapon: Variant, cur: String) -> String:
    for fid in CombatWeaponForm._duel_offense_form_ids(weapon):
        if fid == cur:
            continue
        if not CombatWeaponForm.pressure_class_is(fid, "aggressive", weapon):
            return CombatWeaponForm.normalize_form(fid, weapon)
    return ""


static func _duel_form_from_yomi_and_stamina(
    cur: String, inferred: String, stamina_ratio: float, min_stamina: float, weapon: Variant = null
) -> String:
    var def_form: String = CombatWeaponForm._defensive_form_for_weapon(weapon)
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
        and not CombatWeaponForm.pressure_class_is(cur, "aggressive", weapon)
    ):
        return agg
    if CombatWeaponForm.pressure_class_is(cur, "aggressive", weapon) and stamina_ratio < min_stamina + demote_pad:
        var demote: String = _duel_demote_form(weapon, cur)
        if not demote.is_empty() and demote != cur:
            return demote
    return ""


static func _counter_form_vs_inferred(weapon: Variant, inferred_opp: String) -> String:
    if inferred_opp.is_empty():
        return ""
    CombatWeaponForm._ensure_defs()
    var best_form: String = ""
    var best_mult: float = 1.0
    for entry_raw_form in CombatWeaponForm._form_ids_for_weapon(weapon):
        var fid: String = CombatWeaponForm.normalize_form(str(entry_raw_form), weapon)
        if not CombatWeaponForm.form_allowed_for_weapon(fid, weapon):
            continue
        var mult: float = CombatWeaponForm._counter_spec_for_inferred(fid, inferred_opp, weapon).get("mult", 1.0)
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
    for fid_raw in CombatWeaponForm._duel_offense_form_ids(weapon):
        var fid: String = CombatWeaponForm.normalize_form(fid_raw, weapon)
        if not CombatWeaponForm.form_allowed_for_weapon(fid, weapon):
            continue
        var mult: float = CombatWeaponForm._counter_spec_for_inferred(fid, inferred_opp, weapon).get("mult", 1.0)
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
    if not CombatWeaponForm.form_allowed_for_weapon(next, weapon):
        return false
    CombatWeaponForm.assign_form(manager, c, next, reason)
    CombatWeaponForm._stamp_form_switch_cooldown(c, clk)
    if reason == "counter_read":
        c[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL] = (
            clk + float(CombatConstantsEncounter.COUNTER_READ_COMMITMENT_DURATION_TICKS)
        )
    return true


## WF-3 auto-switch hook — calls **`assign_form`** only; does **not** stamp/clear PA. Caller:
## **`CombatAIActionPicker.pick`** after mental-stack miss. LIVE_PATHS **`#wf-pick-vs-strike`** ·
## **`#wf-assign-form-contract`**.
static func evaluate_automatic_form(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var clk: float = CombatantEntityAccess.combat_clock_float(manager)
    var until: float = float(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL, 0.0))
    # Per-entity response delay — prevents all entities from switching simultaneously under surround pressure.
    var entity_jitter: float = fmod(hash(str(c.id)), 30) / 100.0  # 0-0.3s stagger
    if until - entity_jitter > clk:
        return false
    var cur: String = CombatantEntityAccess.form_str(c)
    var ratio: float = CombatantEntityAccess.stamina_ratio(c)
    var weapon = CombatantEntityAccess.get_weapon(c)
    var min_r: float = CombatWeaponForm.min_stamina_ratio_for_form(cur, weapon)
    var def_form: String = CombatWeaponForm._defensive_form_for_weapon(weapon)
    # Hysteresis: defensive form exit threshold is lower than enter threshold to prevent thrashing.
    var hysteresis_pad: float = CombatConstantsEncounter.WF_STAMINA_HYSTERESIS_PAD if cur == def_form else 0.0
    var min_r_effective: float = min_r + hysteresis_pad
    var envelop: bool = CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c))
    if ratio < min_r and not def_form.is_empty() and cur != def_form and not envelop:
        return _try_assign_auto_switch(manager, c, def_form, "low_stamina", clk)
    if not envelop:
        if _surround_pressure_high(manager, c):
            var sur_form: String = _surround_form_for_weapon(weapon)
            if not sur_form.is_empty() and _try_assign_auto_switch(manager, c, sur_form, "surround_pressure", clk):
                return true
    if CombatMobilityRetreat.cannot_commit_melee(c):
        return false
    if _is_isolated_duel(manager, c):
        var duel_id: int = _primary_melee_threat_id(manager, c)
        if duel_id >= 0:
            var inferred: String = CombatWeaponForm._inferred_opponent_form(manager, c, duel_id)
            if inferred.is_empty():
                return false
            var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
            var can_offense: bool = not (
                not def_form.is_empty() and cur == def_form and ratio < min_r_effective + offense_pad
            )
            if can_offense:
                var counter: String = _duel_counter_form_vs_inferred(weapon, inferred)
                if (
                    CombatWeaponForm._counter_read_confidence_ok(manager, c, duel_id, counter, weapon)
                    and _try_assign_auto_switch(manager, c, counter, "counter_read", clk)
                ):
                    return true
            var duel_next: String = _duel_form_from_yomi_and_stamina(cur, inferred, ratio, min_r, weapon)
            if _try_assign_auto_switch(manager, c, duel_next, "duel_read", clk):
                return true
    var threat_id: int = _primary_melee_threat_id(manager, c)
    if threat_id >= 0:
        var offense_pad_fb: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
        if not (not def_form.is_empty() and cur == def_form and ratio < min_r_effective + offense_pad_fb):
            var inferred_opp: String = CombatWeaponForm._inferred_opponent_form(manager, c, threat_id)
            var counter: String = _counter_form_vs_inferred(weapon, inferred_opp)
            if (
                CombatWeaponForm._counter_read_confidence_ok(manager, c, threat_id, counter, weapon)
                and _try_assign_auto_switch(manager, c, counter, "counter_read", clk)
            ):
                return true
    return false
