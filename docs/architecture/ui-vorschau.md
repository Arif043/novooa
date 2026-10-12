# UI-Vorschau (ohne Backend und Lizenz)

Die Oberfläche lässt sich bauen und gestalten, ohne dass Runtime, Firebase,
Lizenz oder Anmeldung existieren.

## Start

| Weg | Befehl / Profil |
| --- | --- |
| Terminal | `flutter run -d chrome -t lib/main_preview.dart` |
| VS Code | Profil **novooa UI-Vorschau (Chrome)** oder **(macOS)** in `.vscode/launch.json` |

Einstiegspunkt: `lib/main_preview.dart`. Er initialisiert weder Firebase noch das
Verbindungs-Gate und zeigt direkt die App (Standalone-Oberfläche).

## Aufbau

Alle Standalone-Repositories sprechen nur mit drei Schnittstellen:
`WorkspaceApiClient` (JSON), `WorkspaceBinaryClient` und
`WorkspaceRealtimeChannel`. Die Vorschau nutzt **denselben DI-Container** wie
Standalone und tauscht ausschließlich diese Transportwege aus:

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
| `core/network/preview/in_memory_workspace_api_client.dart` | Beantwortet `/v1/…` nach REST-Konvention |
| `core/network/preview/in_memory_workspace_transport.dart` | Realtime-Signale, leerer Binärclient |

## REST-Konvention der Vorschau

- `GET /v1/<name>` → `{items: […]}` (plus Felder eines Einzeldokuments)
- `POST /v1/<name>` → legt ein Dokument mit `id`, `createdAt`, `updatedAt` an
- `PUT /v1/<name>/<id>[/…]` → ergänzt/ersetzt das Dokument; `PUT /v1/<name>` → Einzeldokument
- `DELETE /v1/<name>/<id>` → entfernt das Dokument
- `/v1/license…` → immer `active`
- Jede Änderung löst das Realtime-Topic `<name>` aus, offene Listen aktualisieren sich.

## Grenzen

- Daten sind flüchtig: Neustart = leer.
- Keine Fachlogik: Aufgaben-Ausführung, KI-Agent (außer `/mock`), Importe und
  Exporte liefern leere Ergebnisse.
- „Abmelden“ im Menü hat keine Wirkung (kein Verbindungs-Gate).
- Neue Endpunkte mit anderer Antwortform als in der Konvention brauchen eine
  Ausnahme in `InMemoryWorkspaceApiClient`.
