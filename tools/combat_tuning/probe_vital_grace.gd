extends SceneTree

## Headless probe: confirm the vital-destruction grace period works end-to-end through the REAL
## damage path (take_damage_split) -> grace armed -> per-tick countdown -> is_dead() flips true.
## Also confirms a destroyed LIMB does NOT arm the grace or kill via the vital path.
## Run: Godot --headless --path . -s res://tools/combat_tuning/probe_vital_grace.gd

const _Helpers := preload("res://harness/d001/D001RunnerHelpers.gd")

const HEAD: String = "head"
const CHEST: String = "chest"
const ARM: String = "right_arm"
const TICK: float = 0.05
const MAX_T: float = 6.0


func _init() -> void:
	# --- Single CUT blow: empties the cut channel only; the vital must NOT be destroyed
	# --- (blunt/bone survive) so no grace arms. This is the "less binary" behavior: a single
	# --- sword cut to the head is a heavy wound, not a KO/death.
	var cut_ent: CoreEntity = _Helpers._new_entity("SWORD")
	cut_ent.take_damage_split(500.0, 0.0, HEAD, 10.0, 0.0, 0.0, {})
	print(
		"PROBE_CUT_ONLY cut=%.2f blunt=%.2f destroyed=%s grace=%.3f is_dead=%s"
		% [float(cut_ent.body_cutting.get(HEAD, 0.0)), float(cut_ent.body_blunt.get(HEAD, 0.0)), str(cut_ent.is_vital_part_destroyed()), float(cut_ent._vital_grace_remaining), str(cut_ent.is_dead())]
	)

	# --- Heavy blow (cut AND blunt): drives both channels to zero -> vital destroyed, grace arms.
	# --- Head: real damage path destroys the vital, grace must arm.
	var head_ent: CoreEntity = _Helpers._new_entity("SWORD")
	var head_max: float = float(head_ent.body_max.get(HEAD, 0.0))
	head_ent.take_damage_split(500.0, 500.0, HEAD, 10.0, 0.0, 0.0, {})
	_probe_vital(head_ent, HEAD, head_max)

	# --- Chest: real damage path, grace must arm.
	var chest_ent: CoreEntity = _Helpers._new_entity("SWORD")
	var chest_max: float = float(chest_ent.body_max.get(CHEST, 0.0))
	chest_ent.take_damage_split(500.0, 500.0, CHEST, 10.0, 0.0, 0.0, {})
	_probe_vital(chest_ent, CHEST, chest_max)

	# --- Arm: destroyed limb must NOT arm grace or kill via the vital path.
	var arm_ent: CoreEntity = _Helpers._new_entity("SWORD")
	arm_ent.take_damage_split(500.0, 500.0, ARM, 10.0, 0.0, 0.0, {})
	print(
		"PROBE_ARM grace=%.3f vital_destroyed=%s is_dead=%s"
		% [float(arm_ent._vital_grace_remaining), str(arm_ent.is_vital_part_destroyed()), str(arm_ent.is_dead())]
	)

	quit(0)


func _probe_vital(ent: CoreEntity, part: String, max_val: float) -> void:
	var cut_after: float = float(ent.body_cutting.get(part, 0.0))
	var blunt_after: float = float(ent.body_blunt.get(part, 0.0))
	var grace: float = float(ent._vital_grace_remaining)
	var destroyed: bool = ent.is_vital_part_destroyed()
	print(
		"PROBE_%s max=%.2f after cut=%.2f blunt=%.2f destroyed=%s grace_armed=%.3f dead_during_grace=%s"
		% [part.to_upper(), max_val, cut_after, blunt_after, str(destroyed), grace, str(ent.is_dead())]
	)
	# Drive the countdown to expiry and confirm death registers.
	var t := 0.0
	while t < MAX_T and not ent.is_dead():
		ent.process_blood_loss(TICK)
		t += TICK
	print(
		"PROBE_%s after_t=%.2f is_dead=%s grace_remaining=%.3f death_reason=%s"
		% [part.to_upper(), t, str(ent.is_dead()), float(ent._vital_grace_remaining), ent._get_death_reason()]
	)
