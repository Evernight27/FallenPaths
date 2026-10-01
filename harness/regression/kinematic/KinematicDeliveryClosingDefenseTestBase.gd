class_name KinematicDeliveryClosingDefenseTestBase

extends CombatRegressionHarnessCore

## Shared fixtures for the kinematic delivery/closing-defense test modules: entity + damage-sample helpers.
## Split out of KinematicDeliveryClosingDefenseTests to keep each test module under the file-size budget.

const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

## Tier 5.1 (optional long-tail): rear **`engagement_angle`** ×  **`afterblow_damage_mult`** compose on **`v`**.
## -> **`strike_ke_j`** (~**(cls ×  sqrtab)2**).
const HumanSpecies := preload("res://resources/species/human.tres")


static func _kin_entity_with_human_species(weapon_id: String) -> CoreEntity:
    var e: CoreEntity = CombatRegressionHarness._new_entity(weapon_id)
    if e.species == null:
        e.species = HumanSpecies
        e.apply_species()
    return e


static func _kin_dmg_sample_on_part(
    part: String, vo: float, weapon_id: String, move_id: String, arch: Dictionary
) -> Dictionary:
    var m: Node = CombatManager.new()
    m.set_meta(CombatRegressionHarness.HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    m.set_meta(CombatRegressionHarness.HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
    m.register(KinematicDeliveryClosingDefenseTestBase._kin_entity_with_human_species(weapon_id), "player")
    m.register(KinematicDeliveryClosingDefenseTestBase._kin_entity_with_human_species(weapon_id), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        part,
        0.62,
        move_id,
        arch,
        vo,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        1.0,
        1.0,
        {},
        {}
    )
    var rd: Dictionary = res.get("result_dict", {}) as Dictionary
    return {
        "mgr": m,
        "tgt": tgt,
        "pre_blunt": float(rd.get("pre_blunt_applied", -999.0)),
        "pre_cut": float(rd.get("pre_cut_applied", -999.0)),
    }


## Tier 5.1 (optional long-tail): **`effective_blunt_target_mass_kg`**  -  **MACE** **`direct_blow`**
## **`pre_blunt_applied`** differs on **head** vs **chest** (reduced-mass coupling).

## Tier 5.1 (optional long-tail): **`effective_blunt_target_mass_kg`**  -  **MACE** **`direct_blow`**
## **`pre_blunt_applied`** differs on **head** vs **chest** (reduced-mass coupling).


static func _kin_unarmed_pre_blunt_afterblow_sample(afterblow_mult: float) -> float:
    var m: Node = CombatManager.new()
    m.set_meta(HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
    m.register(CombatRegressionHarness._new_entity_unarmed(), "player")
    m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = m.combatants[0]
    var tgt: Dictionary = m.combatants[1]
    var res: Dictionary = AttackResolver.compute_and_apply_damage(
        m,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(tgt),
        atk,
        tgt,
        "chest",
        0.62,
        "punch",
        {},
        -1.0,
        1.0,
        1.0,
        -1.0,
        -1.0,
        1.0,
        afterblow_mult,
        1.0,
        {},
        {}
    )
    var pre: float = float(res.get("result_dict", {}).get("pre_blunt_applied", -999.0))
    CombatRegressionHarness._free_manager(m)
    return pre


## Tier 5.1 (optional long-tail): unarmed path  -  **`afterblow_damage_mult`** scales **`pre_blunt_applied`** via
## **`sqrt(mult)`** (closing/stamina path, not KE).

## Tier 5.1 (optional long-tail): unarmed path  -  **`afterblow_damage_mult`** scales **`pre_blunt_applied`** via
## **`sqrt(mult)`** (closing/stamina path, not KE).


static func _kin_result_split_fields_sample(
    vo: float, weapon_id: String, move_id: String, arch: Dictionary
) -> Dictionary:
    var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
        vo, 1.0, 1.0, {}, weapon_id, move_id, 1.0, arch
    )
    CombatRegressionHarness._free_manager(sample["mgr"] as Node)
    return {
        "final_cut": float(sample["final_cut"]),
        "final_blunt": float(sample["final_blunt"]),
        "final_bone": float(sample["final_bone"]),
        "total_physical": float(sample["total_physical"]),
    }

## Tier 5.1 (optional long-tail): weapon path  -  **`afterblow_damage_mult`** scales **`pre_cut_applied`** by
## **`sqrt(mult)`** (**`v`** ×  sqrtmult -> **`pre_cut`** ~ sqrtKE).

## Tier 5.1 (optional long-tail): weapon path  -  **`afterblow_damage_mult`** scales **`pre_cut_applied`** by
## **`sqrt(mult)`** (**`v`** ×  sqrtmult -> **`pre_cut`** ~ sqrtKE).
