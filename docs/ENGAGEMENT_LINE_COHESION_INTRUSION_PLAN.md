# Engagement: line cohesion, posture, intrusion geometry

**Status:** Tier **1** mirrors [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary); cross-tier **Status** → plan [all tiers at a glance](IMPLEMENTATION_ORDER.md#all-tiers-at-a-glance). §2 is a **verification mirror** (edit Tier **1** rows **after** the milestone table).

**Harness names:** [`REGRESSION_HARNESS_MAP_TIER19.md`](REGRESSION_HARNESS_MAP_TIER19.md) only (not listed in §2). **Doc pass:** 2026-05-17 — §2 = verification mirror; spec history → **§7**.

**Plan / code:** Tier 1 **spec** — §1 pointer to master plan dependency chain, §2 verification mirror, §4–§6 plugs / dictionary / tuning. **P-step order, milestone Status, development gates, Tier 3+** → **`IMPLEMENTATION_ORDER.md`** only. **`FEATURE_LINE_CRASH_INTRUSION`** production default **true** (Phase B 2026-05-17).

**Concept stack:** **`slots`** + plugs → **`line_cohesion`** / **`engagement_posture`** → crash / wedge / **`lane_offset`** → **`effective_pair_eff_dist`** → morale → AI (intruder reads via **`formation_id_for_zone_geometry`**). **Modules:** `CombatFormationEngagement`, `CombatIntrusionGeometry`, `BreachResolver`, `CombatEngagementResolver`, `CombatManager`, `FormationBreachRules`, `ui/BattleScene` · `TACTICAL_ZONES_BREACH_MOVEMENT.md` · `CombatConstants.gd`.

---

## 2. Current state checklist

> **Mirror only:** Change **`Status` / Done / Partial / Todo** here **after** updating **`docs/IMPLEMENTATION_ORDER.md`** [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary). These tables are **verification** (what must hold when an item is **Done**), not a second milestone column.

Posture string values **must** match `CombatConstants.ENGAGEMENT_POSTURE_LINE` / `_OPEN` / `_DUEL` (used in formation dict + UI).

### 2.0 Skirmish vs breach clog (formation moves)

| Item | State | Notes |
|------|:-----:|-------|
| `FormationBreachRules.breach_clogs_open_lanes` vs `breach_blocks_open_lane_moves` | **Done** | Raw breach marks vs move lock; skirmish unclegs via `FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES` + `is_skirmish_line_engagement` (`CombatEngagementMode` source). |
| `AvailableActionsBuilder` / `CombatResolveAction` use `breach_blocks_open_lane_moves` | **Done** | Formation moves respect skirmish-aware clog. |
| Engagement mode Option 2 baseline (`duel` cap + `formation` min by active counts) | **Done** | `CombatEngagementMode.snapshot` + `clear_resolved_mode_cache` on `CombatManager.start()`. Harness → registry Tier **1.7–1.8**. |

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
| `CombatIntrusionGeometry.crash_neighbor_hold_support` | **Done** | Adjacent rank-0 allies on **host** line (`formation_id_for_zone_geometry`); weapon reach scale; cap 2. |
| `BreachResolver` adds neighbor hold to defender hold | **Done** | `formation_def` / output fid from defender **host** geometry; global `front_z` + body unchanged. |

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
| `CombatPairGeometry.effective_pair_eff_dist` (+ `CombatDistanceBands` / `AvailableActionsBuilder` forwards) for `CombatConstants.ENGAGEMENT_ROLE_INTRUDED` | **Done** | Wedge + anchor + `lane_offset`; bands use file-spacing equivalent; ZoC host geometry for intruders. |
| Per-formation **`intrusion_wedge_by_file`** | **Done** | Authoritative breach state; stress, cohesion, eff dist, UI corridor strip; §4.1. |
| Per-combatant `lane_offset` (bounded float; default 0) | **Done** | Seam bias + repack on plugs/moves; anchor peer nudge §4.2. |
| Intrusion / plug **repack** rules for `lane_offset` + wedge | **Done** | Wedge cleared on death/reset; offsets repacked in `CombatFormationFlow`. |
| **`lane_stress_by_file` / ZoC** use wedge | **Done** | `TacticalCombat` + `ZoneOfControl` lane stress; intruder host ZoC id for geometry. |
| **Depth-rank polearm + spear lanes (P10)** | **Done** | **`CombatDepthPolearm`** + **`CombatMeleeListing`** + bands cache + **`CombatStrikeStamping`** **`pa`** keys + doctrine AI mults. Plan [§1.9](IMPLEMENTATION_ORDER.md#tier-19--p10-depth-rank-polearm-reach--spear-lanes) · registry bullets **1–4**. |

### 2.6 Cohesion & posture refinement

| Item | State | Notes |
|------|:-----:|-------|
| LINE ↔ OPEN hysteresis (`L_in` > `L_out`) | **Done** | `CombatConstants.LINE_COHESION_POSTURE_ENTER_LINE_MIN` / `LINE_COHESION_POSTURE_LEAVE_LINE_BELOW`; prior `engagement_posture` on formation dict. |
| Encounter / army tags (discipline, default open/line) | **Done** | `encounter`: posture deltas / `line_discipline` / optional `posture_asymmetry_strength`; **morale cohesion** `morale_cohesion_player` / `morale_cohesion_enemy`. Preset: `discipline_posture_*_delta`, `line_discipline`. |
| Per-side asymmetric posture (open army vs line) | **Done** | `CombatFormationEngagement`: two-pass cohesion; `L_in`/`L_out` nudge from `our_coh − opp_coh` (`POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH` + encounter key). |

### 2.7 Morale

| Item | State | Notes |
|------|:-----:|-------|
| Morale system driving `morale_cohesion_factor` | **Done** | **`CombatMoraleCohesion`**: encounter **`morale_cohesion_player`** / **`morale_cohesion_enemy`** or mean of combatant **`morale_cohesion`** (see `CombatManager.register`). |

### 2.8 AI, tests, cross-doc

| Item | State | Notes |
|------|:-----:|-------|
| `CombatAIActionPicker` / `CombatTargetScoring` | **Done** | Intruder-aware geometry; crash + listed-hostile + depth spear × doctrine. Registry Tier **1.6**. |
| `IncursionBreachTest` / neighbor hold | **Optional** | Prefer headless **`run_all()`** for CI. |
| Engagement + telemetry harness | **Done** | Registry Tier **1.7–1.8** · plan [§1.7–1.8](IMPLEMENTATION_ORDER.md#tier-17-18--shipped-maintain). |
| Sync `TACTICAL_ZONES_BREACH_MOVEMENT.md` | **Done** | Phase B 2026-05-17 — live intrusion gate **on**; bundle header + plan Tier **2.1**; long ZoC investigation phases may still lag **`combat/`**. |

---

## 4. Plug taxonomy (spec — P3–P4 **shipped** in code)

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
| **Minimum wedge fields** (v1; extend in code + here when shipped) | `pressure` (float 0..1, breach intensity), `depth` (float 0..1, how far “through” the line), `intruder_id` (int, primary occupant of the breach; **-1** if cleared). Key literals: **`CombatIntrusionWedge.FIELD_*`**. Single-source freeze + range notes: **`CombatConstants.gd`** (Tier **1.3** P4 block above `LANE_OFFSET_*`). Optional: `halfwidth_files` (float, lateral blur for neighbors), `updated_at` (combat clock) for decay. |
| **Writer** | On **crash success**, same tick as slot writes: upsert wedge at **`intrusion_anchor_file`** (and optionally neighbor files scaled by `halfwidth_files`). Initialize from `breach_severity` / existing `breached_files[file]` where practical so one code path owns severity. |
| **Readers (wedge throughout)** | `CombatFormationEngagement` (cohesion), `TacticalCombat._recompute_lane_stress_by_file` (stress from wedge + optional dual), `ZoneOfControl` (if lane stress or frontage uses wedge), `CombatPairGeometry.effective_pair_eff_dist` (via `AvailableActionsBuilder` forward), `CombatDistanceBands`, `BreachResolver` as needed, formation diagram / battle UI (glyph or shading by file). |
| **Clear / decay** | On intruder death, retreat, or scripted breach heal: reduce `pressure`/`depth`, remove key when below epsilon, or clear `intruder_id`; keep **`breached_files`** in sync with wedge/clog rules (parallel summary consumed by **`FormationBreachRules`**, lane stress, **`CombatTargetScoring.opponent_breach_file_targeting_mult`**, and debug). |
| **Invariant** | No consumer should assume “breach = dual living in column only”; **wedge may be non-zero while `slots` show a solo intruder** in depth ranks. |

### 4.2 Lane metric offset (P4 — with `effective_pair_eff_dist`)

**Purpose:** Represent **sub-file** lateral position on the engagement line so reach, crash contests, and distance bands are not limited to integer `|Δfile|` steps. **Topology** (who holds which `slots` cell, vacancy, death) stays on the **rank×file** grid from P3; **`lane_offset` does not introduce gap-column cells** in P4. **Coupling:** on crash success and on wedge update, **bias `lane_offset`** for the intruder (and optionally anchor rank-0 peers) toward the **wedge seam** per §4.1 so combatant metrics stay consistent with formation-level breach geometry.

| Topic | Convention / note |
|-------|-------------------|
| **Range** | **Shipped:** **`CombatConstants.LANE_OFFSET_ABS_MAX`** = **0.5** → clamp **`lane_offset`** to **[-0.5, 0.5]** everywhere (see **`CombatConstants.gd`** Tier **1.3** P4 freeze block). |
| **Meaning of 0** | Fighter’s body is at the **nominal center** of their current `(rank, file)` column for engagement math. |
| **Sign** | **Shipped:** **positive** = toward **increasing file index** (+file neighbor); intruder seam bias **`INTRUSION_INTRUDER_LANE_OFFSET_BIAS`** uses this convention (`CombatFormationFlow`, `CombatPairGeometry.effective_pair_eff_dist`). |
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
| `morale_cohesion_factor` | float | **Tier 1.5.** Refreshed each engagement recompute by **`CombatMoraleCohesion`**; clamped **0.15–1.0**. |
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
| `morale_cohesion` | float 0..1 | **Tier 1.5.** Per fighter; averaged per side into `morale_cohesion_factor` when encounter override absent; optional **`node.morale_cohesion`** at register. |
| `lane_offset` | float | **P4.** Lateral position within the line at the combatant’s current engagement column; bounded; **0** = column center; **biased from wedge seam** where applicable (§4.1–§4.2). Sign convention fixed in code + §4.2. |
| `tactical_penetration_depth` | int | Abstract depth (existing); optional small weight in P4 distance term. |

---

## 6. Tuning

All numeric defaults for cohesion, posture **hysteresis** (**`LINE_COHESION_POSTURE_ENTER_LINE_MIN`** / **`LINE_COHESION_POSTURE_LEAVE_LINE_BELOW`**), **opponent-relative posture coupling** (`POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH`; encounter **`posture_asymmetry_strength`**), discipline shifts, and neighbor hold live in **`combat/CombatConstants.gd`** (`COHESION_*`, `CRASH_NEIGHBOR_*`, `CRASH_AI_POSTURE_*`, wedge / `lane_offset` / `EFF_DIST_*`). Tune by playtest.

---

## 7. Changelog (plan doc only)

- **2026-05-12:** **Docs only** — §1 compressed to pointer + concept stack; §3 removed (duplicate of master plan); §2.8 AI row → plan harness anchor + **`REGRESSION_HARNESS_MAP_TIER19.md`**. **`TACTICAL_ZONES_BREACH_MOVEMENT.md`** / **`TACTICAL_FORMATIONS_FF4.md`** — shorter bundle headers; tactical-zones **Last reviewed** (wording only). **Related** banner → one line.
- **2026-05-11:** §2.5 spear-lane row — **`pa["depth_polearm_lane_type"]`** shipped (parry + **`strike_phys_ctx`**); **`StrikePhysics.depth_polearm_thrust_closing_factor`** uses lane id (**`IMPLEMENTATION_ORDER`** (g)–(h)); banner `Last verified` aligned.
- **2026-05-11 (c):** **`DefenseChoiceResolver._depth_polearm_lane_is_open`** empty-key fix + **`strike_phys_ctx`** **`allows_low`** + **`StrikePhysics`** unknown-lane fallback (**`IMPLEMENTATION_ORDER`** (j)–(k)).
- **Earlier (≤ 2026-05-09):** Plan-focus + **Tier 3** sequencing in **`IMPLEMENTATION_ORDER`** only; **1.9** **Partial** banner; §4 plug title **P3–P4 shipped**; §3 roadmap stub removed **2026-05-12**; wedge-first P4 + P3 **Done** (**2026-04-13**); lane offset spec; morale (**05-06**); §2 status sweeps (**04-27**); verification pass (**04-07**).

---
