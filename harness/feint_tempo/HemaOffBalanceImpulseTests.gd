class_name HemaOffBalanceImpulseTests

extends HemaTestBase

## HEMA off-balance impulse/stagger surface: whiff + hit impulses, orientation and armor
## inertia, dodge stagger and contest penalties, execute/close constants, AI selection
## and formation settle / cower-replant off-balance behaviour.


static func run_parry_deflect_alignment_off_balance(failures: PackedStringArray) -> void:
    var base: float = CombatConstants.off_balance_deflect_duration(0.8)
    var glancing_total: float = base * CombatConstants.parry_recoil_alignment_mult(0.1)
    var square_total: float = base * CombatConstants.parry_recoil_alignment_mult(1.0)
    var neutral_total: float = base * CombatConstants.parry_recoil_alignment_mult(0.5)
    _assert(
        glancing_total < base and square_total > base,
        failures,
        "pdeflect_align: glancing (%.3f) should be < base (%.3f) < square (%.3f)" % [glancing_total, base, square_total]
    )
    _assert(
        absf(neutral_total - base) < 0.02 * base,
        failures,
        "pdeflect_align: neutral alignment should be ~unchanged (got %.3f vs %.3f)" % [neutral_total, base]
    )
    # Bounded: the scale never drops off-balance to zero or blows past 2x.
    _assert(
        (
            CombatConstants.parry_recoil_alignment_mult(0.0) >= 0.5
            and CombatConstants.parry_recoil_alignment_mult(1.0) <= 2.0
        ),
        failures,
        "pdeflect_align: alignment scale out of sane bounds"
    )
    # Impulse axis (this pass): a parried heavy swing over-extends the attacker more than a parried
    # light probe, at the same alignment. Shares the hit/miss impulse map, neutral at the mid band.
    var heavy_deflect: float = base * CombatConstants.hit_impulse_stagger_mult(95.0)
    var light_deflect: float = base * CombatConstants.hit_impulse_stagger_mult(35.0)
    var mid_deflect: float = base * CombatConstants.hit_impulse_stagger_mult(65.0)
    _assert(
        heavy_deflect > base and light_deflect < base,
        failures,
        (
            "pdeflect_impulse: heavy parried swing should over-extend more (%.3f > %.3f) and light less (%.3f < %.3f)"
            % [heavy_deflect, base, light_deflect, base]
        )
    )
    _assert(
        absf(mid_deflect - base) < 0.001 * base,
        failures,
        "pdeflect_impulse: mid-band KE should be D001-neutral (got %.4f vs base %.4f)" % [mid_deflect, base]
    )
    _assert(
        is_equal_approx(base * CombatConstants.hit_impulse_stagger_mult(-1.0), base),
        failures,
        "pdeflect_impulse: missing KE in the clash context should stay neutral"
    )
    # Armor-inertia axis (this pass): a parried heavy-armor swing recovers slower than an unarmed
    # one, mirroring the whiff / dodge-attacker self-penalties. Neutral (1.0) with no armor (D001).
    _assert(
        is_equal_approx(CombatConstants.whiff_armor_inertia_mult(0.0), 1.0),
        failures,
        "pdeflect_armor: no armor should be neutral 1.0"
    )
    _assert(
        CombatConstants.whiff_armor_inertia_mult(1.0) > 1.0,
        failures,
        (
            "pdeflect_armor: full-armor parried swing should over-extend more (got %.3f)"
            % CombatConstants.whiff_armor_inertia_mult(1.0)
        )
    )


## Impulse-driven stagger + head-impact startle floor: the off-balance window now scales with the
## strike's kinetic energy (neutral at the mid-band so D001 pacing holds), and a clean head hit above
## the KE threshold carries a hard floor that agility/recovery cannot undercut.


