# Mercy & Execution Plan (Quarter / Coup de Gràce)

**Date:** 2026-08-07
**Status:** PROPOSAL — design agreed (personality + mood + situation; mid-combat + post-victory). Pending realism research + implementation.

## Concept

Standing units can finish off ("execute") a **downed** opponent — alive but not standing (`CoreEntity.is_incapacitated` = unconscious or cowering, plus `STATE_YIELDED` surrender). Executing vs sparing is a **decision**, made by the same AI picker that chooses every move (`CombatAIActionPicker`), weighted by **personality × mood × situation**. Both sides make the decision — an enemy may execute a downed player unit.

Executions resolve through the standard death pipeline (`died=true` → kill log, `_check_for_winner`) so post-battle accounting, UI, and world bridge keep working.

Two windows:

- **Mid-combat** — while the enemy side still has ≥1 standing fighter (combat auto-ends at zero standing, `CombatStandingHelper.gd:29`).
- **Post-victory mop-up** — during the winner's medical phase. The phase **first triages the winner's own wounded, then** resolves each downed enemy: execute, or spare-and-stabilize as a prisoner. Prisoners must be stabilized so they do not bleed out — *it makes no sense to take prisoners if they die waiting* (losing-side bleed keeps ticking during the medical phase; only fled winners get `COMBATANT_KEY_SUSPEND_BLEED_TICK`, `MedicalPhaseController.halt_losing_side_combat`).

## 1. Decision model

Execute weight = **personality** × **mood** × **situation**, folded into the existing action-weight pipeline (`CombatAIActionWeights`). Conceptually:

```
execute_weight = base_ai_weight(MOVE_ID_EXECUTE)
                × personality_mult    (unit trait)
                × mood_mult           (side morale, existing CombatCampaignMoodBias pattern)
                × threat_mult         (situation)
                × grudge_mult         (did I damage them?)
```

| Factor | Direction | Signal | Status |
|--------|-----------|--------|--------|
| Personality trait | **+execute** for high `ruthlessness` | New per-combatant field (see §2) | New |
| Campaign mood | low morale → spare, high → execute | `CombatCampaignMoodBias.offense_action_weight_mult`-style ramp | Exists |
| Not currently threatened | **+execute** | `CombatTargetScoring.ordered_melee_opponents(manager, c, combatants, 0)` empty for the executor | Exists |
| Currently in melee/combat range of other units | **−execute** | same list non-empty; `CombatWeaponForm._primary_melee_threat_id` (private, replicate) | Exists |
| Damaged the downed target during combat | **+execute** | New per-pair damage ledger (see §2) | New |
| Did not damage the target | **−execute** | same ledger empty | New |
| Doctrine | mop-up active (`CombatDoctrine.envelop_mop_up_active`) → natural execute window | Exists |

**Spare** is the implicit fallback: not choosing execute leaves the unit downed. Post-victory, spared downed units become **prisoners** (§4). Mop-up doctrine (`envelop_mop_up_active` / `mop_up_underdog_active`) is the existing "finish the fight" machinery and the strongest natural gate — executions most plausibly cluster there, but the trait/mood/grudge weights must still apply so sparing stays possible.

## 2. Data model

- **`FEATURE_MERCY_EXECUTE`** — new flag in `combat/constants/CombatConstantsFeatureFlags.gd` (default **true** when shipped, per §9c precedent), mirrored in `CombatConstants.gd` like `FEATURE_WOUNDED_VITALS_EXPLOIT`.
- **`MOVE_ID_EXECUTE := "execute"`** — new constant in the moves constants file, mirrored in `CombatConstants.gd`, plus an `is_execute_move(move_id)` helper (pattern: `is_medical_move`). Registered in `CombatantFieldRegistry`-style ownership tables where moves/actions are listed.
- **Personality trait** — new combatant key (e.g. `ruthlessness`, 0–100, 50 = neutral). Seed precedence: encounter config → party roster / species resource (new `@export` on `SpeciesResource`) → default. Registered in `CombatantRegister` defaults + `CombatantFieldRegistry` owner table.
- **Damage-attribution ledger** — new combatant key on the *attacker* (e.g. `damage_dealt_by_id: {target_id: total}`). Stamped in `AttackResultApplier`'s hit path (`:720-786`), where `attacker_id` / `target_id` / result dict are all in scope (entity damage itself flows through `EntityDamage.apply_damage_split`). **Do not** reuse yomi: `CombatAttention` records *attempts* at wind-up (`AttackWindUpStarter.gd:253`) and resolved move ids (`AttackResultApplier.gd:797`), not landed damage, and it is feature-gated.

