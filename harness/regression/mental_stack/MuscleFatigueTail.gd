class_name CombatRegressionHarnessMuscleFatigueTail
extends RefCounted

## Phase 2 per-limb muscle fatigue harness (FEATURE_MUSCLE_GROUP_FATIGUE).

## Harness assertion tolerance tiers.
const ASSERT_CRITICAL_TOLERANCE: float = 0.001
const ASSERT_COMPUTED_TOLERANCE: float = 0.02


static func run(failures: PackedStringArray) -> void:
    _run_muscle_fatigue_production_flag_default_on(failures)
    _run_muscle_fatigue_flag_off_skips_pools(failures)
    _run_muscle_fatigue_flag_off_wind_up_unchanged(failures)
    _run_muscle_fatigue_attack_raises_dominant_limb(failures)
    _run_muscle_fatigue_formation_raises_legs(failures)
    _run_muscle_fatigue_production_formation_move_raises_legs(failures)
    _run_muscle_fatigue_close_attempt_raises_initiator_legs(failures)
    _run_muscle_fatigue_offense_damp_when_limb_tired(failures)
    _run_muscle_fatigue_high_limb_lengthens_wind_up(failures)
    _run_muscle_fatigue_waiting_recovery(failures)
    _run_muscle_fatigue_recovering_slower_than_waiting(failures)
    _run_muscle_fatigue_heavy_damps_more_than_quick(failures)
    _run_muscle_fatigue_wait_boost_when_limb_tired(failures)
    _run_muscle_fatigue_party_leg_line(failures)
    _run_muscle_fatigue_sync_to_entity(failures)
    _run_muscle_fatigue_gauge_suffix_shows_worst_limb(failures)
    _run_muscle_fatigue_formation_damp_tired_legs(failures)
    _run_muscle_fatigue_parry_capacity_mult(failures)
    _run_muscle_fatigue_cowering_recovery(failures)
    _run_muscle_fatigue_entity_seed_from_campaign(failures)
    _run_muscle_fatigue_dodge_chance_tired_legs(failures)
    _run_muscle_fatigue_step_speed_curve(failures)
    _run_muscle_fatigue_balance_stability_mult(failures)
    _run_muscle_fatigue_step_precision_mult(failures)
    _run_muscle_fatigue_two_handed_off_arm_share(failures)
    _run_muscle_fatigue_camp_rest_clears_entity(failures)
    _run_muscle_fatigue_battle_ui_suffix(failures)
    _run_muscle_fatigue_exertion_recovery_cycle(failures)
    _run_muscle_fatigue_single_leg_fatigue_pickup(failures)


static func _with_flag(on: bool, block: Callable) -> void:
    var prev: bool = CombatConstants.is_feature_muscle_group_fatigue_enabled()
    CombatConstants.set_feature_muscle_group_fatigue_load(on)
    block.call()
    CombatConstants.set_feature_muscle_group_fatigue_load(prev)


static func _run_muscle_fatigue_production_flag_default_on(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_muscle_group_fatigue_enabled():
        HarnessFixtures._fail(failures, "muscle_fatigue_flag: production default should be on (Expand MXf)")


static func _run_muscle_fatigue_flag_off_skips_pools(failures: PackedStringArray) -> void:
    _with_flag(
        false,
        func() -> void:
            var mgr: Node = HarnessFixtures._harness_start_1v1()
            for c in mgr.combatants:
                if c.has(CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE):
                    HarnessFixtures._fail(failures, "muscle_fatigue_off: should not seed pools when flag off")
            HarnessFixtures._free_manager(mgr)
    )


static func _run_muscle_fatigue_attack_raises_dominant_limb(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            CombatMuscleFatigue.apply_exertion_after_breath_spend(
                null, c, 20.0, CombatConstants.MOVE_ID_HEAVY, CombatMuscleFatigue.EXERTION_KIND_ATTACK
            )
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c)
            var fatigue: float = CombatMuscleFatigue.limb_fatigue(c, limb)
            if fatigue <= 0.01:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_attack: want dominant limb fatigue got %.4f limb=%s" % [fatigue, limb]
                )
    )


