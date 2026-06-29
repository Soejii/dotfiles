<#
  00-backup-prewipe.ps1  --  Pre-wipe safety net for the Arch migration.

  Runs on THIS Windows box. By default it is a DRY RUN: it only reports what
  would be saved, how big it is, and which git repos still have unpushed/dirty
  work. Nothing is copied until you pass -Execute with a -Dest on an EXTERNAL
  drive (both internal NVMes get wiped, so the destination must NOT be C/D/F/Z).

  Usage:
    .\00-backup-prewipe.ps1                         # dry run, safe, just reports
    .\00-backup-prewipe.ps1 -Execute -Dest E:\arch-backup

  What it grabs (the irreplaceable stuff the audit found):
    - C:\CODE\KEYSTORE          (Android .jks signing keys + GCP service acct json)
    - no-git project folders    (automation, absen, ggst-*, nakula-cli, sadewa-cli, BUILDS)
    - every .env under C:\CODE   (credentials)
    - ~/.claude, ~/.config/opencode, ~/.ssh, ~/.gitconfig  (toolchain identity)
    - Chrome bookmarks          (passwords are DPAPI-bound: use Chrome Sync / manual export)
    - a git report of every dirty / unpushed repo so nothing is left behind
#>

[CmdletBinding()]
param(
    [string]$Dest,
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
$code = 'C:\CODE'
$me   = $env:USERPROFILE

# --- folders with NO git history -> total loss on wipe ---
$noGit = @(
    "$code\KEYSTORE",          # CRITICAL: app signing keys, unrecoverable
    "$code\automation",        # Playwright bot + .env + assets
    "$code\absen",
    "$code\ggst-input-tracker",
    "$code\ggst-pocket-finder",
    "$code\nakula-cli",
    "$code\sadewa-cli",
    "$code\BUILDS"
) | Where-Object { Test-Path $_ }

# --- user identity / config trees ---
$userTrees = @(
    "$me\.claude",
    "$me\.config\opencode",
    "$me\.ssh"
) | Where-Object { Test-Path $_ }

$singleFiles = @(
    "$me\.gitconfig",
    "$me\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
) | Where-Object { Test-Path $_ }

function Get-SizeMB($path) {
    try {
        $b = (Get-ChildItem $path -Recurse -File -Force -ErrorAction SilentlyContinue |
              Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.git\\|\\target\\|\\build\\|\\\.dart_tool\\' } |
              Measure-Object Length -Sum).Sum
        [math]::Round(($b / 1MB), 1)
    } catch { 0 }
}

Write-Host "`n===== IRREPLACEABLE FOLDERS (no git) =====" -ForegroundColor Cyan
foreach ($f in $noGit) { "{0,9} MB  {1}" -f (Get-SizeMB $f), $f }

Write-Host "`n===== USER CONFIG TREES =====" -ForegroundColor Cyan
foreach ($f in $userTrees) { "{0,9} MB  {1}" -f (Get-SizeMB $f), $f }

Write-Host "`n===== .env FILES UNDER C:\CODE =====" -ForegroundColor Cyan
$envFiles = Get-ChildItem $code -Recurse -Force -Filter '.env' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\node_modules\\' }
$envFiles | ForEach-Object { $_.FullName }

Write-Host "`n===== GIT REPOS WITH UNSAVED WORK (push before wipe!) =====" -ForegroundColor Yellow
Get-ChildItem $code -Directory | ForEach-Object {
    if (Test-Path "$($_.FullName)\.git") {
        Push-Location $_.FullName
        $dirty    = (git status --porcelain 2>$null | Measure-Object).Count
        $unpushed = (git log --branches --not --remotes --oneline 2>$null | Measure-Object).Count
        Pop-Location
        if ($dirty -gt 0 -or $unpushed -gt 0) {
            "{0,-30} dirty={1,-4} unpushed={2}" -f $_.Name, $dirty, $unpushed
        }
    }
}

if (-not $Execute) {
    Write-Host "`nDRY RUN complete. Re-run with:  -Execute -Dest <external-drive>\arch-backup`n" -ForegroundColor Green
    return
}

# ---------------- EXECUTE ----------------
if (-not $Dest) { throw "Pass -Dest <path on an EXTERNAL drive>." }
$destRoot = (Split-Path $Dest -Qualifier)
if ($destRoot -match '^[CDFZ]:') {
    throw "Dest '$Dest' is on an internal disk ($destRoot) that gets wiped. Use an external/USB drive."
}

$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$outDir = Join-Path $Dest "backup-$stamp"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
Write-Host "Backing up to $outDir ..." -ForegroundColor Green

# robocopy big trees, skipping regenerable junk
$exclude = @('node_modules', '.git', 'target', 'build', '.dart_tool', '.gradle')
foreach ($src in ($noGit + $userTrees)) {
    $leaf = Split-Path $src -Leaf
    $dst  = Join-Path $outDir $leaf
    robocopy $src $dst /E /XD $exclude /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
}

# .env files (flattened into env-files\<repo>.env)
$envOut = Join-Path $outDir 'env-files'
New-Item -ItemType Directory -Path $envOut -Force | Out-Null
foreach ($e in $envFiles) {
    $rel = $e.FullName.Substring($code.Length).TrimStart('\') -replace '[\\/]', '_'
    Copy-Item $e.FullName (Join-Path $envOut $rel) -Force
}

foreach ($f in $singleFiles) { Copy-Item $f $outDir -Force -ErrorAction SilentlyContinue }

# manifest + checksums for the keystore bundle (verify integrity later)
$ks = Join-Path $outDir 'KEYSTORE'
if (Test-Path $ks) {
    Get-ChildItem $ks -Recurse -File | Get-FileHash -Algorithm SHA256 |
        Select-Object Hash, Path | Out-File (Join-Path $outDir 'KEYSTORE-sha256.txt')
}

"Backup created $stamp" | Out-File (Join-Path $outDir 'MANIFEST.txt')
Write-Host "`nDONE. Verify $outDir, then ENCRYPT it (7z a -p -mhe=on keys.7z KEYSTORE env-files) before storing offsite." -ForegroundColor Green
Write-Host "Reminder: push the dirty/unpushed repos listed above, and enable Chrome Sync for passwords (DPAPI won't decrypt on Linux)." -ForegroundColor Yellow
