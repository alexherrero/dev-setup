#!/usr/bin/env bash
# install-harness.sh — bootstrap the agentm + crickets harness layer (opt-in).
#
# OPT-IN stage: runs only when setup.sh is invoked with --with-harness (the
# orchestrator excludes it from the plan otherwise). Layered ON TOP of the base
# install — assumes the CLIs + base configs are already placed.
#
# Scope (DS-4, from the ratified ecosystem-reconciliation design):
#   task 3  clone agentm (+ git pull) and run agentm/install.sh --scope user
#   task 4  provision the Python memory engine (venv + requirements)
#   task 5  install crickets plugins via the github-source marketplace
#   task 6  wire the launchd memory daemon (macOS only)
#   task 7  state-mode fallback on Linux/Windows
#
# The operator supplies their OWN vault path + repo forks — the alexherrero/*
# defaults are a reference, not a given (see auth-checklist + docs).
#
# STATUS: no-op skeleton (DS-4 task 2). Mutating logic lands in tasks 3-7 and
# routes through a dry-run guard so the stage is verifiable without side effects.

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

echo "==> harness (opt-in)"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "    [dry-run] would bootstrap agentm + crickets + memory engine (DS-4 tasks 3-7 — not yet implemented)"
  exit 0
fi
echo "    harness-bootstrap skeleton — implementation lands in DS-4 tasks 3-7. No-op for now."
exit 0
