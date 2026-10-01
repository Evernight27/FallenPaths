class_name WeaponConstants

extends RefCounted

## Per-weapon move defs + Expand WF spawn keys: **`default_form`** / **`allowed_forms[]`** feed
## **`CombatWeaponForm.seed_combatant_form`** (resolution step 4). LIVE_PATHS **`#spawn→reset-path-wf-1a`**
## **`#wf-assign-form-contract`**.
# Damage types (also in CombatConstants; defined here to avoid circular preload)
const DAMAGE_TYPE_SHARP: String = "sharp"

const DAMAGE_TYPE_BLUNT: String = "blunt"

# Archetype / kinematic IDs (owned by WeaponTemplateDefinitions; re-exported for WeaponConstants.X resolution)
const ARCHETYPE_STAB := WeaponTemplateDefinitions.ARCHETYPE_STAB

const ARCHETYPE_SLASH := WeaponTemplateDefinitions.ARCHETYPE_SLASH

const ARCHETYPE_OVERHEAD := WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD

const ARCHETYPE_QUICK_SLASH := WeaponTemplateDefinitions.ARCHETYPE_QUICK_SLASH

const ARCHETYPE_POMMEL := WeaponTemplateDefinitions.ARCHETYPE_POMMEL

const ARCHETYPE_HEAVY_BLUNT := WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT

const ARCHETYPE_THRUSTING_BLUNT := WeaponTemplateDefinitions.ARCHETYPE_THRUSTING_BLUNT

const KINEMATIC_DELIVERY_THRUST := WeaponTemplateDefinitions.KINEMATIC_DELIVERY_THRUST

const KINEMATIC_DELIVERY_SWING := WeaponTemplateDefinitions.KINEMATIC_DELIVERY_SWING

const KINEMATIC_DELIVERY_MIXED := WeaponTemplateDefinitions.KINEMATIC_DELIVERY_MIXED

const DEFAULT_COOLDOWN := WeaponTemplateDefinitions.DEFAULT_COOLDOWN

# Attack types: stab (point), cut/slash (edge), blunt/swing (head).
# Contact area per attack: stab -> point_width, cut -> blade_width, blunt -> head_diameter.
const ATTACK_TYPE_STAB: String = "stab"

const ATTACK_TYPE_CUT: String = "cut"

const ATTACK_TYPE_BLUNT: String = "blunt"

# Default baseline for physical modifier (contact area, cm)
const BASELINE_CONTACT_CM: float = 2.0

const BASELINE_MASS_KG: float = 1.0

const J_PER_MM_BASE: float = 55.0  # Williams: 55 J for 1 mm mild steel

const PENETRATION_EXPONENT: float = 0.6  # 1/1.67; thicker armor needs disproportionately more energy

# Global impact speed floor/ceiling (m/s): fallback when a weapon template has no Tier-A band entry; ImpactVelocityModel
# uses these (see ImpactVelocityModel._tier_a_default_band).
const VELOCITY_MIN_M_S: float = 6.0

const VELOCITY_MAX_M_S: float = 24.0

# Legacy KE->damage scale (sqrt(KE) law). No longer drives the cut channel (see CUT_DAMAGE_* below); it
# remains the calibration anchor for bone-damage excess energy (CombatDamageMechanism) and species
# tissue-capacity derivation (SpeciesResource). Historical note: it was originally the pre-armor cut law
# (100 J -> ~35 pre_armor, with the damage ceiling at ~661 J — an internal calibration choice, see DAMAGE_KE_MAX).
const DAMAGE_KE_SCALE: float = 3.5  # Legacy sqrt(KE) anchor; retained for bone/tissue-capacity calibration only

const DAMAGE_KE_MIN: float = 1.0

