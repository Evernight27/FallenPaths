# Attack Archetypes, Velocity/Intensity Arcs, and Cut/Blunt Split

Design for: (1) contact area in damage, (2) attack archetypes with windup→velocity/intensity arcs, (3) every attack applying a split of cut + blunt so weapon shape and attack type matter.

---

## 1. Overview

| Piece | Purpose |
|-------|--------|
| **Contact area in damage** | Smaller contact (stab) → higher local damage per joule; thick blade → more blunt component. |
| **Attack archetypes** | Overhead, quick slash, stab, pommel, etc. each have a **velocity/intensity arc** (windup time → effective speed/commitment) so long windups deliver more KE. |
| **Cut/blunt split** | Every hit applies some to `body_cutting` and some to `body_blunt`. Thick swords bruise/break bones more; pommel/mace still “break skin” (small cut component). |

---

## 2. Contact area in damage

**Current:** Contact area affects **penetration** only; pre-armor damage is `scale × √(KE) × strength_mod × arm_mod`.

**Change:** Multiply pre-armor damage by a **contact factor** so concentrated force does more “local” damage:

```
contact_damage_factor = (BASELINE_CONTACT_CM / contact_width_cm)^CONTACT_DAMAGE_EXPONENT
```

- `CONTACT_DAMAGE_EXPONENT` in [0.2, 0.5] (e.g. 0.3): stab (0.3 cm) gets ~(2/0.3)^0.3 ≈ 1.7×, cut (2 cm) stays 1.0×. Keeps damage in a sane band.
- Same KE: stab > cut in pre-armor damage; penetration was already stab-favored. Optionally cap the factor (e.g. max 2.0) so one stab doesn’t overscale.

Apply this in `WeaponDamageHelper.compute_pre_armor_damage()` after the current formula, using the attack’s contact width (from weapon + attack type or archetype).

---

## 3. Attack archetypes and velocity/intensity arcs

**Idea:** Each **attack** is an archetype (e.g. `overhead`, `quick_slash`, `stab`, `pommel_strike`, `heavy_blunt`) with:

- **Velocity arc:** How windup/commitment maps to impact speed. Long windup → higher velocity (and KE); quick flick → lower.
- **Intensity arc:** Optional separate curve for “commitment” (recovery cost, etc.); can share or mirror the velocity arc.
- **Contact:** Override or use weapon default (point_width, blade_width, head_diameter).
- **Cut ratio:** 0.0–1.0 (rest blunt). Defines the split for this attack.

**Data shape (per archetype):**

```gdscript
# Attack archetype: id, velocity factor (0–1 or multiplier), contact override, cut_ratio.
# velocity_factor: 1.0 = full windup → full velocity; 0.5 = quick attack → half velocity band.
# Optional: windup_time or recovery_multiplier for state machine.
{
  "id": "overhead",
  "velocity_factor": 1.0,      # Uses full intensity → full velocity (long windup)
  "intensity_bias": 0.2,       # Min intensity (can't do a "light" overhead)
  "contact_override_cm": -1.0, # -1 = use weapon default for attack type
  "cut_ratio": 0.6,            # 60% cut, 40% blunt (thick sword)
  "recovery_multiplier": 1.2   # Longer recovery after big swing
}
```

**Where intensity comes from:** Keep current: intensity from strength + random in CombatManager. The **archetype** then maps that to effective velocity:

- **Effective velocity for KE:** `velocity = VEL_MIN + (VEL_MAX - VEL_MIN) * intensity * archetype.velocity_factor`  
  So “overhead” (factor 1.0) uses full band; “quick_slash” (e.g. 0.6) compresses it (quicker but less KE).
- **Windup/recovery:** If you add windup_time to the state machine, archetype can define `windup_multiplier` and `recovery_multiplier` so overhead has longer windup and recovery than quick slash.

**Weapon × attack type → archetype:** Weapon still defines available attack types (stab, cut, blunt). Each can map to a **default archetype** (e.g. cut → “slash”) or you can define multiple archetypes per weapon (overhead slash, quick slash, pommel) and pick by RNG or later by player choice. For a first pass: one archetype per (weapon, attack_type), e.g. sword+cut → “slash” (velocity 0.9, cut_ratio from weapon).

**Weapon blade “thickness” (cut ratio):** Add to weapon definition:

- `blade_cut_ratio` or `cut_fraction`: 0.85 = slim blade (85% cut, 15% blunt), 0.5 = thick (50/50). Default per weapon type; overridden by archetype if needed.
- Dagger: high cut ratio; mace: 0.0 (all blunt) or 0.05 (“break skin”); pommel strike: 0.05.

So: **velocity/intensity arc** = archetype’s velocity_factor (and optional intensity_bias / recovery_multiplier). **Cut/blunt split** = archetype cut_ratio, possibly overridden by weapon’s blade cut_ratio for slashing attacks.

---

## 4. Split damage (cut + blunt every hit)

**Current:** One damage type per hit; one call to `take_damage(amount, part, damage_type, pen_s, pen_b)`; armor returns one stream; one pool (cut or blunt) is reduced.

**Change:** Every attack produces **two** pre-armor amounts: `pre_cut`, `pre_blunt` (with `pre_cut + pre_blunt = pre_total`, and ratio from archetype/weapon). Then:

