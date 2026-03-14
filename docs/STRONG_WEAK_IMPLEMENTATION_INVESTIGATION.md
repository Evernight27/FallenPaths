# Strong/Weak System Implementation Investigation

Investigation into different implementation approaches for the strong/weak contact system, and whether it applies to non-blade weapons (shaft, haft) or is blade-specific.

---

## 1. HEMA Concept: Strong vs Weak

**Definition (Liechtenauer, i.33):**
- **Strong** = portion of the weapon near the guard/hands. Maximum mechanical advantage; defender controls the bind.
- **Weak** = portion near the tip. Minimum leverage; easier for opponent to push aside or deflect.

**Blade parry ideal:** "Catch the weak of their blade on the strong of yours." Defender wants: (a) their blade at strong (near hilt), and (b) attacker's blade at weak (near tip). Both matter.

---

## 2. Implementation Approaches (Blade Weapons)

### 2.1 Option A: Archetype-Only (Current)

**Current:** `PARRY_STRONG_CONTACT_BY_ARCH` — per attacker archetype: overhead 1.12, slash 1.0, stab 0.98, heavy_blunt 1.08, quick_slash 0.95.

**Logic:** OVERHEAD exposes more weak (blade angled down, tip leads); defender more likely to catch weak. Slash/horizontal = moderate. Quick slash = less exposed.

**Pros:** Already implemented; zero schema change; simple.
**Cons:** No defender geometry; no blade length; attacker-only. Doesn't model "defender's strong fraction."

---

### 2.2 Option B: Defender Strong Fraction (Length-Based)

**Data:** For blade parrying parts, `strong_fraction = handle_length / total_length`. E.g. sword: 30/(30+90) = 0.25. So ~25% of blade is "strong" (near guard).

**Use:** Parry capacity × `(1 + STRONG_CONTACT_BONUS * contact_quality)`. When defender catches attacker's weak (archetype OVERHEAD), contact_quality is high. Bonus scales with how much of defender's parrying surface is "strong."

**Formula options:**
- `bonus = STRONG_BONUS_MAX * (1 - strong_fraction)` — more strong zone = larger bonus when you use it. Or
- `bonus = STRONG_BONUS_MAX * strong_fraction * weak_exposure` — weak_exposure from archetype (OVERHEAD=1.0, SLASH=0.5, etc.)

**Example:** Sword strong_fraction 0.25, OVERHEAD weak_exposure 1.0 → bonus = 0.12 * 0.25 * 1.0 = 0.03 (3% capacity). Tune STRONG_BONUS_MAX.

**Pros:** Uses actual blade geometry; refines PARRY_STRONG_CONTACT_BY_ARCH.
**Cons:** Need handle_length, total_length (or infer from parts: handle length_cm / sum lengths).

---

### 2.3 Option C: Attacker Weak Exposure (Move/Moment)

**Data:** Each move has `weak_exposure: float` 0–1. OVERHEAD = 1.0 (tip leads, most weak exposed); THRUST = 0.8 (point leads); SLASH = 0.5; QUICK_SLASH = 0.3 (quick, less commitment).

**Use:** `parry_c_d *= (1 + STRONG_CONTACT_BONUS * weak_exposure)`. Replaces or augments archetype lookup with move-specific value.

**Pros:** Finer granularity than archetype.
**Cons:** More data entry; may duplicate archetype info.

---

### 2.4 Option D: Bidirectional (Defender Strong × Attacker Weak)

**Full model:** Both defender's strong fraction and attacker's weak exposure.

```
contact_quality = defender_strong_zone_used * attacker_weak_exposed
parry_c_d *= (1 + STRONG_BONUS_MAX * contact_quality)
```

- Defender strong zone: from blade length. "Zone used" could be 1.0 when alignment good (defender controlled contact), else random 0.5–1.0.
- Attacker weak exposed: from archetype or move.

**Pros:** Most physically accurate.
**Cons:** Most complex; two variables to tune.

---

