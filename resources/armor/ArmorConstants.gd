class_name ArmorConstants
extends RefCounted

## Armor piece definitions, layer config, material properties constants.

# Damage types (canonical in CombatConstants)
const DAMAGE_TYPE_SHARP: String = CombatConstants.DAMAGE_TYPE_SHARP
const DAMAGE_TYPE_BLUNT: String = CombatConstants.DAMAGE_TYPE_BLUNT

# Armor layer dict keys (canonical strings  -  use ARMOR_LAYER_KEY_*, not literals)
const ARMOR_LAYER_KEY_DURABILITY := "durability"
const DEFAULT_ARMOR_LAYER_DURABILITY := 100.0
const ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM := "sharp_resistance_rha_mm"
const DEFAULT_ARMOR_LAYER_SHARP_RESISTANCE := 0.0
const ARMOR_LAYER_KEY_BLUNT_CUSHION := "blunt_cushion"
const DEFAULT_ARMOR_LAYER_BLUNT_CUSHION := 0.0
const ARMOR_LAYER_KEY_RIGIDITY := "rigidity"
const DEFAULT_ARMOR_LAYER_RIGIDITY := 0.0

# Armor: sharp penetration vs resistance; blunt transmission (no penetration). Durability loss per layer from absorbed
# damage.
const PENETRATION_DAMAGE_REDUCTION_MAX: float = 0.75
const DURABILITY_LOSS_RATE: float = 0.1

# Durability: no wear unless absorbed damage meets a minimum. Sharp term: max(flat, sharp_resistance_rha_mm * ratio).
# For blunt-origin absorbed damage, add (1 - blunt_transmission) * BLUNT_DURABILITY_THRESHOLD_RATIO so layers that
# absorb more blunt (padding) require more absorbed damage before wearing (research: energy absorption and degradation
# linked; padding designed to absorb repeated small blows).
const DURABILITY_MIN_DAMAGE_FLAT: float = 0.5
const DURABILITY_MIN_DAMAGE_RATIO: float = 0.05
const BLUNT_DURABILITY_THRESHOLD_RATIO: float = 0.5
# Joule-path durability wear: the joule walk (FEATURE_JOULE_ARMOR_BUDGET) calls the pure static
# penetration/transmission math, which never mutated layer durability — so a piece absorbed
# identically on contact 1 and contact 50 (armor never wore). This scale converts absorbed KE (J)
# into durability loss so armor progressively fails under repeated blows. 0.5 normalizes J (a
# committed strike ~100 J) to the same wear order-of-magnitude as the scalar path's damage units:
# a plate layer (durability 100, rate 0.07) wears ~3.5/committed hit -> fails after ~28 hits.
const JOULE_KE_DURABILITY_SCALE: float = 0.5

