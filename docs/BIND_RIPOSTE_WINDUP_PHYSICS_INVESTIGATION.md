# Bind Riposte Wind-Up: Physics-Based Implementation Investigation

## Purpose

Explore how bind riposte wind-up reduction should be implemented, with focus on **what is physically possible** for each weapon from a bind position. Different parry parts (blade, shaft, haft) and different attack types (thrust, cut, blunt) have fundamentally different mechanics.

---

## 1. Physics of the Bind by Parry Part

### 1.1 Blade-on-Blade Bind (Sword, Dagger)

**Parry part:** Blade. **Bind geometry:** Both blades in contact; defender's forte controls attacker's foible.

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Thrust** | Extension — point already in line; blade slides forward along/off opponent's blade | **Minimal** — no swing, just extend. Liechtenauer: "thrust from Plough." |
| **Cut (wind)** | Roll blade along opponent's blade (Vier Versetzen, Winden) | **Moderate** — blade rotation, but opponent's blade guides. Faster than cut from idle. |
| **Cut (disengage)** | Disengage, then cut from new angle | **Full** — must break contact and swing. Same as normal cut. |

**Sources:** Liechtenauer Part 5 (Binds), HEMA 101 (Vier Versetzen, thrust from bind).

---

### 1.2 Shaft-on-Blade Bind (Spear, Mace)

**Parry part:** Shaft. **Bind geometry:** Defender's shaft met attacker's blade. Contact is shaft, not blade.

#### Spear (shaft parries)

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Thrust** | Point is forward; extend arms. Shaft is already in line. | **Minimal** — same as sword thrust from bind. Fiore: spear thrust after parry. |
| **Slash** | Spearhead must swing — blade is at tip, shaft was in contact | **Moderate** — rotate shaft to bring head to target. |
| **Pole swing** | Heavier motion; blunt strike with shaft | **Significant** — full swing. |

#### Mace (shaft parries)

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Strike (overhead/side/direct)** | Head is at end of shaft. Shaft was in contact; head was not. | **Significant** — must swing the head into the opponent. Heavy mass at end of lever. |
| **Thrust with poll** | Some maces have back spike; extend | **Minimal** — if weapon has thrust option. *Current mace has no thrust move.* |

**Conclusion:** Spear thrust from bind = fast. Mace strike from bind = slow (must swing head into position). A single "bind riposte mult" fails to capture this.

---

### 1.3 Haft-on-Blade Bind (Axe)

