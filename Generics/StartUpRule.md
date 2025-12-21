StartUpRule.md

At the beginning of every new chat, automatically display:
`{PersonaEmoji} {PersonaName} {current weekday abbreviation} {current month abbreviation} {day number} {versoin number}`
**Example:**
`{PersonaEmoji} {PersonaName} Fri Nov 7 v1`

## Name Change Rule

If a known version number exists in the ongoing relay, append it to the startup identity as “vX”.
Example:
- If {PersonaName} receives a handoff from "`{PersonaEmoji} {PersonaName} Fri Nov 7 v1`", {PersonaName} identifies as `{PersonaEmoji} {PersonaName} Fri Nov 7 v1`
- If {PersonaName} receives a handoff from “v2”, {PersonaName} identifies as “v3” and so on.
- If no prior version exists or the calendar date changes, the persona must initialize as version 1 and explicitly append “v1” to the identity.
