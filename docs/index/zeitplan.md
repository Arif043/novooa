# Zeitplan

> Zeit- und ereignisgesteuerte Auslöser legen fest, **wann** eine Aufgabe läuft, ohne den Workflow selbst zu ändern.

Umgesetzt sind zeitbasierte Auslöser, Ereignis-Auslöser für Dateien und
Webhooks (lokale Runtime) sowie der Twilio-Eingang für SMS und WhatsApp.

## Datenmodell

- [Auslöser-Datenmodell](../notes/ausloeser-datenmodell.md)
- [Zeitplan-Wiederholungsarten](../notes/zeitplan-wiederholungsarten.md)
- [Ereignisziel eines Auslösers](../notes/ausloeser-ereignisziel.md)
- [Ereignisquellen-Registry](../notes/ereignisquellen-registry.md)
- [Materialisierte nächste Ausführung](../notes/naechste-ausfuehrung-materialisiert.md)
- [Auslöser in der Standalone-Datenbank](../notes/ausloeser-standalone-aufgabenbezug.md)
- [Firestore-Regeln und Index für Auslöser](../notes/ausloeser-firestore-regeln.md)

## Ausführung

- [Worker für fällige Auslöser](../notes/faellige-ausloeser-worker.md)
- [Zeitplan-Worker der Runtime](../notes/runtime-zeitplan-worker.md)
- [Datei-Ereignisse lösen Aufgaben aus](../notes/datei-ereignisse-dispatch.md)
- [Schleifenschutz zur Laufzeit](../notes/schleifenschutz-laufzeit.md)
- [Schleifenschutz zur Entwurfszeit](../notes/schleifenschutz-entwurfszeit.md)

## Kanäle und Nachrichten

- [Kommunikationskanal-Datenmodell](../notes/kommunikationskanal-datenmodell.md)
- [Twilio-Webhook](../notes/twilio-webhook.md)
- [Normalisierte Kanal-Ereignistypen](../notes/kanal-ereignistypen.md)
- [Eingehende Nachrichten (Inbox)](../notes/eingangs-nachrichten-inbox.md)
- [E-Mail-Auslöser über Mail-Connector](../notes/email-ausloeser-mail-connector.md)
- [Fake-Kanalnachricht für Tests](../notes/fake-kanalnachricht.md)

## Oberfläche

- [Zeitplan-Seite](../notes/zeitplan-seite.md)
- [Dialog „Auslöser hinzufügen“](../notes/ausloeser-dialog.md)
- [Adaptive Datums- und Zeitauswahl](../notes/adaptive-datums-zeitauswahl.md)
- [Muster für leere Zustände](../notes/leerer-zustand-muster.md)
- [Luminous-Seitenstil](../notes/luminous-seitenstil.md)

## Offene Punkte

- Bearbeiten-Dialog für bestehende Auslöser.
- Ereignis `fileCreated` auf Storage-/Firestore-Dateiversionen (Cloud) ausführen.
- Nummern-/WhatsApp-Provisionierung innerhalb des Team-Subaccounts.
- E-Mail-Connectoren und ihre Provider-Ereignisse an `taskRuns` anbinden.
- Team-Rollen auf die Auslöser-Verwaltung anwenden.

## Verwandt

- [Aufgabe](./aufgabe.md)
- [Aktivitäten](../features/aktivitaeten.md)
- [Webhooks](../features/webhooks.md)
- [Kommunikation](../features/kommunikation.md)
- [Architektur](../architecture.md)
