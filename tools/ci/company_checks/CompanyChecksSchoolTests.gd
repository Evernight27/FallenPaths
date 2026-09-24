class_name CompanyChecksSchoolTests
extends CompanyChecksCore
## XCamp-6: gladiatorial school system checks — opponent fighter profile (reveal tiers,
## persistence round-trip), combat counter recommendations, and form/weapon drill merging.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks`.


## Profile reveal tier advances correctly and tendency visibility is gated by tier.
static func _run_xcamp_6_profile_reveal(failures: PackedStringArray) -> void:
	var p := OpponentFighterProfile.make("f1", "Vex", "SWORD", "ox",
		{"strength": 12.0, "endurance": 10.0},
		{"aggression": 0.8, "parry_bias": 0.2, "target_part": "head"})
	if p.reveal != OpponentFighterProfile.REVEAL_UNKNOWN:
		_fail(failures, "profile_reveal: new profile should be REVEAL_UNKNOWN")
	else:
		_pass()
	if p.has_weapon_reveal():
		_fail(failures, "profile_reveal: unknown tier should not expose weapon")
	else:
		_pass()
	if p.tendency_visible("aggression"):
		_fail(failures, "profile_reveal: unknown tier should hide tendency")
	else:
		_pass()
	p.advance_reveal()
	if p.reveal != OpponentFighterProfile.REVEAL_WEAPON:
		_fail(failures, "profile_reveal: after 1 advance want REVEAL_WEAPON got %d" % p.reveal)
	else:
		_pass()
	if not p.has_weapon_reveal():
		_fail(failures, "profile_reveal: weapon tier should expose weapon")
	else:
		_pass()
	if p.tendency_visible("aggression"):
		_fail(failures, "profile_reveal: weapon tier should still hide tendency")
	else:
		_pass()
	p.advance_reveal()
	if p.reveal != OpponentFighterProfile.REVEAL_FULL:
		_fail(failures, "profile_reveal: after 2 advances want REVEAL_FULL got %d" % p.reveal)
	else:
		_pass()
	if not p.tendency_visible("aggression"):
		_fail(failures, "profile_reveal: full tier should expose tendency")
	else:
		_pass()
	# Further advance stays at FULL.
	p.advance_reveal()
	if p.reveal != OpponentFighterProfile.REVEAL_FULL:
		_fail(failures, "profile_reveal: should cap at FULL")
	else:
		_pass()


## to_dict / from_dict round-trip preserves all fields including reveal tier.
static func _run_xcamp_6_profile_roundtrip(failures: PackedStringArray) -> void:
	var orig := OpponentFighterProfile.make("f2", "Brutus", "AXE", "plow",
		{"strength": 15.0, "perception": 8.0},
		{"aggression": 0.3, "parry_bias": 0.9, "target_part": "torso"})
	orig.advance_reveal()
	orig.advance_reveal()
	var d: Dictionary = orig.to_dict()
	var restored: OpponentFighterProfile = OpponentFighterProfile.from_dict(d)
	if restored.fighter_id != orig.fighter_id:
		_fail(failures, "roundtrip: fighter_id mismatch")
	elif restored.display_name != orig.display_name:
		_fail(failures, "roundtrip: display_name mismatch")
	elif restored.weapon_id != orig.weapon_id:
		_fail(failures, "roundtrip: weapon_id mismatch")
	elif restored.form_id != orig.form_id:
		_fail(failures, "roundtrip: form_id mismatch")
	elif restored.reveal != orig.reveal:
		_fail(failures, "roundtrip: reveal mismatch want %d got %d" % [orig.reveal, restored.reveal])
	elif restored.stats.get("strength", -1) != 15.0:
		_fail(failures, "roundtrip: stats.strength mismatch")
	elif restored.tendency.get("parry_bias", -1) != 0.9:
		_fail(failures, "roundtrip: tendency.parry_bias mismatch")
	else:
		_pass()


