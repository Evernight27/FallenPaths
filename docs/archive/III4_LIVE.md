# III-4 engagement geometry (archived detail)

Live stub: [`../LIVE_PATHS.md#iii-4--engagement-geometry-audit`](../LIVE_PATHS.md#iii-4--engagement-geometry-audit).

<a id="iii-4--engagement-geometry-audit"></a>

### III-4 — Engagement geometry audit & bridge (G2 → G1)

**Problem (example):** Border Skirmish **7 party vs 3 enemies** — campaign sets **`player_front_count: 7`** (single rank) and **`formation_doctrine_enemy: pinch_center`**; enemy `default_for_count(3)` → 3-wide front → **Skirmish**. Before **3a nearest-wing**, only center files matched strict offset `floor((7−3)/2)=2`; outer rank-0 files had no mapped opposition → **L4** **`wait`** / **`rotate_file`** loops. **Shipped:** nearest rank-0 hostile by mapped distance (outer party files ↔ outer enemy files) + enemy pinch (same as Escort).

**Symptom breakdown (pre–Track A baseline → shipped):**

| Unit class | Typical slot | Before Track A | Shipped (Track A) | Lever |
|------------|--------------|----------------|-------------------|-------|
| Rank-0 center (e.g. party files 2–4 on 7v3) | strict offset + nearest | melee or close | utility / L3 / close | **3a** mapped opposition |
| Rank-0 wings (e.g. party files 0–1, 5–6 on 7v3) | often LONG, no strict pair | L4 → **`wait`** | **nearest-wing** → file-opposed weight + melee; L4 close when no rank-0 map (**3d**) or envelop mop-up (**3e**) | **3a** + **3d**; **3b** `rotate_file` optional |
| Post-rout mop-up (e.g. 4v1, `wing_lack=false`) | MID/CLOSE band, out of swing reach | **`rotate_file`** / focus loop, **`strikes=0`**, close-only stall | **3e:** suppress rotate without melee; **`attempt_close`** at LONG; at MID/CLOSE list **melee** via **`envelop_mop_up_strike_at_band`** + **`can_melee_threaten`** resolve parity; L4 close when reserve-only; utility pick once strikes list | **3e** (`CombatMeleeListing` + `CombatDoctrine` + picker) |
| Rank-1 (files 0–1) | depth polearm or reserve | wait/focus or thrust lane | L4 or utility | **III-6** depth scheduling ☑ (line plug = Combat maintain) |
| Skirmish compaction | any | slots repacked `0..n-1` | wider side keeps span when outnumbering | **2b** |

**Cognition path:** [#combat-cognition-pipeline](#combat-cognition-pipeline) → L4 when reserve posture only → `_pick_hold_line_action` may **`pick_weighted`** listed **`attempt_close`** when wing lacks mapped opposition + LONG ([#tier-43 L4](#tier-43-mental-stack--combat-attention)). **`rotate_file`** on menu exits L4 → utility pick (**3b**).

**Two tracks** (do not mix flags or stream ownership):

| Track | When | Deliverable | `FEATURE_*` |
|-------|------|-------------|-------------|
| **A — bridge** | Combat maintain (pre–Camp-5 OK) | Mapped opposition, compaction gate, Skirmish **`rotate_file`** exception (**3b**), L4+close (**3d**), campaign preset keys (**3c**) | **None** — harness only ([`PLANNING` policy](PLANNING.md#harness-and-flags)) |
| **B — IV-9** | Expand post–Camp-5 | Gap-column slot topology | `FEATURE_GAP_COLUMN_TOPOLOGY` (one per PR) |

**Model lock:** Each side has **independent** file indices `0..files-1` (`CombatFormationSetup`). There is **no shared slot grid**. Track A uses a **logical opposition offset** seeded at `start()` — not physical “move enemies into player columns.” **`CombatPairGeometry`** keeps raw `|Δfile|` for reach/bands until IV-9 (**I11**).

#### Terminology — footing, guards, stances, and forms {#wf-footing-terminology}

Do **not** conflate these when reading PR slices, harness rows, or UI suffixes. Full attachment model: [#wf-footing-guards-stances](#wf-footing-guards-stances).

| Name in docs / code | Module | What it moves | Attached to | **Not** attached to |
|---------------------|--------|---------------|-------------|---------------------|
| **Formation moves** (plan **3b**) | `CombatFormationMoveListing`, `CombatFormationFlow` | Rank/file reshuffle: `swap_rank`, `rotate_file`, `fall_back`, `flee` | Formation slot / file index | **`weapon_form`**, **`guard_line`**, position-angle offset |
| **Weapon form (L2)** | `CombatWeaponForm`, `assign_form` | Temperament + move-family weights; **home guard** on spawn/switch | **`guard_line`** home via **`GuardLineUpdater.set_guard_from_line`** | Position-angle offset; tier-4.2 spacing mults |
| **Moment guard (L3)** | `guard_line`, `GuardLineUpdater`, D-006 | Blade line after wind-up, parry deflect, hit finish | **Outcomes** + live **`guard_line`** dict field | Legacy **`stance`** string (harness alias only) |
| **Position-angle footwork (Tier 4.4 pilot)** | `CombatFootwork.gd` | **`position_angle_offset_deg`** on exchange | **`attack_line`** (wind-up step), **`guard_line`** (parry step), **body-part line** (dodge step) | **`weapon_form`**, **`stance`**, formation file |
| **Defense tempo “footwork” (III-8 / Tier 4.2)** | `CombatConstants.DEFENSE_*`, feint listing | Spacing + body-state mults on dodge / feint listing | **`distance_to`**, **`STATE_*`**, **`recovery_cause`** (`defense_footwork_recovering_dodge_mult_for_cause`, `AI_FEINT_LISTING_DEFENDER_*`) | Form id; home guard; **`position_angle_offset_deg`** |
| **Formation lane footing (Tier 1 / Phase 5)** | `ZoneOfControl.get_footing_duration_multiplier` | Step-over fallen bodies → **`swap_rank` / `rotate_file` / fall_back** duration mult | Formation file **`slot_obstacles`** column | **`weapon_form`**, **`guard_line`**, PA step, WF layers — grep **`get_lane_and_footing_duration_multiplier`**, not **`CombatFootwork`** |

**Layer label disambiguation:** **`MS-L4`** = mental-stack hold-line reserve posture (`attempt_close` pool) — [#tier-43](#tier-43-mental-stack--combat-attention). **`WF-L4`** = weapon-form move-family weights (four-layer table below). **`Tier 4.4` / PA** = position-angle exchange step — **not** the same as either. **Formation lane footing** = slot obstacle duration only — **not** any of the above. Full map: [#wf-layer-labels](#wf-layer-labels).

**UI suffix order (gauge — shipped):** primary → pick → attention → **position-angle footwork** → flurry → exhaustion → **`Grd`/`Atk` line** (`active_line_for_ui`) → **`Form`**. Diagram cell: **`[guard short]`** then **`[Form]`**; position-angle diagram suffix usually empty (gauge-only arc step).

Track A fixes **wing engagement** via mapped opposition (**3a**), compaction (**2b**), and L4 **`attempt_close`** (**3d**). **`rotate_file`** (**3b**) is optional lateral shuffle polish — not required for the minimum 7v3 wing fix.

#### Shipped constants (reference — do not churn without harness)

| Constant | Value | Effect on 7v3 |
|----------|-------|----------------|
| `FORMATION_MAX_FRONT_FILES_DEFAULT` | 5 | `default_for_count(7)` → 5 front, 2 rear |
| `ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE` | 4 | 3 enemies → raw **Skirmish** (not Formation line) |
| `snapshot_is_true_duel` | `player_active == 1` **and** `enemy_active == 1` | 7v2 / 7v1 mop-up stays **Skirmish**; `rotate_file` when outnumbering files only |
| `can_stay_formation_from_snapshot` | active ≥ `ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE` both sides | 7v5→7v2 drops formation hysteresis → Skirmish tools |
| `AI_ATTRITION_LOW_STANDING_MAX` | 2 | AI attrition offense damp per side only (not mode classifier) |
| `DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES` | 1 | Depth thrust uses **raw** Δfile (unchanged Track A) |
| `CLOSE_SLOTS_PER_TARGET` | 3 (+ tight bonus) | Wings can share close slots on same defender |
| `DOCTRINE_PINCH_INWARD_BIAS_PER_FILE` | 0.18 | Weight-only pinch today; Escort enemy doctrine only |

**Track A constant (PR 3b ☑):** `SKIRMISH_ROTATE_OUTNUMBER_FILE_MARGIN` — minimum `player_files - enemy_files` before Skirmish allows **`rotate_file`** only (prefer exception over lowering `ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE`). **`swap_rank`**, **`drag_back`**, and **`fall_back`** stay **Formation-mode only** — they need `formation_ranks > 1` and stable line; Skirmish 7v3 does not widen those gates in Track A.

#### Formation moves — shipped execution (read before **3b**)

**Listing order** (`AvailableActionsBuilder.build`): `CombatMeleeListing` first, then `CombatFormationMoveListing.append_formation_move_actions` (same `zone_geometry_line_context` cache per combatant).

**Policy gate (shipped):** `allow_swap_rank`, `allow_drag_back`, and `allow_fall_back` require **Formation** mode. **`rotate_file`** uses **`allow_rotate_file_for_formation(manager, formation_id)`** — Formation always; Skirmish when that side outnumbers (**3b**). Listing + resolve both call the helper (not raw `movement_policy` alone).

**Dual gate:** `CombatResolveAction` re-checks the same rotate helper at commit — listing alone is insufficient.

| Move | Listing rules (summary) | Skirmish outnumber (shipped) |
|------|-------------------------|------------------------------|
| `rotate_file` | rank 0, `files >= 2`, adjacent same-rank ally, not in cooldown | **Listed** when `our_files > opp_files + margin` (**3b**) |
| `swap_rank` / `drag_back` | `formation_ranks > 1`, partner fitness | **Not listed** (Formation only) |
| `fall_back` | loose discipline + empty rear, or cowering | **Not listed** |
| `flee` | `CombatFormationFlee.flee_action_legal` | Can list |

**After resolve** (`CombatFormationFlow`): formation moves swap rank/file indices, call `repack_lane_offset_after_rank_file_change` (lane offset → column center), then **`manager._recompute_zoc_and_distance()`** + `notify_formation_changed`. This is **contiguous-grid shuffle**, not gap-column envelopment (IV-9).

**AI weights (unchanged by Track A):** `CombatAIActionPicker` — `rotate_file` fixed **0.55** (× blocked-lane mult); `attempt_close` uses full **`hostile_pair_targeting_weight_mult`** when utility pick runs. **3b** only opens the menu; it does not retune weights.

#### Recompute pipeline (authoritative order)

```text
CombatManager.start()
  → CombatFormationSetup.build_formations_and_assign_slots
  → EngagementOpposition.seed_from_formations
  → mark_all_formations_vacancy_dirty
  → seed doctrine / encounter overlays
  → _reset_tactical_engagement_state (cohesion only — **not** full ZoC/bands)
  → vacancy_reconcile_pass(false) + _recompute_zoc_and_distance()  (**III-4 PR2 ☑**)

First geometry refresh (if not already at start):
  → CombatProcessTick frame 1: vacancy_reconcile_pass → [if changed_fids] _recompute_zoc_and_distance
  → or get_available_actions: mark_all dirty → vacancy_reconcile_pass → build()

get_available_actions (every turn list)
  → mark_all_formations_vacancy_dirty → vacancy_reconcile_pass → AvailableActionsBuilder.build

notify_formation_changed / CombatFormationFlow resolves (rotate, swap, drag, flee step)
  → vacancy_reconcile_pass and/or direct manager._recompute_zoc_and_distance

_recompute_zoc_and_distance:
  TacticalCombat.recompute_incursion_pressure
  → ZoneOfControl.recompute_all
  → CombatDistanceBands.update_distance_to_from_formations
  → CombatFormationEngagement.recompute_all  (+ evaluate_automatic_doctrine / pinch pilot)
```

**Turn-1 note:** empty `distance_to` defaults to **LONG** (`CombatantEntityAccess.distance_to_opponent_band`) — wings can list `attempt_close` before first recompute; pair reach still uses live `CombatPairGeometry` in listing.

**`attempt_close` resolve (shipped — Track A does not change):** `CombatEngagementResolver.resolve_close_attempt` — pressure vs evasion roll; on success writes **`distance_to` = CLOSE** inline for the pair. It does **not** call `_recompute_zoc_and_distance` (tactical band patch only). Melee listing on later turns still uses live `CombatPairGeometry` + updated band.

**Track A PR2 option (shipped ☑):** after opposition seed in `start()`, `vacancy_reconcile_pass(false)` then `_recompute_zoc_and_distance()` once before first `EVENT_ACTION_READY`.

**Listing invariant (I0):** Turn menus see slot placement **after** the latest vacancy reconcile on that path. ZoC/bands need not rerun if reconcile changed nothing — intentional.

#### Invariants (audit checklist)

| ID | Invariant |
|----|-----------|
| **I0** | Listing runs after vacancy reconcile on `get_available_actions` / tick paths |
| **I1** | Symmetric distance bands: if A sees B at band X, B sees A at X (existing tier-1 rows) |
| **I2** | `attempt_close` listed only at LONG + free close slot (`CombatMeleeListing`) |
| **I3** | Stamped `pa` pair geometry matches live pair at strike time |
| **I4** | Mapped opposition drives `is_melee_file_opposed_priority` / `wing_lacks_*` consistently (tier-1 pinch rows stay valid or fixtures updated) |
| **I5** | Depth polearm lateral thrust gate still uses raw Δfile until IV-9 (**I11**) |
| **I6** | Formation-move resolves call `_recompute_zoc_and_distance` even when vacancy reconcile returns empty |
| **I7** | Dual occupancy during adjacent-rank moves unchanged unless IV-9 doc says otherwise |
| **I8** | Skirmish wide line: when `player_files > enemy_files`, compaction must not collapse intentional frontage (**2b**) |
| **I9** | `CombatEngagementMode.snapshot` ↔ `TacticalCombat` mode telemetry aligned |
| **I10** | Opposition kind stamped on strike when calibration paths need it |
| **I11** | **Opposition mapping ≠ pair spacing** until IV-9 unifies column topology |

#### G2 consumer audit (functions → primary callers)

| Function / policy | Module | Consumers (non-exhaustive) | Track A touch |
|-------------------|--------|----------------------------|---------------|
| `is_file_opposed_rank0_pair` | `CombatTargetScoring` | `is_melee_file_opposed_priority`, `wing_lacks_file_opposed`, `pinch_score_mult`, `ordered_melee_opponents` | **→ EngagementOpposition** |
| `is_melee_file_opposed_priority` | `CombatTargetScoring` | `file_opposed_mult`, `hold_lane_mult`, `hostile_pair_targeting_weight_mult`, `ordered_melee_opponents` sort | **3a** delegate |
| `file_opposed_mult` / `hold_lane_mult` | `CombatTargetScoring` | `hostile_pair_targeting_weight_mult` → `CombatAIActionPicker._get_action_weight` | **3a** fixtures |
| `hostile_pair_targeting_weight_mult` | `CombatTargetScoring` | `CombatAIActionPicker`, `CombatDebug` targeting trace | **3a** verify weights |
| `pinch_score_mult` | `CombatTargetScoring` | `hostile_pair_targeting_weight_mult`, depth-spear AI mults | tier-1 compat |
| `soft_geometry_score` | `CombatTargetScoring` | `hostile_pair_targeting_weight_mult` | **no change** (uses `eff_dist`) |
| `engagement_mode_targeting_mult` | `CombatTargetScoring` | `hostile_pair_targeting_weight_mult`, AI pick cache | verify Skirmish 7v3 |
| `effective_pair_geometry` / `cached_eff_dist` | `CombatPairGeometry` | `CombatMeleeListing`, `CombatDistanceBands`, `CombatStrikeStamping`, `AttackResolver`, `ZoneOfControl` parry flank | **No change** Track A |
| `can_melee_threaten` | `CombatMeleeListing` | `CombatDistanceBands`, `AttackResolver` resolve gate, `TacticalCombat` surround scan, tier-1 depth rows | verify after bands stable |
| `mid_reach_files` / parry flank spacing | `ZoneOfControl` | `CombatDistanceBands`, flank parry mod (`PARRY_FLANK_EFFECTIVE_FILES_MIN`) | verify only (raw Δfile) |
| `movement_policy` | `CombatEngagementMode` | `CombatFormationMoveListing`, **`CombatResolveAction`** (resolve-time reject) | **3b** outnumber exception |
| `compact_native_line_files_if_thinned` | `CombatFormationVacancyPlugs` | every `reconcile_vacancy_plugs` pass | **2b** gate |
| `repack_lane_offset_after_rank_file_change` | `CombatFormationFlow`, `CombatFormationVacancyPlugs` | after plug / rotate / swap writes | verify only |
| `action_list_is_reserve_posture_only` | `CombatListedActions` | `MentalStackDecider` L4 trigger | doc + **3d** pick |
| `action_list_is_hold_line_only` | `CombatListedActions` | harness / UI hints only (**not** L4 trigger) | doc clarity |
| `_filter_hold_line_actions` | `MentalStackDecider` | L4 pick pool | **3d** add `attempt_close` branch |
| `attempt_close_listed_for_pair` | `CombatMeleeListing` | listing + `CombatAIActionPicker` weight zero at non-LONG | verify after **3a** |
| `zone_geometry_line_context*` | `ZoneOfControl` | listing sort cache (`AvailableActionsBuilder`, `CombatAIActionPicker`, `CombatDebug`) | verify cache invalidation on reconcile |
| `evaluate_automatic_doctrine` | `CombatDoctrine` | `CombatFormationEngagement.recompute_all` (hollow center only) | **p4c** (not Track A) |
| `enemy_line_hollow_center_for_pinch` | `CombatDoctrine` | auto-pinch pilot; uses rank-0 **raw** files on zone geometry fid | **p4c** |
| `refresh_party_formation_meta` | `CampaignEncounterBridge` | every `prepare_combat_from_encounter` | **3c** merge preset keys |

**Numeric superiority auto-pinch** (outnumber without hollow center) is **p4c**, not Track A — do not fold into **3a**.

#### Root-cause stack (7v3 Border Skirmish)

| Priority | Gate | Module | Track A fix |
|:--------:|------|--------|-------------|
| 1 | Skirmish file compaction | `CombatFormationVacancyPlugs._should_compact_native_line_files` (Skirmish → always pack `0..n-1`) | **2b:** skip when outnumbering |
| 2 | L4 ignores `attempt_close` | `MentalStackDecider._filter_hold_line_actions` | **3d:** pick close when reserve-only + wing lacks mapped opposition + LONG |
| 3 | Same-index file opposition | `CombatTargetScoring.is_file_opposed_rank0_pair` | **3a:** `EngagementOpposition` mapped offset + nearest wing |
| 4 | Skirmish **`rotate_file`** when outnumbering | `allow_rotate_file_for_formation` (**3b** ☑) |
| 4b | Post-rout **`rotate_file`** loop (4v1, no melee) | `should_suppress_skirmish_rotate_file` (melee-only; close-only still suppresses) + `CombatFormationMoveListing` | **3e** ☑ |
| 4c | Band/reach gap (MID/CLOSE, no geometric reach) | `CombatMeleeListing.envelop_mop_up_strike_at_band` + `can_melee_threaten`; `CombatEngagementResolver` close at LONG or **`envelop_close_allowed`** | **3e** ☑ |
| 4d | Pincer roles unwired | `CombatDoctrine` pincer APIs → `on_combat_commitment`, `pincer_preferred_flank_target_mult` | **3e** ☑ |
| 5 | 5-wide default front | `FormationPreset.default_for_count` / bridge refresh | **3c:** encounter `player_front_count` or `for_front_count(7,7)` |
| 6 | Pinch weight only | `CombatDoctrine` (hollow center auto-pinch) | **p4c** — not Track A |
| 7 | Contiguous columns only | `FormationSlots` | **IV-9** Track B |

**Logical opposition (Track A 3a):** at `start()`, `offset = floor((player_files - enemy_files) / 2)`. Center pairs: `actor.file == opp.file + offset` (direction-aware). Wings: nearest living rank-0 enemy by `|actor.file - (opp.file + offset)|`. **`CombatPairGeometry`** unchanged in Track A.

**Storage contract (PR 2):** seed on manager after formation build — e.g. meta `_opposition_file_offset_by_side: { "player": int, "enemy": int }` (enemy offset = negation of player offset for symmetric queries). `EngagementOpposition.opposition_file_offset(manager, side)` is the only reader; do not scatter width math in consumers.

#### L4 reserve posture — listing vs pick (Track A 3d spec)

**Reserve posture definition** (`CombatListedActions.is_reserve_posture_listing_move_id`): `wait`, focus-line moves, **`attempt_close`**. Anything else — melee, medical, **`rotate_file`**, swap, flee, … — breaks reserve posture.

| Stage | Shipped behavior |
|-------|------------------|
| L4 **trigger** | `action_list_is_reserve_posture_only` — every listed move ∈ {wait, focus, `attempt_close`} |
| L4 **pick pool** | `_filter_hold_line_actions` + listed **`attempt_close`** when `CombatDoctrine.hold_line_close_pick_eligible` (wing lacks map, pincer flank, or **3e** mop-up) |
| Pick order inside L4 | **3e** mop-up (reserve-only): **`pick_weighted`** close when eligible (beats focus) — **LONG band only** in utility weights; MID/CLOSE close weight **0** (finish with listed strikes). Else: 1) focus if incoming telegraph needs retarget 2) close when eligible + LONG 3) else **`wait`** |
| Harness | `_run_mental_stack_hold_line_only_picks_focus_or_wait` + `_run_mental_stack_hold_line_attempt_close_wing` + `_run_mental_stack_hold_line_attempt_close_mop_up` + `_run_mental_stack_close_beats_focus_mop_up_under_telegraph` + `_run_envelop_melee_strike_listed_close_mop_up_reach_gap` + `_run_attempt_close_ai_weight_mid_mop_up` (LONG boost / MID zero) |

Utility **`pick_weighted`** still applies `_get_action_weight` for `attempt_close` when L4 does not fire (center files with melee listed, or any menu that is not reserve-only).

#### L4 ↔ **3b** interaction (mental stack)

**3d** and **3b** share the same L4 trigger but behave differently once both ship:

| Wing menu (after Track A slices) | `reserve_posture_only`? | Pick layer for `attempt_close` / `rotate_file` |
|----------------------------------|-------------------------|------------------------------------------------|
| wait + focus + close only (**3d**, no **3b**) | **Yes** | **L4** — `pick_weighted` on close pool |
| wait + focus + close + **`rotate_file`** (**3d** + **3b**) | **No** — `rotate_file` ∉ reserve posture | **Utility** — `pick_weighted` on full menu; close vs rotate compete via `_get_action_weight` |
| center file: melee + … | **No** | **Utility** (unchanged) |

**Implementation order implication:** ship **3d (PR7) before or without 3b (PR5)** for Border Skirmish wing fix. **3b** is polish for lateral shuffle after wings already close/melee; it is **not** in the minimum slice. Do **not** add `rotate_file` to `is_reserve_posture_listing_move_id` — that would keep L4 firing and hide rotate from utility competition.

**F5 / hints:** when **3b** lists rotate on a wing, gauge may show utility pick (`Stack` cleared) rather than `Stack hold_line` — expected; soak greps in PR8 must allow both patterns.

#### Module plan

| Module | Role |
|--------|------|
| **`EngagementOpposition.gd`** ☑ | Offset seed, `is_mapped_file_opposed`, `wing_lacks_mapped_opposition` |
| **`CombatTargetScoring.gd`** ☑ | Delegate opposition + `wing_lacks_file_opposed` when meta seeded |
| **`CombatPairGeometry.gd`** | Raw spacing Track A; column graph Track B |
| **`CombatFormationVacancyPlugs.gd`** ☑ | Compaction gate (**2b**); IV-9 disables gap-mode compaction |
| **`CombatEngagementMode.gd`** ☑ | Skirmish outnumber **`rotate_file`** via `allow_rotate_file_for_formation` |
| **`MentalStackDecider.gd`** ☑ | L4+close (**3d**) + **3e** `hold_line_close_pick_eligible` |
| **`CombatDoctrine.gd`** ☑ (**3e**) | `envelop_mop_up_active`, `envelop_close_allowed`, rotate suppress, pincer role + wing commit propagation |
| **`CombatFormationMoveListing.gd`** ☑ (**3e**) | Gate `rotate_file` when `should_suppress_skirmish_rotate_file` |
| **`CombatResolveAction.gd`** ☑ (**3e**) | Resolve-time `rotate_file` reject when mop-up suppress active (listing parity) |
| **`CombatEngagementResolver.gd`** ☑ (**3e**) | Resolve close at MID/CLOSE when `envelop_close_allowed` (listing parity) |
| **`CombatMeleeListing.gd`** ☑ (**3e**) | `envelop_mop_up_strike_at_band` — list strikes + `can_melee_threaten` at MID/CLOSE during mop-up when band/reach gap |
| **`CombatPlayerTurnHints.gd`** ☑ | Wing hint (**3d**); **3e** mop-up hint (“finish the last enemy; close in or strike.”) |
| **`CombatAIActionPicker.gd`** ☑ (**3e**) | Mop-up damp `rotate_file` + focus-line; boost listed **`attempt_close`** at **LONG** only (`ENVELOP_MOP_UP_CLOSE_AI_WEIGHT_MULT`); weight **0** at MID/CLOSE during mop-up (strike finish) |

Do **not** add a monolithic `EngagementGeometry.gd` facade unless IV-9 forces it; prefer smallest owner per [`AGENTS_ENTRY`](AGENTS_ENTRY.md).

#### Secondary consumers (verify Track A — usually no code change)

| Area | Module | Why it matters |
|------|--------|----------------|
| **Pick entry** | `TurnReadyHandler`, `CombatEventDispatch` | Both call `CombatAIActionPicker.pick` after listing — no geometry logic, but F5 traces pass through |
| **Listing cache** | `AvailableActionsBuilder` | Builds one `zone_geometry_line_context` per combatant per list pass |
| **Resolve gate** | `CombatResolveAction` | Re-checks `movement_policy` for `rotate_file` / swap / drag at commit time (**3b** must match listing) |
| **Strike path** | `AttackResolver`, `CombatStrikeStamping` | Stamps `effective_pair_*` from live pair geometry; `can_melee_threaten` abort |
| **Surround / incursion** | `TacticalCombat`, `CombatSurroundArcOccupancy`, `AttackResolver` | Threat scan uses **`can_melee_threaten`** + arc occupancy — flank **pressure**, not opposition mapping |
| **Cohesion / posture** | `CombatFormationEngagement`, `CombatMoraleCohesion` | `front_fill`, `lane_stress_by_file`, posture thresholds on recompute — width affects fill ratio |
| **Depth lane** | `CombatDepthPolearm`, `CombatMeleeRankTargeting` | `depth_polearm_valid_line_threat`, same-file rank-0 ally — uses **raw** file + home fid |
| **Retreat gate** | `CombatMobilityRetreat` | `formation_retreat_only_for` skips melee listing entirely |
| **Scheduler** | `CombatEventScheduler` | Back-rank `action_ready` bump after vacancy; reads `zone_geometry_for_combatant` |
| **Lane stress** | `CombatFormationEngagement._avg_lane_stress` | Per-file `lane_stress_by_file` nested dict — IV-9 gap columns affect keys |
| **UI diagram** | `FormationDiagramBuilder`, `FormationLayoutBuilder`, `BattleUILayout` | Render **raw** rank/file from combatants; wings show empty cells correctly today |
| **F5 / Q4** | `CombatF5SoakTrace`, `scripts/run_q_track_audits.gd` | `tooltip_hold_line`, `turn_ready_formation_line`, Q4 **ii8** `diagram_banner` — update PR7/8 for close copy |
| **Debug** | `CombatDebug` | Targeting trace mirrors listing sort + pair geometry |

#### Explicitly out of scope (Track A)

| Item | Reason |
|------|--------|
| `CombatFootwork.gd` / position-angle pilot | Tier 4.4 deferred — not formation file movement |
| `CombatPairGeometry` / band math | I11 — wings stay LONG until IV-9 |
| Skirmish **`swap_rank` / `drag_back` / `fall_back`** | Need Formation stable line + ranks; **3b** is **`rotate_file` only** |
| `ZoneOfControl.mid_reach_files` retune | Layered tuning; verify only |
| Surround sector / arc occupancy retune | III-1 / D-005 — separate track |
| `PassiveParryContext` / `DefenseChoiceResolver` guard matrix | III-2 / IV-4 — flank **defense** not position |
| `CombatDoctrine` numeric-superiority auto-pinch | **p4c** Expand playbook |
| `FormationLayoutBuilder` grid reparent | Optional layout; not battle logic |
| `CombatEngagementResolver` close contest math | **3e** adds MID/CLOSE band gate only; contest math unchanged |
| Player per-target UI | Design lock — [`SHIP_PLAN` §9b](SHIP_PLAN.md#combat-mental-stack-shipped) |

#### Integration surfaces (by layer)

| Layer | Files |
|-------|-------|
| **Authority** | `FormationSlots`, `CombatFormationSetup`, `CombatFormationVacancyPlugs`, `CombatFormationFlow`, `CombatFormationFlee`, `CombatFormationRout`, `CombatManager`, `CombatantEntityAccess`, `FormationPreset`, `CombatFormationMoveDuration` |
| **Geometry** | `ZoneOfControl`, `CombatPairGeometry`, `CombatDistanceBands`, `TacticalCombat`, `CombatFormationEngagement`, `CombatMoraleCohesion`, `CombatEngagementMode`, `CombatConstants` |
| **Listing** | `CombatMeleeListing`, `CombatMeleeRankTargeting`, `CombatDepthPolearm`, `CombatFormationMoveListing`, `AvailableActionsBuilder`, `CombatListedActions`, `CombatMobilityRetreat` |
| **Cognition** | `CombatTargetScoring`, `CombatAIActionPicker`, `MentalStackDecider`, `CombatDoctrine`, `TurnReadyHandler`, `CombatEventDispatch` |
| **Resolution** | `CombatEngagementResolver`, `CombatResolveAction`, `AttackResolver`, `DefenseChoiceResolver`, `CombatStrikeStamping`, `CombatSurroundArcOccupancy`, `weapon/StrikeRealismProfile` |
| **Tick / schedule** | `CombatProcessTick`, `CombatManager.get_available_actions`, `CombatEventScheduler`, `AttackWindUpStarter`, `CounterTempo` (III-6 depth recheck — **Partial ☑**) |
| **UI / telemetry** | `FormationDiagramBuilder`, `FormationLayoutBuilder`, `BattleUILayout`, `BattleScene`, `CombatCombatantsSnapshot`, `CombatDebug`, `CombatF5SoakTrace`, `CombatPlayerTurnHints`, `CombatUiHints` |
| **Campaign (3c — Campaign leads)** | `PartySetup`, `CampaignEncounterBridge`, `ContractSpawner`, `CombatFlow`, `EncounterNode`, `SoakEncounterPresets` |
| **Harness / audits** | `CombatRegressionHarnessTier1Tail`, `CombatRegressionHarness`, `CombatRegressionHarnessAttentionFootworkTail`, `CombatRegressionHarnessFeintTempoTail`, `CombatRegressionHarnessMedicalMobilityTail` (`movement_policy`), `CombatD001SoakRunner`, `scripts/run_company_state_checks.gd`, `scripts/run_q_track_audits.gd` (Q4 ii8), vacancy / formation-move tails |

Shared files **`CampaignEncounterBridge.gd`**, **`CombatFlow.gd`**: Campaign stream owns Track A **3c**; Combat owns opposition + stack.

#### Track A — PR sequence (harness gate each)

**Hard order:** **PR3 (2b compaction) before PR4 (3a opposition)** — else mapped file span is undone every reconcile. PR2 (offset scaffold) can land with PR3 or PR4.

**Recommended player-visible order:** **PR3 → PR4 → PR7** (minimum slice) **before PR5 (3b)**. **3d** fixes wing `wait` via L4+close; **3b** only matters once wings have non-reserve menus or you want lateral shuffle — shipping **3b** before **3d** does not fix the primary 7v3 symptom.

| PR | Slice | Owner | Harness / soak |
|----|-------|-------|----------------|
| 1 | This section + consumer table (doc) | Combat | — |
| 2 | `EngagementOpposition.gd` + offset meta seed in setup/`start` | Combat | `_run_opposition_offset_seeded_at_start` ☑ |
| 3 | Skirmish compaction gate (**2b**) | Combat | `_run_geometry_skirmish_wide_line_no_compact` ☑ |
| 4 | Mapped opposition delegate (**3a**) | Combat | tier-1 pinch/file-opposed compat (~39 rows in `Tier1Tail`) ☑ |
| 5 | Skirmish outnumber **`rotate_file` only** (**3b**) — optional after PR7 | Combat | `_run_skirmish_outnumber_allows_rotate_file` ☑ |
| 6 | Campaign preset keys + bridge merge (**3c**) | **Campaign** | `_run_camp_3_player_front_count_encounter` ☑ |
| 7 | L4+close + [§9b](SHIP_PLAN.md#combat-mental-stack-shipped) + hints (**3d**) | Combat | `AttentionFootworkTail._run_mental_stack_hold_line_attempt_close_wing` ☑ |
| 8 | Soak preset + acceptance (**ii_envelop**) | Combat + Playtest | D001 `_run_ii_envelop` ☑ |
| 9 | Post-rout mop-up + pincer wire (**3e**) | Combat | `_run_envelop_mop_up_*`, `_run_pincer_*`, `AttentionFootworkTail._run_mental_stack_hold_line_attempt_close_mop_up` ☑ |

**Soak (PR 8):** add `SoakEncounterPresets` preset **`ii_envelop`** — 7 living party vs 3 enemies, `WORLD_META_LOCK_PARTY_FORMATION` or explicit `{files:7,ranks:1}` / `player_front_count: 7`; F5 hint line per existing soak pattern. Headless: extend `CombatD001SoakRunner` or tier harness with outnumber fixture.

**F5 grep targets (PR 7–8):** `Stack hold_line`, `pick move_id=attempt_close`, `turn_ready_formation_line`, `gauge_tooltip_formation`, `tooltip_match=hold_line` (extend for close copy), `note_formation_move_pick rotate_file` when **3b** on.

**F5 grep targets (PR 9 / 3e):** `engagement_debug turn` with `mop_up=true`, `rotate_suppress=true`, `pick=attempt_close`; tail should not show long `rotate=1 strikes=0` loops on last enemy.

#### Pre-integration checklist (Track A — historical; all items ☑)

**Minimum player-visible slice (no campaign):** PR **3 → 4 → 7** (+ PR2 offset). Skips **3b** rotate and **3c** wider preset; still fixes wing wait on 5×2 vs 3 with default Border Skirmish.

| # | Item | Spec |
|---|------|------|
| 1 | **`EngagementOpposition` API** | `seed_from_formations(manager)` · `opposition_file_offset(manager, side)` · `is_mapped_file_opposed(manager, actor, opp)` · `wing_lacks_mapped_opposition(...)` (wraps rank-0 ref + depth lane like today) · delegate `CombatTargetScoring.is_file_opposed_rank0_pair` only |
| 2 | **Offset math** | `offset_player = floor((player_files - enemy_files) / 2)`; player rank-0 opposed to enemy rank-0 when `player.file == enemy.file + offset_player`; symmetric check from enemy POV with `-offset_player`. **Equal width → offset 0** (backward compatible). |
| 3 | **Meta lifecycle** | Seed after `build_formations_and_assign_slots`; **`CombatManager.stop()`** + **`start()`** clear opposition meta (mirror telemetry meta pattern). |
| 4 | **Compaction 2b (asymmetric)** | In Skirmish, skip `compact_native_line_files_if_thinned` for formation **fid** only when **`our_files > opposing_side_files`** (compare `formations[fid].files` vs opponent formation record). Narrower side may still compact. |
| 5 | **L4 close target (3d)** | Filter listed `attempt_close` into pick pool; use **`CombatAIActionPicker.pick_weighted`** on that pool (same targeting weights as utility) — not arbitrary first entry. Gate: `wing_lacks_mapped_opposition` + LONG band (reuse listing band check). |
| 6 | **Campaign 3c merge order** | `prepare_combat_from_encounter`: apply `ENCOUNTER_KEY_PLAYER_*` → **`world.party_formation` meta** before/alinstead of blind `refresh_party_formation_meta` default. **`CombatFlow`** / **`BattleScene`** read meta — encounter dict alone does not widen preset unless bridge copies it. |
| 7 | **`for_front_count` clamp** | `FormationPreset.for_front_count(n, front)` already clamps `files = mini(front, n)` — document in contract spawn, do not assume 7-wide with &lt;7 living fighters. |
| 8 | **Harness wiring** | Register new `_run_*` in `CombatRegressionHarnessTier1Tail` and/or `AttentionFootworkTail`; invoked from `CombatRegressionHarness.gd` `run_early` / `run` / `run_mid` as appropriate. |
| 9 | **Bootstrap recompute (PR2)** | Consider one-shot `_recompute_zoc_and_distance()` at end of `start()` after offset seed — avoids frame-1 Skirmish compaction racing first listing. |
| 10 | **Gate every PR** | `.\scripts\run_all_combat_checks.ps1` → **PHASE0: PASS**; tier-1 pinch/file-opposed rows green after PR4. |
| 11 | **3b scope** | Skirmish exception for **`allow_rotate_file` only** — update `movement_policy` (or shared helper) consumed by **`CombatFormationMoveListing`** and **`CombatResolveAction`**. Do not widen `allow_swap_rank` / `allow_drag_back` / `allow_fall_back` in Skirmish. |
| 12 | **L4 vs 3b** | Do not classify `rotate_file` as reserve posture. With **3b** on, wing menus leave L4 → utility pick handles close vs rotate. Test both **3d-only** and **3d+3b** in harness / F5. |
| 13 | **Close resolve** | **3d** pick-only; **3e** adds MID/CLOSE band gate in `CombatEngagementResolver` when `envelop_close_allowed` — contest math unchanged. |

**Do not implement yet (Track B / other rows):** gap columns · MS-L5 plug layer · lower `ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE` · shared-grid slot moves · `CombatFootwork` tier 4.4 expansion.

#### Track B — IV-9 (post–Camp-5)

| Mode | `file` meaning | Compaction | Opposition |
|------|----------------|------------|------------|
| **Legacy** (flag off) | Contiguous column index | Skirmish packs unless **I8** gate | Mapped (Track A) or same-file |
| **Gap-column** (flag on) | Column id with intentional gaps | **Off** or gap-aware | Reach graph / column arc |

**IV-9 blockers to design first:** (1) disable `compact_native_line_files_if_thinned` in gap mode; (2) preserve vacancy reconcile loop + dual occupancy (`_run_vacancy_reconcile_*`). **MS-L5** plug cognition stays Expand — not Track A. **III-2** guard lines: flank path + zone fidelity ☑ (**IV-4/5/6**) — not a Track A blocker.

**Dependencies:** IV-1 → IV-2 → IV-3; III-2 → IV-4/5; IV-7 → IV-8; **IV-9 last** (highest risk). Track A **does not** require IV-9.

**Track B sketch (Expand — one `FEATURE_*` per PR):** design doc → flag default off → gap `FormationSlots` + compaction off → setup/plugs/flow → pair geometry column graph → listing/bands → UI diagram gaps → dual-mode harness parity (all formation-move + tier-1 targeting with flag on/off).

#### F5 acceptance (Border Skirmish — optional manual; headless `[ii_envelop]` ☑)

| Check | Pass criterion |
|-------|----------------|
| Mode line | `mode=Skirmish`, `player_front` ≥ 5 (7 with Border Skirmish template), `enemy_front=3` |
| Wing activity | Outer rank-0: **`Stack hold_line`**, **`attempt_close@`**, and/or **`rotate_file@`** (not 100% idle **`wait`**) |
| Center | Rank-0 center files: melee or close vs mapped opponents |
| Hits / doctrine | Grep **`hit_resolve `** · **`engagement_debug`** (fight_start rank0_map + turn lines for reserve_only/rotate/close) · enemy **`pinch_center`** on one **`diagram_banner enemy:`** row |
| Regression | `run_all_combat_checks.ps1` → **PHASE0: PASS** + `[ii_envelop] pass=true` + **`ii_envelop_hit`** + **`ii_envelop_mopup: PASS`** (`mop_up=true`) |
| **3e mop-up tail (combat phase)** | While last enemy standing: `engagement_debug turn` with `mop_up=true`, `rotate_suppress=true`, **`menu=strikes_listed`** and **`strikes>0`** (or utility pick = melee, not endless `attempt_close`). **Fail:** long runs of `menu=reserve_only` + `strikes=0` + `pick=attempt_close`. Post-victory **medical** may also show `mop_up=true` with strikes listed — that is triage, not the combat stall class. Optional gauge **`Mop-up`** hint · `validate_f5_soak_log.ps1`: **`ii_envelop_mopup`** / **`ii_envelop_mopup_rotate_suppress`** / optional **`camp_mopup_strike_finish`** |
| L4 telegraph | `_run_mental_stack_hold_line_only_picks_focus_or_wait` + `_run_mental_stack_hold_line_attempt_close_wing` + `_run_mental_stack_close_beats_focus_mop_up_under_telegraph` |
| Optional Q | Camp-3.4 `[Stack]` lines show reduced idle-wait ratio vs pre-Track-A baseline |

### P4 playbooks — expansion backlog ([`#expansion-backlog-p4-playbooks`](#expansion-backlog-p4-playbooks))

| ID | Tier anchor | Intent | Modules / notes |
|----|-------------|--------|-----------------|
| **p4a** | [7.2 / exhaustion](#d-004-exhaustion) | **☑ 2026-06-08** — tunnel 0.50 + offense damp ramp | `CombatExhaustion`, **ii4d** |
| **p4b** | [0.1 formation duration](#tier-01-formation-move-duration-ui) | **☑ 2026-06-08** — Formation duration UI copy polish | **`p4b_formation_duration_ui_copy_line`** · **`_run_p4b_formation_duration_ui_copy_suite`** · **ii5a** |
| **p4c** | [1.10 auto doctrine](#p4c--tier-110-automatic-doctrine-pilot) | **☑ 2026-06-08** — **`numeric_superiority_for_pinch`** + hollow center · **`_run_p4c_numeric_superiority_auto_pinch`** — **not** III-4 Track A | `CombatDoctrine`, `CombatFormationEngagement` |
| **p4d** | [3.2 parry/bind](#tier-32-parry-bind-deflect) | **☑ 2026-06-08** — Doc ↔ code sync for bind/deflect | **`p4d_parry_bind_doc_sync_line`** · **`_run_p4d_parry_bind_doc_code_parity_suite`** · calibration audit + **ii2b** |
| **p4e** | [4.2b feint](#tier-42-feint-d-telegraph-ai) | **☑ 2026-06-08** — Feint listing ↔ reveal progress parity | `CombatAIActionPicker` · `DefenseChoiceResolver._feint_readiness_reveal_mult` · **`_run_feint_move_listing_reveal_progress_dampens_early_wind_up`** |
| **p4f** | [6.2 flee](#tier-62-dedicated-flee-formation-action) | **☑ 2026-06-08** — Dedicated **flee** formation action UX + AI | `CombatFormationFlee`, `CombatFormationRout` · **`CombatRegressionHarnessFleeTail`** |
| **p4g** | [4.5 flurry](#tier-45-flurry-bind-exchange-deferred) | **☑ 2026-06-08** — Bind-exchange flurry depth (flag **on**) | `CombatFlurryBind` · **`_run_p4g_flurry_bind_depth_suite`** + existing **`_run_flurry_bind_*`** |
| **p4h** | [3.2 bind riposte](#tier-32-parry-bind-deflect) | **☑ 2026-06-08** — Bind riposte balance soak | **`_run_p4h_bind_riposte_balance_suite`** + existing **`_run_bind_riposte_*`** · Playtest **ii2b** / **Q2** maintain |

### Phase 4 — New systems (**IV-\***)

One **$FEATURE_*$** (or explicit "no flag") per PR. **Dependency hints:** IV-2 → IV-3; III-2 → IV-4 / IV-5; IV-7 → IV-8; IV-9 last (high risk).

| ID | Status | Intent | Notes |
|----|--------|--------|-------|

| **IV-2** | **Done** | Multi-target **close** slots | Shipped (spread at LONG) |
| **IV-3** | **Shipped ☑** | Engagement **1v1** classifier (`snapshot_is_true_duel`) | **`iv3_doc_sync_line`** · **`_run_iv3_true_duel_classifier_suite`** · **`_run_engagement_scenarios`** ☑ 2026-06-08 |
| **IV-4** | **Shipped ☑** | Guard **matrix** / eight-diagonal fidelity | **`guard_cardinal_for_attack_path`** · **`guard_zone_part_for_line`** · **`_run_iv4_guard_matrix_suite`** ☑ 2026-06-08 |
| **IV-5** | **Shipped ☑** | Arm **interpose** (BP6) | **`FEATURE_ARM_INTERPOSE`** · **`arm_interpose_eval`** ☑ 2026-06-08 · `_run_iv5_arm_interpose_suite` |
| **IV-6** | **Shipped ☑** | Zone-specific guard / octant attack paths | **`FEATURE_IV6_ATTACK_PATH_OCTANT`** · **`get_attack_path`** / **`_iv6_diagonal_attack_path`** · **`_run_iv6_attack_path_octant_suite`** ☑ 2026-06-08 |
| **IV-7** | **Shipped ☑** | **Armor burden** on initiative/readiness | **`FEATURE_ARMOR_BURDEN`** · **`armor_burden_action_ready_mult`** · **`armor_burden_passive_readiness_mult`** · **`_run_iv7_armor_burden_*`** ☑ 2026-06-08 |
| **IV-7b** | **Shipped ☑** | Stamina engage floor for offense listing | **`AI_STAMINA_ENGAGE_FLOOR_RATIO`** · **`ai_offense_stamina_weight_mult`** · **`_run_iv7b_stamina_engage_floor_suite`** ☑ 2026-06-08 |
| **IV-8** | **Shipped ☑** | Combat-start **initiative** ordering | **`FEATURE_INITIATIVE_ORDER`** · **`initiative_score_for_combatant`** · **`_run_iv8_initiative_order_*`** ☑ 2026-06-08 |
| **IV-9** | **Shipped ☑** | **Gap-column** slot topology (flag default **off**) | **`FEATURE_GAP_COLUMN_TOPOLOGY`** · compaction gate · **`FormationSlots`** column graph · **`CombatPairGeometry`** arc · diagram gaps · **`_run_iv9_gap_column_*`** ☑ 2026-06-08 |
| **IV-10** | **Shipped ☑** | **Subregion** combat multipliers | **`FEATURE_SUBREGION_COMBAT_MULT`** · **`CombatHitSubRegion.combat_damage_mult`** · **`_run_iv10_subregion_combat_mult_*`** ☑ 2026-06-08 |
| **IV-11** | **Slice 1–10 ☑** | Leader formation **abilities** | player + enemy commander · pinch outnumber AI · F5 **`leader_order=`** (validator **`iv11_leader_order`**) · encounter spawn |
| **IV-12** | **Shipped ☑** | Multi-unit same slot + distraction | **`FEATURE_IV12_SLOT_DISTRACTION`** (default off) · formation **slot cell** grouping · **`drag_back`** dual-occ · surround pad · **`iv12_offense_weight_mult`** · pile-on **`IV12_AI_COLOCATED_TARGET_BIAS_MULT`** · **`_run_iv12_*`** ☑ 2026-06-08 |
| **IV-13** | **Shipped ☑** | ZoC **weapon-reach** bonus at weak front | **`FEATURE_IV13_WEAPON_REACH_ZOC`** (default off) · **`ZoneOfControl.weapon_reach_zoc_bonus_m`** · **`CombatMeleeListing`** + **`CombatDistanceBands`** · **`_run_iv13_weapon_reach_zoc_*`** ☑ 2026-06-08 |


### Cognition & AI (Tier 4 — not IV)

| ID | Status | Intent | Modules / notes |
|----|--------|--------|-----------------|
| **MS-L5–L6** | **Shipped ☑** | Mental-stack layers — formation plug, rout | **`MENTAL_STACK_LAYER_FORMATION_PLUG`** · **`FEATURE_MS_L6_ROUT`** ☑ 2026-06-08 · `_run_mental_stack_*` |
| **MS-L7** | **Shipped ☑** | Exhaustion tunnel L5 + offense damp (p4a ☑ 2026-06-08) | [#tier-43](#tier-43-mental-stack--combat-attention) |
| **MS-MID** | **Shipped ☑** | Mid-fight ally medical listing + L1 coordination | **`FEATURE_MS_MID_INFIGHT_MED`** · **`_run_ms_mid_infight_med_depth_suite`** ☑ 2026-06-08 |
| **MS-CAMP** | **Shipped ☑** | Trait/morale → stack thresholds via bridge meta (XCamp-3.8: stance pref; XCamp-3.9: MS weight biases, enemy mood bias from encounter config) | **XCamp-3.8** · **`stance_preference_for_campaign_mood`** · **`apply_campaign_mood_stance_preferences`** · company checks **`_run_xcamp_38_ms_camp_bridge`** ☑ 2026-06-08 · **XCamp-3.9** · **`CombatCampaignMoodBias`** · **`apply_campaign_mood_bias_to_encounter`** · mood→MS multipliers (wait/focus/offense/flee/disengage) · enemy `enemy_mood_bias` from encounter config → `ENCOUNTER_KEY_MOOD_BIAS_ENEMY` · company checks **`_run_xcamp_39_mood_bias_to_ms`** ☑ 2026-06-21 |
| **Tier 4.4 PA pilot** | **Shipped** | Line-key exchange step + octant lookup | [#wf-tier-44-pa](#wf-tier-44-pa) · maintain [#wf-footing-improvement-backlog](#wf-footing-improvement-backlog) |
| **Tier 4.4 spatial** | **Slice 1–3 ☑** | Band · wing dodge · flurry PA | **`FEATURE_T44_SPATIAL_*`** · **`_run_t44_spatial_*`** |
| **Player targets** | **Wontfix** | Per-click target UI | [`SHIP_PLAN` §9b](SHIP_PLAN.md#combat-mental-stack-shipped) |
| **WF-1a–1c** | **Shipped** | Module, picker **`mod`**, UI suffix, soak **ii5c**/**ii8** | [#wf-1a-shipped](#wf-1a-shipped) · [#wf-1b-shipped](#wf-1b-shipped) · [#wf-1c-shipped](#wf-1c-shipped) |
| **WF-2a–2b** | **Shipped** | Yomi inference + counter picks | [#wf-2-open](#wf-2-open) |
| **WF-3** | **Shipped** | Auto-switch (stamina, surround, duel/yomi, counter-read) | [#wf-3-open](#wf-3-open) |
| **WF-4** | **Shipped** | Roster / encounter spawn wiring | [#wf-4-open](#wf-4-open) |

<a id="weapon-form-stances"></a>
