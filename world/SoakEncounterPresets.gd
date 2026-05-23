class_name SoakEncounterPresets
extends RefCounted

## F5 soak encounter markers — docs/LIVE_PATHS.md#headless-gate-authoritative (editor-only convenience).
## **`emit_f5_soak_guide`** prints **`FP_COMBAT: soak_guide`** lines at session start (grep **`soak_guide`** in Output).

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")

const PRESET_II2B_SWORD_DUEL := "ii2b"
const PRESET_II3_SURROUND := "ii3"
const PRESET_II4D_EXHAUSTION := "ii4d"
const PRESET_II5_COWERING := "ii5"
const PRESET_II6_AMBIENT_SHOCK := "ii6"
const PRESET_II8_FORMATION := "ii8"

## Suggested F5 order for open **D-001** rows (change **`dev_soak_encounter`** between fights).
const D001_PRESET_RUN_ORDER: PackedStringArray = [
	PRESET_II2B_SWORD_DUEL,
	PRESET_II3_SURROUND,
	PRESET_II5_COWERING,
	PRESET_II6_AMBIENT_SHOCK,
	PRESET_II8_FORMATION,
	PRESET_II4D_EXHAUSTION,
]

## World meta: **`CampaignEncounterBridge.get_fightable_party_nodes`** sends only **`is_party_leader`**.
const WORLD_META_PLAYER_LEADER_ONLY := "soak_player_leader_only"
## Cap fightable roster (leader first, then companions) — **ii6** expects **`party_entering_combat count=2`**.
const WORLD_META_SOAK_PARTY_FIGHTER_CAP := "soak_party_fighter_cap"
## Set when **ii5** destroys leader arms; cleared + restored on non-soak **`clear_world_soak_meta`**.
const WORLD_META_SOAK_LEADER_ARMS_DESTROYED := "soak_leader_arms_destroyed"
## When set, **`CampaignEncounterBridge.refresh_party_formation_meta`** must not replace **`party_formation`**.
const WORLD_META_LOCK_PARTY_FORMATION := "soak_lock_party_formation"
## Stamped on **`WORLD_META_COMBAT_ENCOUNTER`** for F5 grep when entering a cyan soak marker.
const ENCOUNTER_KEY_SOAK_PRESET_ID := "soak_preset_id"

## Written to **`EncounterNode.encounter_config`**; read in **`EncounterNode.spawn_enemies`**.
const ENCOUNTER_KEY_FORCE_WEAPON_ID := "soak_force_weapon_id"


static func apply_preset(encounter: Node, preset_id: String) -> bool:
	if encounter == null:
		return false
	match preset_id:
		PRESET_II2B_SWORD_DUEL:
			_apply_ii2b_sword_duel(encounter)
			return true
		PRESET_II4D_EXHAUSTION:
			_apply_ii4d_exhaustion_duel(encounter)
			return true
		PRESET_II3_SURROUND:
			_apply_ii3_surround(encounter)
			return true
		PRESET_II5_COWERING:
			_apply_ii5_cowering_fall_back(encounter)
			return true
		PRESET_II6_AMBIENT_SHOCK:
			_apply_ii6_ambient_shock(encounter)
			return true
		PRESET_II8_FORMATION:
			_apply_ii8_formation_line(encounter)
			return true
		_:
			return false


## After party setup: preset-specific world state (wounds, **`party_formation`** meta).
static func apply_world_post_setup(world: Node2D, preset_id: String) -> void:
	if world == null or preset_id.is_empty():
		return
	# Cyan→cyan in one F5 session: drop prior preset meta (e.g. **ii5** armless leader before **ii6**).
	clear_world_soak_meta(world)
	match preset_id:
		PRESET_II2B_SWORD_DUEL, PRESET_II4D_EXHAUSTION:
			_apply_ii2b_world(world)
		PRESET_II5_COWERING:
			_apply_ii5_world(world)
		PRESET_II6_AMBIENT_SHOCK:
			_apply_ii6_world(world)
			_wound_companion_for_ambient_shock(world)
		PRESET_II8_FORMATION:
			_apply_ii8_world(world)


static func party_weapon_id_for_preset(preset_id: String) -> String:
	if preset_id == PRESET_II2B_SWORD_DUEL or preset_id == PRESET_II4D_EXHAUSTION:
		return "SWORD"
	return ""


static func is_known_preset(preset_id: String) -> bool:
	var id: String = preset_id.strip_edges().to_lower()
	return id in [
		PRESET_II2B_SWORD_DUEL,
		PRESET_II3_SURROUND,
		PRESET_II4D_EXHAUSTION,
		PRESET_II5_COWERING,
		PRESET_II6_AMBIENT_SHOCK,
		PRESET_II8_FORMATION,
	]


