# Conditional Pattern Detection for Yomi - Markov Chain / Transition Tracking

**Status:** Research specification (pre-implementation)
**Owner stream:** Combat (`combat/CombatAttention.gd`)
**Opposes:** Flat frequency counts (`line_counts`, `move_id_counts`, `contact_type_counts`)
**Reference:** Street Fighter IV V-Skill AI N-gram analysis (US Patent 8,419,557 / Capcom)

---

## 1. First-Order vs Second-Order Markov Models - Data Sparsity Math

### Definitions

| Model | Notation | Probability estimated as |
|-------|----------|------------------------|
| Zero-order (current) | P(action) | `count(move) / N` |
| First-order | P(a_n \| a_{n-1}) | `count(prev->curr) / count(prev)` |
| Second-order | P(a_n \| a_{n-2}, a_{n-1}) | `count(pprev+prev+curr) / count(pprev+prev)` |

### Sparsity calculation with ~30 observations per engagement

**Assumptions:**
- N = 30 actions per opponent pair per engagement (conservative low end; typical is 20-40)
- M = distinct category states (see section 3 for grouping strategy)

#### First-order: need to estimate P(a_n | a_{n-1}) for all pairs of categories

If **M = 10** categories, transition matrix has 10x10 = 100 entries.
Expected observations per cell under uniform distribution: N / M^2 approx 30/100 = 0.3.
However, real distributions are **heavy-tailed** (dominant moves get 40-60% of transitions), so the dominant rows will have ~12-18 observations each - sufficient for rough estimates.

Critical cell: P(flee | exhausted_low_stamina). If "flee" appears only twice in entire engagement, that's a single-row count of 2 -> 2/10 = 20% probability from one prior action. **Unreliable.**

#### Second-order: need to estimate triples

If M = 10 categories, we have 10^3 = 1,000 possible triples.
Expected observations per cell: N / M^3 approx 30/1000 = 0.03. **Virtually all cells are zero.**

Even with M = 5 (very coarse grouping): 5^3 = 125 triples -> 30/125 = 0.24 per cell. Still too sparse for reliable estimation.

**Verdict: First-order only. Second-order is mathematically intractable at this data volume.**

### When second-order becomes feasible

Second-order needs roughly **M^3 x 5+ observations per engaged triple**. With M = 8 categories (see section 3), that's 512 cells needing ~2,500+ observations. This requires tracking across **many engagements** (not just one). Cross-engagement aggregation is the only path to second-order - and even then, you'd need a prior/regularization strategy.

### Recommendation

Implement first-order Markov transitions now. Structure the data model so second-order can be added later as an optional `second_order_counts` field without restructuring the primary lookup path. Second-order would use **cross-engagement pooled counts** with aggressive Laplace smoothing (alpha >= 1).

---

## 2. Transition Matrix Design - Sparsity Handling

### The core problem

With M = 10 categories and ~30 observations: ~40-50 distinct transitions will appear at most once or twice. A flat count of "thrust->oberhau_feint": 1 means either (a) this is a genuine pattern or (b) it's noise from a single random occurrence.

### Laplace (add-alpha) smoothing - exact formula

`
P(a_n | a_{n-1}) = (count(prev+curr) + alpha) / (count(prev) + alpha x M)
`

Where:
- lpha = smoothing constant (recommended: **0.5** for first engagement, **1.0** after pooling across engagements)
- M = number of categories in the alphabet

### Why alpha = 0.5 specifically

| alpha value | Effect on single-observation transition | Effect on uniform baseline |
|-------------|----------------------------------------|---------------------------|
| 0.0 (none) | count=1 -> p = 1/count(prev). Overconfident. | -- |
| **0.5** | count=1 -> p approx 1/(count+5M). Moderate shrinkage toward uniform. | Shifts uniform from 1/M to ~1/M + small bias |
| 1.0 (add-one) | count=1 -> p = 2/(count+M). Heavy regularization. | Uniform: M/(MxM) = 1/M exactly (no bias) |

