extends SceneTree

## Headless Camp-1 economy loop (1.1–1.8) + Camp-2 bridge spot checks.
## Run: Phase 0 / **`run_all_combat_checks.ps1`** (inline) · **`run_campaign_ship_audit.ps1`**
## Labels: Camp-1.x in failure messages map to SHIP_PLAN § Camp-1.

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _MapBleedPolicy := preload("res://world/MapBleedPolicy.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _Snapshot := preload("res://world/PartyMemberSnapshot.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _ContractSpawner := preload("res://world/ContractSpawner.gd")
const _EncounterNodeScript := preload("res://world/EncounterNode.gd")
const _CoreEntityScript := preload("res://core/CoreEntity.gd")
const _CampaignWorldScript := preload("res://scripts/_harness_campaign_world.gd")
const _Persistence := preload("res://world/CampaignPersistence.gd")
const _EncounterSpawner := preload("res://world/EncounterSpawner.gd")
const HARNESS_NAME := "CompanyStateChecks"
const _CompanyHud := preload("res://ui/CompanyHud.gd")
const _CombatFlow := preload("res://world/CombatFlow.gd")
const _PartySetup := preload("res://world/PartySetup.gd")

static var _test_count: int = 0
static var _party_manager_script: Script = load(ResourcePaths.PARTY_MANAGER) as Script


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	var failures: PackedStringArray = PackedStringArray()
	_run_camp_1_1_company_state(failures)
	_run_camp_1_2_wages_and_day(failures)
	_run_camp_1_3_supply_pools(failures)
	_run_camp_1_3_settlement_tool_repair(failures)
	_run_camp_1_4_contracts(failures)
	_run_camp_1_5_settlement_data(failures)
	_run_camp_1_6_camp_heal(failures)
	_run_camp_1_7_renown_scaling(failures)
	_run_camp_1_8_roster_cleanup(failures)
	_run_camp_2_bridge_spot_checks(failures)
	_run_camp_3_player_front_count_encounter(failures)
	_run_persistence_roundtrip(failures)
	if failures.is_empty():
		quit(_OperationalLog.harness_ok(HARNESS_NAME, "(%d tests)" % _test_count))
	else:
		quit(_OperationalLog.harness_fail(HARNESS_NAME, failures, "(%d tests)" % _test_count))


static func _fail(failures: PackedStringArray, msg: String) -> void:
	failures.append(msg)


static func _pass() -> void:
	_test_count += 1


static func _make_world(living_count: int, dead_count: int = 0, in_tree: bool = false) -> Node2D:
	var world := Node2D.new()
	world.set_script(_CampaignWorldScript)
	var pm_script: Script = load("res://PartyManager.gd") as Script
	var pm: Node = pm_script.new()
	pm.name = "PartyManagerHarness"
	world.add_child(pm)
	for i in living_count + dead_count:
		var n := Node2D.new()
		n.name = "Brother%d" % i
		if i >= living_count:
			n.set_script(load("res://scripts/_harness_dead_stub.gd"))
		pm.members.append({"name": n.name, "node_ref": n})
	world.set_meta("party_manager", pm)
	_CompanyState.init_from_defaults(world)
	if in_tree:
		Engine.get_main_loop().root.add_child(world)
	return world


static func _add_player_at_camp(world: Node2D) -> Node2D:
	var player := Node2D.new()
	player.name = "Character"
	player.position = Vector2(32, 32)
	world.add_child(player)
	return player


static func _add_living_entity_member(pm: Node, member_name: String) -> Node:
	var ent: Node = _CoreEntityScript.new()
	ent.name = member_name
	ent.apply_species()
	pm.members.append(
		{
			"name": member_name,
			"node_ref": ent,
			"company_mood": 50.0,
		}
	)
	return ent


# --- Camp-1.1 ---

static func _run_camp_1_1_company_state(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1)
	var state: Dictionary = _CompanyState.get_state(world)
	if int(state.get("gold", -1)) != _CompanyState.DEFAULT_GOLD:
		_fail(failures, "Camp-1.1: gold want %d got %s" % [_CompanyState.DEFAULT_GOLD, state.get("gold")])
	else:
		_pass()
	if int(state.get("medical_supplies", -1)) != _CompanyState.DEFAULT_MEDICAL_SUPPLIES:
		_fail(
			failures,
			"Camp-1.1: med want %d got %s"
			% [_CompanyState.DEFAULT_MEDICAL_SUPPLIES, state.get("medical_supplies")]
		)
	else:
		_pass()
	if int(state.get("tool_supplies", -1)) != _CompanyState.DEFAULT_TOOL_SUPPLIES:
		_fail(
			failures,
			"Camp-1.1: tools want %d got %s"
			% [_CompanyState.DEFAULT_TOOL_SUPPLIES, state.get("tool_supplies")]
		)
	else:
		_pass()
	if int(state.get("renown", -1)) != _CompanyState.DEFAULT_RENOWN:
		_fail(failures, "Camp-1.1: renown want 0 got %s" % state.get("renown"))
	else:
		_pass()
	if bool(state.get("bankrupt", true)):
		_fail(failures, "Camp-1.1: bankrupt should start false")
	else:
		_pass()
	if _CompanyState.WORLD_META_COMPANY_STATE != "company_state":
		_fail(failures, "Camp-1.1: company_state meta key")
	else:
		_pass()
	world.free()

	var world_hud: Node2D = _make_world(1, 0, true)
	_CompanyState.attach_to_world(world_hud)
	if not world_hud.has_meta(_CompanyState.WORLD_META_COMPANY_HUD):
		_fail(failures, "Camp-1.1: attach_to_world should create company HUD meta")
	else:
		_pass()
	var hud: Control = world_hud.get_meta(_CompanyState.WORLD_META_COMPANY_HUD) as Control
	if hud == null or not hud.has_method("refresh_from_state"):
		_fail(failures, "Camp-1.1: company HUD missing refresh_from_state")
	else:
		_pass()
	var gold_after_encounter: int = _CompanyState.get_gold(world_hud)
	_CompanyState.add_gold(world_hud, 77)
	if _CompanyState.get_gold(world_hud) != gold_after_encounter + 77:
		_fail(failures, "Camp-1.1: gold should persist in company_state meta")
	else:
		_pass()
	if hud is _CompanyHud:
		var gold_lbl: Label = (hud as _CompanyHud)._gold_label
		if gold_lbl == null or not str(gold_lbl.text).contains(str(gold_after_encounter + 77)):
			_fail(failures, "Camp-1.1: HUD gold label want %d got '%s'" % [gold_after_encounter + 77, gold_lbl.text])
		else:
			_pass()
	world_hud.queue_free()


# --- Camp-1.2 ---

static func _run_camp_1_2_wages_and_day(failures: PackedStringArray) -> void:
	if _CompanyState.gate_day_tick_mode() != "hybrid":
		_fail(failures, "Camp-1.2: day_tick_mode want hybrid")
	else:
		_pass()
	var world: Node2D = _make_world(2)
	var steps: int = _CompanyState.gate_steps_per_day()
	var bill: int = _CompanyState.compute_next_wage_bill(world)
	for _i in steps:
		_CompanyState.on_overworld_step(world)
	if _CompanyState.get_day_index(world) != 1:
		_fail(
			failures,
			"Camp-1.2: day_index want 1 got %d after %d steps" % [_CompanyState.get_day_index(world), steps]
		)
	else:
		_pass()
	var want_gold: int = _CompanyState.DEFAULT_GOLD - bill
	if _CompanyState.get_gold(world) != want_gold:
		_fail(
			failures,
			"Camp-1.2: gold want %d got %d (bill=%d living=2)" % [want_gold, _CompanyState.get_gold(world), bill]
		)
	else:
		_pass()
	if _CompanyState.get_overworld_step_count(world) != 0:
		_fail(failures, "Camp-1.2: step count should reset after day advance")
	else:
		_pass()
	world.free()

	var world_dead: Node2D = _make_world(1, 1)
	if _CompanyState.compute_next_wage_bill(world_dead) != _CompanyState.DEFAULT_WAGE_PER_MEMBER:
		_fail(failures, "Camp-1.2: dead brother excluded from wage bill")
	else:
		_pass()
	world_dead.free()

	var world_hybrid: Node2D = _make_world(1, 0, true)
	_add_player_at_camp(world_hybrid)
	if _CompanyState.request_end_day(world_hybrid):
		_fail(failures, "Camp-1.2: hybrid end_day off camp should fail")
	else:
		_pass()
	world_hybrid.get_node("Character").position = Vector2(192, 192)
	if _CompanyState.request_end_day(world_hybrid):
		_fail(failures, "Camp-1.2: hybrid end_day still off camp at (3,3)")
	else:
		_pass()
	world_hybrid.get_node("Character").position = Vector2(32, 32)
	var gold_before: int = _CompanyState.get_gold(world_hybrid)
	if not _CompanyState.request_end_day(world_hybrid):
		_fail(failures, "Camp-1.2: hybrid end_day on camp should succeed")
	else:
		_pass()
	if _CompanyState.get_gold(world_hybrid) != gold_before - _CompanyState.DEFAULT_WAGE_PER_MEMBER:
		_fail(failures, "Camp-1.2: end_day on camp should deduct one living wage")
	else:
		_pass()
	_Persistence.clear_slot()
	_CompanyState.set_gold(world_hybrid, 400)
	if not _CompanyState.request_end_day(world_hybrid):
		_fail(failures, "Camp-1.2: second end_day for autosave probe should succeed")
	else:
		_pass()
	if not _Persistence.has_save():
		_fail(failures, "Camp-1.2: end_day should write autosave via try_advance_day")
	else:
		_pass()
	world_hybrid.queue_free()

	var hint_state: Dictionary = {
		"gold": 20,
		"wage_per_member": _CompanyState.DEFAULT_WAGE_PER_MEMBER,
	}
	if not _CompanyState.should_show_next_wage_hint(hint_state, 2):
		_fail(failures, "Camp-1.2: wage hint when gold below bill")
	else:
		_pass()
	hint_state["gold"] = 100
	if _CompanyState.should_show_next_wage_hint(hint_state, 2):
		_fail(failures, "Camp-1.2: no wage hint when gold sufficient")
	else:
		_pass()


# --- Camp-1.3 ---

static func _run_camp_1_3_supply_pools(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1)
	if not _CompanyState.consume_medical(world, 1):
		_fail(failures, "Camp-1.3: consume_medical should succeed")
	else:
		_pass()
	if _CompanyState.get_medical_supplies(world) != 2:
		_fail(failures, "Camp-1.3: med supplies want 2 got %d" % _CompanyState.get_medical_supplies(world))
	else:
		_pass()
	if _CompanyState.consume_medical(world, 99):
		_fail(failures, "Camp-1.3: consume_medical should fail when insufficient")
	else:
		_pass()
	if not _CompanyState.consume_tool(world, 1):
		_fail(failures, "Camp-1.3: consume_tool should succeed")
	else:
		_pass()
	if _CompanyState.get_tool_supplies(world) != 1:
		_fail(failures, "Camp-1.3: tool supplies want 1 got %d" % _CompanyState.get_tool_supplies(world))
	else:
		_pass()
	if _CompanyState.consume_tool(world, 5):
		_fail(failures, "Camp-1.3: consume_tool should fail when insufficient")
	else:
		_pass()
	world.free()


# --- Camp-1.4 ---

static func _run_camp_1_4_contracts(failures: PackedStringArray) -> void:
	if _CompanyState.gate_encounter_lifecycle() != "r3_loss_ends_run":
		_fail(failures, "Camp-1.4: encounter lifecycle want r3_loss_ends_run")
	else:
		_pass()
	if not _CompanyState.contract_loss_ends_run():
		_fail(failures, "Camp-1.4: contract_loss_ends_run should be true")
	else:
		_pass()
	if _ContractSpawner.get_template_count() < 2:
		_fail(failures, "Camp-1.4: need >= 2 contract templates")
	else:
		_pass()

	var world: Node2D = _make_world(1)
	_CompanyState.mark_tutorial_completed(world)
	var gold_before: int = _CompanyState.get_gold(world)
	_CompanyState.set_active_contract(
		world,
		{
			"contract_title": "Border Skirmish",
			"pay_gold": 100,
			"difficulty_rating": 1,
			"contract_type": "skirmish",
		}
	)
	var paid: int = _CompanyState.apply_contract_victory_pay(world)
	if paid != 100:
		_fail(failures, "Camp-1.4: first contract pay want 100 got %d" % paid)
	else:
		_pass()
	if _CompanyState.get_gold(world) != gold_before + 100:
		_fail(failures, "Camp-1.4: gold should increase by contract pay on win")
	else:
		_pass()
	if _CompanyState.get_renown(world) != 1:
		_fail(failures, "Camp-1.4: renown +1 after contract win")
	else:
		_pass()
	_CompanyState.set_active_contract(world, {"pay_gold": 100, "contract_type": "skirmish"})
	_CompanyState.set_renown(world, 2)
	var paid2: int = _CompanyState.apply_contract_victory_pay(world)
	var want_scaled: int = int(round(100.0 * (1.0 + 2.0 * _CompanyState.RENOWN_PAY_SCALE)))
	if paid2 != want_scaled:
		_fail(failures, "Camp-1.4: scaled pay want %d got %d" % [want_scaled, paid2])
	else:
		_pass()
	world.free()

	var world_loss: Node2D = _make_world(1)
	_CompanyState.mark_tutorial_completed(world_loss)
	var g0: int = _CompanyState.get_gold(world_loss)
	_CompanyState.set_active_contract(world_loss, {"pay_gold": 200, "contract_type": "skirmish"})
	_CompanyState.clear_active_contract(world_loss)
	if _CompanyState.get_gold(world_loss) != g0:
		_fail(failures, "Camp-1.4: loss path (clear contract) must not grant pay")
	else:
		_pass()
	world_loss.free()

	var enc: Node2D = _EncounterNodeScript.new()
	enc.encounter_config = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[0])
	var bridge_world: Node2D = _make_world(1)
	_CampaignBridge.prepare_combat_from_encounter(bridge_world, enc)
	var active: Dictionary = _CompanyState.get_active_contract(bridge_world)
	if str(active.get("contract_title", "")).is_empty():
		_fail(failures, "Camp-1.4: prepare_combat should stash active_contract")
	else:
		_pass()
	if int(active.get("pay_gold", -1)) != int(_ContractSpawner.CONTRACT_TEMPLATES[0].get("pay_gold", 0)):
		_fail(failures, "Camp-1.4: active_contract pay_gold mismatch")
	else:
		_pass()
	bridge_world.free()
	enc.free()

	var label: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[0])
	if not label.contains("100") or not label.contains("★"):
		_fail(failures, "Camp-1.4: marker label should show pay and difficulty")
	else:
		_pass()
	var world_renown: Node2D = _make_world(1)
	_CompanyState.set_renown(world_renown, 2)
	var scaled_lbl: String = _ContractSpawner.format_marker_label(
		_ContractSpawner.CONTRACT_TEMPLATES[0], world_renown
	)
	if not scaled_lbl.contains("renown"):
		_fail(failures, "Camp-1.4: marker should show renown-scaled pay hint")
	else:
		_pass()
	world_renown.free()

	var recap: String = _CompanyState.format_death_recap_suffix(
		{
			"part": "chest",
			"cause": "hemorrhage",
			"killer": "Goblin",
			"weapon": "Rusty sword",
		}
	)
	if not recap.contains("Goblin") or not recap.contains("Rusty"):
		_fail(failures, "Camp-1.8: death recap should include killer and weapon")
	else:
		_pass()

	var kill_world: Node2D = _make_world(0, 1)
	_CampaignBridge.record_battle_kill(kill_world, "Brother0", "Raider", "Axe", "head")
	_CampaignBridge.build_last_battle_summary(kill_world)
	var deaths: Array = _CompanyState.get_last_battle_summary(kill_world).get("deaths", [])
	if deaths.is_empty() or str((deaths[0] as Dictionary).get("killer", "")) != "Raider":
		_fail(failures, "Camp-1.8: battle kill log should merge into last_battle_summary")
	else:
		_pass()
	kill_world.free()

	var defeat_world: Node2D = _make_world(0, 1)
	_CampaignBridge.record_battle_kill(defeat_world, "Brother0", "Raider", "Spear", "chest")
	_CampaignBridge.build_last_battle_summary(defeat_world, "enemy")
	var loss_summary: Dictionary = _CompanyState.get_last_battle_summary(defeat_world)
	if str(loss_summary.get("winner", "")) != "enemy":
		_fail(failures, "Camp-1.8: defeat summary should record battle winner")
	else:
		_pass()
	var loss_lines: PackedStringArray = _CompanyState.format_last_battle_death_lines(defeat_world)
	if loss_lines.is_empty() or not str(loss_lines[0]).contains("Raider"):
		_fail(failures, "Camp-1.8: defeat death lines should include killer recap")
	else:
		_pass()
	defeat_world.free()

	var defeat_live: Node2D = _make_world(1)
	_CampaignBridge.record_battle_kill(defeat_live, "Brother0", "Orc", "Axe", "head")
	_CampaignBridge.build_last_battle_summary(defeat_live, "enemy")
	var live_deaths: Array = _CompanyState.get_last_battle_summary(defeat_live).get("deaths", [])
	if live_deaths.is_empty() or str((live_deaths[0] as Dictionary).get("killer", "")) != "Orc":
		_fail(failures, "Camp-1.8: defeat should merge kill log when roster not yet is_dead")
	else:
		_pass()
	defeat_live.free()

	var tut_contract: Dictionary = {"tutorial": true, "contract_type": "tutorial"}
	if _CompanyState.defeat_should_end_company_run(tut_contract):
		_fail(failures, "Camp-1.4: tutorial loss must not end company run")
	else:
		_pass()
	var practice_contract: Dictionary = {"training": true, "contract_type": "practice"}
	if _CompanyState.defeat_should_end_company_run(practice_contract):
		_fail(failures, "Camp-1.4: practice loss must not end company run")
	else:
		_pass()
	var paid_contract: Dictionary = {"pay_gold": 100, "contract_type": "skirmish"}
	if not _CompanyState.defeat_should_end_company_run(paid_contract):
		_fail(failures, "Camp-1.4: paid contract loss should end run (R3)")
	else:
		_pass()