static func _run_muscle_fatigue_high_limb_lengthens_wind_up(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            seed(88422)
            var mgr_hi: Node = HarnessFixtures._harness_start_1v1()
            CombatMuscleFatigue.seed_combatant_if_enabled(mgr_hi.combatants[0])
            AttackWindUpStarter.start(mgr_hi, 0, 1, "slash")
            var dur_hi: float = float(mgr_hi.combatants[0].get(DataKeys.PA_STATE_DURATION, 0.0))
            HarnessFixtures._free_manager(mgr_hi)
            seed(88422)
            var mgr_lo: Node = HarnessFixtures._harness_start_1v1()
            var c: Dictionary = mgr_lo.combatants[0]
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c, mgr_lo)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.85
            AttackWindUpStarter.start(mgr_lo, 0, 1, "slash")
            var dur_lo: float = float(c.get(DataKeys.PA_STATE_DURATION, 0.0))
            HarnessFixtures._free_manager(mgr_lo)
            if dur_lo <= dur_hi * 1.05:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_wind_up: want longer wind-up hi=%.3f tired=%.3f" % [dur_hi, dur_lo]
                )
    )


static func _run_muscle_fatigue_waiting_recovery(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = BodyPartConstants.PART_RIGHT_ARM
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.6
            CombatMuscleFatigue.process_waiting_recovery(c, 5.0)
            var after: float = CombatMuscleFatigue.limb_fatigue(c, limb)
            if after >= 0.55:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_recovery: want decay got before=0.6 after=%.3f" % after
                )
    )


static func _run_muscle_fatigue_flag_off_wind_up_unchanged(failures: PackedStringArray) -> void:
    _with_flag(
        false,
        func() -> void:
            seed(99102)
            var mgr: Node = HarnessFixtures._harness_start_1v1()
            var c: Dictionary = mgr.combatants[0]
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE] = {BodyPartConstants.PART_RIGHT_ARM: 0.9}
            AttackWindUpStarter.start(mgr, 0, 1, "slash")
            var dur_tired: float = float(c.get(DataKeys.PA_STATE_DURATION, 0.0))
            HarnessFixtures._free_manager(mgr)
            seed(99102)
            var mgr2: Node = HarnessFixtures._harness_start_1v1()
            AttackWindUpStarter.start(mgr2, 0, 1, "slash")
            var dur_fresh: float = float(mgr2.combatants[0].get(DataKeys.PA_STATE_DURATION, 0.0))
            HarnessFixtures._free_manager(mgr2)
            if absf(dur_tired - dur_fresh) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(
                    failures,
                    (
                        "muscle_fatigue_off_wind_up: flag off should ignore pools tired=%.3f fresh=%.3f"
                        % [dur_tired, dur_fresh]
                    )
                )
    )


static func _run_muscle_fatigue_formation_raises_legs(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            CombatMuscleFatigue.apply_formation_exertion(c, CombatConstants.MOVE_ID_ROTATE_FILE)
            var r_leg: float = CombatMuscleFatigue.limb_fatigue(c, BodyPartConstants.PART_RIGHT_LEG)
            var l_leg: float = CombatMuscleFatigue.limb_fatigue(c, BodyPartConstants.PART_LEFT_LEG)
            if r_leg <= 0.01 or l_leg <= 0.01:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_formation: want leg fatigue got R=%.4f L=%.4f" % [r_leg, l_leg]
                )
    )


