# How Damage Is Calculated (Kinetic System) and Consistency With Physics / Medical Literature

## 1. How damage is calculated

### Step 1: Kinetic energy (J)

```
KE = ½ × mass_kg × velocity_m/s²
```

- **mass_kg**: weapon mass (e.g. 1.2 kg sword, 1.7 kg mace).
- **velocity_m/s**: effective impact speed from the attack (6–18 m/s, derived from **power** and **follow_through** below, or explicit `velocity_m_s` on the attack).

So harder/heavier/faster swings → more KE. **This step is standard physics.**

#### Where velocity comes from: power and follow_through (game parameters)

Velocity is **not** rolled directly. Each attack has two 0.0–1.0 game parameters that scale it:

| Parameter | Represents (in-game) | How it’s calculated | Used in formula |
|-----------|------------------------|----------------------|------------------|
| **power** | How much force the attacker puts into the swing (intent/commitment). | **Random per attack:** `randf_range(0.2, 1.0)` in CombatManager. No strength, weapon, or player input yet. | `factor = (0.5 + 0.5×power) × (0.5 + 0.5×follow_through)`; velocity = VELOCITY_MIN_M_S + (VELOCITY_MAX_M_S − VELOCITY_MIN_M_S) × factor. |
| **follow_through** | Follow-through / commitment to the swing (how much they “carry through”). Comment also mentions “recovery cost” (not yet used). | **Random per attack:** `randf_range(0.2, 1.0)` in CombatManager. Same as power—no other inputs. | Same as power: both multiply into one factor that scales velocity. |

- **Calculation today:**  
  In `CombatManager.resolve_action()`, when building an `AttackInstance`:  
  `follow_through = _follow_through_from_stats(atk)` and `power = _power_from_stats(atk)` (stats + random).  
  So both are **purely random** per swing; neither is derived from strength, weapon type, skill, or player choice.

- **How they affect damage:**  
  In `WeaponDamageHelper.get_effective_velocity_m_s()`:  
  `factor = (0.5 + 0.5*power) * (0.5 + 0.5*follow_through)` → factor in [0.25, 1.0].  
  That factor linearly scales velocity between 6 and 18 m/s, so KE = ½ m v² (and thus pre-armor damage and penetration) all depend on both power and follow_through.

- **Naming note:**  
  **follow_through** is an abstract “carry-through” knob (wind-up, recovery, impact speed). Physical momentum (p = mv) is never computed; only KE is used for damage.

---

### Step 2: Pre-armor damage (abstract “amount”)

```
raw = DAMAGE_KE_SCALE × √(KE) × (strength / 10) × arm_mod
pre_armor_damage = clamp(raw, DAMAGE_KE_MIN, DAMAGE_KE_MAX)   →  [1, 80]
```

- **DAMAGE_KE_SCALE** = 2.6 (tuning constant).
- **√(KE)**: damage grows with the square root of energy (e.g. 4× KE → 2× damage).
- **strength / 10**: stronger attacker multiplies damage (min 0.1).
- **arm_mod**: arm function (e.g. injured arm &lt; 1.0).
- Result is **clamped to 1–80** before armor.

So “damage” here is an **abstract magnitude** (your HP scale), not joules or a medical score.

---

### Step 3: Penetration (for armor)

- **Sharp:** `pen_mm_rha = (KE / J_PER_MM_RHA) × (baseline / contact_width_cm)^0.5` (smaller contact → deeper penetration).
- **Blunt:** `pen_mpa = pressure_MPa` from `BLUNT_PRESSURE_SCALE × KE / A_m²` (impact pressure).

Armor then uses these to decide deflection vs penetration and how much damage is reduced.

---

### Step 4: Armor reduction

- **ArmorPiece.apply_damage(pre_armor_damage, damage_type, penetration_sharp, penetration_blunt)**:
  - Compares penetration to each layer’s resistance (mm RHA for sharp, MPa for blunt).
  - Deflection: sharp fails to penetrate → damage halved, rest as blunt.
  - Penetration: damage reduced by a factor from resistance/penetration.
- Output: **damage_remaining** (still an abstract number).

---

### Step 5: Apply to body

- **CoreEntity.take_damage(final_amount, part, damage_type, …)**:
  - **final_amount** = armor’s damage_remaining (rounded to int).
  - **Split:** If final_amount ≥ BONE_DAMAGE_THRESHOLD, a fraction goes to **bone_health**, rest to tissue (body_cutting or body_blunt). Otherwise all to tissue. Severance when tissue 0 and bone 0; fracture when bone 0 (see BODY_PART_AND_BONE_SYSTEM.md).
  - Death when vital part (head/chest) has tissue 0 (cutting or blunt).

So the **only** place that uses KE directly in the “damage number” is step 2: **pre_armor_damage = f(√(KE), strength, arm_mod)**, then armor and body use that same abstract scale.

---

## 2. Consistency with physics

