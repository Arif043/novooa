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

`TaskWorkflow` definiert den frameworkfreien Vertrag fuer Start, Review und
Queue-Ausfuehrung eines Runs. `createGenkitTaskWorkflow` implementiert ihn mit
dem Genkit-Runner. `task-workflow-functions.ts` ist der Firebase-Host: Er
validiert Callable-Payloads, überträgt Firebase-Auth in den Workflow-Kontext
und adaptiert Cloud-Tasks. `CloudTaskRuntimeFactory` verdrahtet hierfür
Firestore, Storage, Benachrichtigungen und die Cloud-Modellinferenz.

Der Builder-Assistent folgt derselben Grenze: `TaskBuilderAssistant` ist der
frameworkfreie Vertrag, `createGenkitTaskBuilderAssistant` erstellt den
Genkit-Responder und `task-builder-assistant-functions.ts` adaptiert die
Firebase-Callable-Function inklusive Auth, Payload-Pruefung und Secret.

`NodeExecutor`, dessen Eingabe und der gemeinsame Laufzeitkontext liegen in
der Domain. Der Vertrag kennt weder Genkit noch einen Anhangs-Workspace.
`NodeExecutorRegistry` bindet Genkit nur fuer `prompt` und
`iterativeRefinement`; auch der Python-Executor fuer `script` erhaelt seinen
temporaeren Workspace erst dort. Der Workflow-Vertrag kennt nur Request,
Resultat und Domain-Ports.

## Node-Ergebnisse und Templates

Ein `NodeExecutionResult` enthaelt `nodeId`, `primitive`, `status` und
benannte `outputs`. Der primäre Output heisst `value` und ist typisiert.
Kanten bestimmen ausschliesslich Reihenfolge und Verzweigungen. Ein Knoten
erhält keine Werte seiner direkten Vorgänger. Benannte Werte werden
ausschliesslich über einen expliziten Template-Ausdruck eingebunden — entweder
flach über den Ausgabenamen eines Bausteins (der primäre Wert ist
ausschliesslich so erreichbar, ein `.value`-Suffix löst nicht mehr auf) oder
per Dot-Pfad für seine benannten Nebenoutputs, zum Beispiel:

```text
{{kunde}}
{{email.sender}}
{{bericht.displayName}}
```

Bausteine mit mehreren fachlichen Ausgabewerten (strukturierte Prompt-Ausgabe,
Dialogeingabe) haben keinen eigenen Ausgabenamen — jedes ihrer Felder ist
stattdessen direkt und flach unter seinem eigenen, graph-weit eindeutigen
Namen erreichbar, ohne umschliessenden Knotennamen.

Kanten regeln ausschließlich Reihenfolge und Abhängigkeiten. Der Baustein
`forEach` löst zuerst sein `itemsTemplate` auf und wendet anschließend seinen
`itemsPointer` auf den resultierenden JSON-Wert an. Er führt seinen
eingebetteten Graphen seriell aus und gibt dessen benannte Ergebnisse als JSON-Array
zurück. Eingebettete Graphen dürfen in Version 1 weder pausierende Bausteine noch ein
weiteres `forEach` enthalten. Diese Regeln und die RFC-6901-JSON-Pointer-
Auswertung liegen in der Domain; der Graph-Runner führt Root-Graph, Bedingungszweig und eingebetteten Graphen über dieselbe Topologie aus. Ein leerer
Pointer bedeutet den vollständigen Wert. Innerhalb jeder Iteration stehen nur
`{{iteration.value}}` und `{{iteration.index}}` im Iterations-Scope bereit.

`documentLookup` fragt genau einen Datensatz über eine Sammlung und sichere
Feldbedingungen ab. Sein primärer Wert ist immer ein für den bestehenden
Wenn-dann-Baustein lesbares Label: `Datensatz gefunden`, `Kein passender
Datensatz gefunden` oder `Suche fehlgeschlagen`. Für ein gefundenes Ergebnis
steht zusätzlich der Datensatz mit seinen fachlichen Feldern als strukturierter Output
bereit. Ein gesonderter „Existiert Dokument?“-Baustein ist daher nicht nötig.
`saveDocument` findet Datensätze ausschließlich über sichtbare Feldbedingungen.
Es aktualisiert alle Treffer und legt ohne Treffer einen neuen Datensatz an. Nicht
konfigurierte Felder eines Treffers bleiben unverändert. Die Version aus diesem Read
wird an den Store weitergegeben, sodass eine parallele Änderung sicher
abgewiesen statt überschrieben wird.

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
einen flachen, typisierten Output pro Feld — ohne umschliessenden Knotennamen
und ohne primären JSON-`value`-Output. Feldnamen müssen graph-weit eindeutige
Template-Identifier sein, zum Beispiel `kundennummer`; der Wert ist dann
direkt über `{{kundennummer}}` verfügbar.

`mediaInput` verwendet denselben Interaktionsvertrag. Während der Ausführung
entscheidet der Nutzer zwischen Bildergalerie und Kamera. Der Client speichert das Bild zuerst
im team-scoped Dateispeicher und übergibt nur dessen `fileId`. Beim Fortsetzen
lädt das Backend die Metadaten selbst, akzeptiert ausschließlich `image/*` und
liefert einen `media`-`value` mit `fileId`, `versionId`, `displayName`,
`contentType` und `sizeBytes`. Der physische Speicherort bleibt in der
Dateiinfrastruktur.

