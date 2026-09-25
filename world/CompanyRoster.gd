class_name CompanyRoster
extends RefCounted

## CompanyRoster -- hire, burial, casualty cleanup, contract lifecycle.

# Runtime preload -- circular dependency (CompanyState preloads CompanyRoster).
static var _company_state_cache: Variant = null
static var _company_economy_cache: Variant = null
static var _party_setup_cache: Variant = null


static func _get_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


static func _get_economy() -> GDScript:
    if _company_economy_cache == null:
        _company_economy_cache = load("res://world/CompanyEconomy.gd")
    return _company_economy_cache


static func _get_party_setup() -> GDScript:
    if _party_setup_cache == null:
        _party_setup_cache = load("res://world/PartySetup.gd")
    return _party_setup_cache


static func roster_has_hire_room(world: Node) -> bool:
    return _get_state().count_living_roster(world) < _get_state().ROSTER_MAX_LIVING


static func can_offer_hire(world: Node2D, from_party_menu: bool = false) -> bool:
    if world == null or not roster_has_hire_room(world):
        return false
    if _get_party_setup().find_vacant_companion_node(world) == null:
        return false
    if _get_state().get_gold(world) < recruit_cost(world):
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


## XCamp-4c: reputation payoff -- the gold cost of a fresh hire at the company's current renown.
## Better recruits cost more; a nameless company (renown 0) is exactly HIRE_GOLD_COST (unchanged).
static func recruit_cost(world: Node) -> int:
    var renown: int = _get_state().get_renown(world) if world != null else 0
    return PlayerCompanionSetup.recruit_cost_for_renown(renown)


static func format_hire_button_label(world: Node = null) -> String:
    return "Hire (-%dg)" % recruit_cost(world)


static func format_hire_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
    if not roster_has_hire_room(world):
        return "Hire (roster full -- %d/%d)" % [_get_state().count_living_roster(world), _get_state().ROSTER_MAX_LIVING]
    if _get_party_setup().find_vacant_companion_node(world) == null:
        return "Hire (no vacant slot)"
    if _get_state().get_gold(world) < recruit_cost(world):
        return "Hire (need %dg /  have %dg)" % [recruit_cost(world), _get_state().get_gold(world)]
    if can_offer_hire(world, from_party_menu):
        return format_hire_button_label(world)
    if _get_state().read_stub_hire_entry() == "tile" and not _get_state()._player_on_camp_tile(world):
        return "Hire (stand on camp tile)"
    return "Hire (unavailable)"


static func format_hire_tooltip(world: Node2D, from_party_menu: bool = false) -> String:
    if world == null or not roster_has_hire_room(world):
        return ""
    if can_offer_hire(world, from_party_menu):
        # XCamp-4c: reputation payoff -- show the recruit quality the company's renown attracts.
        var quality: String = PlayerCompanionSetup.recruit_quality_label(_get_state().get_renown(world))
        return "Recruit a %s for -%dg (fills vacant companion slot)." % [quality, recruit_cost(world)]
    return format_hire_block_reason(world, from_party_menu)


static func try_hire_rookie(world: Node2D, rng: RandomNumberGenerator = null, from_party_menu: bool = false) -> bool:
    if not can_offer_hire(world, from_party_menu):
        return false
    var gold_before: int = _get_state().get_gold(world)
    if not _get_state().consume_gold(world, recruit_cost(world)):
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
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            (
                "hire_rookie name=%s quality=%s gold=%d living=%d"
                % [
                    PlayerCompanionSetup.resolve_fighter_display_name(hired),
                    PlayerCompanionSetup.recruit_quality_label(_get_state().get_renown(world)),
                    _get_state().get_gold(world),
                    _get_state().count_living_roster(world),
                ]
            )
        )
    return true


static func find_living_surgeon(world: Node) -> Node:
    if world == null:
        return null
    var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null:
        return null
    var roster: Array = pm.members if "members" in pm else (pm.get_members() if pm.has_method("get_members") else [])
    for member in roster:
        if member is not Dictionary:
            continue
        var node_ref: Variant = (member as Dictionary).get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        if PlayerCompanionSetup.member_is_surgeon(node_ref as Node):
            return node_ref as Node
    return null


static func has_surgeon(world: Node) -> bool:
    return find_living_surgeon(world) != null


## XSurgeon: a company may hold one surgeon at a time (a second hire would be a redundant medical
## slot). The surgeon is a separate, non-roster slot (dedicated Character/Surgeon node), so the hire
## needs no fighter roster room and no vacant companion slot -- a full ROSTER_MAX_LIVING roster can
## still hire a surgeon. Cost is flat (no renown payoff), unlike a fighter hire.
static func can_offer_surgeon_hire(world: Node2D, from_party_menu: bool = false) -> bool:
    if world == null:
        return false
    if has_surgeon(world):
        return false
    if _get_state().get_gold(world) < surgeon_hire_cost():
        return false
    var entry: String = _get_state().read_stub_hire_entry()
    if entry == "party_menu":
        return true
    if from_party_menu and entry == "both":
        return true
    if entry == "tile" or entry == "both":
        return _get_state()._player_on_camp_tile(world)
    return false


