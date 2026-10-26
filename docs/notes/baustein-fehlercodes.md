# Fehlercodes der Bausteine

> Geschäftsfehler eines Bausteins sind `NodeFailure`-Werte mit festem Code und Feldern; der Client übersetzt beides, der technische Text ist sprachneutral.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

Katalog: `nodeFailures` in `functions/src/features/task_execution/domain/entities/node-failures.ts`.
Übersetzung: `ActivityFailureCode` und `activity_failure_explanations.dart`
(Schlüssel `activity_failures.*`).

| Code | Felder | Woher |
| --- | --- | --- |
| `configurationMissing` | `primitive` | Konfiguration passt nicht zum Baustein-Typ |
| `settingMissing` | `setting` (`model`, `modelInputMapping`, `inputFile`, `outputFile`, `audioInput`, `recipient`, `messageBody`, `notificationText`, `mailbox`) | Modell, Datei lesen/schreiben, Sprache zu Text, Nachricht, Benachrichtigung |
| `settingInvalid` | `setting` (`modelInputDuplicate`, `modelParameter`, `documentFilterValue`, `documentFieldValue`, `documentFieldDuplicate`, `jsonPointer`), `name` | Modell, Datensatz suchen/speichern, Für jedes Element |
| `valueTypeMismatch` | `target` (`modelInput`, `documentFilter`, `forEachItems`), `expected`, `name` | Modelleingaben, Feldbedingungen, Für jedes Element |
| `tensorShapeMismatch` | `name` | Tensor-Eingaben |
| `modelOutputInvalid` | `output` (`image`, `audio`) | Datei-Ausgaben eines Modells |
| `triggerMismatch` | `trigger` (`email`, `whatsapp`, `sms`, `telegram`, `instagram`, `webhook`) | E-Mail, Nachricht, Webhook lesen |
| `capabilityUnavailable` | `capability` (`speechSynthesis`, `speechTranscription`, `httpRequests`, `float16Tensors`) | Sprache, HTTP, Tensoren |
| `httpBodyInvalidJson` | – | HTTP-Anfrage |
| `httpStatusFailed` | `status`, `excerpt` | HTTP-Anfrage mit „bei Fehler abbrechen“ |
| `forEachUnsupported` | `reason` (`nestedForEach`, `pausingBlock`) | Für jedes Element |
| `scriptFailed` | – (Konsole an der Failure) | Fehler im Script |
| `scriptOutputInvalid` | `reason`, `name`, `type` | `workflow_output` |
| `scriptPackagesUnavailable` | `reason` (`notInstalled`, `unsupported`), `packages` | Script mit Paketen |
| `pluginDisabled` | `plugin` | Baustein eines deaktivierten Plugins ([Plugins aktivieren](./plugin-aktivierung.md)) |
| `conditionOperandMismatch` | `operator`, `expected`, `received` | [Bedingungen](./bedingter-ablauf-auswertung.md) |
| `unexpected` | – | Exception in einem verschachtelten Plan; nicht übersetzt |

- **Schleifen:** Scheitert eine Runde von „Für jedes Element“, behält die
  Failure ihren Code; `iteration` (Index) kommt dazu, der Client hängt
  „(Durchlauf n)“ an.
- **Modellaufrufe** haben eigene Codes, siehe
  [Fehlerschichtung eines Modellaufrufs](./fehlerschichtung-modellaufruf.md).
- **Bleiben Exceptions:** Fehler der Infrastruktur-Ports (Dateiablage,
  Datensätze, Postfach, Modell, HTTP-Client, Script-Dienst nicht erreichbar).
  Der Runner macht daraus einen gescheiterten Baustein ohne Code. Ebenso
  Invarianten (`mediaReferenceFor`) und die Prüfung von
  Formulardefinitionen (`validateDialogInputDefinition`), die auch der
  Builder nutzt.

## Siehe auch

- [Fehlgeschlagene Bausteine in den Aktivitäten](./baustein-fehler-aktivitaeten.md)
