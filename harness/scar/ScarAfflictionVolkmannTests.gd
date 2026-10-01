class_name ScarAfflictionVolkmannTests

extends ScarTestBase

## Scar affliction + volkmann ischemia: arterial/struck-down affliction rolls,
## scarred infection slowdown, post-sepsis weakness, dead-member minting,
## scar line-effect suffix, bone sited penalties, amputation pruning,
## phantom pain, TQ ischemia latches, pre-expiry resolution, osteo infection.


static func _run_affliction_roll_arterial_wins_over_bone(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.blood_volume = 100.0
    if "bone_health" in ent:
        ent.bone_health["left_leg"] = 20.0
    if "bone_max" in ent:
        ent.bone_max["left_leg"] = 100.0
    ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "severity": "critical", "is_arterial": true},
        {"current_bleeding_rate": 0.0, "severity": "critical", "is_arterial": true},
    ]
    if CampaignAfflictions._worst_bone_part(ent) != "left_leg":
        _fail(failures, "arterial_bone_roll: left_leg bone should be the worst crippled bone")
    if CampaignAfflictions._count_untreated_arterial(ent) != 2:
        _fail(
            failures,
            (
                "arterial_bone_roll: expected 2 untreated arterial wounds (got %d)"
                % CampaignAfflictions._count_untreated_arterial(ent)
            )
        )
    var bone_names: Array = [
        CampaignAfflictions.AFFLICTION_LIMPING_LIMB,
        CampaignAfflictions.AFFLICTION_SHAKY_GRIP,
        CampaignAfflictions.AFFLICTION_CRACKED_RIBS,
    ]
    var fired: int = 0
    for s in range(1, 65):
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.seed = s
        var roll: Dictionary = CampaignAfflictions._roll_affliction_for_entity(ent, ent, rng)
        if roll.is_empty():
            continue
        fired += 1
        var id: String = str(roll.get("id", ""))
        if bone_names.has(id):
            _fail(failures, "arterial_bone_roll: arterial gate named a bone affliction (seed %d got %s)" % [s, id])
        elif id != CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION:
            _fail(failures, "arterial_bone_roll: unexpected affliction (seed %d got %s)" % [s, id])
    if fired == 0:
        _fail(failures, "arterial_bone_roll: no rolls fired across seeds (gate never exercised)")
    _free_entity_fixture(ent)


