# Plugins aktivieren

> Eingebaute Plugins sind je Arbeitsbereich aus, bis ein Admin sie unter Einstellungen → Plugins einschaltet; ausgeschaltete Plugins sperren ihre Bausteine und Auslöser, ohne etwas zu löschen.

Gehört zu: [Integrationen](../index/integrationen.md)

- **Standard aus:** Ohne Zeile in `workspace_plugins` ist ein Plugin aus
  ([Migration 0028](./sqlite-workspace-plugins-0028.md)). Nach dem Update
  schaltet ein Admin vorhandene Plugins einmal ein; Aufgaben und Auslöser
  bleiben unverändert.
- **API:** `GET /v1/plugins` → `{items: [{id, enabled, enabledAt}]}` in der
  Reihenfolge von `integrationPlugins` (alle Mitglieder, die Palette braucht
  es). `PUT /v1/plugins/:id {enabled}` nur für Admins (Rollen-Policy,
  Schreibzugriffe); unbekannte Kennung → `404 plugin_not_found`. Danach das
  Echtzeit-Thema `plugins`.
- **Sperre im Backend (Decorator):** `registerIntegrationPlugins` umhüllt jeden
  Executor eines Plugins (`executorEnabledBy`); ausgeschaltet scheitert der
  Baustein mit `pluginDisabled` (Detail `plugin`). `integrationWebhookInterpreters`
  umhüllt die Interpreter (`interpreterEnabledBy`): Auslöser des Plugins
  starten nichts, der Aufruf gilt als angenommen. Feature
  `functions/src/features/plugins/` (Kern), Guard in
  `features/integrations/plugin-activation-guard.ts`.
- **Client:** `PluginsCubit` ist app-weit (`main.dart`); Palette, Leinwand,
  Auslöser-Dialog und Einstellungen lesen ihn. Bis die Liste geladen ist,
  gilt jedes Plugin als aus.
  - Palette: nur Bausteine aktiver Plugins (`PluginNodeModule.pluginId`).
  - Bereits eingebaute Bausteine bleiben bearbeitbar und zeigen „Plugin
    deaktiviert“ (`PluginNodeBody`).
  - Auslöser-Dialog: die Quelle „Shopware“ nur bei aktivem Plugin oder für
    einen bestehenden Shopware-Auslöser.
- **Einstellungen → Plugins** (nur Admins): je Plugin Icon, Titel,
  Beschreibung und Schalter; Ausschalten fragt nach. Ein aktives Plugin
  zeigt seinen Einstellungsbereich (`PluginDescription.settingsBuilder`), bei
  Google Drive die [Google-Konten](./google-konto-verbinden.md). Plugins
  melden sich mit `PluginCatalog.register` an
  (`lib/features/plugins/presentation/plugin_catalog.dart`).
- Der Export eines Arbeitsbereichs enthält den Zustand der Plugins nicht.

## Siehe auch

- [Integrations-Plugins](./integrations-plugins.md)
- [Bausteine von Plugins](./plugin-bausteine.md)
- [Baustein-Fehlercodes](./baustein-fehlercodes.md)
