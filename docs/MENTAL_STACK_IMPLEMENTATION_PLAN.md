# Mental Stack / Yomi — Implementation Plan

**Research sessions:** Observation decay, Markov transitions, cohesion/morale, attention load, deception/theory of mind, weapon form inference (staleness + cross-validation + priors), counter-read mechanics, mental stack tier behavior, combat attention aggregation.

**Scope:** `combat/` yomi & mental stack system — ~12 owning `.gd` files, 3 harness sets, 5 constant definitions.

---

## Priority Overview

| Tier | What | Why first |
|------|------|-----------|
| **P0** | Observation decay + power-law aggregation + graduated confidence | Foundation: everything else needs weighted/stale-aware yomi reads to work correctly |
| **P1** | Form inference improvements (priors, cross-validation, staleness) + counter-read gating | Blocks false positives and wrong switch penalties |
| **P2** | Tier persistence/transition graph + MS-L5/L6 cohesion/rout + attention budget | Strategic depth on top of reliable reads |
| **P3** | Deception state machine + temporal windows + multi-tick tracking | Advanced AI behavior, depends on P0-P2 infrastructure |

---

## Phase 0 (P0): Observation Decay + Aggregation Foundation

**Goal:** Make yomi observations fade over time and aggregate with diminishing returns. All downstream systems (form inference, focus drift, attention budget) benefit from this without code changes — they just read decayed/weighted data.

### Files changed
1. **`combat/CombatConstantsMentalStack.gd`** (+5 lines)
   - `YOMI_DECAY_FACTOR_PER_TICK: float = 0.92`
   - `YOMI_POWER_LAW_ALPHA: float = 0.7`
   - `YOMI_NON_ENGAGED_WEIGHT: float = 0.25`
   - `YOMI_ATTENTION_BUDGET_MAX: int = 3`
   - `COMBATANT_KEY_FORM_INFERENCE_HISTORY: String = "form_inference_history"`

2. **`combat/CombatAttention.gd`** (modify + add ~120 lines)
   - Modify `_empty_yomi_entry()`: add `"last_tick": float`, `"weighted_line_counts"`, `"weighted_move_id_counts"` defaults
   - Modify `record_attack_toward_defender(manager, attacker_id, defender, part, move_id)`: 
     - Store timestamp (`entry["last_tick"] = manager.get_game_clock()` if manager != null)
     - Compute threat weight using distance band + strength → store in `weighted_line_counts`/`weighted_move_id_counts`
   - Add `yomi_weighted_total(entry, alpha=0.7)`: power-law sum of counts (diminishing returns)
   - Add `_apply_decay_to_entry(entry, current_tick)`: lazy decay — multiply weighted counts by `pow(DECAY_FACTOR, age_in_ticks)`
   - Add `get_observation_view(entry, view_type="raw"/"weighted")`: returns snapshot with either raw or weighted counts
   - Add `get_attention_weight(c, attacker_id)`: returns 0.25–1.0 based on engagement + priority rank
   - Modify `refresh_for_waiting_tick()`: call `_apply_decay_to_entry()` before calling form inference refresh

3. **`combat/CombatWeaponForm.gd`** (modify ~10 lines)
   - In `infer_opponent_form()` at line 445: change `yomi_observation_total(entry)` → `yomi_weighted_total(entry, YOMI_POWER_LAW_ALPHA)` for the minimum obs gate check

### What stays the same
- `record_attack_toward_defender(null, ...)` calls (from resolved strike) still work — no manager means weight defaults to 1.0
- All existing harness tests pass unchanged: raw counts are preserved in `line_counts`/`move_id_counts`; only weighted variants change inference behavior
- Focus drift (`YOMI_FOCUS_DRIFT_MIN_LINE_COUNT`) uses raw counts (unchanged)

### Harness impact
- **`AttentionLoadYomiTests.gd`**: No changes needed — tests use raw focus/part/mult logic, not inference
- **`WeaponFormGaugeTests.gd`**: `WF-T2_duel_wall_recovery_gate` may see slightly different inference timing due to decay. The test feeds 5 observations rapidly (same tick), so decay has zero effect → passes unchanged
- **`WeaponFormAssignTests.gd`**: No changes needed — tests use `assign_form`, spawn defaults, mod bands