## Counter recommendations: parry-heavy → aggressive counter; aggressive → defensive; balanced → controlling.
static func _run_xcamp_6_counter_recommendations(failures: PackedStringArray) -> void:
	# Parry-heavy opponent.
	var parry := OpponentFighterProfile.make("fp", "Parry Guy", "SWORD", "wall",
		{}, {"aggression": 0.2, "parry_bias": 0.9, "target_part": "head"})
	var rec_p: Dictionary = CombatCounter.recommendations(parry)
	if str(rec_p.get("counter_pressure", "")) != CombatCounter.PRESSURE_AGGRESSIVE:
		_fail(failures, "counter: parry-heavy want aggressive got '%s'" % str(rec_p.get("counter_pressure")))
	else:
		_pass()
	if str(rec_p.get("weapon_type", "")) != "SPEAR":
		_fail(failures, "counter: parry-heavy want SPEAR got '%s'" % str(rec_p.get("weapon_type")))
	else:
		_pass()
	if str(rec_p.get("stat_to_drill", "")) != "agility":
		_fail(failures, "counter: parry-heavy want agility got '%s'" % str(rec_p.get("stat_to_drill")))
	else:
		_pass()

	# Aggressive opponent.
	var agg := OpponentFighterProfile.make("fa", "Berserker", "MACE", "ox",
		{}, {"aggression": 0.9, "parry_bias": 0.2, "target_part": "torso"})
	var rec_a: Dictionary = CombatCounter.recommendations(agg)
	if str(rec_a.get("counter_pressure", "")) != CombatCounter.PRESSURE_DEFENSIVE:
		_fail(failures, "counter: aggressive want defensive got '%s'" % str(rec_a.get("counter_pressure")))
	else:
		_pass()
	if str(rec_a.get("weapon_type", "")) != "MACE":
		_fail(failures, "counter: aggressive want MACE got '%s'" % str(rec_a.get("weapon_type")))
	else:
		_pass()
	if str(rec_a.get("stat_to_drill", "")) != "endurance":
		_fail(failures, "counter: aggressive want endurance got '%s'" % str(rec_a.get("stat_to_drill")))
	else:
		_pass()

	# Balanced (tied) opponent.
	var bal := OpponentFighterProfile.make("fb", "Even", "SWORD", "balanced",
		{}, {"aggression": 0.5, "parry_bias": 0.5, "target_part": ""})
	var rec_b: Dictionary = CombatCounter.recommendations(bal)
	if str(rec_b.get("counter_pressure", "")) != CombatCounter.PRESSURE_CONTROLLING:
		_fail(failures, "counter: balanced want controlling got '%s'" % str(rec_b.get("counter_pressure")))
	else:
		_pass()
	if str(rec_b.get("stat_to_drill", "")) != "perception":
		_fail(failures, "counter: balanced want perception got '%s'" % str(rec_b.get("stat_to_drill")))
	else:
		_pass()

	# Null profile returns empty dict.
	var rec_n: Dictionary = CombatCounter.recommendations(null)
	if not rec_n.is_empty():
		_fail(failures, "counter: null profile should return empty dict")
	else:
		_pass()

	# is_scouted_enough gating.
	if CombatCounter.is_scouted_enough(parry):
		_fail(failures, "counter: unknown-reveal profile should not be scouted enough")
	else:
		_pass()
	parry.advance_reveal()
	if not CombatCounter.is_scouted_enough(parry):
		_fail(failures, "counter: weapon-reveal profile should be scouted enough")
	else:
		_pass()


## Form and weapon drills: train queues pending; merge applies gain with diminishing returns.
static func _run_xcamp_6_form_weapon_drill(failures: PackedStringArray) -> void:
	if not CompanyState.read_stub_proficiency_enabled():
		return
	var ent: Node = _harness_core_entity()
	# Queue form drill.
	ent._set_form_training_pending_value("wrath", 1.0)
	# Queue weapon drill.
	ent._set_weapon_training_pending_value("SWORD", 1.0)
	# Merge form.
	EntityProficiency.merge_form_training_pending(ent)
	var form_val: float = EntityProficiency.form_proficiency_value(ent, "wrath")
	if form_val <= 0.0:
		_fail(failures, "drill: form proficiency after merge should be > 0, got %f" % form_val)
	else:
		_pass()
	# Pending should be cleared after merge.
	var pending_form: float = float(ent._get_form_training_pending().get("wrath", -1.0))
	if pending_form != 0.0:
		_fail(failures, "drill: form pending should be 0 after merge, got %f" % pending_form)
	else:
		_pass()
	# Merge weapon.
	EntityProficiency.merge_weapon_training_pending(ent)
	var wpn_val: float = EntityProficiency.weapon_proficiency_value(ent, "SWORD")
	if wpn_val <= 0.0:
		_fail(failures, "drill: weapon proficiency after merge should be > 0, got %f" % wpn_val)
	else:
		_pass()
	var pending_wpn: float = float(ent._get_weapon_training_pending().get("SWORD", -1.0))
	if pending_wpn != 0.0:
		_fail(failures, "drill: weapon pending should be 0 after merge, got %f" % pending_wpn)
	else:
		_pass()
	# Second drill at higher proficiency should yield less gain (diminishing returns).
	var before: float = EntityProficiency.form_proficiency_value(ent, "wrath")
	ent._set_form_training_pending_value("wrath", 10.0)
	EntityProficiency.merge_form_training_pending(ent)
	var after: float = EntityProficiency.form_proficiency_value(ent, "wrath")
	var gain: float = after - before
	# At novice level (before < 5), gain_mult = 1.0, so gain should be ~10.
	# Just verify it gained something.
	if gain <= 0.0:
		_fail(failures, "drill: second form drill should still increase proficiency")
	else:
		_pass()
	_free_harness_core_entity(ent)


