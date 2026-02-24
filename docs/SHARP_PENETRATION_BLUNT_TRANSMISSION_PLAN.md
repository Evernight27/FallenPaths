# Implementation Plan: Sharp = Penetration, Blunt = Transmission

## Overview

Switch the armor system so that:
- **Sharp (cutting):** Penetration model — armor either stops the edge (deflection) or it cuts through (penetration).
- **Blunt:** Transmission-only model — armor never "penetrates" blunt; force always transmits proportionally to the strike.

---

## Phase 1: Audit All Implementation Points

### 1.1 Damage Flow Entry Points

| Location | Method | Damage Type | Penetration Used |
|----------|--------|-------------|------------------|
| `ui/CombatManager.gd` | `_execute_attack` | Split (cut + blunt) | pen_sharp, pen_blunt, pen_blunt_momentum_per_area |
| `ui/CombatManager.gd` | Fallback (no weapon) | Single stream | pen_sharp, pen_blunt for take_damage |
| `core/CoreEntity.gd` | `take_damage_split` | Split | Passes to armor.apply_damage |
| `core/CoreEntity.gd` | `take_damage` | Single | Passes to armor.apply_damage |
| `character.gd` | Passthrough | — | Forwards to _combat_body |
| *(removed)* | Combat.gd was legacy; BattleScene/CombatManager is sole combat system | — | — |
| `tests/TestBattle.gd` | Scripted tests | Split | pen_sharp, pen_blunt (500, 3000, 2500) |

### 1.2 Armor Processing

| Location | Logic |
|----------|-------|
| `armor/ArmorPiece.gd` | `apply_damage` → `_process_layer` |
| `_process_layer` | SHARP: pen vs sharp_res → penetrate or deflect. BLUNT: pen vs blunt_res → penetrate or deflect. |

### 1.3 Penetration Computation

| Location | Output |
|----------|--------|
| `weapon/WeaponDamageHelper.gd` | `compute_penetration(DAMAGE_TYPE_SHARP)` → pen_sharp, pen_blunt (deflect) |
| `weapon/WeaponDamageHelper.gd` | `compute_penetration(DAMAGE_TYPE_BLUNT)` → pen_blunt, momentum_per_area (explodes for stabs) |

### 1.4 Constants

| File | Relevant Constants |
|------|-------------------|
| `armor/ArmorConstants.gd` | DEFLECTION_TRANSMISSION_DEFAULT, BLUNT_BAT_TRANSMISSION, BLUNT_CUSHION_MOMENTUM_THRESHOLD, layer blunt_bat_transmission, deflection_transmission |
| `weapon/WeaponConstants.gd` | BLUNT_PRESSURE_SCALE, BLUNT_MOMENTUM_TO_MPA, MIN_BLUNT_AREA_M2, etc. |

---

## Phase 2: ArmorPiece Changes (Core Logic)

### 2.1 Add Blunt-Transmission-Only Mode

**File:** `armor/ArmorPiece.gd`

**Current behavior for BLUNT in `_process_layer`:**
- If `pen_mpa < blunt_res` → deflect (transmission)
- Else → penetrate (damage reduction factor)

**New behavior for BLUNT:**
- Always use transmission. Never use penetration branch.
- Remove the `current_pen >= layer_res` penetration path for BLUNT.
- For BLUNT: `after_transmission = damage * transmission`, where transmission = f(layer, momentum_per_area).

**Implementation:**
```gdscript
# In _process_layer, when damage_type == BLUNT:
# ALWAYS deflect (transmission) — never penetrate
if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
    var base_tx: float = layer.get("blunt_bat_transmission", ArmorConstants.BLUNT_BAT_TRANSMISSION)
    var cushion: float = layer.get("blunt_cushion", 0.0)
    if blunt_momentum_per_area < 0.0 or cushion <= 0.0:
        transmission = base_tx * (1.0 - cushion)
    else:
        var thresh: float = ArmorConstants.BLUNT_CUSHION_MOMENTUM_THRESHOLD
        var momentum_factor: float = clampf(1.0 - blunt_momentum_per_area / thresh, 0.0, 1.0)
        transmission = base_tx * (1.0 - cushion * momentum_factor)
    var after_transmission: float = damage * transmission
    _apply_durability_loss(layer, damage - after_transmission)
    return {"damage": after_transmission, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}
```

**Multi-layer blunt:** Each layer applies transmission. Current loop already processes layer-by-layer; for blunt we never "break" from penetration — we always apply transmission and continue to next layer with reduced damage.

**Critical:** The current loop structure: when blunt "deflects", it continues to inner layers with `damage_remaining` as blunt. We keep that. We just never take the penetration branch for blunt.

### 2.2 Update `apply_damage` Signature (Optional)

We can keep `penetration_blunt` in the signature for backward compatibility but ignore it for the rigid check. Or remove it from the blunt path. **Recommendation:** Keep signature; document that `penetration_blunt` is ignored for blunt (only `penetration_blunt_momentum_per_area` matters for cushion).

---

