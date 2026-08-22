extends Node

## Bootstrapper for HarnessFixtures — makes it available as a global Autoload in headless mode.
## Godot requires Autoloads to extend Node; HarnessFixtures itself extends RefCounted, so this
## thin wrapper is instantiated by the engine and exposes the real fixture logic via its static API.

func _ready() -> void:
	# No-op — HarnessFixtures methods are all static; nothing to initialize here.
	pass
