class_name CombatFileKeyedDict
extends RefCounted

## Read dict entries keyed by formation file index as int or string (e.g. JSON round-trip).


static func get_value(d: Dictionary, file_index: int, default_value: Variant = null) -> Variant:
	if d.has(file_index):
		return d[file_index]
	return d.get(str(file_index), default_value)