## 3. Window A — mid-combat execution

Hook map (verified against current gates):

1. **Downed predicate** — `CombatExecute.is_downed_opponent_of(manager, attacker, target)`: target alive, hostile, not standing (`is_incapacitated` or `STATE_YIELDED`). Lives beside `is_living_hostile_to` (`CombatantIdentityAccess.gd:~49`).
2. **Bypass the four `are_living_hostiles` gates** — only for the execute move:
   - `CombatMeleeListing.gd:29` (`can_melee_threaten`)
   - `CombatMeleeRankTargeting.gd:20` (`melee_pair_rank_allowed`)
   - `CombatTargetScoring.gd:88/144` (scoring loops)
   - `AttackWindUpStarter.gd:53` (hard reject at wind-up start)
   Execute still needs the target within reach/band (or mop-up reach-gap strike, `CombatMeleeListing.envelop_mop_up_strike_at_band`).
3. **Listing** — append execute actions in `AvailableActionsBuilder.build` → `CombatMeleeListing.append_melee_actions_for_combatant`, one entry per downed opponent in reach: `{target_id, move_id: MOVE_ID_EXECUTE}`.
4. **AI weight** — new branch in `CombatAIActionWeights` applying the §1 multipliers (trait, mood, threat, grudge).
5. **Resolve** — new branch in `CombatResolveAction`: wind-up-less, skip-defense kill. Bypass the `AttackWindUpStarter` `are_living_hostiles` guard for `MOVE_ID_EXECUTE`; emit `died=true` so the standard death pipeline runs (`on_combatant_died` → `_check_for_winner`, `CombatManager.gd`) and the kill log fires (`BattleScene.gd:514-532`).
6. **Timing** — combat ends the tick a side hits zero standing; executes must resolve before that, so the listing window is naturally bounded by the enemy's last standing fighter.

## 4. Window B — post-victory mop-up (medical phase)

Current contract (`CombatManager._end_combat_phase` `:588-646`, `MedicalPhaseController`): player win → `medical_phase=true`, winner-side triage only, `can_end_medical_phase` = all winner wounded comprehensively treated, then `combat_ended`. Losing side is halted and never treated; losing-side bleed keeps ticking.

**Rework to two-stage triage** (player-win only; enemy-win teardown unchanged):

1. **Stage 1 — own wounded first (unchanged).** Winner-side medical actions only; `can_end_medical_phase` still requires winner wounded treated. This is the existing behavior, preserved.
2. **Stage 2 — prisoner triage.** Once no winner-side fighter needs care, each living losing-side downed unit is resolved:
   - **Spare** → stabilize (bandage/pack/pressure via the existing `MedicalPhaseController.get_ally_medical_actions` ladder, now usable across sides) so they stop bleeding, then mark as **prisoner** (`STATE_YIELDED`-adjacent / new prisoner stamp) — they leave the field alive.
   - **Execute** → standard death pipeline (`died=true`, kill log).
   - Decision uses §1 weights; with no enemy standing, `threat_mult` is gone → trait + mood + grudge dominate.
3. **Phase end** — `can_end_medical_phase` extended: also requires no unresolved losing-side downed (each executed or stabilized). `combat_ended` emits as today.

Sequencing note: because losing-side bleed continues during the phase, a "spare" that arrives too late can still die — the stabilization step is time-sensitive, which is the design intent (triage order matters).

## 5. World bridge / battle summary

- Kill log (`record_battle_kill` → `campaign_battle_kill_log` → `build_last_battle_summary`) works unchanged via the death pipeline.
- Add a **prisoners** entry to the battle summary (`CampaignEncounterBridge.build_last_battle_summary`) — spared units are recorded as captured (name/side), distinct from kills and from survivors. Ownership: Campaign stream (shared file); Combat provides the prisoner stamp; Campaign formats/consumes.

## 6. Feature registry (proposed §9c row)

