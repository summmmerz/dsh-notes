#requires -Version 5.1
<#
  dsh-shared-tree-repair.ps1  --  repair the dsh shared profile tree

  Background
  ----------
  dsh resolves runtime packages for profile plugins through a shared tree at
  %DSH_HOME%\profiles\node_modules.  Every entry there is a junction pointing at
  a package inside the dsh CLI install.  That tree is a stale snapshot: when the
  CLI is upgraded, packages it gained keep no junction and packages it dropped
  leave a dangling one.  A profile plugin that imports a package with no
  junction dies at startup with:

      Cannot find package '@deepseek-ai/dsh-xxx' imported from
      ...\node_modules\...\lib\index.js

  and dsh-safe then quarantines (disables) that plugin.

  What this script does
  ---------------------
  Mirrors EVERY package found in the CLI's own node_modules into the shared tree
  as a junction (scoped directories included).  Idempotent: existing entries are
  left untouched, and a profile's own node_modules always wins over the shared
  tree, so this cannot introduce version skew.

  Options
  -------
    -DshHome <path>   defaults to $env:DSH_HOME, else %USERPROFILE%\.dsh
    -Prune            additionally delete dangling shared-tree links whose target
                      no longer exists (they resolve nothing; safe but optional)
    -WhatIf           with -Prune, only report what would be removed

  Exit codes: 0 = ok, 1 = environment not found
#>
[CmdletBinding()]
param(
    [string]$DshHome,
    [switch]$Prune,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

if (-not $DshHome) {
    if ($env:DSH_HOME) { $DshHome = $env:DSH_HOME }
    else { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
}

# --- locate the dsh CLI install -------------------------------------------------
$cliRoot = $null
try {
    $npmRoot = (& npm root -g 2>$null | Select-Object -Last 1)
    if ($npmRoot) {
        $candidate = Join-Path $npmRoot.Trim() '@deepseek-ai\dsh'
        if (Test-Path (Join-Path $candidate 'lib\bin.js')) { $cliRoot = $candidate }
    }
} catch { }

if (-not $cliRoot) {
    $shim = Get-Command dsh -ErrorAction SilentlyContinue
    if ($shim) {
        $shimDir = Split-Path $shim.Source -Parent
        $candidate = Join-Path $shimDir 'node_modules\@deepseek-ai\dsh'
        if (Test-Path (Join-Path $candidate 'lib\bin.js')) { $cliRoot = $candidate }
    }
}
if (-not $cliRoot) { Write-Error 'Cannot locate the dsh CLI install (npm root -g / dsh shim).'; exit 1 }

$source = Join-Path $cliRoot 'node_modules'
$farm   = Join-Path $DshHome 'profiles\node_modules'
if (-not (Test-Path $source)) { Write-Error "CLI node_modules not found: $source"; exit 1 }
if (-not (Test-Path $farm))   { Write-Error "Shared profile tree not found: $farm"; exit 1 }

Write-Host "dsh CLI   : $cliRoot"
Write-Host "DSH_HOME  : $DshHome"
Write-Host "shared    : $farm"
Write-Host ''

# --- enumerate packages on both sides -------------------------------------------
function Get-PackageEntries {
    param([string]$Root)
    $names = New-Object System.Collections.Generic.List[string]
    foreach ($entry in (Get-ChildItem $Root -Force -ErrorAction SilentlyContinue)) {
        if ($entry.Name.StartsWith('.')) { continue }
        if ($entry.Name.StartsWith('@')) {
            foreach ($child in (Get-ChildItem $entry.FullName -Force -ErrorAction SilentlyContinue)) {
                if ($child.Name.StartsWith('.')) { continue }
                $names.Add("$($entry.Name)/$($child.Name)")
            }
        } else {
            $names.Add($entry.Name)
        }
    }
    return $names
}

function Get-LinkPath {
    param([string]$Farm, [string]$Name)
    if ($Name.StartsWith('@')) {
        $parts = $Name.Split('/', 2)
        return (Join-Path (Join-Path $Farm $parts[0]) $parts[1])
    }
    return (Join-Path $Farm $Name)
}

$available = Get-PackageEntries -Root $source
$present   = Get-PackageEntries -Root $farm
$presentSet = @{}
foreach ($n in $present) { $presentSet[$n] = $true }

# --- create missing junctions ---------------------------------------------------
$added = New-Object System.Collections.Generic.List[string]
$failed = New-Object System.Collections.Generic.List[string]
foreach ($name in $available) {
    if ($presentSet.ContainsKey($name)) { continue }
    $target = Get-LinkPath -Farm $source -Name $name
    $link   = Get-LinkPath -Farm $farm   -Name $name
    if (-not (Test-Path $target)) { $failed.Add("$name (target missing)"); continue }
    $parent = Split-Path $link -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    try {
        New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop | Out-Null
        $added.Add($name)
    } catch {
        $failed.Add("$name ($($_.Exception.Message))")
    }
}
Write-Host ("mirrored : {0} new junction(s); {1} already present" -f $added.Count, $present.Count)
if ($failed.Count -gt 0) {
    Write-Host ("skipped  : {0}" -f $failed.Count)
    $failed | ForEach-Object { Write-Host "           $_" }
}

# --- optional: drop dangling links ---------------------------------------------
if ($Prune) {
    $removed = 0
    foreach ($link in (Get-ChildItem $farm -Force -Recurse -Depth 1 -ErrorAction SilentlyContinue)) {
        if (-not $link.LinkType) { continue }
        if (Test-Path (Join-Path $link.FullName 'package.json')) { continue }
        $removed++
        if ($WhatIf) { Write-Host "would remove: $($link.FullName)" }
        else { Remove-Item $link.FullName -Force -Recurse -ErrorAction SilentlyContinue }
    }
    $verb = if ($WhatIf) { 'would prune' } else { 'pruned' }
    Write-Host "$verb  : $removed dangling link(s)"
}

# --- verify --------------------------------------------------------------------
$after = Get-PackageEntries -Root $farm
$afterSet = @{}
foreach ($n in $after) { $afterSet[$n] = $true }
$stillMissing = @($available | Where-Object { -not $afterSet.ContainsKey($_) })
Write-Host ''
Write-Host ("verify   : runtime packages {0}; shared tree {1}; still missing {2}" -f $available.Count, $after.Count, $stillMissing.Count)
if ($stillMissing.Count -gt 0) { $stillMissing | ForEach-Object { Write-Host "           MISSING $_" } }
exit 0
