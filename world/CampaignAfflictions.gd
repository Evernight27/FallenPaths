class_name CampaignAfflictions
extends RefCounted

## Post-victory permanent injuries (Camp-2.4 / XCamp-3.4 catalog).
## Tier RNG from [guide affliction table](../../docs/CAMPAIGN_DECISION_GUIDE.md#affliction-rng-medieval-alignment).
## Canonical: `apply_after_victory` . `format_scar_line` . `count_scarred_brothers`.

const AFFLICTION_SLOWED_CIRCULATION := "slowed_circulation"
const AFFLICTION_OLD_WOUND_ACHE := "old_wound_ache"
const AFFLICTION_LIMPING_LIMB := "limping_limb"
const AFFLICTION_PARTLY_COLLAPSED_LUNG := "partly_collapsed_lung"
const AFFLICTION_SHAKY_GRIP := "shaky_grip"
const AFFLICTION_CRACKED_RIBS := "cracked_ribs"

# CAMP-SCAR-1: wound-derived scars (plan Part 2). Minted on individual wound resolution, each carries
# a `part` ("" = whole-body) plus per-part effect multipliers read by Core. Coexists with the
# post-victory RNG-roll afflictions above via the shared campaign_afflictions array (id+part merge).
const SCAR_SCARRED_TISSUE := "scarred_tissue"
const SCAR_MALUNITED_BONE := "malunited_bone"
const SCAR_ISCHEMIC_CONTRACTURE := "ischemic_contracture"
const SCAR_POST_SEPSIS_WEAKNESS := "post_sepsis_weakness"
const SCAR_OSTEOMYELITIC_BONE := "osteomyelitic_bone"
## Permanent disability from traumatic amputation (a limb severed to body_cutting=0 + bone=0). Minted
## idempotently while the limb stays severed; carries the chronic systemic stamina cost of an amputee
## plus a modest chronic part penalty (robust if the severed pools are ever restored).
const SCAR_AMPUTATED_LIMB := "amputated_limb"

## Post-victory affliction trigger probabilities (tier roll). P_PERIL / P_DANGER / P_BONE_CRIPPLE /
## P_CAP and the max-one-per-fight structure are TIED to the guide's medieval-alignment table
## (CAMPAIGN_DECISION_GUIDE.md#affliction-rng-medieval-alignment): peril 30% Â· danger 12% Â· bone
## cripple 45% Â· max one per fight. P_STRUCK_DOWN and P_ARTERIAL_FAIL carry a clinical anchor:
##   - P_STRUCK_DOWN 0.33 â‰ˆ the ~35% prolonged-symptom figure for concussion/mTBI (pro boxer survey:
##     persistent symptoms days-weeks after a KO; RESEARCH_concussion_mTBI_combat.md + PMC3003467).
##   - P_ARTERIAL_FAIL 0.55 â‰ˆ residual loss from a major extremity arterial injury, which even WITH
##     modern revascularization carries 10-46% limb loss / lifelong ischemia (popliteal-artery series:
##     amputation 14.5-46%; NTDB lower-extremity arterial complications ~19%). With no vascular repair
##     (medieval field surgery ligates at best), a survivor's disablement is strictly more likely â€”
##     0.55 is the tuned upper band. P_COLLAPSED_LUNG_SPLIT 0.35 is a tuned flavor split (which chronic
##     chest presentation the near-death danger tier lands on), not a clinical ratio; the guide cites it.
const P_PERIL := 0.30
const P_DANGER := 0.12
const P_BONE_CRIPPLE := 0.45
const P_ARTERIAL_FAIL := 0.55
const P_STRUCK_DOWN := 0.33
const P_CAP := 0.55
const P_COLLAPSED_LUNG_SPLIT := 0.35

const CATALOG_IDS: Array[String] = [
	AFFLICTION_SLOWED_CIRCULATION,
	AFFLICTION_OLD_WOUND_ACHE,
	AFFLICTION_LIMPING_LIMB,
	AFFLICTION_PARTLY_COLLAPSED_LUNG,
	AFFLICTION_SHAKY_GRIP,
	AFFLICTION_CRACKED_RIBS,
]