# XCamp-4i: how much wear erodes a layer's protection. 0.0 = no degradation (a layer keeps
# protecting at full strength until its durability hits 0, the pre-XCamp-4i behavior); 1.0 =
# full effect, a layer at D% durability provides D% of its sharp resistance and its blunt
# transmission/cushion degrade proportionally toward "no protection." Fresh armor (100%) is
# unaffected at any strength, so existing calibration and fresh-armor tests are unchanged.
const ARMOR_WEAR_DEGRADATION_STRENGTH: float = 1.0
# XCamp-4k/4l: how much a layer's rigidity shields its protection from wear. A worn layer's
# cut-resistance AND its blunt cushion both scale as prot^(1 - rigidity*this) — so at full
# durability (prot=1) the factor is 1.0 for every material (bit-identical to XCamp-4i) and at
# zero durability (prot=0) it is 0.0 for every material (a destroyed layer neither blocks a cut
# nor cushions a blow, keeping the XCamp-4i invariants). Between the two, a rigid plate
# (rigidity 1.0) retains both far longer than a soft gambeson (rigidity 0.0): a dented plate
# still deflects blade and its underlayer still cushions, a torn cloth layer does neither.
# 0.0 disables the split on both axes (pure XCamp-4i).
const ARMOR_WEAR_RIGIDITY_SHIELD: float = 0.6
# XCamp-4m: fatigue — a worn layer wears faster than a fresh one (compromised material fails
# quicker). Multiplier on durability loss = 1.0 + ARMOR_WEAR_FATIGUE_MAX * (1 - dur/max_dur).
# Pinned: at full durability the multiplier is exactly 1.0 (fresh armor bit-identical to 4i/4k/4l),
# rising to 1.0 + ARMOR_WEAR_FATIGUE_MAX at zero durability. 0.0 disables fatigue (constant wear).
const ARMOR_WEAR_FATIGUE_MAX: float = 0.5
# XCamp-4t: fatigue cliff. 4m already makes a worn layer wear faster, linearly from the first
# point of wear. Real metal is different: it holds up, then in the final stretch of its life the
# micro-cracks it has accumulated open at once and it fails all at once (fatigue / S-N curve).
# So the wear-rate penalty is not just linear in wear_frac — it gets an extra, *convex* boost that
# only activates once a layer is very worn. Below the threshold the cliff factor is exactly 1.0
# (4m unchanged, its pinned mid-life values stay bit-identical); above it the factor ramps from
# 1.0 to 1.0 + CLIFF_MAX at zero durability. 0.0 disables the cliff (pure 4m linear fatigue).
const ARMOR_WEAR_FATIGUE_CLIFF_THRESHOLD: float = 0.75
const ARMOR_WEAR_FATIGUE_CLIFF_MAX: float = 0.5
# XCamp-4o: damage-type-accurate wear. A layer's durability loss rate is modulated by how
# its rigidity interacts with the failure mode. Flexible layers (low rigidity) fray/tear
# faster from cuts (SHARP) but absorb blunts well (padding is its design purpose); rigid
# layers (high rigidity) deflect blade so cuts wear them slower, but dents/blows (BLUNT) are
# their real failure mode and wear them faster. The modifier is 1.0 at rigidity 0.5 (the
# neutral midpoint) for both types, so materials at the midpoint are unchanged. 0.0 disables
# the effect entirely (constant wear rate, pre-XCamp-4o behaviour). 0.15 = a ±15% spread at
# the rigidity extremes.
const ARMOR_WEAR_DAMAGE_TYPE_SPREAD: float = 0.15
# XCamp-4q: breakthrough crush. When a hit destroys a layer (transitions it to durability 0),
# the next surviving inner layer takes a one-time durability penalty: the shock of sudden
# exposure plus spall/debris from the failed outer layer. The penalty equals the energy the
# broken layer absorbed on this hit times this ratio, applied through the normal wear math.
# Pinned: fires only on the destruction transition (layer was not destroyed before this hit),
# no-op when 0.0 or no surviving inner layer. A fresh outer layer that survives the hit
# produces no crush, so pre-4q behavior is preserved for the common case.
const ARMOR_BREAKTHROUGH_CRUSH_RATIO: float = 0.2
# XCamp-4r: worn deflection. A layer's sharp_deflect_transmission (the fraction of a
# stopped cut that passes through as blunt shock) rises as the layer wears: a fresh,
# flat bevel turns a blade cleanly, while a dented/scratched surface catches and channels
# it. Deflected transmission = base * (1 + penalty * wear_frac) where wear_frac = 1 -
# pow(prot, ARMOR_WEAR_CURVE_EXPONENT) (the 4s convex shape of the 4i protection factor:
# 1.0 fresh, 0.0 destroyed). Pinned: at full durability (prot=1) the factor is exactly 1.0
# (fresh armor bit-identical to pre-4r); a destroyed layer's transmission is base * (1 +
# penalty). 0.0 disables (constant deflection).
const ARMOR_WEAR_DEFLECT_PENALTY: float = 0.5
# XCamp-4s: non-linear (cliff-edge) deflection wear. The 4r wear_frac that drives the
# deflection penalty is now shaped by this power curve: wear_frac = 1 - pow(prot, exp)
# instead of 1 - prot. With exp < 1.0 a worn bevel stays clean through most of a layer's
# life (small penalty at mid-life) and only degrades sharply as prot -> 0 (near failure).
# 1.0 = the pre-4s linear curve (wear_frac = 1 - prot). Only affects the 4r deflection
# penalty; the 4k threshold and 4l cushion keep the linear protection factor.
const ARMOR_WEAR_CURVE_EXPONENT: float = 0.7

