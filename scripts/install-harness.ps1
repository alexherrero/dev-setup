#!/usr/bin/env pwsh
# install-harness.ps1 — bootstrap the agentm + crickets harness layer (opt-in).
#
# Mirror of install-harness.sh. OPT-IN stage: runs only when setup.ps1 is
# invoked with -WithHarness (the orchestrator excludes it from the plan
# otherwise). Layered ON TOP of the base install.
#
# Scope (DS-4): clone + install agentm, install crickets plugins via the
# github-source marketplace, provision the Python memory engine, state-mode
# fallback. The launchd memory daemon is macOS-only (no Windows twin in scope).
#
# The operator supplies their OWN vault path + repo forks — the alexherrero/*
# defaults are a reference, not a given (see auth-checklist + docs).
#
# STATUS: no-op skeleton (DS-4 task 2). Logic lands in tasks 3-7 behind a
# dry-run guard.

$ErrorActionPreference = 'Stop'

$dryRun = ($env:DRY_RUN -eq '1')

Write-Host '==> harness (opt-in)'
if ($dryRun) {
  Write-Host '    [dry-run] would bootstrap agentm + crickets + memory engine (DS-4 tasks 3-7 — not yet implemented)'
  exit 0
}
Write-Host '    harness-bootstrap skeleton — implementation lands in DS-4 tasks 3-7. No-op for now.'
exit 0