# Cut-damage energy law: pre-armor cut scales as KE^CUT_DAMAGE_ENERGY_EXPONENT. The exponent matches the
# Williams penetration exponent (KE^0.6) so the cut channel and the penetration channel agree on how the
# SAME strike kinetic energy converts to effect — the earlier sqrt(KE) (KE^0.5) was a non-physical "game
# abstraction" (see DAMAGE_KE_SCALE note) that under-scaled high-energy cuts. Tissue-severance work is
# near-linear in energy, so a steeper (still sub-linear, still capped at DAMAGE_KE_MAX) curve is more
# physically grounded while preserving the anti-trivialization intent.
const CUT_DAMAGE_ENERGY_EXPONENT: float = 0.6

# Cut-damage KE scale, re-anchored at the 100 J -> 35 pre-armor calibration point (35.0 / 100^0.6).
# At the anchor the cut damage is identical to the old sqrt(KE) law; below it cuts land slightly softer,
# above it slightly harder (<=~10% across the combat-realistic 35-160 J band).
const CUT_DAMAGE_KE_SCALE: float = 2.2083

# Pre-armor sharp damage hard cap — corresponds to KE=(90/3.5)^2 ≈ 661 J. A design ceiling chosen so a single
# committed limb strike stays just under the "sever the limb" regime (severance is a sustained, multi-blow
# event, not a single ~600 J swing); it is a tuning cap, not a measured biomechanical threshold.
const DAMAGE_KE_MAX: float = 90.0

# Cap penetration (mm RHA) from KE — physically grounded: Williams formula at max realistic combat KE (~130-160J spear
# thrust / mace overhead)
# with favorable point geometry gives ~14mm RHA. Cap prevents edge-case amplification from area_factor scaling.
# Sources: Williams 1950; Knight "Medieval Armor" 2003; Lehmann force-plate HEMA data 2013
const PENETRATION_KE_CAP_MM_RHA: float = 15.0

# Sharp: smaller contact (point) penetrates better than wide (cut). Factor = (BASELINE /
# contact_width_cm)^CONTACT_AREA_EXPONENT.
const CONTACT_AREA_EXPONENT: float = 0.5

const MIN_CONTACT_WIDTH_CM: float = 0.3

# Contact area in damage: smaller contact -> more local tissue disruption via stress concentration.
# Game-tuned exponent — chosen so dagger tip (0.3cm) gets ~1.5x vs sword edge (~1.7cm) at baseline 2.0cm.
# At exponent=0.23: dagger=(2/0.3)^0.23≈1.55, sword=(2/1.7)^0.23≈1.04. Cap prevents tiny contacts from overscaling.
const CONTACT_DAMAGE_EXPONENT: float = 0.23  # Game-tuned; gives dagger ~1.5x vs sword edge ~1.04x at baseline contact

# Cap on point-contact amplification; prevents tiny contacts from exceeding 1.5x
const CONTACT_DAMAGE_FACTOR_MAX: float = 1.50

# Blunt: transmission-only (no rigid check). Older blunt rigid-penetration constants were removed in favor of this
# model.
# Floor so tiny contacts don't produce absurd momentum/area; 1 cm min keeps normal blade areas unchanged.
const MIN_BLUNT_AREA_M2: float = 1e-4

# For CUT moves, blunt stream uses at least this contact (cm) so the "slap" doesn't get blade pressure.
const BLUNT_CUT_MIN_CONTACT_CM: float = 5.0

# For STAB moves, blunt slip channel uses at least this contact (cm) so point-thrust blunt damage isn't amplified by
# tiny
# contact area. The blunt pressure formula was calibrated for ~3 cm² blade-slap contacts; using geometric point area
# (~0.5 cm² for dagger) would produce absurdly high pressure from modest momentum. Floor of 2.5 cm ensures stab blunt
# slip damage stays in the same calibration regime as cut slap — both represent transmitted energy through a broad face.
const BLUNT_STAB_MIN_CONTACT_CM: float = 2.5

