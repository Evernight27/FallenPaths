# Binding and Tempo: Weapon Positioning and Attack Timing

## Purpose

Investigate how HEMA concepts of **bind** (Blade contact where both fencers control) and **tempo** (Vor/Nach — initiative, who acts first) should affect weapon positioning and attack timing.

---

## 1. Current Implementation

| Concept | Current | Notes |
|---------|---------|------|
| **Bind** | parry_control ≥ PARRY_BIND_CONTROL_THRESHOLD → blade stays in attack line | GuardLineUpdater: bind = same line |
| **Deflect** | parry_control < threshold → blade deflects via get_deflected_line_from_angles | Bilateral angle-based |
| **Tempo** | gauge fill rate; off_balance reduces fill | OFF_BALANCE_GAUGE_FILL_MULT |
| **Parry bonus** | parry_bonus_until after deflect | Slight capacity boost for ~2s |

---

## 2. HEMA Bind (Bindung)

### 2.1 Physical Meaning

- **Bind** = blades in contact, both fencers exerting force. Blade orientation stabilizes at a compromise angle.
- **Soft bind** = light contact; either can disengage or wind.
- **Hard bind** = strong pressure; wind/through is needed to break.

### 2.2 Impact on Weapon Positioning

| Scenario | Current | Potential |
|----------|---------|-----------|
| Same-line parry (high vs high) | parry_control → bind or deflect | ✓ |
| Bind outcome | guard_line = attack_line (blade stays) | Could add **bind_angle**: lerp(attack, guard) by control |
| Post-bind wind | Not modeled | After bind, next action could be wind (change angle from bind) or thrust from bind |
| Parry-counter from bind | parry_thrust/cut use attack_line | Often optimal: thrust from bind = same angle, minimal transition |

### 2.3 Implementation Options

**A: Bind angle blend**

When bind (parry_control high), set guard to weighted blend of attack and defender guard:
```gdscript
# bind_angle = lerp(attack_angle, guard_angle, 0.5) or by parry_control
# Both blades end at compromise angle
```

**B: Bind duration**

Store `bind_until` timestamp. While in bind, both combatants have restricted guard options (must wind to change) or get bonus to riposte from same line.

**C: Wind from bind**

New action: "wind" — change angle from current bind position. Cost: low (blades already in contact). Opens thrust or cut in new line.

---

## 3. Tempo (Vor/Nach)

### 3.1 Physical Meaning

- **Vor** = before; acting first. Initiative.
- **Nach** = after; reacting. Defending.
- **Indes** = in the moment; acting in the same tempo as the opponent.

### 3.2 Impact on Attack Timing

| Concept | Current | Potential |
|---------|---------|-----------|
| Gauge fill | All waiting combatants fill | Vor: last to act fills slower? Or first to act gets bonus? |
| Wind-up | Same for all | Nach (reacting to attack): could have **reaction wind-up** — shorter if countering from good position |
| Parry timing | reaction_time vs effective_wind_up | Late parry = deep Nach (reacting late) |
| Off-balance | Reduces gauge fill | Represents losing Vor (attacker parried → off balance) |

### 3.3 Implementation Options

**A: Tempo state per combatant**

- `tempo_state`: "vor" | "nach" | "neutral"
- Last to successfully attack = Vor (initiative). Parried attacker = Nach.
- Vor: +10% gauge fill? Or next attack costs less wind-up?
- Nach: parry bonus? Or riposte bonus?

**B: Gauge asymmetry**

- Attacker who was parried: gauge fills slower (OFF_BALANCE_GAUGE_FILL_MULT) ✓ Already implemented.
- Defender who parried: parry_bonus_until gives capacity; could also give faster gauge.

**C: Indes actions**

- Actions that occur "in the moment" — e.g. parry-riposte in one tempo.
- Current parry-counter moves (parry_thrust, parry_cut) approximate this: immediate counter after parry.
- Could formalize: when defender parries with high control, they get "indes window" — next action has reduced wind-up if it's a parry-counter and from same line.

---

## 4. Bind → Positioning Summary

| Change | Effort | Effect |
|--------|--------|--------|
| Bind angle blend | Low | Blades end at compromise angle; more realistic blade position |
| Bind duration / wind option | Medium | Enables winding from bind; adds tactical layer |
| Parry-counter from bind = minimal transition | Low | Already true if attack_line matches; explicit bonus? |

---

## 5. Tempo → Timing Summary

| Change | Effort | Effect |
|--------|--------|--------|
| Tempo state (vor/nach) | Medium | Explicit initiative tracking; bonuses/penalties |
| Indes window for parry-counters | Low | When parry_deflect with high control, next parry_thrust/cut has reduced wind-up |
| Gauge fill by tempo | Low | Extend OFF_BALANCE to "last to act" more broadly |

---

## 6. Recommended Phase 1

1. **Bind angle blend**: When parry_control ≥ threshold, set defender guard_angle = lerp(attack_angle, guard_angle, 0.4 + 0.3 * parry_control). Stores continuous angle; guard_line = angle_to_nearest_line for legacy.
2. **Indes parry-counter**: When defender parries (parry_deflect) and chooses parry_thrust/cut, multiply wind-up by 0.85 (faster counter from good position).

---

## References

- HEMA 101: Parries, Binds and Winds
- Liechtenauer: Vor und Nach
- CombatConstants: PARRY_BIND_CONTROL_THRESHOLD, GuardLineUpdater
- DefenseResolutionHandler: parry_clash_context
