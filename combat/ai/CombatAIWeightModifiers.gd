class_name CombatAIWeightModifiers
extends RefCounted

## AI action-weight modifier functions extracted from CombatAIActionWeights (pure code-motion split).
## All functions are static and stateless; delegates in CombatAIActionWeights preserve call-site compatibility.


## Open/guarded line bias for move selection. A fencer attacks the line the defender is NOT
## covering, not the line the defender is holding. alignment (0..1) is how on-line the
## move is: 1.0 = same line as the guard (fully guarded, discounted), 0.0 = fully open
## (full bonus). The mapping is continuous so 45-degree adjacent lines fall in between.
## Exempt (1.0) for reactive counter-tempo actions, which are deliberately in-line.
## Feints DO take the bias: a feint only draws a response when it presents an open line,
## and every feint shares the attack_line of its plain counterpart, so the factor cancels
## in the feint/plain weight ratio (locked by the feint_listing harness invariants).
## Exception: if the defender's guard was just committed/displaced on a line by a feint
## (live PA_FEINT_OPEN_LINE window), that line is NOT guarded — the defense model already
## discounts parry on it, so the offensive bias must not treat it as "on the guard line"
## either (doing so would cancel the feint_open_line_m press). The discount scales with
## live open-line openness (CombatGuardLines.open_line_openness: eased time decay over the
## window), so the guarded discount re-earns itself as the open-line window closes.
## Depends on line alignment + feint-open-line state; never on defender footwork/off-balance
## (locked by the feint_list settled/recov footwork harness invariants; the open-line
## window is absent in those fixtures, so the invariants are untouched).
static func open_guard_line_weight_mult(
    atk_line: String, guard_line: String, move_id: String, defender: Dictionary, is_counter_tempo: bool
) -> float:
    if atk_line.is_empty() or guard_line.is_empty():
        return 1.0
    if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        return 1.0
    if is_counter_tempo:
        return 1.0
    var align: float = CombatConstants.get_line_alignment(atk_line, guard_line)
    # A line the defender's guard was just committed/displaced on (feint open-line window)
    # is not actually guarded: the defense model already discounts parry on it, so treat it
    # as open here. This keeps the offensive open/guarded bias consistent with the defensive
    # parry model and stops the guarded-line discount from eating the feint_open_line_m press.
    # The discount is scaled by live openness (eased time decay over the window): at the moment
    # the line was opened it reads fully open; as the off-balance/stagger window closes the guarded
    # discount gradually returns. Fresh fixtures have no live open-line, so invariants hold.
    var open_now: String = _defender_live_feint_open_line(defender)
    if not open_now.is_empty() and CombatGuardLines.normalize_line(atk_line) == open_now:
        var openness: float = CombatGuardLines.open_line_openness(defender)
        align = align * (1.0 - openness)
    return lerpf(CombatConstantsAIWeights.AI_OPEN_LINE_MULT, CombatConstantsAIWeights.AI_GUARDED_LINE_MULT, align)


## Line-memory repeat suppression: after a strike on a given line fails (miss/parry/dodge),
## the AI briefly de-weights re-attacking that same line so it varies under pressure.
## The penalty decays linearly to 1.0 over AI_LINE_FAIL_DECAY_WINDOW_S on the combat clock.
## A successful hit clears the entry (handled in AttackResultApplier), so pressing an
## advantage is unaffected.
static func line_fail_weight_mult(attacker: Dictionary, candidate_line: String, manager: Node) -> float:
    if candidate_line.is_empty():
        return 1.0
    var mem: Dictionary = attacker.get(DataKeys.ATTACK_LINE_FAIL_MEMORY, {})
    if not mem.has(candidate_line):
        return 1.0
    var last_fail: float = float(mem[candidate_line])
    var now: float = manager.combat_clock
    var age: float = now - last_fail
    var window: float = CombatConstantsAIWeights.AI_LINE_FAIL_DECAY_WINDOW_S
    if age >= window or age < 0.0:
        return 1.0
    var recency: float = 1.0 - age / window
    return lerpf(1.0, CombatConstantsAIWeights.AI_LINE_FAIL_PENALTY_FLOOR, recency)