static func surgeon_hire_cost() -> int:
    return _get_economy().SURGEON_HIRE_GOLD_COST


static func format_surgeon_hire_block_reason(world: Node2D, from_party_menu: bool = false) -> String:
    if world == null:
        return "Hire surgeon (unavailable)"
    if has_surgeon(world):
        return "Hire surgeon (a surgeon already serves the company)"
    if _get_state().get_gold(world) < surgeon_hire_cost():
        return "Hire surgeon (need %dg / have %dg)" % [surgeon_hire_cost(), _get_state().get_gold(world)]
    if can_offer_surgeon_hire(world, from_party_menu):
        return "Hire surgeon (-%dg)" % surgeon_hire_cost()
    if _get_state().read_stub_hire_entry() == "tile" and not _get_state()._player_on_camp_tile(world):
        return "Hire surgeon (stand on camp tile)"
    return "Hire surgeon (unavailable)"


static func format_surgeon_hire_tooltip(world: Node2D, from_party_menu: bool = false) -> String:
    if world == null:
        return ""
    if can_offer_surgeon_hire(world, from_party_menu):
        return (
            "Hire medical staff (-%dg). The surgeon never fights; they ride into campaign battles "
            + "and unlock full field TCCC in the post-victory medical phase (separate slot, no roster cost)."
        ) % surgeon_hire_cost()
    return format_surgeon_hire_block_reason(world, from_party_menu)


## XSurgeon: hire medical staff. Mirrors `try_hire_rookie` (gold-before rollback if spawn fails).
static func try_hire_surgeon(world: Node2D, rng: RandomNumberGenerator = null, from_party_menu: bool = false) -> bool:
    if not can_offer_surgeon_hire(world, from_party_menu):
        return false
    var gold_before: int = _get_state().get_gold(world)
    if not _get_state().consume_gold(world, surgeon_hire_cost()):
        return false
    var roll: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
    if rng == null:
        roll.randomize()
    var hired: Node = _get_party_setup().spawn_surgeon_member(world, roll)
    if hired == null:
        _get_state().set_gold(world, gold_before)
        return false
    _get_state().refresh_hud(world)
    _get_state().try_autosave(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            (
                "hire_surgeon name=%s gold=%d living=%d"
                % [
                    PlayerCompanionSetup.resolve_fighter_display_name(hired),
                    _get_state().get_gold(world),
                    _get_state().count_living_roster(world),
                ]
            )
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
    return contract_loss_ends_run() and not contract.is_empty() and not is_tutorial_contract(contract)


static func apply_contract_victory_pay(world: Node) -> int:
    var contract: Dictionary = get_active_contract(world)
    if contract.is_empty():
        return 0
    mark_tutorial_completed(world)
    if is_tutorial_contract(contract):
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world(
                "contract_victory tutorial -- no pay (type=%s)" % contract.get("contract_type", "")
            )
        return 0
    var base_pay: int = contract.get("pay_gold", 0)
    var renown_mult: float = 1.0 + float(_get_state().get_renown(world)) * _get_state().RENOWN_PAY_SCALE
    var int_mult: float = 1.0
    if _get_state().read_stub_proficiency_enabled():
        int_mult = _apply_int_contract_bonus(world)
    var scaled: int = int(round(float(base_pay) * renown_mult * int_mult))
    # XCamp-5f: per-fighter fame accrues on a win and pays a sponsor bonus for each survivor at/above
    # the qualifying tier; add it to this contract's payout.
    var sponsor_gold: int = award_fame_for_victory(world)
    scaled += sponsor_gold
    _get_state().add_gold(world, scaled)
    _get_state().set_renown(world, _get_state().get_renown(world) + 1)
    _get_state().set_medical_supplies(
        world, _get_state().get_medical_supplies(world) + _get_state().CONTRACT_VICTORY_MED_RESUPPLY
    )
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            (
                "contract_victory pay=%d gold=%d renown=%d med_resupply=%d med=%d"
                % [
                    scaled,
                    _get_state().get_gold(world),
                    _get_state().get_renown(world),
                    _get_state().CONTRACT_VICTORY_MED_RESUPPLY,
                    _get_state().get_medical_supplies(world)
                ]
            )
        )
        if world is Node2D:
            if CampaignEncounterBridge.party_has_untreated_wounds(world as Node2D):
                var budget: Dictionary = CompanyState.triage_med_budget(world as Node2D)
                OperationalLog.play_world(
                    (
                        "contract_victory triage parts_need=%d med_shortfall=%d"
                        % [budget.get("parts_need", 0), budget.get("med_shortfall", 0)]
                    )
                )
    return scaled


