class_name CompanyCamp
extends RefCounted

## CompanyCamp -- camp healing gates/execution, tool repair, field care formatting/status.

## CAMP_HEAL_ENTRY.
const CAMP_HEAL_ENTRY: String = "both"
## A camp rest is "+1 day" (the day counter advances by 1), so it must apply one full day of healing.
## Healing durations are defined in days (HealingConstants.SECONDS_PER_DAY = 86400 s), so the rest feeds a
## full day of game-time into the exponential healing/bleeding advance. (The old 600 s x 3.0 = 1800 s applied
## only ~30 min of healing per "day", decoupling healing from the day counter by 48x — a 6-week bone break
## needed ~2000 in-game days.)
const CAMP_HEAL_SECONDS: float = HealingConstants.SECONDS_PER_DAY
## CAMP_HEAL_MULTIPLIER.
const CAMP_HEAL_MULTIPLIER: float = 1.0
## FIELD_CARE_MARCH_CHAIN.
const FIELD_CARE_MARCH_CHAIN: String = "pressure (free) -- bandage/pack/TQ"

# Runtime preload -- circular dependency (CompanyState preloads CompanyCamp).
static var _company_state_cache: Variant = null
static var _company_economy_cache: Variant = null
static var _company_mood_cache: Variant = null
static var _combat_flow_cache: Variant = null


static func _get_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


static func _get_economy() -> GDScript:
    if _company_economy_cache == null:
        _company_economy_cache = load("res://world/CompanyEconomy.gd")
    return _company_economy_cache


static func _get_mood() -> GDScript:
    if _company_mood_cache == null:
        _company_mood_cache = load("res://world/CompanyMood.gd")
    return _company_mood_cache


static func _get_combat_flow() -> Variant:
    if _combat_flow_cache == null:
        _combat_flow_cache = load("res://world/CombatFlow.gd")
    return _combat_flow_cache


static func format_field_bandage_dress_note(world: Node2D) -> String:
    if _get_economy().get_medical_supplies(world) >= 1:
        return "Field bandage (-1 med/part)"
    return "Field bandage (0 med / reduced efficacy)"


static func format_field_care_march_chain() -> String:
    return FIELD_CARE_MARCH_CHAIN


static func _try_apply_decay(world: Node2D) -> void:
    var day_index: int = _get_state().get_day_index(world)
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("_get_training_pending"):
            EntityProficiency.apply_decay(entity, day_index)


static func _try_merge_training_pending(world: Node2D) -> void:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if (
            entity != null
            and entity.has_method("_get_training_pending")
            and entity.has_method("_set_training_pending_value")
        ):
            EntityProficiency.merge_training_pending(entity)


const TRAIN_STATS: Array = ["strength", "agility", "intelligence", "endurance", "perception"]


static func can_train_stat(world: Node2D, node_ref: Node, stat: String) -> bool:
    if not _get_state().read_stub_proficiency_enabled():
        return false
    if stat not in TRAIN_STATS:
        return false
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    return _get_economy().get_gold(world) >= _get_economy().TRAIN_GOLD_COST


## Drills a stat for a party member: charges gold, queues +1 into training_pending.
## The queued gain is applied to _proficiency_bonus at next camp rest.
static func train_stat(world: Node2D, node_ref: Node, stat: String) -> bool:
    if not can_train_stat(world, node_ref, stat):
        return false
    if not _get_economy().consume_gold(world, _get_economy().TRAIN_GOLD_COST):
        return false
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null or not entity.has_method("_set_training_pending_value"):
        _get_economy().add_gold(world, _get_economy().TRAIN_GOLD_COST)
        return false
    var pending: Dictionary = entity._get_training_pending()
    var current: float = float(pending.get(stat, 0.0))
    entity._set_training_pending_value(stat, current + 1.0)
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "train_stat %s %s pending=%.1f gold_left=%d"
            % [str(node_ref.name), stat, current + 1.0, _get_economy().get_gold(world)]
        )
    return true


static func camp_heal_ready(world: Node2D, from_party_menu: bool = false) -> bool:
    return can_offer_camp_heal(world, from_party_menu) and _party_bleeding_controlled(world)


static func format_camp_heal_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
    if not _party_bleeding_controlled(world):
        var parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
        if parts > 0:
            return "Camp rest (%d part(s) need dressing -- Treat next wound or field care above, then retry)" % parts
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
    if world == null or not CampaignEncounterBridge.party_has_untreated_wounds(world):
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
    var parts_need: int = CampaignEncounterBridge.party_untreated_part_count(world)
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
    return " Short %d med -- bandage at reduced efficacy or win contracts for resupply (+4 med)." % shortfall


