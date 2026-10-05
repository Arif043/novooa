# Feature: Plugins

Verwandt: [`aufgabe.md`](./aufgabe.md) · [`zeitplan.md`](./zeitplan.md) · [`skills.md`](./skills.md) ·
[`import-export.md`](./import-export.md) · [`../architecture/betriebsvarianten.md`](../architecture/betriebsvarianten.md)

## Zweck

Ein **Plugin** bündelt Erweiterungen, die novooa zur Laufzeit um Funktionen ergänzt — ähnlich wie bei WordPress:

- **Bausteine** für die Palette des Aufgabenstudios,
- **Trigger** (Ereignisse, die eine Aufgabe starten),
- **Einstellungs-Panels** unter *Einstellungen → Plugins*.

Der Admin veröffentlicht Plugins in Firebase; ein Team installiert sie aus dem Katalog (oder per ZIP-Datei).

**Verfügbarkeit:** Standalone (lokale Runtime, `WorkspaceCapabilities.plugins`). Die Cloud hat noch keine
Ausführungsumgebung für Plugin-Code (siehe [Cloud später](#cloud-später)); dort ist das Feature aus, Aufgaben mit
Plugin-Bausteinen überspringen diese mit einem Hinweis.

## Grundidee: deklarative Oberfläche, Code nur im Backend

Flutter kann auf iOS und im Web keinen nachgeladenen Dart-Code ausführen. Deshalb enthält ein Plugin **keinen
Client-Code**. Es beschreibt seine Oberfläche in einem Manifest (`plugin.json`); der Client rendert daraus generische
Bausteine, Felder und Panels. Ausgeführt wird nur der Backend-Teil (`backend/index.mjs`), in der Runtime.

```text
Admin ──publish──▶ Firebase (Storage + Firestore)
                         │  localRuntimePluginsRelay (Lizenz, Rate-Limit)
                         ▼
Runtime: Vorschau ─▶ Signatur prüfen ─▶ Installieren ─▶ <runtime>/plugins/<id>/
Client:  Einstellungen → Plugins (Katalog, Vorschau, Bestätigen)
         Palette, Baustein-Konfiguration, Auslöser-Dialog lesen die Manifeste
```

## Paketformat

Ein ZIP mit:

```text
plugin.json          Manifest (Pflicht)
backend/index.mjs    Einstieg (Pfad über "entry" änderbar)
SIGNATURE            Ed25519-Signatur des Herausgebers (Pflicht für die Installation)
… weitere Dateien    Assets, Hilfsmodule
```

Grenzen: höchstens 200 Dateien, 10 MB entpackt, 15 MB als ZIP; keine Pfade mit `..`, `.git` oder `node_modules`.
Ein gemeinsamer Wurzelordner im ZIP wird abgeschnitten.

### Manifest (`schemaVersion: 1`)

| Feld | Bedeutung |
| --- | --- |
| `id` | Kleinbuchstaben, Ziffern, `-` (2–40 Zeichen); Kennung und Ordnername |
| `version` | `1.2.3` |
| `name`, `description` | Anzeigetexte (deutsch) |
| `entry` | Einstiegsdatei, Standard `backend/index.mjs` |
| `network` | Hostnamen, die das Plugin braucht — **Angabe für den Nutzer, wird nicht erzwungen** (siehe Sicherheit) |
| `primitives[]` | `type`, `label`, `description`, `group`, `icon`, `settings[]` (Felder), `outputs[]` |
| `triggers[]` | `type`, `label`, `description`, `settings[]` |
| `settingsPanels[]` | `id`, `title`, `description`, `icon`, `fields[]` |

**Felder** (`settings`, `fields`): `key`, `label`, `kind` (`text`, `multilineText`, `number`, `choice`, `toggle`,
`template`), `description`, `required`, `secret` (nur Panels), `options` (für `choice`), `defaultValue`.
`template`/`text`/`multilineText` erlauben Template-Ausdrücke wie `{{rechnung.summe}}` und die `#`-Suche.

**Ausgaben** (`outputs`): `name`, `label`, `type` (`string`, `number`, `boolean`, `datetime`, `json`). Der Ausgabewert
`value` ist der primäre Wert (`{{baustein}}`); alle anderen erscheinen als feste Felder (`{{baustein.feld}}`) — wie bei
den eingebauten Bausteinen (siehe [`../node-executor-outputs.md`](../node-executor-outputs.md)).

`icon` nennt ein Symbol beim Namen (`extension`, `bolt`, `mail`, `chat`, `cloud`, `storage`, `description`, `image`,
`code`, `tune`, `notifications`, `search`, … siehe `plugin_icons.dart`); unbekannte Namen zeigen das Plugin-Symbol.

Ein vollständiges Beispiel liegt in [`../../examples/plugins/hallo`](../../examples/plugins/hallo).

### Backend-Vertrag

`backend/index.mjs` exportiert ein Objekt:

```js
export default {
  primitives: {
    // settings: Werte der Felder (Templates bereits aufgelöst); panel: Werte der Einstellungs-Panels
    greet: ({settings, panel}) => ({value: `${panel.greeting}, ${settings.name}!`}),
  },
  triggers: {
    // state: was der Trigger beim letzten Aufruf zurückgegeben hat
    tick: ({settings, panel, state}) => ({
      events: [{context: "Lesbarer Auslösetext", data: {count: 1}}],
      state: 1,
    }),
  },
};
```

- Bausteine liefern die deklarierten Ausgaben; unbekannte Namen oder falsche Typen brechen den Baustein mit
  Fehlermeldung ab.
- Trigger werden von der Runtime regelmäßig abgefragt (Intervall des Trigger-Workers, Standard 30 s; Ereignisse
  sollten also ohne eigenes Warten zurückkommen). Jedes Ereignis startet die Aufgabe des Triggers; `data` ist in der
  Aufgabe als `{{ereignis.feld}}` erreichbar. Höchstens 50 Ereignisse und 100 KB Zustand je Abfrage.
- Der Zustand wird erst gespeichert, nachdem alle Läufe eingereiht sind: scheitert das Einreihen, kommt dasselbe
  Ereignis beim nächsten Durchgang erneut (lieber doppelt als verloren). Plugins sollten Ereignisse deshalb
  idempotent behandeln (z. B. Cursor statt Zähler).
- Geheimnisse (`secret: true`) stehen nur im Backend: `panel.<key>`. Der Client erfährt nur, *ob* eines gesetzt ist.

## Sicherheit

Plugin-Code ist fremder Code in der Runtime. Schutz in zwei Stufen:

1. **Vertrauen durch Signatur.** Installiert wird nur, was der Herausgeber (Admin) mit seinem privaten Ed25519-Schlüssel
   signiert hat. Die Runtime prüft gegen `NOVOOA_PLUGIN_PUBLIC_KEY` (PEM). Ohne Schlüssel wird **nichts**
   installiert; `NOVOOA_PLUGIN_ALLOW_UNSIGNED=true` ist nur für die Entwicklung. Die Signatur deckt alle Dateien
   (Pfad und Inhalt) ab; nachträgliche Änderungen machen das Paket ungültig.
2. **Isolation beim Ausführen.** Jeder Aufruf läuft in einem eigenen Node-Prozess mit dem
   [Permission-Modell](https://nodejs.org/api/permissions.html): nur Lesen im Plugin-Ordner, keine Schreibzugriffe,
   keine Kindprozesse, keine Worker, **leere Umgebung** (keine Geheimnisse der Runtime), 128 MB Heap, 30 s Zeitlimit,
   1 MB Ausgabe. Die Tests (`process-plugin-runner.test.ts`) belegen das mit echten `ERR_ACCESS_DENIED`-Fehlern.

**Grenzen, die man kennen muss:**

- **Netzwerkzugriff lässt sich mit Node nicht beschränken.** Ein signiertes Plugin darf also beliebige Hosts
  erreichen; `network` im Manifest ist eine Auskunft für den Nutzer, keine technische Sperre. Die Vertrauensgrenze ist
  die Signatur — wer den privaten Schlüssel hat, kann Code in jede Runtime bringen. Schlüssel offline halten.
- Plugins erhalten **keinen Zugriff auf Dienste der Runtime** (Dateien, Datensammlungen, Sprachmodelle). Das ist
  bewusst weggelassen; es bräuchte eine schmale RPC-Schnittstelle mit eigener Rechteprüfung.
- Der Katalog selbst ist nur über das Relay erreichbar: `firestore.rules` und `storage.rules` verweigern jeden
  Client-Zugriff auf `pluginCatalog` und `plugins/…` (Standardregel `/{document=**}` bzw. `/{allPaths=**}`).

## Veröffentlichen (Admin)

```bash
cd functions && npm run build
node scripts/plugin-tool.mjs generate-key ./schluessel          # einmalig
node scripts/plugin-tool.mjs pack    ../examples/plugins/hallo --key ./schluessel/plugin-private.pem --out hallo.zip
node scripts/plugin-tool.mjs publish ../examples/plugins/hallo --key ./schluessel/plugin-private.pem --project <firebase-projekt>
```

`publish` legt `plugins/<id>/<version>/package.zip` in Storage und `pluginCatalog/<id>` in Firestore an (braucht
Application-Default-Credentials mit Schreibrechten). Neue Versionen überschreiben nur den Katalogeintrag; ältere Pakete
bleiben abrufbar. Den öffentlichen Schlüssel setzt man in der Runtime als `NOVOOA_PLUGIN_PUBLIC_KEY`.

## Installieren (Team)

*Einstellungen → Plugins*: Katalogeintrag wählen oder ZIP-Datei auswählen → **Vorschau** (Name, Version, was das
Plugin mitbringt, „ersetzt Version x“) → **Installieren**. Erst die Bestätigung schreibt in den Plugin-Ordner;
die Vorschau ist 15 Minuten gültig. Updates ersetzen den Ordner atomar; Plugin-Einstellungen bleiben erhalten.
Deinstallieren löscht Ordner und Einstellungen.

Aufgaben speichern nur `pluginId`, `nodeType` und die Feldwerte — nie Code oder Manifest. Ein Plugin-Update gilt
deshalb sofort für alle Aufgaben. Fehlt das Plugin (Deinstallation, Import auf einem anderen Gerät), bleibt die Aufgabe
bearbeitbar, der Baustein zeigt einen Hinweis und wird beim Ausführen übersprungen. Export/Import von Aufgaben
(siehe [`import-export.md`](./import-export.md)) übernimmt die Bausteine, **nicht** das Plugin.

## Architektur

| Schicht | Ort |
| --- | --- |
| Manifest, Paket, Signatur-Prüfsumme | `functions/src/features/plugins/domain/entities/` |
| Ports (Store, Einstellungen, Katalog, Runner) und Use Cases | `…/plugins/domain/repositories`, `…/usecases` |
| Ordner-Store, Prozess-Runner, Routen `/v1/plugins…` | `…/plugins/infrastructure/local/` |
| Firebase-Katalog und Relay-Function `localRuntimePluginsRelay` | `…/plugins/infrastructure/firebase/` |
| Executor des Bausteins `plugin` | `task_execution/domain/executors/plugin-node-executor.ts` |
| Trigger-Abfrage (`source: "plugin"`) | `plugins/domain/usecases/poll-plugin-triggers.ts`, verdrahtet im Trigger-Worker |
| Executor-Registry (offen für Erweiterung) | `task_execution/infrastructure/genkit/runner/node-executor-registry.ts` |
| Client: Domain, Repositories, Cubits | `lib/features/plugins/` |
| Generischer Baustein | `lib/features/task_builder/…/plugin_node_config.dart`, `plugin_node_widget.dart` |
| Palette | `plugin_baustein_choices.dart` (Gruppen aus den Manifesten) |
| Trigger-Auswahl | `lib/features/schedule/…/plugin_trigger_picker.dart` |

Der Baustein `plugin` ist ein einziger Enum-Wert (`WorkflowPrimitive.plugin` / `"plugin"`); die Vielfalt kommt aus
`nodeType` und dem Manifest. Dadurch braucht ein neues Plugin keine Änderung an Enum, Mapper, Schema oder Executor-Liste.
Die Executor-Registry ist trotzdem offen (`register`/`registerFactory`), damit auch eingebaute Executoren ohne Änderung
des Dispatch-Codes ergänzt werden können.

### Konfiguration der Runtime

| Variable | Bedeutung |
| --- | --- |
| `NOVOOA_PLUGIN_PUBLIC_KEY` | Öffentlicher Ed25519-Schlüssel (PEM, `\n` erlaubt); ohne ihn wird nichts installiert |
| `NOVOOA_PLUGIN_ALLOW_UNSIGNED` | `true` nimmt jedes Paket an — nur Entwicklung |
| `PLUGINS_RELAY_URL` | Relay in Firebase (in `docker-compose.local.yaml` voreingestellt); leer = kein Katalog, ZIP geht weiter |
| `NOVOOA_PLUGINS_DIR` | Verlegt den Plugin-Ordner (Standard `<Runtime-Verzeichnis>/plugins`) |

Plugin-Einstellungen liegen in `<Runtime-Verzeichnis>/plugin-settings/<id>.json` (Rechte `0600`, da sie Geheimnisse
enthalten können), der Trigger-Zustand in `plugin-trigger-state/`. Die Dateien sind nicht Teil des Exports.

## Cloud später

Die Fähigkeit ist als `WorkspaceCapabilities.plugins` angelegt; die Cloud registriert `Unavailable…`-Repositories wie
bei Skills. Für die Cloud fehlt ausschließlich die **Ausführung**: Firebase Functions laden gebündeltes TypeScript und
erlauben kein sicheres Nachladen. Der Weg dorthin: Paket und Einstellungen team-scoped in Firestore/Storage
(`teams/{teamId}/plugins/…`), Ausführung in einem eigenen Cloud-Run-Dienst, der denselben `PluginRunner`-Vertrag erfüllt
(`runPrimitive`, `pollTrigger`). Client, Manifest und Paketformat bleiben unverändert.

## Nicht umgesetzt

- Zugriff der Plugins auf Dienste der Runtime (Dateien, Daten, Sprachmodelle, Nachrichten).
- Erzwungene Netzwerkbeschränkung (`network`).
- KI-Agent: Der Aufgabenstudio-Agent kennt Plugin-Bausteine nicht und legt sie nicht an.
- Typ des primären `value`-Ausgangs in der Oberfläche (zeigt Text); Nebenoutputs sind typisiert.
- Vorschläge für `{{ereignis.…}}` in der `#`-Suche (die Felder bestimmt das Plugin zur Laufzeit).
- Aufräumen des Trigger-Zustands beim Löschen eines Triggers.
- Versionsprüfung `minAppVersion` (Feld wird nur gelesen).
