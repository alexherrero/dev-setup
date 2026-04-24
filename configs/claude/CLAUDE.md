# Global Claude Code Instructions

## Worktrees
Never create git worktrees automatically. Always work directly on the current branch (typically `main`). Do not call `EnterWorktree` unless the user explicitly asks for a worktree session.

## Commit messages
Do not append a `Co-Authored-By: Claude …` trailer to git commit messages. The user is the sole author of intent — Claude is the tool, not a co-author. Plain commit message only. Applies to every repo and every commit unless the user explicitly opts in for a specific commit.
