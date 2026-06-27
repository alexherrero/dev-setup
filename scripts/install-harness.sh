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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/os.sh
. "$REPO_ROOT/scripts/lib/os.sh" # sets $OS (macos|debian)

AGENTM_REPO="${AGENTM_REPO:-https://github.com/alexherrero/agentm.git}"
AGENTM_CLONE="${AGENTM_CLONE:-$HOME/Antigravity/agentm}"
AGENTM_VENV="${AGENTM_VENV:-$HOME/.agentm/venv}"

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

# --- Python memory engine: venv + requirements (decision D, gated) ----------
# The MCP memory daemon (task 6) runs from this venv's interpreter, so deps live
# in the venv — not system site-packages (homebrew python is PEP-668 externally-
# managed). These are heavy (sentence-transformers etc.); gated behind the
# opt-in --with-harness flag so base installs stay lean.
PYTHON_BIN="$(command -v python3.13 || command -v python3 || true)"
echo "  python  venv=${AGENTM_VENV}  interpreter=${PYTHON_BIN:-<none>}"
if [[ -z "$PYTHON_BIN" ]]; then
  if [[ "$OS" == "macos" ]]; then
    run brew install python@3.13
    PYTHON_BIN="/opt/homebrew/bin/python3.13"
  else
    echo "    FAIL: no python3 found (need >=3.10 for the memory engine)" >&2
    [[ "$DRY_RUN" == "1" ]] || exit 1
    PYTHON_BIN="python3"
  fi
fi
[[ -d "$AGENTM_VENV" ]] || run "$PYTHON_BIN" -m venv "$AGENTM_VENV"
reqs="$AGENTM_CLONE/requirements.txt"
if [[ "$DRY_RUN" != "1" && ! -f "$reqs" ]]; then
  echo "    WARN: $reqs not found — skipping memory-engine deps" >&2
else
  run "$AGENTM_VENV/bin/pip" install --upgrade -r "$reqs"
fi
echo "    python: memory-engine deps in venv"

# --- crickets: plugins via github-source marketplace (decisions B + C) -------
# Marketplace is GITHUB-source (clean, consistent updates; makes every plugin a
# real install incl. ship-release/releasing-conventions). The clone is for the
# default-set list + local dev only — installed plugins don't need it at runtime.
CRICKETS_REPO_SLUG="${CRICKETS_REPO:-alexherrero/crickets}"
CRICKETS_CLONE="${CRICKETS_CLONE:-$HOME/Antigravity/crickets}"
echo "  crickets  marketplace=${CRICKETS_REPO_SLUG} (github)  clone=${CRICKETS_CLONE}"
if [[ -d "$CRICKETS_CLONE/.git" ]]; then
  run git -C "$CRICKETS_CLONE" pull --ff-only
else
  run mkdir -p "$(dirname "$CRICKETS_CLONE")"
  run git clone "https://github.com/${CRICKETS_REPO_SLUG}.git" "$CRICKETS_CLONE"
fi
# Register the github-source marketplace if absent; else refresh it (decision B).
if [[ "$DRY_RUN" == "1" ]]; then
  run claude plugin marketplace add "$CRICKETS_REPO_SLUG"
elif claude plugin marketplace list 2>/dev/null | grep -qi crickets; then
  claude plugin marketplace update crickets
else
  claude plugin marketplace add "$CRICKETS_REPO_SLUG"
fi
# Install-or-update each plugin in the default set (decision B).
default_set="$CRICKETS_CLONE/dist/default-set.json"
if [[ -f "$default_set" ]]; then
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if [[ "$DRY_RUN" == "1" ]]; then
      printf '    [dry-run] claude plugin install %s@crickets --scope user (or update)\n' "$p"
    else
      claude plugin install "$p@crickets" --scope user 2>/dev/null \
        || claude plugin update "$p@crickets" \
        || echo "    WARN: could not install/update $p@crickets" >&2
    fi
  done < <(jq -r '.plugins[]' "$default_set")
else
  echo "    WARN: $default_set not found — skipping crickets plugins" >&2
fi
echo "    crickets: plugins installed/updated (github-source)"

exit 0
