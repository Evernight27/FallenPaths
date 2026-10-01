class_name FeintTempoDefenseFootworkTestBase

extends CombatRegressionHarnessCore

## Shared fixtures for the feint/defense-footwork test modules. Holds the CombatRegressionHarness preload
## const shared across the split modules. Split out of FeintDefenseFootworkTests to keep each test module
## under the file-size budget.

const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
