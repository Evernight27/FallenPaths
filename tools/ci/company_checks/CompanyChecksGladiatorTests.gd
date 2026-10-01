class_name CompanyChecksGladiatorTests

extends CompanyChecksCore

## XCamp-4/4b/4c/5f gladiatorial-system checks: fighter display names and
## persistence, recruit quality/cost scaling by renown, gear commerce,
## hire integration and fame accrual/tier/survivor scaling.


## XCamp-4/4b/4c gladiatorial-system checks: fighter display names, recruit quality/cost
## scaling by renown, gear commerce (CompanyGear), and the fighter_name/base_stats
## persistence roundtrip. Labels XCamp-4.x map to the EXPANSION_PLAN queue.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks`.
## XCamp-4b: deterministic slot->name mapping, pool integrity, persisted-name precedence,
## and pool-exhaustion behavior of the name roller.
static func _run_xcamp_4b_fighter_names(failures: PackedStringArray) -> void:
    if PlayerCompanionSetup.fighter_display_name("Character") != PlayerCompanionSetup.PLAYER_FIGHTER_NAME:
        _fail(
            failures,
            (
                "XCamp-4b: player node want '%s' got '%s'"
                % [PlayerCompanionSetup.PLAYER_FIGHTER_NAME, PlayerCompanionSetup.fighter_display_name("Character")]
            )
        )
    else:
        _pass()
    if PlayerCompanionSetup.fighter_display_name("Companion") != PlayerCompanionSetup.FIGHTER_NAMES[0]:
        _fail(
            failures,
            (
                "XCamp-4b: slot 1 want '%s' got '%s'"
                % [PlayerCompanionSetup.FIGHTER_NAMES[0], PlayerCompanionSetup.fighter_display_name("Companion")]
            )
        )
    else:
        _pass()
    if PlayerCompanionSetup.fighter_display_name("Companion2") != PlayerCompanionSetup.FIGHTER_NAMES[1]:
        _fail(
            failures,
            (
                "XCamp-4b: slot 2 want '%s' got '%s'"
                % [PlayerCompanionSetup.FIGHTER_NAMES[1], PlayerCompanionSetup.fighter_display_name("Companion2")]
            )
        )
    else:
        _pass()
    var last_name: String = PlayerCompanionSetup.FIGHTER_NAMES[PlayerCompanionSetup.FIGHTER_NAMES.size() - 1]
    if PlayerCompanionSetup.fighter_display_name("Companion99") != last_name:
        _fail(
            failures,
            (
                "XCamp-4b: out-of-range slot should clamp to last pool name '%s' got '%s'"
                % [last_name, PlayerCompanionSetup.fighter_display_name("Companion99")]
            )
        )
    else:
        _pass()
    if PlayerCompanionSetup.fighter_display_name("LegacyBro") != "LegacyBro":
        _fail(failures, "XCamp-4b: unknown node name should pass through unchanged")
    else:
        _pass()
    var seen := {}
    var dup: String = ""
    for n in PlayerCompanionSetup.FIGHTER_NAMES:
        if seen.has(n):
            dup = n
            break
        seen[n] = true
    if not dup.is_empty():
        _fail(failures, "XCamp-4b: duplicate name in pool: %s" % dup)
    elif PlayerCompanionSetup.FIGHTER_NAMES.has(PlayerCompanionSetup.PLAYER_FIGHTER_NAME):
        _fail(
            failures,
            "XCamp-4b: hero name '%s' must not be in the companion pool" % PlayerCompanionSetup.PLAYER_FIGHTER_NAME
        )
    else:
        _pass()
    var ent: Node = _harness_core_entity()
    ent.name = "Companion2"
    if PlayerCompanionSetup.resolve_fighter_display_name(ent) != PlayerCompanionSetup.FIGHTER_NAMES[1]:
        _fail(
            failures,
            (
                "XCamp-4b: empty fighter_name should fall back to slot name '%s' got '%s'"
                % [PlayerCompanionSetup.FIGHTER_NAMES[1], PlayerCompanionSetup.resolve_fighter_display_name(ent)]
            )
        )
    else:
        _pass()
    ent.fighter_name = "Brann"
    if PlayerCompanionSetup.resolve_fighter_display_name(ent) != "Brann":
        _fail(failures, "XCamp-4b: persisted fighter_name should beat slot-derived name")
    else:
        _pass()
    _free_harness_core_entity(ent)
    var rng := RandomNumberGenerator.new()
    rng.seed = 1
    var used_all := PackedStringArray()
    used_all.append_array(PlayerCompanionSetup.FIGHTER_NAMES)
    if PlayerCompanionSetup._roll_name(used_all, rng) != "":
        _fail(failures, "XCamp-4b: exhausted pool should roll empty so caller falls back to slot name")
    else:
        _pass()
    var used_one := PackedStringArray()
    used_one.append_array(PlayerCompanionSetup.FIGHTER_NAMES)
    used_one.remove_at(0)
    if PlayerCompanionSetup._roll_name(used_one, rng) != PlayerCompanionSetup.FIGHTER_NAMES[0]:
        _fail(
            failures,
            "XCamp-4b: single free name should be rolled, got '%s'" % PlayerCompanionSetup._roll_name(used_one, rng)
        )
    else:
        _pass()


