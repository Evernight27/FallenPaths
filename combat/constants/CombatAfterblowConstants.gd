class_name CombatAfterblowConstants
extends RefCounted

## Afterblow constants: physically realistic  -  allow completion iff blow wasn't intense enough to hinder.
## Extracted from CombatConstants for modular organization.

## Afterblow: physically realistic  -  allow completion iff blow wasn't intense enough to hinder.
const AFTERBLOW_DAMAGE_HINDER_THRESHOLD: float = 15.0
const AFTERBLOW_HINDRANCE_BLOCK: float = 0.7
const AFTERBLOW_HINDRANCE_ALLOW: float = 0.3
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5
## Severity cap for the hindrance model: damage above AFTERBLOW_DAMAGE_HINDER_THRESHOLD scales up to this
## multiplier before clamping into the 0-1 hindrance range. A 1.5× cap means even a heavy blow only adds
## half a unit of hindrance on its own — part-relevance and intensity must also contribute to block.
const AFTERBLOW_SEVERITY_MAX: float = 1.5
## Outcome discount for glancing/negligible afterblows: a struck-aside blow still hinders the follow-up but
## far less than a clean hit. 0.6 keeps the hindrance meaningful without treating a glancing graze as a
## full-stop event.
const AFTERBLOW_GLANCING_OUTCOME_MULT: float = 0.6
## Floor for the afterblow damage multiplier: even at maximum hindrance the follow-up blow retains 20% of
## its full damage. A fully hindered afterblow is still a committed swing, not a wind-up with no effect.
const AFTERBLOW_DAMAGE_MULT_FLOOR: float = 0.2

# Part relevance weights for afterblow hindrance calculation
const AFTERBLOW_RELEVANCE_ARM_ATTACKING: float = 1.0
const AFTERBLOW_RELEVANCE_HEAD: float = 1.0
const AFTERBLOW_RELEVANCE_TORSO: float = 0.6
const AFTERBLOW_RELEVANCE_SUPPORTING_LEG: float = 0.9
const AFTERBLOW_RELEVANCE_LEG: float = 0.5
const AFTERBLOW_RELEVANCE_ARM: float = 0.4
const AFTERBLOW_RELEVANCE_DEFAULT: float = 0.2
