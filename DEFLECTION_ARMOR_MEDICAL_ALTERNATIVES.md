# Deflection, Armor, and Medically Accurate Alternatives

Inspection of how **deflecting wounds** works with your armor and damage system, plus alternatives to improve medical accuracy.

---

## 0. Implemented deflection model (current behavior)

**Design:** When sharp is reduced to 0 by the outer or inner layer, it is transformed into blunt damage. That blunt is run **first against the outer layer’s blunt resistance, then the inner layer’s**, in order. Any damage past that is transferred to the body; wound severity is based on that reduced damage.

**Flow:**

1. **Sharp** is applied to layers in order (outer → inner). When a layer **stops** sharp (penetration &lt; resistance):
   - Sharp is “reduced to 0” (no penetration). Convert to blunt: `deflected_blunt = damage × layer.deflection_transmission` (per-layer, e.g. plate 0.45, cloth 0.18). Durability loss is applied for the energy absorbed in stopping the blade.
   - No blunt reduction is applied in this step.
2. **Deflected blunt** is then run through **all layers in order** (layer 0, then 1, …) as blunt. Each layer reduces it via `_process_layer(..., BLUNT, ...)`. So outer’s blunt resistance is applied first, then inner’s.
3. **Remaining damage** is returned as BLUNT; `CoreEntity` applies it to `body_blunt`, splits deflected vs direct for bruise/crush, and severity is derived from that reduced amount (`_severity_from_damage(part, damage, sub_region)`).

So: **outer-first, inner-second** for blunt is guaranteed; the deflecting layer participates in that same ordered pass. Wound severity is always based on the final, reduced damage to the body.

---

## 1. Legacy / previous system (for reference)

### 1.1 Armor-side deflection (old)

Previously: sharp failed to penetrate → fixed 50% → same layer’s blunt reduction → then deflected blunt was run through *other* layers only (skip deflecting layer), which could put inner-before-outer when the inner layer deflected. That has been replaced by the model in §0.

### 1.2 CombatManager “deflected” outcome (UI only)

After damage is applied:

- If outcome was `"hit"` and `(final_cut + final_blunt) < pre_armor * DEFLECTED_DAMAGE_RATIO` (0.25), the outcome is **reclassified** to `"deflected"`.
- So “deflected” here means: **armor absorbed most of the hit** (tissue damage &lt; 25% of pre-armor). Recovery time uses `RECOVERY_EXTRA_DEFLECTED_S`.

This does **not** change damage; it only affects feedback and recovery.

### 1.3 Downstream: wounds and pain

- In `CoreEntity.take_damage_split`, all non-zero blunt (including from deflected sharp) is applied to `body_blunt` and recorded as **one wound per hit** via `_add_wound(part, INJURY_TYPE_CRUSH, to_blunt, sub_region)`.
- So **deflected damage is always treated as “crush”** (with positive bleeding rates in `BLEEDING_RATES`). There is no distinction between “armor-deflected contusion” (bruise, little/no bleed) and “direct blunt crush” (more tissue damage, more bleed).
- Pain comes from wounds; crush contributes. Bruise type exists in `BleedingConstants` (0 bleed) but is never created for deflected hits.

---

## 2. Medical Accuracy: What’s Right and What’s Not

### 2.1 What aligns with medicine

- **Sharp fails → effect becomes blunt:** Correct. No penetration ⇒ no laceration/puncture; remaining effect is behind-armor trauma (contusion, possible fracture, internal injury). Converting to blunt and reducing is the right direction.
- **Layered armor:** Outer layer (e.g. plate) stopping the blade, inner (e.g. gambeson) absorbing some impact is consistent with historical and modern BAT (behind-armor trauma) ideas.
- **Blunt resistance reducing transmitted force:** Stiffer plate transmits more; padding (gambeson) absorbs more. Your layer ordering and blunt_res values reflect that (plate high blunt_res, cloth lower but present).

### 2.2 Gaps and arbitrary choices

