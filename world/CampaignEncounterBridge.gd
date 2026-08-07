class_name CampaignEncounterBridge
extends RefCounted

## Overworld f''' " combat glue: encounter meta, living party gather, formation refresh, vitality on the map.
## Canonical: `overworld_tile_from_position` . `overworld_tile_center` . `place_player_on_overworld_tile`.

const META_ENEMY_FORMATION := "enemy_formation"
# Runtime preload ''" circular dependency (CompanyState preloads CampaignEncounterBridge).
static var _company_state_cache: Variant = null
static var _contract_spawner_cache: Variant = null


static func _get_company_state() -> GDScript:
	if _company_state_cache == null:
		_company_state_cache = load("res://world/CompanyState.gd")
	return _company_state_cache


# Runtime preload ''" circular dependency (ContractSpawner preloads CampaignEncounterBridge).


static func _get_contract_spawner() -> GDScript:
	if _contract_spawner_cache == null:
		_contract_spawner_cache = load("res://world/ContractSpawner.gd")
	return _contract_spawner_cache


## Cached $Character accessor  -  replaces all `world.$Character` string lookups.
## Uses `has_node` + typed cast to avoid silent failures on node rename.
static func get_player(world: Node2D) -> Node2D:
	if world == null or not world.has_node("Character"):
		return null
	return world.get_node("Character") as Node2D


static func clear_battle_kill_log(world: Node) -> void:
	if world != null and world.has_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG):
		world.remove_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG)


static func record_battle_kill(
	world: Node, victim_name: String, killer_name: String, weapon: String, part: String
) -> void:
	if world == null or victim_name.is_empty():
		return
	var kill_log: Array = []
	if world.has_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG):
		var raw: Variant = world.get_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG)
		if raw is Array:
			kill_log = raw
	(
		kill_log
		. append(
			{
				"victim": victim_name,
				"killer": killer_name,
				"weapon": weapon,
				"part": part,
			}
		)
	)
	world.set_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG, kill_log)


static func _kill_log_entry_for_victim(world: Node, victim_name: String) -> Dictionary:
	if world == null or not world.has_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG):
		return {}
	var raw: Variant = world.get_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG)
	if raw is not Array:
		return {}
	for entry in raw:
		if entry is Dictionary and entry.get("victim", "") == victim_name:
			return entry
	return {}


## Apply encounter node config to world meta before **`CombatFlow.start_combat`**.
static func prepare_combat_from_encounter(world: Node2D, encounter: Node) -> void:
	if world == null or encounter == null:
		return
	clear_battle_kill_log(world)
	# XCamp-4: reset medic action tracker for this combat (per-entity).
	world.set_meta("campaign_medic_actions_by", {})
	if encounter.has_method("get_combat_encounter_dict"):
		var enc: Dictionary = _get_contract_spawner().build_encounter_config(encounter.get_combat_encounter_dict())
		if "soak_preset_id" in encounter:
			var soak_id: String = str(encounter.soak_preset_id).strip_edges()
			if not soak_id.is_empty():
				enc = enc.duplicate(true) if not enc.is_empty() else {}
				enc[SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID] = soak_id
		if not enc.is_empty():
			_normalize_encounter_weapon_form_keys(enc)
			world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, enc)
		if enc.has("contract_title") or enc.has("pay_gold") or _get_company_state().is_tutorial_contract(enc):
			var contract: Dictionary = {
				"contract_title": str(enc.get("contract_title", "Contract")),
				"pay_gold": enc.get("pay_gold", 0),
				"difficulty_rating": enc.get("difficulty_rating", 1),
				"contract_type": enc.get("contract_type", ""),
				"tutorial": _get_company_state().is_tutorial_contract(enc),
			}
			_get_company_state().set_active_contract(world, contract)
		if enc.has("map_bleed_mult"):
			_get_company_state().set_map_bleed_mult(world, enc.get("map_bleed_mult", 1.0))
	if encounter.has_method("get_enemy_formation_dict"):
		var ef: Dictionary = encounter.get_enemy_formation_dict()
		if not ef.is_empty():
			world.set_meta(META_ENEMY_FORMATION, ef)
	var preset_id: String = ""
	if "soak_preset_id" in encounter:
		preset_id = str(encounter.soak_preset_id).strip_edges()
	if not preset_id.is_empty():
		SoakEncounterPresets.apply_world_post_setup(world, preset_id)
	else:
		# Random red tiles must not inherit **`dev_soak_encounter`** world meta from **`main._ready`**.
		SoakEncounterPresets.clear_world_soak_meta(world)
	refresh_party_formation_meta(world)
	_get_company_state().wire_party_medical_supply(world)
	apply_campaign_mood_stance_preferences(world)
	_apply_party_mood_to_encounter_meta(world)
	apply_campaign_mood_bias_to_encounter(world)
	# XCamp-4: snapshot combat participation for post-combat decay tracking.
	_proficiency_snapshot_combat_participation(world)
	SoakEncounterPresets.emit_f5_fight_enter_hint(encounter)


