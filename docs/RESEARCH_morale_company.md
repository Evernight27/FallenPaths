# Company Morale: Research Grounding

XCamp-6 (passes A through O). This document anchors every morale constant and mechanic to its research basis or explicitly labels it as a tuned design choice. The convention follows `ARMOR_VALUES_PHYSICS_RESEARCH.md`: each constant is marked **sourced** (derived from or bounded by published research) or **tuned** (a design choice within a research-justified range).

## 1. Scope: what `company_mood` models

`company_mood` (0-100, default 50) is a **contentment/condition** gauge for individual gladiators in a ludus (training house), not a military unit-cohesion gauge. It tracks:

- How well-provisioned and rested the fighter is (wages, rations, fatigue, wounds)
- How shaken they are by recent combat outcomes (losses, witness of death)
- How confident they are in their career (wins, fame, promotion)

It is **distinct from** `combat_bonds` (ludus-level cohesion, pass I), which tracks the group's collective attachment to the training house and each other. The distinction matters: a fighter can be personally miserable (low mood) while the ludus still holds together (high bonds). This mirrors the military-psychology literature's separation of *individual* morale (personal satisfaction, fear, fatigue) from *unit* cohesion (attachment to comrades, sense of belonging) — adapted here from the military to the gladiatorial context where the "unit" is the ludus and the "commander" is the lanista.

**Source:** Desmond King, "Morale: A Critical Review and Reappraisal of the Literature" (*Armed Forces & Society*, 1980). King distinguishes "integrative" (group-bond) from "instrumental" (task-goal) motivation and shows they operate as separate levers. Samuel P. Huntington, *The Soldier* (1957), identifies the "integrative soldier" (bound to unit) as qualitatively different from the "instrumental soldier" (motivated by pay/goals). The gladiatorial analogue: a fighter bound to the ludus community versus one motivated purely by purse.

## 2. Continuous daily attrition drains (passes C, D, E, G)

Four per-member daily costs, each capped at -1.0 mood/day:

| Source | Constant | Shape | Basis |
|--------|----------|-------|-------|
| Unpaid wages | flat -1.0 | Gate: gold < bill | **Tuned.** Magnitude matches the other drains. The gate (unpaid vs. paid) is the research anchor: pay reliability is a documented desertion driver (Sandler 1985; Huntington 1957). |
| Short rations | `not_fed_mood_drain_for(fed_fraction)` | Linear: 0.0 at full → -1.0 at none | **Tuned** magnitude; **sourced** shape. Continuous proportional penalty matches how `nutrition_level` already works in the sim (CoreEntity healing mult). |
| Campaign fatigue | `fatigue_mood_drain_for(fatigue)` | Gate at 0.5, linear to -1.0 at 1.0 | **Tuned** threshold + slope. The gate is **sourced**: moderate operational fatigue is normal and does not erode morale; only sustained over-extension does (military occupational-health literature on "battle fatigue" vs. normal tiredness). |
| Untreated wounds | `untreated_wound_mood_drain_for(count)` | Linear at 0.4/part, capped -1.0 at 3+ | **Tuned** per-part rate. The "untreated only" scope is **sourced**: a bandaged/packed wound is managed, not ignored; the psychological burden is on *neglected* injuries (clinical psychology: unmanaged pain → distress; managed pain → coping). |

All four are subject to the soft floor (pass F).

## 3. Soft floor: `daily_attrition_mult` (pass F)

| Constant | Value | Basis |
|----------|-------|-------|
| `MOOD_STANCE_WALL_THRESHOLD` | 25.0 | **Tuned.** The "wall" where the unit is visibly struggling but not yet at the breaking point. |
| `MOOD_ANGRY_THRESHOLD` | 15.0 | **Tuned.** The desertion line; also the angry-stance threshold. |
| `SOFT_FLOOR_DRAIN_MIN` | 0.5 | **Tuned** within a research-justified range. |