**Parry part:** Haft. **Bind geometry:** Defender's haft met attacker's blade. Axe blade and spike are at the ends.

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Spike thrust** | Spike is forward; extend like spear | **Minimal** — Le Jeu de la Hache: thrust with spike from bind. |
| **Chop (overhead/diagonal)** | Blade at end; must swing head into target | **Moderate** — rotate axe to bring blade to target. Faster than from idle (weapon already moving, opponent's blade gives reference). |
| **Poll strike** | Back of head; similar to chop | **Moderate** — swing required. |

**Conclusion:** Axe spike thrust = fast. Axe chop = moderate benefit (less than thrust, more than mace strike).

---

## 2. Summary: Physics-Derived Wind-Up Multipliers

| Parry Part | Contact Type | Motion from Bind | Suggested Mult | Rationale |
|------------|--------------|------------------|----------------|-----------|
| Blade | stab | Extend | **0.50–0.55** | Minimal — point in line |
| Blade | cut | Wind along blade | **0.70–0.80** | Moderate — roll, not full swing |
| Shaft (spear) | stab | Extend | **0.50–0.55** | Same as blade thrust |
| Shaft (spear) | cut | Rotate shaft | **0.75–0.85** | Moderate |
| Shaft (mace) | blunt | Swing head | **0.85–0.95** | Significant — head must travel |
| Haft (axe) | stab | Extend spike | **0.50–0.55** | Same as thrust |
| Haft (axe) | cut | Swing blade | **0.75–0.85** | Moderate — blade at end |

**Key insight:** The multiplier should depend on **contact_type** (stab/cut/blunt), not just weapon. Stab = extend = fast. Cut = wind or short swing = moderate. Blunt = full swing of mass = slow.

---

## 3. Implementation Approaches

### Approach A: Uniform Multiplier (Simplest)

**Rule:** Bind riposte always gets `wind_up_s *= 0.6` when attacking parry_against_id.

**Pros:** Trivial; one constant.  
**Cons:** Mace strike gets same bonus as sword thrust — physically wrong. Dagger (fastest) and mace (slowest) treated identically.

---

### Approach B: Contact-Type Multipliers

**Rule:** Multiplier depends on the chosen move's `contact_type`:

```gdscript
const PARRY_BIND_RIPOSTE_MULT_BY_CONTACT: Dictionary = {
    "stab": 0.55,   # Extend — minimal wind-up
    "cut": 0.78,    # Wind or moderate swing
    "blunt": 0.90   # Full swing of mass
}
```

**Eligibility:** Only when move's contact_type is in weapon's bind-riposte-eligible set (from parry moves, or weapon override for axe spike).

**Pros:** Physically grounded. Stab fast, blunt slow. One table.  
**Cons:** Spear slash vs axe chop both "cut" — spear might deserve slightly better (lighter). Mace 0.9 is still a benefit; some may argue mace gets 1.0 (no bonus).

---

### Approach C: Contact-Type + Weapon-Type Overrides

**Base:** Approach B. **Override:** Per-weapon constants for edge cases.

```gdscript
# Base by contact_type
const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55
const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78
const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90

# Optional weapon overrides (weapon_id -> mult override when in bind)
# Mace: shaft bind, blunt only — weakest benefit
const PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE: Dictionary = {
    "MACE": 0.92,   # Heavier swing from shaft bind
    "DAGGER": 0.50  # Lightest weapon, thrust dominant — slightly faster
}
```

**Pros:** Fine-grained. Dagger can be fastest; mace slowest.  
**Cons:** More constants; must maintain per weapon.

---

### Approach D: Parry-Part + Contact-Type Matrix

**Rule:** Multiplier from `(parry_part_id, contact_type)`:

|            | stab | cut | blunt |
|------------|------|-----|-------|
| blade      | 0.52 | 0.75| —     |
| shaft      | 0.54 | 0.80| 0.90  |
| haft       | 0.53 | 0.78| —     |

*Blade/haft don't have blunt as primary bind follow-up; those weapons use cut or stab.*

**Pros:** Most physically detailed.  
**Cons:** Sparse matrix; most cells unused. Overkill for 5 weapons.

---

### Approach E: Archetype-Based (Wind/Strike Characteristics)

**Rule:** Use archetype's existing `windup_multiplier` as base; bind applies an additional scale.

- **stab** archetype: already quick wind-up (1.0). Bind makes it 0.55× effective.
- **slash** archetype: bind makes it 0.78×.
- **heavy_blunt** archetype: bind makes it 0.90×.

Same as B, but keyed by archetype instead of contact_type. For our weapons, contact_type and archetype align (stab→stab, cut→slash/overhead, blunt→heavy_blunt/pommel).

**Pros:** Reuses existing archetype data.  
**Cons:** Archetype ≠ contact_type for all moves (e.g. slash could be ARCHETYPE_SLASH or ARCHETYPE_OVERHEAD). contact_type is more direct.

---

### Approach F: Move-Level `bind_riposte_mult` (Optional Override)

**Rule:** Moves can specify `bind_riposte_mult: 0.5`. If present, use it; else use Approach B from contact_type.

```gdscript
"parry_thrust": { ..., "bind_riposte_mult": 0.52 },
"parry_chop": { ..., "bind_riposte_mult": 0.78 },
"parry_strike": { ..., "bind_riposte_mult": 0.90 },
"thrust": { ..., "bind_riposte_mult": 0.52 },  # Normal thrust from bind
```

**Pros:** Maximum tuning per move. parry_thrust can differ from thrust if desired.  
**Cons:** Schema bloat; many moves need the field; redundancy with contact_type.

---

### Approach G: Physics Formula (Mass + Contact Type)

**Rule:** Base mult from contact_type; scale by weapon mass (lighter = faster from bind).

```gdscript
var base: float = PARRY_BIND_RIPOSTE_MULT_BY_CONTACT[contact_type]
var mass_kg: float = weapon.mass
var mass_factor: float = lerpf(1.05, 0.95, (mass_kg - 0.3) / (1.8 - 0.3))  # Dagger 1.05, Spear 0.95
wind_up_s *= base * mass_factor
```

**Pros:** Dagger naturally fastest; spear/mace slowest.  
**Cons:** Mass already affects wind-up via archetype; risk of double-counting. Added complexity.

---

## 4. Eligibility: Which Moves Get the Bonus?

From BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION: use parry moves to infer eligible contact types per weapon.

| Weapon | Parry Moves | Eligible Contact Types |
|--------|-------------|------------------------|
| Sword  | parry_thrust (stab), parry_cut (cut) | stab, cut |
| Axe    | parry_chop (cut) | cut. *Add stab for spike_thrust — Le Jeu has thrust from bind.* |
| Mace   | parry_strike (blunt) | blunt |
| Dagger | parry_thrust_dagger (stab) | stab |
| Spear  | parry_thrust_spear (stab) | stab. *Add cut for spear_slash if desired.* |

**Axe edge case:** Axe has spike_thrust but no parry_spike. Add optional `bind_riposte_contact_types: ["cut", "stab"]` to axe weapon def to include spike.

---

## 5. Recommendation

### Primary: **Approach B (Contact-Type Multipliers)** + **Approach C (Weapon Overrides for Edge Cases)**

1. **Constants:**
   ```gdscript
   const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55    # Extend — minimal
   const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78     # Wind or moderate swing
   const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90   # Full swing
   # Optional: PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE for MACE 0.92, DAGGER 0.50
   ```

2. **Eligibility:** Infer from weapon's parry moves (Approach B from BIND_RIPOSTE doc). Axe: add `bind_riposte_contact_types: ["cut", "stab"]` in weapon def for spike.

3. **Logic in AttackWindUpStarter:**
   - If `atk.get("parry_was_bind")` and `atk.get("parry_against_id") == target_id`:
     - Get `contact_type` from weapon for chosen move_id.
     - If contact_type in weapon's eligible set:
       - mult = weapon_override if present, else contact_type mult.
       - wind_up_s *= mult.

### Variant: **Approach B Only** (No weapon overrides)

Use 0.55 / 0.78 / 0.90 for stab / cut / blunt. Simpler; physically sound. Add weapon overrides only if tuning demands it.

---

## 6. Implementation Checklist

1. **CombatConstants.gd:**
   - `PARRY_BIND_RIPOSTE_MULT_STAB := 0.55`
   - `PARRY_BIND_RIPOSTE_MULT_CUT := 0.78`
   - `PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90`
   - Optional: `PARRY_BIND_RIPOSTE_MULT_BY_CONTACT` dict or `PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE`

2. **Helper** `_get_bind_riposte_mult(weapon, move_id, contact_type) -> float`:
   - If weapon override present, return it.
   - Else return contact_type mult (stab/cut/blunt).

3. **Helper** `_get_bind_riposte_contact_types(weapon) -> Array`:
   - From weapon def `bind_riposte_contact_types` if present.
   - Else from weapon's is_parry moves' contact_type.

4. **AttackWindUpStarter.start:**
   - After `wind_up_s *= trans_mult`, before leg/perf/agility:
   - If bind conditions met and contact_type eligible: `wind_up_s *= bind_mult`.

5. **WeaponConstants / Weapon def (optional):** Axe: `"bind_riposte_contact_types": ["cut", "stab"]`.

---

## 7. Comparison Table

| Approach | Physical Accuracy | Effort | Schema Change | Best For |
|----------|-------------------|--------|---------------|----------|
| A: Uniform | Low | Minimal | None | Quick prototype |
| **B: Contact-type** | **High** | **Low** | **None** | **Default** |
| C: + Weapon override | Very High | Low | Optional weapon field | Fine-tuning |
| D: Matrix | Very High | Medium | None | Max accuracy |
| E: Archetype | High | Low | None | Alternative to B |
| F: Move-level | Very High | High | Move def | Per-move control |
| G: Mass formula | High | Medium | None | Mass-aware |

---

## References

- PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md
- BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION.md
- WeaponConstants.gd (moves, parry_part_id, contact types)
- Liechtenauer (Binds, thrust from bind)
- Le Jeu de la Hache (spike thrust from haft contact)
- Fiore (spear thrust after parry)
