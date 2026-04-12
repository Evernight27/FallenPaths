# Engagement: line cohesion, posture, intrusion geometry

**Status:** In progress — foundation and crash-gap modeling landed; slots, vacancy plug, and intruder distance are next.

**Last verified against repo:** 2026-04-07.

**Where this sits in the full project:** Follow **`docs/IMPLEMENTATION_ORDER.md`** (Tier 1). This file is the **detailed** checklist for that tier only.

**Related code:** `combat/CombatFormationEngagement.gd`, `combat/CombatIntrusionGeometry.gd`, `combat/BreachResolver.gd`, `combat/CombatEngagementResolver.gd`, `combat/CombatManager.gd`, `combat/CombatFormationSetup.gd`, `ui/BattleScene.gd`  
**Related docs:** `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md`, `combat/CombatConstants.gd` (tuning), `combat/FormationBreachRules.gd` (skirmish / breach clog).

---

## 1. Logical dependency order (read top → bottom)

Work should generally follow this chain so each layer has inputs from the layer above:

1. **Formation truth** — `slots`, `rank`/`file`, plug-on-death (`CombatFormationFlow`), incursion + ZoC (`TacticalCombat`, `ZoneOfControl`).
2. **Cohesion & posture (telemetry + rules)** — scalar `line_cohesion`, discrete `engagement_posture` (`CombatFormationEngagement`), UI + `engagement_state_changed`.
3. **Crash contest (gap vs line)** — `BreachResolver` hold/drive; **local** neighbor support (`CombatIntrusionGeometry`).
4. **Intrusion as geometry** — combatant role + host/anchor; then **empty attacker slot**, **intruder representation in defender space**, **vacancy plug** distinct from death plug.
5. **Pair distance** — `CombatDistanceBands` / `effective_pair_eff_dist` aware of intruder logical position.
6. **Morale & encounter tags** — feed `morale_cohesion_factor` and posture thresholds without duplicating incursion math.
7. **AI & tests** — consume posture/cohesion where useful; extend harnesses when crash geometry changes.

---

## 2. Current state checklist

Posture string values **must** match `CombatConstants.ENGAGEMENT_POSTURE_LINE` / `_OPEN` / `_DUEL` (used in formation dict + UI).

### 2.0 Skirmish vs breach clog (formation moves)

| Item | State | Notes |
|------|:-----:|-------|
| `FormationBreachRules.breach_clogs_open_lanes` vs `breach_blocks_open_lane_moves` | **Done** | Raw breach marks vs move lock; skirmish unclegs via `FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES` + `is_skirmish_line_engagement`. |
| `AvailableActionsBuilder` / `CombatResolveAction` use `breach_blocks_open_lane_moves` | **Done** | Formation moves respect skirmish-aware clog. |

### 2.1 Foundation & visibility

| Item | State | Notes |
|------|:-----:|-------|
| Per-formation `line_cohesion` (0..1) | **Done** | From rank-0 fill, avg `breached_files`, `morale_cohesion_factor` (default 1.0). |
| Per-formation `engagement_posture` (`line` / `open` / `duel`) | **Done** | Duel = both sides exactly one rank-0 fighter; line/open from cohesion threshold. |
| Formation init keys in `CombatFormationSetup` | **Done** | Includes `morale_cohesion_factor`. |
| `CombatManager._recompute_zoc_and_distance()` runs engagement recompute | **Done** | After incursion + ZoC + distance bands. |
| `engagement_state_changed` + `notify_engagement_state_changed` | **Done** | Emitted only when cohesion or posture changes; `CombatDebug.flow_log` gated by `COMBAT_EVENT_DEBUG`. |
| Battle UI: label under each formation diagram | **Done** | `BattleScene` — posture + cohesion %. |

### 2.2 Crash / gap (local “hold the gap”)

| Item | State | Notes |
|------|:-----:|-------|
| `CombatIntrusionGeometry.crash_neighbor_hold_support` | **Done** | Adjacent rank-0 allies, weapon reach scale, cap 2. |
| `BreachResolver` adds neighbor hold to defender hold | **Done** | Global `front_z` + body unchanged. |

### 2.3 Intrusion state (flags only)

| Item | State | Notes |
|------|:-----:|-------|
| Combatant defaults: `engagement_role`, `intrusion_host_fid`, `intrusion_anchor_file` | **Done** | In `CombatManager.register`; cleared in `_reset_tactical_breach_state`. |
| On crash success: set `intruded` + host + anchor | **Done** | `CombatEngagementResolver`; `notify_formation_changed` for attacker & defender formations. |
| Remove intruder from own `slots` / empty rank-0 hole on attacker side | **Todo** | Attacker still occupies home slot until vacancy path exists. |
| Represent intruder in defender `slots` (or parallel structure) | **Todo** | Needed for “inside the line” fiction and plug logic. |

### 2.4 Plug taxonomy & formation flow

| Item | State | Notes |
|------|:-----:|-------|
| Death plug (promote same file) | **Done** (pre-existing) | `CombatFormationFlow.on_combatant_died`. |
| Vacancy plug (empty rank-0 without death) | **Todo** | Distinct from death plug; triggered after intrusion slot update. |
| Document ordering: death vs vacancy vs swap | **Todo** | Short subsection in §4 below + code comments in `CombatFormationFlow`. |