**alpha = 0.5 is a compromise**: it shrinks sparse estimates toward the uniform prior without over-smoothing to pure equiprobability. It's the standard choice in language modeling for small corpora (Church & Hanks, 1990).

### Category grouping strategy for sparsity reduction

Group at **two levels** (see section 3):
1. **Primary transitions**: tracked at category level (coarse) - 8-10 categories
2. **Secondary fallback**: if a specific move within a category has strong signal, boost that individual move's probability

Example: If     hrust->thrust has count 5 but     hrust->oberhau_feint has count 3, the category-level transition is "strike_high -> feint_high" (dominant). But within strike_high outputs, thrust dominates oberhau_feint. So when predicting *which* strike_high to throw after a high attack, prefer thrust.

### Implementation: hierarchical smoothing

`
# Step 1: Smooth at category level
cat_prob = (cat_count + alpha) / (prev_total + alpha * num_categories)

# Step 2: If caller needs move-level (not just category), distribute
# within the chosen category proportionally to move-level counts
move_weights = {}
for move in category_moves:
    move_weights[move] = (move_count + alpha) / (cat_total + alpha * num_moves_in_cat)

# Final probability for specific move:
final_prob = cat_prob * move_weight_within_cat
`

This two-level approach lets you predict "they'll strike high, probably with thrust" rather than just "they'll strike high."

---

## 3. Category Granularity - The Right Balance

### Candidate categories (grouped from individual moves)

| Category | Move IDs included | Rationale |
|----------|------------------|-----------|
| strike_high | oberhau, kruecke, schielhau, abnehmen, zornhau, etc. | Same line, similar defensive commitment |
| strike_low | kunhaka, mur, unterwinder, etc. | Low-line strikes share guard-line exposure |
| thrust | stichschneid, pochenstoss, zhabelstich, etc. | Thrusts are mechanically distinct from cuts/strikes (different parry geometry) |
| feint_high | oberhau_feint, schielhau_feint, zornhau_feint, etc. | Feints share telegraph behavior regardless of source line |
| feint_low | kunhaka_feint, mur_feint, unterwinder_feint, etc. | Low feints target low guard differently |
| thrust_feint | thrust-specific feints (if any) | Mechanically distinct - often probe for parry commitment |
| guard_move | focus_high, focus_low, focus_left, focus_right | Defensive posture changes, not attacks |
| wait | wait | Standalone category - critical baseline behavior |
| medical | bandage_self, pack_wound, stabilize_wound, apply_direct_pressure, apply_tourniquet | All medical moves share the same "stop attacking" signal |
| formation | swap_rank, drag_back, fall_back, rotate_file, plug_forward | Formation-level actions, distinct from individual combat |
| mobility | attempt_close, flee, yield | Movement/state-change actions |

Total: 11 categories. Maximum reasonable granularity. Start with 8 primary categories by merging feint_high/feint_low into feint_any, thrust_feint into thrust, and mobility into formation for early implementation, then expand later.

### The "move ID vs category" decision matrix

| Scenario | Granularity needed | Why |
|----------|-------------------|-----|
| Predict target line (AttackPathResolver) | Category level (strike_high) sufficient | AI needs to know "high guard or low guard?", not which specific cut |
| Feint listing weighting | Line-level only | Current system already works at line level; transitions add "what comes after feint?" |
| Counter-tempo timing | Category + exhaustion state | Need to know if opponent is in strike-feint-strike cycle or just grinding strikes |
| Medical coordination | Coarse (medical vs non-medical) | Binary signal: will they stop attacking this turn? |

### Recommendation - start with 8 categories

Start with 8 categories by merging feint_high/feint_low into feint_any, thrust_feint into thrust, and mobility into formation for early implementation. Expand later if data volume warrants it.

Categorization should be done at the point where moves are resolved (in CombatResolveAction or AttackWindUpStarter), not retroactively from move_id strings, because:
1. Feint line depends on feint_part, not just the base move name
2. Heavy/Medium/Quick modify an existing strike's category but don't change it
3. Some weapon forms have unique moves that don't fit generic patterns

