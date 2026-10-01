class_name CompanyChecksArmorCommerceTests

extends CompanyChecksCore

## XCamp-4d-4n armor commerce + durability checks: recruit kit, sell/unequip,
## armor tiers, condition and persist/repair, wear protection, encumbrance,
## material + blunt material wear and wear fatigue.


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
        _fail(
            failures,
            "recruit_kit: Trained hire weapon want %s got '%s'" % [PlayerCompanionSetup.RECRUIT_KIT_WEAPON, tr_weapon]
        )
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
        _fail(
            failures,
            "recruit_kit: Seasoned hire weapon want %s got '%s'" % [PlayerCompanionSetup.RECRUIT_KIT_WEAPON, se_weapon]
        )
    else:
        _pass()
    var se_armor: Dictionary = EncounterSpawner.armor_ids_from_entity(se_ent) if se_ent != null else {}
    var got_head: String = str(se_armor.get(PlayerCompanionSetup.RECRUIT_KIT_ARMOR_PART, "")).strip_edges()
    if got_head != PlayerCompanionSetup.RECRUIT_KIT_ARMOR_ID:
        _fail(
            failures,
            (
                "recruit_kit: Seasoned hire %s armor want %s got '%s'"
                % [PlayerCompanionSetup.RECRUIT_KIT_ARMOR_PART, PlayerCompanionSetup.RECRUIT_KIT_ARMOR_ID, got_head]
            )
        )
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
        _fail(
            failures,
            "sell: selling with no weapon should refund 0, got %d" % CompanyGear.sell_equipped_weapon(world, fighter)
        )
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
        _fail(
            failures, "sell: gold after weapon sell want %d got %d" % [gold_before + 75, CompanyState.get_gold(world)]
        )
    else:
        _pass()
    if CompanyGear.equipped_weapon_id(fighter) != "":
        _fail(
            failures, "sell: weapon should be unequipped after sell, got '%s'" % CompanyGear.equipped_weapon_id(fighter)
        )
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
        _fail(
            failures,
            "sell: gold after armor sell want %d got %d" % [gold_before_armor + 60, CompanyState.get_gold(world)]
        )
    else:
        _pass()
    if CompanyGear.equipped_armor_piece_id(fighter, "head") != "":
        _fail(
            failures,
            (
                "sell: head armor should be unequipped after sell, got '%s'"
                % CompanyGear.equipped_armor_piece_id(fighter, "head")
            )
        )
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
        _fail(
            failures,
            "tiers: right_arm ladder want 4 entries got %d" % CompanyGear.armor_tiers_for_part("right_arm").size()
        )
    else:
        _pass()
    if CompanyGear.armor_tiers_for_part("left_leg").size() != 4:
        _fail(
            failures,
            "tiers: left_leg ladder want 4 entries got %d" % CompanyGear.armor_tiers_for_part("left_leg").size()
        )
    else:
        _pass()

    # best_armor_for_part still returns the top (plate) tier.
    if CompanyGear.best_armor_for_part("chest") != "CUIRASS":
        _fail(failures, "tiers: best for chest want CUIRASS got '%s'" % CompanyGear.best_armor_for_part("chest"))
    else:
        _pass()

    # Tier indices: -1 for unknown piece, increasing up the ladder.
    if CompanyGear.armor_tier_index("chest", "GAMBESON") != 0:
        _fail(
            failures, "tiers: GAMBESON index on chest want 0 got %d" % CompanyGear.armor_tier_index("chest", "GAMBESON")
        )
    else:
        _pass()
    if CompanyGear.armor_tier_index("chest", "CUIRASS") != 3:
        _fail(
            failures, "tiers: CUIRASS index on chest want 3 got %d" % CompanyGear.armor_tier_index("chest", "CUIRASS")
        )
    else:
        _pass()
    if CompanyGear.armor_tier_index("head", "CUIRASS") != -1:
        _fail(
            failures,
            "tiers: CUIRASS is not a head tier, want index -1 got %d" % CompanyGear.armor_tier_index("head", "CUIRASS")
        )
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
        _fail(
            failures,
            "tiers: head should wear LEATHER_CAP, got '%s'" % CompanyGear.equipped_armor_piece_id(fighter, "head")
        )
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
                _fail(
                    failures,
                    (
                        "persist: inner cloth layer should stay 100.0, got %s"
                        % str((f_cuirass.layers[1] as Dictionary).get("durability", ""))
                    )
                )
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
        _fail(
            failures,
            "wear4i: worn plate sharp damage should exceed fresh, got %s <= %s" % [str(sharp_worn), str(sharp_fresh)]
        )
    else:
        _pass()
    if absf(sharp_dead - incoming) > 0.0001:
        _fail(failures, "wear4i: destroyed plate sharp damage should equal incoming, got %s" % str(sharp_dead))
    else:
        _pass()

    # --- Blunt: no momentum (uses base_tx * (1—cushion)) ---
    var blunt_fresh: float = ArmorPiece.blunt_transmission_math(incoming, fresh, -1.0, -1.0)
    var blunt_worn: float = ArmorPiece.blunt_transmission_math(incoming, worn, -1.0, -1.0)
    var blunt_dead: float = ArmorPiece.blunt_transmission_math(incoming, dead, -1.0, -1.0)
    if absf(blunt_fresh - 3.825) > 0.01:
        _fail(failures, "wear4i: fresh plate blunt damage want ~3.825 got %s" % str(blunt_fresh))
    else:
        _pass()
    if blunt_worn <= blunt_fresh:
        _fail(
            failures,
            "wear4i: worn plate blunt damage should exceed fresh, got %s <= %s" % [str(blunt_worn), str(blunt_fresh)]
        )
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
        _fail(
            failures,
            (
                "wear4i: worn cuirass should transmit more through apply_damage, got %s <= %s"
                % [str(wd["damage"]), str(fd["damage"])]
            )
        )
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
        _fail(
            failures, "encumbrance: full plate should slow dodge, got %s vs bare %s" % [str(plate_mod), str(bare_mod)]
        )
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
        _fail(
            failures,
            (
                "encumbrance: adding a cuirass should not increase dodge speed, got %s > %s"
                % [str(light_plus_mod), str(light_mod)]
            )
        )
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
        _fail(
            failures,
            (
                "wear4k: worn plate should protect better vs cuts than worn cloth, got %s >= %s"
                % [str(d_plate), str(d_cloth)]
            )
        )
    else:
        _pass()

    # (2) Threshold degrades: a cut fresh cloth stops (deflected) now penetrates a 50% cloth layer.
    var fresh_deflected: bool = bool(ArmorPiece.sharp_penetration_math(pen, fresh_cloth, incoming)["deflected"])
    var worn_deflected: bool = bool(ArmorPiece.sharp_penetration_math(pen, worn_cloth, incoming)["deflected"])
    if not fresh_deflected or worn_deflected:
        _fail(
            failures,
            (
                "wear4k: want fresh cloth to deflect (%s) and worn cloth to be penetrated (%s)"
                % [str(fresh_deflected), str(worn_deflected)]
            )
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
    var fresh: Dictionary = {
        "sharp_resistance_rha_mm": 1.0,
        "blunt_transmission": 0.55,
        "blunt_cushion": 0.5,
        "rigidity": 0.0,
        "durability": 100.0,
        "max_durability": 100.0
    }
    var worn_flex: Dictionary = {
        "sharp_resistance_rha_mm": 1.0,
        "blunt_transmission": 0.55,
        "blunt_cushion": 0.5,
        "rigidity": 0.0,
        "durability": 50.0,
        "max_durability": 100.0
    }
    var worn_rigid: Dictionary = {
        "sharp_resistance_rha_mm": 1.0,
        "blunt_transmission": 0.55,
        "blunt_cushion": 0.5,
        "rigidity": 1.0,
        "durability": 50.0,
        "max_durability": 100.0
    }
    var dead: Dictionary = {
        "sharp_resistance_rha_mm": 1.0,
        "blunt_transmission": 0.55,
        "blunt_cushion": 0.5,
        "rigidity": 0.0,
        "durability": 0.0,
        "max_durability": 100.0
    }

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
            (
                "wear4l: want fresh < worn_rigid < worn_flexible, got %s / %s / %s"
                % [str(f_fresh), str(f_rigid), str(f_flex)]
            )
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