static func compute_field_treatment_effectiveness(entity: Node, world: Node2D, stabilize_floor: bool) -> float:
    var supply: float = _get_economy().compute_medical_supply_factor(world)
    var skill: float = 1.0
    if entity != null and entity.has_method("_get_medical_effectiveness"):
        skill = float(entity._get_medical_effectiveness())
        if entity.has_method("_get_campaign_supply_factor"):
            var stamped: float = float(entity._get_campaign_supply_factor())
            if stamped > 0.001:
                skill /= stamped
    var eff: float = skill * supply
    if stabilize_floor:
        return clampf(maxf(eff, CombatConstants.FIELD_CARE_STABILIZE_FLOOR), 0.25, 2.0)
    return clampf(eff, CombatConstants.FIELD_CARE_EFF_MIN, CombatConstants.FIELD_CARE_EFF_MAX)


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
    if CampaignEncounterBridge.party_has_untreated_wounds(world):
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
    if CampaignEncounterBridge.party_has_untreated_wounds(world):
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
        if OperationalLog.is_play_session_active():
            var parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
            var block: String = format_camp_heal_block_reason(world, from_party_menu)
            OperationalLog.play_world("camp_heal blocked: %s parts_need=%d" % [block, parts])
        return false
    if not _get_economy().consume_medical(world, 1):
        return false
    var day_before: int = _get_state().get_day_index(world)
    # Snapshot rest quality from current provisions BEFORE the day advance consumes food: a well-fed
    # company rests well (full recovery); a starving company rests poorly (partial recovery).
    var rest_quality: float = compute_rest_quality(world)
    _advance_party_healing(world, CAMP_HEAL_SECONDS, CAMP_HEAL_MULTIPLIER)
    _get_state().try_advance_day(world)
    _apply_roster_rest_quality(world, rest_quality)
    _sharpen_roster_weapons(world)
    _restore_roster_muscle_fatigue(world)
    _try_apply_decay(world)
    _try_merge_training_pending(world)
    _get_mood().apply_camp_rest_mood(world)
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        (
            OperationalLog
            . play_world(
                (
                    "camp_heal seconds=%.0f mult=%.1f med_left=%d day=%d->%d rest_quality=%.2f all_dressed=true mood=+%.0f"
                    % [
                        CAMP_HEAL_SECONDS,
                        CAMP_HEAL_MULTIPLIER,
                        _get_economy().get_medical_supplies(world),
                        day_before,
                        _get_state().get_day_index(world),
                        rest_quality,
                        _get_mood().MOOD_CAMP_REST_DELTA,
                    ]
                )
            )
        )
    return true


static func roster_has_repairable_wounds(world: Node2D) -> bool:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
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
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world("settlement_repair tools_left=%d" % _get_economy().get_tool_supplies(world))
    return true


static func _party_bleeding_controlled(world: Node2D) -> bool:
    return not CampaignEncounterBridge.party_has_untreated_wounds(world)


static func _advance_party_healing(world: Node2D, seconds: float, multiplier: float) -> void:
    var effective: float = seconds * multiplier
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null:
            if entity.has_method("process_bleeding"):
                entity.process_bleeding(effective)
            if entity.has_method("process_blood_loss"):
                entity.process_blood_loss(effective)
            if entity.has_method("_process_healing"):
                entity._process_healing(effective)
        if n.has_method("ensure_consciousness_current"):
            n.ensure_consciousness_current()


## Rest quality (0..1) from current provisions: a well-fed company (enough food for the roster) rests
## well (1.0); a starving company rests poorly (REST_QUALITY_FLOOR). This is a snapshot of "are we
## well-provisioned right now?" and is taken before the day advance consumes the day's rations.
static func compute_rest_quality(world: Node2D) -> float:
    var roster: int = _get_state().count_living_roster(world)
    if roster <= 0:
        return 1.0
    var need: int = roster * _get_economy().FOOD_PER_MEMBER_PER_DAY
    if need <= 0:
        return 1.0
    var have: int = _get_economy().get_food_supplies(world)
    var adequacy: float = clampf(float(have) / float(need), 0.0, 1.0)
    return lerpf(CoreEntity.REST_QUALITY_FLOOR, 1.0, adequacy)