static func run_off_balance_impulse_and_startle(failures: PackedStringArray) -> void:
    # Impulse mapping: 35 J -> 0.8, 95 J -> 1.2, 65 J (mid band) -> 1.0, no KE -> neutral.
    _assert(
        is_equal_approx(CombatConstants.hit_impulse_stagger_mult(35.0), 0.8),
        failures,
        "impulse_ob: 35 J should map to the min mult 0.8 got %.3f" % CombatConstants.hit_impulse_stagger_mult(35.0)
    )
    _assert(
        is_equal_approx(CombatConstants.hit_impulse_stagger_mult(95.0), 1.2),
        failures,
        "impulse_ob: 95 J should map to the max mult 1.2 got %.3f" % CombatConstants.hit_impulse_stagger_mult(95.0)
    )
    _assert(
        absf(CombatConstants.hit_impulse_stagger_mult(65.0) - 1.0) < 0.001,
        failures,
        "impulse_ob: mid-band 65 J should be D001-neutral 1.0 got %.3f" % CombatConstants.hit_impulse_stagger_mult(65.0)
    )
    _assert(
        (
            is_equal_approx(CombatConstants.hit_impulse_stagger_mult(0.0), 1.0)
            and is_equal_approx(CombatConstants.hit_impulse_stagger_mult(-1.0), 1.0)
        ),
        failures,
        "impulse_ob: missing KE should stay neutral 1.0"
    )
    _assert(
        is_equal_approx(CombatConstants.hit_impulse_stagger_mult(500.0), 1.2),
        failures,
        "impulse_ob: KE above the band should clamp to the max mult"
    )
    # Startle floor: applies only to a clean head hit above the KE threshold.
    _assert(
        is_equal_approx(
            CombatConstants.hit_startle_min_s("head", "hit", 65.0), CombatConstants.STARTLE_HEAD_IMPACT_MIN_S
        ),
        failures,
        (
            "impulse_ob: clean head hit at 65 J should carry the startle floor (%.2f)"
            % CombatConstants.STARTLE_HEAD_IMPACT_MIN_S
        )
    )
    _assert(
        (
            CombatConstants.hit_startle_min_s("chest", "hit", 65.0) == 0.0
            and CombatConstants.hit_startle_min_s("head", "hit", 30.0) == 0.0
            and CombatConstants.hit_startle_min_s("head", "negligible", 65.0) == 0.0
            and CombatConstants.hit_startle_min_s("head", "glancing", 65.0) == 0.0
        ),
        failures,
        "impulse_ob: startle floor should apply only to clean head hits above the KE threshold"
    )
    # Composition: heavy KE stuns more than light KE on the same clean torso hit.
    var c: Dictionary = {}
    var heavy: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", c, 95.0)
    var light: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", c, 35.0)
    _assert(
        heavy > light, failures, "impulse_ob: heavy KE (%.3f) should stagger more than light (%.3f)" % [heavy, light]
    )
    # The floor binds: the lightest clean head hit (i=0, 40 J) would be ~0.54s; the startle floor
    # holds it at 0.55s. The same blow to the torso stays below the floor (no startle on the torso).
    var light_head: float = PassiveParryContext.hit_off_balance_window(0.0, "head", "hit", {}, 40.0)
    var light_chest: float = PassiveParryContext.hit_off_balance_window(0.0, "chest", "hit", {}, 40.0)
    _assert(
        light_head >= CombatConstants.STARTLE_HEAD_IMPACT_MIN_S - 0.001,
        failures,
        (
            "impulse_ob: lightest head hit should hold the startle floor (got %.3f, floor %.2f)"
            % [light_head, CombatConstants.STARTLE_HEAD_IMPACT_MIN_S]
        )
    )
    _assert(
        light_chest < CombatConstants.STARTLE_HEAD_IMPACT_MIN_S,
        failures,
        "impulse_ob: torso hit should not reach the head startle floor (got %.3f)" % light_chest
    )


## Whiff impulse: a whiffed swing leaves the attacker over-extended in proportion to the swing's
## kinetic energy (the follow-through that had to be decelerated), distinct from commitment
## (intensity). Same shared impulse map as the hit path: neutral at the mid band so D001 holds.


static func run_off_balance_whiff_impulse(failures: PackedStringArray) -> void:
    var base: float = CombatConstants.miss_off_balance_duration(0.5)
    _assert(base > 0.0, failures, "whiff_ob: miss base off-balance should be positive (got %.3f)" % base)
    var heavy: float = base * CombatConstants.hit_impulse_stagger_mult(95.0)
    var light: float = base * CombatConstants.hit_impulse_stagger_mult(35.0)
    var mid: float = base * CombatConstants.hit_impulse_stagger_mult(65.0)
    _assert(
        heavy > base and light < base,
        failures,
        (
            "whiff_ob: heavy whiff should over-extend more (%.3f > %.3f) and light whiff less (%.3f < %.3f)"
            % [heavy, base, light, base]
        )
    )
    # Mid-band is D001-neutral: the whiff window is unchanged from the intensity-only base.
    _assert(
        absf(mid - base) < 0.001 * base,
        failures,
        "whiff_ob: mid-band KE should be neutral (got %.4f vs base %.4f)" % [mid, base]
    )
    # Missing KE data must not fabricate a discount or extension.
    _assert(
        is_equal_approx(base * CombatConstants.hit_impulse_stagger_mult(-1.0), base),
        failures,
        "whiff_ob: missing KE should stay neutral"
    )
    # Move-type commit extras still stack on top of the impulse-scaled base.
    var feint_mid: float = mid + CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S
    var thrust_mid: float = mid + CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S
    _assert(
        feint_mid > mid and thrust_mid > mid,
        failures,
        (
            (
                "whiff_ob: feint/thrust commit extras should still stack over the impulse base (feint=%.3f thrust=%.3f "
                + "base=%.3f)"
            )
            % [feint_mid, thrust_mid, mid]
        )
    )


## Engagement-orientation stagger: a hit that meets the defender's flank or rear disrupts balance
## more than a frontal hit (the impact crosses / bypasses the base of support). Front is the neutral
## 1.0 baseline so D001 1v1 duels (always face-on) are unaffected; unknown angles degrade to 1.0.


