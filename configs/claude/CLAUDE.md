# Global Claude Code Instructions

> [!NOTE]
> Symlinked into `~/.claude/CLAUDE.md` by `dev-setup/scripts/link-configs.sh`. Edits here apply globally — every Claude Code session, every project on this machine.

## Worktrees

Git worktrees are a first-class workflow, but **operator authority is required** — never spawn one without it. Authority = an explicit operator command (e.g. `/spawn-worker`, where the invocation *is* the initiation) OR a durable `isolation.mode: worktree-per-plan` config opt-in in `.harness/project.json`. Silent authority-free auto-spawn stays forbidden (not as cleanup, not as a convenience for another task, not as a side effect). Absent operator authority, work directly on the current branch (typically `main`), and do not call `EnterWorktree` on your own initiative. The line is authority, not the worktree itself. (ADR 0028, 2026-06-14, refines ADR 0022.)

## Commit messages

Do not append a `Co-Authored-By: Claude …` trailer to git commit messages. The user is the sole author of intent — Claude is the tool, not a co-author. Plain commit message only. Applies to every repo and every commit unless the user explicitly opts in for a specific commit.

## Push and confirmation

The stop-gate on a push is **recoverability, not destructiveness or blast-radius** — the same doctrine the developer-workflows execution commands (`/work`, `/bugfix`, `/release`) inline verbatim. A recoverable push proceeds (announced); only a genuinely unrecoverable one stops for confirmation. The `~/.claude/settings.json` allowlist encodes the mechanical floor: `git push`, `git push origin`, `git push -u:*`, `git push --set-upstream:*`, `git push origin HEAD:*` are auto-allowed; force / delete / branch-delete refspecs route through `ask`. Adding extra "is this OK?" ceremony in conversation on top of that gate is redundant.

**Recoverable → announce + proceed** (no confirmation wait, no conversational pre-confirm): standard `git push` / `-u` / `HEAD:`; create + push a tag; force-push to your **own un-shared** branch (you can force-push back); delete a branch whose tip is still reachable.

**Unrecoverable → pre-announce + let the harness gate stop you** (state what's about to happen so the `ask` prompt isn't surprising; don't ask permission in conversation, but don't slip it past either):

- `git push --force` / `-f` / `--force-with-lease` that **rewrites published, shared** history
- sole-ref delete of unmerged work — `git push --delete <branch>`, `git push origin --delete <branch>`, or `git push origin :<branch>` (refspec-deletion form) — when the tip is no longer reachable
- `git push --tags` that would **overwrite a published tag**
- any immutable publish / deploy / migration reached through a push

When in doubt about a **routine** push, push — the operator can always reset or force-push back, and forcing them to micromanage routine pushes is the bigger cost. When uncertain whether a **destructive** push is recoverable, treat it as unrecoverable (the conservative default the doctrine names). Applies to every repo on this device.

## GitHub `claude` contributor chip

