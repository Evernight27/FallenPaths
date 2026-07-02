class_name CombatFootwork
extends RefCounted

## Tier 4.4 pilot: abstract step-on-attack shifts **`attack_angle_deg`** via per-combatant offset (no world positions).
## Tier 4.4.2: symmetric defender step on committed parry (guard line) or dodge (eval part line).
## Lifecycle: **`clear_on_exchange_end`** when **`pending_attack`** drops or exchange aborts; UI via **`offset_visible_for_ui_state`** (**`wind_up`** / **`recovering`** only).
## Attachment: reads **line keys** only  -  not **`weapon_form`** or stance alias. Hub LIVE_PATHS **`#wf-tier-44-pa`** (stamp / geometry / clear / lookup). Form home via **`assign_form`**; matrix **`#wf-form-guard-pa-matrix`**.
## Canonical: apply_attack_step_on_windup . apply_defender_step_on_parry . apply_defender_step_on_dodge . attack_eval_step_deg_for_attacker . attack_angle_deg_for_listing_preview . parry_eval_step_deg_for_defender . dodge_eval_step_deg_for_defender . guard_angle_deg . apply_offset_to_angle_deg . clear_on_exchange_end . clear_on_death . reconcile_idle_offset . return_to_waiting . return_to_cowering . CombatUiHints.footwork_hint_text.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")


static func enabled() -> bool:
	return CombatConstants.is_feature_position_angle_footwork_enabled()


## Footing UI / diagram suffix only while an exchange step is active (not idle reserve).
static func offset_visible_for_ui_state(c: Dictionary) -> bool:
	if c == null or c.is_empty():
		return false
	var st: String = _EntityAccess.state_str(c)
	return (
		st == CombatConstants.STATE_WIND_UP
		or st == CombatConstants.STATE_RECOVERING
	)


