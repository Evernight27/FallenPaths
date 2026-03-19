# Combat Stance States: Medieval Soldier vs HEMA Psychology

Investigation of combat stances/psychological states for units: how medieval soldiers and HEMA practitioners differed, and how to model **defensive**, **aggressive**, **balanced**, and **controlling** stances—driven by stamina, personality, and weapon skill.

---

## Part 1: Medieval Soldier States (Formation Combat)

### 1.1 Source Context

Medieval formation combat was **collective** — individuals acted as part of a unit. States were less about personal "Vor/Nach" and more about **role** and **fatigue**.

| State | Description | When |
|-------|-------------|------|
| **Fresh / eager** | Front rank, ready to fight. Aggressive or controlled by formation discipline. | Start of engagement |
| **Exhausted** | Can't maintain shield, weaker blows. Needs rotation. | After sustained fighting |
| **Wounded** | Diminished capability, may fall back or fight desperately | After taking hits |
| **Routed** | Broke rank, fleeing. No formation cohesion. | Morale collapse |

**Key:** Medieval soldiers didn't have formal "stances" in the HEMA sense. They had **fatigue**, **morale**, and **formation role**. Stance-like behavior emerged from: am I pressing or holding? Am I fresh or tired?

---

## Part 2: HEMA Psychology — Vor, Nach, Indes

### 2.1 Liechtenauer's Five Words (Simplified)

| Term | Meaning | Combat state |
|------|---------|--------------|
| **Vor (Before)** | You attack first, compel opponent to defend. **Initiative.** | Controlling, pressing |
| **Nach (After)** | You respond to their attack. **Reactive.** | Defensive, countering |
| **Indes (Instantly)** | Act in the moment—often in the bind. **Timing.** | Balanced, opportunistic |

**Vor** = controlling the tempo. Your actions demand answers. Opponent is in Nach.

**Nach** = trying to win back the initiative. Defensive but not passive—counter-attacks, parry-riposte.

**Indes** = the transition moment. Acting while they act. Bind work, feints, tempo steals.

### 2.2 Correspondence to Stances

| HEMA concept | Stance equivalent |
|--------------|-------------------|
| **Vor** | Aggressive or Controlling — pressing the attack |
| **Nach** | Defensive — responding, protecting |
| **Indes** | Balanced — ready to act in the moment; or Controlling — feints, binding |

---

## Part 3: Proposed Stance System

### 3.1 Four Stances (Per User)

| Stance | Description | Effect |
|--------|-------------|--------|
| **Defensive** | Hold back, protect self. Prioritize parry/dodge over damage. | ↑ Parry capacity, ↑ evasion, ↓ damage dealt, ↓ close success (attacker) |
| **Aggressive** | Disregard incoming attacks, maximize damage. All-in. | ↑ Damage dealt, ↓ parry capacity, ↓ evasion, ↑ close success |
| **Balanced** | Default. Neither extreme. | Baseline modifiers |
| **Controlling** | Feints, binds, keep opponent occupied. Harder for them to engage or fall back. | ↑ Opponent's close/disengage difficulty, ↑ bind/feint effectiveness, moderate defense |

---

### 3.2 What Drives Stance Choice

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

### 3.3 Stance Effects (Summary Table)

| Stance | Parry | Evasion | Damage | Close attempt (attacker) | Opponent disengage | Opponent close |
|--------|-------|---------|--------|--------------------------|--------------------|----------------|
| **Defensive** | ×1.2 | ×1.15 | ×0.85 | ×0.9 | ×1.0 | ×1.0 |
| **Balanced** | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |
| **Aggressive** | ×0.8 | ×0.85 | ×1.2 | ×1.1 | ×1.0 | ×1.0 |
| **Controlling** | ×1.0 | ×1.0 | ×0.95 | ×1.0 | ×0.85 (harder) | ×0.9 (harder) |

