class_name CompanyEconomy
extends RefCounted

## CompanyEconomy -- state accessors, gold, supplies, wages, renown, provisions, med supply wiring.

## Starting economy: 500g = ~23 days of wages for default 7-member company (15g/day) + buffer for 1 battle at default
## size.
const DEFAULT_GOLD: int = 500
## Daily wage per mercenary — calibrated so a 7-merc company burns ~105g/day in wages alone.
## At 500g starting gold + average contract payout of ~150-300g, this yields ~2-3 week campaign pacing before player
## must actively earn income.
const DEFAULT_WAGE_PER_MEMBER: int = 15
const DEFAULT_MEDICAL_SUPPLIES: int = 15
## Victory med resupply per successful contract — offsets medical supply consumption from post-battle healing.
const CONTRACT_VICTORY_MED_RESUPPLY: int = 4
const DEFAULT_TOOL_SUPPLIES: int = 2
## Starting food for 7-member company at 1g/day consumption = 14 days of self-sufficiency without resupply.
const DEFAULT_FOOD_SUPPLIES: int = 14
const FOOD_PER_MEMBER_PER_DAY: int = 1
const DEFAULT_RENOWN: int = 0
const DEFAULT_DAY_INDEX: int = 0
## Hire cost per mercenary — ~13 days of a single merc's wages; acts as soft gate on rapid roster expansion.
const HIRE_GOLD_COST: int = 200
## Hire cost for medical staff (the company surgeon). Flat so the door is a deliberate, stable spend;
## a surgeon never fights, so recruit quality / renown payoff does not apply.
const SURGEON_HIRE_GOLD_COST: int = 175
## Gold cost to bury fallen mercenaries (respect mechanic; prevents morale/renown penalties from unburied dead).
const BURIAL_GOLD_COST: int = 25
## Gold cost to drill one stat for one party member (queues +1 proficiency, applied at next camp rest).
## ~1.7 days of a single merc's wages; a soft gate so training is a deliberate spend, not free.
const TRAIN_GOLD_COST: int = 25
## Maximum living combatants per side in engagement formation — balanced around squad-level medieval skirmish size.
const ROSTER_MAX_LIVING: int = 7
const HIRE_ENTRY: String = "both"
## P2 persistence.
const PERSISTENCE_MODE: String = "P2"
const P2_RESTORE_ON_MAIN_RESTART: bool = true
## Re-exported from CompanyState for backward compat -- preload CampaignTypes directly in new code.
const RENOWN_PAY_SCALE: float = 0.05

const WORLD_META_CAMPAIGN_MED_BATTLE: String = "campaign_med_battle"

const PERSISTENCE_MODE_STR: String = "P2"

# Runtime preload for sibling module ' avoids circular parse-time dependencies
# (CompanyState preloads CompanyEconomy, so CompanyEconomy must lazy-load CompanyState).
static var _company_state: Variant = null


static func _get_state() -> GDScript:
    if CompanyEconomy._company_state == null:
        CompanyEconomy._company_state = load("res://world/CompanyState.gd")
    return CompanyEconomy._company_state


## 'Sec12 EA tuning defaults (not decision stubs).


static func persistence_uses_disk_autosave() -> bool:
    return PERSISTENCE_MODE_STR == "P2"


static func persistence_restore_on_main_restart() -> bool:
    return persistence_uses_disk_autosave() and P2_RESTORE_ON_MAIN_RESTART


static func persistence_clear_slot_on_run_end_reload() -> bool:
    return persistence_uses_disk_autosave() and not persistence_restore_on_main_restart()


## Attach company state to world.
static func attach_to_world(world: Node2D) -> void:
    if world == null:
        return
    if not world.has_meta(_get_state().WORLD_META_COMPANY_STATE):
        init_from_defaults(world)
    _ensure_hud_on_world(world)
    refresh_hud(world)


## Initialize world with default state dict.
static func init_from_defaults(world: Node2D) -> void:
    if world == null:
        return
    world.set_meta(_get_state().WORLD_META_COMPANY_STATE, _default_state_dict())