## Production wiring: a formation move (rotate_file) accumulates leg muscle-fatigue on BOTH movers via
## `CombatFormationFlow.start_rotate_file` -> `apply_formation_exertion`. Previously the leg-fatigue writer was
## dead in production (only the harness exercised it), so formation movement never tired the legs.
static func _run_muscle_fatigue_production_formation_move_raises_legs(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            seed(44710)
            var mgr: Node = CombatManager.new()
            for _i in 6:
                mgr.register(HarnessFixtures._new_entity("SWORD"), "player")
            for _j in 3:
                mgr.register(HarnessFixtures._new_entity("SWORD"), "enemy")
            mgr.start({"files": 3, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
            var a: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
            var b: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 1)
            if a.is_empty() or b.is_empty():
                HarnessFixtures._fail(failures, "muscle_fatigue_prod_formation: missing rank-0 file-0/file-1 pair")
                HarnessFixtures._free_manager(mgr)
                return
            var a_id: int = CombatantEntityAccess.id_int(a)
            var b_id: int = CombatantEntityAccess.id_int(b)
            var a_before: float = CombatMuscleFatigue.max_leg_fatigue(a)
            var b_before: float = CombatMuscleFatigue.max_leg_fatigue(b)
            a["gauge"] = 100.0
            b["gauge"] = 100.0
            CombatFormationFlow.start_rotate_file(mgr, a_id, b_id)
            var a_after: float = CombatMuscleFatigue.max_leg_fatigue(a)
            var b_after: float = CombatMuscleFatigue.max_leg_fatigue(b)
            if CombatantEntityAccess.state_str(a) != CombatConstants.STATE_SWAP_RANK:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_prod_formation: rotate_file did not start (state=%s)"
                    % CombatantEntityAccess.state_str(a)
                )
            if a_after <= a_before + 0.01 or b_after <= b_before + 0.01:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_prod_formation: want leg fatigue rise a=%.4f->%.4f b=%.4f->%.4f"
                    % [a_before, a_after, b_before, b_after]
                )
            HarnessFixtures._free_manager(mgr)
    )


## Production wiring: a successful close attempt (closing distance) accumulates leg muscle-fatigue on the
## INITIATOR only via `CombatEngagementResolver.resolve_close_attempt` -> `apply_formation_exertion`. Closing
## distance is a leg-driven advance; the defender does not move (their band is a symmetric modeling artifact).
## Leg fatigue is arm-independent, so parry capacity is unaffected.
static func _run_muscle_fatigue_close_attempt_raises_initiator_legs(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            seed(44711)
            var fixtures: Array = HarnessFixtures._harness_7v3_wing_rank0_fixtures()
            var mgr: Node = fixtures[0] as Node
            var p: Dictionary = fixtures[1] as Dictionary
            var en: Dictionary = fixtures[2] as Dictionary
            if p.is_empty() or en.is_empty():
                HarnessFixtures._fail(failures, "muscle_fatigue_close: missing 7v3 wing fixtures")
                HarnessFixtures._free_manager(mgr)
                return
            var p_id: int = CombatantEntityAccess.id_int(p)
            var e_id: int = CombatantEntityAccess.id_int(en)
            HarnessFixtures._harness_bind_pair_long_band(p, en)
            if not CombatMeleeListing.attempt_close_listed_for_pair(mgr, p, e_id, CombatConstants.DISTANCE_LONG):
                HarnessFixtures._fail(failures, "muscle_fatigue_close: setup want listable close at LONG")
                HarnessFixtures._free_manager(mgr)
                return
            var sd: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(p)
            sd["strength"] = 400.0
            var sd_e: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(en)
            sd_e["agility"] = 5.0
            var p_before: float = CombatMuscleFatigue.max_leg_fatigue(p)
            var e_before: float = CombatMuscleFatigue.max_leg_fatigue(en)
            var cap: Array = []
            mgr.action_resolved.connect(
                func(_a: int, _t: int, result: Dictionary) -> void:
                    cap.clear()
                    cap.append(result)
            )
            CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
            var p_after: float = CombatMuscleFatigue.max_leg_fatigue(p)
            var e_after: float = CombatMuscleFatigue.max_leg_fatigue(en)
            HarnessFixtures._free_manager(mgr)
            if cap.is_empty():
                HarnessFixtures._fail(failures, "muscle_fatigue_close: expected action_resolved")
                return
            var r: Dictionary = cap[0] as Dictionary
            if str(r.get("outcome", "")) != "close_success":
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_close: expected close_success got %s" % str(r)
                )
                return
            if p_after <= p_before + 0.01:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_close: want initiator leg fatigue rise %.4f->%.4f" % [p_before, p_after]
                )
            if e_after > e_before + 0.001:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_close: defender should not gain leg fatigue %.4f->%.4f" % [e_before, e_after]
                )
    )


