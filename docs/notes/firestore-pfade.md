# Firestore-Pfade

> Übersicht der Firestore-Collections; fast alles ist unter `teams/{teamId}` team-scoped.

Gehört zu: [Architektur](../index/architektur.md)

```text
users/{uid}
users/{uid}/notifications/{notificationId}
users/{uid}/settings/aiModel
users/{uid}/secrets/aiProvider
teams/{teamId}
teams/{teamId}/members/{uid}
teams/{teamId}/tasks/{taskId}
teams/{teamId}/taskTriggers/{triggerId}
teams/{teamId}/taskRuns/{runId}
teams/{teamId}/activities/{activityId}
teams/{teamId}/communicationChannels/{channelId}
teams/{teamId}/mailConnectors/{connectorId}
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}/messages/{messageId}
teams/{teamId}/folders/{folderId}
teams/{teamId}/files/{fileId}/versions/{versionId}
teams/{teamId}/knowledgeBases/{knowledgeBaseId}/notes/{noteId}
modelCatalog/{modelId}
licenses/{tokenHash}
localRuntimeWakeups/{licenseId}
skillsRelayRateLimits/{sha256(licenseId)}
```

Storage: `teams/{teamId}/files/{fileId}/versions/{versionId}/{fileName}`.
Modelldateien liegen nicht in Storage, sondern im
[globalen Modellspeicher](./globaler-modellspeicher.md).

Projekt `syscat-90bff`, Datenbank `(default)`, `FIRESTORE_NATIVE`,
`europe-west3`.

## Siehe auch

- [Firestore-Regeln für Nutzerdaten](./firestore-regeln-nutzerdaten.md)
- [Dateiablage in der Cloud](./dateiablage-cloud-pfade.md)
