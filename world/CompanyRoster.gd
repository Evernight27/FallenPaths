class_name CompanyRoster
extends RefCounted

## CompanyRoster -- hire, burial, casualty cleanup, contract lifecycle.

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")

# Runtime preload -- circular dependency (CompanyState preloads CompanyRoster).
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

static var _party_setup_cache: Variant = null
static func _get_party_setup() -> GDScript:
	if _party_setup_cache == null:
		_party_setup_cache = load("res://world/PartySetup.gd")
	return _party_setup_cache

static var _company_camp_cache: Variant = null
static func _get_company_camp() -> GDScript:
	if _company_camp_cache == null:
		_company_camp_cache = load("res://world/CompanyCamp.gd")
	return _company_camp_cache


static func roster_has_hire_room(world: Node) -> bool:
	return _get_state().count_living_roster(world) < _get_state().ROSTER_MAX_LIVING


static func can_offer_hire(world: Node2D, from_party_menu: bool = false) -> bool:
	if world == null or not roster_has_hire_room(world):
		return false
	if _get_party_setup().find_vacant_companion_node(world) == null:
		return false
	if _get_state().get_gold(world) < _get_state().HIRE_GOLD_COST:
		return false
	var entry: String = _get_state().read_stub_hire_entry()
	if entry == "party_menu":
		return true
	if from_party_menu and entry == "both":
		return true
	if entry == "tile" or entry == "both":
		return _get_state()._player_on_camp_tile(world)
	return false


static func should_show_party_hire_button(world: Node2D) -> bool:
	return world != null and roster_has_hire_room(world)


static func format_hire_button_label(_world: Node = null) -> String:
	return "Hire rookie (-%dg)" % _get_state().HIRE_GOLD_COST


static func format_hire_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
	if not roster_has_hire_room(world):
		return "Hire (roster full -- %d/%d)" % [_get_state().count_living_roster(world), _get_state().ROSTER_MAX_LIVING]
	if _get_party_setup().find_vacant_companion_node(world) == null:
		return "Hire (no vacant slot)"
	if _get_state().get_gold(world) < _get_state().HIRE_GOLD_COST:
		return "Hire (need %dg /  have %dg)" % [_get_state().HIRE_GOLD_COST, _get_state().get_gold(world)]
	if can_offer_hire(world, from_party_menu):
		return format_hire_button_label(world)
	if _get_state().read_stub_hire_entry() == "tile" and not _get_state()._player_on_camp_tile(world):
		return "Hire (stand on camp tile)"
	return "Hire (unavailable)"


static func format_hire_tooltip(world: Node2D, from_party_menu: bool = false) -> String:
	if world == null or not roster_has_hire_room(world):
		return ""
	if can_offer_hire(world, from_party_menu):
		return "Recruit a rookie for -%dg (fills vacant companion slot)." % _get_state().HIRE_GOLD_COST
	return format_hire_block_reason(world, from_party_menu)


static func try_hire_rookie(
	world: Node2D, rng: RandomNumberGenerator = null, from_party_menu: bool = false
) -> bool:
	if not can_offer_hire(world, from_party_menu):
		return false
	var gold_before: int = _get_state().get_gold(world)
	if not _get_state().consume_gold(world, _get_state().HIRE_GOLD_COST):
		return false
	var roll: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		roll.randomize()
	var hired: Node = _get_party_setup().spawn_hire_companion(world, roll)
	if hired == null:
		_get_state().set_gold(world, gold_before)
		return false
	_get_state().refresh_hud(world)
	_get_state().try_autosave(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"hire_rookie name=%s gold=%d living=%d"
			% [hired.name, _get_state().get_gold(world), _get_state().count_living_roster(world)]
		)
	return true


static func set_active_contract(world: Node, contract: Dictionary) -> void:
	if world == null:
		return
	world.set_meta(_get_state().WORLD_META_ACTIVE_CONTRACT, contract.duplicate(true))


static func get_active_contract(world: Node) -> Dictionary:
	if world == null or not world.has_meta(_get_state().WORLD_META_ACTIVE_CONTRACT):
		return {}
	var raw: Variant = world.get_meta(_get_state().WORLD_META_ACTIVE_CONTRACT)
	return raw if raw is Dictionary else {}


