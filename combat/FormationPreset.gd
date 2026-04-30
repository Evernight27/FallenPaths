class_name FormationPreset
extends RefCounted

## Builds formation presets for party and enemy. Used by CombatFlow, BattleScene, CombatManager.
## Preset: { files: int, ranks: int, density: String } — Option A: files = front-line count, ranks = depth.
## Optional **discipline** (Tier 1.4): `line_discipline` (`CombatConstants.LINE_DISCIPLINE_*`; formation overrides encounter).
## Posture: `discipline_posture_*_delta` + hysteresis via `CombatFormationEngagement`. Movement: only `loose` allows
## rank-0 solo `fall_back` into an empty same-file rear; `strict` / `normal` / empty use paired swap/drag/fall_back_pair only.
## Fill order: rank 0 first (primary melee), then rank 1, etc. See FORMATION_FILE_DENSITY_SURVIVABILITY_INVESTIGATION.
## Density spacing: tight→compact UI, normal→default, loose→wide.

const DENSITY_TIGHT := "tight"
const DENSITY_NORMAL := "normal"
const DENSITY_LOOSE := "loose"

# UI pixel spacing by density (GridContainer h_separation, v_separation)
# h = file-to-file (lateral); v = rank-to-rank (depth). Ranks typically closer than files.
const SPACING_TIGHT_PX := 8
const SPACING_NORMAL_PX := 16
const SPACING_LOOSE_PX := 28
## Ratio of v_separation to h_separation. <1 = ranks closer than files (formation depth < width).
const RANK_VS_FILE_SPACING_RATIO := 0.65

## Returns preset dict. Default: front line up to `CombatConstants.FORMATION_MAX_FRONT_FILES_DEFAULT`, ranks = ceil(n/files).
## Count is clamped to `CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP`. Use for_front_count for an explicit front width.
static func default_for_count(count: int, density: String = DENSITY_NORMAL) -> Dictionary:
	if count <= 0:
		return {"files": 1, "ranks": 1, "density": density}
	var n: int = mini(count, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP)
	var files: int = mini(CombatConstants.FORMATION_MAX_FRONT_FILES_DEFAULT, n)
	var ranks: int = maxi(1, int(ceilf(float(n) / float(files))))
	return {"files": files, "ranks": ranks, "density": density}

## Returns preset with explicit front-line count. files = front_count, ranks = ceil(count/front_count).
## Example: for_front_count(6, 4) -> 4 in rank 0, 2 in rank 1.
static func for_front_count(count: int, front_count: int, density: String = DENSITY_NORMAL) -> Dictionary:
	if count <= 0 or front_count <= 0:
		return {"files": 1, "ranks": 1, "density": density}
	var n: int = mini(count, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP)
	var files: int = mini(front_count, n)
	var ranks: int = maxi(1, int(ceilf(float(n) / float(files))))
	return {"files": files, "ranks": ranks, "density": density}

## Returns horizontal (file-to-file) pixel separation for GridContainer from density.
static func separation_px_from_density(density: String) -> int:
	match density:
		DENSITY_TIGHT:
			return SPACING_TIGHT_PX
		DENSITY_LOOSE:
			return SPACING_LOOSE_PX
		_:
			return SPACING_NORMAL_PX

## Returns vertical (rank-to-rank) pixel separation. Ranks closer than files for formation depth.
static func v_separation_px_from_density(density: String) -> int:
	return int(separation_px_from_density(density) * RANK_VS_FILE_SPACING_RATIO)
