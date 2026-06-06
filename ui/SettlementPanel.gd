class_name SettlementPanel
extends RefCounted

## Post-victory settlement (Camp-1.5). Pay, wound summary, roster cleanup (Camp-1.8 K3).

const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _Snapshot := preload("res://world/PartyMemberSnapshot.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")


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

	var worst: Dictionary = _worst_triage_from_summary(world)
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

	var memorials: PackedStringArray = _CompanyState.apply_casualty_cleanup(world)
	for line in memorials:
		var mem := Label.new()
		mem.text = line
		_RowFormatter.configure_wrapped_label(mem)
		mem.add_theme_color_override("font_color", Color(0.85, 0.55, 0.45))
		vbox.add_child(mem)

	var supplies_lbl := Label.new()
	var med_n: int = _CompanyState.get_medical_supplies(world)
	var med_suffix: String = _CompanyState.format_hud_triage_suffix(world)
	supplies_lbl.text = "Supplies: %d med%s · %d tools" % [med_n, med_suffix, _CompanyState.get_tool_supplies(world)]
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
				supplies_lbl.text = "Supplies: %d med%s · %d tools" % [
					_CompanyState.get_medical_supplies(world),
					_CompanyState.format_hud_triage_suffix(world),
					_CompanyState.get_tool_supplies(world),
				]
				repair_btn.disabled = true
				repair_btn.text = "Gear repaired"
		)
		vbox.add_child(repair_btn)

	var roster_rows: Array = _roster_rows_for_settlement(world, true)
	for m in roster_rows:
		var snap: Dictionary = m if m is Dictionary else {}
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 2)
		_append_member_vitals_labels(block, snap)
		vbox.add_child(block)

	var btn := Button.new()
	btn.text = "Continue"
	var wait_state: Dictionary = {"done": false}
	btn.pressed.connect(func() -> void:
		wait_state["done"] = true
		_apply_victory_mood_boost(world)
		layer.queue_free()
		_CompanyState.clear_active_contract(world)
		_CompanyState.refresh_hud(world)
		_CampaignBridge.sync_overworld_player_grid_anchor(world)
		_disable_overworld_input(world, true)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"settlement_continue pay=%d gold=%d renown=%d tutorial=%s"
				% [
					pay,
					_CompanyState.get_gold(world),
					_CompanyState.get_renown(world),
					str(_CompanyState.is_tutorial_contract(contract)).to_lower(),
				]
			)
	)
	vbox.add_child(btn)

	while not bool(wait_state.get("done", false)):
		await world.get_tree().process_frame


static func _apply_victory_mood_boost(world: Node2D) -> void:
	if world == null or not world.has_meta("party_manager"):
		return
	var pm: Variant = world.get_meta("party_manager")
	if pm == null or not pm.has_method("get_members"):
		return
	for m in pm.get_members():
		if m is Dictionary:
			_CompanyState.adjust_member_mood(world, str(m.get("name", "")), _CompanyState.MOOD_BATTLE_WON_DELTA)


static func _worst_triage_from_summary(world: Node2D) -> Dictionary:
	var summary: Dictionary = _CompanyState.get_last_battle_summary(world)
	var members: Variant = summary.get("members", [])
	if not (members is Array):
		return {}
	var worst_eta: float = INF
	var worst: Dictionary = {}
	for entry in members as Array:
		if entry is not Dictionary:
			continue
		var snap: Dictionary = (entry as Dictionary).get("snapshot", entry) as Dictionary
		if snap.is_empty():
			continue
		var bv: float = float(snap.get("blood_volume", 100.0))
		var bleed: float = float(snap.get("total_bleeding_rate", 0.0))
		if bleed <= 0.0 and not bool(snap.get("has_untreated_wounds", false)):
			continue
		var triage_line: String = ""
		var eta: float = INF
		if bleed <= 0.0 and bool(snap.get("has_untreated_wounds", false)):
			triage_line = "Undressed — field bandage/pack/TQ needed"
			eta = 0.0
		else:
			triage_line = _RowFormatter.format_triage_line(bv, bleed)
			eta = _RowFormatter.seconds_to_danger_band(bv, bleed)
		if eta < worst_eta:
			worst_eta = eta
			worst = {
				"name": str(snap.get("name", "?")),
				"triage_line": triage_line,
			}
	return worst


static func _roster_rows_for_settlement(world: Node2D, prefer_live_snapshots: bool = false) -> Array:
	if prefer_live_snapshots:
		var pm_live: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
		if pm_live != null and "members" in pm_live:
			var live_rows: Array = []
			for m in pm_live.members:
				if m is Dictionary:
					live_rows.append(_Snapshot.snapshot_from_member(m))
			if not live_rows.is_empty():
				return live_rows
	var summary: Dictionary = _CompanyState.get_last_battle_summary(world)
	var members: Variant = summary.get("members", [])
	if members is Array and not (members as Array).is_empty():
		var rows: Array = []
		for entry in members as Array:
			if entry is Dictionary:
				var snap: Variant = (entry as Dictionary).get("snapshot", entry)
				if snap is Dictionary:
					rows.append(snap)
		return rows
	var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
	if pm != null and "members" in pm:
		var fallback: Array = []
		for m in pm.members:
			if m is Dictionary:
				fallback.append(_Snapshot.snapshot_from_member(m))
		return fallback
	return []


static func _append_member_vitals_labels(parent: VBoxContainer, m: Dictionary) -> void:
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
	var untreated: Variant = m.get("untreated_parts", [])
	if untreated is PackedStringArray and (untreated as PackedStringArray).size() > 0:
		var wound_lbl := Label.new()
		wound_lbl.text = "Untreated: " + _MapFieldCare.format_part_list(untreated)
		_RowFormatter.configure_wrapped_label(wound_lbl)
		wound_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
		parent.add_child(wound_lbl)
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
