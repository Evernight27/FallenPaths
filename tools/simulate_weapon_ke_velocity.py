#!/usr/bin/env python3
"""
Mirror WeaponDamageHelper + ImpactVelocityModel for min/mid/max intensity (0, 0.5, 1.0).
Weapon defs copied from WeaponConstants._weapon_definitions_build (subset).
"""
from __future__ import annotations

import math

ABS_V_MIN, ABS_V_MAX = 2.0, 30.0
REFERENCE_STRIKE_RADIUS_M = 0.52
MIN_LEVER_M = 0.12
INTENSITY_V_FLOOR = 0.2
MIN_INERTIA = 0.001
INERTIA_KE_STRIKE_CAP_MULT = 1.0

DEFAULT_BANDS = {
    "SWORD": {"stab": (4.5, 17.0), "cut": (6.0, 22.0), "blunt": (5.0, 18.0)},
    "AXE": {"stab": (4.0, 15.0), "cut": (5.5, 20.0), "blunt": (5.5, 19.0)},
    "MACE": {"stab": (6.0, 18.0), "cut": (7.0, 20.0), "blunt": (7.0, 20.5)},
    "DAGGER": {"stab": (4.0, 18.0), "cut": (5.5, 20.0), "blunt": (4.0, 14.0)},
    "SPEAR": {"stab": (5.0, 20.0), "cut": (5.5, 17.5), "blunt": (5.5, 17.5)},
}

KINEMATIC_THRUST = "thrust"
KINEMATIC_SWING = "swing"
KINEMATIC_MIXED = "mixed"

ARCHETYPES = {
    "stab": {
        "velocity_factor": 1.0,
        "velocity_intensity_curve": 0.95,
        "kinematic_delivery": KINEMATIC_THRUST,
    },
    "slash": {
        "velocity_factor": 0.9,
        "velocity_intensity_curve": 1.04,
        "kinematic_delivery": KINEMATIC_SWING,
    },
    "overhead": {
        "velocity_factor": 1.0,
        "velocity_intensity_curve": 1.1,
        "kinematic_delivery": KINEMATIC_SWING,
    },
    "quick_slash": {
        "velocity_factor": 0.65,
        "velocity_intensity_curve": 0.8,
        "kinematic_delivery": KINEMATIC_SWING,
    },
    "pommel_strike": {
        "velocity_factor": 0.7,
        "velocity_intensity_curve": 0.88,
        "kinematic_delivery": KINEMATIC_SWING,
    },
    "heavy_blunt": {
        "velocity_factor": 1.0,
        "velocity_intensity_curve": 1.12,
        "kinematic_delivery": KINEMATIC_SWING,
    },
}

