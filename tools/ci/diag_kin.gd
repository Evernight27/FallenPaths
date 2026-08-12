extends SceneTree

const WeaponDamageHelper := preload("res://resources/weapons/WeaponDamageHelper.gd")
const AttackInstance := preload("res://resources/weapons/AttackInstance.gd")
const WeaponConstants := preload("res://resources/weapons/WeaponConstants.gd")
const HarnessFixtures := preload("res://harness/HarnessFixtures.gd")


func _init() -> void:
    var spear: RefCounted = HarnessFixtures.get_cached_weapon("SPEAR")
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    for vo in [9.0, 14.0]:
        var ai := AttackInstance.new("spear_thrust", 0.62)
        ai.archetype = arch
        ai.velocity_m_s = vo
        var ke: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, ai)
        var raw: float = WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, ke)) * maxf(0.1, 80.0 / 100.0) * 1.0
        var ct: float = WeaponDamageHelper._get_effective_sharp_contact_cm(spear, "st")
        var cf_new: float = pow(WeaponConstants.BASELINE_CONTACT_CM / ct, 0.23)
        cf_new = minf(cf_new, 1.50)
        print("vo=%.1f ke=%.4f raw=%.4f pre_cut_clamped=%.4f ratio_check=%s" % [
            vo, ke, raw * cf_new, min(raw * cf_new, WeaponConstants.DAMAGE_KE_MAX),
            "OK" if (raw * cf_new) < WeaponConstants.DAMAGE_KE_MAX else "CLAMPED"
        ])
    quit(0)