| Current behavior | Medical / realism issue |
|-----------------|-------------------------|
| **Fixed 50% halving** on deflection | Transmitted energy depends on armor type: hard plate with little padding transmits more; mail + gambeson spreads and absorbs. A single 0.5 factor for all layers is arbitrary. |
| **RHA_TO_MPA = 0.6** | Documented as approximate; no standard conversion. Used only to drive *relative* blunt transmission when sharp fails; ordering matters more than the exact number. |
| **Deflection = one layer then stop** | When outer plate deflects, the remaining “blunt” could still be partially absorbed by inner layers (gambeson). Currently inner layers are not applied to the deflected amount. |
| **All deflected damage → crush wound** | Medically, deflected hits often cause **contusion/bruise** (pain, little/no bleeding) rather than crush (tissue destruction, more bleeding). Low transmitted force → bruise; high → crush. |
| **No “was_deflected” flag to wound** | CombatManager can infer “deflected” from total damage &lt; 25% pre-armor, but the wound system doesn’t know “this blunt came from a deflected sharp.” So you can’t branch wound type (bruise vs crush) or bleeding by deflection. |

---

## 3. Alternatives for a More Medically Accurate System

### Option A: Layer-dependent deflection transmission (no new wound type)

**Idea:** Keep “sharp → blunt on deflect,” but **replace the fixed 50%** with a **per-layer (or per-layer-type) transmission fraction**.

- **Implementation:** In `ArmorPiece._process_layer`, when `current_pen < layer_res`:
  - Read a layer property, e.g. `deflection_transmission` (0.0–1.0), or derive from layer type:
    - **Plate:** high transmission (e.g. 0.4–0.5) — hard surface, less absorption.
    - **Mail:** medium (e.g. 0.35) — spreads load but still transmits.
    - **Leather:** medium-low (e.g. 0.25).
    - **Cloth/gambeson:** lower (e.g. 0.15–0.2) — best absorption.
  - `after_deflect = damage * deflection_transmission` instead of `damage / 2.0`.
- **Medical basis:** Behind-armor trauma literature: transmission depends on stiffness and padding. Plate without padding transmits more; gambeson reduces BAT.
- **Pros:** Small change; no new wound types; more realistic variation by armor. **Cons:** Still one blunt type (crush) for all deflected damage.

### Option B: Let inner layers absorb deflected blunt (multi-layer deflection)

**Idea:** When a layer **deflects**, don’t return immediately. Treat `after_deflect` as **blunt damage** and **run it through the remaining (inner) layers** as a blunt hit.

- **Implementation:** In `ArmorPiece.apply_damage`, when a layer returns `deflected: true`:
  - Instead of `break`, set `damage_remaining = result.damage`, `current_damage_type = BLUNT`, and **continue** to the next layer (with same or converted blunt penetration).
  - Inner layers then reduce this blunt as they do for normal blunt (and no second “deflection” branch for blunt).
- **Medical basis:** Outer plate stops the blade; remaining energy hits gambeson; gambeson further absorbs. Two-stage absorption is realistic.
- **Pros:** Better match to layered kit; gambeson meaningfully reduces deflected trauma. **Cons:** Slightly more complex; need to ensure blunt pen is correct for the “deflected” stream when passed to inner layers (you already use `pen_rha * RHA_TO_MPA` for that).

### Option C: Deflected blunt → bruise when force is low (wound-type choice)

**Idea:** When the **source** of blunt was a **deflected sharp** and the **transmitted amount is low**, create a **bruise** (0 bleed, pain) instead of **crush** (positive bleed).

- **Implementation:**
  - **ArmorPiece:** Extend return to include e.g. `was_deflected: bool` (true when the last meaningful step was a deflection).
  - **CoreEntity.take_damage_split:** When applying armor for the **sharp** stream, if result is `damage_type == BLUNT` and `was_deflected == true`, mark this hit as “deflected blunt” (e.g. pass a flag or store in a small context).
  - When creating the blunt wound for that hit: if “deflected blunt” and `to_blunt` &lt; a threshold (e.g. 2–3 in your scale) or severity is minor, call `_add_wound(part, INJURY_TYPE_BRUISE, to_blunt, sub_region)`; else `_add_wound(part, INJURY_TYPE_CRUSH, to_blunt, sub_region)`.
- **Medical basis:** Deflected impacts often cause contusion (bruise) without significant vessel damage; only heavier transmitted force causes crush-like injury and bleeding.
- **Pros:** Medically accurate distinction (bruise vs crush); uses existing INJURY_TYPE_BRUISE and 0-bleed; pain without inflating bleed. **Cons:** Need to thread “was_deflected” from armor to entity; threshold is tunable.

