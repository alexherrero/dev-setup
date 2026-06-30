# Project Wiki

Welcome to the development-setup wiki — human-and-agent-readable documentation for this codebase. The sections below follow the **six-section documentation taxonomy** (the crickets [`documentation`](https://github.com/alexherrero/crickets/wiki/crickets-conventions) convention): each page is written for a single reader intent — doing, looking up, or understanding — and never mixes intents.

> [!NOTE]
> This page is maintained by crickets' `wiki-maintenance:documenter` sub-agent at phase boundaries. Humans may edit it directly; the sub-agent preserves human edits. `Home` is curated — it surfaces the pages a reader acts on; the [sidebar](_Sidebar) is the complete sitemap.

## 🔧 How-to guides

Task-focused recipes for users who already know the basics.

- [Install via the one-liner](Install-Via-One-Liner) — `curl | bash` / `irm | iex` bootstrap. No `git` prereq.
- [Bootstrap a new Mac](Bootstrap-A-New-Mac) — fresh Mac → full GUI + CLI dev environment via `git clone`.
- [Bootstrap a new Debian or Ubuntu host](Bootstrap-A-New-Debian-Or-Ubuntu) — fresh Linux host → CLI-only dev environment via `git clone`.

## 📖 Reference

Canonical lookup surface — tables of commands, flags, exit codes, paths.

- [Scripts reference](Scripts) — entry-point scripts (`install.sh`, `install.ps1`, `setup.sh`, `setup.ps1`); flags, exit codes, files written.

## 📐 Designs

"Why we built X" design docs; load-bearing decisions are recorded in each design's `## Amendment log` (the ADR model is retired — there is no Decisions section).

- [Development setup — design](Development-Setup-Design) — intent, shape, and trade-offs of the OS-dispatch orchestrator architecture.
- [Public curl|bash installer — design](Public-Curl-Bash-Installer) — bootstrap layer's intent, trust model, and why the redirect-Location parse beats the JSON Releases API.

## Conventions

See [README](README) for the section taxonomy, page templates, filename rules, and stylistic conventions this wiki follows.
