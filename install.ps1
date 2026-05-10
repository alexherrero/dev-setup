#!/usr/bin/env pwsh
<#
.SYNOPSIS
    One-line bootstrap for development-setup on Windows.

.DESCRIPTION
    Fetches the latest tagged release from GitHub, extracts the source
    archive to a temp dir, and execs setup.ps1 from there with all
    user-supplied args forwarded. No git prereq on the host.

    Trust model: same as install.sh — the trust boundary is GitHub's
    TLS cert + the repo owner's release-signing discipline. Read the
    script before piping it to iex if you don't trust it.

    PowerShell 7+ recommended (matches the rest of setup.ps1's
    invariants); Windows PowerShell 5.1 likely works for the bootstrap
    itself but isn't routinely tested.

.EXAMPLE
    # Recommended for installs with flags — the temp-file pattern lets
    # PowerShell bind named params correctly:
    $tmp = "$env:TEMP\install.ps1"
    Invoke-WebRequest -UseBasicParsing `
        -Uri 'https://raw.githubusercontent.com/alexherrero/dev-setup/main/install.ps1' `
        -OutFile $tmp
    & $tmp -SkipApps

.EXAMPLE
    # Simple form (no args, default install):
    iwr -UseBasicParsing https://raw.githubusercontent.com/alexherrero/dev-setup/main/install.ps1 | iex
#>

[CmdletBinding()]
param(
    [switch]$SkipApps,
    [switch]$DryRun,
    [switch]$Help,
    [string]$Only
)

$ErrorActionPreference = 'Stop'

$Repo = 'alexherrero/dev-setup'
$LatestUrl = "https://github.com/$Repo/releases/latest"

# Resolve latest release tag via /releases/latest HTML redirect Location
# header — *not* the JSON Releases API. The API is rate-limited to
# 60 unauthenticated requests/hr per IP and CI runners on shared NATs
# routinely hit it (HTTP 403). The HTML redirect has no such limit and
# matches the pattern used by install.sh, install-apt.sh's shfmt
# fallback, and Anthropic's claude.ai/install.ps1.
#
#   HEAD https://github.com/<owner>/<repo>/releases/latest
#     → 302 Location: .../releases/tag/vX.Y.Z
Write-Host "==> Resolving latest release tag from $LatestUrl"
try {
    Invoke-WebRequest -Uri $LatestUrl -Method Head `
        -MaximumRedirection 0 -UseBasicParsing -ErrorAction Stop | Out-Null
    throw "Expected 302 redirect from $LatestUrl"
}
catch {
    $response = $_.Exception.Response
    if (-not $response) { throw }
    $location = $response.Headers.Location
    if (-not $location) { throw "No Location header in 302 response from $LatestUrl" }
    $locationStr = if ($location -is [System.Uri]) { $location.AbsoluteUri } else { [string]$location }
    $Tag = $locationStr -replace '.*/releases/tag/', ''
    if (-not $Tag) { throw "Could not parse tag from redirect Location: $locationStr" }
}
Write-Host "==> Latest release: $Tag"

# GitHub strips the leading 'v' from the tarball/zip top-level dir name:
# tag v3.0.0 expands to 'dev-setup-3.0.0/' inside the archive.
$Version = $Tag -replace '^v', ''

$ArchiveUrl = "https://github.com/$Repo/archive/refs/tags/$Tag.zip"

# Stage everything under a fresh per-invocation tempdir. New-TemporaryFile
# gives us a unique sentinel; we use its base name to seed a sibling dir
# so $env:TEMP contains the dir directly (Expand-Archive destination).
$WorkDir = Join-Path $env:TEMP ("dev-setup-bootstrap-{0}" -f ([guid]::NewGuid().ToString('N').Substring(0, 8)))
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
$ZipFile = Join-Path $WorkDir "$Tag.zip"

Write-Host "==> Downloading $ArchiveUrl"
Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ZipFile -UseBasicParsing

Write-Host "==> Extracting to $WorkDir"
Expand-Archive -Path $ZipFile -DestinationPath $WorkDir -Force

$Extracted = Join-Path $WorkDir "dev-setup-$Version"
if (-not (Test-Path -Path $Extracted -PathType Container)) {
    throw "Expected extract dir not found: $Extracted"
}
$SetupPs1 = Join-Path $Extracted 'setup.ps1'
if (-not (Test-Path -Path $SetupPs1 -PathType Leaf)) {
    throw "setup.ps1 not found in extract dir: $SetupPs1"
}

# Forward user-supplied params to setup.ps1 via splatting on
# $PSBoundParameters. Only params the user explicitly bound are present
# in the hashtable, so setup.ps1 sees the same surface the user typed.
Write-Host "==> Running $SetupPs1"
if ($PSBoundParameters.Count -gt 0) {
    $argsPreview = ($PSBoundParameters.GetEnumerator() | ForEach-Object {
            if ($_.Value -is [switch]) { "-$($_.Key)" } else { "-$($_.Key) $($_.Value)" }
        }) -join ' '
    Write-Host "    forwarded args: $argsPreview"
}
Write-Host "    (extract dir kept at $WorkDir — re-run setup.ps1 from there to skip the download)"
Write-Host ""

Set-Location $Extracted
& $SetupPs1 @PSBoundParameters
exit $LASTEXITCODE
