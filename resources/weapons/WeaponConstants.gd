class_name WeaponConstants
extends RefCounted

## Per-weapon move defs + Expand WF spawn keys: **`default_form`** / **`allowed_forms[]`** feed
## **`CombatWeaponForm.seed_combatant_form`** (resolution step 4). LIVE_PATHS **`#spawn--reset-path-wf-1a`** ??
## **`#wf-assign-form-contract`**.

# Damage types (also in CombatConstants; defined here to avoid circular preload)
const DAMAGE_TYPE_SHARP: String = "sharp"
const DAMAGE_TYPE_BLUNT: String = "blunt"

# Archetype / kinematic IDs (owned by WeaponTemplateDefinitions; re-exported for WeaponConstants.X resolution)
const ARCHETYPE_STAB := WeaponTemplateDefinitions.ARCHETYPE_STAB
const ARCHETYPE_SLASH := WeaponTemplateDefinitions.ARCHETYPE_SLASH
const ARCHETYPE_OVERHEAD := WeaponTemplateDefinitions.ARCHETYPE_OVERHEAD
const ARCHETYPE_QUICK_SLASH := WeaponTemplateDefinitions.ARCHETYPE_QUICK_SLASH
const ARCHETYPE_POMMEL := WeaponTemplateDefinitions.ARCHETYPE_POMMEL
const ARCHETYPE_HEAVY_BLUNT := WeaponTemplateDefinitions.ARCHETYPE_HEAVY_BLUNT
const ARCHETYPE_THRUSTING_BLUNT := WeaponTemplateDefinitions.ARCHETYPE_THRUSTING_BLUNT
const KINEMATIC_DELIVERY_THRUST := WeaponTemplateDefinitions.KINEMATIC_DELIVERY_THRUST
const KINEMATIC_DELIVERY_SWING := WeaponTemplateDefinitions.KINEMATIC_DELIVERY_SWING
const KINEMATIC_DELIVERY_MIXED := WeaponTemplateDefinitions.KINEMATIC_DELIVERY_MIXED
const DEFAULT_COOLDOWN := WeaponTemplateDefinitions.DEFAULT_COOLDOWN

# Attack types: stab (point), cut/slash (edge), blunt/swing (head).
# Contact area per attack: stab -> point_width, cut -> blade_width, blunt -> head_diameter.
const ATTACK_TYPE_STAB: String = "stab"
const ATTACK_TYPE_CUT: String = "cut"
const ATTACK_TYPE_BLUNT: String = "blunt"

# Default baseline for physical modifier (contact area, cm)
const BASELINE_CONTACT_CM: float = 2.0
const BASELINE_MASS_KG: float = 1.0
const J_PER_MM_BASE: float = 55.0  # Williams: 55 J for 1 mm mild steel
const PENETRATION_EXPONENT: float = 0.6  # 1/1.67; thicker armor needs disproportionately more energy
# Global impact speed floor/ceiling (m/s): fallback when a weapon template has no Tier-A band entry; ImpactVelocityModel
# uses these (see ImpactVelocityModel._tier_a_default_band).
const VELOCITY_MIN_M_S: float = 6.0
const VELOCITY_MAX_M_S: float = 24.0
# Damage pre-armor: scale * sqrt(KE) * strength_mod * arm_mod * contact_factor.
# sqrt(KE) is a game abstraction — Yoganandan et al. (J. Trauma) reports LINEAR energy thresholds
# for tissue severance (~400-600 J sharp for arm), but a square-root flattens the damage curve so
# extreme strikes don't trivialize armor. Calibrated so DESIGN_KE_ARM_J=100 gives ~35 pre_armor,
# and DAMAGE_KE_MAX=90 corresponds to KE=(90/3.5)^2 ≈ 661 J — within the arm-severance band.
const DAMAGE_KE_SCALE: float = 3.5  # Game-tuning constant; sqrt(KE) flattening calibrated so 100J→35 dmg, cap at ~522J≈arm-severance
const DAMAGE_KE_MIN: float = 1.0

# Pre-armor sharp damage hard cap — corresponds to KE=(90/3.5)^2 ≈ 661 J, within the Yoganandan arm-severance band (400-600J).
const DAMAGE_KE_MAX: float = 90.0

