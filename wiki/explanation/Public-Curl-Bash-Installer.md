# Public curl|bash installer — design

> [!NOTE]
> **Status:** pending
> **Plan:** [.harness/PLAN.md](../../.harness/PLAN.md) — `feat-curl-bash-installer`, tasks 4–6.

The intent, trust model, and shape of the public one-liner bootstrap (`curl … | bash` on macOS / Linux, `irm … | iex` on Windows) that pins to the latest GitHub release tag and then hands off to the existing `setup.sh` / `setup.ps1` orchestrators.

## Intent

_Filled by /work (post-gates)._ Cover: why the repo went public, why a curl|bash bootstrap over a `git clone` flow, why latest-release-tag instead of `main` HEAD, and how the bootstrap relates to the existing `setup.sh` / `setup.ps1` entry points.

## Shape

_Filled by /work (post-gates)._ ASCII diagram of the bootstrap flow: API call → tarball/zip download → extract to tempdir → exec `setup.sh` / `setup.ps1` with forwarded args. Note the `curl`-or-`wget` fallback on POSIX and the `Invoke-RestMethod` / `Expand-Archive` path on Windows. Reference the no-jq / grep-sed parsing approach already used in `install-apt.sh`.

## Trust model

_Filled by /work (post-gates)._ Document the security posture: trust = GitHub TLS + the user's own pre-pipe audit. Mirror Homebrew's wording. Note that the bootstrap pulls a tagged release (reviewed, tested) rather than `main` HEAD (unreviewed). Forks / mirrors / cached copies after the visibility flip are out of our control — that's why the pre-flip audit (task 1) is exhaustive.

## Trade-offs

_Filled by /work (post-gates)._ Cover: why no `--version vX.Y.Z` pin in v1 (deferred); why no homebrew tap / winget / apt repo in v1 (deferred); why the `git clone` flow stays supported forever (backwards compat); why MIT over Apache-2.0 (matches converge reference + personal-tool / no-warranty posture).

## Related

- [Install via one-liner](../how-to/Install-Via-One-Liner) — the user-facing recipe.
- [Dev-machine setup — design](Dev-Machine-Setup-Design) — the orchestrator that the bootstrap hands off to.
- [.harness/PLAN.md](../../.harness/PLAN.md) — full task list, constraints, and verification strategy.
