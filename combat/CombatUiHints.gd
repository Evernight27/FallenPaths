class_name CombatUiHints
extends RefCounted

## Shared UI hint resolution for snapshot rows and live combatant dicts.
## Gauge suffix order (footing): Step (PA) → Grd/Atk (guard line) → Form — **`BattleUIUpdater._compose_waiting_gauge_label`**. LIVE_PATHS **`#battle-ui`** · **`#wf-1c--ui-surfacing`** · **`#wf-tier-44-pa`** (Step) · soak **`#wf-soak-audit-status`**.
## **`active_line_for_ui`**: wind-up → **`pending_attack`** line; else **`guard_line`** — does **not** read **`weapon_form`** or PA offset.
## Diagram: guard **`[short]`** then form **`[Ox]`** — **`FormationDiagramBuilder._cell_label_with_footwork`**. LIVE_PATHS **`#wf-footing-guards-stances`** · **`#wf-guard-writers`** (L3 drift).
## **Camp-3.3:** one-shot medical-phase combat-log hints — **once per play session** when
## `world` meta is set (campaign fights); **once per fight** on `manager` when no world node.

const WORLD_META_MEDICAL_PHASE_HINTS_SHOWN := "fp_medical_phase_hints_shown"
const _META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT := "_fp_medical_phase_hints_shown_fight"
const _META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT := "_fp_campaign_medical_exit_hint_shown_fight"

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _CompanyState := preload("res://world/CompanyState.gd")


static func any_tactical_features_enabled() -> bool:
	return _Footwork.enabled() or _Attention.enabled() or _CounterTempo.enabled() or _FlurryBind.enabled()


static func medical_phase_active(manager: Node) -> bool:
	return manager != null and bool(manager.medical_phase)


static func medical_phase_hints_already_shown(manager: Node, world: Node = null) -> bool:
	if world != null and world.has_meta(WORLD_META_MEDICAL_PHASE_HINTS_SHOWN):
		return bool(world.get_meta(WORLD_META_MEDICAL_PHASE_HINTS_SHOWN))
	if manager != null and manager.has_meta(_META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT):
		return bool(manager.get_meta(_META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT))
	return false


static func mark_medical_phase_hints_shown(manager: Node, world: Node = null) -> void:
	if world != null:
		world.set_meta(WORLD_META_MEDICAL_PHASE_HINTS_SHOWN, true)
	elif manager != null:
		manager.set_meta(_META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT, true)


## One-shot combat-log copy when medical phase begins (Camp-3.3).
static func medical_phase_combat_log_hints() -> PackedStringArray:
	return PackedStringArray([
		(
			"Medical phase — your side triages only; defeated opponents cannot strike or act."
		),
		(
			"Triage priority: hold direct pressure on active bleeds (especially arterial), "
			+ "then bandage or pack "
			+ "(battle bandages are free; pack/stabilize cost −1 company med each)."
		),
		(
			"Allies choose medical actions automatically — gauge may show Stack medical or "
			+ "self_medical when triage is urgent."
		),
		(
			"Stabilize (−1 med) slows bleeding but does not dress the wound — bandage, pack, or "
			+ "tourniquet still required before camp rest or marching."
		),
	])


static func _campaign_medical_exit_hint_shown_this_fight(manager: Node) -> bool:
	return (
		manager != null
		and manager.has_meta(_META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT)
		and bool(manager.get_meta(_META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT))
	)


static func _mark_campaign_medical_exit_hint_shown(manager: Node) -> void:
	if manager != null:
		manager.set_meta(_META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT, true)


