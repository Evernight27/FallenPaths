class_name TuningConfigData
extends RefCounted

## Serializable config structures for the combat tuning scene.
## Each combatant has species, stats, weapon, form, guard.

const _Bp := preload("res://core/BodyPartConstants.gd")
const _ArmorConst := preload("res://resources/armor/ArmorConstants.gd")

static func _sanitize_name(raw: String) -> String:
	"""Remove invisible/control characters, BOM and BBCode artifacts from display names."""
	var s := raw.strip_edges()
	s = s.trim_prefix("\ufeff")  # BOM
	# Strip zero-width chars and control characters (keep printable ASCII + common Unicode letters/digits/space)
	return s.replace("\u200b", "").replace("\u200c", "").replace("\u200d", "").replace("\u200e", "").replace("\u200f", "")

const SPECIES_OPTIONS: Array[String] = [
	"res://resources/species/human.tres",
]

# Body part order used for display and serialization.
const BODY_PARTS: Array[String] = [
	_Bp.PART_HEAD,
	_Bp.PART_CHEST,
	_Bp.PART_RIGHT_ARM,
	_Bp.PART_LEFT_ARM,
	_Bp.PART_RIGHT_LEG,
	_Bp.PART_LEFT_LEG,
]

## Per-combatant config: what to spawn and how to configure it.
class TuningCombatantConfig:
	var display_name: String = "Attacker"
	var species_tres_path: String = "res://resources/species/human.tres"
	var strength: int = 100
	var agility: int = 100
	var intelligence: int = 100
	var endurance: int = 100
	var perception: int = 100
	var weapon_id: String = "SWORD"
	var form: String = "balanced"
	var guard_line: String = "high"
	var armor_overrides: Dictionary = {}  # part -> armor_resource_path

	func _init(
		p_name: String = "Attacker",
		p_weapon: String = "SWORD",
		p_form: String = "balanced",
		p_guard: String = "high",
		p_str: int = 100, p_agi: int = 100, p_int: int = 100, p_end: int = 100, p_per: int = 100
	):
		display_name = TuningConfigData._sanitize_name(p_name)
		weapon_id = p_weapon
		form = p_form
		guard_line = p_guard
		strength = p_str
		agility = p_agi
		intelligence = p_int
		endurance = p_end
		perception = p_per

	## Randomize stats/form/guard/resources/armor/species but keep a fixed weapon (weapon-sweep batches).
	func randomize_with_weapon(fixed_weapon_id: String) -> void:
		randomize_loadout()
		weapon_id = fixed_weapon_id

	## Do not name this `randomize()` — bare calls resolve to Godot's global RNG seed function.
	func randomize_loadout() -> void:
		display_name = TuningConfigData._sanitize_name(["Warrior", "Mercenary", "Sellsword", "Veteran", "Rogue", "Berserker", "Shield-bearer", "Skirmisher"][randi() % 8])

		strength = randi() % 61 + 70  # 70-130
		agility = randi() % 61 + 70
		intelligence = randi() % 61 + 70
		endurance = randi() % 61 + 70
		perception = randi() % 61 + 70

		var weapons := ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
		weapon_id = weapons[randi() % weapons.size()]

		var forms := ["balanced", "wrath", "plow", "fool", "ox", "wall", "tempest"]
		form = forms[randi() % forms.size()]

		var guards := ["high", "low", "left", "right"]
		guard_line = guards[randi() % guards.size()]

		species_tres_path = SPECIES_OPTIONS[randi() % SPECIES_OPTIONS.size()]

		armor_overrides.clear()
		var armor_count := randi() % 3  # 0-2 armor pieces
		var all_parts := ["head", "chest", "right_arm", "left_arm", "right_leg", "left_leg"]
		var parts_to_armor := []
		for i in armor_count:
			if parts_to_armor.size() >= all_parts.size():
				break
			var available := []
			for p in all_parts:
				if not p in parts_to_armor:
					available.append(p)
			if available.is_empty():
				break
			parts_to_armor.append(available[randi() % available.size()])
		for part in parts_to_armor:
			var options: Array = _ArmorConst.get_armor_options_by_part().get(part, [])
			if not options.is_empty():
				armor_overrides[part] = options[randi() % options.size()]

	static func random_configs_pair() -> Array[TuningCombatantConfig]:
		var atk := TuningCombatantConfig.new("Attacker")
		var def := TuningCombatantConfig.new("Defender")
		atk.randomize_loadout()
		def.randomize_loadout()
		return [atk, def]

