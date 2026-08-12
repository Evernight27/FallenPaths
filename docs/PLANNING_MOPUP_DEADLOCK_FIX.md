# Plan: Envelop Mop-Up AI Deadlock Fix

## Problem Statement

During envelop mop-up (post-rout cleanup), an AI combatant can enter a WAIT deadlock when:
- Mop-up is active (`envelop_mop_up_active` = true)
- The combatant's hostile target is at LONG distance with stale band readings
- No melee strikes are listed (reach doesn't cover eff_dist, and mop-up only forces CLOSE/MID listing)
- `attempt_close` fails listing checks (close_block cooldown or full defender slots)
- `fight_finish_tail_active` returns false because no hostile strike is listed
- Result: combatant picks WAIT every tick with no way to progress

## Root Cause Analysis

**Choke point:** `CombatDoctrine.fight_finish_tail_active` (line 351) gates on `action_list_has_hostile_strike` BEFORE checking if mop-up is active. This prevents the `trust_menu_close` override in `_filter_hold_line_close_actions` from kicking in.

The trust_menu_close path (MentalStackDecider.gd:403-404) says: "if we're fighting a sparse tail, trust any attempt_close even if listing checks fail." But this path is blocked because the same function that gates it requires listed strikes — creating a circular dependency.

## Existing Mitigations (Partial Coverage)

| Mitigation | File:Line | What it covers | Gap |
|---|---|---|---|
| `envelop_mop_up_strike_at_band` | CombatMeleeListing:54-59 | Forces melee listing at CLOSE/MID during mop-up | Doesn't help LONG distance targets |
| `trust_menu_close` override | MentalStackDecider:403-404 | Bypasses listing for sparse tail fighters | Blocked by fight_finish_tail_active gate |
| Resolve fallback | CombatResolveAction:158 | Falls through to resolve even if listing check fails | Doesn't help with action listing phase |
| Rotate suppression with strike check | CombatDoctrine:437-438 | Allows rotate when strikes exist, suppresses otherwise | No strikes = no rotate |

## Fix Options (Ranked by Impact/Cost)

### Option A: Relax fight_finish_tail_active gate for mop-up (Recommended)

**File:** `combat/formation/CombatDoctrine.gd` — `fight_finish_tail_active`
**Change:** When `envelop_mop_up_active` is true, skip the `action_list_has_hostile_strike` requirement.

```gdscript
static func fight_finish_tail_active(manager, c, actions, combatant_id):
    if manager == null or c.is_empty() or combatant_id < 0:
        return false
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    # Mop-up fighters don't need listed strikes — mop-up status itself is sufficient trigger
    if envelop_mop_up_active(manager, fid):
        return true
    # Non-mop-up paths still require listed hostile strikes
    if not CombatListedActions.action_list_has_hostile_strike(actions, combatant_id):
        return false
    return (rank == 0 and skirmish_line_sparse) or mop_up_underdog_active(manager, c)
```

**Impact:** High — enables trust_menu_close for ALL mop-up fighters regardless of listing state.
**Risk:** Low — trust_menu_close only bypasses listing checks that are already known to be unreliable at LONG distance (band/reach lag). The resolve phase still validates via `attempt_close_listed_for_pair` and `close_attempt_pair_blocked`.

### Option B: Add explicit mop-up close listing path

**File:** `combat/ai/CombatMeleeListing.gd` — `attempt_close_listed_for_pair`
**Change:** During mop-up, add a fallback listing check for LONG distance targets when `envelop_close_allowed` is true.

```gdscript
static func attempt_close_listed_for_pair(manager, attacker, defender_id, dist):
    ...
    if dist == CombatConstants.DISTANCE_LONG:
        # NEW: During mop-up, allow close at LONG even without reach coverage
        if envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(attacker)):
            if not close_attempt_pair_blocked(manager, attacker, defender_id):
                var defender = get_combatant(defender_id)
                return defender != null and defender_has_free_close_slot(...)
```

**Impact:** Medium — fixes the listing gap directly at the source.
**Risk:** Low — preserves all existing resolve-phase validation. Only changes what gets listed, not what gets resolved.

### Option C: Both A + B (Most Robust)

Combine both approaches for defense-in-depth:
- **A** handles the decision-layer gap (MentalStackDecider can pick close even without listing)
- **B** handles the listing-layer gap (close attempts appear in action list during mop-up at LONG)

## Implementation Plan

1. **Apply Option A first** (`CombatDoctrine.gd:348-361`) — smallest change, highest impact
2. **Run F5 soak tests** to verify no regressions in non-mop-up behavior
3. **If edge cases remain**, apply Option B as a supplementary fix
4. **Add harness test** to cover the specific deadlock scenario (mop-up + LONG distance + stale band)

## Files to Modify

| File | Function | Change Type |
|---|---|---|
| `combat/formation/CombatDoctrine.gd` | `fight_finish_tail_active` | Gate relaxation for mop-up |
| (optional) `combat/ai/CombatMeleeListing.gd` | `attempt_close_listed_for_pair` | Mop-up LONG distance listing |

## Verification

1. Run existing F5 soak tests: `tools/ci/run_q_audit.sh`, `tools/ci/run_playtest.sh`
2. Verify mop-up still works with the new gate relaxation
3. Confirm non-mop-up fighters (sparse rank-0, underdog) still require hostile strikes as before
4. Test stale band reading scenario programmatically if possible