static func _run_muscle_fatigue_offense_damp_when_limb_tired(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.8
            var mult: float = CombatMuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_HEAVY)
            var effective: float = clampf(
                0.8 * CombatMuscleFatigue.move_exertion_profile_mult(CombatConstants.MOVE_ID_HEAVY), 0.0, 1.0
            )
            var expected: float = lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_OFFENSE_DAMP_FLOOR, effective)
            if absf(mult - expected) > 0.02:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_offense_damp: want ~%.3f got %.3f" % [expected, mult]
                )
            var wait_m: float = CombatMuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_WAIT)
            if absf(wait_m - 1.0) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_offense_damp: wait should stay 1.0 got %.3f" % wait_m
                )
    )


static func _run_muscle_fatigue_recovering_slower_than_waiting(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var wait_c: Dictionary = {}
            var rec_c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(wait_c)
            CombatMuscleFatigue.seed_combatant_if_enabled(rec_c)
            var limb: String = BodyPartConstants.PART_RIGHT_ARM
            wait_c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.5
            rec_c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.5
            CombatMuscleFatigue.process_waiting_recovery(wait_c, 2.0)
            CombatMuscleFatigue.process_recovering_recovery(rec_c, 2.0)
            var wait_after: float = CombatMuscleFatigue.limb_fatigue(wait_c, limb)
            var rec_after: float = CombatMuscleFatigue.limb_fatigue(rec_c, limb)
            if wait_after >= rec_after:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_recovering_rate: want waiting faster wait=%.3f rec=%.3f" % [wait_after, rec_after]
                )
    )


static func _run_muscle_fatigue_heavy_damps_more_than_quick(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.55
            var heavy_m: float = CombatMuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_HEAVY)
            var quick_m: float = CombatMuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_QUICK)
            if heavy_m >= quick_m:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_profile_damp: heavy=%.3f should beat quick=%.3f" % [heavy_m, quick_m]
                )
    )


static func _run_muscle_fatigue_wait_boost_when_limb_tired(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.7
            var boost: float = CombatMuscleFatigue.wait_recovery_weight_mult(c)
            if boost <= 1.05:
                HarnessFixtures._fail(failures, "muscle_fatigue_wait_boost: want >1.05 got %.3f" % boost)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.05
            var fresh: float = CombatMuscleFatigue.wait_recovery_weight_mult(c)
            if absf(fresh - 1.0) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_wait_boost: fresh want 1.0 got %.3f" % fresh)
    )


static func _run_muscle_fatigue_party_leg_line(failures: PackedStringArray) -> void:
    var line: String = (
        CombatMuscleFatigue
        . format_party_limb_fatigue_line(
            {
                BodyPartConstants.PART_RIGHT_ARM: 0.1,
                BodyPartConstants.PART_LEFT_LEG: 0.42,
            }
        )
    )
    if not line.contains("L leg") or not line.contains("42"):
        HarnessFixtures._fail(failures, "muscle_fatigue_party: want leg line got '%s'" % line)


static func _run_muscle_fatigue_sync_to_entity(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var mgr: Node = HarnessFixtures._harness_start_1v1()
            var c: Dictionary = mgr.combatants[0]
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c, mgr)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.33
            CombatMuscleFatigue.sync_to_entities_from_manager(mgr)
            var entity: Node = CombatantEntityAccess.get_entity_from_manager(mgr, c)
            if entity == null or not ("muscle_fatigue" in entity):
                HarnessFixtures._fail(failures, "muscle_fatigue_sync: missing entity pools")
            elif absf(float(entity.muscle_fatigue.get(limb, -1.0)) - 0.33) > 0.01:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_sync: want 0.33 on %s got %s" % [limb, str(entity.muscle_fatigue.get(limb))]
                )
            HarnessFixtures._free_manager(mgr)
    )