# --- Generic layer stats (cloth, leather, mail, plate only) ---
# Sharp resistance: mm RHA equivalent. Nonlinear pen = (KE/55)^0.6 × area_factor (Williams).
# Blunt: transmission-only (no penetration check). Durability uses sharp_resistance_rha_mm and blunt_transmission.
# Sharp deflect transmission: fraction of damage that becomes blunt when sharp is stopped by layer (plate transmits
# more, cloth absorbs).
# Blunt transmission: fraction of blunt damage that passes through layer (transmission-only; no penetration).
# Durability: wear per damage absorbed; cloth tears fastest, plate lasts. See ARMOR_VALUES_PHYSICS_RESEARCH.md.

const SHARP_DEFLECT_TRANSMISSION_DEFAULT: float = 0.5
const BLUNT_TRANSMISSION_DEFAULT: float = 0.65

# blunt_cushion 0-1: transmission = base * (1 - cushion * momentum_factor). High cushion = padding absorbs.
# When momentum/area (kg.m/s)/m2 exceeds this, cushion is overwhelmed (heavy blows push through padding).
# Rupsil et al., MIT HMIT drop-hammer tests: gambeson maintains effective cushioning up to ~5000-7000 (kg.m/s)/m^2.
# At 3000 threshold (old value), even moderate mace hits overwhelmed padding entirely — too aggressive.
const BLUNT_CUSHION_MOMENTUM_THRESHOLD: float = 5500.0  # (kg.m/s)/m^2 — Rupsil/HMIT experimental data

# Area coupling for rigid layers: coupling = lerp(1, contact_cm/REFERENCE, rigidity). No clamp.
# ArmorPiece uses WeaponConstants.get_blunt_coupling_reference_cm() (mean head_diameter from weapon defs).
const BLUNT_COUPLING_REFERENCE_CM: float = 6.0  # fallback only
# Rigidity >= this: apply area coupling. Below: no area effect (flexible).
const RIGIDITY_THRESHOLD: float = 0.5
# Warn when area_factor or transmission outside these (tuning check).
# Min: narrow stab / point vs max head_diameter reference (e.g. 0.2 cm / 8 cm); not a data error.
const BLUNT_AREA_FACTOR_WARN_MIN: float = 0.02
const BLUNT_AREA_FACTOR_WARN_MAX: float = 5.0
const BLUNT_TRANSMISSION_WARN_MIN: float = 0.0
const BLUNT_TRANSMISSION_WARN_MAX: float = 1.0

# rigidity 0 - 1: area coupling for blunt. Rigid (plate) transmits more with large contact (mace); flexible (cloth) no
# effect.
# Cloth: gambeson padding, leg wraps, coif. Williams: 50 J for 16 layers linen. pen=(50/55)^0.6 ' 0.9 mm.
const LAYER_CLOTH: Dictionary = {
    "sharp_resistance_rha_mm": 0.9,
    "blunt_cushion": 0.65,
    "blunt_transmission": 0.55,
    "rigidity": 0.0,
    "durability_loss_rate": 0.22,
    "sharp_deflect_transmission": 0.16,
    "mass_kg": 0.45
}

# Leather: buff coat, boiled leather. Williams: buff 30 J, cuir-bouilli 20–30 J. pen=(30/55)^0.6 ≈ 0.6 mm.
# NOTE: leather (0.6) reads as LESS cut-resistant than cloth (0.9) only because the cloth value models a 16-layer
# gambeson (thick) while leather models a single buff coat (thin). At equivalent thickness leather (denser, tougher)
# stops cuts better than linen — the ordering reflects thickness, not material quality.
const LAYER_LEATHER: Dictionary = {
    "sharp_resistance_rha_mm": 0.6,
    "blunt_cushion": 0.5,
    "blunt_transmission": 0.58,
    "rigidity": 0.2,
    "durability_loss_rate": 0.16,
    "sharp_deflect_transmission": 0.24,
    "mass_kg": 1.05
}

