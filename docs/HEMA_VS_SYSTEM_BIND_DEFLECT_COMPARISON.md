# HEMA vs System: Bind vs Deflect Comparative Analysis

## Purpose

Compare **HEMA blade clash mechanics and outcomes** (Liechtenauer, HEMA 101, Sword STEM) to **this system's implementation**, identifying alignments and gaps in how bind vs deflection work.

---

## 1. HEMA Blade Clash Mechanics

### 1.1 Contact Quality (HEMA 101: Binds and Winds)

| Aspect | HEMA Concept | Outcome |
|--------|--------------|---------|
| **Good parry** | Defender catches attacker's weak on defender's strong; Overbind; Vier Versetzen (same cut parries same cut) | **Hard bind** — blade stays in line, defender controls |
| **Bad parry** | Blades meet "dead centre" or poorly; defender couldn't establish strong-on-weak | **Soft bind** or **deflection** — blade sheds, no control |
| **Decisive parry** | Defender had plenty of capacity; proper setup; good geometry | **Bind** — blade held in line |
| **Marginal parry** | Defender barely stopped it; late or poorly positioned | **Deflect** — blade knocked aside |
| **Blocking parry** | Point held high/side (Liechtenauer discourages); can still form strong contact | Can bind but geometry less ideal |

### 1.2 Geometry (HEMA 101: Parries, Vier Versetzen)

| Geometry | HEMA Outcome | Blade Position |
|----------|--------------|----------------|
| **Same line** (Oberhau vs Oberhau) | Both end in Plough | **Bind** — blades in same line |
| **Same line** (Unterhau vs Unterhau) | Both end in Ox | **Bind** — blades in same line |
| **Adjacent** (e.g. high attack, left parry) | Lateral shed — cut "behind" incoming blade | **Deflect** — blade goes to other adjacent (~45°) |
| **Opposite** (e.g. high attack, low block) | Strong block can drive blade through | **Deflect** — blade to opposite (~90°) or partial |
| **Thrust** | Almost always deflected (point directed offline) | **Deflect** — rarely full stop/bind |

### 1.3 Factors Affecting Bind vs Deflect (HEMA)

| Factor | Effect on bind vs deflect |
|--------|---------------------------|
| **Strong-on-weak contact** | Good = bind; poor = deflect |
| **Margin (defender capacity vs attack)** | High margin = control = bind; low = deflect |
| **Alignment** | Good alignment ≈ proper contact = bind |
| **Setup time** | More time = better parry = bind; late = deflect |
| **Off-balance** | Poor positioning = worse contact = deflect |
| **Attack type** | Thrust deflects more; cut can bind |
| **Mass** | Heavy vs light affects who controls (Fiore) |

---

## 2. System Mechanics (Current Implementation)

### 2.1 Parry Outcomes

| Outcome | Condition | Where |
|---------|-----------|-------|
| **parry_deflect** | `is_block_parry` AND `c_d_final >= parry_p_a * 1.08` | DefenseResolutionHandler |
| **parry_partial** | Parry chosen but not full stop | DefenseResolutionHandler |
| **parry_deflect** → attacker blade position | Recovery completes; `set_guard_deflected` called | CombatStateHandlers → GuardLineUpdater |

### 2.2 Blade Position After parry_deflect (GuardLineUpdater)

| Condition | System outcome |
|-----------|----------------|
| `attack_line == defender_guard_line` | **Bind** — blade stays in attack line |
| Defender adjacent (45°) | **Lateral** — deflect to other adjacent (45°) |
| Defender opposite (90°) | **Strong block** — deflect to opposite (90°) |
| No `defender_guard_line` | Fallback: opposite line |

### 2.3 Data Used for Deflection Decision

| Data | Used? | Where |
|------|-------|-------|
| `defender_guard_line` | ✓ Yes | Stored at parry, passed to `set_guard_deflected` |
| `effective_attack_line` | ✓ Yes | From diagonal roll |
| `parry_p_a`, `parry_c_d` | ✗ No | Computed but not passed |
| `alignment` | ✗ No | Used for parry capacity, not deflection |
| `parry_readiness` | ✗ No | Not passed |
| `parry_off_balance` | ✗ No | Not passed |
| `late_parry` | ✗ No | Not passed |
| `attack_type` | ✗ No | Not passed |
| `is_block_parry` | ✗ No | Only determines full_stop path, not deflection outcome |