## Phase 3: Momentum/Area for Blunt Transmission

### 3.1 Problem: Explosion for Stabs

`compute_penetration(DAMAGE_TYPE_BLUNT)` returns `momentum_per_area` which can be 300,000+ for stabs. The cushion formula uses it:
`momentum_factor = 1 - momentum_per_area / 3000` → clamps to 0, so cushion fully overwhelmed.

**Options:**
- **A) Cap momentum_per_area** before passing to armor: `min(momentum_per_area, 2 * BLUNT_CUSHION_MOMENTUM_THRESHOLD)` so cushion can still matter for extreme cases.
- **B) Leave as-is** — heavy thrusts overwhelm padding (realistic). No change needed.
- **C) Scale momentum_per_area** for sharp-dominant attacks so it stays in a sensible range.

**Recommendation:** **B** — leave momentum_per_area uncapped. A spear thrust should overwhelm padding. The explosion in pen_blunt is fixed by not using it; momentum_per_area is only for cushion, and 300k overwhelming 3k threshold is correct.

### 3.2 Ensure momentum_per_area Is Always Provided

For blunt transmission, we need `penetration_blunt_momentum_per_area` for cushion. Currently CombatManager gets it from `compute_penetration(DAMAGE_TYPE_BLUNT)`. We still need that call — but we can simplify it to only return `momentum_per_area` (and optionally remove pen_blunt computation).

---

## Phase 4: WeaponDamageHelper Simplification

### 4.1 Remove or Simplify Blunt Penetration Computation

**File:** `weapon/WeaponDamageHelper.gd`

**Current:** `compute_penetration(DAMAGE_TYPE_BLUNT)` returns `penetration_blunt` (explodes) and `penetration_blunt_momentum_per_area`.

**New:** 
- Keep `compute_penetration(DAMAGE_TYPE_BLUNT)` but only compute and return `penetration_blunt_momentum_per_area`.
- Return `penetration_blunt: 0.0` or a sentinel — it will be ignored by armor.
- **Alternative:** Add `compute_blunt_momentum_per_area(weapon, attack_instance)` and use that. CombatManager would call it instead of full compute_penetration for blunt.

**Recommendation:** Keep `compute_penetration(DAMAGE_TYPE_BLUNT)` for API consistency. Return `penetration_blunt: 0.0` (or -1.0 to indicate "not used"). The momentum_per_area is the only value used.

---

## Phase 5: CoreEntity.take_damage_split Changes

### 5.1 Blunt Processing

**File:** `core/CoreEntity.gd`

**Current:** Calls `armor.apply_damage(blunt_pre_val, DAMAGE_TYPE_BLUNT, 0.0, pen_b, penetration_blunt_momentum_per_area, 0)`.

**New:** Same call. Armor will ignore pen_b for the rigid check and always use transmission. No change needed in CoreEntity — the change is entirely in ArmorPiece.

### 5.2 Deflected Sharp → Blunt

When sharp deflects, we get `deflected_raw`. That is processed as BLUNT with `apply_damage(deflected_raw, DAMAGE_TYPE_BLUNT, 0.0, pen_b, ...)`. The deflected sharp becomes blunt trauma. With blunt=transmission-only, that will use transmission. **No change** — already correct.

---

## Phase 6: CombatManager Changes

### 6.1 Penetration Computation

**Current:**
```gdscript
var pen_sharp_dict = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_SHARP)
var pen_blunt_dict = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_BLUNT)
pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
pen_blunt = pen_blunt_dict.get("penetration_blunt", -1.0)
pen_blunt_momentum_per_area = pen_blunt_dict.get("penetration_blunt_momentum_per_area", -1.0)
```

**New:** Keep the same. pen_blunt will be 0 or unused; pen_blunt_momentum_per_area is still needed. Optionally stop passing pen_blunt to take_damage_split if we want to clean up — but keeping it avoids signature changes. Armor will ignore it.

### 6.2 Debug Print

Update the print to not imply pen_blunt matters for blunt: e.g. "pen_sharp=%.2f mm RHA | blunt: transmission only (momentum/A=%.0f)"

---

## Phase 7: CoreEntity.take_damage (Single Stream)

### 7.1 Blunt-Only Damage

**Current:** `armor.apply_damage(amount_val, DAMAGE_TYPE_BLUNT, pen_s, pen_b, penetration_blunt_momentum_per_area)`.

**New:** Same. Armor ignores pen_b for rigid check. If `penetration_blunt_momentum_per_area` is -1 (not provided), cushion uses base only. **Ensure** callers that deal blunt-only damage (e.g. fallback unarmed) pass a sensible momentum_per_area or -1. CombatManager fallback uses `take_damage(pre_blunt, ..., DAMAGE_TYPE_BLUNT, -1.0, pen_blunt, -1.0)` — momentum -1 is fine, cushion will use base.

---

## Phase 8: Physics-Accurate Numbers

### 8.1 Transmission Values (ArmorConstants)

Current layer values (from code):

