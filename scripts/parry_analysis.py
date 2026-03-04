#!/usr/bin/env python3
"""
Parry rate analysis: computes can_parry_in_time, choose_parry, and deflect vs partial rates.
Uses formulas from AttackResolver.gd, EntityPainConsciousness.gd, CombatManager.gd.
"""

# Constants from codebase
WIND_UP_BASE_S = 0.25
WIND_UP_SCALE_S = 0.6
COMMITMENT_FRACTION = 0.2
PASSIVE_PARRY_BASE_REACTION_S = 0.24
PARRY_BLADE_MOVEMENT_S = 0.13
PASSIVE_PARRY_MIN_TIME_FOR_FULL_S = 0.25
PARRY_STRENGTH_NORM = 100.0
PARRY_DODGE_STRENGTH_RATIO = 2.2
PARRY_DEFLECT_THRESHOLD = 1.08
VELOCITY_MAX_M_S = 24.0
VELOCITY_MIN_M_S = 6.0
PARRY_V_FRACTION = 0.5
PARRY_MOVEMENT_MASS_STRENGTH_MIN = 0.5
PARRY_MOVEMENT_MASS_STRENGTH_MAX = 2.0

WEAPONS = {
    "SWORD": {"mass": 1.2, "parry_speed_factor": 1.0},
    "AXE": {"mass": 1.5, "parry_speed_factor": 0.95},
    "MACE": {"mass": 1.7, "parry_speed_factor": 0.9},
    "DAGGER": {"mass": 0.3, "parry_speed_factor": 1.2},
    "SPEAR": {"mass": 1.8, "parry_speed_factor": 1.0},
}

ARCHETYPES = {
    "stab": {"velocity_factor": 1.0, "windup_mult": 1.0},
    "slash": {"velocity_factor": 0.9, "windup_mult": 1.0},
    "overhead": {"velocity_factor": 1.0, "windup_mult": 1.15},
    "quick_slash": {"velocity_factor": 0.65, "windup_mult": 0.8},
    "heavy_blunt": {"velocity_factor": 1.0, "windup_mult": 1.1},
}


def wind_up_duration(intensity: float, windup_mult: float = 1.0, leg: float = 1.0, perf_mod: float = 1.0, agility: int = 100) -> float:
    base = (WIND_UP_BASE_S + WIND_UP_SCALE_S * intensity) * max(0.5, windup_mult)
    agi_factor = max(0.7, min(1.3, agility / 100.0))
    return base / leg / max(0.35, perf_mod) / agi_factor


def velocity_from_intensity(intensity: float, velocity_factor: float = 1.0) -> float:
    factor = 0.5 + 0.5 * max(0, min(1, intensity))
    if velocity_factor:
        factor *= max(0.1, min(1.5, velocity_factor))
    return VELOCITY_MIN_M_S + (VELOCITY_MAX_M_S - VELOCITY_MIN_M_S) * max(0, min(1, factor))


def reaction_time(perception: int, consciousness: float = 100, head_pain_mod: float = 1.0) -> float:
    perc_norm = max(0.2, min(1.5, perception / 100.0))
    cons_norm = max(0.1, min(1.0, consciousness / 100.0))
    factor = max(0.15, min(1.0, perc_norm * cons_norm * head_pain_mod))
    return PASSIVE_PARRY_BASE_REACTION_S / factor


def parry_speed(def_weapon: dict) -> float:
    base = VELOCITY_MAX_M_S * PARRY_V_FRACTION
    factor = def_weapon.get("parry_speed_factor", 1.0)
    return base * max(0.5, min(1.5, factor))


