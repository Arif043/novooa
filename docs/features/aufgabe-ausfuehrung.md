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

## Node-Ergebnisse und Templates

Ein `NodeExecutionResult` enthaelt `nodeId`, `primitive`, `status` und
benannte `outputs`. Der regulaere Kantenfluss verwendet ausschliesslich den
String-Output `text`. Benannte Werte sind ueber den Referenznamen eines Knotens
in Templates erreichbar, zum Beispiel:

```text
{{email.sender}}
{{bericht.storagePath}}
{{kunde}}
```

Der letzte nichtleere `text`-Output ist das `finalOutput` des Runs. Die vollstaendige
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
input:  { runId: string; decision: "approve" | "reject"; output?: string }
output: { runId: string; status: "queued" | "rejected" }
```

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