### Option D: Combine A + B + C (full medical deflection model)

- **A:** Per-layer `deflection_transmission` (plate &gt; mail &gt; leather &gt; cloth) so transmitted force varies by what actually stopped the blade.
- **B:** After deflection, pass the resulting blunt through inner layers so gambeson (or other padding) can further reduce it.
- **C:** If the final blunt is “from deflection” and below a severity/damage threshold, record as bruise; otherwise crush.

This gives you:

- Energy transmission that depends on armor construction.
- Two-stage absorption (outer stops sharp, inner absorbs blunt).
- Wound semantics that match reality (contusion vs crush) and existing pain/bleed design.

### Option E: Keep numbers, add “deflection” only for UI and bruise (minimal)

**Idea:** Don’t change armor math. Only:

- Have armor (or CombatManager) expose “this hit was deflected” (e.g. sharp stream returned BLUNT + flag, or post-armor &lt; 25% pre-armor).
- When creating the blunt wound for that hit, if damage is below a small threshold (e.g. 2) or severity is minor, add as **bruise** instead of crush.

So: same deflection formula, but **deflected low-force hits create bruise (0 bleed)** instead of crush. Medically better (contusion vs laceration/crush) with minimal code.

---

## 4. Summary Table

| Alternative | What changes | Medical gain |
|-------------|--------------|--------------|
| **A** | Fixed 50% → per-layer deflection transmission | Transmission varies by armor type (plate vs gambeson). |
| **B** | Deflected blunt is applied to inner layers | Two-stage absorption; padding reduces BAT. |
| **C** | Deflected + low blunt → bruise wound | Contusion (pain, no bleed) vs crush (bleed); matches BAT. |
| **D** | A + B + C | Full model: transmission + layering + bruise vs crush. |
| **E** | No armor change; deflected + low damage → bruise | Minimal change; better wound semantics only. |

Recommendation: **Implement E for a quick win** (deflected, low blunt → bruise). If you want the system to be as medically accurate as possible, **implement D** (layer-dependent transmission, inner-layer absorption, and bruise vs crush by deflection + severity).

---

## 5. Code touch points (for implementation)

- **ArmorPiece.gd:** `_process_layer` — deflection branch: replace `damage/2` with layer-based transmission (A); return `was_deflected` (C/D/E); optionally don’t `break` on deflect and instead feed blunt into next layer (B).
- **ArmorConstants.gd:** Add per-layer or per-type `deflection_transmission` (A/D).
- **ArmorPiece.apply_damage:** If doing B, on deflect continue loop with `damage_remaining`, `current_damage_type = BLUNT`, and appropriate pen.
- **CoreEntity.take_damage_split:** Use armor result `was_deflected` (or infer from damage ratio); when adding blunt wound, if deflected and (to_blunt &lt; threshold or severity minor) use INJURY_TYPE_BRUISE, else INJURY_TYPE_CRUSH (C/D/E).
- **CombatManager:** DEFLECTED_DAMAGE_RATIO remains for UI only; no need to change unless you want “deflected” to require armor actually deflecting (e.g. sharp→blunt) rather than any low-damage hit.

This keeps your current deflection and armor pipeline intact while giving you a path to the most medically accurate behavior you want.

---

## 6. Deflection follow-ups: realism and options

Below are the three optional follow-ups from the implemented model (§0), with **why each would be more realistic** and **several concrete possibilities** for implementation.

---

### 6.1 Durability on deflection

**Why it would be more realistic**

In reality, both “stopping the blade” and “absorbing the transmitted force” wear the kit. The layer that **stops** the sharp takes concentrated stress (edge impact, possible scoring or denting). Layers that **absorb** the resulting blunt take distributed load (padding compresses, mail links shift, plate can still deform if the blow was heavy). So:

- **Deflecting layer:** Already gets durability loss for the energy that didn’t reach the body (`damage - after_deflect`). Realistically you could also account for “impact event” wear (e.g. plate denting, mail link strain) that isn’t proportional to damage alone.
- **Layers that absorb deflected blunt:** They already get durability loss when they reduce that blunt (in the blunt pass, `_process_layer` applies `_apply_durability_loss` for the amount absorbed). So they *do* wear. The design choice is whether that wear should be **the same** as for direct blunt, or **different** (e.g. lower rate for padding absorbing deflected force, or higher for metal taking a second impact).