## Proactive yomi line variation: a candidate line the attacker has been leaning on
## recently (per the target's yomi recent-window counts) is getting readable. De-weight
## it so the AI varies BEFORE the defender's guard drift fully matures. Complement to
## line_fail_weight_mult: that reacts to a line that FAILED; this reacts to a line USED
## A LOT, regardless of outcome. Kept mild (FLOOR 0.85) and share-scaled so it only
## nudges — a working open line is still preferred via the open/guarded bias, which
## dominates this term. If every available strike is on the same line, all get the same
## factor and the relative ordering is unchanged, so it never punishes a genuine
## single-line weapon.
static func yomi_vary_weight_mult(defender: Dictionary, attacker_id: int, candidate_line: String) -> float:
    if candidate_line.is_empty() or defender.is_empty():
        return 1.0
    var entry: Dictionary = CombatAttention.yomi_entry_for_attacker(defender, attacker_id)
    if entry.is_empty():
        return 1.0
    var counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_RECENT_LINE_COUNTS, {}) as Dictionary
    var n_this: int = int(counts.get(candidate_line, 0))
    if n_this < CombatConstantsAIWeights.AI_YOMI_VARY_MIN_RECENT:
        return 1.0
    var n_total: int = 0
    for raw in counts.values():
        n_total += int(raw)
    if n_total <= 0:
        return 1.0
    var share: float = clampf(float(n_this) / float(n_total), 0.0, 1.0)
    return lerpf(1.0, CombatConstantsAIWeights.AI_YOMI_VARY_FLOOR, share)


