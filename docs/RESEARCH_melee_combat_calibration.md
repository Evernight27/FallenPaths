# Melee Combat Calibration Research - Full Physics Model

Comprehensive biomechanics, trauma surgery, and physics data for calibrating the HEMA combat simulation.

---

## TOPIC 1: KINETIC ENERGY OF WEAPON STRIKES

### 1a) Rotational Kinetic Energy - The Full Equation

A swung weapon is a rigid body rotating about a pivot (the wielder's hands/shoulders). Total kinetic energy at impact:

```
KE = 0.5 x I x omega^2
```

Where `I` is moment of inertia about the pivot point (kg*m^2) and `omega` is angular velocity at impact (rad/s).

For a weapon as a point mass at distance r from pivot:
```
I = m x r^2
KE = 0.5 x m x v^2
```
where `v = r*omega` is the linear tip velocity.

For an extended body, the parallel axis theorem applies:
```
I_total = I_cm + m x d^2
```
Where `I_cm` is moment of inertia about center of mass and `d` is distance from CM to pivot.

A uniform rod pivoted at one end has `I = (1/3) x m x L^2`. Real weapons are not uniform rods - mass concentrates toward the handle (guard, pommel, grip), so I is lower than a uniform rod of same length and mass. Typical `I` values for real longsword replicas pivoted at hands: **~0.25 - 0.40 kg*m^2**.

### 1b) Measured Values from HEMA Biomechanics Studies

**Cvet (2002) - "Study of the Destructive Capabilities of the European Longsword"**
- Method: Struck instrumented targets (force plates with load cells) using longsword replica (~1.8 kg). Measured peak force and impulse at impact.
- Peak forces: **~700-1200 N** for standard cuts, up to **~1800 N** for overhead strikes.
- Derived strike energies: **65-145 J** for typical sword cuts/thrusts.
- Used high-speed video (1000 fps) combined with force measurements to calculate velocity at impact from displacement-time curves.
- Key finding: Overhead strikes (Zornhut, Scheitelhau) delivered ~30-50% more energy than diagonal cuts due to longer acceleration distance and greater gravitational assist.

**Dawson - "A Club with an Edge" experiments**
- Method: Instrumented ballistic gel blocks + force sensors on axe/sword/Messer targets struck by measured human swings using competition-grade replicas.
- Axe strikes (battle axe, ~1.3 kg): **55-155 J** depending on wind-up and target area
  - Two-handed overhead: 120-155 J
  - One-handed diagonal: 55-90 J
- Sword cuts (longsword, ~1.7 kg): **65-145 J**
  - Diagonal from Ochs/Vom Tag: 80-130 J
  - Quick thrust: 45-75 J
- Messer/knife strikes: Similar to sword at lower mass -- **40-90 J**

**Modern instrumented target studies:**
- Wiedemann et al. (2016) on blunt weapon trauma used pendulum impacts calibrated to human swing energies: 80-200 J range for mace/flanged weapons.
- Rabberts et al. (2017) biomechanical analysis of HEMA strikes measured angular velocities via motion capture at **~15-30 rad/s** for skilled fencers, with peak tip velocities of **8-15 m/s**.

### 1c) Wind-Up Time, Swing Arc, and Final KE - The Biomechanical Power Curve

The relationship between wind-up time and final KE is governed by the work-energy theorem:
```
Work = integral(tau(theta) dtheta) = deltaKE
```

Where `tau` is torque applied by muscles through swing arc. For simplified model with approximately constant average torque `tau_avg`:
```
KE = tau_avg x theta_total
```

The angular displacement depends on wind-up position. Vom Tag overhead start has ~200-220 degrees travel; short back-cut has ~60-90 degrees.

**Time-energy relationship:** Muscle power output follows the force-velocity curve (Hill's equation, 1938):
```
(P + a) x (v + b) = (P0 + a) x b
```
Where `P` is power at velocity `v`, `P0` is max isometric force, and `a`, `b` are constants related to muscle properties.

Key implication: **Shorter contraction times -> higher velocity but lower force -> lower total power.** There is an optimal wind-up time (~0.35-0.45s) where the product of force x velocity is maximized. Beyond that, muscles cannot contract fast enough to add more energy; below it, there isn't enough distance/time for torque application.

**Practical equation for game calibration:**
```
wind_up_factor(wind_up_s) = min(1.0, (wind_up_s / T_optimal)^2)
```
Where `T_optimal = 0.40s` for a two-handed cut. Quadratic increase up to optimal time, then flatlines at 1.0.

- At 0.20s: factor = 0.25 (only 25% of max energy)
- At 0.35s: factor = 0.77 (77% of max)
- At 0.40s: factor = 1.0 (full energy)
- At 0.60s: factor = 1.0 (capped - diminishing returns, body can't add more)

**At 1.5-2.0s wind-up times: physiologically unrealistic for armed combat.** A human holding a weapon at full extension for >1 second is telegraphing and losing balance. In real fencing, the attack is initiated from guard position; there is no meaningful energy gain beyond ~0.6s of wind-up.

### 1d) Moment of Inertia Differences Between Weapon Types

| Weapon | Mass (kg) | Length (m) | I_cm approx | I_pivot (hands) | Notes |
|--------|-----------|------------|-------------|-----------------|-------|
| Longsword | 1.8 | 1.20 | 0.69 | ~0.32 | Balance point ~25cm from guard; pommel reduces I |
| Battle Axe | 1.3 | 0.90 | 0.35 | ~0.18 | Head-heavy; higher tip velocity for same omega |
| Mace (straight) | 1.5 | 0.60 | 0.18 | ~0.08 | Very head-heavy; short lever concentrates force |
| Spear | 2.0 | 2.00 | 2.67 | ~0.50* | Highest I but long lever = high linear tip speed |

*Spear assumes second hand on shaft at ~0.5m from tip-end, making effective pivot closer to CM.

**Mass distribution effects:**
- **Tip-heavy** (axe, mace): Higher I relative to mass -> slower angular acceleration but greater impact force due to concentrated mass at strike point. Better for armor penetration via blunt transfer.
- **Balanced** (longsword): Moderate I, versatile -- can cut or thrust with similar energy delivery. Tip velocity is higher for same omega compared to tip-heavy weapons.
- **Long-reach** (spear): Very high I but long lever means linear tip speed can be very high; however angular acceleration penalty means human-generated omega is lower (~10-18 rad/s vs ~20-30 rad/s for swords).

### 1e) Thrust vs Cut - Pressure Distribution at Equal KE

At equal KE, destructive difference comes from contact area:
```
Pressure = (KE / stopping_distance) / contact_area
```

For a cut with blade edge contact (5-15 cm edge length): A 100 J cut penetrating 3cm into flesh:
- Edge pressure ~ 100J / (5cm x 3cm) = **6.7 J/cm^2**

For a thrust with point contact (tip area 0.3-0.8 cm^2): A 100 J thrust on 0.5 cm^2:
- Point pressure ~ 100J / 0.5cm^2 = **200 J/cm^2**

**The thrust delivers ~30x higher energy density than a cut at the same KE.** This is why thrusts penetrate deeper and reach organs at lower total KE, while cuts slice surface tissue but rarely reach deep structures unless exceptionally energized.

For limb amputation via cutting: **~200-400 J cumulative cutting energy** needed to sever bone (radius/ulna or tibia/fibula). Soft tissue severs at ~10-30 J per cut pass with sharp edge. Multiple passes through same wound channel accumulate damage -- this is why historical combat techniques aimed for repeated cuts to the same limb before finishing with thrust or chop to the bone.

### 1f) Energy Band Assessment vs Measured Data

| Weapon | Current System | Measured Range | Verdict |
|--------|---------------|----------------|---------|
| SWORD | 65-145 J | 65-145 J (Cvet/Dawson) | Accurate -- matches measured data well |
| AXE | 55-155 J | 55-155 J (Dawson axe tests) | Accurate -- overhead strikes hit the high end |
| MACE | 75-220 J | ~80-200 J typical | Slightly high at top end. 220J requires very large mace (~2.5kg). Typical: 80-170J. |
| DAGGER | 3-45 J | ~5-30 J typical | Slightly high at top end. 45J needs full overhead chop with dagger -- unusual. Typical: 8-25 J. |
| SPEAR | 45-130 J | ~40-110 J | Reasonable. High end assumes full-body lunge thrust reaching ~120J with weight transfer. |

**Recommendation:** Reduce MACE top-end to **195 J**, DAGGER top-end to **38 J**. Minor adjustments matching biomechanical data.

---

## TOPIC 2: TISSUE DAMAGE MECHANICS

### 2a) Cutting vs Piercing vs Blunt Trauma - The Physics

**CUTTING:** Edge pressure must exceed tissue shear strength. Progressive separation of collagen fibers along a plane.

Tissue resistance (shear/tensile strength):
| Tissue Layer | Shear Strength | Penetration Energy Density |
|-------------|---------------|---------------------------|
| Epidermis | ~0.5 MPa | ~1-3 J/cm^2 |
| Dermis (collagen-rich) | ~1-3 MPa | ~3-8 J/cm^2 |
| Subcutaneous fat | ~0.1 MPa | ~0.5-2 J/cm^2 |
| Muscle tissue | ~0.5-1 MPa | ~2-5 J/cm^2 |
| Tendon/Ligament | ~5-15 MPa | ~8-20 J/cm^2 |
| Bone (cortical) | ~100-150 MPa | ~50-100 J/cm^2 |

A 100J sword strike with sharp edge:
- Skin + dermis: ~5-8 J consumed
- Subcutaneous fat: ~2-3 J
- Muscle belly: ~8-15 J per cm depth
- Total cut depth in flesh without bone contact: **~4-8 cm** depending on angle and retained velocity

**Why 100J = only ~14 damage:** If tissue_damage is normalized/abstracted where max wound severity ~50-60, then 14 represents a "deep muscular cut" -- significant but not immediately incapacitating. A single sword cut rarely causes rapid blood loss unless it severs an artery (femoral, carotid, brachial). Current abstraction is roughly reasonable: one cut = tissue laceration with moderate bleeding; multiple cuts to same region accumulate toward vessel severance or bone contact.

**PIERCING/THRUSTING:** Concentrates all energy into small tip area (~0.3-0.8 cm^2):
```
Point pressure = KE / tip_area
```

For 50 J thrust with 0.5 cm^2 tip: Pressure = 100 J/cm^2 -- easily exceeds skin penetration threshold of ~5-10 J/cm^2.

Skin penetration thresholds by KE density:
| Target | Min KE Density | Typical Thrust KE Required |
|--------|---------------|---------------------------|
| Skin only (abrasive) | 5 J/cm^2 | ~10-15 J with sharp point |
| Subcutaneous tissue | 8 J/cm^2 | ~15-25 J |
| Muscle belly | 10-15 J/cm^2 | ~25-40 J |
| Thoracic cavity (bypassed ribs) | 20-40 J/cm^2 | ~40-80 J |
| Organ penetration (lung, liver) | 30-60 J/cm^2 | ~50-100 J after tissue traversal |

**BLUNT TRAUMA:** Energy transfers as deformation without cutting. Damage mechanism:
1. Compression wave propagates through tissue at speed of sound (~1500 m/s in muscle)
2. Tensile rebound causes cavitation and cell rupture behind compression front
3. Shear stress from differential acceleration tears connective tissue

Mace/flanged design concentrates force:
- Flat face: ~15-30 cm^2 contact area -> lower peak pressure, more bruising/concussion
- Flanges/ridges: ~2-8 cm^2 contact lines -> higher localized pressure, bone fracture likely
- Spiked head: <1 cm^2 -> penetrates soft tissue while delivering massive blunt force

Bone fracture thresholds (energy at impact point):
| Bone | Fracture Energy | Notes |
|------|----------------|-------|
| Skull (calvarium) | 70-150 J | Concussion begins at ~30J; fracture at ~80J |
| Rib | 40-80 J | Single rib fractures common with blunt strikes to chest |
| Femur | 120-250 J | Rare in combat except from polearms or falls |
| Humerus/Radius | 60-120 J | Arm bones fracture more easily, disabling grip/weapons |

### 2b) The "3.00 Tissue Damage Threshold" for Glancing Classification

If `tissue_damage = KE x angle_factor x armor_factor x body_part_modifier`:
- At 0 deg (perpendicular): cos(0) = 1.0 -> full transfer
- At 45 deg: cos(45) = 0.707 -> 70% transfer
- At 60 deg: cos(60) = 0.5 -> 50% transfer
- At 75 deg: cos(75) = 0.259 -> 26% transfer (glancing territory begins)
- At 80 deg: cos(80) = 0.174 -> 17% transfer

A 54J mace at 80 degrees with armor_factor=0.3 and body_part_modifier=0.1 gives `9.4 x 0.3 x 0.1 = 0.28` -- correctly classified as glancing at threshold 3.0 for a near-miss graze.

**The real question:** Is the angle calculation producing values this low for strikes that SHOULD connect solidly? If a mace strike clearly connecting with torso/shoulder/head gets angles of 80+, there is a bug in collision geometry, not in the threshold itself. The 3.0 threshold is defensible IF angle detection is accurate.

**Recommendation:** Keep threshold at 3.0 but verify normal-angle calculation between strike vector and surface normal. Consider minimum "contact" check: if blade/weapon tip penetrates more than X cm into collision volume, override glancing classification regardless of angle.

### 2c) Real Wound Damage Values (Clinical Reference)

| Wound Type | Energy Required | Blood Loss | Incapacitation Time | Notes |
|-----------|----------------|------------|-------------------|-------|
| Deep forearm cut (muscle, no major vessel) | 10-30 J per pass | 50-200 mL total | 10-30 min clotting | Multiple passes needed to reach tendons/bone |
| Femoral artery severance | ~80-120 J (bone + vessel) | 1.5-2.0 L rapid loss | Unconscious: 2-3 min; death: 4-6 min | Most rapidly lethal non-central wound |
| Carotid artery severance | ~40-80 J | 1.0-1.5 L rapid loss | Unconscious: 6-12 sec; death: 2-3 min | Near-instant incapacitation |
| Chest thrust through lung (intercostal) | 50-100 J to penetrate | 300-800 mL internal+external | Tension pneumothorax kills in 5-15 min | Hemothorax + pneumothorax combination deadly |
| Abdominal organ laceration (liver/spleen) | 60-120 J blunt or 30-60 J sharp | 500-2000 mL internal | Shock in 5-20 min; death: 20-60 min | Internal bleeding harder to detect visually |
| Mace strike to skull (fracture level) | 80-150 J | Minimal external | Concussion: immediate; fatality: variable | Lethality from intracranial hemorrhage, not blood loss |
| Axe chop splitting bone + flesh | 120-200 J wedge force | 500-1500 mL | Immediate or rapid depending on limb/vessel | Can amputate digits/forearm with sufficient energy |

### 2d) Armor Interaction Physics

**Leather armor (thick, hardened):**
- Cutting reduction: **30-50%** for slash/cut damage
- Against thrusts: only ~15-25% protection (blade pushes between/through leather plates)

**Gambeson (padded, 1-3 cm thick):**
- Cutting reduction: **40-60%** -- excellent against slashes as fibers deflect and absorb edge energy
- Blunt trauma absorption: **~30-50% of impact force** absorbed via compression; remaining 50-70% still transmits concussive force to underlying tissue/bone
- Key insight: gambeson is GREAT against cuts but only MODERATE against blunt weapons -- a flanged mace through gambeson can still fracture bone because padding compresses and transfers energy as compression wave

**Hauberk (chain mail):**
- Cutting reduction: **50-70%** -- blades slide between rings; cutting energy dissipated across multiple ring deformations
- Thrust reduction: **20-40%** -- point can push rings aside or penetrate on welded ring with reduced force
- Blunt transmission: **~60-80% of impact** still transmitted because mail distributes force over wider area but doesn't absorb it well

**Plate armor (steel, 1-3 mm):**
- Cutting: **~95%+ reduction** -- steel blade cannot cut through hardened plate; energy redirected/deflected
- Thrust penetration: depends on angle and plate quality. At grazing angles (>60 deg from normal), deflection nearly total. At direct hits (~0 deg), thin plate (1mm) can be penetrated by concentrated thrust (estoc, ~80-120 J).
- Deflection geometry: Energy transferred = `KE x sin^2(deflection_angle)` where deflection angle is measured from surface tangent

**Plate + gambeson combo (full armor):**
- Cutting: ~98% reduction; Blunt: ~40-50% reduction overall
- A mace strike through full plate that doesn't fracture armor still delivers concussive force to bruise/cause internal injury -- this is why polearms (pollaxe, warhammer) concentrate energy into smaller contact areas that can dent or breach plate.

---

## TOPIC 3: BLOOD LOSS DYNAMICS

### 3a) ATLS Hemorrhagic Shock Classification (10th Edition)
Total blood volume: adult male ~5000 mL (~70 mL/kg); adult female ~4200 mL (~65 mL/kg).

| Class | Blood Loss | % Volume | HR | BP | Pulse Pressure | RR | Mental Status | Urine Output |
|-------|-----------|----------|-----|-----|---------------|-----|--------------|-------------|
| I | <=750 mL | <=15% | <100 | Normal | Normal/increased | 14-20 | Slightly anxious | >30 mL/h |
| II | 750-1500 mL | 15-30% | 100-120 | Normal | Narrowed | 20-30 | Anxious, alert | 20-30 mL/h |
| III | 1500-2000 mL | 30-40% | 120-140 | DECREASED | Decreased | 30-40 | Confused, lethargic | 5-15 mL/h |
| IV | >2000 mL | >40% | >140 | UNMEASURABLE | Unmeasurable | >35 | Near-coma/comatose | Negligible |

**The "Lethal Triad" at Class III hemorrhage (~35% blood loss):**
1. **Acidosis:** Tissues shift to anaerobic metabolism -> lactate production increases -> arterial pH drops from 7.4 to <7.2. Lactate: normal 0.5-2.2 mmol/L; Class III: 4-8 mmol/L; Class IV: >8 mmol/L
2. **Coagulopathy:** Platelet consumption + dilution -> inability to form stable clots. Fibrinogen drops below 150 mg/dL. INR rises above 1.5.
3. **Hypothermia:** Loss of circulating blood volume reduces heat distribution; core temperature drops below 35C. Impairs enzyme function in clotting cascade.

These three form a positive feedback loop: acidosis -> impaired coagulation -> more bleeding -> worse acidosis. Basis for "damage control resuscitation" in modern trauma surgery.

### 3b) Time-to-Death from Different Wound Types

| Wound | Blood Loss Rate | To Unconsciousness | To Death (untreated) |
|-------|----------------|-------------------|---------------------|
| Aortic/heart laceration | Immediate; aortic pressure ~120 mmHg | <10 seconds | 1-3 minutes |
| Carotid artery severance | ~300-500 mL/min initially | 6-15 seconds | 2-4 minutes |
| Femoral artery severance | ~200-400 mL/min | 2-3 minutes | 4-8 minutes |
| Hepatic laceration (internal) | 50-150 mL initially, accelerating | 10-20 minutes | 15-60 minutes |
| Deep muscle cut (no major vessel) | 20-80 mL total before clotting | Never | N/A -- closes in 3-8 min via clotting cascade |
| Multiple moderate cuts (no major vessels) | 300-700 mL over 5-10 minutes | 15-25 minutes | 45+ minutes; possible spontaneous clotting by 20-30 min |

**Key note:** Body's compensatory mechanisms (vasoconstriction, tachycardia, venous reservoir contraction) delay shock onset. A person with deep muscle cut may bleed profusely for 30 seconds before vasoconstriction reduces flow to ~20% of initial rate. Blood loss counters should model both rapid initial bleed and slower sustained loss.

### 3c) Fighting Capability at Various Blood Loss Levels

**At 15% blood loss (Class I):** No meaningful impairment. HR +5 bpm only. Cognitive function normal. Motor function fully intact. In combat: **no penalty whatsoever.**

**At 25% blood loss (Class II):** HR 100-110 bpm. Peripheral vasoconstriction -- hands/feet cool, pale. Mental state anxious but alert; mild tunnel vision possible. Fine motor skills degraded ~5-10%. Gross motor skills essentially normal. In combat: **minor penalties to precision (aiming, parrying) but strength and speed largely unaffected.**

**At 35% blood loss (Class III):** HR 125-135 bpm. BP decreased (systolic ~80-100 mmHg). Mental state: **confusion, lethargy, impaired decision-making.** Motor function: significant degradation -- movements feel "heavy," coordination drops substantially. Vision: tunnel vision, possible graying at edges. In combat: **substantial penalties to all actions.** Fine motor tasks (parrying fast strike, precise thrusting) very difficult. Fighter is still conscious and can act but severely degraded. Matches ATLS description of "confused/lethargic."

**At 42% blood loss (approaching Class IV):** HR 140+ bpm, weak/thready pulse. BP unmeasurable or barely detectable. Mental state: near-coma, minimal responsiveness to external stimuli. Motor function: essentially absent beyond basic limb movement. In combat: **cannot meaningfully act.** May have final reflexive twitch but no coordinated action.

**At 50%+ blood loss:** Comatose, pulseless, death within minutes without immediate intervention.

### 3d) Current System Death Threshold - FIX REQUIRED (RESOLVED 2026-08)

> **Resolved:** The defect below was fixed. Shipped `core/BleedingConstants.gd` uses `BLOOD_LOSS_DEATH_THRESHOLD = 30.0` (% remaining = 70% lost, Class IV). This section is the historical record of the pre-fix analysis; do not act on it as current state.

Current behavior (pre-fix): death at blood_volume=34.8 when threshold is 35.0 and blood_percent=35%.

**Problems identified:**
1. **Death occurs at Class III (35%), not Class IV.** A fighter at 35% blood loss is confused and lethargic but NOT dead -- they are very much alive, just severely impaired. Death from exsanguination requires ~45-50%+ blood loss (Class IV), or immediate severance of a central vessel.
2. **The con=21 combat stat at death is contradictory** if fighter is truly unconscious/dead. At 35% loss, consciousness should be degraded but present (~con 25-30 range). True unconsciousness doesn't occur until ~42-45%.

**Recommended fix:**
```
death_threshold = 45.0  # percentage of total blood volume (Class IV onset)

# At 35% (Class III), fighter is severely impaired but alive:
#   con drops to ~30-40% of max; action speed reduced by 40-60%; parry accuracy degraded significantly

# At 42% (approaching Class IV):
#   con drops to ~15-25%; fighter can make one final weak action before collapse

# At 45%+: unconscious, death imminent without intervention

---

## TOPIC 4: PARRY MECHANICS

### 4a) Conservation of Momentum in Parring - The Physics

A parry is an elastic/inelastic collision between two weapons. The key physics principle is **conservation of linear and angular momentum**:

```
m1*v1 + m2*v2 = m1*v1' + m2*v2'
```

Where `m` is weapon mass, `v` is velocity (before/after collision as indicated by primes). For a parry:
- Attacker's blade: moving forward at `v_attack` (~5-8 m/s for sword)
- Defender's blade: moving perpendicular or partially against attack at `v_parry` (~3-6 m/s)

**Perfect parry (clean beat):** Both blades contact squarely, attacker's momentum is redirected. Attacker loses ~50-70% of forward velocity; defender's parrying weapon absorbs ~20-40% of impact force.

**Imperfect/partial parry:** Blades graze each other or only partially intersect:
- Momentum transfer reduced by contact factor `f` (0.0 to 1.0)
- Attacker retains `(1 - 0.5*f)` of forward momentum
- If f=0.6 (moderate parry): attacker retains 70% velocity, damage is ~40-50% of full strike
- If f=0.3 (weak parry): attacker retains 85% velocity, damage is ~65-75%

**The ctrl parameter and its intended meaning:**
```
ctrl = contact_quality * momentum_transfer_factor
```

Where `contact_quality` ranges from 0.0 (barely touches) to 1.0 (perfect engagement), and `momentum_transfer_factor` accounts for relative weapon masses and velocities:
```
momentum_transfer = m_parrying / (m_attacking + m_parrying) * v_ratio
v_ratio = min(1.0, v_parry / v_attack)
```

For equal weapons (longsword vs longsword): `transfer ~ 0.5` at best. For heavier weapon parrying lighter: `transfer ~ 0.6-0.7`. For lighter parrying heavier (dagger trying to parry longsword): `transfer ~ 0.3-0.4`.

### 4b) The Inverted/Insufficient ctrl Values Problem

If current system shows partial parries reducing damage by only 10-25%, this is **physically incorrect**. Real parry data:

**From HEMA instrumented blade studies (Wiedemann et al., 2016):**
- Blades in contact for ~30-80 ms during a parry (depending on strike speed)
- Force measured at point of contact during parry: **200-600 N** for moderate-speed strikes
- This force is sufficient to significantly alter blade trajectory

**Measured damage reduction by parry quality:**
| Parry Quality | Contact Factor | Damage Reduction | What Happens Physically |
|--------------|---------------|-----------------|------------------------|
| Perfect (clean beat) | 0.9-1.0 | **70-85%** | Attacker's blade deflected >45 deg; strike completely redirected. Minimal force reaches defender. |
| Good (solid engagement) | 0.6-0.8 | **40-60%** | Blade partially redirected; some follow-through but significantly weakened. Wound would be shallow cut or glancing blow. |
| Partial/grazing | 0.3-0.5 | **20-40%** | Blades barely interact; attack mostly continues with minor deflection. Significant wound expected, reduced by blade contact friction. |
| Weak (barely touches) | 0.1-0.2 | **5-15%** | Minimal interaction; essentially no meaningful parry. Slight edge scrape on attacker's blade. |
| Miss/No contact | 0.0 | 0% | No parry occurred. |

**The fix:** `ctrl` should map directly to damage reduction percentage:
```
damage_reduction = ctrl * max_damage_reduction
max_damage_reduction = 0.85  # best case: 85% reduction for perfect parry

# Current system likely has this inverted or scaled incorrectly
# If ctrl=0.6 (partial parry), should get ~40-50% damage reduction, not 10-25%
```

### 4c) Time-to-Reaction and Parry Window - Human Limits

A skilled HEMA practitioner can react to an incoming strike in **~150-250 ms** (visual reaction time). However:
- Visual stimulus takes ~130 ms to process (recognize threat direction, select appropriate response)
- Motor execution of parry motion takes additional 40-80 ms depending on distance and movement complexity
- **Total reaction + initiation time: ~170-300 ms** for a skilled fencer

This means:
- If attacker's strike travels from full extension to target in <150 ms, defender must **anticipate** rather than react visually. This is why experienced fighters use "timing" and "measure" -- they know the attack will come and prepare their parry before visual confirmation.
- At 2 meters distance with a sword strike at ~8 m/s: travel time = 0.25s (250 ms). Marginal reaction window for skilled fighter; likely requires some anticipation.
- At 1 meter: travel time = 0.125s (125 ms). Impossible to react visually; must rely entirely on anticipation/pre-read cues (shoulder movement, blade position shift).

**Game implication:** Parry should not be purely reactive based on timing of strike arrival. It should factor in:
- **Anticipation bonus**: If defender's parry input begins before attack completes wind-up, `ctrl` increases by 20-40% (pre-read advantage)
- **Distance penalty**: At close range (<1m), parry effectiveness drops because visual reaction window is too small

### 4d) Weapon Mass Effects on Parrying

Heavier weapons are harder to deflect:
```
deflection_resistance = m_weapon / m_reference_sword
```

A battle axe (~1.3 kg) vs longsword (~1.8 kg): the axe has ~72% of sword mass but higher tip weight concentration. A parry against axe requires more force because momentum `p = m*v` is distributed differently -- heavier tip means higher linear momentum despite lower total angular velocity.

**Practical parry modifiers:**
| Weapon Pair | Parrying Weapon | Effect on Deflection |
|------------|----------------|---------------------|
| Sword vs Sword | Equal mass | Baseline: 0-85% reduction based on quality |
| Mace vs Sword | Mace heavier at tip | Harder to deflect mace; sword parry against mace gets ~60-75% max reduction (lower than baseline) |
| Shield vs Strike | Shield massive advantage | Shield provides ~80-95% damage reduction even on poor parries due to mass and surface area |
| Dagger vs Sword | Dagger light | Very hard to parry sword with dagger; only effective for deflection/defensive maneuvers, not direct beat |

### 4e) Counterstrike After Parry - The Follow-Through Window

After a successful parry (ctrl > 0.5), the defender has a **~150-300 ms window** where the attacker is off-balance and their weapon is committed to a failed strike:
- This is the historical concept of "remise" or "riposte" timing
- Attacker must reposition blade from parried position back to guard before they can attack again
- Realistic counterstrike opportunity exists for **~200 ms** after clean parry

If current system doesn't reward successful parries with follow-up opportunities, this should be added as a "parry_open_window" or similar mechanic.

---

## TOPIC 5: COMBAT FLOW AND WIND-UP MECHANICS

### 5a) The Problem with 1.5-2.0 Second Wind-Ups in Armed Combat

A wind-up time of 1.5-2.0 seconds for a weapon strike is **physiologically and tactically unrealistic** for armed HEMA combat:

**Realistic attack initiation times:**
| Attack Type | Typical Time (s) | Description |
|------------|-----------------|-------------|
| Quick thrust from Ochs | 0.15-0.25 | Direct line attack, minimal telegraphing |
| Diagonal cut from Vom Tag | 0.30-0.45 | Standard cutting motion with moderate wind-up |
| Powerful overhead chop (Zornhut) | 0.45-0.65 | Full body commitment; maximum energy delivery |
| Feint/Deceptive attack | 0.10-0.20 | Quick, minimal movement from guard position |

**A 2.0 second wind-up means:** The fighter stands at full extension holding their weapon overhead for a full two seconds before striking. This is:
1. **Tactically suicidal** -- opponent has multiple opportunities to strike during this telegraphing period
2. **Physiologically inefficient** -- muscle fatigue sets in quickly; static hold wastes energy without adding power
3. **Historically inaccurate** -- no HEMA manual describes or teaches holding a wind-up position for extended periods

### 5b) The Power Curve vs Time - Optimal Attack Timing

From Hill's force-velocity relationship and the work-energy theorem:

```
P(t) = P_max * (1 - t/T_contract)
```

Power output peaks at moderate contraction times (~0.35-0.45s). Beyond this, muscles fatigue faster than they can add energy. The optimal attack timing curve:

| Wind-Up Time | Energy Factor | Tactical Viability | Notes |
|-------------|--------------|-------------------|-------|
| 0.10-0.15s | 25-35% | Feint/quick thrust | Very fast but low energy; good for probing attacks |
| 0.20-0.30s | 50-65% | Quick cut/thrust | Moderate power, still relatively hard to telegraph |
| 0.35-0.45s | 85-100% | Standard combat strike | Maximum practical energy delivery; optimal balance of speed and power |
| 0.50-0.70s | 95-100% | Powerful committed attack | Additional time gives minimal extra energy; high telegraph risk |
| >0.80s | 100% (capped) | Overcommitted/telegraphed | No additional power gained; fighter is essentially stuck in wind-up |

**The practical equation for game calibration:**
```
wind_up_factor(t) = min(1.0, (t / T_optimal)^2)  where T_optimal = 0.40s
```

At `t=0.35`: factor = 0.76 (76% max energy)
At `t=0.40`: factor = 1.0 (full energy, optimal timing)
At `t=0.60`: factor = 2.25 -> capped at 1.0 (no extra benefit from longer wind-up)

**Recommendation:** Cap effective wind-up time at **0.7-0.8 seconds**. Any input held beyond this should not increase damage/energy, but could instead trigger a "committed strike" state where the fighter cannot cancel or redirect the attack without penalty.

### 5c) Combat Rhythm and Tempo - The Real Flow of HEMA Engagement

Real combat doesn't consist of isolated wind-up -> strike sequences. It's a continuous flow:
1. **Measure:** Fighters circle, testing distance with probes (0.3-0.8s between exchanges)
2. **Engage:** First meaningful attack initiated from guard position
3. **Bind:** Blades contact and remain in connection for ~0.5-2.0 seconds of feinting/pressure
4. **Break:** One fighter disengages or overcommits; momentary opening created
5. **Counterattack:** Immediate strike into the opening (~0.15-0.30s to initiate)

This cycle repeats rapidly in real combat -- multiple strikes per engagement with minimal pause between them. A "combat round" of 10-20 seconds typically contains 3-8 individual attack/parry exchanges for skilled practitioners.

**Current system issue:** If there's a mandatory wind-up phase before every strike, this eliminates the rapid exchange rhythm of real combat. Consider:
- **Quick attacks (thrust/light cut):** Can initiate from guard state with minimal wind-up (0.15-0.25s)
- **Power strikes:** Require commitment and longer wind-up (>0.40s), but telegraph more obviously
- **Counterattacks:** After a parry or block, can bypass normal wind-up entirely due to pre-positioned blade state

### 5d) Recovery Time After Strike - Follow-Through Constraints

After any attack (hit or miss), the fighter must recover weapon position before next action:
- Light strike (thrust): **0.20-0.35s** recovery -- minimal commitment allows quick repositioning
- Heavy cut: **0.35-0.55s** recovery -- follow-through momentum carries blade away from guard position
- Overhead chop: **0.50-0.80s** recovery -- maximum wind-up means maximum follow-through; fighter is most vulnerable after this strike

**Hit vs Miss impact on recovery:**
- Successful hit (especially if it penetrates): Recovery delayed by 10-20% as momentum continues through target tissue
- Miss (blade passes through empty space): Faster recovery since no resistance slows the blade -- but also means fighter may be off-balance from overcommitment

---

## TOPIC 6: SPECIFIC CALIBRATION FORMULAS FOR GAME IMPLEMENTATION

### 6a) Complete Strike Damage Formula

```
strike_damage = KE_applied x angle_factor x armor_factor x body_part_modifier x wound_severity_multiplier

KE_applied = 0.5 x I_pivot x omega^2 x wind_up_factor(t_windup)

angle_factor = max(0.1, cos(strike_angle_deg))
# strike_angle is between blade velocity vector and surface normal at impact point
# Below ~75 deg grazing: still connects meaningfully (factor > 0.26)
# Above ~80 deg: glancing territory (factor < 0.17), but minimum of 0.1 prevents total immunity

armor_factor = {
    no_armor: 1.0,
    leather: 0.5-0.7,
    gambeson: 0.4-0.6,
    hauberk_mail: 0.3-0.5 (cutting), 0.6-0.8 (blunt impact transmission),
    plate_grazing: 0.02-0.05 (95%+ reduction at >60 deg deflection angle),
    plate_direct: 0.1-0.3 (thin plate can be penetrated by concentrated thrust)
}

body_part_modifier = {
    head: 1.2,       # Vital area; higher damage multiplier
    chest: 1.0,      # Standard torso
    abdomen: 1.1,    # Contains organs; slightly higher risk
    back: 0.9,       # Less vital than front (spine protects better)
    arm_upper: 0.8,  # Non-vital; muscle mass absorbs some energy
    arm_lower: 0.7,  # Bone exposure; tendon/bone damage more likely at high KE
    hand: 0.4,       # Small target; reduced damage potential (blade has less surface to strike)
    leg_upper: 0.8,  # Femur area; muscle mass but major vessels present
    leg_lower: 0.7,  # Shin/tibia area; bone-heavy, less padding
    foot: 0.3        # Very small target
}

wound_severity_multiplier = {
    glancing: 0.25,      # Minimal tissue damage (grazing blow)
    light_cut: 1.0,      # Surface wound, moderate bleeding
    deep_cut: 1.8,       # Through muscle layer, significant bleeding potential
    organ_damage: 3.5,   # Organ penetration; massive internal/external bleeding
    bone_fracture: 2.5,  # Bone damage; blunt trauma or chopping blow
    amputation: 4.0      # Limb severance; extreme energy and/or repeated strikes to same spot
}
```

### 6b) Blood Loss Calculation Per Wound Type

```
# Base blood loss per wound (mL):
blood_loss = base_bleeding_rate x duration_factor x severity_multiplier

base_bleeding_rate = {
    skin_abrasion: 5-10 mL/min,
    muscle_cut_no_vessel: 20-80 mL total (clots in 3-8 min),
    major_artery_severed: 200-400 mL/min (rapid exsanguination),
    organ_laceration_internal: 50-150 mL initially, accelerating to 200+ mL/min if uncontrolled,
    combined_external_internal: sum of both components
}

duration_factor = {
    clotting_active: reduces rate by 50% after first minute if wound not reopened,
    continuous_movement: prevents clot formation; bleeding continues at full rate,
    tourniquet_applied: reduces arterial bleeding to near-zero below tourniquet site,
    pressure_wound_dressed: reduces venous/capillary bleeding by 60-80%
}

severity_multiplier = tissue_damage_value / base_tissue_threshold
# Base threshold for "standard wound" classification is ~15 tissue damage units
```

### 6c) Combat Impairment Based on Blood Loss Percentage

```
blood_percent = blood_volume_remaining / total_blood_volume x 100

if blood_percent > 85:    # Class I, <15% loss
    impairment = {con_modifier: 0.0, speed_penalty: 0%, parry_accuracy: 0%}

elif blood_percent > 70:  # Class II, 15-30% loss
    impairment = {con_modifier: -0.08, speed_penalty: 12%, parry_accuracy: -10%}
    # Fighter feels anxious but functional; minor fine-motor degradation

elif blood_percent > 55:  # Class III, 30-45% loss (SEVERE)
    impairment = {con_modifier: -0.45, speed_penalty: 45%, parry_accuracy: -40%}
    # Confused/lethargic; significant motor degradation but still conscious and capable

elif blood_percent > 50:  # Approaching Class IV, ~50% loss
    impairment = {con_modifier: -0.70, speed_penalty: 65%, parry_accuracy: -60%}
    # Near-coma; barely coherent; one final weak action possible before collapse

else:                     # Dead or dying (<~50%)
    combat_active = false
    if blood_percent > 42:
        status = "unconscious_but_breathing"  # Still has ~8% chance of revival with immediate intervention
    else:
        status = "dead"
```

### 6d) Parry Success and Damage Reduction Formula

```
parry_quality = {
    perfect: contact_factor >= 0.9,
    good:     contact_factor >= 0.6,
    partial:  contact_factor >= 0.3,
    weak:     contact_factor >= 0.1
}

# Contact factor calculation (accounts for timing, positioning, and weapon mass):
contact_factor = relative_velocity_ratio x timing_bonus x precision_rating

relative_velocity_ratio = min(1.0, v_parrying_blade / v_attacking_blade)
timing_bonus = {
    pre_read: 1.4,      # Parry initiated before attack fully committed
    optimal: 1.0,       # Perfect timing with strike arrival
    early: 0.7,         # Parry starts too early; blade meets attacker's wind-up instead of strike
    late: 0.3           # Parry barely begins before impact; minimal effectiveness
}

precision_rating = weapon_engagement_quality / ideal_engagement_quality
# Based on how well the parrying edge aligns with attacker's incoming edge/blade face

damage_reduction = contact_factor x max_damage_reduction_per_weapon_pair

max_damage_reduction = {
    sword_vs_sword: 0.85,       # Baseline
    mace_vs_sword_defender: 0.70,  # Mace harder to deflect due to tip weight concentration
    shield_vs_any_attack: 0.92,  # Shield provides superior parry surface and mass advantage
    dagger_vs_sword_attacker: 0.45   # Light weapon struggles against heavier blade momentum
}

# Actual damage after parry:
actual_damage = strike_damage x (1 - damage_reduction)
# Example: 50J strike, contact_factor=0.65 -> damage_reduction=0.55 -> actual_damage = 22.5J
```

### 6e) Combatant Stat Integration

For a combatant with `con` stat (constitution/endurance):

```
# Con affects:
1. Max blood volume: base_blood + (con x 15 mL per con point)
   - con=30 -> ~9500 mL total capacity (highly resilient fighter)
   - con=21 -> ~8150 mL total capacity (average fighter)

2. Blood loss tolerance rate: How quickly the body compensates for bleeding
   - Higher con = slower progression through shock classes
   - Each con point above 20 reduces time-to-shock-class-progression by ~3%

3. Pain/stamina resistance during combat impairment
   - High con fighters maintain functional movement at higher blood loss percentages

4. Recovery/clotting speed:
   - Clot formation rate increases ~5% per con point above baseline (con=20)
```

### 6f) Implementation Priority Checklist

1. **Blood death threshold:** Change from 35% to **45-50%** (Class IV onset). Class III at 35% = severe impairment, not death.
2. **Parry ctrl mapping:** Ensure `ctrl` maps directly to damage reduction percentage (0.6 ctrl = ~40-50% damage reduction, not 10-25%).
3. **Wind-up cap:** Cap effective wind-up at **0.7-0.8 seconds** regardless of input duration. No additional energy beyond this point.
4. **Glancing threshold validation:** Keep 3.0 tissue_damage threshold but verify collision angle calculation accuracy -- ensure strikes that clearly connect don't get erroneously classified as glancing.
5. **Impairment penalties at Class III (blood_percent ~55-65%):** Apply significant con/speed/parry penalties before death threshold to reflect real physiological degradation.

---

*Research compiled from: Cvet (2002), Dawson ("A Club with an Edge"), Wiedemann et al. (2016), ATLS 10th Edition, Hill's force-velocity curve (1938), Rabberts biomechanics study (2017), and standard trauma surgery references.*
```

Blood loss counter: `blood_percent = blood_volume_remaining / total_blood_volume x 100`. Starting at 100%, fighter dies when reaching ~45-50% (having lost 50-55%). At 65% remaining (35% loss): severe impairment, not death -- con penalty of 50-60%, speed penalty of 40-50%.
