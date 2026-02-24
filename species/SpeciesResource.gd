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
# Limb totals tuned for KE realism: arm 20 (100 J sever), leg 28 (200 J sever). See JOULES_FORCE_OPTIMAL_NUMBERS.md.
@export var right_arm: int = 12
@export var left_arm: int = 12
@export var left_leg: int = 16
@export var right_leg: int = 16
# Bone max: scale with tissue; larger segments = more bone. Keep proportions per species.
@export var head_bone: int = 8
@export var chest_bone: int = 22
@export var right_arm_bone: int = 8
@export var left_arm_bone: int = 8
@export var left_leg_bone: int = 12
@export var right_leg_bone: int = 12
# Core attributes (RimWorld-style: 100 = average, 50–150 range)
@export var strength: int = 8       # Damage, parry (Paths scale: ~1–10 for damage mod)
@export var agility: int = 100      # Gauge fill, dodge, cooldowns (50–150: 100 = average)
@export var intelligence: int = 100 # Medical effectiveness modifier (50–150)
@export var endurance: int = 100    # Damage resistance, pain shock resistance (50–150)
@export var perception: int = 100   # Dodge (not ranged accuracy) (50–150)
@export var description: String = ""

# Blood loss thresholds (0–100 remaining %). If < 0, use BleedingConstants defaults (death 35, critical 30).
# Lets different species be more/less tolerant: e.g. death at 40% = more fragile, 30% = more resilient.
@export var blood_loss_death_threshold: float = -1.0    # death when remaining <= this; -1 = use global default
@export var blood_loss_critical_threshold: float = -1.0  # critical state when remaining <= this; -1 = use global default

# Pain reference for normalized pain (Method B). Typical pain from 1 moderate hit for this species.
# Smaller species get higher severity per damage → more pain per hit. -1 = auto-compute from body proportions.
@export var pain_reference_scale: float = -1.0

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

## Typical pain from one moderate hit for this species. Used for normalized pain (Method B).
## Auto-computed from body_max sum when pain_reference_scale < 0. Human (sum 96) → ~3.
## Divisor 32: ~2 moderate hits to NRS 4 (first effect). Research: Krebs 4-6 band, acute trauma 57% NRS 5-10.
## See PAIN_MEDICAL_RESEARCH_SYNTHESIS.md.
func get_pain_reference(body_max_dict: Dictionary) -> float:
	var total: int = 0
	for p in BODY_PARTS:
		total += body_max_dict.get(p, 0)
	if total <= 0:
		return 6.0  # fallback
	var base_ref: float = float(total) / 32.0  # human 96 → ~3; ~2 moderate hits to first effect
	if pain_reference_scale > 0.0:
		return base_ref * pain_reference_scale
	return base_ref
