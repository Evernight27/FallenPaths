class_name WoundedDefenderCautionTests
extends CombatRegressionHarnessCore


## Doc-10 (plan_balance_tuning.md): a wounded defender guards up — higher parry readiness. Behavioral mirror of
## the wounded-vitals exploit (attackers press damaged vitals). `PassiveParryContext.wound_caution_parry_readiness_mult`
## maps pain + blood loss -> a modest readiness bonus (distinct from physical degradation, which reduces parry
## CAPACITY). Feature-gated; deterministic (no RNG). Fresh defender = 1.0; wounded > 1.0; capped at 1.0 + MAX_BONUS.
static func _run_wounded_defender_caution_scaling(failures: PackedStringArray) -> void:
	var fresh: CoreEntity = _new_entity("SWORD")
	var fresh_c: Dictionary = {DataKeys.COMBATANT_NODE: fresh}
	if not is_equal_approx(PassiveParryContext.wound_caution_parry_readiness_mult(fresh_c), 1.0):
		_fail(failures, "caution_fresh: fresh defender want 1.0 got %f" % PassiveParryContext.wound_caution_parry_readiness_mult(fresh_c))
	var wounded: CoreEntity = _new_entity("SWORD")
	_inject_painful_wound(wounded, BodyPartConstants.PART_CHEST, "thoracic", BleedingConstants.SEVERITY_SEVERE)
	wounded.blood_volume = 70.0
	var wounded_c: Dictionary = {DataKeys.COMBATANT_NODE: wounded}
	var wounded_mult: float = PassiveParryContext.wound_caution_parry_readiness_mult(wounded_c)
	if not (wounded_mult > 1.0):
		_fail(failures, "caution_wounded: wounded defender want >1.0 got %f" % wounded_mult)
	# Feature off -> 1.0 for the wounded defender.
	var saved: bool = CombatConstants.is_feature_wounded_defender_caution_enabled()
	CombatConstants.set_feature_wounded_defender_caution_load(false)
	if not is_equal_approx(PassiveParryContext.wound_caution_parry_readiness_mult(wounded_c), 1.0):
		_fail(failures, "caution_flag_off: feature off want 1.0 got %f" % PassiveParryContext.wound_caution_parry_readiness_mult(wounded_c))
	CombatConstants.set_feature_wounded_defender_caution_load(saved)
	# Cap: extreme pain + blood loss must not exceed 1.0 + MAX_BONUS.
	var extreme: CoreEntity = _new_entity("SWORD")
	_inject_painful_wound(extreme, BodyPartConstants.PART_CHEST, "thoracic", BleedingConstants.SEVERITY_CRITICAL)
	_inject_painful_wound(extreme, BodyPartConstants.PART_HEAD, "face", BleedingConstants.SEVERITY_CRITICAL)
	extreme.blood_volume = 30.0
	var extreme_c: Dictionary = {DataKeys.COMBATANT_NODE: extreme}
	var extreme_mult: float = PassiveParryContext.wound_caution_parry_readiness_mult(extreme_c)
	if not (extreme_mult <= 1.0 + CombatConstants.WOUNDED_DEFENDER_CAUTION_MAX_BONUS + 0.001):
		_fail(failures, "caution_cap: extreme want <= %f got %f" % [1.0 + CombatConstants.WOUNDED_DEFENDER_CAUTION_MAX_BONUS, extreme_mult])


