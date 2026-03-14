# HEMA Zones, Attack Paths, Flurries & Feints: Adaptation Investigation

Investigation into how HEMA zone systems, weapon positioning, attack paths, and engagements (flurries, parries, feints) can be adapted for Fallen Paths' abstract combat system.

---

## 1. Your Current System: Quick Reference

| Element | Fallen Paths | Notes |
|--------|--------------|-------|
| **Body parts** | 6: head, chest, left_arm, right_arm, left_leg, right_leg | BodyPartConstants; sub-regions per part |
| **Target selection** | `target_part` optional in actions; weighted random when absent | AI picks (target_id, move_id); target_part from choice or BodyPartConstants.get_weighted_random_part |
| **Guard** | Scalar (0.4 when attacking, rises when idle) | Zone-agnostic; readiness × guard = parry capacity |
| **Attack types** | cut/thrust/blunt; archetypes (oberhau, slash, stab, etc.) | move_id → archetype_id → velocity_factor, recovery_mult |
| **Defense** | Parry (capacity vs momentum), dodge, deflection | Parry_deflect, parry_partial, miss, dodge |
| **Timing** | Wind-up → execute → recovery; gauge-based readiness | Mental stack layers; _is_being_targeted |
| **Engagement** | None (soft engagement in MENTAL_STACK doc) | Could add engaged_with_id |

---

## 2. HEMA Zone Systems: Overview

### 2.1 Liechtenauer / German Longsword

**Four lines / Vier Leger (four guards):**

- **Ochs** (Ox) — upper thrusting guard; point high
- **Pflug** (Plow) — lower thrusting guard
- **Alber** (Fool) — low, exposed
- **Vom Tag** (Day/Roof) — high, blade above head

Guards cover **high, low, left, right**. Parries use the same strikes (Oberhau, Unterhau) that end in these guards—Oberhau ends in Plough, Unterhau ends in Ox. Attack paths are not arbitrary: cuts flow through guards (e.g., high cut passes Tag → Longpoint → Fool).

### 2.2 Meyer

**Body divisions:** Four quarters (upper/lower left and right). Head subdivided into **four zones** for precise close-range targeting.

**Guards:** Same four primary (Ochs, Pflug, Tag, Alber) plus secondary (Zornhut, Langort, etc.). Key insight: **guards are transitional, not static**—a cut flows through multiple guards. E.g., Oberhau: Tag → Longpoint → Alber.

**Cuts as attack paths:**
- **Straight cuts:** Oberhau (high), Zornhau (diagonal), Mittelhau (horizontal), Unterhau (low)
- **Inverted cuts:** Schielhau, Krumphau, Zwerch, etc.

Each cut has an implied **path** and **target zone**. Zornhau: shoulder → opponent's left (head/face/chest). Unterhau: from below → opponent's arm/head.

### 2.3 Italian Rapier / Bolognese

