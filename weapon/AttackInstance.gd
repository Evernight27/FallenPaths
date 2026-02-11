class_name AttackInstance
extends RefCounted

# One resolved attack: which attack type (stab/cut/blunt) and how much
# intensity (0–1) the unit committed (wind-up, recovery). Impact speed is always velocity_m_s (m/s).
# Creator sets velocity_m_s from WeaponDamageHelper.velocity_m_s_from_intensity or from physics (e.g. partial parry).
# archetype: optional dict from WeaponConstants.get_archetype(id) with velocity_factor, cut_ratio, recovery_multiplier, windup_multiplier.

var attack_type: String = "cut"
var intensity: float = 0.5   # 0.0–1.0: swing commitment (from strength + random; speed only affects gauge fill)
var velocity_m_s: float = -1.0  # If < 0, helper derives from intensity.
var archetype: Dictionary = {}  # Set by CombatManager from weapon + attack_type.


func _init(p_attack_type: String = "cut", p_intensity: float = 0.5, p_velocity_m_s: float = -1.0) -> void:
	attack_type = p_attack_type
	intensity = clampf(p_intensity, 0.0, 1.0)
	velocity_m_s = p_velocity_m_s


static func create(p_attack_type: String, p_intensity: float = 0.5, p_velocity_m_s: float = -1.0) -> AttackInstance:
	return AttackInstance.new(p_attack_type, p_intensity, p_velocity_m_s)
