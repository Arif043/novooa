# Fähigkeiten an Bausteinen

> Prompt und Iterative Verfeinerung hängen Skills per Ordnername an; beim Lauf kopiert der Runner nur diese Ordner in den Workspace und bietet sie über die Genkit-Skill-Middleware an.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

`PromptNodeConfig` und `IterativeRefinementNodeConfig` speichern
`skillAttachments`:

```json
{"name": "pdf-verarbeitung", "description": "Verarbeitet PDFs …"}
```

`description` dient nur der Anzeige. Ein Baustein hat entweder eigene
Fähigkeiten **oder** einen [Mitarbeiter](./mitarbeiter.md), nie beides
([Ausschließlichkeit](./mitarbeiter-ausschliesslichkeit.md)).

**Ausführung:**

1. [`skill-workspace.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/skill-workspace.ts)
   kopiert die angehängten Ordner nach `<node-workspace>/skills/<name>/`. Die
   Kopie der `SKILL.md` bekommt den Ordnernamen als `name` und eine einzeilige
   `description` — die Middleware liest den Kopf zeilenweise und versteht
   gefaltete Beschreibungen (`description: >`) nicht. Originale bleiben.
2. [`node-attachment-genkit.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-genkit.ts)
   hängt `skills({skillPaths: [<skillsDir>]})` aus `@genkit-ai/middleware` an:
   ein System-Prompt-Fragment listet die Skills, `use_skill` liefert die
   `SKILL.md` (Progressive Disclosure), weitere Dateien liest das Modell über
   die `filesystem`-Middleware.
3. Fehlt ein Skill, bricht der Baustein ab: „Der Skill „x“ wurde nicht
   gefunden“ (steht in der Aktivität).

`skillContentReader` gehört zur `TaskGraphRuntime`, nicht zu
`TaskRunServices`, weil nur der Runner ihn nutzt. Im Panel erscheint die
Sektion „Fähigkeiten“ mit dem Auswahlmuster der Wissensbasis.

## Siehe auch

- [Anhänge und Workspace](./anhaenge-workspace.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