## Post-victory tier roll: an unconscious member in the danger blood band keeps the struck-down cause
## (0.33). The old code had the danger branch (0.12) overwrite `pick`, naming "Partly collapsed lung" or
## "Old wound ache" at the struck-down 0.33 gate.
static func _run_affliction_roll_struck_down_wins_over_danger(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.blood_volume = 56.0  # danger band (< 58, >= peril 55)
    var proxy: _StruckDownProxy = _StruckDownProxy.new()
    if not (ent.blood_volume < BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING):
        _fail(failures, "struck_down_roll: fixture blood must sit in the danger band")
    if not (ent.blood_volume >= BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING):
        _fail(failures, "struck_down_roll: fixture blood must not sit in the peril band")
    if not proxy.is_unconscious():
        _fail(failures, "struck_down_roll: proxy must report unconscious")
    var fired: int = 0
    for s in range(1, 65):
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.seed = s
        var roll: Dictionary = CampaignAfflictions._roll_affliction_for_entity(ent, proxy, rng)
        if roll.is_empty():
            continue
        fired += 1
        var id: String = str(roll.get("id", ""))
        if id != CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION:
            _fail(failures, "struck_down_roll: danger band relabeled a struck-down roll (seed %d got %s)" % [s, id])
    if fired == 0:
        _fail(failures, "struck_down_roll: no rolls fired across seeds (gate never exercised)")
    proxy.free()
    _free_entity_fixture(ent)


## CAMP-SCAR-1 (infection-clear intersection): when a dressing cures an infected wound, the resolution
## clock is recomputed from the pre-infection baseline — and that baseline on a scarred part must
## include the scar slow-down shared through `EntityWounds.scaled_healing_duration_seconds`. Otherwise
## a scarred limb that got infected would heal FASTER than the identical scarred limb that stayed clean
## (raw base vs base/scar_heal_mult). Clean part -> raw base; scarred part -> base / scar_heal_mult;
## severed stump -> raw base (canonical, amputation scar is its chronic state).


static func _run_scarred_infection_clear_keeps_slowdown(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var scarred: Node = _new_entity("SWORD")
    var severed: Node = _new_entity("SWORD")
    var b: float = HealingConstants.get_wound_healing_duration_seconds(
        "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
    )
    var d_clean: float = EntityWounds.scaled_healing_duration_seconds(
        clean, "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
    )
    if absf(d_clean - b) > 1e-6:
        _fail(failures, "inf_clear: clean baseline must be the raw base (%.3f vs %.3f)" % [d_clean, b])
    _seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
    var scar_h: float = float(scarred._get_scar_heal_mult("left_leg"))
    var d_scar: float = EntityWounds.scaled_healing_duration_seconds(
        scarred, "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
    )
    if absf(d_scar - b / scar_h) > 1e-6:
        _fail(
            failures,
            (
                "inf_clear: a cured scarred wound must still close at base/scar_heal_mult (%.3f vs %.3f)"
                % [d_scar, b / scar_h]
            )
        )
    severed.body_cutting["left_leg"] = 0.0
    severed.body_blunt["left_leg"] = 0.0
    if "bone_health" in severed:
        severed.bone_health["left_leg"] = 0.0
    var d_sev: float = EntityWounds.scaled_healing_duration_seconds(
        severed, "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
    )
    if absf(d_sev - b) > 1e-6:
        _fail(failures, "inf_clear: severed stump baseline must stay raw base (%.3f vs %.3f)" % [d_sev, b])
    _free_entity_fixture(clean)
    _free_entity_fixture(scarred)
    _free_entity_fixture(severed)


## The post-sepsis weakness scar is the convalescent aftermath: minted only after recovery (latched
## sepsis_recovered, is_septic already false), NEVER while actively septic — a member still septic or
## dead of sepsis must not carry the "post-sepsis" label. id-dedup (part "") prevents re-mints on
## later advances.


static func _run_post_sepsis_weakness_only_after_recovery(failures: PackedStringArray) -> void:
    var active: Node = _new_entity("SWORD")
    active.is_septic = true
    active.sepsis_recovered = false
    CampaignAfflictions._mint_scars_for_entity(active, "Test", null, null)
    if active.campaign_afflictions.size() > 0:
        _fail(
            failures,
            (
                "postsepsis: an actively-septic member must not mint the recovery scar (got %s)"
                % str(active.campaign_afflictions)
            )
        )
    var recovered: Node = _new_entity("SWORD")
    recovered.is_septic = false
    recovered.sepsis_recovered = true
    CampaignAfflictions._mint_scars_for_entity(recovered, "Test", null, null)
    if not (
        recovered.campaign_afflictions.size() == 1
        and str(recovered.campaign_afflictions[0].get("id", "")) == CampaignAfflictions.SCAR_POST_SEPSIS_WEAKNESS
    ):
        _fail(
            failures,
            (
                "postsepsis: a recovered member must mint exactly one post-sepsis weakness scar (got %s)"
                % str(recovered.campaign_afflictions)
            )
        )
    CampaignAfflictions._mint_scars_for_entity(recovered, "Test", null, null)
    if recovered.campaign_afflictions.size() != 1:
        _fail(failures, "postsepsis: id-dedup must prevent re-minting on a later advance")
    var dead: Node = _new_entity("SWORD")
    dead.is_septic = false
    dead.sepsis_recovered = true
    dead._sepsis_dead = true
    CampaignAfflictions._mint_scars_for_entity(dead, "Test", null, null)
    if dead.campaign_afflictions.size() > 0:
        _fail(failures, "postsepsis: a sepsis-dead member must not carry the recovery scar")
    _free_entity_fixture(active)
    _free_entity_fixture(recovered)
    _free_entity_fixture(dead)


## The dead do not mint: a death-registered member (sepsis or tetanus death flag) who still carries a
## resolved-wound stash must not accrue permanent afflictions on a later op-log pass — corpse
## bookkeeping drains the stash without minting a single scar.


static func _run_dead_member_mints_nothing(failures: PackedStringArray) -> void:
    for dflag in ["_sepsis_dead", "_tetanus_dead"]:
        var dead: Node = _new_entity("SWORD")
        dead.set(dflag, true)
        dead.is_septic = false
        dead.sepsis_recovered = true
        dead._stash_resolved_wound(
            {
                "part": "left_arm",
                "severity": BleedingConstants.SEVERITY_SEVERE,
                "injury_type": BleedingConstants.INJURY_TYPE_CUT,
                "is_compound_fracture": false,
                "is_osteomyelitis": false,
                "was_infected": true
            }
        )
        CampaignAfflictions._mint_scars_for_entity(dead, "Test", null, null)
        if dead.campaign_afflictions.size() > 0:
            _fail(
                failures,
                (
                    "dead_mint[%s]: a dead member must mint no afflictions (got %s)"
                    % [dflag, str(dead.campaign_afflictions)]
                )
            )
        if dead.resolved_wounds_this_advance.size() != 0:
            _fail(failures, "dead_mint[%s]: a dead member's resolved-stash should still be drained" % dflag)
        _free_entity_fixture(dead)


## The scar/affliction line suffix renders a real SIGNED delta, not a terse remaining-value
## ("Stamina × 85%" misreads as an 85% loss): 0.88 -> "Stamina -12%", 1.05 pain -> "Pain +5%",
## neutral multipliers emit no fragment.


static func _run_scar_line_effect_suffix_signed(failures: PackedStringArray) -> void:
    var ribs: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_CRACKED_RIBS, "chest")
    var suf_ribs: String = CampaignAfflictions.format_scar_line("Test", ribs)
    if not suf_ribs.contains("Stamina -12%") or not suf_ribs.contains("Pain +5%"):
        _fail(failures, "suffix: cracked_ribs should read 'Stamina -12%, Pain +5%' (got %s)" % suf_ribs)
    var ache: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_OLD_WOUND_ACHE, "")
    var suf_ache: String = CampaignAfflictions.format_scar_line("Test", ache)
    if not suf_ache.contains("Pain +8%") or suf_ache.contains("Stamina"):
        _fail(failures, "suffix: old_wound_ache should read only 'Pain +8%' (got %s)" % suf_ache)
    var slow: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION, "")
    var suf_slow: String = CampaignAfflictions.format_scar_line("Test", slow)
    if not suf_slow.contains("Stamina -10%"):
        _fail(failures, "suffix: slowed_circulation 0.90 should read 'Stamina -10%' (got %s)" % suf_slow)
    if suf_slow.contains(" - - "):
        _fail(failures, "suffix: no remaining-value double-dash form may survive (got %s)" % suf_slow)
    var flat: Dictionary = {"id": "x", "label": "x", "stamina_mult": 1.0, "pain_mult": 1.0}
    if not CampaignAfflictions.format_scar_line("Test", flat).ends_with("  -  x"):
        _fail(failures, "suffix: neutral multipliers must produce no suffix fragment")
    var deep_scar: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "chest")
    var suf_scar: String = CampaignAfflictions.format_scar_line("Test", deep_scar)
    if not suf_scar.contains("Pain +3%"):
        _fail(failures, "suffix: scarred_tissue pain 1.03 should read 'Pain +3%' (got %s)" % suf_scar)