The user has accepted the residual `claude` entry in `mentionableUsers` / contributor sidebar on `alexherrero/agentm` and `alexherrero/sherwood` (the former from cache lag after a history rewrite, the latter anchored to immutable closed PR #23). Do not propose a GitHub Support ticket, PR deletion, or any further cleanup for this. If the topic comes up again, treat it as resolved unless the user explicitly reopens it.

## Token discipline

Token budget is a hard daily constraint — the standing goal is all-day-autonomous coding on a smaller Claude plan, so treat tokens as scarce in every session. Defaults:

- **`Edit`, not `Write`, for existing files.** Output is billed ~5× input, and `Write` re-emits the whole file as output tokens while `Edit` emits only the changed strings. Reserve `Write` for new files or a near-total rewrite.
- **Stay silent between tool calls.** Don't narrate each step — surface a line only when you find something load-bearing, change direction, or hit a blocker. (This trims inter-tool chatter only; it does *not* shrink the detailed end-of-task status report the dev-flow convention below asks for.)
- **`/clear`, not `/compact`, at phase boundaries.** State is on disk (`PLAN.md` / `progress.md`); a compaction summary is redundant work that also re-bills on every later turn. `/clear` after `progress.md` is written — never mid-task.
- **Stagger agents; don't multiply them.** Time-shift the per-repo sessions so their growing contexts don't co-exist in one 5-hour window, and `/clear` idle ones. Use subagents (prefer the cheap-floor `Explore`) to keep a session's own context small — but spinning up many parallel full sessions for throughput multiplies the per-agent floor (~15×).
- **Route the model to the work.** `opusplan` (Opus plans, Sonnet executes the long phase) for token-heavy build sessions; keep full Opus for planning and audit. Set it per session with `/model opusplan`, and flag it if you notice an expensive model doing cheap work.

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
- **When a plan completes** (last task `[x]`), run the close-out in order as the final steps of the plan: flip plan-level `Status: done`, append end-of-plan summary to `progress.md`, move the corresponding ROADMAP item to Completed with a full narrative (release links + scope + what shipped + what's deferred), and **archive the active `PLAN.md` to `PLAN.archive.YYYYMMDD-<slug>.md` right then — as the final close-out step, not when the next plan starts.** (This matches the agentm harness's own `05-release.md`, which archives the completed plan at release time.)

### CHANGELOG + ADR shapes

- **CHANGELOG entries** (Keep-a-Changelog style): lead paragraph framing the release; Added / Changed / Internal sections; cross-references to paired releases when applicable (URL-link the sibling repo's release page).
- **ADRs**: `> [!NOTE]` block with `Status: accepted|superseded|rejected` + `Date`; sections Context (with open questions the decision resolves) / Decision (with rationale + "why not the alternative" per call) / Consequences (positive bullets / negative bullets / load-bearing assumptions with explicit re-audit triggers) / Related.
  - **Per-repo carve-out — ADR model retired in `agentm` + `crickets` (AG track, 2026-06-21).** In those two repos a new decision no longer adds an ADR: it amends the relevant **living design** (`wiki/designs/`) — body reconciled to current truth + a terse amendment-log entry at the bottom (date · what changed · why-not-the-alternative · re-audit trigger), the amendment and the body-update landing as **one atomic change**. The ADR *shape* above still governs **every other repo** (incl. dev-setup) until it migrates — this is a scoped opt-out, not a machine-wide flip. Rationale: the dominant drift is the chain-read (a superseding decision left pointing back through the superseded record); a living body collapses the chain, an immutable ADR + pointer re-creates it. See agentm `wiki/reference/Design-Governance.md` + the AG design-doc §5. Existing agentm/crickets ADRs fold into living designs script-driven (`migrate-adr.py`), per arc.

### Coordinated cross-repo releases

When a plan ships paired releases across sibling repos:

- **Lock the order** explicitly in the plan (which repo's release notes URL-link the other → that one ships second).
- Each release's GitHub release notes cross-link the sibling release.
- CI must be green on both release commits before plan-close.

### Wake-on-CI pattern

Don't mark tasks `[x]` speculatively. Push → schedule a ~90s wake → close out with `[x]` + `progress.md` append only when CI confirms green across the OS matrix.

### Documentation soft-warnings

When `check-wiki.py --strict` reports a soft length warning ("how-to page is N words, soft ceiling 600; consider splitting") and the content is genuinely load-bearing (worked scenarios, troubleshooting), it's acceptable to keep the page intact. Explicitly note the trade-off in the commit message / CHANGELOG.

## Harness + toolkit conventions (loaded per-project, not globally)

The `agentm` and `crickets` conventions are imported by each repo's own `CLAUDE.md`, not here: `@AGENTS.md` in `~/Antigravity/agentm/CLAUDE.md`, and `@AGENTS.md` + `@~/Antigravity/agentm/AGENTS.md` in `~/Antigravity/crickets/CLAUDE.md` (crickets runs on the agentm phase harness, so it loads both). This is the token-efficiency floor-trim (2026-06-13): a project that isn't agentm/crickets no longer re-reads either `AGENTS.md` on every tool call × every agent, and an agentm session no longer carries the crickets-only conventions. Do not re-add the global imports — that re-inflates the per-call floor for every project on the machine.