# Cap penetration (mm RHA) from KE — physically grounded: Williams formula at max realistic combat KE (~130-160J spear thrust / mace overhead)
# with favorable point geometry gives ~14mm RHA. Cap prevents edge-case amplification from area_factor scaling.
# Sources: Williams 1950; Knight "Medieval Armor" 2003; Lehmann force-plate HEMA data 2013
const PENETRATION_KE_CAP_MM_RHA: float = 15.0

# Sharp: smaller contact (point) penetrates better than wide (cut). Factor = (BASELINE / contact_width_cm)^CONTACT_AREA_EXPONENT.
const CONTACT_AREA_EXPONENT: float = 0.5
const MIN_CONTACT_WIDTH_CM: float = 0.3
# Contact area in damage: smaller contact -> more local tissue disruption via stress concentration.
# Game-tuned exponent — chosen so dagger tip (0.3cm) gets ~1.5x vs sword edge (~1.7cm) at baseline 2.0cm.
# At exponent=0.23: dagger=(2/0.3)^0.23≈1.55, sword=(2/1.7)^0.23≈1.04. Cap prevents tiny contacts from overscaling.
const CONTACT_DAMAGE_EXPONENT: float = 0.23  # Game-tuned; gives dagger ~1.5x vs sword edge ~1.04x at baseline contact
const CONTACT_DAMAGE_FACTOR_MAX: float = 1.50  # Cap on point-contact amplification; prevents tiny contacts from exceeding 1.5x
# Blunt: transmission-only (no rigid check). Older blunt rigid-penetration constants were removed in favor of this
# model.
# Floor so tiny contacts don't produce absurd momentum/area; 1 cm min keeps normal blade areas unchanged.
const MIN_BLUNT_AREA_M2: float = 1e-4
# For CUT moves, blunt stream uses at least this contact (cm) so the "slap" doesn't get blade pressure.
const BLUNT_CUT_MIN_CONTACT_CM: float = 5.0
# For STAB moves, blunt slip channel uses at least this contact (cm) so point-thrust blunt damage isn't amplified by tiny
# contact area. The blunt pressure formula was calibrated for ~3 cm² blade-slap contacts; using geometric point area
# (~0.5 cm² for dagger) would produce absurdly high pressure from modest momentum. Floor of 2.5 cm ensures stab blunt
# slip damage stays in the same calibration regime as cut slap — both represent transmitted energy through a broad face.
const BLUNT_STAB_MIN_CONTACT_CM: float = 2.5
# For BLUNT moves, the pressure formula caps the effective contact so a large head doesn't dissipate momentum over a
# huge face. A mace head (8 cm diameter) only couples through a small patch of flesh at impact, not the full 64 cm²
# cross-section; without this cap the mace pressure (and thus damage) drops ~21× below the ~3 cm² calibration and the
# weapon underperforms even a dagger. Cap of 2.5 cm keeps blunt heads in the same calibration regime as stab slip.
const BLUNT_HEAD_MAX_CONTACT_CM: float = 2.5
# No weapon is 0% cutting: even maces can break skin (flanges/ridges). Floor for cut_ratio.
const MIN_CUT_RATIO: float = 0.02

# --- Effective edge (sharpness) for cutting ---
## Sharpness 0-1: effective sharp contact = geometric / (SHARPNESS_FACTOR_MIN + (1 - SHARPNESS_FACTOR_MIN) * sharpness).
## Sharpness 1 = geometric; sharpness 0 = geometric/0.2 (duller = wider effective contact = less penetration).
const SHARPNESS_FACTOR_MIN: float = 0.2

