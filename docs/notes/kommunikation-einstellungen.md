# Einstellungs-Tab „Kommunikation“

> Der Tab zeigt die verbundenen Outlook-Postfächer der Runtime als Karten.

Gehört zu: [Kommunikation](../index/kommunikation.md)

- **Kopfzeile:** Titel, Erklärung, Verbinden-Aktion („Postfach verbinden“).
  Im Leerzustand übernimmt dessen Aktion, die Kopfzeile zeigt sie dann nicht
  doppelt.
- **Karten** im gemeinsamen `ResponsiveCardGrid` (wie Aufgaben, Fähigkeiten,
  Mitarbeiter): Icon, Name, Adresse, „Anbieter · Richtung“, Status als Punkt
  und Text. Abgelaufene Anmeldung: Hinweis mit „Neu verbinden“.
- **Zustände:** Laden, Leer (mit Aktion), Fehler ohne Daten („Erneut
  versuchen“), Fehler mit Daten (Hinweis über den Karten), Erfolg.
- **Laden:** ereignisgesteuert über
  `watchWorkspaceChannel('mail-connectors')`, siehe
  [Postfächer in der Runtime](./runtime-postfaecher.md).
- **„Postfach verbinden“:** `CommunicationMailboxesSheet` (Fenster am
  Desktop, Bottom Sheet am Handy). Seite 1 listet verbundene Postfächer;
  „Weiteres Postfach verbinden“ gleitet zu Seite 2 mit allen Anbietern. Ohne
  Postfach startet der Dialog bei den Anbietern. Zurück führt zu Seite 1;
  reduzierte Bewegung ohne Animation. Der Dialog liefert den Anbieter, die
  Anmeldung startet der Aufrufer.
- **Anbieter** in `mail_provider_option.dart` (`mailProviderOptions`: Name,
  Beschreibung, Icon, Verbinden-Aktion); ein neuer wie Gmail ist ein Eintrag.
  Anzeigenamen in `communication_labels.dart`.

## Siehe auch

- [Mail-Connectoren](./mail-connectoren.md)
- [Postfächer in der Runtime](./runtime-postfaecher.md)