## Default attacker: sword, balanced form, 110/100/105/105/95 stats.
static func default_attacker_config() -> TuningCombatantConfig:
	return TuningCombatantConfig.new(
		"Attacker", "SWORD", "balanced", "high",
		110, 100, 105, 105, 95
	)

## Default defender: sword, plow form (defensive), 100/100/100/100/100 stats.
static func default_defender_config() -> TuningCombatantConfig:
	return TuningCombatantConfig.new(
		"Defender", "SWORD", "plow", "middle",
		100, 100, 100, 100, 100
	)

## Standard heavy vs light scenario.
static func heavy_vs_light_configs() -> Array[TuningCombatantConfig]:
	return [
		TuningCombatantConfig.new("Heavy", "MACE", "wrath", "high", 140, 80, 90, 130, 80),
		TuningCombatantConfig.new("Light", "SWORD", "fool", "low", 80, 140, 100, 80, 120),
	]

## Spear vs sword.
static func spear_vs_sword_configs() -> Array[TuningCombatantConfig]:
	return [
		TuningCombatantConfig.new("Spear", "SPEAR", "ox", "middle", 110, 100, 100, 100, 100),
		TuningCombatantConfig.new("Sword", "SWORD", "balanced", "high", 100, 100, 100, 100, 100),
	]

## HEMA calibration: human sword duel, no armor (mirrors ii2b intent).
static func hema_sword_duel_configs() -> Array[TuningCombatantConfig]:
	var atk := TuningCombatantConfig.new(
		"Attacker", "SWORD", "balanced", "high",
		100, 100, 100, 100, 100
	)
	atk.species_tres_path = "res://resources/species/human.tres"
	var def := TuningCombatantConfig.new(
		"Defender", "SWORD", "plow", "low",
		100, 100, 100, 100, 100
	)
	def.species_tres_path = "res://resources/species/human.tres"
	return [atk, def]


const WEAPON_IDS: Array[String] = ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]

const GOBLIN_BASELINE_STATS := {
	"strength": 60,
	"agility": 115,
	"intelligence": 70,
	"endurance": 70,
	"perception": 90,
}

const HUMAN_BASELINE_STATS := {
	"strength": 100,
	"agility": 100,
	"intelligence": 100,
	"endurance": 100,
	"perception": 100,
}


static func armor_profile_none() -> Dictionary:
	return {}


static func armor_profile_light() -> Dictionary:
	return {
		"head": "LEATHER_CAP",
		"chest": "LEATHER_CUIRASS",
	}


static func armor_profile_medium() -> Dictionary:
	return {
		"head": "KETTLE_HELM",
		"chest": "GAMBESON",
		"right_arm": "LEATHER_BRACERS_RIGHT",
		"left_leg": "LEATHER_GREAVES_LEFT",
	}


static func armor_profile_heavy() -> Dictionary:
	return {
		"head": "KETTLE_HELM",
		"chest": "CUIRASS",
		"right_arm": "VAMBRACES_RIGHT",
		"left_arm": "VAMBRACES_LEFT",
		"right_leg": "GREAVES_RIGHT",
		"left_leg": "GREAVES_LEFT",
	}


static func fighter_config(
	display_name: String,
	weapon_id: String,
	species_path: String = "res://resources/species/human.tres",
	form: String = "balanced",
	guard_line: String = "high",
	stats: Dictionary = HUMAN_BASELINE_STATS,
	armor: Dictionary = {}
) -> TuningCombatantConfig:
	var c := TuningCombatantConfig.new(
		display_name, weapon_id, form, guard_line,
		int(stats.get("strength", 100)),
		int(stats.get("agility", 100)),
		int(stats.get("intelligence", 100)),
		int(stats.get("endurance", 100)),
		int(stats.get("perception", 100))
	)
	c.species_tres_path = species_path
	c.armor_overrides = armor.duplicate()
	return c


static func mirror_duel_configs(
	weapon_id: String,
	species_path: String = "res://resources/species/human.tres",
	stats: Dictionary = HUMAN_BASELINE_STATS,
	armor: Dictionary = {}
) -> Array[TuningCombatantConfig]:
	var wid: String = weapon_id.to_upper()
	var default_form: String = "balanced"
	if wid == "MACE" or wid == "AXE":
		default_form = "wrath"
	elif wid == "SPEAR":
		default_form = "ox"
	elif wid == "DAGGER":
		default_form = "fool"
	return [
		fighter_config("Attacker", wid, species_path, default_form, "high", stats, armor),
		fighter_config("Defender", wid, species_path, "plow", "low", stats, armor),
	]


