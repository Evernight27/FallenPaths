# Combat ↔ Tuning Integration Audit Report

## Scope
Integration between `combat_tuning/` (tuning harness) and `combat/` (production combat), focusing on data flow through `action_resolved` signals, result dictionaries, and logging.

---

## A. Data Flow Gaps

### A1. Keys read by TuningLogFormatter not written by production for non-hit outcomes
**Severity:** Medium — missing data shows as defaults/empty in tuning logs.

`TuningLogFormatter.format_exchange_line` reads many keys from `result_dict` that are only populated on `hit` outcomes (in `AttackResolver.gd:288-312`). For `miss`, `dodge`, `parry_deflect`, and `parry_partial`, the `empty_result` dict in `AttackResultApplier.gd:288` contains:
```
{"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0}
```

Keys consumed by `TuningLogFormatter` but absent from non-hit outcomes:

| Key | Read at | Written only on | Missing from |
|-----|---------|----------------|--------------|
| `penetration_sharp_applied` / `penetration` | TLF:281, 689 | Hit + harness meta on | All non-hit |
| `total_physical` | TLF:287, 691 | Hit only (AR:290) | All non-hit |
| `final_cut`, `final_blunt`, `final_bone` | TLF:288-290, 692-694 | Hit only (AR:300-302) | All non-hit |
| `pre_armor` | TLF:292, 695 | Hit only (AR:311) | All non-hit |
| `mechanical_post_armor` | TLF:293, 696 | Hit only (AR:308) | All non-hit |
| `health_before`, `health_after` | TLF:300-301, 357-358 | Hit (AR:314-315) + empty_result has zeros | Non-hit shows 0 |
| `strike_ke_j_applied` / `ke` | TLF:123 | Hit + harness meta (AR:321) | All non-hit |
| `damage_resolve_note` | TLF:331, 669 | Hit only (AR:313) | All non-hit |

**Impact:** Non-hit rows in CSV/logs show defaults (0.0, empty string) rather than meaningful values. This is partially mitigated by fallback defaults but makes tuning analysis less accurate for parry/dodge/miss scenarios.

### A2. Tuning enrichment keys not available until `_enrich_payload_for_tuning` runs
**Severity:** Low — works correctly, but creates ordering dependency.

`AttackResultApplier._enrich_payload_for_tuning()` (ARA:180-232) adds keys AFTER initial result dict creation. Keys like `move_id`, `intensity`, `power`, `follow_through`, `wind_up_s`, `attack_line`, `atk_guard`, `def_guard`, `weapon_id`, `kinematic_delivery`, `gauge_atk_pre`, `gauge_def_pre` are all added by this function (ARA:192-221).

These keys are consumed by `TuningLogFormatter` via fallback chain:
```gdscript
result.get("intensity", rd.get("intensity", -1.0))  # TLF:237
```

**Impact:** The dual-level lookup (top-level result, then nested result_dict) is correct but fragile — if `_enrich_payload_for_tuning` is gated off (tuning_expose_strike_context = false), all these values fall to -1.0/empty.

### A3. Signal slot order inconsistency for parry outcomes
**Severity:** Low — documented behavior, not a bug.

For `parry_deflect` and `parry_partial`, the signal is emitted with reversed slots:
```gdscript
manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)  # ARA:512, 591
```
While hit/miss/dodge use normal order:
```gdscript
manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)   # ARA:621, 660, 690
```

`CombatTuningMain._on_action_resolved` (CTM:258-294) handles this by looking up entities from `attacker_id_sig` / `target_id_sig`, so the swap is handled. But `_enrich_strike_log_result` (CTM:230-255) only enriches with weapon ID for `attacker_id_sig`, which is correct post-swap.

---

## B. Missing Result Dict Fields

### B1. `recovery_s` not in empty_result — **FIXED**
**Severity:** Resolved.

The skip path at ARA:290-315 now calls `_enrich_payload_for_tuning()` before emitting `action_resolved`, passing `{"recovery_s": float(result.get("recovery_duration", 0.0))}` in the extras dict. This brings it in line with the miss/dodge paths.

`TuningLogFormatter` reads `recovery_s` at TLF:327 via fallback chain. All non-hit outcomes now properly enrich with `recovery_s`.

### B2. `aim_prof_tier` and `occ_mult` never written to result dict
**Severity:** Low — always falls to default (-1.0).

Read at TLF:230, 233:
```gdscript
var aim_prof: float = float(result.get("aim_prof_tier", rd.get("aim_prof_tier", -1.0))))
var occ_mult: float = float(result.get("occ_mult", rd.get("occ_mult", -1.0))))
```

