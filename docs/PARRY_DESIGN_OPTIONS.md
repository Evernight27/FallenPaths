# Parry Design: Active vs Passive vs Other Options

You already have **passive dodge** (perception/agility/legs/pain) and **active parry** (choose parry when someone is winding up; wind-up race; capacity vs momentum). This doc lays out options if you rework parries toward a passive or hybrid model.

---

## Current system (active parry)

- **When:** Defender is in `STATE_WAITING`, gauge full, and someone is winding up on them.
- **Choice:** Parry appears with weight 5 vs 1 for attacks (and medical when in danger). Defender explicitly picks parry or something else.
- **Execution:** Defender enters `STATE_PARRY_WIND_UP` (reaction time + blade movement, scaled by weapon mass/strength, pain/consciousness). At impact, parry progress and capacity vs attack momentum determine full deflect vs partial hit.
- **Trade-off:** Choosing parry costs your “turn” (no attack, no medical). Strong and intentional.

---

## Option A: Full passive parry (perception/state, no choice)

**Idea:** Remove parry as an action. When an attack is about to land, roll a **parry chance** = f(perception, weapon readiness, legs, pain, consciousness). If success, resolve as now (capacity vs momentum) or a simplified version. Defender never “chooses” parry.

**Pros:**

- Matches “I reacted and got my blade in the way” without spending an action.
- HEMA suggests many contacts are parries; passive can get you toward that rate without defenders constantly choosing “parry.”
- Same stat family as dodge (perception, state) — consistent.

**Cons:**

- No meaningful choice: defender can’t “commit to defending.” May feel arbitrary.
- Action economy: if they’re attacking, do they still get a passive parry? Usually you’d say no (or heavy penalty) when in wind_up, so passive parry only when **not** committed (e.g. in `STATE_WAITING` or recovering). Then “someone attacks you while you’re waiting” is the only case — which is exactly when you currently *can* choose parry. So you’re replacing “I choose parry” with “RNG says you parried,” which can feel less tactical.
- Risk of “always defend a bit” if passive is strong, or “parry never matters” if weak.

**Verdict:** Viable if you want combat to feel more reactive and less “I picked parry this turn.” Best if you pair it with clear rules for when passive parry applies (e.g. only when defender is in a “ready” state, not winding up an attack or doing medical).

---

## Option B: Hybrid — keep active parry, add passive “reactive block”

**Idea:** Keep current active parry. **Additionally**, when the defender did **not** choose parry (e.g. they attacked or did medical) and an attack lands on them, roll a **reactive block** chance = f(perception, consciousness, weapon, pain). If it succeeds, apply a **weaker** effect than full parry: e.g. treat as deflected (armor soak) or reduce impact (partial parry with a cap).

**Pros:**

- Best of both: deliberate “I parry” plus “sometimes you get your blade in the way” when committing to something else.
- Perception/state matter even when the defender isn’t explicitly defending.
- You can tune: active parry = full capacity vs momentum; passive = e.g. 30% damage reduction or “count as deflected if armor would soak most.”

**Cons:**

- More rules and tuning (two layers of parry).
- Need to avoid passive making active parry pointless (passive should be clearly weaker or rarer when you *could* have parried).

**Verdict:** Strong option if you want both “I choose to parry” and “reaction based on perception/state” without removing the active choice.

---

## Option C: Reactive parry (choice stays, resolution is perception/state, no wind-up race)

**Idea:** Parry remains an **option** when someone is winding up on you, but instead of a **wind-up race** you do a **reaction check** at impact: roll f(perception, consciousness, weapon mass/strength, pain) vs attack “speed” or timing. If defender wins, they get a full parry in place (current capacity vs momentum). If they lose, attack lands. No separate parry wind-up timer.

**Pros:**

- Keeps “do I try to parry or attack?” as a real choice.
- Perception and state directly drive success; no second wind-up to simulate.
- Simpler than two timers (attack wind-up vs parry wind-up).

