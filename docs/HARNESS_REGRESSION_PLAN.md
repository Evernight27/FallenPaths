# Harness Regression Fix Plan

**Session default:** Combat maintain. Gate: `PHASE0: PASS`. Prompts: [`agent_combat.md`](../scripts/agent_prompts/agent_combat.md).

## Current State

| Category | Fixed This Session | Remaining | Root Cause |
|----------|-------------------|-----------|------------|
| Stub identity / caching | 100% (4 files) | 0 | `load()` vs `preload()`, missing `apply_result()` chains, stub save/restore leaks |
| Medical windup INT read | 1 file | 0 | `_copy_core_stats` bypass in `CombatantEntityAccess` |
| Stub save/restore leaks | 100% (3 files) | 0 | Functions set `PROFICIENCY_ENABLED = true` without restoring old value |
| **Feint timing** | 0 | ~9 | Production behavior changed but harness expects diverging outcomes at same seed |
| **Parry / Flurry bind** | 0 | ~7 | Exchange counter lifecycle, UI suffix wiring, gauge bonus differential |
| **Interpose geometry** | 0 | ~3 | Alignment range thresholds, boundary precision, path-index bounds |
| **F5 soak under-tune** | 0 | ~4 | Deterministic numeric divergence across fields (wind-up cap, blunt floor) |
| **Targeting RNG drift** | 0 | ~2 | Body-part weight shifts, seeding strategy changes |
| **Pinch weights** | 0 | ~2 | Outnumber detection threshold, mult constant value |

## Fix Strategy

The remaining failures are **production design changes that moved without test updates**. Each requires a developer decision: update production code to match harness expectations, or update harness to match new production behavior.

---

## Phase 1 — Quick Wins (developer decisions, no new code)

These are constant-sync or threshold fixes where the developer picks one direction and we sync both sides.

### 1a. Stub gating dead-code tests
**File:** `CombatRegressionHarnessProficiencyTail.gd:127-158`
**Issue:** `_run_stub_gating_off` and `_run_copy_core_stats_no_bonuses_when_off` test stub=OFF path, but default is `true` so they skip.
**Decision needed:**
- Option A: Change default to `false` in `CompanyState.gd:79` (breaks production if anyone relies on default-on)
- Option B: Make tests explicitly set `PROFICIENCY_ENABLED = false` before running, restore after (preferred — no production impact)

### 1b. Hard-coded thresholds that should read from constants
**Files:** Multiple tail files contain numeric tolerances and thresholds not tied to `CombatConstants`.
**Examples:**
- `KinematicTail.gd:127` — mult `1.32` hard-coded (should read constant)
- `KinematicTail.gd:996` — `amb_cap = 1.12` hard-coded
- `KinematicTail.gd:540` — `parry_graze = 0.05` hard-coded
- `Proficiency1v1Tail.gd:411` — `total_gain < 0.1` threshold

**Fix:** Extract to named constants in harness, or read from production `CombatConstants.*`. Low risk either way.

### 1c. F5 soak trace validation tolerance
**File:** `CombatRegressionHarness.gd` (F5 validation functions)
**Issue:** Validates every numeric field against soak logs with `is_equal_approx`; any single constant drift fails entire scenario.
**Fix:** Increase epsilon for non-critical fields, or pin values that must stay exact vs those allowed to drift.

---

## Phase 2 — Behavioral Sync (developer provides direction, we implement)

Each item below needs a developer decision on which behavior is correct: harness expectation or production change.

### 2a. Feint Timing (~9 tests → `FeintTempoTail.gd`)
| Test | What it expects | Production dependency | Decision needed |
|------|----------------|----------------------|-----------------|
| `_run_feint_commitment_fraction_*` (lines 2681, 2756) | Feint + plain bracket reaction time differently at same wind-up | `COMMITMENT_FRACTION` vs `COMMITMENT_FRACTION_FEINT` in `DefenseChoiceResolver.choose_defense` | Did commitment fractions converge? If yes, update harness to expect identical behavior. If no, production has a bug. |
| `_run_feint_telegraph_*_spacing_long_vs_mid` (lines 2501, 2571) | LONG distance damps telegraph dodge-bite vs MID at same seed | `FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG` (< 1.0) applied in guard zone check | Did spacing mult get removed or set to 1.0? |
| `_run_feint_listing_reveal_mult_on_live_pa` (line 2438+) | Pre-reveal readiness damping affects listing weights | `feint_target_reveal_at_progress` + `_feint_readiness_reveal_mult` in MentalStackDecider | Did reveal logic change to always use full readiness? |
| `_run_defense_footwork_recovering_*` (lines 2938, 2961, 3037) | Recovery cause mult stacks with spacing; cause order matters | `DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE` table + spacing band multiplier | Did production switch to single recovery dodge value? |

