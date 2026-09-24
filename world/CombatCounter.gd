class_name CombatCounter
extends RefCounted

## XCamp-6 (Gladiator school): pure counter-recommendation for a scouted opponent.
##
## Given an OpponentFighterProfile, returns the weapon / fighting form / stat a player
## should prep to beat that fighter. Deterministic + testable: no scene or RNG access.
## The recommendation is a *suggestion* — the prep UI surfaces it and the player decides.

## Opponent tendencies (from OpponentFighterProfile).
const TENDENCY_AGGRESSION: String = OpponentFighterProfile.TENDENCY_AGGRESSION
const TENDENCY_PARRY_BIAS: String = OpponentFighterProfile.TENDENCY_PARRY_BIAS
const TENDENCY_TARGET_PART: String = OpponentFighterProfile.TENDENCY_TARGET_PART

# Counter pressure classes (mirror CombatWeaponForm pressure_class values).
const PRESSURE_AGGRESSIVE: String = "aggressive"
const PRESSURE_DEFENSIVE: String = "defensive"
const PRESSURE_CONTROLLING: String = "controlling"


## Map a scouted profile to a prep recommendation.
## Returns a Dictionary with:
##   counter_pressure  - the pressure class to fight in ("aggressive" | "defensive" | "controlling")
##   counter_form      - a concrete form id that carries that pressure (example to drill toward)
##   weapon_type       - a weapon type to equip (SWORD/AXE/MACE/DAGGER/SPEAR)
##   stat_to_drill     - the stat to drill (PROFICIENCY_STATS member)
##   notes             - human-readable reasons (PackedStringArray)
##
## Logic:
##   parry-heavy opponent  -> overwhelm with aggressive pressure + reach (SPEAR), drill agility.
##   aggressive opponent   -> bait and punish with defensive pressure + heavy (MACE), drill endurance.
##   balanced / tied       -> control the tempo with SWORD, drill perception to read the line.
static func recommendations(profile: OpponentFighterProfile) -> Dictionary:
	if profile == null:
		return {}
	var notes: PackedStringArray = PackedStringArray()

	var aggression: float = clampf(float(profile.tendency.get(TENDENCY_AGGRESSION, 0.5)), 0.0, 1.0)
	var parry: float = clampf(float(profile.tendency.get(TENDENCY_PARRY_BIAS, 0.5)), 0.0, 1.0)

	var counter_pressure: String
	var counter_form: String
	var weapon_type: String
	var stat_to_drill: String

	if parry > aggression:
		counter_pressure = PRESSURE_AGGRESSIVE
		counter_form = "ox"
		weapon_type = "SPEAR"
		stat_to_drill = "agility"
		notes.append("Parry-heavy: keep them at range and overwhelm with committed pressure.")
	elif aggression > parry:
		counter_pressure = PRESSURE_DEFENSIVE
		counter_form = "plow"
		weapon_type = "MACE"
		stat_to_drill = "endurance"
		notes.append("Aggressive: hold the line and punish the overcommit.")
	else:
		counter_pressure = PRESSURE_CONTROLLING
		counter_form = "balanced"
		weapon_type = "SWORD"
		stat_to_drill = "perception"
		notes.append("Balanced: control the tempo and read the line.")

	var target_part: String = str(profile.tendency.get(TENDENCY_TARGET_PART, "")).strip_edges()
	if not target_part.is_empty():
		notes.append("Favors the %s line - guard it." % target_part)

	return {
		"counter_pressure": counter_pressure,
		"counter_form": counter_form,
		"weapon_type": weapon_type,
		"stat_to_drill": stat_to_drill,
		"notes": notes,
	}


## Whether a profile has enough intel to drive a meaningful recommendation
## (weapon known at minimum; full reveal for the tendency-based branch).
static func is_scouted_enough(profile: OpponentFighterProfile) -> bool:
	if profile == null:
		return false
	return profile.has_weapon_reveal()
