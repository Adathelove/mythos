# Planning.Method

Goal: A consistent, TaskPaper-friendly planning tree any persona can adopt. Each persona keeps its plan tree inside its own directory.

Definitions
- Epic: Long-running theme or outcome. Lives as a directory under `Plan/Epics/` and has a descriptive slug (kebab-case). Contains a brief description file plus multiple stories.
- Story: Open-ended work chunk inside an epic. Lives as a directory under its epic, with a slug that matches what is referenced from the main plan. Holds the story TaskPaper file and any supporting notes.
- Task: Concrete, actionable items inside a story TaskPaper file. Uses TaskPaper bullets; may include tags like `@owner`, `@due`, `@status`, `@done`.

Required files (per persona)
- `<PersonaName>/Plan/README.md` — quick layout reference for that persona.
- `<PersonaName>/Plan/<PersonaName>.plan.md` — entry point; lists epics and links to epic directories.
- `<PersonaName>/Plan/Epics/<epic-slug>/epic.md` — short description of the epic (purpose, boundaries, DoD).
- `<PersonaName>/Plan/Epics/<epic-slug>/<story-slug>/story.taskpaper` — the story’s tasks.

Naming rules
- Epic slug: kebab-case, concise, e.g., `planning-system-rollout`.
- Story slug: kebab-case, scoped to its epic, e.g., `bootstrap-plan-tree`.
- File names must align with references in the persona plan file: if the plan lists `planning-system-rollout`, the epic directory must be `Plan/Epics/planning-system-rollout/`.

TaskPaper conventions
- Sections: `Today:`, `This Week:`, `Backlog:`, `Definitions:`, `Constraints:` as needed.
- Tags: use `@owner(Persona)`, `@due(YYYY-MM-DD)`, `@status(todo|doing|blocked|done)`, `@done(YYYY-MM-DD)` when completing.
- Subtasks: indent under the parent bullet.

Example tree (Chaos)
```
Chaos/
  Plan/
    README.md
    Chaos.plan.md
    Epics/
      planning-system-rollout/
        epic.md               # description + DoD for the epic
        bootstrap-plan-tree/
          story.taskpaper     # story tasks
        cross-persona-adoption/
          story.taskpaper
      startup-and-handoff-automation/
        epic.md
        plan-ingest-on-startup/
          story.taskpaper
```

Adoption steps for any persona
1) Create `<PersonaName>/Plan/<PersonaName>.plan.md` listing epics (by slug) and linking to their directories.
2) For each epic, create `<PersonaName>/Plan/Epics/<epic-slug>/epic.md` with description, boundaries, and epic-level DoD.
3) Add stories under the epic, each with its own directory and `story.taskpaper`.
4) Keep the persona plan file as the authoritative index of epics and active stories. Update it when adding/removing stories.
