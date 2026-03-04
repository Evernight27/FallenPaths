# Combat: Attack, Parry, and Dodge Data Flow Trace

This document traces how attack, parry, and dodge data flow through the combat system to verify connections are correct.

---

## 1. Attack flow

### 1.1 Commitment (_begin_attack_with_target)

| Data | Source | Stored / used |
|------|--------|----------------|
| target_id | resolve_action(attacker_id, target_id) | → pending_attack.target_id |
| power, follow_through | randf_range(POWER_MIN/MAX, FOLLOW_THROUGH_MIN/MAX) | → pending_attack |
| intensity | (0.5+0.5*power)*(0.5+0.5*follow_through), clamped INTENSITY_MIN..1 | → pending_attack.intensity |
| weapon | atk.node.get_weapon() | Used to pick attack_type, archetype |
| attack_type | weapon.get_available_attack_types() (non-parry) or move_id | → pending_attack.attack_type |
| archetype | WeaponConstants.get_archetype(weapon.get_archetype_id(attack_type)) | → pending_attack.archetype |
| wind_up_s | _wind_up_duration(intensity, windup_mult) / leg / perf_mod | → pending_attack.wind_up_duration |
| leg | atk.node.get_leg_functionality() (CombatManager uses atk.node) | Affects wind_up_duration only |
| atk_perf_mod | atk.node.get_performance_modifier() | Affects wind_up_duration |

**Combatant state:** atk.state = STATE_WIND_UP, atk.pending_attack = { target_id, intensity, power, follow_through, attack_type, archetype, wind_up_duration }.

**Connection check:** Attacker leg health and performance only affect wind-up duration, not damage. Damage uses intensity and attacker stats later in _execute_attack. OK.

### 1.2 Execution (_execute_attack) — read from pending_attack

| Data | From | Used for |
|------|------|----------|
| target_id | pa.target_id | Resolve target, targetable parts |
| intensity | pa.intensity | Recovery duration, parry p_a (via attack_instance), damage (attack_instance) |
| attack_type | pa.attack_type | Parry attack_instance, damage attack_instance |
| archetype | pa.archetype | Parry attack_instance, damage (pre_armor, recovery_mult) |
| velocity_override | pa.get("velocity_m_s", -1.0) | **-1 on first hit; set on partial parry re-entry** → parry v_intent (first time) and damage v_m_s |

**Connection check:** All attack parameters flow from the single pending_attack payload. On partial parry re-entry, velocity_m_s is the only extra key; intensity/attack_type/archetype are unchanged and still read from pa (before we clear pending_attack). OK.

### 1.3 Damage block (after defense / no defense)

| Data | Source | Used for |
|------|--------|----------|
| weapon | atk.node.get_weapon() | All damage math |
| attack_instance | New(attack_type, intensity, archetype, velocity_m_s) | get_effective_velocity_m_s, compute_kinetic_energy_j, pre_armor cut/blunt, penetration |
| velocity_m_s on instance | velocity_override if >= 0 else velocity_m_s_from_intensity(intensity, archetype) | **First hit: from intensity. Partial parry re-entry: from pa.velocity_m_s (reduced).** |
| arm_mod (attacker) | atk.node.get_attack_damage_modifier() | pre_cut_raw, pre_blunt_raw (attacker arm health) |
| atk.stats.strength | Combatant cache (refreshed in _process via _refresh_combatant_stats) | compute_pre_armor_cut/blunt, str_mod in log |

**Connection check:** Partial parry writes attacker.pending_attack["velocity_m_s"] = maxf(v_reduced, v_min). On re-entry, velocity_override is that value, so damage uses reduced velocity. Attack intensity and archetype are still the same locals from the start of _execute_attack. OK.

---

## 2. Parry flow

### 2.1 Can-parry and capacity (defense choice, _execute_attack)

