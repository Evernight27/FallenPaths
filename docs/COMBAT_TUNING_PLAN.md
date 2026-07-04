# Combat Tuning — Fix Plan

**Date:** 2026-07-03
**Triggered by:** D001 soak + regression harness analysis of spear KE, sword/axe damage, parry outcomes, follow-through fairness, miss rates.
**Status:** Implemented + expanded + second pass (2026-07-03). All 6 original fixes applied. Expansions: SPEAR/DAGGER coupling_cut, harness tests, comments, stale fallback fix, asymmetric block test.

---

## Summary

Five combat tuning issues identified through double-pass code tracing and verification against harness soak data (`.d001_soak_out.txt`, `.calibration_audit.txt`). All fixes are low-effort constant changes or single-conditionals in existing modules. No new files, no API additions, no structural refactors.

---

## Fix 1: Spear KE Overpowered

### Problem
Spear `pole_swing` is classified as `ARCHETYPE_HEAVY_BLUNT` (weapon/WeaponConstants.gd:187). Combined with blunt velocity band vmax=17.5 m/s, a 2m spear shaft produces ~245J at i=0.85 due to rotational inertia (I≈1.53 kg·m²) and the `0.5 * I * omega²` model. Reference max for the archetype is 130J. Long-weapon geometry multiplier (~+15%) compounds the issue.

### Verification
- weapon/WeaponConstants.gd:381-425 — spear template definition
- weapon/WeaponConstants.gd:187 — `pole_swing` archetype = `ARCHETYPE_HEAVY_BLUNT`
- weapon/WeaponConstants.gd:465-515 — archetype constants (velocity_factor=1.0, curve=1.12)
- weapon/ImpactVelocityModel.gd — blunt velocity band vmax=17.5 m/s; long-weapon geometry multiplier +15%

### Fix
In `weapon/ImpactVelocityModel.gd`, lower the `blunt` velocity band max from 17.5 to ~12.0 m/s for polearm-length weapons, OR add a spear-specific override. Alternative: create `ARCHETYPE_POLEARM` in WeaponConstants with curve ≤ 1.0 and v_factor ≤ 0.85.

### Files
- `weapon/ImpactVelocityModel.gd` — velocity band vmax adjustment
- `weapon/WeaponConstants.gd` — archetype constants (if new archetype created)

---

## Fix 2: Sword / Axe Underpowered (Cut vs Blunt Damage Gap)

### Problem
SWORD coupling_cut=0.84 and AXE coupling=0.86 are significantly lower than MACE coupling_blunt=1.06 — a ~23% damage multiplier gap. Commit fractions further reduce cut velocity (stab=0.58, cut=0.72, overhead=0.78) while blunt slip velocity is not reduced. The `cut_ratio` split (0.75 for sword) routes most cut damage through the sqrt(KE) model, which is less efficient than the linear momentum model used for blunt.

### Verification
- weapon/WeaponConstants.gd:213-252 — SWORD strike_physics (coupling_cut=0.84)
- weapon/WeaponConstants.gd:279-288 — AXE strike_physics (coupling=0.86)
- combat/CombatConstantsParryChoice.gd:commit fractions (stab=0.58, cut=0.72, overhead=0.78, blunt=0.76)
- weapon/StrikeRealismProfile.gd — velocity_intent_mult_from_pa applies no special bonus to cuts

### Fix
Increase `coupling_cut` in SWORD strike_physics from 0.84 → 0.92. Increase AXE from 0.86 → 0.92. Also raised SPEAR from 0.87 → 0.92 and DAGGER from 0.88 → 0.92 for consistency across all cut-capable weapons.

### Files
- `weapon/WeaponConstants.gd:231-240` — SWORD strike_physics coupling_cut → 0.92
- `weapon/WeaponConstants.gd:279-288` — AXE strike_physics coupling_cut → 0.92
- `weapon/WeaponConstants.gd:367` — DAGGER coupling_cut → 0.92
- `weapon/WeaponConstants.gd:413` — SPEAR coupling_cut → 0.92

---

## Fix 3: Deflects Rare on Balanced Entity Matchups

