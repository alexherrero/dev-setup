# Wiki convention

How this project documents itself. This `wiki/` folder is the source of truth for human-and-agent-readable documentation and is mirrored to the repo's GitHub Wiki on every push to the default branch.

This scaffold follows the **six-section documentation taxonomy** — one reader intent per page, never mixed. The taxonomy is authoritative in the crickets [`documentation`](https://github.com/alexherrero/crickets/wiki/crickets-conventions) convention (which converged the older four-mode Diátaxis layout onto this frame); that is the single source for any conflict.

> [!NOTE]
> **Authoring tooling lives in crickets.** Page authoring + the structural lint (`check-wiki.py`) are owned by [`crickets`](https://github.com/alexherrero/crickets)' `wiki-maintenance` plugin. When crickets is paired, its `wiki-maintenance:documenter` sub-agent maintains these pages at phase boundaries (never inline); if it isn't installed, this scaffold stands on its own.

## Two readers, one surface

Every page is written for two audiences: a **human** who needs to understand the system without reading every file, and an **agent** who needs to resume work in a future session without the original context. Tables, diagrams, cross-links, and `file:line` references serve both.

## Six sections

Four sections are always present; two are conditional, added only when the repo earns them.

| Section | Purpose | Reader's question |
|---|---|---|
| 🔧 `how-to/` | Task-focused recipes (onboarding walkthroughs live here, numerically prefixed with a `<!-- mode: tutorial -->` hint) | "How do I X?" |
| 📖 `reference/` | Canonical lookup — tables of flags, keys, exit codes | "What are the flags / keys / codes?" |
| 📐 `designs/` | "Why we built X" design docs; decisions recorded in each design's `## Amendment log` | "What was the plan, why this shape, what did we decide?" |
| 💡 `explanation/` | Intent and rationale | "Why is it this way?" |
| 🏛️ `architecture/` *(conditional)* | System component map | added when a `wiki/architecture.yml` manifest declares it |
| ⚙️ `operational/` *(conditional)* | Run-the-system runbooks | added when the repo's visibility is non-public |

There is **no `decisions/` section and no standalone ADRs** — the ADR model is retired. A non-obvious decision is recorded as a dated entry in the governing design's `## Amendment log` (`**YYYY-MM-DD — <summary>.** <decision>. *Why not the alternative:* … *Re-audit trigger:* …`), reconciled with the design body in one atomic change.

This repo currently populates **How-to · Reference · Designs**; the other sections appear when content (or, for the conditionals, the gate) calls for them.

## The single-section rule

Each page serves exactly one reader intent. A how-to does not contain background narrative; a reference is not a walk-through; an explanation is not a how-to; a design's rationale stays in the design, not scattered across how-tos. When content mixes intents, split the page.

The `.diataxis` marker enables strict-mode `check-wiki.py` enforcement.

## Filename rules

- `CamelCase-With-Dashes.md` (matches GitHub Wiki URL convention).
- **Globally unique across sections** — basename collisions fail the sync workflow loudly.
- Onboarding walkthroughs sort numerically: `01-`, `02-`, etc.

## GitHub Wiki sync

`.github/workflows/wiki-sync.yml` mirrors this folder to the repo's GitHub Wiki on push to the default branch (add / edit / rename / delete). Collisions fail loudly. Gracefully skips if the wiki isn't enabled.

## Full spec

The canonical convention lives in the crickets [`documentation`](https://github.com/alexherrero/crickets/wiki/crickets-conventions) domain.
