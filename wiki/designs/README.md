# Designs

"Why we built X" design docs — the canonical entry point for understanding what was built and why. Each design carries a current-truth body plus an `## Amendment log`: load-bearing decisions are recorded there as dated entries, **not** as standalone ADRs (the ADR model is retired, and there is no `decisions/` section).

Amendment-log entry shape (newest first):

> **YYYY-MM-DD — &lt;summary&gt;.** &lt;decision&gt;. *Why not the alternative:* &lt;why-not&gt;. *Re-audit trigger:* &lt;condition&gt;.

When paired with [`crickets`](https://github.com/alexherrero/crickets), design docs are authored + maintained via its `/design` skill and `wiki-maintenance` plugin; absent crickets, they are hand-maintained here.