static func has_active_campaign_contract(world: Node) -> bool:
	return not get_active_contract(world).is_empty()


static func is_campaign_contract_battle_world(world: Node) -> bool:
	return has_active_campaign_contract(world)


static func clear_active_contract(world: Node) -> void:
	if world != null and world.has_meta(_get_state().WORLD_META_ACTIVE_CONTRACT):
		world.remove_meta(_get_state().WORLD_META_ACTIVE_CONTRACT)


static func get_last_battle_summary(world: Node) -> Dictionary:
	if world == null or not world.has_meta(_get_state().WORLD_META_LAST_BATTLE_SUMMARY):
		return {}
	var raw: Variant = world.get_meta(_get_state().WORLD_META_LAST_BATTLE_SUMMARY)
	return raw if raw is Dictionary else {}


static func contract_loss_ends_run() -> bool:
	return _get_state().read_stub_encounter_lifecycle() == "r3_loss_ends_run"


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
	mark_tutorial_completed(world)
	if is_tutorial_contract(contract):
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"contract_victory tutorial -- no pay (type=%s)"
				% contract.get("contract_type", "")
			)
		return 0
	var base_pay: int = contract.get("pay_gold", 0)
	var renown_mult: float = 1.0 + float(_get_state().get_renown(world)) * _get_state().RENOWN_PAY_SCALE
	var int_mult: float = 1.0
	if _get_state().read_stub_proficiency_enabled():
		int_mult = _apply_int_contract_bonus(world)
	var scaled: int = int(round(float(base_pay) * renown_mult * int_mult))
	_get_state().add_gold(world, scaled)
	_get_state().set_renown(world, _get_state().get_renown(world) + 1)
	_get_state().set_medical_supplies(world, _get_state().get_medical_supplies(world) + _get_state().CONTRACT_VICTORY_MED_RESUPPLY)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"contract_victory pay=%d gold=%d renown=%d med_resupply=%d med=%d"
			% [scaled, _get_state().get_gold(world), _get_state().get_renown(world), _get_state().CONTRACT_VICTORY_MED_RESUPPLY, _get_state().get_medical_supplies(world)]
		)
		if world is Node2D:
			if _CampaignBridge.party_has_untreated_wounds(world as Node2D):
				var budget: Dictionary = CompanyState.triage_med_budget(world as Node2D)
				_OperationalLog.play_world(
					"contract_victory triage parts_need=%d med_shortfall=%d"
					% [budget.get("parts_need", 0), budget.get("med_shortfall", 0)]
				)
	return scaled


static func is_tutorial_contract(contract: Dictionary) -> bool:
	if contract.is_empty():
		return false
	if contract.get("tutorial") == true:
		return true
	return contract.get("contract_type", "") == "tutorial"


static func count_last_battle_deaths(world: Node) -> int:
	var summary: Dictionary = get_last_battle_summary(world)
	var deaths: Variant = summary.get("deaths", [])
	if deaths is Array:
		return (deaths as Array).size()
	return 0


static func compute_settlement_burial_cost(world: Node) -> int:
	if world == null or not _get_state().read_stub_burial_costs_enabled():
		return 0
	return count_last_battle_deaths(world) * _get_state().BURIAL_GOLD_COST


static func format_settlement_burial_debt_warning(world: Node2D, gold_before: int = -1) -> String:
	var cost: int = compute_settlement_burial_cost(world)
	if cost <= 0:
		return ""
	var gold: int = gold_before if gold_before >= 0 else _get_state().get_gold(world)
	if gold >= cost:
		return ""
	return (
		"Burial will cost %dg but you only have %dg -- debt is allowed (same as unpaid wages)."
		% [cost, gold]
	)