## Editor F5: grep **`soak_guide`** after **`FP_SESSION_BEGIN`** — scenario targets + Output patterns (no separate test scene).
static func emit_f5_soak_guide(preset_id: String, marker_tile: Variant = null) -> void:
	if not OS.has_feature("editor"):
		return
	var id: String = preset_id.strip_edges().to_lower()
	var lines: PackedStringArray = (
		_preset_soak_guide_lines(id, marker_tile)
		if not id.is_empty()
		else _general_soak_guide_lines()
	)
	for line in lines:
		_OperationalLog.play_combat("soak_guide %s" % line)
	_emit_d001_human_blocker_checklist(preset_id)
	_emit_d001_run_order_hint(preset_id)
	if not id.is_empty() and marker_tile == null:
		_OperationalLog.play_combat(
			"soak_guide WARN no cyan marker spawned — re-F5 or free a grid tile; preset world setup still applied"
		)


## Editor F5: log once per combat entry (grep **`soak_fight_enter`**).
static func emit_f5_fight_enter_hint(encounter: Node) -> void:
	if not OS.has_feature("editor") or not _OperationalLog.is_play_session_active():
		return
	var preset: String = ""
	if encounter != null and "soak_preset_id" in encounter:
		preset = str(encounter.soak_preset_id).strip_edges().to_lower()
	if preset.is_empty():
		_F5SoakTrace.set_fight_profile("7v7")
		_F5SoakTrace.prepare_fight_end_log()
		_OperationalLog.play_combat(
			"soak_fight_enter tile=red 7v7 — play until win/medical; end grep soak_fight_end soak_coverage"
		)
		return
	_F5SoakTrace.set_fight_profile(preset)
	_F5SoakTrace.prepare_fight_end_log()
	_OperationalLog.play_combat("soak_fight_enter tile=cyan preset=%s (grep soak=%s on encounter_begin)" % [preset, preset])
	for line in _fight_enter_hint_lines(preset):
		_OperationalLog.play_combat("soak_fight_enter %s" % line)


static func _fight_enter_hint_lines(preset_id: String) -> PackedStringArray:
	match preset_id:
		PRESET_II2B_SWORD_DUEL:
			return PackedStringArray([
				"human II-2b + #1 — 1v1 swords; party_entering_combat count=1",
				"grep parry_deflect|parry_bind|riposte_chain|flurry_bind",
			])
		PRESET_II3_SURROUND:
			return PackedStringArray([
				"human #3 — 4-wide front; grep ui_hint Arc overlap",
			])
		PRESET_II5_COWERING:
			return PackedStringArray([
				"human #5 — pick fall_back when cowering_fall_back listed",
			])
		PRESET_II6_AMBIENT_SHOCK:
			return PackedStringArray([
				"human #6 — count=2; wait 30-60s no hits on Companion; grep ambient_pain_shock Companion",
			])
		PRESET_II8_FORMATION:
			return PackedStringArray([
				"human #8 + II-5c — count=4; grep diagram_banner player: + turn_ready_gauge",
			])
		PRESET_II4D_EXHAUSTION:
			return PackedStringArray([
				"human II-4d — long duel; grep exhaustion crossed 25|50|75; gauge Exh on row",
			])
		_:
			return PackedStringArray()


static func _emit_d001_run_order_hint(active_preset: String) -> void:
	var order_s: String = " → ".join(D001_PRESET_RUN_ORDER)
	if active_preset.is_empty():
		_OperationalLog.play_combat(
			"soak_guide D-001 preset order: %s — then 7v7 red tiles for #4 #7 II-5a/b/c" % order_s
		)
		return
	var idx: int = D001_PRESET_RUN_ORDER.find(active_preset)
	if idx < 0:
		return
	if idx + 1 < D001_PRESET_RUN_ORDER.size():
		_OperationalLog.play_combat(
			"soak_guide D-001 next preset: %s" % D001_PRESET_RUN_ORDER[idx + 1]
		)
	else:
		_OperationalLog.play_combat(
			"soak_guide D-001 presets done — use 7v7 for formation/medical/gauge II-5a/b/c (#4 #7)"
		)


