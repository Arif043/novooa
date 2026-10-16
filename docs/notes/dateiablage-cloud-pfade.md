# Dateiablage in der Cloud

> In der Cloud liegen Dateiinhalte team-scoped in Firebase Storage, Metadaten und Versionen in Firestore.

Gehört zu: [Dateien](../index/dateien.md)

Firestore:

```text
teams/{teamId}
teams/{teamId}/members/{uid}
teams/{teamId}/folders/{folderId}
teams/{teamId}/files/{fileId}
teams/{teamId}/files/{fileId}/versions/{versionId}
```

Storage:

```text
teams/{teamId}/files/{fileId}/versions/{versionId}/{fileName}
```

- Aktueller Team-Kontext: `users/{uid}.teamId`. Die Team-ID ist eine
  generierte Dokument-ID, nicht aus der UID abgeleitet; der Arbeitsbereich
  wird automatisch angelegt. Heute ein persönlicher Arbeitsbereich pro
  Nutzer:in, später derselbe Pfad für echte Teams.
- Die UI bekommt den Team-Kontext aus dem Team-Repository.
- Das Datei-Dokument trägt die aktuellen Versionsmetadaten zusätzlich als
  abgeleitete Lesedarstellung; neue Version und diese Felder werden gemeinsam
  geschrieben.
- Die Domain kennt weder Firebase noch Flutter noch den Datei-Picker.

## Siehe auch

- [Copy-on-Write-Versionen](./datei-copy-on-write.md)
- [Sicherheitsregeln der Dateiablage](./datei-sicherheitsregeln.md)
- [Dateiversionen in SQLite (0009)](./sqlite-dateiversionen-normalisiert.md)
