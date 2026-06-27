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

# harness_clone — clone a sibling repo, failing GRACEFULLY. A cloud/web session
# (e.g. Codespaces) commonly scopes GitHub egress to the launching repo, so
# sibling clones (agentm, crickets) hit the session git-proxy and return HTTP
# 403. The harness scripts are correct — the repos are simply unreachable. Rather
# than let `set -e` abort the whole run at exit 128, detect the failure, print
# actionable guidance, and skip the opt-in harness stage (the base install is
# unaffected). DRY_RUN routes through run() and never reaches the failure path.
harness_clone() {
  local repo="$1" dest="$2" name="$3"
  run mkdir -p "$(dirname "$dest")"
  if [[ "$DRY_RUN" == "1" ]]; then
    run git clone "$repo" "$dest"
    return 0
  fi
  local out
  if out="$(git clone "$repo" "$dest" 2>&1)"; then
    return 0
  fi
  printf '%s\n' "$out" >&2
  if printf '%s' "$out" | grep -q '403'; then
    cat >&2 <<EOF
    SKIP: harness layer — cannot reach $name ($repo) under this session's GitHub scope.
      Cloud/web sessions often limit GitHub egress to the launching repo, so sibling
      clones return HTTP 403. The scripts are correct; the repos are just unreachable here.
      Fix: broaden the session's GitHub scope to include the harness repos, point
      AGENTM_REPO / CRICKETS_REPO at reachable mirrors, or see ROADMAP DS-5
      (first-class cloud support — pip/npm-published artifacts).
EOF
  else
    printf '    SKIP: harness layer — failed to clone %s (%s).\n' "$name" "$repo" >&2
  fi
  echo "    Skipping the rest of the opt-in harness stage; base install unaffected." >&2
  exit 0
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
  harness_clone "$AGENTM_REPO" "$AGENTM_CLONE" "agentm"
fi

installer="$AGENTM_CLONE/install.sh"
if [[ "$DRY_RUN" != "1" && ! -f "$installer" ]]; then
  echo "    FAIL: $installer not found after clone" >&2
  exit 1
fi
run env CI=true bash "$installer" --scope user
echo "    agentm: installed/updated (--scope user)"

# --- vault / state-mode sequencing (decision E) -----------------------------
# agentm installed with CI=true (no interactive vault prompt), so wire the state
# backend explicitly. Mac with a resolvable vault -> vault mode (path is
# per-machine, NEVER baked — agentm's CI gate forbids hardcoded CloudStorage
# literals); otherwise (Drive not synced, or Linux/Windows) -> local state.
agentm_config="$AGENTM_CLONE/scripts/agentm_config.py"
vault="${MEMORY_VAULT_PATH:-}"
if [[ "$OS" == "macos" && -z "$vault" ]]; then
  # Best-effort auto-detect (operator can always set MEMORY_VAULT_PATH instead,
  # per decision A). Globs — not `find` — because Google Drive's File Provider
  # materializes paths on direct stat but isn't reliably enumerable by find.
  for cand in \
    "$HOME/Library/CloudStorage/GoogleDrive-"*/"My Drive/Obsidian/Agent" \
    "$HOME/Library/CloudStorage/GoogleDrive-"*/.shortcut-targets-by-id/*/"Obsidian/Agent"; do
    [[ -d "$cand" ]] && {
      vault="$cand"
      break
    }
  done
fi
if [[ -n "$vault" && -d "$vault" ]]; then
  echo "  state   vault -> $vault"
  run python3 "$agentm_config" --vault-path "$vault"
else
  echo "  state   local (no vault resolvable — Linux/Windows, or Drive not synced)"
  run python3 "$agentm_config" --state-mode local
fi

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
  harness_clone "https://github.com/${CRICKETS_REPO_SLUG}.git" "$CRICKETS_CLONE" "crickets"
fi
# Register the github-source marketplace if absent; else refresh it (decision B).
if [[ "$DRY_RUN" == "1" ]]; then
  run claude plugin marketplace add "$CRICKETS_REPO_SLUG"
else
  # Capture + bash string-match, NOT `list | grep -qi` — grep -q short-circuits
  # the pipe and SIGPIPEs the producer, which pipefail turns into a false miss.
  mk_list="$(claude plugin marketplace list 2>/dev/null || true)"
  if [[ "$mk_list" == *crickets* ]]; then
    claude plugin marketplace update crickets
  else
    claude plugin marketplace add "$CRICKETS_REPO_SLUG"
  fi
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

# --- launchd memory daemon (macOS only — decision E) ------------------------
# Scripts the manual procedure documented in agentm's plist template: substitute
# the venv interpreter (task 4 — deps live there), the absolute log dir, and
# PYTHONPATH; inject a generated bearer token via PlistBuddy (never a repo
# literal); launchctl bootstrap. IDEMPOTENT: skip if already loaded.
if [[ "$OS" == "macos" ]]; then
  plist_src="$AGENTM_CLONE/install/com.agentm.memory-server.plist"
  plist_dst="$HOME/Library/LaunchAgents/com.agentm.memory-server.plist"
  daemon_label="com.agentm.memory-server"
  log_dir="$HOME/Library/Logs/agentm"
  echo "  daemon  ${daemon_label} (launchd)"
  if [[ "$DRY_RUN" != "1" && ! -f "$plist_src" ]]; then
    echo "    WARN: $plist_src not found — skipping memory daemon" >&2
  elif launchctl print "gui/$(id -u)/$daemon_label" >/dev/null 2>&1; then
    # launchctl print (not `list | grep`): grep -q short-circuits the pipe →
    # launchctl dies with SIGPIPE → pipefail would wrongly report not-loaded.
    echo "    daemon: already loaded — skipping (idempotent; bootout+re-bootstrap to refresh)"
  elif [[ "$DRY_RUN" == "1" ]]; then
    printf '    [dry-run] sed (python3.13->%s/bin/python, AGENTM_LOG_DIR->%s, AGENTM_SCRIPTS_DIR->%s/scripts) %s > %s\n' \
      "$AGENTM_VENV" "$log_dir" "$AGENTM_CLONE" "$plist_src" "$plist_dst"
    printf '    [dry-run] PlistBuddy Set :EnvironmentVariables:AGENTM_TOKEN <generated> + launchctl bootstrap gui/%s %s\n' "$(id -u)" "$plist_dst"
  else
    mkdir -p "$log_dir" "$(dirname "$plist_dst")"
    sed -e "s|/opt/homebrew/bin/python3.13|$AGENTM_VENV/bin/python|" \
      -e "s|AGENTM_LOG_DIR|$log_dir|" \
      -e "s|AGENTM_SCRIPTS_DIR|$AGENTM_CLONE/scripts|" \
      "$plist_src" >"$plist_dst"
    /usr/libexec/PlistBuddy -c "Set :EnvironmentVariables:AGENTM_TOKEN $(openssl rand -hex 32)" "$plist_dst"
    launchctl bootstrap "gui/$(id -u)" "$plist_dst"
    echo "    daemon: bootstrapped (token set; health on http://127.0.0.1:7821/health)"
  fi
else
  echo "  daemon  skipped (launchd is macOS-only — decision E)"
fi

exit 0