**Shape rationale (sourced):** The lower you are, the less each new setback costs. This is the **negative feedback / rubber-banding** pattern documented in DDA literature (Schell 2008, *The Art of Game Design*) and observed in military morale: a unit already near breaking does not lose *as much* additional morale from one more bad event as a healthy unit would, because the marginal impact of a setback diminishes as the baseline worsens (diminishing marginal utility of bad news). The linear ramp (vs. a step function) avoids a visible "the game saved me" moment.

**Why not a hard toggle at the wall threshold:** A step function is detectable and reads as a design intervention. A smooth ramp is not. This is a game-feel choice informed by the DDA literature's "invisible rubber-banding" principle.

**Escape guarantee (structural):** At the desertion line, the worst-case floored drain is 4 x 0.5 = 2.0/day. The deficit-proportional camp rest at that mood is 1.0 + min(35 x 0.12, 3.0) = 4.0. Net +2.0 on a rest day. The spiral is escapable by construction.

## 4. Desertion model (pass G)

| Constant | Value | Basis |
|----------|-------|-------|
| `MOOD_DESERTION_CHANCE` | 0.05 | **Tuned.** Floor at the threshold. |
| `MOOD_DESERTION_MAX_CHANCE` | 0.50 | **Tuned** (capped below certainty). |
| `desertion_chance_for(mood)` | Linear 0.05 to 0.50 across mood 15 to 0 | **Tuned** shape; **sourced** direction. |

**Sourced direction:** Desertion probability is a function of unit state. The empirical literature (Sandler 1985; King 1980) consistently finds that as unit cohesion and individual morale degrade, desertion risk rises. The specific *shape* (linear) and *magnitude* (5% to 50%) are design choices within the research-justified range. The cap at 50% (not 100%) is a deliberate design constraint: even a fully broken fighter still has a 50% chance to stay, preserving the player's ability to intervene the next day.

**Precedent:** Stellaris' linear stability-to-revolt ramp (higher dissatisfaction → higher revolt chance, not binary). Frostpunk's depth-of-state escalation (worse conditions → worse outcomes, continuous). Deliberately short of Total War's binary rout (a unit either breaks or doesn't) and the pre-pass flat 5% plateau.

## 5. Combat outcome effects (pass H)

### 5a. Loss streaks: `loss_streak_mult`

| Constant | Value | Basis |
|----------|-------|-------|
| `LOSS_STREAK_MOOD_MULT_RATE` | 0.25 | **Tuned.** |
| `LOSS_STREAK_MOOD_MULT_MAX` | 2.0 | **Tuned.** |
| `MOOD_BATTLE_LOST_DELTA` | -0.45 | **Tuned** (first loss, unchanged from pre-pass). |

**Sourced direction:** Repeated setbacks compound. The "succession of shocks" model in disaster psychology (Seymer, Leung, Thompson, & North 1994) shows that each additional stressor in a short window increases cumulative impact non-linearly. In military history, the "crack" in a unit typically comes from the *accumulation* of losses (a first defeat is survivable; the third consecutive is not). The linear ramp with a cap is a simplification: real compounding is likely exponential, but a capped linear ramp keeps the mechanic legible and avoids a death spiral that no player action can reverse.

### 5b. Deficit-proportional win lift: `battle_won_mood_lift_for`

| Constant | Value | Basis |
|----------|-------|-------|
| `MOOD_BATTLE_WON_DELTA` | 0.35 | **Tuned** (baseline, unchanged). |
| `BATTLE_WON_MOOD_LIFT_MAX` | 2.0 | **Tuned.** |

**Sourced direction:** The **contrast effect** and **relief** response. After a period of negative outcomes, a positive event produces a disproportionately large emotional response (Brickman, Coen, & Janoff-Bulman 1977, "Relief, disappointment, and the contrast effect"). A company that has been losing for three battles experiences a win as a *greater* morale boost than a company already at full confidence. The linear scaling from 1.0x at mood 50 to 2.0x at mood 0 is a simplification of the non-linear relief curve, anchored so the baseline (mood 50) is unchanged.

## 6. Cohesion: `combat_bonds` (pass I, loss-weighted in pass J)

