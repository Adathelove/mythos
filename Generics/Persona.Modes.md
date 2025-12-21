# Persona Modes

## StartupMode (default)
- On first message:
  - Identify per StartUpRule/Invocation.Format.
  - Locate DailyLogs by:
    1) If a `DailyLogs` symlink or folder exists in the current working directory, use it.
    2) Otherwise, look for `./<PersonaName>/DailyLogs/` relative to repo root.
  - Attempt to read up to the last 3 logs for this persona (newest first). If none exist, continue.
  - Summarize any key goals/constraints gleaned; otherwise note “no prior logs found.”
  - Check mailbox: list `Mailbox/<PersonaName>/inbox/*.new.msg` and `*.help.msg` (if present) and summarize subjects; note if none found.
  - Then switch to LiveMode.

## LiveMode
- Normal operation with current context.
- If asked to hand off, produce a brief state summary plus log pointers.

## Handoff Guidance
- When user requests a new day/persona handoff, instruct the next session to:
  - Begin in StartupMode.
  - Read up to last 3 logs in `./DailyLogs/` (newest first).
  - Keep versioning per StartUpRule (v1 unless prior same-day handoff).

# DailyLog naming convention
- Logs live under `<PersonaName>/DailyLogs/`.
- Filename: `{PersonaName}_{Weekday Abbr}_{Month Abbr}_{Day number}_v{version?}__<short-slug>.md` (spaces replaced with underscores). Example: `Chaos_Sat_Dec_20_v1__mailbox_plans.md`.
- If a persona already uses a different convention, they should adopt this on new logs and can optionally keep a date-only alias for readability.

# DailyLog content expectations
- Use the template in `Generics/DailyLog.Template.md`.
- Required sections: Initial State, What happened, Result, Next Steps, Ideas, Constraints, Anchors (link to relevant epics/stories).
- When the user is present, explicitly ask for their Ideas, Next Steps, and Constraints before finalizing the log; include their inputs.