# Runtime preload -- circular dependency (CompanyState preloads CampaignAfflictions).
static var _company_state: Variant = null


static func _get_company_state() -> GDScript:
	if CampaignAfflictions._company_state == null:
		CampaignAfflictions._company_state = load("res://world/CompanyState.gd")
	return CampaignAfflictions._company_state


static func apply_after_victory(world: Node2D, rng: RandomNumberGenerator) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if not _get_company_state().read_stub_afflictions_enabled():
		return lines
	if world == null or rng == null:
		return lines
	for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
		var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
		if entity == null:
			continue
		var roll: Dictionary = _roll_affliction_for_entity(entity, n, rng)
		if roll.is_empty():
			continue
		if not entity.has_method("_add_campaign_affliction"):
			continue
		if entity._add_campaign_affliction(roll):
			var name_s: String = str(n.name)
			lines.append(format_scar_line(name_s, roll))
			_get_company_state().adjust_member_mood(world, name_s, -1.35)
	return lines


# ---------------------------------------------------------------------------
# CAMP-SCAR-1: wound-derived scars (plan Part 2). Minted when an individual
# wound *resolves* (remodeling phase), not at battle end. Coexists with the
# post-victory RNG-roll above via the shared campaign_afflictions array.
# ---------------------------------------------------------------------------

## World layer calls this after a healing advance (_process_healing) that resolved wounds.
## For each party member it mints scars from the member's resolved-wound descriptors, then
## clears the stash. Returns the "you scarred" lines for the settlement / op log.
static func mint_from_resolved_wounds(world: Node2D, rng: RandomNumberGenerator) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if not _get_company_state().read_stub_wound_scars_enabled():
		return lines
	if world == null or rng == null:
		return lines
	for n in CampaignEncounterBridge.get_fightable_party_nodes(world):
		var entity: Node = CampaignEncounterBridge.health_entity_from_character(n)
		if entity == null:
			continue
		var member_lines: PackedStringArray = _mint_scars_for_entity(entity, str(n.name), world, rng)
		for l in member_lines:
			lines.append(l)
	return lines