# For BLUNT moves, the pressure formula caps the effective contact so a large head doesn't dissipate momentum over a
# huge face. A mace head (8 cm diameter) only couples through a small patch of flesh at impact, not the full 64 cm²
# cross-section; without this cap the mace pressure (and thus damage) drops ~21× below the ~3 cm² calibration and the
# weapon underperforms even a dagger. Cap of 2.5 cm keeps blunt heads in the same calibration regime as stab slip.
const BLUNT_HEAD_MAX_CONTACT_CM: float = 2.5

# No weapon is 0% cutting: even maces can break skin (flanges/ridges). Floor for cut_ratio.
const MIN_CUT_RATIO: float = 0.02

# --- Effective edge (sharpness) for cutting ---
## Sharpness 0-1 maps to the edge's effective bearing (contact) width: a freshly ground edge has a NARROW apex
## (small bearing width -> high pressure), a dull edge has a wide rolled/burnished edge capped at the FULL blade
## width (the cutting edge can never be wider than the blade itself). effective = lerp(geometric, apex, sharpness)
## where apex = max(MIN_CONTACT_WIDTH_CM, geometric * SHARP_APEX_FRACTION). Sharper -> narrower -> higher pressure.
## (Replaces the old hyperbolic geometric/(0.2+0.8*s), which gave a sharp edge the full blade width and a dull edge
## 5x the blade width — physically impossible.)
const SHARP_APEX_FRACTION: float = 0.25

# --- Edge geometry (wedge mechanics by included angle) ---
## Cutting force depends on wedge (included) angle — a sharper edge displaces less material per mm of depth.
## Wedge mechanics: F = RHA_thickness / sin(edge_angle/2); a sharp ~30° included edge cuts with far less force
## than an obtuse ~90° one. All angles are INCLUDED angles. The sharpness stat maps onto this range: a keen,
## freshly-ground edge sits near the sharp end (model ~25°), a battle-worn/nicked edge rolls toward the dull end
## (~65°). Keen replica test edges can reach ~20°/side (~40° included); a durable historical working edge and
## impact tools such as axes are ground more obtuse, so the model's sharp value is a tuned combat-feel choice
## kept sharp for playability rather than a documented historical standard.
# Default included angle for a freshly ground fighting sword edge (degrees).
const EDGE_ANGLE_DEFAULT_DEG: float = 28.0

# Sharpness-to-edge-angle mapping range: sharp=1 → EDGE_ANGLE_SHARP_DEG, dull=0 → EDGE_ANGLE_DULL_DEG.
const EDGE_ANGLE_SHARP_DEG: float = 25.0  # model sharp end (keen, freshly-ground edge)

const EDGE_ANGLE_DULL_DEG: float = 65.0  # model dull end (battle-worn/nicked; 70°+ is essentially blunt)

# Wedge penetration bonus: sin(DEFAULT/2) / sin(angle/2) scales how much easier a sharper wedge penetrates vs dull.
## At sharp=1 (25°): factor = sin(14°)/sin(12.5°) ≈ 1.12 — ~12% penetration boost over default.
## At sharp=0 (65°): factor = sin(14°)/sin(32.5°) ≈ 0.448 — ~55% reduction vs default (dull edge struggles to bite).
# Floor so even razor-sharp edges don't trivialize thick armor.
const EDGE_WEDGE_PENETRATION_FLOOR: float = 0.3  # minimum wedge factor, keeps dull weapons still dangerous

# --- Pressure-based blunt damage (replaces flat DAMAGE_MOMENTUM_SCALE) ---
## P = m·v/(A·Δt): pressure at wound interface where Δt is contact duration, A is contact area.
# ~12 ms median impact contact duration, rigid weapon vs yielding tissue (plausible single-digit to ~20-30 ms band;
# tuned)
const BLUNT_IMPACT_CONTACT_TIME_MS: float = 12.0

## Δt reference impact speed (m/s): the 12 ms constant is anchored at this tip speed. Faster impacts
## shorten the pulse width, so peak force rises above linear-in-v (a mild high-speed shortening).
const BLUNT_IMPACT_REFERENCE_SPEED_M_S: float = 10.0

