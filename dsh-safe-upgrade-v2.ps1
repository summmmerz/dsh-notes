<#
dsh-safe-upgrade-v2.ps1 -- upgrade @deepseek-ai/dsh without losing runtime plugins.

WHY v2 EXISTS (what was wrong with v1 = dsh-safe-upgrade.ps1)
-------------------------------------------------------------
v1 line 59 was `npm install -g $toAdd` (no version pin). Measured 2026-09-30, that is
CATASTROPHIC, because the official sub-packages publish a stale `latest` dist-tag:

  @deepseek-ai/dsh-base           latest = 0.0.1-rc.1   (the real 0.2.0-rc.2 is on `next`)
  @deepseek-ai/dsh-llm            latest = 0.0.1-rc.1
  @deepseek-ai/dsh-web-app        latest = 0.0.1-rc.1
  @deepseek-ai/dsh-plugin-manager latest = 0.1.6-alpha.2

So v1 installs dsh-base / dsh-llm / dsh-web-app at 0.0.1-rc.1 -- far OLDER than what you
already had -- producing an environment that cannot boot.

v2 reads each version string out of the new manifest and installs EXACT versions.
Good news: in 0.2.0-rc.2 all 115 `@deepseek-ai/dsh-*` specs are already exact
(no caret ranges), so copying them verbatim is safe.

WHY THIS SCRIPT IS NEEDED AT ALL
--------------------------------
The published @deepseek-ai/dsh manifest declares core runtime packages (dsh-llm,
dsh-agent, dsh-session, dsh-host-webserver, dsh-tools, ...) under devDependencies
instead of dependencies -- still true in 0.2.0-rc.2. `npm i -g` does not install
devDependencies, so the `dsh web` profile cannot boot. This script re-adds those
packages at the global top level, where the CLI finds them by walking up.

USAGE
-----
  # Close the running dsh web GUI FIRST (it holds node_modules open).
  ./dsh-safe-upgrade-v2.ps1                  # install the `next` tag (currently 0.2.0-rc.2)
  ./dsh-safe-upgrade-v2.ps1 -Version 0.2.0-rc.2
  ./dsh-safe-upgrade-v2.ps1 -DryRun          # print the plan, change nothing

NOTE
----
Do NOT use `@latest`: the latest tag points at the very old 0.0.1-rc.1.
This script defaults to the `next` tag.

This file is intentionally ASCII-only so it parses correctly regardless of the
console code page or the file's encoding.
#>
param(
    [string]$Version = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ---- 0. Safety: is dsh web still running? ----
$running = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'dsh' -and $_.CommandLine -match 'web' }
if ($running) {
    Write-Host "[!] dsh web is still running (pid: $($running.ProcessId -join ', '))." -ForegroundColor Yellow
    Write-Host "    Close it before upgrading; it holds node_modules open." -ForegroundColor Yellow
    if (-not $DryRun) { throw "Stop dsh web first." }
}

# ---- 1. Resolve target version ----
$spec = if ($Version) { "@deepseek-ai/dsh@$Version" } else { "@deepseek-ai/dsh@next" }
Write-Host "==> 1/6 Resolving target: $spec"
$targetVersion = (npm view $spec version 2>&1 | Out-String).Trim()
if ($targetVersion -notmatch '^(0|[1-9])') { throw "Could not resolve version: $targetVersion" }
Write-Host "    target version = $targetVersion"

# ---- 2. Back up the current manifest ----
Write-Host "==> 2/6 Backing up the current global manifest"
$prefix = (npm prefix -g | Out-String).Trim()
$pkgDir = Join-Path $prefix "node_modules\@deepseek-ai\dsh"
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$liveManifest = Join-Path $pkgDir "package.json"
if (Test-Path $liveManifest) {
    $bak = Join-Path $pkgDir "package.json.bak-$stamp"
    if ($DryRun) {
        Write-Host "    [DryRun] would back up -> $bak"
    } else {
        Copy-Item $liveManifest $bak -Force
        Write-Host "    backed up -> $bak"
    }
}

# ---- 3. Uninstall + install ----
if ($DryRun) {
    Write-Host "==> 3/6 [DryRun] npm uninstall -g @deepseek-ai/dsh"
    Write-Host "==> 3/6 [DryRun] npm install -g $spec"
} else {
    Write-Host "==> 3/6 Uninstalling old, installing $targetVersion"
    npm uninstall -g "@deepseek-ai/dsh" | Out-Null
    npm install -g $spec
    if ($LASTEXITCODE -ne 0) { throw "Install failed." }
}

