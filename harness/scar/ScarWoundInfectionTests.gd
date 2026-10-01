class_name ScarWoundInfectionTests

extends ScarTestBase

## Scar wound lifecycle: stash/clear resolved wounds, health-clock round trip,
## systemic infection round trip, reinjury severity, and amputation minting
## (severed part, closed injuries, scarred resolves slower, severed bone).


static func _run_stash_and_clear_resolved_wounds(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    if ent.resolved_wounds_this_advance.size() != 0:
        _fail(failures, "stash: should start empty")
    ent._stash_resolved_wound(
        {
            "part": "left_leg",
            "severity": "severe",
            "is_compound_fracture": true,
            "is_osteomyelitis": true,
            "was_infected": true
        }
    )
    if ent.resolved_wounds_this_advance.size() != 1:
        _fail(failures, "stash: should hold one descriptor (got %d)" % ent.resolved_wounds_this_advance.size())
    var d0: Dictionary = ent.resolved_wounds_this_advance[0]
    if str(d0.get("part", "")) != "left_leg" or not bool(d0.get("is_osteomyelitis", false)):
        _fail(failures, "stash: descriptor fields should round-trip (got %s)" % str(d0))
    ent.clear_resolved_wounds()
    if ent.resolved_wounds_this_advance.size() != 0:
        _fail(
            failures,
            "stash: clear_resolved_wounds should empty the stash (got %d)" % ent.resolved_wounds_this_advance.size()
        )
    _free_entity_fixture(ent)


## The health-system clock must survive save/load: without it, every saved wound's age
## collapses (age = clock—created_at) and it heals as freshly made.


static func _run_health_clock_round_trip(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    # A wound aged 2400s of a 3600s healing duration (created at 1200, clock at 3600).
    ent.wounds["left_leg"] = [
        {
            "created_at_game_time": 1200.0,
            "healing_duration_seconds": 3600.0,
            "severity": "severe",
            "injury_type": "cut"
        },
    ]
    ent._game_time_seconds = 3600.0
    var wound: Dictionary = ent.wounds["left_leg"][0]
    var before: float = ent._get_wound_healing_progress(wound)
    if before <= 0.0:
        _fail(failures, "persist_clock: pre-save healing progress should be > 0 (got %.4f)" % before)
    var serialized: Dictionary = CampaignPersistence._serialize_entity(ent)
    if absf(float(serialized.get("game_time_seconds", -1.0)) - 3600.0) > 1e-6:
        _fail(
            failures,
            (
                "persist_clock: game_time_seconds should serialize as 3600 (got %s)"
                % str(serialized.get("game_time_seconds"))
            )
        )
    var fresh: Node = _new_entity("SWORD")
    CampaignPersistence._apply_entity(fresh, serialized)
    if absf(float(fresh._game_time_seconds) - 3600.0) > 1e-6:
        _fail(
            failures, "persist_clock: restored _game_time_seconds should be 3600 (got %.1f)" % fresh._game_time_seconds
        )
    var rwound: Dictionary = fresh.wounds["left_leg"][0]
    var after: float = fresh._get_wound_healing_progress(rwound)
    if absf(after - before) > 1e-6:
        _fail(
            failures,
            (
                "persist_clock: wound healing progress should survive the round-trip (before %.4f, after %.4f)"
                % [before, after]
            )
        )
    _free_entity_fixture(ent)
    _free_entity_fixture(fresh)


## Entity-level sepsis / tetanus state (survives the seeding wound resolving) must round-trip.


static func _run_systemic_infection_round_trip(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.is_septic = true
    ent.sepsis_resolve_progress = 0.4
    ent.sepsis_recovered = true
    ent.is_tetanus = true
    ent.tetanus_incubation_days = 7.5
    ent.tetanus_resolve_progress = 0.3
    var serialized: Dictionary = CampaignPersistence._serialize_entity(ent)
    for k in [
        "is_septic",
        "sepsis_resolve_progress",
        "sepsis_recovered",
        "is_tetanus",
        "tetanus_incubation_days",
        "tetanus_resolve_progress"
    ]:
        if not serialized.has(k):
            _fail(failures, "persist_sys: %s should be serialized" % k)
    var fresh: Node = _new_entity("SWORD")
    CampaignPersistence._apply_entity(fresh, serialized)
    if fresh.is_septic != true:
        _fail(failures, "persist_sys: restored is_septic should be true (got %s)" % str(fresh.is_septic))
    if absf(float(fresh.sepsis_resolve_progress) - 0.4) > 1e-6:
        _fail(
            failures,
            "persist_sys: restored sepsis_resolve_progress should be 0.4 (got %.3f)" % fresh.sepsis_resolve_progress
        )
    if fresh.sepsis_recovered != true:
        _fail(failures, "persist_sys: restored sepsis_recovered should be true")
    if fresh.is_tetanus != true:
        _fail(failures, "persist_sys: restored is_tetanus should be true (got %s)" % str(fresh.is_tetanus))
    if absf(float(fresh.tetanus_incubation_days) - 7.5) > 1e-6:
        _fail(
            failures,
            "persist_sys: restored tetanus_incubation_days should be 7.5 (got %.2f)" % fresh.tetanus_incubation_days
        )
    # A clean entity must not pick up systemic state from an empty/old save (defaults stay).
    var clean: Node = _new_entity("SWORD")
    CampaignPersistence._apply_entity(clean, {})
    if clean.is_septic or clean.is_tetanus or absf(float(clean.tetanus_incubation_days) - (-1.0)) > 1e-9:
        _fail(
            failures,
            (
                (
                    "persist_sys_defaults: empty apply should leave systemic state at defaults (septic=%s tetanus=%s "
                    + "inc=%s)"
                )
                % [str(clean.is_septic), str(clean.is_tetanus), str(clean.tetanus_incubation_days)]
            )
        )
    _free_entity_fixture(ent)
    _free_entity_fixture(fresh)
    _free_entity_fixture(clean)


## CAMP-SCAR-1 §9.3: a wound landing on a scarred part is rated one severity band worse
## (SCAR_REINJURY_MULT) than the same wound on a clean part.


static func _run_scar_reinjury_severity(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    _seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
    # With FEATURE_ABSOLUTE_SEVERITY_PCT_CAP off, severity is governed by absolute tissue damage
    # (MODERATE at 2.0, SEVERE at 5.0). Penetration 6.0mm => depth_mult 1.0, "thigh" => sub_mult 1.0,
    # so the only variable is the scar re-injury mult: clean 4.5 (MODERATE) vs scarred 4.5*1.15=5.175
    # (SEVERE) — the 15% bump crosses the band.
    var dmg: float = 4.5
    var sub: String = "thigh"
    var sev_clean: String = EntityWounds.severity_from_damage(clean, "left_leg", dmg, sub, -1.0, 6.0)
    var sev_scar: String = EntityWounds.severity_from_damage(scarred, "left_leg", dmg, sub, -1.0, 6.0)
    var rank_clean: int = EntityWounds._severity_rank(sev_clean)
    var rank_scar: int = EntityWounds._severity_rank(sev_scar)
    if rank_scar <= rank_clean:
        _fail(
            failures, "scar_reinjury: scarred part should land worse severity (%s vs clean %s)" % [sev_scar, sev_clean]
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)


## Amputation: a severed limb mints a permanent amputated_limb scar (idempotent per part).


static func _run_amputation_mints_scar(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.body_cutting["left_leg"] = 0.0
    ent.body_blunt["left_leg"] = 0.0
    if "bone_health" in ent:
        ent.bone_health["left_leg"] = 0.0
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var found: bool = false
    for aff in ent.campaign_afflictions:
        if (
            aff is Dictionary
            and str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB
            and str(aff.get("part", "")) == "left_leg"
        ):
            found = true
            break
    if not found:
        _fail(
            failures,
            (
                "amputation: severed limb should mint an amputated_limb scar (afflictions: %s)"
                % str(ent.campaign_afflictions)
            )
        )
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var count: int = 0
    for aff in ent.campaign_afflictions:
        if (
            aff is Dictionary
            and str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB
            and str(aff.get("part", "")) == "left_leg"
        ):
            count += 1
    if count != 1:
        _fail(failures, "amputation: should have exactly 1 amputated_limb entry (got %d)" % count)
    _free_entity_fixture(ent)


## A severed limb should not also receive a per-wound scar (scarred_tissue etc.) when its
## stump wound resolves — the amputated_limb scar is the sole chronic record for that part.


static func _run_severed_part_skips_wound_scar(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.body_cutting["left_leg"] = 0.0
    ent.body_blunt["left_leg"] = 0.0
    if "bone_health" in ent:
        ent.bone_health["left_leg"] = 0.0
    # Simulate a resolved wound descriptor on the severed part
    ent._stash_resolved_wound({"part": "left_leg", "severity": "critical", "was_infected": true})
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    # amputated_limb should be present
    var has_amp: bool = false
    var has_scarred: bool = false
    for aff in ent.campaign_afflictions:
        if aff is Dictionary:
            if (
                str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB
                and str(aff.get("part", "")) == "left_leg"
            ):
                has_amp = true
            if (
                str(aff.get("id", "")) == CampaignAfflictions.SCAR_SCARRED_TISSUE
                and str(aff.get("part", "")) == "left_leg"
            ):
                has_scarred = true
    if not has_amp:
        _fail(failures, "severed_skip: amputated_limb should be minted for severed part")
    if has_scarred:
        _fail(failures, "severed_skip: scarred_tissue should NOT be minted for a severed part")
    _free_entity_fixture(ent)


## Closed injuries do not remodel into soft-tissue scar, so they never mint `scarred_tissue`:
## a resolving severe bruise (closed contusion resorbs wholly) and a clean severe non-compound
## fracture (heals with internal bone callus; malunion models exposed bone only) mint nothing on
## resolution, even when infected — while an open severe cut (and the other open muscle/tissue
## types) still mint. Gated on the descriptor's injury_type on both the infected and the
## clean-severe paths.


static func _run_closed_injuries_mint_no_wound_scar(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent._stash_resolved_wound(
        {"part": "left_leg", "severity": "severe", "injury_type": BleedingConstants.INJURY_TYPE_BRUISE}
    )
    ent._stash_resolved_wound(
        {"part": "right_leg", "severity": "severe", "injury_type": BleedingConstants.INJURY_TYPE_FRACTURE}
    )
    ent._stash_resolved_wound(
        {
            "part": "left_arm",
            "severity": "severe",
            "was_infected": true,
            "injury_type": BleedingConstants.INJURY_TYPE_BRUISE
        }
    )
    ent._stash_resolved_wound(
        {"part": "right_arm", "severity": "severe", "injury_type": BleedingConstants.INJURY_TYPE_CUT}
    )
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var has_control: bool = false
    for aff in ent.campaign_afflictions:
        if aff is Dictionary and str(aff.get("id", "")) == CampaignAfflictions.SCAR_SCARRED_TISSUE:
            match str(aff.get("part", "")):
                "left_leg":
                    _fail(failures, "closed: a resolving severe bruise should mint no scarred_tissue")
                "right_leg":
                    _fail(failures, "closed: a resolving clean severe fracture should mint no scarred_tissue")
                "left_arm":
                    _fail(failures, "closed: an infected bruise should mint no scarred_tissue (closed injury)")
                "right_arm":
                    has_control = true
    if not has_control:
        _fail(failures, "closed: an open severe cut should still mint scarred_tissue (control)")
    _free_entity_fixture(ent)


## A new wound on an already-scarred part closes slower: `EntityWounds.add_wound` scales the
## resolution duration by 1 / _get_scar_heal_mult(part) (hypovascular scar tissue lengthens the
## remodeling phase), so the wound's healing-progress arithmetic reaches the resolution threshold
## later. A severed part keeps the canonical duration (its amputation scar prunes the part scars).


static func _run_scarred_part_wound_resolves_slower(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    scarred._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg"))
    EntityWounds.add_wound(
        clean, "left_leg", BleedingConstants.INJURY_TYPE_CUT, 5.0, "", BleedingConstants.SEVERITY_SEVERE
    )
    EntityWounds.add_wound(
        scarred, "left_leg", BleedingConstants.INJURY_TYPE_CUT, 5.0, "", BleedingConstants.SEVERITY_SEVERE
    )
    var clean_dur: float = float(clean.wounds["left_leg"][0].get("healing_duration_seconds", 0.0))
    var scarred_dur: float = float(scarred.wounds["left_leg"][0].get("healing_duration_seconds", 0.0))
    var heal_h: float = float(
        CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg").get("heal_mult", 1.0)
    )
    if scarred_dur <= clean_dur:
        _fail(failures, "scar_resolve: scarred-part wound should resolve SLOWER (longer duration)")
    if absf(scarred_dur - clean_dur / heal_h) > 1e-6:
        _fail(
            failures,
            "scar_resolve: scarred duration %.3f should be clean %.3f / heal %.3f" % [scarred_dur, clean_dur, heal_h]
        )
    var severed: Node = _new_entity("SWORD")
    severed.body_cutting["left_leg"] = 0.0
    severed.body_blunt["left_leg"] = 0.0
    if "bone_health" in severed:
        severed.bone_health["left_leg"] = 0.0
    severed._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg"))
    EntityWounds.add_wound(
        severed, "left_leg", BleedingConstants.INJURY_TYPE_CUT, 5.0, "", BleedingConstants.SEVERITY_SEVERE
    )
    var severed_dur: float = float(severed.wounds["left_leg"][0].get("healing_duration_seconds", 0.0))
    if absf(severed_dur - clean_dur) > 1e-6:
        _fail(
            failures,
            (
                "scar_resolve: severed-part stump wound should keep the canonical duration "
                + "(got %.3f vs clean %.3f)" % [severed_dur, clean_dur]
            )
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)
    _free_entity_fixture(severed)


## A severed limb never feeds the post-victory bone-cripple roll: `_worst_bone_part` skips parts
## whose bone is zeroed (a limb severed in the fight would otherwise read as the worst crippled bone
## and roll "Limping left_leg" for a limb that no longer exists — its chronic state is the
## amputated_limb scar, minted on the next advance), falling through to an attached <25% bone
## instead. When no surviving bone is crippled, the roll yields nothing on every seed.


static func _run_severed_bone_part_not_bone_crippled(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.body_cutting["left_leg"] = 0.0
    ent.body_blunt["left_leg"] = 0.0
    if "bone_health" in ent:
        ent.bone_health["left_leg"] = 0.0
    if "bone_max" in ent:
        ent.bone_max["left_leg"] = 100.0
        ent.bone_max["chest"] = 100.0
        ent.bone_health["chest"] = 20.0
    ent.blood_volume = 100.0
    var worst: String = CampaignAfflictions._worst_bone_part(ent)
    if worst != "chest":
        _fail(failures, "bone_roll: severed left_leg should be skipped, worst surviving bone is chest (got %s)" % worst)
    if CampaignAfflictions._bone_affliction_id(worst) != CampaignAfflictions.AFFLICTION_CRACKED_RIBS:
        _fail(
            failures,
            "bone_roll: chest bone should map to cracked_ribs (got %s)" % CampaignAfflictions._bone_affliction_id(worst)
        )
    var only_severed: Node = _new_entity("SWORD")
    only_severed.body_cutting["right_leg"] = 0.0
    only_severed.body_blunt["right_leg"] = 0.0
    if "bone_health" in only_severed:
        only_severed.bone_health["right_leg"] = 0.0
    if "bone_max" in only_severed:
        only_severed.bone_max["right_leg"] = 100.0
    only_severed.blood_volume = 100.0
    if not CampaignAfflictions._worst_bone_part(only_severed).is_empty():
        _fail(failures, "bone_roll: only a severed bone -> no surviving crippled bone")
    for s in [1, 2, 3, 4, 5]:
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.seed = s
        var roll: Dictionary = CampaignAfflictions._roll_affliction_for_entity(only_severed, only_severed, rng)
        if not roll.is_empty():
            _fail(
                failures,
                (
                    "bone_roll: severed-only member should roll no affliction (seed %d got %s)"
                    % [s, str(roll.get("id", "?"))]
                )
            )
    _free_entity_fixture(ent)
    _free_entity_fixture(only_severed)

## Post-victory tier roll: the arterial-fail cause (0.55) must name the affliction, not a coexisting
## crippled bone (0.45). The old code had the bone branch unconditionally overwrite `pick`, so a member
## with 2+ untreated arterial wounds AND a <25% bone rolled "Limping left_leg" / "Shaky grip" /
## "Cracked ribs" at the 0.55 arterial gate instead of slowed_circulation (arterial fail).
