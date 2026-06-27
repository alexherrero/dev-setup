#!/usr/bin/env pwsh
# install-harness.ps1 — bootstrap the agentm + crickets harness layer (opt-in).
#
# Mirror of install-harness.sh. OPT-IN stage: runs only when setup.ps1 is
# invoked with -WithHarness (the orchestrator excludes it from the plan
# otherwise). Layered ON TOP of the base install.
#
# Scope (DS-4) — built per task:
#   task 3  clone agentm (+ git pull) and run agentm/install.sh --scope user  [done]
#   task 4  provision the Python memory engine                                [pending]
#   task 5  install crickets plugins via the github-source marketplace        [pending]
#   task 7  state-mode fallback (the launchd daemon is macOS-only, no Win twin)[pending]
#
# OPERATOR-SUBSTITUTABLE: the alexherrero/* repos + clone locations are a
# REFERENCE, not a given. Point AGENTM_REPO / AGENTM_CLONE at your own forks and
# set your vault path per-machine. See the auth-checklist + docs/architecture.md.
#
# DRY-RUN: every mutating action routes through Invoke-Run; DRY_RUN=1 prints the
# action instead of executing. Full live run is exercised on a test machine.
#
# Windows note: agentm's installer is bash; it runs under Git-for-Windows bash
# (installed by the tooling stage). Windows harness support is partial by design
# (decision E — Mac-first); the cross-platform fallback is finished in task 7.

$ErrorActionPreference = 'Stop'

$dryRun = ($env:DRY_RUN -eq '1')

$AgentmRepo  = if ($env:AGENTM_REPO) { $env:AGENTM_REPO } else { 'https://github.com/alexherrero/agentm.git' }
$AgentmClone = if ($env:AGENTM_CLONE) { $env:AGENTM_CLONE } else { Join-Path $HOME 'Antigravity/agentm' }

function Invoke-Run {
  param([Parameter(Mandatory)][string]$Exe, [string[]]$Arguments = @())
  if ($dryRun) {
    Write-Host ('    [dry-run] {0} {1}' -f $Exe, ($Arguments -join ' '))
    return
  }
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) { throw ('{0} exited {1}' -f $Exe, $LASTEXITCODE) }
}

Write-Host '==> harness (opt-in)'
if ($dryRun) { Write-Host '    (dry-run — printing actions, mutating nothing)' }

# --- agentm: clone-or-update, then install (--scope user) via bash ----------
Write-Host ('  agentm  {0} -> {1}' -f $AgentmRepo, $AgentmClone)
if (Test-Path -LiteralPath (Join-Path $AgentmClone '.git')) {
  Invoke-Run 'git' @('-C', $AgentmClone, 'pull', '--ff-only')
}
else {
  $parent = Split-Path -Parent $AgentmClone
  if (-not $dryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  else { Write-Host ('    [dry-run] mkdir {0}' -f $parent) }
  Invoke-Run 'git' @('clone', $AgentmRepo, $AgentmClone)
}

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
  Write-Warning 'bash not found (install Git for Windows) — cannot run agentm installer; skipping. See task 7 / docs.'
}
else {
  if (-not $dryRun) { $env:CI = 'true' }
  Invoke-Run 'bash' @((Join-Path $AgentmClone 'install.sh'), '--scope', 'user')
}

Write-Host '    agentm: installed/updated (--scope user)'

# --- vault / state-mode (decision E) — Windows has no Google-Drive vault shape
$agentmConfig = Join-Path $AgentmClone 'scripts/agentm_config.py'
if ($env:MEMORY_VAULT_PATH -and (Test-Path -LiteralPath $env:MEMORY_VAULT_PATH)) {
  Write-Host ('  state   vault -> {0}' -f $env:MEMORY_VAULT_PATH)
  Invoke-Run 'python3' @($agentmConfig, '--vault-path', $env:MEMORY_VAULT_PATH)
}
else {
  Write-Host '  state   local (no Google-Drive vault shape on Windows — decision E)'
  Invoke-Run 'python3' @($agentmConfig, '--state-mode', 'local')
}

# --- Python memory engine: venv + requirements (decision D, gated) ----------
$AgentmVenv = if ($env:AGENTM_VENV) { $env:AGENTM_VENV } else { Join-Path $HOME '.agentm/venv' }
$py = Get-Command python3.13 -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
$pyPath = if ($py) { $py.Path } else { 'python' }
Write-Host ('  python  venv={0}  interpreter={1}' -f $AgentmVenv, $pyPath)
if (-not $py) { Invoke-Run 'winget' @('install', '--id', 'Python.Python.3.13', '-e') }
if (-not (Test-Path -LiteralPath $AgentmVenv)) { Invoke-Run $pyPath @('-m', 'venv', $AgentmVenv) }
Invoke-Run (Join-Path $AgentmVenv 'Scripts/pip.exe') @('install', '--upgrade', '-r', (Join-Path $AgentmClone 'requirements.txt'))
Write-Host '    python: memory-engine deps in venv'

# --- crickets: plugins via github-source marketplace (decisions B + C) -------
$CricketsSlug  = if ($env:CRICKETS_REPO) { $env:CRICKETS_REPO } else { 'alexherrero/crickets' }
$CricketsClone = if ($env:CRICKETS_CLONE) { $env:CRICKETS_CLONE } else { Join-Path $HOME 'Antigravity/crickets' }
Write-Host ('  crickets  marketplace={0} (github)  clone={1}' -f $CricketsSlug, $CricketsClone)
if (Test-Path -LiteralPath (Join-Path $CricketsClone '.git')) {
  Invoke-Run 'git' @('-C', $CricketsClone, 'pull', '--ff-only')
}
else {
  $cparent = Split-Path -Parent $CricketsClone
  if (-not $dryRun) { New-Item -ItemType Directory -Force -Path $cparent | Out-Null }
  else { Write-Host ('    [dry-run] mkdir {0}' -f $cparent) }
  Invoke-Run 'git' @('clone', ('https://github.com/{0}.git' -f $CricketsSlug), $CricketsClone)
}
Invoke-Run 'claude' @('plugin', 'marketplace', 'add', $CricketsSlug)
$defaultSet = Join-Path $CricketsClone 'dist/default-set.json'
if (Test-Path -LiteralPath $defaultSet) {
  $plugins = (Get-Content -Raw $defaultSet | ConvertFrom-Json).plugins
  foreach ($p in $plugins) {
    Invoke-Run 'claude' @('plugin', 'install', ('{0}@crickets' -f $p), '--scope', 'user')
  }
}
else { Write-Warning ('{0} not found — skipping crickets plugins' -f $defaultSet) }
Write-Host '    crickets: plugins installed/updated (github-source)'

# --- memory daemon: macOS-only (decision E) ---------------------------------
# launchd is macOS-only; there is no Windows twin in this scope. A Windows
# operator who wants the MCP daemon supervises memory_mcp_server.py themselves
# (NSSM / Task Scheduler) — see docs.
Write-Host '  daemon  skipped (launchd is macOS-only — decision E)'

exit 0
