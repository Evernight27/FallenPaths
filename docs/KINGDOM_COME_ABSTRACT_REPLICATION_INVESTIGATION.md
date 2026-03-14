# Kingdom Come Combat: Abstract Replication with Mental Stack

An investigation into adapting Kingdom Come: Deliverance's combat system to work with Fallen Paths' mental stack, **without using 3D models**—using abstract data, 2D representation, or text instead.

---

## 1. Kingdom Come Combat: Core Elements

| Element | KCD Implementation | Abstract Equivalent |
|---------|-------------------|---------------------|
| **Attack directions** | 5 zones: head, left upper, right upper, left lower, right lower | Part targeting (head, left_arm, right_arm, left_leg, right_leg) — chest as "center" or merged with upper |
| **Attack types** | Slash, stab, kick | Cut, thrust, blunt (you already have these) |
| **Strong/weak strike** | Left click = slow/strong; right click = fast/weak | Intensity, archetype (overhead vs quick_slash) — you have this |
| **Combos** | Sequential strikes to specific zones → bonus damage, harder to block | Ordered part sequence; mental stack "combo in progress" layer |
| **Block** | Hold direction to block; drains stamina | Zone-specific guard OR scalar guard (you have scalar) |
| **Perfect block** | Block during opponent swing (green icon) → riposte priority | Parry_deflect with high capacity → counter opportunity |
| **Master strike** | Block during early attack phase → automatic counter | Parry_deflect in early wind-up → guaranteed counter |
| **Stamina** | Depletes with block, attacks, low health; affects power and block break | Gauge as stamina; or separate stamina pool |
| **30+ target zones, 4 armor layers** | Granular hit detection | Sub-regions per part (you have this) |

---

## 2. Mapping KCD to Fallen Paths (No 3D)

### 2.1 Zone Mapping

**KCD 5 directions → Fallen Paths 6 parts:**

| KCD Zone | Fallen Paths Part | Notes |
|----------|-------------------|-------|
| Head | head | Direct match |
| Left upper | left_arm | Upper body left |
| Right upper | right_arm | Upper body right |
| Left lower | left_leg | Lower body left |
| Right lower | right_leg | Lower body right |
| — | chest | KCD merges chest into "upper" (left/right torso). Option: chest = center, or add as 6th zone |

**Simplest mapping:** Use your existing 6 parts. KCD's "left upper" and "right upper" include torso—you can treat chest as "center guard" or allow attacks to chest as a 6th zone. Your `BODY_PARTS` already support this.

### 2.2 Zone-Specific Guard (Key Addition for KCD Feel)

**Current Fallen Paths:** Guard is a single scalar (0.4 when attacking, rises when idle). Parry capacity uses readiness × guard.

**KCD:** Defender chooses which direction to block. Attack from unblocked direction = hits.

**Abstract replication without 3D:**

**Option A: Guard by zone (directional)**

- Each combatant has `guard_zone: String` = one of "head", "chest", "left_arm", "right_arm", "left_leg", "right_leg".
- When attacking zone X: if defender's `guard_zone == X` → block/parry easier (or mandatory block). Else → normal hit chance.
- **No 3D needed:** Represent as text ("Guarding: Head") or 2D icon showing which zone is defended.
- **Mental stack layer:** "Enemy guarding head → attack chest or limbs."

**Option B: Guard coverage (multiple zones)**

- `guard_zones: Array` = list of zones currently defended (e.g., ["head", "chest"] for high guard).
- Attack to guarded zone = block. Attack to unguarded = hit (subject to dodge/parry).
- More KCD-like but more state.

**Option C: Guard scalar + zone modifier**

- Keep scalar guard. Add `last_guard_zone` or `intended_guard_zone`.
- When attacker targets part P: if P == defender.guard_zone → guard applies fully. Else → guard × 0.5 (partial) or 0 (no block).
- Minimal change; one extra field per combatant.

### 2.3 Combos

**KCD:** Sequence like [head → right_upper → left_lower]. If all connect in order, combo finisher deals bonus damage.

**Abstract replication:**

- **Combo definition:** `{ "id": "scatter", "sequence": ["head", "right_arm", "left_leg"], "finisher_bonus": 1.5 }`
- **Combatant state:** `combo_progress: Dictionary` = { "combo_id": "scatter", "step": 1 } when first hit landed.
- **Mental stack layer:** "Combo in progress → next action must be next step in combo, target that part."
- **On hit:** If current attack is next step → increment step. If step == len(sequence) → apply finisher bonus, clear progress.
- **On miss/block/parry:** Clear combo progress.
- **No 3D:** Combo is just a list of part names. UI shows "Combo: Head ✓ → R.Arm → L.Leg" or similar.

