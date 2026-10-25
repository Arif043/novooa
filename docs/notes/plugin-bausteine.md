# Bausteine von Plugins

> Ein Plugin bringt Bausteine mit, ohne den Kern zu ändern: im Backend ein registrierter `NodeExecutor`, im Client eine `PluginNodeConfig` plus `PluginNodeModule`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

**Backend:** `NodeExecutor`, angemeldet an der `NodeExecutorRegistry`
(`createDefaultNodeExecutorRegistry`). Die Konfiguration steht noch in
`workflowPrimitives` und `nodeConfigSchema` (`task-definition.ts`), je
Primitive eine Zeile.

**Client:**

- Konfiguration erbt von `PluginNodeConfig`
  (`task_builder/domain/entities/plugin_node_config.dart`) und liegt im
  Plugin-Ordner (`NodeConfig` ist bewusst nicht `sealed`). Sie liefert
  `typeId` (Kennung in Palette und Registry), `documentPrimitive` (Name im
  Backend und Dokument; Vorgabe `typeId`, mehrere Aktionen dürfen sich einen
  teilen), `toDocument()`, `primaryOutputType`, `secondaryOutputs`
  (Name → Typ).
- `TaskBuilderCubit.updatePluginNode` ändert sie ohne eigene Mutation.
- `PluginNodeModule` (`task_builder/presentation/plugin_node_module.dart`)
  bündelt Titel, Beschreibung, Gruppe und Icon der Palette,
  Anfangskonfiguration, `fromDocument` und Widget. Titel und Beschreibung
  sind Funktionen (`'schlüssel'.tr`), weil die Plugins sich vor dem Laden
  der Übersetzungen anmelden;
  `PluginNodeModules.register` meldet es beim Start an. Mapper, Palette,
  Canvas und Ausgaben-Anzeige bleiben unverändert.
- Karte und Konfigurationsfenster zeigen Namen und Icon des Moduls statt
  des allgemeinen „Baustein“ (`NodeConfigLabels` in
  `task_builder/presentation/cubits/node_config_labels.dart`).
- Texte eines Plugins stehen wie alle UI-Texte in `en`, `de` und `tr`; die
  Beschreibungen seiner Aktionen tragen nur Schlüssel (`titleKey`,
  `labelKey`, …), übersetzt wird im Widget.

**Aktionen:** Ein Primitive kann mehrere Aktionen tragen (`config.action`).
Für Nutzer:innen ist jede Aktion ein eigener Baustein (Titel, Beschreibung,
Formular, Ausgaben, Palette-Eintrag); im Backend reicht ein Executor an die
Aktion weiter. Eine neue Aktion kostet so eine Datei im Plugin, keine
Änderung am Kern.

Der Kern kennt Plugin-Bausteine nur als `WorkflowPrimitive.plugin`. Ein
gespeicherter Baustein ohne angemeldetes Plugin wird beim Laden zur
Texteingabe; die Leinwand zeigt „Dieser Baustein ist nicht verfügbar“.
Beispiel: `test/features/task_builder/plugin_node_test.dart`.

## Siehe auch

- [Integrations-Plugins](./integrations-plugins.md)
- [Bausteinkatalog](./bausteinkatalog.md)