## XCamp-4: mark which party members are entering this combat (for decay tracking).
static func _proficiency_snapshot_combat_participation(world: Node2D) -> void:
	if world == null:
		return
	var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
	if pm == null or not ("members" in pm):
		return
	for m in pm.members:
		if m is not Dictionary:
			continue
		var node_ref: Variant = (m as Dictionary).get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		var node: Node = node_ref as Node
		if node.has_method("is_dead") and node.is_dead():
			continue
		var entity: Node = health_entity_from_character(node)
		if entity != null:
			entity.set("_last_fought_in_combat", true)


## XCamp-4: record a medic action performed by a specific entity (increments counter for INT floor).
static func record_medic_action(world: Node2D, medic_entity: Node) -> void:
	if world == null or medic_entity == null:
		return
	var actions: Dictionary = (
		world.get_meta("campaign_medic_actions_by") if world.has_meta("campaign_medic_actions_by") else {}
	)
	var key: int = medic_entity.get_instance_id()
	var count: int = int(actions.get(key, 0))
	actions[key] = count + 1
	world.set_meta("campaign_medic_actions_by", actions)


## Drop transient combat meta after battle (entity wounds persist on **`CoreEntity`** nodes).
static func clear_transient_combat_meta(world: Node2D) -> void:
	if world == null:
		return
	SoakEncounterPresets.clear_world_soak_meta(world)
	if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		world.remove_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
	if world.has_meta(META_ENEMY_FORMATION):
		world.remove_meta(META_ENEMY_FORMATION)
	if world.has_meta("campaign_map_bleed_mult"):
		world.remove_meta("campaign_map_bleed_mult")


## After victory/defeat: refresh party formation count from living members.
static func on_return_from_combat(world: Node2D, winner: String) -> void:
	if world == null or winner != CombatConstants.SIDE_PLAYER:
		# XCamp-4: still apply decay for defeated mercenaries (decay applies regardless of outcome).
		if _get_company_state().read_stub_proficiency_enabled():
			var current_day: int = _get_company_state().get_day_index(world)
			for n in get_fightable_party_nodes(world):
				var entity: Node = health_entity_from_character(n)
				if entity != null and "_proficiency_bonus" in entity and "last_fought_day" in entity:
					entity.last_fought_in_combat = false
					EntityProficiency.apply_decay(entity, current_day)
		clear_transient_combat_meta(world)
		return
	# Camp-2.1: any player victory lifts map bleed block (not only tutorial-tagged contracts).
	_get_company_state().mark_tutorial_completed(world)
	build_last_battle_summary(world)

	# XCamp-4: proficiency ''"" update _last_fought_day and apply decay for party members.
	_proficiency_post_combat(world)

	clear_transient_combat_meta(world)
	refresh_party_formation_meta(world)
	_get_company_state().wire_party_medical_supply(world)
	sync_overworld_player_grid_anchor(world)
	_log_party_vitality(world, "After battle")
	if party_has_untreated_wounds(world):
		if OperationalLog.is_play_session_active():
			OperationalLog.play_world(_get_company_state().format_post_fight_field_care_world_log(world))