### Regression risks
- **Low.** Decay is multiplicative on weighted counts only; raw counts are untouched. Form inference still requires 4 raw observations (unchanged threshold). Weighted totals decrease slowly at first (`0.92^1 = 0.92`), so short engagements see <8% change per tick.

---

## Phase 1 (P1): Form Inference Improvements

**Goal:** Reduce false positive inferences, detect stale reads, and grade confidence for gated behavior downstream.

### Files changed
1. **`combat/CombatConstantsEncounter.gd`** (+20 lines)
   - `WF_YOMI_FORM_PRIORS: Dictionary = {"balanced": 3.0, "ox": 2.5, "wall": 2.0, "plow": 1.8, "wrath": 1.2, "fool": 1.0, "tempest": 0.5}`
   - `WF_YOMI_STALENESS_RECENT_WINDOW: int = 5`
   - `WF_YOMI_FORM_INFERENCE_MIN_SIGNAL_AGREEMENT: int = 2`

2. **`combat/CombatWeaponForm.gd`** (add ~80 lines, modify ~15)
   - Add `_prior_sum_for_weapon(weapon)`: returns sum of priors for forms supported by given weapon
   - Add `_per_signal_scores(form, entry, weapon)`: returns `{lines: float, moves: float, contacts: float, feint: float}` sub-scores per signal type
   - Add `_signal_vote_count(candidate_form, entry, weapon)`: counts how many independent signal types pick candidate as best
   - Modify `infer_opponent_form()`:
     - Add prior boost inside scoring loop: `s += (prior / prior_sum) * total_obs * 0.3`
     - After margin check passes: add `_signal_vote_count(best_form, entry, weapon) < MIN_SIGNAL_AGREEMENT → return ""`
   - Add `get_form_inference_confidence(observer, opponent_id) -> float`: returns 0.0 (no inference), 0.3 (tentative, 4–5 obs), 0.6 (moderate, 6–7 obs), or 0.85+ (confident, 8+ obs with margin scaling)

### What stays the same
- `infer_opponent_form()` still returns `String` (empty = no inference). No caller signature changes.
- The margin check (`best - second >= 0.15`) is unchanged — priors and cross-validation add gates *after* it passes, reducing false positives without changing true positive detection on clear signals

### Harness impact
- **`WeaponFormGaugeTests.gd:_run_weapon_form_wf_t2_duel_wall_recovery_gate`**: Feeds 5 `oberhau` observations → infers wrath. With priors and cross-validation: all 5 are high-line attacks (wall signature), but no feint/move signal agreement → **may fail** because wall needs ≥2 signal types to agree. Fix: test should feed a mix of line + move data that satisfies cross-validation, or lower `MIN_SIGNAL_AGREEMENT` to 1 for existing tests during transition period.
- **`WeaponFormAssignTests.gd`**: Tests at lines 656–747 use `record_attack_toward_defender` with specific patterns → may see different inference results due to priors (tempest suppressed) and cross-validation. Review each test's observation pattern against the new signal agreement gate.

### New harness tests (add to `WeaponFormGaugeTests.gd`)
- `_run_weapon_form_inference_stale_switch`: 8 wrath obs → infer wrath, then 5 fool obs → detect staleness, infer fool
- `_run_weapon_form_inference_signal_agreement`: 4 high-line-only obs → should return "" (lines signal alone < 2 votes)
- `_run_weapon_form_inference_confidence_tiers`: N=4→0.3, N=6→0.6, N=10→0.85+
- `_run_weapon_form_inference_rare_form_prior`: 4 tempest-like obs → wrath wins over tempest (prior suppression)

---

## Phase 2 (P1): Counter-Read Gating + Wrong-Penalty Tracking

**Goal:** Stop blind auto-switches; add cost to wrong reads and multi-tick adaptive behavior.

