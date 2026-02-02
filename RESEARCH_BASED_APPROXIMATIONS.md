# Research-Based Approximations

This document ties the game’s “abstract” constants to medical and physics research so they are **simplified approximations** of real data, not arbitrary numbers.

---

## 1. Bone: Thresholds and Fractions (BodyPartConstants)

### Research

- **Skull fracture:** Quasi-static frontal bone ~3.95 ± 1.18 J at fracture; dynamic frontal 7–18 J, temporal 3–23 J (PubMed 20803457, TRB 1486162).
- **Hip/proximal femur:** Fracture work 5–51 J, loads 778–4,040 N (JBJS 1990; NHTSA/ESV).
- **Long bones (torsional):** Femur ~35 J, tibia ~25 J mean energy absorption (SciDirect 002192908090353X).
- **Relative strength:** Skull fractures at **lower** energy than femur/tibia; leg bones are load-bearing and absorb more energy. Tibia is subcutaneous and commonly fractured.

### Game approximation

- **Threshold** = “damage above which bone starts taking a share.” Lower threshold = bone involved earlier (thin tissue and/or lower fracture energy).
- **Head (3):** Skull fractures at 4–23 J → bone involved with **less** total impact → **lowest** threshold. Thin tissue over skull.
- **Chest (8):** Ribs/sternum; more overlying tissue; moderate threshold.
- **Arms (5):** Humerus/radius/ulna; between head and leg in typical loading.
- **Legs (6):** Femur 35 J, tibia 25 J → bone absorbs substantial energy, but limb has more tissue → **higher** threshold than head; leg slightly above arm (tibia common fracture).

**Fraction to bone:** Head high (0.55) — impact often reaches skull quickly; chest moderate (0.30); limbs 0.38–0.42 — share of energy that goes to bone vs soft tissue (simplified from loading type and anatomy).

*Sources: Skull – PubMed 20803457, TRB; Hip – JBJS, NHTSA; Long bones – J Biomech / SciDirect.*

---

## 2. Body Part “Capacity” (body_max) – SpeciesResource

### Research

- **Segment mass % of body weight** (de Leva 1996, Plagenhoef 1983 – ExRx.net, Bionumbers):
  - Head & neck: **6.81%** (de Leva)
  - Trunk: **43.02%**
  - Total arm (both): **9.43%** → ~4.7% per arm
  - Total leg (both): **40.74%** → ~20.4% per leg
- Thorax (chest subset): ~20% (Plagenhoef). So **chest** and **each leg** are largest segments; **head** and **each arm** smaller.

### Game approximation

- **body_max** = abstract “tissue capacity” per part. Scale relative to segment mass so larger segments have higher capacity.
- **Relative** (normalized to sum ~100 for 6 parts): head ~7, chest ~20, arm ~5, leg ~20 per side.
- **Default scaling** (e.g. base 10): head 12, chest 28, arm 12, leg 28 (or head 10, chest 25, arm 10, leg 25) so **chest ≈ leg > head ≈ arm**.

*Sources: de Leva 1996 J Biomech; Plagenhoef 1983; ExRx.net segment data.*

---

## 3. Healing: Linear vs Exponential

### Research

- **Wound healing:** Four phases (hemostasis, inflammation, proliferation, remodeling) – StatPearls NBK470443.
- **Surface area:** 72% of venous leg ulcers fit **exponential decay** of wound area; exponential model had **35% complete closure** vs **21%** for non-exponential (BMC Dermatol 1471-5945-9-2). Rate proportional to **current wound size** (exponential decay) fits contraction and epithelial proliferation.

### Game approximation

- **Linear healing** (current): `heal = min(deficit, rate * time)` → constant rate until full. Simple but not physiologic.
- **Exponential healing:** `deficit(t) = deficit(0) * exp(-t/τ)` or per tick `heal = deficit * (1 - exp(-Δt/τ))`. **Faster early**, slower as wound closes. Use **τ = duration / 3** so that after `duration` seconds we are ~95% healed (1 - e^(-3) ≈ 0.95), keeping “duration” as “time to near-full heal.”

**Blood volume recovery:** Same exponential form (deficit × (1 - exp(-t/τ))) so that after ~24 h we approach 100% without overshoot.

*Sources: BMC Dermatol 9:2; StatPearls NBK470443.*

---

## 4. Clotting: Linear vs Exponential Decay of Bleeding Rate

### Research

- Hemostasis involves **rate constants** and decay-like kinetics (Blood Coag Fibrinolysis; clot life span models). Bleeding rate often **decreases proportionally** to current rate as clot forms (fewer open vessels / less flow).
- **First-order decay:** d(rate)/dt = -k·rate ⇒ rate = rate₀·exp(-k·t). So **exponential** decay of bleeding rate is more physiologically plausible than **linear** (constant subtraction per second).

### Game approximation

- **Current (linear):** `rate -= clotting * delta` → same amount per second.
- **Exponential:** `rate *= exp(-clotting * delta)` → **fraction** per second; same clotting constant gives “half-life” ln(2)/clotting seconds. Use exponential so clotting is “fraction of current rate removed per second.”

*Sources: Blood Coag Fibrinolysis; hemostasis kinetics.*

---

## 5. Damage vs Impact Energy

### Research

- **Injury risk** increases **non-linearly** with impact energy (CIREN, NHTSA crash data). Higher energy → disproportionately higher injury risk.
- **sqrt(KE)** or similar **sublinear** scaling of “damage” with KE is a simple approximation: more energy → more damage, but with **diminishing returns** per joule (consistent with risk curves).

### Game approximation

- **Pre-armor damage ∝ sqrt(KE)** (WeaponDamageHelper) is kept as a **research-consistent** choice: monotonic increase with energy, sublinear. **DAMAGE_KE_SCALE** and min/max remain tuned for gameplay; the **form** is grounded.

*Sources: CIREN/NHTSA; J Trauma.*

---

## 6. Summary of Code Changes

| System        | Change | Research basis |
|---------------|--------|----------------|
| Bone          | Comments + threshold/fraction rationale | Skull 4–23 J, femur 35 J, tibia 25 J; head low threshold, high fraction |
| body_max      | Defaults from segment mass (head/arm smaller, chest/leg larger) | de Leva / Plagenhoef segment % |
| Healing       | **Exponential** heal: deficit × (1 - exp(-Δt/τ)), τ = duration/3 | 72% wounds exponential; 35% vs 21% closure |
| Clotting      | **Exponential** decay: rate *= exp(-k×Δt) | First-order rate constants; proportion of rate removed per second |
| Damage vs KE  | Keep sqrt(KE); document as sublinear injury–energy link | Non-linear injury risk with energy |

All constants remain **approximations** for gameplay; they are now **anchored** to these sources and formulas.
