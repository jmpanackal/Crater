<#
.SYNOPSIS
    Runs the Crater headless GDScript test suite (tests/test_*.gd) via Godot.

.DESCRIPTION
    Every file in tests/ extends SceneTree, prints PASS/FAIL lines, and calls
    quit(0) on success or quit(1) on failure (see tests/test_hollow_layout.gd
    for the pattern). This script runs each one headlessly in its own Godot
    process and reports a pass/fail summary, matching a real CI exit code
    (0 = all passed, 1 = at least one failed or Godot could not be found).

.PARAMETER Filter
    Optional substring to only run matching test files, e.g. "hollow" runs
    every tests/test_*hollow*.gd file. Defaults to running everything.

.PARAMETER GodotPath
    Override the Godot executable path for this run. Otherwise resolved from
    $env:GODOT_BIN, then the pinned local install below, then "godot4"/"godot"
    on PATH.

.PARAMETER TimeoutSeconds
    Per-test wall-clock limit, default 30s (generous for these single-scene
    headless tests). A test whose SceneTree script hits an uncaught error
    mid-function (push_error from a bad rename, a nonexistent method call,
    etc.) never reaches its own quit() call, so the Godot process would
    otherwise idle forever and hang the whole suite - this happened during
    development. A timed-out test is killed and reported as a failure rather
    than silently blocking every test after it. $PerTestTimeoutOverrides
    below raises this for specific tests that are legitimately slow (not
    hung) instead of raising it globally, which would weaken the hang-catch
    for the other ~57 tests that normally finish in a second or two.

.EXAMPLE
    tools/run_tests.ps1
.EXAMPLE
    tools/run_tests.ps1 -Filter hollow
.EXAMPLE
    $env:GODOT_BIN = "D:\Godot\Godot_v4.7.2-stable_win64_console.exe"; tools/run_tests.ps1
#>

param(
    [string]$Filter = "",
    [string]$GodotPath,
    [int]$TimeoutSeconds = 30,
    # How many tests run at once. Each test is its own headless Godot process that loads the whole Hollow, so they are
    # CPU-bound and independent; running several at once cuts the wall-clock a lot. 1 = the old one-at-a-time run.
    [int]$Jobs = 6
)

# Tests that are legitimately slow rather than hung, so they need more than
# the default budget. test_home_court_navigation.gd walks the entire opening
# route (measured ~176s wall-clock after the 2026-09-19 world-scale pass made
# every walk segment ~5x longer); everything else still gets $TimeoutSeconds.
$PerTestTimeoutOverrides = @{
	"test_home_court_navigation.gd" = 300
	"test_hollow_traversal.gd" = 600
	"test_hollow_elevators.gd" = 180
	"test_hollow_map_lint.gd" = 120
}

# Deliberately NOT "Stop": Godot writes real SCRIPT ERROR / WARNING lines to
# stderr for things that aren't fatal to this runner (a failing test's own
# push_error, ObjectDB leak warnings at exit, etc). Under "Stop", PowerShell
# can promote a child process's stderr line into a terminating error and
# abort the whole run after the first failure instead of finishing the
# summary - this happened during development. Exit codes below are checked
# explicitly instead of relying on exceptions.
$ErrorActionPreference = "Continue"

# tools/ sits directly under the project root.
$projectRoot = Split-Path -Parent $PSScriptRoot

# Known-good install on this machine (found 2026-09-13). Not committed as a
# hard requirement - override via -GodotPath or $env:GODOT_BIN on any other
# machine or CI runner.
$pinnedGodot = "C:\MASTER FOLDER\Master Tools\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

function Resolve-Godot {
    param([string]$Override)
    if ($Override) { return $Override }
    if ($env:GODOT_BIN) { return $env:GODOT_BIN }
    if (Test-Path $pinnedGodot) { return $pinnedGodot }
    $onPath = Get-Command godot4 -ErrorAction SilentlyContinue
    if (-not $onPath) { $onPath = Get-Command godot -ErrorAction SilentlyContinue }
    if ($onPath) { return $onPath.Source }
    return $null
}

$godot = Resolve-Godot -Override $GodotPath
if (-not $godot -or -not (Test-Path $godot)) {
    Write-Host "Could not find a Godot executable." -ForegroundColor Red
    Write-Host "Set `$env:GODOT_BIN to its full path, pass -GodotPath <path>, or fix `$pinnedGodot in this script." -ForegroundColor Red
    exit 1
}

$testDir = Join-Path $projectRoot "tests"
$pattern = if ($Filter) { "*$Filter*.gd" } else { "test_*.gd" }
$testFiles = Get-ChildItem -Path $testDir -Filter $pattern | Where-Object { $_.Name -like "test_*.gd" } | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Host "No test files matched filter '$Filter' in $testDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "Godot:  $godot"
Write-Host "Tests:  $($testFiles.Count) file(s)$(if ($Filter) { " matching '$Filter'" })"
Write-Host ""

