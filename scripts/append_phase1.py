import os

phase1 = """## Phase 1: Deterministic Rout Picks (MS-L6) - Low Effort, High Impact

**Gap:** MS-L6 uses weighted random pick for rout decisions (flee vs fall_back), but when abandonment is warranted there should be one correct direction. A retreating soldier does not flip a coin.

**Swordmaster rationale:** "When the line breaks, there is one correct direction to run - toward cover or toward allies who still hold. Not random." In real combat, rout decisions are deterministic based on terrain and ally positions.

**Evidence in code:**
- `MentalStackDecider.gd` line 153: `_AIPicker.pick_weighted(rout_pool, ...)` - RNG-based selection
- `CombatFormationRout.gd` lines 338-357: `filter_rout_disengage_actions` returns {flee, fall_back} pool - both can be valid but one is usually tactically superior
- `CombatAIActionPicker.gd` lines 97-109: `pick_highest_medical` already implements deterministic "highest weight wins" pattern - reuse this exactly
- `CombatFormationRout.gd` line 327: `rout_cognition_pressure` and line 180: `abandonment_warranted` provide the trigger; the decision within should be deterministic

**What to implement:**
1. Add `pick_highest_rout(actions, combatant_id, manager)` to `CombatAIActionPicker.gd` - follow the exact pattern of `pick_highest_medical` (lines 97-109): iterate actions, compute weight via `_get_action_weight` for flee/fall_back moves using `flee_ai_pick_mult` from CombatFormationRout (line 202), return highest-weight action
2. In `MentalStackDecider.gd` line 153, replace `_AIPicker.pick_weighted(rout_pool, combatant_id, manager, actions)` with `_AIPicker.pick_highest_rout(rout_pool, combatant_id, manager)`
3. The weight computation for rout picks: flee weight = `AI_FLEE_ROUTINE_WEIGHT * flee_ai_pick_mult(manager, c)` (see CombatAIActionPicker.gd lines 293-301); fall_back weight = `0.45 / opponent_controlling_disengage_listing_divisor` (lines 302-306). Use these exact formulas.
4. Add harness test confirming same rout choice across multiple ticks in identical state

**Files to touch:** `combat/MentalStackDecider.gd`, `combat/CombatAIActionPicker.gd`

**Validation:** Harness confirms deterministic pick; PHASE0 green.

---
"""

base = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(base, "..", "docs", "MENTAL_STACK_IMPROVEMENT_PLAN.md")
with open(path, "a") as f:
    f.write(phase1)

print("Phase 1 appended")