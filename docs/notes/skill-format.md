# Skill-Format (agentskills.io)

> Ein Skill ist ein Ordner mit `SKILL.md` (YAML-Kopf mit `name` und `description`, danach Markdown) und optional `scripts/`, `references/`, `assets/`.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

Standard: [agentskills.io](https://agentskills.io/specification), mit
Progressive Disclosure.

| Feld | Regel |
| --- | --- |
| `name` | 1–64 Zeichen, `a-z`, `0-9`, Bindestriche; nicht am Rand, nicht doppelt; == Ordnername |
| `description` | Pflicht, 1–1024 Zeichen: was der Skill tut und wann er gilt |
| `license` | optional |
| `compatibility` | optional, ≤ 500 Zeichen |
| `metadata` | optional, String-Map |
| `allowed-tools` | optional, experimentell — gelesen, nicht ausgewertet |

Beim Import wird korrigiert statt abgelehnt: Ein fehlender oder ungültiger
`name` wird aus dem Ordnernamen abgeleitet („Next.js Development“ →
`next-js-development`) und in die gespeicherte `SKILL.md` geschrieben.
Abgelehnt wird nur ohne `SKILL.md` oder `description` und bei verletzten
Grenzen (höchstens 200 Dateien und 10 MB je Skill, keine Pfade mit `..`).
`.git/`, `node_modules/` und `__MACOSX/` werden nicht übernommen.

## Siehe auch

- [Skills-Ordner](./skills-ordner.md)
- [Skills importieren](./skills-import.md)