## Returns the defender's currently-live feint-open line (normalized), or "" if none.
## A feint that just committed/displaced the guard leaves that line open for the
## PA_FEINT_OPEN_LINE window. Shared by open_guard_line_weight_mult (which must NOT
## treat that line as guarded) and _feint_open_line_mult (the follow-up press) so the
## two factors agree on which line is open.
static func _defender_live_feint_open_line(defender: Dictionary) -> String:
    if defender.is_empty():
        return ""
    var until: float = float(defender.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, -1.0))
    if until <= 0.0 or CombatTiming.now_seconds() >= until:
        return ""
    var open_line: String = str(defender.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if open_line.is_empty():
        return ""
    return CombatGuardLines.normalize_line(open_line)


## Feint open-line follow-up: when a feint just landed and the target's guard is still
## displaced on a line for the PA_FEINT_OPEN_LINE window, boost striking that same line —
## press the opening the feint drew. Mirrors the defensive reader
## (DefenseChoiceResolver._feint_open_line_parry_mult): same normalize_line match, but turns
## the live open-line openness (CombatGuardLines.open_line_openness: eased time decay over
## the window) into a weight boost instead of a parry penalty. Gated to honest strikes only at
## the call site (a feint on an already-open line is inert). Mild and windowed by design:
## the press peaks right after the feint and decays linearly as the window closes, without
## overpowering stamina/timing.
static func _feint_open_line_mult(defender: Dictionary, candidate_line: String) -> float:
    if candidate_line.is_empty():
        return 1.0
    var open_now: String = _defender_live_feint_open_line(defender)
    if open_now.is_empty() or CombatGuardLines.normalize_line(candidate_line) != open_now:
        return 1.0
    var openness: float = CombatGuardLines.open_line_openness(defender)
    return lerpf(1.0, CombatConstantsAIWeights.AI_FEINT_OPEN_LINE_FOLLOWUP_TOP_MULT, openness)


## Feint repeat-read damp: after a feint on a line gets PARRIED, the defender demonstrably
## covered that line — re-telegraphing it is the least realistic choice. This de-weights
## feint moves that repeat a just-parried line harder than the generic line_fail_m (which
## damps ALL moves on any just-failed line to AI_LINE_FAIL_PENALTY_FLOOR). Stacked: a feint
## on a parrued line takes ~floor*0.60 vs an honest strike's ~floor, so the AI steers to
## committing or varying rather than re-running the same feint.
##
## Keyed on the PARRY record specifically (ATTACK_LINE_PARRY_MEMORY), not any failure: a
## missed feint is not a read (no reaction was drawn), and a dodged feint opens the line
## (the open-line factors should encourage a commit there, not suppress re-feints). Only a
## parry is true "the defender expects this line" evidence. Mirrors line_fail_weight_mult's
## clock/window/recency. Fresh fixtures / honest moves / unparrued lines all return 1.0, so
## the pinned feint/plain ratios and footwork invariants are untouched.
static func _feint_read_fail_mult(
    attacker: Dictionary, candidate_line: String, move_id: String, manager: Node
) -> float:
    if not WeaponConstants.is_feint_move(move_id):
        return 1.0
    if candidate_line.is_empty():
        return 1.0
    var mem: Dictionary = attacker.get(DataKeys.ATTACK_LINE_PARRY_MEMORY, {})
    if not mem.has(candidate_line):
        return 1.0
    var last_parry: float = float(mem[candidate_line])
    var age: float = manager.combat_clock - last_parry
    var window: float = CombatConstantsAIWeights.AI_LINE_FAIL_DECAY_WINDOW_S
    if age >= window or age < 0.0:
        return 1.0
    var recency: float = 1.0 - age / window
    return lerpf(1.0, CombatConstantsAIWeights.AI_FEINT_REPEAT_FAIL_DAMP, recency)


## IV-11: doctrine-context weight for party leader / enemy commander instant orders.
static func _leader_formation_command_pick_weight(manager: Node, c: Dictionary, move_id: String) -> float:
    var w: float = CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
    if move_id != CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
        return w
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if fid.is_empty():
        return w
    if CombatDoctrine.numeric_superiority_for_pinch(manager, fid):
        w *= CombatConstants.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
    var mood_bias: float = CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
    w *= CombatCampaignMoodBias.offense_action_weight_mult(mood_bias)
    return w


## LONG band, close listed but no melee strikes '"" mapped rank-0 band-lag shuffle (not bind-close wings).
static func _long_close_only_offense_menu(manager: Node, c: Dictionary, combatant_id: int, all_actions: Array) -> bool:
    if manager == null or c.is_empty() or combatant_id < 0 or all_actions.is_empty():
        return false
    if CombatListedActions.action_list_has_hostile_melee_strike(all_actions, combatant_id):
        return false
    if EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
        return false
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if CombatDoctrine.envelop_mop_up_active(manager, fid):
        return false
    if CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
        return false
    if EngagementOpposition.wing_lacks_mapped_opposition(manager, c):
        return false
    if not CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
        return false
    for raw in all_actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw as Dictionary
        if a.get(DataKeys.ACTION_MOVE_ID, "") != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tid: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tid < 0:
            continue
        if CombatantEntityAccess.distance_to_opponent_band(c, tid, "") != CombatConstants.DISTANCE_LONG:
            continue
        if CombatMeleeListing.attempt_close_listed_for_pair(manager, c, tid, CombatConstants.DISTANCE_LONG):
            return true
    return false


## MS-L8: post-strike weight bonus '"" apply multiplicative boost to strikes vs recently struck target.


## MS-L8: post-strike weight bonus '"" apply multiplicative boost to strikes vs recently struck target.
static func _post_strike_weight_mult(c: Dictionary, a: Dictionary, manager: Node) -> float:
    if not CombatConstants.is_feature_ms_post_strike_enabled():
        return 1.0
    var strike_tick_val: float = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0)
    if strike_tick_val <= 0.0:
        return 1.0
    var current_clock: float = manager.combat_clock
    if absf(strike_tick_val - current_clock) >= CombatConstants.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE:
        return 1.0
    # Stamp is active '"" check if this action targets the struck combatant.
    var struck_id: int = c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID, -1)
    if struck_id < 0:
        return 1.0
    var tid: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
    if tid != struck_id:
        return 1.0
    var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
    if CombatConstants.is_medical_move(mid):
        return 1.0
    if mid == CombatConstants.MOVE_ID_WAIT or mid == CombatConstants.MOVE_ID_FLEE:
        return 1.0
    if CombatConstants.is_formation_movement_move(mid):
        return 1.0
    # This is a strike/close vs the recently struck target '"" apply bonus.
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid)
    if tgt.is_empty() or not CombatantEntityAccess.alive_bool(tgt):
        return 1.0
    # Check if defender was forced to parry (has parry_against_id set).
    var parry_forced: bool = (
        tgt.has(DataKeys.PA_PARRY_AGAINST_ID) and int(tgt.get(DataKeys.PA_PARRY_AGAINST_ID, -1)) >= 0
    )
    if parry_forced:
        return CombatConstants.POST_STRIKE_MOMENTUM_WEIGHT_BONUS
    return CombatConstants.POST_STRIKE_HIT_WEIGHT_BONUS


