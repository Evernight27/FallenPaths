class_name CompanyDayCycle
extends RefCounted

## CompanyDayCycle -- day tick orchestration (end day request, auto step-tick, provisions, desertion pass).

# Runtime preload -- circular dependency (CompanyState preloads CompanyDayCycle).
static var _company_state_cache: Variant = null
static var _company_mood_cache: Variant = null
static var _company_economy_cache: Variant = null


static func _get_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


static func _get_mood() -> GDScript:
    if _company_mood_cache == null:
        _company_mood_cache = load("res://world/CompanyMood.gd")
    return _company_mood_cache


static func _get_economy() -> GDScript:
    if _company_economy_cache == null:
        _company_economy_cache = load("res://world/CompanyEconomy.gd")
    return _company_economy_cache


static func try_advance_day(world: Node2D) -> bool:
    if world == null:
        return false
    var bill: int = _get_state().compute_next_wage_bill(world)
    var gold_before: int = _get_state().get_gold(world)
    var state: Dictionary = _get_state().get_state(world).duplicate()
    state["gold"] = state.get("gold", 0) - bill
    state["day_index"] = state.get("day_index", 0) + 1
    state["overworld_step_count"] = 0
    _get_state()._write_state(world, state)
    if gold_before < bill and bill > 0:
        _get_mood()._apply_unpaid_wage_mood(world)
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world(_get_economy().format_wages_short_log(gold_before, bill))
    on_day_tick(world)
    if _get_state().read_stub_bankrupt_mode() == "desertion":
        _run_daily_desertion_pass(world)
    _get_state()._warn_if_gold_below_next_wage(world)
    _get_state()._warn_if_company_insolvent(world)
    if _get_state().count_living_roster(world) <= 0:
        _trigger_company_collapsed(world, "bankrupt")
        return true
    var autosaved: bool = _get_state().try_autosave(world)
    if OperationalLog.is_play_session_active():
        var autosave_bit: String = ""
        if autosaved:
            autosave_bit = " autosave=true"
        (
            OperationalLog
            . play_world(
                (
                    "company_day_advanced day=%d wages_paid=%d gold=%d living=%d%s"
                    % [
                        _get_state().get_day_index(world),
                        bill,
                        _get_state().get_gold(world),
                        _get_state().count_living_roster(world),
                        autosave_bit,
                    ]
                )
            )
        )
    return true


static func on_day_tick(world: Node2D) -> void:
    if world == null:
        return
    if _get_state().read_stub_provisions_enabled():
        _apply_daily_provisions(world)
    _apply_roster_daily_fatigue(world)
    _get_state().advance_school_scouts(world)


## Campaign weariness: each day of operations (marching, operating) adds a little fatigue to every member.
## Recovered by camp rest. Kept small so a rested company stays fresh; compounds if the player never rests.
static func _apply_roster_daily_fatigue(world: Node2D) -> void:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("add_campaign_fatigue_day"):
            entity.add_campaign_fatigue_day()


static func _apply_daily_provisions(world: Node2D) -> void:
    var need: int = _get_state().count_living_roster(world) * _get_economy().FOOD_PER_MEMBER_PER_DAY
    if need <= 0:
        return
    var have: int = _get_state().get_food_supplies(world)
    var fed_fraction: float = 1.0
    if have >= need:
        _get_state().set_food_supplies(world, have - need)
        fed_fraction = 1.0
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world("provisions fed=%d food_left=%d" % [need, _get_state().get_food_supplies(world)])
    else:
        if have > 0:
            _get_state().set_food_supplies(world, 0)
        fed_fraction = clampf(float(have) / float(need), 0.0, 1.0)
        _get_mood()._apply_not_fed_mood(world)
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world(
                "provisions short need=%d had=%d mood=%.0f" % [need, have, _get_mood().MOOD_NOT_FED_DELTA]
            )
    _apply_roster_nutrition(world, fed_fraction)


## Set each living member's nutrition level from the day's feeding fraction (1.0 = well-fed, <1.0 = short rations).
## Malnutrition slows wound healing (see CoreEntity._get_nutrition_healing_speed_mult).
static func _apply_roster_nutrition(world: Node2D, fed_fraction: float) -> void:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("set_nutrition_level"):
            entity.set_nutrition_level(fed_fraction)


static func on_overworld_step(world: Node2D) -> void:
    var mode: String = _get_state().read_stub_day_tick_mode()
    _increment_overworld_step(world)
    if mode == "end_day":
        _get_state().refresh_hud(world)
        return
    if mode == "steps" or mode == "hybrid":
        if _get_state().get_overworld_step_count(world) >= _get_state().read_stub_steps_per_day():
            try_advance_day(world)