## The post-victory RNG bone afflictions carry their `part` AND a modest sited penalty (move_speed /
## grip / stamina_pool, 0.95) through the SAME scar reader the wound-derived catalog uses: a "Limping
## right_leg" actually slows gait (named functional cost is real), while whole-body stamina stays in
## the tuned 5-10% band. Non-bone afflictions (old_wound_ache, slowed_circulation) stay pure / part "".


static func _run_bone_afflictions_carry_sited_penalty(failures: PackedStringArray) -> void:
    var limp: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_LIMPING_LIMB, "right_leg")
    if (
        absf(float(limp.get("move_speed", 1.0)) - 0.95) > 1e-9
        or absf(float(limp.get("stamina_mult", 1.0)) - 0.92) > 1e-9
    ):
        _fail(failures, "sited: limping_limb should carry move_speed 0.95 on top of stamina 0.92")
    var grip: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_SHAKY_GRIP, "left_arm")
    if absf(float(grip.get("grip", 1.0)) - 0.95) > 1e-9 or absf(float(grip.get("stamina_mult", 1.0)) - 0.94) > 1e-9:
        _fail(failures, "sited: shaky_grip should carry grip 0.95 on top of stamina 0.94")
    var ribs: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_CRACKED_RIBS, "chest")
    if (
        absf(float(ribs.get("stamina_pool", 1.0)) - 0.95) > 1e-9
        or absf(float(ribs.get("stamina_mult", 1.0)) - 0.88) > 1e-9
    ):
        _fail(failures, "sited: cracked_ribs should carry stamina_pool 0.95 on top of stamina 0.88")
    var ache: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_OLD_WOUND_ACHE, "")
    if "move_speed" in ache or "grip" in ache or "stamina_pool" in ache or str(ache.get("part", "")) != "":
        _fail(failures, "sited: old_wound_ache is a whole-body pain condition, must carry no sited penalty or part")
    var ent: Node = _new_entity("SWORD")
    ent._add_campaign_affliction(limp)
    ent._add_campaign_affliction(grip)
    ent._add_campaign_affliction(ribs)
    var lp: Dictionary = ent._get_scar_part_penalty("right_leg")
    var gp: Dictionary = ent._get_scar_part_penalty("left_arm")
    var cp: Dictionary = ent._get_scar_part_penalty("chest")
    if absf(float(lp.get("move_speed", 1.0)) - 0.95) > 1e-9:
        _fail(
            failures,
            (
                "sited: scar reader should apply move_speed 0.95 to the limping leg (got %.3f)"
                % float(lp.get("move_speed", 1.0))
            )
        )
    if absf(float(gp.get("grip", 1.0)) - 0.95) > 1e-9:
        _fail(
            failures,
            "sited: scar reader should apply grip 0.95 to the shaky arm (got %.3f)" % float(gp.get("grip", 1.0))
        )
    if absf(float(cp.get("stamina_pool", 1.0)) - 0.95) > 1e-9:
        _fail(
            failures,
            (
                "sited: scar reader should apply stamina_pool 0.95 to the cracked chest (got %.3f)"
                % float(cp.get("stamina_pool", 1.0))
            )
        )
    var leg_frac: float = ent._get_leg_functionality()
    if absf(leg_frac - 0.95) > 1e-6:
        _fail(failures, "sited: a limping right leg should slow whole-locomotion to ~0.95 (got %.3f)" % leg_frac)
    # Separate axes: per-part penalties sit on the part, whole-body stamina stays exactly in-band.
    var sm: float = ent._get_campaign_stamina_mult()
    if absf(sm - 0.92 * 0.94 * 0.88 * 0.95) > 1e-6:
        _fail(failures, "sited: stamina mult should be whole-body product + chest pool (got %.4f)" % sm)
    _free_entity_fixture(ent)


