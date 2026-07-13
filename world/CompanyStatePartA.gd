class_name CompanyStatePartA
extends RefCounted

## Thin facade over split company modules -- backward-compatible re-export for all 141+ static functions.
## Module ownership:
##   CompanyEconomy.gd  -- state accessors, gold, supplies, wages, renown, provisions, med supply wiring
##   CompanyMood.gd     -- mood management, stance preferences, desertion risk counting
##   CompanyCamp.gd     -- camp healing gates/execution, tool repair, field care formatting/status
##   CompanyDayCycle.gd -- day tick orchestration (end day request, auto step-tick, provisions, desertion pass)
##   CompanyRoster.gd   -- hire/casualty/burial lifecycle, contract management, tutorial/combat meta

const PartySetup := preload("res://world/PartySetup.gd")
const DEFAULT_CAMP_TILE: Vector2i = CampaignTypes.DEFAULT_CAMP_TILE

# World meta keys (Sec10) -- re-exported from CampaignTypes for backward compat.
const WORLD_META_COMPANY_STATE: String = CampaignTypes.WORLD_META_COMPANY_STATE
const WORLD_META_ACTIVE_CONTRACT: String = CampaignTypes.WORLD_META_ACTIVE_CONTRACT
const WORLD_META_LAST_BATTLE_SUMMARY: String = CampaignTypes.WORLD_META_LAST_BATTLE_SUMMARY
const WORLD_META_BATTLE_KILL_LOG: String = CampaignTypes.WORLD_META_BATTLE_KILL_LOG
const WORLD_META_COMPANY_HUD: String = CampaignTypes.WORLD_META_COMPANY_HUD

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

static var _combat_flow_cache: Variant = null

## XCamp-4: use-based stat proficiency system (enabled by default; harness may gate).
static var proficiency_enabled: bool = true


static func _get_combat_flow() -> Variant:
    if _combat_flow_cache == null:
        _combat_flow_cache = load("res://world/CombatFlow.gd")
    return _combat_flow_cache


## === Stub / Gate Readers ===

## === Stub / Gate Readers ===


static func read_stub_day_tick_mode() -> String:
    return DAY_TICK_MODE


static func read_stub_steps_per_day() -> int:
    return STEPS_PER_DAY


static func read_stub_encounter_lifecycle() -> String:
    return ENCOUNTER_LIFECYCLE


static func read_stub_camp_heal_entry() -> String:
    return CAMP_HEAL_ENTRY


static func read_stub_casualty_on_settlement() -> String:
    return CASUALTY_ON_SETTLEMENT


static func read_stub_map_bleed_policy() -> String:
    return MAP_BLEED_POLICY


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
    return CompanyEconomy.PERSISTENCE_MODE_STR


static func read_stub_hire_entry() -> String:
    return HIRE_ENTRY


static func read_stub_proficiency_enabled() -> bool:
    return proficiency_enabled


static func persistence_uses_disk_autosave() -> bool:
    return CompanyEconomy.persistence_uses_disk_autosave()


static func persistence_restore_on_main_restart() -> bool:
    return CompanyEconomy.persistence_restore_on_main_restart()


static func persistence_clear_slot_on_run_end_reload() -> bool:
    return CompanyEconomy.persistence_clear_slot_on_run_end_reload()


## === Persistence ===

## === Persistence ===


static func load_campaign_autosave_for_boot() -> Dictionary:
    if not persistence_uses_disk_autosave() or not CampaignPersistence.has_save():
        return {}
    var data: Dictionary = CampaignPersistence.load_save()
    if CampaignPersistence.is_valid_save(data):
        return data
    CampaignPersistence.clear_slot()
    if OperationalLog.is_play_session_active():
        OperationalLog.warn("campaign_autosave invalid -- cleared slot, starting fresh")
    return {}


static func restore_campaign_autosave_on_main(
    world: Node2D, save_data: Dictionary, rng: RandomNumberGenerator, enemy_scene: PackedScene
) -> bool:
    if world == null or not CampaignPersistence.is_valid_save(save_data):
        return false
    CampaignPersistence.apply_save(world, save_data, rng, enemy_scene)
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
    if CampaignPersistence.has_save():
        return "Saved"
    return "Autosave on"


static func format_party_autosave_footer() -> String:
    if not persistence_uses_disk_autosave():
        return ""
    var lines: PackedStringArray = PackedStringArray(
        [
            "Autosave: settlement continue, End day, and Camp rest.",
        ]
    )
    if persistence_restore_on_main_restart():
        lines.append("Restart main restores your last save.")
        lines.append("Start new company wipes the save (testing).")
    return " ".join(lines)


