class_name CompanySchool
extends RefCounted

## XCamp-6 (gladiatorial school system): the rival schools and their master lineups.
##
## Owns the single world-meta home for all campaign school state so the scout and match
## modules and persistence share one coherent block:
##   state := {
##     "dossiers":      { school_id: Array[OpponentFighterProfile] },  # footprint:
##     "scouts":        { member_name: {school_id, return_day} },      #  :: CompanyScout
##     "active_match":  { ... },                                       # :: CompanyMatch
##   }
##
## Dossiers are the *scouted* view of a school: they start at REVEAL_UNKNOWN (name only) and
## climb one tier per scout paid (weapon, then full tendency). The lineup order in the dossier
## is itself the strategic information a player counter-orders against -- bout i pairs the
## company lineup[i] against the school lineup[i].

## World meta key for the whole XCamp-6 school state block. Persisted via
## CompanySchool.state_to_save / state_from_save (see CampaignPersistence).
const WORLD_META_SCHOOL_STATE: String = "gladiator_school_state"

## Part id vocabulary consumed by tendency.target_part (BodyPartConstants vocabulary).
const PART_HEAD: String = "head"
const PART_CHEST: String = "chest"
const PART_LEFT_ARM: String = "left_arm"
const PART_RIGHT_ARM: String = "right_arm"
const PART_LEFT_LEG: String = "left_leg"
const PART_RIGHT_LEG: String = "right_leg"

## Rival-school registry (id -> def). Deterministic so the harness can pin behavior.
## Lineup ordering is intentional (bout i pairs lineup[i] vs lineup[i]).
const SCHOOL_DEFS: Dictionary = {
	"house_verath": {
		"display_name": "House Verath",
		"prestige": 2,
		"lineup": [
			{
				"fighter_id": "verath_glaive", "display_name": "Marrik", "weapon_id": "SPEAR", "form_id": "wall",
				"stats": {"strength": 106, "agility": 96, "intelligence": 100, "endurance": 103, "perception": 108},
				"tendency": {"aggression": 0.35, "parry_bias": 0.8, "target_part": PART_HEAD},
			},
			{
				"fighter_id": "verath_maul", "display_name": "Enna", "weapon_id": "MACE", "form_id": "ox",
				"stats": {"strength": 112, "agility": 94, "intelligence": 97, "endurance": 109, "perception": 96},
				"tendency": {"aggression": 0.85, "parry_bias": 0.15, "target_part": PART_CHEST},
			},
			{
				"fighter_id": "verath_blade", "display_name": "Corvin", "weapon_id": "SWORD", "form_id": "balanced",
				"stats": {"strength": 101, "agility": 104, "intelligence": 103, "endurance": 100, "perception": 106},
				"tendency": {"aggression": 0.5, "parry_bias": 0.5, "target_part": ""},
			},
		],
	},
	"iron_pit": {
		"display_name": "The Iron Pit",
		"prestige": 3,
		"lineup": [
			{
				"fighter_id": "pit_blade", "display_name": "Sull", "weapon_id": "SWORD", "form_id": "wrath",
				"stats": {"strength": 108, "agility": 101, "intelligence": 98, "endurance": 102, "perception": 99},
				"tendency": {"aggression": 0.7, "parry_bias": 0.3, "target_part": PART_LEFT_ARM},
			},
			{
				"fighter_id": "pit_dagger", "display_name": "Vella", "weapon_id": "DAGGER", "form_id": "tempest",
				"stats": {"strength": 96, "agility": 113, "intelligence": 104, "endurance": 97, "perception": 110},
				"tendency": {"aggression": 0.4, "parry_bias": 0.75, "target_part": PART_CHEST},
			},
			{
				"fighter_id": "pit_axe", "display_name": "Gorst", "weapon_id": "AXE", "form_id": "plow",
				"stats": {"strength": 114, "agility": 95, "intelligence": 96, "endurance": 110, "perception": 97},
				"tendency": {"aggression": 0.45, "parry_bias": 0.6, "target_part": PART_HEAD},
			},
		],
	},
}

## Constants for the school-profile payload carried into a bout's combat encounter (for the
## combat-side tendency hook, which is a later slice). Intentionally defined here (world side)
## so combat reads them from the encounter config without importing world state.
const ENCOUNTER_KEY_SCHOOL_FIGHTER_PROFILE: String = "school_fighter_profile"
const ENCOUNTER_KEY_SCHOOL_ID: String = "school_id"


