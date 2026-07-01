class_name CompanyCamp
extends RefCounted

## CompanyCamp -- camp healing gates/execution, tool repair, field care formatting/status.

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _EntityProficiency := preload("res://core/EntityProficiency.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")

## CAMP_HEAL_ENTRY.
const CAMP_HEAL_ENTRY: String = "both"
## CAMP_HEAL_SECONDS.
const CAMP_HEAL_SECONDS: float = 600.0
## CAMP_HEAL_MULTIPLIER.
const CAMP_HEAL_MULTIPLIER: float = 3.0
## FIELD_CARE_MARCH_CHAIN.
const FIELD_CARE_MARCH_CHAIN: String = "pressure (free) -- bandage/pack/TQ"


# Runtime preload — circular dependency (CompanyState preloads CompanyCamp).
static var _company_state_cache: Variant = null

static func _get_state() -> GDScript:
	if _company_state_cache == null:
		_company_state_cache = load("res://world/CompanyState.gd")
	return _company_state_cache

static var _company_economy_cache: Variant = null
static func _get_economy() -> GDScript:
	if _company_economy_cache == null:
		_company_economy_cache = load("res://world/CompanyEconomy.gd")
	return _company_economy_cache

static var _company_mood_cache: Variant = null
static func _get_mood() -> GDScript:
	if _company_mood_cache == null:
		_company_mood_cache = load("res://world/CompanyMood.gd")
	return _company_mood_cache


static func format_field_bandage_dress_note(world: Node2D) -> String:
	if _get_economy().get_medical_supplies(world) >= 1:
		return "Field bandage (-1 med/part)"
	return "Field bandage (0 med / reduced efficacy)"


static func format_field_care_march_chain() -> String:
	return FIELD_CARE_MARCH_CHAIN


static func _try_apply_decay(world: Node2D) -> void:
	var day_index: int = _get_state().get_day_index(world)
	for n in _CampaignBridge.get_fightable_party_nodes(world):
		var entity: Node = _CampaignBridge.health_entity_from_character(n)
		if entity != null and entity.has_method("get_training_pending"):
			_EntityProficiency.apply_decay(entity, day_index)


static func _try_merge_training_pending(world: Node2D) -> void:
	for n in _CampaignBridge.get_fightable_party_nodes(world):
		var entity: Node = _CampaignBridge.health_entity_from_character(n)
		if entity != null and entity.has_method("get_training_pending") and entity.has_method("set_training_pending_value"):
			_EntityProficiency.merge_training_pending(entity)


static func camp_heal_ready(world: Node2D, from_party_menu: bool = false) -> bool:
	return can_offer_camp_heal(world, from_party_menu) and _party_bleeding_controlled(world)


static func format_camp_heal_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
	if not _party_bleeding_controlled(world):
		var parts: int = _CampaignBridge.party_untreated_part_count(world)
		if parts > 0:
			return (
				"Camp rest (%d part(s) need dressing -- Treat next wound or field care above, then retry)"
				% parts
			)
		return "Camp rest (dress wounds with Treat next wound or field care above first)"
	if _get_economy().get_medical_supplies(world) < 1:
		return "Camp rest (need 1 med after dressing)"
	if can_offer_camp_heal(world, from_party_menu):
		return format_camp_rest_button_label(world, from_party_menu)
	if _get_state().read_stub_camp_heal_entry() == "tile" and not _get_state()._player_on_camp_tile(world):
		return "Camp rest (stand on camp tile)"
	return "Camp rest (unavailable)"


static func format_party_triage_gate_line(world: Node2D) -> String:
	var budget: Dictionary = triage_med_budget(world)
	var parts_need: int = budget.get("parts_need", 0)
	var med_left: int = _get_economy().get_medical_supplies(world)
	var total_est: int = budget.get("total_worst_case", 0)
	var body: String = (
		(
			"%d part(s) need dressing -- Treat next wound (highest threat) or use each brother's care buttons. "
			+ "Order: %s, then %s. "
			+ "Up to %d med for dressings + camp rest (have %d)."
		)
		% [parts_need, format_field_care_march_chain(), format_field_bandage_dress_note(world), total_est, med_left]
	)
	return body + format_field_care_shortfall_suffix(world)


static func format_field_care_complete_line(world: Node2D) -> String:
	var mins: int = int(CAMP_HEAL_SECONDS / 60.0)
	var med_note: String = ""
	if world != null and _get_economy().get_medical_supplies(world) < 1:
		med_note = " Need 1 med to camp -- win contracts for resupply (+4 med)."
	return "All wounds dressed -- Camp rest unlocked (-1 med, %d min / +1 day / +1 mood).%s" % [mins, med_note]


