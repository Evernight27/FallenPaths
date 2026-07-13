class_name CombatAfterblowConstants
extends RefCounted

## Afterblow constants: physically realistic  -  allow completion iff blow wasn't intense enough to hinder.
## Extracted from CombatConstants for modular organization.

## Afterblow: physically realistic  -  allow completion iff blow wasn't intense enough to hinder.
const AFTERBLOW_DAMAGE_HINDER_THRESHOLD: float = 15.0
const AFTERBLOW_HINDRANCE_BLOCK: float = 0.7
const AFTERBLOW_HINDRANCE_ALLOW: float = 0.3
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5

# Part relevance weights for afterblow hindrance calculation
const AFTERBLOW_RELEVANCE_ARM_ATTACKING: float = 1.0
const AFTERBLOW_RELEVANCE_HEAD: float = 1.0
const AFTERBLOW_RELEVANCE_TORSO: float = 0.7
const AFTERBLOW_RELEVANCE_SUPPORTING_LEG: float = 0.9
const AFTERBLOW_RELEVANCE_LEG: float = 0.5
const AFTERBLOW_RELEVANCE_ARM: float = 0.4
const AFTERBLOW_RELEVANCE_DEFAULT: float = 0.2
