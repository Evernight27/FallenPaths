class_name EntityScarAfflictions
extends RefCounted

## Scar affliction multipliers, extracted from **`CoreEntity`**.
## Pure functions over `entity: Node` reading `campaign_afflictions` array.
## All tuning values referenced from `BleedingConstants` by class_name.


static func get_damage_mult(entity: Node, part: String) -> float:
    var m: float = 1.0
    for raw in entity.campaign_afflictions:
        if raw is Dictionary and str(raw.get("part", "")) == part:
            m *= clampf(float(raw.get("damage_mult", 1.0)), 0.5, 2.0)
    return m


static func get_bleed_mult(entity: Node, part: String) -> float:
    var m: float = 1.0
    for raw in entity.campaign_afflictions:
        if raw is Dictionary and str(raw.get("part", "")) == part:
            m *= clampf(float(raw.get("bleed_mult", 1.0)), 0.5, 2.0)
    return m


static func get_heal_mult(entity: Node, part: String) -> float:
    var m: float = 1.0
    for raw in entity.campaign_afflictions:
        if raw is Dictionary and str(raw.get("part", "")) == part:
            m *= clampf(float(raw.get("heal_mult", 1.0)), 0.1, 1.0)
    return m


static func get_part_penalty(entity: Node, part: String) -> Dictionary:
    var out: Dictionary = {"move_speed": 1.0, "grip": 1.0, "perception": 1.0, "stamina_pool": 1.0}
    if part.is_empty():
        return out
    for raw in entity.campaign_afflictions:
        if not raw is Dictionary or str(raw.get("part", "")) != part:
            continue
        for k in out.keys():
            var v: float = float(raw.get(k, 1.0))
            if v != 1.0:
                out[k] *= clampf(v, 0.3, 1.0)
    return out


static func get_reinjury_mult(entity: Node, part: String) -> float:
    if part.is_empty():
        return 1.0
    for raw in entity.campaign_afflictions:
        if raw is Dictionary and str(raw.get("part", "")) == part:
            return BleedingConstants.SCAR_REINJURY_MULT
    return 1.0
