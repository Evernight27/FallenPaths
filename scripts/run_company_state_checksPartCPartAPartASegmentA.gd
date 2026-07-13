class_name CompanyStateChecksHarnessPartCPartAPartASegmentA
extends RefCounted

## Headless Camp-1 economy loop + Camp-2 spot checks + XCamp-3.x + P2 persistence roundtrip.
## Run: .\scripts\run_company_state_checks.ps1
## Labels: Camp-1.x / XCamp-3.x in failure messages map to SHIP_PLAN S Camp-1 / EXPANSION_PLAN Exp-3.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `scripts/README.md`).
## P2 rows use `CampaignPersistence.begin_harness_isolated_save()`  -  production `user://fallen_paths_slot0.json`
## untouched.
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const CampaignWorldScript := preload("res://scripts/_harness_campaign_world.gd")
const HARNESS_NAME := "CompanyStateChecks"
static var _test_count: int = 0


static func _run_camp_2_bridge_spot_checkssegmenta(failures: PackedStringArray) -> void:
    if CompanyState.read_stub_map_bleed_policy() != "warn_eta":
        _fail(failures, "Camp-2.1: map_bleed policy want warn_eta")
    else:
        _pass()
    var world: Node2D = _make_world(1)
    if MapBleedPolicy.effective_policy(world) != MapBleedPolicy.POLICY_BLOCK:
        _fail(failures, "Camp-2.1: tutorial incomplete should block")
    else:
        _pass()
    world.set_meta(CompanyState.WORLD_META_MAP_BLEED_MULT, 0.25)
    CampaignEncounterBridge.clear_transient_combat_meta(world)
    if world.has_meta(CompanyState.WORLD_META_MAP_BLEED_MULT):
        _fail(failures, "Camp-2.1: map_bleed_mult should clear after combat")
    else:
        _pass()
    CompanyState.mark_tutorial_completed(world)
    if MapBleedPolicy.effective_policy(world) != MapBleedPolicy.POLICY_WARN_ETA:
        _fail(failures, "Camp-2.1: post-tutorial map bleed policy want warn_eta")
    else:
        _pass()
    world.set_meta("active_contract", {"tutorial": true, "pay_gold": 0})
    if CompanyState.apply_contract_victory_pay(world) != 0:
        _fail(failures, "Camp-3.1: tutorial pay want 0")
    else:
        _pass()
    var world_paid: Node2D = _make_world(1)
    CompanyState.set_active_contract(
        world_paid, {"contract_title": "Escort", "pay_gold": 120, "contract_type": "escort"}
    )
    if CompanyState.apply_contract_victory_pay(world_paid) != 120:
        _fail(failures, "Camp-2.1: paid contract pay want 120")
    else:
        _pass()
    if not CompanyState.is_tutorial_completed(world_paid):
        _fail(failures, "Camp-2.1: paid contract win should lift map bleed block")
    else:
        _pass()
    if MapBleedPolicy.effective_policy(world_paid) != MapBleedPolicy.POLICY_WARN_ETA:
        _fail(failures, "Camp-2.1: after paid win map bleed policy want warn_eta")
    else:
        _pass()
    world.free()
    world_paid.free()
    var world_win: Node2D = _make_world(1)
    if CompanyState.is_tutorial_completed(world_win):
        _fail(failures, "Camp-2.1: fresh world should start pre-first-win")
    else:
        _pass()
    CampaignEncounterBridge.on_return_from_combat(world_win, "player")
    if not CompanyState.is_tutorial_completed(world_win):
        _fail(failures, "Camp-2.1: on_return_from_combat(player) should lift map bleed block")
    else:
        _pass()
    if MapBleedPolicy.effective_policy(world_win) != MapBleedPolicy.POLICY_WARN_ETA:
        _fail(failures, "Camp-2.1: after combat return policy want warn_eta")
    else:
        _pass()
    world_win.free()

    var snap: Dictionary = {"name": "T", "blood_volume": 55.0, "total_bleeding_rate": 1.2}
    var entry: Dictionary = CampaignEncounterBridge.member_battle_summary_entry(snap, null)
    if int(entry.get("worst_atls_band", 0)) < 2:
        _fail(failures, "Camp-2.2: worst_atls_band for 55%% blood")
    else:
        _pass()
    var bleed_ent: Node = _harness_core_entity()
    bleed_ent.apply_species()
    bleed_ent.wounds["left_arm"] = [
        {"current_bleeding_rate": 1.0, "is_arterial": false, "severity": "moderate"},
    ]
    var bleed_snap: Dictionary = {"name": "Bleeder", "blood_volume": 80.0, "total_bleeding_rate": 1.0}
    var bleed_entry: Dictionary = CampaignEncounterBridge.member_battle_summary_entry(bleed_snap, bleed_ent)
    var snap_entry: Dictionary = bleed_entry.get("snapshot", {})
    if snap_entry is Dictionary and (snap_entry.get("untreated_parts", []) as PackedStringArray).size() > 0:
        _pass()
    else:
        _fail(failures, "Camp-2.2: battle snapshot should carry untreated_parts when present")
    _free_harness_core_entity(bleed_ent)

    var entity: Node = _harness_core_entity()
    entity.intelligence = 100
    entity._set_campaign_supply_factor(0.5)
    if absf(entity._get_medical_effectiveness() - 0.5) > 0.02:
        _fail(failures, "Camp-2.3: supply factor at 0 med floor")
    else:
        _pass()
    _free_harness_core_entity(entity)

    var world_med: Node2D = _make_world(1)
    CompanyState.set_medical_supplies(world_med, 0)
    CompanyState.wire_party_medical_supply(world_med)
    var hint: String = CompanyState.format_battle_medical_supply_hint(world_med)
    if not hint.contains("efficacy"):
        _fail(failures, "Camp-2.3: depleted med should produce supply hint")
    else:
        _pass()
    CompanyState.set_medical_supplies(world_med, 1)
    CompanyState.wire_party_medical_supply(world_med)
    var hint_one: String = CompanyState.format_battle_medical_supply_hint(world_med)
    if not hint_one.contains("One med left"):
        _fail(failures, "Camp-2.3: 1 med left should warn about next spend got '%s'" % hint_one)
    else:
        _pass()
    CompanyState.set_medical_supplies(world_med, 3)
    CompanyState.wire_party_medical_supply(world_med)
    var hint_tight: String = CompanyState.format_battle_medical_supply_hint(world_med)
    if not hint_tight.contains("tight"):
        _fail(failures, "Camp-2.3: low med pool should warn about map dressings got '%s'" % hint_tight)
    else:
        _pass()
    world_med.free()

    var pre_stab: Node = _harness_core_entity()
    pre_stab.apply_species()
    pre_stab.wounds["chest"] = [
        {"current_bleeding_rate": 2.0, "is_arterial": true, "severity": "severe"},
    ]
    if EntityMedical._can_apply_stabilize(pre_stab, "chest"):
        _fail(failures, "Camp-2.5: stabilize should require pressure first")
    else:
        _pass()
    _free_harness_core_entity(pre_stab)

    seed(90210)
    var stab_ent: Node = _harness_core_entity()
    stab_ent.apply_species()
    stab_ent.wounds["chest"] = [{"current_bleeding_rate": 0.8, "is_arterial": true, "severity": "severe"}]
    if not stab_ent.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.5: setup pressure on chest")
    else:
        _pass()
    if not stab_ent._can_apply_stabilize("chest"):
        _fail(failures, "Camp-2.5: should offer stabilize under pressure with bleed")
    else:
        _pass()
    if not stab_ent._apply_stabilize("chest", 2.0):
        _fail(failures, "Camp-2.5: apply_stabilize should succeed")
    else:
        _pass()
    if bool(stab_ent.bandaged_parts.get("chest", false)):
        _fail(failures, "Camp-2.5: stabilize must not set bandaged_parts")
    else:
        _pass()
    _free_harness_core_entity(stab_ent)

    seed(90210)
    var press_ent: Node = _harness_core_entity()
    press_ent.apply_species()
    press_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.6, "severity": "moderate"},
    ]
    if not press_ent.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.5: setup pressure for bandage failure retain")
    else:
        _pass()
    if not EntityMedical.has_direct_pressure_on_part(press_ent, "chest"):
        _fail(failures, "Camp-2.5: want pressure held before bandage attempt")
    else:
        _pass()
    if press_ent._apply_bandage("chest", 0.0):
        _fail(failures, "Camp-2.5: zero-eff bandage should fail for pressure-retain test")
    else:
        _pass()
    if not EntityMedical.has_direct_pressure_on_part(press_ent, "chest"):
        _fail(failures, "Camp-2.5: failed bandage must retain direct pressure for retry")
    else:
        _pass()
    _free_harness_core_entity(press_ent)

    seed(90210)
    var pack_ent: Node = _harness_core_entity()
    pack_ent.apply_species()
    pack_ent.linen_strips_remaining = 4
    pack_ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    if not pack_ent.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.5: setup pressure for packing failure retain")
    else:
        _pass()
    if not pack_ent._apply_packing("chest", 0.0):
        _pass()
    else:
        _fail(failures, "Camp-2.5: zero-eff packing should fail for pressure-retain test")
    if not EntityMedical.has_direct_pressure_on_part(pack_ent, "chest"):
        _fail(failures, "Camp-2.5: failed packing must retain direct pressure for retry")
    else:
        _pass()
    _free_harness_core_entity(pack_ent)

    var pain_ent: Node = _harness_core_entity()
    pain_ent.apply_species()
    if not pain_ent._add_campaign_affliction({"id": "old_wound_ache", "pain_mult": 1.1, "stamina_mult": 1.0}):
        _fail(failures, "Camp-2.4: pain affliction add")
    else:
        _pass()
    if absf(pain_ent._get_campaign_pain_mult() - 1.1) > 0.02:
        _fail(failures, "Camp-2.4: pain_mult want 1.1 got %.3f" % pain_ent._get_campaign_pain_mult())
    else:
        _pass()
    var aff_snap: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "Scar", "node_ref": pain_ent})
    if not str(aff_snap.get("affliction_effects", "")).contains("Pain"):
        _fail(failures, "Camp-2.4: snapshot should expose affliction effect line")
    else:
        _pass()
    _free_harness_core_entity(pain_ent)

    var day_world: Node2D = _make_world(1)
    var day_line: String = CompanyState.format_day_hud_line(day_world)
    if not day_line.contains("steps"):
        _fail(failures, "Camp-1.2: hybrid HUD should show step progress")
    else:
        _pass()
    _release_harness_world(day_world)

    var esc_lbl: String = ContractSpawner.format_marker_label(ContractSpawner.CONTRACT_TEMPLATES[1])
    if not esc_lbl.contains("bleed"):
        _fail(failures, "Camp-1.4: contract marker should show map bleed mult when <1")
    else:
        _pass()

    seed(90210)
    var field_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_medical_supplies(field_world, 2)
    var pm_f: Node = field_world.get_meta("party_manager")
    var live: Node = _add_living_entity_member(pm_f, "Fielder")
    live.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    live.apply_direct_pressure("chest")
    var member_d: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "Fielder", "node_ref": live})
    if not MapFieldCare.can_offer_field_stabilize(field_world, member_d):
        _fail(failures, "Camp-2.1: field stabilize should be offered under pressure")
    else:
        _pass()
    seed(90210)
    if not MapFieldCare.try_field_stabilize(field_world, member_d):
        _fail(failures, "Camp-2.1: field stabilize should succeed")
    else:
        _pass()
    if bool(live.bandaged_parts.get("chest", false)):
        _fail(failures, "Camp-2.1: field stabilize must not set bandaged_parts (hemostatic hold only)")
    else:
        _pass()
    if CompanyState.camp_heal_ready(field_world, true):
        _fail(failures, "Camp-2.1: camp rest must stay gated after stabilize until bandage dresses wound")
    else:
        _pass()
    if not MapFieldCare.can_offer_field_bandage(field_world, member_d):
        _fail(failures, "Camp-2.1: field bandage should remain offered after stabilize while pressure held")
    else:
        _pass()
    _release_harness_world(field_world)

    seed(90210)
    var dress_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_medical_supplies(dress_world, 2)
    var pm_d: Node = dress_world.get_meta("party_manager")
    var dresser: Node = _add_living_entity_member(pm_d, "Dresser")
    dresser.wounds["chest"] = [
        {"current_bleeding_rate": 0.6, "severity": "moderate"},
    ]
    var dress_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "Dresser", "node_ref": dresser})
    if MapFieldCare.can_offer_field_bandage(dress_world, dress_member):
        _fail(failures, "Camp-2.1: field bandage should require direct pressure first")
    else:
        _pass()
    if not dresser.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.1: setup pressure on chest for field bandage")
    else:
        _pass()
    dress_member = PartyMemberSnapshot.snapshot_from_member({"name": "Dresser", "node_ref": dresser})
    if not MapFieldCare.can_offer_field_bandage(dress_world, dress_member):
        _fail(failures, "Camp-2.1: field bandage should be offered on untreated chest")
    else:
        _pass()
    var bandaged_ok: bool = false
    for attempt in range(24):
        CompanyState.set_medical_supplies(dress_world, 2)
        dresser.bandaged_parts.erase("chest")
        if dresser.self_direct_pressure_part != "chest":
            dresser.apply_direct_pressure("chest")
        seed(90210 + attempt)
        if MapFieldCare.try_field_bandage(dress_world, dress_member):
            bandaged_ok = true
            break
    if not bandaged_ok:
        _fail(failures, "Camp-2.1: field bandage should eventually dress untreated chest")
    else:
        _pass()
    if CompanyState.camp_heal_ready(dress_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: camp_heal_ready should be true after field bandage dresses wound")
    var day_before_rest: int = CompanyState.get_day_index(dress_world)
    if not CompanyState.try_camp_heal(dress_world, true):
        _fail(failures, "Camp-2.1: camp rest should succeed after pressure + field bandage")
    else:
        _pass()
    if CompanyState.get_day_index(dress_world) != day_before_rest + 1:
        _fail(
            failures,
            (
                "Camp-2.1: camp rest after field care should advance day %d -> %d"
                % [day_before_rest, CompanyState.get_day_index(dress_world)]
            )
        )
    else:
        _pass()
    _release_harness_world(dress_world)

    var ally_pressure_world: Node2D = _make_world(1, 0, true)
    var leader_ent: Node = _harness_core_entity()
    leader_ent.name = "Character"
    ally_pressure_world.add_child(leader_ent)
    var pm_ap: Node = ally_pressure_world.get_meta("party_manager")
    var patient_ent: Node = _harness_core_entity()
    patient_ent.wounds["right_arm"] = [
        {"current_bleeding_rate": 0.4, "severity": "moderate"},
    ]
    pm_ap.add_child(patient_ent)
    pm_ap.members.append({"name": "Patient", "node_ref": patient_ent, "company_mood": 50.0})
    var patient_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "Patient", "node_ref": patient_ent}
    )
    var script_err_before: int = OperationalLog.harness_script_error_count()
    if not MapFieldCare.try_field_pressure(ally_pressure_world, patient_member):
        _fail(failures, "Camp-2.1: field pressure with leader performer should succeed on ally arm wound")
    else:
        _pass()
    if not EntityMedical.has_direct_pressure_on_part(patient_ent, "right_arm"):
        _fail(failures, "Camp-2.1: ally field pressure should hold compression on right_arm")
    else:
        _pass()
    if OperationalLog.harness_script_error_count() > script_err_before:
        _fail(
            failures,
            "Camp-2.1: field pressure with leader performer must not SCRIPT_ERROR (can_apply_direct_pressure_from_ally)"
        )
    else:
        _pass()
    _release_harness_world(ally_pressure_world)

    var treat_next_world: Node2D = _make_world(1, 0, true)
    var treat_leader: Node = _harness_core_entity()
    treat_leader.name = "Character"
    treat_next_world.add_child(treat_leader)
    CompanyState.set_medical_supplies(treat_next_world, 3)
    var pm_tn: Node = treat_next_world.get_meta("party_manager")
    var bleed_bro: Node = _add_living_entity_member(pm_tn, "BleedBro")
    bleed_bro.wounds["chest"] = [{"current_bleeding_rate": 0.6, "severity": "moderate"}]
    var ok_bro: Node = _add_living_entity_member(pm_tn, "OkBro")
    var roster: Array = []
    for raw in pm_tn.members:
        if raw is Dictionary:
            roster.append(PartyMemberSnapshot.snapshot_from_member(raw as Dictionary))
    if not MapFieldCare.try_treat_next_wound(treat_next_world, roster):
        _fail(failures, "Camp-2.1: treat next wound should apply field pressure on highest threat")
    else:
        _pass()
    if not EntityMedical.has_direct_pressure_on_part(bleed_bro, "chest"):
        _fail(failures, "Camp-2.1: treat next wound should pressure highest-threat part first")
    else:
        _pass()
    var treat_next_dressed: bool = false
    for attempt in range(48):
        CompanyState.set_medical_supplies(treat_next_world, 3)
        roster = []
        for raw in pm_tn.members:
            if raw is Dictionary:
                roster.append(PartyMemberSnapshot.snapshot_from_member(raw as Dictionary))
        seed(90400 + attempt)
        # MARCH chain: pressure -> stabilize -> pack/bandage; RNG may fail one tick.
        MapFieldCare.try_treat_next_wound(treat_next_world, roster)
        if EntityWounds.part_has_definitive_hemostasis(bleed_bro, "chest"):
            treat_next_dressed = true
            break
    if not treat_next_dressed:
        _fail(failures, "Camp-2.1: treat next wound should eventually dress chest after pressure and stabilize")
    else:
        _pass()
    if not CompanyState.camp_heal_ready(treat_next_world, true):
        _fail(failures, "Camp-2.1: camp rest should unlock after treat-next chain dresses wound")
    else:
        _pass()
    _release_harness_world(treat_next_world)

    var split_world: Node2D = _make_world(2, 0, true)
    var split_leader: Node = _harness_core_entity()
    split_leader.name = "Character"
    split_world.add_child(split_leader)
    CompanyState.set_medical_supplies(split_world, 4)
    var pm_split: Node = split_world.get_meta("party_manager")
    var split_bro: Node = _add_living_entity_member(pm_split, "SplitDress")
    split_bro.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    split_bro.wounds["left_leg"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var split_roster: Array = []
    var split_member: Dictionary = {}
    for raw in pm_split.members:
        if raw is Dictionary:
            var split_snap: Dictionary = PartyMemberSnapshot.snapshot_from_member(raw as Dictionary)
            split_roster.append(split_snap)
            if str(split_snap.get("name", "")) == "SplitDress":
                split_member = split_snap
    if split_member.is_empty():
        _fail(failures, "Camp-2.1: split dress harness member missing")
    else:
        _pass()
    if not MapFieldCare.can_offer_field_bandage(split_world, split_member):
        _fail(failures, "Camp-2.1: treat-next should offer bandage on clotted part while another bleeds")
    else:
        _pass()
    if not MapFieldCare.can_treat_next_wound(split_world, split_roster):
        _fail(failures, "Camp-2.1: treat-next should stay available when one part needs pressure and another can dress")
    else:
        _pass()
    if not MapFieldCare.try_treat_next_wound(split_world, split_roster):
        _fail(failures, "Camp-2.1: treat-next should pressure bleeding part before dressing clotted part")
    else:
        _pass()
    if not EntityMedical.has_direct_pressure_on_part(split_bro, "chest"):
        _fail(failures, "Camp-2.1: treat-next multi-part should hold pressure on bleeding chest first")
    else:
        _pass()
    split_member = PartyMemberSnapshot.snapshot_from_member({"name": "SplitDress", "node_ref": split_bro})
    var next_after_pressure: String = MapFieldCare.format_next_field_care_action(split_world, split_member)
    var next_is_dress_step: bool = (
        next_after_pressure.contains("Field stabilize")
        or next_after_pressure.contains("Field bandage")
        or next_after_pressure.contains("Field pack")
    )
    if not next_is_dress_step or next_after_pressure.contains("Field pressure"):
        _fail(
            failures,
            "Camp-2.1: next action after chest pressure should advance dressing got '%s'" % next_after_pressure
        )
    else:
        _pass()
    var treat_next_lbl: String = MapFieldCare.format_treat_next_wound_button_label(split_world, split_roster)
    if not treat_next_lbl.contains("Treat next") or not treat_next_lbl.contains("SplitDress"):
        _fail(failures, "Camp-2.1: treat-next button should name brother and step got '%s'" % treat_next_lbl)
    else:
        _pass()
    _release_harness_world(split_world)

    var retry_world: Node2D = _make_world(1)
    var pm_retry: Node = retry_world.get_meta("party_manager")
    var retry_ent: Node = _add_living_entity_member(pm_retry, "RetryBand")
    retry_ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    retry_ent.apply_direct_pressure("chest")
    var retry_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "RetryBand", "node_ref": retry_ent}
    )
    var saw_fail_refund: bool = false
    for attempt in range(48):
        CompanyState.set_medical_supplies(retry_world, 2)
        retry_ent.bandaged_parts.erase("chest")
        if retry_ent.self_direct_pressure_part != "chest":
            retry_ent.apply_direct_pressure("chest")
        retry_member = PartyMemberSnapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
        seed(88000 + attempt)
        var med_before: int = CompanyState.get_medical_supplies(retry_world)
        if MapFieldCare.try_field_bandage(retry_world, retry_member):
            continue
        if (
            CompanyState.get_medical_supplies(retry_world) == med_before
            and not bool(retry_ent.bandaged_parts.get("chest", false))
            and EntityMedical.has_direct_pressure_on_part(retry_ent, "chest")
        ):
            saw_fail_refund = true
            break
    if not saw_fail_refund:
        _fail(failures, "Camp-2.1: field bandage failure should refund med, keep wound undressed, retain pressure")
    else:
        _pass()
    OperationalLog.begin_play_session("headless://field_bandage_fail_log", "", false, false)
    OperationalLog.set_capture_enabled(true)
    CompanyState.set_medical_supplies(retry_world, 2)
    retry_ent.bandaged_parts.erase("chest")
    retry_ent.apply_direct_pressure("chest")
    retry_member = PartyMemberSnapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
    for attempt in range(48):
        seed(88100 + attempt)
        if not MapFieldCare.try_field_bandage(retry_world, retry_member):
            break
    var fail_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("field_care bandage failed") and s.contains("parts_left="):
            fail_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not fail_logged:
        _fail(failures, "Camp-2.1: bandage failure log should include parts_left")
    else:
        _pass()
    var retry_tree_root: Node = _harness_root()
    if retry_tree_root != null and retry_world.get_parent() == null:
        retry_tree_root.add_child(retry_world)
    var retry_menu: PopupPanel = _new_party_menu()
    retry_world.add_child(retry_menu)
    var retry_roster_ui: Array = []
    for raw in pm_retry.members:
        if raw is Dictionary:
            retry_roster_ui.append(PartyMemberSnapshot.snapshot_from_member(raw as Dictionary))
    retry_menu.show_party(retry_world, retry_roster_ui)
    var fail_notice: bool = false
    for attempt in range(48):
        seed(88200 + attempt)
        CompanyState.set_medical_supplies(retry_world, 2)
        retry_ent.bandaged_parts.erase("chest")
        if retry_ent.self_direct_pressure_part != "chest":
            retry_ent.apply_direct_pressure("chest")
        retry_member = PartyMemberSnapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
        var fail_step := func() -> bool: return MapFieldCare.try_field_bandage(retry_world, retry_member)
        retry_menu._run_field_care_step(fail_step, "bandage")
        var ui_blob: String = " ".join(_collect_control_label_texts(retry_menu))
        if ui_blob.contains("retry") or ui_blob.contains("keep pressure"):
            fail_notice = true
            break
    if not fail_notice:
        _fail(failures, "Camp-2.1: Party menu should surface bandage failure retry notice")
    else:
        _pass()
    var retry_hint: String = MapFieldCare.format_field_care_retry_hint("bandage")
    if not retry_hint.contains("retry"):
        _fail(failures, "Camp-2.1: field care retry hint should mention retry got '%s'" % retry_hint)
    else:
        _pass()
    retry_menu.queue_free()
    _release_harness_world(retry_world)

    var clot_world: Node2D = _make_world(1)
    var pm_clot: Node = clot_world.get_meta("party_manager")
    var clot_ent: Node = _add_living_entity_member(pm_clot, "ClotDress")
    clot_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var clot_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "ClotDress", "node_ref": clot_ent})
    if MapFieldCare.can_offer_field_bandage(clot_world, clot_member):
        _pass()
    else:
        _fail(failures, "Camp-2.1: field bandage should be offered on clotted untreated part without pressure")
    if MapFieldCare.field_bandage_needs_pressure_first(clot_member):
        _fail(failures, "Camp-2.1: clotted part should not block bandage waiting on pressure")
    else:
        _pass()
    var clot_dressed: bool = false
    for attempt in range(48):
        CompanyState.set_medical_supplies(clot_world, 2)
        clot_ent.bandaged_parts.erase("chest")
        clot_member = PartyMemberSnapshot.snapshot_from_member({"name": "ClotDress", "node_ref": clot_ent})
        seed(99000 + attempt)
        if MapFieldCare.try_field_bandage(clot_world, clot_member):
            clot_dressed = true
            break
    if not clot_dressed:
        _fail(failures, "Camp-2.1: field bandage should eventually dress clotted untreated chest")
    else:
        _pass()
    if CompanyState.camp_heal_ready(clot_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: clotted field bandage should dress part for camp rest")
    _release_harness_world(clot_world)

    var zero_med_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_medical_supplies(zero_med_world, 0)
    var pm_zero: Node = zero_med_world.get_meta("party_manager")
    var zero_ent: Node = _add_living_entity_member(pm_zero, "ZeroMedDress")
    zero_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var zero_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "ZeroMedDress", "node_ref": zero_ent}
    )
    if not MapFieldCare.can_offer_field_bandage(zero_med_world, zero_member):
        _fail(failures, "Camp-2.1 E3: field bandage should be offered at 0 company med")
    else:
        _pass()
    var zero_gate: String = CompanyState.format_party_triage_gate_line(zero_med_world)
    if not zero_gate.contains("0 med"):
        _fail(failures, "Camp-2.1 E3: triage gate at 0 med should mention 0-med bandage got '%s'" % zero_gate)
    else:
        _pass()
    var zero_hud: String = CompanyState.format_hud_triage_suffix(zero_med_world)
    if not zero_hud.contains("0-med"):
        _fail(failures, "Camp-2.1 E3: HUD suffix at 0 med should mention 0-med bandages got '%s'" % zero_hud)
    else:
        _pass()
    var zero_camp_block: String = CompanyState.format_camp_heal_block_reason(zero_med_world, true)
    if not zero_camp_block.contains("dressing"):
        _fail(failures, "Camp-2.1 E3: camp block at 0 med with wounds should cite dressing got '%s'" % zero_camp_block)
    else:
        _pass()
    var zero_menu: PopupPanel = _new_party_menu()
    zero_med_world.add_child(zero_menu)
    var zero_roster_before: Array = []
    for raw in pm_zero.members:
        if raw is Dictionary:
            zero_roster_before.append(PartyMemberSnapshot.snapshot_from_member(raw as Dictionary))
    zero_menu.show_party(zero_med_world, zero_roster_before)
    var zero_dressed: bool = false
    for attempt in range(48):
        CompanyState.set_medical_supplies(zero_med_world, 0)
        zero_ent.bandaged_parts.erase("chest")
        zero_member = PartyMemberSnapshot.snapshot_from_member({"name": "ZeroMedDress", "node_ref": zero_ent})
        seed(99100 + attempt)
        if MapFieldCare.try_field_bandage(zero_med_world, zero_member):
            zero_dressed = true
            break
    if not zero_dressed:
        _fail(failures, "Camp-2.1 E3: field bandage should succeed at 0 med with reduced efficacy")
    else:
        _pass()
    if CompanyState.get_medical_supplies(zero_med_world) != 0:
        _fail(failures, "Camp-2.1 E3: field bandage at 0 med must not consume company med")
    else:
        _pass()
    var zero_roster_after: Array = []
    for raw in pm_zero.members:
        if raw is Dictionary:
            zero_roster_after.append(PartyMemberSnapshot.snapshot_from_member(raw as Dictionary))
    zero_menu.show_party(zero_med_world, zero_roster_after)
    var zero_labels: String = " ".join(_collect_control_label_texts(zero_menu))
    if not zero_labels.contains("Camp rest unlocked"):
        _fail(
            failures,
            (
                "Camp-2.1 E3: Party should show dressed-complete banner at 0 med got '%s'"
                % zero_labels.substr(0, mini(120, zero_labels.length()))
            )
        )
    else:
        _pass()
    zero_menu.queue_free()
    _release_harness_world(zero_med_world)

    var wired_zero_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_medical_supplies(wired_zero_world, 0)
    CompanyState.wire_party_medical_supply(wired_zero_world)
    var pm_wz: Node = wired_zero_world.get_meta("party_manager")
    var wired_ent: Node = _add_living_entity_member(pm_wz, "WiredZeroMed")
    wired_ent.intelligence = 100
    wired_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var wired_eff: float = CompanyState.compute_field_treatment_effectiveness(wired_ent, wired_zero_world, false)
    if absf(wired_eff - 0.5) > 0.03:
        _fail(failures, "Camp-2.1 E3: post-fight wired 0-med field efficacy want ~0.50 got %.2f" % wired_eff)
    else:
        _pass()
    CompanyState.set_medical_supplies(wired_zero_world, 4)
    if absf(float(wired_ent._get_campaign_supply_factor()) - 1.0) > 0.03:
        _fail(failures, "Camp-2.1 E3: set_medical_supplies should rewire entity supply stamp to 1.0 at 4 med")
    else:
        _pass()
    _release_harness_world(wired_zero_world)

    var sort_world: Node2D = _make_world(1)
    var pm_sort: Node = sort_world.get_meta("party_manager")
    var sort_ent: Node = _add_living_entity_member(pm_sort, "SortThreat")
    sort_ent.wounds["left_leg"] = [
        {"current_bleeding_rate": 0.08, "severity": "minor"},
    ]
    sort_ent.wounds["right_arm"] = [
        {"current_bleeding_rate": 0.9, "is_arterial": true, "severity": "severe"},
    ]
    var sorted: Array = EntityWounds.sorted_untreated_part_names(sort_ent)
    if sorted.is_empty() or str(sorted[0]) != "right_arm":
        _fail(failures, "Camp-2.1: untreated parts should sort by threat (want right_arm first got %s)" % str(sorted))
    else:
        _pass()
    _release_harness_world(sort_world)
