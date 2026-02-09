# Current System Weaknesses and What the Physics Changes Would Fix

Summary of the **main weaknesses** of your current damage/armor system and what implementing **effective edge (sharp)** and **momentum-based blunt** would make more accurate.

---

## 1. Main weaknesses of the current system

### 1.1 One formula for both damage types (sharp and blunt from same KE)

**Current:** Pre-armor is a single value: `pre_armor = scale × √(KE) × …`, then split by `cut_ratio` into `pre_cut` and `pre_blunt`. So sharp and blunt **magnitude** both scale with √(KE).

**Weakness:** Real cutting is dominated by **pressure** (force/area, edge geometry). Real blunt trauma is dominated by **momentum transfer** (mass × velocity). Using the same KE-based magnitude for both under-expresses weapon identity: a mace and a sword at the same KE only differ by the split (0% vs 75% cut), not by *how much* blunt or sharp damage they can do relative to each other. So the system is **mechanically simple but physically coarse**.

---

### 1.2 No edge sharpness / blade condition

**Current:** Sharp penetration and sharp damage use **geometric** contact only (blade_width, point_width). There is no notion of a dull vs sharp edge.

**Weakness:** In reality, a sharper edge has **smaller effective contact** → higher pressure → deeper penetration and more severe cutting. So:

- Blade **condition** (maintenance, wear) doesn’t matter.
- **Weapon quality** (well-honed vs factory edge) doesn’t matter.
- All swords of the same dimensions behave identically for cutting.

Cutting is **less accurate** than it could be without adding a separate “sharpness” multiplier; the physics is already contact-area driven, but the contact is only geometric.

---

### 1.3 Blunt damage scales with √(KE), not momentum

**Current:** `pre_blunt = pre_armor × (1 - cut_ratio)`, and `pre_armor ∝ √(KE)`. So blunt magnitude scales with **kinetic energy**, not with mass or momentum.

**Weakness:** Blunt trauma (contusion, concussion, behind-armor trauma) correlates better with **impulse/momentum transfer** than with KE. Two impacts with the same KE can have very different momentum:

- **Heavy, slow (mace):** high momentum, high force over a longer time → more concussion, more BAT.
- **Light, fast (stick):** lower momentum, high peak force over a short time → different injury profile.

So the current model **underweights mass** and **overweights velocity** for blunt. That makes “heavy and concussive” vs “light and fast” less distinct than in reality.

---

### 1.4 Mace vs leather (and other padding) is counterhistorical

**Current:** Mace has large head → low pressure → `pen_blunt` (~12 MPa) below leather’s `blunt_resistance_mpa` (14) and plate (40). So mace is in the **deflection path** vs both: heavy transmission reduction, and mace ends up **worse than sword vs leather** (sword’s blunt stream has high pressure and penetrates).

**Weakness:** Historically, maces were **good vs plate** (concussion through armor) and still **effective vs padded/leather** (heavy blow still transmits). In your system they are good vs plate (after BAT fix) but **poor vs leather** because blunt pen is pressure-based and the mace’s large contact keeps pen below leather’s resistance. So the **role of mass/momentum** for “blunt through padding” is not captured.

---

### 1.5 Deflected damage → crush only (medical)

**Current:** All non-zero blunt (including from deflected sharp) is applied as **crush** wounds (with bleeding). There is no distinction between low-force contusion (bruise) and high-force crush.

**Weakness:** Medically, deflected or low-energy impacts often cause **contusion/bruise** (pain, little or no bleeding). Only higher transmitted force causes crush-like tissue damage and significant bleeding. So wound **type** (bruise vs crush) is less accurate; this is independent of edge/momentum but is a known gap in the docs.

---

### 1.6 Sharp deflection: deflecting layer applied twice to deflected blunt

**Current:** When sharp deflects, the deflecting layer converts damage to blunt (× transmission), then that deflected blunt is run through **all** layers again, **including the same deflecting layer**. So that layer effectively reduces the deflected amount twice (once at deflection, once in the full blunt pass).