# --- Camp-1.5 ---

static func _run_camp_1_3_settlement_tool_repair(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1)
	var pm: Node = world.get_meta("party_manager")
	var ent: Node = _add_living_entity_member(pm, "Gear")
	if ent.has_method("get_wounded_parts"):
		ent.wounds["chest"] = [{"current_bleeding_rate": 0.1}]
	if not _CompanyState.can_offer_settlement_tool_repair(world):
		_fail(failures, "Camp-1.3: should offer tool repair when wounded + tools")
	else:
		_pass()
	if not _CompanyState.apply_settlement_tool_repair(world):
		_fail(failures, "Camp-1.3: tool repair should succeed")
	else:
		_pass()
	if _CompanyState.get_tool_supplies(world) != 1:
		_fail(failures, "Camp-1.3: tool repair should consume 1 tool")
	else:
		_pass()
	world.free()


static func _run_camp_1_5_settlement_data(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1)
	var pm: Node = world.get_meta("party_manager")
	_add_living_entity_member(pm, "Survivor")
	_CampaignBridge.build_last_battle_summary(world)
	var summary: Dictionary = _CompanyState.get_last_battle_summary(world)
	var members: Variant = summary.get("members", [])
	if not (members is Array) or (members as Array).is_empty():
		_fail(failures, "Camp-1.5: last_battle_summary should list living members")
	else:
		_pass()
	var entry: Dictionary = (members as Array)[0]
	var snap: Dictionary = entry.get("snapshot", {})
	if float(snap.get("blood_volume", -1)) < 0:
		_fail(failures, "Camp-1.5: snapshot missing blood_volume")
	else:
		_pass()
	world.free()