# --- Edge geometry (wedge mechanics by included angle) ---
## Clinical/metallurgical basis: cutting force depends on wedge angle — sharper edges displace less material per mm depth.
## Wedge mechanics: F = RHA_thickness / sin(edge_angle/2); a 30° wedge needs ~4× less force than 90°.
## Historical steel edge angles (measured in modern replicas): fighting swords ~18-25°, daggers ~20-30°, battle axes ~25-35°.
## Dull edges (battle-worn): 40-60°; very dull/nicks: 70-90°+. Sharpness stat maps to effective edge angle.
# Default included angle for a freshly ground fighting sword edge (degrees).
const EDGE_ANGLE_DEFAULT_DEG: float = 28.0
# Sharpness-to-edge-angle mapping range: sharp=1 → EDGE_ANGLE_SHARP_DEG, dull=0 → EDGE_ANGLE_DULL_DEG.
const EDGE_ANGLE_SHARP_DEG: float = 25.0      # newly ground fighting edge (historical swords ~25-35°)
const EDGE_ANGLE_DULL_DEG: float = 65.0        # battle-worn/nicked edge (70°+ is essentially blunt)
# Wedge penetration bonus: sin(DEFAULT/2) / sin(angle/2) scales how much easier a sharper wedge penetrates vs dull.
## At sharp=1 (25°): factor = sin(14°)/sin(12.5°) ≈ 1.12 — ~12% penetration boost over default.
## At sharp=0 (65°): factor = sin(14°)/sin(32.5°) ≈ 0.448 — ~55% reduction vs default (dull edge struggles to bite).
# Floor so even razor-sharp edges don't trivialize thick armor.
const EDGE_WEDGE_PENETRATION_FLOOR: float = 0.3   # minimum wedge factor, keeps dull weapons still dangerous

# --- Pressure-based blunt damage (replaces flat DAMAGE_MOMENTUM_SCALE) ---
## P = m·v/(A·Δt): pressure at wound interface where Δt is contact duration, A is contact area.
const BLUNT_IMPACT_CONTACT_TIME_MS: float = 12.0       # Median of measured range 8-18ms for rigid steel vs yielding flesh (Campbell et al., J. Biomechanics 36:1157)
## Δt reference impact speed (m/s): the 12 ms constant is anchored at this tip speed. Faster impacts have
## shorter pulse width (elastic-plastic contact duration scales ~v^-0.4), so peak force rises above linear-in-v.
const BLUNT_IMPACT_REFERENCE_SPEED_M_S: float = 10.0
## Δt speed exponent: Δt(v) = Δt_ref · (v/v_ref)^(-BLUNT_CONTACT_TIME_SPEED_EXPONENT). 0.4 sits in the
## measured 0.3-0.5 band for rigid-on-yielding impacts (Campbell et al.); 0 keeps the legacy constant model.
const BLUNT_CONTACT_TIME_SPEED_EXPONENT: float = 0.4
## Δt clamp (s): prevents sub-band velocities from inflating contact time into unrealistic multi-ms pulses.
const BLUNT_CONTACT_TIME_MIN_S: float = 0.005
const BLUNT_CONTACT_TIME_MAX_S: float = 0.025
## BLUNT_DAMAGE_PER_UNIT_PRESSURE: game-tuning coefficient calibrated so a typical mace impact produces ~25-45 damage after strength/mod factors are applied. Uses aggregate contact pressure (not peak stress), so the coefficient absorbs modeling simplifications — not directly derivable from clinical thresholds.
const BLUNT_DAMAGE_PER_UNIT_PRESSURE: float = 0.000025      # Pa→damage; game-tuning coefficient calibrated for mace impact range
const BLUNT_TARGET_EFFECTIVE_MASS_KG: float = 6.5         # Two-body reduced mass Plagenhofs limb-segment compliance; matches 5-8 kg biomechanical range for yielding tissue targets
## Effective inertia radius fraction — uniform rod about one end has I=mL²/3, but real weapons concentrate mass toward grip.
## Reduced from 0.48 to 0.35 (physics audit) and combined with removed separate MASS_DIST_CORRECTION:
## the single factor now correctly interpolates between measured values: dagger ~0.17m, arming sword ~0.32m, longswords ~0.42-0.50m.
const INERTIA_EFF_RADIUS_FRACTION: float = 0.35
const BLUNT_DAMAGE_MIN: float = 1.0       # Gameplay floor — prevents zero-damage hits from rounding or weak parry follow-throughs
const BLUNT_DAMAGE_MAX: float = 90.0      # Same ceiling as DAMAGE_KE_MAX; single blunt strike should not exceed maximal limb trauma in one blow

