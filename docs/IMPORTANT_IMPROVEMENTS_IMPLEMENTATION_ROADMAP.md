# Most Important Improvements: Implementation Roadmap

Investigation into the **best ways to implement** the highest-priority improvements for Fallen Paths combat, based on PHYSICS_REALISM_DECISIONS, GUARD_LINE_DYNAMICS_INVESTIGATION, HEMA_ZONES, and existing docs.

---

## 1. What's Already Done

| System | Status | Location |
|--------|--------|----------|
| 4-line guard (alignment, variance, leak) | Done | CombatConstants, AttackResolver, DefenseChoiceResolver |
| Afterblow | Done | AfterblowHandler.gd |
| attack_line per move | Done | WeaponConstants.gd |
| guard_line per combatant | Done | CombatManager (default "high") |
| **Guard line dynamics** | Done | GuardLineUpdater, CombatStateHandlers, AttackResultApplier |
| **Transition cost** | Done | CombatManager._begin_attack_with_target |
| **Physics-based riposte (tempo penalty)** | Done | CombatStateHandlers (OFF_BALANCE_GAUGE_FILL_MULT) |
| **Combat debug logging** | Done | CombatDebug.gd, COMBAT_DEBUG flag |

---

## 2. Priority Order (Impact vs Effort)

| # | Improvement | Effort | Impact | Rationale |
|---|-------------|--------|--------|-----------|
| 1 | **Guard line dynamics** (after-attack) | Low | High | Physics: cut ends in guard. Fixes "guard never changes." |
| 2 | **Riposte priority** | Low | High | HEMA: parry → counter. Universal historical source. |
| 3 | **Transition cost** (wind-up from guard) | Medium | High | Physics: blade inertia. Rewards flow. |
| 4 | **Calibration logging** | Low | Medium | Enables tuning to 57–80% parry share. |
| 5 | Parry updates guard (Option F) | Low | Medium | Optional add-on; defenders who only parry get guard evolution. |

---

## 3. Implementation Details

### 3.1 Guard Line Dynamics (After-Attack) — **Implement First**

**Goal:** When attacker finishes recovery, set `guard_line = attack_line` of the move they used.

**Data needed:** `last_move_id` on combatant. Move has `attack_line` (already in WeaponConstants).

**Hook:** `CombatStateHandlers.process_recovering` — when `c.state_timer >= c.state_duration` and we're about to set `c.state = STATE_WAITING`, update guard_line from last_move_id.

**Where to get move_id:** Attacker's `pending_attack.attack_type` (move_id). For most outcomes (miss, dodge, hit), we don't clear pending_attack in apply_result — process_recovering clears it. So we can read `c.pending_attack.get("attack_type","")` in process_recovering before clearing. **Exception:** parry_deflect clears `atk.pending_attack` in apply_result, so we must set `atk["last_move_id"]` there *before* clearing.

**Files to change:**

1. **AttackResultApplier** — in parry_deflect block, before `atk.pending_attack = {}`: add `atk["last_move_id"] = atk.pending_attack.get("attack_type", "")`.
2. **CombatStateHandlers.process_recovering** — when transitioning to WAITING, before `c.pending_attack = {}`:
   ```gdscript
   var move_id: String = c.get("last_move_id", "")
   if move_id.is_empty():
       move_id = c.pending_attack.get("attack_type", "")
   c.pending_attack = {}
   if not move_id.is_empty():
       var move_def = WeaponConstants.get_move(move_id)
       var line: String = move_def.get("attack_line", "")
       if not line.is_empty():
           c["guard_line"] = line
   ```
4. **WeaponConstants** — add helper if needed: `static func get_attack_line(move_id: String) -> String` returning `get_move(move_id).get("attack_line", "high")`. Or just use get_move inline.

**Edge cases:**
- Skip / medical / no attack: last_move_id empty → keep current guard.
- Move has no attack_line: fallback "high".

---

