# Formation File/Density + Survivability-Gated Push: Investigation

Investigation of how the formation system can support:
1. **Explicit control** over front-line count vs reserve depth
2. **Density choice** (tight vs loose) and its tradeoffs: engagement capacity, fall-back/rotation ease, and fight-to-death tendency
3. **Survivability-gated push and flank** so most units stay in flag protection; only durable units attempt incursion

---

## Part 1: Front Line vs Back Line — File/Rank Assignment

### Current State

- **FormationPreset:** `{ files, ranks, density }`. Default: 2 files, ceil(count/2) ranks.
- **Assignment:** Spawn order. Plan: heavy armor front, spears second row, weaker in reserve.
- **Constraint:** Formation shape is derived from count and density; no explicit "I want 4 in front, 6 in reserve."

### Design Goal: Explicit Front-Line Choice

Player/encounter should be able to choose:
- **Front-line count:** How many units in rank 0 (primary melee)
- **Reserve depth:** How many ranks behind (rank 1+ for support, ranged, rotation)

### Option A: Files × Ranks with Explicit Fill

Preset: `{ files: 4, ranks: 3, density: "normal" }` → 12 slots. Fill front first; spill to rank 1, then rank 2.
- **Front = files × 1** = 4 in rank 0.
- Control: set `files` and `ranks` so `files` = desired front count. For 6 in front: `files: 6, ranks: ceil(total/6)`.

**Pros:** Reuses existing structure. `files` directly = front-line count when single rank in front.
**Cons:** Deeper formations (2+ in rank 0) require different mapping.

### Option B: Explicit Front-Count in Preset

Preset: `{ front_count: 4, reserve_ranks: 2, density: "normal" }`.
- **front_count:** Slots in rank 0. Can exceed `files` if you want overlapping (e.g. shield wall with 6 in front, 4 files → 1.5 per file).
- **reserve_ranks:** Ranks 1..N for support. Units per reserve rank = `front_count` or `front_count - 1` (narrower reserve).

**Derivation:** `files = front_count` (simple); `ranks = 1 + reserve_ranks`. Or: `files` from width preference, `front_count` slots in rank 0 (some files have 2? or extra rank 0 slots).

### Option C: Slot Template (Most Flexible)

Preset defines **slot layout** explicitly:
```
slots: [
  { rank: 0, file: 0 }, { rank: 0, file: 1 }, { rank: 0, file: 2 }, { rank: 0, file: 3 },  # 4 front
  { rank: 1, file: 0 }, { rank: 1, file: 1 }, { rank: 1, file: 2 }, { rank: 1, file: 3 },  # 4 support
  { rank: 2, file: 1 }, { rank: 2, file: 2 }   # 2 reserve (narrower)
]
```
- Fill in order. First 4 → rank 0. Next 4 → rank 1. Last 2 → rank 2.
- Allows wedge, convex, refuse-flank shapes.

**Recommendation:** Start with **Option A** — use `files` as front-line count and `ranks` for depth. Add **Option B** fields (`front_count`, `reserve_ranks`) as optional overrides if you want "4 in front, 2 ranks behind" without caring about file width. Option C later for exotic shapes.

**Integrated:** Option A implemented. FormationPreset: `files` = front count; `for_front_count(count, front_count)` helper; preset supports optional `front_count` override. CombatManager fills rank 0 first by spawn order.

---

## Part 2: Density and Its Tradeoffs

### Density Effects (Recap from Existing Docs)

| Density | spacing_m | Close attempt | Disengage | Physical width |
|---------|-----------|---------------|-----------|----------------|
| **Tight** | 0.9 | Easier to close (×0.8 evasion) | Harder to disengage (×0.8) | Narrow frontage per file |
| **Normal** | 1.2 | Standard | Standard | Default |
| **Loose** | 1.8 | Harder to close (×1.2 evasion) | Easier to disengage (×1.2) | Wide frontage per file |

### Engagement Capacity: How Many Can Engage Each Unit?