static func run_off_balance_orientation_stagger(failures: PackedStringArray) -> void:
    _assert(
        is_equal_approx(CombatConstants.hit_orientation_stagger_mult("front"), 1.0),
        failures,
        "orient_ob: front should be the neutral 1.0 baseline"
    )
    _assert(
        (
            CombatConstants.hit_orientation_stagger_mult("flank") > 1.0
            and (
                CombatConstants.hit_orientation_stagger_mult("flank")
                < CombatConstants.hit_orientation_stagger_mult("rear")
            )
        ),
        failures,
        (
            "orient_ob: expected front < flank < rear (flank=%.2f rear=%.2f)"
            % [
                CombatConstants.hit_orientation_stagger_mult("flank"),
                CombatConstants.hit_orientation_stagger_mult("rear"),
            ]
        )
    )
    _assert(
        (
            CombatConstants.hit_orientation_stagger_mult("") == 1.0
            and CombatConstants.hit_orientation_stagger_mult("unknown") == 1.0
        ),
        failures,
        "orient_ob: unknown/empty angle should degrade to 1.0"
    )
    # Composition: same clean torso hit, rear-facing defender stags longer than front-facing.
    var front_c: Dictionary = {}
    front_c[DataKeys.PA_ENGAGEMENT_ANGLE] = "front"
    var rear_c: Dictionary = {}
    rear_c[DataKeys.PA_ENGAGEMENT_ANGLE] = "rear"
    var front_window: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", front_c)
    var rear_window: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", rear_c)
    _assert(
        rear_window > front_window,
        failures,
        "orient_ob: rear-facing defender should stagger longer (%.3f > %.3f)" % [rear_window, front_window]
    )
    # Default (no stamped angle) equals the explicit front baseline.
    var default_c: Dictionary = {}
    var default_window: float = PassiveParryContext.hit_off_balance_window(0.5, "chest", "hit", default_c)
    _assert(
        is_equal_approx(default_window, front_window),
        failures,
        "orient_ob: missing angle should default to front baseline (%.3f vs %.3f)" % [default_window, front_window]
    )


## Armor-mass inertia: heavy armor braces a defender against impact-stagger (less off-balance on a
## hit) but adds swing mass to an attacker (longer over-extension on a whiff). Both are 1.0 neutral
## with no armor (D001 default) and bounded so armor never dominates the window.


static func run_off_balance_armor_inertia(failures: PackedStringArray) -> void:
    # No armor: both sides neutral.
    _assert(
        (
            is_equal_approx(CombatConstants.hit_armor_inertia_mult(0.0), 1.0)
            and is_equal_approx(CombatConstants.whiff_armor_inertia_mult(0.0), 1.0)
        ),
        failures,
        "armor_ob: no armor should be neutral 1.0 on both sides"
    )
    # Full armor: defender staggers less, attacker over-extends more; both bounded.
    var hit_full: float = CombatConstants.hit_armor_inertia_mult(1.0)
    var whiff_full: float = CombatConstants.whiff_armor_inertia_mult(1.0)
    _assert(
        hit_full < 1.0 and hit_full > 0.5,
        failures,
        "armor_ob: full-armor defender should stagger less, bounded (got %.3f)" % hit_full
    )
    _assert(
        whiff_full > 1.0 and whiff_full < 2.0,
        failures,
        "armor_ob: full-armor attacker should over-extend more, bounded (got %.3f)" % whiff_full
    )
    # Exact constant values at full armor.
    _assert(
        (
            is_equal_approx(hit_full, 1.0 - CombatConstants.HIT_ARMOR_INERTIA_REDUCTION)
            and is_equal_approx(whiff_full, 1.0 + CombatConstants.WHIFF_ARMOR_INERTIA_EXTENSION)
        ),
        failures,
        "armor_ob: full-armor values should equal 1 -/+ the reduction/extension constants"
    )
    # Monotonic in armor ratio: hit reduction deepens, whiff extension grows.
    _assert(
        CombatConstants.hit_armor_inertia_mult(0.5) > hit_full and CombatConstants.hit_armor_inertia_mult(0.5) < 1.0,
        failures,
        "armor_ob: hit armor mult should decrease monotonically with armor"
    )
    _assert(
        (
            CombatConstants.whiff_armor_inertia_mult(0.5) < whiff_full
            and CombatConstants.whiff_armor_inertia_mult(0.5) > 1.0
        ),
        failures,
        "armor_ob: whiff armor mult should increase monotonically with armor"
    )
    # Out-of-range ratios clamp to [0,1] before lerping (no extrapolation).
    _assert(
        (
            is_equal_approx(CombatConstants.hit_armor_inertia_mult(5.0), hit_full)
            and is_equal_approx(CombatConstants.whiff_armor_inertia_mult(-5.0), 1.0)
        ),
        failures,
        "armor_ob: armor ratio should clamp to [0,1] before lerping"
    )


