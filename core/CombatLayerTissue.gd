class_name CombatLayerTissue
extends RefCounted

## S6/S9/M3 layer-tissue: flat budget (S6) or yield/rupture sheets (M3) before bone MFB.
## Arm stack 2+3 mm: subcut + muscle order-of-magnitude vs upper-limb ultrasound SC fat (~3–8 mm, BMI-dependent).

const _Bleeding := preload("res://core/BleedingConstants.gd")

const LAYER_NAME_SUBCUTANEOUS := "subcutaneous"
const LAYER_NAME_MUSCLE := "muscle"

## Per-part soft-tissue stack (mm): [subcutaneous, muscle, …]. Sum matches legacy single budget.
const SOFT_TISSUE_LAYER_STACK_MM_BY_PART: Dictionary = {
	"head": [1.5, 2.5],
	"chest": [3.0, 5.0],
	"right_arm": [2.0, 3.0],
	"left_arm": [2.0, 3.0],
	"right_leg": [2.5, 4.5],
	"left_leg": [2.5, 4.5],
}

## M3 yield/rupture (mm into layer) — budget_mm matches stack slice.
const LAYER_YIELD_RUPTURE_BY_PART: Dictionary = {
	"head": [
		{"name": LAYER_NAME_SUBCUTANEOUS, "yield_pen_mm": 0.6, "rupture_pen_mm": 1.5, "budget_mm": 1.5},
		{"name": LAYER_NAME_MUSCLE, "yield_pen_mm": 1.2, "rupture_pen_mm": 2.5, "budget_mm": 2.5},
	],
	"chest": [
		{"name": LAYER_NAME_SUBCUTANEOUS, "yield_pen_mm": 1.0, "rupture_pen_mm": 2.5, "budget_mm": 3.0},
		{"name": LAYER_NAME_MUSCLE, "yield_pen_mm": 2.0, "rupture_pen_mm": 4.0, "budget_mm": 5.0},
	],
	"right_arm": [
		{"name": LAYER_NAME_SUBCUTANEOUS, "yield_pen_mm": 0.8, "rupture_pen_mm": 2.0, "budget_mm": 2.0},
		{"name": LAYER_NAME_MUSCLE, "yield_pen_mm": 1.5, "rupture_pen_mm": 3.0, "budget_mm": 3.0},
	],
	"left_arm": [
		{"name": LAYER_NAME_SUBCUTANEOUS, "yield_pen_mm": 0.8, "rupture_pen_mm": 2.0, "budget_mm": 2.0},
		{"name": LAYER_NAME_MUSCLE, "yield_pen_mm": 1.5, "rupture_pen_mm": 3.0, "budget_mm": 3.0},
	],
	"right_leg": [
		{"name": LAYER_NAME_SUBCUTANEOUS, "yield_pen_mm": 0.9, "rupture_pen_mm": 2.2, "budget_mm": 2.5},
		{"name": LAYER_NAME_MUSCLE, "yield_pen_mm": 1.6, "rupture_pen_mm": 3.2, "budget_mm": 4.5},
	],
	"left_leg": [
		{"name": LAYER_NAME_SUBCUTANEOUS, "yield_pen_mm": 0.9, "rupture_pen_mm": 2.2, "budget_mm": 2.5},
		{"name": LAYER_NAME_MUSCLE, "yield_pen_mm": 1.6, "rupture_pen_mm": 3.2, "budget_mm": 4.5},
	],
}

static var _harness_force_layer_tissue: bool = false
static var _harness_force_layer_tissue_curves: bool = false


static func is_active(force: bool = false) -> bool:
	return force or _Bleeding.FEATURE_LAYER_TISSUE or _harness_force_layer_tissue


static func is_curves_active(force: bool = false) -> bool:
	return force or _Bleeding.FEATURE_LAYER_TISSUE_CURVES or _harness_force_layer_tissue_curves


static func is_layer_penetration_active(force_layer: bool = false, force_curves: bool = false) -> bool:
	return is_active(force_layer) or is_curves_active(force_curves)


static func layer_definitions(part: String) -> Array:
	var row: Variant = LAYER_YIELD_RUPTURE_BY_PART.get(part, LAYER_YIELD_RUPTURE_BY_PART["right_arm"])
	if row is Array:
		return row.duplicate(true)
	return LAYER_YIELD_RUPTURE_BY_PART["right_arm"].duplicate(true)


static func seed_layer_state_for_part(part: String) -> Array:
	var out: Array = []
	for def: Dictionary in layer_definitions(part):
		out.append(
			{
				"name": str(def.get("name", "")),
				"state": "intact",
				"accumulated_pen_mm": 0.0,
			}
		)
	return out


static func seed_all_layer_states(entity: Node) -> void:
	if not entity.has_method("_get_body_part_list"):
		return
	entity.tissue_layer_state = {}
	for part: Variant in entity._get_body_part_list():
		entity.tissue_layer_state[str(part)] = seed_layer_state_for_part(str(part))


static func soft_tissue_layer_stack_mm(part: String) -> Array:
	var row: Variant = SOFT_TISSUE_LAYER_STACK_MM_BY_PART.get(part, [2.5, 2.5])
	if row is Array:
		return row
	return [2.5, 2.5]


static func soft_tissue_budget_mm(part: String) -> float:
	var total: float = 0.0
	for layer_mm in soft_tissue_layer_stack_mm(part):
		total += float(layer_mm)
	return total


