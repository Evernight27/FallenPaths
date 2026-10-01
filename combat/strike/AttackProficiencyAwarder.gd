class_name AttackProficiencyAwarder
extends RefCounted

## XCamp-4: proficiency stat-award surface for a resolved attack action.
## Carried out of `AttackResultApplier` (outcome applier) so the stat-training
## domain owns its own module. `notify_proficiency_gains_from_resolve` is called
## after each action outcome (miss, dodge, hit, parry) by `AttackResultApplier.apply_result`;
## `evaluate_counter_read_outcome` is the Phase-2 counter-read perception award;
## `is_defender_outnumbered` reports whether the defender is the last alive in their
## slot group (feeds the dodger's desirable-difficulty bonus).


## XCamp-4: award proficiency stat gains from a resolved attack action.
## Called after each action outcome (miss, dodge, hit, parry) in apply_result.
static func notify_proficiency_gains_from_resolve(
    manager: Node, attacker_id: int, target_id: int, action: String, result_dict: Dictionary
) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
    if atk.is_empty():
        return

    var weapon_id: String = CombatantEntityAccess.weapon_type_id(atk)
    var form_str: String = CombatantEntityAccess.form_str(atk)

    var attacker_entity: Node = CombatantEntityAccess.combat_body(atk)
    var target_entity: Node = CombatantEntityAccess.combat_body(tgt) if not tgt.is_empty() else null
    var atk_tracked: bool = attacker_entity != null and EntityProficiency.is_stat_gain_tracked(attacker_entity)
    var tgt_tracked: bool = (
        not tgt.is_empty() and target_entity != null and EntityProficiency.is_stat_gain_tracked(target_entity)
    )
    # XCamp-4: physical stat training (striking / dodging / absorbing / parrying) is gated by how
    # cleanly the fighter executed the act. Two multiplicative factors: blood loss
    # (wounded_write_factor) and pain x consciousness execution quality (execution_quality_factor)
    # — the same pain/consciousness model the combat system uses to degrade the fighter's actions.
    # Perception reads (dodge / parry / counter-read) are cognitive and intentionally NOT scaled.
    # For a healthy, fully blooded fighter both factors are 1.0, so uncompromised fighters train
    # exactly as before.
    var atk_wounded: float = (
        (
            EntityProficiency.wounded_write_factor(float(attacker_entity.blood_volume))
            * EntityProficiency.execution_quality_factor(attacker_entity)
        )
        if attacker_entity != null
        else 1.0
    )
    var def_wounded: float = (
        (
            EntityProficiency.wounded_write_factor(float(target_entity.blood_volume))
            * EntityProficiency.execution_quality_factor(target_entity)
        )
        if target_entity != null
        else 1.0
    )
    # XCamp-4: desirable-difficulty for the perception channel — successfully *reading* or *deflecting*
    # a stronger opponent's attack is a sharper perception lesson, mirroring the attacker-STR scaling
    # already applied on a clean hit (opponent_difficulty_mult, same stats_dict source). For the parry /
    # dodge reads the *reader is the defender*, so the attacker is the foe; the counter-read path in
    # evaluate_counter_read_outcome inverts the pair (reader = attacker, foe = defender).
    var atk_str: float = CombatantEntityAccess.stats_dict(atk).get(
        DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    var def_str: float = EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    if not tgt.is_empty():
        def_str = CombatantEntityAccess.stats_dict(tgt).get(
            DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
        )

    # XCamp-4: a completed strike attempt (rep) trains the attacker's weapon/form even when it did not
    # land — a clean hit already carries the larger GAIN_*_PROF_HIT_BASE share via the hit path.
    # Gated by the same execution-quality x blood-loss composite as the physical stat reps: a
    # compromised fighter executes the swing less cleanly, so the motor rep is worth less.
    if atk_tracked and action != "hit" and action != "defeated":
        EntityProficiency.award_weapon_proficiency(
            attacker_entity, weapon_id, EntityProficiency.GAIN_WEAPON_PROF_ATTEMPT_BASE * atk_wounded
        )
        EntityProficiency.award_form_proficiency(
            attacker_entity, form_str, EntityProficiency.GAIN_FORM_PROF_ATTEMPT_BASE * atk_wounded
        )

    # XCamp-4: a committed strike is aerobic exertion — the wind-up, strike, and recovery cycle
    # trains cardiovascular/muscular-stamina conditioning (END) regardless of outcome. This is the
    # attacker's END channel (previously they trained END only by taking damage), so a fighter who
    # swings a lot but blocks well still builds endurance. Fires on every offensive outcome incl. a
    # clean hit; "defeated" completes no swing. Scaled by the wounded factor like other physical
    # gains; cognitive (PER) and weapon/form familiarity are unaffected.
    if atk_tracked and action != "defeated" and attacker_entity != null and "_proficiency_bonus" in attacker_entity:
        EntityProficiency.award_stat_gain(
            attacker_entity,
            "endurance",
            EntityProficiency.GAIN_STRIKE_AEROBIC_END_BASE * atk_wounded,
            weapon_id,
            form_str
        )
        # XCamp-4: a completed wind-up trains the attacker's execution AGI regardless of outcome -
        # miss / dodge / hit / parry all complete the swing, so timing/execution is trained on every
        # committed strike ("defeated" completes no swing). Previously miss-only, which created an
        # inverted incentive where a clean hit trained AGI *less* than a whiff.
        EntityProficiency.award_stat_gain(
            attacker_entity,
            "agility",
            EntityProficiency.GAIN_WINDUP_COMPLETED_AGI_BASE * atk_wounded,
            weapon_id,
            form_str
        )

    match action:
        "miss":
            # Strike attempted: the wind-up STR rep. (Wind-up AGI is now awarded in the common
            # committed-strike block above, so it fires on every swing, not just a miss.)
            # XCamp-4 write-side gate: only tracked attackers accrue (untracked enemies stay flat).
            if atk_tracked:
                EntityProficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * atk_wounded,
                    weapon_id,
                    form_str
                )

        "dodge":
            # Defender dodged - AGI gain for defender. Attacker gets STR wind-up gain.
            if tgt.is_empty() or target_entity == null:
                if atk_tracked:
                    EntityProficiency.award_stat_gain(
                        attacker_entity,
                        "strength",
                        EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * atk_wounded,
                        weapon_id,
                        form_str
                    )
                return
            var outnumbered := is_defender_outnumbered(manager, tgt)
            var dodge_gain := EntityProficiency.GAIN_DODGE_EVADED_BASE
            if outnumbered:
                dodge_gain += EntityProficiency.GAIN_DODGE_OUTNUMBERED_BONUS
            if tgt_tracked:
                var tgt_weapon: String = CombatantEntityAccess.weapon_type_id(tgt)
                var tgt_form: String = CombatantEntityAccess.form_str(tgt)
                # Desirable difficulty: evading a *stronger* foe's strike is a sharper reflex lesson,
                # so the defender's AGI gain scales with the attacker's strength (same factor as the
                # perception read in the same dodge).
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "agility",
                    dodge_gain * def_wounded * EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
                    tgt_weapon,
                    tgt_form
                )
                # XCamp-4: evading reads the attack line (perception) — subordinate to the parry read.
                # Cognitive: not scaled by blood loss, but scaled by execution quality — a dazed fighter
                # reads the attack less sharply, so the perception lesson is smaller. Also scaled by the
                # attacker's difficulty (desirable difficulty): dodging a *stronger* foe's strike is a
                # sharper read, matching the attacker-STR scaling on a clean hit.
                EntityProficiency.award_stat_gain_raw(
                    target_entity,
                    "perception",
                    (
                        EntityProficiency.GAIN_DODGE_READ_PER_BASE
                        * EntityProficiency.execution_quality_factor(target_entity)
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    )
                )
            if atk_tracked:
                EntityProficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * atk_wounded,
                    weapon_id,
                    form_str
                )

        "hit":
            # Attacker hit - STR gain scaled by damage dealt AND opponent difficulty (beating a stronger foe
            # teaches more — desirable-difficulty principle). Write-side gate: tracked attackers only.
            if atk_tracked:
                var dmg: float = result_dict.get(DataKeys.RESULT_DMG, 0)
                var str_gain := (
                    EntityProficiency.GAIN_MELEE_HIT_BASE
                    + minf(
                        dmg / EntityProficiency.GAIN_HIT_STR_DAMAGE_DIVIDER,
                        EntityProficiency.GAIN_MELEE_HIT_MAX_DMG_CONTRIB
                    )
                )
                # Self-relative difficulty (desirable difficulty): a near-level bout is the 1.0 baseline,
                # beating a much stronger foe teaches proportionally more. Sized against the fighter's
                # own strength (atk_str/def_str read at the top of the resolve). 1.0 when no target.
                var hit_difficulty: float = (
                    EntityProficiency.opponent_difficulty_mult(def_str, atk_str) if not tgt.is_empty() else 1.0
                )
                str_gain *= hit_difficulty
                EntityProficiency.award_stat_gain(
                    attacker_entity, "strength", str_gain * atk_wounded, weapon_id, form_str
                )

                # Severe wound bonus (severity from result_dict). A critical landed on a stronger foe is a
                # harder, more valuable lesson, so it scales by the same difficulty factor as the hit STR.
                var wound_severity: String = result_dict.get(DataKeys.RESULT_WOUND_SEVERITY, "")
                if not wound_severity.is_empty():
                    var sev_mult: float = EntityProficiency.get_severity_mult(wound_severity)
                    EntityProficiency.award_stat_gain(
                        attacker_entity,
                        "strength",
                        EntityProficiency.GAIN_SEVERE_WOUND_BASE * sev_mult * hit_difficulty * atk_wounded,
                        weapon_id,
                        form_str
                    )

                var move_id_hit: String = str(
                    result_dict.get(DataKeys.ACTION_MOVE_ID, result_dict.get(DataKeys.ATTACK_ATTACK_TYPE, ""))
                )
                var move_def_hit: Dictionary = (
                    WeaponConstants.get_move(move_id_hit) if not move_id_hit.is_empty() else {}
                )
                var hit_part: String = str(result_dict.get(DataKeys.RESULT_PART, ""))
                var intended_part: String = str(
                    result_dict.get(DataKeys.ACTION_TARGET_PART, result_dict.get(DataKeys.AIM_PART_OVERRIDE, ""))
                )
                var focus_part: String = ""
                if not tgt.is_empty():
                    focus_part = CombatAttention.get_focus_part(tgt)
                # XCamp-4: targeting gains (weapon/form/INT/PER) for the attacker on a clean hit.
                # The enclosing block is already gated on atk_tracked. atk_wounded (blood x execution
                # quality) gates the weapon/form motor gains; execution_quality_factor alone gates the
                # cognitive INT/PER awards (a pained/dazed fighter reads the field less sharply).
                # The weapon/form motor gains scale by the same target-difficulty factor computed
                # above (hit_difficulty): landing a clean hit on a *stronger* foe is a sharper
                # weapon-handling lesson, mirroring the hit STR gain.
                EntityProficiency.notify_targeting_gains_from_hit(
                    attacker_entity,
                    weapon_id,
                    form_str,
                    move_def_hit,
                    hit_part,
                    intended_part,
                    focus_part,
                    atk_wounded,
                    EntityProficiency.execution_quality_factor(attacker_entity),
                    hit_difficulty
                )

            # Defender END gain for absorbing damage. Gated on the write-side tracked flag: only
            # tracked defenders accrue stat bonuses (untracked enemies stay at baseline). The defender's
            # stance form modulates the END (a braced/defensive guard that absorbs force trains more
            # endurance than a loose one) — consistent with the parry-deflect/parry-partial sites.
            if target_entity != null and "_proficiency_bonus" in target_entity and tgt_tracked:
                var dmg_taken: float = result_dict.get(DataKeys.RESULT_DMG, 0)
                var end_gain := (
                    EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE
                    + minf(
                        dmg_taken / EntityProficiency.GAIN_END_DMG_TAKEN_DIVIDER,
                        EntityProficiency.GAIN_DAMAGE_ABSORBED_MAX_CONTRIB
                    )
                )
                var tgt_wep_hit: String = CombatantEntityAccess.weapon_type_id(tgt)
                var tgt_frm_hit: String = CombatantEntityAccess.form_str(tgt)
                EntityProficiency.award_stat_gain(
                    target_entity, "endurance", end_gain * def_wounded, tgt_wep_hit, tgt_frm_hit
                )

        "parry_deflect":
            # Both attacker and defender get wind-up completion gains.
            # Defender also gets END gain for successfully blocking (absorbing parry recoil).
            # Write-side gate: tracked attackers only.
            if atk_tracked:
                EntityProficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    (
                        EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE
                        * EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT
                        * atk_wounded
                    ),
                    weapon_id,
                    form_str
                )
            if not tgt.is_empty() and target_entity != null and "_proficiency_bonus" in target_entity and tgt_tracked:
                var tgt_weapon: String = CombatantEntityAccess.weapon_type_id(tgt)
                var tgt_form: String = CombatantEntityAccess.form_str(tgt)
                # XCamp-4: the parrier's physical gains modulate with their weapon/form — a parry is a
                # defensive weapon act, so STR and END both carry the stance/weapon modifiers (consistent
                # with the hit path's absorbed-END handling). Meeting a *stronger* foe's blade is a harder
                # physical lesson, so both also scale by the desirable-difficulty factor.
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "strength",
                    (
                        EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE
                        * EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT
                        * def_wounded
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    ),
                    tgt_weapon,
                    tgt_form
                )
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "endurance",
                    (
                        EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE
                        * EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT
                        * def_wounded
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    ),
                    tgt_weapon,
                    tgt_form
                )
                # XCamp-4: a clean parry is a fast reactive act — beyond the weapon skill (STR) and force
                # absorption (END), the defender trains reflex/timing (AGI). Smaller than a dodge because a
                # parry is a controlled, localised movement. Gated on the write-side tracked flag. Reacting
                # to a *stronger* foe's faster strike is a harder reflex lesson, so this also scales by the
                # desirable-difficulty factor.
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "agility",
                    (
                        EntityProficiency.GAIN_PARRY_REFLEX_AGI_BASE
                        * def_wounded
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    ),
                    tgt_weapon,
                    tgt_form
                )
                # XCamp-4: a clean parry is a *read* of the incoming attack line — threat detection /
                # anticipation (perception), the sharpest perception lesson in the exchange. Not scaled
                # by blood loss or form/weapon, but scaled by execution quality (a dazed fighter reads
                # less sharply) and by the attacker's difficulty (desirable difficulty: meeting a
                # *stronger* foe's blade is a sharper read). Fires on parry_deflect; a partial parry
                # earns the reduced share below.
                EntityProficiency.award_stat_gain_raw(
                    target_entity,
                    "perception",
                    (
                        EntityProficiency.GAIN_PARRY_READ_PER_BASE
                        * EntityProficiency.execution_quality_factor(target_entity)
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    )
                )
                # XCamp-4: a clean parry is a precise defensive weapon act — the parrier trains
                # their own weapon/form (documented: fires on parry_deflect and parry_partial).
                # Gated by the defender's execution-quality x blood-loss composite like the
                # other parry physical gains, and scaled by the attacker's difficulty (meeting a
                # stronger foe's blade is a harder weapon-control rep).
                if tgt_tracked:
                    EntityProficiency.award_weapon_proficiency(
                        target_entity,
                        tgt_weapon,
                        (
                            EntityProficiency.GAIN_PARRY_WEAPON_PROF_BASE
                            * def_wounded
                            * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                        )
                    )
                    EntityProficiency.award_form_proficiency(
                        target_entity,
                        tgt_form,
                        (
                            EntityProficiency.GAIN_PARRY_FORM_PROF_BASE
                            * def_wounded
                            * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                        )
                    )

        "parry_partial":
            # Attacker gets partial STR gain; defender gets a partial END gain for absorbing the reduced hit
            # (a partial parry still transmits some force into the defender's arm — less than a full deflect).
            # Write-side gate: tracked attackers only.
            if atk_tracked:
                EntityProficiency.award_stat_gain(
                    attacker_entity,
                    "strength",
                    (
                        EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE
                        * EntityProficiency.GAIN_PARRY_PARTIAL_STR_MULT
                        * atk_wounded
                    ),
                    weapon_id,
                    form_str
                )
            if not tgt.is_empty() and target_entity != null and "_proficiency_bonus" in target_entity and tgt_tracked:
                var tgt_weapon: String = CombatantEntityAccess.weapon_type_id(tgt)
                var tgt_form: String = CombatantEntityAccess.form_str(tgt)
                # Desirable difficulty: a partial parry still met a *stronger* foe's line, so the
                # absorbed-END lesson scales with the attacker's strength, matching the PER read.
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "endurance",
                    (
                        EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE
                        * EntityProficiency.GAIN_PARRY_PARTIAL_END_MULT
                        * def_wounded
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    ),
                    tgt_weapon,
                    tgt_form
                )
                # XCamp-4: a partial parry still met the line — reflex/timing was exercised, just less
                # cleanly than a full deflect, so the parrier earns a reduced AGI reflex gain. Also
                # scales by the desirable-difficulty factor (meeting a stronger foe's line is harder).
                EntityProficiency.award_stat_gain(
                    target_entity,
                    "agility",
                    (
                        EntityProficiency.GAIN_PARRY_REFLEX_AGI_BASE
                        * EntityProficiency.GAIN_PARRY_PARTIAL_AGI_MULT
                        * def_wounded
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    ),
                    tgt_weapon,
                    tgt_form
                )
                # XCamp-4: a partial parry still met the line — the read was right, the execution just
                # fell short, so the parrier earns a reduced perception read (same 0.3 partial fraction
                # as the other parry awards). Not blood- or form-scaled, but scaled by execution
                # quality (a dazed fighter reads less sharply) and by the attacker's difficulty
                # (desirable difficulty: reading a *stronger* foe is a sharper lesson).
                EntityProficiency.award_stat_gain_raw(
                    target_entity,
                    "perception",
                    (
                        EntityProficiency.GAIN_PARRY_READ_PER_BASE
                        * EntityProficiency.GAIN_PARRY_PARTIAL_PER_MULT
                        * EntityProficiency.execution_quality_factor(target_entity)
                        * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                    )
                )
                # XCamp-4: a partial parry still met the line — the parrier trains their weapon/form
                # too, gated by the defender's execution-quality x blood-loss composite and scaled by
                # the attacker's difficulty (meeting a stronger foe's line is a harder weapon-control rep).
                if tgt_tracked:
                    EntityProficiency.award_weapon_proficiency(
                        target_entity,
                        tgt_weapon,
                        (
                            EntityProficiency.GAIN_PARRY_WEAPON_PROF_BASE
                            * def_wounded
                            * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                        )
                    )
                    EntityProficiency.award_form_proficiency(
                        target_entity,
                        tgt_form,
                        (
                            EntityProficiency.GAIN_PARRY_FORM_PROF_BASE
                            * def_wounded
                            * EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
                        )
                    )

        "defeated":
            # No proficiency gains on defeated action.
            pass

        _:
            # skip - no gains
            pass


