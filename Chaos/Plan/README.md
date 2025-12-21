# Plan directory (Chaos)

Layout
- `Chaos/Plan/Chaos.plan.md` — persona entry point listing epics and linking to epic dirs (relative: `Epics/...`).
- `Chaos/Plan/Epics/<epic-slug>/epic.md` — epic description and DoD.
- `Chaos/Plan/Epics/<epic-slug>/<story-slug>/story.taskpaper` — story tasks.

Conventions
- Slugs are kebab-case and must match references in the persona plan file.
- TaskPaper tags: `@owner(Persona)`, `@due(YYYY-MM-DD)`, `@status(todo|doing|blocked|done)`, `@done(YYYY-MM-DD)`.
- Stories hold actionable tasks; epics describe scope and success; persona plan stays the authoritative index.
