param([string[]]$Paths)

$ok = $true

foreach ($p in $Paths) {

	$errors = $null

	$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $p -Raw), [ref]$errors)

	if ($errors.Count -gt 0) {

		Write-Host "SYNTAX ERROR in $($p):"

		foreach ($e in $errors) { Write-Host "  $e" }

		$ok = $false

	} else {

		Write-Host "SYNTAX OK: $($p)"

	}

}

if ($ok) { exit 0 } else { exit 1 }