**Effort:** Medium — requires reading `DefenseChoiceResolver.gd`, `MentalStackDecider.gd`, and comparing current logic vs harness expectations.

### 2b. Parry / Flurry Bind (~7 tests → `CombatRegressionHarness.gd:10659-10859`)
| Test | What it expects | Production dependency | Decision needed |
|------|----------------|----------------------|-----------------|
| `_run_flurry_bind_exchange_consumes_on_wind_up` (line 10678) | Counter decrements at wind-up start, not on hit | `FlurryBind.open_window` + `_WindUpStarter.start` decrement logic | Was consumption moved from wind-up to resolve? |
| `_run_flurry_bind_window_closes_on_hit` (line 10710) | Hit clears ALL flurry keys on both combatants | `FlurryBind.clear_pair(mgr, p_id, e_id)` called from hit resolution | Were keys retained across hits or cleared only one-sided? |
| `_run_flurry_bind_listing_restricts_to_bind_partner` (line 10732) | Melee listing shows ONLY bind partner when flurry active | `AvailableActionsBuilder.build` target filter | Was the filter removed or broadened? |
| `_run_flurry_bind_opens_on_bind_deflect` (line 10773) | Mutual windows open on BOTH sides from `parry_deflect` | `AttackResultApplier.apply_result` → `FlurryBind.open_pair_after_bind` | Was opening changed to one-sided? |
| `_run_flurry_bind_expires_after_window` (line 10807) | Window expires at `FLURRY_BIND_WINDOW_S` (0.6s) in `process_waiting` | `FlurryBind.process_waiting` expiry check | Did duration change or move to different handler? |
| `_run_flurry_bind_ui_gauge_label_*` (line 10832) | Gauge shows "Bind exchange" suffix when active | `BattleUIUpdater.gauge_label_text_for_combatant` + `FlurryBind.is_active` | Was UI suffix wiring broken? |

**Effort:** Medium — requires tracing flurry lifecycle through `_WindUpStarter`, `AttackResultApplier`, `AvailableActionsBuilder`, and `BattleUIUpdater`.

### 2c. Interpose Geometry (~3 tests → `KinematicTail.gd`)
| Test | What it expects | Production dependency | Decision needed |
|------|----------------|----------------------|-----------------|
| `_run_iv5_arm_interpose_eval` | Alignment boost computed as linear interpolation clamped 0..1 | `CombatGuardLines.arm_interpose_eval` formula | Was the interpolation changed? |
| `_run_iv5_arm_interpose_misalignment_threshold` | Guard exactly at `ARM_INTERPOSE_MIN_ANGLE_DEG` → inactive; 1 above → active | `guard_attack_misaligned_for_interpose` uses `>=` comparison | Was comparison changed from `>=` to `>` or vice versa? |
| `_run_iv5_arm_interpose_path_index_bounds` | Path index must be ≤ `ARM_INTERPOSE_MAX_PATH_INDEX` | Production checks against max constant | Did the max constant change or was the check removed? |

**Effort:** Low — constant syncs. Read values from production, update harness expectations (or vice versa).

### 2d. F5 Soak / Wind-Up Caps (~4 tests → `CombatRegressionHarness.gd`)
| Test | What it expects | Production dependency | Decision needed |
|------|----------------|----------------------|-----------------|
| `_run_f5_soak_trace_validation` | Every numeric field matches soak log within epsilon | Deterministic computation from seed | Which fields are allowed to drift? |
| `_run_wind_up_duration_bound` (line 12391) | `overhead_strike` wind-up capped at `WIND_UP_DURATION_MAX_S` | `_WindUpStarter.start` caps `state_duration` | Did cap get removed or increased? |
| `_run_kinematic_delivery_mace_weak_tap_*` (line 12413) | Weak tap raw momentum < `BLUNT_DAMAGE_MIN`; clamped path floors to min | `WeaponDamageHelper.compute_pre_armor_blunt` vs `compute_blunt_slip_pre_armor` | Did slip path also get floored? |

**Effort:** Low-Medium — constant syncs and tolerance adjustments.

### 2e. Targeting RNG (~2 tests → `Targeting1v1Tail.gd`)
| Test | What it expects | Production dependency | Decision needed |
|------|----------------|----------------------|-----------------|
| `_run_targeting_exchange` (line ~150) | Aim distribution matches expected percentages | `BodyPartConstants.get_weighted_random_part` weights from armor/health | Did body-part weights shift? |
| `_run_targeting_rng_seed_determinism` | Same seed → identical aim→actual mapping | RNG seeding strategy in harness loop | Was a non-deterministic element introduced? |

