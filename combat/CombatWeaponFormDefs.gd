class_name CombatWeaponFormDefs
extends RefCounted

## Weapon-scoped form/posture tables for **`CombatWeaponForm`**.
## SWORD: Liechtenauer Vier Leger + Meyer secondaries. Other weapons: treatise-specific guards.
## Canonical: **`CombatWeaponForm._def(form, weapon)`** resolves here.

const _CombatConstants := preload("res://combat/CombatConstants.gd")


static func _neutral_mod() -> Dictionary:
    return {
        "parry": 1.0,
        "evasion": 1.0,
        "damage": 1.0,
        "close_attempt": 1.0,
        "ai_melee_focus": 1.0,
        "feint_readthrough": 1.0,
        "ai_feint_listing": 1.0,
    }


static func build_all() -> Dictionary:
    return {
        "SWORD": _sword_forms(),
        "AXE": _axe_forms(),
        "MACE": _mace_forms(),
        "DAGGER": _dagger_forms(),
        "SPEAR": _spear_forms(),
    }


static func _sword_forms() -> Dictionary:
    return {
        "wall":
        {
            "display_name": "Wall",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_right", "high_left"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.18,
            "wait_weight_mult": 1.35,
            "mod":
            {
                "parry": 1.2,
                "evasion": 1.15,
                "damage": 0.85,
                "close_attempt": 0.9,
                "ai_melee_focus": 0.92,
                "feint_readthrough": 1.06,
                "ai_feint_listing": 0.94,
            },
            "move_family_mult":
            {
                "thrust": 1.0,
                "high_cut": 0.88,
                "low_cut": 0.9,
                "slash": 0.75,
                "feint": 0.8,
                "parry": 1.15,
                "close": 0.85,
            },
            "move_id_mult": {},
            "signature":
            {
                "move_ids": {"thrust": 0.85, "oberhau": 0.7},
                "contact_types": {"stab": 0.9, "cut": 0.75},
                "lines": {"high": 1.0, "high_right": 0.85},
                "feint_bias": 0.35,
            },
            "counters":
            {
                "wrath": {"mult": 1.1, "families": ["parry", "feint"]},
                "tempest": {"mult": 1.08, "families": ["parry"]},
            },
            "target_part_bias": {"chest": 1.12, "head": 0.92},
            "move_family_part_bias": {"parry": {"chest": 1.08}},
            "duel_offense_forms": PackedStringArray(),
        },
        "balanced":
        {
            "display_name": "Balanced",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod": _neutral_mod(),
            "move_family_mult": {},
            "move_id_mult": {},
            "signature": {"move_ids": {}, "contact_types": {}, "lines": {"high": 0.35}, "feint_bias": 0.1},
            "counters": {},
            "target_part_bias": {},
            "move_family_part_bias": {},
            "duel_offense_forms": PackedStringArray(),
        },
        "wrath":
        {
            "display_name": "Wrath",
            "home_guard": "high_left",
            "preferred_guards": PackedStringArray(["high_left", "high_right"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.28,
            "wait_weight_mult": 0.85,
            "mod":
            {
                "parry": 0.8,
                "evasion": 0.85,
                "damage": 1.2,
                "close_attempt": 1.1,
                "ai_melee_focus": 1.1,
                "feint_readthrough": 0.95,
                "ai_feint_listing": 1.02,
            },
            "move_family_mult":
            {
                "thrust": 0.9,
                "high_cut": 1.18,
                "low_cut": 1.05,
                "slash": 1.08,
                "feint": 1.0,
                "parry": 0.92,
                "close": 1.1,
            },
            "move_id_mult": {"oberhau": 1.15, "slash": 1.08},
            "signature":
            {
                "move_ids": {"oberhau": 1.2, "slash": 1.0, "unterhau": 0.85},
                "contact_types": {"cut": 1.0},
                "lines": {"high": 0.9, "high_left": 0.75, "high_right": 0.7},
                "feint_bias": 0.12,
            },
            "counters":
            {
                "plow": {"mult": 1.1, "families": ["high_cut", "slash"]},
                "fool": {"mult": 1.06, "families": ["high_cut"]},
            },
            "target_part_bias": {"head": 1.18, "left_arm": 1.08, "right_arm": 1.08},
            "move_family_part_bias":
            {
                "high_cut": {"head": 1.15, "left_arm": 1.06, "right_arm": 1.06},
                "slash": {"left_arm": 1.08, "right_arm": 1.08},
            },
            "duel_offense_forms": PackedStringArray(["wrath", "fool", "ox"]),
        },
        "fool":
        {
            "display_name": "Fool",
            "home_guard": "low_left",
            "preferred_guards": PackedStringArray(["low_left", "low"]),
            "pressure_class": "controlling",
            "min_stamina_ratio": 0.24,
            "wait_weight_mult": 0.95,
            "mod":
            {
                "parry": 1.0,
                "evasion": 1.0,
                "damage": 0.95,
                "close_attempt": 1.0,
                "ai_melee_focus": 0.98,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 1.06,
            },
            "move_family_mult":
            {
                "thrust": 0.95,
                "high_cut": 0.92,
                "low_cut": 1.1,
                "slash": 0.95,
                "feint": 1.25,
                "parry": 1.02,
                "close": 1.0,
            },
            "move_id_mult":
            {
                "oberhau_feint": 1.2,
                "thrust_feint": 1.15,
                "unterhau": 1.1,
            },
            "signature":
            {
                "move_ids": {"oberhau_feint": 1.25, "thrust_feint": 1.2, "unterhau": 1.1},
                "contact_types": {"cut": 0.55},
                "lines": {"low": 0.75, "low_left": 0.85},
                "feint_bias": 1.45,
            },
            "counters":
            {
                "ox": {"mult": 1.12, "families": ["feint", "thrust", "low_cut"]},
                "wrath": {"mult": 1.06, "families": ["feint"]},
            },
            "target_part_bias": {"left_leg": 1.15, "right_leg": 1.15, "head": 0.92},
            "move_family_part_bias":
            {
                "low_cut": {"left_leg": 1.12, "right_leg": 1.12},
                "feint": {"head": 1.10},
            },
            "duel_offense_forms": PackedStringArray(["wrath", "fool", "ox"]),
        },
        "ox":
        {
            "display_name": "Ox",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high_right", "high"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.2,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.08,
                "evasion": 1.04,
                "damage": 1.04,
                "close_attempt": 1.0,
                "ai_melee_focus": 1.02,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.98,
            },
            "move_family_mult":
            {
                "thrust": 1.15,
                "high_cut": 0.95,
                "low_cut": 0.85,
                "slash": 0.95,
                "feint": 0.95,
                "parry": 1.08,
                "close": 1.0,
            },
            "move_id_mult": {"thrust": 1.2, "oberhau": 0.75},
            "signature":
            {
                "move_ids": {"thrust": 1.25, "oberhau": 0.65},
                "contact_types": {"stab": 1.2, "cut": 0.55},
                "lines": {"high_right": 0.85, "high": 0.65},
                "feint_bias": 0.08,
            },
            "counters":
            {
                "fool": {"mult": 1.1, "families": ["thrust"]},
                "tempest": {"mult": 1.08, "families": ["thrust", "parry"]},
            },
            "target_part_bias": {"chest": 1.18, "head": 1.05},
            "move_family_part_bias": {"thrust": {"chest": 1.15, "head": 1.05}},
            "duel_offense_forms": PackedStringArray(["wrath", "fool", "ox"]),
        },
        "plow":
        {
            "display_name": "Plow",
            "home_guard": "low",
            "preferred_guards": PackedStringArray(["low", "high"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.14,
                "evasion": 1.06,
                "damage": 0.96,
                "close_attempt": 0.94,
                "ai_melee_focus": 0.94,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 0.96,
            },
            "move_family_mult":
            {
                "thrust": 1.2,
                "high_cut": 0.88,
                "low_cut": 0.95,
                "slash": 0.9,
                "feint": 0.92,
                "parry": 1.1,
                "close": 0.95,
            },
            "move_id_mult": {"thrust": 1.25},
            "signature":
            {
                "move_ids": {"thrust": 1.3},
                "contact_types": {"stab": 1.25},
                "lines": {"low": 0.8, "high": 0.55},
                "feint_bias": 0.06,
            },
            "counters": {"wrath": {"mult": 1.08, "families": ["thrust", "high_cut"]}},
            "target_part_bias": {"chest": 1.12, "head": 1.02},
            "move_family_part_bias": {"thrust": {"chest": 1.12}},
            "duel_offense_forms": PackedStringArray(),
        },
        "tempest":
        {
            "display_name": "Tempest",
            "home_guard": "left",
            "preferred_guards": PackedStringArray(["left", "right"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.26,
            "wait_weight_mult": 0.9,
            "mod":
            {
                "parry": 0.84,
                "evasion": 0.88,
                "damage": 1.18,
                "close_attempt": 1.08,
                "ai_melee_focus": 1.08,
                "feint_readthrough": 0.94,
                "ai_feint_listing": 1.04,
            },
            "move_family_mult":
            {
                "thrust": 0.92,
                "high_cut": 1.12,
                "low_cut": 1.0,
                "slash": 1.2,
                "feint": 1.05,
                "parry": 0.9,
                "close": 1.05,
            },
            "move_id_mult": {"slash": 1.18, "oberhau": 1.05},
            "signature":
            {
                "move_ids": {"slash": 1.2, "oberhau": 0.95},
                "contact_types": {"cut": 1.05},
                "lines": {"left": 0.85, "right": 0.85, "high": 0.6},
                "feint_bias": 0.18,
            },
            "counters":
            {
                "wall": {"mult": 1.1, "families": ["slash", "high_cut"]},
                "ox": {"mult": 1.06, "families": ["slash"]},
            },
            "target_part_bias": {"left_arm": 1.12, "right_arm": 1.12, "head": 1.10},
            "move_family_part_bias":
            {
                "slash": {"left_arm": 1.12, "right_arm": 1.12, "head": 1.08},
            },
            "duel_offense_forms": PackedStringArray(),
        },
    }


static func _axe_forms() -> Dictionary:
    # Le Jeu de la Hache: demi-hache ready, bec/spike point, queue bind.
    return {
        "balanced": _balanced_entry("Balanced"),
        "wall":
        {
            "display_name": "High Ward",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_left"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.3,
            "mod":
            {
                "parry": 1.18,
                "evasion": 1.08,
                "damage": 0.88,
                "close_attempt": 0.88,
                "ai_melee_focus": 0.90,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 0.92,
            },
            "move_family_mult":
            {
                "thrust": 0.85,
                "high_cut": 0.82,
                "slash": 0.80,
                "parry": 1.18,
                "close": 0.82,
            },
            "move_id_mult": {"parry_chop": 1.2},
            "signature":
            {
                "move_ids": {"parry_chop": 1.1, "overhead_chop": 0.75},
                "contact_types": {"cut": 0.8},
                "lines": {"high": 1.0},
                "feint_bias": 0.2,
            },
            "counters": {"demi_hache": {"mult": 1.08, "families": ["parry"]}},
            "target_part_bias": {"chest": 1.08, "head": 0.94},
            "move_family_part_bias": {"parry": {"left_arm": 1.1}},
            "duel_offense_forms": PackedStringArray(),
        },
        "demi_hache":
        {
            "display_name": "Demi-hache",
            "home_guard": "high_left",
            "preferred_guards": PackedStringArray(["high", "high_left"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.28,
            "wait_weight_mult": 0.88,
            "mod":
            {
                "parry": 0.85,
                "evasion": 0.88,
                "damage": 1.22,
                "close_attempt": 1.05,
                "ai_melee_focus": 1.12,
                "feint_readthrough": 0.96,
                "ai_feint_listing": 0.98,
            },
            "move_family_mult":
            {
                "thrust": 0.72,
                "high_cut": 1.22,
                "slash": 1.15,
                "feint": 0.75,
                "parry": 0.90,
                "close": 1.0,
            },
            "move_id_mult":
            {
                "overhead_chop": 1.28,
                "diagonal_chop": 1.22,
                "spike_thrust": 0.78,
                "poll_strike": 1.05,
            },
            "signature":
            {
                "move_ids": {"overhead_chop": 1.25, "diagonal_chop": 1.15},
                "contact_types": {"cut": 1.1, "blunt": 0.9},
                "lines": {"high": 0.95, "high_left": 0.85},
                "feint_bias": 0.15,
            },
            "counters":
            {
                "bec_point": {"mult": 1.1, "families": ["high_cut", "slash"]},
                "queue_bind": {"mult": 1.06, "families": ["high_cut"]},
            },
            "target_part_bias": {"head": 1.20, "left_arm": 1.10, "right_arm": 1.10},
            "move_family_part_bias":
            {
                "high_cut": {"head": 1.18, "left_arm": 1.08, "right_arm": 1.08},
            },
            "duel_offense_forms": PackedStringArray(["demi_hache", "bec_point"]),
        },
        "bec_point":
        {
            "display_name": "Bec point",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high_right", "high"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.05,
                "evasion": 1.02,
                "damage": 1.05,
                "close_attempt": 0.98,
                "ai_melee_focus": 1.04,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.96,
            },
            "move_family_mult":
            {
                "thrust": 1.25,
                "high_cut": 0.78,
                "slash": 0.82,
                "parry": 1.05,
                "close": 0.95,
            },
            "move_id_mult": {"spike_thrust": 1.35, "overhead_chop": 0.70, "diagonal_chop": 0.75},
            "signature":
            {
                "move_ids": {"spike_thrust": 1.3},
                "contact_types": {"stab": 1.25},
                "lines": {"high": 0.8, "high_right": 0.9},
                "feint_bias": 0.08,
            },
            "counters": {"demi_hache": {"mult": 1.1, "families": ["thrust"]}},
            "target_part_bias": {"chest": 1.18, "head": 1.05},
            "move_family_part_bias": {"thrust": {"chest": 1.15}},
            "duel_offense_forms": PackedStringArray(["demi_hache", "bec_point"]),
        },
        "queue_bind":
        {
            "display_name": "Queue bind",
            "home_guard": "low",
            "preferred_guards": PackedStringArray(["low", "high"]),
            "pressure_class": "controlling",
            "min_stamina_ratio": 0.24,
            "wait_weight_mult": 0.95,
            "mod":
            {
                "parry": 1.0,
                "evasion": 0.98,
                "damage": 1.0,
                "close_attempt": 1.12,
                "ai_melee_focus": 0.96,
                "feint_readthrough": 1.05,
                "ai_feint_listing": 1.0,
            },
            "move_family_mult":
            {
                "thrust": 0.88,
                "high_cut": 0.85,
                "slash": 0.88,
                "parry": 1.05,
                "close": 1.15,
            },
            "move_id_mult": {"poll_strike": 1.28, "parry_chop": 1.05},
            "signature":
            {
                "move_ids": {"poll_strike": 1.2, "parry_chop": 0.9},
                "contact_types": {"blunt": 1.15},
                "lines": {"low": 0.7, "high": 0.55},
                "feint_bias": 0.12,
            },
            "counters": {"demi_hache": {"mult": 1.08, "families": ["close"]}},
            "target_part_bias": {"head": 1.12, "chest": 1.08},
            "move_family_part_bias": {"high_cut": {"head": 1.1}},
            "duel_offense_forms": PackedStringArray(),
        },
        "debout_haut":
        {
            "display_name": "Debout haut",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high_right", "high"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.26,
            "wait_weight_mult": 0.88,
            "mod":
            {
                "parry": 0.86,
                "evasion": 0.88,
                "damage": 1.20,
                "close_attempt": 1.08,
                "ai_melee_focus": 1.10,
                "feint_readthrough": 0.94,
                "ai_feint_listing": 1.02,
            },
            "move_family_mult":
            {
                "thrust": 0.75,
                "high_cut": 1.20,
                "slash": 1.10,
                "feint": 0.90,
                "parry": 0.88,
                "close": 1.05,
            },
            "move_id_mult":
            {
                "overhead_chop": 1.25,
                "horizontal_chop": 1.15,
                "overhead_feint": 1.10,
            },
            "signature":
            {
                "move_ids": {"overhead_chop": 1.20, "horizontal_chop": 1.10},
                "contact_types": {"cut": 1.08},
                "lines": {"high": 0.9, "high_right": 0.85},
                "feint_bias": 0.14,
            },
            "counters":
            {
                "bec_point": {"mult": 1.08, "families": ["high_cut", "slash"]},
            },
            "target_part_bias": {"head": 1.16, "left_arm": 1.08, "right_arm": 1.08},
            "move_family_part_bias":
            {
                "high_cut": {"head": 1.14},
            },
            "duel_offense_forms": PackedStringArray(["demi_hache", "debout_haut"]),
        },
        "envers":
        {
            "display_name": "Envers",
            "home_guard": "high_left",
            "preferred_guards": PackedStringArray(["high_left", "left"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.04,
                "evasion": 1.02,
                "damage": 1.06,
                "close_attempt": 0.98,
                "ai_melee_focus": 1.02,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.98,
            },
            "move_family_mult":
            {
                "thrust": 1.0,
                "high_cut": 0.92,
                "slash": 1.08,
                "parry": 1.04,
                "close": 0.96,
            },
            "move_id_mult":
            {
                "diagonal_chop": 1.15,
                "low_chop": 1.10,
                "reverse_grip_thrust": 1.05,
            },
            "signature":
            {
                "move_ids": {"diagonal_chop": 1.10, "low_chop": 1.05},
                "contact_types": {"cut": 1.02},
                "lines": {"high_left": 0.85, "left": 0.75},
                "feint_bias": 0.10,
            },
            "counters":
            {
                "demi_hache": {"mult": 1.06, "families": ["slash"]},
            },
            "target_part_bias": {"left_arm": 1.10, "right_arm": 1.10, "chest": 1.05},
            "move_family_part_bias":
            {
                "slash": {"left_arm": 1.08, "right_arm": 1.08},
            },
            "duel_offense_forms": PackedStringArray(),
        },
    }


static func _mace_forms() -> Dictionary:
    return {
        "balanced": _balanced_entry("Balanced"),
        "wall":
        {
            "display_name": "Braced ward",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_left", "high_right"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.32,
            "mod":
            {
                "parry": 1.15,
                "evasion": 1.05,
                "damage": 0.88,
                "close_attempt": 0.88,
                "ai_melee_focus": 0.90,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.90,
            },
            "move_family_mult":
            {
                "high_cut": 0.85,
                "slash": 0.82,
                "parry": 1.12,
                "close": 0.85,
            },
            "move_id_mult": {"parry_strike": 1.15, "overhead_strike": 0.80},
            "signature":
            {
                "move_ids": {"parry_strike": 1.0},
                "contact_types": {"blunt": 0.95},
                "lines": {"high": 1.0},
                "feint_bias": 0.05,
            },
            "counters": {"crown_guard": {"mult": 1.06, "families": ["parry"]}},
            "target_part_bias": {"chest": 1.10, "head": 0.95},
            "move_family_part_bias": {},
            "duel_offense_forms": PackedStringArray(),
        },
        "crown_guard":
        {
            "display_name": "Crown guard",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_left"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.30,
            "wait_weight_mult": 0.86,
            "mod":
            {
                "parry": 0.82,
                "evasion": 0.86,
                "damage": 1.25,
                "close_attempt": 1.02,
                "ai_melee_focus": 1.14,
                "feint_readthrough": 0.92,
                "ai_feint_listing": 0.88,
            },
            "move_family_mult":
            {
                "high_cut": 1.25,
                "slash": 0.90,
                "parry": 0.88,
                "close": 1.0,
            },
            "move_id_mult":
            {
                "overhead_strike": 1.32,
                "direct_blow": 1.18,
                "side_strike": 0.78,
            },
            "signature":
            {
                "move_ids": {"overhead_strike": 1.3, "direct_blow": 1.1},
                "contact_types": {"blunt": 1.15},
                "lines": {"high": 1.0},
                "feint_bias": 0.06,
            },
            "counters": {"flank_guard": {"mult": 1.08, "families": ["high_cut"]}},
            "target_part_bias": {"head": 1.25, "chest": 1.08},
            "move_family_part_bias": {"high_cut": {"head": 1.22}},
            "duel_offense_forms": PackedStringArray(["crown_guard", "flank_guard"]),
        },
        "flank_guard":
        {
            "display_name": "Flank guard",
            "home_guard": "right",
            "preferred_guards": PackedStringArray(["right", "left"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.26,
            "wait_weight_mult": 0.92,
            "mod":
            {
                "parry": 0.88,
                "evasion": 0.90,
                "damage": 1.15,
                "close_attempt": 1.0,
                "ai_melee_focus": 1.08,
                "feint_readthrough": 0.95,
                "ai_feint_listing": 0.92,
            },
            "move_family_mult":
            {
                "high_cut": 0.95,
                "slash": 1.18,
                "parry": 0.92,
                "close": 1.0,
            },
            "move_id_mult":
            {
                "side_strike": 1.30,
                "overhead_strike": 0.85,
                "direct_blow": 0.95,
            },
            "signature":
            {
                "move_ids": {"side_strike": 1.25},
                "contact_types": {"blunt": 1.08},
                "lines": {"right": 0.9, "left": 0.85},
                "feint_bias": 0.08,
            },
            "counters": {"crown_guard": {"mult": 1.08, "families": ["slash"]}},
            "target_part_bias": {"left_arm": 1.15, "right_arm": 1.15},
            "move_family_part_bias": {"slash": {"left_arm": 1.12, "right_arm": 1.12}},
            "duel_offense_forms": PackedStringArray(["crown_guard", "flank_guard"]),
        },
        "envers":
        {
            "display_name": "Envers",
            "home_guard": "high_left",
            "preferred_guards": PackedStringArray(["high_left", "left"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.04,
                "evasion": 1.02,
                "damage": 1.06,
                "close_attempt": 0.98,
                "ai_melee_focus": 1.02,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.98,
            },
            "move_family_mult":
            {
                "high_cut": 0.95,
                "slash": 1.08,
                "parry": 1.04,
                "close": 0.96,
            },
            "move_id_mult":
            {
                "side_strike": 1.12,
                "upcut_mace": 1.15,
            },
            "signature":
            {
                "move_ids": {"side_strike": 1.08, "upcut_mace": 1.10},
                "contact_types": {"blunt": 1.04},
                "lines": {"high_left": 0.85, "left": 0.75},
                "feint_bias": 0.06,
            },
            "counters": {},
            "target_part_bias": {"left_arm": 1.10, "right_arm": 1.10},
            "move_family_part_bias":
            {
                "slash": {"left_arm": 1.08, "right_arm": 1.08},
            },
            "duel_offense_forms": PackedStringArray(),
        },
        "debout_devant":
        {
            "display_name": "Debout devant",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high_right", "high"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.28,
            "wait_weight_mult": 0.90,
            "mod":
            {
                "parry": 0.86,
                "evasion": 0.88,
                "damage": 1.18,
                "close_attempt": 1.04,
                "ai_melee_focus": 1.10,
                "feint_readthrough": 0.94,
                "ai_feint_listing": 1.00,
            },
            "move_family_mult":
            {
                "high_cut": 1.18,
                "slash": 1.05,
                "parry": 0.88,
                "close": 1.02,
            },
            "move_id_mult":
            {
                "overhead_strike": 1.25,
                "direct_blow": 1.15,
                "thrusting_blow": 1.10,
            },
            "signature":
            {
                "move_ids": {"overhead_strike": 1.20, "direct_blow": 1.08},
                "contact_types": {"blunt": 1.12},
                "lines": {"high": 0.9, "high_right": 0.85},
                "feint_bias": 0.08,
            },
            "counters":
            {
                "crown_guard": {"mult": 1.06, "families": ["high_cut"]},
            },
            "target_part_bias": {"head": 1.18, "chest": 1.06},
            "move_family_part_bias":
            {
                "high_cut": {"head": 1.15},
            },
            "duel_offense_forms": PackedStringArray(["crown_guard", "debout_devant"]),
        },
        "basse_garde":
        {
            "display_name": "Basse garde",
            "home_guard": "low",
            "preferred_guards": PackedStringArray(["low", "high"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.25,
            "mod":
            {
                "parry": 1.12,
                "evasion": 1.06,
                "damage": 0.90,
                "close_attempt": 0.86,
                "ai_melee_focus": 0.90,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 0.92,
            },
            "move_family_mult":
            {
                "high_cut": 0.85,
                "slash": 0.82,
                "parry": 1.10,
                "close": 0.84,
            },
            "move_id_mult":
            {
                "low_strike": 1.15,
                "parry_strike": 1.12,
            },
            "signature":
            {
                "move_ids": {"low_strike": 1.10, "parry_strike": 1.05},
                "contact_types": {"blunt": 0.96},
                "lines": {"low": 0.8, "high": 0.55},
                "feint_bias": 0.04,
            },
            "counters": {},
            "target_part_bias": {"left_leg": 1.12, "right_leg": 1.12, "chest": 1.05},
            "move_family_part_bias":
            {
                "slash": {"left_leg": 1.10, "right_leg": 1.10},
            },
            "duel_offense_forms": PackedStringArray(),
        },
    }


static func _dagger_forms() -> Dictionary:
    return {
        "balanced": _balanced_entry("Balanced"),
        "wall":
        {
            "display_name": "High block",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_right"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.18,
            "wait_weight_mult": 1.25,
            "mod":
            {
                "parry": 1.22,
                "evasion": 1.12,
                "damage": 0.90,
                "close_attempt": 0.88,
                "ai_melee_focus": 0.92,
                "feint_readthrough": 1.06,
                "ai_feint_listing": 0.94,
            },
            "move_family_mult":
            {
                "thrust": 0.92,
                "slash": 0.85,
                "feint": 0.88,
                "parry": 1.18,
                "close": 0.90,
            },
            "move_id_mult": {"parry_thrust_dagger": 1.2},
            "signature":
            {
                "move_ids": {"parry_thrust_dagger": 1.1},
                "contact_types": {"stab": 0.95},
                "lines": {"high": 1.0},
                "feint_bias": 0.25,
            },
            "counters": {"high_hut": {"mult": 1.08, "families": ["parry"]}},
            "target_part_bias": {"chest": 1.10},
            "move_family_part_bias": {},
            "duel_offense_forms": PackedStringArray(),
        },
        "high_hut":
        {
            "display_name": "High hut",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high", "high_right"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 0.98,
            "mod":
            {
                "parry": 1.05,
                "evasion": 1.04,
                "damage": 1.02,
                "close_attempt": 1.0,
                "ai_melee_focus": 1.04,
                "feint_readthrough": 1.03,
                "ai_feint_listing": 1.02,
            },
            "move_family_mult":
            {
                "thrust": 1.22,
                "slash": 0.82,
                "feint": 1.08,
                "parry": 1.0,
                "close": 1.0,
            },
            "move_id_mult":
            {
                "quick_thrust": 1.28,
                "committed_thrust": 1.15,
                "quick_slash": 0.78,
            },
            "signature":
            {
                "move_ids": {"quick_thrust": 1.3, "committed_thrust": 1.1},
                "contact_types": {"stab": 1.2},
                "lines": {"high": 0.9, "high_right": 0.85},
                "feint_bias": 0.35,
            },
            "counters": {"reverse_seize": {"mult": 1.1, "families": ["thrust"]}},
            "target_part_bias": {"chest": 1.20, "head": 1.08},
            "move_family_part_bias": {"thrust": {"chest": 1.18, "head": 1.06}},
            "duel_offense_forms": PackedStringArray(["high_hut", "reverse_seize"]),
        },
        "low_bind":
        {
            "display_name": "Low bind",
            "home_guard": "low_left",
            "preferred_guards": PackedStringArray(["low", "low_left"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.08,
                "evasion": 1.0,
                "damage": 0.98,
                "close_attempt": 1.05,
                "ai_melee_focus": 0.98,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 1.0,
            },
            "move_family_mult":
            {
                "thrust": 1.0,
                "slash": 1.15,
                "feint": 1.05,
                "parry": 1.05,
                "close": 1.08,
            },
            "move_id_mult": {"quick_slash": 1.22, "quick_thrust": 0.95},
            "signature":
            {
                "move_ids": {"quick_slash": 1.2},
                "contact_types": {"cut": 1.1},
                "lines": {"low": 0.8, "low_left": 0.85},
                "feint_bias": 0.2,
            },
            "counters": {"high_hut": {"mult": 1.06, "families": ["slash"]}},
            "target_part_bias": {"left_arm": 1.12, "right_arm": 1.12},
            "move_family_part_bias": {"slash": {"left_arm": 1.10, "right_arm": 1.10}},
            "duel_offense_forms": PackedStringArray(),
        },
        "reverse_seize":
        {
            "display_name": "Reverse seize",
            "home_guard": "low",
            "preferred_guards": PackedStringArray(["low", "high"]),
            "pressure_class": "controlling",
            "min_stamina_ratio": 0.24,
            "wait_weight_mult": 0.94,
            "mod":
            {
                "parry": 1.0,
                "evasion": 1.02,
                "damage": 0.94,
                "close_attempt": 1.15,
                "ai_melee_focus": 0.96,
                "feint_readthrough": 1.08,
                "ai_feint_listing": 1.08,
            },
            "move_family_mult":
            {
                "thrust": 0.95,
                "slash": 0.92,
                "feint": 1.18,
                "parry": 1.02,
                "close": 1.12,
            },
            "move_id_mult": {"quick_thrust": 1.05, "dagger_pommel": 1.15},
            "signature":
            {
                "move_ids": {"quick_thrust": 0.95, "dagger_pommel": 1.0},
                "contact_types": {"stab": 0.9},
                "lines": {"low": 0.75},
                "feint_bias": 0.5,
            },
            "counters": {"high_hut": {"mult": 1.12, "families": ["feint", "close"]}},
            "target_part_bias": {"head": 1.10, "chest": 1.12},
            "move_family_part_bias": {"feint": {"chest": 1.1}},
            "duel_offense_forms": PackedStringArray(["high_hut", "reverse_seize"]),
        },
        "rovera":
        {
            "display_name": "Rovera (inverted)",
            "home_guard": "low_right",
            "preferred_guards": PackedStringArray(["low_right", "low"]),
            "pressure_class": "controlling",
            "min_stamina_ratio": 0.24,
            "wait_weight_mult": 0.96,
            "mod":
            {
                "parry": 1.02,
                "evasion": 1.04,
                "damage": 0.96,
                "close_attempt": 1.12,
                "ai_melee_focus": 0.98,
                "feint_readthrough": 1.06,
                "ai_feint_listing": 1.10,
            },
            "move_family_mult":
            {
                "thrust": 1.05,
                "slash": 0.90,
                "feint": 1.12,
                "parry": 1.0,
                "close": 1.15,
            },
            "move_id_mult":
            {
                "reverse_thrust": 1.30,
                "grab_strike": 1.18,
                "low_thrust_dagger": 1.15,
            },
            "signature":
            {
                "move_ids": {"reverse_thrust": 1.25, "grab_strike": 1.10},
                "contact_types": {"stab": 0.95, "blunt": 1.05},
                "lines": {"low": 0.85, "high": 0.55},
                "feint_bias": 0.45,
            },
            "counters":
            {
                "high_hut": {"mult": 1.10, "families": ["close", "thrust"]},
            },
            "target_part_bias": {"left_leg": 1.18, "right_leg": 1.18, "head": 1.05},
            "move_family_part_bias":
            {
                "thrust": {"left_leg": 1.15, "right_leg": 1.15},
            },
            "duel_offense_forms": PackedStringArray(["rovera", "reverse_seize"]),
        },
        "dente_di_porc":
        {
            "display_name": "Dente di porco (boar's tusk)",
            "home_guard": "high_left",
            "preferred_guards": PackedStringArray(["high_left", "left"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.06,
                "evasion": 1.04,
                "damage": 1.02,
                "close_attempt": 0.98,
                "ai_melee_focus": 1.02,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 1.04,
            },
            "move_family_mult":
            {
                "thrust": 1.10,
                "slash": 0.88,
                "feint": 1.06,
                "parry": 1.05,
                "close": 1.02,
            },
            "move_id_mult":
            {
                "committed_thrust": 1.18,
                "feint_thrust_dagger": 1.15,
            },
            "signature":
            {
                "move_ids": {"committed_thrust": 1.12, "feint_thrust_dagger": 1.08},
                "contact_types": {"stab": 1.10},
                "lines": {"high_left": 0.85, "left": 0.70},
                "feint_bias": 0.40,
            },
            "counters":
            {
                "low_bind": {"mult": 1.06, "families": ["thrust"]},
            },
            "target_part_bias": {"chest": 1.15, "head": 1.08},
            "move_family_part_bias":
            {
                "thrust": {"chest": 1.12, "head": 1.06},
            },
            "duel_offense_forms": PackedStringArray(),
        },
    }


static func _spear_forms() -> Dictionary:
    return {
        "balanced": _balanced_entry("Balanced"),
        "wall":
        {
            "display_name": "Short grip",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_left"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.28,
            "mod":
            {
                "parry": 1.16,
                "evasion": 1.06,
                "damage": 0.90,
                "close_attempt": 0.88,
                "ai_melee_focus": 0.90,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 0.92,
            },
            "move_family_mult":
            {
                "thrust": 0.90,
                "slash": 0.85,
                "parry": 1.15,
                "close": 0.85,
            },
            "move_id_mult": {"parry_thrust_spear": 1.18, "spear_thrust": 0.85},
            "signature":
            {
                "move_ids": {"parry_thrust_spear": 1.1},
                "contact_types": {"stab": 0.95},
                "lines": {"high": 1.0},
                "feint_bias": 0.1,
            },
            "counters": {"iron_gate": {"mult": 1.08, "families": ["parry"]}},
            "target_part_bias": {"chest": 1.10},
            "move_family_part_bias": {},
            "duel_offense_forms": PackedStringArray(),
        },
        "iron_gate":
        {
            "display_name": "Iron gate",
            "home_guard": "low",
            "preferred_guards": PackedStringArray(["low", "high"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.10,
                "evasion": 1.04,
                "damage": 1.02,
                "close_attempt": 0.96,
                "ai_melee_focus": 1.0,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.96,
            },
            "move_family_mult":
            {
                "thrust": 1.28,
                "slash": 0.78,
                "parry": 1.08,
                "close": 0.92,
            },
            "move_id_mult":
            {
                "spear_thrust": 1.32,
                "off_line_thrust": 0.88,
                "spear_slash": 0.72,
            },
            "signature":
            {
                "move_ids": {"spear_thrust": 1.35},
                "contact_types": {"stab": 1.28},
                "lines": {"high": 0.75, "low": 0.85},
                "feint_bias": 0.06,
            },
            "counters": {"high_port": {"mult": 1.08, "families": ["thrust"]}},
            "target_part_bias": {"chest": 1.22, "head": 1.0},
            "move_family_part_bias": {"thrust": {"chest": 1.18}},
            "duel_offense_forms": PackedStringArray(["iron_gate", "true_cross"]),
        },
        "true_cross":
        {
            "display_name": "True cross",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high_right", "high_left"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.06,
                "evasion": 1.02,
                "damage": 1.04,
                "close_attempt": 0.98,
                "ai_melee_focus": 1.02,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.98,
            },
            "move_family_mult":
            {
                "thrust": 1.15,
                "slash": 0.88,
                "parry": 1.05,
                "close": 0.95,
            },
            "move_id_mult":
            {
                "off_line_thrust": 1.30,
                "spear_thrust": 1.08,
                "parry_thrust_spear": 1.05,
            },
            "signature":
            {
                "move_ids": {"off_line_thrust": 1.25, "spear_thrust": 1.0},
                "contact_types": {"stab": 1.15},
                "lines": {"high_right": 0.85, "high_left": 0.8},
                "feint_bias": 0.08,
            },
            "counters": {"iron_gate": {"mult": 1.1, "families": ["thrust"]}},
            "target_part_bias": {"chest": 1.15},
            "move_family_part_bias": {"thrust": {"chest": 1.12}},
            "duel_offense_forms": PackedStringArray(["iron_gate", "true_cross"]),
        },
        "high_port":
        {
            "display_name": "High port",
            "home_guard": "high_left",
            "preferred_guards": PackedStringArray(["high_left", "left"]),
            "pressure_class": "aggressive",
            "min_stamina_ratio": 0.26,
            "wait_weight_mult": 0.90,
            "mod":
            {
                "parry": 0.88,
                "evasion": 0.90,
                "damage": 1.12,
                "close_attempt": 1.02,
                "ai_melee_focus": 1.08,
                "feint_readthrough": 0.96,
                "ai_feint_listing": 1.0,
            },
            "move_family_mult":
            {
                "thrust": 0.88,
                "slash": 1.18,
                "parry": 0.92,
                "close": 1.0,
            },
            "move_id_mult":
            {
                "spear_slash": 1.22,
                "pole_swing": 1.18,
                "spear_thrust": 0.82,
            },
            "signature":
            {
                "move_ids": {"spear_slash": 1.15, "pole_swing": 1.1},
                "contact_types": {"cut": 1.05, "blunt": 1.0},
                "lines": {"left": 0.85, "high_left": 0.8},
                "feint_bias": 0.12,
            },
            "counters": {"iron_gate": {"mult": 1.06, "families": ["slash"]}},
            "target_part_bias": {"left_arm": 1.12, "right_arm": 1.12, "head": 1.08},
            "move_family_part_bias":
            {
                "slash": {"left_arm": 1.10, "right_arm": 1.10, "head": 1.06},
            },
            "duel_offense_forms": PackedStringArray(),
        },
        "guarda_di_corpo":
        {
            "display_name": "Guarda di corpo",
            "home_guard": "high_right",
            "preferred_guards": PackedStringArray(["high_right", "high"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.06,
                "evasion": 1.04,
                "damage": 1.04,
                "close_attempt": 0.98,
                "ai_melee_focus": 1.02,
                "feint_readthrough": 1.02,
                "ai_feint_listing": 0.98,
            },
            "move_family_mult":
            {
                "thrust": 1.18,
                "slash": 0.85,
                "parry": 1.06,
                "close": 0.94,
            },
            "move_id_mult":
            {
                "spear_thrust": 1.25,
                "inside_stab": 1.15,
                "false_cut": 1.10,
            },
            "signature":
            {
                "move_ids": {"spear_thrust": 1.28, "inside_stab": 1.10},
                "contact_types": {"stab": 1.20},
                "lines": {"high_right": 0.85, "high": 0.70},
                "feint_bias": 0.08,
            },
            "counters":
            {
                "iron_gate": {"mult": 1.08, "families": ["thrust"]},
            },
            "target_part_bias": {"chest": 1.16, "head": 1.04},
            "move_family_part_bias":
            {
                "thrust": {"chest": 1.14},
            },
            "duel_offense_forms": PackedStringArray(["iron_gate", "guarda_di_corpo"]),
        },
        "guarda_di_corpo_basso":
        {
            "display_name": "Guarda di corpo basso",
            "home_guard": "low_left",
            "preferred_guards": PackedStringArray(["low_left", "low"]),
            "pressure_class": "neutral",
            "min_stamina_ratio": 0.22,
            "wait_weight_mult": 1.0,
            "mod":
            {
                "parry": 1.08,
                "evasion": 1.04,
                "damage": 1.00,
                "close_attempt": 0.96,
                "ai_melee_focus": 0.98,
                "feint_readthrough": 1.04,
                "ai_feint_listing": 1.02,
            },
            "move_family_mult":
            {
                "thrust": 1.12,
                "slash": 0.88,
                "parry": 1.08,
                "close": 0.96,
            },
            "move_id_mult":
            {
                "low_thrust_spear": 1.30,
                "off_line_thrust": 1.10,
            },
            "signature":
            {
                "move_ids": {"low_thrust_spear": 1.25, "off_line_thrust": 1.05},
                "contact_types": {"stab": 1.12},
                "lines": {"low": 0.85, "low_left": 0.80},
                "feint_bias": 0.06,
            },
            "counters":
            {
                "high_port": {"mult": 1.06, "families": ["thrust"]},
            },
            "target_part_bias": {"left_leg": 1.15, "right_leg": 1.15, "chest": 1.04},
            "move_family_part_bias":
            {
                "thrust": {"left_leg": 1.12, "right_leg": 1.12},
            },
            "duel_offense_forms": PackedStringArray(),
        },
    }


static func _balanced_entry(display: String) -> Dictionary:
    return {
        "display_name": display,
        "home_guard": "high",
        "preferred_guards": PackedStringArray(["high"]),
        "pressure_class": "neutral",
        "min_stamina_ratio": 0.22,
        "wait_weight_mult": 1.0,
        "mod": _neutral_mod(),
        "move_family_mult": {},
        "move_id_mult": {},
        "signature": {"move_ids": {}, "contact_types": {}, "lines": {"high": 0.35}, "feint_bias": 0.1},
        "counters": {},
        "target_part_bias": {},
        "move_family_part_bias": {},
        "duel_offense_forms": PackedStringArray(),
    }