| Data | Source | Used for |
|------|--------|----------|
| wind_up_duration | pa.get("wind_up_duration", 0.5) | effective_wind_up = wind_up_duration * (1 - COMMITMENT_FRACTION) |
| effective_wind_up | As above | Compare to reaction_time |
| reaction_time | tgt.node.get_passive_parry_reaction_time() | **CoreEntity: perception, consciousness, head pain.** Character → _combat_body. |
| can_parry_in_time | reaction_time < effective_wind_up && def_weapon && atk_weapon | Whether parry is an option |
| atk_weapon | atk.node.get_weapon() | m_a, v_intent → p_a |
| v_intent | WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance) | p_a = m_a * v_intent |
| attack_instance (parry) | New(attack_type, intensity, archetype, velocity_override or -1) | **First hit: velocity_override = -1 → full-speed intent for p_a.** Correct. |
| p_a | m_a * v_intent | Attacker momentum; compared to c_d and written on partial parry (reduced v) |
| def_weapon | tgt.node.get_weapon() | m_d for c_d |
| m_d, s_d | def_weapon.mass, tgt.stats.get("strength", 100) | c_d_full = m_d * parry_speed * (s_d / PARRY_STRENGTH_NORM) |
| def_perf | tgt.node.get_performance_modifier() | c_d_full *= perf (pain/consciousness) |
| arm_mod (defender) | tgt.node.get_attack_damage_modifier() | **CoreEntity: get_attacking_arm(), get_arm_functionality(arm), arm pain.** c_d_full *= arm_mod → parry tied to arm health. |
| time_to_react | effective_wind_up - reaction_time | capacity_mult = clamp(time_to_react / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S) |
| parry_readiness | _get_passive_parry_readiness(tgt) | STATE_WAITING=1, RECOVERING=lerp(early, late) |
| parry_off_balance | _is_off_balance(tgt) | c_d *= OFF_BALANCE_PARRY_CAPACITY_MULT if true |
| choose_parry | Expected-damage comparison: parry when E_parry ≤ E_dodge and viable; dodge when E_dodge < E_parry or full_dodge_prob ≥ PARRY_PREFER_DODGE_FULL_THRESHOLD (0.12). PARRY_DODGE_STRENGTH_RATIO (2.2) for block viable. | See AttackResolver |

**Connection check:** Parry uses defender’s **live** arm (get_attack_damage_modifier), **live** performance and reaction time (node methods). Defender strength is from **cached** tgt.stats (refreshed each frame in _process). So parry is correctly tied to arm health, reaction, and strength. OK.

### 2.2 Resolve parry (_resolve_parry_with_momentum)

| Data | Source | Used for |
|------|--------|----------|
| p_a, c_d | Arguments (from _execute_attack) | deflected = (c_d >= p_a * PARRY_DEFLECT_THRESHOLD)  # 1.08 |
| pa | attacker.pending_attack | intensity, attack_type, archetype for attack_instance; **not** velocity_m_s (v_intent = full) |
| v_intent | WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance) | Full intent for v_min = v_intent * PARRY_V_MIN_FRACTION |
| remaining_momentum | p_a - c_d | v_reduced = remaining_momentum / m_a |
| velocity_m_s (partial) | maxf(v_reduced, v_min) | **Written to attacker.pending_attack["velocity_m_s"]** → used on re-entry as velocity_override in damage. |
| _execute_attack(attacker_id) | Called on partial | Re-entry with same pa (plus velocity_m_s, passive_parry_attempted). |

**Connection check:** Partial parry writes the only modified field (velocity_m_s) into pending_attack; re-entry uses it for damage velocity and skips a second defense (already_used_defense). Full deflect clears pending_attack and puts attacker in recovery. OK.

---

## 3. Dodge flow

### 3.1 Defense choice

| Data | Source | Used for |
|------|--------|----------|
| defense_choice | "parry" if choose_parry else "dodge" | If "dodge", only dodge is attempted; no parry. |
| already_used_defense | pa.get("passive_parry_attempted", false) | If true (partial parry follow-through), skip both dodge and parry → go to damage. |

