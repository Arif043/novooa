# Lebenszyklus eines Runs in der Cloud

> Ein nicht abgeschlossenes `TaskRunDocument` ist die Quelle der Wahrheit für Status, UI, Freigaben und Wiederaufnahme; nach Erfolg wird es gelöscht, der Verlauf bleibt in den Aktivitäten.

Gehört zu: [Architektur](../index/architektur.md)

- Aufgaben liegen unter `teams/{teamId}/tasks/{taskId}` mit `id`, `title`,
  `objective`, `selectedNodeId`, `teamId`, `graph`, `createdAt`, `updatedAt`.
- `TaskRepository` bündelt Entwurfs-Persistenz und Ausführung;
  `FirebaseTaskRepository` speichert in Firestore und ruft die Callable über
  `TaskRunnerDatasource`. Autosave beim Öffnen und nach jeder Mutation.
- Ausführen: Der Client sendet nur `taskId` und optionalen Kontext; die
  Callable lädt die Aufgabe serverseitig, legt
  `teams/{teamId}/taskRuns/{runId}` an und antwortet sofort mit `runId`.
- Danach stellt das Backend einen Cloud Task `{teamId, runId, mode}` ein; der
  Worker lädt den Run und führt ihn aus. Cloud Tasks ersetzt nur Auftrag,
  Retry und Concurrency, nicht den gespeicherten Zustand.
- Freigaben, Formulare und Medien setzen über `reviewTaskRunFlow` anhand von
  `resumeState` fort; Ablehnung → `rejected`.

## Siehe auch

- [Run starten](./run-start.md)
- [Aktivitäten eines Runs](./aktivitaeten-schreiben.md)
- [Grenzen von Cloud Functions](./cloud-functions-grenzen.md)