**Possibilities**

| Option | What changes | Realism / effect |
|--------|--------------|-------------------|
| **A. Leave as-is** | Deflecting layer: durability for `(damage - after_deflect)`. Blunt pass: each layer loses durability for the blunt it absorbs (same as direct blunt). | Simple; all layers that absorb energy wear. No distinction between “stopped blade” vs “absorbed deflected force.” |
| **B. Extra “deflection event” wear on deflecting layer** | When a layer deflects, apply an **additional** durability cost (e.g. fixed per deflect or scaled by incoming damage) to that layer only. | Reflects extra wear from the impact event (denting, link strain, edge contact) beyond the energy “absorbed” in the formula. |
| **C. Different durability rate for deflected blunt** | When applying durability in the blunt pass, if the blunt **came from deflection** (you’d pass a flag or detect it in a separate “deflected blunt only” path), use a different `durability_loss_rate` (e.g. lower for padding, same or higher for metal). | Padding compressing from deflected force may wear less than taking a direct mace hit; metal might wear similarly either way. Lets you tune by layer type. |
| **D. Durability only for “meaningful” absorption** | Only apply durability to a layer in the blunt pass if it reduced damage by more than a small threshold (e.g. &gt; 0.1). | Avoids tiny durability ticks when a layer barely reduces the deflected blunt; cleaner for near-zero absorption. |

**Implemented (minimal damage + per-layer rates):**

- **Minimum damage to cause wear:** Durability loss is applied only when `damage_absorbed >= threshold`, where `threshold = max(DURABILITY_MIN_DAMAGE_FLAT, armor_value * DURABILITY_MIN_DAMAGE_RATIO)`. `armor_value = sharp_resistance_rha_mm + blunt_resistance_mpa / 10` so both resistances contribute. Constants: `DURABILITY_MIN_DAMAGE_FLAT = 0.5`, `DURABILITY_MIN_DAMAGE_RATIO = 0.05`. So light taps below the threshold cause no durability loss; heavier hits (or hits on low-resistance layers with a low armor value) still need to clear the flat 0.5 minimum.
- **Different layers wear at different rates:** Each layer uses its own `durability_loss_rate` (cloth 0.20, leather 0.15, mail 0.12, plate 0.08). So cloth wears fastest per point of damage absorbed, plate slowest.

**Recommendation:** A is already consistent. Add B if you want deflection to feel more punishing on the deflecting layer; add C if you want padding vs metal to wear differently when absorbing deflected force.

---

### 6.2 Transmission from “damage at layer” vs “incoming”

**Why it would be more realistic**

Right now, when a layer deflects, the deflected blunt is:

`deflected_blunt = damage * transmission`

where `damage` is the **sharp damage that reached that layer** (after any outer layers reduced it). So:

- If **outer** deflects: `damage` = incoming sharp (unchanged by previous layers). So deflected blunt is proportional to the **full** strike.
- If **inner** deflects: `damage` = sharp after the outer layer reduced it. So deflected blunt is proportional to what **got through** the outer layer.

So you’re already using “damage at layer” (the value passed into `_process_layer` for the deflecting layer), not “incoming” from the very start of the call. The only ambiguity is if you had a **different** definition in mind:

- **“Incoming”** = pre-armor damage at the start of `apply_damage`. Using that would ignore that outer layers already absorbed part of the strike before the inner layer deflected, so it would be **less** realistic (overstates deflected blunt when inner deflects).
- **“Damage at layer”** = sharp damage at the deflecting layer (current behavior). This **is** more realistic: the energy that becomes blunt is the part that that layer actually had to stop.

So the “different possibility” is really: do you want transmission to use **damage at deflecting layer** (current, realistic) or **incoming** (simpler but less realistic when inner deflects)?

**Possibilities**

