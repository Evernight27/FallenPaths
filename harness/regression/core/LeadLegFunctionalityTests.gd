class_name LeadLegFunctionalityTests
extends CombatRegressionHarnessCore


## Lead/trail foot asymmetry (Tier 2.1): the lead leg drives the step into a strike, so a
## compromised lead leg slows wind-up more than an equally damaged trail leg. D001-neutral at
## healthy values (all legs at full bone -> 1.0).
static func _run_lead_leg_functionality_symmetric_vs_lead(failures: PackedStringArray) -> void:
	# Healthy entity: lead-leg value == symmetric blend == 1.0.
	var e := _new_entity("SWORD")
	var sym_healthy: float = BodyPartQuery.get_leg_functionality(e)
	var lead_healthy: float = BodyPartQuery.get_leg_functionality_for(e, e.lead_leg)
	if not is_equal_approx(lead_healthy, 1.0):
		_fail(failures, "lead_leg_healthy: lead-leg want 1.0 got %f" % lead_healthy)
	if not is_equal_approx(sym_healthy, 1.0):
		_fail(failures, "lead_leg_healthy: symmetric want 1.0 got %f" % sym_healthy)

	# Damage only the lead leg (bone ratio 0.4 -> factor 0.40).
	var lead: String = e.lead_leg
	_deplete_leg_bone(e, lead, 0.4)
	var lead_w: float = BodyPartQuery.get_leg_functionality_for(e, lead)
	var sym_w: float = BodyPartQuery.get_leg_functionality(e)
	if not is_equal_approx(lead_w, 0.40):
		_fail(failures, "lead_leg_wound: lead-leg want 0.40 got %f" % lead_w)
	if not (lead_w < sym_w):
		_fail(failures, "lead_leg_wound: lead-leg (%f) must be < symmetric blend (%f)" % [lead_w, sym_w])

	# Damage only the trail leg: lead-leg value must stay 1.0; symmetric blend drops.
	var e2 := _new_entity("SWORD")
	var trail2: String = (
		BodyPartConstants.PART_LEFT_LEG
		if e2.lead_leg == BodyPartConstants.PART_RIGHT_LEG
		else BodyPartConstants.PART_RIGHT_LEG
	)
	_deplete_leg_bone(e2, trail2, 0.4)
	var lead_healthy2: float = BodyPartQuery.get_leg_functionality_for(e2, e2.lead_leg)
	var sym_w2: float = BodyPartQuery.get_leg_functionality(e2)
	if not is_equal_approx(lead_healthy2, 1.0):
		_fail(failures, "trail_leg_wound: lead-leg must stay 1.0, got %f" % lead_healthy2)
	if not (sym_w2 < 1.0):
		_fail(failures, "trail_leg_wound: symmetric blend must drop below 1.0, got %f" % sym_w2)


## A fully destroyed lead leg (all channels zeroed) reports the 0.08 destroyed floor.
static func _run_lead_leg_destroyed_drive_floor(failures: PackedStringArray) -> void:
	var e := _new_entity("SWORD")
	var lead: String = e.lead_leg
	_destroy_leg(e, lead)
	var lead_d: float = BodyPartQuery.get_leg_functionality_for(e, lead)
	if not is_equal_approx(lead_d, 0.08):
		_fail(failures, "lead_leg_destroyed: want 0.08 got %f" % lead_d)


## Tier 2.1 v2 close-advance lead-leg drive: a wounded lead leg weakens the closing lunge.
## D001-neutral at 1.0; monotonic decreasing; bounded at CLOSE_ADVANCE_LEAD_LEG_MULT_MIN.
static func _run_lead_leg_close_advance_drive(failures: PackedStringArray) -> void:
	# Healthy lead leg -> exactly 1.0 (D001-neutral).
	if not is_equal_approx(CombatConstants.close_advance_lead_leg_mult(1.0), 1.0):
		_fail(failures, "close_lead_healthy: want 1.0 got %f" % CombatConstants.close_advance_lead_leg_mult(1.0))
	# Wounded lead leg -> a dip between the floor and 1.0.
	var m_wound: float = CombatConstants.close_advance_lead_leg_mult(0.4)
	if not (m_wound < 1.0 and m_wound > CombatConstants.CLOSE_ADVANCE_LEAD_LEG_MULT_MIN):
		_fail(failures, "close_lead_wound: want in (%f, 1.0) got %f"
			% [CombatConstants.CLOSE_ADVANCE_LEAD_LEG_MULT_MIN, m_wound])
	# Destroyed lead leg -> at or above the floor (never underflows).
	var m_dest: float = CombatConstants.close_advance_lead_leg_mult(0.08)
	if m_dest < CombatConstants.CLOSE_ADVANCE_LEAD_LEG_MULT_MIN - 0.001:
		_fail(failures, "close_lead_destroyed: want >= floor %f got %f"
			% [CombatConstants.CLOSE_ADVANCE_LEAD_LEG_MULT_MIN, m_dest])
	# Monotonic: more lead-leg damage -> weaker drive.
	if not (m_dest < m_wound and m_wound < 1.0):
		_fail(failures, "close_lead_monotonic: want destroyed < wounded < healthy, got %f/%f" % [m_dest, m_wound])


## Lead-leg / dominant-hand correlation (production seed path): a fighter's lead leg matches their
## dominant side, so the lead/trail asymmetry varies across the population instead of always
## right-legged. Deterministic assertion: side(lead_leg) must equal side(dominant_hand) no matter
## which way the seed's coin fell. Uses the production apply_species() path (not the harness
## deterministic path, which pins lead_leg to RIGHT).
static func _run_lead_leg_correlates_with_dominant_hand(failures: PackedStringArray) -> void:
	for i in 8:
		var e := CoreEntity.new()
		e.apply_species()
		var hand_left: bool = (e.dominant_hand == BodyPartConstants.PART_LEFT_ARM)
		var leg_left: bool = (e.lead_leg == BodyPartConstants.PART_LEFT_LEG)
		if hand_left != leg_left:
			_fail(failures, "lead_hand_corr[%d]: dominant_hand=%s lead_leg=%s (sides must match)" % [i, e.dominant_hand, e.lead_leg])
		_free_harness_node(e)


## Set a leg's bone_health to ratio * bone_max (cutting/blunt stay full so the part stays operable).
static func _deplete_leg_bone(e: Node, part: String, ratio: float) -> void:
	var mx: int = e.bone_max.get(part, 8)
	e.bone_max[part] = mx
	e.bone_health[part] = float(mx) * ratio


## Zero all three channels for a leg so is_part_physically_operable reports it destroyed.
static func _destroy_leg(e: Node, part: String) -> void:
	e.body_cutting[part] = 0.0
	e.body_blunt[part] = 0.0
	e.bone_health[part] = 0.0
