extends Resource

class_name SpeciesResource

# Body part max health. Unit dies when head or chest reaches 0.
const BODY_PARTS := ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]
const VITAL_PARTS := ["head", "chest"]

# Basic stats for a species. Save as .tres in res://species/
# Tissue max = abstract capacity per part. Give each species UNIQUE mass proportions so they play differently:
#   Human: segment-mass (de Leva/Plagenhoef) — chest > leg > head = arm.
#   Goblin: top-heavy, spindly limbs — large head/chest share, thin arms/legs.
#   (Future: e.g. Orc = limb-heavy; Elf = lean limbs, smaller chest.)
# See BALANCING_INVESTIGATION.md, RESEARCH_BASED_APPROXIMATIONS.md.
@export var name: String = "Unknown"
@export var head: int = 10       # human ~9% of total; goblin larger share
@export var chest: int = 30      # human largest; scale per species
@export var right_arm: int = 10
@export var left_arm: int = 10
@export var left_leg: int = 26
@export var right_leg: int = 26
# Bone max: scale with tissue; larger segments = more bone. Keep proportions per species.
@export var head_bone: int = 8
@export var chest_bone: int = 22
@export var right_arm_bone: int = 8
@export var left_arm_bone: int = 8
@export var left_leg_bone: int = 18
@export var right_leg_bone: int = 18
@export var strength: int = 1
@export var speed: int = 100
@export var description: String = ""

# Blood loss thresholds (0–100 remaining %). If < 0, use BleedingConstants defaults (death 35, critical 30).
# Lets different species be more/less tolerant: e.g. death at 40% = more fragile, 30% = more resilient.
@export var blood_loss_death_threshold: float = -1.0    # death when remaining <= this; -1 = use global default
@export var blood_loss_critical_threshold: float = -1.0  # critical state when remaining <= this; -1 = use global default

func get_body_part_max(part: String) -> int:
	match part:
		"head": return head
		"chest": return chest
		"right_arm": return right_arm
		"left_arm": return left_arm
		"left_leg": return left_leg
		"right_leg": return right_leg
	return 0

func get_bone_max(part: String) -> int:
	match part:
		"head": return head_bone
		"chest": return chest_bone
		"right_arm": return right_arm_bone
		"left_arm": return left_arm_bone
		"left_leg": return left_leg_bone
		"right_leg": return right_leg_bone
	return maxi(1, int(get_body_part_max(part) / 2.0))
