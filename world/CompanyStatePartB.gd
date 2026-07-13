class_name CompanyStatePartB
extends CompanyStatePartA


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
        var steps_left: int = maxi(0, read_stub_steps_per_day() - get_overworld_step_count(world))
        if steps_left <= 0:
            return "End day: stand on the camp tile to pay wages -- or move to finish today's steps."
        return "End day: stand on the camp tile (0,0) -- or take %d more step(s) for an auto day tick." % steps_left
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
            tips.append("Field care -- %s; 0-med bandages; win contracts for camp med (+4)." % march)
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
            (
                "Company med depleted -- bandages free in battle; on map use field bandage at %.0f%% efficacy "
                % (factor * 100.0)
            )
            + " (pack / stabilize need -1 med when available)."
        )
    if med == 1:
        return (
            "One med left -- pack or stabilize in medical phase costs your last supply; "
            + "battle bandages are free; save med for map dressings + camp rest."
        )
    if med <= 5:
        return "Med supplies tight (%d) -- battle bandages free; plan field dressings + camp rest on the map." % med
    if factor < 0.99:
        return "Medical supplies low - treatment efficacy %.0f%%." % (factor * 100.0)
    return ""


## === Settlement / Battle UI hints ===

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
        (
            "Low company mood -- %d brother(s) may default to wall form in the next fight "
            + "(unless they have an explicit form preference)."
        )
        % low
    )


## === Refresh / Visibility (delegated) ===

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

## === HUD creation (delegated) ===


static func _ensure_hud_on_world(world: Node2D) -> void:
    _CompanyEconomy._ensure_hud_on_world(world)


static func _get_or_create_overlay(root: Node) -> CanvasLayer:
    return _CompanyEconomy._get_or_create_overlay(root)


static func _resolve_hud(world: Node) -> Control:
    return _CompanyEconomy._resolve_hud(world)


## === Post-victory afflictions (delegated) ===

## === Post-victory afflictions (delegated) ===


static func apply_post_victory_afflictions(world: Node2D) -> PackedStringArray:
    var rng: RandomNumberGenerator = _CampaignBridge.resolve_overworld_rng(world)
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    return _CampaignAfflictions.apply_after_victory(world, rng)


## === Bridge accessor (used by company modules) ===

## === Bridge accessor (used by company modules) ===


static func get_campaign_bridge() -> GDScript:
    return _CampaignBridge


## === Internal helpers (used by multiple modules) ===

## === Internal helpers (used by multiple modules) ===


static func _warn_if_company_insolvent(world: Node) -> void:
    if world == null or get_gold(world) >= 0:
        return
    if not _OperationalLog.is_play_session_active():
        return
    _OperationalLog.play_world(format_company_debt_log(get_gold(world)))


static func format_company_debt_log(gold: int) -> String:
    return "Company is in debt (%dg). Low-mood brothers may desert at the next day end." % gold


static func _warn_if_gold_below_next_wage(world: Node) -> void:
    var bill: int = compute_next_wage_bill(world)
    if get_gold(world) >= bill:
        return
    if not _OperationalLog.is_play_session_active():
        return
    _OperationalLog.play_world(
        "company_wages: gold=%d below next wage bill=%d (day %d)" % [get_gold(world), bill, get_day_index(world)]
    )


## === Party manager resolution (shared utility) ===

## === Party manager resolution (shared utility) ===


static func _resolve_party_manager(world: Node) -> Node:
    if world == null or not world.has_meta("party_manager"):
        return null
    var pm: Variant = world.get_meta("party_manager")
    return pm if pm is Node else null


## === Resolve / Battle hooks (delegated to CompanyEconomy) ===

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

## === Triage / Med helpers (delegated to CompanyCamp) ===


static func triage_med_budget(world: Node2D) -> Dictionary:
    return _CompanyCamp.triage_med_budget(world)


static func format_party_triage_gate_line(world: Node2D) -> String:
    return _CompanyCamp.format_party_triage_gate_line(world)


static func format_field_care_complete_line(world: Node2D) -> String:
    return _CompanyCamp.format_field_care_complete_line(world)


## === Camp rest button label (delegated to CompanyCamp) ===

## === Camp rest button label (delegated to CompanyCamp) ===


static func format_camp_rest_button_label(world: Node2D, from_party_menu: bool = false) -> String:
    return _CompanyCamp.format_camp_rest_button_label(world, from_party_menu)


static func format_camp_heal_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
    return _CompanyCamp.format_camp_heal_block_reason(world, from_party_menu)


## === Autosave (delegated to CompanyEconomy) ===

## === Autosave (delegated to CompanyEconomy) ===


static func try_autosave(world: Node2D) -> bool:
    return _CompanyEconomy.try_autosave(world)


static func format_autosave_action_suffix() -> String:
    return _CompanyEconomy.format_autosave_action_suffix()


## === Medical supply factor (delegated to CompanyEconomy) ===

## === Medical supply factor (delegated to CompanyEconomy) ===


static func compute_medical_supply_factor(world: Node) -> float:
    return _CompanyEconomy.compute_medical_supply_factor(world)


## === Wages short log (delegated to CompanyEconomy) ===

## === Wages short log (delegated to CompanyEconomy) ===


static func format_wages_short_log(gold_before: int, bill: int) -> String:
    return _CompanyEconomy.format_wages_short_log(gold_before, bill)


## === Settlement field care hint (delegated to CompanyCamp) ===

## === Settlement field care hint (delegated to CompanyCamp) ===


static func format_settlement_field_care_hint(world: Node2D) -> String:
    return _CompanyCamp.format_settlement_field_care_hint(world)


## === Member node resolution (internal helper used by CompanyDayCycle desertion pass) ===

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
