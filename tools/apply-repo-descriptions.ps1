#Requires -Version 5.1
<#
.SYNOPSIS
    Review and apply curated GitHub repository About descriptions.
.DESCRIPTION
    Default: preview only. With -Apply: back up all current descriptions before updating.
    Changes ONLY repository descriptions; never changes visibility, topics, code, or README files.
    Requires GitHub CLI (gh) authenticated as the repository owner.
.EXAMPLE
    .\apply-repo-descriptions.ps1
.EXAMPLE
    .\apply-repo-descriptions.ps1 -Apply
#>
[CmdletBinding()]
param(
    [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$manifestPath = Join-Path $PSScriptRoot "repository-about-descriptions.json"
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Missing manifest: $manifestPath" }
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$owner = [string]$manifest.owner
if ($owner -cne "Mounir-Almzayek") { throw "Unexpected owner in manifest." }
$items = @($manifest.repositories)
if ($items.Count -ne 27) { throw "Expected exactly 27 public repositories; found $($items.Count)." }
if (@($items | Select-Object -ExpandProperty name -Unique).Count -ne $items.Count) { throw "Duplicate repositories in manifest." }
$null = Get-Command gh -ErrorAction Stop
$me = (& gh api user --jq .login 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw "GitHub CLI authentication missing: run gh auth login." }
if ($me -ine $owner) { throw "Authenticated GitHub user '$me' is not '$owner'. Aborting." }

$baseline = [System.Collections.Generic.List[object]]::new()
Write-Host "Checking current About descriptions for $($items.Count) repositories..." -ForegroundColor Cyan
foreach ($item in $items) {
    $name = [string]$item.name
    $desired = [string]$item.description
    if ($name -notmatch '^[A-Za-z0-9._-]+$' -or [string]::IsNullOrWhiteSpace($desired) -or $desired.Length -gt 160) {
        throw "Invalid repo name or description length: $name"
    }
    $full = "$owner/$name"
    $raw = (& gh api "repos/$full" --jq '.description // ""' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Cannot read $full; aborting before changes. $raw" }
    $baseline.Add([pscustomobject]@{ repository = $full; before = $raw; proposed = $desired; change = ($raw -cne $desired) })
}
$changed = @($baseline | Where-Object { $_.change })
$baseline | ForEach-Object {
    $mark = if ($_.change) { "CHANGE" } else { "SAME " }
    Write-Host "[$mark] $($_.repository)" -ForegroundColor $(if ($_.change) { "Yellow" } else { "DarkGray" })
    if ($_.change) { Write-Host "        $($_.proposed)" }
}
Write-Host ""
Write-Host "Changes needed: $($changed.Count) / $($items.Count)" -ForegroundColor Cyan
if (-not $Apply) {
    Write-Host "PREVIEW ONLY: nothing was changed. Re-run with -Apply to save a backup and update descriptions." -ForegroundColor Green
    return
}

$backupDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "GitHub-Description-Backups"
$null = New-Item -ItemType Directory -Path $backupDir -Force
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path $backupDir "Mounir-Almzayek-repo-descriptions-$stamp.json"
$baseline | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $backupPath -Encoding UTF8
Write-Host "Backup saved to: $backupPath" -ForegroundColor Green
$failures = [System.Collections.Generic.List[string]]::new()
$success = 0
foreach ($item in $changed) {
    Write-Host "Updating $($item.repository) ..." -ForegroundColor Cyan
    $output = (& gh repo edit $item.repository --description $item.proposed 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        $failures.Add("$($item.repository): $output")
        Write-Warning "Update failed for $($item.repository): $output"
        continue
    }
    $actual = (& gh api "repos/$($item.repository)" --jq '.description // ""' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $actual -cne $item.proposed) {
        $failures.Add("$($item.repository): could not verify the new description")
        Write-Warning "Verification failed for $($item.repository)"
        continue
    }
    $success++
}
Write-Host "Verified changes: $success / $($changed.Count) requested. Unchanged: $($items.Count-$changed.Count)." -ForegroundColor Green
if ($failures.Count -gt 0) {
    Write-Warning "$($failures.Count) updates failed or could not be verified:"
    $failures | ForEach-Object { Write-Warning $_ }
    throw "Partial completion: see warnings. Backup is available at $backupPath"
}
Write-Host "All requested descriptions are verified." -ForegroundColor Green