**Weakness:** Arguably double-counts that layer’s absorption for the deflected stream. You already mitigated the blunt-vs-blunt double-apply with a single pass; the sharp-deflection path still has this quirk. Not a physics “sharp vs blunt formula” issue but a structural one.

---

### 1.7 Minor: RHA_TO_MPA and transmission constants

**Current:** Deflected sharp → blunt uses `pen_mm_rha * RHA_TO_MPA` and per-layer `deflection_transmission`. RHA_TO_MPA is an approximate conversion; transmission values are tuned for feel.

**Weakness:** No direct physical calibration; they’re tuning knobs. Acceptable for gameplay; just not “derived from first principles.”

---

## 2. What implementing the physics changes would make more accurate

### 2.1 Effective edge (sharpness) for cutting

**Change:** Model edge as **effective contact width** (from a sharpness stat or effective edge width). Use it in sharp penetration and in pre-armor cut.

**Would improve:**

- **Cutting and penetration:** Sharper blade → smaller effective contact → higher pressure → higher `pen_sharp` and more cut damage. Dull blade → more deflects, less cutting. Matches **pressure-driven cutting**.
- **Blade condition / quality:** Sharpness can represent maintenance or weapon quality; you can add degradation (e.g. effective contact increases with use) later if desired.
- **No new “magic” multiplier:** Everything stays in terms of contact area and energy; only the **effective** contact changes with edge.

Deflection logic stays the same; it just receives a more physically meaningful `pen_sharp` and `pre_cut`.

---

### 2.2 Momentum-based pre-armor blunt

**Change:** Compute pre-armor blunt from **momentum**: `pre_blunt = scale × (mass × velocity) × strength_mod × arm_mod × contact_factor`, instead of from the KE-based pool split.

**Would improve:**

- **Blunt trauma accuracy:** Heavy, slow weapons do more blunt damage than light, fast ones for similar KE. Concussion/BAT scale with impulse, not just energy.
- **Weapon identity:** Maces feel “heavy and concussive”; swords’ blunt component stays relatively small (low mass). Difference comes from **formulas**, not only from cut_ratio.
- **Mace vs leather (potential):** If you also tune **blunt penetration** or **transmission** to reflect momentum (e.g. momentum/area for pen_blunt, or higher effective transmission for high-momentum impacts), maces can become more effective vs padding/leather while still using the same deflection rules. If you only change pre_blunt to momentum and keep pen_blunt as KE/area, mace vs leather stays pressure-limited; then adding a momentum term to transmission or to pen_blunt would be the lever for “heavy blow through padding.”

Deflection logic unchanged; you still pass one `pen_blunt` and one `pre_blunt`, with `pre_blunt` now from momentum.

---

### 2.3 Summary table

| Weakness | What the change improves |
|----------|---------------------------|
| Single KE formula for both types | Sharp and blunt come from **different physics** (pressure vs momentum); weapon identity and realism improve. |
| No edge sharpness | **Cutting** reflects blade condition and pressure; dull blades deflect more and cut less. |
| Blunt from KE split | **Blunt trauma** scales with momentum; heavy weapons are more concussive; matches BAT/concussion better. |
| Mace poor vs leather | **Partially** fixed by momentum blunt; fully fixed if pen_blunt or transmission also reflects momentum so heavy blows “push through” padding more. |
| Deflected → crush only | **Not** fixed by edge/momentum; needs wound-type choice (bruise vs crush by force/source). |
| Deflecting layer twice on deflected blunt | **Not** fixed by edge/momentum; needs a small armor-flow change (e.g. don’t re-apply deflecting layer to deflected blunt). |

---

## 3. Bottom line

- **Main weaknesses:** (1) One KE-based pool for sharp and blunt, (2) no edge sharpness, (3) blunt from KE instead of momentum, (4) mace vs leather counterhistorical, (5) deflected damage always crush, (6) deflecting layer applied twice to deflected blunt.
- **Implementing effective edge + momentum blunt** would make **cutting** (pressure, blade condition) and **blunt trauma** (mass, momentum, weapon identity) more accurate, and can help **mace vs leather** if you also let momentum affect blunt penetration or transmission. It would **not** fix wound type (bruise vs crush) or the double-apply of the deflecting layer; those need separate, small changes.