## Campaign weariness: a night's rest at camp recovers accumulated fatigue by the rest quality. A
## well-provisioned camp (quality 1.0) fully clears it; a poor camp recovers only a fraction, leaving
## residual weariness that lowers the next battle's stamina cap.
static func _apply_roster_rest_quality(world: Node2D, quality: float) -> void:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("apply_rest_quality"):
            entity.apply_rest_quality(quality)


## Weapon edge wear: a rest at camp lets the company sharpen its weapons (edge restored to full).
static func _sharpen_roster_weapons(world: Node2D) -> void:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("sharpen_weapon"):
            entity.sharpen_weapon()


## Camp rest clears per-limb muscle exertion pools (FEATURE_MUSCLE_GROUP_FATIGUE campaign bridge):
## a rested fighter enters the next fight with fresh limbs.
static func _restore_roster_muscle_fatigue(world: Node2D) -> void:
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("_restore_muscle_fatigue_at_camp"):
            entity._restore_muscle_fatigue_at_camp()


static func format_post_fight_field_care_short_log(parts_left: int) -> String:
    return "field_care: untreated wounds remain after battle triage parts_left=%d -- open Party on the map" % parts_left


static func format_post_fight_field_care_world_log(world: Node2D) -> String:
    var budget: Dictionary = triage_med_budget(world)
    var parts: int = budget.get("parts_need", 0)
    var med_left: int = _get_economy().get_medical_supplies(world)
    var zero_med_note: String = ""
    if med_left <= 0:
        zero_med_note = "; 0-med bandages OK for map dressings"
    return (
        (
            "field_care: open Party -- %s; %d part(s) need dressing; "
            + "med_left=%d; bandage_med_est=%d; total_med_est=%d; med_shortfall=%d%s; "
            + "battle bandages free; then Camp rest (-1 med / +1 day / +1 mood)"
        )
        % [
            format_field_care_march_chain(),
            parts,
            med_left,
            budget.get("field_bandage_med_est", 0),
            budget.get("total_worst_case", 0),
            budget.get("med_shortfall", 0),
            zero_med_note,
        ]
    )


static func format_party_button_label(world: Node2D) -> String:
    if world == null or not CampaignEncounterBridge.party_has_untreated_wounds(world):
        return "Party"
    var parts: int = CampaignEncounterBridge.party_untreated_part_count(world)
    if parts <= 0:
        return "Party"
    return "Party /  %d to dress" % parts


static func format_hud_triage_suffix(world: Node2D) -> String:
    if world == null or not CampaignEncounterBridge.party_has_untreated_wounds(world):
        return ""
    var budget: Dictionary = triage_med_budget(world)
    var parts: int = budget.get("parts_need", 0)
    if parts <= 0:
        return ""
    var total: int = budget.get("total_worst_case", 0)
    var med_left: int = _get_economy().get_medical_supplies(world)
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
    if CampaignEncounterBridge.party_has_untreated_wounds(world):
        btn.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
    else:
        btn.remove_theme_color_override("font_color")
    var tips: PackedStringArray = PackedStringArray()
    if CampaignEncounterBridge.party_has_untreated_wounds(world):
        var budget: Dictionary = triage_med_budget(world)
        var shortfall: int = budget.get("med_shortfall", 0)
        var med_left: int = _get_economy().get_medical_supplies(world)
        var march: String = format_field_care_march_chain()
        if med_left == 0:
            tips.append("Field care -- %s; 0-med bandages; win contracts for camp med (+4)." % march)
        elif shortfall > 0:
            tips.append("Field care -- %s; short %d med." % [march, shortfall])
        else:
            tips.append("Field care -- %s." % march)
    var st: GDScript = _get_state()
    if _get_economy().should_show_next_wage_hint(st.get_state(world), st.count_living_roster(world)):
        tips.append(_get_economy().format_next_wage_hint(st.get_state(world), st.count_living_roster(world)))
    if _get_economy().should_show_next_provisions_hint(world):
        tips.append(_get_economy().format_next_provisions_hint(world))
    if st.roster_has_hire_room(world):
        var hire_tip: String = st.format_hire_tooltip(world, false)
        if not hire_tip.is_empty():
            tips.append(hire_tip)
    if st.persistence_uses_disk_autosave():
        tips.append(st.format_party_autosave_footer())
    btn.tooltip_text = " ".join(tips)
