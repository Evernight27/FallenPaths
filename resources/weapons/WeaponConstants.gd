class_name WeaponConstants
extends RefCounted

## Per-weapon move defs + Expand WF spawn keys: **`default_form`** / **`allowed_forms[]`** feed
## **`CombatWeaponForm.seed_combatant_form`** (resolution step 4). LIVE_PATHS **`#spawn--reset-path-wf-1a`** ??
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
# Pre-armor damage: scale * sqrt(KE) * strength_mod * arm_mod. 2.0 aligns severance with research (~100 J arm, ~200 J
# leg).
# Severance tuning narrative: docs/LIVE_PATHS.md#research-audit + .calibration_audit.txt.
const DAMAGE_KE_SCALE: float = 2.0
const DAMAGE_KE_MIN: float = 1.0
const DAMAGE_KE_MAX: float = 80.0
# Cap penetration (mm RHA) from KE so very high energy doesn't trivialize armor.
const PENETRATION_KE_CAP_MM_RHA: float = 15.0

# --- Physics-based contact area ---
# Sharp: smaller contact (point) penetrates better than wide (cut). Factor = (BASELINE / contact_width_cm)^????.
const CONTACT_AREA_EXPONENT: float = 0.5
const MIN_CONTACT_WIDTH_CM: float = 0.2
# Contact area in damage: smaller contact -> more local damage. Cap factor so stab doesn't overscale.
const CONTACT_DAMAGE_EXPONENT: float = 0.3
const CONTACT_DAMAGE_FACTOR_MAX: float = 2.0
# Blunt: transmission-only (no rigid check). Older blunt rigid-penetration constants were removed in favor of this
# model.
# Floor so tiny contacts don't produce absurd momentum/area; 1 cm???? min keeps normal blade areas unchanged.
const MIN_BLUNT_AREA_M2: float = 1e-4
# For CUT moves, blunt stream uses at least this contact (cm) so the "slap" doesn't get blade pressure.
const BLUNT_CUT_MIN_CONTACT_CM: float = 5.0
# No weapon is 0% cutting: even maces can break skin (flanges/ridges). Floor for cut_ratio.
const MIN_CUT_RATIO: float = 0.02

# --- Effective edge (sharpness) for cutting ---
# Sharpness 0-1: effective sharp contact = geometric / (SHARPNESS_FACTOR_MIN + (1 - SHARPNESS_FACTOR_MIN) * sharpness).
# Sharpness 1 = geometric; sharpness 0 = geometric/0.2 (duller = wider effective contact = less penetration).
const SHARPNESS_FACTOR_MIN: float = 0.2

# --- Momentum-based blunt damage ---
# Pre-armor blunt = DAMAGE_MOMENTUM_SCALE * (mass_kg * velocity_m_s) * strength_mod * arm_mod * contact_factor, clamped.
# Tuned so typical mace (1.7 kg, 12 m/s) and sword blunt portion sit in same band as before.
const DAMAGE_MOMENTUM_SCALE: float = 0.65
const BLUNT_DAMAGE_MIN: float = 1.0
const BLUNT_DAMAGE_MAX: float = 80.0
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
# Williams (Knight & Blast Furnace): 1mm=55J, 1.5mm=110J, 2mm=175J ?????? E ?????? t^1.67. Nonlinear: pen =
# (KE/J_BASE)^PEN_EXPONENT.


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


## Weapon template id (`SWORD`, `AXE`, �) from equipped weapon node/dict.
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


## Expand WF: allowed form ids for weapon template; empty ?????? no clamp.


## Expand WF: allowed form ids for weapon template; empty ?????? no clamp.
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
