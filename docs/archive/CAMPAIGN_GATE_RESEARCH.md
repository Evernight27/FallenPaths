# Campaign gate research (archived)

Live summary: [`../CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22`](../CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22).

<a id="gate-research-appendix"></a>

## Gate research appendix

Sections below document **options considered before ship**. Tables are **research context only** — do not re-decide unless you are adding a **new** gate. Shipped choice is in the banner and [user bundle](#user-bundle-2026-05-22).

---

<a id="d-day"></a>

## D-day — Wage / calendar tick (Camp-1.2)

> **Shipped (2026-05-22):** **T3** — wages every **5** overworld steps **or** **End day** at camp tile `(0,0)` / Party menu. **`DAY_TICK_MODE`** = `"hybrid"`, **`STEPS_PER_DAY`** = `5`. Below: pre-ship options.

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

---

<a id="d-encounter"></a>

## D-encounter — Contract tile lifecycle (Camp-1.4, §11)

> **Shipped (2026-05-22):** **R3** — finite template deck at boot (`ContractSpawner.spawn_campaign_contracts`); marker **`queue_free` on step-in**; **paid loss ends run** (no same-tile retry). Tutorial soft defeat respawns via `ensure_special_encounter_present`. **`ENCOUNTER_LIFECYCLE`** = `"r3_loss_ends_run"`. Below: pre-ship options.

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

---

<a id="d-camp-ui"></a>

## D-camp-ui — Camp heal entry (Camp-1.6)

> **Shipped (2026-05-22):** **H3** — Party menu **and** camp tile `(0,0)`; **600 s** × **3×** heal mult, **−1 med**; controlled bleed required before camp heal. Tutorial job tile: **`ContractSpawner.TUTORIAL_TILE`** `(1,0)` (not a separate inn). **`CAMP_HEAL_ENTRY`** = `"both"`. Heal rate table: [camp heal rates](#camp-heal-rates-on-move-vs-camp). Below: pre-ship options.

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

### Camp heal **time cost** (sub-choice — research)

| Option | Game time advanced | Map steps equivalent |
|--------|-------------------|----------------------|
| **180 s** | 3 min | 3 steps |
| **300 s** | 5 min | 5 steps (matches bandage hemostasis band min) |
| **600 s** | 10 min | 10 steps |

---

<a id="d-casualty"></a>

## D-casualty — Dead brothers after victory (Camp-1.8)

> **Shipped (2026-05-22):** **K3** — memorial line + **kill recap** from `last_battle_summary`; remove dead from roster on settlement continue / soft defeat. **`CASUALTY_ON_SETTLEMENT`** = `"memorial_then_remove"`. Below: pre-ship options.

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

---

<a id="d-bleed"></a>

## D-bleed — Map bleed policy (Camp-2.1)

> **Shipped (2026-05-22):** **B** (`warn_eta` after first win) + **tutorial block** until first win (`MapBleedPolicy.POLICY_BLOCK` when bleed risk present) + **Party field care** (`MapFieldCare`: pressure → optional stabilize → bandage; procedure time runs bleed physics only — see [`LIVE_PATHS#bleeding-physics`](LIVE_PATHS.md#bleeding-physics)). **Camp rest** requires **dressed** wounds (`bandaged`/`pack`/`TQ`), not stabilize alone. Not gate **C** (separate A/B fork post-tutorial). **`MAP_BLEED_POLICY`** = `"warn_eta"`. Below: pre-ship options.

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

**Ship note:** Tutorial block until first win achieves onboarding goals of **A** without maintaining a separate post-tutorial policy fork (**C** was superseded).

---

<a id="d-supply-battle"></a>

## D-supply-battle — Med supplies in battle (Camp-1.3, 2.3, 2.5)

> **Shipped (2026-05-22):** **E3** — `supply_factor` floor (**0.5** at 0 med) always; **−1 med** for **pack** and **stabilize** (Camp-2.5). Camp heal separate **−1** per [§17](SHIP_PLAN.md#battle-supply-consumption). **`MED_BATTLE_MODE`** = `"hybrid"`, **`SUPPLY_FACTOR_AT_ZERO_MED`** = `0.5`. Below: pre-ship options.

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

---

<a id="d-affliction"></a>

## D-affliction — Permanent campaign injuries (Camp-2.4)

> **Shipped (2026-05-22):** **Tier RNG** post-victory (`CampaignAfflictions.gd`); **`AFFLICTIONS_ENABLED`** = `true`. Trigger table and probabilities: [affliction RNG](#affliction-rng-medieval-alignment). Below: simplified pre-ship sketch.

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

**Pre-ship sketch (superseded):** single-trigger **50%** at blood &lt; 42% — replaced by tier table above.

---

<a id="d-bankrupt"></a>

## D-bankrupt — Company failure (Camp-2.6)

> **Shipped (2026-05-22):** **B3** — desertion at low **company mood**; insolvency **warns** (HUD next-wage hint); run ends when roster empty / last deserter. **`BANKRUPT_MODE`** = `"desertion"`. Not instant gold &lt; 0 wipe (**B1**). Integration: [B3 desertion](#b3-desertion-integration-points). Below: pre-ship options.

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
| **B3** | Deep BB feel; shipped in EA | Slow fail can confuse if wage warn is missed |

---

<a id="d-persistence"></a>

## D-persistence — Save scope (Camp-5, §13)

> **Shipped for EA (2026-05-22):** **P1** — session-only (restart / paid R3 reload = new company). **Open post-EA:** **P2** single-slot autosave on settlement continue if playtests demand it. Below: pre-ship options.

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

---

<a id="ea-tuning"></a>

## §12 economy tuning — sensitivity (not a binary decision)

Starting values in [SHIP_PLAN §12](SHIP_PLAN.md#ea-tuning-defaults) are **BB-scaled to 2–4h**, not physics-derived.

| Knob | If too hard | If too easy |
|------|-------------|-------------|
| Starting gold **500** | Raise to **700** | Lower to **400** |
| Wage **15×head** | Lower to **12** | Raise to **18** |
| Med **3** | +1 starter | −1; force shop tension |
| Pay **100–140** (shipped templates) | +20% base | −15% |

**Physics-safe rule:** Do **not** fix map bleed frustration by changing `BLOOD_LOSS_RATE_MULTIPLIER` during EA ship — use **D-bleed B** + tutorial block + supplies + field care ([`LIVE_PATHS` §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain)).

---

<a id="recommended-bundle"></a>

## Recommended bundle (superseded)

Use [User bundle](#user-bundle-2026-05-22) · [`SHIP_PLAN` decision log](SHIP_PLAN.md#decision-log).

## References (external)

- ATLS hemorrhage classes / early control: [ATLS 10th ed. excerpts](https://pubhtml5.com/oxsy/uctd/ATLS_10th_Edition_Student_Manual/62)
- Extremity bleed timing / tourniquet urgency: [Platinum 5 min model](https://pubmed.ncbi.nlm.nih.gov/29547925/); [tourniquet 3 h surgical window](https://pmc.ncbi.nlm.nih.gov/articles/PMC6611996/)
- TCCC hemorrhage ladder: [NAEMT TCCC MP PDF](https://www.naemt.org/docs/default-source/education-documents/tccc/tccc-mp-updates-190801/tccc-guidelines-for-medical-personnel-190801.pdf)
- BB economy / injuries: [Game Mechanics](https://battlebrothers.fandom.com/wiki/Game_Mechanics); [Permanent Injuries](https://battlebrothers.fandom.com/wiki/Permanent_Injuries)
- RimWorld medicine potency: [Medical Potency](https://rimworldwiki.com/wiki/Medical_Potency); CE stabilize: [Combat Extended repo](https://github.com/CombatExtended-Continued/CombatExtended)

**In-repo:** [`LIVE_PATHS.md#bleeding-physics`](LIVE_PATHS.md#bleeding-physics) · [`CombatResearchAnchors.gd`](../core/CombatResearchAnchors.gd) · [`BleedingConstants.gd`](../core/BleedingConstants.gd)
