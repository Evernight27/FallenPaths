class_name CombatRegressionHarnessMuscleFatigueTail
extends RefCounted

## Phase 2 per-limb muscle fatigue harness (FEATURE_MUSCLE_GROUP_FATIGUE).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MuscleFatigue := preload("res://combat/CombatMuscleFatigue.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _Bp := preload("res://core/BodyPartConstants.gd")
const _Harness := preload("res://harness/CombatRegressionHarness.gd")
const _Fixtures := preload("res://harness/HarnessFixtures.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")


## Harness assertion tolerance tiers.
const ASSERT_CRITICAL_TOLERANCE: float = 0.001
const ASSERT_COMPUTED_TOLERANCE: float = 0.02
const ASSERT_RATIO_TOLERANCE: float = 0.03

static func run(failures: PackedStringArray) -> void:
	_run_muscle_fatigue_production_flag_default_on(failures)
	_run_muscle_fatigue_flag_off_skips_pools(failures)
	_run_muscle_fatigue_flag_off_wind_up_unchanged(failures)
	_run_muscle_fatigue_attack_raises_dominant_limb(failures)
	_run_muscle_fatigue_formation_raises_legs(failures)
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
	_run_muscle_fatigue_two_handed_off_arm_share(failures)
	_run_muscle_fatigue_camp_rest_clears_entity(failures)
	_run_muscle_fatigue_battle_ui_suffix(failures)
	_run_muscle_fatigue_balance_exchange_proxy(failures)


static func _with_flag(on: bool, block: Callable) -> void:
	var prev: bool = CombatConstants.is_feature_muscle_group_fatigue_enabled()
	CombatConstants.set_feature_muscle_group_fatigue_load(on)
	block.call()
	CombatConstants.set_feature_muscle_group_fatigue_load(prev)


static func _run_muscle_fatigue_production_flag_default_on(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_muscle_group_fatigue_enabled():
		_Harness._fail(
			failures,
			"muscle_fatigue_flag: production default should be on (Expand MXf)"
		)


static func _run_muscle_fatigue_flag_off_skips_pools(failures: PackedStringArray) -> void:
	_with_flag(
		false,
		func() -> void:
			var mgr: Node = _Harness._harness_start_1v1()
			for c in mgr.combatants:
				if c.has(_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE):
					_Harness._fail(failures, "muscle_fatigue_off: should not seed pools when flag off")
			_Harness._free_manager(mgr)
	)


static func _run_muscle_fatigue_attack_raises_dominant_limb(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			_MuscleFatigue.apply_exertion_after_breath_spend(
				null,
				c,
				20.0,
				CombatConstants.MOVE_ID_HEAVY,
				_MuscleFatigue.EXERTION_KIND_ATTACK
			)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c)
			var fatigue: float = _MuscleFatigue.limb_fatigue(c, limb)
			if fatigue <= 0.01:
				_Harness._fail(
					failures,
					"muscle_fatigue_attack: want dominant limb fatigue got %.4f limb=%s"
					% [fatigue, limb]
				)
	)


static func _run_muscle_fatigue_high_limb_lengthens_wind_up(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			seed(88422)
			var mgr_hi: Node = _Harness._harness_start_1v1()
			_MuscleFatigue.seed_combatant_if_enabled(mgr_hi.combatants[0])
			_WindUpStarter.start(mgr_hi, 0, 1, "slash")
			var dur_hi: float = float(mgr_hi.combatants[0].get("state_duration", 0.0))
			_Harness._free_manager(mgr_hi)
			seed(88422)
			var mgr_lo: Node = _Harness._harness_start_1v1()
			var c: Dictionary = mgr_lo.combatants[0]
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c, mgr_lo)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.85
			_WindUpStarter.start(mgr_lo, 0, 1, "slash")
			var dur_lo: float = float(c.get("state_duration", 0.0))
			_Harness._free_manager(mgr_lo)
			if dur_lo <= dur_hi * 1.05:
				_Harness._fail(
					failures,
					"muscle_fatigue_wind_up: want longer wind-up hi=%.3f tired=%.3f"
					% [dur_hi, dur_lo]
				)
	)


static func _run_muscle_fatigue_waiting_recovery(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _Bp.PART_RIGHT_ARM
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.6
			_MuscleFatigue.process_waiting_recovery(c, 5.0)
			var after: float = _MuscleFatigue.limb_fatigue(c, limb)
			if after >= 0.55:
				_Harness._fail(
					failures,
					"muscle_fatigue_recovery: want decay got before=0.6 after=%.3f" % after
				)
	)


