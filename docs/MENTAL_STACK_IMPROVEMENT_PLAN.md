# Mental Stack Improvement Plan - Swordmaster Gap Analysis

## Status: All 7 phases shipped

**Shipped:** Phase 4 (MS-L5 vacancy plug, 2026-06-08) · Phase 1 (MS-L6 rout layer, 2026-06-08) · Phase 2 (Feint resistance, 2026-06-12) · Phase 3 (Post-strike momentum / MS-L8, 2026-06-12) · Phase 5 (Exhaustion gradient, 2026-06-12) · Phase 6 (Positional awareness / MS-L9, 2026-06-12) · Phase 7 (Medical escalation TCCC ladder, 2026-06-12). All swordmaster gaps closed.

**Baseline:** Every phase must pass `./scripts/run_all_combat_checks.ps1` (PHASE0: PASS + ii_envelop_mopup: PASS).

## Revision History

| Date | Change |
|------|--------|
| 2026-06-12 | Fixed remaining inconsistencies: corrected risk assessment (line 389) to reference `combat_clock` instead of `current_tick()`; fixed type references ("int" → "float") in stamp-related risk assessments. All `_TacticalCombat.current_tick()` references now correctly appear only in pitfall/warning context. |
| 2026-06-11 | Major revision: corrected Phase 5 exhaustion model (simplified to single code path), fixed Phase 3 stamp design (tick-based numeric comparison instead of boolean), added rollback plans for all phases, added implementation order dependencies table, clarified Phase 2 threshold derivation from `PassiveParryContext`, completed incomplete Phase 6 geometry algorithm, resolved Phase 7 performer_id signature conflict. |
| 2026-06-11 | Corrected Phase 3 stamp design: replaced non-existent `_TacticalCombat.current_tick()` with `manager.combat_clock` (float) + 2-second tolerance window. Fixed critical bug where stamp code wrote `true` instead of clock value. Removed `momentum_layer_blocked` from CombatPostStrike module — fight-finish check stays in decider. Replaced underspecified Phase 7 escalation boost with complete `_compute_escalation_bonus` implementation. Added FEATURE flag boilerplate for Phase 3 and Phase 6. Fixed implementation order table (removed A-E labels, corrected phase numbers). Added 6 new integration test scenarios (stamp expiry, feint+post-strike, positional vs rout, medical fallback paths). Zone constants in Phase 6 now correctly reference ZoneOfControl module consts. |
| 2026-06-11 | Grounded plan in actual codebase: verified CombatConstants constants, CombatMedicalWeighting signatures, AttackResultApplier stamp write points, ZoneOfControl API surface, MentalStackConfig structure, and MentalStackDecider try_pick line numbers. Added implementation checklist template. Improved integration tests with setup/expectation/stamp columns. |

## Terminology: Layer Labels vs Numeric Stamps

The code uses **descriptive layer names** (`MENTAL_STACK_LAYER_HOLD_LINE`, `MENTAL_STACK_LAYER_ROUT`, etc.) while this plan also assigns **numeric labels** for implementation ordering. They are not the same thing and should not be conflated:

| Pre-layer guard | `MobilityRetreat.cannot_commit_melee` | Before L0 | Hard gate - if true, filters to retreat-only actions; not a decision layer |
| L0 | `SELF_MEDICAL` | 1st | Immediate peril self-aid |
| L1 | `MEDICAL` | 2nd | Ally peril - coordinated medical |
| L2 | `COUNTER` | 3rd | Counter-tempo window |
| L3 | `INCOMING` | 4th | Incoming wind-up targeting |
| L4b | `SPARSE_FIGHT` | 5th | Fight-finish tails - offense over wait/focus |
| L4 | `HOLD_LINE` | 6th | Reserve posture (wait, focus, attempt_close) |
| MS-L5 | `FORMATION_PLUG` | 7th | Vacancy plug-forward (shipped as Phase 4) |
| MS-L6 | `ROUT` | 8th | Cohesion break - flee/fall_back (shipped as Phase 1) |
| **MS-L8** | `POST_STRIKE` | 9th | Press advantage after strike (Phase 3, pending) |
| **MS-L9** | `POSITIONAL_DIS` | 10th | Surrounded + wounded - disengage (Phase 6, pending) |
| L5 / MS-L7 | `EXHAUSTION` | 11th | Disengage tunnel — soft intercept at 0.50, hard tunnel at 0.75 (shipped, extended by Phase 5) |
| **MS-WEIGHT** | *(none)* | - | Medical escalation weighting (Phase 7, picker-level only; not a layer) |
| **Pre-layer infra** | `POST_STRIKE_TICK_CLEAR` | Top of `try_pick` | Erase strike tick stamp at start of cognition cycle (Phase 3 infrastructure) |

**Rule:** Always refer to layers by their descriptive ID in code. The numeric labels are plan shorthand for ordering discussions only.

**Note on MS-WEIGHT (Phase 7):** Medical escalation is **not a decision layer** - it does not insert into `try_pick` and does not stamp `MENTAL_STACK_LAYER_*`. It operates purely at the picker weight level (`_get_medical_weight` / `CombatMedicalWeighting.compute_weight`), modifying weights for medical actions. This is intentional: medical decisions are already gated by L0/L1 layers; escalation only affects *which* medical action gets picked when the medical layer has already decided to act. The label was changed from MS-L10 to MS-WEIGHT to avoid confusion with a decision layer.

---

## Lessons Learned from Shipped Phases

These lessons inform how pending phases should be designed and implemented:

### From Phase 4 (MS-L5 Vacancy Plug)
- **Extract filter logic to the owning module.** `CombatFormationVacancyPlugs.filter_formation_plug_actions()` is the right pattern - the decider calls a single method on the specialist module. Do NOT inline filter logic in `MentalStackDecider`.
- **Layer-blocked check is essential.** `formation_plug_layer_blocked()` prevents the plug from firing when rout or other layers should take priority. Every new layer needs a similar blocked-check to avoid conflicts.

### From Phase 1 (MS-L6 Rout Triage)
- **FEATURE_* flags default off in harness, on in production.** This pattern lets harness tests verify no-regression while production gets the behavior. Use `is_feature_ms_l6_rout_enabled()` with a load-overridable wrapper (see `CombatConstants.gd` L396).
- **Rout layer has two independent gates:** `rout_layer_blocked()` (other layers take priority) and `rout_cognition_pressure()` (blood volume + formation stress). This separation is important: one gate controls *whether the layer gets a chance*, the other controls *whether conditions justify rout*.
- **Harness test naming convention is strict.** Use `_run_mental_stack_*` prefix. D001 track entries use `ii_rout_*` prefix. Both must be present for a phase to ship.

### General Patterns
- **Stamp lifecycle:** Layers stamp via `_stamp_layer_pick()` which writes `COMBATANT_KEY_MENTAL_STACK_LAYER`. The stamp is erased at the top of each `try_pick` call. New stamps that persist across turns need an explicit consumption+erase mechanism.
- **GDScript dict erase does NOT return the erased value.** `dict.erase(key)` returns `null`, not the old value. To read-and-erase atomically, use `var val = dict[key]; dict.erase(key)`. This is critical for stamp lifecycle design.
- **Filter functions return Arrays of action dicts.** They do NOT pick - picking is always done by `_AIPicker.pick_weighted()` after the filter returns. The decider controls *which* pool gets weighted-picked; the picker controls *which item* from that pool wins.

---

## Shipped Phases (reference only)

### Phase 4: MS-L5 Vacancy Plug - Shipped 2026-06-08

**What was implemented:** `MENTAL_STACK_LAYER_FORMATION_PLUG` fires between L4 hold-line and MS-L6 rout. `_VacancyPlugs.filter_formation_plug_actions()` returns plug-forward moves when a rank-0 gap exists; `MENTAL_STACK_LAYER_ROUT` does not fire until after plug check.

**Code:** `MentalStackDecider.gd` L133-142 - `CombatFormationVacancyPlugs.gd` - harness `_run_mental_stack_formation_plug_*` - D001 `ii_formation_plug`.

**FEATURE_* flag:** None (part of core mental stack, controlled by `is_feature_mental_stack_ai_enabled()`).

### Phase 1: MS-L6 Rout Triage - Shipped 2026-06-08

**What was implemented:** `MENTAL_STACK_LAYER_ROUT` fires between MS-L5 plug and L5 exhaustion. `_FormationRout.filter_rout_disengage_actions()` returns flee/fall_back pool when cohesion pressure detected; `rout_cognition_pressure()` checks blood volume + formation stress; `rout_layer_blocked()` respects fight-finish tails and medical peril gates.

**Code:** `MentalStackDecider.gd` L144-154 - `CombatFormationRout.gd` (L320 rout_layer_blocked, L338 filter_rout_disengage_actions, L361 rout_layer_eligible) - harness `_run_mental_stack_rout_*` - D001 `ii_rout_cohesion` - `ii_rout_heavy_casualties` - `ii_rout_no_stamp_when_offense_listed`.

**FEATURE_* flag:** `is_feature_ms_l6_rout_enabled()` (default off in harness, on in production).

---

## Swordmaster Rationale (Summary)

A swordmaster teaches combat through layered decision-making, not just technique. The current system already implements many of these principles well (triage priority, counter-tempo, yomi/habit tracking, weapon-form counters, exhaustion awareness, formation discipline). These gaps are where a master would push further:

| # | Swordmaster Teaching | System Gap | Phase | Status |
|---|---|---|---|---|
| 1 | "When the line breaks, run the right way" - rout is not random | MS-L6 used RNG for flee vs fall_back | **Phase 1** | **Shipped** |
| 2 | "Do not react to the feint - wait for the real attack" | No active feint-resistance gate; AI falls for bait | **Phase 2** | Pending |
| 3 | "After a good strike, press or disengage - do not linger aimlessly" | No post-strike momentum layer; fights stall | **Phase 3** | Pending |
| 4 | "Close the gap when your brother falls" - vacancy before holding position | L5 plug fires before L4 hold-line | **Phase 4** | **Shipped** |
| 5 | "When tired, reduce aggression gradually - do not fight heroically into collapse" | Binary exhaustion tunnel: full offense to complete passivity | **Phase 5** | Pending |
| 6 | "Am I fighting from good ground?" - positioning awareness | No disengage trigger for surrounded positions with blocked retreat | **Phase 6** | Pending |
| 7 | "If the bandage fails, pack it harder or tie it off" - medical escalation | Repeated same-action failures on wounds; no TCCC ladder progression | **Phase 7** | Pending |

---

## Implementation Order and Dependencies

| Phase | Files Changed | Depends On | Effort | FEATURE_* Flag |
|-------|---------|--------------|------------|--------|
| **2** | `CombatAIActionPicker.gd` (+ optional helper in `PassiveParryContext.gd`) | None | Medium | `is_feature_ms_feint_resistance_enabled()` |
| **7** | `CombatMedicalWeighting.gd`, `MedicalPhaseController.gd` | None | Medium | `is_feature_ms_medical_escalation_enabled()` |
| **5** | `CombatExhaustion.gd`, `MentalStackDecider.gd` | None (shares exhaustion module with shipped Phase 1) | Low-Medium | Extends existing `is_feature_fight_exhaustion_enabled()` |
| **3** | `MentalStackDecider.gd`, `CombatAIActionPicker.gd`, `CombatConstants.gd`, `AttackResultApplier.gd`, new `CombatPostStrike.gd` | None | Medium-Large | `is_feature_ms_post_strike_enabled()` |
| **6** | `ZoneOfControl.gd`, `MentalStackDecider.gd`, `CombatConstants.gd` | None | Large | `is_feature_ms_positional_awareness_enabled()` |

