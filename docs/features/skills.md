# Feature: Fähigkeiten (Skills)

Verwandt: [`aufgabe.md`](./aufgabe.md) · [`wissensbasis.md`](./wissensbasis.md)

## Zweck

Fähigkeiten (Skills) sind wiederverwendbare Anweisungen mit Progressive
Disclosure. Ein Skill besteht aus einer Markdown-Datei `SKILL.md` mit
YAML-Frontmatter (Name + Kurzbeschreibung) und wird bei Bedarf zur Laufzeit
eines Bausteins in den Modellkontext geladen. Skills sind **kein eigener
Baustein**, sondern werden — analog zur Wissensbasis — an unterstützte
Bausteine gehängt.

## Verantwortlichkeiten

- Team-scoped Metadaten (Titel, Beschreibung, Storage-Pfad) in Firestore
  modellieren.
- SKILL.md-Inhalt in Firebase Storage speichern, damit die Genkit-Skill-
  Middleware den Ordner direkt einbinden kann.
- Angehängte Skills serverseitig beim TaskRun herunterladen, in ein
  temporäres Verzeichnis mounten und der Middleware `skills({skillPaths: …})`
  aus `@genkit-ai/middleware` bereitstellen.
- Verwaltungs-UI unter `/skills` mit Anlegen, Bearbeiten und Löschen.
- Node-Attachment-UI im `PromptWidget` und `IterativeRefinementWidget`.

## Datenmodell

Firestore:

```text
teams/{teamId}/skills/{skillId}
```

Feldübersicht:

| Feld           | Typ         | Bedeutung                                             |
| -------------- | ----------- | ----------------------------------------------------- |
| `title`        | `string`    | Anzeigename                                           |
| `description`  | `string`    | Wann diese Fähigkeit einzusetzen ist                  |
| `storagePath`  | `string`    | Pfad zur SKILL.md in Storage                          |
| `createdAt`    | `timestamp` | Anlagezeitpunkt                                       |
| `updatedAt`    | `timestamp` | Letzte Änderung                                       |

Storage:

```text
teams/{teamId}/skills/{skillId}/SKILL.md
```

Weitere Dateien im Skill-Ordner (z. B. Beispiel-Assets) sind vorgesehen, aber
im MVP nicht über die UI editierbar.

## Node-Anhänge

`PromptNodeConfig` und `IterativeRefinementNodeConfig` implementieren das
neue `SkillAttachmentSupport`-Mixin und speichern eine Liste
`skillAttachments`. Ein Anhang enthält nur Referenzdaten:

```json
{
  "skillId": "skill.1",
  "title": "E-Mails freundlich beantworten",
  "description": "Wann dieser Skill greift.",
  "storagePath": "teams/{teamId}/skills/skill.1/SKILL.md"
}
```

Andere NodeConfigs bleiben unverändert. Weitere Bausteine mit LLM-Anteil
können den Mixin bei Bedarf einbinden.

## Ausführung im TaskRun

Bevor ein `PromptNode` oder `IterativeRefinementNode` das Modell ruft,
bereitet
[`node-attachment-workspace.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-workspace.ts)
einen node-lokalen Ordner unter `/tmp/…/` vor. Für Skills legt
[`skill-workspace.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/skill-workspace.ts)
darin ein `skills/`-Verzeichnis an und lädt pro Anhang die SKILL.md nach
`skills/<slug>/SKILL.md`.

Die Middleware-Kette in
[`node-attachment-genkit.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-genkit.ts)
hängt anschließend `skills({skillPaths: [<skillsDir>]})` an. Genkit spielt
dann automatisch:

1. Ein System-Prompt-Fragment mit der Liste der verfügbaren Skills wird
   injiziert.
2. Das Werkzeug `use_skill` wird registriert. Das Modell ruft es mit dem
   Skill-Namen auf und erhält den SKILL.md-Inhalt zurück — Progressive
   Disclosure.

Das temporäre Verzeichnis wird nach dem Modell-Turn wieder entfernt.

## UI

Route: `/skills`, Drawer-Label: **Fähigkeiten**.

Die Seite zeigt eine Liste vorhandener Skills mit Aktionen zum Bearbeiten
und Löschen. Anlegen und Bearbeiten laufen über einen Dialog mit den Feldern
Name, Kurzbeschreibung und dem SKILL.md-Inhalt. Der Editor ist bewusst
einfach — Fokus im MVP liegt darauf, dass Skills als Attachments benutzbar
sind.

Im NodeInspector der Bausteine `Prompt` und `Iterative Verfeinerung`
erscheint eine zusätzliche Sektion „Fähigkeiten" mit demselben Bottom-Sheet-
Auswahlmuster wie die Wissensbasis.

## Firestore- und Storage-Regeln

Firestore: Team-Mitglieder dürfen die Skill-Metadaten ihres Teams lesen,
anlegen, ändern und löschen. `updatedAt == request.time` wird beim Create
und Update erzwungen.

Storage: `teams/{teamId}/skills/{skillId}/**` ist für Team-Mitglieder les-
und schreibbar; Uploads sind auf 50 MiB begrenzt.

## Definition of Done

- [ ] Skill kann in der UI angelegt, bearbeitet und gelöscht werden.
- [ ] Angehängter Skill erscheint im NodeInspector des Prompt- und
      Iterative-Verfeinerungs-Bausteins.
- [ ] Backend lädt angehängte SKILL.md-Dateien in `<workspace>/skills/`
      herunter und aktiviert die Genkit-Skill-Middleware.
- [ ] `flutter analyze` und `npm --prefix functions run build` sind sauber.
