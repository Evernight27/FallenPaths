# Camp ship audit: headless proxies for SHIP_PLAN section 8 + Camp-3.4 / Camp-5 gates.
# Does not replace F5 campaign playtest (dev_soak_encounter empty).
#   .\scripts\run_campaign_ship_audit.ps1           # full (company + Q + ii7 + PHASE0)
#   .\scripts\run_campaign_ship_audit.ps1 -TailOnly # Q + ii7 only (after run_all_combat_checks)
param(
	[switch]$TailOnly
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
$fail = 0
$auditLines = New-Object System.Collections.Generic.List[string]

Write-Host "=== Campaign ship audit (headless) ==="
Write-Host ""

if (-not $TailOnly) {
	Write-Host "=== CompanyStateChecks (SHIP_PLAN section 8 steps 1-10 proxies) ==="
	& (Join-Path $Root "scripts\run_company_state_checks.ps1")
	if ($LASTEXITCODE -ne 0) { $fail = 1; $auditLines.Add("COMPANY_STATE: FAIL") } else { $auditLines.Add("COMPANY_STATE: PASS") }
	Write-Host ""
} else {
	$auditLines.Add("COMPANY_STATE: SKIP (Phase 0 already ran)")
}

Write-Host "=== Q track audits (Camp-3.4 ii7 + Q1/Q2 proxies) ==="
& (Join-Path $Root "scripts\run_q_audit.ps1") -Track Track
if ($LASTEXITCODE -ne 0) {
	$fail = 1
	$auditLines.Add("Q_TRACK: FAIL")
} else {
	$auditLines.Add("Q_TRACK: PASS")
}
Write-Host ""

$soak = Join-Path $Root ".d001_soak_out.txt"
$ii7 = $false
$iiEnvelop = $false
if (Test-Path $soak) {
	$soakText = Get-Content -Path $soak -Raw -Encoding utf8
	$ii7 = $soakText -match '\[ii7\] pass=true'
	$iiEnvelop = $soakText -match '\[ii_envelop\] pass=true'
}
if (-not $ii7) {
	Write-Host 'FAIL: [ii7] pass=true missing in .d001_soak_out.txt - run .\scripts\run_all_combat_checks.ps1'
	$fail = 1
	$auditLines.Add("II7_MEDICAL: FAIL")
} else {
	Write-Host "PASS: [ii7] medical smoke (headless)"
	$auditLines.Add("II7_MEDICAL: PASS")
}
if (-not $iiEnvelop) {
	Write-Host 'FAIL: [ii_envelop] pass=true missing in .d001_soak_out.txt - run .\scripts\run_all_combat_checks.ps1'
	$fail = 1
	$auditLines.Add("II_ENVELOP: FAIL")
} else {
	Write-Host "PASS: [ii_envelop] 7v3 wing engagement smoke (headless)"
	$auditLines.Add("II_ENVELOP: PASS")
}

if (-not $TailOnly) {
	$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
	if (-not (Test-Path $phase0)) {
		Write-Host 'WARN: .phase0_combat_checks.txt missing - run .\scripts\run_all_combat_checks.ps1 for full PHASE0'
	} elseif (-not (Select-String -Path $phase0 -Pattern '^PHASE0: PASS' -Quiet)) {
		Write-Host "WARN: PHASE0 not PASS in .phase0_combat_checks.txt"
		$fail = 1
		$auditLines.Add("PHASE0: FAIL")
	} else {
		Write-Host "PASS: PHASE0 summary on disk"
		$auditLines.Add("PHASE0: PASS")
	}
} else {
	$auditLines.Add("PHASE0: SKIP (caller verified)")
}

Write-Host ""
Write-Host "=== Still manual (Camp-3.4 / Camp-5 sign-off) ==="
Write-Host '  F5 main.tscn: dev_soak_encounter empty - tutorial + 1 paid contract (SHIP_PLAN section 8)'
Write-Host '  Optional III-4 F5: dev_soak_encounter=ii_envelop -> validate_f5_soak_log.ps1 (wing rotate/close/hold_line)'
Write-Host '  Optional feel: .\scripts\run_q_feel.ps1 -Track Camp | Q1 | Q2'
Write-Host "  Medical phase Stack labels: spot-check once in F5 after a fight with medical phase"
Write-Host ""

$auditPath = Join-Path $Root ".campaign_ship_audit.txt"
if ($fail -ne 0) {
	$auditLines.Add("CAMPAIGN_SHIP_AUDIT: FAIL")
	$auditLines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
	$auditLines | Set-Content -Path $auditPath -Encoding utf8
	Write-Host "=== CAMPAIGN_SHIP_AUDIT: FAIL ==="
	exit 1
}
$auditLines.Add("CAMPAIGN_SHIP_AUDIT: PASS (headless)")
$auditLines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$auditLines | Set-Content -Path $auditPath -Encoding utf8
Write-Host "=== CAMPAIGN_SHIP_AUDIT: PASS (headless) ==="
exit 0