## Emit session/fight one-shot hints via **`manager.notify_combat_ui_hint`** (BattleScene hook).
static func emit_medical_phase_session_hints(manager: Node, world: Node = null) -> void:
	if not medical_phase_active(manager) or not manager.has_method("notify_combat_ui_hint"):
		return
	var emit_general: bool = not medical_phase_hints_already_shown(manager, world)
	if emit_general:
		mark_medical_phase_hints_shown(manager, world)
		for line in medical_phase_combat_log_hints():
			# Combat log only — FP uses `note_medical_phase_intro` + `medical_action pick`.
			manager.notify_combat_ui_hint(line, false)
	if world != null:
		var supply_hint: String = _CompanyState.format_battle_medical_supply_hint(world)
		if (
			not supply_hint.is_empty()
			and (
				emit_general
				or _CompanyState.is_campaign_contract_battle_world(world)
			)
		):
			manager.notify_combat_ui_hint(supply_hint, false)
	if (
		world != null
		and _CompanyState.is_campaign_contract_battle_world(world)
		and not _campaign_medical_exit_hint_shown_this_fight(manager)
	):
		_mark_campaign_medical_exit_hint_shown(manager)
		var triage_ready: bool = (
			manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase()
		)
		var exit_hint: String = (
			_BattleUIConstants.CAMPAIGN_MEDICAL_EARLY_EXIT_HINT_READY
			if triage_ready
			else _BattleUIConstants.CAMPAIGN_MEDICAL_EARLY_EXIT_HINT
		)
		manager.notify_combat_ui_hint(exit_hint, false)


static func medical_phase_context_tooltip_lines(manager: Node, world: Node = null) -> PackedStringArray:
	if not medical_phase_active(manager):
		return PackedStringArray()
	var winner: String = str(manager.medical_phase_winner).strip_edges()
	var lines: PackedStringArray = []
	var resolved_world: Node = world if world != null else _CompanyState.resolve_world_from_battle(manager)
	var campaign_contract: bool = _CompanyState.is_campaign_contract_battle_world(resolved_world)
	if winner.is_empty():
		lines.append(
			"Medical phase — triage wounded allies before returning to camp."
			if campaign_contract
			else "Medical phase — triage wounded allies before ending the battle."
		)
	else:
		lines.append(
			"Medical phase — %s side triages only; opponents cannot strike."
			% winner
		)
	lines.append(
		"Priority: direct pressure, then bandage/pack/TQ. Battle bandages are free; stabilize costs 1 med."
	)
	if campaign_contract:
		var triage_ready: bool = (
			manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase()
		)
		lines.append(
			_BattleUIConstants.CAMPAIGN_MEDICAL_TOOLTIP_EXIT_READY
			if triage_ready
			else _BattleUIConstants.CAMPAIGN_MEDICAL_TOOLTIP_EXIT_PENDING
		)
	return lines


static func medical_wind_up_gauge_primary_label(c: Dictionary, remain: float) -> String:
	var pm: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_medical")
	var mid: String = str(pm.get("medical_id", "")).strip_edges()
	var self_id: int = _EntityAccess.id_int(c)
	var tgt_cid: int = int(pm.get("target_combatant_id", self_id))
	var med_label: String = (
		_BattleUIConstants.MEDICAL_ACTION_LABELS_ALLY.get(
			mid, _BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
		)
		if tgt_cid != self_id
		else _BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
	)
	return "%s %.1fs" % [med_label, remain]


static func medical_busy_row_tooltip_line(c: Dictionary) -> String:
	var st: String = _EntityAccess.state_str(c)
	if st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
		return "Receiving care — another combatant is treating this wound."
	if st == CombatConstants.STATE_MEDICAL_WIND_UP:
		return "Medical wind-up — hold until the procedure completes."
	return ""


static func _first_exported_hint(c: Dictionary, keys: Array) -> String:
	for key in keys:
		var s: String = str(c.get(key, "")).strip_edges()
		if not s.is_empty():
			return s
	return ""


## Tier 4.4 PA gauge text — from live offset when flag on; exported row key when off. LIVE_PATHS **`#wf-tier-44-pa`** (UI phase) · **`#battle-ui`**.
static func footwork_hint_text(c: Dictionary) -> String:
	if not _Footwork.enabled():
		return str(c.get("position_angle_ui_hint", "")).strip_edges()
	return _Footwork.get_ui_hint(c)


