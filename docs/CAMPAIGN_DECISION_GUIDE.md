# Campaign decision guide — research-backed defaults

**When to open this file:** Only when you hit the matching **Decision gate** on a [`SHIP_PLAN`](SHIP_PLAN.md) `Camp-*` row (or [`decision-gates`](SHIP_PLAN.md#decision-gates-at-implementation) table). **Do not** choose everything up front.

**Purpose:** Pros/cons + physics alignment for that gate. Grounded in **your shipped sim** (`BleedingConstants`, `CombatResearchAnchors`) plus ATLS/CoTCCC, merc-game peers, and RimWorld CE patterns.

**After you choose:** Log one line in [`SHIP_PLAN` decision log](SHIP_PLAN.md#decision-log) · replace the matching **`CompanyState` stub** (see [§19](SHIP_PLAN.md#implementation-stubs)) · delete `TODO(decision-*)` in touched files.

| Gate (Camp row) | Read section |
|-----------------|--------------|
| Camp-1.2 | [D-day](#d-day) |
| Camp-1.4 | [D-encounter](#d-encounter) |
| Camp-1.6 | [D-camp-ui](#d-camp-ui) (+ heal duration there) |
| Camp-1.8 | [D-casualty](#d-casualty) |
| Camp-2.1 | [D-bleed](#d-bleed) |
| Camp-2.3 / 2.5 | [D-supply-battle](#d-supply-battle) |
| Camp-2.4 | [D-affliction](#d-affliction) |
| Camp-2.6 | [D-bankrupt](#d-bankrupt) |
| Camp-5 | [D-persistence](#d-persistence) |

**No gate (use §12 numbers, tune in playtest):** Camp-1.1, 1.3 map pools, 1.5 layout, 1.7 formulas, Camp-4 templates.

---

## How this ties to your physics

| Anchor (repo) | Value | Literature / design |
|---------------|-------|---------------------|
| Reference untreated TTD | **~48 s** | CoTCCC/ATLS band **30–120 s** (`LITERATURE_TTD_*`) |
| Death threshold | **35%** blood remaining | ATLS Class IV (>40% lost) |
| Triage danger / peril | **55%** / **42%** @ **90 s** / **45 s** | UI bands vs ~48 s ref TTD |
| Map step time | **60 s** / step | `CampaignEncounterBridge.advance_party_overworld_minute` |
| Direct pressure | **×0.5** bleed mult → **~2× TTD** | `LITERATURE_PRESSURE_TTD_RATIO_TARGET` ≈ 2 |
| Med skill | INT → **0.5–1.5×** efficacy | Separate from supply factor (Camp-2.3) |

**Implication:** One overworld step (60 s) with **untreated** reference arterial bleed is enough to cross from “hurt” to “peril” — map policy and ETA UI are not cosmetic.

---

<a id="d-bleed"></a>

## D-bleed — Map bleed policy (Camp-2.1)

| Option | Behavior |
|--------|----------|
| **A** | Block map move if `party_has_untreated_wounds` |
| **B** | Allow move; Party menu shows ATLS band + bleed ETA to danger/peril |
| **C** | Tutorial **A**; campaign **B** |

### Research

- **ATLS / “golden hour”:** Second peak deaths (minutes–hours) are often **compressible hemorrhage** when resuscitation runs ahead of control — supports making untreated bleed **visible and urgent**, not silent ([ATLS trimodal model](https://pubhtml5.com/oxsy/uctd/ATLS_10th_Edition_Student_Manual/32)).
- **CoTCCC:** Extremity hemorrhage control is **immediate**; delay is measured in **minutes**, not abstract turns ([TCCC MP guidelines](https://www.naemt.org/docs/default-source/education-documents/tccc/tccc-mp-updates-190801/tccc-guidelines-for-medical-personnel-190801.pdf)).
- **Your sim:** At 13.5 HP/s reference bleed, **48 s** to death threshold → **one 60 s map step** without treatment is lethal for worst case.
- **ACE / Phoenix Command:** Player legibility = **time-to-critical** display, not hard gates.
- **CDDA / survival roguelikes:** Hard blocks on travel until stabilized reduce frustration from “didn’t know I was dying.”

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **A** | No silent bleed-out on map; teaches TCCC order; simple to implement | Can feel railroaded; blocks exploration after messy wins; frustrates if UI didn’t teach treatment |
| **B** | Matches deep sim + merc loop (move to contract while hurt); ACE-style triage card; uses existing thresholds | Requires **Camp-3.2** ETA to be correct and loud; players can still ignore warnings |
| **C** | Best onboarding + best campaign feel | Two code paths; tutorial must use policy A clearly |

**Lean:** **C** (tutorial A, campaign B) — aligns with Camp-3.2/3.1 order and your research chain without dumbing down the full loop.

---

<a id="d-supply-battle"></a>

## D-supply-battle — Med supplies in battle (Camp-1.3, 2.3, 2.5)

| Option | Behavior |
|--------|----------|
| **E1** | **Efficacy only:** 0 med → `supply_factor` floor (e.g. 0.5); no per-action spend |
| **E2** | **−1 med** per successful bandage/pack (or per medical phase “treatment burst”) |
| **E3** | **Hybrid:** efficacy floor + **−1** only for **pack** / **stabilize** (Camp-2.5) |

### Research

- **RimWorld:** Medicine mainly changes **Medical Potency** (tend quality / surgery), not one-shot deletes for every bandage ([Medical Potency](https://rimworldwiki.com/wiki/Medical_Potency): herbal 0.6, industrial 1.0).
- **RimWorld CE:** Stabilize costs **one medicine**, temp bleed reduction — explicit map/battle bridge ([CE stabilizing](https://github.com/CombatExtended-Continued/CombatExtended)).
- **CoTCCC:** Hemostatic dressings + **≥3 min** direct pressure — treatments are **events**, not infinite free actions ([CoTCCC MP](https://www.naemt.org/docs/default-source/education-documents/tccc/tccc-mp-updates-190801/tccc-guidelines-for-medical-personnel-190801.pdf)).
- **Your sim:** INT already scales efficacy; duplicate “pay per click” + floor can feel punishing in **medical phase** (already time-expensive).

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **E1** | Clean Camp-2.3; fewer battle UI hooks; matches potency model | Less BB inventory tension; players hoard med on map only |
| **E2** | Strong economic sink; BB-like supply attrition | Can stall medical phase; tuning hell with INT×supply; feels bad if you win fight but run out mid-triage |
| **E3** | CE-like “big” spends; bandage/pressure stay playable at 0 med (low efficacy) | More rules to explain |

**Lean:** **E3** — `supply_factor` always (E1) + **−1 med** for pack and optional stabilize (Camp-2.5). Camp heal stays **−1** per [§18](SHIP_PLAN.md#battle-supply-consumption).

---

<a id="d-day"></a>

## D-day — Wage / calendar tick (Camp-1.2)

| Option | Behavior |
|--------|----------|
| **T1** | **N overworld steps** = 1 day (wages at boundary) |
| **T2** | **“End day”** control (camp / Party menu); steps free, wages on button |
| **T3** | **Hybrid:** wages every N steps **or** early end-day at camp tile |

### Research

- **Battle Brothers:** Wages at **noon** once per day; time passes on world map (~**1:45 real min**/day); town pauses clock ([BB mechanics](https://battlebrothers.fandom.com/wiki/Game_Mechanics)).
- **Your map:** 3×3, **60 s**/step → N=3 steps ≈ **3 min** game time per “day” if player moves constantly (fast pressure).

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **T1** | Automatic pressure; no extra UI; easy to test | Punishes exploration; unclear to player why wages fired; conflates with bleed tick (same step hook) |
| **T2** | BB-like “make money before noon”; clear player agency | Players forget → surprise bankrupt; needs visible “day N” + bill preview |
| **T3** | Teaches camp tile; flexible | Two systems to maintain |

**Recommended N (if T1 or T3):** **5 steps** ≈ **300 s** game time (~6× ref TTD) — one “day” is several map moves, not three.

**Lean:** **T3** with **N = 5** default steps, **End day** at camp (Party menu or camp tile). Log `overworld_step_count` in `company_state` ([§10](SHIP_PLAN.md#data-contracts)).

---

<a id="d-bankrupt"></a>

## D-bankrupt — Company failure (Camp-2.6)

| Option | Behavior |
|--------|----------|
| **B1** | **Hard bankrupt:** gold &lt; 0 after wages → run ends (modal + restart) |
| **B2** | **Grace loan:** once per run, −50 gold “debt” with 3-day repayment |
| **B3** | **BB-style desertion:** negative gold → mood/desertion cascade, not instant game over |

### Research

- **BB:** No formal “bankruptcy screen”; **unpaid wages + starvation** erode morale → **desertion**; company dies by attrition ([BB survival loop](https://www.sevastromo.com/battle-brothers/)).
- **Merc design:** Economic failure should be **understandable** (wage bill preview) more than sudden.

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **B1** | Clear lose condition for §8 playtest; simple | Harsh for learning; less BB fantasy |
| **B2** | One mistake recoverable; teaches budgeting | Can be exploited; needs UI copy |
| **B3** | Deep BB feel | Needs mood/desertion systems not in EA plan; slow fail confusing |

**Lean:** **B1** for EA checklist + **HUD “next wage: X”** warning at gold &lt; 2× bill. Add B2 post-EA if playtests feel too punishing.

---

<a id="d-encounter"></a>

## D-encounter — Contract tile lifecycle (Camp-1.4, §11)

| Option | Behavior |
|--------|----------|
| **R1** | Respawn marker **on win only** |
| **R1b** | **Defer `queue_free`** until victory; loss leaves same contract |
| **R2** | Cooldown days per tile |
| **R3** | Finite contract pool |

### Research

- **BB:** Contracts are UI nodes, not consumed tiles; failure **does not erase** the contract from the board.
- **Your code:** `queue_free` on step-in makes **R1 alone** punish loss with empty tile.

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **R1** | Simple spawner | Bad loss UX on small 3×3 |
| **R1b** | BB-fair retries; no respawn scheduler | Slightly more state (`active_contract` meta) |
| **R2** | Pacing / scarcity | Empty map confusion |
| **R3** | Run arc | Can end run early with no jobs |

**Lean:** **R1b** (documented default in [§11](SHIP_PLAN.md#encounter-lifecycle)).

---

<a id="d-camp-ui"></a>

## D-camp-ui — Camp heal entry (Camp-1.6)

| Option | Behavior |
|--------|----------|
| **H1** | Fixed **camp tile** on grid |
| **H2** | **Party menu** button |
| **H3** | Both |

### Research

- **BB:** Healing in **town** UI, not tile type.
- **CoTCCC / prolonged field care:** Stabilize then **evac** — camp is “safe phase” abstraction, not geometry.

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **H1** | Spatial “inn” fantasy | Tilemap has no layer yet; 3×3 crowded |
| **H2** | Ships fast; works with D-bleed B | Less discoverable |
| **H3** | Best UX | Two entry points to test |

**Lean:** **H2** for Camp-1.6; add **H1** at `Vector2i(2,2)` when tutorial exists (Camp-3.1).

### Camp heal **time cost** (sub-choice)

| Option | Game time advanced | Map steps equivalent |
|--------|-------------------|----------------------|
| **180 s** | 3 min | 3 steps |
| **300 s** | 5 min | 5 steps (matches bandage hemostasis band min) |
| **600 s** | 10 min | 10 steps |

**Lean:** **300 s** + **−1 med** — aligns with `LITERATURE_BANDAGE_HEMOSTASIS_HALF_LIFE_S_MIN` (60–300 s) in `CombatResearchAnchors`; meaningful `process_healing` without full reset.

---

<a id="d-affliction"></a>

## D-affliction — Permanent campaign injuries (Camp-2.4)

Pick **one** starter affliction + **trigger** thresholds tied to ATLS/BB.

### Trigger candidates (physics-aligned)

| Trigger | Sim basis | BB parallel |
|---------|-----------|-------------|
| **Blood &lt; 42%** at fight end | `MEDICAL_TRIAGE_PERIL` | “Struck down” severe |
| **Blood &lt; 50%** | Class II–III band | Moderate permanent injury |
| **Any part bone ≤ 25% max** | Structural cripple | Crippled limb injuries |
| **≥2 parts** with untreated arterial at end | TCCC failure to control | Rare multi-hit |

| Apply chance | Pros | Cons |
|--------------|------|------|
| **100%** if trigger | Predictable tests | Harsh early campaign |
| **50%** if trigger | BB ~33% survive flavor | RNG complaints |
| **Scaling with renown** | Later fights scar more | Complex |

### Starter affliction examples (one for EA)

| Affliction | Effect | BB analog |
|------------|--------|-----------|
| **Slowed circulation** | −10% max stamina or −5 END | Weakened heart |
| **Partly collapsed lung** | −15% max fatigue | Partly collapsed lung |
| **Old wound ache** | +pain decay rate | Scars (flavor) |

**Lean:** Trigger **blood &lt; 42%** at victory screen (survived fight, still peril band) → **50%** chance **Slowed circulation** (−10% max stamina). Store on **`CoreEntity`**. Combat applies; Campaign displays.

---

<a id="d-casualty"></a>

## D-casualty — Dead brothers after victory (Camp-1.8)

| Option | Behavior |
|--------|----------|
| **K1** | Auto-remove dead from `PartyManager` on settlement continue |
| **K2** | Settlement lists dead; player confirms removal |
| **K3** | Auto-remove + **memorial line** in settlement log |

### Research

- **BB:** Death is **permanent**; no ghost roster entries.
- **Your code:** Dead can remain in `members` with invalid refs until cleaned.

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **K1** | No stale refs; simple | Emotional beat skipped |
| **K2** | Player acknowledgment | Extra click |
| **K3** | Best narrative + clean roster | Slightly more UI |

**Lean:** **K3** for EA — one line per fallen brother, then remove from roster.

---

<a id="d-persistence"></a>

## D-persistence — Save scope (§13)

| Option | Behavior |
|--------|----------|
| **P1** | Session-only (restart `main` = new company) |
| **P2** | Single-slot autosave on settlement continue |
| **P3** | Save at camp + after each contract |

### Pros / cons

| Option | Pros | Cons |
|--------|------|------|
| **P1** | Zero scope; matches 2–4 h sit | Crash = loss |
| **P2** | Safety net for EA | Serialize wounds + company_state + meta |
| **P3** | Full merc fantasy | Scope creep |

**Lean:** **P1** for Camp-5; **P2** as first post-EA row if playtests demand it.

---

<a id="ea-tuning"></a>

## §12 economy tuning — sensitivity (not a binary decision)

Starting values in [SHIP_PLAN §12](SHIP_PLAN.md#ea-tuning-defaults) are **BB-scaled to 2–4h**, not physics-derived.

| Knob | If too hard | If too easy |
|------|-------------|-------------|
| Starting gold **500** | Raise to **700** | Lower to **400** |
| Wage **15×head** | Lower to **12** | Raise to **18** |
| Med **3** | +1 starter | −1; force shop tension |
| Pay **80–150** | +20% base | −15% |

**Physics-safe rule:** Do **not** fix map bleed frustration by changing `BLOOD_LOSS_RATE_MULTIPLIER` during Campaign ship — use policy **B/C** + supplies ([`LIVE_PATHS` §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain)).

---

<a id="recommended-bundle"></a>

## Optional fast path (only if you want every gate pre-decided)

Skip this section if you are using [just-in-time gates](SHIP_PLAN.md#decision-gates-at-implementation). Otherwise copy-paste when starting implementation:

```markdown
- YYYY-MM-DD — D-bleed → C (tutorial A, campaign B)
- YYYY-MM-DD — D-supply-battle → E3 (efficacy floor + −1 pack/stabilize)
- YYYY-MM-DD — D-day → T3 (5 steps or End day at camp)
- YYYY-MM-DD — D-bankrupt → B1 + wage warning HUD
- YYYY-MM-DD — D-encounter → R1b
- YYYY-MM-DD — D-camp-ui → H2 now, H1 at (2,2) with tutorial
- YYYY-MM-DD — camp heal time → 300 s, −1 med
- YYYY-MM-DD — D-affliction → blood <42% end fight, 50% → −10% max stamina
- YYYY-MM-DD — D-casualty → K3
- YYYY-MM-DD — D-persistence → P1 (EA)
```

---

## References (external)

- ATLS hemorrhage classes / early control: [ATLS 10th ed. excerpts](https://pubhtml5.com/oxsy/uctd/ATLS_10th_Edition_Student_Manual/62)
- Extremity bleed timing / tourniquet urgency: [Platinum 5 min model](https://pubmed.ncbi.nlm.nih.gov/29547925/); [tourniquet 3 h surgical window](https://pmc.ncbi.nlm.nih.gov/articles/PMC6611996/)
- TCCC hemorrhage ladder: [NAEMT TCCC MP PDF](https://www.naemt.org/docs/default-source/education-documents/tccc/tccc-mp-updates-190801/tccc-guidelines-for-medical-personnel-190801.pdf)
- BB economy / injuries: [Game Mechanics](https://battlebrothers.fandom.com/wiki/Game_Mechanics); [Permanent Injuries](https://battlebrothers.fandom.com/wiki/Permanent_Injuries)
- RimWorld medicine potency: [Medical Potency](https://rimworldwiki.com/wiki/Medical_Potency); CE stabilize: [Combat Extended repo](https://github.com/CombatExtended-Continued/CombatExtended)

**In-repo:** [`LIVE_PATHS.md#bleeding-physics`](LIVE_PATHS.md#bleeding-physics) · [`CombatResearchAnchors.gd`](../core/CombatResearchAnchors.gd) · [`BleedingConstants.gd`](../core/BleedingConstants.gd)