## Mint scars for one entity from its resolved-wound stash (resolved_wounds_this_advance).
## Deterministic rules (plan Â§2.3); the whole-body post-sepsis weakness is added if the member is
## (or was) septic. Clears the stash at the end. `world` may be null (harness) â€” the mood
## adjustment is then skipped.
static func _mint_scars_for_entity(entity: Node, name_s: String, world: Node, _rng: RandomNumberGenerator) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	# The dead do not mint: a fallen member must not accrue permanent scars (wound-remodeling,
	# amputation, or post-sepsis) on any later op-log pass — dead tissue does not remodel. The
	# resolved-wound stash is drained anyway so a corpse's battle-time carry-over is not re-read on
	# every future advance.
	if entity.has_method("is_dead") and entity.is_dead():
		if "clear_resolved_wounds" in entity:
			entity.clear_resolved_wounds()
		return lines
	var stash: Array = entity.resolved_wounds_this_advance if "resolved_wounds_this_advance" in entity else []
	for desc in stash:
		var part: String = str(desc.get("part", ""))
		var sev: String = str(desc.get("severity", ""))
		var was_infected: bool = bool(desc.get("was_infected", false))
		var is_osteo: bool = bool(desc.get("is_osteomyelitis", false))
		var is_compound: bool = bool(desc.get("is_compound_fracture", false))
		var had_ischemia: bool = bool(desc.get("had_ischemia", false))
		# A severed limb's chronic state is the amputated_limb scar (minted after this loop); a wound
		# resolving on a severed part (e.g. the amputation stump healing over) must not also mint a
		# per-wound remodeling scar â€” it would double-label ("Scarred left leg" + "Amputated left leg")
		# and double-penalize a part that no longer bears weapon damage.
		if BodyPartQuery.is_part_severed(entity, part):
			continue
		if is_osteo:
			# infected compound fracture: chronic bone; takes precedence over malunited (and the
			# soft-tissue remodeling scar). A concurrent tourniquet/compartment ischemia is a
			# SEPARATE mechanism (Volkmann contracture) and still mints below -- the former
			# `continue` swallowed it, silently dropping the harder grip handicap (0.78) from the
			# same arm whenever the wound went osteo.
			_mint_one(entity, _scar_def(SCAR_OSTEOMYELITIC_BONE, part), name_s, world, lines)
		elif is_compound:
			_mint_one(entity, _scar_def(SCAR_MALUNITED_BONE, part), name_s, world, lines)
		if had_ischemia and _is_arm_part(part):
			# Volkmann ischemic contracture: arm-only (missed compartment / tourniquet ischemia).
			_mint_one(entity, _scar_def(SCAR_ISCHEMIC_CONTRACTURE, part), name_s, world, lines)
		# `scarred_tissue` is a soft-tissue remodeling scar and only open wounds remodel: a closed
		# contusion (bruise) resorbs wholly and a clean (non-compound) fracture heals with internal
		# bone callus (its malunion/osteo mints are keyed on the exposed-bone compound flag). Neither
		# mints. compound_fracture is an open injury (exposed bone) and cut/stab/crush/internal_bleed
		# all tear or breach tissue, so they keep the rule; legacy descriptors ("" for pre-stash-era
		# saves) keep the original behavior too.
		var injury_type: String = str(desc.get("injury_type", ""))
		var is_open_tissue_wound: bool = (
			injury_type.is_empty()
			or (
				injury_type != BleedingConstants.INJURY_TYPE_BRUISE
				and injury_type != BleedingConstants.INJURY_TYPE_FRACTURE
			)
		)
		if not is_osteo and is_open_tissue_wound and (
			was_infected
			or sev == BleedingConstants.SEVERITY_SEVERE
			or sev == BleedingConstants.SEVERITY_CRITICAL
		):
			# infected, or a severe/critical clean open wound also remodels into scarred tissue.
			_mint_one(entity, _scar_def(SCAR_SCARRED_TISSUE, part), name_s, world, lines)
	# Whole-body post-sepsis weakness (diffuse/symmetric, no part). Plan §2.3: mint only AFTER the
	# member has recovered — the weakness is the convalescent aftermath, never an active-sepsis tell.
	# The latched sepsis_recovered flag is set by EntityHealing at the same moment is_septic clears,
	# so a recovered member reads recovered=true / septic=false; a member still actively septic (or
	# died of sepsis, _sepsis_dead) must not carry the label. id-dedup (part "") prevents re-minting.
	var sepsis_recovered: bool = "sepsis_recovered" in entity and bool(entity.sepsis_recovered)
	var actively_septic: bool = "is_septic" in entity and bool(entity.is_septic)
	var sdead: bool = bool(entity._sepsis_dead) if "_sepsis_dead" in entity else false
	if sepsis_recovered and not actively_septic and not sdead and "campaign_afflictions" in entity:
		_mint_one(entity, _scar_def(SCAR_POST_SEPSIS_WEAKNESS, ""), name_s, world, lines)
	_mint_amputation_scar_for_entity(entity, name_s, world, lines)
	if "clear_resolved_wounds" in entity:
		entity.clear_resolved_wounds()
	return lines