### Problem
Parry block requires BOTH defender weapon mass >= 90% of attacker's mass AND defender strength >= 95% of attacker's strength. In tuning harness runs (balanced entities), this is hard to achieve, so `is_block_parry` fails and only edge_deflect is possible — which requires alignment >= 0.6 AND c_d >= p_a * 1.08. Headless AI soak data (`deflect=3 bind=4 partial=0`) shows deflects DO occur in normal combat with varied entity stats; the issue is specifically balanced matchups.

### Verification
- combat/CombatConstantsParry.gd:26-27 — PARRY_BLOCK_MASS_THRESHOLD=0.9, PARRY_BLOCK_STR_THRESHOLD=0.95
- .d001_soak_out.txt:18 — actual soak data shows deflects working with varied entities
- combat/CombatD001SoakSanity.gd:516-543 — plausibility validator requires deflect >= 1 and bind >= 1

### Fix
Lower `PARRY_BLOCK_MASS_THRESHOLD` from 0.9 → 0.75. Lower `PARRY_BLOCK_STR_THRESHOLD` from 0.95 → 0.85. This allows deflects on evenly matched combatants while still preventing them when the attacker has a clear advantage.

### Files
- `combat/CombatConstantsParry.gd:26-27` — block threshold constants

---

## Fix 4: Edge Deflect Threshold Too High

### Problem
Edge deflect requires c_d >= p_a * 1.08 (PARRY_DEFLECT_THRESHOLD). But parry_c_d gets reduced by 12+ multiplicative factors (alignment, stamina, exhaustion, spacing). Even when block_parry is not viable, the surplus threshold is too high for edge_deflect to trigger in practice on tuned entities.

### Verification
- combat/CombatConstantsParry.gd:6 — PARRY_DEFLECT_THRESHOLD=1.08
- combat/DefenseChoiceResolver.gd — 12+ multiplicative reductions to parry_c_d
- combat/DefenseResolutionHandler.gd — edge_deflect branch logic

### Fix
Lower `PARRY_DEFLECT_THRESHOLD` from 1.08 → 1.03-1.04. This reduces the surplus required for an edge deflect without making them too common.

### Files
- `combat/CombatConstantsParry.gd:6` — PARRY_DEFLECT_THRESHOLD constant

---

## Fix 5: Follow-Through Unfair on Good Parries

### Problem
After any parry_partial, `_execute_attack()` is always re-entered with no quality gate. Twist dodge uses half efficiency (PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY=0.5) and a time_factor floor of 0.15 for fast parries, making it nearly impossible even on good parries. The defender has no meaningful choice — blade contact always transfers force forward.

### Verification
- combat/AttackResultApplier.gd:525 — follow-through always triggers _execute_attack() re-entry
- combat/CombatConstantsAttackPath.gd:105 — PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY=0.5, time_factor floor ~0.15
- combat/DefenseResolutionHandler.gd:82-83 — follow-through velocity reduction formulas

### Fix
Add a parry quality gate before `_execute_attack()` re-entry in `AttackResultApplier.gd`: if `parry_remaining_ratio <= 0.1`, skip the re-entry entirely (treat as full stop, similar to deflect). Increase `PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY` from 0.5 → 0.65-0.7. Raise time_factor floor from 0.15 → 0.35.

### Files
- `combat/AttackResultApplier.gd:525` — add conditional gate before _execute_attack() call
- `combat/CombatConstantsAttackPath.gd:105` — PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY → 0.67
- `combat/DefenseResolutionHandler.gd:82` — time_factor floor → 0.35

### Harness Tests Added
- `combat/CombatRegressionHarness.gd:_run_follow_through_gate_at_low_remaining_ratio` — verifies gate threshold logic (ratio > 0.1 triggers follow-through, <= 0.1 skips)
- `combat/CombatRegressionHarness.gd:_run_block_threshold_balance_test` — verifies balanced SWORD vs SWORD passes both block thresholds at new values (mass 0.75, str 0.85)

---

## Fix 6: Cut-to-Blunt Shift Too Aggressive on Parry

### Problem
PARRY_CUT_TO_BLUNT_SHIFT=0.45 means a parry with ratio=0.6 shifts cut_ratio by 27 percentage points toward blunt. This disproportionately hurts cut weapons (swords/axes) that are already underpowered due to lower coupling values, compounding the damage gap.