**Cons:**

- You lose the “race” tension (who got their action in first). More abstract.

**Verdict:** Good if you want parry to feel like “reaction + readiness” rather than “I started my parry 0.3s ago.”

---

## Option D: Passive parry only when “ready” (state-gated)

**Idea:** Full passive parry (as in A), but it **only applies** when the defender is in a “ready” state: e.g. `STATE_WAITING` (gauge full or not) or early recovery — and **not** when they are in `STATE_WIND_UP` (attacking) or `STATE_MEDICAL_WIND_UP`. So “perception/readiness” = “are you in a position to react?”

**Pros:**

- Clear rule: you only get a chance to passively parry when you’re not committed to another action.
- Aligns with “you can’t block well while mid-swing or bandaging.”

**Cons:**

- When you’re in `STATE_WAITING` with full gauge, you *could* have chosen active parry. So this is “replace active parry with a passive roll in the same situation” unless you also allow passive parry when gauge isn’t full (e.g. “attack lands before you acted”). The interesting case is: **attack lands on you before your gauge filled** — then you never had a chance to choose parry; passive would give you a reaction chance. That’s a real addition.

**Verdict:** Most useful if you combine with “attacks can land on you while you’re still filling gauge.” Then passive parry = “reaction when you didn’t have a turn to choose parry.” If everyone only ever gets hit when they had a full gauge and could have chosen parry, then D is just A with a state filter.

---

## Option E: Keep active, tune toward “parry often” (no rework)

**Idea:** Don’t change to passive. Keep active parry but:
- Increase **parry choice weight** (or make parry the default when someone is winding up and you’re not in medical danger) so defenders parry more often.
- Slightly shorten parry wind-up or increase capacity so successful parries are more frequent when chosen.

**Pros:**

- No redesign; matches HEMA “many contacts are parries” by making the *choice* to parry more common and a bit more successful.

**Cons:**

- Still doesn’t use “perception” explicitly; it’s all in performance modifier (pain/consciousness) and timing. No “aware defender reacts without choosing.”

**Verdict:** Easiest if you’re okay with parry staying a deliberate action.

---

## Fully automatic combat: Option A and how to implement it

If the **entire combat system is automatic** (no one explicitly chooses “attack,” “parry,” or “medical” — e.g. AI or a tick-based resolver picks everything from state and priorities), then **Option A (full passive parry) is the right fit**. Parry should not be a chosen action; it should be a **reaction** when an attack would land, driven by perception and state.

Below are **different ways to implement** Option A. You can pick one or combine elements.

---

### Approach A1: Single roll at impact (simplest)

When an attack would land (after miss/dodge checks):

1. **State gate:** If defender is in `STATE_WIND_UP` (attacking) or `STATE_MEDICAL_WIND_UP`, no parry (or multiply chance by 0).
2. **Parry chance** = f(perception, consciousness, weapon, pain, legs). Same family as dodge: e.g.  
   `parry_chance = clamp(perception_factor * perf * weapon_readiness * leg_penalty, 0, 1)`  
   with a base constant (e.g. 0.5 at “full” stats) so you can tune overall rate.
3. Roll `randf() < parry_chance` → **success:** resolve as parry (use existing capacity vs momentum, or a simplified version). **Fail:** proceed to normal damage.

**Pros:** Easy to wire in, one roll, easy to tune.  
**Cons:** Binary (parry or not); no “partial parry” unless you add it in resolution.

---

### Approach A2: Readiness modifier (state affects chance)

Same as A1, but **parry chance** is multiplied by a **readiness** value that depends on defender state:

- `STATE_WAITING`: readiness = 1.0 (or 0.8 if gauge is low — “not quite ready”).
- `STATE_RECOVERING`: readiness = 0.6–0.9 (e.g. higher late in recovery, lower right after a hit).
- `STATE_WIND_UP` / `STATE_MEDICAL_WIND_UP`: readiness = 0 (no parry) or 0.1 (desperate flinch).

