class_name PartySetup
extends RefCounted

## Sets up party manager, party menu, and Party button. Used by scenes/campaign/main.gd.
## world: the main scene (Node2D) - Character plus Character/Companion ... up to party size under
## `CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP`.
## Also sets default party_formation for combat (FF4 formation UI). Optional encounter dict: set world meta
## **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** before **`CombatFlow.start_combat`** (same keys as
## **`CombatManager`** encounter defaults  -  see **`CombatManager.gd`** **`start()`**). Customize via world meta.

static var _company_state_cache: Variant = null


static func _get_company_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


static func setup_party(world: Node2D) -> void:
    if world == null or not world.is_inside_tree():
        return
    var party_manager_script = load(ResourcePaths.PARTY_MANAGER)
    if not party_manager_script:
        return
    var root: Node = world.get_tree().root
    _teardown_party_overlay_ui(world, root)
    for child in world.get_children().duplicate():
        if child.get_script() == party_manager_script:
            child.free()
    var pm = party_manager_script.new()
    pm.name = "PartyManager"
    world.add_child(pm)
    var player: Node2D = CampaignEncounterBridge.get_player(world)
    if player != null:
        pm.add_member(player)
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        if pm.get_members().size() >= CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP:
            break
        var path: String = "Character/%s" % _companion_node_name(i)
        if world.has_node(path):
            var companion_node: Node = world.get_node_or_null(path)
            if is_instance_valid(companion_node):
                pm.add_member(companion_node)

    var party_menu_script = load(ResourcePaths.PARTY_MENU)
    if not party_menu_script:
        world.set_meta("party_manager", pm)
        _get_company_state().attach_to_world(world)
        return

    var party_menu = party_menu_script.new()
    var overlay = _get_or_create_overlay(root)
    overlay.add_child(party_menu)

    var party_button = _create_party_button(world)
    overlay.add_child(party_button)

    world.set_meta("party_manager", pm)
    world.set_meta("party_menu", party_menu)
    # Default party formation for combat (front width capped in FormationPreset; BattleScene uses when starting combat).
    world.set_meta("party_formation", FormationPreset.default_for_count(pm.get_members().size()))
    _get_company_state().attach_to_world(world)


## XCamp-3.1: first companion scene node not on the living roster (post-casualty slot).
static func find_vacant_companion_node(world: Node2D) -> Node:
    if world == null or not world.has_node("Character"):
        return null
    var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    var occupied: Dictionary = {}
    if pm != null and "members" in pm:
        for member in pm.members:
            if member is not Dictionary:
                continue
            var node_ref: Variant = (member as Dictionary).get("node_ref")
            if not is_instance_valid(node_ref) or not (node_ref is Node):
                continue
            var node: Node = node_ref as Node
            if node.has_method("is_dead") and node.is_dead():
                continue
            occupied[node] = true
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var path: String = "Character/%s" % _companion_node_name(i)
        if not world.has_node(path):
            continue
        var companion: Node = world.get_node(path)
        if not occupied.has(companion):
            return companion
    return null


## Reset a vacant companion slot and register with PartyManager.
static func spawn_hire_companion(world: Node2D, rng: RandomNumberGenerator) -> Node:
    if world == null or rng == null:
        return null
    var companion: Node = find_vacant_companion_node(world)
    if companion == null:
        return null
    var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null or not pm.has_method("add_member"):
        return null
    var slot_index: int = _companion_slot_index(companion.name)
    PlayerCompanionSetup.setup_hired_companion(companion, rng, slot_index)
    if "visible" in companion:
        companion.visible = false
    pm.add_member(companion)
    world.set_meta("party_formation", FormationPreset.default_for_count(pm.get_members().size()))
    return companion


static func _companion_node_name(index: int) -> String:
    return "Companion" + ("" if index == 1 else str(index))


static func _companion_slot_index(node_name: String) -> int:
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        if node_name == _companion_node_name(i):
            return i - 1
    return 0


static func _find_overlay(root: Node) -> CanvasLayer:
    for child in root.get_children():
        if child.name == "UIOverlayLayer" and child is CanvasLayer:
            return child
    return null


static func _teardown_party_overlay_ui(world: Node2D, root: Node) -> void:
    if world.has_meta("party_menu"):
        var menu: Variant = world.get_meta("party_menu")
        if menu is Node and is_instance_valid(menu):
            var menu_parent: Node = (menu as Node).get_parent()
            if menu_parent != null:
                menu_parent.remove_child(menu)
            (menu as Node).free()
        world.remove_meta("party_menu")
    var overlay: CanvasLayer = _find_overlay(root)
    if overlay == null:
        return
    for gc in overlay.get_children().duplicate():
        if gc is Button and gc.name == "PartyButton":
            overlay.remove_child(gc)
            gc.free()


static func _get_or_create_overlay(root: Node) -> CanvasLayer:
    return CompanyEconomy._get_or_create_overlay(root)


static func _create_party_button(world: Node2D) -> Button:
    var party_button = Button.new()
    party_button.name = "PartyButton"
    party_button.text = "Party"
    party_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
    party_button.offset_left = 10
    party_button.offset_top = 10
    party_button.offset_right = 110
    party_button.offset_bottom = 50
    party_button.focus_mode = Control.FOCUS_NONE
    party_button.mouse_filter = Control.MOUSE_FILTER_STOP
    party_button.custom_minimum_size = Vector2(100, 32)
    party_button.add_theme_font_size_override("font_size", 16)
    party_button.z_index = 101
    party_button.pressed.connect(Callable(world, "_on_party_button_pressed"))
    _get_company_state().refresh_party_button(world)
    return party_button