## XCamp-4b: gather_living_fighter_names includes only living members; a fallen member's
## name is freed for reuse.


static func _run_xcamp_4b_living_names_invariant(failures: PackedStringArray) -> void:
    var world := Node2D.new()
    var player_ent: Node = _harness_core_entity()
    player_ent.name = "Character"
    player_ent.apply_species()
    player_ent.fighter_name = "Ash"
    world.add_child(player_ent)
    var c1: Node = _harness_core_entity()
    c1.name = "Companion"
    c1.apply_species()
    c1.fighter_name = "Brann"
    player_ent.add_child(c1)
    var c2: Node = _harness_core_entity()
    c2.name = "Companion2"
    c2.apply_species()
    c2.fighter_name = "Sola"
    c2.blood_volume = 0.0
    player_ent.add_child(c2)
    var used: PackedStringArray = PlayerCompanionSetup.gather_living_fighter_names(world)
    if used.size() != 2 or used[0] != "Ash" or used[1] != "Brann":
        _fail(failures, "XCamp-4b: living names want [Ash, Brann] (dead name freed) got %s" % str(used))
    else:
        _pass()
    _release_harness_world(world)


## XCamp-4c: recruit quality label and hire cost scale with company renown, are inert at
## renown 0 (XCamp-3.1 flat-cost parity), monotonic, and capped.


