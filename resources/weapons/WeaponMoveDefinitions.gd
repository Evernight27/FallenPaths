class_name WeaponMoveDefinitions
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


static func _move_definitions_build() -> Dictionary:
    # attack_line: Liechtenauer 4 lines - high (0°), low (180°), left (270°), right (90°) + compound octants
    # high_left, high_right, low_left. Blade path, not body target.
    # angle_variance_deg: optional ~3deg human error; heavier/awkward moves have more variance.
    # angle_offset_deg: optional bias from base line (e.g. off_line_thrust angled toward flank).
    # impact_station_mean: fraction along weapon from hands (0=hands, 1=tip). Spear thrusts may exceed 0.8 due to long
    # shaft; clamped at 0.80.
    # impact_station_spread: per-strike jitter around mean. Precision strikes use small nonzero value (0.01-0.02).
    return {
        "thrust":
        {
            # Sword (Liechtenauer/KDF): thrust, Oberhau, Unterhau, horizontal (Zwerchau-style), pommel, parry-counters
            "name": "Point thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
            "base_cooldown": 2.4,
            "attack_line": "high_right",
            "preferred_parts": ["head"],
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.78,
            "impact_station_mean": 0.70,
            "impact_station_spread": 0.05
        },
        "oberhau_feint":
        # Tier 4.2: optional feint_windup_duration_mult (>1)  -  extra wind-up vs same-archetype honest cut
        {
            # (two-line commitment cost).
            "name": "Feint high, cut low",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
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
        # Tier 4.2: stab feint  -  feint_target_reveal_at_progress earlier than oberhau_feint (faster thrust
        {
            # telegraph); feint_windup_duration_mult < cut feint (stab archetype already tighter).
            "name": "Feint line, thrust true",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_POMMEL,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.0,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "impact_station_mean": 0.74,
            "impact_station_spread": 0.03
        },
        "parry_cut":
        {
            "name": "Parry and cut",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
            "base_cooldown": 1.9,
            "is_parry": true,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm"],
            "impact_station_mean": 0.62,
            "impact_station_spread": 0.05
        },
        "zornhau":
        {
            # Liechtenauer Meisterhäue — decisive counter-strikes with yomi-intent scaling.
            # Zornhau: parry high-right, cut low-left (wound from above through guard).
            "name": "Zornhau (wrath strike)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
            "base_cooldown": 2.8,
            "attack_line": "low_left",
            "preferred_parts": ["left_arm", "right_leg"],
            "angle_variance_deg": 8,
            "weapon_extension_commit_fraction": 0.76,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.04
        },
        "scheitelhau":
        {
            # Scheitelhau:Decapitator — overhead cut from high with wide arc, targets head heavily.
            "name": "Scheitelhau (decapitator)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
            "base_cooldown": 3.0,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 14,
            "weapon_extension_commit_fraction": 0.82,
            "impact_station_mean": 0.74,
            "impact_station_spread": 0.07
        },
        "krumphau":
        {
            # Krumphau — binding strike that wraps around opponent blade to expose inner line.
            "name": "Krumphau (hook cut)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
            "base_cooldown": 2.4,
            "attack_line": "high_left",
            "preferred_parts": ["left_arm", "head"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.54,
            "impact_station_mean": 0.30,
            "impact_station_spread": 0.03
        },
        "schielhau":
        {
            # Schielhau (peeking cut) — feint high-right, strike from low-right past guard edge.
            "name": "Schielhau (peeking cut)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
            "base_cooldown": 2.6,
            "is_feint": true,
            "feint_windup_duration_mult": 1.08,
            "feint_target_reveal_at_progress": 0.42,
            "attack_line": "high_right",
            "preferred_parts": ["head", "right_arm"],
            "angle_variance_deg": 9,
            "weapon_extension_commit_fraction": 0.78,
            "impact_station_mean": 0.66,
            "impact_station_spread": 0.05
        },
        "spike_thrust":
        {
            # Axe (Le Jeu de la Hache): spike, overhead chop, diagonal chop, poll
            "name": "Spike thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
            "base_cooldown": 3.0,
            "attack_line": "high_left",
            "preferred_parts": ["left_arm", "right_arm", "chest"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.68,
            "impact_station_spread": 0.06
        },
        "poll_strike":
        {
            # Axe poll strike uses blunt haft contact — swing path with long lever creates excess KE due to high inertia;
            # ARCHETYPE_POLL_STRIKE has velocity_factor=0.62 to cap rotational KE to ~151J (in 40-155J axe band).
            "name": "Back-of-head strike (blunt)",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_POLL_STRIKE,
            "base_cooldown": 3.0,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 11,
            "impact_station_mean": 0.22,
            "impact_station_spread": 0.02,
            # strike_energy_mult_override retained for historical reference; no longer consumed by attack pipeline.
            "strike_energy_mult_override": 0.40
        },
        "parry_chop":
        {
            "name": "Parry and chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_QUICK_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_POMMEL,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.6,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.58,
            "impact_station_mean": 0.80,
            "impact_station_spread": 0.0
        },
        "off_line_thrust":
        {
            "name": "Angled thrust",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.5,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 15,
            "angle_offset_deg": 25,
            "impact_station_mean": 0.78,
            "impact_station_spread": 0.04
        },
        "spear_slash":
        {
            # Spear cut: very long lever (2.05m) suppresses KE via the 1/r² penalty. Uses ARCHETYPE_POLE_SLASH
            # (vf=0.80, swing) + the spear's Tier C cut band (5-14 m/s) so committed slashes land ~55-66J
            # (in the 45-130J spear band) instead of the ~17-30J the shared POLE_SWING vf=0.62 produced.
            "name": "Slash with spearhead",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_POLE_SLASH,
            "base_cooldown": 2.8,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm"],
            "angle_variance_deg": 10,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.05,
            # strike_energy_mult_override retained for historical reference; no longer consumed by attack pipeline.
            "strike_energy_mult_override": 1.5
        },
        "pole_swing":
        {
            # Pole swing uses shaft butt/head — long weapon but strike occurs near grip (shaft COM).
            # ARCHETYPE_POLE_SWING has velocity_factor=0.62 and inertia_scale=0.85 to keep KE in realistic range.
            "name": "Pole swing (blunt)",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_POLE_SWING,
            "base_cooldown": 2.5,
            "attack_line": "left",
            "preferred_parts": ["left_arm", "right_arm", "head"],
            "angle_variance_deg": 12,
            "impact_station_mean": 0.55,
            "impact_station_spread": 0.08
        },
        "zwerchau":
        # SWORD additions (HEMA expansion): zwerchau (inside-line crossing cut), bind_press (post-bind center
        {
            # thrust), low_thrust (leg/groin)
            "name": "Crossing cut (Zwerchau)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.1,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.54,
            "impact_station_mean": 0.76,
            "impact_station_spread": 0.03
        },
        "bind_void":
        {
            "name": "Slip offline (Void)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.3,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.45,
            "impact_station_mean": 0.70,
            "impact_station_spread": 0.05
        },
        "bind_wind":
        {
            "name": "Rotate the bind (Wind)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
            "base_cooldown": 2.2,
            "attack_line": "high_left",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 9,
            "weapon_extension_commit_fraction": 0.50,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.04
        },
        "bind_wrestle":
        # HEMA bind-to-wrestling transition: from a sustained hard bind the binder closes to a body
        # grab, unbalancing the fatigued opponent. Gated on BIND_WRESTLING_AVAILABLE.
        {
            "name": "Close the bind (Wrestle)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.5,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 7,
            "weapon_extension_commit_fraction": 0.40,
            "impact_station_mean": 0.80,
            "impact_station_spread": 0.03
        },
        "verwunden":
        # HEMA circumscription: compound cut that draws the opponent's blade off one line (the
        # feint) and strikes the far side of the committed guard. is_feint carries the around-motion
        # wind-up cost + early reveal; circumscription marks the open-line payoff as the OPPOSITE line
        # (the side the committed blade can no longer reach) rather than the strike line itself.
        {
            "name": "Circumference cut (Verwunden)",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
            "base_cooldown": 2.4,
            "attack_line": "high",
            "preferred_parts": ["head", "chest"],
            "is_feint": true,
            "circumscription": true,
            "feint_windup_duration_mult": 1.15,
            "feint_target_reveal_at_progress": 0.5,
            "angle_variance_deg": 10,
            "weapon_extension_commit_fraction": 0.60,
            "impact_station_mean": 0.70,
            "impact_station_spread": 0.05
        },
        "low_thrust_sword":
        {
            "name": "Low thrust (Grifo)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.0,
            "attack_line": "low",
            "preferred_parts": ["left_leg", "right_leg"],
            "angle_variance_deg": 8,
            "weapon_extension_commit_fraction": 0.55,
            "impact_station_mean": 0.72,
            "impact_station_spread": 0.03
        },
        "horizontal_chop":
        # AXE additions (Le Jeu de la Hache expansion): horizontal_chop, low_chop, reverse_grip_thrust,
        {
            # overhead_feint, parry_thrust_axe
            "name": "Horizontal chop",
            "contact_type": ATTACK_TYPE_CUT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_SLASH,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
            "base_cooldown": 2.5,
            "is_parry": true,
            "attack_line": "high",
            "preferred_parts": ["chest"],
            "angle_variance_deg": 9,
            "impact_station_mean": 0.74,
            "impact_station_spread": 0.03
        },
        "upcut_mace":
        # MACE additions (Vadi/Talhoffer expansion): upcut_mace, low_strike, thrusting_blow, feint_overhead_mace,
        {
            # parry_thrust_mace
            "name": "Rising mace blow",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_THRUSTING_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_THRUSTING_BLUNT,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_POMMEL,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            # Spear shaft butt strike — uses body mass transfer through the long shaft;
            # default BLUNT strike_mass (0.55 kg) is too low for this move type.
            "name": "Shaft butt strike",
            "contact_type": ATTACK_TYPE_BLUNT,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_THRUSTING_BLUNT,
            "base_cooldown": 2.0,
            "attack_line": "high",
            "preferred_parts": ["head"],
            "angle_variance_deg": 10,
            "impact_station_mean": 0.15,
            "impact_station_spread": 0.02,
            "strike_mass_override_kg": 2.5
        },
        "low_thrust_spear":
        {
            "name": "Low thrust (legs)",
            "contact_type": ATTACK_TYPE_STAB,
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
            "archetype_id": WeaponTemplateDefinitions.ARCHETYPE_STAB,
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
# Dimensions: blade_width = edge contact for cuts; point_width = tip for thrusts; head_diameter = striking head for
# blunt.
# thrust_head_width = width of head/shaft behind point (cm); used for blunt momentum/area on thrusts. Broader head =
# lower p/A.
# edge_width = effective sharp contact for blunt weapons (flanges/ridges that can break skin); used for sharp-component
# penetration.
# impact_velocity_bands (optional): Tier C overrides  -  keys stab|cut|blunt -> {"min":m/s,"max":m/s} or Vector2;
# see ImpactVelocityModel.gd.
# Data: Oakeshott/longsword 2 - 3 cm edge, 0.3 - 0.6 cm point; Le Jeu axe 3 - 4 cm edge, 0.5 - 1 cm spike; mace flanges
# 0.4 - 0.6 cm (Williams, Tod Cutler); Fiore/Talhoffer dagger ~1.5 cm edge, 0.2 - 0.4 cm point; spear 0.4 - 0.8 cm
# point, head blade 2 - 3 cm.
# No weapon has 0% cutting (MIN_CUT_RATIO); each component uses get_sharp_contact_cm / get_blunt_contact_cm for its
# damage type.



