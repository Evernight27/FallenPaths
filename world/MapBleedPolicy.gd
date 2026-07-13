class_name MapBleedPolicy
extends RefCounted

## Camp-2.1 map bleed policy (D-bleed B + tutorial block until first win).
## Uses `PartyRowFormatter` / `BleedingConstants` triage bands  -  do not retune bleed constants here.

const POLICY_WARN_ETA := "warn_eta"
const POLICY_BLOCK := "block"
const WORLD_META_BLEED_WARN := "map_bleed_last_warn"
# Runtime preload ' circular dependency (CompanyState preloads CompanyHud |' MapBleedPolicy).
static var _company_state_cache: Variant = null


static func _get_company_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


static func effective_policy(world: Node2D) -> String:
    if world == null:
        return POLICY_WARN_ETA
    if not _get_company_state().is_tutorial_completed(world):
        return POLICY_BLOCK
    return _get_company_state().read_stub_map_bleed_policy()


static func should_block_map_move(world: Node2D) -> bool:
    if world == null:
        return false
    if effective_policy(world) != POLICY_BLOCK:
        return false
    return CampaignEncounterBridge.party_has_untreated_wounds(world) or _party_has_active_bleed(world)


static func should_block_entering_combat(world: Node2D) -> bool:
    return should_block_map_move(world)


static func party_has_map_bleed_risk(world: Node2D) -> bool:
    if world == null:
        return false
    if CampaignEncounterBridge.party_has_untreated_wounds(world):
        return true
    return _party_has_active_bleed(world)


static func _party_has_active_bleed(world: Node2D) -> bool:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity == null:
            continue
        if CombatantEntityAccess.get_total_bleeding_rate_from_node(entity) > 0.0:
            return true
    return false


static func worst_triage_summary(world: Node2D) -> Dictionary:
    return PartyRowFormatter.worst_triage_from_member_rows(CampaignEncounterBridge.party_member_snapshots(world))


static func on_overworld_step(world: Node2D) -> void:
    if world == null or not party_has_map_bleed_risk(world):
        if world != null and world.has_meta(WORLD_META_BLEED_WARN):
            world.remove_meta(WORLD_META_BLEED_WARN)
        return
    var summary: Dictionary = worst_triage_summary(world)
    if summary.is_empty():
        if CampaignEncounterBridge.party_has_untreated_wounds(world):
            var parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
            var msg_clot: String = (
                "Wounds undressed on map  -  %d part(s) need dressing in Party (%s)."
                % [parts, _get_company_state().format_field_care_march_chain()]
            )
            msg_clot += _med_budget_step_suffix(world)
            if world.has_meta(WORLD_META_BLEED_WARN) and str(world.get_meta(WORLD_META_BLEED_WARN)) == msg_clot:
                return
            world.set_meta(WORLD_META_BLEED_WARN, msg_clot)
            CombatDebug.world_session(msg_clot)
        return
    var line: String = str(summary.get("triage_line", ""))
    var msg: String = (
        "Bleeding on map  -  %s: %s. Open Party for field care or finish treatment."
        % [
            str(summary.get("name", "ally")),
            line,
        ]
    )
    if CampaignEncounterBridge.party_has_untreated_wounds(world):
        var parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
        msg = (
            "Bleeding on map  -  %s: %s. %d part(s) need dressing in Party (%s)."
            % [
                str(summary.get("name", "ally")),
                line,
                parts,
                _get_company_state().format_field_care_march_chain(),
            ]
        )
    msg += _med_budget_step_suffix(world)
    if world.has_meta(WORLD_META_BLEED_WARN) and str(world.get_meta(WORLD_META_BLEED_WARN)) == msg:
        return
    world.set_meta(WORLD_META_BLEED_WARN, msg)
    CombatDebug.world_session(msg)


static func map_move_blocked_message(world: Node2D) -> String:
    if CampaignEncounterBridge.party_has_untreated_wounds(world) and not _party_has_active_bleed(world):
        var parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
        return (
            "Dress wounds in Party  -  %d part(s) need %s before moving on the map."
            % [parts, _get_company_state().format_field_care_march_chain()]
        )
    var summary: Dictionary = worst_triage_summary(world)
    if summary.is_empty():
        return "Stabilize bleeding in Party before moving on the map."
    return (
        "Stabilize first  -  %s: %s (Party --'??'' field care or camp)."
        % [
            str(summary.get("name", "ally")),
            str(summary.get("triage_line", "")),
        ]
    )


static func hud_bleed_hint(world: Node2D) -> String:
    if not party_has_map_bleed_risk(world):
        return ""
    var dress_parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
    if dress_parts > 0 and not _party_has_active_bleed(world):
        return (
            "Dress wounds  -  %d part(s) '. Party '. %s"
            % [dress_parts, _get_company_state().format_field_care_march_chain()]
        )
    var summary: Dictionary = worst_triage_summary(world)
    if summary.is_empty():
        return "Bleeding  -  open Party"
    var line: String = str(summary.get("triage_line", "open Party"))
    if dress_parts > 0:
        return "Bleeding  -  %s '. %d part(s) to dress" % [line, dress_parts]
    return "Bleeding  -  %s" % line


static func _med_budget_step_suffix(world: Node2D) -> String:
    if world == null:
        return ""
    var med_left: int = _get_company_state().get_medical_supplies(world)
    var budget: Dictionary = _get_company_state().triage_med_budget(world)
    var shortfall: int = budget.get("med_shortfall", 0)
    if med_left <= 0:
        return " 0-med bandages OK on map."
    if shortfall > 0:
        return " Short %d med for dressings + camp." % shortfall
    return ""