static func _run_xcamp_4_c_recruit_quality_cost(failures: PackedStringArray) -> void:
    var base0: float = PlayerCompanionSetup.recruit_proficiency_base(0)
    if not is_equal_approx(base0, PlayerCompanionSetup.ROOKIE_HIRE_BASE_PROFICIENCY):
        _fail(failures, "XCamp-4c: base(0) want %f got %f" % [PlayerCompanionSetup.ROOKIE_HIRE_BASE_PROFICIENCY, base0])
    else:
        _pass()
    if PlayerCompanionSetup.recruit_quality_label(0) != "Green":
        _fail(failures, "XCamp-4c: renown 0 want Green got '%s'" % PlayerCompanionSetup.recruit_quality_label(0))
    else:
        _pass()
    if PlayerCompanionSetup.recruit_cost_for_renown(0) != CompanyState.HIRE_GOLD_COST:
        _fail(
            failures,
            (
                "XCamp-4c: cost(0) want %d (flat XCamp-3.1) got %d"
                % [CompanyState.HIRE_GOLD_COST, PlayerCompanionSetup.recruit_cost_for_renown(0)]
            )
        )
    else:
        _pass()
    if PlayerCompanionSetup.recruit_quality_label(7) != "Green":
        _fail(
            failures,
            "XCamp-4c: renown 7 (base 4.8) want Green got '%s'" % PlayerCompanionSetup.recruit_quality_label(7)
        )
    else:
        _pass()
    if PlayerCompanionSetup.recruit_quality_label(8) != "Trained":
        _fail(
            failures,
            "XCamp-4c: renown 8 (base 5.2) want Trained got '%s'" % PlayerCompanionSetup.recruit_quality_label(8)
        )
    else:
        _pass()
    var want_trained: int = int(
        round(float(CompanyState.HIRE_GOLD_COST) * PlayerCompanionSetup.RECRUIT_COST_TRAINED_MULT)
    )
    if PlayerCompanionSetup.recruit_cost_for_renown(8) != want_trained:
        _fail(
            failures,
            "XCamp-4c: Trained cost want %d got %d" % [want_trained, PlayerCompanionSetup.recruit_cost_for_renown(8)]
        )
    else:
        _pass()
    if PlayerCompanionSetup.recruit_quality_label(19) != "Trained":
        _fail(
            failures,
            "XCamp-4c: renown 19 (base 9.6) want Trained got '%s'" % PlayerCompanionSetup.recruit_quality_label(19)
        )
    else:
        _pass()
    if PlayerCompanionSetup.recruit_quality_label(20) != "Seasoned":
        _fail(
            failures,
            "XCamp-4c: renown 20 (base 10.0) want Seasoned got '%s'" % PlayerCompanionSetup.recruit_quality_label(20)
        )
    else:
        _pass()
    var want_seasoned: int = int(
        round(float(CompanyState.HIRE_GOLD_COST) * PlayerCompanionSetup.RECRUIT_COST_SEASONED_MULT)
    )
    if PlayerCompanionSetup.recruit_cost_for_renown(20) != want_seasoned:
        _fail(
            failures,
            "XCamp-4c: Seasoned cost want %d got %d" % [want_seasoned, PlayerCompanionSetup.recruit_cost_for_renown(20)]
        )
    else:
        _pass()
    var prev: int = -1
    var monotonic_ok: bool = true
    for r in range(0, 40):
        var c: int = PlayerCompanionSetup.recruit_cost_for_renown(r)
        if c < prev:
            monotonic_ok = false
            break
        prev = c
    if not monotonic_ok:
        _fail(failures, "XCamp-4c: hire cost must be non-decreasing in renown")
    else:
        _pass()
    if PlayerCompanionSetup.recruit_proficiency_base(1000) > PlayerCompanionSetup.ROOKIE_HIRE_PROFICIENCY_CAP:
        _fail(failures, "XCamp-4c: base must cap at %f" % PlayerCompanionSetup.ROOKIE_HIRE_PROFICIENCY_CAP)
    else:
        _pass()
    var world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world)
    CompanyState.set_renown(world, 20)
    CompanyState.set_gold(world, 1000)
    if CompanyRoster.recruit_cost(world) != want_seasoned:
        _fail(
            failures,
            (
                "XCamp-4c: CompanyRoster.recruit_cost(renown 20) want %d got %d"
                % [want_seasoned, CompanyRoster.recruit_cost(world)]
            )
        )
    else:
        _pass()
    var tip: String = CompanyRoster.format_hire_tooltip(world, true)
    if not tip.contains("Seasoned"):
        _fail(failures, "XCamp-4c: high-renown hire tooltip should name the quality tier, got '%s'" % tip)
    else:
        _pass()
    _free_harness_world(world)


## XCamp-4: gear commerce -- price table sanity, buy+equip weapon and armor,
## re-buy guard, broke-company guard, and the gold refund when equip is impossible.


