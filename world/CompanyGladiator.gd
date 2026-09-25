class_name CompanyGladiator
extends RefCounted

## XCamp-6 (gladiatorial school system): "school-day" operations for the gladiator management
## screen -- arena-day scheduling, live bout entry, bout-end resolution, and match rewards.
##
## This is glue over the company + XCamp-6 modules (CompanyState faces CompanySchool / CompanyScout /
## CompanyMatch); it owns no state of its own. The school-state block in CompanySchool stays the
## single home for dossiers / scouts / the active match.
##
## Live bout pipeline (was the CompanyMatch "follow-up slice"):
##   enter_current_bout()  -> begin_current_bout (single-fighter lock)
##                         -> build_current_bout_encounter + begin_contract_encounter (spawn)
##                         -> stamp_bout_enemy
##   scene awaits CombatFlow.start_combat, then battle_ended -> CompanyGladiator.finalize_bout()
##   finalize_bout()       -> +1 day-independent settlement: victory pay / loss recovery, record_bout_outcome
##                         -> collect_match_result + match_victory reward when the match is decided.

# Runtime preload -- CompanyState preloads a large module graph, so this stays lazy like CompanyCamp.
static var _state_cache: Variant = null

## Match-ticket economy (winner-take-all per bout, then a showcase bonus for the overall win).
## Calibrated below contract pay (~150-300g) so arena nights are a viable but not overwhelming income
## source; a hard win at The Iron Pit (~prestige 3) pays 60+100 = 160g, roughly one contract.
const BOUT_PURSE_BASE: int = 40
const BOUT_PURSE_PER_PRESTIGE: int = 20
const MATCH_WIN_GOLD_BASE: int = 60
const MATCH_WIN_GOLD_PER_PRESTIGE: int = 30
const MATCH_WIN_RENOWN: int = 1
const MATCH_WIN_MED_RESUPPLY: int = 3


static func _get_state() -> GDScript:
	if _state_cache == null:
		_state_cache = load("res://world/CompanyState.gd")
	return _state_cache


## === Bout finance ===


## Winner-take-all purse for one bout at the active match's school.
static func bout_win_purse(world: Node) -> int:
	var school_id: String = CompanyState.match_school_id(world)
	return BOUT_PURSE_BASE + CompanySchool.school_prestige(school_id) * BOUT_PURSE_PER_PRESTIGE


## Gold a match-losing school still has to pay: a draw steps down to the base purse, a loss pays
## nothing extra (the downed fighter recovers at camp).
static func match_loss_purse(_world: Node) -> int:
	return 0


## === Scheduling ===


## Can `member_names` be appointed to fight `school_id` on arena day `match_day`?
## {ok, reason}. Builds on CompanyMatch.can_appoint_match and validates the chosen day.
static func can_schedule_match(world: Node, school_id: String, member_names: Array, match_day: int) -> Dictionary:
	var gate: Dictionary = CompanyState.can_appoint_match(world, school_id, member_names)
	if not gate.get("ok", false):
		return gate
	if match_day < 0:
		return {"ok": false, "reason": "pick an arena day first"}
	var today: int = CompanyState.get_day_index(world)
	if match_day < today:
		return {"ok": false, "reason": "day %d is already past (today is day %d)" % [match_day, today]}
	return {"ok": true, "reason": ""}


## Appoints the lineup and schedules the match for `match_day`. Returns true on success.
static func schedule_match(world: Node, school_id: String, member_names: Array, match_day: int) -> bool:
	if not can_schedule_match(world, school_id, member_names, match_day).get("ok", false):
		return false
	return CompanyMatch.appoint_match(world, school_id, member_names, match_day)


## === Live bout entry ===


## Everything the school screen needs to decide whether the current bout can be entered today.
static func bout_entry_gate(world: Node) -> Dictionary:
	var gate: Dictionary = CompanyState.can_enter_current_bout(world)
	gate["arena_day"] = CompanyMatch.match_day(world)
	gate["today"] = CompanyState.get_day_index(world)
	gate["card"] = CompanyState.current_bout_card(world)
	return gate


## Starts the current bout: locks the fight to the single appointed fighter, builds the EncounterNode,
## spawns the school's fighter, stamps the bout profile, and hands the enemies to the caller to start
## combat. Returns the spawned enemy array (empty when entry was gated or spawn rolled back --
## CompanyMatch.begin_current_bout etc. already cleaned up in that case).
static func enter_current_bout(world: Node2D) -> Array:
	if world == null:
		return []
	if not CompanyMatch.begin_current_bout(world):
		return []
	var enemy_scene: PackedScene = CampaignEncounterBridge.resolve_enemy_scene(world)
	var encounter: EncounterNode = CompanyMatch.build_current_bout_encounter(world, enemy_scene)
	world.add_child(encounter)
	var rng: RandomNumberGenerator = CampaignEncounterBridge.resolve_overworld_rng(world)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var enemies: Array = CampaignEncounterBridge.begin_contract_encounter(world, encounter, rng)
	if enemies.is_empty():
		CompanyMatch.remove_single_fighter_lock(world)
		return []
	var profile: OpponentFighterProfile = CompanyState.current_bout_opponent(world)
	if profile != null and not enemies.is_empty():
		CompanyMatch.stamp_bout_enemy(enemies[0] as Node, profile)
	return enemies


## === Bout end ===


