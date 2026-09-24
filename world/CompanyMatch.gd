class_name CompanyMatch
extends RefCounted

## XCamp-6 (gladiatorial school system): the school-match orchestrator.
##
## Design (locked):
##   - Pairing is preset-order 1v1s when the match is fought: bout i pairs your lineup[i]
##     against the school's dossier lineup[i]. No mid-fight swaps.
##   - Each fighter fights exactly once; a losing fighter is downed (not killed) and gets the
##     normal medical/field-care pipeline after combat (the battle sim already ends at
##     incapacitation, so this needs no extra death handling).
##   - The match is decided by the count of bout wins; ties draw.
##   - The player's levers are the appointed lineup order + which weapons/forms/stats they
##     trained, informed by scouting reports (see CompanyScout / CompanySchool).
##
## This module is the pure state machine (appoint -> per-bout record -> outcome) plus the
## single-fighter combat-entry scaffolding. The live BattleScene wiring (each bout entered via
## the normal encounter path restricted to one player) is a follow-up slice.

## When set on the world (member name), CampaignEncounterBridge.get_fightable_party_nodes
## returns only that living member -- so a match bout fights 1v1 instead of the whole party.
const WORLD_META_MATCH_SINGLE_FIGHTER: String = "match_single_fighter"

## Arena-day scheduling (XCamp-6 gladiator-completion slice): the match block gains an optional
## "match_day" when the player schedules fights for a future day. -1 (no key) keeps the legacy
## XCamp-6 behaviour of "bouts open as soon as the match is appointed", which the school harness
## exercises -- so all existing checks pass unchanged.
const NO_MATCH_DAY: int = -1

const MATCH_STATE_APPOINTED: String = "appointed"
const MATCH_STATE_COMPLETED: String = "completed"

const OUTCOME_VICTORY: String = "victory"
const OUTCOME_DRAW: String = "draw"
const OUTCOME_DEFEAT: String = "defeat"


## === Active-match block (shared home is CompanySchool) ===