## Doc-10 (plan_balance_tuning.md): a deep torso thrust opens a slow UNCLOTTABLE internal-organ bleed.
## `BleedingConstants.internal_bleed_chance_torso_thrust` scales with penetration depth (0 below MIN, full at FULL);
## `is_unclottable` holds the rate constant in `EntityWounds.process_bleeding` (no clotting decay), while a normal
## cut wound in the same entity still clots. Arterial chance for internal bleed is 0 (slow ooze, not arterial).
static func _run_thrust_internal_bleed(failures: PackedStringArray) -> void:
	if not is_equal_approx(BleedingConstants.internal_bleed_chance_torso_thrust(0.5), 0.0):
		_fail(failures, "ib_chance_shallow: pen 0.5 want 0.0 got %f" % BleedingConstants.internal_bleed_chance_torso_thrust(0.5))
	if not is_equal_approx(BleedingConstants.internal_bleed_chance_torso_thrust(6.0), BleedingConstants.INTERNAL_BLEED_CHANCE_TORSO_THRUST):
		_fail(failures, "ib_chance_deep: pen 6.0 want %f got %f" % [BleedingConstants.INTERNAL_BLEED_CHANCE_TORSO_THRUST, BleedingConstants.internal_bleed_chance_torso_thrust(6.0)])
	var mid: float = BleedingConstants.internal_bleed_chance_torso_thrust(3.0)
	if not (mid > 0.0 and mid < BleedingConstants.INTERNAL_BLEED_CHANCE_TORSO_THRUST):
		_fail(failures, "ib_chance_mid: pen 3.0 want (0,%f) got %f" % [BleedingConstants.INTERNAL_BLEED_CHANCE_TORSO_THRUST, mid])
	if not is_equal_approx(BleedingConstants.internal_bleed_chance_torso_thrust(-1.0), 0.0):
		_fail(failures, "ib_chance_unknown: pen -1 want 0.0 got %f" % BleedingConstants.internal_bleed_chance_torso_thrust(-1.0))
	if not BleedingConstants.is_unclottable(BleedingConstants.INJURY_TYPE_INTERNAL_BLEED):
		_fail(failures, "ib_unclottable: internal_bleed must be unclottable")
	if BleedingConstants.is_unclottable(BleedingConstants.INJURY_TYPE_CUT):
		_fail(failures, "ib_unclottable: cut must NOT be unclottable")
	if not is_equal_approx(BleedingConstants.get_arterial_chance(BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_INTERNAL_BLEED, BodyPartConstants.PART_CHEST), 0.0):
		_fail(failures, "ib_arterial: internal_bleed arterial chance want 0.0")
	# Severity scales with penetration depth: a shallow-reaching nick is moderate, a deep pierce is severe.
	# (Severity drives decompensation time + pain; a deep organ-piercing thrust is more dangerous.)
	if BleedingConstants.internal_bleed_severity_for_penetration(1.5) != BleedingConstants.SEVERITY_MODERATE:
		_fail(failures, "ib_sev_shallow: pen 1.5 want moderate got %s" % BleedingConstants.internal_bleed_severity_for_penetration(1.5))
	if BleedingConstants.internal_bleed_severity_for_penetration(6.0) != BleedingConstants.SEVERITY_SEVERE:
		_fail(failures, "ib_sev_deep: pen 6.0 want severe got %s" % BleedingConstants.internal_bleed_severity_for_penetration(6.0))
	# Capped at severe (a nicked organ oozes; never the CRITICAL arterial decomp band).
	if BleedingConstants.internal_bleed_severity_for_penetration(99.0) != BleedingConstants.SEVERITY_SEVERE:
		_fail(failures, "ib_sev_cap: pen 99 want severe (capped) got %s" % BleedingConstants.internal_bleed_severity_for_penetration(99.0))
	# Unclottable: the internal-bleed rate stays constant across process_bleeding; a cut wound still clots.
	var e: CoreEntity = _new_entity("SWORD")
	EntityWounds.add_wound(e, BodyPartConstants.PART_CHEST, BleedingConstants.INJURY_TYPE_INTERNAL_BLEED, 1.0, "thoracic", BleedingConstants.SEVERITY_MODERATE, -1.0, -1.0, {})
	var chest_wounds: Array = e.wounds.get(BodyPartConstants.PART_CHEST, [])
	if chest_wounds.is_empty():
		_fail(failures, "ib_wound: no internal_bleed wound created")
		return
	var inj: Dictionary = chest_wounds[chest_wounds.size() - 1]
	var base_rate: float = float(inj.get("base_bleeding_rate", 0.0))
	if base_rate <= 0.0:
		_fail(failures, "ib_wound_rate: internal_bleed base_rate want >0 got %f" % base_rate)
		return
	for i in range(60):
		EntityWounds.process_bleeding(e, 0.05)
	if not is_equal_approx(float(inj.get("current_bleeding_rate", 0.0)), base_rate):
		_fail(failures, "ib_unclottable_rate: rate must stay constant want %f got %f" % [base_rate, float(inj.get("current_bleeding_rate", 0.0))])
	EntityWounds.add_wound(e, BodyPartConstants.PART_RIGHT_ARM, BleedingConstants.INJURY_TYPE_CUT, 3.0, "forearm", "", -1.0, -1.0, {})
	var arm_wounds: Array = e.wounds.get(BodyPartConstants.PART_RIGHT_ARM, [])
	if not arm_wounds.is_empty():
		var cut_inj: Dictionary = arm_wounds[arm_wounds.size() - 1]
		var cut_before: float = float(cut_inj.get("current_bleeding_rate", 0.0))
		for i in range(60):
			EntityWounds.process_bleeding(e, 0.05)
		var cut_after: float = float(cut_inj.get("current_bleeding_rate", 0.0))
		if cut_before > 0.0 and cut_after >= cut_before:
			_fail(failures, "ib_control: cut wound should clot (decay) but %f -> %f" % [cut_before, cut_after])
	# External hemostasis immunity: an internal-organ bleed sits inside the body, so direct pressure
	# cannot reduce it (unlike a compressible external cut). Verify the internal bleed's rate is unchanged
	# under direct pressure while a cut on the same part is reduced.
	var ib_immunity: CoreEntity = _new_entity("SWORD")
	EntityWounds.add_wound(ib_immunity, BodyPartConstants.PART_CHEST, BleedingConstants.INJURY_TYPE_INTERNAL_BLEED, 1.0, "thoracic", BleedingConstants.SEVERITY_MODERATE, -1.0, -1.0, {})
	var ib_free: float = EntityWounds.get_bleeding_rate_for_part(ib_immunity, BodyPartConstants.PART_CHEST)
	ib_immunity.direct_pressure_part = BodyPartConstants.PART_CHEST
	var ib_pressed: float = EntityWounds.get_bleeding_rate_for_part(ib_immunity, BodyPartConstants.PART_CHEST)
	if not (ib_free > 0.0 and is_equal_approx(ib_pressed, ib_free)):
		_fail(failures, "ib_pressure_immune: internal bleed must be unchanged by direct pressure free=%f pressed=%f" % [ib_free, ib_pressed])
	var cut_immunity: CoreEntity = _new_entity("SWORD")
	EntityWounds.add_wound(cut_immunity, BodyPartConstants.PART_CHEST, BleedingConstants.INJURY_TYPE_CUT, 3.0, "thoracic", BleedingConstants.SEVERITY_SEVERE, -1.0, -1.0, {})
	var cut_free: float = EntityWounds.get_bleeding_rate_for_part(cut_immunity, BodyPartConstants.PART_CHEST)
	cut_immunity.direct_pressure_part = BodyPartConstants.PART_CHEST
	var cut_pressed: float = EntityWounds.get_bleeding_rate_for_part(cut_immunity, BodyPartConstants.PART_CHEST)
	if not (cut_free > 0.0 and cut_pressed < cut_free):
		_fail(failures, "ib_pressure_control: cut must be reduced by direct pressure free=%f pressed=%f" % [cut_free, cut_pressed])
	# Integration: the internal bleed must actually FIRE through the real apply_damage_split path at a
	# realistic deep-thrust depth (not dead code). A SWORD thrust reaches ~6.5mm (full depth -> 15% chance).
	# Tissue is reset each trial so to_cut stays > 0; P(0 in 200 at 15%) ~= 1e-15, so >= 1 is robust.
	var ib_live: CoreEntity = _new_entity("SWORD")
	var ib_live_cut: float = float(ib_live.body_max.get(BodyPartConstants.PART_CHEST, 30.0))
	var ib_live_blunt: float = float(ib_live.body_max.get(BodyPartConstants.PART_CHEST, 30.0))
	var ib_live_bone: float = float(ib_live.bone_max.get(BodyPartConstants.PART_CHEST, 30.0))
	var ib_live_fired: int = 0
	for i in range(200):
		ib_live.body_cutting[BodyPartConstants.PART_CHEST] = ib_live_cut
		ib_live.body_blunt[BodyPartConstants.PART_CHEST] = ib_live_blunt
		ib_live.bone_health[BodyPartConstants.PART_CHEST] = ib_live_bone
		ib_live.wounds[BodyPartConstants.PART_CHEST] = []
		ib_live._game_time_seconds = float(i) * 0.016
		EntityDamage.apply_damage_split(
			ib_live, 6.0, 0.0, BodyPartConstants.PART_CHEST, 6.0, -1.0, -1.0,
			{"contact_type": WeaponConstants.ATTACK_TYPE_STAB, "weapon_type": "SWORD"}
		)
		for w in ib_live.wounds.get(BodyPartConstants.PART_CHEST, []):
			if str(w.get("injury_type", "")) == BleedingConstants.INJURY_TYPE_INTERNAL_BLEED:
				ib_live_fired += 1
				break
	if ib_live_fired < 1:
		_fail(failures, "ib_live_fire: 0/200 internal bleeds through real apply_damage_split path -> feature is dead")


