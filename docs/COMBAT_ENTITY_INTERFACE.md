# Combat Entity Interface

Nodes that participate in combat (Character, CoreEntity, CombatBody) must implement this interface. Combat systems use `CombatantEntityAccess` to safely call these methods.

## Required Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `get_weapon()` | Weapon or null | Weapon for attack type, damage, parry |
| `get_attacking_arm()` | String | "right_arm", "left_arm", or "" (cowering) |
| `get_attack_damage_modifier()` | float | Arm health × pain modifier for damage |
| `get_performance_modifier()` | float | Pain/consciousness modifier for gauge, hit chance |
| `get_targetable_parts()` | Array | Body parts that can be hit |
| `is_incapacitated()` | bool | Consciousness < threshold or cowering |
| `is_dead()` | bool | Blood loss or vital part destroyed |

## Optional (with defaults)

| Method | Returns | Default | Purpose |
|--------|---------|---------|---------|
| `get_hit_chance_performance_modifier()` | float | get_performance_modifier() | Hit chance specifically |
| `get_action_bar_performance_modifier()` | float | get_performance_modifier() | Gauge fill rate |
| `get_leg_functionality()` | float | 1.0 | Wind-up, dodge, mobility |
| `get_dodge_chance()` | float | 0.0 | Dodge probability |
| `get_part_dodge_modifier(part)` | float | 1.0 | Part-specific dodge |
| `get_passive_parry_reaction_time()` | float | — | Parry timing (needs weapon) |
| `get_armor_for_part(part)` | Variant | null | Armor for damage calc |
| `get_armor_sharp_resistance_for_part(part)` | float | 0.0 | Penetration |
| `get_armor_slots()` | Dictionary | {} | Equipment display |

## Medical

| Method | Purpose |
|--------|---------|
| `get_medical_entity()` | Returns health-holding node (Character → CombatBody) |
| `get_blood_volume()` | Blood level |
| `get_total_bleeding_rate()` | Bleeding rate |
| `get_wounded_parts()` | Parts with wounds |
| `can_apply_direct_pressure(part)` | Can hold pressure |
| `apply_direct_pressure(part)` | Apply pressure |
| `clear_direct_pressure()` | Release pressure |
| `is_applying_direct_pressure()` | Currently holding |
| `get_direct_pressure_part()` | Part being held |

## Damage

| Method | Purpose |
|--------|---------|
| `take_damage_split(cut, blunt, part, ...)` | Apply damage |
| `take_damage(amount, part, type, ...)` | Legacy single-stream |
| `process_bleeding(delta)` | Advance bleeding |
| `process_blood_loss(delta)` | Advance blood loss |

## Implementation Notes

- **Character**: Delegates to `_combat_body` (CombatBody/CoreEntity child).
- **CoreEntity**: Implements directly; delegates equipment to EntityEquipment, medical to EntityMedical, etc.
- **CombatantEntityAccess**: Centralized safe access; returns defaults when methods missing.
