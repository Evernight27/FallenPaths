class_name SettlementPanel
extends RefCounted

## Post-victory settlement (Camp-1.5). Pay, wound summary, roster cleanup (Camp-1.8 K3).

const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _ContractSpawner := preload("res://world/ContractSpawner.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _CampaignAfflictions := preload("res://world/CampaignAfflictions.gd")


static func show_and_await(world: Node2D) -> void:
	if world == null or world.get_tree() == null:
		return
	_disable_overworld_input(world, false)
	_hide_party_menu_if_open(world)
	var contract: Dictionary = _CompanyState.get_active_contract(world)
	var base_pay: int = int(contract.get("pay_gold", 0))
	var pay: int = _CompanyState.apply_contract_victory_pay(world)
	var affliction_lines: PackedStringArray = _CompanyState.apply_post_victory_afflictions(world)
	var title: String = str(contract.get("contract_title", "Contract"))

	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.name = "SettlementLayer"
	world.get_tree().root.add_child(layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -200
	panel.offset_right = 280
	panel.offset_bottom = 200
	layer.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 360)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "Settlement — %s" % title
	hdr.add_theme_font_size_override("font_size", 18)
	vbox.add_child(hdr)

	var roster_rows: Array = _CampaignBridge.party_member_snapshots(world)
	var worst: Dictionary = _RowFormatter.worst_triage_from_member_rows(roster_rows)
	if not worst.is_empty():
		var warn := Label.new()
		warn.text = "Worst triage — %s: %s" % [
			str(worst.get("name", "?")),
			str(worst.get("triage_line", "")),
		]
		_RowFormatter.configure_wrapped_label(warn)
		warn.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
		vbox.add_child(warn)

	var pay_lbl := Label.new()
	if _CompanyState.is_tutorial_contract(contract):
		pay_lbl.text = "No contract pay (%s)" % title
	elif pay > base_pay and base_pay > 0:
		pay_lbl.text = (
			"Payment: +%d gold (contract %d + renown %d bonus)"
			% [pay, base_pay, pay - base_pay]
		)
	else:
		pay_lbl.text = "Payment: +%d gold (renown %d)" % [pay, _CompanyState.get_renown(world)]
	vbox.add_child(pay_lbl)

	for aff_line in affliction_lines:
		var aff_lbl := Label.new()
		aff_lbl.text = "Scarred — " + aff_line
		_RowFormatter.configure_wrapped_label(aff_lbl)
		aff_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95))
		vbox.add_child(aff_lbl)
	var scarred: int = _CampaignAfflictions.count_scarred_brothers(world)
	if scarred > 0 and affliction_lines.is_empty():
		var scar_summary := Label.new()
		scar_summary.text = (
			"Company scars: %d brother(s) carry permanent injuries (Party for details)."
			% scarred
		)
		_RowFormatter.configure_wrapped_label(scar_summary)
		scar_summary.add_theme_color_override("font_color", Color(0.7, 0.62, 0.88))
		vbox.add_child(scar_summary)

	var memorials: PackedStringArray = _CompanyState.apply_casualty_cleanup(world)
	for line in memorials:
		var mem := Label.new()
		mem.text = line
		_RowFormatter.configure_wrapped_label(mem)
		mem.add_theme_color_override("font_color", Color(0.85, 0.55, 0.45))
		vbox.add_child(mem)

	var burial_debt_warn: String = _CompanyState.format_settlement_burial_debt_warning(world)
	if not burial_debt_warn.is_empty():
		var burial_warn_lbl := Label.new()
		burial_warn_lbl.text = burial_debt_warn
		_RowFormatter.configure_wrapped_label(burial_warn_lbl)
		burial_warn_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
		vbox.add_child(burial_warn_lbl)

	var burial_lines: PackedStringArray = _CompanyState.apply_settlement_burial_costs(world)
	for line in burial_lines:
		var burial_lbl := Label.new()
		burial_lbl.text = line
		_RowFormatter.configure_wrapped_label(burial_lbl)
		burial_lbl.add_theme_color_override("font_color", Color(0.82, 0.72, 0.55))
		vbox.add_child(burial_lbl)

	var supplies_lbl := Label.new()
	supplies_lbl.text = format_settlement_supplies_line(world)
	vbox.add_child(supplies_lbl)

	if _CampaignBridge.party_has_untreated_wounds(world):
		var care_hint := Label.new()
		care_hint.text = _CompanyState.format_settlement_field_care_hint(world)
		_RowFormatter.configure_wrapped_label(care_hint)
		care_hint.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
		vbox.add_child(care_hint)

	var repair_state: Dictionary = {"done": false, "repaired": false}
	if _CompanyState.can_offer_settlement_tool_repair(world):
		var repair_btn := Button.new()
		repair_btn.text = "Repair gear (−1 tool, light field maintenance)"
		repair_btn.pressed.connect(func() -> void:
			if _CompanyState.apply_settlement_tool_repair(world):
				repair_state["repaired"] = true
				supplies_lbl.text = format_settlement_supplies_line(world)
				repair_btn.disabled = true
				repair_btn.text = "Gear repaired"
		)
		vbox.add_child(repair_btn)

	for m in roster_rows:
		var snap: Dictionary = m if m is Dictionary else {}
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 2)
		_append_member_vitals_labels(block, snap, world)
		vbox.add_child(block)

	_append_settlement_hint_if_set(
		vbox,
		_CompanyState.format_settlement_victory_mood_hint(),
		Color(0.72, 0.88, 0.72),
		_CompanyState.count_living_roster(world) > 0
	)
	_append_settlement_hint_if_set(
		vbox,
		_CompanyState.format_settlement_low_mood_stance_hint(world),
		Color(0.75, 0.82, 0.95)
	)
	_append_settlement_hint_if_set(
		vbox,
		_ContractSpawner.format_settlement_deck_refresh_hint(world),
		Color(0.72, 0.85, 0.95)
	)

	if _CompanyState.persistence_uses_disk_autosave():
		var save_hint := Label.new()
		save_hint.text = (
			"Progress autosaves on continue — restart main restores your last save."
			if _CompanyState.persistence_restore_on_main_restart()
			else "Progress autosaves when you continue."
		)
		_RowFormatter.configure_wrapped_label(save_hint)
		save_hint.add_theme_color_override("font_color", Color(0.65, 0.78, 0.88))
		vbox.add_child(save_hint)

	var btn := Button.new()
	btn.text = format_settlement_continue_button_label()
	var wait_state: Dictionary = {"done": false}
	btn.pressed.connect(func() -> void:
		wait_state["done"] = true
		_apply_victory_mood_boost(world)
		layer.queue_free()
		_CompanyState.clear_active_contract(world)
		var rng: RandomNumberGenerator = _CampaignBridge.resolve_overworld_rng(world)
		var enemy_scene: PackedScene = _CampaignBridge.resolve_enemy_scene(world)
		if rng != null:
			_ContractSpawner.try_refresh_contract_deck(world, rng, enemy_scene)
		_CompanyState.refresh_hud(world)
		_CampaignBridge.sync_overworld_player_grid_anchor(world)
		_disable_overworld_input(world, true)
		_CompanyState.try_autosave(world)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(format_settlement_continue_log(world, contract, pay))
	)
	vbox.add_child(btn)

	while not bool(wait_state.get("done", false)):
		await world.get_tree().process_frame


