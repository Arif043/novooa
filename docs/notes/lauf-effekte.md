# Folgen eines Laufs (Effekte)

> Bausteine melden neben ihren Werten typisierte Effekte — was sie nach außen bewirkt haben; sie stehen an der Node-Aktivität und erscheinen in der [Seite „Ergebnisse“](./ergebnisse-seite.md).

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

| Art | Inhalt | Quelle |
| --- | --- | --- |
| `fileWritten` | Datei, Version, Name, Typ, Größe, neu oder neue Version | jeder Schreibzugriff auf den Dateispeicher (Datei schreiben, Bild, Sprache, Modell, Teamarbeit, Drive lesen) |
| `messageSent` | Kanal, Empfänger, Betreff | Nachricht senden |
| `notificationSent` | Titel | Benachrichtigung |
| `recordsChanged` | Sammlung (ID), angelegt/geändert/gelöscht, Anzahl, ggf. Datensatz | Datensatz speichern und jede Änderung an Sammlungen |
| `httpRequested` | Methode, Host oder Verbindung, Status | nur der HTTP-Baustein, nur ändernde Methoden (kein `GET`) |
| `externalAction` | Plugin, Aktion, Kennzeichen | Shopware (Bestellstatus, Produkt ändern), Google Drive (speichern) |

- **Aufzeichnung ohne Zutun der Bausteine:** Der Laufkontext umhüllt die
  Ports (`TeamFileStore`, `TaskMessageSender`, `DocumentStore`,
  `TeamNotificationSender`, `OutboundHttpClient`) mit Decorators, die nach
  einem erfolgreichen ändernden Aufruf einen Effekt festhalten. Nur Plugins
  mit eigenem Client melden selbst (`effectLabel` an der Aktion,
  `runContext.effects`).
- **Herkunft:** Jeder Effekt nennt den verursachenden Baustein
  (`sourceNodeId`) und in Schleifen die Runde (`iteration`, ab 0). Ein
  `RunEffectRecorder` je Baustein reicht an den umschließenden weiter: Ein
  Effekt aus einer Schleife steht auch an der Schleife.
- **Fehler:** Ein gescheiterter Baustein behält, was er schon bewirkt hat.
- **Wiederholung:** Übernommene Schritte aus dem Journal bringen ihre Effekte
  mit; nichts wird doppelt gezählt, nichts geht verloren.
- **Datenschutz:** Kein Nachrichtentext, keine HTTP-URL-Pfade, Query,
  Header oder Bodies.
- Gespeichert in `activities.effects_json` (Migration `0030`), ausgeliefert
  mit `GET /v1/activities`; der Client zeigt sie am Baustein unter „Folgen“,
  Datei-Folgen öffnen die [Datei-Detailansicht](./datei-detailansicht.md).
- Code: `run-effect.ts`, `run-effect-recorder.ts`,
  `effect-recording-ports.ts` (Domain), `task-graph-runner.ts`.

## Siehe auch

- [Graph-Schnappschuss eines Laufs](./lauf-graph-schnappschuss.md)
- [Aktivitäten eines Runs](./aktivitaeten-schreiben.md)