### 2.4 Perfect Block & Master Strike

**KCD:**

- **Perfect block:** Block during opponent's swing (not before) → bullet-time, riposte with priority.
- **Master strike:** Block during *early* attack phase → automatic, unavoidable counter.

**Fallen Paths already has:**

- Parry with reaction_time vs effective_wind_up.
- Parry_deflect → no damage, attacker in recovery.
- Parry_partial → reduced damage, possible twist dodge.

**Abstract replication:**

- **Perfect block:** When parry_deflect occurs and defender was in WAITING (not recovering) → set `riposte_priority: true` on defender. Next tick, defender's action gets priority (or reduced cost).
- **Master strike:** When parry_deflect occurs and attack was in *early* wind-up (e.g., first 30% of wind_up_duration) → defender automatically gets a counter attack. Implement as: on parry_deflect, if `wind_up_progress < 0.3`, emit `master_strike_triggered` → resolve defender counter immediately before attacker recovery.

**No 3D:** Both are timing/state rules. Text: "Perfect block! Riposte!" or "Master strike!"

### 2.5 Stamina

**KCD:** Stamina depletes with block, attack, sprint. Low stamina → weak attacks, block breaks, vulnerable to finisher.

**Fallen Paths:** Gauge = readiness. Could double as stamina, or add separate pool.

**Abstract options:**