So: `effective_parry_chance = base_parry_chance(perception, state) * readiness(state, timer)`.

**Pros:** “Can’t block well mid-swing” and “recovering fighters are slightly vulnerable” without extra actions.  
**Cons:** Slightly more state logic.

---

### Approach A3: Opposed roll (attacker vs defender)

No raw “parry chance.” At impact:

- **Attacker score** = attack intensity/speed or wind-up duration (how committed and how fast the blow is).
- **Defender score** = reaction = f(perception, consciousness, weapon mass/strength, pain).

Roll or compare (e.g. defender wins on `randf() < defender_score / (attacker_score + defender_score)`). If defender wins → parry (full capacity vs momentum). If attacker wins → normal damage. Optionally, **margin of win** could scale partial parry (narrow win = partial, big win = full deflect).

**Pros:** Parry feels like “reaction vs commitment”; one unified roll.  
**Cons:** Tuning is less direct than a single “parry chance”; attacker stats matter for parry rate.

---

### Approach A4: Perception gates “reactable” attacks

Two stages:

1. **Is this attack “reactable”?** Roll (or threshold): e.g. `reactable = randf() < perception_factor * constant`. Only if true does the defender get a parry check.
2. If reactable, **resolve parry** with existing capacity vs momentum (or simplified). So perception controls *how often* you even get a chance; physics/weapon state control *whether* that chance succeeds.

**Pros:** Perception clearly = “noticed the blow in time”; high-perception fighters get more parry opportunities.  
**Cons:** Two rolls; can feel like “double RNG” if both are visible.

---

### A4 variants: Perception = “how fast and if” they notice, then react and parry

You want perception to control **(1) whether** the creature notices the incoming attack and **(2) how fast** they notice it, so they can **react and attempt to parry** after noticing. Below are concrete ways to do that. All assume you have **attack wind-up duration** available at impact (store it in `pending_attack` when starting the attack, or recompute from intensity/archetype in `_execute_attack`).

---

#### A4v1. Reaction time vs wind-up (binary “noticed in time?”)

**Idea:** Defender has a **reaction time** — how long until they “notice” the attack and can start reacting.

- **Reaction time** = `BASE_REACTION_S / perception_factor`.  
  - `perception_factor` = f(perception stat, consciousness, head pain) — e.g. `(perception/100) * consciousness_factor * head_pain_mod`, clamped.  
  - So high perception, clear head, no head injury → short reaction time; low perception or wounded → long reaction time.
- **Wind-up duration** = attacker’s wind-up (seconds until impact when attack started).
- **At impact:** If `reaction_time <= wind_up_duration` → defender “noticed in time” → **parry attempt** (capacity vs momentum as now). If `reaction_time > wind_up_duration` → never noticed in time → **no parry**, attack lands.

So “if” they get a parry is binary: did they have enough time to notice? “How fast” they notice is encoded in reaction time: fast attacks (short wind-up) are harder to notice in time; high perception shortens reaction time so more attacks become reactable.

**Implementation note:** Store `wind_up_duration` in `pending_attack` when you call `_begin_attack_with_target` (you already have `wind_up_s` there). In `_execute_attack`, read it (or recompute from `pa.intensity` and `pa.archetype`) and compare to defender’s reaction time.

---

#### A4v2. Notice chance roll, wind-up as “telegraph” modifier

**Idea:** “Did they notice?” is a roll; “how telegraphed” the attack is (wind-up length) makes notice more or less likely.

- **Notice chance** = `perception_factor * telegraph_factor(wind_up_duration)`.
  - `perception_factor` = 0–1 from perception, consciousness, head pain.
  - `telegraph_factor` = e.g. `clamp(wind_up_duration / REFERENCE_WIND_UP, 0.2, 1.0)` — longer wind-up = more telegraphed = easier to notice; very fast attacks cap at 0.2 so even high perception doesn’t guarantee notice.
