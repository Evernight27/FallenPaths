class_name ArmorPiece
extends RefCounted

## Armor piece data model: layer stack, damage mitigation, durability.

# One piece of armor per body part. A piece can be composed of multiple layers
# (e.g. plate + gambeson) to reflect medieval kit. Damage is processed through
# layers in order: outer first, then inner.
#
# SHARP: Penetration model. pen_sharp vs sharp_resistance -> penetrate or stop.
#        When stopped: fraction transmitted as blunt (sharp_deflect_transmission); durability loss on absorbed share.
# BLUNT: Transmission-only model. Fraction of damage passes (blunt_transmission); cushion and area coupling reduce it.
# Durability loss on absorbed share.

var display_name: String = ""
var body_part: String = ""
var piece_id: String = ""
# Each layer: { sharp_resistance_rha_mm, blunt_transmission, durability, max_durability, durability_loss_rate }.
var layers: Array = []


static func create_from_definition(pid: String) -> ArmorPiece:
	var def: Dictionary = ArmorConstants.get_piece_definition(pid)
	if def.is_empty():
		return null
	var piece := ArmorPiece.new()
	piece.piece_id = pid
	piece.display_name = def.get("name", pid)
	piece.body_part = def.get("body_part", "")
	var layer_defs: Array = def.get("layers", [])
	for layer_def in layer_defs:
		var layer: Dictionary = layer_def.duplicate()
		layer["durability"] = 100.0
		layer["max_durability"] = 100.0
		if not layer.has("durability_loss_rate"):
			layer["durability_loss_rate"] = ArmorConstants.DURABILITY_LOSS_RATE
		piece.layers.append(layer)
	return piece


## Independent copy with current durability/mass — post-XCamp-4i a piece is stateful
## (durability mutates on hit), so callers must not share one instance. Deep-copies
## every layer so wear on the copy never touches the source.
func clone() -> ArmorPiece:
	var copy := ArmorPiece.new()
	copy.piece_id = piece_id
	copy.display_name = display_name
	copy.body_part = body_part
	for layer in layers:
		if layer is Dictionary:
			copy.layers.append(layer.duplicate())
	return copy


## Total mass (kg) from layer mass_kg fields  -  sum matches full kit when all pieces equipped (typical harness ~15 - 28
## kg).
## Body-part scale: same layer defs are reused for vambraces vs cuirass; smaller regions carry less steel/textile.
func get_total_mass_kg() -> float:
	var t: float = 0.0
	for layer in layers:
		if layer is Dictionary:
			t += float(layer.get("mass_kg", _default_mass_kg_for_layer(layer)))
	return t * _body_part_mass_scale(body_part)


func _body_part_mass_scale(part: String) -> float:
	match part:
		BodyPartConstants.PART_CHEST:
			return 1.0
		BodyPartConstants.PART_HEAD:
			return 0.58
		BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM:
			return 0.4
		BodyPartConstants.PART_RIGHT_LEG, BodyPartConstants.PART_LEFT_LEG:
			return 0.48
		_:
			return 0.5


func _default_mass_kg_for_layer(layer: Dictionary) -> float:
	var rig: float = layer.get("rigidity", 0.0)
	# Derived from the canonical layer masses so a hand-built layer can't drift
	# from the definition (see docs/ARMOR_VALUES_PHYSICS_RESEARCH.md §6). The
	# leather/mail band shares rigidity 0.2, so use their midpoint.
	if rig >= 0.95:
		return float(ArmorConstants.LAYER_PLATE["mass_kg"])
	if rig >= 0.2:
		return (float(ArmorConstants.LAYER_LEATHER["mass_kg"]) + float(ArmorConstants.LAYER_MAIL["mass_kg"])) * 0.5
	return float(ArmorConstants.LAYER_CLOTH["mass_kg"])


