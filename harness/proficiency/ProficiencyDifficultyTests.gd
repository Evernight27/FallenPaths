class_name ProficiencyDifficultyTests

extends CombatRegressionHarnessCore

## XCamp-4: opponent-relative difficulty scaling and weapon-form proficiency.
## Stronger-foe sharpening, self-relative opponent difficulty, swing economy/tiers,
## weapon-form caps, attempt tracking, inactivity decay and rust/mastery notes.


static func _run_decay_forgetting_curve_shape(failures: PackedStringArray) -> void:
    # Day 1 is exactly one day-equivalent of decay by construction.
    if not is_equal_approx(EntityProficiency.decay_inactivity_factor(1), 1.0):
        _fail(failures, "decay_curve: day-1 factor want 1.0 got %.4f" % EntityProficiency.decay_inactivity_factor(1))
    # Non-positive inactivity gives no decay.
    if EntityProficiency.decay_inactivity_factor(0) != 0.0 or EntityProficiency.decay_inactivity_factor(-5) != 0.0:
        _fail(failures, "decay_curve: non-positive days should give 0.0")
    # Monotonic: more layoff days never yields less decay.
    var prev: float = 0.0
    for d in range(1, 41):
        var f: float = EntityProficiency.decay_inactivity_factor(d)
        if f < prev:
            _fail(failures, "decay_curve: factor not monotonic at day %d (%.4f < %.4f)" % [d, f, prev])
        prev = f
    # Saturation: a 30-day layoff costs fewer than 30 day-equivalents (vs the old linear drain).
    if EntityProficiency.decay_inactivity_factor(30) >= 30.0:
        _fail(
            failures,
            (
                "decay_curve: 30-day factor should be < 30 (saturating), got %.4f"
                % EntityProficiency.decay_inactivity_factor(30)
            )
        )
    # But still strictly increasing toward that bound (not flat).
    if not (EntityProficiency.decay_inactivity_factor(30) > EntityProficiency.decay_inactivity_factor(10)):
        _fail(failures, "decay_curve: 30-day factor should exceed 10-day factor")
    # Long layoffs bound near ~1/lambda day-equivalents, well below linear.
    if EntityProficiency.decay_inactivity_factor(60) >= 20.0:
        _fail(
            failures,
            (
                "decay_curve: 60-day factor should stay < 20 (saturated), got %.4f"
                % EntityProficiency.decay_inactivity_factor(60)
            )
        )
    # Concrete value pinning the curve constant (guards against accidental re-tuning to a flat/identity shape).
    if absf(EntityProficiency.decay_inactivity_factor(5) - 4.4507) > 0.01:
        _fail(
            failures, "decay_curve: 5-day factor want ~4.4507 got %.4f" % EntityProficiency.decay_inactivity_factor(5)
        )


## Gain-side severity curve (compressive clinical shape, decoupled from the AI severity score).


static func _run_gain_severity_curve(failures: PackedStringArray) -> void:
    # Compressive shape: minor < moderate < severe < critical, but the top step is smaller than the first.
    var vals: Array = [
        EntityProficiency.get_severity_mult("minor"),
        EntityProficiency.get_severity_mult("moderate"),
        EntityProficiency.get_severity_mult("severe"),
        EntityProficiency.get_severity_mult("critical"),
    ]
    if (
        absf(vals[0] - 0.4) > 0.0001
        or absf(vals[1] - 1.0) > 0.0001
        or absf(vals[2] - 1.4) > 0.0001
        or absf(vals[3] - 1.7) > 0.0001
    ):
        _fail(failures, "sev_gain: expected 0.4/1.0/1.4/1.7 got %s" % str(vals))
    if not (vals[0] < vals[1] and vals[1] < vals[2] and vals[2] < vals[3]):
        _fail(failures, "sev_gain: severity ordering violated %s" % str(vals))
    # Compressive: the minor->moderate jump must be larger than the severe->critical step.
    if not (vals[1] - vals[0] > vals[3] - vals[2]):
        _fail(failures, "sev_gain: curve should be compressive %s" % str(vals))
    # Decoupled from the AI wound-damage score: gain 'severe' differs from the AI 'severe' (1.5).
    if absf(EntityProficiency.get_severity_mult("severe") - float(EntityProficiency.SEVERITY_MULT["severe"])) < 0.0001:
        _fail(failures, "sev_gain: gain curve still aliased with AI SEVERITY_MULT")
    # Unknown severity falls back to 1.0.
    if absf(EntityProficiency.get_severity_mult("unknown") - 1.0) > 0.0001:
        _fail(failures, "sev_gain: unknown severity should default to 1.0")


## Opponent-difficulty multiplier is self-relative: a near-level bout is the 1.0 baseline, beating a
## stronger foe teaches more (>1.0), a weaker foe teaches less (<1.0), and an empty own-strength falls
## back to the fixed GAIN_DIFFICULTY_STR_BASE reference. The result is clamped to the [MIN, MAX] band.


