extends Node

## Battle scene shell: wires **`BattleUIUpdater`** gauge rows and formation diagram.
## Footing: suffix order **Step Ã¢â ' Grd/Atk Ã¢â ' Form** via **`CombatUiHints`** — LIVE_PATHS **`#battle-ui`** · **`#wf-footing-doc-map`** · soak **`#wf-soak-audit-status`**.

signal battle_ended(winner: String, defeated: Node)

const _TurnReadyHandler := preload("res://ui/TurnReadyHandler.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationDiagramBuilder := preload("res://ui/FormationDiagramBuilder.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")

var players: Array = []
var enemies: Array = []
var parent_scene: Node = null

# manager & combat ids
var manager: Node = null
var id_to_controls := {} # map combatant id -> {row, name, body_bars, body_labels, gauge, gauge_label, node}
var combat_log: RichTextLabel = null
var combat_log_scroll: ScrollContainer = null
var end_battle_button: Button = null
var _pending_winner: String = ""
var _pending_defeated: Node = null
var _in_medical_phase: bool = false
var _medical_phase_finished_announced: bool = false
## Campaign medical phase log: 0 none, 1 idle/paused, 2 triage complete (`can_end_medical_phase`).
var _campaign_medical_status_log: int = 0
var _end_battle_exit_in_progress: bool = false
var _medical_exit_fast_forward_active: bool = false
## Cached reference to ContentVBox  -  avoids repeated get_node_or_null in _ensure_end_battle_button.
var _content_vbox: Control = null

# UI nodes
var canvas_layer: CanvasLayer
var formation_diagram_hbox: Control = null
var formation_diagram_enemy: Control = null
var formation_diagram_player: Control = null
var _enemy_engagement_label: Label = null
var _player_engagement_label: Label = null
var _player_list: Control = null
var _enemy_list: Control = null
var _player_preset: Dictionary = {}
var _enemy_preset: Dictionary = {}
var _diagram_refresh_sig: String = ""
var _ui_poll_accum: float = 0.0
## Poll interval while combat is running (stamina/guard refill in `waiting`; turn gauge on label).
const _UI_POLL_INTERVAL_S: float = 0.25
## States whose countdown labels need per-frame refresh; other UI uses combat signals.
const _TIMED_UI_STATES: Array[String] = [
	CombatConstants.STATE_WIND_UP,
	CombatConstants.STATE_MEDICAL_WIND_UP,
	CombatConstants.STATE_RECOVERING,
	CombatConstants.STATE_SWAP_RANK,
	CombatConstants.STATE_FALLING_BACK,
]
func _ready() -> void:
	# Processing will be enabled by start()
	set_process(false)

## Start battle. Optional p_player_formation and p_enemy_formation: { files, ranks, density, optional **`CombatConstants.FORMATION_PRESET_KEY_DOCTRINE`** or **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, optional **`CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS`**, —Â¦ }.
## When omitted, uses world meta "party_formation" / "enemy_formation" or defaults from count.
## Optional p_encounter: merged into **`CombatManager.encounter`** before **`manager.start()`** (same keys as **`CombatManager.start`** default_enc — doctrine, **`depth_polearm_ai_doctrine_mults_*`**, **`ENCOUNTER_KEY_FLEE_*`**, posture deltas, —Â¦). Preset dicts may set **`FORMATION_PRESET_KEY_FLEE_*`** rout overrides per side. If empty, reads **`parent_scene`** meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** when present (**`CombatFlow.start_combat`** can set it on the world).
func start(
	p_players,
	p_enemies,
	p_player_formation: Dictionary = {},
	p_enemy_formation: Dictionary = {},
	p_encounter: Dictionary = {}
) -> void:
	# Accept either a single Node or an Array of Nodes for each side
	if p_players == null:
		players = []
	elif p_players is Array:
		players = p_players.duplicate()
	else:
		players = [p_players]

	if p_enemies == null:
		enemies = []
	elif p_enemies is Array:
		enemies = p_enemies.duplicate()
	else:
		enemies = [p_enemies]

	# Hide the previous scene to prevent underlying UI from showing (Node has no visible; CanvasItem does)
	if parent_scene != null and "visible" in parent_scene:
		parent_scene.visible = false

	_diagram_refresh_sig = ""
	_create_ui()
	_update_ui()

	# setup combat manager
	var mgr_script = load(ResourcePaths.COMBAT_MANAGER)
	if mgr_script == null:
		push_error("BattleScene: failed to load CombatManager script")
		return
	manager = mgr_script.new()
	add_child(manager)
	# register combatants
	_player_list = get_node_or_null(BattleUIConstants.MAIN_LIST_PATH + "/PlayerStatsScroll/PlayerPanel/PlayerVBox/PlayerList")
	_enemy_list = get_node_or_null(BattleUIConstants.MAIN_LIST_PATH + "/EnemyStatsScroll/EnemyPanel/EnemyVBox/EnemyList")
	if _player_list == null or _enemy_list == null:
		push_error("BattleScene: missing PlayerList or EnemyList in UI tree — combatant rows will not render")
	for pl in players:
		var pid = manager.register(pl, CombatConstants.SIDE_PLAYER)
		CombatantRowBuilder.create_row(pid, pl, _player_list, id_to_controls)
	for en in enemies:
		var eid = manager.register(en, CombatConstants.SIDE_ENEMY)
		CombatantRowBuilder.create_row(eid, en, _enemy_list, id_to_controls)
	# Formation presets: use provided or default from count
	_player_preset = p_player_formation if not p_player_formation.is_empty() else _FormationPreset.default_for_count(players.size())
	_enemy_preset = p_enemy_formation if not p_enemy_formation.is_empty() else _FormationPreset.default_for_count(enemies.size())
	# Connect signals BEFORE manager.start() so turn_ready is never missed (robustness)
	manager.connect("turn_ready", Callable(self, "_on_turn_ready"))
	manager.connect("turn_resolved", Callable(self, "_on_turn_resolved"))
	manager.connect("action_resolved", Callable(self, "_on_action_resolved"))
	manager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	manager.connect("enemies_eliminated", Callable(self, "_on_enemies_eliminated"))
	manager.connect("combatant_health_changed", Callable(self, "_on_combatant_health_changed"))
	manager.connect("formation_changed", Callable(self, "_on_formation_changed"))
	manager.connect("engagement_state_changed", Callable(self, "_on_engagement_state_changed"))
	manager.connect("combat_ui_hint", Callable(self, "_on_combat_ui_hint"))
	var encounter_src: Dictionary = {}
	if not p_encounter.is_empty():
		encounter_src = p_encounter.duplicate(true)
	elif parent_scene != null and parent_scene.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		var em: Variant = parent_scene.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
		if em is Dictionary:
			encounter_src = (em as Dictionary).duplicate(true)
	if not encounter_src.is_empty():
		manager.encounter = encounter_src
	# Start manager (builds formations, assigns rank/file; merges encounter defaults)
	manager.start(_player_preset, _enemy_preset)
	if CombatConstants.DEBUG_BACK_RANK_DEPTH_POLEARM_LOADOUT:
		_apply_debug_depth_polearm_loadout(manager)
	# Creature stats: fixed registration order (rows stay in list order; no reparent on formation change).
	# Formation positions: FormationDiagramBuilder only.
	if formation_diagram_hbox != null:
		formation_diagram_enemy = _FormationDiagramBuilder.create(manager, _enemy_preset, CombatConstants.SIDE_ENEMY)
		formation_diagram_player = _FormationDiagramBuilder.create(manager, _player_preset, CombatConstants.SIDE_PLAYER)
		var player_col := VBoxContainer.new()
		player_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_player_engagement_label = Label.new()
		_player_engagement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_player_engagement_label.add_theme_font_size_override("font_size", 11)
		_player_engagement_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		player_col.add_child(_player_engagement_label)
		player_col.add_child(formation_diagram_player)
		formation_diagram_hbox.add_child(player_col)
		var sep = VSeparator.new()
		sep.custom_minimum_size = Vector2(12, 0)
		formation_diagram_hbox.add_child(sep)
		var enemy_col := VBoxContainer.new()
		enemy_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_enemy_engagement_label = Label.new()
		_enemy_engagement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_enemy_engagement_label.add_theme_font_size_override("font_size", 11)
		_enemy_engagement_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
		enemy_col.add_child(_enemy_engagement_label)
		enemy_col.add_child(formation_diagram_enemy)
		formation_diagram_hbox.add_child(enemy_col)
		_sync_engagement_labels_from_manager()
	# Ensure ScrollContainer child has proper minimum size so scrolling works (wait for layout)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_update_scroll_content_size()
	set_process(true)

func _update_scroll_content_size() -> void:
	var base := BattleUIConstants.MAIN_LIST_PATH
	var player_scroll: ScrollContainer = get_node_or_null(base + "/PlayerStatsScroll") as ScrollContainer
	var enemy_scroll: ScrollContainer = get_node_or_null(base + "/EnemyStatsScroll") as ScrollContainer
	var player_vbox: Control = get_node_or_null(base + "/PlayerStatsScroll/PlayerPanel/PlayerVBox") as Control
	var enemy_vbox: Control = get_node_or_null(base + "/EnemyStatsScroll/EnemyPanel/EnemyVBox") as Control
	if player_scroll == null or enemy_scroll == null or player_vbox == null or enemy_vbox == null:
		return
	_apply_stats_scroll_min_size(player_scroll, player_vbox, players.size())
	_apply_stats_scroll_min_size(enemy_scroll, enemy_vbox, enemies.size())


func _apply_stats_scroll_min_size(scroll: ScrollContainer, inner_vbox: Control, row_count: int) -> void:
	# ScrollContainer only shows scrollbar when child min size exceeds viewport.
	# get_combined_minimum_size() can be unreliable with nested containers, so we also
	# estimate from row count (each combatant row ~180px).
	var content_min := inner_vbox.get_combined_minimum_size()
	var estimated_height := row_count * 180
	var scroll_height := scroll.size.y
	if scroll_height <= 1.0:
		var p: Control = scroll.get_parent() as Control
		if p != null:
			scroll_height = p.size.y
	if scroll_height <= 1.0:
		scroll_height = 260.0
	var min_height := maxf(maxf(content_min.y, estimated_height), scroll_height + 1.0)
	inner_vbox.custom_minimum_size = Vector2(content_min.x, min_height)

## Tier 1.9 playtest: rank > 0 fighters get `SPEAR` (formation presets are unchanged).
func _apply_debug_depth_polearm_loadout(mgr: Node) -> void:
	if mgr == null:
		return
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.rank_int(c) <= 0:
			continue
		var n: Node = _EntityAccess.scene_node(c)
		if n == null or not n.has_method("equip_weapon"):
			continue
		var w: Weapon = _Weapon.create_from_definition("SPEAR")
		if w != null:
			n.call("equip_weapon", w)


func _create_ui() -> void:
	var layout = BattleUILayout.create(self)
	canvas_layer = layout.canvas_layer
	combat_log = layout.combat_log
	combat_log_scroll = layout.combat_log_scroll
	formation_diagram_hbox = layout.get("formation_diagram_hbox", null)

func _scroll_combat_log_to_bottom() -> void:
	if combat_log_scroll == null:
		return
	# Layout updates over multiple frames; scrollbar max_value is stale until layout settles.
	# Single defer is often insufficient (especially during medical phase when layout changes).
	# Use double defer so we scroll after the RichTextLabel's fit_content has propagated.
	call_deferred("_scroll_combat_log_to_bottom_deferred")

func _scroll_combat_log_to_bottom_deferred() -> void:
	if combat_log_scroll == null:
		return
	call_deferred("_do_scroll_combat_log_to_bottom")

func _do_scroll_combat_log_to_bottom() -> void:
	if combat_log_scroll == null:
		return
	var vbar = combat_log_scroll.get_v_scroll_bar()
	if vbar:
		combat_log_scroll.scroll_vertical = int(vbar.max_value)

## Builds the combatant snapshot once and refreshes rows. Returns the snapshot for reuse in the same frame.
func _update_ui() -> Array:
	if manager == null or not is_instance_valid(manager):
		return []
	var caps: Array = manager.get_combatants()
	for c in caps:
		var cid_ui: int = _EntityAccess.id_int(c)
		if cid_ui in id_to_controls:
			BattleUIUpdater.update_combatant_row(id_to_controls[cid_ui], c, manager)
	_sync_formation_diagrams_for_tactical_hints(caps)
	return caps


func _tactical_diagram_signature(caps: Array) -> String:
	var parts: PackedStringArray = []
	for raw in caps:
		if raw is not Dictionary:
			continue
		var c: Dictionary = raw
		if not _EntityAccess.is_on_battlefield(c):
			continue
		var chunks: PackedStringArray = []
		var stats: Dictionary = _EntityAccess.stats_dict(c)
		var hp_mille: int = int(roundf(_RowFormatter.total_body_health_ratio(stats) * 1000.0))
		var fn_mille: int = int(roundf(_RowFormatter.body_functionality_ratio(c, manager) * 1000.0))
		chunks.append("hp=%d" % hp_mille)
		chunks.append("fn=%d" % fn_mille)
		chunks.append("r=%d" % _EntityAccess.rank_int(c))
		chunks.append("f=%d" % _EntityAccess.file_int(c))
		var sfx: String = _UiHints.footwork_diagram_suffix(c).strip_edges()
		if not sfx.is_empty():
			chunks.append("sfx=%s" % sfx)
		var fw: String = _UiHints.footwork_hint_text(c)
		if not fw.is_empty():
			chunks.append("fw=%s" % fw)
		var attn: String = _UiHints.attention_hint_text(c)
		if not attn.is_empty():
			chunks.append("a=%s" % attn)
		var tempo: String = _UiHints.counter_tempo_hint_key(c, manager)
		if not tempo.is_empty():
			chunks.append("t=%s" % tempo)
		parts.append("%d:%s" % [_EntityAccess.id_int(c), "|".join(chunks)])
	parts.sort()
	return "|".join(parts)


func _sync_formation_diagrams_for_tactical_hints(caps: Array) -> void:
	var sig: String = _tactical_diagram_signature(caps)
	if sig == _diagram_refresh_sig:
		return
	_diagram_refresh_sig = sig
	if formation_diagram_player != null:
		_FormationDiagramBuilder.refresh(formation_diagram_player)
	if formation_diagram_enemy != null:
		_FormationDiagramBuilder.refresh(formation_diagram_enemy)

func _manager_needs_timer_ui_refresh() -> bool:
	if manager == null:
		return false
	for raw in manager.combatants:
		if raw is not Dictionary:
			continue
		var c: Dictionary = raw
		if not _EntityAccess.alive_bool(c, true):
			continue
		if _EntityAccess.state_str(c) in _TIMED_UI_STATES:
			return true
	return false


func _combat_manager_actively_simulating() -> bool:
	return manager != null and manager.is_processing()


func _sync_medical_phase_flag_from_manager() -> void:
	if manager != null and manager.medical_phase:
		_in_medical_phase = true


func _should_poll_ui_this_frame(delta: float) -> bool:
	_sync_medical_phase_flag_from_manager()
	if _in_medical_phase or _manager_needs_timer_ui_refresh():
		_ui_poll_accum = 0.0
		return true
	if not _combat_manager_actively_simulating():
		_ui_poll_accum = 0.0
		return false
	_ui_poll_accum += delta
	if _ui_poll_accum >= _UI_POLL_INTERVAL_S:
		_ui_poll_accum = 0.0
		return true
	return false


func _process(delta: float) -> void:
	if _end_battle_exit_in_progress:
		if _medical_exit_fast_forward_active and is_instance_valid(manager):
			_update_ui()
			_refresh_medical_fast_forward_exit_button()
		return
	_sync_medical_phase_flag_from_manager()
	var caps: Array = []
	if _should_poll_ui_this_frame(delta):
		caps = _update_ui()
	# Medical phase: contract battles can leave early (fast-forward sim); soak shows End battle once triage complete.
	if (
		_in_medical_phase
		and manager != null
		and is_instance_valid(manager)
		and not _end_battle_exit_in_progress
	):
		if _is_campaign_contract_battle():
			_ensure_campaign_medical_exit_button()
		elif _needs_medical_fast_forward_on_exit():
			_show_end_battle_button("End battle and finish triage", true, 280)
		elif manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase():
			_ensure_end_battle_button()
		# After medical actions are done and everyone is paused, announce status once per tier.
		var anyone_busy: bool = _winner_side_medical_busy(caps)
		if _is_campaign_contract_battle():
			if not anyone_busy:
				_announce_campaign_medical_status_log()
		elif not _medical_phase_finished_announced and not anyone_busy:
			_medical_phase_finished_announced = true
			if combat_log:
				combat_log.append_text(
					"\n[color=green]--- Medical phase finished. You may end the battle. ---[/color]\n"
				)
				_scroll_combat_log_to_bottom()

func _on_combatant_health_changed(_combatant_id: int) -> void:
	# Refresh UI when consciousness/pain/blood changes (driven by health_changed signal from entity)
	_update_ui()

func _on_formation_changed(_side: String) -> void:
	_diagram_refresh_sig = ""
	if formation_diagram_player != null:
		_FormationDiagramBuilder.refresh(formation_diagram_player)
	if formation_diagram_enemy != null:
		_FormationDiagramBuilder.refresh(formation_diagram_enemy)
	_update_ui()


func _on_engagement_state_changed(_formation_id: String, _line_cohesion: float, _engagement_posture: String) -> void:
	_sync_engagement_labels_from_manager()
	_update_ui()


func _sync_engagement_labels_from_manager() -> void:
	if manager == null:
		return
	if _enemy_engagement_label != null:
		_enemy_engagement_label.text = _format_engagement_line(
			_FormationSlots.formation_record_for_manager(manager, CombatConstants.SIDE_ENEMY), CombatConstants.SIDE_ENEMY
		)
	if _player_engagement_label != null:
		_player_engagement_label.text = _format_engagement_line(
			_FormationSlots.formation_record_for_manager(manager, CombatConstants.SIDE_PLAYER), CombatConstants.SIDE_PLAYER
		)
	_log_fp_diagram_banner_if_changed()


func _log_fp_diagram_banner_if_changed() -> void:
	if manager == null or not _OperationalLog.is_play_session_active():
		return
	var form: Dictionary = _FormationSlots.formation_record_for_manager(manager, CombatConstants.SIDE_PLAYER)
	if form.is_empty():
		return
	var player_line: String = _format_engagement_line(form, CombatConstants.SIDE_PLAYER)
	_F5SoakTrace.log_diagram_banner_player(player_line)
	var enemy_form: Dictionary = _FormationSlots.formation_record_for_manager(manager, CombatConstants.SIDE_ENEMY)
	if not enemy_form.is_empty() and manager.has_method("get_formation_doctrine"):
		var enemy_doc: String = str(manager.get_formation_doctrine(CombatConstants.SIDE_ENEMY)).strip_edges()
		if enemy_doc != CombatConstants.DOCTRINE_DEFAULT and not enemy_doc.is_empty():
			_F5SoakTrace.log_diagram_banner_enemy(_format_engagement_line(enemy_form, CombatConstants.SIDE_ENEMY))


func _format_engagement_line(form: Dictionary, formation_id: String) -> String:
	if form.is_empty():
		return "—"
	var mode_disp: String = "—"
	if manager != null:
		mode_disp = _EngagementMode.mode_display_name(_EngagementMode.engagement_mode(manager))
	var posture: String = str(form.get("engagement_posture", "—"))
	var coh: float = form.get("line_cohesion", 0.0)
	var line: String = "%s · %s · cohesion %d%%" % [mode_disp, posture.capitalize(), int(roundf(coh * 100.0))]
	if manager != null:
		var cas_pct: int = _FormationRout.casualty_percent_for_formation(manager, formation_id)
		if cas_pct > 0:
			line += " · %d%% casualties" % cas_pct
	if manager != null and manager.has_method("get_formation_doctrine"):
		var doc: String = str(manager.get_formation_doctrine(formation_id))
		if doc != CombatConstants.DOCTRINE_DEFAULT and not doc.is_empty():
			line += " · %s" % doc.replace("_", " ").capitalize()
	return line


func _on_combat_ui_hint(message: String) -> void:
	var m: String = message.strip_edges()
	if m.is_empty():
		return
	if combat_log == null:
		return
	combat_log.append_text("[color=#aab0c0]%s[/color]\n" % m)
	_scroll_combat_log_to_bottom()

func _on_turn_ready(combatant_id: int) -> void:
	_TurnReadyHandler.handle(manager, combatant_id)
	_update_ui()


func _on_turn_resolved(_combatant_id: int) -> void:
	_update_ui()

func _append_combat_log(attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary) -> void:
	if combat_log == null:
		return
	var line: String = CombatLogFormatter.format_action_line(attacker_name, attacker_side, target_name, target_side, result)
	combat_log.append_text(line + "\n")
	# Trim old lines (RichTextLabel doesn't have line limit; approximate by newline count)
	var text: String = combat_log.text
	var lines: PackedStringArray = text.split("\n")
	if lines.size() > BattleUIConstants.LOG_MAX_LINES:
		combat_log.text = "\n".join(lines.slice(-BattleUIConstants.LOG_MAX_LINES, lines.size()))
	_scroll_combat_log_to_bottom()

func _on_action_resolved(attacker_id: int, target_id: int, result: Dictionary) -> void:
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	var atk_name: String = _EntityAccess.get_display_name(atk, attacker_id)
	var atk_side: String = _EntityAccess.side_str(atk)
	var tgt_name: String = _EntityAccess.get_display_name(tgt, target_id)
	var tgt_side: String = _EntityAccess.side_str(tgt)
	_append_combat_log(atk_name, atk_side, tgt_name, tgt_side, result)
	var victim_id: int = CombatLogFormatter.action_resolved_victim_id(attacker_id, target_id, result)
	var victim: Dictionary = _EntityAccess.manager_get_combatant(manager, victim_id)
	if result.get(CombatConstants.RESULT_KEY_DIED, false) and parent_scene != null and _EntityAccess.is_on_side(victim, CombatConstants.SIDE_PLAYER):
		var killer_name: String = atk_name
		var killer_node: Node = _EntityAccess.scene_node(atk)
		if target_id >= 0:
			killer_name = atk_name
		else:
			killer_name = "—"
			killer_node = null
		var weapon: String = ""
		if killer_node != null:
			weapon = _EntityAccess.get_weapon_display_name_from_node(killer_node)
		var part_hit: String = result.get("part", "")
		_CampaignBridge.record_battle_kill(
			parent_scene,
			_EntityAccess.get_display_name(victim, victim_id),
			killer_name,
			weapon,
			part_hit
		)
	var row_id: int = CombatLogFormatter.last_hit_row_combatant_id(attacker_id, target_id, result)
	if row_id in id_to_controls and id_to_controls[row_id].get("last_hit_label"):
		var lbl: Label = id_to_controls[row_id].last_hit_label
		var row_hit: String = CombatLogFormatter.format_row_last_hit(result)
		if not row_hit.is_empty():
			lbl.text = row_hit
		elif result.get(CombatConstants.RESULT_KEY_DIED, false):
			lbl.text = "No targetable parts"
		elif result.get("outcome", "") not in ["parry_partial", "parry_deflect"]:
			lbl.text = ""
	_update_ui()

func _on_enemies_eliminated(winner_side: String) -> void:
	_pending_winner = winner_side
	_pending_defeated = null
	_in_medical_phase = true
	_medical_phase_finished_announced = false
	_campaign_medical_status_log = 0
	if not _OperationalLog.is_play_session_active():
		_CombatDebug.combat_session("enemies_eliminated medical phase started winner=%s" % winner_side)
	if combat_log:
		if _is_campaign_contract_battle():
			var can_end_now: bool = _campaign_medical_can_end()
			if can_end_now:
				_campaign_medical_status_log = 2
			combat_log.append_text(
				BattleUIConstants.campaign_medical_victory_log_line(can_end_now)
			)
		else:
			combat_log.append_text(
				"\n[color=orange]——— Enemies eliminated. Medical phase: dress all wounded (bandage/pack/TQ) before ending. ———[/color]\n"
			)
		_scroll_combat_log_to_bottom()
	_UiHints.emit_medical_phase_session_hints(manager, parent_scene)
	if _is_campaign_contract_battle():
		call_deferred("_ensure_campaign_medical_exit_button")

func _on_combat_ended(winner_side: String, defeated_node: Node) -> void:
	_pending_winner = winner_side
	_pending_defeated = defeated_node
	var def_name: String = str(defeated_node.name) if defeated_node != null else "null"
	if not _OperationalLog.is_play_session_active():
		_CombatDebug.combat_session("combat_ended winner=%s defeated=%s" % [winner_side, def_name])
	# Player medical-phase exit logs via finish_battle / campaign button — skip duplicate banner.
	if combat_log and not (winner_side == CombatConstants.SIDE_PLAYER and _in_medical_phase):
		combat_log.append_text("\n[color=yellow]——— Combat ended. Winner: %s ———[/color]\n" % winner_side)
		_scroll_combat_log_to_bottom()
	# Enemy won: show End battle immediately. Player won: handled by _on_enemies_eliminated (medical phase first).
	if winner_side == CombatConstants.SIDE_ENEMY:
		_show_end_battle_button()

func _is_campaign_contract_battle() -> bool:
	return _CompanyState.is_campaign_contract_battle_world(parent_scene)


func _winner_side_medical_busy(caps: Array) -> bool:
	return _MedicalPhase.winner_side_triage_busy(manager, caps)


func _announce_campaign_medical_status_log() -> void:
	if combat_log == null or manager == null:
		return
	var can_end: bool = _campaign_medical_can_end()
	if can_end and _campaign_medical_status_log < 2:
		combat_log.append_text(BattleUIConstants.CAMPAIGN_MEDICAL_FINISHED_LOG_LINE)
		_campaign_medical_status_log = 2
		_scroll_combat_log_to_bottom()
	elif not can_end and _campaign_medical_status_log < 1:
		combat_log.append_text(BattleUIConstants.CAMPAIGN_MEDICAL_IDLE_LOG_LINE)
		_campaign_medical_status_log = 1
		_scroll_combat_log_to_bottom()


func _campaign_medical_can_end() -> bool:
	return (
		manager != null
		and manager.has_method("can_end_medical_phase")
		and manager.can_end_medical_phase()
	)


func _needs_medical_fast_forward_on_exit() -> bool:
	return (
		manager != null
		and manager.medical_phase
		and manager.has_method("can_end_medical_phase")
		and not manager.can_end_medical_phase()
	)


func _ensure_campaign_medical_exit_button() -> void:
	if _end_battle_exit_in_progress:
		return
	if end_battle_button != null and end_battle_button.disabled:
		return
	var can_end: bool = _campaign_medical_can_end()
	var label: String = BattleUIConstants.campaign_medical_exit_button_label(can_end)
	var min_width: int = BattleUIConstants.campaign_medical_exit_button_min_width(can_end)
	if (
		end_battle_button != null
		and end_battle_button.text == label
		and int(end_battle_button.custom_minimum_size.x) == min_width
	):
		return
	# Pause live triage until click; campaign batch_resolve / soak tick-replay via finish_battle_interactive.
	_ensure_end_battle_button(label, true, min_width)


func _ensure_end_battle_button(
	button_text: String = "End battle",
	pause_manager: bool = true,
	button_min_width: int = 160
) -> void:
	if _content_vbox == null:
		_content_vbox = get_node_or_null("CombatCanvasLayer/UIRoot/ContentVBox")
	if _content_vbox == null:
		return
	if end_battle_button != null:
		var label_changed: bool = end_battle_button.text != button_text
		if label_changed:
			end_battle_button.text = button_text
		end_battle_button.custom_minimum_size = Vector2(button_min_width, 44)
		if label_changed:
			call_deferred("_scroll_combat_log_to_bottom")
		return
	if not _OperationalLog.is_play_session_active():
		_CombatDebug.combat_session("showing battle exit button label=%s pause=%s" % [button_text, pause_manager])
	if pause_manager and manager != null:
		manager.set_process(false)
	end_battle_button = Button.new()
	end_battle_button.name = "EndBattleButton"
	end_battle_button.text = button_text
	end_battle_button.custom_minimum_size = Vector2(button_min_width, 44)
	end_battle_button.pressed.connect(_on_end_battle_button_pressed)
	_content_vbox.add_child(end_battle_button)
	# Button changes layout; scroll again after layout settles so "Combat ended" stays visible
	call_deferred("_scroll_combat_log_to_bottom")


func _show_end_battle_button(
	button_text: String = "End battle",
	pause_manager: bool = true,
	button_min_width: int = 160
) -> void:
	_ensure_end_battle_button(button_text, pause_manager, button_min_width)


func _refresh_medical_fast_forward_exit_button() -> void:
	if end_battle_button == null or manager == null or not is_instance_valid(manager):
		return
	var parts_left: int = _MedicalPhase.winner_side_untreated_part_count(manager)
	end_battle_button.text = BattleUIConstants.medical_exit_button_label_finishing(
		_is_campaign_contract_battle(),
		parts_left
	)


func _on_end_battle_button_pressed() -> void:
	if _end_battle_exit_in_progress:
		return
	_end_battle_exit_in_progress = true
	var needs_fast_forward: bool = _needs_medical_fast_forward_on_exit()
	_medical_exit_fast_forward_active = needs_fast_forward
	if end_battle_button != null:
		end_battle_button.disabled = true
		if needs_fast_forward:
			_refresh_medical_fast_forward_exit_button()
			end_battle_button.custom_minimum_size = Vector2(
				BattleUIConstants.campaign_medical_exit_button_finishing_min_width(),
				44
			)
	if needs_fast_forward:
		if combat_log != null:
			combat_log.append_text(
				BattleUIConstants.medical_exit_processing_log_line(_is_campaign_contract_battle())
			)
			_scroll_combat_log_to_bottom()
		if is_inside_tree():
			await get_tree().process_frame
	if is_instance_valid(manager):
		manager.set_process(false)
		if manager.medical_phase and manager.has_method("finish_battle_interactive"):
			await manager.finish_battle_interactive()
			if not is_instance_valid(manager):
				return
		elif manager.medical_phase and manager.has_method("finish_battle"):
			manager.finish_battle()
		_sync_pending_winner_from_manager()
	_medical_exit_fast_forward_active = false
	if not is_inside_tree():
		return
	emit_signal("battle_ended", _pending_winner, _pending_defeated)
	queue_free()


func _sync_pending_winner_from_manager() -> void:
	if manager == null or not is_instance_valid(manager):
		return
	var winner: String = str(manager.medical_phase_winner).strip_edges()
	if winner.is_empty() and manager.medical_phase:
		winner = CombatConstants.SIDE_PLAYER
	if not winner.is_empty():
		_pending_winner = winner

func _exit_tree() -> void:
	if is_instance_valid(manager):
		manager.disconnect("turn_ready", Callable(self, "_on_turn_ready"))
		manager.disconnect("turn_resolved", Callable(self, "_on_turn_resolved"))
		manager.disconnect("action_resolved", Callable(self, "_on_action_resolved"))
		manager.disconnect("combat_ended", Callable(self, "_on_combat_ended"))
		manager.disconnect("enemies_eliminated", Callable(self, "_on_enemies_eliminated"))
		manager.disconnect("combatant_health_changed", Callable(self, "_on_combatant_health_changed"))
		manager.disconnect("formation_changed", Callable(self, "_on_formation_changed"))
		manager.disconnect("engagement_state_changed", Callable(self, "_on_engagement_state_changed"))
		manager.disconnect("combat_ui_hint", Callable(self, "_on_combat_ui_hint"))
	# Restore visibility of the parent scene when this battle UI is removed
	if parent_scene != null:
		parent_scene.visible = true
                                                                                                