# ---- 4. Collect runtime plugins from the NEW manifest, with exact versions ----
Write-Host "==> 4/6 Reading the new manifest for runtime plugins"
if (-not (Test-Path $liveManifest)) { throw "Manifest not found: $liveManifest" }
$manifest = Get-Content $liveManifest -Raw | ConvertFrom-Json

$skip = @('@deepseek-ai/dsh-loader-smoke', '@deepseek-ai/dsh-llm-mock-server')
$toAdd = @()

# devDependencies is the part `npm i -g` misses.
foreach ($dep in $manifest.devDependencies.PSObject.Properties) {
    if ($dep.Name -like '@deepseek-ai/dsh-*' -and $dep.Name -notin $skip) {
        $v = [string]$dep.Value
        # Manifest specs are exact. Fall back to the target version if a range shows up.
        if ($v -match '[\^~><*|]' -or $v -eq 'latest' -or [string]::IsNullOrWhiteSpace($v)) {
            $v = $targetVersion
        }
        $toAdd += "$($dep.Name)@$v"
    }
}

Write-Host "    $($toAdd.Count) package(s) to re-add, all pinned to manifest versions"
if ($toAdd.Count -eq 0) {
    Write-Host "    No @deepseek-ai/dsh-* devDependencies; nothing to re-add."
} elseif ($DryRun) {
    $toAdd | ForEach-Object { Write-Host "      [DryRun] $_" }
} else {
    $batch = 30
    for ($i = 0; $i -lt $toAdd.Count; $i += $batch) {
        $end = [Math]::Min($i + $batch - 1, $toAdd.Count - 1)
        $chunk = $toAdd[$i..$end]
        Write-Host "    installing batch $([int]($i / $batch) + 1) ($($chunk.Count) packages)"
        npm install -g $chunk
        if ($LASTEXITCODE -ne 0) { throw "Runtime plugin install failed." }
    }
}

# ---- 5. Verify installed versions ----
if (-not $DryRun) {
    Write-Host "==> 5/6 Verifying installed versions"
    $installed = $null
    try { $installed = (npm ls -g --depth=0 --json 2>$null | Out-String | ConvertFrom-Json) } catch { }
    $bad = @()
    foreach ($name in '@deepseek-ai/dsh-llm', '@deepseek-ai/dsh-agent', '@deepseek-ai/dsh-session',
                      '@deepseek-ai/dsh-host-webserver', '@deepseek-ai/dsh-base', '@deepseek-ai/dsh-web-app') {
        $actual = $null
        if ($installed -and $installed.dependencies) {
            $p = $installed.dependencies.PSObject.Properties[$name]
            if ($p) { $actual = $p.Value.version }
        }
        if (-not $actual) {
            $bad += "$name not installed"
        } elseif ($actual -ne $targetVersion) {
            $bad += "$name mismatch: $actual (expected $targetVersion)"
        } else {
            Write-Host "    OK  $name = $actual"
        }
    }
    if ($bad.Count -gt 0) {
        Write-Host "    WARNINGS:" -ForegroundColor Yellow
        $bad | ForEach-Object { Write-Host "      $_" -ForegroundColor Yellow }
    }
}

# ---- 6. Verify the profile boots ----
Write-Host "==> 6/6 Verifying the profile loads"
if ($DryRun) { Write-Host "    [DryRun] skipped"; return }

$dshVer = (dsh --version 2>&1 | Out-String).Trim()
Write-Host "    dsh --version = $dshVer"

$dump = dsh --profile web --dump-config 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "    profile boot OK ($($dump.Count) lines)"
} else {
    Write-Host "    profile boot FAILED:" -ForegroundColor Red
    $dump | Select-Object -First 30 | ForEach-Object { Write-Host "      $_" }
    exit 1
}

Write-Host ""
Write-Host "Done. Start it with:" -ForegroundColor Green
Write-Host "  dsh web"
Write-Host ""
Write-Host "Remember the breaking changes: V4 Flash was removed from the default model list,"
Write-Host "so you may need to re-select your model in Settings."
