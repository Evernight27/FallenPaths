# State Machines and Parry: Ways to Make Combat More Realistic

Investigation of how the current combat state machine and parry interact, and different ways to use states (and new states) for more realistic behavior.

---

## 1. Current state machine (summary)

```
                    ┌─────────────────────────────────────────────────────────┐
                    │  STATE_WAITING                                           │
                    │  - Gauge fills (agility × performance)                   │
                    │  - Can act only when gauge >= 100                        │
                    │  - Actions: attack, parry (if someone winding up on me), │
                    │            medical (if ally in danger)                   │
                    └─────────────────────────────────────────────────────────┘
                       │                    │                    │
         attack        │ parry              │ medical            │
         chosen        │ chosen             │ chosen             │
                       ▼                    ▼                    ▼
    ┌──────────────┐  ┌──────────────────┐  ┌─────────────────────┐
    │ STATE_WIND_UP│  │ STATE_PARRY_      │  │ STATE_MEDICAL_       │
    │ (attack)     │  │ WIND_UP           │  │ WIND_UP              │
    │ - Timer to   │  │ - Timer to get    │  │ - Timer for bandage  │
    │   impact     │  │   blade in place  │  │   / tourniquet       │
    │ - No gauge   │  │ - No gauge fill   │  │ - No gauge fill      │
    └──────────────┘  └──────────────────┘  └─────────────────────┘
           │                     │                      │
           │ impact              │ parry ready first    │ done
           │ or parry at impact  │ or attack lands      │
           ▼                     ▼                      ▼
    ┌──────────────────────────────────────────────────────────────┐
    │  STATE_RECOVERING                                            │
    │  - Follow-through after hit/deflect/miss/parry/medical        │
    │  - Duration depends on outcome (miss longest, deflect extra) │
    │  - No gauge fill                                             │
    └──────────────────────────────────────────────────────────────┘
           │
           │ timer done
           ▼
    back to STATE_WAITING (gauge 0)
```

**Current realism-related behavior:**

- **Waiting:** Binary “can act / can’t act” (gauge 100). No notion of “guard” or “readiness.”
- **Wind-up:** Committed; no abort. Resolution is either “attack lands” or “parry race” (if defender chose parry).
- **Recovering:** Flat duration; no early/late phase. Defender can be attacked during recovery and gets **passive parry** (A4v3) if they notice in time.
- **Parry:** Active (choose parry → parry_wind_up → resolve) plus passive (reaction time vs wind-up, capacity scaled by time_to_react). Passive parry is **disabled** when defender is in WIND_UP or MEDICAL_WIND_UP; **enabled** when WAITING or RECOVERING.

---

## 2. Gaps for realism

| Gap | Why it matters |
|-----|----------------|
| **No guard / readiness** | In real fencing, “on guard” vs “blade down” changes how fast you can parry. Right now WAITING is the same whether you’re “ready” or not. |
| **Recovery is flat** | Right after a big miss or heavy hit you’re more vulnerable (off balance, slow to react). Late recovery you’re almost back to ready. State doesn’t distinguish. |
| **No commitment phase** | Once you start wind-up you’re 100% committed. Realistically there’s a short “telegraph” before full commitment. |
| **Parry only “available when attacked”** | Active parry exists only when someone is winding up on you. No “I’m in a defensive stance so I’m harder to hit even when I don’t choose parry.” |
| **No “off balance” after whiff** | Missing or being deflected could leave you more exposed for a moment; we only model longer recovery time. |
| **Gauge is only “when can I act”** | Gauge doesn’t represent posture (e.g. “I’m 80% ready to act and 50% ready to defend”). |

---

## 3. Ways to use state machines and parry for more realism

Below are concrete options. Each can be implemented alone or combined.

---

### 3.1 Guard / readiness state (sub-state or modifier in WAITING)

**Idea:** While in `STATE_WAITING`, the combatant has a **guard level** or **readiness** that affects passive parry and possibly dodge.

- **How:** Add a field, e.g. `guard: float` (0–1) or an enum `READY_LOW / READY_HIGH / NOT_READY`. It only matters in WAITING (and maybe early RECOVERING).
- **Effect:**  
  - **Passive parry:** Multiply parry capacity or “time to react” by a function of guard (e.g. high guard → faster reaction or higher capacity).  
  - **Dodge:** Optionally same (high guard = more balanced = better dodge).  
  - **Gauge fill:** Optionally slightly slower when “high guard” (you’re prioritizing defense over stepping in to attack).
- **Realism:** Matches “blade in guard = quicker block”; “blade down” = slower to get into parry.
- **Implementation:** No new top-level state; extend the WAITING (and optionally RECOVERING) data with guard. When they choose “attack,” guard could drop or reset; when they choose “parry” or do nothing, guard could rise over time (or stay high if they didn’t attack last).