static func _run_xcamp_4_gear_commerce(failures: PackedStringArray) -> void:
    if CompanyGear.weapon_price("SWORD") != 150:
        _fail(failures, "XCamp-4: SWORD price want 150 got %d" % CompanyGear.weapon_price("SWORD"))
    else:
        _pass()
    if CompanyGear.best_armor_for_part("head") != "KETTLE_HELM":
        _fail(failures, "XCamp-4: head best armor want KETTLE_HELM got '%s'" % CompanyGear.best_armor_for_part("head"))
    else:
        _pass()
    if CompanyGear.armor_price_for_part("head") != 120:
        _fail(failures, "XCamp-4: head armor price want 120 got %d" % CompanyGear.armor_price_for_part("head"))
    else:
        _pass()
    if CompanyGear.weapon_price("BOGUS") != 0:
        _fail(failures, "XCamp-4: unknown weapon id should price 0, got %d" % CompanyGear.weapon_price("BOGUS"))
    else:
        _pass()

    var world: Node2D = _make_world(0)
    CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var fighter: Node = _add_living_entity_member(pm, "GearBro")
    CompanyState.set_gold(world, 300)
    if not CompanyGear.can_buy_weapon(world, fighter, "SWORD"):
        _fail(failures, "XCamp-4: can_buy_weapon should pass with gold and no current sword")
    else:
        _pass()
    if not CompanyGear.buy_weapon(world, fighter, "SWORD"):
        _fail(failures, "XCamp-4: buy_weapon should succeed")
    else:
        _pass()
    if CompanyState.get_gold(world) != 300 - CompanyGear.weapon_price("SWORD"):
        _fail(
            failures,
            (
                "XCamp-4: gold after sword buy want %d got %d"
                % [300 - CompanyGear.weapon_price("SWORD"), CompanyState.get_gold(world)]
            )
        )
    else:
        _pass()
    if not CompanyGear.is_weapon_equipped(fighter, "SWORD"):
        _fail(failures, "XCamp-4: sword should read as equipped after buy")
    else:
        _pass()
    if CompanyGear.can_buy_weapon(world, fighter, "SWORD"):
        _fail(failures, "XCamp-4: already-equipped weapon should not be buyable again")
    else:
        _pass()
    if not CompanyGear.buy_armor(world, fighter, "head", "KETTLE_HELM"):
        _fail(failures, "XCamp-4: buy_armor should succeed with remaining gold")
    else:
        _pass()
    if (
        CompanyState.get_gold(world)
        != 300 - CompanyGear.weapon_price("SWORD") - CompanyGear.armor_price_for_part("head")
    ):
        _fail(
            failures,
            (
                "XCamp-4: gold after helm buy want %d got %d"
                % [
                    300 - CompanyGear.weapon_price("SWORD") - CompanyGear.armor_price_for_part("head"),
                    CompanyState.get_gold(world)
                ]
            )
        )
    else:
        _pass()
    if not CompanyGear.is_best_armor_equipped(fighter, "head"):
        _fail(failures, "XCamp-4: kettle helm should read as equipped after buy")
    else:
        _pass()
    CompanyState.set_gold(world, 0)
    var broke: Node = _add_living_entity_member(pm, "BrokeBro")
    if CompanyGear.can_buy_weapon(world, broke, "SWORD"):
        _fail(failures, "XCamp-4: broke company should not pass can_buy_weapon")
    else:
        _pass()
    if CompanyGear.buy_weapon(world, broke, "SWORD"):
        _fail(failures, "XCamp-4: buy_weapon should fail without gold")
    else:
        _pass()
    _release_harness_world(world)

    var refund_world: Node2D = _make_world(1)
    CompanyState.attach_to_world(refund_world)
    var stub_node: Node = (refund_world.get_meta("party_manager").members[0] as Dictionary).get("node_ref")
    CompanyState.set_gold(refund_world, 500)
    if not CompanyGear.can_buy_weapon(refund_world, stub_node, "SWORD"):
        _fail(failures, "XCamp-4: refund fixture should pass can_buy_weapon (no weapon yet, has gold)")
    else:
        _pass()
    if CompanyGear.buy_weapon(refund_world, stub_node, "SWORD"):
        _fail(failures, "XCamp-4: buy on equip-incapable entity should fail")
    else:
        _pass()
    if CompanyState.get_gold(refund_world) != 500:
        _fail(failures, "XCamp-4: failed buy should refund gold, want 500 got %d" % CompanyState.get_gold(refund_world))
    else:
        _pass()
    _release_harness_world(refund_world)


## XCamp-4b: fighter_name and the rolled base-stats survive a P2 save/load/apply roundtrip.
## Uses distinctive values that differ from what a fresh re-roll would produce, so the test
## genuinely proves the apply path writes the saved values (not the rolled defaults).