## Phase 2: Feint resistance gate '"" returns true when defender has high readiness and is not off-balance.
## Swordmaster teaching: "Do not react to the feint - wait for the real attack."
## Threshold >0.75 means: settled fighter with decent guard (>=0.80) rejects feints;
## recovering fighter must be >89% through recovery (0.75 / 0.85 curve max).
static func _is_feint_resistance_active(defender_id: int, manager: Node) -> bool:
    if defender_id < 0:
        return false
    var defender: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
    if defender.is_empty():
        return false
    var readiness: float = PassiveParryContext.get_passive_parry_readiness(defender)
    if readiness <= 0.75:
        return false
    var state: String = CombatantEntityAccess.state_str(defender)
    if state == CombatConstants.STATE_WIND_UP:
        return false
    if PassiveParryContext.is_off_balance(defender):
        return false
    return true


## When mental stack is on but no layer fired: high **`attention_load`** dampens offensive picks (still weighted, not
## hard block).
## Combat-finish tails (sparse / mop-up) skip salience damp so fights actually end.
static func _salience_offense_weight_mult(c: Dictionary, manager: Node = null) -> float:
    if not CombatConstants.is_feature_mental_stack_ai_enabled():
        return 1.0
    if not CombatAttention.enabled():
        return 1.0
    if manager != null and not c.is_empty():
        var fid_sal: String = CombatantEntityAccess.formation_id_str(c)
        if (
            CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid_sal)
            or CombatDoctrine.envelop_mop_up_active(manager, fid_sal)
            or CombatDoctrine.mop_up_underdog_active(manager, c)
        ):
            return 1.0
    var attention_load: float = CombatAttention.get_attention_load(c)
    if attention_load <= 0.05:
        return 1.0
    return lerpf(1.0, 1.0 - CombatConstants.MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX, attention_load)


## Duel/skirmish (few standing on side): damp routine offense.
## Skip damp on post-flee sparse lines and mop-up tails '"" low headcount should finish, not idle.


## Duel/skirmish (few standing on side): damp routine offense.
## Skip damp on post-flee sparse lines and mop-up tails '"" low headcount should finish, not idle.
static func _attrition_offense_weight_mult(manager: Node, c: Dictionary) -> float:
    if manager == null:
        return 1.0
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if CombatDoctrine.envelop_mop_up_active(manager, fid):
        return 1.0
    if CombatDoctrine.mop_up_underdog_active(manager, c):
        return 1.0
    if CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
        return 1.0
    var side: String = CombatantEntityAccess.side_str(c)
    var standing: int = CombatEngagementMode.count_active_for_side(manager, side)
    if standing <= int(CombatConstants.AI_ATTRITION_LOW_STANDING_MAX):
        return CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT
    return 1.0


## Fight-finish tails (sparse / mop-up / underdog): damp focus shuffle when strikes/close are listed.
static func _fight_finish_focus_damp_mult(manager: Node, c: Dictionary, combatant_id: int, all_actions: Array) -> float:
    if manager == null or c.is_empty() or all_actions.is_empty():
        return 1.0
    if not CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
        return 1.0
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, all_actions, combatant_id):
        return 1.0
    return CombatConstants.AI_FOCUS_LINE_SPARSE_ENGAGEMENT_LISTED_MULT