### 3.2 Riposte Priority — **Implement Second**

**Goal:** On parry_deflect, defender gets to act first (next tick) — "after parrying, then it's a tempo to attack" (Dall'Agocchie).

**Mechanic:** Set defender `gauge = 100` so on the next process tick they emit `turn_ready` (player) or immediately pick a riposte action (AI). No new state machine; reuse existing turn flow.

**Files to change:**

1. **AttackResultApplier** — in parry_deflect block, after setting `tgt.state = STATE_WAITING`:
   ```gdscript
   if tgt != null:
       tgt["parry_bonus_until"] = ...
       tgt.state = CombatConstants.STATE_WAITING
       tgt.state_timer = 0.0
       tgt.state_duration = 0.0
       tgt.gauge = 100.0  # Riposte priority: act next tick
   ```

**Rationale:** Defender was target of attack; their gauge was not filling during the exchange. Setting to 100 makes them "ready" immediately. Next frame, `process_waiting` sees gauge >= 100 → player gets turn_ready, AI auto-picks and resolves. Defender effectively gets the next action.

**Optional refinement:** Clear `riposte_priority = true` when they act, so we can show "Riposte!" in UI. For now, gauge=100 is sufficient.

---

### 3.3 Transition Cost (Wind-Up from Guard) — **Implement Third**

**Goal:** Attacks from the same guard line as current position have normal wind-up; attacks from wrong guard cost extra time (blade must move).

**Formula:** `windup_mult *= (1.0 + (1.0 - alignment) * GUARD_TRANSITION_COST_SCALE)`. Alignment from `CombatConstants.get_line_alignment(attack_line, guard_line)`.

**Constant:** `GUARD_TRANSITION_COST_SCALE := 0.4` (at alignment 0: +40% wind-up).

**Hook:** `CombatManager._begin_attack_with_target` — after computing `wind_up_s`, multiply by transition factor. Need attack_line from the move. The `attack_type` in pending_attack is the move_id. So:
- Get move_def from WeaponConstants.get_move(attack_type) — but attack_type might be from weapon at this point. Check: we use `attack_type = move_id` if provided, else pick from weapon. So at _begin_attack we have the move_id (attack_type).
- Get attack_line from move: `WeaponConstants.get_move(attack_type).get("attack_line", "high")`
- Get guard_line from atk: `atk.get("guard_line", "high")`
- alignment = CombatConstants.get_line_alignment(attack_line, guard_line)
- transition_mult = 1.0 + (1.0 - alignment) * CombatConstants.GUARD_TRANSITION_COST_SCALE
- wind_up_s *= transition_mult

**Files to change:**

1. **CombatConstants** — add `const GUARD_TRANSITION_COST_SCALE := 0.4`
2. **CombatManager._begin_attack_with_target** — after `wind_up_s = CombatTiming.wind_up_duration(...)` and leg/perf/agility modifiers, add:
   ```gdscript
   var attack_line: String = "high"
   var move_def = WeaponConstants.get_move(attack_type)
   if not move_def.is_empty():
       attack_line = move_def.get("attack_line", "high")
   var guard_line: String = atk.get("guard_line", "high")
   var align: float = CombatConstants.get_line_alignment(attack_line, guard_line)
   var trans_mult: float = 1.0 + (1.0 - align) * CombatConstants.GUARD_TRANSITION_COST_SCALE
   wind_up_s *= trans_mult
   ```

**AI consideration:** CombatAIActionPicker could weight moves by transition cost (prefer same-line follow-ups). Defer; the mechanic itself works without AI changes.

---

### 3.4 Calibration Logging — **Implement Fourth**

**Goal:** Optional debug logs for alignment, parry_c_d, variance, geometric_leak so we can tune to HEMA 57–80% blade-blade contact.

**Mechanic:** Add a constant `const COMBAT_DEBUG_CALIBRATION := false`. When true, log in AttackResolver / DefenseChoiceResolver at key points. Or use a debug/verbose flag.

**Log points:**
- Before parry calc: attack_line, guard_line, alignment
- After parry: parry_c_d (before/after alignment), variance_eff, remaining_ratio, geometric_leak
- Resolved outcome: parry_deflect / parry_partial / hit

**Files:** AttackResolver.gd, DefenseChoiceResolver.gd. Add `if CombatConstants.COMBAT_DEBUG_CALIBRATION: print(...)`.

**Constant:** `CombatConstants.COMBAT_DEBUG_CALIBRATION := false` (or read from project settings).

---

### 3.5 Parry Updates Guard (Optional) — **Implement Fifth**

**Goal:** When defender parries (deflect or partial), their blade ends in a position. Set `guard_line = attack_line` when alignment was good.

**Hook:** AttackResultApplier, parry_deflect and parry_partial. For parry_deflect, tgt gets full deflect — their blade met the attack. Set `tgt["guard_line"] = attack_line`. Need attack_line from result — AttackResolver returns it? Check: result has attack_line? Probably not. We need to get it from attacker's pending_attack.attack_type before we clear it. In parry_deflect we clear atk.pending_attack... no we don't, we set atk.state=RECOVERING and the pending_attack gets cleared elsewhere. Actually in parry_deflect we don't touch atk.pending_attack in the apply_result — we set atk.pending_attack = {} in the parry_deflect block? No, looking at the code again: we set atk.state, state_duration, off_balance. We don't clear pending_attack in apply_result for parry_deflect. The pending_attack gets cleared in process_recovering when attacker finishes. So at parry_deflect time, atk still has pending_attack with attack_type. So we can get attack_line from WeaponConstants.get_move(atk.pending_attack.get("attack_type","")).get("attack_line","high"). Then set tgt.guard_line = that.

For parry_partial, we call _execute_attack (attacker continues) and tgt goes to WAITING. We could set tgt.guard_line there too. Need attack_line — from atk.pending_attack.

**Refined:** Only update when alignment > 0.6 (good parry). For parry_deflect, alignment is high (they deflected). For parry_partial, we'd need to pass alignment in the result. Check AttackResolver — does result include alignment? DefenseChoiceResolver computes it. The result from resolve_attack... let me check. Actually for parry_deflect we know the parry worked well. For parry_partial, it's messier. Simplest: for parry_deflect only, set tgt.guard_line = attack_line. For parry_partial, defer (defender's blade may have been in odd position).

---

## 4. Implementation Order & Dependencies

```
1. Guard line dynamics (B)
   └── Requires: last_move_id set in AttackResultApplier
   └── Requires: process_recovering reads last_move_id, updates guard_line

2. Riposte priority
   └── Independent. Just set tgt.gauge = 100 on parry_deflect.

3. Transition cost (C)
   └── Requires: guard_line is correct (from 1)
   └── Apply in _begin_attack_with_target

4. Calibration logging
   └── Independent. Add print statements behind flag.

5. Parry updates guard (F)
   └── Optional. Depends on 1 (guard_line exists). parry_deflect only.
```

---

## 5. Summary: Minimal Code Touches

| Improvement | Files | Lines (est.) |
|-------------|-------|--------------|
| Guard dynamics | AttackResultApplier, CombatStateHandlers, CombatConstants (optional helper) | ~15 |
| Riposte priority | AttackResultApplier | ~1 |
| Transition cost | CombatConstants, CombatManager | ~10 |
| Calibration | CombatConstants, AttackResolver, DefenseChoiceResolver | ~20 |
| Parry guard | AttackResultApplier | ~5 |

**Total:** ~50 lines across 5–6 files for the first four improvements.

---

## References

- PHYSICS_REALISM_DECISIONS_INVESTIGATION.md
- GUARD_LINE_DYNAMICS_INVESTIGATION.md
- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- AttackResultApplier.gd, CombatStateHandlers.gd, CombatManager.gd