### Files changed
1. **`combat/CombatConstantsEncounter.gd`** (+15 lines) — ✅ DONE
   - `COUNTER_READ_SAME_PRESSURE_BONUS: float = 1.0` (no restriction)
   - `COUNTER_READ_NEUTRAL_TO_AGGRESSIVE_MIN_CONFIDENCE: float = 0.65`
   - `COUNTER_READ_AGGRESSIVE_TO_DEFENSIVE_MIN_CONFIDENCE: float = 0.75`
   - `COUNTER_READ_COMMITMENT_DURATION_TICKS: int = 3`
   - `OVERCOMMIT_PARRY_DEFLECT_PENALTY: float = 0.7`
   - `COMBATANT_KEY_COUNTER_READ_HISTORY`, `COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL`

2. **`combat/CombatWeaponForm.gd`** (modify `_try_assign_auto_switch`, add ~55 lines) — ✅ DONE
   - Modified `_try_assign_auto_switch`: pressure-distance confidence gating for counter-read / duel-read switches
     - Same-pressure: any confidence level works
     - Neutral→aggressive: requires ≥0.65 confidence
     - Aggressive→defensive: requires ≥0.75 confidence
     - Stamp `counter_read_committed_until = clk + COMMITMENT_DURATION` on defensive switch
   - Modified `evaluate_automatic_form`: honor commitment window (no auto-switch during lock)
   - Added `record_counter_read_outcome(c, opponent_id, success, inferred_form)` — appends to history array
   - Added `is_counter_read_committed(c, current_tick)` — checks commitment window
   - Added `count_recent_wrong_readings(c)` — counts last 5 wrong readings

3. **`combat/AttackResultApplier.gd`** (add ~25 lines) — ✅ DONE
   - Added `_evaluate_counter_read_outcome(manager, attacker_id, target_id, defender_form_at_parry)`
   - Called after `parry_deflect`, `miss`, `dodge`, and `hit` outcomes to record correctness

4. **Harness tests** (add ~60 lines to `WeaponFormGaugeTests.gd`) — ✅ DONE
   - `_run_weapon_form_phase2_pressure_gate_same_pressure`: verifies high-line-only obs don't infer (signal gate)
   - `_run_weapon_form_phase2_neutral_to_aggressive_gate`: low confidence with 3 obs stays below threshold
   - `_run_weapon_form_phase2_commitment_stamp`: yomi observation total ≥4 for inference

### What stays the same
- Same-pressure auto-switches (ox→plow) still work at any confidence level
- The `_duel_counter_form_vs_inferred` and `_counter_form_vs_inferred` internal methods are unchanged — only `_try_assign_auto_switch` gains a confidence gate
- Low-stamina and surround-pressure auto-switches bypass confidence gating entirely

### Harness impact
- **`WeaponFormGaugeTests.gd:_run_weapon_form_wf_t2_duel_wall_recovery_gate`**: Wrath→fool is aggressive→controlling. With MIN_SIGNAL_AGREEMENT=2, 5 oberhau obs may not pass signal gate → test already passes (no inference = no auto-switch needed).
- New Phase 2 tests added to `WeaponFormGaugeTests.gd:_run_weapon_form_phase2_suite()` — registered via `WeaponFormTail.gd`.

---

## Phase 3 (P2): Mental Stack Tier Transitions + Cohesion/Rout

**Goal:** Add tier persistence, explicit transition graph, and implement MS-L5/MS-L6 behavior stubs.

### Files changed
1. **`combat/MentalStackDecider.gd`** (modify ~60 lines)
   - Add `_tier_state` dictionary on combatant: `{active_tier: String, entered_at: float, consecutive_failures: int}`
   - Modify `try_pick()`: after a tier fires, stamp `_tier_state`. On next call, if same tier conditions still met within commitment window (3 ticks), skip re-evaluation and return same tier result → "persistence"
   - Add explicit transition guards: e.g., L1→L2 requires `consecutive_failures >= 2` on guard checks; L0→MS-L8 triggers when `threat_scan_score > THRESHOLD`
   - Implement MS-L5 `_check_l5_cohesion`: proximity-based morale modifier — count living allies within engagement distance, apply cohesion bonus to guard priority duration
   - Implement MS-L6 `_check_l6_rout`: trigger when guard breaks 3 consecutive times AND no living allies within range; behavior = retreat action with reduced attack capability