static func _append_settlement_hint_if_set(
	parent: VBoxContainer,
	text: String,
	color: Color = Color(0.75, 0.82, 0.95),
	show: bool = true
) -> void:
	if not show or text.is_empty():
		return
	var lbl := Label.new()
	lbl.text = text
	_RowFormatter.configure_wrapped_label(lbl)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


static func format_settlement_supplies_line(world: Node2D) -> String:
	var med_n: int = _CompanyState.get_medical_supplies(world)
	var med_suffix: String = _CompanyState.format_hud_triage_suffix(world)
	var line: String = (
		"Supplies: %d med%s · %d tools · %d food"
		% [med_n, med_suffix, _CompanyState.get_tool_supplies(world), _CompanyState.get_food_supplies(world)]
	)
	if _CompanyState.should_show_next_provisions_hint(world):
		line += " (rations short — mood −1 at next day end)"
	return line


static func format_settlement_continue_button_label() -> String:
	if _CompanyState.persistence_uses_disk_autosave():
		return "Continue (saves progress)"
	return "Continue"


## F5 §8 step 3: settlement Continue button world log (paid win path).
static func format_settlement_continue_log(world: Node2D, contract: Dictionary, pay: int) -> String:
	var autosave_bit: String = ""
	if _CompanyState.persistence_uses_disk_autosave():
		autosave_bit = " autosave=true"
	return (
		"settlement_continue pay=%d gold=%d renown=%d tutorial=%s%s"
		% [
			pay,
			_CompanyState.get_gold(world),
			_CompanyState.get_renown(world),
			str(_CompanyState.is_tutorial_contract(contract)).to_lower(),
			autosave_bit,
		]
	)