- At impact: roll `randf() < notice_chance`. Success → **parry attempt**. Fail → no parry.

So “if” they notice is the roll; “how fast” the attack is (wind-up) changes the odds. Fast attacks are less likely to be noticed; perception still gates how often you get a chance.

---

#### A4v3. “When” they notice → time left to parry (quality of reaction)

**Idea:** Defender “notices” after a delay; the **remaining time** until impact is how long they have to get their parry in place. More time → better parry (e.g. full capacity); less time → partial parry or lower success.

- **Reaction time** = time until they notice = `BASE_REACTION_S / perception_factor` (same as A4v1).
- **Wind-up duration** = attacker’s wind-up.
- **At impact:**  
  - If `reaction_time >= wind_up_duration` → never noticed in time → **no parry**.  
  - If `reaction_time < wind_up_duration` → they noticed with **time_to_react = wind_up_duration - reaction_time** seconds to set the parry.  
    - **Parry attempt:** use existing capacity vs momentum.  
    - **Optional:** scale parry effectiveness by `time_to_react`: e.g. if `time_to_react` is very small, treat as “partial parry” (reduce damage instead of full deflect), or multiply parry capacity by `clamp(time_to_react / MIN_TIME_FOR_FULL_PARRY, 0, 1)`.

So “how fast” they notice directly sets “how much time they had to react”; that can drive both “if” they get a parry (only if they noticed in time) and “how good” the parry is (more time = better).

---

#### A4v4. Two rolls: “Did they notice?” + “How fast did they react?”

**Idea:** Separate “did they notice at all?” from “how quickly did they react?”

- **Roll 1 — Notice:** `randf() < notice_chance(perception, wind_up_duration)`. If fail, no parry (attack too subtle or defender didn’t pick it up).
- **Roll 2 — Reaction delay (only if noticed):** Sample a **reaction delay** = e.g. `BASE_DELAY * (1 - perception_factor * randf())` so high perception tends to give shorter delay.  
  - If `reaction_delay < wind_up_duration` → noticed **in time** → **parry attempt**. Optionally, parry quality scales with `wind_up_duration - reaction_delay`.  
  - If `reaction_delay >= wind_up_duration` → noticed but too late → no parry.

So “if” is partly the notice roll and partly “did I react fast enough?”; “how fast” is the reaction delay. Good for making perception matter twice (notice + reaction speed).

---

#### A4v5. Notice threshold vs attack subtlety (single opposed check)

**Idea:** One check: defender’s perception vs attack’s “subtlety.” Margin of success can scale parry quality.

- **Attack subtlety** = e.g. `1.0 / (1.0 + wind_up_duration)` or `REFERENCE_WIND_UP / wind_up_duration` — fast attacks = higher subtlety = harder to notice.
- **Defender notice score** = perception * consciousness_mod * (1 - head_pain_penalty), normalized to a 0–1 or 0–100 scale.
- **At impact:** Roll or compare: e.g. `defender_notice_score + randf() * 20` vs `50 + subtlety * 30`. Success = noticed in time → parry attempt. **Optional:** margin of success = “how much time they had” → scale parry capacity or partial parry by margin.

So one roll captures both “if” and “how favorable” the reaction was; perception and wind-up both feed in.

---

#### Summary for A4 variants

| Variant | “If” they get a parry | “How fast” they notice |
|--------|------------------------|-------------------------|
| **A4v1** | Binary: `reaction_time <= wind_up` | Reaction time from perception; fast attacks harder to react to |
| **A4v2** | Roll: notice_chance(perception, wind_up) | Wind-up length as telegraph (longer = easier to notice) |
| **A4v3** | Binary: noticed in time; optional quality by time left | Reaction time → time_to_react; more time = better parry |
| **A4v4** | Notice roll + reaction_delay < wind_up | Reaction delay from perception; two stages |
| **A4v5** | One roll: perception vs attack subtlety | Subtlety from wind-up; margin can scale parry quality |

