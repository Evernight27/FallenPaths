# Master implementation order (Fallen Paths — combat)

**Purpose:** Single **sequenced spine** for “what to implement next.” Other markdown files are **reference / design depth**; follow **this order** when choosing work so dependencies stay linear.

**Last verified against repo:** 2026-04-07 (combat `*.gd` + `ui/BattleScene.gd`).

**How to use:** Implement **top to bottom**. Within a tier, complete **bullets in order** unless a bullet is explicitly optional.

---

## Tier 0 — Baseline (shipped / maintain)

**Meaning:** The **current playable combat stack** — extend it; do not replace wholesale. `docs/COMBAT_ROADMAP_AND_STAMINA.md` Part 3 still has granular checkboxes; some items may remain optional or “nice-to-have.”

**Code anchors (non-exhaustive):**

| Area | Primary modules |
|------|-----------------|
| Orchestration | `combat/CombatManager.gd`, `CombatProcessTick.gd`, `CombatEventScheduler.gd`, `CombatEventDispatch.gd` |
| Formations | `CombatFormationSetup.gd`, `CombatFormationFlow.gd`, `FormationSlots.gd`, `FormationPreset.gd` |
| Actions / targeting | `AvailableActionsBuilder.gd`, `CombatResolveAction.gd`, `CombatEngagementResolver.gd` |
| Distance / ZoC | `CombatDistanceBands.gd`, `ZoneOfControl.gd`, `TacticalCombat.gd` (incursion, surround, ambush) |
| Breach / crash | `BreachResolver.gd`, `FormationBreachRules.gd` (breach clog + skirmish unclegs) |
| Engagement v1 | `CombatFormationEngagement.gd`, `CombatIntrusionGeometry.gd` (neighbor hold) |
| Medical | `MedicalPhaseController.gd`, `CombatMedicalCoordination.gd` (and related) |
| UI | `ui/BattleScene.gd`, `BattleUIUpdater.gd`, formation diagram builders |

**Do not rip out** Tier 0 when adding tiers below; extend the **smallest owning module** per `AGENTS.md` / `.cursor/rules/fallen-paths.mdc`.

---

## Tier 1 — Engagement geometry (active track)

**Plan:** `docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` (authoritative checklist + data dictionary).

| Step | Deliverable | Status |
|------|-------------|:------:|
| 1.1 | P0–P2: cohesion, posture, UI, neighbor crash hold, intruder **flags** | **Done** |
| 1.2 | **P3:** Vacancy plug (≠ death plug) + attacker slot release + intruder representation in defender space | **Todo** |
| 1.3 | **P4:** `CombatDistanceBands` / `effective_pair_eff_dist` for intruded combatants | **Todo** |
| 1.4 | **P5:** LINE↔OPEN hysteresis; encounter / discipline tags | **Todo** |
| 1.5 | **P6:** Morale → `morale_cohesion_factor` | **Todo** |
| 1.6 | **P7:** AI posture hooks; tests / harness tune; optional | **Todo** |

**After Tier 1.3:** Update `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` so breach/incursion/intruder language matches code (Tier 2).

---

## Tier 2 — Tactical docs & ZoC narrative sync

| Step | Deliverable | Depends on |
|------|-------------|------------|
| 2.1 | Align `TACTICAL_ZONES_BREACH_MOVEMENT.md` with engagement plan (intrusion, neighbor hold, vacancy plug) | Tier 1.2+ |
| 2.2 | Note in `TACTICAL_FORMATIONS_FF4.md` how intruder / vacancy extends rank×file (short subsection) | Tier 1.2 |

---

## Tier 3 — Melee depth (parry / weapon / guards)

**Plans:** `PARRY_BIND_AND_WEAPON_GEOMETRY.md`, `PARRY_DEFLECT_AND_CALIBRATION.md`, `GUARDS_LINES_AFTERBLOW.md`

| Step | Deliverable | Depends on |
|------|-------------|------------|
| 3.1 | Stable **distance + targeting** after intruder P4 (avoid redoing parry range work) | Tier 1.3 |
| 3.2 | Parry / bind / deflect changes per those docs | 3.1 |
| 3.3 | Guard line / afterblow integration | 3.2 |

---

## Tier 4 — AI & stance

**Plan:** `docs/AI_ENGAGEMENT_STANCE_AND_FEINTS.md`

| Step | Deliverable | Depends on |
|------|-------------|------------|
| 4.1 | Posture-aware weights (`CombatAIActionPicker`) once P5 stable | After **1.4** (hysteresis/tags); step **1.5** (morale) optional before AI tuning |
| 4.2 | Stance / feint / footwork per AI doc | 4.1 |

---

## Tier 5 — Damage & physics polish

**Plan:** `docs/PHYSICS_DAMAGE_AND_FLOW.md`

| Step | Deliverable | Depends on |
|------|-------------|------------|
| 5.1 | Angles, damage flow, audits — **after** Tier 3 if parry changes hit paths | Tier 3.2 |

---

## Tier 6 — Medical & pain extensions

**Plan:** `docs/MEDICAL_PAIN_INCAPACITATION.md`

| Step | Deliverable | Depends on |
|------|-------------|------------|
| 6.1 | Extensions as needed; medical phase already interacts with `CombatManager` | Independent, but avoid conflicting with formation busy states |

---

## Tier 7 — Research / fidelity (non-blocking)

**Plan:** `docs/HEMA_ROADMAP_AND_SOURCES.md` — research, comparisons, future fidelity; **does not** gate implementation tiers above.

---

## Plan inventory (all combat markdown)

| Document | Role in spine |
|----------|----------------|
| **This file** | **Order** — start here |
| `README.md` | Index of all combat markdown + link here |
| `ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` | **Tier 1** detail |
| `COMBAT_ROADMAP_AND_STAMINA.md` | Historical phases, stamina, consolidated checklists |
| `TACTICAL_ZONES_BREACH_MOVEMENT.md` | ZoC, movement, breach narrative — **sync Tier 2** |
| `TACTICAL_FORMATIONS_FF4.md` | Formation model — **extend Tier 2** after intrusion |
| `AI_ENGAGEMENT_STANCE_AND_FEINTS.md` | **Tier 4** |
| `PARRY_*`, `GUARDS_LINES_AFTERBLOW.md` | **Tier 3** |
| `PHYSICS_DAMAGE_AND_FLOW.md` | **Tier 5** |
| `MEDICAL_PAIN_INCAPACITATION.md` | **Tier 6** |
| `HEMA_ROADMAP_AND_SOURCES.md` | **Tier 7** |

---

## Changelog

- **2026-04-07:** Verified against codebase; Tier 0 expanded with module table; Tier 4 dependency wording fixed; plan inventory + `README.md`; last-verified stamp.
- **Initial:** Master order + inventory; Tier 1 aligned with engagement plan P0–P7.
