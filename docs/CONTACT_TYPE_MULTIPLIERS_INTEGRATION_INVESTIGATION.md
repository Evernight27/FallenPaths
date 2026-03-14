# Contact Type Multipliers: Current System & Bind Riposte Integration

## Purpose

Inspect the current contact-type multiplier system, evaluate its physical accuracy, and determine the most physically grounded way to integrate bind riposte wind-up multipliers.

---

## 1. Current Contact-Type Multiplier System

### 1.1 PARRY_CONTACT_MODIFIERS (CombatConstants)

**What it does:** Modifies parry capacity based on *what the defender parries with* (their parry part).

```gdscript
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.88, "haft": 0.92}
```

| Parry Part | Multiplier | Physics |
|------------|------------|---------|
| blade | 1.0 | Baseline. Blade-on-blade best — flat catches edge, forte controls foible. |
| shaft | 0.88 | Wood shaft vs blade — edge can bite, less control. Spear/mace. |
| haft | 0.92 | Wood haft vs blade — slightly better than shaft (shorter, stiffer?). Axe. |

**Applied in:** `DefenseChoiceResolver._compute_parry_c_d()` — multiplies `c_d_full` after base capacity.

**Physical accuracy:** ✓ Good. Blade is optimal parrying surface; wood is worse. Haft vs shaft difference (0.92 vs 0.88) is plausible — haft often shorter, more rigid.

---

### 1.2 PARRY_DEF_VS_ATK_MOD (CombatConstants)

**What it does:** Modifies parry capacity based on *defender weapon type vs attacker contact type* (sparse overrides).

```gdscript
const PARRY_DEF_VS_ATK_MOD: Dictionary = {"DAGGER": {"stab": 0.9}, "MACE": {"blunt": 1.05}, "SPEAR": {"cut": 0.95}}
```

| Defender | vs Attacker | Mult | Physics |
|----------|-------------|------|---------|
| DAGGER | stab | 0.9 | Small blade vs thrust — point can slip past, harder to control. |
| MACE | blunt | 1.05 | Shaft absorbs blunt impact; percussion-on-percussion. |
| SPEAR | cut | 0.95 | Long shaft vs cut — blade can slide along or bite into wood. |

**Applied in:** `DefenseChoiceResolver._compute_parry_c_d()` — looks up `def_weapon.weapon_type` + `contact_type`. Missing entries default to 1.0.

**Physical accuracy:** ✓ The three entries are sensible. **Gap:** Sparse — SWORD, AXE have no overrides. Many def×atk combinations use 1.0 (implicit neutral).

---

### 1.3 Related: redirect_thrust_bonus, redirect_blunt_penalty (DefenseResolutionHandler)

**What they do:** Modify *redirect effectiveness* (partial parry) when shedding momentum.

- Thrust: +22% redirect (point deflects easily)
- Blunt: −12% redirect (momentum harder to shed)

**Scope:** Partial parry path only; does not affect full-stop parry capacity.

---

## 2. Bind Riposte System (Proposed)

**What it does:** Reduces wind-up when defender ripostes from a *bind* (blades in contact, defender in control).

**Proposed constants (from BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION):**
```gdscript
# Wind-up multiplier when riposting from bind. Lower = faster.
const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55   # Extend — minimal wind-up
const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78    # Wind along blade — moderate
const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90   # Swing head — significant wind-up
```

**Phase:** Post-parry, when defender chooses their next attack. Different from parry capacity (pre-parry).

---

## 3. Relationship Between Systems

| System | Phase | Keyed By | Purpose |
|--------|-------|----------|---------|
| PARRY_CONTACT_MODIFIERS | Parry capacity | Defender parry part | How well defender's *weapon* catches attacks |
| PARRY_DEF_VS_ATK_MOD | Parry capacity | def_weapon_type × atk_contact_type | Matchup-specific parry difficulty |
| redirect_thrust/blunt | Partial parry | Attack contact_type | How well momentum sheds |
| PARRY_BIND_RIPOSTE_MULT_* | Riposte wind-up | Defender's *riposte move* contact_type | How fast defender can follow up from bind |

**Key insight:** Parry capacity and bind riposte use contact_type for *different things*:
- **Parry capacity:** Attacker's contact_type (what's coming at defender)
- **Bind riposte:** Defender's chosen move's contact_type (what defender does next)

No overlap — they don't conflict. Integration is additive: add bind riposte constants and logic.

---

## 4. Physical Accuracy: Completing PARRY_DEF_VS_ATK_MOD

**Current:** 3 entries. **Default:** 1.0 for everything else.

**Should we add more?** For physical consistency, consider:

| Defender | vs Stab | vs Cut | vs Blunt | Rationale |
|----------|---------|--------|----------|-----------|
| SWORD | 1.0 | 1.0 | 0.95? | Blade vs blade neutral. Blade vs blunt — edge can chip, less ideal. |
| AXE | 0.92? | 0.92? | 1.0 | Haft vs thrust — point can slip. Haft vs cut — edge bites wood. Haft vs blunt — absorb. |
| MACE | 0.9 | 0.92? | 1.05 ✓ | Shaft vs thrust — slips. vs cut — bites. vs blunt — current. |
| DAGGER | 0.9 ✓ | 1.0 | 0.85? | Small vs thrust — current. vs cut — ok. vs blunt — overwhelmed. |
| SPEAR | 0.95? | 0.95 ✓ | 1.0 | Long vs thrust — point can slip past. vs cut — current. vs blunt — shaft absorbs. |

