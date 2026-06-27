#!/usr/bin/env bash
# install-harness.sh — bootstrap the agentm + crickets harness layer (opt-in).
#
# OPT-IN stage: runs only when setup.sh is invoked with --with-harness (the
# orchestrator excludes it from the plan otherwise). Layered ON TOP of the base
# install — assumes the CLIs + base configs are already placed.
#
# Scope (DS-4, ratified ecosystem-reconciliation design) — built per task:
#   task 3  clone agentm (+ git pull) and run agentm/install.sh --scope user  [done]
#   task 4  provision the Python memory engine (venv + requirements)          [pending]
#   task 5  install crickets plugins via the github-source marketplace        [pending]
#   task 6  wire the launchd memory daemon (macOS only)                       [pending]
#   task 7  state-mode fallback on Linux/Windows                              [pending]
#
# OPERATOR-SUBSTITUTABLE: the alexherrero/* repos + clone locations below are a
# REFERENCE, not a given. Point AGENTM_REPO / AGENTM_CLONE (and, later,
# CRICKETS_REPO) at your own forks, and set your vault path via
# `agentm_config.py --vault-path <yours>` or MEMORY_VAULT_PATH. See the
# auth-checklist + docs/architecture.md.
#
# DRY-RUN: every mutating action routes through run(); DRY_RUN=1 prints the
# action instead of executing it, so the stage is verifiable on a live machine
# without side effects. The full live run is exercised on a dedicated test
# machine (see PLAN.md / progress.md).

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

AGENTM_REPO="${AGENTM_REPO:-https://github.com/alexherrero/agentm.git}"
AGENTM_CLONE="${AGENTM_CLONE:-$HOME/Antigravity/agentm}"

# run — exec a command, or print it under DRY_RUN=1. Read-only probes (file
# tests, directory checks) run for real either way, so the dry-run still
# branches correctly on real machine state; only state-changing commands wrap.
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '    [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

echo "==> harness (opt-in)"
[[ "$DRY_RUN" == "1" ]] && echo "    (dry-run — printing actions, mutating nothing)"

# --- agentm: clone-or-update, then install (--scope user) -------------------
# Install-or-update by default (decision B): clone when absent, else fast-forward
# the existing clone. agentm's installer is idempotent and, with CI=true, skips
# its interactive vault first-run prompt (vault_path is set per-machine, never
# baked — see the operator-substitutable note above).
echo "  agentm  ${AGENTM_REPO} -> ${AGENTM_CLONE}"
if [[ -d "$AGENTM_CLONE/.git" ]]; then
  run git -C "$AGENTM_CLONE" pull --ff-only
else
  run mkdir -p "$(dirname "$AGENTM_CLONE")"
  run git clone "$AGENTM_REPO" "$AGENTM_CLONE"
fi

installer="$AGENTM_CLONE/install.sh"
if [[ "$DRY_RUN" != "1" && ! -f "$installer" ]]; then
  echo "    FAIL: $installer not found after clone" >&2
  exit 1
fi
run env CI=true bash "$installer" --scope user

echo "    agentm: installed/updated (--scope user)"
exit 0
