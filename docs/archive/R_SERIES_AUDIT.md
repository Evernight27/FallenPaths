# R-Series Audit Report — Third Deep Review

**Date:** 2026-07-06
**Scope:** `CombatResolveAction`, `CombatManager` delegates, `CombatStateHandlers`, `CombatFormationMoveListing`, `MentalStackDecider` (post-M4), `CounterTempo` (post-O2/M6), `CombatFlurryBind` (post-H4), `CombatDistanceBands` (post-Q6), `CombatAIActionPicker`, `CombatEngagementResolver`
**Excludes:** P-series fixes, Q-series fixes

---

## R1: Double-signal risk in `_commit_bind_resolve` — missing signal emission at wrapper level

**Severity:** High
**File:** `combat/CombatResolveAction.gd:439-442`

```gdscript
static func _commit_bind_resolve(manager: Node, attacker_id: int, target_id: int) -> bool:
    manager._resolve_bind(attacker_id, target_id)
```

The `_commit_*_resolve` wrappers uniformly emit `action_resolved` + `turn_resolved` after calling the delegate. But `_commit_bind_resolve` does NOT emit either signal — it delegates to `resolve_bind()` which emits its own `action_resolved` internally (at lines 505-627 of EngagementResolver). Meanwhile, all other D-series wrappers (`_commit_disengage_resolve`, `_commit_lateral_step_resolve`, etc.) call the delegate AND then emit signals.

**Problem:** The wrapper returns `bool` but emits no signal itself. The inner function emits `action_resolved` but NOT `turn_resolved`. Every other path in `resolve_action()` emits `turn_resolved` at the end (lines 299-441). This means a successful bind is the ONLY D-series move that skips `turn_resolved`.

**Impact:** Any listener expecting `turn_resolved` after every resolved action (UI update, breath refill reset, turn accounting) will miss bind completions. This creates a silent state desync where the attacker is marked ready again but the "turn done" signal never fires.

---

## R2: Bind resolve emits `action_resolved` on every early-return failure — no consistent `turn_resolved` pairing

**Severity:** Medium
**File:** `combat/CombatEngagementResolver.gd:503-570`

Every early-return guard in `resolve_bind` (medical blocked, target invalid, attacker invalid, no arm, not close, cooldown) emits `action_resolved` but does NOT emit `turn_resolved`. Compare with `_commit_disengage_resolve` (line 413) which always emits both.

**Problem:** Inconsistent signal pairing across D-series moves. Some paths emit only `action_resolved`, others emit both. Listeners that expect paired signals (e.g., UI clearing action highlight on `turn_resolved`) will leave stale UI state after a bind failure.

---

## R3: `_filter_incoming_threat_actions` excludes counter-tempo actions from L3 — contradicts L2/L3 ordering intent

**Severity:** Medium
**File:** `combat/MentalStackDecider.gd:476-491`

```gdscript
if a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
    continue  # M6: counter-tempo is L2-only; exclude from L3 fallback.
```

The comment says M6 fixed this to be L2-only. But consider the scenario: an attacker winds up at me (L3 triggers), but I also have a counter-tempo window open. Counter-tempo was already evaluated at L2 and either succeeded or failed. If it succeeded, we never reach L3. If it failed (no counter actions listed at L2 time), we reach L3 — and then the filter explicitly excludes counter-tempo moves that ARE in the action list.

**Problem:** If a counter-tempo move was listed but not picked at L2 (e.g., low weight vs other counter options), it becomes permanently unavailable for the turn because L3 will filter it out. The AI loses a valid defensive option. In a tight timing window where both L2 and L3 fire, this could cause the AI to pick a suboptimal melee strike against an incoming attacker when counter-tempo would have been superior.

---

## R4: Duel distance cognition (MS-L8) — `bind` recommendation at CLOSE ignores bind cooldown check

**Severity:** Medium
**File:** `combat/MentalStackDecider.gd:696-697`

```gdscript
if c_skill > h_skill * 1.25 and CombatConstants.MOVE_ID_BIND in move_ids:
    return {"preferred_move": CombatConstants.MOVE_ID_BIND}
```

The duel layer checks if `MOVE_ID_BIND` is in the action list, but does NOT check `bind_cooldown_until`. The listing layer (`CombatFormationMoveListing.gd:626`) already filters out bind when cooldown is active. However, the action list passed to `_duel_distance_cognition_layer` is the FULL menu — not the filtered list. If bind was listed for another target but is on cooldown vs this specific duel opponent, the AI will pick it and fail in resolve.

**Impact:** Wasted turns when the duel layer recommends bind that's actually on cooldown. This is worse than random picking because the mental stack layer has already committed (stamped), preventing fallback to utility pick.

---

## R5: `resolve_bind` — both attacker AND target get action ready scheduled, but only attacker gets `turn_resolved`

**Severity:** High
**File:** `combat/CombatEngagementResolver.gd:617-622` vs signal emission at line 624

```gdscript
_EventScheduler.schedule_action_ready(manager, attacker_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)
_EventScheduler.schedule_action_ready(manager, target_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)
manager.emit_signal("action_resolved", attacker_id, target_id, {...})
```

Both combatants participate in the bind (both spend breath, both get cooldowns). Both are scheduled as ready again. But only `attacker_id` gets `turn_resolved` (via the wrapper chain). The target's turn state is never updated.

**Problem:** If the target was in `STATE_WAITING`, they remain waiting even though their action just resolved (they were dragged into a bind). The target will not get another turn until something else triggers them, effectively losing a turn. Compare with `_resolve_advance` (line 414) which also affects both but at least emits `action_resolved` for attacker — the target's state handling is similarly inconsistent.