static func _default_state_dict() -> Dictionary:
    return {
        "gold": DEFAULT_GOLD,
        "wage_per_member": DEFAULT_WAGE_PER_MEMBER,
        "medical_supplies": DEFAULT_MEDICAL_SUPPLIES,
        "tool_supplies": DEFAULT_TOOL_SUPPLIES,
        "food_supplies": DEFAULT_FOOD_SUPPLIES,
        "renown": DEFAULT_RENOWN,
        "day_index": DEFAULT_DAY_INDEX,
        "bankrupt": false,
        "overworld_step_count": 0,
        "contract_deck_index": 0,
        "tutorial_completed": false,
    }


static func get_state(world: Node) -> Dictionary:
    var meta_key: String = _get_state().WORLD_META_COMPANY_STATE
    if world == null or not world.has_meta(meta_key):
        return {}
    var raw: Variant = world.get_meta(meta_key)
    return raw if raw is Dictionary else {}


static func _write_state(world: Node, state: Dictionary) -> void:
    if world == null:
        return
    world.set_meta(_get_state().WORLD_META_COMPANY_STATE, state)
    refresh_hud(world)


static func get_gold(world: Node) -> int:
    return get_state(world).get("gold", 0)


static func set_gold(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["gold"] = maxi(0, value)
    _write_state(world, state)


static func add_gold(world: Node, delta: int) -> void:
    set_gold(world, get_gold(world) + delta)


static func consume_gold(world: Node, amount: int) -> bool:
    if amount <= 0:
        return true
    if get_gold(world) < amount:
        return false
    set_gold(world, get_gold(world) - amount)
    return true


static func get_medical_supplies(world: Node) -> int:
    return get_state(world).get("medical_supplies", 0)


static func set_medical_supplies(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["medical_supplies"] = maxi(0, value)
    _write_state(world, state)
    _sync_party_medical_supply_after_med_change(world)


static func get_tool_supplies(world: Node) -> int:
    return get_state(world).get("tool_supplies", 0)


static func set_tool_supplies(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["tool_supplies"] = maxi(0, value)
    _write_state(world, state)


static func get_food_supplies(world: Node) -> int:
    return get_state(world).get("food_supplies", 0)


static func set_food_supplies(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["food_supplies"] = maxi(0, value)
    _write_state(world, state)


static func consume_food(world: Node, amount: int) -> bool:
    if amount <= 0:
        return true
    if get_food_supplies(world) < amount:
        return false
    set_food_supplies(world, get_food_supplies(world) - amount)
    return true


static func consume_medical(world: Node, amount: int = 1) -> bool:
    if amount <= 0:
        return true
    if get_medical_supplies(world) < amount:
        return false
    set_medical_supplies(world, get_medical_supplies(world) - amount)
    return true


static func consume_tool(world: Node, amount: int = 1) -> bool:
    if amount <= 0:
        return true
    if get_tool_supplies(world) < amount:
        return false
    set_tool_supplies(world, get_tool_supplies(world) - amount)
    return true


static func _sync_party_medical_supply_after_med_change(world: Node) -> void:
    if world is Node2D:
        wire_party_medical_supply(world as Node2D)


static func get_renown(world: Node) -> int:
    return get_state(world).get("renown", 0)


static func set_renown(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["renown"] = maxi(0, value)
    _write_state(world, state)


static func get_contract_deck_index(world: Node) -> int:
    return get_state(world).get("contract_deck_index", 0)


static func set_contract_deck_index(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["contract_deck_index"] = maxi(0, value)
    _write_state(world, state)


static func get_day_index(world: Node) -> int:
    return get_state(world).get("day_index", 0)


static func set_day_index(world: Node, value: int) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["day_index"] = maxi(0, value)
    _write_state(world, state)


static func is_bankrupt(world: Node) -> bool:
    return get_state(world).get("bankrupt") == true


static func set_bankrupt(world: Node, value: bool) -> void:
    var state: Dictionary = get_state(world).duplicate()
    state["bankrupt"] = value
    _write_state(world, state)


static func get_overworld_step_count(world: Node) -> int:
    return get_state(world).get("overworld_step_count", 0)


static func get_wage_per_member(world: Node) -> int:
    return int(get_state(world).get("wage_per_member", DEFAULT_WAGE_PER_MEMBER))


static func count_living_roster(world: Node) -> int:
    var pm: Variant = _resolve_party_manager(world)
    if pm == null:
        return 0
    var living := 0
    for member in pm.members:
        if not member is Dictionary:
            continue
        var node_ref: Variant = member.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        # XSurgeon: the surgeon is a separate, non-roster slot (dedicated node) -- it does not
        # consume a fighter slot, draw wages, or eat provisions, so it is excluded from the count.
        if PlayerCompanionSetup.member_is_surgeon(node_ref as Node):
            continue
        living += 1
    return living


static func compute_next_wage_bill(world: Node) -> int:
    return get_wage_per_member(world) * count_living_roster(world)


static func format_hud_economy_hint_lines(
    state: Dictionary, living_count: int, world: Node2D = null
) -> PackedStringArray:
    var hints: PackedStringArray = PackedStringArray()
    if should_show_next_wage_hint(state, living_count):
        hints.append(format_next_wage_hint(state, living_count))
    if world != null and should_show_next_provisions_hint(world):
        hints.append(format_next_provisions_hint(world))
    return hints


static func should_show_next_wage_hint(state: Dictionary, living_count: int) -> bool:
    var gold: int = state.get("gold", 0)
    var bill: int = state.get("wage_per_member", DEFAULT_WAGE_PER_MEMBER) * maxi(1, living_count)
    return gold < bill


static func format_next_wage_hint(state: Dictionary, living_count: int) -> String:
    var bill: int = state.get("wage_per_member", DEFAULT_WAGE_PER_MEMBER) * maxi(1, living_count)
    var gold: int = state.get("gold", 0)
    if gold < 0:
        return "Wages: %dg due -- %dg debt (desertion risk)" % [bill, -gold]
    if gold < bill:
        return "Next wage: %dg (short %d -- mood hit if unpaid)" % [bill, bill - gold]
    return "Next wage: %dg" % bill


static func should_show_next_provisions_hint(world: Node2D) -> bool:
    if world == null or not _get_state().read_stub_provisions_enabled():
        return false
    var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
    return need > 0 and get_food_supplies(world) < need


static func format_next_provisions_hint(world: Node2D) -> String:
    var need: int = count_living_roster(world) * FOOD_PER_MEMBER_PER_DAY
    var have: int = get_food_supplies(world)
    if have <= 0:
        return "Next rations: %d food (none left -- mood -1 at day end)" % need
    return "Next rations: %d food (short %d -- mood -1)" % [need, need - have]


static func format_wages_short_log(gold_before: int, bill: int) -> String:
    return "Wages short  -  paid what you could; mood fell (gold %d, bill %d)." % [gold_before, bill]


static func format_autosave_action_suffix() -> String:
    if persistence_uses_disk_autosave():
        return " -- saves progress"
    return ""


static func try_autosave(world: Node2D) -> bool:
    if not persistence_uses_disk_autosave() or world == null:
        return false
    var ok: bool = CampaignPersistence.save_slot(world)
    if ok:
        if world.has_meta(_get_state().WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE):
            world.remove_meta(_get_state().WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE)
        refresh_hud(world)
    elif OperationalLog.is_play_session_active():
        OperationalLog.warn("campaign_autosave failed -- slot not written")
    return ok


static func compute_medical_supply_factor(world: Node) -> float:
    if get_medical_supplies(world) >= 1:
        return 1.0
    return _get_state().read_stub_supply_factor_at_zero_med()


static func wire_party_medical_supply(world: Node2D) -> void:
    if world == null:
        return
    var factor: float = compute_medical_supply_factor(world)
    (
        world
        . set_meta(
            WORLD_META_CAMPAIGN_MED_BATTLE,
            {
                "mode": _get_state().read_stub_med_battle_mode(),
                "supply_factor": factor,
                "med_count": get_medical_supplies(world),
            }
        )
    )
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("_set_campaign_supply_factor"):
            entity._set_campaign_supply_factor(factor)


static func on_battle_medical_complete(world: Node, target_method: String, success: bool) -> void:
    if world == null or not success or _get_state().read_stub_med_battle_mode() != "hybrid":
        return
    for key in CombatConstantsMedical.MEDICAL_WIND_UP_CONFIG:
        var cfg: Dictionary = (CombatConstantsMedical.MEDICAL_WIND_UP_CONFIG as Dictionary).get(key, {}) as Dictionary
        if cfg.get("target_method", "") == target_method:
            consume_medical(world, 1)
            break


static func _resolve_party_manager(world: Node) -> Node:
    if world == null or not world.has_meta("party_manager"):
        return null
    var pm: Variant = world.get_meta("party_manager")
    return pm if pm is Node else null


## HUD helpers (used by CompanyState facade).
static func _ensure_hud_on_world(world: Node2D) -> void:
    if _resolve_hud(world) != null:
        return
    if world != null and world.has_meta(_get_state().WORLD_META_COMPANY_HUD):
        var stale_hud: Variant = world.get_meta(_get_state().WORLD_META_COMPANY_HUD)
        if typeof(stale_hud) != TYPE_OBJECT or not is_instance_valid(stale_hud):
            world.remove_meta(_get_state().WORLD_META_COMPANY_HUD)
    if world == null or not world.is_inside_tree():
        return
    var root: Node = world.get_tree().root
    var overlay: CanvasLayer = _get_or_create_overlay(root)
    var hud: Control = CompanyHud.new()
    overlay.add_child(hud)
    world.set_meta(_get_state().WORLD_META_COMPANY_HUD, hud)


static func _get_or_create_overlay(root: Node) -> CanvasLayer:
    for child in root.get_children():
        if child.name == "UIOverlayLayer" and child is CanvasLayer:
            return child
    var overlay := CanvasLayer.new()
    overlay.name = "UIOverlayLayer"
    overlay.layer = 100
    root.add_child(overlay)
    return overlay


static func _resolve_hud(world: Node) -> Control:
    if world != null and world.has_meta(_get_state().WORLD_META_COMPANY_HUD):
        var meta_hud: Variant = world.get_meta(_get_state().WORLD_META_COMPANY_HUD)
        if is_instance_valid(meta_hud) and meta_hud is Control:
            return meta_hud
    if world == null or not world.is_inside_tree():
        return null
    var root: Node = world.get_tree().root
    for child in root.get_children():
        if child.name != "UIOverlayLayer":
            continue
        var found: Node = child.get_node_or_null("CompanyHud")
        if found is Control:
            if world != null:
                world.set_meta(_get_state().WORLD_META_COMPANY_HUD, found)
            return found
    return null


static func refresh_hud(world: Node) -> void:
    if world == null:
        return
    var hud: Control = _resolve_hud(world)
    if hud != null and hud.has_method("refresh_from_state"):
        hud.call(
            "refresh_from_state",
            get_state(world),
            count_living_roster(world),
            should_show_next_wage_hint(get_state(world), count_living_roster(world)),
            world
        )


static func format_hud_wage_suffix(world: Node2D) -> String:
    if world == null:
        return ""
    var state: Dictionary = get_state(world)
    var living: int = count_living_roster(world)
    if not should_show_next_wage_hint(state, living):
        return ""
    var gold: int = state.get("gold", 0)
    if gold < 0:
        return " /  wage debt"
    return " /  wages short"


static func format_battle_medical_supply_hint(world: Node) -> String:
    if world == null or not world.has_meta(WORLD_META_CAMPAIGN_MED_BATTLE):
        return ""
    var raw: Variant = world.get_meta(WORLD_META_CAMPAIGN_MED_BATTLE)
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