# --- Parry deflection damage transfer (Issue 4 + physics audit MEDIUM #7) ---
## Momentum-based impulse model: F = Δp/Δt where blade contact time ≈ 20ms (HEMA force-plate studies).
## Deflected momentum transmits to defender's arm at ~20% of incoming momentum fraction.
## Damage = momentum_transfer × IMPULSE_DAMAGE_SCALE × PARRY_DEFLECTION_SHOCK_TRANSFER. A parry transmits a small
## fraction of the incoming blow's momentum into the defender's arm (HEMA force-plate: ~20% of incoming momentum).
## Energy analysis: a sword parry deposits ~0.1-0.3 J into the arm (vs ~100 J for a full hit), so a typical parry
## deals a SMALL amount (~0.2-1.0), meaningful mainly for heavy blows (mace). The >0.5 apply-gate suppresses the
## small values, so light parries are effectively free.
const PARRY_DEFLECTION_MOMENTUM_FRACTION: float = 0.20   # fraction of incoming momentum transferred to defender's arm
const IMPULSE_DAMAGE_SCALE: float = 0.6                   # converts (kg·m/s) impulse to game damage units
## Fraction of calculated impulse damage actually applied as tissue/bone blunt damage (rest absorbed by armor/weapon).
## Blade steel absorbs ~55% through flexion/vibration; remaining 45% transfers to defender's arm.
const PARRY_DEFLECTION_SHOCK_TRANSFER: float = 0.45
const WEAPON_MOVE_PREFERRED_PARTS: Dictionary = {
	"SPEAR":
	{
		"spear_thrust": ["chest"],
		"off_line_thrust": ["chest"],
		"false_cut": ["chest"],
		"inside_stab": ["chest"],
		"low_thrust_spear": ["left_leg", "right_leg"],
		"parry_thrust_spear": ["chest"],
	},
	"DAGGER":
	{
		"quick_thrust": ["chest"],
		"committed_thrust": ["chest"],
		"reverse_thrust": ["left_leg", "right_leg"],
		"low_thrust_dagger": ["left_leg", "right_leg"],
		"feint_thrust_dagger": ["chest"],
		"grab_strike": ["head"],
		"parry_thrust_dagger": ["chest"],
	},
	"MACE":
	{
		"overhead_strike": ["head"],
		"side_strike": ["left_arm", "right_arm"],
		"direct_blow": ["head", "chest"],
		"upcut_mace": ["left_leg", "right_leg"],
		"low_strike": ["left_leg", "right_leg"],
		"thrusting_blow": ["head", "chest"],
		"feint_overhead_mace": ["head"],
		"parry_thrust_mace": ["chest"],
	},
	"AXE":
	{
		"overhead_chop": ["head"],
		"spike_thrust": ["chest"],
		"poll_strike": ["head"],
		"horizontal_chop": ["left_arm", "right_arm", "chest"],
		"low_chop": ["left_leg", "right_leg"],
		"reverse_grip_thrust": ["chest"],
		"overhead_feint": ["head"],
		"parry_thrust_axe": ["chest"],
	},
}


## Weapon `mass` when present; else **`BASELINE_MASS_KG`** (parry, KE, inertia).
static func weapon_mass_kg(weapon: Variant) -> float:
	if weapon == null:
		return BASELINE_MASS_KG
	var mass_raw: Variant = weapon.get("mass") if weapon is Object else null
	if mass_raw is float or mass_raw is int:
		return float(mass_raw)
	return BASELINE_MASS_KG


## True when weapon requires two hands (muscle fatigue off-hand share).


## True when weapon requires two hands (muscle fatigue off-hand share).
static func weapon_is_two_handed(weapon: Variant) -> bool:
	if weapon == null:
		return false
	if weapon is Weapon:
		return weapon.is_two_handed
	var v: Variant = weapon.get("is_two_handed") if weapon is Object else null
	return v is bool and v


# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# Williams (Knight & Blast Furnace): 1mm=55J, 1.5mm=110J, 2mm=175J -- E ~ t^1.67. Nonlinear: pen =
# (KE/J_BASE)^PEN_EXPONENT.
# Material correction: medieval armor steel ~250-300 BHN vs modern RHA 450-500 HBW, making it
# roughly 1.5-1.7× easier to penetrate at equivalent thickness. Derived from metallurgical studies of surviving
# armor (Robinson 1974; Hirst & Williams 2006) rather than direct Williams testing.
# Obliquity: combat impacts are rarely normal; average deflection ~18° → effective thickness ×1.1 (t/cos(θ)).
const WILLIAMS_MATERIAL_CORRECTION := 1.6   # Medieval armor ~250-300 BHN vs RHA 450-500 HBW → ~1.6× easier penetration (Robinson 1974; Hirst & Williams 2006)
const WILLIAMS_OBLIQUITY_FACTOR := 1.1       # average combat deflection angle ~18°