These keys are never written by any production module (`AttackResolver`, `DefenseChoiceResolver`, `DefenseResolutionHandler`). They appear to be reserved for future occupancy-based targeting profiling.

---

## C. Stale / Dead Code

### C1. `TuningLogFormatter.ke_sample_from_result` — unused outside itself
**Severity:** Low.

Method at TLF:70-105 builds a KE sample dict. Called only from `CombatTuningMain._log_batch_cycle_summary` (CTM:787). The `parry_control` extraction at TLF:95-96 reads from nested `rd`, but `parry_control` is written to the top-level payload by `_enrich_payload_for_tuning` (ARA:227), not to `result_dict`. This means the `rd["parry_control"]` read at TLF:96 will always be absent.

### C2. `CombatTuningMain._on_enemies_eliminated` — empty stub
**Severity:** Trivial.

CTM:309-310 is an empty function connected to a signal but does nothing. `_in_medical_phase_start()` (CTM:315-318) handles the actual logging.

### C3. `CombatTuningMain._on_formation_changed` — empty stub
**Severity:** Trivial.

CTM:326-327 is an empty function connected to signal but unused.

---

## D. Logging Inconsistencies

### D1. Production events not surfaced in tuning log
**Severity:** Medium — tuning log misses combat events that affect state.

`CombatDebug.combat_session()` (CD:77-84) logs these events that the tuning log does NOT capture:
- Turn picks (`flow_log_turn` at CD:220-253)
- Action rejected / skip turn (`resolve_action_rejected` at CD:51-66)
- Incapacitated state entries (ARA:646-653)
- Death lines (AR:336, ARA:331 area)
- Medical phase events (`medical_session`)

The tuning log only captures `action_resolved` signal events. It does not log: turn picks, wind-up starts, state transitions, formation changes, or medical interventions.

### D2. F5 soak trace keys differ from tuning enrichment
**Severity:** Low — parallel logging systems.

`CombatF5SoakTrace.note_hit_resolve()` and `note_strike_avowed()` run in production but write to a separate trace system. The tuning formatter has its own CSV output via `_Formatter.csv_row()`. These two systems don't share data, so running the tuning harness does not contribute to F5 soak logs.

### D3. `parry_clash_context` nested dict — inconsistent access pattern
**Severity:** Low.

`TuningLogFormatter` reads parry control at TLF:96 from `rd["parry_control"]`, but production writes `parry_clash_context` as a nested dict (ARA:498-499). The `_enrich_payload_for_tuning` function flattens it to top-level `parry_control` (ARA:227), so tuning log gets the flattened value correctly. However, `ke_sample_from_result` at TLF:96 accesses `rd["parry_control"]` on the nested result_dict, where it won't exist — it's in the clash sub-dict.

---

## E. Cross-Module Coupling

### E1. Production code contains tuning-specific branches
**Severity:** Medium — hardcoded coupling from production to tuning.

`AttackResultApplier` preloads and calls tuning-specific code:
- `_tuning_follow_through_extras()` (ARA:140-146) reads `tuning_ft_parent_strike` from attacker dict
- `_clear_tuning_follow_through_marker()` (ARA:149-152) clears the marker
- `_tuning_parry_parent_strike_index()` (ARA:154-158) reads manager meta
- `_tuning_context_enabled()` (ARA:176-178) gates on `tuning_expose_strike_context`
- `_enrich_payload_for_tuning()` (ARA:180-232) — 53 lines of tuning-only enrichment

Similarly, `AttackResolver.gd:317-324` has two `if manager.get_meta(...)` branches that only fire for harness/tuning sessions.

**Recommendation:** Consider extracting these to a `TuningStrikeBridge` module so production modules don't carry tuning-specific dead-code branches.

### E2. TuningLogFormatter preloads production modules
**Severity:** Low — expected, but creates circular dependency risk.

TLF:7-10:
```gdscript
const _ConfigData := preload("res://combat_tuning/TuningConfigData.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _DesignAnchors := preload("res://combat/CombatDesignAnchors.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
```

`TuningLogFormatter` depends on `CombatLogFormatter` (production UI), `CombatDesignAnchors` (production constants), and `BleedingConstants` (core). This is functional but means any rename in these modules requires updating the tuning module.

### E3. TuningCombatManager extends production CombatManager with meta hooks
**Severity:** Low — intended pattern.

`TuningCombatManager.gd:16-18`:
```gdscript
set_meta("tuning_expose_strike_context", true)
set_meta("_harness_expose_penetration_applied", true)
set_meta("_harness_expose_damage_kinematics", true)
```

