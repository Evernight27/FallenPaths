class_name ScarTests
extends CombatRegressionHarnessCore
## CAMP-SCAR-1: wound-derived scars. Part-specific penalties (§9.5) — a scarred limb carries a
## location-specific penalty on top of the universal damage/bleed/heal multipliers: leg -> move_speed,
## arm -> grip, head -> perception, chest -> stamina_pool. Plus the catalog, id+part merge/deepen, and
## the resolved-wound stash seam. All core-side (no world/party node needed).


static func _free_entity_fixture(n: Node) -> void:
	_free_harness_node(n)


## Mint a real catalog scar def onto the entity via the shared _add_campaign_affliction path.
static func _seed_scar(ent: Node, scar_id: String, part: String) -> Dictionary:
	var def: Dictionary = CampaignAfflictions.scar_def(scar_id, part)
	ent._add_campaign_affliction(def)
	return def


## No scars -> every part-specific factor is 1.0.
static func _run_scar_part_penalty_empty(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	var pen: Dictionary = ent._get_scar_part_penalty("left_leg")
	for k in pen.keys():
		if absf(float(pen[k]) - 1.0) > 1e-9:
			_fail(failures, "scar_empty: %s should be 1.0 with no scars (got %s)" % [k, str(pen[k])])
	_free_entity_fixture(ent)


## A malunited-bone leg scar reduces whole-locomotion functionality + effective move speed.
static func _run_leg_scar_reduces_leg_functionality(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	_seed_scar(scarred, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
	var f_clean: float = clean._get_leg_functionality()
	var f_scar: float = scarred._get_leg_functionality()
	if not (f_scar < f_clean):
		_fail(failures, "scar_leg: leg functionality should drop with a malunited leg (%.3f vs clean %.3f)" % [f_scar, f_clean])
	var s_clean: int = clean._get_effective_speed()
	var s_scar: int = scarred._get_effective_speed()
	if not (s_scar <= s_clean):
		_fail(failures, "scar_leg_speed: effective speed should not increase with a scarred leg (%d vs clean %d)" % [s_scar, s_clean])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)


## A Volkmann ischemic-contracture arm scar reduces weapon-handling (grip) functionality.
static func _run_arm_scar_reduces_grip(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	_seed_scar(scarred, CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE, "right_arm")
	var g_clean: float = BodyPartQuery.get_arm_functionality(clean, "right_arm")
	var g_scar: float = BodyPartQuery.get_arm_functionality(scarred, "right_arm")
	if not (g_scar < g_clean):
		_fail(failures, "scar_arm: arm functionality should drop with a contracture (%.3f vs clean %.3f)" % [g_scar, g_clean])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)


## A scarred head reduces the performance (perception) modifier.
static func _run_head_scar_reduces_perception(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	_seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "head")
	var p_clean: float = EntityPainConsciousness.get_performance_modifier(clean)
	var p_scar: float = EntityPainConsciousness.get_performance_modifier(scarred)
	if not (p_scar < p_clean):
		_fail(failures, "scar_head: performance modifier should drop with a head scar (%.3f vs clean %.3f)" % [p_scar, p_clean])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)


## A scarred chest reduces the campaign stamina pool multiplier.
static func _run_chest_scar_reduces_stamina(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	_seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "chest")
	var m_clean: float = clean._get_campaign_stamina_mult()
	var m_scar: float = scarred._get_campaign_stamina_mult()
	if not (m_scar < m_clean):
		_fail(failures, "scar_chest: stamina mult should drop with a chest scar (%.3f vs clean %.3f)" % [m_scar, m_clean])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)


