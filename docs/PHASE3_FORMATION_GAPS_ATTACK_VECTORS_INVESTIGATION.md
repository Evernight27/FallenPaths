# Phase 3: Formation Gaps and Attack Vectors — Investigation

**Question:** Do formation gaps need to be implemented more thoroughly for attack vectors at the current stage of the plan?

---

## Current State (Phase 3)

- **Slots:** `formation.slots` maps `(rank, file)` → combatant_id for primary occupants.
- **Slot obstacles:** `formation.slot_obstacles` tracks dead/incapacitated in each slot (non-blocking).
- **Targeting:** `AvailableActionsBuilder` filters melee targets: opponent must be rank 0 (front), file adjacent (|Δfile| ≤ 1), weapon.melee_range >= effective_distance.
- **Gaps:** `formation.gaps` is not maintained. When a unit dies, we remove from slots and add to obstacles; plug fills the vacancy. No persistent "gaps" set.

---

## When Would Gaps Matter?

| Use case | Phase | Needed now? |
|----------|-------|-------------|
| **Attack vectors** | 3 | Targeting is unit-based (enemy rank 0). We do not attack empty slots. |
| **Incursion/breakthrough** | 6 | Enemy pushes into our gap when plug fails. Requires ZoC. |
| **Lateral plug** | 5+ | Neighbors shift to cover gap. Uses slot occupancy, not explicit gaps. |
| **Lane clarity** | 5 | "Blocked" = living unit in the way. Does not require gaps. |

---

## Conclusion

**No.** Formation gaps do not need to be implemented for Phase 3 attack vectors.

- **Attack vectors:** We target **enemy units** in rank 0, adjacent files. We never target an empty slot.
- **Gaps** become relevant in Phase 6 for the plug vs incursion contest (breakthrough into gaps when plug fails).
- **Current flow:** Death → remove from slots → plug fills → slot occupied. Any temporary "gap" is immediately filled by plug. No open gaps persist for targeting.

**Recommendation:** Defer `formation.gaps` to Phase 6. Add it when implementing breakthrough (plug vs incursion contest). At Phase 3, slots + slot_obstacles are sufficient for targeting and plug logic.
