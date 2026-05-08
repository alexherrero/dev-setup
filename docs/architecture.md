# Architecture

How `dev-machine-setup` is laid out, what each piece does, and where the
plumbing lives. Read this if you're adapting the repo, debugging a stage
failure, or contributing.

## Repo layout

```
.
├── install.sh              POSIX bootstrap (curl|bash → setup.sh)
├── install.ps1             Windows bootstrap (irm|iex → setup.ps1)
├── setup.sh                Top-level orchestrator (Mac + Debian/Ubuntu)
├── setup.ps1               Top-level orchestrator (Windows)
├── configs/                Literal captured app configs (claude, gemini, antigravity, …)
├── scripts/                Per-concern install stages
│   ├── lib/os.sh           OS detection helper (sets $OS = macos|debian)
│   ├── install-brew.sh     Mac toolchain (Homebrew + formulae)
│   ├── install-apt.sh      Debian toolchain (apt + NodeSource + gh repos)
│   ├── install-tooling.ps1 Windows toolchain (winget: Git, Node LTS, gh, ripgrep)
│   ├── install-clis.sh     Claude Code CLI + Gemini CLI
│   ├── install-clis.ps1    Same for Windows (Claude via winget; Gemini via npm; Codex skip-with-warn)
│   ├── install-gui-apps.sh Mac-only GUI apps (browser-assisted)
│   ├── install-gui-apps.ps1 Windows GUI apps (winget Antigravity + Claude Desktop)
│   ├── link-configs.sh     Place captured configs at OS-native paths
│   ├── link-configs.ps1    Same for Windows
│   ├── verify-install.sh   Warn-only post-setup health check
│   ├── verify-install.ps1  Same for Windows
│   ├── auth-checklist.sh   Print manual auth steps
│   └── auth-checklist.ps1  Same for Windows
├── docs/                   First-run guide, Debian + Windows notes, this file
├── wiki/                   Diátaxis-shaped wiki (mirrored to GitHub Wiki on push)
└── .harness/               agentic-harness state (PLAN.md, progress.md, hooks)
```

## OS-dispatch architecture

The orchestrator detects OS, then runs a flat ordered list of per-concern
stages. There is no plugin system and no DAG — just a flat list per
platform. Each stage is idempotent: re-running converges to the same end
state instead of reinstalling.

```
install.sh / install.ps1   →  fetch latest release tarball, extract, exec setup
   │
setup.sh / setup.ps1
   │
   ├── scripts/lib/os.sh   →  detect_os()  →  macos | debian | windows
   │
   ├── macOS plan:    brew → clis → gui-apps → link-configs → verify-install → auth-checklist
   ├── Debian plan:   apt        → clis →                     link-configs → verify-install → auth-checklist
   └── Windows plan:  tooling    → clis → gui-apps          → link-configs → verify-install → auth-checklist
```

The Debian plan drops `gui-apps` deliberately — Antigravity, Claude
Desktop, and Gemini Desktop are GUI-first products with no first-party
Linux build. See [docs/debian.md](debian.md#why-antigravity-isnt-supported-on-linux).

## Why this shape

- **Single shared scripts, OS-dispatched at the top.** The alternative —
  parallel `scripts-mac/` / `scripts-debian/` / `scripts-windows/`
  trees — was rejected. Keeping `link-configs.sh` and friends shared
  keeps cross-platform drift visible at review time. The cost is a
  handful of `case "$OS"` blocks.
- **Configs as literal files in `configs/`.** Not generated, not
  templated. Every value the setup writes to `~/.claude/settings.json`
  / `~/.gemini/settings.json` / `~/.antigravity/argv.json` lives as a
  reviewable file in the repo. `scripts/capture.sh` round-trips changes
  back into the repo.
- **Idempotent everywhere.** Every stage detects already-applied state
  and skips. Pre-existing destination files are moved to
  `~/.dev-machine-setup-backup/<utc>/` before being replaced.
- **Codex opt-in.** Codex is the only CLI a user might actively *not*
  want (paid OpenAI account, separate auth). Default-off keeps the
  baseline run frictionless.
- **No `git` prereq via `install.sh` / `install.ps1`.** The bootstrap
  fetches the latest tagged release source archive over plain HTTPS,
  which is universally available. The trust boundary is GitHub's TLS
  cert + the repo owner's release-signing discipline. See
  [wiki/explanation/Public-Curl-Bash-Installer.md](../wiki/explanation/Public-Curl-Bash-Installer.md).

## Development

This repo uses the [agentic-harness](https://github.com/alexherrero/agentic-harness)
phase-gated workflow. Work is organized around `/plan` → `/work` →
`/review` → `/release`. State lives under `.harness/`; documentation
lives under `wiki/`. See [CLAUDE.md](../CLAUDE.md) and
[AGENTS.md](../AGENTS.md) for the agent entry points, and
[.harness/verify.sh](../.harness/verify.sh) for the per-file lint gate
wired into `PostToolUse`.

## Related

- [docs/first-run.md](first-run.md) — manual auth checklist.
- [docs/debian.md](debian.md) — Debian/Ubuntu specifics.
- [docs/windows.md](windows.md) — Windows specifics.
- [wiki/explanation/Dev-Machine-Setup-Design.md](../wiki/explanation/Dev-Machine-Setup-Design.md) — design rationale.
- [wiki/reference/Scripts.md](../wiki/reference/Scripts.md) — entry-point table.
