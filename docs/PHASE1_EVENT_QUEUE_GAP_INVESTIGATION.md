# Phase 1 Event Queue — Gap Fix Options Investigation

Analysis of the three critical gaps identified in the Phase 1 event-driven migration, with option comparisons for each.

---

## Problem 1: Parry Defender Never Gets EVENT_ACTION_READY

**Context:** When `parry_deflect` or `parry_partial` occurs, the defender is set to `STATE_WAITING` (lines 121–124 and 148–150 in `AttackResultApplier.gd`). With the old gauge system, their gauge would fill and they'd eventually get `turn_ready`. With event-driven flow, no `EVENT_ACTION_READY` is scheduled, so they never act again—combat effectively freezes when parries happen.

**Affected branches:** `parry_deflect`, `parry_partial` (both set `tgt.state = STATE_WAITING`).

---

### Option A: Call `manager._schedule_event()` from AttackResultApplier

**Approach:** In both `parry_deflect` and `parry_partial` branches, after setting `tgt.state = STATE_WAITING`, call `manager._schedule_event()` to schedule `EVENT_ACTION_READY` for the defender.

**Implementation:**
```gdscript
# In parry_deflect, after tgt.state_duration = 0.0:
if manager.has_method("_schedule_event"):
    manager._schedule_event({
        "type": CombatConstants.EVENT_ACTION_READY,
        "combatant_id": target_id,
        "resolve_at": manager.combat_clock + 0.01,  # or 0, or cooldown
        "data": {}
    })
```

| Pros | Cons |
|------|------|
| Fix is local to where state changes | AttackResultApplier couples to CombatManager's event API |
| Mirrors `process_medical_wind_up_cancel` pattern | `_schedule_event` is "private"; Applier reaches into manager |
| Single place to fix for both parry outcomes | Timing choice (0, 0.01, or cooldown) needs a decision |
| No changes to CombatManager call sites | |

**Timing options:**
- `resolve_at = combat_clock` — fires on next process; can race with other events
- `resolve_at = combat_clock + 0.01` — slight delay, avoids same-frame edge cases
- `resolve_at = combat_clock + manager._action_ready_cooldown(tgt)` — defender gets full cooldown like recovery end

---

### Option B: Callback / signal from AttackResultApplier

**Approach:** Add a signal or callback on CombatManager (e.g. `defender_ready_for_riposte(combatant_id)`) that `AttackResultApplier` emits when a defender transitions to WAITING after a parry. CombatManager connects and schedules the event.

**Implementation:**
- Add `signal defender_ready_to_act(combatant_id: int)` on CombatManager
- AttackResultApplier emits `manager.emit_signal("defender_ready_to_act", target_id)` when setting parry defender to WAITING
- CombatManager connects and schedules `EVENT_ACTION_READY`

| Pros | Cons |
|------|------|
| Keeps scheduling logic in CombatManager | More wiring (signal + connection) |
| AttackResultApplier doesn't depend on event API | Applier still needs manager reference to emit |
| Easier to add extra behavior (e.g. riposte bonus) later | Slightly more indirection |

---

### Option C: Central “transition to WAITING” hook on CombatManager

**Approach:** Add `func on_combatant_entered_waiting(c: Dictionary)` on CombatManager. Any code that sets `state = STATE_WAITING` calls it. That function decides whether to schedule `EVENT_ACTION_READY` (e.g. skip when coming from medical cancel, which already schedules).

**Implementation:**
- CombatManager: `func on_combatant_entered_waiting(c: Dictionary) -> void` — if not from medical/receiving_care path, schedule `EVENT_ACTION_READY`
- AttackResultApplier, process_incapacitation, etc. call `manager.on_combatant_entered_waiting(tgt)` when setting WAITING

| Pros | Cons |
|------|------|
| Single place that controls “who gets an event when entering WAITING” | Requires auditing all WAITING transitions |
| Reduces risk of missing new transition sites | Some transitions (e.g. medical cancel) already schedule—need to avoid double-scheduling |
| Clear ownership of event-scheduling policy | |

---

### Option D: Post-apply hook from _execute_attack