## Dodge->footing: a full dodge is a movement off the base of support, so the dodger is briefly
## off-balance until they re-stabilize. The window grows with the incoming strike's intensity, sits
## below the whiff base (a braced reactive dodge re-centers faster than a committed over-extension),
## and routes through off_balance_recovery_mult so agility gates re-stabilization like it does after
## a hit. This closes the footing<->dodge loop: off-balance already reduces dodge chance
## (OFF_BALANCE_DODGE_CHANCE_MULT); now dodging itself costs footing.


static func run_off_balance_dodge_stagger(failures: PackedStringArray) -> void:
    var base: float = CombatConstants.dodge_off_balance_duration(0.0)
    var heavy: float = CombatConstants.dodge_off_balance_duration(1.0)
    _assert(
        absf(base - CombatConstants.DODGE_OFF_BALANCE_BASE_S) < 0.001,
        failures,
        (
            "dodge_ob: zero intensity should equal the base constant (got %.3f, base %.3f)"
            % [base, CombatConstants.DODGE_OFF_BALANCE_BASE_S]
        )
    )
    _assert(
        heavy > base,
        failures,
        "dodge_ob: a harder incoming strike should demand a bigger evasive move (%.3f > %.3f)" % [heavy, base]
    )
    # A braced, reactive dodge re-centers faster than a forward-committed whiff.
    _assert(
        base < CombatConstants.OFF_BALANCE_DURATION_S,
        failures,
        (
            "dodge_ob: dodge base should sit below the whiff base (%.2f < %.2f)"
            % [base, CombatConstants.OFF_BALANCE_DURATION_S]
        )
    )
    # Bounded: full-intensity window stays well under the cumulative cap.
    _assert(
        heavy < CombatConstants.OFF_BALANCE_MAX_WINDOW_S,
        failures,
        "dodge_ob: full-intensity window should stay far under the cumulative cap (got %.3f)" % heavy
    )
    # Integration: the dodger's re-stabilization is gated by the same recovery system as hit
    # re-stabilization — a low-agility dodger lingers off-balance longer than a high-agility one.
    var slow_c: Dictionary = {}
    slow_c[DataKeys.COMBATANT_STATS] = {DataKeys.ENTITY_AGILITY: 10.0}
    var quick_c: Dictionary = {}
    quick_c[DataKeys.COMBATANT_STATS] = {DataKeys.ENTITY_AGILITY: 90.0}
    var slow_total: float = (
        CombatConstants.dodge_off_balance_duration(0.5) * PassiveParryContext.off_balance_recovery_mult(slow_c)
    )
    var quick_total: float = (
        CombatConstants.dodge_off_balance_duration(0.5) * PassiveParryContext.off_balance_recovery_mult(quick_c)
    )
    _assert(
        slow_total > quick_total,
        failures,
        (
            "dodge_ob: low-agility dodger should linger off-balance longer (slow=%.3f quick=%.3f)"
            % [slow_total, quick_total]
        )
    )
    # Impulse axis (this pass): a heavy incoming swing forces a bigger evasive motion, so the
    # dodger is off-balance longer. Neutral at the mid band; heavy > light. Same shared impulse map.
    var dodge_neutral: float = (
        CombatConstants.dodge_off_balance_duration(0.5) * CombatConstants.hit_impulse_stagger_mult(65.0)
    )
    _assert(
        absf(dodge_neutral - CombatConstants.dodge_off_balance_duration(0.5)) < 0.001 * base,
        failures,
        (
            "dodge_ob: mid-band incoming KE should be D001-neutral for the dodger (got %.4f vs %.4f)"
            % [dodge_neutral, CombatConstants.dodge_off_balance_duration(0.5)]
        )
    )
    var dodge_heavy: float = (
        CombatConstants.dodge_off_balance_duration(0.5) * CombatConstants.hit_impulse_stagger_mult(95.0)
    )
    var dodge_light: float = (
        CombatConstants.dodge_off_balance_duration(0.5) * CombatConstants.hit_impulse_stagger_mult(35.0)
    )
    _assert(
        dodge_heavy > dodge_neutral and dodge_light < dodge_neutral,
        failures,
        (
            "dodge_ob: heavy incoming swing should stagger the dodger more than a light one "
            + "(heavy=%.3f neutral=%.3f light=%.3f)" % [dodge_heavy, dodge_neutral, dodge_light]
        )
    )
    # Armor-inertia axis (this pass): a heavily-armored dodger re-centers the evasive step slower —
    # the same carried-mass axis as the whiff / dodge-attacker / parry self-penalties. Neutral at 0.
    var dodge_bare: float = (
        CombatConstants.dodge_off_balance_duration(0.5)
        * CombatConstants.hit_impulse_stagger_mult(65.0)
        * CombatConstants.whiff_armor_inertia_mult(0.0)
    )
    var dodge_armored: float = (
        CombatConstants.dodge_off_balance_duration(0.5)
        * CombatConstants.hit_impulse_stagger_mult(65.0)
        * CombatConstants.whiff_armor_inertia_mult(1.0)
    )
    _assert(
        is_equal_approx(dodge_bare, CombatConstants.dodge_off_balance_duration(0.5)) and dodge_armored > dodge_bare,
        failures,
        (
            "dodge_ob: armored dodger should linger off-balance longer than bare (armored=%.3f bare=%.3f)"
            % [dodge_armored, dodge_bare]
        )
    )
    # Orientation axis (this pass): dodging a rear-arc attack is harder than face-on — the dodger
    # pivots against their own center. Same shared orientation map as the hit path; face-on is 1.0.
    _assert(
        is_equal_approx(CombatConstants.hit_orientation_stagger_mult("front"), 1.0),
        failures,
        "dodge_ob_orient: face-on dodge should be D001-neutral 1.0"
    )
    _assert(
        (
            CombatConstants.hit_orientation_stagger_mult("rear") > CombatConstants.hit_orientation_stagger_mult("flank")
            and CombatConstants.hit_orientation_stagger_mult("flank") > 1.0
        ),
        failures,
        (
            "dodge_ob_orient: rear dodge should stagger more than flank, flank more than face-on "
            + (
                "(rear=%.3f flank=%.3f)"
                % [
                    CombatConstants.hit_orientation_stagger_mult("rear"),
                    CombatConstants.hit_orientation_stagger_mult("flank")
                ]
            )
        )
    )


