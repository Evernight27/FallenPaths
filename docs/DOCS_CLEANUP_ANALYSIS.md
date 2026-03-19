# Docs Cleanup Analysis: Invalidated / Complete Documents

Analysis of 68 docs in `/docs` to identify files that are **invalidated**, **already complete**, or **superseded** and can be removed to reduce clutter.

**Cleanup executed:** March 2025 — 20 documents removed per recommendations below.

**Consolidation executed:** March 2025 — additional cleanup:
- **Deleted (5):** STAMINA_ENGAGEMENT_GATE_AND_DISTANCE_OPTIONS, ENGAGEMENT_FLURRY_IMPLEMENTATION_OPTIONS, ENGAGEMENT_ALTERNATIVE_PARADIGMS_AND_REFERENCE_SYSTEMS, DOMINIONS_CHAINMAIL_ZOC_HYBRID_INVESTIGATION, MEN_OF_WAR_ZOC_COMPARISON_INVESTIGATION
- **Deleted (1):** FEINT_STAMINA_COUNTER_FLURRY_DEEP_INVESTIGATION (merged into FEINT_COUNTER_STAMINA_READINESS_DIAGONAL)
- **Deleted (3):** PARRY_DESIGN_OPTIONS, PARRY_IMPROVEMENT_OPTIONS, PARRY_DODGE_TWEAK_OPTIONS (merged into PARRY_SYSTEM_OPTIONS)
- **Created:** PARRY_SYSTEM_OPTIONS.md (consolidated parry design, improvement, and tweak options)

---

## Summary: Documents Safe to Remove

### Tier 1: Explicitly Complete — Implementation Done (13 docs)

These documents have clear "IMPLEMENTED" / "Status: Implemented" / "Completed" markers. The investigations led to code that exists; the docs are historical records.

| Document | Why Remove | Replacement |
|----------|------------|-------------|
| **AFTERBLOW_IMPLEMENTATION_INVESTIGATION.md** | "IMPLEMENTED" section; AfterblowHandler.gd exists | Implementation is the source of truth |
| **MODULARIZATION_INVESTIGATION.md** | "All listed extractions have been completed"; "March 2025 Implementation (Completed)" | Code structure; MODULARIZATION_POSSIBILITIES has future items |
| **MASS_AND_GUARD_WOBBLE_INVESTIGATION.md** | "Status: Implemented" | — |
| **PARRY_DODGE_INVESTIGATION.md** | "Status: Implemented"; "Implementation Summary (completed)" | — |
| **BODY_PART_BLOCKING_PATHWAYS_INVESTIGATION.md** | "Option 6 (Path + Guard Intercept) — IMPLEMENTED" | — |
| **STRONG_WEAK_IMPLEMENTATION_INVESTIGATION.md** | "Already implemented" for shaft/haft | — |
| **GLANCING_RECOVERY_INVESTIGATION.md** | "Implemented: Method B" | — |
| **BALANCE_TRACE_HEMA.md** | "Recommendation (implemented)" | — |
| **ATTACK_PATH_DEFENDER_POSITIONING_INVESTIGATION.md** | "Guard-dependent paths — Implemented" (§1) | ATTACK_PATHS_BY_GUARD in code |
| **TRANSITION_COST_WEAPON_POSITIONING_INVESTIGATION.md** | Documents transition cost — already implemented per IMPORTANT_IMPROVEMENTS | — |
| **BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md** | "OFF_BALANCE_GAUGE_FILL_MULT ✓ Already implemented" | — |
| **COMBAT_ISSUES_TODO_INVESTIGATION.md** | §1 Arm interpose "Implemented"; most items are design options, not investigations | Keep as TODO tracker; or merge open items into COMBAT_SYSTEM_ISSUES |
| **RIPOSTE_PHYSICS_INVESTIGATION.md** | "Option A: Reduced Wind-Up from Guard Position (Already Implemented)" | — |

---

### Tier 2: Superseded by Angle System (4 docs)

The continuous angle system is implemented (ANGLE_SYSTEM_INTEGRATION_STATUS). These investigations led to that implementation; the design space has been resolved.

| Document | Why Remove | Superseded By |
|----------|------------|---------------|
| **ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md** | Phase 1–3 recommendations implemented (probability curves, 8 dir or continuous) | ANGLE_SYSTEM_INTEGRATION_STATUS.md |
| **ANGLE_VS_DISCRETE_AND_BILATERAL_INTERSECTION_INVESTIGATION.md** | Bilateral deflection (`get_deflected_angle_bilateral`) implemented | CombatConstants.gd; ANGLE_SYSTEM_INTEGRATION_STATUS |
| **APPROACH_5_VS_6_HEMA_COMPARISON.md** | Approach 6 hybrid implemented via continuous angle system | Angle-based implementation |
| **SOFT_DEFLECTION_WEAPON_POSITION_INVESTIGATION.md** | Guard deflect blend / angle-based deflection implemented | GuardLineUpdater, get_deflected_line_from_angles |

