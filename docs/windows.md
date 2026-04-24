# Windows support

The Windows implementation of `setup.sh` is **deferred**. The `.ps1`
files in this repo are parseable skeletons with the same stage
structure as the Mac scripts — each prints its stage banner followed
by `TODO: implement on Windows reference VM` and exits 0.

## Why deferred

- Each vendor's Windows installer is shaped differently (winget IDs,
  `Setup.exe`, MSIX, MSI, curl-to-installer) — verifying every path
  needs a clean Windows reference VM, which we haven't wired up.
- macOS is the primary dev surface today. Shipping a half-tested
  Windows bootstrap is worse than an honest stub that refuses to lie.
- Several behaviors need real-OS validation before they can be
  scripted: symlink creation (Developer Mode / admin), SmartScreen
  "Mark-of-the-Web" handling (equivalent of `xattr -d com.apple.quarantine`),
  and whether each app respects `%APPDATA%` or `%LOCALAPPDATA%`.

## What exists today

- [setup.ps1](../setup.ps1) — orchestrator with the same stage list as
  [setup.sh](../setup.sh) (`brew → clis → gui-apps → link-configs →
  auth-checklist`) and the same flag shape (`-DryRun`, `-SkipApps`,
  `-Only <stage>`, `-Help`).
- [scripts/install-brew.ps1](../scripts/install-brew.ps1),
  [scripts/install-clis.ps1](../scripts/install-clis.ps1),
  [scripts/install-gui-apps.ps1](../scripts/install-gui-apps.ps1),
  [scripts/link-configs.ps1](../scripts/link-configs.ps1),
  [scripts/auth-checklist.ps1](../scripts/auth-checklist.ps1) — one
  stub per stage. Each prints its stage banner + TODO + exits 0 so the
  orchestrator walks through the full plan predictably.
- [.harness/verify.sh](../.harness/verify.sh) — parses every `.ps1`
  under the PowerShell AST when `pwsh` is installed; no-ops otherwise,
  matching today's macOS dev surface.

## What still needs to be built

| Stage | Remaining work |
| --- | --- |
| `install-brew.ps1` | Decide on winget vs. Chocolatey for the equivalents of `node` / `gh` / `jq` / `ripgrep` / `shellcheck` / `shfmt`. `gh` and `jq` have first-party winget manifests; the rest need to be confirmed. |
| `install-clis.ps1` | Locate Anthropic's Windows-side installer for Claude Code (or fall back to an npm-global). Gemini CLI (`@google/gemini-cli`) is identical to the macOS path once node is on PATH. |
| `install-gui-apps.ps1` | Resolve winget IDs for Antigravity, Gemini Desktop, Claude Desktop; if missing, port the browser-assisted shape from [install-gui-apps.sh](../scripts/install-gui-apps.sh) — open download URL, poll install dir, strip MOTW. |
| `link-configs.ps1` | Map each captured config to its Windows path (`%USERPROFILE%\.claude\...`, `%APPDATA%\Claude\...`, `%USERPROFILE%\.gemini\...`). Use `New-Item -ItemType SymbolicLink` where the macOS version symlinks (requires Developer Mode enabled). Keep copy-if-absent for the tool-owned JSONs. Port the `~/.zshrc` marker-block append to `$PROFILE`. |
| `auth-checklist.ps1` | Near-verbatim port of [auth-checklist.sh](../scripts/auth-checklist.sh). |
| `scripts/capture.ps1` (new) | Not listed in the current PLAN, but a Windows equivalent of [capture.sh](../scripts/capture.sh) will be needed so the reference-machine capture loop works on both platforms. |

## Why keep the skeletons in the repo?

The project's stated contract is cross-platform. Keeping the `.ps1`
structure in place means adding Windows support later is a matter of
filling in bodies, not redesigning the orchestrator shape or retrofitting
a parallel directory tree.
