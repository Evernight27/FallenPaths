class_name CompanyScout
extends RefCounted

## XCamp-6 (gladiatorial school system): scouting a rival school.
##
## To scout, the company pays gold and sends a party member to watch the school's open
## skirmishes. That member is tied up for SCOUT_TIE_DAYS days (cannot be appointed to a school
## match). When they return, CompanySchool.advance_dossier_reveal() lifts every fighter in that
## school's dossier one scouting tier (unknown -> weapon -> full tendency).
##
## Scout returns resolve from the day tick: CompanyDayCycle.on_day_tick calls advance_scouts().

const SCOUT_GOLD_COST: int = 50
const SCOUT_TIE_DAYS: int = 2


## === Live block access (shared home is CompanySchool) ===


static func _state(world: Node) -> Dictionary:
	return CompanySchool.get_school_state(world)


static func _set_state(world: Node, state: Dictionary) -> void:
	CompanySchool.set_school_state(world, state)


## member_name -> {school_id, return_day} for every active dispatch.
static func scout_entries(world: Node) -> Dictionary:
	if world == null:
		return {}
	return (_state(world).get("scouts", {}) as Dictionary).duplicate(true)


## Names of every party member currently away scouting.
static func active_scout_member_names(world: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for key in scout_entries(world).keys():
		out.append(str(key))
	return out


static func member_is_scouting(world: Node, member_name: String) -> bool:
	return scout_entries(world).has(member_name)


## Scout info for a member: {school_id, return_day, days_left}; {} when not scouting.
static func scout_info_for(world: Node, member_name: String) -> Dictionary:
	if world == null or member_name.is_empty() or not member_is_scouting(world, member_name):
		return {}
	var entry: Dictionary = scout_entries(world)[member_name]
	var return_day: int = int(entry.get("return_day", 0))
	var days_left: int = maxi(0, return_day - CompanyState.get_day_index(world))
	return {
		"school_id": str(entry.get("school_id", "")),
		"return_day": return_day,
		"days_left": days_left,
	}


static func scout_days_remaining(world: Node, member_name: String) -> int:
	return int(scout_info_for(world, member_name).get("days_left", 0))


## === Dispatch ===


## Can the named party member be sent to scout `school_id`? {ok, reason}.
static func can_dispatch_scout(world: Node, member_name: String, school_id: String) -> Dictionary:
	if world == null:
		return {"ok": false, "reason": "no world"}
	if CompanyState.has_active_match(world):
		return {"ok": false, "reason": "school match underway"}
	if not CompanySchool.has_school(school_id):
		return {"ok": false, "reason": "unknown school '%s'" % school_id}
	if CompanySchool.dossier_fully_revealed(world, school_id):
		return {"ok": false, "reason": "'%s' already fully scouted" % CompanySchool.school_display_name(school_id)}
	if member_name.is_empty():
		return {"ok": false, "reason": "no scout named"}
	var member: Node = CompanyScout._resolve_member_node_by_name(world, member_name)
	if member == null:
		return {"ok": false, "reason": "no party member '%s'" % member_name}
	if member.has_method("is_dead") and member.is_dead():
		return {"ok": false, "reason": "%s cannot scout while dead" % member_name}
	if member_is_scouting(world, member_name):
		return {"ok": false, "reason": "%s is already away scouting" % member_name}
	if CompanyState.get_gold(world) < SCOUT_GOLD_COST:
		return {"ok": false, "reason": "need %dg more to scout" % (SCOUT_GOLD_COST - CompanyState.get_gold(world))}
	return {"ok": true, "reason": ""}


## Dispatches a scout: charges gold, ties up the member for SCOUT_TIE_DAYS. Returns true on success.
static func dispatch_scout(world: Node, member_name: String, school_id: String) -> bool:
	if not can_dispatch_scout(world, member_name, school_id).get("ok", false):
		return false
	if not CompanyState.consume_gold(world, SCOUT_GOLD_COST):
		return false
	var state: Dictionary = _state(world)
	var scouts: Dictionary = state.get("scouts", {})
	scouts[member_name] = {
		"school_id": school_id,
		"return_day": CompanyState.get_day_index(world) + SCOUT_TIE_DAYS,
	}
	_set_state(world, state)
	if OperationalLog.is_play_session_active():
		OperationalLog.play_world(
			(
				"scout_dispatch member=%s school=%s gold=%d return_day=%d"
				% [
					member_name,
					CompanySchool.school_display_name(school_id),
					CompanyState.get_gold(world),
					CompanyState.get_day_index(world) + SCOUT_TIE_DAYS,
				]
			)
		)
	return true


## === UI readiness ===


## Who can scout which school right now: {school_id: [member_name, ...]}. Powers UI gating so a
## schedule screen shows exactly the legal choices (downtime members only, non-revealed schools,
## away-squad ties respected).
static func scouting_candidates(world: Node) -> Dictionary:
	var out: Dictionary = {}
	if world == null:
		return out
	for sid in CompanySchool.school_ids():
		if CompanySchool.dossier_fully_revealed(world, sid):
			continue
		var ready: Array = []
		for name_s in _living_member_names(world):
			if can_dispatch_scout(world, name_s, sid).get("ok", false):
				ready.append(name_s)
		if not ready.is_empty():
			out[sid] = ready
	return out


static func _living_member_names(world: Node) -> PackedStringArray:
	var out := PackedStringArray()
	var pm: Node = CompanyState._resolve_party_manager(world)
	if pm == null:
		return out
	var members: Variant = pm.get("members")
	if not (members is Array):
		return out
	for member in members:
		if not (member is Dictionary):
			continue
		var name_s: String = str(member.get("name", ""))
		if name_s.is_empty():
			continue
		var node_ref: Variant = member.get("node_ref", null)
		if node_ref is Node:
			var n: Node = node_ref as Node
			if n.has_method("is_dead") and n.is_dead():
				continue
		out.append(name_s)
	return out


## === Return resolution (day tick) ===


## Resolve every scout who has reached their return day: drop the dispatch and advance that
## school's dossier one revealing tier. A scout who is gone (dead, deserted, or roster loss)
## is marked lost and brings back no intel. Returns per-fighter log lines. Called by
## CompanyDayCycle.on_day_tick; also safe to call directly (tests / match prep).
static func advance_scouts(world: Node) -> PackedStringArray:
	var lines := PackedStringArray()
	if world == null:
		return lines
	var state: Dictionary = _state(world)
	var scouts: Dictionary = state.get("scouts", {})
	var day: int = CompanyState.get_day_index(world)
	var due: Array = []
	for key in scouts.keys():
		var entry: Dictionary = scouts[key]
		if int(entry.get("return_day", -1)) > day:
			continue
		due.append({"member_name": str(key), "school_id": str(entry.get("school_id", ""))})
	if due.is_empty():
		return lines
	for row in due:
		scouts.erase(row["member_name"])
	_set_state(world, state)
	var returning_schools: Dictionary = {}
	for row in due:
		var member_name: String = str(row["member_name"])
		var school_id: String = str(row["school_id"])
		var scout_node: Node = _resolve_member_node_by_name(world, member_name)
		if scout_node == null or (scout_node.has_method("is_dead") and scout_node.is_dead()):
			if OperationalLog.is_play_session_active():
				OperationalLog.play_world(
					"scout_no_return member=%s school=%s"
					% [member_name, CompanySchool.school_display_name(school_id)]
				)
			continue
		returning_schools[school_id] = true
		if OperationalLog.is_play_session_active():
			OperationalLog.play_world(
				"scout_return member=%s school=%s day=%d"
				% [member_name, CompanySchool.school_display_name(school_id), day]
			)
	for sid in returning_schools.keys():
		if not CompanySchool.has_school(sid):
			continue
		lines.append_array(CompanySchool.advance_dossier_reveal(world, sid))
	return lines


static func _resolve_member_node_by_name(world: Node, member_name: String) -> Node:
	if world == null or member_name.is_empty():
		return null
	return CompanyState._resolve_member_node_by_name(world, member_name)