static func human_weapon_mirror_configs(weapon_id: String) -> Array[TuningCombatantConfig]:
	return mirror_duel_configs(weapon_id)


static func human_vs_goblin_configs(weapon_id: String) -> Array[TuningCombatantConfig]:
	var wid: String = weapon_id.to_upper()
	return [
		fighter_config("Human", wid, "res://resources/species/human.tres", "balanced", "high", HUMAN_BASELINE_STATS),
		fighter_config("Goblin", wid, "res://resources/species/goblin.tres", "fool", "low", GOBLIN_BASELINE_STATS),
	]


static func sword_armor_tier_configs(tier: String) -> Array[TuningCombatantConfig]:
	var armor: Dictionary = armor_profile_none()
	match tier.to_lower():
		"light":
			armor = armor_profile_light()
		"medium":
			armor = armor_profile_medium()
		"heavy":
			armor = armor_profile_heavy()
	return mirror_duel_configs("SWORD", "res://resources/species/human.tres", HUMAN_BASELINE_STATS, armor)


const WEAPON_SWEEP_KEY_PREFIX := "Weapon Sweep "


static func weapon_sweep_scenario_key(weapon_id: String) -> String:
	return "%s%s" % [WEAPON_SWEEP_KEY_PREFIX, weapon_id]


static func is_weapon_sweep_key(key: String) -> bool:
	return key.begins_with(WEAPON_SWEEP_KEY_PREFIX)


static func weapon_id_from_sweep_key(key: String) -> String:
	if not is_weapon_sweep_key(key):
		return ""
	var wid: String = key.substr(WEAPON_SWEEP_KEY_PREFIX.length()).strip_edges()
	return wid if wid in WEAPON_IDS else ""


## Fresh 1v1 pair: both wield `weapon_id`; all other fields randomized.
static func weapon_sweep_configs(weapon_id: String) -> Array[TuningCombatantConfig]:
	var wid: String = weapon_id.to_upper().strip_edges()
	var atk := TuningCombatantConfig.new("Attacker", wid)
	atk.randomize_with_weapon(wid)
	_ensure_min_armor(atk, wid)
	atk.display_name = _sanitize_name("Attacker")
	var def := TuningCombatantConfig.new("Defender", wid)
	def.randomize_with_weapon(wid)
	_ensure_min_armor(def, wid)
	def.display_name = _sanitize_name("Defender")
	return [atk, def]

const TWO_HANDED_WEAPONS: PackedStringArray = ["SPEAR"]

static func _ensure_min_armor(cfg: TuningCombatantConfig, weapon_id: String) -> void:
	if not weapon_id.to_upper().strip_edges() in TWO_HANDED_WEAPONS:
		return
	var current_count := cfg.armor_overrides.size()
	if current_count >= 1:
		return
	var all_parts := ["head", "chest", "right_arm", "left_arm", "right_leg", "left_leg"]
	for part in all_parts:
		if not part in cfg.armor_overrides:
			var options: Array = _ArmorConst.get_armor_options_by_part().get(part, [])
			if not options.is_empty():
				cfg.armor_overrides[part] = options[randi() % options.size()]
				break


## One scenario key per weapon for batch weapon-sweep mode.
static func weapon_sweep_keys() -> Array[String]:
	var out: Array[String] = []
	for wid in WEAPON_IDS:
		out.append(weapon_sweep_scenario_key(wid))
	return out


## Keys run sequentially by the balance-matrix batch (mirror + cross-species + armor tiers).
static func balance_matrix_keys() -> Array[String]:
	var out: Array[String] = []
	for wid in WEAPON_IDS:
		out.append("Mirror %s" % wid)
	out.append_array([
		"Human vs Goblin (Sword)",
		"Human vs Goblin (Spear)",
		"Human vs Goblin (Dagger)",
		"Sword Unarmored",
		"Sword Light Armor",
		"Sword Medium Armor",
		"Sword Heavy Armor",
		"Heavy vs Light",
		"Spear vs Sword",
		"HEMA Sword Duel",
	])
	return out