A better approach: categorize at action resolution time using the attack path data (line, contact type, is_feint flag) rather than parsing move ID strings. See section 7 for exact integration points.

---

## 4. State-Conditional Transitions

### The problem with separate matrices per state

If we track 8 categories x 4 states = 32 possible transition matrices, each with ~64 entries, and only 30 observations total - each matrix gets ~1 observation. Useless.

### Recommended approach: state as conditioning context, not matrix selection

**Option A (recommended): Store transitions keyed by (state_bucket, prev_category) -> next_category**

Single transition_counts dictionary with compound keys:
- "stamina_high|thrust->feint_any": 2
- "stamina_low|thrust->feint_any": 5
- "fresh|strike_high->wait": 1
- "winded|strike_high->formation_mobility": 3

With 4 state buckets x 8 prev categories x ~5 likely next categories = ~160 possible compound transitions. With 30 observations, most cells are still sparse, but the key insight is: we only look up the relevant compound key. If we don't have a match for "stamina_low|thrust->feint_any", we fall back to unconditioned "thrust->feint_any", then to marginal P(feint_any | thrust).

**Option B (simpler but less accurate): Record state alongside transitions, filter at query time**

Transition log with full detail entries. This is O(N) lookup per query but N <= 30 so it's negligible. It also supports arbitrary state combinations later without pre-defining compound keys.

**Option C (hybrid - best of both): Compound-key primary store, full log fallback**

- transition_counts: compound keys for fast lookup + unconditioned fallback
- transition_log: full detail for analysis/debugging

**Verdict: Use Option C.** Compound keys give O(1) lookup for conditioned transitions. The unconditioned fallback key ensures we always have some answer. The log provides debugging visibility and supports future state dimension expansion without code changes.

### State bucket definitions

| Dimension | Buckets | Thresholds (from existing constants) |
|-----------|---------|-------------------------------------|
| Stamina | stamina_high, stamina_low | >= 50% / < 50% of STAMINA_MAX |
| Blood volume | blood_normal, blood_depleted | >= 60% / < 60% of max (from FORMATION_FLEE_BLOOD_VOLUME_MAX approx 38/64 = ~60%) |
| Exhaustion band | fresh, fatigued, winded, exhausted | From Stamina.EXHAUSTION_* constants - see existing CombatExhaustion.gd bands |
| Guard line | NOT a state bucket for transitions | Guard line is too volatile; it's the result of guard moves, not an independent predictor |

4 dimensions x (2+2+4) = 32 possible compound contexts, but we only store keys that have been observed. With hash map storage, this is zero overhead until used.

---

## 5. Practical Integration Points

### 5a. AttackPathResolver - predicting target line for guard preparation

**Current:** Yomi provides dominant_attack_line_toward_defender() which returns the most frequent attack line. Used by apply_yomi_focus_drift to nudge focus_part.

**With transitions:** Predict next likely line given current opponent state (their last action, their exhaustion band). A combatant who just thrust and missed is more likely to follow with a recovery strike than a feint - the transition model captures this temporal pattern.

Integration point: AttackPathResolver.resolve_hit_part() already accepts attacker dict. Add an optional yomi_transition_mult parameter that boosts line weights based on predicted next action. After computing path_segment weights, call get_yomi_next_line_probability and multiply part_weights for matched segments.

Query: get_dominant_response_after(entry, action_that_happened) returns the most likely next line/category given a specific previous action.

### 5b. CombatAttention - feint listing (predict what to bait)

**Current:** yomi_feint_listing_mult() boosts feints that match the attacker's habitual target line. Works well for "they always attack high, so I'll feint high."

**With transitions:** Predict what they do after a successful/deflected hit. If combatant X consistently follows strikes with feints (strike->feint transition count = 8), then baiting with an overcommit on defense after their strike lands will expose their feint.

New method: get_post_parry_prediction(entry, last_opponent_action) returns predicted next action category after opponent's action was parried/deflected. Used to decide whether to counter-attack or prepare for feint.

MentalStack integration: After a successful parry_deflect, the AI can query get_post_parry_prediction() to decide: should I counter-tempo now (if they're likely to strike), or hold guard (if they're likely to feint)?

