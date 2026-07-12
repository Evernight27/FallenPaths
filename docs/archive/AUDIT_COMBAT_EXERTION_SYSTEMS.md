# Combat Exertion Systems Audit Report

**Date:** 2026-07-06  
**Scope:** Composure, Breath/Stamina, Exhaustion, Muscle Fatigue systems  
**Files Audited:** `combat/CombatStateHandlers.gd`, `combat/AttackWindUpStarter.gd`, `combat/CombatExhaustion.gd`, `combat/CombatMuscleFatigue.gd`, `combat/CombatAIActionPicker.gd`, `combat/MentalStackDecider.gd`, `combat/DefenseChoiceResolver.gd`, `combat/CombatConstants.gd` (L1-200), `combat/CombatantEntityAccess.gd` (L1-150), `combat/CombatManager.gd` (L1-150), `core/CoreEntity.gd` (L1-150)

---

## CRITICAL Severity

| File:Line | Gap | Impact |
|-----------|-----|--------|
| **CombatStateHandlers.gd:237** | `process_waiting` composure fill does not multiply by `_Exhaustion.composure_fill_breath_mult(c)` consistently with `process_recovering` (L274) and `process_cowering_idle` (L250). The formula reads `COMPOSURE_FILL_WAITING * _Exhaustion.composure_fill_breath_mult(c)`, but breath ratio at 0 means composure fills at only ~12.5/s instead of documented 25/s in COMPOSURE_PLAN.md Step 3A. | **Gameplay balance**: Fighters with zero breath recover composure at half the designed rate, creating an un-intended soft-lock when both breath and composure are depleted. This contradicts COMPOSURE_PLAN.md §3A specification of flat 25/s WAITING fill. |
| **AttackWindUpStarter.gd:197** | `CombatConstantsFootwork` is referenced but never preloaded/imported. Should be `_Footwork` (line 17 preload) or the full path. This will cause a runtime error on wind-up composure cost calculation for CLOSE/LONG distance bands. | **Runtime crash**: Any attack from CLOSE or LONG distance band using reach-based composure modifiers will crash with "self has no method" or similar undefined reference error. |
| **CombatStateHandlers.gd:99** | `enter_short_recovery` unconditionally zeroes `c.gauge = 0.0` on arm-loss recovery entry. This is listed as intentional per COMPOSURE_PLAN Step 2 table, but there's no guard against re-entering short recovery while already in STATE_RECOVERING with a non-zero gauge from prior composure fill. | **State corruption**: If `enter_short_recovery` fires twice on the same combatant before state transition, it will zero any accumulated composure from waiting periods unexpectedly. |

---

## HIGH Severity

| File:Line | Gap | Impact |
|-----------|-----|--------|
| **CombatMuscleFatigue.gd:168** | `apply_exertion_after_breath_spend` calls `_EntityAccess.get_entity_from_manager(manager, c) if manager != null else null` - the entity lookup result is passed to `seed_combatant_if_enabled(c, entity)`, but if `manager` is null (called from `apply_formation_exertion` L194), the seed will always initialize pools to 0.0 instead of reading persisted entity values. | **Data loss**: Formation exertion spent when `manager` is null won't preserve existing muscle fatigue from entity persistence, effectively resetting limb fatigue on formation moves called without manager context. |
| **CombatExhaustion.gd:128-130** | `clamp_breath_to_effective_max` writes directly to `combatant["breath"]` and `combatant["stamina"]` instead of using `_EntityAccess.breath_float()` / setter pattern. This bypasses any potential validation or fallback logic in the access layer. | **Inconsistency**: Direct dict write could desync if `CombatantEntityAccess` implements additional breath/stamina handling in the future. Minor now, but violates established access patterns. |
| **AttackWindUpStarter.gd:212** | Composure cost deduction (`atk_d.gauge = maxf(0.0, gauge_atk_pre - composure_cost)`) happens AFTER quality calculation (L190-192). This is correct per design (quality uses pre-cost gauge), but `gauge_atk_pre` is captured separately from the actual gauge read at L194. If another system modifies `atk_d.gauge` between L190 and L212, quality and cost deduction will use different base values. | **Race condition**: Quality/cost mismatch if concurrent modifications occur. Unlikely in single-threaded Godot but possible if signal handlers modify gauge mid-wind-up. |
| **CombatStateHandlers.gd:247** | `process_cowering_idle` applies breath refill at `BREATH_RECOVERING_REFILL_MULT` (0.6x per L248 comment), but does NOT apply `_Exhaustion.composure_fill_breath_mult(c)` to the composure fill rate like `process_waiting` and `process_recovering` do. Line 250 uses `COMPOSURE_FILL_RECOVERING * _Exhaustion.composure_fill_breath_mult(c)`. | **Inconsistency**: Cowering breath refill is reduced, but cowering composure fill already uses the slower RECOVERING rate AND breath mult - this creates a double-penalty not documented in COMPOSURE_PLAN.md. A cowering fighter with 0 breath fills composure at ~4/s (8 * 0.5), which may be excessively punitive. |
| **DefenseChoiceResolver.gd:192-193** | Parry readiness calculation multiplies `pr_base * br_rd * ex_rd * _Attention.focus_effective(tgt) * yomi_rd` but the result is clamped 0..1 only at the final assignment. Individual mults (`br_rd`, `ex_rd`) can stack multiplicatively to very low values before clamp, making intermediate debugging difficult. | **Debugging difficulty**: No individual component logging for readiness factors when `combat_debug_active()` is on. Hard to diagnose why parry readiness is unexpectedly low in soak tests. |
| **CombatAIActionPicker.gd:653-657** | `_composure_action_weight_mult` reads `gauge_float(c, GAUGE_MAX)` but if gauge key is missing/invalid, defaults to 100 - meaning a combatant with corrupted/missing gauge data will always pass the cost check. Should log a warning or use a more conservative default. | **Silent failure**: Corrupted combatant dict with missing gauge silently falls back to full composure weight, bypassing exhaustion-based dampening entirely. |
| **MentalStackDecider.gd:569-570** | `_positional_disengage_check` reads entity blood volume directly from node (`_EntityAccess.get_blood_volume_from_node(_node as Node)`), but casts `_node` to `Node` without null check. If `combatant["node"]` is null, this returns 0 and the combatant will always appear vulnerable. | **Null safety**: Missing null check on `_node` before cast means dead/unregistered combatants could trigger MS-L9 disengage logic incorrectly. |
| **CombatExhaustion.gd:297-316** | `_medical_exertion_gain_mult` accesses `entity._pain_shock_until_time` and `entity._pain_delay_hit_time` as private fields using direct property access (`entity._pain_shock_until_time`). These are internal implementation details of the pain/consciousness system that could change without updating this caller. | **Fragile coupling**: Direct access to private entity fields creates tight coupling. If PainConsciousness internals refactor these field names, exhaustion gain will silently break (return 1.0). |

