# Campaign decision guide

**Start:** [User bundle](#user-bundle-2026-05-22) · [`CompanyState`](../world/CompanyState.gd) · [§19](SHIP_PLAN.md#implementation-stubs) · [decision log](SHIP_PLAN.md#decision-log).

Closed-gate defaults, §12 economy, or **new gates** (const + `read_stub_*` + decision-log line). Persistence: [**P2** save](#d-persistence).

---

## Physics anchors

| Anchor | Value |
|--------|-------|
| Untreated TTD | ~48 s (CoTCCC/ATLS 30–120 s) |
| Death threshold | 30% blood remaining |
| Triage danger / peril | 55% / 47% @ 60 s / 30 s |
| Map step | 60 s |
| Direct pressure | ~2× TTD |

One untreated arterial step can reach peril — map ETA is not cosmetic.

---

<a id="user-bundle-2026-05-22"></a>

## User bundle (2026-05-22) — closed gates

Consts in `CompanyState`; `read_stub_*()` forwards ([SHIP_PLAN §19](SHIP_PLAN.md#implementation-stubs)).

| Gate | Choice | Code |
|------|--------|------|
| **D-day** | T3, N=5, End day at (0,0) | `DAY_TICK_MODE`, `STEPS_PER_DAY` |
| **D-encounter** | R3 + paid loss = run end | `ENCOUNTER_LIFECYCLE` |
| **D-camp-ui** | H3 | `CAMP_HEAL_*` |
| **D-casualty** | K3 + kill recap | `CASUALTY_ON_SETTLEMENT` |
| **D-bleed** | B + tutorial block + field care | `MAP_BLEED_POLICY` |
| **D-supply-battle** | E3 | `MED_BATTLE_MODE`, `SUPPLY_FACTOR_AT_ZERO_MED` |
| **D-affliction** | Tier RNG | `AFFLICTIONS_ENABLED` |
| **D-bankrupt** | B3 desertion | `BANKRUPT_MODE` |
| **D-persistence** | P1 EA → **P2 shipped** | `PERSISTENCE_MODE` |

<a id="camp-heal-rates-on-move-vs-camp"></a>

**Camp heal:** on-move 60 s @ 1× · camp rest 600 s @ 3× (−1 med) · require definitive hemostasis before camp.

<a id="affliction-rng-medieval-alignment"></a>

**Affliction RNG:** peril 30% · danger 12% · bone cripple 45% · max one per fight · mood −1.35 on permanent.

<a id="b3-desertion-integration-points"></a>

**B3 desertion:** `company_mood` ≤ 15 → 5%/day desertion (leader exempt). Empty roster → bankrupt modal.

---

<a id="gate-research-appendix"></a>
<a id="d-day"></a>
<a id="d-encounter"></a>
<a id="d-camp-ui"></a>
<a id="d-casualty"></a>
<a id="d-bleed"></a>
<a id="d-supply-battle"></a>
<a id="d-affliction"></a>
<a id="d-bankrupt"></a>

## Gate notes

Each D-* choice is closed in the [user bundle](#user-bundle-2026-05-22); consts in [#d-persistence](#d-persistence) / [SHIP_PLAN §19](SHIP_PLAN.md#implementation-stubs).

<a id="d-persistence"></a>

### D-persistence

| Mode | Behavior |
|------|----------|
| **P1** (legacy EA) | Session-only; `clear_slot` on campaign boot / run-end reload |
| **P2** (shipped) | Single-slot autosave; `PERSISTENCE_MODE := "P2"` in `CompanyState` / `CompanyEconomy` |

<a id="ea-tuning"></a>

### §12 economy

Gold / wage / med / tools in `CompanyState.init_from_defaults()` — retune in playtest without a new gate.

<a id="recommended-bundle"></a>

Superseded by [user bundle](#user-bundle-2026-05-22).
