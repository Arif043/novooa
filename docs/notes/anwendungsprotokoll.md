# Anwendungsprotokoll

> Technische Ereignisse landen getrennt von Workflow-Aktivitäten im Anwendungsprotokoll; Client und Runtime schreiben in denselben Port.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Standalone: `ApplicationLogger` speichert strukturierte Info- und
  Fehlerereignisse in `application_logs` und gibt sie zusätzlich als JSON auf
  Docker-Stdout aus.
- Der native Client sendet eigene Ereignisse per
  `POST /v1/application-logs`; die Runtime vergibt ID und Zeitstempel und
  markiert die Quelle als `client`.
- `GET /v1/application-logs` liefert die jüngsten Einträge für
  **Aktivitäten → Protokoll**.
- Cloud: derselbe Port über `FirebaseApplicationLogger` auf Cloud Logging.

## Siehe auch

- [Script-Ausgabe im Protokoll](./script-ausgabe-protokoll.md)
- [Aktivitäten](../features/aktivitaeten.md)