static func _run_xcamp_4b_name_persistence_roundtrip(failures: PackedStringArray) -> void:
    CampaignPersistence.clear_slot()
    var world: Node2D = _instantiate_main_hire_world(true)
    var player_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        CampaignEncounterBridge.get_player(world)
    )
    var comp_node: Node = world.get_node_or_null("Character/Companion")
    var comp_ent: Node = CampaignEncounterBridge.health_entity_from_character(comp_node)
    if player_ent == null or comp_ent == null:
        _fail(failures, "XCamp-4b P2: could not resolve player/companion entities")
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    player_ent.strength = 117
    comp_ent.fighter_name = "Sentinel"
    comp_ent.strength = 84
    comp_ent.fame = 35
    # XCamp-4: verify gear (equipment) also survives the round-trip.
    EncounterSpawner.equip_weapon_id(player_ent, "SWORD")
    var helm: ArmorPiece = ArmorPiece.create_from_definition("KETTLE_HELM")
    if helm != null and comp_ent.has_method("equip_armor"):
        comp_ent.equip_armor("head", helm)
    if not CampaignPersistence.save_slot(world):
        _fail(failures, "XCamp-4b P2: save_slot after setup failed")
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    _pass()
    var loaded: Dictionary = CampaignPersistence.load_save()
    if not CampaignPersistence.is_valid_save(loaded):
        _fail(failures, "XCamp-4b P2: loaded save should be valid v%d" % CampaignPersistence.SAVE_VERSION)
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    _pass()
    var fresh: Node2D = _instantiate_main_hire_world(true)
    var rng := RandomNumberGenerator.new()
    CampaignPersistence.apply_save(fresh, loaded, rng, null)
    var f_player_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        CampaignEncounterBridge.get_player(fresh)
    )
    var f_comp_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        fresh.get_node_or_null("Character/Companion")
    )
    if f_player_ent == null or f_comp_ent == null:
        _fail(failures, "XCamp-4b P2: could not resolve entities in restored world")
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        _free_harness_world(fresh)
        return
    if str(f_player_ent.fighter_name) != "Ash":
        _fail(failures, "XCamp-4b P2: player fighter_name want 'Ash' got '%s'" % str(f_player_ent.fighter_name))
    else:
        _pass()
    if int(f_player_ent.strength) != 117:
        _fail(failures, "XCamp-4b P2: player base strength want 117 got %d" % int(f_player_ent.strength))
    else:
        _pass()
    if str(f_comp_ent.fighter_name) != "Sentinel":
        _fail(failures, "XCamp-4b P2: companion fighter_name want 'Sentinel' got '%s'" % str(f_comp_ent.fighter_name))
    else:
        _pass()
    if int(f_comp_ent.strength) != 84:
        _fail(failures, "XCamp-4b P2: companion base strength want 84 got %d" % int(f_comp_ent.strength))
    else:
        _pass()
    # XCamp-5f: per-fighter fame (career arc) must survive the round-trip.
    if int(f_comp_ent.fame) != 35:
        _fail(failures, "XCamp-5f P2: companion fame want 35 got %d" % int(f_comp_ent.fame))
    else:
        _pass()
    # XCamp-4: gear (equipment) must also survive the round-trip.
    if EncounterSpawner.weapon_id_from_entity(f_player_ent) != "SWORD":
        _fail(
            failures,
            "XCamp-4 P2: player weapon want SWORD got '%s'" % EncounterSpawner.weapon_id_from_entity(f_player_ent)
        )
    else:
        _pass()
    var f_comp_armor: Dictionary = EncounterSpawner.armor_ids_from_entity(f_comp_ent)
    if str(f_comp_armor.get("head", "")) != "KETTLE_HELM":
        _fail(failures, "XCamp-4 P2: comp head armor want KETTLE_HELM got '%s'" % str(f_comp_armor.get("head", "")))
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _free_harness_world(world)
    _free_harness_world(fresh)


## XCamp-4b/4c: end-to-end hire integration — the recruit actually receives a pool name
## (no collision with a living member), pays the renown-scaled cost, and arrives with an
## elevated proficiency baseline at high renown.


