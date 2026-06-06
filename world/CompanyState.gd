class_name CompanyState
extends RefCounted

## World-persistent company economy (session meta only — no disk save in EA).
## Camp-1.1–1.2: economy + HUD · Camp-1.3–1.6: supplies, contracts, camp heal.
## Canonical: `is_tutorial_contract` · `defeat_should_end_company_run` · `try_camp_heal` · `gate_*`.

const _CompanyHud := preload("res://ui/CompanyHud.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")

const DEFAULT_CAMP_TILE := Vector2i(0, 0)

# World meta keys (§10)
const WORLD_META_COMPANY_STATE := "company_state"
const WORLD_META_ACTIVE_CONTRACT := "active_contract"
const WORLD_META_LAST_BATTLE_SUMMARY := "last_battle_summary"
const WORLD_META_BATTLE_KILL_LOG := "campaign_battle_kill_log"
const WORLD_META_COMPANY_HUD := "company_hud"

# §12 EA tuning defaults (not decision stubs)
const DEFAULT_GOLD := 500
const DEFAULT_WAGE_PER_MEMBER := 15
## EA 7v7: ~1 med per dressed part + camp rest; heavy fights can leave 15+ parts — tune with contract resupply.
const DEFAULT_MEDICAL_SUPPLIES := 15
const CONTRACT_VICTORY_MED_RESUPPLY := 4
const DEFAULT_TOOL_SUPPLIES := 2
const DEFAULT_RENOWN := 0
const DEFAULT_DAY_INDEX := 0

# Closed gates (2026-05-22 decision log)
const DAY_TICK_MODE := "hybrid"
const STEPS_PER_DAY := 5
const ENCOUNTER_LIFECYCLE := "r3_loss_ends_run"
const CAMP_HEAL_ENTRY := "both"
const CAMP_HEAL_SECONDS := 600.0
const CAMP_HEAL_MULTIPLIER := 3.0
const CASUALTY_ON_SETTLEMENT := "memorial_then_remove"
const MAP_BLEED_POLICY := "warn_eta"
const WORLD_META_MAP_BLEED_MULT := "campaign_map_bleed_mult"
const MED_BATTLE_MODE := "hybrid"
const SUPPLY_FACTOR_AT_ZERO_MED := 0.5
const AFFLICTIONS_ENABLED := true
const BANKRUPT_MODE := "desertion"
const PERSISTENCE_MODE := "P1"  # D-persistence: session-only EA; P2 = disk autosave

const RENOWN_PAY_SCALE := 0.05

const MOOD_DEFAULT := 50.0
const MOOD_ANGRY_THRESHOLD := 15.0
const MOOD_DESERTION_CHANCE := 0.05
const MOOD_BATTLE_WON_DELTA := 0.35
const MOOD_BATTLE_LOST_DELTA := -0.45
const MOOD_DEATH_WITNESS_DELTA := -0.25
const WORLD_META_CAMPAIGN_MED_BATTLE := "campaign_med_battle"

# Harness / legacy readers
static func read_stub_day_tick_mode() -> String:
	return DAY_TICK_MODE


static func read_stub_steps_per_day() -> int:
	return STEPS_PER_DAY


static func read_stub_encounter_lifecycle() -> String:
	return ENCOUNTER_LIFECYCLE


static func read_stub_camp_heal_entry() -> String:
	return CAMP_HEAL_ENTRY


static func read_stub_camp_heal_seconds() -> float:
	return CAMP_HEAL_SECONDS


static func read_stub_casualty_on_settlement() -> String:
	return CASUALTY_ON_SETTLEMENT


static func read_stub_map_bleed_policy() -> String:
	return MAP_BLEED_POLICY


## Camp-2.1 / Camp-3.1: persisted **first campaign win** — lifts map bleed block (`MapBleedPolicy` → `warn_eta`).
static func is_tutorial_completed(world: Node) -> bool:
	return bool(get_state(world).get("tutorial_completed", false))


static func mark_tutorial_completed(world: Node) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["tutorial_completed"] = true
	_write_state(world, state)


static func is_tutorial_contract(contract: Dictionary) -> bool:
	if contract.is_empty():
		return false
	if bool(contract.get("tutorial", false)):
		return true
	return str(contract.get("contract_type", "")) == "tutorial"


static func set_map_bleed_mult(world: Node, mult: float) -> void:
	if world == null:
		return
	world.set_meta(WORLD_META_MAP_BLEED_MULT, clampf(mult, 0.05, 1.0))


static func get_map_bleed_mult(world: Node) -> float:
	if world == null or not world.has_meta(WORLD_META_MAP_BLEED_MULT):
		return 1.0
	return clampf(float(world.get_meta(WORLD_META_MAP_BLEED_MULT, 1.0)), 0.05, 1.0)


static func read_stub_med_battle_mode() -> String:
	return MED_BATTLE_MODE