## Δt speed exponent: Δt(v) = Δt_ref · (v/v_ref)^(-BLUNT_CONTACT_TIME_SPEED_EXPONENT). 0.4 is a mild,
## design-level high-speed shortening (0 keeps the legacy constant-Δt model); not a measured contact law.
const BLUNT_CONTACT_TIME_SPEED_EXPONENT: float = 0.4

## Δt clamp (s): prevents sub-band velocities from inflating contact time into unrealistic multi-ms pulses.
const BLUNT_CONTACT_TIME_MIN_S: float = 0.005

const BLUNT_CONTACT_TIME_MAX_S: float = 0.025

## BLUNT_DAMAGE_PER_UNIT_PRESSURE: game-tuning coefficient calibrated so a typical mace impact produces ~25-45 damage
## after strength/mod factors are applied. Uses aggregate contact pressure (not peak stress), so the coefficient absorbs
## modeling simplifications — not directly derivable from clinical thresholds.
# Pa→damage; game-tuning coefficient calibrated for mace impact range
const BLUNT_DAMAGE_PER_UNIT_PRESSURE: float = 0.000025

## Effective inertia radius fraction — uniform rod about one end has I=mL²/3, but real weapons concentrate mass toward
## grip.
## Reduced from 0.48 to 0.35 (physics audit) and combined with removed separate MASS_DIST_CORRECTION:
## the single factor now correctly interpolates between measured values: dagger ~0.17m, arming sword ~0.32m, longswords
## ~0.42-0.50m.
const INERTIA_EFF_RADIUS_FRACTION: float = 0.35

# Gameplay floor — prevents zero-damage hits from rounding or weak parry follow-throughs
const BLUNT_DAMAGE_MIN: float = 1.0

# Same ceiling as DAMAGE_KE_MAX; single blunt strike should not exceed maximal limb trauma in one blow
const BLUNT_DAMAGE_MAX: float = 90.0

# --- Parry deflection damage transfer (Issue 4 + physics audit MEDIUM #7) ---
## Momentum-based impulse model: F = Δp/Δt where blade contact time ≈ 20 ms (plausible order of
## magnitude for a sword flex transient; see Hertzian/modal contact mechanics). No parry force-plate
## dataset with these exact figures is published, so the fractions below are physically-motivated
## design constants, not measurements.
## A parry transmits only a SMALL fraction of the incoming blow's momentum into the defender's arm
## (~20%); the rest is redirected or absorbed by the parrying blade. Energy check: a sword parry then
## deposits ~0.1-0.3 J into the arm (vs ~100 J for a full committed hit), so the >0.5 apply-gate makes
## light parries effectively free and only heavy blows (mace) register meaningful arm shock.
# fraction of incoming momentum transferred to defender's arm (design estimate)
const PARRY_DEFLECTION_MOMENTUM_FRACTION: float = 0.20

const IMPULSE_DAMAGE_SCALE: float = 0.6  # converts (kg·m/s) impulse to game damage units

## Fraction of calculated impulse damage actually applied as tissue/bone blunt damage (rest absorbed by armor/weapon).
## Blades store and release energy in bending/vibration (they ring after a parry), so part of the impulse is
## absorbed by the steel; ~45% is modeled as transferring to the defender's arm (design estimate).
const PARRY_DEFLECTION_SHOCK_TRANSFER: float = 0.45