## Stab/thrust penetration bonus: forensic consensus that stabs penetrate deeper than cuts of equivalent energy
## because force concentrates on tiny tip area rather than distributing along cutting edge (~1.6× per Knight's Forensic Pathology).
const STAB_PENETRATION_MULT := 1.5


# --- Move pool (historical / HEMA-inspired) ---
# Each move: id, name (UI), contact_type (stab/cut/blunt), archetype_id, base_cooldown.
# Parry moves have is_parry: true (explicit parry attack following a defensive action).
# Weapons reference move ids; get_available_attack_types() returns move ids for that weapon.
# contact_type maps to weapon dimensions: stab->point_width, cut->blade_width, blunt->head_diameter.
static func get_all_move_ids() -> Array:
	return WeaponMoveDefinitions._move_definitions_build().keys()


static func get_move(move_id: String) -> Dictionary:
	var all_moves := WeaponMoveDefinitions._move_definitions_build()
	if not all_moves.has(move_id):
		return {}
	return all_moves[move_id].duplicate(true)


static func is_parry_move(move_id: String) -> bool:
	var m = get_move(move_id)
	return m.get("is_parry", false)


static func is_feint_move(move_id: String) -> bool:
	var m = get_move(move_id)
	return m.get("is_feint", false)


# Per-weapon overrides for shared move defs (Layer B aim).


static func preferred_parts_for_weapon_move(weapon_id: String, move_id: String) -> Array:
	var wid: String = str(weapon_id).to_upper().strip_edges()
	if WEAPON_MOVE_PREFERRED_PARTS.has(wid):
		var per_weapon: Variant = WEAPON_MOVE_PREFERRED_PARTS[wid]
		if per_weapon is Dictionary and (per_weapon as Dictionary).has(move_id):
			var parts: Variant = (per_weapon as Dictionary)[move_id]
			if parts is Array:
				return (parts as Array).duplicate()
	var md: Dictionary = get_move(move_id)
	return md.get("preferred_parts", [])


## move_id (e.g. thrust, oberhau) -> stab | cut | blunt. Bare stab/cut/blunt pass through unchanged.
## Single source for combat + velocity; use this directly (not a separate forwarder).


## move_id (e.g. thrust, oberhau) -> stab | cut | blunt. Bare stab/cut/blunt pass through unchanged.
## Single source for combat + velocity; use this directly (not a separate forwarder).
static func contact_type_for_move_id(move_id: String) -> String:
	var key: String = move_id.to_lower().strip_edges()
	if key == ATTACK_TYPE_STAB or key == ATTACK_TYPE_CUT or key == ATTACK_TYPE_BLUNT:
		return key
	var md: Dictionary = get_move(move_id)
	if md.is_empty():
		return ATTACK_TYPE_CUT
	var ct: String = str(md.get("contact_type", ATTACK_TYPE_CUT)).to_lower()
	if ct == ATTACK_TYPE_STAB or ct == ATTACK_TYPE_CUT or ct == ATTACK_TYPE_BLUNT:
		return ct
	return ATTACK_TYPE_CUT


static func get_all_weapon_ids() -> Array:
	return ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]


# Use get_weapon_definition(weapon_id) for a fresh copy.
static func get_weapon_definition(weapon_id: String) -> Dictionary:
	var id_normalized := weapon_id.to_upper()
	var all := WeaponTemplateDefinitions._weapon_definitions_build()
	if not all.has(id_normalized):
		return {}
	return all[id_normalized].duplicate(true)


static func get_archetype(archetype_id: String) -> Dictionary:
	var all_arch := WeaponTemplateDefinitions._archetype_definitions_build()
	if not all_arch.has(archetype_id):
		push_warning("[WeaponConstants] Unknown archetype '%s', falling back to SLASH" % archetype_id)
		return all_arch.get(ARCHETYPE_SLASH, {})
	return all_arch[archetype_id].duplicate(true)


# Reference for area coupling: larger contact (mace) vs smaller (pommel). Using max(head_diameter)
# so the largest blunt weapon yields area_factor=1.0 and transmission stays <= layer blunt_transmission.
static func get_blunt_coupling_reference_cm() -> float:
	var ids: Array = get_all_weapon_ids()
	var max_hd: float = 0.0
	for wid in ids:
		var d: Dictionary = get_weapon_definition(wid)
		var hd = d.get("head_diameter", 0.0)
		if (hd is float or hd is int) and float(hd) > max_hd:
			max_hd = float(hd)
	return max_hd if max_hd > 0.0 else 6.0