## J absorbed in muscle/fat before bone sees blunt fracture KE (order-of-magnitude; not FEM).
const BLUNT_TISSUE_KE_BUDGET_J_BY_PART: Dictionary = {
	"head": 25.0,
	"chest": 35.0,
	"right_arm": 22.0,
	"left_arm": 22.0,
	"right_leg": 28.0,
	"left_leg": 28.0,
}


## Remaining KE reaching bone for blunt MFB when `FEATURE_BLUNT_TISSUE_KE_GATE` is on.
static func blunt_ke_reaching_bone(part: String, strike_ke_j: float) -> float:
	if strike_ke_j < 0.0:
		return -1.0
	if not _Bleeding.FEATURE_BLUNT_TISSUE_KE_GATE:
		return strike_ke_j
	var budget: float = float(BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get(part, 24.0))
	return maxf(-1.0, strike_ke_j - budget)


static func _state_rank(state: String) -> int:
	match state:
		"ruptured":
			return 2
		"damaged":
			return 1
		_:
			return 0


static func _merge_layer_state(prev: String, next: String) -> String:
	return next if _state_rank(next) > _state_rank(prev) else prev


static func _state_from_pen(absorbed_mm: float, yield_mm: float, rupture_mm: float) -> String:
	if absorbed_mm >= rupture_mm:
		return "ruptured"
	if absorbed_mm >= yield_mm:
		return "damaged"
	return "intact"


## M3: yield → damaged → ruptured; excess pen past rupture flows to deeper layers.
static func penetration_through_layers(
	part: String, penetration_sharp_mm: float, layer_state: Array, active: bool = true
) -> Dictionary:
	if not active or penetration_sharp_mm < 0.0:
		return penetration_after_soft_tissue(part, penetration_sharp_mm, true)
	var remaining: float = penetration_sharp_mm
	var absorbed_total: float = 0.0
	var per_layer_absorbed: Array = []
	var states_out: Array = []
	var defs: Array = layer_definitions(part)
	for i in defs.size():
		var def: Dictionary = defs[i]
		var budget: float = float(def.get("budget_mm", 2.0))
		var yield_mm: float = float(def.get("yield_pen_mm", 0.8))
		var rupture_mm: float = float(def.get("rupture_pen_mm", 2.0))
		var row: Dictionary = (
			layer_state[i]
			if i < layer_state.size() and layer_state[i] is Dictionary
			else {"name": str(def.get("name", "")), "state": "intact", "accumulated_pen_mm": 0.0}
		)
		var prev_state: String = str(row.get("state", "intact"))
		if remaining <= 0.0:
			per_layer_absorbed.append(0.0)
			states_out.append(
				{
					"name": str(def.get("name", "")),
					"state": prev_state,
					"accumulated_pen_mm": float(row.get("accumulated_pen_mm", 0.0)),
				}
			)
			continue
		var absorbed: float = minf(remaining, budget)
		var new_state: String = _merge_layer_state(
			prev_state, _state_from_pen(absorbed, yield_mm, rupture_mm)
		)
		var held: float = absorbed
		if new_state == "ruptured":
			held = minf(absorbed, rupture_mm)
			remaining = maxf(0.0, remaining - held)
		else:
			remaining = maxf(0.0, remaining - absorbed)
		absorbed_total += held
		per_layer_absorbed.append(held)
		states_out.append(
			{
				"name": str(def.get("name", "")),
				"state": new_state,
				"accumulated_pen_mm": held,
			}
		)
	return {
		"penetration_to_bone_mm": remaining,
		"layer_absorbed_mm": absorbed_total,
		"soft_tissue_budget_mm": soft_tissue_budget_mm(part),
		"layers_absorbed_mm": per_layer_absorbed,
		"layer_states": states_out,
		"layer_state": states_out,
	}


static func penetration_after_soft_tissue(part: String, penetration_sharp_mm: float, active: bool = true) -> Dictionary:
	if not active or penetration_sharp_mm < 0.0:
		return {
			"penetration_to_bone_mm": penetration_sharp_mm,
			"layer_absorbed_mm": 0.0,
			"soft_tissue_budget_mm": soft_tissue_budget_mm(part),
			"layers_absorbed_mm": [],
		}
	var remaining: float = penetration_sharp_mm
	var absorbed_total: float = 0.0
	var per_layer: Array = []
	for layer_mm in soft_tissue_layer_stack_mm(part):
		var budget: float = float(layer_mm)
		var take: float = minf(remaining, budget)
		per_layer.append(take)
		absorbed_total += take
		remaining = maxf(0.0, remaining - take)
		if remaining <= 0.0:
			break
	return {
		"penetration_to_bone_mm": remaining,
		"layer_absorbed_mm": absorbed_total,
		"soft_tissue_budget_mm": soft_tissue_budget_mm(part),
		"layers_absorbed_mm": per_layer,
	}


## M3: optional bleed/severity bump when subcutaneous ruptured on part.
static func layer_rupture_bleed_mult(entity: Node, part: String) -> float:
	if entity == null or not ("tissue_layer_state" in entity):
		return 1.0
	var rows: Variant = entity.tissue_layer_state.get(part, [])
	if not rows is Array:
		return 1.0
	for row: Variant in rows:
		if row is Dictionary:
			if (
				str(row.get("name", "")) == LAYER_NAME_SUBCUTANEOUS
				and str(row.get("state", "")) == "ruptured"
			):
				return _Bleeding.LAYER_RUPTURE_SUBCUT_BLEED_MULT
	return 1.0
