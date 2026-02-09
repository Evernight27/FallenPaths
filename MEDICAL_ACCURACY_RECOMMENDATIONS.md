# Medical Accuracy – Equation & Number Recommendations

Summary of where your equations and numbers are already well-grounded vs. optional changes for greater medical accuracy. Your existing docs (BLEEDING_MEDICAL_ACCURACY.md, SUB_REGIONS_MEDICAL_SOURCES.md, RESEARCH_BASED_APPROXIMATIONS.md) cover most of the model; this adds **concrete equation/number tweaks** and one logic fix.

---

## 1. Already Medically Sound (No Change Needed)

| Area | Status | Source / note |
|------|--------|----------------|
| **Blood loss death/critical** | OK | 35% / 30% remaining aligns with ATLS Class IV / III–IV. |
| **Cut > crush** (bleeding, arterial) | OK | Penetrating vs blunt literature; relative scaling correct. |
| **Damage ∝ sqrt(KE)** | OK | Sublinear injury–energy link (CIREN/NHTSA). |
| **Bone threshold ordering** | OK | Skull low (2–3), abdomen high (10), limbs mid (4–6); matches 4–23 J skull, ~35 J femur, ~25 J tibia. |
| **Strike velocity 6–18 m/s** | OK | Full-speed strikes 17–24 m/s; 6–18 is plausible in-combat range. |
| **Body part target weights** | OK | NCBI surface area (head ~12%, chest ~27%, legs ~20% each). |
| **Consciousness from head + blood + pain** | OK | Head as proxy for brain; blood modifier; pain tiers 0/10/25/50/75% plausible. |
| **Incapacitation < 10%** | OK | No strict clinical “10%”; “cannot act” threshold is reasonable. |

---

## 2. Optional Equation / Number Tweaks

### 2.1 Sharp penetration: J_PER_MM_RHA (WeaponConstants.gd)

- **Current:** `J_PER_MM_RHA = 130.0` (comment: “1 mm mild steel ≈ 55 J; raised for balance”).
- **Medical:** ~55 J per mm mild steel is a common ballpark; 130 makes armor *harder* to penetrate than in reality.
- **Recommendation:** If you want **more realistic** penetration (armor fails more often): try **70–90** (e.g. `80.0`). Keep **130** if you prefer current balance.

### 2.2 Body part capacity vs segment mass (SpeciesResource)

- **Research (de Leva / Plagenhoef):** Head+neck ~7%, trunk ~43%, each arm ~4.7%, each leg ~20.4% → **chest > leg > head > arm**.
- **Current:** head 12, chest 28, arm 12, leg 28 → head = arm, chest = leg.
- **Optional refinement:** e.g. head **10**, chest **30**, arm **10**, leg **26** so chest is largest, then leg, then head/arm (closer to segment mass). Only change if you want part “durability” to better reflect mass.

### 2.3 Velocity cap (WeaponConstants.gd)

- **Research:** Peak strike speeds ~17–24 m/s.
- **Current:** `VELOCITY_MAX_M_S = 18.0`.
- **Optional:** Raise to **20–22** if you want near-peak strikes to be possible; 18 is already in a plausible band.

### 2.4 Bone thresholds: game units vs joules

- Your **relative** thresholds (scalp 2, thigh 5, abdominal 10) match research (skull low, femur/tibia mid, abdomen soft).
- Damage is abstract; approximate mapping: pre_armor ≈ scale×√(KE)×… so e.g. **~4–23 J** (skull) ≈ low single-digit to low-teens damage; **~25–35 J** (tibia/femur) ≈ mid-teens. No code change; useful to keep this in mind when tuning so “head fractures with less damage than leg” stays true.

---

## 3. Logic Change: Pain from Non-Bleeding Trauma

**Issue:** Pain is computed only from **wounds** (`get_total_pain()` sums `wounds[part]`). Wounds are only added in `_add_wound()` when `base_rate > 0`. So **blunt or minor damage that doesn’t bleed** (e.g. heavy bruising, deflected hits that still hurt) **never adds pain**. Medically, significant blunt trauma is very painful even without hemorrhage.

**Recommendation:** Treat “no bleeding” as “bleeding rate 0” but **still add the wound** so it contributes to pain. In `CoreEntity._add_wound()`:

- Do **not** `return` when `base_rate <= 0`.
- When `base_rate <= 0`, set `base_bleeding_rate` and `current_bleeding_rate` to `0.0` and still append the injury.
- `process_bleeding()` already leaves rate 0 wounds with rate 0; only remove from the list when you want (e.g. when rate has been 0 for a long time, or when wound is “healed” in a later pass). Easiest: **do not remove** wounds whose rate is 0 (only remove when explicitly healed or after a cleanup step). That way pain from bruising/non-bleeding trauma is included.

**Implemented:** `_add_wound` now adds the injury even when `base_rate <= 0` (with rate 0); `process_bleeding` only removes wounds when rate hits 0 *and* they had a positive base rate (clotted). Pain-only wounds stay and contribute to `get_total_pain()`. With current `BLEEDING_RATES` all entries are positive, so 0-rate wounds only appear if you add a 0-rate severity/type (e.g. "minor crush" or "bruise" that doesn’t bleed but hurts); the logic is ready for that.

---

## 4. What Not to Change

- **RHA_TO_MPA, BLUNT_PRESSURE_SCALE:** No direct clinical equivalents; ordering (sharp vs blunt, armor layers) is what matters; keep as tuned.
- **Exact pain reduction tiers (10/25/50/75%):** No exact mapping in literature; relative severity is fine.
- **Absolute bleeding rates (BLEEDING_RATES):** Tuned for gameplay; relative cut > crush and severity scaling are correct per BLEEDING_MEDICAL_ACCURACY.md.

---

## 5. Summary Table

| Item | Action | Reason |
|------|--------|--------|
| J_PER_MM_RHA | Optional: 130 → 70–90 | Closer to “55 J/mm” realism; armor penetrates more. |
| body_max (species) | Optional: head/chest/arm/leg proportions | Align with segment mass (chest > leg > head > arm). |
| VELOCITY_MAX_M_S | Optional: 18 → 20–22 | Allow near-peak strike speeds. |
| Pain from 0-bleeding wounds | **Implemented** | Blunt/non-bleeding trauma now contributes to pain when you add 0-rate wounds (e.g. bruise type). |
| Blood, clotting, arterial, bone order | No change | Already aligned with your medical docs. |

**Optional:** In `process_healing()`, when a part reaches full tissue health, you could remove wounds for that part with `base_bleeding_rate == 0` so pain-only wounds don’t persist forever. Until then they remain and keep contributing to pain.