## Resolves a finished bout and advances the match. Call from the school scene's _on_battle_ended.
## Winner is the battle sim side ("player"/"enemy"). Returns a UI-facing result dict:
##   {ok, player_won, purse, sponsor_gold, renown_gained, promotions,
##    bout:{finished,outcome,player_wins,opponent_wins,total_bouts},
##    match:{...} (final result when the last bout was decided),
##    match_reward:{gold,renown,med} (overall-match bonus when won)}
static func finalize_bout(world: Node2D, winner: String) -> Dictionary:
	var out: Dictionary = {"ok": false, "player_won": false}
	if world == null:
		return out
	var player_won: bool = winner == CombatConstantsMisc.SIDE_PLAYER
	out["player_won"] = player_won
	var player_node: Node = CampaignEncounterBridge.get_player(world)
	if player_won:
		BattleEndHandler.handle_victory(world, player_node as Node2D, winner)
		CampaignEncounterBridge.on_return_from_combat(world, winner)
		var purse: int = bout_win_purse(world)
		_get_state().add_gold(world, purse)
		_get_state().set_renown(world, _get_state().get_renown(world) + 1)
		# Per-fighter fame (difficulty-scaled) + sponsor gold for qualifying survivors.
		var sponsor_gold: int = CompanyRoster.award_fame_for_victory(world)
		_get_state().add_gold(world, sponsor_gold)
		out["purse"] = purse
		out["sponsor_gold"] = sponsor_gold
		out["renown_gained"] = 1
		out["promotions"] = (
			world.get_meta(CampaignTypes.WORLD_META_LAST_FAME_PROMOTIONS, PackedStringArray())
			if world.has_meta(CampaignTypes.WORLD_META_LAST_FAME_PROMOTIONS)
			else PackedStringArray()
		)
	else:
		# A losing bout downs the fighter (the sim ends at incapacitation, never death); the loser
		# recovers through the normal medical/field-care pipeline at camp. Never ends the run.
		BattleEndHandler.restore_overworld_party(world, player_node, true)
		_get_state().apply_battle_lost_mood(world)
		CampaignEncounterBridge.build_last_battle_summary(world, winner)
		CampaignEncounterBridge.on_return_from_combat(world, winner)
	# Fatigue + weapon wear + fight-day tracking apply to the roster either way (same as a contract).
	CombatFlow._apply_last_fought_day_to_roster(world)
	CombatFlow._apply_battle_fatigue_to_roster(world)
	CombatFlow._apply_battle_weapon_wear_to_roster(world)
	out["bout"] = CompanyMatch.record_bout_outcome(world, player_won)
	if bool(out["bout"].get("finished", false)):
		var result: Dictionary = CompanyMatch.collect_match_result(world)
		out["match"] = result
		out["match_reward"] = {}
		if str(result.get("outcome", "")) == CompanyMatch.OUTCOME_VICTORY:
			out["match_reward"] = apply_match_victory_reward(world, result)
	_get_state().refresh_hud(world)
	out["ok"] = true
	return out


## The overall-match showcase bonus for winning the school match (on top of per-bout purses).
## Returns the {gold, renown, med} actually granted.
static func apply_match_victory_reward(world: Node, result: Dictionary) -> Dictionary:
	if world == null:
		return {}
	var prestige: int = CompanySchool.school_prestige(str(result.get("school_id", "")))
	var gold: int = MATCH_WIN_GOLD_BASE + prestige * MATCH_WIN_GOLD_PER_PRESTIGE
	_get_state().add_gold(world, gold)
	_get_state().set_renown(world, _get_state().get_renown(world) + MATCH_WIN_RENOWN)
	_get_state().set_medical_supplies(
		world, _get_state().get_medical_supplies(world) + MATCH_WIN_MED_RESUPPLY
	)
	if OperationalLog.is_play_session_active():
		OperationalLog.play_world(
			(
				"match_victory %s gold=%d renown=%d med_resupply=%d gold_left=%d"
				% [
					CompanySchool.school_display_name(str(result.get("school_id", ""))),
					gold,
					MATCH_WIN_RENOWN,
					MATCH_WIN_MED_RESUPPLY,
					_get_state().get_gold(world),
				]
			)
		)
	return {"gold": gold, "renown": MATCH_WIN_RENOWN, "med": MATCH_WIN_MED_RESUPPLY}


## === Rest / day management ===


## Rest the company (school screen equivalent of the camp tile):
##   - When the camp rest gate is met (dressed wounds + 1 med), a full camp rest: heal + merge queued
##     drills + sharpen + mood + rest quality, which also advances the day (CompanyCamp.try_camp_heal).
##   - Otherwise an "end day": wages, provisions, daily fatigue, scout returns, autosave
##     (CompanyDayCycle.try_advance_day), so queued drills stay pending until a med-funded rest.
## Returns {ok, kind: "camp_rest"|"end_day", day, rested, med}.
static func rest_day(world: Node2D) -> Dictionary:
	var out: Dictionary = {"ok": false, "kind": "", "day": -1, "rested": false}
	if world == null:
		return out
	if CompanyState.camp_heal_ready(world, true):
		out["rested"] = CompanyState.try_camp_heal(world, true)
		out["kind"] = "camp_rest"
	else:
		out["rested"] = false
		out["kind"] = "end_day"
		CompanyState.try_advance_day(world)
	out["ok"] = true
	out["day"] = CompanyState.get_day_index(world)
	out["med"] = _get_state().get_medical_supplies(world)
	return out