## Attacker PA stamp from **line id** (not form). Scrubs leaked idle keys before fresh stamp. Production callers: LIVE_PATHS **`#wf-pa-stamp-callers`**. Empty line clears offset. Optional **`opponent_id`** / **`manager`** for Tier 4.4 spatial band + flurry magnitude when flags on.
static func apply_attack_step_on_windup(
	attacker: Dictionary,
	attack_line: String,
	opponent_id: int = -1,
	manager: Node = null
) -> void:
	if not enabled() or attacker == null:
		return
	reconcile_idle_offset(attacker)
	var line: String = attack_line.strip_edges()
	if line.is_empty():
		clear_position_offset(attacker)
		return
	var off: float = attack_eval_step_deg_for_attacker(attacker, line, opponent_id, manager)
	attacker[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = off
	refresh_ui_hint(attacker)


## Defender parry PA stamp from live **`guard_line`**. Scrubs leaked idle keys before fresh stamp. **`#wf-pa-stamp-callers`**. Optional **`attacker_id`** / **`manager`** for Tier 4.4 spatial band + flurry magnitude when flags on.
static func apply_defender_step_on_parry(
	defender: Dictionary, guard_line: String, attacker_id: int = -1, manager: Node = null
) -> void:
	if not enabled() or defender == null:
		return
	reconcile_idle_offset(defender)
	var line: String = guard_line.strip_edges()
	if line.is_empty():
		line = CombatConstants.GUARD_DEFAULT
	var off: float = parry_eval_step_deg_for_defender(defender, attacker_id, manager, line)
	defender[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = off
	refresh_ui_hint(defender)


## Defender dodge PA stamp from body-part -> line. Scrubs leaked idle keys before fresh stamp. **`#wf-pa-stamp-callers`**. Optional **`attacker_id`** for band magnitude; optional **`manager`** for wing-file dodge bias when flag on.
static func apply_defender_step_on_dodge(
	defender: Dictionary,
	dodge_eval_part: String,
	attacker_id: int = -1,
	manager: Node = null
) -> void:
	if not enabled() or defender == null:
		return
	reconcile_idle_offset(defender)
	var off: float = dodge_eval_step_deg_for_defender(
		defender, dodge_eval_part, attacker_id, manager
	)
	defender[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = off
	refresh_ui_hint(defender)


static func format_position_angle_ui_hint(c: Dictionary) -> String:
	if not enabled() or c == null:
		return ""
	var off: float = c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	if absf(off) < 0.01:
		return ""
	return "Step"


## Prefer **`CombatUiHints.footwork_hint_text`** for UI/snapshot. Alias of **`get_ui_hint`**.
static func snapshot_ui_hint(c: Dictionary) -> String:
	return get_ui_hint(c)


## Player-visible label: always derived from live offset (ignores stale stamped keys).
static func get_ui_hint(c: Dictionary) -> String:
	if not enabled() or c == null or not offset_visible_for_ui_state(c):
		return ""
	return format_position_angle_ui_hint(c)


## Drop leaked PA keys when idle (**`waiting`** / **`cowering`** / medical)  -  UI already hides; keeps dict + snapshot clean.
static func reconcile_idle_offset(c: Dictionary) -> void:
	if c == null or offset_visible_for_ui_state(c):
		return
	if (
		c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
		or c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
	):
		clear_position_offset(c)


## Set idle reserve and scrub leaked PA keys (same-frame snapshot guard after resolve/abort).
static func return_to_waiting(c: Dictionary) -> void:
	if c == null or c.is_empty():
		return
	c.state = CombatConstants.STATE_WAITING
	reconcile_idle_offset(c)


## Set cowering reserve and scrub leaked PA keys (mobility / no-arm idle  -  no Step UI).
static func return_to_cowering(c: Dictionary) -> void:
	if c == null or c.is_empty():
		return
	c.state = CombatConstants.STATE_COWERING
	reconcile_idle_offset(c)


## Formation diagram cells: no suffix (offset degrees are combat-only, not shown in UI).
static func get_diagram_label_suffix(_c: Dictionary) -> String:
	return ""


static func refresh_ui_hint(c: Dictionary) -> void:
	if c == null:
		return
	var hint: String = format_position_angle_ui_hint(c)
	if hint.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = hint


static func get_attacker_offset_deg(attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return 0.0
	return attacker.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)


static func get_defender_offset_deg(defender: Dictionary) -> float:
	return get_attacker_offset_deg(defender)


## Attacker contact angle += stamped offset (read only). **`#wf-pa-geometry-callers`**.
static func apply_offset_to_angle_deg(base_deg: float, attacker: Dictionary) -> float:
	if not enabled() or attacker == null:
		return base_deg
	return fmod(base_deg + get_attacker_offset_deg(attacker) + 360.0, 360.0)


static func apply_defender_offset_to_guard_deg(base_guard_deg: float, defender: Dictionary) -> float:
	if not enabled() or defender == null:
		return base_guard_deg
	return fmod(base_guard_deg + get_defender_offset_deg(defender) + 360.0, 360.0)


## Defender contact guard angle: **`get_guard_angle_deg(guard_line)`** '+/- PA offset. **`#wf-pa-geometry-callers`**.
static func guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
	var base: float = CombatConstants.get_guard_angle_deg(combatant, wobble_context)
	return apply_defender_offset_to_guard_deg(base, combatant)


## Parry alignment during **`choose_defense`** without stamping offset until defense commits.
static func guard_angle_deg_with_step_deg(
	combatant: Dictionary, wobble_context: Dictionary, step_deg: float
) -> float:
	var base: float = CombatConstants.get_guard_angle_deg(combatant, wobble_context)
	if not enabled() or absf(step_deg) < 0.01:
		return base
	return fmod(base + step_deg + 360.0, 360.0)


## Attacker alignment preview during wind-up / listing without stamping offset until wind-up commits.
static func attack_eval_step_deg_for_attacker(
	attacker: Dictionary,
	attack_line: String,
	opponent_id: int = -1,
	manager: Node = null
) -> float:
	if not enabled() or attacker == null:
		return 0.0
	var line: String = attack_line.strip_edges()
	if line.is_empty():
		return 0.0
	var base_off: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
	return base_off * _t44_attacker_spatial_mult(attacker, opponent_id, manager)


## Turn-listing attack angle: live stamp when wind-up/recovering; else **`attack_eval_step_deg_for_attacker`** preview. **`#wf-pick-vs-strike`** . **`CombatAIActionPicker`**.
static func attack_angle_deg_for_listing_preview(
	attacker: Dictionary,
	attack_line: String,
	base_angle_deg: float,
	opponent_id: int = -1,
	manager: Node = null
) -> float:
	if not enabled() or attacker == null:
		return base_angle_deg
	if offset_visible_for_ui_state(attacker):
		return apply_offset_to_angle_deg(base_angle_deg, attacker)
	var step: float = attack_eval_step_deg_for_attacker(attacker, attack_line, opponent_id, manager)
	if absf(step) < 0.01:
		return base_angle_deg
	return fmod(base_angle_deg + step + 360.0, 360.0)


static func parry_eval_step_deg_for_defender(
	defender: Dictionary,
	attacker_id: int = -1,
	manager: Node = null,
	guard_line: String = ""
) -> float:
	if not enabled() or defender == null:
		return 0.0
	var line: String = guard_line.strip_edges()
	if line.is_empty():
		line = str(defender.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()
	if line.is_empty():
		line = CombatConstants.GUARD_DEFAULT
	var base_off: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	return base_off * _t44_defender_parry_spatial_mult(defender, attacker_id, manager)


## Dodge alignment preview during **`choose_defense`** without stamping offset until dodge commits.
static func dodge_eval_step_deg_for_defender(
	defender: Dictionary,
	dodge_eval_part: String,
	attacker_id: int = -1,
	manager: Node = null
) -> float:
	if not enabled() or defender == null:
		return 0.0
	var part: String = dodge_eval_part.strip_edges()
	if part.is_empty():
		return 0.0
	var line: String = CombatConstants.guard_line_for_body_part(part)
	var base_off: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	return base_off * _t44_defender_dodge_spatial_mult(defender, attacker_id, manager)


## Clears step offset + UI hint. Call when **`pending_attack`** is dropped or an exchange ends without **`AttackResolver`** resolve (abort, skip, recovery, medical halt). All production callers: LIVE_PATHS **`#wf-pa-clear-callers`**.
static func clear_on_exchange_end(c: Dictionary) -> void:
	clear_position_offset(c)


## Fatal wound / bleed-out  -  alias of **`clear_on_exchange_end`** (grep **`#wf-pa-clear-callers`** death rows).
static func clear_on_death(c: Dictionary) -> void:
	clear_on_exchange_end(c)


static func clear_position_offset(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG)
	refresh_ui_hint(c)


static func _t44_attacker_spatial_mult(attacker: Dictionary, opponent_id: int, manager: Node) -> float:
	return (
		_t44_band_pa_magnitude_mult_for_attacker(attacker, opponent_id)
		* _t44_flurry_pa_mult(attacker, opponent_id, manager)
	)


static func _t44_defender_parry_spatial_mult(
	defender: Dictionary, attacker_id: int, manager: Node
) -> float:
	return (
		_t44_band_pa_magnitude_mult_for_defender(defender, attacker_id)
		* _t44_flurry_pa_mult(defender, attacker_id, manager)
	)


static func _t44_defender_dodge_spatial_mult(
	defender: Dictionary, attacker_id: int, manager: Node
) -> float:
	return (
		_t44_band_pa_magnitude_mult_for_defender(defender, attacker_id)
		* _t44_file_dodge_wing_mult(defender, manager)
		* _t44_flurry_pa_mult(defender, attacker_id, manager)
	)


static func _t44_band_pa_magnitude_mult_for_attacker(attacker: Dictionary, opponent_id: int) -> float:
	if not CombatConstants.is_feature_t44_spatial_band_pa_enabled():
		return 1.0
	var band: String = _EntityAccess.distance_to_opponent_band(
		attacker, opponent_id, CombatConstants.DISTANCE_MID
	)
	return CombatConstants.t44_spatial_band_pa_magnitude_mult(band)


static func _t44_file_dodge_wing_mult(defender: Dictionary, manager: Node) -> float:
	if manager == null or defender.is_empty():
		return 1.0
	var fid: String = _EntityAccess.formation_id_str(defender)
	if fid.is_empty():
		return 1.0
	var formation: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if formation.is_empty():
		return 1.0
	var files: int = maxi(1, int(formation.get("files", 1)))
	return CombatConstants.t44_spatial_file_dodge_wing_mult(_EntityAccess.file_int(defender), files)


static func _t44_band_pa_magnitude_mult_for_defender(defender: Dictionary, attacker_id: int) -> float:
	if not CombatConstants.is_feature_t44_spatial_band_pa_enabled():
		return 1.0
	var band: String = CombatConstants.defender_distance_band_to_attacker_id(defender, attacker_id)
	return CombatConstants.t44_spatial_band_pa_magnitude_mult(band)


static func _t44_flurry_pa_mult(c: Dictionary, opponent_id: int, manager: Node) -> float:
	if not CombatConstants.is_feature_t44_spatial_flurry_pa_enabled():
		return 1.0
	if manager == null or opponent_id < 0 or c.is_empty():
		return 1.0
	var clk: float = _EntityAccess.combat_clock_float(manager)
	if not _FlurryBind.is_active_vs(c, opponent_id, clk):
		return 1.0
	return CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
