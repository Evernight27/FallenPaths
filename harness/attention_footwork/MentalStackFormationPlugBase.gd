class_name MentalStackFormationPlugBase

extends CombatRegressionHarnessCore

## Shared preloads for the attention / mental-stack / footwork test modules.
## Holds the CombatRegressionHarness, CombatFormationRout and CombatWeaponForm
## consts referenced across the split test classes.

const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

const FormationRout := preload("res://combat/formation/CombatFormationRout.gd")

const CombatWeaponFormConst := preload("res://combat/weapon_form/CombatWeaponForm.gd")