### Verification
- combat/CombatConstantsParry.gd:35 — PARRY_CUT_TO_BLUNT_SHIFT=0.45
- combat/DefenseResolutionHandler.gd — cut_ratio shift logic on parry exchange

### Fix
Reduce `PARRY_CUT_TO_BLUNT_SHIFT` from 0.45 → 0.25-0.30. This still provides some damage type shift on parry but doesn't compound the sword/axe underpowering issue.

### Files
- `combat/CombatConstantsParry.gd:35` — PARRY_CUT_TO_BLUNT_SHIFT constant

---

## Fix Priority (Impact × Effort)

| # | Fix | Impact | Effort | Effort Details |
|---|-----|--------|--------|----------------|
| 1 | Spear KE correction | High | Low | 1 line in ImpactVelocityModel.gd |
| 2 | Cut coupling increase (all weapons) | High | Low | 4 numbers in WeaponConstants.gd (SWORD, AXE, SPEAR, DAGGER) |
| 3 | Block threshold reduction | Medium-High | Low | 2 constants in CombatConstantsParry.gd |
| 4 | Follow-through quality gate | Medium | Medium | Conditional + 2 constants across 2 files |
| 5 | Deflect threshold reduction | Lower | Low | 1 constant in CombatConstantsParry.gd |
| 6 | Cut-to-blunt shift reduction | Lower | Low | 1 constant in CombatConstantsParry.gd |

---

## Expansions (beyond original plan)

- **SPEAR coupling_cut** raised from 0.87 → 0.92 — spear slash moves benefit from same cut balance fix as sword/axe.
- **DAGGER coupling_cut** raised from 0.88 → 0.92 — dagger cuts now consistent with other weapons.
- **Follow-through gate harness test** (`_run_follow_through_gate_at_low_remaining_ratio`) — verifies the new `remaining_ratio > 0.1` gate logic at AttackResultApplier.gd:526.
- **Block threshold balance test** (`_run_block_threshold_balance_test`) — verifies balanced SWORD vs SWORD passes both block thresholds at new values (mass 0.75, str 0.85).

---

## Second pass improvements

### P1 — Stale fallback defaults fixed
- `combat/DefenseChoiceResolver.gd:389-390` — fallback defaults for `block_mass_threshold` and `block_str_threshold` changed from hardcoded `0.9` / `0.95` to reference `CombatConstants.PARRY_BLOCK_MASS_THRESHOLD` / `PARRY_BLOCK_STR_THRESHOLD` directly. If `parry_cfg` is ever constructed with missing keys, it will now use the live threshold values instead of stale defaults.

### P2 — Integration test for follow-through gate
- `_run_follow_through_integration_gate` — exercises the actual gate logic (ratio 0.05 should skip `_execute_attack`, ratio 0.15 should trigger it) rather than just testing boolean comparisons in isolation.

### P2 — Asymmetric block threshold test
- `_run_block_threshold_asymmetric_test` — tests DAGGER vs SPEAR (mass ratio 0.167, well below 0.75 threshold — must NOT qualify for block parry) and AXE vs MACE (mass ratio 0.883, above 0.75 — should pass mass check).

### P3 — Inline comments on all tuning changes
- `combat/AttackResultApplier.gd:526` — comment explaining follow-through gate rationale
- `combat/DefenseResolutionHandler.gd:83` — comment on time_factor floor change from 0.15 → 0.35
- `weapon/ImpactVelocityModel.gd:44` — comment on SPEAR blunt vmax reduction from 17.5 → 12.0

---

## Implementation Notes

- All fixes are maintainable changes — no new files, no APIs, no structural refactors.
- Each fix is isolated and can be tested independently via D001 soak runs.
- After all fixes are applied, run `.d001_soak_out.txt` harness and compare parry_stats, damage distributions, and miss rates against baseline.
- If a single archetype change (ARCHETYPE_POLEARM) is preferred over velocity band tweaking for Fix 1, coordinate with the weapon template section in WeaponConstants.gd to avoid conflicts with existing polearm moves.
- The follow-through quality gate (Fix 5) changes combat flow behavior — test thoroughly with full engagement sequences (wind-up → strike → parry → follow-through → resolve).