**Recommendation:** Use **A4v1** or **A4v3** if you want a clear “reaction time vs wind-up” model and minimal rolls. Use **A4v3** if you also want “how much time they had” to improve parry quality. Use **A4v2** or **A4v5** if you prefer a single or two-stage roll with wind-up as “telegraph” rather than an explicit reaction time in seconds.

---

### Approach A5: Parry as damage reduction (no full deflect)

Passive “parry” never fully cancels the blow; it only **reduces** damage. At impact:

- Roll parry chance (A1 or A2). If success, compute a **reduction factor** from capacity vs momentum (e.g. same formula as now, but result is “multiply damage by (1 - factor)” instead of “full deflect if factor ≥ threshold”).
- So you always take some hit when “parried” passively, but less. Optionally cap: “passive parry can at most reduce to 25% of pre-armor” (like deflected).

**Pros:** No “I parried and took zero”; every blow has some consequence. Good for automatic combat where you want attrition.  
**Cons:** Different feel from “clean deflect”; may need different messaging (“glanced off” vs “parried”).

---

### Approach A6: Reuse dodge formula, different outcome

Use the **same** stat inputs as dodge (agility, perception, legs, pain, consciousness) to drive a **second** roll after dodge fails: “parry roll.” So: miss check → dodge check → **parry check** → damage. Parry chance could be a separate constant (e.g. higher than dodge, since blade-block is more common than full evasion). Success → full parry (capacity vs momentum); fail → damage.

**Pros:** Consistent with existing dodge; one stat family; easy to explain “first you try to avoid, then you try to block.”  
**Cons:** Two defensive rolls in a row can make combat feel very defensive if both are strong.

---

### Recommendation for automatic combat

- **Option A** is the right design: parry is passive, no choice.
- **Implementation:** Start with **A1** (single roll at impact, state-gated so no parry when in wind_up/medical_wind_up). Add **A2** (readiness) if you want recovery/waiting to feel different. If you want “reaction vs commitment” feel, use **A3**. If you want perception to gate *whether* you get a chance, use **A4**. If you want passive parry to only ever reduce damage, use **A5**.

---

## Recommendation

- **If the entire combat system is automatic** (no one chooses parry as an action), use **Option A** and implement it with one of the approaches above (A1–A6). See “Fully automatic combat: Option A and how to implement it.”
- **If you want perception/state to drive “did I get my blade in the way?”** (and you still have action choice)  
  - Prefer **B (hybrid)** or **C (reactive parry)**.  
  - B keeps the current “I choose parry” moment and adds a weaker passive reaction when you didn’t choose parry.  
  - C keeps the choice but makes success a perception/state roll instead of a wind-up race.

- **If you want to simplify and remove the parry choice**  
  - **A (full passive)** is consistent, especially if you add **D (state-gated)** so passive parry only when defender isn’t winding up an attack or doing medical.  
  - The most interesting case is when an attack lands **before** the defender’s gauge is full — then passive parry is the only way to “react”; that’s a clear design gain.

- **If you only want parries to be more common and more impactful**  
  - **E** is enough: keep active parry, bump weight and/or success so “defended” (parry + deflected) sits in the ~57–80% band from research.

**Suggested path:** Implement **B (hybrid)** so that:
1. Active parry stays as-is (choice, wind-up, capacity vs momentum).
2. When an attack would hit and the defender did **not** actively parry (e.g. they’re in recovery, or they chose attack and the attacker’s blow lands first), roll a **passive parry chance** from perception/consciousness/weapon/pain; on success, apply a reduced effect (e.g. partial parry or treat as deflected). That gives you perception-based reaction without removing the tactical “I parry” decision.

If you tell me which option you prefer (A, B, C, D, or E), I can outline concrete formula and where to hook it in `CombatManager.gd` (e.g. in `_execute_attack` before applying damage).
