class_name EntitySeverance
extends RefCounted

## Severance math, extracted from **`EntityDamage`** (pure code-motion split).
## Pure functions over `entity: Node` + `part: String`: severance ease factor and
## per-part severance thresholds (species-scaled).

## Base minimum damage required for any severance attempt — raised from 10 to 28 based on clinical data:
## Traumatic blade amputation is biomechanically impossible; real dismemberment requires bone fracture + massive force.
const MIN_DAMAGE_TO_SEVER: int = 28

## Per-body-part minimum severance thresholds — models that different body regions require vastly different force.
## Head is most fragile (thin bone, vital structures); extremities are nearly impossible to amputate with blades alone.
## Clinical basis: traumatic dismemberment requires >200J cutting energy + sustained force; real battlefield amputations
## are almost always from blast/impaction trauma, not blade wounds. Values tuned for gameplay pacing while maintaining
## realism.
## Reference values scale against human tissue budgets (head=10, chest=30, arms=12, legs=16).
const SEVERANCE_MIN_DAMAGE_BY_PART: Dictionary = {
    "head": 25,  # Thin skull + vital structures — most fragile region
    "chest": 30,  # Rib cage + thoracic musculature — very difficult to sever through armor/bone
    "abdomen": 30,  # Soft tissue but deep organ protection — requires massive force
    "neck": 25,  # Thin structures but trachea/spine provide resistance; clinically fatal before severance
    "right_arm": 35,  # Humerus + biceps/triceps — traumatic amputation biomechanically impossible with blades
    "left_arm": 35,  # Same as right arm (non-dominant)
    "right_leg": 40,  # Femur is strongest bone in body; quadriceps/hamstrings provide massive tissue resistance
    "left_leg": 40,  # Same as left leg
}

const SEVERANCE_REFERENCE_TISSUE_BY_PART: Dictionary = {
    "head": 10.0,
    "chest": 30.0,
    "abdomen": 30.0,
    "neck": 10.0,
    "right_arm": 12.0,
    "left_arm": 12.0,
    "right_leg": 16.0,
    "left_leg": 16.0,
}

# Severance ease: full-health limb resists dismemberment; already wounded/bone-damaged parts give way more easily.
## Overall ease range: 1.0 (healthy) to 1.8 (max). Each wound adds SEVERANCE_EASE_PER_WOUND=3% to the base factor.
## Severity bonus scales by clinical trauma tier — tuned for gameplay feel rather than direct clinical mapping:
## minor (superficial): no bonus, moderate (fat/muscle only): +5%, severe (deep fascia/tendon): +12%, critical
## (bone/joint): +20%.
const SEVERANCE_EASE_MAX: float = 1.8

const SEVERANCE_EASE_TISSUE_FACTOR: float = 0.4

const SEVERANCE_EASE_BONE_FACTOR: float = 0.3

const SEVERANCE_EASE_PER_WOUND: float = 0.03

const SEVERANCE_EASE_WOUND_CAP: float = 0.12

const SEVERANCE_EASE_SEVERITY_BONUS: Dictionary = {"minor": 0.0, "moderate": 0.05, "severe": 0.12, "critical": 0.20}


static func get_severance_ease_factor(entity: Node, part: String) -> float:
    var max_tissue: int = entity.body_max.get(part, 1)
    var max_bone: int = entity.bone_max.get(part, 1)
    if max_tissue <= 0 or max_bone <= 0:
        return 1.0
    var cur_cut: float = entity.body_cutting.get(part, 0.0)
    var cur_blunt: float = entity.body_blunt.get(part, 0.0)
    var cur_bone: float = entity.bone_health.get(part, 0.0)
    var tissue_ratio: float = (cur_cut + cur_blunt) / float(maxi(1, max_tissue * 2))
    var bone_ratio: float = cur_bone / float(max_bone)
    var wound_count: int = entity.wounds.get(part, []).size()
    var wound_factor: float = minf(float(wound_count) * SEVERANCE_EASE_PER_WOUND, SEVERANCE_EASE_WOUND_CAP)
    var worst_sev: String = BleedingConstants.SEVERITY_MINOR
    for injury in entity.wounds.get(part, []):
        var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MINOR)
        var order: Array = [
            BleedingConstants.SEVERITY_MINOR,
            BleedingConstants.SEVERITY_MODERATE,
            BleedingConstants.SEVERITY_SEVERE,
            BleedingConstants.SEVERITY_CRITICAL
        ]
        if order.find(sev) > order.find(worst_sev):
            worst_sev = sev
    var severity_bonus: float = SEVERANCE_EASE_SEVERITY_BONUS.get(worst_sev, 0.0)
    # A part carrying a wound-derived scar severs more easily — scar tissue shears at ~70-80% of
    # normal tensile strength (same anchor as SCAR_REINJURY_MULT). One small bonus, capped at
    # SEVERANCE_EASE_MAX in the sum below. (A severed part returns early in apply_damage_split and
    # never reaches this, so its amputated_limb scar never feeds here.)
    var scar_ease: float = 0.0
    if "campaign_afflictions" in entity:
        for raw in entity.campaign_afflictions:
            if raw is Dictionary and str(raw.get("part", "")) == part and part != "":
                scar_ease = BleedingConstants.SCAR_SEVERANCE_EASE_BONUS
                break
    var severance_ease: float = (
        1.0
        + (1.0 - tissue_ratio) * SEVERANCE_EASE_TISSUE_FACTOR
        + (1.0 - bone_ratio) * SEVERANCE_EASE_BONE_FACTOR
        + wound_factor
        + severity_bonus
        + scar_ease
    )
    return clampf(severance_ease, 1.0, SEVERANCE_EASE_MAX)


static func _get_severance_threshold_for_part(part: String) -> float:
    """Returns minimum damage to attempt severance for a specific body part.
    Traumatic blade amputation is biomechanically impossible — real dismemberment requires bone fracture
    + massive force from blast/impaction trauma, not cutting weapons.
    Extremities (arms/legs) have highest thresholds."""
    if SEVERANCE_MIN_DAMAGE_BY_PART.has(part):
        return float(SEVERANCE_MIN_DAMAGE_BY_PART[part])
    return float(MIN_DAMAGE_TO_SEVER)


static func _get_severance_threshold_for_part_entity_aware(entity: Node, part: String) -> float:
    """Returns minimum damage to attempt severance for a specific body part, scaled by species tissue budget.
    Scales thresholds proportionally so smaller species don't require human-scale damage to trigger severance."""
    var base_threshold: float = _get_severance_threshold_for_part(part)
    if entity == null or not ("body_max" in entity):
        return base_threshold
    var ref_tissue: float = SEVERANCE_REFERENCE_TISSUE_BY_PART.get(part, 10.0)
    var cur_tissue: float = float(entity.body_max.get(part, int(ref_tissue)))
    if ref_tissue <= 0.0:
        return base_threshold
    var scale: float = cur_tissue / ref_tissue
    return base_threshold * scale