static func _run_muscle_fatigue_gauge_suffix_shows_worst_limb(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_ARM] = 0.2
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.48
            var suffix: String = CombatMuscleFatigue.gauge_hint_suffix(c)
            if not suffix.contains("right leg") and not suffix.contains("right_leg"):
                HarnessFixtures._fail(failures, "muscle_fatigue_gauge_suffix: want leg in '%s'" % suffix)
    )


static func _run_muscle_fatigue_formation_damp_tired_legs(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.75
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_LEFT_LEG] = 0.75
            var mult: float = CombatMuscleFatigue.formation_movement_weight_mult(c, CombatConstants.MOVE_ID_ROTATE_FILE)
            # New curve at 75% fatigue: step_spd × precision
            var leg_f := 0.75
            var step_spd := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_FORWARD_SPEED_FLOOR_AT_MAX, pow(leg_f, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            var step_prec := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX, pow(leg_f, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            var expected := step_spd * step_prec
            if mult < 0.0 or absf(mult - expected) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_formation_damp: want ~%.3f got %.3f" % [expected, mult])
    )


static func _run_muscle_fatigue_parry_capacity_mult(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.8
            var mult: float = CombatMuscleFatigue.parry_capacity_mult(c)
            var expected: float = lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_PARRY_CAPACITY_FLOOR, 0.8)
            if absf(mult - expected) > 0.02:
                HarnessFixtures._fail(
                    failures, "muscle_fatigue_parry_cap: want ~%.3f got %.3f" % [expected, mult]
                )
    )


static func _run_muscle_fatigue_cowering_recovery(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {"state": CombatConstants.STATE_COWERING, "gauge": 10.0}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = BodyPartConstants.PART_RIGHT_ARM
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.55
            CombatStateHandlers.process_cowering_idle(null, c, 4.0)
            var after_f: float = CombatMuscleFatigue.limb_fatigue(c, limb)
            if after_f >= 0.5:
                HarnessFixtures._fail(failures, "muscle_fatigue_cowering: want limb decay got %.3f" % after_f)
            if CombatantEntityAccess.gauge_float(c) <= 10.5:
                HarnessFixtures._fail(
                    failures,
                    "muscle_fatigue_cowering: want composure fill got %.1f" % CombatantEntityAccess.gauge_float(c)
                )
    )


static func _run_muscle_fatigue_entity_seed_from_campaign(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var player: Node = HarnessFixtures._new_entity("SWORD")
            player.muscle_fatigue = {BodyPartConstants.PART_RIGHT_ARM: 0.28}
            var mgr: Node = CombatManager.new()
            mgr.register(player, "player")
            mgr.register(HarnessFixtures._new_entity("SWORD"), "enemy")
            mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
            var c: Dictionary = mgr.combatants[0]
            var seeded: float = CombatMuscleFatigue.limb_fatigue(c, BodyPartConstants.PART_RIGHT_ARM)
            HarnessFixtures._free_manager(mgr)
            if absf(seeded - 0.28) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_seed: want 0.28 from entity got %.3f" % seeded)
    )