static func _run_opponent_difficulty_self_relative(failures: PackedStringArray) -> void:
    # Near-level: target strength == own strength -> exactly the 1.0 baseline.
    if absf(EntityProficiency.opponent_difficulty_mult(120.0, 120.0) - 1.0) > 0.0001:
        _fail(failures, "diff_self: near-level bout should be the 1.0 baseline")
    # Beating a stronger foe teaches more.
    var stronger: float = EntityProficiency.opponent_difficulty_mult(140.0, 100.0)
    if not (stronger > 1.0):
        _fail(failures, "diff_self: stronger foe should scale up (got %.3f)" % stronger)
    # Beating a weaker foe teaches less.
    var weaker: float = EntityProficiency.opponent_difficulty_mult(60.0, 100.0)
    if not (weaker < 1.0):
        _fail(failures, "diff_self: weaker foe should scale down (got %.3f)" % weaker)
    # Self-relative: the same strong foe teaches a *weaker* attacker more than a stronger one,
    # because the gap to their own strength is larger.
    var weak_attacker: float = EntityProficiency.opponent_difficulty_mult(120.0, 80.0)
    var strong_attacker: float = EntityProficiency.opponent_difficulty_mult(120.0, 120.0)
    if not (weak_attacker > strong_attacker):
        _fail(
            failures,
            (
                "diff_self: weaker attacker should gain more from the same strong foe (weak=%.3f strong=%.3f)"
                % [weak_attacker, strong_attacker]
            ),
        )
    # Empty own-strength (0.0) falls back to the fixed base reference.
    var base_ref: float = EntityProficiency.opponent_difficulty_mult(120.0, 0.0)
    var expected_base: float = clampf(
        1.0 + (120.0 - EntityProficiency.GAIN_DIFFICULTY_STR_BASE) * EntityProficiency.GAIN_DIFFICULTY_STR_SCALE,
        EntityProficiency.GAIN_DIFFICULTY_STR_MIN,
        EntityProficiency.GAIN_DIFFICULTY_STR_MAX
    )
    if absf(base_ref - expected_base) > 0.0001:
        _fail(
            failures,
            "diff_self: own-strength 0 should use the base reference (got %.3f want %.3f)" % [base_ref, expected_base]
        )
    # Band clamping: a far-weak target floors at MIN.
    var floored: float = EntityProficiency.opponent_difficulty_mult(1.0, 100.0)
    if absf(floored - EntityProficiency.GAIN_DIFFICULTY_STR_MIN) > 0.0001:
        _fail(failures, "diff_self: far-weak target should clamp to MIN (got %.3f)" % floored)


## Repeated apply_decay calls within one absence (consecutive camp rests) must not re-charge
## days already decayed: total loss over a 3-day absence equals the single-shot geometric
## bound, not the full-span factor re-applied on each rest (Topic 7d saturation shape).


static func _run_decay_repeated_calls_do_not_double_charge(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true

    # Stepped: three camp rests (days 2, 3, 4) after a fight on day 1.
    var stepped: CoreEntity = _new_entity("SWORD")
    stepped._proficiency_bonus["strength"] = 25.0
    stepped.last_fought_day = 1
    EntityProficiency.apply_decay(stepped, 2)
    EntityProficiency.apply_decay(stepped, 3)
    EntityProficiency.apply_decay(stepped, 4)
    var stepped_str: float = float(stepped._proficiency_bonus.get("strength", 0.0))

    # A no-op call on the same day must not decay again.
    EntityProficiency.apply_decay(stepped, 4)
    var noop_str: float = float(stepped._proficiency_bonus.get("strength", 0.0))
    if absf(noop_str - stepped_str) > 0.0001:
        _fail(failures, "decay_repeat: same-day re-apply should be a no-op (%.4f -> %.4f)" % [stepped_str, noop_str])

    # One-shot: a single call spanning the same absence must land on the same value.
    var one_shot: CoreEntity = _new_entity("SWORD")
    one_shot._proficiency_bonus["strength"] = 25.0
    one_shot.last_fought_day = 1
    EntityProficiency.apply_decay(one_shot, 4)
    var one_shot_str: float = float(one_shot._proficiency_bonus.get("strength", 0.0))

    if absf(stepped_str - one_shot_str) > 0.001:
        _fail(
            failures,
            "decay_repeat: stepped 3 calls (%.4f) should equal one-shot span (%.4f)" % [stepped_str, one_shot_str],
        )

    # Saturation bound: total loss must not exceed rate*mult*factor(3) (the full geometric span).
    var bound_loss: float = (
        absf(EntityProficiency.DECAY_RATE_VETERAN_PLUS * EntityProficiency.DECAY_MULT_STR)
        * EntityProficiency.decay_inactivity_factor(3)
    )
    if 25.0 - stepped_str > bound_loss + 0.0001:
        _fail(
            failures,
            "decay_repeat: loss (%.4f) exceeds saturating bound (%.4f)" % [25.0 - stepped_str, bound_loss],
        )
    if stepped_str >= 25.0:
        _fail(failures, "decay_repeat: no decay was applied (still %.4f)" % stepped_str)

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(stepped)
    HarnessFixtures._free_harness_node(one_shot)


## Weapon/form proficiency stops accumulating at the veteran cap (20): the tier clamps to 1.0 past it,
## so extra points would be pure bookkeeping that shows up as e.g. "27/20" in the roster UI.


static func _run_weapon_form_proficiency_capped_at_veteran_max(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: CoreEntity = _new_entity("SWORD")
    # One large gain would overshoot the cap; the stored value must not.
    EntityProficiency.award_weapon_proficiency(ent, "SWORD", 100.0)
    var wp: float = float(ent._weapon_proficiency.get("SWORD", 0.0))
    if absf(wp - EntityProficiency.WEAPON_PROF_VETERAN_MAX) > 0.001:
        _fail(
            failures,
            "wp_cap: weapon prof should cap at %.0f, got %.2f" % [EntityProficiency.WEAPON_PROF_VETERAN_MAX, wp],
        )
    EntityProficiency.award_form_proficiency(ent, CombatWeaponForm.FORM_WRATH, 100.0)
    var fp: float = float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))
    if absf(fp - EntityProficiency.FORM_PROF_VETERAN_MAX) > 0.001:
        _fail(
            failures,
            "form_cap: form prof should cap at %.0f, got %.2f" % [EntityProficiency.FORM_PROF_VETERAN_MAX, fp],
        )
    # A further award at the cap must be a no-op.
    EntityProficiency.award_weapon_proficiency(ent, "SWORD", 5.0)
    if absf(float(ent._weapon_proficiency.get("SWORD", 0.0)) - EntityProficiency.WEAPON_PROF_VETERAN_MAX) > 0.001:
        _fail(
            failures,
            "wp_cap: at-cap re-award should be a no-op, got %.2f" % float(ent._weapon_proficiency.get("SWORD", 0.0)),
        )
    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)


