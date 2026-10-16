# Skills importieren

> Skills kommen aus GitHub, ZIP, einem Ordner oder dem skills.sh-Katalog, immer in zwei Schritten: Vorschau, dann Übernehmen.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

App: **Fähigkeiten → Importieren** (Sheet).

| Quelle | Verhalten |
| --- | --- |
| GitHub | `https://github.com/o/r`, `…/tree/<branch>/<pfad>` oder `o/r`; Repository als ZIP von `codeload.github.com` (zählt nicht gegen das REST-Limit 60/h), höchstens 25 MB, nur öffentlich; mehrere Skills je Repository möglich |
| ZIP | ein oder mehrere Skill-Ordner; gemeinsamer Wurzelordner wird abgeschnitten; höchstens 25 MB, entpackt 100 MB (Zip-Bomben-Schutz) |
| Ordner | nur Desktop; ein Skill oder mehrere; höchstens 10 MB / 2000 Dateien |
| Katalog | Suche und Bestenliste von skills.sh |

- **Vorschau** (`POST /v1/skills/imports…`) listet gefundene Skills mit
  Hinweisen und abgelehnten Ordnern; nichts wird gespeichert. Sie liegt 15
  Minuten im Speicher (höchstens 10 gleichzeitig).
- **Übernehmen** (`POST …/commit`) speichert die Auswahl; vergebene Namen
  bekommen `-2`, `-3` …

| Route | Zweck |
| --- | --- |
| `GET /v1/skills` | liest den Skills-Ordner |
| `DELETE /v1/skills/:name` | löscht einen Skill |
| `POST /v1/skills/imports` | Vorschau aus `{github:{url}}`, `{folder:{name,files}}` oder `{skillsSh:{id}}` |
| `POST /v1/skills/imports/archive?name=` | Vorschau aus ZIP (`application/zip`) |
| `POST /v1/skills/imports/:importId/commit` | übernimmt `{names:[…]}` |

## Siehe auch

- [skills.sh-Katalog](./skills-sh-katalog.md)
- [Sicherheit der Fähigkeiten](./skills-sicherheit.md)
