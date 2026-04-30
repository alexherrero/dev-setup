# Scripts reference

> [!NOTE]
> **Status:** pending
> **Plan:** [.harness/PLAN.md](../../.harness/PLAN.md) — `feat-curl-bash-installer`, tasks 5–6.

The canonical lookup surface for the repo-root entry-point scripts — the curl|bash bootstrap (`install.sh` / `install.ps1`) and the orchestrators they hand off to (`setup.sh` / `setup.ps1`). Per-stage scripts under `scripts/` are documented inline in the source; this page only covers the public entry points users invoke directly.

## ⚡ Quick Reference

| Script | Platform | Purpose | Entry point for |
|---|---|---|---|
| `install.sh` | macOS / Linux | _(populated by /work post-gates)_ — curl\|bash bootstrap; fetches latest release tag, extracts, execs `setup.sh`. | `curl -fsSL …/install.sh \| bash` |
| `install.ps1` | Windows | _(populated by /work post-gates)_ — `irm`/`iex` bootstrap; fetches latest release zip, extracts, execs `setup.ps1`. | `irm …/install.ps1 \| iex` |
| `setup.sh` | macOS / Linux | OS-dispatching orchestrator — runs the per-platform stage list. | `git clone` flow + `install.sh` hand-off. |
| `setup.ps1` | Windows | Windows orchestrator. | `git clone` flow + `install.ps1` hand-off. |

## Flags

| Script | Flag | Effect |
|---|---|---|
| `install.sh` | _(populated by /work post-gates)_ | _(populated by /work post-gates — at minimum: forwarded args go to `setup.sh`.)_ |
| `install.ps1` | _(populated by /work post-gates)_ | _(populated by /work post-gates — at minimum: splatted args go to `setup.ps1`.)_ |
| `setup.sh` | `--with-codex` | Also installs the OpenAI Codex CLI. Off by default. Exports `WITH_CODEX=1` to subprocesses. |
| `setup.sh` | `--dry-run` | _(populated by /work post-gates — confirms in-source flag name.)_ Prints the stage list without executing. |
| `setup.ps1` | `-WithCodex` | _(confirm by /work)_ Windows equivalent of `--with-codex`. |
| `setup.ps1` | `-Help` | Prints usage and exits 0. |

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success. |
| `2` | `setup.sh`: unsupported OS (not macOS, not Debian-family). |
| non-zero | Bootstrap or stage failure — inspect stderr, the printed extract dir, or `verify-install.sh` output. |

## Files

| Path | Purpose |
|---|---|
| `install.sh` | POSIX bootstrap — repo-root, served via `raw.githubusercontent.com`. |
| `install.ps1` | Windows bootstrap — repo-root, served via `raw.githubusercontent.com`. |
| `setup.sh` | OS-dispatching orchestrator. |
| `setup.ps1` | Windows orchestrator. |
| `scripts/lib/os.sh` | `detect_os()` — single source of truth for `macos` / `debian` / unsupported. |
| `scripts/verify-install.sh` | Penultimate stage; emits the `N ok / N warn / N skip` summary the bootstrap and `git clone` flows both rely on. |

## Related

- [Install via the one-liner](../how-to/Install-Via-One-Liner) — task-level recipe.
- [Public curl\|bash installer — design](../explanation/Public-Curl-Bash-Installer) — intent, trust model, trade-offs.
- [Bootstrap a new Mac](../how-to/Bootstrap-A-New-Mac) — `git clone` flow on macOS.
- [Bootstrap a new Debian or Ubuntu host](../how-to/Bootstrap-A-New-Debian-Or-Ubuntu) — `git clone` flow on Linux.