static func read_stub_supply_factor_at_zero_med() -> float:
	return SUPPLY_FACTOR_AT_ZERO_MED


static func read_stub_afflictions_enabled() -> bool:
	return AFFLICTIONS_ENABLED


static func read_stub_bankrupt_mode() -> String:
	return BANKRUPT_MODE


static func read_stub_persistence_mode() -> String:
	return PERSISTENCE_MODE


static func attach_to_world(world: Node2D) -> void:
	if world == null:
		return
	if not world.has_meta(WORLD_META_COMPANY_STATE):
		init_from_defaults(world)
	_ensure_hud_on_world(world)
	refresh_hud(world)


static func init_from_defaults(world: Node2D) -> void:
	if world == null:
		return
	world.set_meta(WORLD_META_COMPANY_STATE, _default_state_dict())


static func _default_state_dict() -> Dictionary:
	return {
		"gold": DEFAULT_GOLD,
		"wage_per_member": DEFAULT_WAGE_PER_MEMBER,
		"medical_supplies": DEFAULT_MEDICAL_SUPPLIES,
		"tool_supplies": DEFAULT_TOOL_SUPPLIES,
		"renown": DEFAULT_RENOWN,
		"day_index": DEFAULT_DAY_INDEX,
		"bankrupt": false,
		"overworld_step_count": 0,
		"contract_deck_index": 0,
		"tutorial_completed": false,
	}


static func get_state(world: Node) -> Dictionary:
	if world == null or not world.has_meta(WORLD_META_COMPANY_STATE):
		return {}
	var raw: Variant = world.get_meta(WORLD_META_COMPANY_STATE)
	return raw if raw is Dictionary else {}


static func _write_state(world: Node, state: Dictionary) -> void:
	if world == null:
		return
	world.set_meta(WORLD_META_COMPANY_STATE, state)
	refresh_hud(world)


static func get_gold(world: Node) -> int:
	return int(get_state(world).get("gold", 0))