# Mail: chainmail + jack. Williams: 80–120 J. pen=(120/55)^0.6 ≈ 1.5 mm.
## Adjusted to ~1.0 RHA equiv — historical chainmail (~1mm rings) is more vulnerable than plate suggests; sword thrusts
## and glancing cuts penetrate more readily than the old 1.5 value implied (experimental HEMA armor penetration tests).
const LAYER_MAIL: Dictionary = {
    "sharp_resistance_rha_mm": 1.0,
    "blunt_cushion": 0.1,
    "blunt_transmission": 0.62,
    "rigidity": 0.2,
    "durability_loss_rate": 0.12,
    # Capped at the penetrated-boundary value (1 - PENETRATION_DAMAGE_REDUCTION_MAX = 0.25) so the damage curve is
    # monotonic at the penetration threshold: a cut that just penetrates must do >= a glancing deflection.
    "sharp_deflect_transmission": 0.25,
    "mass_kg": 2.45
}

# Plate: medieval steel. Williams: 2 mm=175 J, 3.5 mm'380 J. Rigid -> area coupling (mace > thrust).
# Blunt transmission reduced from 0.72 to ~0.38 so plate armor transmits LESS blunt force than cloth/mail.
# Historical: hard plate on padded gambeson deflects/shatters blow energy; soft clothing alone transmits more impact shock.
## Further reduced to 0.28 for improved realism — hardened steel plate with gambeson underlayer significantly dampens shock transmission.
# Updated to 0.45 based on HEMA experimental data: flat-plate mace/hammer impacts transmit 30-60% energy; 0.45 sits in the middle of this range (Rupsil drop-hammer tests, MIT HMIT studies).
const LAYER_PLATE: Dictionary = {
    "sharp_resistance_rha_mm": 3.5,
    "blunt_cushion": 0.15,
    "blunt_transmission": 0.45,
    "rigidity": 1.0,
    "durability_loss_rate": 0.07,
    "sharp_deflect_transmission": 0.15,
    "mass_kg": 4.85
}
const DEFAULT_PENETRATION_SHARP: float = 5.0


# --- Armor piece definitions: one piece per body part, built from cloth/leather/mail/plate only ---
# Order: outer layer first (e.g. plate), then inner (e.g. cloth). Reflects how soldiers wore kit.
# Piece IDs by body part for random equipment.
static func get_armor_options_by_part() -> Dictionary:
    return {
        "head": ["KETTLE_HELM", "MAIL_COIF", "LEATHER_CAP", "CLOTH_COIF"],
        "chest": ["CUIRASS", "HAUBERK", "LEATHER_CUIRASS", "GAMBESON"],
        "right_arm": ["VAMBRACES_RIGHT", "MAIL_SLEEVES_RIGHT", "LEATHER_BRACERS_RIGHT", "ARM_WRAPS_RIGHT"],
        "left_arm": ["VAMBRACES_LEFT", "MAIL_SLEEVES_LEFT", "LEATHER_BRACERS_LEFT", "ARM_WRAPS_LEFT"],
        "right_leg": ["GREAVES_RIGHT", "MAIL_CHAUSSES_RIGHT", "LEATHER_GREAVES_RIGHT", "LEG_WRAPS_RIGHT"],
        "left_leg": ["GREAVES_LEFT", "MAIL_CHAUSSES_LEFT", "LEATHER_GREAVES_LEFT", "LEG_WRAPS_LEFT"]
    }


# Use get_piece_definition(piece_id) to get a definition with fresh layer copies.
static func get_piece_definition(piece_id: String) -> Dictionary:
    var id_normalized := piece_id
    match piece_id:
        # Back-compat aliases for older generic right-side IDs.
        "VAMBRACES":
            id_normalized = "VAMBRACES_RIGHT"
        "LEATHER_BRACERS":
            id_normalized = "LEATHER_BRACERS_RIGHT"
        "ARM_WRAPS":
            id_normalized = "ARM_WRAPS_RIGHT"
        "GREAVES":
            id_normalized = "GREAVES_RIGHT"
        "LEG_WRAPS":
            id_normalized = "LEG_WRAPS_RIGHT"
        "LEATHER_GREAVES":
            id_normalized = "LEATHER_GREAVES_RIGHT"
    var all := _piece_definitions_build()
    if not all.has(id_normalized):
        return {}
    return all[id_normalized].duplicate(true)


