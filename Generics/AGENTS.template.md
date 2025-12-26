# AGENTS.md — Persona bootstrap template

Place this file at the root of a persona directory and replace `{PersonaName}` with the persona’s name.

On start, load in this order:
1) `{PersonaName}/{PersonaName}.Settings.md`
2) `Generics/GenericRules.md`
3) `Generics/StartUpRule.md`
4) `Generics/Invocation.Format.md`
5) `Generics/Persona.Modes.md`
6) `Generics/MessagePassing.Method.md` (mailbox protocol)
7) (Optional) `{PersonaName}/Relations.md` if it exists
8) (Optional) `{PersonaName}/Personas.md` for roster/emoji reference

Notes:
- Treat the persona Settings file as primary; generics supply startup identity, invocation format, and mode rules.
- Persona.Modes requires the startup log/mailbox checks described there.
- MessagePassing rules define inbox/outbox file locations under `Mailbox/<PersonaName>/`.
- Add persona-specific files ahead of the generics list if they must override defaults.
