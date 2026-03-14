# Physics Realism: Systems Requiring Decisions — Investigation

After implementing the 4-line guard system (Liechtenauer: high, low, left, right), this doc identifies **other systems that need design decisions** to prioritize physics-based realism. Ordered by impact and dependencies.

---

## 1. What Is Implemented (4-Line System)

| Component | Status | Location |
|-----------|--------|----------|
| LINE_ANGLE_DEG table | Done | CombatConstants.gd |
| get_line_alignment(attack_line, guard_line) | Done | CombatConstants.gd |
| attack_line per move | Done | WeaponConstants.gd (_move_definitions_build) |
| guard_line per combatant | Done | CombatManager.gd (_register_combatant); default "high" |
| BP2: parry_c_d *= alignment | Done | DefenseChoiceResolver.gd |
| BP3: variance ∝ 1/alignment | Done | AttackResolver.gd |
| BP5: geometric leak | Done | AttackResolver.gd |
| Constants: PARRY_ALIGNMENT_FLOOR, GEOMETRIC_LEAK_MAX | Done | CombatConstants.gd |

---

## 2. Guard Line Dynamics (Priority: Medium)

**Current:** Combatants have `guard_line` defaulting to "high." It never changes.

**Question:** Should `guard_line` evolve based on combat state?

| Option | Description | Physics Basis |
|--------|-------------|---------------|
| **A: Static default** | Always "high" (current). | Simplest; neutral guard is high (Vom Tag). |
| **B: After attack** | Last attack's line becomes new guard. E.g. oberhau → guard_line = "high." | Liechtenauer: cut ends in a guard; next defense starts from that position. |
| **C: Explicit choice** | Player/AI chooses guard_line each turn or when idle. | Historical: fighter chooses where to hold blade. |
| **D: Blend** | Default "high"; after attack, set guard_line = attack_line of that move. No explicit choice. | B without UI; automatic continuity. |

**Recommendation:** **Option D** — set `tgt["guard_line"] = attack_line` when defender finishes an attack (or when attacker recovers from their attack, if defender was last to act). Gives weapon-position continuity without new UI. Defer explicit guard choice (C) until/if you add active defense.

**Data:** `attack_line` from move; defender's last move_id must be stored (e.g. `last_move_id` on combatant) or inferred from state. If defender didn't attack, keep current guard_line.

---

## 3. Physically Realistic Afterblow (Priority: High)

**Current:** No afterblow. When A hits B, B's `pending_attack` (if any) is not resolved.

**Physics:** A creature hit mid-swing can complete a *previously planned* attack **iff** the blow wasn't intense enough to hinder the action (part hit, damage, intensity, outcome).

**Decisions:**

| Item | Options | Recommendation |
|------|---------|---------------|
| **Hindrance model** | Score (0–1), hard thresholds, per-part damage, KE threshold | Hybrid: immediate disqualifiers + hindrance score (LINE_GUARD doc §3.5) |
| **Hook point** | After `compute_and_apply_damage` returns, before recovery/state transition | In `CombatManager` after `resolve_attack` returns "hit"; check `tgt.pending_attack` |
| **Flow** | A hits B → apply damage → check B.pending_attack targets A → hindrance → if allowed, resolve B→A | See LINE_GUARD doc §3.6 |
| **Data** | hit_part, final_cut/blunt/bone, outcome, intensity, B.pending_attack, get_attacking_arm | All available in take_result and combatant state |

**IMPLEMENTED:** `AfterblowHandler.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)` called from CombatManager when action=="hit". Hybrid hindrance; stance from dominant_hand; damage *= (1-hindrance); full resolution for B→A and B→C. See combat/AfterblowHandler.gd.

---

## 4. Arm Interpose (BP6) — **Implemented**

**Implemented:** When hit part would be head, roll `p_interpose = INTERPOSE_BASE × exposure(attack_line, guard_line)`. If success, redirect to left_arm or right_arm. Exposure table in CombatConstants.INTERPOSE_EXPOSURE; INTERPOSE_BASE = 0.10.

**Location:** AttackResolver.gd (before compute_and_apply_damage).

---

