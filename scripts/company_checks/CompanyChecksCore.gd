class_name CompanyChecksCore
extends RefCounted

## Shared fixtures for headless company-state harness modules under scripts/company_checks/.

const CampaignWorldScript := preload("res://scripts/_harness_campaign_world.gd")
const PARTY_MANAGER_SCRIPT := preload("res://world/PartyManager.gd")
const PARTY_MENU_SCRIPT := preload("res://ui/PartyMenu.gd")

static var _test_count: int = 0


static func _fail(failures: PackedStringArray, msg: String) -> void:
    failures.append(msg)


static func _pass() -> void:
    _test_count += 1


static func _new_party_manager() -> Node:
    return PARTY_MANAGER_SCRIPT.new()


static func _new_party_menu() -> PopupPanel:
    return PARTY_MENU_SCRIPT.new() as PopupPanel


static func _party_manager_script_ref() -> Script:
    return PARTY_MANAGER_SCRIPT as Script


static func _party_menu_script_ref() -> Script:
    return PARTY_MENU_SCRIPT as Script


static func _harness_root() -> Node:
    var loop: Variant = Engine.get_main_loop()
    if loop is SceneTree:
        return (loop as SceneTree).root
    return null


static func _release_harness_world(world: Node) -> void:
    if world == null or not is_instance_valid(world):
        return
    if world is Node2D and (world as Node2D).is_inside_tree():
        _free_harness_world(world)
    else:
        world.free()


static func _detach_and_free_meta_node(world: Node, meta_key: String) -> void:
    if world == null or not world.has_meta(meta_key):
        return
    var node_ref: Variant = world.get_meta(meta_key)
    world.remove_meta(meta_key)
    if typeof(node_ref) != TYPE_OBJECT or not is_instance_valid(node_ref):
        return
    var node: Node = node_ref as Node
    if node == null:
        return
    var node_parent: Node = node.get_parent()
    if node_parent != null:
        node_parent.remove_child(node)
    node.free()


static func _free_harness_world(world: Node) -> void:
    if world == null or not is_instance_valid(world):
        return
    _detach_and_free_meta_node(world, CompanyState.WORLD_META_COMPANY_HUD)
    _detach_and_free_meta_node(world, "party_menu")
    var root: Node = _harness_root()
    if root != null:
        for layer in root.get_children():
            if layer.name != "UIOverlayLayer":
                continue
            for gc in layer.get_children().duplicate():
                if gc is Button and gc.name == "PartyButton":
                    layer.remove_child(gc)
                    gc.free()
    var parent: Node = world.get_parent()
    if parent != null:
        parent.remove_child(world)
    world.free()


static func _cleanup_harness_ui_overlay() -> void:
    var root: Node = _harness_root()
    if root == null:
        return
    for child in root.get_children():
        if child.name != "UIOverlayLayer":
            continue
        for gc in child.get_children():
            child.remove_child(gc)
            gc.free()
        root.remove_child(child)
        child.free()


static func _cleanup_harness_tree_leaks() -> void:
    var root: Node = _harness_root()
    if root == null:
        return
    for child in root.get_children().duplicate():
        if child is Node2D and child.get_script() == CampaignWorldScript:
            _free_harness_world(child)
    _cleanup_harness_ui_overlay()


static func _make_world(living_count: int, dead_count: int = 0, in_tree: bool = false) -> Node2D:
    var world := Node2D.new()
    world.set_script(CampaignWorldScript)
    var pm_script: Script = PARTY_MANAGER_SCRIPT as Script
    var pm: Node = pm_script.new()
    pm.name = "PartyManagerHarness"
    world.add_child(pm)
    for i in living_count + dead_count:
        var n := Node2D.new()
        n.name = "Brother%d" % i
        if i >= living_count:
            n.set_script(load("res://scripts/_harness_dead_stub.gd"))
        pm.add_child(n)
        pm.members.append({"name": n.name, "node_ref": n})
    world.set_meta("party_manager", pm)
    CompanyState.init_from_defaults(world)
    if in_tree:
        var root: Node = _harness_root()
        if root != null:
            root.add_child(world)
    return world


static func _add_player_at_camp(world: Node2D) -> Node2D:
    var player := Node2D.new()
    player.name = "Character"
    player.position = Vector2(32, 32)
    world.add_child(player)
    return player


static func _add_living_entity_member(pm: Node, member_name: String) -> Node:
    var ent: Node = _harness_core_entity()
    ent.name = member_name
    ent.apply_species()
    pm.add_child(ent)
    (
        pm
        . members
        . append(
            {
                "name": member_name,
                "node_ref": ent,
                "company_mood": 50.0,
            }
        )
    )
    return ent


static func _harness_core_entity() -> Node:
    var ent: Node = CoreEntity.new()
    HarnessFixtures._track_harness_node(ent)
    return ent


static func _free_harness_core_entity(ent: Node) -> void:
    HarnessFixtures._free_harness_node(ent)


static func _instantiate_main_hire_world(in_tree: bool = false) -> Node2D:
    var packed: PackedScene = load("res://main.tscn") as PackedScene
    var world: Node2D = packed.instantiate() as Node2D
    if in_tree:
        var root: Node = _harness_root()
        if root != null:
            root.add_child(world)
    var rng := RandomNumberGenerator.new()
    rng.seed = 4242
    PlayerCompanionSetup.setup_player_and_companion(world, rng)
    PartySetup.setup_party(world)
    return world


static func _trim_party_to_leader(world: Node2D) -> void:
    var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null or not pm.has_method("remove_member_by_name"):
        return
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var suffix: String = "Companion" + ("" if i == 1 else str(i))
        pm.remove_member_by_name(suffix)


static func _make_overworld_spawn_world(in_tree: bool = false) -> Node2D:
    var world := Node2D.new()
    world.set_script(CampaignWorldScript)
    OverworldMap.stamp_world_map_size(world)
    var pm_script: Script = PARTY_MANAGER_SCRIPT as Script
    var pm: Node = pm_script.new()
    pm.name = "PartyManagerHarness"
    world.add_child(pm)
    var brother: Node = _harness_core_entity()
    brother.name = "Brother0"
    brother.apply_species()
    pm.add_child(brother)
    pm.members.append({"name": brother.name, "node_ref": brother, "company_mood": 50.0})
    world.set_meta("party_manager", pm)
    CompanyState.init_from_defaults(world)
    var player := Node2D.new()
    player.name = "Character"
    player.position = OverworldMap.tile_center(CompanyState.DEFAULT_CAMP_TILE)
    world.add_child(player)
    if in_tree:
        var root: Node = _harness_root()
        if root != null:
            root.add_child(world)
    return world


static func _count_encounter_markers(world: Node2D) -> int:
    var n: int = 0
    for child in world.get_children():
        if child.get_script() == EncounterNode:
            n += 1
    return n


static func _clear_paid_contract_markers(world: Node2D) -> void:
    if world == null:
        return
    for child in world.get_children().duplicate():
        if child.get_script() != EncounterNode:
            continue
        if str(child.marker_kind) == "contract":
            child.free()


static func _collect_control_label_texts(root: Node) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    if root is Label:
        out.append((root as Label).text)
    for child in root.get_children():
        out.append_array(_collect_control_label_texts(child))
    return out