**Approach:** After `_AttackResultApplier.apply_result()`, `_execute_attack` examines the result and schedules events for any defender set to WAITING.

**Implementation:**
- `_execute_attack` gets the result dict (or re-reads combatant state)
- If `result.action` is `parry_deflect` or `parry_partial`, schedule `EVENT_ACTION_READY` for `result.target_id`

| Pros | Cons |
|------|------|
| Keeps event scheduling in CombatManager | Logic spread across `_execute_attack` and result parsing |
| AttackResultApplier stays decoupled from events | Must correctly pass back defender id from apply_result |
| | Only covers parry; incapacitation is a different code path |

---

### Recommendation (Problem 1)

**Preferred: Option A** — Direct `_schedule_event` from AttackResultApplier, with `resolve_at = combat_clock + 0.02` to slightly stagger and avoid same-frame races. Matches the existing medical-wind-up-cancel pattern and keeps the fix localized.

**Alternative: Option C** if you want a single policy for all WAITING transitions.

---

## Problem 2: Incapacitation (Cowering Recovery) — Unit Never Gets EVENT_ACTION_READY

**Context:** When `process_incapacitation` detects a unit leaving cowering (arms functional again), it sets `c.state = STATE_WAITING` (line 34). No `EVENT_ACTION_READY` is scheduled; they never get another turn.

---

### Option A: Schedule event from process_incapacitation (mirror medical cancel)

**Approach:** Same pattern as `process_medical_wind_up_cancel`: after setting `c.state = STATE_WAITING`, call `manager._schedule_event()` for `EVENT_ACTION_READY`.

**Implementation:**
```gdscript
# At end of cowering-recovery block in process_incapacitation:
if manager.has_method("_schedule_event"):
    manager._schedule_event({
        "type": CombatConstants.EVENT_ACTION_READY,
        "combatant_id": c.id,
        "resolve_at": manager.combat_clock + 0.05,
        "data": {}
    })
```

| Pros | Cons |
|------|------|
| Same approach as medical cancel | Duplicates scheduling logic |
| Small, localized change | Timing (0.05) is somewhat arbitrary |
| Very clear cause and effect | |

---

### Option B: Use central on_combatant_entered_waiting

**Approach:** If you adopt Option C for Problem 1, `process_incapacitation` calls `manager.on_combatant_entered_waiting(c)` when leaving cowering. Scheduling is centralized.

| Pros | Cons |
|------|------|
| Reuses shared policy | Depends on adopting Option C for Problem 1 |
| No new scheduling patterns | |

---

### Option C: Defer to next process_waiting (not viable with event-driven)

**Approach:** Rely on `process_waiting` to eventually give them a turn.

**Verdict:** Not viable. With the event-driven fix for Problem 3, `process_waiting` will no longer drive turn_ready from gauge, so this path would never fire.

---

### Recommendation (Problem 2)

**Preferred: Option A** — Schedule from `process_incapacitation`, using the same pattern as medical cancel. If you later add `on_combatant_entered_waiting`, this can be refactored to call that.

---

## Problem 3: process_waiting Duplication — Gauge Fill and turn_ready Logic

**Context:** `process_waiting` still contains:
1. Gauge fill (`c.gauge = min(100, c.gauge + fill_rate)`)
2. Turn-ready logic (`if c.gauge >= 100`: emit `turn_ready` or run AI)

With event-driven flow, `EVENT_ACTION_READY` sets `gauge = 100` when a combatant becomes ready. Each frame, `process_waiting` sees `gauge >= 100` and emits `turn_ready` again (player) or runs the AI again (enemy), causing duplicate turn grants.

---

### Option A: Remove gauge fill and turn_ready, keep only guard + stamina

**Approach:** Strip `process_waiting` down to:
- Guard rise: `c["guard"] = min(1.0, guard + GUARD_RISE_RATE * delta)`
- Stamina refill: `c["stamina"] = min(STAMINA_MAX, stamina + STAMINA_REFILL_RATE * delta)`

Remove all gauge logic and the `if c.gauge >= 100` block (turn_ready / AI).