## Formation diagram cell suffix (empty — offset is not shown on the diagram); gauge via **`footwork_hint_text`**.
static func footwork_diagram_suffix(c: Dictionary) -> String:
	if c == null:
		return ""
	var exported: String = str(c.get("position_angle_ui_hint", "")).strip_edges()
	if not _Footwork.enabled():
		if exported.is_empty():
			return ""
		return (" · " + exported) if not exported.begins_with(" · ") else exported
	return _Footwork.get_diagram_label_suffix(c)


## Gauge **` · Step`** suffix from Tier 4.4 PA — **`#battle-ui`** · **`#wf-tier-44-pa`** (display only).
static func footwork_hint_suffix(c: Dictionary) -> String:
	var hint: String = footwork_hint_text(c)
	return (" · " + hint) if not hint.is_empty() else ""


static func attention_hint_text(c: Dictionary, manager: Node = null) -> String:
	if c.is_empty():
		return ""
	if not _Attention.enabled():
		return _first_exported_hint(
			c, ["attention_ui_hint", CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT]
		)
	if manager != null:
		return _Attention.live_ui_hint(manager, c)
	var exported: String = _first_exported_hint(
		c, ["attention_ui_hint", CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT]
	)
	if not exported.is_empty():
		return exported
	return _Attention.snapshot_ui_hint(c)


## Snapshot row keys + live derive when **`manager`** set (see **`CounterTempo.snapshot_ui_hint`**).
static func counter_tempo_hint_key(c: Dictionary, manager: Node = null) -> String:
	if c == null or c.is_empty():
		return ""
	var row: String = _first_exported_hint(
		c, ["counter_tempo_ui_hint", CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT]
	)
	if not _CounterTempo.enabled():
		return row
	if manager != null:
		var live: String = _CounterTempo.snapshot_ui_hint(manager, c)
		return live if not live.is_empty() else row
	return row


## Empty unless **`STATE_COWERING`** (Tier **6.1** mobility).
static func cowering_mobility_tooltip_line(c: Dictionary) -> String:
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		return ""
	if _EntityAccess.can_flee_or_fall_back(c):
		return "No arms — may fall back when rear rank in your file is clear."
	if not _EntityAccess.is_unconscious(c):
		return "No arms — holding position (fall back blocked)."
	return ""


static func flurry_bind_gauge_label(c: Dictionary, manager: Node = null) -> String:
	if not _FlurryBind.enabled() or manager == null or c.is_empty():
		return ""
	var clk: float = _EntityAccess.combat_clock_float(manager)
	if not _FlurryBind.is_active(c, clk):
		return ""
	return "Bind exchange"


static func flurry_bind_hint_suffix(c: Dictionary, manager: Node = null) -> String:
	var label: String = flurry_bind_gauge_label(c, manager)
	return (" · " + label) if not label.is_empty() else ""


static func exhaustion_hint_suffix(c: Dictionary) -> String:
	return _Exhaustion.gauge_hint_suffix(c)


static func _guard_line_ui_states() -> Array:
	return [
		CombatConstants.STATE_WAITING,
		CombatConstants.STATE_WIND_UP,
		CombatConstants.STATE_RECOVERING,
		CombatConstants.STATE_COWERING,
	]