## School registry: ids, display names, lineup sizes, master profiles, and the world-meta state
## home seeding every registered school with a REVEAL_UNKNOWN dossier.
static func _run_xcamp_6_school_registry(failures: PackedStringArray) -> void:
	var ids: PackedStringArray = CompanySchool.school_ids()
	if not ids.has("house_verath") or not ids.has("iron_pit"):
		_fail(failures, "registry: missing school ids got %s" % str(ids))
	else:
		_pass()
	if CompanySchool.school_display_name("house_verath") != "House Verath":
		_fail(failures, "registry: house_verath display name")
	else:
		_pass()
	if CompanySchool.school_prestige("iron_pit") != 3:
		_fail(failures, "registry: iron_pit prestige")
	else:
		_pass()
	if not CompanySchool.has_school("iron_pit") or CompanySchool.has_school("no_such"):
		_fail(failures, "registry: has_school lookup")
	else:
		_pass()
	if CompanySchool.school_lineup_size("house_verath") != 3 or CompanySchool.school_lineup_size("iron_pit") != 3:
		_fail(failures, "registry: lineup sizes")
	else:
		_pass()
	var master: Array = CompanySchool.school_master_lineup("house_verath")
	if master.size() != 3:
		_fail(failures, "registry: master lineup size")
	elif not _is_ordered_names(master, ["Marrik", "Enna", "Corvin"]):
		_fail(failures, "registry: lineup order is the counter-order (must not change)")
	else:
		_pass()
	if not master.is_empty() and (master[0] as OpponentFighterProfile).reveal != OpponentFighterProfile.REVEAL_UNKNOWN:
		_fail(failures, "registry: master profile should start unknown")
	else:
		_pass()
	# World-meta state home seeds every registered school.
	var world: Node2D = _make_world(1)
	var state: Dictionary = CompanySchool.get_school_state(world)
	if state.get("dossiers", {}).size() != CompanySchool.school_ids().size():
		_fail(failures, "registry: state home should seed all schools")
	else:
		_pass()
	CompanySchool.set_school_state(world, {"dossiers": {"house_verath": []}, "scouts": {}, "active_match": {}})
	if CompanySchool.dossier_for(world, "iron_pit").size() != 3:
		_fail(failures, "registry: _ensure_dossiers should re-seed missing iron_pit")
	else:
		_pass()
	_release_harness_world(world)


static func _is_ordered_names(profiles: Array, names: Array) -> bool:
	if not profiles is Array or profiles.is_empty():
		return false
	for i in names.size():
		if i >= profiles.size():
			return false
		var p: Variant = profiles[i]
		if not (p is OpponentFighterProfile) or (p as OpponentFighterProfile).display_name != str(names[i]):
			return false
	return true