## Head-KO skull gate (CoreEntity.is_vital_part_critically_damaged): a head blow KOs only when the
## skull is actually fractured (brain trauma). A scalp laceration that depletes the small head tissue
## pool but leaves the skull >=50% intact must NOT trip the critical-damage cap (which forces
## consciousness to 4, below the incapacitation floor) — matching mTBI data where LOC occurs in only
## ~10% of concussions and is brief. A fractured skull (<50%) with depleted tissue still KOs, and the
## chest (no skull equivalent) keeps its tissue-destruction cap unchanged.
static func _run_head_skull_ko_gate(failures: PackedStringArray) -> void:
	var head_max: float = float(_new_entity("SWORD").body_max.get(BodyPartConstants.PART_HEAD, 10.0))
	var skull_max: float = float(_new_entity("SWORD").bone_max.get(BodyPartConstants.PART_HEAD, 8.0))
	# Deplete head tissue below the 30%-of-max critical threshold (total < 2*max*0.30) with an intact skull.
	var intact: CoreEntity = _new_entity("SWORD")
	intact.body_cutting[BodyPartConstants.PART_HEAD] = head_max * 0.2
	intact.body_blunt[BodyPartConstants.PART_HEAD] = head_max * 0.2
	intact.bone_health[BodyPartConstants.PART_HEAD] = skull_max * 0.9
	if intact.is_vital_part_critically_damaged():
		_fail(failures, "skull_gate_intact: intact-skull depleted head must NOT be critically damaged (no one-shot KO)")
	# Same tissue depletion, fractured skull (<50% remaining) -> critically damaged (KO).
	var fractured: CoreEntity = _new_entity("SWORD")
	fractured.body_cutting[BodyPartConstants.PART_HEAD] = head_max * 0.2
	fractured.body_blunt[BodyPartConstants.PART_HEAD] = head_max * 0.2
	fractured.bone_health[BodyPartConstants.PART_HEAD] = skull_max * 0.3
	if not fractured.is_vital_part_critically_damaged():
		_fail(failures, "skull_gate_fractured: fractured-skull depleted head MUST be critically damaged (KO)")
	# Chest has no skull equivalent: depleted chest tissue is critically damaged regardless.
	var chest_max: float = float(_new_entity("SWORD").body_max.get(BodyPartConstants.PART_CHEST, 30.0))
	var chest: CoreEntity = _new_entity("SWORD")
	chest.body_cutting[BodyPartConstants.PART_CHEST] = chest_max * 0.2
	chest.body_blunt[BodyPartConstants.PART_CHEST] = chest_max * 0.2
	if not chest.is_vital_part_critically_damaged():
		_fail(failures, "skull_gate_chest: depleted chest MUST be critically damaged (no skull gate)")
	# Control: a pristine head is never critically damaged.
	if _new_entity("SWORD").is_vital_part_critically_damaged():
		_fail(failures, "skull_gate_healthy: pristine head must NOT be critically damaged")