## Mint a permanent amputation scar for a limb the member has severed. Idempotent per part:
## once the scar exists it is not re-minted, so repeated overworld minutes after a severance
## do not stack penalties. The severity-scaled chronic penalty rides on top of the acute
## destroyed-part state already handled by BodyPartQuery.
static func _mint_amputation_scar_for_entity(entity: Node, name_s: String, world: Node2D, lines: PackedStringArray) -> void:
	if not "campaign_afflictions" in entity or not "body_cutting" in entity or not "bone_health" in entity:
		return
	var parts: Array = BodyPartQuery.get_body_part_list(entity)
	for part in parts:
		if not BodyPartQuery.is_limb(part):
			continue
		if not BodyPartQuery.is_part_severed(entity, part):
			continue
		# The amputation supersedes the limb's prior injuries: a severed part's old per-part scars
		# (e.g. "Scarred left leg") and bone afflictions (e.g. "Limping left_leg") describe a limb
		# that no longer exists â€” their multipliers are moot (the severed part reads ~0) and their
		# labels would double-list beside "Amputated {part}". Prune same-part entries every call so
		# old saved double-labels are cleaned too; sole whole-body afflictions (part "") are untouched.
		var i: int = entity.campaign_afflictions.size() - 1
		while i >= 0:
			var raw_v: Variant = entity.campaign_afflictions[i]
			if raw_v is Dictionary \
					and str((raw_v as Dictionary).get("part", "")) == part \
					and str((raw_v as Dictionary).get("id", "")) != SCAR_AMPUTATED_LIMB:
				entity.campaign_afflictions.remove_at(i)
			i -= 1
		var has_scar: bool = false
		for raw in entity.campaign_afflictions:
			if raw is Dictionary and str(raw.get("id", "")) == SCAR_AMPUTATED_LIMB and str(raw.get("part", "")) == part:
				has_scar = true
				break
		if has_scar:
			continue
		_mint_one(entity, _scar_def(SCAR_AMPUTATED_LIMB, part), name_s, world, lines)


## Mint a single scar def via the shared _add_campaign_affliction (id+part merge). On success,
## log the scar line and nudge mood down (world may be null in the harness; then skip mood).
static func _mint_one(entity: Node, def: Dictionary, name_s: String, world: Node, lines: PackedStringArray) -> void:
	if def.is_empty() or not entity.has_method("_add_campaign_affliction"):
		return
	if entity._add_campaign_affliction(def):
		lines.append(format_scar_line(name_s, def))
		if world != null:
			_get_company_state().adjust_member_mood(world, name_s, -1.35)