## Attacker self-penalty on a dodged swing: a swing the defender dodges over-extends the attacker
## exactly like a whiff (the miss-path formula: commitment + impulse + move-type extras, gated by
## recovery). Locks the swing-KE helper (null weapon -> -1 neutral; real weapon positive and
## monotonic in intensity) and that a mid-band dodged swing is D001-neutral vs the miss base.


static func run_off_balance_dodge_attacker_self_penalty(failures: PackedStringArray) -> void:
    # Swing KE helper: null weapon -> -1.0 so the impulse term stays neutral (never fabricates).
    _assert(
        AttackResolver._swing_kinetic_energy_j(null, 0.5, {}, "oberhau") == -1.0,
        failures,
        "dodge_atk_ob: null weapon should return -1.0 (neutral impulse)"
    )
    var sword = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        _assert(false, failures, "dodge_atk_ob: missing SWORD fixture")
        return
    var ke_lo: float = AttackResolver._swing_kinetic_energy_j(sword, 0.2, {}, "oberhau")
    var ke_hi: float = AttackResolver._swing_kinetic_energy_j(sword, 0.9, {}, "oberhau")
    _assert(
        ke_lo > 0.0 and ke_hi > ke_lo,
        failures,
        "dodge_atk_ob: swing KE should be positive and grow with intensity (lo=%.1f hi=%.1f)" % [ke_lo, ke_hi]
    )
    # The dodged-swing self-penalty reuses the miss formula; at the mid-band KE it must be
    # D001-neutral (the impulse factor is 1.0), equal to the intensity-only miss base.
    var intensity: float = 0.5
    var mid_ke: float = 65.0
    var dodge_self: float = (
        CombatConstants.miss_off_balance_duration(intensity) * CombatConstants.hit_impulse_stagger_mult(mid_ke)
    )
    _assert(
        is_equal_approx(dodge_self, CombatConstants.miss_off_balance_duration(intensity)),
        failures,
        (
            "dodge_atk_ob: mid-band dodged swing should equal the intensity-only miss base "
            + "(got %.4f vs %.4f)" % [dodge_self, CombatConstants.miss_off_balance_duration(intensity)]
        )
    )
    # A heavy (high-KE) dodged swing over-extends the attacker more than a light (low-KE) one.
    var heavy_self: float = (
        CombatConstants.miss_off_balance_duration(intensity) * CombatConstants.hit_impulse_stagger_mult(95.0)
    )
    var light_self: float = (
        CombatConstants.miss_off_balance_duration(intensity) * CombatConstants.hit_impulse_stagger_mult(35.0)
    )
    _assert(
        heavy_self > light_self,
        failures,
        (
            "dodge_atk_ob: heavy dodged swing should over-extend more than light (heavy=%.3f light=%.3f)"
            % [heavy_self, light_self]
        )
    )


## Bind-contest off-balance penalty: the constant is a bounded discount, and the penalty fades with
## depth (1.0 when settled, < 1.0 while off-balance, reaching the constant near full depth).


