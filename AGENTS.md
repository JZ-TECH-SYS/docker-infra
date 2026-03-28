# Agent Instructions

This repository may also contain supplemental instructions in `.github/AGENTS.md`; when present, treat them as additional repository context.

## Working Rules
- Read `.claude/napkin.md` at the start of each session and keep it curated with recurring, high-value guidance only.
- For UI work, read `.interface-design/system.md` first and keep new components aligned with it.
- Preserve the existing architecture, naming, and folder layout; prefer minimal diffs over rewrites.
- Match the current stack detected from the repository manifests instead of introducing new patterns or dependencies by default.
- Validate only the affected surface first (`api/`, `web/`, `app/`, or the touched package), then widen scope if needed.
- Do not create or rewrite documentation unless the task explicitly asks for it.
