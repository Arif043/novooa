# Einstellungs-Tab „Kommunikation“

> Der Tab zeigt verbundene Kanäle als Karten; in der Cloud E-Mail, WhatsApp und SMS, in Standalone nur die Outlook-Postfächer der Runtime.

Gehört zu: [Kommunikation](../index/kommunikation.md)

- **Kopfzeile:** Titel, Erklärung, Verbinden-Aktion („Postfach verbinden“
  lokal, „Kanal verbinden“ in der Cloud). Im Leerzustand übernimmt dessen
  Aktion, die Kopfzeile zeigt sie dann nicht doppelt.
- **Karten** im gemeinsamen `ResponsiveCardGrid` (wie Aufgaben, Fähigkeiten,
  Mitarbeiter): Icon, Name, Adresse, „Anbieter · Richtung“, Status als Punkt
  und Text, Kanalmenü. Abgelaufene Anmeldung: Hinweis mit „Neu verbinden“.
- **Zustände:** Laden, Leer (mit Aktion), Fehler ohne Daten („Erneut
  versuchen“), Fehler mit Daten (Hinweis über den Karten), Erfolg.
- **Laden:** ereignisgesteuert über
  `watchWorkspaceChannel('mail-connectors')`, siehe
  [Postfächer in der Runtime](./runtime-postfaecher.md).
- **„Postfach verbinden“ (lokal):** `CommunicationMailboxesSheet` (Fenster am
  Desktop, Bottom Sheet am Handy). Seite 1 listet verbundene Postfächer;
  „Weiteres Postfach verbinden“ gleitet zu Seite 2 mit allen Anbietern. Ohne
  Postfach startet der Dialog bei den Anbietern. Zurück führt zu Seite 1;
  reduzierte Bewegung ohne Animation. Der Dialog liefert den Anbieter, die
  Anmeldung startet der Aufrufer. Cloud: Auswahl der Kanalart als Aktionsliste.
- **Anbieter** in `mail_provider_option.dart` (`mailProviderOptions`: Name,
  Beschreibung, Icon, Verbinden-Aktion); ein neuer wie Gmail ist ein Eintrag.
  Anzeigenamen in `communication_labels.dart`.
- Testnachricht pro Kanal: [Fake-Kanalnachricht](./fake-kanalnachricht.md).

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [Kommunikationskanal-Datenmodell](./kommunikationskanal-datenmodell.md)
