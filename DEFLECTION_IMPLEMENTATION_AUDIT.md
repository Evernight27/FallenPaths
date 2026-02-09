# Deflection & Armor Implementation Audit

Audit of where the deflection/armor changes (Option D + 6.1 durability, realism A for transmission) are implemented and how they are reflected in the UI.

---

## 1. Systems: What’s Implemented

### 1.1 Armor (ArmorPiece + ArmorConstants)

| Feature | Status | Where |
|--------|--------|--------|
| Sharp→blunt on deflect (transmission only) | ✓ | `ArmorPiece._process_layer`: `after_deflect = damage * layer.deflection_transmission` |
| Deflected blunt run outer→inner (all layers in order) | ✓ | `ArmorPiece.apply_damage`: on deflect, loop `for j in range(layers.size())` with BLUNT |
| Per-layer deflection_transmission | ✓ | `ArmorConstants`: cloth 0.18, leather 0.25, mail 0.35, plate 0.45 |
| Return was_deflected, deflected_blunt_amount | ✓ | `ArmorPiece.apply_damage` return dict |
| Durability: min damage vs armor value | ✓ | `ArmorConstants.DURABILITY_MIN_DAMAGE_FLAT`, `DURABILITY_MIN_DAMAGE_RATIO`; `_apply_durability_loss` threshold |
| Per-layer durability rate | ✓ | Each layer has `durability_loss_rate` (cloth 0.20, leather 0.15, mail 0.12, plate 0.08) |

### 1.2 Damage & wounds (CoreEntity)

| Feature | Status | Where |
|--------|--------|--------|
| Blunt from deflection vs direct tracked | ✓ | `take_damage_split`: `blunt_from_deflection`, `blunt_from_direct` from armor results |
| Bruise vs crush for deflected blunt | ✓ | Deflected portion: `DEFLECTION_BRUISE_THRESHOLD` or minor severity → bruise; else crush. Direct → crush. |
| Severity from reduced damage | ✓ | `_severity_from_damage(part, damage, sub_region)` used for all wounds (cut, bruise, crush, fracture) |
| Return was_deflected to caller | ✓ | `take_damage_split` returns `was_deflected: blunt_from_deflection > 0` |
| Minor crush → bruise fallback | ✓ | `_add_wound`: if CRUSH and severity minor, treat as bruise |

### 1.3 Bleeding & healing

| Feature | Status | Where |
|--------|--------|--------|
| Bruise: 0 bleed, all severities | ✓ | `BleedingConstants.BLEEDING_RATES[INJURY_TYPE_BRUISE]` = 0 |
| Bruise healing duration | ✓ | `HealingConstants.get_wound_healing_duration_seconds`: `WOUND_TYPE_BRUISE` uses `BRUISE_HEAL_DURATION_BY_SEVERITY` |
| Pain from bruise (0-bleed wounds) | ✓ | `get_total_pain()` sums all wounds; bruise has severity multiplier, 0 bleed |

### 1.4 Single-stream path (take_damage)

| Feature | Status | Where |
|--------|--------|--------|
| Backward compatible | ✓ | Uses `armor.apply_damage`; only reads `result.get("damage")`, `result.get("damage_type")`. Extra keys ignored. |

### 1.5 Combat (CombatManager)

| Feature | Status | Where |
|--------|--------|--------|
| Calls take_damage_split, gets final_cut/blunt/bone | ✓ | `resolve_action` |
| Outcome "deflected" when tissue damage &lt; 25% pre_armor | ✓ | `outcome = "deflected"` when `(final_cut + final_blunt) < pre_armor * DEFLECTED_DAMAGE_RATIO` |
| Passes was_deflected in result_dict | ✓ | `result_dict["was_deflected"] = take_result.get("was_deflected", false)` for UI/tooltips |
| Recovery longer for "deflected" | ✓ | `_recovery_duration`: `RECOVERY_EXTRA_DEFLECTED_S` when outcome == "deflected" |

### 1.6 Character

| Feature | Status | Where |
|--------|--------|--------|
| take_damage_split delegated to CoreEntity | ✓ | `character.gd`: `_combat_body.take_damage_split(...)` |

---

## 2. UI: What’s Reflected

### 2.1 Combat log (BattleScene)

| Item | Reflected? | How |
|------|------------|-----|
| Outcome "deflected" | ✓ | `elif outcome == "deflected":` → line with "(deflected)" and cut/blunt breakdown |
| Damage (cut/blunt) | ✓ | `result.final_cut`, `result.final_blunt` in the log line |
| was_deflected | Available | In `result` as `result.get("was_deflected", false)`; not yet shown in text (could add e.g. "armor deflected" when true) |

### 2.2 Equipment / armor (BattleScene, PartyMenu)

| Item | Reflected? | How |
|------|------------|-----|
| Armor names per part | ✓ | `get_armor_slots()`, `piece.display_name` |
| Armor durability % | ✗ | `ArmorPiece.get_durability_percent()` exists but is not displayed in the UI |

### 2.3 Wounds

| Item | Reflected? | How |
|------|------------|-----|
| Wound count / wounded parts | ✓ | `get_wounded_parts()` for medical actions (bandage, pressure, tourniquet) |
| Wound type (bruise vs crush vs cut) | ✗ | Stored in `wounds[part][].injury_type`; no UI currently lists "Bruise" vs "Crush" per wound. Pain and bleeding use the type; healing duration uses it (bruise uses bruise duration). |

---

## 3. Summary

- **Fully implemented across systems:** Armor deflection (transmission, outer→inner blunt pass), durability (min damage + per-layer rates), deflected vs direct blunt tracking, bruise vs crush wound creation, severity from reduced damage, bleeding/healing for bruise, and combat outcome "deflected" with recovery and result payload (including `was_deflected`) are all wired through.
- **UI aligned:** Combat log shows "deflected" and cut/blunt; damage numbers and outcome are correct. `was_deflected` is in the result for future UI (e.g. "armor deflected").
- **UI not yet shown (optional):**
  - **Armor durability %** – data and API exist; no equipment panel or tooltip shows it.
  - **Wound type (bruise/crush/cut)** – used for pain, bleeding, and healing; no screen lists wound types by name.

Transmission is **Option A (damage at deflecting layer)** throughout; no Option C minimum is used, so realism A is kept.
