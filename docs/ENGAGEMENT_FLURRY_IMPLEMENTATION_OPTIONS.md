# Engagement & Flurry Implementation Options

## Goal

When units are **engaged** with each other:
- **Faster recovery** — attacker recovers quicker so they can strike again sooner
- **Flurry of blows** — multiple exchanges in quick succession with the engaged opponent
- **Disengagement** when engagement expires or stamina is low → both back off to normal pace

---

## Current System (Baseline)

| Component | Current | Where |
|-----------|---------|-------|
| Turn order | Gauge fills; first to 100 acts | CombatStateHandlers.process_waiting |
| Recovery | `CombatTiming.recovery_duration(intensity, outcome, ...)` → state_duration | AttackResultApplier, DefenseResolutionHandler |
| Stamina | Attack 8, parry 10; refills in WAITING | AttackResultApplier, process_waiting |
| Engagement | **Not implemented** | — |

---

## Approach A: Recovery Modifier + Engagement Timer (Minimal)

**Idea:** Engagement is a flag + timer. When engaged, recovery is shorter. No explicit flurry phase.

### Mechanics
1. On attack → `attacker.engaged_with_id = target_id`, `target.engaged_with_id = attacker_id`, `engagement_until = now + ENGAGEMENT_DURATION_S`
2. On recovery duration calc: if `engaged_with_id >= 0` and target alive and `engagement_until > now` → `recovery *= ENGAGEMENT_RECOVERY_MULT` (e.g. 0.7)
3. Engagement clears when: timer expires, target dies, either chooses different target, or either has stamina < ENGAGEMENT_STAMINA_FLOOR (e.g. 20)

### Data
```gdscript
# Per combatant
engaged_with_id: int = -1
engagement_until: float = -1.0  # timestamp
```

### Pros
- Minimal change: one new state, one modifier in recovery calc
- Faster recovery creates implicit flurry (both act more often when engaged)
- Stamina gate: low stamina → engagement breaks

### Cons
- No guarantee of back-and-forth; third party can interrupt
- "Flurry" is emergent, not explicit

### Files
- CombatManager/register: add engaged_with_id, engagement_until
- AttackWindUpStarter or resolve_action: set engagement on attack
- CombatTiming.recovery_duration or call site: apply engagement mult
- process_waiting: clear engagement when timer expired or stamina low

---

## Approach B: Engagement Phase With Reduced Wind-Up Too

**Idea:** Same as A, but also reduce **wind-up** when attacking engaged target. Double speed-up.

### Mechanics
1. Engagement as in A
2. When attacking `engaged_with_id` (your current duel partner): `wind_up_s *= ENGAGEMENT_WINDUP_MULT` (e.g. 0.75)
3. Recovery mult as in A

### Pros
- Faster attacks *and* recovery when locked in → clear flurry feel
- Reuses AttackWindUpStarter (add engagement check before bind check)

### Cons
- Two modifiers to tune
- May feel too fast if both stacked

---

## Approach C: Flurry Sub-Phase (Explicit Multi-Blow)

**Idea:** When A attacks B, enter `STATE_IN_FLURRY` instead of normal flow. Resolve multiple blows before returning to WAITING.

### Mechanics
1. On attack resolve (hit/parry/miss/dodge) → instead of attacker RECOVERING, enter flurry:
   - `A.flurry_partner_id = B.id`, `B.flurry_partner_id = A.id`
   - `A.state = STATE_IN_FLURRY`, `B.state = STATE_IN_FLURRY`
   - `flurry_remaining = FLURRY_MAX_BLOWS` (e.g. 3)
   - `flurry_turn = "attacker"` or `"defender"` (defender responds first after parry; attacker after hit)

2. Flurry loop (in process or new handler):
   - Whose turn: resolve their attack (reduced wind-up, e.g. 0.2s fixed or 0.5× normal)
   - Apply result (hit/parry/damage)
   - Consume stamina each blow
   - If either stamina < FLOOR or flurry_remaining <= 0 or either dead → disengage, both RECOVERING (short), then WAITING

3. Disengagement: `flurry_remaining = 0` or `stamina < 20` or death

### Data
```gdscript
# New state
STATE_IN_FLURRY := "in_flurry"

# Per combatant in flurry
flurry_partner_id: int = -1
flurry_remaining: int = 0
flurry_turn: String = ""  # "me" or "them" or resolve order
```

### Pros
- Explicit flurry: 2–4 blows in a row, no gauge between them
- Stamina gates length naturally
- Dramatic "clash" feel