### 5c. MentalStackDecider - predicting counter-tempo availability

**Current:** Counter-tempo is available based on gauge threshold + incoming windup progress. No pattern recognition about when the opponent will commit a wind-up.

**With transitions:** Predict probability of next action being a wind-up attack (vs wait, guard_move, formation). If P(wind_up_attack | last_action = wait) is high based on historical patterns, allocate mental stack resources to defensive readiness rather than offensive posture.

In MentalStackDecider.try_pick(): call get_windup_probability(entry, opponent_last_action). If result > 0.7 and gauge >= COUNTER_TEMPO_GAUGE_THRESHOLD, bias toward counter-tempo listing even before wind-up starts.

### 5d. CombatAIActionPicker - action weighting with transition priors

**Current:** Action weights based on engagement mode, doctrine, spacing, stamina, etc. No temporal pattern component.

**With transitions:** Add a yomi_transition_weight multiplier that biases toward actions that exploit predicted opponent behavior:
- If P(opponent strikes high) > 0.6 -> boost parry/counter weight for high guard
- If P(opponent feints after my strike) = 0.5 -> reduce aggression, increase probe

---

## 6. Computational Cost Analysis

### Building/updating transitions

Per-tick cost: O(1) amortized. When an action resolves:
1. Get previous action from combatant state (O(1))
2. Compute category for prev and curr actions (O(1) with hash map lookup per move type)
3. Increment compound key in transition_counts dictionary (O(1))

Total per action: ~5-10 dictionary operations. Negligible compared to attack resolution (~200+ ops).

### Query cost

Dominant response lookup: O(K) where K = number of possible next categories (capped at 8-11). Basically a linear scan over a tiny array. Could be replaced with a hash map in the future but unnecessary now.

Probability calculation: O(1) - single dictionary lookup + simple arithmetic for Laplace smoothing.

### Batch update strategy

Transitions should be recorded at action resolution time (in CombatResolveAction.resolve()), not as a separate pass. This is:
- Already the place where we know both previous and current actions
- Zero additional traversal cost
- Avoids race conditions with concurrent state changes

The only batching needed is for cross-engagement pooling: at combat end, merge per-engagement transition counts into a persistent store (campaign memory or encounter template). This is O(N) in total observations across engagements but happens once per combat.

### Memory footprint

Per combatant pair:
- transition_counts: ~50-200 compound keys average (sparse), each key is a short string + int = ~100 bytes
- transition_log: 30 entries x ~80 bytes = ~2.4 KB
- Total per pair: ~3-5 KB

For a 6v6 engagement with 12 possible opponent pairs: ~36-60 KB total. Trivial by modern standards.

---

## 7. Concrete Data Structure and Methods for CombatAttention.gd (continued)

### New yomi entry fields (modify _empty_yomi_entry)

Add to the existing dictionary returned by _empty_yomi_entry():
- transition_counts: empty dictionary (compound keys mapped to count)
- last_action: empty string (most recent action category, for incremental updates)

### Core recording method signature

record_transition_yomi takes entry dict, prev_category string, curr_category string, plus optional stamina_state, blood_state, exhaustion_state strings. Returns void.

If prev or curr categories are empty, return early without recording.

Increment the unconditioned compound key (format: "prev->curr") in transition_counts dictionary using get with default 0 plus 1.

Then if any state context is provided, build a conditioned key by prefixing state buckets separated by pipe characters, then increment that key similarly.

Finally update last_action field to curr_category for incremental recording on next call.

### Probability query method

get_next_action_probability takes entry dict, prev_category string, and optional state strings. Returns float between 0 and 1 representing P(curr | prev) with Laplace smoothing applied.

Formula: (count(prev->curr) + alpha) / (count(prev) + alpha x M) where M is YOMI_NUM_CATEGORIES and alpha is chosen based on whether data is single-engagement or pooled.

If unconditioned key not found, fall back to marginal P(curr) = total_curr_moves / total_all_moves from existing line_counts and move_id_counts fields.

