#!/usr/bin/env pwsh
# scripts/auth-checklist.ps1 — printed at the end of setup.ps1.
#
# Mirror of scripts/auth-checklist.sh. Always exits 0; informational
# output only, not a gate. Windows = Mac scope (full GUI + CLI), so the
# checklist includes the GUI sign-in steps that the Linux version drops.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Build the steps list. PSCustomObject pairs (Cmd, Desc) — printed with
# auto-numbering so additions / removals don't require renumbering.
$steps = @()

# CLI auth steps (always).
$steps += [pscustomobject]@{
  Cmd  = 'claude login'
  Desc = 'Sign in to the Claude Code CLI. Opens a browser for Anthropic oauth.'
}
$steps += [pscustomobject]@{
  Cmd  = 'gh auth login'
  Desc = 'Sign in to GitHub. Pick "GitHub.com" -> "HTTPS" -> "Login with a web browser". Required for `gh pr create`, `gh release create`, etc.'
}
$steps += [pscustomobject]@{
  Cmd  = 'gemini'
  Desc = 'First invocation of the Gemini CLI triggers Google oauth. Just run `gemini` in any terminal and follow the browser prompt.'
}

# GUI sign-ins (always — Windows = Mac scope, both apps installed via winget).
$steps += [pscustomobject]@{
  Cmd  = 'Open Antigravity from the Start menu'
  Desc = 'Launch Antigravity Desktop and sign in with the Google account you want it tied to. First launch finalizes workspace + agent config.'
}
$steps += [pscustomobject]@{
  Cmd  = 'Open Claude from the Start menu'
  Desc = 'Launch Claude Desktop and sign in with your Anthropic account. MCP extensions and preferences persist across restarts under %APPDATA%\Claude or %LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\... depending on install variant.'
}

# Print.
Write-Host '==> first-run auth checklist (OS=windows)'
Write-Host ''
Write-Host 'Installed tooling is in place. Complete each step below in any order — this is'
Write-Host 'the minimum set that can''t be scripted (oauth, interactive login, or signing'
Write-Host 'into the GUI apps).'
Write-Host ''

$i = 1
foreach ($s in $steps) {
  '  {0}. {1}' -f $i, $s.Cmd | Write-Host
  '     {0}'   -f $s.Desc    | Write-Host
  Write-Host ''
  $i++
}

Write-Host 'See docs/first-run.md for the same list with extra context.'

exit 0