---

## MEDIUM Severity

| File:Line | Gap | Impact |
|-----------|-----|--------|
| **CombatStateHandlers.gd:237** | `process_waiting` reads `c.get("gauge", 0.0)` but `c.gauge = minf(...)` on the same line uses direct property access. Inconsistent - should use `c.get()` consistently or document why direct access is safe here. | **Minor inconsistency**: Pattern variance that could confuse future maintainers. |
| **AttackWindUpStarter.gd:311-335** | `_resolve_composure_cost` has a hardcoded cost table inline (L326-334) instead of using `CombatConstants.COMPOSURE_COST_TABLE` or equivalent. COMPOSURE_PLAN.md §3C shows the canonical table; costs should live in constants for easy rebalancing without touching logic files. | **Maintainability**: Cost changes require code deploy instead of constant update. Current values match plan (Feint:9 vs documented 5 - discrepancy). |
| **COMPOSURE_PLAN.md L138** vs **AttackWindUpStarter.gd:327** | Feint composure cost is documented as 5 in COMPOSURE_PLAN §3C table, but implemented as 9 in `cost_table`. **Discrepancy between design doc and implementation.** | **Design drift**: Either the plan needs updating to 9, or the code should be 5. This affects AI feint weight calculations via `_composure_action_weight_mult`. |
| **COMPOSURE_PLAN.md L138** vs **AttackWindUpStarter.gd:329** | Heavy composure cost is documented as 70 in COMPOSURE_PLAN §3C table, but implemented as 55 in `cost_table`. **Discrepancy between design doc and implementation.** | **Design drift**: Heavy attacks are cheaper than designed, affecting combat pacing and risk/reward balance. |
| **CombatMuscleFatigue.gd:186-194** | `apply_formation_exertion` uses hardcoded breath values (8.0, 10.0, 12.0) instead of constants. These should be `MUSCLE_FATIGUE_FORMATION_PROXY_BREATH_*` constants in CombatConstants for tuning visibility. | **Maintainability**: Hidden tuning parameters that affect formation fatigue accumulation rate. |
| **CombatExhaustion.gd:80** | `effective_stamina_max` reads `combatant.get("campaign_breath_mult", combatant.get("campaign_stamina_mult", 1.0))` but doesn't validate the combatant dict is non-empty first (unlike `blood_stamina_cap_mult` at L59). If called with empty dict, will return default 1.0 mult silently. | **Null safety**: Missing early return for empty combatant, unlike sister function `blood_stamina_cap_mult`. |
| **CombatAIActionPicker.gd:674-838** | `_compute_attack_weight_components` is ~165 lines of sequential multiplication with 12+ multiplier variables. No intermediate validation that any single mult hasn't gone negative or NaN. A bug in one module's return value silently corrupts the entire weight calculation. | **Error propagation**: Single bad float (NaN/Inf/negative) from any submodule silently produces garbage action weights, making AI behavior unpredictable. |
| **CombatExhaustion.gd:184-189** | `process_waiting_recovery` applies `blood_stamina_cap_mult(combatant)` to exhaustion recovery rate, but `process_recovering_recovery` (L206-218) does NOT apply blood cap mult. Inconsistent - a severely wounded fighter recovers fight-exhaustion at different blood-capped rates depending on state. | **Design inconsistency**: Blood loss affects WAITING recovery but not RECOVERING recovery for exhaustion. May be intentional but undocumented in COMPOSURE_PLAN or MUSCLE_FATIGUE_PLAN. |
| **CombatStateHandlers.gd:193-220** | `process_receiving_medical` sets `c.gauge = 50.0` every tick (L195). This means a patient receiving care has their composure clamped to exactly 50 regardless of prior value, preventing them from building composure above 50 during treatment. May be intentional but undocumented. | **Potential game feel issue**: Patient can never exceed 50 composure while receiving care. If treatment takes 3+ seconds, they'll be locked at 50 even though COMPOSURE_FILL_WAITING would normally fill to ~75 in that time. |
| **DefenseChoiceResolver.gd:480-486** | When defender dodges (not parrying), `_Footwork.clear_on_exchange_end(tgt)` is called, followed by `apply_defender_step_on_dodge`. However, the else branch (L485-486, no weapon) also calls `clear_on_exchange_end` with no follow-up step. The sequence `clear → apply_dodge_step` could be interrupted if `apply_defender_step_on_dodge` internally reads cleared state. | **Ordering risk**: Footwork clear before dodge step application could cause transient state issues in CombatFootwork's internal tracking. |
| **CombatAIActionPicker.gd:746-752** | Feint listing stamina gate (`breath_ratio < AI_FEINT_LISTING_STAMINA_GATE`) applies dampening multiplicatively after all other feint factors. This means a low-breath feint could still have very high weight if the defender is off-balance (`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`), making breath fatigue ineffective at discouraging bad feints. | **Balance issue**: Breath exhaustion doesn't reliably prevent AI from feinting when other conditions favor it. |
| **CombatMuscleFatigue.gd:228-260** | `offense_weight_mult`, `wait_recovery_weight_mult`, and `formation_movement_weight_mult` all independently read limb fatigue values. If muscle fatigue pools change between calls (e.g., mid-frame exertion apply), these three functions could see inconsistent fatigue snapshots for the same combatant. | **Temporal consistency**: Weight calculations across different action types may reflect stale/different fatigue state if called at different times in the same tick. |