const WEAPON_MOVE_PREFERRED_PARTS: Dictionary = {
    "SPEAR":
    {
        "spear_thrust": ["chest"],
        "off_line_thrust": ["chest"],
        "false_cut": ["chest"],
        "inside_stab": ["chest"],
        "low_thrust_spear": ["left_leg", "right_leg"],
        "parry_thrust_spear": ["chest"],
    },
    "DAGGER":
    {
        "quick_thrust": ["chest"],
        "committed_thrust": ["chest"],
        "reverse_thrust": ["left_leg", "right_leg"],
        "low_thrust_dagger": ["left_leg", "right_leg"],
        "feint_thrust_dagger": ["chest"],
        "grab_strike": ["head"],
        "parry_thrust_dagger": ["chest"],
    },
    "MACE":
    {
        "overhead_strike": ["head"],
        "side_strike": ["left_arm", "right_arm"],
        "direct_blow": ["head", "chest"],
        "upcut_mace": ["left_leg", "right_leg"],
        "low_strike": ["left_leg", "right_leg"],
        "thrusting_blow": ["head", "chest"],
        "feint_overhead_mace": ["head"],
        "parry_thrust_mace": ["chest"],
    },
    "AXE":
    {
        "overhead_chop": ["head"],
        "spike_thrust": ["chest"],
        "poll_strike": ["head"],
        "horizontal_chop": ["left_arm", "right_arm", "chest"],
        "low_chop": ["left_leg", "right_leg"],
        "reverse_grip_thrust": ["chest"],
        "overhead_feint": ["head"],
        "parry_thrust_axe": ["chest"],
    },
}

# medieval ~250-300 BHN vs RHA ~450-500 HBW -> ~1.6x easier penetration (hardness-ratio approximation)
const WILLIAMS_MATERIAL_CORRECTION := 1.6

# effective thickness t/cos(theta) at ~25 deg mean obliquity (1.05 at 18 deg; use the glancing end)
const WILLIAMS_OBLIQUITY_FACTOR := 1.1

## Stab/thrust penetration bonus: forensic consensus that stabs penetrate deeper than cuts of equivalent energy
## because force concentrates on tiny tip area rather than distributing along cutting edge (~1.6× per Knight's Forensic
## Pathology).
const STAB_PENETRATION_MULT := 1.5


## Weapon `mass` when present; else **`BASELINE_MASS_KG`** (parry, KE, inertia).
static func weapon_mass_kg(weapon: Variant) -> float:
    if weapon == null:
        return BASELINE_MASS_KG
    var mass_raw: Variant = weapon.get("mass") if weapon is Object else null
    if mass_raw is float or mass_raw is int:
        return float(mass_raw)
    return BASELINE_MASS_KG


## True when weapon requires two hands (muscle fatigue off-hand share).

## True when weapon requires two hands (muscle fatigue off-hand share).


static func weapon_is_two_handed(weapon: Variant) -> bool:
    if weapon == null:
        return false
    if weapon is Weapon:
        return weapon.is_two_handed
    var v: Variant = weapon.get("is_two_handed") if weapon is Object else null
    return v is bool and v


# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# Empirical power law E ~ t^1.67: pen = (KE/J_BASE)^0.6 where 0.6 = 1/1.67. A committed sword thrust
# carries ~50-150 J, and ~55 J is the right order of magnitude to punch a sharp point through ~1 mm of
# soft (mild) steel, so the 55 J/mm anchor is a physically-grounded tuning choice rather than a single
# measured constant. The 1.67 exponent makes thicker plate need disproportionately more energy — the core
# of why "heavier steel just means the weapon doesn't reach".
# Material correction: medieval armor steel (temperable, ~250-300 BHN) vs modern RHA (work-hardened to
# ~450-500 HBW). The 1.6 factor is essentially the hardness ratio (450/275 ~ 1.64): at equal thickness,
# medieval plate is roughly 1.5-1.7x easier to penetrate. A first-order approximation; medieval steel
# hardness varies between smiths and eras.
# Obliquity: glancing impacts lengthen the effective path through the plate (t/cos(theta)). 1/cos(18°) ~ 1.05;
# 1/cos(25°) ~ 1.10. The factor assumes the glancing end of plausible combat deflection angles (~25°), since
# most edge-on-plate hits carry some deflection rather than dead-square impact.