## Wound-derived scar catalog (plan Â§2.2). Each carries a part ("" = whole-body) plus the
## universal per-scar effect multipliers (stamina/pain/damage/bleed/heal) AND the part-specific
## penalties (plan Â§9.5): a scarred limb carries a *location*-specific penalty on top of the
## universal floor â€” a malunited/scarred leg drives slower (move_speed), a malunited/contracted
## arm grips weaker (grip), a scarred head reads slower (perception), a scarred thorax limits
## sustained output (stamina_pool). Part-specific keys are only present when != 1.0.
static func _scar_def(id: String, part: String) -> Dictionary:
	var label: String = id
	var s: float = 1.0
	var p: float = 1.0
	var d: float = 1.0
	var b: float = 1.0
	var h: float = 1.0
	match id:
		SCAR_SCARRED_TISSUE:
			label = "Scarred %s" % (_part_label(part))
			s = 1.0; p = 1.03; d = 1.10; b = 1.05; h = 0.85
		SCAR_MALUNITED_BONE:
			label = "Malunited %s" % (_part_label(part))
			s = 0.95; p = 1.05; d = 1.15; b = 1.0; h = 0.85
		SCAR_ISCHEMIC_CONTRACTURE:
			label = "Contracted %s (Volkmann)" % (_part_label(part))
			s = 0.82; p = 1.0; d = 1.15; b = 1.0; h = 0.80
		SCAR_POST_SEPSIS_WEAKNESS:
			label = "Post-sepsis weakness"
			s = 0.80; p = 1.05; d = 1.0; b = 1.0; h = 0.90
		SCAR_OSTEOMYELITIC_BONE:
			label = "Infected bone %s" % (_part_label(part))
			s = 1.0; p = 1.05; d = 1.10; b = 1.0; h = 0.75
		SCAR_AMPUTATED_LIMB:
			# Chronic systemic cost of being an amputee: severance blood-loss residue + the
			# sustained metabolic/effort cost of an altered gait (legs) or one-handed bracing
			# (arms). The severed part itself already reads ~0 in combat (BodyPartQuery), so the
			# levers here are the whole-body stamina_mult (gait/effort) and a modest whole-body
			# pain_mult for phantom limb pain - persistent phantom sensation/pain follows ~50-80%
			# of amputations (Bosmans et al. 2010 systematic review), worse with a rough medieval
			# stump. damage/bleed/heal stay neutral (a severed part takes no weapon damage and its
			# stump is handled by the stump path).
			label = "Amputated %s" % (_part_label(part))
			s = 0.85; p = 1.06; d = 1.0; b = 1.0; h = 1.0
	var def: Dictionary = {
		"id": id,
		"label": label,
		"part": part,
		"stamina_mult": s,
		"pain_mult": p,
		"damage_mult": d,
		"bleed_mult": b,
		"heal_mult": h,
		# Source marker for Core's _add_campaign_affliction: only wound-derived scars id+part-deepen
		# (plan Â§9.6). The post-victory tier-RNG afflictions share this array but must keep plain
		# id-dedup, so they never set this flag.
		"is_wound_scar": true,
	}
	# Part-specific penalties (Â§9.5), keyed by (scar id, part category). Research anchors:
	# malunion "trouble placing weight" (Wikipedia:Malunion); Volkmann's hand/forearm flexion
	# contracture (Wikipedia:Volkmann's contracture); scar loss of elasticity (Wikipedia:Scar);
	# a scarred thorax limits sustained cardiopulmonary output.
	var ms: float = 1.0  # move_speed (leg/foot)
	var gr: float = 1.0  # grip (arm/hand)
	var pc: float = 1.0  # perception (head)
	var st_pool: float = 1.0  # stamina_pool (chest)
	var pl: String = part.to_lower()
	var leg: bool = pl.contains("leg") or pl.contains("foot")
	var arm: bool = pl.contains("arm") or pl.contains("hand")
	var head: bool = pl.contains("head")
	var chest: bool = pl.contains("chest")
	match id:
		SCAR_SCARRED_TISSUE:
			if leg: ms = 0.95
			if arm: gr = 0.94
			if head: pc = 0.93
			if chest: st_pool = 0.93
		SCAR_MALUNITED_BONE:
			if leg: ms = 0.88
			if arm: gr = 0.90
		SCAR_ISCHEMIC_CONTRACTURE:
			if arm: gr = 0.78
		SCAR_OSTEOMYELITIC_BONE:
			if leg: ms = 0.90
			if arm: gr = 0.90
		SCAR_AMPUTATED_LIMB:
			# Chronic post-healing gait / grip adaptation cost. Modest on top of the already-severe
			# acute destroyed-part state (get_leg_functionality ~0.08-0.55, arm ~0) so it reads as the
			# long-term residual, not a double punishment.
			if leg: ms = 0.90
			if arm: gr = 0.90
	if ms != 1.0:
		def["move_speed"] = ms
	if gr != 1.0:
		def["grip"] = gr
	if pc != 1.0:
		def["perception"] = pc
	if st_pool != 1.0:
		def["stamina_pool"] = st_pool
	return def


static func _part_label(part: String) -> String:
	return part if not part.is_empty() else "wound"


static func _is_arm_part(part: String) -> bool:
	var p: String = part.to_lower()
	return (p.contains("arm") or p.contains("hand"))


static func count_scarred_brothers(world: Node2D) -> int:
	if world == null:
		return 0
	var n: int = 0
	for node in CampaignEncounterBridge.get_fightable_party_nodes(world):
		var entity: Node = CampaignEncounterBridge.health_entity_from_character(node)
		if entity == null or not ("campaign_afflictions" in entity):
			continue
		if entity.campaign_afflictions is Array and not (entity.campaign_afflictions as Array).is_empty():
			n += 1
	return n


static func format_scar_line(member_name: String, def: Dictionary) -> String:
	var label: String = str(def.get("label", def.get("id", "?")))
	var fx: String = _effect_suffix(def)
	if fx.is_empty():
		return "%s  -  %s" % [member_name, label]
	return "%s  -  %s (%s)" % [member_name, label, fx]