static func school_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for k in SCHOOL_DEFS.keys():
		ids.append(str(k))
	return ids


static func has_school(school_id: String) -> bool:
	return SCHOOL_DEFS.has(school_id)


static func school_display_name(school_id: String) -> String:
	if not SCHOOL_DEFS.has(school_id):
		return ""
	var def: Dictionary = SCHOOL_DEFS[school_id]
	return str(def.get("display_name", school_id))


static func school_prestige(school_id: String) -> int:
	if not SCHOOL_DEFS.has(school_id):
		return 0
	var def: Dictionary = SCHOOL_DEFS[school_id]
	return int(def.get("prestige", 1))


## Player-facing school intel (no leak past the reveal tiers: only ratio / names surface).
static func school_summary(world: Node, school_id: String) -> Dictionary:
	var doss: Array = dossier_for(world, school_id)
	return {
		"id": school_id,
		"display_name": school_display_name(school_id),
		"prestige": school_prestige(school_id),
		"roster_size": school_lineup_size(school_id),
		"fightable_roster": doss.size(),
		"reveal_ratio": OpponentFighterProfile.dossier_reveal_ratio(doss),
		"fully_revealed": not doss.is_empty() and dossier_fully_revealed(world, school_id),
	}


static func schools_overview(world: Node) -> Array:
	var out: Array = []
	for sid in school_ids():
		out.append(school_summary(world, sid))
	return out


## Master line-up definition rows (Array of Dictionaries) for a school. The opponent's preset
## fight order; bout i pairs the company lineup[i] against school lineup[i].
static func school_master_lineup_defs(school_id: String) -> Array:
	if not SCHOOL_DEFS.has(school_id):
		return []
	var def: Dictionary = SCHOOL_DEFS[school_id]
	var lineup: Variant = def.get("lineup", [])
	return lineup if lineup is Array else []


static func school_lineup_size(school_id: String) -> int:
	return school_master_lineup_defs(school_id).size()


## Master lineup as fresh OpponentFighterProfile instances (always REVEAL_UNKNOWN).
static func school_master_lineup(school_id: String) -> Array:
	var out: Array = []
	for row in school_master_lineup_defs(school_id):
		if row is not Dictionary:
			continue
		var d: Dictionary = row
		out.append(
			OpponentFighterProfile.make(
				str(d.get("fighter_id", "")),
				str(d.get("display_name", "")),
				str(d.get("weapon_id", "")),
				str(d.get("form_id", "")),
				_dup_dict(d.get("stats", {})),
				_dup_dict(d.get("tendency", {}))
			)
		)
	return out


## === State home (world meta) ===


static func _default_state() -> Dictionary:
	var dossiers: Dictionary = {}
	for sid in school_ids():
		dossiers[sid] = school_master_lineup(sid)
	return {"dossiers": dossiers, "scouts": {}, "active_match": {}}


## Whole-school state block from world meta. Never returns nil: missing/unknown schools get a
## master (REVEAL_UNKNOWN) dossier so the block is always internally consistent.
static func get_school_state(world: Node) -> Dictionary:
	var state: Dictionary = _default_state()
	if world == null:
		return state
	var raw: Variant = world.get_meta(WORLD_META_SCHOOL_STATE) if world.has_meta(WORLD_META_SCHOOL_STATE) else null
	if raw is Dictionary:
		state = raw
	return _ensure_dossiers(state)


static func set_school_state(world: Node, state: Dictionary) -> void:
	if world == null:
		return
	world.set_meta(WORLD_META_SCHOOL_STATE, _ensure_dossiers(state))


## Rebuild the block shape, seeding a master dossier for any registered school that is missing.
static func _ensure_dossiers(state: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"dossiers": _dup_dict(state.get("dossiers", {})),
		"scouts": _dup_dict(state.get("scouts", {})),
		"active_match": _dup_dict(state.get("active_match", {})),
	}
	var doss: Dictionary = out["dossiers"]
	for sid in school_ids():
		if not doss.has(sid):
			doss[sid] = school_master_lineup(sid)
	return out


## === Dossiers ===


## The scouted dossier for a school: Array[OpponentFighterProfile] in lineup order.
static func dossier_for(world: Node, school_id: String) -> Array:
	if not has_school(school_id) or world == null:
		return []
	var doss: Variant = get_school_state(world).get("dossiers", {}).get(school_id, [])
	var out: Array = []
	if doss is Array:
		for p in doss:
			if p is OpponentFighterProfile:
				out.append(p)
	return out