static func format_settlement_field_care_hint(world: Node2D) -> String:
	if world == null or not _CampaignBridge.party_has_untreated_wounds(world):
		return ""
	var budget: Dictionary = triage_med_budget(world)
	var parts_need: int = budget.get("parts_need", 0)
	var total_est: int = budget.get("total_worst_case", 0)
	var med_left: int = _get_economy().get_medical_supplies(world)
	var hint: String = (
		(
			"Before the next fight: open Party on the map -- %s, then %s on %d part(s). "
			+ "Battle triage bandages are free; after Continue, finish dressing on the map, then Camp rest -- "
			+ "(-1 med / +1 day / +1 mood). Up to %d med for dressings + camp (have %d)."
		)
		% [
			format_field_care_march_chain(),
			format_field_bandage_dress_note(world),
			parts_need,
			total_est,
			med_left,
		]
	)
	return hint + format_field_care_shortfall_suffix(world)


static func triage_med_budget(world: Node2D) -> Dictionary:
	var parts_need: int = _CampaignBridge.party_untreated_part_count(world)
	var med_left: int = _get_economy().get_medical_supplies(world)
	var field_bandage_med: int = 0
	if med_left >= 1:
		field_bandage_med = parts_need
	var camp_med: int = 1
	var total: int = field_bandage_med + camp_med
	return {
		"parts_need": parts_need,
		"field_bandage_med_est": field_bandage_med,
		"camp_med": camp_med,
		"total_worst_case": total,
		"med_shortfall": maxi(0, total - med_left),
	}


static func format_field_care_shortfall_suffix(world: Node2D) -> String:
	var shortfall: int = triage_med_budget(world).get("med_shortfall", 0)
	if shortfall <= 0:
		return ""
	return (
		" Short %d med -- bandage at reduced efficacy or win contracts for resupply (+4 med)."
		% shortfall
	)


static func compute_field_treatment_effectiveness(
	entity: Node, world: Node2D, stabilize_floor: bool
) -> float:
	var supply: float = _get_economy().compute_medical_supply_factor(world)
	var skill: float = 1.0
	if entity != null and entity.has_method("get_medical_effectiveness"):
		skill = float(entity.get_medical_effectiveness())
		if entity.has_method("get_campaign_supply_factor"):
			var stamped: float = float(entity.get_campaign_supply_factor())
			if stamped > 0.001:
				skill /= stamped
	var eff: float = skill * supply
	if stabilize_floor:
		return clampf(maxf(eff, _CombatConstants.FIELD_CARE_STABILIZE_FLOOR), 0.25, 2.0)
	return clampf(eff, _CombatConstants.FIELD_CARE_EFF_MIN, _CombatConstants.FIELD_CARE_EFF_MAX)


static func format_field_bandage_med_bit(world: Node2D, entity: Node = null) -> String:
	if _get_economy().get_medical_supplies(world) >= 1:
		return "-1 med"
	var eff_pct: float = (
		compute_field_treatment_effectiveness(entity, world, false) * 100.0
		if entity != null
		else _get_economy().compute_medical_supply_factor(world) * 100.0
	)
	return "0 med / %.0f%% eff" % eff_pct


static func roster_recently_needed_field_dressing(world: Node2D) -> bool:
	if world == null:
		return false
	if _CampaignBridge.party_has_untreated_wounds(world):
		return true
	var summary: Dictionary = _get_state().get_last_battle_summary(world)
	var members: Variant = summary.get("members", [])
	if not (members is Array):
		return false
	for entry in members:
		if entry is not Dictionary:
			continue
		var snap: Dictionary = (entry as Dictionary).get("snapshot", entry) as Dictionary
		if snap.get("has_untreated_wounds") == true:
			return true
	return false


static func should_show_party_camp_rest_button(world: Node2D) -> bool:
	if world == null:
		return false
	if can_offer_camp_heal(world, true):
		return true
	if _get_economy().get_medical_supplies(world) >= 1:
		return true
	if _CampaignBridge.party_has_untreated_wounds(world):
		return true
	if not _party_bleeding_controlled(world):
		return false
	if _get_economy().get_medical_supplies(world) >= 1:
		return false
	var entry: String = _get_state().read_stub_camp_heal_entry()
	if entry != "party_menu" and entry != "both":
		return false
	return roster_recently_needed_field_dressing(world)


static func can_offer_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool:
	if _get_economy().get_medical_supplies(world) < 1:
		return false
	var entry: String = _get_state().read_stub_camp_heal_entry()
	if entry == "party_menu":
		return true
	if from_party_menu and entry == "both":
		return true
	if entry == "tile" or entry == "both":
		return _get_state()._player_on_camp_tile(world)
	return false