**Connection check:** One defense per attack; no mixing. OK.

### 3.2 Dodge roll (when defense_choice == "dodge")

| Data | Source | Used for |
|------|--------|----------|
| dodge_chance | tgt.node.get_dodge_chance() | **CoreEntity: get_leg_functionality(), get_performance_modifier(), leg pain, agility, perception.** Character → _combat_body.get_dodge_chance(). |
| dodge_roll | randf() | Tiers: roll < eff_dodge × DODGE_FULL_THRESHOLD (0.4) → full dodge; roll < eff_dodge → partial (parry_remaining_ratio); else → hit. |

**CoreEntity.get_dodge_chance():**
- leg = get_leg_functionality() (both legs, bone factor)
- perf = get_performance_modifier() (pain/consciousness)
- leg_pain_mod = pain modifier for region "legs"
- dodge_stat_factor = (agility + perception) / 200, clamped 0.5..1.5
- return DODGE_CHANCE_AT_FULL_SPEED (0.10) * dodge_stat_factor * leg * perf * leg_pain_mod

**Connection check:** Dodge is driven by leg health, leg pain, agility, perception, and general performance. All from the defender node (CoreEntity or Character→CombatBody). OK.

---

## 4. Cross-checks

### 4.1 Partial parry → damage (no second defense)

- _resolve_parry_with_momentum (partial) sets `attacker.pending_attack["velocity_m_s"]` and calls _execute_attack(attacker_id).
- Before that, in _execute_attack we set `pa["passive_parry_attempted"] = true` when choosing parry.
- On re-entry: pa has passive_parry_attempted == true → already_used_defense == true → we skip dodge and parry, log "Partial parry follow-through", then clear pending_attack and run damage.
- Damage uses local velocity_override (read at top of _execute_attack from pa), which is the reduced value. **Connected.**

### 4.2 Attacker/defender stats

- **Attacker:** atk.stats (strength, etc.) and atk.node (weapon, arm modifier, performance) are used. Stats are refreshed in _process via _refresh_combatant_stats from entity (CoreEntity); node methods are live.
- **Defender:** tgt.stats used for parry strength (cached); tgt.node used for reaction time, weapon, arm modifier, performance, dodge chance (all live). **Consistent.**

### 4.3 Character vs CoreEntity

- **Character:** Combat-related methods (get_weapon, get_attacking_arm, get_attack_damage_modifier, get_dodge_chance, get_passive_parry_reaction_time, get_leg_functionality, get_performance_modifier, etc.) delegate to _combat_body (CoreEntity). So for party members the data flow is Character → CoreEntity. **Connected.**

---

## 5. Summary

| Flow | Data path | Status |
|------|-----------|--------|
| Attack commit | resolve_action → _begin_attack_with_target → pending_attack (intensity, wind_up_duration, etc.) | OK |
| Attack execute | pending_attack → _execute_attack locals → miss → defense → damage; velocity_override from pa on re-entry | OK |
| Attack damage | weapon, attack_instance (intensity, velocity_override), atk.stats.strength, atk.node.get_attack_damage_modifier() | OK |
| Parry decision | wind_up_duration from pa; reaction_time, def_weapon, atk_weapon from nodes; p_a, c_d with defender arm_mod and strength | OK |
| Parry resolve | p_a, c_d → full or partial; partial writes velocity_m_s, re-calls _execute_attack | OK |
| Parry → damage | Re-entry with already_used_defense, no second defense, velocity_override = reduced | OK |
| Dodge | defense_choice == "dodge" only; get_dodge_chance() from defender node (leg, agility, perception, perf) | OK |
| No mixing | already_used_defense skips defense on partial follow-through; one of dodge or parry per attack | OK |

**Conclusion:** Attack, parry, and dodge data flows are consistent and correctly connected. Partial parry reduces velocity and that velocity is used for damage on re-entry with no second defense roll.
