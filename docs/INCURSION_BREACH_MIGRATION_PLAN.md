# Incursion & Breach Migration Plan

Plan to evolve the tactical layer from **aggregate pressure + lane stress** toward a **physically interpretable** breach model: spear-wall vs heavy fighter, **rank penetration**, **flank/rear exposure**, and **surround cost**—while **keeping** abstract formation state (`rank`, `file`, `distance_to`, `zone_id`, no continuous `(x,y)`).

**Related docs:** `docs/IMPLEMENTATION_OUTLINE.md` (Phase 4–6), `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` (if present), `docs/FF4_REMAINING_DECISIONS_CHECKLIST.md` (**Notes** section links here for incursion/breach work).

---

## 1. Goals

| Goal | Success criteria |
|------|------------------|
| **Tactical breach** | A unit can **enter a “deep” state** or **mark a file/edge breached** from **reach + spacing + local ZoC**, not only front-rank headcount. |
| **Rank breaking** | **Penetration depth** (e.g. `0 = front line`, `1 = past first rank`) is explicit and affects **engagement angle**, **surround load**, and optionally **targets**. |
| **Physics-flavored inputs** | Core levers are **meters** (reach, spacing), **time** (wind-up, reaction), **mass** (where already used)—constants are **tunable proxies** with documented meaning. |
| **No position tracking** | Still **no** continuous positions; only **coarse** grid + bands + optional **enum/depth** flags. |
| **Avoid double-count** | **Bodies** stay in `obs_pen`; **global** incursion and **local** breach use **headroom** or **separate terms** (see current `ZoneOfControl._raw_zone_strength`). |

---

## 2. Current Baseline (snapshot)

- **`TacticalCombat.recompute_incursion_pressure`**: global `delta = opp_front − our_front` → `incursion_pressure`; **`lane_stress_by_file`** from dual living + density.
- **`ZoneOfControl._raw_zone_strength`**: merges **global + lane** with **headroom**; **zone exposure** (front > flank > rear); **`obs_pen`** separate.
- **`TacticalCombat.count_engaging_threats` / `surround_defense_multiplier`**: count + `1/min(n,4)` × perception.
- **`ZoneOfControl.get_engagement_parry_multiplier`**: ZoC threshold + edge file → discrete flank/rear mods; pack `|Δfile| >= 2` fallback.
- **`AttackResolver`**: `surround_threat_count`, `zone_engagement_parry_mult`, `engagement_angle` inferred from mult vs constants.

---

## 3. Target Architecture (layers)

```
[ Coarse state: rank, file, zone_id, distance_to, weapon reach/mass ]
        ↓
[ Breach / hold contest ] → penetration_depth, breached_file/edge flags
        ↓
[ Threat load: sector-weighted surround ] → replaces plain count+split where desired
        ↓
[ ZoC raw strength ] ← global + lane + (optional) local breach stress
        ↓
[ Engagement parry mult ] ← continuous ZoC + explicit angle from zone/files
        ↓
[ DefenseChoiceResolver ] ← dodge/parry with sector-aware multipliers (optional phase)
```

---

## 4. Prerequisites (decide or document before / alongside implementation)

These items are **not** afterthoughts—they constrain **Phase A** (gate) and how **B–H** connect to the rest of the codebase. Review this section when executing the **master checklist (§9)**.

### 4.1 Interacting systems

| Topic | Requirement |
|--------|----------------|
| **Multi-target / parry choice** (deferred in `IMPLEMENTATION_OUTLINE`) | If **threat load** replaces **threat count**, decide whether **multi-target** will **reuse** the same **load** model—avoid two unrelated “threat” definitions. Prefer **one** model or **documented** layering (ties to **§4.5** and FF4 checklist §9). |
| **Medical phase** | **`penetration_depth` / breach flags** must **clear** or **freeze** when entering medical phase so **deep** does not keep flank/surround mods during triage. |
| **Formation moves** (swap / fall back / rotate) | Rules when **`penetration_depth > 0`** or **`breached_files`** active: e.g. **abort** breach on **reform**, **block** moves until cleared—lock in **Phase A**. |
| **Ranged (future)** | If rear ranks gain **ranged** later, define **deep** front-liners as archer targets or **melee-only** for surround—**one sentence** until ranged exists. |

### 4.2 Gameplay rules (Phase A gate)