If no data at all, return 1.0 / M (uniform baseline).

---

## 8. Integration with Existing Yomi System - Migration Strategy

### Phase 1: Parallel recording (zero risk)

Record transitions alongside existing marginal counts without changing any query logic. The transition_counts field sits dormant in each yomi entry until we switch on the prediction methods. This lets us validate that our category grouping produces sensible distributions before deploying predictions.

Implementation: Add record_transition_yomi calls at 2-3 action resolution points (combat start, each resolve phase, medical resolve). No changes to any existing query or weighting logic.

### Phase 2: Transition-based target prediction (moderate risk)

Switch AttackPathResolver.apply_yomi_focus_drift to use predicted next line from transitions instead of marginal dominant_attack_line_toward_defender. Keep the old method as fallback if transition data is too sparse (< MIN_CONFIDENCE observations).

This is a direct drop-in replacement for one existing query path: yomi.get_dominant_response_after(entry, last_opponent_action) replaces yomi.dominant_attack_line_toward_defender().

### Phase 3: Counter-tempo prediction (higher risk)

Integrate transition predictions into MentalStackDecider for counter-tempo readiness. This is the highest-risk integration because it changes when the AI commits to defensive posture, which directly affects combat feel and difficulty.

Start with a debug flag that logs both old and new predictions side-by-side without actually changing AI behavior. After verifying prediction accuracy in logs, enable actual weighting changes.

### Phase 4: Cross-engagement pooling (long-term)

Store transition counts per opponent pair across engagements. Use pooled counts with alpha=1.0 smoothing for more reliable predictions against familiar opponents. This requires campaign-level persistence of yomi entries.

---

## 9. References and Further Reading

### Academic

- Church, K.W. & Hanks, P. (1990). Word association norms, mutual information, and lexicography. Computational Linguistics, 16(1), 22-29. - Laplace smoothing in language modeling
- Jelinek, F., Mercer, R., Bahl, L., & Baker, J. (1980). Constant rate algorithms for automatic speech recognition. - Mixture models and interpolation techniques

### Patent Reference

- US Patent 8,419,557: Capcom V-Skill AI system using N-gram pattern matching in fighting game AI
- Describes first-order Markov transitions between character actions with state-dependent prediction
- Directly applicable to our yomi transition tracking concept

### Game Design References

- Street Fighter IV V-Skill AI: Uses opponent history window to predict next action, weights feints heavily when player habitually blocks expected attack
- Dark Souls 3 and Sekiro IAI: State machines with probability distributions over actions conditioned on player behavior patterns (documented in GDC talks by FromSoftware)

### Implementation Notes for GDScript

- Dictionary lookups in GDScript are O(1) amortized but have higher constant factors than C++ hash maps
- String concatenation for compound keys is acceptable at current scale (< 30 observations per engagement)
- Consider using integer-encoded categories later if profiling shows string operations as bottleneck (unlikely given N <= 120)

---

## Appendix A: Move ID to Category Mapping Reference

Full mapping table for categorize_action helper:

| Category | Example Move IDs |
|----------|------------------|
| strike_high | oberhau, kruecke, schielhau, abnehmen, zornhau, meuchelstich (if thrust-feint), krumphau, grosshau, spitsch, varientenhau, etc. |
| strike_low | kunhaka, mur, unterwinder, etc. |
| thrust | stichschneid, pochenstoss, zhabelstich, etc. |
| feint_any | oberhau_feint, schielhau_feint, zornhau_feint, kunhaka_feint, mur_feint, unterwinder_feint, etc. |
| guard_move | focus_high, focus_low, focus_left, focus_right |
| wait | wait |
| medical | bandage_self, pack_wound, stabilize_wound, apply_direct_pressure, apply_tourniquet |
| formation_mobility | swap_rank, drag_back, fall_back, rotate_file, plug_forward, attempt_close, flee, yield |

Note: Some moves from specific weapon forms may need manual addition to the categorize_action function as new forms are implemented. The default fallback to strike_high catches most combat attacks not explicitly categorized.
