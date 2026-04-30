# Engagement: line cohesion, posture, intrusion geometry

**Status:** P3–P4 **shipped**; P5 **partial** — hysteresis, posture deltas, **`line_discipline`** / encounter `line_discipline`; **`morale_cohesion_factor`** remains **1.0** until morale module (**Tier 1.5**). Optional: richer tags, **2.1** tactical doc narrative sync.

**Last verified against repo:** 2026-04-27. **Spec addendum:** 2026-04-13 — **§4.1 intrusion wedge** + **§4.2 `lane_offset`** + distance. **2026-04-27:** Doc + code alignment — host formation id for ZoC/pair geometry centralized in **`ZoneOfControl.formation_id_for_zone_geometry`**; legacy **`LINE_COHESION_POSTURE_LINE_MIN`** constant removed (use **`LINE_COHESION_POSTURE_ENTER_LINE_MIN`** / **`LINE_COHESION_POSTURE_LEAVE_LINE_BELOW`** + discipline deltas only).

**Execution plan (ordered steps, exit criteria, implementation gate):** **`docs/IMPLEMENTATION_ORDER.md`** — Tier 1 expanded (P3–P7). Treat that file as the **single logical plan** before and during implementation.

**This file’s role:** **Specification** for Tier 1 — dependency narrative §1, verification tables §2, plug taxonomy §4, data dictionary §5, tuning §6. Do **not** duplicate sequencing or milestone status outside `IMPLEMENTATION_ORDER.md` (update the plan there when you close a step).

**Related code:** `combat/CombatFormationEngagement.gd`, `combat/CombatIntrusionGeometry.gd`, `combat/BreachResolver.gd`, `combat/CombatEngagementResolver.gd`, `combat/CombatManager.gd`, `combat/CombatFormationSetup.gd`, `ui/BattleScene.gd`  
**Related docs:** `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md`, `combat/CombatConstants.gd` (tuning), `combat/FormationBreachRules.gd` (skirmish / breach clog).

---

## 1. Logical dependency order (read top → bottom)

Work should generally follow this chain so each layer has inputs from the layer above:

1. **Formation truth** — `slots`, `rank`/`file`, plug-on-death (`CombatFormationFlow`), incursion + ZoC (`TacticalCombat`, `ZoneOfControl`).
2. **Cohesion & posture (telemetry + rules)** — scalar `line_cohesion`, discrete `engagement_posture` (`CombatFormationEngagement`), UI + `engagement_state_changed`.
3. **Crash contest (gap vs line)** — `BreachResolver` hold/drive; **local** neighbor support (`CombatIntrusionGeometry`).
4. **Intrusion as geometry** — combatant role + host/anchor; **empty attacker slot**; **intruder in defender `slots`** (occupancy / plugs / diagram); **vacancy plug** distinct from death plug; **intrusion wedge** on the defender formation (§4.1) as the **canonical** description of the torn sector (depth, pressure, lateral extent)—not inferred only from co-occupied cells.
5. **Pair distance** — `AvailableActionsBuilder.effective_pair_eff_dist` (used by `CombatDistanceBands`, `BreachResolver`, …) uses **wedge-aware** geometry: per-file wedge state **plus** per-combatant **`lane_offset`** as the **lateral metric** clamped/derived from the wedge seam (P4). Integer `file` / `slots` stay topology; wedge + offsets are the **continuous** breach model.
6. **Encounter tags (Tier 1.4)** — posture threshold deltas + **`line_discipline`** (see `CombatConstants` / `CombatFormationEngagement._effective_posture_thresholds`). **Morale (Tier 1.5)** — will drive `morale_cohesion_factor` (currently fixed **1.0**). **Cohesion inputs** prefer wedge + **`breached_files`** over ad-hoc slot heuristics where both exist.
7. **AI & tests** — e.g. **`CombatAIActionPicker`** crash weight vs **`engagement_posture`**; extend harnesses when crash or wedge geometry changes.

---

## 2. Current state checklist

