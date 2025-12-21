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
