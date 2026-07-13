class_name CombatFlow
extends RefCounted

## Handles combat initiation and battle-end cleanup. Used by main.gd.
## Optional world meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** (`"combat_encounter"`): copied into
## **`BattleScene.start`** |' **`CombatManager.encounter`** before **`start()`** (doctrine, depth polearm AI mults,
## posture, morale, ...  -  see **`CombatManager`** default_enc in **`CombatManager.gd`**).
## Encounter nodes set meta via **`CampaignEncounterBridge.prepare_combat_from_encounter`**.

# Runtime preload ' circular dependency (CompanyState preloads CombatFlow).
static var _company_state_cache: Variant = null


static func _get_company_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


static func start_combat(world: Node2D, enemies: Array):
    var players: Array = CampaignEncounterBridge.get_fightable_party_nodes(world)
    if players.is_empty():
        if not CombatConstants.is_headless_harness_quiet():
            OperationalLog.warn(
                "CombatFlow.start_combat: no living players (check world meta 'party_manager', members[], node_ref)."
            )
        CampaignEncounterBridge.abort_contract_encounter_entry(world)
        return
    var player_node: Node = world.get_node_or_null("Character")
    if enemies.is_empty():
        CampaignEncounterBridge.abort_contract_encounter_entry(world)
        return
    if OperationalLog.is_play_session_active():
        var roster: PackedStringArray = PackedStringArray()
        for p in players:
            if p is Node:
                var role: String = "leader" if p.get("is_party_leader") == true else "member"
                roster.append("%s(%s)" % [str(p.name), role])
        OperationalLog.play_combat("party_entering_combat count=%d [%s]" % [players.size(), ", ".join(roster)])
    for p in players:
        if p.has_method("set_process_input"):
            p.set_process_input(false)
    var pb = _find_party_button(world)
    if pb:
        pb.visible = false
    _get_company_state().set_overworld_hud_visible(world, false)
    CampaignEncounterBridge.clear_battle_kill_log(world)

    var battle_script = load(ResourcePaths.BATTLE_SCENE)
    if battle_script == null:
        OperationalLog.warn("CombatFlow.start_combat: BattleScene script missing")
        _restore_overworld_after_aborted_combat(world, player_node)
        return
    var current = world.get_tree().get_current_scene()
    var battle = battle_script.new()
    battle.parent_scene = current
    world.get_tree().root.add_child(battle)
    world.set_meta("_combat_enemies", enemies)

    await world.get_tree().process_frame
    if not is_instance_valid(world) or not world.is_inside_tree():
        return
    if battle.has_method("start"):
        var party_formation: Dictionary = (
            world.get_meta("party_formation", {}) if world.has_meta("party_formation") else {}
        )
        var enemy_formation: Dictionary = (
            world.get_meta("enemy_formation", {}) if world.has_meta("enemy_formation") else {}
        )
        var combat_encounter: Dictionary = (
            world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
            if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
            else {}
        )
        OperationalLog.play_combat_start(
            players.size(), enemies.size(), party_formation, enemy_formation, combat_encounter
        )
        battle.start(players, enemies, party_formation, enemy_formation, combat_encounter)
    await world.get_tree().process_frame
    if not is_instance_valid(world) or not world.is_inside_tree():
        return
    if not is_instance_valid(battle):
        return
    if battle.has_signal("battle_ended"):
        battle.connect("battle_ended", Callable(world, "_on_battle_ended"), CONNECT_ONE_SHOT)


