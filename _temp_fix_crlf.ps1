$files = @(
    "E:\FallenPaths\fallen-paths\combat\CombatManager.gd",
    "E:\FallenPaths\fallen-paths\core\EntityPainConsciousness.gd",
    "E:\FallenPaths\fallen-paths\harness\d001\D001RunnerHelpers.gd"
)

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f)
    $content = $content.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($f, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Output "Fixed: $($f.Replace('E:\FallenPaths\fallen-paths\', ''))"
}
