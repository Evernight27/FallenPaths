# Duel System Implementation Plan

**Date:** 2026-07-07
**Scope:** Realistic 1v1 duel mechanics — bind, distance management, blade contact, tempo, footwork.
**Based on:** Deep-dive audit of `CombatEngagementResolver`, `CombatFlurryBind`, `CombatDistanceBands`, `MentalStackDecider` (MS-L8), `CombatAIActionPicker`, `AttackResultApplier`, and R-Series audit report.

---

## Current System Inventory

| Mechanic | File | Lines | Status |
|----------|------|-------|--------|
| Engagement mode classifier | `CombatEngagementMode.gd` | full | 3 modes: Formation, Skirmish, Duel (1v1) |
| Distance bands | `CombatDistanceBands.gd` | full | Discrete: CLOSE, MID, LONG (+ FAR) |
| Bind contest (manual D6) | `CombatEngagementResolver.gd` | 510-641 | Skill+STR push, lane offset shift, binary outcome |
| Parry-to-bind (passive) | `AttackResultApplier.gd` | 521-531, 601-619 | Binary: parry_control >= 0.65 = bind |
| Flurry bind exchange | `CombatFlurryBind.gd` | full | Post-bind faster exchanges (1.5s, 3 exchanges) |
| Disengage (D2) | `CombatEngagementResolver.gd` | 195-270 | Uncontested: pushes pair to LONG |
| Lateral Step (D3) | `CombatEngagementResolver.gd` | 272-349 | Shifts lane_offset by +/- 0.25, no combat effect |
| Advance (D4) | `CombatEngagementResolver.gd` | 351-426 | Uncontested: LONG -> MID |
| Bait/Open Line (D5) | `CombatEngagementResolver.gd` | 428-508 | Sets bait_open_line + bait_active_until, payoff wired in DefenseChoiceResolver:179 and CounterTempo:211 |
| Attempt Close | `CombatEngagementResolver.gd` | 40-133 | Contested pressure/evasion contest |
| Duel AI cognition (MS-L8) | `MentalStackDecider.gd` | 601-738 | Context-aware: reach, skill, lane, breath |

---

## Corrected Findings from R-Series Audit

The R-Series audit identified several issues. After verification:

| ID | Status | Notes |
|----|--------|-------|
| R1/R7 (bind missing turn_resolved) | **CONFIRMED BUG** | `_commit_bind_resolve` at `CombatResolveAction.gd:458-461` does NOT emit `turn_resolved`. All other D-series wrappers do. |
| R5 (target no turn_resolved in bind) | **PARTIAL** | Both attacker and target get `schedule_action_ready`, but only attacker gets `turn_resolved`. Target's state machine may desync. |
| R4 (duel AI bind cooldown) | **CONFIRMED BUG** | `MentalStackDecider.gd:696` recommends bind without checking `bind_cooldown_until`. |
| R6 (bait no breath cost) | **INCORRECT** | Bait does have `BREATH_BAIT_COST = 3.0` (`CombatEngagementResolver.gd:492`). |
| C3 (bait payoff dead code) | **INCORRECT** | Bait IS wired: DefenseChoiceResolver:179 reduces parry readiness, CounterTempo:211 extends counter window. |

---

## Phase 1: Bug Fixes (Immediate)

### Fix F1: Bind missing `turn_resolved` signal

**File:** `combat/CombatResolveAction.gd:458-461`
**Problem:** `_commit_bind_resolve` never emits `turn_resolved` for attacker or target. This causes UI desync and turn accounting errors.
**Fix:** Add `turn_resolved` emission for both participants.

```gdscript
## Bind/blade-work: skill+str contest at CLOSE, winner pushes loser's lane_offset.
static func _commit_bind_resolve(manager: Node, attacker_id: int, target_id: int) -> bool:
    manager._resolve_bind(attacker_id, target_id)
    manager.emit_signal("turn_resolved", attacker_id)
    manager.emit_signal("turn_resolved", target_id)  # Target also participated (spends breath, gets cooldown)
    return true
```

### Fix F2: Duel AI bind cooldown check

**File:** `combat/MentalStackDecider.gd:696-697`
**Problem:** `_analyze_duel_context` recommends bind when `MOVE_ID_BIND` is in the action list, but doesn't verify the attacker's `bind_cooldown_until`. The listing layer filters it, but the cognition layer receives the full menu.
**Fix:** Add cooldown check before recommending bind.

```gdscript
elif band == CombatConstants.DISTANCE_CLOSE:
    var bind_cd: float = float(c.get("bind_cooldown_until", -1.0))
    if c_skill > h_skill * 1.25 and CombatConstants.MOVE_ID_BIND in move_ids:
        if not _EntityAccess.timestamp_cooldown_active(manager, bind_cd, -1.0):
            return {"preferred_move": CombatConstants.MOVE_ID_BIND}
```

---