def compute_parry_scenario(
    atk_weapon: str,
    def_weapon: str,
    archetype: str,
    intensity: float,
    atk_str: int,
    atk_agi: int,
    def_str: int,
    def_agi: int,
    def_perc: int,
    def_perf: float = 1.0,
    def_arm_mod: float = 1.0,
    def_readiness: float = 1.0,
    def_consciousness: float = 100.0,
    def_head_pain_mod: float = 1.0,
) -> dict:
    aw = WEAPONS.get(atk_weapon, WEAPONS["SWORD"])
    dw = WEAPONS.get(def_weapon, WEAPONS["SWORD"])
    arch = ARCHETYPES.get(archetype, ARCHETYPES["slash"])

    wind_up = wind_up_duration(intensity, arch["windup_mult"], 1.0, 1.0, atk_agi)
    effective_wind_up = wind_up * (1.0 - COMMITMENT_FRACTION)
    rt = reaction_time(def_perc, def_consciousness, def_head_pain_mod)

    can_parry_in_time = rt < effective_wind_up
    parry_time_to_react = max(0, effective_wind_up - rt) if can_parry_in_time else 0

    v_intent = velocity_from_intensity(intensity, arch["velocity_factor"])
    parry_progress = 1.0 - max(0, min(1, parry_time_to_react / max(0.001, effective_wind_up))) if can_parry_in_time else 1.0
    vel_curve = parry_progress * parry_progress
    p_a = aw["mass"] * v_intent * vel_curve

    blade_movement = PARRY_BLADE_MOVEMENT_S * max(
        PARRY_MOVEMENT_MASS_STRENGTH_MIN,
        min(PARRY_MOVEMENT_MASS_STRENGTH_MAX, dw["mass"] * PARRY_STRENGTH_NORM / max(1, def_str)),
    )
    effective_parry_time = max(0, parry_time_to_react - blade_movement)
    capacity_mult = min(1.0, effective_parry_time / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S)

    v_parry = parry_speed(dw)
    c_d_full = dw["mass"] * v_parry * (def_str / PARRY_STRENGTH_NORM)
    c_d_full *= max(0.7, min(1.3, def_agi / 100.0))
    c_d_full *= max(0.35, def_perf)
    c_d_full *= max(0.1, def_arm_mod)
    parry_c_d = c_d_full * capacity_mult * def_readiness

    choose_parry = can_parry_in_time and (p_a <= parry_c_d * PARRY_DODGE_STRENGTH_RATIO)

    deflected_mean = parry_c_d >= p_a * PARRY_DEFLECT_THRESHOLD
    deflect_prob = max(0, min(1, (parry_c_d * 1.1 - p_a) / (p_a * 0.2 + 0.001))) if choose_parry else 0
    deflect_prob = (deflect_prob + 1) / 2  # simplify: variance shifts outcome

    return {
        "wind_up": wind_up,
        "effective_wind_up": effective_wind_up,
        "reaction_time": rt,
        "can_parry_in_time": can_parry_in_time,
        "choose_parry": choose_parry,
        "p_a": p_a,
        "c_d": parry_c_d,
        "parry_time_to_react": parry_time_to_react,
        "capacity_mult": capacity_mult,
        "deflect_prob_approx": deflect_prob if choose_parry else 0,
    }


def main():
    print("=== Parry Analysis: Key Matchups ===\n")

    scenarios = [
        ("Human vs Human, sword/slash, int 0.6", "SWORD", "SWORD", "slash", 0.6, 100, 100, 100, 100, 100),
        ("Human vs Human, sword/overhead, int 0.8", "SWORD", "SWORD", "overhead", 0.8, 100, 100, 100, 100, 100),
        ("Human attacking Goblin, sword (Goblin defends)", "SWORD", "SWORD", "slash", 0.6, 100, 100, 60, 115, 90),
        ("Goblin attacking Human, sword (Human defends)", "SWORD", "SWORD", "slash", 0.6, 60, 115, 100, 100, 100),
        ("Human vs Human, dagger quick_slash", "DAGGER", "DAGGER", "quick_slash", 0.7, 100, 100, 100, 100, 100),
        ("Human vs Human, mace", "MACE", "SWORD", "heavy_blunt", 0.7, 100, 100, 100, 100, 100),
    ]

    for name, atk_w, def_w, arch, inten, atk_s, atk_a, def_s, def_a, def_p in scenarios:
        r = compute_parry_scenario(atk_w, def_w, arch, inten, atk_s, atk_a, def_s, def_a, def_p)
        print(f"--- {name} ---")
        print(f"  effective_wind_up: {r['effective_wind_up']:.3f}s  reaction: {r['reaction_time']:.3f}s")
        print(f"  can_parry_in_time: {r['can_parry_in_time']}  choose_parry: {r['choose_parry']}")
        print(f"  p_a: {r['p_a']:.1f}  c_d: {r['c_d']:.1f}  (need p_a <= c_d*{PARRY_DODGE_STRENGTH_RATIO} = {r['c_d']*PARRY_DODGE_STRENGTH_RATIO:.1f})")
        print(f"  capacity_mult: {r['capacity_mult']:.2f}")
        if r["choose_parry"]:
            print(f"  deflect_prob (approx): ~{r['deflect_prob_approx']*100:.0f}%")
        else:
            print(f"  -> DODGE chosen (attack effectively unparriable)")
        print()

    print("=== Wounded Defender (perf=0.85, arm=0.75, reaction +15%) ===\n")
    r = compute_parry_scenario(
        "SWORD", "SWORD", "slash", 0.6,
        100, 100, 100, 100, 100,
        def_perf=0.85, def_arm_mod=0.75, def_head_pain_mod=0.88,
    )
    print("Human vs Human, wounded def:")
    print(f"  can_parry: {r['can_parry_in_time']}  choose_parry: {r['choose_parry']}  p_a: {r['p_a']:.1f}  c_d: {r['c_d']:.1f}")
    print()

    r2 = compute_parry_scenario(
        "DAGGER", "SWORD", "quick_slash", 0.65,
        100, 115, 100, 100, 100,
        def_perf=0.85, def_head_pain_mod=0.88,
    )
    print("Human ( wounded) vs Goblin dagger quick_slash:")
    print(f"  effective_wind_up: {r2['effective_wind_up']:.3f}s  reaction: {r2['reaction_time']:.3f}s")
    print(f"  can_parry: {r2['can_parry_in_time']}  choose_parry: {r2['choose_parry']}")


if __name__ == "__main__":
    main()