These three meta flags gate data exposure in production code. The coupling is:
- `tuning_expose_strike_context` → `_enrich_payload_for_tuning()` in ARA
- `_harness_expose_penetration_applied` → penetration keys in AR
- `_harness_expose_damage_kinematics` → KE/contact keys in AR

**Observation:** The same meta keys are used by `CombatRegressionHarness` (CRH:12089-12090), indicating shared harness infrastructure is working correctly.

---

## Parry System Audit (Round 2)

### PA1. Defender contact part not in clash context — **FIXED**
**Severity:** Medium — tuning logs cannot diagnose why shaft/haft parries produce lower bind control.

`_build_parry_clash_context` in `DefenseResolutionHandler.gd:379-438` did not record which defender weapon part (`blade`, `shaft`, `haft`) was in contact. This is needed because `PARRY_CONTACT_MODIFIERS` (blade=1.0, shaft=0.88, haft=0.92) affect `c_d_final` via `_compute_parry_c_d` but are invisible in the logged clash context.

**Fix:** Added optional `defender: Dictionary` parameter to `_build_parry_clash_context`. When weapon has parts, writes `def_contact_part` to clash context. All three call sites (full deflect, edge deflect, partial) now pass `tgt`.

### PA2. Follow-through hit loses parry remaining ratio — **FIXED**
**Severity:** Medium — tuning log for follow-through strikes shows no indication of parry reduction.

When a `parry_partial` follows through to a hit (remaining_ratio > 0.1), the `_tuning_follow_through_extras()` function in `AttackResultApplier.gd:140-146` only captured `parent_exchange_index`. The `remaining_ratio` and `geometric_leak` from the parry clash context were lost.

**Fix:** `_tuning_follow_through_extras` now reads `parry_clash_context` on attacker dict and extracts `remaining_ratio` → `ft_remaining_ratio`, `geometric_leak` → `ft_geometric_leak`. `TuningLogFormatter.format_exchange_line` displays as `parry_ft_parent=#N rem=0.XX leak=0.XXX` when parent index > 0.

### PA3. Guard update alignment vs bind control threshold — **Verified OK**
**Severity:** None (verified consistent).

Guard line update on `parry_partial` uses `PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD` (0.6) at `AttackResultApplier.gd:562`. Bind check uses a separate `parry_control >= 0.65` composite score at line 572. Guard updates more liberally than bind, which is correct: blade positioning should happen for any well-aligned partial, but riposte/flurry benefits require higher control quality.

### PA4. Stale bind state clearance on misaligned partial — **Verified OK**
**Severity:** None (verified correct).

When `align < PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD` (`AttackResultApplier.gd:584-587`), the code erases `parry_was_bind`, `parry_against_id`, and `parry_bonus_until`. This correctly clears stale bind state from a previous deflect when a new partial parry is poorly aligned.

---

## Parry System Audit (Round 3)

### H1. Stale `PARRY_BIND_RIPOSTE_GAUGE_BONUS` duplicate — **FIXED**
**Severity:** High — value drift between two definitions.

`CombatConstantsParry.gd:84` defined `const PARRY_BIND_RIPOSTE_GAUGE_BONUS = 10.0`, while the canonical value lives in `CombatConstantsStamina.gd:17` as `28.0`. Production code (`AttackResultApplier.apply_parry_bind_riposte_gauge_bonus`) uses the Stamina value (28.0) via re-export through `CombatConstants.gd:590`. The Parry version was used only in its own self-validation function but created risk of silent drift if one changed without the other.

**Fix:** Removed stale constant from `CombatConstantsParry.gd`. Updated `p4d_parry_bind_doc_sync_line()` to reference `_Stamina.PARRY_BIND_RIPOSTE_GAUGE_BONUS` via new preload of `CombatConstantsStamina`.

### H3. AI `parry_forced` missing expiration check — **FIXED**
**Severity:** High — AI may treat expired bind as active.

`CombatAIActionPicker.gd:818` checked `tgt.has("parry_against_id") and int(tgt.get("parry_against_id", -1)) >= 0` but never verified whether `parry_bonus_until` had expired. Unlike `DefenseChoiceResolver._parry_bonus_if_active()` (line 527-530), which properly gates on `tgt.get("parry_bonus_until", -1.0) > now_s`, the AI check could return true for stale bind state beyond the bonus window.

**Fix:** Added `_CombatTiming.now_seconds()` check and updated condition to `int(tgt.get("parry_against_id", -1)) >= 0 and tgt.get("parry_bonus_until", -1.0) > now_s`. Also simplified redundant `has()` + `get()` to single `get()`.

### M6. Unclamped `geometric_leak` — **FIXED**
**Severity:** Medium — floating-point alignment > 1.0 produces negative leak.

