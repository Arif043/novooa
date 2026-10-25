# Client-Paket `novooa_runtime_client`

> Verbindung, Anmeldung, HTTP und Echtzeit zur Runtime liegen in einem privaten Dart-Paket, das das offizielle Frontend und Kunden-Dashboards gemeinsam nutzen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md) · [Architektur](../index/architektur.md)

- **Ort:** `packages/novooa_runtime_client/` im syscat2-Repo, `publish_to: none`.
  Die App bindet es per `path` ein, Dashboards per Git mit `path` und Tag:

  ```yaml
  novooa_runtime_client:
    git:
      url: git@github.com:<org>/syscat2.git
      path: packages/novooa_runtime_client
      ref: novooa-runtime-client-v0.1.0
  ```

- **Inhalt (headless, ohne UI und Texte):**
  - Adresse: `RuntimeEndpoint` und `RuntimeProfile`.
  - Verbindung: `HttpWorkspaceApiClient` und `SessionAwareWorkspaceApiClient`.
  - Binär- und Echtzeit-Zugriff: `WorkspaceBinaryClient` und `WorkspaceRealtimeChannel`.
  - Token-Speicher: `createRuntimeCredentialStore()`.
  - Anmeldung, Einladung, Notzugang und Ersteinrichtung.
  - Der Ablauf dazu als `RuntimeConnectionCubit`.
- **Fehler** kommen als `RuntimeAccessFailure` (Art, Status, Detail). Die App
  formuliert sie an einer Stelle (`lib/core/runtime/runtime_access_failure_text.dart`),
  ein Dashboard in seiner eigenen.
- **In der App bleiben** die Formulare der Anmeldung und Einrichtung, die
  UI-Vorschau (`InMemoryWorkspaceApiClient` implementiert die Schnittstelle
  des Pakets) und alle fachlichen Repositories.
- **Versionen:** SemVer in `pubspec.yaml` und `CHANGELOG.md`, Git-Tag
  `novooa-runtime-client-v<version>`. Ändert sich ein Vertrag der Runtime,
  den das Paket nutzt (Login, Sitzung, Realtime-Ticket), gehören Paket,
  Changelog und neuer Tag in denselben Commit.

## Siehe auch

- [Runtime-Sitzungen](./runtime-sitzungen.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
- [Kunden-Dashboards](./kunden-dashboards.md)