| Pros | Cons |
|------|------|
| Fully event-driven; no duplication | Gauge is still used elsewhere (e.g. medical, AvailableActionsBuilder) |
| Clear ownership: events handle readiness | Need to ensure all WAITING→ready paths schedule events |
| Matches Phase 1 design | |

---

### Option B: Gate turn_ready on “not already granted this frame”

**Approach:** Add `c.event_ready_emitted_this_turn = true` when `EVENT_ACTION_READY` fires. In `process_waiting`, only emit turn_ready if that flag is false. Clear the flag when the combatant acts or at end of frame.

| Pros | Cons |
|------|------|
| Keeps gauge fill (could be useful for UI/legacy) | Two systems still active; more complexity |
| Prevents duplicate emission | Gauge fill no longer affects timing; confusing |
| | Extra state to manage and clear |

---

### Option C: Run process_waiting only for non-event-driven states

**Approach:** Add a flag like `manager.use_event_queue` and skip the gauge/turn_ready block when true. Only run guard + stamina.

| Pros | Cons |
|------|------|
| Allows gradual migration | Dead code remains; flag adds branching |
| Could revert by flipping flag | Two modes to maintain |
| | Overkill if migration is permanent |

---

### Option D: Remove process_waiting entirely for WAITING combatants

**Approach:** Don’t call `process_waiting` for `STATE_WAITING`. Handle guard and stamina elsewhere (e.g. in `_process` before or after event handling, or in a shared “idle update” step).

| Pros | Cons |
|------|------|
| Forces full event-driven flow | Guard rise and stamina refill must move somewhere |
| No duplicate logic | Risk of forgetting to apply guard/stamina |
| | Structural change to the process loop |

---

### Recommendation (Problem 3)

**Preferred: Option A** — Remove gauge fill and turn_ready from `process_waiting`, keep only guard rise and stamina refill. Simple, matches the event-driven design, and gauge can remain for compatibility where it’s still needed (e.g. `c.gauge = 100` from `_handle_action_ready`).

---

## Cross-Cutting: process_wind_up and process_recovering Completion Logic

**Context:** Both handlers still contain completion logic:
- `process_wind_up`: `if c.state_timer >= c.state_duration: manager._execute_attack(c.id)`
- `process_recovering`: `if c.state_timer >= c.state_duration: complete_recovery(c)`

With events, `EVENT_MELEE_ATTACK` and `EVENT_RECOVERY_END` drive these transitions. The completion logic is redundant and could theoretically double-fire if timing drifts.

### Options

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| Remove completion | Only advance `state_timer`; events do the rest | Single source of truth; no double-fire | Requires events to always fire on time |
| Keep as fallback | Leave completion logic as safety net | Handles missed/delayed events | Risk of double _execute_attack / complete_recovery |
| Remove and add assertion | Remove completion; add debug assert if timer exceeds duration | Catches event bugs | More strict; needs event correctness |

**Recommendation:** Remove the completion logic from both. Events are the authority. If events fail to fire, that’s a bug to fix, not something to paper over with fallback logic.

---

## Summary: Recommended Approach

| Problem | Recommended fix |
|---------|------------------|
| 1. Parry defender stuck | **Option A:** Call `manager._schedule_event()` from AttackResultApplier for both `parry_deflect` and `parry_partial`. Use `resolve_at = combat_clock + 0.02`. |
| 2. Cowering recovery stuck | **Option A:** Call `manager._schedule_event()` from `process_incapacitation` when leaving cowering. Use `resolve_at = manager.combat_clock + 0.05`. |
| 3. process_waiting duplication | **Option A:** Remove gauge fill and turn_ready block from `process_waiting`; keep only guard rise and stamina refill. |
| Wind-up/recovery completion | Remove completion logic; rely on events. Keep `state_timer += delta` for UI countdown. |

---

## Timing Constants

| Transition | Suggested resolve_at | Rationale |
|------------|----------------------|-----------|
| Parry defender ready | `combat_clock + 0.02` | Small delay; riposte slightly after deflect |
| Cowering recovery | `combat_clock + 0.05` | Same as medical cancel; slight stagger |
| Medical cancel | `combat_clock + 0.05` | (existing) |

These can be tuned later (e.g. parry bonus, engagement timing).