static func _run_xcamp_4b_4c_hire_integration(failures: PackedStringArray) -> void:
    # --- Renown 0: baseline hire gets a pool name and pays the flat cost ---
    var world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world)
    CompanyState.set_renown(world, 0)
    CompanyState.set_gold(world, CompanyState.HIRE_GOLD_COST + 100)
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var hired: bool = CompanyRoster.try_hire_rookie(world, rng, true)
    if not hired:
        _fail(failures, "XCamp-4b/4c: hire at renown 0 should succeed")
    else:
        _pass()
    if CompanyState.get_gold(world) != 100:
        _fail(failures, "XCamp-4b/4c: gold after renown-0 hire want 100 got %d" % CompanyState.get_gold(world))
    else:
        _pass()
    var comp_node: Node = world.get_node_or_null("Character/Companion")
    if comp_node == null:
        _fail(failures, "XCamp-4b/4c: companion node not found after hire")
    else:
        _pass()
        var display_name: String = PlayerCompanionSetup.resolve_fighter_display_name(comp_node)
        if display_name.is_empty():
            _fail(failures, "XCamp-4b/4c: hired fighter should have a non-empty display name")
        elif not (
            display_name == PlayerCompanionSetup.PLAYER_FIGHTER_NAME
            or PlayerCompanionSetup.FIGHTER_NAMES.has(display_name)
        ):
            _fail(failures, "XCamp-4b/4c: display name '%s' not in known pool" % display_name)
        else:
            _pass()
        if display_name == PlayerCompanionSetup.PLAYER_FIGHTER_NAME:
            _fail(failures, "XCamp-4b/4c: hired fighter should not share the player hero name")
        else:
            _pass()
    _release_harness_world(world)

    # --- Name collision: a fallen member's name is freed, and a hire filling that
    # slot must not reuse any living member's name (production flow: death ->
    # roster removal -> hire into the vacant slot). ---
    var world2: Node2D = _instantiate_main_hire_world(true)
    var pm2: Node = world2.get_meta("party_manager")
    var comp6_node: Node = world2.get_node_or_null("Character/Companion6")
    if comp6_node == null:
        _fail(failures, "XCamp-4b/4c collision: Companion6 node missing in fixture")
    else:
        _pass()
        var ent6: Node = CampaignEncounterBridge.health_entity_from_character(comp6_node)
        if ent6 == null:
            _fail(failures, "XCamp-4b/4c collision: Companion6 entity not resolvable")
        else:
            ent6.blood_volume = 0.0
            pm2.remove_member_by_name("Companion6")
    var living_names: PackedStringArray = PlayerCompanionSetup.gather_living_fighter_names(world2)
    if living_names.size() != 6:
        _fail(failures, "XCamp-4b/4c collision: living names after one death want 6 got %d" % living_names.size())
    else:
        _pass()
    CompanyState.set_renown(world2, 0)
    CompanyState.set_gold(world2, CompanyState.HIRE_GOLD_COST + 100)
    var rng2 := RandomNumberGenerator.new()
    rng2.seed = 42
    var hired2: bool = CompanyRoster.try_hire_rookie(world2, rng2, true)
    if not hired2:
        _fail(failures, "XCamp-4b/4c collision: hire should succeed with a vacancy")
    else:
        _pass()
    var new_node: Node = world2.get_node_or_null("Character/Companion6")
    if new_node == null:
        _fail(failures, "XCamp-4b/4c collision: Companion6 node not found after hire")
    else:
        _pass()
        var new_name: String = PlayerCompanionSetup.resolve_fighter_display_name(new_node)
        if new_name.is_empty() or living_names.has(new_name):
            _fail(failures, "XCamp-4b/4c collision: new name '%s' is empty or reused a living name" % new_name)
        else:
            _pass()
    _release_harness_world(world2)

    # --- Renown 20: seasoned cost and an elevated per-stat proficiency baseline ---
    var world3: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world3)
    CompanyState.set_renown(world3, 20)
    var seasoned_cost: int = PlayerCompanionSetup.recruit_cost_for_renown(20)
    CompanyState.set_gold(world3, seasoned_cost + 100)
    var rng3 := RandomNumberGenerator.new()
    rng3.seed = 99
    var hired3: bool = CompanyRoster.try_hire_rookie(world3, rng3, true)
    if not hired3:
        _fail(failures, "XCamp-4c: hire at renown 20 should succeed")
    else:
        _pass()
    if CompanyState.get_gold(world3) != 100:
        _fail(failures, "XCamp-4c: gold after renown-20 hire want 100 got %d" % CompanyState.get_gold(world3))
    else:
        _pass()
    var comp3: Node = world3.get_node_or_null("Character/Companion")
    if comp3 == null:
        _fail(failures, "XCamp-4c: companion node not found after renown-20 hire")
    else:
        _pass()
        var ent3: Node = CampaignEncounterBridge.health_entity_from_character(comp3)
        if ent3 == null or not "_proficiency_bonus" in ent3:
            _fail(failures, "XCamp-4c: hired entity missing _proficiency_bonus")
        else:
            var bonuses: Dictionary = ent3._proficiency_bonus
            var min_bonus: float = INF
            for stat in EntityStatsUtil.PROFICIENCY_STATS:
                var v: float = float(bonuses.get(stat, 0.0))
                if v < min_bonus:
                    min_bonus = v
            if min_bonus < 5.0:
                _fail(failures, "XCamp-4c: renown-20 hire min proficiency bonus want >= 5.0 got %.2f" % min_bonus)
            else:
                _pass()
    _release_harness_world(world3)


