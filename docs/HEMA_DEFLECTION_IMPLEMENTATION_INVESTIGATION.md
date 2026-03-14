# HEMA-Accurate Deflection Implementation Investigation

## Goal

Implement margin vs decisiveness, bind/deflect logic, and related factors so parry deflection matches **how HEMA engagements actually occur** — based on Liechtenauer, HEMA 101, and source analysis.

---

## HEMA Concepts: Bind vs Deflect

### From HEMA 101 (Liechtenauer Part 5 & Part 9: Binds and Winds)

**Parry outcome depends on contact quality:**

1. **Good parry (Vier Versetzen, proper parry):**
   - Same cut parries same cut: Oberhau parries Oberhau → both end in Plough. Unterhau parries Unterhau → both end in Ox.
   - Defender catches attacker's **weak** (mid-blade) on defender's **strong** (near hilt).
   - Result: **Hard bind** — Overbind, pressure on opponent's sword, defender in control.
   - Blade stays in the line of contact (same line).

2. **Bad parry:**
   - "Orange made a bad parry, and both fencers ended up with their blade **dead centre**" — neutral bind (both soft).
   - Or: defender couldn't establish control → blade **deflects** (shed) because they're just knocking it aside.
   - Result: **Soft bind** or **deflection** — no control, blade goes where physics pushes it.

3. **Blocking parries (Liechtenauer discourages):**
   - Point held high or out to the side. "Straight parry" — point offline, overbind but point not threatening.
   - Can form strong contact but geometry is less ideal than Vier Versetzen.

4. **Fencing from the sweeps (lateral deflect):**
   - Cut "behind" the incoming blade → deflect towards one side. Geometry-dependent lateral shed.

### Margin vs Decisiveness Mapping

| HEMA term | Condition | Result |
|-----------|-----------|--------|
| **Decisive parry** | Defender had plenty of capacity; good alignment; proper setup | **Hard bind** — blade controlled, stays in line |
| **Marginal parry** | Defender barely stopped it; late or poorly positioned | **Soft bind / deflect** — blade deflects, defender can't hold it |
| **Bad parry** | Blades meet poorly; dead centre or misaligned | **Deflection** — defender just knocks it aside |

**Implementation rule:** Higher margin + better conditions → **bind**. Lower margin + worse conditions → **deflect**.

---

## Available Data (What We Have)

### From DefenseChoiceResolver / DefenseResolutionHandler

| Variable | Meaning | HEMA interpretation |
|----------|---------|---------------------|
| `parry_p_a` | Attacker momentum | Attack strength |
| `parry_c_d` / `c_d_final` | Defender capacity (after variance) | How much defender could absorb |
| `_alignment` | cos(θ) attack vs guard | **Strong-on-weak proxy** — good alignment ≈ proper contact geometry |
| `parry_readiness` | Defender readiness (0–1) | Was defender "in guard" and prepared? |
| `parry_off_balance` | Defender off-balance | Poor positioning → bad parry |
| `late_parry` | Parry was reflexive (too late for full setup) | **Less time to position** → worse parry |
| `is_block_parry` | Block (mass/str) vs redirect | Block = head-on; redirect = from side. Block can be "blocking parry" (point offline) — LL discourages but can still bind |
| `parry_time_to_react` | Time defender had | More time = better setup |
| `m_a_parry`, `m_d_parry` | Weapon masses | Mass disparity affects control |
| `_attack_line`, `_guard_line` | Lines | Geometry (same-line → bind likely) |
| `pa["effective_attack_line"]` | Resolved line (diagonal) | Actual contact line |
| `intensity` | Attacker commitment | Stronger attack = harder to control |

### Not yet passed to deflection logic

- `parry_readiness`
- `parry_off_balance`
- `late_parry`
- `parry_time_to_react`
- `c_d_final` / `parry_p_a` (margin ratio)
- `_alignment`
- `is_block_parry`
- `attack_type` (thrust/cut/blunt)

---

## Proposed: Parry Control Score

A single **parry_control** score (0–1) that predicts bind vs deflect:

```
parry_control = base × margin_factor × alignment × readiness_factor × timing_factor × block_mod
```

### Components

1. **base** = 0.5 (neutral)

