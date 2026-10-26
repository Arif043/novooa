# Integrations-Plugins

> Ein Plugin schließt ein externes System an und bringt dafür Bausteine mit; Plugins sind fest eingebaute Module, keine nachladbaren Pakete.

Gehört zu: [Integrationen](../index/integrationen.md)

- Plugins nutzen die allgemeine Schicht: [Verbindungen](../index/verbindungen.md)
  für Zugang und Anmeldung, `OutboundHttpClient` für Aufrufe,
  [Webhooks](../index/webhooks.md) für eingehende Ereignisse — und ergänzen
  nur, was dem System eigen ist.
Ablage:

```
functions/src/features/integrations/
  integration-plugin.ts       Vertrag (id, executors(dependencies), eventTriggers?)
  index.ts                    integrationPlugins, registerIntegrationPlugins
  <system>/                   ein Ordner je Plugin, z. B. shopware/
    <system>-plugin.ts        meldet die Teile an
    domain/, infrastructure/  wie jedes Feature
lib/features/integrations/<system>/   Client: Konfiguration, Widget, Einstellungen
```

Regeln:

- **Der Kern importiert nichts aus `features/integrations`** — ESLint
  (`no-restricted-imports`) erzwingt das. Verdrahtet wird nur in
  `src/shared/local`: `registerIntegrationPlugins(createDefaultNodeExecutorRegistry())`,
  weitergereicht über `TaskGraphRuntime.executorRegistry`.
- Ein neues Plugin wird nur in `integrationPlugins` eingetragen. Es ist je
  Arbeitsbereich aus, bis ein Admin es einschaltet
  ([Plugins aktivieren](./plugin-aktivierung.md)); die Registrierung umhüllt
  Executoren und Interpreter mit der Sperre.
- `executors(dependencies)` bekommt die Dienste der Runtime, die Plugins
  nutzen dürfen (`IntegrationPluginDependencies`, heute
  `googleAccessTokens`); die Komposition reicht sie herein.
- Der Vertrag wächst mit dem nächsten Bedarf (Routen, Worker).
  `eventTriggers` bringen eine Ereignisquelle samt Interpreter; die Komposition
  reicht sie an den Webhook-Empfänger (`integrationWebhookInterpreters`). Im
  Client ist `EventTriggerSource` noch ein geschlossenes Enum (`shopware` fest,
  das Formular liegt im Plugin).
- Client: `registerIntegrationNodes` (`lib/features/integrations/integration_nodes.dart`);
  jedes Plugin meldet sich dort zusätzlich im `PluginCatalog` an (Titel,
  Beschreibung, Icon, optional Einstellungen).

## Siehe auch

- [Bausteine von Plugins](./plugin-bausteine.md)
- [Plugins aktivieren](./plugin-aktivierung.md)
- [Ereignisquellen-Registry](./ereignisquellen-registry.md)
- [Shopware-Plugin](./shopware-plugin.md)