**Dokumentenscanner.** Der Baustein hat die Option `documentScanEnabled`
(Schalter „Als Dokument scannen“ im Task-Builder, Standard aus). Ist sie an und
wählt der Nutzer die Kamera, scannt der Client das Dokument mit automatischer
Randerkennung und Perspektivkorrektur statt eines normalen Fotos: auf Android und
iOS mit einem nativen Plugin, im Browser mit einer eigenen Scanner-Seite. Ergebnis
ist ein JPEG, das wie jedes andere Bild hochgeladen wird; Backend und Vertrag
ändern sich dadurch nicht, das Backend reicht die Option nur durch. Einzelheiten,
Plattformen und Grenzen: [`dokumentscanner.md`](./dokumentscanner.md).

## Aktivitaeten

Der Worker schreibt eine Aktivitaet beim Start, je eine Aktivitaet pro Knoten
und einen abschliessenden Erfolgs- oder Fehlerstatus. Der Flutter-Client startet
nur den Run; die Aktivitaeten-Seite liest diese Firestore-Logs live.

## Lokale Ausfuehrung

Die Web-App verwendet ausschließlich Firebase Functions und Cloud-Dienste. Die
lokale Runtime ist ausschließlich über die native Flutter-App erreichbar. Das
Profil startet ohne Firebase und spricht nur den Loopback-Endpunkt der
Docker-Runtime an:

```bash
flutter run -d macos --dart-define=NOVOOA_RUNTIME=standalone
```

`POST /v1/task-runs` und `POST /v1/task-runs/review` liefern bei einer
fachlich ungueltigen Anfrage `400` mit einem stabilen Failure-Vertrag:

```ts
{ failure: { code: "invalidTaskId", message: "taskId muss ein nicht leerer String sein." } }
```

### Warteschlange und Wiederholungen

Die lokale Runtime führt Runs seriell aus: Ein einzelner `TaskRunQueueWorker`
holt Jobs aus `task_run_jobs` und startet den nächsten erst, wenn der aktuelle
beendet ist.

- **Fehler werden nicht wiederholt.** Scheitert ein Baustein oder wirft die
  Ausführung eine Exception, ist der Run `failed` und der Job endgültig
  `failed`. Eine Wiederholung würde Bausteine mit Nebenwirkungen (E-Mail,
  HTTP-Anfrage, Shopware-Aktion) erneut ausführen.
- **Abstürze werden wiederholt.** Beim Abholen erhält ein Job einen Lease von
  60 Sekunden. Stirbt der Prozess während des Jobs, läuft der Lease ab und der
  Job wird erneut abgeholt. Der Run setzt dann beim letzten abgeschlossenen
  Baustein fort (siehe Schritt-Journal).
- **Begrenzt auf drei Versuche.** Hat ein Job nach Abstürzen alle Versuche
  verbraucht, wird er aufgegeben und der Run mit einer Fehlermeldung als
  `failed` markiert (`failAbandonedTaskRun`).

### Schritt-Journal (Checkpointing)

Die lokale Runtime hält das Ergebnis jedes ausgeführten Bausteins in
`task_run_steps` fest (`TaskRunStepJournal`, SQLite-Adapter
`SQLiteTaskRunStepJournal`). Wird ein Run nach einem Absturz wiederholt, läuft
der Graph wie gewohnt; für jeden Baustein mit gespeichertem Ergebnis wird
dieses übernommen statt ihn erneut auszuführen. Variablen, Verzweigungen und
übersprungene Zweige ergeben sich daraus neu.

- **Schritt-Key = Idempotency-Key:** `runId` plus Schritt-Pfad
  (`TaskRunStepKey`). Top-level ist der Pfad die Node-ID, in Teilgraphen
  kommen Container-Baustein und Aufrufindex dazu, z. B. `schleife:3/mail`
  für die vierte Iteration einer Schleife. Ein Absturz in einer Schleife
  wiederholt bereits abgeschlossene Iterationen nicht.
- Gespeichert werden nur ausgeführte Bausteine. Übersprungene ergeben sich neu,
  wartende Freigaben setzen über den Resume-Zustand fort.
- Nach Erfolg oder Fehler wird das Journal des Runs gelöscht, beim Löschen des
  Runs per Cascade ebenfalls.
- **Verbleibendes Fenster:** Stürzt der Prozess ab, nachdem ein Baustein seinen
  Effekt ausgelöst hat, aber bevor das Ergebnis gespeichert ist, läuft genau
  dieser Baustein erneut.
- Die Cloud verdrahtet kein Journal und verhält sich unverändert.

Die Failure-Codes (`invalidRequest`, `invalidTaskId`,
`invalidReviewDecision`, `invalidFormValues`) liegen in der Domain. HTTP- und
Datasource-Exceptions bleiben Infrastrukturdetails und werden im Client in
eine fachliche Failure uebersetzt.

Das lokale Startprofil bietet Aufgaben mit Texteingabe und Freigabe,
Aktivitäten, Zeitpläne, Dateien sowie Wissensbasis. Aufgaben, Runs,
Aktivitäten, Zeitpläne, Dateien und Notizen werden per lokalem Polling
gelesen. Zeitpläne erzeugen ihre Runs unabhängig von einer geöffneten
Desktop-App im Runtime-Container. Cloud-gebundene Features wie externe
Kommunikationskanäle, Assistenz und Modellprovider werden in diesem Profil
nicht eingebunden.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`aufgabe-executoren.md`](./aufgabe-executoren.md)
- [`../node-executor-outputs.md`](../node-executor-outputs.md)