2. **`combat/CombatMoraleCohesion.gd`** (modify ~25 lines, was 45-line stub)
   - Implement `_compute_cohesion_modifier(combatant_id, manager)`: returns float [0.5–1.5] based on ally proximity and banner carrier presence
   - Implement `morale_check_during_rout(combatant_id, manager) -> bool`: probability of rallying increases with ally proximity

3. **`combat/CombatConstantsMentalStack.gd`** (+5 lines)
   - `MENTAL_STACK_TIER_COMMITMENT_TICKS: int = 3`
   - `MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD: int = 3` (consecutive guard breaks)

### Harness impact
- **`AttentionLoadYomiTests.gd:_run_mental_stack_medical_overrides_attack`**: Tests L0 medical override. Tier persistence doesn't affect this test (medical is always highest priority). Passes unchanged.
- New harness tests needed in `AttentionLoadYomiTests.gd`:
  - `_run_mental_stack_tier_persistence`: fire L3, verify same tier returned for commitment ticks
  - `_run_mental_stack_l5_cohesion_bonus`: place character near 2 living allies → verify cohesion bonus applied
  - `_run_mental_stack_l6_rout_trigger`: break guard 3× with no nearby allies → trigger rout

---

## Phase 4 (P2): Attention Budget + Selective Focus

**Goal:** Model limited cognitive capacity — characters can't meaningfully track yomi on more than 3 opponents simultaneously.

### Files changed
1. **`combat/CombatAttention.gd`** (add ~50 lines)
   - Add `_update_attention_priority(manager, combatant_id)` at end of `refresh_for_waiting_tick()`: ranks attackers by weighted score, marks priority rank on each entry
   - Modify `get_observation_view("weighted")`: applies attention weight multiplier (1.0 for top-3, 0.5 for others)
   - Non-engaged observations (distance=LONG): stored at 25% weight in `weighted_line_counts`

### Harness impact
- No existing harness tests check attention priority ranking or non-engaged weight reduction → passes unchanged with no modifications needed
- New test: `_run_attention_budget_degrades_excess_targets` — 1v5 engagement, verify top 3 get rank < 3, bottom 2 get degraded mult

---

## Phase 5 (P3): Deception State Machine + Temporal Windows

**Goal:** Add AI-level deception awareness and recent-vs-historical observation divergence for form-switch detection.

### Files changed
1. **`combat/yomi/YomiConstants.gd`** (new file, ~20 lines)
   - `DECEPTION_ESTABLISH_PROB: float = 0.5`
   - `DECEPTION_PROBE_THRESHOLD: int = 3` (consecutive correct reads before probing)
   - `DECEPTION_EXPLOIT_BAIT_PROB_MAX: float = 0.5`

2. **`combat/CombatAttention.gd`** (add ~40 lines)
   - Add `deception_state` sub-dict on combatant: `{phase: "Establish"/"Probe"/"Exploit", resistance: float, exploit_counter: int}`
   - Modify `get_observation_view("weighted")`: support `"recent"` view type using last N observations (tracked via timestamped counts)

3. **`combat/CombatWeaponForm.gd`** (add ~30 lines)
   - Modify `evaluate_automatic_form`: add `_should_bait_counter_read(c, opponent_id)` check — if deception_resistance > threshold and random < bait probability, skip auto-switch even when counter-read available

### Harness impact
- No existing harness tests reference deception → new tests only
- New test: `_run_deception_exploit_bait_suppression` — set opponent in "Exploit" phase → verify ≥30% of counter-reads are skipped

---

## Dependency Graph (Implementation Order)

```
Phase 0 (decay + aggregation)
    │
    ├─→ Phase 1 (form inference: priors, cross-validation, confidence)
    │       │
    │       └─→ Phase 2 (counter-read gating uses get_form_inference_confidence())
    │               │
    │               └─→ Phase 5 (deception uses counter-read history from Phase 2)
    │
    ├─→ Phase 3 (tier transitions + cohesion/rout — independent of yomi weights)
    │
    └─→ Phase 4 (attention budget — reads from weighted counts in Phase 0)
```