## Weapon template id (`SWORD`, `AXE`, ï¿½) from equipped weapon node/dict.
static func weapon_type_id(weapon: Variant) -> String:
	return WeaponTemplateDefinitions._weapon_template_id(weapon)


## Legacy encounter / mood keys -> weapon-native form id (e.g. axe `wrath` -> `demi_hache`).
static func resolve_form_legacy_alias(weapon: Variant, raw_form: String) -> String:
	var s: String = str(raw_form).strip_edges().to_lower()
	if s.is_empty():
		return s
	var wt: String = WeaponTemplateDefinitions._weapon_template_id(weapon)
	if wt.is_empty():
		return s
	var def: Dictionary = get_weapon_definition(wt)
	if def.is_empty():
		return s
	var aliases: Variant = def.get("form_legacy_aliases", {})
	if aliases is Dictionary and (aliases as Dictionary).has(s):
		return str((aliases as Dictionary)[s]).strip_edges().to_lower()
	return s


## Expand WF: default form id for equipped weapon ( **`balanced`** when unarmed).


## Expand WF: default form id for equipped weapon ( **`balanced`** when unarmed).
static func default_form_for_weapon(weapon: Variant) -> String:
	var wt: String = WeaponTemplateDefinitions._weapon_template_id(weapon)
	if wt.is_empty():
		return "balanced"
	var def: Dictionary = get_weapon_definition(wt)
	if def.is_empty():
		return "balanced"
	return str(def.get("default_form", "balanced")).strip_edges().to_lower()


## Expand WF: allowed form ids for weapon template; empty -> no clamp.


## Expand WF: allowed form ids for weapon template; empty -> no clamp.
static func allowed_forms_for_weapon(weapon: Variant) -> Array:
	var wt: String = WeaponTemplateDefinitions._weapon_template_id(weapon)
	if wt.is_empty():
		return ["balanced", "wall"]
	var def: Dictionary = get_weapon_definition(wt)
	if def.is_empty():
		return ["balanced"]
	var raw: Variant = def.get("allowed_forms", [])
	if raw is Array:
		return raw
	return ["balanced"]



# --- Edge geometry helper: maps sharpness (0-1) to wedge penetration factor ---
## Sharp=1 → sharper edge (EDGE_ANGLE_SHARP_DEG) → higher wedge penetration bonus.
## Sharp=0 → duller edge (EDGE_ANGLE_DULL_DEG) → lower wedge penetration bonus.
## Factor = sin(DEFAULT/2) / sin(angle/2), clamped to FLOOR so dull weapons still bite weakly.
static func edge_wedge_penetration_factor(sharpness: float) -> float:
	var eff_angle_deg: float = lerpf(EDGE_ANGLE_SHARP_DEG, EDGE_ANGLE_DULL_DEG, 1.0 - clampf(sharpness, 0.0, 1.0))
	var eff_angle_rad: float = deg_to_rad(eff_angle_deg)
	# Wedge factor: sharper wedge displaces less material per unit depth.
	# sin(default/2)/sin(angle/2): at angle=default → 1.0; at angle=sharp → >1.0 (bonus); at angle=dull → <1.0 (penalty).
	var numer: float = sin(deg_to_rad(EDGE_ANGLE_DEFAULT_DEG) / 2.0)
	var denom: float = sin(eff_angle_rad / 2.0)
	if denom <= 0.0:
		return EDGE_WEDGE_PENETRATION_FLOOR
	var factor: float = numer / denom
	return maxf(factor, EDGE_WEDGE_PENETRATION_FLOOR)


## Kinematic archetype helpers for test scaffolding — avoid inline dict construction across ~100+ call sites.
static func make_kinematic_arch_swing() -> Dictionary:
	return {"kinematic_delivery": KINEMATIC_DELIVERY_SWING}

static func make_kinematic_arch_thrust() -> Dictionary:
	return {"kinematic_delivery": KINEMATIC_DELIVERY_THRUST}

static func make_kinematic_arch_mixed() -> Dictionary:
	return {"kinematic_delivery": KINEMATIC_DELIVERY_MIXED}
