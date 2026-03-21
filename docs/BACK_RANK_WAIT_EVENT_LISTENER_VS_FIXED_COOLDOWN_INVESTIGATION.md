# Back Rank Wait: Event Listener vs Fixed Cooldown — Investigation

**Question:** Should the back row use an event listener instead of a fixed 2-second wait when they have no actions?

---

## Current System: Fixed 2s Cooldown

When a back-rank (rank 1+) unit skips (no actions), we schedule `EVENT_ACTION_READY` at `combat_clock + 2.0`.

| Pros | Cons |
|------|------|
| Simple, predictable | Wastes events: back rank gets turn every 2s even when nothing changed |
| No extra logic | Feels arbitrary (why 2s?) |
| Works without formation_changed | Event queue can accumulate many skip events in long battles |
| Promoted units already get 0.15s wake on plug | Back rank may "miss" a plug if their 2s fires before the plug and they skip again |

---

## Alternative A: formation_changed Event Listener

**Mechanism:** When `formation_changed` fires (plug, swap), schedule `EVENT_ACTION_READY` at +0.2s for all back-rank units in WAITING on that formation. When back rank skips, do **not** schedule—they wait until the next formation change.

| Pros | Cons |
|------|------|
| Back rank wakes only when something relevant happens | **Stuck forever:** If formation never changes (front healthy, won't swap), back rank never acts |
| Reduces event spam | Need safety: max wait (e.g. 4s) to avoid permanent freeze |
| Semantically correct: "wait for your moment" | formation_changed can fire often (swap)—every swap would wake back rank, who'd skip again |
| Responsive to plug (0.2s vs possibly waiting for old 2s) | More complex: cancel pending, schedule on signal |

---

## Alternative B: Hybrid — formation_changed Wake + Fallback Cooldown

**Mechanism:**
1. On `formation_changed`: Cancel any pending `EVENT_ACTION_READY` for back-rank units in that formation; schedule at +0.2s.
2. When back rank skips: Schedule at 2.5s (fallback). If formation_changed fires before that, the 0.2s event replaces the need for the 2.5s one (both would fire—first wins; second finds them already acted or in different state).

**Problem:** Duplicate events. If we schedule 0.2s on formation_changed and they already have 2.5s pending, we'd have two events. When 0.2s fires, they skip and schedule another 2.5s. The old 2.5s would still fire later—waste. We need to **cancel** pending when formation_changed fires.

| Pros | Cons |
|------|------|
| Back rank wakes quickly when plug/swap happens | Requires `_cancel_pending_action_ready(combatant_id)` |
| Fallback ensures they never wait forever | Slightly more code |
| Best of both worlds | |

---

## Alternative C: formation_changed Wake + No Fallback

Back rank never schedules on skip. They only wake on formation_changed. **Risk:** If front rank never dies and never swaps (e.g. long standoff), back rank is permanently stuck. **Mitigation:** Add a "max wait" timer: if a back-rank unit has been WAITING for >4s with no formation_changed, schedule one. That's equivalent to a 4s fallback.

---

## Recommendation

**Hybrid (B)** with cancel support:

1. Add `_cancel_pending_action_ready(combatant_id)` to remove matching events from the queue.
2. On `formation_changed(fid)`: For each combatant in that formation with rank > 0 and state WAITING, cancel their pending ACTION_READY and schedule at +0.2s.
3. When back rank skips: Schedule at 2.5s (fallback).

Result: Plug/swap → back rank acts in 0.2s. Nothing changes → back rank checks every 2.5s. No duplicate turns.

---

## Implementation (done)

**Hybrid event model** (see CombatManager, event queue):

- **Signals drive scheduling:** `formation_changed` → `_reschedule_back_rank_turns(fid)` reschedules back-rank ACTION_READY at `READY_DELAY_FORMATION_RECHECK_S` (0.2s). `turn_resolved(combatant_id)` emitted when a combatant commits their action.
- **Centralized scheduling:** `_schedule_action_ready(combatant_id, delay_s)` always cancels pending first, then schedules. Avoids duplicate turns.
- **Constants:** `READY_DELAY_*` in CombatConstants (SKIP_DEFAULT, SKIP_BACK_RANK, FORMATION_RECHECK, AFTER_PROMOTION, PARRY_RIPOSTE, CLOSE_ATTEMPT).
- **Heap-compatible:** Events remain time-ordered; signals trigger insertions. Phase 1 min-heap will key by `resolve_at`.