static func set_gold(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["gold"] = maxi(0, value)
	_write_state(world, state)


static func add_gold(world: Node, delta: int) -> void:
	set_gold(world, get_gold(world) + delta)


static func get_medical_supplies(world: Node) -> int:
	return int(get_state(world).get("medical_supplies", 0))


static func set_medical_supplies(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["medical_supplies"] = maxi(0, value)
	_write_state(world, state)


static func get_tool_supplies(world: Node) -> int:
	return int(get_state(world).get("tool_supplies", 0))


static func set_tool_supplies(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["tool_supplies"] = maxi(0, value)
	_write_state(world, state)


static func consume_medical(world: Node, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if get_medical_supplies(world) < amount:
		return false
	set_medical_supplies(world, get_medical_supplies(world) - amount)
	return true


static func consume_tool(world: Node, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if get_tool_supplies(world) < amount:
		return false
	set_tool_supplies(world, get_tool_supplies(world) - amount)
	return true


static func get_renown(world: Node) -> int:
	return int(get_state(world).get("renown", 0))


static func set_renown(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["renown"] = maxi(0, value)
	_write_state(world, state)


static func get_day_index(world: Node) -> int:
	return int(get_state(world).get("day_index", 0))


static func set_day_index(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["day_index"] = maxi(0, value)
	_write_state(world, state)


static func is_bankrupt(world: Node) -> bool:
	return bool(get_state(world).get("bankrupt", false))


static func set_bankrupt(world: Node, value: bool) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["bankrupt"] = value
	_write_state(world, state)


static func get_overworld_step_count(world: Node) -> int:
	return int(get_state(world).get("overworld_step_count", 0))


static func get_wage_per_member(world: Node) -> int:
	return int(get_state(world).get("wage_per_member", DEFAULT_WAGE_PER_MEMBER))


static func count_living_roster(world: Node) -> int:
	var pm: Variant = _resolve_party_manager(world)
	if pm == null:
		return 0
	var living := 0
	for member in pm.members:
		if not member is Dictionary:
			continue
		var node_ref: Variant = member.get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		living += 1
	return living


static func compute_next_wage_bill(world: Node) -> int:
	return get_wage_per_member(world) * count_living_roster(world)


static func on_overworld_step(world: Node2D) -> void:
	var mode: String = read_stub_day_tick_mode()
	_increment_overworld_step(world)
	if mode == "end_day":
		refresh_hud(world)
		return
	if mode == "steps" or mode == "hybrid":
		if get_overworld_step_count(world) >= read_stub_steps_per_day():
			try_advance_day(world)


static func request_end_day(world: Node2D) -> bool:
	var mode: String = read_stub_day_tick_mode()
	if mode == "steps":
		return false
	if mode == "hybrid" and not _player_on_camp_tile(world):
		return false
	return try_advance_day(world)


static func try_advance_day(world: Node2D) -> bool:
	if world == null:
		return false
	var bill: int = compute_next_wage_bill(world)
	var gold_before: int = get_gold(world)
	var state: Dictionary = get_state(world).duplicate()
	state["gold"] = int(state.get("gold", 0)) - bill
	state["day_index"] = int(state.get("day_index", 0)) + 1
	state["overworld_step_count"] = 0
	_write_state(world, state)
	if gold_before < bill and bill > 0:
		_apply_unpaid_wage_mood(world)
		_OperationalLog.play_world(
			"Wages short — paid what you could; mood fell (gold %d, bill %d)."
			% [gold_before, bill]
		)
	if read_stub_bankrupt_mode() == "desertion":
		_run_daily_desertion_pass(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"company_day_advanced day=%d wages_paid=%d gold=%d living=%d"
			% [
				get_day_index(world),
				bill,
				get_gold(world),
				count_living_roster(world),
			]
		)
	_warn_if_gold_below_next_wage(world)
	_warn_if_company_insolvent(world)
	if count_living_roster(world) <= 0:
		_trigger_company_collapsed(world, "bankrupt")
	return true


static func _warn_if_company_insolvent(world: Node) -> void:
	if world == null or get_gold(world) >= 0:
		return
	_OperationalLog.play_world(
		"Company is in debt (%dg). Low-mood brothers may desert at the next day end."
		% get_gold(world)
	)


static func can_offer_end_day(world: Node2D) -> bool:
	var mode: String = read_stub_day_tick_mode()
	if mode == "end_day":
		return true
	if mode == "hybrid":
		return _player_on_camp_tile(world)
	return false


static func should_show_next_wage_hint(state: Dictionary, living_count: int) -> bool:
	var gold: int = int(state.get("gold", 0))
	var bill: int = int(state.get("wage_per_member", DEFAULT_WAGE_PER_MEMBER)) * maxi(1, living_count)
	return gold < bill


static func format_next_wage_hint(state: Dictionary, living_count: int) -> String:
	var bill: int = int(state.get("wage_per_member", DEFAULT_WAGE_PER_MEMBER)) * living_count
	return "Next wage: %dg" % bill


static func format_day_hud_line(world: Node) -> String:
	var day: int = get_day_index(world)
	if read_stub_day_tick_mode() != "hybrid":
		return "Day: %d" % day
	return "Day %d · %d/%d steps" % [day, get_overworld_step_count(world), read_stub_steps_per_day()]


static func format_camp_heal_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if not _party_bleeding_controlled(world):
		var parts: int = _Bridge.party_untreated_part_count(world)
		if parts > 0:
			return "Camp rest (%d part(s) need dressing first)" % parts
		return "Camp rest (dress wounds first)"
	if get_medical_supplies(world) < 1:
		return "Camp rest (need 1 med after dressing)"
	if can_offer_camp_heal(world, from_party_menu):
		return format_camp_rest_button_label(world, from_party_menu)
	if read_stub_camp_heal_entry() == "tile" and not _player_on_camp_tile(world):
		return "Camp rest (stand on camp tile)"
	return "Camp rest (unavailable)"


## Party menu banner when camp rest is blocked by undressed wounds.
static func format_party_triage_gate_line(world: Node2D) -> String:
	var budget: Dictionary = triage_med_budget(world)
	var parts_need: int = int(budget.get("parts_need", 0))
	var med_left: int = get_medical_supplies(world)
	var total_est: int = int(budget.get("total_worst_case", 0))
	var dress_note: String = (
		"Field bandage (−1 med/part)"
		if med_left >= 1
		else "Field bandage (0 med · reduced efficacy)"
	)
	var shortfall_note: String = ""
	var shortfall: int = int(budget.get("med_shortfall", 0))
	if shortfall > 0:
		shortfall_note = (
			" Short %d med — bandage at reduced efficacy or win contracts for resupply (+4 med)."
			% shortfall
		)
	var body: String = (
		(
			"%d part(s) need dressing — Field pressure (free, 2m) on each part, then %s. "
			+ "Up to %d med for map dressings + camp rest (have %d). Battle triage bandages are free."
		)
		% [parts_need, dress_note, total_est, med_left]
	)
	return body + shortfall_note


## Post-victory settlement banner when roster still needs map field care.
static func format_settlement_field_care_hint(world: Node2D) -> String:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if world == null or not _Bridge.party_has_untreated_wounds(world):
		return ""
	var budget: Dictionary = triage_med_budget(world)
	var parts_need: int = int(budget.get("parts_need", 0))
	var total_est: int = int(budget.get("total_worst_case", 0))
	var med_left: int = get_medical_supplies(world)
	var hint: String = (
		(
			"Open Party on the map: field pressure (free), then bandage/pack/TQ on %d part(s). "
			+ "Battle triage bandages are free; Return to camp finishes remaining care automatically. "
			+ "Dress any still-untreated wounds in Party. "
			+ "Camp rest (−1 med · +1 day) when everyone is dressed. "
			+ "Up to %d med for map dressings + camp (have %d)."
		)
		% [parts_need, total_est, med_left]
	)
	var shortfall: int = int(budget.get("med_shortfall", 0))
	if shortfall > 0:
		hint += " Short %d med — reduced-efficacy bandages or contract resupply (+4 med)." % shortfall
	return hint


## Worst-case company med to finish map dressing + one camp rest (E3: 0-med bandages cost no supply).
static func triage_med_budget(world: Node2D) -> Dictionary:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	var parts_need: int = _Bridge.party_untreated_part_count(world)
	var med_left: int = get_medical_supplies(world)
	var field_bandage_med: int = parts_need if med_left >= 1 else 0
	var camp_med: int = 1
	var total: int = field_bandage_med + camp_med
	return {
		"parts_need": parts_need,
		"field_bandage_med_est": field_bandage_med,
		"camp_med": camp_med,
		"total_worst_case": total,
		"med_shortfall": maxi(0, total - med_left),
	}


## Short overworld HUD suffix when party has undressed wounds.
static func format_hud_triage_suffix(world: Node2D) -> String:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if world == null or not _Bridge.party_has_untreated_wounds(world):
		return ""
	var budget: Dictionary = triage_med_budget(world)
	var parts: int = int(budget.get("parts_need", 0))
	if parts <= 0:
		return ""
	var total: int = int(budget.get("total_worst_case", 0))
	var med_left: int = get_medical_supplies(world)
	if med_left == 0 and parts > 0:
		return " · %d to dress · 0-med bandages OK · need 1 med for camp" % parts
	if total > 0 and med_left < total:
		return " · %d to dress · need about %d med (have %d)" % [parts, total, med_left]
	if total > 0:
		return " · %d to dress · about %d med" % [parts, total]
	return " · %d to dress" % parts


## Overworld Party button label when roster needs map field care.
static func format_party_button_label(world: Node2D) -> String:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if world == null or not _Bridge.party_has_untreated_wounds(world):
		return "Party"
	var parts: int = _Bridge.party_untreated_part_count(world)
	if parts <= 0:
		return "Party"
	return "Party · %d to dress" % parts


## True when post-fight care still applies: undressed wounds now or last battle summary flagged dressing.
static func roster_recently_needed_field_dressing(world: Node2D) -> bool:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if world == null:
		return false
	if _Bridge.party_has_untreated_wounds(world):
		return true
	var summary: Dictionary = get_last_battle_summary(world)
	var members: Variant = summary.get("members", [])
	if not (members is Array):
		return false
	for entry in members as Array:
		if entry is not Dictionary:
			continue
		var snap: Dictionary = (entry as Dictionary).get("snapshot", entry) as Dictionary
		if bool(snap.get("has_untreated_wounds", false)):
			return true
	return false


## Party menu: show camp rest control when blocked state is still actionable copy.
static func should_show_party_camp_rest_button(world: Node2D) -> bool:
	if world == null:
		return false
	if can_offer_camp_heal(world, true):
		return true
	if get_medical_supplies(world) >= 1:
		return true
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if _Bridge.party_has_untreated_wounds(world):
		return true
	if not _party_bleeding_controlled(world):
		return false
	if get_medical_supplies(world) >= 1:
		return false
	var entry: String = read_stub_camp_heal_entry()
	if entry != "party_menu" and entry != "both":
		return false
	return roster_recently_needed_field_dressing(world)


static func refresh_party_button(world: Node2D) -> void:
	if world == null:
		return
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	const _CombatFlow := preload("res://world/CombatFlow.gd")
	var pb: Control = _CombatFlow._find_party_button(world)
	if pb == null or not pb is Button:
		return
	var btn: Button = pb as Button
	btn.text = format_party_button_label(world)
	btn.custom_minimum_size.x = maxf(100.0, btn.get_minimum_size().x + 8.0)
	if _Bridge.party_has_untreated_wounds(world):
		btn.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	else:
		btn.remove_theme_color_override("font_color")
	if not _Bridge.party_has_untreated_wounds(world):
		btn.tooltip_text = ""
		return
	var budget: Dictionary = triage_med_budget(world)
	var shortfall: int = int(budget.get("med_shortfall", 0))
	var med_left: int = get_medical_supplies(world)
	if med_left == 0:
		btn.tooltip_text = (
			"Open for field care — pressure (free), then 0-med bandages; "
			+ "win contracts for camp med (+4)."
		)
	elif shortfall > 0:
		btn.tooltip_text = (
			"Open for field care — pressure (free) then bandage/pack/TQ; short %d med."
			% shortfall
		)
	else:
		btn.tooltip_text = "Open for field care — pressure (free) then bandage/pack/TQ."


## Party menu / camp tile button copy (heal + day tick).
static func format_camp_rest_button_label(world: Node2D, from_party_menu: bool = false) -> String:
	var mins: int = int(read_stub_camp_heal_seconds() / 60.0)
	if world == null:
		return "Camp rest (−1 med, %d min · +1 day)" % mins
	if can_offer_camp_heal(world, from_party_menu):
		return "Camp rest (−1 med, %d min · +1 day)" % mins
	return "Camp rest (−1 med, %d min)" % mins


static func refresh_hud(world: Node) -> void:
	if world == null:
		return
	var hud: Control = _resolve_hud(world)
	if hud != null and hud.has_method("refresh_from_state"):
		hud.call(
			"refresh_from_state",
			get_state(world),
			count_living_roster(world),
			should_show_next_wage_hint(get_state(world), count_living_roster(world)),
			world
		)
	if world is Node2D:
		refresh_party_button(world as Node2D)


static func set_overworld_hud_visible(world: Node2D, visible: bool) -> void:
	var hud: Control = _resolve_hud(world)
	if hud != null:
		hud.visible = visible


static func _ensure_hud_on_world(world: Node2D) -> void:
	if _resolve_hud(world) != null:
		return
	if world != null and world.has_meta(WORLD_META_COMPANY_HUD):
		var stale_hud: Variant = world.get_meta(WORLD_META_COMPANY_HUD)
		if typeof(stale_hud) != TYPE_OBJECT or not is_instance_valid(stale_hud):
			world.remove_meta(WORLD_META_COMPANY_HUD)
	if world == null or not world.is_inside_tree():
		return
	var root: Node = world.get_tree().root
	var overlay: CanvasLayer = _get_or_create_overlay(root)
	var hud: Control = _CompanyHud.new()
	overlay.add_child(hud)
	world.set_meta(WORLD_META_COMPANY_HUD, hud)


static func _get_or_create_overlay(root: Node) -> CanvasLayer:
	for child in root.get_children():
		if child.name == "UIOverlayLayer" and child is CanvasLayer:
			return child
	var overlay := CanvasLayer.new()
	overlay.name = "UIOverlayLayer"
	overlay.layer = 100
	root.add_child(overlay)
	return overlay


static func _increment_overworld_step(world: Node) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["overworld_step_count"] = int(state.get("overworld_step_count", 0)) + 1
	world.set_meta(WORLD_META_COMPANY_STATE, state)


static func _warn_if_gold_below_next_wage(world: Node) -> void:
	var bill: int = compute_next_wage_bill(world)
	if get_gold(world) >= bill:
		return
	_OperationalLog.play_world(
		"company_wages: gold=%d below next wage bill=%d (day %d)"
		% [get_gold(world), bill, get_day_index(world)]
	)


static func _player_on_camp_tile(world: Node2D) -> bool:
	if world == null or not world.has_node("Character"):
		return false
	var player: Node2D = world.get_node("Character") as Node2D
	if player == null:
		return false
	if not world.has_method("_tile_coords"):
		return false
	var tile: Vector2i = world.call("_tile_coords", player.position)
	var camp: Vector2i = DEFAULT_CAMP_TILE
	if world.has_meta("camp_tile") and world.get_meta("camp_tile") is Vector2i:
		camp = world.get_meta("camp_tile")
	return tile == camp


static func _resolve_party_manager(world: Node) -> Node:
	if world == null or not world.has_meta("party_manager"):
		return null
	var pm: Variant = world.get_meta("party_manager")
	return pm if pm is Node else null


static func set_active_contract(world: Node, contract: Dictionary) -> void:
	if world == null:
		return
	world.set_meta(WORLD_META_ACTIVE_CONTRACT, contract.duplicate(true))


static func get_active_contract(world: Node) -> Dictionary:
	if world == null or not world.has_meta(WORLD_META_ACTIVE_CONTRACT):
		return {}
	var raw: Variant = world.get_meta(WORLD_META_ACTIVE_CONTRACT)
	return raw if raw is Dictionary else {}


static func has_active_campaign_contract(world: Node) -> bool:
	return not get_active_contract(world).is_empty()


static func is_campaign_contract_battle_world(world: Node) -> bool:
	return has_active_campaign_contract(world)


static func clear_active_contract(world: Node) -> void:
	if world != null and world.has_meta(WORLD_META_ACTIVE_CONTRACT):
		world.remove_meta(WORLD_META_ACTIVE_CONTRACT)


static func get_last_battle_summary(world: Node) -> Dictionary:
	if world == null or not world.has_meta(WORLD_META_LAST_BATTLE_SUMMARY):
		return {}
	var raw: Variant = world.get_meta(WORLD_META_LAST_BATTLE_SUMMARY)
	return raw if raw is Dictionary else {}


static func contract_loss_ends_run() -> bool:
	return read_stub_encounter_lifecycle() == "r3_loss_ends_run"


## Paid R3 contracts end the run on loss; tutorial / dev soak do not.
static func defeat_should_end_company_run(contract: Dictionary) -> bool:
	return (
		contract_loss_ends_run()
		and not contract.is_empty()
		and not is_tutorial_contract(contract)
	)


static func apply_contract_victory_pay(world: Node) -> int:
	var contract: Dictionary = get_active_contract(world)
	if contract.is_empty():
		return 0
	# Camp-2.1 / Camp-3.1: first win (any contract) → `warn_eta`; block only pre-first-win.
	mark_tutorial_completed(world)
	if is_tutorial_contract(contract):
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"contract_victory tutorial — no pay (type=%s)"
				% str(contract.get("contract_type", ""))
			)
		return 0
	var base_pay: int = int(contract.get("pay_gold", 0))
	var scaled: int = int(round(float(base_pay) * (1.0 + float(get_renown(world)) * RENOWN_PAY_SCALE)))
	add_gold(world, scaled)
	set_renown(world, get_renown(world) + 1)
	set_medical_supplies(world, get_medical_supplies(world) + CONTRACT_VICTORY_MED_RESUPPLY)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"contract_victory pay=%d gold=%d renown=%d med_resupply=%d med=%d"
			% [scaled, get_gold(world), get_renown(world), CONTRACT_VICTORY_MED_RESUPPLY, get_medical_supplies(world)]
		)
		if world is Node2D:
			const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
			if _Bridge.party_has_untreated_wounds(world as Node2D):
				var budget: Dictionary = triage_med_budget(world as Node2D)
				_OperationalLog.play_world(
					"contract_victory triage parts_need=%d med_shortfall=%d"
					% [int(budget.get("parts_need", 0)), int(budget.get("med_shortfall", 0))]
				)
	return scaled


static func apply_casualty_cleanup(world: Node2D) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if read_stub_casualty_on_settlement() != "memorial_then_remove":
		return lines
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return lines
	var summary: Dictionary = {}
	if world != null and world.has_meta(WORLD_META_LAST_BATTLE_SUMMARY):
		var raw: Variant = world.get_meta(WORLD_META_LAST_BATTLE_SUMMARY)
		if raw is Dictionary:
			summary = raw
	var deaths: Array = summary.get("deaths", [])
	var to_remove: Array = []
	for m in pm.members:
		var node_ref: Variant = m.get("node_ref") if m is Dictionary else null
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		if not (node_ref as Node).has_method("is_dead") or not (node_ref as Node).is_dead():
			continue
		var name_s: String = str(m.get("name", (node_ref as Node).name))
		var recap: String = _death_recap_for_name(name_s, deaths)
		lines.append("Memorial — %s%s" % [name_s, recap])
		to_remove.append(name_s)
	for name_s in to_remove:
		if pm.has_method("remove_member_by_name"):
			pm.remove_member_by_name(name_s)
	return lines


static func _death_recap_for_name(member_name: String, deaths: Array) -> String:
	for d in deaths:
		if d is Dictionary and str(d.get("name", "")) == member_name:
			return format_death_recap_suffix(d as Dictionary)
	return ""


## K3 memorial suffix: part, cause, optional killer + weapon from battle log.
## K3: lines for modals / logs from last battle `deaths` array.
static func format_last_battle_death_lines(world: Node) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var summary: Dictionary = get_last_battle_summary(world)
	var deaths: Variant = summary.get("deaths", [])
	if deaths is not Array:
		return lines
	for d in deaths as Array:
		if d is not Dictionary:
			continue
		var name_s: String = str((d as Dictionary).get("name", "?"))
		var recap: String = format_death_recap_suffix(d as Dictionary)
		lines.append("Fallen — %s%s" % [name_s, recap])
	return lines


static func format_death_recap_suffix(death: Dictionary) -> String:
	var part: String = str(death.get("part", ""))
	var cause: String = str(death.get("cause", ""))
	var killer: String = str(death.get("killer", ""))
	var weapon: String = str(death.get("weapon", ""))
	if part.is_empty() and cause.is_empty() and killer.is_empty():
		return ""
	var core: String = ""
	if not part.is_empty() and not cause.is_empty():
		core = "%s — %s" % [part, cause]
	elif not part.is_empty():
		core = part
	elif not cause.is_empty():
		core = cause
	if killer.is_empty():
		return " (%s)" % core if not core.is_empty() else ""
	if weapon.is_empty():
		return " (%s; fell to %s)" % [core, killer] if not core.is_empty() else " (fell to %s)" % killer
	return " (%s; %s — %s)" % [core, killer, weapon] if not core.is_empty() else " (%s — %s)" % [killer, weapon]


static func can_offer_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool:
	if get_medical_supplies(world) < 1:
		return false
	var entry: String = read_stub_camp_heal_entry()
	if entry == "party_menu":
		return true
	if from_party_menu and entry == "both":
		return true
	if entry == "tile" or entry == "both":
		return _player_on_camp_tile(world)
	return false


## All camp-rest gates (entry + med + dressed wounds) — use for button enabled state.
static func camp_heal_ready(world: Node2D, from_party_menu: bool = false) -> bool:
	return can_offer_camp_heal(world, from_party_menu) and _party_bleeding_controlled(world)


static func try_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool:
	if not can_offer_camp_heal(world, from_party_menu):
		return false
	if not _party_bleeding_controlled(world):
		if _OperationalLog.is_play_session_active():
			const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
			var parts: int = _Bridge.party_untreated_part_count(world)
			var block: String = format_camp_heal_block_reason(world, from_party_menu)
			_OperationalLog.play_world("camp_heal blocked: %s parts_need=%d" % [block, parts])
		return false
	if not consume_medical(world, 1):
		return false
	var day_before: int = get_day_index(world)
	_advance_party_healing(world, read_stub_camp_heal_seconds(), CAMP_HEAL_MULTIPLIER)
	try_advance_day(world)
	refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"camp_heal seconds=%.0f mult=%.1f med_left=%d day=%d->%d all_dressed=true"
			% [
				CAMP_HEAL_SECONDS,
				CAMP_HEAL_MULTIPLIER,
				get_medical_supplies(world),
				day_before,
				get_day_index(world),
			]
		)
	return true


static func roster_has_repairable_wounds(world: Node2D) -> bool:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	for n in _Bridge.get_fightable_party_nodes(world):
		var entity: Node = _Bridge.health_entity_from_character(n)
		if entity == null:
			continue
		if entity.has_method("get_wounded_parts") and not entity.get_wounded_parts().is_empty():
			return true
	return false


static func can_offer_settlement_tool_repair(world: Node2D) -> bool:
	return get_tool_supplies(world) >= 1 and roster_has_repairable_wounds(world)


static func apply_settlement_tool_repair(world: Node2D) -> bool:
	if not can_offer_settlement_tool_repair(world):
		return false
	if not consume_tool(world, 1):
		return false
	_advance_party_healing(world, 120.0, 1.5)
	refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world("settlement_repair tools_left=%d" % get_tool_supplies(world))
	return true


static func format_battle_medical_supply_hint(world: Node) -> String:
	if world == null or not world.has_meta(WORLD_META_CAMPAIGN_MED_BATTLE):
		return ""
	var raw: Variant = world.get_meta(WORLD_META_CAMPAIGN_MED_BATTLE)
	if raw is not Dictionary:
		return ""
	var med: int = int((raw as Dictionary).get("med_count", 0))
	var factor: float = float((raw as Dictionary).get("supply_factor", 1.0))
	if med <= 0:
		return (
			"Company med depleted — bandages free in battle; on map use field bandage at %.0f%% efficacy "
			% (factor * 100.0)
			+ " (pack / stabilize need −1 med when available)."
		)
	if med == 1:
		return (
			"One med left — pack or stabilize in medical phase costs your last supply; "
			+ "battle bandages are free; save med for map dressings + camp rest."
		)
	if med <= 5:
		return (
			"Med supplies tight (%d) — battle bandages free; plan field dressings + camp rest on the map."
			% med
		)
	if factor < 0.99:
		return "Medical supplies low - treatment efficacy %.0f%%." % (factor * 100.0)
	return ""


static func _party_bleeding_controlled(world: Node2D) -> bool:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	return not _Bridge.party_has_untreated_wounds(world)


static func _advance_party_healing(world: Node2D, seconds: float, multiplier: float) -> void:
	const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	var effective: float = seconds * multiplier
	for n in _Bridge.get_fightable_party_nodes(world):
		var entity: Node = _Bridge.health_entity_from_character(n)
		if entity != null:
			_EntityTimeAdvance.advance(entity, effective, true)
		if n.has_method("ensure_consciousness_current"):
			n.ensure_consciousness_current()


static func compute_medical_supply_factor(world: Node) -> float:
	if get_medical_supplies(world) >= 1:
		return 1.0
	return read_stub_supply_factor_at_zero_med()


static func wire_party_medical_supply(world: Node2D) -> void:
	if world == null:
		return
	var factor: float = compute_medical_supply_factor(world)
	world.set_meta(
		WORLD_META_CAMPAIGN_MED_BATTLE,
		{
			"mode": read_stub_med_battle_mode(),
			"supply_factor": factor,
			"med_count": get_medical_supplies(world),
		}
	)
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	for n in _Bridge.get_fightable_party_nodes(world):
		var entity: Node = _Bridge.health_entity_from_character(n)
		if entity != null and entity.has_method("set_campaign_supply_factor"):
			entity.set_campaign_supply_factor(factor)


static func on_battle_medical_complete(world: Node, target_method: String, success: bool) -> void:
	if world == null or not success or read_stub_med_battle_mode() != "hybrid":
		return
	if target_method in ["apply_packing", "apply_stabilize"]:
		consume_medical(world, 1)
	if world is Node2D:
		wire_party_medical_supply(world as Node2D)


static func resolve_world_from_battle(manager: Node) -> Node2D:
	if manager == null:
		return null
	var battle: Node = manager.get_parent()
	if battle == null:
		return null
	var ps: Variant = battle.get("parent_scene")
	if ps is Node2D:
		return ps as Node2D
	return null


static func adjust_member_mood(world: Node, member_name: String, delta: float) -> void:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return
	for m in pm.members:
		if m is Dictionary and str(m.get("name", "")) == member_name:
			var cur: float = float(m.get("company_mood", MOOD_DEFAULT))
			m["company_mood"] = clampf(cur + delta, 0.0, 100.0)
			return


## B3: soft-defeat / non-R3-reload losses only (paid R3 ends run → scene reload skips mood).
static func apply_battle_lost_mood(world: Node) -> void:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return
	for m in pm.members:
		if not m is Dictionary:
			continue
		var node_ref: Variant = m.get("node_ref")
		if not is_instance_valid(node_ref):
			continue
		if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		var name_s: String = str(m.get("name", (node_ref as Node).name))
		adjust_member_mood(world, name_s, MOOD_BATTLE_LOST_DELTA)


## B3: each living brother loses mood per fallen ally (applied before K3 roster removal).
static func apply_battle_death_witness_mood(world: Node, death_count: int) -> void:
	if death_count <= 0:
		return
	var delta: float = MOOD_DEATH_WITNESS_DELTA * float(death_count)
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return
	for m in pm.members:
		if not m is Dictionary:
			continue
		var node_ref: Variant = m.get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		var name_s: String = str(m.get("name", (node_ref as Node).name))
		adjust_member_mood(world, name_s, delta)


static func _apply_unpaid_wage_mood(world: Node) -> void:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return
	for m in pm.members:
		if not m is Dictionary:
			continue
		var node_ref: Variant = m.get("node_ref")
		if not is_instance_valid(node_ref):
			continue
		if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		var cur: float = float(m.get("company_mood", MOOD_DEFAULT))
		m["company_mood"] = clampf(cur - 1.0, 0.0, 100.0)


static func _run_daily_desertion_pass(world: Node2D) -> void:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var deserted: Array = []
	for m in pm.members:
		if not m is Dictionary:
			continue
		var node_ref: Variant = m.get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		if (node_ref as Node).get("is_party_leader") == true:
			continue
		var mood: float = float(m.get("company_mood", MOOD_DEFAULT))
		if mood > MOOD_ANGRY_THRESHOLD:
			continue
		if rng.randf() >= MOOD_DESERTION_CHANCE:
			continue
		var name_s: String = str(m.get("name", (node_ref as Node).name))
		deserted.append(name_s)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world("brother_deserted name=%s mood=%.1f" % [name_s, mood])
	if not deserted.is_empty():
		_OperationalLog.play_world(
			"desertion summary=%s" % ", ".join(deserted)
		)
	for name_s in deserted:
		if pm.has_method("remove_member_by_name"):
			pm.remove_member_by_name(name_s)
		if is_instance_valid(_resolve_member_node_by_name(world, name_s)):
			_resolve_member_node_by_name(world, name_s).queue_free()
	if count_living_roster(world) <= 0:
		_trigger_company_collapsed(world, "bankrupt")


static func _trigger_company_collapsed(world: Node2D, reason: String) -> void:
	if world == null:
		return
	if is_bankrupt(world):
		return
	set_bankrupt(world, true)
	if world.has_method("_company_run_end"):
		world.call_deferred("_company_run_end", reason)


static func _resolve_member_node_by_name(world: Node, member_name: String) -> Node:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return null
	for m in pm.members:
		if m is Dictionary and str(m.get("name", "")) == member_name:
			var node_ref: Variant = m.get("node_ref")
			if is_instance_valid(node_ref) and node_ref is Node:
				return node_ref
	return null


static func apply_post_victory_afflictions(world: Node2D) -> PackedStringArray:
	const _Afflictions := preload("res://world/CampaignAfflictions.gd")
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	var rng: RandomNumberGenerator = _Bridge.resolve_overworld_rng(world)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return _Afflictions.apply_after_victory(world, rng)


static func _resolve_hud(world: Node) -> Control:
	if world != null and world.has_meta(WORLD_META_COMPANY_HUD):
		var meta_hud: Variant = world.get_meta(WORLD_META_COMPANY_HUD)
		if typeof(meta_hud) == TYPE_OBJECT and is_instance_valid(meta_hud) and meta_hud is Control:
			return meta_hud
	if world == null or not world.is_inside_tree():
		return null
	var root: Node = world.get_tree().root
	for child in root.get_children():
		if child.name != "UIOverlayLayer":
			continue
		var found: Node = child.get_node_or_null("CompanyHud")
		if found is Control:
			if world != null:
				world.set_meta(WORLD_META_COMPANY_HUD, found)
			return found
	return null