# --- Move pool (historical / HEMA-inspired) ---
# Each move: id, name (UI), contact_type (stab/cut/blunt), archetype_id, base_cooldown.
# Parry moves have is_parry: true (explicit parry attack following a defensive action).
# Weapons reference move ids; get_available_attack_types() returns move ids for that weapon.
# contact_type maps to weapon dimensions: stab->point_width, cut->blade_width, blunt->head_diameter.
static func get_all_move_ids() -> Array:
    return WeaponMoveDefinitions._move_definitions_build().keys()


static func get_move(move_id: String) -> Dictionary:
    var all_moves := WeaponMoveDefinitions._move_definitions_build()
    if not all_moves.has(move_id):
        return {}
    return all_moves[move_id].duplicate(true)


static func is_parry_move(move_id: String) -> bool:
    var m = get_move(move_id)
    return m.get("is_parry", false)


static func is_feint_move(move_id: String) -> bool:
    var m = get_move(move_id)
    return m.get("is_feint", false)


## HEMA circumscription (verwunden): a compound cut that draws the guard off one line and
## strikes the far side of the committed blade. Marks the open-line payoff as the OPPOSITE line.


static func is_circumscription_move(move_id: String) -> bool:
    var m = get_move(move_id)
    return m.get("circumscription", false)


# Per-weapon overrides for shared move defs (Layer B aim).


static func preferred_parts_for_weapon_move(weapon_id: String, move_id: String) -> Array:
    var wid: String = str(weapon_id).to_upper().strip_edges()
    if WEAPON_MOVE_PREFERRED_PARTS.has(wid):
        var per_weapon: Variant = WEAPON_MOVE_PREFERRED_PARTS[wid]
        if per_weapon is Dictionary and (per_weapon as Dictionary).has(move_id):
            var parts: Variant = (per_weapon as Dictionary)[move_id]
            if parts is Array:
                return (parts as Array).duplicate()
    var md: Dictionary = get_move(move_id)
    return md.get("preferred_parts", [])


## move_id (e.g. thrust, oberhau) -> stab | cut | blunt. Bare stab/cut/blunt pass through unchanged.
## Single source for combat + velocity; use this directly (not a separate forwarder).

## move_id (e.g. thrust, oberhau) -> stab | cut | blunt. Bare stab/cut/blunt pass through unchanged.
## Single source for combat + velocity; use this directly (not a separate forwarder).


static func contact_type_for_move_id(move_id: String) -> String:
    var key: String = move_id.to_lower().strip_edges()
    if key == ATTACK_TYPE_STAB or key == ATTACK_TYPE_CUT or key == ATTACK_TYPE_BLUNT:
        return key
    var md: Dictionary = get_move(move_id)
    if md.is_empty():
        return ATTACK_TYPE_CUT
    var ct: String = str(md.get("contact_type", ATTACK_TYPE_CUT)).to_lower()
    if ct == ATTACK_TYPE_STAB or ct == ATTACK_TYPE_CUT or ct == ATTACK_TYPE_BLUNT:
        return ct
    return ATTACK_TYPE_CUT


static func get_all_weapon_ids() -> Array:
    return ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]


# Use get_weapon_definition(weapon_id) for a fresh copy.


static func get_weapon_definition(weapon_id: String) -> Dictionary:
    var id_normalized := weapon_id.to_upper()
    var all := WeaponTemplateDefinitions._weapon_definitions_build()
    if not all.has(id_normalized):
        return {}
    return all[id_normalized].duplicate(true)


static func get_archetype(archetype_id: String) -> Dictionary:
    var all_arch := WeaponTemplateDefinitions._archetype_definitions_build()
    if not all_arch.has(archetype_id):
        push_warning("[WeaponConstants] Unknown archetype '%s', falling back to SLASH" % archetype_id)
        return all_arch.get(ARCHETYPE_SLASH, {})
    return all_arch[archetype_id].duplicate(true)


# Reference for area coupling: larger contact (mace) vs smaller (pommel). Using max(head_diameter)
# so the largest blunt weapon yields area_factor=1.0 and transmission stays <= layer blunt_transmission.