## XCamp-4: post-combat proficiency processing ''"" update fight day, apply decay, medic INT floor.
static func _proficiency_post_combat(world: Node2D) -> void:
	if world == null or not _get_company_state().read_stub_proficiency_enabled():
		return
	var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
	if pm == null or not ("members" in pm):
		return
	var current_day: int = _get_company_state().get_day_index(world)
	for m in pm.members:
		if m is not Dictionary:
			continue
		var node_ref: Variant = (m as Dictionary).get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		var node: Node = node_ref as Node
		if node.has_method("is_dead") and node.is_dead():
			continue
		var entity: Node = health_entity_from_character(node)
		if entity == null or not ("_proficiency_bonus" in entity):
			continue
		# Update last_fought_day for mercenaries who participated in combat.
		var fought: bool = false
		if "last_fought_in_combat" in entity:
			fought = bool(entity.last_fought_in_combat)
		elif "_last_fought_in_combat" in entity:
			fought = bool(entity.get("_last_fought_in_combat"))
		if fought and "last_fought_day" in entity:
			entity.last_fought_day = current_day
		# Apply decay (gated by CompanyState.read_stub_proficiency_enabled).
		EntityProficiency.apply_decay(entity, current_day)

	# Medic INT floor: only the combatants who actually performed medical actions get a temporary INT boost.
	var medic_actions_by_entity: Dictionary = (
		world.get_meta("campaign_medic_actions_by") if world.has_meta("campaign_medic_actions_by") else {}
	)
	for entity_key in medic_actions_by_entity.keys():
		var action_count: int = int(medic_actions_by_entity[entity_key])
		if action_count <= 0:
			continue
		for m in pm.members:
			if m is not Dictionary:
				continue
			var node_ref: Variant = (m as Dictionary).get("node_ref")
			if not is_instance_valid(node_ref) or not (node_ref is Node):
				continue
			var node: Node = node_ref as Node
			if node.has_method("is_dead") and node.is_dead():
				continue
			var member_entity: Node = health_entity_from_character(node)
			if member_entity == null:
				continue
			var key_match: bool = false
			if entity_key is int:
				key_match = member_entity.get_instance_id() == int(entity_key)
			elif entity_key is Object:
				key_match = member_entity == entity_key
			if not key_match:
				continue
			# Medic INT floor: flat bonus per medical action (not subject to diminishing returns via
			# award_stat_gain).
			# This is intentional ''"" the medic floor is a guaranteed baseline reward, not practice-based growth.
			if "_proficiency_bonus" in member_entity:
				var prof: Dictionary = member_entity._proficiency_bonus
				prof["intelligence"] = (
					float(prof.get("intelligence", 0.0)) + EntityProficiency.GAIN_MEDIC_INT_FLOOR * action_count
				)
				member_entity._proficiency_bonus = prof
			break


## Step onto contract tile: stash contract, spawn enemies, consume marker (R3).
static func _apply_party_mood_to_encounter_meta(world: Node2D) -> void:
	if world == null or not world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		return
	var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	if pm == null:
		return
	var avg: float = _compute_average_mood(pm)
	if avg < 0:
		return
	var enc: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
	if enc is Dictionary:
		var merged: Dictionary = enc.duplicate(true)
		merged[CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER] = clampf(avg / 100.0, 0.15, 1.0)
		world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, merged)


## Average `company_mood` across party members; returns -1 when roster is empty.
static func _compute_average_mood(pm: Variant) -> float:
	if not ("members" in pm):
		return -1.0
	var sum: float = 0.0
	var n: int = 0
	for m in pm.members:
		if m is Dictionary:
			sum += float(m.get("company_mood", CampaignTypes.MOOD_DEFAULT))
			n += 1
	if n <= 0:
		return -1.0
	return sum / float(n)