## XCamp-5f: per-fighter fame accrues on a victory, scaled by desirable difficulty (a stronger foe
## teaches more), and pays a sponsor bonus for survivors at/above the qualifying career tier. Each
## survivor's own strength is pinned to 100.0 so only the foe-strength dimension varies; the expected
## gain is recomputed from the production constant + difficulty function (no hardcoded float).


static func _run_xcamp_5f_fame_accrual(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_fighter_fame_enabled():
        return
    var own: float = 100.0
    # foe = ceiling / baseline / floor of the difficulty band -> three distinct multipliers.
    for foe in [200.0, 100.0, 40.0]:
        var res: Dictionary = _measure_fame_award(failures, foe, own)
        if res.is_empty():
            return
        var want_gain: int = roundi(
            float(CompanyState.FAME_WIN_BASE) * EntityProficiency.opponent_difficulty_mult(foe, own)
        )
        if int(res.get("fame", -1)) != want_gain:
            _fail(failures, "fame: foe=%.0f gain want %d got %d" % [foe, want_gain, int(res.get("fame", -1))])
        else:
            _pass()
        var tier_min: int = int(
            (CompanyState.FAME_TIERS[CompanyState.FAME_SPONSOR_MIN_TIER_INDEX] as Dictionary).get("min", 0)
        )
        var want_sponsor: int = (
            CompanyState.FAME_SPONSOR_PER_QUALIFYING_FIGHTER if int(res.get("fame", 0)) >= tier_min else 0
        )
        if int(res.get("sponsor", -1)) != want_sponsor:
            _fail(
                failures,
                (
                    "fame: foe=%.0f sponsor want %d got %d (fame=%d tier_min=%d)"
                    % [foe, want_sponsor, int(res.get("sponsor", -1)), int(res.get("fame", 0)), tier_min]
                )
            )
        else:
            _pass()
        # Promotion note is emitted exactly when the survivor climbs a tier on this award.
        var fame_now: int = int(res.get("fame", 0))
        var want_promo: bool = CompanyState.fame_tier_label(0) != CompanyState.fame_tier_label(fame_now)
        var promos: PackedStringArray = res.get("promotions", PackedStringArray())
        if want_promo != (promos.size() > 0):
            _fail(
                failures,
                (
                    "fame: foe=%.0f promotion-note presence want=%s got %d notes (fame=%d)"
                    % [foe, str(want_promo), promos.size(), fame_now]
                )
            )
        else:
            _pass()


## XCamp-5f helper: fresh leader-only world, pin survivor strength, set foe-strength meta + last-battle
## summary, run award_fame_for_victory; returns {fame: gain, sponsor: gold}. Returns {} on setup failure.


static func _measure_fame_award(failures: PackedStringArray, foe_str: float, own_str: float) -> Dictionary:
    var world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world)
    var pm: Node = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null:
        _fail(failures, "fame: no party_manager in fixture")
        _release_harness_world(world)
        return {}
    var members: Array = []
    for m in pm.members:
        if not (m is Dictionary):
            continue
        members.append({"name": str((m as Dictionary).get("name", "")), "snapshot": {"strength": own_str}})
    if members.is_empty():
        _fail(failures, "fame: no living members to award")
        _release_harness_world(world)
        return {}
    world.set_meta(CampaignTypes.WORLD_META_FOE_STRENGTH, foe_str)
    world.set_meta(CampaignTypes.WORLD_META_LAST_BATTLE_SUMMARY, {"members": members, "deaths": []})
    var player_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        CampaignEncounterBridge.get_player(world)
    )
    if player_ent == null or not ("fame" in player_ent):
        _fail(failures, "fame: player entity missing or lacks 'fame' field")
        _release_harness_world(world)
        return {}
    player_ent.fame = 0
    var sponsor: int = CompanyRoster.award_fame_for_victory(world)
    var promos: Variant = world.get_meta(CampaignTypes.WORLD_META_LAST_FAME_PROMOTIONS, [])
    var res: Dictionary = {
        "fame": int(player_ent.fame),
        "sponsor": int(sponsor),
        "promotions": promos if promos is PackedStringArray else PackedStringArray(),
    }
    _release_harness_world(world)
    return res