| Decision | Options to pick |
|----------|-----------------|
| **Who can go deep** | Rank **0** only vs **any** rank (relief into deep?). |
| **Symmetry** | Enemy uses **same** breach rules as player (recommended). |
| **Encounter flags** | **`protection_circle_active`:** **§10.2 A3** — discourage **wide flank/surround** across open ground between circles; **allow** **frontal** breach/crash into the opponent’s circle. |
| **Close vs breach** | **§10.2 A4** — **`attempt_close`** and **`crash`** are **separate** (engage vs break through). |
| **Stamina / tempo** | **§10.2 A5** — crash: stamina + cooldown; **no** extra deep tax—**surround** carries pressure while deep. |
| **Skirmish / interposition** | **§10.2 A6** — crash/breach **allowed** for **interposing** / disrupting between enemies, not only full formations. |
| **Breach exit** | **§10.2 A8** — breach lasts until **incap** or **no longer in enemy formation**; **§10.2 A7** — clear on **combat end** for post-combat medical. |

**Deliverable for Phase A:** Short **design note** (states, transitions, double-count rules with **obs_pen**, **incursion headroom**, **geometric reach**).

### 4.3 API, naming & MOVE taxonomy

| Item | Requirement |
|------|-------------|
| **Tactical vs armor “penetration”** | Codebase uses **penetration** for **armor/sharp** (`WeaponDamageHelper`, `ArmorPiece`). Prefer **`tactical_penetration_depth`**, **`line_depth`**, or **`line_position`** in tactical API/docs—avoid confusion with **mm RHA**. |
| **`pa` / resolver keys** | Plan rename or parallel key: **`surround_threat_count`** → **`surround_load`** (or **count** = floor of load)—document for **AttackResolver** / **`DefenseChoiceResolver`**. |
| **`MOVE_ID` groups** | **`FORMATION_MOVEMENT_MOVE_IDS`** vs melee—**crash** belongs in a **separate** group (e.g. **`BREACH_MOVE_IDS`**) unless it truly shares the **formation pair** state machine. |
| **`get_combatants()`** | `CombatManager.get_combatants()` feeds **Battle UI** rows; add **`penetration_depth` / `line_position`** (and formation breach flags if surfaced) when those fields exist. |
| **Actions before AI** | **`CombatAIActionPicker`** only chooses among moves **`AvailableActionsBuilder.get_available_actions`** returns—**crash** (and any breach move) must be **implemented there** before Phase G utility tuning is meaningful. |

### 4.4 Lifecycle, persistence & consistency

| Item | Requirement |
|------|-------------|
| **Combat start/stop** | **`start()`** rebuilds formations—reset **`breached_files`**, **`lane_stress_by_file`**, and new tactical fields as needed. **`_end_combat_phase`** may not clear all dicts; **`stop()`** + next **`start()`** does—document if **mid-battle reload** ever appears. |
| **Save/load** | If combat state is **persisted**, new fields go through **serialize** or are explicitly **non-persisted** (reset on load). |
| **Afterblow / riposte** | Secondary hits use the same **`AttackResolver`** path—**surround** / **zone** keys stay **per swing** if **`pa`** is rebuilt (verify when adding fields). |

### 4.5 Surround math: count, split divisor, and load

| Item | Requirement |
|------|-------------|
| **`SURROUND_MAX_SPLIT_DIVISOR`** | Today **`surround_defense_multiplier`** uses **integer** `n` and **`mini(n, SURROUND_MAX_SPLIT_DIVISOR)`**. When Phase D introduces **float load**, define **one** rule: map load → effective **n**, **replace** split with the load curve only, or **cap**—avoid **two conflicting** surround semantics. |
| **FF4 checklist §9 (parry threat scoring)** | Still open; when **multi-target** lands, align **parry threat score** (momentum vs damage) with **surround load** per **§4.1**. |

### 4.6 Tooling, events & validation

| Item | Requirement |
|------|-------------|
| **Feature toggle** | **Name** the flag in code + doc: **legacy surround count** vs **sector threat load** (Phase D). |
| **Telemetry / debug** | At least one line or overlay: `inc_g`, `lane_z`, `breach_stress`, `surround_load` (per tick or per attack). |
| **`CombatDebug`** | **`CombatDebug.flow_log`** / **`COMBAT_DEBUG`** branches for **breach/crash** outcomes, consistent with **attack** / **formation** logs. |
| **Event queue** | New **`EVENT_*`** for crash/breach must respect **FF4 §6** ordering (agility, then **`combatant_id`**) and avoid starving **`EVENT_ACTION_READY`**. |
| **Automated tests** | No in-tree `*test*.gd` harness today—Phase H: **manual** scenarios or **add** minimal GUT/headless before claiming **regression**. |