- **Gauge as stamina:** Attacks consume gauge beyond 100 (e.g., heavy attack costs 120, leaves you at 0). Block/parry consume some gauge. Low gauge = intensity cap (can't do full power).
- **Separate stamina:** New `stamina: float` 0–100. Block costs 10, attack costs 5–20 by archetype. At 0: can't block (or block fails), weak attacks.
- **Unified:** One pool. "Readiness" when full = can act. "Stamina" = same pool, consumed by actions. Refill rate = agility × rest_factor.

---

## 3. Non-3D Representation Options

### 3.1 Text-Based

- **Combat log:** "Goblin strikes at your head. You block. Riposte!"
- **Zone labels:** "You guard your head. Enemy attacks your left arm — hit! 12 damage."
- **Combo display:** "Combo: Head → R.Arm (next) → L.Leg"
- **Minimal UI:** Buttons or list for zone selection; no graphics.

### 3.2 2D Abstract

- **Silhouette:** Simple front-view human outline. Click or highlight zones (head, arms, legs, chest). Color = guarded (green) vs exposed (red).
- **Zone grid:** 2×3 or 3×2 grid. Each cell = zone. Icons for health, guard, last hit.
- **Card-based:** Each zone a card. "Head" card shows guard state, health bar. Attacker plays "Strike: Head" card.
- **Hex or zone diagram:** Abstract shapes for zones; lines connecting combo sequence.

### 3.3 Schematic / Diagram

- **Riddle of Steel style:** Diagram from your MELEE_SIMULATION doc — hit zones as labeled regions. No character model.
- **Top-down or side-view:** Stick figure or simple shapes. Zones as regions.

### 3.4 Hybrid

- **Main view:** Text or simple 2D. **Combat log:** Narrative. **Zone selector:** Dropdown or button row for "Target: Head / Chest / L.Arm / R.Arm / L.Leg / R.Leg".

---

## 4. Mental Stack Integration

### 4.1 New Layers for KCD-Style Combat

| Layer | Condition | Decision |
|-------|-----------|----------|
| 1 | Ally in peril | Medical (unchanged) |
| 2 | Enemy winding up on me | Parry / block (unchanged; now consider guard_zone vs attack target) |
| 3 | **Master strike available** | Execute counter (new: on parry_deflect early → guaranteed counter) |
| 4 | **Riposte priority** | Counter-attack (new: perfect block gave priority) |
| 5 | **Combo in progress** | Next combo step (attack target = sequence[step]) |
| 6 | Engaged / best target | Attack with zone selection (see 4.2) |
| 7 | Default | Attack nearest |

### 4.2 Zone Selection in Attack Layer

When layer 6 (or 5) fires and the choice is "attack":

**Scoring per (target_id, move_id, target_part):**

- `unguarded_bonus`: If defender's guard_zone != target_part, +50% weight.
- `combo_bonus`: If target_part is next in combo, +100% weight.
- `armor_penalty`: If part has heavy armor and we use cut, -20%. Thrust better vs armor.
- `kill_potential`: Part low health, or head/chest for lethality.
- `last_hit_diversity`: Slight penalty for attacking same zone twice (optional).

**Mental stack picks:** Filter actions by layer; within layer 6, use weighted selection over (target, move, part) with above scores.

### 4.3 Guard Selection (Defender)

When defender must choose guard (if using directional guard):

- **Threatened zone:** If attacker has pending_attack and we know target_part (e.g., from telegraph or probabilistic), guard that zone.
- **Mental stack:** Layer 2 "enemy winding up on me" — if we have `_is_being_targeted` and know attack target (from telegraph), set guard_zone = that part.
- **Default:** Guard head (most lethal) or chest (largest).

**Telegraph:** Attacker commits to target_part at wind-up start. Defender can react (Observer-like). You already have wind-up duration; defender's reaction_time determines if they see it in time.

---

## 5. Implementation Paths

### Path A: Minimal KCD Overlay

**Add:**

1. **Zone-specific guard:** `guard_zone: String` per combatant. When attacking part P: if P == defender.guard_zone, parry/block chance × 1.5 (or block mandatory). Else, normal.
2. **Attack target_part:** Extend attack actions to include optional `target_part`. If absent, random as now. Mental stack layer 6 scores by unguarded.
3. **Perfect block → riposte:** On parry_deflect, set defender `riposte_priority`. Next turn, defender acts first or at reduced cost.

**Representation:** Text in combat log. Optional: 2D zone diagram for guard display.

### Path B: Full KCD-Style

**Add:**

1. Zone guard (as A).
2. **Combos:** Combo definitions per weapon; combo_progress state; mental stack combo layer.
3. **Master strike:** Early parry_deflect → auto counter.
4. **Stamina pool:** Separate or gauge-double-duty. Low stamina = weak attacks, block break.
5. **Kick:** New move type (blunt, low damage, high stagger) — KCD has kick to break guard.

**Representation:** 2D zone selector (silhouette or grid), combo progress UI, stamina bar.

### Path C: Abstract-Only (No Spatial UI)

**Add:**

1. Zone guard (as A).
2. Attack target_part selection via mental stack scoring.
3. Combos (data only; no special combo UI—just "combo landed" in log).
4. Perfect block / master strike (timing rules; log messages).

**Representation:** Pure text. "You attack his left arm (unguarded). Hit! 14 damage." "Combo: Head → R.Arm → L.Leg. Finisher! 28 damage."

---

## 6. Data Structures (No 3D Dependencies)

```gdscript
# Zone guard (Path A minimum)
combatant["guard_zone"] = "head"  # or "chest", "left_arm", etc.

# Combo (Path B)
const COMBO_SCATTER = { "id": "scatter", "sequence": ["head", "right_arm", "left_leg"], "finisher_mult": 1.5 }
combatant["combo_progress"] = { "combo_id": "scatter", "step": 0 }  # 0 = not started; 1 = first hit; etc.

# Riposte / Master strike (Path A/B)
combatant["riposte_priority"] = true   # after perfect block
# Master strike: resolve in AttackResolver on parry_deflect when wind_up_progress < 0.3

# Attack with target part (extends current)
action = { "target_id": 2, "move_id": "slash", "target_part": "head" }  # target_part optional
```

---

## 7. Summary: What You Need

| KCD Feature | Abstract Implementation | 3D Required? |
|-------------|-------------------------|--------------|
| 5 attack zones | 6 body parts (existing) | No |
| Directional block | guard_zone: String | No |
| Combos | sequence + combo_progress | No |
| Perfect block | parry_deflect → riposte_priority | No |
| Master strike | early parry_deflect → auto counter | No |
| Stamina | gauge or new stamina pool | No |
| Strong/weak | intensity, archetype (existing) | No |
| Kick | new blunt move, stagger | No |

**All KCD combat logic can be represented as state (strings, numbers, arrays) and rules. No 3D models, animations, or spatial representation required.** The "combat" is resolved in code; the representation (text, 2D diagram, cards) is purely for player feedback.

---

## References

- Kingdom Come: Deliverance — Combat (Fandom wiki), Deltia's guides, Steam guides
- Fallen Paths: MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md, MENTAL_STACK_IMPLEMENTATION_COMPARISON.md
- BodyPartConstants.gd, BleedingConstants.gd, WeaponConstants.gd
- MELEE_SIMULATION_AI_INVESTIGATION.md (Playtank systemic melee, zone diagrams)