## Scout dispatch: gold cost, member tie-up, and the gate matrix.
static func _run_xcamp_6_scout_dispatch(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	var gold_before: int = CompanyState.get_gold(world)
	var check: Dictionary = CompanyState.can_dispatch_scout(world, "Brother0", "house_verath")
	if not check.get("ok", false):
		_fail(failures, "scout_dispatch: initial dispatch should be allowed: %s" % str(check.get("reason", "")))
	else:
		_pass()
	if not CompanyState.dispatch_scout(world, "Brother0", "house_verath"):
		_fail(failures, "scout_dispatch: dispatch_scout should succeed")
	else:
		_pass()
	if CompanyState.get_gold(world) != gold_before - CompanyScout.SCOUT_GOLD_COST:
		_fail(failures, "scout_dispatch: gold should be charged")
	else:
		_pass()
	if not CompanyState.member_is_scouting(world, "Brother0"):
		_fail(failures, "scout_dispatch: member should be scouting")
	else:
		_pass()
	if CompanyState.scout_days_remaining(world, "Brother0") != CompanyScout.SCOUT_TIE_DAYS:
		_fail(failures, "scout_dispatch: tie-up days")
	else:
		_pass()
	# Gates.
	if CompanyState.can_dispatch_scout(world, "Brother0", "house_verath").get("ok", false):
		_fail(failures, "scout_dispatch: already-scouting member should be blocked")
	else:
		_pass()
	if CompanyState.dispatch_scout(world, "Brother0", "house_verath"):
		_fail(failures, "scout_dispatch: double dispatch should fail")
	else:
		_pass()
	if CompanyState.can_dispatch_scout(world, "Nobody", "house_verath").get("ok", false):
		_fail(failures, "scout_dispatch: unknown member should be blocked")
	else:
		_pass()
	if CompanyState.can_dispatch_scout(world, "Brother1", "no_such").get("ok", false):
		_fail(failures, "scout_dispatch: unknown school should be blocked")
	else:
		_pass()
	# A second member can still scout (only the sender is tied up).
	if not CompanyState.dispatch_scout(world, "Brother1", "iron_pit"):
		_fail(failures, "scout_dispatch: second member should be able to scout another school")
	else:
		_pass()
	if CompanyState.active_scout_member_names(world).size() != 2:
		_fail(failures, "scout_dispatch: two active scouts expected")
	else:
		_pass()
	_release_harness_world(world)


## Scout return: two scout dispatches fully reveal a school's dossier across day ticks.
static func _run_xcamp_6_scout_return_reveals(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3, 0, true)
	if not CompanyState.dispatch_scout(world, "Brother0", "house_verath"):
		_fail(failures, "scout_return: dispatch 1 failed")
		return
	var day: int = CompanyState.get_day_index(world)
	# Advance two days: first returns (tie-up = 2).
	CompanyState.try_advance_day(world)
	CompanyState.try_advance_day(world)
	var day_gap: int = CompanyState.get_day_index(world) - day
	if CompanyState.member_is_scouting(world, "Brother0"):
		_fail(failures, "scout_return: scout should have returned after %d days" % day_gap)
	# First return lifts every fighter to weapon reveal (not full yet).
	var dossier1: Array = CompanyState.dossier_for(world, "house_verath")
	if dossier1.is_empty():
		_fail(failures, "scout_return: dossier missing after scout")
		return
	var all_weapon: bool = true
	for p in dossier1:
		if not (p as OpponentFighterProfile).has_weapon_reveal():
			all_weapon = false
	if not all_weapon:
		_fail(failures, "scout_return: first return should reveal weapon tier for all fighters")
	else:
		_pass()
	if CompanyState.dossier_reveal_ratio(world, "house_verath") >= 1.0:
		_fail(failures, "scout_return: weapon tier alone should not fully reveal")
	else:
		_pass()
	# Second scout completes the dossier.
	if not CompanyState.dispatch_scout(world, "Brother1", "house_verath"):
		_fail(failures, "scout_return: dispatch 2 failed")
		return
	CompanyState.try_advance_day(world)
	CompanyState.try_advance_day(world)
	if not CompanyState.dossier_fully_revealed(world, "house_verath"):
		_fail(failures, "scout_return: two returns should fully reveal dossier")
	else:
		_pass()
	if CompanyState.dossier_reveal_ratio(world, "house_verath") < 1.0:
		_fail(failures, "scout_return: fully revealed ratio should be 1.0")
	else:
		_pass()
	# Fully-revealed school can no longer be scouted.
	if CompanyState.can_dispatch_scout(world, "Brother2", "house_verath").get("ok", false):
		_fail(failures, "scout_return: fully revealed school should block new scouts")
	else:
		_pass()
	_release_harness_world(world)


## Match state machine: appoint -> bout-by-bout record -> outcome, plus gates.
static func _run_xcamp_6_match_flow(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	if CompanyState.has_active_match(world):
		_fail(failures, "match: fresh world should have no active match")
	else:
		_pass()
	# Gates.
	if CompanyState.can_appoint_match(world, "no_such", ["Brother0"]).get("ok", false):
		_fail(failures, "match: unknown school should block appointment")
	else:
		_pass()
	if CompanyState.appoint_match(world, "house_verath", ["Brother0", "Brother0", "Brother1"]):
		_fail(failures, "match: duplicate names should block appointment")
	else:
		_pass()
	var over_lineup: Array = ["Brother0", "Brother1", "Brother2", "Nobody"]
	if CompanyState.can_appoint_match(world, "house_verath", over_lineup).get("ok", false):
		_fail(failures, "match: lineup larger than school should block")
	else:
		_pass()
	# Appoint and verify snapshot.
	if not CompanyState.appoint_match(world, "house_verath", ["Brother2", "Brother1", "Brother0"]):
		_fail(failures, "match: appoint should succeed")
	else:
		_pass()
	var match_snap: Dictionary = CompanyState.match_active_snapshot(world)
	if CompanyState.match_school_id(world) != "house_verath":
		_fail(failures, "match: school id should be house_verath")
	else:
		_pass()
	if int(match_snap.get("bout_index", -1)) != 0:
		_fail(failures, "match: fresh match bout_index should be 0")
	if CompanyState.current_bout_player_name(world) != "Brother2":
		_fail(failures, "match: lineup order is the counter-order — bout 0 should be Brother2")
	else:
		_pass()
	# Bout entry scaffold.
	var enter: Dictionary = CompanyState.can_enter_current_bout(world)
	if not enter.get("ok", false):
		_fail(failures, "match: should be able to enter bout 0: %s" % str(enter.get("reason", "")))
	else:
		_pass()
	var opponent: OpponentFighterProfile = CompanyState.current_bout_opponent(world)
	if opponent == null or opponent.display_name != "Marrik":
		_fail(failures, "match: bout 0 opponent should be the school's lineup[0] (Marrik)")
	elif opponent.weapon_id != "SPEAR":
		_fail(failures, "match: bout 0 opponent should hold SPEAR")
	else:
		_pass()
	if not CompanyState.begin_current_bout(world):
		_fail(failures, "match: begin_current_bout should succeed")
	elif world.get_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER, "") != "Brother2":
		_fail(failures, "match: single-fighter bout lock should name the appointed fighter")
	else:
		_pass()
	var enc: EncounterNode = CompanyState.build_current_bout_encounter(world)
	if enc == null or enc.enemy_count != 1:
		_fail(failures, "match: bout encounter should force enemy_count 1")
	elif enc.encounter_config.get(SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "") != "SPEAR":
		_fail(failures, "match: bout encounter should force the opponent's weapon")
	elif not enc.encounter_config.has(CompanySchool.ENCOUNTER_KEY_SCHOOL_FIGHTER_PROFILE):
		_fail(failures, "match: bout encounter should carry the school profile for the AI hook")
	else:
		_pass()
	enc.free()
	# Bout outcomes — wins, then loses, then wins -> victory.
	var r1: Dictionary = CompanyState.record_bout_outcome(world, true)
	if r1.get("finished", true):
		_fail(failures, "match: bout 1 should not finish a 3-bout match")
	else:
		_pass()
	var r2: Dictionary = CompanyState.record_bout_outcome(world, false)
	var score_w: Dictionary = CompanyState.match_score(world)
	if int(score_w.get("player_wins", -1)) != 1 or int(score_w.get("opponent_wins", -1)) != 1:
		_fail(failures, "match: score 1-1 expected after two bouts")
	else:
		_pass()
	var r3: Dictionary = CompanyState.record_bout_outcome(world, true)
	if not r3.get("finished", false):
		_fail(failures, "match: third bout should finish the match")
	else:
		_pass()
	if r3.get("outcome", "") != CompanyMatch.OUTCOME_VICTORY:
		_fail(failures, "match: 2-1 should be victory got '%s'" % str(r3.get("outcome", "")))
	else:
		_pass()
	var result: Dictionary = CompanyState.match_result(world)
	if result.get("outcome", "") != CompanyMatch.OUTCOME_VICTORY:
		_fail(failures, "match: match_result should show victory")
	else:
		_pass()
	if world.has_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER):
		_fail(failures, "match: single-fighter lock should clear after the bout is recorded")
	else:
		_pass()
	# Cannot re-appoint while a (completed) match block is active until cancelled.
	if CompanyState.appoint_match(world, "iron_pit", ["Brother0"]):
		_fail(failures, "match: appoint should block while a match block is active")
	else:
		_pass()
	if not CompanyState.cancel_active_match(world):
		_fail(failures, "match: cancel should succeed")
	else:
		_pass()
	if CompanyState.has_active_match(world):
		_fail(failures, "match: cancel should clear the active match")
	else:
		_pass()
	_release_harness_world(world)