> **Sequencing:** Milestone table and **P3–P7 numbered steps** live in **`docs/IMPLEMENTATION_ORDER.md` (Tier 1 expanded).** Update that file when status changes. The tables below are the **spec verification** view (what each area must satisfy when done).

Posture string values **must** match `CombatConstants.ENGAGEMENT_POSTURE_LINE` / `_OPEN` / `_DUEL` (used in formation dict + UI).

### 2.0 Skirmish vs breach clog (formation moves)

| Item | State | Notes |
|------|:-----:|-------|
| `FormationBreachRules.breach_clogs_open_lanes` vs `breach_blocks_open_lane_moves` | **Done** | Raw breach marks vs move lock; skirmish unclegs via `FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES` + `is_skirmish_line_engagement` (`CombatEngagementMode` source). |
| `AvailableActionsBuilder` / `CombatResolveAction` use `breach_blocks_open_lane_moves` | **Done** | Formation moves respect skirmish-aware clog. |
| Engagement mode Option 2 baseline (`duel` cap + `formation` min by active counts) | **Partial** | `CombatEngagementMode.snapshot` now includes `player_active` / `enemy_active`; mode classifier gates by active-count bands + front/fill + hysteresis + intrusion grace. Remaining work is P9 runtime soak/telemetry lock. |

### 2.1 Foundation & visibility

| Item | State | Notes |
|------|:-----:|-------|
| Per-formation `line_cohesion` (0..1) | **Done** | From rank-0 fill, avg `breached_files`, `morale_cohesion_factor` (default 1.0). |
| Per-formation `engagement_posture` (`line` / `open` / `duel`) | **Done** | Duel = both sides exactly one rank-0 fighter; line/open from cohesion threshold. |
| Formation init keys in `CombatFormationSetup` | **Done** | Includes `morale_cohesion_factor`. |
| `CombatManager._recompute_zoc_and_distance()` runs engagement recompute | **Done** | After incursion + ZoC + distance bands. |
| `engagement_state_changed` + `notify_engagement_state_changed` | **Done** | Emitted only when cohesion or posture changes; `CombatDebug.flow_log` for cohesion/posture lines requires `COMBAT_EVENT_DEBUG` and `COMBAT_EVENT_DEBUG_VERBOSE` (see `CombatConstants.gd`). |
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
| Remove intruder from own `slots` / empty rank-0 hole on attacker side | **Done** | `CombatFormationFlow.apply_intrusion_after_crash_success` + vacancy plug on home file. |
| Represent intruder in defender `slots` (occupancy) | **Done** | `FormationSlots.place_intruder_behind_front_line` (rear ranks when depth > 1); plugs/diagram use `slots`. |
| Per-formation **intrusion wedge** (`intrusion_wedge_by_file`) | **Done** | **P4** canonical breach corridor; writers/readers + tests; see §4.1. |

### 2.4 Plug taxonomy & formation flow

| Item | State | Notes |
|------|:-----:|-------|
| Death plug (promote same file) | **Done** (pre-existing) | `CombatFormationFlow.on_combatant_died`. |
| Vacancy plug (empty rank-0 without death) | **Done** | `CombatFormationFlow.apply_vacancy_plug_same_file`; after intrusion slot writes. |
| Document ordering: death vs vacancy vs swap | **Done** | §4 rule line + class comment on `CombatFormationFlow` (plug order). |

### 2.5 Distance & targeting

| Item | State | Notes |
|------|:-----:|-------|
| `AvailableActionsBuilder.effective_pair_eff_dist` (+ `CombatDistanceBands` callers) for `CombatConstants.ENGAGEMENT_ROLE_INTRUDED` | **Done** | Wedge + anchor + `lane_offset`; bands use file-spacing equivalent; ZoC host geometry for intruders. |
| Per-formation **`intrusion_wedge_by_file`** | **Done** | Authoritative breach state; stress, cohesion, eff dist, UI corridor strip; §4.1. |
| Per-combatant `lane_offset` (bounded float; default 0) | **Done** | Seam bias + repack on plugs/moves; anchor peer nudge §4.2. |
| Intrusion / plug **repack** rules for `lane_offset` + wedge | **Done** | Wedge cleared on death/reset; offsets repacked in `CombatFormationFlow`. |
| **`lane_stress_by_file` / ZoC** use wedge | **Done** | `TacticalCombat` + `ZoneOfControl` lane stress; intruder host ZoC id for geometry. |