## Overall condition (0.0–100.0): the weakest layer's remaining durability, i.e. the
## layer that will fail (stop protecting) next. A fresh piece reads 100.0. A value of
## 0.0 means the outer layer is destroyed — inner layers may still be protecting.
func get_condition_pct() -> float:
	var weakest: float = -1.0
	for layer in layers:
		if layer is not Dictionary:
			continue
		var d: float = float(
			layer.get(ArmorConstants.ARMOR_LAYER_KEY_DURABILITY, ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
		)
		if weakest < 0.0 or d < weakest:
			weakest = d
	if weakest < 0.0:
		return 100.0
	return clampf(weakest, 0.0, 100.0)


## XCamp-4n: returns indices of all currently destroyed layers (durability <= 0).
## Used by EntityDamage to detect layer-failure transitions and emit combat traces.
func destroyed_layer_indices() -> Array:
	var out: Array = []
	for i in range(layers.size()):
		if layers[i] is Dictionary and _is_layer_destroyed(layers[i]):
			out.append(i)
	return out


# Apply damage through all layers. Returns { damage, damage_type, was_deflected, transmitted_blunt_amount }.
# When SHARP is stopped by a layer: fraction transmitted as blunt (one layer's transmission); caller adds to blunt and
# runs once.
# BLUNT: transmission-only. Uses blunt_transmission + cushion (momentum_per_area) + area coupling (rigid layers).
# blunt_contact_cm: weapon contact for area coupling; < 0 = skip (e.g. unarmed fallback).
# start_layer_index: when >0, skip outer layers (e.g. 1 after sharp deflected on layer 0 so deflected blunt is not
# reduced twice).
func apply_damage(
	incoming_damage: float,
	damage_type: String,
	penetration_sharp: float,
	penetration_blunt_momentum_per_area: float = -1.0,
	blunt_contact_cm: float = -1.0,
	start_layer_index: int = 0,
	blunt_coupling_contact_cm: float = -1.0,
	apply_wear: bool = true
) -> Dictionary:
	var damage_remaining: float = incoming_damage
	var current_damage_type: String = damage_type
	var pen_rha: float = penetration_sharp
	var was_deflected: bool = false
	var incoming_was_sharp: bool = damage_type == ArmorConstants.DAMAGE_TYPE_SHARP

	for i in range(start_layer_index, layers.size()):
		var layer: Dictionary = layers[i]
		if _is_layer_destroyed(layer):
			continue
		var dmg_in: float = damage_remaining
		var result := _process_layer(
			damage_remaining, current_damage_type, pen_rha, layer, penetration_blunt_momentum_per_area, blunt_contact_cm, blunt_coupling_contact_cm, apply_wear
		)
		damage_remaining = result.damage
		current_damage_type = result.damage_type
		# XCamp-4q: breakthrough crush — if this layer just broke, shock the next inner layer.
		# Skipped when apply_wear=false (the pass is a damage-only retransmission).
		if apply_wear and _is_layer_destroyed(layer):
			apply_breakthrough_crush(i, maxf(0.0, dmg_in - damage_remaining), current_damage_type)
		if result.deflected:
			was_deflected = true
			if incoming_was_sharp:
				# Sharp stopped by rigid layer (plate/mail): transmitted as blunt.
				# Do NOT return immediately — continue processing the deflected blunt through remaining layers.
				# This is physically correct: plate stops blade but transmits shock to gambeson underneath,
				# which further cushions before reaching tissue. Research: Williams 2003 shows padded underlayer
				# absorbs ~65% of deflection energy; MIT HMIT drop-hammer tests confirm multi-layer cushioning.
				# Without this, plate-only armor would transmit 100% of impact as blunt (same damage as no armor).
				if i + 1 >= layers.size():
					# Last layer — nothing left to process through.
					return {
						"damage": maxf(0.0, damage_remaining),
						"damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT,
						"was_deflected": true,
						"transmitted_blunt_amount": maxf(0.0, damage_remaining)
					}
				# Continue to next iteration — remaining layers process the blunt shock.
			else:
				# Blunt: this layer applied transmission; continue to inner layers.
				pass
		if damage_remaining <= 0.0:
			break

	var transmitted_blunt_amount: float = 0.0
	if was_deflected and incoming_was_sharp and current_damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		transmitted_blunt_amount = maxf(0.0, damage_remaining)
	return {
		"damage": maxf(0.0, damage_remaining),
		"damage_type": current_damage_type,
		"was_deflected": was_deflected,
		"transmitted_blunt_amount": transmitted_blunt_amount
	}


func _process_layer(
	damage: float,
	damage_type: String,
	pen_rha: float,
	layer: Dictionary,
	blunt_momentum_per_area: float = -1.0,
	blunt_contact_cm: float = -1.0,
	blunt_coupling_contact_cm: float = -1.0,
	apply_wear: bool = true
) -> Dictionary:
	if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		var after_transmission: float = blunt_transmission_math(
			damage, layer, blunt_momentum_per_area, blunt_contact_cm, blunt_coupling_contact_cm
		)

		# Area coupling warnings  -  only when called from instance methods (not from shared static).
		var rigidity: float = float(
			layer.get(ArmorConstants.ARMOR_LAYER_KEY_RIGIDITY, ArmorConstants.DEFAULT_ARMOR_LAYER_RIGIDITY)
		)
		if blunt_contact_cm > 0.0 and rigidity >= ArmorConstants.RIGIDITY_THRESHOLD:
			var ref_cm: float = WeaponConstants.get_blunt_coupling_reference_cm()
			var warn_cm: float = (
				blunt_coupling_contact_cm if blunt_coupling_contact_cm >= 0.0 else blunt_contact_cm
			)
			var area_factor: float = warn_cm / ref_cm
			if (
				area_factor < ArmorConstants.BLUNT_AREA_FACTOR_WARN_MIN
				or area_factor > ArmorConstants.BLUNT_AREA_FACTOR_WARN_MAX
			):
				push_warning(
					(
						(
                            "[Armor] Area coupling factor %.3f outside tuning range [%.2f, %.2f] "
							+ "(contact=%.2f cm, ref=%.2f). Adjust BLUNT_COUPLING_REFERENCE_CM or weapon contact."
						)
						% [
							area_factor,
							ArmorConstants.BLUNT_AREA_FACTOR_WARN_MIN,
							ArmorConstants.BLUNT_AREA_FACTOR_WARN_MAX,
							warn_cm,
							ref_cm,
						]
					)
				)

		if (
			after_transmission / maxf(damage, 0.01) < ArmorConstants.BLUNT_TRANSMISSION_WARN_MIN
			or after_transmission / maxf(damage, 0.01) > ArmorConstants.BLUNT_TRANSMISSION_WARN_MAX
		):
			push_warning(
				(
					(
                        "[Armor] Blunt transmission %.3f outside [%.2f, %.2f]. Check layer blunt_transmission, "
						+ "cushion, rigidity, or BLUNT_COUPLING_REFERENCE_CM."
					)
					% [
						after_transmission / maxf(damage, 0.01),
						ArmorConstants.BLUNT_TRANSMISSION_WARN_MIN,
						ArmorConstants.BLUNT_TRANSMISSION_WARN_MAX,
					]
				)
			)

		if apply_wear:
			_apply_durability_loss(layer, damage - after_transmission, ArmorConstants.DAMAGE_TYPE_BLUNT)
		return {"damage": after_transmission, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}

	# SHARP: Delegate to shared static penetration math.
	var result: Dictionary = sharp_penetration_math(pen_rha, layer, damage)
	if result.deflected:
		if apply_wear:
			# The edge that was stopped caught this layer, so its failure mode is SHARP
			# (a blade catch, not a blow) — matches the joule path, which wears the
			# deflected layer as DAMAGE_TYPE_SHARP. The transmitted shock is blunt, but
			# that wear is applied to the inner layers, not the one that stopped it.
			_apply_durability_loss(layer, damage - result.damage, damage_type)
		# A stopped edge transmits as blunt shock — flip the type so the remaining inner
		# layers cushion it via blunt_transmission_math (the joule path does this with
		# sharp_mode = false). Without this the deflected shock re-enters the inner layers
		# as a CUT (their sharp-penetration formula), and apply_damage's transmitted_blunt_amount
		# (keyed on current_damage_type == BLUNT) is never set.
		return {"damage": result.damage, "damage_type": ArmorConstants.DAMAGE_TYPE_BLUNT, "deflected": true}
	# Penetrated: the edge passes all the way through this layer, so it tears the layer
	# even when little edge energy remains. As the layer wears its effective RHA drops and
	# the absorbed remainder (damage - result.damage) shrinks toward 0; without a floor the
	# layer would asymptote just above zero durability and never fully fail. Floor at the
	# minimum wear threshold and bypass the threshold gate.
	var absorbed_pen: float = maxf(
		damage - result.damage, ArmorConstants.DURABILITY_MIN_DAMAGE_FLAT
	)
	if apply_wear:
		_apply_durability_loss(layer, absorbed_pen, damage_type, true)
	return {"damage": result.damage, "damage_type": damage_type, "deflected": false}


static func _is_layer_destroyed(layer: Dictionary) -> bool:
	var dur: float = layer.get(ArmorConstants.ARMOR_LAYER_KEY_DURABILITY, ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
	return dur <= 0.0


## XCamp-4m: fatigue multiplier on durability loss. A worn layer wears faster than a fresh one
## (compromised material fails quicker): 1.0 at full durability, rising to
## 1.0 + ARMOR_WEAR_FATIGUE_MAX at zero. Fresh armor (dur == max) returns exactly 1.0, so the
## pre-4m wear behaviour is bit-identical.
static func _wear_fatigue_multiplier(durability: float, max_durability: float) -> float:
	if max_durability <= 0.0:
		return 1.0
	var wear_frac: float = clampf(1.0 - durability / max_durability, 0.0, 1.0)
	return 1.0 + ArmorConstants.ARMOR_WEAR_FATIGUE_MAX * wear_frac


## XCamp-4t: fatigue-cliff multiplier on durability loss. A layer in the final stretch of its
## life (wear_frac past CLIFF_THRESHOLD) fails all at once, so its wear rate gets an extra
## convex boost on top of the 4m linear fatigue. Pinned: at/above the threshold the factor is
## exactly 1.0 (pure 4m behaviour — the pinned mid-life values stay bit-identical), ramping to
## 1.0 + CLIFF_MAX at zero durability. 0.0 CLIFF_MAX disables the cliff entirely.
static func _wear_fatigue_cliff(durability: float, max_durability: float) -> float:
	var max_thr: float = ArmorConstants.ARMOR_WEAR_FATIGUE_CLIFF_THRESHOLD
	var cliff_max: float = ArmorConstants.ARMOR_WEAR_FATIGUE_CLIFF_MAX
	if cliff_max <= 0.0:
		return 1.0
	if max_durability <= 0.0:
		return 1.0
	var wear_frac: float = clampf(1.0 - durability / max_durability, 0.0, 1.0)
	if wear_frac <= max_thr:
		return 1.0
	var ramp: float = (wear_frac - max_thr) / maxf(0.0001, 1.0 - max_thr)
	return 1.0 + cliff_max * clampf(ramp, 0.0, 1.0)


## XCamp-4o: damage-type-accurate wear-rate modifier. Real materials fail differently by
## failure mode: flexible layers (low rigidity) fray/tear faster from cuts but absorb blunts
## (padding is their design purpose), while rigid layers deflect blade (cuts wear them
## slower) but are dented by blows (blunts wear them faster). bias = 2*rigidity - 1 runs
## -1 (fully flexible) to +1 (fully rigid); at rigidity 0.5 the modifier is exactly 1.0 for
## both types. SHARP: 1 - spread*bias. BLUNT: 1 + spread*bias. Clamped to [0.1, 2.0] so the
## rate can never go negative or absurd. 0.0 spread or an empty damage_type returns 1.0
## (constant wear rate, pre-4o behaviour).
static func _wear_type_modifier(rigidity: float, damage_type: String) -> float:
	var spread: float = ArmorConstants.ARMOR_WEAR_DAMAGE_TYPE_SPREAD
	if spread <= 0.0 or damage_type == "":
		return 1.0
	var bias: float = 2.0 * rigidity - 1.0
	if damage_type == ArmorConstants.DAMAGE_TYPE_SHARP:
		return clampf(1.0 - spread * bias, 0.1, 2.0)
	if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		return clampf(1.0 + spread * bias, 0.1, 2.0)
	return 1.0


## XCamp-4q: breakthrough crush. When a hit destroys a layer (transitions it to durability 0),
## the next surviving inner layer takes a one-time durability penalty — the shock of sudden
## exposure plus spall/debris from the failed outer layer. `absorbed_by_broken` is the energy
## the broken layer absorbed this hit; the inner layer's extra wear is that times
## ARMOR_BREAKTHROUGH_CRUSH_RATIO, applied through the normal wear math (so it also respects
## thresholds, rate, fatigue, and damage-type modifiers). No-op when the ratio is 0.0, when
## absorbed energy is 0, or when no surviving inner layer exists after `broken_index`.
func apply_breakthrough_crush(broken_index: int, absorbed_by_broken: float, damage_type: String = "") -> void:
	var ratio: float = ArmorConstants.ARMOR_BREAKTHROUGH_CRUSH_RATIO
	if ratio <= 0.0 or absorbed_by_broken <= 0.0:
		return
	var crush: float = absorbed_by_broken * ratio
	for j in range(broken_index + 1, layers.size()):
		var inner: Dictionary = layers[j]
		if inner is Dictionary and not _is_layer_destroyed(inner):
			_apply_durability_loss(inner, crush, damage_type)
			return


## `ignore_threshold` skips the "no wear unless absorbed clears the floor" gate: used for a
## penetrated cut, where the edge is passing through the layer, so it tears the layer even when
## little edge energy is left. Without it a worn-through layer (effective RHA -> 0, absorbing
## ~nothing) would asymptote just above zero durability and never fully fail.
func _apply_durability_loss(
	layer: Dictionary, damage_absorbed: float, damage_type: String = "", ignore_threshold: bool = false
) -> void:
	# Threshold: sharp (mm RHA) for penetration toughness; for blunt-origin damage add term from absorption (1 -
	# blunt_transmission) so layers that absorb more blunt require more absorbed damage before wearing (research: energy
	# absorption and degradation linked; padding designed to absorb many small blows).
	var sharp_res: float = layer.get(
		ArmorConstants.ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM, ArmorConstants.DEFAULT_ARMOR_LAYER_SHARP_RESISTANCE
	)
	var threshold: float = maxf(
		ArmorConstants.DURABILITY_MIN_DAMAGE_FLAT, sharp_res * ArmorConstants.DURABILITY_MIN_DAMAGE_RATIO
	)
	if damage_type == ArmorConstants.DAMAGE_TYPE_BLUNT:
		var blunt_tx: float = layer.get("blunt_transmission", ArmorConstants.BLUNT_TRANSMISSION_DEFAULT)
		threshold += (1.0 - blunt_tx) * ArmorConstants.BLUNT_DURABILITY_THRESHOLD_RATIO
	if not ignore_threshold and damage_absorbed < threshold:
		return
	var rate: float = layer.get("durability_loss_rate", ArmorConstants.DURABILITY_LOSS_RATE)
	var cur_dur: float = layer.get(
		ArmorConstants.ARMOR_LAYER_KEY_DURABILITY, ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY
	)
	var max_dur: float = float(layer.get("max_durability", ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY))
	var fatigue_mult: float = _wear_fatigue_multiplier(cur_dur, max_dur)
	var rigidity: float = float(layer.get(ArmorConstants.ARMOR_LAYER_KEY_RIGIDITY, ArmorConstants.DEFAULT_ARMOR_LAYER_RIGIDITY))
	var type_mult: float = _wear_type_modifier(rigidity, damage_type)
	var cliff_mult: float = _wear_fatigue_cliff(cur_dur, max_dur)
	var loss: float = damage_absorbed * rate * fatigue_mult * type_mult * cliff_mult
	layer["durability"] = maxf(0.0, cur_dur - loss)


## Joule-path durability wear: called from ArmorJouleBudget.account_ke_through_armor with the KE (J)
## this layer absorbed. The joule walk uses the pure static math (which never mutated durability),
## so without this a piece absorbed identically on every contact. Converts absorbed J to durability
## loss via JOULE_KE_DURABILITY_SCALE so armor progressively fails under repeated blows.
## XCamp-4p: mirrors the scalar-path damage-type-accurate wear (4o) — `damage_type` is the layer's
## failure mode this contact, so the authoritative joule path matches the scalar fallback. Empty
## ("" default) yields the pre-4p constant-rate behaviour, keeping back-compat for direct callers.
func apply_joule_durability_loss(layer: Dictionary, absorbed_j: float, damage_type: String = "") -> void:
	if absorbed_j <= 0.0:
		return
	var rate: float = layer.get("durability_loss_rate", ArmorConstants.DURABILITY_LOSS_RATE)
	var cur_dur: float = layer.get(
		ArmorConstants.ARMOR_LAYER_KEY_DURABILITY, ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY
	)
	var max_dur: float = float(layer.get("max_durability", ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY))
	var fatigue_mult: float = _wear_fatigue_multiplier(cur_dur, max_dur)
	var rigidity: float = float(layer.get(ArmorConstants.ARMOR_LAYER_KEY_RIGIDITY, ArmorConstants.DEFAULT_ARMOR_LAYER_RIGIDITY))
	var type_mult: float = _wear_type_modifier(rigidity, damage_type)
	var cliff_mult: float = _wear_fatigue_cliff(cur_dur, max_dur)
	var loss: float = absorbed_j * rate * ArmorConstants.JOULE_KE_DURABILITY_SCALE * fatigue_mult * type_mult * cliff_mult
	layer["durability"] = maxf(0.0, cur_dur - loss)


## XCamp-4i: a worn layer protects less. Returns the layer's effective protection factor in
## [0,1]: 1.0 when the layer is at full durability (bit-identical to the unworn path), scaling
## down toward 0.0 as it wears to nothing. Global tuning via ARMOR_WEAR_DEGRADATION_STRENGTH
## (0.0 disables degradation entirely).
static func _layer_protection_factor(layer: Dictionary) -> float:
	var strength: float = ArmorConstants.ARMOR_WEAR_DEGRADATION_STRENGTH
	if strength <= 0.0:
		return 1.0
	var max_dur: float = float(
		layer.get("max_durability", ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
	)
	if max_dur <= 0.0:
		return 1.0
	var dur: float = float(
		layer.get(ArmorConstants.ARMOR_LAYER_KEY_DURABILITY, ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
	)
	var raw: float = clampf(dur / max_dur, 0.0, 1.0)
	return lerpf(1.0, raw, clampf(strength, 0.0, 1.0))


## XCamp-4u: wear-scaled sharp resistance (mm RHA) for a single layer. Mirrors the XCamp-4k
## material-accurate wear curve: a worn layer's effective cut-resistance drops, and rigid layers
## (plate/mail) keep more than soft layers (cloth/leather). Fresh (prot=1) returns the base value
## bit-identically; destroyed (prot=0) returns 0. Single source of truth shared by the damage
## math (sharp_penetration_math) and out-of-math consumers (get_outer_layer_effective_rha_mm).
static func _layer_effective_sharp_resistance(layer: Dictionary) -> float:
	var sharp_res: float = float(
		layer.get(
			ArmorConstants.ARMOR_LAYER_KEY_SHARP_RESISTANCE_RHA_MM, ArmorConstants.DEFAULT_ARMOR_LAYER_SHARP_RESISTANCE
		)
	)
	var prot: float = _layer_protection_factor(layer)
	if prot < 1.0:
		var rigidity: float = float(
			layer.get(ArmorConstants.ARMOR_LAYER_KEY_RIGIDITY, ArmorConstants.DEFAULT_ARMOR_LAYER_RIGIDITY)
		)
		var exponent: float = clampf(1.0 - rigidity * ArmorConstants.ARMOR_WEAR_RIGIDITY_SHIELD, 0.1, 1.0)
		sharp_res *= pow(prot, exponent)
	return sharp_res


## XCamp-4v: wear-aware sharp resistance (mm RHA) for a single layer, exposed for
## ArmorPenetrationTrace so wound-depth tracking degrades with armor wear the same
## way the damage math does (fresh layers return the base value bit-identically).
static func effective_sharp_resistance_for_layer(layer: Dictionary) -> float:
	return _layer_effective_sharp_resistance(layer)


## Shared sharp penetration math  -  used by both ArmorPiece and ArmorJouleBudget.
## Returns { damage, deflected }. Single source of truth for the penetration formula.
##
## Deflection is KE-dependent: the old flat branch (incoming * sharp_deflect_transmission) made
## plate armor a near-binary on/off shield — a 35 J and a 145 J sword cut both transmitted ~29%
## because sword-cut penetration (0.95-2.24 mm) is always below plate's 3.5 mm RHA. Now the
## deflected transmission ramps from the layer's base value up to the penetration-branch floor
## (PENETRATION_DAMAGE_REDUCTION_MAX complement, ~0.25) as penetration approaches the layer's
## resistance, so a harder hit transmits more and the two branches meet continuously at the
## threshold (no discontinuity).
static func sharp_penetration_math(pen_rha: float, layer: Dictionary, incoming: float) -> Dictionary:
	var sharp_res: float = _layer_effective_sharp_resistance(layer)
	var prot: float = _layer_protection_factor(layer)
	var current_pen: float = pen_rha
	if current_pen < sharp_res:
		var base_transmission: float = float(
			layer.get(
				"sharp_deflect_transmission",
				layer.get("deflection_transmission", ArmorConstants.SHARP_DEFLECT_TRANSMISSION_DEFAULT)
			)
		)
		# XCamp-4r: worn deflection. A worn surface no longer presents a clean bevel, so the
		# fraction of a stopped cut that passes through as blunt shock rises with wear_frac.
		# XCamp-4s: wear_frac is shaped convexly (1 - pow(prot, curve_exp)) so a worn bevel
		# stays clean through most of a layer's life and degrades sharply only near failure.
		# At full durability the factor is exactly 1.0 (fresh armor bit-identical to pre-4r).
		if prot < 1.0 and ArmorConstants.ARMOR_WEAR_DEFLECT_PENALTY > 0.0:
			var wear_frac_deflect: float = 1.0 - pow(prot, ArmorConstants.ARMOR_WEAR_CURVE_EXPONENT)
			base_transmission *= 1.0 + ArmorConstants.ARMOR_WEAR_DEFLECT_PENALTY * wear_frac_deflect
		# Proximity of penetration to the layer's resistance: 0 = glancing (full deflection),
		# 1 = at the threshold (armor nearly failing). Ramps the deflected transmission up to
		# the penetration-branch floor so the branches are continuous at sharp_res.
		var proximity: float = clampf(current_pen / maxf(0.001, sharp_res), 0.0, 1.0)
		var penetration_floor: float = 1.0 - ArmorConstants.PENETRATION_DAMAGE_REDUCTION_MAX
		var transmission: float = lerpf(base_transmission, penetration_floor, proximity)
		var after: float = incoming * clampf(transmission, 0.0, 1.0)
		return {"damage": after, "deflected": true}
	var factor: float = clampf(
		1.0 - (sharp_res / maxf(1.0, current_pen)) * ArmorConstants.PENETRATION_DAMAGE_REDUCTION_MAX, 0.0, 1.0
	)
	return {"damage": incoming * factor, "deflected": false}


## Shared blunt transmission math  -  used by both ArmorPiece and ArmorJouleBudget.
## Returns transmitted damage value. Single source of truth for the cushion/coupling formula.
## blunt_contact_cm drives the rigid-plate area coupling. blunt_coupling_contact_cm, when >= 0, is the
## weapon's TRUE (uncapped) contact face used for that coupling: a mace's broad head drives more of a
## rigid plate into the body, so it must couple at full face size even though the pressure/penetration
## channel caps its effective face at BLUNT_HEAD_MAX_CONTACT_CM. -1.0 falls back to blunt_contact_cm.
static func blunt_transmission_math(
	incoming: float,
	layer: Dictionary,
	blunt_momentum_per_area: float,
	blunt_contact_cm: float,
	blunt_coupling_contact_cm: float = -1.0
) -> float:
	var base_tx: float = float(layer.get("blunt_transmission", ArmorConstants.BLUNT_TRANSMISSION_DEFAULT))
	var cushion: float = float(
		layer.get(ArmorConstants.ARMOR_LAYER_KEY_BLUNT_CUSHION, ArmorConstants.DEFAULT_ARMOR_LAYER_BLUNT_CUSHION)
	)
	var prot: float = _layer_protection_factor(layer)
	if prot < 1.0:
		base_tx = lerpf(1.0, base_tx, prot)
		# XCamp-4l: material-accurate cushion wear. A torn gambeson/cloth loses its
		# padding; a dented plate barely loses any (its small cushion value is really the
		# underlayer's job). Same rigidity shield as the sharp axis, so a rigid layer
		# keeps cushioning far longer. Pinned: prot=1 -> 1.0 (fresh, unchanged), prot=0 ->
		# 0.0 (a destroyed layer cushions nothing, full transmission — the 4i invariant).
		var cushion_rigidity: float = float(
			layer.get(ArmorConstants.ARMOR_LAYER_KEY_RIGIDITY, ArmorConstants.DEFAULT_ARMOR_LAYER_RIGIDITY)
		)
		var cushion_exponent: float = clampf(1.0 - cushion_rigidity * ArmorConstants.ARMOR_WEAR_RIGIDITY_SHIELD, 0.1, 1.0)
		cushion *= pow(prot, cushion_exponent)
	var transmission: float
	if blunt_momentum_per_area < 0.0 or cushion <= 0.0:
		transmission = base_tx * (1.0 - cushion)
	else:
		var thresh: float = ArmorConstants.BLUNT_CUSHION_MOMENTUM_THRESHOLD
		var momentum_factor: float = clampf(1.0 - blunt_momentum_per_area / thresh, 0.0, 1.0)
		transmission = base_tx * (1.0 - cushion * momentum_factor)
	var rigidity: float = float(
		layer.get(ArmorConstants.ARMOR_LAYER_KEY_RIGIDITY, ArmorConstants.DEFAULT_ARMOR_LAYER_RIGIDITY)
	)
	if rigidity >= ArmorConstants.RIGIDITY_THRESHOLD and blunt_contact_cm > 0.0:
		# Coupling uses the weapon's TRUE face (blunt_coupling_contact_cm) when supplied: a broad
		# head (mace) drives more of a rigid plate into the body, so it must couple at full face
		# size. The pressure/penetration channel passes the capped face (BLUNT_HEAD_MAX_CONTACT_CM)
		# as blunt_contact_cm; using that here would make the largest blunt weapon — the one that
		# defines the reference — couple at only cap/reference instead of 1.0.
		var coupling_cm: float = (
			blunt_coupling_contact_cm if blunt_coupling_contact_cm >= 0.0 else blunt_contact_cm
		)
		var ref_cm: float = WeaponConstants.get_blunt_coupling_reference_cm()
		var area_factor: float = coupling_cm / ref_cm
		var coupling: float = lerpf(1.0, area_factor, rigidity)
		transmission *= coupling
	return incoming * clampf(transmission, 0.0, 1.0)


## XCamp-4u: wear-aware outer-layer sharp resistance. Returns the effective RHA of the
## outermost surviving layer, accounting for the 4k material-accurate wear curve.
## Use this for out-of-math consumers (AI doctrine, mace bonus) so they reflect current wear.
func get_outer_layer_effective_rha_mm() -> float:
	for layer in layers:
		if not _is_layer_destroyed(layer):
			return _layer_effective_sharp_resistance(layer)
	return 0.0