**Controlling** makes opponent's disengage and close attempts harder — you're occupying their attention, feinting, binding. They can't easily break off or close on someone else.

**Numbers are placeholders** — tune for feel.

---

### 3.4 Stamina Gates

| Stance | Min stamina to choose | Notes |
|--------|------------------------|------|
| **Defensive** | 0 | Always available. Safer when low. |
| **Balanced** | 0 | Default. |
| **Aggressive** | 20–30 | Exhausting. Can't sustain at 0. |
| **Controlling** | 15–25 | Requires energy for feints, footwork. |

When stamina drops below minimum, unit **reverts to balanced or defensive** (can't maintain aggressive/controlling).

---

### 3.5 Stance Transitions

- Stance can change **between actions** (on turn/event choice).
- Optional: **transition cost** — switching from aggressive to defensive takes a moment (e.g. 0.2 s delay) as you "reel in."
- Simpler: instant switch; modifiers apply on next action.

---

## Part 4: Medieval vs HEMA — Differences

| Aspect | Medieval formation | HEMA (duel) |
|--------|-------------------|-------------|
| **Vor/Nach** | Less explicit. Formation advances or holds. | Core concept — who has initiative. |
| **Feints** | Rare in dense shield wall (no room). More in loose/open. | Common — probing, baiting parry. |
| **Controlling** | Shield wall "holding the line" = collective control. | Bind, Fühlen (feeling), keep blade engaged. |
| **Exhaustion** | Triggers rotation. State change = fall back. | Triggers defensive play; can't sustain Vor. |

**Synthesis:** For Fallen Paths (formation + 1v1 engagement), use **HEMA stance concepts** (Vor/Nach/Indes) mapped to **four explicit stances**, modulated by **stamina** and **personality/skill**. Formation context affects which stances are viable (tight = less feinting; loose = more controlling).

---

## Part 5: Implementation Outline

### 5.1 Data

```
combatant.stance: "defensive" | "balanced" | "aggressive" | "controlling"
combatant.stance_preference: "cautious" | "reckless" | "tactical" | "balanced"  # from personality/trait
```

### 5.2 Stance Choice Logic (AI)

1. Check stamina — filter out stances below min_stamina.
2. Situation — outnumbered? wounded ally? winning?
3. Preference — cautious → defensive bias; reckless → aggressive bias; tactical → controlling when useful.
4. Pick stance for this action/phase.

### 5.3 Modifier Application

- When resolving parry: `parry_capacity *= stance_parry_mod(stance)`
- When resolving damage: `damage *= stance_damage_mod(stance)`
- When resolving close attempt: `attacker_roll` modified by attacker stance; `defender_evasion` by defender stance.
- When resolving disengage: if defender has **controlling** stance, `attacker_disengage_difficulty *= 1.15` (or similar).

### 5.4 Controlling — Feint / Bind Integration

- Controlling stance **enhances** feint effectiveness (when feints are implemented).
- Controlling **increases** opponent's action cost or difficulty for disengage and close.
- Represents: "I'm keeping you busy, you can't easily turn away or press someone else."

---

## Part 6: Recommendation Summary

1. **Four stances:** Defensive, Balanced, Aggressive, Controlling.
2. **Driven by:** Stamina (gates), personality/trait (preference), weapon/skill (fit), situation (context).
3. **Effects:** Modifiers to parry, evasion, damage, close attempt, and—for Controlling—opponent disengage/close difficulty.
4. **No stamina cost** for stance itself; stamina **gates** which stances are available.
5. **Controlling** = feint/bind emphasis; makes it harder for opponent to fall back or engage others.

---

## References

- HEMA Vor/Nach/Indes — Liechtenauer, Ringeck, Meyer (HEMA 101, Keith Farrell)
- `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` — formation density
- `docs/STATE_MACHINE_PARRY_REALISM.md` — defensive stance option
- `docs/FEINT_COUNTER_STAMINA_READINESS_DIAGONAL_INVESTIGATION.md` — feint approaches
