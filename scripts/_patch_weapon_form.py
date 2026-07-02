from pathlib import Path

p = Path(r"e:\FallenPaths\fallen-paths\combat\CombatWeaponForm.gd")
lines = p.read_text(encoding="utf-8").splitlines()
start = next(i for i, l in enumerate(lines) if l.startswith("static var _FORM_DEFS"))
end = next(
    i
    for i in range(start, len(lines))
    if lines[i].strip() == "}," and i + 1 < len(lines) and lines[i + 1].strip() == "}"
)
insert = """
const _FormDefs := preload("res://combat/CombatWeaponFormDefs.gd")

const FORM_AXE_DEMI := "demi_hache"
const FORM_AXE_BEC := "bec_point"
const FORM_AXE_QUEUE := "queue_bind"
const FORM_MACE_CROWN := "crown_guard"
const FORM_MACE_FLANK := "flank_guard"
const FORM_DAGGER_HIGH := "high_hut"
const FORM_DAGGER_LOW := "low_bind"
const FORM_DAGGER_REVERSE := "reverse_seize"
const FORM_SPEAR_IRON := "iron_gate"
const FORM_SPEAR_CROSS := "true_cross"
const FORM_SPEAR_PORT := "high_port"

static var _FORM_DEFS_BY_WEAPON: Dictionary = {}


static func _ensure_defs() -> void:
\tif not _FORM_DEFS_BY_WEAPON.is_empty():
\t\treturn
\t_FORM_DEFS_BY_WEAPON = _FormDefs.build_all()


static func _weapon_key(weapon: Variant) -> String:
\tvar wid: String = _WeaponConstants.weapon_type_id(weapon)
\tif wid.is_empty():
\t\treturn "SWORD"
\treturn wid
""".strip("\n").splitlines()
new_lines = lines[:start] + insert + lines[end + 1 :]
p.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print(f"spliced lines {start}-{end}")
