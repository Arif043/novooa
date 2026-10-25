# Firestore-Pfade der Hintergrunddienste

> Firestore hält nur noch Daten der Hintergrunddienste: Lizenzen, Wake-ups, Postfächer und Relay-Warteschlangen; Fachdaten der Kundschaft liegen in der Runtime.

Gehört zu: [Architektur](../index/architektur.md)

```text
licenses/{tokenHash}
localRuntimeWakeups/{licenseId}
localRuntimeMailRelayEvents/{eventId}
localRuntimeMailRelayDeadLetters/{eventId}
teams/{workspaceId}/mailConnectors/{connectorId}
teams/{workspaceId}/mailConnectorCredentials/{connectorId}
teams/{workspaceId}/mailConnectorAuthorizations/{authorizationId}
modelCatalog/{modelId}
skillsRelayRateLimits/{sha256(licenseId)}
```

- `teams/{workspaceId}` ist hier nur der Namensraum des Arbeitsbereichs einer
  Lizenz; Postfächer gehören immer zu genau einer Runtime-Lizenz
  (`runtimeLicenseId`).
- Clients lesen nur `localRuntimeWakeups` (eigene Lizenz) und `modelCatalog`;
  alles andere schreiben und lesen die Functions über das Admin SDK
  ([Regelprüfung der Runtime-Wake-ups](./runtime-wakeup-regelpruefung.md)).
- Projekt `syscat-90bff`, Datenbank `(default)`, `FIRESTORE_NATIVE`,
  `europe-west3`.

## Siehe auch

- [Firebase-Wake-up der Runtime](./runtime-firebase-wakeup.md)
- [Mail-Relay und Dead-Letter-Queue](./mail-relay-dead-letter.md)