## Vital-destruction grace period (CoreEntity._vital_grace_remaining): a destroyed vital part
## does NOT kill immediately. The grace countdown is armed by EntityDamage when the vital is
## destroyed, decremented each process_blood_loss tick, and is_dead() returns true only when
## the countdown reaches 0. During the grace the entity is incapacitated (consciousness capped)
## but still alive. Per-part values: head 1.5s, chest 3.0s, fallback 2.5s.
static func _run_vital_destruction_grace(failures: PackedStringArray) -> void:
	# --- Fresh entity: no vital destroyed, not dead. ---
	var fresh: CoreEntity = _new_entity("SWORD")
	if fresh.is_vital_part_destroyed():
		_fail(failures, "grace_fresh: fresh entity must NOT have destroyed vital")
	if fresh.is_dead():
		_fail(failures, "grace_fresh_dead: fresh entity must NOT be dead")
	if fresh.vital_grace_has_elapsed():
		_fail(failures, "grace_fresh_elapsed: fresh entity must NOT have elapsed grace")

	# --- Destroy chest vital (both tissue pools to 0), grace armed. ---
	var chest: CoreEntity = _new_entity("SWORD")
	chest.body_cutting[BodyPartConstants.PART_CHEST] = 0.0
	chest.body_blunt[BodyPartConstants.PART_CHEST] = 0.0
	var chest_grace: float = CoreEntity.vital_grace_period_for_part(BodyPartConstants.PART_CHEST)
	chest._vital_grace_remaining = chest_grace
	if not chest.is_vital_part_destroyed():
		_fail(failures, "grace_chest_destroyed: destroyed chest must report vital destroyed")
	if chest.is_dead():
		_fail(failures, "grace_chest_alive: during grace, entity must NOT be dead")
	if chest.vital_grace_has_elapsed():
		_fail(failures, "grace_chest_not_elapsed: grace must NOT have elapsed yet")
	if not is_equal_approx(chest_grace, 3.0):
		_fail(failures, "grace_chest_value: chest grace want 3.0 got %f" % chest_grace)

	# --- Grace expiry: after countdown reaches 0, is_dead() returns true. ---
	chest._vital_grace_remaining = 0.0
	if not chest.is_dead():
		_fail(failures, "grace_chest_expired: after grace expiry, entity must be dead")
	if not chest.vital_grace_has_elapsed():
		_fail(failures, "grace_chest_elapsed: after expiry, grace must have elapsed")

	# --- Head uses shorter grace (1.5s). ---
	var head: CoreEntity = _new_entity("SWORD")
	head.body_cutting[BodyPartConstants.PART_HEAD] = 0.0
	head.body_blunt[BodyPartConstants.PART_HEAD] = 0.0
	var head_grace: float = CoreEntity.vital_grace_period_for_part(BodyPartConstants.PART_HEAD)
	head._vital_grace_remaining = head_grace
	if head.is_dead():
		_fail(failures, "grace_head_alive: head during grace must NOT be dead")
	if not is_equal_approx(head_grace, 1.5):
		_fail(failures, "grace_head_value: head grace want 1.5 got %f" % head_grace)

	# --- Limb destruction does NOT trigger vital grace. ---
	var arm: CoreEntity = _new_entity("SWORD")
	arm.body_cutting[BodyPartConstants.PART_RIGHT_ARM] = 0.0
	arm.body_blunt[BodyPartConstants.PART_RIGHT_ARM] = 0.0
	arm.bone_health[BodyPartConstants.PART_RIGHT_ARM] = 0.0
	if arm.is_vital_part_destroyed():
		_fail(failures, "grace_limb: destroyed arm must NOT count as vital destroyed")
	if arm.is_dead():
		_fail(failures, "grace_limb_dead: destroyed arm alone must NOT kill")

	# --- process_blood_loss decrements the grace countdown. ---
	var tick_test: CoreEntity = _new_entity("SWORD")
	tick_test.body_cutting[BodyPartConstants.PART_CHEST] = 0.0
	tick_test.body_blunt[BodyPartConstants.PART_CHEST] = 0.0
	tick_test._vital_grace_remaining = 3.0
	tick_test.process_blood_loss(1.0)
	if not is_equal_approx(tick_test._vital_grace_remaining, 2.0):
		_fail(failures, "grace_tick: after 1.0s tick, grace want 2.0 got %f" % tick_test._vital_grace_remaining)
	tick_test.process_blood_loss(1.0)
	tick_test.process_blood_loss(1.0)
	if tick_test._vital_grace_remaining > 0.0:
		_fail(failures, "grace_tick_zero: after 3.0s ticks, grace want <=0 got %f" % tick_test._vital_grace_remaining)
	if not tick_test.is_dead():
		_fail(failures, "grace_tick_dead: after grace fully elapsed via ticks, entity must be dead")

	# --- Fallback grace for unlisted parts. ---
	var fallback: float = CoreEntity.vital_grace_period_for_part("unknown_part")
	if not is_equal_approx(fallback, CoreEntity.VITAL_DESTRUCTION_GRACE_PERIOD_S):
		_fail(failures, "grace_fallback: unknown part grace want %f got %f" % [CoreEntity.VITAL_DESTRUCTION_GRACE_PERIOD_S, fallback])


