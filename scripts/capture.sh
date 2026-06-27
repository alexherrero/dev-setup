#!/usr/bin/env bash
# capture.sh — copy current-machine configs into configs/, normalized and
# secret-stripped, so the repo reflects the reference dev environment.
#
# Idempotent: running twice produces no git diff (JSON is sorted, arrays
# ordered where semantics allow, machine-unique IDs removed).
#
# Sources captured:
#   ~/.claude/settings.json                → configs/claude/settings.json   (whitelist: includeCoAuthoredBy + permissions only)
#   ~/.claude/CLAUDE.md                    → configs/claude/CLAUDE.md
#   ~/Library/Application Support/Claude/
#     claude_desktop_config.json           → configs/claude-desktop/claude_desktop_config.json
#   ~/.gemini/settings.json                → configs/gemini/settings.json
#   ~/.antigravity/argv.json               → configs/antigravity/argv.json  (JSONC → JSON, ID stripped)
#   ~/.zshrc  (export PATH lines)          → configs/zsh/.zshrc-additions   (PATH lines + static MEMORY_VAULT_PATH block)
#   git global user.name + user.email      → configs/git/.gitconfig

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- helpers -----------------------------------------------------------------

# Copy JSON with sorted keys (stable diffs).
capture_json() {
  local src=$1 dst=$2
  [[ -f $src ]] || { echo "missing source: $src" >&2; return 1; }
  mkdir -p "$(dirname "$dst")"
  jq -S . "$src" > "$dst"
}

# --- Claude Code CLI ---------------------------------------------------------

mkdir -p configs/claude
# Whitelist: dev-setup owns ONLY includeCoAuthoredBy + permissions. Other keys
# (hooks → agentm; enabledPlugins / model / marketplaces / notif → Claude-app
# runtime) are owned + written by their tool, never snapshotted here — capturing
# them would make this repo a stale shadow-owner of another tool's authority.
# Sort top-level keys + permission arrays so the repo state stays diff-clean.
jq -S '
  {includeCoAuthoredBy, permissions}
  | with_entries(select(.value != null))
  | .permissions.allow |= (if . then sort else . end)
  | .permissions.ask  |= (if . then sort else . end)
' ~/.claude/settings.json > configs/claude/settings.json

cp ~/.claude/CLAUDE.md configs/claude/CLAUDE.md

# --- Claude Desktop ----------------------------------------------------------

capture_json \
  "$HOME/Library/Application Support/Claude/claude_desktop_config.json" \
  configs/claude-desktop/claude_desktop_config.json

# --- Gemini CLI --------------------------------------------------------------

capture_json ~/.gemini/settings.json configs/gemini/settings.json

# --- Antigravity -------------------------------------------------------------

# argv.json is JSONC (VS Code convention). Strip `//` line comments, remove
# the machine-unique crash-reporter-id (regenerated on first launch), and
# write valid sorted JSON. Antigravity tolerates both JSON and JSONC here.
mkdir -p configs/antigravity
sed 's|//.*||' ~/.antigravity/argv.json \
  | jq -S 'del(."crash-reporter-id")' \
  > configs/antigravity/argv.json

# --- zsh ---------------------------------------------------------------------

# Capture PATH exports from ~/.zshrc (deduped, $HOME-portable), then append the
# static MEMORY_VAULT_PATH resolver block. The PATH lines are machine-derived;
# the resolver block is dev-setup-owned static content re-emitted every run, so
# it survives capture regeneration (round-trip-safe) — a non-PATH hand-edit to
# ~/.zshrc can't wipe it. The antigravity installer re-adds its own PATH line on
# install, so capturing it is harmless (idempotent on the target side too).
mkdir -p configs/zsh
{
  awk '/^[[:space:]]*export PATH=/ && !seen[$0]++' ~/.zshrc \
    | sed "s|$HOME|\$HOME|g; s|/Users/$USER|\$HOME|g"
  cat <<'ZSHRC_BLOCK'

# agentm MemoryVault path (DS-2) — resolve from .agentm-config.json if present.
# No-ops cleanly when jq or the config is absent (e.g. base install, no harness).
if command -v jq >/dev/null 2>&1 && [ -f "$HOME/.claude/.agentm-config.json" ]; then
  MEMORY_VAULT_PATH="$(jq -r '."plugins.obsidian-vault.vault_path" // .vault_path // empty' "$HOME/.claude/.agentm-config.json" 2>/dev/null)"
  if [ -n "$MEMORY_VAULT_PATH" ]; then
    export MEMORY_VAULT_PATH
  else
    unset MEMORY_VAULT_PATH
  fi
fi
ZSHRC_BLOCK
} > configs/zsh/.zshrc-additions

# --- git ---------------------------------------------------------------------

# Write a fresh [user] section from git's global config, rather than copying
# ~/.gitconfig verbatim — avoids dragging in machine-specific includes or
# credential helpers.
mkdir -p configs/git
{
  echo "[user]"
  printf '\tname = %s\n' "$(git config --global user.name)"
  printf '\temail = %s\n' "$(git config --global user.email)"
} > configs/git/.gitconfig

echo "==> capture complete"
echo "    review with: git diff configs/"
