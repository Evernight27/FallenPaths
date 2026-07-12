# Composure Rework Plan

Continuous composure gauge (0-100) replaces the binary ready/not-ready system. Actions cost composure; quality scales with remaining composure. Breath (was stamina) stays as exertion/endurance tracking with exhaustion accumulation.

**Files:** [`AGENTS.md`](../AGENTS.md) · [`PLANNING.md`](PLANNING.md) · [`LIVE_PATHS.md`](LIVE_PATHS.md#composure-rework)

---

## Step 1 — Primitives & Infrastructure (safe)

| File | Change |
|------|--------|
| `combat/CombatantEntityAccess.gd` | Add `is_combatant_threatened(manager, id)` — scans WIND_UP combatants for `pending_attack.target_id == id` |
| `weapon/Weapon.gd` | Add `var is_two_handed: bool = false` after mass field |
| `weapon/WeaponConstants.gd` | Add `weapon_is_two_handed(weapon)` static |
| `combat/CombatConstantsParry.gd` | Add `OFF_BALANCE_DURATION_S := 0.4` |
| `combat/CombatConstantsFootwork.gd` | Invert dodge mults: `1.09→0.25, 1.06→0.40, 1.10→0.40, 1.07→0.60, 0.88→0.30, 0.86→0.45` |

No behavioral change to combat. These are new tools used by later steps.

---

## Step 2 — Remove gauge zeroes & gates (production-only)

| File | Line | Change |
|------|------|--------|
| `CombatStateHandlers.gd` | 233 | Delete `c.gauge = 0.0` (process_wind_up — gauge persists through wind-up) |
| `CombatStateHandlers.gd` | 254 | Delete `c.gauge = 0.0` (process_recovering — gauge persists through recovery) |
| `CombatStateHandlers.gd` | 106 | Delete `c.gauge = 0.0` (complete_recovery — gauge persists into WAITING) |
| `CombatStateHandlers.gd` | 242 | Delete `c.gauge = 0.0` (process_medical_wind_up — no fill either) |
| `CombatStateHandlers.gd` | 76 | `= 0.0` → `= 15.0` (COWERING→WAITING — partial composure) |
| `CombatStateHandlers.gd` | 192 | `= 100.0` → `= 50.0` (process_receiving_medical — partial) |
| `AttackResultApplier.gd` | 275 | Delete `atk.gauge = 0.0` (skip branch) |
| `AttackResultApplier.gd` | 289 | Delete `atk.gauge = 0.0` (defeated branch) |
| `CombatEngagementResolver.gd` | 20 | `= 0.0` → `= maxf(0, gauge - 35)` (close attempt cost deduction) |
| `MedicalActionStarter.gd` | 138 | Delete `c.gauge = 0.0` (direct pressure — medical cost=0) |
| `MedicalActionStarter.gd` | 174 | Delete `c.gauge = 0.0` (wind-up start — cost=0) |
| `MedicalWindUpHandler.gd` | 80 | `= 100.0` → `= minf(100, gauge + 30)` (patient boost from care) |
| `CombatEventDispatch.gd` | 120 | Delete `c.gauge = 0.0` (medical block abort — external interruption keeps gauge) |
| `CombatEventDispatch.gd` | 101 | Delete `c.gauge = 100.0` (action_ready — composure fills gradually) |
| `AvailableActionsBuilder.gd` | 31-35 | Remove gauge gate entirely; set `counter_tempo = can_act()` directly |
| `CombatResolveAction.gd` | 46 | Remove gauge gate check |
| `CombatAIActionPicker.gd` | 151-152 | Remove sanity check (continuous gauge never hits "full") |
| `CombatManager.gd` | ~223 | Add `"breath": STAMINA_MAX` alongside existing `"stamina"` key |

**Also keep (no change):**
- `CombatManager:601` skip_turn gauge=0 (non-wait skips reset)
- `CounterTempo:226` abort gauge=0 (total vulnerability)
- `AfterblowHandler:52` wind-up abort gauge=0
- `StateHandlers:98` enter_short_recovery gauge=0 (arm loss = disoriented)
- `CombatFormationFlee:86` / `Yield:46` gauge=0 (out of fight)
- `MedicalPhaseController:216,230` gauge=0 on phase entry (different context)
- `MedicalPhaseController:493,497` gauge=100 on phase exit (campaign handoff)

---

## Step 3 — Composure fill & cost model

### 3A — Composure fill rates

`CombatStateHandlers.gd:process_waiting` (~line 223):
```gdscript
c.gauge = minf(100.0, c.get("gauge", 0.0) + COMPOSURE_FILL_WAITING * delta)
```

`CombatStateHandlers.gd:process_recovering` (~line 254, after removing gauge=0):
```gdscript
c.gauge = minf(100.0, c.get("gauge", 0.0) + COMPOSURE_FILL_RECOVERING * delta)
```

### 3B — Composure constants (`CombatConstants.gd`)
```gdscript
const COMPOSURE_FILL_WAITING := 25.0
const COMPOSURE_FILL_RECOVERING := 8.0
const COMPOSURE_FILL_MEDICAL_WIND_UP := 0.0
const GAUGE_MAX := 100.0
const GAUGE_FULL_THRESHOLD := 100.0  # was 0.95
```

<a id="3c--cost-deduction-at-wind-up-start"></a>

### 3C — Cost deduction at wind-up start (`AttackWindUpStarter.gd:186`)

Replace `atk_d.gauge = 0.0`:
```gdscript
var composure_cost: float = _resolve_composure_cost(move_id)
atk_d.gauge = maxf(0.0, gauge_atk_pre - composure_cost)
```

Cost table:
| Action | Cost |
|--------|------|
| Wait / Focus | 0 |
| Feint | 5 |
| Quick | 20 |
| Medium | 45 |
| Heavy | 70 |
| Retreat | 10 |
| Attempt Close | 35 |
| Formation Move | 15 |
| Medical | 0 |
| Counter-Tempo | 30 |

### 3D — Wait action (separate from skip_turn)

`CombatResolveAction.gd:90-92` — replace `skip_turn`:
```gdscript
if move_id == MOVE_ID_WAIT:
    manager.emit_signal("action_resolved", attacker_id, target_id, {"outcome": "wait", ...})
    manager.emit_signal("turn_resolved", attacker_id)
    EventScheduler.schedule_action_ready(manager, attacker_id, 0.1)
    return true
```
No gauge change — composure persists, fills at 25/s during WAITING.

### 3E — Focus already-set (separate from skip_turn)

`CombatResolveAction.gd:128` — same pattern as wait.

### 3F — CounterTempo cost update
| `CounterTempo.gd:112` | spend 50 → 30 |
|---|---|
| `CounterTempo.gd:209-210` | threshold stays 50 |
| `CounterTempo.gd:226` | abort gauge=0 — keep |

---

## Step 4 — Action quality & parry rework

### 4A — Wind-up quality scaling (`CombatTiming.gd`)
```gdscript
var quality_mult: float = 1.5 - 0.5 * (gauge_atk_pre / 100.0)
# Low composure = longer wind-up = more predictable timing
wind_up_duration *= quality_mult
```

### 4B — Parry_p_a composure scaling (`DefenseChoiceResolver.gd:161`)
```gdscript
parry_p_a *= (0.6 + 0.4 * gauge_atk_pre / 100.0)
```

### 4C — Parry_c_d composure scaling
```gdscript
parry_c_d *= (0.5 + 0.5 * gauge_def_current / 100.0)
```

### 4D — Parry lockout
`DefenseChoiceResolver.gd` — gate before parry selection:
```gdscript
if c.get("off_balance_until", -1.0) > CombatTiming.now_seconds():
    # Cannot parry — locked out
```

`AttackResultApplier.gd` ~line 414 — after parry_deflect:
```gdscript
c.off_balance_until = manager.combat_clock + OFF_BALANCE_DURATION_S
```

---

## Step 5 — Breath rename (stamina → breath)

Largest diff (~34 files). Both keys set on combatant dict — old code reading "stamina" continues to work.

### 5A — Constant renames (`CombatConstantsStamina.gd`)
```
STAMINA_MAX → BREATH_MAX (100.0)
STAMINA_REFILL_RATE → BREATH_REFILL_RATE (5.0)
STAMINA_ATTACK_COST_BASE → BREATH_ATTACK_COST_BASE (12.0)
STAMINA_ATTACK_COST_SCALE → BREATH_ATTACK_COST_SCALE (8.0)
STAMINA_PARRY_COST_BASE → BREATH_PARRY_COST_BASE (12.0)
STAMINA_PARRY_COST_SCALE → BREATH_PARRY_COST_SCALE (8.0)
STAMINA_FACTOR_POWER → BREATH_FACTOR_POWER (0.50 — was 0.65)
STAMINA_EXHAUSTION_MAX_MULT_FLOOR → BREATH_EXHAUSTION_MAX_MULT_FLOOR
STAMINA_BLOOD_MAX_MULT_FLOOR → BREATH_BLOOD_MAX_MULT_FLOOR
STAMINA_REFILL_EXHAUSTION_MULT_FLOOR → BREATH_REFILL_EXHAUSTION_MULT_FLOOR
STAMINA_AT_ZERO_PARRY_MULT → BREATH_AT_ZERO_PARRY_MULT
STAMINA_AT_ZERO_DAMAGE_MULT → BREATH_AT_ZERO_DAMAGE_MULT
EXHAUSTION_EXERTION_PER_STAMINA_POINT → EXHAUSTION_EXERTION_PER_BREATH_POINT (0.004)
```

### 5B — Function renames
```
stamina_factor() → breath_factor()
stamina_attack_cost_from_intensity() → breath_attack_cost_from_intensity()
action_ready_stamina_delay_mult() → action_ready_breath_delay_mult()
defender_passive_readiness_stamina_mult_from_ratio() → defender_passive_readiness_breath_mult_from_ratio()
```

### 5C — UI labels
| File | Old | New |
|---|---|---|
| `BattleUIUpdater.gd` | `"Stm"` | `"Brth"` |
| `BattleUIUpdater.gd` | `"Ready"` | `"Cmp"` |
| `CombatUiHints.gd` | stamina tooltip lines | breath + composure tooltip lines |
| `CombatExhaustion.gd` | gauge_suffix_text | breath suffix (unchanged Exh) |

### 5D — Campaign afflictions
`world/CampaignAfflictions.gd` — rename `stamina_mult` → `breath_mult` in constants, add `breath_mult` key alongside `stamina_mult`.

---

## Step 6 — AI composure modulation

### 6A — Weight modulation (`CombatAIActionPicker.gd`)
```gdscript
var gauge_ratio: float = gauge / 100.0
if move_cost > gauge:
    weight_mult *= lerpf(0.3, 1.0, gauge / maxf(0.01, move_cost))
```
Low composure: prefer wait, feint, quick, retreat. High composure: prefer medium/heavy.

### 6B — Feint boost at low composure (`CombatAttackWeighting.gd`)
Low composure → boost feint weight (1.06→1.12 default).

---

## Step 7 — Harness & test updates

### 7A — Harness gauge=100 → composure values
~28 setups across `CombatRegressionHarness.gd` (25), `CombatD001SoakRunner.gd` (5):

| Purpose | New gauge value |
|---------|-----------------|
| Wait / no action | 100 |
| Quick strike | 80 |
| Medium strike | 55 |
| Heavy strike | 30 |
| Feint | 95 |
| Counter-tempo | 70 |
| Retreat | 90 |
| Close attempt | 65 |
| Formation move | 85 |
| Medical | 100 |

### 7B — Soak label checks
`CombatD001SoakSanity.gd` — "Stm XX%" → "Brth XX%", "Ready" → "Cmp XX%".

### 7C — QTrack audits
`CombatQTrackAudits.gd` — gauge suffix order, `turn_ready_gauge` patterns for breath + composure format.

---

## Step 8 — Campaign integration

### 8A — Campaign breath mult
`CombatExhaustion.gd:64` — read `campaign_breath_mult` with fallback to `campaign_stamina_mult`.
`CoreEntity.gd` — add `get_campaign_breath_mult()` as alias.

### 8B — Party member display
`PartyMemberSnapshot.gd` — show breath + composure in party list.

---

## Production gauge=0 sites (KEEP — no change)

| Site | Reason |
|------|--------|
| `CombatManager:601` skip_turn | Non-wait skips reset composure |
| `StateHandlers:98` enter_short_recovery | Arm loss = disoriented |
| `CounterTempo:226` abort | Total vulnerability after failed counter |
| `AfterblowHandler:52` wind-up abort | Action was aborted mid-wind-up |
| `CombatEventDispatch:120` → gap D | CHANGED — removed above |
| `CombatFormationFlee:86` | Out of fight |
| `CombatFormationYield:46` | Out of fight |
| `MedicalPhaseController:216,230` phase entry | Medical phase uses gauge for triage, not combat |
| `MedicalPhaseController:493,497` phase exit | Campaign handoff — readiness reset |
| `MedicalPhaseController:1072` unstick | Safety valve for medical triage |
