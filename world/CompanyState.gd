class_name CompanyState
extends RefCounted

## World-persistent company economy (P2 single-slot autosave on settlement continue + day tick).
## Camp-1.1–1.2: economy + HUD · Camp-1.3–1.6: supplies, contracts, camp heal.
## Canonical: `is_tutorial_contract` · `defeat_should_end_company_run` · `try_camp_heal` · `gate_*`.

const _CampaignPersistence := preload("res://world/CampaignPersistence.gd")
const _CompanyHud := preload("res://ui/CompanyHud.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _PartySetup := preload("res://world/PartySetup.gd")

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
## XCamp-3.6: food rations (1 per living brother per day); ~2 days at full roster.
const DEFAULT_FOOD_SUPPLIES := 14
const FOOD_PER_MEMBER_PER_DAY := 1
const DEFAULT_RENOWN := 0
const DEFAULT_DAY_INDEX := 0
## XCamp-3.1: gold cost to hire a replacement rookie at camp (§12 tuning).
const HIRE_GOLD_COST := 200
## XCamp-3.7: burial fee per fallen brother on settlement continue (§12 tuning).
const BURIAL_GOLD_COST := 25
## Max living brothers (EA scene slots: leader + 6 companions).
const ROSTER_MAX_LIVING := 7
const HIRE_ENTRY := "both"  # camp tile + Party menu (same as CAMP_HEAL_ENTRY)

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
const PROVISIONS_ENABLED := true
const BURIAL_COSTS_ENABLED := true
const BANKRUPT_MODE := "desertion"
const PERSISTENCE_MODE := "P2"  # D-persistence: single-slot autosave (P1 = session-only)
## Testing: paid run-end reload keeps slot; `main` restores last autosave (flip false for ship wipe).
const P2_RESTORE_ON_MAIN_RESTART := true
const WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE := "campaign_restored_from_save"

const RENOWN_PAY_SCALE := 0.05

const MOOD_DEFAULT := 50.0
const MOOD_ANGRY_THRESHOLD := 15.0
const MOOD_DESERTION_CHANCE := 0.05
const MOOD_BATTLE_WON_DELTA := 0.35
const MOOD_BATTLE_LOST_DELTA := -0.45
const MOOD_DEATH_WITNESS_DELTA := -0.25
const MOOD_CAMP_REST_DELTA := 1.0
const MOOD_NOT_FED_DELTA := -1.0
## XCamp-3.8 (MS-CAMP): map campaign mood to default weapon form at fight entry.
const MOOD_STANCE_WALL_THRESHOLD := 25.0
const MOOD_STANCE_WRATH_THRESHOLD := 70.0
const WORLD_META_CAMPAIGN_MED_BATTLE := "campaign_med_battle"
## Shared MARCH copy (Party, settlement, map bleed, operational logs).
const FIELD_CARE_MARCH_CHAIN := "pressure (free) → bandage/pack/TQ"

# Harness / compatibility readers
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
	var v = get_state(world).get("tutorial_completed")
	return v == true


static func mark_tutorial_completed(world: Node) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["tutorial_completed"] = true
	_write_state(world, state)


static func is_tutorial_contract(contract: Dictionary) -> bool:
	if contract.is_empty():
		return false
	if contract.get("tutorial") == true:
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


static func read_stub_provisions_enabled() -> bool:
	return PROVISIONS_ENABLED


static func read_stub_burial_costs_enabled() -> bool:
	return BURIAL_COSTS_ENABLED


static func read_stub_bankrupt_mode() -> String:
	return BANKRUPT_MODE


static func read_stub_persistence_mode() -> String:
	return PERSISTENCE_MODE


static func persistence_uses_disk_autosave() -> bool:
	return read_stub_persistence_mode() == "P2"


## Testing (P2): paid run-end reload keeps slot — `main` `_ready` restores last autosave.
static func persistence_restore_on_main_restart() -> bool:
	return persistence_uses_disk_autosave() and P2_RESTORE_ON_MAIN_RESTART


static func persistence_clear_slot_on_run_end_reload() -> bool:
	return persistence_uses_disk_autosave() and not persistence_restore_on_main_restart()


static func load_campaign_autosave_for_boot() -> Dictionary:
	if not persistence_uses_disk_autosave() or not _CampaignPersistence.has_save():
		return {}
	var data: Dictionary = _CampaignPersistence.load_save()
	if _CampaignPersistence.is_valid_save(data):
		return data
	_CampaignPersistence.clear_slot()
	if _OperationalLog.is_play_session_active():
		_OperationalLog.warn("campaign_autosave invalid — cleared slot, starting fresh")
	return {}


static func restore_campaign_autosave_on_main(
	world: Node2D, save_data: Dictionary, rng: RandomNumberGenerator, enemy_scene: PackedScene
) -> bool:
	if world == null or not _CampaignPersistence.is_valid_save(save_data):
		return false
	_CampaignPersistence.apply_save(world, save_data, rng, enemy_scene)
	world.set_meta(WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE, true)
	return true


static func format_hud_persistence_suffix(world: Node) -> String:
	var line: String = format_hud_persistence_line(world)
	if line.is_empty():
		return ""
	return " · %s" % line.to_lower()


static func format_hud_persistence_line(world: Node) -> String:
	if not persistence_uses_disk_autosave():
		return ""
	if world != null and world.get_meta(WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE, false) == true:
		return "Restored"
	if _CampaignPersistence.has_save():
		return "Saved"
	return "Autosave on"


static func format_party_autosave_footer() -> String:
	if not persistence_uses_disk_autosave():
		return ""
	var lines: PackedStringArray = PackedStringArray([
		"Autosave: settlement continue, End day, and Camp rest.",
	])
	if persistence_restore_on_main_restart():
		lines.append("Restart main restores your last save.")
		lines.append("Start new company wipes the save (testing).")
	return " ".join(lines)


static func count_desertion_risk_roster(world: Node) -> int:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return 0
	var at_risk: int = 0
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
		if float(m.get("company_mood", MOOD_DEFAULT)) <= MOOD_ANGRY_THRESHOLD:
			at_risk += 1
	return at_risk


static func format_party_desertion_risk_footer(world: Node2D) -> String:
	var at_risk: int = count_desertion_risk_roster(world)
	if at_risk <= 0:
		return ""
	return (
		"%d brother(s) at desertion risk (mood ≤%d) — 5%% roll each at day end."
		% [at_risk, int(MOOD_ANGRY_THRESHOLD)]
	)


static func format_party_end_day_unavailable_hint(world: Node2D) -> String:
	if world == null or can_offer_end_day(world):
		return ""
	if read_stub_day_tick_mode() == "hybrid":
		var steps_left: int = maxi(
			0, read_stub_steps_per_day() - get_overworld_step_count(world)
		)
		if steps_left <= 0:
			return "End day: stand on the camp tile to pay wages — or move to finish today's steps."
		return (
			"End day: stand on the camp tile (0,0) — or take %d more step(s) for an auto day tick."
			% steps_left
		)
	return ""


static func format_party_menu_footer(world: Node2D) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var end_day_hint: String = format_party_end_day_unavailable_hint(world)
	if not end_day_hint.is_empty():
		lines.append(end_day_hint)
	var desertion_hint: String = format_party_desertion_risk_footer(world)
	if not desertion_hint.is_empty():
		lines.append(desertion_hint)
	var autosave_hint: String = format_party_autosave_footer()
	if not autosave_hint.is_empty():
		lines.append(autosave_hint)
	return "\n".join(lines)


static func format_end_day_tooltip(world: Node2D) -> String:
	if world == null:
		return "Pay wages and consume daily rations."
	var tips: PackedStringArray = PackedStringArray([
		"Pay wages and consume daily rations for each living brother.",
	])
	for hint in format_hud_economy_hint_lines(
		get_state(world), count_living_roster(world), world
	):
		tips.append(hint)
	var desertion_hint: String = format_party_desertion_risk_footer(world)
	if not desertion_hint.is_empty():
		tips.append(desertion_hint)
	return " ".join(tips)


static func format_camp_rest_tooltip(world: Node2D) -> String:
	if world == null:
		return "Heal wounds, advance the day, and boost mood."
	var tips: PackedStringArray = PackedStringArray([
		"Heal all dressed brothers, advance the day, and grant +1 mood (tavern rest).",
	])
	for hint in format_hud_economy_hint_lines(
		get_state(world), count_living_roster(world), world
	):
		tips.append(hint)
	return " ".join(tips)


static func format_new_company_button_label() -> String:
	return "Start new company (testing)"


static func can_offer_new_campaign_from_menu() -> bool:
	return persistence_restore_on_main_restart()


static func request_new_campaign(world: Node2D) -> void:
	if world == null or world.get_tree() == null:
		return
	_CampaignPersistence.clear_slot()
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world("campaign_boot fresh=true reason=user_new_company")
	world.get_tree().change_scene_to_file("res://main.tscn")


static func format_end_day_button_label(world: Node2D = null) -> String:
	var base: String = "End day (saves progress)" if persistence_uses_disk_autosave() else "End day"
	return base + format_wage_day_tick_suffix(world) + format_provisions_day_tick_suffix(world)


## HUD / End day / Camp rest when gold cannot cover the next wage bill.
static func format_wage_day_tick_suffix(world: Node2D) -> String:
	if world == null:
		return ""
	var bill: int = compute_next_wage_bill(world)
	var gold: int = get_gold(world)
	if gold >= bill:
		return ""
	if gold < 0:
		return " — wage debt (desertion risk)"
	return " — wages short (mood hit if unpaid)"


## End day when daily rations cannot feed the living roster (XCamp-3.6).
static func format_provisions_day_tick_suffix(world: Node2D) -> String:
	if world == null or not read_stub_provisions_enabled():
		return ""
	var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
	if need <= 0:
		return ""
	if get_food_supplies(world) >= need:
		return ""
	return " — rations short (mood −1)"


static func should_show_next_provisions_hint(world: Node2D) -> bool:
	if world == null or not read_stub_provisions_enabled():
		return false
	var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
	return need > 0 and get_food_supplies(world) < need


static func format_next_provisions_hint(world: Node2D) -> String:
	var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
	var have: int = get_food_supplies(world)
	if have <= 0:
		return "Next rations: %d food (none left — mood −1 at day end)" % need
	return "Next rations: %d food (short %d — mood −1)" % [need, need - have]


static func format_hud_provisions_suffix(world: Node2D) -> String:
	if not should_show_next_provisions_hint(world):
		return ""
	return " · rations short"


static func format_hud_economy_hint_lines(
	state: Dictionary, living_count: int, world: Node2D = null
) -> PackedStringArray:
	var hints: PackedStringArray = PackedStringArray()
	if should_show_next_wage_hint(state, living_count):
		hints.append(format_next_wage_hint(state, living_count))
	if world != null and should_show_next_provisions_hint(world):
		hints.append(format_next_provisions_hint(world))
	return hints


static func format_hire_tooltip(world: Node2D, from_party_menu: bool = false) -> String:
	if world == null or not roster_has_hire_room(world):
		return ""
	if can_offer_hire(world, from_party_menu):
		return "Recruit a rookie for −%dg (fills vacant companion slot)." % HIRE_GOLD_COST
	return format_hire_block_reason(world, from_party_menu)


static func format_wages_short_log(gold_before: int, bill: int) -> String:
	return "Wages short — paid what you could; mood fell (gold %d, bill %d)." % [gold_before, bill]


static func format_company_debt_log(gold: int) -> String:
	return (
		"Company is in debt (%dg). Low-mood brothers may desert at the next day end."
		% gold
	)


static func format_autosave_action_suffix() -> String:
	if persistence_uses_disk_autosave():
		return " · saves progress"
	return ""


static func try_autosave(world: Node2D) -> bool:
	if not persistence_uses_disk_autosave() or world == null:
		return false
	var ok: bool = _CampaignPersistence.save_slot(world)
	if ok:
		if world.has_meta(WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE):
			world.remove_meta(WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE)
		refresh_hud(world)
	elif _OperationalLog.is_play_session_active():
		_OperationalLog.warn("campaign_autosave failed — slot not written")
	return ok


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
		"food_supplies": DEFAULT_FOOD_SUPPLIES,
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


static func consume_gold(world: Node, amount: int) -> bool:
	if amount <= 0:
		return true
	if get_gold(world) < amount:
		return false
	set_gold(world, get_gold(world) - amount)
	return true


static func read_stub_hire_entry() -> String:
	return HIRE_ENTRY


static func roster_has_hire_room(world: Node) -> bool:
	return count_living_roster(world) < ROSTER_MAX_LIVING


static func can_offer_hire(world: Node2D, from_party_menu: bool = false) -> bool:
	if world == null or not roster_has_hire_room(world):
		return false
	if _PartySetup.find_vacant_companion_node(world) == null:
		return false
	if get_gold(world) < HIRE_GOLD_COST:
		return false
	var entry: String = read_stub_hire_entry()
	if entry == "party_menu":
		return true
	if from_party_menu and entry == "both":
		return true
	if entry == "tile" or entry == "both":
		return _player_on_camp_tile(world)
	return false


static func should_show_party_hire_button(world: Node2D) -> bool:
	return world != null and roster_has_hire_room(world)


static func format_hire_button_label(_world: Node = null) -> String:
	return "Hire rookie (−%dg)" % HIRE_GOLD_COST


static func format_hire_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
	if not roster_has_hire_room(world):
		return "Hire (roster full — %d/%d)" % [count_living_roster(world), ROSTER_MAX_LIVING]
	if _PartySetup.find_vacant_companion_node(world) == null:
		return "Hire (no vacant slot)"
	if get_gold(world) < HIRE_GOLD_COST:
		return "Hire (need %dg · have %dg)" % [HIRE_GOLD_COST, get_gold(world)]
	if can_offer_hire(world, from_party_menu):
		return format_hire_button_label(world)
	if read_stub_hire_entry() == "tile" and not _player_on_camp_tile(world):
		return "Hire (stand on camp tile)"
	return "Hire (unavailable)"


static func try_hire_rookie(
	world: Node2D, rng: RandomNumberGenerator = null, from_party_menu: bool = false
) -> bool:
	if not can_offer_hire(world, from_party_menu):
		return false
	var gold_before: int = get_gold(world)
	if not consume_gold(world, HIRE_GOLD_COST):
		return false
	var roll: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		roll.randomize()
	var hired: Node = _PartySetup.spawn_hire_companion(world, roll)
	if hired == null:
		set_gold(world, gold_before)
		return false
	refresh_hud(world)
	try_autosave(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"hire_rookie name=%s gold=%d living=%d"
			% [hired.name, get_gold(world), count_living_roster(world)]
		)
	return true


static func get_medical_supplies(world: Node) -> int:
	return int(get_state(world).get("medical_supplies", 0))


static func set_medical_supplies(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["medical_supplies"] = maxi(0, value)
	_write_state(world, state)
	_sync_party_medical_supply_after_med_change(world)


static func get_tool_supplies(world: Node) -> int:
	return int(get_state(world).get("tool_supplies", 0))


static func set_tool_supplies(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["tool_supplies"] = maxi(0, value)
	_write_state(world, state)


static func get_food_supplies(world: Node) -> int:
	return int(get_state(world).get("food_supplies", 0))


static func set_food_supplies(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["food_supplies"] = maxi(0, value)
	_write_state(world, state)


static func consume_food(world: Node, amount: int) -> bool:
	if amount <= 0:
		return true
	if get_food_supplies(world) < amount:
		return false
	set_food_supplies(world, get_food_supplies(world) - amount)
	return true


static func consume_medical(world: Node, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if get_medical_supplies(world) < amount:
		return false
	set_medical_supplies(world, get_medical_supplies(world) - amount)
	return true


static func _sync_party_medical_supply_after_med_change(world: Node) -> void:
	if world is Node2D:
		wire_party_medical_supply(world as Node2D)


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


static func get_contract_deck_index(world: Node) -> int:
	return int(get_state(world).get("contract_deck_index", 0))


static func set_contract_deck_index(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["contract_deck_index"] = maxi(0, value)
	_write_state(world, state)


static func get_day_index(world: Node) -> int:
	return int(get_state(world).get("day_index", 0))


static func set_day_index(world: Node, value: int) -> void:
	var state: Dictionary = get_state(world).duplicate()
	state["day_index"] = maxi(0, value)
	_write_state(world, state)


static func is_bankrupt(world: Node) -> bool:
	return get_state(world).get("bankrupt") == true


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
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(format_wages_short_log(gold_before, bill))
	on_day_tick(world)
	if read_stub_bankrupt_mode() == "desertion":
		_run_daily_desertion_pass(world)
	_warn_if_gold_below_next_wage(world)
	_warn_if_company_insolvent(world)
	if count_living_roster(world) <= 0:
		_trigger_company_collapsed(world, "bankrupt")
		return true
	var autosaved: bool = try_autosave(world)
	if _OperationalLog.is_play_session_active():
		var autosave_bit: String = " autosave=true" if autosaved else ""
		_OperationalLog.play_world(
			"company_day_advanced day=%d wages_paid=%d gold=%d living=%d%s"
			% [
				get_day_index(world),
				bill,
				get_gold(world),
				count_living_roster(world),
				autosave_bit,
			]
		)
	return true


static func _warn_if_company_insolvent(world: Node) -> void:
	if world == null or get_gold(world) >= 0:
		return
	if not _OperationalLog.is_play_session_active():
		return
	_OperationalLog.play_world(format_company_debt_log(get_gold(world)))


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
	var bill: int = int(state.get("wage_per_member", DEFAULT_WAGE_PER_MEMBER)) * maxi(1, living_count)
	var gold: int = int(state.get("gold", 0))
	if gold < 0:
		return "Wages: %dg due — %dg debt (desertion risk)" % [bill, -gold]
	if gold < bill:
		return "Next wage: %dg (short %d — mood hit if unpaid)" % [bill, bill - gold]
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
			return (
				"Camp rest (%d part(s) need dressing — Treat next wound or field care above, then retry)"
				% parts
			)
		return "Camp rest (dress wounds with Treat next wound or field care above first)"
	if get_medical_supplies(world) < 1:
		return "Camp rest (need 1 med after dressing)"
	if can_offer_camp_heal(world, from_party_menu):
		return format_camp_rest_button_label(world, from_party_menu)
	if read_stub_camp_heal_entry() == "tile" and not _player_on_camp_tile(world):
		return "Camp rest (stand on camp tile)"
	return "Camp rest (unavailable)"


## Shared field-bandage med copy (Party gate, settlement, buttons).
static func format_field_bandage_dress_note(world: Node2D) -> String:
	if get_medical_supplies(world) >= 1:
		return "Field bandage (−1 med/part)"
	return "Field bandage (0 med · reduced efficacy)"


static func format_field_care_march_chain() -> String:
	return FIELD_CARE_MARCH_CHAIN


static func format_field_care_shortfall_suffix(world: Node2D) -> String:
	var shortfall: int = int(triage_med_budget(world).get("med_shortfall", 0))
	if shortfall <= 0:
		return ""
	return (
		" Short %d med — bandage at reduced efficacy or win contracts for resupply (+4 med)."
		% shortfall
	)


## Map field-care procedure efficacy (live world med × skill; strips stale entity supply stamp).
static func compute_field_treatment_effectiveness(
	entity: Node, world: Node2D, stabilize_floor: bool
) -> float:
	var supply: float = compute_medical_supply_factor(world)
	var skill: float = 1.0
	if entity != null and entity.has_method("get_medical_effectiveness"):
		skill = float(entity.get_medical_effectiveness())
		if entity.has_method("get_campaign_supply_factor"):
			var stamped: float = float(entity.get_campaign_supply_factor())
			if stamped > 0.001:
				skill /= stamped
	var eff: float = skill * supply
	if stabilize_floor:
		return clampf(maxf(eff, 1.15), 0.25, 2.0)
	return clampf(eff, 0.25, 1.5)


static func format_field_bandage_med_bit(world: Node2D, entity: Node = null) -> String:
	if get_medical_supplies(world) >= 1:
		return "−1 med"
	var eff_pct: float = (
		compute_field_treatment_effectiveness(entity, world, false) * 100.0
		if entity != null
		else compute_medical_supply_factor(world) * 100.0
	)
	return "0 med · %.0f%% eff" % eff_pct


static func format_post_fight_field_care_short_log(parts_left: int) -> String:
	return (
		"field_care: untreated wounds remain after battle triage parts_left=%d — open Party on the map"
		% parts_left
	)


static func format_post_fight_field_care_world_log(world: Node2D) -> String:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	var budget: Dictionary = triage_med_budget(world)
	var parts: int = int(budget.get("parts_need", 0))
	var med_left: int = get_medical_supplies(world)
	var zero_med_note: String = (
		"; 0-med bandages OK for map dressings" if med_left <= 0 else ""
	)
	return (
		"field_care: open Party — %s; %d part(s) need dressing; "
		+ "med_left=%d; bandage_med_est=%d; total_med_est=%d; med_shortfall=%d%s; "
		+ "battle bandages free; then Camp rest (−1 med · +1 day · +1 mood)"
	) % [
		FIELD_CARE_MARCH_CHAIN,
		parts,
		med_left,
		int(budget.get("field_bandage_med_est", 0)),
		int(budget.get("total_worst_case", 0)),
		int(budget.get("med_shortfall", 0)),
		zero_med_note,
	]


## Party menu banner when camp rest is blocked by undressed wounds.
static func format_party_triage_gate_line(world: Node2D) -> String:
	var budget: Dictionary = triage_med_budget(world)
	var parts_need: int = int(budget.get("parts_need", 0))
	var med_left: int = get_medical_supplies(world)
	var total_est: int = int(budget.get("total_worst_case", 0))
	var body: String = (
		(
			"%d part(s) need dressing — Treat next wound (highest threat) or use each brother's care buttons. "
			+ "Order: %s, then %s. "
			+ "Up to %d med for dressings + camp rest (have %d). Battle triage bandages are free."
		)
		% [parts_need, FIELD_CARE_MARCH_CHAIN, format_field_bandage_dress_note(world), total_est, med_left]
	)
	return body + format_field_care_shortfall_suffix(world)


## Party menu banner after the last untreated part is dressed (same session).
static func format_field_care_complete_line(world: Node2D) -> String:
	var mins: int = int(read_stub_camp_heal_seconds() / 60.0)
	var med_note: String = ""
	if world != null and get_medical_supplies(world) < 1:
		med_note = " Need 1 med to camp — win contracts for resupply (+4 med)."
	return "All wounds dressed — Camp rest unlocked (−1 med, %d min · +1 day · +1 mood).%s" % [mins, med_note]


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
			"Before the next fight: open Party on the map — %s, then %s on %d part(s). "
			+ "Battle triage bandages are free; after Continue, finish dressing on the map, then Camp rest "
			+ "(−1 med · +1 day · +1 mood). Up to %d med for dressings + camp (have %d)."
		)
		% [
			FIELD_CARE_MARCH_CHAIN,
			format_field_bandage_dress_note(world),
			parts_need,
			total_est,
			med_left,
		]
	)
	return hint + format_field_care_shortfall_suffix(world)


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
static func format_hud_wage_suffix(world: Node2D) -> String:
	if world == null:
		return ""
	var state: Dictionary = get_state(world)
	var living: int = count_living_roster(world)
	if not should_show_next_wage_hint(state, living):
		return ""
	var gold: int = int(state.get("gold", 0))
	if gold < 0:
		return " · wage debt"
	return " · wages short"


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
		if snap.get("has_untreated_wounds") == true:
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
	var tips: PackedStringArray = PackedStringArray()
	if _Bridge.party_has_untreated_wounds(world):
		var budget: Dictionary = triage_med_budget(world)
		var shortfall: int = int(budget.get("med_shortfall", 0))
		var med_left: int = get_medical_supplies(world)
		var march: String = format_field_care_march_chain()
		if med_left == 0:
			tips.append(
				"Field care — %s; 0-med bandages; win contracts for camp med (+4)." % march
			)
		elif shortfall > 0:
			tips.append("Field care — %s; short %d med." % [march, shortfall])
		else:
			tips.append("Field care — %s." % march)
	if should_show_next_wage_hint(get_state(world), count_living_roster(world)):
		tips.append(format_next_wage_hint(get_state(world), count_living_roster(world)))
	if should_show_next_provisions_hint(world):
		tips.append(format_next_provisions_hint(world))
	if roster_has_hire_room(world):
		var hire_tip: String = format_hire_tooltip(world, false)
		if not hire_tip.is_empty():
			tips.append(hire_tip)
	if persistence_uses_disk_autosave():
		tips.append(format_party_autosave_footer())
	btn.tooltip_text = " ".join(tips)


## Party menu / camp tile button copy (heal + day tick).
static func format_camp_rest_button_label(world: Node2D, from_party_menu: bool = false) -> String:
	var save_bit: String = format_autosave_action_suffix()
	if world == null:
		return "Camp rest (−1 med · +1 day · +1 mood)%s" % save_bit
	if can_offer_camp_heal(world, from_party_menu):
		return (
			"Camp rest (−1 med · +1 day · +1 mood)%s%s%s"
			% [
				save_bit,
				format_wage_day_tick_suffix(world),
				format_provisions_day_tick_suffix(world),
			]
		)
	return "Camp rest (−1 med · +1 day)"


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
	if not _OperationalLog.is_play_session_active():
		return
	_OperationalLog.play_world(
		"company_wages: gold=%d below next wage bill=%d (day %d)"
		% [get_gold(world), bill, get_day_index(world)]
	)


static func _player_on_camp_tile(world: Node2D) -> bool:
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	if world == null or not world.has_node("Character"):
		return false
	var player: Node2D = world.get_node("Character") as Node2D
	if player == null:
		return false
	var tile: Vector2i = _Bridge.overworld_tile_from_position(player.position)
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


## Daily economy after wages: provisions (XCamp-3.6) and future day hooks.
static func on_day_tick(world: Node2D) -> void:
	if world == null:
		return
	if read_stub_provisions_enabled():
		_apply_daily_provisions(world)


static func _apply_daily_provisions(world: Node2D) -> void:
	var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
	if need <= 0:
		return
	var have: int = get_food_supplies(world)
	if have >= need:
		set_food_supplies(world, have - need)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"provisions fed=%d food_left=%d" % [need, get_food_supplies(world)]
			)
		return
	if have > 0:
		set_food_supplies(world, 0)
	_apply_not_fed_mood(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"provisions short need=%d had=%d mood=%.0f" % [need, have, MOOD_NOT_FED_DELTA]
		)


static func count_last_battle_deaths(world: Node) -> int:
	var summary: Dictionary = get_last_battle_summary(world)
	var deaths: Variant = summary.get("deaths", [])
	if deaths is Array:
		return (deaths as Array).size()
	return 0


## XCamp-3.7: burial fee preview (no gold mutation).
static func compute_settlement_burial_cost(world: Node) -> int:
	if world == null or not read_stub_burial_costs_enabled():
		return 0
	return count_last_battle_deaths(world) * BURIAL_GOLD_COST


static func format_settlement_burial_debt_warning(world: Node2D, gold_before: int = -1) -> String:
	var cost: int = compute_settlement_burial_cost(world)
	if cost <= 0:
		return ""
	var gold: int = gold_before if gold_before >= 0 else get_gold(world)
	if gold >= cost:
		return ""
	return (
		"Burial will cost %dg but you only have %dg — debt is allowed (same as unpaid wages)."
		% [cost, gold]
	)


static func format_settlement_victory_mood_hint() -> String:
	return "On continue: living brothers gain a mood boost from victory."


static func format_settlement_low_mood_stance_hint(world: Node2D) -> String:
	var pm: Node = _resolve_party_manager(world)
	if pm == null:
		return ""
	var low: int = 0
	for m in pm.members:
		if not m is Dictionary:
			continue
		var node_ref: Variant = m.get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		if float(m.get("company_mood", MOOD_DEFAULT)) <= MOOD_STANCE_WALL_THRESHOLD:
			low += 1
	if low <= 0:
		return ""
	return (
		"Low company mood — %d brother(s) may default to wall form in the next fight "
		+ "(unless they have an explicit form preference)."
	) % low


## XCamp-3.7: charge burial fees from last battle death count (allows wage-style debt).
static func apply_settlement_burial_costs(world: Node2D) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if world == null or not read_stub_burial_costs_enabled():
		return lines
	var deaths: int = count_last_battle_deaths(world)
	if deaths <= 0:
		return lines
	var cost: int = compute_settlement_burial_cost(world)
	var state: Dictionary = get_state(world).duplicate()
	state["gold"] = int(state.get("gold", 0)) - cost
	_write_state(world, state)
	lines.append("Burial costs: −%dg (%d fallen × %dg)" % [cost, deaths, BURIAL_GOLD_COST])
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"burial_cost deaths=%d cost=%d gold=%d" % [deaths, cost, get_gold(world)]
		)
	return lines


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
	CompanyState.apply_camp_rest_mood(world)
	refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"camp_heal seconds=%.0f mult=%.1f med_left=%d day=%d->%d all_dressed=true mood=+%.0f"
			% [
				CAMP_HEAL_SECONDS,
				CAMP_HEAL_MULTIPLIER,
				get_medical_supplies(world),
				day_before,
				get_day_index(world),
				MOOD_CAMP_REST_DELTA,
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
	const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
	var effective: float = seconds * multiplier
	for n in _Bridge.get_fightable_party_nodes(world):
		var entity: Node = _Bridge.health_entity_from_character(n)
		if entity != null:
			if entity.has_method("process_bleeding"):
				entity.process_bleeding(effective)
			if entity.has_method("process_blood_loss"):
				entity.process_blood_loss(effective)
			if entity.has_method("process_healing"):
				entity.process_healing(effective)
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


## B3: camp tavern rest — each living brother gains mood after successful camp heal.
static func apply_camp_rest_mood(world: Node) -> void:
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
		adjust_member_mood(world, name_s, MOOD_CAMP_REST_DELTA)


## MS-CAMP / XCamp-3.8: derive roster default weapon form from campaign mood (spawn only).
static func stance_preference_for_campaign_mood(mood: float) -> String:
	const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
	if mood <= MOOD_STANCE_WALL_THRESHOLD:
		return _WeaponForm.FORM_WALL
	if mood >= MOOD_STANCE_WRATH_THRESHOLD:
		return _WeaponForm.FORM_WRATH
	return _WeaponForm.FORM_BALANCED


## B3 / XCamp-3.6: each living brother loses mood when daily rations are short.
static func _apply_not_fed_mood(world: Node) -> void:
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
		adjust_member_mood(world, name_s, MOOD_NOT_FED_DELTA)


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
	var deserted_names: Array = []
	var deserted_summaries: Array = []
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
		deserted_names.append(name_s)
		deserted_summaries.append("%s(mood=%d)" % [name_s, int(roundf(mood))])
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world("brother_deserted name=%s mood=%.1f" % [name_s, mood])
	if not deserted_summaries.is_empty() and _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"desertion summary=%s" % ", ".join(deserted_summaries)
		)
	for name_s in deserted_names:
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