## === State Accessors (delegated to CompanyEconomy) ===

## === State Accessors (delegated to CompanyEconomy) ===


static func attach_to_world(world: Node2D) -> void:
    CompanyEconomy.attach_to_world(world)


static func init_from_defaults(world: Node2D) -> void:
    CompanyEconomy.init_from_defaults(world)


static func _default_state_dict() -> Dictionary:
    return CompanyEconomy._default_state_dict()


static func get_state(world: Node) -> Dictionary:
    return CompanyEconomy.get_state(world)


static func _write_state(world: Node, state: Dictionary) -> void:
    CompanyEconomy._write_state(world, state)


static func get_gold(world: Node) -> int:
    return CompanyEconomy.get_gold(world)


static func set_gold(world: Node, value: int) -> void:
    CompanyEconomy.set_gold(world, value)


static func add_gold(world: Node, delta: int) -> void:
    CompanyEconomy.add_gold(world, delta)


static func consume_gold(world: Node, amount: int) -> bool:
    return CompanyEconomy.consume_gold(world, amount)


static func get_medical_supplies(world: Node) -> int:
    return CompanyEconomy.get_medical_supplies(world)


static func set_medical_supplies(world: Node, value: int) -> void:
    CompanyEconomy.set_medical_supplies(world, value)


static func get_tool_supplies(world: Node) -> int:
    return CompanyEconomy.get_tool_supplies(world)


static func set_tool_supplies(world: Node, value: int) -> void:
    CompanyEconomy.set_tool_supplies(world, value)


static func get_food_supplies(world: Node) -> int:
    return CompanyEconomy.get_food_supplies(world)


static func set_food_supplies(world: Node, value: int) -> void:
    CompanyEconomy.set_food_supplies(world, value)


static func consume_food(world: Node, amount: int) -> bool:
    return CompanyEconomy.consume_food(world, amount)


static func consume_medical(world: Node, amount: int = 1) -> bool:
    return CompanyEconomy.consume_medical(world, amount)


static func consume_tool(world: Node, amount: int = 1) -> bool:
    return CompanyEconomy.consume_tool(world, amount)


static func get_renown(world: Node) -> int:
    return CompanyEconomy.get_renown(world)


static func set_renown(world: Node, value: int) -> void:
    CompanyEconomy.set_renown(world, value)


static func get_contract_deck_index(world: Node) -> int:
    return CompanyEconomy.get_contract_deck_index(world)


static func set_contract_deck_index(world: Node, value: int) -> void:
    CompanyEconomy.set_contract_deck_index(world, value)


static func get_day_index(world: Node) -> int:
    return CompanyEconomy.get_day_index(world)


static func set_day_index(world: Node, value: int) -> void:
    CompanyEconomy.set_day_index(world, value)


static func is_bankrupt(world: Node) -> bool:
    return CompanyEconomy.is_bankrupt(world)


static func set_bankrupt(world: Node, value: bool) -> void:
    CompanyEconomy.set_bankrupt(world, value)


static func get_overworld_step_count(world: Node) -> int:
    return CompanyEconomy.get_overworld_step_count(world)


static func get_wage_per_member(world: Node) -> int:
    return CompanyEconomy.get_wage_per_member(world)


static func wire_party_medical_supply(world: Node2D) -> void:
    CompanyEconomy.wire_party_medical_supply(world)


## === Roster helpers (delegated) ===

## === Roster helpers (delegated) ===


static func count_living_roster(world: Node) -> int:
    return CompanyEconomy.count_living_roster(world)


static func compute_next_wage_bill(world: Node) -> int:
    return CompanyEconomy.compute_next_wage_bill(world)


## === Tutorial / Contract meta (delegated to CompanyRoster) ===

## === Tutorial / Contract meta (delegated to CompanyRoster) ===


static func is_tutorial_completed(world: Node) -> bool:
    return CompanyRoster.is_tutorial_completed(world)


static func mark_tutorial_completed(world: Node) -> void:
    CompanyRoster.mark_tutorial_completed(world)


static func is_tutorial_contract(contract: Dictionary) -> bool:
    return CompanyRoster.is_tutorial_contract(contract)


static func set_map_bleed_mult(world: Node, mult: float) -> void:
    CompanyRoster.set_map_bleed_mult(world, mult)


static func get_map_bleed_mult(world: Node) -> float:
    return CompanyRoster.get_map_bleed_mult(world)


static func set_active_contract(world: Node, contract: Dictionary) -> void:
    CompanyRoster.set_active_contract(world, contract)