# --- Camp-1.6 ---

static func _run_camp_1_6_camp_heal(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(0, 0, true)
	var pm: Node = world.get_meta("party_manager")
	_add_living_entity_member(pm, "Wounded")
	_add_player_at_camp(world)
	_CompanyState.set_medical_supplies(world, 0)
	if _CompanyState.try_camp_heal(world):
		_fail(failures, "Camp-1.6: camp heal must fail at 0 med")
	else:
		_pass()
	_CompanyState.set_medical_supplies(world, 2)
	var day_before: int = _CompanyState.get_day_index(world)
	if not _CompanyState.try_camp_heal(world):
		_fail(failures, "Camp-1.6: camp heal should succeed on camp with med")
	else:
		_pass()
	if _CompanyState.get_medical_supplies(world) != 1:
		_fail(failures, "Camp-1.6: camp heal should consume 1 med")
	else:
		_pass()
	if _CompanyState.get_day_index(world) != day_before + 1:
		_fail(
			failures,
			"Camp-1.6: camp heal should advance day (got %d want %d)"
			% [_CompanyState.get_day_index(world), day_before + 1]
		)
	else:
		_pass()
	world.queue_free()

	var world_menu: Node2D = _make_world(0, 0, true)
	var pm2: Node = world_menu.get_meta("party_manager")
	_add_living_entity_member(pm2, "Field")
	_add_player_at_camp(world_menu)
	world_menu.get_node("Character").position = Vector2(192, 192)
	_CompanyState.set_medical_supplies(world_menu, 2)
	if not _CompanyState.can_offer_camp_heal(world_menu, true):
		_fail(failures, "Camp-1.6: party menu camp heal should be offered (H3 both)")
	else:
		_pass()
	var day_menu_before: int = _CompanyState.get_day_index(world_menu)
	if not _CompanyState.try_camp_heal(world_menu, true):
		_fail(failures, "Camp-1.6: party menu camp heal should succeed off camp tile")
	else:
		_pass()
	if _CompanyState.get_day_index(world_menu) != day_menu_before + 1:
		_fail(
			failures,
			"Camp-1.6: party menu camp heal off camp should still advance day (got %d want %d)"
			% [_CompanyState.get_day_index(world_menu), day_menu_before + 1]
		)
	else:
		_pass()
	_Persistence.clear_slot()
	var day_save_before: int = _CompanyState.get_day_index(world_menu)
	if not _CompanyState.try_camp_heal(world_menu, true):
		_fail(failures, "Camp-1.6: second camp heal for autosave probe should succeed")
	else:
		_pass()
	if not _Persistence.has_save():
		_fail(failures, "Camp-1.6: camp rest should write autosave via try_advance_day")
	else:
		_pass()
	var loaded_camp: Dictionary = _Persistence.load_save()
	var st_camp: Variant = loaded_camp.get("company_state", {})
	if st_camp is not Dictionary or int((st_camp as Dictionary).get("day_index", -1)) != day_save_before + 1:
		_fail(
			failures,
			"Camp-1.6: autosave day_index want %d got %s"
			% [day_save_before + 1, st_camp]
		)
	else:
		_pass()
	world_menu.queue_free()


# --- Camp-1.7 ---

static func _run_camp_1_7_renown_scaling(failures: PackedStringArray) -> void:
	var easy: Dictionary = _ContractSpawner.CONTRACT_TEMPLATES[0]
	var hard: Dictionary = _ContractSpawner.CONTRACT_TEMPLATES[1]
	var n_easy: int = int(easy.get("enemy_count", 0))
	var n_hard: int = int(hard.get("enemy_count", 0))
	if n_hard <= n_easy:
		_fail(failures, "Camp-1.7: escort enemy_count should exceed skirmish")
	else:
		_pass()
	if int(hard.get("pay_gold", 0)) <= int(easy.get("pay_gold", 0)):
		_fail(failures, "Camp-1.7: later template base pay should exceed first")
	else:
		_pass()
	var f_easy: Dictionary = _ContractSpawner.build_enemy_formation_for_template(easy)
	var f_hard: Dictionary = _ContractSpawner.build_enemy_formation_for_template(hard)
	var slots_easy: int = int(f_easy.get("files", 1)) * int(f_easy.get("ranks", 1))
	var slots_hard: int = int(f_hard.get("files", 1)) * int(f_hard.get("ranks", 1))
	if slots_hard <= slots_easy:
		_fail(
			failures,
			"Camp-1.7: harder contract formation slots want > easy (%d vs %d)"
			% [slots_hard, slots_easy]
		)
	else:
		_pass()
	var world: Node2D = _make_world(1)
	_CompanyState.set_renown(world, 4)
	var scaled: Dictionary = _ContractSpawner.scale_template_for_renown(world, easy)
	if int(scaled.get("enemy_count", 0)) < int(easy.get("enemy_count", 0)) + 2:
		_fail(
			failures,
			"Camp-1.7: renown=4 should add +2 enemies (got %d base %d)"
			% [scaled.get("enemy_count"), easy.get("enemy_count")]
		)
	else:
		_pass()
	var tut: Dictionary = _ContractSpawner.scale_template_for_renown(world, _ContractSpawner.TUTORIAL_TEMPLATE)
	if int(tut.get("enemy_count", 0)) != int(_ContractSpawner.TUTORIAL_TEMPLATE.get("enemy_count", 0)):
		_fail(failures, "Camp-1.7: tutorial enemy_count must not scale with renown")
	else:
		_pass()
	world.free()


# --- Camp-1.8 ---

static func _run_camp_1_8_roster_cleanup(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1, 1)
	var pm: Node = world.get_meta("party_manager")
	_CampaignBridge.build_last_battle_summary(world)
	if pm.members.size() != 2:
		_fail(failures, "Camp-1.8: harness want 2 roster entries before cleanup")
	else:
		_pass()
	var lines: PackedStringArray = _CompanyState.apply_casualty_cleanup(world)
	if lines.is_empty():
		_fail(failures, "Camp-1.8: memorial line expected for dead brother")
	else:
		_pass()
	if pm.members.size() != 1:
		_fail(failures, "Camp-1.8: dead brother removed from roster")
	else:
		_pass()
	var fightable: Array = _CampaignBridge.get_fightable_party_nodes(world)
	if fightable.size() != 1:
		_fail(failures, "Camp-1.8: fightable roster want 1 got %d" % fightable.size())
	else:
		_pass()
	world.free()


# --- Camp-2+ (spot checks; full gates in combat harness) ---

static func _run_camp_2_bridge_spot_checks(failures: PackedStringArray) -> void:
	if _CompanyState.gate_map_bleed_policy() != "warn_eta":
		_fail(failures, "Camp-2.1: map_bleed policy want warn_eta")
	else:
		_pass()
	var world: Node2D = _make_world(1)
	if _MapBleedPolicy.effective_policy(world) != _MapBleedPolicy.POLICY_BLOCK:
		_fail(failures, "Camp-2.1: tutorial incomplete should block")
	else:
		_pass()
	world.set_meta(_CompanyState.WORLD_META_MAP_BLEED_MULT, 0.25)
	_CampaignBridge.clear_transient_combat_meta(world)
	if world.has_meta(_CompanyState.WORLD_META_MAP_BLEED_MULT):
		_fail(failures, "Camp-2.1: map_bleed_mult should clear after combat")
	else:
		_pass()
	_CompanyState.mark_tutorial_completed(world)
	if _MapBleedPolicy.effective_policy(world) != _MapBleedPolicy.POLICY_WARN_ETA:
		_fail(failures, "Camp-2.1: post-tutorial map bleed policy want warn_eta")
	else:
		_pass()
	world.set_meta("active_contract", {"tutorial": true, "pay_gold": 0})
	if _CompanyState.apply_contract_victory_pay(world) != 0:
		_fail(failures, "Camp-3.1: tutorial pay want 0")
	else:
		_pass()
	var world_paid: Node2D = _make_world(1)
	_CompanyState.set_active_contract(
		world_paid,
		{"contract_title": "Escort", "pay_gold": 120, "contract_type": "escort"}
	)
	if _CompanyState.apply_contract_victory_pay(world_paid) != 120:
		_fail(failures, "Camp-2.1: paid contract pay want 120")
	else:
		_pass()
	if not _CompanyState.is_tutorial_completed(world_paid):
		_fail(failures, "Camp-2.1: paid contract win should lift map bleed block")
	else:
		_pass()
	if _MapBleedPolicy.effective_policy(world_paid) != _MapBleedPolicy.POLICY_WARN_ETA:
		_fail(failures, "Camp-2.1: after paid win map bleed policy want warn_eta")
	else:
		_pass()
	world.free()
	world_paid.free()
	var world_win: Node2D = _make_world(1)
	if _CompanyState.is_tutorial_completed(world_win):
		_fail(failures, "Camp-2.1: fresh world should start pre-first-win")
	else:
		_pass()
	_CampaignBridge.on_return_from_combat(world_win, "player")
	if not _CompanyState.is_tutorial_completed(world_win):
		_fail(failures, "Camp-2.1: on_return_from_combat(player) should lift map bleed block")
	else:
		_pass()
	if _MapBleedPolicy.effective_policy(world_win) != _MapBleedPolicy.POLICY_WARN_ETA:
		_fail(failures, "Camp-2.1: after combat return policy want warn_eta")
	else:
		_pass()
	world_win.free()

	var snap: Dictionary = {"name": "T", "blood_volume": 55.0, "total_bleeding_rate": 1.2}
	var entry: Dictionary = _CampaignBridge.member_battle_summary_entry(snap, null)
	if int(entry.get("worst_atls_band", 0)) < 2:
		_fail(failures, "Camp-2.2: worst_atls_band for 55%% blood")
	else:
		_pass()
	var bleed_ent: Node = _CoreEntityScript.new()
	bleed_ent.apply_species()
	bleed_ent.wounds["left_arm"] = [
		{"current_bleeding_rate": 1.0, "is_arterial": false, "severity": "moderate"},
	]
	var bleed_snap: Dictionary = {"name": "Bleeder", "blood_volume": 80.0, "total_bleeding_rate": 1.0}
	var bleed_entry: Dictionary = _CampaignBridge.member_battle_summary_entry(bleed_snap, bleed_ent)
	var snap_entry: Dictionary = bleed_entry.get("snapshot", {})
	if snap_entry is Dictionary and (snap_entry.get("untreated_parts", []) as PackedStringArray).size() > 0:
		_pass()
	else:
		_fail(failures, "Camp-2.2: battle snapshot should carry untreated_parts when present")
	bleed_ent.free()

	var entity: Node = _CoreEntityScript.new()
	entity.intelligence = 100
	entity.set_campaign_supply_factor(0.5)
	if absf(entity.get_medical_effectiveness() - 0.5) > 0.02:
		_fail(failures, "Camp-2.3: supply factor at 0 med floor")
	else:
		_pass()
	entity.free()

	var world_med: Node2D = _make_world(1)
	_CompanyState.set_medical_supplies(world_med, 0)
	_CompanyState.wire_party_medical_supply(world_med)
	var hint: String = _CompanyState.format_battle_medical_supply_hint(world_med)
	if not hint.contains("efficacy"):
		_fail(failures, "Camp-2.3: depleted med should produce supply hint")
	else:
		_pass()
	_CompanyState.set_medical_supplies(world_med, 1)
	_CompanyState.wire_party_medical_supply(world_med)
	var hint_one: String = _CompanyState.format_battle_medical_supply_hint(world_med)
	if not hint_one.contains("last"):
		_fail(failures, "Camp-2.3: 1 med left should warn about next spend")
	else:
		_pass()
	world_med.free()

	var pre_stab: Node = _CoreEntityScript.new()
	pre_stab.apply_species()
	pre_stab.wounds["chest"] = [
		{"current_bleeding_rate": 2.0, "is_arterial": true, "severity": "severe"},
	]
	if _EntityMedical.can_apply_stabilize(pre_stab, "chest"):
		_fail(failures, "Camp-2.5: stabilize should require pressure first")
	else:
		_pass()
	pre_stab.free()

	seed(90210)
	var stab_ent: Node = _CoreEntityScript.new()
	stab_ent.apply_species()
	stab_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.8, "is_arterial": true, "severity": "severe"}
	]
	if not stab_ent.apply_direct_pressure("chest"):
		_fail(failures, "Camp-2.5: setup pressure on chest")
	else:
		_pass()
	if not stab_ent.can_apply_stabilize("chest"):
		_fail(failures, "Camp-2.5: should offer stabilize under pressure with bleed")
	else:
		_pass()
	if not stab_ent.apply_stabilize("chest", 2.0):
		_fail(failures, "Camp-2.5: apply_stabilize should succeed")
	else:
		_pass()
	if bool(stab_ent.bandaged_parts.get("chest", false)):
		_fail(failures, "Camp-2.5: stabilize must not set bandaged_parts")
	else:
		_pass()
	stab_ent.free()

	var pain_ent: Node = _CoreEntityScript.new()
	pain_ent.apply_species()
	if not pain_ent.add_campaign_affliction({"id": "old_wound_ache", "pain_mult": 1.1, "stamina_mult": 1.0}):
		_fail(failures, "Camp-2.4: pain affliction add")
	else:
		_pass()
	if absf(pain_ent.get_campaign_pain_mult() - 1.1) > 0.02:
		_fail(failures, "Camp-2.4: pain_mult want 1.1 got %.3f" % pain_ent.get_campaign_pain_mult())
	else:
		_pass()
	var aff_snap: Dictionary = _Snapshot.snapshot_from_member(
		{"name": "Scar", "node_ref": pain_ent}
	)
	if not str(aff_snap.get("affliction_effects", "")).contains("Pain"):
		_fail(failures, "Camp-2.4: snapshot should expose affliction effect line")
	else:
		_pass()
	pain_ent.free()

	var day_world: Node2D = _make_world(1)
	var day_line: String = _CompanyState.format_day_hud_line(day_world)
	if not day_line.contains("steps"):
		_fail(failures, "Camp-1.2: hybrid HUD should show step progress")
	else:
		_pass()
	day_world.free()

	var esc_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[1])
	if not esc_lbl.contains("bleed"):
		_fail(failures, "Camp-1.4: contract marker should show map bleed mult when <1")
	else:
		_pass()

	seed(90210)
	var field_world: Node2D = _make_world(1)
	_CompanyState.set_medical_supplies(field_world, 2)
	var pm_f: Node = field_world.get_meta("party_manager")
	var live: Node = _add_living_entity_member(pm_f, "Fielder")
	live.wounds["chest"] = [
		{"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
	]
	live.apply_direct_pressure("chest")
	var member_d: Dictionary = _Snapshot.snapshot_from_member({"name": "Fielder", "node_ref": live})
	if not _MapFieldCare.can_offer_field_stabilize(field_world, member_d):
		_fail(failures, "Camp-2.1: field stabilize should be offered under pressure")
	else:
		_pass()
	seed(90210)
	if not _MapFieldCare.try_field_stabilize(field_world, member_d):
		_fail(failures, "Camp-2.1: field stabilize should succeed")
	else:
		_pass()
	field_world.free()

	var triage: String = _RowFormatter.format_triage_line(72.0, 1.2)
	if not triage.contains("Class II") or not triage.contains("Bleeding"):
		_fail(failures, "Camp-3.2: triage line should include ATLS band and bleed rate")
	else:
		_pass()
	var eta: String = _RowFormatter.format_danger_eta_phrase(40.0, 2.0)
	if eta.is_empty() or not eta.contains("danger"):
		_fail(failures, "Camp-3.2: danger ETA phrase missing for bleeding ally")
	else:
		_pass()

	var debt_world: Node2D = _make_world(2)
	_CompanyState.set_gold(debt_world, 5)
	_CompanyState.try_advance_day(debt_world)
	if _CompanyState.get_gold(debt_world) >= 0:
		_fail(failures, "Camp-2.6: wages should drive gold negative when underfunded")
	else:
		_pass()
	debt_world.free()

	var soft_world: Node2D = _make_world(1)
	soft_world.set_script(_CampaignWorldScript)
	_add_player_at_camp(soft_world)
	_CompanyState.set_gold(soft_world, 77)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	soft_world.set_meta("rng", rng)
	soft_world.set_meta("enemy_scene", load(ResourcePaths.ENEMY_SCENE) as PackedScene)
	var lost: Dictionary = _ContractSpawner.TUTORIAL_TEMPLATE.duplicate(true)
	_CombatFlow.resume_overworld_after_soft_defeat(soft_world, lost)
	if _CompanyState.get_gold(soft_world) != 77:
		_fail(failures, "Camp-2.6: soft defeat resume must preserve company gold")
	else:
		_pass()
	var tutorial_markers: int = 0
	for child in soft_world.get_children():
		if child is EncounterNode and child.is_tutorial_encounter():
			tutorial_markers += 1
	if tutorial_markers != 1:
		_fail(failures, "Camp-2.6: soft defeat should respawn one tutorial marker got %d" % tutorial_markers)
	else:
		_pass()
	soft_world.free()

	var mood_world: Node2D = _make_world(1)
	var pm_mood: Node = mood_world.get_meta("party_manager")
	pm_mood.members[0]["company_mood"] = 50.0
	_CompanyState.apply_battle_lost_mood(mood_world)
	var after: float = float(pm_mood.members[0].get("company_mood", 50.0))
	if not is_equal_approx(after, 49.55):
		_fail(failures, "Camp-2.6 B3: battle loss mood should be -0.45 on living roster got %.2f" % after)
	else:
		_pass()
	mood_world.free()

	var death_mood_world: Node2D = _make_world(1, 1)
	var pm_death: Node = death_mood_world.get_meta("party_manager")
	pm_death.members[0]["company_mood"] = 50.0
	_CampaignBridge.build_last_battle_summary(death_mood_world)
	var survivor_mood: float = float(pm_death.members[0].get("company_mood", 50.0))
	if not is_equal_approx(survivor_mood, 49.75):
		_fail(
			failures,
			"Camp-2.6 B3: death witness mood should be -0.25 per death on survivors got %.2f"
			% survivor_mood
		)
	else:
		_pass()
	death_mood_world.free()

	var multi_death_world: Node2D = _make_world(1, 2)
	var pm_multi: Node = multi_death_world.get_meta("party_manager")
	pm_multi.members[0]["company_mood"] = 50.0
	_CampaignBridge.build_last_battle_summary(multi_death_world)
	var multi_mood: float = float(pm_multi.members[0].get("company_mood", 50.0))
	if not is_equal_approx(multi_mood, 49.5):
		_fail(
			failures,
			"Camp-2.6 B3: two deaths should be -0.50 on survivor got %.2f" % multi_mood
		)
	else:
		_pass()
	multi_death_world.free()

	var r3_mood_world: Node2D = _make_world(1, 1)
	var pm_r3: Node = r3_mood_world.get_meta("party_manager")
	pm_r3.members[0]["company_mood"] = 50.0
	_CompanyState.set_active_contract(
		r3_mood_world, {"pay_gold": 100, "contract_type": "skirmish", "contract_title": "Paid"}
	)
	_CampaignBridge.build_last_battle_summary(r3_mood_world, "enemy")
	var r3_survivor: float = float(pm_r3.members[0].get("company_mood", 50.0))
	if not is_equal_approx(r3_survivor, 50.0):
		_fail(
			failures,
			"Camp-2.6 B3: R3 loss should skip death witness mood before reload got %.2f" % r3_survivor
		)
	else:
		_pass()
	r3_mood_world.free()

	var restart_world: Node2D = _make_world(1, 0, true)
	restart_world.set_script(_CampaignWorldScript)
	PartySetup.setup_party(restart_world)
	var pm_a: Variant = restart_world.get_meta("party_manager")
	PartySetup.setup_party(restart_world)
	var pm_b: Variant = restart_world.get_meta("party_manager")
	var pm_on_world: int = 0
	for child in restart_world.get_children():
		if child.get_script() == _party_manager_script:
			pm_on_world += 1
	if pm_a == pm_b or pm_on_world != 1:
		_fail(
			failures,
			"Camp-2.6: setup_party should replace stale world PartyManager (count=%d)" % pm_on_world
		)
	else:
		_pass()
	restart_world.free()

	_run_camp_4_contract_flavor(failures)
	_run_encounter_entry_rollback(failures)
	_run_combat_start_abort_cleanup(failures)


static func _run_combat_start_abort_cleanup(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1)
	world.set_script(_CampaignWorldScript)
	_add_player_at_camp(world)
	var pm: Node = world.get_meta("party_manager")
	if pm is Node and "members" in pm and pm.members.size() > 0:
		var dead_ref: Variant = pm.members[0].get("node_ref")
		if dead_ref is Node:
			(dead_ref as Node).set_script(load("res://scripts/_harness_dead_stub.gd") as Script)
	_CompanyState.set_active_contract(world, {"contract_title": "Abort Test", "pay_gold": 50})
	world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"tutorial": false})
	var dummy: Node2D = Node2D.new()
	dummy.name = "SpawnedEnemyStub"
	world.add_child(dummy)
	world.set_meta("_combat_enemies", [dummy])
	_CombatFlow.start_combat(world, [])
	if world.has_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT):
		_fail(failures, "Camp-1.4: aborted combat start should clear active_contract")
	else:
		_pass()
	if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		_fail(failures, "Camp-1.4: aborted combat start should clear combat_encounter meta")
	else:
		_pass()
	if world.has_meta("_combat_enemies"):
		_fail(failures, "Camp-1.4: aborted combat start should clear _combat_enemies")
	else:
		_pass()
	if is_instance_valid(dummy):
		_fail(failures, "Camp-1.4: aborted combat start should free spawned enemy nodes")
	else:
		_pass()
	world.free()