### 2.5 Option E: Alignment as Strong-Weak Proxy (Already Partially There)

**HEMA_DEFLECTION_IMPLEMENTATION:** "Good alignment ≈ strong-on-weak contact. Misaligned = poor contact."

**Current:** Alignment already multiplies parry_c_d. Same-line parry (alignment high) = Vier Versetzen = proper geometry = strong-on-weak. Cross-line = worse contact.

**Implication:** Alignment already encodes "contact quality" including strong/weak. PARRY_STRONG_CONTACT_BY_ARCH adds an *attacker* dimension (OVERHEAD exposes weak). So we have:
- Defender geometry → alignment (partially; also guard position)
- Attacker exposure → strong_contact_by_arch

**Question:** Is adding defender strong_fraction redundant with alignment? Alignment = cos(θ) attack vs guard. Strong-on-weak = *where* on each blade contact happens. Related but distinct: you can have good alignment (same line) but poor strong-on-weak (blades meet at mutual weak). So they're complementary.

---

## 3. Does Strong/Weak Apply to Non-Blade Weapons?

### 3.1 Shaft (Spear, Mace)

**Physics:** A pole has the same leverage principle. Contact near the hands = strong (defender has mechanical advantage). Contact far from hands (near tip) = weak (attacker can push the shaft aside more easily).

**Historical:** Polearm shaft "can be used as a very effective lever to push away, trip, or otherwise control an opponent." (Historical sources) The whole shaft structure creates leverage; where contact occurs determines who controls.

**Current implementation:** We already have `_get_leverage_factor(def_weapon, alignment)` for shaft/haft when parry part length > 80 cm. Formula: `lerp(0.65, 1.0, alignment)`. Good alignment → 1.0 (strong, near hands). Poor alignment → 0.65 (weak, far from hands).

**Conclusion:** **Already implemented** for shaft/haft. The leverage factor IS the shaft analogue of strong/weak. No additional system needed for spear/mace parrying.

---

### 3.2 Haft (Axe)

**Physics:** Same as shaft. Haft parries (Le Jeu de la Hache) — contact near grip = strong; contact near blade = weak. Axe haft is 90 cm; our leverage factor applies (length > 80).

**Conclusion:** **Already covered** by the same leverage factor. Haft parries behave like shaft parries for strong/weak purposes.

---

### 3.3 Blade (Sword, Dagger)

**Physics:** Strong = near guard; weak = near tip. Distinct from shaft because:
- Blade has a *cutting edge* — strong vs weak affects bind quality (flat parry, edge alignment) beyond pure leverage.
- Blade strong/weak is HEMA-specific terminology; sword systems emphasize it.
- Shaft strong/weak is pure leverage; no edge.

**Conclusion:** Blade warrants its **own** refinement (Options B–E). Shaft/haft use leverage factor; blade uses strong_fraction + archetype/move.

---

### 3.4 Mixed Weapons (Axe)

Axe can parry with **blade** or **haft** (Le Jeu). Currently parry_part_id = "haft" for axe. If we added "blade" as parry option for some moves, blade parries would use blade strong/weak; haft parries use leverage factor.

