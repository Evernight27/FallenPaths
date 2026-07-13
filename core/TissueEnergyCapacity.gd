class_name TissueEnergyCapacity
extends RefCounted

## M6: J-internal tissue capacity '??" display `body_cutting` / `body_blunt` (production on).
## One J reservoir per part; cut and blunt displays debit independently (severance parity with HP path).


static func is_active(force: bool = false) -> bool:
    return force or BleedingConstants.FEATURE_TISSUE_ENERGY_POOL


static func design_ke_j_for_part(part: String) -> float:
    return CombatDesignAnchors.design_ke_j_for_part(part)


static func capacity_j_for_part(part: String, body_max_tissue: int) -> float:
    var display_ref: float = float(CombatDesignAnchors.reference_tissue_display_for_part(part))
    var tissue_max: float = maxf(1.0, float(body_max_tissue))
    return design_ke_j_for_part(part) * (tissue_max / display_ref)


static func dual_display_max(body_max_tissue: int) -> float:
    return float(maxi(1, body_max_tissue * 2))


## Total cut+blunt display points from remaining J (both streams full -> dual_display_max).
static func display_total_from_remaining_j(body_max_tissue: int, remaining_j: float, capacity_j: float) -> float:
    if body_max_tissue <= 0 or capacity_j <= 0.01:
        return 0.0
    var frac: float = clampf(remaining_j / capacity_j, 0.0, 1.0)
    return round(dual_display_max(body_max_tissue) * frac)


## Per-stream display (audit helper): half of total at same J fraction.
static func display_tissue_from_remaining_j(body_max_tissue: int, remaining_j: float, capacity_j: float) -> float:
    return display_total_from_remaining_j(body_max_tissue, remaining_j, capacity_j) * 0.5


static func remaining_j_from_display_pools(
    body_max_tissue: int, display_cutting: float, display_blunt: float, capacity_j: float
) -> float:
    if body_max_tissue <= 0 or capacity_j <= 0.01:
        return 0.0
    var display_total: float = maxf(0.0, display_cutting) + maxf(0.0, display_blunt)
    return capacity_j * (display_total / dual_display_max(body_max_tissue))


static func seed_entity_energy_pools(entity: Node, from_species_apply: bool = true) -> void:
    if not ("tissue_energy_capacity_j" in entity):
        return
    entity.tissue_energy_capacity_j = {}
    entity.tissue_energy_remaining_j = {}
    if not from_species_apply or not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        return
    if not entity.has_method("_get_body_part_list"):
        return
    for part: Variant in entity._get_body_part_list():
        var p: String = str(part)
        var body_max_t: int = int(entity.body_max.get(p, 1))
        var cap_j: float = capacity_j_for_part(p, body_max_t)
        entity.tissue_energy_capacity_j[p] = cap_j
        entity.tissue_energy_remaining_j[p] = cap_j
        sync_display_pools_from_j(entity, p, 0.5)


static func ensure_energy_pools_for_part(entity: Node, part: String) -> void:
    if not ("tissue_energy_capacity_j" in entity):
        return
    if entity.tissue_energy_capacity_j.has(part):
        return
    var body_max_t: int = int(entity.body_max.get(part, 1))
    var cap_j: float = capacity_j_for_part(part, body_max_t)
    entity.tissue_energy_capacity_j[part] = cap_j
    var rem_j: float = remaining_j_from_display_pools(
        body_max_t,
        entity.body_cutting.get(part, 0.0),
        entity.body_blunt.get(part, 0.0),
        cap_j,
    )
    entity.tissue_energy_remaining_j[part] = clampf(rem_j, 0.0, cap_j)


## Full J -> split cut/blunt display (seed / lazy init).
static func sync_display_pools_from_j(entity: Node, part: String, cut_share: float = 0.5) -> void:
    if not entity.tissue_energy_capacity_j.has(part):
        return
    var body_max_t: int = int(entity.body_max.get(part, 1))
    var cap_j: float = float(entity.tissue_energy_capacity_j[part])
    var rem_j: float = entity.tissue_energy_remaining_j.get(part, 0.0)
    var total_display: float = display_total_from_remaining_j(body_max_t, rem_j, cap_j)
    var share: float = clampf(cut_share, 0.0, 1.0)
    var cut_disp: float = total_display * share
    entity.body_cutting[part] = entity._round_tissue(cut_disp)
    entity.body_blunt[part] = entity._round_tissue(maxf(0.0, total_display - cut_disp))


## Debit cut/blunt display like HP path; sync remaining J from displays (bone unchanged).
static func apply_tissue_damage_to_entity(entity: Node, part: String, to_cut: float, to_blunt: float) -> void:
    ensure_energy_pools_for_part(entity, part)
    if not entity.tissue_energy_capacity_j.has(part):
        return
    var body_max_t: int = int(entity.body_max.get(part, 1))
    var cap_j: float = float(entity.tissue_energy_capacity_j[part])
    var cur_cut: float = entity.body_cutting.get(part, 0.0)
    var cur_blunt: float = entity.body_blunt.get(part, 0.0)
    entity.body_cutting[part] = entity._round_tissue(maxf(0.0, cur_cut - maxf(0.0, to_cut)))
    entity.body_blunt[part] = entity._round_tissue(maxf(0.0, cur_blunt - maxf(0.0, to_blunt)))
    var rem_j: float = remaining_j_from_display_pools(
        body_max_t,
        entity.body_cutting.get(part, 0.0),
        entity.body_blunt.get(part, 0.0),
        cap_j,
    )
    entity.tissue_energy_remaining_j[part] = clampf(rem_j, 0.0, cap_j)
