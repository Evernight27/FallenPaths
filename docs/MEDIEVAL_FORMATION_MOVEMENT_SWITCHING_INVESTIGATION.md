# Medieval Formation Movement & Rank Switching: Investigation

Investigation of how medieval (and Roman) formation movement—rank swap, fall back, retreat—actually worked, and how to model it realistically: **time and effort** vs stamina cost; **clear lane vs crowded**; **aggressive enemy vs defensive enemy**.

---

## Part 1: Historical Movement Mechanics

### 1.1 Roman System (Maniple / Cohort)

| Aspect | How it worked |
|--------|----------------|
| **Gaps** | Deliberate gaps between maniples. Retreating troops fell back *through* gaps. |
| **Fall back** | Exhausted hastati withdrew through gaps; principes advanced into those gaps to fill the line. |
| **Cost** | **Time** — the withdrawal and advance took real seconds. **Coordination** — had to happen on command, in sync. **Risk** — during the moment of swap, the line was momentarily thinner. |
| **Stamina** | Exhaustion triggered rotation, but the *act* of falling back was not "spending energy" — it was *relief*. The effort was in holding the line until the moment to withdraw. |

**Key insight:** Falling back was **escape from exertion**, not exertion itself. The cost was **tactical** (temporary weakness, coordination) and **temporal** (took time).

---

### 1.2 Medieval Shield Wall

| Aspect | How it worked |
|--------|----------------|
| **Channels** | Pre-designated channels for rotation. Reserved warriors from rear replaced exhausted front. |
| **Footwork** | Synchronized on vocal command. Small increments—no chaotic running. |
| **Plugging** | When a man fell, neighbors closed immediately. Gap = catastrophe. Fall back had to preserve the line. |
| **Structure** | 6–8 ranks deep (sometimes 16). Rear ranks reinforced; could advance when needed. |

**Key insight:** Rotation required (1) **clear path** — someone had to step aside or you went through a channel; (2) **time** — synchronized footwork took seconds; (3) **no panic** — controlled retreat. If you were **hard pressed** (enemy actively attacking), you couldn't safely withdraw—you'd be cut down or create a gap.

---

### 1.3 What Made Fall Back Harder vs Easier

| Factor | Harder to fall back | Easier to fall back |
|--------|---------------------|----------------------|
| **Enemy pressure** | Aggressive enemy pressing the attack | Defensive enemy, low stamina, holding back |
| **Lane** | Rank 1 advancing into your slot (moving forward) or crowded | Clear channel; reserve holding position |
| **Formation density** | Tight shield wall (no room to step aside) | Loose formation (space to slip through) |
| **Exhaustion** | You're exhausted (slow, can't move quickly) | You're fresh (can move fast) |
| **Coordination** | Formation scattered, no command | Formation cohesive, synchronized |

**Your intuition is correct:** Stamina cost is wrong. The difficulty is **time** (how long the move takes) and **situational** (clear lane vs blocked, aggressive vs defensive opponent).

---

## Part 2: Recommended Model — Time + Situational Modifiers

### 2.1 No Stamina Cost for Fall Back / Swap

**Rationale:** Historically, fall back was *escape* from exertion. Adding stamina cost would double-penalize the exhausted (they need to leave because low stamina, but leaving costs more stamina). The *reason* you fall back is often low stamina—the action itself shouldn't spend it.

**Implementation:** Fall back and swap rank do **not** consume stamina. They take **time** (event delay) and are **blocked or slowed** by situational factors.

---

### 2.2 Time (Event Delay)

**Mechanic:** Fall back / swap rank is an event that resolves after a **duration**. Duration depends on:

| Factor | Effect on duration |
|--------|---------------------|
| **Base duration** | e.g. 0.5–1.5 s (agility, armor burden) |
| **Lane clarity** | Clear lane = base. Blocked/crowded = ×1.5 or ×2. |
| **Opponent pressure** | Aggressive opponent = ×1.3–1.5. Defensive/low stamina = ×1.0 or ×0.9. |
| **Formation density** | Tight = ×1.2. Loose = ×0.9. |

During this time, the unit is **vulnerable** — they're disengaging or moving. Opponent can attack them; if they're hit during the move, the move can be interrupted or they take penalty.

---

### 2.3 Lane Clarity — People in the Way

**Clear lane:** Rank 1 is holding position or has space. Unit can slip through. Normal duration.

**Blocked / crowded:** 
- Rank 1 is **advancing** (plugging, filling a gap) — they're moving *into* the slot. Unit has to squeeze past or wait. **Slower**.
- Multiple units in same area (drag-back, step-over) — reduced footing, distraction. **Slower** and possibly **higher risk** (distraction deficit).