Push-Location $projectRoot
try {
    $results = @()
    $suiteClock = [System.Diagnostics.Stopwatch]::StartNew()

    # Slowest tests first, so the long ones start at once and the short ones fill the gaps.
    $queue = New-Object System.Collections.Generic.List[object]
    $order = $testFiles | Sort-Object { if ($PerTestTimeoutOverrides.ContainsKey($_.Name)) { -$PerTestTimeoutOverrides[$_.Name] } else { 0 } }, Name
    $slot = 0
    foreach ($file in $order) { $slot++; $queue.Add([PSCustomObject]@{ File = $file; Slot = $slot }) }
    $running = New-Object System.Collections.Generic.List[object]

    while ($queue.Count -gt 0 -or $running.Count -gt 0) {
        while ($running.Count -lt $Jobs -and $queue.Count -gt 0) {
            $item = $queue[0]
            $queue.RemoveAt(0)
            $file = $item.File
            $rel = "tests/$($file.Name)"

            # Launched via raw System.Diagnostics.Process, NOT Start-Process:
            # Start-Process -PassThru's returned object reliably reports
            # HasExited=True but leaves ExitCode $null on Windows PowerShell 5.1
            # (confirmed while writing this script) - every test would silently
            # read as failed. Reading stdout/stderr via ReadToEndAsync (started
            # before WaitForExit, not read sequentially after) avoids the classic
            # redirected-pipe deadlock without needing event-based BeginRead.
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $godot
            $psi.Arguments = "--headless --path . --script $rel"
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            # Tests that save and load use the one save file; give each process its own so parallel runs never collide.
            $psi.EnvironmentVariables["KRATER_SAVE_SLOT"] = "t$($item.Slot)"

            $proc = [System.Diagnostics.Process]::Start($psi)
            $effectiveTimeout = $TimeoutSeconds
            if ($PerTestTimeoutOverrides.ContainsKey($file.Name) -and $PerTestTimeoutOverrides[$file.Name] -gt $TimeoutSeconds) {
                $effectiveTimeout = $PerTestTimeoutOverrides[$file.Name]
            }
            $running.Add([PSCustomObject]@{
                File = $file; Rel = $rel; Proc = $proc; Timeout = $effectiveTimeout
                Out = $proc.StandardOutput.ReadToEndAsync(); Err = $proc.StandardError.ReadToEndAsync()
                Clock = [System.Diagnostics.Stopwatch]::StartNew()
            })
        }

        foreach ($job in $running.ToArray()) {
            $timedOut = $false
            if (-not $job.Proc.HasExited) {
                if ($job.Clock.Elapsed.TotalSeconds -le $job.Timeout) { continue }
                $timedOut = $true
                try { $job.Proc.Kill() } catch {}
                $exitCode = -1
            }
            else {
                # WaitForExit(int) can return before the process's I/O buffers are
                # fully flushed; the parameterless overload blocks until they are,
                # so ExitCode is guaranteed valid after it.
                $job.Proc.WaitForExit()
                $exitCode = $job.Proc.ExitCode
            }
            $running.Remove($job) | Out-Null
            $seconds = [math]::Round($job.Clock.Elapsed.TotalSeconds, 1)

            Write-Host "--- $($job.Rel) ($seconds s) ---" -ForegroundColor Cyan
            [System.Threading.Tasks.Task]::WaitAll(@($job.Out, $job.Err), 5000) | Out-Null
            if ($job.Out.IsCompleted -and $job.Out.Result) {
                $job.Out.Result -split "`r?`n" | ForEach-Object { Write-Host $_ }
            }
            if ($job.Err.IsCompleted -and $job.Err.Result) {
                $job.Err.Result -split "`r?`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkYellow }
            }
            if ($timedOut) {
                Write-Host "TIMEOUT after $($job.Timeout)s - killed. Likely an uncaught error that never reached quit()." -ForegroundColor Red
            }
            $results += [PSCustomObject]@{
                Test     = $job.File.Name
                Passed   = ((-not $timedOut) -and ($exitCode -eq 0))
                ExitCode = $exitCode
                TimedOut = $timedOut
                Seconds  = $seconds
            }
            Write-Host ""
        }
        Start-Sleep -Milliseconds 200
    }
    $results = @($results | Sort-Object Test)
}
finally {
    Pop-Location
}

Write-Host "=== Summary ===" -ForegroundColor White
foreach ($r in $results) {
    if ($r.Passed) {
        Write-Host ("PASS   {0}" -f $r.Test) -ForegroundColor Green
    }
    elseif ($r.TimedOut) {
        Write-Host ("FAIL   {0}  (timed out)" -f $r.Test) -ForegroundColor Red
    }
    else {
        Write-Host ("FAIL   {0}  (exit {1})" -f $r.Test, $r.ExitCode) -ForegroundColor Red
    }
}


# @(...) matters: Where-Object returns a bare scalar (not a 1-element array)
# when exactly one result matches, and a bare object has no .Count property
# (reads as $null, which subtracts as 0) — that silently corrupted the
# passed/total tally whenever exactly one test failed. Confirmed while
# writing this script.
$failed = @($results | Where-Object { -not $_.Passed })
$passCount = $results.Count - $failed.Count
Write-Host ""
$summaryColor = if ($failed.Count -eq 0) { "Green" } else { "Red" }
Write-Host "$passCount/$($results.Count) passed in $([math]::Round($suiteClock.Elapsed.TotalSeconds, 0)) s ($Jobs at a time)" -ForegroundColor $summaryColor

if ($failed.Count -gt 0) {
    exit 1
}
exit 0