**Critical path:** Phase 0 → Phase 1 → Phase 2. All other phases can run in parallel once Phase 0 is merged.

---

## Regression Test Summary

| Harness File | Tests Affected | Risk Level | Action |
|-------------|---------------|------------|--------|
| `WeaponFormGaugeTests.gd` | `_run_weapon_form_wf_t2_duel_wall_recovery_gate` (lines 116–151) | **Medium** — signal agreement + confidence gating may change inference results | Update observation patterns to satisfy cross-validation; adjust confidence thresholds for pressure-gate test expectations |
| `WeaponFormAssignTests.gd` | Lines 656–747 (auto-switch tests) | **Medium** — same-pressure auto-switches unaffected, but counter-read paths gated by confidence | Review each test's inferred form against new priors + signal agreement; add new counter-read gating tests |
| `AttentionLoadYomiTests.gd` | All mental stack / attention tests | **Low** — uses raw focus parts/mults, not inference or weighted counts | No changes expected; verify after Phase 0 merge |
| `MentalStackFormationPlugTests.gd` | Tier 4.3 formation plug tests | **Low** — MS-L5/MS-L6 are currently stubs; new implementations should be compatible | Review cohesion/rout behavior against existing formation expectations |

---

## Constants Reference (All New)

### CombatConstantsMentalStack.gd
| Constant | Value | Purpose |
|----------|-------|---------|
| `YOMI_DECAY_FACTOR_PER_TICK` | 0.92 | Exponential decay: `count *= 0.92^age_ticks` |
| `YOMI_POWER_LAW_ALPHA` | 0.7 | Sub-linear aggregation: `sum(count^0.7)` |
| `YOMI_NON_ENGAGED_WEIGHT` | 0.25 | Long-distance observations count at 25% |
| `YOMI_ATTENTION_BUDGET_MAX` | 3 | Cognitive capacity limit |
| `MENTAL_STACK_TIER_COMMITMENT_TICKS` | 3 | Tier persistence window |
| `MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD` | 3 | Consecutive guard breaks before rout |

### CombatConstantsEncounter.gd
| Constant | Value | Purpose |
|----------|-------|---------|
| `WF_YOMI_FORM_PRIORS` | dict (balanced=3.0 → tempest=0.5) | Bayesian priors for rare-form suppression |
| `WF_YOMI_STALENESS_RECENT_WINDOW` | 5 | Observations in recent vs all comparison |
| `WF_YOMI_FORM_INFERENCE_MIN_SIGNAL_AGREEMENT` | 2 | Minimum signal types voting for best form |
| `COUNTER_READ_COMMITMENT_DURATION_TICKS` | 3 | Stance lock after wrong counter-read |
| `OVERCOMMIT_PARRY_DEFLECT_PENALTY` | 0.7 | Multiplier on parry readiness when overcommitted and parried |

---

## File Change Summary

| File | Lines Added | Lines Modified | Risk |
|------|------------|----------------|------|
| `CombatConstantsMentalStack.gd` | ~25 | 0 | None (constants only) |
| `CombatConstantsEncounter.gd` | ~25 | 0 | None (constants only) |
| `combat/CombatAttention.gd` | ~180 | ~30 | Medium (core data layer — but additive, preserves raw counts) |
| `combat/CombatWeaponForm.gd` | ~120 | ~25 | Medium (inference logic — needs harness validation) |
| `combat/MentalStackDecider.gd` | ~70 | ~15 | Low-Medium (tier behavior changes — test tier persistence) |
| `combat/AttackResultApplier.gd` | ~15 | ~15 | Low (adds outcome recording callback) |
| `combat/CombatMoraleCohesion.gd` | ~30 | ~15 | Low (implements stubs) |
| `combat/yomi/YomiConstants.gd` | ~20 | 0 | None (new file) |
| **Total** | **~485** | **~95** | |
