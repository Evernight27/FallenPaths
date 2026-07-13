class_name WeaponConstants
extends RefCounted

## Per-weapon move defs + Expand WF spawn keys: **`default_form`** / **`allowed_forms[]`** feed **`CombatWeaponForm.seed_combatant_form`** (resolution step 4). LIVE_PATHS **`#spawn--reset-path-wf-1a`** ?? **`#wf-assign-form-contract`**.

# Damage types (also in CombatConstants; defined here to avoid circular preload)
const DAMAGE_TYPE_SHARP: String = "sharp"
const DAMAGE_TYPE_BLUNT: String = "blunt"

# Attack types: stab (point), cut/slash (edge), blunt/swing (head).
# Contact area per attack: stab -> point_width, cut -> blade_width, blunt -> head_diameter.
const ATTACK_TYPE_STAB: String = "stab"
const ATTACK_TYPE_CUT: String = "cut"
const ATTACK_TYPE_BLUNT: String = "blunt"

# Default baseline for physical modifier (contact area, cm)
const BASELINE_CONTACT_CM: float = 2.0
const BASELINE_MASS_KG: float = 1.0


## Weapon `mass` when present; else **`BASELINE_MASS_KG`** (parry, KE, inertia).
static func weapon_mass_kg(weapon: Variant) -> float:
    if weapon == null:
        return BASELINE_MASS_KG
    var mass_raw: Variant = weapon.get("mass") if weapon is Object else null
    if mass_raw is float or mass_raw is int:
        return float(mass_raw)
    return BASELINE_MASS_KG


## True when weapon requires two hands (muscle fatigue off-hand share).
static func weapon_is_two_handed(weapon: Variant) -> bool:
    if weapon == null:
        return false
    if weapon is Weapon:
        return weapon.is_two_handed
    var v: Variant = weapon.get("is_two_handed") if weapon is Object else null
    return v is bool and v


# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# Williams (Knight & Blast Furnace): 1mm=55J, 1.5mm=110J, 2mm=175J ?????? E ?????? t^1.67. Nonlinear: pen = (KE/J_BASE)^PEN_EXPONENT.
const J_PER_MM_BASE: float = 55.0  # Williams: 55 J for 1 mm mild steel
const PENETRATION_EXPONENT: float = 0.6  # 1/1.67; thicker armor needs disproportionately more energy
# Global impact speed floor/ceiling (m/s): fallback when a weapon template has no Tier-A band entry; ImpactVelocityModel uses these (see ImpactVelocityModel._tier_a_default_band).
const VELOCITY_MIN_M_S: float = 6.0
const VELOCITY_MAX_M_S: float = 24.0
# Pre-armor damage: scale * sqrt(KE) * strength_mod * arm_mod. 2.0 aligns severance with research (~100 J arm, ~200 J leg).
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
# Blunt: transmission-only (no rigid check). Older blunt rigid-penetration constants were removed in favor of this model.
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


# --- Move pool (historical / HEMA-inspired) ---
# Each move: id, name (UI), contact_type (stab/cut/blunt), archetype_id, base_cooldown.
# Parry moves have is_parry: true (explicit parry attack following a defensive action).
# Weapons reference move ids; get_available_attack_types() returns move ids for that weapon.
# contact_type maps to weapon dimensions: stab->point_width, cut->blade_width, blunt->head_diameter.
static func get_all_move_ids() -> Array:
    return _move_definitions_build().keys()


static func get_move(move_id: String) -> Dictionary:
    var all_moves := _move_definitions_build()
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