### Cons
- New state, new process handler, more complex
- 2v1: who gets flurry? (Need rule: flurry only when 1v1 or when attacker's target is not attacked by others)
- Turn order within flurry must be defined (defender ripostes first after parry, etc.)

### Files
- CombatConstants: STATE_IN_FLURRY, FLURRY_MAX_BLOWS, FLURRY_STAMINA_FLOOR, FLURRY_WINDUP_MULT
- CombatStateHandlers: process_flurry (or process_in_flurrying)
- CombatManager _process: route to process_flurry when state == STATE_IN_FLURRY
- AttackResultApplier: on action_resolved, optionally enter flurry instead of recovery

---

## Approach D: Engagement Meter (Shared Resource)

**Idea:** Engaged pair shares an "exchange meter" that fills with each blow. When it maxes, both disengage.

### Mechanics
1. Engagement: `(A, B)` share `engagement_meter = 0`, `engagement_meter_max = 100`
2. Each blow in the exchange: `engagement_meter += BLOW_COST` (e.g. 25)
3. When `engagement_meter >= engagement_meter_max` → both disengage, short recovery
4. Stamina: each blow costs stamina; if either < FLOOR, force disengage early

5. Recovery within engagement: `recovery *= 0.7` (as in A)
6. Blows can be rapid (reduced wind-up when attacking partner) until meter fills

### Pros
- Clear "exchange length" — 4 blows of 25 each, then break
- Stamina can truncate early

### Cons
- Two resources (meter + stamina) — redundancy
- More state to track (pair-wise meter)

---

## Approach E: Gauge-Free Flurry (Alternating Blows)

**Idea:** During flurry, gauge is ignored. A and B alternate blows until disengagement.

### Mechanics
1. A attacks B → result (parry/hit)
2. If parry: B gets immediate "riposte" (no gauge) → resolve B's attack
3. If B's attack parried: A gets immediate counter → resolve
4. Continue until: max N blows, or stamina < FLOOR, or one dies, or one "breaks" (heavy hit)
5. After flurry: both enter recovery; gauge resets to 0

### Flow
```
A attacks → B parries → B riposte (instant) → A parries? → A counter (instant) → ...
or
A attacks → B hit → B optional afterblow? → disengage
```

### Pros
- No gauge during flurry — pure blow-for-blow
- Matches HEMA "binding" or rapid exchange

### Cons
- Bypasses normal turn economy; can feel unfair if one side is much stronger
- Afterblow already exists; need to integrate

---

## Approach F: Hybrid — Engagement Modifiers + Optional Flurry Entry

**Idea:** Light touch: engagement = recovery/wind-up modifiers (A/B). Optionally: when *both* have full gauge and one attacks, enter 1–2 bonus blows (mini-flurry) before normal recovery.

### Mechanics
1. **Always:** Engagement = recovery × 0.75, wind-up × 0.85 when attacking partner (A + B)
2. **Optional:** When engagement forms and both had gauge 100: grant 1 "flurry blow" to defender (riposte) with 0.3s wind-up, then normal recovery

### Pros
- Majority is simple modifiers
- One guaranteed exchange when both were ready

### Cons
- "Optional flurry" adds conditional logic

---

## Comparison

| Approach | Recovery Faster | Wind-Up Faster | Explicit Flurry | Stamina Gate | Complexity |
|----------|-----------------|----------------|-----------------|--------------|------------|
| A: Modifier + timer | ✓ | — | Emergent | ✓ | Low |
| B: + Wind-up | ✓ | ✓ | Emergent | ✓ | Low |
| C: Sub-phase | ✓ (built-in) | ✓ (built-in) | ✓ 2–4 blows | ✓ | High |
| D: Meter | ✓ | ✓ | ✓ (meter-driven) | ✓ | Medium |
| E: Gauge-free | ✓ (implicit) | ✓ (instant) | ✓ Alternate | ✓ | Medium–High |
| F: Hybrid | ✓ | ✓ | 1 bonus blow | ✓ | Medium |

---

## Recommendations

**Start with Approach A or B** — minimal, reuses existing flow. Engagement = recovery (and optionally wind-up) modifier. Timer + stamina gate for disengagement. Flurry emerges from both acting faster.

**If you want explicit flurry:** **Approach C** — dedicated flurry phase with fixed 2–4 blows, stamina gate, then both recover and exit. Requires new state and handler.

**Stamina integration (all approaches):**
- Each attack/parry in flurry consumes stamina (existing)
- If either combatant `stamina < ENGAGEMENT_STAMINA_FLOOR` (e.g. 20): force disengagement, clear engaged_with_id, both enter recovery
- Check at start of each "blow" in flurry, or each time engagement is read for recovery mod

---

## Data Schema (Common Across Approaches)

```gdscript
# Combatant
engaged_with_id: int = -1
engagement_until: float = -1.0  # Time.get_ticks_msec()/1000 + ENGAGEMENT_DURATION_S

# Constants
ENGAGEMENT_DURATION_S := 4.0       # Max time before auto-disengage
ENGAGEMENT_RECOVERY_MULT := 0.75   # Recovery × this when engaged
ENGAGEMENT_WINDUP_MULT := 0.85     # (B only) Wind-up × this when attacking partner
ENGAGEMENT_STAMINA_FLOOR := 20.0   # Below this, force disengage

# C/D/E only
STATE_IN_FLURRY := "in_flurry"
FLURRY_MAX_BLOWS := 3
FLURRY_STAMINA_FLOOR := 15.0
```

---

## Hooks

1. **Set engagement:** In `resolve_action` or `_begin_attack_with_target`, when attack is committed: set both combatants' engaged_with_id, engagement_until
2. **Clear engagement:** When: target dies, timer expired, stamina low, or explicit "break engagement" action
3. **Recovery modifier:** In `CombatTiming.recovery_duration` or at call site in AttackResolver/DefenseResolutionHandler — pass engagement context, multiply result
4. **Wind-up modifier:** In AttackWindUpStarter — if attacking engaged_with_id and engagement valid, multiply wind_up_s