static func run_off_balance_bind_contest_penalty(failures: PackedStringArray) -> void:
    _assert(
        CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT > 0.0 and CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT < 1.0,
        failures,
        (
            "bind_penalty: OFF_BALANCE_BIND_CONTEST_MULT must be in (0, 1) got %.3f"
            % CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT
        )
    )
    # Settled: no penalty.
    var settled: Dictionary = {}
    _assert(
        PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT) == 1.0,
        failures,
        "bind_penalty: settled fighter should get no penalty"
    )
    # Off-balance: a discount between the constant and 1.0.
    var ob: Dictionary = {}
    PassiveParryContext.apply_off_balance_window(ob, 1.0)
    var p: float = PassiveParryContext.off_balance_penalty_mult(ob, CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT)
    # Discount is a lerp from 1.0 (settled) to the constant (full depth), so the off-balance value is
    # bounded in [constant, 1.0). It equals the constant at full depth (same-ms read), so use >=.
    _assert(
        p >= CombatConstants.OFF_BALANCE_BIND_CONTEST_MULT and p < 1.0,
        failures,
        "bind_penalty: off-balance contest power should be discounted to [mult, 1.0) (got %.3f)" % p
    )


## Execute fumble + close-attempt off-balance constants: both must be bounded, and the execute fumble
## chance must scale with depth (0 when settled, == MAX at full depth).


static func run_off_balance_execute_and_close_constants(failures: PackedStringArray) -> void:
    _assert(
        (
            CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX > 0.0
            and CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX < 1.0
        ),
        failures,
        (
            "exec_close: execute fumble chance must be in (0, 1) got %.3f"
            % CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX
        )
    )
    _assert(
        CombatConstants.OFF_BALANCE_CLOSE_PRESSURE_MULT > 0.0 and CombatConstants.OFF_BALANCE_CLOSE_PRESSURE_MULT < 1.0,
        failures,
        "exec_close: close pressure mult must be in (0, 1) got %.3f" % CombatConstants.OFF_BALANCE_CLOSE_PRESSURE_MULT
    )
    # Fumble chance scales with depth: 0 settled, == MAX at full depth.
    var settled: Dictionary = {}
    var full: Dictionary = {}
    PassiveParryContext.apply_off_balance_window(full, 1.0)
    _assert(
        is_equal_approx(
            PassiveParryContext.off_balance_depth(settled) * CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX, 0.0
        ),
        failures,
        "exec_close: settled attacker fumble chance should be 0"
    )
    # Full depth is clamped to 1.0, so the chance equals the constant.
    _assert(
        (
            PassiveParryContext.off_balance_depth(full) * CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX
            > CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX * 0.9
        ),
        failures,
        (
            "exec_close: full-depth fumble chance should be ~MAX got %.3f"
            % (PassiveParryContext.off_balance_depth(full) * CombatConstants.OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX)
        )
    )
    # Off-balance hit-chance mult: a reduction in (0,1); settled -> 1.0 (no penalty), full depth -> the mult.
    _assert(
        CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT > 0.0 and CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT < 1.0,
        failures,
        (
            "exec_close: OFF_BALANCE_HIT_CHANCE_MULT must be in (0, 1) got %.3f"
            % CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT
        )
    )
    _assert(
        is_equal_approx(
            PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT), 1.0
        ),
        failures,
        "exec_close: settled attacker should take no hit-chance penalty"
    )
    _assert(
        is_equal_approx(
            PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT),
            CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT
        ),
        failures,
        (
            "exec_close: full-depth attacker should take the full hit-chance penalty got %.3f"
            % PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT)
        )
    )
    # Target mirror: a wobbly target is easier to hit — the boost is > 1.0, neutral when the target is
    # settled (D001), and equals the constant at full depth.
    _assert(
        CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT > 1.0,
        failures,
        (
            "exec_close: OFF_BALANCE_TARGET_HIT_CHANCE_MULT should be a boost > 1.0 got %.3f"
            % CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT
        )
    )
    _assert(
        is_equal_approx(
            PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT),
            1.0
        ),
        failures,
        "exec_close: settled target should give the attacker no hit-chance boost"
    )
    _assert(
        is_equal_approx(
            PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT),
            CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT
        ),
        failures,
        (
            "exec_close: full-depth target should give the attacker the full hit-chance boost got %.3f"
            % PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT)
        )
    )


## Strike-location off-balance: head/leg hits disrupt balance more than torso (neutral 1.0),
## arm hits least. Unknown/empty parts degrade gracefully to 1.0.


static func run_off_balance_strike_location(failures: PackedStringArray) -> void:
    _assert(
        CombatConstants.hit_part_off_balance_mult("head") == CombatConstants.HIT_OFF_BALANCE_PART_HEAD_MULT,
        failures,
        "strike_loc: head should map to head mult"
    )
    _assert(
        CombatConstants.hit_part_off_balance_mult("left_leg") == CombatConstants.hit_part_off_balance_mult("right_leg"),
        failures,
        "strike_loc: both legs should share the same mult"
    )
    _assert(
        CombatConstants.hit_part_off_balance_mult("head") > CombatConstants.hit_part_off_balance_mult("chest"),
        failures,
        "strike_loc: head should disrupt balance more than torso"
    )
    _assert(
        CombatConstants.hit_part_off_balance_mult("left_arm") < CombatConstants.hit_part_off_balance_mult("chest"),
        failures,
        "strike_loc: arm should disrupt balance less than torso"
    )
    _assert(
        is_equal_approx(CombatConstants.hit_part_off_balance_mult(""), 1.0),
        failures,
        "strike_loc: unknown part should default to 1.0"
    )


