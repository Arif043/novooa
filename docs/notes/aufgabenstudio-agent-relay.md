# Relay des Aufgabenstudio-Agenten

> `localRuntimeTaskBuilderRelay` lässt lokale Runtimes denselben Cloud-Agenten nutzen wie die App, nach Prüfung ihrer Lizenz.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- `onRequest`, höchstens 120 s.
- Prüft die signierte Lizenz (`FirebaseRuntimeRelayLicenseVerifier`), führt
  `runTaskBuilderAssistant` aus und liefert dieselbe Antwort (`answer`,
  `commands`, `knowledgeCommands`).
- Die Runtime kennt die URL über `LOCAL_RUNTIME_TASK_BUILDER_RELAY_URL` (in
  Compose vorbelegt); ohne URL oder Lizenz meldet sie einen lesbaren Fehler.
- Das Relay kennt kein Team (`teamIdForActor` → `null`); die Modellsuche des
  Agenten durchsucht dann nur den globalen Katalog.

## Siehe auch

- [Wo die KI-Agenten laufen](./ki-agenten-betriebsorte.md)
- [Cloud-Endpunkte der Runtime](./runtime-cloud-endpunkte.md)