## The amputation supersedes the limb's prior injuries: minting amputated_limb prunes earlier
## same-part scars and bone afflictions (their multipliers are moot on a severed part and their
## labels would double-list beside "Amputated {part}"), while whole-body afflictions are untouched.


static func _run_amputation_prunes_same_part_afflictions(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg"))
    ent._add_campaign_affliction(CampaignAfflictions.catalog_def(CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION))
    ent.body_cutting["left_leg"] = 0.0
    ent.body_blunt["left_leg"] = 0.0
    if "bone_health" in ent:
        ent.bone_health["left_leg"] = 0.0
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var has_scarred: bool = false
    var has_slowed: bool = false
    var amp_count: int = 0
    for aff in ent.campaign_afflictions:
        if aff is Dictionary:
            var aid: String = str(aff.get("id", ""))
            var apart: String = str(aff.get("part", ""))
            if aid == CampaignAfflictions.SCAR_SCARRED_TISSUE and apart == "left_leg":
                has_scarred = true
            if aid == CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION:
                has_slowed = true
            if aid == CampaignAfflictions.SCAR_AMPUTATED_LIMB and apart == "left_leg":
                amp_count += 1
    if has_scarred:
        _fail(failures, "amp_prune: pre-severance part scar should be pruned by the amputation")
    if not has_slowed:
        _fail(failures, "amp_prune: whole-body affliction should survive the amputation")
    if amp_count != 1:
        _fail(failures, "amp_prune: exactly one amputated_limb should remain (got %d)" % amp_count)
    # A second mint stays idempotent after the prune (the amputation scar is never itself pruned).
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    amp_count = 0
    for aff in ent.campaign_afflictions:
        if (
            aff is Dictionary
            and str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB
            and str(aff.get("part", "")) == "left_leg"
        ):
            amp_count += 1
    if amp_count != 1:
        _fail(failures, "amp_prune: amputation scar stays idempotent after prune (got %d)" % amp_count)
    _free_entity_fixture(ent)


## Phantom limb pain: the amputated_limb scar carries a whole-body pain_mult (persistent phantom
## sensation/pain follows ~50-80% of amputations), which the campaign pain reader applies in combat.


static func _run_amputated_phantom_pain(failures: PackedStringArray) -> void:
    var def: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_AMPUTATED_LIMB, "right_arm")
    var def_pain: float = float(def.get("pain_mult", 1.0))
    if absf(def_pain - 1.06) > 1e-9:
        _fail(failures, "phantom: amputated_limb should carry pain_mult 1.06 (got %.3f)" % def_pain)
    var ent: Node = _new_entity("SWORD")
    ent._add_campaign_affliction(def)
    var pain_read: float = ent._get_campaign_pain_mult()
    if absf(pain_read - 1.06) > 1e-9:
        _fail(failures, "phantom: whole-body pain reader should reflect 1.06 (got %.3f)" % pain_read)
    _free_entity_fixture(ent)


