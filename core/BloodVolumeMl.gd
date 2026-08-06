class_name BloodVolumeMl
extends RefCounted

## S6 literal blood pool (mL) pilot  -  canonical `blood_volume_ml` when active; `blood_volume` % stays in sync for
## UI/ATLS.

## Adult reference blood volume: 70 mL/kg × 75 kg = 5250 mL. Based on Nadler-Rodkey formula (Nadler et al. 1962) and
## ATLS 11th ed. Table 1-3 (average adult male blood volume ~70 mL/kg, female ~65 mL/kg). Used as default for all
## human-species entities; non-human species scale via _REFERENCE_SPECIES_TISSUE_SUM in WeaponDamageHelper.
const REFERENCE_BLOOD_VOLUME_ML_ADULT: float = CombatDesignAnchors.REFERENCE_BLOOD_VOLUME_ML_ADULT
const REFERENCE_BLOOD_ML_PER_KG: float = CombatDesignAnchors.REFERENCE_BLOOD_ML_PER_KG

static var _harness_force_literal_blood_ml: bool = false


static func is_active(force: bool = false) -> bool:
    return force or BleedingConstants.FEATURE_LITERAL_BLOOD_ML or _harness_force_literal_blood_ml


static func blood_volume_ml_max_for_reference_mass(reference_mass_kg: float) -> float:
    return CombatDesignAnchors.reference_blood_volume_ml_for_mass(reference_mass_kg)


static func init_entity_pool(entity: Node, reference_mass_kg: float) -> void:
    var max_ml: float = blood_volume_ml_max_for_reference_mass(reference_mass_kg)
    # END scaling: higher endurance -> larger blood pool (END=150 -> 1.25x max blood).
    if entity.has_method("_get_endurance_blood_volume_mult"):
        max_ml *= entity._get_endurance_blood_volume_mult()
    _set_ml_max(entity, max_ml)
    _set_ml(entity, max_ml)
    entity.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME


static func clear_entity_pool(entity: Node) -> void:
    _set_ml_max(entity, -1.0)
    _set_ml(entity, -1.0)


static func entity_uses_ml(entity: Node) -> bool:
    if not is_active():
        return false
    return _ml_max(entity) > 0.0


static func sync_percent_from_ml(entity: Node) -> void:
    var max_ml: float = _ml_max(entity)
    var ml: float = _ml(entity)
    if max_ml <= 0.0:
        return
    entity.blood_volume = clampf(100.0 * ml / max_ml, 0.0, BleedingConstants.MAX_BLOOD_VOLUME)


static func sync_ml_from_percent(entity: Node) -> void:
    var max_ml: float = _ml_max(entity)
    if max_ml <= 0.0:
        return
    var pct: float = clampf(entity.blood_volume, 0.0, BleedingConstants.MAX_BLOOD_VOLUME)
    _set_ml(entity, max_ml * pct / BleedingConstants.MAX_BLOOD_VOLUME)


static func blood_ml_loss_per_second(total_bleeding_rate: float, blood_ml_max: float, loss_mult: float = 1.0) -> float:
    var pct_loss_per_s: float = BleedingConstants.blood_volume_loss_per_second(total_bleeding_rate, loss_mult)
    return pct_loss_per_s * blood_ml_max / BleedingConstants.MAX_BLOOD_VOLUME


static func blood_ml_recovery_per_second(recovery_pct_per_s: float, blood_ml_max: float) -> float:
    return recovery_pct_per_s * blood_ml_max / BleedingConstants.MAX_BLOOD_VOLUME


static func process_blood_loss_tick(
    entity: Node, total_bleeding_rate: float, delta: float, loss_mult: float, recovery_pct_per_s: float
) -> void:
    var max_ml: float = _ml_max(entity)
    if total_bleeding_rate > 0.0:
        var loss_ml: float = blood_ml_loss_per_second(total_bleeding_rate, max_ml, loss_mult) * delta
        _set_ml(entity, maxf(0.0, _ml(entity) - loss_ml))
        sync_percent_from_ml(entity)
    elif recovery_pct_per_s > 0.0:
        var add_ml: float = blood_ml_recovery_per_second(recovery_pct_per_s, max_ml) * delta
        _set_ml(entity, minf(max_ml, _ml(entity) + add_ml))
        sync_percent_from_ml(entity)


static func _ml(entity: Node) -> float:
    return float(entity.get("blood_volume_ml"))


static func _ml_max(entity: Node) -> float:
    return float(entity.get("blood_volume_ml_max"))


static func _set_ml(entity: Node, value: float) -> void:
    entity.set("blood_volume_ml", value)


static func _set_ml_max(entity: Node, value: float) -> void:
    entity.set("blood_volume_ml_max", value)