---

## R6: Bait resolve — no breath cost deduction despite being a committed action

**Severity:** Low
**File:** `combat/CombatEngagementResolver.gd:453-501`

The `resolve_bait` function stamps `bait_open_line` and `bait_active_until` on the attacker but does NOT deduct any breath cost. Compare with `resolve_bind` which deducts `BREATH_BIND_COST` from both participants. Bait is a committed tactical action that occupies a turn, yet costs zero breath.

**Impact:** AI can bait infinitely without resource pressure. This may be intentional design (bait as free feint), but it's inconsistent with the resource model of other D-series moves. If intentional, should be documented. If not, `BREATH_BAIT_COST` should exist.

---

## R7: `resolve_bind` — no `turn_resolved` emitted for either participant

**Severity:** High (confirmed from grep)
**File:** `combat/CombatEngagementResolver.gd:503-633`

Confirmed by grep: `resolve_bind` emits only `action_resolved` (lines 505, 517, 526, 534, 544, 554, 563, 624). No `turn_resolved` is emitted anywhere in the function. The wrapper `_commit_bind_resolve` also does not emit it.

**Impact:** This is a confirmed signal gap. Every other resolve path emits `turn_resolved`. Bind is the only D-series move without it. Any system tracking "whose turn completed" via `turn_resolved` will miss bind actions entirely.

---

## R8: `_commit_*_resolve` wrappers — inconsistent return value semantics

**Severity:** Low
**File:** `combat/CombatResolveAction.gd:401-441`

All `_commit_*_resolve` functions return `bool`, but none of the callers check the return value. The wrapper at line 218 calls `_commit_bind_resolve(manager, attacker_id, target_id)` with no assignment or condition. The return type is a dead contract — every caller unconditionally proceeds to schedule action ready and emit turn_resolved.

**Impact:** If a future refactor adds early-return logic inside the wrappers (e.g., "return false on fatal error"), callers won't observe it. The `bool` return should either be used or removed.

---

## R9: `CombatStateHandlers.process_recovering` — composure fill rate may conflict with breath refill during bind cooldown

**Severity:** Low
**File:** `combat/CombatStateHandlers.gd:272-285`

During RECOVERING state, both composure gauge fills at 8/s AND breath refills. After a bind, both participants are put in action cooldown but their state isn't explicitly changed to RECOVERING — they stay in whatever state they were (likely WAITING). The `schedule_action_ready` will transition them back to WAITING after the delay.

**Problem:** During the bind cooldown window (~0.5s), combatants are still in WAITING and filling composure at 25/s, not RECOVERING at 8/s. This means a fighter who just lost a bind (spent breath, got pushed) gets MORE composure fill during their forced cooldown than they would if they had chosen to wait voluntarily. The resource recovery rate is higher for involuntary downtime.

---

## R10: `_analyze_duel_context` — hostile count check uses `hostiles.size() != 1` then reassigns `hostiles = engaging`

**Severity:** Medium
**File:** `combat/MentalStackDecider.gd:656-667`

```gdscript
if hostiles.size() != 1:
    var engaging: Array = []
    for h in hostiles:
        var hid: int = _EntityAccess.id_int(h)
        var hb: String = _EntityAccess.distance_to_opponent_band(c, hid)
        if hb != CombatConstants.DISTANCE_FAR:
            engaging.append(h)
    if engaging.size() != 1:
        return {}
    hostiles = engaging
```

The M4 fix improved the filter to only count non-FAR hostiles. But `hostiles` is reassigned (not appended), meaning the original `hostiles` array with all enemies is discarded. If there are 3 enemies total but only 1 at engaging range, this works correctly. However, if there are 2 enemies at engaging range, the function returns empty — preventing bind/advance recommendations even though a clear duel dynamic exists.

**Problem:** In a 2v1 or 3v1 where two enemies are at CLOSE/MID range, the duel layer silently bails out. The AI misses bind/advance opportunities against either opponent because neither is "the one hostile." This may be intentional (duel layer only for true 1v1), but means the layer fires less often than expected in multi-opponent engagements.

---

## Summary

| ID | Severity | File | Issue |
|----|----------|------|-------|
| R1 | High | CombatResolveAction:439 | `_commit_bind_resolve` missing signal emissions |
| R2 | Medium | CombatEngagementResolver:503-570 | Bind early returns: `action_resolved` without `turn_resolved` |
| R3 | Medium | MentalStackDecider:476 | L3 filters counter-tempo that may be the best available option |
| R4 | Medium | MentalStackDecider:696 | Duel layer recommends bind without checking cooldown |
| R5 | High | CombatEngagementResolver:617-622 | Target of bind gets no `turn_resolved` despite participating |
| R6 | Low | CombatEngagementResolver:453 | Bait has no breath cost (may be intentional) |
| R7 | High | CombatEngagementResolver:503-633 | Confirmed: bind never emits `turn_resolved` |
| R8 | Low | CombatResolveAction:401-441 | `_commit_*_resolve` return bool is unused dead contract |
| R9 | Low | CombatStateHandlers:272 | Post-bind cooldown fills composure at WAITING rate, not RECOVERING |
| R10 | Medium | MentalStackDecider:656-667 | Duel layer bails on 2+ engaging hostiles, missing bind opportunities |

**Highest priority:** R1/R7 (same root cause — bind signal gap), R5 (target turn-state orphan).