### 4.7 Optional (post–v1)

- **Reform / rally** to clear **`breached_files`** without winning the fight.  
- **Morale**: cohesion when an ally stays **deep** too long.  
- **Plug vs breach on death** (outline deferred)—explicit **later**.

---

## 5. Phases

Each phase lists **tasks**. **§4** holds cross-cutting requirements; phases should not contradict them.

### Phase A — Design locks (short)

- [ ] Define **`penetration_depth`** enum or `0..N` (max ≈ `formation.ranks - 1` or cap at 2).
- [ ] Define **enter/exit**: **Crash** action, successful breach contest, **disengage**, **death**, **rout** (see **§4.2**).
- [ ] Define **surround “price”** while deep: min floor, sector weights, or **attention load** (units: normalized 0..1).
- [ ] Confirm **double-counting** with **obs_pen**, **incursion headroom**, **geometric reach**.

**Deliverable:** Design note (append to this doc or appendix).

---

### Phase B — Data on combatants & formations

- [ ] Add **`combatant["penetration_depth"]`** or **`line_position`** (see **§4.3** naming).
- [ ] Optional: **`formation["breached_files"]`** / **`edge_breach`** with **TTL** or until **reform**.
- [ ] Optional: **`combatant["breach_until_clock"]`** for timed disorder.
- [ ] **`CombatManager`**: defaults on **register**; respect **§4.4** lifecycle and save/load.

**Files:** `ui/CombatManager.gd`; persistence paths if any.

---

### Phase C — Breach / hold resolver (core)

- [ ] Module **`combat/BreachResolver.gd`** (or `TacticalCombat` methods): **hold** vs **drive** strength using existing reach/spacing/ZoC inputs—**no** new coordinates.
- [ ] Output: success / fail / partial; set **`penetration_depth`** and/or **`breached_files`**.
- [ ] Integration: **`CombatManager.resolve_action`** for **`MOVE_ID_CRASH`** or tagged **close**—prefer **event-driven** (see **§4.6** events).
- [ ] **`MOVE_ID`**: use **`BREACH_MOVE_IDS`** (or equivalent) per **§4.3**.

**Files:** `BreachResolver.gd`, `CombatConstants.gd`, `AvailableActionsBuilder.gd`, `CombatManager.gd`.

---

### Phase D — Surround: threat load (replace or parallel)

- [ ] **Sector-weighted load** from **`can_melee_threaten`**, **`zone_id`**, **`Δfile`**, reach at **`distance_to`**.
- [ ] **`surround_defense_multiplier`**: e.g. **`1/(1+k·load)`** + perception; reconcile with **`SURROUND_MAX_SPLIT_DIVISOR`** per **§4.5**.
- [ ] **`penetration_depth > 0`**: min load floor or rear-sector weight (**§4.2** surround price).
- [ ] **`pa`** keys and **feature toggle** per **§4.3** and **§4.6**.

**Files:** `TacticalCombat.gd`, `AttackResolver.gd`, `DefenseChoiceResolver.gd` as needed.

**Migration:** Legacy **count** behind toggle until tuning stabilizes.

---

### Phase E — Flank / engagement: continuous + explicit

- [ ] **`get_engagement_parry_multiplier`**: smooth ZoC + file + optional **`breached_files`**.
- [ ] **`AttackResolver`**: **`engagement_angle`** from explicit rules, not only **`zone_mult`** vs **FLANK/REAR** constants.

**Files:** `ZoneOfControl.gd`, `AttackResolver.gd`, `CombatConstants.gd`.

---

### Phase F — Incursion stack alignment

- [ ] Choose: tactical breach **replaces** part of **`incursion_pressure`** vs **adds** **`local_breach_stress[file]`** into **`_raw_zone_strength`**.
- [ ] Preserve **headroom** merge; third term only if non-duplicative (**§4.1** multi-target alignment).

**Files:** `TacticalCombat.gd`, `ZoneOfControl.gd`.

---

### Phase G — AI & UI