### 2.6 Cohesion & posture refinement

| Item | State | Notes |
|------|:-----:|-------|
| LINE ↔ OPEN hysteresis (`L_in` > `L_out`) | **Done** | `CombatConstants.LINE_COHESION_POSTURE_ENTER_LINE_MIN` / `LINE_COHESION_POSTURE_LEAVE_LINE_BELOW`; prior `engagement_posture` on formation dict. |
| Encounter / army tags (discipline, default open/line) | **Partial** | `encounter`: `engagement_posture_enter_delta` / `engagement_posture_leave_delta` / `line_discipline` (`ENCOUNTER_KEY_LINE_DISCIPLINE`); preset: `discipline_posture_*_delta`, `line_discipline`. **Morale not wired** (factor stays 1.0). |
| Per-side asymmetric posture (open army vs line) | **Todo** | Current posture is per formation but duel/line/open rules are still coarse. |

### 2.7 Morale

| Item | State | Notes |
|------|:-----:|-------|
| Morale system driving `morale_cohesion_factor` | **Todo** | Placeholder 1.0 until morale module exists. |

### 2.8 AI, tests, cross-doc

| Item | State | Notes |
|------|:-----:|-------|
| `CombatAIActionPicker` weights from posture | **Partial** | Crash (`MOVE_ID_CRASH`) weight multiplier from side **`engagement_posture`**; further moves / cohesion coupling optional. |
| `IncursionBreachTest` / harness updates for neighbor hold | **Optional** | Re-baseline if `p_win` expectations are asserted. |
| Engagement mode regression harness checks (historical count bands + hysteresis invariants) | **Partial** | `IncursionBreachTest` validates mode/count-band consistency, compares tactical vs harness mode snapshots, and emits transition/error telemetry counters; still needs long-run multi-seed soak scenarios. |
| Sync `TACTICAL_ZONES_BREACH_MOVEMENT.md` with this plan | **Partial** | **2026-04-27:** implementation banner updated (P3–P4 in code); bundled investigation sections may still use pre-wedge language — edit when touching those sections (**Tier 2.1**). |

---

## 3. Roadmap phases (P0–P7)

**Milestone names, status, and implementation steps** are maintained in **`docs/IMPLEMENTATION_ORDER.md`** — Tier 1 milestone summary + Tier 1.1–1.6 sections. §1 dependency order here matches that plan.

---

## 4. Plug taxonomy (spec — implementation in P3)

| Kind | Trigger | Owner |
|------|---------|--------|
| **Death plug** | Ally dies → empty `(rank,file)` in column | `CombatFormationFlow.on_combatant_died` (existing). |
| **Vacancy plug** | Empty rank-0 (or other) cell **without** death — e.g. intruder left home slot | New path; may reuse slot walk with a different entry condition. |
| **Pair formation resolve** | Swap / rotate / fall_back complete | `CombatFormationFlow` (existing). |

**Rule (to implement):** vacancy plug must not fight death plug in the same tick; define order (e.g. apply **slot writes** for intrusion first, then **one** promote pass per file).

### 4.1 Intrusion wedge (P4 — canonical breach geometry)

**Purpose:** Represent the **torn sector** of the line (the physical “gap” and pressure through the frontage) as **formation-scoped** state keyed by **file**, independent of whether a tile is co-occupied. This is the **authoritative** model for “between the units” for **cohesion, lane stress, ZoC, pair distance, and UI**; **`slots`** remain the source of truth for **who occupies which cell** and for **plugs**.

