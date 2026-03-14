class_name PartySetup
extends RefCounted

## Sets up party manager, party menu, and Party button. Used by main.gd.
## world: the main scene (Node2D) - must have Character and optionally Character/Companion.

static func setup_party(world: Node2D) -> void:
	var party_manager_script = load(ResourcePaths.PARTY_MANAGER)
	if not party_manager_script:
		return
	var pm = party_manager_script.new()
	world.get_tree().root.add_child(pm)
	if world.has_node("Character"):
		pm.add_member(world.get_node("Character"))
	if world.has_node("Character/Companion"):
		pm.add_member(world.get_node("Character/Companion"))

	var party_menu_script = load(ResourcePaths.PARTY_MENU)
	if not party_menu_script:
		world.set_meta("party_manager", pm)
		return

	var party_menu = party_menu_script.new()
	var root = world.get_tree().root
	var overlay = _get_or_create_overlay(root)
	overlay.add_child(party_menu)

	var party_button = _create_party_button(world)
	overlay.add_child(party_button)

	world.set_meta("party_manager", pm)
	world.set_meta("party_menu", party_menu)

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