static func _general_soak_guide_lines() -> PackedStringArray:
	return PackedStringArray([
		"POST one fight — copy all Godot Output; grep soak_fight_end | soak_coverage | soak_validate_hint | FP_ERROR | SCRIPT_ERROR",
		"II-0 general — walk any encounter tile (2×7v7 on grid) or set main.tscn dev_soak_encounter=ii2b|ii4d|ii3|ii5|ii6|ii8",
		"grep FP_COMBAT: ui_hint | parry_deflect | parry_bind | parry_partial | riposte_chain | flurry_bind | counter_tempo",
		"grep FP_COMBAT: exhaustion | engagement mode= | engagement ui player: | engagement transition | fled id=",
		"grep FP_COMBAT: cowering_fall_back | ambient_pain_shock | medical | soak= (on encounter_begin when using cyan preset)",
		"grep FP_COMBAT: turn_ready_gauge | gauge_tooltip_formation | diagram_banner player: | medical_action pick",
		"D-008: no crash_success / crash_through in normal play (line crash removed)",
	])


## Human-only **D-001** rows — printed every F5 session (grep **`soak_guide human`**).
static func _emit_d001_human_blocker_checklist(active_preset: String) -> void:
	if not OS.has_feature("editor"):
		return
	var lines: PackedStringArray = PackedStringArray([
		"II-2b feel: cyan ii2b (or 7v7) — bind/deflect timing; III-3 worksheet after",
		"II-5c gauge: grep turn_ready_gauge label=Stm.*Ready.*Exh.*Grd (any player turn)",
		"II-5a tooltip: grep tooltip_match=ok on formation turns (counter/medical/melee_only are OK)",
		"#8 diagram: grep diagram_banner player: (same as engagement ui player:)",
		"#5 fall_back: cyan ii5 — grep cowering_fall_back listed then pick (grep cowering_fall_back pick|executed)",
		"#6 companion shock: cyan ii6 — party_entering_combat count=2; grep ambient_pain_shock Companion",
		"#7 medical: grep medical_pack_wound listed then medical_action pick move=pack_wound",
	])
	if active_preset == PRESET_II4D_EXHAUSTION:
		lines.append("II-4d: this preset — confirm Exh N% on waiting gauge during long duel")
	elif active_preset == PRESET_II8_FORMATION:
		lines.append(
			"#8: this preset — count=4 party_entering_combat; engagement label above party diagram"
		)
	elif active_preset == PRESET_II5_COWERING:
		lines.append("#5: this preset — arms destroyed until red-tile fight clears soak meta")
	elif active_preset == PRESET_II2B_SWORD_DUEL:
		lines.append("#1/II-2b: this preset — walk cyan ii2b label; count=1; bind/deflect feel")
	elif active_preset == PRESET_II3_SURROUND:
		lines.append("#3: this preset — 4 enemies; Arc overlap on front-rank turns")
	elif active_preset == PRESET_II6_AMBIENT_SHOCK:
		lines.append("#6: this preset — soak_setup ii6; do not hit Companion early")
	for line in lines:
		_OperationalLog.play_combat("soak_guide human %s" % line)