## L3 moment line for gauge/diagram — wind-up → **`pending_attack`** line; else **`guard_line`**. Does **not** read **`weapon_form`** or PA offset. LIVE_PATHS **`#wf-guard-writers`** · **`#battle-ui`**.
static func active_line_for_ui(c: Dictionary) -> String:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled() or c.is_empty():
		return ""
	var st: String = _EntityAccess.state_str(c)
	if st not in _guard_line_ui_states():
		return ""
	if st == CombatConstants.STATE_WIND_UP:
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
		var attack_line: String = str(pa.get("attack_line", "")).strip_edges()
		if not attack_line.is_empty():
			return attack_line
		var move_id: String = str(pa.get("attack_type", pa.get("move_id", ""))).strip_edges()
		if not move_id.is_empty():
			var move_def: Dictionary = _WeaponConstants.get_move(move_id)
			return str(move_def.get("attack_line", "")).strip_edges()
		return ""
	return str(c.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()


## Gauge **` · Grd`** / **` · Atk`** suffix from **`active_line_for_ui`**. LIVE_PATHS **`#battle-ui`** · soak content asserts open **`#wf-soak-audit-status`**.
static func guard_line_gauge_suffix(c: Dictionary) -> String:
	var line: String = active_line_for_ui(c)
	if line.is_empty():
		return ""
	var short: String = _GuardLines.display_short_for_line(line)
	if short.is_empty():
		return ""
	var prefix: String = (
		"Atk" if _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP else "Grd"
	)
	return " · %s %s" % [prefix, short]


static func guard_line_diagram_suffix(c: Dictionary) -> String:
	var line: String = active_line_for_ui(c)
	if line.is_empty():
		return ""
	var short: String = _GuardLines.display_short_for_line(line)
	if short.is_empty():
		return ""
	return " [%s]" % short


static func guard_line_tooltip_line(c: Dictionary) -> String:
	var line: String = active_line_for_ui(c)
	if line.is_empty():
		return ""
	var long_label: String = _GuardLines.display_long_for_line(line)
	if _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
		return "Attack line: %s" % long_label
	return "Guard: %s" % long_label


## Gauge **` · Form {name}`** from **`form_str`** — independent of **`guard_line`** drift. LIVE_PATHS **`#battle-ui`** · **`#wf-1c--ui-surfacing`** · soak **`#wf-soak-audit-status`** (ii5c open).
static func weapon_form_gauge_suffix(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	var name: String = _WeaponForm.display_name(_EntityAccess.form_str(c))
	if name.is_empty():
		return ""
	return " · Form %s" % name


## Diagram **`[Ox]`** suffix from **`form_str`** — after guard short in **`FormationDiagramBuilder`**. LIVE_PATHS **`#battle-ui`**.
static func weapon_form_diagram_suffix(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	var name: String = _WeaponForm.display_name(_EntityAccess.form_str(c))
	if name.is_empty():
		return ""
	return " [%s]" % name


static func weapon_form_tooltip_line(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	var form: String = _EntityAccess.form_str(c)
	var name: String = _WeaponForm.display_name(form)
	if name.is_empty():
		return ""
	var pressure: String = _WeaponForm.pressure_class_label_for_ui(c)
	if pressure.is_empty():
		return "Form: %s" % name
	return "Form: %s (%s)" % [name, pressure]


## Short label fragment for listed **`attempt_close`** vs a controlling defender.
static func close_attempt_list_hint_for_defender(defender: Dictionary) -> String:
	if defender.is_empty():
		return ""
	if not _WeaponForm.controlling_pressure_active(defender):
		return ""
	var form: String = _EntityAccess.form_str(defender)
	var fname: String = _WeaponForm.display_name(form)
	if fname.is_empty():
		return "controlling defender"
	return "%s (controlling)" % fname


## Player turn hint when **`attempt_close`** is listed vs a controlling defender (Fool / space-holding form).
static func controlling_defender_close_hint_line(
	manager: Node, c: Dictionary, actions: Array
) -> String:
	if manager == null or c.is_empty() or actions.is_empty():
		return ""
	if not _EntityAccess.is_player_side(c):
		return ""
	for raw in actions:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			continue
		var tid: int = int(a.get("target_id", -1))
		if tid < 0:
			continue
		var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
		if tgt.is_empty():
			continue
		var tag: String = close_attempt_list_hint_for_defender(tgt)
		if tag.is_empty():
			continue
		return (
			"Close is harder vs %s — strike from range or commit with strength."
			% tag.replace(" (controlling)", "")
		)
	return ""


static func surround_arc_occupancy_tooltip_line(c: Dictionary, manager: Node = null) -> String:
	if manager == null or c.is_empty():
		return ""
	if not CombatConstants.is_feature_surround_arc_occupancy_enabled():
		return ""
	var blocked: int = _TacticalCombat.arc_occupancy_blocked_for_defender(manager, c)
	if blocked <= 0:
		return ""
	return (
		"Arc overlap: %d threat(s) share your front sector (reduced surround weight)."
		% blocked
	)


static func counter_tempo_gauge_label(tempo_hint: String) -> String:
	if tempo_hint.is_empty():
		return ""
	if tempo_hint == "counter_ready":
		return "Counter!"
	if tempo_hint == "counter_winding":
		return "Seize tempo…"
	return ""


## Export stamped hint fields on a **`CombatCombatantsSnapshot`** row from live **`c`**.
static func stamp_snapshot_hint_fields(item: Dictionary, c: Dictionary, manager: Node) -> void:
	if _Footwork.enabled() and _Footwork.offset_visible_for_ui_state(c):
		var off_deg: float = _Footwork.get_defender_offset_deg(c)
		if absf(off_deg) >= 0.01:
			item["position_angle_offset_deg"] = off_deg
		var fw_hint: String = footwork_hint_text(c)
		if not fw_hint.is_empty():
			item["position_angle_ui_hint"] = fw_hint
	if _Attention.enabled():
		var attn_hint: String = _first_exported_hint(
			c, [CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, "attention_ui_hint"]
		)
		if attn_hint.is_empty():
			attn_hint = attention_hint_text(c, manager)
		if not attn_hint.is_empty():
			item["attention_ui_hint"] = attn_hint
	if _CounterTempo.enabled() and manager != null:
		var tempo_hint: String = counter_tempo_hint_key(c, manager)
		if not tempo_hint.is_empty():
			item["counter_tempo_ui_hint"] = tempo_hint


## Waiting tick: salience + yomi + attention UI stamp (see **`CombatAttention.refresh_for_waiting_tick`**).
static func refresh_waiting_tick_stamps(manager: Node, c: Dictionary) -> void:
	if manager == null or c == null or not _Attention.enabled():
		return
	_Attention.refresh_for_waiting_tick(manager, c)


static func gauge_tooltip_lines(c: Dictionary, manager: Node = null) -> PackedStringArray:
	var tips: PackedStringArray = []
	var st0: String = _EntityAccess.state_str(c)
	if st0 in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
		var ratio_pct: int = int(roundf(_EntityAccess.stamina_ratio(c) * 100.0))
		var cap_pct: int = int(roundf(_Exhaustion.effective_stamina_max(c)))
		tips.append(
			"Stamina %d%% of %d burst max — progress bar (label shows Stm when waiting)."
			% [ratio_pct, cap_pct]
		)
		var gauge_pct: int = int(roundf(_EntityAccess.gauge_float(c)))
		if gauge_pct >= 100:
			tips.append("Turn ready — action selection allowed for this combatant.")
		elif gauge_pct > 0:
			tips.append("Readiness %d%% — turn / counter-tempo gauge (label only)." % gauge_pct)
	var fw: String = footwork_hint_text(c)
	if not fw.is_empty():
		tips.append("Arc footwork (position-angle step): %s" % fw)
	var attn: String = attention_hint_text(c, manager)
	if not attn.is_empty():
		tips.append("Attention: %s" % attn)
	var tempo: String = counter_tempo_hint_key(c, manager)
	if tempo == "counter_ready":
		tips.append("Counter window open — seize tempo.")
	elif tempo == "counter_winding":
		tips.append("Incoming wind-up — counter window building.")
	if bool(c.get("is_counter_tempo_wind_up", false)):
		tips.append("Counter-tempo riposte — shortened wind-up.")
	if _FlurryBind.enabled() and manager != null and _FlurryBind.is_active(c, _EntityAccess.combat_clock_float(manager)):
		var left: int = int(c.get("flurry_exchanges_left", 0))
		tips.append(
			"Bind exchange — faster blows vs bound opponent (%d exchange(s) left)."
			% maxi(0, left)
		)
	var cow: String = cowering_mobility_tooltip_line(c)
	if not cow.is_empty():
		tips.append(cow)
	if manager != null:
		var rout: String = _FormationRout.rout_pressure_tooltip_line(manager, c)
		if not rout.is_empty():
			tips.append(rout)
	var fm: String = _FormationMoveDuration.formation_preview_tooltip_line(manager, c)
	if not fm.is_empty():
		tips.append(fm)
	var cap_tip: String = _Exhaustion.stamina_cap_tooltip_line(c)
	if not cap_tip.is_empty() and st0 not in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
		tips.append(cap_tip)
	var exh: String = _Exhaustion.gauge_tooltip_line(c)
	if not exh.is_empty():
		tips.append(exh)
	var arc_sur: String = surround_arc_occupancy_tooltip_line(c, manager)
	if not arc_sur.is_empty():
		tips.append(arc_sur)
	var grd: String = guard_line_tooltip_line(c)
	if not grd.is_empty():
		tips.append(grd)
	var wf: String = weapon_form_tooltip_line(c)
	if not wf.is_empty():
		tips.append(wf)
	var st: String = _EntityAccess.state_str(c)
	if manager != null and medical_phase_active(manager):
		for mp_line in medical_phase_context_tooltip_lines(manager):
			tips.append(mp_line)
		var busy_line: String = medical_busy_row_tooltip_line(c)
		if not busy_line.is_empty():
			tips.append(busy_line)
	if st in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
		var listed_fm: String = str(
			c.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")
		).strip_edges()
		if not listed_fm.is_empty():
			tips.append(listed_fm)
		var hold_line: String = str(
			c.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")
		).strip_edges()
		if not hold_line.is_empty():
			tips.append(hold_line)
		var close_ctrl: String = str(
			c.get(CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT, "")
		).strip_edges()
		if not close_ctrl.is_empty():
			tips.append(close_ctrl)
	if st in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
		tips.append(
			"Formation move — heavy hits (intensity ≥ %.0f) may cancel; lighter hits extend duration."
			% CombatConstants.FORMATION_HIT_CANCEL_INTENSITY
		)
	return tips


static func formation_cell_tooltip_lines(
	c: Dictionary, display_name: String, manager: Node = null
) -> PackedStringArray:
	var lines: PackedStringArray = []
	var fw: String = footwork_hint_text(c)
	if not fw.is_empty():
		lines.append("%s — footwork: %s" % [display_name, fw])
	var attn: String = attention_hint_text(c, manager)
	if not attn.is_empty():
		lines.append("%s — attention: %s" % [display_name, attn])
	var tempo: String = counter_tempo_hint_key(c, manager)
	if tempo == "counter_ready":
		lines.append("%s — counter window open" % display_name)
	elif tempo == "counter_winding":
		lines.append("%s — counter window building" % display_name)
	var cow: String = cowering_mobility_tooltip_line(c)
	if not cow.is_empty():
		lines.append("%s — %s" % [display_name, cow])
	var fm: String = _FormationMoveDuration.formation_preview_tooltip_line(manager, c)
	if not fm.is_empty():
		lines.append("%s — %s" % [display_name, fm])
	var grd: String = guard_line_tooltip_line(c)
	if not grd.is_empty():
		lines.append("%s — %s" % [display_name, grd])
	var wf: String = weapon_form_tooltip_line(c)
	if not wf.is_empty():
		lines.append("%s — %s" % [display_name, wf])
	return lines
