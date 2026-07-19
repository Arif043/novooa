# Feature: Mitarbeiter (Subagents)

Verwandt: [`aufgabe.md`](./aufgabe.md) · [`skills.md`](./skills.md)

## Zweck

Ein Mitarbeiter ist ein wiederverwendbarer Subagent: eine feste Rolle mit
Prompt-Vorlage und einer Menge Default-Fähigkeiten. Konzeptionell entspricht
er einem `ai.definePrompt`-Bauplan in Genkit — der Executor rendert die
Vorlage mit der node-spezifischen Anweisung, setzt die Rolle als
System-Prompt und ruft das Modell mit den gemergten Skills als Middleware
auf.

Mitarbeiter sind **kein eigener Baustein**, sondern werden 0..1 an einen
Baustein zugewiesen — heute an `Prompt` und `Iterative Verfeinerung`.

## Verantwortlichkeiten

- Team-scoped Modellierung eines Mitarbeiters mit Rolle, Vorlage und
  Default-Skills.
- Verwaltungs-UI unter `/employees` mit Anlegen, Bearbeiten und Löschen.
- Node-Assignment-UI im `PromptWidget` und `IterativeRefinementWidget`.
- Serverseitig die Rolle als `system`-Prompt setzen, die Vorlage mit
  `{{instruction}}` rendern und die Default-Skills mit den Node-Skills
  mergen, bevor die Genkit-Skill-Middleware sie ausrollt.

## Datenmodell

Firestore:

```text
teams/{teamId}/employees/{employeeId}
```

Feldübersicht:

| Feld             | Typ         | Bedeutung                                              |
| ---------------- | ----------- | ------------------------------------------------------ |
| `name`           | `string`    | Anzeigename                                            |
| `role`           | `string`    | System-Prompt-Text                                     |
| `promptTemplate` | `string`    | User-Prompt-Vorlage mit `{{instruction}}`              |
| `defaultSkills`  | `list<map>` | Eingebettete `SkillAttachment`-Referenzen              |
| `createdAt`      | `timestamp` | Anlagezeitpunkt                                        |
| `updatedAt`      | `timestamp` | Letzte Änderung                                        |

`defaultSkills` sind eingebettete Referenzen — die eigentlichen SKILL.md
liegen weiterhin in Firebase Storage (siehe
[`skills.md`](./skills.md)).

## Node-Zuweisung

`PromptNodeConfig` und `IterativeRefinementNodeConfig` implementieren das
neue `EmployeeAssignmentSupport`-Mixin und halten ein optionales
`employee: EmployeeAttachment?`. Ein Assignment enthält die Daten, die der
Executor braucht, ohne zur Laufzeit noch einmal Firestore anzufragen:

```json
{
  "employeeId": "employee.1",
  "name": "Rezeption",
  "role": "Du bist die Rezeption von novooa. Antworte freundlich, klar…",
  "promptTemplate": "{{instruction}}",
  "defaultSkills": [
    {
      "skillId": "skill.1",
      "title": "E-Mails freundlich beantworten",
      "description": "…",
      "storagePath": "teams/{teamId}/skills/skill.1/SKILL.md"
    }
  ]
}
```

## Ausführung im TaskRun

Vor dem Modell-Turn ermittelt
[`employee-context.ts`](../../functions/src/task-runner/employee-context.ts)
den zugewiesenen Mitarbeiter und mergt seine Default-Skills mit den
node-lokalen Skills. Duplikate (gleiche `skillId`) werden entfernt;
node-spezifische Skills gewinnen. Der gemergte Satz wandert durch den
bestehenden Skill-Workspace nach `<workspace>/skills/…/SKILL.md` und wird
automatisch von der `skills`-Middleware angeboten.

Zusätzlich setzt der Executor `system = employee.role` beim
`ai.generate(…)`-Aufruf und rendert die Prompt-Vorlage: enthält sie
`{{instruction}}`, wird die Baustein-Anweisung dort eingesetzt; sonst wird
sie an die Vorlage angehängt.

Konzeptionell entspricht das dem Muster
`ai.definePrompt({ name, system, prompt, use }).execute(...)`. Wir bleiben
bei `ai.generate(…)`, um Registry-Kollisionen bei parallelen Runs zu
vermeiden — die Semantik ist identisch.

## UI

Route: `/employees`, Drawer-Label: **Mitarbeiter**.

Die Verwaltungsseite zeigt eine Liste vorhandener Mitarbeiter mit Aktionen
zum Bearbeiten und Löschen. Der Editor bietet:

- Name
- Rolle (System-Prompt)
- Prompt-Vorlage (mit `{{instruction}}`)
- Auswahl der Default-Fähigkeiten aus den vorhandenen Team-Skills.

Im NodeInspector der Bausteine `Prompt` und `Iterative Verfeinerung`
erscheint eine neue Sektion „Mitarbeiter" mit einem 0..1-Slot — inklusive
Anzeige, wie viele Default-Skills der Mitarbeiter mitbringt.

## Firestore-Regeln

`teams/{teamId}/employees/{employeeId}` ist für Team-Mitglieder les- und
schreibbar; `updatedAt == request.time` wird beim Create und Update
erzwungen.

## Definition of Done

- [ ] Mitarbeiter kann in der UI angelegt, bearbeitet und gelöscht werden.
- [ ] Default-Skills werden aus vorhandenen Team-Skills gewählt und
      gespeichert.
- [ ] Zugewiesener Mitarbeiter erscheint im NodeInspector des Prompt- und
      Iterative-Verfeinerungs-Bausteins.
- [ ] Backend setzt die Rolle als `system`-Prompt und rendert die
      Vorlage mit `{{instruction}}`.
- [ ] Backend merget Node- und Default-Skills und rollt sie über die
      Genkit-Skill-Middleware aus.
- [ ] `flutter analyze` und `npm --prefix functions run build` sind sauber.
