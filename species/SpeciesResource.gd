extends Resource

class_name SpeciesResource

# Body part max health. Unit dies when head or chest reaches 0.
const BODY_PARTS := ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]
const VITAL_PARTS := ["head", "chest"]

# Basic stats for a species. These can be saved as .tres resources in res://species/
# Tissue max = abstract capacity per part. Defaults scaled from segment mass % (de Leva 1996, Plagenhoef 1983): head/arm ~7%/5%, chest/leg ~20%. See RESEARCH_BASED_APPROXIMATIONS.md.
@export var name: String = "Unknown"
@export var head: int = 12       # segment ~7%
@export var chest: int = 28     # thorax/trunk ~20%
@export var right_arm: int = 12
@export var left_arm: int = 12  # arm ~5% each
@export var left_leg: int = 28
@export var right_leg: int = 28 # leg ~20% each
# Bone max per part: abstract; scaled with tissue (larger segments = more bone mass).
@export var head_bone: int = 8
@export var chest_bone: int = 20
@export var right_arm_bone: int = 8
@export var left_arm_bone: int = 8
@export var left_leg_bone: int = 20
@export var right_leg_bone: int = 20
@export var strength: int = 1
@export var speed: int = 100
@export var description: String = ""

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