| Element | In your system | Physics | Verdict |
|--------|----------------|---------|--------|
| KE formula | KE = ½ m v² | Standard. | **Correct.** |
| More KE → more damage | √(KE) in pre-armor | More energy → more potential injury. | **Consistent.** |
| Penetration vs armor | Sharp: mm RHA from KE + contact area; blunt: pressure from KE/area | Penetration and pressure are standard in ballistics/impact. | **Consistent.** |
| Contact area | Used for penetration (sharp and blunt), **not** for pre-armor damage | In reality, same KE on smaller area → higher pressure → often more severe local injury. | **Gap:** damage does not depend on contact area; only penetration does. |

So: **energy and pressure are used in a physics-consistent way for penetration.** The main physics gap is that **pre-armor damage does not depend on contact area** (stab vs cut with same KE currently give the same pre-armor damage; only penetration differs).

---

## 3. Consistency with medical / injury literature

| Idea | In your system | Medical / biomechanics | Verdict |
|------|----------------|------------------------|---------|
| Energy and severity | √(KE) → damage | Blunt injury often related to energy; relationship is non-linear and criterion-dependent (thresholds, power law). √(KE) is a plausible, simple shape. | **Plausible**; not a 1:1 copy of any single medical index. |
| “Damage” number (1–80) | Abstract HP | No medical scale is “X J = Y points.” AIS, ISS, etc. are categorical or composite. | **Abstract by design**; not directly comparable to real injury scores. |
| Strength / arm function | strength_mod, arm_mod | Stronger person can deliver more force/KE; injured arm reduces force and control. | **Consistent** with “who is striking” and “functional capacity.” |
| Armor reduces injury | Armor reduces pre-armor → final damage | Armor absorbs energy and limits penetration; less energy/penetration → less injury. | **Consistent.** |
| Sharp vs blunt pools | body_cutting vs body_blunt; deflection turns sharp → blunt | Real impacts can have both cutting and blunt components; deflection as “sharp fails, blunt remains” is a reasonable simplification. | **Consistent.** |
| Contact area and severity | Not in damage | Concentrated force (small area) is associated with deeper wounds, fractures, focal injury. | **Gap:** medically, same KE with smaller contact area often implies more severe local damage; your damage formula doesn’t reflect that. |

So: **directionally your system matches how energy, armor, and sharp vs blunt are thought about in injury mechanics**, but the **absolute “damage” values are game abstractions**, and **contact area affects penetration but not the damage number**.

---

## 4. Summary

- **How damage is calculated:**  
  KE from mass and velocity → **pre_armor_damage = scale × √(KE) × strength_mod × arm_mod** (clamped 1–80) → armor reduces it using penetration (mm RHA and MPa) → remainder is subtracted from body_cutting or body_blunt.

- **Consistent with physics:**  
  KE formula; “more KE → more damage”; penetration and blunt pressure from KE (and contact area). **Not yet:** pre-armor damage does not depend on contact area.

- **Consistent with medical literature:**  
  Non-linear (√) link from energy to severity; strength and arm function; armor reducing injury; sharp vs blunt and deflection. **Not:** “damage” is not tied to a real injury scale; contact area is not used in the damage magnitude.

If you want to push the system closer to physics and medical intuition, the next step is to **make pre-armor damage depend on contact area** (e.g. multiply by a factor like `(baseline / contact_width)^β` so that stab with same KE does more damage than cut), while keeping the same penetration and armor logic.

---

## 5. Power and follow_through: is this the best system?

**Pros of the current setup**

- **Simple:** Two 0–1 knobs give variance per swing without extra subsystems.
- **Consistent:** Both feed one velocity factor → KE → damage/penetration, so “stronger” (power/follow_through) always means more impact.
- **Extensible:** You can later drive power/follow_through from strength, skill, stance, or player input instead of pure RNG.

**Limitations**

- **Fully random today:** Neither power nor follow_through is tied to stats, weapon, or intent. Every swing is `randf_range(0.2, 1.0)` for both. That’s good for variance but not for “stronger character / better weapon = more reliable hard hits.”
- **“Momentum” ≠ physics:** The name suggests p = mv, but here it’s an abstract follow-through. If you want to avoid confusion, consider renaming (e.g. `follow_through` or `commitment`).
- **Recovery cost unused:** AttackInstance comments mention “recovery cost” for follow_through; that could drive cooldown or next-turn penalty and isn’t implemented yet.

**Alternatives**

- **Single knob:** One 0–1 “intensity” or “velocity factor” instead of power × follow_through. Simpler; less variance.
- **Stats in the mix:** e.g. `power = randf_range(0.2, 1.0) * (strength / 10)` or bias the range by weapon/skill so stronger/skilled fighters have higher average.
- **Player/situation input:** If the player chooses “light / normal / heavy” attack, map that to power (and optionally follow_through) instead of full random.
- **Physical momentum:** If you ever want real p = mv in the formula (e.g. for knockback or a different damage curve), compute v from your factor then p = m×v and use it where needed.

**Verdict:** The **equation** (factor from power and follow_through → velocity → KE) is sound and flexible. The **source** of power and follow_through (pure RNG) is the main design choice; tying them to stats or intent would make the system feel more responsive to character and player without changing the rest of the pipeline.