## Phase 2: evaluate whether a counter-read switch was correct by comparing the defender's actual form at action start
## against their inferred form.
static func evaluate_counter_read_outcome(
    manager: Node, attacker_id: int, target_id: int, defender_form_at_parry: String
) -> void:
    if manager == null or attacker_id < 0 or target_id < 0:
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty():
        return
    ## Check if the attacker had a counter-read commitment stamp — this means they auto-switched based on inference.
    if not CombatWeaponForm.is_counter_read_committed(atk, manager.combat_clock):
        return
    ## The defender's actual form at action start was captured and stored on the attacker.
    ## If the attacker switched to a counter-form expecting that form but got something else, record wrong.
    var inferred_key: String = CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID
    var cache_raw: Variant = atk.get(inferred_key, null)
    if cache_raw is not Dictionary:
        return
    var cached_val: Variant = (cache_raw as Dictionary).get(str(target_id), "")
    if cached_val is String and not str(cached_val).is_empty():
        var inferred_form: String = str(cached_val).strip_edges()
        var success: bool = defender_form_at_parry.strip_edges() == inferred_form
        CombatWeaponForm.record_counter_read_outcome(atk, target_id, success, inferred_form)
        CombatAttention.record_deception_outcome(atk, target_id, success)
        # XCamp-4: a committed counter-read outcome trains perception regardless of correctness
        # (a wrong read still teaches what that line was NOT). Not form-scaled, but scaled by the
        # reader's execution quality — a dazed fighter reads the opponent's form less reliably — and
        # by the target's difficulty (desirable difficulty: predicting a *stronger* foe's form is a
        # sharper read). Here the reader is the attacker, so the target (defender) is the foe.
        var atk_ent: Node = CombatantEntityAccess.scene_node(atk)
        if atk_ent != null and EntityProficiency.is_stat_gain_tracked(atk_ent):
            var per_amount: float = (
                EntityProficiency.GAIN_COUNTER_READ_CORRECT_PER_BASE
                if success
                else EntityProficiency.GAIN_COUNTER_READ_WRONG_PER_BASE
            )
            per_amount *= EntityProficiency.execution_quality_factor(atk_ent)
            var atk_str: float = CombatantEntityAccess.stats_dict(atk).get(
                DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
            )
            var def_dict: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
            var def_str: float = EntityProficiency.GAIN_DIFFICULTY_STR_BASE
            if not def_dict.is_empty():
                def_str = CombatantEntityAccess.stats_dict(def_dict).get(
                    DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
                )
            per_amount *= EntityProficiency.opponent_difficulty_mult(def_str, atk_str)
            EntityProficiency.award_stat_gain_raw(atk_ent, "perception", per_amount)


## Checks if the defender combatant is the last alive in their slot group (outnumbered).
static func is_defender_outnumbered(manager: Node, defender: Dictionary) -> bool:
    var slot_key: String = defender.get(DataKeys.COMBATANT_SLOT_KEY, "")
    if slot_key.is_empty():
        return false
    var slot_group: String = slot_key.get_slice("_", 0) if "_" in slot_key else ""
    if slot_group.is_empty():
        return false
    var defender_side := CombatantEntityAccess.side_str(defender)
    var count_alive_in_group: int = 0
    if not manager.has_method("get_combatants"):
        return false
    for c in manager.get_combatants():
        if not c is Dictionary:
            continue
        if not CombatantEntityAccess.side_str(c) == defender_side:
            continue
        var c_slot: String = c.get(DataKeys.COMBATANT_SLOT_KEY, "").get_slice("_", 1)
        if c_slot != slot_group:
            continue
        if not CombatantEntityAccess.alive_bool(c):
            continue
        count_alive_in_group += 1
    return count_alive_in_group <= 1