**Recommended order:** 2 → 7 → 5 → 3 → 6

- **Phase 2 (Feint resistance):** Picker-level weight adjustment only — no new dict keys, no new modules, no stamp lifecycle. Cleanest single-file change.
- **Phase 7 (Medical escalation):** Pure weight adjustments in existing functions. Signature changes use default parameters for backward compatibility. No new dict keys.
- **Phase 5 (Exhaustion gradient):** Threshold split and lerp extension in existing functions. Low risk, high behavioral impact. Shares the already-tested exhaustion module.
- **Phase 3 (Post-strike momentum):** New combatant dict key (`COMBATANT_KEY_LAST_STRIKE_TICK`), new stamp write in `AttackResultApplier`, new specialist module `CombatPostStrike.gd`, new layer in `try_pick`. Most complex of the "easy" phases.
- **Phase 6 (Positional awareness):** New O(n) geometry computation on every cognition cycle, new `is_combatant_surrounded` method in `ZoneOfControl`, cross-formation direction heuristic requires careful testing. Highest risk due to performance and correctness concerns.

**Parallelization note:** Phases 2 and 7 can be implemented in parallel (different modules, no shared state). Phase 5 depends only on shipped code. Phase 3 introduces stamp infrastructure that is independent of Phase 6, but both should be tested together in integration tests.

---

### Phase 2: Feint Resistance Gate - Picker-Level Hard Block

**Gap:** The AI has sophisticated feint listing weights (downweighting feints vs ready defenders), but no active gate that says "I see through this feint, do not commit." When a feint is listed against a defender with high readiness + settled footwork, the AI still sometimes picks it. A swordmaster teaches: "Do not react to the feint - wait for the real attack."

**Evidence in code:**
- `CombatAIActionPicker._compute_attack_weight_components` L458-513: feint listing damp is purely multiplicative (never zeroing). Even at maximum readiness, the feint weight is reduced but not eliminated.
- `CounterTempo.can_act` (L86-104): counter-tempo window already correctly rejects feints - feints do NOT open counter windows. This is working as intended.
- `PassiveParryContext.get_passive_parry_readiness`: has readiness gauges 0..1 that could inform a hard block threshold.
- `CombatWeaponForm.mod("ai_feint_listing")`: weapon-form-specific feint susceptibility multiplier.

**Clarification:** This is a **picker-level hard block**, NOT a new decision layer. It does NOT stamp `MENTAL_STACK_LAYER_*` on the combatant dict. It only affects `_get_action_weight` return value for feint moves, by returning 0.0 when conditions are met. Counter-tempo already handles feints correctly - this is a narrower gap: high-readiness defenders should reject feints even outside counter-tempo windows.

**Scope:** 2 files - `combat/CombatAIActionPicker.gd`, `combat/CombatConstants.gd`

**Readiness threshold derivation from code analysis:**

`PassiveParryContext.get_passive_parry_readiness()` returns:
- For `STATE_WAITING`: `guard_readiness_float(c)` — the combatant's `guard` field clamped to 0..1. This is set by WF/PA geometry and defaults to ~1.0 for settled fighters.
- For `STATE_RECOVERING`: lerp from curve[0] to curve[1] based on recovery progress. Default curves are `[0.5, 0.85]` (from `READINESS_BY_CAUSE["attack_hit"]`).
- Multiplied by `armor_burden_passive_readiness_mult(c)` — heavy armor can reduce readiness below 1.0 even when waiting.

A threshold of **>0.75** means: a settled fighter with decent guard (≥0.80) and no heavy armor burden will reject feints. A recovering fighter must be >89% through recovery to pass the threshold (0.75 / 0.85 ≈ 0.89). This is intentional — it represents a genuinely well-prepared defender.

**Design decisions resolved from code analysis:**

1. **Threshold basis:** The readiness threshold of >0.75 is grounded in `PassiveParryContext` behavior: for WAITING state, guard ≥0.80 passes; for RECOVERING, progress must exceed ~89% of recovery duration to pass (since curve max is 0.85). This matches the existing convention where readiness gauges 0..1 use 0.75 as a meaningful boundary for parry behavior.

2. **Weapon form interaction:** `CombatWeaponForm.mod("ai_feint_listing")` is a multiplicative factor applied within `_compute_attack_weight_components`. The hard block supersedes it - when readiness > 0.75 AND footwork is settled/recovering, the entire feint weight returns 0.0 regardless of weapon form susceptibility. Weapon forms that are more feint-prone still get blocked at this threshold.

3. **State check:** Use `_EntityAccess.state_str()` to check for `STATE_WAITING` (settled) or `STATE_RECOVERING` (recovering from prior exchange). Exclude `STATE_WINDING_UP` and any off-balance state (`_PassiveParry.is_off_balance()`).

**Changes:**
1. Add to `CombatAIActionPicker`: `_is_feint_resistance_active(defender_id: int, manager: Node) -> bool`
   ```
   Returns true when ALL of:
   - is_feature_mental_stack_ai_enabled() == true (counter-tempo is part of core mental stack)
   - PassiveParryContext.get_passive_parry_readiness(defender) > 0.75
   - defender state is STATE_WAITING or STATE_RECOVERING (not off-balance, not winding up)
   ```
   Reads from `PassiveParryContext` for readiness; `_EntityAccess.state_str()` for state; `_PassiveParry.is_off_balance()` for explicit off-balance check.

2. Add to `_compute_attack_weight_components`: when computing weight for a feint move (line 459: `if _WeaponConstants.is_feint_move(move_id)`), if `_is_feint_resistance_active(tid_feint, manager)` - return `feint_list_m = 0.0` (hard block). This is placed BEFORE the existing multiplicative damp chain so it short-circuits all other feint logic.

3. Log via `CombatDebug.flow_log` when feint resistance blocks a pick:
   ```
   "feint_resistance blocked move=%s vs defender=%d readiness=%.2f state=%s"
   ```

**What NOT to change:**
- Feint listing weights for low-readiness defenders remain unchanged.
- Counter-tempo behavior is completely untouched (it already rejects feints correctly).
- Stamina gate (`AI_FEINT_LISTING_STAMINA_GATE`) remains in effect below the hard block.
- Doctrine-specific feint multipliers (probing, pinch center, hold lane) still apply when resistance is NOT active.

**MentalStackConfig.gd update:** No config change needed - this is a picker-level weight adjustment, not a layer. It follows the master switch `is_feature_mental_stack_ai_enabled()`. The FEATURE flag in `CombatConstants.gd` provides independent enable/disable for harness testing.

**Rollback plan:** Remove `_is_feint_resistance_active` method and its call site in `_compute_attack_weight_components`. Revert any changes to `CombatConstants.gd`. No dict keys, no stamp lifecycle — pure revert of two code additions.

**Acceptance criteria (beyond harness pass):**
- Feint resistance is a picker-level weight adjustment only - it does NOT stamp `MENTAL_STACK_LAYER_*`.
- Threshold of >0.75 matches existing passive parry readiness thresholds in `PassiveParryContext`.
- Weapon form feint susceptibility (`CombatWeaponForm.mod("ai_feint_listing")`) is superseded by the hard block - no feint gets through when conditions are met.
- Off-balance defenders still fall for feints (readiness is typically low when off-balance, but the state check provides an additional guard).

**Validation:**
- Harness: `_run_mental_stack_feint_resistance_high_readiness` — attacker with feints vs high-readiness (>0.75) settled defender (STATE_WAITING) — AI should consistently reject feints (weight = 0.0), pick non-feint attacks instead
- Harness: `_run_mental_stack_feint_resistance_low_readiness_still_falls_for` — attacker with feints vs low-readiness (<0.75) or off-balance defender — feints still listed and may be picked (existing damp chain applies, no hard block)
- Harness: `_run_mental_stack_feint_resistance_winding_up_still_falls_for` — attacker with feints vs defender in STATE_RECOVERING with high readiness — if off-balance flag is set, feints should NOT be blocked (off-balance overrides readiness check)
- D001: `ii_feint_resistance_high_readiness` / `ii_feint_resistance_low_readiness_still_falls_for` / `ii_feint_resistance_winding_up`
- Counter-tempo window behavior unchanged (feints do NOT open counter windows - already working)
- No harness regression

**FEATURE flag implementation:** Add to `CombatConstants.gd`:
```gdscript
const FEATURE_MS_FEINT_RESISTANCE := true
static var _feature_ms_feint_resistance_load: int = -1

static func is_feature_ms_feint_resistance_enabled() -> bool:
    if _feature_ms_feint_resistance_load >= 0:
        return _feature_ms_feint_resistance_load != 0
    return FEATURE_MS_FEINT_RESISTANCE

static func set_feature_ms_feint_resistance_load(enabled: bool) -> void:
    _feature_ms_feint_resistance_load = 1 if enabled else 0
```

---

### Phase 3: Post-Strike Momentum Layer (MS-L8)

**Gap:** After a successful strike (especially one that wounds or forces defense), the AI has no mechanism to "press the advantage" or "disengage cleanly." It returns to the weighted pool and may wait, focus-shuffle, or even rotate away from a newly opened target. A swordmaster teaches: "After a good strike, press or disengage - do not linger aimlessly."

**Dual mechanism:** MS-L8 uses a **two-tier approach**:
1. **Filter-pool priority** (hard): `_filter_post_strike_actions()` returns a prioritized array fed to `pick_weighted()`. The pool order is: hostile melee strikes vs the struck target - `attempt_close` toward that target - `fall_back`/`wait` if the target is dead/gone. This is the primary mechanism - it narrows the action space before weighting.
2. **Weight bonus** (soft): When no post-strike filter pool matches (or when the layer falls through to the salience-damped utility pick), `_get_action_weight` applies a multiplicative bonus to strikes vs the recently struck target. This catches cases where the strike is not listed in the filter pool but is still available in the broader action list.

**Evidence in code:**
- `AttackResultApplier`: records `recovery_cause` on attacker dict (`"attack_hit"`, `"attack_deflect"`, `"attack_miss"`, `"skip"`), and `parry_against_id`/`parry_bonus_until` on defender dict - but **no "last strike landed" tick stamp exists**. No `COMBATANT_KEY_*` constant tracks this either.
- `MentalStackDecider.try_pick`: no layer for post-strike state; the cognition pipeline resets each turn.
- `CombatDebug.combat_session`: strike outcomes are logged but not consumed by AI decision-making.
- `CounterTempo.clear_riposte_chain` / `grant_riposte_chain`: there's already a riposte-chain mechanism, but it's purely counter-tempo (defense-counter), not offense-follow-up.

**Scope:** 4 files - `combat/MentalStackDecider.gd`, `combat/CombatAIActionPicker.gd`, `combat/CombatConstants.gd`, `combat/AttackResultApplier.gd`

**Design decision on filter function ownership (CORRECTED):**

> **Lesson from Phase 4:** The `_filter_post_strike_actions` function should be extracted to a specialist module (`CombatPostStrike.gd`) following the same pattern as `CombatFormationVacancyPlugs.filter_formation_plug_actions()`. The decider calls a single method on the specialist module. Do NOT inline filter logic in `MentalStackDecider`. This keeps the decider clean and makes the filter testable in isolation.

**Why a new module:** Post-strike momentum has enough complexity (checking if target is alive, filtering hostile melee strikes vs struck target, computing attempt_close eligibility, handling dead target fallback) that it warrants its own small module (~60 lines). This matches the Phase 4 pattern where vacancy plug logic lives in `CombatFormationVacancyPlugs` rather than being inline in the decider.