static func get_blunt_coupling_reference_cm() -> float:
    var ids: Array = get_all_weapon_ids()
    var max_hd: float = 0.0
    for wid in ids:
        var d: Dictionary = get_weapon_definition(wid)
        var hd = d.get("head_diameter", 0.0)
        if (hd is float or hd is int) and float(hd) > max_hd:
            max_hd = float(hd)
    return max_hd if max_hd > 0.0 else 6.0


## Weapon template id (`SWORD`, `AXE`, `MACE`) from equipped weapon node/dict.


static func weapon_type_id(weapon: Variant) -> String:
    return WeaponTemplateDefinitions._weapon_template_id(weapon)


## Legacy encounter / mood keys -> weapon-native form id (e.g. axe `wrath` -> `demi_hache`).


static func resolve_form_legacy_alias(weapon: Variant, raw_form: String) -> String:
    var s: String = str(raw_form).strip_edges().to_lower()
    if s.is_empty():
        return s
    var wt: String = WeaponTemplateDefinitions._weapon_template_id(weapon)
    if wt.is_empty():
        return s
    var def: Dictionary = get_weapon_definition(wt)
    if def.is_empty():
        return s
    var aliases: Variant = def.get("form_legacy_aliases", {})
    if aliases is Dictionary and (aliases as Dictionary).has(s):
        return str((aliases as Dictionary)[s]).strip_edges().to_lower()
    return s


## Expand WF: default form id for equipped weapon ( **`balanced`** when unarmed).

## Expand WF: default form id for equipped weapon ( **`balanced`** when unarmed).


static func default_form_for_weapon(weapon: Variant) -> String:
    var wt: String = WeaponTemplateDefinitions._weapon_template_id(weapon)
    if wt.is_empty():
        return "balanced"
    var def: Dictionary = get_weapon_definition(wt)
    if def.is_empty():
        return "balanced"
    return str(def.get("default_form", "balanced")).strip_edges().to_lower()


## Expand WF: allowed form ids for weapon template; empty -> no clamp.

## Expand WF: allowed form ids for weapon template; empty -> no clamp.


static func allowed_forms_for_weapon(weapon: Variant) -> Array:
    var wt: String = WeaponTemplateDefinitions._weapon_template_id(weapon)
    if wt.is_empty():
        return ["balanced", "wall"]
    var def: Dictionary = get_weapon_definition(wt)
    if def.is_empty():
        return ["balanced"]
    var raw: Variant = def.get("allowed_forms", [])
    if raw is Array:
        return raw
    return ["balanced"]


# --- Edge geometry helper: maps sharpness (0-1) to wedge penetration factor ---
## Sharp=1 → sharper edge (EDGE_ANGLE_SHARP_DEG) → higher wedge penetration bonus.
## Sharp=0 → duller edge (EDGE_ANGLE_DULL_DEG) → lower wedge penetration bonus.
## Factor = sin(DEFAULT/2) / sin(angle/2), clamped to FLOOR so dull weapons still bite weakly.


static func edge_wedge_penetration_factor(sharpness: float) -> float:
    var eff_angle_deg: float = lerpf(EDGE_ANGLE_SHARP_DEG, EDGE_ANGLE_DULL_DEG, 1.0 - clampf(sharpness, 0.0, 1.0))
    var eff_angle_rad: float = deg_to_rad(eff_angle_deg)
    # Wedge factor: sharper wedge displaces less material per unit depth.
    # sin(default/2)/sin(angle/2): at angle=default → 1.0; at angle=sharp → >1.0 (bonus); at angle=dull → <1.0
    # (penalty).
    var numer: float = sin(deg_to_rad(EDGE_ANGLE_DEFAULT_DEG) / 2.0)
    var denom: float = sin(eff_angle_rad / 2.0)
    if denom <= 0.0:
        return EDGE_WEDGE_PENETRATION_FLOOR
    var factor: float = numer / denom
    return maxf(factor, EDGE_WEDGE_PENETRATION_FLOOR)