## A part-scoped damage_mult affects only the scarred part (the stored part actually matters).
static func _run_scar_damage_mult_part_scoped(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	_seed_scar(ent, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
	var d_sc: float = ent._get_scar_damage_mult("left_leg")
	var d_other: float = ent._get_scar_damage_mult("right_leg")
	if d_sc <= 1.0:
		_fail(failures, "scar_scope: scarred-part damage_mult should be > 1.0 (got %.3f)" % d_sc)
	if d_other != 1.0:
		_fail(failures, "scar_scope: non-scarred part damage_mult should be 1.0 (got %.3f)" % d_other)
	_free_entity_fixture(ent)


## A second severe wound on an already-scarred part DEEPENS the scar (id+part merge), not no-ops.
static func _run_scar_deepens_on_merge(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	_seed_scar(ent, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
	var d_first: float = ent._get_scar_damage_mult("left_leg")
	# Re-mint the same id+part: _add_campaign_affliction deepens (returns false = already present).
	var added: bool = ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg"))
	var d_second: float = ent._get_scar_damage_mult("left_leg")
	if added:
		_fail(failures, "scar_deepen: re-mint of an existing id+part should deepen, not add a new entry (added=true)")
	if not (d_second > d_first):
		_fail(failures, "scar_deepen: damage_mult should deepen on re-mint (%.3f vs first %.3f)" % [d_second, d_first])
	_free_entity_fixture(ent)


## A deepened scar also heals WORSE (heal_mult moves further below 1.0), not faster: re-injuring
## hypovascular scar tissue impairs the remodeling phase (reduced tensile strength / extensibility,
## same anchor as SCAR_REINJURY_MULT). Directional pin for the deepen path — heals slower, never
## toward 1.0.
static func _run_scar_heal_deepens_worse(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	_seed_scar(ent, CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
	var h_first: float = ent._get_scar_heal_mult("left_leg")
	if h_first >= 1.0:
		_fail(failures, "scar_heal_deepen: baseline heal_mult should be < 1.0 (got %.3f)" % h_first)
	ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg"))
	var h_second: float = ent._get_scar_heal_mult("left_leg")
	if not (h_second < h_first):
		_fail(failures, "scar_heal_deepen: heal_mult should get WORSE (lower) on re-mint (%.3f vs first %.3f)" % [h_second, h_first])
	_free_entity_fixture(ent)


## The catalog emits the part-specific keys only for the matching part category.
static func _run_catalog_has_part_keys(failures: PackedStringArray) -> void:
	var leg: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
	if not ("move_speed" in leg and float(leg["move_speed"]) < 1.0):
		_fail(failures, "catalog_leg: malunited leg should carry move_speed < 1.0 (got %s)" % str(leg.get("move_speed")))
	var arm: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE, "right_arm")
	if not ("grip" in arm and float(arm["grip"]) < 1.0):
		_fail(failures, "catalog_arm: contracture arm should carry grip < 1.0 (got %s)" % str(arm.get("grip")))
	var head: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "head")
	if not ("perception" in head and float(head["perception"]) < 1.0):
		_fail(failures, "catalog_head: head scar should carry perception < 1.0 (got %s)" % str(head.get("perception")))
	var chest: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "chest")
	if not ("stamina_pool" in chest and float(chest["stamina_pool"]) < 1.0):
		_fail(failures, "catalog_chest: chest scar should carry stamina_pool < 1.0 (got %s)" % str(chest.get("stamina_pool")))
	# A whole-body scar (part "") carries no part-specific keys.
	var whole: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_POST_SEPSIS_WEAKNESS, "")
	for k in ["move_speed", "grip", "perception", "stamina_pool"]:
		if k in whole:
			_fail(failures, "catalog_whole: whole-body scar should not carry %s" % k)


## The resolved-wound stash seam: stash descriptors, then clear on advance.
static func _run_stash_and_clear_resolved_wounds(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	if ent.resolved_wounds_this_advance.size() != 0:
		_fail(failures, "stash: should start empty")
	ent._stash_resolved_wound({"part": "left_leg", "severity": "severe", "is_compound_fracture": true, "is_osteomyelitis": true, "was_infected": true})
	if ent.resolved_wounds_this_advance.size() != 1:
		_fail(failures, "stash: should hold one descriptor (got %d)" % ent.resolved_wounds_this_advance.size())
	var d0: Dictionary = ent.resolved_wounds_this_advance[0]
	if str(d0.get("part", "")) != "left_leg" or not bool(d0.get("is_osteomyelitis", false)):
		_fail(failures, "stash: descriptor fields should round-trip (got %s)" % str(d0))
	ent.clear_resolved_wounds()
	if ent.resolved_wounds_this_advance.size() != 0:
		_fail(failures, "stash: clear_resolved_wounds should empty the stash (got %d)" % ent.resolved_wounds_this_advance.size())
	_free_entity_fixture(ent)


## The health-system clock must survive save/load: without it, every saved wound's age
## collapses (age = clock - created_at) and it heals as freshly made.
static func _run_health_clock_round_trip(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	# A wound aged 2400s of a 3600s healing duration (created at 1200, clock at 3600).
	ent.wounds["left_leg"] = [
		{"created_at_game_time": 1200.0, "healing_duration_seconds": 3600.0, "severity": "severe", "injury_type": "cut"},
	]
	ent._game_time_seconds = 3600.0
	var wound: Dictionary = ent.wounds["left_leg"][0]
	var before: float = ent._get_wound_healing_progress(wound)
	if before <= 0.0:
		_fail(failures, "persist_clock: pre-save healing progress should be > 0 (got %.4f)" % before)
	var serialized: Dictionary = CampaignPersistence._serialize_entity(ent)
	if absf(float(serialized.get("game_time_seconds", -1.0)) - 3600.0) > 1e-6:
		_fail(failures, "persist_clock: game_time_seconds should serialize as 3600 (got %s)" % str(serialized.get("game_time_seconds")))
	var fresh: Node = _new_entity("SWORD")
	CampaignPersistence._apply_entity(fresh, serialized)
	if absf(float(fresh._game_time_seconds) - 3600.0) > 1e-6:
		_fail(failures, "persist_clock: restored _game_time_seconds should be 3600 (got %.1f)" % fresh._game_time_seconds)
	var rwound: Dictionary = fresh.wounds["left_leg"][0]
	var after: float = fresh._get_wound_healing_progress(rwound)
	if absf(after - before) > 1e-6:
		_fail(failures, "persist_clock: wound healing progress should survive the round-trip (before %.4f, after %.4f)" % [before, after])
	_free_entity_fixture(ent)
	_free_entity_fixture(fresh)


## Entity-level sepsis / tetanus state (survives the seeding wound resolving) must round-trip.
static func _run_systemic_infection_round_trip(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent.is_septic = true
	ent.sepsis_resolve_progress = 0.4
	ent.sepsis_recovered = true
	ent.is_tetanus = true
	ent.tetanus_incubation_days = 7.5
	ent.tetanus_resolve_progress = 0.3
	var serialized: Dictionary = CampaignPersistence._serialize_entity(ent)
	for k in ["is_septic", "sepsis_resolve_progress", "sepsis_recovered", "is_tetanus", "tetanus_incubation_days", "tetanus_resolve_progress"]:
		if not serialized.has(k):
			_fail(failures, "persist_sys: %s should be serialized" % k)
	var fresh: Node = _new_entity("SWORD")
	CampaignPersistence._apply_entity(fresh, serialized)
	if fresh.is_septic != true:
		_fail(failures, "persist_sys: restored is_septic should be true (got %s)" % str(fresh.is_septic))
	if absf(float(fresh.sepsis_resolve_progress) - 0.4) > 1e-6:
		_fail(failures, "persist_sys: restored sepsis_resolve_progress should be 0.4 (got %.3f)" % fresh.sepsis_resolve_progress)
	if fresh.sepsis_recovered != true:
		_fail(failures, "persist_sys: restored sepsis_recovered should be true")
	if fresh.is_tetanus != true:
		_fail(failures, "persist_sys: restored is_tetanus should be true (got %s)" % str(fresh.is_tetanus))
	if absf(float(fresh.tetanus_incubation_days) - 7.5) > 1e-6:
		_fail(failures, "persist_sys: restored tetanus_incubation_days should be 7.5 (got %.2f)" % fresh.tetanus_incubation_days)
	# A clean entity must not pick up systemic state from an empty/old save (defaults stay).
	var clean: Node = _new_entity("SWORD")
	CampaignPersistence._apply_entity(clean, {})
	if clean.is_septic or clean.is_tetanus or absf(float(clean.tetanus_incubation_days) - (-1.0)) > 1e-9:
		_fail(failures, "persist_sys_defaults: empty apply should leave systemic state at defaults (septic=%s tetanus=%s inc=%s)" % [str(clean.is_septic), str(clean.is_tetanus), str(clean.tetanus_incubation_days)])
	_free_entity_fixture(ent)
	_free_entity_fixture(fresh)
	_free_entity_fixture(clean)


## CAMP-SCAR-1 §9.3: a wound landing on a scarred part is rated one severity band worse
## (SCAR_REINJURY_MULT) than the same wound on a clean part.
static func _run_scar_reinjury_severity(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	_seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
	# With FEATURE_ABSOLUTE_SEVERITY_PCT_CAP off, severity is governed by absolute tissue damage
	# (MODERATE at 2.0, SEVERE at 5.0). Penetration 6.0mm => depth_mult 1.0, "thigh" => sub_mult 1.0,
	# so the only variable is the scar re-injury mult: clean 4.5 (MODERATE) vs scarred 4.5*1.15=5.175
	# (SEVERE) — the 15% bump crosses the band.
	var dmg: float = 4.5
	var sub: String = "thigh"
	var sev_clean: String = EntityWounds.severity_from_damage(clean, "left_leg", dmg, sub, -1.0, 6.0)
	var sev_scar: String = EntityWounds.severity_from_damage(scarred, "left_leg", dmg, sub, -1.0, 6.0)
	var rank_clean: int = EntityWounds._severity_rank(sev_clean)
	var rank_scar: int = EntityWounds._severity_rank(sev_scar)
	if rank_scar <= rank_clean:
		_fail(failures, "scar_reinjury: scarred part should land worse severity (%s vs clean %s)" % [sev_scar, sev_clean])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)


## Amputation: a severed limb mints a permanent amputated_limb scar (idempotent per part).
static func _run_amputation_mints_scar(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent.body_cutting["left_leg"] = 0.0
	ent.body_blunt["left_leg"] = 0.0
	if "bone_health" in ent:
		ent.bone_health["left_leg"] = 0.0
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var found: bool = false
	for aff in ent.campaign_afflictions:
		if aff is Dictionary and str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB and str(aff.get("part", "")) == "left_leg":
			found = true
			break
	if not found:
		_fail(failures, "amputation: severed limb should mint an amputated_limb scar (afflictions: %s)" % str(ent.campaign_afflictions))
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var count: int = 0
	for aff in ent.campaign_afflictions:
		if aff is Dictionary and str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB and str(aff.get("part", "")) == "left_leg":
			count += 1
	if count != 1:
		_fail(failures, "amputation: should have exactly 1 amputated_limb entry (got %d)" % count)
	_free_entity_fixture(ent)


## A severed limb should not also receive a per-wound scar (scarred_tissue etc.) when its
## stump wound resolves — the amputated_limb scar is the sole chronic record for that part.
static func _run_severed_part_skips_wound_scar(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent.body_cutting["left_leg"] = 0.0
	ent.body_blunt["left_leg"] = 0.0
	if "bone_health" in ent:
		ent.bone_health["left_leg"] = 0.0
	# Simulate a resolved wound descriptor on the severed part
	ent._stash_resolved_wound({"part": "left_leg", "severity": "critical", "was_infected": true})
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	# amputated_limb should be present
	var has_amp: bool = false
	var has_scarred: bool = false
	for aff in ent.campaign_afflictions:
		if aff is Dictionary:
			if str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB and str(aff.get("part", "")) == "left_leg":
				has_amp = true
			if str(aff.get("id", "")) == CampaignAfflictions.SCAR_SCARRED_TISSUE and str(aff.get("part", "")) == "left_leg":
				has_scarred = true
	if not has_amp:
		_fail(failures, "severed_skip: amputated_limb should be minted for severed part")
	if has_scarred:
		_fail(failures, "severed_skip: scarred_tissue should NOT be minted for a severed part")
	_free_entity_fixture(ent)


## Closed injuries do not remodel into soft-tissue scar, so they never mint `scarred_tissue`:
## a resolving severe bruise (closed contusion resorbs wholly) and a clean severe non-compound
## fracture (heals with internal bone callus; malunion models exposed bone only) mint nothing on
## resolution, even when infected — while an open severe cut (and the other open muscle/tissue
## types) still mint. Gated on the descriptor's injury_type on both the infected and the
## clean-severe paths.
static func _run_closed_injuries_mint_no_wound_scar(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent._stash_resolved_wound({"part": "left_leg", "severity": "severe",
		"injury_type": BleedingConstants.INJURY_TYPE_BRUISE})
	ent._stash_resolved_wound({"part": "right_leg", "severity": "severe",
		"injury_type": BleedingConstants.INJURY_TYPE_FRACTURE})
	ent._stash_resolved_wound({"part": "left_arm", "severity": "severe", "was_infected": true,
		"injury_type": BleedingConstants.INJURY_TYPE_BRUISE})
	ent._stash_resolved_wound({"part": "right_arm", "severity": "severe",
		"injury_type": BleedingConstants.INJURY_TYPE_CUT})
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var has_control: bool = false
	for aff in ent.campaign_afflictions:
		if aff is Dictionary and str(aff.get("id", "")) == CampaignAfflictions.SCAR_SCARRED_TISSUE:
			match str(aff.get("part", "")):
				"left_leg":
					_fail(failures, "closed: a resolving severe bruise should mint no scarred_tissue")
				"right_leg":
					_fail(failures, "closed: a resolving clean severe fracture should mint no scarred_tissue")
				"left_arm":
					_fail(failures, "closed: an infected bruise should mint no scarred_tissue (closed injury)")
				"right_arm":
					has_control = true
	if not has_control:
		_fail(failures, "closed: an open severe cut should still mint scarred_tissue (control)")
	_free_entity_fixture(ent)


## A new wound on an already-scarred part closes slower: `EntityWounds.add_wound` scales the
## resolution duration by 1 / _get_scar_heal_mult(part) (hypovascular scar tissue lengthens the
## remodeling phase), so the wound's healing-progress arithmetic reaches the resolution threshold
## later. A severed part keeps the canonical duration (its amputation scar prunes the part scars).
static func _run_scarred_part_wound_resolves_slower(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	scarred._add_campaign_affliction(
		CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
	)
	EntityWounds.add_wound(
		clean, "left_leg", BleedingConstants.INJURY_TYPE_CUT, 5.0, "", BleedingConstants.SEVERITY_SEVERE
	)
	EntityWounds.add_wound(
		scarred, "left_leg", BleedingConstants.INJURY_TYPE_CUT, 5.0, "", BleedingConstants.SEVERITY_SEVERE
	)
	var clean_dur: float = float(clean.wounds["left_leg"][0].get("healing_duration_seconds", 0.0))
	var scarred_dur: float = float(scarred.wounds["left_leg"][0].get("healing_duration_seconds", 0.0))
	var heal_h: float = float(
		CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg").get("heal_mult", 1.0)
	)
	if scarred_dur <= clean_dur:
		_fail(failures, "scar_resolve: scarred-part wound should resolve SLOWER (longer duration)")
	if absf(scarred_dur - clean_dur / heal_h) > 1e-6:
		_fail(failures, "scar_resolve: scarred duration %.3f should be clean %.3f / heal %.3f"
				% [scarred_dur, clean_dur, heal_h])
	var severed: Node = _new_entity("SWORD")
	severed.body_cutting["left_leg"] = 0.0
	severed.body_blunt["left_leg"] = 0.0
	if "bone_health" in severed:
		severed.bone_health["left_leg"] = 0.0
	severed._add_campaign_affliction(
		CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
	)
	EntityWounds.add_wound(
		severed, "left_leg", BleedingConstants.INJURY_TYPE_CUT, 5.0, "", BleedingConstants.SEVERITY_SEVERE
	)
	var severed_dur: float = float(severed.wounds["left_leg"][0].get("healing_duration_seconds", 0.0))
	if absf(severed_dur - clean_dur) > 1e-6:
		_fail(failures, "scar_resolve: severed-part stump wound should keep the canonical duration "
				+ "(got %.3f vs clean %.3f)" % [severed_dur, clean_dur])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)
	_free_entity_fixture(severed)


## A severed limb never feeds the post-victory bone-cripple roll: `_worst_bone_part` skips parts
## whose bone is zeroed (a limb severed in the fight would otherwise read as the worst crippled bone
## and roll "Limping left_leg" for a limb that no longer exists — its chronic state is the
## amputated_limb scar, minted on the next advance), falling through to an attached <25% bone
## instead. When no surviving bone is crippled, the roll yields nothing on every seed.
static func _run_severed_bone_part_not_bone_crippled(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent.body_cutting["left_leg"] = 0.0
	ent.body_blunt["left_leg"] = 0.0
	if "bone_health" in ent:
		ent.bone_health["left_leg"] = 0.0
	if "bone_max" in ent:
		ent.bone_max["left_leg"] = 100.0
		ent.bone_max["chest"] = 100.0
		ent.bone_health["chest"] = 20.0
	ent.blood_volume = 100.0
	var worst: String = CampaignAfflictions._worst_bone_part(ent)
	if worst != "chest":
		_fail(failures, "bone_roll: severed left_leg should be skipped, worst surviving bone is chest (got %s)" % worst)
	if CampaignAfflictions._bone_affliction_id(worst) != CampaignAfflictions.AFFLICTION_CRACKED_RIBS:
		_fail(failures, "bone_roll: chest bone should map to cracked_ribs (got %s)"
				% CampaignAfflictions._bone_affliction_id(worst))
	var only_severed: Node = _new_entity("SWORD")
	only_severed.body_cutting["right_leg"] = 0.0
	only_severed.body_blunt["right_leg"] = 0.0
	if "bone_health" in only_severed:
		only_severed.bone_health["right_leg"] = 0.0
	if "bone_max" in only_severed:
		only_severed.bone_max["right_leg"] = 100.0
	only_severed.blood_volume = 100.0
	if not CampaignAfflictions._worst_bone_part(only_severed).is_empty():
		_fail(failures, "bone_roll: only a severed bone -> no surviving crippled bone")
	for s in [1, 2, 3, 4, 5]:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = s
		var roll: Dictionary = CampaignAfflictions._roll_affliction_for_entity(only_severed, only_severed, rng)
		if not roll.is_empty():
			_fail(failures, "bone_roll: severed-only member should roll no affliction (seed %d got %s)"
					% [s, str(roll.get("id", "?"))])
	_free_entity_fixture(ent)
	_free_entity_fixture(only_severed)


## Post-victory tier roll: the arterial-fail cause (0.55) must name the affliction, not a coexisting
## crippled bone (0.45). The old code had the bone branch unconditionally overwrite `pick`, so a member
## with 2+ untreated arterial wounds AND a <25% bone rolled "Limping left_leg" / "Shaky grip" /
## "Cracked ribs" at the 0.55 arterial gate instead of slowed_circulation (arterial fail).
static func _run_affliction_roll_arterial_wins_over_bone(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent.blood_volume = 100.0
	if "bone_health" in ent:
		ent.bone_health["left_leg"] = 20.0
	if "bone_max" in ent:
		ent.bone_max["left_leg"] = 100.0
	ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.0, "severity": "critical", "is_arterial": true},
		{"current_bleeding_rate": 0.0, "severity": "critical", "is_arterial": true},
	]
	if CampaignAfflictions._worst_bone_part(ent) != "left_leg":
		_fail(failures, "arterial_bone_roll: left_leg bone should be the worst crippled bone")
	if CampaignAfflictions._count_untreated_arterial(ent) != 2:
		_fail(failures, "arterial_bone_roll: expected 2 untreated arterial wounds (got %d)"
				% CampaignAfflictions._count_untreated_arterial(ent))
	var bone_names: Array = [
		CampaignAfflictions.AFFLICTION_LIMPING_LIMB,
		CampaignAfflictions.AFFLICTION_SHAKY_GRIP,
		CampaignAfflictions.AFFLICTION_CRACKED_RIBS,
	]
	var fired: int = 0
	for s in range(1, 65):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = s
		var roll: Dictionary = CampaignAfflictions._roll_affliction_for_entity(ent, ent, rng)
		if roll.is_empty():
			continue
		fired += 1
		var id: String = str(roll.get("id", ""))
		if bone_names.has(id):
			_fail(failures, "arterial_bone_roll: arterial gate named a bone affliction (seed %d got %s)"
					% [s, id])
		elif id != CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION:
			_fail(failures, "arterial_bone_roll: unexpected affliction (seed %d got %s)" % [s, id])
	if fired == 0:
		_fail(failures, "arterial_bone_roll: no rolls fired across seeds (gate never exercised)")
	_free_entity_fixture(ent)


class _StruckDownProxy extends Node:
	var _unconscious: bool = true
	func is_unconscious() -> bool:
		return _unconscious


## Post-victory tier roll: an unconscious member in the danger blood band keeps the struck-down cause
## (0.33). The old code had the danger branch (0.12) overwrite `pick`, naming "Partly collapsed lung" or
## "Old wound ache" at the struck-down 0.33 gate.
static func _run_affliction_roll_struck_down_wins_over_danger(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent.blood_volume = 56.0  # danger band (< 58, >= peril 55)
	var proxy: _StruckDownProxy = _StruckDownProxy.new()
	if not (ent.blood_volume < BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING):
		_fail(failures, "struck_down_roll: fixture blood must sit in the danger band")
	if not (ent.blood_volume >= BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING):
		_fail(failures, "struck_down_roll: fixture blood must not sit in the peril band")
	if not proxy.is_unconscious():
		_fail(failures, "struck_down_roll: proxy must report unconscious")
	var fired: int = 0
	for s in range(1, 65):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = s
		var roll: Dictionary = CampaignAfflictions._roll_affliction_for_entity(ent, proxy, rng)
		if roll.is_empty():
			continue
		fired += 1
		var id: String = str(roll.get("id", ""))
		if id != CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION:
			_fail(failures, "struck_down_roll: danger band relabeled a struck-down roll (seed %d got %s)"
					% [s, id])
	if fired == 0:
		_fail(failures, "struck_down_roll: no rolls fired across seeds (gate never exercised)")
	proxy.free()
	_free_entity_fixture(ent)


## CAMP-SCAR-1 (infection-clear intersection): when a dressing cures an infected wound, the resolution
## clock is recomputed from the pre-infection baseline — and that baseline on a scarred part must
## include the scar slow-down shared through `EntityWounds.scaled_healing_duration_seconds`. Otherwise
## a scarred limb that got infected would heal FASTER than the identical scarred limb that stayed clean
## (raw base vs base/scar_heal_mult). Clean part -> raw base; scarred part -> base / scar_heal_mult;
## severed stump -> raw base (canonical, amputation scar is its chronic state).
static func _run_scarred_infection_clear_keeps_slowdown(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	var severed: Node = _new_entity("SWORD")
	var b: float = HealingConstants.get_wound_healing_duration_seconds(
		"left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
	)
	var d_clean: float = EntityWounds.scaled_healing_duration_seconds(
		clean, "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
	)
	if absf(d_clean - b) > 1e-6:
		_fail(failures, "inf_clear: clean baseline must be the raw base (%.3f vs %.3f)" % [d_clean, b])
	_seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
	var scar_h: float = float(scarred._get_scar_heal_mult("left_leg"))
	var d_scar: float = EntityWounds.scaled_healing_duration_seconds(
		scarred, "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
	)
	if absf(d_scar - b / scar_h) > 1e-6:
		_fail(failures, "inf_clear: a cured scarred wound must still close at base/scar_heal_mult (%.3f vs %.3f)"
				% [d_scar, b / scar_h])
	severed.body_cutting["left_leg"] = 0.0
	severed.body_blunt["left_leg"] = 0.0
	if "bone_health" in severed:
		severed.bone_health["left_leg"] = 0.0
	var d_sev: float = EntityWounds.scaled_healing_duration_seconds(
		severed, "left_leg", BleedingConstants.SEVERITY_SEVERE, BleedingConstants.INJURY_TYPE_CUT
	)
	if absf(d_sev - b) > 1e-6:
		_fail(failures, "inf_clear: severed stump baseline must stay raw base (%.3f vs %.3f)" % [d_sev, b])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)
	_free_entity_fixture(severed)


## The post-sepsis weakness scar is the convalescent aftermath: minted only after recovery (latched
## sepsis_recovered, is_septic already false), NEVER while actively septic — a member still septic or
## dead of sepsis must not carry the "post-sepsis" label. id-dedup (part "") prevents re-mints on
## later advances.
static func _run_post_sepsis_weakness_only_after_recovery(failures: PackedStringArray) -> void:
	var active: Node = _new_entity("SWORD")
	active.is_septic = true
	active.sepsis_recovered = false
	CampaignAfflictions._mint_scars_for_entity(active, "Test", null, null)
	if active.campaign_afflictions.size() > 0:
		_fail(failures, "postsepsis: an actively-septic member must not mint the recovery scar (got %s)"
				% str(active.campaign_afflictions))
	var recovered: Node = _new_entity("SWORD")
	recovered.is_septic = false
	recovered.sepsis_recovered = true
	CampaignAfflictions._mint_scars_for_entity(recovered, "Test", null, null)
	if not (recovered.campaign_afflictions.size() == 1
			and str(recovered.campaign_afflictions[0].get("id", "")) == CampaignAfflictions.SCAR_POST_SEPSIS_WEAKNESS):
		_fail(failures, "postsepsis: a recovered member must mint exactly one post-sepsis weakness scar (got %s)"
				% str(recovered.campaign_afflictions))
	CampaignAfflictions._mint_scars_for_entity(recovered, "Test", null, null)
	if recovered.campaign_afflictions.size() != 1:
		_fail(failures, "postsepsis: id-dedup must prevent re-minting on a later advance")
	var dead: Node = _new_entity("SWORD")
	dead.is_septic = false
	dead.sepsis_recovered = true
	dead._sepsis_dead = true
	CampaignAfflictions._mint_scars_for_entity(dead, "Test", null, null)
	if dead.campaign_afflictions.size() > 0:
		_fail(failures, "postsepsis: a sepsis-dead member must not carry the recovery scar")
	_free_entity_fixture(active)
	_free_entity_fixture(recovered)
	_free_entity_fixture(dead)


## The dead do not mint: a death-registered member (sepsis or tetanus death flag) who still carries a
## resolved-wound stash must not accrue permanent afflictions on a later op-log pass — corpse
## bookkeeping drains the stash without minting a single scar.
static func _run_dead_member_mints_nothing(failures: PackedStringArray) -> void:
	for dflag in ["_sepsis_dead", "_tetanus_dead"]:
		var dead: Node = _new_entity("SWORD")
		dead.set(dflag, true)
		dead.is_septic = false
		dead.sepsis_recovered = true
		dead._stash_resolved_wound({"part": "left_arm", "severity": BleedingConstants.SEVERITY_SEVERE,
				"injury_type": BleedingConstants.INJURY_TYPE_CUT, "is_compound_fracture": false,
				"is_osteomyelitis": false, "was_infected": true})
		CampaignAfflictions._mint_scars_for_entity(dead, "Test", null, null)
		if dead.campaign_afflictions.size() > 0:
			_fail(failures, "dead_mint[%s]: a dead member must mint no afflictions (got %s)"
					% [dflag, str(dead.campaign_afflictions)])
		if dead.resolved_wounds_this_advance.size() != 0:
			_fail(failures, "dead_mint[%s]: a dead member's resolved-stash should still be drained" % dflag)
		_free_entity_fixture(dead)


## The scar/affliction line suffix renders a real SIGNED delta, not a terse remaining-value
## ("Stamina - - 85%" misreads as an 85% loss): 0.88 -> "Stamina -12%", 1.05 pain -> "Pain +5%",
## neutral multipliers emit no fragment.
static func _run_scar_line_effect_suffix_signed(failures: PackedStringArray) -> void:
	var ribs: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_CRACKED_RIBS, "chest")
	var suf_ribs: String = CampaignAfflictions.format_scar_line("Test", ribs)
	if not suf_ribs.contains("Stamina -12%") or not suf_ribs.contains("Pain +5%"):
		_fail(failures, "suffix: cracked_ribs should read 'Stamina -12%, Pain +5%' (got %s)" % suf_ribs)
	var ache: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_OLD_WOUND_ACHE, "")
	var suf_ache: String = CampaignAfflictions.format_scar_line("Test", ache)
	if not suf_ache.contains("Pain +8%") or suf_ache.contains("Stamina"):
		_fail(failures, "suffix: old_wound_ache should read only 'Pain +8%' (got %s)" % suf_ache)
	var slow: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION, "")
	var suf_slow: String = CampaignAfflictions.format_scar_line("Test", slow)
	if not suf_slow.contains("Stamina -10%"):
		_fail(failures, "suffix: slowed_circulation 0.90 should read 'Stamina -10%' (got %s)" % suf_slow)
	if suf_slow.contains(" - - "):
		_fail(failures, "suffix: no remaining-value double-dash form may survive (got %s)" % suf_slow)
	var flat: Dictionary = {"id": "x", "label": "x", "stamina_mult": 1.0, "pain_mult": 1.0}
	if not CampaignAfflictions.format_scar_line("Test", flat).ends_with("  -  x"):
		_fail(failures, "suffix: neutral multipliers must produce no suffix fragment")
	var deep_scar: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "chest")
	var suf_scar: String = CampaignAfflictions.format_scar_line("Test", deep_scar)
	if not suf_scar.contains("Pain +3%"):
		_fail(failures, "suffix: scarred_tissue pain 1.03 should read 'Pain +3%' (got %s)" % suf_scar)


## The post-victory RNG bone afflictions carry their `part` AND a modest sited penalty (move_speed /
## grip / stamina_pool, 0.95) through the SAME scar reader the wound-derived catalog uses: a "Limping
## right_leg" actually slows gait (named functional cost is real), while whole-body stamina stays in
## the tuned 5-10% band. Non-bone afflictions (old_wound_ache, slowed_circulation) stay pure / part "".
static func _run_bone_afflictions_carry_sited_penalty(failures: PackedStringArray) -> void:
	var limp: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_LIMPING_LIMB, "right_leg")
	if absf(float(limp.get("move_speed", 1.0)) - 0.95) > 1e-9 \
			or absf(float(limp.get("stamina_mult", 1.0)) - 0.92) > 1e-9:
		_fail(failures, "sited: limping_limb should carry move_speed 0.95 on top of stamina 0.92")
	var grip: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_SHAKY_GRIP, "left_arm")
	if absf(float(grip.get("grip", 1.0)) - 0.95) > 1e-9 \
			or absf(float(grip.get("stamina_mult", 1.0)) - 0.94) > 1e-9:
		_fail(failures, "sited: shaky_grip should carry grip 0.95 on top of stamina 0.94")
	var ribs: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_CRACKED_RIBS, "chest")
	if absf(float(ribs.get("stamina_pool", 1.0)) - 0.95) > 1e-9 \
			or absf(float(ribs.get("stamina_mult", 1.0)) - 0.88) > 1e-9:
		_fail(failures, "sited: cracked_ribs should carry stamina_pool 0.95 on top of stamina 0.88")
	var ache: Dictionary = CampaignAfflictions._affliction_def(CampaignAfflictions.AFFLICTION_OLD_WOUND_ACHE, "")
	if "move_speed" in ache or "grip" in ache or "stamina_pool" in ache or str(ache.get("part", "")) != "":
		_fail(failures, "sited: old_wound_ache is a whole-body pain condition, must carry no sited penalty or part")
	var ent: Node = _new_entity("SWORD")
	ent._add_campaign_affliction(limp)
	ent._add_campaign_affliction(grip)
	ent._add_campaign_affliction(ribs)
	var lp: Dictionary = ent._get_scar_part_penalty("right_leg")
	var gp: Dictionary = ent._get_scar_part_penalty("left_arm")
	var cp: Dictionary = ent._get_scar_part_penalty("chest")
	if absf(float(lp.get("move_speed", 1.0)) - 0.95) > 1e-9:
		_fail(
			failures,
			"sited: scar reader should apply move_speed 0.95 to the limping leg (got %.3f)"
			% float(lp.get("move_speed", 1.0))
		)
	if absf(float(gp.get("grip", 1.0)) - 0.95) > 1e-9:
		_fail(
			failures,
			"sited: scar reader should apply grip 0.95 to the shaky arm (got %.3f)"
			% float(gp.get("grip", 1.0))
		)
	if absf(float(cp.get("stamina_pool", 1.0)) - 0.95) > 1e-9:
		_fail(
			failures,
			"sited: scar reader should apply stamina_pool 0.95 to the cracked chest (got %.3f)"
			% float(cp.get("stamina_pool", 1.0))
		)
	var leg_frac: float = ent._get_leg_functionality()
	if absf(leg_frac - 0.95) > 1e-6:
		_fail(failures, "sited: a limping right leg should slow whole-locomotion to ~0.95 (got %.3f)" % leg_frac)
	# Separate axes: per-part penalties sit on the part, whole-body stamina stays exactly in-band.
	var sm: float = ent._get_campaign_stamina_mult()
	if absf(sm - 0.92 * 0.94 * 0.88 * 0.95) > 1e-6:
		_fail(failures, "sited: stamina mult should be whole-body product + chest pool (got %.4f)" % sm)
	_free_entity_fixture(ent)


## The amputation supersedes the limb's prior injuries: minting amputated_limb prunes earlier
## same-part scars and bone afflictions (their multipliers are moot on a severed part and their
## labels would double-list beside "Amputated {part}"), while whole-body afflictions are untouched.
static func _run_amputation_prunes_same_part_afflictions(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg"))
	ent._add_campaign_affliction(CampaignAfflictions.catalog_def(CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION))
	ent.body_cutting["left_leg"] = 0.0
	ent.body_blunt["left_leg"] = 0.0
	if "bone_health" in ent:
		ent.bone_health["left_leg"] = 0.0
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var has_scarred: bool = false
	var has_slowed: bool = false
	var amp_count: int = 0
	for aff in ent.campaign_afflictions:
		if aff is Dictionary:
			var aid: String = str(aff.get("id", ""))
			var apart: String = str(aff.get("part", ""))
			if aid == CampaignAfflictions.SCAR_SCARRED_TISSUE and apart == "left_leg":
				has_scarred = true
			if aid == CampaignAfflictions.AFFLICTION_SLOWED_CIRCULATION:
				has_slowed = true
			if aid == CampaignAfflictions.SCAR_AMPUTATED_LIMB and apart == "left_leg":
				amp_count += 1
	if has_scarred:
		_fail(failures, "amp_prune: pre-severance part scar should be pruned by the amputation")
	if not has_slowed:
		_fail(failures, "amp_prune: whole-body affliction should survive the amputation")
	if amp_count != 1:
		_fail(failures, "amp_prune: exactly one amputated_limb should remain (got %d)" % amp_count)
	# A second mint stays idempotent after the prune (the amputation scar is never itself pruned).
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	amp_count = 0
	for aff in ent.campaign_afflictions:
		if aff is Dictionary \
				and str(aff.get("id", "")) == CampaignAfflictions.SCAR_AMPUTATED_LIMB \
				and str(aff.get("part", "")) == "left_leg":
			amp_count += 1
	if amp_count != 1:
		_fail(failures, "amp_prune: amputation scar stays idempotent after prune (got %d)" % amp_count)
	_free_entity_fixture(ent)


## Phantom limb pain: the amputated_limb scar carries a whole-body pain_mult (persistent phantom
## sensation/pain follows ~50-80% of amputations), which the campaign pain reader applies in combat.
static func _run_amputated_phantom_pain(failures: PackedStringArray) -> void:
	var def: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_AMPUTATED_LIMB, "right_arm")
	var def_pain: float = float(def.get("pain_mult", 1.0))
	if absf(def_pain - 1.06) > 1e-9:
		_fail(failures, "phantom: amputated_limb should carry pain_mult 1.06 (got %.3f)" % def_pain)
	var ent: Node = _new_entity("SWORD")
	ent._add_campaign_affliction(def)
	var pain_read: float = ent._get_campaign_pain_mult()
	if absf(pain_read - 1.06) > 1e-9:
		_fail(failures, "phantom: whole-body pain reader should reflect 1.06 (got %.3f)" % pain_read)
	_free_entity_fixture(ent)


## TQ ischemia latches had_ischemia on the wound so a Volkmann contracture mints at resolution —
## even though the tourniquet has long been removed (the flag travels on the wound, not the TQ dict).
static func _run_tq_ischemia_latches_volkmann(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	var wound: Dictionary = {
		"injury_type": BleedingConstants.INJURY_TYPE_CUT,
		"severity": BleedingConstants.SEVERITY_SEVERE,
		"sub_region": "",
		"cumulative_damage": 2.0,
		"current_bleeding_rate": 0.0,
		"base_bleeding_rate": 0.0,
		"is_arterial": false,
		"is_stabilized": true,
		"penetration_to_tissue_mm": -1.0,
		"created_at_game_time": 0.0,
		"healing_duration_seconds": 7200.0,
	}
	ent.wounds["right_arm"] = [wound]
	ent.tourniquet_applied["right_arm"] = {"applied_at": 0.0, "effectiveness": 1.0}
	seed(12345)
	# Call 1: advance past TQ max duration -> TQ removed, ischemia latched; wound NOT yet resolved.
	ent._process_healing(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 100.0)
	if ent.tourniquet_applied.has("right_arm"):
		_fail(failures, "tq_latch: tourniquet should be removed after max duration")
	var w: Dictionary = ent.wounds.get("right_arm", [{}])[0]
	if not bool(w.get("had_ischemia", false)):
		_fail(failures, "tq_latch: wound should have had_ischemia=true after TQ expiry (got %s)" % str(w.get("had_ischemia")))
	# Call 2: advance until the wound resolves. TQ is already gone, so the descriptor's had_ischemia
	# can only come from the latched wound flag — proving the latch survives TQ removal.
	ent._process_healing(4000.0)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var has_contracture: bool = false
	for aff in ent.campaign_afflictions:
		if aff is Dictionary and str(aff.get("id", "")) == CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE and str(aff.get("part", "")) == "right_arm":
			has_contracture = true
	if not has_contracture:
		_fail(failures, "tq_latch_volkmann: a Volkmann contracture should mint for a TQ-ischemia'd arm (afflictions: %s)" % str(ent.campaign_afflictions))
	_free_entity_fixture(ent)


## A tourniquet released at wound resolution (before its max-duration expiry) must NOT mint a
## Volkmann contracture: the clamp came off while the limb was still healing (pre-expiry), so no
## ischemic necrosis occurred and the arm should not carry the grip 0.78 contracture. Negative twin
## of _run_tq_ischemia_latches_volkmann -- pins the false-positive the old
## `tourniquet_applied.has(part)` term minted onto every wound that resolved while a TQ was still on.
static func _run_pre_expiry_resolution_mints_no_volkmann(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	var wound: Dictionary = {
		"injury_type": BleedingConstants.INJURY_TYPE_CUT,
		"severity": BleedingConstants.SEVERITY_SEVERE,
		"sub_region": "",
		"cumulative_damage": 2.0,
		"current_bleeding_rate": 0.0,
		"base_bleeding_rate": 0.0,
		"is_arterial": false,
		"is_stabilized": true,
		"penetration_to_tissue_mm": -1.0,
		"created_at_game_time": 0.0,
		"healing_duration_seconds": 360.0,
	}
	ent.wounds["right_arm"] = [wound]
	ent.tourniquet_applied["right_arm"] = {"applied_at": 0.0, "effectiveness": 1.0}
	seed(12345)
	# A single advance sits well past this wound's resolution (360s heal -> resolves ~360s) but inside
	# the 3600s TQ max duration -- the clamp is released at resolution, no ischemia latch, no necrosis.
	ent._process_healing(2000.0)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	if ent.tourniquet_applied.has("right_arm"):
		_fail(failures, "tq_preexp: the clamp should be released when its wound resolves (stale clamp on a healed limb)")
	if ent.wounds.has("right_arm"):
		_fail(failures, "tq_preexp: the wound should have resolved in the advance")
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var has_contracture: bool = false
	for aff in ent.campaign_afflictions:
		if aff is Dictionary and str(aff.get("id", "")) == CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE and str(aff.get("part", "")) == "right_arm":
			has_contracture = true
	if has_contracture:
		_fail(failures, "tq_preexp: a Volkmann contracture must NOT mint when the TQ was released at resolution (pre-expiry, no ischemic necrosis) (afflictions: %s)" % str(ent.campaign_afflictions))
	_free_entity_fixture(ent)


## Osteo precedence is malunited-only: a wound that went osteomyelitis still mints the concurrent
## Volkmann contracture (had_ischemia) -- the former `continue` in the osteo branch swallowed the
## separate ischemia mechanism, dropping the harder grip handicap (0.78) from an infected compound
## arm whenever the wound also carried a TQ/compartment ischemia.
static func _run_osteo_infection_still_mints_volkmann(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	if not "resolved_wounds_this_advance" in ent:
		_fail(failures, "osteo_volkmann: harness entity must expose the resolved-wound stash")
	var desc: Array[Dictionary] = [{
		"part": "right_arm",
		"severity": BleedingConstants.SEVERITY_SEVERE,
		"injury_type": BleedingConstants.INJURY_TYPE_CUT,
		"was_infected": true,
		"is_compound_fracture": true,
		"is_osteomyelitis": true,
		"had_ischemia": true,
	}]
	ent.resolved_wounds_this_advance = desc
	CampaignAfflictions._mint_scars_for_entity(ent, "Test", null, null)
	var has_osteo: bool = false
	var has_contracture: bool = false
	for aff in ent.campaign_afflictions:
		if not (aff is Dictionary):
			continue
		var aid: String = str(aff.get("id", ""))
		var apart: String = str(aff.get("part", ""))
		if aid == CampaignAfflictions.SCAR_OSTEOMYELITIC_BONE and apart == "right_arm":
			has_osteo = true
		if aid == CampaignAfflictions.SCAR_ISCHEMIC_CONTRACTURE and apart == "right_arm":
			has_contracture = true
	if not has_osteo:
		_fail(failures, "osteo_volkmann: infected compound wound must mint the osteo scar (afflictions: %s)"
				% str(ent.campaign_afflictions))
	if not has_contracture:
		_fail(failures, "osteo_volkmann: concurrent TQ ischemia must still mint the Volkmann contracture "
				+ "when the wound also went osteo -- precedence supersedes malunited/scarred_tissue, "
				+ "not the separate ischemia mechanism (afflictions: %s)" % str(ent.campaign_afflictions))
	_free_entity_fixture(ent)


## Deepen is scar-only (plan §9.6): the post-victory tier-RNG bone afflictions share campaign_afflictions
## and carry a `part`, but a repeated roll must keep plain id+part dedup — never silently stacking
## damage_mult the way a wound-derived scar deepens. Gates on the `is_wound_scar` source marker.
static func _run_scar_deepen_is_scar_only(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	var rng_def: Dictionary = {
		"id": CampaignAfflictions.AFFLICTION_LIMPING_LIMB,
		"label": "Limping left_leg",
		"part": "left_leg",
		"stamina_mult": 0.92,
		"pain_mult": 1.0,
		"damage_mult": 1.0,
		"heal_mult": 1.0,
	}
	if not ent._add_campaign_affliction(rng_def):
		_fail(failures, "scar_only: RNG bone affliction should add first time")
	if ent._add_campaign_affliction(rng_def):
		_fail(failures, "scar_only: repeated RNG bone affliction should id+part dedup, not deepen")
	if ent.campaign_afflictions.size() != 1:
		_fail(failures, "scar_only: RNG re-roll should leave 1 entry (got %d)" % ent.campaign_afflictions.size())
	var d_first: float = float(ent.campaign_afflictions[0].get("damage_mult", 1.0))
	var h_first: float = float(ent.campaign_afflictions[0].get("heal_mult", 1.0))
	if absf(d_first - 1.0) > 1e-9:
		_fail(failures, "scar_only: RNG re-roll must not deepen damage_mult (got %.3f)" % d_first)
	if absf(h_first - 1.0) > 1e-9:
		_fail(failures, "scar_only: RNG re-roll must not deepen heal_mult (got %.3f)" % h_first)
	# A wound-derived scar on the same part still deepens (the flag path is alive).
	var scar: Dictionary = CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg")
	ent._add_campaign_affliction(scar)
	var d_once: float = ent._get_scar_damage_mult("left_leg")
	ent._add_campaign_affliction(CampaignAfflictions.scar_def(CampaignAfflictions.SCAR_MALUNITED_BONE, "left_leg"))
	var d_twice: float = ent._get_scar_damage_mult("left_leg")
	if not (d_twice > d_once):
		_fail(failures, "scar_only: wound-derived scar deepen should still fire (%.3f vs %.3f)" % [d_twice, d_once])
	_free_entity_fixture(ent)


## A scarred part severs more easily than healthy tissue (scar tissue shears at ~70-80% of normal
## tensile strength — same anchor as the re-injury bump). The severance ease factor is higher for an
## otherwise-identical part carrying a wound-derived scar.
static func _run_scar_increases_severance_ease(failures: PackedStringArray) -> void:
	var clean: Node = _new_entity("SWORD")
	var scarred: Node = _new_entity("SWORD")
	_seed_scar(scarred, CampaignAfflictions.SCAR_SCARRED_TISSUE, "left_leg")
	var ease_clean: float = EntityDamage.get_severance_ease_factor(clean, "left_leg")
	var ease_scar: float = EntityDamage.get_severance_ease_factor(scarred, "left_leg")
	if not (ease_scar > ease_clean):
		_fail(failures, "scar_sever: scarred part should sever more easily (scar %.3f vs clean %.3f)" % [ease_scar, ease_clean])
	_free_entity_fixture(clean)
	_free_entity_fixture(scarred)


## A combat severance mints a stump the same way surgery does, so it must also release the limb's
## prior medical state: the clamp/dressings described the OLD wound channel the stump replaces.
## Left on, an already-stale clamp (past ITS max duration) "expires" the very next healing tick and
## latches had_ischemia onto the STUMP -- a phantom Volkmann grip on a limb the strike just removed
## -- and the old bandage/packing reads as definitive hemostasis for a brand-new bleeding stump,
## starving it of care. The release invariant lives at the mint (ensure_stump_wound); this is the
## dismemberment twin of the surgical-amputation practice.
static func _run_severance_mint_releases_prior_medical_state(failures: PackedStringArray) -> void:
	var ent: Node = _new_entity("SWORD")
	var part: String = "right_arm"
	ent.wounds[part] = [{
		"severity": BleedingConstants.SEVERITY_SEVERE,
		"current_bleeding_rate": 0.5,
		"base_bleeding_rate": 0.5,
		"is_arterial": false,
		"is_stabilized": false,
		"created_at_game_time": 0.0,
		"healing_duration_seconds": 7200.0,
	}]
	# Clamp applied long ago (already past its max-duration window the moment it runs), plus dressings.
	ent.tourniquet_applied[part] = {
		"applied_at": -(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 60.0),
		"effectiveness": 1.0
	}
	ent.bandaged_parts[part] = true
	ent.packed_parts[part] = true
	# The strike destroys the limb exactly like apply_damage_split's severance: pools zeroed, stump mint.
	ent.body_cutting[part] = 0.0
	ent.body_blunt[part] = 0.0
	ent.bone_health[part] = 0.0
	EntityWounds.ensure_stump_wound(ent, part)
	var stump: Dictionary = ent.wounds.get(part, [{}])[0]
	if not bool(stump.get("is_stump", false)):
		_fail(failures, "sever_release: the destroyed limb should hold an amputation stump")
	if ent.tourniquet_applied.has(part):
		_fail(failures, "sever_release: a combat severance must release the prior clamp (stale TQ on a fresh stump)")
	if ent.bandaged_parts.get(part, false):
		_fail(failures, "sever_release: a combat severance must release the prior bandage (old dressing on a fresh stump)")
	if ent.packed_parts.has(part):
		_fail(failures, "sever_release: a combat severance must release the prior packing (old packing on a fresh stump)")
	# One tick: with the clamp gone there is nothing to "expire" -- the fresh stump must NOT latch
	# had_ischemia from the pre-severance clamp (phantom ischemic limb).
	ent._process_healing(1.0)
	stump = ent.wounds.get(part, [{}])[0]
	if bool(stump.get("had_ischemia", false)):
		_fail(failures, "sever_release: a released clamp must NOT latch ischemia onto the fresh stump (phantom ischemic limb)")
	_free_entity_fixture(ent)