---

### Tier 3: Superseded by Other Docs or Code (3 docs)

| Document | Why Remove | Superseded By |
|----------|------------|---------------|
| **PHYSICS_INTEGRATION_INVESTIGATION.md** | Integration done; says INTERPOSE "Superseded by guard-dependent paths" | Implementation; PHYSICS_REALISM_DECISIONS_INVESTIGATION |
| **IMPORTANT_IMPROVEMENTS_IMPLEMENTATION_ROADMAP.md** | §1 "What's Already Done" — guard dynamics, afterblow, transition cost all done | Roadmap items implemented; HEMA_SYSTEM_CHANGES has remaining work |
| **ATTACKING_BINDING_ANGLE_IMPROVEMENT_INVESTIGATION.md** | Mostly cleanup recommendations (dead code removal); angle flow already implemented | Actionable items could move to COMBAT_SYSTEM_ISSUES or a tech-debt list |

---

## Documents to KEEP (Still Relevant)

| Document | Reason |
|----------|--------|
| **ANGLE_SYSTEM_INTEGRATION_STATUS.md** | Current reference for angle system; lists updated components |
| **LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md** | Design reference; physics derivation (Part 4B) still useful |
| **COMBAT_ENTITY_INTERFACE.md** | Interface spec |
| **COMBAT_SYSTEM_ISSUES.md** | Active issue tracker |
| **COMBAT_PARRY_MISS_RESEARCH.md** | HEMA calibration reference |
| **PHYSICS_REALISM_DECISIONS_INVESTIGATION.md** | Consolidates implemented vs not-implemented physics |
| **MODULARIZATION_POSSIBILITIES.md** | Future extraction opportunities (CoreEntity, etc.) |
| **HEMA_SYSTEM_CHANGES_IMPLEMENTATION_ROADMAP.md** | Remaining HEMA work; bind/deflect/riposte options |
| **KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md** | KCD-style features not yet implemented |
| **MENTAL_STACK_*,** MELEE_SIMULATION_AI, etc. | Future AI/mental stack work |

---

## Optional: Consolidate Before Delete

- **MODULARIZATION_POSSIBILITIES** vs **MODULARIZATION_INVESTIGATION**: The latter says "additional beyond" the former. If removing MODULARIZATION_INVESTIGATION, ensure MODULARIZATION_POSSIBILITIES still has the completed items or a pointer to implemented code.
- **COMBAT_ISSUES_TODO_INVESTIGATION**: Consider merging open items (§2–§10) into COMBAT_SYSTEM_ISSUES, then remove.
- **LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION**: Afterblow and line guard are done. Keep as reference for physics derivation, or archive elsewhere.

---

## Suggested Removal Order

1. **Safest first** (implementation clearly done):  
   AFTERBLOW_IMPLEMENTATION_INVESTIGATION, MASS_AND_GUARD_WOBBLE_INVESTIGATION, PARRY_DODGE_INVESTIGATION, GLANCING_RECOVERY_INVESTIGATION, STRONG_WEAK_IMPLEMENTATION_INVESTIGATION, BODY_PART_BLOCKING_PATHWAYS_INVESTIGATION, BALANCE_TRACE_HEMA
2. **Angle-system superseded**:  
   ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION, ANGLE_VS_DISCRETE_AND_BILATERAL_INTERSECTION_INVESTIGATION, APPROACH_5_VS_6_HEMA_COMPARISON, SOFT_DEFLECTION_WEAPON_POSITION_INVESTIGATION
3. **Modularization / roadmaps** (after verifying no unique content):  
   MODULARIZATION_INVESTIGATION, IMPORTANT_IMPROVEMENTS_IMPLEMENTATION_ROADMAP, PHYSICS_INTEGRATION_INVESTIGATION, ATTACK_PATH_DEFENDER_POSITIONING_INVESTIGATION, TRANSITION_COST_WEAPON_POSITIONING_INVESTIGATION, BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION, RIPOSTE_PHYSICS_INVESTIGATION, ATTACKING_BINDING_ANGLE_IMPROVEMENT_INVESTIGATION

---

## Count

- **~20 documents** can be removed without losing critical information.
- **ANGLE_SYSTEM_INTEGRATION_STATUS** and **PHYSICS_REALISM_DECISIONS_INVESTIGATION** are the main current references for implemented systems.