## XCamp-3.8 (MS-CAMP): stamp fight-entry weapon form from campaign mood when roster has no explicit pref.
static func apply_campaign_mood_stance_preferences(world: Node2D) -> void:
	if world == null:
		return
	var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
	if pm == null or not ("members" in pm):
		return
	for m in pm.members:
		if m is not Dictionary:
			continue
		var node_ref: Variant = (m as Dictionary).get("node_ref")
		if not is_instance_valid(node_ref) or not (node_ref is Node):
			continue
		var node: Node = node_ref as Node
		if node.has_method("is_dead") and node.is_dead():
			continue
		if not ("stance_preference" in node):
			continue
		var existing: String = CombatWeaponForm.normalize_form(str(node.get("stance_preference")))
		if not existing.is_empty() and existing != CombatWeaponForm.FORM_BALANCED:
			continue
		var mood: float = float((m as Dictionary).get("company_mood", CampaignTypes.MOOD_DEFAULT))
		node.set("stance_preference", _get_company_state().stance_preference_for_campaign_mood(mood))


## XCamp-3.9 (MS-CAMP): stamp fight-entry campaign mood bias from average company mood into encounter meta.
## Enemy side reads `enemy_mood_bias` from encounter config (0''""100; default 50 = neutral).
static func apply_campaign_mood_bias_to_encounter(world: Node2D) -> void:
	if world == null or not world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		return
	var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
	if pm == null:
		return
	var avg_mood: float = _compute_average_mood(pm)
	if avg_mood < 0:
		return
	var enc: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
	if enc is Dictionary:
		var merged: Dictionary = enc.duplicate(true)
		merged[CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER] = avg_mood
		var enemy_bias: float = enc.get("enemy_mood_bias", 50.0)
		merged[CombatCampaignMoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY] = clampf(enemy_bias, 0.0, 100.0)
		world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, merged)


static func begin_contract_encounter(world: Node2D, encounter: Node, rng: RandomNumberGenerator) -> Array:
	if world == null or encounter == null:
		return []
	prepare_combat_from_encounter(world, encounter)
	var enemies: Array = []
	if encounter.has_method("spawn_enemies"):
		enemies = encounter.spawn_enemies(world, rng)
	if enemies.is_empty():
		abort_contract_encounter_entry(world)
		return []
	encounter.queue_free()
	return enemies


## Spawn failed or combat aborted after `prepare_combat_from_encounter` ''"" keep map marker, drop stale meta.
static func abort_contract_encounter_entry(world: Node2D) -> void:
	if world == null:
		return
	if world.has_meta("_combat_enemies"):
		var raw: Variant = world.get_meta("_combat_enemies")
		if raw is Array:
			for enemy in raw:
				if is_instance_valid(enemy) and enemy is Node:
					(enemy as Node).queue_free()
		world.remove_meta("_combat_enemies")
	clear_transient_combat_meta(world)
	_get_company_state().clear_active_contract(world)


## Camp-2.2 row: blood, bleed, untreated parts, worst ATLS class (1''""4).
static func member_battle_summary_entry(snap: Dictionary, entity: Node) -> Dictionary:
	var blood_pct: float = snap.get("blood_volume", 100.0)
	var bleed_rate: float = snap.get("total_bleeding_rate", 0.0)
	var snap_copy: Dictionary = snap.duplicate(true)
	var untreated: PackedStringArray = untreated_wound_part_names(entity)
	if not untreated.is_empty():
		snap_copy["untreated_parts"] = untreated
	return {
		"name": str(snap.get("name", "?")),
		"blood_pct": blood_pct,
		"bleed_rate": bleed_rate,
		"untreated": entity_has_untreated_wounds(entity),
		"untreated_parts": untreated,
		"worst_atls_band": BleedingConstants.atls_hemorrhage_class_from_remaining_pct(blood_pct),
		"snapshot": snap_copy,
	}