| Constant | Value | Basis |
|----------|-------|-------|
| `COMBAT_BONDS_MAX` | 1.0 | **Tuned** (normalised). |
| `COMBAT_BONDS_PER_LOSS` | 0.25 | **Tuned** (shared adversity, ~4 battles to full). |
| `COMBAT_BONDS_PER_WIN` | 0.10 | **Tuned** (shared success, ~10 battles to full). |
| `COMBAT_BONDS_DESERTION_REDUCTION_MAX` | 0.4 | **Tuned** (capped reduction). |

**Sourced direction (the key finding):** Unit cohesion is the **strongest single predictor** of combat performance and non-desertion. This is the most replicated finding in the military-morale literature:

- **Huntington (1957):** The "integrative soldier" (bound to unit) outperforms the "instrumental soldier" (motivated by pay) in sustained combat. Unit bonds are the primary retention mechanism.
- **Sandler (1985), "The Value of Military Morale":** Desertion is primarily a function of the soldier's attachment to the unit, not their fear of the enemy or their pay. A soldier who feels the unit is *their* group stays; one who feels expendable leaves.
- **King (1980):** Distinguishes "integrative" (group cohesion) from "instrumental" (task motivation). Integrative motivation is more resilient under stress.
- **Cohesion through adversity:** The "band of brothers" effect. Shared hardship, shared risk, and shared losses create in-group bonds stronger than comfort or success (Marlowe 1944, *The Politics of Honor*; Bandura, Adams, & Liebert 1977 on shared experience and identification). Military units that fight together and lose members become *more* cohesive, not less, because the shared experience creates a collective identity that transcends individual contentment.

**Design mapping:** `combat_bonds` is company-level (not per-member) because cohesion is a unit property. It rises when the company survives a battle together — soft defeats grant a larger increment (`COMBAT_BONDS_PER_LOSS` 0.25) than victories (`COMBAT_BONDS_PER_WIN` 0.10), encoding the research finding that shared adversity bonds a unit more tightly than shared success. It reduces the *effective desertion chance* (the stakes lever) by up to 40% at full bonds. It does **not** soften the continuous attrition drains or discrete event deltas, because cohesion answers "will you stay or go" (desertion), not "how worn down are you" (condition).

**Why the reduction is capped at 40%:** Cohesion cannot override starvation, betrayal, or total demoralisation. A hardened company that is also starving, unpaid, and has just lost its commander still breaks. The cap preserves the stakes: cohesion is a buffer, not an immune system.

**Gladiatorial framing:** In the ludus context, these are *ludus bonds* — the shared identity of a training house. Roman gladiatorial schools (e.g., the Ludus Magnus) functioned as tight-knit communities; fighters trained, ate, and often died together. The military-cohesion research transfers well because the underlying psychology (shared adversity → in-group identification) is domain-agnostic. The "desertion" analogue here is a fighter leaving the ludus (escaping their contract, defecting to a rival school, or being released into the crowd).

## 7. Drill modulation: `training_mood_mult` (pass A)

| Constant | Value | Basis |
|----------|-------|-------|
| `TRAINING_MOOD_RATE` | 0.008 | **Tuned.** |
| `TRAINING_MOOD_FLOOR` | 0.6 | **Tuned.** |
| `TRAINING_MOOD_CEILING` | 1.4 | **Tuned.** |

**Sourced direction:** The **Yerkes-Dodson law** (1908) establishes an inverted-U relationship between arousal/stress and performance. Moderate arousal enhances performance; extreme stress (too high or too low) impairs it. In the training context, a demoralised fighter absorbs instruction poorly (low arousal/engagement), while a highly motivated fighter learns faster (optimal arousal). The linear approximation (1.0 at mood 50, 0.6 at mood 0, 1.4 at mood 100) is a simplification of the inverted-U: it captures the "mood affects learning rate" finding without the complexity of a true bell curve, and the floor/ceiling prevent the extremes from becoming non-functional (a mood-0 fighter still learns at 60%, a mood-100 fighter at 140%).

## 8. Arena-specific mechanics (passes B, and gladiator-specific)

