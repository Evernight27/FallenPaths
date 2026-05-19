# Ai Engagement Stance And Feints

**Plan / code:** Tier **4** → [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md#tier-4--ai--stance) ([milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary) is the only **Status** column). This file = **live-path tables** (modules + grep) + **investigations** below.

| Step | Plan | Live-path / registry |
|------|------|----------------------|
| **4.1** | [Done](IMPLEMENTATION_ORDER.md#tier-41-posture--stance-weights-ai-listing) | [Posture / stance table](#tier-41-posture--stance-weights-ai-listing-live-path) — **`_run_ai_targeting_`**, **`_run_crash_ai_`** |
| **4.2** | [Done](IMPLEMENTATION_ORDER.md#tier-42-feint-d-telegraph-ai) | [Spacing / tempo table](#tier-42-footwork--tempo--live-path-shipped) — **`_run_feint_`**, **`_run_defense_spacing_`**, **`_run_counter_tempo_`** |
| **4.2b** | [Done](IMPLEMENTATION_ORDER.md#p4e--tier-42b-feint-listing-reveal-parity) | Listing × reveal — **`_run_feint_move_listing_reveal_progress_dampens_early_wind_up`** (row in [§4.2 table](#tier-42-footwork--tempo--live-path-shipped)) |
| **4.3** | [Done](IMPLEMENTATION_ORDER.md#tier-43-mental-stack--combat-attention) | [Attention / stack table](#tier-43-mental-stack--combat-attention-live-path) — **`_run_attention_`**, **`_run_focus_`**, **`_run_mental_stack_`**, **`_run_yomi_`** |
| **4.4** | [Done](IMPLEMENTATION_ORDER.md#tier-44-spatial-footwork-deferred) | [Position-angle table](#tier-44-position-angle-footwork-live-path) — **`_run_footwork_`** |
| **4.5** | [Done](IMPLEMENTATION_ORDER.md#tier-45-flurry-bind-exchange-deferred) | [Bind exchange table](#tier-45-flurry-bind-exchange-live-path) — **`_run_flurry_*`** |

## Contents

1. [Tier 4.1 live path](#tier-41-posture--stance-weights-ai-listing-live-path)
2. [Tier 4.2 live path](#tier-42-footwork--tempo--live-path-shipped)
3. [Tier 4.3 live path](#tier-43-mental-stack--combat-attention-live-path)
4. [Tier 4.4 live path](#tier-44-position-angle-footwork-live-path)
5. [Tier 4.5 live path](#tier-45-flurry-bind-exchange-live-path)
6. Investigations — [`Source:`](#feint-counter-stamina-readiness-diagonal-investigation) sections below

---

<a id="tier-41-posture--stance-weights-ai-listing-live-path"></a>

## Tier 4.1 posture + stance weights — live path (shipped)

**Reader:** listed-hostile melee weights multiply by **our** formation posture+cohesion, **opponent** formation posture+cohesion, combatant **stance** (`ai_melee_focus`), and (crash only) line posture. Intruders read formation state via **`ZoneOfControl.formation_id_for_zone_geometry`** / **`formation_dict_for_zone_geometry`**.

| Layer | Module | Role | Harnesses (grep) |
|-------|--------|------|------------------|
| Listed hostile weights | `CombatTargetScoring.gd` | **`ai_targeting_weight_mult`**, **`posture_cohesion_targeting_mult`**, **`opponent_formation_targeting_mult`**, **`stance_ai_targeting_mult`**, **`opponent_breach_file_targeting_mult`** | **`_run_ai_targeting_stance_mult_ordering`**; broader **`_run_ai_targeting_`**, **`_run_targeting_`**, **`_run_hostile_pair_`** |
| Crash listing | `CombatAIActionPicker.gd` | **`_crash_weight_posture_mult`**, **`crash_line_cohesion_weight_mult`** | **`_run_crash_ai_posture_mult_with_cached_fd`**, **`_run_crash_ai_cohesion_weight_monotone`** |
| Intruder geometry | `ZoneOfControl.gd` | Host-line **`formation_dict_for_zone_geometry`** for posture / breach reads | (shared with Tier **1.6** harnesses above) |

<a id="tier-42-footwork--tempo--live-path-shipped"></a>

## Tier 4.2 footwork / tempo — live path (shipped)

**Reader:** pair **`distance_to[attacker]`** on the defender (`CombatDistanceBands` snapshot) nudges passive defense in **`DefenseChoiceResolver.choose_defense`**. Feint-specific spacing uses **`FEINT_*_SPACING_*`** / **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**. **Recovering** defenders get an extra multiplier on **reported `dodge_chance` only** (not **`parry_c_d`** readiness curves). **Position-angle steps** (attack/defender offset on arc) → [§4.4 table](#tier-44-position-angle-footwork-live-path) (orthogonal to pair spacing).

| Layer | Module | Constants | Harnesses (grep) |
|-------|--------|-----------|------------------|
| Pair spacing (all states) | `DefenseChoiceResolver.gd` | `DEFENSE_SPACING_PARRY_MULT_*`, `DEFENSE_SPACING_DODGE_MULT_*` | `_run_defense_spacing_band_modulates_parry_and_dodge` |
| Recovering dodge (after spacing) | `DefenseChoiceResolver.gd` | `DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT`, `DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE`, `defense_footwork_recovering_dodge_mult_for_cause` | `_run_defense_footwork_recovering_boosts_dodge_vs_waiting`, `_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult`, `_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close` |
| Settled waiting dodge (after spacing) | `DefenseChoiceResolver.gd` | `DEFENSE_FOOTWORK_WAITING_DODGE_MULT` (skipped when `PassiveParryContext.is_off_balance`) | `_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance`, `_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close` |
| Passive readiness (orthogonal) | `PassiveParryContext.gd`, `DefenseChoiceResolver.gd` | `READINESS_BY_CAUSE` (recovering **`parry_readiness`** / AI listing); incoming `PASSIVE_PARRY_READINESS_INCOMING_*` | `_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut`, `_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering` |
| Feint listing settled footwork | `CombatAIActionPicker.gd` | `AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT` (vs `DEFENSE_FOOTWORK_WAITING_DODGE_MULT` on dodge) | `_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance` |
| Feint listing recovering footwork | `CombatAIActionPicker.gd` | `ai_feint_listing_defender_recovering_footwork_mult_for_cause` (inverse `defense_footwork_recovering_dodge_mult_for_cause`; base `AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`) | `_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting`, `_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult`, `_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally` |
| Feint listing spacing (recovering) | `CombatAIActionPicker.gd` | `AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*` on **`pr_def`** (state-agnostic; recovering uses cause curve) | `_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering`, `_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering`, `_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally` |
| Feint listing wind-up reveal (4.2b) | `CombatAIActionPicker.gd`, `DefenseChoiceResolver.gd` | Live **`pending_attack`** on listed target → **`read_m`** × **`_feint_readiness_reveal_mult(pa_live, attacker)`** (parity with **`choose_defense`**) | `_run_feint_move_listing_reveal_progress_dampens_early_wind_up` |
| Counter-tempo (pilot) | `CounterTempo.gd`, `AttackWindUpStarter.gd`, `AvailableActionsBuilder.gd`, `CombatResolveAction.gd`, `CombatEventScheduler.gd`, `CombatAIActionPicker.gd`, `BattleUIUpdater.gd` | `COMBATANT_KEY_COUNTER_WINDOW_UNTIL`, `COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`, `COUNTER_TEMPO_GAUGE_*`, `COMBATANT_KEY_COUNTER_TEMPO_UI_HINT`, `AI_COUNTER_TEMPO_*` | `_run_counter_tempo_*` |
| Riposte chain | `CounterTempo.gd`, `AttackResultApplier.gd`, `AttackWindUpStarter.gd` | `COMBATANT_KEY_RIPOSTE_CHAIN_*`, `RIPOSTE_CHAIN_WINDUP_MULT`, `PA_KEY_RIPOSTE_CHAIN` | `_run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain` |

**`dodge_chance` stack in `choose_defense` (reported value):** base × stance evasion × ambush × surround × **`_spacing_band_dodge_chance_mult`** → if **`STATE_RECOVERING`**, × **`defense_footwork_recovering_dodge_mult_for_cause(recovery_cause)`**; elif settled **`STATE_WAITING`**, × **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`**.

**Shipped (4.2b / P4e):** feint-move listing applies **`DefenseChoiceResolver._feint_readiness_reveal_mult`** when the attacker has live **`pending_attack`** on the listed defender (same wind-up progress as **`choose_defense`**). **Rejected:** probabilistic feint without explicit **`feint_part`**.

<a id="tier-43-mental-stack--combat-attention-live-path"></a>

## Tier 4.3 mental stack & combat attention — live path (shipped)

**Reader:** **Salience** (who matters now) picks the AI layer; **focus** (`focus_part` + `focus_intensity`, damped by **`attention_load`**) scales feint read-through and reported **`parry_readiness`**. Pair spacing / feint telegraph → [§4.2](#tier-42-footwork--tempo--live-path-shipped); arc step offsets → [§4.4](#tier-44-position-angle-footwork-live-path).

| Layer | Module | Role | Harnesses (grep) |
|-------|--------|------|------------------|
| Salience + load | `CombatAttention.gd` | **`is_being_wind_up_targeted`**, **`has_actionable_counter_tempo`**, **`attention_load`**, **`focus_effective`**, UI hint refresh | **`_run_attention_being_wind_up_targeted_when_telegraph_set`**, **`_run_attention_counter_tempo_salience_matches_can_act`**, **`_run_attention_load_stacks_peril_and_incoming`**, **`_run_attention_load_dampens_focus_effective_readiness`**, **`_run_attention_ui_hint_*`**, **`_run_attention_refresh_waiting_tick_stamps_ui_hint`** |
| Focus on defense | `DefenseChoiceResolver.gd`, `GuardLineUpdater.gd` | Read-through / readiness × **`focus_effective`**; guard moves sync **`focus_part`** | **`_run_focus_intensity_scales_feint_readthrough_and_guard_zone`**, **`_run_guard_from_move_syncs_focus_part_with_guard_line`** |
| AI stack | `MentalStackDecider.gd`, `CombatAIActionPicker.gd` | Layered **`decide_action`** before weighted attack pick | **`_run_mental_stack_medical_overrides_attack`**, **`_run_mental_stack_incoming_windup_prefers_defense`**, **`_run_mental_stack_counter_over_plain_attack_when_window_open`**, **`_run_mental_stack_attack_layer_matches_legacy_weights`**, **`_run_mental_stack_stamps_layer_on_medical_pick`** |
| Focus-line commands | `CombatAttention.gd`, `AvailableActionsBuilder.gd`, `CombatResolveAction.gd` | **`append_focus_line_listing_actions`**; listed **`focus_*`** retarget; party-lead telegraph bias | **`_run_focus_line_actions_listed_when_attention_enabled`**, **`_run_focus_line_resolve_sets_guard_and_focus`**, **`_run_focus_line_party_leader_prefers_telegraph_match`** |
| Yomi memory | `CombatAttention.gd`, `AttackWindUpStarter.gd`, `AttackResultApplier.gd`, `CombatAIActionPicker.gd` | Per-attacker habit; feint listing / readiness mults | **`_run_yomi_guard_tendency_boosts_feint_after_repeated_high`**, **`_run_yomi_updates_on_parry_deflect_clears_on_hit`**, **`_run_yomi_focus_drift_*`**, **`_run_yomi_parry_deflect_boosts_feint_listing_mult`**, **`_run_yomi_defense_readiness_mult_boosts_after_parry_deflect`** |
| Lifecycle | `CombatManager.start()` | **`CombatAttention.clear_focus_and_yomi`** on combat start | (covered by focus/yomi harnesses + telegraph scrub in **4.2**) |

<a id="tier-44-position-angle-footwork-live-path"></a>

## Tier 4.4 position-angle footwork — live path (shipped)

**Reader:** abstract **±deg offset** on arc geometry (not world positions). Gated by **`CombatConstants.is_feature_position_angle_footwork_enabled()`** (production default **on**; harness **`set_feature_position_angle_footwork_load`** toggles for isolation). Per-line offsets: **`POSITION_ANGLE_OFFSET_DEG_BY_LINE`** (`high` **0°**, `low` **+6°**, `left` **+14°**, `right` **-14°**). Pair **CLOSE/MID/LONG** spacing remains under [§4.2](#tier-42-footwork--tempo--live-path-shipped).

**UI rule:** gauge / diagram step hints (`Step ±N°`) only while **`state`** is **`wind_up`** or **`recovering`** (**`CombatFootwork.offset_visible_for_ui_state`**). Idle reserve (e.g. back rank **`waiting`**) must not show a stale step after an aborted wind-up.

**Lifecycle:** call **`CombatFootwork.clear_on_exchange_end`** (alias of **`clear_position_offset`**) whenever **`pending_attack`** is torn down without a full **`AttackResolver`** resolve — notably **`CounterTempo.abort_attacker_wind_up`**, **`CombatStateHandlers.enter_short_recovery`** / **`complete_recovery`**, **`AfterblowHandler._cancel_pending`**, **`MedicalPhaseController.halt_losing_side_combat`**, plus normal resolve via **`AttackResolver`** / **`AttackResultApplier`**.

**Depth rank:** rank-1 **spear** with an open depth polearm lane may wind up legitimately; aborted depth attacks must not leave **-14°** (or other offsets) on **`waiting`** rows.

| Layer | Module | Role | Harnesses (grep) |
|-------|--------|------|------------------|
| Feature flag | `CombatConstants.gd` | **`is_feature_position_angle_footwork_enabled()`** / load setter; **`POSITION_ANGLE_OFFSET_DEG_BY_LINE`** | all **`_run_footwork_*`** wrap flag on/off |
| Step + offset math | `CombatFootwork.gd` | **`apply_attack_step_on_windup`**, **`apply_defender_step_on_parry`**, **`apply_defender_step_on_dodge`**, **`apply_offset_to_angle_deg`**, **`guard_angle_deg`**, **`clear_position_offset`**, **`clear_on_exchange_end`**, **`offset_visible_for_ui_state`** | **`_run_footwork_attack_step_offset_stamped_on_windup`**, **`_run_footwork_offset_shifts_attack_angle_deg`**, **`_run_footwork_defender_parry_step_stamps_offset`**, **`_run_footwork_defender_offset_shifts_guard_angle_deg`**, **`_run_footwork_defender_dodge_step_stamps_offset`**, **`_run_footwork_guard_line_for_body_part_maps_legs_and_chest`**, **`_run_footwork_choose_defense_dodge_does_not_keep_parry_offset`** |
| Wind-up stamp | `AttackWindUpStarter.gd` | Move **`attack_line`** → attacker offset at wind-up start | **`_run_footwork_windup_arc_intended_includes_attacker_step`** |
| Defense pick | `DefenseChoiceResolver.gd` | Parry alignment + commit parry/dodge step; **`clear_on_exchange_end`** before dodge branch | **`_run_footwork_arc_contact_applies_offset_once`** |
| Resolve / arc | `AttackResolver.gd`, `WeaponSwingPhysics.gd` | Before **`stamp_resolve_angle_geometry_on_pa`**, re-**`apply_attack_step_on_windup(atk, atk_line_base)`** when diagonal C rolls a new **`effective_attack_line`** (skipped on parry follow-through re-resolve); **`pa.position_angle_offset_deg`**; arc end / contact angle | **`_run_footwork_arc_end_fallback_prefers_intended_over_attack_angle`**, **`_run_footwork_partial_follow_through_freezes_resolve_angles`** |
| Abort / recovery scrub | `CounterTempo.gd`, `CombatStateHandlers.gd`, `AfterblowHandler.gd`, `MedicalPhaseController.gd` | **`abort_attacker_wind_up`** and related paths **`clear_on_exchange_end`** so reserve units do not keep offsets | **`_run_footwork_abort_attacker_wind_up_clears_offset`**, **`_run_footwork_back_rank_abort_clears_depth_windup`** |
| Lifecycle scrub | `CombatManager.start()`, `AttackResultApplier.gd`, `CombatManager._on_combatant_died` | Clear offset on restart / exchange end / death | **`_run_footwork_offset_scrubbed_on_combat_start`**, **`_run_footwork_defender_offset_scrubbed_after_exchange`** |
| UI | `CombatFootwork.gd`, `CombatUiHints.gd`, `BattleUIUpdater.gd`, `CombatCombatantsSnapshot.gd`, `FormationDiagramBuilder.gd`, `BattleScene.gd` | **`get_ui_hint`** / **`get_diagram_label_suffix`** only in **`wind_up`** / **`recovering`**; gauge + tooltips; snapshot fields; diagram refresh on hint / flag-off | **`_run_footwork_ui_hint_*`**, **`_run_footwork_waiting_hides_stale_step_ui`**, **`_run_footwork_diagram_label_suffix_compact`**, **`_run_footwork_snapshot_*`**, **`_run_combat_snapshot_exports_*`** |

<a id="tier-45-flurry-bind-exchange-live-path"></a>

## Tier 4.5 flurry / bind exchange — live path (shipped)

**Reader:** After hard bind **`parry_deflect`**, both partners get a short window (**`FLURRY_BIND_WINDOW_S`**, max **`FLURRY_BIND_MAX_EXCHANGES`** wind-ups) of faster attacks vs each other only — not full **`STATE_IN_FLURRY`**. Gated by **`CombatConstants.FEATURE_FLURRY_BIND_EXCHANGE`** (production default **on**).

| Layer | Module | Role | Harnesses (grep) |
|-------|--------|------|------------------|
| Window state | `CombatFlurryBind.gd` | **`open_pair_after_bind`**, **`process_waiting`**, **`clear_pair`** on hit | **`_run_flurry_bind_opens_on_bind_deflect`**, **`_run_flurry_bind_expires_after_window`**, **`_run_flurry_bind_window_closes_on_hit`** |
| Wind-up / stamina | `AttackWindUpStarter.gd`, `AttackResultApplier.gd` | ×**`FLURRY_BIND_WIND_UP_MULT`**; attack cost ×**`FLURRY_BIND_STAMINA_ATTACK_COST_MULT`**; consume exchange on discounted wind-up | **`_run_flurry_bind_exchange_wind_up_reduced_vs_plain`**, **`_run_flurry_bind_exchange_consumes_on_wind_up`** |
| Melee listing | `CombatMeleeListing.gd` | Hostile melee only vs **`flurry_against_id`** while active | **`_run_flurry_bind_listing_restricts_to_bind_partner`** |
| UI | `CombatUiHints.gd`, `BattleUIUpdater.gd` | Gauge **Bind exchange (N left)** + tooltip | **`_run_flurry_bind_ui_gauge_label_when_window_open`** |
| Flag | `CombatConstants.gd` | **`is_feature_flurry_bind_exchange_enabled`** / load setter | **`_run_flurry_bind_feature_flag_respects_runtime_toggle`** |

**Constants:** **`FLURRY_BIND_WINDOW_S`** **1.25** · **`FLURRY_BIND_MAX_EXCHANGES`** **2** · **`FLURRY_BIND_WIND_UP_MULT`** **0.82** · **`FLURRY_BIND_STAMINA_ATTACK_COST_MULT`** **0.88**.

---

<a id="feint-counter-stamina-readiness-diagonal-investigation"></a>

## Source: `FEINT_COUNTER_STAMINA_READINESS_DIAGONAL_INVESTIGATION.md`

# Feint, Counter Window, Stamina, Recovery→Readiness & Diagonal Line Roll: Integration Investigation

Investigation into different ways to integrate five combat features: feint (telegraph vs real target), counter windows (tempo interrupt), stamina, recovery cause → readiness scaling, and diagonal line roll. Each section explores multiple approaches with pros, cons, and implementation notes.

---

## 1. Feint (Telegraph vs Real Target)

**Shipped in code:** see [§4.2 live path](#tier-42-footwork--tempo--live-path-shipped) (not this investigation).

**Open in this investigation doc only:** probabilistic misdirection (Approach **B**, rejected as primary); Approach **C** partial via **`feint_target_reveal_at_progress`** (not full “hide target until 50%” without **`feint_part`** split).

**HEMA:** Feint = threaten line A to draw parry; disengage; hit line B. Single-tempo action (Giganti: cavazione baits response).

### Approach A: Feint as Explicit Two-Phase Commitment

**Mechanic:** Move has `is_feint: bool`. When true, attacker commits `feint_part` (telegraph) ≠ `target_part` (real). Defender sees telegraph; if they parry/guard toward feint_part, they get parry penalty when real hit lands.

**Flow:**
1. Attacker chooses feint move, feint_part, target_part (e.g. feint head, real chest).
2. Wind-up: defender sees feint_part (or probabilistic inference).
3. Defender chooses parry/dodge based on feint_part (guards wrong zone).
4. Execute: real target_part used for hit resolution. If defender guarded feint_part, parry_c_d × 0.6 (or similar).

**Pros:** Historical. Tactical depth. Mind-games.
**Cons:** Two-phase commitment. Defender needs reaction logic. Feint cost: ~10% wind-up (Fabris). New move type or flag per move. AI must decide when to feint.

**Data:** `pending_attack.feint_part`, `pending_attack.target_part`. Move: `is_feint: true`, `feint_windup_penalty: 0.1`.

---

### Approach B: Feint as Probabilistic Misdirection

**Mechanic:** X% chance actual target ≠ intended. No explicit feint_part. At resolve, roll: if `randf() < FEINT_CHANCE`, swap target_part to a different part in path (or adjacent line).

**Pros:** Simple. Emergent deception. No new UI or commitment flow.
**Cons:** Not intentional feint. Attacker doesn't "threaten then redirect." Feels random, not skillful.

**Data:** `FEINT_CHANCE := 0.08` (or per-move). At resolve, before path lookup, roll for swap.

---

### Approach C: Feint as Telegraph Delay

**Mechanic:** Attacker commits target_part at 50% wind-up (not at start). First half of wind-up: defender sees "attack incoming" but not which part. Second half: telegraph reveals target_part. Defender has less time to react to real target.

**Pros:** Reduces defender reaction window. No feint_part/target_part split.
**Cons:** Doesn't model "bait wrong parry." Just shortens effective reaction time.

**Data:** `COMMITMENT_FRACTION` already exists (0.2). Could add `telegraph_at_progress: 0.5` — defender only gets target_part for parry choice after 50% wind-up.

---

### Approach D: Feint as Parry Bait (Guard Zone Only)

**Mechanic:** Requires zone-specific guard (guard_zone). Attacker feints → defender moves guard to feint_part. Real attack goes to target_part. Defender's guard_zone is wrong → parry penalty.

**Pros:** Clean integration with guard_zone. No new attack types.
**Cons:** Depends on guard_zone implementation. Defender AI must "fall for" feint (guard feint_part when they see telegraph).

---

### Feint Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| Full HEMA fidelity | A | High |
| Simple variance | B | Low |
| Shorter reaction | C | Medium |
| With guard_zone | D | Medium (after guard_zone) |

**Suggested path:** **C** (telegraph delay) is lowest effort and improves tempo without new mechanics. **A** if you want explicit feint moves and mind-games.

### Feint A vs D: Integration Differences

| Aspect | A (Explicit Two-Phase) | D (Parry Bait / Guard Zone) |
|--------|------------------------|------------------------------|
| **Prerequisite** | None | guard_zone system |
| **Defender state** | Uses existing parry choice; feint affects parry capacity when defender "guarded wrong" | Requires defender to have guard_zone; feint = bait guard to wrong zone |
| **Standalone** | Yes — can add feint without other systems | No — blocked on guard_zone |
| **AI complexity** | AI must choose feint_part, target_part; decide when to feint | AI must "fall for" feints (guard telegraph); attacker exploits |

**Verdict:** **A** is self-contained and can be added immediately. **D** is cleaner conceptually but requires guard_zone.

---

## 2. Counter Window (Tempo / Partial Gauge Interrupt)

**Current:** Act only when gauge = 100. No interrupt during enemy wind-up.

**HEMA:** "When he raises his sword... strike while his hand is rising." (Dall'Agocchie) Opponent committed = your opportunity.

### Approach A: Partial Gauge Counter (Spend 50% → Act Now)

**Mechanic:** When enemy is in WIND_UP and my gauge ≥ 50, I can spend 50 gauge → immediate action. My action resolves *before* the enemy's attack. If my action defeats/kills them, their attack never executes.

**Flow:**
1. Enemy enters WIND_UP. My gauge = 60.
2. I choose "Counter" (new action). Spend 50 gauge → gauge = 10.
3. I immediately resolve my attack (or other action). Order: counter resolves first.
4. If enemy dies or is incapacitated, their wind-up is cancelled. Else, their attack still executes (they were winding up on me; I countered someone else, or missed).

**Pros:** Captures tempo. "Strike while his hand is rising." High impact.
**Cons:** Order of resolution: counter first. Attacker may "lose" to counter. Balance: 50% cost. New decision for player/AI. UI: "Counter" button when eligible.

**Data:** `get_available_actions` adds "counter" when `gauge >= 50` and `_is_enemy_winding_up_on_me(c)`. Counter action spends 50, triggers immediate resolve.

---

### Approach B: Stricter Counter (60% Gauge or Wind-Up > 50%)

**Mechanic:** Same as A but: (1) require 60% gauge, or (2) only when enemy wind-up progress > 50% (they're committed, can't abort).

**Pros:** Reduces counter spam. More committed = more vulnerable.
**Cons:** More tuning. May feel restrictive.

---

### Approach C: Counter as Gauge Advantage (No Interrupt)

**Mechanic:** When enemy is in WIND_UP, my gauge fills 20% faster. I don't interrupt; I just get to act sooner after their attack resolves.

**Pros:** No resolution order complexity. Simpler.
**Cons:** Doesn't capture "strike during their wind-up." Less dramatic.

---

### Approach D: Counter Window as Reaction Action

**Mechanic:** During enemy wind-up, defender gets a one-time "counter" option that costs 40 gauge. If taken, defender's action is queued to resolve *before* attacker's. Not an attack—a defensive counter (parry-thrust, etc.) that happens "early."

**Pros:** Defensive flavor. Fits "catch them in the middle of the cut."
**Cons:** Only defender can counter. Attacker can't counter defender's wind-up (asymmetric).

---

### Counter Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| Full tempo interrupt | A | Medium |
| Reduce spam | B | Low (tweak A) |
| Simpler | C | Low |
| Defensive only | D | Medium |

**Suggested path:** **A** for full tempo play. **B** if counters feel too frequent. Requires: `_is_enemy_winding_up_on_me`, counter action in available_actions, resolution order (counter first).

### Flurries of Blows (Counter Interaction)

**HEMA:** Rapid successive attacks. 70–90% of exchanges end in some hit. Double hits 7–40%. Binding enables quick thrusts.

**Flurry options:**
- **1. Emergent from counter:** Counter creates one extra exchange per wind-up. Natural limit from gauge cost. Low effort.
- **2. Explicit sub-phase:** Enter `STATE_IN_FLURRY` after attack resolves. High effort.
- **3. Riposte chain:** After parry_deflect, defender's next attack has 50% wind-up. Medium effort. Complementary with counter.
- **4. Binding state:** parry_deflect → bound. While bound, short thrusts only. High effort.

**Suggested:** Implement counter window first. Flurries emerge from repeated counter opportunities (Option 1). Add riposte chain for more flow.

---

## 3. Stamina

**Current:** Gauge = readiness (0–100). Fills when idle. Must be 100 to act. No consumption beyond "spend 100 to act."

**KCD:** Stamina depletes with block, attack, sprint. Low stamina → weak attacks, block breaks, vulnerable.

### Approach A: Gauge as Stamina (Over-Spend)

**Mechanic:** Attacks cost gauge by intensity/archetype. Heavy attack costs 120 → leaves gauge at 0 (or negative, clamped). Light attack costs 60. Block/parry costs 15. Gauge refills at agility × rate. When gauge < 100, can't act. When gauge < 50, intensity cap 0.5 (weak attacks only).

**Pros:** One pool. Readiness = stamina. Low gauge = vulnerable.
**Cons:** Changes gauge semantics. "Full" used to mean 100; now "can act" might be 100 but "strong attack" needs 120. Tuning: cost per move.

**Data:** Move: `stamina_cost: float` (e.g. 80–120). Parry: `PARRY_STAMINA_COST := 15`. `process_waiting`: gauge += fill_rate. When acting: gauge -= cost; clamp 0.

---

### Approach B: Separate Stamina Pool

**Mechanic:** New `stamina: float` 0–100 per combatant. Gauge = readiness (unchanged). Stamina consumed by: attack (5–20 by archetype), parry (10), block (15). Refill: stamina += rate when idle. At stamina 0: can't parry (or parry fails), attacks deal 50% damage, or can't heavy attack.

**Pros:** Clear separation. Gauge = "can I act"; stamina = "how well can I fight."
**Cons:** Two pools. More UI. More state.

**Data:** `combatant["stamina"] = 100`. `STAMINA_ATTACK_COST`, `STAMINA_PARRY_COST`. Refill in process_waiting.

---

### Approach C: Unified Pool (Gauge = Stamina = Readiness)

**Mechanic:** One pool. "Readiness" when full = can act. Same pool consumed by actions. Refill rate = agility × rest_factor. Attacking costs 100 (to act) + overflow cost. E.g. heavy attack: need 100 to queue, then consume 20 more → gauge drops to 80. Next fill to 100 before next act.

**Pros:** Single number. Simple mental model.
**Cons:** Gauge semantics shift. "100" = ready; acting drops it. Already partially true (gauge = 0 after acting). Main change: parry/block also consume.

---

### Approach D: Stamina as Intensity Cap Only

**Mechanic:** No stamina pool. Instead: "fatigue" or "exertion" from recent actions. After N attacks in a row, intensity cap drops (e.g. 0.7 max). Recovers over time. Simpler: no new pool, just a debuff.

**Pros:** Minimal. No stamina UI. Emergent "tired" state.
**Cons:** Less granular. No "block costs stamina" or "parry costs stamina."

---

### Stamina Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| KCD-style | A or B | Medium |
| Simplest | C | Low–Medium |
| Minimal | D | Low |

**Suggested path:** **D** (intensity cap from exertion) for minimal change. **A** if you want explicit stamina costs. **B** if you want clear separation of readiness vs stamina.

---

## 4. Recovery Cause → Readiness Scaling

**Current:** `recovery_cause` is set when entering RECOVERING: "skip", "attack_miss", "attack_deflect", "attack_hit". Used by AttackPathResolver (staggered → chest bias). Readiness uses uniform lerp(0.5, 0.85) for all recoveries.

**Question:** Should parry capacity (readiness) differ by *why* they're recovering?

### Approach A: Cause-Based Readiness Curves

**Mechanic:** Different readiness multiplier per recovery_cause:
- `attack_hit` → lerp(0.3, 0.6, progress) — more stunned, worse parry
- `attack_miss` → lerp(0.45, 0.8, progress) — off-balance but less stunned
- `attack_deflect` → lerp(0.5, 0.85, progress) — blade deflected, similar to current
- `skip` / `medical` → lerp(0.5, 0.85, progress) — unchanged

**Pros:** Hit → more vulnerable. Miss → less so. Realistic.
**Cons:** New constants per cause. Tuning.

**Data:** `READINESS_BY_CAUSE: Dictionary` with early/late per cause. `PassiveParryContext.get_passive_parry_readiness(c)` reads `c.recovery_cause` and picks curve.

---

### Approach B: Cause as Readiness Modifier (Single Curve)

**Mechanic:** Keep single lerp(0.5, 0.85). Multiply by cause modifier:
- attack_hit: ×0.7
- attack_miss: ×0.95
- attack_deflect: ×1.0
- skip/medical: ×1.0

**Pros:** Simpler. One curve, one multiplier.
**Cons:** Less granular than full curves.

---

### Approach C: Incoming Attack Type on Readiness

**Mechanic:** Pass incoming `attack_type` (cut/thrust/blunt) into readiness. Thrust → lower readiness (harder to react). Cut → same or higher (more telegraph).

**Pros:** Thrust is faster, less telegraph. Cut has visible arc.
**Cons:** Pass attack_type into parry calc. More parameters. Complicates DefenseChoiceResolver.

---

### Approach D: Keep Uniform (No Change)

**Mechanic:** Same lerp for all. recovery_cause only used for path resolver (staggered bias).

**Pros:** Simplest. No new tuning.
**Cons:** "Recovering from hit" parries same as "recovering from whiff."

---

### Recovery→Readiness Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| Realistic cause effect | A | Low |
| Simple modifier | B | Low |
| Attack-type aware | C | Medium |
| No change | D | None |

**Suggested path:** **B** (cause modifier) — low effort, clear effect. **A** if you want finer control. recovery_cause already exists; just use it in `get_passive_parry_readiness`.

---

## 5. Diagonal Line Roll

**Current:** Diagonal moves (oberhau, diagonal_chop) have single primary `attack_line`. Oberhau = "high", diagonal_chop = "left". Parry resolution uses that line exclusively.

**Physics:** Zornhau (descending diagonal) crosses high and left. Which line the guard meets first varies by trajectory and defender position.

### Approach A: Keep Primary (No Change)

**Mechanic:** One line per move. oberhau = high, diagonal_chop = left.

**Pros:** Simple. No extra roll.
**Cons:** Diagonal parries feel binary. Same outcome every time.

---

### Approach B: Weighted Roll at Resolve

**Mechanic:** Diagonal moves have `attack_lines: Array` with weights. E.g. oberhau: `[{"high": 0.65}, {"left": 0.35}]`. At resolve, roll to pick which line is "primary" for this exchange. Use that for alignment, path, parry.

**Pros:** Physics: path crosses lines; which intersects first varies. More varied outcomes.
**Cons:** Extra roll per diagonal move. Need line_weights per move. Slightly more complex.

**Data:** Move: `attack_lines: [{"line": "high", "weight": 0.65}, {"line": "left", "weight": 0.35}]`. At AttackResolver start, if move has attack_lines, roll to pick effective attack_line for this resolve.

---

### Approach C: Alignment-Weighted Roll

**Mechanic:** Roll weighted by defender's guard_line. If defender has high guard, 70% high / 30% left. If low guard, 50/50. Reflects "which line would my guard meet first given their position."

**Pros:** Tactical. Defender posture affects which line "wins."
**Cons:** More logic. Need weight table per (guard_line, diagonal_move).

---

### Approach D: Secondary Line as Fallback

**Mechanic:** Diagonal move has `primary_line` and `secondary_line`. If parry would fail on primary (e.g. alignment 0), use secondary for a "lucky" intercept roll. Not full weighted—just fallback.

**Pros:** Occasional variance. Simple.
**Cons:** Binary: primary or secondary. Less smooth than weighted.

---

### Diagonal Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| No change | A | None |
| Physics variance | B | Low |
| Tactical | C | Medium |
| Occasional variance | D | Low |

**Suggested path:** **B** (weighted roll) — low effort, good payoff. Add `attack_lines` only to diagonal moves (oberhau, unterhau, diagonal_chop, maybe slash). Others keep single `attack_line`.

### B vs C: Side-by-Side Comparison

| Aspect | B (Fixed Weighted) | C (Alignment-Weighted) |
|--------|---------------------|-------------------------|
| **Roll input** | Move only | Move + defender guard_line |
| **Probabilities** | Constant per move | Vary by defender |
| **Defender agency** | None | High — defender's guard influences outcome |
| **Realism** | "Blade path varies" | "Blade meets defender's guard where it is" |
| **Tactical depth** | Low | High |
| **Tuning** | One table per diagonal move | Table per (move, guard_line) — 4× more cells |

**Verdict:** **B** is simpler and adds variance. **C** is more tactical and realistic.

---

## 6. Implementation Order & Dependencies

```
1. Recovery cause → readiness (B: modifier)
   └── recovery_cause exists; PassiveParryContext change only

2. Diagonal line roll (B: weighted)
   └── WeaponConstants + AttackResolver; no new state

3. Stamina (D: intensity cap) or (A: gauge over-spend)
   └── Independent. D = minimal. A = more changes.

4. Counter window (A: 50% gauge)
   └── Requires: _is_enemy_winding_up_on_me, counter action, resolution order

5. Feint (C: telegraph delay) or (A: explicit feint)
   └── C = COMMITMENT_FRACTION tweak. A = new move type, defender logic.
```

---

## 7. Summary: Suggested Choices

| Feature | Suggested Approach | Rationale |
|---------|---------------------|-----------|
| **Feint** | C (telegraph delay) or A (explicit) | C = low effort. A = full fidelity. |
| **Counter window** | A (50% gauge interrupt) | Captures tempo. Medium effort. |
| **Stamina** | D (intensity cap) or A (gauge over-spend) | D = minimal. A = KCD-style. |
| **Recovery→Readiness** | B (cause modifier) | recovery_cause exists; one multiplier. |
| **Diagonal line roll** | B (weighted roll) | Physics variance. Low effort. |

---

## References

- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- PassiveParryContext.gd (get_passive_parry_readiness)
- AttackResolver.gd, DefenseChoiceResolver.gd
- WeaponConstants.gd (attack_line, move definitions)

---

<a id="combat-stance-states-investigation"></a>

## Source: `COMBAT_STANCE_STATES_INVESTIGATION.md`

## Combat Stance States: Medieval Soldier vs HEMA Psychology

Investigation of combat stances/psychological states for units: how medieval soldiers and HEMA practitioners differed, and how to model **defensive**, **aggressive**, **balanced**, and **controlling** stances—driven by stamina, personality, and weapon skill.

---

### Part 1: Medieval Soldier States (Formation Combat)

#### 1.1 Source Context

Medieval formation combat was **collective** — individuals acted as part of a unit. States were less about personal "Vor/Nach" and more about **role** and **fatigue**.

| State | Description | When |
|-------|-------------|------|
| **Fresh / eager** | Front rank, ready to fight. Aggressive or controlled by formation discipline. | Start of engagement |
| **Exhausted** | Can't maintain shield, weaker blows. Needs rotation. | After sustained fighting |
| **Wounded** | Diminished capability, may fall back or fight desperately | After taking hits |
| **Routed** | Broke rank, fleeing. No formation cohesion. | Morale collapse |

**Key:** Medieval soldiers didn't have formal "stances" in the HEMA sense. They had **fatigue**, **morale**, and **formation role**. Stance-like behavior emerged from: am I pressing or holding? Am I fresh or tired?

---

### Part 2: HEMA Psychology — Vor, Nach, Indes

#### 2.1 Liechtenauer's Five Words (Simplified)

| Term | Meaning | Combat state |
|------|---------|--------------|
| **Vor (Before)** | You attack first, compel opponent to defend. **Initiative.** | Controlling, pressing |
| **Nach (After)** | You respond to their attack. **Reactive.** | Defensive, countering |
| **Indes (Instantly)** | Act in the moment—often in the bind. **Timing.** | Balanced, opportunistic |

**Vor** = controlling the tempo. Your actions demand answers. Opponent is in Nach.

**Nach** = trying to win back the initiative. Defensive but not passive—counter-attacks, parry-riposte.

**Indes** = the transition moment. Acting while they act. Bind work, feints, tempo steals.

#### 2.2 Correspondence to Stances

| HEMA concept | Stance equivalent |
|--------------|-------------------|
| **Vor** | Aggressive or Controlling — pressing the attack |
| **Nach** | Defensive — responding, protecting |
| **Indes** | Balanced — ready to act in the moment; or Controlling — feints, binding |

---

### Part 3: Proposed Stance System

#### 3.1 Four Stances (Per User)

| Stance | Description | Effect |
|--------|-------------|--------|
| **Defensive** | Hold back, protect self. Prioritize parry/dodge over damage. | ↑ Parry capacity, ↑ evasion, ↓ damage dealt, ↓ close success (attacker) |
| **Aggressive** | Disregard incoming attacks, maximize damage. All-in. | ↑ Damage dealt, ↓ parry capacity, ↓ evasion, ↑ close success |
| **Balanced** | Default. Neither extreme. | Baseline modifiers |
| **Controlling** | Feints, binds, keep opponent occupied. Harder for them to engage or fall back. | ↑ Opponent's close/disengage difficulty, ↑ bind/feint effectiveness, moderate defense |

---

#### 3.2 What Drives Stance Choice

**Stamina:**
- Low stamina → can't sustain aggressive (exhausting). Tends toward defensive or balanced.
- High stamina → can afford aggressive or controlling.

**Personality (AI / trait):**
- Cautious → prefer defensive.
- Reckless → prefer aggressive when stamina allows.
- Tactical → prefer controlling when opponent is dangerous.
- Balanced → default.

**Weapon / skill:**
- Dagger, quick weapon → controlling (feints, tempo) fits.
- Two-handed, heavy → aggressive (commit to blows) or balanced.
- Shield-heavy → defensive fits (hold the line).

**Situation:**
- Outnumbered → defensive or controlling.
- Winning hand → aggressive to finish.
- Ally wounded nearby → defensive to cover.

---

#### 3.3 Stance Effects (Summary Table)

| Stance | Parry | Evasion | Damage | Close attempt (attacker) | Opponent disengage | Opponent close |
|--------|-------|---------|--------|--------------------------|--------------------|----------------|
| **Defensive** | ×1.2 | ×1.15 | ×0.85 | ×0.9 | ×1.0 | ×1.0 |
| **Balanced** | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |
| **Aggressive** | ×0.8 | ×0.85 | ×1.2 | ×1.1 | ×1.0 | ×1.0 |
| **Controlling** | ×1.0 | ×1.0 | ×0.95 | ×1.0 | ×0.85 (harder) | ×0.9 (harder) |

**Controlling** makes opponent's disengage and close attempts harder — you're occupying their attention, feinting, binding. They can't easily break off or close on someone else.

**Numbers are placeholders** — tune for feel.

---

#### 3.4 Stamina Gates

| Stance | Min stamina to choose | Notes |
|--------|------------------------|------|
| **Defensive** | 0 | Always available. Safer when low. |
| **Balanced** | 0 | Default. |
| **Aggressive** | 20–30 | Exhausting. Can't sustain at 0. |
| **Controlling** | 15–25 | Requires energy for feints, footwork. |

When stamina drops below minimum, unit **reverts to balanced or defensive** (can't maintain aggressive/controlling).

---

#### 3.5 Stance Transitions

- Stance can change **between actions** (on turn/event choice).
- Optional: **transition cost** — switching from aggressive to defensive takes a moment (e.g. 0.2 s delay) as you "reel in."
- Simpler: instant switch; modifiers apply on next action.

---

### Part 4: Medieval vs HEMA — Differences

| Aspect | Medieval formation | HEMA (duel) |
|--------|-------------------|-------------|
| **Vor/Nach** | Less explicit. Formation advances or holds. | Core concept — who has initiative. |
| **Feints** | Rare in dense shield wall (no room). More in loose/open. | Common — probing, baiting parry. |
| **Controlling** | Shield wall "holding the line" = collective control. | Bind, Fühlen (feeling), keep blade engaged. |
| **Exhaustion** | Triggers rotation. State change = fall back. | Triggers defensive play; can't sustain Vor. |

**Synthesis:** For Fallen Paths (formation + 1v1 engagement), use **HEMA stance concepts** (Vor/Nach/Indes) mapped to **four explicit stances**, modulated by **stamina** and **personality/skill**. Formation context affects which stances are viable (tight = less feinting; loose = more controlling).

---

### Part 5: Implementation Outline

#### 5.1 Data

```
combatant.stance: "defensive" | "balanced" | "aggressive" | "controlling"
combatant.stance_preference: "cautious" | "reckless" | "tactical" | "balanced"  # from personality/trait
```

#### 5.2 Stance Choice Logic (AI)

1. Check stamina — filter out stances below min_stamina.
2. Situation — outnumbered? wounded ally? winning?
3. Preference — cautious → defensive bias; reckless → aggressive bias; tactical → controlling when useful.
4. Pick stance for this action/phase.

#### 5.3 Modifier Application

- When resolving parry: `parry_capacity *= stance_parry_mod(stance)`
- When resolving damage: `damage *= stance_damage_mod(stance)`
- When resolving close attempt: `attacker_roll` modified by attacker stance; `defender_evasion` by defender stance.
- When resolving disengage: if defender has **controlling** stance, `attacker_disengage_difficulty *= 1.15` (or similar).

#### 5.4 Controlling — Feint / Bind Integration

- Controlling stance **enhances** feint effectiveness (when feints are implemented).
- Controlling **increases** opponent's action cost or difficulty for disengage and close.
- Represents: "I'm keeping you busy, you can't easily turn away or press someone else."

---

### Part 6: Recommendation Summary

1. **Four stances:** Defensive, Balanced, Aggressive, Controlling.
2. **Driven by:** Stamina (gates), personality/trait (preference), weapon/skill (fit), situation (context).
3. **Effects:** Modifiers to parry, evasion, damage, close attempt, and—for Controlling—opponent disengage/close difficulty.
4. **No stamina cost** for stance itself; stamina **gates** which stances are available.
5. **Controlling** = feint/bind emphasis; makes it harder for opponent to fall back or engage others.

---

### References

- HEMA Vor/Nach/Indes — Liechtenauer, Ringeck, Meyer (HEMA 101, Keith Farrell)
- `docs/TACTICAL_FORMATIONS_FF4.md` — formation density
- `docs/PARRY_DEFLECT_AND_CALIBRATION.md` — defensive stance option
- `docs/AI_ENGAGEMENT_STANCE_AND_FEINTS.md` — feint approaches

---

<a id="footwork-positioning-investigation"></a>

## Source: `FOOTWORK_POSITIONING_INVESTIGATION.md`

## Footwork and Positioning: Implementation Approaches

**Shipped slice (Tier 4.2):** pair **`distance_to`** bands + recovering **`dodge_chance`** — see [Tier 4.2 live path](#tier-42-footwork--tempo--live-path-shipped). Position-angle steps → [§4.4](#tier-44-position-angle-footwork-live-path). Sections below are **design options**; not all are implemented.

### Purpose

Investigate ways to implement footwork and positioning in the abstract combat system, and how they could affect angle, reach, and outcome.

---

### 1. Design Constraints

- **No 3D body / skeletal** — abstract representation
- **Angle-driven** — existing 4-line / continuous angle system
- **Reach** — weapons have melee_range; distance could matter
- **User said**: reach/distance shouldn't impact angle for now; possibly add later for accuracy

---

### 2. What Footwork/Positioning Could Add

| Benefit | Description |
|---------|-------------|
| **Distance** | In/out of range; step back = out of reach, step in = close |
| **Angle** | Off-line step = attacker's angle changes relative to defender |
| **Stability** | Good stance = less variance; moving = more |
| **Recovery** | Footwork affects recovery (e.g. lunging = longer recovery) |
| **Feint** | Step can sell feint (commit to one side) |

---

### 3. Abstraction Levels

#### 3.1 Minimal: Distance Band Only

**Model:** Each combatant has `distance_band`: "close" | "medium" | "far"

| Band | Effect |
|------|--------|
| Close | Full damage, full parry; maybe +alignment (blades easier to control) |
| Medium | Default; current behavior |
| Far | Reduced damage (glancing), harder to parry (extended arm) |

**Transition:** Attack or dodge moves band. Parry doesn't change band.

**Effort:** Low. Add 3-state; modifier tables per band.

#### 3.2 Moderate: Distance + Stance

**Model:** `distance_band` + `stance`: "balanced" | "committed" | "retreating"

| Stance | Effect |
|--------|--------|
| Balanced | Default variance, default recovery |
| Committed | Lower angle variance (committed to line), longer recovery |
| Retreating | Higher variance (moving), shorter recovery? Or faster gauge (retreat = defensive) |

**Transition:** Stance chosen at attack/dodge/parry. Or derived from last action.

**Effort:** Medium. Interacts with recovery, variance.

#### 3.3 Rich: Position Vector (Abstract)

**Model:** `position_angle` (0–360) + `distance` (0–1 normalized). Defines where combatant stands relative to opponent.

- Attacker at 0° (front), defender at 180° (front to attacker) = default.
- Attacker steps to 30° = off to the side; attack angle effectively +30°.
- Distance 0.8 = closer; 0.3 = farther.

**Effect on angle:** `effective_attack_angle = attack_angle + position_offset`. Step changes perspective.

**Effort:** High. New state; angle system must add position offset.

---

### 4. Implementation Options

#### Option A: Distance Band (Phase 1)

```gdscript
const DISTANCE_CLOSE: float = 0.0   # melee_range * 0.6
const DISTANCE_MEDIUM: float = 1.0 # melee_range * 1.0
const DISTANCE_FAR: float = 1.4    # melee_range * 1.4

# combatant["distance"] = 0.0–1.0 normalized
# Band: close if < 0.4, far if > 1.2, else medium
# Attack: move to close. Dodge: move to far. Parry: no change.
# Modifier: close = parry_align_mult 1.1; far = 0.9
```

**Pros:** Simple. Clear physical meaning.  
**Cons:** Doesn't change angle; only modifiers.

#### Option B: Step-on-Attack (Angle Offset)

**Model:** When attacker initiates attack, they "step" toward defender. Step direction = attack_line. Adds small `position_angle_offset` that persists for 1 exchange.

- Oberhau (high): step forward, offset 0°.
- Slash (left): step left, offset +20°.
- Effect: Defender's view of attack shifts. `effective_guard_angle += position_offset` when defender resolves parry.

**Pros:** Angle system gains position.  
**Cons:** Asymmetric (attacker moves; defender static?).

#### Option C: Both Step (Symmetric)

**Model:** Attacker steps on attack; defender steps on dodge or parry (small step).

- Parry: defender steps slightly to improve angle (if they have time).
- Dodge: defender steps to "far" + angle changes (duck = low, etc.).

**Pros:** Symmetric.  
**Cons:** More state; more transitions.

#### Option D: Stance Affects Variance Only

**Model:** No distance. Add `stance` from last action:

- After attack: "committed" for 0.5s → variance × 0.9.
- After parry: "recovering" (existing) → variance × 1.1.
- After dodge: "mobile" → variance × 1.05.

**Pros:** Minimal. Uses existing recovery_cause.  
**Cons:** No spatial representation.

---

### 5. Reach and Distance (Deferred)

User noted: reach/distance shouldn't impact angle for now. Possibly add later.

**When to add:**
- If parry success at "far" feels wrong (extended arm = weaker parry).
- If hit damage at "close" vs "far" needs differentiation.
- If weapon range (spear vs dagger) needs clearer in/out of range.

**Angle impact:** At far distance, attacker's blade arrives at a more oblique angle to defender's guard (geometry). Could reduce alignment. Defer until distance bands exist.

---

### 6. Recommended Phasing

| Phase | Content | Effort |
|-------|---------|--------|
| **1** | Distance band (close/medium/far) on combatant. Attack→close, dodge→far. Modifiers for parry/damage. | Low |
| **2** | Stance (balanced/committed/retreating) from last action. Affects variance. | Low |
| **3** | Position angle offset: step-on-attack adds offset. Effective attack/guard angle += offset. | Medium |
| **4** | Reach vs distance: at far, reduce parry alignment; at close, increase. | Low (after Phase 1) |

---

### 7. Integration with Angle System

- **Current:** attack_angle_deg, guard_angle_deg drive alignment, deflection, path.
- **With position:** effective_attack_angle = attack_angle_deg + attacker_position_offset. effective_guard_angle = guard_angle_deg + defender_position_offset.
- **With distance:** alignment *= distance_modifier(distance_band). Only when distance bands exist.

---

### References

- ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md
- CombatConstants: GUARD_TRANSITION_COST_SCALE
- WeaponConstants: melee_range per weapon

---

<a id="melee-simulation-ai-investigation"></a>

## Source: `MELEE_SIMULATION_AI_INVESTIGATION.md`

## Melee Simulation Games: Combat Decision-Making Investigation

An investigation into how complex simulation games—especially those with detailed melee weapon simulation or physics-based attacks—handle combat AI decisions.

---

### 1. Game Categories and Their Approaches

#### 1.1 Semi-Freeform / Directional Melee (Mount & Blade, Chivalry, Mordhau)

**Mount & Blade 2: Bannerlord** and similar games use **directional attacks** (choose attack direction before release) and **directional blocking** (block must match incoming attack direction).

##### Combat Mechanics

- **Attack:** Player/AI picks direction (left, right, overhead, thrust) and commits. Weapon animates from wind-up to release.
- **Block:** Defender must hold block in the correct direction. Shield users have an easier time (broader coverage).
- **Momentum, angle, weapon weight** influence damage (Bannerlord specifically).
- **Initiative:** Who attacks first matters; blocking or countering shifts advantage.

##### AI Decision-Making (Bannerlord)

- **Three-tier system:** Individual agents make real-time decisions; formation/orders affect aggression, not proficiency.
- **Opponent observation:** AI evaluates whether to attack or defend by watching opponent actions.
- **Directional awareness:**
  - If enemy is blocking → AI blocks incoming attack OR switches its own attack direction to avoid being blocked.
  - If enemy has shield → directional switching is less effective; AI adapts.
- **Skill scaling:** Higher melee skill → better understanding of stun durations, combat timings, enemy equipment. Skilled bots identify openings and switch attack directions.
- **Known issue:** At highest difficulty, AI is accused of reading player *inputs* directly rather than reacting to visual/animation cues—feels unfair.

**Relevance to Fallen Paths:** Bannerlord AI explicitly considers *opponent's block/guard state* when choosing attack direction. Your system has parry and guard; similar logic could weight "attack from unguarded angle" higher. Directional switching = "read defender's guard, pick counter."

---

##### Chivalry / Mordhau

- **Traces:** Weapon uses **trace/cast projected through animation** (line from handle to tip) for hit detection. Frame time turns weapon "on" for damage.
- **Feint, morph, chamber:** Advanced techniques consume stamina; AI would need to decide when to feint vs commit.
- **Initiative:** Blocking/countering shifts who has the next "turn" in the exchange.

**AI pattern:** Proximity-based target selection; behavior trees for move→attack cycles; animation events for damage frames. Less documented on high-level tactical decisions.

---

#### 1.2 Physics-Based Melee (Exanima, Hellish Quart, Blade & Sorcery)

##### Exanima

- **Physics-driven:** Characters use active ragdoll; weapons and bodies interact via physics.
- **Balance simulation:** "Dynamic balancer" lets characters maintain balance during combat, recover from falls, trip/slip realistically.
- **Combat loop:** Distance and timing. AI (and player) wait outside range, let opponent attack, dodge during swing, counter during recovery.
- **Companion AI:** Learns over time; gains experience and confidence.
- **Hit location:** Weapon tip deals most damage; reach matters.

**AI decisions:** Distance management, timing windows (recovery), pattern recognition. "Learnable" rather than deep—once you understand patterns, AI isn't complex. Emphasis on *when* to act, not *which* of many options.

---

##### Hellish Quart

- **Physics-driven blade collision:** Blades genuinely clash and block via engine physics, not predetermined animations.
- **Collision modes:** "Stable" vs "Precise" to handle sword interactions (reducing "sticky blade" issues).
- **Motion capture:** Thousands of fencing moves drive active ragdoll.
- **One-hit lethality:** Single well-placed attack can end fight if it penetrates guard.
- **AI tiers:** Multiple difficulty levels; "Fencer AI" tier for advanced opponents.
- **Guards, attack cancellation, positioning** are core.

**AI decisions:** Guard choice, attack selection from motion-captured library, positioning. Physics means AI can't "cheat" timing—must work within same collision constraints as player. Decisions are which guard to hold, which attack to launch, when to cancel.

---

##### Blade & Sorcery (VR)

- **Freeform melee:** Player controls limbs directly; weapon follows hand.
- **Physics:** Grab opponent or their weapon; distance judgment from VR.
- **No traditional AI decision model** for combat—enemies use animation-driven attacks; player's physical input drives response. Highlights the gap: when combat is *physics-based*, animation-driven AI is a poor fit.

---

#### 1.3 Realistic / HEMA-Inspired (Kingdom Come: Deliverance)

- **30+ target zones** per character; **4 armor layers**.
- **Physics reactions:** Swords clash and slide along armor; hits generate proper physical reactions.
- **Attack types:** Slash, stab, kick — directed at 5 body areas (head, left/right upper, left/right lower).
- **Combo system:** Fighting-game style chains; particular strikes chain to special finishers.
- **Stamina:** Depletes with actions; low stamina weakens attacks, breaks blocks, enables finishing moves.
- **Variables:** Armor, stamina, balance, fighting style, health, bleeding, fatigue, hunger.
- **Weapon authenticity:** Axes/maces vs armor; swords all-purpose; shields and reach matter.
- **Striking from unexpected angles** is more effective.

**AI decisions:** Not well documented publicly. Likely considers armor coverage, stamina state, exposed angles. Combo selection would need to chain valid follow-ups based on last hit.

**Relevance:** Your system has body parts, armor, bleeding—similar granularity. Kingdom Come's "unexpected angles" = target selection by armor exposure and guard gaps.

---

#### 1.4 Read-React / Fighting-Game Adjacent (For Honor)

- **Directional parry:** Parry in direction of incoming attack; tight timing window.
- **Reading:** Success depends on reading attack patterns and animations.
- **Visual cues:** Dark-red dial flashes when attack about to connect.
- **Character-specific timing:** Faster opponents (Orochi) parry shortly after swing; slower (Shugoki) wait until animation finishes.
- **Unblockables:** Can't block; can parry or dodge. Must read "on instinct" (no flash cue).
- **Post-parry:** Guard break → heavy damage; AI would need to know this sequence.

**AI decisions:** React to attack direction and timing; choose parry direction; choose follow-up (guard break, light, heavy). Timing windows are character-specific—AI needs lookup or learned data per matchup.

---

#### 1.5 Content-Driven with Polish (The Last of Us Part II)

- **Melee attack data:** Animations for attacker and defender; **starting and ending conditions** (range, facing, line of motion). If conditions not met, melee doesn't start.
- **Timeline events:** Hit frames, target tracking, invincibility windows—tags on animation timeline.
- **Melee behaviors:** One per NPC at a time. Each behavior has:
  - **Attack list** — which attacks can be started from this behavior
  - **Destination** — run to target, stay at distance, etc.
  - **Motion types** — run, walk, sprint within behavior
  - **Enter/exit conditions**
- **Design shift from Uncharted 4:** Longer attack tells, obvious telegraphing, dodge option. "Bear equal weight and complexity to gun combat."
- **Modular AI systems** for melee; emphasis on telegraphing so skilled players can react.

**AI decisions:** Behavior selects from attack list based on conditions. Attacks have prerequisites (range, facing). Exit conditions drive transitions. Highly content-driven but structured—behavior = mode, attack list = options.

**Relevance:** Your mental stack layers map to "behaviors" in a lighter form. Layer = behavior mode; options = attack list. TLOU2 uses explicit conditions per attack—you use `get_available_actions` similarly.

---

#### 1.6 Procedural / Simulation-Heavy (Dwarf Fortress)

- **Body part model:** Creatures = hierarchy of parts (limbs, organs, bones, tissue layers). Each part has states: healthy, bruised, torn, mangled, nonfunctional, broken, missing.
- **Damage types:** Slashing (cuts through tissue, severs); blunt (bruises, shatters bone); piercing (penetrates, high chance to hit organs).
- **Material properties:** Contact area, momentum, elasticity affect outcomes.
- **Defense:** Block (shield skill), Dodge (Dodger skill), Observer (anticipate attacks, reduce surprise).
- **Flow-based:** Attacks take ~6 ticks; red arrow warns defender. Block/dodge rolls determine outcome.
- **Adventure mode:** High Observer reveals *which limb or weapon* opponent will use next—explicit read of incoming attack.

**AI decisions:** DF doesn't have tactical AI in the same sense—creatures act on instincts/needs. But the *resolution* model is rich: body parts, materials, skills. Observer skill = "I know what's coming" — relevant for parry/defend weighting in your system.

---

#### 1.7 Systemic vs Content-Driven (Playtank Framework)

The [Playtank "Building Systemic Melee"](https://playtank.io/2024/08/12/building-systemic-melee/) article distinguishes:

| Type | Description | Player Activities |
|------|--------------|-------------------|
| **Feature-Rich** | God of War, Ghost of Tsushima. Content-driven; cues and timing. | Wait for animations; retry; look for hints. |
| **Content-Based** | Soulsborne, Street Fighter. Learn attack sequences, reach, frames. | Learn content; anticipate opponent. |
| **Semi-Freeform** | Chivalry, Mount & Blade. Directional input; weapon guidance. | Judge distance; guide direction; positioning. |
| **Ragdoll/Physics** | Exanima, Hellish Quart, Gang Beasts. Simulation-driven. | Wait for simulation; learn simulation rules. |
| **Systemic** | Stim/response; weapon "injects" state into hit object. Result depends on what's hit. | Modular; object-rich. |

**Hit detection options:**

1. **Frame time** — weapon "on" for damage during specific animation frames
2. **Trace/cast** — line or sweep from handle to tip; intersection = hit
3. **Collision volume** — physics collider; compound (crossguard, blade, pommel) or single mesh
4. **Attack direction** — angle from centerpoint (navel) to determine zone hit

**Defense options:** Guards/stances, parry, block, interrupt, riposte, dodge.

**Footwork:** Push/pull, circling, positioning. Loop: Circling → Push/Pull → Positioning → Attack.

---

### 2. Decision-Making Patterns Across Games

#### 2.1 Observation → Response

| Game | What AI Observes | What AI Decides |
|------|------------------|-----------------|
| **Bannerlord** | Opponent block direction, shield presence | Attack direction, block direction |
| **For Honor** | Attack direction, animation phase | Parry direction, dodge, follow-up |
| **Exanima** | Opponent range, swing state, recovery | When to step in, when to strike |
| **Hellish Quart** | Guard, blade position (physics) | Guard choice, attack from library |
| **Kingdom Come** | Armor coverage, stamina, angle | Target zone, attack type |
| **TLOU2** | Range, facing, conditions | Which behavior, which attack from list |
| **Dwarf Fortress** | (Instinct-driven) | Block/dodge rolls; Observer reveals incoming |

#### 2.2 Common Decision Axes

1. **Target selection** — Who to attack (Bannerlord: first available; many games: closest or most damaged)
2. **Attack direction/type** — Which strike (Bannerlord: counter block; For Honor: mix-up; KC: exposed angle)
3. **Defense choice** — Block, parry, dodge (Bannerlord: match direction; For Honor: match direction + timing; Exanima: move out of the way)
4. **Timing** — When to act (Exanima: recovery windows; For Honor: parry window; TLOU2: attack tells)
5. **Positioning** — Distance, angle (Exanima: stay outside range; Chivalry: weapon reach; KC: unexpected angle)
6. **Stamina/resources** — (Mordhau, KC: stamina; TLOU2: behavior constraints)

#### 2.3 Physics vs Animation

- **Animation-driven:** Decisions trigger animations; hit detection tied to frame events. Easier to balance; predictable.
- **Physics-driven:** Decisions affect rigidbodies/constraints; outcomes emerge from simulation. Harder to tune; can feel unfair if physics is chaotic.
- **Hybrid:** Some games use animation for "when" and physics for "where" (e.g., trace along animated weapon path). Chivalry traces through animation.

---

### 3. Implications for Fallen Paths

#### 3.1 Your Current System (from codebase)

- **Gauge-based readiness** — who can act when
- **Wind-up → execute** — commitment before resolution
- **Defense:** Passive dodge (perception/agility), passive parry (readiness/capacity vs momentum)
- **Body parts,** armor, bleeding, damage types
- **Attack types:** Cut, thrust, blunt; archetypes (quick_slash, overhead, etc.)
- **No directional guard** — guard is a scalar (0.4 when attacking, rises when idle)
- **No explicit "attack direction"** — attack_type and part selection, not left/right/overhead

#### 3.2 Patterns You Could Adopt

| Pattern | Game Source | Implementation Idea |
|---------|-------------|----------------------|
| **Counter block/guard** | Bannerlord | If defender has high guard on a part, weight attacking a different part or a thrust (harder to block uniformly) |
| **Recovery window** | Exanima | Enemy in RECOVERING = high-priority target; short opportunity window |
| **Exposed angle** | Kingdom Come | Score target parts by armor coverage, current guard; "unexpected" = unguarded |
| **Observer/read** | Dwarf Fortress | Perceive "enemy winding up" → weight parry. (You have `_is_being_targeted`.) |
| **Behavior + attack list** | TLOU2 | Mental stack layer = behavior; `get_available_actions` = attack list; conditions filter |
| **Stamina-like** | Mordhau, KC | Gauge already acts like stamina; intensity/commitment affects recovery. Could add "heavy attack = more gauge cost" for trade-off |
| **Timing windows** | For Honor | Parry has reaction window; your passive parry uses reaction_time vs effective_wind_up. Could expose "parry difficulty" per attack type. |

#### 3.3 What Doesn't Map Directly

- **Directional blocking:** You don't have left/right/overhead guard. Adding it would be a large change. Without it, "switch attack direction" from Bannerlord doesn't apply literally—but "attack unguarded part" does (body part targeting).
- **Physics blade collision:** Hellish Quart/Exanima-level physics would require a different engine/approach. Your system uses resolved outcomes (hit/parry/miss) not continuous physics.
- **Combo chains:** Kingdom Come combos are scripted sequences. You could add "last attack type" and weight follow-ups (e.g., thrust after cut), but it's new content.

---

### 4. Summary: Decision-Making Priorities in Simulation Melee

Complex melee simulation games tend to prioritize:

1. **Observe opponent state** — block direction, guard, recovery, stamina, exposed parts
2. **Choose action that counters or exploits** — attack unguarded, parry incoming, wait for recovery
3. **Respect timing** — act in valid windows; don't commit when opponent can punish
4. **Manage resources** — stamina, gauge, initiative
5. **Use positioning** — distance, angle (when the system supports it)

For **physics-based** games, decisions are often simpler (Exanima: "when to strike") because the simulation handles the rest. For **animation-driven** games with directional combat (Bannerlord, Mordhau), AI needs to track opponent guard and pick counter-directions. For **content-driven** games (TLOU2), behaviors and attack lists with conditions structure choices.

**Fallen Paths** sits between: animation-driven resolution (wind-up, execute) but with body parts, armor, and defense rolls. The mental stack + opportunity scoring (enemy in recovery, low health, unguarded part) aligns with Bannerlord and Kingdom Come patterns. Observer-style "enemy winding up on me" → parry fits Dwarf Fortress and your `_is_being_targeted` design. You don't need directional guard to benefit—**body part targeting** and **attack type** (thrust vs cut) can serve the same role as "angle" in other games.

---

### References

- Mount & Blade 2: Bannerlord AI overhaul, Steam discussions, AltChar
- Exanima: Steam, store page, community guides
- Kingdom Come: Deliverance: Gaming Nexus, forum posts, combat system
- Chivalry, Mordhau: GamePressure, Toolify, Playtank
- Hellish Quart: Wikipedia, Rock Paper Shotgun, The Gamer
- For Honor: Inverse, VG247, Oreate AI
- The Last of Us Part II: Game Developer (GDC 2021)
- Dwarf Fortress: Wiki (body parts, combat skill, dodging)
- Playtank: "Building Systemic Melee" (2024)
- ACM: "Development of Tactical Level AI for Melee and Range Combat" (2020)
- Fallen Paths: COMBAT_ATTACK_PARRY_DODGE_FLOW.md, CombatManager.gd

---

<a id="mental-stack-engagement-investigation"></a>

**Shipped slice (Tier 4.3):** salience + focus + AI stack + yomi — see [Tier 4.3 live path](#tier-43-mental-stack--combat-attention-live-path). **`STATE_IN_FLURRY`** / bind expansion below remain **design options**.

## Source: `MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md`

## Mental Stack AI & Engagement System Investigation

An investigation into (1) fighting-game-style mental stack decision-making for AI, and (2) an engagement/flurry system where units become locked in exchanges before returning to neutral.

---

### Part 1: Mental Stack AI Decision-Making

#### What Is "Mental Stack" (Fighting Games)

The **mental stack** is the cognitive load a player must manage during a match—all the options, threats, and decisions that must be tracked simultaneously. Pro players (e.g., Daigo, Tokido, Fuudo) describe it as:

- **Prioritization:** Focus on the most critical threats and opportunities, not everything at once
- **Automation:** Fundamentals (anti-air, basic punishes) become automatic, freeing mental capacity for higher-level decisions
- **Matchup knowledge:** Knowing opponent options narrows what to consider
- **Stress response:** Tournament pressure or unfamiliar situations can cause mental overwhelm ("mind went blank")
- **Defense vs offense:** Stronger defense lowers mental stack; oppressive offense (e.g., Street Fighter 5) increases it

For AI, this translates to: **model which options matter most at any moment, and let lower-priority decisions be cheap or automatic.**

---

#### Implementation Approaches

##### A. Layered Priority Stack (Explicit Mental Stack)

**Idea:** Maintain an ordered stack of "what I'm thinking about right now." Top of stack = highest priority decision. Lower items are only considered when higher ones are satisfied or irrelevant.

```
Stack (top = highest priority):
  1. "Ally in immediate peril" → must treat or hold pressure
  2. "I'm being targeted by wind-up" → parry/defend vs counter
  3. "Engaged opponent attacking me" → respond in exchange
  4. "Threatened ally" → peel or finish enemy
  5. "Best target to attack" → pick from available enemies
  6. "Default" → attack nearest / first available
```

**Implementation:**

- Each layer has a **condition** (when it applies) and a **decision function** (what to do)
- When it's the unit's turn, scan from top to bottom; first satisfied condition drives the choice
- Layers can "consume" mental capacity (e.g., "engaging" uses 2 of 3 stack slots)

**Pros:** Directly models pro-player prioritization; easy to debug (inspect stack); tunable depth  
**Cons:** Needs good condition design; can feel rigid if layers are too coarse

---

##### B. Threat-Weighted Option Filtering

**Idea:** Don't use an explicit stack. Instead, assign a **threat score** and **opportunity score** to each option. Options below a threshold are pruned before decision-making.

```
For each potential action:
  threat_urgency = f(who_is_attacking_me, ally_bleeding, who_i_am_attacking)
  opportunity_value = f(kill_potential, part_exposure, weapon_matchup)
  if threat_urgency > THRESHOLD: consider defensive/medical first
  else: pick from options weighted by opportunity_value
```

**Implementation:**

- `get_available_actions` returns all options; a new `filter_and_rank_actions(actions, combatant_id)` applies threat/opportunity scoring
- Medical urgency already exists; extend to "I am being wind-up targeted" (high threat) and "enemy in recovery" (high opportunity)
- Prune bottom 50% of options by combined score before `pick_weighted_action`

**Pros:** Fits current `pick_weighted_action` pipeline; continuous rather than discrete layers  
**Cons:** Threshold tuning; less explicit "mental stack" semantics

---

##### C. Finite State Machine with Context

**Idea:** FSM states map to "what mode is my mind in." Each state has different decision logic. Transitions are driven by game state (e.g., "ally hurt" → MEDICAL_PRIORITY, "enemy winding up on me" → DEFENSIVE_PRIORITY).

States (examples):

- `NEUTRAL` — pick best attack target, or medical if urgent
- `DEFENSIVE` — parry-weighted when someone winding up on me
- `MEDICAL_PRIORITY` — self or ally in peril
- `ENGAGED` — in flurry; respond to exchange (see Part 2)
- `PRESSURING` — I just hit; consider follow-up vs reset

**Implementation:**

- Add `mental_state` (or `ai_mode`) to combatant dict
- Each state has its own `get_actions_for_state` / `pick_action_for_state`
- Transition logic in `_process` or when `action_resolved` fires

**Pros:** Familiar pattern; integrates cleanly with engagement (ENGAGED state)  
**Cons:** State explosion if too many modes; transitions can feel abrupt

---

##### D. Yomi Layers (Read/Counter-Read)

**Idea:** Fighting game "yomi" = reading what the opponent will do and choosing counters. Model this as explicit layers: "I think they will X, so I do Y."

- **Layer 0:** Default (attack, or defend if obvious threat)
- **Layer 1:** "They often parry when I attack" → feint / change target / delay
- **Layer 2:** "They expect my feint" → commit to real attack

**Implementation:**

- Store per-opponent or per-matchup **tendency** (e.g., `opponent_parry_rate`, `opponent_target_preference`)
- When choosing attack: if `opponent_parry_rate > 0.6`, weight feint or secondary target higher
- Simple memory: last N actions per opponent; Bayesian-style update of tendencies

**Pros:** Captures mind-games; makes AI feel adaptive  
**Cons:** Needs enough data per opponent; can feel random if tendencies are noisy

---

##### E. Heuristic Decision Tree (Fast, No Learning)

**Idea:** Single decision tree with clear branches. Each node checks a condition and either picks an action or recurses.

```
if ally_in_immediate_peril and can_help: → medical
else if enemy_winding_up_on_me and gauge_full: → parry or counter
else if engaged_with_opponent: → exchange_action
else if enemy_in_recovery: → attack_that_enemy
else: → pick_from(attack_targets)
```

**Implementation:**

- Refactor `pick_weighted_action` into a `decide_action(combatant_id)` that returns a single action
- Inner logic uses existing `_is_in_immediate_peril`, `get_available_actions`, and new helpers like `_is_being_targeted(combatant_id)`, `_is_engaged(combatant_id)`

**Pros:** Simple, fast, debuggable; matches "narrow to what matters"  
**Cons:** Can feel predictable; no adaptation

---

#### Recommendation for Fallen Paths

**Short term:** Combine **A (Layered Stack)** with **E (Heuristic Tree)**. Implement a small stack (3–5 layers) with conditions that map to current systems:

1. Medical peril (existing urgency)
2. "Enemy winding up on me" (parry weighting—already have parry as action)
3. Engagement response (when engagement exists—Part 2)
4. Best attack target (threat/opportunity scoring)
5. Default (current behavior)

**Medium term:** Add **D (Yomi)** by tracking opponent action history and tuning weights (e.g., parry more vs opponents who attack predictably).

---

### Part 2: Engagement & Flurry System

#### Concept

When a unit **attacks** someone, they become **engaged** with that target. While engaged:

- Attacks can be exchanged in a **flurry** — multiple blows in quick succession
- The exchange continues until a **disengagement condition** (one side retreats, both recover, hit/miss/parry creates reset)
- After disengagement, both return to **neutral** (normal gauge, normal turns)

This mirrors HEMA "binding" or "corps-à-corps" — close-quarters exchange where both parties are committed.

---

#### Design Options

##### Option 1: Engagement = Soft Lock (Target Preference Only)

**Idea:** "Engagement" is just a flag: `engaged_with_id`. No mechanical change. AI and display treat engaged pair as "in a duel." Flurry is cosmetic (animations suggest exchange) but mechanically it's the same 1-attack-per-wind-up.

- On attack → `attacker.engaged_with_id = target_id`, `target.engaged_with_id = attacker_id`
- Clear when: target dies, attacker chooses new target, or after N seconds
- `pick_weighted_action` weights attacking engaged target higher (or lower, for "break off" behavior)

**Pros:** Minimal code; easy to add  
**Cons:** No actual flurry; engagement is flavor only

---

##### Option 2: Engagement Enables Counter Window

**Idea:** When A attacks B, B gets a **counter window** — if B's gauge is ready (or partially ready) during A's wind-up or recovery, B can immediately counter with a reduced-cost or guaranteed-order attack.

- Engagement formed when A begins wind-up on B
- During A's wind-up or early recovery, B gets `can_counter = true`
- Counter consumes less gauge (e.g., 50%) or uses a "counter" action type
- After counter (or if B doesn't counter), both enter recovery; engagement ends

**Pros:** Adds real tactical depth; rewards reading the opponent  
**Cons:** Order of operations (who counters whom) needs careful design; can favor defender

---

##### Option 3: Flurry Sub-Phase (Multiple Exchanges)

**Idea:** When A attacks B, instead of one attack→result→recovery, enter a **flurry phase**. Both A and B exchange blows in quick succession (e.g., 2–4 attacks total) before returning to normal turns.

**Flow:**

1. A attacks B → engagement starts
2. Flurry phase begins:
   - Resolve A's attack (hit/parry/miss/dodge)
   - If B alive and can respond: B gets **instant** counter (or at reduced wind-up)
   - Resolve B's counter
   - If A alive and can respond: A gets instant counter
   - … repeat until max flurry length (e.g., 4) or disengagement condition
3. Disengagement: both go to recovery; gauge reset as normal

**Disengagement conditions:**

- One combatant dies
- One combatant is "broken" or stunned (e.g., hard hit, parry break)
- Max flurry length reached
- One side "retreats" (new action: break engagement, costs gauge or adds recovery)

**Pros:** Dramatic "clash" feel; rewards commitment  
**Cons:** Complex ordering; can make combat feel bursty; need rules for 2v1 (who gets countered)

---

##### Option 4: Binding / Corps-à-Corps (HEMA-Inspired)

**Idea:** Weapons "bind" on parry or deflected hit. While bound, both are in close range; next action is a **bind resolution** (push, cut, thrust from bind) rather than a full swing.

- On parry_deflect or certain deflected outcomes → `bound_with_id`, `bound_until` timestamp
- While bound: only "bind resolution" moves available (short thrust, push, disarm attempt)
- Bind resolution has different damage/risk profile
- After resolution or timeout: back to normal

**Pros:** Very HEMA-flavored; distinct mechanical phase  
**Cons:** Requires new move types and UI; may slow pace

---

##### Option 5: Engagement as "Combat Pair" With Shared Timeline

**Idea:** Engaged pairs share a **micro-timeline**. Instead of global gauge fill, the pair has a shared "exchange meter" that fills during the flurry. When it maxes, both disengage and return to global turn order.

- Engagement: (A, B) pair
- Each blow in the flurry adds to exchange_meter
- Exchange resolves as in Option 3, but disengagement is driven by meter + conditions
- Non-engaged units continue normal gauge fill; they can "interrupt" by attacking someone in a flurry (target gets hit, flurry ends?)

**Pros:** Clear phase boundaries; allows external interruption  
**Cons:** Two overlapping time systems (global gauge + exchange meter)

---

#### Recommendation for Fallen Paths

**Phase 1:** Implement **Option 1 (Soft Lock)** to add engagement tracking and AI preference. Low risk, immediate value for "who is dueling whom" display and AI.

**Phase 2:** Add **Option 2 (Counter Window)**. When B is engaged and A is in wind-up, B can spend partial gauge for a counter. This creates real engagement payoff without full flurry complexity.

**Phase 3 (if desired):** Experiment with **Option 3 (Flurry Sub-Phase)** for a single engagement type (e.g., when both have full gauge and one attacks). Cap at 2–3 exchanges initially to avoid runaway chains.

---

### Integration With Current System

#### Current State (from codebase)

- **CombatManager:** Gauge-based readiness; states `WAITING`, `WIND_UP`, `RECOVERING`, etc.
- **pick_weighted_action:** Medical by urgency; attacks equal weight (1.0)
- **get_available_actions:** Attack options = (move_id, target_id) for each weapon move and each enemy
- **Parry:** Active choice when someone winding up (or passive per PARRY_SYSTEM_OPTIONS)

#### Hooks for Mental Stack

1. **`_is_being_targeted(combatant_id)`** — check if any enemy has `pending_attack.target_id == combatant_id`
2. **`_get_mental_stack(combatant_id)`** — return ordered list of (condition, decision_fn) for current state
3. **Refactor `pick_weighted_action`** — first run stack; if a layer returns an action, use it; else fall through to current weighted pick

#### Hooks for Engagement

1. **Combatant dict:** Add `engaged_with_id: int = -1`
2. **`_begin_attack_with_target`** — set `attacker.engaged_with_id = target_id`, `target.engaged_with_id = attacker_id`
3. **After `action_resolved`** — optionally clear engagement (e.g., on miss, dodge, or deflected) or maintain for counter window
4. **`get_available_actions`** — when engaged, could add "break engagement" or prioritize engaged target
5. **Flurry (Option 3):** New state `STATE_IN_FLURRY`; `_process` handles flurry sequence instead of single attack resolution

---

### References

- Daigo, Tokido, Fuudo on mental stack: [EventHubs](https://www.eventhubs.com/news/2021/apr/11/daigo-tokido-mental-information/)
- Fighting game AI (heuristics, FSM): [William Thyer](https://williamthyer.github.io/posts/2022/1/heuristic_ai/)
- Killer Instinct Shadow AI: [Game Developer](https://www.gamedeveloper.com/programming/the-killer-groove-the-shadow-ai-of-killer-instinct)
- Fire Emblem Engage Break: weapon triangle, counter prevention
- NWN2 Flurry: 2-second combat units, attacks per flurry
- Yomi: [Smogon "Yomi and You"](https://www.smogon.com/forums/threads/yomi-and-you.11746/) (read/counter-read)
- Current code: `CombatManager.gd`, `AttackResolver.gd`, `BattleScene.gd`, `PARRY_SYSTEM_OPTIONS.md`

---

<a id="mental-stack-implementation-comparison"></a>

## Source: `MENTAL_STACK_IMPLEMENTATION_COMPARISON.md`

## Mental Stack Implementation: Approaches vs. Industry Systems

A detailed comparison of proposed mental stack approaches against how real games and AI systems handle layered/priority-based decision-making, with recommendations for Fallen Paths.

---

### 1. Summary of Proposed Approaches (from MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md)

| Approach | Core Idea | Decision Flow |
|----------|-----------|---------------|
| **A. Layered Priority Stack** | Ordered stack; first satisfied condition wins | Scan top→bottom; first layer that applies drives choice |
| **B. Threat-Weighted Filtering** | Score options by threat/opportunity; prune low scorers | Continuous scoring; filter then weighted random |
| **C. FSM with Context** | Discrete mental states (NEUTRAL, DEFENSIVE, etc.) | State machine; each state has its own pick logic |
| **D. Yomi Layers** | Read opponent tendencies; counter-read | Adapt weights based on opponent history |
| **E. Heuristic Decision Tree** | Single if/else tree | Hard-coded condition→action branches |

---

### 2. Industry Systems: How Real Games Do It

#### 2.1 Halo 2 / Bungie (GDC 2005)

**Architecture:** Hierarchical finite state machine / behavior DAG (~50 behaviors).

**Decision model:** **Prioritized-list** — march down a prioritized list of children; the first one that *can* run does. Higher-priority siblings can **interrupt** the current behavior on every tick.

**Relevancy:** **Binary** (can run / cannot run), not analog scores. Damian Isla noted that "tweaking floats to get a specific set of priorities is feasible when there are two or three choices, but when there are twenty or more it is almost impossible."

**Behavior impulses:** Free-floating triggers that reference full behaviors. Used when priority depends on context—e.g., "fight normally, *unless* player is in vehicle, then get in vehicle." Separates the *condition* from the *behavior*, placed at a specific point in the priority list.

**Key quote:** *"We think first of the best thing to do, but failing that we will consider the second best, the third best and so on. Whichever we choose, when a better option opens up, we immediately switch to it."*

**Design principles:** Explicitness over implicitness; hackability (impulses can run arbitrary code); take something that works and vary from it.

**Mapping to our approaches:**  
- **A (Layered Stack)** ≈ Halo's prioritized-list. Same idea: ordered list, first applicable wins, higher can interrupt.  
- **E (Heuristic Tree)** ≈ simplified version of Halo's tree without the DAG structure.

---

#### 2.2 Guild Wars 2 / Infinite Axis Utility System (IAUS)

**Architecture:** Utility-based action selection. Each action has a **Decision Score** = geometric mean of consideration scores × weight.

**Flow:**
1. **Inputs** normalized to [0–1] (health 25/100 → 0.25, ammo 15/30 → 0.5, etc.)
2. **Considerations (axis):** Each action has 1+ considerations. Same input can mean different things per action (e.g., ammo=0 → Shoot scores 0, Reload scores 1)
3. **Response curves:** Logistic (threshold), Gaussian (sweet spot), Linear, Quadratic, Logit
4. **Combination:** Geometric mean (not naive multiply — avoids penalizing actions with many considerations)
5. **Weights:** 5 = emergency, 2–3 = important, 1 = normal. Emergency can override even when GM is lower.

**Example:** Retreat GM=0.4, Weight=5 → 2.0; Reload GM=0.9, Weight=1 → 0.9. Retreat wins despite lower GM.

**Design goals:** Data-driven; designers configure curves/weights without code; scales to hundreds of NPCs (MMO combat).

**Mapping to our approaches:**  
- **B (Threat-Weighted Filtering)** ≈ utility-lite. Scoring options, pruning, weighted choice. Full IAUS would add curves, geometric mean, and explicit weights.  
- Medical urgency in Fallen Paths already resembles a single consideration with an urgency curve.

---

#### 2.3 The Sims (Needs-Based / Marginal Utility)

**Architecture:** Needs increment over time; each need has a **non-linear impact** on happiness. Pick action that yields the *greatest happiness increase* if taken.

**Flow:**
1. Needs: sleep, eat, social, etc. Each has a formula (e.g., `-eat_need²` for hunger impact)
2. For each possible action: compare current happiness impact vs. impact *after* doing the action
3. Choose action with largest marginal utility

**Key insight:** Marginal utility — first bites of food have high value, then diminishing returns. Same for sleep, toilet, etc. Non-linear curves prevent "eat constantly" or "never eat."

**Mapping to our approaches:**  
- **B (Threat-Weighted)** — same family. Continuous scoring; non-linear escalation. Sims uses "happiness deltas" rather than raw scores.  
- Medical urgency in Fallen Paths is analogous: bleeding urgency escalates non-linearly; pending_retry adds a spike.

---

#### 2.4 Subsumption Architecture (Brooks, Robotics)

**Architecture:** Layered reactive control. **Higher layers subsume (suppress) lower layers** without stopping them. Bottom-up: obstacle avoidance runs always; wander runs when nothing else inhibits it; explore runs on top.

**Flow:** Parallel processes; each layer competes for control. External sensor input mediates priority. Lower layers = reflexes; higher = task-oriented.

**Mapping to our approaches:**  
- **A (Layered Stack)** — similar priority idea but inverted: subsumption = "higher inhibits lower"; our stack = "higher preempts lower." Same outcome: high-priority things win.  
- **C (FSM)** — subsumption is more parallel/reactive; FSM is sequential state transitions. Different philosophy.

---

#### 2.5 Behavior Trees vs. FSM (General)

**Behavior Trees:**
- Modular; implicit transitions via parent control nodes
- Adding behaviors = add subtree; no need to rework transitions
- Depth-first traversal; naturally responsive to state changes
- Parallel nodes for concurrent tasks
- Scale better than FSM for complex combat (many states, many transitions)

**FSM:**
- Explicit transitions; risk of "spaghetti" and lock-in
- State explosion when many conditions affect many states
- Good for small, clear mode sets (e.g., 3–5 mental states)

**When to use which:** BTs for large, evolving behavior sets; FSM for a small number of distinct "modes" (e.g., NEUTRAL, DEFENSIVE, MEDICAL_PRIORITY).

**Mapping to our approaches:**  
- **C (FSM with Context)** — classic FSM. Viable if we keep states to ~5.  
- **A (Layered Stack)** — can be implemented *inside* a BT as a prioritized selector, or standalone.

---

### 3. Comparative Analysis

| Criterion | A. Layered Stack | B. Threat-Weighted | C. FSM | D. Yomi | E. Heuristic Tree |
|-----------|------------------|--------------------|--------|---------|---------------------|
| **Industry precedent** | Halo 2 (prioritized-list), subsumption | GW2 (IAUS), Sims (marginal utility) | Halo (HFSM), many games | Fighting games, MCTS/planning | Common in smaller games |
| **Fits Fallen Paths pipeline** | High — drop-in before pick_weighted | High — extends current weights | Medium — new state vars, transitions | Low — needs opponent memory | High — refactor of pick logic |
| **Tunability** | Add/remove/reorder layers | Add considerations, tune curves | Add states, transition rules | Add tendency trackers | Add branches |
| **Data-driven potential** | Low (order is code) | High (scores/curves configurable) | Medium (states configurable) | Medium (tendency params) | Low (code-bound) |
| **Debugging** | Easy (inspect stack, which layer fired) | Medium (inspect scores) | Easy (current state visible) | Hard (why did tendency change?) | Easy (trace branches) |
| **Gray-area handling** | Poor — binary layer match | Excellent — continuous scores | Medium — state boundaries | Good — gradual adaptation | Poor — binary branches |
| **Scalability** | Good — O(layers) | Good — O(actions × considerations) | Risky — state explosion | Medium — memory per opponent | Good for small trees |
| **Interrupt semantics** | Natural (higher wins) | Via score (emergency weight) | Via transition | N/A | Via condition order |

---

### 4. Fit for Fallen Paths

#### Current System (CombatManager)

- **get_available_actions:** Returns flat list of {target_id, move_id, target_part}
- **pick_weighted_action:** Medical actions get urgency-based weight; attacks get weight 1.0. Weighted random selection.
- **Combat phase:** No parry as explicit action in combat phase (parry is when someone winds up on you — see PARRY_SYSTEM_OPTIONS)
- **Medical phase:** Urgency, pending_retry, bleeding rate already drive weights

#### Gaps

1. **Attacks are equal weight (1.0)** — no targeting intelligence (who to attack, which move)
2. **No "I'm being targeted" awareness** — defender doesn't weigh parry/defend differently
3. **No engagement awareness** — when engagement exists, no preference for engaged target
4. **Medical works well** — urgency and pending_retry already implement a form of prioritization

#### What We Need

- A way to **prioritize** medical > defend (when targeted) > attack best target > default
- **Binary or near-binary** for hard overrides (e.g., "ally in peril → must help")
- **Scoring** for gray areas (e.g., which enemy to attack when several are valid)
- **Minimal refactor** — avoid rewriting get_available_actions or resolve_action

---

### 5. Option-by-Option Assessment

#### A. Layered Priority Stack

**Verdict:** **Best fit** for Fallen Paths.

**Why:**
- Matches Halo 2's prioritized-list — industry-proven for combat
- Binary relevancy per layer avoids float tweaking (Halo's lesson)
- Natural interrupt: medical peril always beats attack; "being targeted" beats "pick target"
- Fits existing pipeline: layers can **filter** actions (e.g., layer 1 returns only medical) or **override** (e.g., layer 2 says "do parry")
- Easy to debug: log which layer fired

**Implementation sketch:**
```
Layers (order = priority):
  1. Ally in immediate peril + can help → restrict to medical, pick by urgency (existing)
  2. Enemy winding up on me + parry available → prefer parry (or restrict to parry+attack)
  3. Engaged + engagement actions available → prefer engaged target
  4. Attack options → score by opportunity (enemy in recovery, low health, etc.)
  5. Default → current equal-weight attack
```

**Risk:** Can feel rigid if layers are too coarse. Mitigate by allowing layer 4 to use continuous scoring (threat-weighted) for attack target selection.

---

#### B. Threat-Weighted Option Filtering

**Verdict:** **Strong complement** to A, or alternative if you prefer full utility.

**Why:**
- Guild Wars 2 proves it scales; Sims proves marginal utility works
- Handles gray areas (which enemy? which move?) that layers treat clumsily
- Natural extension of current medical weighting — same pattern for attacks

**Drawback for Fallen Paths:**
- Need to design considerations for attacks: distance (N/A in turn-based?), enemy health, enemy state (recovering?), weapon matchup, engaged status
- Threshold tuning can be brittle ("why did it pick X when Y was clearly better?")
- Less explicit than layers for hard overrides — emergency weight 5 works but is less clear than "layer 1 always wins"

**Best use:** Implement **inside** layer 4 of the stacked approach — use utility scoring for "best attack target" while layers 1–3 handle overrides.

---

#### C. FSM with Context

**Verdict:** **Viable but heavier** than stacked layers.

**Why:**
- Clean mental model: "I'm in DEFENSIVE mode, so I parry more"
- Integrates with engagement (ENGAGED state)

**Drawbacks:**
- Requires transition logic: when does DEFENSIVE → NEUTRAL? When wind-up ends? Tick delay?
- State explosion: NEUTRAL, DEFENSIVE, MEDICAL, ENGAGED, PRESSURING = 5 states. Add "ally threatened" and you need MEDICAL vs THREATENED_ALLY vs both?
- Transitions can feel abrupt ("I was attacking, now I'm defending" — need hysteresis?)
- More code than layers: each state has its own pick logic; transitions need maintenance

**When to use:** If you later add complex modes (e.g., "berserker" vs "cautious" personality) that affect many decisions, FSM is a good container. For initial mental stack, layers are simpler.

---

#### D. Yomi Layers

**Verdict:** **Later phase**, not first implementation.

**Why:**
- Adds adaptation and mind-games
- Requires opponent action history and tendency estimates
- Current system has no feint/secondary-target mechanics — yomi would need something to "read" and "counter"

**When to add:** After layers (and optionally engagement) are in place. Use for: "opponent parries 60% of the time → weight feint higher" or "opponent targets my head → guard head." Needs data structures (per-opponent history) and possibly new actions (feint).

---

#### E. Heuristic Decision Tree

**Verdict:** **Equivalent to A** with different expression.

**Why:**
- Same logic: if peril → medical; else if targeted → parry; else if engaged → X; else attack
- Tree = flattened stack. Stack = ordered list of (condition, action).
- Tree is more verbose (nested if/else); stack is more declarative (list of layers)

**When to use:** If you prefer a single function with explicit branches and don't want a layer registry. Functionally identical to A.

---

### 6. Recommended Implementation Path

#### Phase 1: Layered Priority Stack (Approach A)

1. **Define layer registry** (array of `{condition: Callable, decision: Callable}`)
2. **Conditions:**
   - `ally_in_peril_and_can_help(combatant_id)` — existing `_is_in_immediate_peril` + can perform medical
   - `enemy_winding_up_on_me_and_can_parry(combatant_id)` — new `_is_being_targeted` + parry in actions
   - `engaged_and_has_engaged_actions(combatant_id)` — when engagement exists
   - `has_attack_options(combatant_id)` — always true in combat if can attack
3. **Decisions:**
   - Layer 1: restrict to medical, use existing `pick_weighted_action` on subset
   - Layer 2: prefer parry (or restrict to parry + attacks, weight parry high)
   - Layer 3: prefer attacking engaged target (when engagement added)
   - Layer 4: use threat/opportunity scoring for attacks (optionally B-style)
   - Layer 5: current equal-weight `pick_weighted_action`
4. **Entry point:** Replace direct `pick_weighted_action(actions, id)` with `decide_action_via_stack(actions, id)` that iterates layers and returns first match

**Effort:** ~1–2 days. New helpers: `_is_being_targeted`, `_get_mental_stack_layers`. Minimal changes to `_process` and `BattleScene`.

---

#### Phase 2: Threat/Opportunity Scoring for Attack Selection (Approach B, inside Layer 4)

1. For each attack action, compute:
   - `enemy_in_recovery` → bonus
   - `enemy_low_health` → bonus (kill potential)
   - `enemy_engaged_with_me` → bonus or penalty (commit vs peel)
   - `pending_retry` / threatened ally → bonus to attack that enemy
2. Multiply into weight; use in weighted random
3. Add response curves if desired (e.g., logistic for "low health urgency")

**Effort:** ~1 day. Extends layer 4; no new architecture.

---

#### Phase 3 (Optional): Yomi (Approach D)

1. Per-combatant or per-opponent-pair: store last N actions
2. Compute simple tendencies: parry_rate, target_preference (head vs body)
3. When picking attack: adjust weights by tendency (e.g., if parry_rate > 0.6, weight feint or secondary target)
4. Requires feint or equivalent action to be meaningful

**Effort:** ~2–3 days. New data structures, tuning.

---

### 7. Final Recommendation

**Implement Approach A (Layered Priority Stack) first**, with Layer 4 using Approach B (Threat-Weighted) for attack target selection.

**Rationale:**
- Halo 2's prioritized-list directly validates the layered approach for combat AI
- Binary layer conditions give clear overrides (medical > defend > attack) without float tuning
- Layer 4 can use Guild Wars 2–style considerations for "which enemy" without converting the whole system to full IAUS
- Fits Fallen Paths' existing pipeline: `get_available_actions` unchanged; `pick_weighted_action` becomes the fallback used by layers 4–5
- Debuggable and maintainable: add/remove/reorder layers without touching core resolution

**Avoid for now:** Full FSM (C) — more overhead than benefit at current scope. Full IAUS (B alone) — overkill when hard overrides (medical, parry) are better expressed as layers. Yomi (D) — add after core stack works and engagement exists.

---

### References

- GDC 2005: Damian Isla, "Handling Complexity in the Halo 2 AI"
- Game AI Pro 3, Ch. 13: "Choosing Effective Utility-Based Considerations" (Mike Lewis)
- Guild Wars 2 / IAUS: [Tono Game Consultants](https://tonogameconsultants.com/infinite-axis-utility-systems/)
- The Sims AI: [Itinerant Games](https://itinerantgames.tumblr.com/post/95195640138/decision-making-ai-in-the-sims)
- Subsumption: Brooks, "A Robust Layered Control System for a Mobile Robot"
- Behavior Trees vs FSM: Opsive, PeerDH, GameDev.net comparisons
- MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md (this project)

---
