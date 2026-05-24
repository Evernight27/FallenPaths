class_name PartySetup
extends RefCounted

## Sets up party manager, party menu, and Party button. Used by main.gd.
## world: the main scene (Node2D) - Character plus Character/Companion … up to party size under `CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP`.
## Also sets default party_formation for combat (FF4 formation UI). Optional encounter dict: set world meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** before **`CombatFlow.start_combat`** (same keys as **`CombatManager`** encounter defaults — see **`CombatManager.gd`** **`start()`**). Customize via world meta.

const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _CompanyState := preload("res://world/CompanyState.gd")

static func setup_party(world: Node2D) -> void:
	var party_manager_script = load(ResourcePaths.PARTY_MANAGER)
	if not party_manager_script:
		return
	var root: Node = world.get_tree().root
	for child in world.get_children():
		if child.get_script() == party_manager_script:
			child.queue_free()
	var pm = party_manager_script.new()
	pm.name = "PartyManager"
	world.add_child(pm)
	if world.has_node("Character"):
		pm.add_member(world.get_node("Character"))
	for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
		if pm.get_members().size() >= CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP:
			break
		var path = "Character/Companion" + ("" if i == 1 else str(i))
		if world.has_node(path):
			pm.add_member(world.get_node(path))

	var party_menu_script = load(ResourcePaths.PARTY_MENU)
	if not party_menu_script:
		world.set_meta("party_manager", pm)
		_CompanyState.attach_to_world(world)
		return

	var party_menu = party_menu_script.new()
	var overlay = _get_or_create_overlay(root)
	overlay.add_child(party_menu)

	var party_button = _create_party_button(world)
	overlay.add_child(party_button)

	world.set_meta("party_manager", pm)
	world.set_meta("party_menu", party_menu)
	# Default party formation for combat (front width capped in FormationPreset; BattleScene uses when starting combat).
	world.set_meta("party_formation", _FormationPreset.default_for_count(pm.get_members().size()))
	_CompanyState.attach_to_world(world)

static func _get_or_create_overlay(root: Node) -> CanvasLayer:
	for child in root.get_children():
		if child.name == "UIOverlayLayer":
			return child
	var overlay = CanvasLayer.new()
	overlay.name = "UIOverlayLayer"
	overlay.layer = 100
	root.add_child(overlay)
	return overlay

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
	return party_button