static func catalog_def(id: String, bone_part: String = "") -> Dictionary:
	return _affliction_def(id, bone_part)


## Public accessor for the wound-derived scar catalog (CAMP-SCAR-1), so harnesses / callers can
## mint a scar def directly. Returns the part-specific + universal effect multipliers.
static func scar_def(id: String, part: String = "") -> Dictionary:
	return _scar_def(id, part)


static func _roll_affliction_for_entity(entity: Node, character: Node, rng: RandomNumberGenerator) -> Dictionary:
	var blood: float = 100.0
	if "blood_volume" in entity:
		blood = entity.blood_volume
	# Tier ladder: the cause with the highest trigger probability both gates the roll AND names the
	# affliction (max one per fight). Each branch only wins when its own probability exceeds the best
	# so far -- an unconscious/peril/arterial member must not be relabeled by a lower-probability cause
	# (formerly the last-written `pick` could hijack the result: an arterial-fail 0.55 gate with a
	# crippled bone named the bone affliction at 0.55 instead of slowed_circulation, and an
	# unconscious member in the danger band named collapsed lung / old wound ache at 0.33).
	var p: float = 0.0
	var pick: String = AFFLICTION_SLOWED_CIRCULATION
	var bone_part: String = _worst_bone_part(entity)
	if character.has_method("is_unconscious") and character.is_unconscious():
		p = maxf(p, P_STRUCK_DOWN)
		pick = AFFLICTION_SLOWED_CIRCULATION
	if blood < BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING:
		if P_PERIL > p:
			p = P_PERIL
			pick = AFFLICTION_SLOWED_CIRCULATION
	elif blood < BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING:
		if P_DANGER > p:
			p = P_DANGER
			pick = AFFLICTION_OLD_WOUND_ACHE
			if rng.randf() < P_COLLAPSED_LUNG_SPLIT:
				pick = AFFLICTION_PARTLY_COLLAPSED_LUNG
	if _count_untreated_arterial(entity) >= 2:
		if P_ARTERIAL_FAIL > p:
			p = P_ARTERIAL_FAIL
			pick = AFFLICTION_SLOWED_CIRCULATION
	if not bone_part.is_empty() and P_BONE_CRIPPLE > p:
		p = P_BONE_CRIPPLE
		pick = _bone_affliction_id(bone_part)
	p = minf(p, P_CAP)
	if p <= 0.0 or rng.randf() >= p:
		return {}
	return _affliction_def(pick, bone_part)


static func _bone_affliction_id(part: String) -> String:
	var p: String = part.to_lower()
	if p.contains("leg") or p.contains("foot"):
		return AFFLICTION_LIMPING_LIMB
	if p.contains("arm") or p.contains("hand"):
		return AFFLICTION_SHAKY_GRIP
	if p.contains("chest") or p.contains("rib"):
		return AFFLICTION_CRACKED_RIBS
	return AFFLICTION_LIMPING_LIMB


