class_name CombatAfterblowConstants
extends RefCounted

## Afterblow constants: physically realistic — allow completion iff blow wasn't intense enough to hinder.
## Extracted from CombatConstants for modular organization.

## Afterblow: physically realistic — allow completion iff blow wasn't intense enough to hinder.
const AFTERBLOW_DAMAGE_HINDER_THRESHOLD: float = 15.0
const AFTERBLOW_HINDRANCE_BLOCK: float = 0.7
const AFTERBLOW_HINDRANCE_ALLOW: float = 0.3
const AFTERBLOW_CANCELLED_RECOVERY_S: float = 0.5