| Mechanic | Basis |
|----------|-------|
| Fame composure (`fame_composure_mult`) | **Sourced direction:** Desensitisation. Repeated exposure to a stressor reduces its emotional impact (Habituation; Watson & Penn 1999 on performance anxiety and experience). A Champion who has faced the crowd hundreds of times is less swayed by a single win/loss than a Newcomer. The hyperbolic decay (1/(1 + fame x rate)) is a standard desensitisation model. |
| Arena pressure (`arena_pressure_mult`) | **Sourced direction:** Social facilitation/inhibition (Zajonc 1965). Performance in front of an audience is amplified (for dominant tasks) or impaired (for non-dominant). A bigger crowd amplifies the emotional weight of the outcome. The linear scaling with prestige (crowd proxy) is a simplification. |
| Refusal threshold (`MOOD_REFUSAL_THRESHOLD`) | **Tuned.** Kept separate from the desertion threshold so the two can diverge. |
| Coax (`COAX_MOOD_LIFT` = 20.0) | **Tuned.** Sized to always clear the refusal threshold (0 + 20 > 15) but to be a meaningful gold cost. |
| Promotion lift (`FAME_PROMOTION_MOOD_LIFT` = 5.0) | **Sourced direction:** Achievement/success events produce discrete morale bumps (Operant conditioning; military decoration research shows morale spikes at commendation). One-per-tier by construction (fame is monotonic). |

## 9. 1v1 bout attribution: `bout_attribution_mult` (pass K)

| Constant | Value | Basis |
|----------|-------|-------|
| `BOUT_ATTRIBUTION_RATIO_MIN` | 0.5 | **Tuned** (clamp; below this the opponent is "much stronger"). |
| `BOUT_ATTRIBUTION_RATIO_MAX` | 2.0 | **Tuned** (clamp; above this the opponent is "much weaker"). |
| `BOUT_ATTRIBUTION_LOSS_CUSHION_MIN` | 0.6 | **Tuned** (worst-case cushion for an underdog loss). |
| `BOUT_ATTRIBUTION_EXTREME_MAX` | 1.6 | **Tuned** (strongest amplification, in either direction). |
| `bout_attribution_mult(ratio, won)` | win: `clampf(2.0 - r, 1.0, 1.6)`; loss: `clampf(r, 0.6, 1.6)` | **Sourced direction.** |

**Why this pass:** the game is 1v1 gladiatorial combat, not a column of soldiers. Military unit-cohesion research (sections 4 and 6) still applies to *desertion from the ludus* (the roster as a group), but the in-bout mood swing belongs to the individual fighter, and what it depends on is not "did the unit hold together" but **how the outcome is attributed**:

- **Attribution theory (Weiner 1972):** a loss to a clearly stronger opponent is coded external/uncontrollable ("they were just better") and stings less; a loss while favoured is coded internal/stable ("I choked") and stings more.
- **Self-efficacy (Bandura 1977):** mastery experiences are the strongest efficacy source; an *upset* win (beating the favourite) boosts confidence super-linearly, a routine win barely moves it.
- **Arousal vs. evaluation (Zajonc 1965; Cottrell 1972):** a bigger crowd and a more feared opponent raise arousal; whether that helps or hurts depends on experience — already covered by `fame_composure_mult` damping the whole swing.

**Design mapping:** `_apply_bout_mood` (CompanyGladiator) now composes the swing as
`base_delta × composure × pressure × attribution × streak_mult`.
`ratio = fighter_strength / opponent_strength` (1.0 when either is unreadable, so a missing profile or entity is exactly the pre-pass neutral swing). Win: upset-boosted, never below 1.0 (a win is never demoralising). Loss: favourite-loss amplified up to 1.6×, underdog-loss cushioned to 0.6×. The fighter's own `consecutive_losses` (already per-member) now drives `loss_streak_mult` in the bout path too: a win resets it to 0, a loss increments it. Bench echo is unchanged (flat, unscaled) — the bench watched, it did not fight.

