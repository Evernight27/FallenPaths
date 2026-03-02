# Parry and Dodge Tweak Options

This document investigates different ways to implement two tweaks:

1. **Parry:** Let Goblins (and similar low-perception or unarmed defenders) parry sometimes.
2. **Dodge:** Add a small floor so defense never feels hopeless (e.g. 1–2% flinch chance).

---

## Context

- **Parry** requires: defender has weapon, `reaction_time < effective_wind_up`, and (when choosing) `p_a <= c_d * PARRY_DODGE_STRENGTH_RATIO`. Goblins (perception 80) have reaction ~0.35 s; `effective_wind_up = wind_up * (1 - COMMITMENT_FRACTION)` (0.8). For wind_up 0.45 s → 0.36 s, so they are right on the edge; slightly shorter wind-ups → "cannot parry in time."
- **Dodge** is `dodge_stat_factor * DODGE_CHANCE_AT_FULL_SPEED * leg * perf * leg_pain_mod`, clamped 0–1. Injured defenders can hit 0% dodge.
- **Weapons:** Enemies (Enemy.tscn = CoreEntity) get a random weapon in `_equip_random_equipment`; `get_all_weapon_ids()` is non-empty, so the only way they have no weapon is if `Weapon.create_from_definition(weapon_id)` returns null (rare).

---

## 1. Parry: Let Goblins Parry Sometimes

### Option A: Raise species perception (recommended)

**Idea:** Reaction time is already `PASSIVE_PARRY_BASE_REACTION_S / perception_factor` with perception in the factor. So raising a species’ perception shortens reaction time with no new systems—just tune the stat. Goblins (perception 80) have reaction ~0.35 s; at 90 perception → ~0.31 s, at 95 → ~0.29 s, so they clear typical effective wind-ups (e.g. 0.36 s).

**Touchpoints:**

- `species/goblin.tres`: set `perception = 90` (or 95). No code changes.

**Side effects:** Perception also affects dodge (`(agility + perception) / 200`) and attacker hit chance when they attack. So this is a small “more alert / reactive” buff—fits Goblins; no redundancy.

**Pros:** No new fields or code; one stat to tune; consistent with existing meaning of perception.  
**Will they actually parry against 150-str party?** They *can* parry in time (reaction &lt; effective wind-up). But the defender only *chooses* parry when `p_a <= c_d * PARRY_DODGE_STRENGTH_RATIO` (1.4). Rough numbers: Goblin str 65 → typical `c_d` ~4–10; party str 150, weapon ~1.7 kg, v ~21 m/s → `p_a` ~36. So `c_d` would need ≥ 36/1.4 ≈ 26 for the Goblin to choose parry; their `c_d` is far below that. So against a 150-str party, Goblins will almost always choose dodge (“opponent stronger, prefer dodge”) and the party effectively avoids the parry—the Goblin never attempts it. Raising perception only makes parry *available*; it does not make weak defenders choose parry into much stronger attackers. To have Goblins sometimes parry (often partial) into the party, raise Goblin strength/weapon so `c_d` can approach that range, or relax `PARRY_DODGE_STRENGTH_RATIO`.

**Cons:** None for this use case. Use Option A2 only if you want parry to improve without touching dodge or hit chance.

---

### Option A2: Species reaction-time multiplier (parry-only)

**Idea:** If you want “parry in time” to improve without changing dodge or attacker hit chance, add an optional species multiplier that scales only parry reaction time.

**Touchpoints:**

- `species/SpeciesResource.gd`: add `@export var parry_reaction_mult: float = 1.0` (&lt; 1 = faster).
- `core/CoreEntity.gd` in `get_passive_parry_reaction_time()`: multiply result by `species.parry_reaction_mult` when present.
- `species/goblin.tres`: set `parry_reaction_mult = 0.9` if using this instead of Option A.

**Pros:** Parry-only tuning.  
**Cons:** Redundant with perception for most cases; extra field and code.

---

### Option B: Lower global base reaction time

**Idea:** Reduce `PASSIVE_PARRY_BASE_REACTION_S` in CoreEntity (e.g. 0.28 → 0.24) so everyone can parry a bit more often.

**Touchpoints:**

- `core/CoreEntity.gd`: change `const PASSIVE_PARRY_BASE_REACTION_S: float = 0.28` to `0.24` (or 0.25).

**Pros:** One constant, no new data.  
**Cons:** Buffs all defenders (players and enemies); may make parry too common.

---

### Option C: Increase commitment window (effective wind-up)

**Idea:** Give defenders more “telegraph” time by increasing `COMMITMENT_FRACTION` so the reaction window is longer.

**Touchpoints:**

- `ui/CombatManager.gd`: e.g. `const COMMITMENT_FRACTION := 0.25` (was 0.2). Then `effective_wind_up = wind_up_duration * (1.0 - 0.25) = wind_up * 0.75`. So for 0.45 s wind-up → 0.3375 s. That’s still less than Goblin 0.35 s. To get Goblins in, need ~0.22 or lower effective (0.35/0.45 ≈ 0.78) → COMMITMENT_FRACTION ≈ 0.22 only gives 0.351; so you’d need something like 0.30 (effective 0.315) to barely include 0.35, but then 0.35 &lt; 0.315 is false. So you actually need *longer* effective wind_up (e.g. *decrease* COMMITMENT_FRACTION to 0.15 so effective = 0.45*0.85 = 0.3825 &gt; 0.35).

Correct: `effective_wind_up = wind_up_duration * (1.0 - COMMITMENT_FRACTION)`. To make it *larger*, *decrease* COMMITMENT_FRACTION. So COMMITMENT_FRACTION 0.1 → effective = wind_up * 0.9. For 0.45 → 0.405 &gt; 0.35. So lowering COMMITMENT_FRACTION from 0.2 to 0.1 gives more time to react.

