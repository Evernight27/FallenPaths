class_name CompanyRunEndPanel
extends RefCounted

## Run-ending modal (contract loss / defeat). Restarts main after dismiss (Camp-1.4 / Camp-2.6).
## Tutorial losses dismiss without scene reload (company meta preserved).

const MAIN_SCENE := "res://main.tscn"
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _Persistence := preload("res://world/CampaignPersistence.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")


static func show_and_await(world: Node2D, reason: String, detail: String = "") -> void:
	if world == null or world.get_tree() == null:
		return
	_disable_overworld_input(world, false)
	_hide_party_menu_if_open(world)
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.name = "CompanyRunEndLayer"
	world.get_tree().root.add_child(layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var tall_body: bool = detail.length() > 120
	panel.offset_left = -260
	panel.offset_top = -160 if tall_body else -120
	panel.offset_right = 260
	panel.offset_bottom = 160 if tall_body else 120
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = _title_for_reason(reason)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var body := Label.new()
	body.text = detail if not detail.is_empty() else _body_for_reason(reason)
	_RowFormatter.configure_wrapped_label(body)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(body)

	var btn := Button.new()
	btn.text = _button_label_for_reason(reason)
	var wait_state: Dictionary = {"done": false}
	btn.pressed.connect(func() -> void:
		wait_state["done"] = true
		layer.queue_free()
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"company_run_end reason=%s reload=%s"
				% [reason, str(not _uses_soft_resume(reason)).to_lower()]
			)
		if not _uses_soft_resume(reason):
			_Persistence.clear_slot()
			world.get_tree().change_scene_to_file(MAIN_SCENE)
	)
	vbox.add_child(btn)

	await world.get_tree().process_frame
	btn.grab_focus()
	while not bool(wait_state.get("done", false)):
		await world.get_tree().process_frame


static func _title_for_reason(reason: String) -> String:
	match reason:
		"contract_failed":
			return "Contract failed"
		"bankrupt":
			return "Company bankrupt"
		"tutorial_failed":
			return "Fight lost"
		"soft_defeat_resume":
			return "Defeated"
		_:
			return "Company destroyed"


static func _body_for_reason(reason: String) -> String:
	match reason:
		"contract_failed":
			return (
				"The company could not complete the contract. Your mercenaries are scattered. "
				+ "EA: this run is not saved — restart begins a new company."
			)
		"bankrupt":
			return (
				"You cannot pay wages or hold the company together. "
				+ "Brothers with very low mood may desert instead of a total gold wipe. "
				+ "EA: this run is not saved — restart begins a new company."
			)
		"tutorial_failed":
			return "Tutorial lost — return to camp and try again."
		"soft_defeat_resume":
			return "Battle lost. Return to camp and recover."
		_:
			return "Your company has been defeated."


static func _button_label_for_reason(reason: String) -> String:
	match reason:
		"tutorial_failed", "soft_defeat_resume":
			return "Return to camp"
		_:
			return "Restart company"


static func _uses_soft_resume(reason: String) -> bool:
	return reason in ["tutorial_failed", "soft_defeat_resume"]


static func _hide_party_menu_if_open(world: Node2D) -> void:
	if world == null or not world.has_meta("party_menu"):
		return
	var menu: Variant = world.get_meta("party_menu")
	if menu is PopupPanel and (menu as PopupPanel).visible:
		(menu as PopupPanel).hide()


static func _disable_overworld_input(world: Node2D, enabled: bool) -> void:
	var player: Node = world.get_node_or_null("Character")
	if player != null and player.has_method("set_process_input"):
		player.set_process_input(enabled)
	var pb: Control = _find_party_button(world)
	if pb != null:
		pb.visible = enabled


static func _find_party_button(world: Node2D) -> Control:
	var root: Node = world.get_tree().root
	for child in root.get_children():
		if child.name == "UIOverlayLayer":
			var pb: Node = child.get_node_or_null("PartyButton")
			if pb is Control:
				return pb
	return null