static func get_active_contract(world: Node) -> Dictionary:
    return CompanyRoster.get_active_contract(world)


static func has_active_campaign_contract(world: Node) -> bool:
    return CompanyRoster.has_active_campaign_contract(world)


static func is_campaign_contract_battle_world(world: Node) -> bool:
    return CompanyRoster.is_campaign_contract_battle_world(world)


static func clear_active_contract(world: Node) -> void:
    CompanyRoster.clear_active_contract(world)


static func get_last_battle_summary(world: Node) -> Dictionary:
    return CompanyRoster.get_last_battle_summary(world)


static func contract_loss_ends_run() -> bool:
    return CompanyRoster.contract_loss_ends_run()


static func defeat_should_end_company_run(contract: Dictionary) -> bool:
    return CompanyRoster.defeat_should_end_company_run(contract)


## === End day / Day cycle (delegated to CompanyDayCycle) ===

## === End day / Day cycle (delegated to CompanyDayCycle) ===


static func request_end_day(world: Node2D) -> bool:
    return CompanyDayCycle.request_end_day(world)


static func try_advance_day(world: Node2D) -> bool:
    return CompanyDayCycle.try_advance_day(world)


static func on_overworld_step(world: Node2D) -> void:
    CompanyDayCycle.on_overworld_step(world)


static func can_offer_end_day(world: Node2D) -> bool:
    return CompanyDayCycle.can_offer_end_day(world)


static func on_day_tick(world: Node2D) -> void:
    CompanyDayCycle.on_day_tick(world)


static func _run_daily_desertion_pass(world: Node2D) -> void:
    CompanyDayCycle._run_daily_desertion_pass(world)


## === Camp healing (delegated to CompanyCamp) ===

## === Camp healing (delegated to CompanyCamp) ===


static func can_offer_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool:
    return CompanyCamp.can_offer_camp_heal(world, from_party_menu)


static func camp_heal_ready(world: Node2D, from_party_menu: bool = false) -> bool:
    return CompanyCamp.camp_heal_ready(world, from_party_menu)


static func try_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool:
    return CompanyCamp.try_camp_heal(world, from_party_menu)


## === Tool repair (delegated to CompanyCamp) ===

## === Tool repair (delegated to CompanyCamp) ===


static func roster_has_repairable_wounds(world: Node2D) -> bool:
    return CompanyCamp.roster_has_repairable_wounds(world)


static func can_offer_settlement_tool_repair(world: Node2D) -> bool:
    return CompanyCamp.can_offer_settlement_tool_repair(world)


static func apply_settlement_tool_repair(world: Node2D) -> bool:
    return CompanyCamp.apply_settlement_tool_repair(world)


## === Hire (delegated to CompanyRoster) ===

## === Hire (delegated to CompanyRoster) ===


static func roster_has_hire_room(world: Node) -> bool:
    return CompanyRoster.roster_has_hire_room(world)


static func can_offer_hire(world: Node2D, from_party_menu: bool = false) -> bool:
    return CompanyRoster.can_offer_hire(world, from_party_menu)


static func should_show_party_hire_button(world: Node2D) -> bool:
    return CompanyRoster.should_show_party_hire_button(world)


static func format_hire_button_label(_world: Node = null) -> String:
    return CompanyRoster.format_hire_button_label(_world)


static func format_hire_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
    return CompanyRoster.format_hire_block_reason(world, from_party_menu)


static func format_hire_tooltip(world: Node2D, from_party_menu: bool = false) -> String:
    return CompanyRoster.format_hire_tooltip(world, from_party_menu)


static func try_hire_rookie(world: Node2D, rng: RandomNumberGenerator = null, from_party_menu: bool = false) -> bool:
    return CompanyRoster.try_hire_rookie(world, rng, from_party_menu)


## === Burial / Casualties (delegated to CompanyRoster) ===

## === Burial / Casualties (delegated to CompanyRoster) ===


static func count_last_battle_deaths(world: Node) -> int:
    return CompanyRoster.count_last_battle_deaths(world)


static func compute_settlement_burial_cost(world: Node) -> int:
    return CompanyRoster.compute_settlement_burial_cost(world)


static func format_settlement_burial_debt_warning(world: Node2D, gold_before: int = -1) -> String:
    return CompanyRoster.format_settlement_burial_debt_warning(world, gold_before)


static func apply_settlement_burial_costs(world: Node2D) -> PackedStringArray:
    return CompanyRoster.apply_settlement_burial_costs(world)


static func apply_casualty_cleanup(world: Node2D) -> PackedStringArray:
    return CompanyRoster.apply_casualty_cleanup(world)


