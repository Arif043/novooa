# Backend-Struktur

## Ziel

Das TypeScript-Backend unter `functions/src` ist **Feature First** organisiert.
Jedes Feature besitzt zwei Schichten: `domain` für reine Geschäftslogik und
`infrastructure` für technische Adapter. Eine `application`-Schicht gibt es
nicht; Use Cases liegen unter `domain/usecases`.

```text
functions/src/
  index.ts
  features/
    assistant/
      domain/
        entities/
        repositories/
        usecases/
      infrastructure/
        functions/
        genkit/
    task_execution/
      domain/
        entities/
        repositories/
        usecases/
      infrastructure/
        firebase/
        genkit/
        local/
        functions/
        functions/
    teams/
      domain/
        entities/
        repositories/
        usecases/
      infrastructure/
        firebase/
        functions/
    scheduling/
      domain/
      infrastructure/
        firebase/
        local/
        functions/
    communication/
      domain/
        entities/
        repositories/
        usecases/
      infrastructure/
        firebase/
        microsoft_graph/
        security/
        sendgrid/
        twilio/
        functions/
    files/
      domain/
      infrastructure/
        firebase/
        local/
    knowledge_base/
      domain/
      infrastructure/
        firebase/
        genkit/
        local/
    machine_learning/
      domain/
      infrastructure/
        firebase/
        local/
    notifications/
      domain/
      infrastructure/
        firebase/
  shared/
    firebase/
    genkit/
    local/
    logging/
```

`shared/` enthält ausschließlich echte Querschnittsthemen ohne fachliche
Zuständigkeit, beispielsweise strukturiertes Logging über
`firebase-functions/logger`. Der Firebase-Export-Root `index.ts` re-exportiert
nur öffentliche Trigger und enthält keine Logik.

## Schichtregeln

- `domain/` importiert weder Firebase, Genkit, Twilio noch Node-/HTTP-SDKs.
- `domain/entities/` enthält reine Typen, Value Objects und Regeln.
- `domain/repositories/` definiert Ports; Implementierungen gehören nie in
  diese Schicht.
- `domain/usecases/` enthält Geschäftsabläufe und hängt nur von Domain-Typen
  und Ports ab.
- `infrastructure/` implementiert Ports und kapselt Firestore, Storage, Cloud
  Tasks, Firebase Functions, Genkit, lokale SQLite-Datenbanken und Provider.
- Callable-, Scheduler- und Webhook-Handler gehören in
  `infrastructure/functions/`. Sie validieren Eingaben, rufen Use Cases auf und
  übersetzen Fehler, enthalten aber keine Geschäftsregeln.
- Jeder öffentliche Handler protokolliert Fehler über `withExceptionLogging`
  bzw. `logException` aus `shared/logging`, bevor er sie weiterwirft oder in
  einen transport-spezifischen Fehler übersetzt.
- Abhängigkeiten zeigen nach innen: Infrastructure darf Domain importieren,
  Domain kennt Infrastructure nicht.
- Nur ein Function-Handler darf als Composition Root Adapter anderer Features
  erzeugen und über deren Ports verdrahten. Laufzeitlogik außerhalb eines
  solchen Handlers importiert keine fremde Infrastructure.

## Feature-Grenzen

| Feature | Verantwortung |
| --- | --- |
| `assistant` | Agentenanfrage, Ausführungskontext, neutrale Responder-Ports und gemeinsame Genkit-/Callable-Adapter |
| `task_execution` | Task-Definitionen, Runs, Graph Runner, Node Executors und Cloud Tasks |
| `teams` | Arbeitsbereich, Mitgliedschaft und Einladungen |
| `scheduling` | Zeit- und Event-Trigger sowie Fälligkeiten |
| `communication` | Nachrichten, Kanäle, Inbox, Trigger sowie Mail-Connectoren und Provider-Sender |
| `files` | Datei-Metadaten, Versionen und Objektzugriff |
| `knowledge_base` | Notizen, Links und Workspace-Auflösung |
| `machine_learning` | Modellkatalog, ONNX-Verträge und spätere Inferenzports |
| `notifications` | In-App-Freigaben und Push-Versand |

Ein Feature darf einen Port eines anderen Features verwenden, nicht dessen
Firebase- oder lokalen Adapter. Gemeinsame technische Hilfen werden erst dann
in `shared/` verschoben, wenn sie mindestens zwei Features ohne fachliche
Kopplung benötigen.

## Migrationsregeln

- Öffentliche Function-Namen und ihre Eingabe-/Ausgabe-Verträge bleiben bei
  einer Strukturmigration unverändert.
- Eine Migration verschiebt immer ein vollständiges Feature: Domain-Modelle,
  Ports, Use Cases und die zugehörigen Adapter.
- Jeder Schritt muss mit `npm --prefix functions run build` und den vorhandenen
  Functions-Tests geprüft werden.
- Dokumente mit Quellpfaden werden im selben Schritt angepasst.

## Migration

Alle bestehenden Backend-Module sind in die Feature-First-Struktur überführt.
Unter `functions/src` verbleiben ausschließlich der Export-Root `index.ts`,
`features/` und technische Querschnittsmodule in `shared/`.
