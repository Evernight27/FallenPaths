class_name KinematicDeliveryStaminaFormationTests
extends CombatRegressionHarnessCore
## Tier 5.1 (optional long-tail): **`strike_mods.strike_energy_mult`** in **`compute_and_apply_damage`**  -
## **`strike_ke_j`** * mult; **`pre_cut`** * **`sqrt(mult)`**; **`penetration_sharp`** * **`mult^PENETRATION_EXPONENT`**
## -  cut swings.


static func _run_kinematic_delivery_strike_energy_mult_integration_pre_cut_not_pen(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.45
    var want_pen: float = pow(mult, WeaponConstants.PENETRATION_EXPONENT)
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"strike_energy_mult": mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        var ke_ratio: float = float(shaped["strike_ke_j"]) / maxf(float(base["strike_ke_j"]), 0.001)
        var cut_ratio: float = float(shaped["pre_cut"]) / maxf(float(base["pre_cut"]), 0.001)
        var pen_ratio: float = float(shaped["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
        if absf(ke_ratio - mult) > 0.03:
            _fail(failures, "%s: kin_energy_mult_int ke ratio %.4f want %.4f" % [tag, ke_ratio, mult])
        if absf(cut_ratio - sqrt(mult)) > 0.05:
            _fail(
                failures,
                "%s: kin_energy_mult_int pre_cut ratio %.4f want sqrt(mult) %.4f" % [tag, cut_ratio, sqrt(mult)]
            )
        if absf(pen_ratio - want_pen) > 0.06:
            _fail(failures, "%s: kin_energy_mult_int pen ratio %.4f want mult^exp %.4f" % [tag, pen_ratio, want_pen])


## Tier 5.1 (optional long-tail): **`afterblow_damage_mult`** scales assembled **`v`** (sqrt) ->
## **`strike_ke_j_applied`** (~linear in mult)  -  cut swings, thrust, blunt.


## Tier 5.1 (optional long-tail): **`afterblow_damage_mult`** scales assembled **`v`** (sqrt) ->
## **`strike_ke_j_applied`** (~linear in mult)  -  cut swings, thrust, blunt.
static func _run_kinematic_delivery_afterblow_mult_scales_strike_ke_via_velocity(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var ab_mult: float = 0.64
    var want_ke: float = ab_mult
    var fixtures: Array = _kin_fixtures_all_damage()
    for cfx in fixtures:
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var clean: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var hindered: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, ab_mult, arch)
        _free_manager(clean["mgr"] as Node)
        _free_manager(hindered["mgr"] as Node)
        var ke_ratio: float = float(hindered["strike_ke_j"]) / maxf(float(clean["strike_ke_j"]), 0.001)
        if absf(ke_ratio - want_ke) > 0.06:
            _fail(
                failures,
                (
                    "%s: kin_afterblow ke ratio %.4f want ~%.4f (clean=%.2f hindered=%.2f)"
                    % [tag, ke_ratio, want_ke, float(clean["strike_ke_j"]), float(hindered["strike_ke_j"])]
                )
            )


## Tier 5.1 (optional long-tail): **`angle_to_nearest_line`** quadrant boundaries at **45deg / 135deg / 225deg /
## 315deg**.


## Tier 5.1 (optional long-tail): **`angle_to_nearest_line`** quadrant boundaries at **45deg / 135deg / 225deg /
## 315deg**.
static func _run_kinematic_delivery_angle_to_nearest_line_boundaries(failures: PackedStringArray) -> void:
    if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        var oct: Array = [
            [0.0, _GuardLines.LINE_HIGH],
            [45.0, _GuardLines.LINE_HIGH_RIGHT],
            [90.0, _GuardLines.LINE_RIGHT],
            [135.0, _GuardLines.LINE_LOW_RIGHT],
            [180.0, _GuardLines.LINE_LOW],
            [225.0, _GuardLines.LINE_LOW_LEFT],
            [270.0, _GuardLines.LINE_LEFT],
            [315.0, _GuardLines.LINE_HIGH_LEFT],
        ]
        for pair in oct:
            var got: String = CombatConstants.angle_to_nearest_line(float(pair[0]))
            if got != str(pair[1]):
                _fail(failures, "kin_line_bound: %.1fdeg want %s got %s" % [float(pair[0]), str(pair[1]), got])
        return
    if CombatConstants.angle_to_nearest_line(44.9) != "high":
        _fail(failures, "kin_line_bound: 44.9deg want high")
    if CombatConstants.angle_to_nearest_line(45.0) != "right":
        _fail(failures, "kin_line_bound: 45.0deg want right")
    if CombatConstants.angle_to_nearest_line(134.9) != "right":
        _fail(failures, "kin_line_bound: 134.9deg want right")
    if CombatConstants.angle_to_nearest_line(135.0) != "low":
        _fail(failures, "kin_line_bound: 135.0deg want low")
    if CombatConstants.angle_to_nearest_line(224.9) != "low":
        _fail(failures, "kin_line_bound: 224.9deg want low")
    if CombatConstants.angle_to_nearest_line(225.0) != "left":
        _fail(failures, "kin_line_bound: 225.0deg want left")
    if CombatConstants.angle_to_nearest_line(314.9) != "left":
        _fail(failures, "kin_line_bound: 314.9deg want left")
    if CombatConstants.angle_to_nearest_line(315.0) != "high":
        _fail(failures, "kin_line_bound: 315.0deg want high")


static func _harness_destroy_limb(entity: CoreEntity, part: String) -> void:
    _Fixtures._harness_destroy_limb(entity, part)


static func _harness_restore_limb(entity: CoreEntity, part: String) -> void:
    _Fixtures._harness_restore_limb(entity, part)


## Tier 6.1: cumulative effective pain scales pain-shock **chance** (0.8- -  - 1.2- - ); hit pain remains primary.


## Tier 6.1: cumulative effective pain scales pain-shock **chance** (0.8- -  - 1.2- - ); hit pain remains primary.
static func _run_medical_pain_shock_susceptibility_mult_from_effective_pain(failures: PackedStringArray) -> void:
    var low: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(3.0)
    var at_first: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(
        PainConsciousnessConstants.NRS_FIRST_EFFECT
    )
    var mid: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(6.0)
    var high: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(9.0)
    if absf(low - 0.8) > 0.0001 or absf(at_first - 0.8) > 0.0001:
        _fail(failures, "med_shock_sus: low pain want 0.8 got low=%.3f first=%.3f" % [low, at_first])
    if absf(high - 1.2) > 0.0001:
        _fail(failures, "med_shock_sus: high pain want 1.2 got %.3f" % high)
    if mid <= 0.8 or mid >= 1.2:
        _fail(failures, "med_shock_sus: mid pain want between 0.8 and 1.2 got %.3f" % mid)


## Tier 6.1: sustained high pain can enter pain shock on combat ticks (ambient roll).


## Tier 6.1: sustained high pain can enter pain shock on combat ticks (ambient roll).
static func _run_medical_ambient_pain_shock_tick_enters_from_sustained_pain(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ambient_pain_shock(true)
    var ent: Node = _new_entity("SWORD")
    ent.take_damage_split(20.0, 20.0, "chest")
    ent._pain_shock_until_time = -1.0
    ent._ambient_pain_shock_accum = 0.0
    var pain: float = ent._get_effective_pain_for_thresholds()
    if pain <= PainConsciousnessConstants.NRS_SHOCK + 0.5:
        _fail(failures, "ambient_shock: need high effective pain got %.2f" % pain)
        _free_harness_node(ent)
        return
    var entered: bool = false
    var interval: float = PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    ent._ambient_pain_shock_accum = interval - 0.001
    for _i in 80:
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
            entered = true
            break
        ent._ambient_pain_shock_accum = interval - 0.001
    if not entered:
        _fail(failures, "ambient_shock: want shock from sustained pain (pain=%.2f)" % pain)
    _free_harness_node(ent)


## Tier 6.1: ambient pain shock gated by **`FEATURE_AMBIENT_PAIN_SHOCK`**.


## Tier 6.1: ambient pain shock gated by **`FEATURE_AMBIENT_PAIN_SHOCK`**.
static func _run_medical_ambient_pain_shock_skips_when_feature_off(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ambient_pain_shock(false)
    var ent: Node = _new_entity("SWORD")
    ent.take_damage_split(20.0, 20.0, "chest")
    ent._pain_shock_until_time = -1.0
    for _i in 40:
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 2.0):
            _fail(failures, "ambient_shock_off: should not enter shock when feature off")
            CombatConstants.set_feature_ambient_pain_shock(true)
            _free_harness_node(ent)
            return
    CombatConstants.set_feature_ambient_pain_shock(true)
    _free_harness_node(ent)


static func _run_campaign_bridge_can_enter_combat_rejects_empty_party(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var pm: Node = _PartyManagerScript.new()
    world.set_meta("party_manager", pm)
    var ready: Dictionary = _CampaignBridge.can_enter_combat(world)
    world.free()
    pm.free()
    if bool(ready.get("ok", true)):
        _fail(failures, "bridge_enter: empty party should not be ok")
    if not str(ready.get("message", "")).contains("No living"):
        _fail(failures, "bridge_enter: want no living party message got '%s'" % str(ready.get("message")))


static func _run_campaign_bridge_can_enter_combat_rejects_unconscious(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var pm: Node = _PartyManagerScript.new()
    var ent: CoreEntity = _new_entity("SWORD")
    ent.name = "UnconsciousFighter"
    ent.consciousness = 0.0
    ent.effective_consciousness = 0.0
    ent._consciousness_dirty = false
    pm.add_member(ent)
    world.set_meta("party_manager", pm)
    var ready: Dictionary = _CampaignBridge.can_enter_combat(world)
    world.free()
    _free_harness_node(ent)
    pm.free()
    if bool(ready.get("ok", true)):
        _fail(failures, "bridge_enter: unconscious member should block combat")
    if not str(ready.get("message", "")).contains("unconscious"):
        _fail(failures, "bridge_enter: want unconscious message got '%s'" % str(ready.get("message")))


static func _run_weapon_blade_strong_fraction(failures: PackedStringArray) -> void:
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    var dagger: Weapon = _Weapon.create_from_definition("DAGGER")
    var spear: Weapon = _Weapon.create_from_definition("SPEAR")
    if sword == null or dagger == null or spear == null:
        _fail(failures, "weapon_strong_fraction: missing sword/dagger/spear")
        return
    var sword_want: float = 30.0 / 120.0
    var dagger_want: float = 12.0 / 32.0
    if absf(sword.get_parry_strong_fraction() - sword_want) > 0.001:
        _fail(
            failures, "weapon_strong_fraction: sword %.3f want %.3f" % [sword.get_parry_strong_fraction(), sword_want]
        )
    if absf(dagger.get_parry_strong_fraction() - dagger_want) > 0.001:
        _fail(
            failures,
            "weapon_strong_fraction: dagger %.3f want %.3f" % [dagger.get_parry_strong_fraction(), dagger_want]
        )
    if absf(spear.get_parry_strong_fraction() - 0.25) > 0.001:
        _fail(failures, "weapon_strong_fraction: non-blade spear should use neutral 0.25")


## Tier 3.2: bind-riposte contact sets are normalized, deduped, and data-driven per weapon.


## Tier 3.2: bind-riposte contact sets are normalized, deduped, and data-driven per weapon.
static func _run_bind_riposte_contact_types_normalized(failures: PackedStringArray) -> void:
    var valid: Dictionary = {
        WeaponConstants.ATTACK_TYPE_STAB: true,
        WeaponConstants.ATTACK_TYPE_CUT: true,
        WeaponConstants.ATTACK_TYPE_BLUNT: true
    }
    var expected: Dictionary = {
        "SWORD": [WeaponConstants.ATTACK_TYPE_STAB, WeaponConstants.ATTACK_TYPE_CUT],
        "AXE": [WeaponConstants.ATTACK_TYPE_CUT, WeaponConstants.ATTACK_TYPE_STAB],
        "MACE": [WeaponConstants.ATTACK_TYPE_BLUNT],
        "DAGGER": [WeaponConstants.ATTACK_TYPE_STAB],
        "SPEAR": [WeaponConstants.ATTACK_TYPE_STAB]
    }
    for wid in expected.keys():
        var weapon: Weapon = _Weapon.create_from_definition(str(wid))
        if weapon == null:
            _fail(failures, "bind_contacts: missing weapon %s" % str(wid))
            continue
        var seen: Dictionary = {}
        for raw_ct in weapon.bind_riposte_contact_types:
            var ct: String = str(raw_ct)
            if not valid.get(ct, false):
                _fail(failures, "bind_contacts: %s invalid contact %s" % [str(wid), ct])
            if seen.get(ct, false):
                _fail(failures, "bind_contacts: %s duplicate contact %s" % [str(wid), ct])
            seen[ct] = true
        if weapon.bind_riposte_contact_types != expected[wid]:
            _fail(
                failures,
                (
                    "bind_contacts: %s got %s want %s"
                    % [str(wid), str(weapon.bind_riposte_contact_types), str(expected[wid])]
                )
            )


## Tier 7: attack stamina cost rises with wind-up intensity.


## Tier 7: attack stamina cost rises with wind-up intensity.
static func _run_tier7_stamina_attack_cost_scales_with_intensity(failures: PackedStringArray) -> void:
    var light: float = CombatConstants.stamina_attack_cost_from_intensity(0.0)
    var heavy: float = CombatConstants.stamina_attack_cost_from_intensity(1.0)
    if not is_equal_approx(light, CombatConstants.STAMINA_ATTACK_COST_BASE):
        _fail(failures, "tier7_stam_cost: light want %.1f got %.1f" % [CombatConstants.STAMINA_ATTACK_COST_BASE, light])
    var want_heavy: float = CombatConstants.STAMINA_ATTACK_COST_BASE + CombatConstants.STAMINA_ATTACK_COST_SCALE
    if not is_equal_approx(heavy, want_heavy):
        _fail(failures, "tier7_stam_cost: heavy want %.1f got %.1f" % [want_heavy, heavy])


## Tier 7: parry stamina cost scales with incoming strike intensity (mirrors attack curve).


## Tier 7: parry stamina cost scales with incoming strike intensity (mirrors attack curve).
static func _run_tier7_stamina_parry_cost_scales_with_intensity(failures: PackedStringArray) -> void:
    var light: float = CombatConstants.stamina_parry_cost_from_intensity(0.0)
    var heavy: float = CombatConstants.stamina_parry_cost_from_intensity(1.0)
    if not is_equal_approx(light, CombatConstants.STAMINA_PARRY_COST_BASE):
        _fail(failures, "tier7_parry_stam: light want %.1f got %.1f" % [CombatConstants.STAMINA_PARRY_COST_BASE, light])
    var want_heavy: float = CombatConstants.STAMINA_PARRY_COST_BASE + CombatConstants.STAMINA_PARRY_COST_SCALE
    if not is_equal_approx(heavy, want_heavy):
        _fail(failures, "tier7_parry_stam: heavy want %.1f got %.1f" % [want_heavy, heavy])
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = _EntityAccess.id_int(defender)
    var e_id: int = _EntityAccess.id_int(attacker)
    defender["stamina"] = CombatConstants.STAMINA_MAX
    attacker["pending_attack"] = {"attack_type": "oberhau", "effective_attack_line": "high", "intensity": 1.0}
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.5, "kinematic_delivery": "cut"},
            }
        )
    )
    var spent: float = CombatConstants.STAMINA_MAX - _EntityAccess.stamina_float(defender)
    if not is_equal_approx(spent, want_heavy):
        _fail(failures, "tier7_parry_stam: heavy parry want spend %.1f got %.1f" % [want_heavy, spent])
    _free_manager(mgr)


## Tier 7.2: five heavy attacks without refill exhaust the stamina pool.


## Tier 7.2: five heavy attacks without refill exhaust the stamina pool.
static func _run_tier7_stamina_depletion_five_heavy_attacks_exhaust_pool(failures: PackedStringArray) -> void:
    var cost_heavy: float = CombatConstants.stamina_attack_cost_from_intensity(1.0)
    var stamina_left: float = CombatConstants.STAMINA_MAX
    for _i in 5:
        stamina_left = maxf(0.0, stamina_left - cost_heavy)
    if stamina_left > 0.01:
        _fail(failures, "tier7_stam_deplete: five heavy attacks should exhaust pool, left %.2f" % stamina_left)
    if CombatConstants.STAMINA_REFILL_RATE > 5.5:
        _fail(
            failures,
            "tier7_stam_deplete: refill rate %.2f too high for 7.2 pacing target" % CombatConstants.STAMINA_REFILL_RATE
        )


## Tier 7.2: sustained exchange (~2 min) with attack every 3s + idle refill should leave combatant fatigued.


## Tier 7.2: sustained exchange (~2 min) with attack every 3s + idle refill should leave combatant fatigued.
static func _run_tier7_stamina_depletion_sustained_exchange_sim(failures: PackedStringArray) -> void:
    var stamina: float = CombatConstants.STAMINA_MAX
    var attack_cost: float = CombatConstants.stamina_attack_cost_from_intensity(0.85)
    var dt: float = 0.1
    var elapsed: float = 0.0
    var next_attack: float = 0.0
    while elapsed < 120.0:
        if elapsed >= next_attack - 0.001:
            stamina = maxf(0.0, stamina - attack_cost)
            next_attack += 3.0
        else:
            stamina = minf(CombatConstants.STAMINA_MAX, stamina + CombatConstants.STAMINA_REFILL_RATE * dt)
        elapsed += dt
    if stamina > CombatConstants.STAMINA_MAX * 0.35:
        _fail(failures, "tier7_stam_deplete_sim: after 120s intense exchange want <=35%% stamina got %.1f" % stamina)


## MXm-3: central fatigue + hypovolemia cap burst pool ceiling.


## MXm-3: central fatigue + hypovolemia cap burst pool ceiling.
static func _run_stamina_effective_max_exhaustion_and_blood_cap(failures: PackedStringArray) -> void:
    var fresh: Dictionary = {
        "stamina": CombatConstants.STAMINA_MAX,
        "stats": {"blood_volume": 100.0},
        CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.0,
    }
    if not is_equal_approx(CombatExhaustion.effective_stamina_max(fresh), CombatConstants.STAMINA_MAX):
        _fail(
            failures,
            (
                "stam_eff_max: fresh want %.1f got %.1f"
                % [CombatConstants.STAMINA_MAX, CombatExhaustion.effective_stamina_max(fresh)]
            )
        )
    var spent: Dictionary = fresh.duplicate(true)
    spent[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 1.0
    var want_exh: float = CombatConstants.STAMINA_MAX * CombatConstants.STAMINA_EXHAUSTION_MAX_MULT_FLOOR
    if not is_equal_approx(CombatExhaustion.effective_stamina_max(spent), want_exh):
        _fail(
            failures,
            (
                "stam_eff_max: full exhaustion want %.1f got %.1f"
                % [want_exh, CombatExhaustion.effective_stamina_max(spent)]
            )
        )
    var bleed: Dictionary = fresh.duplicate(true)
    bleed["stats"] = {"blood_volume": 35.0}
    var want_blood: float = CombatConstants.STAMINA_MAX * CombatConstants.STAMINA_BLOOD_MAX_MULT_FLOOR
    if not is_equal_approx(CombatExhaustion.effective_stamina_max(bleed), want_blood):
        _fail(
            failures,
            "stam_eff_max: low blood want %.1f got %.1f" % [want_blood, CombatExhaustion.effective_stamina_max(bleed)]
        )


## MXm-3: PCr resynthesis slows when fight-exhausted.


## MXm-3: PCr resynthesis slows when fight-exhausted.
static func _run_stamina_effective_refill_slows_with_exhaustion(failures: PackedStringArray) -> void:
    var fresh: Dictionary = {CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.0}
    var spent: Dictionary = {CombatConstants.COMBATANT_KEY_EXHAUSTION: 1.0}
    var rate_fresh: float = CombatExhaustion.effective_stamina_refill_rate(fresh)
    var rate_spent: float = CombatExhaustion.effective_stamina_refill_rate(spent)
    if not is_equal_approx(rate_fresh, CombatConstants.STAMINA_REFILL_RATE):
        _fail(failures, "stam_eff_refill: fresh want base rate got %.3f" % rate_fresh)
    var want_spent: float = CombatConstants.STAMINA_REFILL_RATE * CombatConstants.STAMINA_REFILL_EXHAUSTION_MULT_FLOOR
    if not is_equal_approx(rate_spent, want_spent):
        _fail(failures, "stam_eff_refill: exhausted want %.3f got %.3f" % [want_spent, rate_spent])


## Formation pressure: defensive threshold uses burst ratio vs effective max (not absolute / STAMINA_MAX).


## Formation pressure: defensive threshold uses burst ratio vs effective max (not absolute / STAMINA_MAX).
static func _run_opponent_pressure_defensive_uses_burst_ratio(failures: PackedStringArray) -> void:
    var ZOC := preload("res://combat/ZoneOfControl.gd")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var fid: String = _EntityAccess.formation_id_str(player)
    _EntityAccess.set_exhaustion_float(enemy, 1.0)
    enemy["stats"] = {"blood_volume": 100.0}
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["stamina"] = 30.0
    var mod_neutral: float = ZOC.get_opponent_pressure_duration_multiplier(mgr, fid)
    if not is_equal_approx(mod_neutral, CombatConstants.PRESSURE_MOD_NEUTRAL):
        _fail(
            failures,
            (
                "pressure_ratio: 30/70 burst want neutral (%.2f) got %.2f"
                % [CombatConstants.PRESSURE_MOD_NEUTRAL, mod_neutral]
            )
        )
    enemy["stamina"] = 20.0
    var mod_def: float = ZOC.get_opponent_pressure_duration_multiplier(mgr, fid)
    if not is_equal_approx(mod_def, CombatConstants.PRESSURE_MOD_DEFENSIVE):
        _fail(
            failures,
            (
                "pressure_ratio: 20/70 burst want defensive (%.2f) got %.2f"
                % [CombatConstants.PRESSURE_MOD_DEFENSIVE, mod_def]
            )
        )
    _free_manager(mgr)


## Tier 7: fatigued combatants wait longer between **`EVENT_ACTION_READY`** schedules.


## Tier 7: fatigued combatants wait longer between **`EVENT_ACTION_READY`** schedules.
static func _run_tier7_stamina_action_ready_cooldown_scales_with_fatigue(failures: PackedStringArray) -> void:
    var fresh: Dictionary = {"stamina": CombatConstants.STAMINA_MAX, "stats": {"agility": 100}}
    var tired: Dictionary = {"stamina": 0.0, "stats": {"agility": 100}}
    var cd_fresh: float = _EventScheduler.action_ready_cooldown(fresh)
    var cd_tired: float = _EventScheduler.action_ready_cooldown(tired)
    if cd_fresh <= 0.0:
        _fail(failures, "tier7_ready_delay: fresh cooldown invalid %.3f" % cd_fresh)
        return
    var want_ratio: float = CombatConstants.STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT
    if not is_equal_approx(cd_tired / cd_fresh, want_ratio):
        _fail(failures, "tier7_ready_delay: tired/fresh ratio want %.3f got %.3f" % [want_ratio, cd_tired / cd_fresh])


## Tier 0.1 / P4b: lane obstacles slow formation-move duration estimates.


## Tier 0.1 / P4b: lane obstacles slow formation-move duration estimates.
static func _run_formation_move_duration_lane_obstacle_slows_estimate(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var clear_dur: float = _FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, c)
    var lane_clear: float = _ZoneOfControl.get_swap_lane_duration_multiplier(mgr, "player", _EntityAccess.file_int(c))
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    var lane_slow: float = _ZoneOfControl.get_swap_lane_duration_multiplier(mgr, "player", _EntityAccess.file_int(c))
    var slow_dur: float = _FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, c)
    _free_manager(mgr)
    if lane_slow < CombatConstants.LANE_MOD_CROWDED - 0.01:
        _fail(failures, "form_dur_lane: obstacle lane mult want >= crowded got %.3f" % lane_slow)
    if slow_dur <= clear_dur * 1.08:
        _fail(failures, "form_dur_lane: slow %.3f should exceed clear %.3f" % [slow_dur, clear_dur])
    if lane_clear > CombatConstants.LANE_MOD_CLEAR + 0.02:
        _fail(failures, "form_dur_lane: clear lane mult expected ~1.0 got %.3f" % lane_clear)


## Tier 0.1: **`CombatFormationFlow`** pair duration matches **`CombatFormationMoveDuration`** estimate.


## Tier 0.1: **`CombatFormationFlow`** pair duration matches **`CombatFormationMoveDuration`** estimate.
static func _run_formation_move_duration_matches_flow_pair_start(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    var want: float = _FormationMoveDuration.estimate_adjacent_rank_pair_duration_s(mgr, p0, p1, "swap_rank")
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    var got: float = float(p0.get("state_duration", -1.0))
    _free_manager(mgr)
    if not is_equal_approx(got, want):
        _fail(failures, "form_dur_flow: pair start want %.4f got %.4f" % [want, got])


## Tier 0.1: listed formation moves carry **`formation_move_duration_hint`** when lane is crowded.


## Tier 0.1: listed formation moves carry **`formation_move_duration_hint`** when lane is crowded.
static func _run_formation_move_duration_listed_actions_stamp_hint(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "form_dur_list: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _free_manager(mgr)
    var rotate_act: Dictionary = _ListedActions.first_action_move_vs_target(
        acts, CombatConstants.MOVE_ID_ROTATE_FILE, ally_id
    )
    if rotate_act.is_empty():
        _fail(failures, "form_dur_list: expected rotate_file in crowded-lane actions")
        return
    var hint: String = str(rotate_act.get("formation_move_duration_hint", ""))
    if hint.is_empty() or not hint.contains("crowded"):
        _fail(failures, "form_dur_list: rotate_file want crowded duration hint got '%s'" % hint)


## Tier 0.1 UI: player turn-ready lists formation-move duration from stamped action hints.


## Tier 0.1 UI: player turn-ready lists formation-move duration from stamped action hints.
static func _run_formation_move_duration_player_turn_hint_from_listed_actions(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "form_dur_turn_hint: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    var line: String = _PlayerTurnHints.formation_listed_moves_hint_if_applicable(mgr, c, acts)
    if line.is_empty() or not line.contains("crowded"):
        _fail(failures, "form_dur_turn_hint: want crowded lane in hint got '%s'" % line)
    var compact: String = CombatDebug.format_actions_compact(acts)
    if not compact.contains("crowded"):
        _fail(failures, "form_dur_turn_hint: format_actions_compact want duration suffix got '%s'" % compact)
    _free_manager(mgr)


## Tier 0.1: listed formation-move duration appears on waiting gauge tooltip after turn-ready sync.


## Tier 0.1: listed formation-move duration appears on waiting gauge tooltip after turn-ready sync.
static func _run_formation_move_duration_gauge_tooltip_listed_hint(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "form_dur_gauge: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, c, acts)
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, mgr)
    var joined: String = "\n".join(tips)
    _free_manager(mgr)
    if not joined.contains("crowded"):
        _fail(failures, "form_dur_gauge: want crowded lane in gauge tooltip got '%s'" % joined)


## Tier 0.1: listed formation duration not shown on gauge tooltip after leaving waiting.


## Tier 0.1: listed formation duration not shown on gauge tooltip after leaving waiting.
static func _run_formation_move_duration_gauge_tooltip_clears_when_not_waiting(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
    if c.is_empty():
        _fail(failures, "form_dur_gauge_wait: need rank-0 player at file 0")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, c, acts)
    var stamped: String = str(c.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
    if stamped.is_empty():
        _fail(failures, "form_dur_gauge_wait: want stamped listed hint before state change")
        _free_manager(mgr)
        return
    c["state"] = CombatConstants.STATE_WIND_UP
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, mgr)
    var joined: String = "\n".join(tips)
    _free_manager(mgr)
    if stamped in joined:
        _fail(failures, "form_dur_gauge_wait: listed hint should hide when not waiting got '%s'" % joined)


## Tier 0.1: resolve clears **`COMBATANT_KEY_FORMATION_MOVES_TURN_HINT`** on the actor.


## Tier 0.1: resolve clears **`COMBATANT_KEY_FORMATION_MOVES_TURN_HINT`** on the actor.
static func _run_formation_move_duration_gauge_tooltip_clears_on_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
    if c.is_empty():
        _fail(failures, "form_dur_gauge_resolve: need rank-0 player at file 0")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, c, acts)
    if not c.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
        _fail(failures, "form_dur_gauge_resolve: want stamped hint before resolve")
        _free_manager(mgr)
        return
    var cid: int = _EntityAccess.id_int(c)
    _ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_WAIT, {})
    _free_manager(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
        _fail(failures, "form_dur_gauge_resolve: hint key should clear after wait resolve")


## Tier 0 / wind-up: explicit **`move_id`** not on weapon does not start wind-up or substitute a random move.


## Tier 0 / wind-up: explicit **`move_id`** not on weapon does not start wind-up or substitute a random move.
static func _run_wind_up_rejects_move_not_on_weapon(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var atk_id: int = _EntityAccess.id_int(atk)
    var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
    atk["gauge"] = 100.0
    _WindUpStarter.start(mgr, atk_id, def_id, "spear_thrust")
    if _EntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP:
        _fail(failures, "wind_up_reject: SWORD should not wind up with spear_thrust")
    if not _EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
        _fail(failures, "wind_up_reject: pending_attack should stay empty")
    _free_manager(mgr)


static func _run_formation_diagram_health_bar_reflects_body_damage(failures: PackedStringArray) -> void:
    var mgr: Node = _harness_start_1v1(
        "SWORD",
        {"files": 1, "ranks": 1, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
        {"files": 1, "ranks": 1}
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
    var diagram: Control = FormationDiagramBuilder.create(mgr, {"files": 1, "ranks": 1, "density": "normal"}, "player")
    var grid: GridContainer = diagram.get_meta("_formation_grid", null) as GridContainer
    var bar_before: ProgressBar = FormationDiagramBuilder.first_health_bar_in_grid(grid)
    if bar_before == null:
        _fail(
            failures,
            (
                "form_health_bar: want ProgressBar in living cell (%s)"
                % FormationDiagramBuilder.debug_grid_cell_summary(grid)
            )
        )
        diagram.free()
        _free_manager(mgr)
        return
    var ratio_before: float = _PartyRowFormatter.total_body_health_ratio(_EntityAccess.stats_dict(c))
    if ratio_before < 0.95:
        _fail(failures, "form_health_bar: want near-full body ratio got %.3f" % ratio_before)
    var bar_before_val: float = bar_before.value
    var part: String = "chest"
    var mx: float = float(ent.body_max.get(part, 1))
    ent.body_cutting[part] = mx * 0.35
    ent.body_blunt[part] = mx * 0.35
    FormationDiagramBuilder.refresh(diagram)
    for raw in mgr.get_combatants():
        if _EntityAccess.id_int(raw) == _EntityAccess.id_int(c):
            c = raw as Dictionary
            break
    var ratio_after: float = _PartyRowFormatter.total_body_health_ratio(_EntityAccess.stats_dict(c))
    var bar_after: ProgressBar = FormationDiagramBuilder.first_health_bar_in_grid(grid)
    if bar_after == null:
        diagram.free()
        _free_manager(mgr)
        _fail(failures, "form_health_bar: bar missing after refresh")
        return
    var bar_after_val: float = bar_after.value
    diagram.free()
    _free_manager(mgr)
    if ratio_after >= ratio_before - 0.05:
        _fail(
            failures, "form_health_bar: want lower body ratio got before=%.3f after=%.3f" % [ratio_before, ratio_after]
        )
    if bar_after_val >= bar_before_val - 1.0:
        _fail(
            failures,
            "form_health_bar: want lower bar value got before=%.1f after=%.1f" % [bar_before_val, bar_after_val]
        )


static func _formation_health_bar_fill_color(bar: ProgressBar) -> Color:
    if bar == null:
        return Color.WHITE
    var sb: StyleBox = bar.get_theme_stylebox("fill")
    if sb is StyleBoxFlat:
        return (sb as StyleBoxFlat).bg_color
    return Color.WHITE


static func _run_formation_diagram_health_bar_tint_reflects_function_loss(failures: PackedStringArray) -> void:
    var mgr: Node = _harness_start_1v1(
        "SWORD",
        {"files": 1, "ranks": 1, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
        {"files": 1, "ranks": 1}
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
    var diagram: Control = FormationDiagramBuilder.create(mgr, {"files": 1, "ranks": 1, "density": "normal"}, "player")
    var grid: GridContainer = diagram.get_meta("_formation_grid", null) as GridContainer
    var bar_before: ProgressBar = FormationDiagramBuilder.first_health_bar_in_grid(grid)
    if bar_before == null:
        _fail(
            failures,
            (
                "form_health_tint: want ProgressBar in living cell (%s)"
                % FormationDiagramBuilder.debug_grid_cell_summary(grid)
            )
        )
        diagram.free()
        _free_manager(mgr)
        return
    var func_before: float = _PartyRowFormatter.body_functionality_ratio(c, mgr)
    var color_before: Color = _formation_health_bar_fill_color(bar_before)
    var arm: String = "right_arm"
    var mx: float = float(ent.body_max.get(arm, 1))
    ent.body_cutting[arm] = 0.0
    ent.body_blunt[arm] = 0.0
    ent.bone_health[arm] = 0
    FormationDiagramBuilder.refresh(diagram)
    for raw in mgr.get_combatants():
        if _EntityAccess.id_int(raw) == _EntityAccess.id_int(c):
            c = raw as Dictionary
            break
    var func_after: float = _PartyRowFormatter.body_functionality_ratio(c, mgr)
    var bar_after: ProgressBar = FormationDiagramBuilder.first_health_bar_in_grid(grid)
    if bar_after == null:
        diagram.free()
        _free_manager(mgr)
        _fail(failures, "form_health_tint: bar missing after refresh")
        return
    var color_after: Color = _formation_health_bar_fill_color(bar_after)
    diagram.free()
    _free_manager(mgr)
    if func_after >= func_before - 0.08:
        _fail(failures, "form_health_tint: want lower function got before=%.3f after=%.3f" % [func_before, func_after])
    if color_after.g >= color_before.g - 0.05 and color_after.r <= color_before.r + 0.05:
        _fail(
            failures,
            (
                "form_health_tint: want redder fill before=(%.2f,%.2f,%.2f) after=(%.2f,%.2f,%.2f)"
                % [color_before.r, color_before.g, color_before.b, color_after.r, color_after.g, color_after.b]
            )
        )


## Tier 0.1 UI: crowded lane shows formation-move duration hint on diagram tooltips.


## Tier 0.1 UI: crowded lane shows formation-move duration hint on diagram tooltips.
static func _run_formation_move_duration_ui_hint_when_lane_crowded(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    var nm: String = _EntityAccess.get_display_name(c, _EntityAccess.id_int(c))
    var tip: String = "\n".join(_UiHints.formation_cell_tooltip_lines(c, nm, mgr))
    _free_manager(mgr)
    if not tip.contains("Formation move"):
        _fail(failures, "form_dur_ui: want Formation move hint got '%s'" % tip)
    if not tip.contains("crowded"):
        _fail(failures, "form_dur_ui: want crowded lane in hint got '%s'" % tip)

## Tier 1: **`rotate_file`** listed for adjacent rank-0 allies on a multi-file line.
