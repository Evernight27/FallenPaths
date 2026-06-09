$files = @('CombatRegressionHarness.gd','CombatRegressionHarnessSimulation.gd','CombatRegressionHarnessFpDedupeTail.gd','CombatRegressionHarnessMedicalPhaseTail.gd','CombatRegressionHarnessWeaponFormTail.gd','CombatRegressionHarnessTier1Tail.gd','CombatRegressionHarnessFeintTempoTail.gd','CombatRegressionHarnessFleeTail.gd','CombatRegressionHarnessKinematicTail.gd','CombatRegressionHarnessAttentionFootworkTail.gd','CombatRegressionHarnessMedicalMobilityTail.gd')
foreach ($f in $files) {
    $path = 'e:\FallenPaths\fallen-paths\combat\' + $f
    $lines = [System.IO.File]::ReadAllLines($path).Count
    Write-Host ($f + ' : ' + $lines.ToString() + ' lines')
}
