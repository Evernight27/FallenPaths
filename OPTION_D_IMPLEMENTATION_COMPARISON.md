# Option D: Implementation Approaches Compared

Option D = full medical deflection model: **(A)** per-layer deflection transmission, **(B)** deflected blunt passes through inner layers, **(C)** deflected + low blunt → bruise wound.

Below are **four concrete implementation strategies**, with advantages, drawbacks, and code impact. All achieve the same behavior; they differ in where logic lives, how many armor calls you make, and how much the API changes.

---

## Shared requirements (all approaches)

- **Data:** Each layer (or layer type) needs a **deflection transmission** value (e.g. plate 0.45, mail 0.35, leather 0.25, cloth 0.18) used instead of the fixed `damage / 2.0`.
- **B (inner absorption):** When a layer deflects, the resulting blunt damage must be reduced by **remaining (inner) layers** before returning.
- **C (bruise vs crush):** The entity must know “this blunt came from a deflected sharp” and “how much of total blunt is from deflection vs direct,” so it can create **bruise** (0 bleed) when deflected + low/minor, else **crush**.
- **Deflected vs direct blunt:** When a hit has both a sharp stream (deflected → blunt) and a direct blunt stream, `to_blunt` is split by ratio so the deflected portion can become bruise and the direct portion crush. So we need either:
  - `blunt_from_deflection` and `blunt_from_direct` (or equivalent) from the armor step, or
  - A single “was_deflected” plus the **amount** of blunt that came from the sharp call (so entity can compute the ratio).

All four strategies below assume we track deflected blunt amount for C.

---

## Strategy 1: Single-pass armor, extended return (recommended default)

**Idea:** Armor does A and B in one `apply_damage()` pass. It returns a few extra fields. Entity does C and ratio-splitting for wound type.

### Flow

1. **ArmorPiece.apply_damage(incoming, type, pen_s, pen_b):**
   - Loop layers as now. When **sharp** fails to penetrate:
     - Use layer’s `deflection_transmission` (or default) instead of `0.5` → `after_deflect = damage * transmission`.
     - Apply same layer’s blunt reduction to `after_deflect`.
     - Set `damage_remaining = after_deflect`, `current_damage_type = BLUNT`, **do not break**; continue loop so inner layers further reduce this blunt (B).
   - Track `was_deflected: bool` (true if any layer deflected during this call) and, when the **incoming** type was SHARP and we end with BLUNT, set `deflected_blunt_amount: float` = final damage (so caller knows how much of the returned value is “from deflection”).
   - Return `{ damage, damage_type, was_deflected, deflected_blunt_amount }`. For non-deflected or blunt-in calls, `deflected_blunt_amount = 0.0`.

2. **CoreEntity.take_damage_split:**
   - For sharp stream: call `apply_damage(cut_pre, SHARP, ...)`; get `d`, `dtype`, `was_deflected`, `deflected_blunt_amount`. If BLUNT, add `d` to `final_blunt` and store `blunt_from_deflection = d` (and mark that we have deflected blunt). For blunt stream: call `apply_damage(blunt_pre, BLUNT, ...)`; add to `final_blunt` and store `blunt_from_direct = that amount`.
   - When creating wounds: split `to_blunt` into deflected vs direct by ratio (`to_blunt_deflected = to_blunt * (blunt_from_deflection / total_final)`). For deflected portion: if below threshold or severity minor → `_add_wound(..., INJURY_TYPE_BRUISE, ...)` else crush. For direct portion: always crush.

### Advantages

- **Single armor call per stream** — no new methods, no two-phase flow.
- **All armor logic in one place** — deflection + inner-layer absorption stay inside ArmorPiece; easy to reason about and test.
- **Small API extension** — only two new return keys (`was_deflected`, `deflected_blunt_amount`); backward compatible if callers ignore them.
- **Clear separation** — armor = “how much gets through”; entity = “what wound type (bruise vs crush).”

### Drawbacks

- **Armor return type grows** — every caller gets the extra keys (can default them for non-deflection paths).
- **Entity must implement ratio split** — slightly more logic in `take_damage_split` (deflected vs direct blunt and two wound branches).

### Code touch points

- **ArmorPiece:** `_process_layer` uses layer `deflection_transmission`; on deflect return `deflected: true` but **caller** (apply_damage loop) does not break—instead sets damage/type and continues. Loop tracks `was_deflected` and, when incoming was SHARP and final type is BLUNT, sets `deflected_blunt_amount = damage_remaining`. Return dict extended.
- **ArmorConstants:** Add `deflection_transmission` per layer (or per LAYER_* constant).
- **CoreEntity.take_damage_split:** Track `blunt_from_deflection` and `blunt_from_direct`; when adding blunt wounds, split by ratio and apply bruise vs crush rule for deflected portion.

---

## Strategy 2: Two-call armor (entity drives inner absorption)

