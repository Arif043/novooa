# Deployment-Umgebungen

> Staging und Produktion bekommen getrennte Firebase-Projekte für die Hintergrunddienste (Lizenz, Relays, Postfächer); eine Runtime zeigt über ihre Cloud-Endpunkte auf genau eines davon.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md)

| Umgebung | Firebase-Projekt | Nutzung |
| --- | --- | --- |
| Staging | noch anzulegen | Test-Runtimes, Entwicklung der Relays |
| Produktion | `syscat-90bff` | Runtimes der Kundschaft |

- Functions werden mit `npm --prefix functions run deploy` je Projekt
  ausgerollt; eine Hosting-Web-App gibt es nicht mehr, die Runtime liefert
  sie selbst aus ([Die Runtime liefert die Web-App aus](./runtime-liefert-web-app.md)).
- Welche Umgebung eine Runtime nutzt, legen ihre
  [Cloud-Endpunkte](./runtime-cloud-endpunkte.md) fest.
- Web-Push braucht den öffentlichen VAPID-Schlüssel des Projekts als
  Dart-Define beim Bauen der Web-App:

  ```bash
  flutter build web --dart-define=FCM_WEB_VAPID_KEY=<öffentlicher Schlüssel>
  ```

- Nach Anlage des Staging-Projekts in `.firebaserc`:

  ```json
  {"projects": {"production": "syscat-90bff", "staging": "<staging-project-id>"}}
  ```

## Siehe auch

- [Microsoft-Graph-App je Umgebung](./microsoft-graph-entra-app.md)
- [Lizenz ausstellen](./lizenz-ausstellen.md)