static func request_end_day(world: Node2D) -> bool:
    var mode: String = _get_state().read_stub_day_tick_mode()
    if mode == "steps":
        return false
    if mode == "hybrid" and not _get_state()._player_on_camp_tile(world):
        return false
    return try_advance_day(world)


static func _increment_overworld_step(world: Node) -> void:
    var state: Dictionary = _get_state().get_state(world).duplicate()
    state["overworld_step_count"] = state.get("overworld_step_count", 0) + 1
    world.set_meta(_get_state().WORLD_META_COMPANY_STATE, state)


static func can_offer_end_day(world: Node2D) -> bool:
    var mode: String = _get_state().read_stub_day_tick_mode()
    if mode == "end_day":
        return true
    if mode == "hybrid":
        return _get_state()._player_on_camp_tile(world)
    return false


static func format_day_hud_line(world: Node) -> String:
    var day: int = _get_state().get_day_index(world)
    if _get_state().read_stub_day_tick_mode() != "hybrid":
        return "Day: %d" % day
    return (
        "Day %d / %d/%d steps"
        % [day, _get_state().get_overworld_step_count(world), _get_state().read_stub_steps_per_day()]
    )


static func format_party_end_day_unavailable_hint(world: Node2D) -> String:
    var st: GDScript = _get_state()
    if world == null or st.can_offer_end_day(world):
        return ""
    if st.read_stub_day_tick_mode() == "hybrid":
        var steps_left: int = maxi(0, st.read_stub_steps_per_day() - st.get_overworld_step_count(world))
        if steps_left <= 0:
            return "End day: stand on the camp tile to pay wages -- or move to finish today's steps."
        return "End day: stand on the camp tile (0,0) -- or take %d more step(s) for an auto day tick." % steps_left
    return ""


static func format_party_menu_footer(world: Node2D) -> String:
    var lines: PackedStringArray = PackedStringArray()
    var end_day_hint: String = format_party_end_day_unavailable_hint(world)
    if not end_day_hint.is_empty():
        lines.append(end_day_hint)
    var desertion_hint: String = _get_mood().format_party_desertion_risk_footer(world)
    if not desertion_hint.is_empty():
        lines.append(desertion_hint)
    var autosave_hint: String = _get_state().format_party_autosave_footer()
    if not autosave_hint.is_empty():
        lines.append(autosave_hint)
    return "\n".join(lines)


static func _run_daily_desertion_pass(world: Node2D) -> void:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var deserted_names: Array = []
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        if (node_ref as Node).get(DataKeys.COMBATANT_IS_PARTY_LEADER) == true:
            continue
        # XSurgeon: the dedicated surgeon node is not freed on desertion (would break future hires).
        if PlayerCompanionSetup.member_is_surgeon(node_ref as Node):
            continue
        var mood: float = float(m.get("company_mood", _get_mood().MOOD_DEFAULT))
        if mood > _get_mood().MOOD_ANGRY_THRESHOLD:
            continue
        if rng.randf() >= _get_mood().MOOD_DESERTION_CHANCE:
            continue
        var name_s: String = str(m.get("name", (node_ref as Node).name))
        deserted_names.append({"name": name_s, "mood": mood})
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world("brother_deserted name=%s mood=%.1f" % [name_s, mood])
    if deserted_names.size() > 0 and OperationalLog.is_play_session_active():
        var summary_bits: PackedStringArray = PackedStringArray()
        for row in deserted_names:
            if row is Dictionary:
                summary_bits.append(
                    (
                        "%s(mood=%.0f)"
                        % [str((row as Dictionary).get("name", "")), float((row as Dictionary).get("mood", 0.0))]
                    )
                )
        OperationalLog.play_world("desertion summary=%s" % ", ".join(summary_bits))
    for row in deserted_names:
        var name_s: String = str(row.get("name", "")) if row is Dictionary else str(row)
        if pm.has_method("remove_member_by_name"):
            pm.remove_member_by_name(name_s)
        var member_node: Node = _get_state()._resolve_member_node_by_name(world, name_s)
        if is_instance_valid(member_node):
            member_node.queue_free()
    if _get_state().count_living_roster(world) <= 0:
        _trigger_company_collapsed(world, "bankrupt")


static func _trigger_company_collapsed(world: Node2D, reason: String) -> void:
    if world == null:
        return
    if _get_state().is_bankrupt(world):
        return
    _get_state().set_bankrupt(world, true)
    if world.has_method("_company_run_end"):
        world.call_deferred("_company_run_end", reason)