---

## 3. Comparative Tables

### 3.1 Bind vs Deflect Decision

| Criterion | HEMA | System | Match? |
|-----------|------|--------|--------|
| **Same line → bind** | Oberhau vs Oberhau → Plough (bind) | Same line → bind | ✓ Yes |
| **Geometry determines direction** | Adjacent shed → lateral; opposite block → through | Adjacent → 45°; opposite → 90° | ✓ Yes |
| **Contact quality affects bind/deflect** | Good parry → bind; bad → deflect | **Not modeled** — geometry only | ✗ No |
| **Margin (decisive vs marginal)** | High margin → bind; low → deflect | **Not modeled** | ✗ No |
| **Alignment affects outcome** | Good alignment ≈ strong-on-weak → bind | Affects parry capacity only; not deflection | ⚠ Partial |
| **Late parry** | Less setup → worse contact → deflect | **Not passed** to deflection | ✗ No |
| **Off-balance** | Poor positioning → deflect | **Not passed** to deflection | ✗ No |
| **Thrust vs cut** | Thrust deflects more; cut can bind | **Not distinguished** in deflection | ✗ No |

### 3.2 Deflection Magnitude (45° vs 90°)

| Criterion | HEMA | System | Match? |
|-----------|------|--------|--------|
| **Adjacent geometry max 45°** | Lateral shed can't drive blade 90° | Adjacent defender → never opposite | ✓ Yes |
| **Severity affects magnitude** | Strong clash → more displacement | **Not modeled** — always full geometry outcome | ✗ No |
| **Thrust deflects easier** | Point diverts with lateral force | **Not modeled** in deflection | ✗ No |
| **Blunt deflects harder** | Momentum-based | **Not modeled** in deflection | ✗ No |

### 3.3 Parry Resolution Path

| Aspect | HEMA | System | Match? |
|--------|------|--------|--------|
| **Full stop requires block** | Block (head-on) can fully stop; redirect sheds | `parry_deflect` only when `is_block_parry` | ✓ Yes |
| **Redirect = partial** | Redirect parry typically sheds (deflect) or partial | `parry_partial` when not block or c_d insufficient | ✓ Yes |
| **Same cut parries same cut** | Oberhau parries Oberhau | Same line (alignment 1) → bind | ✓ Yes |
| **Strong-on-weak** | Defender strong on attacker weak | Alignment (cos θ) as proxy; affects parry_c_d | ⚠ Partial |

### 3.4 Defender Blade Position

| Aspect | HEMA | System | Match? |
|--------|------|--------|--------|
| **Defender ends where contact was** | Blade meets attack in line of contact | `set_guard_from_move(tgt, move_id, eff_line)` | ✓ Yes |
| **Defender in attack line after parry** | Both blades in contact line | tgt ends in `eff_line` (attack line) | ✓ Yes |

---

## 4. Gap Summary

### Aligned with HEMA ✓

1. **Same-line → bind** — Oberhau vs Oberhau, blade stays in line.
2. **Geometry-based direction** — Adjacent → lateral (45°); opposite → strong block (90°).
3. **Geometry cap** — Adjacent defender never produces 90° deflection.
4. **Block vs redirect** — Only block parries can full-stop (parry_deflect).
5. **Defender blade** — Ends in attack line where contact occurred.
6. **4-line model** — Maps to Liechtenauer high/low/left/right.

### Not Aligned / Gaps ✗

1. **Contact quality** — System does not distinguish good vs bad parry for bind/deflect.
2. **Margin vs decisiveness** — A marginal full-stop (c_d ≈ 1.08 × p_a) is treated identically to a decisive one (c_d >> p_a).
3. **Late parry** — Reflexive parries are not more likely to deflect.
4. **Off-balance** — Defender off-balance does not increase deflection likelihood.
5. **Parry readiness** — Defender readiness does not affect blade outcome.
6. **Severity/magnitude** — Deflection is always full (45° or 90°); no partial deflection by clash strength.
7. **Attack type** — Thrust vs blunt vs cut do not modulate deflection in guard update.
8. **Soft vs hard bind** — Both result in same line; system does not model control quality for follow-up (e.g. riposte priority).

### Partially Aligned ⚠

