#!/usr/bin/env pwsh
# setup.ps1 — Windows dev-machine orchestrator.
#
# Mirror of setup.sh's shape and flag conventions. Detects Windows
# implicitly (this script only runs on Windows), then runs the install
# stages in order. Each stage's banner is printed by the sub-script
# (`==> <name>`); this orchestrator adds an outer `====> stage: <name>`
# so stage boundaries are obvious in long logs.
#
# Stage list (Windows = Mac scope: full GUI + CLI):
#   tooling         winget Git + Node LTS + gh + ripgrep
#   clis            Claude Code (winget) + Gemini CLI (npm); Codex skip-with-warn
#   gui-apps        Antigravity Desktop + Claude Desktop (winget)
#   link-configs    Place captured configs at Windows OS locations
#   verify-install  Warn-only post-setup health check
#   auth-checklist  Print manual auth steps
#
# Per-flag side effects on env vars exported to sub-stages:
#   -SkipApps     -> SKIP_APPS=1, gui-apps stage filtered out
#   -WithCodex    -> WITH_CODEX=1 (note: Codex on Windows is currently
#                                  skip-with-warn regardless; the flag
#                                  signals user intent and changes the
#                                  message in install-clis / verify-install
#                                  / auth-checklist)
#
# Force-debian-on-mac and inline OS detection are bash concepts —
# Windows scripts are implicitly platform-locked and don't need them.

[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$SkipApps,
  [switch]$WithCodex,
  [string]$Only,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot

$Stages = @(
  [pscustomobject]@{ Name = 'tooling';        Script = 'install-tooling.ps1';   Desc = 'Install winget toolchain (Git for Windows, Node LTS, gh, ripgrep)' }
  [pscustomobject]@{ Name = 'clis';           Script = 'install-clis.ps1';      Desc = 'Install Claude Code CLI (winget) + Gemini CLI (npm); Codex skip-with-warn' }
  [pscustomobject]@{ Name = 'gui-apps';       Script = 'install-gui-apps.ps1';  Desc = 'Install Antigravity Desktop + Claude Desktop (winget)' }
  [pscustomobject]@{ Name = 'link-configs';   Script = 'link-configs.ps1';      Desc = 'Place captured configs from configs/ into their Windows locations' }
  [pscustomobject]@{ Name = 'verify-install'; Script = 'verify-install.ps1';    Desc = 'Health-check the install (warn-only — tools, configs, agents, skills)' }
  [pscustomobject]@{ Name = 'auth-checklist'; Script = 'auth-checklist.ps1';    Desc = 'Print the manual auth steps (claude login, gh auth login, etc.)' }
)

function Show-Usage {
  Write-Host 'Usage: ./setup.ps1 [-DryRun] [-SkipApps] [-WithCodex] [-Only <stage>] [-Help]'
  Write-Host ''
  Write-Host 'Bootstrap a fresh Windows dev environment (full GUI + CLI scope, mirrors Mac).'
  Write-Host ''
  Write-Host 'Stages:'
  foreach ($s in $Stages) {
    '  {0,-15} {1}' -f $s.Name, $s.Desc | Write-Host
  }
  Write-Host ''
  Write-Host 'Options:'
  Write-Host '  -DryRun       Print the ordered stage list and exit (no scripts run)'
  Write-Host '  -SkipApps     Skip the gui-apps stage AND export SKIP_APPS=1 to sub-stages'
  Write-Host '  -WithCodex    Export WITH_CODEX=1 (note: Codex is currently skip-with-warn on'
  Write-Host '                Windows — install-clis.ps1 cites openai/codex#18648, #11744)'
  Write-Host '  -Only <s>     Run only the named stage'
  Write-Host '  -Help         Show this help'
  Write-Host ''
  Write-Host 'Windows = Mac scope: Antigravity Desktop and Claude Desktop are installed'
  Write-Host 'via winget. No Gemini Desktop (no first-party Windows app). See docs/windows.md.'
}

if ($Help) { Show-Usage; exit 0 }

# Export per-flag env vars so sub-stage .ps1 scripts pick them up.
# Mirrors setup.sh's `export WITH_CODEX` / `export SKIP_APPS`.
if ($WithCodex) { $env:WITH_CODEX = '1' } else { $env:WITH_CODEX = '0' }
if ($SkipApps)  { $env:SKIP_APPS  = '1' } else { $env:SKIP_APPS  = '0' }

if ($Only) {
  $validNames = $Stages | ForEach-Object { $_.Name }
  if ($validNames -notcontains $Only) {
    Write-Error ("unknown stage: {0}" -f $Only)
    Write-Error ("valid stages: {0}" -f ($validNames -join ', '))
    exit 2
  }
}

$plan = $Stages | Where-Object {
  (-not $Only -or $_.Name -eq $Only) -and
  (-not $SkipApps -or $_.Name -ne 'gui-apps')
}

if ($DryRun) {
  Write-Host '==> planned stages:'
  if (-not $plan) {
    Write-Host '    (none)'
  }
  else {
    foreach ($s in $plan) {
      $path = Join-Path $RepoRoot (Join-Path 'scripts' $s.Script)
      '    {0,-15} ({1})' -f $s.Name, $path | Write-Host
    }
  }
  exit 0
}

if (-not $plan) {
  Write-Host '==> nothing to do (all stages filtered out)'
  exit 0
}

foreach ($s in $plan) {
  $scriptPath = Join-Path $RepoRoot (Join-Path 'scripts' $s.Script)
  Write-Host ''
  Write-Host ("====> stage: {0}" -f $s.Name)
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    # Missing stage script = feature not yet implemented. Warn + continue
    # rather than halting. With tasks 1-6 of feat-windows-cli-support
    # complete, every stage script in the list above exists; this branch
    # is defensive against future PLAN.md churn.
    Write-Warning ("{0} does not exist — skipping (see PLAN.md)" -f $scriptPath)
    continue
  }
  & pwsh -NoProfile -File $scriptPath
  if ($LASTEXITCODE -ne 0) {
    Write-Error ("stage {0} failed with exit code {1}" -f $s.Name, $LASTEXITCODE)
    exit $LASTEXITCODE
  }
}

Write-Host ''
Write-Host '====> setup.ps1 complete'