2. **margin_factor** = clamp(c_d_final / (parry_p_a * PARRY_DEFLECT_THRESHOLD), 0.5, 2.0)
   - Ratio 1.08 (marginal) → ~1.0
   - Ratio 1.5+ (decisive) → higher, caps at 2.0
   - **HEMA:** Decisive = more control → bind. Marginal = less control → deflect.

3. **alignment** = _alignment (already 0.15–1.0)
   - **HEMA:** Good alignment ≈ strong-on-weak contact. Misaligned = poor contact = deflect.

4. **readiness_factor** = parry_readiness × (0.7 if parry_off_balance else 1.0)
   - **HEMA:** Off-balance = bad positioning = deflect.

5. **timing_factor** = 1.0 if not late_parry else 0.6
   - **HEMA:** Late parry = reflexive, no setup = worse contact.

6. **block_mod** = 1.0 (or 0.9 if is_block_parry for "blocking parry" penalty — optional)
   - **HEMA:** Block parry can still bind; Vier Versetzen is preferred. Slight penalty or neutral.

**Final:**
```
parry_control = clamp(
  margin_factor * alignment * readiness_factor * timing_factor,
  0.0, 1.0
)
```

**Thresholds:**
- `parry_control >= BIND_THRESHOLD` (e.g. 0.65): **Bind** — blade stays in line
- `parry_control < BIND_THRESHOLD`: **Deflect** — use geometry + severity for magnitude (adjacent vs opposite)

---

## Geometry Cap (From Prior Investigation)

**Rule:** Geometry defines *maximum* deflection. Severity/control defines *whether* we achieve it.

- **Same line** (attack == defender guard): Always bind when control high. When control low, still bind (geometry forces contact in same line).
- **Adjacent defender:** Max deflection = 45° (other adjacent). Never opposite.
- **Opposite defender:** Max deflection = 90°. Control/severity decides bind vs adjacent vs opposite.

### Integrated Logic

```
if attack_line == defender_guard_line:
  # Same-line. HEMA: Oberhau vs Oberhau → Plough. Typically bind.
  return attack_line  # bind

# Different line. Control decides magnitude.
if parry_control >= BIND_THRESHOLD:
  # High control: defender "holds" the contact. Blade stays near attack line.
  # For adjacent defender, "hold" could mean slight deflect to adjacent (controlled shed).
  # For opposite, "hold" = bind in attack line (defender met it but didn't drive through).
  return attack_line  # bind (defender controlled the contact)
else:
  # Low control: deflect. Geometry limits direction; severity limits magnitude.
  if defender_guard in adjacents:
    return other_adjacent  # 45° max
  else:
    # Opposite. Severity determines: adjacent (partial) or opposite (full).
    if severity >= OPPOSITE_THRESHOLD:
      return opposite
    else:
      return adjacent  # partial deflect
```

**Refinement:** For "low control" with same line, HEMA 101 says bad parry → blades dead centre = soft bind. So blade still ends in same line, but it's a *soft* bind (both fencers can act). We don't distinguish soft vs hard bind in guard_line — both = same line. So same-line can always return attack_line.

---

## Attack Type Modulation

From PassiveParryContext / existing constants:
- **Thrust:** Easier to redirect (`PARRY_REDIRECT_THRUST_BONUS`). Point diverts with lateral force. May deflect further for same control.
- **Blunt:** Harder to redirect (`PARRY_REDIRECT_BLUNT_PENALTY`). Momentum-based. May need higher severity for 90°.

**Suggested:** When computing deflection magnitude (adjacent vs opposite for opposite-defender case):
- Thrust: lower `OPPOSITE_THRESHOLD` (e.g. 0.5) — thrust deflects more easily
- Blunt: higher `OPPOSITE_THRESHOLD` (e.g. 0.8) — blunt needs more to get 90°
- Cut: default (e.g. 0.65)

---

## Mass and Strength (Optional Layer)

HEMA/Fiore: Light weapon deflects by angle; heavy weapon absorbs.

- `m_a > m_d`: Attacker heavier. Defender may not drive 90° deflection. Cap opposite deflect when mass ratio favors attacker.
- `m_d >= m_a`: Normal.

```
mass_deflect_cap = clamp(m_d / m_a, 0.5, 1.5)
# If mass_deflect_cap < 0.8, may restrict opposite deflect
```

Can be deferred; parry_p_a and parry_c_d already encode mass through velocity and capacity.

