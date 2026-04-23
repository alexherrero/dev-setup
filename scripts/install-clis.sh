#!/usr/bin/env bash
# install-clis.sh — install the non-brew CLIs:
#   - Claude Code CLI via Anthropic's official curl installer  (→ ~/.local/bin/claude)
#   - Gemini CLI via npm global (@google/gemini-cli)           (→ brew node prefix)
#
# Requires node + npm from install-brew.sh. Idempotent: re-running pulls
# the latest stable of each (no-op if already on latest).

set -euo pipefail

readonly CLAUDE_INSTALLER_URL="https://claude.ai/install.sh"
readonly GEMINI_NPM_PACKAGE="@google/gemini-cli"

# --- Claude Code CLI --------------------------------------------------------

echo "==> Claude Code CLI"
if command -v claude >/dev/null 2>&1; then
  echo "    currently: $(claude --version 2>&1 | head -1)"
fi
# Default target is "stable" — installer is re-entrant; running it again
# either upgrades to latest stable or no-ops if already current.
curl -fsSL "$CLAUDE_INSTALLER_URL" | bash -s stable

# Ensure ~/.local/bin is on PATH in future shells. Uses a marker so the
# line is appended exactly once, even if the user has other tooling.
zshrc="$HOME/.zshrc"
marker='# ~/.local/bin (dev-machine-setup — Claude Code CLI)'
if ! grep -Fq "$marker" "$zshrc" 2>/dev/null; then
  {
    echo ""
    echo "$marker"
    # Intentionally single-quoted — we want the literal $HOME written into
    # .zshrc so it resolves at shell startup, not at write time.
    # shellcheck disable=SC2016
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "$zshrc"
  echo "    appended PATH export to $zshrc"
fi
# Make it resolvable in this shell too, for the post-check below.
export PATH="$HOME/.local/bin:$PATH"

# --- Gemini CLI -------------------------------------------------------------

echo "==> Gemini CLI ($GEMINI_NPM_PACKAGE)"
if ! command -v npm >/dev/null 2>&1; then
  echo "    FAIL: npm not found. Run scripts/install-brew.sh first." >&2
  exit 1
fi
if command -v gemini >/dev/null 2>&1; then
  echo "    currently: $(gemini --version 2>&1 | head -1)"
fi
# npm install -g is idempotent: reports "changed N packages" on upgrade,
# "up to date" when already latest.
npm install -g "$GEMINI_NPM_PACKAGE"

# --- Post-check -------------------------------------------------------------

echo "==> verifying"
missing=()
for bin in claude gemini; do
  if command -v "$bin" >/dev/null 2>&1; then
    version=$("$bin" --version 2>&1 | head -1)
    printf '    %-8s %-40s %s\n' "$bin" "$(command -v "$bin")" "$version"
  else
    printf '    %-8s MISSING\n' "$bin"
    missing+=("$bin")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "==> FAIL: CLIs not on PATH: ${missing[*]}" >&2
  exit 1
fi

echo "==> clis stage complete"
