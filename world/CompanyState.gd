class_name CompanyState
extends RefCounted

## Thin facade over split company modules -- backward-compatible re-export for all 141+ static functions.
## Module ownership:
##   CompanyEconomy.gd  -- state accessors, gold, supplies, wages, renown, provisions, med supply wiring
##   CompanyMood.gd     -- mood management, stance preferences, desertion risk counting
##   CompanyCamp.gd     -- camp healing gates/execution, tool repair, field care formatting/status
##   CompanyDayCycle.gd -- day tick orchestration (end day request, auto step-tick, provisions, desertion pass)
##   CompanyRoster.gd   -- hire/casualty/burial lifecycle, contract management, tutorial/combat meta

const _CampaignPersistence := preload("res://world/CampaignPersistence.gd")
const _CompanyHud := preload("res://ui/CompanyHud.gd")
const _PartySetup := preload("res://world/PartySetup.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
# Runtime preload -- circular dependency (CombatFlow preloads CampaignEncounterBridge -> EntityWounds -> EntityStatsUtil).
static var _combat_flow_cache: Variant = null
static func _get_combat_flow() -> Variant:
	if _combat_flow_cache == null:
		_combat_flow_cache = load("res://world/CombatFlow.gd")
	return _combat_flow_cache
const _CampaignAfflictions := preload("res://world/CampaignAfflictions.gd")
const _CompanyEconomy := preload("res://world/CompanyEconomy.gd")

const _CompanyMood := preload("res://world/CompanyMood.gd")
const _CompanyCamp := preload("res://world/CompanyCamp.gd")
const _CompanyDayCycle := preload("res://world/CompanyDayCycle.gd")
const _CompanyRoster := preload("res://world/CompanyRoster.gd")

## Re-exported from CampaignTypes for backward compat -- preload CampaignTypes directly in new code.
const DEFAULT_CAMP_TILE: Vector2i = preload("res://world/CampaignTypes.gd").DEFAULT_CAMP_TILE

# World meta keys (Sec10) -- re-exported from CampaignTypes for backward compat.
const WORLD_META_COMPANY_STATE: String = preload("res://world/CampaignTypes.gd").WORLD_META_COMPANY_STATE
const WORLD_META_ACTIVE_CONTRACT: String = preload("res://world/CampaignTypes.gd").WORLD_META_ACTIVE_CONTRACT
const WORLD_META_LAST_BATTLE_SUMMARY: String = preload("res://world/CampaignTypes.gd").WORLD_META_LAST_BATTLE_SUMMARY
const WORLD_META_BATTLE_KILL_LOG: String = preload("res://world/CampaignTypes.gd").WORLD_META_BATTLE_KILL_LOG
const WORLD_META_COMPANY_HUD: String = preload("res://world/CampaignTypes.gd").WORLD_META_COMPANY_HUD

## Sec12 EA tuning defaults (inline -- kept here for backward compat with all callers).
const DEFAULT_GOLD: int = 500
const DEFAULT_WAGE_PER_MEMBER: int = 15
const DEFAULT_MEDICAL_SUPPLIES: int = 15
const CONTRACT_VICTORY_MED_RESUPPLY: int = 4
const DEFAULT_TOOL_SUPPLIES: int = 2
const DEFAULT_FOOD_SUPPLIES: int = 14
const FOOD_PER_MEMBER_PER_DAY: int = 1
const DEFAULT_RENOWN: int = 0
const DEFAULT_DAY_INDEX: int = 0
const HIRE_GOLD_COST: int = 200
const BURIAL_GOLD_COST: int = 25
const ROSTER_MAX_LIVING: int = 7
const HIRE_ENTRY: String = "both"

## Closed gates.
const DAY_TICK_MODE: String = "hybrid"
const STEPS_PER_DAY: int = 5
const ENCOUNTER_LIFECYCLE: String = "r3_loss_ends_run"
const CAMP_HEAL_ENTRY: String = "both"
const CAMP_HEAL_SECONDS: float = 600.0
const CAMP_HEAL_MULTIPLIER: float = 3.0
const CASUALTY_ON_SETTLEMENT: String = "memorial_then_remove"
const MAP_BLEED_POLICY: String = "warn_eta"
const WORLD_META_MAP_BLEED_MULT: String = "campaign_map_bleed_mult"
const MED_BATTLE_MODE: String = "hybrid"
const SUPPLY_FACTOR_AT_ZERO_MED: float = 0.5
const AFFLICTIONS_ENABLED: bool = true
const PROVISIONS_ENABLED: bool = true
const BURIAL_COSTS_ENABLED: bool = true
const BANKRUPT_MODE: String = "desertion"
## P2 persistence.
const PERSISTENCE_MODE: String = "P2"
const P2_RESTORE_ON_MAIN_RESTART: bool = true
const WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE: String = "campaign_restored_from_save"

## XCamp-4: use-based stat proficiency system (enabled by default; harness may gate).
static var PROFICIENCY_ENABLED: bool = true

const RENOWN_PAY_SCALE: float = 0.05

## Mood constants (inline -- kept here for backward compat with all callers).
const MOOD_DEFAULT: float = 50.0
const MOOD_ANGRY_THRESHOLD: float = 15.0
const MOOD_DESERTION_CHANCE: float = 0.05
const MOOD_BATTLE_LOST_DELTA: float = -0.45
const MOOD_DEATH_WITNESS_DELTA: float = -0.25
const MOOD_CAMP_REST_DELTA: float = 1.0
const MOOD_NOT_FED_DELTA: float = -1.0
const MOOD_BATTLE_WON_DELTA: float = 0.35
const MOOD_STANCE_WALL_THRESHOLD: float = 25.0
const MOOD_STANCE_WRATH_THRESHOLD: float = 70.0


## === Stub / Gate Readers ===

static func read_stub_day_tick_mode() -> String: return DAY_TICK_MODE
static func read_stub_steps_per_day() -> int: return STEPS_PER_DAY
static func read_stub_encounter_lifecycle() -> String: return ENCOUNTER_LIFECYCLE
static func read_stub_camp_heal_entry() -> String: return CAMP_HEAL_ENTRY
static func read_stub_casualty_on_settlement() -> String: return CASUALTY_ON_SETTLEMENT
static func read_stub_map_bleed_policy() -> String: return MAP_BLEED_POLICY
static func read_stub_med_battle_mode() -> String: return MED_BATTLE_MODE
static func read_stub_supply_factor_at_zero_med() -> float: return SUPPLY_FACTOR_AT_ZERO_MED
static func read_stub_afflictions_enabled() -> bool: return AFFLICTIONS_ENABLED
static func read_stub_provisions_enabled() -> bool: return PROVISIONS_ENABLED
static func read_stub_burial_costs_enabled() -> bool: return BURIAL_COSTS_ENABLED
static func read_stub_bankrupt_mode() -> String: return BANKRUPT_MODE
static func read_stub_persistence_mode() -> String: return _CompanyEconomy.PERSISTENCE_MODE_STR
static func read_stub_hire_entry() -> String: return HIRE_ENTRY
static func read_stub_proficiency_enabled() -> bool: return PROFICIENCY_ENABLED
static func persistence_uses_disk_autosave() -> bool: return _CompanyEconomy.persistence_uses_disk_autosave()
static func persistence_restore_on_main_restart() -> bool: return _CompanyEconomy.persistence_restore_on_main_restart()
static func persistence_clear_slot_on_run_end_reload() -> bool: return _CompanyEconomy.persistence_clear_slot_on_run_end_reload()


## === Persistence ===

static func load_campaign_autosave_for_boot() -> Dictionary:
	if not persistence_uses_disk_autosave() or not _CampaignPersistence.has_save():
		return {}
	var data: Dictionary = _CampaignPersistence.load_save()
	if _CampaignPersistence.is_valid_save(data):
		return data
	_CampaignPersistence.clear_slot()
	if _OperationalLog.is_play_session_active():
		_OperationalLog.warn("campaign_autosave invalid -- cleared slot, starting fresh")
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
	return " /  %s" % line.to_lower()


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


## === State Accessors (delegated to CompanyEconomy) ===

static func attach_to_world(world: Node2D) -> void: _CompanyEconomy.attach_to_world(world)
static func init_from_defaults(world: Node2D) -> void: _CompanyEconomy.init_from_defaults(world)
static func _default_state_dict() -> Dictionary: return _CompanyEconomy._default_state_dict()
static func get_state(world: Node) -> Dictionary: return _CompanyEconomy.get_state(world)
static func _write_state(world: Node, state: Dictionary) -> void: _CompanyEconomy._write_state(world, state)

static func get_gold(world: Node) -> int: return _CompanyEconomy.get_gold(world)
static func set_gold(world: Node, value: int) -> void: _CompanyEconomy.set_gold(world, value)
static func add_gold(world: Node, delta: int) -> void: _CompanyEconomy.add_gold(world, delta)
static func consume_gold(world: Node, amount: int) -> bool: return _CompanyEconomy.consume_gold(world, amount)

static func get_medical_supplies(world: Node) -> int: return _CompanyEconomy.get_medical_supplies(world)
static func set_medical_supplies(world: Node, value: int) -> void: _CompanyEconomy.set_medical_supplies(world, value)
static func get_tool_supplies(world: Node) -> int: return _CompanyEconomy.get_tool_supplies(world)
static func set_tool_supplies(world: Node, value: int) -> void: _CompanyEconomy.set_tool_supplies(world, value)
static func get_food_supplies(world: Node) -> int: return _CompanyEconomy.get_food_supplies(world)
static func set_food_supplies(world: Node, value: int) -> void: _CompanyEconomy.set_food_supplies(world, value)

static func consume_food(world: Node, amount: int) -> bool: return _CompanyEconomy.consume_food(world, amount)
static func consume_medical(world: Node, amount: int = 1) -> bool: return _CompanyEconomy.consume_medical(world, amount)
static func consume_tool(world: Node, amount: int = 1) -> bool: return _CompanyEconomy.consume_tool(world, amount)

static func get_renown(world: Node) -> int: return _CompanyEconomy.get_renown(world)
static func set_renown(world: Node, value: int) -> void: _CompanyEconomy.set_renown(world, value)
static func get_contract_deck_index(world: Node) -> int: return _CompanyEconomy.get_contract_deck_index(world)
static func set_contract_deck_index(world: Node, value: int) -> void: _CompanyEconomy.set_contract_deck_index(world, value)
static func get_day_index(world: Node) -> int: return _CompanyEconomy.get_day_index(world)
static func set_day_index(world: Node, value: int) -> void: _CompanyEconomy.set_day_index(world, value)

static func is_bankrupt(world: Node) -> bool: return _CompanyEconomy.is_bankrupt(world)
static func set_bankrupt(world: Node, value: bool) -> void: _CompanyEconomy.set_bankrupt(world, value)
static func get_overworld_step_count(world: Node) -> int: return _CompanyEconomy.get_overworld_step_count(world)
static func get_wage_per_member(world: Node) -> int: return _CompanyEconomy.get_wage_per_member(world)
static func wire_party_medical_supply(world: Node2D) -> void: _CompanyEconomy.wire_party_medical_supply(world)

## === Roster helpers (delegated) ===

static func count_living_roster(world: Node) -> int: return _CompanyEconomy.count_living_roster(world)
static func compute_next_wage_bill(world: Node) -> int: return _CompanyEconomy.compute_next_wage_bill(world)


## === Tutorial / Contract meta (delegated to CompanyRoster) ===

static func is_tutorial_completed(world: Node) -> bool: return _CompanyRoster.is_tutorial_completed(world)
static func mark_tutorial_completed(world: Node) -> void: _CompanyRoster.mark_tutorial_completed(world)
static func is_tutorial_contract(contract: Dictionary) -> bool: return _CompanyRoster.is_tutorial_contract(contract)

static func set_map_bleed_mult(world: Node, mult: float) -> void: _CompanyRoster.set_map_bleed_mult(world, mult)
static func get_map_bleed_mult(world: Node) -> float: return _CompanyRoster.get_map_bleed_mult(world)

static func set_active_contract(world: Node, contract: Dictionary) -> void: _CompanyRoster.set_active_contract(world, contract)
static func get_active_contract(world: Node) -> Dictionary: return _CompanyRoster.get_active_contract(world)
static func has_active_campaign_contract(world: Node) -> bool: return _CompanyRoster.has_active_campaign_contract(world)
static func is_campaign_contract_battle_world(world: Node) -> bool: return _CompanyRoster.is_campaign_contract_battle_world(world)
static func clear_active_contract(world: Node) -> void: _CompanyRoster.clear_active_contract(world)
static func get_last_battle_summary(world: Node) -> Dictionary: return _CompanyRoster.get_last_battle_summary(world)

static func contract_loss_ends_run() -> bool: return _CompanyRoster.contract_loss_ends_run()
static func defeat_should_end_company_run(contract: Dictionary) -> bool: return _CompanyRoster.defeat_should_end_company_run(contract)


## === End day / Day cycle (delegated to CompanyDayCycle) ===

static func request_end_day(world: Node2D) -> bool: return _CompanyDayCycle.request_end_day(world)
static func try_advance_day(world: Node2D) -> bool: return _CompanyDayCycle.try_advance_day(world)
static func on_overworld_step(world: Node2D) -> void: _CompanyDayCycle.on_overworld_step(world)
static func can_offer_end_day(world: Node2D) -> bool: return _CompanyDayCycle.can_offer_end_day(world)
static func on_day_tick(world: Node2D) -> void: _CompanyDayCycle.on_day_tick(world)
static func _run_daily_desertion_pass(world: Node2D) -> void: _CompanyDayCycle._run_daily_desertion_pass(world)


## === Camp healing (delegated to CompanyCamp) ===

static func can_offer_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool: return _CompanyCamp.can_offer_camp_heal(world, from_party_menu)
static func camp_heal_ready(world: Node2D, from_party_menu: bool = false) -> bool: return _CompanyCamp.camp_heal_ready(world, from_party_menu)
static func try_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool: return _CompanyCamp.try_camp_heal(world, from_party_menu)


## === Tool repair (delegated to CompanyCamp) ===

static func roster_has_repairable_wounds(world: Node2D) -> bool: return _CompanyCamp.roster_has_repairable_wounds(world)
static func can_offer_settlement_tool_repair(world: Node2D) -> bool: return _CompanyCamp.can_offer_settlement_tool_repair(world)
static func apply_settlement_tool_repair(world: Node2D) -> bool: return _CompanyCamp.apply_settlement_tool_repair(world)


## === Hire (delegated to CompanyRoster) ===

static func roster_has_hire_room(world: Node) -> bool: return _CompanyRoster.roster_has_hire_room(world)
static func can_offer_hire(world: Node2D, from_party_menu: bool = false) -> bool: return _CompanyRoster.can_offer_hire(world, from_party_menu)
static func should_show_party_hire_button(world: Node2D) -> bool: return _CompanyRoster.should_show_party_hire_button(world)
static func format_hire_button_label(_world: Node = null) -> String: return _CompanyRoster.format_hire_button_label(_world)
static func format_hire_block_reason(world: Node2D, from_party_menu: bool = false) -> String: return _CompanyRoster.format_hire_block_reason(world, from_party_menu)
static func format_hire_tooltip(world: Node2D, from_party_menu: bool = false) -> String: return _CompanyRoster.format_hire_tooltip(world, from_party_menu)
static func try_hire_rookie(
	world: Node2D, rng: RandomNumberGenerator = null, from_party_menu: bool = false
) -> bool: return _CompanyRoster.try_hire_rookie(world, rng, from_party_menu)


## === Burial / Casualties (delegated to CompanyRoster) ===

static func count_last_battle_deaths(world: Node) -> int: return _CompanyRoster.count_last_battle_deaths(world)
static func compute_settlement_burial_cost(world: Node) -> int: return _CompanyRoster.compute_settlement_burial_cost(world)
static func format_settlement_burial_debt_warning(world: Node2D, gold_before: int = -1) -> String: return _CompanyRoster.format_settlement_burial_debt_warning(world, gold_before)
static func apply_settlement_burial_costs(world: Node2D) -> PackedStringArray: return _CompanyRoster.apply_settlement_burial_costs(world)
static func apply_casualty_cleanup(world: Node2D) -> PackedStringArray: return _CompanyRoster.apply_casualty_cleanup(world)
static func format_last_battle_death_lines(world: Node) -> PackedStringArray: return _CompanyRoster.format_last_battle_death_lines(world)
static func format_death_recap_suffix(death: Dictionary) -> String: return _CompanyRoster.format_death_recap_suffix(death)


## === Mood management (delegated to CompanyMood) ===

static func adjust_member_mood(world: Node, member_name: String, delta: float) -> void: _CompanyMood.adjust_member_mood(world, member_name, delta)
static func apply_camp_rest_mood(world: Node) -> void: _CompanyMood.apply_camp_rest_mood(world)
static func stance_preference_for_campaign_mood(mood: float) -> String: return _CompanyMood.stance_preference_for_campaign_mood(mood)
static func apply_battle_lost_mood(world: Node) -> void: _CompanyMood.apply_battle_lost_mood(world)
static func apply_battle_death_witness_mood(world: Node, death_count: int) -> void: _CompanyMood.apply_battle_death_witness_mood(world, death_count)
static func count_desertion_risk_roster(world: Node) -> int: return _CompanyMood.count_desertion_risk_roster(world)
static func format_party_desertion_risk_footer(world: Node2D) -> String: return _CompanyMood.format_party_desertion_risk_footer(world)


## === Contract victory (delegated to CompanyRoster) ===

static func apply_contract_victory_pay(world: Node) -> int: return _CompanyRoster.apply_contract_victory_pay(world)


## === Field care status (delegated to CompanyCamp) ===

static func format_field_bandage_dress_note(world: Node2D) -> String: return _CompanyCamp.format_field_bandage_dress_note(world)
static func format_field_care_march_chain() -> String: return _CompanyCamp.format_field_care_march_chain()
static func format_field_care_shortfall_suffix(world: Node2D) -> String: return _CompanyCamp.format_field_care_shortfall_suffix(world)
static func compute_field_treatment_effectiveness(
	entity: Node, world: Node2D, stabilize_floor: bool
) -> float: return _CompanyCamp.compute_field_treatment_effectiveness(entity, world, stabilize_floor)
static func format_field_bandage_med_bit(world: Node2D, entity: Node = null) -> String: return _CompanyCamp.format_field_bandage_med_bit(world, entity)
static func format_post_fight_field_care_short_log(parts_left: int) -> String: return _CompanyCamp.format_post_fight_field_care_short_log(parts_left)
static func format_post_fight_field_care_world_log(world: Node2D) -> String: return _CompanyCamp.format_post_fight_field_care_world_log(world)
static func roster_recently_needed_field_dressing(world: Node2D) -> bool: return _CompanyCamp.roster_recently_needed_field_dressing(world)
static func should_show_party_camp_rest_button(world: Node2D) -> bool: return _CompanyCamp.should_show_party_camp_rest_button(world)


## === UI formatting (uses module functions internally) ===

static func format_end_day_tooltip(world: Node2D) -> String:
	if world == null:
		return "Pay wages and consume daily rations."
	var tips: PackedStringArray = PackedStringArray([
		"Pay wages and consume daily rations for each living brother.",
	])
	for hint in _CompanyEconomy.format_hud_economy_hint_lines(
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
	for hint in _CompanyEconomy.format_hud_economy_hint_lines(
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
	world.get_tree().change_scene_to_file(preload("res://combat/CombatConstants.gd").PATH_MAIN_SCENE)


static func format_end_day_button_label(world: Node2D = null) -> String:
	var base: String = "End day"
	if persistence_uses_disk_autosave():
		base = "End day (saves progress)"
	return base + format_wage_day_tick_suffix(world) + format_provisions_day_tick_suffix(world)


static func format_wage_day_tick_suffix(world: Node2D) -> String:
	if world == null:
		return ""
	var bill: int = compute_next_wage_bill(world)
	var gold: int = get_gold(world)
	if gold >= bill:
		return ""
	if gold < 0:
		return " -- wage debt (desertion risk)"
	return " -- wages short (mood hit if unpaid)"


static func format_provisions_day_tick_suffix(world: Node2D) -> String:
	if world == null or not read_stub_provisions_enabled():
		return ""
	var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
	if need <= 0:
		return ""
	if get_food_supplies(world) >= need:
		return ""
	return " -- rations short (mood -1)"


static func should_show_next_provisions_hint(world: Node2D) -> bool:
	return _CompanyEconomy.should_show_next_provisions_hint(world)


static func format_next_provisions_hint(world: Node2D) -> String:
	return _CompanyEconomy.format_next_provisions_hint(world)


static func format_hud_provisions_suffix(world: Node2D) -> String:
	if not should_show_next_provisions_hint(world):
		return ""
	return " /  rations short"


static func format_party_end_day_unavailable_hint(world: Node2D) -> String:
	if world == null or can_offer_end_day(world):
		return ""
	if read_stub_day_tick_mode() == "hybrid":
		var steps_left: int = maxi(
			0, read_stub_steps_per_day() - get_overworld_step_count(world)
		)
		if steps_left <= 0:
			return "End day: stand on the camp tile to pay wages -- or move to finish today's steps."
		return (
			"End day: stand on the camp tile (0,0) -- or take %d more step(s) for an auto day tick."
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


static func format_hud_economy_hint_lines(
	state: Dictionary, living_count: int, world: Node2D = null
) -> PackedStringArray:
	return _CompanyEconomy.format_hud_economy_hint_lines(state, living_count, world)


static func should_show_next_wage_hint(state: Dictionary, living_count: int) -> bool:
	return _CompanyEconomy.should_show_next_wage_hint(state, living_count)


static func format_next_wage_hint(state: Dictionary, living_count: int) -> String:
	return _CompanyEconomy.format_next_wage_hint(state, living_count)


static func format_day_hud_line(world: Node) -> String:
	return _CompanyDayCycle.format_day_hud_line(world)


## === Party button / HUD (delegated to CompanyCamp + CompanyEconomy) ===

static func format_party_button_label(world: Node2D) -> String:
	if world == null or not _CampaignBridge.party_has_untreated_wounds(world):
		return "Party"
	var parts: int = _CampaignBridge.party_untreated_part_count(world)
	if parts <= 0:
		return "Party"
	return "Party /  %d to dress" % parts


static func format_hud_wage_suffix(world: Node2D) -> String:
	if world == null:
		return ""
	var state: Dictionary = get_state(world)
	var living: int = count_living_roster(world)
	if not _CompanyEconomy.should_show_next_wage_hint(state, living):
		return ""
	var gold: int = state.get("gold", 0)
	if gold < 0:
		return " /  wage debt"
	return " /  wages short"


static func format_hud_triage_suffix(world: Node2D) -> String:
	if world == null or not _CampaignBridge.party_has_untreated_wounds(world):
		return ""
	var budget: Dictionary = _CompanyCamp.triage_med_budget(world)
	var parts: int = budget.get("parts_need", 0)
	if parts <= 0:
		return ""
	var total: int = budget.get("total_worst_case", 0)
	var med_left: int = get_medical_supplies(world)
	if med_left == 0 and parts > 0:
		return " /  %d to dress /  0-med bandages OK /  need 1 med for camp" % parts
	if total > 0 and med_left < total:
		return " /  %d to dress /  need about %d med (have %d)" % [parts, total, med_left]
	if total > 0:
		return " /  %d to dress /  about %d med" % [parts, total]
	return " /  %d to dress" % parts


static func refresh_party_button(world: Node2D) -> void:
	if world == null:
		return
	var pb: Control = _get_combat_flow()._find_party_button(world)
	if pb == null or not pb is Button:
		return
	var btn: Button = pb as Button
	btn.text = format_party_button_label(world)
	btn.custom_minimum_size.x = maxf(100.0, btn.get_minimum_size().x + 8.0)
	if _CampaignBridge.party_has_untreated_wounds(world):
		btn.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	else:
		btn.remove_theme_color_override("font_color")
	var tips: PackedStringArray = PackedStringArray()
	if _CampaignBridge.party_has_untreated_wounds(world):
		var budget: Dictionary = _CompanyCamp.triage_med_budget(world)
		var shortfall: int = budget.get("med_shortfall", 0)
		var med_left: int = get_medical_supplies(world)
		var march: String = format_field_care_march_chain()
		if med_left == 0:
			tips.append(
				"Field care -- %s; 0-med bandages; win contracts for camp med (+4)." % march
			)
		elif shortfall > 0:
			tips.append("Field care -- %s; short %d med." % [march, shortfall])
		else:
			tips.append("Field care -- %s." % march)
	if _CompanyEconomy.should_show_next_wage_hint(get_state(world), count_living_roster(world)):
		tips.append(_CompanyEconomy.format_next_wage_hint(get_state(world), count_living_roster(world)))
	if _CompanyEconomy.should_show_next_provisions_hint(world):
		tips.append(format_next_provisions_hint(world))
	if roster_has_hire_room(world):
		var hire_tip: String = format_hire_tooltip(world, false)
		if not hire_tip.is_empty():
			tips.append(hire_tip)
	if persistence_uses_disk_autosave():
		tips.append(format_party_autosave_footer())
	btn.tooltip_text = " ".join(tips)


## === Battle medical hint (delegated to CompanyEconomy) ===

static func format_battle_medical_supply_hint(world: Node) -> String:
	if world == null or not world.has_meta(_CompanyEconomy.WORLD_META_CAMPAIGN_MED_BATTLE):
		return ""
	var raw: Variant = world.get_meta(_CompanyEconomy.WORLD_META_CAMPAIGN_MED_BATTLE)
	if raw is not Dictionary:
		return ""
	var med: int = (raw as Dictionary).get("med_count", 0)
	var factor: float = (raw as Dictionary).get("supply_factor", 1.0)
	if med <= 0:
		return (
			"Company med depleted -- bandages free in battle; on map use field bandage at %.0f%% efficacy "
			% (factor * 100.0)
			+ " (pack / stabilize need -1 med when available)."
		)
	if med == 1:
		return (
			"One med left -- pack or stabilize in medical phase costs your last supply; "
			+ "battle bandages are free; save med for map dressings + camp rest."
		)
	elif med <= 5:
		return (
			"Med supplies tight (%d) -- battle bandages free; plan field dressings + camp rest on the map."
			% med
		)
	if factor < 0.99:
		return "Medical supplies low - treatment efficacy %.0f%%." % (factor * 100.0)
	return ""


## === Settlement / Battle UI hints ===

static func format_settlement_victory_mood_hint() -> String:
	return ""

static func format_settlement_low_mood_stance_hint(world: Node2D) -> String:
	var pm: Node = _CompanyEconomy._resolve_party_manager(world)
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
		if float(m.get("company_mood", _CompanyMood.MOOD_DEFAULT)) <= _CompanyMood.MOOD_STANCE_WALL_THRESHOLD:
			low += 1
	if low <= 0:
		return ""
	return (
		"Low company mood -- %d brother(s) may default to wall form in the next fight "
		+ "(unless they have an explicit form preference)."
	) % low


## === Refresh / Visibility (delegated) ===

static func refresh_hud(world: Node) -> void:
	if world == null:
		return
	_CompanyEconomy.refresh_hud(world)
	if world is Node2D:
		refresh_party_button(world as Node2D)


static func set_overworld_hud_visible(world: Node2D, visible: bool) -> void:
	var hud: Control = _resolve_hud(world)
	if hud != null:
		hud.visible = visible


## === Player position on camp tile (used by multiple modules) ===

static func _player_on_camp_tile(world: Node2D) -> bool:
	if world == null:
		return false
	var player: Node2D = get_campaign_bridge().get_player(world)
	if player == null:
		return false
	var tile: Vector2i = get_campaign_bridge().overworld_tile_from_position(player.position)
	var camp: Vector2i = DEFAULT_CAMP_TILE
	if world.has_meta("camp_tile") and world.get_meta("camp_tile") is Vector2i:
		camp = world.get_meta("camp_tile")
	return tile == camp


## === HUD creation (delegated) ===

static func _ensure_hud_on_world(world: Node2D) -> void: _CompanyEconomy._ensure_hud_on_world(world)
static func _get_or_create_overlay(root: Node) -> CanvasLayer: return _CompanyEconomy._get_or_create_overlay(root)
static func _resolve_hud(world: Node) -> Control: return _CompanyEconomy._resolve_hud(world)


## === Post-victory afflictions (delegated) ===

static func apply_post_victory_afflictions(world: Node2D) -> PackedStringArray:
	var rng: RandomNumberGenerator = _CampaignBridge.resolve_overworld_rng(world)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return _CampaignAfflictions.apply_after_victory(world, rng)


## === Bridge accessor (used by company modules) ===

static func get_campaign_bridge() -> GDScript:
	return _CampaignBridge


## === Internal helpers (used by multiple modules) ===

static func _warn_if_company_insolvent(world: Node) -> void:
	if world == null or get_gold(world) >= 0:
		return
	if not _OperationalLog.is_play_session_active():
		return
	_OperationalLog.play_world(format_company_debt_log(get_gold(world)))


static func format_company_debt_log(gold: int) -> String:
	return (
		"Company is in debt (%dg). Low-mood brothers may desert at the next day end."
		% gold
	)


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


## === Party manager resolution (shared utility) ===

static func _resolve_party_manager(world: Node) -> Node:
	if world == null or not world.has_meta("party_manager"):
		return null
	var pm: Variant = world.get_meta("party_manager")
	return pm if pm is Node else null


## === Resolve / Battle hooks (delegated to CompanyEconomy) ===

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


static func on_battle_medical_complete(world: Node, target_method: String, success: bool) -> void:
	_CompanyEconomy.on_battle_medical_complete(world, target_method, success)


## === Triage / Med helpers (delegated to CompanyCamp) ===

static func triage_med_budget(world: Node2D) -> Dictionary:
	return _CompanyCamp.triage_med_budget(world)


static func format_party_triage_gate_line(world: Node2D) -> String:
	return _CompanyCamp.format_party_triage_gate_line(world)


static func format_field_care_complete_line(world: Node2D) -> String:
	return _CompanyCamp.format_field_care_complete_line(world)


## === Camp rest button label (delegated to CompanyCamp) ===

static func format_camp_rest_button_label(world: Node2D, from_party_menu: bool = false) -> String:
	return _CompanyCamp.format_camp_rest_button_label(world, from_party_menu)


static func format_camp_heal_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
	return _CompanyCamp.format_camp_heal_block_reason(world, from_party_menu)


## === Autosave (delegated to CompanyEconomy) ===

static func try_autosave(world: Node2D) -> bool:
	return _CompanyEconomy.try_autosave(world)


static func format_autosave_action_suffix() -> String:
	return _CompanyEconomy.format_autosave_action_suffix()


## === Medical supply factor (delegated to CompanyEconomy) ===

static func compute_medical_supply_factor(world: Node) -> float:
	return _CompanyEconomy.compute_medical_supply_factor(world)


## === Wages short log (delegated to CompanyEconomy) ===

static func format_wages_short_log(gold_before: int, bill: int) -> String:
	return _CompanyEconomy.format_wages_short_log(gold_before, bill)


## === Settlement field care hint (delegated to CompanyCamp) ===

static func format_settlement_field_care_hint(world: Node2D) -> String:
	return _CompanyCamp.format_settlement_field_care_hint(world)


## === Member node resolution (internal helper used by CompanyDayCycle desertion pass) ===

static func _resolve_member_node_by_name(world: Node, member_name: String) -> Node:
	var pm: Node = _CompanyEconomy._resolve_party_manager(world)
	if pm == null:
		return null
	for m in pm.members:
		if m is Dictionary and m.get("name", "") == member_name:
			var node_ref: Variant = m.get("node_ref")
			if is_instance_valid(node_ref) and node_ref is Node:
				return node_ref
	return null