static func _piece_definitions_build() -> Dictionary:
    return {
        # Head: bascinet = plate skull + cloth aventail/cap under metal; mail coif = mail + cloth; leather cap; cloth coif
        "KETTLE_HELM":
        {"name": "Bascinet", "body_part": "head", "layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]},
        "MAIL_COIF":
        {"name": "Mail Coif", "body_part": "head", "layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]},
        "LEATHER_CAP": {"name": "Leather Cap", "body_part": "head", "layers": [LAYER_LEATHER.duplicate()]},
        "CLOTH_COIF": {"name": "Cloth Coif", "body_part": "head", "layers": [LAYER_CLOTH.duplicate()]},
        # Chest: cuirass = plate + cloth; hauberk = mail + cloth; leather jack = boiled leather; gambeson = cloth only
        "CUIRASS":
        {"name": "Cuirass", "body_part": "chest", "layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]},
        "GAMBESON": {"name": "Gambeson", "body_part": "chest", "layers": [LAYER_CLOTH.duplicate()]},
        "HAUBERK":
        {"name": "Mail Hauberk", "body_part": "chest", "layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]},
        "LEATHER_CUIRASS": {"name": "Leather Jack", "body_part": "chest", "layers": [LAYER_LEATHER.duplicate()]},
        # Arms: vambraces = plate + cloth; mail sleeves = mail + cloth; leather bracers = leather; cloth wraps = cloth
        "VAMBRACES_RIGHT":
        {
            "name": "Vambraces (R)",
            "body_part": "right_arm",
            "layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
        },
        "VAMBRACES_LEFT":
        {
            "name": "Vambraces (L)",
            "body_part": "left_arm",
            "layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
        },
        "MAIL_SLEEVES_RIGHT":
        {"name": "Mail Sleeves (R)", "body_part": "right_arm", "layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]},
        "MAIL_SLEEVES_LEFT":
        {"name": "Mail Sleeves (L)", "body_part": "left_arm", "layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]},
        "LEATHER_BRACERS_RIGHT":
        {"name": "Leather Bracers (R)", "body_part": "right_arm", "layers": [LAYER_LEATHER.duplicate()]},
        "LEATHER_BRACERS_LEFT":
        {"name": "Leather Bracers (L)", "body_part": "left_arm", "layers": [LAYER_LEATHER.duplicate()]},
        "ARM_WRAPS_RIGHT": {"name": "Arm Wraps (R)", "body_part": "right_arm", "layers": [LAYER_CLOTH.duplicate()]},
        "ARM_WRAPS_LEFT": {"name": "Arm Wraps (L)", "body_part": "left_arm", "layers": [LAYER_CLOTH.duplicate()]},
        # Legs: greaves = plate + cloth; mail chausses = mail + cloth; leather chausses = leather; cloth wraps = cloth
        "GREAVES_RIGHT":
        {
            "name": "Greaves (R)",
            "body_part": "right_leg",
            "layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
        },
        "GREAVES_LEFT":
        {
            "name": "Greaves (L)",
            "body_part": "left_leg",
            "layers": [LAYER_PLATE.duplicate(), LAYER_CLOTH.duplicate()]
        },
        "MAIL_CHAUSSES_RIGHT":
        {"name": "Mail Chausses (R)", "body_part": "right_leg", "layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]},
        "MAIL_CHAUSSES_LEFT":
        {"name": "Mail Chausses (L)", "body_part": "left_leg", "layers": [LAYER_MAIL.duplicate(), LAYER_CLOTH.duplicate()]},
        "LEG_WRAPS_RIGHT":
        {"name": "Leg Wraps (R)", "body_part": "right_leg", "layers": [LAYER_CLOTH.duplicate()]},
        "LEG_WRAPS_LEFT":
        {"name": "Leg Wraps (L)", "body_part": "left_leg", "layers": [LAYER_CLOTH.duplicate()]},
        "LEATHER_GREAVES_RIGHT":
        {"name": "Leather Chausses (R)", "body_part": "right_leg", "layers": [LAYER_LEATHER.duplicate()]},
        "LEATHER_GREAVES_LEFT":
        {"name": "Leather Chausses (L)", "body_part": "left_leg", "layers": [LAYER_LEATHER.duplicate()]}
    }

# Default penetration when no weapon is specified (strength-scaled later)
