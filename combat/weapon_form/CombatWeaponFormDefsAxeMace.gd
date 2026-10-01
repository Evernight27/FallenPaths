class_name CombatWeaponFormDefsAxeMace
extends RefCounted

## AXE and MACE form/posture tables.


static func _axe_forms() -> Dictionary:
    # Le Jeu de la Hache: demi-hache ready, bec/spike point, queue bind.
    return {
        "balanced": _axe_balanced_entry(),
        "wall":
        {
            "display_name": "High Ward",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_left"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.3,
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("defensive"),
            "cooldown_modifiers": {"windup": 1.12, "recovery": 1.06},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("aggressive"),
            "cooldown_modifiers": {"windup": 0.90, "recovery": 1.20},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("neutral"),
            "cooldown_modifiers": {"windup": 0.94, "recovery": 1.00},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("controlling"),
            "cooldown_modifiers": {"windup": 1.04, "recovery": 1.08},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("aggressive"),
            "cooldown_modifiers": {"windup": 0.92, "recovery": 1.16},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("neutral"),
            "cooldown_modifiers": {"windup": 0.98, "recovery": 0.98},
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
        "balanced": _mace_balanced_entry(),
        "wall":
        {
            "display_name": "Braced ward",
            "home_guard": "high",
            "preferred_guards": PackedStringArray(["high", "high_left", "high_right"]),
            "pressure_class": "defensive",
            "min_stamina_ratio": 0.20,
            "wait_weight_mult": 1.32,
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("defensive"),
            "cooldown_modifiers": {"windup": 1.10, "recovery": 1.05},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("aggressive"),
            "cooldown_modifiers": {"windup": 0.92, "recovery": 1.18},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("aggressive"),
            "cooldown_modifiers": {"windup": 0.94, "recovery": 1.14},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("neutral"),
            "cooldown_modifiers": {"windup": 0.98, "recovery": 0.98},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("aggressive"),
            "cooldown_modifiers": {"windup": 0.94, "recovery": 1.15},
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
            "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("defensive"),
            "cooldown_modifiers": {"windup": 1.10, "recovery": 1.06},
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


static func _axe_balanced_entry() -> Dictionary:
    return {
        "display_name": "Balanced",
        "home_guard": "high",
        "preferred_guards": PackedStringArray(["high"]),
        "pressure_class": "neutral",
        "min_stamina_ratio": 0.22,
        "wait_weight_mult": 1.0,
        "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("neutral"),
        "cooldown_modifiers": {"windup": 1.0, "recovery": 1.0},
        "mod": CombatWeaponFormDefsShared._neutral_mod(),
        "move_family_mult": {},
        "move_id_mult": {},
        "signature": {"move_ids": {}, "contact_types": {}, "lines": {"high": 0.35}, "feint_bias": 0.1},
        "counters": {},
        "target_part_bias": {},
        "move_family_part_bias": {},
        "duel_offense_forms": PackedStringArray(),
    }


static func _mace_balanced_entry() -> Dictionary:
    return {
        "display_name": "Balanced",
        "home_guard": "high",
        "preferred_guards": PackedStringArray(["high"]),
        "pressure_class": "neutral",
        "min_stamina_ratio": 0.22,
        "wait_weight_mult": 1.0,
        "stamina_cost_mult": CombatWeaponFormDefsShared._stamina_cost_for_pressure("neutral"),
        "cooldown_modifiers": {"windup": 1.0, "recovery": 1.0},
        "mod": CombatWeaponFormDefsShared._neutral_mod(),
        "move_family_mult": {},
        "move_id_mult": {},
        "signature": {"move_ids": {}, "contact_types": {}, "lines": {"high": 0.35}, "feint_bias": 0.1},
        "counters": {},
        "target_part_bias": {},
        "move_family_part_bias": {},
        "duel_offense_forms": PackedStringArray(),
    }