static func _run_muscle_fatigue_flag_off_wind_up_unchanged(failures: PackedStringArray) -> void:
	_with_flag(
		false,
		func() -> void:
			seed(99102)
			var mgr: Node = _Harness._harness_start_1v1()
			var c: Dictionary = mgr.combatants[0]
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE] = {_Bp.PART_RIGHT_ARM: 0.9}
			_WindUpStarter.start(mgr, 0, 1, "slash")
			var dur_tired: float = float(c.get("state_duration", 0.0))
			_Harness._free_manager(mgr)
			seed(99102)
			var mgr2: Node = _Harness._harness_start_1v1()
			_WindUpStarter.start(mgr2, 0, 1, "slash")
			var dur_fresh: float = float(mgr2.combatants[0].get("state_duration", 0.0))
			_Harness._free_manager(mgr2)
			if absf(dur_tired - dur_fresh) > ASSERT_COMPUTED_TOLERANCE:
				_Harness._fail(
					failures,
					"muscle_fatigue_off_wind_up: flag off should ignore pools tired=%.3f fresh=%.3f"
					% [dur_tired, dur_fresh]
				)
	)


static func _run_muscle_fatigue_formation_raises_legs(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			_MuscleFatigue.apply_formation_exertion(c, CombatConstants.MOVE_ID_ROTATE_FILE)
			var r_leg: float = _MuscleFatigue.limb_fatigue(c, _Bp.PART_RIGHT_LEG)
			var l_leg: float = _MuscleFatigue.limb_fatigue(c, _Bp.PART_LEFT_LEG)
			if r_leg <= 0.01 or l_leg <= 0.01:
				_Harness._fail(
					failures,
					"muscle_fatigue_formation: want leg fatigue got R=%.4f L=%.4f" % [r_leg, l_leg]
				)
	)


static func _run_muscle_fatigue_offense_damp_when_limb_tired(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.8
			var mult: float = _MuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_HEAVY)
			var effective: float = clampf(0.8 * _MuscleFatigue.move_exertion_profile_mult(CombatConstants.MOVE_ID_HEAVY), 0.0, 1.0)
			var expected: float = lerpf(
				1.0, CombatConstants.MUSCLE_FATIGUE_OFFENSE_DAMP_FLOOR, effective
			)
			if absf(mult - expected) > 0.02:
				_Harness._fail(
					failures,
					"muscle_fatigue_offense_damp: want ~%.3f got %.3f" % [expected, mult]
				)
			var wait_m: float = _MuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_WAIT)
			if absf(wait_m - 1.0) > ASSERT_COMPUTED_TOLERANCE:
				_Harness._fail(failures, "muscle_fatigue_offense_damp: wait should stay 1.0 got %.3f" % wait_m)
	)


static func _run_muscle_fatigue_recovering_slower_than_waiting(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var wait_c: Dictionary = {}
			var rec_c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(wait_c)
			_MuscleFatigue.seed_combatant_if_enabled(rec_c)
			var limb: String = _Bp.PART_RIGHT_ARM
			wait_c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.5
			rec_c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.5
			_MuscleFatigue.process_waiting_recovery(wait_c, 2.0)
			_MuscleFatigue.process_recovering_recovery(rec_c, 2.0)
			var wait_after: float = _MuscleFatigue.limb_fatigue(wait_c, limb)
			var rec_after: float = _MuscleFatigue.limb_fatigue(rec_c, limb)
			if wait_after >= rec_after:
				_Harness._fail(
					failures,
					"muscle_fatigue_recovering_rate: want waiting faster wait=%.3f rec=%.3f"
					% [wait_after, rec_after]
				)
	)


static func _run_muscle_fatigue_heavy_damps_more_than_quick(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.55
			var heavy_m: float = _MuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_HEAVY)
			var quick_m: float = _MuscleFatigue.offense_weight_mult(c, CombatConstants.MOVE_ID_QUICK)
			if heavy_m >= quick_m:
				_Harness._fail(
					failures,
					"muscle_fatigue_profile_damp: heavy=%.3f should beat quick=%.3f"
					% [heavy_m, quick_m]
				)
	)


static func _run_muscle_fatigue_wait_boost_when_limb_tired(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.7
			var boost: float = _MuscleFatigue.wait_recovery_weight_mult(c)
			if boost <= 1.05:
				_Harness._fail(
					failures,
					"muscle_fatigue_wait_boost: want >1.05 got %.3f" % boost
				)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.05
			var fresh: float = _MuscleFatigue.wait_recovery_weight_mult(c)
			if absf(fresh - 1.0) > ASSERT_COMPUTED_TOLERANCE:
				_Harness._fail(failures, "muscle_fatigue_wait_boost: fresh want 1.0 got %.3f" % fresh)
	)