## Tier-RNG affliction effects (XCamp-3.4 catalog). These stamina/pain multipliers are TUNED design
## values (no direct clinical coefficient â€” chronic pain and effort costs are game-scaled), set to the
## 5-10% band so the post-victory affliction reads as a lingering hardship rather than a second wound:
## stamina 0.85-0.94 / pain 1.04-1.08. Bone-affliction entries carry their `part` AND a modest sited
## penalty (move_speed / grip / stamina_pool, 0.95) that the shared scar reader applies: the bone is
## crippled, so the named functional cost is real â€” a limp slows gait, a shaky grip weakens grip, a
## cracked rib limits sustained output. (RNG bone afflictions stay plain id+part dedup in Core: these
## keys are penalties, not wound-scar deepen sources.) The wound-derived scar catalog (_scar_def) is the
## anchored sibling â€” its multipliers trace to plan Â§2.2.
static func _affliction_def(id: String, bone_part: String) -> Dictionary:
	match id:
		AFFLICTION_OLD_WOUND_ACHE:
			return {
				"id": id,
				"label": "Old wound ache",
				"stamina_mult": 1.0,
				"pain_mult": 1.08,
			}
		AFFLICTION_PARTLY_COLLAPSED_LUNG:
			return {
				"id": id,
				"label": "Partly collapsed lung",
				"stamina_mult": 0.85,
				"pain_mult": 1.0,
			}
		AFFLICTION_SHAKY_GRIP:
			return {
				"id": id,
				"label": "Shaky grip",
				"stamina_mult": 0.94,
				"pain_mult": 1.04,
				"part": bone_part,
				"grip": 0.95,
			}
		AFFLICTION_CRACKED_RIBS:
			return {
				"id": id,
				"label": "Cracked ribs",
				"stamina_mult": 0.88,
				"pain_mult": 1.05,
				"part": bone_part,
				"stamina_pool": 0.95,
			}
		AFFLICTION_LIMPING_LIMB:
			var limb_label: String = bone_part if not bone_part.is_empty() else "leg"
			return {
				"id": id,
				"label": "Limping %s" % limb_label,
				"stamina_mult": 0.92,
				"pain_mult": 1.0,
				"part": bone_part,
				"move_speed": 0.95,
			}
		_:
			return {
				"id": AFFLICTION_SLOWED_CIRCULATION,
				"label": "Slowed circulation",
				"stamina_mult": 0.90,
				"pain_mult": 1.0,
			}


static func _effect_suffix(def: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	var sm: float = def.get("stamina_mult", 1.0)
	var pm: float = def.get("pain_mult", 1.0)
	if absf(sm - 1.0) > 0.02:
		bits.append("Stamina %s" % _pct_delta(sm))
	if absf(pm - 1.0) > 0.02:
		bits.append("Pain %s" % _pct_delta(pm))
	return ", ".join(bits)


## Signed percent delta for a multiplier vs 1.0 ("-12%" for 0.88, "+8%" for 1.08). The suffix is a
## real delta, not a remaining-value percentage: a 0.85 stamina multiplier reads "Stamina -15%"
## (reduced by 15%), never "Stamina -- 85%" which reads as an 85% loss.
static func _pct_delta(mult: float) -> String:
	var d: int = int(roundf((mult - 1.0) * 100.0))
	var sign_str: String = "+" if d >= 0 else ""
	return "%s%d%%" % [sign_str, d]


static func _count_untreated_arterial(entity: Node) -> int:
	var n := 0
	if not entity.wounds is Dictionary:
		return 0
	var bandaged: Dictionary = entity.bandaged_parts if "bandaged_parts" in entity else {}
	var packed: Dictionary = entity.packed_parts if "packed_parts" in entity else {}
	var tq: Dictionary = entity.tourniquet_applied if "tourniquet_applied" in entity else {}
	for part in entity.wounds.keys():
		if bandaged.get(part, false) or packed.get(part, false) or tq.has(part):
			continue
		for injury in entity.wounds[part]:
			if injury is Dictionary and injury.get("is_arterial", false):
				n += 1
	return n


## Worst surviving bone (post-victory bone-cripple roll). Severed parts are excluded: a limb severed in
## the fight has bone_health 0, which would read as the worst crippled bone and roll "Limping left_leg" /
## "Shaky grip" for a limb that no longer exists — its chronic state is the amputated_limb scar (minted on
## the next advance), not a bone-cripple. So a member whose only <25% bone is severed gets no bone-cripple.
static func _worst_bone_part(entity: Node) -> String:
	var worst: String = ""
	var worst_ratio: float = 1.0
	if entity.get("bone_health") == null or entity.get("bone_max") == null:
		return ""
	for part in entity.bone_health.keys():
		var mx: float = entity.bone_max.get(part, 0)
		if mx <= 0.0:
			continue
		var ratio: float = entity.bone_health.get(part, 0.0) / mx
		if ratio <= 0.25 and ratio < worst_ratio:
			if not BodyPartQuery.is_part_severed(entity, part):
				worst_ratio = ratio
				worst = part as String
	return worst