## How much of a school's roster the company has fully scouted (0.0..1.0).
static func dossier_reveal_ratio(world: Node, school_id: String) -> float:
	return OpponentFighterProfile.dossier_reveal_ratio(dossier_for(world, school_id))


static func dossier_fully_revealed(world: Node, school_id: String) -> bool:
	var doss: Array = dossier_for(world, school_id)
	return not doss.is_empty() and dossier_reveal_ratio(world, school_id) >= 1.0


## Advance every fighter in a school's dossier one reveal tier (used when a scout returns).
## Returns per-fighter log lines ("Name: weapon -> full"). No-op when the school is unknown.
static func advance_dossier_reveal(world: Node, school_id: String) -> PackedStringArray:
	var lines := PackedStringArray()
	if not has_school(school_id) or world == null:
		return lines
	var state: Dictionary = get_school_state(world)
	var doss: Dictionary = state.get("dossiers", {})
	var profiles: Array = dossier_for(world, school_id)
	for p in profiles:
		var before: int = p.reveal
		p.advance_reveal()
		lines.append("%s: %s -> %s" % [p.display_name, _reveal_label(before), _reveal_label(p.reveal)])
	doss[school_id] = profiles
	set_school_state(world, state)
	return lines


static func _reveal_label(tier: int) -> String:
	match tier:
		OpponentFighterProfile.REVEAL_WEAPON:
			return "weapon"
		OpponentFighterProfile.REVEAL_FULL:
			return "full"
		_:
			return "unknown"


## The player-visible dossier rows: exactly what the reveal tiers entitle the company to know.
## weapon_id + base stats surface at REVEAL_WEAPON; form/style + tendency only at REVEAL_FULL.
## Unknown fighters read as a clean name card (no intel leak to a naive UI).
static func dossier_visible_view(world: Node, school_id: String) -> Array:
	var out: Array = []
	for p in dossier_for(world, school_id):
		out.append(profile_visible_view(p))
	return out


static func profile_visible_view(p: OpponentFighterProfile) -> Dictionary:
	if p == null:
		return {}
	var row: Dictionary = {"name": p.display_name, "fighter_id": p.fighter_id}
	if p.has_weapon_reveal():
		row["weapon_id"] = p.weapon_id
		row["stats"] = (p.stats as Dictionary).duplicate(true) if p.stats is Dictionary else {}
	else:
		row["weapon_id"] = ""
		row["stats"] = {}
	if p.has_full_reveal():
		row["form_id"] = p.form_id
		row["tendency"] = (p.tendency as Dictionary).duplicate(true) if p.tendency is Dictionary else {}
	else:
		row["form_id"] = ""
		row["tendency"] = {}
	return row


## === Persistence boundary ===


## Convert the in-memory block (profile objects) into a JSON-safe saveable block.
static func state_to_save(world: Node) -> Dictionary:
	var state: Dictionary = get_school_state(world)
	var doss_out: Dictionary = {}
	var doss: Dictionary = state.get("dossiers", {})
	for sid in doss.keys():
		var arr: Array = []
		var profiles: Variant = doss[sid]
		if profiles is Array:
			for p in profiles:
				if p is OpponentFighterProfile:
					arr.append((p as OpponentFighterProfile).to_dict())
		doss_out[str(sid)] = arr
	return {
		"dossiers": doss_out,
		"scouts": _dup_dict(state.get("scouts", {})),
		"active_match": _dup_dict(state.get("active_match", {})),
	}


## Rebuild the world-meta block from a saved block (restores reveals, scouts, and match state).
static func state_from_save(world: Node, data: Dictionary) -> void:
	if world == null or data.is_empty():
		return
	var raw_dossiers: Variant = data.get("dossiers", {})
	if not (raw_dossiers is Dictionary):
		return
	var profiles_by_school: Dictionary = {}
	for sid in (raw_dossiers as Dictionary).keys():
		var arr: Array = []
		var raw: Variant = (raw_dossiers as Dictionary).get(sid, [])
		if raw is Array:
			for d in raw:
				if d is Dictionary:
					arr.append(OpponentFighterProfile.from_dict(d))
		profiles_by_school[str(sid)] = arr
	set_school_state(
		world,
		{
			"dossiers": profiles_by_school,
			"scouts": _dup_dict(data.get("scouts", {})),
			"active_match": _dup_dict(data.get("active_match", {})),
		}
	)


static func _dup_dict(d: Variant) -> Dictionary:
	return (d as Dictionary).duplicate(true) if d is Dictionary else {}