**Touchpoints:**

- `ui/CombatManager.gd`: `const COMMITMENT_FRACTION := 0.1` (was 0.2).

**Pros:** Single constant; no species data.  
**Cons:** Affects all combats; “commitment” phase shortens (more of wind-up counts as telegraph), which may change feel.

---

### Option D: Guarantee enemy weapon

**Idea:** Ensure every enemy that can hold a weapon gets one (retry or fallback weapon if create fails).

**Touchpoints:**

- `main.gd` in `_equip_random_equipment`: if `Weapon.create_from_definition(weapon_id)` returns null, try next `weapon_id` or a fixed default (e.g. "DAGGER") until one succeeds; only skip equipping if all fail.

**Pros:** Removes “no weapon” as a cause of “cannot parry in time.”  
**Cons:** Does not fix reaction-time edge case; only helps when weapon was missing.

---

### Recommendation (parry)

- **Primary:** **Option A** (raise Goblin perception to 90–95) — no code, no new stats, same meaning as “more likely to notice attacks.”  
- **Optional:** **Option D** (guarantee weapon) as a robustness fix if weapons ever fail to equip.  
- **Option A2** only if you need parry to improve without affecting dodge or hit chance.  
- **Option B** or **Option C** only if you want a global balance shift for all defenders.

---

## 2. Dodge: Add a Small Floor

### Option A: Constant floor in get_dodge_chance (simplest)

**Idea:** Clamp dodge chance from below by a small constant (e.g. 1–2%).

**Touchpoints:**

- `core/CoreEntity.gd`:  
  - Add `const DODGE_CHANCE_FLOOR: float = 0.01` (or 0.02).  
  - In `get_dodge_chance()`:  
    `return clampf(dodge_stat_factor * DODGE_CHANCE_AT_FULL_SPEED * leg * perf * leg_pain_mod, DODGE_CHANCE_FLOOR, 1.0)`  
    (replace current `clampf(..., 0.0, 1.0)`).

**Pros:** One constant, one line change; every defender keeps at least 1% dodge.  
**Cons:** Even fully incapacitated defenders get the floor (if you consider that unrealistic, use Option B).

---

### Option B: Floor only when injured

**Idea:** Apply a floor only when the “raw” dodge would be very low (e.g. leg or perf &lt; 1), to represent a minimal flinch without giving full-health defenders an extra chance.

**Touchpoints:**

- `core/CoreEntity.gd` in `get_dodge_chance()`:  
  - Compute `raw = dodge_stat_factor * DODGE_CHANCE_AT_FULL_SPEED * leg * perf * leg_pain_mod`.  
  - If `raw < DODGE_CHANCE_FLOOR` and (e.g.) `(leg < 1.0 or perf < 1.0)`, use `maxf(raw, DODGE_CHANCE_FLOOR)`; else use `raw`.  
  - Then `clampf(..., 0.0, 1.0)` as now.

**Pros:** Floor only for injured/low-capability defenders; full-health unchanged.  
**Cons:** Slightly more logic; need to define “injured” (leg/perf thresholds).

---

### Option C: Species dodge floor

**Idea:** SpeciesResource gets an optional `dodge_floor` (0–1). Entity uses it as minimum dodge when applicable.

**Touchpoints:**

- `species/SpeciesResource.gd`: `@export var dodge_floor: float = 0.0`.  
- `core/CoreEntity.gd` in `get_dodge_chance()`:  
  - Compute dodge as now.  
  - `var floor_val: float = 0.0`  
  - `if species != null and "dodge_floor" in species: floor_val = species.dodge_floor`  
  - `return clampf(maxf(raw_dodge, floor_val), 0.0, 1.0)`  
- `species/goblin.tres`: e.g. `dodge_floor = 0.02` for a “twitchy” minimum.

**Pros:** Per-species flavor; humans can stay 0, Goblins get a small floor.  
**Cons:** More data; floor is always on for that species (not only when injured).

---

### Recommendation (dodge)

- **Simplest and robust:** **Option A** (constant `DODGE_CHANCE_FLOOR = 0.01` in CoreEntity).  
- **More realistic:** **Option B** (floor only when injured).  
- **Flavor per species:** **Option C** (species `dodge_floor`) if you want Goblins (or others) to have a higher minimum dodge than humans.

---

## Summary Table

| Tweak        | Option | Where | Effort | Notes |
|-------------|--------|--------|--------|--------|
| Parry       | A – raise perception | goblin.tres only | None | Recommended; “Goblins parry sometimes” no code, no new stats. |
| Parry       | A2 – species reaction mult | SpeciesResource + CoreEntity + tres | Low | Parry-only; use if dodge/hit must not change. |
| Parry       | B – lower base reaction   | CoreEntity const | Trivial | Buffs all defenders. |
| Parry       | C – commitment window     | CombatManager const | Trivial | Larger telegraph for everyone. |
| Parry       | D – guarantee weapon      | main.gd _equip_random_equipment | Low | Only helps when weapon was missing. |
| Dodge       | A – constant floor       | CoreEntity const + clamp | Trivial | 1% floor for all. |
| Dodge       | B – floor when injured   | CoreEntity get_dodge_chance | Low | Floor only when leg/perf &lt; 1. |
| Dodge       | C – species floor         | SpeciesResource + CoreEntity + tres | Low | Per-species minimum dodge. |

Implementing **Parry A** (raise Goblin perception to 90–95) + **Dodge A** (or B) gives the intended feel; no code change for parry.
