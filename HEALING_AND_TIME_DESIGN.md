# Healing and Time Design (Medical Realism)

## Bleeding Continues Outside Combat

- **Bleeding and blood loss advance whenever time advances.**  
  During combat, `CombatManager._process(delta)` ticks `process_bleeding(delta)` and `process_blood_loss(delta)` every frame.  
  Outside combat, when the player moves one tile (no enemy), `_advance_time_one_minute()` runs **process_bleeding(60)**, **process_blood_loss(60)**, then **process_healing(60)** for the player and party. So bleeding continues in real time; the medical system is based on medical realism.

## Time Advance: 1 Minute Per Move

- When the player **moves one tile** and **does not** start combat, the game advances time by **1 minute** (60 seconds).
- For each party member: **process_bleeding(60)** → **process_blood_loss(60)** → **process_healing(60)**.  
  Blood loss can kill during time advance (e.g. bleed out while travelling).

## Medically Realistic Healing (Duration-Based)

Healing is **duration-based**: the time to restore a part from 0 to full is set from medical averages (days/weeks). Rate = (max − current) / duration_seconds, so healing approaches full over that duration.

### Tissue (body_cutting / body_blunt)

- **Duration to full heal** (seconds) = base duration by **worst wound severity on that part** × part multiplier.
- **Severity durations (base):**
  - **Minor** (superficial): ~4 days (345 600 s)
  - **Moderate**: ~10 days (864 000 s)
  - **Severe**: ~3 weeks (1 814 400 s)
  - **Critical**: ~6 weeks (3 628 800 s)
- **Part multipliers** (longer duration = slower heal): head 1.15×, chest 1.25×, limbs 1.0×.
- Each pool (cutting, blunt) heals toward `body_max` at rate = `body_max / duration` per second (capped so current never exceeds max).

### Bone (bone_health)

- **Duration to full heal**: ~6 weeks (42 days = 3 628 800 s) base; part multipliers (head 1.2×, chest 1.3×, legs 1.1×, arms 1.0×).
- Rate = `bone_max / duration` per second.

### Blood Volume

- When **not bleeding** (`get_total_bleeding_rate() == 0`), blood volume recovers toward 100% over **24 hours** (86 400 s): rate = (100 − blood_volume) / 86 400 per second.

## Bleeding and Wound Severity (Existing)

- Bleeding rates and severities are defined in **BleedingConstants** (injury type + severity + body part multipliers).
- Wounds are created on damage in **CoreEntity**; severity is derived from damage vs part max (and absolute thresholds).
- Clotting and bandaging reduce bleeding rate; blood loss drains blood_volume; death at ≤20% blood volume.

## Summary

| System        | When it runs |
|---------------|----------------|
| Bleeding      | Combat (every frame) + time advance (60 s per move) |
| Blood loss    | Combat (every frame) + time advance (60 s per move) |
| Healing       | Time advance only (60 s per move) |
| Blood recover | Inside process_healing when not bleeding (24 h to approach 100%) |

Tuning: **core/HealingConstants.gd** (durations, part multipliers), **core/BleedingConstants.gd** (bleeding rates, severities, blood thresholds).