static func _move_definitions_build() -> Dictionary:
    # attack_line: Liechtenauer 4 lines - high (0????), low (180????), left (270????), right (90????) + compound octants high_left, high_right, low_left. Blade path, not body target.
    # angle_variance_deg: optional ????deg human error; heavier/awkward moves have more variance.
    # angle_offset_deg: optional bias from base line (e.g. off_line_thrust angled toward flank).
    # impact_station_mean: fraction along weapon from hands (0=hands, 1=tip). Spear thrusts may exceed 0.8 due to long shaft; clamped at 0.80.
    # impact_station_spread: per-strike jitter around mean. Precision strikes use small nonzero value (0.01-0.02).
    return {
        "thrust":
        {
            # Sword (Liechtenauer/KDF): thrust, Oberhau, Unterhau, horizontal (Zwerchau-style), pommel, parry-counters
            "name": "Point thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.2,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "weapon_extension_commit_fraction": 0.56,
            "impact_station_mean": 0.76,
            "impact_station_spread": 0.01
        },
        "oberhau":
        {
            "name": "Downward diagonal cut",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_OVERHEAD,
            "base_cooldown": 2.4,
            "attack_line": "high_right",
            "preferred_parts": ["head"],
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.78,
            "impact_station_mean": 0.70,
            "impact_station_spread": 0.05
        },
        "oberhau_feint":
        {
            # Tier 4.2: optional feint_windup_duration_mult (>1)  -  extra wind-up vs same-archetype honest cut (two-line commitment cost).
            "name": "Feint high, cut low",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_OVERHEAD,
            "base_cooldown": 2.6,
            "attack_line": "high_right",
            "preferred_parts": ["head"],
            "is_feint": true,
            "feint_windup_duration_mult": 1.1,
            "feint_target_reveal_at_progress": 0.45,
            "angle_variance_deg": 10,
            "impact_station_mean": 0.58,
            "impact_station_spread": 0.06
        },
        "thrust_feint":
        {
            # Tier 4.2: stab feint  -  feint_target_reveal_at_progress earlier than oberhau_feint (faster thrust telegraph); feint_windup_duration_mult < cut feint (stab archetype already tighter).
            "name": "Feint line, thrust true",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.4,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "is_feint": true,
            "feint_windup_duration_mult": 1.07,
            "feint_target_reveal_at_progress": 0.4,
            "angle_variance_deg": 9,
            "weapon_extension_commit_fraction": 0.52,
            "impact_station_mean": 0.62,
            "impact_station_spread": 0.05
        },
        "unterhau":
        {
            "name": "Upward diagonal cut",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 2.2,
            "attack_line": "low_left",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.74,
            "impact_station_mean": 0.66,
            "impact_station_spread": 0.05
        },
        "slash":
        {
            "name": "Horizontal cut (cross)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 2.0,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm", "chest"],
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.72,
            "impact_station_mean": 0.64,
            "impact_station_spread": 0.05
        },
        "pommel_strike":
        {
            "name": "Pommel strike (blunt)",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_POMMEL,
            "base_cooldown": 1.8,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 9,
            "impact_station_mean": 0.16,
            "impact_station_spread": 0.02
        },
        "parry_thrust":
        {
            "name": "Parry and riposte",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.0,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "weapon_extension_commit_fraction": 0.50,
            "impact_station_mean": 0.74,
            "impact_station_spread": 0.03
        },
        "parry_cut":
        {
            "name": "Parry and cut",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 1.9,
            "is_parry": true,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm"],
            "impact_station_mean": 0.62,
            "impact_station_spread": 0.05
        },
        "spike_thrust":
        {
            # Axe (Le Jeu de la Hache): spike, overhead chop, diagonal chop, poll
            "name": "Spike thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 3.2,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 9,
            "weapon_extension_commit_fraction": 0.58,
            "impact_station_mean": 0.80,
            "impact_station_spread": 0.01
        },
        "overhead_chop":
        {
            "name": "Overhead chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_OVERHEAD,
            "base_cooldown": 3.5,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 12,
            "weapon_extension_commit_fraction": 0.80,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.06
        },
        "diagonal_chop":
        {
            "name": "Diagonal chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 3.0,
            "attack_line": "high_left",
            "preferred_parts": ["left_arm", "right_arm", "chest"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.06
        },
        "poll_strike":
        {
            "name": "Back-of-head strike (blunt)",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 3.0,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.22,
            "impact_station_spread": 0.02
        },
        "parry_chop":
        {
            "name": "Parry and chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 3.0,
            "is_parry": true,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm"],
            "impact_station_mean": 0.64,
            "impact_station_spread": 0.06
        },
        "overhead_strike":
        {
            # Mace: overhead, side, direct  -  heavy weapon, more wobble
            "name": "Overhead strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 3.5,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 13,
            "impact_station_mean": 0.44,
            "impact_station_spread": 0.05
        },
        "side_strike":
        {
            "name": "Side strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 3.2,
            "attack_line": "right",
            "preferred_parts": ["left_arm", "right_arm"],
            "angle_variance_deg": 12,
            "impact_station_mean": 0.40,
            "impact_station_spread": 0.05
        },
        "direct_blow":
        {
            "name": "Direct blow",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 3.0,
            "attack_line": "high",
            "preferred_parts": ["head", "chest"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.38,
            "impact_station_spread": 0.02
        },
        "parry_strike":
        {
            "name": "Parry and strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 3.0,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "impact_station_mean": 0.42,
            "impact_station_spread": 0.04
        },
        "quick_thrust":
        {
            # Dagger / rondel  -  small, quick, tighter control
            "name": "Quick thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 0.7,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 5,
            "weapon_extension_commit_fraction": 0.55,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.01
        },
        "committed_thrust":
        {
            "name": "Strong thrust (armor-piercing)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 1.0,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 6,
            "weapon_extension_commit_fraction": 0.60,
            "impact_station_mean": 0.78,
            "impact_station_spread": 0.01
        },
        "quick_slash":
        {
            "name": "Quick slash",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_QUICK_SLASH,
            "base_cooldown": 0.6,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm"],
            "angle_variance_deg": 6,
            "weapon_extension_commit_fraction": 0.62,
            "impact_station_mean": 0.58,
            "impact_station_spread": 0.04
        },
        "dagger_pommel":
        {
            "name": "Pommel blow",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_POMMEL,
            "base_cooldown": 0.5,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 6,
            "impact_station_mean": 0.18,
            "impact_station_spread": 0.02
        },
        "parry_thrust_dagger":
        {
            "name": "Parry and stab",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 0.6,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 5,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.03
        },
        "spear_thrust":
        {
            # Spear (Fiore): thrust, angled thrust, slash, pole swing
            "name": "Forward thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 3.0,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.58,
            "impact_station_mean": 0.80,
            "impact_station_spread": 0.02
        },
        "off_line_thrust":
        {
            "name": "Angled thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.8,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 15,
            "angle_offset_deg": 25,
            "impact_station_mean": 0.78,
            "impact_station_spread": 0.04
        },
        "spear_slash":
        {
            "name": "Slash with spearhead",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 2.8,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm"],
            "angle_variance_deg": 10,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.05
        },
        "pole_swing":
        {
            "name": "Pole swing (blunt)",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 2.5,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm", "head"],
            "angle_variance_deg": 12,
            "impact_station_mean": 0.55,
            "impact_station_spread": 0.08
        },
        "zwerchau":
        {
            # SWORD additions (HEMA expansion): zwerchau (inside-line crossing cut), bind_press (post-bind center thrust), low_thrust (leg/groin)
            "name": "Crossing cut (Zwerchau)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 2.3,
            "attack_line": "high_left",
            "preferred_parts": ["head", "chest"],
            "is_feint": false,
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.76,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.05
        },
        "bind_press":
        {
            "name": "Bind and press",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.1,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.54,
            "impact_station_mean": 0.76,
            "impact_station_spread": 0.03
        },
        "low_thrust_sword":
        {
            "name": "Low thrust (Grifo)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.0,
            "attack_line": "low",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 8,
            "weapon_extension_commit_fraction": 0.55,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.03
        },
        "horizontal_chop":
        {
            # AXE additions (Le Jeu de la Hache expansion): horizontal_chop, low_chop, reverse_grip_thrust, overhead_feint, parry_thrust_axe
            "name": "Horizontal chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 2.8,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm", "chest"],
            "angle_variance_deg": 10,
            "impact_station_mean": 0.70,
            "impact_station_spread": 0.06
        },
        "low_chop":
        {
            "name": "Low chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_SLASH,
            "base_cooldown": 2.9,
            "attack_line": "low_left",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.66,
            "impact_station_spread": 0.06
        },
        "reverse_grip_thrust":
        {
            "name": "Reverse spike thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.0,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 9,
            "weapon_extension_commit_fraction": 0.52,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.03
        },
        "overhead_feint":
        {
            "name": "Feint overhead chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": ARCHETYPE_OVERHEAD,
            "base_cooldown": 3.2,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "is_feint": true,
            "feint_windup_duration_mult": 1.15,
            "feint_target_reveal_at_progress": 0.4,
            "angle_variance_deg": 12,
            "impact_station_mean": 0.70,
            "impact_station_spread": 0.06
        },
        "parry_thrust_axe":
        {
            "name": "Parry and spike thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.5,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 9,
            "impact_station_mean": 0.74,
            "impact_station_spread": 0.03
        },
        "upcut_mace":
        {
            # MACE additions (Vadi/Talhoffer expansion): upcut_mace, low_strike, thrusting_blow, feint_overhead_mace, parry_thrust_mace
            "name": "Rising mace blow",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 3.0,
            "attack_line": "low_left",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 12,
            "impact_station_mean": 0.42,
            "impact_station_spread": 0.05
        },
        "low_strike":
        {
            "name": "Low mace strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 2.8,
            "attack_line": "low",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.40,
            "impact_station_spread": 0.05
        },
        "thrusting_blow":
        {
            "name": "Spike thrust (armor gap)",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_THRUSTING_BLUNT,
            "base_cooldown": 2.5,
            "attack_line": "high",
            "preferred_parts": ["head", "chest"],
            "angle_variance_deg": 9,
            "weapon_extension_commit_fraction": 0.56,
            "impact_station_mean": 0.44,
            "impact_station_spread": 0.03
        },
        "feint_overhead_mace":
        {
            "name": "Feint overhead smash",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_OVERHEAD,
            "base_cooldown": 3.2,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "is_feint": true,
            "feint_windup_duration_mult": 1.15,
            "feint_target_reveal_at_progress": 0.38,
            "angle_variance_deg": 13,
            "impact_station_mean": 0.42,
            "impact_station_spread": 0.05
        },
        "parry_thrust_mace":
        {
            "name": "Parry and spike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_THRUSTING_BLUNT,
            "base_cooldown": 2.4,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 9,
            "impact_station_mean": 0.46,
            "impact_station_spread": 0.03
        },
        "reverse_thrust":
        {
            # DAGGER additions (Fiore expansion): reverse_thrust, grab_strike, low_thrust_dagger, feint_thrust_dagger
            "name": "Inverted grip thrust (Rovera)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 0.8,
            "attack_line": "low",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 5,
            "weapon_extension_commit_fraction": 0.48,
            "impact_station_mean": 0.65,
            "impact_station_spread": 0.03
        },
        "grab_strike":
        {
            "name": "Grapple pommel strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_POMMEL,
            "base_cooldown": 0.9,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 6,
            "impact_station_mean": 0.16,
            "impact_station_spread": 0.02
        },
        "low_thrust_dagger":
        {
            "name": "Low thrust (groin/legs)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 0.75,
            "attack_line": "low",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 5,
            "weapon_extension_commit_fraction": 0.52,
            "impact_station_mean": 0.66,
            "impact_station_spread": 0.03
        },
        "feint_thrust_dagger":
        {
            "name": "Feint thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 0.9,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "is_feint": true,
            "feint_windup_duration_mult": 1.05,
            "feint_target_reveal_at_progress": 0.35,
            "angle_variance_deg": 5,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.03
        },
        "false_cut":
        {
            # SPEAR additions (Fiore expansion): false_cut, inside_stab, shaft_thrust, low_thrust_spear
            "name": "False cut and thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.8,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "is_feint": true,
            "feint_windup_duration_mult": 1.08,
            "feint_target_reveal_at_progress": 0.42,
            "angle_variance_deg": 8,
            "weapon_extension_commit_fraction": 0.56,
            "impact_station_mean": 0.78,
            "impact_station_spread": 0.03
        },
        "inside_stab":
        {
            "name": "Close-range stab",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 1.5,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.44,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.03
        },
        "shaft_thrust":
        {
            "name": "Shaft butt strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": ARCHETYPE_HEAVY_BLUNT,
            "base_cooldown": 2.0,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 10,
            "impact_station_mean": 0.15,
            "impact_station_spread": 0.02
        },
        "low_thrust_spear":
        {
            "name": "Low thrust (legs)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.6,
            "attack_line": "low",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.54,
            "impact_station_mean": 0.80,
            "impact_station_spread": 0.03
        },
        "parry_thrust_spear":
        {
            "name": "Parry and stab",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": ARCHETYPE_STAB,
            "base_cooldown": 2.7,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "weapon_extension_commit_fraction": 0.68,
            "impact_station_mean": 0.80,
            "impact_station_spread": 0.03
        }
    }