**Effort:** Medium — requires reading `BodyPartConstants.gd`, checking armor/health weight calculations, verifying RNG sequence.

### 2f. Pinch Weights (~2 tests)
| Test | What it expects | Production dependency | Decision needed |
|------|----------------|----------------------|-----------------|
| `_run_iv11_pinch_outnumber_ai_weight_suite` (line ~12249) | `AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT` applied when outnumbered in ZoC | `MentalStackDecider.try_pick` / `CombatAIActionPicker.pick_weighted` | Did the outnumber detection condition change? |
| Leader command telegraph timing | Telegraph duration based on constant; followers see it | Telegraph stamp/clear lifecycle | Did duration constant shift? |

**Effort:** Medium — requires tracing ZoC-based outnumber check in AI pick pipeline.

---

## Phase 3 — Stale Dead Code Cleanup (no test impact, but confusing)

| Issue | File:Line | Action |
|-------|-----------|--------|
| `PARRY_BIND_RIPOSTE_GAUGE_BONUS = 10.0` stale constant | `CombatConstantsParry.gd:84` | Remove — production reads from `_Stamina.PARRY_BIND_RIPOSTE_GAUGE_BONUS` (=28.0) in Stamina module |

---

## Execution Order

```
Phase 1a (stub dead-code fix)          → Developer decision: A or B
Phase 1b (threshold extraction)         → Low risk, pick canonical source
Phase 1c (F5 tolerance adjustment)      → Developer picks per-field epsilon
Phase 2c (interpose constants)          → Read production values, sync harness
Phase 2d (F5/wind-up caps)            → Constant syncs + tolerance
Phase 2e (targeting RNG weights)        → Verify BodyPartConstants unchanged
Phase 2f (pinch weight detection)       → Trace ZoC outnumber check
Phase 2a (feint timing)                → Complex — requires full logic comparison
Phase 2b (parry/bind lifecycle)         → Complex — multi-module tracing
Phase 3 (stale constant removal)        → Cosmetic, anytime
```

**Why this order:** Quick wins first reduces failure count incrementally. Complex behavioral items (2a, 2b) require the most developer context and should come after simpler syncs establish confidence.

---

## Developer Decision Checklist

Before any Phase 2 fix, answer these questions:

1. **Feint commitment fractions** — Should feints have shorter effective wind-up than plain strikes? (Yes → production bug; No → harness needs update)
2. **Flurry bind exchange timing** — Are exchanges consumed on wind-up start or on hit resolution? (Wind-up is original design; Hit was recent change)
3. **Interpose boundary comparison** — Is exact-boundary active (`>=`) or inactive (`>`)? (Exact-boundary-inactive is safer for testing)
4. **F5 soak tolerance** — Which fields must be byte-exact vs allowed ±epsilon drift? (Game state: exact; derived values: epsilon ok)
5. **Pinch outnumber detection** — What ZoC radius and ally/enemy counting logic defines "outnumbered"? (Current logic may have changed in a recent refactor)

---

## Files to Read for Each Phase

| Phase | Primary files | Secondary files |
|-------|--------------|-----------------|
| 1a | `world/CompanyState.gd`, `ProficiencyTail.gd` | — |
| 1b | Multiple tail files (thresholds) | `CombatConstants.gd` |
| 1c | `CombatRegressionHarness.gd` (F5 validation) | `.f5_soak_in.txt` |
| 2a | `DefenseChoiceResolver.gd`, `MentalStackDecider.gd`, `FeintTempoTail.gd` | `CombatConstantsParry.gd`, `CombatConstantsGuardZone.gd` |
| 2b | `FlurryBind` module, `_WindUpStarter.gd`, `AttackResultApplier.gd`, `BattleUIUpdater.gd` | `AvailableActionsBuilder.gd` |
| 2c | `CombatGuardLines.gd`, `KinematicTail.gd` | `CombatConstantsFeatureFlags.gd` |
| 2d | `_WindUpStarter.gd`, `WeaponDamageHelper.gd`, `CombatRegressionHarness.gd` | — |
| 2e | `BodyPartConstants.gd`, `Targeting1v1Tail.gd` | Weapon/armor data files |
| 2f | `MentalStackDecider.gd`, `ZoneOfControl.gd`, `CombatAIActionPicker.gd` | `CombatConstants.gd` (pinch constants) |
