# How to install via the one-liner bootstrap

> [!NOTE]
> **Status:** pending
> **Plan:** [.harness/PLAN.md](../../.harness/PLAN.md) — `feat-curl-bash-installer`, tasks 5–6.
> **Goal:** Bootstrap a fresh Mac, Debian/Ubuntu host, or Windows machine from zero to a fully configured AI-first dev environment with a single command — no `git clone` required.
> **Prereqs:** `curl` (or `wget`) on POSIX; PowerShell 5.1+ on Windows; admin / sudo on the target host; internet access.

The one-liner pulls the latest tagged release, extracts it to a tempdir, and execs the same `setup.sh` / `setup.ps1` orchestrator the `git clone` flow uses. The `git clone` flow keeps working — see [Bootstrap a new Mac](Bootstrap-A-New-Mac) / [Bootstrap a new Debian or Ubuntu host](Bootstrap-A-New-Debian-Or-Ubuntu).

## Steps

_Filled by /work (post-gates)._ Numbered, copy-pasteable. Skeleton:

1. _Run the one-liner for your platform (macOS / Linux: `curl -fsSL …/install.sh | bash`; Windows: `irm …/install.ps1 | iex`)._
2. _Reload your shell so PATH and rc-file additions take effect._
3. _Complete the auth checklist printed at the end of the run._

## Variants

_Filled by /work (post-gates)._ Cover at minimum:

- **macOS / Linux** — `curl … | bash` form, with the `--with-codex` flag forwarding example.
- **Windows** — `irm … | iex` form, including the `-WithCodex` flag forwarding example.
- **Inspect-before-run** — download the script first, audit, then execute (recommended security posture; mirrors Homebrew's stance).

## Verify

_Filled by /work (post-gates)._ The bootstrap prints the extract dir on exit; `verify-install.sh` runs as the penultimate stage of the orchestrator (Mac baseline 30 ok / 0 warn). See [Scripts reference](../reference/Scripts) for the canonical entry-point table.

## Troubleshooting

| Symptom | Fix |
|---|---|
| _(populated by /work post-gates)_ | _(populated by /work post-gates)_ |

## Related

- [Public curl|bash installer — design](../explanation/Public-Curl-Bash-Installer) — why the bootstrap looks the way it does, and the trust model.
- [Bootstrap a new Mac](Bootstrap-A-New-Mac) — the equivalent flow via `git clone`.
- [Bootstrap a new Debian or Ubuntu host](Bootstrap-A-New-Debian-Or-Ubuntu) — Linux equivalent via `git clone`.
