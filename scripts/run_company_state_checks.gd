extends SceneTree

## Headless Camp-1 economy loop (1.1–1.8) + Camp-2 bridge spot checks + P2 persistence roundtrip.
## Run: .\scripts\run_company_state_checks.ps1
## Labels: Camp-1.x in failure messages map to SHIP_PLAN § Camp-1.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `scripts/README.md`).
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _MapBleedPolicy := preload("res://world/MapBleedPolicy.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _Snapshot := preload("res://world/PartyMemberSnapshot.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _ContractSpawner := preload("res://world/ContractSpawner.gd")
const _EncounterNodeScript := preload("res://world/EncounterNode.gd")
const _CoreEntityScript := preload("res://core/CoreEntity.gd")
const _CampaignWorldScript := preload("res://scripts/_harness_campaign_world.gd")
const HARNESS_NAME := "CompanyStateChecks"
const _CompanyHud := preload("res://ui/CompanyHud.gd")
const _CombatFlow := preload("res://world/CombatFlow.gd")
const _SettlementPanel := preload("res://ui/SettlementPanel.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _PartySetup := preload("res://world/PartySetup.gd")
const _Persistence := preload("res://world/CampaignPersistence.gd")
const _EncounterSpawner := preload("res://world/EncounterSpawner.gd")

static var _test_count: int = 0
static var _party_manager_script: Script = load(ResourcePaths.PARTY_MANAGER) as Script
static var _party_menu_script: Script = load(ResourcePaths.PARTY_MENU) as Script


func _init() -> void:
	CombatConstants.set_headless_harness_quiet(true)
	call_deferred("_run_harness")


func _run_harness() -> void:
	_OperationalLog.ensure_harness_error_logger()
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
	_cleanup_harness_tree_leaks()
	call_deferred("_finish_harness", failures)


func _finish_harness(failures: PackedStringArray) -> void:
	await process_frame
	_cleanup_harness_tree_leaks()
	var script_errors: int = _OperationalLog.harness_script_error_count()
	if script_errors > 0:
		_fail(
			failures,
			"Harness: %d SCRIPT_ERROR(s) during CompanyStateChecks (see FP_ERROR lines)"
			% script_errors
		)
	if failures.is_empty():
		quit(_OperationalLog.harness_ok(HARNESS_NAME, "(%d tests)" % _test_count))
	else:
		quit(_OperationalLog.harness_fail(HARNESS_NAME, failures, "(%d tests)" % _test_count))


static func _fail(failures: PackedStringArray, msg: String) -> void:
	failures.append(msg)


static func _pass() -> void:
	_test_count += 1


static func _harness_root() -> Node:
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root
	return null


static func _release_harness_world(world: Node) -> void:
	if world == null or not is_instance_valid(world):
		return
	if world is Node2D and (world as Node2D).is_inside_tree():
		_free_harness_world(world)
	else:
		world.free()


static func _detach_and_free_meta_node(world: Node, meta_key: String) -> void:
	if world == null or not world.has_meta(meta_key):
		return
	var node_ref: Variant = world.get_meta(meta_key)
	world.remove_meta(meta_key)
	if typeof(node_ref) != TYPE_OBJECT or not is_instance_valid(node_ref):
		return
	var node: Node = node_ref as Node
	if node == null:
		return
	var node_parent: Node = node.get_parent()
	if node_parent != null:
		node_parent.remove_child(node)
	node.free()


static func _free_harness_world(world: Node) -> void:
	if world == null or not is_instance_valid(world):
		return
	_detach_and_free_meta_node(world, _CompanyState.WORLD_META_COMPANY_HUD)
	_detach_and_free_meta_node(world, "party_menu")
	var root: Node = _harness_root()
	if root != null:
		for layer in root.get_children():
			if layer.name != "UIOverlayLayer":
				continue
			for gc in layer.get_children().duplicate():
				if gc is Button and gc.name == "PartyButton":
					layer.remove_child(gc)
					gc.free()
	var parent: Node = world.get_parent()
	if parent != null:
		parent.remove_child(world)
	world.free()


static func _cleanup_harness_ui_overlay() -> void:
	var root: Node = _harness_root()
	if root == null:
		return
	for child in root.get_children():
		if child.name != "UIOverlayLayer":
			continue
		for gc in child.get_children():
			child.remove_child(gc)
			gc.free()
		root.remove_child(child)
		child.free()


static func _cleanup_harness_tree_leaks() -> void:
	var root: Node = _harness_root()
	if root == null:
		return
	for child in root.get_children().duplicate():
		if child is Node2D and child.get_script() == _CampaignWorldScript:
			_free_harness_world(child)
	_cleanup_harness_ui_overlay()


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
		pm.add_child(n)
		pm.members.append({"name": n.name, "node_ref": n})
	world.set_meta("party_manager", pm)
	_CompanyState.init_from_defaults(world)
	if in_tree:
		var root: Node = _harness_root()
		if root != null:
			root.add_child(world)
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
	pm.add_child(ent)
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
	_release_harness_world(world)

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
	_free_harness_world(world_hud)


# --- Camp-1.2 ---

static func _run_camp_1_2_wages_and_day(failures: PackedStringArray) -> void:
	if _CompanyState.read_stub_day_tick_mode() != "hybrid":
		_fail(failures, "Camp-1.2: day_tick_mode want hybrid")
	else:
		_pass()
	var world: Node2D = _make_world(2)
	var steps: int = _CompanyState.read_stub_steps_per_day()
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
	_release_harness_world(world)

	var world_dead: Node2D = _make_world(1, 1)
	if _CompanyState.compute_next_wage_bill(world_dead) != _CompanyState.DEFAULT_WAGE_PER_MEMBER:
		_fail(failures, "Camp-1.2: dead brother excluded from wage bill")
	else:
		_pass()
	_release_harness_world(world_dead)

	var world_hybrid: Node2D = _make_world(1, 0, true)
	_add_player_at_camp(world_hybrid)
	world_hybrid.get_node("Character").position = Vector2(192, 192)
	if _CompanyState.request_end_day(world_hybrid):
		_fail(failures, "Camp-1.2: hybrid end_day off camp should fail")
	else:
		_pass()
	world_hybrid.get_node("Character").position = Vector2(160, 160)
	if _CompanyState.request_end_day(world_hybrid):
		_fail(failures, "Camp-1.2: hybrid end_day still off camp at (2,2)")
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
	_free_harness_world(world_hybrid)

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
	if _CompanyState.get_medical_supplies(world) != _CompanyState.DEFAULT_MEDICAL_SUPPLIES - 1:
		_fail(
			failures,
			"Camp-1.3: med supplies want %d got %d"
			% [_CompanyState.DEFAULT_MEDICAL_SUPPLIES - 1, _CompanyState.get_medical_supplies(world)]
		)
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
	if _CompanyState.read_stub_persistence_mode() != "P1":
		_fail(failures, "Camp-5: persistence gate want P1 (session-only EA)")
	else:
		_pass()
	if _CompanyState.read_stub_encounter_lifecycle() != "r3_loss_ends_run":
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
	if not _CompanyState.is_tutorial_contract({"contract_type": "tutorial"}):
		_fail(failures, "Camp-1.4: contract_type tutorial must count as tutorial contract")
	else:
		_pass()
	if not _CompanyState.is_tutorial_contract({"tutorial": true}):
		_fail(failures, "Camp-1.4: tutorial flag alone must count as tutorial contract")
	else:
		_pass()
	if _CompanyState.is_tutorial_contract({"pay_gold": 100, "contract_type": "skirmish"}):
		_fail(failures, "Camp-1.4: paid skirmish must not count as tutorial contract")
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
	var day_before_camp: int = _CompanyState.get_day_index(world)
	var gold_before_camp: int = _CompanyState.get_gold(world)
	if not _CompanyState.try_camp_heal(world):
		_fail(failures, "Camp-1.6: camp heal should succeed on camp with med")
	else:
		_pass()
	if _CompanyState.get_medical_supplies(world) != 1:
		_fail(failures, "Camp-1.6: camp heal should consume 1 med")
	else:
		_pass()
	if _CompanyState.get_day_index(world) != day_before_camp + 1:
		_fail(
			failures,
			"Camp-1.6: camp heal should advance day %d -> %d"
			% [day_before_camp, _CompanyState.get_day_index(world)]
		)
	else:
		_pass()
	var wage_bill: int = _CompanyState.compute_next_wage_bill(world)
	if _CompanyState.get_gold(world) != gold_before_camp - wage_bill:
		_fail(
			failures,
			"Camp-1.6: camp heal should pay wages (gold %d want %d bill=%d)"
			% [_CompanyState.get_gold(world), gold_before_camp - wage_bill, wage_bill]
		)
	else:
		_pass()
	_free_harness_world(world)

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
		_fail(failures, "Camp-1.6: party menu camp heal should advance day")
	else:
		_pass()
	_free_harness_world(world_menu)

	var bleed_world: Node2D = _make_world(0, 0, true)
	var pm_b: Node = bleed_world.get_meta("party_manager")
	var wounded: Node = _add_living_entity_member(pm_b, "Bleeder")
	wounded.wounds["left_arm"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
	_CompanyState.set_medical_supplies(bleed_world, 2)
	if _CompanyState.camp_heal_ready(bleed_world, true):
		_fail(failures, "Camp-1.6: camp_heal_ready must be false while untreated wounds remain")
	else:
		_pass()
	if _CompanyState.try_camp_heal(bleed_world, true):
		_fail(failures, "Camp-1.6: camp heal must fail while untreated wounds remain")
	else:
		_pass()
	wounded.bandaged_parts["left_arm"] = true
	if not _CompanyState.camp_heal_ready(bleed_world, true):
		_fail(failures, "Camp-1.6: camp_heal_ready should be true after wound dressed")
	else:
		_pass()
	if not _CompanyState.try_camp_heal(bleed_world, true):
		_fail(failures, "Camp-1.6: camp heal should succeed after wound dressed")
	else:
		_pass()
	_free_harness_world(bleed_world)


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
	if _CompanyState.read_stub_map_bleed_policy() != "warn_eta":
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
	if not hint_one.contains("One med left"):
		_fail(failures, "Camp-2.3: 1 med left should warn about next spend got '%s'" % hint_one)
	else:
		_pass()
	_CompanyState.set_medical_supplies(world_med, 3)
	_CompanyState.wire_party_medical_supply(world_med)
	var hint_tight: String = _CompanyState.format_battle_medical_supply_hint(world_med)
	if not hint_tight.contains("tight"):
		_fail(failures, "Camp-2.3: low med pool should warn about map dressings got '%s'" % hint_tight)
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

	seed(90210)
	var press_ent: Node = _CoreEntityScript.new()
	press_ent.apply_species()
	press_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.6, "severity": "moderate"},
	]
	if not press_ent.apply_direct_pressure("chest"):
		_fail(failures, "Camp-2.5: setup pressure for bandage failure retain")
	else:
		_pass()
	if not _EntityMedical.has_direct_pressure_on_part(press_ent, "chest"):
		_fail(failures, "Camp-2.5: want pressure held before bandage attempt")
	else:
		_pass()
	if press_ent.apply_bandage("chest", 0.0):
		_fail(failures, "Camp-2.5: zero-eff bandage should fail for pressure-retain test")
	else:
		_pass()
	if not _EntityMedical.has_direct_pressure_on_part(press_ent, "chest"):
		_fail(failures, "Camp-2.5: failed bandage must retain direct pressure for retry")
	else:
		_pass()
	press_ent.free()

	seed(90210)
	var pack_ent: Node = _CoreEntityScript.new()
	pack_ent.apply_species()
	pack_ent.linen_strips_remaining = 4
	pack_ent.wounds["chest"] = [
		{"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
	]
	if not pack_ent.apply_direct_pressure("chest"):
		_fail(failures, "Camp-2.5: setup pressure for packing failure retain")
	else:
		_pass()
	if not pack_ent.apply_packing("chest", 0.0):
		_pass()
	else:
		_fail(failures, "Camp-2.5: zero-eff packing should fail for pressure-retain test")
	if not _EntityMedical.has_direct_pressure_on_part(pack_ent, "chest"):
		_fail(failures, "Camp-2.5: failed packing must retain direct pressure for retry")
	else:
		_pass()
	pack_ent.free()

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
	_release_harness_world(day_world)

	var esc_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[1])
	if not esc_lbl.contains("bleed"):
		_fail(failures, "Camp-1.4: contract marker should show map bleed mult when <1")
	else:
		_pass()

	seed(90210)
	var field_world: Node2D = _make_world(1, 0, true)
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
	if bool(live.bandaged_parts.get("chest", false)):
		_fail(failures, "Camp-2.1: field stabilize must not set bandaged_parts (hemostatic hold only)")
	else:
		_pass()
	if _CompanyState.camp_heal_ready(field_world, true):
		_fail(failures, "Camp-2.1: camp rest must stay gated after stabilize until bandage dresses wound")
	else:
		_pass()
	if not _MapFieldCare.can_offer_field_bandage(field_world, member_d):
		_fail(failures, "Camp-2.1: field bandage should remain offered after stabilize while pressure held")
	else:
		_pass()
	_release_harness_world(field_world)

	seed(90210)
	var dress_world: Node2D = _make_world(1, 0, true)
	_CompanyState.set_medical_supplies(dress_world, 2)
	var pm_d: Node = dress_world.get_meta("party_manager")
	var dresser: Node = _add_living_entity_member(pm_d, "Dresser")
	dresser.wounds["chest"] = [
		{"current_bleeding_rate": 0.6, "severity": "moderate"},
	]
	var dress_member: Dictionary = _Snapshot.snapshot_from_member({"name": "Dresser", "node_ref": dresser})
	if _MapFieldCare.can_offer_field_bandage(dress_world, dress_member):
		_fail(failures, "Camp-2.1: field bandage should require direct pressure first")
	else:
		_pass()
	if not dresser.apply_direct_pressure("chest"):
		_fail(failures, "Camp-2.1: setup pressure on chest for field bandage")
	else:
		_pass()
	dress_member = _Snapshot.snapshot_from_member({"name": "Dresser", "node_ref": dresser})
	if not _MapFieldCare.can_offer_field_bandage(dress_world, dress_member):
		_fail(failures, "Camp-2.1: field bandage should be offered on untreated chest")
	else:
		_pass()
	var bandaged_ok: bool = false
	for attempt in range(24):
		_CompanyState.set_medical_supplies(dress_world, 2)
		dresser.bandaged_parts.erase("chest")
		if dresser.self_direct_pressure_part != "chest":
			dresser.apply_direct_pressure("chest")
		seed(90210 + attempt)
		if _MapFieldCare.try_field_bandage(dress_world, dress_member):
			bandaged_ok = true
			break
	if not bandaged_ok:
		_fail(failures, "Camp-2.1: field bandage should eventually dress untreated chest")
	else:
		_pass()
	if _CompanyState.camp_heal_ready(dress_world, true):
		_pass()
	else:
		_fail(failures, "Camp-2.1: camp_heal_ready should be true after field bandage dresses wound")
	var day_before_rest: int = _CompanyState.get_day_index(dress_world)
	if not _CompanyState.try_camp_heal(dress_world, true):
		_fail(failures, "Camp-2.1: camp rest should succeed after pressure + field bandage")
	else:
		_pass()
	if _CompanyState.get_day_index(dress_world) != day_before_rest + 1:
		_fail(
			failures,
			"Camp-2.1: camp rest after field care should advance day %d -> %d"
			% [day_before_rest, _CompanyState.get_day_index(dress_world)]
		)
	else:
		_pass()
	_release_harness_world(dress_world)

	var retry_world: Node2D = _make_world(1)
	var pm_retry: Node = retry_world.get_meta("party_manager")
	var retry_ent: Node = _add_living_entity_member(pm_retry, "RetryBand")
	retry_ent.wounds["chest"] = [
		{"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
	]
	retry_ent.apply_direct_pressure("chest")
	var retry_member: Dictionary = _Snapshot.snapshot_from_member(
		{"name": "RetryBand", "node_ref": retry_ent}
	)
	var saw_fail_refund: bool = false
	for attempt in range(48):
		_CompanyState.set_medical_supplies(retry_world, 2)
		retry_ent.bandaged_parts.erase("chest")
		if retry_ent.self_direct_pressure_part != "chest":
			retry_ent.apply_direct_pressure("chest")
		retry_member = _Snapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
		seed(88000 + attempt)
		var med_before: int = _CompanyState.get_medical_supplies(retry_world)
		if _MapFieldCare.try_field_bandage(retry_world, retry_member):
			continue
		if (
			_CompanyState.get_medical_supplies(retry_world) == med_before
			and not bool(retry_ent.bandaged_parts.get("chest", false))
			and _EntityMedical.has_direct_pressure_on_part(retry_ent, "chest")
		):
			saw_fail_refund = true
			break
	if not saw_fail_refund:
		_fail(
			failures,
			"Camp-2.1: field bandage failure should refund med, keep wound undressed, retain pressure"
		)
	else:
		_pass()
	_OperationalLog.begin_play_session("headless://field_bandage_fail_log", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	_CompanyState.set_medical_supplies(retry_world, 2)
	retry_ent.bandaged_parts.erase("chest")
	retry_ent.apply_direct_pressure("chest")
	retry_member = _Snapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
	for attempt in range(48):
		seed(88100 + attempt)
		if not _MapFieldCare.try_field_bandage(retry_world, retry_member):
			break
	var fail_logged: bool = false
	for line in _OperationalLog.get_captured_lines():
		var s: String = str(line)
		if s.contains("field_care bandage failed") and s.contains("parts_left="):
			fail_logged = true
			break
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	if not fail_logged:
		_fail(failures, "Camp-2.1: bandage failure log should include parts_left")
	else:
		_pass()
	_release_harness_world(retry_world)

	var clot_world: Node2D = _make_world(1)
	var pm_clot: Node = clot_world.get_meta("party_manager")
	var clot_ent: Node = _add_living_entity_member(pm_clot, "ClotDress")
	clot_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
	]
	var clot_member: Dictionary = _Snapshot.snapshot_from_member(
		{"name": "ClotDress", "node_ref": clot_ent}
	)
	if _MapFieldCare.can_offer_field_bandage(clot_world, clot_member):
		_pass()
	else:
		_fail(
			failures,
			"Camp-2.1: field bandage should be offered on clotted untreated part without pressure"
		)
	if _MapFieldCare.field_bandage_needs_pressure_first(clot_member):
		_fail(failures, "Camp-2.1: clotted part should not block bandage waiting on pressure")
	else:
		_pass()
	var clot_dressed: bool = false
	for attempt in range(48):
		_CompanyState.set_medical_supplies(clot_world, 2)
		clot_ent.bandaged_parts.erase("chest")
		clot_member = _Snapshot.snapshot_from_member({"name": "ClotDress", "node_ref": clot_ent})
		seed(99000 + attempt)
		if _MapFieldCare.try_field_bandage(clot_world, clot_member):
			clot_dressed = true
			break
	if not clot_dressed:
		_fail(failures, "Camp-2.1: field bandage should eventually dress clotted untreated chest")
	else:
		_pass()
	if _CompanyState.camp_heal_ready(clot_world, true):
		_pass()
	else:
		_fail(failures, "Camp-2.1: clotted field bandage should dress part for camp rest")
	_release_harness_world(clot_world)

	var zero_med_world: Node2D = _make_world(1, 0, true)
	_CompanyState.set_medical_supplies(zero_med_world, 0)
	var pm_zero: Node = zero_med_world.get_meta("party_manager")
	var zero_ent: Node = _add_living_entity_member(pm_zero, "ZeroMedDress")
	zero_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
	]
	var zero_member: Dictionary = _Snapshot.snapshot_from_member(
		{"name": "ZeroMedDress", "node_ref": zero_ent}
	)
	if not _MapFieldCare.can_offer_field_bandage(zero_med_world, zero_member):
		_fail(failures, "Camp-2.1 E3: field bandage should be offered at 0 company med")
	else:
		_pass()
	var zero_gate: String = _CompanyState.format_party_triage_gate_line(zero_med_world)
	if not zero_gate.contains("0 med"):
		_fail(failures, "Camp-2.1 E3: triage gate at 0 med should mention 0-med bandage got '%s'" % zero_gate)
	else:
		_pass()
	var zero_hud: String = _CompanyState.format_hud_triage_suffix(zero_med_world)
	if not zero_hud.contains("0-med"):
		_fail(failures, "Camp-2.1 E3: HUD suffix at 0 med should mention 0-med bandages got '%s'" % zero_hud)
	else:
		_pass()
	var zero_camp_block: String = _CompanyState.format_camp_heal_block_reason(zero_med_world, true)
	if not zero_camp_block.contains("dressing"):
		_fail(
			failures,
			"Camp-2.1 E3: camp block at 0 med with wounds should cite dressing got '%s'" % zero_camp_block
		)
	else:
		_pass()
	var zero_dressed: bool = false
	for attempt in range(48):
		_CompanyState.set_medical_supplies(zero_med_world, 0)
		zero_ent.bandaged_parts.erase("chest")
		zero_member = _Snapshot.snapshot_from_member({"name": "ZeroMedDress", "node_ref": zero_ent})
		seed(99100 + attempt)
		if _MapFieldCare.try_field_bandage(zero_med_world, zero_member):
			zero_dressed = true
			break
	if not zero_dressed:
		_fail(failures, "Camp-2.1 E3: field bandage should succeed at 0 med with reduced efficacy")
	else:
		_pass()
	if _CompanyState.get_medical_supplies(zero_med_world) != 0:
		_fail(failures, "Camp-2.1 E3: field bandage at 0 med must not consume company med")
	else:
		_pass()
	_release_harness_world(zero_med_world)

	var sort_world: Node2D = _make_world(1)
	var pm_sort: Node = sort_world.get_meta("party_manager")
	var sort_ent: Node = _add_living_entity_member(pm_sort, "SortThreat")
	sort_ent.wounds["left_leg"] = [
		{"current_bleeding_rate": 0.08, "severity": "minor"},
	]
	sort_ent.wounds["right_arm"] = [
		{"current_bleeding_rate": 0.9, "is_arterial": true, "severity": "severe"},
	]
	var sorted: Array = _EntityWounds.sorted_untreated_part_names(sort_ent)
	if sorted.is_empty() or str(sorted[0]) != "right_arm":
		_fail(
			failures,
			"Camp-2.1: untreated parts should sort by threat (want right_arm first got %s)"
			% str(sorted)
		)
	else:
		_pass()
	_release_harness_world(sort_world)

	var pack_world: Node2D = _make_world(1, 0, true)
	_CompanyState.set_medical_supplies(pack_world, 2)
	var pm_pack: Node = pack_world.get_meta("party_manager")
	var field_pack_ent: Node = _add_living_entity_member(pm_pack, "FieldPack")
	field_pack_ent.linen_strips_remaining = 4
	field_pack_ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.5,
			"severity": "severe",
			"sub_region": "thoracic",
		},
	]
	field_pack_ent.apply_direct_pressure("chest")
	var pack_member: Dictionary = _Snapshot.snapshot_from_member(
		{"name": "FieldPack", "node_ref": field_pack_ent}
	)
	if not _MapFieldCare.can_offer_field_pack(pack_world, pack_member):
		_fail(failures, "Camp-2.1: field pack should be offered on pressured junctional wound")
	else:
		_pass()
	var packed_ok: bool = false
	for attempt in range(32):
		_CompanyState.set_medical_supplies(pack_world, 2)
		field_pack_ent.packed_parts.erase("chest")
		if not _EntityMedical.has_direct_pressure_on_part(field_pack_ent, "chest"):
			field_pack_ent.apply_direct_pressure("chest")
		seed(99200 + attempt)
		if _MapFieldCare.try_field_pack(pack_world, pack_member):
			packed_ok = true
			break
	if not packed_ok:
		_fail(failures, "Camp-2.1: field pack should eventually pack junctional chest")
	else:
		_pass()
	if _CompanyState.camp_heal_ready(pack_world, true):
		_pass()
	else:
		_fail(failures, "Camp-2.1: field pack should count as dressed for camp rest")
	_release_harness_world(pack_world)

	var tq_world: Node2D = _make_world(1, 0, true)
	var pm_tq: Node = tq_world.get_meta("party_manager")
	var tq_ent: Node = _add_living_entity_member(pm_tq, "FieldTQ")
	tq_ent.wounds["left_leg"] = [
		{"current_bleeding_rate": 1.4, "severity": "severe", "is_arterial": true},
	]
	var tq_member: Dictionary = _Snapshot.snapshot_from_member({"name": "FieldTQ", "node_ref": tq_ent})
	if not _MapFieldCare.can_offer_field_tourniquet(tq_world, tq_member):
		_fail(failures, "Camp-2.1: field tourniquet should be offered on severe limb bleed")
	else:
		_pass()
	if not _MapFieldCare.try_field_tourniquet(tq_world, tq_member):
		_fail(failures, "Camp-2.1: field tourniquet should succeed on indicated limb")
	else:
		_pass()
	if not _CompanyState.camp_heal_ready(tq_world, true):
		_fail(failures, "Camp-2.1: field tourniquet should dress part for camp rest")
	else:
		_pass()
	_release_harness_world(tq_world)

	var label_world: Node2D = _make_world(1)
	var pm_lbl: Node = label_world.get_meta("party_manager")
	var lbl_ent: Node = _add_living_entity_member(pm_lbl, "LabelTest")
	lbl_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.5, "severity": "moderate"},
	]
	var lbl_member: Dictionary = _Snapshot.snapshot_from_member({"name": "LabelTest", "node_ref": lbl_ent})
	var pressure_lbl: String = _MapFieldCare.format_field_pressure_button_label(label_world, lbl_member)
	if not pressure_lbl.contains("Chest"):
		_fail(failures, "Camp-2.1: field pressure button should name target part got '%s'" % pressure_lbl)
	else:
		_pass()
	var budget: Dictionary = _CompanyState.triage_med_budget(label_world)
	if int(budget.get("parts_need", 0)) != 1 or int(budget.get("total_worst_case", 0)) != 2:
		_fail(
			failures,
			"Camp-2.1: triage_med_budget want parts=1 total=2 got %s" % str(budget)
		)
	else:
		_pass()
	if int(budget.get("med_shortfall", -1)) != 0:
		_fail(failures, "Camp-2.1: med_shortfall should be 0 when supplies sufficient")
	else:
		_pass()
	_CompanyState.set_medical_supplies(label_world, 0)
	var budget_zero: Dictionary = _CompanyState.triage_med_budget(label_world)
	if int(budget_zero.get("field_bandage_med_est", -1)) != 0:
		_fail(failures, "Camp-2.1 E3: triage budget at 0 med should not charge for bandages")
	else:
		_pass()
	var hud_suffix: String = _CompanyState.format_hud_triage_suffix(label_world)
	if not hud_suffix.contains("1"):
		_fail(failures, "Camp-2.1: HUD triage suffix should show part count got '%s'" % hud_suffix)
	else:
		_pass()
	var wait_member: Dictionary = lbl_member
	var wait_lbl: String = _MapFieldCare.format_field_bandage_waiting_label(wait_member)
	if not wait_lbl.contains("Chest"):
		_fail(failures, "Camp-2.1: bandage waiting label should name part got '%s'" % wait_lbl)
	else:
		_pass()
	var pm_multi: Node = label_world.get_meta("party_manager")
	var multi_ent: Node = _add_living_entity_member(pm_multi, "MultiPart")
	multi_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
	multi_ent.wounds["left_leg"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
	var multi_member: Dictionary = _Snapshot.snapshot_from_member({"name": "MultiPart", "node_ref": multi_ent})
	var multi_hint: String = _MapFieldCare.format_member_field_care_hint(multi_member)
	if not multi_hint.contains("2 part"):
		_fail(failures, "Camp-2.1: member field care hint should count parts got '%s'" % multi_hint)
	else:
		_pass()
	var single_hint: String = _MapFieldCare.format_member_field_care_hint(lbl_member)
	if not single_hint.contains("One part left"):
		_fail(failures, "Camp-2.1: single-part hint expected got '%s'" % single_hint)
	else:
		_pass()
	var next_action: String = _MapFieldCare.format_next_field_care_action(label_world, lbl_member)
	if not next_action.contains("Field pressure"):
		_fail(failures, "Camp-2.1: next field care action should start with pressure got '%s'" % next_action)
	else:
		_pass()
	var party_lbl: String = _CompanyState.format_party_button_label(label_world)
	if not party_lbl.contains("to dress"):
		_fail(failures, "Camp-2.1: party button label should show dress count got '%s'" % party_lbl)
	else:
		_pass()
	var btn_world: Node2D = _make_world(0, 0, true)
	btn_world.set_script(_CampaignWorldScript)
	var player_char := Node2D.new()
	player_char.name = "Character"
	btn_world.add_child(player_char)
	_PartySetup.setup_party(btn_world)
	var pm_btn: Node = btn_world.get_meta("party_manager")
	var btn_ent: Node = _add_living_entity_member(pm_btn, "BtnTint")
	btn_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
	_CompanyState.refresh_party_button(btn_world)
	var pb: Control = _CombatFlow._find_party_button(btn_world)
	if pb == null or not pb is Button:
		_fail(failures, "Camp-2.1: refresh_party_button should find PartyButton on overlay")
	else:
		var party_btn: Button = pb as Button
		if not party_btn.text.contains("to dress"):
			_fail(failures, "Camp-2.1: overlay PartyButton text want dress count got '%s'" % party_btn.text)
		elif not party_btn.has_theme_color_override("font_color"):
			_fail(failures, "Camp-2.1: overlay PartyButton should tint when wounds need dressing")
		elif party_btn.tooltip_text.is_empty():
			_fail(failures, "Camp-2.1: overlay PartyButton tooltip should hint field care")
		else:
			_pass()
	_CompanyState.set_medical_supplies(btn_world, 0)
	_CompanyState.refresh_party_button(btn_world)
	var pb_zero: Control = _CombatFlow._find_party_button(btn_world)
	if pb_zero == null or not pb_zero is Button:
		_fail(failures, "Camp-2.1: PartyButton missing for 0-med tooltip test")
	elif not (pb_zero as Button).tooltip_text.contains("0-med"):
		_fail(
			failures,
			"Camp-2.1: PartyButton tooltip at 0 med should mention 0-med bandages got '%s'"
			% (pb_zero as Button).tooltip_text
		)
	else:
		_pass()
	btn_ent.apply_direct_pressure("chest")
	var btn_member: Dictionary = _Snapshot.snapshot_from_member({"name": "BtnTint", "node_ref": btn_ent})
	var btn_dressed: bool = false
	for attempt in range(24):
		btn_ent.bandaged_parts.erase("chest")
		if btn_ent.self_direct_pressure_part != "chest":
			btn_ent.apply_direct_pressure("chest")
		btn_member = _Snapshot.snapshot_from_member({"name": "BtnTint", "node_ref": btn_ent})
		seed(90300 + attempt)
		if _MapFieldCare.try_field_bandage(btn_world, btn_member):
			btn_dressed = true
			break
	if not btn_dressed:
		_fail(failures, "Camp-2.1: PartyButton clear test could not dress chest")
	else:
		_pass()
	btn_world.set_meta(
		_CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
		{
			"members": [
				{
					"name": "BtnTint",
					"snapshot": {"name": "BtnTint", "has_untreated_wounds": true},
				}
			],
			"deaths": [],
			"winner": "player",
		}
	)
	_CompanyState.set_medical_supplies(btn_world, 0)
	if not _CompanyState.should_show_party_camp_rest_button(btn_world):
		_fail(failures, "Camp-2.1: dressed roster with 0 med should show camp rest button")
	else:
		_pass()
	_CompanyState.refresh_party_button(btn_world)
	var pb_clear: Button = _CombatFlow._find_party_button(btn_world) as Button
	if pb_clear == null:
		_fail(failures, "Camp-2.1: PartyButton missing after dress")
	elif pb_clear.text != "Party" or pb_clear.has_theme_color_override("font_color"):
		_fail(
			failures,
			"Camp-2.1: PartyButton should clear dress tint after dressing got '%s'" % pb_clear.text
		)
	else:
		_pass()
	_free_harness_world(btn_world)
	_cleanup_harness_ui_overlay()
	var part_list: String = _MapFieldCare.format_part_list(PackedStringArray(["chest", "left_leg"]))
	if not part_list.contains("Chest") or not part_list.contains("L.Leg"):
		_fail(failures, "Camp-2.1: format_part_list want human labels got '%s'" % part_list)
	else:
		_pass()
	_CompanyState.set_medical_supplies(label_world, 1)
	var budget_short: Dictionary = _CompanyState.triage_med_budget(label_world)
	if int(budget_short.get("med_shortfall", 0)) < 1:
		_fail(failures, "Camp-2.1: med_shortfall should be positive when under-supplied")
	else:
		_pass()
	var gate_line: String = _CompanyState.format_party_triage_gate_line(label_world)
	if not gate_line.contains("Short"):
		_fail(failures, "Camp-2.1: triage gate should warn med shortfall got '%s'" % gate_line)
	else:
		_pass()
	var short_hud: String = _CompanyState.format_hud_triage_suffix(label_world)
	if not short_hud.contains("about") and not short_hud.contains("need"):
		_fail(failures, "Camp-2.1: HUD suffix should note med estimate got '%s'" % short_hud)
	else:
		_pass()
	_release_harness_world(label_world)

	var undressed_world: Node2D = _make_world(1)
	_CompanyState.mark_tutorial_completed(undressed_world)
	var pm_ud: Node = undressed_world.get_meta("party_manager")
	var ud_ent: Node = _add_living_entity_member(pm_ud, "Clotted")
	ud_ent.wounds["chest"] = [{"current_bleeding_rate": 0.0, "severity": "moderate", "clotted": true}]
	var move_msg: String = _MapBleedPolicy.map_move_blocked_message(undressed_world)
	if not move_msg.contains("Dress wounds") or not move_msg.contains("1 part"):
		_fail(failures, "Camp-2.1: undressed-only map block should mention dressing got '%s'" % move_msg)
	else:
		_pass()
	var hud_ud: String = _MapBleedPolicy.hud_bleed_hint(undressed_world)
	if not hud_ud.contains("Dress wounds"):
		_fail(failures, "Camp-2.1: HUD should hint dress when clotted but undressed got '%s'" % hud_ud)
	else:
		_pass()
	_release_harness_world(undressed_world)

	var step_world: Node2D = _make_world(1)
	_CompanyState.mark_tutorial_completed(step_world)
	var pm_st: Node = step_world.get_meta("party_manager")
	var st_ent: Node = _add_living_entity_member(pm_st, "ClotStep")
	st_ent.wounds["chest"] = [{"current_bleeding_rate": 0.0, "severity": "moderate", "clotted": true}]
	_CompanyState.set_medical_supplies(step_world, 0)
	_MapBleedPolicy.on_overworld_step(step_world)
	if not step_world.has_meta(_MapBleedPolicy.WORLD_META_BLEED_WARN):
		_fail(failures, "Camp-2.1: overworld step should warn when clotted but undressed")
	else:
		var warn_msg: String = str(step_world.get_meta(_MapBleedPolicy.WORLD_META_BLEED_WARN))
		if not warn_msg.contains("undressed"):
			_fail(failures, "Camp-2.1: clotted step warn should mention undressed got '%s'" % warn_msg)
		elif not warn_msg.contains("0-med"):
			_fail(failures, "Camp-2.1: clotted step warn at 0 med should mention 0-med bandages got '%s'" % warn_msg)
		else:
			_pass()
	var settle_hint: String = _CompanyState.format_settlement_field_care_hint(step_world)
	if not settle_hint.contains("1 part") or not settle_hint.contains("Party"):
		_fail(failures, "Camp-2.1: settlement field care hint missing got '%s'" % settle_hint)
	else:
		_pass()
	step_world.set_meta(
		_CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
		{
			"members": [
				{
					"name": "ClotStep",
					"snapshot": {
						"name": "ClotStep",
						"blood_volume": 100.0,
						"total_bleeding_rate": 0.0,
						"has_untreated_wounds": true,
					},
				}
			],
			"deaths": [],
			"winner": "player",
		}
	)
	var worst_settle: Dictionary = _SettlementPanel._worst_triage_from_summary(step_world)
	if not str(worst_settle.get("triage_line", "")).contains("Undressed"):
		_fail(
			failures,
			"Camp-2.1: settlement worst triage should cover clotted undressed got '%s'"
			% str(worst_settle.get("triage_line", ""))
		)
	else:
		_pass()
	_release_harness_world(step_world)

	var persist_world: Node2D = _make_world(1)
	var pm_p: Node = persist_world.get_meta("party_manager")
	var persist_ent: Node = _add_living_entity_member(pm_p, "Persist")
	persist_ent.wounds["chest"] = [{"current_bleeding_rate": 0.6, "severity": "moderate"}]
	var persist_member: Dictionary = _Snapshot.snapshot_from_member({"name": "Persist", "node_ref": persist_ent})
	_MapFieldCare.try_field_pressure(persist_world, persist_member)
	if not _EntityMedical.has_direct_pressure_on_part(persist_ent, "chest"):
		_fail(failures, "Camp-2.1: field pressure should set compression before step")
	else:
		_pass()
	var held_line: String = _MapFieldCare.format_member_pressure_held_line(persist_member)
	if not held_line.contains("Chest"):
		_fail(failures, "Camp-2.1: pressure held line should name part got '%s'" % held_line)
	else:
		_pass()
	_CampaignBridge.advance_party_overworld_minute(persist_world)
	if not _EntityMedical.has_direct_pressure_on_part(persist_ent, "chest"):
		_fail(failures, "Camp-2.1: overworld step must retain field pressure until dressed")
	else:
		_pass()
	_release_harness_world(persist_world)

	_OperationalLog.begin_play_session("headless://camp_field_care_done", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	var log_world: Node2D = _make_world(1)
	var pm_log: Node = log_world.get_meta("party_manager")
	var log_ent: Node = _add_living_entity_member(pm_log, "LogDress")
	log_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
	log_ent.apply_direct_pressure("chest")
	var log_member: Dictionary = _Snapshot.snapshot_from_member({"name": "LogDress", "node_ref": log_ent})
	_CompanyState.set_medical_supplies(log_world, 2)
	var dressed: bool = false
	for attempt in range(24):
		log_ent.bandaged_parts.erase("chest")
		if log_ent.self_direct_pressure_part != "chest":
			log_ent.apply_direct_pressure("chest")
		seed(90210 + attempt)
		if _MapFieldCare.try_field_bandage(log_world, log_member):
			dressed = true
			break
	if not dressed:
		_fail(failures, "Camp-2.1: field care log test could not dress chest")
	else:
		_pass()
	var bandage_logged: bool = false
	var camp_logged: bool = false
	for line in _OperationalLog.get_captured_lines():
		var s: String = str(line)
		if s.contains("field_care bandage") and s.contains("camp_rest_ready"):
			bandage_logged = true
		if s.contains("camp_heal") and s.contains("all_dressed=true"):
			camp_logged = true
	if not bandage_logged:
		_fail(failures, "Camp-2.1: field bandage success should log camp_rest_ready")
	else:
		_pass()
	if _CompanyState.try_camp_heal(log_world, true):
		_pass()
	else:
		_fail(failures, "Camp-2.1: camp heal should succeed after all_dressed log test")
	for line in _OperationalLog.get_captured_lines():
		if str(line).contains("camp_heal") and str(line).contains("all_dressed=true"):
			camp_logged = true
			break
	if not camp_logged:
		_fail(failures, "Camp-2.1: camp heal success should log all_dressed=true")
	else:
		_pass()
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	_release_harness_world(log_world)

	_OperationalLog.begin_play_session("headless://camp_heal_blocked", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	var block_world: Node2D = _make_world(1)
	_CompanyState.set_medical_supplies(block_world, 3)
	var pm_block: Node = block_world.get_meta("party_manager")
	var block_ent: Node = _add_living_entity_member(pm_block, "BlockCamp")
	block_ent.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
	if _CompanyState.try_camp_heal(block_world, true):
		_fail(failures, "Camp-2.1: camp heal should fail when wounds undressed")
	else:
		_pass()
	var block_logged: bool = false
	for line in _OperationalLog.get_captured_lines():
		var s: String = str(line)
		if s.contains("camp_heal blocked:") and s.contains("parts_need=1"):
			block_logged = true
			break
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	if not block_logged:
		_fail(failures, "Camp-2.1: camp heal blocked log should include parts_need")
	else:
		_pass()
	_release_harness_world(block_world)

	var healthy_world: Node2D = _make_world(1)
	_CompanyState.mark_tutorial_completed(healthy_world)
	_CompanyState.set_medical_supplies(healthy_world, 0)
	if _CompanyState.should_show_party_camp_rest_button(healthy_world):
		_fail(failures, "Camp-2.1: healthy roster at 0 med should hide camp rest button")
	else:
		_pass()
	_release_harness_world(healthy_world)

	_OperationalLog.begin_play_session("headless://field_care_hint_zero_med", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	var zero_hint_world: Node2D = _make_world(1, 0, true)
	_CompanyState.set_medical_supplies(zero_hint_world, 0)
	var pm_zh: Node = zero_hint_world.get_meta("party_manager")
	var zh_ent: Node = _add_living_entity_member(pm_zh, "ZeroHint")
	zh_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
	_CampaignBridge.on_return_from_combat(zero_hint_world, "player")
	var zero_hint_ok: bool = false
	for line in _OperationalLog.get_captured_lines():
		if str(line).contains("field_care:") and str(line).contains("0-med bandages OK"):
			zero_hint_ok = true
			break
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	if not zero_hint_ok:
		_fail(failures, "Camp-2.2: post-fight field_care hint at 0 med should mention 0-med bandages")
	else:
		_pass()
	_release_harness_world(zero_hint_world)

	_OperationalLog.begin_play_session("headless://contract_victory_triage", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	var pay_world: Node2D = _make_world(1)
	_CompanyState.set_active_contract(
		pay_world,
		{"contract_title": "Escort", "pay_gold": 100, "contract_type": "escort"}
	)
	var pm_pay: Node = pay_world.get_meta("party_manager")
	var pay_ent: Node = _add_living_entity_member(pm_pay, "PayBleed")
	pay_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
	_CompanyState.apply_contract_victory_pay(pay_world)
	var pay_logged: bool = false
	for line in _OperationalLog.get_captured_lines():
		if str(line).contains("contract_victory triage"):
			pay_logged = true
			break
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	if not pay_logged:
		_fail(failures, "Camp-2.1: contract victory should log triage budget when wounds remain")
	else:
		_pass()
	_release_harness_world(pay_world)

	var mgr_cnt: Node = _MgrScript.new()
	var wounded_cnt: Node = _CoreEntityScript.new()
	wounded_cnt.apply_species()
	wounded_cnt.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
	mgr_cnt.register(wounded_cnt, "player")
	mgr_cnt.register(_CoreEntityScript.new(), "enemy")
	mgr_cnt.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr_cnt.medical_phase = true
	mgr_cnt.medical_phase_winner = "player"
	if _MedicalPhase.winner_side_untreated_part_count(mgr_cnt) != 1:
		_fail(failures, "Camp-2.1: winner_side_untreated_part_count want 1")
	else:
		_pass()
	mgr_cnt.free()

	var bleed_sim_world: Node2D = _make_world(1)
	var pm_bleed: Node = bleed_sim_world.get_meta("party_manager")
	var bleed_sim_ent: Node = _add_living_entity_member(pm_bleed, "BleedSim")
	bleed_sim_ent.wounds["chest"] = [
		{"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
	]
	bleed_sim_ent.apply_direct_pressure("chest")
	var bv_before_pressure: float = float(bleed_sim_ent.blood_volume)
	var cut_before: float = float(bleed_sim_ent.body_cutting.get("chest", 0.0))
	var bleed_member: Dictionary = _Snapshot.snapshot_from_member(
		{"name": "BleedSim", "node_ref": bleed_sim_ent}
	)
	_MapFieldCare.try_field_pressure(bleed_sim_world, bleed_member)
	if float(bleed_sim_ent.blood_volume) > bv_before_pressure + 0.01:
		_fail(failures, "Camp-2.1: field care must not recover blood during active hemorrhage")
	else:
		_pass()
	if float(bleed_sim_ent.body_cutting.get("chest", 0.0)) > cut_before + 0.01:
		_fail(failures, "Camp-2.1: field care procedure must not run tissue healing")
	else:
		_pass()
	_release_harness_world(bleed_sim_world)

	_OperationalLog.begin_play_session("headless://camp_field_care_hint", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	var hint_world: Node2D = _make_world(1, 0, true)
	var pm_h: Node = hint_world.get_meta("party_manager")
	var bleeder: Node = _add_living_entity_member(pm_h, "HintBleed")
	bleeder.wounds["right_arm"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
	_CampaignBridge.on_return_from_combat(hint_world, "player")
	var hint_found: bool = false
	for line in _OperationalLog.get_captured_lines():
		if str(line).contains("field_care:") and str(line).contains("Camp rest"):
			hint_found = true
			if not str(line).contains("bandage_med_est="):
				_fail(failures, "Camp-2.2: field_care hint should log med budget estimates")
			if not str(line).contains("med_shortfall="):
				_fail(failures, "Camp-2.2: field_care hint should log med_shortfall")
			break
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	if not hint_found:
		_fail(failures, "Camp-2.2: on_return_from_combat should log field-care hint when untreated")
	else:
		_pass()
	_release_harness_world(hint_world)

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
	_release_harness_world(debt_world)

	var soft_world: Node2D = _make_world(1, 0, true)
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
	_free_harness_world(soft_world)

	var mood_world: Node2D = _make_world(1)
	var pm_mood: Node = mood_world.get_meta("party_manager")
	pm_mood.members[0]["company_mood"] = 50.0
	_CompanyState.apply_battle_lost_mood(mood_world)
	var after: float = float(pm_mood.members[0].get("company_mood", 50.0))
	if not is_equal_approx(after, 49.55):
		_fail(failures, "Camp-2.6 B3: battle loss mood should be -0.45 on living roster got %.2f" % after)
	else:
		_pass()
	_release_harness_world(mood_world)

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
	_release_harness_world(death_mood_world)

	var multi_death_world: Node2D = _make_world(1, 2)
	var pm_multi_death: Node = multi_death_world.get_meta("party_manager")
	pm_multi_death.members[0]["company_mood"] = 50.0
	_CampaignBridge.build_last_battle_summary(multi_death_world)
	var multi_mood: float = float(pm_multi_death.members[0].get("company_mood", 50.0))
	if not is_equal_approx(multi_mood, 49.5):
		_fail(
			failures,
			"Camp-2.6 B3: two deaths should be -0.50 on survivor got %.2f" % multi_mood
		)
	else:
		_pass()
	_release_harness_world(multi_death_world)

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
	_release_harness_world(r3_mood_world)

	var restart_world: Node2D = _make_world(1, 0, true)
	restart_world.set_script(_CampaignWorldScript)
	PartySetup.setup_party(restart_world)
	var pm_a: Variant = restart_world.get_meta("party_manager")
	PartySetup.setup_party(restart_world)
	var pm_b: Variant = restart_world.get_meta("party_manager")
	var pm_on_world: int = 0
	for child in restart_world.get_children():
		if child.get_script() == _party_manager_script and not child.is_queued_for_deletion():
			pm_on_world += 1
	if pm_a == pm_b or pm_on_world != 1:
		_fail(
			failures,
			"Camp-2.6: setup_party should replace stale world PartyManager (count=%d)" % pm_on_world
		)
	else:
		_pass()
	var overlay_menus: int = 0
	var overlay_buttons: int = 0
	var harness_root: Node = _harness_root()
	if harness_root != null:
		for layer in harness_root.get_children():
			if layer.name != "UIOverlayLayer":
				continue
			for gc in layer.get_children():
				if gc.get_script() == _party_menu_script:
					overlay_menus += 1
				elif gc is Button and gc.name == "PartyButton":
					overlay_buttons += 1
	if overlay_menus != 1 or overlay_buttons != 1:
		_fail(
			failures,
			"Camp-2.6: setup_party should leave one PartyMenu and PartyButton on overlay got menu=%d button=%d"
			% [overlay_menus, overlay_buttons]
		)
	else:
		_pass()
	_free_harness_world(restart_world)
	_cleanup_harness_ui_overlay()

	_run_camp_4_contract_flavor(failures)
	_run_encounter_entry_rollback(failures)
	_run_combat_start_abort_cleanup(failures)


static func _run_combat_start_abort_cleanup(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1, 0, true)
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
	if is_instance_valid(dummy) and not dummy.is_queued_for_deletion():
		_fail(failures, "Camp-1.4: aborted combat start should free spawned enemy nodes")
	else:
		_pass()
	_free_harness_world(world)


static func _run_encounter_entry_rollback(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(1, 0, true)
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
	_free_harness_world(world)


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
	world_sk.free()
	enc_sk.free()
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
	if int(escort.get(_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 5:
		_fail(failures, "Camp-4/III-4: Escort template want player_front_count=5 (Formation 5x2, not Skirmish 7-wide)")
	else:
		_pass()
	var world_esc: Node2D = _make_world(7)
	world_esc.set_meta(
		_CombatConstants.WORLD_META_COMBAT_ENCOUNTER,
		{_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 5}
	)
	_CampaignBridge.refresh_party_formation_meta(world_esc)
	var pf_esc: Dictionary = world_esc.get_meta("party_formation", {}) as Dictionary
	if int(pf_esc.get("files", 0)) != 5 or int(pf_esc.get("ranks", 0)) != 2:
		_fail(
			failures,
			"Camp-4/III-4: escort party_formation want 5x2 got files=%d ranks=%d"
			% [int(pf_esc.get("files", 0)), int(pf_esc.get("ranks", 0))]
		)
	else:
		_pass()
	world_esc.free()
	var world_esc_pc: Node2D = _make_world(7)
	var enc_esc: Node2D = _EncounterNodeScript.new()
	enc_esc.encounter_config = escort
	_CampaignBridge.prepare_combat_from_encounter(world_esc_pc, enc_esc)
	var pf_esc_pc: Dictionary = world_esc_pc.get_meta("party_formation", {}) as Dictionary
	if int(pf_esc_pc.get("files", 0)) != 5 or int(pf_esc_pc.get("ranks", 0)) != 2:
		_fail(
			failures,
			"Camp-4/III-4: escort prepare_combat want 5x2 party_formation got files=%d ranks=%d"
			% [int(pf_esc_pc.get("files", 0)), int(pf_esc_pc.get("ranks", 0))]
		)
	else:
		_pass()
	world_esc_pc.free()
	enc_esc.free()
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
	elif not lbl.contains("5-wide"):
		_fail(failures, "Camp-4/III-4: escort marker label should show 5-wide formation hint")
	else:
		_pass()
	var skirmish_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[0])
	if not skirmish_lbl.contains("7-wide"):
		_fail(failures, "Camp-4/III-4: skirmish marker label should show 7-wide formation hint")
	else:
		_pass()
	var world_tut_pc: Node2D = _make_world(2)
	var enc_tut: Node2D = _EncounterNodeScript.new()
	enc_tut.encounter_config = _ContractSpawner.build_encounter_config(_ContractSpawner.TUTORIAL_TEMPLATE)
	_CampaignBridge.prepare_combat_from_encounter(world_tut_pc, enc_tut)
	var pf_tut: Dictionary = world_tut_pc.get_meta("party_formation", {}) as Dictionary
	if int(pf_tut.get("files", 0)) != 2:
		_fail(
			failures,
			"Camp-4/III-4: tutorial prepare_combat want 2-wide party_formation got files=%d ranks=%d"
			% [int(pf_tut.get("files", 0)), int(pf_tut.get("ranks", 0))]
		)
	else:
		_pass()
	world_tut_pc.free()
	enc_tut.free()
	var tut_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.TUTORIAL_TEMPLATE)
	if not tut_lbl.contains("2-wide"):
		_fail(failures, "Camp-4/III-4: tutorial marker label should show 2-wide formation hint")
	else:
		_pass()


static func _run_persistence_roundtrip(failures: PackedStringArray) -> void:
	_Persistence.clear_slot()
	var world: Node2D = _make_world(0, 0, true)
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
	var fresh: Node2D = _make_world(0, 0, true)
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
	if _Persistence.normalize_marker_kind_for_restore("practice", {"tutorial": false}) != "contract":
		_fail(failures, "P2 persistence: legacy practice marker should restore as contract")
	else:
		_pass()
	if _Persistence.normalize_marker_kind_for_restore("practice", {"tutorial": true}) != "tutorial":
		_fail(failures, "P2 persistence: legacy practice+tutorial config should restore as tutorial")
	else:
		_pass()
	var legacy_world: Node2D = _make_world(0, 0, true)
	_add_player_at_camp(legacy_world)
	var pm_legacy: Node = legacy_world.get_meta("party_manager")
	_add_living_entity_member(pm_legacy, "Brother0")
	var legacy_cfg: Dictionary = _ContractSpawner.build_encounter_config(
		_ContractSpawner.CONTRACT_TEMPLATES[0]
	)
	legacy_cfg["training"] = true
	var legacy_save: Dictionary = {
		"version": _Persistence.SAVE_VERSION,
		"company_state": {"gold": 50},
		"roster": [{"name": "Brother0", "company_mood": 50.0, "entity": {}}],
		"remaining_encounters": [
			{
				"tile": [1, 0],
				"encounter_config": legacy_cfg,
				"enemy_count": 2,
				"enemy_formation": {},
				"contract_marker_label": "Legacy",
				"marker_kind": "practice",
			}
		],
		"player_tile": [0, 0],
	}
	var leg_rng := RandomNumberGenerator.new()
	leg_rng.seed = 9
	_Persistence.apply_save(legacy_world, legacy_save, leg_rng, null)
	var legacy_marker: Node2D = null
	for child in legacy_world.get_children():
		if child.get_script() == _EncounterNodeScript:
			legacy_marker = child
			break
	if legacy_marker == null:
		_fail(failures, "P2 persistence: apply_save should restore legacy practice encounter marker")
	elif str(legacy_marker.marker_kind) != "contract":
		_fail(
			failures,
			"P2 persistence: legacy practice marker_kind want contract got %s"
			% str(legacy_marker.marker_kind)
		)
	else:
		_pass()
	if (
		legacy_marker != null
		and (legacy_marker.encounter_config as Dictionary).has("training")
	):
		_fail(failures, "P2 persistence: restored encounter_config should drop legacy training flag")
	else:
		_pass()
	_release_harness_world(legacy_world)
	_Persistence.clear_slot()
	if _Persistence.has_save():
		_fail(failures, "P2 persistence: clear_slot should remove save file")
	else:
		_pass()
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
	_release_harness_world(world)
	_release_harness_world(fresh)
	_cleanup_harness_ui_overlay()
