class_name ScarTests

extends ScarTestBase

## Scar part-specific penalties (leg/arm/head/chest), damage-mult scoping,
## scar merge/heal deepening, and catalog part-key structure.


static func _run_scar_part_penalty_empty(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var pen: Dictionary = ent._get_scar_part_penalty("left_leg")
    for k in pen.keys():
        if absf(float(pen[k]) - 1.0) > 1e-9:
            _fail(failures, "scar_empty: %s should be 1.0 with no scars (got %s)" % [k, str(pen[k])])
    _free_entity_fixture(ent)


## A malunited-bone leg scar reduces whole-locomotion functionality + effective move speed.


static func _run_leg_scar_reduces_leg_functionality(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    _seed_scar(scarred, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    var f_clean: float = clean._get_leg_functionality()
    var f_scar: float = scarred._get_leg_functionality()
    if not (f_scar < f_clean):
        _fail(
            failures,
            "scar_leg: leg functionality should drop with a malunited leg (%.3f vs clean %.3f)" % [f_scar, f_clean]
        )
    var s_clean: int = clean._get_effective_speed()
    var s_scar: int = scarred._get_effective_speed()
    if not (s_scar <= s_clean):
        _fail(
            failures,
            (
                "scar_leg_speed: effective speed should not increase with a scarred leg (%d vs clean %d)"
                % [s_scar, s_clean]
            )
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)


## A Volkmann ischemic-contracture arm scar reduces weapon-handling (grip) functionality.


static func _run_arm_scar_reduces_grip(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    _seed_scar(scarred, CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE, "right_arm")
    var g_clean: float = BodyPartQuery.get_arm_functionality(clean, "right_arm")
    var g_scar: float = BodyPartQuery.get_arm_functionality(scarred, "right_arm")
    if not (g_scar < g_clean):
        _fail(
            failures,
            "scar_arm: arm functionality should drop with a contracture (%.3f vs clean %.3f)" % [g_scar, g_clean]
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)


## A scarred head reduces the performance (perception) modifier.


static func _run_head_scar_reduces_perception(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    _seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "head")
    var p_clean: float = EntityPainConsciousness.get_performance_modifier(clean)
    var p_scar: float = EntityPainConsciousness.get_performance_modifier(scarred)
    if not (p_scar < p_clean):
        _fail(
            failures,
            "scar_head: performance modifier should drop with a head scar (%.3f vs clean %.3f)" % [p_scar, p_clean]
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)


## A scarred chest reduces the campaign stamina pool multiplier.


static func _run_chest_scar_reduces_stamina(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    _seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "chest")
    var m_clean: float = clean._get_campaign_stamina_mult()
    var m_scar: float = scarred._get_campaign_stamina_mult()
    if not (m_scar < m_clean):
        _fail(
            failures, "scar_chest: stamina mult should drop with a chest scar (%.3f vs clean %.3f)" % [m_scar, m_clean]
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)


## A part-scoped damage_mult affects only the scarred part (the stored part actually matters).


static func _run_scar_damage_mult_part_scoped(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    _seed_scar(ent, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    var d_sc: float = ent._get_scar_damage_mult("left_leg")
    var d_other: float = ent._get_scar_damage_mult("right_leg")
    if d_sc <= 1.0:
        _fail(failures, "scar_scope: scarred-part damage_mult should be > 1.0 (got %.3f)" % d_sc)
    if d_other != 1.0:
        _fail(failures, "scar_scope: non-scarred part damage_mult should be 1.0 (got %.3f)" % d_other)
    _free_entity_fixture(ent)


## A second severe wound on an already-scarred part DEEPENS the scar (id+part merge), not no-ops.


static func _run_scar_deepens_on_merge(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    _seed_scar(ent, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    var d_first: float = ent._get_scar_damage_mult("left_leg")
    # Re-mint the same id+part: _add_campaign_affliction deepens (returns false = already present).
    var added: bool = ent._add_campaign_affliction(
        CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    )
    var d_second: float = ent._get_scar_damage_mult("left_leg")
    if added:
        _fail(failures, "scar_deepen: re-mint of an existing id+part should deepen, not add a new entry (added=true)")
    if not (d_second > d_first):
        _fail(failures, "scar_deepen: damage_mult should deepen on re-mint (%.3f vs first %.3f)" % [d_second, d_first])
    _free_entity_fixture(ent)


## A deepened scar also heals WORSE (heal_mult moves further below 1.0), not faster: re-injuring
## hypovascular scar tissue impairs the remodeling phase (reduced tensile strength / extensibility,
## same anchor as SCAR_REINJURY_MULT). Directional pin for the deepen path — heals slower, never
## toward 1.0.


static func _run_scar_heal_deepens_worse(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    _seed_scar(ent, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    var h_first: float = ent._get_scar_heal_mult("left_leg")
    if h_first >= 1.0:
        _fail(failures, "scar_heal_deepen: baseline heal_mult should be < 1.0 (got %.3f)" % h_first)
    ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg"))
    var h_second: float = ent._get_scar_heal_mult("left_leg")
    if not (h_second < h_first):
        _fail(
            failures,
            "scar_heal_deepen: heal_mult should get WORSE (lower) on re-mint (%.3f vs first %.3f)" % [h_second, h_first]
        )
    _free_entity_fixture(ent)


## The catalog emits the part-specific keys only for the matching part category.


static func _run_catalog_has_part_keys(failures: PackedStringArray) -> void:
    var leg: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
    if not ("move_speed" in leg and float(leg["move_speed"]) < 1.0):
        _fail(
            failures, "catalog_leg: malunited leg should carry move_speed < 1.0 (got %s)" % str(leg.get("move_speed"))
        )
    var arm: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE, "right_arm")
    if not ("grip" in arm and float(arm["grip"]) < 1.0):
        _fail(failures, "catalog_arm: contracture arm should carry grip < 1.0 (got %s)" % str(arm.get("grip")))
    var head: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "head")
    if not ("perception" in head and float(head["perception"]) < 1.0):
        _fail(failures, "catalog_head: head scar should carry perception < 1.0 (got %s)" % str(head.get("perception")))
    var chest: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "chest")
    if not ("stamina_pool" in chest and float(chest["stamina_pool"]) < 1.0):
        _fail(
            failures,
            "catalog_chest: chest scar should carry stamina_pool < 1.0 (got %s)" % str(chest.get("stamina_pool"))
        )
    # A whole-body scar (part "") carries no part-specific keys.
    var whole: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_POST_SEPSIS_WEAKNESS, "")
    for k in ["move_speed", "grip", "perception", "stamina_pool"]:
        if k in whole:
            _fail(failures, "catalog_whole: whole-body scar should not carry %s" % k)

## The resolved-wound stash seam: stash descriptors, then clear on advance.