static func _preset_soak_guide_lines(preset_id: String, marker_tile: Variant) -> PackedStringArray:
	if not is_known_preset(preset_id):
		return PackedStringArray([
			"unknown preset '%s' — valid: ii2b ii4d ii3 ii5 ii6 ii8" % preset_id,
		])
	var tile_s: String = "walk cyan marker on 3×3 grid"
	if marker_tile is Vector2i:
		tile_s = "cyan marker tile=%s" % str(marker_tile)
	match preset_id:
		PRESET_II2B_SWORD_DUEL:
			var lines_ii2b: PackedStringArray = PackedStringArray([
				"preset=ii2b — II-0 #1 + D-001 II-2b deflect/bind | %s" % tile_s,
				"setup: leader-only 1v1 swords; expect FP_COMBAT engagement mode=Duel on encounter_begin soak=ii2b",
				"grep: parry_deflect | parry_bind | parry_partial | riposte_chain | flurry_bind | counter_tempo",
				"play: exchange until bind/deflect; riposte after deflect; flurry after bind if window opens",
			])
			if _CombatConstants.combat_dev_verbose_active():
				lines_ii2b.append(
					"Q1 research_feel ON — grep research_feel | research_validate_hint; crosswalk docs/LIVE_PATHS.md#enable-per-hit-research_feel-lines"
				)
			else:
				lines_ii2b.append(
					"Q1 optional: main dev_research_feel=true then re-F5; grep research_feel (pen_mm ke_frac cut/blunt/bone)"
				)
			lines_ii2b.append(
				"Q2 feel: exchange until bind+deflect; riposte after deflect; flurry after bind — grep parry_stats deflect= q2_validate_hint at fight end"
			)
			lines_ii2b.append("Q2 headless: .\\scripts\\run_q_audit.ps1 -Track Q2 after run_all_combat_checks")
			return lines_ii2b
		PRESET_II4D_EXHAUSTION:
			return PackedStringArray([
				"preset=ii4d — II-4d stamina/exhaustion (3–5 min duel) | %s" % tile_s,
				"setup: same as ii2b; soak=ii4d on encounter_begin",
				"grep: exhaustion crossed 25|50|75 | engagement mode= | parry_* during long fight",
				"on-screen: waiting gauge Stm N% · Ready · Exh N% · Grd",
				"Q3 headless: [ii4d] exhaustion_* PASS — F5 optional 3–5 min pacing (q3_validate_hint)",
			])
		PRESET_II3_SURROUND:
			return PackedStringArray([
				"preset=ii3 — II-0 #3 multi-threat surround | %s" % tile_s,
				"setup: 4-wide enemy front; surround arc occupancy on",
				"grep: ui_hint Arc overlap | parry_* under 2+ front threats | surround_threat in [Combat.Flow] if COMBAT_EVENT_DEBUG_VERBOSE",
			])
		PRESET_II5_COWERING:
			return PackedStringArray([
				"preset=ii5 — II-0 #5 cowering → fall_back | %s" % tile_s,
				"setup: leader armless (cowering); loose 2×3 party formation",
				"grep: cowering_fall_back listed | cowering_fall_back executed | ui_hint No arms",
				"play: on your turn pick fall_back when listed (not flee-only path)",
				"Q3 headless: .\\scripts\\run_q_audit.ps1 -Track Track — [ii5] cowering_* PASS in .d001_soak_out.txt",
				"Q3 F5 only: confirm fall_back pick UX on world grid (grep q3_validate_hint at fight end)",
			])
		PRESET_II6_AMBIENT_SHOCK:
			return PackedStringArray([
				"preset=ii6 — II-0 #6 ambient pain shock | %s" % tile_s,
				"setup: companion chest wounded pre-fight; 1 enemy",
				"grep: ambient_pain_shock | avoid new hits on companion — wait several combat ticks",
				"note: shock rolls on sustained pain, not every hit",
			])
		PRESET_II8_FORMATION:
			return PackedStringArray([
				"preset=ii8 — II-0 #8 skirmish vs LINE labels | %s" % tile_s,
				"setup: 4 fightable party + 4-wide line + 4 enemies (grep party_entering_combat count=4)",
				"grep: engagement mode=Formation line | engagement ui player: | engagement transition",
				"on-screen: centered label above party diagram (Formation line · Line · cohesion) — ZoC line below title is separate",
				"Q4 headless: [ii8] diagram_banner + tooltip_match_ok PASS — F5 optional layout glance (q4_validate_hint)",
			])
		_:
			return PackedStringArray()


static func _tag_encounter(encounter: Node, preset_id: String) -> void:
	if "soak_preset_id" in encounter:
		encounter.soak_preset_id = preset_id


static func clear_world_soak_meta(world: Node2D) -> void:
	if world == null:
		return
	if (
		world.has_meta(WORLD_META_SOAK_LEADER_ARMS_DESTROYED)
		and bool(world.get_meta(WORLD_META_SOAK_LEADER_ARMS_DESTROYED))
	):
		_restore_leader_arms(world)
	if world.has_meta(WORLD_META_SOAK_LEADER_ARMS_DESTROYED):
		world.remove_meta(WORLD_META_SOAK_LEADER_ARMS_DESTROYED)
	if world.has_meta(WORLD_META_PLAYER_LEADER_ONLY):
		world.remove_meta(WORLD_META_PLAYER_LEADER_ONLY)
	if world.has_meta(WORLD_META_SOAK_PARTY_FIGHTER_CAP):
		world.remove_meta(WORLD_META_SOAK_PARTY_FIGHTER_CAP)
	if world.has_meta(WORLD_META_LOCK_PARTY_FORMATION):
		world.remove_meta(WORLD_META_LOCK_PARTY_FORMATION)


static func _lock_party_formation_on_world(world: Node2D, preset: Dictionary) -> void:
	world.set_meta("party_formation", preset)
	world.set_meta(WORLD_META_LOCK_PARTY_FORMATION, true)


