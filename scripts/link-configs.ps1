#!/usr/bin/env pwsh
# link-configs.ps1 — Windows stub (PLAN.md task 9).
#
# Real implementation deferred. Target: the Windows equivalents of each
# OS config path used by link-configs.sh:
#   - Claude Code      %USERPROFILE%\.claude\settings.json / CLAUDE.md
#   - Claude Desktop   %APPDATA%\Claude\claude_desktop_config.json
#   - Gemini CLI       %USERPROFILE%\.gemini\settings.json
#   - Antigravity      %USERPROFILE%\.antigravity\argv.json
#   - git              `git config --global`  (identical on Windows)
# Use New-Item -ItemType SymbolicLink for the symlink cases (requires
# Developer Mode or admin on older Windows). See docs/windows.md.

$ErrorActionPreference = 'Stop'

Write-Host '==> link-configs (Windows)'
Write-Host '    TODO: implement on Windows reference VM'
exit 0