## 5. Diagonal Cut Line Roll (BP1) — Optional

**Current:** Diagonal moves (oberhau, diagonal_chop) have single primary `attack_line`.

**Physics:** Zornhau crosses high and left. Which line the guard "meets" first varies by trajectory.

| Option | Description |
|--------|-------------|
| **Keep primary** | oberhau = "high", diagonal_chop = "left." Simple. |
| **Weighted roll** | At resolve, roll: 65% high, 35% left for descending diagonal. Adds variance. |

**Recommendation:** **Keep primary** for now. Weighted roll (Option P5) can be added later if diagonal parries feel too binary.

---

## 6. Variance Constant (PARRY_GEOMETRY_VARIANCE_BASE)

**Current:** Geometry variance is multiplicative with technique variance: `variance_eff *= clamp(1/alignment, 1, 2.5)`. PARRY_GEOMETRY_VARIANCE_BASE exists but is not used (we scale technique variance instead).

**Doc suggested:** Separate geometry variance `= PARRY_GEOMETRY_VARIANCE_BASE × clamp(1/alignment, 1, 2.5)` instead of scaling technique.

**Decision:** Keep current approach (technique × geometry scale) vs replace with pure geometry variance. Current is simpler and preserves agility's effect on technique variance. **Recommendation:** Keep as-is; tune if parry outcomes feel off.

---

## 7. Measure / Distance — Defer

**Current:** No distance. All attacks "in range" when chosen.

**Physics:** At bind (close), thrust from bind; at long measure, cuts may fall short.

**Recommendation:** **Defer.** Would require `steps_to_opponent` or abstract measure bands. Significant scope increase.

---

## 8. Weapon Position Continuity (last_guard)

**Current:** No `last_guard`. Each parry uses current `guard_line` only.

**Physics:** After a cut, weapon is in a guard (e.g. Plough). Next parry from that position is faster.

**Recommendation:** **Defer** until guard_line dynamics (§2) are decided. If guard_line evolves after attack (Option D), that partly captures continuity. Explicit wind-up cost from guard transition (`windup_mult × transition_factor`) is a later enhancement.

---

## 9. Thrust Line

**Current:** All thrusts use `attack_line = "high"` (point threatens center/high).

**Alternative:** Add "center" as fifth line for thrusts. Would require extending LINE_ANGLE_DEG to 5×5.

**Recommendation:** **Keep "high"** for thrusts. Four lines suffice; "center" adds complexity with limited benefit.

---

## 10. Calibration and Validation

| Metric | Target (HEMA) | How to Validate |
|--------|---------------|-----------------|
| Blade-blade share of contacts | 57–80% (longsword) | Log parry_deflect + parry_partial vs hit; tune alignment floor, leak, variance |
| Wrong guard = partial, not total fail | — | alignment floor 0.15 ensures some parry effect even at 90° |
| Outcome variance when wrong | — | Playtest; adjust GEOMETRIC_LEAK_MAX, variance scale |

**Recommendation:** Add optional debug logging (alignment, parry_c_d before/after, variance_eff, geometric_leak, remaining_ratio) behind a flag for calibration runs. Tune PARRY_ALIGNMENT_FLOOR (0.15), GEOMETRIC_LEAK_MAX (0.35) to hit 57–80% parry share in longsword vs longsword.

---

## 11. Decision Summary (Recommended Order)

| Order | System | Decision | Effort |
|-------|--------|----------|--------|
| 1 | **Afterblow** | Implement hybrid hindrance model; hook after damage | Medium |
| 2 | **Guard line dynamics** | Option D: set guard_line = attack_line after attacker's recovery | Low |
| 3 | **Calibration** | Add debug logging; tune to 57–80% parry | Low |
| 4 | Arm interpose | Defer | — |
| 5 | Diagonal line roll | Defer | — |
| 6 | Measure, last_guard, thrust center | Defer | — |

---

## References

- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md (Parts 3, 4, 4B)
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- COMBAT_PARRY_MISS_RESEARCH.md
- CombatManager.gd, AttackResolver.gd, DefenseChoiceResolver.gd
- CombatConstants.gd (LINE_ANGLE_DEG, get_line_alignment)