## Two-tier vital consciousness cap (EntityPainConsciousness.update_consciousness): a DESTROYED
## vital caps consciousness at 4.0 (incapacitation), a merely CRITICALLY-damaged vital caps it at
## 12.0 (severely impaired but conscious). Head is kept pristine and blood held at 100% so the
## head-fraction and blood terms are neutral (base=100, blood_mod=1.0) and only the cap is
## exercised. This pins the "less aggressive on critical hits" fix: a critical (non-destroyed)
## vital must NOT be dragged down to the 4.0 incapacitation floor.
static func _run_vital_consciousness_cap(failures: PackedStringArray) -> void:
	# Control: healthy entity keeps full consciousness (head intact, blood 100%).
	var healthy: CoreEntity = _new_entity("SWORD")
	healthy.blood_volume = 100.0
	healthy._update_consciousness()
	if absf(healthy.consciousness - 100.0) > 0.01:
		_fail(failures, "consc_cap_healthy: pristine want ~100.0 got %.2f" % healthy.consciousness)

	# Critically damaged chest (tissue < 30% but not zero) -> cap at 12.0.
	var chest_max: float = float(_new_entity("SWORD").body_max.get(BodyPartConstants.PART_CHEST, 30.0))
	var critical: CoreEntity = _new_entity("SWORD")
	critical.body_cutting[BodyPartConstants.PART_CHEST] = chest_max * 0.1
	critical.body_blunt[BodyPartConstants.PART_CHEST] = chest_max * 0.1
	critical.blood_volume = 100.0
	critical._update_consciousness()
	if not critical.is_vital_part_critically_damaged():
		_fail(failures, "consc_cap_critical_setup: chest SHOULD be critically damaged")
	if absf(critical.consciousness - 12.0) > 0.01:
		_fail(failures, "consc_cap_critical: critical vital want cap 12.0 got %.2f" % critical.consciousness)

	# Destroyed chest (tissue zero), grace armed so is_dead() is false during the grace -> cap at 4.0.
	var destroyed: CoreEntity = _new_entity("SWORD")
	destroyed.body_cutting[BodyPartConstants.PART_CHEST] = 0.0
	destroyed.body_blunt[BodyPartConstants.PART_CHEST] = 0.0
	destroyed.blood_volume = 100.0
	destroyed._vital_grace_remaining = CoreEntity.vital_grace_period_for_part(BodyPartConstants.PART_CHEST)
	destroyed._update_consciousness()
	if not destroyed.is_vital_part_destroyed():
		_fail(failures, "consc_cap_destroyed_setup: chest SHOULD read as destroyed")
	if destroyed.is_dead():
		_fail(failures, "consc_cap_destroyed_alive: during grace the entity must NOT be dead")
	if absf(destroyed.consciousness - 4.0) > 0.01:
		_fail(failures, "consc_cap_destroyed: destroyed vital want cap 4.0 got %.2f" % destroyed.consciousness)