## Phase 2: Bind Pressure Decay (Quick Win A4)

**New file:** `combat/CombatBindPressure.gd`
**Extends:** `CombatFlurryBind.gd` behavior

**Concept:** After a bind (manual or parry-to-bind), the winner has a `bind_pressure_value` (0.0-1.0 float) that decays over time. Higher pressure gives advantages in subsequent exchanges. If not maintained via another bind action, pressure drops and the opponent can "wiggle free."

**Implementation details:**
- New combatant keys: `bind_pressure_value` (float 0..1), `bind_pressure_until` (timestamp), `bind_pressure_target_id` (int)
- On successful manual bind: winner gets `bind_pressure_value = clampf(atk_power / (atk_power + tgt_power), 0.3, 0.9)`
- On parry-to-bind (AttackResultApplier): `bind_pressure_value = clampf((parry_control - 0.65) / (1.0 - 0.65), 0.2, 0.8)`
- Decay: In `CombatStateHandlers.process_waiting`, if `bind_pressure_until` not expired, reduce `bind_pressure_value` by `BIND_PRESSURE_DECAY_RATE * delta` (default: 0.3/s)
- When pressure drops below `BIND_PRESSURE_MIN_THRESHOLD` (0.15), clear the bind state
- Pressure affects: parry capacity mult, bind contest power, flurry exchange quality

**Files to modify:**
- NEW: `combat/CombatBindPressure.gd` — core module
- `combat/CombatEngagementResolver.gd:602-634` — set pressure on manual bind winner
- `combat/AttackResultApplier.gd:527-529` — set pressure on parry-to-bind
- `combat/CombatStateHandlers.gd:271-286` — decay tick in process_waiting
- `combat/CombatConstantsCloseSlots.gd` — new constants
- `combat/CombatConstants.gd` — re-exports
- `combat/DefenseChoiceResolver.gd` — pressure affects parry capacity

---

## Phase 3: Continuous Bind State Spectrum (Foundation A1)

**Extends:** Phase 2 bind pressure into a full multi-state system.

**States:**
| State | Key | Meaning | Available Actions |
|-------|-----|---------|-------------------|
| `bind_none` | — | No blade contact | Normal menu |
| `bind_light` | pressure 0.15-0.35 | Glancing contact, can slip free | Normal + void, press |
| `bind_medium` | pressure 0.35-0.65 | Contested control | Press, wind/vind, void, disengage-bind |
| `bind_hard` | pressure 0.65-1.0 | Dominant control | All above + thrust-after-bind, bind-riposte |

**New actions (listed only when in bind state):**
- **`bind_press`** — Maintain/increase pressure. Low breath cost (2), contested. On success: increase pressure by 0.15.
- **`bind_void`** — Slip offline to create opening. Medium breath cost (4). On success: clear bind, gain angular advantage (lane shift + parry bonus vs next attack).
- **`bind_wind`** — Rotate to take inside/outside of opponent's blade. High breath cost (6). Contested rotation contest.

**New combatant keys:**
- `bind_state` (String: "none", "light", "medium", "hard")
- `bind_control_side` (String: "inside", "outside", "centre", or empty)
- `bind_partner_id` (int)

**Derivation from pressure:**
```gdscript
static func state_from_pressure(pressure: float) -> String:
    if pressure < 0.15: return "none"
    if pressure < 0.35: return "light"
    if pressure < 0.65: return "medium"
    return "hard"
```

**Files to modify:**
- `combat/CombatBindPressure.gd` — add state derivation, control side tracking
- NEW: `combat/CombatBindActionListing.gd` — bind-specific action menu items
- `combat/AvailableActionsBuilder.gd` — inject bind actions when in bind state
- `combat/CombatEngagementResolver.gd` — resolve_bind_press, resolve_bind_void, resolve_bind_wind
- `combat/CombatResolveAction.gd` — wrapper functions for new resolve paths
- `combat/CombatAIActionPicker.gd` — AI weights for bind actions
- `combat/MentalStackDecider.gd` — "blade reading" cognition layer (E1)

---

## Phase 4: Footwork-Blade Coordination Penalty (Quick Win D2)

**Concept:** When a fighter performs a footwork action (lateral step, disengage, advance), their defensive readiness drops for the duration of the movement. Mismatched footwork and blade posture is dangerous.

**Implementation:**
- New combatant key: `footwork_exposed_until` (timestamp)
- On lateral_step/disengage/advance resolve: set `footwork_exposed_until = now + FOOTWORK_EXPOSED_DURATION_S` (0.3s)
- In `DefenseChoiceResolver.choose_defense`: if `footwork_exposed_until` not expired, apply parry/dodge penalty mult
- New constant: `FOOTWORK_EXPOSED_PARRY_MULT = 0.7`, `FOOTWORK_EXPOSED_DODGE_MULT = 0.8`

