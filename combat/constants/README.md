# constants/

Literal modules and helpers. Public API is the facade `combat/CombatConstants.gd` (`CombatConstants.X`).

Godot does not resolve inherited `const` cleanly — keep re-exports on the facade; put new literals in a package module then re-export.
