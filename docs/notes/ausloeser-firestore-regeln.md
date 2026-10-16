# Firestore-Regeln und Index für Auslöser

> Team-Mitglieder dürfen Auslöser lesen und schreiben; die Rules validieren Konfiguration, Team-Scope und Aufgabe.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Security Rules erlauben Team-Mitgliedern Lesen, Erstellen, Aktualisieren und
Löschen von `taskTriggers`. Zeitplan-Auslöser werden über `config`,
Ereignis-Auslöser über `eventConfig` validiert, jeweils mit `policy`,
Team-Scope und existierender Aufgabe.

Composite Index für die Worker-Query (`firestore.indexes.json`):

```text
collectionGroup: taskTriggers
enabled ASC, nextRunAt ASC
```

## Siehe auch

- [Worker für fällige Auslöser](./faellige-ausloeser-worker.md)
- [Auslöser-Datenmodell](./ausloeser-datenmodell.md)
