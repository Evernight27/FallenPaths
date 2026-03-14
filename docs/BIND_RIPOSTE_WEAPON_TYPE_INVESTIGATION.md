# Bind Riposte: Weapon-Type Robustness Investigation

## Purpose

Make the bind riposte bonus **historically accurate** and **robust across weapon types** (sword, axe, mace, dagger, spear, future additions). An axe or mace does not thrust from bind; each weapon has its own natural follow-up.

---

## 1. Historical Context by Weapon

| Weapon | Natural Follow-Up from Bind | Source | Contact Type |
|--------|-----------------------------|--------|--------------|
| **Longsword** | Thrust (primary), cut (Wind) | Liechtenauer: Plough → thrust; Vier Versetzen | stab, cut |
| **Axe / Poleaxe** | Chop/cut, spike thrust (Le Jeu) | Le Jeu de la Hache: cuts, thrusts with spike | cut, stab |
| **Mace** | Strike (blunt) | No explicit treatise; percussion combat | blunt |
| **Dagger** | Thrust | Fiore, Talhoffer | stab |
| **Spear** | Thrust | Fiore | stab |

**Conclusion:** Each weapon has different "bind-favored" contact types. A single rule (e.g. "thrust only") fails for axe and mace.

---

## 2. Current System: What We Already Have

### 2.1 Parry-Counter Moves (is_parry: true)

The move definitions already encode weapon-appropriate ripostes:

| Weapon | Parry Moves | Contact Type |
|--------|-------------|--------------|
| Sword | parry_thrust, parry_cut | stab, cut |
| Axe | parry_chop | cut |
| Mace | parry_strike | blunt |
| Dagger | parry_thrust_dagger | stab |
| Spear | parry_thrust_spear | stab |

These are the **explicit** "parry and counter" techniques. They are the natural follow-ups.

### 2.2 Available Data at Riposte Time

- `atk` (defender): has `parry_was_bind`, `parry_against_id`
- `tgt` (target): the attacker who was parried
- `move_id` / `attack_type`: the chosen move (e.g. "parry_thrust", "oberhau", "parry_chop")
- Weapon: from `_EntityAccess.get_weapon(atk)` — has `get_contact_type(move_id)`, `get_available_attack_types()`
- Move definition: `WeaponConstants.get_move(move_id)` — has `contact_type`, `is_parry`

---

## 3. Implementation Approaches

### Approach A: Move-Level Flag `bind_riposte_eligible`

Add `bind_riposte_eligible: true` to moves that are valid follow-ups from bind.

**Move definitions:**
```gdscript
"parry_thrust": { ..., "bind_riposte_eligible": true },
"parry_cut": { ..., "bind_riposte_eligible": true },
"thrust": { ..., "bind_riposte_eligible": true },
"parry_chop": { ..., "bind_riposte_eligible": true },
"overhead_chop": { ..., "bind_riposte_eligible": true },
"parry_strike": { ..., "bind_riposte_eligible": true },
"overhead_strike": { ..., "bind_riposte_eligible": true },
# etc.
```

**Logic:** Bonus applies when `WeaponConstants.get_move(move_id).get("bind_riposte_eligible", false)`.

**Pros:** Explicit per move; new weapons add flag to appropriate moves.  
**Cons:** Must remember to add flag when adding moves; some redundancy with is_parry.

---

### Approach B: Infer from `is_parry` Moves (Weapon-Derived)

**Rule:** Bind riposte bonus applies when the chosen move's `contact_type` matches **any** of the defender's weapon's `is_parry` moves' contact types.

Example:
- Sword has parry_thrust (stab), parry_cut (cut) → both stab and cut get bonus
- Axe has parry_chop (cut) → only cut gets bonus
- Mace has parry_strike (blunt) → only blunt gets bonus

**Logic:**
```gdscript
static func _weapon_bind_riposte_contact_types(weapon, atk) -> Array:
    var contact_types := []
    if weapon == null or not weapon.has_method("get_available_attack_types"):
        return contact_types
    for move_id in weapon.get_available_attack_types():
        if WeaponConstants.is_parry_move(move_id):
            var ct = weapon.get_contact_type(move_id)
            if ct not in contact_types:
                contact_types.append(ct)
    return contact_types

# In AttackWindUpStarter:
var allowed = _weapon_bind_riposte_contact_types(weapon, atk)
if atk.get("parry_was_bind") and atk.get("parry_against_id") == target_id:
    if weapon.get_contact_type(attack_type) in allowed:
        wind_up_s *= PARRY_BIND_RIPOSTE_WINDUP_MULT
```