## Tier 4.3.7: focus-line retarget '"" party lead favors matching incoming telegraph; others rarely shift.
static func _focus_line_action_weight(
    move_id: String, combatant_id: int, manager: Node, c: Dictionary, all_actions: Array = []
) -> float:
    if not CombatAttention.enabled():
        return 0.0
    var line: String = CombatConstants.guard_line_for_focus_move_id(move_id)
    if line.is_empty():
        return 0.0
    var cur_line: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
    if cur_line == line:
        return 0.0
    var part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(line, "")
    var fid_focus: String = CombatantEntityAccess.formation_id_str(c)
    var mood_focus_mult: float = CombatCampaignMoodBias.focus_line_action_weight_mult(
        CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
    )
    if part.is_empty() or part == CombatAttention.get_focus_part(c):
        var already_w: float = CombatConstants.AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT
        if CombatDoctrine.envelop_mop_up_active(manager, fid_focus):
            already_w *= CombatConstants.ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT
        already_w *= _form_focus_preferred_mult(c, line)
        already_w *= _fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)
        already_w *= mood_focus_mult
        return already_w
    if (
        CombatantEntityAccess.is_formation_telegraph_leader(c)
        and CombatAttention.is_being_wind_up_targeted(manager, combatant_id)
    ):
        var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
        var tele_line: String = CombatConstants.PART_TO_LINE.get(tele, "")
        if tele_line == line:
            var leader_w: float = CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
            if CombatDoctrine.envelop_mop_up_active(manager, fid_focus):
                leader_w *= CombatConstants.ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT
            leader_w *= _form_focus_preferred_mult(c, line)
            leader_w *= _fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)
            leader_w *= mood_focus_mult
            return leader_w
    var w: float = CombatConstants.AI_FOCUS_LINE_BASE_WEIGHT
    if CombatDoctrine.envelop_mop_up_active(manager, fid_focus):
        w *= CombatConstants.ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT
    w *= _form_focus_preferred_mult(c, line)
    w *= _fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)
    w *= _guard_priority_focus_mult(c, line)
    w *= mood_focus_mult
    return w


## Tier 4.3.8: focus-line weight boost when the move's line matches the guard-priority target line and
## priority is high — lets a braced unit "hold + position" compete with routine strikes (utility pick
## path; L4G stack layer fires first). Reads the cached target line stamped by drift to avoid re-scanning.
static func _guard_priority_focus_mult(c: Dictionary, line: String) -> float:
    var score: float = float(c.get(CombatConstants.COMBATANT_KEY_GUARD_PRIORITY, 0.0))
    if score < CombatConstantsMentalStack.GUARD_PRIORITY_MIN_SCORE:
        return 1.0
    var cached_target: String = str(c.get(CombatConstants.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE, "")).strip_edges()
    if cached_target.is_empty() or cached_target != line:
        return 1.0
    return lerpf(1.0, CombatConstantsMentalStack.GUARD_PRIORITY_FOCUS_WEIGHT_TOP, score)


static func _form_focus_preferred_mult(c: Dictionary, line: String) -> float:
    var form: String = CombatantEntityAccess.form_str(c)
    for pg in CombatWeaponForm.preferred_guards(form, CombatantEntityAccess.get_weapon(c)):
        if pg == line:
            return CombatConstants.AI_FOCUS_LINE_FORM_PREFERRED_MULT
    return 1.0


## Controlling opponent front rank → ' lower disengage listing weight (pairs with duration mult).


## Controlling opponent front rank → ' lower disengage listing weight (pairs with duration mult).
static func _opponent_controlling_disengage_listing_divisor(manager: Node, c: Dictionary) -> float:
    if manager == null or c.is_empty():
        return 1.0
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if fid.is_empty():
        return 1.0
    return maxf(1.0, ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(manager, fid))


## Tier 1.9 (P10): when depth spear lane is open **and** at least one **valid line** rank-0 hostile exists, prefer
## thrusts; de-emphasize closing (thrust works from MID).
## Formation **`doctrine`** (`pinch_center` / `hold_lane` / `probing`) nudges stab vs cut weights (Tier 1.9 optional
## coupling).