- [ ] **`AvailableActionsBuilder`**: expose **crash** before **`CombatAIActionPicker`** can weight it (**§4.3**).
- [ ] **CombatAIActionPicker**: crash when local ZoC weak + reach favorable; avoid deep when load/stamina high; **cooldown** on crash (**§6**).
- [ ] **`get_combatants()`** + rows / diagram / **`CombatLogFormatter`**: Deep, breached file, optional load (**§4.3**).

**Files:** `AvailableActionsBuilder.gd`, `CombatAIActionPicker.gd`, `CombatLogFormatter.gd`, `FormationDiagramBuilder.gd`, `CombatManager.gd`.

---

### Phase H — Validation & tuning

- [ ] Scenarios: 1 vs 3 same file; weak center; tight vs loose density; deep surround spike.
- [ ] Regression: ZoC, surround, formation moves, incursion headroom—per **§4.6** test strategy.

---

## 6. Risk register

| Risk | Mitigation |
|------|------------|
| Over-stacking debuffs | **Caps** on **inc_pen + breach + surround**; **document** each term. |
| AI always/never crashes | **Utility thresholds** + **cooldown** on crash. |
| Performance | **Breach** on **action**, not every frame; threat load **O(n²)** same order as current surround count. |

---

## 7. Suggested order of implementation

0. **Phase A** (**gate**) — satisfies **§4.2**; blocks **B**.  
1. **Phase B** + **Phase E** — data + explicit **`engagement_angle`** / smooth flank (lower risk).  
2. **Phase D** — threat load; use **toggle** (**§4.6**).  
3. **Phase C** — `BreachResolver` + **MOVE_ID** / hooks.  
4. **Phase F** — incursion alignment.  
5. **Phase G** — AI/UI (**§4.3** surfaces).  
6. **Phase H** — scenarios + validation (**§4.6**).

---

## 8. Out of scope (later)

- Full **Shardplate** / **blade** fantasy systems (separate **durability** layer).  
- **3D** positioning or **navmesh**.  
- **Cavalry charge** as separate physics integrator.

---

## 9. Master checklist

Use this as the **single** execution list; detailed rules live in **§4** and phase sections in **§5**.

- [ ] **§4** prerequisites reviewed (interacting systems, gameplay, API, lifecycle, surround math, tooling).  
- [ ] **Phase A** complete (**gate**).  
- [ ] **Phase B**: combatant/formation fields.  
- [ ] **Phase C**: `BreachResolver` + integration.  
- [ ] **Phase D**: sector-weighted surround + **§4.5** reconciliation.  
- [ ] **Phase E**: smooth ZoC flank + explicit **`engagement_angle`**.  
- [ ] **Phase F**: incursion / breach / lane coherence.  
- [ ] **Phase G**: AI + UI + **`get_combatants`**.  
- [ ] **Phase H**: scenarios + regression strategy.

---

## 10. Phase A — Design locks (gate for Phase B+)

**Status:** **Gameplay locks (§10.2) are decided** (see below). **§10.3** systems alignment still needs confirmation before Phase D/F polish; Phase B may proceed per §10.5.

### 10.1 Already constrained (do not contradict)

| Topic | Lock |
|--------|------|
| Distance / close attempt | FF4 §1: hybrid model; **attempt_close** = roll vs evasion (engagement_pressure vs defender evasion), stances apply. |
| Flank / rear vs protection circle | FF4 §5: ZoC-based flank/rear. **`protection_circle_active`:** **discourage wide flanking** (leaving the friendly circle to cross **open ground between** circles and **surround** the enemy). **Do not** treat frontal **line break** the same: units **may** push **straight forward** into the opponent’s circle and **crash through** the line. Implementation: forbid or penalize **lateral / encirclement** paths; **allow** **frontal breach** and **crash** (see **§10.2 A3**). |
| Event ordering | FF4 §6: agility, then `combatant_id`. |
| Surround split cap | FF4 §4: `SURROUND_MAX_SPLIT_DIVISOR` = **4** (tune later). |
| Spacing / effective distance | FF7–8: density-derived spacing; `|Δfile| × avg_spacing`; `REACH_SAFETY_FACTOR` = 0.8. |
| Multi-target / parry threat | FF4 §8–9 still **open** globally; incursion plan §4.1 says **one** threat model when surround load lands—**align when those checklist items are filled**. |
| Tactical vs armor “penetration” | §4.3: use **`tactical_penetration_depth`** (int 0..N) in combatant/formation API—not armor RHA “penetration”. |

### 10.2 Gameplay — **locked**

