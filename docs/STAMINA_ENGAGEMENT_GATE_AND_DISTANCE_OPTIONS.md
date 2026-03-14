# Stamina-Based Engagement: Gating Replacements & Distance / Engagement Ease

> **Implementation plan:** The chosen approach (distance bands + state-based event queue) is documented in `STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md`. This doc retains the exploration of alternative gating and distance options.

## Context

You want to replace the gauge system with a stamina-driven engagement model. Two design questions:

1. **What gates when units engage?** (replacement for "gauge must be 100% to act")
2. **How to simulate distance and engagement ease** so that:
   - High agility + light armor → faster disengage, harder to engage (evasive)
   - Low agility + heavy armor → easier to engage (easier to pin down)
   - Weapon choice factors in (reach, commitment)

---

## Part 1: Gating Mechanisms (Replacement for Gauge)

### Option A: Stamina Threshold Only

**Idea:** You can attempt to engage whenever stamina ≥ MIN_ENGAGE_STAMINA (e.g. 15–20). Below that, you cannot initiate.

- **Gate:** `stamina >= STAMINA_ENGAGE_MIN` to attempt engagement
- **Pros:** Dead simple; stamina is the sole gate
- **Cons:** No pacing beyond stamina recovery; can feel spammy if refill is fast

---

### Option B: Stamina + Engagement Readiness (Abstract Cooldown)

**Idea:** After disengaging, you have a brief "not ready" period. Stamina refills, but you also need `engagement_cooldown <= 0` to initiate again.

- **Gate:** `stamina >= MIN` AND `engagement_cooldown <= 0`
- **Cooldown:** Set when you disengage; decays over real time (or game ticks). Light/agile units: short cooldown; heavy/slow: long.
- **Pros:** Prevents instant re-engage; differentiates light vs heavy
- **Cons:** Two things to track (stamina + cooldown)

---

### Option C: Initiative Meter (Stamina-Adjacent)

**Idea:** A separate "initiative" or "readiness" value that fills over time, scaled by stamina and agility. Only when it crosses a threshold can you attempt engagement.

- **Gate:** `initiative >= 100` (or similar)
- **Fill rate:** `INITIATIVE_FILL_BASE * (agility/100) * stamina_factor(stamina) * (1 - armor_burden)`
- **Pros:** One number to display; can tune pacing separately from stamina (stamina = effectiveness, initiative = "when can I act")
- **Cons:** Functionally similar to gauge; may feel like a rename unless initiative is consumed differently (e.g. spent only on engagement attempt, not per blow)

---

### Option D: Stamina + Opponent-Dependent "Window"