---

## Data Flow Changes

### 1. DefenseResolutionHandler (`_resolve_parry`, parry_deflect branch)

Compute and include in return dict:

```gdscript
var margin_ratio := c_d_final / maxf(parry_p_a * CombatConstants.PARRY_DEFLECT_THRESHOLD, 0.01)
var late_parry := dc.get("late_parry", false)
var parry_readiness := parry_readiness
var parry_off_balance := dc.get("parry_off_balance", false)

# Parry control for bind vs deflect
var margin_factor := clampf(margin_ratio, 0.5, 2.0)
var readiness_factor := parry_readiness * (0.7 if parry_off_balance else 1.0)
var timing_factor := 0.6 if late_parry else 1.0
var parry_control := clampf(margin_factor * _alignment * readiness_factor * timing_factor, 0.0, 1.0)

return {
  "action": "parry_deflect",
  "target_id": target_id,
  "recovery_duration": rec_dur,
  "parry_clash_context": {
    "parry_control": parry_control,
    "margin_ratio": margin_ratio,
    "alignment": _alignment,
    "defender_guard_line": _guard_line,
    "late_parry": late_parry,
    "parry_off_balance": parry_off_balance,
    "is_block_parry": is_block_parry,
    "attack_type": attack_type,
    "effective_attack_line": pa.get("effective_attack_line", _attack_line)
  }
}
```

### 2. AttackResultApplier (parry_deflect)

Store `parry_clash_context` on attacker (in addition to `defender_guard_line_at_parry` for backwards compat). Or merge: store full context, use for both.

### 3. GuardLineUpdater.set_guard_deflected

New signature: `set_guard_deflected(c, move_id, effective_line_override, defender_guard_line, clash_context = {})`

Logic:
1. Use `defender_guard_line` and `effective_attack_line` (from clash_context or override) for geometry.
2. Use `parry_control` from clash_context. If absent, fall back to geometry-only (current behavior).
3. Apply thresholds: BIND_THRESHOLD, OPPOSITE_THRESHOLD (by attack_type).
4. Geometry cap: adjacent defender never → opposite.

### 4. CombatStateHandlers.process_recovering

Pass `c.get("parry_clash_context", {})` to `set_guard_deflected`. Erase after use.

---

## Constants to Add (CombatConstants.gd)

```gdscript
# HEMA bind vs deflect: parry_control above this → bind (blade stays).
const PARRY_BIND_CONTROL_THRESHOLD := 0.65
# For opposite-defender geometry: severity above this → 90° deflect. Below → 45°.
const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := 0.65
const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := 0.5   # Thrust deflects easier
const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := 0.8    # Blunt needs more
# Late parry: control penalty (less time to set up proper parry).
const PARRY_LATE_CONTROL_FACTOR := 0.6
# Off-balance: control penalty.
const PARRY_OFF_BALANCE_CONTROL_FACTOR := 0.7
```

---

## Summary: HEMA-Accurate Flow

| Factor | HEMA meaning | Implementation |
|--------|--------------|----------------|
| Margin (c_d / p_a) | Decisive vs marginal parry | margin_factor; high → bind |
| Alignment | Strong-on-weak contact | alignment; good → bind |
| Readiness | Defender in guard | readiness_factor |
| Off-balance | Poor positioning | 0.7× penalty |
| Late parry | No setup time | 0.6× penalty |
| Same-line | Oberhau vs Oberhau → Plough | Always bind |
| Adjacent defender | Lateral shed | Max 45°; never opposite |
| Opposite defender | Head-on block | Severity → 45° or 90° |
| Attack type | Thrust/Blunt differ | Thresholds by type |
| Block vs redirect | Block = point held | Optional slight penalty |

---

## References

- HEMA 101: Liechtenauer Part 5 (Parries), Part 9 (Binds and Winds)
- HEMA 101: "Orange made a bad parry, and both fencers ended up with their blade dead centre"
- HEMA 101: Oberhau parries Oberhau, end in Plough; strong-on-weak; Overbind = hard bind = control
- Sword STEM: Vector transformations (magnitude vs direction)
- Project: HEMA_VS_KCD_SOURCE_ANALYSIS.md, DEFLECTION_PHYSICS_SEVERITY_INVESTIGATION.md
