class_name ScarTestBase

extends CombatRegressionHarnessCore

## Shared fixtures for the scar test modules: entity teardown and scar seeding.
## Split out of ScarTests to keep each test module under the file-size budget.


## CAMP-SCAR-1: wound-derived scars. Part-specific penalties (§9.5) — a scarred limb carries a
## location-specific penalty on top of the universal damage/bleed/heal multipliers: leg -> move_speed,
## arm -> grip, head -> perception, chest -> stamina_pool. Plus the catalog, id+part merge/deepen, and
## the resolved-wound stash seam. All core-side (no world/party node needed).
static func _free_entity_fixture(n: Node) -> void:
    _free_harness_node(n)


## Mint a real catalog scar def onto the entity via the shared _add_campaign_affliction path.


static func _seed_scar(ent: Node, scar_id: String, part: String) -> Dictionary:
    var def: Dictionary = CampaignAfflictions.scar_def(scar_id, part)
    ent._add_campaign_affliction(def)
    return def

## No scars -> every part-specific factor is 1.0.