**Pros:** Fully data-driven; no new move fields. Adding a weapon with parry_chop automatically gives cut bonus.  
**Cons:** Relies on parry moves existing; weapon with no parry moves gets no bonus (correct).

---

### Approach C: Weapon-Level Config `bind_riposte_contact_types`

Add to weapon definition:

```gdscript
"SWORD": { ..., "bind_riposte_contact_types": ["stab", "cut"] },
"AXE": { ..., "bind_riposte_contact_types": ["cut", "stab"] },
"MACE": { ..., "bind_riposte_contact_types": ["blunt"] },
"DAGGER": { ..., "bind_riposte_contact_types": ["stab"] },
"SPEAR": { ..., "bind_riposte_contact_types": ["stab"] },
```

**Logic:** Bonus when `weapon_def.get("bind_riposte_contact_types", []).has(contact_type)`.

**Pros:** Explicit per weapon; one place per weapon.  
**Cons:** New field; must maintain when adding weapons; duplicates info from parry moves.

---

### Approach D: Move-Level `bind_riposte_mult` (Optional Override)

Moves can optionally specify a multiplier. Default: use Approach B when eligible, else no bonus.

```gdscript
"parry_thrust": { ..., "bind_riposte_mult": 0.6 },
"parry_chop": { ..., "bind_riposte_mult": 0.65 },
```

If present, use it; else fall back to Approach B with default constant.

**Pros:** Fine-grained tuning per move; e.g. parry_thrust gets stronger bonus than normal thrust.  
**Cons:** More fields; usually default is enough.

---

## 4. Recommendation: Approach B (Weapon-Derived from Parry Moves)

**Primary choice: Approach B.**

1. **Historically accurate:** Each weapon's parry moves already encode the correct follow-up (thrust for sword/dagger/spear, chop for axe, strike for mace).
2. **Robust for new weapons:** Add a weapon with `parry_slash` → slash gets bonus. No extra config.
3. **No schema bloat:** No new fields in weapon or move definitions.
4. **Fallback:** Weapon with no parry moves (e.g. improvised) gets no bonus — correct.

**Edge cases:**
- **Axe spike thrust:** Axe has `spike_thrust` but no `parry_spike`. So spike wouldn't get bonus by B. Le Jeu does have thrust from bind. Option: add `parry_spike` to axe, or add `bind_riposte_contact_types: ["cut", "stab"]` for axe only (hybrid with C for that weapon).
- **Sword normal thrust vs parry_thrust:** Both have contact_type stab; parry_thrust is is_parry. Sword has parry_thrust → stab is in allowed set. So normal thrust gets bonus too. Historically fine: thrust from bind is the action, whether you call it parry_thrust or thrust.

---

## 5. Hybrid for Edge Cases

Use B as default. For weapons with multiple valid follow-ups not all represented by parry moves (e.g. axe spike from bind), add optional weapon override:

```gdscript
# In weapon def, optional:
"bind_riposte_contact_types": ["cut", "stab"]  # overrides inferred from parry moves
```

Logic: if weapon has `bind_riposte_contact_types`, use it; else infer from is_parry moves. New weapons can use either.

---

## 6. Implementation Checklist

1. Add `PARRY_BIND_RIPOSTE_WINDUP_MULT := 0.6` to CombatConstants.
2. Add helper `_get_bind_riposte_contact_types(weapon)` that:
   - Returns `weapon_def["bind_riposte_contact_types"]` if present
   - Else builds from weapon's is_parry moves' contact_type
3. In AttackWindUpStarter, after computing wind_up_s:
   - If `atk.get("parry_was_bind")` and `atk.get("parry_against_id") == target_id`:
     - Get `contact_type` from weapon for chosen move_id
     - If contact_type in allowed set: apply multiplier
4. Clear parry_was_bind/parry_against_id on action (already done).

---

## 7. Summary Table

| Approach | Historical Accuracy | Robustness | Schema Change | Best For |
|----------|---------------------|------------|---------------|----------|
| A: Move flag | High | Manual per move | Move def | Explicit control |
| **B: Infer from parry** | **High** | **Automatic** | **None** | **Default** |
| C: Weapon config | High | Manual per weapon | Weapon def | Override when needed |
| D: Move mult | High | Per-move tuning | Move def | Fine-tuning |
| **B + C hybrid** | **High** | **Flexible** | **Optional** | **Production** |

---

## References

- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md
- Le Jeu de la Hache (Wiktenauer, ARMA)
- WeaponConstants.gd (move definitions, is_parry)