**For now:** Axe parries with haft → leverage factor applies. No blade strong/weak for axe parries (we're not modeling axe blade parries).

---

## 4. Summary: What Applies Where

| Defender Parry Part | Strong/Weak Concept | Current Implementation | Additional Needed? |
|---------------------|---------------------|-------------------------|-------------------|
| Blade (sword, dagger) | Strong = near guard; weak = near tip. Defender catches attacker's weak on defender's strong. | PARRY_STRONG_CONTACT_BY_ARCH (attacker archetype only) | Option: add defender strong_fraction from blade/handle lengths |
| Shaft (spear, mace) | Strong = near hands; weak = far. Same leverage principle. | `_get_leverage_factor` — alignment → 0.65–1.0 for length > 80 cm | **No** — already modeled |
| Haft (axe) | Same as shaft | Same leverage factor | **No** |
| Handle (sword/dagger) | N/A — handle doesn't parry; blade does | — | — |

---

## 5. Recommended Implementation Paths

### Path 1: Minimal (Keep Current)

- Rely on PARRY_STRONG_CONTACT_BY_ARCH for blade.
- Rely on leverage factor for shaft/haft.
- **Effort:** 0.

### Path 2: Blade Strong Fraction Only

- For defender weapons with parry_part_id = "blade", compute `strong_fraction = handle_length / total_length` from parts.
- When attacker archetype has high weak exposure (OVERHEAD), multiply parry_c_d by `(1 + STRONG_BONUS * strong_fraction)`.
- Replace or augment PARRY_STRONG_CONTACT_BY_ARCH. If augmenting: `parry_c_d *= strong_contact_by_arch` (current) and also `*= (1 + length_based_bonus)`.
- **Effort:** Low. Need `get_parry_strong_fraction()` in Weapon.gd. Sword: handle 30, blade 90 → 30/120 = 0.25. Dagger: 12/32 = 0.375.

### Path 3: Full Bidirectional

- Defender strong_fraction + attacker weak_exposure from move.
- Most accurate; most tuning.
- **Effort:** Medium.

---

## 6. Recommendation

**For blade weapons (sword, dagger):** Implement **Path 2** — add `get_parry_strong_fraction()` using existing part lengths. When parry_contact_type is "blade" and attacker archetype is OVERHEAD (or has high weak_exposure), apply `(1 + 0.08 * strong_fraction)` or similar. This refines the current archetype modifier with defender geometry. Tune to taste.

**For shaft/haft:** **No additional work.** The leverage factor already models "contact point along the weapon" — which is the shaft/haft equivalent of strong/weak.

**Unifying principle:** Both blade and shaft/haft have "strong near hands, weak far." Blade uses an explicit strong_fraction (from lengths) because HEMA sources emphasize it and blade geometry is more complex (edge, flat). Shaft/haft use alignment as a proxy (good alignment = defender controlled contact = strong) — sufficient for polearm mechanics without adding a parallel system.

---

## 7. Data Requirements (If Path 2)

Weapon parts already have length_cm. For sword:
- blade: 90 cm, parry_eligible
- handle: 30 cm, not parry_eligible

strong_fraction = handle_length / (handle_length + blade_length) = 30/120 = 0.25.

Or: strong_fraction = length of "strong zone" / parry_part_length. Convention: strong zone = 1/3 of blade nearest guard? So 30 cm of 90 cm blade = 0.33. Simpler: strong_fraction = handle / total.

```gdscript
func get_parry_strong_fraction() -> float:
    if not has_parts():
        return 0.25  # Legacy default
    var handle_len: float = 0.0
    var parry_len: float = get_parry_part_length_cm()
    for p in parts:
        if p is Dictionary:
            var pid: String = str(p.get("id", ""))
            var plen: float = float(p.get("length_cm", 0))
            if pid in ["handle", "haft"]:  # "haft" for axe where haft parries
                handle_len = plen
                break
    var total: float = 0.0
    for p in parts:
        if p is Dictionary:
            total += float(p.get("length_cm", 0))
    if total <= 0 or parry_part_id.to_lower() != "blade":
        return 0.25
    return clampf(handle_len / total, 0.1, 0.5)
```

Only used when defender parries with blade. Returns 0.25 for sword, ~0.375 for dagger. Axe parries with haft — not blade — so this wouldn't apply (or would return default). Mace/spear: parry with shaft, leverage factor applies, not strong_fraction.

---

## 8. References

- HEMA_FIDELITY_IMPROVEMENTS.md §A (Blade Geometry)
- WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md §4.1, §11
- WEAPON_PART_MODEL_IMPLEMENTATION_PLAN.md Phase 6
- HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md (alignment as strong-on-weak proxy)
- DefenseChoiceResolver.gd: _get_leverage_factor, PARRY_STRONG_CONTACT_BY_ARCH
- Weapon.gd: parts, get_parry_part_length_cm, get_parry_contact_type
