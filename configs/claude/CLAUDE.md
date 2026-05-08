# Global Claude Code Instructions

## Worktrees
Never create git worktrees automatically. Always work directly on the current branch (typically `main`). Do not call `EnterWorktree` unless the user explicitly asks for a worktree session.

## Commit messages
Do not append a `Co-Authored-By: Claude …` trailer to git commit messages. The user is the sole author of intent — Claude is the tool, not a co-author. Plain commit message only. Applies to every repo and every commit unless the user explicitly opts in for a specific commit.

## GitHub `claude` contributor chip
The user has accepted the residual `claude` entry in `mentionableUsers` / contributor sidebar on `alexherrero/agentic-harness` and `alexherrero/sherwood` (the former from cache lag after a history rewrite, the latter anchored to immutable closed PR #23). Do not propose a GitHub Support ticket, PR deletion, or any further cleanup for this. If the topic comes up again, treat it as resolved unless the user explicitly reopens it.
