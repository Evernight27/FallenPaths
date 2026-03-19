class_name FormationPreset
extends RefCounted

## Builds formation presets for party and enemy. Used by CombatFlow, BattleScene, CombatManager.
## Preset: { files: int, ranks: int, density: String } — Option A: files = front-line count, ranks = depth.
## Fill order: rank 0 first (primary melee), then rank 1, etc. See FORMATION_FILE_DENSITY_SURVIVABILITY_INVESTIGATION.
## Density spacing: tight→compact UI, normal→default, loose→wide.

const DENSITY_TIGHT := "tight"
const DENSITY_NORMAL := "normal"
const DENSITY_LOOSE := "loose"

# UI pixel spacing by density (GridContainer h_separation, v_separation)
const SPACING_TIGHT_PX := 8
const SPACING_NORMAL_PX := 16
const SPACING_LOOSE_PX := 28

## Returns preset dict. Default: 2 files, ceil(count/2) ranks, normal density.
## Use for_front_count when you want explicit front-line count (e.g. 4 in front, 2 ranks behind).
static func default_for_count(count: int, density: String = DENSITY_NORMAL) -> Dictionary:
	if count <= 0:
		return {"files": 1, "ranks": 1, "density": density}
	var files: int = min(2, count)
	var ranks: int = int(ceil(float(count) / float(files)))
	return {"files": files, "ranks": ranks, "density": density}

## Returns preset with explicit front-line count. files = front_count, ranks = ceil(count/front_count).
## Example: for_front_count(6, 4) -> 4 in rank 0, 2 in rank 1.
static func for_front_count(count: int, front_count: int, density: String = DENSITY_NORMAL) -> Dictionary:
	if count <= 0 or front_count <= 0:
		return {"files": 1, "ranks": 1, "density": density}
	var files: int = mini(front_count, count)
	var ranks: int = int(ceilf(float(count) / float(files)))
	return {"files": files, "ranks": ranks, "density": density}

## Returns pixel separation for GridContainer from density.
static func separation_px_from_density(density: String) -> int:
	match density:
		DENSITY_TIGHT:
			return SPACING_TIGHT_PX
		DENSITY_LOOSE:
			return SPACING_LOOSE_PX
		_:
			return SPACING_NORMAL_PX
