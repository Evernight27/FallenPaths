class_name CombatDesignAnchors
extends RefCounted

## Single source for cross-module combat design anchors (KE, mass, blood mL, human display caps).
## Consumers: `SpeciesResource`, `TissueEnergyCapacity`, `BloodVolumeMl`, `WeaponDamageHelper`,
## `MaterialFailureCurves`, `CombatCalibrationAudit`, harness simulation, `CombatResearchAnchors`.

## Narrative committed-strike KE (J) for arm / leg slots (S1 delivery, S5 derived limbs, M6 pool).
const DESIGN_KE_ARM_J := 100.0
const DESIGN_KE_LEG_J := 200.0

## Adult reference mass (kg)  -  matches `resources/species/human.tres` `reference_body_mass_kg`.
const REFERENCE_ADULT_MASS_KG := 75.0

## Whole-blood volume scaling (StatPearls / transfusion texts).
const REFERENCE_BLOOD_ML_PER_KG := 70.0
const REFERENCE_BLOOD_VOLUME_ML_ADULT := REFERENCE_ADULT_MASS_KG * REFERENCE_BLOOD_ML_PER_KG

## `human.tres` tissue integer sum (10+30+12+12+16+16); scales inferred mass when `reference_body_mass_kg` unset.
const REFERENCE_HUMAN_TISSUE_SUM := 96

## Human hand-export tissue display caps (energy pool '?'' J capacity).
const REFERENCE_HUMAN_ARM_TISSUE_DISPLAY := 20
const REFERENCE_HUMAN_LEG_TISSUE_DISPLAY := 24

## HEMA committed oberhau strict audit band (S1 / `.calibration_audit.txt` `audit_KE_arm_strict_65-145J`).
## Based on force-plate measurements: Lehmann 2013, Schmidt chronometry — trained fighters deliver 65-145J committed longsword cuts.
const COMMITTED_STRIKE_KE_J_MIN := 65.0
const COMMITTED_STRIKE_KE_J_MAX := 145.0

## Combat-realistic KE band: what a typical exchange produces (i≈0.55–0.75, commit≈0.7–0.9).
## Lower than committed because most exchanges involve partial commitment; consistent with HEMA bout recordings.
const COMBAT_REALISTIC_KE_J_MIN := 35.0
const COMBAT_REALISTIC_KE_J_MAX := 95.0

## Reference committed arm KE (oberhau i=1 + extension commit; M1/M2 curve anchors).
const REFERENCE_COMMITTED_OBERHAU_KE_J := 137.0

## Material curve ultimate pen = S8 severity full depth + offset (6.0 mm at current tuning).
const CUT_TISSUE_ULTIMATE_PEN_OFFSET_MM := 1.0


static func design_ke_j_for_part(part: String) -> float:
    if part.ends_with("_leg"):
        return DESIGN_KE_LEG_J
    return DESIGN_KE_ARM_J


static func reference_tissue_display_for_part(part: String) -> int:
    if part.ends_with("_leg"):
        return REFERENCE_HUMAN_LEG_TISSUE_DISPLAY
    return REFERENCE_HUMAN_ARM_TISSUE_DISPLAY


static func cut_tissue_ultimate_pen_mm() -> float:
    return BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM + CUT_TISSUE_ULTIMATE_PEN_OFFSET_MM


static func reference_blood_volume_ml_for_mass(reference_mass_kg: float) -> float:
    if reference_mass_kg <= 0.0:
        return REFERENCE_BLOOD_VOLUME_ML_ADULT
    return REFERENCE_BLOOD_ML_PER_KG * reference_mass_kg


static func committed_strike_ke_in_strict_band(ke_j: float) -> bool:
    return ke_j >= COMMITTED_STRIKE_KE_J_MIN and ke_j <= COMMITTED_STRIKE_KE_J_MAX


## Per-weapon KE audit bands for tuning / balance matrix (committed delivery, i≈0.65–0.85).
static func ke_band_min_max_for_weapon(weapon_id: String, kinematic_delivery: String = "") -> Vector2:
    var wid: String = weapon_id.to_upper().strip_edges()
    var delivery: String = kinematic_delivery.to_lower().strip_edges()
    if wid == "DAGGER":
        return Vector2(15.0, 70.0)
    if delivery == "thrust" and wid == "SPEAR":
        # Spear thrust: m=3.5kg body-transfer × v²/2 at v=[5,8.0] → [56,112]J; matches committed strike ceiling (145J max).
        # Floor matches the default SPEAR band (45J) so the [Matchup] header ref and the thrust in_band check agree.
        return Vector2(45.0, 130.0)
    match wid:
        "AXE":
            # Axe cut: short blade (25cm) on long lever (1.105m → low omega) produces less KE than sword.
            # Band-min lowered from 55J to 40J; swing at i=0.6 lands ~38-45J, committed (~0.75) ~50-60J with inertia_scale=0.80 (pure physics).
            return Vector2(40.0, 155.0)
        "MACE":
            # Committed-delivery band from the template's rotational physics: I≈0.415 kg·m² (head 0.7 + shaft
            # 0.3, ×inertia_scale 0.80), lever r=0.625 m (head COM from grip). Committed overhead i=1 → v≈13.1 m/s
            # → ω=v/r≈21 rad/s → KE≈91 J (pure physics, no e_mult); a quick low/side blow (i≈0.4) lands ~40 J.
            return Vector2(40.0, 190.0)
        "SPEAR":
            return Vector2(45.0, 130.0)
        _:
            return Vector2(COMMITTED_STRIKE_KE_J_MIN, COMMITTED_STRIKE_KE_J_MAX)


static func ke_in_weapon_band(ke_j: float, weapon_id: String, kinematic_delivery: String = "") -> bool:
    if ke_j <= 0.0:
        return false
    var band: Vector2 = ke_band_min_max_for_weapon(weapon_id, kinematic_delivery)
    return ke_j >= band.x and ke_j <= band.y