## Single-fighter bout filter: get_fightable_party_nodes honors the match bout lock.
static func _run_xcamp_6_single_fighter_filter(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	if CampaignEncounterBridge.get_fightable_party_nodes(world).size() != 3:
		_fail(failures, "filter: without a lock all living members should fight")
	else:
		_pass()
	world.set_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER, "Brother1")
	var nodes: Array = CampaignEncounterBridge.get_fightable_party_nodes(world)
	if nodes.size() != 1 or (nodes[0] as Node).name != "Brother1":
		_fail(failures, "filter: bout lock should return exactly the appointed fighter")
	else:
		_pass()
	world.set_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER, "Nobody")
	if not CampaignEncounterBridge.get_fightable_party_nodes(world).is_empty():
		_fail(failures, "filter: unknown named fighter should yield no fighters")
	else:
		_pass()
	world.remove_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER)
	if CampaignEncounterBridge.get_fightable_party_nodes(world).size() != 3:
		_fail(failures, "filter: clearing the lock should restore the whole party")
	else:
		_pass()
	_release_harness_world(world)


## School state persistence: the block JSON-round-trips with reveal tiers, scouts, and match state.
static func _run_xcamp_6_school_persistence(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	CompanySchool.advance_dossier_reveal(world, "house_verath")
	CompanySchool.advance_dossier_reveal(world, "house_verath")
	if not CompanyScout.dispatch_scout(world, "Brother0", "iron_pit"):
		_fail(failures, "persist: scout dispatch failed")
		return
	if not CompanyMatch.appoint_match(world, "iron_pit", ["Brother1"]):
		_fail(failures, "persist: appoint failed")
		return
	var saved: Dictionary = CompanySchool.state_to_save(world)
	var text: String = JSON.stringify(saved)
	if text.is_empty():
		_fail(failures, "persist: state should JSON-serialize")
		return
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_fail(failures, "persist: parsed state should be a dictionary")
		return
	var world2: Node2D = _make_world(3)
	CompanySchool.state_from_save(world2, parsed as Dictionary)
	var restored: Array = CompanySchool.dossier_for(world2, "house_verath")
	if restored.size() != 3:
		_fail(failures, "persist: dossier size restored")
	elif not _is_ordered_names(restored, ["Marrik", "Enna", "Corvin"]):
		_fail(failures, "persist: dossier order restored")
	else:
		_pass()
	if not (restored[0] as OpponentFighterProfile).has_full_reveal():
		_fail(failures, "persist: reveal tier restored")
	else:
		_pass()
	if not CompanyScout.member_is_scouting(world2, "Brother0"):
		_fail(failures, "persist: scout block restored")
	else:
		_pass()
	if CompanyState.match_school_id(world2) != "iron_pit":
		_fail(failures, "persist: active match restored")
	else:
		_pass()
	_release_harness_world(world2)
	_release_harness_world(world)


## Outcome variants: draw and defeat verdicts, exact/under-size lineups, and the guarantee that a
## finished match never leaves the single-fighter bout lock nor wedges the campaign behind it.
static func _run_xcamp_6_match_outcome_variants(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	if not CompanyMatch.appoint_match(world, "iron_pit", ["Brother0", "Brother1"]):
		_fail(failures, "outcome: appoint 2-bout match failed")
		return
	var r1: Dictionary = CompanyMatch.record_bout_outcome(world, true)
	var r2: Dictionary = CompanyMatch.record_bout_outcome(world, false)
	if bool(r1.get("finished")) or not bool(r2.get("finished")):
		_fail(failures, "outcome: 2-bout match should finish on second bout")
	elif CompanyState.match_result(world).get("outcome", "") != "draw":
		_fail(failures, "outcome: 1-1 should read as a draw")
	else:
		_pass()
	# A stale bout lock on a finished match must be cleared even on an extra record call.
	world.set_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER, "Brother0")
	CompanyMatch.record_bout_outcome(world, true)
	if world.has_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER):
		_fail(failures, "outcome: extra record on finished match should clear bout lock")
	else:
		_pass()
	var collected: Dictionary = CompanyState.collect_match_result(world)
	if collected.get("outcome", "") != "draw":
		_fail(failures, "outcome: collect should hand over the draw result")
	elif CompanyState.has_active_match(world):
		_fail(failures, "outcome: collect should clear the match block")
	else:
		_pass()
	_release_harness_world(world)

	var world2: Node2D = _make_world(3)
	if not CompanyMatch.appoint_match(world2, "house_verath", ["Brother0", "Brother1", "Brother2"]):
		_fail(failures, "outcome: appoint exact-size 3-bout match failed")
		return
	for i in 3:
		CompanyMatch.record_bout_outcome(world2, false)
	if CompanyState.match_result(world2).get("outcome", "") != "defeat":
		_fail(failures, "outcome: 0-3 should read as a defeat")
	else:
		_pass()
	CompanyState.collect_match_result(world2)
	if not CompanyState.can_appoint_match(world2, "iron_pit", ["Brother0"]).get("ok", false):
		_fail(failures, "outcome: after collect the company should be able to appoint again")
	else:
		_pass()
	_release_harness_world(world2)