# --- Weapon template definitions ---
# Per weapon: mass (kg), dimensions (cm), edge_width (cm, optional), blade_cut_ratio, melee_range, moves.
# Dimensions: blade_width = edge contact for cuts; point_width = tip for thrusts; head_diameter = striking head for blunt.
# thrust_head_width = width of head/shaft behind point (cm); used for blunt momentum/area on thrusts. Broader head = lower p/A.
# edge_width = effective sharp contact for blunt weapons (flanges/ridges that can break skin); used for sharp-component penetration.
# impact_velocity_bands (optional): Tier C overrides  -  keys stab|cut|blunt ?????? {"min":m/s,"max":m/s} or Vector2; see ImpactVelocityModel.gd.
# Data: Oakeshott/longsword 2 - 3 cm edge, 0.3 - 0.6 cm point; Le Jeu axe 3 - 4 cm edge, 0.5 - 1 cm spike; mace flanges 0.4 - 0.6 cm (Williams, Tod Cutler); Fiore/Talhoffer dagger ~1.5 cm edge, 0.2 - 0.4 cm point; spear 0.4 - 0.8 cm point, head blade 2 - 3 cm.
# No weapon has 0% cutting (MIN_CUT_RATIO); each component uses get_sharp_contact_cm / get_blunt_contact_cm for its damage type.
static func get_all_weapon_ids() -> Array:
    return ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]


