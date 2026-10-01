class_name CombatEndDuelFeintTests

extends CombatRegressionHarnessCore

## Combat-end, duel, and feint: enemy-win stops the manager, duel auto-end detection, and feint second windup
## clears prior telegraph before restamp.


static func _run_combat_end_enemy_win_stops_manager(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var ent_player := _new_entity("SWORD")
    mgr.register(ent_player, "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.set_process(true)
    var ended_box: Array = [0]
    mgr.combat_ended.connect(func(_w: String, _d: Node) -> void: ended_box[0] = int(ended_box[0]) + 1)
    mgr._end_combat_phase("enemy", ent_player)
    if not mgr.medical_phase:
        _fail(failures, "combat_end_enemy_win: medical_phase should be set true for halt_losing_side")
    if mgr.is_processing():
        _fail(failures, "combat_end_enemy_win: manager should stop processing")
    if not mgr.combat_resolution_closed:
        _fail(failures, "combat_end_enemy_win: combat_resolution_closed should be true")
    for _i in 24:
        ProcessTick.tick(mgr, 0.05)
    if int(ended_box[0]) != 1:
        _fail(
            failures,
            "combat_end_enemy_win: combat_ended should emit once after manual ticks (got %d)" % int(ended_box[0])
        )
    _free_manager(mgr)


## Tier 5.0: full-stop **`duel_auto_end_detection`** — runs a seeded 1v1 SWORD duel for up to 120 s, asserts combat
## resolves (medical_phase or single survivor). Validates the auto-end chain (winner check -> phase end -> manager stop)
## under full AI-driven simulation.
## Realism note: armored sword duels run longer than a minute (seeded SWORD duel resolves ~68 s, up to ~76 s across
## weapons), so the budget is 120 s — generous vs. real fight length while still bounded.


static func _run_duel_auto_end_detection(failures: PackedStringArray) -> void:
    seed(42)
    var mgr: Node = MgrScript.new()
    # A gladiator duel is between trained professionals, not random bandits: both sides are
    # proficiency-tracked veterans with full weapon/form familiarity and seasoned stat bonuses.
    # This matches the fixture the auto-end budget was calibrated against — untracked bandits no
    # longer accrue mid-fight proficiency (write-side gate), so an even 1v1 of untrained fighters
    # can outlast the budget instead of resolving as a real duel does.
    var p_ent: CoreEntity = _new_entity("SWORD")
    var e_ent: CoreEntity = _new_entity("SWORD")
    for ent in [p_ent, e_ent]:
        ent._combat_skill_trained = true
        ent._weapon_proficiency["SWORD"] = EntityProficiency.WEAPON_PROF_VETERAN_MAX
        ent._form_proficiency[CombatWeaponForm.FORM_BALANCED] = EntityProficiency.FORM_PROF_VETERAN_MAX
        for stat in EntityStatsUtil.PROFICIENCY_STATS:
            ent._proficiency_bonus[stat] = 10.0
    mgr.register(p_ent, "player")
    mgr.register(e_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var elapsed: float = 0.0
    const MAX_TICKS := 2400
    for _i in MAX_TICKS:
        for c in mgr.combatants:
            if c is not Dictionary:
                continue
            if not EntityAccess.alive_bool(c):
                continue
            if bool(c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)):
                continue
            var st: String = EntityAccess.state_str(c)
            if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
                continue
            if EntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
                continue
            var cid: int = EntityAccess.id_int(c)
            var actions: Array = mgr.get_available_actions(cid)
            var log_side: String = "player" if EntityAccess.is_player_side(c) else "enemy"
            AIPicker.resolve_picked_turn_or_skip(mgr, cid, actions, log_side)
        ProcessTick.tick(mgr, 0.05)
        elapsed += 0.05
        if mgr.medical_phase:
            break
    var players_alive := 0
    var enemies_alive := 0
    for c in mgr.combatants:
        if c is not Dictionary or not EntityAccess.alive_bool(c):
            continue
        if bool(c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)):
            continue
        if EntityAccess.is_player_side(c):
            players_alive += 1
        else:
            enemies_alive += 1
    var single_survivor := (players_alive + enemies_alive) == 1 and (players_alive + enemies_alive) > 0
    if not mgr.medical_phase and not single_survivor:
        _fail(
            failures,
            (
                "duel_auto_end_timeout: clock=%.2f medical_phase=%s player_alive=%d enemy_alive=%d"
                % [elapsed, str(mgr.medical_phase), players_alive, enemies_alive]
            )
        )
    _free_manager(mgr)


## Tier 4.3: mental stack L1 picks medical when ally in peril.

## Tier 4.3: mental stack L1 picks medical when ally in peril.


static func _run_feint_second_windup_clears_prior_telegraph_before_restamp(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(_FEINT_WINDUP_HARNESS_SEED)
    WindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "left_leg", "feint_part": "head"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
        _fail(
            failures,
            (
                "feint_rewind: first telegraph want head got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    seed(_FEINT_WINDUP_HARNESS_SEED)
    WindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "right_leg", "feint_part": "chest"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "chest":
        _fail(
            failures,
            (
                "feint_rewind: second telegraph want chest got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    if str(e.get("guard_zone", "")) != "chest":
        _fail(failures, "feint_rewind: second guard_zone telegraph want chest got %s" % str(e.get("guard_zone", "")))
    _free_manager_restore_global_rng(mgr)

## Tier 3.0 (+ Tier 5 damage-flow anchor): **`WeaponDamageHelper.kinematic_delivery`** overrides move inference;
## **`kinematic_mixed_blend`** **0** / **1** KE + effective velocity match pure thrust / swing at the same move +
## intensity; interior blend **0.5** velocity = **`lerp`** of pure thrust vs pure swing speeds; mixed blend **0.5** KE =
## **`lerp`** of thrust vs swing KE **at that same blended `v`** (not **`lerp`** of pure-mode KE at each mode's
## **`v`**). Repeats the mixed **0** / **0.5** / **1** bracket checks on **AXE** **`diagonal_chop`** and **DAGGER**
## **`quick_slash`** (extra cut fixtures; **`spear_slash`** can degenerate thrust/swing KE at some intensities).

## Tier 3.0 (+ Tier 5 damage-flow anchor): **`WeaponDamageHelper.kinematic_delivery`** overrides move inference;
## **`kinematic_mixed_blend`** **0** / **1** KE + effective velocity match pure thrust / swing at the same move +
## intensity; interior blend **0.5** velocity = **`lerp`** of pure thrust vs pure swing speeds; mixed blend **0.5** KE =
## **`lerp`** of thrust vs swing KE **at that same blended `v`** (not **`lerp`** of pure-mode KE at each mode's
## **`v`**). Repeats the mixed **0** / **0.5** / **1** bracket checks on **AXE** **`diagonal_chop`** and **DAGGER**
## **`quick_slash`** (extra cut fixtures; **`spear_slash`** can degenerate thrust/swing KE at some intensities).