| Layer | blunt_bat_transmission | blunt_cushion | deflection_transmission |
|-------|------------------------|---------------|-------------------------|
| Cloth | 0.50 | 0.80 | 0.16 |
| Leather | 0.58 | 0.50 | 0.24 |
| Mail | 0.70 | 0.20 | 0.36 |
| Plate | 0.80 | 0.00 | 0.46 |

**Physics rationale:**
- **Plate:** Rigid, transmits most force (0.80). No cushion (0). Sharp deflection 0.46 — plate stops the cut but transmits ~46% as blunt.
- **Mail:** Transmits trauma (0.70). Little cushion (0.2).
- **Cloth:** Absorbs impact (0.50 blunt, 0.16 sharp deflection). High cushion (0.8).
- **Leather:** Between cloth and mail.

**Verification:** These are already in a sensible order. Plate > mail > leather > cloth for transmission. No changes needed unless tuning.

### 8.2 BLUNT_CUSHION_MOMENTUM_THRESHOLD

Current: 3000 (kg·m/s)/m².

**Reference:** Mace 1.7 kg, 12 m/s, 8 cm head → p/A ≈ 4080. Above 3000, so cushion overwhelmed. Realistic.

**Recommendation:** Keep 3000. Document that thrusts (high p/A) will overwhelm cushion.

### 8.3 Sharp Penetration (Unchanged)

Sharp still uses: pen_sharp vs sharp_resistance_rha_mm. PENETRATION_DAMAGE_REDUCTION_MAX = 0.5. J_PER_MM_RHA = 80. All remain as-is.

---

## Phase 9: Test Updates

### 9.1 TestBattle.gd

**Current calls:**
- `take_damage_split(2.0, 2.0, part, 2.0, 500.0)` — pen_sharp 2, pen_blunt 500
- `take_damage_split(6.0, 6.0, part, 3.0, 3000.0)`
- `take_damage_split(5.0, 3.0, "chest", 2.5, 2500.0)`

**New:** pen_blunt is ignored. Tests should still pass. For blunt transmission, we need momentum_per_area. Currently tests don't pass it — `take_damage_split` has no 4th/5th/6th param for momentum. Checking signature: `take_damage_split(cut_pre, blunt_pre, part, penetration_sharp, penetration_blunt, penetration_blunt_momentum_per_area)`. So 6 params. Tests use 5: `(2.0, 2.0, part, 2.0, 500.0)` — that's cut, blunt, part, pen_sharp, pen_blunt. No momentum. Default -1. So cushion uses base. **Tests will behave differently** — blunt will always use transmission. With pen_blunt 500, currently that might have penetrated some layers. Now it won't. So test outcomes may change. **Update tests** to expect transmission-only blunt. The mangled limb test, severed limb test, chest wounds — verify they still produce expected outcomes. If not, adjust test expectations or add new assertions.

---

## Phase 10: Documentation and Comments

### 10.1 ArmorPiece

Add header comment:
```
# SHARP: Penetration model. pen_sharp vs sharp_resistance → penetrate or deflect.
# BLUNT: Transmission-only model. Force always transmits; no penetration check.
#       Uses blunt_bat_transmission and cushion (momentum_per_area) for absorption.
```

### 10.2 ArmorConstants

Update comments to state blunt is transmission-only. blunt_resistance_mpa is no longer used for penetration check; could be repurposed later for durability or kept for reference.

### 10.3 DAMAGE_PHYSICS_EXPLOSION_FIX_OPTIONS.md

Add note that the chosen fix is "Blunt = Transmission Only" — removes need for pen_blunt entirely.

---

## Implementation Order

1. **ArmorPiece._process_layer** — Implement blunt transmission-only (never penetrate).
2. **WeaponDamageHelper** — Simplify compute_penetration(DAMAGE_TYPE_BLUNT) to only return momentum_per_area; set pen_blunt = 0 or document as unused.
3. **CombatManager** — Update debug print.
4. **Tests** — Run TestBattle; adjust expectations if needed.
5. **Documentation** — Update ArmorPiece, ArmorConstants, plan doc.

---

## Verification Checklist

- [x] Sharp damage: still penetrates or deflects based on pen_sharp vs sharp_res.
- [x] Sharp deflection: converts to blunt, uses transmission through layers.
- [x] Blunt damage: always uses transmission; never penetration branch.
- [x] Blunt cushion: momentum_per_area still affects transmission when cushion > 0.
- [x] Multi-layer armor: blunt applies transmission per layer, damage reduces through stack.
- [x] No pen_blunt explosion: pen_blunt no longer used for rigid check.
- [x] take_damage (single stream) BLUNT: works with momentum -1 (base transmission).
- [x] take_damage_split: deflected + direct blunt both use transmission.
- [ ] TestBattle: scripted tests pass or expectations updated (run in Godot editor).
- [x] CombatManager fallback (no weapon): still works.

---

## Rollback

If issues arise: revert ArmorPiece._process_layer to restore blunt penetration branch (pen vs blunt_res). Keep WeaponDamageHelper changes (or revert) as desired. The system is backward-compatible at the API level; only behavior changes.
