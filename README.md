<div align="center">
  <h1>dev-setup</h1>
  <p><strong>One-line bootstrap for an AI-first dev environment.</strong> Mac, Debian/Ubuntu, Windows. Idempotent. Configuration captured as literal files. No <code>git</code> prereq on the target host.</p>

  <a href="https://github.com/alexherrero/dev-setup/actions/workflows/ci-tests.yml"><img alt="CI tests" src="https://github.com/alexherrero/dev-setup/actions/workflows/ci-tests.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg"></a>
  <a href="https://github.com/alexherrero/dev-setup/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/alexherrero/dev-setup"></a>

  <br>

  <img alt="Claude" src="https://img.shields.io/badge/Claude-D97757?logo=claude&logoColor=white&style=flat-square">
  <img alt="Gemini" src="https://img.shields.io/badge/Gemini-4285F4?logo=googlegemini&logoColor=white&style=flat-square">
  <img alt="Antigravity" src="https://img.shields.io/badge/Antigravity-1A73E8?logo=google&logoColor=white&style=flat-square">
</div>

---

Opinionated bootstrap that takes a fresh Mac, Debian/Ubuntu host, or Windows machine from zero to a fully configured AI-coding dev environment in one command. Configuration lives as literal files in `configs/` so the setup is diffable, auditable, and portable. Re-running converges instead of reinstalling.

## Install

### macOS / Debian / Ubuntu

```bash
curl -fsSL https://raw.githubusercontent.com/alexherrero/dev-setup/main/install.sh | bash
```

### Windows (PowerShell 7+)

```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/alexherrero/dev-setup/main/install.ps1 | iex
```

For flag-passing examples (`--skip-apps`, `--dry-run`, etc.) and the `inspect-before-run` form, see [How to install via the one-liner](wiki/how-to/Install-Via-One-Liner.md).

### Alternative: `git clone`

```bash
git clone https://github.com/alexherrero/dev-setup.git && cd dev-setup && ./setup.sh
```

## Quick start

1. **Run the one-liner above** for your platform.
2. **Reload your shell** so newly-installed CLIs resolve. POSIX: `source ~/.zshrc` (or `~/.bashrc`). Windows: open a new PowerShell window.
3. **Complete the auth checklist** printed at the end of the run (`claude login`, `gh auth login`, `gemini` first-run, GUI sign-ins on Mac/Windows). The full list is in [docs/first-run.md](docs/first-run.md).

## What gets installed

| Component | macOS | Debian/Ubuntu | Windows | Source |
| --- | :-: | :-: | :-: | --- |
| Claude Code CLI | ✓ | ✓ | ✓ | `claude.ai/install.sh` (POSIX) / `winget` (Win) |
| Gemini CLI | ✓ | ✓ | ✓ | `npm` |
| Antigravity Desktop | ✓ | — | ✓ | DMG / `winget` |
| Claude Desktop | ✓ | — | ✓ | DMG / `winget` |
| Gemini Desktop | ✓ | — | — | DMG |
| Toolchain (`node`, `gh`, `jq`, `ripgrep`, `shellcheck`, `shfmt`) | `brew` | `apt` + NodeSource | `winget` | per-platform |

## Stages

Each platform's orchestrator runs an ordered, idempotent stage list. `--dry-run` (POSIX) / `-DryRun` (Windows) prints the plan without running anything.

| Stage | Description |
| --- | --- |
| `brew` (Mac) / `apt` (Linux) / `tooling` (Win) | Install the package manager and toolchain |
| `clis` | Install Claude Code CLI + Gemini CLI |
| `gui-apps` *(Mac/Win only)* | Install Antigravity Desktop, Claude Desktop, (Mac) Gemini Desktop |
| `link-configs` | Place captured configs at OS-native paths with backup-on-replace |
| `verify-install` | Warn-only post-setup health check (zero warns expected) |
| `auth-checklist` | Print the manual auth steps |

## Flags

| POSIX | Windows | Effect |
| --- | --- | --- |
| `--help` | `-Help` | Print stage list + flag reference, exit 0 |
| `--dry-run` | `-DryRun` | Print the planned stages and exit 0 |
| `--skip-apps` | `-SkipApps` | Skip GUI installs (CI / headless) |
| `--only <stage>` | `-Only <stage>` | Run a single stage |

## Documentation

| Doc | Description |
| --- | --- |
| [docs/first-run.md](docs/first-run.md) | Manual auth checklist (claude login, gh auth login, etc.) |
| [docs/debian.md](docs/debian.md) | Debian/Ubuntu specifics — supported-distro matrix, toolchain detail |
| [docs/windows.md](docs/windows.md) | Windows specifics — winget, MSIX redirect |
| [docs/architecture.md](docs/architecture.md) | OS-dispatch architecture, repo layout, agentic-harness pointer |
| [How to install via the one-liner](wiki/how-to/Install-Via-One-Liner.md) | One-line bootstrap recipe with flag-passing examples |
| [Public curl\|bash installer — design](wiki/explanation/Public-Curl-Bash-Installer.md) | Why the bootstrap looks the way it does, trust model |
| [Scripts reference](wiki/reference/Scripts.md) | Entry-point table — flags, exit codes, files written |
| [.harness/PLAN.md](.harness/PLAN.md) | Current plan and verification criteria |

## Testing

CI is **manually dispatched** — no auto-runs on push or PR. The [`ci-tests.yml`](.github/workflows/ci-tests.yml) workflow runs four jobs in parallel:

| Job | Runner | What it tests |
| --- | --- | --- |
| Static analysis | `ubuntu-latest` | `shellcheck`, `actionlint`, pwsh AST parse, `lychee` link check, secret-scan, LICENSE check |
| macOS | `macos-latest` | Full Mac install (`--skip-apps`); bootstrap-from-curl |
| Ubuntu | `ubuntu-latest` | Full Debian path; bootstrap-from-curl |
| Windows | `windows-latest` | Full Win install (`-SkipApps`); bootstrap-from-iwr |

Each platform job asserts `verify-install` reports zero warns and a re-run produces no repo drift. To dispatch: [Actions tab](https://github.com/alexherrero/dev-setup/actions) → **CI tests** → **Run workflow**. Concurrency is `cancel-in-progress`.

## License

[MIT](LICENSE) — Copyright (c) 2026 Alex Herrero.
