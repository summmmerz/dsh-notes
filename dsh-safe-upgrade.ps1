<#
dsh-safe-upgrade.ps1 — upgrade @deepseek-ai/dsh WITHOUT losing runtime plugins.

WHY THIS SCRIPT EXISTS
  The published CLI manifest (@deepseek-ai/dsh) declares several RUNTIME plugins
  (dsh-llm, dsh-agent, dsh-session, dsh-host-*, ...) under devDependencies.
  `npm i -g pkg --include=dev` does NOT install them for registry installs
  (empirically verified), so a plain `npm update -g @deepseek-ai/dsh` yields a
  CLI whose `dsh web` profile cannot boot.

WHAT IT DOES
  1. uninstalls the old global dsh
  2. installs the requested version from the registry
  3. reads the NEW manifest and re-adds its @deepseek-ai/dsh-* devDependencies
     at the global top level (the CLI resolves them by walking up to the
     global node_modules root)
  4. verifies `dsh --version` and `dsh --profile web --dump-config`

USAGE
  ./dsh-safe-upgrade.ps1                # latest
  ./dsh-safe-upgrade.ps1 -Version 0.1.0-rc.8

IMPORTANT
  Close the web GUI (`dsh web`, http://127.0.0.1:3080) BEFORE running this.
  A fresh install from a local source folder (`npm i -g <repo>/apps/cli`)
  includes devDependencies automatically and does not need this script.
#>
param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$spec = if ($Version) { "@deepseek-ai/dsh@$Version" } else { "@deepseek-ai/dsh" }

Write-Host "==> 1/4 uninstalling old global dsh"
npm uninstall -g "@deepseek-ai/dsh"
if ($LASTEXITCODE -ne 0) { throw "uninstall failed" }

Write-Host "==> 2/4 installing $spec"
npm install -g $spec
if ($LASTEXITCODE -ne 0) { throw "install failed" }

# 3. discover runtime plugins declared in the NEW manifest's devDependencies
$prefix = npm prefix -g
$pkgDir = Join-Path $prefix "node_modules\@deepseek-ai\dsh"
$manifest = Get-Content (Join-Path $pkgDir "package.json") -Raw | ConvertFrom-Json

$toAdd = @()
foreach ($dep in $manifest.devDependencies.PSObject.Properties) {
    if ($dep.Name -like "@deepseek-ai/dsh-*" -and
        $dep.Name -ne "@deepseek-ai/dsh-loader-smoke" -and
        $dep.Name -ne "@deepseek-ai/dsh-llm-mock-server") {
        $toAdd += $dep.Name
    }
}
if ($toAdd.Count -gt 0) {
    Write-Host "==> 3/4 adding runtime plugins: $($toAdd -join ', ')"
    npm install -g $toAdd
    if ($LASTEXITCODE -ne 0) { throw "runtime plugin install failed" }
} else {
    Write-Host "==> 3/4 manifest is already correct; nothing to re-add"
}

# 4. verify
Write-Host "==> 4/4 verifying"
dsh --version
$dump = dsh --profile web --dump-config 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "profile boot OK ($($dump.Count) lines)"
} else {
    Write-Host "profile boot FAILED:"
    $dump | Select-Object -First 20
    exit 1
}
Write-Host "Done. You can restart the web GUI with: dsh web"