static func handle_battle_ended(world: Node2D, winner: String, defeated: Node):
    if not OperationalLog.is_play_session_active():
        var def_name: String = str(defeated.name) if defeated != null else "null"
        CombatDebug.combat_session("handle_battle_ended winner=%s defeated=%s" % [winner, def_name])
    await world.get_tree().process_frame
    var player = world.get_node_or_null("Character")
    var player_lost := winner != "player"
    if not OperationalLog.is_play_session_active():
        var outcome: String = "defeat" if player_lost else "victory"
        CombatDebug.combat_session("handle_battle_ended player_lost=%s => %s" % [player_lost, outcome])

    if player_lost:
        CampaignEncounterBridge.build_last_battle_summary(world, winner)
        var contract: Dictionary = _get_company_state().get_active_contract(world)
        var lost_contract: Dictionary = contract.duplicate(true)
        var ends_run: bool = _get_company_state().defeat_should_end_company_run(contract)
        var soft_retry: bool = not contract.is_empty() and _get_company_state().is_tutorial_contract(contract)
        var death_lines: PackedStringArray = _get_company_state().format_last_battle_death_lines(world)
        if ends_run:
            BattleEndHandler.handle_defeat(world, player, winner)
        elif not contract.is_empty():
            _get_company_state().apply_battle_lost_mood(world)
        CampaignEncounterBridge.clear_transient_combat_meta(world)
        _apply_last_fought_day_to_roster(world)
        _get_company_state().clear_active_contract(world)
        if ends_run:
            var title: String = str(contract.get("contract_title", "Contract"))
            var detail: String = "Failed: %s. The company cannot recover this contract." % title
            detail = _append_death_recap_to_detail(detail, death_lines)
            await CompanyRunEndPanel.show_and_await(world, "contract_failed", detail)
        elif soft_retry:
            var kind: String = "Tutorial" if contract.get("tutorial", false) else "Practice"
            var detail: String = "%s lost. You'll return to camp  -  try again when ready." % kind
            detail = _append_death_recap_to_detail(detail, death_lines)
            await CompanyRunEndPanel.show_and_await(world, "tutorial_failed", detail)
            resume_overworld_after_soft_defeat(world, lost_contract)
        else:
            var detail: String = "Battle lost. Return to camp and recover."
            detail = _append_death_recap_to_detail(detail, death_lines)
            await CompanyRunEndPanel.show_and_await(world, "soft_defeat_resume", detail)
            resume_overworld_after_soft_defeat(world, lost_contract)
        return

    BattleEndHandler.handle_victory(world, player, winner)
    CampaignEncounterBridge.on_return_from_combat(world, winner)
    _apply_last_fought_day_to_roster(world)
    await SettlementPanel.show_and_await(world)
    var pb = _find_party_button(world)
    if pb:
        pb.visible = true
    _get_company_state().set_overworld_hud_visible(world, true)
    _get_company_state().refresh_hud(world)


## Tutorial (and other non-run-ending) losses: keep company met" restore map UI.
static func _restore_overworld_after_aborted_combat(world: Node2D, player: Node) -> void:
    if world == null:
        return
    BattleEndHandler.restore_overworld_party(world, player, true)
    CampaignEncounterBridge.sync_overworld_player_grid_anchor(world)
    var pb_abort := _find_party_button(world)
    if pb_abort:
        pb_abort.visible = true
    _get_company_state().set_overworld_hud_visible(world, true)
    _get_company_state().refresh_hud(world)


static func resume_overworld_after_soft_defeat(world: Node2D, lost_contract: Dictionary) -> void:
    if world == null:
        return
    var player: Node = world.get_node_or_null("Character")
    BattleEndHandler.restore_overworld_party(world, player, true)
    CampaignEncounterBridge.sync_overworld_player_grid_anchor(world)
    for line in _get_company_state().apply_casualty_cleanup(world):
        OperationalLog.play_world(line)
    CampaignEncounterBridge.nudge_player_toward_camp_tile(world)
    var pb := _find_party_button(world)
    if pb:
        pb.visible = true
    _get_company_state().set_overworld_hud_visible(world, true)
    _get_company_state().refresh_hud(world)
    var rng: RandomNumberGenerator = CampaignEncounterBridge.resolve_overworld_rng(world)
    var enemy_scene: PackedScene = CampaignEncounterBridge.resolve_enemy_scene(world)
    if rng != null:
        ContractSpawner.ensure_special_encounter_present(world, rng, enemy_scene, lost_contract)
    _get_company_state().try_autosave(world)


static func _apply_last_fought_day_to_roster(world: Node2D):
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    var day_index: int = _get_company_state().get_day_index(world)
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("_get_training_pending"):
            entity.last_fought_day = day_index


static func _append_death_recap_to_detail(detail: String, death_lines: PackedStringArray) -> String:
    if death_lines.is_empty():
        return detail
    var block: String = "\n".join(death_lines)
    if detail.is_empty():
        return block
    return "%s\n\n%s" % [detail, block]


static func _find_party_button(world: Node2D) -> Control:
    if world == null or not world.is_inside_tree():
        return null
    var root = world.get_tree().root
    for child in root.get_children():
        if "name" in child and child.name == "UIOverlayLayer":
            if child.has_node("PartyButton"):
                var pb = child.get_node_or_null("PartyButton")
                if is_instance_valid(pb):
                    return pb
            for gc in child.get_children():
                if "name" in gc and gc.name == "PartyButton":
                    return gc
    for child in root.get_children():
        if child.has_method("find_node"):
            var pb = child.find_node("PartyButton", true, false)
            if pb != null:
                return pb
        if "name" in child and child.name == "PartyButton":
            return child
    return null
