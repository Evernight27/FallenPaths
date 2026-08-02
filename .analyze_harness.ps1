$lines = Get-Content 'E:\FallenPaths\fallen-paths\.harness_out.txt'
$counts = @{}
foreach ($l in $lines) {
    if ($l -match '- CombatRegressionHarness:.*targetable parts empty') { $k='TARGETABLE_EMPTY' }
    elseif ($l -match '- CombatRegressionHarness:.*no attacks recorded|no hits in 3 attacks') { $k='NO_ATTACKS' }
    elseif ($l -match '- CombatRegressionHarness:.*-999|-1\.0000') { $k='PEN_INVALID' }
    elseif ($l -match '- CombatRegressionHarness:.*ke.*too small|full ke too small') { $k='KE_SMALL' }
    elseif ($l -match '- CombatD001SoakRunner:') { $k='SOAK_RUNNER' }
    elseif ($l -match '- CombatCalibrationAudit:') { $k='CALIBRATION' }
    elseif ($l -match '- CombatRegressionHarness:.*setup failed') { $k='SETUP_FAILED' }
    elseif ($l -match '- CombatRegressionHarness:.*missing ') { $k='MISSING_FIXTURE' }
    else {
        if ($l -match '- CombatRegressionHarness:') { $k='REGRESSION_OTHER' }
    }
    if ($k) {
        if ($counts.ContainsKey($k)) { $counts[$k]++ } else { $counts[$k]=1 }
    }
}
foreach ($pair in ($counts.GetEnumerator() | Sort-Object Value -Descending)) {
    Write-Output "$($pair.Name): $($pair.Value)"
}