## Tier 1.9 (P10): when depth spear lane is open **and** at least one **valid line** rank-0 hostile exists, prefer
## thrusts; de-emphasize closing (thrust works from MID).
## Formation **`doctrine`** (`pinch_center` / `hold_lane` / `probing`) nudges stab vs cut weights (Tier 1.9 optional
## coupling).
static func _depth_polearm_action_weight_mult(
    manager: Node, c: Dictionary, move_id: String, actor_zone_geometry_line_context: Dictionary = {}
) -> float:
    if manager == null or c.is_empty():
        return 1.0
    var fid_depth: String = (
        ZoneOfControl.zone_geometry_fid_from_pack(actor_zone_geometry_line_context)
        if not actor_zone_geometry_line_context.is_empty()
        else ZoneOfControl.zone_geometry_fid_str(manager, c)
    )
    if not CombatDepthPolearm.depth_polearm_lane_open(manager, c, fid_depth):
        return 1.0
    if not CombatDepthPolearm.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(manager, c, manager.combatants):
        return 1.0
    if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        return CombatConstants.DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT
    var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
    # Doctrine keys use home roster **`formation_id`**.
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if ct == WeaponConstants.ATTACK_TYPE_STAB:
        var w: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT
        var doc: String = CombatDoctrine.doctrine_for_fid(manager, fid)
        match doc:
            CombatConstants.DOCTRINE_PINCH_CENTER:
                w *= manager.get_depth_polearm_ai_doctrine_mult(
                    fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB
                )
            CombatConstants.DOCTRINE_HOLD_LANE:
                w *= manager.get_depth_polearm_ai_doctrine_mult(
                    fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB
                )
            CombatConstants.DOCTRINE_PROBING:
                w *= manager.get_depth_polearm_ai_doctrine_mult(
                    fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB
                )
        return w
    if ct == WeaponConstants.ATTACK_TYPE_CUT or ct == WeaponConstants.ATTACK_TYPE_BLUNT:
        var w2: float = CombatConstants.DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT
        var doc2: String = CombatDoctrine.doctrine_for_fid(manager, fid)
        match doc2:
            CombatConstants.DOCTRINE_HOLD_LANE:
                w2 *= manager.get_depth_polearm_ai_doctrine_mult(
                    fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB
                )
            CombatConstants.DOCTRINE_PINCH_CENTER:
                w2 *= manager.get_depth_polearm_ai_doctrine_mult(
                    fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB
                )
            CombatConstants.DOCTRINE_PROBING:
                w2 *= manager.get_depth_polearm_ai_doctrine_mult(
                    fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB
                )
        return w2
    return 1.0


## Fitness for formation positioning: performance (attack capability) →  health (blood). Higher = more able to
## fight.
## Used for swap rank: lowest fitness should be in back. Does not use stamina/action-ready.


## Fitness for formation positioning: performance (attack capability) →  health (blood). Higher = more able to
## fight.
## Used for swap rank: lowest fitness should be in back. Does not use stamina/action-ready.
static func _get_positioning_fitness(c: Dictionary) -> float:
    var perf: float = CombatantEntityAccess.get_performance_modifier(c)
    var n: Node = CombatantEntityAccess.scene_node(c)
    var health: float = clampf(CombatantEntityAccess.get_blood_volume_from_node(n) / 100.0, 0.0, 1.0)
    return perf * health


## V5 HEMA realism fix: scale attack weight based on opponent's degraded state.
## Wounded opponents are easier to hit — AI should exploit this like a real fighter would.
static func _opponent_degradation_weight_mult(manager: Node, target_id: int) -> float:
    if manager == null or target_id < 0:
        return 1.0
    var tgt = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if tgt.is_empty():
        return 1.0
    var mult: float = 1.0
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, tgt)
    if entity != null and entity.has_method("_get_wounds"):
        var wounds_dict: Dictionary = entity._get_wounds()
        var total_damage: float = 0.0
        var part_count: int = 0
        for part_key in wounds_dict:
            var injuries: Array = wounds_dict[part_key]
            if injuries.is_empty():
                continue
            part_count += 1
            for inj in injuries:
                total_damage += EntityProficiency.SEVERITY_MULT.get(inj.get("severity", ""), 1.0)
        if part_count > 0:
            var max_possible: float = part_count * 2.0
            var wound_ratio: float = clampf(total_damage / max(max_possible, 0.001), 0.0, 1.0)
            if wound_ratio > 0.3:
                mult *= lerpf(
                    1.0, CombatConstants.AI_WOUNDED_OPPONENT_WEIGHT_MULT, clampf((wound_ratio - 0.3) / 0.7, 0.0, 1.0)
                )
    return mult