# Use get_weapon_definition(weapon_id) for a fresh copy.
static func get_weapon_definition(weapon_id: String) -> Dictionary:
    var id_normalized := weapon_id.to_upper()
    var all := _weapon_definitions_build()
    if not all.has(id_normalized):
        return {}
    return all[id_normalized].duplicate(true)


static func _weapon_definitions_build() -> Dictionary:
    return {
        # Longsword / arming sword: thrust, cuts, pommel, parry-counters (German tradition).
        "SWORD":
        {
            "name": "Sword",
            "default_form": "ox",
            "allowed_forms": ["ox", "plow", "wrath", "fool", "wall", "tempest", "balanced"],
            "mass": 1.2,
            "parry_speed_factor": 1.0,
            "blade_width": 2.0,
            "point_width": 0.5,
            "thrust_head_width": 2.0,
            "head_diameter": 3.0,
            "edge_width": 0.0,
            "blade_cut_ratio": 0.75,
            "melee_range": 1.5,
            "parts":
            [
                {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
                {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
            ],
            "parry_part_id": "blade",
            "strike_physics":
            {
                "station_mean": 0.54,
                "station_spread": 0.1,
                "station_cut_vel_guard": 0.9,
                "station_cut_vel_tip": 1.06,
                "coupling_stab": 0.9,
                "coupling_cut": 0.92,
                "coupling_blunt": 0.96,
                "blunt_pressure": 1.0,
                "blunt_head_ref_cm": 6.0
            },
            "moves":
            [
                {"id": "thrust"},
                {"id": "oberhau"},
                {"id": "oberhau_feint"},
                {"id": "thrust_feint"},
                {"id": "unterhau"},
                {"id": "slash"},
                {"id": "zwerchau"},
                {"id": "bind_press"},
                {"id": "low_thrust_sword"},
                {"id": "pommel_strike"},
                {"id": "parry_thrust"},
                {"id": "parry_cut"}
            ]
        },
        # Battle axe: spike, chops, poll, parry-counter (Le Jeu de la Hache style).
        "AXE":
        {
            "name": "Axe",
            "default_form": "demi_hache",
            "allowed_forms": ["demi_hache", "bec_point", "queue_bind", "debout_haut", "envers", "wall", "balanced"],
            "form_legacy_aliases":
            {
                "wrath": "demi_hache",
                "aggressive": "demi_hache",
                "tempest": "debout_haut",
                "defensive": "wall",
                "ox": "bec_point",
                "plow": "queue_bind",
            },
            "mass": 1.5,
            "parry_speed_factor": 0.95,
            "bind_riposte_contact_types": ["cut", "stab"],
            "blade_width": 3.0,
            "point_width": 0.8,
            "thrust_head_width": 1.5,
            "head_diameter": 4.0,
            "edge_width": 0.0,
            "blade_cut_ratio": 0.6,
            "melee_range": 1.5,
            "parts":
            [
                {"id": "blade", "length_cm": 25, "mass_fraction": 0.4, "parry_eligible": true, "striking_for": ["cut"]},
                {
                    "id": "spike",
                    "length_cm": 8,
                    "mass_fraction": 0.15,
                    "parry_eligible": false,
                    "striking_for": ["stab"]
                },
                {
                    "id": "haft",
                    "length_cm": 90,
                    "mass_fraction": 0.45,
                    "parry_eligible": true,
                    "striking_for": ["blunt"]
                }
            ],
            "parry_part_id": "haft",
            "strike_physics":
            {
                "station_mean": 0.58,
                "station_spread": 0.12,
                "station_cut_vel_guard": 0.88,
                "station_cut_vel_tip": 1.07,
                "coupling_stab": 0.88,
                "coupling_cut": 0.92,
                "coupling_blunt": 0.98,
                "blunt_pressure": 1.05,
                "blunt_head_ref_cm": 6.0
            },
            "moves":
            [
                {"id": "spike_thrust"},
                {"id": "overhead_chop"},
                {"id": "overhead_feint"},
                {"id": "diagonal_chop"},
                {"id": "horizontal_chop"},
                {"id": "low_chop"},
                {"id": "reverse_grip_thrust"},
                {"id": "poll_strike"},
                {"id": "parry_chop"},
                {"id": "parry_thrust_axe"}
            ]
        },
        # Mace: overhead, side, direct, parry-counter (blunt only).
        "MACE":
        {
            "name": "Mace",
            "default_form": "crown_guard",
            "allowed_forms":
            ["crown_guard", "flank_guard", "envers", "debout_devant", "basse_garde", "wall", "balanced"],
            "form_legacy_aliases":
            {
                "wrath": "crown_guard",
                "aggressive": "crown_guard",
                "tempest": "flank_guard",
                "defensive": "wall",
                "braced": "basse_garde",
            },
            "mass": 1.7,
            "parry_speed_factor": 0.9,
            "blade_width": 0.0,
            "point_width": 0.5,
            "thrust_head_width": 2.0,
            "head_diameter": 8.0,
            "edge_width": 0.5,
            "blade_cut_ratio": 0.0,
            "melee_range": 1.3,
            "parts":
            [
                {
                    "id": "head",
                    "length_cm": 15,
                    "mass_fraction": 0.7,
                    "parry_eligible": false,
                    "striking_for": ["blunt"]
                },
                {"id": "shaft", "length_cm": 55, "mass_fraction": 0.3, "parry_eligible": true}
            ],
            "parry_part_id": "shaft",
            "strike_physics":
            {
                "station_mean": 0.62,
                "station_spread": 0.09,
                "station_cut_vel_guard": 0.92,
                "station_cut_vel_tip": 1.04,
                "coupling_stab": 0.95,
                "coupling_cut": 0.92,
                "coupling_blunt": 1.06,
                "blunt_pressure": 1.14,
                "blunt_head_ref_cm": 6.0
            },
            "moves":
            [
                {"id": "overhead_strike"},
                {"id": "side_strike"},
                {"id": "direct_blow"},
                {"id": "upcut_mace"},
                {"id": "low_strike"},
                {"id": "thrusting_blow"},
                {"id": "feint_overhead_mace"},
                {"id": "parry_strike"},
                {"id": "parry_thrust_mace"}
            ]
        },
        # Dagger / rondel: thrusts, slash, pommel, parry-counter (Fiore, Talhoffer).
        "DAGGER":
        {
            "name": "Dagger",
            "default_form": "high_hut",
            "allowed_forms": ["high_hut", "low_bind", "reverse_seize", "rovera", "dente_di_porc", "wall", "balanced"],
            "form_legacy_aliases":
            {
                "fool": "high_hut",
                "wrath": "high_hut",
                "aggressive": "high_hut",
                "controlling": "reverse_seize",
                "defensive": "wall",
                "ox": "high_hut",
            },
            "mass": 0.3,
            "parry_speed_factor": 1.2,
            "blade_width": 1.5,
            "point_width": 0.3,
            "thrust_head_width": 1.0,
            "head_diameter": 2.5,
            "edge_width": 0.0,
            "blade_cut_ratio": 0.9,
            "melee_range": 0.8,
            "parts":
            [
                {"id": "blade", "length_cm": 20, "mass_fraction": 0.55, "parry_eligible": true},
                {"id": "handle", "length_cm": 12, "mass_fraction": 0.45, "parry_eligible": false}
            ],
            "parry_part_id": "blade",
            "strike_physics":
            {
                "station_mean": 0.52,
                "station_spread": 0.08,
                "station_cut_vel_guard": 0.91,
                "station_cut_vel_tip": 1.1,
                "coupling_stab": 0.94,
                "coupling_cut": 0.92,
                "coupling_blunt": 0.9,
                "blunt_pressure": 0.95,
                "blunt_head_ref_cm": 6.0
            },
            "moves":
            [
                {"id": "quick_thrust"},
                {"id": "committed_thrust"},
                {"id": "reverse_thrust"},
                {"id": "low_thrust_dagger"},
                {"id": "feint_thrust_dagger"},
                {"id": "quick_slash"},
                {"id": "grab_strike"},
                {"id": "dagger_pommel"},
                {"id": "parry_thrust_dagger"}
            ]
        },
        # Spear (Fiore): thrusts, slash, pole swing (shaft), parry-counter.
        "SPEAR":
        {
            "name": "Spear",
            "default_form": "iron_gate",
            "allowed_forms":
            ["iron_gate", "true_cross", "high_port", "guarda_di_corpo", "guarda_di_corpo_basso", "wall", "balanced"],
            "form_legacy_aliases":
            {
                "plow": "iron_gate",
                "wrath": "high_port",
                "aggressive": "high_port",
                "ox": "true_cross",
                "defensive": "wall",
                "tempest": "high_port",
            },
            "mass": 1.8,
            "parry_speed_factor": 1.0,
            "blade_width": 2.5,
            "point_width": 0.6,
            "thrust_head_width": 2.5,
            "head_diameter": 3.5,
            "edge_width": 0.0,
            "blade_cut_ratio": 0.85,
            "melee_range": 2.5,
            "depth_melee_eligible": true,
            "parts":
            [
                {
                    "id": "head",
                    "length_cm": 25,
                    "mass_fraction": 0.15,
                    "parry_eligible": false,
                    "striking_for": ["stab", "cut"]
                },
                {
                    "id": "shaft",
                    "length_cm": 200,
                    "mass_fraction": 0.85,
                    "parry_eligible": true,
                    "striking_for": ["blunt"]
                }
            ],
            "parry_part_id": "shaft",
            "impact_velocity_bands": {"stab": {"min": 5.5, "max": 21.0}},
            "strike_physics":
            {
                "station_mean": 0.48,
                "station_spread": 0.11,
                "station_cut_vel_guard": 0.89,
                "station_cut_vel_tip": 1.05,
                "coupling_stab": 0.91,
                "coupling_cut": 0.92,
                "coupling_blunt": 0.99,
                "blunt_pressure": 1.02,
                "blunt_head_ref_cm": 6.0
            },
            "moves":
            [
                {"id": "spear_thrust"},
                {"id": "off_line_thrust"},
                {"id": "false_cut"},
                {"id": "inside_stab"},
                {"id": "low_thrust_spear"},
                {"id": "spear_slash"},
                {"id": "pole_swing"},
                {"id": "shaft_thrust"},
                {"id": "parry_thrust_spear"}
            ]
        }
    }


# Default cooldown when no weapon or unknown attack type
const DEFAULT_COOLDOWN: float = 1.5

# --- Attack archetypes: velocity arc, cut ratio, recovery/windup multiplier ---
# velocity_factor: 1.0 = full intensity -> full velocity; <1 = quicker attack, less KE.
# cut_ratio: 0-1 (rest blunt). Overridden by weapon blade_cut_ratio for slash/cut when not set in archetype.
# recovery_multiplier / windup_multiplier: scale state-machine timing.
const ARCHETYPE_STAB: String = "stab"
const ARCHETYPE_SLASH: String = "slash"
const ARCHETYPE_OVERHEAD: String = "overhead"
const ARCHETYPE_QUICK_SLASH: String = "quick_slash"
const ARCHETYPE_POMMEL: String = "pommel_strike"
const ARCHETYPE_HEAVY_BLUNT: String = "heavy_blunt"
const ARCHETYPE_THRUSTING_BLUNT: String = "thrusting_blunt"

## Kinematic delivery for `WeaponDamageHelper` (abstract  -  no unit positions): thrust = linear band + point-mass KE; swing = ???? - lever + rotational KE; mixed = blend (`kinematic_mixed_blend` 0..1).
const KINEMATIC_DELIVERY_THRUST := "thrust"
const KINEMATIC_DELIVERY_SWING := "swing"
const KINEMATIC_DELIVERY_MIXED := "mixed"


static func get_archetype(archetype_id: String) -> Dictionary:
    var all_arch := _archetype_definitions_build()
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


static func _archetype_definitions_build() -> Dictionary:
    return {
        ARCHETYPE_STAB:
        {
            "velocity_factor": 1.0,
            "velocity_intensity_curve": 0.95,
            "cut_ratio": -1.0,  # use weapon blade_cut_ratio
            "recovery_multiplier": 1.0,
            "windup_multiplier": 1.0,
            "kinematic_delivery": KINEMATIC_DELIVERY_THRUST
        },
        ARCHETYPE_SLASH:
        {
            "velocity_factor": 0.9,
            "velocity_intensity_curve": 1.04,
            "cut_ratio": -1.0,
            "recovery_multiplier": 1.0,
            "windup_multiplier": 1.0,
            "kinematic_delivery": KINEMATIC_DELIVERY_SWING
        },
        ARCHETYPE_OVERHEAD:
        {
            "velocity_factor": 1.0,
            "velocity_intensity_curve": 1.1,
            "cut_ratio": -1.0,
            "recovery_multiplier": 1.2,
            "windup_multiplier": 1.15,
            "kinematic_delivery": KINEMATIC_DELIVERY_SWING
        },
        ARCHETYPE_QUICK_SLASH:
        {
            "velocity_factor": 0.65,
            "velocity_intensity_curve": 0.8,
            "cut_ratio": -1.0,
            "recovery_multiplier": 0.85,
            "windup_multiplier": 0.8,
            "kinematic_delivery": KINEMATIC_DELIVERY_SWING
        },
        ARCHETYPE_POMMEL:
        {
            "velocity_factor": 0.7,
            "velocity_intensity_curve": 0.88,
            "cut_ratio": 0.05,
            "recovery_multiplier": 0.9,
            "windup_multiplier": 0.85,
            "kinematic_delivery": KINEMATIC_DELIVERY_SWING
        },
        ARCHETYPE_HEAVY_BLUNT:
        {
            "velocity_factor": 1.0,
            "velocity_intensity_curve": 1.12,
            "cut_ratio": 0.05,
            "recovery_multiplier": 1.15,
            "windup_multiplier": 1.1,
            "kinematic_delivery": KINEMATIC_DELIVERY_SWING
        },
        ARCHETYPE_THRUSTING_BLUNT:
        {
            "velocity_factor": 0.85,
            "velocity_intensity_curve": 0.95,
            "cut_ratio": 0.05,
            "recovery_multiplier": 0.95,
            "windup_multiplier": 0.9,
            "kinematic_delivery": KINEMATIC_DELIVERY_THRUST
        }
    }


## Weapon template id (`SWORD`, `AXE`, �) from equipped weapon node/dict.
static func weapon_type_id(weapon: Variant) -> String:
    return _weapon_template_id(weapon)


static func _weapon_template_id(weapon: Variant) -> String:
    if weapon == null:
        return ""
    if weapon is Object:
        var wt: Variant = weapon.get("weapon_type")
        if wt != null:
            return str(wt).strip_edges().to_upper()
    return ""


## Legacy encounter / mood keys -> weapon-native form id (e.g. axe `wrath` -> `demi_hache`).
static func resolve_form_legacy_alias(weapon: Variant, raw_form: String) -> String:
    var s: String = str(raw_form).strip_edges().to_lower()
    if s.is_empty():
        return s
    var wt: String = _weapon_template_id(weapon)
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
static func default_form_for_weapon(weapon: Variant) -> String:
    var wt: String = _weapon_template_id(weapon)
    if wt.is_empty():
        return "balanced"
    var def: Dictionary = get_weapon_definition(wt)
    if def.is_empty():
        return "balanced"
    return str(def.get("default_form", "balanced")).strip_edges().to_lower()


## Expand WF: allowed form ids for weapon template; empty ?????? no clamp.
static func allowed_forms_for_weapon(weapon: Variant) -> Array:
    var wt: String = _weapon_template_id(weapon)
    if wt.is_empty():
        return ["balanced", "wall"]
    var def: Dictionary = get_weapon_definition(wt)
    if def.is_empty():
        return ["balanced"]
    var raw: Variant = def.get("allowed_forms", [])
    if raw is Array:
        return raw
    return ["balanced"]