**Tight formation:**
- Units packed shoulder-to-shoulder. Many attackers can get "close" to the same defender (bunching).
- **High attackers per defender** → defense split (parry_capacity / num_close_threats) hits harder.
- Fall back: **hard** — no room to slip through; lane blocked. Medieval: "pre-designated channels" required.
- Tendency: **fight to death** — can't rotate easily; you hold or die.

**Loose formation:**
- Units spread out. Each defender faces fewer close attackers (enemy also spread).
- **Lower attackers per defender** → defense split less severe.
- Fall back: **easier** — space to slip through; channels exist. Roman: gaps between maniples.
- Tendency: **rotate out** — exhausted can fall back; reserves replace.

### Tradeoff Matrix

| Formation | Attackers per defender | Fall-back difficulty | Rotation | Typical outcome |
|-----------|------------------------|----------------------|----------|-----------------|
| **Tight (shield wall)** | High (3–4) | Hard (×1.3–1.6 duration) | Rare | Fight to death, plug or die |
| **Normal** | Medium (2) | Normal | Possible | Mix of hold and rotate |
| **Loose** | Low (1–2) | Easier (×0.9) | Common | Rotate when tired |

### Implementation Hooks

1. **Close slots per target:** Already planned. Tight formation could allow more (e.g. 4 close per defender); loose fewer (2). Or: derive from density: `max_close_per_defender = 2 + (tight ? 2 : 0)`.
2. **Fall-back duration:** Already: `lane_modifier × pressure_modifier`. Density affects `lane_modifier`: tight = blocked/crowded more often; loose = clear more often.
3. **Fight-to-death tendency:** When lane is blocked and pressure high, fall-back may fail → unit stays in rank 0. Morale + formation state could drive "attempt fall back" vs "hold position" AI decision.

---

## Part 3: Survivability-Gated Push and Flank (Flag Protection)

### Lore: Magic Flags and Protection Circles

- **Flag:** Creates magic-neutralization / protection circle. Units inside = protected.
- **Outside:** No protection; high risk. Only survivable units (heavy armor, high endurance) can operate there.
- **Norm:** Most units stay in circle. Shield walls engage front-on. Durable units may push into enemy lines.

### Mechanical Translation

| Behavior | Normal unit | Survivable unit (heavy armor, high endurance) |
|----------|-------------|-----------------------------------------------|
| **Flank attempt** | Never (stay in circle) | Could, but flag design disables flank for all |
| **Push / incursion** | Never | Yes, when gap opens and conditions met |
| **Fall back** | Prefer (rotate out when hurt) | May hold (can absorb hits) |

### Survivability Score

Derive a **survivability** value from existing stats:

```
survivability = f(armor, endurance, wounds, consciousness)
```

**Proposed formula:**
- **Armor:** Sum or max of armor resistance (RHA/mm) for vital parts. Normalized 0–1.
- **Endurance:** 0–1 from current/max.
- **Wounds:** Penalty for critical wounds, low health. 0–1.
- **Consciousness:** From EntityPainConsciousness. 0–1.

Example: `survivability = 0.4 * armor_norm + 0.3 * endurance_norm + 0.2 * (1 - wound_penalty) + 0.1 * consciousness_norm`

Or simpler: `survivability = armor_norm` (armor is the main differentiator for "can I survive outside the circle").

### Push Decision Gate

**Current plan:** Incursion eligibility uses strength, ZoC, plug contest. Add **survivability threshold**:

| Step | Gate |
|------|------|
| 1. Slot opens | Plug attempt, incursion attempt (contest) |
| 2. Incursion eligibility | `survivability >= PUSH_SURVIVABILITY_THRESHOLD` (e.g. 0.6) |
| 3. Push decision roll | Only if eligible. Roll factors: push_tendency, morale, stamina. |

**Effect:** Unarmored, wounded, or low-endurance units never pass step 2. They never attempt incursion. They stay in formation, in flag protection.

### Flank Attempt Gate (When Flank Exists)

If using ZoC-based flank (flank zone accessible when control < threshold):

| Step | Gate |
|------|------|
| 1. Flank zone accessible | Control < threshold |
| 2. Unit considers flank | `survivability >= FLANK_SURVIVABILITY_THRESHOLD` |
| 3. Flank attempt | Only if 2 passes |

