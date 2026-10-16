# Dialog „Auslöser hinzufügen“

> Ein gruppierter, scrollbarer Dialog legt einen Zeitplan- oder Ereignis-Auslöser für eine per Dropdown gewählte Aufgabe an.

Gehört zu: [Zeitplan](../index/zeitplan.md)

## Optionen

- **Zeitplan:** einmalig, täglich, wöchentlich (siehe
  [Wiederholungsarten](./zeitplan-wiederholungsarten.md)).
- **Ereignis:** E-Mail, SMS, WhatsApp, Datei erstellt, Neue Dateiversion,
  Datei gelöscht, Webhook.

Zu jedem Ereignis gibt es ein Zielfeld („Wo?“, „Welcher Kanal?“, „Welches
Postfach?“, Standard „Überall“), das ein Auswahl-Sheet öffnet:

- **Datei-Ereignisse:** Verzeichnisbaum mit Schalter „Unterordner
  einbeziehen“ oder einzelne Datei mit Suche. Darunter Chips für Dateitypen;
  bei einer einzelnen Datei entfallen sie.
- **SMS/WhatsApp:** aktive Kanäle des Typs. **E-Mail:** verbundene Postfächer.
  Ohne Kommunikationskanäle in der Betriebsvariante bleibt „Überall“.
- Der Textfilter liegt eingeklappt unter „Weitere Optionen“.

## Verhalten

- Datum und Uhrzeit nutzen die [adaptive Auswahl](./adaptive-datums-zeitauswahl.md).
- Auf kleinen Displays und bei großer Systemschrift ersetzen beschriftete
  Auswahlfelder die Segmentauswahl.
- Speichern verhindert doppelte Übermittlung und behält bei Fehlern die
  Eingaben.
- Meldet die Analyse einen möglichen Zyklus, verlangt der Dialog eine
  Bestätigung (siehe [Schleifenschutz zur Entwurfszeit](./schleifenschutz-entwurfszeit.md)).

## Siehe auch

- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md)
- [Zeitplan-Seite](./zeitplan-seite.md)
