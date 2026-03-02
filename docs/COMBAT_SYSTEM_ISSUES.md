# Combat System Issues (from log analysis)

Identified from a full combat log (2v2 vs Goblins). Fixes applied where noted.

---

## 1. Crippled attackers still queue attacks (FIXED)

**Problem:** When a combatant lost both arms (e.g. Goblin), they kept entering wind-up and then at execute we printed "has no functional arm; skips attack" with a long recovery (1.5–1.8s). So they wasted full wind-up time every turn for no effect.

**Cause:** Attack commitment is made when gauge hits 100%; arm state is only checked at `_execute_attack`. AI was still given attack options and could commit, then arm was gone by execute (or was already gone when gauge filled).

**Fix applied:**
- `get_available_actions`: In combat phase, do not add attack options if `get_attacking_arm().is_empty()`.
- When AI has no actions but has an opponent, check `get_attacking_arm()` before calling `_begin_attack_with_target`. If no functional arm, put combatant in short recovery (0.8s) and clear gauge instead of starting wind-up.

Result: Combatants with no usable arm no longer do a full wind-up then skip; they take a short "skip turn" recovery.

---

## 2. "Deflected" outcome (FIXED)

**Was:** Deflected was used when tissue_dmg < pre_armor*0.25 but damage was still applied, which was misleading.

**Fix applied:**
- **Deflected** = all damage avoided (actual_dmg <= 0). Armor/angle fully prevented any tissue damage. Attacker gets short recovery (RECOVERY_EXTRA_DEFLECTED_S).
- **Glancing** = armor absorbed most but some got through (tissue_dmg < pre_armor * GLANCING_DAMAGE_RATIO). Damage is applied; outcome and recovery use RECOVERY_EXTRA_GLANCING_S.
- UI/logs distinguish both; BattleScene shows "(deflected — all avoided)" vs "(glancing)".

---

## 3. Partial parry gives defender a second full avoid roll

**Problem:** After a partial parry (attack continues with reduced velocity), the same attack is re-resolved from the top of `_execute_attack`: new miss roll, new dodge roll, (and parry is not re-attempted because we proceed to damage). So the defender gets two independent chances to avoid (first: full parry; second: miss or dodge).

**Effect:** Partial parries are very strong: they reduce impact velocity *and* give another avoid roll. In your log, several partial parries were followed by a dodge on the second roll (e.g. Goblin2 -> Character partial parry, then Goblin2 -> Character dodge).

**Options (design choice):**
- **Keep as-is:** Glancing blow is easier to avoid; two chances is intentional.
- **Single roll:** After partial parry, skip miss/dodge and go straight to damage with the reduced velocity (one avoid chain per attack).
- **Weaker second roll:** e.g. half dodge chance on the follow-through.

No change applied; leaving as design choice.

---

## 4. Goblin2 hit chance drop (perf_mod=0.35)

**Observation:** `Goblin2 -> Companion | perf_mod=0.92` later became `perf_mod=0.35 effective_hit=0.33 miss_chance=0.67 roll=0.007 => miss`. So the same attacker’s hit chance dropped sharply.

**Cause:** `get_hit_chance_performance_modifier()` uses pain/consciousness and head pain. Goblin2 took a lot of damage (head, chest, legs, etc.), so performance dropped. This is working as designed: injured fighters miss more.

No change needed unless you want to tune how fast hit chance degrades with injury.

---

## 5. Medical action wording (bandage_self on ally)

**Observation:** Log shows "Character chose medical bandage_self on part=left_leg (target_combatant_id=1)" and "Character starting bandage_self on part=left_leg" / "applying direct pressure on ally's left_leg". So the *move_id* is `bandage_self` but the *target* is an ally (Companion).

**Cause:** Same move_id is used for self and ally bandage; the target is distinguished by `target_combatant_id`. The name is confusing when target ≠ self.

**Recommendation:** In logs/UI, when target_combatant_id != performer, show something like "bandage (ally)" or use a separate move_id for ally bandage so it’s clear. Optional UX/clarity improvement only.

---

## 6. No functional arms → cowering / incapacitated (FIXED)

**Fix applied:**
- **is_cowering()** (CoreEntity): returns true when `get_attacking_arm().is_empty()` (both arms destroyed).
- **is_incapacitated()** now includes cowering: true when consciousness < threshold OR is_cowering(). So a unit with no usable arms counts as incapacitated for the fight (no gauge fill, not standing for victory).
- **STATE_COWERING**: When a combatant finishes recovery and has no functional arms, they enter STATE_COWERING instead of STATE_WAITING. Log: "[Combat] X is cowering (no functional arms)."
- When arm functionality returns (e.g. after medical/healing), if they have `is_cowering()` false, they leave cowering: state = STATE_WAITING, log "[Combat] X no longer cowering (arm functionality returned)."
- INCAPACITATED log shows "(cowering — no functional arms)" when applicable.

---

## Summary

| Issue | Severity | Status |
|-------|----------|--------|
| Crippled attackers wind-up then skip | High | **Fixed** (no arm → no attack options; skip turn with short recovery) |
| "Deflected" vs "glancing" | Medium | **Fixed** (deflected = all avoided; glancing = some got through) |
| No arms → cowering/incapacitated | High | **Fixed** (STATE_COWERING; is_incapacitated includes cowering; clear when arms return) |
| Partial parry double avoid roll | Design | Left as-is; optional tuning later |
| Goblin2 perf drop | Working | No change |
| Medical move_id vs target | Low | Optional UX wording |