---

### 3.2 Recovery phases (early vs late recovery)

**Idea:** Split `STATE_RECOVERING` into **early** and **late** (or use a 0–1 progress) and tie it to defense and/or interruptibility.

- **How:**  
  - Keep one `STATE_RECOVERING` but add `recovery_phase: String` ("early" / "late") or use `state_timer / state_duration` (e.g. &lt; 0.5 = early).  
  - Or add `STATE_RECOVERING_EARLY` and `STATE_RECOVERING_LATE` and transition when timer crosses a threshold.
- **Effect:**  
  - **Passive parry:** In early recovery, apply a penalty: e.g. reaction_time × 1.5, or capacity_mult × 0.6. In late recovery, no penalty (or small bonus as “getting set again”).  
  - **Optional:** Being hit in early recovery could cause “off balance” (extra recovery or worse next parry).
- **Realism:** Right after a whiff or heavy block you’re more vulnerable; as you recover posture you’re readier to parry again.
- **Implementation:** In `_execute_attack`, when resolving passive parry for a defender in RECOVERING, read their `state_timer` and `state_duration` and apply a recovery-phase modifier to reaction time or parry capacity.

---

### 3.3 Commitment window during attack wind-up

**Idea:** The first fraction of attack wind-up is “telegraph / commitment”; after that, the attacker is fully committed and the defender’s reaction matters more.

- **How:**  
  - Store `wind_up_duration` (already done). Define `COMMITMENT_FRACTION` (e.g. 0.2). For the first 20% of wind-up, the attack could be treated as “not yet committed” (e.g. defender’s passive parry uses full wind_up_duration for time_to_react, or attacker could “abort” in some designs).  
  - Or: only after commitment fraction does the attack “count” as a real strike for the defender’s reaction (so reaction_time is compared to `wind_up_duration * (1 - COMMITMENT_FRACTION)`).
- **Effect:**  
  - Slightly more time for defender to “see it coming” (effective wind-up for reaction is shorter), or a small window where the attacker could cancel (if you add that mechanic).  
- **Realism:** Matches “telegraph” before full commitment; fast attacks are still hard to react to because total time is short.
- **Implementation:** When computing passive parry, use `effective_wind_up = wind_up_duration * (1.0 - COMMITMENT_FRACTION)` for the reaction_time comparison, or scale time_to_react by that.

---

### 3.4 State-dependent passive parry (readiness multiplier)

**Idea:** Passive parry effectiveness depends on **current state** and optionally **recovery progress**, not only on perception and time_to_react.

- **How:** Define a **readiness multiplier** per state (and optionally per recovery phase):  
  - `STATE_WAITING`: 1.0 (or 1.0 × guard if you add guard).  
  - `STATE_RECOVERING`: 0.5 in early half, 0.85 in late half (example).  
  - `STATE_WIND_UP`, `STATE_MEDICAL_WIND_UP`: 0 (already done).  
  - `STATE_PARRY_WIND_UP`: N/A (active parry in progress).  
  Multiply parry capacity (or reaction_time, or notice chance) by this readiness.
- **Effect:** Same A4v3 formula, but “in recovery” or “early recovery” makes passive parry weaker without adding new states.
- **Realism:** You’re worse at reacting when you’re mid-swing or just finished one; better when you’re standing ready.
- **Implementation:** In the passive parry block, compute `readiness = _get_passive_parry_readiness(tgt)` and multiply `c_d` or scale `reaction_time` (e.g. reaction_time /= readiness so low readiness = slower reaction).

---

### 3.5 “Off balance” after miss or heavy deflect

**Idea:** After a **miss** or a **full parry (deflect)**, the attacker is “off balance” for a short time: longer or worse recovery, and/or worse passive parry if they’re attacked before they recover.

- **How:**  
  - When the attacker goes to RECOVERING after a **miss** or **parry_deflect**, set a flag or timer, e.g. `off_balance_until: float` (game time) or `off_balance_duration_s: float`.  
  - While `off_balance` is true, if they are attacked, their **own** passive parry (if they’re the defender) is penalized (e.g. reaction time × 1.3, or capacity × 0.7).  
  - Or: extend their next recovery by a small amount.
- **Effect:** Whiffing or being fully parried leaves you briefly more vulnerable; encourages commitment and accuracy.
- **Realism:** Matches “recovering from a big miss” or “having your blow deflected” leaving you open.
- **Implementation:** In the place where you set `atk.state = STATE_RECOVERING` after miss or parry_deflect, set a combatant field `off_balance_until = game_time + OFF_BALANCE_DURATION`. In passive parry, when the defender has `off_balance_until > game_time`, apply a penalty to their parry.

---

### 3.6 Defensive stance (choice that trades gauge for parry)