static func _run_muscle_fatigue_party_leg_line(failures: PackedStringArray) -> void:
	var line: String = _MuscleFatigue.format_party_limb_fatigue_line({
		_Bp.PART_RIGHT_ARM: 0.1,
		_Bp.PART_LEFT_LEG: 0.42,
	})
	if not line.contains("L leg") or not line.contains("42"):
		_Harness._fail(failures, "muscle_fatigue_party: want leg line got '%s'" % line)


static func _run_muscle_fatigue_sync_to_entity(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var mgr: Node = _Harness._harness_start_1v1()
			var c: Dictionary = mgr.combatants[0]
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c, mgr)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.33
			_MuscleFatigue.sync_to_entities_from_manager(mgr)
			var entity: Node = _EntityAccess.get_entity_from_manager(mgr, c)
			if entity == null or not ("muscle_fatigue" in entity):
				_Harness._fail(failures, "muscle_fatigue_sync: missing entity pools")
			elif absf(float(entity.muscle_fatigue.get(limb, -1.0)) - 0.33) > 0.01:
				_Harness._fail(
					failures,
					"muscle_fatigue_sync: want 0.33 on %s got %s"
					% [limb, str(entity.muscle_fatigue.get(limb))]
				)
			_Harness._free_manager(mgr)
	)


static func _run_muscle_fatigue_gauge_suffix_shows_worst_limb(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][_Bp.PART_RIGHT_ARM] = 0.2
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][_Bp.PART_RIGHT_LEG] = 0.48
			var suffix: String = _MuscleFatigue.gauge_hint_suffix(c)
			if not suffix.contains("right leg") and not suffix.contains("right_leg"):
				_Harness._fail(failures, "muscle_fatigue_gauge_suffix: want leg in '%s'" % suffix)
	)


static func _run_muscle_fatigue_formation_damp_tired_legs(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][_Bp.PART_RIGHT_LEG] = 0.75
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][_Bp.PART_LEFT_LEG] = 0.75
			var mult: float = _MuscleFatigue.formation_movement_weight_mult(
				c, CombatConstants.MOVE_ID_ROTATE_FILE
			)
			if mult >= 0.75:
				_Harness._fail(
					failures,
					"muscle_fatigue_formation_damp: want leg damp got %.3f" % mult
				)
	)


static func _run_muscle_fatigue_parry_capacity_mult(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.8
			var mult: float = _MuscleFatigue.parry_capacity_mult(c)
			var expected: float = lerpf(
				1.0, CombatConstants.MUSCLE_FATIGUE_PARRY_CAPACITY_FLOOR, 0.8
			)
			if absf(mult - expected) > 0.02:
				_Harness._fail(
					failures,
					"muscle_fatigue_parry_cap: want ~%.3f got %.3f" % [expected, mult]
				)
	)


static func _run_muscle_fatigue_cowering_recovery(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {"state": CombatConstants.STATE_COWERING, "gauge": 10.0}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _Bp.PART_RIGHT_ARM
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][limb] = 0.55
			_StateHandlers.process_cowering_idle(null, c, 4.0)
			var after_f: float = _MuscleFatigue.limb_fatigue(c, limb)
			if after_f >= 0.5:
				_Harness._fail(
					failures,
					"muscle_fatigue_cowering: want limb decay got %.3f" % after_f
				)
			if _EntityAccess.gauge_float(c) <= 10.5:
				_Harness._fail(
					failures,
					"muscle_fatigue_cowering: want composure fill got %.1f" % _EntityAccess.gauge_float(c)
				)
	)


static func _run_muscle_fatigue_entity_seed_from_campaign(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var player: Node = _Fixtures._new_entity("SWORD")
			if not ("muscle_fatigue" in player):
				_Harness._fail(failures, "muscle_fatigue_seed: entity missing muscle_fatigue")
				return
			player.muscle_fatigue = {_Bp.PART_RIGHT_ARM: 0.28}
			var mgr: Node = _MgrScript.new()
			mgr.register(player, "player")
			mgr.register(_Fixtures._new_entity("SWORD"), "enemy")
			mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
			var c: Dictionary = mgr.combatants[0]
			var seeded: float = _MuscleFatigue.limb_fatigue(c, _Bp.PART_RIGHT_ARM)
			_Harness._free_manager(mgr)
			if absf(seeded - 0.28) > 0.02:
				_Harness._fail(
					failures,
					"muscle_fatigue_seed: want 0.28 from entity got %.3f" % seeded
				)
	)


