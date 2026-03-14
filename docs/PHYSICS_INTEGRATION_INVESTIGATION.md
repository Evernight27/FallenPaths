# Physics Integration: Investigation & Implementation

Investigation and implementation of physics-based combat improvements: penetration angle, reaction state, intended target, target reaction, redundancy removal, and parry_partial guard accuracy.

---

## 1. Penetration Angle from Alignment

**When to apply:** Only when `parry_remaining_ratio == 1.0` (direct hit, no parry/dodge contact). Avoid double-counting with parry/dodge deflection.

**Logic:** Misaligned guard = blade hits at oblique angle. `angle_factor = lerp(1.0, PARRY_PENETRATION_ANGLE_MIN, (1 - alignment) * PARRY_PENETRATION_ALIGNMENT_SCALE)`.

**Implemented:** `compute_and_apply_damage` accepts `alignment`; applies alignment-based oblique only when parry_remaining_ratio >= 1.0.

---

## 2. Target Reaction Affecting Angle

**Already integrated:** Partial dodge and twist dodge set `parry_remaining_ratio`; `compute_and_apply_damage` applies angle factor when ratio < 1.0. No change needed.

---

## 3. Recovery Cause & Reaction State

**recovery_cause:** Set when entering RECOVERING: "skip", "attack_miss", "attack_deflect", "attack_hit". Used by path resolver when defender is RECOVERING + attack_hit = staggered, bias chest.

**defender_ctx:** Passed to `resolve_hit_part`: state, recovery_cause, passive_parry_attempted. Modifiers: staggered → chest; parry attempted + hit → limbs.

**Implemented:** AttackResultApplier sets recovery_cause; AttackResolver builds defender_ctx; AttackPathResolver uses it.

---

## 4. Intended Target (target_part)

**Flow:** CombatAIActionPicker adds target_part when picking attack (from path segment). Options passed to AttackWindUpStarter; pending_attack gets target_part. AttackPathResolver boosts intended_part when in path.

**Implemented:** Full flow from AI pick → pending_attack → path resolver boost.

---

## 5. Redundancy: Arm Interpose vs Path

**INTERPOSE_BASE/INTERPOSE_EXPOSURE:** Superseded by guard-dependent paths. Path puts arms first when guard is high; no separate interpose roll. Kept as constants for potential fallback; not used in resolution.

---

## 6. Parry Partial Guard by Alignment

**Logic:** Only update defender guard_line when alignment >= PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD (0.6). Poor alignment = blade didn't properly meet; guard position uncertain.

**Implemented:** AttackResultApplier computes alignment; calls set_guard_from_move only when align >= threshold.

---

## Summary of Changes

| Component | Change |
|-----------|--------|
| CombatConstants | PARRY_PENETRATION_ALIGNMENT_SCALE, PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD |
| AttackResolver | Pass alignment to compute_and_apply_damage; defender_ctx and intended_part to resolve_hit_part |
| AttackPathResolver | defender_ctx, intended_part; reaction state modifiers; weighted sampling |
| AttackResultApplier | recovery_cause on RECOVERING; parry_partial guard by alignment |
| AttackWindUpStarter | options param; target_part in pending_attack |
| CombatManager | Pass options to WindUpStarter |
| CombatAIActionPicker | Add target_part for attack actions from path segment |