static func scenario_menu_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	entries.append({"key": "Random", "label": "Random", "description": "Fully randomized matchup each cycle", "separator": false})
	entries.append({"key": "", "label": "--- General ---", "description": "", "separator": true})
	entries.append({"key": "Default", "label": "Default", "description": "Balanced sword duel (legacy attacker/defender stats)", "separator": false})
	entries.append({"key": "HEMA Sword Duel", "label": "HEMA Sword Duel", "description": "Human SWORD vs SWORD, 100 stats, no armor (ii2b)", "separator": false})
	entries.append({"key": "", "label": "--- Weapon mirrors (human, no armor) ---", "description": "", "separator": true})
	for wid in WEAPON_IDS:
		entries.append({
			"key": "Mirror %s" % wid,
			"label": "Mirror %s" % wid,
			"description": "Human %s vs %s, 100 stats, no armor — weapon calibration" % [wid, wid],
			"separator": false,
		})
	entries.append({"key": "", "label": "--- Species cross ---", "description": "", "separator": true})
	entries.append({
		"key": "Human vs Goblin (Sword)",
		"label": "Human vs Goblin (Sword)",
		"description": "Human baseline stats vs goblin species stats, SWORD",
		"separator": false,
	})
	entries.append({
		"key": "Human vs Goblin (Spear)",
		"label": "Human vs Goblin (Spear)",
		"description": "Human vs goblin, SPEAR reach matchup",
		"separator": false,
	})
	entries.append({
		"key": "Human vs Goblin (Dagger)",
		"label": "Human vs Goblin (Dagger)",
		"description": "Human vs goblin, DAGGER knife fight",
		"separator": false,
	})
	entries.append({"key": "", "label": "--- Armor tiers (human sword) ---", "description": "", "separator": true})
	entries.append({
		"key": "Sword Unarmored",
		"label": "Sword Unarmored",
		"description": "Human SWORD mirror duel, no armor",
		"separator": false,
	})
	for tier in ["Light", "Medium", "Heavy"]:
		entries.append({
			"key": "Sword %s Armor" % tier,
			"label": "Sword %s Armor" % tier,
			"description": "Human SWORD mirror duel, %s kit on both" % tier.to_lower(),
			"separator": false,
		})
	entries.append({"key": "", "label": "--- Classic matchups ---", "description": "", "separator": true})
	entries.append({"key": "Heavy vs Light", "label": "Heavy vs Light", "description": "MACE bruiser vs SWORD skirmisher", "separator": false})
	entries.append({"key": "Spear vs Sword", "label": "Spear vs Sword", "description": "Reach vs sword baseline", "separator": false})
	entries.append({"key": "Goblin vs Human", "label": "Goblin vs Human", "description": "Randomized goblin vs randomized human", "separator": false})
	return entries


static func configs_for_scenario(key: String) -> Array:
	match key:
		"Random":
			return TuningCombatantConfig.random_configs_pair()
		"Default":
			return [default_attacker_config(), default_defender_config()]
		"HEMA Sword Duel":
			return hema_sword_duel_configs()
		"Heavy vs Light":
			return heavy_vs_light_configs()
		"Spear vs Sword":
			return spear_vs_sword_configs()
		"Goblin vs Human":
			var atk := TuningCombatantConfig.new("Goblin")
			atk.species_tres_path = "res://resources/species/goblin.tres"
			atk.randomize_loadout()
			var def := TuningCombatantConfig.new("Human")
			def.randomize_loadout()
			return [atk, def]
		"Human vs Goblin (Sword)":
			return human_vs_goblin_configs("SWORD")
		"Human vs Goblin (Spear)":
			return human_vs_goblin_configs("SPEAR")
		"Human vs Goblin (Dagger)":
			return human_vs_goblin_configs("DAGGER")
		"Sword Unarmored":
			return sword_armor_tier_configs("none")
		"Sword Light Armor":
			return sword_armor_tier_configs("light")
		"Sword Medium Armor":
			return sword_armor_tier_configs("medium")
		"Sword Heavy Armor":
			return sword_armor_tier_configs("heavy")
		_:
			if is_weapon_sweep_key(key):
				var sweep_wid: String = weapon_id_from_sweep_key(key)
				if not sweep_wid.is_empty():
					return weapon_sweep_configs(sweep_wid)
			if key.begins_with("Mirror "):
				var wid: String = key.substr(7).strip_edges()
				if wid in WEAPON_IDS:
					return human_weapon_mirror_configs(wid)
	return []
