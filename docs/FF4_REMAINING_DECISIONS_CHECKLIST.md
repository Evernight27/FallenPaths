# FF4 Migration Plan — Remaining Decisions Checklist

Complete each choice below. Once filled, the plan is ready for implementation.

---

## 1. Distance Bands (Section 3.2)

**Can distance bands combine with positional targeting (engagement system)?** Yes. They are complementary: distance bands govern close/mid/long transitions and what attacks are possible; the engagement system (1v1 primary, flurry) and positional targeting (formation rank/file + weapon reach) govern who can attack whom and from where. Use **Hybrid (C)** — pair-wise for unformed, zone-based for formations — so zone-based distance ties to ZoC when both sides use formations.

**Option:**
- [ ] **A: Pair-wise**
- [ ] **B: Zone-based**
- [x] **C: Hybrid** — Pair-wise for unformed; zone-based for formations.

**Close attempt mechanic:** When melee at mid/long wants to close:
- [x] **Roll vs evasion** — engagement_pressure vs defender evasion. Tie in stats. Units have stances (defensive, aggressive, balanced, controlling) — see `docs/COMBAT_STANCE_STATES_INVESTIGATION.md`.
- [ ] **Fixed success** — e.g. 70% chance
- [ ] **Cost-based** — Spend turn/stamina; success guaranteed
- [ ] **Other:** _____

---

## 2. ZoC When to Add (Section 3.3)

**Phase:**
- [x] Phase 4 (after formations)
- [ ] Later phase: _____
- [x] Notes: Implement after Phase 3 unless Phase 5 or 6 is needed for ease of integration.

---

## 3. Formation Actions (Section 3.4)

**Swap rank / Fall back movement:** Time-based (not stamina). Difficulty scales with: lane clearance (people in the way vs clear retreat), opponent pressure (aggressive vs defensive). See `docs/MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md`.

**Disengagement:** Form logic around unit health, morale, and formation structure. Investigate: when do units fall back vs fight to death vs break rank and rout? Priority: health → morale → formation cohesion.

**Fall back:** Combination of (b) and (c). Expand with realistic movement:
- **Drag back:** Units in rear ranks can drag damaged units from front to clear the frontline. Causes distraction deficit for the unit in that space or clearing it. Requires adjacent units to hold formation for movement to occur.
- **Step over fallen:** Units can step over fallen friends — reduced footing (×1.15–1.25 duration), but movement allowed. Dead/wounded stay tracked in slot as ground obstacles; they do NOT block allies from advancing. May prevent foe from finishing the wounded unit.
- **Multi-unit same spot:** Allow multiple units in same slot when dragging/transitioning, with appropriate deficits (distraction, footing).
- (b) Disengage + move to rear zone; (c) Full retreat when appropriate.

**Rotate:**
- [ ] **(a)** File shift only
- [x] **(b)** Rank shift (primary)
- [x] **(c)** Both — rank shift main functionality; other movement types for advanced formation tracking. Formations change flexibly per situation; leader abilities affect flexibility (defer leader abilities).

---

## 4. Surround — Max Split Divisor (Section 3.6)

**Value:** Cap on `num_close_threats` in defense split. E.g. 3, 4, 5.
- [x] **4** (default; tune in Phase 6)

---

## 5. Flanking (Section 3.8)

**Investigate:** Engagement angle vs ZoC-based for system accuracy. See `docs/ENGAGEMENT_ANGLE_VS_ZOC_FLANKING_INVESTIGATION.md`.

**Option:**
- [ ] **A: File-based** — Flank = leftmost/rightmost files. ×0.75 parry when targeting.
- [ ] **B: Engagement angle** — Per-pair angle (front/flank/rear). Modifier per angle.
- [x] **C: ZoC-based** — When zone control < threshold, enemy can occupy = flank/rear.

**Hybrid:** Formation vs formation uses ZoC; pack vs formation uses engagement-angle fallback. Add `protection_circle_active` on encounter/formation to disable flank/rear entirely (flag lore: magic circles).

**Modifier values:** 0.8 and 0.7 work for now; investigate more accurate numbers.
- Front: 1.0 (baseline)
- Flank: 0.8 (placeholder)
- Rear: 0.7 (placeholder)

---

## 6. Event Queue — Simultaneous Events (Section 3.9)

**Tie-break when multiple events at same resolve_at:**
- [x] Agility, then combatant_id (suggested)
- [ ] Combatant_id only
- [ ] Random
- [ ] Other: _____

---

## 7. Formation Targeting — Point 8 (Section 3.12)

**Engagement restriction:** Units can only attack enemies at appropriate distance based on formation positions and weapon ranges. Parry deficit: add later to awareness for decisions; initially based only on whether unit is physically capable of blocking.

**spacing_m source:**
- [ ] **(a)** Explicit per formation
- [x] **(b)** Derive from density (tight=0.9, normal=1.2, loose=1.8)

**effective_distance formula:**
- [x] `|Δfile| × avg_spacing` (simple)
- [ ] Add rank depth / diagonal
- [ ] Other: _____

**REACH_SAFETY_FACTOR:** 0.8 for now; investigate more accurate numbers.
- [x] 0.8 (placeholder)

**ZoC extent modifier:**
- [ ] Add now
- [x] Defer to Phase 4+

---

## 8. Multi-Target (Section 3.11) — Deferred to Implementation

When implementing, pick:
- Close slots per target: _____
- AI target weighting: (yes/no) _____
- Defense split max: _____

---

## 9. Parry Choice — Threat Scoring (Investigation Part 4b)

When defender must choose which attack to parry:
- [ ] **A: Momentum-based** — threat = parry_p_a (simple)
- [ ] **B: Expected damage** — threat = estimated_damage_on_hit
- [ ] **C: Combined** — parry_p_a × damage_weight + partial_deflect_factor
- [ ] **Other:** _____

---

## 10. Weapon State — Wind-Up Commit (Investigation Part 4b)

**Per-move commit_fraction:** Each move has appropriate percentage for its specific movement type. When does blade switch from near-body to extended during wind-up?
- [ ] **Global:** Use COMMITMENT_FRACTION (e.g. 0.8 — extended in last 20% of wind-up)
- [x] **Per move:** Add `commit_fraction` to move def (0–1). Default 0.7; thrusts 0.6; heavy swings 0.8. Each move switches at its specific percentage.
- [ ] **Other:** _____

---

## Notes

- **Master outline:** See `docs/IMPLEMENTATION_OUTLINE.md` for consolidated phase-by-phase implementation guide.
- **Parry choice** triggers only when defender cannot parry both attacks (capacity/time insufficient). If they can parry all, no choice.
- **Wind-up extended phase:** Attacker's weapon counts as extended after commit point. See investigation Part 4b.
