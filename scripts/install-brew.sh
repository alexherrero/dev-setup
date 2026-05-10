#!/usr/bin/env bash
# install-brew.sh — install Homebrew (if missing) + the formulae this repo
# depends on. Idempotent: already-installed formulae are skipped by brew.
#
# Formulae installed:
#   - node       (JS runtime; also used by install-clis.sh for npm global @google/gemini-cli)
#   - gh         (GitHub CLI — auth, PRs, releases)
#   - jq         (JSON processor used by capture.sh and verify.sh)
#   - ripgrep    (fast code/content search)
#   - shellcheck (shell linter run by .harness/verify.sh on every .sh edit)
#   - shfmt      (shell formatter)
#
# No casks. GUI apps (Antigravity, Gemini Desktop, Claude Desktop) come in
# install-gui-apps.sh; they don't have stable brew casks.

set -euo pipefail

readonly FORMULAE=(node gh jq ripgrep shellcheck shfmt)

# --- 1. Install Homebrew if missing -----------------------------------------

if ! command -v brew >/dev/null 2>&1; then
  echo "==> Homebrew not found — installing"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # The installer prints shell-env instructions rather than wiring them.
  # Evaluate brew shellenv for this session so subsequent commands see it,
  # and append the same line to ~/.zprofile for future shells (Apple Silicon
  # path). On Intel Macs brew installs to /usr/local and shellenv is
  # effectively a no-op.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    marker='# brew shellenv (development-setup)'
    if ! grep -Fq "$marker" "$HOME/.zprofile" 2>/dev/null; then
      {
        echo ""
        echo "$marker"
        # Intentionally single-quoted — we want the literal $(...) written
        # into .zprofile so it evaluates at shell startup, not now.
        # shellcheck disable=SC2016
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
      } >> "$HOME/.zprofile"
    fi
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "==> Homebrew already installed: $(brew --version | head -1)"
fi

# --- 2. Install formulae (skip already-installed) ---------------------------

echo "==> ensuring formulae installed"
for f in "${FORMULAE[@]}"; do
  if brew list --formula "$f" >/dev/null 2>&1; then
    printf '    %-12s already installed\n' "$f"
  else
    printf '    %-12s installing...\n' "$f"
    brew install "$f"
  fi
done

# --- 3. Post-check ----------------------------------------------------------

# macOS default bash is 3.2, so no associative arrays — use a flat list of
# expected binary names (ripgrep -> rg is the only formula/bin mismatch).
echo "==> verifying binaries on PATH"
EXPECTED_BINS=(node gh jq rg shellcheck shfmt)
missing=()
for bin in "${EXPECTED_BINS[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    printf '    %-12s -> %s\n' "$bin" "$(command -v "$bin")"
  else
    printf '    %-12s MISSING\n' "$bin"
    missing+=("$bin")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "==> FAIL: installed but not on PATH: ${missing[*]}" >&2
  echo "    Re-open your shell or run: eval \"\$(/opt/homebrew/bin/brew shellenv)\"" >&2
  exit 1
fi

echo "==> brew stage complete"