| Option | Formula | Realism / effect |
|--------|---------|-------------------|
| **A. Damage at deflecting layer (current)** | `after_deflect = damage * transmission` with `damage` = sharp at that layer. | Realistic: deflected blunt reflects the energy that layer actually stopped. Inner deflection → less deflected blunt when outer already reduced sharp. |
| **B. Incoming (pre-armor) damage** | Pass `incoming_damage` into the deflection branch and use `after_deflect = incoming_damage * transmission`. | Unrealistic when inner deflects: deflected blunt would be the same whether outer reduced sharp or not. Only makes sense if you want “deflection always transmits the same fraction of the **original** hit.” |
| **C. Damage at layer with a minimum** | See below. | Gameplay compromise: inner deflection never drops below a small fraction of the original strike. |
| **D. Layer-weighted blend** | e.g. `after_deflect = (0.7 * damage_at_layer + 0.3 * incoming) * transmission` so deflected blunt is partly tied to full strike. | Tuning knob between “at layer” (realistic) and “incoming” (simpler / more punishing). |

**Option C in more detail**

Option C (“damage at layer with a minimum”) makes deflected blunt **at least** a small fraction of the **incoming** (pre-armor) damage, so that when the **inner** layer deflects (and damage at layer is already low), the body still takes a non-trivial amount of blunt. That keeps deflection from feeling “free” when the outer layer has already eaten most of the sharp.

**What it changes**

- **Current (A):** When the inner layer deflects, `damage_at_layer` can be small (e.g. 2 after the outer layer reduced 20 → 2). So `deflected_blunt = 2 * 0.18 = 0.36` (cloth). After the blunt pass, the body might receive almost nothing. Realistic, but a strong outer + inner can make deflected hits do negligible damage.
- **With C:** You define a floor for the **input** to transmission, e.g. “use at least 10% of incoming when computing deflected blunt.” So the blunt that is then run through the blunt pass is at least `incoming * 0.1 * transmission` (or a variant). So even if damage at layer is 2, you might use `max(2, 20*0.1) = 2` (no change) or, with a different formula, `max(2, 20*0.1) * transmission = 2 * transmission` (same as now), or you could set the *transmitted* blunt to at least `incoming * 0.1 * transmission`, i.e. deflected_blunt = max(damage_at_layer * transmission, incoming * MIN_FRACTION * transmission). Then when damage_at_layer is very low, deflected_blunt doesn’t go below e.g. 20 * 0.1 * 0.18 = 0.36; when damage_at_layer is high, you still use damage_at_layer * transmission. So the only change is when inner deflection would have given *less* than that floor — you lift it to the floor.

**Possible formulas**

1. **Floor on transmitted blunt**  
   `deflected_blunt = max(damage_at_layer * transmission, incoming * MIN_DEFLECTED_FRACTION).`  
   Example: `MIN_DEFLECTED_FRACTION = 0.08`. So deflected blunt is never below 8% of the original strike. Inner deflection then always does at least that much before the blunt pass (and the blunt pass can reduce it further). So: body damage from deflection has a **minimum** tied to how hard the original hit was.

2. **Floor on “effective” damage used for transmission**  
   `effective_damage = max(damage_at_layer, incoming * 0.1); after_deflect = effective_damage * transmission.`  
   So you never use *less* than 10% of incoming when deciding how much blunt is created. Inner deflection with small damage_at_layer (e.g. 2) would use 2 if incoming is 20 (2 &lt; 2), or use 2 if incoming is 10 (2 &gt; 1). So this only kicks in when damage_at_layer is a very small fraction of incoming (e.g. outer reduced 20 → 1; then effective_damage = 2, deflected_blunt = 2 * transmission).

3. **Scaling the shortfall**  
   If `damage_at_layer * transmission` is below `incoming * MIN_FRACTION`, set deflected_blunt to the latter; otherwise keep `damage_at_layer * transmission`. So you only override when the “realistic” deflected blunt would be below the minimum.

**What could change in gameplay**

- **Deflection always does a bit of harm:** Even with strong layered armor (e.g. plate + gambeson), a deflected strike still does at least X% of the original hit as blunt (before the blunt pass). So fights with lots of deflections still chip away at the target.
- **Tuning:** `MIN_DEFLECTED_FRACTION` or `MIN_FRACTION` (e.g. 0.05–0.15) controls how “free” deflection feels. Lower = closer to current (realistic); higher = deflected hits always matter more.
- **Inner deflection:** The biggest effect is when the **inner** layer deflects and damage at layer is already low. Option C raises the deflected blunt in those cases so the body doesn’t get almost zero damage. Outer deflection is less affected because damage at layer is usually close to incoming.
- **Consistency with “damage at layer”:** You can still use damage_at_layer for the main term and only apply the minimum when it would otherwise be very small, so you stay close to “energy at the deflecting layer” while avoiding near-zero deflected blunt.