**Critical design decision - stamp uses numeric tick (NOT boolean):**

The original plan used a boolean stamp (`true`/`false`). This is wasteful — every cognition cycle writes and reads a boolean that is always `true` when the stamp exists. Instead, use a **numeric tick stamp**: write the current game tick number on strike hit, read and compare at the top of `try_pick`. This has two advantages:
1. The stamp naturally expires after 1 turn (tick + 1 ≠ current tick).
2. No explicit erase needed — stale values are harmless because they won't match the current tick.

The stamp is a **single-key system**:
- `COMBATANT_KEY_LAST_STRIKE_TICK := "last_strike_tick"` — stores `float` (the `combat_clock` value when the hit landed). Default value is 0.0 (no strike has been landed).
- Read-and-compare at the **start** of `try_pick`, right after L37:
  ```gdscript
  c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
  var _strike_tick_val: float = float(c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0))
  var _current_clock: float = manager.combat_clock
  var _strike_tick_active: bool = _strike_tick_val > 0.0 and absf(_strike_tick_val - _current_clock) < 2.0
  ```
- If `_strike_tick_active` is true, the stamp fires once. The `absf(... ) < 2.0` tolerance accounts for the fact that `combat_clock` is a float (seconds) rather than an integer tick — two cognition cycles within the same turn will have clocks within ~2 seconds of each other. On the next turn, the clock difference exceeds 2.0 and the stamp naturally expires without any erase call.

**Important:** The stamp uses `manager.combat_clock` directly (the CombatManager float). No preload or static method needed. The 2-second tolerance window ensures the stamp fires exactly once per strike exchange even if multiple cognition cycles happen within the same turn.

2. **Momentum duration:** Post-strike momentum lasts exactly **1 cognition cycle** (one `try_pick` call). The clock-based stamp naturally expires after one turn because the stored clock value diverges from `manager.combat_clock` by more than 2.0 seconds. Constant: `POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE := 2.0`.

3. **Strike quality differentiation:** Two tiers of weight bonus in `_get_action_weight`:
   - `POST_STRIKE_HIT_WEIGHT_BONUS := 1.1` - applied for any successful hit (`recovery_cause == "attack_hit"`).
   - `POST_STRIKE_MOMENTUM_WEIGHT_BONUS := 1.3` - applied when the strike also wounded (blood volume reduction) or forced a defense. The quality check uses the presence of `parry_against_id` on the defender dict (indicating the defender was hit and parried partially). For wound detection, we check if the target has untreated wounds via `_EntityAccess.entity_has_untreated_wounds()`.

4. **Stamp write point:** In `AttackResultApplier`, immediately after each `recovery_cause = "attack_hit"` assignment, set:
   ```gdscript
   var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
   if not atk.is_empty():
       atk[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = manager.combat_clock
   ```
   The stamp is written on the **attacker dict** only - the defender never receives it regardless of parry outcome. This must be done in all three `attack_hit` code paths (lines 427, 451, 466).

   **Critical:** Do NOT use a bare `atk` variable — resolve it from `manager` via `_EntityAccess.manager_get_combatant()`. The `apply_result` function receives `attacker_id: int`, not the dict directly. This is a common pattern in `AttackResultApplier` (see line 152: `var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)`).

5. **Edge cases:**
   - **Defender who parried:** Does NOT get post-strike momentum. The stamp only applies to the attacker who landed the hit.
   - **Miss/deflect:** Only `recovery_cause == "attack_hit"` sets the stamp. Deflections and misses do not trigger post-strike momentum.
   - **Killing blow:** Stamp is set even on killing blows (lines 427, 451) - though in practice the target is dead so there's nothing to press against. The filter will return empty for a dead target, and the stamp erases harmlessly.

**Changes:**
1. Add constants to `CombatConstants.gd`:
   ```gdscript
   const MENTAL_STACK_LAYER_POST_STRIKE := "post_strike"
   const COMBATANT_KEY_LAST_STRIKE_TICK := "last_strike_tick"
   const POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE := 2.0
   const POST_STRIKE_HIT_WEIGHT_BONUS := 1.1
   const POST_STRIKE_MOMENTUM_WEIGHT_BONUS := 1.3
   ## FEATURE flag for post-strike momentum layer.
   const FEATURE_MS_POST_STRIKE := true
   static var _feature_ms_post_strike_load: int = -1
   static func is_feature_ms_post_strike_enabled() -> bool:
       if _feature_ms_post_strike_load >= 0:
           return _feature_ms_post_strike_load != 0
       return FEATURE_MS_POST_STRIKE
   static func set_feature_ms_post_strike_load(enabled: bool) -> void:
       _feature_ms_post_strike_load = 1 if enabled else 0
   ```

   **Note:** `POST_STRIKE_MOMENTUM_TURNS` was removed — the clock-based stamp uses `POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE` instead (2.0 seconds). The stamp naturally expires when the combat clock diverges by more than 2.0 seconds from the stored stamp value.

2. Add stamp write to `AttackResultApplier`: after each `recovery_cause = "attack_hit"` assignment, add:
   ```gdscript
   var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
   if not atk.is_empty():
       atk[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = manager.combat_clock
   ```
   In three locations (lines 427, 451, 466). Only the attacker dict receives this stamp. Resolve `atk` from `manager` — do NOT assume a bare `atk` variable exists in scope.

   **CRITICAL:** The stamp value must be `manager.combat_clock` (a `float`), NOT a boolean or integer. The stamp uses combat clock comparison (`absf(stamp - current_clock) < 2.0`) at read time. Writing any other type would cause the comparison to fail or produce unexpected behavior.

3. Add to `MentalStackDecider`:
   - Stamp consumption at top of `try_pick` (right after L37):
     ```gdscript
     c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
     var _strike_tick_val: float = float(c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0))
     var _current_clock: float = manager.combat_clock
     var _strike_tick_active: bool = _strike_tick_val > 0.0 and absf(_strike_tick_val - _current_clock) < 2.0
     ```
   - **Delegate filter to specialist module:** Call `CombatPostStrike.filter_post_strike_actions(actions, combatant_id, manager, c)` — do NOT inline the filter logic in `MentalStackDecider`. This matches the Phase 4 pattern where `CombatFormationVacancyPlugs.filter_formation_plug_actions()` owns the filter.
   - Note: `_post_strike_momentum_active` helper is unnecessary with clock-based stamps. The `_strike_tick_active` local variable already carries the full state check.

4. Add new module `combat/CombatPostStrike.gd`:
   ```gdscript
   class_name CombatPostStrike
   extends RefCounted

   ## Post-strike momentum layer (MS-L8): press advantage after successful strike.
   ## Filter function owned here — MentalStackDecider calls a single method.

   const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
   const _ListedActions := preload("res://combat/CombatListedActions.gd")
   const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")

   static func filter_post_strike_actions(
       actions: Array, combatant_id: int, manager: Node, c: Dictionary
   ) -> Array:
       ## Returns a prioritized array for pick_weighted():
       ## 1. Hostile melee strikes vs the struck target (highest priority)
       ## 2. attempt_close toward that target
       ## 3. fall_back/wait if the target is dead/gone
       var out: Array = []
       # ... implementation ...
       return out
   ```

   **Note:** `momentum_layer_blocked` is NOT a method on `CombatPostStrike`. The `fight_finish_tail_active` check is performed by the decider before calling the filter, following the same pattern as MS-L6 rout (`_FormationRout.rout_layer_blocked`). This avoids an unnecessary preload of `CombatDoctrine.gd` in the new module.

4. Insert MS-L8 layer in `try_pick` after MS-L6 rout (after L154), before L5 exhaustion:
   ```gdscript
   # MS-L8: post-strike momentum - press advantage or disengage cleanly.
   # Fight-finish tails skip MS-L8 so listed offense can win via L4b sparse-fight path.
   if _strike_tick_active and _EntityAccess.id_int(c) == combatant_id:
       if not _Doctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
           var pool: Array = CombatPostStrike.filter_post_strike_actions(
               actions, combatant_id, manager, c
           )
           if not pool.is_empty():
               return _stamp_layer_pick(
                   c,
                   CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE,
                   _AIPicker.pick_weighted(pool, combatant_id, manager)
               )
   ```

