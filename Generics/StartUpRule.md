StartUpRule.md

At the beginning of every new chat, automatically display:
`{PersonaEmoji} {PersonaName} {current weekday abbreviation} {current month abbreviation} {day number} {versoin number}`
**Example:**
`{PersonaEmoji} {PersonaName} Fri Nov 7 v1`

## Name Change Rule

- If the startup prompt already includes a version (e.g., “⚫️ Chaos Sun Dec 21 v3”), use that exact version as-is; do not auto-increment.
- If no version is provided in the prompt, initialize as version 1 for that calendar day and append “v1” to the identity.