| Topic | Convention / note |
|-------|-------------------|
| **Container** | `manager.formations[fid].intrusion_wedge_by_file` — `Dictionary` mapping **file index** (int) → **wedge** (`Dictionary`). Missing key = no wedge at that file. |
| **Minimum wedge fields** (v1; extend in code + here when shipped) | `pressure` (float 0..1, breach intensity), `depth` (float 0..1, how far “through” the line), `intruder_id` (int, primary occupant of the breach; **-1** if cleared). Optional: `halfwidth_files` (float, lateral blur for neighbors), `updated_at` (combat clock) for decay. |
| **Writer** | On **crash success**, same tick as slot writes: upsert wedge at **`intrusion_anchor_file`** (and optionally neighbor files scaled by `halfwidth_files`). Initialize from `breach_severity` / existing `breached_files[file]` where practical so one code path owns severity. |
| **Readers (wedge throughout)** | `CombatFormationEngagement` (cohesion), `TacticalCombat._recompute_lane_stress_by_file` (stress from wedge + optional dual), `ZoneOfControl` (if lane stress or frontage uses wedge), `AvailableActionsBuilder.effective_pair_eff_dist`, `CombatDistanceBands`, `BreachResolver` as needed, formation diagram / battle UI (glyph or shading by file). |
| **Clear / decay** | On intruder death, retreat, or scripted breach heal: reduce `pressure`/`depth`, remove key when below epsilon, or clear `intruder_id`; keep **`breached_files`** in sync if it remains a parallel summary for debug or legacy. |
| **Invariant** | No consumer should assume “breach = dual living in column only”; **wedge may be non-zero while `slots` show a solo intruder** in depth ranks. |

### 4.2 Lane metric offset (P4 — with `effective_pair_eff_dist`)

**Purpose:** Represent **sub-file** lateral position on the engagement line so reach, crash contests, and distance bands are not limited to integer `|Δfile|` steps. **Topology** (who holds which `slots` cell, vacancy, death) stays on the **rank×file** grid from P3; **`lane_offset` does not introduce gap-column cells** in P4. **Coupling:** on crash success and on wedge update, **bias `lane_offset`** for the intruder (and optionally anchor rank-0 peers) toward the **wedge seam** per §4.1 so combatant metrics stay consistent with formation-level breach geometry.

| Topic | Convention / note |
|-------|-------------------|
| **Range** | Closed interval **[-1, 1]** or **[-0.5, 0.5]**; pick one in code + comment and clamp all writers. |
| **Meaning of 0** | Fighter’s body is at the **nominal center** of their current `(rank, file)` column for engagement math. |
| **Sign** | Document whether positive is “toward global +file neighbor” or “toward enemy baseline”; use one sign everywhere in math + UI. |
| **Who has offsets** | All front-rank combatants may carry `lane_offset`; non–rank-0 can stay 0 until a later tier needs depth offsets. |

**When to set / update**

- **Register / reset / formation setup:** `lane_offset = 0` (or formation preset default).
- **Crash success (intruder):** after **`intrusion_wedge_by_file`** upsert (§4.1), set intruder offset **into the seam** (tuned constant toward wedge anchor / defender column center); optionally **nudge** anchor defender ±δ (and rare ± adjacent rank-0) so **pairwise** lateral distances stay ≥ a floor constant (anti-overlap). Bounds: clamp to range.
- **Vacancy / death / pair resolve:** whenever `rank` or `file` changes, **re-default or repack** offsets (simplest v1: reset non-intruded movers to 0; keep intruder offset until cleared with role); document chosen rule in `CombatFormationFlow` comments.

**Distance**

- `effective_pair_eff_dist` = **coarse term** (existing file spacing × density, intruder-aware file semantics per `IMPLEMENTATION_ORDER` Tier 1.3) **plus** **lateral metric term** `f(|Δfile|, lane_offset_a, lane_offset_b)` **plus** (when in/near a wedge) a **small depth / pressure term** derived from **`intrusion_wedge_by_file`** so pairs across the torn sector are not stair-stepped only by integer rank. When all offsets are 0 and wedge absent, restore baseline behavior within epsilon.

**Explicitly out of scope for P4**