**Recommendation:** Keep A (current). It’s the physically consistent choice. Use C (e.g. floor on transmitted blunt with MIN_DEFLECTED_FRACTION ≈ 0.05–0.10) only if you want deflection to feel heavier for gameplay and to avoid “zero damage” deflections with strong armor.

---

### 6.3 Wound type and severity: bruise vs crush, and which layer deflected

**Why it would be more realistic**

Medically:

- **Deflected force** often causes **contusion** (bruise): pain, swelling, little or no broken skin or vessel damage. **Higher** transmitted force can cause **crush**-like injury: more tissue damage, bleeding. So low deflected blunt → bruise, high → crush (you already do this).
- **Which layer deflected** can matter:
  - **Outer** (e.g. plate) deflects: the force that reaches the body has already been reduced by the full stack (outer + inner blunt resistance). So it’s more often **diffuse** and **contusion-like** (bruise).
  - **Inner** (e.g. gambeson) deflects: the outer layer didn’t stop the sharp; the inner one did. So the strike was already “focused” enough to get past the outer layer; the transmitted blunt might be more **localized** or **concentrated**, and in some models you could treat it as slightly more **crush-like** or use a different severity curve.

So “which layer deflected” can be a **modifier** to wound type or severity, not just “deflected + low damage → bruise.”

**Possibilities**

| Option | What changes | Realism / effect |
|--------|--------------|-------------------|
| **A. Current only (deflected + low/minor → bruise)** | No info about which layer deflected. Deflected blunt: below threshold or minor severity → bruise; else crush. | Already realistic for “low force = contusion, high = crush.” Doesn’t distinguish outer vs inner deflection. |
| **B. Outer deflect → bias to bruise** | Armor returns e.g. `deflecting_layer_index`. If index == 0 (outer), treat deflected blunt as “one step more bruise-like”: e.g. use a higher bruise threshold (e.g. 5 instead of 3) or always bruise if severity ≤ moderate. | Reflects that outer deflection usually means more absorption before body; more often bruise. |
| **C. Inner deflect → bias to crush** | If deflecting layer is inner (e.g. index ≥ 1), use a **lower** bruise threshold (e.g. 2) or require severity == minor for bruise; else crush. | Reflects that inner deflection can mean more focused force; slightly more crush-like. |
| **D. Severity modifier by deflecting layer** | Don’t change wound type, but when **deflected**, multiply effective damage for **severity** by e.g. 0.9 if outer deflected, 1.1 if inner. So outer-deflect hits are logged as slightly less severe, inner as slightly more. | Subtle: same wound type (bruise/crush) but severity bands shift by which layer stopped the blade. |
| **E. Explicit “deflected by outer” vs “deflected by inner” in wound** | Store in the wound dict e.g. `deflected_by`: `"outer"` / `"inner"` / `""`. UI or later systems (healing, infection) can use it. Bruise/crush and severity still from current rules. | Good for flavour and future systems; doesn’t change damage or wound type by itself. |

**Recommendation:** A is already a good default. Add B and/or C if you want armor layout (outer vs inner stopping the blow) to affect wound type; add D for a softer severity tweak; add E if you want the info for UI or other mechanics later.

---

## 7. Summary of follow-up options

| Follow-up | Most realistic default | Optional tweaks |
|-----------|-------------------------|------------------|
| **Durability** | Keep current (deflecting layer + blunt pass both wear). | B: extra deflection-event wear on deflecting layer; C: different durability rate for deflected blunt. |
| **Transmission basis** | Keep “damage at deflecting layer.” | C/D: min or blend with incoming if you want deflected hits to feel heavier. |
| **Wound type / severity** | Keep deflected + low/minor → bruise. | B: outer deflect → more bruise; C: inner deflect → more crush; D: severity modifier; E: store deflecting layer in wound. |