## XCamp-5f: fame_tier_label resolves to the right FAME_TIERS row -- each tier's min maps to its own
## label, and min-1 stays on the previous row.


static func _run_xcamp_5f_fame_tier_label(failures: PackedStringArray) -> void:
    var tiers: Array = CompanyState.FAME_TIERS
    for i in range(tiers.size()):
        var tier: Dictionary = tiers[i]
        var want: String = str(tier.get("label", ""))
        var got: String = CompanyState.fame_tier_label(int(tier.get("min", 0)))
        if got != want:
            _fail(failures, "fame_tier_label: fame=%s want '%s' got '%s'" % [str(tier.get("min", 0)), want, got])
        else:
            _pass()
        if i > 0:
            var prev: Dictionary = tiers[i - 1]
            var below: int = int(tier.get("min", 0)) - 1
            if CompanyState.fame_tier_label(below) != str(prev.get("label", "")):
                _fail(
                    failures,
                    "fame_tier_label: fame=%d (below '%s') want '%s'" % [below, want, str(prev.get("label", ""))]
                )
            else:
                _pass()


## XCamp-5f: awarding is a no-op with no battle summary; sponsor gold scales with the number of
## surviving qualifying fighters; a member who died (in the summary but no longer in the live roster)
## is excluded from both the fame write and the sponsor count.


static func _run_xcamp_5f_fame_survivor_scaling(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_fighter_fame_enabled():
        return
    var w0: Node2D = _instantiate_main_hire_world(true)
    if CompanyRoster.award_fame_for_victory(w0) != 0:
        _fail(failures, "fame scaling: award with no battle summary should return 0")
    else:
        _pass()
    _release_harness_world(w0)
    var world: Node2D = _instantiate_main_hire_world(true)
    var pm: Node = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null:
        _fail(failures, "fame scaling: no party_manager in fixture")
        _release_harness_world(world)
        return
    var members: Array = []
    var names: PackedStringArray = PackedStringArray()
    for m in pm.members:
        if not (m is Dictionary):
            continue
        var nm: String = str((m as Dictionary).get("name", ""))
        names.append(nm)
        members.append({"name": nm, "snapshot": {"strength": 100.0}})
    if members.size() < 2:
        _fail(failures, "fame scaling: fixture needs >= 2 living members, got %d" % members.size())
        _release_harness_world(world)
        return
    # Dead member: listed in the battle summary, already removed from the live roster.
    members.append({"name": "Ghost", "snapshot": {"strength": 100.0}})
    world.set_meta(CampaignTypes.WORLD_META_FOE_STRENGTH, 100.0)
    world.set_meta(CampaignTypes.WORLD_META_LAST_BATTLE_SUMMARY, {"members": members, "deaths": ["Ghost"]})
    var sponsor: int = CompanyRoster.award_fame_for_victory(world)
    var per_gain: int = roundi(
        float(CompanyState.FAME_WIN_BASE) * EntityProficiency.opponent_difficulty_mult(100.0, 100.0)
    )
    for m in pm.members:
        if not (m is Dictionary):
            continue
        var nr: Variant = (m as Dictionary).get("node_ref")
        if not is_instance_valid(nr) or not (nr is Node):
            continue
        var ent: Node = CampaignEncounterBridge.health_entity_from_character(nr as Node)
        if ent == null or not ("fame" in ent):
            continue
        if int(ent.fame) != per_gain:
            _fail(
                failures,
                (
                    "fame scaling: survivor '%s' fame want %d got %d"
                    % [str((m as Dictionary).get("name", "")), per_gain, int(ent.fame)]
                )
            )
        else:
            _pass()
    var want_sponsor: int = names.size() * CompanyState.FAME_SPONSOR_PER_QUALIFYING_FIGHTER
    if sponsor != want_sponsor:
        _fail(failures, "fame scaling: sponsor want %d got %d (dead member must be excluded)" % [want_sponsor, sponsor])
    else:
        _pass()
    _release_harness_world(world)

## XCamp-4d: quality recruits bring their own kit through the live hire path. A Trained hire
## (renown>=8) arrives with the standard weapon; a Seasoned hire (renown>=20) arrives with that
## weapon plus a plate-grade head piece. Verified through try_hire_rookie + the entity equipment
## readout, so this exercises the real spawn flow, not the helper in isolation.
