# Feature: Integrationen (Plugins)

Verwandt: [`verbindungen.md`](./verbindungen.md) · [`webhooks.md`](./webhooks.md) · [`aufgabe.md`](./aufgabe.md) ·
[`../architecture/betriebsvarianten.md`](../architecture/betriebsvarianten.md)

## Zweck

Ein **Plugin** schließt ein externes System (z. B. Shopware) an novooa an und bringt dafür Bausteine mit. Plugins sind
**fest eingebaute Module**, keine nachladbaren Pakete: Wer sie entwickelt, liefert sie mit der App aus. Sie nutzen die
allgemeine Schicht — [Verbindungen](./verbindungen.md) für Zugang und Anmeldung, den `OutboundHttpClient` für Aufrufe,
[Webhooks](./webhooks.md) für eingehende Ereignisse — und ergänzen nur, was dem System eigen ist.

**Verfügbarkeit:** Standalone. In der Cloud sind die Executoren der Plugins nicht angemeldet; ein Baustein dieser Art wird
dort übersprungen.

## Ablage und Regeln

```
functions/src/features/integrations/
  integration-plugin.ts       Vertrag (id, executors)
  index.ts                    Liste der Plugins, registerIntegrationPlugins
  <system>/                   ein Ordner je Plugin, z. B. shopware/
    <system>-plugin.ts        meldet die Teile des Plugins an
    domain/, infrastructure/  wie jedes Feature
lib/features/integrations/<system>/   Client: Konfiguration, Widget, Einstellungen des Plugins
```

- **Der Kern importiert nichts aus `features/integrations`.** ESLint (`no-restricted-imports` in `eslint.config.mjs`)
  erzwingt das für alle anderen Features. Verdrahtet wird ausschließlich in `src/shared/local` (die Komposition ruft
  `registerIntegrationPlugins(createDefaultNodeExecutorRegistry())` auf und reicht die Registry über
  `TaskGraphRuntime.executorRegistry` an den Runner).
- Ein neues Plugin wird in `integrationPlugins` (`integrations/index.ts`) eingetragen, sonst nirgends im Backend.
- Der Vertrag `IntegrationPlugin` ist klein (`id`, `executors`, optional `eventTriggers`) und wächst mit dem, was das
  nächste Plugin braucht (Routen, Worker). `eventTriggers` bringen eine Ereignisquelle samt Interpreter mit; die
  Komposition reicht die Interpreter an den Webhook-Empfänger (`integrationWebhookInterpreters`). Im Client ist
  `EventTriggerSource` noch ein geschlossenes Enum: der Wert `shopware` steht dort fest, das Formular liegt im Plugin.

## Bausteine eines Plugins

- **Backend:** ein `NodeExecutor`. Das Primitive steht in `workflowPrimitives` (`task.ts`) und sein Konfigurationsschema
  in `nodeConfigSchema` (`task-definition.ts`); das ist je Primitive eine Zeile (siehe
  [`aufgabe.md`](./aufgabe.md) § Bausteine von Plugins).
- **Client:** `PluginNodeConfig` und `PluginNodeModule` im Ordner des Plugins; `registerIntegrationNodes`
  (`lib/features/integrations/integration_nodes.dart`) meldet sie beim Start an.
- Ein Primitive kann mehrere **Aktionen** tragen (`config.action`). Für Nutzer:innen ist jede Aktion ein eigener Baustein
  (Titel, Beschreibung, Formular, Ausgaben, Palette-Eintrag); im Backend gibt es einen Executor, der an die Aktion
  weiterreicht. So kostet eine neue Aktion eine Datei im Plugin und keine Änderung am Kern.
