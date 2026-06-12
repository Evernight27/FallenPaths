$files = @(
    "E:\FallenPaths\fallen-paths\core/BleedingConstants.gd",
    "E:\FallenPaths\fallen-paths\combat/CombatConstants.gd"
)
foreach ($f in $files) {
    (Get-Item $f).LastWriteTime = Get-Date
}
