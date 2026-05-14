# Global Claude Code Instructions

> [!NOTE]
> Symlinked into `~/.claude/CLAUDE.md` by `dev-setup/scripts/link-configs.sh`. Edits here apply globally — every Claude Code session, every project on this machine.

## Worktrees

Never create git worktrees automatically. Always work directly on the current branch (typically `main`). Do not call `EnterWorktree` unless the user explicitly asks for a worktree session.

## Commit messages

Do not append a `Co-Authored-By: Claude …` trailer to git commit messages. The user is the sole author of intent — Claude is the tool, not a co-author. Plain commit message only. Applies to every repo and every commit unless the user explicitly opts in for a specific commit.

## GitHub `claude` contributor chip

The user has accepted the residual `claude` entry in `mentionableUsers` / contributor sidebar on `alexherrero/agentic-harness` and `alexherrero/sherwood` (the former from cache lag after a history rewrite, the latter anchored to immutable closed PR #23). Do not propose a GitHub Support ticket, PR deletion, or any further cleanup for this. If the topic comes up again, treat it as resolved unless the user explicitly reopens it.

## Development flow conventions

Apply by default in any project that uses a plan-driven workflow (signal: `.harness/PLAN.md` or `.harness/ROADMAP.md` present). The user will say so if a particular session wants a leaner style.

### Status reports

- **Lead with roadmap context** when `.harness/ROADMAP.md` exists: *"Currently building ROADMAP item #X — &lt;name&gt;. &lt;one-sentence framing&gt;."*
- **Include a plan-status chart** with ✅/⬜ symbols per task — greppable + scannable.
- **Include a link block** to local state files when relevant: absolute paths to `ROADMAP.md` / `PLAN.md` / `progress.md`. Note `.harness/` is gitignored.
- **End with an explicit handoff phrase**: *"Say 'let's do task N' to continue"* (or *"Ending loop"* if no follow-on action).
- After a task lands, also include: commit SHA, CI status with per-OS times, files changed count, key design calls or scope adjustments, manual verification scenarios when relevant, and negative-test results when relevant.

### `.harness/PLAN.md` shape

- **Locked design calls section** at the bottom of every plan — capture the resolutions to open design questions so they don't drift mid-plan.
- **Task `Status: [x]` annotations** include a paragraph-long narrative of what shipped, not just the checkmark. The next session's context is whatever this captures.
- **When a plan completes** (last task `[x]`): flip plan-level `Status: done`, append end-of-plan summary to `progress.md`, move the corresponding ROADMAP item to Completed with a full narrative (release links + scope + what shipped + what's deferred), archive the active `PLAN.md` to `PLAN.archive.YYYYMMDD-<slug>.md` when the next plan starts.

### CHANGELOG + ADR shapes

- **CHANGELOG entries** (Keep-a-Changelog style): lead paragraph framing the release; Added / Changed / Internal sections; cross-references to paired releases when applicable (URL-link the sibling repo's release page).
- **ADRs**: `> [!NOTE]` block with `Status: accepted|superseded|rejected` + `Date`; sections Context (with open questions the decision resolves) / Decision (with rationale + "why not the alternative" per call) / Consequences (positive bullets / negative bullets / load-bearing assumptions with explicit re-audit triggers) / Related.

### Coordinated cross-repo releases

When a plan ships paired releases across sibling repos:

- **Lock the order** explicitly in the plan (which repo's release notes URL-link the other → that one ships second).
- Each release's GitHub release notes cross-link the sibling release.
- CI must be green on both release commits before plan-close.

### Wake-on-CI pattern

Don't mark tasks `[x]` speculatively. Push → schedule a ~90s wake → close out with `[x]` + `progress.md` append only when CI confirms green across the OS matrix.

### Documentation soft-warnings

When `check-wiki.py --strict` reports a soft length warning ("how-to page is N words, soft ceiling 600; consider splitting") and the content is genuinely load-bearing (worked scenarios, troubleshooting), it's acceptable to keep the page intact. Explicitly note the trade-off in the commit message / CHANGELOG.

## Harness + toolkit conventions (auto-applied via sibling-repo imports)

The following imports pull in conventions from sibling repos at the canonical clone location (`~/Antigravity/agentic-harness/`, `~/Antigravity/agent-toolkit/`). If a sibling repo isn't installed, the import is silently skipped — only the personal style above applies in that case.

When working in a project that has its own `agentic-harness` install (its own project-level `AGENTS.md` + `CLAUDE.md`), these device-global imports may duplicate the project-level instructions. That's harmless — the agent sees the same rules twice.

@~/Antigravity/agentic-harness/AGENTS.md

@~/Antigravity/agent-toolkit/AGENTS.md