### 2.5 Distance & targeting

| Item | State | Notes |
|------|:-----:|-------|
| `CombatDistanceBands` / `effective_pair_eff_dist` for `ENGAGEMENT_ROLE_INTRUDED` | **Todo** | Intruder still uses home rank/file for bands today. |

### 2.6 Cohesion & posture refinement

| Item | State | Notes |
|------|:-----:|-------|
| LINE ↔ OPEN hysteresis (`L_in` > `L_out`) | **Todo** | Constants + stored band or last posture in formation dict. |
| Encounter / army tags (discipline, default open/line) | **Todo** | Bias thresholds or `morale_cohesion_factor` baseline. |
| Per-side asymmetric posture (open army vs line) | **Todo** | Current posture is per formation but duel/line/open rules are still coarse. |

### 2.7 Morale

| Item | State | Notes |
|------|:-----:|-------|
| Morale system driving `morale_cohesion_factor` | **Todo** | Placeholder 1.0 until morale module exists. |

### 2.8 AI, tests, cross-doc

| Item | State | Notes |
|------|:-----:|-------|
| `CombatAIActionPicker` weights from posture | **Todo** | Optional after posture is stable. |
| `IncursionBreachTest` / harness updates for neighbor hold | **Optional** | Re-baseline if `p_win` expectations are asserted. |
| Sync `TACTICAL_ZONES_BREACH_MOVEMENT.md` with this plan | **Todo** | Avoid drift on breach vs incursion vs intruder. |

---

## 3. Roadmap table (ordered phases)

Phases match §1 dependency order. **Done** phases are collapsed into the checklist above; remaining work:

| Phase | Name | Deliverable | Status |
|:-----:|------|-------------|:------:|
| **P0** | Foundation & UI | Cohesion, posture, signal, labels | **Done** |
| **P1** | Neighbor crash hold | `CombatIntrusionGeometry` + `BreachResolver` | **Done** |
| **P2** | Intrusion flags + UI refresh | Crash success fields + `formation_changed` | **Done** |
| **P3** | Slot + vacancy | Attacker removed from home slot; intruder cell on defender; vacancy plug path | **Todo** |
| **P4** | Intruder distance | `CombatDistanceBands` / `AvailableActionsBuilder` use intrusion geometry | **Todo** |
| **P5** | Posture polish | Hysteresis; encounter tags; asymmetric rules if needed | **Todo** |
| **P6** | Morale | Wire `morale_cohesion_factor` | **Todo** |
| **P7** | AI & tests | Optional weights; test / doc sync | **Todo** |

---

## 4. Plug taxonomy (spec — implementation in P3)

| Kind | Trigger | Owner |
|------|---------|--------|
| **Death plug** | Ally dies → empty `(rank,file)` in column | `CombatFormationFlow.on_combatant_died` (existing). |
| **Vacancy plug** | Empty rank-0 (or other) cell **without** death — e.g. intruder left home slot | New path; may reuse slot walk with a different entry condition. |
| **Pair formation resolve** | Swap / rotate / fall_back complete | `CombatFormationFlow` (existing). |

**Rule (to implement):** vacancy plug must not fight death plug in the same tick; define order (e.g. apply **slot writes** for intrusion first, then **one** promote pass per file).

---

## 5. Data dictionary (authoritative field names)

### Per formation (`manager.formations[fid]`)

| Field | Type | Purpose |
|-------|------|---------|
| `line_cohesion` | float 0..1 | Continuous line solidity. |
| `engagement_posture` | String | Same strings as `CombatConstants.ENGAGEMENT_POSTURE_*` (UI + future rules). |
| `morale_cohesion_factor` | float | Morale hook; default **1.0**. |
| `breached_files` | Dictionary | Per-file breach severity (existing). |

### Per combatant (`CombatManager` combatant dict)

| Field | Type | Purpose |
|-------|------|---------|
| `engagement_role` | String | `CombatConstants.ENGAGEMENT_ROLE_LINE` \| `ENGAGEMENT_ROLE_INTRUDED` (extend as needed). |
| `intrusion_host_fid` | String | Defender `formation_id` when intruded; else `""`. |
| `intrusion_anchor_file` | int | Defender file index when intruded; else **-1**. |
| `tactical_penetration_depth` | int | Abstract depth (existing); may align with P4 distance. |

---

## 6. Tuning

All numeric defaults for cohesion, posture threshold, and neighbor hold live in **`combat/CombatConstants.gd`** (`COHESION_*`, `LINE_COHESION_POSTURE_LINE_MIN`, `CRASH_NEIGHBOR_*`). Tune by playtest after P3–P4 land.

---

## 7. Changelog (plan doc only)

- **2026-04-07:** Repo verification pass; §2.0 skirmish/breach clog; posture/role cross-refs to `CombatConstants`; last-verified stamp.
- **Prior revision:** Reordered by dependency chain; checklist replaces ambiguous single table; P0–P2 marked done; P3–P7 explicit; plug taxonomy and data dictionary added.