1. **Alignment** — Used for parry capacity (parry_c_d × alignment) but not for bind/deflect outcome.
2. **Strong-on-weak** — Alignment as proxy; no explicit blade contact-point model.

---

## 5. Outcome Comparison by Scenario

### Scenario A: Oberhau vs Oberhau (same line), decisive parry

| | HEMA | System |
|---|------|--------|
| **Outcome** | Hard bind; blades in Plough | Bind; blade stays in high |
| **Match** | ✓ |

### Scenario B: Oberhau vs Oberhau (same line), marginal parry

| | HEMA | System |
|---|------|--------|
| **Outcome** | Soft bind or deflect (blade may shed) | Bind; blade stays in high |
| **Match** | ✗ — System always binds for same-line regardless of margin |

### Scenario C: High attack, left parry (adjacent), decisive

| | HEMA | System |
|---|------|--------|
| **Outcome** | Lateral shed to right (or controlled deflection) | Deflect to right (45°) |
| **Match** | ✓ |

### Scenario D: High attack, left parry (adjacent), marginal

| | HEMA | System |
|---|------|--------|
| **Outcome** | Might deflect more (uncontrolled) or less (weak contact) | Deflect to right (45°) |
| **Match** | ⚠ — System always full 45°; HEMA allows variation |

### Scenario E: High attack, low block (opposite), decisive

| | HEMA | System |
|---|------|--------|
| **Outcome** | Strong block; blade driven to low (90°) | Deflect to low (90°) |
| **Match** | ✓ |

### Scenario F: High attack, low block (opposite), marginal

| | HEMA | System |
|---|------|--------|
| **Outcome** | Might only partially deflect (45° to side) or full 90° | Deflect to low (90°) |
| **Match** | ✗ — System always full 90° for opposite; no partial |

### Scenario G: Thrust parried

| | HEMA | System |
|---|------|--------|
| **Outcome** | Usually deflected (point offline); rarely full stop | parry_deflect only if block; geometry applies |
| **Match** | ⚠ — Thrust gets same deflection logic as cut |

### Scenario H: Late parry, same line

| | HEMA | System |
|---|------|--------|
| **Outcome** | Reflexive; poorer contact; more likely deflect | Bind (same as timely parry) |
| **Match** | ✗ — Late parry not distinguished |

---

## 6. Recommendations for Better HEMA Alignment

### Priority 1: Margin/Control for Bind vs Deflect

- Pass `parry_control` (or components) from parry resolution to `set_guard_deflected`.
- When `parry_control` high: bind (blade stays in line) even for different-line geometry.
- When low: use geometry for deflect (current behavior).
- **Closes gap:** Scenarios B, H.

### Priority 2: Severity for Deflection Magnitude

- For opposite-defender case: use clash severity to choose adjacent (45°) vs opposite (90°).
- Light clash → adjacent; heavy → opposite.
- **Closes gap:** Scenario F.

### Priority 3: Late Parry, Off-Balance, Readiness

- Include in `parry_control` or as separate modifiers.
- Late parry / off-balance / low readiness → lower control → more deflect.
- **Closes gap:** Scenario H; improves B, D.

### Priority 4: Attack Type Modulation

- Thrust: easier to deflect (lower threshold for 90° when opposite).
- Blunt: harder (higher threshold).
- **Closes gap:** Scenario G.

---

## 7. Summary Table

| Mechanic | HEMA | System | Gap |
|----------|------|--------|-----|
| Same-line bind | ✓ | ✓ | None |
| Geometry direction (adjacent/opposite) | ✓ | ✓ | None |
| Geometry cap (adjacent ≠ opposite) | ✓ | ✓ | None |
| Contact quality → bind/deflect | ✓ | ✗ | **High** |
| Margin → bind/deflect | ✓ | ✗ | **High** |
| Late/off-balance/readiness | ✓ | ✗ | Medium |
| Severity → magnitude | ✓ | ✗ | Medium |
| Attack type (thrust/blunt) | ✓ | ✗ | Low |
| Defender position | ✓ | ✓ | None |

---

## References

- HEMA 101: Liechtenauer Part 5 (Parries), Part 9 (Binds and Winds)
- Sword STEM: Vector transformations
- Project: PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md, HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md, HEMA_VS_KCD_SOURCE_ANALYSIS.md
