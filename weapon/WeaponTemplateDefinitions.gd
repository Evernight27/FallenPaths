class_name WeaponTemplateDefinitions
extends RefCounted

## Per-weapon move defs + Expand WF spawn keys: **`default_form`** / **`allowed_forms[]`** feed
## **`CombatWeaponForm.seed_combatant_form`** (resolution step 4). LIVE_PATHS **`#spawn--reset-path-wf-1a`** ??
## **`#wf-assign-form-contract`**.

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

## Kinematic delivery for `WeaponDamageHelper` (abstract  -  no unit positions): thrust = linear band + point-mass KE;
## swing = ???? - lever + rotational KE; mixed = blend (`kinematic_mixed_blend` 0..1).
const KINEMATIC_DELIVERY_THRUST := "thrust"
const KINEMATIC_DELIVERY_SWING := "swing"
const KINEMATIC_DELIVERY_MIXED := "mixed"


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


static func _weapon_template_id(weapon: Variant) -> String:
    if weapon == null:
        return ""
    if weapon is Object:
        var wt: Variant = weapon.get("weapon_type")
        if wt != null:
            return str(wt).strip_edges().to_upper()
    return ""

## Legacy encounter / mood keys -> weapon-native form id (e.g. axe `wrath` -> `demi_hache`).
