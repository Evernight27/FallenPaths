class_name AttackInstance
extends RefCounted

## Attack instance data structure: attack type, intensity, part, optional override.

# One resolved attack: move_id (WeaponConstants moves, e.g. thrust, oberhau) and how much
# intensity (0 - 1) the unit committed (wind-up, recovery). Impact speed is always velocity_m_s (m/s).
# Creator sets velocity_m_s from WeaponDamageHelper (weapon + move_id) or from physics (e.g. partial parry).
# archetype: optional dict from WeaponConstants.get_archetype(id) with velocity_factor, cut_ratio, recovery_multiplier,
# windup_multiplier.

var attack_type: String = "cut"
var intensity: float = 0.5  # 0.0 - 1.0: swing commitment (from strength + random; speed only affects gauge fill)
var velocity_m_s: float = -1.0  # If < 0, helper derives from intensity.
var archetype: Dictionary = {}  # Set by CombatManager from weapon + attack_type.
## StrikeRealismProfile: scales KE (v2 - -  coupling) and momentum (v - -  coupling) vs baseline band speed.
var strike_energy_mult: float = 1.0
var strike_momentum_mult: float = 1.0
## Swing-mechanics strike-mass coupling (TOPIC 8b): body-to-blade effective-mass transfer. 1.0 default keeps
## bare fixtures and untracked fighters unchanged; resolver sets 0.90-1.0 from combined weapon+form tier.
var strike_mass_mult: float = 1.0
## Weapon extension at impact (0 - 1). When >= 0, scales effective intensity for KE/cut (not blunt slip).
var delivery_commit_fraction: float = -1.0


func _init(p_attack_type: String = "cut", p_intensity: float = 0.5, p_velocity_m_s: float = -1.0) -> void:
    attack_type = p_attack_type
    intensity = clampf(p_intensity, 0.0, 1.0)
    velocity_m_s = p_velocity_m_s
