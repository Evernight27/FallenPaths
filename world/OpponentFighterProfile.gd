class_name OpponentFighterProfile
extends RefCounted

## XCamp-6 (Gladiator school): a single opponent fighter in a rival school's lineup.
##
## Carries the identity (name / weapon / form / stats) and the *hidden* combat tendency
## (the thing scouting reveals), plus a progressive reveal tier. A SchoolDossier is an
## ordered Array[OpponentFighterProfile] — the opponent's lineup order is itself the
## strategic information a player counter-orders against.
##
## Pure data + logic. No scene/manager access; safe to instantiate headlessly.

## Reveal tiers: how much of this fighter a player has observed.
const REVEAL_UNKNOWN: int = 0   # nothing but roster membership (name)
const REVEAL_WEAPON: int = 1    # weapon type + base stats
const REVEAL_FULL: int = 2      # weapon, form/style, and combat tendency

## Tendency keys (consumed by CombatCounter and the combat AI hook).
const TENDENCY_AGGRESSION: String = "aggression"    # 0.0..1.0  high = overcommits / all-in
const TENDENCY_PARRY_BIAS: String = "parry_bias"    # 0.0..1.0  high = defensive / parry-heavy
const TENDENCY_TARGET_PART: String = "target_part"  # part id   preferred target line


var fighter_id: String = ""
var display_name: String = ""
var weapon_id: String = ""
var form_id: String = ""
var stats: Dictionary = {}
var tendency: Dictionary = {}
var reveal: int = REVEAL_UNKNOWN


## Build a profile at REVEAL_UNKNOWN; the tendency is hidden until scouting reveals it.
static func make(
	p_fighter_id: String,
	p_display_name: String,
	p_weapon_id: String,
	p_form_id: String,
	p_stats: Dictionary = {},
	p_tendency: Dictionary = {}
) -> OpponentFighterProfile:
	var p := OpponentFighterProfile.new()
	p.fighter_id = p_fighter_id
	p.display_name = p_display_name
	p.weapon_id = p_weapon_id
	p.form_id = p_form_id
	p.stats = p_stats.duplicate(true)
	p.tendency = p_tendency.duplicate(true)
	p.reveal = OpponentFighterProfile.REVEAL_UNKNOWN
	return p


## Advance reveal one tier (capped at FULL). Returns the new tier.
func advance_reveal() -> int:
	reveal = mini(reveal + 1, OpponentFighterProfile.REVEAL_FULL)
	return reveal


## Set reveal directly (e.g. from a persisted dossier). Clamped to the valid range.
func set_reveal(tier: int) -> void:
	reveal = clampi(int(tier), 0, OpponentFighterProfile.REVEAL_FULL)


func has_weapon_reveal() -> bool:
	return reveal >= OpponentFighterProfile.REVEAL_WEAPON


func has_full_reveal() -> bool:
	return reveal >= OpponentFighterProfile.REVEAL_FULL


## True when the given tendency key is currently visible to the player.
func tendency_visible(key: String) -> bool:
	return has_full_reveal() and tendency.has(key)


## The tendency value the player may currently see ("" when hidden).
func visible_tendency(key: String) -> String:
	if not tendency_visible(key):
		return ""
	return str(tendency.get(key, ""))


func to_dict() -> Dictionary:
	return {
		"fighter_id": fighter_id,
		"display_name": display_name,
		"weapon_id": weapon_id,
		"form_id": form_id,
		"stats": stats.duplicate(true),
		"tendency": tendency.duplicate(true),
		"reveal": reveal,
	}


static func from_dict(d: Dictionary) -> OpponentFighterProfile:
	var p := OpponentFighterProfile.new()
	p.fighter_id = str(d.get("fighter_id", ""))
	p.display_name = str(d.get("display_name", ""))
	p.weapon_id = str(d.get("weapon_id", ""))
	p.form_id = str(d.get("form_id", ""))
	p.stats = (d.get("stats", {}) as Dictionary).duplicate(true)
	p.tendency = (d.get("tendency", {}) as Dictionary).duplicate(true)
	p.set_reveal(int(d.get("reveal", OpponentFighterProfile.REVEAL_UNKNOWN)))
	return p


## A SchoolDossier is an ordered Array of profiles (lineup order = strategic info).
## `profiles` must already be an ordered Array[OpponentFighterProfile].
static func make_dossier(profiles: Array) -> Array:
	var out: Array = []
	for p in profiles:
		if p is OpponentFighterProfile:
			out.append(p)
	return out


## Score how much of the roster is revealed (0.0..1.0) — drives "scouted enough?" UI gating.
static func dossier_reveal_ratio(profiles: Array) -> float:
	if profiles.is_empty():
		return 0.0
	var known: int = 0
	for p in profiles:
		if p is OpponentFighterProfile and p.has_full_reveal():
			known += 1
	return float(known) / float(profiles.size())
