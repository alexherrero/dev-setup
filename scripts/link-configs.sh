#!/usr/bin/env bash
# link-configs.sh — place captured configs at their real OS locations.
#
# Strategy per-file, based on who writes the file in steady state:
#
#   symlink              : user-authored, tools don't rewrite.
#                          Edits on either side sync.
#     - ~/.claude/CLAUDE.md
#
#   copy-if-absent       : app-owned JSON — the owning tool rewrites in
#                          place (reorders keys, mutates permissions arrays,
#                          inserts auto-channel keys, etc.). Symlinking would
#                          cause constant repo churn. Fresh-machine seed only;
#                          drift is managed by re-running scripts/capture.sh.
#     - ~/.claude/settings.json               (Claude Code rewrites regularly)
#     - ~/Library/.../claude_desktop_config.json (Claude Desktop reorders keys)
#     - ~/.gemini/settings.json               (Gemini CLI writes back preferences)
#     - ~/.antigravity/argv.json              (Electron/VS Code derivative)
#
#   append-idempotent    : shell fragment, not a file replacement.
#                          Guarded by a marker comment; each PATH line is
#                          only appended if not already present verbatim.
#     - configs/zsh/.zshrc-additions → appended to ~/.zshrc
#
#   git-config merge     : use `git config --global` so existing includes,
#                          credential helpers, and signing config survive.
#     - configs/git/.gitconfig → ~/.gitconfig (user.name, user.email)
#
# Any pre-existing non-matching file at a destination is moved to
# ~/.dev-machine-setup-backup/<utc-timestamp>/ before being replaced.
# Backup dir is lazy-created so a fully-idempotent re-run leaves no trace.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="$HOME/.dev-machine-setup-backup"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
BACKED_UP=0

# --- helpers ----------------------------------------------------------------

backup_if_needed() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  # Already the correct symlink into our repo? No backup needed.
  if [[ -L "$path" ]]; then
    local target; target="$(readlink "$path")"
    [[ "$target" == "$REPO_ROOT/"* ]] && return 0
  fi
  if ((BACKED_UP == 0)); then
    mkdir -p "$BACKUP_DIR"
    BACKED_UP=1
  fi
  # Preserve a legible path under the backup dir. $HOME-relative when we can,
  # otherwise flatten the absolute path.
  local rel
  if [[ "$path" == "$HOME/"* ]]; then
    rel="${path#"$HOME"/}"
  else
    rel="${path#/}"
  fi
  local bdest="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$bdest")"
  mv "$path" "$bdest"
  printf '    backed up: %s -> %s\n' "$path" "$bdest"
}

link_symlink() {
  local src_rel="$1" dest="$2"
  local src="$REPO_ROOT/$src_rel"
  [[ -f "$src" ]] || { echo "    FAIL: missing source $src" >&2; return 1; }
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    printf '    symlink   %-55s (already correct)\n' "$dest"
    return 0
  fi
  backup_if_needed "$dest"
  ln -s "$src" "$dest"
  printf '    symlink   %-55s -> %s\n' "$dest" "$src"
}

link_copy_if_absent() {
  local src_rel="$1" dest="$2"
  local src="$REPO_ROOT/$src_rel"
  [[ -f "$src" ]] || { echo "    FAIL: missing source $src" >&2; return 1; }
  if [[ -e "$dest" ]]; then
    printf '    preserve  %-55s (exists; managed by owning tool)\n' "$dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  printf '    seeded    %-55s (copy of %s)\n' "$dest" "$src_rel"
}

append_zshrc_additions() {
  local src="$REPO_ROOT/configs/zsh/.zshrc-additions"
  local dest="$HOME/.zshrc"
  local marker='# dev-machine-setup PATH additions (link-configs.sh)'
  [[ -f "$src" ]] || return 0
  touch "$dest"
  if grep -Fq "$marker" "$dest"; then
    printf '    append    %-55s (marker present)\n' "$dest"
    return 0
  fi
  # Snapshot dest before appending so the "already present?" check reads a
  # stable file and the shell can't be confused about read+write ordering.
  local existing
  existing="$(cat "$dest")"
  local appended=0
  local new_block="" line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if ! printf '%s\n' "$existing" | grep -Fq -- "$line"; then
      new_block+="$line"$'\n'
      appended=1
    fi
  done < "$src"
  {
    echo ""
    echo "$marker"
    [[ -n "$new_block" ]] && printf '%s' "$new_block"
  } >> "$dest"
  if ((appended == 1)); then
    printf '    append    %-55s (marker + new PATH lines)\n' "$dest"
  else
    printf '    append    %-55s (marker only; all PATH lines already present)\n' "$dest"
  fi
}

merge_gitconfig() {
  local src="$REPO_ROOT/configs/git/.gitconfig"
  [[ -f "$src" ]] || return 0
  local name email
  name="$(git config --file "$src" user.name 2>/dev/null || true)"
  email="$(git config --file "$src" user.email 2>/dev/null || true)"
  if [[ -z "$name" || -z "$email" ]]; then
    echo "    gitconfig: no user.name/email in $src — skipping"
    return 0
  fi
  local live_name live_email
  live_name="$(git config --global user.name 2>/dev/null || true)"
  live_email="$(git config --global user.email 2>/dev/null || true)"
  if [[ "$name" == "$live_name" && "$email" == "$live_email" ]]; then
    printf '    gitconfig %-55s (user.name/email already match)\n' "$HOME/.gitconfig"
    return 0
  fi
  git config --global user.name "$name"
  git config --global user.email "$email"
  printf '    gitconfig %-55s (set user.name=%s, user.email=%s)\n' "$HOME/.gitconfig" "$name" "$email"
}

# --- main -------------------------------------------------------------------

echo "==> linking configs"

link_symlink       configs/claude/CLAUDE.md                       "$HOME/.claude/CLAUDE.md"
link_copy_if_absent configs/claude/settings.json                  "$HOME/.claude/settings.json"
link_copy_if_absent configs/claude-desktop/claude_desktop_config.json "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
link_copy_if_absent configs/gemini/settings.json                  "$HOME/.gemini/settings.json"
link_copy_if_absent configs/antigravity/argv.json                 "$HOME/.antigravity/argv.json"
append_zshrc_additions
merge_gitconfig

# --- post-check -------------------------------------------------------------

echo "==> verifying"
# Strict JSON files.
for json in \
  "$HOME/.claude/settings.json" \
  "$HOME/Library/Application Support/Claude/claude_desktop_config.json" \
  "$HOME/.gemini/settings.json"; do
  if [[ -e "$json" ]]; then
    if jq empty "$json" >/dev/null 2>&1; then
      printf '    jq-ok     %s\n' "$json"
    else
      echo "    FAIL: invalid JSON at $json" >&2
      exit 1
    fi
  fi
done
# argv.json is JSONC (Electron / VS Code convention). Strip // line comments
# before validating, matching what scripts/capture.sh does on the way in.
argv="$HOME/.antigravity/argv.json"
if [[ -e "$argv" ]]; then
  if sed 's|//.*||' "$argv" | jq empty >/dev/null 2>&1; then
    printf '    jq-ok     %s (jsonc)\n' "$argv"
  else
    echo "    FAIL: invalid JSONC at $argv" >&2
    exit 1
  fi
fi

if [[ -L "$HOME/.claude/CLAUDE.md" ]]; then
  printf '    readlink  ~/.claude/CLAUDE.md -> %s\n' "$(readlink "$HOME/.claude/CLAUDE.md")"
fi

if ((BACKED_UP == 1)); then
  echo "    backups:  $BACKUP_DIR"
fi

echo "==> link-configs stage complete"