## XCamp-4 write-side gate: only proficiency-tracked fighters accrue stat bonuses. A full strike
## through the production path (AttackResultApplier) must grow the tracked attacker's STR on every
## resolved outcome while the untracked defender's bonuses stay exactly where they started.


static func _run_untracked_fighter_does_not_gain_stat_bonus(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "gate_untracked: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy_ent: Node = data.get("enemy_ent")

    # Fixture invariants: party player is tracked, enemy is not.
    if not ("_combat_skill_trained" in player_ent and bool(player_ent.get("_combat_skill_trained"))):
        _fail(failures, "gate_untracked: fixture player should be tracked")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    if "_combat_skill_trained" in enemy_ent and bool(enemy_ent.get("_combat_skill_trained")):
        _fail(failures, "gate_untracked: fixture enemy should be untracked")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return

    var enemy_before: Dictionary = {}
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        enemy_before[stat] = float(enemy_ent._proficiency_bonus.get(stat, 0.0))
    var player_str_before: float = float(player_ent._proficiency_bonus.get("strength", 0.0))

    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    if atk.is_empty():
        _fail(failures, "gate_untracked: no player combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {
        "target_id": 1,
        "intensity": 0.5,
        "attack_type": "thrust",
    }

    # Every resolved attacker-side outcome (miss/dodge/hit/parry) awards the wind-up STR gain.
    AttackResultApplier.apply_result(mgr, p_id, AttackResolver.resolve_attack(mgr, p_id))

    var player_str_after: float = float(player_ent._proficiency_bonus.get("strength", 0.0))
    if player_str_after <= player_str_before:
        _fail(
            failures,
            (
                "gate_untracked: tracked attacker should gain STR on any resolved strike (before %.2f after %.2f)"
                % [player_str_before, player_str_after]
            ),
        )

    for stat in enemy_before:
        var after_val: float = float(enemy_ent._proficiency_bonus.get(stat, 0.0))
        if absf(after_val - float(enemy_before[stat])) > 0.001:
            _fail(
                failures,
                (
                    "gate_untracked: untracked defender should not accrue %s (before %.2f after %.2f)"
                    % [stat, float(enemy_before[stat]), after_val]
                ),
            )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: weapon/form proficiency accrues on completed strike attempts (reps) for tracked
## fighters; untracked fighters never accrue weapon/form proficiency.


static func _run_weapon_form_attempt_gains_tracked_only(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "wp_attempt: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: Node = data.get("player_ent")
    var enemy_ent: Node = data.get("enemy_ent")

    # Execute a strike—any outcome (miss/dodge/hit/parry) should build player weapon prof.
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    if atk.is_empty():
        _fail(failures, "wp_attempt: no player combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    atk.state = CombatConstants.STATE_WIND_UP
    atk.pending_attack = {
        "target_id": 1,
        "intensity": 0.5,
        "attack_type": "thrust",
    }
    AttackResultApplier.apply_result(mgr, p_id, AttackResolver.resolve_attack(mgr, p_id))

    # Player (tracked) should have accrued some weapon proficiency regardless of outcome.
    var player_wp: float = 0.0
    if "_weapon_proficiency" in player_ent:
        for v in (player_ent._weapon_proficiency as Dictionary).values():
            player_wp += float(v)
    if player_wp <= 0.0:
        _fail(
            failures,
            "wp_attempt: tracked player should accrue weapon proficiency on a strike attempt (got %.3f)" % player_wp,
        )

    # Enemy (untracked) must have zero weapon proficiency—the write-side gate excludes them.
    var enemy_wp: float = 0.0
    if "_weapon_proficiency" in enemy_ent:
        for v in (enemy_ent._weapon_proficiency as Dictionary).values():
            enemy_wp += float(v)
    if enemy_wp > 0.0:
        _fail(failures, "wp_attempt: untracked enemy should NOT accrue weapon proficiency (got %.3f)" % enemy_wp)

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: a perception read is a *cognitive* act, so it is gated by execution quality
## (pain x consciousness, blood excluded) — not by the wounded-fighter physical factor. A dazed
## parrier (low consciousness, no blood loss) reads the incoming line less sharply than an alert one,
## so their PER gain is smaller, while still accruing something. Blood loss alone does NOT reduce the
## read (the parryer here is full-blood), isolating the consciousness channel.


static func _run_dazed_parryer_reads_less(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return

    # Healthy parrier baseline: a full parry read lands at the base value (execution factor 1.0).
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "dazed_parry_read: setup failed")
        return
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "dazed_parry_read: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var per_before: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_healthy: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    # XCamp-4: the read also scales by the attacker's difficulty (desirable difficulty), so the
    # healthy baseline is base x that factor, not the raw base.
    var diff_healthy: float = EntityProficiency.opponent_difficulty_mult(
        CombatantEntityAccess.stats_dict(atk).get(DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE),
        CombatantEntityAccess.stats_dict(enemy).get(
            DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
        )
    )
    var expected_healthy: float = EntityProficiency.GAIN_PARRY_READ_PER_BASE * diff_healthy
    if absf(per_healthy - expected_healthy) > 0.001:
        _fail(
            failures,
            (
                "dazed_parry_read: healthy parrier should read at base x difficulty (got %.4f, want %.4f)"
                % [per_healthy, expected_healthy]
            ),
        )
        return

    # Dazed parrier: same rep, consciousness pinned at 50% (dirty flag cleared so it sticks). Full
    # blood, so the only thing reduced is the execution-quality (consciousness) channel.
    var data2: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data2.is_empty():
        _fail(failures, "dazed_parry_read: setup2 failed")
        return
    var mgr2: Node = data2.get("mgr")
    var enemy_ent2: CoreEntity = data2.get("enemy_ent")
    enemy_ent2._combat_skill_trained = true
    enemy_ent2.effective_consciousness = 50.0
    enemy_ent2._consciousness_dirty = false
    var p_id2: int = data2.get("p_id")
    var enemy2: Dictionary = mgr2.combatants[1]
    if enemy2.is_empty():
        _fail(failures, "dazed_parry_read: no enemy combatant2")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
        return
    var enemy_id2: int = CombatantEntityAccess.id_int(enemy2)
    var atk2: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr2, p_id2)
    atk2.pending_attack = {"target_id": enemy_id2, "intensity": 0.5, "attack_type": "thrust"}
    var per_before2: float = float(enemy_ent2._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr2, p_id2, {"action": "parry_deflect", "target_id": enemy_id2, "parry_clash_context": pclash}
    )
    var per_dazed: float = float(enemy_ent2._proficiency_bonus.get("perception", 0.0)) - per_before2
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data2)
    if per_dazed <= 0.0:
        _fail(failures, "dazed_parry_read: dazed parrier should still read something (got %.4f)" % per_dazed)
        return
    if not (per_dazed < per_healthy):
        _fail(
            failures,
            (
                "dazed_parry_read: dazed parrier should read less than healthy "
                + "(dazed=%.4f healthy=%.4f)" % [per_dazed, per_healthy]
            ),
        )


## XCamp-4: desirable difficulty on the perception channel — successfully parrying a *stronger*
## opponent's strike is a sharper perception lesson, so the parrier's PER read scales up with the
## attacker's strength (and down with a weaker one). Mirrors the attacker-STR scaling already applied
## on a clean hit. Isolates the difficulty dimension: the parrier is healthy and full-blooded in both
## runs (execution quality 1.0), so only the attacker's strength varies.


static func _run_stronger_foe_sharpens_parry_read(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var per_weak: float = _measure_parry_read_vs_attacker_strength(failures, 40.0)
    if per_weak == -INF:
        return
    var per_strong: float = _measure_parry_read_vs_attacker_strength(failures, 200.0)
    if per_strong == -INF:
        return
    if per_weak <= 0.0:
        _fail(failures, "strong_foe_read: parrier should read the weak attacker's line (got %.4f)" % per_weak)
        return
    if not (per_strong > per_weak):
        _fail(
            failures,
            (
                "strong_foe_read: parrying a stronger foe should sharpen the PER read "
                + "(strong=%.4f weak=%.4f)" % [per_strong, per_weak]
            ),
        )


## XCamp-4 helper: run one healthy, full-blooded parry against an attacker whose strength is pinned
## to `str_value` and return the parrier's PER gain. Returns -INF on setup failure (already
## reported to `failures`). The parrier's own strength and execution quality are held constant, so
## only the desirable-difficulty factor varies between calls.


static func _measure_parry_read_vs_attacker_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "strong_foe_read: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "strong_foe_read: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    # Pin the attacker's strength so the desirable-difficulty factor is controlled.
    CombatantEntityAccess.stats_dict_for_mutation(atk).set(DataKeys.ENTITY_STRENGTH, str_value)
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var per_before: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var per_gain: float = float(enemy_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return per_gain


## XCamp-4: desirable difficulty on the *defensive physical* channel — meeting a *stronger* foe's
## blade is a harder physical/reflex lesson, so the parrier's absorbed-END (and, by the same factor,
## reflex-AGI / weapon-STR) gain scales up with the attacker's strength, mirroring the PER read that
## already scales in the same parry event. Isolates the difficulty dimension: the parrier is healthy
## and full-blooded in both runs (execution quality 1.0), so only the attacker's strength varies.


static func _run_stronger_foe_sharpens_defensive_gains(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var end_weak: float = _measure_parry_deflect_end_vs_attacker_strength(failures, 40.0)
    if end_weak == -INF:
        return
    var end_strong: float = _measure_parry_deflect_end_vs_attacker_strength(failures, 200.0)
    if end_strong == -INF:
        return
    if end_weak <= 0.0:
        _fail(failures, "strong_foe_end: parrier should absorb the weak attacker's blow (got %.4f)" % end_weak)
        return
    if not (end_strong > end_weak):
        _fail(
            failures,
            (
                "strong_foe_end: parrying a stronger foe should train more defensive END "
                + "(strong=%.4f weak=%.4f)" % [end_strong, end_weak]
            ),
        )


## XCamp-4 helper: run one healthy, full-blooded parry_deflect against an attacker whose strength is
## pinned to `str_value` and return the parrier's END gain. Returns -INF on setup failure. The
## parrier's own strength and execution quality are held constant, so only the desirable-difficulty
## factor varies between calls.


static func _measure_parry_deflect_end_vs_attacker_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "strong_foe_end: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    enemy_ent._combat_skill_trained = true
    var p_id: int = data.get("p_id")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "strong_foe_end: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    atk.pending_attack = {"target_id": enemy_id, "intensity": 0.5, "attack_type": "thrust"}
    # Pin the attacker's strength so the desirable-difficulty factor is controlled.
    CombatantEntityAccess.stats_dict_for_mutation(atk).set(DataKeys.ENTITY_STRENGTH, str_value)
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust",
        "strike_measure_ratio": 1.05,
        "parry_control": 0.9,
        "strike_momentum_kg_ms": 0.0,
        "strike_kinetic_energy_j": 0.0,
    }
    var end_before: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0))
    AttackResultApplier.apply_result(
        mgr, p_id, {"action": "parry_deflect", "target_id": enemy_id, "parry_clash_context": pclash}
    )
    var end_gain: float = float(enemy_ent._proficiency_bonus.get("endurance", 0.0)) - end_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return end_gain


## XCamp-4: desirable difficulty on the attacker's weapon/form channel — landing a clean hit on a
## *stronger* opponent is a sharper weapon-handling lesson, so the weapon/form hit award scales with
## the target's strength (mirroring the hit STR gain in the same resolve). Isolates the difficulty
## dimension: both runs use a healthy, full-blooded attacker and the same 5.0 dmg.


static func _run_hit_weapon_form_scales_with_target_difficulty(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var wp_weak: float = _measure_hit_weapon_gain_vs_target_strength(failures, 40.0)
    if wp_weak == -INF:
        return
    var wp_strong: float = _measure_hit_weapon_gain_vs_target_strength(failures, 200.0)
    if wp_strong == -INF:
        return
    if wp_weak <= 0.0:
        _fail(failures, "hit_wp_diff: attacker should build SWORD prof on a clean hit (got %.4f)" % wp_weak)
        return
    if not (wp_strong > wp_weak):
        _fail(
            failures,
            (
                "hit_wp_diff: hitting a stronger target should build more weapon prof "
                + "(strong=%.4f weak=%.4f)" % [wp_strong, wp_weak]
            ),
        )


## XCamp-4 helper: one clean hit against a target whose strength is pinned to `str_value`; returns the
## attacker's SWORD weapon-proficiency gain. Returns -INF on setup failure. Attacker health and
## execution quality are held constant, so only the target's desirable-difficulty factor varies.


static func _measure_hit_weapon_gain_vs_target_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "hit_wp_diff: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: CoreEntity = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "hit_wp_diff: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    # Pin the target's strength so the desirable-difficulty factor is controlled.
    CombatantEntityAccess.stats_dict_for_mutation(enemy).set(DataKeys.ENTITY_STRENGTH, str_value)
    var wp_before: float = float(player_ent._weapon_proficiency.get("SWORD", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, enemy_id, "hit", {"dmg": 5})
    var wp_gain: float = float(player_ent._weapon_proficiency.get("SWORD", 0.0)) - wp_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return wp_gain


## XCamp-4: desirable difficulty on the attacker's STR channel — a clean hit that leaves a severe
## wound on a *stronger* opponent is a bigger lesson, so the total STR award (hit + severe-wound)
## scales with the target's strength. Isolates the difficulty dimension: healthy full-blooded
## attacker, same 5.0 dmg and wound severity in both runs.


static func _run_hit_str_scales_with_target_difficulty(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var str_weak: float = _measure_hit_str_gain_vs_target_strength(failures, 40.0)
    if str_weak == -INF:
        return
    var str_strong: float = _measure_hit_str_gain_vs_target_strength(failures, 200.0)
    if str_strong == -INF:
        return
    if str_weak <= 0.0:
        _fail(failures, "hit_str_diff: attacker should gain STR from a clean hit (got %.4f)" % str_weak)
        return
    if not (str_strong > str_weak):
        _fail(
            failures,
            (
                "hit_str_diff: hitting a stronger target should award more STR "
                + "(strong=%.4f weak=%.4f)" % [str_strong, str_weak]
            ),
        )


## XCamp-4 helper: one clean severe hit against a target whose strength is pinned to `str_value`;
## returns the attacker's STR bonus gain (hit + severe-wound). Returns -INF on setup failure.


static func _measure_hit_str_gain_vs_target_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "hit_str_diff: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: CoreEntity = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "hit_str_diff: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    CombatantEntityAccess.stats_dict_for_mutation(enemy).set(DataKeys.ENTITY_STRENGTH, str_value)
    var str_before: float = float(player_ent._proficiency_bonus.get("strength", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(
        mgr, p_id, enemy_id, "hit", {"dmg": 5, "wound_severity": "severe"}
    )
    var str_gain: float = float(player_ent._proficiency_bonus.get("strength", 0.0)) - str_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return str_gain


## XCamp-4: desirable difficulty on the attacker's off-focus PER read — hitting where the defender is
## NOT guarding is an opponent-attention perception act, so it is harder (and a sharper lesson) against
## a *stronger* opponent. This completes the difficulty thread on the offensive cognitive channel: the
## preferred-part INT award is deliberately left unscaled because it rewards the attacker's own
## targeting execution, not a read of the opponent. Both combatants' strengths are pinned, so the
## full difficulty band (floor 0.85, baseline 1.0, ceiling 1.35) is verified end-to-end.


static func _run_off_focus_per_scales_with_target_difficulty(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    # Target strength probes: 0.0 and 200.0 sit well past the clamp band (with the attacker at the
    # reference base), so they exercise the floor and ceiling; the reference base exercises 1.0.
    var per_floor: float = _measure_off_focus_per_vs_target_strength(failures, 0.0)
    if per_floor == -INF:
        return
    var per_base: float = _measure_off_focus_per_vs_target_strength(
        failures, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    if per_base == -INF:
        return
    var per_ceiling: float = _measure_off_focus_per_vs_target_strength(failures, 200.0)
    if per_ceiling == -INF:
        return
    var base: float = EntityProficiency.GAIN_OFF_FOCUS_HIT_PER_BASE
    var want_floor: float = base * EntityProficiency.GAIN_DIFFICULTY_STR_MIN
    var want_base: float = base
    var want_ceiling: float = base * EntityProficiency.GAIN_DIFFICULTY_STR_MAX
    if absf(per_floor - want_floor) > 0.001:
        _fail(failures, "off_focus_per_diff: floor read want %.4f got %.4f" % [want_floor, per_floor])
    if absf(per_base - want_base) > 0.001:
        _fail(failures, "off_focus_per_diff: baseline read want %.4f got %.4f" % [want_base, per_base])
    if absf(per_ceiling - want_ceiling) > 0.001:
        _fail(failures, "off_focus_per_diff: ceiling read want %.4f got %.4f" % [want_ceiling, per_ceiling])


## XCamp-4 helper: one clean off-focus hit with the attacker's strength pinned to 100 and the target's
## to `str_value`; returns the attacker's PER bonus gain. Returns -INF on setup failure. The defender's
## focus is pinned to "head" while the strike lands off-focus on "chest", so only the off-focus PER read
## fires (no preferred-part INT, since the move id is left empty). Both combatants' strengths are held
## fixed, so only the desirable-difficulty factor varies between calls.


static func _measure_off_focus_per_vs_target_strength(failures: PackedStringArray, str_value: float) -> float:
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "off_focus_per_diff: setup failed")
        return -INF
    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var player_ent: CoreEntity = data.get("player_ent")
    var enemy: Dictionary = mgr.combatants[1]
    if enemy.is_empty():
        _fail(failures, "off_focus_per_diff: no enemy combatant")
        ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
        return -INF
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, p_id)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    # Defender is focused on "head"; the strike lands off-focus on "chest".
    enemy[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "head"
    # Pin both combatants' strengths so the difficulty factor is fully controlled. The attacker is
    # held at the reference base so the target strength is the sole driver of the difficulty factor.
    CombatantEntityAccess.stats_dict_for_mutation(atk).set(
        DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
    )
    CombatantEntityAccess.stats_dict_for_mutation(enemy).set(DataKeys.ENTITY_STRENGTH, str_value)
    var per_before: float = float(player_ent._proficiency_bonus.get("perception", 0.0))
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(
        mgr,
        p_id,
        enemy_id,
        "hit",
        {DataKeys.RESULT_PART: "chest", DataKeys.ACTION_TARGET_PART: "chest", DataKeys.RESULT_DMG: 5}
    )
    var per_gain: float = float(player_ent._proficiency_bonus.get("perception", 0.0)) - per_before
    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)
    return per_gain


## XCamp-4: weapon/form familiarity rusts with inactivity for tracked fighters only, and only above
## the 10.0 foundational floor — so a rusted fighter's aim drops in step with their rusted stats.


static func _run_weapon_form_proficiency_decays_with_inactivity(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true

    # Tracked fighter with a trained edge (above the 10.0 floor) on both weapon and form.
    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._weapon_proficiency["SWORD"] = 15.0
    ent._form_proficiency[CombatWeaponForm.FORM_WRATH] = 15.0
    ent.last_fought_day = -5  # 6 days inactive at day 0.
    var wp_before: float = float(ent._weapon_proficiency.get("SWORD", 0.0))
    var fp_before: float = float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))

    EntityProficiency.apply_decay(ent, 0)

    var wp_after: float = float(ent._weapon_proficiency.get("SWORD", 0.0))
    var fp_after: float = float(ent._form_proficiency.get(CombatWeaponForm.FORM_WRATH, 0.0))
    if wp_after >= wp_before:
        _fail(failures, "wpf_decay: tracked weapon prof should rust (before %.2f after %.2f)" % [wp_before, wp_after])
    if fp_after >= fp_before:
        _fail(failures, "wpf_decay: tracked form prof should rust (before %.2f after %.2f)" % [fp_before, fp_after])

    # Untracked fighter: weapon/form should never have accrued, so decay is a no-op even when a
    # value is present (the write-side gate is the real protection; this proves decay respects it).
    var ent_un: CoreEntity = _new_entity("SWORD")
    ent_un._combat_skill_trained = false
    ent_un._weapon_proficiency["SWORD"] = 15.0
    ent_un.last_fought_day = -5
    var uwp_before: float = float(ent_un._weapon_proficiency.get("SWORD", 0.0))
    EntityProficiency.apply_decay(ent_un, 0)
    var uwp_after: float = float(ent_un._weapon_proficiency.get("SWORD", 0.0))
    if absf(uwp_after - uwp_before) > 0.001:
        _fail(
            failures,
            "wpf_decay: untracked weapon prof should NOT rust (before %.2f after %.2f)" % [uwp_before, uwp_after]
        )

    # Foundational edge (<= 10.0) never rusts, mirroring the stat "foundational skill" rule.
    var ent_low: CoreEntity = _new_entity("SWORD")
    ent_low._combat_skill_trained = true
    ent_low._weapon_proficiency["SWORD"] = 8.0
    ent_low.last_fought_day = -5
    var low_before: float = float(ent_low._weapon_proficiency.get("SWORD", 0.0))
    EntityProficiency.apply_decay(ent_low, 0)
    var low_after: float = float(ent_low._weapon_proficiency.get("SWORD", 0.0))
    if absf(low_after - low_before) > 0.001:
        _fail(
            failures,
            (
                "wpf_decay: foundational (<=10) weapon prof should NOT rust (before %.2f after %.2f)"
                % [low_before, low_after]
            )
        )

    CompanyState.proficiency_enabled = old_stub
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_un)
    HarnessFixtures._free_harness_node(ent_low)


## XCamp-4: a successful parry is also a precise weapon act for the *defender* — the parrier brought
## their own blade to meet the incoming strike, so they train their weapon/form too. Gated on the
## write-side tracked flag, so an untracked parrier stays at baseline.


static func _run_parry_deflect_awards_parryer_weapon_prof(failures: PackedStringArray) -> void:
    if not CompanyState.read_stub_proficiency_enabled():
        return
    var data: Dictionary = ProficiencyAwardPersistenceTests._setup_proficiency_combat(failures)
    if data.is_empty():
        _fail(failures, "parry_wp: setup failed")
        return

    var mgr: Node = data.get("mgr")
    var p_id: int = data.get("p_id")
    var enemy_ent: CoreEntity = data.get("enemy_ent")
    # Make the defender tracked so the parry weapon/form gain is expected to fire.
    enemy_ent._combat_skill_trained = true
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])

    var wp_before: float = EntityProficiency.weapon_proficiency_value(enemy_ent, "SWORD")
    # Simulate a clean parry resolution: the defender (e_id) met the attacker's (p_id) strike.
    AttackProficiencyAwarder.notify_proficiency_gains_from_resolve(mgr, p_id, e_id, "parry_deflect", {})
    var wp_after: float = EntityProficiency.weapon_proficiency_value(enemy_ent, "SWORD")
    if wp_after <= wp_before:
        _fail(
            failures,
            (
                "parry_wp: tracked parrier should gain weapon proficiency on a clean parry (before %.3f after %.3f)"
                % [wp_before, wp_after]
            ),
        )

    ProficiencyAwardPersistenceTests._free_proficiency_combat(data)


## XCamp-4: the rust warning fires when *any* trainable proficiency (stat bonus OR weapon/form mastery)
## is above the 10.0 foundational floor and the fighter has gone days without combat — so a fighter
## whose only trained edge is blade mastery is warned too, not just one with high stat bonuses.


static func _run_rust_note_fires_for_weapon_form_mastery(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var world: Node2D = Node2D.new()
    CompanyState.set_day_index(world, 10)

    # Weapon/form above the 10.0 floor, no stat bonuses -> should still get the rust warning.
    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._weapon_proficiency["SWORD"] = 15.0
    ent._form_proficiency[CombatWeaponForm.FORM_WRATH] = 15.0
    ent.last_fought_day = 4  # 6 days without combat.
    var note: String = PartyRowFormatter._proficiency_rust_note(ent, world)
    if note.is_empty():
        _fail(failures, "rust_note_wpf: weapon/form mastery >10 with no stat bonus should still get a rust warning")

    # Weapon/form at/below the 10.0 foundational floor -> no warning (mirrors the stat floor rule).
    var ent_low: CoreEntity = _new_entity("SWORD")
    ent_low._combat_skill_trained = true
    ent_low._weapon_proficiency["SWORD"] = 8.0
    ent_low.last_fought_day = 4
    var low_note: String = PartyRowFormatter._proficiency_rust_note(ent_low, world)
    if not low_note.is_empty():
        _fail(
            failures,
            "rust_note_wpf: foundational (<=10) weapon mastery should NOT trigger a rust warning, got '%s'" % low_note,
        )

    CompanyState.proficiency_enabled = old_stub
    world.queue_free()
    HarnessFixtures._free_harness_node(ent)
    HarnessFixtures._free_harness_node(ent_low)


## XCamp-4: the combat-participation snapshot marks the *canonical* `last_fought_in_combat` property
## (the one the post-combat reader and save/load use), not an orphaned underscore variant the reader
## never sees. Guards the "did this fighter actually fight" flag that participant-gated progression
## (gains/decay only for those who fought) is built on.


static func _run_snapshot_marks_canonical_fought_flag(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var ent: CoreEntity = _new_entity("SWORD")
    world.set_meta("party_manager", {"members": [{"node_ref": ent}]})

    CampaignEncounterBridge._proficiency_snapshot_combat_participation(world)

    if not ent.last_fought_in_combat:
        _fail(
            failures,
            (
                "fought_flag: snapshot should set the canonical last_fought_in_combat property (got %s)"
                % str(ent.last_fought_in_combat)
            )
        )
    if "_last_fought_in_combat" in ent:
        _fail(failures, "fought_flag: snapshot should not leave an orphaned _last_fought_in_combat dynamic property")

    world.queue_free()
    HarnessFixtures._free_harness_node(ent)


## XCamp-4: a fighter who fights on campaign day 0 (DEFAULT_DAY_INDEX) is recorded with
## last_fought_day >= 1, never the 0 "never fought" sentinel — so their bonuses actually decay
## on later days instead of being silently skipped forever.


static func _run_day0_fight_records_decaying_last_fought_day(failures: PackedStringArray) -> void:
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var world: Node2D = Node2D.new()
    CompanyState.set_day_index(world, 0)

    var ent: CoreEntity = _new_entity("SWORD")
    ent._combat_skill_trained = true
    ent._proficiency_bonus["strength"] = 15.0
    ent.last_fought_in_combat = true
    ent.last_fought_day = 0
    world.set_meta("party_manager", {"members": [{"node_ref": ent}]})

    # Post-combat on day 0: should clamp last_fought_day to 1, not leave it at the 0 sentinel.
    CampaignEncounterBridge._proficiency_post_combat(world)
    var recorded: int = int(ent.last_fought_day)
    if recorded == 0:
        _fail(
            failures,
            (
                (
                    "day0_fought: day-0 fight should record last_fought_day >= 1, not the 0 'never fought' sentinel "
                    + "(got "
                    + "%d)"
                )
                % recorded
            )
        )

    # The bonus must actually decay on a later day (proving the recorded day is live, not skipped).
    var before: float = float(ent._proficiency_bonus["strength"])
    CompanyState.set_day_index(world, 5)
    EntityProficiency.apply_decay(ent, 5)
    var after: float = float(ent._proficiency_bonus["strength"])
    if after >= before:
        _fail(
            failures,
            "day0_fought: day-0 fighter's bonus should decay by day 5 (before %.2f after %.2f)" % [before, after]
        )

    CompanyState.proficiency_enabled = old_stub
    world.queue_free()
    HarnessFixtures._free_harness_node(ent)