- **Gap columns** as separate `slots` keys (interstitial cells): defer to a future milestone if seam occupancy puzzles require it; P4 stays **wedge + offset-in-lane** (no extra topology columns).

---

## 5. Data dictionary (authoritative field names)

### Per formation (`manager.formations[fid]`)

| Field | Type | Purpose |
|-------|------|---------|
| `line_cohesion` | float 0..1 | Continuous line solidity. |
| `engagement_posture` | String | Same strings as `CombatConstants.ENGAGEMENT_POSTURE_*` (UI + future rules). |
| `morale_cohesion_factor` | float | Morale hook; default **1.0**. |
| `breached_files` | Dictionary | Per-file breach severity (existing); **wedge writer** may initialize from this; long term avoid duplicating two conflicting severities—document which is canonical in code comments. |
| `intrusion_wedge_by_file` | Dictionary | **P4.** File → wedge dict (§4.1): canonical breach corridor for stress, cohesion, distance, UI. |
| `discipline_posture_enter_delta` / `discipline_posture_leave_delta` | float | **Tier 1.4.** From preset; added to hysteresis thresholds. |
| `line_discipline` | String | **Tier 1.4.** `strict` / `normal` / `loose` (`CombatConstants.LINE_DISCIPLINE_*`); empty = no extra shift. |

### Per combatant (`CombatManager` combatant dict)

| Field | Type | Purpose |
|-------|------|---------|
| `engagement_role` | String | `CombatConstants.ENGAGEMENT_ROLE_LINE` \| `ENGAGEMENT_ROLE_INTRUDED` (extend as needed). |
| `intrusion_host_fid` | String | Defender `formation_id` when intruded; else `""`. |
| `intrusion_anchor_file` | int | Defender file index when intruded; else **-1**. |
| `intrusion_source_file` | int | Home-formation file column when intruded (death/vacancy column); **-1** when not intruded. |
| `lane_offset` | float | **P4.** Lateral position within the line at the combatant’s current engagement column; bounded; **0** = column center; **biased from wedge seam** where applicable (§4.1–§4.2). Sign convention fixed in code + §4.2. |
| `tactical_penetration_depth` | int | Abstract depth (existing); optional small weight in P4 distance term. |

---

## 6. Tuning

All numeric defaults for cohesion, posture **hysteresis** (**`LINE_COHESION_POSTURE_ENTER_LINE_MIN`** / **`LINE_COHESION_POSTURE_LEAVE_LINE_BELOW`**), discipline shifts, and neighbor hold live in **`combat/CombatConstants.gd`** (`COHESION_*`, `CRASH_NEIGHBOR_*`, `CRASH_AI_POSTURE_*`, wedge / `lane_offset` / `EFF_DIST_*`). Tune by playtest.

---

## 7. Changelog (plan doc only)

- **2026-04-27:** §1–§2.6/§2.8 status (P5 partial, 1.6 partial AI, 2.1 banner partial); §5 `line_discipline` + posture deltas; §6 tuning list; morale explicitly deferred (field 1.0).
- **2026-04-13 (c):** **Wedge-first P4** — new §4.1 wedge (`intrusion_wedge_by_file`), §4.2 lane coupling + distance note, dependency §1 and §2.5 rows, §5–§6; slots described as occupancy only; `breached_files` note on single canonical severity.
- **2026-04-13 (b):** §2.3–§2.4 P3 items → **Done** (mirror `IMPLEMENTATION_ORDER` milestone 1.2).
- **2026-04-13:** Lane metric offset spec (later **§4.2** after wedge renumber); §2.5 rows; §5 `lane_offset` + `intrusion_source_file`; §6 P4 tuning note. Aligns with `IMPLEMENTATION_ORDER.md` Tier 1.3 rework.
- **2026-04-07:** Repo verification pass; §2.0 skirmish/breach clog; posture/role cross-refs to `CombatConstants`; last-verified stamp.
- **Prior revision:** Reordered by dependency chain; checklist replaces ambiguous single table; P0–P2 marked done; P3–P7 explicit; plug taxonomy and data dictionary added.