static func _apply_ii2b_world(world: Node2D) -> void:
	world.set_meta(WORLD_META_PLAYER_LEADER_ONLY, true)
	_lock_party_formation_on_world(
		world,
		{"files": 1, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
	)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat(
			"soak_setup ii2b leader-only 1x1 party (grep party_entering_combat count=1)"
		)


static func _apply_ii4d_exhaustion_duel(encounter: Node) -> void:
	_apply_ii2b_sword_duel(encounter)
	_tag_encounter(encounter, PRESET_II4D_EXHAUSTION)


static func _apply_ii2b_sword_duel(encounter: Node) -> void:
	_tag_encounter(encounter, PRESET_II2B_SWORD_DUEL)
	encounter.enemy_count = 1
	encounter.enemy_formation = {"files": 1, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
	var cfg: Dictionary = encounter.encounter_config.duplicate(true)
	cfg[ENCOUNTER_KEY_FORCE_WEAPON_ID] = "SWORD"
	encounter.encounter_config = cfg


static func _apply_ii3_surround(encounter: Node) -> void:
	_tag_encounter(encounter, PRESET_II3_SURROUND)
	encounter.enemy_count = 4
	encounter.enemy_formation = FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)


static func _apply_ii5_cowering_fall_back(encounter: Node) -> void:
	_tag_encounter(encounter, PRESET_II5_COWERING)
	encounter.enemy_count = 2
	encounter.enemy_formation = {"files": 2, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}


static func _apply_ii6_ambient_shock(encounter: Node) -> void:
	_tag_encounter(encounter, PRESET_II6_AMBIENT_SHOCK)
	encounter.enemy_count = 1
	encounter.enemy_formation = {"files": 1, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}


static func _apply_ii8_formation_line(encounter: Node) -> void:
	_tag_encounter(encounter, PRESET_II8_FORMATION)
	encounter.enemy_count = 4
	encounter.enemy_formation = FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)


static func _apply_ii5_world(world: Node2D) -> void:
	_lock_party_formation_on_world(
		world,
		{
			"files": 2,
			"ranks": 3,
			"density": FormationPreset.DENSITY_NORMAL,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
		}
	)
	_destroy_arms_on_character(world, "Character")
	world.set_meta(WORLD_META_SOAK_LEADER_ARMS_DESTROYED, true)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat(
			"soak_setup ii5 leader armless + loose 2x3 (grep cowering_fall_back listed|executed)"
		)


static func _apply_ii8_world(world: Node2D) -> void:
	world.set_meta(WORLD_META_SOAK_PARTY_FIGHTER_CAP, 4)
	_lock_party_formation_on_world(
		world,
		FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)
	)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat(
			"soak_setup ii8 locked 4-wide line cap=4 fighters (grep party_entering_combat count=4)"
		)


static func _apply_ii6_world(world: Node2D) -> void:
	world.set_meta(WORLD_META_SOAK_PARTY_FIGHTER_CAP, 2)
	_lock_party_formation_on_world(
		world,
		{"files": 2, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
	)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat(
			"soak_setup ii6 cap=2 party (grep party_entering_combat count=2)"
		)


static func _restore_leader_arms(world: Node2D) -> void:
	if world == null or not world.has_node("Character/CombatBody"):
		return
	var ent: CoreEntity = world.get_node("Character/CombatBody") as CoreEntity
	if ent == null:
		return
	if ent.has_method("apply_species"):
		ent.apply_species()


static func _destroy_arms_on_character(world: Node2D, character_path: String) -> void:
	if not world.has_node(character_path):
		return
	var character: Node = world.get_node(character_path)
	if not character.has_node("CombatBody"):
		return
	var ent: CoreEntity = character.get_node("CombatBody") as CoreEntity
	if ent == null:
		return
	_destroy_limb_for_soak(ent, "right_arm")
	_destroy_limb_for_soak(ent, "left_arm")


static func _destroy_limb_for_soak(entity: CoreEntity, part: String) -> void:
	if entity == null or part.is_empty():
		return
	entity.body_cutting[part] = 0.0
	entity.body_blunt[part] = 0.0
	if entity.bone_health.has(part):
		entity.bone_health[part] = 0.0


static func _wound_companion_for_ambient_shock(world: Node2D) -> void:
	if not world.has_node("Character/Companion"):
		return
	var companion: Node = world.get_node("Character/Companion")
	if not companion.has_node("CombatBody"):
		return
	var ent: CoreEntity = companion.get_node("CombatBody") as CoreEntity
	if ent == null:
		return
	ent.take_damage_split(22.0, 22.0, "chest")
	ent.blood_volume = 58.0
	ent._pain_shock_until_time = -1.0
	ent._ambient_pain_shock_accum = 0.0
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat(
			"soak_setup ii6 companion chest wounded bv=%.0f (grep ambient_pain_shock on Companion)"
			% ent.blood_volume
		)
