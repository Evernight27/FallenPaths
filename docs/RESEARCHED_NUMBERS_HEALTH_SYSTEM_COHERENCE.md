# Researched Numbers vs. Health System Coherence

This document audits whether the aggressive realism constants (DAMAGE_KE_SCALE 2.0, MIN_DAMAGE_TO_SEVER 10, limb totals) are appropriate for each health system in the project.

---

## 1. Tissue / Bone / Blunt Pools (CoreEntity)

| System | Constants | Coherence |
|--------|-----------|-----------|
| body_cutting, body_blunt | body_max from SpeciesResource | ✓ Arm 12, leg 16 tissue; bone 8/12. Correctly initialized. |
| bone_health | bone_max from SpeciesResource | ✓ Matches bone thresholds in BodyPartConstants. |
| Severance | MIN_DAMAGE_TO_SEVER 10 | ✓ Blocks weak hits; 10 damage ≈ 25 J floor. |
| Early severance | combined_max = body_max + bone_max | ✓ Arm 20, leg 28. remaining_ratio uses rem_cut + rem_bone. Correct. |
| Severance ease | tissue_ratio = (cur_cut + cur_blunt) / (max_tissue * 2) | ✓ Both pools start at max_tissue; combined max = 2×. Correct. |

**Verdict:** Tissue, blunt, and bone pools are coherent with researched limb totals.

---

## 2. Bone Damage (BodyPartConstants)

| Part | Threshold | Fraction | With damage scale 2.0 |
|------|-----------|----------|------------------------|
| head | 3 | 0.55 | First bone at 3 damage (~2.25 J); full break ~18 total |
| arm | 5 | 0.38 | First bone at 5 (~6.25 J); full break ~26 total (~169 J) |
| leg | 6 | 0.42 | First bone at 6 (~9 J); full break ~35 total (~306 J) |
| chest | 8 | 0.30 | First bone at 8 (~16 J) |

**Research:** Arm bones 12–45 J fracture; leg 25–35 J. Thresholds (3–8) represent "first involvement"; full break requires higher total. Sub-region thresholds (elbow 3, hand 4) add granularity.

**Verdict:** Bone thresholds are in abstract damage units; they scale with DAMAGE_KE_SCALE. No change needed.

---

## 3. Severity & Bleeding (BleedingConstants)

| Constant | Value | With new part maxes |
|----------|-------|---------------------|
| SEVERITY_PERCENTAGE_MODERATE | 0.25 | Arm 12: 3 damage = moderate |
| SEVERITY_PERCENTAGE_SEVERE | 0.5 | Arm 12: 6 damage = severe |
| SEVERITY_PERCENTAGE_CRITICAL | 0.75 | Arm 12: 9 damage = critical |
| SEVERITY_ABSOLUTE_MINOR | 2 | Overrides % for tiny hits on large parts |
| SEVERITY_ABSOLUTE_SEVERE | 5 | 5+ damage = at least severe |
| SEVERITY_ABSOLUTE_CRITICAL | 10 | 10+ damage = at least critical |

**Interaction:** Severity = max(percentage-based, absolute). For chest (max 30): 10 damage = 33% (moderate) vs absolute 10 (critical) → critical. A 10-damage hit (~25 J) on chest can be a deep wound; critical is plausible.

**Verdict:** Severity thresholds are appropriate. Absolute 2/5/10 scale with damage; typical sword ~31, so 10 is a solid hit.

---

## 4. Pain & Consciousness (PainConsciousnessConstants, SpeciesResource)

| System | Before (body_max sum 112) | After (body_max sum 96) | Issue |
|--------|---------------------------|-------------------------|-------|
| pain_reference | 112/18.7 ≈ 6.0 | 96/32 ≈ 3.0 | ~2 moderate hits to first effect (research-aligned) |
| NRS first effect | 4 | 4 | ~4 moderate hits to reach |
| Intended behavior | 1 moderate hit ≈ 1 effective pain | 1 moderate hit ≈ 1.2 effective | Pain effects trigger ~20% sooner |

**Research-aligned fix:** Divisor **32** (PAIN_MEDICAL_RESEARCH_SYNTHESIS.md). Human ref = 96/32 = 3. ~2 moderate hits to NRS 4 (first effect). Krebs: NRS 4-6 = 2.67× functional impairment; acute trauma 57% present NRS 5-10.

**Goblin:** 48/32 = 1.5. Smaller species = lower ref = pain effects trigger sooner (realistic).

---

## 5. Pain Shock (PainConsciousnessConstants)

| Constant | Value | With scale 2.0 |
|----------|-------|----------------|
| PAIN_SHOCK_DURATION_IMPACT_REFERENCE | 10.0 | 10 damage = 1.0× duration |
| Typical sword hit | ~31 damage | 31/10 = 3.1×, capped at 2.0× |
| IMPACT_MAX_MULTIPLIER | 2.0 | Heavy hits double shock duration |

**Verdict:** Impact reference 10 is appropriate. Typical hits (15–35 damage) scale shock duration correctly.

---

## 6. Healing (HealingConstants)

Healing durations are severity-based (minor/moderate/severe/critical), not damage-scale. Same severity → same duration. No change needed.

---

## 7. Blood Volume (BleedingConstants)

Death at BLOOD_LOSS_DEATH_THRESHOLD (35%); critical at 30%. These are percentage-based. Bleeding rates scale with severity. No change needed.

---

## Summary of Required Adjustments

| Adjustment | File | Change |
|------------|------|--------|
| Pain reference divisor | SpeciesResource.gd | 32 (human ref=3; ~2 moderate hits to first effect; research-aligned) |

All other systems are coherent with the researched numbers.