static func format_last_battle_death_lines(world: Node) -> PackedStringArray:
    return CompanyRoster.format_last_battle_death_lines(world)


static func format_death_recap_suffix(death: Dictionary) -> String:
    return CompanyRoster.format_death_recap_suffix(death)


## === Mood management (delegated to CompanyMood) ===

## === Mood management (delegated to CompanyMood) ===


static func adjust_member_mood(world: Node, member_name: String, delta: float) -> void:
    CompanyMood.adjust_member_mood(world, member_name, delta)


static func apply_camp_rest_mood(world: Node) -> void:
    CompanyMood.apply_camp_rest_mood(world)


static func stance_preference_for_campaign_mood(mood: float) -> String:
    return CompanyMood.stance_preference_for_campaign_mood(mood)


static func apply_battle_lost_mood(world: Node) -> void:
    CompanyMood.apply_battle_lost_mood(world)


static func apply_battle_death_witness_mood(world: Node, death_count: int) -> void:
    CompanyMood.apply_battle_death_witness_mood(world, death_count)


static func count_desertion_risk_roster(world: Node) -> int:
    return CompanyMood.count_desertion_risk_roster(world)


static func format_party_desertion_risk_footer(world: Node2D) -> String:
    return CompanyMood.format_party_desertion_risk_footer(world)


## === Contract victory (delegated to CompanyRoster) ===

## === Contract victory (delegated to CompanyRoster) ===


static func apply_contract_victory_pay(world: Node) -> int:
    return CompanyRoster.apply_contract_victory_pay(world)


## === Field care status (delegated to CompanyCamp) ===

## === Field care status (delegated to CompanyCamp) ===


static func format_field_bandage_dress_note(world: Node2D) -> String:
    return CompanyCamp.format_field_bandage_dress_note(world)


static func format_field_care_march_chain() -> String:
    return CompanyCamp.format_field_care_march_chain()


static func format_field_care_shortfall_suffix(world: Node2D) -> String:
    return CompanyCamp.format_field_care_shortfall_suffix(world)


static func compute_field_treatment_effectiveness(entity: Node, world: Node2D, stabilize_floor: bool) -> float:
    return CompanyCamp.compute_field_treatment_effectiveness(entity, world, stabilize_floor)


static func format_field_bandage_med_bit(world: Node2D, entity: Node = null) -> String:
    return CompanyCamp.format_field_bandage_med_bit(world, entity)


static func format_post_fight_field_care_short_log(parts_left: int) -> String:
    return CompanyCamp.format_post_fight_field_care_short_log(parts_left)


static func format_post_fight_field_care_world_log(world: Node2D) -> String:
    return CompanyCamp.format_post_fight_field_care_world_log(world)


static func roster_recently_needed_field_dressing(world: Node2D) -> bool:
    return CompanyCamp.roster_recently_needed_field_dressing(world)


static func should_show_party_camp_rest_button(world: Node2D) -> bool:
    return CompanyCamp.should_show_party_camp_rest_button(world)


## === UI formatting (uses module functions internally) ===

## === UI formatting (uses module functions internally) ===


static func format_end_day_tooltip(world: Node2D) -> String:
    if world == null:
        return "Pay wages and consume daily rations."
    var tips: PackedStringArray = PackedStringArray(
        [
            "Pay wages and consume daily rations for each living brother.",
        ]
    )
    for hint in CompanyEconomy.format_hud_economy_hint_lines(get_state(world), count_living_roster(world), world):
        tips.append(hint)
    var desertion_hint: String = format_party_desertion_risk_footer(world)
    if not desertion_hint.is_empty():
        tips.append(desertion_hint)
    return " ".join(tips)


static func format_camp_rest_tooltip(world: Node2D) -> String:
    if world == null:
        return "Heal wounds, advance the day, and boost mood."
    var tips: PackedStringArray = PackedStringArray(
        [
            "Heal all dressed brothers, advance the day, and grant +1 mood (tavern rest).",
        ]
    )
    for hint in CompanyEconomy.format_hud_economy_hint_lines(get_state(world), count_living_roster(world), world):
        tips.append(hint)
    return " ".join(tips)


static func format_new_company_button_label() -> String:
    return "Start new company (testing)"


static func can_offer_new_campaign_from_menu() -> bool:
    return persistence_restore_on_main_restart()


static func request_new_campaign(world: Node2D) -> void:
    if world == null or world.get_tree() == null:
        return
    CampaignPersistence.clear_slot()
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world("campaign_boot fresh=true reason=user_new_company")
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