---

## LOW Severity

| File:Line | Gap | Impact |
|-----------|-----|--------|
| **CombatExhaustion.gd:171** | `apply_attacker_wind_up_exfastion_mult` uses `perf >= 0.999` as the "no penalty" threshold. This means performance at 0.998 still triggers division, adding negligible but non-zero wind-up time for nearly-fresh combatants. Threshold should be documented. | **Micro-inaccuracy**: Combatants at 99.9% performance get fractional wind-up increase. Negligible in practice (~0.1% slower). |
| **CombatMuscleFatigue.gd:118** | `apply_attacker_wind_up_mult` uses `perf >= 0.999` threshold (same pattern as exhaustion). Same micro-inaccuracy concern. | **Micro-inaccuracy**: Consistent with exhaustion but worth noting for completeness. |
| **CombatStateHandlers.gd:234-235** | `_cleanup_expired_bait_stamps` is called from `process_waiting`, `process_cowering_idle`, and `process_recovering`, but not from `process_wind_up` or `process_medical_wind_up`. Bait stamps expire during wind-up states, potentially leaving stale data if the attacker was baiting. | **Minor cleanup gap**: Stale bait data persists through wind-up states until next WAITING/RECOVERING tick. Low impact since wind-up is short duration. |
| **CombatAIActionPicker.gd:90-102** | `pick_weighted` computes action weights twice per action (once for total, once for selection). For large action pools (15+ actions with complex targeting), this doubles the weight computation cost including all the targeting/scoring calls. | **Performance**: O(2n) weight calculations instead of O(n) with cached weights. Noticeable only in large encounters with many actions per combatant. |
| **DefenseChoiceResolver.gd:96-97** | Dodge eval part assignment uses `BodyPartConstants.get_weighted_random_part(targetable)` but the result isn't used until `_apply_feint_telegraph_bias_to_dodge_eval_part` runs immediately after. The initial random selection is thrown away if feint bias applies. | **Minor waste**: Unnecessary RNG call in non-feint path. Could defer random selection until after feint check. |
| **CombatExhaustion.gd:261-267** | `exhaustion_fp_combat_band_index` uses `ex + 0.0001 >= _FP_COMBAT_BANDS[i]` as comparison, adding epsilon for floating point tolerance. This makes band crossing slightly earlier than the documented threshold (e.g., 24.99% exhaustion triggers 25% band). | **Precision**: Epsilon-based comparison causes premature band logging. Acceptable for FP combat tracking but worth documenting. |
| **CombatMuscleFatigue.gd:328-344** | `sync_to_entities_from_manager` only syncs player-side combatants (`SIDE_PLAYER`). If an AI-controlled companion on the player side dies mid-fight, their muscle fatigue won't be synced. The `alive_bool` check at L337 handles this gracefully (skips dead), but it means fatigue data is lost for fallen allies. | **Data loss**: Minor - dead combatants' fatigue state isn't persisted. Matches design (camp rest clears fatigue anyway). |
| **CombatStateHandlers.gd:291-294** | `process_formation_move_timer` caps `state_timer` at `c.get("state_duration", 1.0)`. If `state_duration` is not set on the combatant dict, defaults to 1.0s - which may be too short/long depending on the formation move type. No validation that state_duration was actually set before this function is called. | **Default risk**: Missing state_duration silently uses 1.0s fallback. Should assert or log when duration is missing. |
| **AttackWindUpStarter.gd:32-33** | `_last_fp_tempo_wind_up_line` is a static dedup variable that persists across combat sessions. If `reset_fp_session_dedup()` isn't called at combat start, duplicate suppression carries over between fights. | **State leak**: Dedup state not cleared between combats could suppress legitimate log lines in consecutive fights. Verify `reset_fp_session_dedup` is called in CombatManager.start(). |
| **CombatMuscleFatigue.gd:16** | Constants `EXERTION_KIND_ATTACK`, `EXERTION_KIND_PARRY`, `EXERTION_KIND_FORMATION` are inline strings ("attack", "parry", "formation") rather than preloaded from a constants module. If string literals drift (typo), type comparison silently fails and returns default behavior. | **Type safety**: String-based enum without strong typing. A typo like "atack" would silently bypass exertion tracking. |