**Lines:** Inside (between fencers), Outside (toward opponent's outside). High/low as well. Directional terms: *dritto* (right), *riverso* (left).

**Feint:** Threaten one line to draw parry, then disengage to hit another. Single-tempo action; feint is a *cavazione* (disengage) that baits a response.

### 2.4 Kingdom Come: Deliverance (game)

5 zones: head, left upper, right upper, left lower, right lower. Chest merged into upper. Directional block must match attack direction.

---

## 3. Zone Mapping: HEMA → Fallen Paths

### 3.1 Direct Mapping

| HEMA / Source | Zones | Fallen Paths Equiv | Notes |
|---------------|-------|--------------------|-------|
| Liechtenauer | High, low, left, right (4 lines) | — | Lines, not body parts; map to **attack direction** |
| Meyer | 4 quarters + 4 head zones | 6 parts cover this | quarters ≈ chest + arms + legs; head 4 zones → head |
| KCD | 5 (head, L/R upper, L/R lower) | 6 parts | Add chest; L upper ≈ left_arm (+chest left); R upper ≈ right_arm |
| Italian | Inside / outside | — | More about blade position; less direct body mapping |

### 3.2 Attack Path as (from_guard, to_part) or (cut_type, target_part)

**Option A: Cut type implies path**
- Oberhau → typically head, maybe chest (high line)
- Unterhau → legs or low arm (rising)
- Zornhau → diagonal: right shoulder → left_head, left_arm, chest
- Mittelhau → horizontal: left_arm, right_arm, chest

You already have move_ids (oberhau, unterhau, slash). Each could have an optional `preferred_parts: Array` or `path_zones: Array` to bias target selection. No new UI—mental stack scores by "cut suits part."

**Option B: Explicit attack path (from_zone, to_zone)**
- Stored as `attack_path: { "from": "high_right", "to": "head" }`
- Defender's guard_zone can counter specific paths. E.g., guard "high_right" defends against attacks from that line.
- More granular but more state.

**Option C: Zone-specific guard (recommended minimum)**
- Per KINGDOM_COME_ABSTRACT_REPLICATION: `guard_zone: String` = one of your 6 parts.
- Attack to guarded part → parry easier (or mandatory). Attack to unguarded → normal resolution.
- Fits Liechtenauer "Oberhau parries Oberhau" — same-line parry; different line = hit. Your "line" = body part.

---

## 4. Adapting Zones for Your System

### 4.1 Minimal: Target Part + Cut Compatibility

Add to move/archetype data:
```gdscript
# In WeaponConstants or per-move
# preferred_parts: parts this cut naturally targets (optional; for AI scoring)
oberhau: { ..., preferred_parts: ["head", "chest"] }   # high line
unterhau: { ..., preferred_parts: ["left_arm", "right_arm", "left_leg", "right_leg"] }  # rising
slash: { ..., preferred_parts: ["left_arm", "right_arm", "chest"] }  # horizontal
thrust: { ..., preferred_parts: ["head", "chest", "left_arm", "right_arm"] }  # point threatens center
```

Mental stack layer 6 (attack): when scoring (target_id, move_id, target_part), add `cut_match_bonus` if target_part in preferred_parts. No guard yet; just better target selection.

### 4.2 Low: Zone-Specific Guard

Add `guard_zone: String` per combatant (see KINGDOM_COME_ABSTRACT_REPLICATION §2.2).

- When attacking part P: if defender.guard_zone == P → parry capacity × 1.5 (or block mandatory).
- Else: normal parry.
- Defender chooses guard each "turn" or when entering WAITING. AI: guard the part they expect to be attacked (from telegraph or threat).

### 4.3 Medium: Guard + Attack Path Modifier

- Guard covers one part. Attack has `path` or `line` (high/low/inside/outside).
- If attack line matches defender's guard "line" (e.g., both high) → parry bonus even if exact part differs. Requires mapping parts to lines:
  - High: head
  - Mid: chest, arms
  - Low: legs

Then: `guard_line: "high"` defends head well, and partially chest. Simpler than 6-part guard.

### 4.4 High: Full Meyer-Style Flow

- Track `last_guard` or `weapon_position` per combatant. Cuts transition through guards.
- Next attack's wind-up or recovery depends on previous guard. E.g., Oberhau ends in Plough → next move from Plough is faster than from Alber.
- Most complex; probably overkill for abstract system unless you want deep simulation.

**Recommendation:** Start with 4.1 (cut–part compatibility) and 4.2 (zone guard). Gives zone feel without heavy implementation.

---

## 5. HEMA Engagements: Flurries, Parries, Feints

### 5.1 What the Documents Describe

**Tempo:** Every action commits the fencer for a moment. Reversing requires another action. Exploit commitment windows.

**Parry–riposte chains:** Parry → immediate counter. Liechtenauer: parry with Zornhau, end in Plough, thrust. Sweeping parries deflect diagonally. Absetzen = thrusting parry (counter-attack as parry).

**Feints:** Threaten one target/line to draw parry; disengage; hit the other. Giganti: feint is a cavazione that baits response. Single-tempo effective action.

**Flurries / rapid exchanges:**
- HEMA tournaments: 70–90% of exchanges end in *some* hit (clean, afterblow, or double).
- Double hits: both land ~7–40% depending on ruleset.
- Afterblow: hit after initial strike; discourages suicidal commitment.
- Binding: blades in contact; next action is bind resolution (wind, thrust from bind, etc.).

**Liechtenauer "Before" and "After":** Seize initiative ("Before") or take it back ("After"). Not turn-based—continuous flow.

### 5.2 Translation to Fallen Paths

Your system is **discrete** (wind-up → execute → recovery, gauge-based). HEMA is **continuous**. Translation = capture the *feel* with state and timing rules.

#### 5.2.1 Parry–Riposte (You Have This)

- Parry_deflect → attacker in recovery, defender in WAITING.
- Perfect block / riposte: on parry_deflect, set `riposte_priority` on defender. Next tick, defender acts first or at reduced cost (see KINGDOM_COME doc).
- Master strike: parry_deflect in early wind-up → auto counter.

#### 5.2.2 Feints

**Feint as "threaten one part, hit another":**
- Commitment: attacker declares `feint_part` and `real_part` (or `feint_part` only; real = unguarded).
- Defender reacts to feint_part (guard or parry choice). If defender guarded feint_part, real_part is unguarded → attack to real_part gets bonus or guaranteed hit chance.
- Cost: feint could add slight wind-up (extra 0.1s) or gauge cost. Reward: bypass guard.

**Implementation options:**
- **A. Feint move type:** New move_id `feint_slash` with `feint_part`, `real_part`. Two-phase: wind-up shows feint, execute hits real. Defender must "read" or guard broadly.
- **B. Feint as target bait:** Attacker commits to target_part at wind-up start (telegraph). Defender can set guard_zone = that part. If attacker has feint: actual target_part ≠ telegraph. Defender guarded wrong part → parry penalty.
- **C. Probabilistic feint:** When choosing attack, X% chance to "feint" (attack different part than defender expects). Defender's reaction uses probabilistic guess. Simplest.

**HEMA consistency:** Feint = threaten line A, hit line B. Your lines = parts. So feint = (telegraph_part, actual_part) with telegraph_part ≠ actual_part.

#### 5.2.3 Flurries

**From MENTAL_STACK_ENGAGEMENT_INVESTIGATION:**

- **Option 1 (Soft Lock):** Engagement = `engaged_with_id`. No mechanical change; AI prefers attacking engaged target.
- **Option 2 (Counter Window):** When A winds up on B, B gets counter window—spend partial gauge for immediate counter.
- **Option 3 (Flurry Sub-Phase):** Multiple blows in quick succession (2–4) before reset.

**HEMA flurry feel:**
- Binding: parry_deflect could start a "bind" state. While bound, only bind-resolution moves (short thrust, push). Your system could add `bound_with_id`, `bound_until`, and restrict actions.
- Tempo exploitation: Enemy in recovery = high-value target. You already have "enemy in recovery" in mental stack. Enhance: recovery = soft "flurry opportunity" (next attack gets initiative bonus).
- Afterblow: When A hits B, B can land "afterblow" if B's action resolves within a short window. Implement: on hit, if B has pending_attack and it resolves before A's recovery ends, B's hit counts (possibly reduced damage). Discourages reckless commitment.

#### 5.2.4 Double Hits

HEMA: 7–40% doubles. Your system: one attack resolves at a time. To approximate:
- When A and B both have pending attacks and are targeting each other: resolve in initiative order. If both "hit" in same exchange, you could apply both damages (double hit) or first hit "wins" and second is cancelled/partial.
- Simpler: keep single-resolution; doubles emerge from rapid back-and-forth (flurry option 3) where both land hits in sequence.

---

## 6. Feint Implementation Sketch

### 6.1 Data

```gdscript
# Extend action
action = {
  "target_id": 2,
  "move_id": "slash",
  "target_part": "head",        # real target
  "feint_part": "chest"         # optional; telegraph/feint target
}
```

### 6.2 Flow

1. **Wind-up start:** Attacker commits. Defender sees telegraph: `feint_part` if present, else `target_part`.
2. **Defender reaction:** Chooses parry or guard_zone. If guard_zone == feint_part and target_part != feint_part → defender guarded the wrong part.
3. **Execute:** Parry capacity vs momentum. If defender guarded wrong part (and no universal guard), parry capacity × 0.5 or similar.
4. **Cost:** Feint could use `windup_multiplier` 1.1 (slightly longer) or extra gauge.

### 6.3 AI: When to Feint

- If defender has high parry_rate or frequently guards our preferred target: feint to draw guard, hit elsewhere.
- Mental stack / yomi: track `defender_guard_tendency`. If they often guard head when we attack head, feint head → hit chest.
- Feint requires `target_part` and `feint_part` to be chosen; adds to action space.

---

## 7. Flurry Implementation Sketch

### 7.1 Counter Window (Option 2)

- When A enters WIND_UP targeting B, set `B.counter_window_until = now + A.wind_up_duration * 0.8` (or until execute).
- If B's gauge >= 50% during this window and B chooses "counter" (parry or counter-attack): B spends 50% gauge, gets immediate action that resolves *before* A's attack. Order: B's counter resolves first, then A's (if A still alive).
- Creates parry–riposte and "seize tempo" feel.

### 7.2 Flurry Sub-Phase (Option 3)

- When A attacks B and both survive: enter `STATE_IN_FLURRY` with `flurry_remaining = 3`.
- Resolve A's attack. If B can respond (gauge, alive): B gets instant counter (no full wind-up, reduced wind-up or 0). Resolve B's. If A can respond: A gets instant counter. Repeat until flurry_remaining == 0 or one dies.
- Disengagement: both RECOVERING; flurry ends.

### 7.3 Afterblow

- On hit: target gets `afterblow_window` until attacker's recovery ends.
- If target has pending attack that would have resolved in that window: allow it to resolve as "afterblow" (maybe 50% damage to reflect desperate counter). Attacker takes damage.
- Reduces "all-in" commitment; matches HEMA ruleset feel.

---

## 8. Summary: Adaptation Priorities

| HEMA Concept | Adaptation | Complexity | Value |
|--------------|------------|------------|-------|
| **Zones / body divisions** | 6 parts already match. Add preferred_parts per cut. | Low | Medium |
| **Zone-specific guard** | guard_zone: String; parry bonus when guarded. | Low | High |
| **Attack path** | preferred_parts per move; optional path modifier. | Low | Low–Medium |
| **Parry–riposte** | riposte_priority on parry_deflect. | Low | High |
| **Master strike** | Early parry_deflect → auto counter. | Low | Medium |
| **Feint** | feint_part ≠ target_part; defender guards wrong part. | Medium | High |
| **Counter window** | Partial gauge for counter during enemy wind-up. | Medium | High |
| **Flurry sub-phase** | Multiple exchanges before reset. | High | Medium |
| **Afterblow** | Hit during attacker recovery = partial counter damage. | Medium | Medium |
| **Binding** | bound state, restricted moves. | High | Low (niche) |

### Recommended Implementation Order

1. **Zone guard** (guard_zone + parry modifier) — highest impact for zone feel.
2. **Riposte priority** — you've designed it; implement.
3. **Cut–part compatibility** (preferred_parts) — improves AI targeting.
4. **Feint** (telegraph vs real target) — adds mind-games.
5. **Counter window** — enables tempo play.
6. **Afterblow** (optional) — if you want HEMA-ruleset feel.
7. **Flurry sub-phase** (optional) — if you want dramatic exchanges.

---

## 9. Implementation Approaches: Realism & HEMA Accuracy Comparison

A detailed comparison of implementation options for each system, evaluated against historical sources and HEMA practice.

---

### 9.1 Zone / Guard Systems

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Scalar guard only** | Current: single 0–1 guard value, no zones | Low | Low | Simple; already implemented | Ignores Liechtenauer/Meyer: guards cover specific lines. Historical sources say "Oberhau parries Oberhau" — same line. |
| **B. Single zone guard** | `guard_zone: String` = one of 6 parts; attack to guarded part → parry bonus | **Medium** | **Medium–High** | Matches KCD, Liechtenauer line concept. One part defended = others exposed. Simple. | Crude: real guards cover *lines* (high/low/left/right), not just single body parts. Meyer: guards are transitional. |
| **C. Line-based guard** | `guard_line: "high"|"low"|"inside"|"outside"`; parts mapped to lines; line match → parry | **High** | **High** | Matches Liechtenauer 4 guards, Italian inside/outside. "High" covers head; "low" covers legs. | More abstraction: lines ≠ exact anatomy. Need part→line mapping. |
| **D. Multi-zone guard** | `guard_zones: Array` = 2–3 parts defended (e.g. high guard = head + chest) | **Medium–High** | **Medium** | Reflects that guards cover *regions*. Alber exposes more than Ochs. | More state; balance: too many zones = universal guard. Historical: guards typically cover one "line" well. |
| **E. Guard as weapon position** | Track `last_guard` / `weapon_position`; next move's cost/speed from current position | **Highest** | **Highest** | Meyer: guards are transitional. Cut from Tag → Plough; next from Plough is faster. Full flow. | Complex; requires guard transitions, path-dependent moves. Probably overkill for abstract. |

**Verdict:** **B** or **C** offer best realism/code balance. C is more faithful to Liechtenauer (4 lines); B maps cleanly to your 6 parts. Historical: guards defended *lines*, not single points. **C** slightly more accurate; **B** easier to implement and explain.

---

### 9.2 Attack Paths & Target Selection

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Weighted random** | Current: target_part from BODY_PART_TARGET_WEIGHTS when unspecified | Low | Low | Simple | Ignores cut geometry. Oberhau naturally goes to head; Unterhau to legs. Archaeological: head 40–92% of wounds; torso often 0–2%; arms low in battle, high in duel. |
| **B. preferred_parts per move** | Each move has `preferred_parts`; AI scores these higher | **Medium** | **Medium** | Cut type implies path. Oberhau → head; thrust → center. No new resolution rules. | Static; doesn't account for defender's guard. Historical: provoke to create opening, then strike. |
| **C. preferred_parts + guard interaction** | preferred_parts + guard_zone; unguarded preferred = bonus | **High** | **High** | Combines geometry and defender state. "Unguarded head" when in high guard = exploit. | Requires zone guard (9.1). |
| **D. Historical target weights** | Override weights by context: duel vs battle. Head heavy; torso thrust>cut; arms high in 1v1 | **High** | **High** | Sword STEM / Matzke: head dominant; torso cuts rare archaeologically; arms sniped in duels (patience, space). | Context flag (duel/battle) or environment. Battlefield: legs (Wisby 65% with shields), head. Duel: arms, head. |

**Verdict:** **C** for tactical play. **D** if you want archaeological/historical nuance (different scenarios). Your BODY_PART_TARGET_WEIGHTS already have head 1.2, chest 2.7 — consider *lowering* torso weight for cuts in duels to match sources (thrust torso, cut head/limbs).

---

### 9.3 Feints

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. No feint** | Only real attacks; no deception | Low | Low | Simple | Italian sources: feint is central. Giganti: *cavazione* baits parry. No mind-games. |
| **B. Feint as telegraph vs real** | `feint_part` ≠ `target_part`; defender sees feint; guards wrong part → parry penalty | **High** | **High** | Matches Giganti/Capo Ferro: threaten line A, disengage to B. Single-tempo action. Defender must read or guard broadly. | Two-phase commitment; defender reaction logic. Cost: feint should have slight wind-up (proportionally smaller than defender's parry motion — Fabris). |
| **C. Probabilistic feint** | X% chance actual target ≠ expected; defender guesses | **Medium** | **Medium** | Simple; no explicit feint_part. Emergent deception. | Not a committed feint — attacker doesn't "threaten" then redirect. Historical: feint is intentional provocation. |
| **D. Feint as provocation** | Feint = small motion to force defender to create tempo; then attack in that tempo | **Highest** | **Highest** | Dall'Agocchie: "Provocations... incite him to strike, so that one can attack him more safely." Your tempo = defender's parry attempt; you attack *during* it. | Complex: provocation phase, tempo window. Requires "attack during opponent's action" — counter window (9.5). |

**Verdict:** **B** is the best balance. **D** is most faithful to Dall'Agocchie but needs counter-window infrastructure. Feint cost: Fabris says your attack must be "proportionally shorter" than defender's response — implement as feint adding ~10% wind-up, but wrong guard = large parry penalty (e.g. ×0.5).

---

### 9.4 Parry–Riposte & Master Strike

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Parry only** | parry_deflect → attacker recovery; defender stays WAITING | **Medium** | **Medium** | You have this. Defender survives. | Misses riposte. Liechtenauer: parry with Zornhau, end in Plough, thrust. Absetzen = parry *is* counter. |
| **B. Riposte priority** | parry_deflect → `riposte_priority`; defender acts first next tick | **High** | **High** | Matches "after parrying, then it's a tempo to attack" (Dall'Agocchie #5). Low implementation cost. | Slight delay (next tick). Historical: riposte can be same-tempo (dui tempi vs stesso tempo). |
| **C. Master strike (early parry)** | parry_deflect in early wind-up (<30%) → auto counter before attacker executes | **High** | **High** | KCD master strike. Liechtenauer: catch attack early = control. Mechanically: guaranteed counter. | Can feel overpowered; tune early % threshold. |
| **D. Absetzen (thrust-parry)** | Parry with thrust; no separate parry→riposte, attack *is* defense | **Highest** | **Highest** | Liechtenauer: Absetzen from Plough. Single action. | Needs "parry-thrust" as one move. You have parry_thrust; ensure it can trigger on incoming attack. |

**Verdict:** **B** + **C** both worth adding. **D** is already partially there (parry_thrust) — ensure it's selectable when defender is targeted and gets counter-attack resolution. Riposte = initiative; master strike = early-read reward.

---

### 9.5 Tempo & Counter Windows (Dall'Agocchie's Five Tempi)

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. No counter window** | Only act when gauge full; no interrupt | Low | Low | Current behavior. | Ignores "when he raises his sword... strike while his hand is rising" (#3). Or "when he raises his foot" (#5). Opponent committed = your opportunity. |
| **B. Counter window (partial gauge)** | During enemy wind-up, spend 50% gauge → immediate action, resolves first | **High** | **High** | Captures tempo #3 (hand raising), #4 (guard change), #5 (foot lift). "Time employed to make one movement cannot be employed to make any other" (Fabris). | Order of operations: counter resolves before attack. Attacker may "lose" to counter. Balance: cost (50% gauge), only when wind-up active. |
| **C. Counter + feint synergy** | Feint triggers defender parry (tempo); counter window allows attacker to hit during that parry | **Highest** | **Highest** | Dall'Agocchie provocation: feint creates tempo, attack in it. Defender's parry = commitment; you strike during. | Requires both feint (9.3) and counter window. Complex. |
| **D. Five tempi as discrete triggers** | Explicit check: is opponent (a) in wind-up, (b) changing guard, (c) stepping, (d) post-parry, (e) blow passed? Each = opportunity | **Highest** | **Highest** | Most faithful to Dall'Agocchie. | Five conditions to track; guard/step state may not exist. Granular but heavy. |

**Verdict:** **B** captures the core: "opponent committed = your opportunity." **D** is ideal for maximum accuracy but likely overkill. Implement **B**; optionally, *scale* counter cost by which "tempo" applies (e.g. wind-up = 50%, guard change = 40% if you add guard state).

---

### 9.6 Flurries, Binding, Afterblow

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Single attack resolution** | Current: one attack → resolve → recovery | **Medium** | **Medium** | Simple. Matches "single decisive blow" in some chronicles. | Misses rapid exchanges. HEMA: 70–90% of exchanges end in *some* hit. Archaeological: multiple wounds common. |
| **B. Soft engagement** | `engaged_with_id`; AI preference only; no mechanical change | Low | Low | Minimal. | No flurry feel. Engagement is cosmetic. |
| **C. Counter window only** | B from 9.5; enables back-and-forth when both have gauge | **High** | **High** | Tempo-driven exchanges. No new phase. Both can counter in sequence. | Emergent flurry from repeated counter windows. May need cap (max 2 counters per "exchange") to avoid infinite. |
| **D. Flurry sub-phase** | 2–4 blows in quick succession; reduced wind-up; then reset | **Medium–High** | **Medium** | Dramatic. Matches "multiple wounds" from archaeology. | Ernst Fechten / Liechtenauer: at *close* measure in krieg, quick successive thrusts from bind. At *wide* measure, flurries fail — opponent counters. Your abstract system has no measure; flurry could feel arbitrary. |
| **E. Afterblow** | On hit, target's pending attack can resolve during attacker recovery (e.g. 50% dmg) | **High** | **High** | HEMA rulesets use this to discourage suicidal commitment. Historical: "strike only to be hit shortly thereafter" = failure (Ernst Fechten). | Implement as: if target has attack in progress when hit, it resolves as afterblow. Tune damage (50%? 100%?). |
| **F. Binding state** | parry_deflect → `bound_with_id`; while bound, only bind-resolution moves (thrust, wind) | **Highest** | **Highest** | Liechtenauer krieg: blades in contact; winden, thrust from bind. Close measure critical (30–45 cm). | New state, restricted move set. Ernst Fechten: at *wrong* measure, bind techniques fail. Your system has no distance. Complex. |

**Verdict:**
- **Flurry:** **C** (counter window) gives emergent exchanges; **D** (sub-phase) is optional for dramatic set-pieces. Historical: flurries work at *close* measure; your abstract model may not support measure, so **D** is a stylistic choice.
- **Afterblow:** **E** — strongly recommended. Aligns with HEMA and historical sentiment ("don't get hit back").
- **Binding:** **F** is most accurate for Liechtenauer krieg but requires measure (distance) and new moves. Skip unless you add spatial measure.

---

### 9.7 Measure (Distance) — Not Currently Modeled

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. No measure** | Current: abstract; no distance | **Low** | **Low** | Simple. | Historical: measure is *fundamental*. Close/mid/long/out. "Attack in measure if it can land in one tempo." Bind at ~30–40 cm. At wide measure, everything can be countered (Ernst Fechten). |
| **B. Implicit measure** | "In range" = engaged; "out of range" = not targeting | **Low** | **Low** | Binary. | Crude. No "close vs wide" bind. |
| **C. Measure bands** | Close / mid / long; different parry/counter efficacy by band | **High** | **High** | Bind at close = thrust from bind works. Wide = parry easier, counter harder. | Requires distance state. How is it set? Adjacent tiles? Abstract "steps to opponent"? |
| **D. Tempo-as-measure** | "In measure" = can hit in one tempo (one wind-up). "Out" = need to close first | **Medium** | **Medium** | Abstract: no spatial distance. "Closing" = action that enables attack. | Conflates distance and readiness. Possible for abstract system. |

**Verdict:** Your system is abstract (no tiles/physics). **D** (tempo-as-measure) could work: "approach" action that reduces next-attack wind-up, or "out of measure" = must spend a "close" action first. **C** would need a distance abstraction (e.g. steps_to_opponent 0–3). **A** is acceptable if you accept that measure is implicit in "who can act when" (gauge, recovery).

---

### 9.8 Summary: Realism-Optimized Implementation Path

| Priority | Feature | Best Approach | Realism | Notes |
|----------|---------|---------------|---------|-------|
| 1 | Zone guard | B (single part) or C (line) | High | Line-based slightly more accurate. |
| 2 | Riposte priority | B | High | parry_deflect → next-tick initiative. |
| 3 | Master strike | C | High | Early parry → auto counter. |
| 4 | Target selection | C (preferred_parts + guard) | High | Head priority; cut–part match; unguarded bonus. |
| 5 | Feint | B (telegraph vs real) | High | feint_part, cost ~10% wind-up. |
| 6 | Counter window | B | High | 50% gauge during enemy wind-up. |
| 7 | Afterblow | E | High | Pending attack during hit = resolves at reduced damage. |
| 8 | Historical weights | D (optional) | High | Duel vs battle: head/arms vs head/legs. |
| 9 | Flurry sub-phase | D (optional) | Medium | Stylistic; measure not modeled. |
| 10 | Binding | F (defer) | Highest | Requires measure; new moves. |
| 11 | Measure | D (tempo-as) or C (bands) | High | Only if adding spatial/distance. |

**Trade-off:** Full Liechtenauer fidelity (measure, bind, winden) would require significant new systems. The path above captures the *tactical* and *temporal* essence (tempo, riposte, feint, counter, afterblow, zone guard) without spatial simulation. Archaeological and historical sources support: head focus, thrust-to-torso preference, arm sniping in duels, and "don't get hit back" (afterblow mindset). Your system can approximate all of these with the approaches in this section.

---

## References

- **HEMA_VS_KCD_SOURCE_ANALYSIS.md** — Separates historical longsword sources from KCD game design; use for physical realism prioritization.
- **LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md** — Line-based guard options, simulated vs 3D limitations, physically realistic afterblow model.
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md
- MELEE_SIMULATION_AI_INVESTIGATION.md
- COMBAT_PARRY_MISS_RESEARCH.md
- Meyer's longsword 101 (HEMA 101): Openings, guards, cuts
- Liechtenauer's longsword 101 - Part 5: Parries
- Italian rapier: lines, feints, disengages (Giganti, Capo Ferro)
- HEMA tempo, doubles, afterblows (Sword STEM, Thokk Research)
- BodyPartConstants.gd, CombatManager.gd, AttackResolver.gd