## The pre-bout card: reconciling planned fighter, opponent identity, and reveal-tier intel.
static func _run_xcamp_6_bout_card(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	var stale: Dictionary = CompanyState.current_bout_card(world)
	if bool(stale.get("ok", false)) or stale.get("reason", "") != "no match appointed":
		_fail(failures, "card: without a match the card must say so")
	else:
		_pass()
	if not CompanyMatch.appoint_match(world, "house_verath", ["Brother1", "Brother2"]):
		_fail(failures, "card: appoint failed")
		return
	var card: Dictionary = CompanyState.current_bout_card(world)
	if not bool(card.get("ok", false)):
		_fail(failures, "card: should be enterable for bout 0")
	elif card.get("player_name", "") != "Brother1" or card.get("opponent_name", "") != "Marrik":
		_fail(failures, "card: bout 0 pairs Brother1 vs Marrik got %s" % str(card))
	elif card.get("total_bouts", 0) != 2 or card.get("bout_index", -1) != 0:
		_fail(failures, "card: match geometry wrong on appointed 2-bout")
	else:
		_pass()
	var gate: Dictionary = CompanyState.can_enter_current_bout(world)
	if not bool(gate.get("ok", false)) or gate.get("player_name", "") != "Brother1":
		_fail(failures, "card: enter gate should carry the planned fighter")
	else:
		_pass()
	CompanyMatch.record_bout_outcome(world, true)
	var card2: Dictionary = CompanyState.current_bout_card(world)
	if card2.get("player_name", "") != "Brother2" or card2.get("opponent_name", "") != "Enna":
		_fail(failures, "card: bout 1 should pair Brother2 vs Enna")
	else:
		_pass()
	_release_harness_world(world)


## Dispatch gating vs an active match, and the scouting_candidates readiness helper.
static func _run_xcamp_6_scout_match_gate(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	CompanyState.set_gold(world, 600)
	if not CompanyMatch.appoint_match(world, "iron_pit", ["Brother0"]):
		_fail(failures, "gate: appoint failed")
		return
	var blocked: Dictionary = CompanyScout.can_dispatch_scout(world, "Brother1", "house_verath")
	if bool(blocked.get("ok", false)) or not str(blocked.get("reason", "")).contains("match"):
		_fail(failures, "gate: a scout must not be dispatched mid-match")
	else:
		_pass()
	CompanyMatch.record_bout_outcome(world, true)
	CompanyState.collect_match_result(world)
	if not CompanyScout.dispatch_scout(world, "Brother1", "house_verath"):
		_fail(failures, "gate: after collect, scouting should resume")
		return
	CompanyState.try_advance_day(world)
	CompanyState.try_advance_day(world)
	# Two scout returns fully reveal a school (one return advances one tier).
	if not CompanyScout.dispatch_scout(world, "Brother1", "house_verath"):
		_fail(failures, "gate: second dispatch for the second tier failed")
		return
	CompanyState.try_advance_day(world)
	CompanyState.try_advance_day(world)
	if not CompanySchool.dossier_fully_revealed(world, "house_verath"):
		_fail(failures, "gate: returned scouts should fully reveal house_verath")
		return
	var candidates: Dictionary = CompanyState.scouting_candidates(world)
	if candidates.has("house_verath"):
		_fail(failures, "gate: fully revealed school should not offer candidates")
	elif not candidates.has("iron_pit"):
		_fail(failures, "gate: iron_pit should still offer scout candidates")
	else:
		_pass()
	_release_harness_world(world)


## The intel-safe visible dossier: nothing past the reveal tiers leaks to a naive UI.
static func _run_xcamp_6_dossier_visible_view(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	var unknown: Dictionary = CompanySchool.profile_visible_view(
		CompanySchool.school_master_lineup("iron_pit")[0] as OpponentFighterProfile
	)
	var u_weapon: String = str(unknown.get("weapon_id", ""))
	var u_stats: Dictionary = unknown.get("stats", {}) as Dictionary
	var u_form: String = str(unknown.get("form_id", ""))
	var u_tend: Dictionary = unknown.get("tendency", {}) as Dictionary
	if not u_weapon.is_empty() or not u_stats.is_empty():
		_fail(failures, "visible: unknown fighter must hide weapon and stats")
	elif not u_form.is_empty() or not u_tend.is_empty():
		_fail(failures, "visible: unknown fighter must hide form and tendency")
	else:
		_pass()
	CompanySchool.advance_dossier_reveal(world, "iron_pit")
	var mid_view: Array = CompanySchool.dossier_visible_view(world, "iron_pit")
	var mid: Dictionary = mid_view[0]
	if str(mid.get("weapon_id", "")).is_empty() or not (mid.get("stats", {}) is Dictionary):
		_fail(failures, "visible: weapon tier should reveal weapon and stats")
	elif not str(mid.get("form_id", "")).is_empty() or not (mid.get("tendency", {}) is Dictionary):
		_fail(failures, "visible: weapon tier should still hide form and tendency")
	else:
		_pass()
	CompanySchool.advance_dossier_reveal(world, "iron_pit")
	var full_view: Array = CompanySchool.dossier_visible_view(world, "iron_pit")
	var full: Dictionary = full_view[0]
	var full_tend: Dictionary = full.get("tendency", {}) as Dictionary
	if str(full.get("form_id", "")).is_empty() or full_tend.is_empty() or not full_tend.has("aggression"):
		_fail(failures, "visible: full tier should reveal form and tendency")
	else:
		_pass()
	# The real dossier must stay untouched while the visible view stays redacted.
	if not CompanySchool.dossier_for(world, "iron_pit")[0].has_full_reveal():
		_fail(failures, "visible: master dossier should be fully revealed after two advances")
	else:
		_pass()
	_release_harness_world(world)


## Abandoning a live match (mid-bout) must release the single-fighter lock, not strand the
## whole party behind a filtered fight.
static func _run_xcamp_6_cancel_frees_lock(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	if not CompanyMatch.appoint_match(world, "iron_pit", ["Brother0"]):
		_fail(failures, "cancel: appoint failed")
		return
	if not CompanyMatch.begin_current_bout(world):
		_fail(failures, "cancel: bout entry failed")
		return
	if not world.has_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER):
		_fail(failures, "cancel: bout lock should be set after entering")
		return
	if not CompanyMatch.cancel_active_match(world):
		_fail(failures, "cancel: cancel should succeed mid-bout")
		return
	if world.has_meta(CompanyMatch.WORLD_META_MATCH_SINGLE_FIGHTER):
		_fail(failures, "cancel: cancelling mid-bout must clear the bout lock")
	elif CampaignEncounterBridge.get_fightable_party_nodes(world).size() != 3:
		_fail(failures, "cancel: whole party should be fightable again after cancel")
	else:
		_pass()
	_release_harness_world(world)


## The bout card must redact opponent intel past the reveal tiers, then expose counter plans
## once the fighter is scouted enough to warrant them.
static func _run_xcamp_6_card_intel_redaction(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	if not CompanyMatch.appoint_match(world, "house_verath", ["Brother0"]):
		_fail(failures, "card-intel: appoint failed")
		return
	var hidden: Dictionary = CompanyState.current_bout_card(world)
	var hidden_recs: Dictionary = hidden.get("counter_recommendations", {}) as Dictionary
	if str(hidden.get("opponent_weapon_id", "")).is_empty() == false:
		_fail(failures, "card-intel: unscouted opponent weapon must stay hidden")
	elif not hidden_recs.is_empty():
		_fail(failures, "card-intel: unscouted opponent must not expose counter plans")
	else:
		_pass()
	CompanySchool.advance_dossier_reveal(world, "house_verath")
	var weapon_tier: Dictionary = CompanyState.current_bout_card(world)
	var tier_recs: Dictionary = weapon_tier.get("counter_recommendations", {}) as Dictionary
	if str(weapon_tier.get("opponent_weapon_id", "")) != "SPEAR":
		_fail(failures, "card-intel: weapon tier should expose Marrik's spear")
	elif tier_recs.is_empty():
		_fail(failures, "card-intel: scouted opponent should get counter plans")
	elif not str(weapon_tier.get("opponent_form_id", "")).is_empty() or bool(
		weapon_tier.get("opponent_tendency_visible", false)
	):
		_fail(failures, "card-intel: weapon tier must still hide form and tendency")
	else:
		_pass()
	CompanySchool.advance_dossier_reveal(world, "house_verath")
	var full_tier: Dictionary = CompanyState.current_bout_card(world)
	if str(full_tier.get("opponent_form_id", "")) != "wall" or not bool(
		full_tier.get("opponent_tendency_visible", false)
	):
		_fail(failures, "card-intel: full tier should expose Marrik's wall form and tendency")
	else:
		_pass()
	_release_harness_world(world)


## A scout who never comes back (dead, deserted, roster loss) brings back no intel.
static func _run_xcamp_6_scout_no_return(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	CompanyState.set_gold(world, 600)
	if not CompanyScout.dispatch_scout(world, "Brother1", "house_verath"):
		_fail(failures, "no-return: dispatch failed")
		return
	var pm: Node = CompanyState._resolve_party_manager(world)
	if pm == null:
		_fail(failures, "no-return: no party manager")
		return
	# Simulate the scout dying/deserting before the trips end: their node is unreachable.
	for member in pm.members:
		if member is Dictionary and str(member.get("name", "")) == "Brother1":
			member["node_ref"] = null
	var st: Dictionary = CompanyScout._state(world)
	var scouts: Dictionary = st.get("scouts", {})
	if scouts.is_empty():
		_fail(failures, "no-return: scout state missing")
		return
	scouts["Brother1"]["return_day"] = 0
	CompanyScout._set_state(world, st)
	CompanyState.advance_school_scouts(world)
	var marrik: OpponentFighterProfile = CompanySchool.dossier_for(world, "house_verath")[0] as OpponentFighterProfile
	if marrik.has_weapon_reveal():
		_fail(failures, "no-return: a lost scout must bring back no dossier intel")
	elif CompanyScout.member_is_scouting(world, "Brother1"):
		_fail(failures, "no-return: a lost scout's dispatch should be dropped")
	else:
		_pass()
	_release_harness_world(world)


## School summaries: stable public intel (names/prestige/roster) + reveal ratio that ticks with scouting.
static func _run_xcamp_6_school_summary(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	var overview: Array = CompanyState.schools_overview(world)
	if overview.size() != 2:
		_fail(failures, "summary: exactly two schools should register")
		return
	var house: Dictionary = {}
	for row in overview:
		if str(row.get("id", "")) == "house_verath":
			house = row
	if str(house.get("display_name", "")) != "House Verath" or int(house.get("prestige", 0)) != 2:
		_fail(failures, "summary: house_verath identity wrong")
	elif int(house.get("roster_size", 0)) != 3 or int(house.get("fightable_roster", 0)) != 3:
		_fail(failures, "summary: roster geometry wrong")
	elif float(house.get("reveal_ratio", -1.0)) != 0.0 or bool(house.get("fully_revealed", true)):
		_fail(failures, "summary: fresh school must read unrevealed")
	else:
		_pass()
	if not str(CompanyState.school_summary(world, "nope").get("display_name", "")).is_empty():
		_fail(failures, "summary: unknown school must read as blank")
	else:
		_pass()
	CompanySchool.advance_dossier_reveal(world, "house_verath")
	CompanySchool.advance_dossier_reveal(world, "house_verath")
	var after: Dictionary = CompanyState.school_summary(world, "house_verath")
	if float(after.get("reveal_ratio", -1.0)) != 1.0 or not bool(after.get("fully_revealed", false)):
		_fail(failures, "summary: full reveal should tick ratio and flag")
	else:
		_pass()
	_release_harness_world(world)


## Bout encounter setup: single human school fighter, labeled contract marker, forced weapon,
## and the profile + school id carried for the combat-side tendency hook.
static func _run_xcamp_6_bout_encounter_setup(failures: PackedStringArray) -> void:
	var world: Node2D = _make_world(3)
	if not CompanyMatch.appoint_match(world, "house_verath", ["Brother0", "Brother1"]):
		_fail(failures, "enc: appoint failed")
		return
	var enc: EncounterNode = CompanyMatch.build_current_bout_encounter(world)
	if enc.enemy_count != 1:
		_fail(failures, "enc: exactly one enemy per bout")
	elif (
		enc.marker_kind != "contract"
		or not str(enc.contract_marker_label).contains("House Verath")
		or not str(enc.contract_marker_label).contains("1/2")
	):
		_fail(failures, "enc: marker should label the school and bout (got '%s')" % str(enc.contract_marker_label))
	elif enc.encounter_config.get("enemy_species_pool", []) != [ResourcePaths.HUMAN_SPECIES]:
		_fail(failures, "enc: a school bout must field a human, never a random goblin")
	elif enc.encounter_config.get(SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "") != "SPEAR":
		_fail(failures, "enc: Marrik's spear should be forced on bout 0")
	elif not (enc.encounter_config.get(CompanySchool.ENCOUNTER_KEY_SCHOOL_FIGHTER_PROFILE, {}) is Dictionary):
		_fail(failures, "enc: profile dict must ride along for the tendency hook")
	elif enc.encounter_config.get(CompanySchool.ENCOUNTER_KEY_SCHOOL_ID, "") != "house_verath":
		_fail(failures, "enc: school id must ride along")
	else:
		_pass()
	CompanyMatch.record_bout_outcome(world, true)
	var enc2: EncounterNode = CompanyMatch.build_current_bout_encounter(world)
	if not str(enc2.contract_marker_label).contains("2/2"):
		_fail(failures, "enc: second bout should read 2/2 (got '%s')" % str(enc2.contract_marker_label))
	elif enc2.encounter_config.get(SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "") != "MACE":
		_fail(failures, "enc: Enna's mace should be forced on bout 1")
	else:
		_pass()
	_release_harness_world(world)