| # | Decision | **Locked resolution** |
|---|----------|------------------------|
| **A1** | Who can go deep; rank vs relief | **Front rank (rank 0)** is the **line** that holds breach; when a unit **pushes forward** into the enemy formation, **others step up and fill** rank 0 (normal relief). **Deep / breach** tracks **who is actually forward in the contest**, not a separate “any rank” deep state without this fiction. |
| **A2** | Symmetry | **Same rules** for player and enemy. |
| **A3** | `protection_circle_active` | **Do not** disable frontal breach or crash. Circles **discourage flanking by surrounding** (leaving the circle, crossing **open** space between circles to get to the enemy **flank**). They **do not** discourage **breaking through** the **front** of the enemy line **straight ahead** into the opponent’s circle. (ZoC flank/rear tuning for “inside circle” may still apply; **frontal** push is allowed.) |
| **A4** | `attempt_close` vs `crash` | **Separate features.** **Close** = get into **engagement** (distance / facing the fight). **Crash** = **break past** the opponent’s guard to **move through** / **disrupt** the line—not merely “in position to engage.” |
| **A5** | Stamina / tempo | **Crash** uses **stamina** and a **cooldown** (charge-through-the-line attempt). **No** extra “deep stamina tax” or artificial debuff: pressure while deep comes from **being surrounded** (many threats) and existing **surround** / defense math—not a separate exhaustion rule. |
| **A6** | Skirmish / loose fights | **Still available** where it makes sense: a unit can **push forward** and **interpose** between enemies to **throw them off**, not only in perfect multi-file lines. (Implementation: allow **crash / breach** when the action is **tactically meaningful**—e.g. interposition / disrupt—even if not both full formations.) |
| **A7** | When breach clears (medical / post-combat) | **Clear breach when combat ends** so the unit can **return to friendly lines** and **post-combat medical** care is unblocked. (Mid-fight **medical_phase** behavior can follow the same “clear when fight segment ends” pattern if needed—wire in **CombatManager.stop** / end-of-combat cleanup.) |
| **A8** | How long breach lasts | **Persist** until the **breaching unit** is **incapacitated** **or** **no longer in the enemy formation** (retreated, left the contested formation / forward position). **Not** “friendly formation move clears everyone” by default—**reform does not** wipe breach unless it **removes** the breacher from the enemy formation (see exit conditions). |

**Supersedes** earlier A8a/A8b (reform-wide clear): those options are **not** adopted.

### 10.3 Systems alignment — still open (confirm before Phase D / F / save hooks)

| # | Decision | Proposed default (v1) |
|---|----------|------------------------|
| B1 | **Phase F:** incursion stack | **Add** `local_breach_stress[file]` (or per-side dict) into ZoC merge **without** removing `incursion_pressure` until tuned; preserve headroom merge. |
| B2 | **§4.5 Surround:** float load vs integer `n` | **Toggle:** legacy **count** path default **on**; when `FEATURE_SECTOR_SURROUND_LOAD` (name TBD) is on, use **load →** `1/(1+k·load)` and **stop** using integer split for that path (document single rule—no double semantics). |
| B3 | **Save/load** | New tactical fields **non-persisted** until you add serialize hooks (reset on load). |

### 10.4 Double-count / stacking (deliverable summary)

- **`obs_pen`:** slot obstacles / bodies stay **only** in ZoC casualty term (`ZOC_CASUALTY_PER_BODY` path)—not folded into lane stress or global incursion.  
- **Global incursion:** front-rank delta → `incursion_pressure` (existing).  
- **Lane stress:** dual living + density per file (existing); merged with global via **headroom** (`INCURSION_LANE_HEADROOM_FACTOR`).  
- **Breach (future):** third term only as **`local_breach_stress`** or penetration-driven modifier **after** verifying it does not duplicate incursion or lane terms; **caps** on combined penalties per §6 risk register.

### 10.5 Phase A completion checklist

- [x] **§10.2** gameplay locks recorded (**A1–A8**).  
- [x] **A8a/A8b** — **N/A** (replaced by **A8 persistence** rule).  
- [ ] **§10.3** B1–B3 confirmed (before Phase D/F and persistence work).  
- [ ] §10.4 reviewed (no objection).  
→ **Phase B** (data on combatants/formations) may proceed under **§10.2**.  

---

*Last updated: §10.2 gameplay decisions locked; protection circle clarified (frontal breach vs wide flank); A8 persistence replaces reform-clear options.*
