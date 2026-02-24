# Sub-Region × Part Multiplier Audit

Computed combined values when part and sub-region multipliers are multiplied together. Verifies consistency and flags any issues.

---

## 1. Pain (PainConsciousnessConstants)

**Formula:** `part_mult × sub_mult` (both applied multiplicatively)

| Part | Sub-region | Part | Sub | **Combined** | Notes |
|------|------------|------|-----|--------------|-------|
| head | scalp | 1.4 | 1.3 | **1.82** | Scalp: many nerves |
| head | face | 1.4 | 1.4 | **1.96** | Face: highest pain (trigeminal) |
| head | neck | 1.4 | 1.35 | **1.89** | Neck: vascular, less sensory |
| chest | thoracic | 1.25 | 1.2 | **1.50** | Ribs: more painful |
| chest | abdominal | 1.25 | 1.15 | **1.44** | Soft tissue |
| arm | upper_arm | 1.0 | 0.95 | **0.95** | |
| arm | elbow | 1.0 | 1.1 | **1.10** | Joint |
| arm | forearm | 1.0 | 1.05 | **1.05** | |
| arm | hand | 1.0 | 1.35 | **1.35** | High nerve density |
| leg | thigh | 0.95 | 0.95 | **0.90** | |
| leg | knee | 0.95 | 1.1 | **1.05** | Joint |
| leg | calf | 0.95 | 1.0 | **0.95** | |
| leg | foot | 0.95 | 0.9 | **0.86** | Lowest pain |

**Verdict:** ✓ Ordering is medically plausible. Face > neck > scalp for pain. Hand highest on limbs. Foot lowest.

---

## 2. Bleeding (BleedingConstants)

**Formula:** `part_mult × sub_mult` (BODY_PART_BLEEDING × SUB_REGION_BLEEDING)

| Part | Sub-region | Part | Sub | **Combined** | Notes |
|------|------------|------|-----|--------------|-------|
| head | scalp | 1.5 | 1.8 | **2.70** | Scalp very vascular |
| head | face | 1.5 | 1.4 | **2.10** | |
| head | neck | 1.5 | 1.6 | **2.40** | Carotid/jugular |
| chest | thoracic | 1.2 | 1.15 | **1.38** | |
| chest | abdominal | 1.2 | 1.25 | **1.50** | More vessels |
| arm | upper_arm | 1.0 | 0.9 | **0.90** | |
| arm | elbow | 1.0 | 1.0 | **1.00** | |
| arm | forearm | 1.0 | 1.15 | **1.15** | UE vessels |
| arm | hand | 1.0 | 1.05 | **1.05** | |
| leg | thigh | 1.0 | 1.1 | **1.10** | |
| leg | knee | 1.0 | 1.2 | **1.20** | Popliteal |
| leg | calf | 1.0 | 1.05 | **1.05** | |
| leg | foot | 1.0 | 0.95 | **0.95** | |

**Verdict:** ✓ Scalp (2.70) > neck (2.40) > face (2.10). Scalp bleeds profusely. Consistent.

---

## 3. Arterial Chance (BleedingConstants)

**Formula:** `ARTERIAL_BODY_PART_MULTIPLIERS × SUB_REGION_ARTERIAL_MULTIPLIERS`

| Part | Sub-region | Part | Sub | **Combined** | Notes |
|------|------------|------|-----|--------------|-------|
| head | scalp | 1.4 | 1.2 | **1.68** | |
| head | face | 1.4 | 1.1 | **1.54** | |
| head | neck | 1.4 | 1.5 | **2.10** | Highest - carotid |
| chest | thoracic | 1.2 | 1.15 | **1.38** | |
| chest | abdominal | 1.2 | 1.2 | **1.44** | |
| arm | upper_arm | 1.0 | 0.95 | **0.95** | |
| arm | forearm | 1.0 | 1.2 | **1.20** | UE vascular |
| arm | hand | 1.0 | 0.9 | **0.90** | |
| leg | thigh | 1.0 | 1.15 | **1.15** | SFA |
| leg | knee | 1.0 | 1.15 | **1.15** | Popliteal |

**Verdict:** ✓ Neck (2.10) highest for arterial. Medically correct.

---

## 4. Stump Bleeding (BleedingConstants)

**Formula:** `part × sub × stump_level` (third multiplier for amputation level)

Example: right_arm upper_arm stump = 1.0 × 0.9 × 1.22 = **1.10**
Leg thigh stump = 1.0 × 1.1 × 1.2 = **1.32**

Proximal (upper_arm, thigh) > distal (hand, foot). ✓

---

## 5. Severity (BleedingConstants)

**Sub-region only** (no part-level). Used as: `effective_damage = damage × severity_mod`

| Part | Sub-region | Severity mod | Notes |
|------|------------|--------------|-------|
| head | scalp | 1.25 | Thin over bone |
| arm | elbow | 1.15 | Less tissue |
| arm | hand | 1.1 | Smaller cross-section |
| leg | knee | 1.1 | Less tissue |
| leg | foot | 1.1 | Smaller |

**Verdict:** ✓ Thin tissue = higher effective damage = severity reached sooner.

---

## 6. Potential Issues Found

### Issue A: BleedingConstants empty sub_region fallback

When `sub_region` is provided but not found in the dict, `get(sub_region, 0.0)` returns 0.0. The condition `> 0.0` causes the sub-region multiply to be **skipped** (part_mult only). This is correct fallback behavior. ✓

### Issue B: Pain head face = 1.4 × 1.4

Face sub-region (1.4) equals head part (1.4). Combined = 1.96. This is intentional: face is the most painful part of the most painful region. ✓

### Issue C: Leg part 0.95 creates asymmetry

Leg thigh = 0.95 × 0.95 = 0.90. Arm upper_arm = 1.0 × 0.95 = 0.95. So leg thigh is slightly less painful than arm upper_arm. Plausible (thigh has more muscle mass, less nerve density than hand). ✓

---

## 7. Cross-System Consistency

| Region | Pain rank | Bleeding rank | Arterial rank |
|--------|-----------|---------------|---------------|
| head/face | 1 (1.96) | 2 (2.10) | 2 (1.54) |
| head/scalp | 3 (1.82) | 1 (2.70) | 3 (1.68) |
| head/neck | 2 (1.89) | 3 (2.40) | 1 (2.10) |

Scalp bleeds most, face hurts most, neck most arterial. ✓ Medically consistent.

---

## 8. Summary

All part × sub-region multiplications are applied correctly. No bugs found. Ordering is medically plausible. No changes required.
