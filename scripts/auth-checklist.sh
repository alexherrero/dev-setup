#!/usr/bin/env bash
# auth-checklist.sh — printed at the end of setup.sh. Enumerates the
# manual auth / first-run steps that preceding stages cannot automate.
# Always exits 0; this is informational output, not a gate.
#
# Cross-platform. Mac shows the GUI sign-in steps (Antigravity, Claude
# Desktop); Debian drops them since the CLI-only Linux scope doesn't
# install GUI apps.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/os.sh
. "$REPO_ROOT/scripts/lib/os.sh"

# Build the steps array dynamically per-OS. Each entry is a heredoc-style
# two-line block: `<command>` then a description on the next line. The
# numbering is added at print time so additions / removals don't require
# renumbering downstream.
steps=()

# Always present on both platforms.
steps+=(
"claude login|Sign in to the Claude Code CLI. Opens a browser for Anthropic oauth."
"gh auth login|Sign in to GitHub. Pick \"GitHub.com\" → \"HTTPS\" → \"Login with a web browser\". Required for \`gh pr create\`, \`gh release create\`, etc."
"gemini|First invocation of the Gemini CLI triggers Google oauth. Just run \`gemini\` in any terminal and follow the browser prompt."
)

# GUI sign-ins only run on Mac (CLI-only on Debian — no GUI apps were installed).
if [[ "$OS" == "macos" ]]; then
  steps+=(
"open -a Antigravity|Launch Antigravity and sign in with the Google account you want it tied to. First launch finalizes workspace + agent config."
"open -a Claude|Launch Claude Desktop and sign in with your Anthropic account. MCP extensions and preferences persist across restarts."
  )
fi

# Harness-layer steps (only when --with-harness was passed).
if [[ "${WITH_HARNESS:-0}" == "1" ]]; then
  steps+=(
"(harness) supply your OWN vault + forks|The harness stage uses alexherrero/agentm + alexherrero/crickets and a Google-Drive Obsidian vault as a REFERENCE, not a given. Point AGENTM_REPO / CRICKETS_REPO at your forks; set your vault via \`python3 ~/Antigravity/agentm/scripts/agentm_config.py --vault-path <yours>\` or export MEMORY_VAULT_PATH. No vault → local state."
"(harness) Google Drive + Obsidian (optional)|For vault-backed memory: install Google Drive for Desktop, sign in, sync your Obsidian vault. macOS auto-detects it; Linux/Windows use local state (no Drive shape)."
"(harness) MCP memory daemon token|macOS only: the launchd daemon got a generated AGENTM_TOKEN — read it from ~/Library/LaunchAgents/com.agentm.memory-server.plist to point an MCP host at http://127.0.0.1:7821. Linux: supervise memory_mcp_server.py yourself (no launchd)."
  )
fi

# Print the checklist.
if [[ "$OS" == "macos" ]]; then
  heading_intro="Installed tooling is in place."
else
  heading_intro="CLI install complete (no GUI apps on Debian — that's by design)."
fi

cat <<EOF
==> first-run auth checklist (OS=$OS)

$heading_intro Complete each step below in any order — this is the
minimum set that can't be scripted (oauth, interactive login, or
signing into the GUI apps).

EOF

i=1
for entry in "${steps[@]}"; do
  cmd="${entry%%|*}"
  desc="${entry#*|}"
  printf '  %d. %s\n     %s\n\n' "$i" "$cmd" "$desc"
  i=$((i + 1))
done

echo "See docs/first-run.md for the same list with extra context."