**Idea:** You can engage when stamina is sufficient **and** the opponent presents an opportunity. Opportunity = they are not in a safe state (recovering, in bind, etc.) or their engagement ease is low (they're evasive).

- **Gate:** `stamina >= MIN` AND `opponent.engagement_opening >= OPENING_THRESHOLD`
- **Opening:** Derived from defender state: recovering = high opening; ready + agile + light = low opening. Optionally: attacker reach vs defender distance.
- **Pros:** Tactical: you wait for the right moment; evasive targets are hard to engage
- **Cons:** Can create stalemates (both waiting); needs clear rules for when opening appears

---

### Option E: Stamina + Time-Since-Last-Action (Hybrid)

**Idea:** Minimum time between engagement attempts. Stamina must be above threshold, and `time_since_last_disengage >= f(agility, armor)`.

- **Gate:** `stamina >= MIN` AND `now - last_disengage_time >= cooldown`
- **Cooldown:** `COOLDOWN_BASE * (100/agility) * (1 + armor_burden)` — agile/light = short; slow/heavy = long
- **Pros:** Clear pacing; ties directly to mobility
- **Cons:** Still two dimensions (stamina + time)

---

**Recommendation for gate:** Start with **A** (stamina threshold) plus **B** (short engagement cooldown after disengage). Cooldown is where agility and armor affect "how quickly can I re-engage" — agile/light gets back in fast; heavy/slow takes longer.

---

## Part 2: Distance & Engagement Ease Simulation

Your system is abstract (no grid/physics). "Distance" and "engagement ease" must be derived from stats and weapons.

### Core Idea

- **Engagement ease (for attacker):** How easy it is to *get into* an exchange with a target. High = target is easy to pin down.
- **Disengagement ease (for defender):** How easy it is to *break off* from an exchange. High = defender can slip away.

Design goal:
- **High agility + light armor** → hard to engage (evasive), easy to disengage
- **Low agility + heavy armor** → easy to engage, hard to disengage
- **Weapon reach** → longer reach can engage from "further" (abstract); shorter weapons may need to close first

---

### Approach 1: Stat-Based Engagement Score (No Distance)

**Idea:** Each combatant has an `engagement_resistance` and `disengage_ability` derived from stats.

```
engagement_resistance = base 
  + (100 - agility) * AGILITY_ENGAGEMENT_WEIGHT   # slow = easier to engage
  + armor_burden * ARMOR_ENGAGEMENT_WEIGHT         # heavy armor = easier to engage
  - weapon_commitment * WEAPON_WEIGHT              # heavy weapon = slightly harder (committed)
```

```
disengage_ability = base
  + (agility - 100) * AGILITY_DISENGAGE_WEIGHT     # agile = easier to break off
  - armor_burden * ARMOR_DISENGAGE_WEIGHT          # heavy armor = harder to slip away
  + weapon_reach * REACH_DISENGAGE_WEIGHT?         # longer weapon = can disengage from further? (optional)
```

**Usage:**
- Attacker wants to engage target. Roll or compare: `attacker_engagement_pressure vs target.engagement_resistance`. If pressure wins, engagement forms.
- During exchange, defender can attempt disengage. Compare: `defender.disengage_ability vs attacker.engagement_hold`. If defender wins, they break off.

**Pros:** No distance; pure stats. Easy to implement.  
**Cons:** No spatial flavor; "reach" is only indirect.

---

### Approach 2: Abstract Distance Bands (Close / Mid / Long)

**Idea:** Each combatant pair has `distance_band: String` — "close", "mid", or "long". This is abstract (no tiles).

**How distance is set:**
- Start: "long" (not in range)
- Attacker with sufficient stamina and reach attempts "close" — success depends on defender's evasion (agility, armor burden)
- On engagement: "close"
- On disengage: defender rolls to set distance — agile/light often end at "mid" or "long"; heavy often end at "mid" (still in threat range)
- Weapon reach: spear at "mid" can still attack; dagger must be "close"

**Engagement ease:**
- To go from "long" → "close": roll `attacker_reach + pressure` vs `defender_evasion`
- Evasion = `agility * (1 - armor_burden)` — higher = harder to close on
- Engagement hold (can attacker keep them close?) = `attacker_strength + weapon_commitment` vs `defender_disengage_ability`

**Pros:** Adds tactical flavor; reach matters.  
**Cons:** More state; need rules for how distance changes each tick or action.

---

### Approach 3: Engagement Pressure vs Evasion (Single Roll)

**Idea:** No distance. When A tries to engage B:

```
engagement_pressure = A.strength * stamina_factor(A) * weapon_aggression_factor
evasion = B.agility * (1 - B.armor_burden) * stamina_factor(B)
```

If `pressure > evasion * ENGAGEMENT_THRESHOLD`, engagement forms. Optionally add variance.

**Disengage:** B rolls `disengage_ability` vs A's `hold_strength`. Same stat mix.

**Weapon factors:**
- `weapon_aggression_factor`: dagger = 1.2 (quick to close); mace = 0.9 (slow to commit); spear = 1.1 (reach helps close)
- `weapon_hold_factor`: heavy weapons "hold" better (harder for defender to slip); light = easier to disengage against

**Pros:** One comparison; stats and weapons both matter.  
**Cons:** Still no spatial distance; more about "can I lock you down" than "am I in range."

---

### Approach 4: Effective Reach & Armor Burden

**Idea:** Weapon has `melee_range` (you have 0.8–2.5). Entity has `effective_reach`:

```
effective_reach = weapon.melee_range * (agility/100) * (1 - ARMOR_REACH_PENALTY * armor_burden)
```

Heavy armor shortens effective reach (can't extend as far, slower to step in).

**Engagement:**
- Attacker can engage target if `attacker.effective_reach >= pair.effective_distance`
- `effective_distance` = abstract "steps" or "bands" between them. Starts at 2–3; reduced when attacker "closes" (spends stamina or succeeds on approach roll)
- Defender with high agility + light armor: `effective_distance` drifts upward (they create space). Heavy: drift is slow or negative (they're stuck close)

**Disengage:**
- Defender rolls: `agility * (1 - armor_burden)` to add to `effective_distance`. If it exceeds a threshold, they're "out of range" and disengage.

**Pros:** Reach and armor interact; fits HEMA "measure" intuition.  
**Cons:** More variables; "effective distance" is another abstract state.

---

### Approach 5: Armor Burden (New Stat)

**Idea:** Add explicit `armor_burden: float` (0–1) per combatant, from equipped armor.

```
armor_burden = sum over parts of (piece_weight_factor * coverage_factor) / MAX_BURDEN
```

Or simpler: count plate vs mail vs leather vs cloth; plate = 0.25, mail = 0.15, leather = 0.08, cloth = 0.02 per part. Sum and normalize.

**Use everywhere:**
- Engagement resistance: `+= armor_burden * 0.5`
- Disengage ability: `-= armor_burden * 0.6`
- Initiative/cooldown fill: `*= (1 - armor_burden * 0.3)`
- Effective agility for mobility: `agility * (1 - armor_burden)`

**Pros:** Single derived stat; reusable.  
**Cons:** Requires armor weight/mobility data per piece (or layer). ArmorPiece currently has no explicit weight; could add `mobility_penalty` per layer or piece.

---

## Part 3: Weapon Integration

Weapons already have `melee_range` and mass. Use them:

| Factor | Effect on engagement |
|--------|----------------------|
| **melee_range** | Longer = can engage from "further" (abstract). Spear: easier to initiate engagement; dagger: must get close (harder vs evasive). |
| **mass** | Heavier = more commitment = slower to abort. Use in "hold" or "engagement pressure" — heavy weapon keeps opponent in exchange once close. |
| **parry_speed_factor** | Already exists. Faster parry = better at defending during exchange; could reduce defender's "forced engagement" duration. |
| **base_cooldown (move)** | Quick moves (dagger) = faster follow-ups in flurry; slow moves (axe) = fewer blows per engagement. |

**Suggested formula additions:**
- `engagement_pressure += weapon_reach_factor * (melee_range / REFERENCE_REACH)`
- `hold_strength += weapon_mass_factor * (mass / REFERENCE_MASS)` when in engagement

---

## Part 4: Recommended Synthesis

### Gating (replacement for gauge)
- **Primary:** Stamina ≥ STAMINA_ENGAGE_MIN (e.g. 20)
- **Secondary:** Engagement cooldown after disengage: `cooldown_s = COOLDOWN_BASE * (100/agility) * (1 + armor_burden * 0.5)`
- No gauge; "ready to act" = stamina + cooldown both pass

### Engagement ease
- **engagement_resistance** (defender) = `BASE + (100 - agility)*0.3 + armor_burden*40`
  - High agility, low armor → low resistance (wait, that means easy to engage — we want hard). Fix: **evasion** = `agility * (1 - 0.5*armor_burden)`. Higher evasion = harder to engage.
- **evasion** = `agility * (1 - ARMOR_BURDEN_FACTOR * armor_burden)`
- **engagement_pressure** (attacker) = `strength * stamina_factor * reach_factor`
- Roll: if `pressure * roll > evasion`, engagement forms.

### Disengagement
- **disengage_ability** = `agility * (1 - armor_burden) * stamina_factor`
- **hold** = `attacker.strength * weapon_mass_factor`
- Defender can attempt disengage each blow or at end of flurry. If `disengage_ability > hold`, they break off.

### Armor burden
- Add `mobility_penalty` or `weight` to armor layers/pieces. Sum per entity → `armor_burden` 0–1.

---

## Part 5: Data Additions Needed

| Location | Addition |
|---------|----------|
| **ArmorConstants / ArmorPiece** | `mobility_penalty` or `weight` per layer or piece |
| **CoreEntity / Combatant** | `armor_burden: float` (computed from equipped armor) |
| **WeaponConstants** | Use existing `melee_range`, `mass` in engagement formulas |
| **CombatConstants** | `STAMINA_ENGAGE_MIN`, `ENGAGEMENT_COOLDOWN_BASE`, `ARMOR_BURDEN_FACTOR`, engagement pressure/evasion weights |

---

## References
- `docs/ENGAGEMENT_FLURRY_IMPLEMENTATION_OPTIONS.md` — flurry and engagement design
- `docs/MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md` — engagement options
- `docs/COMBAT_ISSUES_TODO_INVESTIGATION.md` — measure/distance (Section 10)
- `weapon/WeaponConstants.gd` — melee_range, mass per weapon
- `core/CoreEntity.gd` — agility, armor_slots
- `armor/ArmorConstants.gd` — layer definitions (no mobility yet)
