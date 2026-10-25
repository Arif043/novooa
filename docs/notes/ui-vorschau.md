# UI-Vorschau

> `lib/main_preview.dart` startet die Oberfläche ohne Runtime, Firebase, Lizenz oder Anmeldung, mit denselben Repositories über einen In-Memory-Transport.

Gehört zu: [Architektur](../index/architektur.md)

| Weg | Befehl / Profil |
| --- | --- |
| Terminal | `flutter run -d chrome -t lib/main_preview.dart` |
| VS Code | **novooa UI-Vorschau (Chrome)** oder **(macOS)** in `.vscode/launch.json` |

Alle Repositories sprechen nur `WorkspaceApiClient` (JSON),
`WorkspaceBinaryClient` und `WorkspaceRealtimeChannel`. Die Vorschau nutzt
**denselben DI-Container** und tauscht nur diese Transportwege:

```
configureDependencies(standaloneTransport: previewTransport)
  └─ configureStandaloneDependencies(registerTransport: …)
       ├─ registerHttpWorkspaceTransport      (Produktion)
       └─ registerPreviewWorkspaceTransport   (Vorschau, im Speicher)
```

| Datei | Aufgabe |
| --- | --- |
| `core/di/standalone_transport_registration.dart` | Port + HTTP-Variante |
| `core/di/preview_dependency_configuration.dart` | Vorschau-Variante, Sitzungsereignisse |
| `core/network/preview/in_memory_workspace_store.dart` | Sammlungen und Einzeldokumente |
| `core/network/preview/in_memory_workspace_api_client.dart` | beantwortet `/v1/…` nach REST-Konvention |
| `core/network/preview/in_memory_workspace_transport.dart` | Realtime-Signale, leerer Binärclient |

REST-Konvention: `GET /v1/<name>` → `{items: […]}` (plus Felder eines
Einzeldokuments); `POST` legt mit `id`, `createdAt`, `updatedAt` an;
`PUT /v1/<name>/<id>[/…]` ergänzt/ersetzt, `PUT /v1/<name>` = Einzeldokument;
`DELETE` entfernt; `/v1/license…` immer `active`. Jede Änderung löst das
Realtime-Thema `<name>` aus.

**Grenzen:** flüchtige Daten; keine Fachlogik (Ausführung, Agent außer
[`/mock`](./agent-mock.md), Importe/Exporte liefern leer); „Abmelden“ ohne
Wirkung; Endpunkte mit anderer Antwortform brauchen eine Ausnahme in
`InMemoryWorkspaceApiClient`.

## Siehe auch

- [Runtime-API des nativen Clients](./runtime-client-api.md)
- [Lokaler Start der Runtime](./runtime-lokaler-start.md)