static func apply_settlement_burial_costs(world: Node2D) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if world == null or not _get_state().read_stub_burial_costs_enabled():
		return lines
	var deaths: int = count_last_battle_deaths(world)
	if deaths <= 0:
		return lines
	var cost: int = compute_settlement_burial_cost(world)
	var state: Dictionary = _get_state().get_state(world).duplicate()
	state["gold"] = state.get("gold", 0) - cost
	_get_state()._write_state(world, state)
	lines.append("Burial costs: -%dg (%d fallen -- %dg)" % [cost, deaths, _get_state().BURIAL_GOLD_COST])
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"burial_cost deaths=%d cost=%d gold=%d" % [deaths, cost, _get_state().get_gold(world)]
		)
	return lines


static func apply_casualty_cleanup(world: Node2D) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if _get_state().read_stub_casualty_on_settlement() != "memorial_then_remove":
		return lines
	var pm: Node = _get_state()._resolve_party_manager(world)
	if pm == null:
		return lines
	var summary: Dictionary = {}
	if world != null and world.has_meta(_get_state().WORLD_META_LAST_BATTLE_SUMMARY):
		var raw: Variant = world.get_meta(_get_state().WORLD_META_LAST_BATTLE_SUMMARY)
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
		lines.append("Memorial -- %s%s" % [name_s, recap])
		to_remove.append(name_s)
	for name_s in to_remove:
		if pm.has_method("remove_member_by_name"):
			pm.remove_member_by_name(name_s)
	return lines


static func _death_recap_for_name(member_name: String, deaths: Array) -> String:
	for d in deaths:
		if d is Dictionary and d.get("name", "") == member_name:
			return format_death_recap_suffix(d as Dictionary)
	return ""


static func format_last_battle_death_lines(world: Node) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var summary: Dictionary = get_last_battle_summary(world)
	var deaths: Variant = summary.get("deaths", [])
	if deaths is not Array:
		return lines
	for d in deaths:
		if d is not Dictionary:
			continue
		var name_s: String = str((d as Dictionary).get("name", "?"))
		var recap: String = format_death_recap_suffix(d as Dictionary)
		lines.append("Fallen -- %s%s" % [name_s, recap])
	return lines


static func format_death_recap_suffix(death: Dictionary) -> String:
	var part: String = death.get("part", "")
	var cause: String = death.get("cause", "")
	var killer: String = death.get("killer", "")
	var weapon: String = death.get("weapon", "")
	if part.is_empty() and cause.is_empty() and killer.is_empty():
		return ""
	var core: String = ""
	if not part.is_empty() and not cause.is_empty():
		core = "%s -- %s" % [part, cause]
	elif not part.is_empty():
		core = part
	elif not cause.is_empty():
		core = cause
	if killer.is_empty():
		return " (%s)" % core if not core.is_empty() else ""
	if weapon.is_empty():
		return " (%s; fell to %s)" % [core, killer] if not core.is_empty() else " (fell to %s)" % killer
	return " (%s; %s -- %s)" % [core, killer, weapon] if not core.is_empty() else " (%s -- %s)" % [killer, weapon]


static func is_tutorial_completed(world: Node) -> bool:
	var v = _get_state().get_state(world).get("tutorial_completed")
	return v is bool and v


static func mark_tutorial_completed(world: Node) -> void:
	var state: Dictionary = _get_state().get_state(world).duplicate()
	state["tutorial_completed"] = true
	_get_state()._write_state(world, state)


static func set_map_bleed_mult(world: Node, mult: float) -> void:
	if world == null:
		return
	world.set_meta(_get_state().WORLD_META_MAP_BLEED_MULT, clampf(mult, 0.05, 1.0))


static func get_map_bleed_mult(world: Node) -> float:
	if world == null or not world.has_meta(_get_state().WORLD_META_MAP_BLEED_MULT):
		return 1.0
	return clampf(float(world.get_meta(_get_state().WORLD_META_MAP_BLEED_MULT, 1.0)), 0.05, 1.0)


static func _apply_int_contract_bonus(world: Node) -> float:
	var best_mult: float = 1.0
	for n in _CampaignBridge.get_fightable_party_nodes(world):
		var entity: Node = _CampaignBridge.health_entity_from_character(n)
		if entity != null and entity.has_method("get_intelligence_contract_bonus_mult"):
			var m: float = entity.get_intelligence_contract_bonus_mult()
			if m > best_mult:
				best_mult = m
	return best_mult