static func _apply_victory_mood_boost(world: Node2D) -> void:
	if world == null or not world.has_meta("party_manager"):
		return
	var pm: Variant = world.get_meta("party_manager")
	if pm == null or not pm.has_method("get_members"):
		return
	for m in pm.get_members():
		if m is Dictionary:
			_CompanyState.adjust_member_mood(world, str(m.get("name", "")), _CompanyState.MOOD_BATTLE_WON_DELTA)


static func _append_member_vitals_labels(parent: VBoxContainer, m: Dictionary, world: Node2D = null) -> void:
	var name_lbl := Label.new()
	name_lbl.text = str(m.get("name", "?"))
	parent.add_child(name_lbl)
	var bv: float = float(m.get("blood_volume", 100.0))
	var bleed: float = float(m.get("total_bleeding_rate", 0.0))
	var blood_lbl := Label.new()
	blood_lbl.text = _RowFormatter.format_blood_line(bv, bleed)
	if bleed > 0.0:
		blood_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
	parent.add_child(blood_lbl)
	var triage_line: String = _RowFormatter.format_triage_line(bv, bleed)
	if not triage_line.is_empty():
		var triage_lbl := Label.new()
		triage_lbl.text = triage_line
		_RowFormatter.configure_wrapped_label(triage_lbl)
		if bleed > 0.0 or bv <= _RowFormatter.danger_blood_threshold():
			triage_lbl.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
		parent.add_child(triage_lbl)
	var dressing_gate: String = _RowFormatter.format_dressing_gate_line(m)
	if not dressing_gate.is_empty():
		var dress_gate_lbl := Label.new()
		dress_gate_lbl.text = dressing_gate
		_RowFormatter.configure_wrapped_label(dress_gate_lbl)
		dress_gate_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.5))
		parent.add_child(dress_gate_lbl)
	var untreated: Variant = m.get("untreated_parts", [])
	if untreated is PackedStringArray and (untreated as PackedStringArray).size() > 0:
		var wound_lbl := Label.new()
		wound_lbl.text = "Needs dressing: " + _MapFieldCare.format_part_list(untreated)
		_RowFormatter.configure_wrapped_label(wound_lbl)
		wound_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
		parent.add_child(wound_lbl)
	if world != null:
		var next_action: String = _MapFieldCare.format_next_field_care_action(world, m)
		if not next_action.is_empty():
			var next_lbl := Label.new()
			next_lbl.text = next_action
			_RowFormatter.configure_wrapped_label(next_lbl)
			next_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95))
			parent.add_child(next_lbl)
	var afflictions: Variant = m.get("affliction_labels", [])
	if afflictions is PackedStringArray and (afflictions as PackedStringArray).size() > 0:
		var aff_names := Label.new()
		aff_names.text = "Afflictions: " + ", ".join(afflictions)
		_RowFormatter.configure_wrapped_label(aff_names)
		aff_names.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95))
		parent.add_child(aff_names)
	var status_line: String = _RowFormatter.format_vitality_status(m)
	if not status_line.is_empty():
		var status_lbl := Label.new()
		status_lbl.text = status_line
		_RowFormatter.configure_wrapped_label(status_lbl)
		if bool(m.get("has_untreated_wounds", false)) or bool(m.get("is_unconscious", false)):
			status_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
		parent.add_child(status_lbl)
	var aff_fx: String = _RowFormatter.format_affliction_effects_line(m)
	if not aff_fx.is_empty():
		var aff_lbl := Label.new()
		aff_lbl.text = aff_fx
		_RowFormatter.configure_wrapped_label(aff_lbl)
		aff_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95))
		parent.add_child(aff_lbl)


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