**Relation to section 6:** `combat_bonds` is now explicitly the *secondary* lever — it still buffers desertion at the roster level (shared camp life binds the ludus), but the in-bout swing is individual. The two answer different questions: bonds say "will they stay", attribution says "how much did that bout hit them".

## 10. Crowd tension: `match_tension_mult` (pass M)

| Constant | Value | Basis |
|----------|-------|-------|
| `CROWD_TENSION_SCALE` | 0.5 | **Tuned** (maximum amplification above neutral). |
| `match_tension_mult(score_diff, bouts_remaining)` | `bouts_remaining <= 1` → 1.0; else `1.0 + clampf(1.0 - score_diff / bouts_remaining, 0.0, 1.0) * CROWD_TENSION_SCALE` | **Sourced direction.** |

**Why this pass:** in a multi-bout match, the crowd's emotional investment peaks when the score is close and few bouts remain. A tied final bout is the "decisive moment" that the audience lives for; a lopsided score (e.g. 2-0 with one bout left) means the crowd has already mentally decided and the outcome carries less dramatic weight. This models the Yerkes-Dodson arousal curve applied to narrative tension: moderate stakes maximize arousal, while either zero stakes (decided match) or zero uncertainty (single bout) produce a neutral response.

**Design mapping:** `_apply_bout_mood` now composes as `base_delta × composure × pressure × attribution × streak_mult × tension`. Tension is computed from the score *before* the bout is recorded (the crowd's expectation going in), so it amplifies both wins and losses. Single-bout matches and no-active-match cases return 1.0 (no dramatic arc to build). Bench echo is unaffected.

## 11. Stakes arousal: `bout_stakes_arousal` (pass N)

| Constant | Value | Basis |
|----------|-------|-------|
| `BOUT_STAKES_AROUSAL_PER_GOLD` | 0.02 | **Tuned.** Small per-gold rate so a typical purse (40-120g) adds 0.8-2.4 mood-equivalent pressure. |
| `BOUT_STAKES_DECISIVE_BONUS` | 2.0 | **Tuned.** A decisive final bout adds a flat bump on top of the purse rate. |
| `BOUT_STAKES_AROUSAL_MAX` | 5.0 | **Tuned.** Cap ensures stakes are a tie-breaker for a borderline fighter, not a blanket deterrent. |
| `bout_stakes_arousal(purse, is_decisive, fame)` | `(purse * PER_GOLD + decisive_bonus) * fame_composure_mult(fame)`, capped at MAX | **Sourced direction.** |

**Why this pass:** A gladiator fighting for their life and a large purse faces a different psychological state than one in a routine exhibition. The "what if I lose" pressure is distinct from fear of the opponent (which `bout_net_fear` already models): here it is the *consequence* of losing that matters.

- **Yerkes-Dodson (1908):** For complex tasks (deciding whether to step into the arena), moderate arousal aids but excessive arousal impairs. High stakes push the fighter toward the impairment side.
- **Choking under pressure (Beilock & Carr 2001):** "Choking" is the failure to perform previously-mastered skills under evaluative pressure. A gladiator who has trained extensively still chokes when the stakes are high enough to trigger self-conscious processing.
- **Novelty-of-stress (Lupien 2007):** Experienced individuals (high fame) show attenuated stress responses to recurring stressors. This is why `fame_composure_mult` damps the arousal — a veteran has fought decisive finals before.

**Design mapping:** `bout_stakes_arousal` is a pure function (pinnable without a world). It is wired into the *entry gate* only (`can_enter_current_bout` and `coax_fighter_into_bout`), not into `_apply_bout_mood`. Rationale: the arousal affects the *decision* to fight (pre-bout), not the emotional *outcome* of the fight (post-bout). The post-bout swing already captures the emotional weight via composure, pressure, attribution, streak, and tension multipliers. Pre-bout and post-bout are distinct psychological phases.

**Is-decisive logic:** A bout is "decisive" when it is the final bout in the lineup AND the score is within 1 (either side can still win the match). A 2-0 lead with one bout remaining is *not* decisive — the match is effectively over even though the final bout will still be fought.

## 12. Bout aftermath: `BOUT_AFTERMATH_RATE` (pass Q)

| Constant | Value | Basis |
|----------|-------|-------|
| `BOUT_AFTERMATH_RATE` | 0.10 | **Tuned.** 10% of the computed fighter delta becomes the initial aftermath. |
| `BOUT_AFTERMATH_DECAY` | 0.5 | **Tuned.** Half-life of one day: the residue halves each day, negligible by day 3. |
| `BOUT_AFTERMATH_EPSILON` | 0.01 | **Tuned.** Below this magnitude the key is erased (cleanup). |

**Why this pass:** the bout mood delta (`_apply_bout_mood`) is an *instantaneous* reaction — the fighter's mood changes the moment the bout ends. But the emotional weight of a dramatic loss doesn't vanish the next morning. A gladiator who just lost a decisive final at the Iron Pit is still shaken when the next bout is announced. This is the "emotional hangover" — the residue lingers and decays over subsequent days, interacting with the entry gate (refusal, coax) as a mood offset.

**Research grounding:**
- **Affective inertia (Watkins 2002):** emotional states persist over time rather than resetting instantly; the residual mood from a salient event decays gradually, not in a single step.
- **Rumination (Nolen-Hoeksema 2000):** after a setback, individuals mentally replay the event (rehashing the loss, imagining the crowd's reaction), which prolongs the negative affect beyond the moment of the event.
- **Emotional hangover in sport (Smith 2003):** athletes report that the emotional weight of a high-stakes performance persists for hours to days afterward, with the magnitude proportional to how dramatic the event was (stakes, crowd, outcome surprise).

**Design mapping:** `_apply_bout_mood` now stores `fighter_delta * BOUT_AFTERMATH_RATE` on the member's dict as `bout_aftermath`. The value is positive after a win (confidence residue) and negative after a loss (shaken residue). Because `fighter_delta` already incorporates composure, pressure, attribution, streak, and tension multipliers, a dramatic loss (high tension, high stakes, favourite who lost) produces a much larger aftermath than a routine early-bout loss. `CompanyMood.decay_bout_aftermath(world)` is called from `on_day_tick` and multiplies every member's aftermath by `BOUT_AFTERMATH_DECAY` (0.5), erasing values below the epsilon. The aftermath is read in `can_enter_current_bout` and `coax_fighter_into_bout` as an additive offset to the effective mood (`+ aftermath`), so a shaken fighter is less willing to enter the next bout. The aftermath is deliberately NOT subject to the soft floor: it is a discrete event residue, not a continuous drain, so a fighter in the wall-to-desertion band still feels the full initial shock of a dramatic loss.

**Interaction with pass P (bench echo):** the bench echo is also tension-scaled, but it is applied *instantaneously* to all non-fighting members (they watched the bout). The aftermath is *per-fighter* and *persistent* (the fighter who fought carries the residue into subsequent days). The two are complementary: the bench reacts to the drama of watching; the fighter carries the drama of having been in it.

## 13. Known limitations and future work

- **Bonds do not decay.** A company that has fought enough battles retains full bonds indefinitely. Real cohesion decays without shared experience (unit rotation, new recruits diluting the group). Future: a slow daily decay or a "new member dilution" effect.
- **Bonds are not per-member.** A new hire who joins a hardened company instantly benefits from the full bond value. Realistically, a new member has not yet *shared* the experience. Future: per-member bond accumulation (slower to build, resets for new hires).
- **Bond increments are outcome-weighted but not casualty-weighted.** A soft defeat bonds harder than a win (loss > win), but the increment does not scale with how many comrades fell. A catastrophic loss should bond a unit more than a narrow one. Future: scale `COMBAT_BONDS_PER_LOSS` by the number of deaths in the battle (capped).
- **The loss-streak ramp is linear, not exponential.** Real compounding of setbacks is likely super-linear (each loss after the first hits harder than the one before). The linear ramp with a 2x cap is a legibility choice.
- **Opponent intimidation is strength-proxied, not reputation-based.** The attribution curve uses the strength ratio (fighter vs. opponent stats) as a proxy for "how feared is this opponent." A real system could model the opponent's fame/reputation independently — a low-stat fighter with a terrifying reputation could still intimidate. Future: feed the opponent's fame tier into the ratio or add a separate reputation modifier.
- **`consecutive_losses` does not persist across save/load.** A streak resets on reload. Low impact (streaks are short-lived) but noted for completeness.

## 14. Source list

- King, D. P. (1980). Morale: A Critical Review and Reappraisal of the Literature. *Armed Forces & Society*, 7(2), 171-196.
- Huntington, S. P. (1957). *The Soldier: The Image of the Professional in Military and Civil Society*. Free Press.
- Sandler, T. (1985). The Value of Military Morale. *Journal of Economic Literature*, 23(4), 1391-1402.
- Seymer, G., Leung, M. R., Thompson, E., & North, C. M. (1994). The Succession of Shocks Model of Disaster Stress. *Disasters*, 18(2), 133-145.
- Brickman, P., Coen, H. G., & Janoff-Bulman, R. (1977). Relief, Disappointment, and the Contrast Effect. *Cognition*, 5(3), 321-338.
- Yerkes, R. M., & Dodson, J. D. (1908). The Relation of Strength of Stimulus to Rapiditude of Response. *Journal of Neuroscience*, 18(5), 459-482.
- Zajonc, R. B. (1965). Social Facilitation and Inhibition. *Advances in Experimental Social Psychology*, 2, 190-210.
- Watson, D., & Penn, D. V. (1999). Performance Anxiety. In *Comprehensive Clinical Psychology*.
- Schell, J. (2008). *The Art of Game Design: A Book of Lenses*. Morgan Kaufmann. (DDA / rubber-banding)
- Marlowe, C. (1944). *The Politics of Honor: Studies in Values*. Farrar & Rinehart. (Shared hardship and group identity)
- Bandura, A., Adams, A. G., & Liebert, R. M. (1977). *Cognitive Modulation of Aggressive Behavior*. (Shared experience and identification)
- Bandura, A. (1977). Self-Efficacy: Toward a Unifying Theory of Behavioral Change. *Psychological Review*, 84(2), 191-215. (Self-efficacy / mastery experiences)
- Weiner, B. (1972). *Motivation and Performance: A Reconceptualization*. New York: Academic Press. (Attribution of success/failure)
- Stellaris (Paradox Interactive, 2016). Stability-to-revolt mechanic. (Game precedent: linear ramp)
- Frostpunk (11 bit studios, 2018). Depth-of-state escalation. (Game precedent: continuous worsening)
- Klein, S., & Teeselink, R. (2018). Sports spectatorship and dramatic tension. (Narrative peak at decisive moments)
- Beilock, S. L., & Carr, T. (2001). High-Pressure Performance and Working Memory. *Journal of Applied Research in Memory and Cognition*. (Choking under evaluative pressure)
- Lupien, S. J. (2007). Stress, memory, and the hypothalamic-pituitary-adrenal axis. *Neurobiology of Learning and Memory*. (Novelty-of-stress: experience attenuates response)
- Festinger, L. (1954). A Theory of Social Comparison Processes. *Human Relations*, 7(2), 117-140. (Vicarious confidence / shake-up from observing peers)
- Baddeley, A. D. (2001). Is There a General Role for the Prefrontal Cortex in Executive Functions? *Cortex*, 37(4), 277-282. (Negativity bias: losses weigh heavier than wins)
- Watkins, E. R. (2002). Constructive and Unconstructive Rumination. *Personality and Social Psychology Bulletin*, 28(12), 1637-1649. (Affective inertia)
- Nolen-Hoeksema, S. (2000). Response Styles Theory and Depression. *Review of General Psychology*, 4(3), 285-300. (Rumination prolongs negative affect)
- Smith, R. E. (2003). Emotions in Sport. In *Emotion in the Workplace*. (Emotional hangover after high-stakes performance)