`DefenseResolutionHandler.gd:284`: `(1.0 - _effective_alignment) * CombatConstants.GEOMETRIC_LEAK_MAX` can produce a negative value if `_effective_alignment` slightly exceeds 1.0 due to floating point imprecision. This would effectively add to parry success rather than leak energy through.

**Fix:** Wrapped with `maxf(0.0, ...)` to clamp: `maxf(0.0, 1.0 - _effective_alignment) * CombatConstants.GEOMETRIC_LEAK_MAX`.

### L1. Missing `margin_ratio` in tuning log — **FIXED**
**Severity:** Low — primary diagnostic value for parry difficulty is absent from tuning output.

`TuningLogFormatter.format_exchange_line` logged `parry_control`, `follow_through_rem`, and `def_contact_part`, but not `margin_ratio` (the raw timing margin that feeds into both control score and severity). This value exists in the clash context at `DefenseResolutionHandler.gd:416` but was never enriched to the top-level payload.

**Fix:** Added `parry_margin_ratio` enrichment in `_enrich_payload_for_tuning()` (`AttackResultApplier.gd`). Tuning log now displays as `margin=N.NN` between `ctrl` and `rem` in the parry segment.

### FB1. FlurryBind exchange underflow — **FIXED**
**Severity:** Low — latent negative counter if called unexpectedly.

`CombatFlurryBind.consume_exchange_on_wind_up_start()` (CFB:101-105) decrements exchanges without guarding against going negative. While `is_active` already checks `left <= 0`, the counter itself could underflow to -1 or lower before being checked.

**Fix:** Wrapped decrement in `maxf(0, ...)` to clamp at zero.

### D1. Missing diagnostic enrichment from clash context — **FIXED**
**Severity:** Medium — useful tuning data available in nested clash context but not surfaced.

`_enrich_payload_for_tuning()` extracted only `parry_control`, `follow_through_rem`, `def_contact_part`, `kinematic_delivery`, and `margin_ratio` from the parry clash context. The full context also contains `alignment`, `parry_readiness`, and `parry_time_to_react` — all critical for diagnosing parry difficulty tuning.

**Fix:** Added enrichment for `parry_alignment`, `parry_readiness`, `parry_react_s`. Tuning log displays as `align=N.NN ready=N.NN react=N.NNN` in the parry segment.

---

## Summary of Action Items

| Priority | Category | Issue | Location | Status |
|----------|----------|-------|----------|--------|
| P1 | A | Non-hit outcomes lack damage/armor keys — tuning CSV shows zeros | TLF:281-296, ARA:288 | Open (expected) |
| ~~P2~~ | B | `recovery_s` missing from skip-path enrichment | ARA:290-315 | **Fixed** |
| P3 | C | `ke_sample_from_result` reads `rd["parry_control"]` — already correct fallback | TLF:93-96 | **No action needed** |
| P4 | E | Production tuning branches could be extracted to bridge module | ARA:140-232, AR:317-324 | Open (future) |
| P5 | D | Tuning log misses turn picks, state transitions, medical events | CD:77-253 vs CTM:258 | Open (scope decision) |
| P6 | B | `aim_prof_tier`, `occ_mult` — populated on hit only, -1.0 default on non-hit | TLF:230, 233, AR:601-606 | **No action needed** |
| PA1 | Parry | Defender contact part absent from clash context | DRH:379-438 | **Fixed** |
| PA2 | Parry | Follow-through hit loses parry remaining ratio in tuning log | ARA:140-146, TLF:265-267 | **Fixed** |
| PA3 | Parry | Guard update vs bind threshold consistency | ARA:562 vs 572 | **Verified OK** |
| PA4 | Parry | Stale bind state clearance on misaligned partial | ARA:584-587 | **Verified OK** |
| H1 | Parry | Stale PARRY_BIND_RIPOSTE_GAUGE_BONUS=10.0 duplicated from canonical 28.0 in Stamina | CCP:84, CCS:17 | **Fixed** |
| H3 | Parry | AI parry_forced missing parry_bonus_until expiration check | CAIP:818 | **Fixed** |
| M6 | Parry | geometric_leak unclamped, can go negative when alignment > 1.0 (FP) | DRH:284 | **Fixed** |
| L1 | Parry | Tuning log missing margin_ratio for parry outcomes | TLF:318-336, ARA:230-243 | **Fixed** |
| FB1 | FlurryBind | consume_exchange_on_wind_up_start no negative guard | CFB:101-105 | **Fixed** |
| D1 | Parry/Diag | Tuning enrichment misses alignment, readiness, react time from clash context | ARA:230-246, TLF:318-339 | **Fixed** |
