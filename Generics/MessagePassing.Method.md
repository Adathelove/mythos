# MessagePassing.Method

Goal: Lightweight, file-based mailbox so personas can leave, read, and reply to tasks/messages without shared services.

Mailbox layout
- Root: `Mailbox/`
- Per-persona folder: `Mailbox/<PersonaName>/`
- Standard subfolders per persona: `inbox/`, `outbox/`, `anybox/`
  - `inbox/` receives messages for that persona.
  - `outbox/` optional copy/record of sent messages.
  - `anybox/` contains symlinks to other personas’ inboxes to drop messages easily.
- Message files live inside `inbox/` (and optionally `outbox/`). Filenames carry a short slug and status tag.
- Status via filename suffix: `.<status>.msg` where status ∈ {new, in-progress, done, declined, help}
- Replies use the same file (append) or a sibling `-replyN` file; see reply workflow.

Message schema (YAML-ish header + free body)
```
from: <persona|user>
to: <persona>
subject: <short slug>
story: <optional epic/story ref>
status: new|in-progress|done|declined|help
refs: [optional links or file paths]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
Body text / task detail / context
```

Lifecycle
- Write: create `Mailbox/<to>/inbox/<subject>.new.msg` with header+body.
- Claim: recipient renames to `.in-progress.msg` and appends notes.
- Complete: rename to `.done.msg` and append result.
- Decline/help: rename to `.declined.msg` or `.help.msg` with reason.
- Replies: append under `--- reply YYYY-MM-DD by <persona> ---` or create `-reply1.new.msg` if cleaner threading is needed.

Startup checks (per Persona.Modes)
- On StartupMode, if `Mailbox/<PersonaName>/` exists, list unread (`inbox/*.new.msg`) and summarize subjects; mention any `*.help.msg` needing attention.
- When a user asks “inbox,” interpret as mailbox inbox unless context clearly indicates email.
- Announce any replies written during the session.

Tags (within body or header)
- `@story(epic/story)` to tie into Plan tree.
- `@owner(Persona)` for accountability when multiple recipients share a mailbox.
- `@due(YYYY-MM-DD)` if time-bound.

Conventions
- Keep slugs kebab-case and short, e.g., `plan-ingest-ask.new.msg`.
- One primary recipient per file; CC/CC-like notes can go in body.
- If a recipient is missing, drop to `Mailbox/Chaos/` for triage.

Notes
- This is intentionally CLI- and git-friendly (plain text, rename for state).
- Avoid storing sensitive secrets; mailboxes are in-repo unless explicitly moved to a private path.
- Setup helper: `Chaos/mailbox-sync.sh` builds inbox/outbox/anybox for all personas listed in `Chaos/Phyle.txt`.
- Send helper: `core/mailbox-send.sh` writes a `*.new.msg` into a recipient inbox; personas may symlink it locally (e.g., `Chaos/mailbox-send.sh -> ../core/mailbox-send.sh`).
