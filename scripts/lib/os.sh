#!/usr/bin/env bash
# scripts/lib/os.sh — OS detection helper, sourced by other scripts.
#
# Exports $OS = "macos" | "debian" on success. Exits 2 with a descriptive
# error on anything else. Respects an externally-set $OS — set it before
# sourcing to force a path on a different host (e.g. `OS=debian ./setup.sh
# --dry-run` on a Mac dev box, used in plan / verify workflows). The
# external-override path skips all detection logic.
#
# Intentionally does not `set -e` / `set -u`: this file is sourced into
# scripts that manage their own shell flags, and we don't want to clobber
# the caller's settings.

if [[ -z "${OS:-}" ]]; then
  case "$(uname -s)" in
    Darwin)
      OS=macos
      ;;
    Linux)
      # Debian/Ubuntu and direct derivatives ship /etc/debian_version.
      # lsb_release is a secondary signal (covers some edge spins where
      # /etc/debian_version is absent or misleading). Either is sufficient.
      if [[ -f /etc/debian_version ]] || (command -v lsb_release >/dev/null 2>&1 && lsb_release -i 2>/dev/null | grep -qiE 'debian|ubuntu'); then
        OS=debian
      else
        echo "error: unsupported Linux distribution (only Debian/Ubuntu and derivatives are supported)" >&2
        echo "       uname -s: $(uname -s)" >&2
        echo "       uname -r: $(uname -r)" >&2
        if [[ -f /etc/os-release ]]; then
          # Print ID and PRETTY_NAME — the two keys most users recognize.
          grep -E '^(ID|PRETTY_NAME)=' /etc/os-release | sed 's/^/       \/etc\/os-release: /' >&2
        fi
        exit 2
      fi
      ;;
    *)
      echo "error: unsupported OS: $(uname -s)" >&2
      echo "       supported: macos (Darwin), debian (Linux with /etc/debian_version)" >&2
      exit 2
      ;;
  esac
fi

# Validate $OS regardless of whether it was detected or provided externally —
# an override of `OS=plan9` shouldn't silently fall through to the Debian
# dispatch branch in setup.sh.
case "$OS" in
  macos|debian) ;;
  *)
    echo "error: invalid \$OS=$OS (set externally?)" >&2
    echo "       supported values: macos, debian" >&2
    exit 2
    ;;
esac

export OS

# rc_file — print the absolute path of the rc file we should append PATH
# markers to. Mac is captured-zsh, so always ~/.zshrc. Debian inspects
# $SHELL: zsh -> ~/.zshrc, anything else -> ~/.bashrc. Idempotent
# callers should `touch` the result before grep'ing it.
#
# Used by scripts/install-clis.sh and scripts/link-configs.sh; centralized
# here so both stages write to the same file and stay in sync.
rc_file() {
  if [[ "$OS" == "debian" ]]; then
    case "${SHELL:-}" in
      */zsh) echo "$HOME/.zshrc" ;;
      *)     echo "$HOME/.bashrc" ;;
    esac
  else
    echo "$HOME/.zshrc"
  fi
}