5. Add to `CombatAIActionPicker._get_action_weight`: when computing weight for a melee strike move vs a target that was recently struck by this combatant (check: `_strike_tick_active` AND the action's `target_id` matches the struck target), apply `POST_STRIKE_MOMENTUM_WEIGHT_BONUS` or `POST_STRIKE_HIT_WEIGHT_BONUS` multiplicatively. The quality differentiation checks whether the defender has `parry_against_id` set (forced a defense) or has untreated wounds.

6. Add layer constant to `MentalStackConfig.gd`: add `LAYER_POST_STRIKE := "post_strike"` to the const block (L13-21), update `is_layer_active()` match arm:
   ```gdscript
   LAYER_POST_STRIKE:
       return is_enabled() and is_post_strike_enabled()
   ```
   Plus accessor method:
   ```gdscript
   static func is_post_strike_enabled() -> bool:
       return _CombatConstants.is_feature_ms_post_strike_enabled()
   ```

**Placement:** After MS-L6 rout, before L5 exhaustion (new layer between L6 and L5 in `try_pick`). The filter `_filter_post_strike_actions` should check `fight_finish_tail_active()` and defer to the L4b sparse-fight path when active, so fight-finish tails can still finish via listed offense without MS-L8 interference.

**Layer ordering with Phase 6 (MS-L9):** When both Phase 3 (post-strike, MS-L8) and Phase 6 (positional awareness, MS-L9) are implemented, MS-L8 fires first. The code structure is:
```gdscript
# After MS-L6 rout block (L144-154):

# MS-L8: post-strike momentum
if _strike_tick_active and _EntityAccess.id_int(c) == combatant_id:
    var pool = _filter_post_strike_actions(...)
    if not pool.is_empty():
        return _stamp_layer_pick(...)

# MS-L9: positional check (only when post-strike filter returns empty):
if _positional_disengage_check(manager, combatant_id, actions):
    ...

# L5: exhaustion tunnel (existing L157-170, extended by Phase 5)
```
This prevents a surrounded combatant who just landed a strike from disengaging instead of pressing the advantage.

**Risk assessment:** Medium risk - new dict key (float) on attacker combatant dicts when stamp is active. The clock-based stamp naturally expires without erase — stale values are harmless because `absf(stored_clock - current_clock)` exceeds 2.0 seconds. Low memory footprint (one float per combatant, ~20 max). Rollback: remove the stamp write in `AttackResultApplier`, remove stamp consumption from `MentalStackDecider.try_pick`, delete `CombatPostStrike.gd`, revert constants in `CombatConstants.gd` and config in `MentalStackConfig.gd`. No other code depends on `COMBATANT_KEY_LAST_STRIKE_TICK`.

**Acceptance criteria (beyond harness pass):**
- The stamp fires exactly once per strike exchange - never twice in the same cognition cycle, never carries to the next turn unless explicitly re-set by a new strike hit.
- Counter-tempo riposte chains (L2) are unaffected - post-strike fires between MS-L6 and L5, well after counter-tempo. The stamp is erased at the top of `try_pick` before any layer evaluation.
- Fight-finish tail interaction verified: when `fight_finish_tail_active()` is true, MS-L8 defers to L4b sparse-fight path (no duplicate offense picks).
- **Edge case - defender who parried:** The stamp only applies to the *attacker* who landed the hit. A defender who successfully parried does NOT get post-strike momentum.
- **Edge case - miss/deflect:** Only `recovery_cause == "attack_hit"` sets the stamp. Deflections and misses do not trigger post-strike momentum.

**Validation:**
- Harness: `_run_mental_stack_post_strike_press_wounded_target` / `_run_mental_stack_post_strike_disengage_when_target_dead` - two-combatant exchange where AI lands a wound - next turn should prefer pressing that target or disengaging if appropriate
- D001: `ii_post_strike_press_wounded_target` / `ii_post_strike_disengage_when_target_dead`
- Does not interfere with counter-tempo riposte chains (riposte is L2, post-strike is between L6 and L5)
- No harness regression

---

### Phase 5: Exhaustion Gradient - Replace Binary Tunnel with Gradual Descent

**Gap:** `exhaustion_tunnel_active` (in `CombatExhaustion.gd`) is a binary gate: below threshold, full offense possible; above, offense weight floors to `EXHAUSTION_OFFENSE_DAMP_FLOOR`. A swordmaster teaches: "When tired, reduce aggression gradually - do not fight heroically into collapse." The system should show a smooth degradation curve.

**Evidence in code:**
- `CombatExhaustion.exhaustion_tunnel_active`: boolean check against `MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` (actual value: **0.50**, per `CombatConstants.gd` L356).
- `CombatExhaustion.exhaustion_offense_weight_mult`: already has a gradual ramp from `EXHAUSTION_OFFENSE_DAMP_START` (0.25) to tunnel threshold (0.50), then floors at `EXHAUSTION_OFFENSE_DAMP_FLOOR` (0.35) above 0.50.
- `MentalStackDecider.try_pick` L157-170: exhaustion tunnel triggers hard disengage path - no gradient between "normal" and "tunnel."

**Scope:** 2 files - `combat/CombatExhaustion.gd`, `combat/MentalStackDecider.gd`

**Critical design decision on behavioral model (CORRECTED):**

The original plan's "soft intercept" at 0.50 was conceptually muddled: it used the same constant (`MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD`) for two different purposes (soft layer trigger AND hard tunnel trigger), creating confusion about what `exhaustion_tunnel_active()` means. The corrected design:

**Decision:** Keep `MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` at **0.50** and keep `exhaustion_tunnel_active()` semantics **unchanged**. This constant and function are used by existing harness tests (e.g., `p4a_ms_l7_exhaustion_threshold_parity` asserts tunnel == 0.5) and by `exhaustion_offense_weight_mult`. Do NOT repurpose this constant.

Instead, add a **new higher threshold** for the hard disengage tunnel:
- `MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD := 0.75` - new constant for the hard tunnel.
- The existing `exhaustion_tunnel_active()` (checking 0.50) now gates the **"winded" soft layer** - a filter-only approach that presents disengage actions but does not block offense from being picked.

**Behavioral model - definitive:**

| Exhaustion Range | Label | `exhaustion_tunnel_active()` | Behavior in `try_pick` |
|---|---|---|---|
| 0.0 - 0.25 | `fresh` | false | No disengage preference. Normal offense weights. |
| 0.25 - 0.50 | `fatigued` | false | Gradual offense ramp from 1.0 - 0.35 (existing behavior, unchanged). No disengage preference in `try_pick`. |
| 0.50 - 0.75 | `winded` | **true** (unchanged) | **NEW soft intercept**: presents a filtered disengage pool to `pick_weighted()`. This is filter-only - no weight boosting, just narrowing the pool. If `pick_weighted` happens to select offense from the pool, that's allowed. The stamp `MENTAL_STACK_LAYER_EXHAUSTION` is set regardless. |
| >= 0.75 | `exhausted` | true | **NEW hard tunnel**: same behavior as current code (L157-170), but now only at this higher threshold. Only disengage actions are available. |

**Important behavioral note for the "winded" soft layer:** The stamp `MENTAL_STACK_LAYER_EXHAUSTION` is set regardless of what `pick_weighted` returns within the winded pool. This means downstream consumers (UI gauges, soak traces) cannot distinguish between a combatant that chose to disengage vs one that chose to fight while "winded." This is intentional - it minimizes breaking changes. However, it means UI that displays "exhaustion layer active" will show even when the combatant fights. If this becomes problematic, a separate stamp key (e.g., `MENTAL_STACK_LAYER_EXHAUSTION_SOFT`) can be added later with no functional impact.

**Key distinction from original plan:** The "winded" soft layer uses the **same filter function** (`_filter_exhaustion_disengage_actions`) as the hard tunnel. The difference is semantic:
- At "winded" levels (0.50-0.75): the disengage pool is presented as a *preference* - `pick_weighted` may still select offense from within the pool if it has higher weight.
- At "exhausted" levels (>= 0.75): the disengage pool is a *hard gate* - only disengage actions are available and one of them must be picked.

**In practice:** Both paths use `_stamp_layer_pick(c, MENTAL_STACK_LAYER_EXHAUSTION, _AIPicker.pick_weighted(pool, ...))`. The stamp is identical, so UI/logic downstream cannot distinguish winded vs exhausted - this minimizes breaking changes.

**Critical correction on pool composition (CORRECTED):**

> **Lesson from code analysis:** Both the "winded" soft layer and "exhausted" hard tunnel currently reference `_filter_exhaustion_disengage_actions`, which already filters out some formation moves when hostile strikes are listed (`block_formation_shuffle` at L452-484). The plan's claim that "winded pool includes offense actions" is **incorrect** — the existing filter function does NOT include offensive attacks. It only returns: `wait`, `flee`, formation movement moves (`fall_back`, `rotate_file`, `swap_rank`, `drag_back`), and focus-line moves.

> The behavioral difference between "winded" and "exhausted" is NOT pool composition — it's the **presence of the soft layer gate itself**. At "winded" levels, presenting a disengage-preferred pool to `pick_weighted` creates a *preference* (disengage actions get higher weights from `_get_action_weight`). At "exhausted" levels, the existing filter behavior (blocking formation shuffle when hostile strikes listed) becomes mandatory.

> **Simplified design:** Use the SAME `_filter_exhaustion_disengage_actions` for both winded and exhausted. The behavioral difference comes from where they sit in `try_pick`: at "winded" levels, offense can still be picked via the salience-damped utility path if the filter returns empty (early return only happens when pool is non-empty). At "exhausted" levels, the combatant MUST pick from the disengage pool — if it's empty, they skip to the next layer.

**Changes:**
1. Add constant to `CombatConstants.gd`:
   ```gdscript
   const MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD := 0.75
   ```

2. In `CombatExhaustion.exhaustion_offense_weight_mult`: extend the gradual ramp from 0.25 through the new exhausted threshold (0.75), then floor at 0.35 above 0.75:
   ```gdscript
   static func exhaustion_offense_weight_mult(combatant: Dictionary) -> float:
       if not CombatConstants.is_feature_fight_exhaustion_enabled() or combatant.is_empty():
           return 1.0
       var ex: float = _EntityAccess.exhaustion_float(combatant)
       if ex >= CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD:
           return CombatConstants.EXHAUSTION_OFFENSE_DAMP_FLOOR
       if ex < CombatConstants.EXHAUSTION_OFFENSE_DAMP_START:
           return 1.0
       var span: float = maxf(0.001, CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_EXHAUSTED_THRESHOLD - CombatConstants.EXHAUSTION_OFFENSE_DAMP_START)
       var t: float = (ex - CombatConstants.EXHAUSTION_OFFENSE_DAMP_START) / span
       return lerpf(1.0, CombatConstants.EXHAUSTION_OFFENSE_DAMP_FLOOR, clampf(t, 0.0, 1.0))
   ```
   **Note:** The `tunnel` local variable and the `MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` reference are removed — this function no longer reads the tunnel constant at all. It extends the lerp range from `[0.25, 0.75]` instead of `[0.25, 0.50]`. The existing `exhaustion_tunnel_active()` function (L98-104) continues to read `MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` at 0.50 unchanged.

3. In `MentalStackDecider.try_pick` (lines 157-170): replace the existing tunnel block with a unified check that uses `_Exhaustion.exhaustion_tunnel_active(c)` for the soft intercept (unchanged from current behavior) and adds the new exhausted threshold check:
   ```gdscript
   # L5 (MS-L7): exhaustion - wait / disengage before salience utility pick.
   # Fight-finish tails skip L5 so listed offense can win via L4b or salience-damped utility pick.
   # Soft intercept at 0.50 (unchanged): presents disengage pool to pick_weighted().
   # Hard tunnel at 0.75: only disengage actions available (offense weight floors at 0.35).
   if (
       _Exhaustion.exhaustion_tunnel_active(c)  # true when exhaustion >= 0.50
       or _EntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
   ):
       if not _Doctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
           var disengage_pool: Array = _filter_exhaustion_disengage_actions(
               actions, combatant_id, manager, c
           )
           if not disengage_pool.is_empty():
               return _stamp_layer_pick(
                   c,
                   CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION,
                   _AIPicker.pick_weighted(disengage_pool, combatant_id, manager)
               )
   ```
   **Note:** The `try_pick` code block itself is unchanged from current behavior — it still calls `_Exhaustion.exhaustion_tunnel_active(c)` which reads `MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` at 0.50. The behavioral difference between "winded" (0.50-0.75) and "exhausted" (>=0.75) comes entirely from the extended lerp in `exhaustion_offense_weight_mult`: at "winded" levels offense weight is ~0.675 (pick_weighted may select offense), at "exhausted" levels it floors at 0.35 (disengage dominates).

**Simplified design:** Both "winded" and "exhausted" use the identical `_filter_exhaustion_disengage_actions` filter and identical code path. The behavioral difference is purely in `exhaustion_offense_weight_mult`: at "winded" levels (0.50-0.75), offense weight mult is ~0.675 (midpoint of extended lerp), so `pick_weighted` has a meaningful chance to select offense from within the pool. At "exhausted" levels (>= 0.75), offense weight floors at 0.35, making disengage actions dominate `pick_weighted`. This is a much simpler design than the original two-tier approach and avoids code duplication.

**Behavioral impact note:** At exhaustion 0.50, the current code returns 0.35 (hard floor) for offense weight mult. After this change it returns ~0.675 (midpoint of the extended lerp). This is intentional - the "winded" zone should allow more aggressive offense than the old hard floor, with disengage preference handled by `try_pick` layer presentation instead. Harness tests that assert specific weight values at exhaustion 0.50-0.74 will need updating.

**Key simplification:** The original plan's two-tier approach (separate winded pool vs hard pool) was unnecessary. A single code path with different offense weight mults produces the correct behavioral difference: `pick_weighted` naturally prefers disengage at low offense weights and is more balanced at mid-range weights.

**Risk assessment:** Low risk - no new dict keys, no new modules. The change is purely a threshold split and lerp extension in existing functions. Rollback: revert the two changes to `exhaustion_offense_weight_mult` and re-instate the original single-threshold block in `try_pick`. Existing harness test `p4a_ms_l7_exhaustion_threshold_parity` validates that the 0.50 constant is unchanged.

**Acceptance criteria (beyond harness pass):**
- `exhaustion_tunnel_active()` still returns true at exhaustion 0.50 - the constant and function semantics are unchanged. Only the *interpretation* in `try_pick` changes (soft intercept vs hard gate).
- At exhaustion 0.75, the hard tunnel fires (not just soft layer) - the "exhausted" zone must be distinctly more passive than "winded."
- Existing test `p4a_ms_l7_exhaustion_threshold_parity` at L1897-1916 of `CombatRegressionHarnessAttentionFootworkTail.gd` passes without modification.

**Validation:**
- Harness: `_run_mental_stack_exhaustion_gradient_fresh` / `_run_mental_stack_exhaustion_gradient_fatigued` / `_run_mental_stack_exhaustion_gradient_winded` / `_run_mental_stack_exhaustion_gradient_exhausted` - combatant with escalating exhaustion (0.3, 0.5, 0.7, 0.85) - observe behavior shift from "slightly less aggressive" to "disengaging"
- `p4a_ms_l7_exhaustion_threshold_parity` unchanged (still asserts tunnel threshold == 0.50)
- Existing harness fixtures at TUNNEL_THRESHOLD +/- offsets unchanged
- No harness regression

---

### Phase 6: Positional Awareness - Surrounded Combatant Disengage Trigger (MS-L9)

**Gap:** The AI has no awareness of being surrounded (hostiles on multiple sides, blocked retreat paths). A combatant trapped in a pocket with no safe retreat should disengage or flee rather than fight to the death. A swordmaster teaches: "Am I fighting from good ground?"

**Evidence in code:**
- `ZoneOfControl`: tracks zone geometry (front, left_flank, right_flank, rear) per formation via `zone_geometry_line_context`. Has `opponent_formation_for_listing` and `pair_formations_for_targeting` for targeting - but these are listing/targeting helpers, not combatant-level occupancy checks.
- `CombatFormationRout.formation_stress_abandonment_path` (L160-176): checks blood volume + formation stress but NOT positional enclosure.
- `CombatantEntityAccess.is_in_immediate_peril` (via `_Attention`): checks current turn danger, not positional trap.
- `CombatAIActionPicker._get_action_weight`: no weight for "surroundedness" or "blocked retreat."

**Scope:** 3 files - `combat/ZoneOfControl.gd`, `combat/MentalStackDecider.gd`, `combat/CombatConstants.gd`

**Implementation approach - refined with existing API references (CORRECTED):**

> **Lesson from code analysis:** The original plan assumed `zone_geometry_line_context` provides "lane-to-slot mappings that can be checked for hostile occupancy." This is **incorrect**. `zone_geometry_line_context` returns only the combatant's own formation info (`fid` + `formation` dict). It does NOT contain hostile slot occupancy data.
>
> The correct approach requires iterating `manager.combatants` and checking each one's formation + slot relative to the target combatant's formation. This is O(n) where n = total combatants (typically < 20), which is cheap in practice.

**Definition of "surrounded" - precise geometry rules:**

A combatant is "surrounded" when BOTH conditions are met:
1. **Hostile flank pressure:** Hostile combatants occupy slots in >= 2 of these directions relative to the combatant's formation: `front`, `left_flank`, `right_flank`. Rear is excluded - a combatant can have enemies behind them without being "surrounded" because they can still face forward and fight.
2. **Blocked retreat:** Both `flee` and `fall_back` moves are absent or blocked in the current action list. If at least one legal formation retreat move exists, the combatant has an escape route and is NOT surrounded.

**Implementation approach - using existing ZoneOfControl helpers:**

The `is_combatant_surrounded` function uses these existing ZoneOfControl methods:
- **`zone_geometry_for_combatant(manager, combatant)`** — gets target's zone geometry pack (fid + formation dict)
- **`ZoneOfControl.zone_geometry_fid_from_pack(pack)`** — extracts the formation ID string
- **`ZoneOfControl.zone_geometry_formation_from_pack(pack)`** — extracts the formation record
- **`ZoneOfControl.zone_for_cell(files, ranks, rank, file)`** — maps a slot's (rank, file) to a zone name (`front`, `left_flank`, `right_flank`, `rear`)
- **`ZoneOfControl.count_alive_in_zone(manager, fid, zone)`** — counts alive combatants in a specific zone of a formation

The algorithm determines which zone each hostile occupies relative to the target's formation:
1. Resolve the target's formation ID and formation record via `zone_geometry_for_combatant`.
2. For each hostile (alive, opposite side), resolve their formation ID. If same formation as target, use their rank/file to determine which zone they occupy via `zone_for_cell`. If different formation, check if their formation is adjacent in the manager's formation layout and compute approximate direction based on formation positions.
3. Track which of {front, left_flank, right_flank} have hostile presence. Rear is excluded by design.

```gdscript
## ZoneOfControl.gd — add this method to the class.
## ZONE_FRONT, ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK are module-level consts (L18-20).
static func is_combatant_surrounded(manager: Node, combatant_id: int) -> bool:
    var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty(): return false
    var my_zg: Dictionary = zone_geometry_for_combatant(manager, c)
    var my_fid: String = zone_geometry_fid_from_pack(my_zg)
    var my_formation: Dictionary = zone_geometry_formation_from_pack(my_zg)
    if my_formation.is_empty(): return false

    var hostile_zones: Array = [false, false, false]  # front, left_flank, right_flank
    for other in manager.combatants:
        if not _EntityAccess.alive_bool(other): continue
        if _EntityAccess.side_str(other) == _EntityAccess.side_str(c): continue
        var other_zg: Dictionary = zone_geometry_for_combatant(manager, other)
        var other_fid: String = zone_geometry_fid_from_pack(other_zg)
        # Same formation: use rank/file to determine zone relative to target.
        if other_fid == my_fid:
            var zone: String = zone_for_cell(
                int(my_formation.get("files", 1)),
                int(my_formation.get("ranks", 1)),
                _EntityAccess.rank_int(other),
                _EntityAccess.file_int(other)
            )
            if zone == ZONE_FRONT: hostile_zones[0] = true
            elif zone == ZONE_LEFT_FLANK: hostile_zones[1] = true
            elif zone == ZONE_RIGHT_FLANK: hostile_zones[2] = true
        # Different formation: approximate direction based on formation layout.
        # This requires access to manager.formations to determine relative positions.
        # Simplified heuristic: if hostile's formation ID sorts before/after target's,
        # treat as left_flank/right_flank respectively (assumes formations are indexed left-to-right).
        else:
            if other_fid < my_fid: hostile_zones[1] = true   # assumed left flank
            else: hostile_zones[2] = true                      # assumed right flank

    return hostile_zones.count(true) >= 2
```

**Note:** Since `is_combatant_surrounded` is a static method on `ZoneOfControl`, the zone constants (`ZONE_FRONT`, `ZONE_LEFT_FLANK`, `ZONE_RIGHT_FLANK`) are accessible without a module prefix — they are module-level consts defined at L18-20 of `ZoneOfControl.gd`.

**Changes:**
0. Add constants to `CombatConstants.gd`:
   ```gdscript
   const MENTAL_STACK_LAYER_POSITIONAL_DIS := "positional_dis"
   ```

1. Add to `ZoneOfControl`: `is_combatant_surrounded(manager: Node, combatant_id: int) -> bool`
   - New function that computes directional hostile presence using existing zone geometry helpers.
   - Must be efficient: O(n) where n = total combatants (typically < 20). Uses `zone_geometry_for_combatant` for each combatant — no allocation in the inner loop (dicts are read-only lookups).
   - Uses `_EntityAccess.side_str()` to distinguish friend from foe.
   - For same-formation hostiles, uses `zone_for_cell` for precise zone determination. For cross-formation hostiles, uses a simplified heuristic based on formation ID ordering.
   - **Simplification note:** The cross-formation direction heuristic (comparing formation ID strings) is intentionally conservative — it may over-count flank pressure in complex multi-formation encounters, which causes false-positive surrounded detection rather than false negatives. This is acceptable: a combatant who disengages unnecessarily when not truly surrounded is safer than one who fights to the death when they should flee.

2. Add to `MentalStackDecider`: `_positional_disengage_check(manager: Node, combatant_id: int, actions: Array, c: Dictionary) -> Array`
   - Returns empty array when not surrounded OR when combatant is healthy (blood >= 80% AND exhaustion < 0.75).
   - Returns weighted disengage array when conditions met: `[fall_back first, flee second, wait third]`.
   - Checks `rout_layer_blocked()` — if rout layer is blocked (e.g., by medical peril), positional check should also defer (rout has priority over positional).

3. Insert MS-L9 check in `try_pick` after MS-L8 post-strike (if implemented) but before L5 exhaustion:
   ```gdscript
   # MS-L9: positional awareness - disengage when surrounded and vulnerable.
   if not _FormationRout.rout_layer_blocked(manager, c, actions, combatant_id):
       var pos_pool: Array = _positional_disengage_check(manager, combatant_id, actions, c)
       if not pos_pool.is_empty():
           return _stamp_layer_pick(
               c,
               CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS,
               _AIPicker.pick_weighted(pos_pool, combatant_id, manager)
           )
   ```

**MentalStackConfig.gd update:** Add `LAYER_POSITIONAL_DIS := "positional_dis"` to the const block (L13-21), plus accessor and match arm:
```gdscript
static func is_positional_awareness_enabled() -> bool:
    return _CombatConstants.is_feature_ms_positional_awareness_enabled()
```
In `is_layer_active()` match arm, add:
```gdscript
LAYER_POSITIONAL_DIS:
    return is_enabled() and is_positional_awareness_enabled()
```

**Risk assessment:** Medium risk - new geometry computation runs every cognition cycle on every combatant when Phase 6 is active. The O(n) iteration over all combatants is cheap in practice (< 20 combatants), but it's a new hot path that didn't exist before. Must ensure no allocation churn in the inner loop (dicts are read-only lookups, `hostile_zones` array is stack-allocated). Rollback: remove `is_combatant_surrounded` from `ZoneOfControl`, remove `_positional_disengage_check` from `MentalStackDecider`, revert MS-L9 block from `try_pick`, revert constants in `CombatConstants.gd` and config in `MentalStackConfig.gd`. No other code depends on `MENTAL_STACK_LAYER_POSITIONAL_DIS`.

**Acceptance criteria (beyond harness pass):**
- `is_combatant_surrounded` returns false when the combatant has at least one legal retreat move (`flee` or `fall_back` listed), regardless of flank pressure.
- Healthy (blood >= 80%), well-positioned combatants are completely unaffected - no weight changes, no disengage preference.
- The check does not interfere with MS-L6 rout: rout fires first and has its own cohesion pressure gate; positional awareness only triggers when rout's `rout_layer_blocked()` or `rout_cognition_pressure()` prevents it.
- Single-combatant formations never trigger the surrounded check (no flank geometry exists).

**Validation:**
- Harness: `_run_mental_stack_positional_awareness_surrounded_disengage_wounded` / `_run_mental_stack_positional_awareness_healthy_unaffected` - place combatant with 2+ hostile neighbors and no retreat path - should disengage when wounded/exhausted
- D001: `ii_surrounded_disengage_wounded` / `ii_surrounded_healthy_unaffected`
- Healthy, well-positioned surrounded combatants are unaffected
- No harness regression

---

### Phase 7: Medical Escalation Ladder - TCCC Progression on Repeated Failure

**Gap:** When a medical action fails (e.g., bandage doesn't hold, packing fails), the AI may retry the exact same action multiple times. A swordmaster teaches: "If the bandage fails, pack it harder or tie it off." The system should escalate: bandage - pack - tourniquet (TCCC ladder).

**Evidence in code:**
- `CombatMedicalWeighting.compute_weight()` (L16): delegates to a chain of sub-computations including `_compute_failed_part_retry_weight` at L50.
- `CombatMedicalWeighting._compute_failed_part_retry_weight` (L96-104): applies `MEDICAL_AI_WEIGHT_FAILED_PART_RETRY` (2.8) when a part is in `failed_medical_parts` - but this makes the AI *prefer* retrying the same action, not escalate.
- `MedicalPhaseController`: tracks `failed_medical_parts` array on combatant dicts; defines `MEDICAL_AI_WEIGHT_FAILED_PART_RETRY` at L72.
- `CombatConstants.MOVE_ID_BANDAGE_SELF` - `MOVE_ID_PACK_WOUND` - `MOVE_ID_APPLY_TOURNIQUET`: the TCCC escalation ladder already exists as move IDs.
- `BleedingConstants`: bleeding severity tiers that should drive escalation decisions.

**Critical clarification on `failed_medical_parts` semantics:** The existing code tracks **parts**, not individual actions. When a medical procedure fails, the *part* (e.g., `"chest"`) is added to `failed_medical_parts`. On success, the part is removed from the array. This means:
- If bandage on chest fails - `"chest"` is in `failed_medical_parts`
- If pack on chest then succeeds - `"chest"` is removed (array is now empty for that part)
- If bandage on chest fails again later - `"chest"` is re-added

Phase 7's escalation logic must work at the **part level** (same as existing tracking): when a part is in `failed_medical_parts`, check if a higher-tier TCCC action is available for that part. The escalation decision does NOT need to track which specific action failed - it only needs to know that *some* action on this part failed and a better option exists.

**Scope:** 2 files - `combat/CombatMedicalWeighting.gd`, `combat/MedicalPhaseController.gd` (plus weight boost in `combat/CombatAIActionPicker.gd`)

**Critical interaction with existing code:** The existing `MEDICAL_AI_WEIGHT_FAILED_PART_RETRY` (value 2.8, defined in `MedicalPhaseController.gd` L72) makes the AI *prefer* retrying the same action. This constant is read in `CombatMedicalWeighting._compute_failed_part_retry_weight` (L103). Phase 7 must **explicitly override this** - the escalation logic takes priority over the retry bonus. When a higher-tier action is available on the TCCC ladder, the retry bonus should NOT apply to the failed step.

**Design decisions resolved from code analysis:**

1. **Self vs ally distinction (CORRECTED):** The TCCC ladder has separate move IDs for self and ally:
   - Self: `MOVE_ID_BANDAGE_SELF` - `MOVE_ID_PACK_WOUND` - `MOVE_ID_APPLY_TOURNIQUET`
   - Ally: `MOVE_ID_BANDAGE_ALLY` - `MOVE_ID_PACK_WOUND` - `MOVE_ID_APPLY_TOURNIQUET`

   Note: `MOVE_ID_PACK_WOUND` and `MOVE_ID_APPLY_TOURNIQUET` are shared (not self/ally variants). The `escalation_path_for_part` function must determine which bandage variant to use based on whether `tgt_id == performer_id` (self) or not (ally).

2. **TCCC order enforcement:** Never skip from bandage directly to TK when pack is available and valid. The `escalation_path_for_part` function must return steps in strict TCCC order and the escalation check should only consider the *next* available step, not jump ahead.

3. **Medical budget constraints:** Cannot TK if no TK item in inventory, cannot pack if no packing material. Budget check is part of `medical_action_allowed()`. The escalation path function must filter to only actions that pass this check.

4. **Performer ID propagation (CORRECTED):** The existing `_compute_failed_part_retry_weight` signature in `CombatMedicalWeighting.gd` is:
   ```gdscript
   static func _compute_failed_part_retry_weight(
       a: Dictionary, tgt: Dictionary, mid: String, w: float
   ) -> float:
   ```
   The escalation logic needs the performer ID to determine self vs ally bandage variant. **Add `performer_id` parameter with default and propagate from `compute_weight()`:**
   - Update signature: `_compute_failed_part_retry_weight(a, tgt, mid, w, performer_id: int = -1) -> float` (default preserves backward compatibility).
   - Update call site in `compute_weight()` at L50: `w = _compute_failed_part_retry_weight(a, tgt, mid, w, combatant_id)` — `combatant_id` is the first parameter of `compute_weight()`.
   - The `_escalation_path_has_next_step` helper also needs `manager` passed through since it calls `escalation_path_for_part(tgt_id, performer_id, part, manager)`. Update its signature to: `_escalation_path_has_next_step(tgt, part, current_action, manager, performer_id) -> bool`.

**Changes:**
0. Add constant to `CombatConstants.gd`:
   ```gdscript
   const MEDICAL_AI_WEIGHT_ESCALATION_BONUS := 1.5
   ```

1. Add to `MedicalPhaseController`: `escalation_path_for_part(tgt_id: int, performer_id: int, part: String, manager: Node) -> Array[String]`
   - Returns the TCCC ladder for a given wound part in strict order:
     ```
     [bandage_self_or_ally, MOVE_ID_PACK_WOUND, MOVE_ID_APPLY_TOURNIQUET]
     ```
   - Filtered to only actions that are still listed and valid (pass `medical_action_allowed()`).
   - Checks `failed_medical_parts` on the target combatant dict. Since `failed_medical_parts` tracks parts (not actions), if the part is in the array, all steps up to and including the current step are considered "failed."
   - Self vs ally: determines bandage variant based on `tgt_id == performer_id`.

2. Add `_escalation_path_has_next_step(tgt, part, current_action, manager, performer_id) -> bool` to `CombatMedicalWeighting`:
   ```gdscript
   static func _escalation_path_has_next_step(
       tgt: Dictionary, part: String, current_move_id: String,
       manager: Node, performer_id: int
   ) -> bool:
       if performer_id < 0:
           return false
       var path: Array = _MedicalPhase.escalation_path_for_part(
           int(tgt.get("id", -1)), performer_id, part, manager
       )
       var current_idx: int = path.find(current_move_id)
       if current_idx < 0 or current_idx >= path.size() - 1:
           return false
       # There is a next step - check it's actually available (not filtered by budget).
       return true
   ```

3. Modify `_compute_failed_part_retry_weight` in `CombatMedicalWeighting`: add an escalation-aware guard BEFORE applying the retry bonus:
   ```gdscript
   static func _compute_failed_part_retry_weight(
       a: Dictionary, tgt: Dictionary, mid: String, w: float,
       performer_id: int = -1, manager: Node = null
   ) -> float:
       var failed_raw: Variant = tgt.get("failed_medical_parts", null) if not tgt.is_empty() else null
       if (
           failed_raw is Array
           and part_in_array(failed_raw as Array, a.get("target_part", ""))
           and CombatConstants.is_wind_up_medical_move(mid)
       ):
           # Escalation check: is a higher-tier action available?
           var escalation_available: bool = _escalation_path_has_next_step(
               tgt, a.get("target_part", ""), mid, manager, performer_id
           )
           if escalation_available:
               return w  # Suppress retry bonus - escalate instead
           return w * _MedicalPhase.MEDICAL_AI_WEIGHT_FAILED_PART_RETRY
       return w
   ```
   **Note:** `manager` is also added as a parameter (with null default) because `_escalation_path_has_next_step` needs it to call `escalation_path_for_part`. The call site in `compute_weight()` passes both `combatant_id` and `manager`:
   ```gdscript
   w = _compute_failed_part_retry_weight(a, tgt, mid, w, combatant_id, manager)
   ```

4. Add escalation boost in `CombatMedicalWeighting.compute_weight()`: after all sub-computations return (after L59), apply an escalation bonus if the action IS a higher-tier step on the TCCC ladder:
   ```gdscript
   ## At the bottom of compute_weight(), before `return maxf(w, 0.001)`:
   if is_feature_ms_medical_escalation_enabled() and CombatConstants.is_wind_up_medical_move(mid):
       var escalation_boost: float = _compute_escalation_bonus(tgt, part, mid, combatant_id, manager)
       w *= escalation_boost
   ```
   The `_compute_escalation_bonus` helper (new private method in `CombatMedicalWeighting`):
   ```gdscript
   static func _compute_escalation_bonus(
       tgt: Dictionary, part: String, current_move_id: String,
       performer_id: int, manager: Node
   ) -> float:
       if performer_id < 0:
           return 1.0
       var path: Array = _MedicalPhase.escalation_path_for_part(
           int(tgt.get("id", -1)), performer_id, part, manager
       )
       if path.is_empty():
           return 1.0
       var current_idx: int = path.find(current_move_id)
       if current_idx < 0:
           return 1.0
       # Check if there are failed parts that make this a "higher-tier" step.
       var failed_raw: Variant = tgt.get("failed_medical_parts", null)
       if failed_raw is not Array:
           return 1.0
       var failed_list: Array = failed_raw as Array
       if failed_list.is_empty():
           return 1.0
       # If the current step is NOT the first in the path, and the part has failed,
       # this is an escalation — apply bonus.
       if current_idx > 0 and part_in_array(failed_list, part):
           return CombatConstants.MEDICAL_AI_WEIGHT_ESCALATION_BONUS
       return 1.0
   ```
   **Key logic:** The bonus applies when (a) the action is a valid step on the TCCC ladder for this part, AND (b) it is NOT the first step (i.e., there are higher steps available), AND (c) the part has failed medical parts. This ensures pack gets 1.5x when bandage failed, and TK gets 1.5x when bandage+pack both failed.

5. Update `_compute_failed_part_retry_weight` call site in `CombatMedicalWeighting.compute_weight()` to pass both `combatant_id` and `manager`:
   ```gdscript
   w = _compute_failed_part_retry_weight(a, tgt, mid, w, combatant_id, manager)
   ```

**Note:** Phase 7 does NOT modify `CombatAIActionPicker._get_medical_weight`. The entire medical weighting logic lives in `CombatMedicalWeighting.compute_weight()` (extracted in a prior refactor). All changes are confined to `CombatMedicalWeighting.gd` and `MedicalPhaseController.gd`.

**MentalStackConfig.gd update:** Phase 7 (MS-WEIGHT) is NOT a decision layer, so it does NOT add a `LAYER_*` constant or enter the `is_layer_active()` match. However, the feature flag accessor is still needed:
```gdscript
static func is_medical_escalation_enabled() -> bool:
    return _CombatConstants.is_feature_ms_medical_escalation_enabled()
```
The master switch `is_feature_ms_mid_infight_med_enabled()` (which is always true) controls whether mid-fight ally medical listing runs. Phase 7's escalation weighting only affects picker weights within existing L0/L1 medical layers — it does not create a new layer or change listing behavior.

**Risk assessment:** Low risk - no new dict keys, no new modules, no changes to action listing. The change is purely weight adjustments in existing functions. Signature change to `_compute_failed_part_retry_weight` uses a default parameter (`performer_id: int = -1`) so existing call sites (if any outside `compute_weight()`) remain compatible. Rollback: revert `_compute_failed_part_retry_weight` signature and body to original, remove `_escalation_path_has_next_step` from `CombatMedicalWeighting`, remove `escalation_path_for_part` from `MedicalPhaseController`. No other code depends on these new methods.

**Acceptance criteria (beyond harness pass):**
- When a part has failed bandage AND pack is listed - pack gets 1.5x boost, bandage retry bonus is suppressed. The AI does NOT prefer bandage over pack on a wounded part.
- When no higher-tier action is available (e.g., no pack item in inventory) - the existing retry bonus applies normally. The AI falls back to retrying the same action when escalation is impossible.
- TCCC order is strict: bandage - pack - TK. No skipping steps.
- Medical budget constraints honored: cannot TK if no TK item in inventory, cannot pack if no packing material. Budget check is part of `medical_action_allowed()`.
- **Success clears the path:** When a medical action succeeds on a part, that part is removed from `failed_medical_parts` (existing behavior). The escalation bonus resets - subsequent actions on that part return to normal weights until another failure occurs.

**Validation:**
- Harness: `_run_mental_stack_medical_escalation_bandage_to_pack` / `_run_mental_stack_medical_respect_tccc_order` - combatant with wound that failed bandage twice - should escalate to pack or TK
- D001: `ii_medical_escalation_bandage_to_pack` / `ii_medical_respect_tccc_order`
- TCCC order respected: never skip from bandage directly to TK when pack is available and valid
- Medical budget constraints honored (cannot TK if no TK item in inventory)
- Retry bonus correctly suppressed when escalation path exists
- No harness regression

---

## Stacked-Phase Integration Tests

When multiple phases are active simultaneously, their layer interactions must be validated. The following scenarios should be tested once all phases are shipped:

| Scenario | Active Phases | Setup | Expected Behavior | Stamp Value |
|---|---|---|---|---|
| Exhausted + surrounded | 5 + 6 | Combatant at exhaustion 0.85, surrounded by 2+ hostiles on front + left flank, no retreat path | Phase 5 (exhaustion) fires first via `_Exhaustion.exhaustion_tunnel_active()` — disengage pool presented; MS-L9 positional check never reached due to early return from `try_pick` | `MENTAL_STACK_LAYER_EXHAUSTION` |
| Post-strike + surrounded + wounded | 3 + 6 | Combatant lands a wound strike on target (stamp set); also surrounded by hostiles on front + right flank; no retreat path available | Phase 3 (MS-L8 post-strike) fires first — press the struck target via `_filter_post_strike_actions`; MS-L9 positional check never reached. Stamp: `MENTAL_STACK_LAYER_POST_STRIKE` | `MENTAL_STACK_LAYER_POST_STRIKE` |
| Rout + medical peril | 1 + 7 | Ally in immediate peril; combatant also has cohesion pressure (low blood volume) | Phase 1 (rout) checks `rout_layer_blocked()` which returns true due to medical peril gate; L0/L1 medical layers fire instead. Phase 7 escalation affects picker weights within medical layer but does not change routing decision. Stamp: `MENTAL_STACK_LAYER_MEDICAL` or `MENTAL_STACK_LAYER_SELF_MEDICAL` | Layer-specific medical stamp |
| Winded + surrounded + no post-strike | 5 + 6 | Combatant at exhaustion 0.60 (winded), surrounded by hostiles on front + left flank, retreat blocked, no recent strike | Phase 5 "winded" soft layer presents disengage pool — `pick_weighted` may select offense (~0.675 weight) or disengage. If offense selected, stamp is still `MENTAL_STACK_LAYER_EXHAUSTION`. MS-L9 positional check never reached (early return). | `MENTAL_STACK_LAYER_EXHAUSTION` |
| Feint vs high-readiness + exhausted | 2 + 5 | Attacker has feints available; defender at exhaustion 0.80, readiness >0.75, STATE_WAITING | Phase 2 blocks feints at picker level (weight = 0.0) regardless of defender's exhaustion. Exhaustion tunnel fires independently on defender's turn — disengage pool presented. Orthogonal: feint rejection affects attacker's attack weights; exhaustion affects defender's layer selection. | `MENTAL_STACK_LAYER_EXHAUSTION` (defender) |
| Medical escalation + rout | 7 + 1 | Combatant has failed bandage on chest wound; pack and TK also available; rout layer blocked by medical peril gate | Rout doesn't trigger (medical peril gate). L1 medical layer fires. Phase 7 escalation: pack gets 1.5x boost over bandage retry (retry bonus suppressed). Stamp: `MENTAL_STACK_LAYER_MEDICAL` | `MENTAL_STACK_LAYER_MEDICAL` |
| Full stack: post-strike + surrounded + exhausted + medical | 3 + 5 + 6 + 7 | Combatant lands wound strike; also surrounded; exhaustion 0.80; ally needs pack (failed bandage previously) | MS-L8 post-strike fires first (press struck target). If no valid strikes in filter pool, MS-L9 positional check fires but returns empty (rout_layer_blocked by medical peril). L5 exhaustion would fire but medical peril takes priority → L1 medical layer fires with escalation boost on pack. Stamp: `MENTAL_STACK_LAYER_MEDICAL` | `MENTAL_STACK_LAYER_MEDICAL` |
| Post-strike vs dead target | 3 | Combatant lands killing blow; stamp set; next turn the struck target is dead | MS-L8 post-strike filter returns empty (target dead, no valid strikes). Stamp erased at top of `try_pick`. Combatant returns to weighted pool. No stamp value (empty return). | None (empty) |
| Post-strike stamp expires naturally | 3 | Combatant lands strike on turn N; stamp set with combat_clock=10.0; next cognition cycle at combat_clock=12.5 | Stamp check `absf(10.0 - 12.5) = 2.5 > 2.0` — stamp expired, no post-strike momentum. Combatant returns to normal weighted pool. Stamp erased harmlessly (value remains in dict but is ignored). | None (expired) |
| Feint resistance + post-strike | 2 + 3 | Attacker with feints lands a real strike (not feint); stamp set; next turn defender has high readiness | Phase 2 blocks feints on attacker's attack weight computation. Phase 3 sets stamp from the real strike. On attacker's next turn, MS-L8 fires — press the struck target. These are orthogonal: Phase 2 affects attacker's attack weights, Phase 3 affects attacker's layer selection. | `MENTAL_STACK_LAYER_POST_STRIKE` (attacker) |
| Positional awareness vs rout priority | 6 + 1 | Combatant surrounded by 2+ hostiles; also has cohesion pressure (blood volume low) | MS-L6 rout fires first (cohesion pressure gate). If `rout_cognition_pressure()` is true, rout picks flee/fall_back. MS-L9 positional check never reached. If rout is blocked (medical peril), MS-L9 fires and returns disengage pool when surrounded + wounded. | `MENTAL_STACK_LAYER_ROUT` or `MENTAL_STACK_LAYER_POSITIONAL_DIS` |
| Medical escalation — no escalation path exists | 7 | Combatant with failed bandage on chest; NO pack item in inventory, NO TK item | `_escalation_path_has_next_step` returns false (no next step available). Retry bonus applies normally (2.8x). The AI retries bandage because escalation is impossible. This validates the fallback behavior. | N/A (weight-only) |
| Medical escalation — success clears path | 7 | Combatant with failed bandage on chest; escalates to pack which succeeds | Existing `failed_medical_parts` removal on success clears the part. Subsequent actions on that part return to normal weights — no escalation bonus, no suppressed retry. Validates the "success resets" behavior. | N/A (weight-only) |

**Integration test harness:** Add `_run_mental_stack_integration_*` tests in a dedicated tail file or appended to `AttentionFootworkTail` that activate multiple FEATURE flags simultaneously and verify expected layer precedence via the stamped `MENTAL_STACK_LAYER_*` key on the combatant dict.

---

## Harness Naming Convention

All new harness tests MUST use the `_run_mental_stack_*` prefix to match existing patterns. Do not create ad-hoc naming conventions:

| Phase | Correct Harness Prefix |
|-------|----------------------|
| 2 (Feint resistance) | `_run_mental_stack_feint_resistance_*` |
| 3 (Post-strike momentum) | `_run_mental_stack_post_strike_*` |
| 5 (Exhaustion gradient) | `_run_mental_stack_exhaustion_gradient_*` |
| 6 (Positional awareness) | `_run_mental_stack_positional_awareness_*` |
| 7 (Medical escalation) | `_run_mental_stack_medical_escalation_*` |
| Integration | `_run_mental_stack_integration_*` |

This matches the existing convention: `_run_mental_stack_hold_line_*`, `_run_mental_stack_rout_*`, `_run_mental_stack_formation_plug_*`, etc.

**D001 track naming:** Use `ii_<phase_keyword>_*` prefix, matching existing patterns like `ii_rout_cohesion`, `ii_formation_plug`, `ii_envelop_mopup`.

---

## Validation Criteria (All Phases)

Every phase MUST pass:
1. `./scripts/run_all_combat_checks.ps1` - **PHASE0: PASS** + **ii_envelop_mopup: PASS**
2. No harness test regressions (check `.f5_soak_in.txt` outputs)
3. `CAMPAIGN_SHIP_AUDIT: PASS (headless)` unchanged
4. No changes to closed rows (S9c Expand registry, bleed retune, BMI, etc.)

---

## Non-Goals

- Player UI changes (these are AI behavior-only improvements)
- New constants beyond what's needed for thresholds
- Changes to campaign-side medical logic (combat medical only)
- Heroic/stamina-based "fight through" mechanics (swordmaster teaches gradual retreat, not last-stand heroics)
- Phase 7 does NOT change which medical actions are listed - it only affects picker weights. Listing logic is unchanged.

---

## Integration with Planning System

These phases map to the Expand registry in [`SHIP_PLAN.md S9c`](SHIP_PLAN.md#combat-expand-registry). Each phase should be implemented as a separate PR with:
- One `FEATURE_*` flag (where applicable)
- Harness rows in `CombatRegressionHarness*Tail.gd` (using `_run_mental_stack_*` prefix)
- D001 soak track entries in `CombatD001TrackSpecs.gd`
- A line in [`LIVE_PATHS.md`](LIVE_PATHS.md) under the mental stack Expand backlog section
- A decision-log entry in [`SHIP_PLAN.md`](SHIP_PLAN.md) when shipped
- **MentalStackConfig.gd update:** each new phase requires adding a `LAYER_*` constant, updating the `is_layer_active()` match arm, and adding a feature flag accessor (e.g., `is_feint_resistance_enabled()`)

**Agent prompt reference:** [`scripts/cursor/agent_combat.md`](../scripts/cursor/agent_combat.md) - Round 2 priorities include harness row fixes and mental stack regression testing. These phases extend that work.

---

## Complete Layer Ordering (All Phases Shipped)

When all phases are implemented, the full `try_pick` order is:

| Order | Layer ID | Source | Description |
|-------|---------|--------|-------------|
| Pre | `POST_STRIKE_TICK_CLEAR` | - | Erase `COMBATANT_KEY_LAST_STRIKE_TICK` at top of `try_pick` (Phase 3 infrastructure) |
| Pre | `MobilityRetreat.cannot_commit_melee` | `_MobilityRetreat` | Hard gate - retreat-only actions; not a decision layer |
| 1st | `SELF_MEDICAL` | L0 | Immediate peril self-aid |
| 2nd | `MEDICAL` | L1 | Ally peril - coordinated medical |
| 3rd | `counter` | L2 | Counter-tempo window |
| 4th | `incoming` | L3 | Incoming wind-up targeting |
| 5th | `sparse_fight` | L4b | Fight-finish tails - offense over wait/focus |
| 6th | `hold_line` | L4 | Reserve posture (wait, focus, attempt_close) |
| 7th | `formation_plug` | MS-L5 | Vacancy plug-forward (shipped) |
| 8th | `rout` | MS-L6 | Cohesion break - flee/fall_back (shipped) |
| **9th** | **`post_strike`** | **MS-L8** | **Press advantage after strike (Phase 3)** |
| **10th** | **`positional_dis`** | **MS-L9** | **Surrounded + wounded - disengage (Phase 6)** |
| 11th | `exhaustion` | L5/MS-L7 | Disengage tunnel — soft intercept at 0.50, hard tunnel at 0.75 (shipped, extended by Phase 5) |
| - | *(cleared)* | - | Salience-damped utility pick |

**Note on MS-WEIGHT (Phase 7):** Medical escalation is NOT a decision layer. It operates at the picker weight level within L0/L1 medical actions and does not appear in `try_pick` ordering.

**Insertion point for MS-L8 and MS-L9:** Both phases insert between MS-L6 (rout) and L5 (exhaustion). The code structure is:

```gdscript
# After MS-L6 rout block (existing L144-154):

# MS-L8: post-strike momentum (Phase 3)
if _strike_tick_active and _EntityAccess.id_int(c) == combatant_id:
    if not _Doctrine.fight_finish_tail_active(manager, c, actions, combatant_id):
        var pool = CombatPostStrike.filter_post_strike_actions(actions, combatant_id, manager, c)
        if not pool.is_empty():
            return _stamp_layer_pick(c, CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE, ...)

# MS-L9: positional awareness (Phase 6) - only when post-strike is empty
if not _FormationRout.rout_layer_blocked(manager, c, actions, combatant_id):
    var pos_pool = _positional_disengage_check(manager, combatant_id, actions, c)
    if not pos_pool.is_empty():
        return _stamp_layer_pick(c, CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS, ...)

# L5: exhaustion tunnel (existing L157-170, extended by Phase 5)
```

MS-L9 fires **only when MS-L8 filter returns empty**. This ensures a combatant who just landed a strike presses the advantage rather than disengaging due to positional pressure. The `try_pick` function uses early returns, so once any layer produces a pick, subsequent layers are not evaluated.

---

## FEATURE Flag Behavior When Phases Are Disabled

Each new phase has its own `FEATURE_*` flag. When a flag is **off** (default in harness tests), the corresponding behavior does not activate:

| Phase | Flag | Default in Harness | Default in Production | Behavior When Off |
|-------|------|--------------------|----------------------|-------------------|
| 2 (Feint resistance) | `is_feature_ms_feint_resistance_enabled()` | off | on | Picker-level weight adjustment skipped; feints use existing damp weights only. No config change needed - follows master switch. |
| 3 (Post-strike) | `is_feature_ms_post_strike_enabled()` | off | on | No stamp written in `AttackResultApplier`; `_post_strike_momentum_active` always returns false. Adds `LAYER_POST_STRIKE` to `MentalStackConfig.gd`. |
| 5 (Exhaustion gradient) | Extends `is_feature_fight_exhaustion_enabled()` | off | on | Soft intercept at 0.50 not active; hard tunnel fires at original 0.50 threshold (existing behavior). No new flag needed. |
| 6 (Positional awareness) | `is_feature_ms_positional_awareness_enabled()` | off | on | `_positional_disengage_check` always returns empty array; layer never fires. Adds `LAYER_POSITIONAL_DIS` to `MentalStackConfig.gd`. |
| 7 (Medical escalation) | `is_feature_ms_medical_escalation_enabled()` | off | on | `_compute_failed_part_retry_weight` uses existing retry bonus without escalation guard; no escalation boost applied. Medical actions listed normally. |

**Important:** The master switch `is_feature_mental_stack_ai_enabled()` controls whether the entire mental stack pipeline runs. If it is off, all layers (including new phases) are bypassed because `try_pick` returns empty at the top when the feature is disabled. Individual phase flags are only evaluated when the master switch is on.

**Harness testing strategy:** Each phase's harness tests should set its FEATURE flag to true within the test setup and verify the expected behavior. Tests for other phases should leave their flags at default (off) to ensure no cross-phase interference. The integration tests section above covers scenarios where multiple flags are active simultaneously.

---

## Implementation Pitfalls (from Shipped Phases)

### Stamp Design (Phase 3 Critical)
Use a **clock-based stamp** (`COMBATANT_KEY_LAST_STRIKE_TICK := "last_strike_tick"` storing `float` — the `manager.combat_clock` value), NOT a boolean and NOT an integer tick counter. The stamp naturally expires after ~1 turn because the stored clock value diverges from `manager.combat_clock` by more than 2.0 seconds (`absf(stamp - current_clock) < 2.0`). No explicit erase needed — stale values are harmless. This eliminates the read-and-erase pitfall entirely.

**CRITICAL:** Do NOT use `_TacticalCombat.current_tick()` — this method does not exist. Use `manager.combat_clock` directly (it is a `float` on the CombatManager node). The 2-second tolerance window accounts for float precision and ensures the stamp fires exactly once per strike exchange.

### Stamp Read-and-Erase (General Pattern)
When you DO need to read-and-erase a stamp (not applicable to Phase 3's tick-based design), GDScript's `Dictionary.erase(key)` returns `null`, NOT the erased value. The correct pattern:
```gdscript
# WRONG - always returns null:
var val = c.erase(COMBATANT_KEY_LAST_STRIKE_TICK)

# CORRECT - read then erase:
var val = c.get(COMBATANT_KEY_LAST_STRIKE_TICK, null)
c.erase(COMBATANT_KEY_LAST_STRIKE_TICK)
```

### Filter Functions Must Not Pick (Phases 3, 5, 6)
Filter functions (`_filter_*`) return Arrays of action dicts. They must NOT call `pick_weighted()` - that is the decider's responsibility. The pattern is always:
```gdscript
var pool = _filter_something(actions, ...)
if not pool.is_empty():
    return _stamp_layer_pick(c, LAYER_X, _AIPicker.pick_weighted(pool, ...))
```

### Exhaustion Threshold Constants Must Not Be Repurposed (Phase 5)
`MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` at 0.50 is used by harness tests (`p4a_ms_l7_exhaustion_threshold_parity`) and by `exhaustion_tunnel_active()`. Adding a new higher constant for the "exhausted" hard tunnel is the correct approach - never change an existing constant's semantics.

### Medical Weighting Extraction Already Done (Phase 7)
`_compute_failed_part_retry_weight` was already extracted from `CombatAIActionPicker` into `CombatMedicalWeighting.gd`. Phase 7 must work with the current signature and add the `performer_id` parameter rather than duplicating logic back in the picker.

### FEATURE Flag Load Override Pattern (All Phases)
Use the `is_feature_*_load` pattern from `CombatConstants.gd`:
```gdscript
static var _feature_ms_xxx_load: int = -1
static func is_feature_ms_xxx_enabled() -> bool:
    if _feature_ms_xxx_load >= 0:
        return _feature_ms_xxx_load != 0
    return FEATURE_MS_XXX  # compile-time default
```
This allows harness tests to override the flag via `set_feature_ms_xxx_load(enabled)`.

### Phase 2: Feint Resistance Must Check Off-Balance (Not Just Readiness)
`PassiveParryContext.get_passive_parry_readiness()` can return high values for a RECOVERING combatant that is still off-balance. The feint resistance check must include `_PassiveParry.is_off_balance(defender)` as an additional guard — high readiness alone is not sufficient to reject feints if the defender is physically unbalanced.

### Phase 6: Cross-Formation Direction Heuristic Is Approximate
The simplified formation ID string comparison (`other_fid < my_fid` → left flank) is intentionally conservative. In complex multi-formation encounters, this may over-count flank pressure, causing false-positive surrounded detection. A combatant who disengages unnecessarily when not truly surrounded is safer than one who fights to the death when they should flee. For precise direction, implement full formation layout tracking via `manager.formations`.

### Phase 3: Stamp Uses Combat Clock, NOT Integer Ticks
`_TacticalCombat.current_tick()` does not exist. The stamp must use `manager.combat_clock` (a `float`) with a 2-second tolerance window (`absf(stamp - current_clock) < 2.0`). Writing an integer or boolean to the stamp key will cause the comparison to fail. The stamp value type must match — store `float`, read as `float`.

### Phase 7: Default Parameter Preserves Backward Compatibility
The `performer_id: int = -1` default parameter on `_compute_failed_part_retry_weight` ensures existing call sites (if any outside `compute_weight()`) remain compatible. Always use default parameters when extending function signatures in GDScript to avoid breaking callers that don't need the new parameter.

### Exhaustion Offense Weight Mult Changes Break Harness Assertions
At exhaustion 0.50, the current code returns 0.35 (hard floor) for offense weight mult. After Phase 5's extended lerp, it returns ~0.675 (midpoint of the 0.25-0.75 range). Harness tests that assert specific weight values at exhaustion 0.50-0.74 will need updating. The `p4a_ms_l7_exhaustion_threshold_parity` test validates that the 0.50 constant is unchanged — it does NOT validate weight values, so it should pass without modification.

---

## Implementation Checklist Template

Use this checklist for each phase before creating a PR. Adapt items as needed — not every item applies to every phase.

### Pre-Implementation
- [ ] Read order followed: consult AGENTS.md canonical module read order when touching unfamiliar code
- [ ] Owner file confirmed in [PLANNING.md#file-ownership](PLANNING.md#file-ownership)
- [ ] Smallest existing module extended (no new files unless complexity warrants it, per Phase 4 lesson)
- [ ] New cross-cutting API gets a row in AGENTS.md canonical APIs table
- [ ] FEATURE_* flag defined with load-override pattern in `CombatConstants.gd`
- [ ] Layer constant added to `MentalStackConfig.gd` const block (if applicable — MS-WEIGHT does NOT need one)

### During Implementation
- [ ] No inline filter logic in `MentalStackDecider` — extract to specialist module (Phase 4 lesson)
- [ ] GDScript dict erase: use `c.get(key, null)` then `c.erase(key)` — NEVER `var x = c.erase(key)` (Phase 3 pitfall)
- [ ] New layers check `*_layer_blocked()` to avoid conflicts with existing layers (Phase 4 lesson)
- [ ] FEATURE_* flags default off in harness, on in production
- [ ] Harness tests use `_run_mental_stack_*` prefix
- [ ] D001 entries use `ii_*` prefix
- [ ] Log via `CombatDebug.combat_session` or `flow_log` — never bare `print()`

### Post-Implementation Verification
- [ ] `./scripts/run_all_combat_checks.ps1` → **PHASE0: PASS** + **ii_envelop_mopup: PASS**
- [ ] No harness test regressions (check `.f5_soak_in.txt` outputs)
- [ ] `CAMPAIGN_SHIP_AUDIT: PASS (headless)` unchanged
- [ ] No changes to closed rows (S9c Expand registry, bleed retune, BMI, etc.)
- [ ] LIVE_PATHS.md updated with new layer entry in mental stack section
- [ ] Decision-log entry in SHIP_PLAN.md

### Phase-Specific Checks

| Phase | Additional Checklist Items |
|-------|---------------------------|
| **2 (Feint)** | Verify `PassiveParryContext.get_passive_parry_readiness` threshold matches >0.75; weapon form mod superseded by hard block |
| **3 (Post-strike)** | Stamp fires exactly once per exchange; stamp write in ALL three `attack_hit` paths (lines 427, 451, 466 of AttackResultApplier); counter-tempo riposte chains unaffected |
| **5 (Exhaustion)** | `MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD` unchanged at 0.50; `p4a_ms_l7_exhaustion_threshold_parity` still passes; offense weight mult lerp extends to 0.75 |
| **6 (Positional)** | Same-formation zone detection uses `zone_for_cell`; cross-formation heuristic is conservative (false positives > false negatives); healthy combatants completely unaffected |
| **7 (Medical)** | TCCC order strict (no skipping steps); budget constraints honored via `medical_action_allowed()`; retry bonus suppressed when escalation available; success clears `failed_medical_parts` and resets escalation |