static func format_camp_rest_button_label(world: Node2D, from_party_menu: bool = false) -> String:
	var save_bit: String = _get_state().format_autosave_action_suffix()
	if world == null:
		return "Camp rest (-1 med / +1 day / +1 mood)%s" % save_bit
	if can_offer_camp_heal(world, from_party_menu):
		return (
			"Camp rest (-1 med / +1 day / +1 mood)%s%s%s"
			% [
				save_bit,
				_get_state().format_wage_day_tick_suffix(world),
				_get_state().format_provisions_day_tick_suffix(world),
			]
		)
	return "Camp rest (-1 med / +1 day)"


static func try_camp_heal(world: Node2D, from_party_menu: bool = false) -> bool:
	if not can_offer_camp_heal(world, from_party_menu):
		return false
	if not _party_bleeding_controlled(world):
		if _OperationalLog.is_play_session_active():
			var parts: int = _CampaignBridge.party_untreated_part_count(world)
			var block: String = format_camp_heal_block_reason(world, from_party_menu)
			_OperationalLog.play_world("camp_heal blocked: %s parts_need=%d" % [block, parts])
		return false
	if not _get_economy().consume_medical(world, 1):
		return false
	var day_before: int = _get_state().get_day_index(world)
	_advance_party_healing(world, CAMP_HEAL_SECONDS, CAMP_HEAL_MULTIPLIER)
	_get_state().try_advance_day(world)
	_try_apply_decay(world)
	_try_merge_training_pending(world)
	_get_mood().apply_camp_rest_mood(world)
	_get_state().refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"camp_heal seconds=%.0f mult=%.1f med_left=%d day=%d->%d all_dressed=true mood=+%.0f"
			% [
				CAMP_HEAL_SECONDS,
				CAMP_HEAL_MULTIPLIER,
				_get_economy().get_medical_supplies(world),
				day_before,
				_get_state().get_day_index(world),
				_get_mood().MOOD_CAMP_REST_DELTA,
			]
		)
	return true


static func roster_has_repairable_wounds(world: Node2D) -> bool:
	for n in _CampaignBridge.get_fightable_party_nodes(world):
		var entity: Node = _CampaignBridge.health_entity_from_character(n)
		if entity == null:
			continue
		if entity.has_method("get_wounded_parts") and not entity.get_wounded_parts().is_empty():
			return true
	return false


static func can_offer_settlement_tool_repair(world: Node2D) -> bool:
	return _get_economy().get_tool_supplies(world) >= 1 and roster_has_repairable_wounds(world)


static func apply_settlement_tool_repair(world: Node2D) -> bool:
	if not can_offer_settlement_tool_repair(world):
		return false
	if not _get_economy().consume_tool(world, 1):
		return false
	_advance_party_healing(world, 120.0, 1.5)
	_get_state().refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world("settlement_repair tools_left=%d" % _get_economy().get_tool_supplies(world))
	return true


static func _party_bleeding_controlled(world: Node2D) -> bool:
	return not _CampaignBridge.party_has_untreated_wounds(world)


static func _advance_party_healing(world: Node2D, seconds: float, multiplier: float) -> void:
	var effective: float = seconds * multiplier
	for n in _CampaignBridge.get_fightable_party_nodes(world):
		var entity: Node = _CampaignBridge.health_entity_from_character(n)
		if entity != null:
			if entity.has_method("process_bleeding"):
				entity.process_bleeding(effective)
			if entity.has_method("process_blood_loss"):
				entity.process_blood_loss(effective)
			if entity.has_method("process_healing"):
				entity.process_healing(effective)
		if n.has_method("ensure_consciousness_current"):
			n.ensure_consciousness_current()


static func format_post_fight_field_care_short_log(parts_left: int) -> String:
	return (
		"field_care: untreated wounds remain after battle triage parts_left=%d -- open Party on the map"
		% parts_left
	)


static func format_post_fight_field_care_world_log(world: Node2D) -> String:
	var budget: Dictionary = triage_med_budget(world)
	var parts: int = budget.get("parts_need", 0)
	var med_left: int = _get_economy().get_medical_supplies(world)
	var zero_med_note: String = ""
	if med_left <= 0:
		zero_med_note = "; 0-med bandages OK for map dressings"
	return (
		"field_care: open Party -- %s; %d part(s) need dressing; "
		+ "med_left=%d; bandage_med_est=%d; total_med_est=%d; med_shortfall=%d%s; "
		+ "battle bandages free; then Camp rest (-1 med / +1 day / +1 mood)"
	) % [
		format_field_care_march_chain(),
		parts,
		med_left,
		budget.get("field_bandage_med_est", 0),
		budget.get("total_worst_case", 0),
		budget.get("med_shortfall", 0),
		zero_med_note,
	]