static func untreated_wound_part_names(entity: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if entity == null:
		return out
	for p in EntityWounds.sorted_untreated_part_names(entity):
		out.append(p as String)
	return out


static func build_last_battle_summary(world: Node2D, battle_winner: String = CombatConstants.SIDE_PLAYER) -> void:
	if world == null:
		return
	var deaths: Array = []
	var members: Array = []
	var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	if pm != null and "members" in pm:
		for member in pm.members:
			if not member is Dictionary:
				continue
			var node_ref: Variant = member.get("node_ref")
			if not is_instance_valid(node_ref) or not (node_ref is Node):
				continue
			var node: Node = node_ref as Node
			var entity: Node = health_entity_from_character(node)
			var snap: Dictionary = PartyMemberSnapshot.snapshot_from_member(member)
			if node.has_method("is_dead") and node.is_dead():
				var name_s: String = str(member.get("name", node.name))
				var info: Dictionary = _death_info_from_entity(entity)
				var kill: Dictionary = _kill_log_entry_for_victim(world, name_s)
				var part_s: String = kill.get("part", "")
				if part_s.is_empty():
					part_s = str(info.get("part", "unknown"))
				(
					deaths
					. append(
						{
							"name": name_s,
							"part": part_s,
							"cause": str(info.get("cause", "fallen in battle")),
							"weapon": kill.get("weapon", ""),
							"killer": kill.get("killer", ""),
						}
					)
				)
				continue
			members.append(member_battle_summary_entry(snap, entity))
	if battle_winner != CombatConstants.SIDE_PLAYER:
		_merge_roster_kill_log_deaths(world, pm, deaths)
	var contract: Dictionary = _get_company_state().get_active_contract(world)
	if not _get_company_state().defeat_should_end_company_run(contract):
		_get_company_state().apply_battle_death_witness_mood(world, deaths.size())
	world.set_meta(
		CampaignTypes.WORLD_META_LAST_BATTLE_SUMMARY,
		{"deaths": deaths, "members": members, "winner": str(battle_winner)}
	)


## On defeat, party nodes may not yet report `is_dead()`  -  honor battle kill log for roster names.
static func _merge_roster_kill_log_deaths(world: Node2D, pm: Node, deaths: Array) -> void:
	if world == null or pm == null or not world.has_meta(CampaignTypes.WORLD_META_BATTLE_KILL_LOG):
		return
	var listed: Dictionary = {}
	for d in deaths:
		if d is Dictionary:
			listed[(d as Dictionary).get("name", "")] = true
	for member in pm.members:
		if not member is Dictionary:
			continue
		var name_s: String = member.get("name", "")
		if name_s.is_empty() or listed.has(name_s):
			continue
		var kill: Dictionary = _kill_log_entry_for_victim(world, name_s)
		if kill.is_empty():
			continue
		(
			deaths
			. append(
				{
					"name": name_s,
					"part": str(kill.get("part", "unknown")),
					"cause": "fallen in battle",
					"weapon": kill.get("weapon", ""),
					"killer": kill.get("killer", ""),
				}
			)
		)
		listed[name_s] = true


static func can_enter_combat(world: Node2D) -> Dictionary:
	var out: Dictionary = {"ok": true, "message": ""}
	var nodes: Array = get_fightable_party_nodes(world)
	if nodes.is_empty():
		out.ok = false
		out.message = "No living party members can fight."
		return out
	var leader_ok: bool = false
	for n in nodes:
		if n != null and n.get(DataKeys.COMBATANT_IS_PARTY_LEADER) == true:
			leader_ok = true
			break
	if not leader_ok and nodes.size() > 0:
		# Allow combat if any living member exists (solo companion edge case).
		leader_ok = true
	if not leader_ok:
		out.ok = false
		out.message = "Party leader is down."
		return out
	for n in nodes:
		if n == null:
			continue
		if n.has_method("is_unconscious") and n.is_unconscious():
			out.ok = false
			out.message = "%s is unconscious and cannot fight." % str(n.name)
			return out
	return out


static func get_fightable_party_nodes(world: Node2D) -> Array:
	var players: Array = []
	var pm = world.get_meta("party_manager", null) if world != null and world.has_meta("party_manager") else null
	if pm == null:
		return players
	var leader_only: bool = (
		world != null
		and world.has_meta(SoakEncounterPresets.WORLD_META_PLAYER_LEADER_ONLY)
		and bool(world.get_meta(SoakEncounterPresets.WORLD_META_PLAYER_LEADER_ONLY))
	)
	var roster: Array = pm.members if "members" in pm else pm.get_members()
	for member in roster:
		var node_ref = member.get("node_ref") if member is Dictionary else null
		if not is_instance_valid(node_ref):
			continue
		if node_ref.has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		if leader_only and node_ref.get(DataKeys.COMBATANT_IS_PARTY_LEADER) != true:
			continue
		players.append(node_ref)
	if world != null and world.has_meta(SoakEncounterPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP):
		var cap: int = int(world.get_meta(SoakEncounterPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP))
		if cap > 0:
			players = _cap_fightable_party_leader_first(players, cap)
	return players


static func _cap_fightable_party_leader_first(nodes: Array, cap: int) -> Array:
	if nodes.size() <= cap:
		return nodes
	var leader: Node = null
	var rest: Array = []
	for n in nodes:
		if n == null:
			continue
		if n.get(DataKeys.COMBATANT_IS_PARTY_LEADER) == true:
			leader = n
		else:
			rest.append(n)
	var out: Array = []
	if leader != null:
		out.append(leader)
	for n in rest:
		if out.size() >= cap:
			break
		out.append(n)
	if out.is_empty():
		return nodes.slice(0, cap)
	return out


static func refresh_party_formation_meta(world: Node2D) -> void:
	if world == null:
		return
	if (
		world.has_meta(SoakEncounterPresets.WORLD_META_LOCK_PARTY_FORMATION)
		and bool(world.get_meta(SoakEncounterPresets.WORLD_META_LOCK_PARTY_FORMATION))
	):
		return
	var n: int = get_fightable_party_nodes(world).size()
	if n <= 0:
		return
	var preset: Dictionary = FormationPreset.default_for_count(n)
	if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		var enc_raw: Variant = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
		if enc_raw is Dictionary:
			var enc: Dictionary = enc_raw
			if (
				not _get_company_state().is_tutorial_contract(enc)
				and enc.has(CombatConstants.ENCOUNTER_KEY_PLAYER_FORMATION)
			):
				var pf: Variant = enc.get(CombatConstants.ENCOUNTER_KEY_PLAYER_FORMATION)
				if pf is Dictionary and not pf.is_empty():
					preset = pf.duplicate(true)
			elif (
				not _get_company_state().is_tutorial_contract(enc)
				and enc.has(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT)
			):
				var front_n: int = enc.get(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)
				if front_n > 0:
					preset = FormationPreset.for_front_count(n, front_n)
	var prior: Dictionary = world.get_meta("party_formation", {}) if world.has_meta("party_formation") else {}
	if prior.has("density"):
		preset["density"] = prior["density"]
	for key in [
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT,
		CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS,
		CombatConstants.FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX,
		CombatConstants.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN,
	]:
		if prior.has(key):
			preset[key] = prior[key]
	world.set_meta("party_formation", preset)


## Read overworld RNG / enemy scene from `main` exports or session meta (F5 / headless).
static func resolve_overworld_rng(world: Node) -> RandomNumberGenerator:
	if world == null:
		return null
	if world.has_meta("rng"):
		var from_meta: Variant = world.get_meta("rng")
		if from_meta is RandomNumberGenerator:
			return from_meta
	if "rng" in world:
		var from_prop: Variant = world.get("rng")
		if from_prop is RandomNumberGenerator:
			return from_prop
	return null


static func resolve_enemy_scene(world: Node) -> PackedScene:
	if world == null:
		return null
	if world.has_meta("enemy_scene"):
		var from_meta: Variant = world.get_meta("enemy_scene")
		if from_meta is PackedScene:
			return from_meta
	if "enemy_scene" in world:
		var from_prop: Variant = world.get("enemy_scene")
		if from_prop is PackedScene:
			return from_prop
	return null


## Overworld grid math ''"" delegates to **`OverworldMap`** (not per-world `_tile_coords` hooks).
static func overworld_tile_from_position(pos: Vector2) -> Vector2i:
	return OverworldMap.tile_coords_from_pos(pos)


static func overworld_tile_center(tile: Vector2i) -> Vector2:
	return OverworldMap.tile_center(tile)


## Snap player to tile center, reset movement target, and align **`last_player_tile`** (overworld reject uses this).
static func place_player_on_overworld_tile(world: Node2D, tile: Vector2i) -> void:
	var player: Node2D = get_player(world)
	if player == null:
		return
	if player == null:
		return
	var center: Vector2 = overworld_tile_center(tile)
	if player.has_method("_cancel_grid_move_to"):
		player.call("_cancel_grid_move_to", center)
	else:
		player.position = center
	world.set_meta("last_player_tile", tile)


static func sync_overworld_player_grid_anchor(world: Node2D) -> void:
	var player: Node2D = get_player(world)
	if player == null:
		return
	if player == null:
		return
	var tile: Vector2i = overworld_tile_from_position(player.position)
	place_player_on_overworld_tile(world, tile)


## After soft defeat, step one tile toward camp so a respawned marker is not under the player.
static func nudge_player_toward_camp_tile(world: Node2D) -> void:
	var player: Node2D = get_player(world)
	if player == null:
		return
	if player == null:
		return
	var tile: Vector2i = overworld_tile_from_position(player.position)
	var camp: Vector2i = CampaignTypes.DEFAULT_CAMP_TILE
	if world.has_meta("camp_tile") and world.get_meta("camp_tile") is Vector2i:
		camp = world.get_meta("camp_tile")
	if tile == camp:
		place_player_on_overworld_tile(world, camp)
		return
	var step := Vector2i(clampi(camp.x - tile.x, -1, 1), clampi(camp.y - tile.y, -1, 1))
	place_player_on_overworld_tile(world, tile + step)


static func advance_party_overworld_minute(world: Node2D) -> void:
	var seconds_per_move: float = 60.0
	if world == null:
		return
	var bleed_mult: float = _get_company_state().get_map_bleed_mult(world)
	var to_process: Array = []
	var p: Node2D = get_player(world)
	if p != null:
		to_process.append(p)
	var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	var roster: Array = pm.members if pm != null and "members" in pm else []
	for member in roster:
		var node_ref = member.get("node_ref") if member is Dictionary else null
		if is_instance_valid(node_ref) and node_ref != p:
			to_process.append(node_ref)
	for entity in to_process:
		if not is_instance_valid(entity):
			continue
		var health: Node = health_entity_from_character(entity)
		if health == null:
			continue
		if bleed_mult != 1.0:
			if health.has_method("process_bleeding"):
				health.process_bleeding(seconds_per_move * bleed_mult)
			if health.has_method("process_blood_loss"):
				health.process_blood_loss(seconds_per_move * bleed_mult)
			if health.has_method("_process_healing"):
				health._process_healing(seconds_per_move)
		else:
			if health.has_method("process_bleeding"):
				health.process_bleeding(seconds_per_move)
			if health.has_method("process_blood_loss"):
				health.process_blood_loss(seconds_per_move)
			if health.has_method("_process_healing"):
				health._process_healing(seconds_per_move)
		if health.has_method("ensure_consciousness_current"):
			health.ensure_consciousness_current()


static func entity_has_untreated_wounds(entity: Node) -> bool:
	return EntityWounds.entity_has_untreated_wounds(entity)


static func party_untreated_part_count(world: Node2D) -> int:
	var total: int = 0
	for n in get_fightable_party_nodes(world):
		var entity: Node = health_entity_from_character(n)
		if entity == null:
			continue
		total += untreated_wound_part_names(entity).size()
	return total


static func party_has_untreated_wounds(world: Node2D) -> bool:
	for n in get_fightable_party_nodes(world):
		var entity: Node = health_entity_from_character(n)
		if entity_has_untreated_wounds(entity):
			return true
	return false


## Live party display rows (`PartyManager.get_members`); falls back to last battle summary snapshots.
static func party_member_snapshots(world: Node2D) -> Array:
	if world == null:
		return []
	var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		return pm.get_members()
	return _party_member_snapshots_from_summary(world)


static func _party_member_snapshots_from_summary(world: Node2D) -> Array:
	var summary: Dictionary = _get_company_state().get_last_battle_summary(world)
	var members: Variant = summary.get("members", [])
	if not (members is Array):
		return []
	var rows: Array = []
	for entry in members:
		if entry is not Dictionary:
			continue
		var snap: Variant = entry.get("snapshot", entry)
		if snap is Dictionary:
			rows.append(snap)
	return rows


static func health_entity_from_character(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("_get_medical_entity"):
		var e: Variant = node._get_medical_entity()
		return e as Node if e is Node else null
	return node


static func _death_info_from_entity(entity: Node) -> Dictionary:
	if entity == null:
		return {"part": "unknown", "cause": "fallen in battle"}
	if not ("wounds" in entity) or not (entity.wounds is Dictionary):
		var death_cause: String = "fallen in battle"
		if (
			"blood_volume" in entity
			and float(entity.blood_volume) <= BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
		):
			death_cause = "exsanguination"
		return {"part": "unknown", "cause": death_cause, "weapon": "", "killer": ""}
	var worst_part: String = ""
	var worst_rate: float = 0.0
	var arterial: bool = false
	if entity.wounds is Dictionary:
		for part in entity.wounds.keys():
			for injury in entity.wounds[part]:
				if not injury is Dictionary:
					continue
				var rate: float = injury.get("current_bleeding_rate", 0.0)
				if rate > worst_rate:
					worst_rate = rate
					worst_part = str(part)
				if injury.get("is_arterial", false):
					arterial = true
	var cause: String = "arterial hemorrhage" if arterial else "hemorrhage"
	if worst_rate <= 0.0 and float(entity.blood_volume) <= BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING:
		cause = "exsanguination"
	return {
		"part": worst_part if not worst_part.is_empty() else "unknown",
		"cause": cause,
		"weapon": "",
		"killer": "",
	}


## WF-4: strip encounter default weapon form keys before world meta (mirror doctrine string hygiene).
static func _normalize_encounter_weapon_form_keys(enc: Dictionary) -> void:
	for key in [
		CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM,
		CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM,
	]:
		if enc.has(key):
			enc[key] = str(enc.get(key, "")).strip_edges()


static func _log_party_vitality(world: Node2D, prefix: String) -> void:
	for n in get_fightable_party_nodes(world):
		var entity: Node = health_entity_from_character(n)
		if entity == null:
			continue
		var bleed: float = CombatantEntityAccess.get_total_bleeding_rate_from_node(entity)
		var bv: float = CombatantEntityAccess.get_blood_volume_from_node(entity)
		var wounded_n: int = 0
		if entity.has_method("get_wounded_parts"):
			wounded_n = entity.get_wounded_parts().size()
		var untreated: bool = entity_has_untreated_wounds(entity)
		if CombatConstants.combat_debug_active():
			CombatDebug.log(
				(
                    "[World] %s %s: blood=%d%% bleed=%.1f/s wounds=%d untreated=%s"
					% [prefix, n.name, int(bv), bleed, wounded_n, str(untreated)]
				)
			)