WEAPONS: dict = {
    "SWORD": {
        "mass": 1.2,
        "melee_range": 1.5,
        "parts": [
            {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": True},
            {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": False},
        ],
        "parry_part_id": "blade",
    },
    "AXE": {
        "mass": 1.5,
        "melee_range": 1.5,
        "parts": [
            {"id": "blade", "length_cm": 25, "mass_fraction": 0.4, "parry_eligible": True, "striking_for": ["cut"]},
            {"id": "spike", "length_cm": 8, "mass_fraction": 0.15, "parry_eligible": False, "striking_for": ["stab"]},
            {"id": "haft", "length_cm": 90, "mass_fraction": 0.45, "parry_eligible": True, "striking_for": ["blunt"]},
        ],
        "parry_part_id": "haft",
    },
    "MACE": {
        "mass": 1.7,
        "melee_range": 1.5,
        "parts": [
            {"id": "head", "length_cm": 15, "mass_fraction": 0.7, "parry_eligible": False, "striking_for": ["blunt"]},
            {"id": "shaft", "length_cm": 55, "mass_fraction": 0.3, "parry_eligible": True},
        ],
        "parry_part_id": "shaft",
    },
    "DAGGER": {
        "mass": 0.3,
        "melee_range": 0.8,
        "parts": [
            {"id": "blade", "length_cm": 20, "mass_fraction": 0.55, "parry_eligible": True},
            {"id": "handle", "length_cm": 12, "mass_fraction": 0.45, "parry_eligible": False},
        ],
        "parry_part_id": "blade",
    },
    "SPEAR": {
        "mass": 1.8,
        "melee_range": 2.5,
        "impact_velocity_bands": {"stab": {"min": 5.5, "max": 21.0}},
        "parts": [
            {"id": "head", "length_cm": 25, "mass_fraction": 0.15, "parry_eligible": False, "striking_for": ["stab", "cut"]},
            {"id": "shaft", "length_cm": 200, "mass_fraction": 0.70, "parry_eligible": True, "striking_for": ["blunt"]},
        ],
        "parry_part_id": "shaft",
    },
}


def clampf(x: float, a: float, b: float) -> float:
    return max(a, min(b, x))


def total_length_m_parts(parts: list) -> float:
    s = 0.0
    for p in parts:
        s += max(0.0, float(p.get("length_cm", 0.0))) / 100.0
    return max(s, 0.05)


def com_distance_from_grip_m(parts: list, part_index: int) -> float:
    if part_index < 0 or part_index >= len(parts):
        return MIN_LEVER_M
    L_total = total_length_m_parts(parts)
    cum_from_tip = 0.0
    for i, p in enumerate(parts):
        L_i = max(0.0, float(p.get("length_cm", 0.0))) / 100.0
        if i == part_index:
            com_from_tip = cum_from_tip + L_i * 0.5
            return max(MIN_LEVER_M, L_total - com_from_tip)
        cum_from_tip += L_i
    return MIN_LEVER_M


def striking_part_index(w: dict, contact_type: str) -> int:
    parts = w.get("parts") or []
    ct = contact_type.lower()
    for i, p in enumerate(parts):
        sf = p.get("striking_for", [])
        if isinstance(sf, list) and ct in sf:
            return i
    if ct == "stab":
        for i, p in enumerate(parts):
            if str(p.get("id", "")) in ("point", "blade", "spike", "head"):
                return i
    if ct == "cut":
        for i, p in enumerate(parts):
            if str(p.get("id", "")) == "blade":
                return i
    if ct == "blunt":
        for i, p in enumerate(parts):
            if str(p.get("id", "")) in ("head", "haft"):
                return i
    return 0 if parts else -1


def inertia_about_grip_kg_m2(w: dict) -> float:
    M = float(w["mass"])
    parts = w.get("parts") or []
    if not parts:
        L = clampf(float(w.get("melee_range", 1.5)) * 0.75, 0.35, 1.4)
        return max(MIN_INERTIA, M * L * L / 3.0)
    I = 0.0
    for i, p in enumerate(parts):
        frac = clampf(float(p.get("mass_fraction", 1.0)), 0.0, 1.0)
        m_i = max(0.0, M * frac)
        d = com_distance_from_grip_m(parts, i)
        I += m_i * d * d
    return max(MIN_INERTIA, I)


def strike_lever_arm_m(w: dict, contact_type: str) -> float:
    r_geom = max(MIN_LEVER_M, strike_radius_m(w, contact_type))
    parts = w.get("parts") or []
    if not parts:
        return r_geom
    idx = striking_part_index(w, contact_type)
    if idx < 0:
        return r_geom
    r_com = max(MIN_LEVER_M, com_distance_from_grip_m(parts, idx))
    return max(r_com, r_geom)


def get_striking_part_mass_kg(w: dict, contact_type: str) -> float:
    mass = w["mass"]
    parts = w.get("parts") or []
    ct = contact_type.lower()
    for p in parts:
        sf = p.get("striking_for", [])
        if isinstance(sf, list) and ct in sf:
            frac = float(p.get("mass_fraction", 1.0))
            return mass * clampf(frac, 0.0, 1.0)
    if ct == "stab":
        for p in parts:
            pid = str(p.get("id", ""))
            if pid in ("point", "blade", "spike", "head"):
                frac = float(p.get("mass_fraction", 1.0))
                return mass * clampf(frac, 0.0, 1.0)
    if ct == "cut":
        for p in parts:
            if str(p.get("id", "")) == "blade":
                frac = float(p.get("mass_fraction", 1.0))
                return mass * clampf(frac, 0.0, 1.0)
    if ct == "blunt":
        for p in parts:
            pid = str(p.get("id", ""))
            if pid in ("head", "haft"):
                frac = float(p.get("mass_fraction", 1.0))
                return mass * clampf(frac, 0.0, 1.0)
    if parts:
        frac = float(parts[0].get("mass_fraction", 1.0))
        return mass * clampf(frac, 0.0, 1.0)
    return mass


def strike_radius_m(w: dict, contact_type: str) -> float:
    ct = contact_type.lower()
    parts = w.get("parts") or []
    melee_r = float(w.get("melee_range", 1.5))
    total_len_cm = 0.0
    for p in parts:
        sf = p.get("striking_for", [])
        if isinstance(sf, list) and ct in sf:
            total_len_cm += float(p.get("length_cm", 0.0))
    if total_len_cm > 0:
        if ct in ("cut", "blunt"):
            return clampf((total_len_cm / 100.0) * 0.58, 0.22, 1.05)
        if ct == "stab":
            return clampf((total_len_cm / 100.0) * 0.32 + melee_r * 0.09, 0.25, 0.88)
    return clampf(melee_r * 0.36, 0.28, 0.92)


def geometry_velocity_multiplier(w: dict, contact_type: str) -> float:
    r = strike_radius_m(w, contact_type)
    if r <= 0.001:
        return 1.0
    t = math.sqrt(clampf(r / REFERENCE_STRIKE_RADIUS_M, 0.62, 1.38))
    return clampf(t, 0.88, 1.15)


def tier_a_band(wtype: str, ct: str) -> tuple[float, float]:
    wt = wtype.upper()
    by_weapon = DEFAULT_BANDS.get(wt, DEFAULT_BANDS["SWORD"])
    return tuple(by_weapon.get(ct.lower(), by_weapon["cut"]))  # type: ignore


def kinematic_delivery(arch: dict, contact_type: str) -> str:
    raw = str(arch.get("kinematic_delivery", "")).strip().lower()
    if raw in (KINEMATIC_THRUST, KINEMATIC_SWING, KINEMATIC_MIXED):
        return raw
    if contact_type.lower() == "stab":
        return KINEMATIC_THRUST
    return KINEMATIC_SWING


def resolve_band_m_s(wname: str, contact_type: str) -> tuple[float, float]:
    w = WEAPONS[wname]
    ct = contact_type.lower()
    iv = w.get("impact_velocity_bands") or {}
    entry = iv.get(ct)
    if isinstance(entry, dict):
        mn, mx = float(entry["min"]), float(entry["max"])
        if mn >= 0 and mx > mn:
            vmin, vmax = mn, mx
        else:
            vmin, vmax = tier_a_band(wname, ct)
    else:
        vmin, vmax = tier_a_band(wname, ct)
    mult = geometry_velocity_multiplier(w, ct)
    vmin = clampf(vmin * (1.0 + (mult - 1.0) * 0.38), ABS_V_MIN, ABS_V_MAX)
    vmax = clampf(vmax * mult, vmin + 0.55, ABS_V_MAX)
    return vmin, vmax


def _velocity_intensity_g(intensity: float, arch: dict) -> float:
    int0 = clampf(intensity, 0.0, 1.0)
    curve = clampf(float(arch["velocity_intensity_curve"]), 0.55, 1.5)
    intensity_val = int0**curve
    factor = INTENSITY_V_FLOOR + (1.0 - INTENSITY_V_FLOOR) * intensity_val
    vf = clampf(float(arch["velocity_factor"]), 0.1, 1.5)
    factor *= vf
    return clampf(factor, 0.0, 1.0)


def _velocity_linear_from_g(wname: str, contact_type: str, g: float) -> float:
    vmin, vmax = resolve_band_m_s(wname, contact_type)
    return vmin + (vmax - vmin) * g


def _velocity_swing_from_g(wname: str, contact_type: str, g: float) -> float:
    vmin, vmax = resolve_band_m_s(wname, contact_type)
    w = WEAPONS[wname]
    parts = w.get("parts") or []
    if parts:
        r = strike_lever_arm_m(w, contact_type.lower())
        w_min = vmin / r
        w_max = vmax / r
        omega = w_min + (w_max - w_min) * g
        return clampf(omega * r, ABS_V_MIN, ABS_V_MAX)
    return _velocity_linear_from_g(wname, contact_type, g)


def velocity_m_s_from_intensity(intensity: float, archetype_key: str, wname: str, contact_type: str) -> float:
    arch = ARCHETYPES[archetype_key]
    g = _velocity_intensity_g(intensity, arch)
    delivery = kinematic_delivery(arch, contact_type)
    if delivery == KINEMATIC_THRUST:
        return _velocity_linear_from_g(wname, contact_type, g)
    if delivery == KINEMATIC_SWING:
        return _velocity_swing_from_g(wname, contact_type, g)
    if delivery == KINEMATIC_MIXED:
        b = 0.5
        bm = arch.get("kinematic_mixed_blend")
        if isinstance(bm, (int, float)):
            b = clampf(float(bm), 0.0, 1.0)
        return (1.0 - b) * _velocity_linear_from_g(wname, contact_type, g) + b * _velocity_swing_from_g(
            wname, contact_type, g
        )
    return _velocity_swing_from_g(wname, contact_type, g)


def ke_j_thrust(w: dict, contact_type: str, v: float, strike_energy_mult: float = 1.0) -> float:
    m_s = get_striking_part_mass_kg(w, contact_type)
    return 0.5 * m_s * v * v * max(0.05, strike_energy_mult)


def ke_j_swing_rotational(w: dict, contact_type: str, v: float, strike_energy_mult: float = 1.0) -> float:
    parts = w.get("parts") or []
    m_s = get_striking_part_mass_kg(w, contact_type)
    if not parts:
        return ke_j_thrust(w, contact_type, v, strike_energy_mult)
    I_full = inertia_about_grip_kg_m2(w)
    r = strike_lever_arm_m(w, contact_type)
    I_cap = max(MIN_INERTIA, m_s * r * r * INERTIA_KE_STRIKE_CAP_MULT)
    I_use = min(I_full, I_cap)
    omega = v / max(r, MIN_LEVER_M)
    return 0.5 * max(MIN_INERTIA, I_use) * omega * omega * max(0.05, strike_energy_mult)


def ke_j_from_delivery(w: dict, arch: dict, contact_type: str, v: float, strike_energy_mult: float = 1.0) -> float:
    d = kinematic_delivery(arch, contact_type)
    if d == KINEMATIC_THRUST:
        return ke_j_thrust(w, contact_type, v, strike_energy_mult)
    if d == KINEMATIC_SWING:
        return ke_j_swing_rotational(w, contact_type, v, strike_energy_mult)
    if d == KINEMATIC_MIXED:
        b = 0.5
        bm = arch.get("kinematic_mixed_blend")
        if isinstance(bm, (int, float)):
            b = clampf(float(bm), 0.0, 1.0)
        return (1.0 - b) * ke_j_thrust(w, contact_type, v, strike_energy_mult) + b * ke_j_swing_rotational(
            w, contact_type, v, strike_energy_mult
        )
    return ke_j_swing_rotational(w, contact_type, v, strike_energy_mult)


def ke_j(m_kg: float, v: float, strike_energy_mult: float = 1.0) -> float:
    return 0.5 * m_kg * v * v * max(0.05, strike_energy_mult)


def momentum_p_a(m_kg: float, v: float) -> float:
    """Same units as game parry_p_a when velocity_curve_factor=1."""
    return m_kg * v


# Rows: weapon, contact, archetype_key, label
SCENARIOS = [
    ("SWORD", "stab", "stab", "thrust"),
    ("SWORD", "cut", "overhead", "oberhau"),
    ("SWORD", "blunt", "pommel_strike", "pommel_strike"),
    ("AXE", "stab", "stab", "spike_thrust"),
    ("AXE", "cut", "overhead", "overhead_chop"),
    ("AXE", "blunt", "heavy_blunt", "poll_strike"),
    ("MACE", "blunt", "heavy_blunt", "overhead_strike"),
    ("DAGGER", "stab", "stab", "quick_thrust"),
    ("DAGGER", "cut", "quick_slash", "quick_slash"),
    ("SPEAR", "stab", "stab", "spear_thrust"),
    ("SPEAR", "cut", "slash", "spear_slash"),
    ("SPEAR", "blunt", "heavy_blunt", "pole_swing"),
]

INTENSITIES = [0.0, 0.5, 1.0]


def velocity_factor_range(archetype_key: str) -> tuple[float, float]:
    """Reachable g from intensity 0..1: (at i=0, at i=1)."""
    arch = ARCHETYPES[archetype_key]
    vf = clampf(float(arch["velocity_factor"]), 0.1, 1.5)
    curve = clampf(float(arch["velocity_intensity_curve"]), 0.55, 1.5)
    f0 = clampf((INTENSITY_V_FLOOR + (1.0 - INTENSITY_V_FLOOR) * (0.0 ** curve)) * vf, 0.0, 1.0)
    f1 = clampf((INTENSITY_V_FLOOR + (1.0 - INTENSITY_V_FLOOR) * (1.0 ** curve)) * vf, 0.0, 1.0)
    return f0, f1


def main() -> None:
    print("Weapon physics simulation (WeaponDamageHelper + ImpactVelocityModel + WeaponSwingPhysics)")
    print(
        "Thrust: linear v from band; KE = 0.5 * m_strike * v^2. Swing: v_tip = omega*r; KE = 0.5 * I * omega^2 (capped). p_a = m_strike * v."
    )
    print("Columns: i=intensity | v=m/s | KE | p_a")
    print()
    for wname, ct, akey, move in SCENARIOS:
        w = WEAPONS[wname]
        m_s = get_striking_part_mass_kg(w, ct)
        vmin_b, vmax_b = resolve_band_m_s(wname, ct)
        f0, f1 = velocity_factor_range(akey)
        v_band_lo = vmin_b + (vmax_b - vmin_b) * f0
        v_band_hi = vmin_b + (vmax_b - vmin_b) * f1
        row_parts = [
            f"{wname:6} {move:16} m={m_s:.3f}kg band=[{vmin_b:.2f},{vmax_b:.2f}] "
            f"v(intensity) in [{v_band_lo:.2f},{v_band_hi:.2f}]"
        ]
        arch = ARCHETYPES[akey]
        for i in INTENSITIES:
            v = velocity_m_s_from_intensity(i, akey, wname, ct)
            ke = ke_j_from_delivery(w, arch, ct, v)
            pa = momentum_p_a(m_s, v)
            row_parts.append(f"i={i:g}: v={v:.2f} KE={ke:.1f}J p_a={pa:.2f}")
        print(" | ".join(row_parts))


if __name__ == "__main__":
    main()