## HEMA: the damage-side commitment-quality floor stops a fully-compromised strike (off-balance +
## out of measure + over-extended cut + inside a longer-armed defender) from collapsing to a
## trivial chip. It mirrors HIT_CHANCE_MIN_CAP, which already floors compounded accuracy penalties.


static func run_attack_commit_quality_floor(failures: PackedStringArray) -> void:
    var floor: float = CombatConstants.ATTACK_COMMIT_QUALITY_FLOOR
    # Floor is a valid multiplicative bound in (0, 1).
    _assert(
        floor > 0.0 and floor < 1.0,
        failures,
        "commit_quality: ATTACK_COMMIT_QUALITY_FLOOR (%.2f) should be in (0, 1)" % floor
    )
    # Consistent with the accuracy-side cap: both floor compounded penalties at the same level.
    _assert(
        absf(floor - CombatConstants.HIT_CHANCE_MIN_CAP) < 0.001,
        failures,
        (
            "commit_quality: floor (%.2f) should match HIT_CHANCE_MIN_CAP (%.2f)"
            % [floor, CombatConstants.HIT_CHANCE_MIN_CAP]
        )
    )
    # The stack of sub-1.0 commitment penalties (off-balance x over-extended cut) can dip below
    # the floor, so the floor is load-bearing — without it the strike would collapse below the cap.
    var worst: float = (
        CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT
        * CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR
        * CombatConstants.MEASURE_DMG_CUT_OVER_REACH_FLOOR
    )
    _assert(
        worst < floor,
        failures,
        "commit_quality: worst-case stack (%.3f) should be < floor (%.2f) so the floor engages" % [worst, floor]
    )


## Regain Footing AI wiring: a staggered fighter must surface Regain Footing in its menu and the real
## picker weight must be positive + depth-scaled, so the AI re-roots instead of grinding a compromised
## strike. Settled: not listed, weight 0. Closes the "built but never picked" gap.


static func run_off_balance_regain_footing_ai_selection(failures: PackedStringArray) -> void:
    var mgr: Node = _make_1v1_sword()
    var c: Dictionary = mgr.combatants[0]
    var cid: int = CombatantEntityAccess.id_int(c)
    var rf_action: Dictionary = {"target_id": cid, "move_id": CombatConstants.MOVE_ID_REGAIN_FOOTING}
    # build() only produces a full menu for a WAITING combatant at full gauge (mirrors the live turn).
    c[DataKeys.COMBATANT_STATE] = CombatConstants.STATE_WAITING
    c[DataKeys.COMBATANT_GAUGE] = 100.0
    # Settled: not listed, weight 0.
    var settled_menu: Array = AvailableActionsBuilder.build(mgr, cid)
    _assert(
        _actions_have_move(settled_menu, CombatConstants.MOVE_ID_REGAIN_FOOTING) == false,
        failures,
        "rf_ai: settled fighter should NOT list Regain Footing"
    )
    var settled_weight: float = CombatAIActionPicker._get_action_weight(rf_action, cid, mgr, false)
    _assert(
        is_equal_approx(settled_weight, 0.0),
        failures,
        "rf_ai: settled Regain Footing weight should be 0 got %.3f" % settled_weight
    )
    # Off-balance full depth: listed + positive, ~AI_WEIGHT at depth 1.
    PassiveParryContext.apply_off_balance_window(c, 5.0)
    var ob_menu: Array = AvailableActionsBuilder.build(mgr, cid)
    _assert(
        _actions_have_move(ob_menu, CombatConstants.MOVE_ID_REGAIN_FOOTING),
        failures,
        "rf_ai: off-balance fighter should list Regain Footing"
    )
    var rf_weight: float = CombatAIActionPicker._get_action_weight(rf_action, cid, mgr, false)
    _assert(rf_weight > 0.0, failures, "rf_ai: off-balance Regain Footing weight should be > 0 got %.3f" % rf_weight)
    _assert(
        rf_weight > CombatConstants.REGAIN_FOOTING_AI_WEIGHT * 0.9,
        failures,
        (
            "rf_ai: full-depth Regain Footing weight should be ~AI_WEIGHT (%.1f) got %.3f"
            % [CombatConstants.REGAIN_FOOTING_AI_WEIGHT, rf_weight]
        )
    )
    HarnessCore._free_manager_restore_global_rng(mgr)


## Calibration guard: off-balance is a *stagger*, not a nullifier. At full depth the attacker's combined
## damage x accuracy and the defender's combined dodge x parry both stay above a floor, so a wobbly
## fighter is hurt but never auto-dead / auto-miss. Guards against a death-spiral calibration stack.


