class_name CompanyChecksGladiatorTests
extends CompanyChecksCore
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
        var want_gain: int = roundi(float(CompanyState.FAME_WIN_BASE) * EntityProficiency.opponent_difficulty_mult(foe, own))
        if int(res.get("fame", -1)) != want_gain:
            _fail(failures, "fame: foe=%.0f gain want %d got %d" % [foe, want_gain, int(res.get("fame", -1))])
        else:
            _pass()
        var tier_min: int = int((CompanyState.FAME_TIERS[CompanyState.FAME_SPONSOR_MIN_TIER_INDEX] as Dictionary).get("min", 0))
        var want_sponsor: int = (
            CompanyState.FAME_SPONSOR_PER_QUALIFYING_FIGHTER
            if int(res.get("fame", 0)) >= tier_min
            else 0
        )
        if int(res.get("sponsor", -1)) != want_sponsor:
            _fail(
                failures,
                "fame: foe=%.0f sponsor want %d got %d (fame=%d tier_min=%d)"
                % [foe, want_sponsor, int(res.get("sponsor", -1)), int(res.get("fame", 0)), tier_min]
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
                "fame: foe=%.0f promotion-note presence want=%s got %d notes (fame=%d)"
                % [foe, str(want_promo), promos.size(), fame_now]
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
                _fail(failures, "fame_tier_label: fame=%d (below '%s') want '%s'" % [below, want, str(prev.get("label", ""))])
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
                "fame scaling: survivor '%s' fame want %d got %d" % [str((m as Dictionary).get("name", "")), per_gain, int(ent.fame)]
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
static func _run_xcamp_4d_recruit_kit(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Trained: renown 8 -> base 5.2 (>= NOVICE_MAX, < PROFICIENT_MAX) -> standard weapon.
    var trained_world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(trained_world)
    CompanyState.set_renown(trained_world, 8)
    CompanyState.set_gold(trained_world, PlayerCompanionSetup.recruit_cost_for_renown(8) + 100)
    var tr_rng := RandomNumberGenerator.new()
    tr_rng.seed = 1234
    if CompanyRoster.try_hire_rookie(trained_world, tr_rng, true):
        _pass()
    else:
        _fail(failures, "recruit_kit: Trained hire at renown 8 should succeed")
    var tr_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        trained_world.get_node_or_null("Character/Companion")
    )
    var tr_weapon: String = str(EncounterSpawner.weapon_id_from_entity(tr_ent)).strip_edges() if tr_ent != null else ""
    if tr_weapon != PlayerCompanionSetup.RECRUIT_KIT_WEAPON:
        _fail(failures, "recruit_kit: Trained hire weapon want %s got '%s'" % [PlayerCompanionSetup.RECRUIT_KIT_WEAPON, tr_weapon])
    else:
        _pass()
    _release_harness_world(trained_world)

    # Seasoned: renown 20 -> base 10.0 (>= PROFICIENT_MAX) -> standard weapon + plate head piece.
    var season_world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(season_world)
    CompanyState.set_renown(season_world, 20)
    CompanyState.set_gold(season_world, PlayerCompanionSetup.recruit_cost_for_renown(20) + 100)
    var se_rng := RandomNumberGenerator.new()
    se_rng.seed = 5678
    if CompanyRoster.try_hire_rookie(season_world, se_rng, true):
        _pass()
    else:
        _fail(failures, "recruit_kit: Seasoned hire at renown 20 should succeed")
    var se_ent: Node = CampaignEncounterBridge.health_entity_from_character(
        season_world.get_node_or_null("Character/Companion")
    )
    var se_weapon: String = str(EncounterSpawner.weapon_id_from_entity(se_ent)).strip_edges() if se_ent != null else ""
    if se_weapon != PlayerCompanionSetup.RECRUIT_KIT_WEAPON:
        _fail(failures, "recruit_kit: Seasoned hire weapon want %s got '%s'" % [PlayerCompanionSetup.RECRUIT_KIT_WEAPON, se_weapon])
    else:
        _pass()
    var se_armor: Dictionary = EncounterSpawner.armor_ids_from_entity(se_ent) if se_ent != null else {}
    var got_head: String = str(se_armor.get(PlayerCompanionSetup.RECRUIT_KIT_ARMOR_PART, "")).strip_edges()
    if got_head != PlayerCompanionSetup.RECRUIT_KIT_ARMOR_ID:
        _fail(failures, "recruit_kit: Seasoned hire %s armor want %s got '%s'" % [PlayerCompanionSetup.RECRUIT_KIT_ARMOR_PART, PlayerCompanionSetup.RECRUIT_KIT_ARMOR_ID, got_head])
    else:
        _pass()
    _release_harness_world(season_world)


## XCamp-4e: sell/unequip gear. Verify sell values are computed correctly, selling an equipped
## weapon/armor refunds gold and clears the slot, and selling nothing equipped returns 0.
static func _run_xcamp_4e_sell_unequip(failures: PackedStringArray) -> void:
    if CompanyGear.sell_value_for_weapon("SWORD") != 75:
        _fail(failures, "sell: SWORD sell value want 75 got %d" % CompanyGear.sell_value_for_weapon("SWORD"))
    else:
        _pass()
    if CompanyGear.sell_value_for_weapon("MACE") != 90:
        _fail(failures, "sell: MACE sell value want 90 got %d" % CompanyGear.sell_value_for_weapon("MACE"))
    else:
        _pass()
    if CompanyGear.sell_value_for_piece("KETTLE_HELM") != 60:
        _fail(failures, "sell: KETTLE_HELM sell value want 60 got %d" % CompanyGear.sell_value_for_piece("KETTLE_HELM"))
    else:
        _pass()
    if CompanyGear.sell_value_for_piece("CUIRASS") != 75:
        _fail(failures, "sell: CUIRASS sell value want 75 got %d" % CompanyGear.sell_value_for_piece("CUIRASS"))
    else:
        _pass()
    if CompanyGear.sell_value_for_piece("GAMBESON") != 20:
        _fail(failures, "sell: GAMBESON sell value want 20 got %d" % CompanyGear.sell_value_for_piece("GAMBESON"))
    else:
        _pass()
    if CompanyGear.sell_value_for_weapon("BOGUS") != 0:
        _fail(failures, "sell: unknown weapon should price 0, got %d" % CompanyGear.sell_value_for_weapon("BOGUS"))
    else:
        _pass()
    if CompanyGear.sell_value_for_piece("BOGUS") != 0:
        _fail(failures, "sell: unknown armor should price 0, got %d" % CompanyGear.sell_value_for_piece("BOGUS"))
    else:
        _pass()
    var world: Node2D = _make_world(0)
    CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var fighter: Node = _add_living_entity_member(pm, "SellBro")
    CompanyState.set_gold(world, 0)
    if CompanyGear.sell_equipped_weapon(world, fighter) != 0:
        _fail(failures, "sell: selling with no weapon should refund 0, got %d" % CompanyGear.sell_equipped_weapon(world, fighter))
    else:
        _pass()
    CompanyState.set_gold(world, 300)
    CompanyGear.buy_weapon(world, fighter, "SWORD")
    if not CompanyGear.is_weapon_equipped(fighter, "SWORD"):
        _fail(failures, "sell: SWORD should be equipped before sell test")
        _release_harness_world(world)
        return
    var gold_before: int = CompanyState.get_gold(world)
    var refund: int = CompanyGear.sell_equipped_weapon(world, fighter)
    if refund != 75:
        _fail(failures, "sell: weapon refund want 75 got %d" % refund)
    else:
        _pass()
    if CompanyState.get_gold(world) != gold_before + 75:
        _fail(failures, "sell: gold after weapon sell want %d got %d" % [gold_before + 75, CompanyState.get_gold(world)])
    else:
        _pass()
    if CompanyGear.equipped_weapon_id(fighter) != "":
        _fail(failures, "sell: weapon should be unequipped after sell, got '%s'" % CompanyGear.equipped_weapon_id(fighter))
    else:
        _pass()
    CompanyGear.buy_armor(world, fighter, "head", "KETTLE_HELM")
    if not CompanyGear.is_best_armor_equipped(fighter, "head"):
        _fail(failures, "sell: head armor should be equipped before sell test")
        _release_harness_world(world)
        return
    var gold_before_armor: int = CompanyState.get_gold(world)
    var armor_refund: int = CompanyGear.sell_equipped_armor(world, fighter, "head")
    if armor_refund != 60:
        _fail(failures, "sell: head armor refund want 60 got %d" % armor_refund)
    else:
        _pass()
    if CompanyState.get_gold(world) != gold_before_armor + 60:
        _fail(failures, "sell: gold after armor sell want %d got %d" % [gold_before_armor + 60, CompanyState.get_gold(world)])
    else:
        _pass()
    if CompanyGear.equipped_armor_piece_id(fighter, "head") != "":
        _fail(failures, "sell: head armor should be unequipped after sell, got '%s'" % CompanyGear.equipped_armor_piece_id(fighter, "head"))
    else:
        _pass()
    if CompanyGear.sell_equipped_armor(world, fighter, "head") != 0:
        _fail(failures, "sell: selling already-sold armor should refund 0")
    else:
        _pass()
    # XCamp-4v: worn armor sells for less than fresh (condition-scaled refund).
    CompanyState.set_gold(world, 300)
    CompanyGear.buy_armor(world, fighter, "head", "KETTLE_HELM")
    var ent_sell: Node = CampaignEncounterBridge.health_entity_from_character(fighter)
    var helm: ArmorPiece = ent_sell.armor_slots.get("head") as ArmorPiece
    if helm != null:
        helm.layers[0][ArmorConstants.ARMOR_LAYER_KEY_DURABILITY] = 50.0
    var worn_refund: int = CompanyGear.sell_equipped_armor(world, fighter, "head")
    # KETTLE_HELM price 120, 50% condition -> roundi(120 * 0.5 * 0.5) = 30.
    if worn_refund != 30:
        _fail(failures, "sell: worn head armor refund want 30 got %d" % worn_refund)
    else:
        _pass()
    if CompanyGear.sell_equipped_armor(world, fighter, "head") != 0:
        _fail(failures, "sell: selling already-sold armor (worn) should refund 0")
    else:
        _pass()
    _release_harness_world(world)


## XCamp-4f: armor tier ladder. Verify per-part ladder shape, tier-index helpers,
## upgrade-only gating (no re-buys / no downgrades), price consistency, and that
## buying a mid tier equips that exact piece.
static func _run_xcamp_4f_armor_tiers(failures: PackedStringArray) -> void:
    # Ladder shape: all parts now have 4 tiers (cloth < leather < mail < plate).
    if CompanyGear.armor_tiers_for_part("head").size() != 4:
        _fail(failures, "tiers: head ladder want 4 entries got %d" % CompanyGear.armor_tiers_for_part("head").size())
    else:
        _pass()
    if CompanyGear.armor_tiers_for_part("chest").size() != 4:
        _fail(failures, "tiers: chest ladder want 4 entries got %d" % CompanyGear.armor_tiers_for_part("chest").size())
    else:
        _pass()
    if CompanyGear.armor_tiers_for_part("right_arm").size() != 4:
        _fail(failures, "tiers: right_arm ladder want 4 entries got %d" % CompanyGear.armor_tiers_for_part("right_arm").size())
    else:
        _pass()
    if CompanyGear.armor_tiers_for_part("left_leg").size() != 4:
        _fail(failures, "tiers: left_leg ladder want 4 entries got %d" % CompanyGear.armor_tiers_for_part("left_leg").size())
    else:
        _pass()

    # best_armor_for_part still returns the top (plate) tier.
    if CompanyGear.best_armor_for_part("chest") != "CUIRASS":
        _fail(failures, "tiers: best for chest want CUIRASS got '%s'" % CompanyGear.best_armor_for_part("chest"))
    else:
        _pass()

    # Tier indices: -1 for unknown piece, increasing up the ladder.
    if CompanyGear.armor_tier_index("chest", "GAMBESON") != 0:
        _fail(failures, "tiers: GAMBESON index on chest want 0 got %d" % CompanyGear.armor_tier_index("chest", "GAMBESON"))
    else:
        _pass()
    if CompanyGear.armor_tier_index("chest", "CUIRASS") != 3:
        _fail(failures, "tiers: CUIRASS index on chest want 3 got %d" % CompanyGear.armor_tier_index("chest", "CUIRASS"))
    else:
        _pass()
    if CompanyGear.armor_tier_index("head", "CUIRASS") != -1:
        _fail(failures, "tiers: CUIRASS is not a head tier, want index -1 got %d" % CompanyGear.armor_tier_index("head", "CUIRASS"))
    else:
        _pass()

    # Prices strictly increase up each ladder (non-decreasing, last > first).
    for part in CompanyGear.ARMOR_PART_SALE_ORDER:
        var tiers: Array = CompanyGear.armor_tiers_for_part(part)
        for i in range(1, tiers.size()):
            if CompanyGear.armor_price(str(tiers[i])) <= CompanyGear.armor_price(str(tiers[i - 1])):
                _fail(failures, "tiers: %s prices not strictly increasing at index %d" % [part, i])
                break

    # Buy/sell symmetry: selling a piece refunds exactly half its buy price.
    for part in CompanyGear.ARMOR_PART_SALE_ORDER:
        var tiers: Array = CompanyGear.armor_tiers_for_part(part)
        for pid in tiers:
            var pid_s: String = str(pid)
            if CompanyGear.sell_value_for_piece(pid_s) != roundi(float(CompanyGear.armor_price(pid_s)) * 0.5):
                _fail(failures, "tiers: sell value for %s not half of buy price" % pid_s)
                break

    # armor_price_for_part back-compat: equals the top-tier price.
    if CompanyGear.armor_price_for_part("right_arm") != CompanyGear.armor_price("VAMBRACES_RIGHT"):
        _fail(failures, "tiers: armor_price_for_part(right_arm) should equal VAMBRACES_RIGHT price")
    else:
        _pass()

    # Live behavior: bare fighter can buy the cheapest tier; re-buy blocked; downgrade blocked.
    var world: Node2D = _make_world(0)
    CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var fighter: Node = _add_living_entity_member(pm, "TierBro")
    CompanyState.set_gold(world, 200)

    # head: cloth (30) < leather (50) < plate (120). Start bare, buy leather cap.
    if not CompanyGear.can_buy_armor(world, fighter, "head", "LEATHER_CAP"):
        _fail(failures, "tiers: bare fighter should be able to buy LEATHER_CAP on head")
    else:
        _pass()
    if not CompanyGear.buy_armor(world, fighter, "head", "LEATHER_CAP"):
        _fail(failures, "tiers: buying LEATHER_CAP should succeed")
    else:
        _pass()
    if CompanyGear.equipped_armor_piece_id(fighter, "head") != "LEATHER_CAP":
        _fail(failures, "tiers: head should wear LEATHER_CAP, got '%s'" % CompanyGear.equipped_armor_piece_id(fighter, "head"))
    else:
        _pass()
    if not CompanyGear.is_armor_equipped(fighter, "head", "LEATHER_CAP"):
        _fail(failures, "tiers: is_armor_equipped should see LEATHER_CAP on head")
    else:
        _pass()
    # Re-buy same tier: blocked.
    if CompanyGear.can_buy_armor(world, fighter, "head", "LEATHER_CAP"):
        _fail(failures, "tiers: re-buying the worn tier should be blocked")
    else:
        _pass()
    # Downgrade (cloth coif is below worn leather cap): blocked even with gold.
    if CompanyGear.can_buy_armor(world, fighter, "head", "CLOTH_COIF"):
        _fail(failures, "tiers: downgrading from leather cap to cloth coif should be blocked")
    else:
        _pass()
    # Upgrade to plate helm: allowed.
    if not CompanyGear.can_buy_armor(world, fighter, "head", "KETTLE_HELM"):
        _fail(failures, "tiers: upgrading from leather cap to kettle helm should be allowed")
    else:
        _pass()
    if CompanyGear.buy_armor(world, fighter, "head", "KETTLE_HELM"):
        _pass()
    else:
        _fail(failures, "tiers: buying KETTLE_HELM upgrade should succeed")
    if not CompanyGear.is_best_armor_equipped(fighter, "head"):
        _fail(failures, "tiers: after upgrade, best armor should read as equipped on head")
    else:
        _pass()
    # Chest: mail hauberk is the mid tier between leather and plate.
    if CompanyGear.armor_tier_index("chest", "HAUBERK") == 2 and CompanyGear.armor_tier_index("chest", "CUIRASS") == 3:
        _pass()
    else:
        _fail(failures, "tiers: chest mail should sit between leather and plate")
    _release_harness_world(world)


## XCamp-4h: armor condition is surfaced (weakest-layer durability) and read from live pieces.
static func _run_xcamp_4h_armor_condition(failures: PackedStringArray) -> void:
    # Pure: a fresh piece reads 100% condition.
    var fresh: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if fresh == null:
        _fail(failures, "cond: could not build CUIRASS")
        return
    if fresh.get_condition_pct() != 100.0:
        _fail(failures, "cond: fresh CUIRASS want 100.0 got %s" % str(fresh.get_condition_pct()))
    else:
        _pass()

    # Pure: degrading the outer layer drops condition to the weakest layer.
    (fresh.layers[0] as Dictionary)["durability"] = 42.0
    if fresh.get_condition_pct() != 42.0:
        _fail(failures, "cond: worn CUIRASS want 42.0 got %s" % str(fresh.get_condition_pct()))
    else:
        _pass()

    # Pure: destroying every layer reads 0.0 (not -1, not 100).
    for layer in fresh.layers:
        (layer as Dictionary)["durability"] = 0.0
    if fresh.get_condition_pct() != 0.0:
        _fail(failures, "cond: destroyed CUIRASS want 0.0 got %s" % str(fresh.get_condition_pct()))
    else:
        _pass()

    # Live: equip a fresh piece on a harness entity; the map reports name + 100% condition.
    var world: Node2D = _make_world(0)
    CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var fighter: Node = _add_living_entity_member(pm, "CondBro")
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null or not fighter.has_method("equip_armor"):
        _fail(failures, "cond: could not build/equip CUIRASS on harness entity")
        _release_harness_world(world)
        return
    fighter.equip_armor("chest", cuirass)

    var cmap: Dictionary = CompanyGear.equipped_armor_condition_map(fighter)
    if not cmap.has("chest"):
        _fail(failures, "cond: map should include the equipped chest part")
    else:
        _pass()
    var chest: Dictionary = cmap.get("chest", {})
    if str(chest.get("name", "")) != "Cuirass":
        _fail(failures, "cond: chest name want 'Cuirass' got '%s'" % str(chest.get("name", "")))
    else:
        _pass()
    if float(chest.get("condition", -1.0)) != 100.0:
        _fail(failures, "cond: fresh equipped chest condition want 100.0 got %s" % str(chest.get("condition", "")))
    else:
        _pass()
    # Bare parts are omitted.
    if cmap.has("head"):
        _fail(failures, "cond: bare head should not appear in the condition map")
    else:
        _pass()

    # Live: wear the live piece and re-read; condition reflects the worn layer (not a stale value).
    (cuirass.layers[0] as Dictionary)["durability"] = 30.0
    var worn: Dictionary = CompanyGear.equipped_armor_condition_map(fighter)
    var worn_chest: Dictionary = worn.get("chest", {})
    if float(worn_chest.get("condition", -1.0)) != 30.0:
        _fail(failures, "cond: worn live chest condition want 30.0 got %s" % str(worn_chest.get("condition", "")))
    else:
        _pass()
    _release_harness_world(world)


## XCamp-4h: armor layer durability survives a save/load round-trip, and repair restores worn
## armor to full condition for a proportional gold cost.
static func _run_xcamp_4h_armor_persist_repair(failures: PackedStringArray) -> void:
    CampaignPersistence.clear_slot()
    var world: Node2D = _instantiate_main_hire_world(true)
    var comp_node: Node = world.get_node_or_null("Character/Companion")
    var comp_ent: Node = CampaignEncounterBridge.health_entity_from_character(comp_node)
    if comp_ent == null or not comp_ent.has_method("equip_armor"):
        _fail(failures, "persist: could not resolve companion entity")
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null:
        _fail(failures, "persist: could not build CUIRASS")
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    comp_ent.equip_armor("chest", cuirass)
    # Wear the outer plate layer down to 40% (weakest layer -> condition 40).
    (cuirass.layers[0] as Dictionary)["durability"] = 40.0

    # Repair cost: CUIRASS price 150, condition 40 -> ceil(150 * 0.60) = 90.
    var cost: int = CompanyGear.armor_repair_cost(comp_node)
    if cost != 90:
        _fail(failures, "repair: cost for 40% CUIRASS want 90 got %d" % cost)
    else:
        _pass()

    # Repair with enough gold restores all layers to full.
    CompanyState.set_gold(world, 200)
    if not CompanyGear.can_repair_armor(world, comp_node):
        _fail(failures, "repair: can_repair_armor should be true with gold 200 >= cost 90")
    else:
        _pass()
    if not CompanyGear.repair_armor(world, comp_node):
        _fail(failures, "repair: repair_armor should succeed with sufficient gold")
    else:
        _pass()
    if CompanyState.get_gold(world) != 110:
        _fail(failures, "repair: gold after repair want 110 got %d" % CompanyState.get_gold(world))
    else:
        _pass()
    var repaired: ArmorPiece = comp_ent._get_armor_for_part("chest") as ArmorPiece
    if repaired == null:
        _fail(failures, "repair: chest armor missing after repair")
        return
    var all_full: bool = true
    for layer in repaired.layers:
        if float((layer as Dictionary).get("durability", -1.0)) != 100.0:
            _fail(failures, "repair: a layer did not return to 100.0 durability")
            all_full = false
            break
    if all_full:
        _pass()

    # Persistence: wear again, save, load into a fresh world, verify durability survived.
    (repaired.layers[0] as Dictionary)["durability"] = 40.0
    if not CampaignPersistence.save_slot(world):
        _fail(failures, "persist: save_slot after wear failed")
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    _pass()
    var loaded: Dictionary = CampaignPersistence.load_save()
    if not CampaignPersistence.is_valid_save(loaded):
        _fail(failures, "persist: loaded save should be valid v%d" % CampaignPersistence.SAVE_VERSION)
        CampaignPersistence.clear_slot()
        _free_harness_world(world)
        return
    var fresh: Node2D = _instantiate_main_hire_world(true)
    var rng := RandomNumberGenerator.new()
    CampaignPersistence.apply_save(fresh, loaded, rng, null)
    var f_comp_node: Node = fresh.get_node_or_null("Character/Companion")
    var f_comp_ent: Node = CampaignEncounterBridge.health_entity_from_character(f_comp_node)
    var f_cmap: Dictionary = CompanyGear.equipped_armor_condition_map(f_comp_node)
    var f_chest: Dictionary = f_cmap.get("chest", {})
    if str(f_chest.get("name", "")) != "Cuirass":
        _fail(failures, "persist: restored chest piece want 'Cuirass' got '%s'" % str(f_chest.get("name", "")))
    else:
        _pass()
    if float(f_chest.get("condition", -1.0)) != 40.0:
        _fail(failures, "persist: restored chest condition want 40.0 got %s" % str(f_chest.get("condition", "")))
    else:
        _pass()
    if f_comp_ent != null:
        var f_cuirass: ArmorPiece = f_comp_ent._get_armor_for_part("chest") as ArmorPiece
        if f_cuirass != null and f_cuirass.layers.size() >= 2:
            if float((f_cuirass.layers[1] as Dictionary).get("durability", -1.0)) != 100.0:
                _fail(failures, "persist: inner cloth layer should stay 100.0, got %s" % str((f_cuirass.layers[1] as Dictionary).get("durability", "")))
            else:
                _pass()
    CampaignPersistence.clear_slot()
    _free_harness_world(world)
    _free_harness_world(fresh)


## XCamp-4i: a worn armor layer protects LESS. Pins that (a) fresh armor keeps the exact
## pre-XCamp-4i behavior, (b) wear monotonically increases transmitted damage, and
## (c) a destroyed layer (0% durability) provides no protection at all.
static func _run_xcamp_4i_armor_wear_protection(failures: PackedStringArray) -> void:
    var incoming: float = 10.0
    var pen: float = 2.0

    # Build plate-layer variants: fresh / worn 50% / destroyed 0%.
    var fresh: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    fresh["durability"] = 100.0
    fresh["max_durability"] = 100.0
    var worn: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    worn["durability"] = 50.0
    worn["max_durability"] = 100.0
    var dead: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    dead["durability"] = 0.0
    dead["max_durability"] = 100.0

    # --- Sharp: a cut the fresh plate stops (pen 2.0 < 3.5 mm RHA) ---
    var sharp_fresh: float = float(ArmorPiece.sharp_penetration_math(pen, fresh, incoming)["damage"])
    var sharp_worn: float = float(ArmorPiece.sharp_penetration_math(pen, worn, incoming)["damage"])
    var sharp_dead: float = float(ArmorPiece.sharp_penetration_math(pen, dead, incoming)["damage"])
    if absf(sharp_fresh - 2.0714) > 0.01:
        _fail(failures, "wear4i: fresh plate sharp damage want ~2.071 got %s" % str(sharp_fresh))
    else:
        _pass()
    if sharp_worn <= sharp_fresh:
        _fail(failures, "wear4i: worn plate sharp damage should exceed fresh, got %s <= %s" % [str(sharp_worn), str(sharp_fresh)])
    else:
        _pass()
    if absf(sharp_dead - incoming) > 0.0001:
        _fail(failures, "wear4i: destroyed plate sharp damage should equal incoming, got %s" % str(sharp_dead))
    else:
        _pass()

    # --- Blunt: no momentum (uses base_tx * (1 - cushion)) ---
    var blunt_fresh: float = ArmorPiece.blunt_transmission_math(incoming, fresh, -1.0, -1.0)
    var blunt_worn: float = ArmorPiece.blunt_transmission_math(incoming, worn, -1.0, -1.0)
    var blunt_dead: float = ArmorPiece.blunt_transmission_math(incoming, dead, -1.0, -1.0)
    if absf(blunt_fresh - 3.825) > 0.01:
        _fail(failures, "wear4i: fresh plate blunt damage want ~3.825 got %s" % str(blunt_fresh))
    else:
        _pass()
    if blunt_worn <= blunt_fresh:
        _fail(failures, "wear4i: worn plate blunt damage should exceed fresh, got %s <= %s" % [str(blunt_worn), str(blunt_fresh)])
    else:
        _pass()
    if absf(blunt_dead - incoming) > 0.0001:
        _fail(failures, "wear4i: destroyed plate blunt damage should equal incoming, got %s" % str(blunt_dead))
    else:
        _pass()

    # --- End-to-end via apply_damage: a worn outer plate layer weakens a multi-layer piece ---
    var fresh_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    var worn_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (worn_piece.layers[0] as Dictionary)["durability"] = 50.0
    var fd: Dictionary = fresh_piece.apply_damage(incoming, "sharp", pen)
    var wd: Dictionary = worn_piece.apply_damage(incoming, "sharp", pen)
    if float(wd["damage"]) <= float(fd["damage"]):
        _fail(failures, "wear4i: worn cuirass should transmit more through apply_damage, got %s <= %s" % [str(wd["damage"]), str(fd["damage"])])
    else:
        _pass()


## XCamp-4j: armor encumbrance is live. Heavy armor slows dodge; light armor does not.
## Pins that the ENCUMBRANCE_BASELINE_MASS_KG=6.0 floor actually engages (previously the
## baseline was 25.0 and no kit ever exceeded it, so the mechanic was a no-op).
static func _run_xcamp_4j_armor_encumbrance(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(0)
    CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var bare_ent: Node = _add_living_entity_member(pm, "BareBro")
    var plate_ent: Node = _add_living_entity_member(pm, "PlateBro")
    if bare_ent == null or plate_ent == null:
        _fail(failures, "encumbrance: could not build harness entities")
        _release_harness_world(world)
        return
    # Full plate kit on the second entity.
    plate_ent.equip_armor("chest", ArmorPiece.create_from_definition("CUIRASS"))
    plate_ent.equip_armor("head", ArmorPiece.create_from_definition("KETTLE_HELM"))
    plate_ent.equip_armor("right_arm", ArmorPiece.create_from_definition("VAMBRACES_RIGHT"))
    plate_ent.equip_armor("left_arm", ArmorPiece.create_from_definition("VAMBRACES_LEFT"))
    plate_ent.equip_armor("right_leg", ArmorPiece.create_from_definition("GREAVES_RIGHT"))
    plate_ent.equip_armor("left_leg", ArmorPiece.create_from_definition("GREAVES_LEFT"))

    var bare_mod: float = float(bare_ent.get_dodge_speed_modifier())
    var plate_mod: float = float(plate_ent.get_dodge_speed_modifier())

    # No armor: encumbrance factor is exactly 1.0, so dodge speed is unpenalized.
    if absf(bare_mod - 1.0) > 0.001:
        _fail(failures, "encumbrance: bare fighter dodge modifier should be 1.0, got %s" % str(bare_mod))
    else:
        _pass()

    # Full plate (~17.7 kg) is well above the 6.0 kg baseline: a real penalty, and the
    # result must land above the MIN_PERFORMANCE_MODIFIER floor (0.15).
    if plate_mod >= bare_mod:
        _fail(failures, "encumbrance: full plate should slow dodge, got %s vs bare %s" % [str(plate_mod), str(bare_mod)])
    else:
        _pass()
    if plate_mod < 0.15:
        _fail(failures, "encumbrance: full plate should not floor to 0.15, got %s" % str(plate_mod))
    else:
        _pass()

    # Light armor (a single cloth coif, ~0.26 kg) stays under the baseline: free.
    var light_ent: Node = _add_living_entity_member(pm, "LightBro")
    light_ent.equip_armor("head", ArmorPiece.create_from_definition("CLOTH_COIF"))
    var light_mod: float = float(light_ent.get_dodge_speed_modifier())
    if absf(light_mod - 1.0) > 0.001:
        _fail(failures, "encumbrance: light armor should be free, got modifier %s" % str(light_mod))
    else:
        _pass()

    # Monotonic: adding a plate cuirass on top of the light kit must not speed the fighter up.
    light_ent.equip_armor("chest", ArmorPiece.create_from_definition("CUIRASS"))
    var light_plus_mod: float = float(light_ent.get_dodge_speed_modifier())
    if light_plus_mod > light_mod + 0.001:
        _fail(failures, "encumbrance: adding a cuirass should not increase dodge speed, got %s > %s" % [str(light_plus_mod), str(light_mod)])
    else:
        _pass()

    _release_harness_world(world)


## XCamp-4k: worn armor degrades material-accurately — a dented plate keeps more cut
## resistance than a torn cloth layer at the same durability.
static func _run_xcamp_4k_armor_material_wear(failures: PackedStringArray) -> void:
    var incoming: float = 10.0
    var pen: float = 0.5  # a light cut both a fresh plate and a fresh cloth layer stop

    var worn_plate: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    worn_plate["durability"] = 50.0
    worn_plate["max_durability"] = 100.0
    var worn_cloth: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    worn_cloth["durability"] = 50.0
    worn_cloth["max_durability"] = 100.0
    var dead_cloth: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    dead_cloth["durability"] = 0.0
    dead_cloth["max_durability"] = 100.0
    var fresh_cloth: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    fresh_cloth["durability"] = 100.0
    fresh_cloth["max_durability"] = 100.0

    # (1) Cross-material: at identical 50% wear, the rigid plate still out-cuts the torn cloth.
    var d_plate: float = float(ArmorPiece.sharp_penetration_math(pen, worn_plate, incoming)["damage"])
    var d_cloth: float = float(ArmorPiece.sharp_penetration_math(pen, worn_cloth, incoming)["damage"])
    if not d_plate < d_cloth:
        _fail(failures, "wear4k: worn plate should protect better vs cuts than worn cloth, got %s >= %s" % [str(d_plate), str(d_cloth)])
    else:
        _pass()

    # (2) Threshold degrades: a cut fresh cloth stops (deflected) now penetrates a 50% cloth layer.
    var fresh_deflected: bool = bool(ArmorPiece.sharp_penetration_math(pen, fresh_cloth, incoming)["deflected"])
    var worn_deflected: bool = bool(ArmorPiece.sharp_penetration_math(pen, worn_cloth, incoming)["deflected"])
    if not fresh_deflected or worn_deflected:
        _fail(
            failures,
            "wear4k: want fresh cloth to deflect (%s) and worn cloth to be penetrated (%s)"
            % [str(fresh_deflected), str(worn_deflected)]
        )
    else:
        _pass()

    # (3) Invariant: a destroyed cloth layer fully penetrates (damage == incoming), matching XCamp-4i.
    var d_dead: float = float(ArmorPiece.sharp_penetration_math(pen, dead_cloth, incoming)["damage"])
    if absf(d_dead - incoming) > 0.0001:
        _fail(failures, "wear4k: destroyed cloth should fully penetrate, got %s" % str(d_dead))
    else:
        _pass()


## XCamp-4l: worn armor loses blunt cushioning material-accurately — a torn gambeson degrades
## its cushion faster than a dented plate (which keeps cushioning via its underlayer).
## Uses two synthetic layers that are identical except rigidity, so the only variable is the
## XCamp-4l rigidity shield on the cushion term.
static func _run_xcamp_4l_armor_blunt_material_wear(failures: PackedStringArray) -> void:
    var incoming: float = 10.0
    # base_tx 0.55, cushion 0.5 — shared by every variant below; only rigidity + durability
    # differ. (sharp_resistance_rha_mm is present but unused on the blunt channel.)
    var fresh: Dictionary = {"sharp_resistance_rha_mm": 1.0, "blunt_transmission": 0.55,
        "blunt_cushion": 0.5, "rigidity": 0.0, "durability": 100.0, "max_durability": 100.0}
    var worn_flex: Dictionary = {"sharp_resistance_rha_mm": 1.0, "blunt_transmission": 0.55,
        "blunt_cushion": 0.5, "rigidity": 0.0, "durability": 50.0, "max_durability": 100.0}
    var worn_rigid: Dictionary = {"sharp_resistance_rha_mm": 1.0, "blunt_transmission": 0.55,
        "blunt_cushion": 0.5, "rigidity": 1.0, "durability": 50.0, "max_durability": 100.0}
    var dead: Dictionary = {"sharp_resistance_rha_mm": 1.0, "blunt_transmission": 0.55,
        "blunt_cushion": 0.5, "rigidity": 0.0, "durability": 0.0, "max_durability": 100.0}

    # (1) Invariant: fresh layer transmits exactly the no-wear value.
    #     prot=1 -> base_tx=0.55, cushion=0.5 -> 0.55 * (1 - 0.5) = 0.275 -> 10*0.275 = 2.75.
    var f_fresh: float = ArmorPiece.blunt_transmission_math(incoming, fresh, -1.0, -1.0)
    if absf(f_fresh - 2.75) > 0.01:
        _fail(failures, "wear4l: fresh layer want ~2.75 got %s" % str(f_fresh))
    else:
        _pass()

    # (2) Flexible at 50% wear still equals the XCamp-4i uniform value (rigidity 0 -> exponent 1.0).
    #     base_tx=lerp(1,0.55,0.5)=0.775, cushion=0.5*0.5=0.25 -> 0.775*0.75=0.58125 -> 5.8125.
    var f_flex: float = ArmorPiece.blunt_transmission_math(incoming, worn_flex, -1.0, -1.0)
    if absf(f_flex - 5.8125) > 0.05:
        _fail(failures, "wear4l: worn flexible want ~5.8125 (4i value) got %s" % str(f_flex))
    else:
        _pass()

    # (3) Monotonic ladder: fresh < worn_rigid < worn_flexible (rigidity shields cushion,
    #     so the rigid layer transmits less than the flexible layer at the same wear).
    var f_rigid: float = ArmorPiece.blunt_transmission_math(incoming, worn_rigid, -1.0, -1.0)
    if not (f_fresh < f_rigid and f_rigid < f_flex):
        _fail(
            failures,
            "wear4l: want fresh < worn_rigid < worn_flexible, got %s / %s / %s"
            % [str(f_fresh), str(f_rigid), str(f_flex)]
        )
    else:
        _pass()

    # (4) Invariant: a destroyed layer transmits the full incoming blow.
    var f_dead: float = ArmorPiece.blunt_transmission_math(incoming, dead, -1.0, -1.0)
    if absf(f_dead - incoming) > 0.0001:
        _fail(failures, "wear4l: destroyed layer want full transmission %s got %s" % [str(incoming), str(f_dead)])
    else:
        _pass()


## XCamp-4m: fatigue — a worn layer wears faster than a fresh one (compromised material fails
## quicker). Drives _apply_durability_loss directly with a fixed absorbed amount so the only
## variable is the layer's current durability -> the fatigue multiplier.
static func _run_xcamp_4m_armor_wear_fatigue(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.new()
    piece.body_part = "chest"
    var absorbed: float = 10.0
    var rate: float = float(ArmorConstants.LAYER_CLOTH["durability_loss_rate"])

    # Neutral rigidity (0.5) on both layers so the XCamp-4o damage-type wear modifier is
    # exactly 1.0 and the only variable is the fatigue multiplier.
    # Fresh layer (100%): fatigue multiplier is exactly 1.0 -> loss == absorbed * rate.
    var fresh_layer: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    fresh_layer["rigidity"] = 0.5
    fresh_layer["durability"] = 100.0
    fresh_layer["max_durability"] = 100.0
    piece._apply_durability_loss(fresh_layer, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var fresh_loss: float = 100.0 - float(fresh_layer["durability"])
    var expected_fresh: float = absorbed * rate
    if absf(fresh_loss - expected_fresh) > 0.001:
        _fail(failures, "fatigue4m: fresh loss want %.4f (no fatigue) got %s" % [expected_fresh, str(fresh_loss)])
    else:
        _pass()

    # Worn layer (50%): multiplier = 1 + ARMOR_WEAR_FATIGUE_MAX * 0.5 = 1.25 -> loss * 1.25.
    var worn_layer: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    worn_layer["rigidity"] = 0.5
    worn_layer["durability"] = 50.0
    worn_layer["max_durability"] = 100.0
    piece._apply_durability_loss(worn_layer, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var worn_loss: float = 50.0 - float(worn_layer["durability"])
    var expected_worn: float = absorbed * rate * 1.25
    if absf(worn_loss - expected_worn) > 0.001:
        _fail(failures, "fatigue4m: worn loss want %.4f (1.25x) got %s" % [expected_worn, str(worn_loss)])
    else:
        _pass()

    # Behavioral: at the same absorbed damage, the worn layer loses more durability.
    if not worn_loss > fresh_loss:
        _fail(failures, "fatigue4m: worn layer should wear faster, got %s <= %s" % [str(worn_loss), str(fresh_loss)])
    else:
        _pass()


## XCamp-4n: destroyed_layer_indices() drives the ARMOR_LAYER_FAIL combat trace.
## Pins the transition-detection logic: empty when fresh, exact index on partial
## failure, all indices when fully destroyed.
static func _run_xcamp_4n_armor_layer_fail_trace(failures: PackedStringArray) -> void:
    # CUIRASS = [plate (0), cloth (1)]
    var piece := ArmorPiece.create_from_definition("CUIRASS")
    if piece == null:
        _fail(failures, "layerfail4n: could not build CUIRASS")
        return

    # Fresh piece: no destroyed layers.
    var fresh_idx: Array = piece.destroyed_layer_indices()
    if fresh_idx.size() != 0:
        _fail(failures, "layerfail4n: fresh piece should have 0 destroyed layers, got %d" % fresh_idx.size())
    else:
        _pass()

    # Destroy only the outer (plate) layer -> exactly index 0.
    (piece.layers[0] as Dictionary)["durability"] = 0.0
    var partial_idx: Array = piece.destroyed_layer_indices()
    if partial_idx.size() != 1 or int(partial_idx[0]) != 0:
        _fail(failures, "layerfail4n: partial failure want [0], got %s" % str(partial_idx))
    else:
        _pass()

    # Destroy all layers -> indices == [0, 1].
    (piece.layers[1] as Dictionary)["durability"] = 0.0
    var all_idx: Array = piece.destroyed_layer_indices()
    if all_idx.size() != piece.layers.size():
        _fail(failures, "layerfail4n: all destroyed want %d, got %d" % [piece.layers.size(), all_idx.size()])
    else:
        _pass()


## XCamp-4o: damage-type-accurate wear. Two otherwise-identical synthetic layers differing only in
## rigidity: a flexible layer (rigidity 0.0) wears faster from cuts and slower from blunts; a
## rigid layer (rigidity 1.0) is the opposite. A neutral layer (rigidity 0.5) is unaffected.
static func _run_xcamp_4o_armor_damage_type_wear(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.new()
    piece.body_part = "chest"
    var absorbed: float = 10.0

    # Sharp: flexible (rigidity 0.0) should wear MORE than rigid (rigidity 1.0).
    var flex_cut: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    flex_cut["rigidity"] = 0.0
    flex_cut["durability_loss_rate"] = 0.1
    flex_cut["durability"] = 100.0
    flex_cut["max_durability"] = 100.0
    var rigid_cut: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    rigid_cut["rigidity"] = 1.0
    rigid_cut["durability_loss_rate"] = 0.1
    rigid_cut["durability"] = 100.0
    rigid_cut["max_durability"] = 100.0
    piece._apply_durability_loss(flex_cut, absorbed, ArmorConstants.DAMAGE_TYPE_SHARP)
    piece._apply_durability_loss(rigid_cut, absorbed, ArmorConstants.DAMAGE_TYPE_SHARP)
    var flex_cut_loss: float = 100.0 - float(flex_cut["durability"])
    var rigid_cut_loss: float = 100.0 - float(rigid_cut["durability"])
    if not flex_cut_loss > rigid_cut_loss:
        _fail(failures, "damagetype4o: flexible should wear more from cuts, got flex=%s rigid=%s" % [str(flex_cut_loss), str(rigid_cut_loss)])
    else:
        _pass()

    # Blunt: rigid (rigidity 1.0) should wear MORE than flexible (rigidity 0.0).
    var flex_blunt: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    flex_blunt["rigidity"] = 0.0
    flex_blunt["durability_loss_rate"] = 0.1
    flex_blunt["durability"] = 100.0
    flex_blunt["max_durability"] = 100.0
    var rigid_blunt: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    rigid_blunt["rigidity"] = 1.0
    rigid_blunt["durability_loss_rate"] = 0.1
    rigid_blunt["durability"] = 100.0
    rigid_blunt["max_durability"] = 100.0
    piece._apply_durability_loss(flex_blunt, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    piece._apply_durability_loss(rigid_blunt, absorbed, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var flex_blunt_loss: float = 100.0 - float(flex_blunt["durability"])
    var rigid_blunt_loss: float = 100.0 - float(rigid_blunt["durability"])
    if not rigid_blunt_loss > flex_blunt_loss:
        _fail(failures, "damagetype4o: rigid should wear more from blunts, got flex=%s rigid=%s" % [str(flex_blunt_loss), str(rigid_blunt_loss)])
    else:
        _pass()

    # Neutral rigidity (0.5): modifier is exactly 1.0, so loss == absorbed * rate (bit-identical).
    var neutral: Dictionary = ArmorConstants.LAYER_CLOTH.duplicate()
    neutral["rigidity"] = 0.5
    neutral["durability_loss_rate"] = 0.1
    neutral["durability"] = 100.0
    neutral["max_durability"] = 100.0
    piece._apply_durability_loss(neutral, absorbed, ArmorConstants.DAMAGE_TYPE_SHARP)
    var neutral_loss: float = 100.0 - float(neutral["durability"])
    var expected_neutral: float = absorbed * 0.1
    if absf(neutral_loss - expected_neutral) > 0.001:
        _fail(failures, "damagetype4o: neutral rigidity loss want %.4f got %s" % [expected_neutral, str(neutral_loss)])
    else:
        _pass()


## XCamp-4p: the authoritative joule wear path (apply_joule_durability_loss) now applies the same
## damage-type modifier as the scalar path (4o). Pins: flexible sharp > flexible blunt (the type
## split is live in the joule path), and neutral rigidity (0.5) is bit-identical to the pre-4p
## joule rate (absorbed * rate * JOULE_KE_DURABILITY_SCALE) — so the invariant holds.
static func _run_xcamp_4p_armor_joule_wear_consistency(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.new()
    piece.body_part = "chest"
    var absorbed_j: float = 10.0
    var rate: float = 0.1
    var scale: float = ArmorConstants.JOULE_KE_DURABILITY_SCALE
    var baseline: float = absorbed_j * rate * scale  # 0.5

    # Flexible layer (rigidity 0.0), SHARP: type_mult 1.15 -> loss = baseline * 1.15.
    var flex_sharp: Dictionary = {
        "rigidity": 0.0, "durability_loss_rate": rate,
        "durability": 100.0, "max_durability": 100.0,
    }
    piece.apply_joule_durability_loss(flex_sharp, absorbed_j, ArmorConstants.DAMAGE_TYPE_SHARP)
    var flex_sharp_loss: float = 100.0 - float(flex_sharp["durability"])
    if absf(flex_sharp_loss - baseline * 1.15) > 0.001:
        _fail(failures, "joulewear4p: flex sharp want %.4f got %s" % [baseline * 1.15, str(flex_sharp_loss)])
    else:
        _pass()

    # Flexible layer, BLUNT: type_mult 0.85 -> less wear than the sharp case.
    var flex_blunt: Dictionary = {
        "rigidity": 0.0, "durability_loss_rate": rate,
        "durability": 100.0, "max_durability": 100.0,
    }
    piece.apply_joule_durability_loss(flex_blunt, absorbed_j, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var flex_blunt_loss: float = 100.0 - float(flex_blunt["durability"])
    if not flex_sharp_loss > flex_blunt_loss:
        _fail(failures, "joulewear4p: flex sharp should wear more than flex blunt, got %s vs %s" % [str(flex_sharp_loss), str(flex_blunt_loss)])
    else:
        _pass()

    # Neutral rigidity (0.5): bit-identical to the pre-4p joule rate (no type modifier).
    var neutral: Dictionary = {
        "rigidity": 0.5, "durability_loss_rate": rate,
        "durability": 100.0, "max_durability": 100.0,
    }
    piece.apply_joule_durability_loss(neutral, absorbed_j, ArmorConstants.DAMAGE_TYPE_SHARP)
    var neutral_loss: float = 100.0 - float(neutral["durability"])
    if absf(neutral_loss - baseline) > 0.001:
        _fail(failures, "joulewear4p: neutral want %.4f (pre-4p bit-identical) got %s" % [baseline, str(neutral_loss)])
    else:
        _pass()


## XCamp-4q: breakthrough crush — when a layer is destroyed, the next surviving inner layer
## takes a one-time extra durability hit. Pins the three invariants: it wears the inner layer,
## zero absorbed energy is a no-op, and no surviving inner layer is a safe no-op.
static func _run_xcamp_4q_armor_breakthrough_crush(failures: PackedStringArray) -> void:
    var piece := ArmorPiece.create_from_definition("CUIRASS")
    if piece == null or piece.layers.size() < 2:
        _fail(failures, "crush4q: need a 2-layer CUIRASS")
        return
    var inner: Dictionary = piece.layers[1]
    var inner_before: float = float(inner.get("durability", 100.0))

    # A broken outer layer should shock the inner layer (its durability drops).
    piece.apply_breakthrough_crush(0, 10.0, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var inner_after: float = float(inner.get("durability", 100.0))
    if not inner_after < inner_before:
        _fail(failures, "crush4q: inner layer should wear on breakthrough, before=%s after=%s" % [str(inner_before), str(inner_after)])
    else:
        _pass()

    # No-op: zero absorbed energy leaves the inner layer unchanged.
    var before_noop: float = float(inner.get("durability", 100.0))
    piece.apply_breakthrough_crush(0, 0.0, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var after_noop: float = float(inner.get("durability", 100.0))
    if absf(after_noop - before_noop) > 0.0001:
        _fail(failures, "crush4q: zero absorbed should be a no-op, before=%s after=%s" % [str(before_noop), str(after_noop)])
    else:
        _pass()

    # No surviving inner layer: all layers destroyed -> safe no-op, inner stays 0.
    var piece2 := ArmorPiece.create_from_definition("CUIRASS")
    (piece2.layers[0] as Dictionary)["durability"] = 0.0
    (piece2.layers[1] as Dictionary)["durability"] = 0.0
    piece2.apply_breakthrough_crush(0, 10.0, ArmorConstants.DAMAGE_TYPE_BLUNT)
    var inner2: float = float((piece2.layers[1] as Dictionary).get("durability", 0.0))
    if inner2 != 0.0:
        _fail(failures, "crush4q: no surviving inner layer should stay 0, got %s" % str(inner2))
    else:
        _pass()


## XCamp-4r: worn deflection. A worn layer's deflected transmission rises with wear (a dented
## surface no longer presents a clean bevel), so a stopped cut channels more through as shock.
## White-box: drives sharp_penetration_math with pen_rha = 0 so the deflection branch is
## isolated (proximity = 0 -> transmission equals the base value exactly).
static func _run_xcamp_4r_armor_worn_deflect(failures: PackedStringArray) -> void:
    var base_tx: float = float(ArmorConstants.LAYER_PLATE["sharp_deflect_transmission"])

    # Fresh plate: deflected transmission == base (bit-identical to pre-4r).
    var fresh: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    fresh["durability"] = 100.0
    fresh["max_durability"] = 100.0
    var fresh_res: Dictionary = ArmorPiece.sharp_penetration_math(0.0, fresh, 10.0)
    var fresh_tx: float = float(fresh_res["damage"]) / 10.0
    if absf(fresh_tx - base_tx) > 0.001:
        _fail(failures, "deflect4r: fresh transmission want %.4f got %s" % [base_tx, str(fresh_tx)])
    else:
        _pass()

    # Worn plate (50%): prot=0.5; 4s convex wear_frac = 1 - pow(0.5, exp). Transmission rises
    # above fresh (a dented bevel leaks more) but the convex curve keeps it below the old linear value.
    var worn: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    worn["durability"] = 50.0
    worn["max_durability"] = 100.0
    var worn_res: Dictionary = ArmorPiece.sharp_penetration_math(0.0, worn, 10.0)
    var worn_tx: float = float(worn_res["damage"]) / 10.0
    var penalty: float = ArmorConstants.ARMOR_WEAR_DEFLECT_PENALTY
    var curve_exp: float = ArmorConstants.ARMOR_WEAR_CURVE_EXPONENT
    var wear_frac: float = 1.0 - pow(0.5, curve_exp)
    var expected_worn: float = base_tx * (1.0 + penalty * wear_frac)
    if absf(worn_tx - expected_worn) > 0.001:
        _fail(failures, "deflect4r: worn transmission want %.4f got %s" % [expected_worn, str(worn_tx)])
    else:
        _pass()
    if not worn_tx > fresh_tx:
        _fail(failures, "deflect4r: worn transmission %s should exceed fresh %s" % [str(worn_tx), str(fresh_tx)])
    else:
        _pass()


## XCamp-4s: non-linear (cliff-edge) deflection wear. The 4r wear_frac is shaped convexly
## (1 - pow(prot, exp), exp < 1), so a worn bevel stays clean through most of a layer's life
## and the deflected transmission degrades sharply only near failure. Pins, white-box via
## pen_rha = 0 (proximity 0 -> deflected transmission equals the base value exactly):
##   (1) fresh = base exactly (bit-identical, no penalty);
##   (2) destroyed = full transmission 1.0 (a 0% layer drops to sharp_res 0, so even a
##       glancing cut penetrates — the 4i full-penetration invariant, a separate path from
##       the 4r deflection penalty);
##   (3) monotonic: more wear -> more transmitted;
##   (4) convex: the increment accelerates as the layer nears failure
##       (the 75->50 jump < the 50->25 jump), which a linear curve would not show.
static func _run_xcamp_4s_wear_curve_shape(failures: PackedStringArray) -> void:
    var base_tx: float = float(ArmorConstants.LAYER_PLATE["sharp_deflect_transmission"])
    var penalty: float = ArmorConstants.ARMOR_WEAR_DEFLECT_PENALTY

    var l100: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l100["durability"] = 100.0
    l100["max_durability"] = 100.0
    var l75: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l75["durability"] = 75.0
    l75["max_durability"] = 100.0
    var l50: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l50["durability"] = 50.0
    l50["max_durability"] = 100.0
    var l25: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l25["durability"] = 25.0
    l25["max_durability"] = 100.0
    var l0: Dictionary = ArmorConstants.LAYER_PLATE.duplicate()
    l0["durability"] = 0.0
    l0["max_durability"] = 100.0

    var tx_fresh: float = float(ArmorPiece.sharp_penetration_math(0.0, l100, 10.0)["damage"]) / 10.0
    var tx_75: float = float(ArmorPiece.sharp_penetration_math(0.0, l75, 10.0)["damage"]) / 10.0
    var tx_50: float = float(ArmorPiece.sharp_penetration_math(0.0, l50, 10.0)["damage"]) / 10.0
    var tx_25: float = float(ArmorPiece.sharp_penetration_math(0.0, l25, 10.0)["damage"]) / 10.0
    var tx_dead: float = float(ArmorPiece.sharp_penetration_math(0.0, l0, 10.0)["damage"]) / 10.0

    # (1) Fresh: no penalty -> transmission == base exactly.
    if absf(tx_fresh - base_tx) > 0.001:
        _fail(failures, "curve4s: fresh transmission want %.4f got %s" % [base_tx, str(tx_fresh)])
    else:
        _pass()

    # (2) Destroyed: a 0% layer drops to sharp_res 0, so even pen=0 fully penetrates.
    if absf(tx_dead - 1.0) > 0.001:
        _fail(failures, "curve4s: destroyed transmission want 1.0 got %s" % str(tx_dead))
    else:
        _pass()

    # (3) Monotonic: more wear -> more transmitted.
    if not (tx_fresh < tx_75 and tx_75 < tx_50 and tx_50 < tx_25 and tx_25 < tx_dead):
        _fail(
            failures,
            "curve4s: want monotonic fresh<75<50<25<dead, got %s/%s/%s/%s/%s"
            % [str(tx_fresh), str(tx_75), str(tx_50), str(tx_25), str(tx_dead)]
        )
    else:
        _pass()

    # (4) Convex: the increment accelerates as the layer nears failure. A linear curve
    # would give equal 75->50 and 50->25 jumps; the convex curve makes the lower jump larger.
    var jump_hi: float = tx_50 - tx_75
    var jump_lo: float = tx_25 - tx_50
    if not jump_lo > jump_hi:
        _fail(failures, "curve4s: want accelerating degradation (jump_lo %s > jump_hi %s)" % [str(jump_lo), str(jump_hi)])
    else:
        _pass()


## XCamp-4t: fatigue cliff — wear rate accelerates in the final 25% of a layer's life.
## Pins: (1) below threshold the cliff factor is exactly 1.0 (4m unchanged),
## (2) at full wear the cliff reaches 1 + CLIFF_MAX,
## (3) the cliff is monotonic (higher wear -> higher multiplier),
## (4) the 4m pin at 50% is preserved (total fatigue still 1.25 with default constants).
static func _run_xcamp_4t_wear_rate_cliff(failures: PackedStringArray) -> void:
    var threshold: float = ArmorConstants.ARMOR_WEAR_FATIGUE_CLIFF_THRESHOLD
    var cliff_max: float = ArmorConstants.ARMOR_WEAR_FATIGUE_CLIFF_MAX

    # (1) Below threshold: cliff is exactly 1.0 (no effect on 4m behaviour).
    var below: float = ArmorPiece._wear_fatigue_cliff(50.0, 100.0)  # wear_frac = 0.5
    if absf(below - 1.0) > 0.0001:
        _fail(failures, "cliff4t: below threshold want 1.0 got %s" % str(below))
    else:
        _pass()

    var at_threshold: float = ArmorPiece._wear_fatigue_cliff(25.0, 100.0)  # wear_frac = 0.75
    if absf(at_threshold - 1.0) > 0.0001:
        _fail(failures, "cliff4t: at threshold want 1.0 got %s" % str(at_threshold))
    else:
        _pass()

    # (2) At full wear (wear_frac = 1.0): cliff = 1.0 + CLIFF_MAX.
    var full_wear: float = ArmorPiece._wear_fatigue_cliff(0.0, 100.0)
    var expected_full: float = 1.0 + cliff_max
    if absf(full_wear - expected_full) > 0.0001:
        _fail(failures, "cliff4t: full wear want %.4f got %s" % [expected_full, str(full_wear)])
    else:
        _pass()

    # (3) Monotonic: cliff at 10% durability > cliff at 24% durability > cliff at 25% durability.
    var c_10: float = ArmorPiece._wear_fatigue_cliff(10.0, 100.0)  # wear_frac 0.90
    var c_24: float = ArmorPiece._wear_fatigue_cliff(24.0, 100.0)  # wear_frac 0.76
    var c_25: float = ArmorPiece._wear_fatigue_cliff(25.0, 100.0)  # wear_frac 0.75 (at threshold)
    if not (c_10 > c_24 and c_24 > c_25):
        _fail(failures, "cliff4t: want monotonic 10%%>24%%>25%%, got %s/%s/%s" % [str(c_10), str(c_24), str(c_25)])
    else:
        _pass()

    # (4) 4m pin preserved: at 50% durability the total fatigue multiplier is still 1.25
    #     (base fatigue 1.25 * cliff 1.0 = 1.25, since 0.5 <= threshold).
    var base_fatigue: float = ArmorPiece._wear_fatigue_multiplier(50.0, 100.0)
    var cliff_at_50: float = ArmorPiece._wear_fatigue_cliff(50.0, 100.0)
    var total: float = base_fatigue * cliff_at_50
    if absf(total - 1.25) > 0.001:
        _fail(failures, "cliff4t: 4m pin broken, total fatigue at 50%% want 1.25 got %s" % str(total))
    else:
        _pass()


## XCamp-4u: out-of-math consumers (AI doctrine tier, gap-finding, mace bonus) now see the same
## wear-scaled RHA the damage path uses, not the base design value. Pins, white-box on the
## CUIRASS piece (outer = plate 3.5mm / rigidity 1.0, inner = cloth 0.9mm):
##   (1) fresh armor effective == base (bit-identical, no wear);
##   (2) a worn outer layer's effective RHA drops below base and matches the 4k formula
##       (base * pow(prot, 1 - rigidity*shield), prot=0.5 -> base * pow(0.5, 0.4));
##   (3) a destroyed outer layer falls through to the next surviving layer's effective RHA;
##   (4) monotonic: more wear -> lower effective RHA (fresh > 75 > 50 > 25).
static func _run_xcamp_4u_wear_aware_rha(failures: PackedStringArray) -> void:
    var base_plate: float = float(ArmorConstants.LAYER_PLATE["sharp_resistance_rha_mm"])  # 3.5
    var base_cloth: float = float(ArmorConstants.LAYER_CLOTH["sharp_resistance_rha_mm"])  # 0.9
    var shield: float = ArmorConstants.ARMOR_WEAR_RIGIDITY_SHIELD

    # (1) Fresh cuirass (outer = plate): effective == base, bit-identical.
    var fresh_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if fresh_piece == null:
        _fail(failures, "wearrha4u: could not build CUIRASS")
        return
    var fresh_eff: float = fresh_piece.get_outer_layer_effective_rha_mm()
    if absf(fresh_eff - base_plate) > 0.001:
        _fail(failures, "wearrha4u: fresh effective want %.3f got %s" % [base_plate, str(fresh_eff)])
    else:
        _pass()

    # (2) Worn outer plate (50% durability): effective < base and matches the 4k formula.
    var worn_piece: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (worn_piece.layers[0] as Dictionary)["durability"] = 50.0
    var worn_eff: float = worn_piece.get_outer_layer_effective_rha_mm()
    var exp: float = clampf(1.0 - 1.0 * shield, 0.1, 1.0)  # plate rigidity 1.0 -> 0.4
    var expected_worn: float = base_plate * pow(0.5, exp)
    if absf(worn_eff - expected_worn) > 0.001:
        _fail(failures, "wearrha4u: worn 50%% effective want %.4f got %s" % [expected_worn, str(worn_eff)])
    else:
        _pass()
    if not worn_eff < fresh_eff:
        _fail(failures, "wearrha4u: worn %s should be < fresh %s" % [str(worn_eff), str(fresh_eff)])
    else:
        _pass()

    # (3) Destroyed outer plate: fall through to inner cloth layer's effective RHA.
    var dead_outer: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (dead_outer.layers[0] as Dictionary)["durability"] = 0.0
    var cloth_eff: float = dead_outer.get_outer_layer_effective_rha_mm()
    if absf(cloth_eff - base_cloth) > 0.001:
        _fail(failures, "wearrha4u: destroyed outer want inner cloth %.3f got %s" % [base_cloth, str(cloth_eff)])
    else:
        _pass()

    # (4) Monotonic: effective RHA strictly decreases as durability falls.
    var m75: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (m75.layers[0] as Dictionary)["durability"] = 75.0
    var m25: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    (m25.layers[0] as Dictionary)["durability"] = 25.0
    var eff_75: float = m75.get_outer_layer_effective_rha_mm()
    var eff_25: float = m25.get_outer_layer_effective_rha_mm()
    if not (fresh_eff > eff_75 and eff_75 > worn_eff and worn_eff > eff_25):
        _fail(
            failures,
            "wearrha4u: want monotonic %s>%s>%s>%s" % [str(fresh_eff), str(eff_75), str(worn_eff), str(eff_25)]
        )
    else:
        _pass()