**Idea:** Armor returns after the **first** deflecting layer (no inner absorption inside one call). Entity sees `was_deflected` and `deflecting_layer_index`; then calls a **second** method to run the deflected blunt through inner layers only.

### Flow

1. **ArmorPiece.apply_damage(...):**
   - On deflect: use per-layer transmission, compute `after_deflect`, then **break** and return `{ damage: after_deflect, damage_type: BLUNT, was_deflected: true, deflecting_layer_index: i }` (no inner-layer absorption in this call).

2. **New method:** `apply_blunt_from_layer_index(blunt_damage: float, pen_blunt: float, from_layer_index: int) -> float`  
   - Runs only layers `from_layer_index + 1` through end. Returns remaining damage. So “inner absorption” is a separate call.

3. **CoreEntity.take_damage_split:**
   - Sharp stream: `result_cut = armor.apply_damage(...)`. If `result_cut.was_deflected` and `result_cut.deflecting_layer_index < layers.size() - 1`, call `apply_blunt_from_layer_index(result_cut.damage, pen_blunt, result_cut.deflecting_layer_index)` and use that as the deflected blunt amount; else use `result_cut.damage`.
   - Rest as in Strategy 1 (track deflected vs direct blunt, bruise vs crush).

### Advantages

- **Explicit two-phase model** — “outer layer deflects” then “inner layers absorb”; easy to log and debug per phase.
- **Thin first call** — `apply_damage` stays close to current behavior (still breaks on deflect); new behavior is a second, focused method.
- **Reusable inner pass** — `apply_blunt_from_layer_index` could be used elsewhere (e.g. “blunt only to inner layers” for a different mechanic).

### Drawbacks

- **Two calls from entity** when deflection happens — more branching and slightly more complex flow in `take_damage_split`.
- **New public method** — armor API grows; callers must know to call it when `was_deflected` and there are inner layers.
- **Index coupling** — entity must pass `deflecting_layer_index`; if armor layer order changes, behavior stays correct but the contract is more fragile than “armor does it all.”

### Code touch points

- **ArmorPiece:** `apply_damage` returns `was_deflected`, `deflecting_layer_index`; on deflect still `break`. New `apply_blunt_from_layer_index(blunt_damage, pen_blunt, from_index)`.
- **CoreEntity.take_damage_split:** After sharp `apply_damage`, if deflected and inner layers exist, call `apply_blunt_from_layer_index` and use result as `blunt_from_deflection`; else use `result_cut.damage`. Same wound logic as Strategy 1.

---

## Strategy 3: Armor suggests wound type (medical rule in armor)

**Idea:** Armor does A and B in one pass (like Strategy 1) but also decides “would this be bruise or crush?” and returns a **suggested wound type** for the blunt portion, so entity doesn’t need the bruise threshold or severity logic.

### Flow

1. **ArmorPiece.apply_damage(...):**
   - Implements A and B as in Strategy 1. Additionally, when it would return `was_deflected: true` and `damage_type: BLUNT`, it computes a **suggested wound type**: if final damage &lt; BRUISE_THRESHOLD (e.g. 2.0) or a simple severity check → `suggested_blunt_wound_type = "bruise"`, else `"crush"`. Returns `{ damage, damage_type, was_deflected, deflected_blunt_amount, suggested_blunt_wound_type }`. For non-deflected blunt, `suggested_blunt_wound_type = "crush"` (or omit).

2. **CoreEntity.take_damage_split:**
   - Tracks deflected vs direct blunt amounts as in Strategy 1. When creating the **deflected** portion of blunt wound, use `suggested_blunt_wound_type` from the **sharp** stream result (bruise vs crush). Direct blunt always crush.

### Advantages

- **Single place for “deflected + low → bruise”** — medical rule lives in armor (or a small helper armor uses); entity just trusts the suggestion. Tuning (threshold, severity) is in one place.
- **Entity stays dumb** — no bruise threshold or severity logic in CoreEntity; only “add wound of this type.”

### Drawbacks

- **Armor depends on wound semantics** — armor must know about “bruise” vs “crush” and a threshold. If you later add more wound types or rules (e.g. by body part), armor either grows or you move the rule out anyway.
- **Mixed responsibilities** — armor is both “physics” (transmission, absorption) and “injury classification.” Some teams prefer to keep injury type entirely in the entity/medical layer.
- **Deflected vs direct split still in entity** — entity still must split `to_blunt` by ratio and apply the suggested type only to the deflected portion; so entity logic doesn’t shrink much.

### Code touch points

- **ArmorPiece:** Same as Strategy 1, plus at the end of apply_damage (when was_deflected and damage_type == BLUNT) set `suggested_blunt_wound_type = "bruise"` if damage &lt; ArmorConstants.BRUISE_THRESHOLD else `"crush"`. Return it.
- **ArmorConstants:** Add BRUISE_THRESHOLD (or read from a shared medical constant).
- **CoreEntity.take_damage_split:** Use `result_cut.suggested_blunt_wound_type` for the deflected portion of blunt wound; direct blunt always crush. Ratio split unchanged.