**Idea:** Add an explicit “defensive stance” that combatants can choose instead of attacking: gauge fills more slowly (or doesn’t fill) but passive parry (and maybe dodge) is stronger.

- **How:**  
  - New (optional) action: “assume guard” / “defensive stance.” When chosen, combatant stays in WAITING but sets a flag `defensive_stance: bool = true` and optionally a timer.  
  - While in defensive stance: gauge fill rate × 0.5 (or 0); passive parry capacity × 1.2 and/or reaction_time × 0.9.  
  - Stance ends when they choose attack/parry/medical, or after a duration, or when they’re hit.
- **Effect:** “I’m not attacking this turn, I’m getting ready to block” → better defense, slower offense.
- **Realism:** Matches prioritizing guard and watching the opponent; you’re harder to hit but you don’t press the attack.
- **Implementation:** New action in `get_available_actions` (e.g. “guard” or “defensive_stance”); in `resolve_action` set a combatant field; in gauge fill and passive parry read that field and apply modifiers.

---

### 3.7 Parry success leaves defender in “ready” state

**Idea:** After a **successful** passive or active parry (full deflect), the defender is in a good position: treat the next moment as “ready” so their next passive parry (or dodge) is slightly better, or their gauge fills a bit faster for one tick.

- **How:** When resolving a full parry (deflect), set a short-lived flag on the defender, e.g. `parry_ready_bonus_until = game_time + 0.3`. While that’s set, their next passive parry capacity × 1.1 or reaction_time × 0.95.
- **Effect:** Successfully parrying rewards you with a brief “in the zone” window instead of only putting the attacker in recovery.
- **Realism:** A clean parry often leaves you in guard and ready for the next action; the attacker is the one off balance.
- **Implementation:** In `_resolve_parry_with_momentum` when `deflected` is true, set a field on the defender (if you have a combatant dict or node that persists); in passive parry (and optionally dodge) check that field and apply a small bonus.

---

### 3.8 Interruptibility: abort attack early in wind-up

**Idea:** During the first X% of attack wind-up, the attacker can “abort” and go to a short recovery instead of completing the strike (e.g. they see the defender’s parry in place and don’t commit).

- **How:**  
  - Add a notion of “abort window”: e.g. first 15% of `state_duration` in STATE_WIND_UP.  
  - If the player (or AI) chooses “abort” in that window, transition to STATE_RECOVERING with a **short** recovery (e.g. 0.3 s) instead of completing the attack.  
  - No impact, no parry; attacker just recovers.
- **Effect:** Adds a tactical layer: commit or pull back. Defender might feint to force an abort.
- **Realism:** Matches “pulling a strike” when you see the block too early.
- **Implementation:** Only meaningful if the player (or AI) can issue an “abort” command during wind-up; requires UI/input and a check of `state_timer / state_duration < ABORT_FRACTION`.

---

## 4. Summary table

| Option | New state? | Complexity | Realism gain | Best combined with |
|--------|------------|------------|--------------|--------------------|
| **3.1 Guard / readiness** | No (field in WAITING) | Low | High (guard vs no guard) | 3.4 |
| **3.2 Recovery phases** | Optional (early/late) | Low–mid | High (vulnerable after action) | 3.4, 3.5 |
| **3.3 Commitment window** | No | Low | Mid (telegraph) | — |
| **3.4 State-dependent passive parry** | No | Low | High (state = readiness) | 3.1, 3.2 |
| **3.5 Off balance after miss/parry** | No (flag/timer) | Low | High (whiff/deflect cost) | 3.2 |
| **3.6 Defensive stance** | No (action + flag) | Mid | High (trade offense for defense) | 3.1 |
| **3.7 Parry success bonus** | No (flag) | Low | Mid (reward good parry) | — |
| **3.8 Abort attack** | No | Mid (needs input) | Mid (pull strike) | 3.3 |

---

## 5. Recommended order

1. **3.4 State-dependent passive parry** — Use current states (and optionally recovery progress) to scale passive parry. No new states; immediate gain (recovering = worse parry, waiting = full).
2. **3.2 Recovery phases** — Use `state_timer`/`state_duration` in RECOVERING to apply early/late modifiers to passive parry (and later to 3.5).
3. **3.5 Off balance** — After miss or parry_deflect, set a short “off balance” window and penalize the attacker’s defense if they’re hit in that window.
4. **3.1 Guard / readiness** — Add a guard level in WAITING (and optionally in late recovery) and feed it into passive parry and optionally dodge.
5. **3.6 Defensive stance** — Optional action “hold guard” that slows gauge fill and improves parry/dodge.

Implementing 3.4 and 3.2 gives a clear “state machine + parry” realism boost with minimal new machinery; the rest can be added incrementally.
