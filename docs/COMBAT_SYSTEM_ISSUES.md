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

## 3. Partial parry follow-through: twist dodge (IMPLEMENTED)

**Problem:** After a partial parry, the attack continues with reduced velocity. The defender's body has already moved (twist, step) with the parry attempt. Should they get a second avoid chance?

**Implemented:** Twist dodge modeled on time and mobility at **start** of parry attempt (not after). Stored: `parry_twist_time_to_react`, `parry_twist_readiness`. `twist_capacity = time_factor × mobility × readiness`. Also: parry-quality scale (better parry → more twist benefit), attack-type mods (thrust −12%, cut +5%), part-specific modifier. Late parry gets 15% time floor for reflexive movement.

**Alternatives considered:**
- **No second roll:** Proceed straight to damage. Simpler; partial parry is the only mitigation.
- **Partial tier on twist:** Full dodge / partial twist (further reduce remaining_ratio) / hit. More granular but complex.
- **Scale by parry quality:** Better parry (lower remaining_ratio) → more residual slip. Plausible but adds parameters.

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

## 7. Recovery vs readiness (investigation)

**Question:** Should recovery or readiness be scaled differently for different attacks?

### Recovery tracking (attacker only)

- **Who enters recovery:** The **attacker** (or medical performer). The defender never enters RECOVERING from parry or dodge; they go to WAITING immediately (parry_deflect gives `parry_bonus_until`).
- **Recovery duration** (`_recovery_duration`):
  - **Outcome:** hit (+0s). Deflected: base 0.1s + 0.15×intensity. Full_stop: base 0.5s + 0.35×intensity. Glancing (Method B): base 0.12s + (1−severity)×0.2×intensity; severity = tissue/(pre_armor×0.25). Miss/dodge: base 0.35s + 0.9×intensity.
  - **Archetype:** `recovery_multiplier` per move (stab/slash 1.0, overhead 1.2, quick_slash 0.85, pommel 0.9, heavy_blunt 1.15)
  - **Intensity** (commitment) scales base+extra; **agility** shortens; **perf_mod** (pain/consciousness) slows
  - **Attack type** (cut/thrust/blunt): does **not** affect recovery duration directly; only via archetype (chosen by move_id)

### Readiness (defender’s parry capacity when attacked)

- **Definition:** `_get_passive_parry_readiness(c)` → WAITING = 1.0; RECOVERING = lerp(0.5, 0.85, progress) where `progress = state_timer / state_duration`.
- **When it applies:** When the **defender** is in RECOVERING (e.g. just attacked or did medical) and someone attacks them.
- **Uniform:** Same lerp(0.5, 0.85) for all recoveries. No stored “cause” (hit vs miss vs medical) and no incoming attack type.
- **Attack type:** Cut/thrust/blunt affects parry redirect efficiency and twist dodge (thrust −12%, cut +5%), but **not** the readiness multiplier itself.

### Gaps for scaling

| Dimension | Current | Possible extension |
|----------|---------|--------------------|
| **Outcome-based readiness** | Same curve for any recovery cause | Different curves for “recovering from hit” vs “recovering from miss” (stunned vs off-balance) |
| **Incoming attack type** | No effect on readiness | Thrust incoming → harder to react (lower readiness); cut → same or easier (more telegraph) |
| **Recovery cause** | Not stored | Store `recovery_cause` (“attack_hit”, “attack_miss”, “attack_deflect”, “medical”) to drive readiness shape |
| **Archetype vs attack type** | Recovery uses archetype only | Explicit thrust/cut/blunt scaling for recovery or readiness if desired |

### Verdict

- **Recovery duration** already scales by outcome and archetype; no per-attack-type scaling currently.
- **Readiness** is uniform and independent of incoming attack type. To scale by attack type you would:
  1. Pass the incoming `attack_type` (cut/thrust/blunt) into `_get_passive_parry_readiness` or the parry capacity calc.
  2. Optionally store `recovery_cause` when entering RECOVERING and use it to shape the readiness curve (early hit vs early miss could differ).

No code changes required unless you want attack-type or cause-dependent readiness.

**Implemented:** Guard/readiness — when in WAITING, parry capacity × guard. Guard drops to 0.4 when attacking or doing medical; rises at 0.6/s when idle.

---

## Summary

| Issue | Severity | Status |
|-------|----------|--------|
| Crippled attackers wind-up then skip | High | **Fixed** (no arm → no attack options; skip turn with short recovery) |
| "Deflected" vs "glancing" | Medium | **Fixed** (deflected = all avoided; glancing = some got through) |
| No arms → cowering/incapacitated | High | **Fixed** (STATE_COWERING; is_incapacitated includes cowering; clear when arms return) |
| Partial parry follow-through dodge | Design | **Implemented** (50% efficiency twist dodge) |
| Goblin2 perf drop | Working | No change |
| Medical move_id vs target | Low | **Fixed** (Bandaging ally, etc. in UI/logs) |