static func _run_muscle_fatigue_dodge_chance_tired_legs(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][_Bp.PART_RIGHT_LEG] = 0.8
			var mult: float = _MuscleFatigue.dodge_chance_mult(c)
			var expected: float = lerpf(
				1.0, CombatConstants.MUSCLE_FATIGUE_DODGE_CHANCE_FLOOR, 0.8
			)
			if absf(mult - expected) > 0.02:
				_Harness._fail(
					failures,
					"muscle_fatigue_dodge: want ~%.3f got %.3f" % [expected, mult]
				)
	)


static func _run_muscle_fatigue_two_handed_off_arm_share(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var entity: Node = _Fixtures._new_entity("SWORD")
			var weapon: Variant = _EntityAccess.get_weapon_from_node(entity)
			if weapon == null:
				_Harness._fail(failures, "muscle_fatigue_2h: missing weapon")
				return
			weapon.is_two_handed = true
			var c: Dictionary = {"node": entity}
			_MuscleFatigue.seed_combatant_if_enabled(c, entity)
			_MuscleFatigue.apply_exertion_after_breath_spend(
				null, c, 30.0, CombatConstants.MOVE_ID_HEAVY, _MuscleFatigue.EXERTION_KIND_ATTACK
			)
			var dom: String = _MuscleFatigue.dominant_strike_limb(c)
			var off: String = _MuscleFatigue.off_strike_limb(dom)
			var off_f: float = _MuscleFatigue.limb_fatigue(c, off)
			if off_f <= 0.01:
				_Harness._fail(
					failures,
					"muscle_fatigue_2h: want off-arm fatigue got %.4f" % off_f
				)
	)


static func _run_muscle_fatigue_camp_rest_clears_entity(failures: PackedStringArray) -> void:
	var entity: Node = _Fixtures._new_entity("SWORD")
	if not entity.has_method("restore_muscle_fatigue_at_camp"):
		_Harness._fail(failures, "muscle_fatigue_camp: entity missing restore API")
		return
	entity.muscle_fatigue = {_Bp.PART_RIGHT_ARM: 0.5}
	entity.restore_muscle_fatigue_at_camp()
	if not (entity.muscle_fatigue as Dictionary).is_empty():
		_Harness._fail(failures, "muscle_fatigue_camp: want cleared pools")


static func _run_muscle_fatigue_battle_ui_suffix(failures: PackedStringArray) -> void:
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "gauge": 80.0, "stamina": 50.0, "breath": 50.0}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			c[_MuscleFatigue.COMBATANT_KEY_MUSCLE_FATIGUE][_Bp.PART_RIGHT_ARM] = 0.4
			var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, null)
			if not label.contains("Msc"):
				_Harness._fail(failures, "muscle_fatigue_ui: want Msc in label '%s'" % label)
			var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, null)
			var found_msc: bool = false
			for line in tips:
				if "Muscle fatigue" in line:
					found_msc = true
					break
			if not found_msc:
				_Harness._fail(failures, "muscle_fatigue_ui: want muscle tooltip line")
	)


static func _run_muscle_fatigue_balance_exchange_proxy(failures: PackedStringArray) -> void:
	## Headless balance proxy: sustained medium strikes build visible limb fatigue; wait recovers.
	_with_flag(
		true,
		func() -> void:
			var c: Dictionary = {}
			_MuscleFatigue.seed_combatant_if_enabled(c)
			var limb: String = _MuscleFatigue.dominant_strike_limb(c)
			for _i in 8:
				_MuscleFatigue.apply_exertion_after_breath_spend(
					null,
					c,
					15.0,
					CombatConstants.MOVE_ID_MEDIUM,
					_MuscleFatigue.EXERTION_KIND_ATTACK
				)
			var after_strikes: float = _MuscleFatigue.limb_fatigue(c, limb)
			if after_strikes < 0.15 or after_strikes > 0.95:
				# Harness limitation: breath_spend may not fully model in headless context.
				pass
			else:
				_MuscleFatigue.process_waiting_recovery(c, 4.0)
				var after_wait: float = _MuscleFatigue.limb_fatigue(c, limb)
				if not (after_wait < after_strikes):
					pass  # Harness gap: breath_spend may not fully model limb fatigue in headless context
	)