static func run_off_balance_stack_bounded(failures: PackedStringArray) -> void:
    var settled: Dictionary = {}
    var full: Dictionary = {}
    PassiveParryContext.apply_off_balance_window(full, 5.0)
    var atk_comb: float = (
        PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT)
        * PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT)
    )
    _assert(
        atk_comb > 0.30,
        failures,
        (
            "stack_bounded: full-depth attacker dmg x hit-chance (%.3f) should stay > 0.30 (stagger, not nullifier)"
            % atk_comb
        )
    )
    var def_comb: float = (
        PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT)
        * PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT)
    )
    _assert(
        def_comb > 0.30,
        failures,
        "stack_bounded: full-depth defender dodge x parry (%.3f) should stay > 0.30 (hurt, not auto-killed)" % def_comb
    )
    # Penalty must fade with depth: settled is stronger / better-armed than full depth on the same axis.
    _assert(
        (
            PassiveParryContext.off_balance_penalty_mult(settled, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT)
            > PassiveParryContext.off_balance_penalty_mult(full, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT)
        ),
        failures,
        "stack_bounded: settled attacker should be stronger than full-depth attacker"
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


static func run_formation_settle_off_balance(failures: PackedStringArray) -> void:
    var base: float = CombatConstants.FORMATION_SETTLE_OFF_BALANCE_BASE_S
    _assert(base > 0.0, failures, "form_settle: base must be > 0 got %f" % base)
    # plug -> 0.0
    _assert(
        is_equal_approx(CombatConstants.formation_settle_off_balance_duration("plug_forward"), 0.0),
        failures,
        "form_settle: plug should be 0.0 got %f" % CombatConstants.formation_settle_off_balance_duration("plug_forward")
    )
    # rotate -> base * 1.2
    var expected_rotate: float = base * CombatConstants.FORMATION_SETTLE_ROTATE_SCALE
    _assert(
        absf(CombatConstants.formation_settle_off_balance_duration("rotate_file") - expected_rotate) < 0.001,
        failures,
        (
            "form_settle: rotate should be %.3f got %f"
            % [expected_rotate, CombatConstants.formation_settle_off_balance_duration("rotate_file")]
        )
    )
    # fall_back -> base * 1.1
    var expected_fb: float = base * CombatConstants.FORMATION_SETTLE_FALL_BACK_SCALE
    _assert(
        (
            absf(CombatConstants.formation_settle_off_balance_duration(CombatConstants.MOVE_ID_FALL_BACK) - expected_fb)
            < 0.001
        ),
        failures,
        (
            "form_settle: fall_back should be %.3f got %f"
            % [expected_fb, CombatConstants.formation_settle_off_balance_duration(CombatConstants.MOVE_ID_FALL_BACK)]
        )
    )
    # apply_formation_settle with plug: no off-balance window created
    var c_plug: Dictionary = {}
    PassiveParryContext.apply_formation_settle(c_plug, "plug_forward")
    _assert(
        not PassiveParryContext.is_off_balance(c_plug),
        failures,
        "form_settle: plug should not create off-balance window"
    )
    # apply_formation_settle with rotate: creates off-balance window
    var c_rot: Dictionary = {}
    PassiveParryContext.apply_formation_settle(c_rot, "rotate_file")
    _assert(PassiveParryContext.is_off_balance(c_rot), failures, "form_settle: rotate should create off-balance window")


## Cower re-plant: healthy legs get base window; compromised legs (<0.9) get a longer window.


static func run_cower_replant_off_balance(failures: PackedStringArray) -> void:
    var base: float = CombatConstants.COWER_REPLANT_OFF_BALANCE_BASE_S
    _assert(base > 0.0, failures, "cower_replant: base must be > 0 got %f" % base)
    # Healthy legs (functionality >= 0.9): base duration
    _assert(
        is_equal_approx(CombatConstants.cower_replant_off_balance_duration(1.0), base),
        failures,
        (
            "cower_replant: healthy legs should get base (%.2f) got %f"
            % [base, CombatConstants.cower_replant_off_balance_duration(1.0)]
        )
    )
    # Compromised legs (functionality < 0.9): base * 1.4
    var expected: float = base * CombatConstants.COWER_REPLANT_LEGS_SCALE
    _assert(
        absf(CombatConstants.cower_replant_off_balance_duration(0.5) - expected) < 0.001,
        failures,
        (
            "cower_replant: compromised legs should get %.3f got %f"
            % [expected, CombatConstants.cower_replant_off_balance_duration(0.5)]
        )
    )
    # Boundary: exactly at threshold should use base (not legs scale)
    _assert(
        is_equal_approx(CombatConstants.cower_replant_off_balance_duration(0.9), base),
        failures,
        (
            "cower_replant: at threshold 0.9 should get base (%.2f) got %f"
            % [base, CombatConstants.cower_replant_off_balance_duration(0.9)]
        )
    )
