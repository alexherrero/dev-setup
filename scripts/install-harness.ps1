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
exit 0