static func active_match(world: Node) -> Dictionary:
	if world == null:
		return {}
	var raw: Variant = CompanySchool.get_school_state(world).get("active_match", {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


static func has_active_match(world: Node) -> bool:
	return not active_match(world).is_empty()


static func set_active_match(world: Node, match_state: Dictionary) -> void:
	if world == null:
		return
	var state: Dictionary = CompanySchool.get_school_state(world)
	state["active_match"] = match_state.duplicate(true)
	CompanySchool.set_school_state(world, state)


static func clear_active_match(world: Node) -> void:
	if world == null:
		return
	var state: Dictionary = CompanySchool.get_school_state(world)
	state["active_match"] = {}
	CompanySchool.set_school_state(world, state)


static func match_school_id(world: Node) -> String:
	return str(active_match(world).get("school_id", ""))


## Release the 1v1 bout lock (used when a bout entry/spawn is rolled back so the next appointment
## is not wrongly restricted).
static func remove_single_fighter_lock(world: Node) -> void:
	if world != null and world.has_meta(WORLD_META_MATCH_SINGLE_FIGHTER):
		world.remove_meta(WORLD_META_MATCH_SINGLE_FIGHTER)


static func match_bout_count(world: Node) -> int:
	return int(active_match(world).get("lineup", []).size())


## The day the match is scheduled to be fought on. Returns NO_MATCH_DAY (-1) when the match was
## appointed without a schedule (legacy XCamp-6 behaviour: bouts open immediately), or when no
## match is active.
static func match_day(world: Node) -> int:
	return int(active_match(world).get("match_day", NO_MATCH_DAY))


static func match_score(world: Node) -> Dictionary:
	var m: Dictionary = active_match(world)
	return {
		"player_wins": int(m.get("player_wins", 0)),
		"opponent_wins": int(m.get("opponent_wins", 0)),
		"bout_index": int(m.get("bout_index", 0)),
		"total_bouts": match_bout_count(world),
	}


static func current_bout_index(world: Node) -> int:
	return int(active_match(world).get("bout_index", 0))


static func current_bout_player_name(world: Node) -> String:
	var lineup: Array = active_match(world).get("lineup", [])
	var idx: int = current_bout_index(world)
	if idx < 0 or idx >= lineup.size():
		return ""
	return str(lineup[idx])


## The school fighter the current bout pairs against (scouted dossier order).
static func current_bout_opponent(world: Node) -> OpponentFighterProfile:
	var dossier: Array = CompanySchool.dossier_for(world, match_school_id(world))
	var idx: int = current_bout_index(world)
	if idx < 0 or idx >= dossier.size():
		return null
	var p: Variant = dossier[idx]
	return p as OpponentFighterProfile if p is OpponentFighterProfile else null


## The pre-bout "card" the UI / battle-scene wiring needs: who is fighting, who they face, and
## (respecting reveal tiers) what the player may know. Never errors on an invalid state.
## Intel is redacted: weapon only once scouted, form/tendency only at full reveal, and counter
## recommendations only once the fighter is scouted enough to warrant them.
static func current_bout_card(world: Node) -> Dictionary:
	var gate: Dictionary = can_enter_current_bout(world)
	var card: Dictionary = {
		"ok": bool(gate.get("ok", false)),
		"reason": str(gate.get("reason", "")),
		"bout_index": current_bout_index(world),
		"total_bouts": match_bout_count(world),
		"player_name": current_bout_player_name(world),
		"opponent_name": "",
		"opponent_weapon_id": "",
		"opponent_form_id": "",
		"opponent_reveal": OpponentFighterProfile.REVEAL_UNKNOWN,
		"opponent_tendency_visible": false,
		"counter_recommendations": {},
		"school_id": match_school_id(world),
		"school_display_name": CompanySchool.school_display_name(match_school_id(world)),
	}
	if not bool(gate.get("ok", false)):
		return card
	var profile: OpponentFighterProfile = current_bout_opponent(world)
	if profile == null:
		return card
	card["opponent_name"] = profile.display_name
	card["opponent_reveal"] = profile.reveal
	if profile.has_weapon_reveal():
		card["opponent_weapon_id"] = profile.weapon_id
	if profile.has_full_reveal():
		card["opponent_form_id"] = profile.form_id
		card["opponent_tendency_visible"] = true
	if CombatCounter.is_scouted_enough(profile):
		card["counter_recommendations"] = CombatCounter.recommendations(profile)
	return card


## === Appointing ===


## Can the company appoint `member_names` (order = fight order) to fight `school_id`?
## {ok, reason}. Validates a non-empty, duplicate-free, living, not-away lineup sized to the
## school's roster, with no match already active.
static func can_appoint_match(world: Node, school_id: String, member_names: Array) -> Dictionary:
	if world == null:
		return {"ok": false, "reason": "no world"}
	if has_active_match(world):
		return {"ok": false, "reason": "a school match is already underway"}
	if not CompanySchool.has_school(school_id):
		return {"ok": false, "reason": "unknown school '%s'" % school_id}
	if member_names.is_empty():
		return {"ok": false, "reason": "appoint at least one fighter"}
	var max_n: int = CompanySchool.school_lineup_size(school_id)
	if member_names.size() > max_n:
		var over_field: String = (
			"%s fields %d fighters (appointed %d)"
			% [CompanySchool.school_display_name(school_id), max_n, member_names.size()]
		)
		return {"ok": false, "reason": over_field}
	var seen: Dictionary = {}
	for entry in member_names:
		var name_s: String = str(entry)
		if seen.has(name_s):
			return {"ok": false, "reason": "'%s' appointed twice" % name_s}
		seen[name_s] = true
		var member: Node = CompanyScout._resolve_member_node_by_name(world, name_s)
		if member == null:
			return {"ok": false, "reason": "no party member '%s'" % name_s}
		if member.has_method("is_dead") and member.is_dead():
			return {"ok": false, "reason": "%s is dead and cannot fight" % name_s}
		if CompanyScout.member_is_scouting(world, name_s):
			return {"ok": false, "reason": "%s is away scouting" % name_s}
	return {"ok": true, "reason": ""}


## Appoints the lineup and snapshots the match. Returns true on success.
## `match_day` (-1 by default) schedules the match for a future arena day: bouts stay locked until
## that day arrives. -1 keeps the legacy open-immediately behaviour (school harness path).
static func appoint_match(world: Node, school_id: String, member_names: Array, match_day: int = -1) -> bool:
	if not can_appoint_match(world, school_id, member_names).get("ok", false):
		return false
	var lineup: Array = []
	for entry in member_names:
		lineup.append(str(entry))
	var block: Dictionary = {
		"school_id": school_id,
		"lineup": lineup,
		"bout_index": 0,
		"player_wins": 0,
		"opponent_wins": 0,
		"state": MATCH_STATE_APPOINTED,
	}
	if match_day >= 0:
		block["match_day"] = match_day
	set_active_match(world, block)
	if OperationalLog.is_play_session_active():
		OperationalLog.play_world(
			(
				"match_appointed school=%s fighters=%d lineup=[%s]"
				% [CompanySchool.school_display_name(school_id), lineup.size(), ", ".join(lineup)]
			)
		)
	return true


static func cancel_active_match(world: Node) -> bool:
	if not has_active_match(world):
		return false
	clear_active_match(world)
	# Abandoning must also release any single-fighter bout lock set for the live fight.
	if world.has_meta(WORLD_META_MATCH_SINGLE_FIGHTER):
		world.remove_meta(WORLD_META_MATCH_SINGLE_FIGHTER)
	if OperationalLog.is_play_session_active():
		OperationalLog.play_world("match_cancelled")
	return true


## === Bout entry ===


## Can the current bout actually be entered (match active, bout open, fighter available)?
static func can_enter_current_bout(world: Node) -> Dictionary:
	if not has_active_match(world):
		return {"ok": false, "reason": "no match appointed"}
	var idx: int = current_bout_index(world)
	if idx >= match_bout_count(world):
		return {"ok": false, "reason": "no bout open"}
	## Arena-day gate: a scheduled match keeps its bouts locked until the arena day arrives.
	var arena_day: int = match_day(world)
	if arena_day >= 0 and CompanyState.get_day_index(world) < arena_day:
		return {
			"ok": false,
			"reason": "arena day is day %d (today is day %d)" % [arena_day, CompanyState.get_day_index(world)],
			"arena_day": arena_day,
		}
	var player: String = current_bout_player_name(world)
	var member: Node = CompanyScout._resolve_member_node_by_name(world, player)
	if member == null:
		return {"ok": false, "reason": "no party member '%s'" % player}
	if member.has_method("is_dead") and member.is_dead():
		return {"ok": false, "reason": "%s is dead" % player}
	if CompanyScout.member_is_scouting(world, player):
		return {"ok": false, "reason": "%s is away scouting" % player}
	if current_bout_opponent(world) == null:
		return {"ok": false, "reason": "no scouted opponent for bout %d" % idx}
	return {
		"ok": true,
		"reason": "",
		"player_name": player,
		"bout_index": idx,
		"total_bouts": match_bout_count(world),
	}


## Marks that the current bout is about to be fought: restricts the fight to the single
## appointed fighter (CampaignEncounterBridge / CombatFlow read WORLD_META_MATCH_SINGLE_FIGHTER).
## Cleared again by record_bout_outcome(). Returns true when the bout can start.
static func begin_current_bout(world: Node) -> bool:
	if not can_enter_current_bout(world).get("ok", false):
		return false
	world.set_meta(WORLD_META_MATCH_SINGLE_FIGHTER, current_bout_player_name(world))
	return true


## Build the EncounterNode that spawns exactly the current bout's profile as ONE enemy
## (forced weapon, human species). Caller adds it to the world and runs the normal
## begin_contract_encounter path. Carries the profile + school id in encounter config for the
## combat-side tendency hook.
static func build_current_bout_encounter(world: Node, enemy_scene: PackedScene = null) -> EncounterNode:
	var enc := EncounterNode.new()
	var profile: OpponentFighterProfile = current_bout_opponent(world)
	enc.enemy_count = 1
	enc.encounter_config = {}
	var sid: String = match_school_id(world)
	if has_active_match(world) and not sid.is_empty():
		enc.marker_kind = "contract"
		enc.contract_marker_label = (
			"%s bout %d/%d"
			% [
				CompanySchool.school_display_name(sid),
				current_bout_index(world) + 1,
				match_bout_count(world),
			]
		)
	if enemy_scene != null:
		enc.enemy_scene = enemy_scene
	if profile != null:
		if not profile.weapon_id.is_empty():
			enc.encounter_config[SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID] = profile.weapon_id
		enc.encounter_config[CompanySchool.ENCOUNTER_KEY_SCHOOL_FIGHTER_PROFILE] = profile.to_dict()
		enc.encounter_config[CompanySchool.ENCOUNTER_KEY_SCHOOL_ID] = sid
	# School bouts always field the school's own humans; never a random goblin draw.
	enc.encounter_config["enemy_species_pool"] = [ResourcePaths.HUMAN_SPECIES]
	return enc


## Stamp a spawned enemy scene node with the bout profile: forced weapon, form stance, base
## stats, and the hidden tendency (node meta for the combat-side hook). Call after
## spawn_enemies, before CombatFlow.start_combat.
static func stamp_bout_enemy(enemy: Node, profile: OpponentFighterProfile) -> void:
	if enemy == null or profile == null:
		return
	if not profile.weapon_id.is_empty():
		EncounterSpawner.equip_weapon_id(enemy, profile.weapon_id)
	if "stance_preference" in enemy:
		enemy.set("stance_preference", profile.form_id)
	enemy.set_meta("school_profile_id", profile.fighter_id)
	enemy.set_meta("school_tendency", profile.tendency.duplicate(true))
	var ent: Node = CampaignEncounterBridge.health_entity_from_character(enemy)
	if ent == null:
		return
	for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
		if profile.stats.has(stat) and stat in ent:
			ent.set(stat, int(profile.stats[stat]))


## === Bout outcome ===


## Records the result of the current bout and advances the match. Returns
## {finished, outcome ("" when unfinished), player_wins, opponent_wins, total_bouts}.
## finished=true when the last bout is decided.
static func record_bout_outcome(world: Node, player_won: bool) -> Dictionary:
	var m: Dictionary = active_match(world)
	if m.is_empty():
		return {"finished": false, "outcome": "", "player_wins": 0, "opponent_wins": 0, "total_bouts": 0}
	if int(m.get("bout_index", 0)) >= int(m.get("lineup", []).size()):
		# A late extra record on a finished match must not leave a stale single-fighter lock.
		if world.has_meta(WORLD_META_MATCH_SINGLE_FIGHTER):
			world.remove_meta(WORLD_META_MATCH_SINGLE_FIGHTER)
		return {
			"finished": true,
			"outcome": compute_outcome(m),
			"player_wins": int(m.get("player_wins", 0)),
			"opponent_wins": int(m.get("opponent_wins", 0)),
			"total_bouts": int(m.get("lineup", []).size()),
		}
	if player_won:
		m["player_wins"] = int(m.get("player_wins", 0)) + 1
	else:
		m["opponent_wins"] = int(m.get("opponent_wins", 0)) + 1
	m["bout_index"] = int(m.get("bout_index", 0)) + 1
	var finished: bool = int(m["bout_index"]) >= int(m.get("lineup", []).size())
	if finished:
		m["state"] = MATCH_STATE_COMPLETED
	set_active_match(world, m)
	# Any single-fighter bout filter is cleared once the bout is recorded (combat already ended).
	if world.has_meta(WORLD_META_MATCH_SINGLE_FIGHTER):
		world.remove_meta(WORLD_META_MATCH_SINGLE_FIGHTER)
	var score: Dictionary = match_score(world)
	var bout_no: int = maxi(0, int(score.get("bout_index", 0)) - 1)
	var score_detail: String = (
		"match_bout bout=%d player_won=%s score=%.0f-%.0f"
		% [bout_no, str(player_won), score.get("player_wins"), score.get("opponent_wins")]
	)
	if OperationalLog.is_play_session_active():
		OperationalLog.play_world(score_detail)
	return {
		"finished": finished,
		"outcome": compute_outcome(m) if finished else "",
		"player_wins": int(score.get("player_wins", 0)),
		"opponent_wins": int(score.get("opponent_wins", 0)),
		"total_bouts": int(score.get("total_bouts", 0)),
	}


## The match verdict from a (final) match block.
static func compute_outcome(m: Dictionary) -> String:
	var pw: int = int(m.get("player_wins", 0))
	var ow: int = int(m.get("opponent_wins", 0))
	if pw > ow:
		return OUTCOME_VICTORY
	if pw == ow:
		return OUTCOME_DRAW
	return OUTCOME_DEFEAT


## Final result once the match is completed; {} while it is still being fought.
static func match_result(world: Node) -> Dictionary:
	var m: Dictionary = active_match(world)
	if m.is_empty() or str(m.get("state", "")) != MATCH_STATE_COMPLETED:
		return {}
	return {
		"school_id": str(m.get("school_id", "")),
		"outcome": compute_outcome(m),
		"player_wins": int(m.get("player_wins", 0)),
		"opponent_wins": int(m.get("opponent_wins", 0)),
		"total_bouts": int(m.get("lineup", []).size()),
	}


## Returns the final result AND clears the match block + single-fighter lock so the company
## can appoint/scout again right away. {} (and no clear) while the match is still live;
## use cancel_active_match() to abandon a running match instead.
static func collect_match_result(world: Node) -> Dictionary:
	var result: Dictionary = match_result(world)
	if result.is_empty():
		return {}
	clear_active_match(world)
	if world.has_meta(WORLD_META_MATCH_SINGLE_FIGHTER):
		world.remove_meta(WORLD_META_MATCH_SINGLE_FIGHTER)
	return result