**Recommendation:** Keep sparse. The three existing entries address the most salient cases. Expanding to 15 entries (5×3) adds maintenance burden; default 1.0 is a reasonable neutral. Add overrides only when balance or realism clearly demands it.

---

## 5. Integration: Bind Riposte into Existing System

### Option A: Separate Constants (Recommended)

Add bind riposte constants alongside existing parry constants. No changes to PARRY_CONTACT_MODIFIERS or PARRY_DEF_VS_ATK_MOD.

```gdscript
# Bind riposte wind-up (separate from parry capacity). See BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION.
const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55
const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78
const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90
```

**Pros:** Clear separation of concerns. Parry capacity vs riposte speed are different phases. No risk of double-counting.  
**Cons:** None.

---

### Option B: Unified Contact-Type Table

Create one table for all contact-type–based modifiers:

```gdscript
# Parry/redirect/bind by contact_type. Keys: modifier purpose.
const CONTACT_TYPE_PARAMS: Dictionary = {
    "parry_def_vs_atk": {...},       # def_weapon × atk contact (sparse)
    "redirect_mult": {"stab": 1.22, "cut": 1.0, "blunt": 0.88},
    "bind_riposte_windup": {"stab": 0.55, "cut": 0.78, "blunt": 0.90}
}
```

**Pros:** Single place for contact-type logic.  
**Cons:** Restructure. redirect is currently thrust_bonus + blunt_penalty (additive), not per-type. Would need refactor. Overkill for bind riposte.

---

### Option C: Extend PARRY_DEF_VS_ATK_MOD for Bind

Reuse PARRY_DEF_VS_ATK_MOD for bind riposte: when defender has parry_was_bind, look up `def_weapon_type` × `riposte_move_contact_type` for wind-up mult.

**Problem:** PARRY_DEF_VS_ATK_MOD keys defender vs *attacker* contact. Bind riposte keys defender's *chosen* move contact. Semantically different. Also, PARRY_DEF_VS_ATK_MOD is parry capacity (× c_d), not wind-up (× time). Would conflate two uses of the same table.

**Verdict:** Don't reuse. Keep bind riposte as its own constants.

---

### Option D: Parry-Part–Aware Bind Mult (Max Physics)

Combine defender parry part with riposte contact type:

```gdscript
# bind_riposte_mult = f(parry_part, riposte_contact_type)
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
    "blade": {"stab": 0.52, "cut": 0.75},
    "shaft": {"stab": 0.54, "cut": 0.80, "blunt": 0.90},
    "haft": {"stab": 0.53, "cut": 0.78}
}
```

**Pros:** Most physically detailed. Blade thrust from blade bind vs shaft thrust from shaft bind could differ slightly.  
**Cons:** Sparse matrix (blade/haft have no blunt riposte). More constants. Marginal gain over contact-type-only (stab 0.55, cut 0.78, blunt 0.90) for 5 weapons.

**Verdict:** Option A (contact-type only) is sufficient. Add Option D only if tuning shows parry-part matters.

---

## 6. Recommended Integration (Most Physically Accurate)

### 6.1 Keep Current Systems As-Is

- **PARRY_CONTACT_MODIFIERS:** No change. Blade/shaft/haft already reflect parry-part physics.
- **PARRY_DEF_VS_ATK_MOD:** No change. Sparse overrides for salient cases; 1.0 default is fine.
- **redirect_thrust/blunt:** No change. Handles partial parry correctly.

### 6.2 Add Bind Riposte (Option A)

1. **CombatConstants.gd:**
   ```gdscript
   # Bind riposte wind-up. Defender's riposte move contact_type — extend=fast, swing=slow.
   const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55
   const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78
   const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90
   # Or as dict for lookup: PARRY_BIND_RIPOSTE_MULT_BY_CONTACT
   ```

2. **Eligibility:** Only when move's contact_type is in weapon's bind-riposte-eligible set (from parry moves). Axe: add `bind_riposte_contact_types: ["cut", "stab"]` for spike.

3. **AttackWindUpStarter:** After `wind_up_s *= trans_mult`, if bind conditions + eligibility: `wind_up_s *= get_bind_riposte_mult(contact_type)`.

### 6.3 Optional: Weapon Overrides for Edge Cases

If tuning shows need:
```gdscript
const PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE: Dictionary = {
    "MACE": 0.92,   # Shaft bind + blunt = heaviest follow-up
    "DAGGER": 0.50  # Lightest; thrust dominant
}
```
Use override when present; else contact-type mult.

---

## 7. Summary

| System | Action | Rationale |
|--------|--------|-----------|
| PARRY_CONTACT_MODIFIERS | Keep | Already physically sound |
| PARRY_DEF_VS_ATK_MOD | Keep sparse | Default 1.0 is fine; add only when needed |
| Bind riposte | Add new constants | Separate phase; contact-type mults (0.55/0.78/0.90) match extend vs wind vs swing |
| Parry-part × contact matrix | Skip for now | Marginal benefit; contact-type-only is enough |

**Most physically accurate integration:** Add `PARRY_BIND_RIPOSTE_MULT_*` (or `PARRY_BIND_RIPOSTE_MULT_BY_CONTACT` dict) as a separate concern. Use defender's riposte move's `contact_type` for lookup. Do not merge with PARRY_DEF_VS_ATK_MOD or PARRY_CONTACT_MODIFIERS.