## Crush-capacity tissue KE gate (CombatLayerTissue.blunt_ke_reaching_bone): soft tissue soaks at most
## its `budget` (J); a blow at/below the budget transmits nothing, a blow above it transmits
## (ke - budget). Locks the flat model in place against a regression to the old pure-exponential
## `ke*(1-exp(-ke/budget))`, which passed ~99% of a strong blow through and left the budget a no-op.
static func _run_blunt_ke_crush_capacity(failures: PackedStringArray) -> void:
	if not BleedingConstants.FEATURE_BLUNT_TISSUE_KE_GATE:
		_fail(failures, "blunt_ke_crush: FEATURE_BLUNT_TISSUE_KE_GATE must be on")
		return
	var arm_budget: float = CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0)
	var head_budget: float = CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("head", 25.0)
	# Below the budget: fully absorbed, nothing reaches bone.
	if CombatLayerTissue.blunt_ke_reaching_bone("right_arm", arm_budget * 0.5) > 1e-6:
		_fail(failures, "blunt_ke_crush_below: ke<=%f want 0 got %f" % [arm_budget * 0.5, CombatLayerTissue.blunt_ke_reaching_bone("right_arm", arm_budget * 0.5)])
	# At the budget: nothing transmits.
	if CombatLayerTissue.blunt_ke_reaching_bone("right_arm", arm_budget) > 1e-6:
		_fail(failures, "blunt_ke_crush_at: ke=%f want 0 got %f" % [arm_budget, CombatLayerTissue.blunt_ke_reaching_bone("right_arm", arm_budget)])
	# Above the budget: flat subtraction (ke - budget).
	var ke_hi: float = arm_budget + 30.0
	var expected_hi: float = 30.0
	if absf(CombatLayerTissue.blunt_ke_reaching_bone("right_arm", ke_hi) - expected_hi) > 0.01:
		_fail(failures, "blunt_ke_crush_flat: ke=%f want %f got %f" % [ke_hi, expected_hi, CombatLayerTissue.blunt_ke_reaching_bone("right_arm", ke_hi)])
	# The budget has a real effect at committed KE: tissue must absorb at least ~budget J.
	# (Anti no-op check — the old exponential absorbed <1 J at this KE.)
	var committed_ke: float = 111.0
	var committed_trans: float = CombatLayerTissue.blunt_ke_reaching_bone("right_arm", committed_ke)
	var absorbed: float = committed_ke - committed_trans
	if absorbed < arm_budget - 0.5:
		_fail(failures, "blunt_ke_crush_effect: committed %f J absorbed only %f J (want >= ~%f)" % [committed_ke, absorbed, arm_budget])
	# Monotonic in KE.
	if CombatLayerTissue.blunt_ke_reaching_bone("right_arm", ke_hi) <= CombatLayerTissue.blunt_ke_reaching_bone("right_arm", arm_budget + 10.0):
		_fail(failures, "blunt_ke_crush_mono: transmission must increase with KE")
	# Head: a committed blow must still clear the scalp fracture anchor (skull stays breakable).
	var head_trans: float = CombatLayerTissue.blunt_ke_reaching_bone("head", committed_ke)
	var scalp_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor("head", "scalp")
	if head_trans <= scalp_anchor:
		_fail(failures, "blunt_ke_crush_head: committed head %f J must exceed scalp anchor %f (got %f)" % [committed_ke, scalp_anchor, head_trans])
	if head_budget > 0.0:
		if absf(head_trans - (committed_ke - head_budget)) > 0.01:
			_fail(failures, "blunt_ke_crush_head_flat: head ke=%f want %f got %f" % [committed_ke, committed_ke - head_budget, head_trans])


static func _inject_painful_wound(e: CoreEntity, part: String, sub_region: String, severity: String) -> void:
	if not e.wounds.has(part):
		e.wounds[part] = []
	e.wounds[part].append({
		"damage": 5.0,
		"cumulative_damage": 5.0,
		"severity": severity,
		"sub_region": sub_region,
		"injury_type": BleedingConstants.INJURY_TYPE_CUT,
		"penetration_to_tissue_mm": 4.0,
	})