## TQ ischemia latches had_ischemia on the wound so a Volkmann contracture mints at resolution —
## even though the tourniquet has long been removed (the flag travels on the wound, not the TQ dict).


static func _run_tq_ischemia_latches_volkmann(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var wound: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_SEVERE,
        "sub_region": "",
        "cumulative_damage": 2.0,
        "current_bleeding_rate": 0.0,
        "base_bleeding_rate": 0.0,
        "is_arterial": false,
        "is_stabilized": true,
        "penetration_to_tissue_mm": -1.0,
        "created_at_game_time": 0.0,
        "healing_duration_seconds": 7200.0,
    }
    ent.wounds["right_arm"] = [wound]
    ent.tourniquet_applied["right_arm"] = {"applied_at": 0.0, "effectiveness": 1.0}
    seed(12345)
    # Call 1: advance past TQ max duration -> TQ removed, ischemia latched; wound NOT yet resolved.
    ent._process_healing(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 100.0)
    if ent.tourniquet_applied.has("right_arm"):
        _fail(failures, "tq_latch: tourniquet should be removed after max duration")
    var w: Dictionary = ent.wounds.get("right_arm", [{}])[0]
    if not bool(w.get("had_ischemia", false)):
        _fail(
            failures,
            "tq_latch: wound should have had_ischemia=true after TQ expiry (got %s)" % str(w.get("had_ischemia"))
        )
    # Call 2: advance until the wound resolves. TQ is already gone, so the descriptor's had_ischemia
    # can only come from the latched wound flag — proving the latch survives TQ removal.
    ent._process_healing(4000.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var has_contracture: bool = false
    for aff in ent.campaign_afflictions:
        if (
            aff is Dictionary
            and str(aff.get("id", "")) == CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE
            and str(aff.get("part", "")) == "right_arm"
        ):
            has_contracture = true
    if not has_contracture:
        _fail(
            failures,
            (
                "tq_latch_volkmann: a Volkmann contracture should mint for a TQ-ischemia'd arm (afflictions: %s)"
                % str(ent.campaign_afflictions)
            )
        )
    _free_entity_fixture(ent)


## A tourniquet released at wound resolution (before its max-duration expiry) must NOT mint a
## Volkmann contracture: the clamp came off while the limb was still healing (pre-expiry), so no
## ischemic necrosis occurred and the arm should not carry the grip 0.78 contracture. Negative twin
## of _run_tq_ischemia_latches_volkmann -- pins the false-positive the old
## `tourniquet_applied.has(part)` term minted onto every wound that resolved while a TQ was still on.


static func _run_pre_expiry_resolution_mints_no_volkmann(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var wound: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_SEVERE,
        "sub_region": "",
        "cumulative_damage": 2.0,
        "current_bleeding_rate": 0.0,
        "base_bleeding_rate": 0.0,
        "is_arterial": false,
        "is_stabilized": true,
        "penetration_to_tissue_mm": -1.0,
        "created_at_game_time": 0.0,
        "healing_duration_seconds": 360.0,
    }
    ent.wounds["right_arm"] = [wound]
    ent.tourniquet_applied["right_arm"] = {"applied_at": 0.0, "effectiveness": 1.0}
    seed(12345)
    # A single advance sits well past this wound's resolution (360s heal -> resolves ~360s) but inside
    # the 3600s TQ max duration -- the clamp is released at resolution, no ischemia latch, no necrosis.
    ent._process_healing(2000.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if ent.tourniquet_applied.has("right_arm"):
        _fail(
            failures, "tq_preexp: the clamp should be released when its wound resolves (stale clamp on a healed limb)"
        )
    if ent.wounds.has("right_arm"):
        _fail(failures, "tq_preexp: the wound should have resolved in the advance")
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var has_contracture: bool = false
    for aff in ent.campaign_afflictions:
        if (
            aff is Dictionary
            and str(aff.get("id", "")) == CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE
            and str(aff.get("part", "")) == "right_arm"
        ):
            has_contracture = true
    if has_contracture:
        _fail(
            failures,
            (
                (
                    "tq_preexp: a Volkmann contracture must NOT mint when the TQ was released at resolution "
                    + "(pre-expiry, "
                    + "no ischemic necrosis) (afflictions: %s)"
                )
                % str(ent.campaign_afflictions)
            )
        )
    _free_entity_fixture(ent)


## Osteo precedence is malunited-only: a wound that went osteomyelitis still mints the concurrent
## Volkmann contracture (had_ischemia) -- the former `continue` in the osteo branch swallowed the
## separate ischemia mechanism, dropping the harder grip handicap (0.78) from an infected compound
## arm whenever the wound also carried a TQ/compartment ischemia.


static func _run_osteo_infection_still_mints_volkmann(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    if not "resolved_wounds_this_advance" in ent:
        _fail(failures, "osteo_volkmann: harness entity must expose the resolved-wound stash")
    var desc: Array[Dictionary] = [
        {
            "part": "right_arm",
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "was_infected": true,
            "is_compound_fracture": true,
            "is_osteomyelitis": true,
            "had_ischemia": true,
        }
    ]
    ent.resolved_wounds_this_advance = desc
    CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
    var has_osteo: bool = false
    var has_contracture: bool = false
    for aff in ent.campaign_afflictions:
        if not (aff is Dictionary):
            continue
        var aid: String = str(aff.get("id", ""))
        var apart: String = str(aff.get("part", ""))
        if aid == CampaignAfflictions.SCAR_OSTEOMYELITIC_BONE and apart == "right_arm":
            has_osteo = true
        if aid == CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE and apart == "right_arm":
            has_contracture = true
    if not has_osteo:
        _fail(
            failures,
            (
                "osteo_volkmann: infected compound wound must mint the osteo scar (afflictions: %s)"
                % str(ent.campaign_afflictions)
            )
        )
    if not has_contracture:
        _fail(
            failures,
            (
                "osteo_volkmann: concurrent TQ ischemia must still mint the Volkmann contracture "
                + "when the wound also went osteo -- precedence supersedes malunited/scarred_tissue, "
                + "not the separate ischemia mechanism (afflictions: %s)" % str(ent.campaign_afflictions)
            )
        )
    _free_entity_fixture(ent)


class _StruckDownProxy:
    extends Node
    var _unconscious: bool = true

    func is_unconscious() -> bool:
        return _unconscious