**With flag lore:** Set `FLANK_ACCESS_THRESHOLD = 1.0` (never) so flank is never accessible. Then no unit can flank — all stay in circle. No survivability gate needed for flank.

**Alternative:** Keep flank logic but add encounter/formation flag `protection_circle_active`. When true:
- `get_available_zones()` never returns flank/rear.
- `engagement_angle` always "front".
- AI never considers flank. Survivability gate is redundant for flank (flank disabled globally).

### Summary: Survivability Gates

| Action | Gate | Result |
|--------|------|--------|
| **Incursion (push)** | `survivability >= 0.6` (tune) | Only armored/durable units push |
| **Flank** | `protection_circle_active` → never | All stay in front; no flank |
| **Fall back** | None (all can try) | Normal units prefer; survivable may hold |

---

## Part 4: Implementation Outline

### 4.1 Formation Preset Extensions

```gdscript
# FormationPreset - optional explicit front count
{
  "files": 4,           # Front-line width (default)
  "ranks": 3,           # Depth
  "density": "tight",   # tight | normal | loose
  "front_count": 4,     # Optional: override files for front; or files = front_count
  "reserve_ranks": 2    # Optional: explicit reserve depth
}
```

Assignment: Fill rank 0 first with `min(count, files)` units. Then rank 1, etc. Heavy armor favored for rank 0 when assignment logic exists.

### 4.2 Density → Engagement and Fall-Back

| Constant / Formula | Value / Logic |
|-------------------|---------------|
| `max_close_per_defender` | `2 + (1 if density == "tight" else 0)` — tight allows more bunched attackers |
| `lane_clarity_base` | Loose: more often "clear"; tight: more often "crowded" or "blocked" |
| `fall_back_duration` | Already: `BASE × lane_mod × pressure_mod`. Tight → higher lane_mod on average |

### 4.3 Survivability Computation

```gdscript
# Combatant or Entity
static func get_survivability(combatant: Dictionary, entity: Node) -> float:
    var armor_norm := _armor_score(entity)  # 0-1 from armor coverage/resistance
    var endurance_norm := entity.endurance / entity.endurance_max if entity.get("endurance") else 1.0
    var wound_penalty := _wound_severity_factor(entity)  # 0 = fine, 1 = critical
    return 0.5 * armor_norm + 0.3 * endurance_norm + 0.2 * (1.0 - wound_penalty)
```

Add `PUSH_SURVIVABILITY_THRESHOLD` (e.g. 0.5–0.6) to CombatConstants.

### 4.4 Incursion Eligibility (Revised)

When slot opens:
1. Plug attempt (allies).
2. Incursion attempt: **only if** `get_survivability(pusher) >= PUSH_SURVIVABILITY_THRESHOLD`.
3. If eligible: contest plug vs push (existing roll logic).
4. Push decision: existing push_tendency, morale, stamina.

### 4.5 Protection Circle (Flag) Flag

```gdscript
# Encounter or Formation
protection_circle_active: bool = true  # When true: no flank/rear access
```

When true:
- `get_available_zones()` returns only front (or front zone).
- `engagement_angle` always "front".
- AI target picker excludes flank/rear options.

---

## Part 5: Decision Summary

| Decision | Recommendation |
|----------|----------------|
| **Front-line control** | Use `files` = front count; optional `front_count` override. Fill rank 0 first. |
| **Density tradeoff** | Tight = more attackers/defender, harder fall back, fight to death. Loose = fewer attackers, easier rotation. |
| **Survivability gate** | Add `get_survivability(c)` from armor, endurance, wounds. Gate incursion: `survivability >= threshold`. |
| **Flank** | With flag: `protection_circle_active` → disable flank entirely. No survivability gate needed for flank. |
| **Push** | Incursion eligibility requires survivability threshold. Only durable units attempt. |

---

## Part 6: References

- `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` — breakthrough flow, plug vs incursion, fall-back duration
- `docs/MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md` — lane clarity, pressure, density
- `docs/ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md` — ZoC, flank access
- `docs/FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md` — formation structure, targeting
- `combat/FormationPreset.gd` — current preset structure