---

## Strategy 4: Staged pipeline (outer vs inner as separate steps)

**Idea:** Refactor armor into two conceptual steps: **outer layers** (can deflect sharp and convert to blunt) and **inner layers** (only absorb blunt). So “deflection” is “outer step,” “inner absorption” is “inner step.” Implementation can be one loop with a “phase” or two separate loops over layer ranges.

### Flow

1. **Option 4a — Two methods:**  
   - `apply_outer_layers(damage, type, pen_s, pen_b)` → `{ damage, damage_type, was_deflected, deflected_blunt_amount }`. Runs layers 0..k (e.g. k = 0 for “first layer only,” or all layers that have sharp resistance above a threshold).  
   - `apply_inner_layers(blunt_damage, pen_blunt)` → `damage`. Runs remaining layers (e.g. gambeson-only).  
   - Entity: for sharp, call outer; if was_deflected, call inner with deflected amount; use that as blunt_from_deflection. Then call outer for blunt stream (or a single “apply all” that delegates internally).

2. **Option 4b — Single method, phase flag:**  
   - `apply_damage(..., inner_only: bool = false, start_layer: int = 0)` — when `inner_only` true, only processes blunt through layers from start_layer. So entity first call gets was_deflected and deflecting_layer_index; second call is apply_damage(blunt_damage, BLUNT, 0, pen_b, true, deflecting_layer_index + 1). Same as Strategy 2 but framed as “inner phase” of same API.

### Advantages

- **Very explicit model** — “outer stops blade, inner cushions” is visible in the API. Good for documentation and for designers who think in layers.
- **Clear testing** — you can unit-test “outer only” and “inner only” separately.

### Drawbacks

- **Defining “outer” vs “inner”** — either by layer index (so order must be fixed) or by a layer property (e.g. `absorbs_blunt_only: bool`). If by index, adding a new layer type changes semantics; if by property, every layer definition must set it.
- **More complex call flow** — entity or a wrapper must orchestrate “outer then inner” when deflection happens; similar to Strategy 2 but with a more rigid model.
- **Possible redundancy** — if “inner” is “all layers after the first,” this is Strategy 2 with different naming. Real gain is only if you want “inner” to mean a fixed subset (e.g. only cloth layers) regardless of order.

### Code touch points

- **ArmorPiece:** Either two methods (apply_outer_layers, apply_inner_layers) or apply_damage with inner_only/start_layer. Layer definitions may need an “inner_only” or “absorbs_blunt_only” flag if you don’t use index.
- **CoreEntity.take_damage_split:** Call outer for sharp; if deflected, call inner with deflected amount; combine with direct blunt; same wound logic as Strategy 1.

---

## Comparison summary

| Criterion              | Strategy 1 (single-pass) | Strategy 2 (two-call) | Strategy 3 (armor suggests type) | Strategy 4 (staged)   |
|------------------------|--------------------------|------------------------|----------------------------------|------------------------|
| **Armor API surface**  | +2 return keys            | +1 method, +2 keys     | +3 return keys                    | +1 method or params    |
| **Entity complexity**  | Medium (ratio + bruise rule) | Higher (two calls + ratio) | Lower (use suggested type)       | Higher (orchestrate)   |
| **Where B lives**      | Inside apply_damage loop | Second method          | Inside apply_damage               | Separate inner step    |
| **Where C lives**      | Entity                   | Entity                 | Armor (+ entity ratio split)     | Entity                 |
| **Testability**       | One path to test         | Two phases testable    | One path; rule in armor          | Outer/inner testable   |
| **Coupling**           | Low (armor independent of wound names) | Low | Higher (armor knows bruise/crush) | Medium (layer semantics) |
| **Backward compat**    | Good (ignore new keys)   | New method optional    | Good if keys optional            | New entry points       |

---

## Recommendation

- **Default choice: Strategy 1.** One armor call, A and B inside ArmorPiece, C and deflected/direct split in CoreEntity. Small, clear extension to the return type; no new methods; armor stays independent of wound type names.
- **Use Strategy 2** if you want a very explicit “inner absorption” step and don’t mind two calls and a new method.
- **Use Strategy 3** only if you want the “deflected + low → bruise” rule to live entirely in the armor/constants layer and are okay with armor depending on wound semantics.
- **Use Strategy 4** if you are refactoring armor around a strict “outer vs inner” pipeline and want that visible in the API; otherwise Strategy 1 or 2 is simpler.

Implementing **Strategy 1** gives you Option D with minimal API change and clear separation between armor (physics) and entity (wound type and pain/bleed).
