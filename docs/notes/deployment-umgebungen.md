# Deployment-Umgebungen

> Staging und Produktion bekommen getrennte Firebase-Projekte; eine Hosting-Preview im Produktionsprojekt ist kein Staging, weil sie dieselben Functions, Nutzer, Daten und Push-Tokens nutzt.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md)

| Umgebung | GitHub-Environment | Firebase-Projekt | Ziel |
| --- | --- | --- | --- |
| Staging | `staging` | noch anzulegen | `develop` und PR-Previews |
| Produktion | `production` | `syscat-90bff` | `main` und Hosting `live` |

- Beide Environments existieren; der Hosting-Deploy auf `main` nutzt
  `production`. Der PR-Workflow läuft bis zum Staging-Projekt im
  Produktionsprojekt.
- Secrets je Environment, gleiche Namen: `FCM_WEB_VAPID_KEY` (öffentlicher
  Web-Push-Schlüssel, aus Einheitlichkeit als Secret),
  `FIREBASE_SERVICE_ACCOUNT` (gehört zum Projekt der Umgebung).
- Jeder Hosting-Build bekommt den VAPID-Key als Dart-Define:

  ```yaml
  - run: flutter build web --dart-define=FCM_WEB_VAPID_KEY=${{ secrets.FCM_WEB_VAPID_KEY }}
  ```

  Jobs deklarieren `environment: staging` bzw. `environment: production`.
- Nach Anlage des Staging-Projekts in `.firebaserc`:

  ```json
  {"projects": {"production": "syscat-90bff", "staging": "<staging-project-id>"}}
  ```

Vor dem ersten Staging-Deploy: Firebase-Projekt, Flutter-Konfiguration,
Aliase und Workflows umstellen.

## Siehe auch

- [Microsoft-Graph-App je Umgebung](./microsoft-graph-entra-app.md)
- [Cloud-Inferenzdienst](./cloud-inferenzdienst.md)