static func _run_encounter_entry_rollback(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1)
	world.set_script(_CampaignWorldScript)
	var rng := RandomNumberGenerator.new()
	var enc: Node2D = _EncounterNodeScript.new()
	enc.enemy_count = 0
	enc.encounter_config = _ContractSpawner.TUTORIAL_TEMPLATE.duplicate(true)
	world.add_child(enc)
	var before_children: int = world.get_child_count()
	var enemies: Array = _CampaignBridge.begin_contract_encounter(world, enc, rng)
	if not enemies.is_empty():
		_fail(failures, "Camp-1.4: zero-count encounter should return no enemies")
	else:
		_pass()
	if world.has_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT):
		_fail(failures, "Camp-1.4: failed spawn should clear active_contract")
	else:
		_pass()
	if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		_fail(failures, "Camp-1.4: failed spawn should clear combat_encounter meta")
	else:
		_pass()
	if not is_instance_valid(enc) or not enc.is_inside_tree():
		_fail(failures, "Camp-1.4: failed spawn should keep encounter marker on map")
	else:
		_pass()
	if world.get_child_count() != before_children:
		_fail(failures, "Camp-1.4: failed spawn should not remove encounter node")
	else:
		_pass()
	enc.free()
	world.free()


static func _run_camp_3_player_front_count_encounter(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(7)
	world.set_meta(
		CombatConstants.WORLD_META_COMBAT_ENCOUNTER,
		{CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 7}
	)
	_CampaignBridge.refresh_party_formation_meta(world)
	var pf: Dictionary = world.get_meta("party_formation", {}) as Dictionary
	if int(pf.get("files", 0)) != 7:
		_fail(
			failures,
			"Camp-3/III-4: player_front_count=7 want files=7 got %d" % int(pf.get("files", 0))
		)
	elif int(pf.get("ranks", 0)) != 1:
		_fail(
			failures,
			"Camp-3/III-4: player_front_count=7 want ranks=1 got %d" % int(pf.get("ranks", 0))
		)
	else:
		_pass()
	world.free()


static func _run_persistence_roundtrip(failures: PackedStringArray) -> void:
	_Persistence.clear_slot()
	var world: Node2D = _make_world(1, 0, true)
	_add_player_at_camp(world)
	var pm: Node = world.get_meta("party_manager")
	var ent: Node = _add_living_entity_member(pm, "Brother0")
	ent.wounds["chest"] = [{"current_bleeding_rate": 0.6, "is_arterial": false, "severity": "moderate"}]
	ent.blood_volume = 82.0
	_EncounterSpawner.equip_weapon_id(ent, "SWORD")
	_CompanyState.set_gold(world, 777)
	_CompanyState.set_medical_supplies(world, 2)
	_CompanyState.set_renown(world, 3)
	_CompanyState.mark_tutorial_completed(world)
	world.set_meta("party_formation", {"files": 1, "ranks": 1, "density": 1.0})
	world.set_meta(_Persistence.WORLD_META_CAMP_HEAL_HINT_SHOWN, true)
	_Persistence.mark_consumed_contract_tile(world, Vector2i(1, 0))
	var enc: Node2D = _EncounterNodeScript.new()
	enc.encounter_config = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[0])
	enc.enemy_count = 3
	enc.contract_marker_label = "Border Skirmish"
	enc.marker_kind = "contract"
	enc.position = Vector2(160, 32)
	world.add_child(enc)
	world.get_node("Character").position = Vector2(160, 32)
	if not _Persistence.save_slot(world):
		_fail(failures, "P2 persistence: save_slot failed")
	else:
		_pass()
	var loaded: Dictionary = _Persistence.load_save()
	if int(loaded.get("version", 0)) != _Persistence.SAVE_VERSION:
		_fail(failures, "P2 persistence: save version want %d got %s" % [_Persistence.SAVE_VERSION, loaded.get("version")])
	else:
		_pass()
	var state: Variant = loaded.get("company_state", {})
	if state is not Dictionary or int((state as Dictionary).get("gold", 0)) != 777:
		_fail(failures, "P2 persistence: JSON gold want 777 got %s" % state)
	else:
		_pass()
	var consumed: Variant = loaded.get("consumed_contract_tiles", [])
	if consumed is not Array or (consumed as Array).is_empty():
		_fail(failures, "P2 persistence: consumed_contract_tiles missing in save")
	else:
		_pass()
	var fresh: Node2D = _make_world(1, 0, true)
	_add_player_at_camp(fresh)
	var pm_fresh: Node = fresh.get_meta("party_manager")
	_add_living_entity_member(pm_fresh, "Brother0")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	_Persistence.apply_save(fresh, loaded, rng, null)
	if _CompanyState.get_gold(fresh) != 777:
		_fail(failures, "P2 persistence: apply_save gold want 777 got %d" % _CompanyState.get_gold(fresh))
	else:
		_pass()
	if _CompanyState.get_medical_supplies(fresh) != 2:
		_fail(failures, "P2 persistence: apply_save med want 2 got %d" % _CompanyState.get_medical_supplies(fresh))
	else:
		_pass()
	if not _CompanyState.is_tutorial_completed(fresh):
		_fail(failures, "P2 persistence: tutorial_completed not restored")
	else:
		_pass()
	var pf: Dictionary = fresh.get_meta("party_formation", {}) as Dictionary
	if int(pf.get("files", 0)) != 1:
		_fail(failures, "P2 persistence: party_formation files want 1 got %d" % int(pf.get("files", 0)))
	else:
		_pass()
	var restored_ent: Node = null
	for m in pm_fresh.members:
		if m is Dictionary and str((m as Dictionary).get("name", "")) == "Brother0":
			var nr: Variant = (m as Dictionary).get("node_ref")
			if is_instance_valid(nr):
				restored_ent = _CampaignBridge.health_entity_from_character(nr as Node)
			break
	if restored_ent == null or absf(float(restored_ent.blood_volume) - 82.0) > 0.01:
		_fail(
			failures,
			"P2 persistence: wound blood want 82 got %s"
			% (restored_ent.blood_volume if restored_ent != null else "null")
		)
	else:
		_pass()
	if restored_ent == null or float(restored_ent.consciousness) >= 99.5:
		_fail(
			failures,
			"P2 persistence: consciousness should reflect restored blood got %.1f"
			% (float(restored_ent.consciousness) if restored_ent != null else -1.0)
		)
	else:
		_pass()
	if _EncounterSpawner.weapon_id_from_entity(restored_ent) != "SWORD":
		_fail(
			failures,
			"P2 persistence: weapon want SWORD got %s"
			% _EncounterSpawner.weapon_id_from_entity(restored_ent)
		)
	else:
		_pass()
	if not bool(fresh.get_meta(_Persistence.WORLD_META_CAMP_HEAL_HINT_SHOWN, false)):
		_fail(failures, "P2 persistence: camp_heal_hint_shown not restored")
	else:
		_pass()
	var markers: int = 0
	for child in fresh.get_children():
		if child.get_script() == _EncounterNodeScript:
			markers += 1
	if markers != 1:
		_fail(failures, "P2 persistence: remaining_encounters want 1 marker got %d" % markers)
	else:
		_pass()
	_Persistence.clear_slot()
	if _Persistence.has_save():
		_fail(failures, "P2 persistence: clear_slot should remove save file")
	else:
		_pass()

	# Invalid / wrong-version saves are rejected (v1 and corrupt).
	FileAccess.open(_Persistence.SAVE_PATH, FileAccess.WRITE).store_string('{"version":1,"company_state":{},"roster":[{}]}')
	if _Persistence.is_valid_save(_Persistence.load_save()):
		_fail(failures, "P2 persistence: save version 1 should not validate")
	else:
		_pass()
	FileAccess.open(_Persistence.SAVE_PATH, FileAccess.WRITE).store_string('{"version":999}')
	if _Persistence.is_valid_save(_Persistence.load_save()):
		_fail(failures, "P2 persistence: wrong version should not validate")
	else:
		_pass()
	if _Persistence.has_save():
		_Persistence.clear_slot()
	world.queue_free()
	fresh.queue_free()