1. **Armor:** Apply armor **twice** (conceptually): once for sharp (pre_cut, pen_sharp, pen_blunt for deflect path), once for blunt (pre_blunt, blunt pen). You already have deflection (sharp→blunt) in ArmorPiece; so:
   - Sharp stream: `armor.apply_damage(pre_cut, SHARP, pen_s, pen_b)` → `final_cut` (type may become BLUNT if deflected; then add that to blunt stream or treat as blunt for that portion).
   - Blunt stream: `armor.apply_damage(pre_blunt, BLUNT, 0, pen_b)` → `final_blunt`.

2. **Deflection:** When sharp is deflected, armor returns `damage_type: BLUNT` and reduced amount. So the “cut” stream can become blunt-after-armor. Easiest: run armor once per stream; sharp stream may return BLUNT and reduced value → add that to the blunt total for the target. So:
   - `result_cut = armor.apply_damage(pre_cut, SHARP, ...)` → if result_cut.damage_type == BLUNT, add result_cut.damage to blunt side; else add to cut side.
   - `result_blunt = armor.apply_damage(pre_blunt, BLUNT, ...)` → add to blunt side.
   - Then apply `final_cut` to body_cutting, `final_blunt` to body_blunt (with bone split per pool if you want, or one combined bone split from total severity).

3. **API:** Add `take_damage_split(pre_cut, pre_blunt, part, pen_sharp, pen_blunt)` that:
   - Runs armor for cut portion (SHARP); if deflected, adds that amount to blunt portion.
   - Runs armor for blunt portion (BLUNT).
   - Applies bone split per pool (or from combined damage); subtracts from body_cutting and body_blunt.
   - Returns `{ "final_cut": int, "final_blunt": int }` for UI/logging.

**Bone damage:** Today bone split is per hit (threshold, fraction). With split you can:
- **Option A:** Split bone by source: cut damage → bone from cut pool, blunt → bone from blunt pool (same threshold/fraction per pool).
- **Option B:** Combined severity: `total_final = final_cut + final_blunt`; one bone threshold/fraction from total (simpler; blunt-heavy hits still break bones more because they contribute more to total).

Option B is simpler and matches “blunt breaks bones more”: blunt-heavy attacks naturally add more to total and thus to bone.

**Pommel / mace “break skin”:** Use cut_ratio 0.05–0.1 so most damage is blunt but a tiny cut component remains (armor can still deflect that cut; the rest goes through as blunt). No need for a separate “skin break” mechanic unless you want a status effect later.

---

## 5. Implementation order

1. **Contact area in damage**  
   In `WeaponDamageHelper.compute_pre_armor_damage()`, multiply by `(BASELINE_CONTACT_CM / contact_width)^β`, using existing `get_contact_width(weapon, attack_type)`. Add `CONTACT_DAMAGE_EXPONENT` (e.g. 0.3) and optional max factor (e.g. 2.0) in WeaponConstants.

2. **Cut/blunt ratio and split**  
   - Add `cut_ratio` to attack archetype and/or weapon (weapon: `blade_cut_ratio` for slashing; blunt attack type → 0.0; pommel → 0.05).  
   - In CombatManager: compute `pre_armor` total, then `pre_cut = pre_armor * cut_ratio`, `pre_blunt = pre_armor * (1 - cut_ratio)`.  
   - Add `CoreEntity.take_damage_split(cut_pre, blunt_pre, part, pen_s, pen_b)` (and same for character.gd) that applies armor to each stream (sharp deflected → add to blunt), then applies to body_cutting/body_blunt with one combined bone split from total final damage.  
   - CombatManager calls `take_damage_split`, then reports both pools in the log (e.g. “cut -3, blunt -5”).

3. **Attack archetypes**  
   - Define archetype table (overhead, quick_slash, stab, pommel, heavy_blunt, etc.) with velocity_factor, cut_ratio, optional recovery_multiplier.  
   - Map (weapon, attack_type) → archetype (default: one archetype per attack type, cut_ratio from weapon for cut/slash).  
   - In CombatManager: when building AttackInstance, set intensity as now; after choosing attack_type, look up archetype and set `velocity_factor` (or pass archetype to helper).  
   - In `WeaponDamageHelper.get_effective_velocity_m_s()`: multiply the intensity-derived factor by `archetype.velocity_factor` so quick slash uses a lower velocity band.  
   - Optionally: archetype `recovery_multiplier` in `_recovery_duration()` so overhead has longer recovery.

4. **Weapon blade thickness**  
   In weapon definitions, add `blade_cut_ratio` (or per-attack-type cut ratio). Use when resolving cut_ratio for the hit (archetype override or weapon default).

---

## 6. Summary

- **Yes:** Tie damage to contact area (factor from contact width) so physics reflect “concentrated force → more local damage.”  
- **Yes:** Add attack archetypes (overhead, quick slash, stab, pommel, etc.) with velocity/intensity arcs (windup → velocity factor, optional recovery) so long windups deliver more KE and feel different from quick attacks.  
- **Yes:** Have every attack do a cut/blunt split so thick swords bruise/break bones more, slim blades cut more, and pommel/mace still have a small cut component.  

Implement in order: (1) contact area in damage, (2) cut/blunt split + `take_damage_split`, (3) archetypes and velocity arcs, (4) weapon blade thickness and archetype mapping.