One row, added with the implementation PR per [`SHIP_PLAN §9c`](SHIP_PLAN.md#combat-expand-registry):

| ID | Status | Intent |
|----|--------|--------|
| MS/EX-1 | **Phase 0/1c done** — `FEATURE_MERCY_EXECUTE`, `MOVE_ID_EXECUTE` + helpers, data keys (ruthlessness/damage_dealt_by_id), `CombatExecute.gd` decision module (+personality/mood/threat/grudge weights), listing bypass in `CombatMeleeListing.gd`, weight dispatch in `CombatAIActionWeights.gd`, resolve branch in `CombatResolveAction.gd` (instant-kill + ledger stamping), harness tail `harness/mercy/MercyExecuteTail.gd` (17 tests); **Stage-2 post-victory prisoner triage done** — two-stage medical phase (`winner_triage_complete` / extended `can_end_medical_phase`), execute/spare-stabilize listing in `CombatMedicalActionListing.append_prisoner_triage_actions`, `is_living_opponent_of_by_side` helper; **UI polish done** — `"execute"` outcome clause in `CombatLogFormatter`; tuning constants (§10) still pending |

Requires: `FEATURE_*` + harness (new `CombatRegressionHarness` tail, e.g. `harness/mercy/`), `PHASE0: PASS`, no `world/*` edits without Campaign coordination.

## 7. File ownership

| Change | Owner |
|--------|-------|
| `combat/constants/CombatConstantsFeatureFlags.gd`, moves constants, `CombatConstants.gd` | Combat |
| `combat/ai/CombatExecute.gd` (new decision module — predicate, weight, listing/resolve helpers) | Combat |
| `combat/strike/AttackResultApplier.gd` (damage ledger) | Combat |
| `combat/ai/CombatAIActionWeights.gd`, `CombatMeleeListing.gd`, `AvailableActionsBuilder.gd`, `CombatResolveAction.gd`, `AttackWindUpStarter.gd` (execute bypass) | Combat |
| `combat/medical/MedicalPhaseController.gd`, `MedicalPhaseBatchResolve.gd` (two-stage triage) | Combat |
| `resources/species/*` (ruthlessness export) | Shared |
| `world/CampaignEncounterBridge.gd` (prisoner summary) | Shared (Campaign leads) |

Session budget: ≤1 doc section + ≤3 owning `.gd` per edit pass — implementation is phased (see §9).

## 8. Research plan (realism)

Before tuning weights, research the ground truth the mechanic should model. All sources verifiable (this repo's standard — see `plan_balance_tuning.md` audit note).

### R1 — Historical quarter / ransom conventions (execute vs spare)
- Quarter and ransom in the Hundred Years' War (Poitiers 1356, Agincourt 1415 — English killing prisoners *mid-battle* for tactical reasons); mercenary companies and *condottieri* (capture for ransom as the norm); "no quarter given/asked" and its triggers.
- Who was spared vs killed: rank, value of ransom, ability to take prisoners safely (no hands to guard them while the fight continues), enemy reputation for breaking parole.
- Pre-Christian / early medieval: enslavement vs execution, sacrifice.
- **Question:** which factors made victors spare or kill *in the moment* vs *after the battle*? Feeds `threat_mult` and the two-window split.

### R2 — Psychology of killing in close combat
- Firing-rate studies (S.L.A. Marshall's ~15-25% claim; Dave Grossman *On Killing*; Michael Bourke's critique and subsequent estimates) — most soldiers historically *do not* kill when not pressured; proximity matters (Bayonet/rifle/artillery distance gradient).
- Mechanisms: obedience, threat, group pressure, dehumanization, desensitization, moral injury from killing, post-combat remorse (feeds "spare" tendency and why mercy is the fallback).
- **Question:** which variables move a fighter from "not killing" to "killing a helpless enemy"? Feeds `personality_mult` + `mood_mult` (morale as aggression) shape.

### R3 — Tactical realism of executions mid-fight
- Why a fighter with a standing enemy nearby would *not* waste time finishing a downed foe (exposure, stamina, risk of the downed one reviving — consciousness can return, `CombatStateHandlers` cowering recovery). Mirrors the game's threat gate.
- Downed-recovery reality: concussed/unconscious fighters regaining capacity in seconds-to-minutes (see GCS/concussion data in `plan_balance_tuning.md`) — supports both "finish them" urgency and "spare them" risk.
- **Question:** what is the realistic opportunity cost curve? Feeds `execute_weight` relative to other listed moves.

### R4 — Post-battle casualty care & prisoners
- Battlefield triage order (own wounded before enemy; the medical phase already encodes this), survival of untreated wounds (bleed-out times), treatment of prisoners' wounds (were they treated, abandoned, or killed?).
- **Question:** how fast do untreated "downed" casualties actually die, and did victors stabilize prisoners? Validates the Stage-1-before-Stage-2 order and the stabilization requirement.

**Output:** a short research section appended here with sources + a weights proposal table, reviewed before Phase 3 tuning.

## 9. Implementation order

- **Phase 0 — registry + doc:** add §9c row, `FEATURE_MERCY_EXECUTE`, `MOVE_ID_EXECUTE` + helpers, harness tail skeleton. Gate `PHASE0: PASS`.
- **Phase 1 — mid-combat execute:** personality field + seeding, damage ledger, `CombatExecute` module, listing + weights + resolve branch, both sides. Harness: listing/predicate/resolve/kill-log tests.
- **Phase 2 — post-victory prisoner triage:** two-stage medical phase, stabilize-spared, execute decisions, prisoner summary entry (Campaign coordination). Harness: sequencing, stabilization, phase-end, summary.
- **Phase 3 — realism tuning:** apply §8 research → weight constants (see `CombatExecute` knobs); soak validation (7v7 / mop-up tails).

## 10. Tuning knobs

| Knob | Where | Default (proposal) |
|------|-------|--------------------|
| `FEATURE_MERCY_EXECUTE` | `CombatConstantsFeatureFlags.gd` | `true` |
| `EXECUTE_BASE_AI_WEIGHT` | `CombatExecute` | low (execute is not a default habit) |
| `RUTHLESSNESS_MULT` range | `CombatExecute` | 0.4 (ruthless 0) … 1.6 (ruthless 100) |
| Mood ramp | `CombatCampaignMoodBias`-style | low morale → sparing; high → executing |
| `EXECUTE_THREATENED_MULT` | `CombatExecute` | ≤0.2 while any enemy in melee reach |
| `EXECUTE_GRUDGE_MULT` | `CombatExecute` | ≥1.5 when executor dealt damage to the target |
| Prisoner stabilization window | medical phase | bounded by existing bleed-out times |

## 11. Success criteria

- Downed opponents are attackable via `MOVE_ID_EXECUTE`; `PHASE0: PASS` and no regressions in the existing 7v7 / mop-up / medical tails.
- Executions are rare while the executor is engaged (threat gate) and cluster in mop-up / post-victory windows.
- Spared post-victory units survive as prisoners (no bleed-out) and appear in the battle summary; kills still flow through the kill log.
- Enemy AI can execute a downed player unit (both sides symmetric).
- No new `FEATURE_*` is introduced without a harness; weights are research-backed per §8.

## 12. Risks / mitigations

| Risk | Mitigation |
|------|-----------|
| Executions trivialize the medical phase | Stage 1 (own wounded) is mandatory before prisoner triage; bleed keeps ticking |
| Executing feels random | Weights driven by explicit trait/mood/grudge signals, documented and tunable |
| Player rage at losing units to execution | Symmetric rule, low base weight, research-backed rarity when engaged |
| Medical phase contract drift (harness + fast-forward + batch resolve) | Keep Stage 1 code path intact; add sequencing tests before touching `can_end_medical_phase` |
| Ownership overlap on species / bridge | Shared rows — coordinate before editing (`PLANNING#file-ownership`) |

## 13. Research findings & weights proposal (2026-08-07)

Sources verified against live search this date; direct links. Reviewed before Phase 3 tuning.

### R1 — Historical quarter / ransom

- **Agincourt (1415):** Henry V ordered French prisoners killed *mid-battle* when a French rally was feared; the order was a tactical necessity (fear of prisoners rejoining / outnumbering captors), not cruelty — chroniclers did not condemn it. English knights refused the killing as unchivalrous; the execution fell to common men-at-arms/archers. Only high-ransom (high-rank) prisoners were spared. Source: [HistoryExtra — Agincourt: myths and facts](https://www.historyextra.com/period/medieval/battle-agincourt-myths-facts/).
- Ransom as the systemic norm (Hundred Years' War / *condottieri*): rank → ransom value drove sparing; capture-for-ransom was the expected outcome for valuable prisoners (Poitiers 1356, King John II; "golden age of private ransoms"). Killings *after* the battle of non-ransomable common soldiers were routine; "no quarter" was a signalable, dishonorable doctrine.
- **Design feed:** the two-window split (mid-battle vs post-victory) is historically real. Mid-battle executions were rare and *tactically driven* (threat/rear-guard fear) — supports a low base weight with a strong threat/urgency term. Post-victory, value (ransom) pushed *spare*; execute was for the valueless or when guarding prisoners was unsafe.

### R2 — Psychology of killing at close range

- **Ratio of fire:** S.L.A. Marshall's claim that only ~15-25% of American infantry fired in WWII is heavily disputed — historians (Bourke) and later analysis call the data suspect/fabricated from post-action interviews; modern estimates put firing rates far higher. Source: [HistoryNet — Marshall's Ratio of Fire](https://www.historynet.com/sla-marshall-ratio-of-fire/). Grossman's *On Killing* built the "reluctance to kill" thesis on Marshall; its *exact* numbers are unreliable even if the proximity gradient (harder to kill close, personally, directly) is broadly supported.
- **Design feed:** do not hard-code a "kill rarity" from the contested 15-25% figure. Instead: (a) keep `EXECUTE_BASE_AI_WEIGHT` low as a *habit* gate, but (b) let explicit situation/personality signals move the number — this is defensible regardless of the firing-rate dispute. Grudge/proximity (personal violence) is the psychologically strongest single signal — supports `EXECUTE_GRUDGE_MULT ≥1.5`.

### R3 — Downed-recovery reality (mid-fight finish vs leave)

- Concussed/unconscious combatants can regain capacity in seconds-to-minutes. Combat-sport precedent: a downed fighter gets a counted window (e.g. 10-count) to rise; failure to rise = defeat. Brief LOC recovery protocols (sports medicine) run ~1 week return-to-play, but *in-fight* wakefulness is a seconds-scale event. Source: [PMC — Loss of Consciousness: pathophysiology](https://pmc.ncbi.nlm.nih.gov/articles/PMC155414/).
- **Design feed:** the in-game "cowering recovery" (a downed unit can rise again) is realistic → finishing a downed enemy has genuine *urgency* when it may recover, but is a low-value action while other enemies are actively engaging you. Threat gate (≤0.2 while engaged) + grudge/mood terms model this correctly.

### R4 — Post-battle casualty care & prisoners

- **Triage order:** battlefield triage originates in the Napoleonic era; "own wounded first, then enemy wounded" is enduring (and contested) doctrine, with the Geneva obligation to treat enemy wounded acknowledged even while own-first is practiced. Sources: [Wikipedia — Battlefield triage](https://en.wikipedia.org/wiki/Battlefield_triage), [Military Review 2018 — Treating Enemy Wounded After Own Wounded](https://www.armyupress.army.mil/Journals/Military-Review/English-Edition-Archives/September-October-2018/Maneuver-Warfighting/).
- **Design feed:** validates the two-stage order exactly as planned — Stage 1 own wounded first, Stage 2 enemy/prisoner stabilization. Also validates that spared units *must* be stabilized to survive (untreated casualties die; bleeding continues during the phase).

### Weights proposal (Phase 3 baseline, per §10)

| Knob | Research basis | Proposed default |
|------|----------------|------------------|
| `EXECUTE_BASE_AI_WEIGHT` | R1 (mid-battle execution was rare/tactical), R2 (not the default habit) | low — ~5-10% of a standard attack's weight |
| `RUTHLESSNESS_MULT` | R2 (individual disposition; contested absolute numbers → use a relative ramp) | 0.4 … 1.6 over 0…100 (`50 = 1.0`) |
| Mood ramp | existing `CombatCampaignMoodBias` shape; R2 (morale as aggression) | low morale → sparing; high → executing |
| `EXECUTE_THREATENED_MULT` | R1 (tactical fear), R3 (urgency vs exposure) | ≤0.2 while any enemy in melee reach of executor |
| `EXECUTE_GRUDGE_MULT` | R2 (personal violence strongest signal) | ≥1.5 when executor dealt damage to target |
| Stage order + stabilize-to-survive | R4 (own-first triage; untreated die) | hard constraint, not a weight |