## XCamp-5f: award per-fighter fame after a paid-contract victory. Each surviving fighter earns
## FAME_WIN_BASE scaled by how hard the opponents were (desirable difficulty: the strongest foe's
## effective strength vs the fighter's own strength). Also returns the sponsor gold to add to the
## contract payout: FAME_SPONSOR_PER_QUALIFYING_FIGHTER per survivor now at/above the qualifying
## career tier. 0 when the gate is off or there is no battle summary.
static func award_fame_for_victory(world: Node) -> int:
    var state: GDScript = _get_state()
    if world == null or not state.read_stub_fighter_fame_enabled():
        return 0
    var summary: Dictionary = get_last_battle_summary(world)
    var members: Variant = summary.get("members", [])
    if not (members is Array) or (members as Array).is_empty():
        return 0
    # XCamp-6 fix: only party members who actually entered this battle earn fight fame. A match
    # duel (single-fighter lock) or leader-only fight enters only a subset; the bench must not
    # level up by spectating. Falls back to "all members" when no participant list was captured
    # (test fixtures / summary hand-built without going through CombatFlow.start_combat).
    var participant_set: Dictionary = {}
    var participants: Variant = summary.get("participants", [])
    if participants is PackedStringArray or participants is Array:
        for p in participants:
            participant_set[str(p)] = true
    # Strongest opponent's effective strength, captured at combat start (enemies are freed by
    # settlement, so the meta is the only reliable source). Falls back to the neutral reference.
    var foe_str: float = _get_foe_strength(world)
    # name -> live entity for surviving members (to write fame onto the entity).
    var by_name: Dictionary = {}
    var pm: Node = state._resolve_party_manager(world)
    if pm != null and "members" in pm:
        for m in pm.members:
            if not (m is Dictionary):
                continue
            var node_ref: Variant = (m as Dictionary).get("node_ref")
            if not is_instance_valid(node_ref) or not (node_ref is Node):
                continue
            var ent: Node = CampaignEncounterBridge.health_entity_from_character(node_ref as Node)
            if ent == null or not ("fame" in ent):
                continue
            by_name[str((m as Dictionary).get("name", ""))] = ent
    var qualifying_min: float = 0.0
    var tiers: Array = state.FAME_TIERS
    if state.FAME_SPONSOR_MIN_TIER_INDEX < tiers.size():
        var tier: Dictionary = tiers[state.FAME_SPONSOR_MIN_TIER_INDEX]
        if tier is Dictionary:
            qualifying_min = float(tier.get("min", 0.0))
    var sponsor_gold: int = 0
    var log_parts: PackedStringArray = PackedStringArray()
    var promotions: PackedStringArray = PackedStringArray()
    for mem in members:
        if not (mem is Dictionary):
            continue
        var mem_name: String = str((mem as Dictionary).get("name", ""))
        if not participant_set.is_empty() and not participant_set.has(mem_name):
            continue
        var ent: Node = by_name.get(mem_name, null)
        if ent == null:
            continue
        var snap_raw: Variant = (mem as Dictionary).get("snapshot", {})
        var snap: Dictionary = snap_raw if snap_raw is Dictionary else {}
        var own_str: float = float(snap.get("strength", 0.0))
        var diff: float = EntityProficiency.opponent_difficulty_mult(foe_str, own_str)
        var gain: int = roundi(float(state.FAME_WIN_BASE) * diff)
        var old_fame: int = int(ent.fame)
        ent.fame = old_fame + gain
        if float(ent.fame) >= qualifying_min:
            sponsor_gold += state.FAME_SPONSOR_PER_QUALIFYING_FIGHTER
        var name_s: String = str((mem as Dictionary).get("name", ""))
        var new_tier: String = state.fame_tier_label(int(ent.fame))
        var old_tier: String = state.fame_tier_label(old_fame)
        if new_tier != old_tier:
            promotions.append("%s: %s → %s" % [name_s, old_tier, new_tier])
        log_parts.append("%s +%d->%d %s" % [name_s, gain, int(ent.fame), new_tier])
    # Re-set on every award (even empty) so a stale note from a prior battle is cleared.
    world.set_meta(CampaignTypes.WORLD_META_LAST_FAME_PROMOTIONS, promotions)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "fame_award survivors=%d sponsor_gold=%d [%s]" % [
                log_parts.size(), sponsor_gold, " ".join(log_parts)
            ]
        )
    return sponsor_gold


## XCamp-5f: strongest opponent's effective strength for the last battle, captured at combat start.
## Falls back to the neutral difficulty reference when no value was captured (e.g. a fight that never
## registered a foe), so the difficulty multiplier stays in its clamped band.
static func _get_foe_strength(world: Node) -> float:
    if world != null and world.has_meta(CampaignTypes.WORLD_META_FOE_STRENGTH):
        var v: Variant = world.get_meta(CampaignTypes.WORLD_META_FOE_STRENGTH)
        if (v is float or v is int) and float(v) > 0.0:
            return float(v)
    return float(EntityProficiency.GAIN_DIFFICULTY_STR_BASE)


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
    return "Burial will cost %dg but you only have %dg -- debt is allowed (same as unpaid wages)." % [cost, gold]


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
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
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
    for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
        if entity != null and entity.has_method("_get_intelligence_contract_bonus_mult"):
            var m: float = entity._get_intelligence_contract_bonus_mult()
            if m > best_mult:
                best_mult = m
    return best_mult
