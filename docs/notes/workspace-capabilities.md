# Fähigkeiten je Variante (`WorkspaceCapabilities`)

> Die Oberfläche fragt, was das Backend kann, nicht welche Variante läuft; `WorkspaceCapabilities` ist die einzige Quelle dafür.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

`lib/core/runtime/workspace_capabilities.dart`, einmal aus der `RuntimeKind`
abgeleitet (`forKind`) und als Singleton registriert:

| Fähigkeit | Cloud | Standalone |
| --- | --- | --- |
| `assistant` | ja | ja |
| `dataCollections` | nein | ja |
| `modelCatalog` | nein | ja |
| `push` | ja | nur wenn aktiviert und Plattform unterstützt |
| `messagingChannels` (SMS, WhatsApp) | ja | nein |
| `skills` | nein | ja |
| `employees` | nein | ja |
| `connections` | nein | ja |
| `webhooks` | nein | ja |

- Ersetzte Stellen, die Verfügbarkeit über `serviceLocator.isRegistered<T>()`
  errieten (eine DI-Nebenwirkung als Ersatz für ein Fachflag).
- **Push** berücksichtigt die Plattform: FCM hat keine Windows/Linux-SDKs
  (`firebase_options.dart` wirft dort `UnsupportedError`). `main.dart` liest
  `forKind` vor der Firebase-Initialisierung als reine Funktion; danach lesen
  `FcmBootstrapper` und `FcmForegroundNotificationListener` den Singleton.
- Weiterhin offen: Tab- und Routenstruktur hängen an `bool isStandalone`
  (`root_page.dart`, `app_router.dart`, `root_navigation.dart`,
  `settings_page.dart`, `activity_page.dart`, `auth_form_footer.dart`).
- Weitere Paritätslücken: Nutzerprofile und Team-Verwaltung nur Cloud;
  Lizenz und Anwendungsprotokoll nur Standalone. Der Cloud-Runner injiziert
  bewusst einen `UnavailableDocumentStore`.
  `local_workspace_user_repository.dart` ist getestet, aber nicht registriert.

## Siehe auch

- [Push unter Windows und Linux](./push-windows-linux.md)
- [Betriebsvarianten-Matrix](./betriebsvarianten-matrix.md)