static func _run_muscle_fatigue_dodge_chance_tired_legs(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            # 80% fatigue: below collapse start, dodge uses balance_stability curve (floor = BALANCE_STABILITY_FLOOR_AT_MAX).
            var c_80: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_80)
            c_80[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.8
            var mult_80: float = CombatMuscleFatigue.dodge_chance_mult(c_80)
            var leg_f_80 := 0.8
            var expected_80 := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(leg_f_80, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(mult_80 - expected_80) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_dodge_80: want ~%.3f got %.3f" % [expected_80, mult_80])
            # Fresh (0%): should return 1.0
            var c_fresh: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_fresh)
            var fresh_mult: float = CombatMuscleFatigue.dodge_chance_mult(c_fresh)
            if absf(fresh_mult - 1.0) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_dodge_fresh: want 1.0 got %.3f" % fresh_mult)
            # Smooth dodge collapse from 85% → 100% fatigue (no cliff-edge jump).
            var c_collapse: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_collapse)
            c_collapse[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 1.0
            c_collapse[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_LEFT_LEG] = 1.0
            var collapse_mult: float = CombatMuscleFatigue.dodge_chance_mult(c_collapse)
            # At 100% fatigue, smooth transition should reach the flat floor (DODGE_FLAT_FLOOR_AT_MAX).
            if absf(collapse_mult - CombatConstants.MUSCLE_FATIGUE_DODGE_FLAT_FLOOR_AT_MAX) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_dodge_collapse: want %.3f got %.3f" % [CombatConstants.MUSCLE_FATIGUE_DODGE_FLAT_FLOOR_AT_MAX, collapse_mult])
            # Boundary test at exactly 85% collapse start — should return stability (no transition yet).
            var c_boundary: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_boundary)
            c_boundary[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.85
            c_boundary[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_LEFT_LEG] = 0.85
            var boundary_mult: float = CombatMuscleFatigue.dodge_chance_mult(c_boundary)
            var expected_boundary := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(0.85, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(boundary_mult - expected_boundary) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_dodge_85_boundary: want ~%.3f got %.3f" % [expected_boundary, boundary_mult])
            # Verify smooth transition: 90% should be between stability value and flat floor.
            var c_90: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_90)
            c_90[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.90
            var mult_90: float = CombatMuscleFatigue.dodge_chance_mult(c_90)
            if mult_90 >= expected_80 - ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_dodge_smooth: want 90% < 80%% mult=%.3f vs %.3f" % [mult_90, expected_80])
            if mult_90 <= collapse_mult + ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_dodge_smooth: want 90% > full-collapse mult=%.3f vs %.3f" % [mult_90, collapse_mult])
    )


static func _run_muscle_fatigue_step_speed_curve(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            # 0% fatigue = no penalty in any direction
            var c_fresh: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_fresh)
            var fresh_fwd := CombatMuscleFatigue.step_speed_mult(c_fresh, "forward")
            var fresh_lat := CombatMuscleFatigue.step_speed_mult(c_fresh, "lateral")
            if absf(fresh_fwd - 1.0) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed_fresh_fwd: want 1.0 got %.3f" % fresh_fwd)
            # Lateral always applies penalty even when fresh (design: lateral movement is inherently slower).
            var expected_fresh_lat := CombatConstants.MUSCLE_FATIGUE_LATERAL_SPEED_PENALTY
            if absf(fresh_lat - expected_fresh_lat) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed_fresh_lat: want %.3f got %.3f" % [expected_fresh_lat, fresh_lat])
            # 75% fatigue: directional asymmetry (retreat penalized more than forward/lateral)
            var c_tired: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_tired)
            c_tired[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.75
            c_tired[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_LEFT_LEG] = 0.75
            var tired_fwd := CombatMuscleFatigue.step_speed_mult(c_tired, "forward")
            var tired_lat := CombatMuscleFatigue.step_speed_mult(c_tired, "lateral")
            var tired_ret := CombatMuscleFatigue.step_speed_mult(c_tired, "retreat")
            # Verify expected forward value matches curve formula.
            var leg_f_75 := 0.75
            var expected_fwd := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_FORWARD_SPEED_FLOOR_AT_MAX, pow(leg_f_75, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(tired_fwd - expected_fwd) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed_75_fwd: want ~%.3f got %.3f" % [expected_fwd, tired_fwd])
            # Verify lateral penalty constant is applied.
            var expected_lat := expected_fwd * CombatConstants.MUSCLE_FATIGUE_LATERAL_SPEED_PENALTY
            if absf(tired_lat - expected_lat) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed_75_lat: want ~%.3f got %.3f" % [expected_lat, tired_lat])
            # Verify retreat uses independent curve (not compounded on forward).
            var expected_ret := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_RETREAT_SPEED_FLOOR_AT_MAX, pow(leg_f_75, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(tired_ret - expected_ret) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed_75_ret: want ~%.3f got %.3f" % [expected_ret, tired_ret])
            # Verify retreat is harder than forward (research: Barton et al. 2017, Heijnen & Hommel 2005).
            # Retreat floor 0.08 < forward floor 0.10 — backward motion requires more proprioception/balance.
            if not (tired_ret < tired_fwd):
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed: retreat should be harder than forward fwd=%.3f ret=%.3f" % [tired_fwd, tired_ret])
            if not (tired_lat < tired_fwd):
                HarnessFixtures._fail(failures, "muscle_fatigue_step_speed: lateral should be penalized vs forward fwd=%.3f lat=%.3f" % [tired_fwd, tired_lat])
    )


static func _run_muscle_fatigue_two_handed_off_arm_share(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var entity: Node = HarnessFixtures._new_entity("SWORD")
            var weapon: Variant = CombatantEntityAccess.get_weapon_from_node(entity)
            if weapon == null:
                HarnessFixtures._fail(failures, "muscle_fatigue_2h: missing weapon")
                return
            weapon.is_two_handed = true
            var c: Dictionary = {"node": entity}
            CombatMuscleFatigue.seed_combatant_if_enabled(c, entity)
            CombatMuscleFatigue.apply_exertion_after_breath_spend(
                null, c, 30.0, CombatConstants.MOVE_ID_HEAVY, CombatMuscleFatigue.EXERTION_KIND_ATTACK
            )
            var dom: String = CombatMuscleFatigue.dominant_strike_limb(c)
            var off: String = CombatMuscleFatigue.off_strike_limb(dom)
            var off_f: float = CombatMuscleFatigue.limb_fatigue(c, off)
            if off_f <= 0.01:
                HarnessFixtures._fail(failures, "muscle_fatigue_2h: want off-arm fatigue got %.4f" % off_f)
    )


static func _run_muscle_fatigue_camp_rest_clears_entity(failures: PackedStringArray) -> void:
    var entity: Node = HarnessFixtures._new_entity("SWORD")
    if not entity.has_method("_restore_muscle_fatigue_at_camp"):
        HarnessFixtures._fail(failures, "muscle_fatigue_camp: entity missing restore API")
        return
    entity.muscle_fatigue = {BodyPartConstants.PART_RIGHT_ARM: 0.5}
    entity._restore_muscle_fatigue_at_camp()
    if not (entity.muscle_fatigue as Dictionary).is_empty():
        HarnessFixtures._fail(failures, "muscle_fatigue_camp: want cleared pools")


static func _run_muscle_fatigue_battle_ui_suffix(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "gauge": 80.0, "stamina": 50.0, "breath": 50.0}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            c[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_ARM] = 0.4
            var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, null)
            if not label.contains("Msc"):
                HarnessFixtures._fail(failures, "muscle_fatigue_ui: want Msc in label '%s'" % label)
            var tips: PackedStringArray = CombatUiHints.gauge_tooltip_lines(c, null)
            var found_msc: bool = false
            for line in tips:
                if "Muscle fatigue" in line:
                    found_msc = true
                    break
            if not found_msc:
                HarnessFixtures._fail(failures, "muscle_fatigue_ui: want muscle tooltip line")
    )


