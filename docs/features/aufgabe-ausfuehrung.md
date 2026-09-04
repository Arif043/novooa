# Aufgabe: Ausfuehrung

> Laufzeitvertrag des Task Builders. Der Feature-Einstieg liegt in
> [`aufgabe.md`](./aufgabe.md).

## Ablauf

`runTaskDefinitionFlow` ist der einzige exportierte Flow. Der Client sendet
`taskId` und optionalen Kontext. Der Flow authentifiziert die Anfrage, laedt die
Aufgabe aus `teams/{teamId}/tasks/{taskId}`, erzeugt einen Run, stellt eine
Cloud-Task ein und gibt sofort dessen ID zurueck.

```ts
input:  { taskId: string; context?: string }
output: { runId: string; taskId: string; status: "queued" }
```

Der Worker fuehrt anschliessend den Graphen topologisch aus. Der
`NodeExecutorRegistry` ordnet jedem implementierten Primitive eine Strategy zu.
Nicht registrierte Primitives werden mit `status: "skipped"` gespeichert.

## Laufzeitgrenzen

`task-workflows.ts` ist ausschließlich der Firebase- und Genkit-Entrypoint.
Er definiert Callable Flows und Task-Queue-Handler, enthält aber keine
Erzeugung konkreter Stores mehr. `CloudTaskRuntimeFactory` verdrahtet hierfür
Firestore, Storage, Benachrichtigungen und die Cloud-Modellinferenz.

Der Prompt-Baustein hängt an dem Domain-Port `PromptExecutor`.
`GenkitPromptExecutor` ist dessen aktuelle Infrastrukturimplementierung und
enthält die Genkit-Aufrufe. Der Workflow-Vertrag kennt nur Request und Resultat
des Prompts, keine Genkit-Typen. Weitere Genkit-gebundene Executor werden nach
demselben Muster herausgelöst, sobald ihre lokale Implementierung entsteht.

## Node-Ergebnisse und Templates

Ein `NodeExecutionResult` enthaelt `nodeId`, `primitive`, `status` und
benannte `outputs`. Der primäre Output heisst `value` und ist typisiert.
Kanten bestimmen ausschliesslich Reihenfolge und Verzweigungen. Ein Knoten
erhält die typisierten `value`-Outputs seiner direkten Vorgänger. Benannte Werte sind ueber den Referenznamen eines Knotens
in Templates erreichbar, zum Beispiel:

```text
{{email.sender}}
{{bericht.displayName}}
{{kunde}}
```

Kanten regeln ausschließlich Reihenfolge und Abhängigkeiten. Der Baustein
`forEach` löst seinen `itemsPointer` gegen den JSON-`value` auf, führt seinen
Unterplan seriell aus und gibt die primären Unterplanergebnisse als JSON-Array
zurück. Unterpläne dürfen in Version 1 weder pausierende Bausteine noch ein
weiteres `forEach` enthalten.

Die letzte lesbare `value`-Ausgabe ist das `finalOutput` des Runs. Die vollständige
Referenz aller Executor-Outputs liegt in
[`../node-executor-outputs.md`](../node-executor-outputs.md).

## Anhaenge und Workspace

Vor dem Executor-Aufruf bereitet der Graph-Runner einen node-spezifischen
Workspace unter `/tmp` vor. Er laedt Dateiversionen aus Storage und
Wissensnotizen aus Firestore. Nach der Ausfuehrung wird der Workspace entfernt.

Prompt-Executoren verwenden die Genkit-Filesystem-Middleware read-only.
Script-Executoren erhalten Dateimetadaten sowie `list_files()` und
`read_file(display_name)`.

## Freigaben

Ein `humanApproval`-Executor beendet den Run mit
`status: "waitingForApproval"`. Der Zwischenstand liegt in `resumeState` am
Run-Dokument. Eine Freigabe ersetzt den Output des wartenden Knotens und setzt
den Graphen fort; eine Ablehnung markiert den Run als `rejected`.

```ts
reviewTaskRunFlow:
input:  { runId: string; decision: "approve" | "reject"; output?: string; formValues?: Record<string, unknown> }
output: { runId: string; status: "queued" | "rejected" }
```

`dialogInput` nutzt dieselbe Pause- und Wiederaufnahme-Logik. Der Executor
speichert Feldname, Datentyp und Optionen in `resumeState`, sendet eine
Benachrichtigung und erwartet beim Bestätigen `formValues`. Das Backend prüft
alle Werte gegen die gespeicherte Definition. Danach erhält der wartende Knoten
einen primären JSON-`value`-Output sowie einen typisierten Output pro Feld. Feldnamen
müssen eindeutige Template-Identifier sein, zum Beispiel `kundennummer`; der
Wert ist dann über `{{formular1.kundennummer}}` verfügbar.

`mediaInput` verwendet denselben Interaktionsvertrag. Während der Ausführung
entscheidet der Nutzer zwischen Bildergalerie und Kamera. Der Client speichert das Bild zuerst
im team-scoped Dateispeicher und übergibt nur dessen `fileId`. Beim Fortsetzen
lädt das Backend die Metadaten selbst, akzeptiert ausschließlich `image/*` und
liefert einen `media`-`value` mit `fileId`, `versionId`, `displayName`,
`contentType` und `sizeBytes`. Der physische Speicherort bleibt in der
Dateiinfrastruktur. Das spätere Dokument-Scannen ist ein eigener
Medienquelltyp; die aktuelle Kamera nimmt unveränderte Bilder auf.

## Aktivitaeten

Der Worker schreibt eine Aktivitaet beim Start, je eine Aktivitaet pro Knoten
und einen abschliessenden Erfolgs- oder Fehlerstatus. Der Flutter-Client startet
nur den Run; die Aktivitaeten-Seite liest diese Firestore-Logs live.

## Lokale Ausfuehrung

Die Flutter-App verwendet auch lokal dieselbe Callable Function wie in der
Produktion:

```bash
npm --prefix functions run serve
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Es gibt keinen separaten lokalen Genkit-Server oder CORS-Proxy.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`aufgabe-executoren.md`](./aufgabe-executoren.md)
- [`../node-executor-outputs.md`](../node-executor-outputs.md)