---

## Summary by Category

### Missing Error Handling / Null Checks
- AttackWindUpStarter.gd:197 (unresolved constant) - CRITICAL
- MentalStackDecider.gd:569 (null node cast) - HIGH  
- CombatExhaustion.gd:80 (empty combatant in effective_stamina_max) - MEDIUM

### Inconsistent State Machine Transitions
- CombatStateHandlers.gd:99 (double short recovery gauge zeroing) - CRITICAL
- CombatStateHandlers.gd:247 (cowering double-penalty) - HIGH

### Hardcoded Values / Design Doc Discrepancies
- AttackWindUpStarter.gd:311-335 (cost table inline vs. constants) - MEDIUM
- COMPOSURE_PLAN.md Feint cost 5 vs code 9 - MEDIUM
- COMPOSURE_PLAN.md Heavy cost 70 vs code 55 - MEDIUM
- CombatMuscleFatigue.gd:186-194 (hardcoded breath values) - MEDIUM

### Missing Feature Flag Guards
- All muscle fatigue functions properly guard on `enabled()` ✅
- Exhaustion functions properly guard on `is_feature_fight_exhaustion_enabled()` ✅
- No missing flag guards found in audited files.

### Race Conditions / Temporal Issues
- AttackWindUpStarter.gd:212 (gauge read/cost split) - HIGH
- CombatMuscleFatigue.gd:228-260 (fatigue snapshot inconsistency) - MEDIUM

### Error Propagation / Silent Failures
- CombatAIActionPicker.gd:653-657 (missing gauge defaults to 100) - HIGH
- CombatAIActionPicker.gd:674-838 (no NaN/Inf validation in weight chain) - MEDIUM

### Performance Concerns
- CombatAIActionPicker.gd:90-102 (O(2n) weight calculation) - LOW

---

## Recommendations (Priority Order)

1. **Fix AttackWindUpStarter.gd:197** - `CombatConstantsFootwork` reference must be resolved to `_Footwork` or proper preload before any CLOSE/LONG range attacks function correctly.
2. **Verify COMPOSURE_PLAN.md cost table** against implementation (Feint 5→9, Heavy 70→55) and update either documentation or code to match intent.
3. **Add null check in MentalStackDecider.gd:569** before casting `_node` to `Node`.
4. **Move composure cost table** to CombatConstants for visibility and tuning without logic changes.
5. **Add NaN/Inf validation** in `_compute_attack_weight_components` return path (assert weight > 0 and is_finite).
6. **Document cowering composure double-penalty** or adjust `process_cowering_idle` to match design intent.
7. **Ensure `reset_fp_session_dedup()`** is called at `CombatManager.start()`.
