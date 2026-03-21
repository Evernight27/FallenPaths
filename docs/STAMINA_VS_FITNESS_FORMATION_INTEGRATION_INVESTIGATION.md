# Stamina vs Fitness — Formation Integration Investigation

**Principle:** Formation positioning (swap rank, plugging) should use **performance + health (fitness)** only. Engagement actions (attack, attempt_close) should use **stamina**.

---

## Decision Summary

| Action Type | Use | Rationale |
|-------------|-----|------------|
| **Attack** | Stamina | Exhausted units hit weaker, parry worse; AI should be less likely to attack when very low stamina |
| **Attempt close** | Stamina | Engaging the enemy; exhausted units less likely to succeed (pressure roll) and less likely to choose |
| **Swap rank** | Fitness only (perf × blood) | Formation positioning; injured/wounded should retreat to back regardless of stamina |

---

## Integration Points Audited

### ✅ CombatAIActionPicker (fixed)

- **Swap rank:** Uses `_get_positioning_fitness()` (performance × blood). No stamina. Prevents ping-pong when fitness similar.
- **Attack / attempt_close:** Uses stamina_ratio; weight 0.85 when stamina < 20%, else 1.0.

### ✅ CombatManager

- **`_start_swap_rank`:** Time-based duration from agility + lane/pressure mods. No stamina cost or check.
- **`resolve_action` for swap:** Routes to `_start_swap_rank`; never touches AttackResultApplier. Swap does **not** consume stamina.
- **`_resolve_close_attempt`:** Uses `stamina_factor(atk)` and `stamina_factor(def)` for pressure vs evasion roll. Correct — engagement.
- **`_reschedule_back_rank_turns`:** Fixed delay (0.2s). No stamina.
- **Plug on death:** Promotes rank 1 → 0, schedules `READY_DELAY_AFTER_PROMOTION_S`. No stamina.

### ✅ AvailableActionsBuilder

- **Swap rank availability:** Gated only by formation rules (we_are_front, partner_incapacitated, same file, adjacent rank). No stamina check. Correct — offer when formation allows; AI weights by fitness.
- **Attack / attempt_close:** No stamina gating for offering. Correct.

### ✅ AttackResultApplier

- **Swap rank:** Never reaches this path. Swap returns early in `resolve_action`. No stamina consumed for swap.
- **Attack outcomes:** All consume stamina (attack cost, parry cost). Correct.

### ✅ TurnReadyHandler (player companions)

- Uses `CombatAIActionPicker.pick()`. Fix applies.

### ✅ CombatStateHandlers (enemy AI)

- Uses `CombatAIActionPicker.pick()` for action choice. Fix applies.

### ✅ Stance System (CombatConstants)

- `STANCE_MIN_STAMINA_AGGRESSIVE`, `STANCE_MIN_STAMINA_CONTROLLING`: Gates stance on stamina. Affects close_attempt, evasion, parry. All engagement-related. Correct.

### ✅ AttackResolver / DefenseChoiceResolver

- Use stamina for damage scaling, parry capacity, variance. All engagement. Correct.

---

## No Changes Needed

- **CombatConstants:** "Swap rank / fall back: time-based, no stamina" — already correct.
- **Documentation (FF4_REMAINING_DECISIONS_CHECKLIST §3):** "Swap rank / Fall back movement: Time-based (not stamina)" — matches.
- **Human player:** Can choose swap_rank when available. No stamina gate. Correct — formation actions remain available regardless of exhaustion.

---

## Future (Phase 5+)

When implementing **fall back**, **drag back**, **step over fallen**: use fitness for positioning decisions, no stamina. Duration may scale with lane clarity / pressure (time-based), not stamina cost.