**Files to modify:**
- `combat/CombatEngagementResolver.gd` — set key in resolve_lateral_step, resolve_disengage, resolve_advance
- `combat/DefenseChoiceResolver.gd` — read key and apply penalty mults
- `combat/CombatConstantsCloseSlots.gd` — new constants
- `combat/CombatStateHandlers.gd` — cleanup expired stamp

---

## Phase 5: Contested Disengage (Foundation B2)

**Concept:** Currently disengage is uncontested. In HEMA, retreating under pressure requires dealing with the opponent's blade — they can follow or cut off your retreat line.

**Implementation:**
- Modify `resolve_disengage` to include a simple contest when opponent is at CLOSE range
- Opponent gets evasion-like roll: if they succeed, disengage fails and attacker gets pushed further back (larger lane offset)
- At MID range, disengage remains uncontested (already out of immediate reach)

**Files to modify:**
- `combat/CombatEngagementResolver.gd:195-270` — add contest at CLOSE only

---

## Phase 6: Contextual Disengage AI (Quick Win E4)

**Concept:** AI should disengage more when multiple threats exist at different distances, not just when outmatched in 1v1.

**Implementation:**
- In `CombatAIActionPicker._get_action_weight` for `MOVE_ID_DISENGAGE`: count hostile fighters at MID/CLOSE range vs this combatant
- Weight increases with number of nearby threats: `w_dis *= (1.0 + 0.3 * extra_threats)`

**Files to modify:**
- `combat/CombatAIActionPicker.gd:392-407` — add multi-threat context to disengage weight

---

## Phase 7: Lateral Step Angular Advantage (B3)

**Concept:** Lateral step should create angular advantage, not just shift position. Stepping outside closes the opponent's strong-side lines and opens your own.

**Implementation:**
- After lateral_step resolve, set `angular_advantage_until = now + ANGULAR_ADVANTAGE_DURATION_S` (1 turn)
- Track which direction was stepped: `angular_advantage_side` ("left" or "right")
- In `DefenseChoiceResolver`: if angular advantage active and attack comes from disadvantaged side, parry capacity mult increase
- In `CombatAIActionPicker`: lateral step weight increases when lane offset is far from opponent

**Files to modify:**
- `combat/CombatEngagementResolver.gd:272-349` — set angular advantage keys
- `combat/DefenseChoiceResolver.gd` — read and apply angular advantage
- `combat/CombatConstantsCloseSlots.gd` — new constants

---

## Phase 8: Measure Testing / Feint-Advance (Quick Win B4)

**Concept:** Allow combining advance with a probing feint to test opponent's reaction at half-measure.

**Implementation:**
- New move ID: `MOVE_ID_FLECHTE` (German: weaving/stepping forward while threatening)
- At LONG range, fighter advances to MID while making a non-committal threat gesture
- If opponent reacts with attack, flechte-setter gets parry bonus (they anticipated the response)
- Lower breath cost than full advance + feint separately

**Files to modify:**
- `combat/CombatConstantsCloseSlots.gd` — new move ID and constants
- `combat/CombatFormationMoveListing.gd` — list at LONG range
- `combat/CombatEngagementResolver.gd` — resolve_flechte
- `combat/CombatResolveAction.gd` — wrapper
- `combat/CombatAIActionPicker.gd` — weight for flechte

---

## Build Order Summary

| Phase | Item | Priority | Dependencies | Effort | Status |
|-------|------|----------|--------------|--------|--------|
| 1.0 | F1: Bind turn_resolved signal fix | **P0** | None | Trivial | DONE |
| 1.1 | F2: Duel AI bind cooldown check | **P0** | None | Small | DONE |
| 2.0 | A4: Bind Pressure Decay | P1 | Phase 1 | Medium | DONE |
| 3.0 | D2: Footwork-Blade Penalty | P1 | None | Small | Implemented |
| 4.0 | E4: Contextual Disengage AI | P2 | None | Small | DONE |
| 5.0 | A1: Continuous Bind State | P1 | Phase 2 | Large | DONE |
| 6.0 | B2: Contested Disengage | P2 | None | Medium | DONE |
| 7.0 | B3: Lateral Step Angular Advantage | P2 | Phase 3 | Medium | DONE |
| 8.0 | B4: Measure Testing (Flechte) | P3 | None | Medium | Pending |

---

## Not In Scope (Future)

- **B1: Continuous Distance** — Requires refactoring all band-checking code across the codebase. High risk, high reward. Defer until duel system is stable.
- **C1: Tempo Ownership State** — Fundamental architecture change to turn/resolution model. Requires careful design of tempo transfer rules.
- **C2: Forte/Foyle Blade Position** — Needs blade segment tracking in AttackResolver and parry geometry. Worthwhile but complex.
- **A2: Bind Action Menu** — Depends on A1 (continuous bind state). Full implementation with press/void/wind/disengage-bind.
- **C4: Afterblow/Indes Detection** — Requires simultaneous exchange timing within a resolution tick.