**Implementation:**
- `lane_clarity: "clear"|"crowded"|"blocked"` derived from formation state.
- `blocked` = rank 1 advancing into that file, or slot has multiple units (drag-back in progress).
- `crowded` = adjacent files shifting, or formation density tight.
- Duration multiplier: clear 1.0, crowded 1.3, blocked 1.6 (or roll to see if move succeeds at all when blocked).

---

### 2.4 Opponent Pressure — Aggressive vs Defensive

**Aggressive opponent:** High stamina, actively attacking, pressing the engagement. Unit trying to fall back is "hard pressed" — they can't safely turn their back or step away. The opponent gets opportunities to strike during the move.

**Mechanic:**
- When unit attempts fall back, check opponent state: `opponent.stamina > 50` and `opponent.state in [WIND_UP, IN_FLURRY]` or `opponent.recent_action == "attack"` → **aggressive**.
- Aggressive: fall back duration ×1.3; or roll `disengage_hold` vs `opponent.hold_strength` — if fail, fall back delayed or cancelled.
- **Defensive opponent:** Low stamina, holding ground, not attacking. Unit can withdraw more easily. Duration ×1.0 or ×0.9.

**Alternative:** Use the existing **disengage roll** (defender rolls vs attacker hold). Fall back *includes* disengage. If opponent is aggressive (high hold, actively engaged), disengage is harder. If opponent is defensive (low stamina, not engaged), disengage is easier. So the **time** for fall back could scale with disengage difficulty — multiple attempts, or longer single attempt.

---

### 2.5 Summary: Movement Cost Model

| Cost type | Fall back / Swap rank |
|-----------|------------------------|
| **Stamina** | None |
| **Time** | Yes — event delay 0.5–1.5 s base × situational modifiers |
| **Lane** | Clear = normal. Crowded = ×1.3. Blocked = ×1.6 or require coordination |
| **Opponent** | Aggressive = ×1.3 or harder disengage. Defensive = normal or easier |

**Formula (suggested):**
```
fall_back_duration = BASE_FALL_BACK_S * agility_factor * armor_burden_factor
                   × lane_modifier(lane_clarity)   # 1.0, 1.3, 1.6
                   × pressure_modifier(opponent)   # 0.9 defensive, 1.0 neutral, 1.3 aggressive
```

---

## Part 3: Implementation Notes

### 3.1 Event Structure

Fall back and swap rank are **events** with `resolve_at = now + duration`. During the duration:
- Unit is in `STATE_FALLING_BACK` or `STATE_SWAP_RANK`.
- Opponent can target them (vulnerable).
- If unit is hit, optional: interrupt move, or apply penalty (distraction deficit when they arrive).

### 3.2 Lane Clarity Calculation

- `get_lane_clarity(formation, rank, file)`:
  - If rank 1 at same file is advancing (plugging) → `blocked`.
  - If formation density tight and adjacent files shifting → `crowded`.
  - Else → `clear`.

### 3.3 Aggressive vs Defensive Opponent

- `get_opponent_pressure(opponent)`:
  - If `opponent.stamina < 30` and not in WIND_UP → `defensive` (0.9× duration).
  - If `opponent.stamina > 60` and recently attacked or in flurry → `aggressive` (1.3× duration, or require disengage roll).
  - Else → `neutral` (1.0×).

### 3.4 Integration with Disengage

Fall back *requires* disengage when at close. The disengage roll can be:
- **Easier** when opponent defensive (they're not holding you).
- **Harder** when opponent aggressive (they're pressing, holding).
- On success: unit transitions to mid/long, then executes the spatial move (fall back to rank 1 or rear zone).
- The **time** for the whole action = disengage attempt time + movement time.

---

## Part 4: Recommendation Summary

1. **No stamina cost** for fall back or swap rank.
2. **Time-based** — both take event delay; duration scales with lane clarity and opponent pressure.
3. **Lane clarity** — clear lane = fast; people in the way or advancing into your slot = slow or blocked.
4. **Opponent pressure** — aggressive enemy = harder (longer, or disengage roll); defensive/tired enemy = easier.
5. **Vulnerability** — during the move, unit can be targeted; hit may interrupt or penalize.

---

## References

- `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` — Roman vs medieval rotation, plugging
- `docs/STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md` — Event queue, disengage
- Medieval shield wall rotation (Wikipedia, Medievalists.net): pre-designated channels, synchronized footwork