static func _run_muscle_fatigue_single_leg_fatigue_pickup(failures: PackedStringArray) -> void:
    # Verifies max_leg_fatigue picks the higher leg when only one is set.
    _with_flag(
        true,
        func() -> void:
            var c_left_only: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_left_only)
            c_left_only[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_LEFT_LEG] = 0.7
            var left_mult: float = CombatMuscleFatigue.balance_stability_mult(c_left_only)
            var expected_left := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(0.7, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(left_mult - expected_left) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_single_leg_left: want ~%.3f got %.3f" % [expected_left, left_mult])
            var c_right_only: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_right_only)
            c_right_only[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.7
            var right_mult: float = CombatMuscleFatigue.balance_stability_mult(c_right_only)
            if absf(right_mult - expected_left) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_single_leg_right: want ~%.3f got %.3f" % [expected_left, right_mult])
    )

static func _run_muscle_fatigue_balance_stability_mult(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c_fresh: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_fresh)
            var fresh_val: float = CombatMuscleFatigue.balance_stability_mult(c_fresh)
            if absf(fresh_val - 1.0) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_balance_fresh: want 1.0 got %.3f" % fresh_val)
            var c_50: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_50)
            c_50[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.5
            var val_50: float = CombatMuscleFatigue.balance_stability_mult(c_50)
            var expected_50 := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(0.5, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(val_50 - expected_50) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_balance_50: want ~%.3f got %.3f" % [expected_50, val_50])
            var c_max: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_max)
            c_max[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 1.0
            var val_max: float = CombatMuscleFatigue.balance_stability_mult(c_max)
            if absf(val_max - CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_balance_max: want %.3f got %.3f" % [CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, val_max])
    )

static func _run_muscle_fatigue_step_precision_mult(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c_fresh: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_fresh)
            var fresh_val: float = CombatMuscleFatigue.step_precision_mult(c_fresh)
            if absf(fresh_val - 1.0) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_precision_fresh: want 1.0 got %.3f" % fresh_val)
            var c_50: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_50)
            c_50[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 0.5
            var val_50: float = CombatMuscleFatigue.step_precision_mult(c_50)
            var expected_50 := lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX, pow(0.5, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
            if absf(val_50 - expected_50) > ASSERT_COMPUTED_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_precision_50: want ~%.3f got %.3f" % [expected_50, val_50])
            var c_max: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c_max)
            c_max[CombatMuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][BodyPartConstants.PART_RIGHT_LEG] = 1.0
            var val_max: float = CombatMuscleFatigue.step_precision_mult(c_max)
            if absf(val_max - CombatConstants.MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX) > ASSERT_CRITICAL_TOLERANCE:
                HarnessFixtures._fail(failures, "muscle_fatigue_precision_max: want %.3f got %.3f" % [CombatConstants.MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX, val_max])
    )

static func _run_muscle_fatigue_exertion_recovery_cycle(failures: PackedStringArray) -> void:
    _with_flag(
        true,
        func() -> void:
            var c: Dictionary = {}
            CombatMuscleFatigue.seed_combatant_if_enabled(c)
            var limb: String = CombatMuscleFatigue.dominant_strike_limb(c)
            for _i in 8:
                CombatMuscleFatigue.apply_exertion_after_breath_spend(
                    null, c, 15.0, CombatConstants.MOVE_ID_MEDIUM, CombatMuscleFatigue.EXERTION_KIND_ATTACK
                )
            var after_strikes: float = CombatMuscleFatigue.limb_fatigue(c, limb)
            if after_strikes <= 0.0:
                HarnessFixtures._fail(failures, "muscle_fatigue_exert_recovery: want fatigue from strikes got %.4f" % after_strikes)
                return
            var clamped: bool = after_strikes >= 0.0 and after_strikes <= 1.0
            if not clamped:
                HarnessFixtures._fail(failures, "muscle_fatigue_exert_recovery: fatigue should be clamped [0,1] got %.4f" % after_strikes)
                return
            var before_recovery: float = after_strikes
            CombatMuscleFatigue.process_waiting_recovery(c, 4.0)
            var after_wait: float = CombatMuscleFatigue.limb_fatigue(c, limb)
            if after_wait >= before_recovery:
                HarnessFixtures._fail(failures, "muscle_fatigue_exert_recovery: want recovery decay got before=%.4f after=%.4f" % [before_recovery, after_wait])
    )