static func _run_camp_4_contract_flavor(failures: PackedStringArray) -> void:
	const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
	const _CombatConstants := preload("res://combat/CombatConstants.gd")
	var skirmish: Dictionary = _ContractSpawner.build_encounter_config(
		_ContractSpawner.CONTRACT_TEMPLATES[0]
	)
	if str(skirmish.get(_SoakPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "")) != "SWORD":
		_fail(failures, "Camp-4.3: skirmish should force SWORD")
	else:
		_pass()
	if int(skirmish.get(_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 7:
		_fail(failures, "Camp-4/III-4: Border Skirmish template want player_front_count=7")
	else:
		_pass()
	if (
		str(skirmish.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
		!= _CombatConstants.DOCTRINE_PINCH_CENTER
	):
		_fail(failures, "Camp-4/III-4: Border Skirmish should set enemy pinch_center doctrine")
	else:
		_pass()
	if (
		str(skirmish.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER, ""))
		!= _CombatConstants.DOCTRINE_PINCH_CENTER
	):
		_fail(failures, "Camp-4/III-4: Border Skirmish should set player pinch_center doctrine")
	else:
		_pass()
	var world_sk: Node2D = _make_world(7)
	var enc_sk: Node2D = _EncounterNodeScript.new()
	enc_sk.encounter_config = skirmish
	_CampaignBridge.prepare_combat_from_encounter(world_sk, enc_sk)
	var pf_sk: Dictionary = world_sk.get_meta("party_formation", {}) as Dictionary
	if int(pf_sk.get("files", 0)) != 7 or int(pf_sk.get("ranks", 0)) != 1:
		_fail(
			failures,
			"Camp-4/III-4: skirmish prepare_combat want 7x1 party_formation got files=%d ranks=%d"
			% [int(pf_sk.get("files", 0)), int(pf_sk.get("ranks", 0))]
		)
	else:
		_pass()
	var enc_meta_sk: Dictionary = world_sk.get_meta(_CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
	if (
		str(enc_meta_sk.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER, ""))
		!= _CombatConstants.DOCTRINE_PINCH_CENTER
	):
		_fail(failures, "Camp-4/III-4: skirmish player doctrine should reach combat meta")
	else:
		_pass()
	world_sk.free()
	enc_sk.free()
	var enc_ii: Node2D = _EncounterNodeScript.new()
	_SoakPresets.apply_preset(enc_ii, _SoakPresets.PRESET_II_ENVELOP)
	var ii_cfg: Dictionary = enc_ii.get_combat_encounter_dict()
	if int(ii_cfg.get(_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 7:
		_fail(failures, "III-4: ii_envelop preset want player_front_count=7")
	else:
		_pass()
	if (
		str(ii_cfg.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER, ""))
		!= _CombatConstants.DOCTRINE_PINCH_CENTER
	):
		_fail(failures, "III-4: ii_envelop preset should set player pinch_center doctrine")
	else:
		_pass()
	if (
		str(ii_cfg.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
		!= _CombatConstants.DOCTRINE_PINCH_CENTER
	):
		_fail(failures, "III-4: ii_envelop preset should set enemy pinch_center doctrine")
	else:
		_pass()
	enc_ii.free()
	var escort: Dictionary = _ContractSpawner.build_encounter_config(
		_ContractSpawner.CONTRACT_TEMPLATES[1]
	)
	if (
		str(escort.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
		!= _CombatConstants.DOCTRINE_PINCH_CENTER
	):
		_fail(failures, "Camp-4.2: escort should set enemy pinch_center doctrine")
	else:
		_pass()
	if float(escort.get("flee_line_cohesion_max_enemy", 0.0)) <= 0.0:
		_fail(failures, "Camp-4.2: escort should set flee_line_cohesion_max_enemy")
	else:
		_pass()
	var enc: Node2D = _EncounterNodeScript.new()
	enc.encounter_config = escort
	var meta_world: Node2D = _make_world(1)
	_CampaignBridge.prepare_combat_from_encounter(meta_world, enc)
	var got: Dictionary = meta_world.get_meta(_CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
	if got.is_empty() or not got.has(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY):
		_fail(failures, "Camp-4.2: escort doctrine should reach combat meta")
	else:
		_pass()
	meta_world.free()
	enc.free()
	var lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[1])
	if not lbl.contains("Escort") and not lbl.contains("120"):
		_fail(failures, "Camp-4: escort marker label should show title/pay")
	else:
		_pass()
