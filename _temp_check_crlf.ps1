$files = @(
    "E:\FallenPaths\fallen-paths\combat\CombatManager.gd",
    "E:\FallenPaths\fallen-paths\core\EntityPainConsciousness.gd",
    "E:\FallenPaths\fallen-paths\harness\d001\D001RunnerHelpers.gd"
)

foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $crlf = 0; $lfOnly = 0
    for ($j = 0; $j -lt $bytes.Length; $j++) {
        if ($bytes[$j] -eq 13) {
            if ($j + 1 -lt $bytes.Length -and $bytes[$j+1] -eq 10) {
                $crlf++
            } else {
                $lfOnly++
            }
        } elseif ($bytes[$j] -eq 10) {
            $lfOnly++
        }
    }
    Write-Output "$($f.Replace('E:\FallenPaths\fallen-paths\', '')): CRLF=$crlf LF-only=$lfOnly"
}
