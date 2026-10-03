<#
.SYNOPSIS
    Validation entry point for Claude/dev sessions.
.DESCRIPTION
    (default)   Parse-check changed/untracked .gd files with Godot --check-only. Fast.
    -Filter X   Run tests/test_*X*.gd via tools/run_tests.ps1.
    -Full       Run the whole test suite (slow: several minutes).
    Exit code 0 = ok, 1 = failure.
#>
param(
    [string]$Filter = "",
    [switch]$Full,
    [string]$GodotPath
)
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$pinned = "C:\MASTER FOLDER\Master Tools\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$godot = $GodotPath
if (-not $godot) { $godot = $env:GODOT_BIN }
if (-not $godot -and (Test-Path $pinned)) { $godot = $pinned }
if (-not $godot) {
    $c = Get-Command godot4 -ErrorAction SilentlyContinue
    if (-not $c) { $c = Get-Command godot -ErrorAction SilentlyContinue }
    if ($c) { $godot = $c.Source }
}
if (-not $godot -or -not (Test-Path $godot)) {
    Write-Host "Godot not found. Set `$env:GODOT_BIN or pass -GodotPath." -ForegroundColor Red
    exit 1
}

if ($Full -or $Filter) {
    & (Join-Path $PSScriptRoot "run_tests.ps1") -Filter $Filter -GodotPath $godot
    exit $LASTEXITCODE
}

Push-Location $root
try {
    $changed = @(git diff --name-only HEAD -- "*.gd") + @(git ls-files --others --exclude-standard -- "*.gd") |
        Where-Object { $_ -and (Test-Path $_) } | Sort-Object -Unique
    if ($changed.Count -eq 0) { Write-Host "No changed .gd files."; exit 0 }
    $bad = 0
    foreach ($f in $changed) {
        $out = & $godot --headless --path . --check-only --script $f 2>&1 | Out-String
        $failed = ($LASTEXITCODE -ne 0) -or ($out -match "(?m)^(SCRIPT ERROR|Parse Error)")
        if ($failed) { $bad++; Write-Host "FAIL  $f" -ForegroundColor Red; Write-Host $out } else { Write-Host "ok    $f" -ForegroundColor Green }
    }
    Write-Host "$($changed.Count - $bad)/$($changed.Count) parsed cleanly"
    if ($bad -gt 0) { exit 1 }
    exit 0
}
finally { Pop-Location }
