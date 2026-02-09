# Per-Wound Healing System

Individual, medically accurate healing and pain resolution per wound, by body part and wound type.

---

## Overview

- **Game time:** `_game_time_seconds` advances in `process_healing(seconds)`. Each wound stores `created_at_game_time` and `healing_duration_seconds`.
- **Pain:** `get_total_pain()` sums per wound: `damage × severity_pain_mult × (1 - healing_progress)`. Progress is exponential: after `healing_duration_seconds`, progress ≈ 0.95 and pain from that wound is effectively zero.
- **Resolution:** When a wound’s progress ≥ `WOUND_RESOLVED_THRESHOLD` (0.95), it is removed in `process_healing` (no more pain, no list bloat).

---

## Per-Wound Healing Duration (medically accurate)

**HealingConstants.get_wound_healing_duration_seconds(part, severity, injury_type)**

| Wound type | Duration source | Notes |
|------------|-----------------|--------|
| **Bruise** | `BRUISE_HEAL_DURATION_SECONDS` (14 days) × `BRUISE_PART_DURATION_MULTIPLIERS[part]` | Contusions ~2 weeks (MedlinePlus, Cleveland Clinic). Head 1.2×, chest 1.1×, limbs 1.0×. |
| **Cut**    | `get_tissue_heal_duration_seconds(part, severity)` | Minor ~4 d, moderate ~10 d, severe ~21 d, critical ~42 d; part mults (head/chest slower). |
| **Crush**  | Same as cut (tissue duration by severity + part) | Blunt with bleeding; same healing phases as tissue. |

So each wound has a **unique** duration by body part, severity, and type. Bruises resolve in ~2 weeks; cuts/crushes use the existing tissue table (unique per part and severity).

---

## Wound Types and Bruises

- **BleedingConstants:** `INJURY_TYPE_CUT`, `INJURY_TYPE_CRUSH`, `INJURY_TYPE_BRUISE`. Bruise has bleeding rate 0 for all severities.
- **Creation:** In `_add_wound`, if `injury_type == crush` and `severity == minor`, the wound is stored as **bruise** (so minor blunt creates a bruise: pain, no bleed, 14-day resolution).
- **Pain:** All wounds (cut, crush, bruise) contribute to `get_total_pain()` with the same formula; pain decays as each wound’s healing progress increases.

---

## Backwards Compatibility

- Wounds created before this system (no `created_at_game_time` or `healing_duration_seconds`) are **backfilled** in `process_healing`: they get `created_at_game_time = _game_time_seconds` and `healing_duration_seconds` from `get_wound_healing_duration_seconds(part, severity, injury_type)`. From the next time step they participate in per-wound healing and resolution.

---

## API (CoreEntity / Character)

| Method | Purpose |
|--------|---------|
| `get_total_pain()` | Sum of pain from all wounds (each weighted by `1 - healing_progress`). |
| `get_wounds()` | Copy of `wounds` (each injury has `created_at_game_time`, `healing_duration_seconds`, etc.). |
| `get_wound_healing_progress(injury)` | 0.0 (fresh) to 1.0 (resolved) for one wound (for UI). |
| `get_game_time_seconds()` | Current game time (e.g. for save/load). |
| `process_healing(seconds)` | Advances game time, backfills legacy wounds, removes resolved wounds, then tissue/bone/blood healing. |

---

## Flow Summary

1. **Hit:** `take_damage_split` → `_add_wound(part, cut|crush, damage, sub_region)`. Minor crush becomes bruise. Each wound gets `created_at_game_time`, `healing_duration_seconds` (from part + severity + type).
2. **Pain:** `get_total_pain()` uses `(1 - progress)` per wound; progress = `1 - exp(-age / tau)`, tau = duration/3.
3. **Time advance:** `process_healing(seconds)` → advance `_game_time_seconds`; backfill missing wound fields; remove wounds with progress ≥ 0.95; then tissue/bone/blood as before.
4. **Bleeding:** Unchanged; clotting still removes bleeding wounds when rate → 0 in `process_bleeding`.

Result: pain decreases per wound as it “heals” over time, with durations that are unique per body part and wound type and aligned with the medical references in PAIN_HEALING_BRUISE_MEDICAL_RESEARCH.md.
