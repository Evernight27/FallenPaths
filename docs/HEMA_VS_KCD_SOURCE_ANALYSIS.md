# Historical Longsword vs. KCD Game Design: Source Analysis

Investigation to separate recommendations based on **actual Liechtenauer/Meyer/medieval longsword sources** from those that are **Kingdom Come: Deliverance game design choices**. Purpose: identify which implementations would be more accurate for **physical realism** when simulating historical combat.

---

## 1. Methodology

For each mechanic, we trace:
- **Historical source**: Liechtenauer (Zettel, glosses), Ringeck, Meyer, Fiore, Italian masters (Dall'Agocchie, Giganti, Fabris), archaeological evidence (Matzke), HEMA research (Sword STEM)
- **KCD implementation**: What the game does and how it presents it
- **Verdict**: Historical / KCD hybrid / KCD-only / Neither

---

## 2. Zone Systems & Directional Guard

### Historical Longsword

**Liechtenauer / Meyer:** Four primary positions (Vier Leger):
- **High** (Vom Tag) — blade above/at shoulder
- **Fool** (Alber) — low, center or side
- **Ox** (Ochs) — point forward, hilt raised
- **Plough** (Pflug) — point forward, hilt at hips

These are **weapon positions that cover lines** (high, low, left, right), not body-part targets. The HEMA 101 Liechtenauer guards article: "They are better described as 'noteworthy positions'... The 'guards' do not guard you in the sense that they block attacks (although they can do!). Think of them as positions of being 'in guard', i.e. ready to do something."

**Key:** Guards are **lines/directions** (high, low, left, right). Parries use the same cuts that end in these positions — "Oberhau parries Oberhau" (like covers like). An Oberhau ends in Plough; an Unterhau ends in Ox. The geometry of the strike determines what it defends against.

**Body targeting:** Meyer divides body into four quarters (upper/lower left and right); head has four sub-zones for close work. Archaeological (Matzke): head 40–92% of wounds; torso 0–40%; arms/legs variable. Sources don't prescribe "5 zones" as attack directions.

### KCD Implementation

- **5 zones**: Head, left upper, right upper, left lower, right lower
- **Directional block**: Hold block in one of these directions; attack from unblocked direction = hits
- **Design origin**: Controller input (stick or keys for directions), simplified for first-person gameplay

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Directional guard (cover one line, expose others) | **Yes** | No | Liechtenauer: guards cover lines. Same concept. |
| **4 lines** (high/low/left/right) | **Yes** | No | Historical uses 4. |
| **5 body zones** as input directions | **No** | **Yes** | KCD uses 5 for controller ergonomics. Historical: 4 weapon lines, body targeting separate. |
| Guard = block in one direction | Partial | Yes | Historical: guard is *position* from which you parry/counter; parry uses a cut. KCD: static block direction. |

**For physical realism:** Use **line-based guard** (high/low/inside/outside or 4 lines) rather than body-part guard. Line-based maps to Liechtenauer's 4 positions. Body-part guard (6 parts) is acceptable as an abstraction of "which line is defended" if you map parts to lines (head=high, legs=low, etc.).

---

## 3. Combos (Sequential Strikes → Bonus Finisher)

### Historical Longsword

**Liechtenauer / Meyer:** No evidence of scripted combo sequences (e.g. "head → right upper → left lower → finisher"). The ARMA Mastercuts essay: "Liechtenauer's instruction to make rapid strikes one after the other without pause" — continuous pressure, not prescribed sequences. Meyer's cuts flow through guards (Tag → Longpoint → Alber) but as *mechanics of a single cut*, not "land hit 1, then hit 2, then finisher."

**Archaeological:** Multiple wounds common (Matzke); fighters received several blows. That supports *flurries* and *repeated strikes*, not *scripted combos with bonus damage*.

### KCD Implementation

- Sequential strikes to specific zones (e.g. head → R.upper → L.lower) → special finisher, bonus damage
- Learned from trainers; each weapon has unique combos
- "Harder to block" when executing combo
- **Source:** Fighting game design (Street Fighter, etc.). Warhorse consulted Fechtbücher but combos are a **gameplay mechanic** for engagement and late-game difficulty scaling.

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Combo sequences (head→arm→leg→finisher) | **No** | **Yes** | No historical source. Fighting game convention. |
| Rapid successive strikes | **Yes** | No | Liechtenauer: "rapid strikes without pause." |
| Bonus damage for sequence | **No** | **Yes** | Game balance. |
| "Harder to block" during combo | **No** | **Yes** | Game mechanic. |

**For physical realism:** **Do not implement combos** as KCD-style sequences. Prefer: (a) rapid exchanges via counter window / tempo, (b) binding → thrust from bind, (c) preferred_parts per cut type. Combo *progress* and *finisher bonus* are KCD, not historical.

---

## 4. Master Strike (Early Block → Automatic Counter)

### Historical Longsword

**Meisterhau (Mastercuts):** The five *strikes* — Zornhau, Krumphau, Zwerchhau, Schielhau, Scheitelhau. These are techniques that (a) break specific guards, or (b) counter incoming attacks while simultaneously striking. ARMA: "The Mastercuts defensively close off a line of attack from the opponent while **simultaneously** counter-attacking."

**Critical:** "This is **not an issue of perfect timing**, as might be supposed, but rather one of **correct geometry**, put in place by the simple response mechanism of training." You choose the correct Meisterhau for the opponent's guard/attack; the strike *is* the parry. No "block then auto counter" — the attack and defense are one action.

**Absetzen:** Thrust-parry from Plough — parry with a thrust. Same idea: single action that defends and attacks. Not "block at perfect moment, then guaranteed counter."

### KCD Implementation

- Block at exact moment (green icon) during opponent's swing → automatic, unavoidable counter
- Timing-based: player must react to visual cue
- "Master Strike" named after Meisterhau but **mechanically different**: KCD = timing window + guaranteed damage; historical = geometry + technique choice

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Parry + counter | **Yes** | No | Liechtenauer: parry with Zornhau, end in Plough, thrust. |
| **Timing-based** perfect block | **No** | **Yes** | Historical: geometry, not reaction timing. |
| **Automatic unavoidable** counter | **No** | **Yes** | Game balance; real counters can fail. |
| Early parry = better outcome | Partial | Yes | Catching attack early = control (Liechtenauer). But "auto counter" is KCD. |

**For physical realism:** Prefer **riposte priority** (parry_deflect → defender acts first) over **master strike** (guaranteed auto counter). Historical: successful parry puts you in position to thrust; the counter is not "unavoidable." Early parry could grant *initiative* or *reduced counter cost*, not guarantee. KCD's master strike is a game reward for timing, not physics.

---

## 5. Perfect Block & Riposte

### Historical Longsword

**Dall'Agocchie (#5):** "Once you've parried your enemy's blow, then it's a tempo to attack." Parry creates opportunity. Riposte (thrust or cut from the parry position) is standard.

**No "perfect" vs "imperfect" block** in historical sources. A parry either works (you deflect, end in good position) or it doesn't. The concept of "block during swing = riposte priority" aligns: good parry → you're set to counter.

### KCD Implementation

- "Perfect block": Block during opponent's swing (not before) → bullet-time, riposte with priority
- Visual cue (green shield) for timing
- Separates "hold block" from "timed block"

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Parry → counter (riposte) | **Yes** | No | Universal in sources. |
| **Timed** block (during swing) vs hold block | Partial | Yes | Historical: parry is an action (cut into theirs), not "hold block." But "parry during their strike" is correct. |
| Bullet-time / riposte priority | **No** | **Yes** | UX and game feel. |
| Defender gets next action | **Yes** | No | Matches "tempo to attack after parry." |

**For physical realism:** **Riposte priority** (parry_deflect → defender acts first or at reduced cost) is historical. The "perfect" vs "imperfect" distinction is acceptable as parry quality (full deflect vs partial). Avoid bullet-time; keep it as initiative/order of actions.

---

## 6. Feints

### Historical Longsword

**Italian sources (Giganti, Capo Ferro):** Feint is central. Threaten one line to draw parry; disengage; hit the other. Single-tempo action. Dall'Agocchie: provocations "incite him to strike, so that one can attack him more safely." Fabris: attack tempo must be "proportionally shorter" than defender's response.

**German longsword:** Less explicit feint doctrine than Italian rapier, but Meyer describes cuts that deceive (Change Cut, Short Cut, etc.). The principle of "threaten to open" is shared across traditions.

### KCD Implementation

- "Feinting": Hold attack, switch direction before release
- Uses the 5-zone input system
- No separate feint mechanic; feint = abort and re-aim

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Feint (threaten one target, hit another) | **Yes** | No | Italian sources, Meyer. |
| Direction switch during wind-up | Partial | Yes | KCD uses zone switch. Historical: disengage to different line. Same idea. |
| Feint as provocation | **Yes** | No | Dall'Agocchie. |

**For physical realism:** **Feint is historical.** Implement as telegraph vs real target (feint_part ≠ target_part). Cost per Fabris: feint should be proportionally shorter than defender's parry — slight wind-up increase acceptable; wrong guard = parry penalty. This is independent of KCD.

---

## 7. Kick

### Historical Longsword

**Fiore:** Groin kicks, knee stomps in grappling contexts. **But** Fiore warns against striking below the knee in two-handed sword work while standing — leaves you exposed.

**Ringeck / Liechtenauer:** No prominent kick-to-break-guard in core longsword plays. Grappling (ringen am schwert) exists but is distinct. Ernst Fechten (Peters): "It is far better to wound or kill with your sword in krieg than to wrestle."

### KCD Implementation

- Kick to break guard; staggers opponent
- Used when enemy is blocking
- Simple, reliable anti-block tool

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Kick in sword combat | Partial | No | Fiore has kicks in grappling. |
| Kick to **break guard** | **No** | **Yes** | No clear historical precedent. Likely game design for block-break. |
| Stagger/disrupt | Partial | Yes | Pommel strike, grappling exist. Kick as guard-break is KCD. |

**For physical realism:** **Kick-to-break-guard is KCD**, not well attested in longsword sources. If you add it, treat as game option. Historical alternative: pommel strike, or close to bind (measure) and thrust. Focus on sword techniques first.

---

## 8. Stamina

### Historical Longsword

No "stamina bar" in sources. But: fatigue, wounds, and exhaustion matter. Ringeck: cut decisively; hesitation yields poor results. Psychological and physical fatigue would reduce effectiveness. Indirectly supported.

### KCD Implementation

- Stamina depletes with block, attack, sprint, low health
- Low stamina → weak attacks, block breaks, vulnerable to finisher
- Standard action-game resource

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Fatigue affects performance | **Yes** | No | Physically true. |
| Stamina bar / resource pool | **No** | **Yes** | Abstraction for game pacing. |
| Block break when exhausted | Partial | Yes | Plausible; not explicitly in sources. |

**For physical realism:** Fatigue/readiness affecting power and parry is realistic. Your **gauge** or a stamina-like pool is an acceptable abstraction. Not a KCD invention; common in games. Physical basis: yes.

---

## 9. Counter Window (Act During Opponent Wind-Up)

### Historical Longsword

**Dall'Agochelle's five tempi** (opportunities to strike):
1. After parrying
2. When his blow has passed outside your body
3. **When he raises his sword to harm you — strike while his hand is rising**
4. When he moves injudiciously from one guard to another, before fixed
5. **When he raises his forward foot** to step — he cannot defend while unsettled

**Fabris:** "The time employed to make one movement cannot be employed to make any other." Opponent committed = your opportunity.

### KCD Implementation

- No explicit "counter window" — you act when your turn/stamina allows
- Perfect block / master strike require opponent to attack first; reaction-based

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Strike during opponent's preparation | **Yes** | No | Dall'Agochelle #3, #4, #5. |
| Partial gauge for immediate counter | **No** | N/A | Abstraction for discrete turn system. |
| "Opponent committed = your chance" | **Yes** | No | Fabris, five tempi. |

**For physical realism:** **Counter window is historical.** Implement as: during enemy wind-up (or guard change, or step if you model it), defender can spend partial gauge for immediate action that resolves first. This aligns with tempo #3, #4, #5. KCD doesn't have this explicitly; it's from historical sources.

---

## 10. Afterblow

### Historical Longsword

**Ernst Fechten (Peters):** "Mutual kills are unacceptable in this craft; a proper defence protects as it places you into a position of advantage." "It does you little good if you can strike your opponent only to be hit shortly thereafter because you were not covered." The sentiment: don't get hit back. Liechtenauer's techniques from the bind are meant to protect you while you strike.

**HEMA rulesets:** Afterblow (strike back after being hit) exists to discourage suicidal commitment in sport. Historical *ethos*: if you hit and then get hit, you failed.

### KCD Implementation

- No afterblow in standard combat
- Single resolution per exchange
- Attacker hits → target takes damage; no "target strikes back during attacker recovery"

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| "Don't get hit back" | **Yes** | No | Ernst Fechten, Liechtenauer. |
| Afterblow as ruleset mechanism | **No** | No | HEMA sport invention to penalize recklessness. |
| Model: hit then get hit = failure | **Yes** | No | Historical ethos. |

**For physical realism:** **Afterblow mechanic is realistic** — if you hit someone who has an attack in progress, their attack can resolve during your recovery (at reduced effect). This discourages all-in commitment and matches "don't get hit back." KCD omits it (gameplay simplification). Implement for realism.

---

## 11. Binding (Blades in Contact)

### Historical Longsword

**Liechtenauer:** Binding (krieg) is central. "A master's fencing is rightfully at the sword." From the bind: winden, thrust, slice. **Measure is critical**: bind at ~30–40 cm; at wide measure, techniques fail. Ernst Fechten: at wrong measure, "nearly everything can be countered."

### KCD Implementation

- Physics-based blade contact (30+ target zones, 4 armor layers)
- Swords clash and slide
- No discrete "bound" state with restricted moves
- Blades interact continuously via physics

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Binding central to technique | **Yes** | No | Liechtenauer, Ringeck. |
| Bind → thrust/winden only | **Yes** | No | Historical: from bind, specific actions. |
| Physics-based contact | Partial | Yes | KCD uses 3D/physics. You're abstract. |
| Discrete "bound" state | **Yes** | No | Would model krieg phase. |

**For physical realism:** **Binding is historical** and core to Liechtenauer. Implementing it in an abstract system requires: measure (close = bound), restricted move set while bound (thrust, wind, etc.). KCD approximates via physics; you'd need state. High fidelity, high cost. Defer unless adding measure.

---

## 12. Preferred Parts per Cut (Attack Path)

### Historical Longsword

**ARMA Mastercuts:** "Remember that your target is always your opponent's head or body, never his weapon." Zornhau "hits the opponent in his upper left opening." Zwerchhau "targets include the head, the hands or the body." Cuts have natural trajectories: Oberhau → head; Unterhau → legs/arms; thrust → center (face/chest).

**Archaeological (Matzke):** Head dominant (40–92%); torso cuts rare; arms low in battle, higher in duel (hand sniping). Thrust to torso preferred over cut to torso in sources.

### KCD Implementation

- 5 zones; player picks direction
- Cut type (slash/stab) affects which zones are natural
- No explicit "preferred parts" per move — player aims

### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Cuts have natural targets | **Yes** | No | Oberhau→head, etc. |
| Head primary target | **Yes** | No | Sources + archaeology. |
| preferred_parts per move | **Yes** | No | Models cut geometry. KCD doesn't encode it explicitly. |

**For physical realism:** **preferred_parts per move is historical.** Oberhau → head, chest; Unterhau → legs, arms; thrust → head, chest, arms. Combine with guard (unguarded preferred = bonus). Independent of KCD.

---

## 13. Summary: Historical vs. KCD

| Mechanic | Historical Source | KCD Design | For Physical Realism |
|----------|-------------------|------------|----------------------|
| **Zone guard** | 4 lines (Liechtenauer) | 5 body zones | Use **line-based** (4) > body-part (6). |
| **Combos** | None (rapid strikes ≠ sequences) | Fighting game | **Skip.** Use tempo, counter, binding instead. |
| **Master strike** | Geometry, not timing; no "unavoidable" | Timing + guaranteed counter | **Skip** guarantee. Use riposte priority; early parry = initiative bonus. |
| **Riposte** | Parry → counter | Timed block → priority | **Implement.** Parry_deflect → defender acts first. |
| **Feint** | Italian, Meyer | Direction switch | **Implement.** feint_part ≠ target_part. Historical. |
| **Kick to break guard** | Not in longsword | Yes | **Skip** or treat as optional. |
| **Stamina** | Fatigue implied | Resource bar | Acceptable abstraction. |
| **Counter window** | Five tempi (Dall'Agochelle) | Not in KCD | **Implement.** Historical. |
| **Afterblow** | "Don't get hit back" | Not in KCD | **Implement.** Historical ethos. |
| **Binding** | Liechtenauer krieg | Physics approximation | **Defer** unless adding measure. |
| **preferred_parts** | Cut geometry, archaeology | Implicit in aiming | **Implement.** Historical. |
| **5 zones** | Not in sources | Controller input | Use **4 lines** or 6 parts with line mapping for realism. |

---

## 14. Revised Realism-Optimized Path

Prioritized by **historical source strength**, not KCD parity:

1. **Line-based guard** (4 lines) — Liechtenauer. Prefer over 5-zone.
2. **Riposte priority** — Dall'Agochelle, universal.
3. **preferred_parts + guard** — Cut geometry, archaeology.
4. **Feint** — Italian, Meyer.
5. **Counter window** — Five tempi.
6. **Afterblow** — Ernst Fechten ethos.
7. **Historical target weights** — Matzke, sources (optional).
8. **Early parry = initiative** (not auto counter) — Liechtenauer.
9. **Binding** — Defer (needs measure).
10. **Skip: combos, master strike guarantee, kick-to-break** — KCD/game design.

---

## References

- ARMA: "The Mastercuts - What They Are and What They Aren't"
- Chicago Swordplay Guild: "Defining Tempo in Italian Swordplay"
- Ernst Fechten: "On Measure in Krieg"
- HEMA 101: Liechtenauer guards, parries, Meyer cuts
- Sword STEM: "Historical Injury vs Modern Tournament Targeting"
- Matzke: "Armed and Educated"
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
